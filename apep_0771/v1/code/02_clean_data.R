# ==============================================================================
# 02_clean_data.R — Variable Construction
# Paper: When the Campus Goes Dark (apep_0771)
# ==============================================================================

source("00_packages.R")

ipeds_raw   <- readRDS("../data/ipeds_closures_raw.rds")
ipeds_enr   <- readRDS("../data/ipeds_enrollment_raw.rds")
qwi_raw     <- readRDS("../data/qwi_raw.rds")

# ---- 1. Build closure panel from IPEDS ----
cat("Building closure panel from IPEDS...\n")

# Clean county FIPS: must be 5 digits
ipeds_raw <- ipeds_raw %>%
  mutate(county_fips = as.integer(county_fips)) %>%
  filter(!is.na(county_fips), county_fips > 0)

# Identify closures: deathyr > 0 indicates closure year
closures <- ipeds_raw %>%
  filter(!is.na(deathyr), deathyr >= 2013, deathyr <= 2018)

cat(sprintf("  For-profit closures 2013-2018: %d institutions\n", nrow(closures)))
cat(sprintf("  Unique counties with closures: %d\n", n_distinct(closures$county_fips)))

# Get peak pre-closure enrollment for each closed institution
peak_enrollment <- ipeds_enr %>%
  inner_join(closures %>% select(unitid, deathyr), by = "unitid") %>%
  filter(year < deathyr, year >= deathyr - 5) %>%
  group_by(unitid) %>%
  summarise(peak_enrollment = max(total_enrollment, na.rm = TRUE), .groups = "drop")

closures <- closures %>%
  left_join(peak_enrollment, by = "unitid") %>%
  mutate(peak_enrollment = replace_na(peak_enrollment, 0))

# County-level closure summary
county_closures <- closures %>%
  group_by(county_fips) %>%
  summarise(
    n_closures = n(),
    first_closure_year = min(deathyr),
    total_peak_enrollment = sum(peak_enrollment, na.rm = TRUE),
    .groups = "drop"
  )

# Identify control counties: had for-profit but no closure
all_fp_counties <- ipeds_raw %>%
  filter(!is.na(county_fips), county_fips > 0) %>%
  distinct(county_fips)

control_counties <- all_fp_counties %>%
  anti_join(county_closures, by = "county_fips") %>%
  mutate(n_closures = 0L, first_closure_year = 0L, total_peak_enrollment = 0)

county_panel_base <- bind_rows(county_closures, control_counties)

cat(sprintf("  Treated counties: %d\n", sum(county_panel_base$n_closures > 0)))
cat(sprintf("  Control counties: %d\n", sum(county_panel_base$n_closures == 0)))

# ---- 2. Clean QWI data ----
cat("Cleaning QWI data...\n")

qwi <- qwi_raw %>%
  mutate(
    county_fips = as.integer(geography),
    year = as.integer(year),
    quarter = as.integer(quarter),
    yq = year + (quarter - 1) / 4,
    # Create time index (quarters since 2008Q1)
    time_q = (year - 2008) * 4 + quarter
  ) %>%
  filter(!is.na(county_fips), county_fips > 0)

# Keep only counties in our panel (had for-profit colleges)
qwi_panel <- qwi %>%
  inner_join(county_panel_base, by = "county_fips")

cat(sprintf("  QWI panel obs (county x quarter x sector): %d\n", nrow(qwi_panel)))
cat(sprintf("  Unique counties in panel: %d\n", n_distinct(qwi_panel$county_fips)))

# ---- 3. Log transform outcomes ----
qwi_panel <- qwi_panel %>%
  mutate(
    log_emp = log(pmax(emp, 1)),
    log_hir = log(pmax(hir_a, 1)),
    log_sep = log(pmax(sep, 1)),
    log_earn = log(pmax(earn_s, 1))
  )

# ---- 4. Create treatment variables ----
# For CS-DiD: first_treat = year of first closure (0 for never-treated)
# We need to convert to annual for CS-DiD (using year, not quarter)

# Annual first treatment year (already have this)
# For continuous intensity: closure count and enrollment-weighted

# Chain indicators for IV
chain_campuses <- closures %>%
  mutate(
    is_itt = grepl("ITT", instnm, ignore.case = TRUE),
    is_corinthian = grepl("Corinthian|Everest|Heald|WyoTech", instnm, ignore.case = TRUE),
    is_eca = grepl("Education Corporation|Virginia College|Brightwood", instnm, ignore.case = TRUE)
  )

county_chain <- chain_campuses %>%
  group_by(county_fips) %>%
  summarise(
    has_chain = as.integer(any(is_itt | is_corinthian | is_eca)),
    chain_closures = sum(is_itt | is_corinthian | is_eca),
    .groups = "drop"
  )

qwi_panel <- qwi_panel %>%
  left_join(county_chain, by = "county_fips") %>%
  mutate(
    has_chain = replace_na(has_chain, 0L),
    chain_closures = replace_na(chain_closures, 0L)
  )

# ---- 5. Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat(sprintf("Counties: %d treated, %d control\n",
            sum(county_panel_base$n_closures > 0),
            sum(county_panel_base$n_closures == 0)))
cat(sprintf("Period: %d-%d (quarterly)\n",
            min(qwi_panel$year), max(qwi_panel$year)))

sector_summary <- qwi_panel %>%
  group_by(industry) %>%
  summarise(
    n_obs = n(),
    mean_emp = mean(emp, na.rm = TRUE),
    sd_emp = sd(emp, na.rm = TRUE),
    .groups = "drop"
  )
print(sector_summary)

# ---- 6. Save cleaned data ----
saveRDS(qwi_panel, "../data/qwi_panel.rds")
saveRDS(county_panel_base, "../data/county_panel_base.rds")
saveRDS(closures, "../data/closures_detail.rds")

cat("Clean data saved.\n")
