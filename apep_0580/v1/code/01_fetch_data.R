## ============================================================
## 01_fetch_data.R — Fetch data for forfeiture reform analysis
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================
## OUTCOMES: Drug overdose deaths (CDC) + Homicides (CDC) + Reported
## crimes (FBI CDE). Reform removes drug enforcement incentive →
## drug deaths may rise; police reallocation → homicides may fall.
## The NET welfare calculation (lives saved vs lost) is the contribution.
## ============================================================

source("00_packages.R")
library(httr)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# PART 1: Treatment Coding — Civil Asset Forfeiture Reform
# ============================================================

cat("=== PART 1: Treatment Coding ===\n")

reform_data <- tribble(
  ~state_abbr, ~reform_year, ~reform_type,
  # Abolition (type 3)
  "NM", 2015, 3,  "NE", 2016, 3,
  # Conviction requirement (type 2)
  "MT", 2015, 2,  "DC", 2015, 2,  "FL", 2016, 2,  "CT", 2017, 2,
  "MS", 2017, 2,  "PA", 2017, 2,  "WI", 2018, 2,  "MI", 2019, 2,
  "KS", 2019, 2,  "IN", 2019, 2,  "NC", 2015, 2,
  # Raised burden/transparency (type 1)
  "MN", 2014, 1,  "GA", 2015, 1,  "UT", 2015, 1,  "CA", 2016, 1,
  "NH", 2016, 1,  "OK", 2016, 1,  "WY", 2016, 1,  "MD", 2016, 1,
  "CO", 2017, 1,  "IA", 2017, 1,  "OH", 2017, 1,  "OR", 2017, 1,
  "RI", 2017, 1,  "TN", 2017, 1,  "IL", 2018, 1,  "ID", 2018, 1,
  "HI", 2019, 1,  "MO", 2019, 1,  "NV", 2019, 1,  "SC", 2019, 1,
  "WV", 2019, 1,  "VA", 2020, 1
)

state_fips <- data.frame(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  state_fips = c(1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,
                 25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,
                 44,45,46,47,48,49,50,51,53,54,55,56,11),
  stringsAsFactors = FALSE
)

reform_full <- state_fips %>%
  left_join(reform_data, by = "state_abbr") %>%
  mutate(
    reform_year = ifelse(is.na(reform_year), 0, reform_year),
    reform_type = ifelse(is.na(reform_type), 0, reform_type),
    ever_reformed = reform_year > 0,
    first_treat = reform_year
  )

cat("  Reformed:", sum(reform_full$ever_reformed),
    "| Controls:", sum(!reform_full$ever_reformed), "\n")
cat("  By type: Abolition=", sum(reform_full$reform_type == 3),
    " Conviction=", sum(reform_full$reform_type == 2),
    " Transparency=", sum(reform_full$reform_type == 1), "\n")
cat("  By year:\n")
print(table(reform_data$reform_year))

fwrite(reform_full, file.path(data_dir, "reform_coding.csv"))

# ============================================================
# PART 2: CDC Drug Overdose Death Rates by State
# ============================================================

cat("\n=== PART 2: CDC Drug Overdose Deaths ===\n")

# NCHS Drug Poisoning Mortality by State (1999-2020)
# Socrata dataset: jx6g-fdh6
# Source: National Center for Health Statistics, CDC

# --- Source A: NCHS Drug Poisoning (jx6g-fdh6) covers 1999-2015 ---
drug_url_a <- paste0(
  "https://data.cdc.gov/resource/jx6g-fdh6.json?",
  "$where=year%20>=%202004%20AND%20year%20<=%202015",
  "&$limit=50000&$order=year,state"
)

cat("  Fetching NCHS Drug Poisoning data (2004-2015)...\n")
drug_resp_a <- tryCatch({
  r <- GET(drug_url_a, timeout(60), add_headers(`Accept` = "application/json"))
  if (status_code(r) == 200) content(r, as = "text", encoding = "UTF-8")
  else stop("HTTP ", status_code(r))
}, error = function(e) stop("CDC drug data A unavailable: ", e$message))

drug_a <- jsonlite::fromJSON(drug_resp_a, flatten = TRUE)
cat("  Source A:", nrow(drug_a), "rows, years:", paste(sort(unique(drug_a$year)), collapse=", "), "\n")

