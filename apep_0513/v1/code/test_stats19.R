# Test STATS19 data access
# Research-only: checking data availability, columns, geographic coverage

cat("=== STATS19 Data Access Test ===\n\n")

# 1. Install and load stats19
if (!require("stats19", quietly = TRUE)) {
  install.packages("stats19", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(stats19)

cat("stats19 package loaded successfully.\n\n")

# 2. Check what years of data are available
cat("=== Available Data ===\n")
# stats19 provides data from 1979 onwards; let's see what dl_stats19 supports
# The package has get_stats19() which downloads from DfT

# 3. Download accidents (collision) data for 2022 and 2023
cat("--- Downloading collision data for 2022 ---\n")
collisions_2022 <- tryCatch(
  get_stats19(year = 2022, type = "collision"),
  error = function(e) { cat("Error 2022:", e$message, "\n"); NULL }
)

cat("--- Downloading collision data for 2023 ---\n")
collisions_2023 <- tryCatch(
  get_stats19(year = 2023, type = "collision"),
  error = function(e) { cat("Error 2023:", e$message, "\n"); NULL }
)

# Also try casualty data
cat("\n--- Downloading casualty data for 2022 ---\n")
casualties_2022 <- tryCatch(
  get_stats19(year = 2022, type = "casualty"),
  error = function(e) { cat("Error casualties 2022:", e$message, "\n"); NULL }
)

cat("--- Downloading casualty data for 2023 ---\n")
casualties_2023 <- tryCatch(
  get_stats19(year = 2023, type = "casualty"),
  error = function(e) { cat("Error casualties 2023:", e$message, "\n"); NULL }
)

# 4. Examine collision data columns
cat("\n=== COLLISION DATA STRUCTURE ===\n")
if (!is.null(collisions_2022)) {
  cat("\nDimensions (2022):", nrow(collisions_2022), "rows x", ncol(collisions_2022), "cols\n")
  cat("\nColumn names:\n")
  print(names(collisions_2022))

  cat("\n--- Sample of first 3 rows ---\n")
  print(head(collisions_2022, 3))

  # Check specific columns of interest
  cat("\n--- accident_severity ---\n")
  if ("accident_severity" %in% names(collisions_2022)) {
    print(table(collisions_2022$accident_severity, useNA = "ifany"))
  } else {
    cat("NOT FOUND. Looking for similar columns:\n")
    print(grep("sever", names(collisions_2022), value = TRUE, ignore.case = TRUE))
  }

  cat("\n--- speed_limit ---\n")
  if ("speed_limit" %in% names(collisions_2022)) {
    print(table(collisions_2022$speed_limit, useNA = "ifany"))
  } else {
    cat("NOT FOUND. Looking for similar columns:\n")
    print(grep("speed", names(collisions_2022), value = TRUE, ignore.case = TRUE))
  }

  cat("\n--- road_type ---\n")
  if ("road_type" %in% names(collisions_2022)) {
    print(table(collisions_2022$road_type, useNA = "ifany"))
  } else {
    cat("NOT FOUND. Looking for similar columns:\n")
    print(grep("road", names(collisions_2022), value = TRUE, ignore.case = TRUE))
  }

  cat("\n--- local_authority_district ---\n")
  if ("local_authority_district" %in% names(collisions_2022)) {
    cat("Present. Unique values:", length(unique(collisions_2022$local_authority_district)), "\n")
    cat("Sample values:\n")
    print(head(sort(unique(collisions_2022$local_authority_district)), 20))
  } else {
    cat("NOT FOUND. Looking for similar columns:\n")
    print(grep("local|authority|district|la_", names(collisions_2022), value = TRUE, ignore.case = TRUE))
  }

  # Check for local authority codes (ONS codes)
  cat("\n--- Looking for LA codes (ONS style E/W codes) ---\n")
  la_code_cols <- grep("local_authority|lad|la_code|ons", names(collisions_2022), value = TRUE, ignore.case = TRUE)
  cat("Matching columns:", paste(la_code_cols, collapse = ", "), "\n")
  for (col in la_code_cols) {
    cat("\nColumn:", col, "\n")
    cat("Sample values:\n")
    print(head(sort(unique(collisions_2022[[col]])), 15))
  }

  cat("\n--- date field ---\n")
  if ("date" %in% names(collisions_2022)) {
    cat("Class:", class(collisions_2022$date), "\n")
    cat("Range:", as.character(range(collisions_2022$date, na.rm = TRUE)), "\n")

    # Monthly granularity check
    cat("\nMonthly distribution:\n")
    collisions_2022$month <- format(collisions_2022$date, "%Y-%m")
    print(table(collisions_2022$month))
  } else {
    cat("NOT FOUND. Looking for date-like columns:\n")
    print(grep("date|time|year|month", names(collisions_2022), value = TRUE, ignore.case = TRUE))
  }
}

# 5. Welsh vs English identification
cat("\n\n=== WELSH vs ENGLISH LOCAL AUTHORITIES ===\n")
if (!is.null(collisions_2022)) {
  # Look for any column that might have ONS codes (starting with E or W)
  for (col in names(collisions_2022)) {
    vals <- as.character(collisions_2022[[col]])
    w_count <- sum(grepl("^W", vals), na.rm = TRUE)
    e_count <- sum(grepl("^E0", vals), na.rm = TRUE)
    if (w_count > 100 & e_count > 100) {
      cat("\nColumn '", col, "' has Welsh (W*) and English (E0*) codes:\n", sep = "")
      cat("  Welsh (W*) rows:", w_count, "\n")
      cat("  English (E0*) rows:", e_count, "\n")
      cat("  Scottish (S*) rows:", sum(grepl("^S", vals), na.rm = TRUE), "\n")
      cat("  Other/NA:", nrow(collisions_2022) - w_count - e_count - sum(grepl("^S", vals), na.rm = TRUE), "\n")
    }
  }

  # Also check if there's a police_force or similar column
  cat("\n--- police_force ---\n")
  if ("police_force" %in% names(collisions_2022)) {
    cat("Present. Unique values:\n")
    pf_tab <- sort(table(collisions_2022$police_force), decreasing = TRUE)
    print(pf_tab)
  } else {
    cat("NOT FOUND. Looking for similar:\n")
    print(grep("police|force", names(collisions_2022), value = TRUE, ignore.case = TRUE))
  }
}

# 6. Examine casualty data
cat("\n\n=== CASUALTY DATA STRUCTURE ===\n")
if (!is.null(casualties_2022)) {
  cat("\nDimensions (2022):", nrow(casualties_2022), "rows x", ncol(casualties_2022), "cols\n")
  cat("\nColumn names:\n")
  print(names(casualties_2022))

  cat("\n--- casualty_severity ---\n")
  if ("casualty_severity" %in% names(casualties_2022)) {
    print(table(casualties_2022$casualty_severity, useNA = "ifany"))
  }

  cat("\n--- casualty_type ---\n")
  if ("casualty_type" %in% names(casualties_2022)) {
    print(table(casualties_2022$casualty_type, useNA = "ifany"))
  }
}

# 7. Check 2023 data
cat("\n\n=== 2023 DATA CHECK ===\n")
if (!is.null(collisions_2023)) {
  cat("2023 collisions: ", nrow(collisions_2023), "rows\n")
} else {
  cat("2023 collision data NOT available.\n")
}
if (!is.null(casualties_2023)) {
  cat("2023 casualties: ", nrow(casualties_2023), "rows\n")
} else {
  cat("2023 casualty data NOT available.\n")
}

# 8. Try older years to see range
cat("\n\n=== TESTING YEAR RANGE ===\n")
for (yr in c(2019, 2020, 2021)) {
  result <- tryCatch({
    d <- get_stats19(year = yr, type = "collision")
    cat(yr, ": ", nrow(d), " rows\n", sep = "")
  }, error = function(e) {
    cat(yr, ": ERROR - ", e$message, "\n", sep = "")
  })
}

# 9. Check if vehicle data is available (has vehicle type info)
cat("\n\n=== VEHICLE DATA (2022) ===\n")
vehicles_2022 <- tryCatch(
  get_stats19(year = 2022, type = "vehicle"),
  error = function(e) { cat("Error:", e$message, "\n"); NULL }
)
if (!is.null(vehicles_2022)) {
  cat("Dimensions:", nrow(vehicles_2022), "rows x", ncol(vehicles_2022), "cols\n")
  cat("\nColumn names:\n")
  print(names(vehicles_2022))

  cat("\n--- vehicle_type ---\n")
  if ("vehicle_type" %in% names(vehicles_2022)) {
    print(table(vehicles_2022$vehicle_type, useNA = "ifany"))
  }
}

cat("\n\n=== TEST COMPLETE ===\n")
