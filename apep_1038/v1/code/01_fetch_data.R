# 01_fetch_data.R — Fetch TRI data from EPA Envirofacts API
# Focus: facility-level panel 1988-2006 for the 1998 sector expansion analysis
# Strategy: fetch form data year by year, then aggregate to facility-year level

library(httr)
library(jsonlite)
library(data.table)

if (requireNamespace("here", quietly = TRUE)) setwd(here::here()) else setwd(dirname(dirname(sys.frame(1)$ofile)))
data_dir <- "data"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# -----------------------------------------------------------------
# EPA Envirofacts API helper with pagination
# -----------------------------------------------------------------
epa_fetch <- function(table, conditions, start = 0, rows = 10000) {
  parts <- paste(sapply(seq_along(conditions), function(i) {
    paste0(names(conditions)[i], "/", conditions[[i]])
  }), collapse = "/")
  url <- sprintf("https://data.epa.gov/efservice/%s/%s/rows/%d:%d/JSON",
                 table, parts, start, start + rows - 1)
  resp <- GET(url, timeout(120))
  if (status_code(resp) != 200) {
    stop("API error ", status_code(resp), " for ", url)
  }
  txt <- content(resp, as = "text", encoding = "UTF-8")
  if (nchar(txt) < 5 || txt == "[]") return(NULL)
  fromJSON(txt, flatten = TRUE)
}

epa_fetch_all <- function(table, conditions, batch = 10000, max_rows = 300000) {
  chunks <- list()
  start <- 0
  repeat {
    cat("  rows", start, "-", start + batch - 1, "... ")
    d <- epa_fetch(table, conditions, start, batch)
    if (is.null(d) || nrow(d) == 0) { cat("done\n"); break }
    cat(nrow(d), "rows\n")
    chunks[[length(chunks) + 1]] <- as.data.table(d)
    if (nrow(d) < batch || start + batch >= max_rows) break
    start <- start + batch
    Sys.sleep(0.3)
  }
  if (length(chunks) == 0) return(data.table())
  rbindlist(chunks, fill = TRUE)
}

# -----------------------------------------------------------------
# 1. Fetch facility metadata
# -----------------------------------------------------------------
cat("=== Fetching TRI Facility Metadata ===\n")
fac <- epa_fetch_all("tri_facility", conditions = list(), batch = 10000, max_rows = 50000)
cat("Total facilities:", nrow(fac), "\n")

# Keep key columns
fac_cols <- intersect(names(fac), c(
  "tri_facility_id", "facility_name", "street_address", "city_name",
  "county_name", "state_abbr", "zip_code", "region",
  "primary_sic_code", "primary_naics_code",
  "latitude", "longitude", "frs_id", "federal_facility"
))
fac_clean <- fac[, ..fac_cols]
fwrite(fac_clean, "tri_facilities.csv")
cat("Saved tri_facilities.csv\n\n")

# -----------------------------------------------------------------
# 2. Fetch form data year by year (1988-2006)
# -----------------------------------------------------------------
cat("=== Fetching TRI Reporting Forms (1988-2006) ===\n")

# For each year, we need: facility_id, chemical_id, and linkage to releases
# The form table is large (~75-90K rows/year) so we paginate
years <- 1988:2006
all_forms <- list()

for (yr in years) {
  cat("\nYear", yr, ":\n")
  forms_yr <- epa_fetch_all(
    "tri_reporting_form",
    conditions = list("REPORTING_YEAR" = as.character(yr)),
    batch = 10000,
    max_rows = 200000
  )
  if (nrow(forms_yr) > 0) {
    # Keep only columns we need
    keep <- intersect(names(forms_yr), c(
      "doc_ctrl_num", "tri_facility_id", "tri_chem_id",
      "reporting_year", "form_type_ind", "facility_id"
    ))
    forms_yr <- forms_yr[, ..keep]
    all_forms[[length(all_forms) + 1]] <- forms_yr
    cat("  => Kept", nrow(forms_yr), "form records\n")
  }
}

forms_dt <- rbindlist(all_forms, fill = TRUE)
cat("\n=== Total form records:", nrow(forms_dt), "===\n")
fwrite(forms_dt, "tri_forms.csv")

# -----------------------------------------------------------------
# 3. Fetch release quantities year by year
# -----------------------------------------------------------------
cat("\n=== Fetching TRI Release Quantities (1988-2006) ===\n")

all_releases <- list()

for (yr in years) {
  cat("\nYear", yr, ":\n")
  rel_yr <- epa_fetch_all(
    "tri_release_qty",
    conditions = list("REPORTING_YEAR" = as.character(yr)),
    batch = 10000,
    max_rows = 500000
  )
  if (nrow(rel_yr) > 0) {
    keep <- intersect(names(rel_yr), c(
      "doc_ctrl_num", "tri_facility_id", "reporting_year",
      "total_release", "environmental_medium",
      "on_site_release_total", "off_site_release_total",
      "release_qty_me"
    ))
    rel_yr <- rel_yr[, ..keep]
    all_releases[[length(all_releases) + 1]] <- rel_yr
    cat("  => Kept", nrow(rel_yr), "release records\n")
  }
}

releases_dt <- rbindlist(all_releases, fill = TRUE)
cat("\n=== Total release records:", nrow(releases_dt), "===\n")
fwrite(releases_dt, "tri_releases.csv")

# -----------------------------------------------------------------
# 4. Summary statistics
# -----------------------------------------------------------------
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("Facilities:", nrow(fac_clean), "\n")
cat("Forms:", nrow(forms_dt), "\n")
cat("Release records:", nrow(releases_dt), "\n")
cat("Years covered:", paste(range(years), collapse = "-"), "\n")

# Form counts by year
form_counts <- forms_dt[, .N, by = reporting_year][order(reporting_year)]
cat("\nForms by year:\n")
print(form_counts)

# Validate the 1997→1998 jump
if (1997 %in% form_counts$reporting_year && 1998 %in% form_counts$reporting_year) {
  n97 <- form_counts[reporting_year == 1997, N]
  n98 <- form_counts[reporting_year == 1998, N]
  cat(sprintf("\n1997: %d forms -> 1998: %d forms (%.1f%% increase)\n",
              n97, n98, (n98/n97 - 1) * 100))
}

cat("\nData fetch complete.\n")
