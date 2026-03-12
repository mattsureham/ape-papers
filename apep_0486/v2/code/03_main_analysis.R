## 03_main_analysis.R — Primary DiD and DDD estimation
## apep_0486 v2: Progressive Prosecutors, Incarceration, and Public Safety
## NEW in v2: Metro-only specs, entropy-balanced specs, race-specific CS-DiD
##
## NOTE: This script estimates BOTH traditional TWFE and heterogeneity-robust
## Callaway-Sant'Anna (2021) estimators. The TWFE specifications serve as
## descriptive benchmarks; the CS-DiD estimates (att_gt/aggte) are the primary
## identification-robust results reported in Table 4 (tab:csatt). The matched
## TWFE (metro restriction + entropy balancing) and CS-DiD results are the
## basis for inference; unmatched TWFE is retained for transparency only.

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
panel[, state_fips := str_pad(as.character(state_fips), width = 2, pad = "0")]

race_long <- fread(file.path(DATA_DIR, "race_panel.csv"))
race_long[, fips := str_pad(as.character(fips), width = 5, pad = "0")]

# Load metro panel
metro_panel <- fread(file.path(DATA_DIR, "metro_panel.csv"))
metro_panel[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
metro_panel[, state_fips := str_pad(as.character(state_fips), width = 2, pad = "0")]

cat("=== ANALYSIS 1: First Stage — Jail Population (DiD) ===\n")

# --- 1a. TWFE (baseline, full sample) ---
twfe_jail <- feols(
  jail_rate ~ treated | fips + year,
  data = panel[!is.na(jail_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Jail Rate (full sample):\n")
summary(twfe_jail)

# --- 1b. TWFE with controls ---
twfe_jail_ctrl <- feols(
  jail_rate ~ treated + poverty_rate + unemp_rate + log_pop | fips + year,
  data = panel[!is.na(jail_rate) & !is.na(poverty_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Jail Rate (with controls):\n")
summary(twfe_jail_ctrl)

# --- 1c. State × year FE ---
twfe_jail_sxyr <- feols(
  jail_rate ~ treated | fips + state_fips^year,
  data = panel[!is.na(jail_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Jail Rate (State × Year FE):\n")
summary(twfe_jail_sxyr)

# --- 1d. NEW v2: Metro-only sample ---
twfe_jail_metro <- feols(
  jail_rate ~ treated | fips + year,
  data = metro_panel[!is.na(jail_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Jail Rate (Metro-only):\n")
summary(twfe_jail_metro)

# --- 1e. NEW v2: Entropy-balanced TWFE ---
has_ebal <- "ebal_weight" %in% names(panel) && any(panel$ebal_weight > 0, na.rm = TRUE)
twfe_jail_ebal <- NULL
if (has_ebal) {
  ebal_data <- panel[!is.na(jail_rate) & !is.na(ebal_weight) & ebal_weight > 0]
  if (nrow(ebal_data) > 100) {
    twfe_jail_ebal <- feols(
      jail_rate ~ treated | fips + year,
      data = ebal_data,
      weights = ~ebal_weight,
      cluster = ~state_fips
    )
    cat("\nTWFE Jail Rate (Entropy-balanced):\n")
    summary(twfe_jail_ebal)
  }
}

# --- 1f. Callaway & Sant'Anna (full sample) ---
cs_data <- panel[!is.na(jail_rate) & !is.na(treatment_year)]
cs_data[, fips_num := as.integer(factor(fips))]
# Fix: did 2.3.0 converts gname=0 to Inf internally; integer column truncates Inf to NA
# Must use numeric type for treatment_year
cs_data[, treatment_year := as.numeric(treatment_year)]

cat("\nCS-DiD estimation for jail rate (full sample)...\n")
set.seed(2024)
cs_jail <- att_gt(
  yname  = "jail_rate",
  tname  = "year",
  idname = "fips_num",
  gname  = "treatment_year",
  data   = as.data.frame(cs_data),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal",
  bstrap = TRUE,
  cband  = TRUE,
  biters = 1000
)
cs_jail_agg <- aggte(cs_jail, type = "simple")
cat("\nCS-DiD Simple ATT (Jail Rate, full sample):\n")
summary(cs_jail_agg)

cs_jail_es <- aggte(cs_jail, type = "dynamic", min_e = -8, max_e = 6)
es_jail_df <- data.frame(
  event_time = cs_jail_es$egt,
  att = cs_jail_es$att.egt,
  se = cs_jail_es$se.egt,
  ci_lower = cs_jail_es$att.egt - 1.96 * cs_jail_es$se.egt,
  ci_upper = cs_jail_es$att.egt + 1.96 * cs_jail_es$se.egt
)
fwrite(es_jail_df, file.path(DATA_DIR, "es_jail_rate.csv"))

# --- 1g. NEW v2: CS-DiD metro-only ---
cs_metro <- metro_panel[!is.na(jail_rate) & !is.na(treatment_year)]
cs_metro[, fips_num := as.integer(factor(fips))]
cs_metro[, treatment_year := as.numeric(treatment_year)]

cat("\nCS-DiD estimation for jail rate (metro-only)...\n")
set.seed(2024)
cs_jail_metro <- tryCatch({
  att_gt(
    yname  = "jail_rate",
    tname  = "year",
    idname = "fips_num",
    gname  = "treatment_year",
    data   = as.data.frame(cs_metro),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD metro failed:", e$message, "\n")
  NULL
})

cs_jail_metro_agg <- NULL
if (!is.null(cs_jail_metro)) {
  cs_jail_metro_agg <- aggte(cs_jail_metro, type = "simple")
  cat("\nCS-DiD Simple ATT (Jail Rate, metro-only):\n")
  summary(cs_jail_metro_agg)

  cs_jail_metro_es <- aggte(cs_jail_metro, type = "dynamic", min_e = -8, max_e = 6)
  es_jail_metro_df <- data.frame(
    event_time = cs_jail_metro_es$egt,
    att = cs_jail_metro_es$att.egt,
    se = cs_jail_metro_es$se.egt,
    ci_lower = cs_jail_metro_es$att.egt - 1.96 * cs_jail_metro_es$se.egt,
    ci_upper = cs_jail_metro_es$att.egt + 1.96 * cs_jail_metro_es$se.egt
  )
  fwrite(es_jail_metro_df, file.path(DATA_DIR, "es_jail_rate_metro.csv"))
}

cat("\n=== ANALYSIS 2: Pretrial vs Sentenced ===\n")

panel[, pretrial_rate := fifelse(total_pop_15to64 > 0,
                                  total_jail_pretrial / total_pop_15to64 * 100000, NA_real_)]
panel[, sentenced_rate := fifelse(total_pop_15to64 > 0,
                                   total_jail_sentenced / total_pop_15to64 * 100000, NA_real_)]

twfe_pretrial <- feols(
  pretrial_rate ~ treated | fips + year,
  data = panel[!is.na(pretrial_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Pretrial Rate:\n")
summary(twfe_pretrial)

twfe_sentenced <- feols(
  sentenced_rate ~ treated | fips + year,
  data = panel[!is.na(sentenced_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Sentenced Rate:\n")
summary(twfe_sentenced)

# CS-DiD for pretrial
cs_pretrial_data <- panel[!is.na(pretrial_rate) & !is.na(treatment_year)]
cs_pretrial_data[, fips_num := as.integer(factor(fips))]
cs_pretrial_data[, treatment_year := as.numeric(treatment_year)]

set.seed(2024)
cs_pretrial <- tryCatch({
  att_gt(
    yname  = "pretrial_rate",
    tname  = "year",
    idname = "fips_num",
    gname  = "treatment_year",
    data   = as.data.frame(cs_pretrial_data),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD pretrial failed:", e$message, "\n")
  NULL
})

cs_pretrial_agg <- NULL
if (!is.null(cs_pretrial)) {
  cs_pretrial_agg <- aggte(cs_pretrial, type = "simple")
  cat("\nCS-DiD Simple ATT (Pretrial Rate):\n")
  summary(cs_pretrial_agg)

  cs_pretrial_es <- aggte(cs_pretrial, type = "dynamic", min_e = -8, max_e = 6)
  es_pretrial_df <- data.frame(
    event_time = cs_pretrial_es$egt,
    att = cs_pretrial_es$att.egt,
    se = cs_pretrial_es$se.egt,
    ci_lower = cs_pretrial_es$att.egt - 1.96 * cs_pretrial_es$se.egt,
    ci_upper = cs_pretrial_es$att.egt + 1.96 * cs_pretrial_es$se.egt
  )
  fwrite(es_pretrial_df, file.path(DATA_DIR, "es_pretrial_rate.csv"))
}

cat("\n=== ANALYSIS 3: Homicide Mortality ===\n")

twfe_homicide <- feols(
  homicide_rate ~ treated | fips + year,
  data = panel[!is.na(homicide_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Homicide Rate:\n")
summary(twfe_homicide)

twfe_hom_sxyr <- feols(
  homicide_rate ~ treated | fips + state_fips^year,
  data = panel[!is.na(homicide_rate)],
  cluster = ~state_fips
)
cat("\nTWFE Homicide Rate (State × Year FE):\n")
summary(twfe_hom_sxyr)

# CS-DiD for homicides
cs_hom_data <- panel[!is.na(homicide_rate) & !is.na(treatment_year)]
cs_hom_data[, fips_num := as.integer(factor(fips))]
cs_hom_data[, treatment_year := as.numeric(treatment_year)]

set.seed(2024)
cs_homicide <- tryCatch({
  att_gt(
    yname  = "homicide_rate",
    tname  = "year",
    idname = "fips_num",
    gname  = "treatment_year",
    data   = as.data.frame(cs_hom_data),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD homicide failed:", e$message, "\n")
  NULL
})

cs_hom_agg <- NULL
if (!is.null(cs_homicide)) {
  cs_hom_agg <- aggte(cs_homicide, type = "simple")
  cat("\nCS-DiD Simple ATT (Homicide Rate):\n")
  summary(cs_hom_agg)

  cs_hom_es <- aggte(cs_homicide, type = "dynamic", min_e = -8, max_e = 6)
  es_hom_df <- data.frame(
    event_time = cs_hom_es$egt,
    att = cs_hom_es$att.egt,
    se = cs_hom_es$se.egt,
    ci_lower = cs_hom_es$att.egt - 1.96 * cs_hom_es$se.egt,
    ci_upper = cs_hom_es$att.egt + 1.96 * cs_hom_es$se.egt
  )
  fwrite(es_hom_df, file.path(DATA_DIR, "es_homicide_rate.csv"))
}

cat("\n=== ANALYSIS 4: DDD — Racial Decomposition ===\n")

ddd_data <- race_long[!is.na(jail_rate_race)]
ddd_data[, `:=`(
  fips_race = paste0(fips, "_", race),
  year_race = paste0(year, "_", race)
)]

ddd_jail <- feols(
  jail_rate_race ~ is_black:treated | fips_race + year_race + fips^year,
  data = ddd_data,
  cluster = ~state_fips
)
cat("\nDDD Jail Rate (Black × Treated):\n")
summary(ddd_jail)

# DDD for homicide
ddd_hom_data <- race_long[!is.na(homicide_rate_race)]
ddd_homicide <- NULL
if (nrow(ddd_hom_data) > 100) {
  ddd_hom_data[, `:=`(
    fips_race = paste0(fips, "_", race),
    year_race = paste0(year, "_", race)
  )]
  ddd_homicide <- feols(
    homicide_rate_race ~ is_black:treated | fips_race + year_race + fips^year,
    data = ddd_hom_data,
    cluster = ~state_fips
  )
  cat("\nDDD Homicide Rate (Black × Treated):\n")
  summary(ddd_homicide)
}

cat("\n=== ANALYSIS 5: Black-White Jail Ratio ===\n")

twfe_bw_ratio <- feols(
  bw_jail_ratio ~ treated | fips + year,
  data = panel[!is.na(bw_jail_ratio) & is.finite(bw_jail_ratio)],
  cluster = ~state_fips
)
cat("\nTWFE Black/White Jail Ratio:\n")
summary(twfe_bw_ratio)

# ======================================================================
# NEW v2: Race-specific CS-DiD event studies
# ======================================================================
cat("\n=== ANALYSIS 6: Race-Specific CS-DiD Event Studies ===\n")

# Black jail rate CS-DiD
black_data <- panel[!is.na(black_jail_rate) & !is.na(treatment_year)]
black_data[, fips_num := as.integer(factor(fips))]
black_data[, treatment_year := as.numeric(treatment_year)]

set.seed(2024)
cs_black <- tryCatch({
  att_gt(
    yname  = "black_jail_rate",
    tname  = "year",
    idname = "fips_num",
    gname  = "treatment_year",
    data   = as.data.frame(black_data),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD Black jail rate failed:", e$message, "\n")
  NULL
})

cs_black_agg <- NULL
if (!is.null(cs_black)) {
  cs_black_agg <- aggte(cs_black, type = "simple")
  cat("\nCS-DiD Simple ATT (Black Jail Rate):\n")
  summary(cs_black_agg)

  cs_black_es <- aggte(cs_black, type = "dynamic", min_e = -8, max_e = 6)
  es_black_df <- data.frame(
    event_time = cs_black_es$egt,
    att = cs_black_es$att.egt,
    se = cs_black_es$se.egt,
    ci_lower = cs_black_es$att.egt - 1.96 * cs_black_es$se.egt,
    ci_upper = cs_black_es$att.egt + 1.96 * cs_black_es$se.egt,
    race = "Black"
  )
  fwrite(es_black_df, file.path(DATA_DIR, "es_black_jail_rate.csv"))
}

# White jail rate CS-DiD
white_data <- panel[!is.na(white_jail_rate) & !is.na(treatment_year)]
white_data[, fips_num := as.integer(factor(fips))]
white_data[, treatment_year := as.numeric(treatment_year)]

set.seed(2024)
cs_white <- tryCatch({
  att_gt(
    yname  = "white_jail_rate",
    tname  = "year",
    idname = "fips_num",
    gname  = "treatment_year",
    data   = as.data.frame(white_data),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD White jail rate failed:", e$message, "\n")
  NULL
})

cs_white_agg <- NULL
if (!is.null(cs_white)) {
  cs_white_agg <- aggte(cs_white, type = "simple")
  cat("\nCS-DiD Simple ATT (White Jail Rate):\n")
  summary(cs_white_agg)

  cs_white_es <- aggte(cs_white, type = "dynamic", min_e = -8, max_e = 6)
  es_white_df <- data.frame(
    event_time = cs_white_es$egt,
    att = cs_white_es$att.egt,
    se = cs_white_es$se.egt,
    ci_lower = cs_white_es$att.egt - 1.96 * cs_white_es$se.egt,
    ci_upper = cs_white_es$att.egt + 1.96 * cs_white_es$se.egt,
    race = "White"
  )
  fwrite(es_white_df, file.path(DATA_DIR, "es_white_jail_rate.csv"))
}

# ======================================================================
# NEW v2: Metro-only DDD
# ======================================================================
cat("\n=== ANALYSIS 7: Metro-only DDD ===\n")

metro_race <- race_long[metro_sample == 1 & !is.na(jail_rate_race)]
metro_race[, `:=`(
  fips_race = paste0(fips, "_", race),
  year_race = paste0(year, "_", race)
)]

ddd_jail_metro <- tryCatch({
  feols(
    jail_rate_race ~ is_black:treated | fips_race + year_race + fips^year,
    data = metro_race,
    cluster = ~state_fips
  )
}, error = function(e) {
  cat("Metro DDD failed:", e$message, "\n")
  NULL
})

if (!is.null(ddd_jail_metro)) {
  cat("\nDDD Jail Rate (Metro-only, Black × Treated):\n")
  summary(ddd_jail_metro)
}

cat("\n=== SAVING RESULTS ===\n")

results <- list(
  twfe_jail = twfe_jail,
  twfe_jail_ctrl = twfe_jail_ctrl,
  twfe_jail_sxyr = twfe_jail_sxyr,
  twfe_jail_metro = twfe_jail_metro,
  twfe_jail_ebal = twfe_jail_ebal,
  twfe_pretrial = twfe_pretrial,
  twfe_sentenced = twfe_sentenced,
  twfe_homicide = twfe_homicide,
  twfe_hom_sxyr = twfe_hom_sxyr,
  twfe_bw_ratio = twfe_bw_ratio,
  ddd_jail = ddd_jail,
  ddd_jail_metro = ddd_jail_metro,
  ddd_homicide = ddd_homicide,
  cs_jail_agg = cs_jail_agg,
  cs_jail_metro_agg = cs_jail_metro_agg,
  cs_hom_agg = cs_hom_agg,
  cs_pretrial_agg = cs_pretrial_agg,
  cs_black_agg = cs_black_agg,
  cs_white_agg = cs_white_agg
)

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))

# Summary statistics
summ_all <- panel[year >= 2005, .(
  jail_rate_mean = mean(jail_rate, na.rm = TRUE),
  jail_rate_sd = sd(jail_rate, na.rm = TRUE),
  homicide_rate_mean = mean(homicide_rate, na.rm = TRUE),
  homicide_rate_sd = sd(homicide_rate, na.rm = TRUE),
  total_pop_mean = mean(total_pop, na.rm = TRUE),
  poverty_rate_mean = mean(poverty_rate, na.rm = TRUE),
  black_share_mean = mean(black_share, na.rm = TRUE),
  unemp_rate_mean = mean(unemp_rate, na.rm = TRUE),
  N_counties = length(unique(fips)),
  N_obs = .N
)]
fwrite(summ_all, file.path(DATA_DIR, "summary_statistics.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
