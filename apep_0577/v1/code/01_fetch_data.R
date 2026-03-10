#' 01_fetch_data.R — Fetch Eurostat SBS and Business Demography data
#' REACH 2018 Deadline and Chemical Industry Restructuring
#'
#' Data sources:
#'   1. sbs_na_ind_r2: SBS by NACE, country-level (enterprises, employment, turnover)
#'   2. bd_9ac_l_form_r2: Business demography by NACE (births, deaths)
#'   3. sbs_sc_ind_r2: SBS by size class (for micro-firm share construction)

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. SBS — Structural Business Statistics by NACE sector
# ===========================================================================
cat("Fetching SBS data (sbs_na_ind_r2)...\n")

# Key variables:
#   V11110 = Number of enterprises
#   V16110 = Number of persons employed
#   V12110 = Turnover (million EUR)
# Sectors: C20 (chemicals), C22 (rubber/plastics), C23 (non-metallic minerals),
#           C24 (basic metals), C25 (fabricated metals)

sbs_raw <- tryCatch({
  get_eurostat("sbs_na_ind_r2",
    filters = list(
      nace_r2 = c("C20", "C22", "C23", "C24", "C25"),
      indic_sb = c("V11110", "V16110", "V12110")
    ))
}, error = function(e) {
  stop("Failed to fetch SBS data: ", e$message,
       "\nPivot research question or fix the source.")
})

sbs <- as.data.table(sbs_raw)
sbs[, year := as.integer(format(time, "%Y"))]

# Keep country-level (2-char geo codes = EU member states)
sbs <- sbs[nchar(geo) == 2]

# Filter to EU member states + relevant years
eu_countries <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
                  "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
                  "PL","PT","RO","SK","SI","ES","SE")
sbs <- sbs[geo %in% eu_countries & year >= 2008 & year <= 2021]

# Reshape to wide by indicator
sbs_wide <- dcast(sbs, geo + nace_r2 + year ~ indic_sb, value.var = "values")
setnames(sbs_wide, c("V11110", "V16110", "V12110"),
         c("enterprises", "employment", "turnover"), skip_absent = TRUE)

cat("SBS data:", nrow(sbs_wide), "rows,",
    uniqueN(sbs_wide$geo), "countries,",
    uniqueN(sbs_wide$year), "years\n")

fwrite(sbs_wide, paste0(data_dir, "sbs_data.csv"))

# ===========================================================================
# 2. Business Demography — births, deaths, death rates
# ===========================================================================
cat("\nFetching Business Demography data...\n")

# Try bd_9ac_l_form_r2 — enterprise births and deaths by NACE
bd_raw <- tryCatch({
  get_eurostat("bd_9ac_l_form_r2",
    filters = list(
      nace_r2 = c("C20", "C22", "C23", "C24", "C25"),
      indic_sb = c("V11910", "V11920", "V11960")
      # V11910 = births, V11920 = deaths, V11960 = death rate
    ))
}, error = function(e) {
  message("Primary BD dataset failed, trying alternative: ", e$message)
  # Try alternative dataset
  tryCatch({
    get_eurostat("bd_9bd_sz_cl_r2",
      filters = list(
        nace_r2 = c("C20", "C22", "C23", "C24", "C25")
      ))
  }, error = function(e2) {
    stop("Failed to fetch any Business Demography data: ", e2$message,
         "\nPivot research question or fix the source.")
  })
})

bd <- as.data.table(bd_raw)
bd[, year := as.integer(format(time, "%Y"))]
bd <- bd[nchar(geo) == 2 & geo %in% eu_countries & year >= 2008 & year <= 2021]

cat("Business demography:", nrow(bd), "rows,",
    uniqueN(bd$geo), "countries,",
    uniqueN(bd$year), "years\n")

fwrite(bd, paste0(data_dir, "bd_data.csv"))

# ===========================================================================
# 3. SBS by Size Class — for micro-firm share construction
# ===========================================================================
cat("\nFetching SBS by size class data...\n")

sc_raw <- tryCatch({
  get_eurostat("sbs_sc_ind_r2",
    filters = list(
      nace_r2 = c("C20", "C22", "C23", "C24", "C25"),
      indic_sb = "V11110"
    ))
}, error = function(e) {
  stop("Failed to fetch SBS by size class: ", e$message,
       "\nPivot research question or fix the source.")
})

sc <- as.data.table(sc_raw)
sc[, year := as.integer(format(time, "%Y"))]
sc <- sc[nchar(geo) == 2 & geo %in% eu_countries & year >= 2008 & year <= 2021]

cat("SBS by size class:", nrow(sc), "rows,",
    uniqueN(sc$geo), "countries,",
    uniqueN(sc$year), "years\n")

fwrite(sc, paste0(data_dir, "sbs_size_class.csv"))

# ===========================================================================
# DATA VALIDATION
# ===========================================================================
cat("\n=== DATA VALIDATION ===\n")

stopifnot("SBS: Need at least 15 countries" = uniqueN(sbs_wide$geo) >= 15)
stopifnot("SBS: Need years 2008-2019" = all(2008:2019 %in% sbs_wide$year))
stopifnot("SBS: Need C20 sector" = "C20" %in% sbs_wide$nace_r2)
stopifnot("SBS: Need control sectors" = all(c("C22","C23","C24","C25") %in% sbs_wide$nace_r2))
stopifnot("Size class: Need data" = nrow(sc) > 100)

cat("Data validation passed.\n")
cat("SBS:", nrow(sbs_wide), "rows,", uniqueN(sbs_wide$geo), "countries,",
    uniqueN(sbs_wide$year), "years\n")
cat("Business demography:", nrow(bd), "rows\n")
cat("Size class:", nrow(sc), "rows\n")
