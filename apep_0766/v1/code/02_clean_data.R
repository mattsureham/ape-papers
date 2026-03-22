## 02_clean_data.R — Construct analysis dataset
## apep_0766: Council size thresholds and infant mortality in Brazil

source("00_packages.R")
set.seed(20260322)

data_dir <- "../data/"

# ============================================================
# 1. LOAD RAW DATA
# ============================================================
cat("=== Loading raw data ===\n")

pop <- fread(file.path(data_dir, "ibge_population.csv"))
deaths <- fread(file.path(data_dir, "infant_deaths.csv"))
births <- fread(file.path(data_dir, "live_births.csv"))
thresholds <- fread(file.path(data_dir, "constitutional_thresholds.csv"))

# Harmonize year column names (BigQuery uses 'ano')
if ("ano" %in% names(deaths) && !"year" %in% names(deaths)) {
  setnames(deaths, "ano", "year")
}
if ("ano" %in% names(births) && !"year" %in% names(births)) {
  setnames(births, "ano", "year")
}

# Load council sizes if available
council_file <- file.path(data_dir, "council_sizes.csv")
has_council <- file.exists(council_file)
if (has_council) {
  council <- fread(council_file)
  cat(sprintf("Council data loaded: %d rows\n", nrow(council)))
}

cat(sprintf("Population: %d rows (%d municipalities, %d years)\n",
            nrow(pop), uniqueN(pop$muni_code), uniqueN(pop$year)))
cat(sprintf("Deaths: %d rows\n", nrow(deaths)))
cat(sprintf("Births: %d rows\n", nrow(births)))

# ============================================================
# 2. HARMONIZE MUNICIPALITY CODES
# ============================================================
cat("\n=== Harmonizing municipality codes ===\n")

# IBGE uses 7-digit codes; BigQuery data already has 6-digit codes
# Standardize to 6-digit codes throughout
pop[, muni_code6 := as.integer(substr(as.character(muni_code), 1, 6))]

# Deaths and births from BigQuery already have muni_code6
if (!"muni_code6" %in% names(deaths)) {
  deaths[, muni_code6 := as.integer(substr(as.character(muni_code), 1, 6))]
}
if (!"muni_code6" %in% names(births)) {
  births[, muni_code6 := as.integer(substr(as.character(muni_code), 1, 6))]
}

if (has_council) {
  if (!"muni_code6" %in% names(council)) {
    council[, muni_code6 := as.integer(substr(as.character(muni_code), 1, 6))]
  }
}

# ============================================================
# 3. ASSIGN CONSTITUTIONAL COUNCIL SIZE
# ============================================================
cat("\n=== Assigning constitutional council sizes ===\n")

# For each municipality-year, assign the constitutionally mandated
# minimum council size based on population
assign_min_seats <- function(population) {
  cuts <- c(0, 15000, 30000, 50000, 80000, 120000, 160000, 300000,
            450000, 600000, 750000, 900000, Inf)
  seats <- c(9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31)
  idx <- findInterval(population, cuts + 1) + 1
  idx <- pmin(idx, length(seats))
  return(seats[idx])
}

pop[, min_seats := assign_min_seats(population)]

# Verify assignment
pop[, .(n = .N, mean_pop = mean(population)),
    by = min_seats][order(min_seats)] |> print()

# ============================================================
# 4. MERGE AND CONSTRUCT ANALYSIS VARIABLES
# ============================================================
cat("\n=== Merging datasets ===\n")

# Merge population with vital statistics
panel <- merge(pop[, .(muni_code6, year, population, min_seats, muni_name)],
               deaths[, .(muni_code6, year, infant_deaths)],
               by = c("muni_code6", "year"),
               all.x = TRUE)

panel <- merge(panel, births[, .(muni_code6, year, live_births)],
               by = c("muni_code6", "year"),
               all.x = TRUE)

# Replace NA deaths/births with 0 (small municipalities may have zero events)
panel[is.na(infant_deaths), infant_deaths := 0]
panel[is.na(live_births), live_births := 0]

