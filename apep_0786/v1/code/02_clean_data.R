## 02_clean_data.R — Construct analysis panel from aggregated HMDA data
## APEP paper apep_0786: HMDA Reporting Exemption and Minority Lending

source("00_packages.R")

data_dir <- "../data"

# ---------------------------------------------------------------
# Load and combine all years
# ---------------------------------------------------------------
cat("Loading aggregated HMDA data...\n")
years <- 2018:2022
dfs <- lapply(years, function(yr) {
  f <- file.path(data_dir, paste0("hmda_agg_", yr, ".parquet"))
  if (!file.exists(f)) stop("Missing: ", f)
  as.data.table(arrow::read_parquet(f))
})
dt <- rbindlist(dfs, fill = TRUE)
cat(sprintf("Combined: %s rows, years %d-%d\n",
            format(nrow(dt), big.mark = ","), min(dt$year), max(dt$year)))

# ---------------------------------------------------------------
# Clean and validate
# ---------------------------------------------------------------
# Drop missing LEI or county
dt <- dt[!is.na(lei) & lei != "" & !is.na(county_code) & county_code != ""]

# Standardize exempt flag: 1 = exempt, 0 = non-exempt
# Some lenders may have NA if the exempt field wasn't detected
dt[is.na(exempt), exempt := 0L]

# Focus on White and Black for the main racial gap analysis
dt_racial <- dt[race %in% c("White", "Black")]

# ---------------------------------------------------------------
# Construct lender-county-year panel
# ---------------------------------------------------------------
# Pivot: for each lender-county-year, compute denial rates by race
panel <- dt_racial[, .(
  originated = sum(n[action == 1]),
  denied = sum(n[action == 3]),
  total_apps = sum(n),
  mean_loan_amt = weighted.mean(mean_loan_amt, n, na.rm = TRUE),
  mean_income = weighted.mean(mean_income, n, na.rm = TRUE)
), by = .(year, lei, state_code, county_code, race, exempt)]

# Compute denial rate
panel[, denial_rate := denied / total_apps]

# ---------------------------------------------------------------
# Create Black-White denial gap at lender-county-year level
# ---------------------------------------------------------------
# Pivot wider: one row per lender-county-year with Black and White denial rates
bw <- dcast(panel, year + lei + state_code + county_code + exempt ~
              race, value.var = c("denial_rate", "total_apps", "mean_income"),
            fun.aggregate = mean)

# Rename columns
setnames(bw, c("denial_rate_Black", "denial_rate_White",
               "total_apps_Black", "total_apps_White",
               "mean_income_Black", "mean_income_White"),
         c("deny_black", "deny_white",
           "apps_black", "apps_white",
           "income_black", "income_white"))

# Compute Black-White denial gap
bw[, deny_gap := deny_black - deny_white]

# Income ratio (controls for applicant quality differences)
bw[, income_ratio := income_black / income_white]

# Total volume for lender-county-year
bw[, total_volume := apps_black + apps_white]

# ---------------------------------------------------------------
# Sample restrictions
# ---------------------------------------------------------------
# Require at least 5 Black AND 5 White applications per lender-county-year
# (avoids extreme small-sample denial rates)
bw_clean <- bw[apps_black >= 5 & apps_white >= 5]
cat(sprintf("Panel after min-apps filter: %s obs (%s dropped)\n",
            format(nrow(bw_clean), big.mark = ","),
            format(nrow(bw) - nrow(bw_clean), big.mark = ",")))

# Require county to have at least 1 exempt and 1 non-exempt lender
# (needed for within-county comparison)
counties_both <- bw_clean[, .(
  has_exempt = any(exempt == 1),
  has_nonexempt = any(exempt == 0)
), by = .(county_code, year)]
counties_both <- counties_both[has_exempt & has_nonexempt]

bw_final <- bw_clean[counties_both, on = .(county_code, year), nomatch = NULL]
cat(sprintf("Panel after county filter: %s obs in %d county-years\n",
            format(nrow(bw_final), big.mark = ","),
            nrow(counties_both)))

# ---------------------------------------------------------------
# Also construct full-race panel for Asian and Hispanic comparisons
# ---------------------------------------------------------------
panel_all <- dt[race %in% c("White", "Black", "Asian"), .(
  originated = sum(n[action == 1]),
  denied = sum(n[action == 3]),
  total_apps = sum(n),
  mean_income = weighted.mean(mean_income, n, na.rm = TRUE)
), by = .(year, lei, state_code, county_code, race, exempt)]
panel_all[, denial_rate := denied / total_apps]

# ---------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")
cat(sprintf("  Years: %d-%d\n", min(bw_final$year), max(bw_final$year)))
cat(sprintf("  Observations: %s lender-county-years\n",
            format(nrow(bw_final), big.mark = ",")))
cat(sprintf("  Unique lenders: %d (%d exempt, %d non-exempt)\n",
            uniqueN(bw_final$lei),
            uniqueN(bw_final[exempt == 1]$lei),
            uniqueN(bw_final[exempt == 0]$lei)))
cat(sprintf("  Unique counties: %d\n", uniqueN(bw_final$county_code)))
cat(sprintf("  Mean denial gap (Black-White): %.3f\n", mean(bw_final$deny_gap, na.rm = TRUE)))
cat(sprintf("  Mean denial gap — exempt: %.3f | non-exempt: %.3f\n",
            mean(bw_final[exempt == 1]$deny_gap, na.rm = TRUE),
            mean(bw_final[exempt == 0]$deny_gap, na.rm = TRUE)))

# ---------------------------------------------------------------
# Save analysis datasets
# ---------------------------------------------------------------
arrow::write_parquet(bw_final, file.path(data_dir, "panel_bw.parquet"))
arrow::write_parquet(panel_all, file.path(data_dir, "panel_all_races.parquet"))

# Also save summary stats for the paper
sumstats <- bw_final[, .(
  N = .N,
  mean_deny_gap = mean(deny_gap, na.rm = TRUE),
  sd_deny_gap = sd(deny_gap, na.rm = TRUE),
  mean_deny_black = mean(deny_black, na.rm = TRUE),
  sd_deny_black = sd(deny_black, na.rm = TRUE),
  mean_deny_white = mean(deny_white, na.rm = TRUE),
  sd_deny_white = sd(deny_white, na.rm = TRUE),
  mean_apps_black = mean(apps_black, na.rm = TRUE),
  mean_apps_white = mean(apps_white, na.rm = TRUE),
  mean_volume = mean(total_volume, na.rm = TRUE),
  mean_income_black = mean(income_black, na.rm = TRUE),
  mean_income_white = mean(income_white, na.rm = TRUE),
  share_exempt = mean(exempt, na.rm = TRUE)
), by = exempt]

print(sumstats)

arrow::write_parquet(sumstats, file.path(data_dir, "summary_stats.parquet"))

cat("\nAnalysis datasets saved.\n")
