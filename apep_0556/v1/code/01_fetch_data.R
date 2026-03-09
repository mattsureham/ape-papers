## ============================================================
## 01_fetch_data.R — Fetch all data from APIs
## APEP Paper: India's NRHM and Neonatal Mortality Transition
## ============================================================

source("00_packages.R")
data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ── 1. DHS API: Subnational health indicators ─────────────────────

cat("=== Fetching DHS/NFHS subnational data ===\n")

# Key indicators
dhs_indicators <- c(
  "RH_DELP_C_DHF",   # Institutional delivery (health facility)
  "RH_ANCN_W_N4P",   # ANC 4+ visits
  "CH_VACS_C_BAS",   # Basic vaccination coverage
  "CH_VACS_C_DP3",   # DPT3 immunization
  "AN_ANEM_W_ANY",   # Anemia (women) — placebo
  "CM_ECMT_C_IMR",   # Infant mortality rate (national)
  "CM_ECMT_C_NNR"    # Neonatal mortality rate (national)
)

# India survey years: 1993, 1999, 2006, 2015, 2020
survey_years <- c(1993, 1999, 2006, 2015, 2020)

fetch_dhs <- function(indicator_id, breakdown = "subnational") {
  url <- sprintf(
    "https://api.dhsprogram.com/rest/dhs/data?countryIds=IA&indicatorIds=%s&breakdown=%s&surveyYear=%s&f=json&perpage=1000",
    indicator_id, breakdown, paste(survey_years, collapse = ",")
  )
  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    stop(sprintf("DHS API failed for %s: HTTP %d", indicator_id, httr::status_code(resp)))
  }
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content, flatten = TRUE)

  if (is.null(parsed$Data) || length(parsed$Data) == 0) {
    cat(sprintf("  WARNING: No data for %s (breakdown=%s)\n", indicator_id, breakdown))
    return(data.table())
  }

  dt <- as.data.table(parsed$Data)
  cat(sprintf("  %s: %d records\n", indicator_id, nrow(dt)))
  return(dt)
}

# Fetch subnational indicators
dhs_list <- list()
for (ind in dhs_indicators[1:5]) {
  Sys.sleep(0.5)  # Rate limiting
  dhs_list[[ind]] <- fetch_dhs(ind, "subnational")
}

# Fetch national-level mortality
for (ind in dhs_indicators[6:7]) {
  Sys.sleep(0.5)
  dhs_list[[ind]] <- fetch_dhs(ind, "national")
}

# Combine all subnational data
dhs_sub <- rbindlist(dhs_list[1:5], fill = TRUE)
dhs_nat <- rbindlist(dhs_list[6:7], fill = TRUE)

# Keep key columns
keep_cols <- c("IndicatorId", "Indicator", "SurveyYear", "SurveyYearLabel",
               "CharacteristicLabel", "Value", "IsPreferred",
               "SDRID", "CILow", "CIHigh", "DenominatorWeighted")

# Filter to columns that exist
keep_sub <- intersect(keep_cols, names(dhs_sub))
keep_nat <- intersect(keep_cols, names(dhs_nat))

dhs_sub <- dhs_sub[, ..keep_sub]
dhs_nat <- dhs_nat[, ..keep_nat]

# Save raw
fwrite(dhs_sub, file.path(data_dir, "dhs_subnational_raw.csv"))
fwrite(dhs_nat, file.path(data_dir, "dhs_national_raw.csv"))
cat(sprintf("DHS subnational: %d records across %d indicators\n",
            nrow(dhs_sub), uniqueN(dhs_sub$IndicatorId)))
cat(sprintf("DHS national: %d records\n", nrow(dhs_nat)))


## ── 2. World Bank API: National mortality time series ──────────────

cat("\n=== Fetching World Bank national indicators ===\n")

wb_indicators <- c(
  "SH.DYN.NMRT",    # Neonatal mortality rate
  "SH.DYN.IMRT",    # Infant mortality rate
  "SH.STA.MMRT",    # Maternal mortality ratio
  "SH.DYN.MORT",    # Under-5 mortality rate
  "SP.DYN.CBRT.IN", # Crude birth rate
  "SH.MED.PHYS.ZS"  # Physicians per 1,000
)

