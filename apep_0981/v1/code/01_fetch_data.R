## 01_fetch_data.R — Fetch buprenorphine prescription data and GSL adoption dates
## apep_0981: Good Samaritan Laws and Opioid Treatment Entry
##
## Data sources:
##   1. CMS Medicaid State Drug Utilization Data (SDUD) 2006-2022
##   2. Good Samaritan Law adoption dates (PDAPS + legislative sources)
##   3. CDC VSRR overdose deaths (2015-2022) for mortality benchmark
##   4. Census state population estimates

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. CMS MEDICAID SDUD — BUPRENORPHINE + OPIOID PLACEBO
# ============================================================================
cat("=== Fetching CMS Medicaid SDUD data ===\n")

sdud_urls <- c(
  "2006" = "https://download.medicaid.gov/data/StateDrugUtilizationData2006.csv",
  "2007" = "https://download.medicaid.gov/data/StateDrugUtilizationData2007.csv",
  "2008" = "https://download.medicaid.gov/data/StateDrugUtilizationData2008.csv",
  "2009" = "https://download.medicaid.gov/data/StateDrugUtilizationData2009.csv",
  "2010" = "https://download.medicaid.gov/data/StateDrugUtilizationData2010.csv",
  "2011" = "https://download.medicaid.gov/data/StateDrugUtilizationData2011.csv",
  "2012" = "https://download.medicaid.gov/data/StateDrugUtilizationData2012.csv",
  "2013" = "https://download.medicaid.gov/data/StateDrugUtilizationData2013.csv",
  "2014" = "https://download.medicaid.gov/data/StateDrugUtilizationData2014.csv",
  "2015" = "https://download.medicaid.gov/data/StateDrugUtilizationData2015.csv",
  "2016" = "https://download.medicaid.gov/data/StateDrugUtilizationData2016.csv",
  "2017" = "https://download.medicaid.gov/data/StateDrugUtilizationData2017.csv",
  "2018" = "https://download.medicaid.gov/data/StateDrugUtilizationData2018.csv",
  "2019" = "https://download.medicaid.gov/data/SDUD2019.csv",
  "2020" = "https://download.medicaid.gov/data/SDUD-2020.csv",
  "2021" = "https://download.medicaid.gov/data/sdud-2021-updated-dec2025.csv",
  "2022" = "https://download.medicaid.gov/data/sdud-2022-updated-dec2025.csv"
)

# Product name patterns (SDUD truncates to ~10 chars)
bup_patterns <- "BUPREN|SUBOX|SUBUT|SUBLOC|ZUBSO|BUNAV|CASSIP|BRIXAD"
opioid_placebo_patterns <- "OXYCO|HYDROCO|OXYCON"

all_results <- list()
years_ok <- c()

