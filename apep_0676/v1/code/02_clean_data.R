## 02_clean_data.R — Clean and prepare charity data for bunching analysis
## apep_0676: UK Charity Bunching at Audit Thresholds

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Load raw data
## ============================================================

cat("Loading annual return history...\n")
arr <- fread(file.path(data_dir, "publicextract.charity_annual_return_history.txt"),
             sep = "\t", header = TRUE, encoding = "UTF-8")
cat("  Raw rows:", format(nrow(arr), big.mark = ","), "\n")

cat("Loading charity register...\n")
charity <- fread(file.path(data_dir, "publicextract.charity.txt"),
                 sep = "\t", header = TRUE, encoding = "UTF-8", quote = "")

cat("Loading classifications...\n")
classif <- fread(file.path(data_dir, "publicextract.charity_classification.txt"),
                 sep = "\t", header = TRUE, encoding = "UTF-8")

## ============================================================
## 2. Clean annual return data
## ============================================================

# Extract fiscal year from period end date (already POSIXct)
arr[, fiscal_year := year(fin_period_end_date)]

# Income is already integer
arr[, income := as.numeric(total_gross_income)]
arr[, expenditure := as.numeric(total_gross_expenditure)]

# Remove suppressed records (suppression_ind is logical TRUE/FALSE)
arr <- arr[suppression_ind == FALSE | is.na(suppression_ind)]

# Remove missing/negative income
cat("Before removing NA income:", format(nrow(arr), big.mark = ","), "\n")
arr <- arr[!is.na(income) & income >= 0]
cat("After removing NA income:", format(nrow(arr), big.mark = ","), "\n")

cat("\nIncome summary:\n")
print(summary(arr$income))
cat("\nFiscal year range:", min(arr$fiscal_year, na.rm = TRUE),
    "to", max(arr$fiscal_year, na.rm = TRUE), "\n")

yr_tab <- arr[, .N, by = fiscal_year][order(fiscal_year)]
cat("Returns per year:\n")
print(yr_tab)

## ============================================================
## 3. Merge charity info
## ============================================================

charity_info <- charity[, .(
  organisation_number,
  charity_name,
  charity_type,
  charity_registration_status
)]

arr <- merge(arr, charity_info,
             by = "organisation_number",
             all.x = TRUE)

cat("\nRegistration status breakdown:\n")
print(table(arr$charity_registration_status, useNA = "ifany"))

## ============================================================
## 4. Merge classifications
## ============================================================

cat("\nClassification types available:\n")
print(unique(classif$classification_type))

# Get the "What" classification (purpose)
what_classif <- classif[classification_type == "What"]
cat("What classifications:", format(nrow(what_classif), big.mark = ","), "\n")

# Take first classification per charity
what_first <- what_classif[, .SD[1], by = organisation_number]
arr <- merge(arr, what_first[, .(organisation_number, classification_description)],
             by = "organisation_number", all.x = TRUE)

cat("\nTop charity purposes:\n")
print(head(sort(table(arr$classification_description), decreasing = TRUE), 15))

## ============================================================
## 5. Create analysis variables
## ============================================================

# Distance from thresholds (in £)
arr[, dist_25k := income - 25000]
arr[, dist_1m := income - 1000000]
arr[, dist_40k := income - 40000]

# Pre/post reform indicator
# Charities Act 2022 raised examination threshold from £25K to £40K
# Royal Assent: 24 Feb 2022; commencement of s.130 threshold: 31 Mar 2023
# Financial years ending 2023+ are post-reform
arr[, post_reform := fiscal_year >= 2023]

cat("\nPre/post reform split:\n")
print(table(arr$post_reform))

## ============================================================
## 6. Create binned income distributions
## ============================================================

create_bins <- function(dt, threshold, bw, window) {
  subset <- dt[income >= (threshold - window) & income <= (threshold + window)]
  subset[, bin := floor(income / bw) * bw + bw/2]
  counts <- subset[, .N, by = bin]
  setnames(counts, "N", "count")
  setorder(counts, bin)
  return(counts)
}

# Pre-reform period: 2015-2022
pre <- arr[fiscal_year >= 2015 & fiscal_year <= 2022]
post <- arr[fiscal_year >= 2023]

# £25K threshold: £500 bins, ±£15K window
bins_25k_pre <- create_bins(pre, 25000, 500, 15000)
bins_25k_post <- create_bins(post, 25000, 500, 15000)
cat("\n£25K pre-reform bins (sample):\n")
print(bins_25k_pre[bin >= 22000 & bin <= 28000])

# £40K threshold: £500 bins, ±£15K window (post-reform)
bins_40k_post <- create_bins(post, 40000, 500, 15000)

# £1M threshold: £10K bins, ±£300K window (all years 2015+)
all_recent <- arr[fiscal_year >= 2015]
bins_1m <- create_bins(all_recent, 1000000, 10000, 300000)
cat("\n£1M threshold bins (sample around threshold):\n")
print(bins_1m[bin >= 950000 & bin <= 1050000])

# Year-by-year bins at £25K for event study
yearly_bins_25k <- list()
for (y in 2015:max(arr$fiscal_year, na.rm = TRUE)) {
  ydata <- arr[fiscal_year == y]
  if (nrow(ydata) > 100) {
    b <- create_bins(ydata, 25000, 500, 15000)
    b[, year := y]
    yearly_bins_25k[[as.character(y)]] <- b
  }
}
yearly_bins_25k <- rbindlist(yearly_bins_25k)

## ============================================================
## 7. Save cleaned data
## ============================================================

save(arr, bins_25k_pre, bins_25k_post, bins_40k_post, bins_1m,
     yearly_bins_25k,
     file = file.path(data_dir, "cleaned_data.RData"))

cat("\n=== Cleaning complete ===\n")
cat("Total observations:", format(nrow(arr), big.mark = ","), "\n")
cat("Unique charities:", format(uniqueN(arr$organisation_number), big.mark = ","), "\n")
cat("Fiscal years:", min(arr$fiscal_year, na.rm = TRUE), "-",
    max(arr$fiscal_year, na.rm = TRUE), "\n")
cat("Post-reform obs:", format(sum(arr$post_reform), big.mark = ","), "\n")
