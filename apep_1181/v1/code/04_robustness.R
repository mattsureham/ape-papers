# 04_robustness.R — Robustness checks for clawback threshold analysis

source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "models.RData"))

# ============================================================
# 1. Pre-trends: event-study-style comparison across years
# ============================================================
cat("=== PRE-TRENDS CHECK (2021 reform) ===\n\n")

df_2021[, year_f := factor(year)]

m_event <- feols(mean_export_mw ~ i(year_f, treated_2021, ref = "2020") |
                   neighbor + year_f,
                 data = df_2021, vcov = ~yearmonth)

cat("Event-study coefficients (ref = 2020):\n")
print(coeftable(m_event))

# Joint F-test for pre-period coefficient = 0
cat("\nJoint F-test for pre-trends (2019 only):\n")
pre_coef <- coef(m_event)["year_f::2019:treated_2021"]
pre_se <- se(m_event)["year_f::2019:treated_2021"]
f_stat <- (pre_coef / pre_se)^2
p_val <- 2 * pnorm(-abs(pre_coef / pre_se))
cat(sprintf("  F-stat: %.2f, p-value: %.3f\n", f_stat, p_val))
cat("  (Only one pre-period coefficient — t-test equivalent)\n")

# ============================================================
# 2. Placebo reform: fake treatment at 2020 (should show no effect)
# ============================================================
cat("\n=== PLACEBO: fake reform at 2020 ===\n\n")

df_placebo <- df_2021[year <= 2020]
df_placebo[, fake_post := as.integer(year >= 2020)]
df_placebo[, fake_did := treated_2021 * fake_post]

m_placebo <- feols(mean_export_mw ~ fake_did + treated_2021 | neighbor + yearmonth,
                   data = df_placebo, vcov = ~yearmonth)
cat("Placebo result (fake reform at 2020):\n")
etable(m_placebo, se.below = TRUE)

# ============================================================
# 3. Alternative clustering
# ============================================================
cat("\n=== ALTERNATIVE CLUSTERING ===\n\n")

m_ep_clust <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
                    data = df_2021, vcov = ~episode_id)

cat("Episode-level clustering (2021 reform):\n")
etable(m_ep_clust, se.below = TRUE)

m_twoway <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
                  data = df_2021, vcov = ~yearmonth + neighbor)

cat("\nTwo-way clustering (yearmonth + neighbor):\n")
etable(m_twoway, se.below = TRUE)

# ============================================================
# 4. Alternative outcomes
# ============================================================
cat("\n=== ALTERNATIVE OUTCOMES ===\n\n")

m_total <- feols(total_export_mwh ~ did_2021 + treated_2021 | neighbor + yearmonth,
                 data = df_2021, vcov = ~yearmonth)
cat("Total MWh outcome:\n")
etable(m_total, se.below = TRUE)

df_2021[, asinh_export := asinh(mean_export_mw)]
m_log <- feols(asinh_export ~ did_2021 + treated_2021 | neighbor + yearmonth,
               data = df_2021, vcov = ~yearmonth)
cat("Asinh(export) outcome:\n")
etable(m_log, se.below = TRUE)

# ============================================================
# 5. Exclude COVID period
# ============================================================
cat("\n=== EXCLUDE COVID PERIOD ===\n\n")

df_nocovid <- df_2021[!(year %in% c(2020, 2021))]
df_nocovid[, post_nocovid := as.integer(year >= 2022)]
df_nocovid[, did_nocovid := treated_2021 * post_nocovid]

m_nocovid <- feols(mean_export_mw ~ did_nocovid + treated_2021 | neighbor + yearmonth,
                   data = df_nocovid, vcov = ~yearmonth)
cat("Excluding 2020-2021:\n")
etable(m_nocovid, se.below = TRUE)

# ============================================================
# 6. Neighbor clawback stringency heterogeneity
# ============================================================
cat("\n=== NEIGHBOR CLAWBACK STRINGENCY ===\n\n")

# Classification of neighbor clawback rules:
# Strict: Netherlands (any negative hour), Italy (no negatives pre-2025)
# Moderate: Denmark, Belgium (varying rules)
# Lenient: Austria, France, Luxembourg, Poland, Czechia, Norway, Sweden, Switzerland
# (these have longer thresholds or no explicit clawback)
strict_cb <- c("Netherlands")  # NL has strictest: any negative hour
moderate_cb <- c("Denmark", "Belgium")

df_2021[, cb_stringency := fcase(
  neighbor %in% strict_cb, "strict",
  neighbor %in% moderate_cb, "moderate",
  !neighbor %in% c(strict_cb, moderate_cb), "lenient"
)]

m_strict <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
                  data = df_2021[cb_stringency == "strict"], vcov = ~yearmonth)
m_lenient <- feols(mean_export_mw ~ did_2021 + treated_2021 | neighbor + yearmonth,
                   data = df_2021[cb_stringency == "lenient"], vcov = ~yearmonth)

cat("Strict clawback neighbors (NL):\n")
etable(m_strict, se.below = TRUE)
cat("\nLenient clawback neighbors:\n")
etable(m_lenient, se.below = TRUE)

# Interaction
df_2021[, strict_nb := as.integer(cb_stringency == "strict")]
m_cb_interact <- feols(mean_export_mw ~ did_2021 * strict_nb + treated_2021 |
                         neighbor + yearmonth,
                       data = df_2021, vcov = ~yearmonth)
cat("\nClawback stringency interaction:\n")
etable(m_cb_interact, se.below = TRUE)

# ============================================================
# 7. Power analysis
# ============================================================
cat("\n=== POWER ANALYSIS ===\n\n")

se_main <- se(m2)["did_2021"]
mde <- 2.8 * se_main
sd_y <- sd(df_2021[post_2021 == 0]$mean_export_mw)
pre_mean <- mean(df_2021[post_2021 == 0]$mean_export_mw)

cat(sprintf("SE of main estimate: %.1f MW\n", se_main))
cat(sprintf("MDE at 80%% power: %.1f MW\n", mde))
cat(sprintf("  as %% of pre-treatment SD: %.1f%%\n", 100 * mde / sd_y))
cat(sprintf("  as %% of pre-treatment mean: %.1f%%\n", 100 * mde / abs(pre_mean)))
cat(sprintf("95%% CI lower bound: %.1f MW\n", coef(m2)["did_2021"] - 1.96 * se_main))
cat(sprintf("Can rule out reductions > %.1f MW (%.1f%% of baseline)\n",
            abs(coef(m2)["did_2021"] - 1.96 * se_main),
            100 * abs(coef(m2)["did_2021"] - 1.96 * se_main) / pre_mean))

# Save robustness models
save(m_event, m_placebo, m_ep_clust, m_twoway, m_total, m_log, m_nocovid,
     m_strict, m_lenient, m_cb_interact,
     file = file.path(data_dir, "models_robust.RData"))

cat("\n=== Robustness checks complete ===\n")
