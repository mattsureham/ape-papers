## 01_fetch_data.R — Fetch FRA crossing inventory and accident data
## apep_1186: Railroad Quiet Zones and Crossing Safety

source("00_packages.R")
options(scipen = 999)  # Prevent scientific notation in URLs

## ---------------------------------------------------------------
## Helper: paginated Socrata fetch (with retry)
## ---------------------------------------------------------------
fetch_socrata <- function(base_url, limit = 50000, params = "",
                          max_retries = 3) {
  all_rows <- list()
  offset <- 0
  repeat {
    url <- paste0(base_url, "?$limit=", limit, "&$offset=", offset)
    if (nchar(params) > 0) url <- paste0(url, "&", params)
    cat("Fetching offset", offset, "...\n")
    resp <- NULL
    for (attempt in seq_len(max_retries)) {
      resp <- tryCatch(
        httr::GET(url, httr::timeout(180)),
        error = function(e) {
          cat("  Connection error (attempt", attempt, "):", conditionMessage(e), "\n")
          Sys.sleep(5 * attempt)
          NULL
        }
      )
      if (!is.null(resp)) break
    }
    if (is.null(resp)) stop("Failed after ", max_retries, " retries at offset ", offset)
    if (httr::status_code(resp) != 200) {
      stop("API returned status ", httr::status_code(resp), ": ",
           httr::content(resp, "text", encoding = "UTF-8"))
    }
    txt <- httr::content(resp, "text", encoding = "UTF-8")
    chunk <- jsonlite::fromJSON(txt, flatten = TRUE)
    if (is.null(chunk) || nrow(chunk) == 0) break
    all_rows[[length(all_rows) + 1]] <- as.data.table(chunk)
    cat("  Got", nrow(chunk), "rows\n")
    offset <- offset + limit
    if (nrow(chunk) < limit) break
    Sys.sleep(1)
  }
  rbindlist(all_rows, fill = TRUE)
}

## ---------------------------------------------------------------
## 1. FRA Highway-Rail Crossing Inventory (Form 71 — Current)
##    Dataset: m2f8-22s6
## ---------------------------------------------------------------
cat("=== Fetching FRA Crossing Inventory (Current) ===\n")

inv_select <- URLencode(paste(
  "crossingid", "statecode", "statename", "countycode", "countyname",
  "crossingtypecode", "crossingpositioncode",
  "whistleban", "whistlebancode", "whistledate",
  "annualaveragedailytrafficcount",
  "totaldaylightthrutrains", "totalnighttimethrutrains",
  "totalswitchingtrains", "numberpassengertrainperday",
  "maximumtimetablespeed",
  "crossingsurfaceid1",
  "countroadwaygatearms",
  "highwaytrafficsignal",
  "latitude", "longitude",
  "trafficlane",
  "crossingonstatehighwaysystem",
  "crossingclosed",
  sep = ","
))

inventory <- fetch_socrata(
  "https://data.transportation.gov/resource/m2f8-22s6.json",
  params = paste0("$select=", inv_select)
)

cat("Inventory rows:", nrow(inventory), "\n")
stopifnot("crossingid" %in% names(inventory))
stopifnot(nrow(inventory) > 100000)

## ---------------------------------------------------------------
## 2. FRA Accident/Incident Data (Form 57)
##    Dataset: icqf-xf4w
## ---------------------------------------------------------------
cat("\n=== Fetching FRA Accident Data (Form 57) ===\n")

acc_select <- URLencode(paste(
  "gxid", "year4", "month", "day",
  "totkld", "totinj", "totocc",
  "userkld", "userinj",
  "typacc", "typveh", "warnsig",
  "visiblty", "weather",
  "trnspd", "vehspd",
  "public", "state",
  sep = ","
))

accidents <- fetch_socrata(
  "https://data.transportation.gov/resource/icqf-xf4w.json",
  params = paste0("$select=", acc_select)
)

cat("Accident rows:", nrow(accidents), "\n")
stopifnot("gxid" %in% names(accidents))
stopifnot(nrow(accidents) > 50000)

## ---------------------------------------------------------------
## 3. Save raw data
## ---------------------------------------------------------------
fwrite(inventory, "../data/fra_inventory_raw.csv")
fwrite(accidents, "../data/fra_accidents_raw.csv")

cat("\n=== Data fetch complete ===\n")
cat("  Inventory:", nrow(inventory), "crossings\n")
cat("  Accidents:", nrow(accidents), "records\n")
cat("  Quiet zone crossings (24hr):", sum(inventory$whistleban == "24 hr", na.rm = TRUE), "\n")
