# 01b_fetch_pxweb.R — Direct PXWeb query for GWS register data
# Check all GWS tables with Jahr dimension for post-2010 data

source("00_packages.R")

bfs_base <- "https://www.pxweb.bfs.admin.ch/api/v1/de"

# Tables confirmed to have Jahr + Kanton dimensions
tables_with_year <- c(
  "px-x-0902020100_111", # Buildings by canton, category, stories, etc + Jahr
  "px-x-0902020100_112", # Buildings by canton, energy source + Jahr
  "px-x-0902020100_113", # Buildings by canton, owner type + Jahr
  "px-x-0902020100_121", # Buildings by canton, category, period + Jahr
  "px-x-0902020100_122", # Buildings by canton, energy source + Jahr (older format)
  "px-x-0902020100_123", # Buildings by canton, owner type + Jahr (older format)
  "px-x-0902020100_141", # Dwellings by canton, rooms + Jahr
  "px-x-0902020100_151"  # Dwellings by canton, rooms + Jahr
)

cat("=== Checking year ranges for all GWS tables ===\n\n")

for (tbl_id in tables_with_year) {
  url <- paste0(bfs_base, "/", tbl_id, "/", tbl_id, ".px")
  resp <- httr::GET(url, httr::timeout(30))

  if (httr::status_code(resp) == 200) {
    meta <- httr::content(resp, as = "parsed")

    # Find the year variable
    for (v in meta$variables) {
      if (grepl("Jahr|Year|Datum", v$text, ignore.case = TRUE)) {
        years <- v$valueTexts
        cat(tbl_id, "| Year:", paste(years, collapse=", "), "\n")

        # Check if any years > 2010
        year_nums <- as.numeric(gsub("[^0-9]", "", years))
        max_year <- max(year_nums, na.rm = TRUE)
        if (max_year > 2010) {
          cat("  >>> HAS POST-2010 DATA (max:", max_year, ")\n")

          # Print all variables
          for (vv in meta$variables) {
            cat("  Var:", vv$code, "(", vv$text, "):",
                length(vv$values), "vals\n")
            cat("    Values:", paste(head(vv$valueTexts, 12), collapse="; "), "\n")
          }
          cat("\n")
        }
        break
      }
    }
  }
}

# Also check if there are additional tables in higher number ranges
cat("\n=== Checking for newer GWS tables (200+) ===\n")
newer_ids <- paste0("px-x-0902020100_", c(
  201:210, 301:310, 401:410
))

for (tbl_id in newer_ids) {
  url <- paste0(bfs_base, "/", tbl_id, "/", tbl_id, ".px")
  resp <- httr::GET(url, httr::timeout(15))
  if (httr::status_code(resp) == 200) {
    meta <- httr::content(resp, as = "parsed")
    vars <- sapply(meta$variables, function(v) v$text)
    cat(tbl_id, ":", paste(vars, collapse=" | "), "\n")

    for (v in meta$variables) {
      if (grepl("Jahr|Year", v$text, ignore.case = TRUE)) {
        cat("  YEARS:", paste(v$valueTexts, collapse=", "), "\n")
      }
    }
  }
}

# Check the 09030 and 09040 series (construction activity, new buildings)
cat("\n=== Checking construction/new buildings tables ===\n")
construction_ids <- paste0("px-x-0903020000_", c(101, 102, 103, 111, 112, 113, 121, 122, 123))
for (tbl_id in construction_ids) {
  url <- paste0(bfs_base, "/", tbl_id, "/", tbl_id, ".px")
  resp <- httr::GET(url, httr::timeout(15))
  if (httr::status_code(resp) == 200) {
    meta <- httr::content(resp, as = "parsed")
    vars <- sapply(meta$variables, function(v) v$text)
    has_energy <- any(grepl("Energie|Heiz|heat", vars, ignore.case = TRUE))

    if (has_energy) {
      cat(tbl_id, ": ***", paste(vars, collapse=" | "), "\n")
      for (v in meta$variables) {
        cat("  ", v$code, "(", v$text, "):", length(v$values), "vals -",
            paste(head(v$valueTexts, 8), collapse="; "), "\n")
      }
    }
  }
}

# Check 0904 series (building permits)
cat("\n=== Checking building permits tables ===\n")
permit_ids <- paste0("px-x-0904010000_", c(111, 112, 113, 201, 202, 203, 204, 205))
for (tbl_id in permit_ids) {
  url <- paste0(bfs_base, "/", tbl_id, "/", tbl_id, ".px")
  resp <- httr::GET(url, httr::timeout(15))
  if (httr::status_code(resp) == 200) {
    meta <- httr::content(resp, as = "parsed")
    vars <- sapply(meta$variables, function(v) v$text)
    has_energy <- any(grepl("Energie|Heiz|heat|Wärme", vars, ignore.case = TRUE))
    has_canton <- any(grepl("Kanton|canton", vars, ignore.case = TRUE))

    if (has_energy || has_canton) {
      flag <- paste(if(has_energy) "[ENERGY]", if(has_canton) "[CANTON]")
      cat(tbl_id, ":", paste(vars, collapse=" | "), flag, "\n")
      for (v in meta$variables) {
        if (grepl("Jahr|Year|Energie|Heiz|Kanton", v$text, ignore.case = TRUE)) {
          cat("  ", v$code, "(", v$text, "):", paste(head(v$valueTexts, 10), collapse="; "), "\n")
        }
      }
    }
  }
}

cat("\n=== Complete ===\n")
