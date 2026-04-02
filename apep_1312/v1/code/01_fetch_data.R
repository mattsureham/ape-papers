# 01_fetch_data.R — Fetch wage data from Statistics North Macedonia PXWeb API
# REAL DATA ONLY — no simulated fallbacks

source("00_packages.R")

cat("=== Fetching gross wage data from makstat.stat.gov.mk ===\n")

# --- Gross wages (table 125) ---
url_gross <- "https://makstat.stat.gov.mk/PXWeb/api/v1/en/MakStat/PazarNaTrud/Plati/MesecnaBrutoNeto/125_PazTrud_Mk_bruto_ml.px"

meta_resp <- GET(url_gross)
stopifnot("API metadata request failed" = meta_resp$status_code == 200)
meta <- content(meta_resp, as = "parsed")

# Build lookup maps from metadata
sector_vals <- unlist(meta$variables[[1]]$values)
sector_texts <- unlist(meta$variables[[1]]$valueTexts)
sector_map <- setNames(sector_texts, sector_vals)

month_vals <- unlist(meta$variables[[2]]$values)
month_texts <- unlist(meta$variables[[2]]$valueTexts)
month_map <- setNames(month_texts, month_vals)

cat(sprintf("Available: %d sectors x %d months\n", length(sector_vals), length(month_vals)))

# POST query for all data
query_body <- list(
  query = list(
    list(code = meta$variables[[1]]$code,
         selection = list(filter = "all", values = list("*"))),
    list(code = meta$variables[[2]]$code,
         selection = list(filter = "all", values = list("*")))
  ),
  response = list(format = "json")
)

resp_gross <- POST(url_gross,
                   body = toJSON(query_body, auto_unbox = TRUE),
                   content_type_json(),
                   timeout(120))
stopifnot("Gross wage API request failed" = resp_gross$status_code == 200)

data_gross <- content(resp_gross, as = "parsed")
stopifnot("No data returned from gross wage API" = length(data_gross$data) > 0)

cat(sprintf("Gross wage data: %d observations returned\n", length(data_gross$data)))

# Parse into data.table using lookup maps
parse_pxweb <- function(data_list, s_map, m_map, value_name) {
  rows <- lapply(data_list, function(x) {
    data.table(
      sector_code = x$key[[1]],
      sector = s_map[x$key[[1]]],
      month_str = m_map[x$key[[2]]],
      value = as.numeric(x$values[[1]])
    )
  })
  dt <- rbindlist(rows)
  setnames(dt, "value", value_name)
  return(dt)
}

dt_gross <- parse_pxweb(data_gross$data, sector_map, month_map, "gross_wage")

# --- Net wages (table 175) ---
cat("\n=== Fetching net wage data ===\n")
url_net <- "https://makstat.stat.gov.mk/PXWeb/api/v1/en/MakStat/PazarNaTrud/Plati/MesecnaBrutoNeto/175_PazTrud_Mk_neto_ml.px"

meta_net_resp <- GET(url_net)
stopifnot("Net wage API metadata request failed" = meta_net_resp$status_code == 200)
meta_net <- content(meta_net_resp, as = "parsed")

# Build net wage lookup maps
sector_vals_n <- unlist(meta_net$variables[[1]]$values)
sector_texts_n <- unlist(meta_net$variables[[1]]$valueTexts)
sector_map_n <- setNames(sector_texts_n, sector_vals_n)

month_vals_n <- unlist(meta_net$variables[[2]]$values)
month_texts_n <- unlist(meta_net$variables[[2]]$valueTexts)
month_map_n <- setNames(month_texts_n, month_vals_n)

query_net <- list(
  query = list(
    list(code = meta_net$variables[[1]]$code,
         selection = list(filter = "all", values = list("*"))),
    list(code = meta_net$variables[[2]]$code,
         selection = list(filter = "all", values = list("*")))
  ),
  response = list(format = "json")
)

resp_net <- POST(url_net,
                 body = toJSON(query_net, auto_unbox = TRUE),
                 content_type_json(),
                 timeout(120))
stopifnot("Net wage API request failed" = resp_net$status_code == 200)

data_net <- content(resp_net, as = "parsed")
stopifnot("No data returned from net wage API" = length(data_net$data) > 0)

cat(sprintf("Net wage data: %d observations returned\n", length(data_net$data)))

dt_net <- parse_pxweb(data_net$data, sector_map_n, month_map_n, "net_wage")

# --- Merge ---
dt <- merge(dt_gross, dt_net[, .(sector, month_str, net_wage)],
            by = c("sector", "month_str"), all = TRUE)

# Parse month_str (format: "2019M01") — handle both Latin M and Cyrillic М
dt[, month_str_clean := gsub("\u041c", "M", month_str)]  # Cyrillic М → Latin M
dt[, year := as.integer(sub("M.*", "", month_str_clean))]
dt[, month := as.integer(sub(".*M", "", month_str_clean))]
dt[, date := as.IDate(paste0(year, "-", sprintf("%02d", month), "-01"))]
dt[, time := year + (month - 1) / 12]

# Remove "Total" sector
dt <- dt[!grepl("^Total", sector, ignore.case = TRUE)]

# Clean sector names — extract NACE letter code
dt[, nace := sub("^\\(([A-Z])\\).*", "\\1", sector)]
dt[, sector_short := sub("^\\([A-Z]\\) ", "", sector)]

# Sort
setorder(dt, sector, date)

cat(sprintf("\nFinal dataset: %d observations, %d sectors, %d months\n",
            nrow(dt), uniqueN(dt$sector), uniqueN(dt$month_str)))
cat(sprintf("Date range: %s to %s\n", min(dt$date), max(dt$date)))
cat(sprintf("NACE sectors: %s\n", paste(unique(dt$nace), collapse = ", ")))

# Validate: no excessive NAs
na_pct <- sum(is.na(dt$gross_wage)) / nrow(dt)
stopifnot("Too many missing gross wages" = na_pct < 0.05)
cat(sprintf("Missing gross wages: %.1f%%\n", na_pct * 100))

# Save
fwrite(dt, "../data/wages_raw.csv")
cat("\nSaved to data/wages_raw.csv\n")
