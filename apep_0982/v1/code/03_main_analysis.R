# 03_main_analysis.R — Callaway-Sant'Anna DiD + DDD
source("00_packages.R")

annual <- readRDS("../data/annual_panel.rds")

# ============================================================
# 1. PRIMARY: CS-DiD for Black employment in accommodation
# ============================================================
cat("=== PRIMARY: Black accommodation employment ===\n")

ba <- annual %>%
  filter(race_label == "black", sector == "accommodation")

cat(sprintf("Black accommodation: %d state-years, %d states\n", nrow(ba), n_distinct(ba$state_fips)))
cat(sprintf("Treated states: %.0f, cohorts: %s\n",
            sum(ba$first_treat_year > 0) / n_distinct(ba$year),
            paste(sort(unique(ba$first_treat_year[ba$first_treat_year > 0])), collapse = ",")))

cs_black_accom <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = ba,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

cat("\n--- ATT(g,t) summary ---\n")
summary(cs_black_accom)

agg_overall <- aggte(cs_black_accom, type = "simple")
cat("\n--- Overall ATT ---\n")
summary(agg_overall)

agg_dynamic <- aggte(cs_black_accom, type = "dynamic", min_e = -6, max_e = 5)
cat("\n--- Dynamic ATT ---\n")
summary(agg_dynamic)

saveRDS(list(cs = cs_black_accom, overall = agg_overall, dynamic = agg_dynamic),
        "../data/cs_black_accom.rds")

# ============================================================
# 2. PLACEBO: White employment in accommodation
# ============================================================
cat("\n=== PLACEBO: White accommodation employment ===\n")

wa <- annual %>%
  filter(race_label == "white", sector == "accommodation")

cs_white_accom <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = wa,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_white_overall <- aggte(cs_white_accom, type = "simple")
cat("White accommodation ATT:\n")
summary(agg_white_overall)

agg_white_dynamic <- aggte(cs_white_accom, type = "dynamic", min_e = -6, max_e = 5)

saveRDS(list(cs = cs_white_accom, overall = agg_white_overall, dynamic = agg_white_dynamic),
        "../data/cs_white_accom.rds")

# ============================================================
# 3. PLACEBO: Black employment in manufacturing
# ============================================================
cat("\n=== PLACEBO: Black manufacturing employment ===\n")

bm <- annual %>%
  filter(race_label == "black", sector == "manufacturing")

cs_black_mfg <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = bm,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_mfg_overall <- aggte(cs_black_mfg, type = "simple")
cat("Black manufacturing ATT:\n")
summary(agg_mfg_overall)

agg_mfg_dynamic <- aggte(cs_black_mfg, type = "dynamic", min_e = -6, max_e = 5)

saveRDS(list(cs = cs_black_mfg, overall = agg_mfg_overall, dynamic = agg_mfg_dynamic),
        "../data/cs_black_mfg.rds")

# ============================================================
# 4. DDD: State × Race × Sector with fixest
# ============================================================
cat("\n=== DDD: State × Race × Sector ===\n")

ddd_data <- annual %>%
  mutate(
    post = as.integer(year >= first_treat_year & first_treat_year > 0),
    is_black = as.integer(race_label == "black"),
    is_accom = as.integer(sector == "accommodation")
  )

ddd_emp <- feols(
  log_emp ~ post:is_black:is_accom + post:is_black + post:is_accom +
    is_black:is_accom |
    state_fips^race_label^sector + year^race_label^sector,
  data = ddd_data,
  cluster = ~state_fips
)
cat("\nDDD employment:\n")
summary(ddd_emp)

ddd_hires <- feols(
  log_hires ~ post:is_black:is_accom + post:is_black + post:is_accom +
    is_black:is_accom |
    state_fips^race_label^sector + year^race_label^sector,
  data = ddd_data,
  cluster = ~state_fips
)
cat("\nDDD hires:\n")
summary(ddd_hires)

saveRDS(list(emp = ddd_emp, hires = ddd_hires), "../data/ddd_results.rds")

# ============================================================
# 5. Write diagnostics.json
# ============================================================
diag <- list(
  n_treated = length(unique(ba$state_fips[ba$first_treat_year > 0])),
  # AK (2003) is dropped by CS since data starts 2005; effective first cohort is 2010 (AZ)
  n_pre = length(unique(ba$year[ba$year < min(ba$first_treat_year[ba$first_treat_year > 2004])])),
  n_obs = nrow(annual),
  n_states = length(unique(annual$state_fips)),
  n_years = length(unique(annual$year)),
  att_overall = agg_overall$overall.att,
  att_se = agg_overall$overall.se,
  att_white = agg_white_overall$overall.att,
  att_mfg = agg_mfg_overall$overall.att,
  ddd_coef = as.numeric(coef(ddd_emp)["post:is_black:is_accom"]),
  ddd_se = as.numeric(se(ddd_emp)["post:is_black:is_accom"])
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics written. Main analysis complete.\n")
