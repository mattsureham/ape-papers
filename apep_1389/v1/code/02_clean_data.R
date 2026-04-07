## 02_clean_data.R — Build analysis panel from ITA 300A data
source("00_packages.R")

data_dir <- "../data"

# ── Load Appendix B NAICS codes ──
appendix_b <- as.integer(readLines(file.path(data_dir, "appendix_b_naics.txt")))
message("Appendix B: ", length(appendix_b), " NAICS codes")

# ── Read and stack all years ──
csv_files <- sort(list.files(data_dir, pattern = "^ita_20.*\\.csv$", full.names = TRUE))
message("Reading ", length(csv_files), " files...")

panels <- lapply(csv_files, function(f) {
  yr <- as.integer(str_extract(basename(f), "\\d{4}"))
  dt <- fread(f, select = c("annual_average_employees", "naics_code",
                              "total_hours_worked", "total_deaths",
                              "total_dafw_cases", "total_djtr_cases",
                              "total_other_cases", "total_injuries",
                              "total_skin_disorders", "total_respiratory_conditions",
                              "total_poisonings", "total_hearing_loss",
                              "total_other_illnesses",
                              "total_dafw_days", "total_djtr_days",
                              "no_injuries_illnesses",
                              "establishment_type", "size", "state",
                              "year_filing_for"),
              na.strings = c("", "NA", "NULL"))

  # Use year_filing_for if available, otherwise extract from filename
  if ("year_filing_for" %in% names(dt) && !all(is.na(dt$year_filing_for))) {
    dt[, year := as.integer(year_filing_for)]
    dt[is.na(year), year := yr]
  } else {
    dt[, year := yr]
  }
  dt[, year_filing_for := NULL]
  dt
})

df <- rbindlist(panels, fill = TRUE)
message("Raw records: ", format(nrow(df), big.mark = ","))

# ── Clean variables ──
# Employee count
df[, emp := as.numeric(annual_average_employees)]
df <- df[!is.na(emp) & emp > 0]

# NAICS: extract 4-digit
df[, naics4 := as.integer(substr(as.character(naics_code), 1, 4))]
df <- df[!is.na(naics4)]

# Appendix B indicator
df[, appendix_b := as.integer(naics4 %in% appendix_b)]

# Hours worked
df[, hours := as.numeric(total_hours_worked)]
df[is.na(hours) | hours <= 0, hours := NA_real_]

# Injury variables
injury_vars <- c("total_deaths", "total_dafw_cases", "total_djtr_cases",
                 "total_other_cases", "total_injuries", "total_skin_disorders",
                 "total_respiratory_conditions", "total_poisonings",
                 "total_hearing_loss", "total_other_illnesses",
                 "total_dafw_days", "total_djtr_days")
for (v in injury_vars) {
  if (v %in% names(df)) df[, (v) := as.numeric(get(v))]
}

# Total case count (OSHA Total Recordable Cases = DAFW + DJTR + Other)
df[, total_cases := fifelse(is.na(total_dafw_cases), 0L, as.integer(total_dafw_cases)) +
                    fifelse(is.na(total_djtr_cases), 0L, as.integer(total_djtr_cases)) +
                    fifelse(is.na(total_other_cases), 0L, as.integer(total_other_cases))]

# DART cases (Days Away, Restricted, Transferred)
df[, dart_cases := fifelse(is.na(total_dafw_cases), 0L, as.integer(total_dafw_cases)) +
                   fifelse(is.na(total_djtr_cases), 0L, as.integer(total_djtr_cases))]

# Injury rates per 100 FTE (200,000 hours)
df[, tcr := fifelse(!is.na(hours) & hours > 0, total_cases / hours * 200000, NA_real_)]
df[, dart_rate := fifelse(!is.na(hours) & hours > 0, dart_cases / hours * 200000, NA_real_)]

# ── Treatment indicator ──
# Treatment = Appendix B AND >= 100 employees AND year >= 2024
df[, above100 := as.integer(emp >= 100)]
df[, post := as.integer(year >= 2024)]
df[, treated := above100 * appendix_b * post]

# Running variable centered at 100
df[, emp_centered := emp - 100]

# ── Bandwidth restriction for RDD ──
# Main bandwidth: 50-200 employees (wide); robustness uses 80-120
df[, in_bandwidth_wide := emp >= 50 & emp <= 200]
df[, in_bandwidth_narrow := emp >= 80 & emp <= 120]

# ── 2-digit NAICS sector ──
df[, naics2 := as.integer(substr(as.character(naics4), 1, 2))]

# ── State code ──
df[, state_code := as.character(state)]

# ── Summary stats ──
message("\n=== Panel Summary ===")
message("Years: ", paste(sort(unique(df$year)), collapse = ", "))
message("Total records: ", format(nrow(df), big.mark = ","))
message("Appendix B: ", format(sum(df$appendix_b), big.mark = ","),
        " (", round(100*mean(df$appendix_b), 1), "%)")
message("In narrow bandwidth (80-120): ", format(sum(df$in_bandwidth_narrow), big.mark = ","))
message("In wide bandwidth (50-200): ", format(sum(df$in_bandwidth_wide), big.mark = ","))
message("Post-2024: ", format(sum(df$post), big.mark = ","))
message("Mean TCR: ", round(mean(df$tcr, na.rm = TRUE), 2))
message("Mean DART: ", round(mean(df$dart_rate, na.rm = TRUE), 2))

# Save
fwrite(df, file.path(data_dir, "panel_clean.csv"))
message("\nSaved panel_clean.csv: ", format(nrow(df), big.mark = ","), " rows")
