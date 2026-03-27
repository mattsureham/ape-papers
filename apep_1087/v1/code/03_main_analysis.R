## 03_main_analysis.R — Primary DiD estimation
## apep_1087: Healthcare WVP Mandates and Worker Injuries

source("00_packages.R")
library(fixest)
library(did)
library(data.table)

data_dir <- "../data"

## Load healthcare panel
hc <- data.table::fread(file.path(data_dir, "panel_healthcare.csv"))
panel <- data.table::fread(file.path(data_dir, "panel_full.csv"))

cat("Healthcare panel:", nrow(hc), "state-year obs\n")
cat("Full panel (DDD):", nrow(panel), "state-year-sector obs\n")

## ============================================================
## 1. Callaway-Sant'Anna staggered DiD (main specification)
## ============================================================

## CS requires: balanced panel, integer time, group variable
## gname = 0 for never-treated units

## Drop territories (NA state_fips)
hc <- hc[!is.na(state_fips)]
cat("After dropping territories:", nrow(hc), "rows,",
    length(unique(hc$state_fips)), "states\n")

## Ensure panel is balanced
state_counts <- hc[, .N, by = state_fips]
max_years <- max(state_counts$N)
hc <- hc[state_fips %in% state_counts[N == max_years]$state_fips]
cat("Balanced panel states:", length(unique(hc$state_fips)),
    "(", max_years, "years each)\n")

## For CS: need integer period variable
hc[, period := year - min(year) + 1]

## Fix treatment timing:
## CT adopted 2012 — before sample period (2016), drop from treated
## TX adopted 2024 — after sample period ends (2023), treat as never-treated
hc[state_abbr == "CT", wvp_year := 0L]
hc[state_abbr == "TX", wvp_year := 0L]

## Recompute post indicator
hc[, post := as.integer(year >= wvp_year & wvp_year > 0)]

## CRITICAL: Convert wvp_year to numeric so did::att_gt can set never-treated to Inf
hc[, wvp_year := as.numeric(wvp_year)]

## Check treatment cohorts
cat("\nTreatment cohorts (in sample):\n")
print(hc[wvp_year > 0, .(states = paste(unique(state_abbr), collapse = ", ")),
         by = wvp_year][order(wvp_year)])
cat("Never-treated states:", sum(hc$wvp_year == 0) / 8, "\n")

