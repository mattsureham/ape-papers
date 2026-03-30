## ============================================================
## 01_fetch_data.R — Load GFW vessel data and construct treatment panel
## apep_1124: Sanctions at Sea
## ============================================================

source("00_packages.R")

# ---------------------------------------------------------------
# 1. GFW Fishing Effort from Vessel-Level Data (Zenodo)
# ---------------------------------------------------------------
# Source: fishing-vessels-v3.csv from Zenodo record 14982712
# 773K vessel-year rows with flag, gear, fishing_hours per vessel per year
# Downloaded from: https://zenodo.org/records/14982712

cat("=== Loading GFW fishing vessel data ===\n")

vessels_raw <- fread("../data/fishing-vessels-v3.csv",
                     select = c("mmsi", "year", "flag_gfw",
                                "vessel_class_gfw", "fishing_hours",
                                "active_hours", "length_m_gfw",
                                "tonnage_gt_gfw"))

cat(sprintf("Raw vessel data: %d rows, %d unique MMSI, years %d-%d\n",
            nrow(vessels_raw), uniqueN(vessels_raw$mmsi),
            min(vessels_raw$year), max(vessels_raw$year)))

# Aggregate to flag_state × year
gfw_annual <- vessels_raw[
  !is.na(flag_gfw) & flag_gfw != "" & fishing_hours > 0,
  .(n_vessels = uniqueN(mmsi),
    fishing_hours = sum(fishing_hours, na.rm = TRUE),
    total_hours = sum(active_hours, na.rm = TRUE)),
  by = .(flag_iso3 = flag_gfw, year)
][order(flag_iso3, year)]

cat(sprintf("Annual aggregation: %d rows, %d flag states, years %d-%d\n",
            nrow(gfw_annual), uniqueN(gfw_annual$flag_iso3),
            min(gfw_annual$year), max(gfw_annual$year)))

# Also create quarterly proxy from monthly fleet data if available
# For now, annual is our main unit of analysis
# (vessel-level data doesn't have monthly breakdown — only annual)

# ---------------------------------------------------------------
# 2. EU IUU Carding Treatment Panel
# ---------------------------------------------------------------

cat("\n=== Constructing EU IUU carding treatment panel ===\n")

iuu_cards <- tribble(
  ~country_name,      ~flag_iso3, ~yellow_date,     ~red_date,        ~green_date,
  "Belize",           "BLZ",      "2012-11-15",     "2014-03-24",     NA,
  "Cambodia",         "KHM",      "2012-11-15",     "2014-03-24",     NA,
  "Fiji",             "FJI",      "2012-11-15",     NA,               "2014-10-14",
  "Guinea",           "GIN",      "2012-11-15",     "2014-03-24",     NA,
  "Panama",           "PAN",      "2012-11-15",     NA,               "2014-10-14",
  "Sri Lanka",        "LKA",      "2012-11-15",     NA,               "2014-10-14",
  "Togo",             "TGO",      "2012-11-15",     NA,               "2014-10-14",
  "Vanuatu",          "VUT",      "2012-11-15",     NA,               "2014-10-14",
  "South Korea",      "KOR",      "2013-11-26",     NA,               "2015-04-21",
  "Curaçao",          "CUW",      "2013-11-26",     NA,               "2015-04-21",
  "Ghana",            "GHA",      "2013-11-26",     NA,               "2015-04-21",
  "Philippines",      "PHL",      "2014-06-10",     NA,               "2015-04-21",
  "Papua New Guinea", "PNG",      "2014-06-10",     NA,               "2015-10-13",
  "Solomon Islands",  "SLB",      "2014-06-10",     NA,               NA,
  "Thailand",         "THA",      "2015-04-21",     NA,               "2019-01-08",
  "Taiwan",           "TWN",      "2015-10-01",     NA,               "2019-06-27",
  "Comoros",          "COM",      "2015-10-01",     "2017-05-23",     NA,
  "Saint Kitts/Nevis","KNA",      "2015-10-01",     "2017-05-23",     NA,
  "Saint Vincent",    "VCT",      "2015-10-01",     NA,               "2016-04-05",
  "Kiribati",         "KIR",      "2016-04-12",     NA,               "2017-12-04",
  "Sierra Leone",     "SLE",      "2016-04-12",     NA,               "2017-12-04",
  "Trinidad/Tobago",  "TTO",      "2016-04-12",     NA,               "2017-12-04",
  "Liberia",          "LBR",      "2017-05-23",     NA,               NA,
  "Vietnam",          "VNM",      "2017-10-23",     NA,               NA,
  "Ecuador",          "ECU",      "2019-10-31",     NA,               "2020-10-21",
  "Cameroon",         "CMR",      "2021-02-16",     "2023-01-28",     NA
)

iuu_cards <- iuu_cards %>%
  mutate(
    yellow_date = as.Date(yellow_date),
    red_date = as.Date(red_date),
    green_date = as.Date(green_date),
    yellow_year = year(yellow_date)
  )

cat(sprintf("IUU carding panel: %d countries\n", nrow(iuu_cards)))
cat(sprintf("Treatment years: %d to %d\n",
            min(iuu_cards$yellow_year), max(iuu_cards$yellow_year)))

