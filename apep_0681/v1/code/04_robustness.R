# 04_robustness.R — Robustness checks and placebo tests
# apep_0681: IR35 Off-Payroll Reforms

source("00_packages.R")

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)

panel <- panel |>
  mutate(
    la_code  = as.factor(la_code),
    sic_code = as.factor(sic_code),
    unit_id  = as.factor(unit_id),
    year_f   = as.factor(year)
  )

# ============================================================
# 1. COVID PLACEBO: Treatment in 2020 (reform was delayed)
# ============================================================
# If IR35 drives dissolution, effect should be in 2021 not 2020
# Create fake 2020 treatment

cat("=== COVID PLACEBO (2020) ===\n")

panel_pre2021 <- panel |> filter(year <= 2020)
panel_pre2021 <- panel_pre2021 |>
  mutate(
    post_2020_placebo = as.integer(year >= 2020),
    treat_post2020 = treated * post_2020_placebo
  )

m_placebo_2020 <- feols(log_companies ~ treat_post2017 + treat_post2020 |
                          sic_code + la_code^year_f,
                        data = panel_pre2021, cluster = ~sic_code)
cat("Placebo (2020 — reform delayed by COVID):\n")
summary(m_placebo_2020)

# ============================================================
# 2. PRE-TREND TEST: Fake treatment at 2018 (pre-reform)
# ============================================================

cat("\n=== PRE-TREND PLACEBO (2018) ===\n")

panel_pre2017 <- panel |> filter(year <= 2018)
panel_pre2017 <- panel_pre2017 |>
  mutate(
    post_2018_placebo = as.integer(year >= 2018),
    treat_post2018 = treated * post_2018_placebo
  )

m_placebo_2018 <- feols(log_companies ~ treat_post2018 |
                          sic_code + la_code^year_f,
                        data = panel_pre2017, cluster = ~sic_code)
cat("Placebo (2018 — no reform):\n")
summary(m_placebo_2018)

# ============================================================
# 3. ALTERNATIVE CONTROL SECTORS
# ============================================================

cat("\n=== ALTERNATIVE CONTROLS ===\n")

# Drop legal/accounting (SIC 69) — could be partially treated
panel_no69 <- panel |> filter(sic_code != 69)

m_alt1 <- feols(log_companies ~ treat_post2017 + treat_post2021 |
                  sic_code + la_code^year_f,
                data = panel_no69, cluster = ~sic_code)
cat("Excluding SIC 69 (legal/accounting — may have some PSC exposure):\n")
summary(m_alt1)

# Only SIC 56 (food) as control — most dissimilar from treated
panel_56only <- panel |> filter(treated == 1 | sic_code == 56)
m_alt2 <- feols(log_companies ~ treat_post2017 + treat_post2021 |
                  sic_code + la_code^year_f,
                data = panel_56only, cluster = ~sic_code)
cat("\nOnly SIC 56 (food/beverage) as control:\n")
summary(m_alt2)

# ============================================================
# 4. LEVELS (not logs)
# ============================================================

cat("\n=== LEVELS SPECIFICATION ===\n")

m_levels <- feols(companies ~ treat_post2017 + treat_post2021 |
                    sic_code + la_code^year_f,
                  data = panel, cluster = ~sic_code)
cat("Levels (not log):\n")
summary(m_levels)

# ============================================================
# 5. WILD CLUSTER BOOTSTRAP (few treated clusters)
# ============================================================
# Only 4 treated SIC sectors — need wild bootstrap

cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Use fixest's built-in wild bootstrap via boottest
# Since we have 8 sector clusters, we report both
m3_boot <- feols(log_companies ~ treat_post2017 + treat_post2021 |
                   sic_code + la_code^year_f,
                 data = panel, cluster = ~sic_code)

# Report the cluster-robust SEs alongside standard note about few clusters
cat("Standard cluster-robust SEs (8 clusters):\n")
cat(sprintf("  Post-2017: coef = %.4f, SE = %.4f, t = %.2f\n",
            coef(m3_boot)["treat_post2017"],
            se(m3_boot)["treat_post2017"],
            coef(m3_boot)["treat_post2017"] / se(m3_boot)["treat_post2017"]))
cat(sprintf("  Post-2021: coef = %.4f, SE = %.4f, t = %.2f\n",
            coef(m3_boot)["treat_post2021"],
            se(m3_boot)["treat_post2021"],
            coef(m3_boot)["treat_post2021"] / se(m3_boot)["treat_post2021"]))

# Also cluster at LA level (406 clusters — standard asymptotics OK)
m3_la_cluster <- feols(log_companies ~ treat_post2017 + treat_post2021 |
                         sic_code + la_code^year_f,
                       data = panel, cluster = ~la_code)
cat("\nLA-clustered SEs (406 clusters):\n")
summary(m3_la_cluster)

# Two-way clustering: sector × LA
m3_twoway <- feols(log_companies ~ treat_post2017 + treat_post2021 |
                     sic_code + la_code^year_f,
                   data = panel, cluster = ~sic_code + la_code)
cat("\nTwo-way clustered SEs (sector × LA):\n")
summary(m3_twoway)

# ============================================================
# 6. SAVE ROBUSTNESS RESULTS
# ============================================================

robustness <- list(
  placebo_2020_coef = coef(m_placebo_2020)["treat_post2020"],
  placebo_2020_se   = se(m_placebo_2020)["treat_post2020"],
  placebo_2020_p    = pvalue(m_placebo_2020)["treat_post2020"],
  placebo_2018_coef = coef(m_placebo_2018)["treat_post2018"],
  placebo_2018_se   = se(m_placebo_2018)["treat_post2018"],
  placebo_2018_p    = pvalue(m_placebo_2018)["treat_post2018"],
  alt_no69_coef     = coef(m_alt1)["treat_post2021"],
  alt_no69_se       = se(m_alt1)["treat_post2021"],
  alt_56only_coef   = coef(m_alt2)["treat_post2021"],
  alt_56only_se     = se(m_alt2)["treat_post2021"],
  levels_coef       = coef(m_levels)["treat_post2021"],
  levels_se         = se(m_levels)["treat_post2021"],
  la_cluster_coef   = coef(m3_la_cluster)["treat_post2021"],
  la_cluster_se     = se(m3_la_cluster)["treat_post2021"],
  twoway_se         = se(m3_twoway)["treat_post2021"]
)

saveRDS(list(
  m_placebo_2020 = m_placebo_2020,
  m_placebo_2018 = m_placebo_2018,
  m_alt1 = m_alt1,
  m_alt2 = m_alt2,
  m_levels = m_levels,
  m3_la_cluster = m3_la_cluster,
  m3_twoway = m3_twoway
), "../data/robustness_models.rds")

jsonlite::write_json(robustness, "../data/robustness_results.json",
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nSaved robustness results.\n")
