# 01_fetch_data.R — Fetch data from Eurostat for Poland Sunday Trading Ban
# Using NUTS-3 level data (73 Polish subregions) + comparison countries

source("00_packages.R")

if (!requireNamespace("eurostat", quietly = TRUE)) {
  install.packages("eurostat", repos = "https://cloud.r-project.org")
}
library(eurostat)

target_countries <- c("PL", "CZ", "SK", "DE")

# Helper: standardize year column from various Eurostat formats
add_year <- function(df) {
  if ("TIME_PERIOD" %in% names(df)) {
    df$year <- as.numeric(format(df$TIME_PERIOD, "%Y"))
  } else if ("time" %in% names(df)) {
    df$year <- as.numeric(df$time)
  }
  df
}

# Helper: try downloading dataset with fallback
fetch_eurostat <- function(dataset_id, ...) {
  cat(sprintf("Fetching %s...\n", dataset_id))
  tryCatch(
    get_eurostat(dataset_id, ...),
    error = function(e) {
      cat(sprintf("  %s failed: %s\n", dataset_id, e$message))
      NULL
    }
  )
}

# ============================================================================
# Step 1: Employment by NACE section at NUTS-3 level
# nama_10r_3empers — Regional accounts employment (persons) by NACE Rev.2
# ============================================================================

cat("=== Step 1: NUTS-3 employment by NACE section ===\n")

emp_raw <- fetch_eurostat("nama_10r_3empers")

if (is.null(emp_raw) || nrow(emp_raw) == 0) {
  stop("FATAL: Could not fetch employment data from Eurostat.")
}

emp_raw <- add_year(emp_raw)
cat(sprintf("Raw: %d rows, years %d-%d\n", nrow(emp_raw),
            min(emp_raw$year, na.rm=TRUE), max(emp_raw$year, na.rm=TRUE)))

emp <- emp_raw %>%
  filter(substr(geo, 1, 2) %in% target_countries,
         year >= 2013 & year <= 2022)

cat(sprintf("Filtered: %d rows\n", nrow(emp)))
cat("NACE sections:\n")
print(sort(unique(emp$nace_r2)))

# Check Polish NUTS-3 coverage
pl_nuts3 <- emp %>% filter(substr(geo, 1, 2) == "PL", nchar(geo) == 5)
cat(sprintf("Polish NUTS-3 regions: %d\n", n_distinct(pl_nuts3$geo)))

saveRDS(emp, "../data/employment_eurostat.rds")

# ============================================================================
# Step 2: Retail trade volume index (national level, monthly)
# sts_trtu_m — Turnover and volume of sales in retail trade
# ============================================================================

cat("\n=== Step 2: Retail trade monthly index ===\n")

retail_raw <- fetch_eurostat("sts_trtu_m")

if (!is.null(retail_raw) && nrow(retail_raw) > 0) {
  retail_raw <- add_year(retail_raw)
  retail <- retail_raw %>% filter(geo %in% target_countries)
  cat(sprintf("Retail monthly: %d rows\n", nrow(retail)))
  saveRDS(retail, "../data/retail_trade_monthly.rds")
} else {
  cat("WARNING: Retail trade monthly data not available.\n")
}

# ============================================================================
# Step 3: Regional unemployment at NUTS-3 (annual)
# lfst_r_lfu3rt — Unemployment rate by NUTS 3
# ============================================================================

cat("\n=== Step 3: NUTS-3 unemployment ===\n")

unemp_raw <- fetch_eurostat("lfst_r_lfu3rt")
if (is.null(unemp_raw)) {
  unemp_raw <- fetch_eurostat("lfst_r_lfu3pers")
}

if (!is.null(unemp_raw) && nrow(unemp_raw) > 0) {
  unemp_raw <- add_year(unemp_raw)
  unemp <- unemp_raw %>%
    filter(substr(geo, 1, 2) %in% target_countries,
           year >= 2013 & year <= 2022)
  cat(sprintf("Unemployment: %d rows\n", nrow(unemp)))
  saveRDS(unemp, "../data/unemployment_eurostat.rds")
} else {
  cat("WARNING: Unemployment data not available.\n")
}

# ============================================================================
# Step 4: Regional GDP at NUTS-3
# nama_10r_3gdp — GDP at current market prices by NUTS 3
# ============================================================================

cat("\n=== Step 4: NUTS-3 GDP ===\n")

gdp_raw <- fetch_eurostat("nama_10r_3gdp")

if (!is.null(gdp_raw) && nrow(gdp_raw) > 0) {
  gdp_raw <- add_year(gdp_raw)
  gdp <- gdp_raw %>%
    filter(substr(geo, 1, 2) %in% target_countries,
           year >= 2013 & year <= 2022)
  cat(sprintf("GDP: %d rows\n", nrow(gdp)))
  saveRDS(gdp, "../data/gdp_eurostat.rds")
} else {
  cat("WARNING: GDP data not available.\n")
}

# ============================================================================
# Summary + validation
# ============================================================================

cat("\n=== DATA FETCH SUMMARY ===\n")
for (f in c("employment_eurostat", "retail_trade_monthly",
            "unemployment_eurostat", "gdp_eurostat")) {
  path <- paste0("../data/", f, ".rds")
  if (file.exists(path)) {
    d <- readRDS(path)
    cat(sprintf("  %-25s %7d rows  OK\n", f, nrow(d)))
  } else {
    cat(sprintf("  %-25s MISSING\n", f))
  }
}

# Hard validation
stopifnot("Employment data must exist" = file.exists("../data/employment_eurostat.rds"))
emp_check <- readRDS("../data/employment_eurostat.rds")
pl3 <- emp_check %>% filter(substr(geo, 1, 2) == "PL", nchar(geo) == 5)
n_regions <- n_distinct(pl3$geo)
cat(sprintf("\nPolish NUTS-3 regions with employment data: %d\n", n_regions))
stopifnot("Need >= 20 Polish NUTS-3 regions" = n_regions >= 20)

cat("\nData fetch complete.\n")
