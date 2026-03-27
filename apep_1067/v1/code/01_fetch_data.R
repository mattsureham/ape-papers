## 01_fetch_data.R — Download National Bridge Inventory data from FHWA
## APEP Working Paper apep_1067

source("00_packages.R")

# NBI delimited files URL pattern
# Pre-2015: https://www.fhwa.dot.gov/bridge/nbi/{YEAR}/delimited/{ST}{YY}.txt
# 2015+: same pattern but some URL variations
# State abbreviations for NBI files
state_codes <- c(
  "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
  "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
  "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","PR",
  "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV",
  "WI","WY"
)

# FIPS codes mapping for NBI files
state_fips <- c(
  "01","02","04","05","06","08","09","10","11","12",
  "13","15","16","17","18","19","20","21","22","23",
  "24","25","26","27","28","29","30","31","32","33",
  "34","35","36","37","38","39","40","41","42","72",
  "44","45","46","47","48","49","50","51","53","54",
  "55","56"
)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Download NBI files for years 2000-2018
# NBI sufficiency rating was dropped in 2019
years <- 2000:2018

download_nbi_year <- function(year) {
  yy <- sprintf("%02d", year %% 100)
  yyyy <- as.character(year)

  all_records <- list()

  for (i in seq_along(state_codes)) {
    st <- state_codes[i]
    fips <- state_fips[i]

    # NBI URL patterns changed over time
    url <- paste0("https://www.fhwa.dot.gov/bridge/nbi/", yyyy, "/delimited/", st, yy, ".txt")

    tryCatch({
      # Read the delimited file (comma-separated with fixed-width elements)
      raw <- fread(url, sep = ",", header = TRUE, fill = TRUE,
                   select = c("STATE_CODE_001", "STRUCTURE_NUMBER_008",
                              "COUNTY_CODE_003", "OWNER_022",
                              "YEAR_BUILT_027", "ADT_029",
                              "DECK_COND_058", "SUPERSTRUCTURE_COND_059",
                              "SUBSTRUCTURE_COND_060", "SUFFICIENCY_RATING"),
                   showProgress = FALSE)

      if (nrow(raw) > 0) {
        raw$year <- year
        all_records[[length(all_records) + 1]] <- raw
      }
    }, error = function(e) {
      # Try alternative column names (NBI format varies by year)
      tryCatch({
        raw <- fread(url, sep = ",", header = TRUE, fill = TRUE, showProgress = FALSE)

        # Find sufficiency rating column (name varies)
        sr_col <- grep("SUFFICIENCY|SUFF", names(raw), value = TRUE, ignore.case = TRUE)
        state_col <- grep("STATE_CODE|STATE", names(raw), value = TRUE, ignore.case = TRUE)[1]
        struct_col <- grep("STRUCTURE_NUMBER|STRUCTURE", names(raw), value = TRUE, ignore.case = TRUE)[1]
        county_col <- grep("COUNTY_CODE|COUNTY", names(raw), value = TRUE, ignore.case = TRUE)[1]
        owner_col <- grep("OWNER", names(raw), value = TRUE, ignore.case = TRUE)[1]
        year_built_col <- grep("YEAR_BUILT", names(raw), value = TRUE, ignore.case = TRUE)[1]
        adt_col <- grep("ADT_029|^ADT", names(raw), value = TRUE, ignore.case = TRUE)[1]
        deck_col <- grep("DECK_COND", names(raw), value = TRUE, ignore.case = TRUE)[1]
        super_col <- grep("SUPERSTRUCTURE", names(raw), value = TRUE, ignore.case = TRUE)[1]
        sub_col <- grep("SUBSTRUCTURE_COND", names(raw), value = TRUE, ignore.case = TRUE)[1]

        if (length(sr_col) > 0 && nrow(raw) > 0) {
          selected <- data.table(
            STATE_CODE_001 = if (!is.null(state_col) && !is.na(state_col)) raw[[state_col]] else fips,
            STRUCTURE_NUMBER_008 = if (!is.null(struct_col) && !is.na(struct_col)) raw[[struct_col]] else NA,
            COUNTY_CODE_003 = if (!is.null(county_col) && !is.na(county_col)) raw[[county_col]] else NA,
            OWNER_022 = if (!is.null(owner_col) && !is.na(owner_col)) raw[[owner_col]] else NA,
            YEAR_BUILT_027 = if (!is.null(year_built_col) && !is.na(year_built_col)) raw[[year_built_col]] else NA,
            ADT_029 = if (!is.null(adt_col) && !is.na(adt_col)) raw[[adt_col]] else NA,
            DECK_COND_058 = if (!is.null(deck_col) && !is.na(deck_col)) raw[[deck_col]] else NA,
            SUPERSTRUCTURE_COND_059 = if (!is.null(super_col) && !is.na(super_col)) raw[[super_col]] else NA,
            SUBSTRUCTURE_COND_060 = if (!is.null(sub_col) && !is.na(sub_col)) raw[[sub_col]] else NA,
            SUFFICIENCY_RATING = raw[[sr_col[1]]],
            year = year
          )
          all_records[[length(all_records) + 1]] <- selected
        } else {
          cat("  WARNING: No sufficiency rating column found for", st, year, "\n")
        }
      }, error = function(e2) {
        cat("  FAILED:", st, year, "-", conditionMessage(e2), "\n")
      })
    })
  }

  if (length(all_records) > 0) {
    dt <- rbindlist(all_records, fill = TRUE)
    cat(sprintf("Year %d: %d bridges from %d states\n", year, nrow(dt),
                length(unique(dt$STATE_CODE_001))))
    return(dt)
  } else {
    cat(sprintf("Year %d: NO DATA\n", year))
    return(NULL)
  }
}

# Download all years
cat("Downloading NBI data 2000-2018...\n")
cat("This will take several minutes.\n\n")

all_years <- list()
for (yr in years) {
  cat(sprintf("Fetching %d...\n", yr))
  result <- download_nbi_year(yr)
  if (!is.null(result)) {
    all_years[[as.character(yr)]] <- result
  }
  Sys.sleep(0.5)  # Be polite to the FHWA server
}

# Combine all years
nbi <- rbindlist(all_years, fill = TRUE)
cat(sprintf("\nTotal records: %s\n", format(nrow(nbi), big.mark = ",")))
cat(sprintf("Years covered: %d-%d\n", min(nbi$year), max(nbi$year)))
cat(sprintf("Unique bridges: %s\n", format(length(unique(nbi$STRUCTURE_NUMBER_008)), big.mark = ",")))

# Validate: sufficiency rating should exist
stopifnot("SUFFICIENCY_RATING must exist" = "SUFFICIENCY_RATING" %in% names(nbi))
n_missing_sr <- sum(is.na(nbi$SUFFICIENCY_RATING))
cat(sprintf("Missing sufficiency ratings: %s (%.1f%%)\n",
            format(n_missing_sr, big.mark = ","),
            100 * n_missing_sr / nrow(nbi)))

# Save raw data
fwrite(nbi, file.path(data_dir, "nbi_panel_2000_2018.csv"))
cat(sprintf("\nSaved to %s\n", file.path(data_dir, "nbi_panel_2000_2018.csv")))
