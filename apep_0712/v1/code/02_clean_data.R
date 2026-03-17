# 02_clean_data.R — Clean and construct analysis variables
# apep_0712: UK Ground Rent Abolition

source("00_packages.R")

data_dir <- "../data"
ppd <- readRDS(file.path(data_dir, "ppd_2020_2024.rds"))

# --- Key dates ---
cutoff_date <- as.Date("2022-06-30")
royal_assent <- as.Date("2022-02-08")
retirement_cutoff <- as.Date("2023-04-01")

# --- Filter to standard transactions (A category, not deletions) ---
ppd <- ppd[ppd_category == "A" & record_status == "A"]
cat(sprintf("After filtering to standard transactions: %s\n",
            format(nrow(ppd), big.mark = ",")))

# --- Construct key variables ---
ppd[, `:=`(
  # Running variable: days from cutoff
  days_from_cutoff = as.numeric(date_transfer - cutoff_date),

  # Treatment: transaction on or after July 1, 2022
  post = as.integer(date_transfer > cutoff_date),

  # Property categories
  is_flat = as.integer(property_type == "F"),
  is_new_build = as.integer(new_build == "Y"),
  is_leasehold = as.integer(duration == "L"),

  # Log price
  log_price = log(price),

  # Year-month for aggregation
  ym = format(date_transfer, "%Y-%m"),
  year = year(date_transfer),
  month = month(date_transfer),
  quarter = quarter(date_transfer),

  # Region from district (first part of postcode gives area)
  postcode_area = sub("^([A-Z]{1,2}).*", "\\1", postcode)
)]

# --- Create analysis groups ---
# Group 1: New-build leasehold flats (TREATED — affected by the Act)
# Group 2: New-build freehold houses (CONTROL — unaffected)
# Group 3: Existing leasehold flats (CONTROL — retain original ground rent)
ppd[, group := case_when(
  is_new_build == 1 & is_leasehold == 1 & is_flat == 1 ~ "new_leasehold_flat",
  is_new_build == 1 & is_leasehold == 0 ~ "new_freehold",
  is_new_build == 0 & is_leasehold == 1 & is_flat == 1 ~ "existing_leasehold_flat",
  is_new_build == 0 & is_leasehold == 0 ~ "existing_freehold",
  TRUE ~ "other"
)]

cat("\nGroup counts:\n")
print(table(ppd$group))

# --- Filter analysis window: 2021-2024 for main analysis ---
ppd_analysis <- ppd[year >= 2021 & year <= 2024]
cat(sprintf("\nAnalysis window (2021-2024): %s observations\n",
            format(nrow(ppd_analysis), big.mark = ",")))

# --- RDD sample: new-build leasehold flats ---
rdd_sample <- ppd_analysis[group == "new_leasehold_flat"]
cat(sprintf("RDD sample (new-build leasehold flats): %s\n",
            format(nrow(rdd_sample), big.mark = ",")))

# --- DiD sample: new-build leasehold flats + new-build freehold ---
did_sample <- ppd_analysis[group %in% c("new_leasehold_flat", "new_freehold")]
did_sample[, treated := as.integer(group == "new_leasehold_flat")]
cat(sprintf("DiD sample: %s\n", format(nrow(did_sample), big.mark = ",")))

# --- Triple-diff sample: add existing leasehold flats ---
triplediff_sample <- ppd_analysis[group %in% c("new_leasehold_flat", "new_freehold",
                                                 "existing_leasehold_flat")]
triplediff_sample[, `:=`(
  treated_lease = as.integer(is_leasehold == 1),
  treated_new = as.integer(is_new_build == 1)
)]
cat(sprintf("Triple-diff sample: %s\n", format(nrow(triplediff_sample), big.mark = ",")))

# --- Monthly aggregation for plotting ---
monthly_counts <- ppd_analysis[, .(
  n = .N,
  mean_price = mean(price, na.rm = TRUE),
  median_price = median(price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE)
), by = .(ym, group)]

# --- Summary statistics ---
cat("\n=== Summary Statistics: New-build Leasehold Flats ===\n")
cat(sprintf("N = %s\n", format(nrow(rdd_sample), big.mark = ",")))
cat(sprintf("Mean price: £%s\n", format(round(mean(rdd_sample$price)), big.mark = ",")))
cat(sprintf("Median price: £%s\n", format(round(median(rdd_sample$price)), big.mark = ",")))
cat(sprintf("SD price: £%s\n", format(round(sd(rdd_sample$price)), big.mark = ",")))
cat(sprintf("SD log price: %0.3f\n", sd(rdd_sample$log_price)))
cat(sprintf("Pre-reform (≤2022-06-30): %s\n",
            format(sum(rdd_sample$post == 0), big.mark = ",")))
cat(sprintf("Post-reform (>2022-06-30): %s\n",
            format(sum(rdd_sample$post == 1), big.mark = ",")))

# --- Save analysis datasets ---
saveRDS(ppd_analysis, file.path(data_dir, "ppd_analysis.rds"))
saveRDS(rdd_sample, file.path(data_dir, "rdd_sample.rds"))
saveRDS(did_sample, file.path(data_dir, "did_sample.rds"))
saveRDS(triplediff_sample, file.path(data_dir, "triplediff_sample.rds"))
saveRDS(monthly_counts, file.path(data_dir, "monthly_counts.rds"))

cat("\nAll analysis datasets saved.\n")
