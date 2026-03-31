## 01_fetch_data.R — Load and validate datasets
## apep_1179: Anti-corruption enforcement and fiscal composition in China

source("00_packages.R")

# =============================================================================
# 1. Load Wang (2020) corruption investigations dataset
# =============================================================================
# Source: Harvard Dataverse doi:10.7910/DVN/9QZRAD
# 18,947 investigated officials with prefecture/county identifiers and year

corr_raw <- fread("../data/corruption_investigations.tab",
                   encoding = "UTF-8")

cat("Corruption investigations loaded:", nrow(corr_raw), "records\n")
cat("Columns:", paste(names(corr_raw), collapse = ", "), "\n")
cat("Year range:", range(corr_raw$Year, na.rm = TRUE), "\n")

stopifnot(nrow(corr_raw) > 15000)  # Must have real data
stopifnot("prefectureid" %in% names(corr_raw))
stopifnot("Year" %in% names(corr_raw))

# =============================================================================
# 2. Load China City Statistical Yearbook panel
# =============================================================================
# Source: Harvard Dataverse doi:10.7910/DVN/NUYREO
# 262 cities x 33 years (1990-2022), 190 variables

city_raw <- read_dta("../data/china_city_yearbook.dta")
cat("\nCity yearbook loaded:", nrow(city_raw), "observations,",
    ncol(city_raw), "variables\n")

stopifnot(nrow(city_raw) > 5000)  # Must have real data

# Check key fiscal columns exist
fiscal_vars <- c("地方财政一般预算内支出万元", "教育支出万元",
                 "科学支出万元", "固定资产投资总额万元")
city_names <- names(city_raw)

cat("\nChecking fiscal variables:\n")
for (v in fiscal_vars) {
  found <- v %in% city_names
  cat(sprintf("  %s: %s\n", v, ifelse(found, "FOUND", "MISSING")))
}

# Look for city identifier and year columns
cat("\nFirst 20 column names:\n")
print(city_names[1:min(20, length(city_names))])

# =============================================================================
# 3. Save raw data for downstream scripts
# =============================================================================
saveRDS(corr_raw, "../data/corruption_raw.rds")
saveRDS(city_raw, "../data/city_yearbook_raw.rds")

cat("\nRaw data saved to RDS files.\n")
