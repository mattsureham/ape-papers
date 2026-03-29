## 03_main_analysis.R — Main DiD estimation and event study
## APEP-1112: The Alliance Ratchet
##
## Estimates the formation and dissolution effects on fares,
## tests for asymmetry (the "ratchet"), and produces event study coefficients.

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
cat(sprintf("Loaded panel: %s obs, %d routes\n",
            format(nrow(panel), big.mark = ","), uniqueN(panel$route)))

## ============================================================
## 1. Main DiD: Two-shock specification
## ============================================================
cat("\n=== Main DiD Specification ===\n")

## Specification: log(fare) = route FE + quarter FE + beta1*(treated x formation)
##                + beta2*(treated x dissolution) + controls + epsilon
## The "ratchet" test is whether beta2 + beta1 = 0 (i.e., full reversion)

## Main specification with route and year-quarter FE
main_did <- feols(
  log_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq
)

cat("\n--- Main Result ---\n")
summary(main_did)

## Extract coefficients
beta_form <- coef(main_did)["treated:formation"]
beta_diss <- coef(main_did)["treated:dissolution"]
se_form <- se(main_did)["treated:formation"]
se_diss <- se(main_did)["treated:dissolution"]

cat(sprintf("\nFormation effect (beta1): %.4f (SE: %.4f)\n", beta_form, se_form))
cat(sprintf("Dissolution effect (beta2): %.4f (SE: %.4f)\n", beta_diss, se_diss))
cat(sprintf("Sum (beta1 + beta2) = ratchet: %.4f\n", beta_form + beta_diss))
cat(sprintf("  Interpretation: If sum > 0, fares did NOT fully revert → ratchet exists\n"))

## ---- Asymmetry (ratchet) test: H0: beta1 + beta2 = 0 ----
## Compute manually since wald() syntax varies across fixest versions
ratchet_val <- beta_form + beta_diss
ratchet_var <- vcov(main_did)["treated:formation", "treated:formation"] +
  vcov(main_did)["treated:dissolution", "treated:dissolution"] +
  2 * vcov(main_did)["treated:formation", "treated:dissolution"]
ratchet_se_main <- sqrt(ratchet_var)
ratchet_t <- ratchet_val / ratchet_se_main
ratchet_p <- 2 * pt(-abs(ratchet_t), df = nobs(main_did) - 2)
cat(sprintf("\nRatchet test: sum = %.4f, SE = %.4f, t = %.2f, p = %.4f\n",
            ratchet_val, ratchet_se_main, ratchet_t, ratchet_p))

## ============================================================
## 2. Event Study — quarter-by-quarter coefficients
## ============================================================
cat("\n=== Event Study ===\n")

## Create event-time indicators
## Baseline: q_index == 0 (Q4 2020, last pre-NEA quarter)
panel[, event_time := factor(q_index)]

## Drop the baseline (q_index == 0)
es_did <- feols(
  log_fare ~ i(q_index, treated, ref = 0) | route + yq,
  data = panel,
  cluster = ~route + yq
)

cat("Event study estimated.\n")
summary(es_did)

## ============================================================
## 3. Passenger-weighted specification
## ============================================================
cat("\n=== Passenger-Weighted Specification ===\n")

weighted_did <- feols(
  log_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq,
  weights = ~total_pax
)
summary(weighted_did)

## ============================================================
## 4. Mechanisms: HHI, carrier count, B6/AA shares
## ============================================================
cat("\n=== Mechanism: Market Structure ===\n")

## HHI
hhi_did <- feols(
  hhi ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq
)
cat("HHI:\n")
summary(hhi_did)

## Number of carriers
ncarrier_did <- feols(
  n_carriers ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq
)
cat("\nNumber of carriers:\n")
summary(ncarrier_did)

## Passenger volume
pax_did <- feols(
  log_pax ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq
)
cat("\nLog passengers:\n")
summary(pax_did)

## ============================================================
## 5. Heterogeneity: Nonstop vs connecting routes
## ============================================================
cat("\n=== Heterogeneity: Nonstop-heavy vs Connecting routes ===\n")

## Split by median pre-NEA nonstop share
pre_nonstop <- panel[period == "pre", .(avg_nonstop = mean(nonstop_share)), by = route]
med_nonstop <- median(pre_nonstop$avg_nonstop)
high_nonstop_routes <- pre_nonstop[avg_nonstop >= med_nonstop, route]

panel[, high_nonstop := as.integer(route %in% high_nonstop_routes)]

hetero_nonstop <- feols(
  log_fare ~ treated:formation:high_nonstop +
    treated:formation:I(1 - high_nonstop) +
    treated:dissolution:high_nonstop +
    treated:dissolution:I(1 - high_nonstop) | route + yq,
  data = panel,
  cluster = ~route + yq
)
cat("Heterogeneity by nonstop share:\n")
summary(hetero_nonstop)

## ============================================================
## 6. Heterogeneity: Airport-specific effects
## ============================================================
cat("\n=== Heterogeneity: By Origin Airport ===\n")

panel[, origin_airport := sub("-.*", "", route)]
for (apt in c("JFK", "LGA", "BOS", "EWR")) {
  sub_panel <- panel[origin_airport == apt]
  if (nrow(sub_panel) > 100 && sum(sub_panel$treated) > 50) {
    fit <- feols(
      log_fare ~ treated:formation + treated:dissolution | route + yq,
      data = sub_panel,
      cluster = ~route + yq
    )
    cat(sprintf("\n%s (N=%d):\n", apt, nrow(sub_panel)))
    cat(sprintf("  Formation: %.4f (%.4f)\n", coef(fit)["treated:formation"],
                se(fit)["treated:formation"]))
    cat(sprintf("  Dissolution: %.4f (%.4f)\n", coef(fit)["treated:dissolution"],
                se(fit)["treated:dissolution"]))
  }
}

## ============================================================
## 7. Save results for tables
## ============================================================
results <- list(
  main_did = main_did,
  es_did = es_did,
  weighted_did = weighted_did,
  hhi_did = hhi_did,
  ncarrier_did = ncarrier_did,
  pax_did = pax_did,
  hetero_nonstop = hetero_nonstop,
  ratchet_p = ratchet_p,
  beta_form = beta_form,
  beta_diss = beta_diss,
  se_form = se_form,
  se_diss = se_diss
)
saveRDS(results, "../data/main_results.rds")

## ---- Write diagnostics.json ----
diag <- list(
  n_treated = uniqueN(panel$route[panel$treated == 1]),
  n_pre = uniqueN(panel$yq[panel$period == "pre"]),
  n_obs = nrow(panel),
  n_routes = uniqueN(panel$route),
  n_control = uniqueN(panel$route[panel$treated == 0]),
  n_quarters = uniqueN(panel$yq)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics: %d treated routes, %d pre-periods, %s obs\n",
            diag$n_treated, diag$n_pre, format(diag$n_obs, big.mark = ",")))

cat("\n=== Main analysis complete ===\n")