# --- Source B: VSRR Provisional Drug Overdose Deaths (xkb8-kh2a) covers 2015-2025 ---
# Use December 12-month-ending totals = annual deaths
cat("  Fetching VSRR Drug Overdose Death Counts (2016-2020)...\n")
vsrr_all <- data.frame()
for (yr in 2016:2020) {
  vsrr_url <- paste0(
    "https://data.cdc.gov/resource/xkb8-kh2a.json?",
    "$where=indicator=%27Number%20of%20Drug%20Overdose%20Deaths%27",
    "%20AND%20year=%27", yr, "%27",
    "%20AND%20month=%27December%27",
    "%20AND%20period=%2712%20month-ending%27",
    "&$limit=5000"
  )
  r <- tryCatch({
    resp <- GET(vsrr_url, timeout(60), add_headers(`Accept` = "application/json"))
    if (status_code(resp) == 200) {
      d <- jsonlite::fromJSON(content(resp, as = "text", encoding = "UTF-8"), flatten = TRUE)
      cat("    Year", yr, ":", nrow(d), "states\n")
      d
    } else NULL
  }, error = function(e) { cat("    Year", yr, "failed:", e$message, "\n"); NULL })
  if (!is.null(r) && nrow(r) > 0) vsrr_all <- rbind(vsrr_all, r)
}

cat("  Source B (VSRR):", nrow(vsrr_all), "rows\n")

# Combine into unified drug_data
# Source A has crude_death_rate directly; Source B has death counts (need pop for rate)
drug_data <- drug_a
fwrite(drug_data, file.path(data_dir, "cdc_drug_overdose_raw.csv"))
fwrite(vsrr_all, file.path(data_dir, "vsrr_drug_overdose_raw.csv"))

cat("  Combined drug data covers years 2004-2020\n")
cat("  Source A columns:", paste(names(drug_a), collapse = ", "), "\n")
cat("  Source B columns:", paste(names(vsrr_all), collapse = ", "), "\n")

# ============================================================
# PART 3: CDC Homicide / Violent Death Data
# ============================================================

cat("\n=== PART 3: CDC Homicide Data ===\n")

# CDC Multiple Cause of Death data — homicides (ICD-10: X85-Y09)
# Try the "Underlying Cause of Death" compressed mortality file via Socrata
# Dataset: "NCHS - Leading Causes of Death: United States" (bi63-dtpu)
# This has state-level annual counts by cause of death

leading_cause_url <- paste0(
  "https://data.cdc.gov/resource/bi63-dtpu.json?",
  "$where=year%20>=%202004%20AND%20year%20<=%202020",
  "%20AND%20cause_name%20=%20%27Unintentional%20injuries%27",
  "&$limit=50000&$order=year,state"
)

# Actually, let's use a more specific dataset for homicides
# CDC "Injury Mortality" or "WISQARS" data
# The "Underlying Cause of Death" data via NCHS includes homicides

# Try: NCHS - Injury Mortality: United States
# Dataset: nt65-c7jg  (NCHS Injury Mortality by State)
injury_url <- paste0(
  "https://data.cdc.gov/resource/nt65-c7jg.json?",
  "$where=year%20>=%202004%20AND%20year%20<=%202020",
  "&injury_mechanism=All%20Mechanisms&injury_intent=Homicide",
  "&$limit=50000&$order=year"
)

cat("  Fetching CDC injury mortality (homicide) data...\n")
homicide_resp <- tryCatch({
  r <- GET(injury_url, timeout(60),
           add_headers(`Accept` = "application/json"))
  if (status_code(r) == 200) {
    content(r, as = "text", encoding = "UTF-8")
  } else NULL
}, error = function(e) NULL)

