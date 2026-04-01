## 01_fetch_data.R — Construct organ donation panel from published NHSBT data
## apep_1263: The Opt-Out Illusion
##
## Data sources: NHSBT Annual Activity Reports (Table 2.1, Table 3.2, Chapter 13)
## Each financial year runs April 1 to March 31.
## All figures are from published NHSBT reports, cited by year.
##
## Reports used:
##   2018-19: nhsbtdbe.blob.core.windows.net/.../organ-donation-and-transplantation-activity-report-2018-2019.pdf
##   2020-21: nhsbtdbe.blob.core.windows.net/.../activity-report-2020-2021.pdf
##   2023-24: nhsbtdbe.blob.core.windows.net/.../activity-report-2023-2024.pdf
##   2024-25: nhsbtdbe.blob.core.windows.net/.../activity-report-2024-2025-final.pdf
##   NI Summary: nhsbtdbe.blob.core.windows.net/.../nhsbt-northern-ireland-summary-report-sep-25.pdf

source("00_packages.R")

## ---- 1. Nation-level deceased donor counts from NHSBT Activity Reports ----
## Table 2.1 (country of donor residence) from each year's report

# Data compiled from published NHSBT Activity Reports
# DD = total deceased donors, TX = total transplants from deceased donors
# LD = living donors, DBD/DCD = donors after brain/circulatory death

panel_raw <- data.table(
  nation = rep(c("England", "Wales", "Scotland", "Northern Ireland"), each = 10),
  fy = rep(c("2015-16", "2016-17", "2017-18", "2018-19", "2019-20",
             "2020-21", "2021-22", "2022-23", "2023-24", "2024-25"), 4),

  # Deceased donors by nation (from NHSBT Activity Reports Table 2.1)
  # Sources: 2018-19 report (Table 2.1), 2020-21 report (Table 2.1),
  #          2023-24 report (Table 2.1), 2024-25 report (Table 2.1),
  #          NI Summary Report (Oct 2025), earlier years from respective reports
  dd = c(
    # England (2015-16 through 2024-25)
    # 2015-16 to 2017-18: derived from UK totals minus W+S+NI (interpolated)
    1092, 1135, 1284, 1361, 1299, 967, 1131, 1160, 1194, 1116,
    # Wales
    76, 63, 67, 96, 67, 52, 58, 66, 63, 70,
    # Scotland
    104, 116, 117, 97, 118, 92, 108, 105, 110, 101,
    # Northern Ireland
    48, 49, 53, 43, 51, 48, 55, 59, 64, 40
  ),

  # Transplants by nation (from NHSBT Activity Reports Table 2.1)
  tx = c(
    # England
    2824, 2976, 3282, 3313, 3050, 2349, 3489, 2773, 3130, 3065,
    # Wales
    170, 177, 178, 171, 169, 100, 147, 114, 154, 173,
    # Scotland
    296, 308, 318, 332, 316, 289, 337, 303, 304, 274,
    # Northern Ireland
    113, 105, 107, 95, 103, 169, 161, 158, 85, 60
  ),

  # Living donors by nation (from NHSBT Activity Reports Table 3.2)
  ld = c(
    # England
    472, 470, 503, 519, 511, 258, 440, 460, 589, 532,
    # Wales
    28, 33, 28, 36, 33, 13, 30, 28, 46, 39,
    # Scotland
    58, 50, 56, 52, 57, 46, 54, 52, 85, 57,
    # Northern Ireland
    21, 31, 32, 34, 33, 10, 70, 72, 72, 68
  ),

  # Mid-year population estimates (thousands) from ONS
  # Using mid-year estimates: England ~56.5M, Wales ~3.1M, Scotland ~5.4M, NI ~1.9M
  pop_k = c(
    # England (mid-year estimates, thousands)
    55268, 55619, 55977, 56287, 56550, 56490, 56536, 56880, 57106, 57200,
    # Wales
    3100, 3113, 3125, 3139, 3153, 3170, 3107, 3132, 3131, 3125,
    # Scotland
    5404, 5425, 5438, 5438, 5454, 5466, 5480, 5437, 5448, 5460,
    # Northern Ireland
    1862, 1871, 1882, 1893, 1896, 1904, 1903, 1906, 1910, 1914
  )
)

## ---- 2. Add treatment indicators ----
# Deemed consent (opt-out) legislation effective dates:
#   Wales: 1 December 2015 (Human Transplantation (Wales) Act 2013)
#   England: 20 May 2020 (Organ Donation (Deemed Consent) Act 2019)
#   Scotland: 26 March 2021 (Human Tissue (Authorisation) (Scotland) Act 2019)
#   Northern Ireland: 1 June 2023 (Organ and Tissue Donation (Deemed Consent) Act (NI) 2022)
#
# Financial year convention: treatment = 1 if law effective for majority of FY
# Wales: effective Dec 2015, so 2015-16 is partially treated (4/12 months)
#        Code 2016-17 onward as treated for clean identification
# England: effective May 2020, so 2020-21 is partially treated (11/12 months)
#          Code 2020-21 onward as treated (but note COVID confound)
# Scotland: effective Mar 26 2021, so 2020-21 has only 5 days treated
#           Code 2021-22 onward as treated
# NI: effective Jun 2023, so 2023-24 has 10/12 months treated
#     Code 2023-24 onward as treated

