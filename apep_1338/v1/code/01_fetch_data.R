## 01_fetch_data.R — Fetch UK bilateral trade data from UN Comtrade API
## apep_1338: Brexit Rules of Origin and Trade Disintegration
##
## Data: UN Comtrade HS, reporter = UK (826),
##       partners = EU27 + 5 non-EU controls, commodity level = HS4

## Run from paper root: Rscript code/01_fetch_data.R
source("code/00_packages.R")

comtrade_key <- Sys.getenv("COMTRADE_API_PRIMARY")
if (comtrade_key == "") stop("COMTRADE_API_PRIMARY not set in .env")

dir.create("data", showWarnings = FALSE)

## ── Helper: query Comtrade Plus API ──────────────────────────────────────────

fetch_comtrade <- function(year, flow_code, partner_codes, reporter = "826") {
  base_url <- "https://comtradeapi.un.org/data/v1/get/C/A/HS"
  partners_str <- paste(partner_codes, collapse = ",")

  req <- httr2::request(base_url) |>
    httr2::req_url_query(
      reporterCode  = reporter,
      period        = as.character(year),
      partnerCode   = partners_str,
      flowCode      = flow_code,
      cmdCode       = "AG4"
    ) |>
    httr2::req_headers(
      `Ocp-Apim-Subscription-Key` = comtrade_key
    ) |>
    httr2::req_timeout(120) |>
    httr2::req_retry(max_tries = 3, backoff = ~ 10)

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cat("  ERROR:", conditionMessage(e), "\n")
      return(NULL)
    }
  )
  if (is.null(resp)) return(NULL)
  if (httr2::resp_status(resp) != 200) {
    cat("  HTTP", httr2::resp_status(resp), "\n")
    return(NULL)
  }
  body <- httr2::resp_body_json(resp, simplifyVector = TRUE)
  if (is.null(body$data) || length(body$data) == 0) {
    cat("  No data\n")
    return(NULL)
  }
  df <- as.data.frame(body$data)
  cat("  ->", nrow(df), "rows,", n_distinct(df$partnerCode), "partners\n")
  return(df)
}

## ── Partner codes ───────────────────────────────────────────────────────────

# Top EU partners (split into batches to avoid API row limits)
eu_batch1 <- c(276, 250, 380, 528, 56, 724, 616)   # DE, FR, IT, NL, BE, ES, PL
eu_batch2 <- c(372, 203, 752, 40, 208, 642, 300)    # IE, CZ, SE, AT, DK, RO, GR
eu_batch3 <- c(348, 246, 620, 100, 705, 703, 440)   # HU, FI, PT, BG, SI, SK, LT
eu_batch4 <- c(428, 233, 196, 191, 442, 470)        # LV, EE, CY, HR, LU, MT

# Non-EU control partners
controls <- c(842, 124, 392, 410, 36)  # US, CA, JP, KR, AU

years <- 2017:2024
flows <- c("M", "X")

all_data <- list()
idx <- 1

for (yr in years) {
  for (fl in flows) {
    for (batch_name in c("eu1", "eu2", "eu3", "eu4", "ctrl")) {
      batch <- switch(batch_name,
        eu1 = eu_batch1, eu2 = eu_batch2,
        eu3 = eu_batch3, eu4 = eu_batch4,
        ctrl = controls
      )
      cat(sprintf("Fetching %s %d [%s] ... ", fl, yr, batch_name))
      df <- fetch_comtrade(yr, fl, batch)
      if (!is.null(df)) {
        all_data[[idx]] <- df
        idx <- idx + 1
      }
      Sys.sleep(1.2)
    }
  }
}

if (length(all_data) == 0) stop("FATAL: No data fetched from Comtrade. Cannot proceed.")

raw <- bind_rows(all_data)
cat("\n========================================\n")
cat("Total rows fetched:", nrow(raw), "\n")
cat("Years covered:", paste(sort(unique(raw$period)), collapse = ", "), "\n")
cat("Unique HS4 codes:", n_distinct(raw$cmdCode), "\n")
cat("Unique partners:", n_distinct(raw$partnerCode), "\n")

## ── Validate ────────────────────────────────────────────────────────────────

eu27_codes <- c(eu_batch1, eu_batch2, eu_batch3, eu_batch4)
eu_rows <- raw |> filter(partnerCode %in% eu27_codes)
ctrl_rows <- raw |> filter(partnerCode %in% controls)

cat("\nEU27 rows:", nrow(eu_rows), "\n")
cat("Control rows:", nrow(ctrl_rows), "\n")

if (nrow(eu_rows) == 0) stop("FATAL: No EU27 partner data found")
if (nrow(ctrl_rows) == 0) stop("FATAL: No control partner data found")

## ── Save ────────────────────────────────────────────────────────────────────

saveRDS(raw, "data/comtrade_uk_hs4_raw.rds")
cat("Saved data/comtrade_uk_hs4_raw.rds\n")
cat("Data fetch complete.\n")
