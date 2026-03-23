## 01_fetch_data.R — Fetch WIC EBT dates + Birth outcomes + WIC participation
## apep_0832: The Access Cost of Fraud Prevention

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

## ============================================================
## 1. WIC EBT State Adoption Dates
## ============================================================
## Sources: FNS WIC EBT Status Tracker, Meckel (AER 2020) Table A1,
## state WIC agency implementation reports.
## These are the statewide WIC EBT completion years.

wic_ebt_dates <- data.table(
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  ebt_year = c(
    2017L, 2016L, 2017L, 2014L, 2019L, 2014L, 2015L, 2015L, 2018L, 2017L,
    2016L, 2015L, 2013L, 2015L, 2016L, 2017L, 2006L, 2016L, 2014L, 2015L,
    2015L, 2004L, 2011L, 2016L, 2016L, 2014L, 2016L, 2005L, 2014L, 2017L,
    2014L, 2014L, 2016L, 2015L, 2015L, 2017L, 2015L, 2016L, 2016L, 2016L,
    2015L, 2016L, 2006L, 2015L, 2015L, 2016L, 2015L, 2013L, 2013L, 2012L, 2015L
  )
)

stopifnot(nrow(wic_ebt_dates) == 51)
stopifnot(all(wic_ebt_dates$ebt_year >= 2004 & wic_ebt_dates$ebt_year <= 2020))
cat("WIC EBT dates: 51 states, range", min(wic_ebt_dates$ebt_year), "-",
    max(wic_ebt_dates$ebt_year), "\n")

## ============================================================
## 2. State FIPS Crosswalk
## ============================================================
state_fips <- data.table(
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
            "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
            "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
            "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
            "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                            24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                            42,44,45,46,47,48,49,50,51,53,54,55,56)),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California",
                 "Colorado","Connecticut","Delaware","District of Columbia","Florida",
                 "Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas",
                 "Kentucky","Louisiana","Maine","Maryland","Massachusetts","Michigan",
                 "Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada",
                 "New Hampshire","New Jersey","New Mexico","New York","North Carolina",
                 "North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont",
                 "Virginia","Washington","West Virginia","Wisconsin","Wyoming")
)

## ============================================================
## 3. County Health Rankings (LBW + Infant Mortality by State-Year)
## ============================================================
## CHR publishes annual analytic_data CSV files with county- and state-level
## health indicators. State rows have countycode=0.
## Key variables: v037_rawvalue (LBW rate), v129_rawvalue (infant mortality rate)
##
## IMPORTANT: CHR data years lag the release year by ~2-4 years.
## CHR 2024 → 2017-2021 data; CHR 2020 → 2013-2017; etc.
## For our purposes, we use the release year as the panel year (which captures
## a multi-year average centered ~3 years prior to release).

chr_years <- 2010:2024
## URL format changed: 2010-2018 at /files/, 2019+ at /files/media/document/
chr_url_for_year <- function(yr) {
  if (yr <= 2018) {
    paste0("https://www.countyhealthrankings.org/sites/default/files/analytic_data", yr, ".csv")
  } else {
    paste0("https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data", yr, ".csv")
  }
}

all_chr <- list()
for (yr in chr_years) {
  url <- chr_url_for_year(yr)
  cat("Fetching CHR", yr, "... ")

  resp <- tryCatch(
    httr::GET(url, httr::timeout(120)),
    error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL }
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat("status:", if (!is.null(resp)) httr::status_code(resp) else "error", "\n")
    next
  }

  tmp <- tempfile(fileext = ".csv")
  writeBin(httr::content(resp, as = "raw"), tmp)

  ## Read with skip=1 (row 1 = descriptive headers, row 2 = variable codes)
  d <- tryCatch(
    fread(tmp, skip = 1, fill = TRUE),
    error = function(e) { cat("PARSE ERROR\n"); NULL }
  )

  if (is.null(d) || nrow(d) == 0) { cat("empty\n"); next }

  ## Extract state-level rows (countycode == 0 or "000")
  d[, countycode := as.character(countycode)]
  state_d <- d[countycode == "0" | countycode == "000"]

  if (nrow(state_d) == 0) { cat("no state rows\n"); next }

  ## Extract key variables
  cols_want <- c("statecode", "state", "v037_rawvalue", "v129_rawvalue")
  cols_exist <- intersect(cols_want, names(state_d))

  if (!"v037_rawvalue" %in% cols_exist) {
    cat("no LBW variable\n")
    next
  }

  out <- state_d[, ..cols_exist]
  out[, chr_year := yr]

  all_chr[[as.character(yr)]] <- out
  cat(nrow(out), "states\n")
}

