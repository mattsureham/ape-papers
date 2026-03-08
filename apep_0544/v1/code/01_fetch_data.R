## =============================================================
## 01_fetch_data.R — Fetch all data from Eurostat APIs
## apep_0544: Russian Gas Shock and European Manufacturing
## =============================================================

source("00_packages.R")

cat("=== FETCHING DATA FROM EUROSTAT ===\n")

## -----------------------------------------------------------------
## Helper: Find column by matching values
## -----------------------------------------------------------------
find_col <- function(dt, vals) {
  for (cn in names(dt)) {
    if (any(dt[[cn]] %in% vals)) return(cn)
  }
  return(NULL)
}

## -----------------------------------------------------------------
## Helper: Query Eurostat SDMX/JSON API
## -----------------------------------------------------------------
fetch_eurostat <- function(dataset, filter, start_period = "2015-01",
                           end_period = "2024-12") {
  base_url <- "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data"
  url <- paste0(base_url, "/", dataset, "/", filter,
                "?startPeriod=", start_period,
                "&endPeriod=", end_period,
                "&format=JSON")
  cat("  Fetching:", dataset, "...\n")
  resp <- GET(url, timeout(120))
  if (status_code(resp) != 200) {
    stop("Eurostat API returned status ", status_code(resp), " for ", dataset,
         "\nURL: ", url)
  }
  content(resp, as = "text", encoding = "UTF-8")
}

## -----------------------------------------------------------------
## Helper: Parse Eurostat JSON-stat to data.table
## -----------------------------------------------------------------
parse_eurostat_json <- function(json_text) {
  js <- fromJSON(json_text, simplifyVector = FALSE)

  dims <- js$dimension
  dim_ids <- unlist(js$id)
  dim_sizes <- unlist(js$size)

  # Build dimension labels
  dim_labels <- lapply(dim_ids, function(d) {
    cats <- dims[[d]]$category
    idx <- cats$index
    lab <- cats$label
    if (is.list(idx)) idx <- unlist(idx)
    if (is.list(lab)) lab <- unlist(lab)
    # Sort by index position
    ord <- order(idx)
    data.table(code = names(idx)[ord], label = unlist(lab[names(idx)[ord]]))
  })
  names(dim_labels) <- dim_ids

  # Build grid
  grid <- do.call(CJ, lapply(dim_labels, function(x) x$code))
  setnames(grid, dim_ids)

  # Values
  vals <- js$value
  if (is.list(vals)) {
    # Sparse format: named list with string indices
    val_vec <- rep(NA_real_, nrow(grid))
    idx_names <- names(vals)
    for (i in seq_along(vals)) {
      pos <- as.integer(idx_names[i]) + 1L  # 0-indexed
      val_vec[pos] <- as.numeric(vals[[i]])
    }
  } else {
    val_vec <- as.numeric(unlist(vals))
  }
  grid[, value := val_vec]

  # Add labels
  for (d in dim_ids) {
    lbl <- dim_labels[[d]]
    grid[, paste0(d, "_label") := lbl$label[match(get(d), lbl$code)]]
  }

  grid[!is.na(value)]
}

## -----------------------------------------------------------------
## 1. Industrial Production (STS_INPR_M)
## Monthly, seasonally + calendar adjusted, index 2015=100
## All NACE C manufacturing 2-digit sectors
## -----------------------------------------------------------------

# EU countries + Norway, Switzerland, UK, Turkey
geos <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
           "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
           "NL", "PL", "PT", "RO", "SE", "SI", "SK", "NO", "CH", "UK", "TR")

# NACE Rev.2 manufacturing 2-digit codes
nace_codes <- c("C10", "C11", "C13", "C14", "C15", "C16", "C17", "C18",
                "C20", "C21", "C22", "C23", "C24", "C25", "C26", "C27",
                "C28", "C29", "C30", "C31", "C32", "C33")

# Build filter: M.PRD.{sectors}.SCA.I15.{countries}
sector_str <- paste(nace_codes, collapse = "+")
geo_str <- paste(geos, collapse = "+")

ip_json <- fetch_eurostat(
  "sts_inpr_m",
  paste0("M.PRD.", sector_str, ".SCA.I15.", geo_str),
  start_period = "2015-01",
  end_period = "2024-12"
)
ip_dt <- parse_eurostat_json(ip_json)
# The parsed result already has dimension IDs as column names
# Identify key columns dynamically
cat("  IP columns:", paste(names(ip_dt), collapse = ", "), "\n")

# Identify geo and nace columns
ip_geo_col <- find_col(ip_dt, c("DE", "FR", "IT"))
ip_nace_col <- find_col(ip_dt, c("C20", "C24", "C10"))
ip_time_col <- NULL
for (cn in names(ip_dt)) {
  if (any(grepl("^2020-", ip_dt[[cn]]))) { ip_time_col <- cn; break }
}