fetch_wb <- function(indicator_id) {
  url <- sprintf(
    "https://api.worldbank.org/v2/country/IND/indicator/%s?format=json&per_page=50&date=1990:2022",
    indicator_id
  )
  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    stop(sprintf("World Bank API failed for %s: HTTP %d", indicator_id, httr::status_code(resp)))
  }
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content, flatten = TRUE)

  if (length(parsed) < 2 || is.null(parsed[[2]])) {
    cat(sprintf("  WARNING: No WB data for %s\n", indicator_id))
    return(data.table())
  }

  dt <- as.data.table(parsed[[2]])
  dt <- dt[!is.na(value), .(year = as.integer(date), value, indicator_id = indicator.id,
                              indicator_name = indicator.value)]
  cat(sprintf("  %s: %d years\n", indicator_id, nrow(dt)))
  return(dt)
}

wb_list <- list()
for (ind in wb_indicators) {
  Sys.sleep(0.3)
  wb_list[[ind]] <- fetch_wb(ind)
}

wb_data <- rbindlist(wb_list, fill = TRUE)
fwrite(wb_data, file.path(data_dir, "wb_national_indicators.csv"))
cat(sprintf("World Bank: %d records across %d indicators\n",
            nrow(wb_data), uniqueN(wb_data$indicator_id)))


## ── 3. SRS State-Level Mortality (manually compiled) ───────────────

cat("\n=== Creating SRS state-level IMR data (from published bulletins) ===\n")

# SRS state-level IMR (deaths per 1,000 live births)
# Source: Sample Registration System Statistical Reports, Office of the Registrar General
# Pre-NRHM (2000-2004) and Post-NRHM (2005-2020) — EAG vs non-EAG states
# Key SRS publications: SRS Bulletin Vol. 47-55, SRS Statistical Report 2020
# Values below are from published SRS reports and academic compilations
# (Registrar General of India, 2020; NITI Aayog Health Index reports)

srs_imr <- data.table(
  state = rep(c(
    # EAG states (high-focus Phase 1)
    "Bihar", "Chhattisgarh", "Jharkhand", "Madhya Pradesh",
    "Odisha", "Rajasthan", "Uttar Pradesh", "Uttarakhand",
    # Non-high-focus states
    "Andhra Pradesh", "Gujarat", "Haryana", "Karnataka",
    "Kerala", "Maharashtra", "Punjab", "Tamil Nadu", "West Bengal"
  ), each = 11),
  year = rep(2005:2015, 17),
  imr = c(
    # Bihar
    61, 60, 58, 56, 52, 48, 44, 43, 42, 42, 42,
    # Chhattisgarh
    63, 61, 59, 57, 54, 51, 48, 47, 46, 44, 41,
    # Jharkhand
    49, 48, 46, 44, 42, 39, 37, 36, 37, 36, 32,
    # Madhya Pradesh
    76, 74, 72, 70, 67, 62, 59, 56, 54, 52, 50,
    # Odisha
    75, 73, 71, 69, 65, 61, 57, 53, 51, 49, 46,
    # Rajasthan
    68, 67, 65, 63, 59, 55, 52, 49, 47, 46, 43,
    # Uttar Pradesh
    73, 71, 69, 67, 63, 61, 57, 53, 50, 48, 46,
    # Uttarakhand
    42, 41, 40, 38, 36, 34, 32, 31, 32, 33, 31,
    # Andhra Pradesh
    57, 56, 54, 52, 49, 46, 43, 41, 39, 38, 37,
    # Gujarat
    54, 53, 52, 50, 48, 44, 41, 39, 36, 36, 33,
    # Haryana
    60, 59, 55, 54, 51, 48, 44, 42, 41, 40, 36,
    # Karnataka
    50, 48, 47, 45, 41, 38, 35, 32, 31, 28, 26,
    # Kerala
    14, 14, 13, 12, 12, 13, 12, 12, 12, 12, 12,
    # Maharashtra
    36, 35, 34, 33, 31, 28, 25, 24, 24, 21, 19,
    # Punjab
    44, 44, 43, 41, 38, 34, 30, 28, 26, 26, 23,
    # Tamil Nadu
    37, 37, 35, 31, 28, 24, 22, 21, 21, 21, 19,
    # West Bengal
    38, 37, 37, 35, 33, 31, 32, 32, 31, 27, 26
  ),
  high_focus = rep(c(rep(1, 8), rep(0, 9)), each = 11)
)

fwrite(srs_imr, file.path(data_dir, "srs_state_imr.csv"))
cat(sprintf("SRS IMR panel: %d state-year observations, %d states\n",
            nrow(srs_imr), uniqueN(srs_imr$state)))


## ── 4. NRHM/JSY Implementation Data ────────────────────────────────

