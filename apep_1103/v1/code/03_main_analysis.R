## 03_main_analysis.R — Main econometric analysis for apep_1103
## Design: Dose-response DiD using pre-reform DI rate as treatment intensity
##
## Logic: Switzerland's IV reforms (2008, 2012) targeted disability prevention.
## Cantons with higher pre-reform DI burdens were more exposed to the reforms.
## We interact the cross-cantonal DI rate (measured in 2009, highly persistent)
## with year dummies to trace the dynamic effect on OKP health costs.

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel.rds"))

# ══════════════════════════════════════════════════════════════════════════════
# Construct treatment dose: DI rate in 2009 (earliest available, 1yr post first reform)
# DI stock is highly persistent → 2009 cross-section reflects pre-reform distribution
# ══════════════════════════════════════════════════════════════════════════════
di_dose <- panel |>
  filter(year == 2009, !is.na(di_rate)) |>
  select(canton, di_rate_2009 = di_rate)

cat("DI rate 2009 distribution:\n")
print(summary(di_dose$di_rate_2009))

# Standardize dose for interpretability (mean = 0, SD = 1)
di_dose <- di_dose |>
  mutate(di_dose_std = (di_rate_2009 - mean(di_rate_2009)) / sd(di_rate_2009))

# ══════════════════════════════════════════════════════════════════════════════
# Analysis sample: 2000-2022 (full pre/post period)
# ══════════════════════════════════════════════════════════════════════════════
df <- panel |>
  filter(year >= 2000, year <= 2022, !is.na(okp_total_pc)) |>
  left_join(di_dose, by = "canton") |>
  filter(!is.na(di_rate_2009)) |>
  mutate(
    rel_year = year - 2008,
    rel_year_binned = case_when(
      rel_year <= -7 ~ -7L,
      rel_year >= 12 ~ 12L,
      TRUE ~ as.integer(rel_year)
    )
  )

cat("\nAnalysis sample: ", nrow(df), " observations\n")
cat("  Cantons: ", length(unique(df$canton)), "\n")
cat("  Years: ", range(df$year), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 1: SUMMARY STATISTICS
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Summary Statistics ──\n")

# Pre-reform (2000-2007) and post-reform (2008-2022) comparison
summ_pre <- df |>
  filter(year <= 2007) |>
  summarise(
    across(c(okp_total_pc),
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)))
  )

summ_post <- df |>
  filter(year >= 2008) |>
  summarise(
    across(c(okp_total_pc),
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)))
  )

summ_full <- df |>
  summarise(
    okp_mean = mean(okp_total_pc, na.rm = TRUE),
    okp_sd = sd(okp_total_pc, na.rm = TRUE),
    okp_min = min(okp_total_pc, na.rm = TRUE),
    okp_max = max(okp_total_pc, na.rm = TRUE),
    di_rate_2009_mean = mean(di_rate_2009, na.rm = TRUE),
    di_rate_2009_sd = sd(di_rate_2009, na.rm = TRUE),
    n_obs = n(),
    n_cantons = n_distinct(canton),
    n_years = n_distinct(year)
  )

cat("  OKP mean:", round(summ_full$okp_mean, 1), "CHF/insured\n")
cat("  OKP SD:", round(summ_full$okp_sd, 1), "\n")
cat("  DI rate 2009 mean:", round(summ_full$di_rate_2009_mean, 2), "per 1000\n")

# ══════════════════════════════════════════════════════════════════════════════
# MAIN SPECIFICATION: Dose-response DiD
# OKP_ct = α_c + δ_t + β(DI_rate_2009_c × Post2008_t) + ε_ct
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Main Specification: Dose-Response DiD ──\n")

# (1) DI dose × post-2008
m1 <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
            data = df, cluster = ~canton_id)

# (2) Log specification
m2 <- feols(log_okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
            data = df, cluster = ~canton_id)

# (3) DI dose × post-2008 + DI dose × post-2012 (two reforms)
m3 <- feols(okp_total_pc ~ di_rate_2009:post_2008 + di_rate_2009:post_2012 |
              canton_id + year,
            data = df, cluster = ~canton_id)

