## 01_fetch_data.R — Fetch Eurostat ICT security data
## apep_1089: NIS2 Cybersecurity Regulation and Firm Security Investment

source("code/00_packages.R")

cat("=== Fetching Eurostat ICT Security Data ===\n")

# ----------------------------------------------------------------
# 1. Fetch isoc_cisce_ra: ICT security measures in enterprises
# ----------------------------------------------------------------

cat("Fetching isoc_cisce_ra (ICT security measures)...\n")

# Try the eurostat package first
ict_security <- tryCatch(
  {
    dat <- get_eurostat("isoc_cisce_ra", time_format = "num")
    if (is.null(dat) || nrow(dat) == 0) stop("Empty data returned")
    dat
  },
  error = function(e) {
    cat("eurostat package fetch failed:", conditionMessage(e), "\n")
    cat("Trying direct API...\n")
    # Direct Eurostat JSON API as fallback
    url <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/isoc_cisce_ra?format=JSON&lang=en"
    stop("Direct API fallback not implemented. eurostat package must work. Error: ", conditionMessage(e))
  }
)

cat(sprintf("  Fetched %d rows from isoc_cisce_ra\n", nrow(ict_security)))

# Validate: data must not be empty
stopifnot("No data fetched from isoc_cisce_ra" = nrow(ict_security) > 0)

# ----------------------------------------------------------------
# 2. Fetch isoc_cisce_ic: ICT security incidents
# ----------------------------------------------------------------

cat("Fetching isoc_cisce_ic (ICT security incidents)...\n")

ict_incidents <- tryCatch(
  {
    dat <- get_eurostat("isoc_cisce_ic", time_format = "num")
    if (is.null(dat) || nrow(dat) == 0) {
      cat("  Warning: isoc_cisce_ic returned empty. Proceeding without incident data.\n")
      NULL
    } else {
      dat
    }
  },
  error = function(e) {
    cat("  Warning: Could not fetch isoc_cisce_ic:", conditionMessage(e), "\n")
    cat("  Proceeding without incident data.\n")
    NULL
  }
)

if (!is.null(ict_incidents)) {
  cat(sprintf("  Fetched %d rows from isoc_cisce_ic\n", nrow(ict_incidents)))
}

# ----------------------------------------------------------------
# 3. Examine data structure
# ----------------------------------------------------------------

cat("\n=== Data Structure ===\n")
cat("Columns:", paste(names(ict_security), collapse = ", "), "\n")

# Check available indicators
cat("\nUnique indic_is values:\n")
indicators <- sort(unique(ict_security$indic_is))
for (ind in indicators) {
  n <- sum(ict_security$indic_is == ind & !is.na(ict_security$values))
  cat(sprintf("  %s: %d non-null obs\n", ind, n))
}

# Check size classes
cat("\nUnique sizen_r2 values:\n")
print(table(ict_security$sizen_r2))

# Check time periods
cat("\nUnique time values:\n")
print(sort(unique(ict_security$time)))

# Check geographic coverage
cat("\nUnique geo values:\n")
geos <- sort(unique(ict_security$geo))
cat(paste(geos, collapse = ", "), "\n")

# Check unit
cat("\nUnique unit values:\n")
print(table(ict_security$unit))

# ----------------------------------------------------------------
# 4. Save raw data
# ----------------------------------------------------------------

saveRDS(ict_security, "data/ict_security_raw.rds")
if (!is.null(ict_incidents)) {
  saveRDS(ict_incidents, "data/ict_incidents_raw.rds")
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("Saved %d rows to data/ict_security_raw.rds\n", nrow(ict_security)))
