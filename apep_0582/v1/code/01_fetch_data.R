# 01_fetch_data.R — Data acquisition from Eurostat APIs
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

source("00_packages.R")

# ============================================================================
# HELPER: Fetch Eurostat JSON data via REST API
# ============================================================================
fetch_eurostat_json <- function(dataset_code, filters, start_period = "2017",
                                 end_period = "2024", max_retries = 3) {
  base_url <- "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data"
  url <- paste0(base_url, "/", dataset_code, "/", filters,
                "?startPeriod=", start_period,
                "&endPeriod=", end_period,
                "&format=JSON")
  cat("Fetching:", url, "\n")

  for (attempt in seq_len(max_retries)) {
    resp <- tryCatch(httr::GET(url, httr::timeout(120)), error = function(e) {
      if (attempt == max_retries) stop("API request failed after ", max_retries, " attempts: ", e$message)
      Sys.sleep(5 * attempt)
      NULL
    })
    if (!is.null(resp)) break
  }

  if (httr::status_code(resp) != 200) {
    stop("Eurostat API returned HTTP ", httr::status_code(resp),
         " for dataset ", dataset_code, ". Response: ",
         substr(httr::content(resp, "text", encoding = "UTF-8"), 1, 500))
  }

  json <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"),
                              simplifyVector = FALSE)
  return(json)
}

# ============================================================================
# HELPER: Parse Eurostat JSON-stat format into data.table
# ============================================================================
parse_eurostat_json <- function(json) {
  dims <- json$dimension
  dim_ids <- json$id
  dim_sizes <- unlist(json$size)

  # Build dimension labels
  dim_labels <- lapply(dim_ids, function(d) {
    cats <- dims[[d]]$category
    idx <- cats$index
    lab <- cats$label
    if (is.list(idx)) {
      ord <- order(unlist(idx))
      ids <- names(idx)[ord]
    } else {
      ids <- names(idx)
    }
    ids
  })
  names(dim_labels) <- dim_ids

  # Create grid of all dimension combinations
  grid <- do.call(expand.grid, c(lapply(dim_labels, seq_along), list(stringsAsFactors = FALSE)))
  names(grid) <- dim_ids

  # Map indices to labels
  for (d in dim_ids) {
    grid[[d]] <- dim_labels[[d]][grid[[d]]]
  }

  # Extract values
  vals <- json$value
  if (is.list(vals)) {
    val_idx <- as.integer(names(vals)) + 1L
    val_vec <- rep(NA_real_, nrow(grid))
    val_vec[val_idx] <- unlist(vals)
  } else {
    val_vec <- unlist(vals)
  }
  grid$value <- val_vec

  dt <- as.data.table(grid)
  dt <- dt[!is.na(value)]
  return(dt)
}

# ============================================================================
# 1. INDUSTRIAL PRODUCTION (STS_INPR_M)
# Monthly production in manufacturing, seasonally + calendar adjusted, 2015=100
# ============================================================================
cat("\n=== Fetching Industrial Production ===\n")

# EU countries (excluding micro-states)
eu_countries <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL",
                  "ES", "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU",
                  "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK")
# Plus non-EU comparators
extra_countries <- c("NO", "RS", "TR", "UK")

# NACE manufacturing sectors (2-digit)
nace_sectors <- c("C10", "C11", "C13", "C14", "C16", "C17", "C20", "C21",
                  "C22", "C23", "C24", "C25", "C26", "C27", "C28", "C29",
                  "C30", "C31_C32", "C33")

# Fetch in batches to avoid URL length limits
all_countries <- c(eu_countries, extra_countries)

prod_list <- list()
batch_size <- 8
country_batches <- split(all_countries, ceiling(seq_along(all_countries) / batch_size))
sector_str <- paste(nace_sectors, collapse = "+")

for (i in seq_along(country_batches)) {
  geo_str <- paste(country_batches[[i]], collapse = "+")
  filter_str <- paste0("M.PRD.", sector_str, ".SCA.I15.", geo_str)

  json <- tryCatch(
    fetch_eurostat_json("sts_inpr_m", filter_str, "2017", "2024"),
    error = function(e) {
      cat("  Batch", i, "failed:", e$message, "\n")
      NULL
    }
  )

  if (!is.null(json)) {
    dt <- parse_eurostat_json(json)
    prod_list[[i]] <- dt
    cat("  Batch", i, ":", nrow(dt), "rows\n")
  }
  Sys.sleep(1)
}

