## 02_clean_data.R — Construct analysis panel
## apep_0868: Grid Isolation and the Economic Costs of Infrastructure Failure
source("00_packages.R")

cat("=== Loading raw data ===\n")
qcew <- fread("../data/qcew_tx_raw.csv")
grid <- fread("../data/tx_county_grid.csv")

cat(sprintf("QCEW: %d rows, columns: %s\n", nrow(qcew),
    paste(names(qcew), collapse = ", ")))
cat(sprintf("Grid crosswalk: %d counties\n", nrow(grid)))

# Inspect QCEW structure
cat("QCEW column sample:\n")
print(names(qcew))

# The QCEW API returns columns with industry detail. We want total, all industries.
# own_code = 0 (all ownership), industry_code = 10 (Total, all industries)
# The API endpoint we used already filters to industry 10 (total).

# Key variables:
# area_fips: 5-digit county FIPS
# month1_emplvl, month2_emplvl, month3_emplvl: monthly employment
# total_qtrly_wages: total wages
# qtrly_estabs: establishment count
# avg_wkly_wage: average weekly wage

cat("=== Filtering QCEW to total private ownership ===\n")
# own_code: 0=total, 1=federal, 2=state, 3=local, 5=private
# Use own_code=5 (private sector) as primary — avoids government employment
# which is unrelated to the economic shock channel
qcew <- qcew[own_code == 5]
cat(sprintf("After filtering to private sector: %d rows\n", nrow(qcew)))

cat("=== Merging QCEW with grid classification ===\n")

# Standardize FIPS codes
qcew[, fips := sprintf("%05s", as.character(area_fips))]
grid[, fips := sprintf("%05s", as.character(fips))]

# Merge
panel <- merge(qcew, grid[, .(fips, ercot, grid, county_clean)],
               by = "fips", all.x = FALSE)

cat(sprintf("Merged panel: %d rows, %d counties\n",
    nrow(panel), uniqueN(panel$fips)))

# Construct quarterly employment as average of 3 months
emp_cols <- grep("month[123]_emplvl", names(panel), value = TRUE)
if (length(emp_cols) == 3) {
  panel[, emp := rowMeans(.SD, na.rm = TRUE), .SDcols = emp_cols]
} else {
  # Try alternative column names
  emp_cols <- grep("emplvl|employment", names(panel), value = TRUE, ignore.case = TRUE)
  cat(sprintf("Employment columns found: %s\n", paste(emp_cols, collapse = ", ")))
  if (length(emp_cols) >= 1) {
    panel[, emp := get(emp_cols[1])]
  }
}

# Construct key variables
wage_col <- grep("avg_wkly_wage|avg_weekly", names(panel), value = TRUE, ignore.case = TRUE)
if (length(wage_col) > 0) panel[, avg_wage := as.numeric(get(wage_col[1]))]

estab_col <- grep("qtrly_estabs|estabs_count|establishments", names(panel), value = TRUE, ignore.case = TRUE)
if (length(estab_col) > 0) panel[, estabs := as.numeric(get(estab_col[1]))]

wages_col <- grep("total_qtrly_wages|total_wages", names(panel), value = TRUE, ignore.case = TRUE)
if (length(wages_col) > 0) panel[, total_wages := as.numeric(get(wages_col[1]))]

# Create time variables
panel[, yq := year + (quarter - 1) / 4]
panel[, time_id := (year - 2018) * 4 + quarter]  # 1 = 2018Q1
panel[, post := as.integer(yq >= 2021.0)]  # Post = 2021Q1 onwards (Uri was Feb 2021)
panel[, treat := as.integer(ercot == 1)]

# Create event-time variable (relative to 2021Q1)
panel[, event_time := time_id - 13]  # 13 = 2021Q1 (2018Q1=1, so 3*4+1=13)

# Log outcomes (drop zeros)
panel[emp > 0, log_emp := log(emp)]
panel[estabs > 0, log_estabs := log(estabs)]
panel[avg_wage > 0, log_wage := log(avg_wage)]

cat("=== Summary statistics ===\n")
cat("\nERCOT counties:\n")
print(panel[ercot == 1 & year == 2020 & quarter == 4,
      .(N = .N,
        mean_emp = mean(emp, na.rm = TRUE),
        median_emp = median(emp, na.rm = TRUE),
        mean_wage = mean(avg_wage, na.rm = TRUE),
        mean_estabs = mean(estabs, na.rm = TRUE))])

cat("\nNon-ERCOT counties:\n")
print(panel[ercot == 0 & year == 2020 & quarter == 4,
      .(N = .N,
        mean_emp = mean(emp, na.rm = TRUE),
        median_emp = median(emp, na.rm = TRUE),
        mean_wage = mean(avg_wage, na.rm = TRUE),
        mean_estabs = mean(estabs, na.rm = TRUE))])

# Check panel balance
balance <- panel[, .(n_quarters = .N), by = fips]
cat(sprintf("\nPanel balance: %d counties with all %d quarters, %d unbalanced\n",
    sum(balance$n_quarters == max(balance$n_quarters)),
    max(balance$n_quarters),
    sum(balance$n_quarters < max(balance$n_quarters))))

# Keep balanced panel
full_T <- max(balance$n_quarters)
balanced_fips <- balance[n_quarters == full_T, fips]
panel_bal <- panel[fips %in% balanced_fips]
cat(sprintf("Balanced panel: %d counties x %d quarters = %d obs\n",
    uniqueN(panel_bal$fips), full_T, nrow(panel_bal)))

# Save
fwrite(panel, "../data/analysis_panel_full.csv")
fwrite(panel_bal, "../data/analysis_panel_balanced.csv")

cat("\n=== Panel construction complete ===\n")
cat(sprintf("ERCOT counties in balanced panel: %d\n",
    uniqueN(panel_bal[ercot == 1, fips])))
cat(sprintf("Non-ERCOT counties in balanced panel: %d\n",
    uniqueN(panel_bal[ercot == 0, fips])))
