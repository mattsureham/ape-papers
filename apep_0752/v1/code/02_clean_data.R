## 02_clean_data.R — Construct analysis panels for apep_0752
##
## Two panels:
## A. State-year panel (1999-2024): state OD deaths + gaming intensity
## B. County cross-section (2020-2023): VSRR county OD + tribal/gaming status

source("00_packages.R")
data_dir <- "../data"

# Load saved data
state_od <- readRDS(file.path(data_dir, "state_overdose_panel.rds"))
vsrr_county <- readRDS(file.path(data_dir, "vsrr_county_od.rds"))
state_compact <- readRDS(file.path(data_dir, "state_first_compact.rds"))
aian_baseline <- readRDS(file.path(data_dir, "aian_baseline_2010.rds"))
tribal_counties <- readRDS(file.path(data_dir, "tribal_counties.rds"))
treatment <- readRDS(file.path(data_dir, "treatment_assignment.rds"))

# ============================================================
# PANEL A: State-Year (1999-2024)
# ============================================================

cat("=== Building state-year panel ===\n")

# Merge state overdose panel with gaming state treatment
# Normalize state names for matching
normalize_state <- function(s) trimws(tolower(s))

state_od_norm <- state_od |> mutate(state_norm = normalize_state(state))
state_compact_norm <- state_compact |> mutate(state_norm = normalize_state(state_name))

state_panel <- state_od_norm |>
  left_join(
    state_compact_norm |> select(state_norm, first_compact_year),
    by = "state_norm"
  ) |>
  mutate(
    gaming_state = !is.na(first_compact_year),
    post_gaming = !is.na(first_compact_year) & year >= first_compact_year,
    years_since_gaming = ifelse(gaming_state, year - first_compact_year, NA_integer_)
  ) |>
  select(-state_norm)

# Add state-level AI/AN share (from county baseline, aggregated)
state_aian <- aian_baseline |>
  mutate(state_code = substr(fips, 1, 2)) |>
  group_by(state_code) |>
  summarize(
    state_aian_pop = sum(aian_pop_2010, na.rm = TRUE),
    state_total_pop = sum(total_pop_2010, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(state_aian_share = state_aian_pop / state_total_pop)

# Map state names to FIPS via tigris
state_fips_map <- tigris::fips_codes |>
  select(state_code, state_name) |>
  distinct()

state_panel <- state_panel |>
  left_join(state_fips_map |> rename(state = state_name), by = "state") |>
  left_join(state_aian, by = "state_code")

# For VSRR rows missing od_rate, compute from deaths and population
# Fill population forward from NCHS data
state_panel <- state_panel |>
  group_by(state) |>
  arrange(year) |>
  fill(population, .direction = "down") |>
  ungroup() |>
  mutate(
    # Use od_rate where available; compute from deaths/pop otherwise
    od_rate = ifelse(is.na(od_rate) & !is.na(od_deaths) & !is.na(population),
                     (od_deaths / population) * 100000, od_rate)
  )

# Create dose-response: interaction of gaming × AI/AN intensity
state_panel <- state_panel |>
  mutate(
    # Dose = gaming × AI/AN share (high share = more affected by casino income)
    gaming_x_aian = post_gaming * state_aian_share,
    # Log rate (for analysis)
    log_od_rate = log(od_rate + 0.1),
    # State numeric ID for FE
    state_id = as.integer(factor(state))
  )

# Filter to states with valid data
state_panel <- state_panel |>
  filter(!is.na(od_rate), !is.na(state_aian_share))

cat("  Panel size:", nrow(state_panel), "state-years\n")
cat("  States:", n_distinct(state_panel$state), "\n")
cat("  Years:", min(state_panel$year), "-", max(state_panel$year), "\n")
cat("  Gaming states:", sum(state_panel$gaming_state & state_panel$year == 2010), "\n")
cat("  Non-gaming states:", sum(!state_panel$gaming_state & state_panel$year == 2010), "\n")

# ============================================================
# PANEL B: County Cross-Section (2020-2023 VSRR)
# ============================================================

cat("\n=== Building county-level cross-section ===\n")

# Annual county overdose totals from VSRR
county_annual <- vsrr_county |>
  filter(year >= 2020, year <= 2023) |>
  group_by(fips, year) |>
  summarize(
    annual_od_deaths = sum(overdose_deaths, na.rm = TRUE),
    n_months = n(),
    .groups = "drop"
  ) |>
  # Only keep counties reporting all 12 months
  filter(n_months == 12)

# Merge with treatment, demographics
county_panel <- county_annual |>
  left_join(treatment |> select(fips, has_tribal_land, has_casino, treatment_year),
            by = "fips") |>
  left_join(aian_baseline, by = "fips") |>
  mutate(
    has_tribal_land = replace_na(has_tribal_land, FALSE),
    has_casino = replace_na(has_casino, FALSE),
    # Per-capita overdose rate
    od_rate_per_100k = (annual_od_deaths / total_pop_2010) * 100000,
    # County type for comparison
    county_type = case_when(
      has_casino ~ "Casino County",
      has_tribal_land ~ "Tribal (No Casino)",
      aian_share_2010 > 0.05 ~ "High AI/AN (>5%)",
      TRUE ~ "Other"
    )
  ) |>
  filter(!is.na(total_pop_2010), total_pop_2010 > 1000)

cat("  County-year observations:", nrow(county_panel), "\n")
cat("  Casino counties:", sum(county_panel$has_casino & county_panel$year == 2020), "\n")
cat("  Tribal (no casino):", sum(county_panel$county_type == "Tribal (No Casino)" & county_panel$year == 2020), "\n")
cat("  Other counties:", sum(county_panel$county_type == "Other" & county_panel$year == 2020), "\n")

# ============================================================
# Descriptive statistics
# ============================================================

cat("\n=== Descriptive Statistics ===\n")

# State-level summary
cat("\nState-level OD rates by gaming status (mean, all years):\n")
state_panel |>
  filter(!is.na(od_rate)) |>
  group_by(gaming_state) |>
  summarize(
    n_states = n_distinct(state),
    mean_od_rate = round(mean(od_rate, na.rm = TRUE), 2),
    sd_od_rate = round(sd(od_rate, na.rm = TRUE), 2),
    mean_aian_share = round(mean(state_aian_share, na.rm = TRUE) * 100, 2),
    .groups = "drop"
  ) |>
  print()

# County-level summary (2020-2023)
cat("\nCounty-level OD rates by county type (mean, 2020-2023):\n")
county_panel |>
  group_by(county_type) |>
  summarize(
    n_counties = n_distinct(fips),
    mean_od_deaths = round(mean(annual_od_deaths, na.rm = TRUE), 1),
    mean_od_rate = round(mean(od_rate_per_100k, na.rm = TRUE), 1),
    mean_aian_share = round(mean(aian_share_2010, na.rm = TRUE) * 100, 2),
    .groups = "drop"
  ) |>
  print()

# ============================================================
# Save analysis-ready panels
# ============================================================

saveRDS(state_panel, file.path(data_dir, "state_panel_analysis.rds"))
saveRDS(county_panel, file.path(data_dir, "county_panel_analysis.rds"))

cat("\nAnalysis panels saved.\n")
cat("State panel:", nrow(state_panel), "obs\n")
cat("County panel:", nrow(county_panel), "obs\n")
