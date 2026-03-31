## 02_clean_data.R — Clean Ofgem FIT Solar PV Data
## apep_1198: UK FIT Solar Bunching (Triple-Threshold Design)

source("code/00_packages.R")

# ============================================================
# LOAD RAW DATA
# ============================================================

dt <- fread("data/ofgem_fit_solar_raw.csv")
cat(sprintf("Loaded %s solar PV installations\n", format(nrow(dt), big.mark = ",")))

# ============================================================
# STANDARDIZE COLUMN NAMES
# ============================================================

setnames(dt, c(
  "extension", "postcode", "technology", "installed_capacity",
  "declared_net_capacity", "application_date", "commissioning_date",
  "mcs_issue_date", "export_status", "tariff_code", "tariff_description",
  "installation_type", "country", "region", "local_authority",
  "constituency", "accreditation_route", "mpan_prefix",
  "community_school", "llsoa", "mlsoa", "fit_id"
))

# ============================================================
# CAPACITY VARIABLE
# ============================================================

# Use "Declared net capacity" (DNC) as the primary capacity measure
dt[, capacity_kw := as.numeric(declared_net_capacity)]
cat(sprintf("Missing capacity: %d (%.2f%%)\n",
            sum(is.na(dt$capacity_kw)),
            100 * mean(is.na(dt$capacity_kw))))

# Drop missing capacity
dt <- dt[!is.na(capacity_kw)]

# ============================================================
# DATE VARIABLES
# ============================================================

# Commissioning date is the key timing variable
dt[, commission_date := as.Date(commissioning_date)]
dt[, commission_year := as.integer(format(commission_date, "%Y"))]
dt[, commission_month := as.integer(format(commission_date, "%m"))]
dt[, commission_ym := as.integer(format(commission_date, "%Y%m"))]

cat(sprintf("Year range: %d to %d\n",
            min(dt$commission_year, na.rm = TRUE),
            max(dt$commission_year, na.rm = TRUE)))

# Drop missing dates
n_before <- nrow(dt)
dt <- dt[!is.na(commission_date)]
cat(sprintf("Dropped %d rows with missing commission date\n", n_before - nrow(dt)))

# ============================================================
# TARIFF BAND EXTRACTION
# ============================================================

# Extract tariff band from tariff code
# PV-R/0-4/ = Retrofit PV, 0-4 kW
# PV-N/0-4/ = New build PV, 0-4 kW
# PV/4-10/ = PV, 4-10 kW
# PV/10-50/ = PV, 10-50 kW
# PV/50-100/ = PV, 50-100 kW
# PV/100-5M/ = PV, 100-5000 kW

dt[, tariff_band := fcase(
  grepl("0-4", tariff_code), "0-4kW",
  grepl("4-10", tariff_code), "4-10kW",
  grepl("10-50", tariff_code), "10-50kW",
  grepl("50-100", tariff_code), "50-100kW",
  grepl("10-100|100-5M|100-150|150-250", tariff_code), "50kW+",
  grepl("EXGEN|SA|ST|R-SA", tariff_code), "other",
  default = "unknown"
)]

cat("\nTariff band distribution:\n")
print(table(dt$tariff_band))

# ============================================================
# POLICY REGIME DEFINITION
# ============================================================

# Key UK FIT reform dates:
# April 1, 2010: FIT scheme launched (Energy Act 2008)
# - Tariff bands: <=4 kW (highest), 4-10 kW, 10-50 kW, 50-100 kW, 100-5MW
# Oct 31, 2011: Feed-in Tariffs Order 2010 amendment (rate cuts announced)
# April 2012: New degression mechanism introduced (quarterly rate reductions)
# Jan 15, 2016: Scheme pause begins; Feb 8, 2016: Revised FIT scheme
# - The <=4 kW and 4-10 kW bands MERGED into 0-10 kW at identical rates
# - This ELIMINATED the 4 kW threshold
# - The 10 kW and 50 kW thresholds REMAIN
# March 31, 2019: FIT scheme closed to new applications

