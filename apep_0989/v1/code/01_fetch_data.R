# 01_fetch_data.R — Fetch Czech business and Eurostat data
# Czech EET and Business Dynamics (apep_0989)

source("00_packages.R")

cat("=== Fetching CZSO business entity data ===\n")

# ---------------------------------------------------------------
# 1. CZSO: Quarterly business entities by ORP district
# ---------------------------------------------------------------
# CZSO open data table 140131: "Organizační statistika"
# Contains: number of economic subjects by legal form, ORP district, quarter

# First, let's explore available CZSO tables related to business statistics
cat("Searching for relevant CZSO datasets...\n")
czso_tables <- czso::czso_get_catalogue()
biz_tables <- czso_tables[grepl("podnik|organiz|subjekt|economic|business|entreprise",
                                 czso_tables$title, ignore.case = TRUE) |
                           grepl("podnik|organiz|subjekt",
                                 czso_tables$description, ignore.case = TRUE), ]
cat("Found", nrow(biz_tables), "business-related tables:\n")
print(biz_tables[, c("dataset_id", "title")])

# Try the main business register table
# CZSO dataset 140131 = "Organizační statistika"
cat("\nFetching CZSO dataset 140131 (Organizational statistics)...\n")
tryCatch({
  biz_data <- czso::czso_get_table("140131")
  cat("Success! Dimensions:", nrow(biz_data), "rows x", ncol(biz_data), "cols\n")
  cat("Columns:", paste(names(biz_data), collapse = ", "), "\n")
  cat("Sample:\n")
  print(head(biz_data, 10))
  cat("\nTime range:", range(biz_data$rok, na.rm = TRUE), "\n")
  saveRDS(biz_data, "../data/czso_business_raw.rds")
  cat("Saved to data/czso_business_raw.rds\n")
}, error = function(e) {
  cat("ERROR fetching 140131:", e$message, "\n")
  cat("Trying alternative dataset IDs...\n")

  # Try alternative IDs for business statistics
  for (alt_id in c("140141", "140133", "140130", "140142")) {
    tryCatch({
      cat("  Trying", alt_id, "...\n")
      test_data <- czso::czso_get_table(alt_id)
      cat("  SUCCESS with", alt_id, ":", nrow(test_data), "rows\n")
      cat("  Columns:", paste(names(test_data), collapse = ", "), "\n")
      biz_data <<- test_data
      saveRDS(biz_data, "../data/czso_business_raw.rds")
      cat("  Saved to data/czso_business_raw.rds\n")
      break
    }, error = function(e2) {
      cat("  Failed:", e2$message, "\n")
    })
  }
})

# ---------------------------------------------------------------
# 2. CZSO: Sector composition data (for treatment intensity)
# ---------------------------------------------------------------
cat("\n=== Fetching sector composition data ===\n")

# Try to find sector-level business counts by region
sector_tables <- czso_tables[grepl("odvětv|CZ-NACE|sector|branch|NACE",
                                    czso_tables$title, ignore.case = TRUE) |
                              grepl("odvětv|NACE",
                                    czso_tables$description, ignore.case = TRUE), ]
cat("Found", nrow(sector_tables), "sector-related tables:\n")
if (nrow(sector_tables) > 0) {
  print(sector_tables[, c("dataset_id", "title")])
}

# ---------------------------------------------------------------
# 3. Eurostat: Sector-level business statistics for Czech Republic
# ---------------------------------------------------------------
cat("\n=== Fetching Eurostat sector-level data ===\n")

