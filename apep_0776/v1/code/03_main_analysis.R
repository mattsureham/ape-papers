# ==============================================================================
# 03_main_analysis.R — Primary Regressions
# Paper: Working Themselves to Death? (apep_0776)
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
panel_placebo <- readRDS("../data/panel_placebo.rds")
fornero_bite <- readRDS("../data/fornero_bite.rds")

# ---- 1. Main specification: death rate ~ fbite × post ----
cat("--- Main Specification ---\n")

# Panel A: Both sexes pooled
fit_main <- feols(log_death_rate ~ treat | geo + year,
                  data = panel, cluster = ~geo)
cat(sprintf("  Pooled: coef=%.5f, SE=%.5f, p=%.4f\n",
            coef(fit_main)["treat"],
            sqrt(vcov(fit_main)["treat", "treat"]),
            fixest::pvalue(fit_main)["treat"]))

# Panel B: By sex
fit_male <- feols(log_death_rate ~ treat | geo + year,
                  data = filter(panel, sex == "M"), cluster = ~geo)
fit_female <- feols(log_death_rate ~ treat | geo + year,
                    data = filter(panel, sex == "F"), cluster = ~geo)

cat(sprintf("  Male: coef=%.5f, SE=%.5f, p=%.4f\n",
            coef(fit_male)["treat"],
            sqrt(vcov(fit_male)["treat", "treat"]),
            fixest::pvalue(fit_male)["treat"]))
cat(sprintf("  Female: coef=%.5f, SE=%.5f, p=%.4f\n",
            coef(fit_female)["treat"],
            sqrt(vcov(fit_female)["treat", "treat"]),
            fixest::pvalue(fit_female)["treat"]))

# ---- 2. Event study ----
cat("\n--- Event Study ---\n")

panel_es <- panel %>%
  mutate(
    event_time = year - 2012,
    event_time_f = relevel(factor(event_time), ref = "-1"),
    treat_es = fbite * as.numeric(as.character(event_time_f))
  )

# Direct event study: interact fbite with year dummies
fit_es <- feols(log_death_rate ~ i(year, fbite, ref = 2011) | geo + sex,
                data = panel, cluster = ~geo)

cat("  Event study coefficients:\n")
es_coefs <- coef(fit_es)
es_ses   <- sqrt(diag(vcov(fit_es)))
for (j in seq_along(es_coefs)) {
  nm <- names(es_coefs)[j]
  cat(sprintf("    %s: %.5f (%.5f)\n", nm, es_coefs[j], es_ses[j]))
}

# ---- 3. Gender dose-response (DDD) ----
cat("\n--- Gender Dose-Response (DDD) ---\n")

fit_ddd <- feols(log_death_rate ~ treat:female + treat | geo + year + sex,
                 data = panel, cluster = ~geo)
cat(sprintf("  DDD (female×treat): coef=%.5f, SE=%.5f, p=%.4f\n",
            coef(fit_ddd)["treat:female"],
            sqrt(vcov(fit_ddd)["treat:female", "treat:female"]),
            fixest::pvalue(fit_ddd)["treat:female"]))

# ---- 4. Age placebo: 45-54 should show no effect ----
cat("\n--- Age Placebo (45-54) ---\n")

panel_placebo <- panel_placebo %>%
  mutate(log_death_rate = log(death_rate_45_54))

fit_placebo <- feols(log_death_rate ~ treat | geo + year,
                     data = panel_placebo, cluster = ~geo)
cat(sprintf("  Placebo (45-54): coef=%.5f, SE=%.5f, p=%.4f\n",
            coef(fit_placebo)["treat"],
            sqrt(vcov(fit_placebo)["treat", "treat"]),
            fixest::pvalue(fit_placebo)["treat"]))

# ---- 5. Save results ----
results <- list(
  main = fit_main,
  male = fit_male,
  female = fit_female,
  event_study = fit_es,
  ddd = fit_ddd,
  placebo = fit_placebo
)
saveRDS(results, "../data/main_results.rds")

# ---- 6. Diagnostics ----
diag <- list(
  n_treated = n_distinct(panel$geo),
  n_pre = length(unique(panel$year[panel$year < 2012])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\nMain analysis complete.\n")
