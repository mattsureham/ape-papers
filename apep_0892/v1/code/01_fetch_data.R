# 01_fetch_data.R — Data acquisition for apep_0892
# Moldova Wine Embargo: Nightlights + Trade Data

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ═══════════════════════════════════════════════════════════════════════
# STEP 1: Fetch EOAtlas VIIRS Nightlights for All 37 Moldova Admin1 Units
# ═══════════════════════════════════════════════════════════════════════
cat("=== STEP 1: Fetch EOAtlas VIIRS Nightlights ===\n")

nightlights_file <- file.path(data_dir, "nightlights_moldova.csv")

if (!file.exists(nightlights_file)) {
  # EOAtlas nightlight data on AWS S3
  # URL pattern: https://eoatlas-nightlight.s3.amazonaws.com/eoatlas-monthly-nightlight-XXXXX.csv
  # Moldova admin1 shape IDs: 02187-02223 (confirmed via scan)
  base_url <- "https://eoatlas-nightlight.s3.amazonaws.com/eoatlas-monthly-nightlight-"

  # All 37 Moldova admin1 (raion) shape IDs
  shape_ids <- sprintf("%05d", 2187:2223)

  all_data <- list()

  for (sid in shape_ids) {
    url <- paste0(base_url, sid, ".csv")
    resp <- tryCatch({
      req <- httr2::request(url) |>
        httr2::req_timeout(30) |>
        httr2::req_error(is_error = function(resp) FALSE)
      httr2::req_perform(req)
    }, error = function(e) {
      cat("  ERROR downloading", sid, ":", e$message, "\n")
      NULL
    })

    if (!is.null(resp) && httr2::resp_status(resp) == 200) {
      d <- readr::read_csv(httr2::resp_body_string(resp), show_col_types = FALSE)
      d$shape_id <- sid
      all_data[[sid]] <- d
      cat("  ", sid, ":", unique(d$shapeName), "-", nrow(d), "rows\n")
    } else {
      stop(paste("FATAL: Failed to download shape", sid, "- cannot proceed without real data"))
    }
    Sys.sleep(0.3)
  }

  nightlights <- data.table::rbindlist(all_data)
  readr::write_csv(nightlights, nightlights_file)
  cat("\nSaved", nrow(nightlights), "rows across", length(all_data), "raions\n")
} else {
  cat("Nightlights data already cached.\n")
}

nightlights <- data.table::fread(nightlights_file)
cat("\nNightlights data summary:\n")
cat("  Raions:", length(unique(nightlights$shapeName)), "\n")
cat("  Months:", length(unique(paste(nightlights$year, nightlights$month))), "\n")
cat("  Total rows:", nrow(nightlights), "\n")
cat("  Year range:", min(nightlights$year), "-", max(nightlights$year), "\n")
cat("  Mean radiance range:", round(min(nightlights$mean, na.rm = TRUE), 3),
    "-", round(max(nightlights$mean, na.rm = TRUE), 3), "\n")

# Validation
stopifnot(nrow(nightlights) > 0)
stopifnot(length(unique(nightlights$shapeName)) == 37)
cat("  VALIDATED: 37 raions with real nightlights data\n")

# ═══════════════════════════════════════════════════════════════════════
# STEP 2: Fetch UN Comtrade Wine Export Data
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== STEP 2: Fetch UN Comtrade Wine Export Data ===\n")

comtrade_file <- file.path(data_dir, "comtrade_wine.csv")

if (!file.exists(comtrade_file)) {
  cat("Fetching Moldova wine exports from UN Comtrade API...\n")

  # UN Comtrade public preview API (no API key needed)
  # HS code 2204 = Wine of fresh grapes
  # Reporter: Moldova (498)
  # Partners: World (0), Russia (643), EU key markets
  years <- 2010:2023

  all_trade <- list()

  for (yr in years) {
    url <- paste0(
      "https://comtradeapi.un.org/public/v1/preview/C/A/HS?",
      "reporterCode=498",
      "&period=", yr,
      "&cmdCode=2204",
      "&flowCode=X",
      "&partnerCode=0,643,276,380,826,616,642"  # World, Russia, Germany, Italy, UK, Poland, Romania
    )

    resp <- tryCatch({
      req <- httr2::request(url) |>
        httr2::req_timeout(30) |>
        httr2::req_error(is_error = function(resp) FALSE)
      httr2::req_perform(req)
    }, error = function(e) {
      cat("  Comtrade error for", yr, ":", e$message, "\n")
      NULL
    })

    if (!is.null(resp) && httr2::resp_status(resp) == 200) {
      body <- httr2::resp_body_json(resp)
      if (length(body$data) > 0) {
        rows <- lapply(body$data, function(x) {
          data.frame(
            year = as.integer(x$period %||% yr),
            reporter = x$reporterDesc %||% "Moldova",
            partner = x$partnerDesc %||% NA_character_,
            partner_code = as.integer(x$partnerCode %||% NA),
            trade_value = as.numeric(x$primaryValue %||% NA),
            net_weight = as.numeric(x$netWgt %||% NA),
            stringsAsFactors = FALSE
          )
        })
        all_trade[[as.character(yr)]] <- data.table::rbindlist(rows)
        cat("  ", yr, ":", length(rows), "partner records\n")
      } else {
        cat("  ", yr, ": no data\n")
      }
    } else {
      status <- if (!is.null(resp)) httr2::resp_status(resp) else "NULL"
      cat("  ", yr, ": failed (HTTP", status, ")\n")
    }
    Sys.sleep(1.5)  # Rate limit
  }

  if (length(all_trade) > 0) {
    trade_data <- data.table::rbindlist(all_trade, fill = TRUE)
    readr::write_csv(trade_data, comtrade_file)
    cat("Saved", nrow(trade_data), "trade records\n")
  } else {
    stop("FATAL: Cannot access UN Comtrade API. Need real trade data.")
  }
} else {
  cat("Comtrade data already cached.\n")
}

trade_data <- data.table::fread(comtrade_file)
cat("\nTrade data summary:\n")
cat("  Years:", min(trade_data$year), "-", max(trade_data$year), "\n")
cat("  Partners:", paste(unique(trade_data$partner), collapse = ", "), "\n")
cat("  Total records:", nrow(trade_data), "\n")

# Show Russia trade collapse
russia_trade <- trade_data[partner_code == 643, .(year, trade_value)]
if (nrow(russia_trade) > 0) {
  cat("\nMoldova wine exports to Russia ($):\n")
  print(russia_trade[order(year)])
}

cat("\n=== Data Acquisition Complete ===\n")
