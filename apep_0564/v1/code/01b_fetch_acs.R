## =============================================================================
## 01b_fetch_acs.R — Fetch Census ACS County Demographics
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("Fetching Census ACS data...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  cat("WARNING: No CENSUS_API_KEY set. Using unauthenticated requests.\n")
  key_param <- ""
} else {
  key_param <- paste0("&key=", census_key)
  cat("Using Census API key.\n")
}

acs_vars <- c(
  "B05001_006E", "B05001_001E",  # Noncitizen
  "B05002_013E", "B05002_001E",  # Foreign born
  "B17001_002E", "B17001_001E",  # Poverty
  "B01003_001E",                  # Total pop
  "B23025_002E", "B23025_005E",  # Labor force, unemployed
  "NAME"
)

acs_years <- 2009:2023

acs_all <- list()
for (yr in acs_years) {
  acs_file <- file.path(data_dir, paste0("acs_", yr, ".csv"))

  if (!file.exists(acs_file)) {
    vars_str <- paste(acs_vars, collapse = ",")
    url <- paste0("https://api.census.gov/data/", yr,
                  "/acs/acs5?get=", vars_str,
                  "&for=county:*", key_param)

    cat("  Fetching ACS", yr, "...")
    resp <- tryCatch({
      r <- GET(url, timeout(120))
      if (status_code(r) == 200) {
        json <- content(r, as = "text", encoding = "UTF-8")
        mat <- fromJSON(json)
        df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
        names(df) <- mat[1, ]
        df$year <- yr
        fwrite(df, acs_file)
        cat(" OK (", nrow(df), "counties)\n")
        df
      } else {
        cat(" FAILED (HTTP", status_code(r), ")\n")
        NULL
      }
    }, error = function(e) {
      cat(" ERROR:", e$message, "\n")
      NULL
    })

    Sys.sleep(1)  # Rate limiting
  } else {
    cat("  ACS", yr, "already exists\n")
  }

  if (file.exists(acs_file)) {
    acs_all[[as.character(yr)]] <- fread(acs_file)
  }
}

acs <- rbindlist(acs_all, fill = TRUE)
cat("\nACS data combined:", nrow(acs), "rows,",
    length(unique(acs$year)), "years\n")

fwrite(acs, file.path(data_dir, "acs_combined.csv"))

# Validation
stopifnot("ACS must cover 3000+ counties" = nrow(acs) > 3000)
cat("ACS validation passed.\n")