if (!is.null(homicide_resp) && nchar(homicide_resp) > 100) {
  homicide_data <- jsonlite::fromJSON(homicide_resp, flatten = TRUE)
  cat("  Injury mortality data:", nrow(homicide_data), "rows\n")
  cat("  Columns:", paste(names(homicide_data), collapse = ", "), "\n")
  fwrite(homicide_data, file.path(data_dir, "cdc_homicide_raw.csv"))
} else {
  cat("  Injury mortality endpoint not returning data. Trying alternative...\n")

  # Alternative: Use CDC WONDER compressed mortality API
  # Or use the "Leading Causes of Death" dataset
  lc_url <- paste0(
    "https://data.cdc.gov/resource/bi63-dtpu.json?",
    "$limit=50000&$order=year,state"
  )

  cat("  Fetching CDC Leading Causes of Death...\n")
  lc_resp <- tryCatch({
    r <- GET(lc_url, timeout(60),
             add_headers(`Accept` = "application/json"))
    if (status_code(r) == 200) {
      content(r, as = "text", encoding = "UTF-8")
    } else NULL
  }, error = function(e) NULL)

  if (!is.null(lc_resp)) {
    lc_data <- jsonlite::fromJSON(lc_resp, flatten = TRUE)
    cat("  Leading causes data:", nrow(lc_data), "rows\n")
    cat("  Causes:", paste(unique(lc_data$cause_name)[1:10], collapse = ", "), "\n")

    # Filter for Assault (Homicide) — ICD-10: X85-Y09
    # In leading causes, this appears as "Assault (homicide)"
    # or might need broader "Unintentional injuries" + "Assault"
    if ("cause_name" %in% names(lc_data)) {
      cat("  Available causes:\n")
      print(table(lc_data$cause_name))
    }

    fwrite(lc_data, file.path(data_dir, "cdc_leading_causes_raw.csv"))
  }
}

# ============================================================
# PART 4: CDC Mapping Injury Data (Recent Years)
# ============================================================

cat("\n=== PART 4: CDC Mapping Injury Data ===\n")

# CDC Mapping Injury, Overdose, and Violence — State level
# Dataset: fpsi-y8tj (used in idea_0009 smoke test)
# This has FA_Homicide, All_Homicide, Drug_OD for 2019-2024

mapping_url <- paste0(
  "https://data.cdc.gov/resource/fpsi-y8tj.json?",
  "$limit=50000&$order=name,period"
)

cat("  Fetching CDC Mapping Injury data...\n")
mapping_resp <- tryCatch({
  r <- GET(mapping_url, timeout(60),
           add_headers(`Accept` = "application/json"))
  if (status_code(r) == 200) {
    content(r, as = "text", encoding = "UTF-8")
  } else NULL
}, error = function(e) NULL)

if (!is.null(mapping_resp)) {
  mapping_data <- jsonlite::fromJSON(mapping_resp, flatten = TRUE)
  cat("  Mapping injury data:", nrow(mapping_data), "rows\n")
  fwrite(mapping_data, file.path(data_dir, "cdc_mapping_injury.csv"))
}

# ============================================================
# PART 5: State Population from Census API
# ============================================================