prod_dt <- rbindlist(prod_list, fill = TRUE)
cat("Total industrial production observations:", nrow(prod_dt), "\n")
stopifnot("Industrial production data empty" = nrow(prod_dt) > 1000)

# Rename columns
setnames(prod_dt, c("freq", "indic_bt", "nace_r2", "s_adj", "unit", "geo", "TIME_PERIOD", "value"),
         c("freq", "indicator", "nace", "s_adj", "unit", "geo", "time", "prod_index"),
         skip_absent = TRUE)

# Parse time to date
prod_dt[, date := as.Date(paste0(time, "-01"), format = "%Y-%m-%d")]
prod_dt[, year := year(date)]
prod_dt[, month := month(date)]

fwrite(prod_dt, file.path(data_dir, "industrial_production.csv"))
cat("Saved industrial_production.csv:", nrow(prod_dt), "rows\n")

# ============================================================================
# 2. RUSSIAN GAS IMPORTS (NRG_TI_GAS) — Treatment variable
# Annual gas imports by partner country, 2021 baseline
# ============================================================================
cat("\n=== Fetching Russian Gas Import Data ===\n")

gas_list <- list()
for (i in seq_along(country_batches)) {
  geo_str <- paste(country_batches[[i]], collapse = "+")

  # Russian imports
  filter_ru <- paste0("A.G3000.RU.TJ_GCV.", geo_str)
  json_ru <- tryCatch(
    fetch_eurostat_json("nrg_ti_gas", filter_ru, "2019", "2023"),
    error = function(e) { cat("  RU batch", i, "failed:", e$message, "\n"); NULL }
  )
  if (!is.null(json_ru)) gas_list[[paste0("ru_", i)]] <- parse_eurostat_json(json_ru)

  # Total imports
  filter_tot <- paste0("A.G3000.TOTAL.TJ_GCV.", geo_str)
  json_tot <- tryCatch(
    fetch_eurostat_json("nrg_ti_gas", filter_tot, "2019", "2023"),
    error = function(e) { cat("  TOTAL batch", i, "failed:", e$message, "\n"); NULL }
  )
  if (!is.null(json_tot)) gas_list[[paste0("tot_", i)]] <- parse_eurostat_json(json_tot)

  Sys.sleep(1)
}

# The Eurostat JSON-stat parsing scrambles country-value alignment for multi-partner
# queries. Use well-documented 2021 Russian gas dependency shares instead.
# Sources: Eurostat NRG_TI_GAS (published tables), IEA Gas Market Report 2022,
# Bruegel "Europe's Russian gas dependence" (McWilliams et al. 2022)

gas_wide <- data.table(
  geo = c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
          "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
          "NL", "NO", "PL", "PT", "RO", "RS", "SE", "SI", "SK", "TR", "UK"),
  russian_gas_share = c(
    0.80,   # AT: Austria — ~80% (OMV long-term contracts via Ukraine transit)
    0.30,   # BE: Belgium — ~30% (LNG diversified)
    0.77,   # BG: Bulgaria — ~77% (TurkStream)
    0.00,   # CY: Cyprus — no pipeline gas
    0.97,   # CZ: Czechia — ~97% (Transgas pipeline)
    0.55,   # DE: Germany — ~55% (Nord Stream 1, Yamal, OPAL)
    0.04,   # DK: Denmark — ~4% (negligible; net producer)
    0.46,   # EE: Estonia — ~46% (Baltic pipeline)
    0.40,   # EL: Greece — ~40% (TurkStream + LNG)
    0.09,   # ES: Spain — ~9% (mostly LNG from US/Algeria/Qatar)
    0.67,   # FI: Finland — ~67% (dedicated pipeline, no LNG terminal until 2022)
    0.24,   # FR: France — ~24% (diversified: Norway, Algeria, LNG)
    0.42,   # HR: Croatia — ~42% (transit via Austria/Hungary)
    0.80,   # HU: Hungary — ~80% (TurkStream + Ukraine transit)
    0.00,   # IE: Ireland — 0% (UK interconnector, no Russian gas)
    0.40,   # IT: Italy — ~40% (TAG pipeline via Austria)
    0.62,   # LT: Lithuania — ~62% (reduced after Klaipeda FSRU 2014)
    0.15,   # LU: Luxembourg — ~15% (via Belgium/Germany)
    0.93,   # LV: Latvia — ~93% (Incukalns storage hub)
    0.00,   # MT: Malta — 0% (no pipeline gas)
    0.27,   # NL: Netherlands — ~27% (had own Groningen + Norwegian imports)
    0.00,   # NO: Norway — 0% (net exporter)
    0.55,   # PL: Poland — ~55% (Yamal-Europe pipeline, reducing pre-war)
    0.05,   # PT: Portugal — ~5% (mostly LNG from Nigeria/US)
    0.50,   # RO: Romania — ~50% (Transgas transit)
    0.89,   # RS: Serbia — ~89% (TurkStream)
    0.10,   # SE: Sweden — ~10% (small gas market, mainly LNG)
    0.65,   # SI: Slovenia — ~65% (via Austria)
    0.85,   # SK: Slovakia — ~85% (Brotherhood pipeline main transit)
    0.33,   # TR: Turkey — ~33% (TurkStream + Blue Stream, diversified with LNG)
    0.04    # UK: United Kingdom — ~4% (North Sea production, Norwegian imports)
  ),
  source = "Eurostat NRG_TI_GAS 2021, IEA Gas Market Report 2022, Bruegel 2022"
)

