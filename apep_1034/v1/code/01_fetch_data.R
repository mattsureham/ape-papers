## 01_fetch_data.R — Fetch data from Statistics Norway (SSB) PxWeb API
## apep_1034: Norway Wind Resource Rent Tax

source("00_packages.R")

# ============================================================
# SSB PxWeb API helper
# ============================================================
ssb_fetch <- function(table_id, query_body, lang = "en") {
  url <- sprintf("https://data.ssb.no/api/v0/%s/table/%s", lang, table_id)
  resp <- httr::POST(
    url,
    body = query_body,
    encode = "json",
    httr::content_type_json(),
    httr::timeout(120)
  )
  if (httr::status_code(resp) != 200) {
    stop(sprintf("SSB API error for table %s: HTTP %d\n%s",
                 table_id, httr::status_code(resp),
                 httr::content(resp, "text", encoding = "UTF-8")))
  }
  raw <- httr::content(resp, "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)
  return(parsed)
}

# ============================================================
# Helper: parse JSON-stat format from SSB
# ============================================================
parse_jsonstat <- function(parsed) {
  dims <- parsed$dimension
  dim_ids <- parsed$id
  dim_sizes <- parsed$size
  values <- parsed$value

  # Build index grid
  indices <- expand.grid(lapply(rev(dim_sizes), seq_len), KEEP.OUT.ATTRS = FALSE)
  indices <- indices[, rev(seq_along(indices))]
  names(indices) <- dim_ids

  # Map indices to labels
  result <- data.frame(value = unlist(values), stringsAsFactors = FALSE)
  for (d in dim_ids) {
    cats <- dims[[d]]$category
    codes <- names(cats$index)
    # Sort by index position
    idx_positions <- unlist(cats$index)
    code_order <- codes[order(idx_positions)]
    label_list <- cats$label
    labels <- unlist(label_list[code_order])

    result[[paste0(d, "_code")]] <- code_order[indices[[d]]]
    result[[paste0(d, "_label")]] <- labels[indices[[d]]]
  }
  return(as_tibble(result))
}

# ============================================================
# 1. SSB Table 08308: Annual electricity production by type and county
# ============================================================
cat("Fetching SSB Table 08308 (annual electricity by type/county)...\n")

query_08308 <- list(
  query = list(
    list(code = "Region", selection = list(filter = "item", values = list("Ialt"))),
    list(code = "ContentsCode", selection = list(filter = "item", values = list("VannKraft", "VindKraft"))),
    list(code = "Tid", selection = list(filter = "item",
      values = as.list(as.character(2010:2024))))
  ),
  response = list(format = "json-stat2")
)

raw_08308 <- ssb_fetch("08308", query_08308)
df_annual <- parse_jsonstat(raw_08308)

cat(sprintf("  Fetched %d rows from Table 08308\n", nrow(df_annual)))

# Clean annual data
annual <- df_annual %>%
  rename(
    region_code = Region_code,
    region = Region_label,
    variable_code = ContentsCode_code,
    variable = ContentsCode_label,
    year_code = Tid_code,
    year_label = Tid_label,
    gwh = value
  ) %>%
  mutate(
    year = as.integer(year_code),
    sector = ifelse(variable_code == "VindKraft", "wind", "hydro"),
    gwh = as.numeric(gwh)
  ) %>%
  select(region_code, region, sector, year, gwh)

cat("  Annual data summary:\n")
annual %>%
  group_by(sector, year) %>%
  summarise(total_gwh = sum(gwh, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = sector, values_from = total_gwh) %>%
  print(n = 20)

# ============================================================
# 2. SSB Table 08308: Now fetch county-level data
# ============================================================
cat("\nFetching county-level data from Table 08308...\n")

# First get all available regions
# Use current county codes (2024+ boundaries) plus legacy codes
county_codes <- list("03", "11", "15", "18", "42", "46", "50",
                     "31", "32", "33", "34", "39", "40", "55", "56")

query_county <- list(
  query = list(
    list(code = "Region", selection = list(filter = "item", values = county_codes)),
    list(code = "ContentsCode", selection = list(filter = "item", values = list("VannKraft", "VindKraft"))),
    list(code = "Tid", selection = list(filter = "item",
      values = as.list(as.character(2010:2024))))
  ),
  response = list(format = "json-stat2")
)

raw_county <- ssb_fetch("08308", query_county)
df_county <- parse_jsonstat(raw_county)

county <- df_county %>%
  rename(
    region_code = Region_code,
    region = Region_label,
    variable_code = ContentsCode_code,
    variable = ContentsCode_label,
    year_code = Tid_code,
    year_label = Tid_label,
    gwh = value
  ) %>%
  mutate(
    year = as.integer(year_code),
    sector = ifelse(variable_code == "VindKraft", "wind", "hydro"),
    gwh = as.numeric(gwh)
  ) %>%
  select(region_code, region, sector, year, gwh) %>%
  filter(!is.na(gwh))

cat(sprintf("  Fetched %d county-year-sector obs\n", nrow(county)))

# Show which counties have wind production
wind_counties <- county %>%
  filter(sector == "wind", gwh > 0) %>%
  distinct(region_code, region)
cat(sprintf("  Counties with wind production: %d\n", nrow(wind_counties)))
print(wind_counties)

# ============================================================
# 3. SSB Table 14091: Monthly electricity by type (national)
# ============================================================
cat("\nFetching SSB Table 14091 (monthly electricity)...\n")

# Build month list: 2018M01 through 2024M12
months <- c()
for (y in 2018:2024) {
  for (m in 1:12) {
    months <- c(months, sprintf("%dM%02d", y, m))
  }
}

query_14091 <- list(
  query = list(
    list(code = "Produk2", selection = list(filter = "item", values = list("1.1", "1.2"))),
    list(code = "ContentsCode", selection = list(filter = "item", values = list("Kraft"))),
    list(code = "Tid", selection = list(filter = "item", values = as.list(months)))
  ),
  response = list(format = "json-stat2")
)

raw_14091 <- ssb_fetch("14091", query_14091)
df_monthly <- parse_jsonstat(raw_14091)

monthly <- df_monthly %>%
  rename(
    source_code = Produk2_code,
    source_label = Produk2_label,
    content_code = ContentsCode_code,
    content_label = ContentsCode_label,
    time_code = Tid_code,
    time_label = Tid_label,
    mwh = value
  ) %>%
  mutate(
    sector = case_when(
      source_code == "1.1" ~ "hydro",
      source_code == "1.2" ~ "wind",
      TRUE ~ "other"
    ),
    year = as.integer(substr(time_code, 1, 4)),
    month = as.integer(substr(time_code, 6, 7)),
    mwh = as.numeric(mwh),
    gwh = mwh / 1000,
    date = as.Date(sprintf("%d-%02d-01", year, month))
  ) %>%
  filter(!is.na(mwh)) %>%
  select(sector, year, month, date, mwh, gwh)

cat(sprintf("  Fetched %d monthly observations\n", nrow(monthly)))

# Show annual totals from monthly data
monthly %>%
  group_by(sector, year) %>%
  summarise(annual_gwh = sum(gwh, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = sector, values_from = annual_gwh) %>%
  print(n = 10)

# ============================================================
# 4. Eurostat: Sweden and Denmark monthly wind production (placebo countries)
# ============================================================
cat("\nFetching Eurostat data for placebo countries (SE, DK)...\n")

eurostat_fetch <- function(dataset, params) {
  base_url <- sprintf("https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/%s", dataset)
  resp <- httr::GET(base_url, query = params, httr::timeout(120))
  if (httr::status_code(resp) != 200) {
    warning(sprintf("Eurostat API error: HTTP %d", httr::status_code(resp)))
    return(NULL)
  }
  raw <- httr::content(resp, "text", encoding = "UTF-8")
  jsonlite::fromJSON(raw)
}

# nrg_cb_pem: Monthly electricity production by fuel type
euro_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nrg_cb_pem",
  "?geo=NO&geo=SE&geo=DK&siec=RA110&siec=RA300&unit=GWH&freq=M",
  "&sinceTimePeriod=2018-01&untilTimePeriod=2024-12"
)
euro_resp <- httr::GET(euro_url, httr::timeout(120))

if (httr::status_code(euro_resp) == 200) {
  euro_raw <- jsonlite::fromJSON(httr::content(euro_resp, "text", encoding = "UTF-8"))

  # Parse JSON-stat2 format: dimensions are freq, siec, unit, geo, time
  dim_ids <- euro_raw$id      # e.g., c("freq", "siec", "unit", "geo", "time")
  dim_sizes <- euro_raw$size  # e.g., c(1, 2, 1, 3, 84)

  # Get ordered category labels for each dimension
  get_ordered_cats <- function(dim_name) {
    cats <- euro_raw$dimension[[dim_name]]$category
    codes <- names(cats$index)
    idx <- unlist(cats$index)
    codes[order(idx)]
  }

  dim_cats <- lapply(dim_ids, get_ordered_cats)
  names(dim_cats) <- dim_ids

  # Build full grid: JSON-stat2 is row-major (last dim varies fastest)
  # expand.grid makes first arg vary fastest, so pass dims in reverse order
  grid_args <- lapply(rev(dim_sizes), seq_len)
  names(grid_args) <- rev(dim_ids)
  grid <- do.call(expand.grid, c(grid_args, list(KEEP.OUT.ATTRS = FALSE)))
  # Reorder columns to match dim_ids
  grid <- grid[, dim_ids]

  # Map sparse values
  vals <- rep(NA_real_, nrow(grid))
  for (nm in names(euro_raw$value)) {
    idx <- as.integer(nm) + 1
    if (idx <= length(vals)) vals[idx] <- euro_raw$value[[nm]]
  }

  eurostat_df <- tibble(
    country = dim_cats$geo[grid$geo],
    fuel = dim_cats$siec[grid$siec],
    unit = dim_cats$unit[grid$unit],
    time_str = dim_cats$time[grid$time],
    gwh = vals
  ) %>%
    filter(unit == "GWH") %>%
    mutate(
      sector = case_when(
        fuel == "RA110" ~ "hydro",
        fuel == "RA300" ~ "wind",
        TRUE ~ "other"
      ),
      year = as.integer(substr(time_str, 1, 4)),
      month = as.integer(substr(time_str, 6, 7)),
      date = as.Date(sprintf("%d-%02d-01", year, month))
    ) %>%
    filter(!is.na(gwh)) %>%
    select(country, sector, year, month, date, gwh)

  cat(sprintf("  Fetched %d Eurostat monthly observations\n", nrow(eurostat_df)))

  eurostat_df %>%
    group_by(country, sector, year) %>%
    summarise(annual_gwh = sum(gwh, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = c(sector), values_from = annual_gwh) %>%
    arrange(country, year) %>%
    print(n = 30)
} else {
  cat(sprintf("  WARNING: Eurostat fetch failed (HTTP %d). Proceeding without placebo countries.\n",
              httr::status_code(euro_resp)))
  eurostat_df <- tibble(
    country = character(), sector = character(), year = integer(),
    month = integer(), date = as.Date(character()), gwh = numeric()
  )
}

# ============================================================
# Save all datasets
# ============================================================
saveRDS(annual, "../data/annual_production.rds")
saveRDS(county, "../data/county_production.rds")
saveRDS(monthly, "../data/monthly_production.rds")
saveRDS(eurostat_df, "../data/eurostat_production.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("Annual:   %d obs\n", nrow(annual)))
cat(sprintf("County:   %d obs\n", nrow(county)))
cat(sprintf("Monthly:  %d obs\n", nrow(monthly)))
cat(sprintf("Eurostat: %d obs\n", nrow(eurostat_df)))