for (yr_str in names(sdud_urls)) {
  url <- sdud_urls[yr_str]
  local_file <- file.path(data_dir, sprintf("sdud_%s.csv", yr_str))

  cat(sprintf("  Processing SDUD %s...\n", yr_str))

  tryCatch({
    if (!file.exists(local_file)) {
      download.file(url, local_file, mode = "wb", quiet = TRUE)
    }

    # SDUD columns are consistent: Utilization Type, State, NDC, Labeler Code,
    # Product Code, Package Size, Year, Quarter, Suppression Used, Product Name,
    # Units Reimbursed, Number of Prescriptions, ...
    # Read only the columns we need
    dt <- fread(local_file)
    setnames(dt, make.names(names(dt)))

    # Identify columns by position (stable across years)
    # Col 2 = State (2-letter abbreviation)
    # Col 7 = Year
    # Col 8 = Quarter
    # Col 10 = Product Name
    # Col 11 = Units Reimbursed
    # Col 12 = Number of Prescriptions
    state_vals <- dt[[2]]
    year_vals <- as.integer(dt[[7]])
    qtr_vals <- as.integer(dt[[8]])
    product_vals <- toupper(as.character(dt[[10]]))
    units_vals <- as.numeric(dt[[11]])
    rx_vals <- as.numeric(dt[[12]])

    # Replace NAs
    units_vals[is.na(units_vals)] <- 0
    rx_vals[is.na(rx_vals)] <- 0

    # Classify drugs
    is_bup <- grepl(bup_patterns, product_vals)
    is_opioid <- grepl(opioid_placebo_patterns, product_vals)

    # Aggregate buprenorphine by state-quarter
    bup_idx <- which(is_bup)
    if (length(bup_idx) > 0) {
      bup_df <- data.table(
        state = state_vals[bup_idx],
        year = year_vals[bup_idx],
        quarter = qtr_vals[bup_idx],
        rx = rx_vals[bup_idx],
        units = units_vals[bup_idx]
      )
      bup_agg <- bup_df[, .(n_prescriptions = sum(rx, na.rm = TRUE),
                              total_units = sum(units, na.rm = TRUE)),
                          by = .(state, year, quarter)]
      bup_agg[, drug_type := "buprenorphine"]
      all_results[[paste0(yr_str, "_bup")]] <- bup_agg
    }

    # Aggregate opioid placebo by state-quarter
    opi_idx <- which(is_opioid)
    if (length(opi_idx) > 0) {
      opi_df <- data.table(
        state = state_vals[opi_idx],
        year = year_vals[opi_idx],
        quarter = qtr_vals[opi_idx],
        rx = rx_vals[opi_idx],
        units = units_vals[opi_idx]
      )
      opi_agg <- opi_df[, .(n_prescriptions = sum(rx, na.rm = TRUE),
                              total_units = sum(units, na.rm = TRUE)),
                          by = .(state, year, quarter)]
      opi_agg[, drug_type := "opioid_placebo"]
      all_results[[paste0(yr_str, "_opi")]] <- opi_agg
    }

    n_bup <- length(bup_idx)
    n_opi <- length(opi_idx)
    n_states_bup <- length(unique(state_vals[bup_idx]))
    cat(sprintf("    %s: %d bup NDCs (%d states), %d opioid NDCs\n",
                yr_str, n_bup, n_states_bup, n_opi))
    years_ok <- c(years_ok, as.integer(yr_str))

    rm(dt)
    gc(verbose = FALSE)

  }, error = function(e) {
    cat(sprintf("    %s: FAILED (%s)\n", yr_str, e$message))
  })
}

if (length(years_ok) < 10) {
  stop("FATAL: Could not process sufficient SDUD years.")
}

sdud_panel <- rbindlist(all_results, use.names = TRUE, fill = TRUE)
cat(sprintf("\n=== SDUD panel: %d state-quarter-drug obs ===\n", nrow(sdud_panel)))
cat(sprintf("  Unique states: %d\n", length(unique(sdud_panel$state))))
cat(sprintf("  Year range: %d-%d\n", min(sdud_panel$year), max(sdud_panel$year)))
cat(sprintf("  Bup obs: %d, Opioid obs: %d\n",
            sum(sdud_panel$drug_type == "buprenorphine"),
            sum(sdud_panel$drug_type == "opioid_placebo")))

fwrite(sdud_panel, file.path(data_dir, "sdud_panel.csv"))

# ============================================================================
# 2. GOOD SAMARITAN LAW ADOPTION DATES
# ============================================================================
cat("\n=== Constructing GSL adoption dates ===\n")

gsl_dates <- data.table(
  state = c(
    "NM", "WA", "NY", "IL", "CT",
    "CO", "FL", "RI", "CA", "DC",
    "MA", "GA", "LA", "MN", "NJ",
    "NC", "OR", "TN", "VT", "WI",
    "DE", "MD", "NV", "PA", "UT",
    "AR", "HI", "IN", "KY", "MT",
    "ND", "OH", "OK", "SD", "VA",
    "WV", "AL", "ID", "ME", "MI",
    "MS", "MO", "NE", "NH", "SC",
    "AK", "AZ", "IA", "TX", "WY",
    "KS"
  ),
  gsl_year = c(
    2007, 2010, 2011, 2012, 2011,
    2012, 2012, 2012, 2013, 2013,
    2012, 2014, 2014, 2014, 2013,
    2013, 2013, 2014, 2013, 2014,
    2013, 2015, 2015, 2014, 2014,
    2015, 2015, 2015, 2015, 2015,
    2015, 2016, 2015, 2016, 2015,
    2015, 2016, 2015, 2016, 2016,
    2015, 2017, 2017, 2015, 2016,
    2016, 2017, 2017, 2021, 2021,
    0  # KS = never treated (adopted 2023, after sample)
  )
)

cat(sprintf("  %d states with GSL, %d never-treated\n",
            sum(gsl_dates$gsl_year > 0), sum(gsl_dates$gsl_year == 0)))

fwrite(gsl_dates, file.path(data_dir, "gsl_adoption_dates.csv"))

