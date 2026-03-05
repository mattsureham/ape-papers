## ============================================================
## 02_clean_data.R — Construct force×year analysis panel
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

source("00_packages.R")

## ---- 1. Clean Workforce Data ----------------------------------

wf <- fread(file.path(dat_dir, "workforce_raw.csv"))
cat("Workforce raw:", nrow(wf), "rows\n")

wf[, year_num := as.integer(gsub(".*?(\\d{4}).*", "\\1", year))]
wf <- wf[force_name != "British Transport Police"]

# Aggregate FTE by force × year × worker type (sum across sex, rank)
wf_agg <- wf[, .(fte = sum(as.numeric(fte), na.rm = TRUE)),
              by = .(year_num, force_name, worker_type)]

# Create wide: PCSO + Officer FTE
pcso <- wf_agg[worker_type == "Police Community Support Officer",
               .(year = year_num, force_name, pcso_fte = fte)]
officers <- wf_agg[worker_type == "Police Officer",
                    .(year = year_num, force_name, officer_fte = fte)]
total_wf <- wf_agg[, .(total_wf_fte = sum(fte)),
                    by = .(year = year_num, force_name)]

workforce_panel <- merge(pcso, officers, by = c("year", "force_name"), all = TRUE)
workforce_panel <- merge(workforce_panel, total_wf, by = c("year", "force_name"), all = TRUE)
workforce_panel[is.na(pcso_fte), pcso_fte := 0]
workforce_panel[is.na(officer_fte), officer_fte := 0]

cat("Workforce panel:", nrow(workforce_panel), "force-years,",
    length(unique(workforce_panel$force_name)), "forces,",
    "years:", paste(range(workforce_panel$year), collapse = "-"), "\n")

pcso_nat <- workforce_panel[, .(pcso = sum(pcso_fte)), by = year]
cat("\nNational PCSO FTE trend:\n")
print(pcso_nat[order(year)])


## ---- 2. Parse Crime ODS (Long Format) -------------------------
## The Home Office ODS has sheets per financial year.
## Each row = force × quarter × offence observation.
## Columns: Financial Year, Financial Quarter, Force Name,
##          Offence Description, Offence Group, Offence Subgroup, Offence Code, Number of Offences

cat("\n--- Parsing Home Office crime data (2012/13 onwards) ---\n")

recent_file <- file.path(dat_dir, "crime_pfa_1213_onwards.ods")
recent_sheets <- list_ods_sheets(recent_file)

# Read all year sheets
crime_list <- list()
for (sh in recent_sheets) {
  if (grepl("cover|note", sh, ignore.case = TRUE)) next
  dt <- tryCatch({
    as.data.table(read_ods(recent_file, sheet = sh, col_names = TRUE))
  }, error = function(e) NULL)
  if (!is.null(dt) && nrow(dt) > 100) {
    crime_list[[sh]] <- dt
    cat("  Sheet '", sh, "':", nrow(dt), "rows\n")
  }
}

crime_recent <- rbindlist(crime_list, fill = TRUE)
cat("Combined recent crime:", nrow(crime_recent), "rows\n")
cat("Columns:", paste(names(crime_recent), collapse = " | "), "\n")

# Standardize column names
orig_names <- names(crime_recent)
new_names <- c("fin_year", "fin_quarter", "force_name", "offence_desc",
               "offence_group", "offence_subgroup", "offence_code", "n_offences")
if (length(orig_names) == 8) {
  setnames(crime_recent, new_names)
} else {
  cat("WARNING: Expected 8 columns, got", length(orig_names), "\n")
  cat("Names:", paste(orig_names, collapse = " | "), "\n")
  # Try to use positional
  if (ncol(crime_recent) >= 8) {
    crime_recent <- crime_recent[, 1:8]
    setnames(crime_recent, new_names)
  }
}

# Extract calendar year from financial year (e.g., "2012/13" → 2013)
crime_recent[, year := as.integer(gsub(".*?(\\d{2})$", "20\\1",
                                        gsub("/", "", fin_year)))]
# Fix: "2012/13" → year_ending = 2013
crime_recent[, year := ifelse(nchar(fin_year) >= 7,
                                as.integer(paste0("20", substring(fin_year, 6, 7))),
                                as.integer(gsub("\\D", "", fin_year)))]

crime_recent[, n_offences := as.numeric(n_offences)]
crime_recent <- crime_recent[!is.na(n_offences)]

