## 01_fetch_data.R — Fetch data from Statistics Denmark StatBank API
## apep_1395: Denmark Renovation Arbitrage Ban

source("00_packages.R")

# ---- Helper: StatBank API query ----
fetch_statbank <- function(table_id, variables, lang = "en") {
  url <- "https://api.statbank.dk/v1/data"
  body <- list(
    table = table_id,
    format = "BULK",
    lang = lang,
    variables = variables
  )
  resp <- POST(url, body = toJSON(body, auto_unbox = TRUE),
               content_type_json(), encode = "raw")
  if (status_code(resp) != 200) {
    stop(sprintf("StatBank API error for %s: HTTP %d\n%s",
                 table_id, status_code(resp), content(resp, "text")))
  }
  text <- content(resp, "text", encoding = "UTF-8")
  df <- read_delim(text, delim = ";", show_col_types = FALSE)
  cat(sprintf("  %s: %d rows fetched\n", table_id, nrow(df)))
  return(df)
}

# ---- 1. Building permits (BYGV11) — quarterly, municipality-level ----
cat("Fetching BYGV11 (building permits)...\n")
# Fetch residential building types only, total across builder types
# ANVEND: 110=farmhouses, 120=detached, 130=row/terraced, 140=multi-storey, 150=halls of residence, 160=other residential
residential_codes <- c("110", "120", "130", "140", "150", "160", "190")
bygv11 <- fetch_statbank("BYGV11", list(
  list(code = "OMRÅDE", values = list("*")),      # all municipalities
  list(code = "BYGFASE", values = list("1")),     # permitted construction
  list(code = "ANVEND", values = residential_codes),
  list(code = "BYGHERRE", values = list("10", "20", "30")),  # private, social housing, companies
  list(code = "Tid", values = list("*"))           # all quarters
))

saveRDS(bygv11, "../data/bygv11_raw.rds")

# ---- 2. Dwelling stock (BOL101) — annual, municipality-level ----
cat("Fetching BOL101 (dwelling stock)...\n")
bol101 <- fetch_statbank("BOL101", list(
  list(code = "OMRÅDE", values = list("*")),          # all municipalities
  list(code = "BEBO", values = list("1000")),          # occupied dwellings
  list(code = "ANVENDELSE", values = list("*")),      # all dwelling types
  list(code = "UDLFORH", values = list("*")),         # all tenancy types
  list(code = "EJER", values = list("*")),            # all ownership types
  list(code = "OPFØRELSESÅR", values = list("*")),    # all construction years
  list(code = "Tid", values = list("*"))              # all years
))

saveRDS(bol101, "../data/bol101_raw.rds")

# ---- 3. Property sales aggregate (EJ131) — monthly, region-level ----
cat("Fetching EJ131 (property sales)...\n")
ej131 <- fetch_statbank("EJ131", list(
  list(code = "REGION", values = list("*")),
  list(code = "EJENDOMSKATE", values = list("*")),
  list(code = "BNØGLE", values = list("*")),
  list(code = "Tid", values = list("*"))
))

saveRDS(ej131, "../data/ej131_raw.rds")

# ---- 4. BOL106 — dwelling stock simplified ----
cat("Fetching BOL106 (dwelling stock simplified)...\n")
bol106 <- fetch_statbank("BOL106", list(
  list(code = "OMRÅDE", values = list("*")),
  list(code = "ENHED", values = list("*")),
  list(code = "ANVENDELSE", values = list("*")),
  list(code = "Tid", values = list("*"))
))

saveRDS(bol106, "../data/bol106_raw.rds")

cat("\nAll data fetched successfully.\n")
cat(sprintf("BYGV11: %d rows\n", nrow(bygv11)))
cat(sprintf("BOL101: %d rows\n", nrow(bol101)))
cat(sprintf("EJ131:  %d rows\n", nrow(ej131)))
cat(sprintf("BOL106: %d rows\n", nrow(bol106)))
