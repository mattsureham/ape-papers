# 02_clean_data.R — Clean and construct analysis panel
# apep_0835: Greece POS Terminal Mandates

source("00_packages.R")

# -------------------------------------------------------------------
# 1. Load and standardize national SBS data
# -------------------------------------------------------------------
sbs <- fread("../data/sbs_raw.csv")
cat(sprintf("SBS loaded: %d rows\n", nrow(sbs)))

# Standardize column names
setnames(sbs, c("geo", "nace_r2", "indic_sb", "values", "time"),
         c("region", "nace", "indicator", "value", "year"),
         skip_absent = TRUE)
sbs[, year := as.numeric(year)]

# Map service subsectors to 1-digit NACE
sbs[, nace1 := substr(nace, 1, 1)]

# For K65 (insurance), map to K
sbs[nace == "K65", nace1 := "K"]
# For S95 (repair), map to S
sbs[grepl("^S", nace), nace1 := "S"]

cat("Unique 1-digit sectors:\n")
print(sort(unique(sbs$nace1)))

# Keep only 1-digit level aggregates (avoid double-counting subsectors)
# Industry: B, C, D, E are already 1-digit
# Services: F, G, H, I, J, L, M, N are 1-digit; K65 and S95 are subsectors
sbs_1d <- sbs[nchar(nace) == 1 | nace %in% c("K65", "S95")]
cat(sprintf("After filtering to 1-digit: %d rows\n", nrow(sbs_1d)))

# -------------------------------------------------------------------
# 2. Define treatment assignment
# -------------------------------------------------------------------

# Wave 1 (H1 2017): Restaurants, bars, doctors, lawyers, beauty salons
#   → G (Retail/Wholesale), I (Accommodation/Food), M (Professional services)
# Wave 2 (H2 2017): Additional services
#   → N (Administrative), S (Other services)
# Never-treated (until 2024+):
#   → B (Mining), C (Manufacturing), D (Electricity), E (Water), J (ICT)

wave1_sectors <- c("G", "I", "M", "N", "S")  # Service sectors mandated 2017
never_treated <- c("B", "C", "D", "E", "J")   # Industry/ICT — not mandated until 2024
ambiguous_sectors <- c("F", "H", "K", "L")     # Uncertain timing — exclude

sbs_1d[, treatment_group := fcase(
  nace1 %in% wave1_sectors, "treated_2017",
  nace1 %in% never_treated, "never_treated",
  default = "ambiguous"
)]

cat("\nTreatment assignment:\n")
print(sbs_1d[, .N, by = treatment_group])

# -------------------------------------------------------------------
# 3. Reshape to wide (one row per sector-year)
# -------------------------------------------------------------------

# Aggregate to nace1 level if not already
agg <- sbs_1d[treatment_group != "ambiguous",
              .(value = sum(value, na.rm = TRUE)),
              by = .(nace1, year, indicator, treatment_group)]

panel_wide <- dcast(agg, nace1 + year + treatment_group ~ indicator,
                    value.var = "value", fun.aggregate = sum)

# Rename indicators
setnames(panel_wide,
         old = c("V11110", "V16110", "V13310"),
         new = c("establishments", "employment", "wages"),
         skip_absent = TRUE)

cat(sprintf("\nPanel: %d sector-year observations\n", nrow(panel_wide)))
cat("Columns:", paste(names(panel_wide), collapse = ", "), "\n")

# -------------------------------------------------------------------
# 4. Construct analysis variables
# -------------------------------------------------------------------

panel_wide[, treated := as.integer(treatment_group == "treated_2017")]
panel_wide[, post := as.integer(year >= 2017)]
panel_wide[, treat_post := treated * post]

# Cohort variable for CS estimator
panel_wide[, cohort := fifelse(treated == 1, 2017L, 0L)]

# Log outcomes
panel_wide[, log_est := log(establishments + 1)]
panel_wide[, log_emp := log(employment + 1)]
panel_wide[, log_wages := log(wages + 1)]

# Numeric IDs
panel_wide[, sector_id := as.integer(factor(nace1))]
panel_wide[, unit_id := sector_id]  # At national level, unit = sector

# -------------------------------------------------------------------
# 5. Sample restrictions
# -------------------------------------------------------------------

# Keep 2012-2019 (exclude pre-2012 gaps, exclude 2020 COVID)
panel <- panel_wide[year >= 2012 & year <= 2019]

# Remove rows where all outcomes are 0 (missing data coded as 0 after aggregation)
panel <- panel[establishments > 0 | employment > 0 | wages > 0]

cat(sprintf("\nAnalysis panel (2012-2019): %d obs\n", nrow(panel)))
cat(sprintf("  Treated sectors: %s\n", paste(sort(unique(panel[treated == 1]$nace1)), collapse = ", ")))
cat(sprintf("  Control sectors: %s\n", paste(sort(unique(panel[treated == 0]$nace1)), collapse = ", ")))
cat(sprintf("  Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))

# Summary by treatment group
cat("\nMeans by group:\n")
print(panel[, .(
  mean_est = mean(establishments, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  mean_wages = mean(wages / 1e6, na.rm = TRUE),
  n = .N
), by = .(treated, post)])

# -------------------------------------------------------------------
# 6. Save
# -------------------------------------------------------------------
fwrite(panel, "../data/analysis_panel.csv")

# Full panel including 2020
panel_full <- panel_wide[year >= 2012 & year <= 2020]
panel_full <- panel_full[establishments > 0 | employment > 0 | wages > 0]
fwrite(panel_full, "../data/analysis_panel_full.csv")

cat("\nPanel saved.\n")

# -------------------------------------------------------------------
# 7. Also prepare regional panel (employment only, for heterogeneity)
# -------------------------------------------------------------------

if (file.exists("../data/sbs_regional.csv")) {
  reg <- fread("../data/sbs_regional.csv")
  setnames(reg, c("geo", "nace_r2", "indic_sb", "values", "time"),
           c("region", "nace", "indicator", "value", "year"),
           skip_absent = TRUE)
  reg[, year := as.numeric(year)]
  reg[, nace1 := substr(nace, 1, 1)]

  reg[, treatment_group := fcase(
    nace1 %in% wave1_sectors, "treated_2017",
    nace1 %in% never_treated, "never_treated",
    default = "ambiguous"
  )]

  reg_panel <- reg[treatment_group != "ambiguous" & year >= 2012 & year <= 2019]
  setnames(reg_panel, "value", "employment")
  reg_panel[, treated := as.integer(treatment_group == "treated_2017")]
  reg_panel[, post := as.integer(year >= 2017)]
  reg_panel[, treat_post := treated * post]
  reg_panel[, log_emp := log(employment + 1)]
  reg_panel[, region_id := as.integer(factor(region))]
  reg_panel[, sector_id := as.integer(factor(nace1))]
  reg_panel[, unit_id := as.integer(factor(paste(region, nace1, sep = "_")))]
  reg_panel[, cohort := fifelse(treated == 1, 2017L, 0L)]

  # Remove NAs
  reg_panel <- reg_panel[!is.na(employment) & employment > 0]

  fwrite(reg_panel, "../data/regional_panel.csv")
  cat(sprintf("\nRegional panel: %d obs, %d regions, %d sectors\n",
              nrow(reg_panel), uniqueN(reg_panel$region), uniqueN(reg_panel$nace1)))
}
