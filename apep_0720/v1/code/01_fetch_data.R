# 01_fetch_data.R — Fetch Census STC flat files directly
# apep_0720: Sports Betting Revenue Cannibalization

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===================================================================
# CENSUS STC FLAT FILES
# ===================================================================

# State abbreviations in order (matching flat file columns)
state_abbrs <- c("US","AL","AK","AZ","AR","CA","CO","CT","DE","DC",
                 "FL","GA","HI","ID","IL","IN","IA","KS","KY","LA",
                 "ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
                 "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
                 "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV",
                 "WI","WY")

# State FIPS codes matching the abbreviations
state_fips <- c(0, 1,2,4,5,6,8,9,10,11,
                12,13,15,16,17,18,19,20,21,22,
                23,24,25,26,27,28,29,30,31,32,
                33,34,35,36,37,38,39,40,41,42,
                44,45,46,47,48,49,50,51,53,54,
                55,56)

# File naming patterns by year
all_data <- list()

for (year in 2012:2022) {
  # Census STC file naming has changed over time
  yy <- year %% 100
  patterns <- c(
    sprintf("FY%d-Flat-File.txt", year),       # 2019-2022
    sprintf("fy%d_flat_file.txt", year),        # 2015-2018
    sprintf("FY%d_Flat_File.txt", year),        # variant
    sprintf("%02dstaxcd.txt", yy),              # 2010-2014
    sprintf("%d_STC_Detailed.csv", year),
    sprintf("stc%02d.txt", yy),
    sprintf("%dstc.txt", year)
  )

  url_base <- sprintf("https://www2.census.gov/programs-surveys/stc/datasets/%d/", year)
  downloaded <- FALSE

  for (pat in patterns) {
    url <- paste0(url_base, pat)
    cat(sprintf("Trying %d: %s...", year, pat))

    result <- tryCatch({
      lines <- readLines(url, warn = FALSE)
      if (length(lines) < 2) stop("Empty file")
      cat(" OK\n")
      list(lines = lines, url = url)
    }, error = function(e) {
      cat(" skip\n")
      NULL
    })

    if (!is.null(result)) {
      downloaded <- TRUE

      # Parse the flat file (ITEM, US, AL, AK, ...)
      # First line is header
      header <- strsplit(result$lines[1], ",")[[1]]

      # Parse each subsequent line
      rows <- list()
      for (i in 2:length(result$lines)) {
        if (nchar(trimws(result$lines[i])) == 0) next
        vals <- strsplit(result$lines[i], ",")[[1]]
        if (length(vals) < 3) next

        item <- vals[1]
        # Keep only key tax items
        if (!(item %in% c("T00", "T09", "T10", "T11", "T16", "T20"))) next

        # Parse state values (replace X with NA)
        for (j in 2:min(length(vals), length(header))) {
          val <- vals[j]
          amount <- suppressWarnings(as.numeric(val))
          st <- header[j]

          # Map state abbreviation to FIPS
          fips_idx <- match(st, state_abbrs)
          if (!is.na(fips_idx) && !is.na(amount) && state_fips[fips_idx] > 0) {
            rows[[length(rows) + 1]] <- data.frame(
              year = year,
              state_fips = state_fips[fips_idx],
              state_abbr = st,
              item = item,
              amount = amount,
              stringsAsFactors = FALSE
            )
          }
        }
      }

      if (length(rows) > 0) {
        year_df <- bind_rows(rows)
        all_data[[as.character(year)]] <- year_df
        cat(sprintf("  Parsed: %d records (%d states x %d items)\n",
                    nrow(year_df), length(unique(year_df$state_fips)),
                    length(unique(year_df$item))))
      }
      break
    }
  }

  if (!downloaded) {
    cat(sprintf("  WARNING: No data for %d\n", year))
  }
  Sys.sleep(0.2)
}

if (length(all_data) == 0) {
  stop("FATAL: No STC data retrieved from Census flat files.")
}

stc <- bind_rows(all_data)
cat(sprintf("\nTotal STC records: %d\n", nrow(stc)))
cat(sprintf("Years: %d to %d\n", min(stc$year), max(stc$year)))
cat(sprintf("States: %d\n", length(unique(stc$state_fips))))
cat(sprintf("Items: %s\n", paste(unique(stc$item), collapse = ", ")))