cat("  IP dimension columns: geo=", ip_geo_col, ", nace=", ip_nace_col,
    ", time=", ip_time_col, "\n")

# Standardize column names
if (!is.null(ip_geo_col) && ip_geo_col != "geo")
  setnames(ip_dt, ip_geo_col, "geo")
if (!is.null(ip_nace_col) && ip_nace_col != "nace_r2")
  setnames(ip_dt, ip_nace_col, "nace_r2")
if (!is.null(ip_time_col) && ip_time_col != "time")
  setnames(ip_dt, ip_time_col, "time")

cat("  Industrial production:", nrow(ip_dt), "rows,",
    uniqueN(ip_dt$geo), "countries,",
    uniqueN(ip_dt$nace_r2), "sectors\n")

fwrite(ip_dt, file.path(DATA_DIR, "industrial_production.csv"))

## -----------------------------------------------------------------
## 2. Russian Gas Imports by Country (NRG_TI_GAS)
## Annual, TJ gross calorific value
## Partner = Russia (RU) + TOTAL
## -----------------------------------------------------------------

# Query in batches to avoid 400 errors from long URLs
batch1 <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES")
batch2 <- c("FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT")
batch3 <- c("NL", "PL", "PT", "RO", "SE", "SI", "SK", "NO", "TR")

gas_ru_list <- list()
gas_total_list <- list()
for (batch in list(batch1, batch2, batch3)) {
  bstr <- paste(batch, collapse = "+")
  json_ru <- fetch_eurostat("nrg_ti_gas",
    paste0("A.G3000.RU.TJ_GCV.", bstr), "2015", "2023")
  gas_ru_list[[length(gas_ru_list) + 1]] <- parse_eurostat_json(json_ru)

  json_total <- fetch_eurostat("nrg_ti_gas",
    paste0("A.G3000.TOTAL.TJ_GCV.", bstr), "2015", "2023")
  gas_total_list[[length(gas_total_list) + 1]] <- parse_eurostat_json(json_total)
}
gas_ru <- rbindlist(gas_ru_list, fill = TRUE)
gas_total <- rbindlist(gas_total_list, fill = TRUE)

# Merge and compute Russian share
geo_col_ru <- find_col(gas_ru, c("DE", "FR", "IT"))
time_col_ru <- find_col(gas_ru, c("2021", "2020", "2019"))

gas_ru[, ru_imports_tj := value]
gas_total[, total_imports_tj := value]

geo_col_tot <- find_col(gas_total, c("DE", "FR", "IT"))
time_col_tot <- find_col(gas_total, c("2021", "2020", "2019"))

cat("  Gas import columns: geo=", geo_col_ru, ", time=", time_col_ru, "\n")

gas_share <- merge(
  gas_ru[, .SD, .SDcols = c(geo_col_ru, time_col_ru, "ru_imports_tj")],
  gas_total[, .SD, .SDcols = c(geo_col_tot, time_col_tot, "total_imports_tj")],
  by.x = c(geo_col_ru, time_col_ru),
  by.y = c(geo_col_tot, time_col_tot),
  all = TRUE
)
setnames(gas_share, c(geo_col_ru, time_col_ru), c("geo", "time"))
gas_share[, russian_gas_share := fifelse(total_imports_tj > 0,
                                          ru_imports_tj / total_imports_tj, 0)]
gas_share[is.na(russian_gas_share), russian_gas_share := 0]

cat("  Gas imports:", nrow(gas_share), "rows,",
    uniqueN(gas_share$geo), "countries\n")

fwrite(gas_share, file.path(DATA_DIR, "gas_imports.csv"))

## -----------------------------------------------------------------
## 3. Sector Gas Consumption (NRG_BAL_C)
## Final energy consumption by industry sector, natural gas
## We need to map NRG_BAL energy sector codes to NACE 2-digit
## -----------------------------------------------------------------

# NRG_BAL sector codes for manufacturing sub-sectors
# These map to groups of NACE 2-digit codes
nrg_sectors <- c(
  "FC_IND_IS_E",    # Iron & steel (C24 part)
  "FC_IND_CPC_E",   # Chemical & petrochemical (C20)
  "FC_IND_NFM_E",   # Non-ferrous metals (C24 part)
  "FC_IND_NMM_E",   # Non-metallic minerals (C23)
  "FC_IND_TE_E",    # Transport equipment (C29+C30)
  "FC_IND_MAC_E",   # Machinery (C28)
  "FC_IND_MQ_E",    # Mining & quarrying (not manufacturing)
  "FC_IND_FBT_E",   # Food, beverages, tobacco (C10+C11)
  "FC_IND_PPP_E",   # Paper, pulp, printing (C17+C18)
  "FC_IND_WP_E",    # Wood & wood products (C16)
  "FC_IND_CON_E",   # Construction
  "FC_IND_TL_E",    # Textile & leather (C13+C14+C15)
  "FC_IND_NSP_E"    # Not elsewhere specified
)
nrg_str <- paste(nrg_sectors, collapse = "+")

