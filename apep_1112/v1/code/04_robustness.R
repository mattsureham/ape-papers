## 04_robustness.R — Robustness checks
## APEP-1112: The Alliance Ratchet

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

## ============================================================
## 1. Median fares (robust to outlier tickets)
## ============================================================
cat("=== Robustness 1: Median fares ===\n")
rob_median <- feols(
  log_med_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq
)
summary(rob_median)

## ============================================================
## 2. Fare per mile (controls for distance composition)
## ============================================================
cat("\n=== Robustness 2: Fare per mile ===\n")
panel[, log_fare_per_mile := log(avg_fare_per_mile)]
rob_fpm <- feols(
  log_fare_per_mile ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route + yq
)
summary(rob_fpm)

## ============================================================
## 3. Placebo: routes at NEA airports NOT served by B6 or AA
## ============================================================
cat("\n=== Robustness 3: Placebo (non-B6/AA routes at NEA airports) ===\n")

## Identify routes where neither B6 nor AA ever appeared
panel[, ever_b6aa := max(b6_share > 0 | aa_share > 0), by = route]
placebo_panel <- panel[treated == 0 & ever_b6aa == 0]

## Create a "pseudo-treatment" for routes with high pre-NEA HHI
## (routes where coordination effects might spill over)
pre_hhi <- placebo_panel[period == "pre", .(avg_hhi = mean(hhi)), by = route]
med_hhi <- median(pre_hhi$avg_hhi, na.rm = TRUE)
high_hhi_routes <- pre_hhi[avg_hhi >= med_hhi, route]
placebo_panel[, pseudo_treated := as.integer(route %in% high_hhi_routes)]

rob_placebo <- feols(
  log_fare ~ pseudo_treated:formation + pseudo_treated:dissolution | route + yq,
  data = placebo_panel,
  cluster = ~route + yq
)
cat("Placebo (high HHI control routes should show NO effect):\n")
summary(rob_placebo)

## ============================================================
## 4. Excluding COVID quarters (Q2 2020 - Q2 2021)
## ============================================================
cat("\n=== Robustness 4: Excluding COVID overlap ===\n")
panel_nocovid <- panel[!(Year == 2020 & Quarter >= 2) & !(Year == 2021 & Quarter <= 1)]
rob_nocovid <- feols(
  log_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel_nocovid,
  cluster = ~route + yq
)
summary(rob_nocovid)

## ============================================================
## 5. Alternative clustering: route only
## ============================================================
cat("\n=== Robustness 5: Route-only clustering ===\n")
rob_cluster <- feols(
  log_fare ~ treated:formation + treated:dissolution | route + yq,
  data = panel,
  cluster = ~route
)
summary(rob_cluster)

## ============================================================
## 6. Adding route-specific linear trends
## ============================================================
cat("\n=== Robustness 6: Route-specific trends ===\n")
rob_trends <- feols(
  log_fare ~ treated:formation + treated:dissolution | route[q_index] + yq,
  data = panel,
  cluster = ~route + yq
)
summary(rob_trends)

## ============================================================
## Save robustness results
## ============================================================
rob_results <- list(
  rob_median = rob_median,
  rob_fpm = rob_fpm,
  rob_placebo = rob_placebo,
  rob_nocovid = rob_nocovid,
  rob_cluster = rob_cluster,
  rob_trends = rob_trends
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