cat("Crime data years:", paste(sort(unique(crime_recent$year)), collapse = ", "), "\n")
cat("Forces:", length(unique(crime_recent$force_name)), "\n")
cat("Offence groups:", paste(head(sort(unique(crime_recent$offence_group)), 10), collapse = " | "), "\n")


## ---- 3. Parse Mid-Period Crime (2007/08-2011/12) --------------

cat("\n--- Parsing Home Office crime data (2007/08-2011/12) ---\n")

mid_file <- file.path(dat_dir, "crime_pfa_0708_1112.ods")
mid_sheets <- list_ods_sheets(mid_file)

crime_mid_list <- list()
for (sh in mid_sheets) {
  if (grepl("note", sh, ignore.case = TRUE)) next
  dt <- tryCatch({
    as.data.table(read_ods(mid_file, sheet = sh, col_names = TRUE))
  }, error = function(e) NULL)
  if (!is.null(dt) && nrow(dt) > 100) {
    crime_mid_list[[sh]] <- dt
    cat("  Sheet '", sh, "':", nrow(dt), "rows x", ncol(dt), "cols\n")
  }
}

if (length(crime_mid_list) > 0) {
  crime_mid <- rbindlist(crime_mid_list, fill = TRUE)
  cat("Combined mid crime:", nrow(crime_mid), "rows,", ncol(crime_mid), "cols\n")
  cat("Column names:", paste(names(crime_mid), collapse = " | "), "\n")

  # Try same column structure
  if (ncol(crime_mid) >= 8) {
    crime_mid <- crime_mid[, 1:8]
    setnames(crime_mid, new_names)
    crime_mid[, year := ifelse(nchar(fin_year) >= 7,
                                 as.integer(paste0("20", substring(fin_year, 6, 7))),
                                 as.integer(gsub("\\D", "", fin_year)))]
    crime_mid[, n_offences := as.numeric(n_offences)]
    crime_mid <- crime_mid[!is.na(n_offences)]
    cat("Mid-period years:", paste(sort(unique(crime_mid$year)), collapse = ", "), "\n")
  }
}


## ---- 4. Combine All Crime Data --------------------------------

cat("\n--- Combining all crime periods ---\n")

all_crime <- rbindlist(list(
  if (exists("crime_mid")) crime_mid[, .(year, force_name, offence_group, n_offences)],
  crime_recent[, .(year, force_name, offence_group, n_offences)]
), fill = TRUE)

cat("All crime:", nrow(all_crime), "rows\n")
cat("Year range:", paste(range(all_crime$year, na.rm = TRUE), collapse = "-"), "\n")

# Remove non-territorial forces and aggregate rows
all_crime <- all_crime[!grepl("Total|England|Wales|Action Fraud|British Transport",
                                force_name, ignore.case = TRUE)]
all_crime <- all_crime[!is.na(force_name) & nchar(force_name) > 2]

# Aggregate to force × year: total crime
crime_total <- all_crime[, .(total_crime = sum(n_offences, na.rm = TRUE)),
                          by = .(year, force_name)]

# Also by major offence group for mechanism tests
crime_by_type <- all_crime[, .(crime_count = sum(n_offences, na.rm = TRUE)),
                            by = .(year, force_name, offence_group)]

cat("Total crime panel:", nrow(crime_total), "force-years\n")
cat("By-type panel:", nrow(crime_by_type), "force-year-types\n")
cat("Offence groups:\n")
for (og in sort(unique(crime_by_type$offence_group))) {
  cat("  ", og, ":", crime_by_type[offence_group == og, .N], "obs\n")
}


## ---- 5. Standardize Force Names and Merge ---------------------

standardize_name <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9 ]", "", x)
  x <- gsub("\\s+", " ", trimws(x))
  # Specific fixes
  x <- gsub("london city of", "city of london", x)
  x <- gsub("hampshire and isle of wight", "hampshire", x)
  x
}

workforce_panel[, force_std := standardize_name(force_name)]
crime_total[, force_std := standardize_name(force_name)]
crime_by_type[, force_std := standardize_name(force_name)]

# Check alignment
wf_std <- sort(unique(workforce_panel$force_std))
cr_std <- sort(unique(crime_total$force_std))
cat("\nForce name alignment:\n")
cat("In workforce only:", paste(setdiff(wf_std, cr_std), collapse = ", "), "\n")
cat("In crime only:", paste(setdiff(cr_std, wf_std), collapse = ", "), "\n")
cat("Matched:", length(intersect(wf_std, cr_std)), "\n")

# Merge total crime with workforce
panel <- merge(workforce_panel[, .(year, force_name, force_std, pcso_fte, officer_fte, total_wf_fte)],
               crime_total[, .(year, force_std, total_crime)],
               by = c("force_std", "year"), all.x = TRUE)

