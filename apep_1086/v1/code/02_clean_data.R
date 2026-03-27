# 02_clean_data.R — Construct analysis panel
# APEP Paper apep_1086: CAA Attainment Redesignation

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# 1. Parse Green Book: extract redesignation events
# ============================================================================
cat("=== Parsing Green Book ===\n")

# --- NAYRO: has explicit redesignation dates ---
nayro <- read_xls(file.path(data_dir, "nayro.xls"))

# Convert Excel serial date to actual date
nayro <- nayro %>%
  mutate(
    fips = paste0(sprintf("%02d", as.integer(fips_state)),
                  sprintf("%03d", as.integer(fips_cnty))),
    rede_date = suppressWarnings(as.Date(as.numeric(effec_rede), origin = "1899-12-30")),
    rede_year = as.integer(format(rede_date, "%Y")),
    has_redesig = !is.na(rede_date)
  )

cat("Total county-pollutant rows:", nrow(nayro), "\n")
cat("Rows with redesignation:", sum(nayro$has_redesig, na.rm = TRUE), "\n")

# --- PHISTORY: year-by-year designation status panel ---
phistory <- read_xls(file.path(data_dir, "phistory.xls"))
phistory <- phistory %>%
  mutate(
    fips = paste0(sprintf("%02d", as.integer(fips_state)),
                  sprintf("%03d", as.integer(fips_cnty)))
  )

# Reshape PHISTORY to long format
year_cols <- grep("^pw_", names(phistory), value = TRUE)

ph_long <- phistory %>%
  select(fips, fips_state, pollutant, all_of(year_cols)) %>%
  pivot_longer(cols = all_of(year_cols), names_to = "year", values_to = "status") %>%
  mutate(
    year = as.integer(gsub("pw_", "", year)),
    # P = Part of county, W = Whole county in nonattainment
    is_nonattain = status %in% c("P", "W"),
    # NA = not in nonattainment area (attained or never designated)
    is_attain_or_never = is.na(status)
  )

# Identify transitions: nonattainment → not in nonattainment
ph_long <- ph_long %>%
  arrange(fips, pollutant, year) %>%
  group_by(fips, pollutant) %>%
  mutate(
    lag_nonattain = lag(is_nonattain),
    # Redesignation: was nonattainment last year, not this year
    redesig_event = !is.na(lag_nonattain) & lag_nonattain == TRUE & is_nonattain == FALSE
  ) %>%
  ungroup()

redesig_from_ph <- ph_long %>%
  filter(redesig_event == TRUE) %>%
  select(fips, pollutant, year) %>%
  distinct()

cat("Redesignation events (from PHISTORY transitions):", nrow(redesig_from_ph), "\n")
cat("By year (top 10):\n")
redesig_from_ph %>% count(year, sort = TRUE) %>% head(10) %>% print()

# ============================================================================
# 2. Construct county-level treatment variable
# ============================================================================
cat("\n=== Constructing Treatment ===\n")

# Use PHISTORY transitions as primary (covers all years)
# First redesignation year per county (across all pollutants)
first_redesig <- redesig_from_ph %>%
  group_by(fips) %>%
  summarise(
    first_redesig_year = min(year),
    n_events = n(),
    pollutants = paste(unique(pollutant), collapse = "; "),
    .groups = "drop"
  )

cat("Counties with any redesignation:", nrow(first_redesig), "\n")
cat("Year range:", min(first_redesig$first_redesig_year), "-",
    max(first_redesig$first_redesig_year), "\n")
cat("\nFirst redesignation year distribution:\n")
print(table(first_redesig$first_redesig_year))

# Also create a "currently in nonattainment" panel for each county-year
# (this will be the basis for the county-year panel)
county_year_status <- ph_long %>%
  group_by(fips, year) %>%
  summarise(
    any_nonattain = any(is_nonattain, na.rm = TRUE),
    n_pollutants_nonattain = sum(is_nonattain, na.rm = TRUE),
    .groups = "drop"
  )

# Identify ever-nonattainment counties
ever_nonattain_counties <- county_year_status %>%
  filter(any_nonattain == TRUE) %>%
  pull(fips) %>%
  unique()

cat("Counties ever in nonattainment:", length(ever_nonattain_counties), "\n")

# ============================================================================
# 3. Parse AQS: county-year ambient concentrations
# ============================================================================
cat("\n=== Parsing AQS Data ===\n")

aqs_files <- list.files(data_dir, pattern = "^aqs_annual_20.*\\.csv$", full.names = TRUE)
aqs_files <- aqs_files[file.info(aqs_files)$isdir == FALSE]
cat("AQS files:", length(aqs_files), "\n")

aqs_list <- list()
for (f in aqs_files) {
  dt <- tryCatch(
    fread(f, select = c("State Code", "County Code", "Parameter Code",
                         "Arithmetic Mean", "Observation Count", "Year"),
          showProgress = FALSE),
    error = function(e) NULL
  )
  if (is.null(dt) || nrow(dt) == 0) next
  dt <- dt[`Parameter Code` %in% c(88101, 44201)]
  if (nrow(dt) > 0) aqs_list <- c(aqs_list, list(dt))
}

aqs_raw <- rbindlist(aqs_list)
cat("AQS PM2.5/O3 rows:", format(nrow(aqs_raw), big.mark = ","), "\n")

