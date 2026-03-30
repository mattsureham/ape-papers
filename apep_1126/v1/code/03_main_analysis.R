## ============================================================================
## 03_main_analysis.R — Primary DiD estimation for apep_1126
## Canada Cannabis Legalization and US Border Drug Enforcement
## Main sample: Prohibition states only (drop MI, WA, VT, ME)
## ============================================================================

source("00_packages.R")

DATA    <- "../data"
FIGURES <- "../figures"
dir.create(FIGURES, showWarnings = FALSE, recursive = TRUE)

## ---- 1. Load panel and restrict to prohibition states ----
cat("=== Loading county-quarter panel ===\n")
panel <- as.data.table(read_parquet(file.path(DATA, "county_quarter_panel.parquet")))

## Drop states with legal/medical cannabis prior to or around Oct 2018
## MI (legalized Nov 2018 ballot), WA (legal since 2012), VT (legal Jul 2018),
## ME (legal Jan 2017). Remaining 8 prohibition states.
drop_states <- c("MI", "WA", "VT", "ME")
panel <- panel[!(state_abb %in% drop_states)]

## Use high-coverage counties only
panel_hc <- panel[high_coverage == TRUE & !is.na(drug_rate)]

cat(sprintf("Prohibition-state panel: %s obs, %d counties (%d border, %d interior)\n",
            format(nrow(panel_hc), big.mark = ","),
            uniqueN(panel_hc$fips),
            uniqueN(panel_hc[is_border == TRUE, fips]),
            uniqueN(panel_hc[is_border == FALSE, fips])))
cat(sprintf("States: %s\n", paste(sort(unique(panel_hc$state_abb)), collapse = ", ")))

## ---- 2. Create variables ----
panel_hc[, border := as.numeric(is_border)]
panel_hc[, border_post   := border * post_legal]
panel_hc[, border_covid  := border * covid_closed]
panel_hc[, border_reopen := border * post_reopen]

## State-by-quarter FE identifier
panel_hc[, state_yq := paste0(state_abb, "_", year_quarter)]

## Continuous exposure interactions
panel_hc[, exp_post   := exposure_std * post_legal]
panel_hc[, exp_covid  := exposure_std * covid_closed]
panel_hc[, exp_reopen := exposure_std * post_reopen]

## ---- 3. Main specification: UNWEIGHTED three-regime DiD ----
cat("\n=== Spec 1 (MAIN): Unweighted binary border x three regimes ===\n")
spec1 <- feols(
  drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_hc,
  cluster = ~state_abb
)
summary(spec1)

## ---- 4. Secondary specification: WEIGHTED three-regime DiD ----
cat("\n=== Spec 2: Population-weighted binary border x three regimes ===\n")
spec2 <- feols(
  drug_rate ~ border_post + border_covid + border_reopen |
    fips + state_yq,
  data = panel_hc,
  cluster = ~state_abb,
  weights = ~reporting_pop
)
summary(spec2)

## ---- 5. Continuous-exposure specification ----
cat("\n=== Spec 3: Continuous exposure x three regimes (unweighted) ===\n")
spec3 <- feols(
  drug_rate ~ exp_post + exp_covid + exp_reopen |
    fips + state_yq,
  data = panel_hc,
  cluster = ~state_abb
)
summary(spec3)

## ---- 6. Event Study (unweighted, binary border x event-time) ----
cat("\n=== Event Study ===\n")

## Trim extreme event times
panel_hc_es <- panel_hc[event_time >= -16 & event_time <= 20]

es1 <- feols(
  drug_rate ~ i(event_time, is_border, ref = -1) |
    fips + state_yq,
  data = panel_hc_es,
  cluster = ~state_abb
)
cat("Event study coefficients:\n")
es_coefs <- coeftable(es1)
print(es_coefs)

## Save event study coefficients
es_dt <- data.table(
  event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_coefs))),
  estimate   = es_coefs[, "Estimate"],
  se         = es_coefs[, "Std. Error"],
  pval       = es_coefs[, "Pr(>|t|)"]
)
es_dt[, ci_lower := estimate - 1.96 * se]
es_dt[, ci_upper := estimate + 1.96 * se]
fwrite(es_dt, file.path(DATA, "event_study_coefs.csv"))

## ---- 7. Event-study figure ----
cat("\n=== Generating event-study figure ===\n")
es_plot <- ggplot(es_dt, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 0, linetype = "dotted", color = "red", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.18, fill = "steelblue") +
  geom_point(size = 1.8, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.5) +
  labs(
    x = "Quarters relative to Canadian Cannabis Act (2018 Q4)",
    y = "Coefficient (drug arrests per 100k)",
    title = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(FIGURES, "event_study.pdf"), es_plot,
       width = 7, height = 4.5)
cat("  Saved: figures/event_study.pdf\n")

## ---- 8. Save results ----
cat("\n=== Saving results ===\n")

results <- list(
  spec1_unweighted = list(
    beta_post_legal = unname(coef(spec1)["border_post"]),
    beta_covid      = unname(coef(spec1)["border_covid"]),
    beta_reopen     = unname(coef(spec1)["border_reopen"]),
    se_post_legal   = unname(se(spec1)["border_post"]),
    se_covid        = unname(se(spec1)["border_covid"]),
    se_reopen       = unname(se(spec1)["border_reopen"]),
    n_obs           = nobs(spec1),
    n_counties      = uniqueN(panel_hc$fips),
    n_border        = uniqueN(panel_hc[is_border == TRUE, fips]),
    r2_within       = fitstat(spec1, "wr2")$wr2
  ),
  spec2_weighted = list(
    beta_post_legal = unname(coef(spec2)["border_post"]),
    beta_covid      = unname(coef(spec2)["border_covid"]),
    beta_reopen     = unname(coef(spec2)["border_reopen"]),
    se_post_legal   = unname(se(spec2)["border_post"]),
    se_covid        = unname(se(spec2)["border_covid"]),
    se_reopen       = unname(se(spec2)["border_reopen"])
  ),
  spec3_continuous = list(
    beta_post_legal = unname(coef(spec3)["exp_post"]),
    beta_covid      = unname(coef(spec3)["exp_covid"]),
    beta_reopen     = unname(coef(spec3)["exp_reopen"]),
    se_post_legal   = unname(se(spec3)["exp_post"]),
    se_covid        = unname(se(spec3)["exp_covid"]),
    se_reopen       = unname(se(spec3)["exp_reopen"])
  )
)

jsonlite::write_json(results, file.path(DATA, "main_results.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete (prohibition states) ===\n")
cat(sprintf("Key results (MAIN — unweighted):\n"))
cat(sprintf("  beta(border x post-legal):  %7.3f  (SE: %.3f)\n",
            results$spec1_unweighted$beta_post_legal,
            results$spec1_unweighted$se_post_legal))
cat(sprintf("  beta(border x COVID closed):%7.3f  (SE: %.3f)\n",
            results$spec1_unweighted$beta_covid,
            results$spec1_unweighted$se_covid))
cat(sprintf("  beta(border x post-reopen): %7.3f  (SE: %.3f)\n",
            results$spec1_unweighted$beta_reopen,
            results$spec1_unweighted$se_reopen))
cat(sprintf("\nKey results (weighted):\n"))
cat(sprintf("  beta(border x post-legal):  %7.3f  (SE: %.3f)\n",
            results$spec2_weighted$beta_post_legal,
            results$spec2_weighted$se_post_legal))
