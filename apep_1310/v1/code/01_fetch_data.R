# 01_fetch_data.R — Fetch ILO and Eurostat data
# APEP-1310: The Compression Shock

source("00_packages.R")

# ── Helper: fetch ILO STAT API ──────────────────────────────────
fetch_ilo <- function(indicator, ref_areas, max_retries = 3) {
  all_data <- list()
  for (area in ref_areas) {
    url <- paste0(
      "https://rplumber.ilo.org/data/indicator/",
      "?id=", indicator,
      "&ref_area=", area,
      "&format=.csv"
    )
    cat("Fetching ILO:", indicator, "for", area, "...\n")
    for (attempt in 1:max_retries) {
      resp <- tryCatch(
        httr::GET(url, httr::timeout(60)),
        error = function(e) NULL
      )
      if (!is.null(resp) && httr::status_code(resp) == 200) break
      Sys.sleep(2 * attempt)
    }
    if (is.null(resp) || httr::status_code(resp) != 200) {
      stop("FATAL: ILO API failed for ", area, " indicator ", indicator,
           ". Status: ", ifelse(is.null(resp), "NULL", httr::status_code(resp)))
    }
    raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    df <- read.csv(textConnection(raw_text), stringsAsFactors = FALSE)
    df$ref_area_fetched <- area
    all_data[[area]] <- df
  }
  bind_rows(all_data)
}

# ── Fetch employment data ───────────────────────────────────────
countries <- c("LTU", "LVA", "EST")

emp_raw <- fetch_ilo("EMP_TEMP_SEX_ECO_NB_A", countries)
cat("Employment rows fetched:", nrow(emp_raw), "\n")
stopifnot(nrow(emp_raw) > 0)

# ── Fetch wage data ─────────────────────────────────────────────
wage_raw <- fetch_ilo("EAR_4MTH_SEX_ECO_CUR_NB_A", countries)
cat("Wage rows fetched:", nrow(wage_raw), "\n")
stopifnot(nrow(wage_raw) > 0)

# ── Fetch Eurostat minimum wages ────────────────────────────────
cat("Fetching Eurostat minimum wages...\n")
euro_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/",
  "earn_mw_cur/?format=JSON&geo=LT,LV,EE&startPeriod=2010&endPeriod=2023"
)
euro_resp <- httr::GET(euro_url, httr::timeout(60))
if (httr::status_code(euro_resp) != 200) {
  stop("FATAL: Eurostat API failed. Status: ", httr::status_code(euro_resp))
}
euro_json <- httr::content(euro_resp, as = "text", encoding = "UTF-8")
euro_parsed <- fromJSON(euro_json)

# Parse Eurostat JSON-stat format
obs_values <- euro_parsed$value
dim_ids <- euro_parsed$id
dim_sizes <- euro_parsed$size

# Build dimension labels
geo_labels <- euro_parsed$dimension$geo$category$label
time_labels <- euro_parsed$dimension$time$category$label
currency_labels <- euro_parsed$dimension$currency$category$label

geo_idx <- euro_parsed$dimension$geo$category$index
time_idx <- euro_parsed$dimension$time$category$index
currency_idx <- euro_parsed$dimension$currency$category$index

# Reconstruct the flat index
mw_rows <- list()
for (obs_key in names(obs_values)) {
  idx <- as.integer(obs_key)
  # Determine dimension indices from flat key
  n_dims <- length(dim_sizes)
  dim_indices <- integer(n_dims)
  remainder <- idx
  for (d in n_dims:1) {
    dim_indices[d] <- remainder %% dim_sizes[d]
    remainder <- remainder %/% dim_sizes[d]
  }

  # Map indices to labels
  geo_name <- names(geo_idx)[match(dim_indices[which(dim_ids == "geo")], geo_idx)]
  time_name <- names(time_idx)[match(dim_indices[which(dim_ids == "time")], time_idx)]
  curr_name <- names(currency_idx)[match(dim_indices[which(dim_ids == "currency")], currency_idx)]

  mw_rows[[length(mw_rows) + 1]] <- data.frame(
    geo = geo_name,
    time = time_name,
    currency = curr_name,
    mw_value = as.numeric(obs_values[[obs_key]]),
    stringsAsFactors = FALSE
  )
}
mw_raw <- bind_rows(mw_rows)
cat("Eurostat MW rows:", nrow(mw_raw), "\n")
stopifnot(nrow(mw_raw) > 0)

# ── Save raw data ───────────────────────────────────────────────
saveRDS(emp_raw, "../data/emp_raw.rds")
saveRDS(wage_raw, "../data/wage_raw.rds")
saveRDS(mw_raw, "../data/mw_raw.rds")

cat("Raw data saved to data/\n")
cat("  Employment:", nrow(emp_raw), "rows\n")
cat("  Wages:", nrow(wage_raw), "rows\n")
cat("  Minimum wages:", nrow(mw_raw), "rows\n")