# (4) Standardized dose for cleaner interpretation
m4 <- feols(okp_total_pc ~ di_dose_std:post_2008 | canton_id + year,
            data = df, cluster = ~canton_id)

# (5) Log + standardized
m5 <- feols(log_okp_total_pc ~ di_dose_std:post_2008 | canton_id + year,
            data = df, cluster = ~canton_id)

cat("  (1) DI dose × Post08: beta =", round(coef(m1)[1], 3),
    " SE =", round(se(m1)[1], 3), "\n")
cat("  (2) Log: beta =", round(coef(m2)[1], 5),
    " SE =", round(se(m2)[1], 5), "\n")
cat("  (3) Two reforms: beta08 =", round(coef(m3)[1], 3),
    " beta12 =", round(coef(m3)[2], 3), "\n")
cat("  (4) Std dose × Post08: beta =", round(coef(m4)[1], 2),
    " SE =", round(se(m4)[1], 2), "\n")
cat("  (5) Log std: beta =", round(coef(m5)[1], 5),
    " SE =", round(se(m5)[1], 5), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# EVENT STUDY: DI_rate_2009 × year dummies (omit 2007)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Event Study ──\n")

es_model <- feols(okp_total_pc ~ i(rel_year_binned, di_rate_2009, ref = -1) |
                    canton_id + year,
                  data = df, cluster = ~canton_id)

es_log <- feols(log_okp_total_pc ~ i(rel_year_binned, di_rate_2009, ref = -1) |
                  canton_id + year,
                data = df, cluster = ~canton_id)

# Extract coefficients
es_coefs <- as.data.frame(summary(es_model)$coeftable)
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs |>
  mutate(
    rel_year = as.integer(gsub("rel_year_binned::(-?\\d+):.*", "\\1", term)),
    estimate = Estimate,
    se = `Std. Error`,
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  ) |>
  filter(!is.na(rel_year))

cat("  Pre-reform coefficients (should be near zero):\n")
print(es_coefs |> filter(rel_year < 0) |> select(rel_year, estimate, se))
cat("  Post-reform coefficients:\n")
print(es_coefs |> filter(rel_year >= 0) |> select(rel_year, estimate, se))

# ══════════════════════════════════════════════════════════════════════════════
# FIRST STAGE: DI dose × Post → integration intensity and DI rate changes
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── First Stage: Reform Exposure → Integration Uptake and DI Changes ──\n")

df_integ <- df |> filter(!is.na(integ_intensity))

# High-dose cantons adopted more integration measures
fs_integ <- feols(integ_intensity ~ di_rate_2009:post_2008 | canton_id + year,
                  data = df_integ, cluster = ~canton_id)

cat("  DI dose × Post08 → Integration intensity: beta =",
    round(coef(fs_integ)[1], 4), " SE =", round(se(fs_integ)[1], 4), "\n")

# DI rate response (only 2009+ data)
df_di <- df |> filter(!is.na(di_rate), year >= 2009)
if (nrow(df_di) > 50) {
  fs_di <- feols(di_rate ~ di_rate_2009:I(year - 2009) | canton_id + year,
                 data = df_di, cluster = ~canton_id)
  cat("  DI dose × Trend → DI rate: beta =",
      round(coef(fs_di)[1], 4), " SE =", round(se(fs_di)[1], 4), "\n")
}

# ══════════════════════════════════════════════════════════════════════════════
# COST DECOMPOSITION: Which health cost categories respond?
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Cost Decomposition ──\n")

cost_vars <- c("okp_ambulatory_hospital", "okp_inpatient_hospital", "okp_pharmacy",
               "okp_nursing_home", "okp_physician", "okp_physiotherapy", "okp_home_care")
cost_labels <- c("Ambulatory hospital", "Inpatient hospital", "Pharmacy",
                 "Nursing homes", "Physician", "Physiotherapy", "Home care")

decomp_results <- list()
for (i in seq_along(cost_vars)) {
  cv <- cost_vars[i]
  if (!cv %in% names(df) || all(is.na(df[[cv]]))) next
  form <- as.formula(paste0(cv, " ~ di_rate_2009:post_2008 | canton_id + year"))
  fit <- feols(form, data = df, cluster = ~canton_id)
  decomp_results[[cost_labels[i]]] <- tibble(
    cost_type = cost_labels[i],
    beta = coef(fit)[1],
    se = se(fit)[1],
    pval = pvalue(fit)[1],
    mean_y = mean(df[[cv]], na.rm = TRUE),
    pct_effect = coef(fit)[1] / mean(df[[cv]], na.rm = TRUE) * mean(df$di_rate_2009)
  )
}

decomp_df <- bind_rows(decomp_results)
cat("  Decomposition results:\n")
print(decomp_df, width = 120)

# ══════════════════════════════════════════════════════════════════════════════
# HETEROGENEITY: Language region split (German vs French/Italian)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Heterogeneity: Language Region ──\n")

# German-speaking cantons
german_cantons <- c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG",
                    "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG")
