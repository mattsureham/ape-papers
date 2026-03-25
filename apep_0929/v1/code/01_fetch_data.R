# 01_fetch_data.R — Download MIC Furusato Nozei data
# Data already downloaded via curl. This script documents sources and validates.

source("00_packages.R")

data_dir <- "../data"

# --- Validate that all required files exist ---
required_files <- c(
  "municipality_timeseries.xlsx",   # FY2008-FY2024 donation amounts × municipality
  "fy2018_detailed_01.xlsx",        # FY2018 detailed cost breakdown (pre-reform)
  "donation_trends_2022.xlsx"       # FY2024 detailed cost breakdown (post-reform)
)

for (f in required_files) {
  fp <- file.path(data_dir, f)
  if (!file.exists(fp)) stop("MISSING DATA FILE: ", fp)
  cat("OK:", f, "—", file.size(fp), "bytes\n")
}

# --- Source documentation ---
cat("\n=== Data Sources ===\n")
cat("1. municipality_timeseries.xlsx\n")
cat("   Source: MIC (soumu.go.jp), 'Each Municipality Furusato Nozei Donations FY2008-FY2024'\n")
cat("   URL: https://www.soumu.go.jp/main_content/001022819.xlsx\n")
cat("   Contains: Donation amount (千円=thousands yen) and count by municipality × year\n\n")

cat("2. fy2018_detailed_01.xlsx\n")
cat("   Source: MIC, FY2018 Furusato Nozei survey results (published Aug 2019)\n")
cat("   URL: https://www.soumu.go.jp/.../file/results20190802-01.xlsx\n")
cat("   Contains: Donation receipts + cost breakdown (gift procurement, shipping, admin)\n")
cat("   Key variable: Col 19 = gift procurement cost ratio (返礼品の調達に係る費用/受入額)\n\n")

cat("3. donation_trends_2022.xlsx\n")
cat("   Source: MIC, FY2024 Furusato Nozei survey results\n")
cat("   URL: https://www.soumu.go.jp/main_content/001022818.xlsx\n")
cat("   Contains: FY2024 detailed cost breakdown for comparison\n\n")

cat("All data files validated.\n")
