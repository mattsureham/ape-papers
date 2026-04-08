## 02_clean_data.R — Process DVF data into department-month panel
## Paper: apep_1431 — France DMTO Composition Illusion

library(data.table)
library(duckdb)
library(DBI)
library(tidyverse)
library(lubridate)
library(jsonlite)

cat("=== DVF Data Cleaning: apep_1431 ===\n")

# -------------------------------------------------------------------
# 1. Read all DVF files using DuckDB
# -------------------------------------------------------------------
cat("Using DuckDB for out-of-core DVF processing...\n")
con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")

dvf_files <- list.files("data/dvf_raw", pattern = "dvf_.*\\.csv\\.gz$",
                        full.names = TRUE)
cat(sprintf("Found %d DVF files\n", length(dvf_files)))

file_list_sql <- paste0("'", dvf_files, "'", collapse = ", ")

# DVF columns we need (comma-separated CSV):
# id_mutation, date_mutation, nature_mutation, valeur_fonciere,
# code_departement, code_commune, type_local, surface_reelle_bati
query <- sprintf("
  SELECT
    date_mutation,
    TRY_CAST(valeur_fonciere AS DOUBLE) AS valeur_fonciere,
    code_departement,
    code_commune,
    type_local,
    nature_mutation
  FROM read_csv([%s],
    header = true,
    sep = ',',
    ignore_errors = true,
    filename = false
  )
  WHERE
    nature_mutation = 'Vente'
    AND code_departement IS NOT NULL
    AND LENGTH(code_departement) IN (2, 3)
    AND code_departement NOT IN ('971', '972', '973', '974', '976')
    AND TRY_CAST(valeur_fonciere AS DOUBLE) IS NOT NULL
    AND TRY_CAST(valeur_fonciere AS DOUBLE) > 0
", file_list_sql)

cat("Executing DuckDB query...\n")
system.time({
  dvf_raw <- dbGetQuery(con, query)
})
setDT(dvf_raw)
cat(sprintf("Rows read: %s\n", format(nrow(dvf_raw), big.mark=",")))

if (nrow(dvf_raw) == 0) {
  stop("FATAL: No DVF rows returned. Check file paths and column separator.")
}

# Parse dates
dvf_raw[, date_mutation := as.Date(date_mutation)]

# -------------------------------------------------------------------
# 2. Filter to 2021-2025 H1 and residential transactions
# -------------------------------------------------------------------
# Use 2021 as start (avoids mid-2020 partial year issues)
# End at March 2025 for reliable analysis (May-June have data lag)
dvf_raw <- dvf_raw[date_mutation >= as.Date("2021-01-01") &
                   date_mutation <= as.Date("2025-04-30")]

cat(sprintf("After date filter: %s rows\n", format(nrow(dvf_raw), big.mark=",")))

# Residential types subject to DMTO
RESIDENTIAL_TYPES <- c("Maison", "Appartement")
dvf_res  <- dvf_raw[type_local %in% RESIDENTIAL_TYPES]
dvf_other <- dvf_raw[!type_local %in% RESIDENTIAL_TYPES]
cat(sprintf("Residential: %s | Other: %s\n",
            format(nrow(dvf_res), big.mark=","),
            format(nrow(dvf_other), big.mark=",")))

# Remove outliers
dvf_res  <- dvf_res[valeur_fonciere >= 5000 & valeur_fonciere <= 20000000]
dvf_other <- dvf_other[valeur_fonciere >= 1000 & valeur_fonciere <= 50000000]

cat(sprintf("After outlier filter: %s residential\n", format(nrow(dvf_res), big.mark=",")))

# -------------------------------------------------------------------
# 3. Add time variables
# -------------------------------------------------------------------
for (dt in list(dvf_res, dvf_other)) {
  dt[, year  := year(date_mutation)]
  dt[, month := month(date_mutation)]
  dt[, ym    := format(date_mutation, "%Y-%m")]
}
dvf_res[, year  := year(date_mutation)]
dvf_res[, month := month(date_mutation)]
dvf_res[, ym    := format(date_mutation, "%Y-%m")]
dvf_other[, year  := year(date_mutation)]
dvf_other[, month := month(date_mutation)]
dvf_other[, ym    := format(date_mutation, "%Y-%m")]

# -------------------------------------------------------------------
# 4. Aggregate to department-month panel
# -------------------------------------------------------------------
cat("Aggregating to department-month panel...\n")

dept_month <- dvf_res[, .(
  n_transactions    = .N,
  total_value       = sum(valeur_fonciere, na.rm = TRUE),
  mean_value        = mean(valeur_fonciere, na.rm = TRUE),
  median_value      = median(valeur_fonciere, na.rm = TRUE),
  share_maison      = mean(type_local == "Maison"),
  share_above_200k  = mean(valeur_fonciere > 200000),
  share_above_300k  = mean(valeur_fonciere > 300000),
  share_above_500k  = mean(valeur_fonciere > 500000),
  n_below_250k      = sum(valeur_fonciere <= 250000),
  n_above_500k      = sum(valeur_fonciere > 500000)
), by = .(code_departement, year, month, ym)]

dept_month_other <- dvf_other[, .(
  n_other = .N,
  mean_value_other = mean(valeur_fonciere, na.rm = TRUE)
), by = .(code_departement, year, month, ym)]

cat(sprintf("Panel: %d rows, %d departments, %d months\n",
            nrow(dept_month),
            uniqueN(dept_month$code_departement),
            uniqueN(dept_month$ym)))

# -------------------------------------------------------------------
# 5. Define treatment assignment empirically
# -------------------------------------------------------------------
# Since the official adoption list is uncertain, we derive treatment
# from the data using the March/Feb 2025 ratio relative to historical
# March/Feb ratios (2021-2024). Departments with excess ratio > 1.20
# are classified as adopters (their March surge is 20% above historical
# patterns, consistent with buyers rushing before the DMTO increase).
# We use 2021-2024 as the reference (not 2020 which is partial).

hist_mar_feb <- dept_month[year %in% 2021:2024 & month %in% c(2, 3)]
hist_wide <- dcast(hist_mar_feb, code_departement + year ~ month,
                   value.var = "n_transactions")
setnames(hist_wide, c("code_departement", "year", "n_feb", "n_mar"))
hist_wide <- hist_wide[!is.na(n_feb) & !is.na(n_mar) & n_feb > 10]
hist_wide[, ratio := n_mar / n_feb]
hist_avg <- hist_wide[, .(hist_ratio = mean(ratio, na.rm = TRUE)), by = code_departement]

# 2025 March/Feb ratio
mar2025 <- dept_month[year == 2025 & month == 3,
                       .(code_departement, n_mar25 = n_transactions)]
feb2025 <- dept_month[year == 2025 & month == 2,
                       .(code_departement, n_feb25 = n_transactions)]
r2025 <- merge(mar2025, feb2025, by = "code_departement")
r2025[, ratio_2025 := n_mar25 / n_feb25]

dept_treat <- merge(hist_avg, r2025, by = "code_departement")
dept_treat[, excess_ratio := ratio_2025 / hist_ratio]

# Treatment: excess ratio >= 1.15 → adopted DMTO (anomalous March surge)
# Control: excess ratio <= 1.05 (no anomalous surge)
# Ambiguous (1.05-1.15): excluded from main DiD but included in robustness
dept_treat[, treated := fcase(
  excess_ratio >= 1.15, 1L,  # Adopter
  excess_ratio <= 1.05, 0L,  # Non-adopter
  default = NA_integer_       # Ambiguous (excluded from main DiD)
)]

cat(sprintf("\nTreatment assignment (empirical, excess March ratio):\n"))
cat(sprintf("  Treated (excess >= 1.15): %d departments\n",
            sum(dept_treat$treated == 1, na.rm = TRUE)))
cat(sprintf("  Control (excess <= 1.05): %d departments\n",
            sum(dept_treat$treated == 0, na.rm = TRUE)))
cat(sprintf("  Ambiguous (1.05-1.15):    %d departments\n",
            sum(is.na(dept_treat$treated))))
cat(sprintf("  Mean excess ratio treated: %.2f\n",
            mean(dept_treat[treated == 1]$excess_ratio, na.rm = TRUE)))
cat(sprintf("  Mean excess ratio control: %.2f\n",
            mean(dept_treat[treated == 0]$excess_ratio, na.rm = TRUE)))

# Save treatment assignment
fwrite(dept_treat[, .(code_departement, hist_ratio, ratio_2025, excess_ratio, treated)],
       "data/dept_adoption.csv")

# -------------------------------------------------------------------
# 6. Merge treatment into panel
# -------------------------------------------------------------------
dept_month <- merge(dept_month,
                    dept_treat[, .(code_departement, treated, excess_ratio, hist_ratio)],
                    by = "code_departement", all.x = TRUE)
dept_month_other <- merge(dept_month_other,
                           dept_treat[, .(code_departement, treated, excess_ratio)],
                           by = "code_departement", all.x = TRUE)

# -------------------------------------------------------------------
# 7. Add analysis variables
# -------------------------------------------------------------------
dept_month[, post := as.integer(year == 2025 & month >= 4)]
dept_month[, event_time := (year - 2025) * 12 + (month - 3)]  # event_time=0 = March 2025
dept_month[, log_n := log(n_transactions + 1)]
dept_month[, log_mean_value := log(mean_value)]
dept_month[, log_total_value := log(total_value + 1)]
dept_month[, t_numeric := year * 12 + month]

# Period labels
dept_month[, period := fcase(
  year < 2025, paste0("Baseline (", year, ")"),
  year == 2025 & month == 1, "Jan 2025",
  year == 2025 & month == 2, "Feb 2025 (pre)",
  year == 2025 & month == 3, "Mar 2025 (rush)",
  year == 2025 & month == 4, "Apr 2025 (post)"
)]

# -------------------------------------------------------------------
# 8. Save processed data
# -------------------------------------------------------------------
dir.create("data/dept_panel", showWarnings = FALSE, recursive = TRUE)
fwrite(dept_month, "data/dept_panel/dept_month_panel.csv")
fwrite(dept_month_other, "data/dept_panel/dept_month_panel_other.csv")

cat(sprintf("\nFinal panel: %d rows, %d departments\n",
            nrow(dept_month), uniqueN(dept_month$code_departement)))

# -------------------------------------------------------------------
# 9. Summary check
# -------------------------------------------------------------------
cat("\n=== March 2025 surge summary ===\n")
surge_sum <- dept_month[year == 2025 & month %in% c(2, 3) & !is.na(treated),
                         .(n=sum(n_transactions), val=mean(mean_value)/1000),
                         by=.(treated, month)]
setorder(surge_sum, treated, month)
print(surge_sum)

# Write diagnostics
cat("\nWriting diagnostics.json...\n")
diag <- list(
  n_treated = sum(dept_treat$treated == 1, na.rm = TRUE),
  n_control = sum(dept_treat$treated == 0, na.rm = TRUE),
  n_obs = nrow(dept_month[!is.na(treated)]),
  n_pre = length(unique(dept_month[year < 2025]$ym)),
  n_transactions_total = sum(dept_month$n_transactions),
  date_range_start = as.character(min(dvf_res$date_mutation)),
  date_range_end = as.character(max(dvf_res$date_mutation))
)
write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")

dbDisconnect(con)
cat("\n=== Clean complete ===\n")
