## 01_fetch_data.R — Fetch bilateral trade data from UN Comtrade API
## Paper: Carbon Border Deflection (apep_0788)
##
## Data: Monthly bilateral imports, HS 2-digit, 2020-2024
## Source: UN Comtrade Plus API (https://comtradeapi.un.org)

source("00_packages.R")

# --- Load .env ---
env_file <- normalizePath("../../../../.env", mustWork = FALSE)
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub("^['\"]|['\"]$", "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

# --- Configuration ---
COMTRADE_KEY <- Sys.getenv("COMTRADE_API_PRIMARY")
if (nchar(COMTRADE_KEY) == 0) {
  COMTRADE_KEY <- Sys.getenv("COMTRADE_API_SECONDARY")
}
if (nchar(COMTRADE_KEY) == 0) stop("COMTRADE_API_PRIMARY not set in .env")

BASE_URL <- "https://comtradeapi.un.org/data/v1/get/C/M/HS"

# Importer ISO3 numeric codes (we query from importer side)
importers <- c(
  "EU27_2020" = "97",   # EU-27 aggregate
  "USA"       = "842",
  "JPN"       = "392",
  "GBR"       = "826"
)

# Exporter ISO3 numeric codes
exporters <- c(
  "CHN" = "156",  # China
  "IND" = "356",  # India
  "TUR" = "792",  # Turkey
  "RUS" = "643",  # Russia
  "UKR" = "804",  # Ukraine
  "VNM" = "704",  # Vietnam
  "TWN" = "490",  # Taiwan ("Other Asia, nes")
  "BRA" = "076"   # Brazil
)

# HS codes: 72 (iron/steel, covered), 73 (articles, uncovered), 76 (aluminum, covered)
hs_codes <- c("72", "73", "76")

# --- Fetch function ---
fetch_comtrade <- function(reporter_code, partner_codes, cmd_codes, year) {
  # Build period string for all months in the year
  periods <- sprintf("%d%02d", year, 1:12)
  period_str <- paste(periods, collapse = ",")
  partner_str <- paste(partner_codes, collapse = ",")
  cmd_str <- paste(cmd_codes, collapse = ",")

  resp <- request(BASE_URL) |>
    req_url_query(
      reporterCode = reporter_code,
      partnerCode  = partner_str,
      cmdCode      = cmd_str,
      flowCode     = "M",
      period       = period_str,
      includeDesc  = "TRUE"
    ) |>
    req_headers(`Ocp-Apim-Subscription-Key` = COMTRADE_KEY) |>
    req_retry(max_tries = 3, backoff = ~ 5) |>
    req_timeout(120) |>
    req_perform()

  if (resp_status(resp) != 200) {
    stop(sprintf("API returned status %d for reporter %s, year %d",
                 resp_status(resp), reporter_code, year))
  }

  body <- resp_body_json(resp)

  if (length(body$data) == 0) {
    warning(sprintf("No data for reporter %s, year %d", reporter_code, year))
    return(NULL)
  }

  # Convert to data frame
  records <- lapply(body$data, function(x) {
    tibble(
      period       = as.character(x$period %||% NA),
      reporter_code = as.character(x$reporterCode %||% NA),
      reporter_desc = as.character(x$reporterDesc %||% NA),
      partner_code  = as.character(x$partnerCode %||% NA),
      partner_desc  = as.character(x$partnerDesc %||% NA),
      cmd_code      = as.character(x$cmdCode %||% NA),
      cmd_desc      = as.character(x$cmdDesc %||% NA),
      flow_code     = as.character(x$flowCode %||% NA),
      primary_value = as.numeric(x$primaryValue %||% NA),
      net_wgt       = as.numeric(x$netWgt %||% NA),
      qty           = as.numeric(x$qty %||% NA)
    )
  })
  bind_rows(records)
}

# --- Main data collection ---
cat("Fetching UN Comtrade bilateral trade data...\n")
cat("Importers:", paste(names(importers), collapse = ", "), "\n")
cat("Exporters:", paste(names(exporters), collapse = ", "), "\n")
cat("HS codes:", paste(hs_codes, collapse = ", "), "\n")
cat("Years: 2020-2024\n\n")

all_data <- list()
exporter_str <- paste(exporters, collapse = ",")
years <- 2020:2024

for (imp_name in names(importers)) {
  imp_code <- importers[imp_name]
  for (yr in years) {
    cat(sprintf("  Fetching: %s imports from 8 exporters, year %d...\n", imp_name, yr))
    tryCatch({
      result <- fetch_comtrade(imp_code, exporters, hs_codes, yr)
      if (!is.null(result) && nrow(result) > 0) {
        result$importer <- imp_name
        all_data[[paste(imp_name, yr)]] <- result
        cat(sprintf("    -> %d records\n", nrow(result)))
      } else {
        cat(sprintf("    -> 0 records (empty)\n"))
      }
    }, error = function(e) {
      cat(sprintf("    -> ERROR: %s\n", e$message))
      # Do NOT silently continue — flag it
      warning(sprintf("Failed to fetch %s/%d: %s", imp_name, yr, e$message))
    })
    Sys.sleep(1.5)  # Rate limiting
  }
}

# Combine all data
if (length(all_data) == 0) {
  stop("FATAL: No data fetched from Comtrade API. Cannot proceed with simulated data.")
}

trade_raw <- bind_rows(all_data)
cat(sprintf("\nTotal records fetched: %d\n", nrow(trade_raw)))

# Check coverage
cat("\nCoverage check:\n")
cat("  Periods:", length(unique(trade_raw$period)), "\n")
cat("  Importers:", length(unique(trade_raw$importer)), "\n")
cat("  Exporters:", length(unique(trade_raw$partner_desc)), "\n")
cat("  Products:", length(unique(trade_raw$cmd_code)), "\n")

# If EU-27 aggregate is empty, try fetching top 5 EU importers individually
eu_records <- trade_raw |> filter(importer == "EU27_2020")
if (nrow(eu_records) == 0) {
  cat("\nWARNING: EU-27 aggregate not available. Fetching top 5 EU importers...\n")
  eu_countries <- c("DEU" = "276", "FRA" = "251", "ITA" = "381",
                     "NLD" = "528", "ESP" = "724", "BEL" = "056",
                     "POL" = "616", "AUT" = "040", "CZE" = "203",
                     "SWE" = "752")

  eu_data <- list()
  for (eu_name in names(eu_countries)) {
    eu_code <- eu_countries[eu_name]
    for (yr in years) {
      cat(sprintf("  Fetching: %s imports, year %d...\n", eu_name, yr))
      tryCatch({
        result <- fetch_comtrade(eu_code, exporters, hs_codes, yr)
        if (!is.null(result) && nrow(result) > 0) {
          result$importer <- "EU27_2020"
          result$eu_member <- eu_name
          eu_data[[paste(eu_name, yr)]] <- result
          cat(sprintf("    -> %d records\n", nrow(result)))
        }
      }, error = function(e) {
        cat(sprintf("    -> ERROR: %s\n", e$message))
        warning(sprintf("Failed to fetch %s/%d: %s", eu_name, yr, e$message))
      })
      Sys.sleep(1.5)
    }
  }

  if (length(eu_data) > 0) {
    eu_combined <- bind_rows(eu_data)
    # Aggregate to EU level
    eu_agg <- eu_combined |>
      group_by(period, partner_code, partner_desc, cmd_code, cmd_desc,
               flow_code, importer) |>
      summarise(
        primary_value = sum(primary_value, na.rm = TRUE),
        net_wgt = sum(net_wgt, na.rm = TRUE),
        qty = sum(qty, na.rm = TRUE),
        reporter_code = "97",
        reporter_desc = "EU-27",
        .groups = "drop"
      )
    trade_raw <- bind_rows(
      trade_raw |> filter(importer != "EU27_2020"),
      eu_agg
    )
    cat(sprintf("EU aggregate added: %d records\n", nrow(eu_agg)))
  } else {
    stop("FATAL: Cannot fetch EU import data. Cannot proceed.")
  }
}

# Save raw data
saveRDS(trade_raw, "../data/trade_raw.rds")
cat(sprintf("\nRaw data saved: data/trade_raw.rds (%d rows)\n", nrow(trade_raw)))

# Validate: must have data for all 4 destinations
destinations_present <- unique(trade_raw$importer)
required_dests <- c("EU27_2020", "USA", "JPN", "GBR")
missing <- setdiff(required_dests, destinations_present)
if (length(missing) > 0) {
  stop(sprintf("FATAL: Missing destinations: %s", paste(missing, collapse = ", ")))
}

cat("\nData fetch complete. All 4 destinations present.\n")
