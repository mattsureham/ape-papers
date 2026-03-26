## 01_fetch_data.R — Fetch monthly bilateral trade from UN Comtrade
## apep_0977: Korea-Japan boycott trade hysteresis
##
## Reporter: Japan (392)
## Partners: South Korea (410), China (156)
## Flow: Exports (X)
## Classification: HS (2-digit)
## Period: January 2018 – December 2023

source("00_packages.R")

COMTRADE_KEY <- Sys.getenv("COMTRADE_API_PRIMARY")
if (nchar(COMTRADE_KEY) == 0) {
  env_lines <- readLines("../../../../.env", warn = FALSE)
  key_line <- grep("^COMTRADE_API_PRIMARY=", env_lines, value = TRUE)
  if (length(key_line) > 0) {
    COMTRADE_KEY <- sub("^COMTRADE_API_PRIMARY=", "", key_line)
  }
}
stopifnot("Comtrade API key not found" = nchar(COMTRADE_KEY) > 0)
cat(sprintf("API key loaded (first 8 chars): %s...\n", substr(COMTRADE_KEY, 1, 8)))

## ── Helper: query Comtrade v4 subscription API ─────────────────────────────
fetch_comtrade <- function(reporter, partner, period,
                           flow = "X", api_key = COMTRADE_KEY) {
  # Comtrade v4 subscription endpoint: /data/v1/get/C/M/HS
  base_url <- "https://comtradeapi.un.org/data/v1/get/C/M/HS"

  req <- request(base_url) |>
    req_url_query(
      reporterCode = reporter,
      partnerCode = partner,
      period = period,
      flowCode = flow,
      cmdCode = "AG2"
    ) |>
    req_headers(
      `Ocp-Apim-Subscription-Key` = api_key
    ) |>
    req_retry(max_tries = 3, backoff = ~ 5) |>
    req_timeout(120)

  resp <- tryCatch(
    req_perform(req),
    error = function(e) {
      cat(sprintf("  API error: %s\n", e$message))
      return(NULL)
    }
  )

  if (is.null(resp)) return(NULL)

  body <- resp_body_json(resp)

  if (length(body$data) == 0) {
    warning(sprintf("No data for reporter=%s partner=%s period=%s", reporter, partner, period))
    return(NULL)
  }

  rows <- lapply(body$data, function(x) {
    tibble(
      period       = as.character(x$period %||% NA),
      reporter     = as.character(x$reporterCode %||% NA),
      reporter_desc = as.character(x$reporterDesc %||% NA),
      partner      = as.character(x$partnerCode %||% NA),
      partner_desc = as.character(x$partnerDesc %||% NA),
      flow         = as.character(x$flowCode %||% NA),
      cmd_code     = as.character(x$cmdCode %||% NA),
      cmd_desc     = as.character(x$cmdDesc %||% NA),
      trade_value  = as.numeric(x$primaryValue %||% NA),
      net_weight   = as.numeric(x$netWgt %||% NA),
      qty          = as.numeric(x$qty %||% NA)
    )
  })

  bind_rows(rows)
}

## ── Fetch all data ─────────────────────────────────────────────────────────
years <- 2018:2023
partners <- c("410", "156")  # Korea, China
partner_labels <- c("410" = "Korea", "156" = "China")

all_data <- list()
idx <- 1

for (yr in years) {
  for (pc in partners) {
    # Build period string for all 12 months
    periods <- paste0(yr, sprintf("%02d", 1:12))
    period_str <- paste(periods, collapse = ",")

    cat(sprintf("Fetching Japan -> %s, %d ... ", partner_labels[pc], yr))
    result <- fetch_comtrade(
      reporter = "392",
      partner  = pc,
      period   = period_str
    )
    if (!is.null(result) && nrow(result) > 0) {
      all_data[[idx]] <- result
      idx <- idx + 1
      cat(sprintf("%d rows\n", nrow(result)))
    } else {
      cat("0 rows (WARNING)\n")
    }
    Sys.sleep(2)  # Rate limit
  }
}

df_raw <- bind_rows(all_data)

## ── Validate ───────────────────────────────────────────────────────────────
stopifnot("No data fetched from Comtrade" = nrow(df_raw) > 0)

cat(sprintf("\nTotal rows fetched: %d\n", nrow(df_raw)))
cat(sprintf("Unique products: %d\n", n_distinct(df_raw$cmd_code)))
cat(sprintf("Unique periods: %d\n", n_distinct(df_raw$period)))
cat(sprintf("Partners: %s\n", paste(unique(df_raw$partner_desc), collapse = ", ")))

## ── Quick smoke test ───────────────────────────────────────────────────────
bev_korea <- df_raw |>
  filter(cmd_code == "22", partner == "410") |>
  arrange(period)

if (nrow(bev_korea) > 0) {
  bev_jun19 <- bev_korea |> filter(period == "201906") |> pull(trade_value)
  bev_sep19 <- bev_korea |> filter(period == "201909") |> pull(trade_value)
  if (length(bev_jun19) > 0 && length(bev_sep19) > 0) {
    cat(sprintf("\nSmoke test — Beverages (HS22) Japan->Korea:\n"))
    cat(sprintf("  Jun 2019: $%.1fM\n", bev_jun19 / 1e6))
    cat(sprintf("  Sep 2019: $%.1fM\n", bev_sep19 / 1e6))
    cat(sprintf("  Change: %.0f%%\n", (bev_sep19 / bev_jun19 - 1) * 100))
  }
}

## ── Save ───────────────────────────────────────────────────────────────────
saveRDS(df_raw, "../data/comtrade_raw.rds")
cat("\nSaved to data/comtrade_raw.rds\n")