# Check which carded countries appear in GFW data
carded_in_gfw <- iuu_cards$flag_iso3[iuu_cards$flag_iso3 %in% gfw_annual$flag_iso3]
cat(sprintf("Carded countries in GFW: %d / %d (%s)\n",
            length(carded_in_gfw), nrow(iuu_cards),
            paste(carded_in_gfw, collapse = ", ")))

# Some GFW flags use different codes — check for TWN (Taiwan)
# GFW uses "TWN" for Taiwan — confirmed in data
cat(sprintf("Taiwan in GFW: %s\n", "TWN" %in% gfw_annual$flag_iso3))

# ---------------------------------------------------------------
# 3. UN Comtrade Seafood Exports (for heterogeneity)
# ---------------------------------------------------------------

cat("\n=== Fetching UN Comtrade seafood export data ===\n")

iso3_to_m49 <- c(
  "THA" = "764", "VNM" = "704", "KOR" = "410", "PHL" = "608",
  "TWN" = "158", "GHA" = "288", "CMR" = "120", "ECU" = "218",
  "BLZ" = "84",  "KHM" = "116", "FJI" = "242", "GIN" = "324",
  "PAN" = "591", "LKA" = "144", "TGO" = "768", "VUT" = "548",
  "CUW" = "531", "PNG" = "598", "SLB" = "90",  "COM" = "174",
  "KNA" = "659", "VCT" = "670", "KIR" = "296", "SLE" = "694",
  "TTO" = "780", "LBR" = "430"
)

comtrade_results <- list()

for (iso3 in iuu_cards$flag_iso3) {
  m49 <- iso3_to_m49[iso3]
  if (is.na(m49)) next

  # Fetch total seafood exports (HS 03) to World
  url_world <- sprintf(
    "https://comtradeapi.un.org/public/v1/preview/C/A/HS?reporterCode=%s&partnerCode=0&cmdCode=03&flowCode=X&period=%s",
    m49, paste(2010:2023, collapse = ","))

  resp <- tryCatch(
    GET(url_world, timeout(30)),
    error = function(e) NULL
  )

  if (!is.null(resp) && status_code(resp) == 200) {
    data <- content(resp, as = "parsed")
    if (length(data$data) > 0) {
      for (row in data$data) {
        comtrade_results[[length(comtrade_results) + 1]] <- data.frame(
          flag_iso3 = iso3,
          year = as.integer(row$period),
          partner = "World",
          export_value = as.numeric(ifelse(is.null(row$primaryValue), 0, row$primaryValue)),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  # EU exports (partner = 97)
  url_eu <- sprintf(
    "https://comtradeapi.un.org/public/v1/preview/C/A/HS?reporterCode=%s&partnerCode=97&cmdCode=03&flowCode=X&period=%s",
    m49, paste(2010:2023, collapse = ","))

  resp_eu <- tryCatch(
    GET(url_eu, timeout(30)),
    error = function(e) NULL
  )

  if (!is.null(resp_eu) && status_code(resp_eu) == 200) {
    data_eu <- content(resp_eu, as = "parsed")
    if (length(data_eu$data) > 0) {
      for (row in data_eu$data) {
        comtrade_results[[length(comtrade_results) + 1]] <- data.frame(
          flag_iso3 = iso3,
          year = as.integer(row$period),
          partner = "EU",
          export_value = as.numeric(ifelse(is.null(row$primaryValue), 0, row$primaryValue)),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  Sys.sleep(1.5)  # Rate limiting
  cat(sprintf("  Fetched Comtrade for %s\n", iso3))
}

if (length(comtrade_results) > 0) {
  comtrade_df <- bind_rows(comtrade_results)
  cat(sprintf("Comtrade data: %d rows for %d countries\n",
              nrow(comtrade_df), n_distinct(comtrade_df$flag_iso3)))
} else {
  cat("WARNING: No Comtrade data fetched. Proceeding without trade data.\n")
  comtrade_df <- data.frame(flag_iso3 = character(0), year = integer(0),
                            partner = character(0), export_value = numeric(0))
}

# ---------------------------------------------------------------
# 4. Save Raw Data
# ---------------------------------------------------------------

cat("\n=== Saving raw data ===\n")

fwrite(gfw_annual, "../data/gfw_annual.csv")
write_csv(iuu_cards, "../data/iuu_cards.csv")
write_csv(comtrade_df, "../data/comtrade_seafood.csv")

# Validation checks
stopifnot("Must have GFW data for at least 80 flag states" =
            uniqueN(gfw_annual$flag_iso3) >= 80)
stopifnot("GFW data must span 2012-2023" =
            min(gfw_annual$year) <= 2012 & max(gfw_annual$year) >= 2023)
stopifnot("Must have at least 15 carded countries in GFW data" =
            length(carded_in_gfw) >= 15)

cat("\n=== Data fetch complete ===\n")
cat(sprintf("GFW: %d flag states, %d years\n",
            uniqueN(gfw_annual$flag_iso3), uniqueN(gfw_annual$year)))
cat(sprintf("IUU cards: %d countries\n", nrow(iuu_cards)))
cat(sprintf("Comtrade: %d rows\n", nrow(comtrade_df)))
