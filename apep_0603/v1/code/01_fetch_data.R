## 01_fetch_data.R — Fetch powiat-level data from GUS BDL API
## apep_0603: Local Fiscal Multiplier of Poland's Family 500+

source("00_packages.R")

## ------------------------------------------------------------------
## Helper: query BDL API with pagination
## ------------------------------------------------------------------
fetch_bdl <- function(var_id, unit_level = 5, years = 2010:2022,
                      page_size = 100) {
  base_url <- "https://bdl.stat.gov.pl/api/v1/data/by-variable"
  all_records <- list()
  page <- 0

  repeat {
    url <- paste0(base_url, "/", var_id,
                  "?unit-level=", unit_level,
                  paste0("&year=", years, collapse = ""),
                  "&lang=en&format=json",
                  "&page-size=", page_size,
                  "&page=", page)

    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) != 200) {
      stop("BDL API returned status ", httr::status_code(resp),
           " for variable ", var_id, " page ", page)
    }

    body <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"),
                               flatten = TRUE)

    if (is.null(body$results) || length(body$results) == 0) break

    all_records <- c(all_records, list(body$results))
    total_records <- body$totalRecords
    fetched <- (page + 1) * page_size

    cat(sprintf("  var %s: page %d — fetched %d / %d\n",
                var_id, page, min(fetched, total_records), total_records))

    if (fetched >= total_records) break
    page <- page + 1

    Sys.sleep(0.3)  # rate limiting
  }

  if (length(all_records) == 0) {
    stop("No data returned for variable ", var_id)
  }

  bind_rows(all_records)
}

## ------------------------------------------------------------------
## Reshape BDL results to long format
## ------------------------------------------------------------------
reshape_bdl <- function(raw, var_name) {
  out <- raw %>%
    select(id, name, values) %>%
    unnest(values) %>%
    rename(powiat_id = id, powiat_name = name,
           value = val) %>%
    mutate(year = as.integer(year),
           value = as.numeric(value),
           variable = var_name)
  out
}

## ------------------------------------------------------------------
## Variable mapping (all confirmed working at powiat level = 5)
## ------------------------------------------------------------------
## 60529: New business registrations per 10K population
## 60270: Registered unemployment rate (%)
## 59:    Live births (count)
## 58:    Marriages (count)
## 60569: Infant mortality per 1,000 live births
## 72305: Total population (persons) — from P2462 half-year subject
## ------------------------------------------------------------------

years <- 2010:2022

cat("Fetching new business registrations per 10K (var 60529)...\n")
raw_biz <- fetch_bdl(60529, unit_level = 5, years = years)
df_biz <- reshape_bdl(raw_biz, "new_biz_per10k")

cat("Fetching registered unemployment rate (var 60270)...\n")
raw_unemp <- fetch_bdl(60270, unit_level = 5, years = years)
df_unemp <- reshape_bdl(raw_unemp, "unemp_rate")

cat("Fetching live births (var 59)...\n")
raw_births <- fetch_bdl(59, unit_level = 5, years = years)
df_births <- reshape_bdl(raw_births, "births")

cat("Fetching marriages (var 58)...\n")
raw_marriages <- fetch_bdl(58, unit_level = 5, years = years)
df_marriages <- reshape_bdl(raw_marriages, "marriages")

cat("Fetching infant mortality per 1000 (var 60569)...\n")
raw_infmort <- fetch_bdl(60569, unit_level = 5, years = years)
df_infmort <- reshape_bdl(raw_infmort, "infant_mortality_per1k")

cat("Fetching total population (var 72305)...\n")
raw_pop <- fetch_bdl(72305, unit_level = 5, years = years)
df_pop <- reshape_bdl(raw_pop, "population")

## ------------------------------------------------------------------
## Combine and save
## ------------------------------------------------------------------
df_all <- bind_rows(df_biz, df_unemp, df_births, df_marriages,
                    df_infmort, df_pop)

# Validate
n_powiats <- n_distinct(df_all$powiat_id)
n_years <- n_distinct(df_all$year)
cat(sprintf("\nData summary: %d unique powiats, %d years\n",
            n_powiats, n_years))

stopifnot("Must have at least 300 powiats" = n_powiats >= 300)
stopifnot("Must have at least 10 years" = n_years >= 10)

write_csv(df_all, "../data/bdl_raw.csv")
cat("Raw data saved to data/bdl_raw.csv\n")

# Summary stats
df_all %>%
  group_by(variable) %>%
  summarise(
    n_obs = sum(!is.na(value)),
    n_powiats = n_distinct(powiat_id),
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    min = min(value, na.rm = TRUE),
    max = max(value, na.rm = TRUE)
  ) %>%
  print()