# Get data for all countries, natural gas (G3000), in TJ — batch by country
gas_cons_list <- list()
total_cons_list <- list()
for (batch in list(batch1, batch2, batch3)) {
  bstr <- paste(batch, collapse = "+")
  gc_json <- fetch_eurostat("nrg_bal_c",
    paste0("A.", nrg_str, ".G3000.TJ.", bstr), "2015", "2021")
  gas_cons_list[[length(gas_cons_list) + 1]] <- parse_eurostat_json(gc_json)

  tc_json <- fetch_eurostat("nrg_bal_c",
    paste0("A.", nrg_str, ".TOTAL.TJ.", bstr), "2015", "2021")
  total_cons_list[[length(total_cons_list) + 1]] <- parse_eurostat_json(tc_json)
}
gas_cons <- rbindlist(gas_cons_list, fill = TRUE)
total_cons <- rbindlist(total_cons_list, fill = TRUE)

# Compute gas intensity = gas / total energy by sector-country
gas_cons[, gas_tj := value]
total_cons[, total_tj := value]

# Use the NRG_BAL dimension names from the parsed data
# Find the column that contains the sector codes
nrg_cols <- names(gas_cons)
cat("  Gas consumption columns:", paste(nrg_cols, collapse = ", "), "\n")

fwrite(gas_cons, file.path(DATA_DIR, "sector_gas_consumption.csv"))
fwrite(total_cons, file.path(DATA_DIR, "sector_total_consumption.csv"))

cat("  Sector energy:", nrow(gas_cons), "gas rows,",
    nrow(total_cons), "total rows\n")

## -----------------------------------------------------------------
## 4. Producer Prices (STS_INPPD_M) — Domestic output prices
## Monthly, NACE sectors, for mechanism test
## -----------------------------------------------------------------

pp_list <- list()
for (batch in list(batch1, batch2, batch3)) {
  bstr <- paste(batch, collapse = "+")
  pp_json <- tryCatch({
    fetch_eurostat("sts_inpp_m",
      paste0("M.PRC_PRR.", sector_str, ".NSA.I15.", bstr),
      "2015-01", "2024-12")
  }, error = function(e) {
    cat("  Warning: producer prices batch failed:", e$message, "\n")
    NULL
  })
  if (!is.null(pp_json)) {
    pp_list[[length(pp_list) + 1]] <- parse_eurostat_json(pp_json)
  }
}
pp_dt <- if (length(pp_list) > 0) rbindlist(pp_list, fill = TRUE) else data.table()
cat("  Producer prices:", nrow(pp_dt), "rows\n")
fwrite(pp_dt, file.path(DATA_DIR, "producer_prices.csv"))

## -----------------------------------------------------------------
## 5. Summary and Validation
## -----------------------------------------------------------------

cat("\n=== DATA VALIDATION ===\n")

# Industrial production
n_geo <- uniqueN(ip_dt$geo)
n_nace <- uniqueN(ip_dt$nace_r2)
n_time <- uniqueN(ip_dt$time)
stopifnot("Industrial production: need 15+ countries" = n_geo >= 15)
stopifnot("Industrial production: need 10+ sectors" = n_nace >= 10)
stopifnot("Industrial production: need 50+ months" = n_time >= 50)
cat("Industrial production: PASSED —",
    nrow(ip_dt), "rows,", n_geo, "countries,",
    n_nace, "sectors,", n_time, "months\n")

# Gas imports
n_geo_gas <- uniqueN(gas_share$geo)
stopifnot("Gas imports: need 10+ countries" = n_geo_gas >= 10)
gas_2021 <- gas_share[time == "2021"]
cat("Gas imports (2021):", nrow(gas_2021), "countries with data\n")
cat("  Russian share range:",
    round(min(gas_2021$russian_gas_share, na.rm = TRUE), 3), "to",
    round(max(gas_2021$russian_gas_share, na.rm = TRUE), 3), "\n")

# Producer prices
if (nrow(pp_dt) > 0) {
  cat("Producer prices: PASSED —", nrow(pp_dt), "rows\n")
} else {
  cat("Producer prices: WARNING — no data fetched, will use production data only\n")
}

cat("\n=== ALL DATA FETCHED SUCCESSFULLY ===\n")