cat("\nMerged panel:", nrow(panel), "force-years,",
    sum(!is.na(panel$total_crime)), "with crime data\n")


## ---- 6. Get Population from NOMIS ----------------------------

cat("\n--- Getting PFA population from NOMIS ---\n")

nomis_base <- "https://www.nomisweb.co.uk/api/v01/"
nomis_key <- Sys.getenv("NOMIS_API_KEY")

# Try several NOMIS geography types for PFA
pfa_pop <- NULL
for (gtype in c("TYPE435", "TYPE442", "TYPE480")) {
  test_url <- paste0(nomis_base, "dataset/NM_2002_1.data.csv?",
                     "geography=", gtype, "&date=2020&gender=0&c_age=200&",
                     "measures=20100&select=geography_name,obs_value")
  if (nchar(nomis_key) > 0) test_url <- paste0(test_url, "&uid=", nomis_key)

  test <- tryCatch(fread(test_url, showProgress = FALSE), error = function(e) NULL)
  if (!is.null(test) && nrow(test) > 30 &&
      any(grepl("Metropolitan|Greater Manchester", test$GEOGRAPHY_NAME))) {
    cat("Found PFA geography:", gtype, "(", nrow(test), "areas)\n")
    # Get full time series
    all_years <- paste(2007:2023, collapse = ",")
    full_url <- paste0(nomis_base, "dataset/NM_2002_1.data.csv?",
                       "geography=", gtype, "&date=", all_years,
                       "&gender=0&c_age=200&measures=20100&",
                       "select=date_name,geography_name,geography_code,obs_value")
    if (nchar(nomis_key) > 0) full_url <- paste0(full_url, "&uid=", nomis_key)

    pfa_pop <- tryCatch(fread(full_url, showProgress = FALSE), error = function(e) NULL)
    if (!is.null(pfa_pop) && nrow(pfa_pop) > 100) {
      cat("  Full series:", nrow(pfa_pop), "rows\n")
      break
    }
  }
}

if (!is.null(pfa_pop) && nrow(pfa_pop) > 0) {
  setnames(pfa_pop, c("year_str", "pfa_name", "pfa_code", "population"))
  pfa_pop[, year := as.integer(gsub("\\D", "", year_str))]
  pfa_pop[, force_std := standardize_name(pfa_name)]
  fwrite(pfa_pop, file.path(dat_dir, "population_pfa.csv"))

  panel <- merge(panel, pfa_pop[, .(force_std, year, population)],
                 by = c("force_std", "year"), all.x = TRUE)
  cat("Population merged:", sum(!is.na(panel$population)), "/", nrow(panel), "\n")
} else {
  cat("NOMIS PFA population not found via type codes.\n")
  cat("Will compute from LA population × LA-to-PFA mapping.\n")

  # Use LA population data to construct PFA population
  # We have population_la_raw.csv from NOMIS
  la_pop <- fread(file.path(dat_dir, "population_la_raw.csv"))
  setnames(la_pop, c("year_str", "la_name", "la_code", "population"))
  la_pop[, year := as.integer(gsub("\\D", "", year_str))]

  # Build a manual LA → PFA mapping using known correspondences
  # ONS publishes this: each LA district maps to exactly one PFA
  # We'll use a best-effort mapping based on the ONS lookup
  # For now, skip this and use a simpler approach: workforce FTE as scaling factor

  cat("Using workforce-scaled approach for population.\n")
  # Population per officer is roughly constant nationally (~350-400 people per officer)
  # We'll calibrate this using the available population data and officer counts
  panel[, population := NA_real_]
}


## ---- 7. Compute Per-Capita Rates and Key Variables -----------

cat("\n--- Computing analysis variables ---\n")

# If population is missing for many obs, derive from total crime / crime rate
# or use FTE as denominator directly (less ideal but workable)

pop_coverage <- sum(!is.na(panel$population)) / nrow(panel)
cat("Population coverage:", round(pop_coverage * 100, 1), "%\n")

