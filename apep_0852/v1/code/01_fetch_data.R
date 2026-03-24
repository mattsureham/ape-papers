## 01_fetch_data.R — Download CPS Food Security Supplement via Census Bureau API
## Uses Census CPS FSS microdata API: api.census.gov/data/{year}/cps/foodsec/dec

library(data.table)
library(jsonlite)

# Set working directory to paper root (parent of code/)
paper_dir <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE),
  error = function(e) normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
)
if (dir.exists(paper_dir)) setwd(paper_dir)
outdir <- "data"
if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)

cat("=== Fetching CPS Food Security Supplement data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("FATAL: CENSUS_API_KEY not set in .env")

# ── Variables to fetch ───────────────────────────────────────────
vars <- c(
  # Household identifiers
  "HRHHID", "HRHHID2", "PULINENO",
  # Relationship (to filter to reference person = household-level)
  "PERRP",
  # Food security
  "HRFS12M1",   # HH food security status 12-month (1=secure, 2=low, 3=very low)
  "HRFS12MC",   # Children's food security 12-month
  # SNAP
  "HESS2",      # SNAP receipt past 12 months
  # Geography
  "GESTFIPS",   # State FIPS
  "GTMETSTA",   # Metropolitan status
  # Household characteristics
  "HRNUMHOU",   # Household size
  "HEFAMINC",   # Family income range
  "HRPOOR",     # Income relative to 185% poverty
  "HRHTYPE",    # Household type
  "HETENURE",   # Housing tenure
  # Person demographics (reference person)
  "PRTAGE",     # Age
  "PESEX",      # Sex
  "PTDTRACE",   # Race
  "PEHSPNON",   # Hispanic origin
  "PEEDUCA",    # Education
  "PRMARSTA",   # Marital status
  # Children
  "PRCHLD",     # Presence/age of own children <18
  "PRNMCHLD",   # Number of own children <18
  # Weights
  "PWSSWGT",    # Person supplement weight
  "HWHHWGT"     # Household weight
)

# ── Fetch each year ──────────────────────────────────────────────
years <- c(2019, 2021, 2022, 2023)
all_data <- list()

for (yr in years) {
  cat(sprintf("\nFetching %d CPS FSS...\n", yr))
  base_url <- sprintf("https://api.census.gov/data/%d/cps/foodsec/dec", yr)

  # Check variable availability
  var_info <- tryCatch(
    fromJSON(sprintf("%s/variables.json", base_url)),
    error = function(e) {
      stop(sprintf("FATAL: CPS FSS API not available for %d: %s", yr, e$message))
    }
  )

  avail <- names(var_info$variables)
  valid_vars <- intersect(vars, avail)
  missing <- setdiff(vars, avail)
  if (length(missing) > 0) cat(sprintf("  Not available in %d: %s\n", yr, paste(missing, collapse = ", ")))

  # Fetch
  var_str <- paste(valid_vars, collapse = ",")
  api_url <- sprintf("%s?get=%s&key=%s", base_url, var_str, census_key)

  raw <- tryCatch(
    fromJSON(paste(readLines(api_url, warn = FALSE), collapse = "")),
    error = function(e) stop(sprintf("FATAL: API fetch failed for %d: %s", yr, e$message))
  )

  if (is.null(raw) || nrow(raw) < 2) {
    stop(sprintf("FATAL: No data returned for %d.", yr))
  }

  dt <- as.data.table(raw[-1, , drop = FALSE])
  setnames(dt, raw[1, ])
  dt[, year := yr]

  cat(sprintf("  %d: %s person-records\n", yr, format(nrow(dt), big.mark = ",")))
  all_data[[as.character(yr)]] <- dt
}

# ── Combine ──────────────────────────────────────────────────────
combined <- rbindlist(all_data, fill = TRUE)

# Convert numeric columns
num_cols <- setdiff(names(combined), c("HRHHID", "HRHHID2"))
for (col in num_cols) {
  combined[, (col) := suppressWarnings(as.numeric(get(col)))]
}

cat(sprintf("\nTotal person-records: %s across %d years\n",
            format(nrow(combined), big.mark = ","), length(all_data)))

# ── Collapse to household level (reference person) ───────────────
# PERRP: 40 = Reference person with relatives, 41 = Reference person without
# Keep reference person record for household-level analysis
hh_data <- combined[PERRP %in% c(40, 41)]
cat(sprintf("Household-level records (ref person): %s\n", format(nrow(hh_data), big.mark = ",")))

# ── Also count children by age within each household ─────────────
# Use all person records to identify school-age children (5-18)
combined[, hh_id := paste(HRHHID, HRHHID2, year, sep = "_")]
hh_data[, hh_id := paste(HRHHID, HRHHID2, year, sep = "_")]

child_counts <- combined[PRTAGE >= 5 & PRTAGE <= 18, .(n_school_age = .N), by = hh_id]
young_child <- combined[PRTAGE >= 0 & PRTAGE <= 4, .(n_young_child = .N), by = hh_id]

hh_data <- merge(hh_data, child_counts, by = "hh_id", all.x = TRUE)
hh_data <- merge(hh_data, young_child, by = "hh_id", all.x = TRUE)
hh_data[is.na(n_school_age), n_school_age := 0]
hh_data[is.na(n_young_child), n_young_child := 0]
hh_data[, has_school_age := as.integer(n_school_age > 0)]

# ── Save ─────────────────────────────────────────────────────────
fwrite(hh_data, file.path(outdir, "cps_fss_household.csv"))
fwrite(combined, file.path(outdir, "cps_fss_person.csv"))
cat(sprintf("\nSaved: %s/cps_fss_household.csv (%s households)\n",
            outdir, format(nrow(hh_data), big.mark = ",")))

# ── Validation ───────────────────────────────────────────────────
cat("\n=== Data Validation ===\n")
cat(sprintf("Years: %s\n", paste(sort(unique(hh_data$year)), collapse = ", ")))
cat(sprintf("States: %d\n", uniqueN(hh_data$GESTFIPS)))
cat("Households per year:\n")
print(hh_data[, .N, by = year][order(year)])

cat("\nFood security status (HRFS12M1) by year:\n")
print(hh_data[HRFS12M1 > 0, .N, by = .(year, HRFS12M1)][order(year, HRFS12M1)])

cat("\nSchool-age children:\n")
print(hh_data[, .(
  with_school_age = sum(has_school_age),
  without = sum(!has_school_age),
  pct_with = round(100 * mean(has_school_age), 1)
), by = year][order(year)])

# Treated states check
treated_fips <- c(6, 23, 8, 26, 27, 50, 35, 25)  # CA,ME,CO,MI,MN,VT,NM,MA
cat("\nTreated state sample sizes:\n")
print(hh_data[GESTFIPS %in% treated_fips, .N, by = .(year, GESTFIPS)][order(year, GESTFIPS)])

cat("\n=== Data fetch complete ===\n")
