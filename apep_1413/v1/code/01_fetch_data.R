# 01_fetch_data.R — Fetch WDI + Enterprise Survey data for Azerbaijan ASAN analysis
# Paper: apep_1413
# Design: Synthetic Control — Azerbaijan vs. comparator countries
# Treatment: ASAN launch (Dec 2012, operational 2013)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Helper: Fetch WDI indicator for multiple countries
# ============================================================

fetch_wdi_multi <- function(indicator, countries, date_range = "2004:2023") {
  country_str <- paste(countries, collapse = ";")
  url <- sprintf(
    "https://api.worldbank.org/v2/country/%s/indicator/%s?date=%s&format=json&per_page=5000",
    country_str, indicator, date_range
  )
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("WDI API failed for %s: HTTP %d", indicator, httr::status_code(resp)))
  }
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)
  if (length(parsed) < 2 || is.null(parsed[[2]])) {
    warning(sprintf("No data returned for %s", indicator))
    return(data.frame())
  }
  df <- as.data.frame(parsed[[2]])
  df$value <- as.numeric(df$value)
  df$date <- as.integer(df$date)
  df$indicator_id <- indicator
  df <- df[!is.na(df$value), c("countryiso3code", "date", "value", "indicator_id")]
  names(df) <- c("iso3", "year", "value", "indicator")
  return(df)
}

# ============================================================
# 1. Define country groups
# ============================================================

# Former Soviet + regional comparators (broad donor pool for SCM)
donor_countries <- c(
  # Caucasus
  "AZE", "GEO", "ARM",
  # Central Asia
  "KAZ", "UZB", "KGZ", "TJK", "TKM",
  # Eastern Europe / Former Soviet
  "UKR", "MDA", "BLR",
  # Regional neighbors
  "TUR", "IRN",
  # Other upper-middle income post-Soviet
  "RUS", "MNG"
)

cat(sprintf("Donor pool: %d countries\n", length(donor_countries)))

# ============================================================
# 2. Fetch primary outcomes (annual)
# ============================================================

cat("\n=== Fetching WDI indicators ===\n")

indicators <- list(
  "IC.BUS.NREG"       = "New business registrations",
  "IC.REG.DURS"       = "Days to start a business",
  "IC.REG.COST.PC.ZS" = "Cost to start business (% GNI pc)",
  "IC.REG.PROC"       = "Procedures to start business",
  "NY.GDP.PCAP.PP.KD" = "GDP per capita (PPP, constant 2017 $)",
  "NV.IND.TOTL.ZS"    = "Industry value added (% GDP)",
  "SL.UEM.TOTL.ZS"    = "Unemployment rate",
  "FP.CPI.TOTL.ZG"    = "Inflation (CPI, annual %)",
  "BX.KLT.DINV.WD.GD.ZS" = "FDI inflows (% GDP)",
  "GC.REV.XGRT.GD.ZS" = "Revenue excl grants (% GDP)"
)

all_data <- data.frame()
for (ind in names(indicators)) {
  cat(sprintf("  Fetching %s (%s)...", ind, indicators[[ind]]))
  tryCatch({
    df <- fetch_wdi_multi(ind, donor_countries)
    if (nrow(df) > 0) {
      cat(sprintf(" %d obs\n", nrow(df)))
      all_data <- rbind(all_data, df)
    } else {
      cat(" NO DATA\n")
    }
  }, error = function(e) {
    cat(sprintf(" ERROR: %s\n", e$message))
  })
  Sys.sleep(0.5)  # Rate limiting
}

cat(sprintf("\nTotal WDI observations: %d\n", nrow(all_data)))
cat(sprintf("Countries with data: %s\n",
            paste(sort(unique(all_data$iso3)), collapse = ", ")))

# Validate: Azerbaijan must have new business registrations data
aze_reg <- all_data[all_data$iso3 == "AZE" & all_data$indicator == "IC.BUS.NREG", ]
if (nrow(aze_reg) == 0) {
  stop("FATAL: No business registration data for Azerbaijan. Cannot proceed.")
}
cat(sprintf("\nAzerbaijan business registrations: %d years of data\n", nrow(aze_reg)))
cat("Values:\n")
print(aze_reg[order(aze_reg$year), c("year", "value")])

# ============================================================
# 3. Fetch Enterprise Survey bribery indicators (survey years)
# ============================================================

cat("\n=== Fetching Enterprise Survey bribery data ===\n")

es_indicators <- list(
  "IC.FRM.BRIB.ZS" = "Bribery incidence (% firms)",
  "IC.FRM.CORR.ZS" = "Firms giving gifts for contracts (%)",
  "IC.GOV.DURS.ZS" = "Senior mgmt time with govt regs (%)"
)