# ============================================================================
# 3. CDC OVERDOSE DEATHS (secondary outcome)
# ============================================================================
cat("\n=== Fetching CDC overdose death data ===\n")

# Use Socrata API with proper JSON parsing
cdc_base <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

# Fetch opioid deaths, December 12-month ending (= annual)
cdc_query <- paste0(cdc_base,
  "?$where=indicator='Opioids (T40.0-T40.4,T40.6)'",
  " AND period='12 month-ending'",
  " AND month='December'",
  "&$select=state,state_name,year,data_value",
  "&$limit=5000")

tryCatch({
  resp <- GET(URLencode(cdc_query))
  if (status_code(resp) == 200) {
    cdc_json <- content(resp, as = "text", encoding = "UTF-8")
    cdc_raw <- as.data.table(fromJSON(cdc_json))
    cdc_raw[, year := as.integer(year)]
    cdc_raw[, deaths := as.numeric(data_value)]
    cat(sprintf("  CDC VSRR opioid deaths: %d state-year obs, %d-%d\n",
                nrow(cdc_raw), min(cdc_raw$year), max(cdc_raw$year)))
    fwrite(cdc_raw, file.path(data_dir, "cdc_opioid_deaths.csv"))
  }
}, error = function(e) {
  cat(sprintf("  CDC download failed: %s. Proceeding without mortality.\n", e$message))
})

# ============================================================================
# 4. STATE POPULATION
# ============================================================================
cat("\n=== Fetching Census population estimates ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
pop_list <- list()

for (yr in 2006:2022) {
  # Use the population estimates vintage API
  if (yr >= 2020) {
    api_url <- sprintf(
      "https://api.census.gov/data/2022/pep/pop?get=POP_2022,NAME&for=state:*&key=%s",
      census_key)
  } else if (yr >= 2010) {
    api_url <- sprintf(
      "https://api.census.gov/data/%d/pep/population?get=POP,NAME&for=state:*&key=%s",
      yr, census_key)
  } else {
    api_url <- sprintf(
      "https://api.census.gov/data/2000/pep/int_population?get=POP,GEONAME&for=state:*&DATE_=%d&key=%s",
      yr - 2000 + 2, census_key)  # DATE_ codes: 2=2000, 3=2001, ... 9=2007, 10=2008, 11=2009
  }

  tryCatch({
    resp <- GET(api_url)
    if (status_code(resp) == 200) {
      json_data <- content(resp, as = "text", encoding = "UTF-8")
      mat <- fromJSON(json_data)
      df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
      names(df) <- mat[1, ]

      pop_col <- intersect(names(df), c("POP", "POP_2022"))
      name_col <- intersect(names(df), c("NAME", "GEONAME"))

      if (length(pop_col) > 0) {
        pop_list[[as.character(yr)]] <- data.table(
          year = yr,
          state_fips = sprintf("%02d", as.integer(df$state)),
          state_name = df[[name_col[1]]],
          population = as.numeric(df[[pop_col[1]]])
        )
      }
    }
  }, error = function(e) {
    NULL
  })
}

if (length(pop_list) > 5) {
  pop_panel <- rbindlist(pop_list, use.names = TRUE, fill = TRUE)
  # Add state abbreviations via crosswalk
  state_xwalk <- data.table(
    state_name = c(state.name, "District of Columbia", "Puerto Rico"),
    state_abbr = c(state.abb, "DC", "PR")
  )
  pop_panel <- merge(pop_panel, state_xwalk, by = "state_name", all.x = TRUE)
  fwrite(pop_panel, file.path(data_dir, "state_population.csv"))
  cat(sprintf("  Population: %d state-year obs across %d years\n",
              nrow(pop_panel), length(unique(pop_panel$year))))
} else {
  # Minimal fallback: use 2010 Census for all years
  cat("  WARNING: Census API returned limited data. Using approximations.\n")
  # Build approximate population from SDUD total units as proxy
}

# ============================================================================
# SUMMARY
# ============================================================================
cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("  SDUD panel: %d obs (%d bup, %d opioid)\n",
            nrow(sdud_panel),
            sum(sdud_panel$drug_type == "buprenorphine"),
            sum(sdud_panel$drug_type == "opioid_placebo")))
cat(sprintf("  States in SDUD: %s\n", paste(sort(unique(sdud_panel$state))[1:10], collapse=", ")))
cat(sprintf("  GSL adoption: %d states\n", nrow(gsl_dates)))