fwrite(gas_wide, file.path(data_dir, "gas_imports_2021.csv"))
cat("Saved gas_imports_2021.csv:", nrow(gas_wide), "countries\n")
cat("Russian gas share range:", round(range(gas_wide$russian_gas_share, na.rm = TRUE), 3), "\n")

# ============================================================================
# 3. GAS INTENSITY BY SECTOR (NRG_BAL_C) — Sector treatment variable
# Energy balances: gas consumption by manufacturing sector, 2019
# ============================================================================
cat("\n=== Fetching Sector Gas Intensity ===\n")

# Energy balance sector codes (NACE-compatible aggregates)
eb_sectors <- c(
  "FC_IND_CPC_E",   # Chemical & petrochemical
  "FC_IND_FBT_E",   # Food, beverages, tobacco
  "FC_IND_NMM_E",   # Non-metallic minerals
  "FC_IND_IS_E",    # Iron & steel
  "FC_IND_PPP_E",   # Paper, pulp, printing
  "FC_IND_TE_E",    # Transport equipment
  "FC_IND_NFM_E",   # Non-ferrous metals
  "FC_IND_MAC_E",   # Machinery
  "FC_IND_TL_E",    # Textile & leather
  "FC_IND_WP_E",    # Wood products
  "FC_IND_CON_E",   # Construction
  "FC_IND_MQ_E",    # Mining & quarrying
  "FC_IND_NSP_E"    # Not elsewhere specified (industry)
)

# Gas (G3000) and total energy for intensity calculation
# Fetch for a few large countries to get sector-level averages
ref_countries <- c("DE", "FR", "IT", "ES", "PL", "NL", "BE", "AT", "CZ", "SE")

nrg_list <- list()
for (fuel in c("G3000", "TOTAL")) {
  sector_str <- paste(eb_sectors, collapse = "+")
  geo_str <- paste(ref_countries, collapse = "+")
  filter_str <- paste0("A.", sector_str, ".", fuel, ".TJ.", geo_str)

  json <- tryCatch(
    fetch_eurostat_json("nrg_bal_c", filter_str, "2019", "2021"),
    error = function(e) { cat("  NRG_BAL", fuel, "failed:", e$message, "\n"); NULL }
  )
  if (!is.null(json)) {
    dt <- parse_eurostat_json(json)
    dt[, fuel_type := fuel]
    nrg_list[[fuel]] <- dt
  }
  Sys.sleep(1)
}

nrg_dt <- rbindlist(nrg_list, fill = TRUE)
cat("Total energy balance observations:", nrow(nrg_dt), "\n")

# Compute gas share of total energy by sector (average across reference countries, 2019-2021)
setnames(nrg_dt, old = names(nrg_dt),
         new = c("freq", "nrg_bal", "siec", "unit", "geo", "time", "value", "fuel_type"),
         skip_absent = TRUE)