french_cantons <- c("FR", "VD", "VS", "NE", "GE", "JU", "TI")

df$german <- as.integer(df$canton %in% german_cantons)

m_german <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
                  data = df |> filter(german == 1), cluster = ~canton_id)
m_latin <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
                 data = df |> filter(german == 0), cluster = ~canton_id)

cat("  German-speaking: beta =", round(coef(m_german)[1], 3),
    " SE =", round(se(m_german)[1], 3),
    " N =", sum(df$german == 1), "\n")
cat("  French/Italian: beta =", round(coef(m_latin)[1], 3),
    " SE =", round(se(m_latin)[1], 3),
    " N =", sum(df$german == 0), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# HETEROGENEITY: High vs Low pre-reform DI rate cantons
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Heterogeneity: High vs Low pre-reform OKP cost cantons ──\n")

# Split by pre-reform (2000-2007) average OKP cost level
pre_okp <- df |>
  filter(year <= 2007) |>
  group_by(canton) |>
  summarise(pre_okp_mean = mean(okp_total_pc, na.rm = TRUE), .groups = "drop")

df <- df |> left_join(pre_okp, by = "canton")
df$high_cost <- as.integer(df$pre_okp_mean > median(pre_okp$pre_okp_mean))

m_high_cost <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
                     data = df |> filter(high_cost == 1), cluster = ~canton_id)
m_low_cost <- feols(okp_total_pc ~ di_rate_2009:post_2008 | canton_id + year,
                    data = df |> filter(high_cost == 0), cluster = ~canton_id)

cat("  High-cost cantons: beta =", round(coef(m_high_cost)[1], 3),
    " SE =", round(se(m_high_cost)[1], 3), "\n")
cat("  Low-cost cantons: beta =", round(coef(m_low_cost)[1], 3),
    " SE =", round(se(m_low_cost)[1], 3), "\n")

# ══════════════════════════════════════════════════════════════════════════════
# Save results
# ══════════════════════════════════════════════════════════════════════════════
results <- list(
  main = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
  event_study = list(model = es_model, log_model = es_log, coefs = es_coefs),
  first_stage = list(integ = fs_integ),
  decomposition = list(summary = decomp_df),
  heterogeneity = list(
    german = m_german, latin = m_latin,
    high_cost = m_high_cost, low_cost = m_low_cost
  ),
  summary_stats = summ_full,
  di_dose = di_dose,
  data = list(df = df)
)

saveRDS(results, file.path(data_dir, "results.rds"))
cat("\n  Saved results.rds\n")

# Diagnostics for validation
diagnostics <- list(
  n_treated = length(unique(df$canton)),
  n_pre = length(unique(df$year[df$year < 2008])),
  n_obs = nrow(df)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("  Wrote diagnostics.json: n_treated =", diagnostics$n_treated,
    ", n_pre =", diagnostics$n_pre, ", n_obs =", diagnostics$n_obs, "\n")
