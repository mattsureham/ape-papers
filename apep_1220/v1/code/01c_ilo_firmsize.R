source("00_packages.R")
data_dir <- "../data"

cat("=== Searching ILO STAT API for firm-size/enterprise-size indicators ===\n\n")

# ILO STAT has thousands of indicators. Let's search for ones with enterprise size
# Common ILO indicator patterns for enterprise size: ENT, SIZ, INS

# First, get the indicator catalog
cat("Fetching ILO indicator catalog...\n")
catalog_url <- "https://rplumber.ilo.org/data/indicator/?lang=en&type=label&format=csv"
resp <- tryCatch(httr::GET(catalog_url, httr::timeout(60)), error = function(e) NULL)

if (!is.null(resp) && httr::status_code(resp) == 200) {
  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  # Parse the catalog
  lines <- strsplit(raw, "\n")[[1]]
  cat(sprintf("  Catalog has %d lines\n", length(lines)))
  # Look for indicators mentioning enterprise size or firm size
  size_lines <- grep("size|enterprise|establishment|firm", lines, ignore.case = TRUE, value = TRUE)
  cat(sprintf("  Found %d indicators mentioning size/enterprise/firm:\n", length(size_lines)))
  for (line in head(size_lines, 20)) {
    cat(sprintf("    %s\n", substr(line, 1, 120)))
  }
} else {
  cat("  Catalog fetch failed, trying specific indicators\n")
}

cat("\n=== Trying specific ILO indicators for Ecuador by enterprise size ===\n")

# ILO indicators with enterprise size classification
# The classification code for enterprise size is typically INS or ENT
enterprise_indicators <- c(
  "EMP_TEMP_SEX_INS_NB_A",      # Employment by institutional sector
  "EMP_TEMP_SEX_ECO_INS_NB_A",  # Employment by sector and institutional
  "EAR_XEES_SEX_INS_NB_A",      # Earnings by institutional sector
  "EMP_TEMP_SEX_STE_GEO_NB_A",  # Employment by status and geography
  "EMP_NIFL_SEX_ECO_NB_A",      # Informal employment by sector
  "EMP_NIFL_SEX_INS_NB_A"       # Informal employment by institutional sector
)

for (ind in enterprise_indicators) {
  url <- sprintf(
    "https://rplumber.ilo.org/data/indicator/?id=%s&ref_area=ECU&timefrom=2008&timeto=2022&type=label&format=csv",
    ind
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    df <- tryCatch(read.csv(text = raw, stringsAsFactors = FALSE), error = function(e) NULL)
    if (!is.null(df) && nrow(df) > 0) {
      cat(sprintf("  %s: %d rows, %d cols\n", ind, nrow(df), ncol(df)))
      cat(sprintf("    Columns: %s\n", paste(names(df), collapse=", ")))
      # Show unique classif values
      classif_cols <- grep("classif", names(df), ignore.case = TRUE, value = TRUE)
      for (cc in classif_cols) {
        vals <- unique(df[[cc]])
        cat(sprintf("    %s values: %s\n", cc, paste(head(vals, 5), collapse="; ")))
      }
      saveRDS(df, file.path(data_dir, sprintf("ilo_%s_ecu.rds", tolower(ind))))
    } else {
      cat(sprintf("  %s: empty or parse error\n", ind))
    }
  } else {
    status <- if (!is.null(resp)) httr::status_code(resp) else "error"
    cat(sprintf("  %s: %s\n", ind, status))
  }
}

cat("\n=== Trying ILO informal employment indicators ===\n")

# Informal employment is key for Ecuador analysis
informal_indicators <- c(
  "EMP_NIFL_SEX_RT_A",       # Informal employment rate
  "EMP_NIFL_SEX_NB_A",       # Informal employment (number)
  "SDG_0831_SEX_RT_A",       # SDG 8.3.1 - Informal employment rate
  "SDG_0861_SEX_RT_A",       # SDG 8.6.1 - Youth NEET rate
  "SDG_A831_SEX_ECO_RT_A"    # SDG informal by sector
)

for (ind in informal_indicators) {
  url <- sprintf(
    "https://rplumber.ilo.org/data/indicator/?id=%s&ref_area=ECU&timefrom=2008&timeto=2022&type=label&format=csv",
    ind
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    df <- tryCatch(read.csv(text = raw, stringsAsFactors = FALSE), error = function(e) NULL)
    if (!is.null(df) && nrow(df) > 0) {
      cat(sprintf("  %s: %d rows\n", ind, nrow(df)))
      saveRDS(df, file.path(data_dir, sprintf("ilo_%s_ecu.rds", tolower(ind))))
    } else {
      cat(sprintf("  %s: empty\n", ind))
    }
  } else {
    cat(sprintf("  %s: not available\n", ind))
  }
}

cat("\n=== Checking what disability data we actually have ===\n")

# Reload and inspect
if (file.exists(file.path(data_dir, "ilo_disability_indicators.rds"))) {
  dsb <- readRDS(file.path(data_dir, "ilo_disability_indicators.rds"))
  for (nm in names(dsb)) {
    d <- dsb[[nm]]
    cat(sprintf("\n%s:\n", nm))
    cat(sprintf("  Rows: %d, Cols: %d\n", nrow(d), ncol(d)))
    cat(sprintf("  Columns: %s\n", paste(names(d), collapse=", ")))
    if (nrow(d) > 0) {
      print(head(d, 3))
    }
  }
}

cat("\nDone.\n")
