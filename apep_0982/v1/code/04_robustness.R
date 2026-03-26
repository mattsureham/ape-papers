# 04_robustness.R — Robustness checks
source("00_packages.R")

annual <- readRDS("../data/annual_panel.rds")

# ============================================================
# 1. Pre-COVID only (2005-2019)
# ============================================================
cat("=== Robustness 1: Pre-COVID (2005-2019) ===\n")

pre_covid <- annual %>%
  filter(year <= 2019, race_label == "black", sector == "accommodation") %>%
  filter(first_treat_year == 0 | first_treat_year <= 2019) %>%
  mutate(state_id = as.numeric(factor(state_fips)))

cs_precovid <- att_gt(
  yname = "log_emp", tname = "year", idname = "state_id",
  gname = "first_treat_year", data = pre_covid,
  control_group = "nevertreated", anticipation = 0, base_period = "universal"
)
agg_precovid <- aggte(cs_precovid, type = "simple")
cat("Pre-COVID ATT:\n")
summary(agg_precovid)
saveRDS(list(cs = cs_precovid, overall = agg_precovid), "../data/rob_precovid.rds")

# ============================================================
# 2. Not-yet-treated as control
# ============================================================
cat("\n=== Robustness 2: Not-yet-treated controls ===\n")

ba_full <- annual %>%
  filter(race_label == "black", sector == "accommodation") %>%
  mutate(state_id = as.numeric(factor(state_fips)))

cs_nyt <- att_gt(
  yname = "log_emp", tname = "year", idname = "state_id",
  gname = "first_treat_year", data = ba_full,
  control_group = "notyettreated", anticipation = 0, base_period = "universal"
)
agg_nyt <- aggte(cs_nyt, type = "simple")
cat("Not-yet-treated ATT:\n")
summary(agg_nyt)
saveRDS(list(cs = cs_nyt, overall = agg_nyt), "../data/rob_nyt.rds")

# ============================================================
# 3. DDD Pre-COVID
# ============================================================
cat("\n=== Robustness 3: DDD Pre-COVID ===\n")

ddd_pre <- annual %>%
  filter(year <= 2019) %>%
  filter(first_treat_year == 0 | first_treat_year <= 2019) %>%
  mutate(
    post = as.integer(year >= first_treat_year & first_treat_year > 0),
    is_black = as.integer(race_label == "black"),
    is_accom = as.integer(sector == "accommodation")
  )

ddd_pre_fit <- feols(
  log_emp ~ post:is_black:is_accom + post:is_black + post:is_accom +
    is_black:is_accom |
    state_fips^race_label^sector + year^race_label^sector,
  data = ddd_pre,
  cluster = ~state_fips
)
cat("DDD Pre-COVID:\n")
summary(ddd_pre_fit)
saveRDS(ddd_pre_fit, "../data/rob_ddd_precovid.rds")

# ============================================================
# 4. TWFE comparison
# ============================================================
cat("\n=== Robustness 4: TWFE comparison ===\n")

ba_twfe <- annual %>%
  filter(race_label == "black", sector == "accommodation") %>%
  mutate(post = as.integer(year >= first_treat_year & first_treat_year > 0))

twfe_fit <- feols(
  log_emp ~ post | state_fips + year,
  data = ba_twfe,
  cluster = ~state_fips
)
cat("TWFE result:\n")
summary(twfe_fit)
saveRDS(twfe_fit, "../data/rob_twfe.rds")

# ============================================================
# 5. Leave-one-out by largest cohort (2021 wave)
# ============================================================
cat("\n=== Robustness 5: Drop 2021 wave ===\n")

ddd_no2021 <- annual %>%
  filter(first_treat_year != 2021) %>%
  mutate(
    post = as.integer(year >= first_treat_year & first_treat_year > 0),
    is_black = as.integer(race_label == "black"),
    is_accom = as.integer(sector == "accommodation")
  )

ddd_no2021_fit <- feols(
  log_emp ~ post:is_black:is_accom + post:is_black + post:is_accom +
    is_black:is_accom |
    state_fips^race_label^sector + year^race_label^sector,
  data = ddd_no2021,
  cluster = ~state_fips
)
cat("DDD without 2021 cohort:\n")
cat(sprintf("  post:black:accom = %.4f (SE %.4f)\n",
            coef(ddd_no2021_fit)["post:is_black:is_accom"],
            se(ddd_no2021_fit)["post:is_black:is_accom"]))
saveRDS(ddd_no2021_fit, "../data/rob_ddd_no2021.rds")

cat("\nRobustness checks complete.\n")