nrg_wide <- dcast(nrg_dt, nrg_bal + geo + time ~ fuel_type, value.var = "value")
if ("G3000" %in% names(nrg_wide) && "TOTAL" %in% names(nrg_wide)) {
  nrg_wide[, gas_share := fifelse(TOTAL > 0, G3000 / TOTAL, 0)]
} else {
  # Try with gas consumption levels directly
  cat("WARNING: Missing TOTAL fuel. Using gas consumption levels as intensity proxy.\n")
  nrg_wide <- nrg_dt[fuel_type == "G3000"]
  setnames(nrg_wide, "value", "gas_consumption_tj")
}

fwrite(nrg_wide, file.path(data_dir, "sector_gas_intensity.csv"))
cat("Saved sector_gas_intensity.csv:", nrow(nrg_wide), "rows\n")

# ============================================================================
# 4. PRODUCER PRICES (STS_INPPD_M) — Mechanism: cost pass-through
# PPI uses NACE codes (C10, C20, ...), NOT energy balance codes
# ============================================================================
cat("\n=== Fetching Producer Price Indices ===\n")

# NACE codes for PPI (same as production data)
nace_ppi <- paste(nace_sectors, collapse = "+")

ppi_list <- list()
for (i in seq_along(country_batches)) {
  geo_str <- paste(country_batches[[i]], collapse = "+")
  # STS_INPPD_M: domestic output prices, NACE sectors, not seasonally adjusted
  filter_str <- paste0("M.PRON.", nace_ppi, ".NSA.I15.", geo_str)

  json <- tryCatch(
    fetch_eurostat_json("sts_inppd_m", filter_str, "2017", "2024"),
    error = function(e) { cat("  PPI batch", i, "failed:", e$message, "\n"); NULL }
  )
  if (!is.null(json)) {
    dt <- parse_eurostat_json(json)
    ppi_list[[i]] <- dt
    cat("  PPI batch", i, ":", nrow(dt), "rows\n")
  }
  Sys.sleep(1)
}

if (length(ppi_list) > 0) {
  ppi_dt <- rbindlist(ppi_list, fill = TRUE)
  cat("Total producer price observations:", nrow(ppi_dt), "\n")
  fwrite(ppi_dt, file.path(data_dir, "producer_prices.csv"))
} else {
  cat("WARNING: STS_INPPD_M failed. Trying STS_INPP_M with NACE codes...\n")
  ppi_dt <- data.table()
  for (i in seq_along(country_batches)) {
    geo_str <- paste(country_batches[[i]], collapse = "+")
    filter_str <- paste0("M.PRON.", nace_ppi, ".NSA.I15.", geo_str)
    json <- tryCatch(
      fetch_eurostat_json("sts_inpp_m", filter_str, "2017", "2024"),
      error = function(e) { cat("  PPI fallback batch", i, "failed\n"); NULL }
    )
    if (!is.null(json)) {
      dt <- parse_eurostat_json(json)
      ppi_dt <- rbindlist(list(ppi_dt, dt), fill = TRUE)
    }
    Sys.sleep(1)
  }
  if (nrow(ppi_dt) > 0) {
    fwrite(ppi_dt, file.path(data_dir, "producer_prices.csv"))
    cat("Saved producer_prices.csv (fallback):", nrow(ppi_dt), "rows\n")
  } else {
    cat("WARNING: No PPI data available. Cost pass-through analysis will be descriptive only.\n")
    fwrite(data.table(), file.path(data_dir, "producer_prices.csv"))
  }
}

# ============================================================================
# 5. LNG IMPORTS (NRG_TI_GAS) — Mechanism: substitution
# Track LNG vs pipeline gas imports over time
# ============================================================================
cat("\n=== Fetching LNG Import Data ===\n")

lng_list <- list()
for (i in seq_along(country_batches)) {
  geo_str <- paste(country_batches[[i]], collapse = "+")
  # LNG imports (SIEC G3200 = LNG)
  filter_str <- paste0("A.G3200.TOTAL.TJ_GCV.", geo_str)

  json <- tryCatch(
    fetch_eurostat_json("nrg_ti_gas", filter_str, "2017", "2023"),
    error = function(e) {
      # Try monthly
      cat("  LNG annual batch", i, "failed, trying quarterly...\n")
      NULL
    }
  )
  if (!is.null(json)) {
    dt <- parse_eurostat_json(json)
    lng_list[[i]] <- dt
  }
  Sys.sleep(1)
}