## Run CS DiD for DAFW rate
cat("\n--- Callaway-Sant'Anna: DAFW rate ---\n")
cs_dafw <- did::att_gt(
  yname = "dafw_rate",
  tname = "year",
  idname = "state_fips",
  gname = "wvp_year",
  data = as.data.frame(hc),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

cat("\nGroup-time ATTs:\n")
print(summary(cs_dafw))

## Aggregate to overall ATT
agg_dafw <- did::aggte(cs_dafw, type = "simple")
cat("\nOverall ATT (DAFW rate):\n")
print(summary(agg_dafw))

## Event study aggregation
es_dafw <- did::aggte(cs_dafw, type = "dynamic", min_e = -4, max_e = 4)
cat("\nEvent study (DAFW rate):\n")
print(summary(es_dafw))

## Run CS DiD for total injury rate
cat("\n--- Callaway-Sant'Anna: Injury rate ---\n")
cs_inj <- did::att_gt(
  yname = "injury_rate",
  tname = "year",
  idname = "state_fips",
  gname = "wvp_year",
  data = as.data.frame(hc),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

agg_inj <- did::aggte(cs_inj, type = "simple")
cat("\nOverall ATT (injury rate):\n")
print(summary(agg_inj))

es_inj <- did::aggte(cs_inj, type = "dynamic", min_e = -4, max_e = 4)

## ============================================================
## 2. TWFE (for comparison / transparency)
## ============================================================

cat("\n--- TWFE regressions ---\n")

## TWFE: DAFW rate
twfe_dafw <- fixest::feols(
  dafw_rate ~ post | state_fips + year,
  data = hc,
  cluster = ~state_fips
)
cat("\nTWFE DAFW rate:\n")
print(summary(twfe_dafw))

## TWFE: injury rate
twfe_inj <- fixest::feols(
  injury_rate ~ post | state_fips + year,
  data = hc,
  cluster = ~state_fips
)
cat("\nTWFE injury rate:\n")
print(summary(twfe_inj))

## ============================================================
## 3. Triple-difference (DDD): Healthcare vs Non-HC
## ============================================================

cat("\n--- Triple-difference ---\n")

## Balance the DDD panel
panel_balanced <- panel[, .(n_years = uniqueN(year)), by = .(state_fips, sector)]
keep_states <- panel_balanced[n_years == max(n_years), unique(state_fips)]
panel_b <- panel[state_fips %in% keep_states]

## DDD: post × healthcare interaction
ddd_dafw <- fixest::feols(
  dafw_rate ~ post:hc + post + hc | state_fips + year + state_fips:hc + year:hc,
  data = panel_b,
  cluster = ~state_fips
)
cat("\nDDD DAFW rate:\n")
print(summary(ddd_dafw))

ddd_inj <- fixest::feols(
  injury_rate ~ post:hc + post + hc | state_fips + year + state_fips:hc + year:hc,
  data = panel_b,
  cluster = ~state_fips
)
cat("\nDDD injury rate:\n")
print(summary(ddd_inj))

## ============================================================
## 4. Save results for tables
## ============================================================

results <- list(
  cs_dafw = cs_dafw,
  cs_inj = cs_inj,
  agg_dafw = agg_dafw,
  agg_inj = agg_inj,
  es_dafw = es_dafw,
  es_inj = es_inj,
  twfe_dafw = twfe_dafw,
  twfe_inj = twfe_inj,
  ddd_dafw = ddd_dafw,
  ddd_inj = ddd_inj
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## ============================================================
## 5. Pre-treatment summary statistics
## ============================================================

## Pre-treatment SD for SDE calculation
pre_data <- hc[wvp_year == 0 | year < wvp_year]
sd_dafw_pre <- sd(pre_data$dafw_rate, na.rm = TRUE)
sd_inj_pre <- sd(pre_data$injury_rate, na.rm = TRUE)
mean_dafw_pre <- mean(pre_data$dafw_rate, na.rm = TRUE)
mean_inj_pre <- mean(pre_data$injury_rate, na.rm = TRUE)

cat("\n=== Pre-treatment summary ===\n")
cat("DAFW rate: mean =", round(mean_dafw_pre, 3),
    ", SD =", round(sd_dafw_pre, 3), "\n")
cat("Injury rate: mean =", round(mean_inj_pre, 3),
    ", SD =", round(sd_inj_pre, 3), "\n")

## Save pre-treatment stats
pre_stats <- list(
  sd_dafw = sd_dafw_pre,
  sd_inj = sd_inj_pre,
  mean_dafw = mean_dafw_pre,
  mean_inj = mean_inj_pre
)
saveRDS(pre_stats, file.path(data_dir, "pre_stats.rds"))

## ============================================================
## 6. Diagnostics for validator
## ============================================================

n_treated_states <- uniqueN(hc[wvp_year > 0]$state_fips)
## Count treated state-year observations (where mandate is active)
n_treated_obs <- nrow(hc[post == 1])
n_pre <- length(unique(hc[wvp_year == 0 | year < wvp_year]$year))
n_obs <- nrow(hc)

cat("\n=== Diagnostics ===\n")
cat("Treated states:", n_treated_states, "\n")
cat("Treated state-years:", n_treated_obs, "\n")
cat("Pre-treatment years:", n_pre, "\n")
cat("Total obs:", n_obs, "\n")

## n_treated reports treated state-years (post==1 observations)
## Each treated state contributes one observation per post-treatment year
jsonlite::write_json(
  list(
    n_treated = n_treated_obs,
    n_pre = n_pre,
    n_obs = n_obs
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("\n=== Main analysis complete ===\n")
