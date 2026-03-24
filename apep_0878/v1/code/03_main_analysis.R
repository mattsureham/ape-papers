# =============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna DiD + DDD regressions
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

# Restrict to 2001-2022 for balanced pre/post
df <- df %>% filter(year >= 2001, year <= 2022)

cat("Analysis sample:", nrow(df), "rows\n")
cat("Treatment cohorts:", sort(unique(df$eitc_year[df$eitc_year > 0])), "\n")

# =============================================================================
# 1. CALLAWAY-SANT'ANNA: Employment (Equity Channel)
# =============================================================================
# Collapse to state-industry-race-year for CS DiD
# (county-level has too many units for CS computational constraints)
df_state <- df %>%
  filter(!is.na(emp), !is.na(earn_avg)) %>%
  group_by(state_fips, industry, race, year, eitc_year) %>%
  summarize(
    earn_avg = weighted.mean(earn_avg, w = emp),
    emp = sum(emp),
    hires = sum(hires, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    unit_id = as.integer(factor(paste(state_fips, industry, race))),
    log_emp = log(emp + 1),
    log_earn = log(earn_avg + 1),
    black = as.integer(race == "A2"),
    first_treat = ifelse(eitc_year == 0, 0, eitc_year)
  )

cat("State-level panel:", nrow(df_state), "rows,", n_distinct(df_state$unit_id), "units\n")

# --- CS DiD for Black employment ---
cat("\n=== CS DiD: Black Employment ===\n")
cs_black_emp <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "unit_id",
  gname = "first_treat",
  data = df_state %>% filter(race == "A2"),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)
summary(cs_black_emp)

# Aggregate to event study
es_black_emp <- aggte(cs_black_emp, type = "dynamic", min_e = -5, max_e = 5)
cat("\nEvent study (Black employment):\n")
summary(es_black_emp)

# Overall ATT
att_black_emp <- aggte(cs_black_emp, type = "simple")
cat("\nOverall ATT (Black employment):\n")
summary(att_black_emp)

# --- CS DiD for White employment ---
cat("\n=== CS DiD: White Employment ===\n")
cs_white_emp <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "unit_id",
  gname = "first_treat",
  data = df_state %>% filter(race == "A1"),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)
att_white_emp <- aggte(cs_white_emp, type = "simple")
cat("\nOverall ATT (White employment):\n")
summary(att_white_emp)

# =============================================================================
# 2. CALLAWAY-SANT'ANNA: Earnings (Incidence Channel)
# =============================================================================
cat("\n=== CS DiD: Black Earnings ===\n")
cs_black_earn <- att_gt(
  yname = "log_earn",
  tname = "year",
  idname = "unit_id",
  gname = "first_treat",
  data = df_state %>% filter(race == "A2"),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)
att_black_earn <- aggte(cs_black_earn, type = "simple")
summary(att_black_earn)

es_black_earn <- aggte(cs_black_earn, type = "dynamic", min_e = -5, max_e = 5)

cat("\n=== CS DiD: White Earnings ===\n")
cs_white_earn <- att_gt(
  yname = "log_earn",
  tname = "year",
  idname = "unit_id",
  gname = "first_treat",
  data = df_state %>% filter(race == "A1"),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)
att_white_earn <- aggte(cs_white_earn, type = "simple")
summary(att_white_earn)

# =============================================================================
# 3. TRIPLE-DIFFERENCE (DDD): Black-White Gap
# =============================================================================
# fixest DDD: county × industry × race panel
cat("\n=== Triple-Difference (DDD) ===\n")

df$post <- as.integer(df$year >= df$eitc_year & df$eitc_year > 0)

# Employment DDD
ddd_emp <- feols(
  log_emp ~ post:black + post + black |
    fips_county^industry^race + industry^race^year,
  data = df,
  cluster = ~state_fips
)
cat("\nDDD — Employment:\n")
print(summary(ddd_emp))

# Earnings DDD
ddd_earn <- feols(
  log_earn ~ post:black + post + black |
    fips_county^industry^race + industry^race^year,
  data = df,
  cluster = ~state_fips
)
cat("\nDDD — Earnings:\n")
print(summary(ddd_earn))

# Hires DDD
df$log_hires <- log(df$hires + 1)
ddd_hires <- feols(
  log_hires ~ post:black + post + black |
    fips_county^industry^race + industry^race^year,
  data = df,
  cluster = ~state_fips
)
cat("\nDDD — Hires:\n")
print(summary(ddd_hires))

# =============================================================================
# 4. INDUSTRY HETEROGENEITY (Mechanism)
# =============================================================================
cat("\n=== Industry Heterogeneity ===\n")

# EITC intensity varies by sector: Accommodation/Food is most EITC-intensive
for (ind in c("72", "44-45", "62")) {
  cat("\nIndustry:", ind, "\n")
  m <- feols(
    log_earn ~ post:black + post + black |
      fips_county^race + race^year,
    data = df %>% filter(industry == ind),
    cluster = ~state_fips
  )
  cat("  post:black coef:", coef(m)["post:black"],
      " SE:", sqrt(vcov(m)["post:black", "post:black"]), "\n")
}

# =============================================================================
# 5. SAVE RESULTS
# =============================================================================
results <- list(
  cs_black_emp = cs_black_emp,
  cs_white_emp = cs_white_emp,
  cs_black_earn = cs_black_earn,
  cs_white_earn = cs_white_earn,
  es_black_emp = es_black_emp,
  es_black_earn = es_black_earn,
  att_black_emp = att_black_emp,
  att_white_emp = att_white_emp,
  att_black_earn = att_black_earn,
  att_white_earn = att_white_earn,
  ddd_emp = ddd_emp,
  ddd_earn = ddd_earn,
  ddd_hires = ddd_hires
)

saveRDS(results, "../data/main_results.rds")

# --- Diagnostics for validator ---
# Treated units = treated counties (unit of observation in DDD)
n_treated <- n_distinct(df$fips_county[df$eitc_year > 0])
n_pre <- length(unique(df$year[df$year < 2006]))  # years before first cohort
n_obs <- nrow(df)

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json", auto_unbox = TRUE
)
cat("\nDiagnostics: n_treated =", n_treated, ", n_pre =", n_pre, ", n_obs =", n_obs, "\n")
cat("Results saved to main_results.rds\n")
