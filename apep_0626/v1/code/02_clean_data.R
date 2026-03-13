## ============================================================================
## 02_clean_data.R — Variable Construction for apep_0626
## ============================================================================

source("code/00_packages.R")

data_dir <- "data"

## --------------------------------------------------------------------------
## 1. Load data
## --------------------------------------------------------------------------

cat("=== Loading data ===\n")

county_exp <- readRDS(file.path(data_dir, "county_exposure.rds"))
dt <- readRDS(file.path(data_dir, "analysis_1920_1930.rds"))

cat(sprintf("Analysis sample: %s individuals\n", format(nrow(dt), big.mark = ",")))
cat(sprintf("County exposure: %d counties\n", nrow(county_exp)))

## --------------------------------------------------------------------------
## 2. Merge county exposure into individual data
## --------------------------------------------------------------------------

cat("\n=== Merging county exposure ===\n")

## Merge on 1920 county of residence
dt <- merge(dt,
  county_exp[, .(STATEFIP = STATEFIP, COUNTYICP = COUNTYICP,
                  quota_exposure, quota_exposure_broad, fb_share,
                  total_pop)],
  by.x = c("statefip_1920", "countyicp_1920"),
  by.y = c("STATEFIP", "COUNTYICP"),
  all.x = FALSE  # Drop individuals in counties with < 1000 pop
)

cat(sprintf("After merge: %s individuals\n", format(nrow(dt), big.mark = ",")))

## --------------------------------------------------------------------------
## 3. Construct outcome variables
## --------------------------------------------------------------------------

cat("\n=== Constructing outcome variables ===\n")

## Primary outcome: change in occupational income score
dt[, delta_occscore := occscore_1930 - occscore_1920]

## Alternative: change in socioeconomic index
dt[, delta_sei := sei_1930 - sei_1920]

## Occupational upgrading indicator (moved to higher-scoring occupation)
dt[, upgraded := as.integer(delta_occscore > 0)]
dt[, downgraded := as.integer(delta_occscore < 0)]

## Farm-to-nonfarm transition
dt[, farm_exit := as.integer(farm_1920 == 2 & farm_1930 == 1)]
## Nonfarm-to-farm (reverse)
dt[, farm_entry := as.integer(farm_1920 == 1 & farm_1930 == 2)]

## Geographic mobility (mover flag from linked panel)
dt[, moved := as.integer(mover == 1)]

## Homeownership transition
## OWNERSHP: 1=owned, 2=rented
dt[, became_owner := as.integer(ownershp_1920 == 2 & ownershp_1930 == 1)]

## Initial skill categories (based on 1920 OCCSCORE)
dt[, skill_1920 := fcase(
  occscore_1920 <= 15, "Low",
  occscore_1920 <= 25, "Medium",
  default = "High"
)]

## Age categories
dt[, age_cat := fcase(
  age_1920 <= 25, "18-25",
  age_1920 <= 35, "26-35",
  age_1920 <= 45, "36-45",
  default = "46-55"
)]

## Urban/rural (farm as proxy)
## FARM: 1=non-farm, 2=farm
dt[, urban := as.integer(farm_1920 == 1)]

## Race: 1=White, 2=Black, others
dt[, white := as.integer(race_1920 == 1)]
dt[, black := as.integer(race_1920 == 2)]

## Literacy
## LIT: 0=N/A, 1=No, 2=illiterate, 3=cannot write, 4=Yes
dt[, literate := as.integer(lit_1920 == 4)]

## Class of worker: wage/salary vs self-employed
dt[, wage_worker := as.integer(classwkr_1920 == 2)]

## Exposure quartiles
dt[, exp_quartile := cut(quota_exposure,
  breaks = quantile(quota_exposure, probs = c(0, 0.25, 0.5, 0.75, 1)),
  labels = c("Q1 (Low)", "Q2", "Q3", "Q4 (High)"),
  include.lowest = TRUE
)]

## Log county population (control)
dt[, log_pop := log(total_pop)]

## --------------------------------------------------------------------------
## 4. Summary statistics
## --------------------------------------------------------------------------