es_data <- data.frame()
for (ind in names(es_indicators)) {
  cat(sprintf("  Fetching %s...", es_indicators[[ind]]))
  tryCatch({
    df <- fetch_wdi_multi(ind, donor_countries, date_range = "2005:2023")
    if (nrow(df) > 0) {
      cat(sprintf(" %d obs\n", nrow(df)))
      es_data <- rbind(es_data, df)
    } else {
      cat(" NO DATA\n")
    }
  }, error = function(e) {
    cat(sprintf(" ERROR: %s\n", e$message))
  })
  Sys.sleep(0.5)
}

# Check Azerbaijan bribery data
aze_brib <- es_data[es_data$iso3 == "AZE" & es_data$indicator == "IC.FRM.BRIB.ZS", ]
cat(sprintf("\nAzerbaijan bribery data: %d observations\n", nrow(aze_brib)))
if (nrow(aze_brib) > 0) {
  cat("Values:\n")
  print(aze_brib[order(aze_brib$year), c("year", "value")])
}

# ============================================================
# 4. Fetch Worldwide Governance Indicators
# ============================================================

cat("\n=== Fetching Governance Indicators ===\n")

wgi_indicators <- list(
  "CC.EST" = "Control of Corruption",
  "GE.EST" = "Government Effectiveness",
  "RQ.EST" = "Regulatory Quality"
)

wgi_data <- data.frame()
for (ind in names(wgi_indicators)) {
  cat(sprintf("  Fetching %s...", wgi_indicators[[ind]]))
  tryCatch({
    df <- fetch_wdi_multi(ind, donor_countries, date_range = "2004:2023")
    if (nrow(df) > 0) {
      cat(sprintf(" %d obs\n", nrow(df)))
      wgi_data <- rbind(wgi_data, df)
    } else {
      cat(" NO DATA\n")
    }
  }, error = function(e) {
    cat(sprintf(" ERROR: %s\n", e$message))
  })
  Sys.sleep(0.5)
}

# ============================================================
# 5. ASAN rollout timeline
# ============================================================

cat("\n=== ASAN rollout timeline ===\n")

asan_timeline <- data.frame(
  center_name = c(
    "Baku-1", "Baku-2", "Baku-3", "Sumgayit",
    "Ganja", "Sabirabad", "Barda",
    "Masalli", "Guba", "Shaki",
    "Shamakhi", "Mingachevir", "Shirvan",
    "Lankaran", "Nakhchivan", "Gabala",
    "Ismayilli", "Agdash", "Bilasuvar",
    "Goychay", "Imishli", "Jalilabad",
    "Khachmaz", "Oguz", "Tovuz",
    "Zagatala", "Zardab"
  ),
  opening_year = c(
    2012, 2013, 2013, 2013,
    2014, 2014, 2015,
    2016, 2016, 2016,
    2017, 2017, 2017,
    2018, 2018, 2018,
    2019, 2019, 2019,
    2019, 2019, 2019,
    2020, 2020, 2020,
    2020, 2020
  ),
  stringsAsFactors = FALSE
)

# ============================================================
# 6. Data validation
# ============================================================

cat("\n=== Data validation ===\n")

# Check we have enough pre/post data for Azerbaijan
aze_all <- all_data[all_data$iso3 == "AZE", ]
aze_years <- sort(unique(aze_all$year))
pre_years <- aze_years[aze_years < 2013]
post_years <- aze_years[aze_years >= 2013]
cat(sprintf("Azerbaijan pre-treatment years: %s\n", paste(pre_years, collapse = ", ")))
cat(sprintf("Azerbaijan post-treatment years: %s\n", paste(post_years, collapse = ", ")))

if (length(pre_years) < 3) {
  warning("Fewer than 3 pre-treatment years — SCM fit may be poor")
}

# Check donor pool coverage
donor_coverage <- all_data %>%
  filter(indicator == "IC.BUS.NREG") %>%
  group_by(iso3) %>%
  summarize(
    n_years = n(),
    min_year = min(year),
    max_year = max(year),
    .groups = "drop"
  )
cat("\nDonor pool coverage (business registrations):\n")
print(donor_coverage)

# ============================================================
# 7. Save all datasets
# ============================================================

cat("\n=== Saving datasets ===\n")

write.csv(all_data, file.path(data_dir, "wdi_panel.csv"), row.names = FALSE)
write.csv(es_data, file.path(data_dir, "enterprise_survey.csv"), row.names = FALSE)
write.csv(wgi_data, file.path(data_dir, "governance_indicators.csv"), row.names = FALSE)
write.csv(asan_timeline, file.path(data_dir, "asan_timeline.csv"), row.names = FALSE)

cat("All datasets saved.\n")
cat(sprintf("Files: %s\n", paste(list.files(data_dir), collapse = ", ")))