# Pivot to wide format
stc_wide <- stc %>%
  pivot_wider(
    id_cols = c(year, state_fips, state_abbr),
    names_from = item,
    values_from = amount,
    values_fill = 0
  )

cat(sprintf("Wide panel: %d state-years\n", nrow(stc_wide)))

# ===================================================================
# TREATMENT DATES
# ===================================================================

# Year of first legal online sports betting by state
# Using STC fiscal year convention (state fiscal year typically ends June 30)
# Treatment year = first FY with material sports betting revenue
treatment_years <- tribble(
  ~state_fips, ~treat_year, ~state_abbr,
  34, 2019, "NJ",   # FY2019 (started June 2018)
  54, 2019, "WV",   # FY2019
  42, 2019, "PA",   # FY2019
  10, 2019, "DE",   # FY2019
  44, 2019, "RI",   # FY2019
  28, 2019, "MS",   # FY2019
  18, 2020, "IN",   # FY2020
  19, 2020, "IA",   # FY2020
  33, 2020, "NH",   # FY2020
  41, 2020, "OR",   # FY2020
  17, 2020, "IL",   # FY2020 (Mar 2020)
  8,  2021, "CO",   # FY2021
  47, 2021, "TN",   # FY2021
  26, 2021, "MI",   # FY2021
  51, 2021, "VA",   # FY2021
  4,  2022, "AZ",   # FY2022
  9,  2022, "CT",   # FY2022
  36, 2022, "NY",   # FY2022
  22, 2022, "LA",   # FY2022
  56, 2022, "WY",   # FY2022
  46, 2022, "SD",   # FY2022
  24, 2022, "MD",   # FY2022
  30, 2021, "MT",   # FY2021 (retail 2020)
  11, 2021, "DC",   # FY2021
  32, 2019, "NV",   # already had (include as always-treated)
  5,  2022, "AR"    # FY2022
)

# Never-treated states (as of FY2022)
never_treated_fips <- c(1, 2, 6, 13, 15, 27, 40, 45, 48, 49)
# AL, AK, CA, GA, HI, MN, OK, SC, TX, UT

# Also states with no sports betting by 2022:
# ID=16, NE=31, WI=55 — add as never-treated or late-treated
never_treated_fips <- c(never_treated_fips, 16, 31, 55)

cat(sprintf("\nTreated states: %d\n", nrow(treatment_years)))
cat(sprintf("Never-treated: %d\n", length(never_treated_fips)))

# ===================================================================
# MERGE
# ===================================================================

stc_panel <- stc_wide %>%
  left_join(treatment_years %>% select(state_fips, treat_year), by = "state_fips") %>%
  mutate(
    treat_year = ifelse(state_fips %in% never_treated_fips, 0L, treat_year),
    # For CS-DiD: g = 0 means never-treated
    g = ifelse(is.na(treat_year) | treat_year == 0, 0L, as.integer(treat_year)),
    post = as.integer(!is.na(treat_year) & treat_year > 0 & year >= treat_year)
  )

# Quick summary
cat("\n--- T11 (Amusement/Gambling Tax) by period ---\n")
stc_panel %>%
  filter(g > 0) %>%
  mutate(period = ifelse(year >= g, "Post", "Pre")) %>%
  group_by(period) %>%
  summarise(
    mean_T11 = mean(T11, na.rm = TRUE) / 1000,
    n = n(),
    .groups = "drop"
  ) %>%
  print()

cat("\n--- T20 (Pari-mutuel) by period ---\n")
stc_panel %>%
  filter(g > 0) %>%
  mutate(period = ifelse(year >= g, "Post", "Pre")) %>%
  group_by(period) %>%
  summarise(
    mean_T20 = mean(T20, na.rm = TRUE) / 1000,
    n = n(),
    .groups = "drop"
  ) %>%
  print()

saveRDS(stc_panel, file.path(data_dir, "stc_panel.rds"))
saveRDS(treatment_years, file.path(data_dir, "treatment_years.rds"))

cat("\nData saved.\n")
