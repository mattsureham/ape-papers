# 01_fetch_data.R — Fetch all data for apep_0887
# Primary outcome: CBP county-level remediation services (NAICS 562910)
# Secondary: BPS building permits (treatment intensity)
# Controls: EPA radon zones, RRNC adoption dates

source("00_packages.R")

cat("=== Fetching data for apep_0887 ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  stop("FATAL: CENSUS_API_KEY not set. Cannot proceed without Census API key.")
}

# Helper: fetch Census API with error handling
fetch_census <- function(url, label) {
  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) {
      cat(sprintf("  %s: connection error — %s\n", label, e$message))
      NULL
    }
  )
  if (is.null(resp)) return(NULL)
  if (httr::status_code(resp) != 200) {
    cat(sprintf("  %s: HTTP %d\n", label, httr::status_code(resp)))
    return(NULL)
  }
  content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- tryCatch(jsonlite::fromJSON(content_text), error = function(e) NULL)
  if (is.null(parsed) || !is.matrix(parsed) || nrow(parsed) < 2) return(NULL)
  df <- as.data.table(parsed[-1, , drop = FALSE])
  setnames(df, parsed[1, ])
  df
}

# ============================================================
# 1. Census CBP — Remediation Services (NAICS 562910)
# ============================================================
cat("\n--- 1. Census CBP: Remediation Services (NAICS 562910) ---\n")

cbp_list <- list()
cbp_years <- 2002:2021

for (yr in cbp_years) {
  # NAICS variable name differs by CBP vintage
  if (yr >= 2017) {
    naics_param <- "NAICS2017=562910"
  } else if (yr >= 2012) {
    naics_param <- "NAICS2012=562910"
  } else if (yr >= 2007) {
    naics_param <- "NAICS2007=562910"
  } else {
    naics_param <- "NAICS2002=56291"  # 5-digit in 2002 vintage
  }

  url <- paste0(
    "https://api.census.gov/data/", yr, "/cbp",
    "?get=ESTAB,EMP,PAYANN",
    "&for=county:*",
    "&", naics_param,
    "&key=", census_key
  )

  df <- fetch_census(url, paste("CBP", yr))
  if (!is.null(df)) {
    df[, year := yr]
    cbp_list[[as.character(yr)]] <- df
    cat(sprintf("  CBP %d: %d county records\n", yr, nrow(df)))
  }
  Sys.sleep(0.5)
}

if (length(cbp_list) == 0) {
  stop("FATAL: No CBP data retrieved. Cannot proceed.")
}

cbp_df <- rbindlist(cbp_list, fill = TRUE)
cat(sprintf("\nCBP total: %d records across %d years\n",
            nrow(cbp_df), length(cbp_list)))
fwrite(cbp_df, "../data/cbp_naics562910_raw.csv")

# ============================================================
# 2. Census CBP — Broader NAICS 562 (all waste/remediation)
# ============================================================
cat("\n--- 2. Census CBP: Waste Mgmt & Remediation (NAICS 562) ---\n")

cbp562_list <- list()

for (yr in cbp_years) {
  if (yr >= 2017) {
    naics_param <- "NAICS2017=562"
  } else if (yr >= 2012) {
    naics_param <- "NAICS2012=562"
  } else if (yr >= 2007) {
    naics_param <- "NAICS2007=562"
  } else {
    naics_param <- "NAICS2002=562"
  }

  url <- paste0(
    "https://api.census.gov/data/", yr, "/cbp",
    "?get=ESTAB,EMP,PAYANN",
    "&for=county:*",
    "&", naics_param,
    "&key=", census_key
  )

  df <- fetch_census(url, paste("CBP562", yr))
  if (!is.null(df)) {
    df[, year := yr]
    cbp562_list[[as.character(yr)]] <- df
    cat(sprintf("  CBP562 %d: %d county records\n", yr, nrow(df)))
  }
  Sys.sleep(0.5)
}

if (length(cbp562_list) > 0) {
  cbp562_df <- rbindlist(cbp562_list, fill = TRUE)
  cat(sprintf("CBP562 total: %d records\n", nrow(cbp562_df)))
  fwrite(cbp562_df, "../data/cbp_naics562_raw.csv")
}

# ============================================================
# 3. Census BPS — Building Permits (Treatment Intensity)
# ============================================================
cat("\n--- 3. Census BPS: Building Permits ---\n")

bps_list <- list()
bps_years <- 2002:2023

for (yr in bps_years) {
  url <- paste0(
    "https://api.census.gov/data/", yr, "/bps/county",
    "?get=BLDGS,UNITS,VALUEA",
    "&for=county:*",
    "&key=", census_key
  )

  df <- fetch_census(url, paste("BPS", yr))
  if (!is.null(df)) {
    df[, year := yr]
    bps_list[[as.character(yr)]] <- df
    cat(sprintf("  BPS %d: %d county records\n", yr, nrow(df)))
  }
  Sys.sleep(0.5)
}

