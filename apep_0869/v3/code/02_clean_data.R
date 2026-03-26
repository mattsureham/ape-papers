# 02_clean_data.R — Clean QCEW data and construct analysis panel
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry
#
# V2 changes from V1:
# 1. Continuous biometric exposure measure (replaces binary exposed/exempt)
# 2. Extended to 2025 for reversal test
# 3. More NAICS sectors for richer exposure variation

source("00_packages.R")

# ============================================================
# Load raw quarterly data
# ============================================================

qcew_quarterly <- fread("../data/qcew_quarterly_raw.csv")
cat(sprintf("Quarterly raw: %d rows\n", nrow(qcew_quarterly)))

# ============================================================
# Clean quarterly data
# ============================================================

cat("Cleaning quarterly data...\n")

# Filter: private sector (own_code = 5), county-level
df_q <- qcew_quarterly[own_code == 5 & agglvl_code %in% c(70, 74)]

# Keep county-level only (5-digit FIPS)
df_q <- df_q[nchar(area_fips) == 5 & !grepl("000$", area_fips) & !grepl("^US", area_fips)]

# State FIPS
df_q[, state_fips := substr(area_fips, 1, 2)]

# Map industry to 2-digit NAICS
# Ensure industry_code is character, then extract first 2 digits
df_q[, industry_code := as.character(industry_code)]
df_q[, naics_2 := substr(industry_code, 1, 2)]

# Sector names for readability
sector_map <- c(
  "10" = "total", "11" = "agriculture", "21" = "mining", "22" = "utilities",
  "23" = "construction", "31" = "manufacturing", "42" = "wholesale",
  "44" = "retail", "48" = "transportation", "51" = "information",
  "52" = "finance", "53" = "real_estate", "54" = "professional",
  "55" = "management", "56" = "admin_services", "61" = "education",
  "62" = "healthcare", "71" = "arts", "72" = "accommodation", "81" = "other_services"
)
df_q[, sector := sector_map[naics_2]]
df_q <- df_q[!is.na(sector)]

# ============================================================
# Merge continuous biometric exposure
# ============================================================

cat("Merging biometric exposure measure...\n")
exposure <- fread("../data/biometric_exposure.csv")
exposure[, naics_2 := as.character(naics_2)]
df_q[, naics_2 := as.character(naics_2)]
df_q <- merge(df_q, exposure[, .(naics_2, bio_exposure_std)],
              by = "naics_2", all.x = TRUE)

# Sectors not in exposure file get exposure = 0 (conservative)
df_q[is.na(bio_exposure_std), bio_exposure_std := 0]

# Also keep binary exposed indicator (for comparison with V1)
df_q[, exposed := fifelse(sector %in% c("information", "professional"), 1L, 0L)]

# Illinois indicator
df_q[, illinois := fifelse(state_fips == "17", 1L, 0L)]

# Post-Rosenbach: ruling Jan 25, 2019 → treatment starts Q1 2019
df_q[, post := fifelse(year > 2019 | (year == 2019 & qtr >= 1), 1L, 0L)]

# Post-2024 BIPA amendments: SB 2979 signed Aug 2, 2024
df_q[, post_amend := fifelse(year > 2024 | (year == 2024 & qtr >= 3), 1L, 0L)]

# Time variables
df_q[, time_q := year + (qtr - 1) / 4]
df_q[, yearqtr := paste0(year, "Q", qtr)]
df_q[, event_q := (year - 2019) * 4 + (qtr - 1)]

# Employment: average of 3 monthly levels
emp_cols <- c("month1_emplvl", "month2_emplvl", "month3_emplvl")
stopifnot(all(emp_cols %in% names(df_q)))
for (col in emp_cols) df_q[[col]] <- as.numeric(df_q[[col]])
df_q[, employment := rowMeans(.SD, na.rm = TRUE), .SDcols = emp_cols]

# Establishments and wages
df_q[, establishments := as.numeric(qtrly_estabs)]
df_q[, avg_weekly_wage := as.numeric(avg_wkly_wage)]

# Log outcomes
df_q[, log_emp := log(employment + 1)]
df_q[, log_estab := log(establishments + 1)]
df_q[, log_wage := fifelse(avg_weekly_wage > 0, log(avg_weekly_wage), NA_real_)]

# Average establishment size
df_q[, avg_estab_size := fifelse(establishments > 0, employment / establishments, NA_real_)]
df_q[, log_avg_size := fifelse(avg_estab_size > 0, log(avg_estab_size), NA_real_)]

# County-sector panel ID
df_q[, county_sector := paste0(area_fips, "_", naics_2)]

# Drop missing/zero employment
df_q <- df_q[!is.na(employment) & employment > 0]