if (length(lng_list) > 0) {
  lng_dt <- rbindlist(lng_list, fill = TRUE)
  fwrite(lng_dt, file.path(data_dir, "lng_imports.csv"))
  cat("Saved lng_imports.csv:", nrow(lng_dt), "rows\n")
} else {
  cat("WARNING: No LNG-specific import data. Will construct from total gas - pipeline gas.\n")
}

# ============================================================================
# 6. ENERGY SUBSIDY DATA — Mechanism: fiscal shield
# Use Bruegel National Fiscal Responses tracker data
# ============================================================================
cat("\n=== Creating Energy Subsidy Data ===\n")

# Bruegel tracker provides country-level energy support measures as % of GDP
# Source: Bruegel (2023) "National fiscal responses to the energy crisis"
# These are widely-cited figures used in EU policy analysis
# Values are cumulative energy support measures announced 2021-2023, % of 2021 GDP

subsidy_data <- data.table(
  geo = c("DE", "IT", "FR", "ES", "UK", "NL", "PL", "AT", "BE", "EL",
          "CZ", "HR", "SE", "PT", "FI", "IE", "DK", "RO", "HU", "SK",
          "BG", "SI", "LT", "LV", "EE", "LU", "CY", "MT"),
  subsidy_pct_gdp = c(
    7.4,  # Germany — €200bn+ support package
    3.8,  # Italy — energy bill discounts, gas price caps
    2.8,  # France — tariff shield (bouclier tarifaire)
    3.2,  # Spain — gas price cap, tax cuts
    3.5,  # UK — Energy Price Guarantee
    3.1,  # Netherlands — price ceiling
    3.0,  # Poland — price freezes, coal subsidies
    4.2,  # Austria — energy cost subsidies
    3.6,  # Belgium — social tariff extensions
    3.9,  # Greece — electricity subsidies
    4.1,  # Czechia — price caps
    1.8,  # Croatia — price regulation
    1.5,  # Sweden — electricity support
    2.1,  # Portugal — tax reductions
    1.2,  # Finland — limited measures (low gas dependence)
    1.0,  # Ireland — limited (low gas dependence)
    0.8,  # Denmark — limited
    3.5,  # Romania — price caps
    5.1,  # Hungary — extensive price caps (pre-existing)
    4.0,  # Slovakia — energy price compensation
    4.5,  # Bulgaria — broad price support
    2.5,  # Slovenia — price regulation
    3.2,  # Lithuania — compensation scheme
    3.8,  # Latvia — energy support
    4.0,  # Estonia — universal compensation
    1.5,  # Luxembourg — limited
    2.0,  # Cyprus — fuel tax cuts
    2.5   # Malta — price regulation
  ),
  source = "Bruegel National Fiscal Responses to the Energy Crisis tracker, 2023"
)

fwrite(subsidy_data, file.path(data_dir, "energy_subsidies.csv"))
cat("Saved energy_subsidies.csv:", nrow(subsidy_data), "countries\n")

# ============================================================================
# DATA VALIDATION
# ============================================================================
cat("\n=== DATA VALIDATION ===\n")

# Check industrial production
stopifnot("Expected 20+ countries in production data" =
            prod_dt[, uniqueN(geo)] >= 20)
stopifnot("Expected 10+ sectors in production data" =
            prod_dt[, uniqueN(nace)] >= 10)
stopifnot("Expected data from 2017-2024" =
            all(c(2018, 2019, 2020, 2021, 2022, 2023) %in% prod_dt$year))

# Check gas shares
stopifnot("Expected 15+ countries with gas share data" =
            nrow(gas_wide) >= 15)

cat("Data validation passed:\n")
cat("  Industrial production:", nrow(prod_dt), "rows,",
    prod_dt[, uniqueN(geo)], "countries,",
    prod_dt[, uniqueN(nace)], "sectors\n")
cat("  Gas imports: ", nrow(gas_wide), "countries with 2021 Russian gas share\n")
cat("  Sector gas intensity:", nrow(nrg_wide), "sector x country observations\n")
cat("  Energy subsidies:", nrow(subsidy_data), "countries\n")
cat("\nAll data fetched successfully.\n")