chr_panel <- rbindlist(all_chr, fill = TRUE)
chr_panel[, lbw_rate := as.numeric(v037_rawvalue)]
chr_panel[, infant_mort_rate := as.numeric(v129_rawvalue)]
chr_panel[, statecode := as.character(statecode)]

cat("\nCHR panel:", nrow(chr_panel), "state-year obs\n")
cat("Years:", paste(sort(unique(chr_panel$chr_year)), collapse = ", "), "\n")
cat("States per year:", chr_panel[, .N, by = chr_year][, paste(N, collapse = ", ")], "\n")

## Map CHR release year → approximate data midpoint year
## CHR uses 5-year averages typically ending 2-3 years before release
## E.g., CHR 2020 → 2014-2018 data → midpoint ~2016
## We'll use the approximate data center year for the DiD panel
chr_panel[, data_year := chr_year - 3L]  # Approximate center of data window

## ============================================================
## 4. County-Level Birth Rates (CDC Socrata)
## ============================================================
## State × county × year birth rates (2003-2020)
cat("\nFetching county-level birth rates...\n")

## Already confirmed this endpoint works
birth_url <- "https://data.cdc.gov/resource/3h58-x6cd.json"

## Fetch in chunks to get all data
all_births <- list()
offset <- 0
repeat {
  resp <- httr::GET(
    birth_url,
    query = list("$limit" = 50000, "$offset" = offset, "$order" = "year,state_fips_code"),
    httr::timeout(120)
  )
  if (httr::status_code(resp) != 200) break
  chunk <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  if (nrow(chunk) == 0) break
  all_births[[length(all_births) + 1]] <- as.data.table(chunk)
  offset <- offset + 50000
  cat("  Fetched", offset, "rows...\n")
  if (nrow(chunk) < 50000) break
}

birth_rates <- rbindlist(all_births, fill = TRUE)
cat("County birth rates:", nrow(birth_rates), "obs,",
    length(unique(birth_rates$year)), "years,",
    length(unique(birth_rates$state)), "states\n")

## Aggregate to state-year
birth_rates[, birth_rate := as.numeric(birth_rate)]
birth_rates[, year := as.integer(year)]
birth_rates[, state_fips_code := as.character(state_fips_code)]

state_birth_rates <- birth_rates[!is.na(birth_rate),
  .(mean_birth_rate = mean(birth_rate, na.rm = TRUE),
    n_counties = .N),
  by = .(year, state, state_fips_code)
]

cat("State-year birth rates:", nrow(state_birth_rates), "obs\n")

## ============================================================
## 5. WIC Participation from USDA FNS
## ============================================================
cat("\nFetching WIC participation data...\n")

## USDA FNS publishes WIC participation as annual state-level tables
## Try the SNAP/WIC data API
wic_participation <- NULL

## Try direct FNS data download
wic_urls <- c(
  "https://fns-prod.azureedge.us/sites/default/files/resource-files/26wifypart-3.csv",
  "https://fns-prod.azureedge.us/sites/default/files/resource-files/wisummary.csv"
)

for (url in wic_urls) {
  resp <- tryCatch(httr::GET(url, httr::timeout(60)), error = function(e) NULL)
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    tmp <- tempfile(fileext = ".csv")
    writeBin(httr::content(resp, as = "raw"), tmp)
    wic_data <- tryCatch(fread(tmp, fill = TRUE), error = function(e) NULL)
    if (!is.null(wic_data) && nrow(wic_data) > 0) {
      cat("WIC data from", basename(url), ":", nrow(wic_data), "rows\n")
      cat("Columns:", paste(names(wic_data), collapse = ", "), "\n")
      wic_participation <- wic_data
      break
    }
  }
}

## ============================================================
## 6. SAVE ALL DATA
## ============================================================
fwrite(wic_ebt_dates, "data/wic_ebt_dates.csv")
fwrite(state_fips, "data/state_fips.csv")
fwrite(chr_panel, "data/chr_state_panel.csv")
fwrite(state_birth_rates, "data/state_birth_rates.csv")
fwrite(birth_rates, "data/county_birth_rates.csv")
if (!is.null(wic_participation)) fwrite(wic_participation, "data/wic_participation.csv")

cat("\n=== Data fetch summary ===\n")
cat("WIC EBT dates: 51 states\n")
cat("CHR state panel:", nrow(chr_panel), "state-year obs (LBW + infant mortality)\n")
cat("State birth rates:", nrow(state_birth_rates), "state-year obs\n")
cat("County birth rates:", nrow(birth_rates), "county-year obs\n")
cat("WIC participation:", if (!is.null(wic_participation)) nrow(wic_participation) else 0, "obs\n")
cat("Files:", paste(list.files("data/"), collapse = ", "), "\n")
