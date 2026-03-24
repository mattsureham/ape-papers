## 01_fetch_data.R — Fetch all data for apep_0882
## Sources: CDC drug poisoning, Census CBP, FRED oil prices

library(tidyverse)
library(data.table)
library(httr)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== 1. CDC Drug Poisoning Mortality by County (1999-2015) ===\n")

# NCHS Drug Poisoning Mortality by County
# Model-based estimates in 2-unit categorical ranges, all US counties
base_url <- "https://data.cdc.gov/resource/pbkm-d27e.json"

all_mort <- list()
offset <- 0
batch_size <- 50000

repeat {
  url <- paste0(base_url, "?$limit=", batch_size, "&$offset=", offset,
                "&$order=fips,year")
  cat("  Fetching offset", offset, "...\n")
  resp <- GET(url)
  if (status_code(resp) != 200) stop("FATAL: CDC API returned HTTP ", status_code(resp))

  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"))
  if (nrow(batch) == 0) break

  all_mort[[length(all_mort) + 1]] <- batch
  offset <- offset + batch_size
  if (nrow(batch) < batch_size) break
  Sys.sleep(1)
}

mort_raw <- bind_rows(all_mort) %>% as_tibble()

cat("  Rows fetched:", nrow(mort_raw), "\n")
cat("  Year range:", min(mort_raw$year), "-", max(mort_raw$year), "\n")
cat("  Counties:", length(unique(mort_raw$fips)), "\n")

stopifnot(nrow(mort_raw) > 50000)

fwrite(mort_raw, file.path(data_dir, "cdc_drug_poisoning_raw.csv"))
cat("  Saved cdc_drug_poisoning_raw.csv\n\n")


cat("=== 2. Census CBP — Oil & Gas Extraction Employment by County ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("FATAL: CENSUS_API_KEY not set")

cbp_all <- list()

# Fetch NAICS 211 (Oil and Gas Extraction) for 2001-2005
# 2001-2002 use NAICS 1997, 2003-2007 use NAICS 2002
for (yr in 2001:2005) {
  naics_var <- if (yr <= 2002) "NAICS1997" else "NAICS2002"

  # Try to get employment, establishments, and payroll
  url <- paste0("https://api.census.gov/data/", yr,
                "/cbp?get=EMP,ESTAB,PAYANN,", naics_var,
                "&for=county:*&", naics_var, "=211",
                "&key=", census_key)
  cat("  Fetching CBP", yr, "NAICS 211...\n")
  resp <- GET(url, timeout(60))

  if (status_code(resp) == 200) {
    raw <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    df <- as_tibble(raw[-1, , drop = FALSE])
    names(df) <- raw[1, ]
    df$year <- yr
    df$fips <- paste0(df$state, df$county)
    cbp_all[[length(cbp_all) + 1]] <- df
    cat("    Counties with NAICS 211:", nrow(df), "\n")
  } else {
    cat("    WARNING: HTTP", status_code(resp), "for", yr, "\n")
  }
  Sys.sleep(0.5)
}

# Also fetch total employment for all counties (NAICS 00 = total)
cbp_total <- list()
for (yr in 2001:2005) {
  naics_var <- if (yr <= 2002) "NAICS1997" else "NAICS2002"
  url <- paste0("https://api.census.gov/data/", yr,
                "/cbp?get=EMP,ESTAB&for=county:*&", naics_var, "=00",
                "&key=", census_key)
  cat("  Fetching CBP", yr, "total employment...\n")
  resp <- GET(url, timeout(60))

  if (status_code(resp) == 200) {
    raw <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    df <- as_tibble(raw[-1, , drop = FALSE])
    names(df) <- raw[1, ]
    df$year <- yr
    df$fips <- paste0(df$state, df$county)
    cbp_total[[length(cbp_total) + 1]] <- df
    cat("    Total counties:", nrow(df), "\n")
  } else {
    cat("    WARNING: HTTP", status_code(resp), "\n")
  }
  Sys.sleep(0.5)
}

if (length(cbp_all) == 0) stop("FATAL: No CBP NAICS 211 data retrieved")
if (length(cbp_total) == 0) stop("FATAL: No CBP total employment data retrieved")

cbp_211 <- bind_rows(cbp_all)
cbp_tot <- bind_rows(cbp_total)

fwrite(cbp_211, file.path(data_dir, "cbp_naics211_counties.csv"))
fwrite(cbp_tot, file.path(data_dir, "cbp_total_counties.csv"))
cat("  Saved CBP data\n\n")


cat("=== 3. FRED — WTI Crude Oil Prices (Annual Average) ===\n")

fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) == 0) stop("FATAL: FRED_API_KEY not set")

fred_url <- paste0(
  "https://api.stlouisfed.org/fred/series/observations",
  "?series_id=DCOILWTICO",
  "&observation_start=1999-01-01",
  "&observation_end=2019-12-31",
  "&frequency=a",
  "&aggregation_method=avg",
  "&api_key=", fred_key,
  "&file_type=json"
)

resp <- GET(fred_url)
if (status_code(resp) != 200) stop("FATAL: FRED API returned HTTP ", status_code(resp))

oil <- fromJSON(content(resp, "text", encoding = "UTF-8"))$observations %>%
  as_tibble() %>%
  mutate(year = as.integer(substr(date, 1, 4)),
         wti_price = as.numeric(value)) %>%
  select(year, wti_price) %>%
  filter(!is.na(wti_price))

cat("  Oil price years:", nrow(oil), "\n")
cat("  Range: $", min(oil$wti_price), "- $", max(oil$wti_price), "\n")

fwrite(oil, file.path(data_dir, "fred_wti_annual.csv"))
cat("  Saved fred_wti_annual.csv\n\n")


cat("=== 4. BLS QCEW — Extended Employment Panel (2014-2019) ===\n")

# QCEW API works for 2014+; fetch for extended analysis
qcew_all <- list()
for (yr in 2014:2019) {
  url <- paste0("https://data.bls.gov/cew/data/api/", yr,
                "/a/industry/211.csv")
  cat("  Fetching QCEW", yr, "NAICS 211...\n")
  resp <- GET(url, timeout(60))

  if (status_code(resp) == 200) {
    tmp <- fread(content(resp, "text", encoding = "UTF-8"))
    # Keep only county-level rows (5-digit area_fips, private ownership)
    tmp <- tmp[nchar(area_fips) == 5 & own_code == 5 & agglvl_code == 75]
    tmp$fetch_year <- yr
    qcew_all[[length(qcew_all) + 1]] <- tmp
    cat("    County rows:", nrow(tmp), "\n")
  } else {
    cat("    WARNING: HTTP", status_code(resp), "\n")
  }
  Sys.sleep(1)
}

if (length(qcew_all) > 0) {
  qcew_df <- bind_rows(qcew_all)
  fwrite(qcew_df, file.path(data_dir, "qcew_naics211_2014_2019.csv"))
  cat("  Saved qcew_naics211_2014_2019.csv — rows:", nrow(qcew_df), "\n\n")
} else {
  cat("  WARNING: No QCEW data retrieved\n\n")
}


cat("=== All data fetched successfully ===\n")
cat("Files in data/:\n")
cat(paste("  ", list.files(data_dir), collapse = "\n"), "\n")
