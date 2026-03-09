## ============================================================
## 01_fetch_data.R — Data acquisition from World Bank and ILO
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

source("00_packages.R")

## ============================================================
## 1. OECD country list (donors for synthetic control)
## ============================================================

oecd_iso2 <- c(
  "AU", "AT", "BE", "CA", "CL", "CO", "CR", "CZ", "DK", "EE",
  "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IL", "IT", "JP",
  "KR", "LV", "LT", "LU", "MX", "NL", "NZ", "NO", "PL", "PT",
  "SK", "SI", "ES", "SE", "CH", "TR", "GB", "US"
)

oecd_iso3 <- c(
  "AUS", "AUT", "BEL", "CAN", "CHL", "COL", "CRI", "CZE", "DNK", "EST",
  "FIN", "FRA", "DEU", "GRC", "HUN", "ISL", "IRL", "ISR", "ITA", "JPN",
  "KOR", "LVA", "LTU", "LUX", "MEX", "NLD", "NZL", "NOR", "POL", "PRT",
  "SVK", "SVN", "ESP", "SWE", "CHE", "TUR", "GBR", "USA"
)

## ============================================================
## 2. World Bank API — Fetch indicators for all OECD countries
## ============================================================

fetch_wb <- function(indicator, countries, start = 2000, end = 2023) {
  # Fetch in batches of 15 countries to avoid timeout
  batch_size <- 15
  all_results <- list()
  for (i in seq(1, length(countries), by = batch_size)) {
    batch <- countries[i:min(i + batch_size - 1, length(countries))]
    cstr <- paste(batch, collapse = ";")
    url <- sprintf(
      "https://api.worldbank.org/v2/country/%s/indicator/%s?date=%d:%d&format=json&per_page=5000",
      cstr, indicator, start, end
    )
    for (attempt in 1:3) {
      resp <- tryCatch(GET(url, timeout(90)), error = function(e) NULL)
      if (!is.null(resp) && status_code(resp) == 200) break
      Sys.sleep(2)
    }
    if (is.null(resp) || status_code(resp) != 200) {
      cat(sprintf("  WARNING: batch %d failed for %s\n", i, indicator))
      next
    }
    d <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    if (length(d) >= 2 && !is.null(d[[2]])) {
      all_results[[length(all_results) + 1]] <- as.data.table(d[[2]])
    }
    Sys.sleep(1)
  }
  if (length(all_results) == 0) stop("No data from WB for ", indicator)
  dt <- rbindlist(all_results, fill = TRUE)
  dt <- dt[, .(iso2 = countryiso3code, country = country.value,
               year = as.integer(date), value = as.numeric(value))]
  dt <- dt[!is.na(value)]
  cat(sprintf("  %s: %d obs, %d countries, years %d-%d\n",
              indicator, nrow(dt), uniqueN(dt$iso2), min(dt$year), max(dt$year)))
  return(dt)
}

cat("Fetching World Bank indicators...\n")

## Total fertility rate
tfr <- fetch_wb("SP.DYN.TFRT.IN", oecd_iso2)
tfr[, variable := "tfr"]

## Crude birth rate (per 1000)
cbr <- fetch_wb("SP.DYN.CBRT.IN", oecd_iso2)
cbr[, variable := "cbr"]

## GDP per capita (constant 2015 USD)
gdppc <- fetch_wb("NY.GDP.PCAP.KD", oecd_iso2)
gdppc[, variable := "gdp_pc"]

## Female labor force participation (% of female pop 15+)
flfp <- fetch_wb("SL.TLF.CACT.FE.ZS", oecd_iso2)
flfp[, variable := "flfp"]

## Unemployment rate
unemp <- fetch_wb("SL.UEM.TOTL.ZS", oecd_iso2)
unemp[, variable := "unemp"]

## Urban population share
urban <- fetch_wb("SP.URB.TOTL.IN.ZS", oecd_iso2)
urban[, variable := "urban_pct"]

## Population total
pop <- fetch_wb("SP.POP.TOTL", oecd_iso2)
pop[, variable := "pop"]

## Combine all WB data
wb_panel <- rbindlist(list(tfr, cbr, gdppc, flfp, unemp, urban, pop))
wb_wide <- dcast(wb_panel, iso2 + country + year ~ variable, value.var = "value")

cat(sprintf("\nWB panel: %d rows, %d countries, years %d-%d\n",
            nrow(wb_wide), uniqueN(wb_wide$iso2), min(wb_wide$year), max(wb_wide$year)))

## ============================================================
## 3. ILO API — Hours worked by industry for Korea
## ============================================================

cat("\nFetching ILO hours data for Korea...\n")

ilo_url <- paste0(
  "https://rplumber.ilo.org/data/indicator/",
  "?id=HOW_TEMP_SEX_ECO_NB_A&ref_area=KOR",
  "&timefrom=2005&timeto=2023&format=.csv"
)
resp <- GET(ilo_url, timeout(60))
if (status_code(resp) != 200) stop("ILO API failed: ", status_code(resp))

kor_hours_raw <- fread(content(resp, "text", encoding = "UTF-8"))
cat(sprintf("  Korea hours: %d rows, years %s\n",
            nrow(kor_hours_raw), paste(range(kor_hours_raw$time), collapse = "-")))

## ============================================================
## 4. ILO API — Hours worked for ALL OECD countries (for SCM)
## ============================================================

cat("\nFetching ILO hours for all OECD countries...\n")