cat("\n=== Sample characteristics ===\n")
cat(sprintf("N individuals: %s\n", format(nrow(dt), big.mark = ",")))
cat(sprintf("N counties: %d\n", uniqueN(dt, by = c("statefip_1920", "countyicp_1920"))))
cat(sprintf("Mean age (1920): %.1f\n", mean(dt$age_1920)))
cat(sprintf("Share white: %.3f\n", mean(dt$white)))
cat(sprintf("Share literate: %.3f\n", mean(dt$literate)))
cat(sprintf("Share farm: %.3f\n", mean(dt$farm_1920 == 2)))
cat(sprintf("Mean OCCSCORE 1920: %.1f\n", mean(dt$occscore_1920)))
cat(sprintf("Mean OCCSCORE 1930: %.1f\n", mean(dt$occscore_1930)))
cat(sprintf("Mean delta OCCSCORE: %.3f\n", mean(dt$delta_occscore)))
cat(sprintf("Share upgraded: %.3f\n", mean(dt$upgraded)))
cat(sprintf("Share moved: %.3f\n", mean(dt$moved, na.rm = TRUE)))

cat("\n--- By exposure quartile ---\n")
summ_by_q <- dt[, .(
  n = .N,
  mean_exposure = mean(quota_exposure),
  mean_occscore_1920 = mean(occscore_1920),
  mean_delta_occscore = mean(delta_occscore),
  share_upgraded = mean(upgraded),
  share_farm_exit = mean(farm_exit, na.rm = TRUE),
  share_moved = mean(moved, na.rm = TRUE)
), by = exp_quartile]
print(summ_by_q)

## --------------------------------------------------------------------------
## 5. Save cleaned dataset
## --------------------------------------------------------------------------

cat("\n=== Saving cleaned dataset ===\n")
saveRDS(dt, file.path(data_dir, "clean_1920_1930.rds"))
cat(sprintf("Saved: %s (%s bytes)\n",
    file.path(data_dir, "clean_1920_1930.rds"),
    format(file.size(file.path(data_dir, "clean_1920_1930.rds")), big.mark = ",")))

## --------------------------------------------------------------------------
## 6. Prepare placebo data (1910-1920)
## --------------------------------------------------------------------------

cat("\n=== Preparing placebo data ===\n")

if (file.exists(file.path(data_dir, "placebo_1910_1920.rds")) &&
    file.exists(file.path(data_dir, "county_exposure_1910.rds"))) {
  dt_p <- readRDS(file.path(data_dir, "placebo_1910_1920.rds"))
  county_exp_1910 <- readRDS(file.path(data_dir, "county_exposure_1910.rds"))

  ## Merge 1910 county exposure (for actual placebo: 1910 exposure on 1910-1920 changes)
  dt_p <- merge(dt_p,
    county_exp_1910[, .(STATEFIP, COUNTYICP, quota_exposure_1910)],
    by.x = c("statefip_1910", "countyicp_1910"),
    by.y = c("STATEFIP", "COUNTYICP"),
    all.x = FALSE
  )

  ## Also merge 1920 exposure for second placebo test (does 1920 exposure predict 1910-1920 changes?)
  dt_p <- merge(dt_p,
    county_exp[, .(STATEFIP = STATEFIP, COUNTYICP = COUNTYICP, quota_exposure)],
    by.x = c("statefip_1920", "countyicp_1920"),
    by.y = c("STATEFIP", "COUNTYICP"),
    all.x = FALSE
  )

  ## Construct outcomes
  dt_p[, delta_occscore := occscore_1920 - occscore_1910]
  dt_p[, upgraded := as.integer(delta_occscore > 0)]
  dt_p[, farm_exit := as.integer(farm_1910 == 2 & farm_1920 == 1)]
  dt_p[, moved := as.integer(mover == 1)]

  ## Controls
  dt_p[, white := as.integer(race_1910 == 1)]
  dt_p[, literate := as.integer(lit_1910 == 4)]
  dt_p[, urban := as.integer(farm_1910 == 1)]

  cat(sprintf("Placebo sample: %s individuals\n", format(nrow(dt_p), big.mark = ",")))

  saveRDS(dt_p, file.path(data_dir, "clean_placebo.rds"))
  rm(dt_p); gc()
}

cat("\n=== Data cleaning complete ===\n")