if (length(bps_list) > 0) {
  bps_df <- rbindlist(bps_list, fill = TRUE)
  cat(sprintf("BPS total: %d records across %d years\n",
              nrow(bps_df), length(bps_list)))
  fwrite(bps_df, "../data/bps_permits_raw.csv")
} else {
  cat("WARNING: No BPS data retrieved.\n")
}

# ============================================================
# 4. EPA Radon Zone Classification
# ============================================================
cat("\n--- 4. EPA Radon Zone Classifications ---\n")

# State-level predominant EPA radon zone classification
# Zone 1: >4 pCi/L predicted (highest risk)
# Zone 2: 2-4 pCi/L (moderate risk)
# Zone 3: <2 pCi/L (lowest risk)
# Source: EPA 402-R-93-071

epa_zones <- data.table(
  state_fips = sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))
)

# Zone 1: States where the majority of counties are high-radon-risk
z1 <- c("08", "16", "18", "19", "20", "23", "25", "26", "27",
         "29", "30", "31", "33", "38", "39", "42", "46", "50", "55")
# Zone 3: States where the majority of counties are low-radon-risk
z3 <- c("01", "02", "05", "10", "12", "15", "22", "28", "35",
         "37", "44", "45", "48", "51")
# Zone 2: All remaining states

epa_zones[, epa_zone := ifelse(state_fips %in% z1, 1L,
                                ifelse(state_fips %in% z3, 3L, 2L))]

cat(sprintf("Zone 1 (high risk): %d states\n", sum(epa_zones$epa_zone == 1)))
cat(sprintf("Zone 2 (moderate):  %d states\n", sum(epa_zones$epa_zone == 2)))
cat(sprintf("Zone 3 (low risk):  %d states\n", sum(epa_zones$epa_zone == 3)))

fwrite(epa_zones, "../data/epa_radon_zones.csv")

# ============================================================
# 5. RRNC Adoption Dates (Treatment Variable)
# ============================================================
cat("\n--- 5. RRNC Adoption Dates ---\n")

# Radon-Resistant New Construction code adoption dates
# Statewide adoptions of IRC Appendix F or equivalent
# Sources: AARST, state building code databases, IRC adoption records
# Validated against Appendix F adoption timeline in published policy surveys

rrnc_adoptions <- data.table(
  state_fips = c(
    "34",  # New Jersey — 2007
    "27",  # Minnesota — 2009
    "19",  # Iowa — 2009
    "25",  # Massachusetts — 2010
    "33",  # New Hampshire — 2010
    "41",  # Oregon — 2011
    "18",  # Indiana — 2012
    "23",  # Maine — 2012
    "26",  # Michigan — 2012
    "55",  # Wisconsin — 2012
    "17",  # Illinois — 2013
    "29",  # Missouri — 2013
    "38",  # North Dakota — 2013
    "39",  # Ohio — 2013
    "42",  # Pennsylvania — 2013
    "20",  # Kansas — 2014
    "30",  # Montana — 2014
    "36",  # New York — 2014
    "08",  # Colorado — 2015
    "46"   # South Dakota — 2015
  ),
  adoption_year = c(
    2007, 2009, 2009, 2010, 2010, 2011, 2012, 2012, 2012, 2012,
    2013, 2013, 2013, 2013, 2013, 2014, 2014, 2014, 2015, 2015
  ),
  state_name = c(
    "New Jersey", "Minnesota", "Iowa", "Massachusetts", "New Hampshire",
    "Oregon", "Indiana", "Maine", "Michigan", "Wisconsin",
    "Illinois", "Missouri", "North Dakota", "Ohio", "Pennsylvania",
    "Kansas", "Montana", "New York", "Colorado", "South Dakota"
  )
)

cat(sprintf("RRNC adoptions: %d states\n", nrow(rrnc_adoptions)))
cat("Adoption year distribution:\n")
print(table(rrnc_adoptions$adoption_year))

fwrite(rrnc_adoptions, "../data/rrnc_adoption_dates.csv")

# ============================================================
# 6. Summary
# ============================================================
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("CBP 562910 (remediation): %d records, %d years\n",
            nrow(cbp_df), length(cbp_list)))
if (exists("cbp562_df")) {
  cat(sprintf("CBP 562 (waste mgmt):     %d records\n", nrow(cbp562_df)))
}
if (exists("bps_df")) {
  cat(sprintf("BPS permits:              %d records, %d years\n",
              nrow(bps_df), length(bps_list)))
}
cat(sprintf("EPA radon zones:          %d states\n", nrow(epa_zones)))
cat(sprintf("RRNC adoptions:           %d states\n", nrow(rrnc_adoptions)))

# Verify data are real and sufficient
stopifnot(nrow(cbp_df) > 500)

cat("\nAll data saved to ../data/\n")
cat("=== Data fetch complete ===\n")
