## =============================================================================
## 01b_parse_grants.R — Parse public health grant exposition books
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")
library(readODS)  # For .ods files

## ---------------------------------------------------------------------------
## Strategy: Each file has different structure. We extract LA codes + total
## grant amounts by finding rows with ONS codes (E06*, E08*, E09*, E10*)
## ---------------------------------------------------------------------------

parse_grant_generic <- function(filepath, fin_year) {
  ext <- tools::file_ext(filepath)
  cat(sprintf("Parsing %s (%s)...\n", fin_year, ext))

  ## Read all sheets
  if (ext == "xlsx") {
    sheets <- readxl::excel_sheets(filepath)
  } else {
    sheets <- readODS::list_ods_sheets(filepath)
  }

  results <- data.table()

  for (sh in sheets) {
    ## Read sheet with all data as character
    dt <- tryCatch({
      if (ext == "xlsx") {
        as.data.table(readxl::read_excel(filepath, sheet = sh, col_types = "text"))
      } else {
        as.data.table(readODS::read_ods(filepath, sheet = sh))
      }
    }, error = function(e) {
      cat(sprintf("  Error reading sheet '%s': %s\n", sh, e$message))
      return(data.table())
    })

    if (nrow(dt) == 0) next

    ## Find column containing LA codes
    code_col <- NULL
    for (j in seq_len(ncol(dt))) {
      vals <- dt[[j]]
      if (sum(grepl("^E0[6-9]|^E10", vals), na.rm = TRUE) > 20) {
        code_col <- j
        break
      }
    }

    if (is.null(code_col)) next

    ## Extract rows with LA codes
    la_rows <- which(grepl("^E0[6-9]|^E10", dt[[code_col]]))
    if (length(la_rows) < 10) next

    cat(sprintf("  Sheet '%s': found %d LAs in col %d\n", sh, length(la_rows), code_col))

    ## Extract LA code and name
    la_codes <- dt[[code_col]][la_rows]
    la_names <- if (code_col + 1 <= ncol(dt)) dt[[code_col + 1]][la_rows] else NA_character_

    ## Find header row (one row before first LA data)
    header_row <- la_rows[1] - 1
    if (header_row < 1) header_row <- 1
    headers <- as.character(dt[header_row])

    ## Look for allocation columns containing numbers (£'000 or per head)
    ## Try columns after the name column
    for (j in (code_col + 2):min(ncol(dt), code_col + 20)) {
      vals <- suppressWarnings(as.numeric(gsub(",", "", dt[[j]][la_rows])))
      n_valid <- sum(!is.na(vals) & vals > 0)

      if (n_valid > 20) {
        ## Check if this looks like a per-head figure (typically 30-120)
        ## or total allocation (typically 1000-500000 in £'000)
        median_val <- median(vals, na.rm = TRUE)
        is_per_head <- median_val > 10 & median_val < 300
        is_total_k <- median_val > 500

        ## Get the header for this column
        col_header <- headers[j]
        if (is.na(col_header)) col_header <- paste0("col_", j)

        if (is_per_head) {
          cat(sprintf("    Col %d ('%s'): per-head values (median=%.0f, n=%d)\n",
                      j, substr(col_header, 1, 40), median_val, n_valid))

          ## Determine which year this column represents
          ## Look at the header for year indicators
          year_match <- regmatches(col_header, regexpr("20\\d{2}", col_header))
          if (length(year_match) == 0) year_match <- sub("^(\\d{4})-.*", "\\1", fin_year)

          results <- rbind(results, data.table(
            la_code = la_codes,
            la_name = la_names,
            fin_year = fin_year,
            year_approx = as.integer(year_match[1]),
            ph_grant_per_head = vals,
            source_col = col_header,
            source_sheet = sh
          ), fill = TRUE)
          break  # Take first per-head column found
        }
      }
    }
  }

  if (nrow(results) == 0) {
    cat(sprintf("  WARNING: Could not parse per-head data from %s\n", fin_year))
  }
  results
}

## ---------------------------------------------------------------------------
## Parse all grant files
## ---------------------------------------------------------------------------
grant_files <- list.files(DATA_DIR, pattern = "^grant_", full.names = TRUE)
cat(sprintf("Found %d grant files\n", length(grant_files)))

all_grants <- data.table()
for (f in grant_files) {
  fin_year <- sub(".*grant_(.+)\\.(xlsx|ods)$", "\\1", basename(f))
  parsed <- parse_grant_generic(f, fin_year)
  all_grants <- rbind(all_grants, parsed, fill = TRUE)
}

cat(sprintf("\nTotal parsed: %d rows, %d unique LAs, %d years\n",
            nrow(all_grants),
            uniqueN(all_grants$la_code),
            uniqueN(all_grants$fin_year)))

## ---------------------------------------------------------------------------
## Assign calendar years and deduplicate
## ---------------------------------------------------------------------------
## Financial year "2016-17" → calendar year 2016 (start of FY)
all_grants[, year := as.integer(sub("^(\\d{4}).*", "\\1", fin_year))]

## Remove duplicates: keep one grant per LA-year
all_grants <- all_grants[!is.na(ph_grant_per_head) & ph_grant_per_head > 0]
all_grants <- all_grants[order(la_code, year)]
all_grants <- unique(all_grants, by = c("la_code", "year"))

## Also try to recover 2013-15 data from the 2016-17 file (which has baseline columns)
## The 2016-17 file has "2015/16 baseline" in its first sheet

cat("\n=== Grant Panel Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(all_grants)))
cat(sprintf("Unique LAs: %d\n", uniqueN(all_grants$la_code)))
cat(sprintf("Year range: %s\n", paste(sort(unique(all_grants$year)), collapse = ", ")))
cat(sprintf("Mean per-head grant: £%.0f (sd=%.0f)\n",
            mean(all_grants$ph_grant_per_head, na.rm = TRUE),
            sd(all_grants$ph_grant_per_head, na.rm = TRUE)))

## Save
fwrite(all_grants, file.path(DATA_DIR, "grant_panel.csv"))
cat("✓ Grant panel saved\n")