# Infant mortality rate per 1,000 live births
panel[, imr := fifelse(live_births > 0,
                       (infant_deaths / live_births) * 1000,
                       NA_real_)]

cat(sprintf("Panel: %d municipality-years\n", nrow(panel)))
cat(sprintf("  Municipalities: %d\n", uniqueN(panel$muni_code6)))
cat(sprintf("  Years: %s\n", paste(range(panel$year), collapse = "-")))
cat(sprintf("  Mean IMR: %.1f per 1,000\n", mean(panel$imr, na.rm = TRUE)))
cat(sprintf("  Total infant deaths: %s\n", format(sum(panel$infant_deaths), big.mark = ",")))
cat(sprintf("  Total live births: %s\n", format(sum(panel$live_births), big.mark = ",")))

# ============================================================
# 5. CONSTRUCT RDD VARIABLES
# ============================================================
cat("\n=== Constructing RDD variables ===\n")

# Define cutoff points (population thresholds where seats change)
cutoff_values <- c(15000, 30000, 50000, 80000, 120000, 160000, 300000, 450000, 600000)

# For each observation, find the nearest cutoff
panel[, nearest_cutoff := {
  dists <- outer(population, cutoff_values, FUN = function(p, c) abs(p - c))
  cutoff_values[apply(dists, 1, which.min)]
}]

# Running variable: distance to nearest cutoff (normalized)
panel[, run_var := population - nearest_cutoff]

# Treatment: above the nearest cutoff (gets more seats)
panel[, above := as.integer(run_var >= 0)]

# For pooled analysis: seats just above vs just below nearest cutoff
panel[, seats_above := assign_min_seats(nearest_cutoff)]
panel[, seats_below := assign_min_seats(nearest_cutoff - 1)]
panel[, seat_jump := seats_above - seats_below]

# Normalized running variable (as fraction of cutoff)
panel[, run_var_norm := run_var / nearest_cutoff]

# State code (first 2 digits of municipality code)
panel[, state_code := as.integer(substr(as.character(muni_code6), 1, 2))]

# ============================================================
# 6. SAMPLE RESTRICTIONS
# ============================================================
cat("\n=== Applying sample restrictions ===\n")

# Drop municipality-years with zero births (can't compute IMR)
cat(sprintf("  Before: %d obs\n", nrow(panel)))
panel <- panel[live_births > 0]
cat(sprintf("  After dropping zero births: %d obs\n", nrow(panel)))

# Drop obvious outliers in IMR (>200 per 1,000 is implausible)
panel <- panel[imr <= 200]
cat(sprintf("  After dropping IMR > 200: %d obs\n", nrow(panel)))

# Focus on the 5 most populated cutoffs for main analysis
# (enough observations on both sides)
main_cutoffs <- c(15000, 30000, 50000, 80000, 120000)
panel[, main_sample := nearest_cutoff %in% main_cutoffs]

cat(sprintf("  Main sample (5 cutoffs): %d obs\n", sum(panel$main_sample)))

# ============================================================
# 7. SUMMARY STATISTICS
# ============================================================
cat("\n=== Summary statistics ===\n")

# By cutoff
cutoff_stats <- panel[main_sample == TRUE,
                      .(n_muni_years = .N,
                        n_munis = uniqueN(muni_code6),
                        mean_pop = mean(population),
                        mean_imr = mean(imr, na.rm = TRUE),
                        mean_deaths = mean(infant_deaths),
                        mean_births = mean(live_births)),
                      by = nearest_cutoff][order(nearest_cutoff)]

print(cutoff_stats)

# Overall
cat(sprintf("\nOverall mean IMR: %.2f\n", mean(panel$imr, na.rm = TRUE)))
cat(sprintf("Overall SD IMR: %.2f\n", sd(panel$imr, na.rm = TRUE)))

# ============================================================
# 8. SAVE
# ============================================================
cat("\n=== Saving analysis dataset ===\n")
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Saved analysis_panel.csv: %d rows, %d columns\n",
            nrow(panel), ncol(panel)))

# Save cutoff summary for later use
fwrite(cutoff_stats, file.path(data_dir, "cutoff_summary.csv"))