# sbs_na_1a_se_r2: Annual enterprise statistics by NACE section
cat("Fetching Eurostat sbs_na_1a_se_r2 (business statistics by NACE)...\n")
tryCatch({
  euro_biz <- eurostat::get_eurostat("sbs_na_1a_se_r2",
                                     filters = list(geo = c("CZ", "SK"),
                                                    nace_r2 = c("I", "G", "H", "M", "A", "C", "F", "J", "K", "L", "N", "S"),
                                                    indic_sb = c("V11110", "V11210", "V16110")),
                                     time_format = "num")
  cat("Eurostat data:", nrow(euro_biz), "rows\n")
  cat("Indicators: V11110=enterprises, V11210=births, V16110=persons employed\n")
  cat("Years:", range(euro_biz$time, na.rm = TRUE), "\n")
  cat("Countries:", unique(euro_biz$geo), "\n")
  cat("Sectors:", paste(unique(euro_biz$nace_r2), collapse = ", "), "\n")
  saveRDS(euro_biz, "../data/eurostat_sector_raw.rds")
  cat("Saved to data/eurostat_sector_raw.rds\n")
}, error = function(e) {
  cat("ERROR fetching Eurostat:", e$message, "\n")
  cat("Trying with fewer filters...\n")
  tryCatch({
    euro_biz <- eurostat::get_eurostat("sbs_na_1a_se_r2",
                                       filters = list(geo = "CZ"),
                                       time_format = "num")
    cat("Eurostat data (broad):", nrow(euro_biz), "rows\n")
    saveRDS(euro_biz, "../data/eurostat_sector_raw.rds")
  }, error = function(e2) {
    cat("Eurostat also failed:", e2$message, "\n")
    # Try the newer dataset ID
    tryCatch({
      euro_biz <- eurostat::get_eurostat("sbs_na_sca_r2",
                                         filters = list(geo = c("CZ", "SK")),
                                         time_format = "num")
      cat("Alternative Eurostat data:", nrow(euro_biz), "rows\n")
      saveRDS(euro_biz, "../data/eurostat_sector_raw.rds")
    }, error = function(e3) {
      cat("All Eurostat attempts failed:", e3$message, "\n")
    })
  })
})

# ---------------------------------------------------------------
# 4. Eurostat: Quarterly GDP/employment for CZ and SK (for parallel trends)
# ---------------------------------------------------------------
cat("\n=== Fetching Eurostat quarterly employment data ===\n")
tryCatch({
  emp_data <- eurostat::get_eurostat("namq_10_a10_e",
                                     filters = list(geo = c("CZ", "SK", "PL", "HU", "AT"),
                                                    nace_r2 = c("TOTAL", "I", "G", "C", "M"),
                                                    unit = "THS_PER",
                                                    s_adj = "SCA"),
                                     time_format = "date")
  cat("Quarterly employment:", nrow(emp_data), "rows\n")
  cat("Years:", range(emp_data$time, na.rm = TRUE), "\n")
  saveRDS(emp_data, "../data/eurostat_employment_raw.rds")
  cat("Saved to data/eurostat_employment_raw.rds\n")
}, error = function(e) {
  cat("Employment data error:", e$message, "\n")
})

# ---------------------------------------------------------------
# 5. Eurostat: Business demography (births/deaths) by country and sector
# ---------------------------------------------------------------
cat("\n=== Fetching Eurostat business demography data ===\n")
tryCatch({
  demo_data <- eurostat::get_eurostat("bd_9ac_l_form_r2",
                                      filters = list(geo = c("CZ", "SK", "PL", "HU", "AT"),
                                                     nace_r2 = c("I", "G", "H", "M", "C", "B-S_X_O"),
                                                     indic_sb = c("V11910", "V11920")),
                                      time_format = "num")
  cat("Business demography:", nrow(demo_data), "rows\n")
  saveRDS(demo_data, "../data/eurostat_demography_raw.rds")
  cat("Saved to data/eurostat_demography_raw.rds\n")
}, error = function(e) {
  cat("Demography data error:", e$message, "\n")
  # Try alternative: bd_9bd_sz_cl_r2 (births and deaths by size class)
  tryCatch({
    demo_data <- eurostat::get_eurostat("bd_9ac_l_form_r2",
                                        filters = list(geo = c("CZ", "SK")),
                                        time_format = "num")
    cat("Business demography (broad):", nrow(demo_data), "rows\n")
    saveRDS(demo_data, "../data/eurostat_demography_raw.rds")
  }, error = function(e2) {
    cat("Also failed:", e2$message, "\n")
  })
})

# ---------------------------------------------------------------
# 6. CZSO: Unemployment by ORP (for mechanism test)
# ---------------------------------------------------------------
cat("\n=== Fetching CZSO unemployment data ===\n")
tryCatch({
  unemp_data <- czso::czso_get_table("250169")
  cat("Unemployment data:", nrow(unemp_data), "rows\n")
  cat("Columns:", paste(names(unemp_data), collapse = ", "), "\n")
  saveRDS(unemp_data, "../data/czso_unemployment_raw.rds")
  cat("Saved to data/czso_unemployment_raw.rds\n")
}, error = function(e) {
  cat("Unemployment data error:", e$message, "\n")
})

cat("\n=== Data fetch complete ===\n")
cat("Files in data/:\n")
list.files("../data/", pattern = "\\.rds$")
