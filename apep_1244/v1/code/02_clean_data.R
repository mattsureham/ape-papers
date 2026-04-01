# =============================================================================
# 02_clean_data.R — Variable construction and sample selection
# apep_1244: The Upgrading Dividend
# =============================================================================

source("00_packages.R")

panel_1920 <- readRDS("../data/panel_1910_1920.rds")
panel_1910 <- readRDS("../data/panel_1900_1910.rds")
wc_dates   <- readRDS("../data/wc_dates.rds")

# ---- Define hazardous industries (ind1950 codes) ----------------------------
# Manufacturing: 306-499 (durable + non-durable)
# Mining: 206-299 (metal, coal, oil, nonmetallic)

classify_hazardous <- function(ind) {
  as.integer((ind >= 206 & ind <= 299) | (ind >= 306 & ind <= 499))
}

# ---- Process treatment panel (1910-1920) ------------------------------------
cat("Processing 1910-1920 panel...\n")

# Merge WC dates using 1910 state of residence (intent-to-treat)
panel_1920 <- merge(panel_1920, wc_dates, by.x = "statefip_1910", by.y = "statefip", all.x = FALSE)

# Construct outcomes
panel_1920[, `:=`(
  hazardous_1910 = classify_hazardous(ind1950_1910),
  hazardous_1920 = classify_hazardous(ind1950_1920),
  selfemp_1920   = as.integer(classwkr_1920 == 1),  # classwkr: 1=self-employed, 2=wage
  farm_origin    = as.integer(farm_1910 == 2)  # farm=2 means farm residence in IPUMS
)]

panel_1920[, `:=`(
  d_hazardous = hazardous_1920 - hazardous_1910,
  d_occscore  = occscore_1920 - occscore_1910,
  enter_selfemp = selfemp_1920  # Transition to self-employment by 1920
)]

# Treatment variables
panel_1920[, `:=`(
  treated     = as.integer(wc_year > 0),
  wc_exposure = fifelse(wc_year > 0, 1920L - wc_year, 0L)
)]

# Demographics
panel_1920[, `:=`(
  young       = as.integer(age_1910 <= 30),
  black       = as.integer(race_1910 == 2),
  foreign     = as.integer(nativity_1910 >= 4),  # foreign-born
  literate    = as.integer(lit_1910 == 4)
)]

cat("  N treated:", format(sum(panel_1920$treated), big.mark = ","), "\n")
cat("  N control:", format(sum(!panel_1920$treated), big.mark = ","), "\n")
cat("  Hazardous 1910 (treated):", round(mean(panel_1920[treated == 1, hazardous_1910]), 4), "\n")
cat("  Hazardous 1910 (control):", round(mean(panel_1920[treated == 0, hazardous_1910]), 4), "\n")
cat("  Hazardous 1920 (treated):", round(mean(panel_1920[treated == 1, hazardous_1920]), 4), "\n")
cat("  Hazardous 1920 (control):", round(mean(panel_1920[treated == 0, hazardous_1920]), 4), "\n")

# ---- Process pre-period panel (1900-1910) -----------------------------------
cat("\nProcessing 1900-1910 panel...\n")

# Map future WC adoption using 1900 state → future treatment status
panel_1910 <- merge(panel_1910, wc_dates, by.x = "statefip_1900", by.y = "statefip", all.x = FALSE)

panel_1910[, `:=`(
  hazardous_t0 = classify_hazardous(ind1950_1900),
  hazardous_t1 = classify_hazardous(ind1950_1910),
  farm_origin  = as.integer(farm_1900 == 2)
)]

panel_1910[, `:=`(
  d_hazardous = hazardous_t1 - hazardous_t0,
  d_occscore  = occscore_1910 - occscore_1900
)]

panel_1910[, `:=`(
  treated     = as.integer(wc_year > 0),
  wc_exposure = fifelse(wc_year > 0, 1920L - wc_year, 0L)
)]

panel_1910[, `:=`(
  young       = as.integer(age_1900 <= 30),
  black       = as.integer(race_1900 == 2),
  foreign     = as.integer(nativity_1900 >= 4),
  literate    = as.integer(lit_1900 == 4)
)]

cat("  N treated:", format(sum(panel_1910$treated), big.mark = ","), "\n")
cat("  N control:", format(sum(!panel_1910$treated), big.mark = ","), "\n")
cat("  Pre-period hazardous change (treated):", round(mean(panel_1910[treated == 1, d_hazardous], na.rm = TRUE), 5), "\n")
cat("  Pre-period hazardous change (control):", round(mean(panel_1910[treated == 0, d_hazardous], na.rm = TRUE), 5), "\n")

# ---- Stack into DiD dataset -------------------------------------------------
cat("\nStacking cohorts...\n")

# Rename to common columns
stack_post <- panel_1920[, .(
  histid, statefip = statefip_1910, d_hazardous, d_occscore, mover,
  treated, wc_year, wc_exposure,
  young, black, foreign, literate, farm_origin,
  cohort = 2L
)]

stack_pre <- panel_1910[, .(
  histid, statefip = statefip_1900, d_hazardous, d_occscore, mover,
  treated, wc_year, wc_exposure,
  young, black, foreign, literate, farm_origin,
  cohort = 1L
)]

stacked <- rbind(stack_pre, stack_post)

# DiD interaction
stacked[, `:=`(
  post = as.integer(cohort == 2),
  did  = as.integer(cohort == 2 & treated == 1)
)]

cat("Stacked dataset:", format(nrow(stacked), big.mark = ","), "observations\n")
cat("  Pre-period (1900-1910):", format(nrow(stacked[cohort == 1]), big.mark = ","), "\n")
cat("  Treatment (1910-1920):", format(nrow(stacked[cohort == 2]), big.mark = ","), "\n")

# ---- Save -------------------------------------------------------------------
saveRDS(panel_1920, "../data/panel_1920_clean.rds")
saveRDS(panel_1910, "../data/panel_1910_clean.rds")
saveRDS(stacked, "../data/stacked.rds")

cat("\nCleaning complete.\n")
