## 02_clean_data.R — Build analysis panel
## APEP-0739: GP Practice Closures and A&E Utilization

source("code/00_packages.R")

gp_closures <- readRDS("data/gp_closures.rds")
ae_panel    <- readRDS("data/ae_panel.rds")
trusts      <- readRDS("data/trusts.rds")

cat("=== STEP 1: Create closure quarter variable ===\n")

gp_closures[, closure_year := as.integer(format(closure_date, "%Y"))]
gp_closures[, closure_q := as.integer(ceiling(as.integer(format(closure_date, "%m")) / 3))]

## Create a numeric quarter variable: 2018Q1 = 1, 2018Q2 = 2, etc.
gp_closures[, qtr_num := (closure_year - 2018) * 4 + closure_q]

cat(sprintf("Closures by year:\n"))
print(gp_closures[, .N, by = closure_year][order(closure_year)])


cat("\n=== STEP 2: Map GP closures to nearest A&E trust ===\n")

## Match each GP closure to the nearest A&E provider (trust) by distance
## Using only trusts that appear in the A&E panel (i.e., trusts with A&E departments)
ae_trusts <- unique(ae_panel$provider_code)
trusts_ae <- trusts[trust_code %in% ae_trusts & !is.na(trust_lat)]
cat(sprintf("Trusts with A&E data AND coordinates: %d\n", nrow(trusts_ae)))

## For each GP closure, find nearest A&E trust
## Use geosphere::distHaversine for accurate distances
assign_nearest_trust <- function(gp_dt, trust_dt) {
  gp_coords <- as.matrix(gp_dt[, .(longitude, latitude)])
  trust_coords <- as.matrix(trust_dt[, .(trust_lon, trust_lat)])

  nearest_trust <- character(nrow(gp_dt))
  nearest_dist  <- numeric(nrow(gp_dt))

  for (i in seq_len(nrow(gp_dt))) {
    dists <- geosphere::distHaversine(gp_coords[i, ], trust_coords)
    idx <- which.min(dists)
    nearest_trust[i] <- trust_dt$trust_code[idx]
    nearest_dist[i]  <- dists[idx] / 1000  # km
  }

  gp_dt[, `:=`(nearest_trust = nearest_trust, dist_to_trust_km = nearest_dist)]
  gp_dt
}

gp_closures <- assign_nearest_trust(gp_closures, trusts_ae)
cat(sprintf("Mean distance to nearest A&E trust: %.1f km\n", mean(gp_closures$dist_to_trust_km)))
cat(sprintf("Median distance: %.1f km\n", median(gp_closures$dist_to_trust_km)))


cat("\n=== STEP 3: Build trust-quarter panel ===\n")

## Aggregate A&E data to quarterly level
ae_panel[, qtr := quarter(as.Date(paste(ae_year, ae_month, 1, sep = "-")))]
ae_panel[, qtr_num := (ae_year - 2018) * 4 + qtr]

ae_qtr <- ae_panel[, .(
  type1_att = sum(type1_att, na.rm = TRUE),
  total_att = sum(total_att, na.rm = TRUE)
), by = .(provider_code, ae_year, qtr, qtr_num)]

cat(sprintf("A&E quarterly panel: %d trust-quarters\n", nrow(ae_qtr)))

## Count closures per trust per quarter (within 15 km)
gp_closures[, trust_match := nearest_trust]

## Aggregate closures by trust-quarter
closures_by_trust_qtr <- gp_closures[dist_to_trust_km <= 15,
  .(n_closures = .N),
  by = .(trust_match, closure_year, closure_q, qtr_num)
]

## Merge closure counts into A&E panel
ae_qtr <- merge(ae_qtr, closures_by_trust_qtr,
                by.x = c("provider_code", "qtr_num"),
                by.y = c("trust_match", "qtr_num"),
                all.x = TRUE)
ae_qtr[is.na(n_closures), n_closures := 0]


cat("\n=== STEP 4: Define treatment for CS estimator ===\n")

## Treatment = first quarter with any GP closure within 15 km
first_closure <- gp_closures[dist_to_trust_km <= 15,
  .(first_treat_qtr = min(qtr_num)),
  by = nearest_trust
]

ae_qtr <- merge(ae_qtr, first_closure,
                by.x = "provider_code", by.y = "nearest_trust",
                all.x = TRUE)

## Never-treated trusts: those with no closures nearby during entire period
ae_qtr[is.na(first_treat_qtr), first_treat_qtr := 0]

## Create numeric trust ID for CS estimator
ae_qtr[, trust_id := as.integer(factor(provider_code))]

## Log outcome
ae_qtr[, log_type1 := log(type1_att + 1)]
ae_qtr[, log_total := log(total_att + 1)]

## Summary
n_treated <- uniqueN(ae_qtr[first_treat_qtr > 0, provider_code])
n_control <- uniqueN(ae_qtr[first_treat_qtr == 0, provider_code])
cat(sprintf("Treated trusts (any closure within 15 km): %d\n", n_treated))
cat(sprintf("Never-treated trusts: %d\n", n_control))
cat(sprintf("Total trust-quarters: %d\n", nrow(ae_qtr)))

## Keep only trusts with at least 4 quarters of data
trust_counts <- ae_qtr[, .N, by = provider_code]
valid_trusts <- trust_counts[N >= 4, provider_code]
ae_qtr <- ae_qtr[provider_code %in% valid_trusts]
cat(sprintf("After filtering (≥4 quarters): %d trust-quarters, %d trusts\n",
            nrow(ae_qtr), uniqueN(ae_qtr$provider_code)))


cat("\n=== STEP 5: Create cumulative treatment intensity ===\n")

## For dose-response: cumulative closures within 15 km up to quarter t
setorder(ae_qtr, provider_code, qtr_num)
ae_qtr[, cum_closures := cumsum(n_closures), by = provider_code]

## Pre-treatment mean for standardized effects
pre_means <- ae_qtr[qtr_num < first_treat_qtr | first_treat_qtr == 0,
  .(pre_mean_type1 = mean(type1_att, na.rm = TRUE),
    pre_sd_type1 = sd(type1_att, na.rm = TRUE)),
  by = provider_code
]
ae_qtr <- merge(ae_qtr, pre_means, by = "provider_code", all.x = TRUE)

cat("\n=== STEP 6: Create event time variable ===\n")

ae_qtr[, event_time := ifelse(first_treat_qtr > 0, qtr_num - first_treat_qtr, NA_real_)]

## Restrict to balanced event window: -8 to +8 quarters
ae_qtr_es <- ae_qtr[!is.na(event_time) & event_time >= -8 & event_time <= 8]
cat(sprintf("Event study sample (±8 quarters): %d trust-quarters\n", nrow(ae_qtr_es)))


cat("\n=== STEP 7: Save analysis-ready data ===\n")

saveRDS(ae_qtr, "data/ae_analysis.rds")
saveRDS(ae_qtr_es, "data/ae_eventstudy.rds")
saveRDS(gp_closures, "data/gp_closures_mapped.rds")

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
cat(sprintf("  Total trust-quarters: %d\n", nrow(ae_qtr)))
cat(sprintf("  Treated trusts: %d\n", n_treated))
cat(sprintf("  Never-treated trusts: %d\n", n_control))
cat(sprintf("  Quarters covered: %d to %d\n", min(ae_qtr$qtr_num), max(ae_qtr$qtr_num)))
