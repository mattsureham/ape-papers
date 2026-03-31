## 01e_fetch_acs.R — Fetch ACS county demographics
## apep_1190

source("00_packages.R")
data_dir <- "../data"
census_key <- Sys.getenv("CENSUS_API_KEY")

cat("=== Fetching ACS county demographics ===\n")

acs_years <- c(2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022)
acs_list <- list()

for (yr in acs_years) {
  cat(sprintf("  ACS 5-year %d...\n", yr))

  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=B19013_001E,B17001_002E,B01003_001E,NAME&for=county:*&in=state:*&key=%s",
    yr, census_key
  )

  resp <- tryCatch(httr::GET(url, httr::timeout(45)), error = function(e) NULL)

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    df <- as.data.frame(raw[-1, ], stringsAsFactors = FALSE)
    names(df) <- raw[1, ]
    df$acs_year <- yr
    acs_list[[as.character(yr)]] <- df
    cat(sprintf("    %d counties\n", nrow(df)))
  } else {
    cat(sprintf("    Failed: HTTP %s\n",
                ifelse(is.null(resp), "ERROR", httr::status_code(resp))))
  }
  Sys.sleep(0.5)
}

stopifnot("No ACS data" = length(acs_list) > 0)

acs <- bind_rows(acs_list)
acs <- acs %>%
  mutate(
    fips = paste0(state, county),
    med_income = as.numeric(B19013_001E),
    poverty_n = as.numeric(B17001_002E),
    total_pop = as.numeric(B01003_001E)
  ) %>%
  filter(!is.na(total_pop) & total_pop > 0) %>%
  mutate(poverty_rate = poverty_n / total_pop) %>%
  select(fips, acs_year, med_income, poverty_rate, total_pop)

write_csv(acs, file.path(data_dir, "acs_county_demographics.csv"))
cat(sprintf("ACS panel: %d county-years, %d unique counties\n",
            nrow(acs), n_distinct(acs$fips)))
