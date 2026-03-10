## 01_fetch_data.R — Data acquisition from Eurostat APIs
## APEP-0574: Gas Shock Import Substitution
## Sources: Eurostat trade (SITC), production indices (monthly), business demography
## No API keys required.

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

eu27 <- c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
          "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
          "PL","PT","RO","SK","SI","ES","SE")

# =====================================================================
# 1. ANNUAL TRADE — Extra-EU imports by SITC, country, partner
# Dataset: ext_lt_intratrd (Intra and Extra-EU trade by MS and product)
# =====================================================================
cat("=== Fetching annual trade data (ext_lt_intratrd) ===\n")

# This gives us: imports by country, SITC broad group, partner
# SITC groups: SITC5 (chemicals=energy-intensive), SITC6_8 (manuf=mixed),
#              SITC7 (machinery=placebo), SITC3 (fuels), SITC0_1 (food)
trade_annual <- tryCatch({
  raw <- get_eurostat("ext_lt_intratrd",
    filters = list(
      indic_et = "MIO_IMP_VAL",  # Import value in million EUR
      partner = "EXT_EU27_2020", # Extra-EU imports
      sitc06 = c("TOTAL", "SITC5", "SITC6_8", "SITC7", "SITC3", "SITC0_1", "SITC2_4")
    ),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  stop("Failed to fetch trade data: ", e$message,
       "\nPivot research question or fix the source.")
})

trade_annual <- trade_annual[geo %in% eu27]
trade_annual[, year := as.integer(format(time, "%Y"))]
trade_annual <- trade_annual[year >= 2017 & year <= 2024]
setnames(trade_annual, "values", "import_mio_eur")

cat(sprintf("Annual trade: %d rows, %d countries, %d SITC groups, years %d-%d\n",
            nrow(trade_annual), uniqueN(trade_annual$geo),
            uniqueN(trade_annual$sitc06),
            min(trade_annual$year), max(trade_annual$year)))

fwrite(trade_annual, file.path(data_dir, "trade_annual.csv"))

# =====================================================================
# 2. PARTNER-LEVEL TRADE — Chemicals imports by partner country
# Dataset: ext_lt_mainchem (extra-EU chemicals trade by partner)
# Shows where import substitution came from (China, India, etc.)
# =====================================================================
cat("\n=== Fetching partner-level chemicals trade ===\n")

chem_partner <- tryCatch({
  raw <- get_eurostat("ext_lt_mainchem",
    filters = list(
      indic_et = "MIO_IMP_VAL"
    ),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  warning("Partner-level chemicals trade failed: ", e$message)
  NULL
})

if (!is.null(chem_partner)) {
  chem_partner <- chem_partner[geo %in% eu27]
  chem_partner[, year := as.integer(format(time, "%Y"))]
  chem_partner <- chem_partner[year >= 2017 & year <= 2024]
  setnames(chem_partner, "values", "import_mio_eur")
  cat(sprintf("Chemical partner trade: %d rows, %d partners\n",
              nrow(chem_partner), uniqueN(chem_partner$partner)))
  fwrite(chem_partner, file.path(data_dir, "chem_partner_trade.csv"))
}

# Also fetch manufactured goods (SITC 6+8) by partner
cat("Fetching manufactured goods trade by partner...\n")
manu_partner <- tryCatch({
  raw <- get_eurostat("ext_lt_mainmanu",
    filters = list(indic_et = "MIO_IMP_VAL"),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  warning("Manufactured goods partner trade failed: ", e$message)
  NULL
})

if (!is.null(manu_partner)) {
  manu_partner <- manu_partner[geo %in% eu27]
  manu_partner[, year := as.integer(format(time, "%Y"))]
  manu_partner <- manu_partner[year >= 2017 & year <= 2024]
  setnames(manu_partner, "values", "import_mio_eur")
  cat(sprintf("Manufactured goods partner trade: %d rows, %d partners\n",
              nrow(manu_partner), uniqueN(manu_partner$partner)))
  fwrite(manu_partner, file.path(data_dir, "manu_partner_trade.csv"))
}

# Fetch machinery (SITC 7) by partner — our placebo
cat("Fetching machinery trade by partner (placebo)...\n")
mach_partner <- tryCatch({
  raw <- get_eurostat("ext_lt_mainmach",
    filters = list(indic_et = "MIO_IMP_VAL"),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  warning("Machinery partner trade failed: ", e$message)
  NULL
})

if (!is.null(mach_partner)) {
  mach_partner <- mach_partner[geo %in% eu27]
  mach_partner[, year := as.integer(format(time, "%Y"))]
  mach_partner <- mach_partner[year >= 2017 & year <= 2024]
  setnames(mach_partner, "values", "import_mio_eur")
  cat(sprintf("Machinery partner trade: %d rows\n", nrow(mach_partner)))
  fwrite(mach_partner, file.path(data_dir, "mach_partner_trade.csv"))
}

# =====================================================================
# 3. MONTHLY PRODUCTION INDICES — By NACE sector and country
# Dataset: sts_inpr_m (Short-term statistics: industrial production)
# =====================================================================
cat("\n=== Fetching monthly production indices ===\n")

# Energy-intensive NACE sectors
nace_treated <- c("C20", "C23", "C24")  # Chemicals, Glass/ceramics, Metals
# Non-energy-intensive (placebo)
nace_placebo <- c("C26", "C27", "C28")  # Electronics, Electrical, Machinery
# Also fetch total manufacturing
nace_all <- c("C", nace_treated, nace_placebo, "C22", "C25", "C19")

prod_monthly <- tryCatch({
  raw <- get_eurostat("sts_inpr_m",
    filters = list(
      s_adj = "SCA",   # Seasonally + calendar adjusted
      unit = "I21",     # Index 2021=100
      nace_r2 = nace_all
    ),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  stop("Failed to fetch production indices: ", e$message,
       "\nPivot research question or fix the source.")
})

prod_monthly <- prod_monthly[geo %in% eu27]
prod_monthly[, year := year(time)]
prod_monthly[, month := month(time)]
prod_monthly[, ym := format(time, "%Y-%m")]
prod_monthly <- prod_monthly[year >= 2019 & year <= 2024]
setnames(prod_monthly, "values", "prod_index")

cat(sprintf("Production indices: %d rows, %d countries, %d sectors, %s to %s\n",
            nrow(prod_monthly), uniqueN(prod_monthly$geo),
            uniqueN(prod_monthly$nace_r2),
            min(prod_monthly$ym), max(prod_monthly$ym)))

fwrite(prod_monthly, file.path(data_dir, "production_monthly.csv"))

# =====================================================================
# 4. MONTHLY AGGREGATE TRADE — BEC categories (monthly)
# Dataset: ext_st_27_2020msbec (trade by BEC, monthly)
# Gives monthly timing of import shifts
# =====================================================================
cat("\n=== Fetching monthly BEC trade data ===\n")

bec_monthly <- tryCatch({
  raw <- get_eurostat("ext_st_27_2020msbec",
    filters = list(
      stk_flow = "IMP",
      indic_et = "TRD_VAL",  # Trade value
      partner = "EXT_EU27_2020",
      bclas_bec = c("TOTAL", "INT", "CAP", "CONS")
    ),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  warning("Monthly BEC trade failed: ", e$message)
  NULL
})

if (!is.null(bec_monthly)) {
  bec_monthly <- bec_monthly[geo %in% eu27]
  bec_monthly[, year := year(time)]
  bec_monthly[, ym := format(time, "%Y-%m")]
  bec_monthly <- bec_monthly[year >= 2019 & year <= 2024]
  setnames(bec_monthly, "values", "trade_val")
  cat(sprintf("Monthly BEC trade: %d rows, %s to %s\n",
              nrow(bec_monthly), min(bec_monthly$ym), max(bec_monthly$ym)))
  fwrite(bec_monthly, file.path(data_dir, "bec_monthly_trade.csv"))
}

# =====================================================================
# 5. BUSINESS DEMOGRAPHY — Annual firm births/deaths by NACE
# =====================================================================
cat("\n=== Fetching business demography ===\n")

bd_dt <- tryCatch({
  raw <- get_eurostat("bd_9ac_l_form_r2",
    filters = list(
      nace_r2 = c("C20", "C23", "C24_C25", "C26", "C27", "C28", "B-S_X_K642"),
      indic_sb = c("V11110", "V11210", "V11910")  # births, deaths, active
    ),
    cache_dir = data_dir)
  as.data.table(raw)
}, error = function(e) {
  warning("Business demography (bd_9ac_l_form_r2) failed: ", e$message)
  NULL
})

if (!is.null(bd_dt)) {
  bd_dt <- bd_dt[geo %in% eu27]
  bd_dt[, year := as.integer(format(time, "%Y"))]
  bd_dt <- bd_dt[year >= 2015 & year <= 2023]
  setnames(bd_dt, "values", "count")
  cat(sprintf("Business demography: %d rows, %d countries, years %d-%d\n",
              nrow(bd_dt), uniqueN(bd_dt$geo),
              min(bd_dt$year), max(bd_dt$year)))
  fwrite(bd_dt, file.path(data_dir, "business_demography.csv"))
} else {
  cat("Business demography not available — supplementary analysis only.\n")
}

# =====================================================================
# 6. GAS DEPENDENCE — Pre-war Russian gas shares
# =====================================================================
cat("\n=== Setting up gas dependence ===\n")

# 2021 Russian gas import shares (Eurostat Energy Statistics / IEA)
# Sources: Eurostat nrg_ti_gas, European Commission, IEA
gas_dep <- data.table(
  geo = c("FI","LV","EE","BG","SK","CZ","DE","HU","AT","PL",
          "IT","EL","LT","SI","HR","RO","FR","NL","BE","DK",
          "SE","LU","IE","PT","ES","CY","MT"),
  russian_gas_share = c(
    0.75, 0.93, 0.79, 0.77, 0.85, 0.97, 0.55, 0.80, 0.80, 0.55,
    0.40, 0.39, 0.41, 0.09, 0.00, 0.47, 0.17, 0.15, 0.06, 0.00,
    0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00
  ),
  # Total gas consumption as % of TPES (2021)
  gas_tpes_share = c(
    0.06, 0.25, 0.08, 0.14, 0.25, 0.17, 0.27, 0.33, 0.22, 0.17,
    0.40, 0.17, 0.25, 0.10, 0.27, 0.30, 0.16, 0.40, 0.23, 0.14,
    0.02, 0.23, 0.32, 0.22, 0.22, 0.00, 0.00
  ),
  country_name = c(
    "Finland","Latvia","Estonia","Bulgaria","Slovakia","Czech Republic",
    "Germany","Hungary","Austria","Poland","Italy","Greece","Lithuania",
    "Slovenia","Croatia","Romania","France","Netherlands","Belgium",
    "Denmark","Sweden","Luxembourg","Ireland","Portugal","Spain","Cyprus","Malta"
  )
)

# Combined exposure: Russian share × overall gas dependence
gas_dep[, gas_exposure := russian_gas_share * gas_tpes_share]

cat(sprintf("Gas dependence: %d countries\n", nrow(gas_dep)))
cat(sprintf("  Russian share: mean=%.2f, sd=%.2f, range=[%.2f, %.2f]\n",
            mean(gas_dep$russian_gas_share), sd(gas_dep$russian_gas_share),
            min(gas_dep$russian_gas_share), max(gas_dep$russian_gas_share)))
cat(sprintf("  Gas exposure: mean=%.3f, sd=%.3f\n",
            mean(gas_dep$gas_exposure), sd(gas_dep$gas_exposure)))

fwrite(gas_dep, file.path(data_dir, "gas_dependence.csv"))

# =====================================================================
# 7. ENERGY INTENSITY — SITC-to-NACE mapping
# =====================================================================
cat("\n=== Setting up product classifications ===\n")

sitc_class <- data.table(
  sitc06 = c("SITC5", "SITC6_8", "SITC7", "SITC3", "SITC0_1", "SITC2_4"),
  product_label = c("Chemicals (SITC 5)", "Manufactured goods (SITC 6+8)",
                     "Machinery (SITC 7)", "Mineral fuels (SITC 3)",
                     "Food/drink/tobacco (SITC 0+1)", "Raw materials (SITC 2+4)"),
  energy_intensive = c(1, 1, 0, NA, 0, 0),  # SITC3 excluded (fuels themselves)
  nace_match = c("C20", "C23_C24", "C26_C28", NA, NA, NA)
)

nace_class <- data.table(
  nace_r2 = c("C20", "C23", "C24", "C22", "C25", "C19",
              "C26", "C27", "C28", "C"),
  sector_label = c("Chemicals", "Glass/ceramics", "Basic metals",
                    "Rubber/plastics", "Metal products", "Coke/petroleum",
                    "Electronics", "Electrical equip.", "Machinery",
                    "Total manufacturing"),
  energy_intensive = c(1, 1, 1, 0, 0, 1, 0, 0, 0, NA),
  # MJ per EUR of GVA (approx, from EU KLEMS/Eurostat energy statistics)
  energy_intensity_mj = c(15, 25, 30, 5, 4, 45, 2, 3, 3, 8)
)

fwrite(sitc_class, file.path(data_dir, "sitc_classification.csv"))
fwrite(nace_class, file.path(data_dir, "nace_classification.csv"))

# =====================================================================
# DATA VALIDATION
# =====================================================================
cat("\n=== DATA VALIDATION ===\n")

# Trade data
stopifnot("Annual trade must have >50 rows" = nrow(trade_annual) > 50)
stopifnot("Must cover 20+ countries" = uniqueN(trade_annual$geo) >= 20)
stopifnot("Must cover 2019-2023" = all(c(2019, 2022, 2023) %in% trade_annual$year))
cat(sprintf("PASS: Annual trade - %d rows, %d countries, %d SITC groups\n",
            nrow(trade_annual), uniqueN(trade_annual$geo),
            uniqueN(trade_annual$sitc06)))

# Production indices
stopifnot("Production must have >1000 rows" = nrow(prod_monthly) > 1000)
stopifnot("Production must cover 15+ countries" = uniqueN(prod_monthly$geo) >= 15)
cat(sprintf("PASS: Production indices - %d rows, %d countries, %d sectors\n",
            nrow(prod_monthly), uniqueN(prod_monthly$geo),
            uniqueN(prod_monthly$nace_r2)))

# Gas dependence
stopifnot("Gas dep must have 27 rows" = nrow(gas_dep) == 27)
stopifnot("Gas shares must be 0-1" =
  all(gas_dep$russian_gas_share >= 0 & gas_dep$russian_gas_share <= 1))
cat("PASS: Gas dependence - 27 EU countries\n")

cat("\n=== ALL DATA VALIDATION PASSED ===\n")
cat(sprintf("Files saved: %s\n",
            paste(list.files(data_dir, pattern = "\\.csv$"), collapse = ", ")))