dt[, regime := fcase(
  commission_year < 2010, "pre_FIT",
  commission_year >= 2010 & commission_date < as.Date("2016-02-08"), "FIT_bands",
  commission_date >= as.Date("2016-02-08") & commission_date <= as.Date("2019-03-31"), "post_merger",
  commission_date > as.Date("2019-03-31"), "post_FIT",
  default = "unknown"
)]

cat("\nPolicy regime distribution:\n")
print(table(dt$regime))

# ============================================================
# INTEGER BIN CONSTRUCTION (0.1 kW bins)
# ============================================================

# Critical: use integer bins to avoid floating-point issues (lesson from 0727)
dt[, bin_int := as.integer(floor(capacity_kw * 10))]

# ============================================================
# INSTALLATION TYPE
# ============================================================

dt[, is_domestic := grepl("Domestic", installation_type, ignore.case = TRUE) &
                     !grepl("Non.Domestic", installation_type, ignore.case = TRUE)]

cat("\nInstallation type:\n")
print(table(dt$is_domestic))

# ============================================================
# YEAR-BY-YEAR DISTRIBUTION NEAR 4 kW
# ============================================================

cat("\n=== ANNUAL DISTRIBUTION NEAR 4 kW ===\n")
for (yr in 2010:2019) {
  d <- dt[commission_year == yr & capacity_kw >= 3.5 & capacity_kw <= 5.0]
  n_at_4 <- nrow(d[capacity_kw == 4.0])
  n_above_4 <- nrow(d[capacity_kw > 4.0 & capacity_kw <= 4.1])
  ratio <- ifelse(n_above_4 > 0, n_at_4 / n_above_4, Inf)
  cat(sprintf("  %d: at 4.0 kW = %6d, at 4.0-4.1 = %4d, ratio = %.1f:1, total = %6d\n",
              yr, n_at_4, n_above_4, ratio, nrow(d)))
}

# ============================================================
# YEAR-BY-YEAR DISTRIBUTION NEAR 10 kW
# ============================================================

cat("\n=== ANNUAL DISTRIBUTION NEAR 10 kW ===\n")
for (yr in 2010:2019) {
  d <- dt[commission_year == yr & capacity_kw >= 9.0 & capacity_kw <= 11.0]
  n_at_10 <- nrow(d[capacity_kw == 10.0])
  n_above_10 <- nrow(d[capacity_kw > 10.0 & capacity_kw <= 10.1])
  ratio <- ifelse(n_above_10 > 0, n_at_10 / n_above_10, Inf)
  cat(sprintf("  %d: at 10.0 kW = %5d, at 10.0-10.1 = %3d, ratio = %.1f:1, total = %5d\n",
              yr, n_at_10, n_above_10, ratio, nrow(d)))
}

# ============================================================
# SAVE CLEANED DATA
# ============================================================

fwrite(dt, "data/ofgem_fit_solar_clean.csv")
cat(sprintf("\nSaved: data/ofgem_fit_solar_clean.csv (%s rows)\n",
            format(nrow(dt), big.mark = ",")))

# ============================================================
# WRITE DIAGNOSTICS
# ============================================================

diag <- list(
  n_treated = nrow(dt[regime == "FIT_bands"]),
  n_pre = length(unique(dt[commission_year < 2016]$commission_year)),
  n_obs = nrow(dt),
  n_solar_pv = nrow(dt),
  n_at_4kw = nrow(dt[capacity_kw == 4.0]),
  n_at_10kw = nrow(dt[capacity_kw == 10.0]),
  n_at_50kw = nrow(dt[capacity_kw == 50.0])
)
write(toJSON(diag, auto_unbox = TRUE, pretty = TRUE),
      "data/diagnostics.json")
cat("Saved: data/diagnostics.json\n")

cat("\n02_clean_data.R complete.\n")
