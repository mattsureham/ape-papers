## 01_fetch_data.R — Fetch UN Comtrade bilateral trade data for EUDR commodities
## Uses Comtrade v1 API — fetches by destination groups to get bilateral flows

source("code/00_packages.R")

cat("=== FETCHING UN COMTRADE BILATERAL TRADE DATA ===\n")

comtrade_key <- Sys.getenv("COMTRADE_API_PRIMARY")
if (nchar(comtrade_key) == 0) stop("COMTRADE_API_PRIMARY not set in .env")

base_url <- "https://comtradeapi.un.org/data/v1/get/C/A/HS"

# ── Commodity definitions ──────────────────────────────────────────
regulated_hs <- c("0102", "0901", "1201", "1511", "1801", "4001", "4403")
control_hs <- c("0902", "0904", "1513", "2009", "2401")
all_hs <- c(regulated_hs, control_hs)

# ── Exporters ──────────────────────────────────────────────────────
exporters <- c(76, 360, 170, 384, 458, 328, 288, 704, 716)

# ── Destination groups ─────────────────────────────────────────────
# EU-27 country codes
eu27 <- c(40, 56, 100, 191, 196, 203, 208, 233, 246, 251, 276, 300,
          348, 372, 380, 428, 440, 442, 470, 528, 616, 620, 642,
          703, 705, 724, 752)
china <- 156
# World total for computing shares
world <- 0

years <- 2018:2024

# ── Fetch function ─────────────────────────────────────────────────
fetch_batch <- function(reporter, cmd_codes, periods, partner_codes, max_retries = 5) {
  cmd_str <- paste(cmd_codes, collapse = ",")
  period_str <- paste(periods, collapse = ",")
  partner_str <- paste(partner_codes, collapse = ",")

  url <- paste0(base_url,
                "?reporterCode=", reporter,
                "&period=", period_str,
                "&cmdCode=", cmd_str,
                "&flowCode=X",
                "&partnerCode=", partner_str,
                "&partner2Code=0",
                "&includeDesc=TRUE")

  for (attempt in 1:max_retries) {
    tryCatch({
      resp <- httr2::request(url) |>
        httr2::req_headers(`Ocp-Apim-Subscription-Key` = comtrade_key) |>
        httr2::req_timeout(120) |>
        httr2::req_perform()

      status <- httr2::resp_status(resp)
      if (status == 200) {
        json <- httr2::resp_body_json(resp)
        if (length(json$data) == 0) return(NULL)
        dt <- rbindlist(lapply(json$data, function(x) {
          as.data.table(lapply(x, function(v) if (is.null(v)) NA else v))
        }), fill = TRUE)
        return(dt)
      } else if (status == 429) {
        wait <- min(2^attempt + 2, 30)
        cat(sprintf("    Rate limited (attempt %d), waiting %ds...\n", attempt, wait))
        Sys.sleep(wait)
      } else {
        cat(sprintf("    HTTP %d (attempt %d)\n", status, attempt))
        Sys.sleep(3)
      }
    }, error = function(e) {
      cat(sprintf("    Error (attempt %d): %s\n", attempt, e$message))
      Sys.sleep(3)
    })
  }
  return(NULL)
}

# ── Strategy: For each exporter, fetch 3 destination groups ────────
# 1. World total (partner=0)
# 2. China (partner=156)
# 3. EU-27 (partner=comma-separated EU codes, may need splitting)

results <- list()

for (rep in exporters) {
  cat(sprintf("\n--- Exporter %d ---\n", rep))

  # World total
  cat("  World total...")
  dt_world <- fetch_batch(rep, all_hs, years, world)
  if (!is.null(dt_world)) {
    dt_world[, dest_group := "World"]
    results[[length(results) + 1]] <- dt_world
    cat(sprintf(" %d records\n", nrow(dt_world)))
  } else {
    cat(" failed\n")
  }
  Sys.sleep(3)

  # China
  cat("  China...")
  dt_china <- fetch_batch(rep, all_hs, years, china)
  if (!is.null(dt_china)) {
    dt_china[, dest_group := "China"]
    results[[length(results) + 1]] <- dt_china
    cat(sprintf(" %d records\n", nrow(dt_china)))
  } else {
    cat(" 0 records\n")
  }
  Sys.sleep(3)

  # EU-27 — split into two batches to avoid URL length limits
  eu_batch1 <- eu27[1:14]
  eu_batch2 <- eu27[15:27]

  cat("  EU batch 1...")
  dt_eu1 <- fetch_batch(rep, all_hs, years, eu_batch1)
  if (!is.null(dt_eu1)) {
    dt_eu1[, dest_group := "EU-27"]
    results[[length(results) + 1]] <- dt_eu1
    cat(sprintf(" %d records\n", nrow(dt_eu1)))
  } else {
    cat(" 0 records\n")
  }
  Sys.sleep(3)

  cat("  EU batch 2...")
  dt_eu2 <- fetch_batch(rep, all_hs, years, eu_batch2)
  if (!is.null(dt_eu2)) {
    dt_eu2[, dest_group := "EU-27"]
    results[[length(results) + 1]] <- dt_eu2
    cat(sprintf(" %d records\n", nrow(dt_eu2)))
  } else {
    cat(" 0 records\n")
  }
  Sys.sleep(3)
}

cat(sprintf("\n=== Fetched %d result batches ===\n", length(results)))

if (length(results) == 0) {
  stop("FATAL: No data fetched from Comtrade. Cannot proceed.")
}

raw <- rbindlist(results, fill = TRUE)

keep_cols <- c("period", "reporterCode", "reporterDesc",
               "partnerCode", "partnerDesc",
               "cmdCode", "cmdDesc",
               "flowCode", "primaryValue", "netWgt", "qty", "dest_group")
keep_cols <- intersect(keep_cols, names(raw))
raw <- raw[, ..keep_cols]

cat(sprintf("Raw dataset: %d rows\n", nrow(raw)))
cat(sprintf("Dest groups: %s\n", paste(unique(raw$dest_group), collapse = ", ")))
cat(sprintf("Exporters: %d\n", uniqueN(raw$reporterCode)))
cat(sprintf("Commodities: %d\n", uniqueN(raw$cmdCode)))

fwrite(raw, "data/comtrade_raw.csv")
cat("Saved data/comtrade_raw.csv\n")
