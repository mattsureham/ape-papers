## 04_robustness.R — Robustness checks and placebo tests
## apep_1028: Right-to-Counsel and Community-Level Homelessness

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/main_results.rds")

panel <- panel |>
  mutate(coc_id = as.integer(factor(coc_code)))

# ============================================================
# 1. PRE-COVID ONLY: Restrict to 2017-2019 adopters
# ============================================================
cat("=== Robustness 1: Pre-COVID cohorts only ===\n")

# Keep only pre-COVID adopters (2017, 2018, 2019) and never-treated
# Drop 2020 and 2021 data to avoid COVID contamination
panel_precovid <- panel |>
  filter(first_treat %in% c(0L, 2017L, 2018L, 2019L)) |>
  filter(year <= 2019)

cat("Pre-COVID panel:", nrow(panel_precovid), "rows,",
    n_distinct(panel_precovid$coc_code), "CoCs\n")
cat("Treated:", n_distinct(panel_precovid$coc_code[panel_precovid$first_treat > 0]), "\n")

cs_precovid <- att_gt(
  yname = "log_total",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel_precovid,
  control_group = "nevertreated",
  base_period = "universal"
)

att_precovid <- aggte(cs_precovid, type = "simple")
cat("\nPre-COVID ATT (total):\n")
summary(att_precovid)

es_precovid <- aggte(cs_precovid, type = "dynamic", min_e = -8, max_e = 2)

# ============================================================
# 2. NOT-YET-TREATED as control group
# ============================================================
cat("\n=== Robustness 2: Not-yet-treated controls ===\n")

cs_nyt <- att_gt(
  yname = "log_total",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel,
  control_group = "notyettreated",
  base_period = "universal"
)

att_nyt <- aggte(cs_nyt, type = "simple")
cat("\nNot-yet-treated ATT (total):\n")
summary(att_nyt)

# ============================================================
# 3. LEVELS instead of logs
# ============================================================
cat("\n=== Robustness 3: Levels (per capita) ===\n")

# Normalize by pre-treatment mean to get percent change interpretation
panel <- panel |>
  group_by(coc_code) |>
  mutate(
    pre_mean_total = mean(total_homeless[year <= 2016], na.rm = TRUE)
  ) |>
  ungroup() |>
  mutate(
    total_pct = total_homeless / pre_mean_total * 100
  )

twfe_pct <- feols(total_pct ~ treated | coc_id + year, data = panel,
                  cluster = ~coc_id)
cat("\nTWFE in percent of pre-mean:\n")
summary(twfe_pct)

# ============================================================
# 4. PLACEBO: Shift treatment 3 years earlier
# ============================================================
cat("\n=== Robustness 4: Placebo (treatment shifted -3 years) ===\n")

panel_placebo <- panel |>
  mutate(
    first_treat_placebo = ifelse(first_treat > 0, first_treat - 3L, 0L),
    treated_placebo = as.integer(first_treat_placebo > 0 & year >= first_treat_placebo)
  ) |>
  # Only use pre-treatment data (before actual treatment)
  filter(first_treat == 0 | year < first_treat)

twfe_placebo <- feols(log_total ~ treated_placebo | coc_id + year,
                      data = panel_placebo, cluster = ~coc_id)
cat("\nPlacebo TWFE (shifted -3 years):\n")
summary(twfe_placebo)

# ============================================================
# 5. SIZE-MATCHED controls (large CoCs only)
# ============================================================
cat("\n=== Robustness 5: Size-matched controls ===\n")

# Treated CoCs are much larger than average. Restrict controls to
# CoCs with pre-treatment mean > 500 homeless
large_cocs <- panel |>
  filter(year <= 2016) |>
  group_by(coc_code) |>
  summarise(pre_mean = mean(total_homeless, na.rm = TRUE), .groups = "drop") |>
  filter(pre_mean > 500) |>
  pull(coc_code)

panel_large <- panel |>
  filter(coc_code %in% large_cocs)

cat("Large CoCs:", n_distinct(panel_large$coc_code),
    "(treated:", n_distinct(panel_large$coc_code[panel_large$first_treat > 0]), ")\n")

twfe_large <- feols(log_total ~ treated | coc_id + year,
                    data = panel_large, cluster = ~coc_id)
cat("\nTWFE with size-matched controls:\n")
summary(twfe_large)

# ============================================================
# 6. LEAVE-ONE-OUT: Drop NYC (largest treated unit)
# ============================================================
cat("\n=== Robustness 6: Drop NYC ===\n")

panel_no_nyc <- panel |> filter(coc_code != "NY-600")

cs_no_nyc <- att_gt(
  yname = "log_total",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel_no_nyc,
  control_group = "nevertreated",
  base_period = "universal"
)

att_no_nyc <- aggte(cs_no_nyc, type = "simple")
cat("\nCS ATT without NYC:\n")
summary(att_no_nyc)

# ============================================================
# 7. HonestDiD sensitivity analysis
# ============================================================
cat("\n=== Robustness 7: HonestDiD bounds ===\n")

# Use the main CS event study for total homelessness
es <- results$es_total

# Extract event-study estimates and variance-covariance matrix
# for HonestDiD
tryCatch({
  honest_result <- HonestDiD::createSensitivityResults_relativeMagnitudes(
    betahat = es$att.egt,
    sigma = es$V,
    numPrePeriods = sum(es$egt < 0),
    numPostPeriods = sum(es$egt >= 0),
    Mbarvec = seq(0.5, 2, by = 0.5)
  )
  cat("\nHonestDiD relative magnitudes:\n")
  print(honest_result)
}, error = function(e) {
  cat("\nHonestDiD failed (common with small groups):", conditionMessage(e), "\n")
})

# ============================================================
# Save robustness results
# ============================================================
robust <- list(
  att_precovid = att_precovid,
  es_precovid = es_precovid,
  att_nyt = att_nyt,
  twfe_pct = twfe_pct,
  twfe_placebo = twfe_placebo,
  twfe_large = twfe_large,
  att_no_nyc = att_no_nyc
)

saveRDS(robust, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