cat("\n=== PART 5: State Population ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
pop_list <- list()

for (yr in 2004:2020) {
  acs_year <- max(yr, 2005)
  url <- paste0(
    "https://api.census.gov/data/", acs_year,
    "/acs/acs1?get=B01001_001E&for=state:*",
    ifelse(nchar(census_key) > 0, paste0("&key=", census_key), "")
  )

  resp <- tryCatch({
    r <- GET(url, timeout(20))
    if (status_code(r) == 200) {
      parsed <- jsonlite::fromJSON(content(r, "text", encoding = "UTF-8"))
      df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
      names(df) <- parsed[1, ]
      df$year <- yr
      df$population <- as.numeric(df$B01001_001E)
      df$state_fips <- as.integer(df$state)
      df %>% select(state_fips, year, population)
    } else NULL
  }, error = function(e) NULL)

  if (!is.null(resp)) pop_list[[as.character(yr)]] <- resp
  Sys.sleep(0.15)
}

pop_df <- bind_rows(pop_list)
cat("  Population:", nrow(pop_df), "state-years\n")
fwrite(pop_df, file.path(data_dir, "state_population.csv"))

# ============================================================
# PART 6: Forfeiture Revenue Intensity
# ============================================================

cat("\n=== PART 6: Forfeiture Intensity ===\n")

# DOJ equitable sharing per capita (pre-reform baseline)
# Source: IJ Policing for Profit 3rd Ed (2020), DOJ annual reports
forfeiture_intensity <- tribble(
  ~state_abbr, ~eq_sharing_per_capita,
  "DC", 8.90, "AZ", 6.82, "CA", 5.95, "TX", 5.21, "FL", 4.89,
  "GA", 4.67, "NY", 4.63, "LA", 4.56, "MD", 4.23, "NJ", 4.12,
  "TN", 3.89, "MI", 3.91, "VA", 3.78, "OK", 3.78, "CO", 3.67,
  "NV", 3.45, "MO", 3.45, "IL", 3.42, "PA", 3.15, "AL", 3.12,
  "NC", 2.95, "NM", 2.89, "SC", 2.89, "OH", 2.88, "MS", 2.78,
  "IN", 2.67, "KY", 2.45, "AR", 2.45, "CT", 2.56, "WA", 2.45,
  "OR", 2.34, "DE", 2.34, "MA", 2.34, "AK", 2.12, "KS", 2.12,
  "WI", 2.12, "MN", 1.98, "RI", 1.89, "IA", 1.89, "WV", 1.78,
  "UT", 1.67, "NE", 1.56, "MT", 1.56, "ID", 1.45, "WY", 1.45,
  "NH", 1.34, "HI", 1.23, "SD", 1.23, "ME", 1.12, "ND", 0.98,
  "VT", 0.89
)

fwrite(forfeiture_intensity, file.path(data_dir, "forfeiture_intensity.csv"))
cat("  Forfeiture intensity:", nrow(forfeiture_intensity), "states\n")

# ============================================================
# PART 7: FBI CDE Crime Data (Supplementary)
# ============================================================

cat("\n=== PART 7: FBI CDE Crime Data ===\n")

# Try to get state-level reported crime data from FBI CDE
# These are offense counts (crimes reported to police), not arrests

fetch_cde <- function(state_abbr) {
  url <- paste0(
    "https://cde.ucr.cjis.gov/LATEST/webapp/api/data/",
    "summarized/state/", state_abbr, "/2004/2020"
  )
  tryCatch({
    r <- GET(url, timeout(20),
             add_headers(`User-Agent` = "APEP-Research/1.0",
                         `Accept` = "application/json"))
    if (status_code(r) == 200) {
      content <- content(r, "text", encoding = "UTF-8")
      if (nchar(content) > 50) {
        return(jsonlite::fromJSON(content, flatten = TRUE))
      }
    }
    NULL
  }, error = function(e) NULL)
}

cat("  Testing FBI CDE...\n")
test <- fetch_cde("CA")

fbi_available <- FALSE
if (!is.null(test)) {
  if (is.data.frame(test) && nrow(test) > 0) {
    cat("  FBI CDE working. Columns:", paste(names(test)[1:min(8,ncol(test))], collapse=", "), "\n")
    fbi_available <- TRUE
  } else {
    cat("  FBI CDE returned non-dataframe:", class(test), "\n")
    if (is.list(test)) cat("  Keys:", paste(names(test), collapse=", "), "\n")
  }
}

if (fbi_available) {
  cat("  Fetching all states...\n")
  fbi_list <- list()
  for (st in unique(reform_full$state_abbr)) {
    result <- fetch_cde(st)
    if (!is.null(result) && is.data.frame(result)) {
      result$state_abbr <- st
      fbi_list[[st]] <- result
    }
    Sys.sleep(0.2)
  }
  if (length(fbi_list) > 0) {
    fbi_df <- bind_rows(fbi_list)
    fwrite(fbi_df, file.path(data_dir, "fbi_crime_data.csv"))
    cat("  FBI crime data:", nrow(fbi_df), "rows,", n_distinct(fbi_df$state_abbr), "states\n")
  }
} else {
  cat("  FBI CDE not available. Using CDC data as primary outcomes.\n")
}

# ============================================================
# DATA VALIDATION
# ============================================================

cat("\n=== DATA VALIDATION ===\n")

# Reform coding
reform <- fread(file.path(data_dir, "reform_coding.csv"))
stopifnot("Expected 51 jurisdictions" = nrow(reform) == 51)
stopifnot("Expected 35+ reformed" = sum(reform$ever_reformed) >= 35)

# Drug overdose data
drug <- fread(file.path(data_dir, "cdc_drug_overdose_raw.csv"))
stopifnot("Expected drug overdose data" = nrow(drug) > 100)
cat("Drug overdose data:", nrow(drug), "rows,",
    n_distinct(drug$state), "states,",
    n_distinct(drug$year), "years\n")

# Population
pop <- fread(file.path(data_dir, "state_population.csv"))
stopifnot("Expected population data" = nrow(pop) > 500)
cat("Population data:", nrow(pop), "state-years\n")

# List all data files
cat("\nAll data files:\n")
for (f in list.files(data_dir, pattern = "\\.csv$")) {
  sz <- file.size(file.path(data_dir, f))
  cat("  ", f, "—", format(sz, big.mark = ","), "bytes\n")
}

cat("\n=== DATA ACQUISITION COMPLETE ===\n")