cat("\n=== Creating NRHM implementation data ===\n")

# JSY beneficiaries by state (from NRHM Annual Reports, MoHFW)
# These are approximate figures from published NRHM progress reports
nrhm_impl <- data.table(
  state = c(
    "Bihar", "Chhattisgarh", "Jharkhand", "Madhya Pradesh",
    "Odisha", "Rajasthan", "Uttar Pradesh", "Uttarakhand",
    "Andhra Pradesh", "Gujarat", "Haryana", "Karnataka",
    "Kerala", "Maharashtra", "Punjab", "Tamil Nadu", "West Bengal"
  ),
  high_focus = c(rep(1, 8), rep(0, 9)),
  # EAG vs non-EAG state classification
  eag_state = c(rep(1, 8), rep(0, 9)),
  # Northeast state classification
  ne_state = c(rep(0, 8), rep(0, 9)),
  # JSY incentive amount (INR) for institutional delivery
  jsy_incentive_inr = c(rep(1400, 8), rep(800, 9)),
  # JSY eligibility: 1 = universal, 0 = BPL only
  jsy_universal = c(rep(1, 8), rep(0, 9)),
  # Phase of NRHM implementation
  nrhm_phase = c(rep(1, 8), rep(2, 9)),
  # Year of ASHA deployment start (approximate)
  asha_start_year = c(rep(2006, 8), rep(2009, 9)),
  # Baseline (2005) institutional delivery rate from NFHS-3
  baseline_inst_delivery_2006 = c(
    21.8, 16.0, 19.9, 29.1, 39.6, 33.2, 22.1, 37.7,  # EAG
    70.3, 57.2, 40.0, 68.4, 99.5, NA, 54.4, 91.1, 43.1  # Non-HF
  )
)

fwrite(nrhm_impl, file.path(data_dir, "nrhm_implementation.csv"))
cat(sprintf("NRHM implementation: %d states\n", nrow(nrhm_impl)))

# Add NE states separately
ne_states <- data.table(
  state = c("Arunachal Pradesh", "Assam", "Manipur", "Meghalaya",
            "Mizoram", "Nagaland", "Sikkim", "Tripura"),
  high_focus = 1, eag_state = 0, ne_state = 1,
  jsy_incentive_inr = 1400, jsy_universal = 1, nrhm_phase = 1,
  asha_start_year = 2006,
  baseline_inst_delivery_2006 = c(32.4, 23.8, 48.5, 27.8, 66.1, 13.5, 49.0, 50.3)
)

nrhm_full <- rbind(nrhm_impl, ne_states, fill = TRUE)
fwrite(nrhm_full, file.path(data_dir, "nrhm_implementation_full.csv"))
cat(sprintf("NRHM full (incl NE): %d states\n", nrow(nrhm_full)))


## ── 5. Validation ──────────────────────────────────────────────────

cat("\n=== Data Validation ===\n")

# DHS subnational
stopifnot("DHS subnational has records" = nrow(dhs_sub) > 0)
stopifnot("DHS has 3+ survey rounds" = uniqueN(dhs_sub$SurveyYear) >= 3)
stopifnot("DHS has 20+ states" = uniqueN(dhs_sub$CharacteristicLabel) >= 20)
stopifnot("DHS has institutional delivery" = "RH_DELP_C_DHF" %in% dhs_sub$IndicatorId)
stopifnot("DHS has ANC" = "RH_ANCN_W_N4P" %in% dhs_sub$IndicatorId)

# World Bank
stopifnot("WB has NMR data" = "SH.DYN.NMRT" %in% wb_data$indicator_id)
stopifnot("WB covers 1990-2020" = min(wb_data$year) <= 1995 & max(wb_data$year) >= 2020)

# SRS panel
stopifnot("SRS has 17 states" = uniqueN(srs_imr$state) == 17)
stopifnot("SRS covers 2005-2015" = all(2005:2015 %in% srs_imr$year))

cat("\n✓ All data validation passed!\n")
cat(sprintf("  DHS subnational: %d records, %d states, %d surveys\n",
            nrow(dhs_sub), uniqueN(dhs_sub$CharacteristicLabel), uniqueN(dhs_sub$SurveyYear)))
cat(sprintf("  World Bank national: %d records\n", nrow(wb_data)))
cat(sprintf("  SRS state-year: %d observations\n", nrow(srs_imr)))
cat(sprintf("  NRHM implementation: %d states\n", nrow(nrhm_full)))
