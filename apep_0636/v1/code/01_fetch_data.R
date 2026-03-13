## 01_fetch_data.R — Fetch pharmacy and population data from Census APIs
## APEP-0636: PBM Spread Pricing Bans and Community Pharmacy Survival
##
## Data sources:
##   1. Census County Business Patterns (CBP) — NAICS 446110 (Pharmacies)
##   2. Census ACS 1-year population estimates

source("00_packages.R")

cat("=== Fetching data for APEP-0636 ===\n")

# ─── Census API key ─────────────────────────────────────────────────────────
census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  env_candidates <- c(
    file.path(dirname(dirname(dirname(dirname(getwd())))), ".env"),
    file.path(dirname(dirname(dirname(getwd()))), ".env"),
    file.path(dirname(dirname(getwd())), ".env")
  )
  for (ef in env_candidates) {
    if (file.exists(ef)) {
      lines <- readLines(ef, warn = FALSE)
      for (l in lines) {
        if (grepl("^CENSUS_API_KEY=", l)) {
          census_key <- sub("^CENSUS_API_KEY=", "", l)
          census_key <- gsub("[\"']", "", census_key)
        }
      }
      if (nchar(census_key) > 0) break
    }
  }
}
stopifnot("Census API key not found" = nchar(census_key) > 0)
cat("Census API key loaded.\n")

# ─── Valid US state FIPS codes (50 states + DC) ─────────────────────────────
valid_fips <- c("01","02","04","05","06","08","09","10","11","12",
                "13","15","16","17","18","19","20","21","22","23",
                "24","25","26","27","28","29","30","31","32","33",
                "34","35","36","37","38","39","40","41","42","44",
                "45","46","47","48","49","50","51","53","54","55","56")

# ─── 1. County Business Patterns: Pharmacy establishments ───────────────────
cat("\n--- Fetching CBP data (NAICS 446110, 2012-2022) ---\n")

cbp_rows <- list()
for (yr in 2012:2022) {
  cat(sprintf("  CBP %d...", yr))
  naics_var <- if (yr <= 2016) "NAICS2012" else "NAICS2017"
  base_url <- sprintf("https://api.census.gov/data/%d/cbp", yr)

  url <- sprintf("%s?get=ESTAB,EMP,PAYANN&for=state:*&%s=446110&EMPSZES=001&key=%s",
                 base_url, naics_var, census_key)
  resp <- GET(url)

  if (status_code(resp) != 200) {
    alt_var <- if (naics_var == "NAICS2012") "NAICS2017" else "NAICS2012"
    url <- sprintf("%s?get=ESTAB,EMP,PAYANN&for=state:*&%s=446110&EMPSZES=001&key=%s",
                   base_url, alt_var, census_key)
    resp <- GET(url)
  }
  if (status_code(resp) != 200) {
    url <- sprintf("%s?get=ESTAB,EMP,PAYANN&for=state:*&%s=446110&key=%s",
                   base_url, naics_var, census_key)
    resp <- GET(url)
  }
  if (status_code(resp) != 200) stop(sprintf("CBP %d failed (HTTP %d)", yr, status_code(resp)))

  raw <- fromJSON(content(resp, "text"))
  df_yr <- as.data.frame(raw[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df_yr) <- raw[1, ]
  df_yr$year <- yr
  # Filter to valid US states only
  df_yr <- df_yr[df_yr$state %in% valid_fips, ]
  cbp_rows[[as.character(yr)]] <- df_yr
  cat(sprintf(" %d rows\n", nrow(df_yr)))
  Sys.sleep(0.5)
}

cbp_raw <- bind_rows(cbp_rows)
cat(sprintf("CBP total: %d rows (%d states x %d years)\n",
            nrow(cbp_raw), n_distinct(cbp_raw$state), n_distinct(cbp_raw$year)))

# ─── 2. Population estimates (ACS 1-year) ──────────────────────────────────
cat("\n--- Fetching ACS 1-year population (2012-2022) ---\n")

pop_rows <- list()
for (yr in 2012:2022) {
  if (yr == 2020) {
    cat("  ACS 2020... skipped (COVID, no 1-year release)\n")
    next
  }
  cat(sprintf("  ACS %d...", yr))
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=B01003_001E&for=state:*&key=%s",
    yr, census_key
  )
  resp <- GET(url)
  if (status_code(resp) == 200) {
    raw <- fromJSON(content(resp, "text"))
    df_yr <- as.data.frame(raw[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df_yr) <- raw[1, ]
    df_yr <- df_yr %>% rename(POP = B01003_001E)
    df_yr$year <- yr
    df_yr <- df_yr[df_yr$state %in% valid_fips, ]
    pop_rows[[as.character(yr)]] <- df_yr
    cat(sprintf(" %d rows\n", nrow(df_yr)))
  } else {
    cat(sprintf(" failed (HTTP %d)\n", status_code(resp)))
  }
  Sys.sleep(0.3)
}

pop_raw <- bind_rows(pop_rows)

# Interpolate 2020
if ("2019" %in% names(pop_rows) && "2021" %in% names(pop_rows)) {
  cat("  Interpolating 2020 from 2019+2021...\n")
  p19 <- pop_rows[["2019"]] %>% mutate(POP = as.numeric(POP))
  p21 <- pop_rows[["2021"]] %>% mutate(POP = as.numeric(POP))
  p20 <- p19 %>%
    left_join(p21 %>% select(state, POP21 = POP), by = "state") %>%
    mutate(POP = as.character(round((POP + POP21) / 2)), year = 2020L) %>%
    select(-POP21)
  pop_raw <- bind_rows(pop_raw, p20)
}

cat(sprintf("Population total: %d rows\n", nrow(pop_raw)))

# ─── Save raw data ──────────────────────────────────────────────────────────
dir.create("../data", showWarnings = FALSE)
saveRDS(cbp_raw, "../data/cbp_raw.rds")
saveRDS(pop_raw, "../data/pop_raw.rds")

cat("\n=== Data fetch complete ===\n")
cat(sprintf("CBP: %d state-year observations\n", nrow(cbp_raw)))
cat(sprintf("POP: %d state-year observations\n", nrow(pop_raw)))
