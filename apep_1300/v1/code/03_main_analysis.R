# ==============================================================================
# 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
# Paper: The Racial Dividend of the Warehouse Boom (apep_1300)
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
pre_sd <- readRDS("../data/pre_treatment_sd.rds")

# ---------- 1. Overall Warehousing Employment (All Races) ---------------------

cat("=== Callaway-Sant'Anna: All Races, Log Employment ===\n")

df_all <- panel %>%
  filter(race_group == "All") %>%
  # Remove county-years with missing employment
  filter(!is.na(log_emp) & is.finite(log_emp)) %>%
  # Ensure panel is balanced enough for CS
  group_by(county_fips) %>%
  filter(n() >= 15) %>%  # At least 15 years of data

  ungroup() %>%
  mutate(id = as.integer(factor(county_fips)))

cat("Obs:", nrow(df_all), "Counties:", n_distinct(df_all$county_fips), "\n")
cat("Treated:", sum(df_all$first_treat > 0 & df_all$year == min(df_all$year)), "\n")

cs_all <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = df_all,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

# Aggregate: overall ATT
agg_all <- aggte(cs_all, type = "simple")
cat("\nOverall ATT (log employment, all races):\n")
summary(agg_all)

# Event study aggregation
es_all <- aggte(cs_all, type = "dynamic", min_e = -8, max_e = 8)
cat("\nEvent study (all races):\n")
summary(es_all)

# ---------- 2. By Race -------------------------------------------------------

results_by_race <- list()

for (rc in c("Black", "White", "Asian")) {
  cat(sprintf("\n=== Callaway-Sant'Anna: %s, Log Employment ===\n", rc))

  df_race <- panel %>%
    filter(race_group == rc) %>%
    filter(!is.na(log_emp) & is.finite(log_emp)) %>%
    group_by(county_fips) %>%
    filter(n() >= 15) %>%
    ungroup() %>%
    mutate(id = as.integer(factor(county_fips)))

  cat("Obs:", nrow(df_race), "Counties:", n_distinct(df_race$county_fips), "\n")

  cs_race <- att_gt(
    yname = "log_emp",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_race,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )

  agg_race <- aggte(cs_race, type = "simple")
  es_race <- aggte(cs_race, type = "dynamic", min_e = -8, max_e = 8)

  cat(sprintf("ATT (%s): %.4f (SE: %.4f)\n", rc, agg_race$overall.att, agg_race$overall.se))

  results_by_race[[rc]] <- list(
    cs = cs_race,
    agg = agg_race,
    es = es_race
  )
}

# ---------- 3. Earnings by Race -----------------------------------------------

cat("\n=== Earnings Regressions ===\n")

earnings_results <- list()

for (rc in c("All", "Black", "White")) {
  cat(sprintf("\n--- Earnings: %s ---\n", rc))

  df_earn <- panel %>%
    filter(race_group == rc) %>%
    filter(!is.na(log_earn) & is.finite(log_earn) & avg_earnings > 0) %>%
    group_by(county_fips) %>%
    filter(n() >= 15) %>%
    ungroup() %>%
    mutate(id = as.integer(factor(county_fips)))

  cs_earn <- att_gt(
    yname = "log_earn",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_earn,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )

  agg_earn <- aggte(cs_earn, type = "simple")
  cat(sprintf("ATT earnings (%s): %.4f (SE: %.4f)\n", rc, agg_earn$overall.att, agg_earn$overall.se))

  earnings_results[[rc]] <- list(cs = cs_earn, agg = agg_earn)
}

# ---------- 4. Hires (labor market dynamism) ----------------------------------

cat("\n=== Hires Regressions ===\n")

hires_results <- list()

for (rc in c("All", "Black", "White")) {
  cat(sprintf("\n--- Hires: %s ---\n", rc))

  df_hires <- panel %>%
    filter(race_group == rc) %>%
    filter(!is.na(log_hires) & is.finite(log_hires) & hires_all > 0) %>%
    group_by(county_fips) %>%
    filter(n() >= 15) %>%
    ungroup() %>%
    mutate(id = as.integer(factor(county_fips)))

  cs_hires <- att_gt(
    yname = "log_hires",
    tname = "year",
    idname = "id",
    gname = "first_treat",
    data = df_hires,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying"
  )

  agg_hires <- aggte(cs_hires, type = "simple")
  cat(sprintf("ATT hires (%s): %.4f (SE: %.4f)\n", rc, agg_hires$overall.att, agg_hires$overall.se))

  hires_results[[rc]] <- list(cs = cs_hires, agg = agg_hires)
}

# ---------- 5. TWFE comparison (for reference) --------------------------------

cat("\n=== TWFE Comparison (fixest) ===\n")

# Standard TWFE — known to be biased with staggered treatment
twfe_all <- feols(log_emp ~ post | county_fips + year,
                  data = df_all, cluster = ~county_fips)
cat("TWFE (all races):\n")
print(summary(twfe_all))

# By race using fixest (faster, for supplementary analysis)
df_black <- panel %>%
  filter(race_group == "Black") %>%
  filter(!is.na(log_emp) & is.finite(log_emp))

df_white <- panel %>%
  filter(race_group == "White") %>%
  filter(!is.na(log_emp) & is.finite(log_emp))

twfe_black <- feols(log_emp ~ post | county_fips + year,
                    data = df_black, cluster = ~county_fips)
twfe_white <- feols(log_emp ~ post | county_fips + year,
                    data = df_white, cluster = ~county_fips)

cat("\nTWFE (Black):", coef(twfe_black)["post"], "SE:", se(twfe_black)["post"], "\n")
cat("TWFE (White):", coef(twfe_white)["post"], "SE:", se(twfe_white)["post"], "\n")

# ---------- 6. Diagnostics for validator --------------------------------------

# For staggered designs, n_pre = pre-periods for the median cohort
n_treated <- n_distinct(df_all$county_fips[df_all$first_treat > 0])
median_cohort <- median(df_all$first_treat[df_all$first_treat > 0])
n_pre <- length(unique(df_all$year[df_all$year < median_cohort]))
n_obs <- nrow(df_all)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written:", paste(names(diagnostics), diagnostics, sep = "=", collapse = ", "), "\n")

# ---------- 7. Save all results -----------------------------------------------

saveRDS(list(
  cs_all = cs_all,
  agg_all = agg_all,
  es_all = es_all,
  results_by_race = results_by_race,
  earnings_results = earnings_results,
  hires_results = hires_results,
  twfe_all = twfe_all,
  twfe_black = twfe_black,
  twfe_white = twfe_white
), "../data/main_results.rds")

cat("\nMain analysis complete. Results saved.\n")
