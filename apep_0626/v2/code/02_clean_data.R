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
## V2: Additional outcome variables
## --------------------------------------------------------------------------

cat("\n=== V2: Constructing additional variables ===\n")

## Lost homeownership (owned in 1920, rented in 1930)
dt[, lost_home := as.integer(ownershp_1920 == 1 & ownershp_1930 == 2)]

## Net homeownership transition (became_owner - lost_home)
dt[, net_owner := became_owner - lost_home]

## Occupational ladder categories (for transition analysis)
## Using OCC1950 groupings based on IPUMS schema
dt[, occ_cat_1920 := fcase(
  occ1950_1920 >= 0   & occ1950_1920 < 100,  "Professional/Technical",
  occ1950_1920 >= 100 & occ1950_1920 < 200,  "Managers/Officials",
  occ1950_1920 >= 200 & occ1950_1920 < 300,  "Clerical/Sales",
  occ1950_1920 >= 300 & occ1950_1920 < 500,  "Craftsmen/Operatives",
  occ1950_1920 >= 500 & occ1950_1920 < 600,  "Service Workers",
  occ1950_1920 >= 600 & occ1950_1920 < 700,  "Farm Workers",
  occ1950_1920 >= 700 & occ1950_1920 < 800,  "Laborers (Non-Farm)",
  default = "Other"
)]

dt[, occ_cat_1930 := fcase(
  occ1950_1930 >= 0   & occ1950_1930 < 100,  "Professional/Technical",
  occ1950_1930 >= 100 & occ1950_1930 < 200,  "Managers/Officials",
  occ1950_1930 >= 200 & occ1950_1930 < 300,  "Clerical/Sales",
  occ1950_1930 >= 300 & occ1950_1930 < 500,  "Craftsmen/Operatives",
  occ1950_1930 >= 500 & occ1950_1930 < 600,  "Service Workers",
  occ1950_1930 >= 600 & occ1950_1930 < 700,  "Farm Workers",
  occ1950_1930 >= 700 & occ1950_1930 < 800,  "Laborers (Non-Farm)",
  default = "Other"
)]

## Did person move up on the occupational ladder?
occ_rank <- c("Laborers (Non-Farm)" = 1, "Farm Workers" = 2, "Service Workers" = 3,
              "Craftsmen/Operatives" = 4, "Clerical/Sales" = 5,
              "Managers/Officials" = 6, "Professional/Technical" = 7, "Other" = 0)
dt[, occ_rank_1920 := occ_rank[occ_cat_1920]]
dt[, occ_rank_1930 := occ_rank[occ_cat_1930]]
dt[, ladder_up := as.integer(occ_rank_1930 > occ_rank_1920 & occ_rank_1920 > 0 & occ_rank_1930 > 0)]

## Class of worker transition (wage → self-employed)
## CLASSWKR: 1=Self-employed, 2=Wage/salary, 3=Unpaid family
dt[, became_self_employed := as.integer(classwkr_1920 == 2 & classwkr_1930 == 1)]

## Exposure quintiles (finer than quartiles, for figures)
dt[, exp_quintile := cut(quota_exposure,
  breaks = quantile(quota_exposure, probs = seq(0, 1, 0.2)),
  labels = paste0("Q", 1:5),
  include.lowest = TRUE
)]

## V2: Merge first-stage data if available
county_fb_1930_file <- file.path(data_dir, "county_fb_1930.rds")
if (file.exists(county_fb_1930_file)) {
  cat("Merging 1930 FB data for first-stage analysis...\n")
  county_fb_1930 <- readRDS(county_fb_1930_file)
  dt <- merge(dt,
    county_fb_1930[, .(STATEFIP, COUNTYICP, fb_share_1930, restricted_share_1930,
                        total_pop_1930)],
    by.x = c("statefip_1920", "countyicp_1920"),
    by.y = c("STATEFIP", "COUNTYICP"),
    all.x = TRUE
  )
  ## Compute change in foreign-born share
  dt[, delta_fb_share := fb_share_1930 - fb_share]
  dt[, delta_restricted_share := restricted_share_1930 - quota_exposure]
  cat(sprintf("  Matched: %s / %s (%.1f%%)\n",
    format(sum(!is.na(dt$fb_share_1930)), big.mark = ","),
    format(nrow(dt), big.mark = ","),
    100 * mean(!is.na(dt$fb_share_1930))))
}

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
