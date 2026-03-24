# 02_clean_data.R — Build analysis panel with treatment coding
source("00_packages.R")

raw <- read_csv("../data/acs_raw.csv", show_col_types = FALSE)

# ─── Extract state FIPS from GEOID ───
raw <- raw |>
  mutate(
    state_fips = as.integer(substr(GEOID, 1, 2)),
    county_fips = as.integer(GEOID)
  )

# ─── UPHPA treatment coding (state FIPS → first enactment year) ───
# Source: Uniform Law Commission enactment records
uphpa_states <- tribble(
  ~state_fips, ~first_treat,
  32L, 2011L,  # Nevada
  13L, 2012L,  # Georgia
  30L, 2013L,  # Montana
  01L, 2014L,  # Alabama
  05L, 2015L,  # Arkansas
  09L, 2015L,  # Connecticut
  45L, 2016L,  # South Carolina
  15L, 2016L,  # Hawaii
  48L, 2017L,  # Texas
  35L, 2017L,  # New Mexico
  19L, 2018L,  # Iowa
  36L, 2019L,  # New York
  12L, 2019L,  # Florida
  17L, 2019L,  # Illinois
  29L, 2019L,  # Missouri
  51L, 2020L,  # Virginia
  28L, 2020L,  # Mississippi
  06L, 2021L,  # California
  24L, 2022L,  # Maryland
  49L, 2022L,  # Utah
  53L, 2023L,  # Washington
  11L, 2023L   # District of Columbia
)

# Merge treatment coding (never-treated states get first_treat = 0)
raw <- raw |>
  left_join(uphpa_states, by = "state_fips") |>
  mutate(first_treat = replace_na(first_treat, 0L))

# ─── Compute homeownership rates ───
panel <- raw |>
  mutate(
    black_homeown_rate = black_ownerE / black_totalE,
    white_homeown_rate = white_ownerE / white_totalE,
    homeown_gap = black_homeown_rate - white_homeown_rate
  )

# ─── Filter to counties with sufficient Black population ───
# Require ≥ 100 Black households in every year for precision
county_min_black <- panel |>
  group_by(county_fips) |>
  summarize(min_black_hh = min(black_totalE, na.rm = TRUE), .groups = "drop") |>
  filter(min_black_hh >= 100)

panel <- panel |>
  filter(county_fips %in% county_min_black$county_fips)

cat(sprintf("Counties with ≥100 Black HHs in all years: %d\n",
            n_distinct(panel$county_fips)))

# ─── Create balanced panel ───
# Keep counties present in all 15 years
county_counts <- panel |>
  group_by(county_fips) |>
  summarize(n_years = n_distinct(year), .groups = "drop") |>
  filter(n_years == 15)

panel <- panel |>
  filter(county_fips %in% county_counts$county_fips)

cat(sprintf("Balanced panel: %d counties x %d years = %d obs\n",
            n_distinct(panel$county_fips),
            n_distinct(panel$year),
            nrow(panel)))

# Remove counties with any NA homeownership rates
panel <- panel |>
  filter(!is.na(black_homeown_rate) & !is.na(white_homeown_rate))

# Re-check balance after NA removal
county_counts2 <- panel |>
  group_by(county_fips) |>
  summarize(n_years = n_distinct(year), .groups = "drop") |>
  filter(n_years == 15)

panel <- panel |>
  filter(county_fips %in% county_counts2$county_fips)

cat(sprintf("Final balanced panel: %d counties x %d years = %d obs\n",
            n_distinct(panel$county_fips),
            n_distinct(panel$year),
            nrow(panel)))

# ─── Treatment status indicators ───
panel <- panel |>
  mutate(
    treated = as.integer(first_treat > 0),
    post = as.integer(first_treat > 0 & year >= first_treat),
    # Relative time (for event study)
    rel_time = ifelse(first_treat > 0, year - first_treat, NA_integer_)
  )

# ─── Summary of treatment groups ───
treat_summary <- panel |>
  filter(year == 2023) |>
  group_by(first_treat) |>
  summarize(
    n_counties = n(),
    n_states = n_distinct(state_fips),
    .groups = "drop"
  )
cat("\nTreatment cohorts:\n")
print(treat_summary, n = 30)

# Save
write_csv(panel, "../data/panel.csv")
cat("\nSaved: data/panel.csv\n")