# Drop disclosure-suppressed
if ("disclosure_code" %in% names(df_q)) {
  n_before <- nrow(df_q)
  df_q <- df_q[is.na(disclosure_code) | disclosure_code == "" | disclosure_code == "N"]
  cat(sprintf("Dropped %d disclosure-suppressed rows\n", n_before - nrow(df_q)))
}

# ============================================================
# Border counties (from V1, verified)
# ============================================================

# IL border counties
il_border_fips <- c(
  "17085", "17177", "17201", "17007", "17111", "17097",  # IL-WI
  "17015", "17195", "17161", "17131", "17071", "17067", "17001",  # IL-IA
  "17183", "17023", "17029", "17033", "17101", "17185", "17193",  # IL-IN
  "17149", "17013", "17083", "17119", "17163", "17133", "17157",  # IL-MO
  "17077", "17181", "17003", "17153",
  "17127", "17151", "17069", "17059"  # IL-KY
)

# Neighboring state border counties
in_border_fips <- c("18157", "18165", "18153", "18021", "18033",
                    "18083", "18167", "18129")
wi_border_fips <- c("55043", "55045", "55065", "55101", "55127",
                    "55105", "55063")
ia_border_fips <- c("19031", "19045", "19057", "19097", "19101",
                    "19111", "19163", "19087", "19115")
mo_border_fips <- c("29111", "29137", "29163", "29183", "29189",
                    "29510", "29099", "29157", "29017", "29003",
                    "29133", "29186", "29201")
ky_border_fips <- c("21007", "21039", "21055", "21075", "21139",
                    "21145", "21157")

border_fips <- c(il_border_fips, in_border_fips, wi_border_fips,
                 ia_border_fips, mo_border_fips, ky_border_fips)

df_q[, border := fifelse(area_fips %in% border_fips, 1L, 0L)]

# ============================================================
# Continuous treatment interactions
# ============================================================

# Main continuous triple-diff: Illinois × Post × BiometricExposure
df_q[, triple_cont := illinois * post * bio_exposure_std]
df_q[, il_post := illinois * post]
df_q[, exposure_post := bio_exposure_std * post]
df_q[, il_exposure := illinois * bio_exposure_std]

# Reversal interaction
df_q[, triple_amend := illinois * post_amend * bio_exposure_std]

# Binary triple (for V1 comparison)
df_q[, triple := illinois * post * exposed]

# ============================================================
# Summary
# ============================================================

cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Total observations: %d\n", nrow(df_q)))
cat(sprintf("Counties: %d\n", uniqueN(df_q$area_fips)))
cat(sprintf("NAICS sectors: %d\n", uniqueN(df_q$naics_2)))
cat(sprintf("IL counties: %d (border: %d)\n",
            uniqueN(df_q[illinois == 1]$area_fips),
            uniqueN(df_q[illinois == 1 & border == 1]$area_fips)))
cat(sprintf("Control counties: %d (border: %d)\n",
            uniqueN(df_q[illinois == 0]$area_fips),
            uniqueN(df_q[illinois == 0 & border == 1]$area_fips)))
cat(sprintf("Sectors: %s\n", paste(sort(unique(df_q[sector != "total"]$sector)), collapse = ", ")))
cat(sprintf("Time range: %s to %s\n", min(df_q$yearqtr), max(df_q$yearqtr)))

# Exposure distribution
cat("\nExposure by sector (non-total):\n")
exp_summary <- df_q[sector != "total", .(
  bio_exposure = unique(bio_exposure_std),
  mean_emp = mean(employment, na.rm = TRUE)
), by = sector]
print(exp_summary[order(-bio_exposure)])

# ============================================================
# Save
# ============================================================

keep_cols <- c("area_fips", "state_fips", "county_sector", "sector", "naics_2",
               "year", "qtr", "yearqtr", "time_q", "event_q",
               "illinois", "exposed", "post", "post_amend", "border",
               "bio_exposure_std",
               "employment", "establishments", "avg_weekly_wage",
               "avg_estab_size",
               "log_emp", "log_estab", "log_wage", "log_avg_size",
               "triple_cont", "triple", "il_post", "exposure_post",
               "il_exposure", "triple_amend")

df_panel <- df_q[, ..keep_cols]
fwrite(df_panel, "../data/analysis_panel.csv")
cat(sprintf("\nSaved analysis panel: %d rows\n", nrow(df_panel)))

df_border <- df_panel[border == 1]
fwrite(df_border, "../data/border_panel.csv")
cat(sprintf("Saved border panel: %d rows\n", nrow(df_border)))

cat("\n=== CLEANING COMPLETE ===\n")
