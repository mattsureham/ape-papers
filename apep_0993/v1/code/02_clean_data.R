## 02_clean_data.R — Clean and construct analysis panel
## apep_0993: South Korea 52-Hour Workweek Reform

source("00_packages.R")

cat("=== Cleaning data for apep_0993 ===\n")

# ─────────────────────────────────────────────────────────
# 1. Load Korea industry-level hours
# ─────────────────────────────────────────────────────────

raw_hours <- fread("../data/ilo_hours_by_activity.csv")

# Keep total sex, ISIC4 industry codes, filter to 2010+
korea <- raw_hours[
  SEX == "SEX_T" &
  grepl("^ECO_ISIC4_[A-U]$", ECO) &
  as.integer(TIME_PERIOD) >= 2010 &
  as.integer(TIME_PERIOD) <= 2023,
  .(
    industry = sub("ECO_ISIC4_", "", ECO),
    year = as.integer(TIME_PERIOD),
    hours = as.numeric(OBS_VALUE)
  )
]

# Industry labels
industry_labels <- data.table(
  industry = LETTERS[1:21],
  industry_name = c(
    "Agriculture", "Mining", "Manufacturing", "Electricity/Gas",
    "Water/Waste", "Construction", "Wholesale/Retail", "Transport/Storage",
    "Accommodation/Food", "Information/Comm", "Finance/Insurance",
    "Real Estate", "Professional/Sci", "Admin/Support",
    "Public Admin", "Education", "Health/Social", "Arts/Entertainment",
    "Other Services", "Households", "Extraterritorial"
  )
)

korea <- merge(korea, industry_labels, by = "industry", all.x = TRUE)

cat("Korea panel: ", nrow(korea), " obs, ",
    length(unique(korea$industry)), " industries, ",
    length(unique(korea$year)), " years\n")

# ─────────────────────────────────────────────────────────
# 2. Construct treatment variables
# ─────────────────────────────────────────────────────────

# Pre-reform hours (2017) as baseline
baseline <- korea[year == 2017, .(industry, baseline_hours = hours)]
korea <- merge(korea, baseline, by = "industry", all.x = TRUE)

# Drop industries with no 2017 baseline or extreme outliers
korea <- korea[!is.na(baseline_hours) & baseline_hours > 15]

# Treatment intensity: industries with higher pre-reform hours had more workers
# in the 52-68h range directly affected by the cap. The industry average (including
# part-timers) proxies for the share of workers exposed to the overtime constraint.
median_hours <- median(baseline$baseline_hours)
korea[, overtime_gap := pmax(0, baseline_hours - median_hours)]

# Binary: was the industry "high-hours" (above median in 2017)?
# High-hours industries had more workers near the 52-hour statutory cap.
korea[, binding := as.integer(baseline_hours > median_hours)]

# Dose: continuous treatment intensity (demeaned for interpretation)
korea[, dose := baseline_hours - mean(baseline_hours), by = year]

# Post-reform indicator
korea[, post := as.integer(year >= 2018)]

# Wave indicators (staggered implementation)
korea[, wave1 := as.integer(year >= 2018)]  # 300+ employees (Jul 2018)
korea[, wave2 := as.integer(year >= 2020)]  # 50-299 employees (Jan 2020)
korea[, wave3 := as.integer(year >= 2021)]  # 5-49 employees (Jul 2021)

# Relative time for event study
korea[, rel_time := year - 2018]

cat("Treatment summary (2017 baseline hours):\n")
cat("  Median hours:", round(median_hours, 1), "\n")
cat("  High-hours (above median):", sum(baseline$baseline_hours > median_hours), "industries\n")
cat("  Low-hours (at/below median):", sum(baseline$baseline_hours <= median_hours), "industries\n")
cat("  High-hours industries:", paste(baseline[baseline_hours > median_hours, industry], collapse=", "), "\n")

# ─────────────────────────────────────────────────────────
# 3. Load employment for weighting
# ─────────────────────────────────────────────────────────

raw_emp <- fread("../data/ilo_employment_by_activity.csv")

emp <- raw_emp[
  SEX == "SEX_T" &
  grepl("^ECO_ISIC4_[A-U]$", ECO) &
  as.integer(TIME_PERIOD) >= 2010,
  .(
    industry = sub("ECO_ISIC4_", "", ECO),
    year = as.integer(TIME_PERIOD),
    employment = as.numeric(OBS_VALUE)  # thousands
  )
]

korea <- merge(korea, emp, by = c("industry", "year"), all.x = TRUE)

# Use 2017 employment as weight
emp_2017 <- emp[year == 2017, .(industry, emp_weight = employment)]
korea <- merge(korea, emp_2017, by = "industry", all.x = TRUE)

cat("Employment-weighted panel constructed.\n")

# ─────────────────────────────────────────────────────────
# 4. Load cross-country data
# ─────────────────────────────────────────────────────────

raw_cross <- fread("../data/ilo_hours_cross_country.csv")

cross <- raw_cross[
  SEX == "SEX_T" &
  grepl("^ECO_ISIC4_[A-U]$|ECO_ISIC4_TOTAL|ECO_AGGREGATE_TOTAL", ECO) &
  as.integer(TIME_PERIOD) >= 2010 &
  as.integer(TIME_PERIOD) <= 2023,
  .(
    country = REF_AREA,
    industry = sub("ECO_ISIC4_", "", ECO),
    year = as.integer(TIME_PERIOD),
    hours = as.numeric(OBS_VALUE)
  )
]

cat("Cross-country panel:", nrow(cross), "obs,",
    length(unique(cross$country)), "countries\n")

# ─────────────────────────────────────────────────────────
# 5. Save cleaned data
# ─────────────────────────────────────────────────────────

fwrite(korea, "../data/korea_panel.csv")
fwrite(cross, "../data/cross_country_panel.csv")

cat("\nCleaned data saved.\n")
cat("  Korea panel:", nrow(korea), "rows\n")
cat("  Cross-country:", nrow(cross), "rows\n")

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat("Korea industry hours (2017 pre-reform):\n")
print(korea[year == 2017, .(industry, industry_name, hours = round(hours, 1),
                             binding, overtime_gap = round(overtime_gap, 1))][order(-hours)])
