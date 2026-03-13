## 01_fetch_data.R — Fetch CDC VSRR overdose data and construct EPCS treatment panel
## apep_0652: EPCS Mandates and Opioid Mortality

source("00_packages.R")

# ============================================================================
# 1. CDC VSRR Provisional Drug Overdose Deaths (Socrata API)
# ============================================================================
message("Fetching CDC VSRR data...")

base_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

# Fetch year by year to avoid Socrata offset limits
all_data <- list()
for (yr in 2015:2024) {
  offset <- 0
  batch_size <- 50000
  repeat {
    url <- URLencode(sprintf(
      "%s?$limit=%d&$offset=%d&$where=year='%d'&$order=state_name,month",
      base_url, batch_size, offset, yr
    ))
    resp <- httr::GET(url)
    if (httr::status_code(resp) != 200) {
      message("  Warning: CDC API status ", httr::status_code(resp), " for year ", yr, " offset ", offset)
      break
    }
    batch <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    if (length(batch) == 0 || nrow(batch) == 0) break
    all_data[[length(all_data) + 1]] <- batch
    message("  Year ", yr, ": fetched ", offset + nrow(batch), " rows")
    if (nrow(batch) < batch_size) break
    offset <- offset + batch_size
    Sys.sleep(0.3)
  }
  Sys.sleep(0.3)
}

cdc_raw <- data.table::rbindlist(all_data, fill = TRUE)
message("Total CDC rows fetched: ", nrow(cdc_raw))

# Validate
stopifnot(nrow(cdc_raw) > 10000)
stopifnot(all(c("state_name", "year", "month", "indicator") %in% names(cdc_raw)))

data.table::fwrite(cdc_raw, "../data/cdc_vsrr_raw.csv")
message("Saved cdc_vsrr_raw.csv: ", nrow(cdc_raw), " rows")

# ============================================================================
# 2. EPCS Mandate Treatment Dates
# ============================================================================
# Sources: NCSL "State Requirements for Electronic Prescribing" (2024);
# Pharmacy Times "States That Require EPCS" (2023); individual state statutes.

epcs_dates <- data.table::data.table(
  state_abbr = c("NY", "ME", "PA", "AZ", "CT", "IA", "MA", "NC", "OK", "RI",
                  "VA", "AL", "AR", "DE", "IN", "KY", "MO", "NV", "SC", "TN",
                  "TX", "WA", "WY", "KS", "CA", "MD", "MI", "NE", "NH", "UT",
                  "IL"),
  epcs_date = as.Date(c(
    "2016-03-27",  # NY — first state, March 27 2016
    "2017-01-01",  # ME
    "2019-10-24",  # PA
    "2020-01-01", "2020-01-01", "2020-01-01", "2020-01-01", "2020-01-01",
    "2020-01-01", "2020-01-01",  # AZ CT IA MA NC OK RI
    "2020-07-01",  # VA
    "2021-01-01", "2021-01-01", "2021-01-01", "2021-01-01", "2021-01-01",
    "2021-01-01", "2021-01-01", "2021-01-01", "2021-01-01", "2021-01-01",
    "2021-01-01", "2021-01-01",  # AL AR DE IN KY MO NV SC TN TX WA WY
    "2021-07-01",  # KS
    "2022-01-01", "2022-01-01", "2022-01-01", "2022-01-01", "2022-01-01",
    "2022-01-01",  # CA MD MI NE NH UT
    "2024-01-01"   # IL
  )),
  epcs_year = c(2016, 2017, 2019, rep(2020, 7), 2020,
                rep(2021, 12), 2021,
                rep(2022, 6), 2024)
)

state_xwalk <- data.table::data.table(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC")
)
epcs_dates <- merge(epcs_dates, state_xwalk, by = "state_abbr", all.x = TRUE)
data.table::fwrite(epcs_dates, "../data/epcs_treatment_dates.csv")
message("EPCS treatment dates: ", nrow(epcs_dates), " states")

# ============================================================================
# 3. State Population (Census API)
# ============================================================================
message("Fetching state population estimates...")

census_key <- Sys.getenv("CENSUS_API_KEY")

pop_list <- list()
for (yr in 2015:2023) {
  url <- paste0("https://api.census.gov/data/", yr,
                "/acs/acs1?get=B01003_001E,NAME&for=state:*")
  if (nchar(census_key) > 0) url <- paste0(url, "&key=", census_key)
  resp <- httr::GET(url)
  if (httr::status_code(resp) != 200) {
    message("  Census API failed for year ", yr)
    next
  }
  raw <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  df <- data.table::as.data.table(raw[-1, , drop = FALSE])
  names(df) <- raw[1, ]
  df[, year := yr]
  pop_list[[as.character(yr)]] <- df
  Sys.sleep(0.3)
}

pop_dt <- data.table::rbindlist(pop_list, fill = TRUE)
pop_dt[, population := as.numeric(B01003_001E)]
pop_dt[, state_fips := state]
pop_dt <- pop_dt[, .(state_name = NAME, state_fips, year, population)]

# Carry forward 2023 for 2024
pop_2024 <- copy(pop_dt[year == 2023])
pop_2024[, year := 2024]
pop_dt <- rbind(pop_dt, pop_2024)

data.table::fwrite(pop_dt, "../data/state_population.csv")
message("Population data: ", nrow(pop_dt), " state-years")

# ============================================================================
# Validation
# ============================================================================
stopifnot(nrow(cdc_raw) > 10000)
stopifnot(nrow(epcs_dates) >= 25)
stopifnot(nrow(pop_dt) > 400)

message("\n=== Data fetch complete ===")
message("CDC VSRR: ", nrow(cdc_raw), " rows")
message("EPCS dates: ", nrow(epcs_dates), " states")
message("Population: ", nrow(pop_dt), " state-years")