ilo_all_url <- paste0(
  "https://rplumber.ilo.org/data/indicator/",
  "?id=HOW_TEMP_SEX_ECO_NB_A",
  "&ref_area=", paste(oecd_iso3, collapse = "+"),
  "&timefrom=2000&timeto=2023",
  "&classif1=ECO_AGGREGATE_TOTAL",
  "&sex=SEX_T",
  "&format=.csv"
)
resp2 <- GET(ilo_all_url, timeout(120))
if (status_code(resp2) != 200) stop("ILO API (all OECD) failed: ", status_code(resp2))

ilo_all <- fread(content(resp2, "text", encoding = "UTF-8"))
cat(sprintf("  All OECD hours: %d rows, %d countries\n",
            nrow(ilo_all), uniqueN(ilo_all$ref_area)))

## ============================================================
## 5. ILO — Employment by hours bands for Korea (excessive hours)
## ============================================================

cat("\nFetching ILO excessive hours data for Korea...\n")

# EMP_TEMP_SEX_HOW_NB = employment by hours bands
ilo_hours_bands_url <- paste0(
  "https://rplumber.ilo.org/data/indicator/",
  "?id=EMP_TEMP_SEX_HOW_NB_A&ref_area=KOR",
  "&timefrom=2005&timeto=2023&format=.csv"
)
resp3 <- GET(ilo_hours_bands_url, timeout(60))
if (status_code(resp3) == 200) {
  kor_hours_bands <- fread(content(resp3, "text", encoding = "UTF-8"))
  cat(sprintf("  Korea hours bands: %d rows\n", nrow(kor_hours_bands)))
} else {
  cat("  Hours bands not available, trying alternative...\n")
  # Try excessive hours indicator
  ilo_exc_url <- paste0(
    "https://rplumber.ilo.org/data/indicator/",
    "?id=EAR_XEES_SEX_ECO_NB_A&ref_area=KOR",
    "&timefrom=2005&timeto=2023&format=.csv"
  )
  resp3b <- GET(ilo_exc_url, timeout(60))
  kor_hours_bands <- if (status_code(resp3b) == 200) {
    fread(content(resp3b, "text", encoding = "UTF-8"))
  } else {
    cat("  Also not available. Will construct from mean hours.\n")
    data.table()
  }
}

## ============================================================
## 6. ILO — Employment levels by industry for Korea
## ============================================================

cat("\nFetching ILO employment by industry for Korea...\n")

ilo_emp_url <- paste0(
  "https://rplumber.ilo.org/data/indicator/",
  "?id=EMP_TEMP_SEX_ECO_NB_A&ref_area=KOR",
  "&timefrom=2005&timeto=2023&format=.csv"
)
resp4 <- GET(ilo_emp_url, timeout(60))
if (status_code(resp4) != 200) stop("ILO employment API failed: ", status_code(resp4))

kor_emp <- fread(content(resp4, "text", encoding = "UTF-8"))
cat(sprintf("  Korea employment: %d rows\n", nrow(kor_emp)))

## ============================================================
## 7. World Bank — Marriage rate (crude) for OECD countries
## ============================================================

cat("\nFetching UN crude marriage rate...\n")

# WB doesn't have marriage rate. Try UN data portal.
# Using SP.DYN.SMAM.FE (mean age at first marriage, female) as proxy
marriage_age <- tryCatch({
  fetch_wb("SP.DYN.SMAM.FE", oecd_iso2)
}, error = function(e) {
  cat("  Marriage age not available from WB\n")
  data.table()
})

if (nrow(marriage_age) > 0) {
  marriage_age[, variable := "marriage_age_f"]
  wb_wide <- merge(wb_wide,
                   marriage_age[, .(iso2, year, marriage_age_f = value)],
                   by = c("iso2", "year"), all.x = TRUE)
}

## ============================================================
## 8. Save all data
## ============================================================

fwrite(wb_wide, file.path(data_dir, "wb_oecd_panel.csv"))
fwrite(kor_hours_raw, file.path(data_dir, "kor_hours_industry.csv"))
fwrite(ilo_all, file.path(data_dir, "oecd_hours_total.csv"))
if (nrow(kor_hours_bands) > 0) {
  fwrite(kor_hours_bands, file.path(data_dir, "kor_hours_bands.csv"))
}
fwrite(kor_emp, file.path(data_dir, "kor_employment_industry.csv"))

cat("\n=== DATA VALIDATION ===\n")

## Validate: WB panel
stopifnot("Expected 30+ OECD countries" = uniqueN(wb_wide$iso2) >= 30)
stopifnot("Expected years 2000-2023" = min(wb_wide$year) <= 2001 & max(wb_wide$year) >= 2022)
stopifnot("Expected TFR for Korea" = nrow(wb_wide[iso2 == "KOR" & !is.na(tfr)]) >= 15)
cat(sprintf("WB panel: %d rows, %d countries, %d years\n",
            nrow(wb_wide), uniqueN(wb_wide$iso2), uniqueN(wb_wide$year)))

## Validate: ILO Korea hours
stopifnot("Expected 10+ years of Korea hours" = uniqueN(kor_hours_raw$time) >= 10)
stopifnot("Expected industry breakdowns" = any(grepl("ISIC4", kor_hours_raw$classif1)))
cat(sprintf("Korea hours: %d rows, %d years, %d industries\n",
            nrow(kor_hours_raw), uniqueN(kor_hours_raw$time),
            uniqueN(kor_hours_raw[grepl("ISIC4", classif1)]$classif1)))

## Validate: ILO OECD hours
stopifnot("Expected 25+ OECD countries with hours" = uniqueN(ilo_all$ref_area) >= 25)
cat(sprintf("OECD hours: %d rows, %d countries\n",
            nrow(ilo_all), uniqueN(ilo_all$ref_area)))

cat("\nData validation passed. All files saved to:", data_dir, "\n")