aqs_county <- aqs_raw %>%
  as_tibble() %>%
  mutate(
    fips = paste0(sprintf("%02d", as.integer(`State Code`)),
                  sprintf("%03d", as.integer(`County Code`))),
    year = as.integer(Year),
    param = ifelse(`Parameter Code` == 88101, "PM25", "O3"),
    conc = as.numeric(`Arithmetic Mean`)
  ) %>%
  filter(!is.na(conc) & !is.na(fips)) %>%
  group_by(fips, year, param) %>%
  summarise(mean_conc = mean(conc, na.rm = TRUE), n_monitors = n(), .groups = "drop")

aqs_wide <- aqs_county %>%
  pivot_wider(names_from = param, values_from = c(mean_conc, n_monitors), names_sep = "_")

cat("AQS county-year panels:", format(nrow(aqs_wide), big.mark = ","), "\n")

# ============================================================================
# 4. Parse QWI
# ============================================================================
cat("\n=== Parsing QWI Data ===\n")

qwi <- readRDS(file.path(data_dir, "qwi_manufacturing.rds"))
qwi_clean <- qwi %>%
  mutate(
    fips = paste0(state, county),
    year = as.integer(year),
    mfg_emp = as.numeric(Emp),
    mfg_hires = as.numeric(HirA),
    mfg_seps = as.numeric(Sep),
    mfg_earnings = as.numeric(EarnHirAS)
  ) %>%
  select(fips, year, mfg_emp, mfg_hires, mfg_seps, mfg_earnings) %>%
  filter(!is.na(mfg_emp))

cat("QWI county-years:", format(nrow(qwi_clean), big.mark = ","), "\n")

# ============================================================================
# 5. Merge into analysis panel
# ============================================================================
cat("\n=== Merging Analysis Panel ===\n")

panel <- qwi_clean %>%
  left_join(aqs_wide, by = c("fips", "year")) %>%
  left_join(first_redesig, by = "fips") %>%
  left_join(county_year_status, by = c("fips", "year"))

panel <- panel %>%
  mutate(
    ever_treated = !is.na(first_redesig_year),
    post = ifelse(ever_treated, year >= first_redesig_year, FALSE),
    first_treat = ifelse(ever_treated, first_redesig_year, 0),
    county_id = as.integer(factor(fips)),
    # Log outcomes
    log_mfg_emp = log(pmax(mfg_emp, 1)),
    log_mfg_earnings = log(pmax(mfg_earnings, 1)),
    # Air quality outcomes (keep as-is for treated counties with monitors)
    has_pm25 = !is.na(mean_conc_PM25),
    has_o3 = !is.na(mean_conc_O3)
  )

# ============================================================================
# 6. Restrict sample for analysis
# ============================================================================
cat("\n=== Sample Construction ===\n")

# Full sample: all counties with QWI data
cat("Full sample:\n")
cat("  County-years:", format(nrow(panel), big.mark = ","), "\n")
cat("  Unique counties:", n_distinct(panel$fips), "\n")
cat("  Treated:", sum(panel$ever_treated & !duplicated(panel$fips)), "\n")
cat("  Never-treated:", sum(!panel$ever_treated & !duplicated(panel$fips)), "\n")

# Restrict to years with good coverage: 2001-2019
# (QWI starts 2001; we avoid 2020+ COVID disruption)
panel <- panel %>% filter(year >= 2001 & year <= 2019)

# Only keep treated counties with first_redesig_year in 2002-2019
# (need at least 1 pre-period in 2001)
panel <- panel %>%
  filter(!ever_treated | (first_redesig_year >= 2002 & first_redesig_year <= 2019))

cat("\nRestricted sample (2001-2019, redesig 2002-2019):\n")
cat("  County-years:", format(nrow(panel), big.mark = ","), "\n")
cat("  Unique counties:", n_distinct(panel$fips), "\n")
n_treated <- sum(panel$ever_treated & !duplicated(panel$fips))
n_control <- sum(!panel$ever_treated & !duplicated(panel$fips))
cat("  Treated:", n_treated, "\n")
cat("  Never-treated:", n_control, "\n")

# Balanced panel check: how many county-year obs per county?
panel_balance <- panel %>%
  group_by(fips) %>%
  summarise(n_years = n(), .groups = "drop")
cat("  Years per county: mean", round(mean(panel_balance$n_years), 1),
    ", min", min(panel_balance$n_years), ", max", max(panel_balance$n_years), "\n")

# Cohort sizes
if (n_treated > 0) {
  cat("\nCohort sizes (first_redesig_year):\n")
  cohort_tab <- panel %>%
    filter(ever_treated) %>%
    distinct(fips, first_redesig_year) %>%
    count(first_redesig_year)
  print(as.data.frame(cohort_tab))
}

# Summary statistics
cat("\n=== Summary Statistics ===\n")
panel %>%
  group_by(ever_treated) %>%
  summarise(
    n_counties = n_distinct(fips),
    n_obs = n(),
    mean_mfg_emp = round(mean(mfg_emp, na.rm = TRUE)),
    sd_mfg_emp = round(sd(mfg_emp, na.rm = TRUE)),
    mean_pm25 = round(mean(mean_conc_PM25, na.rm = TRUE), 2),
    pct_with_pm25 = round(mean(has_pm25) * 100, 1),
    .groups = "drop"
  ) %>%
  print()

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis_panel.rds\n")
