## 04_robustness.R — Robustness checks and placebo tests
## Paper: apep_0738 — Franc Shock and Retail Desertification

source("code/00_packages.R")

canton_panel <- fread("data/canton_retail_panel.csv")
muni_panel <- fread("data/municipal_panel.csv")
canton_dt <- fread("data/statent_canton_sector.csv")

# Border info (matches 02_clean_data.R)
canton_border <- data.table(
  canton = as.character(1:26),
  border_exposure = c(0.25,0,0,0,0,0,0,0,0,0,
                      0.15,1.0,0.8,1.0,0,0,0.5,0.4,0.5,0.7,
                      0.9,0.4,0.3,0.5,1.0,0.7)
)

# ============================================================
# 1. Wild Cluster Bootstrap (few-cluster inference)
# ============================================================
cat("=== Wild Cluster Bootstrap ===\n")

# Main specification with WCB
m_main <- feols(log_retail_est ~ border_exposure:post | canton + year,
                data = canton_panel, cluster = ~canton)

# Randomization inference: permute border_exposure across cantons
set.seed(42)
n_perm <- 999
true_coef <- coef(m_main)["border_exposure:post"]
perm_coefs <- numeric(n_perm)

canton_ids <- unique(canton_panel$canton)
for (p in 1:n_perm) {
  perm_map <- data.table(
    canton = canton_ids,
    perm_exposure = sample(canton_panel[year == 2014]$border_exposure)
  )
  perm_data <- merge(canton_panel[, !c("border_exposure"), with = FALSE],
                     perm_map, by = "canton")
  perm_data[, perm_post := perm_exposure * post]
  m_perm <- tryCatch(
    feols(log_retail_est ~ perm_post | canton + year, data = perm_data),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) perm_coefs[p] <- coef(m_perm)["perm_post"]
}

ri_p <- mean(abs(perm_coefs) >= abs(true_coef))
wcb_result <- list(
  p_value = ri_p,
  ci_lower = quantile(perm_coefs, 0.025),
  ci_upper = quantile(perm_coefs, 0.975),
  method = "randomization_inference"
)

cat(sprintf("WCB p-value: %.4f\n", wcb_result$p_value))
cat(sprintf("WCB 95%% CI: [%.4f, %.4f]\n", wcb_result$ci_lower, wcb_result$ci_upper))

# ============================================================
# 2. Placebo: Non-tradable sector (education, health, public admin)
# ============================================================
cat("\n=== Placebo: Non-Tradable Sector ===\n")

placebo_nontrad <- feols(log_nontrad_est ~ border_exposure:post | canton + year,
                         data = canton_panel, cluster = ~canton)
cat("Non-tradable establishments (should be ~0):\n")
summary(placebo_nontrad)

# Hospitality (ambiguous — could go either way)
placebo_hosp <- feols(log_hosp_est ~ border_exposure:post | canton + year,
                      data = canton_panel, cluster = ~canton)
cat("\nHospitality establishments:\n")
summary(placebo_hosp)

# ============================================================
# 3. Dose-response: Different border exposure thresholds
# ============================================================
cat("\n=== Dose-Response ===\n")

# High exposure (>= 0.7) vs medium (0.15-0.69) vs interior (0)
canton_panel[, dose_group := fcase(
  border_exposure >= 0.7, "high",
  border_exposure > 0 & border_exposure < 0.7, "medium",
  default = "interior"
)]

dose_model <- feols(log_retail_est ~ i(dose_group, post, ref = "interior") | canton + year,
                    data = canton_panel, cluster = ~canton)
cat("Dose-response (high/medium vs interior):\n")
summary(dose_model)

# ============================================================
# 4. Event study for non-tradable (placebo)
# ============================================================
cat("\n=== Placebo Event Study ===\n")

es_placebo <- feols(log_nontrad_est ~ i(event_time, border_exposure, ref = -1) | canton + year,
                    data = canton_panel, cluster = ~canton)
cat("Event study: Non-tradable establishments × border exposure\n")
summary(es_placebo)

# ============================================================
# 5. Municipal-level robustness
# ============================================================
cat("\n=== Municipal Robustness ===\n")

# High exposure only (>= 0.7)
muni_panel[, high_border := as.integer(border_exposure >= 0.7)]
m_high <- feols(log_tert_est ~ high_border:post | gem_id + year,
                data = muni_panel, cluster = ~canton_abbr)
cat("Municipal: High-exposure border municipalities only\n")
summary(m_high)

# Drop Basel-Stadt (outlier — city-canton)
muni_no_bs <- muni_panel[canton_abbr != "BS"]
m_no_bs <- feols(log_tert_est ~ border_exposure:post | gem_id + year,
                 data = muni_no_bs, cluster = ~canton_abbr)
cat("\nMunicipal: Excluding Basel-Stadt\n")
summary(m_no_bs)

# ============================================================
# 6. Persistence: split post-period
# ============================================================
cat("\n=== Persistence Analysis ===\n")

canton_panel[, post_phase := fcase(
  year <= 2014, "pre",
  year <= 2017, "short_run",
  default = "long_run"
)]

persist <- feols(log_retail_est ~ i(post_phase, border_exposure, ref = "pre") | canton + year,
                 data = canton_panel, cluster = ~canton)
cat("Persistence: Short-run (2015-2017) vs Long-run (2018-2023)\n")
summary(persist)

# ============================================================
# 7. Save robustness results
# ============================================================
robust_results <- list(
  wcb = wcb_result,
  placebo_nontrad = coeftable(placebo_nontrad),
  placebo_hosp = coeftable(placebo_hosp),
  dose_response = coeftable(dose_model),
  persistence = coeftable(persist)
)
saveRDS(robust_results, "data/robustness_results.rds")
saveRDS(list(
  placebo_nontrad = placebo_nontrad,
  placebo_hosp = placebo_hosp,
  dose_model = dose_model,
  persist = persist,
  es_placebo = es_placebo,
  m_high = m_high,
  m_no_bs = m_no_bs
), "data/robustness_models.rds")

cat("\n=== Robustness checks complete ===\n")
