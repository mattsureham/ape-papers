# 02_clean_data.R — Clean QCEW data and construct analysis panel
# APEP-0869: The Litigation Tax on Biometrics

source("00_packages.R")

# ============================================================
# Load raw quarterly data (main analysis uses quarterly)
# ============================================================

qcew_quarterly <- fread("../data/qcew_quarterly_raw.csv")
cat(sprintf("Quarterly raw: %d rows\n", nrow(qcew_quarterly)))

# ============================================================
# Clean quarterly data for main analysis
# ============================================================

cat("Cleaning quarterly data...\n")

# Filter: private sector (own_code = 5), county-level
# agglvl_code 74 = County, NAICS Sector (for 2-digit codes)
# agglvl_code 70 = County, Total All Industries (for code 10)
df_q <- qcew_quarterly[own_code == 5 & agglvl_code %in% c(70, 74)]

# Keep only county-level: 5-digit FIPS, not state-level (ending in 000), not US
df_q <- df_q[nchar(area_fips) == 5 & !grepl("000$", area_fips) & !grepl("^US", area_fips)]

# State FIPS
df_q[, state_fips := substr(area_fips, 1, 2)]

# Map industry to sector names
df_q[, sector := fcase(
  industry_code == "10",    "total",
  industry_code == "51",    "information",
  industry_code == "52",    "finance",
  industry_code == "54",    "professional",
  industry_code == "62",    "healthcare",
  default = "other"
)]
df_q <- df_q[sector != "other"]

# Biometric exposure: Info (51) + Professional (54) are exposed
# Finance (52, GLBA exempt) + Healthcare (62, HIPAA exempt) are controls
df_q[, exposed := fifelse(sector %in% c("information", "professional"), 1L, 0L)]

# Illinois indicator
df_q[, illinois := fifelse(state_fips == "17", 1L, 0L)]

# Post-Rosenbach: ruling Jan 25, 2019 → treatment starts Q1 2019
df_q[, post := fifelse(year > 2019 | (year == 2019 & qtr >= 1), 1L, 0L)]

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

# County-sector panel ID
df_q[, county_sector := paste0(area_fips, "_", sector)]

# Drop missing/zero employment
df_q <- df_q[!is.na(employment) & employment > 0]

# Drop disclosure-suppressed
if ("disclosure_code" %in% names(df_q)) {
  n_before <- nrow(df_q)
  df_q <- df_q[is.na(disclosure_code) | disclosure_code == "" | disclosure_code == "N"]
  cat(sprintf("Dropped %d disclosure-suppressed rows\n", n_before - nrow(df_q)))
}

# ============================================================
# Border counties (hardcoded from Census county adjacency)
# IL counties that share a border with IN, WI, IA, MO, KY
# ============================================================

# IL border counties
il_border_fips <- c(
  # IL-WI border
  "17085", "17177", "17201", "17007", "17111", "17097",
  # IL-IA border
  "17015", "17195", "17161", "17131", "17071", "17067", "17001",
  # IL-IN border
  "17183", "17023", "17029", "17033", "17101", "17185", "17193",
  # IL-MO border
  "17149", "17013", "17083", "17119", "17163", "17133", "17157",
  "17077", "17181", "17003", "17153",
  # IL-KY border
  "17127", "17151", "17069", "17059"
)

# Neighboring state border counties (those adjacent to IL)
# IN counties bordering IL
in_border_fips <- c("18157", "18165", "18153", "18021", "18033",
                    "18083", "18167", "18129")
# WI counties bordering IL
wi_border_fips <- c("55043", "55045", "55065", "55101", "55127",
                    "55105", "55063")
# IA counties bordering IL
ia_border_fips <- c("19031", "19045", "19057", "19097", "19101",
                    "19111", "19163", "19087", "19115")
# MO counties bordering IL
mo_border_fips <- c("29111", "29137", "29163", "29183", "29189",
                    "29510", "29099", "29157", "29017", "29003",
                    "29133", "29186", "29201")
# KY counties bordering IL
ky_border_fips <- c("21007", "21039", "21055", "21075", "21139",
                    "21145", "21157")

border_fips <- c(il_border_fips, in_border_fips, wi_border_fips,
                 ia_border_fips, mo_border_fips, ky_border_fips)

df_q[, border := fifelse(area_fips %in% border_fips, 1L, 0L)]

# ============================================================
# Summary
# ============================================================

cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Total observations: %d\n", nrow(df_q)))
cat(sprintf("Counties: %d\n", uniqueN(df_q$area_fips)))
cat(sprintf("IL counties: %d (border: %d)\n",
            uniqueN(df_q[illinois == 1]$area_fips),
            uniqueN(df_q[illinois == 1 & border == 1]$area_fips)))
cat(sprintf("Control counties: %d (border: %d)\n",
            uniqueN(df_q[illinois == 0]$area_fips),
            uniqueN(df_q[illinois == 0 & border == 1]$area_fips)))
cat(sprintf("Sectors: %s\n", paste(sort(unique(df_q$sector)), collapse = ", ")))
cat(sprintf("Time range: %s to %s\n", min(df_q$yearqtr), max(df_q$yearqtr)))

# Summary table
summary_tab <- df_q[sector != "total", .(
  mean_emp = mean(employment, na.rm = TRUE),
  mean_estab = mean(establishments, na.rm = TRUE),
  mean_wage = mean(avg_weekly_wage, na.rm = TRUE),
  n_counties = uniqueN(area_fips),
  n_obs = .N
), by = .(illinois, exposed)]
print(summary_tab)

# ============================================================
# Save
# ============================================================

keep_cols <- c("area_fips", "state_fips", "county_sector", "sector",
               "industry_code", "year", "qtr", "yearqtr", "time_q", "event_q",
               "illinois", "exposed", "post", "border",
               "employment", "establishments", "avg_weekly_wage",
               "log_emp", "log_estab", "log_wage")

df_panel <- df_q[, ..keep_cols]
fwrite(df_panel, "../data/analysis_panel.csv")
cat(sprintf("\nSaved analysis panel: %d rows\n", nrow(df_panel)))

df_border <- df_panel[border == 1]
fwrite(df_border, "../data/border_panel.csv")
cat(sprintf("Saved border panel: %d rows\n", nrow(df_border)))

cat("\n=== CLEANING COMPLETE ===\n")