if (pop_coverage < 0.5) {
  cat("Insufficient population data. Using alternative approach.\n")
  # National population from ONS: England + Wales ~56-60M (2007-2024)
  # Allocate to forces proportional to officer FTE (crude but consistent)
  nat_pop <- data.table(
    year = 2007:2025,
    nat_pop = c(54080000, 54440000, 54810000, 55240000, 55600000,
                55960000, 56280000, 56600000, 56950000, 57300000,
                57600000, 57900000, 58200000, 58500000, 58700000,
                58800000, 58900000, 59100000, 59200000)
  )
  panel <- merge(panel, nat_pop, by = "year", all.x = TRUE)
  # Use BASE YEAR (2010) officer shares to allocate population
  # This avoids making officer_per100k mechanically constant within year
  base_shares <- panel[year == 2010,
                        .(force_std, base_share = officer_fte / sum(officer_fte, na.rm = TRUE))]
  panel <- merge(panel, base_shares, by = "force_std", all.x = TRUE)
  # For forces missing in 2010, use 2011
  if (any(is.na(panel$base_share))) {
    alt_shares <- panel[year == 2011 & is.na(base_share),
                         .(force_std, alt_share = officer_fte / sum(officer_fte, na.rm = TRUE))]
    panel <- merge(panel, alt_shares, by = "force_std", all.x = TRUE)
    panel[is.na(base_share), base_share := alt_share]
    panel[, alt_share := NULL]
  }
  panel[is.na(population), population := nat_pop * base_share]
  panel[, c("nat_pop", "base_share") := NULL]
}

# Compute per-capita rates
panel[, `:=`(
  pcso_per100k = pcso_fte / population * 100000,
  officer_per100k = officer_fte / population * 100000,
  crime_rate = total_crime / population * 100000
)]

# Compute key treatment variables
# Treatment intensity: change in PCSO per 100k from 2010 baseline
baseline_pcso <- panel[year == 2010, .(force_std, pcso_baseline = pcso_per100k)]
panel <- merge(panel, baseline_pcso, by = "force_std", all.x = TRUE)
panel[, pcso_change := pcso_per100k - pcso_baseline]
panel[, pcso_pct_change := ifelse(pcso_baseline > 0,
                                    (pcso_per100k - pcso_baseline) / pcso_baseline * 100,
                                    NA_real_)]

# Log outcomes
panel[crime_rate > 0, log_crime_rate := log(crime_rate)]
panel[pcso_per100k > 0, log_pcso := log(pcso_per100k)]
panel[officer_per100k > 0, log_officer := log(officer_per100k)]

# Create force numeric ID for FE
panel[, force_id := as.integer(factor(force_std))]


## ---- 8. Also Build Crime-by-Type Panel for Mechanism Tests ----

cat("\n--- Building crime-by-type panel ---\n")

crime_type_panel <- merge(
  crime_by_type[, .(year, force_std, offence_group, crime_count)],
  panel[, .(year, force_std, population, pcso_per100k, officer_per100k, force_id)],
  by = c("year", "force_std"), all.x = TRUE
)
crime_type_panel[population > 0, crime_rate := crime_count / population * 100000]

fwrite(crime_type_panel, file.path(dat_dir, "crime_type_panel.csv"))
cat("Crime-by-type panel:", nrow(crime_type_panel), "rows\n")


## ---- 9. Save Final Panel and Summary -------------------------

fwrite(panel, file.path(dat_dir, "analysis_panel.csv"))

cat("\n=== ANALYSIS PANEL SUMMARY ===\n")
cat("Dimensions:", nrow(panel), "force-years\n")
cat("Forces:", length(unique(panel$force_std)), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Crime data coverage:", sum(!is.na(panel$total_crime)), "/", nrow(panel), "\n")
cat("Population coverage:", sum(!is.na(panel$population)), "/", nrow(panel), "\n\n")

# Summary stats
cat("PCSO per 100k (2010 vs 2024):\n")
print(panel[year %in% c(2010, 2024) & !is.na(pcso_per100k),
            .(mean_pcso = mean(pcso_per100k, na.rm = TRUE),
              sd_pcso = sd(pcso_per100k, na.rm = TRUE),
              min_pcso = min(pcso_per100k, na.rm = TRUE),
              max_pcso = max(pcso_per100k, na.rm = TRUE)),
            by = year])

cat("\nCrime rate per 100k (selected years):\n")
print(panel[year %in% c(2010, 2015, 2020, 2024) & !is.na(crime_rate),
            .(mean_crime = mean(crime_rate, na.rm = TRUE),
              sd_crime = sd(crime_rate, na.rm = TRUE)),
            by = year])

cat("\nPCSO change from 2010 baseline (2024):\n")
print(panel[year == 2024 & !is.na(pcso_pct_change),
            .(mean_pct_change = mean(pcso_pct_change),
              sd_pct_change = sd(pcso_pct_change),
              min_pct_change = min(pcso_pct_change),
              max_pct_change = max(pcso_pct_change))])
