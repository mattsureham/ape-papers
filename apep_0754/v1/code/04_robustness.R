## 04_robustness.R — Robustness checks and placebo tests
## APEP Working Paper apep_0754

source("00_packages.R")

## ---- 1. Load data ----
panel_full <- readRDS("../data/panel_full.rds")
panel_conv <- readRDS("../data/panel_conv.rds")
panel_ddd  <- readRDS("../data/panel_ddd.rds")
results    <- readRDS("../data/main_results.rds")

## ---- 2. Placebo: Supermarket exit rates (should NOT increase) ----
cat("=== Placebo: Supermarket exits ===\n")

panel_super <- panel_full[store_group == "supermarket"]
panel_super[, state_id := as.integer(as.factor(State))]

placebo_super <- feols(
  exit_rate ~ treated | State + yq_num,
  data = panel_super,
  cluster = ~State
)
cat("Supermarket placebo (treated → exit_rate):\n")
print(summary(placebo_super))

## ---- 3. Placebo: Specialty stores (should NOT be affected by online SNAP) ----
cat("\n=== Placebo: Specialty store exits ===\n")

panel_spec <- panel_full[store_group == "specialty"]
placebo_spec <- feols(
  exit_rate ~ treated | State + yq_num,
  data = panel_spec,
  cluster = ~State
)
cat("Specialty store placebo:\n")
print(summary(placebo_spec))

## ---- 4. Placebo: Other grocery stores ----
cat("\n=== Placebo: Other grocery store exits ===\n")

panel_other <- panel_full[store_group == "other_grocery"]
placebo_other <- feols(
  exit_rate ~ treated | State + yq_num,
  data = panel_other,
  cluster = ~State
)
cat("Other grocery placebo:\n")
print(summary(placebo_other))

## ---- 5. Net entry rate (entries minus exits) ----
cat("\n=== Net change rate ===\n")

net_conv <- feols(
  net_change_rate ~ treated | State + yq_num,
  data = panel_conv,
  cluster = ~State
)
cat("Net change rate (convenience stores):\n")
print(summary(net_conv))

net_ddd <- feols(
  net_change_rate ~ treated:is_conv |
    State^store_group + State^yq_num,
  data = panel_ddd,
  cluster = ~State
)
cat("\nNet change rate DDD:\n")
print(summary(net_ddd))

## ---- 6. Entry rate (supply response) ----
cat("\n=== Entry rate ===\n")

entry_conv <- feols(
  entry_rate ~ treated | State + yq_num,
  data = panel_conv,
  cluster = ~State
)
cat("Entry rate (convenience stores):\n")
print(summary(entry_conv))

## ---- 7. Alternative store-type groupings ----
cat("\n=== Alternative DDD: convenience vs ALL non-convenience ===\n")

panel_full[, is_conv_broad := as.integer(store_group == "convenience")]
ddd_broad <- feols(
  exit_rate ~ treated:is_conv_broad |
    State^store_group + State^yq_num,
  data = panel_full,
  cluster = ~State
)
cat("Broad DDD (conv vs all others):\n")
print(summary(ddd_broad))

## ---- 8. Bacon decomposition (for TWFE diagnostic) ----
cat("\n=== Bacon Decomposition ===\n")

# Simple TWFE for decomposition
twfe_conv <- feols(
  exit_rate ~ treated | State + yq_num,
  data = panel_conv,
  cluster = ~State
)
cat("TWFE (convenience stores):\n")
print(summary(twfe_conv))

## ---- 9. Exclude COVID peak quarters ----
cat("\n=== Excluding COVID peak (2020Q2-Q3) ===\n")

panel_conv_no_covid <- panel_conv[!(yq %in% c("2020Q2", "2020Q3"))]
no_covid <- feols(
  exit_rate ~ treated | State + yq_num,
  data = panel_conv_no_covid,
  cluster = ~State
)
cat("Excluding 2020Q2-Q3:\n")
print(summary(no_covid))

## ---- 10. HonestDiD sensitivity (if CS results available) ----
cat("\n=== HonestDiD Sensitivity ===\n")
tryCatch({
  honest_result <- HonestDiD::honest_did(
    results$cs_es,
    type = "relative_magnitude",
    Mbarvec = seq(0.5, 2, by = 0.5)
  )
  cat("HonestDiD relative magnitude bounds:\n")
  print(honest_result)
  saveRDS(honest_result, "../data/honest_did.rds")
}, error = function(e) {
  cat(sprintf("HonestDiD error (non-fatal): %s\n", e$message))
})

## ---- 11. Save robustness results ----
robust_results <- list(
  placebo_super = placebo_super,
  placebo_spec = placebo_spec,
  placebo_other = placebo_other,
  net_conv = net_conv,
  net_ddd = net_ddd,
  entry_conv = entry_conv,
  ddd_broad = ddd_broad,
  twfe_conv = twfe_conv,
  no_covid = no_covid
)
saveRDS(robust_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