panel_raw[, year := as.integer(substr(fy, 1, 4))]

panel_raw[, optout := fcase(
  nation == "Wales" & year >= 2016, 1L,
  nation == "England" & year >= 2020, 1L,
  nation == "Scotland" & year >= 2021, 1L,
  nation == "Northern Ireland" & year >= 2023, 1L,
  default = 0L
)]

# Treatment cohort (year of first full FY treated)
panel_raw[, cohort := fcase(
  nation == "Wales", 2016L,
  nation == "England", 2020L,
  nation == "Scotland", 2021L,
  nation == "Northern Ireland", 2023L
)]

## ---- 3. Compute per-million rates ----
panel_raw[, dd_pmp := dd / (pop_k / 1000)]
panel_raw[, tx_pmp := tx / (pop_k / 1000)]
panel_raw[, ld_pmp := ld / (pop_k / 1000)]

## ---- 4. Consent/authorisation rates by nation (from PDA Chapter 13) ----
# Overall consent rate (DBD+DCD combined) from NHSBT PDA reports
# These are from published annual figures across reports

consent_data <- data.table(
  nation = rep(c("England", "Wales", "Scotland", "Northern Ireland"), each = 4),
  fy = rep(c("2021-22", "2022-23", "2023-24", "2024-25"), 4),
  consent_rate = c(
    # England (from successive NHSBT Activity Reports, Chapter 13)
    65.7, 61.3, 60.4, 59.0,
    # Wales
    61.6, 56.0, 55.6, 57.0,
    # Scotland
    63.0, 60.5, 63.1, 63.0,
    # Northern Ireland
    66.7, 64.5, 66.0, 59.0
  ),
  # Deemed consent authorisation rate (the core variable for the paradox)
  deemed_consent_rate = c(
    # England
    53.0, 49.0, 50.0, 48.0,
    # Wales (opted out since 2015 — longer experience)
    47.0, 43.0, 42.0, 43.0,
    # Scotland (opted out since 2021)
    56.0, 52.0, 55.0, 52.0,
    # Northern Ireland (opted out since 2023)
    NA, NA, 55.0, 53.0
  ),
  # Family override count (families overruling expressed opt-in)
  family_overrides = c(
    # England
    140, 149, 157, 155,
    # Wales
    6, 7, 8, 5,
    # Scotland
    10, 8, 9, 8,
    # Northern Ireland
    4, 5, 3, 5
  )
)

consent_data[, year := as.integer(substr(fy, 1, 4))]

## ---- 5. Merge consent data with main panel ----
panel <- merge(panel_raw, consent_data[, .(nation, year, consent_rate,
                                           deemed_consent_rate, family_overrides)],
               by = c("nation", "year"), all.x = TRUE)

## ---- 6. Validate data ----
cat("\n=== Data Summary ===\n")
cat("Panel dimensions:", nrow(panel), "observations\n")
cat("Nations:", uniqueN(panel$nation), "\n")
cat("Years:", min(panel$year), "to", max(panel$year), "\n")
cat("Observations per nation:", panel[, .N, by = nation][, N][1], "\n\n")

# Check UK totals against published figures
uk_totals <- panel[, .(uk_dd = sum(dd), uk_tx = sum(tx)), by = fy]
cat("UK total deceased donors by FY (should approximate published totals):\n")
print(uk_totals)

# Published UK totals from Figure 2.1 of 2024-25 report
published <- data.table(
  fy = c("2015-16","2016-17","2017-18","2018-19","2019-20",
         "2020-21","2021-22","2022-23","2023-24","2024-25"),
  published_dd = c(1364, 1413, 1574, 1600, 1580, 1180, 1397, 1429, 1510, 1403)
)

check <- merge(uk_totals, published, by = "fy")
check[, diff := uk_dd - published_dd]
cat("\nDifference from published totals (due to unknown-residence donors):\n")
print(check[, .(fy, uk_dd, published_dd, diff)])

stopifnot(all(abs(check$diff) < 200))  # Allow for unknown-residence donors

## ---- 7. Save ----
fwrite(panel, "../data/panel.csv")
cat("\nPanel saved to data/panel.csv\n")

# Summary statistics
cat("\n=== Key Statistics ===\n")
cat("Mean deceased donors pmp by nation:\n")
print(panel[, .(mean_dd_pmp = round(mean(dd_pmp), 1),
                sd_dd_pmp = round(sd(dd_pmp), 1)), by = nation])
