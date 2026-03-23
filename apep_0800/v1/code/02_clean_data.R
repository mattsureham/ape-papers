# =============================================================================
# 02_clean_data.R — Clean and construct analysis variables
# APEP Working Paper apep_0800
# =============================================================================

source("00_packages.R")

df_raw <- arrow::read_parquet("../data/qwi_raw.parquet")
cat(sprintf("Loaded %s rows.\n", format(nrow(df_raw), big.mark = ",")))

# ---------------------------------------------------------------------------
# State FIPS from county FIPS (first 2 digits of 5-digit county code)
# ---------------------------------------------------------------------------
df <- df_raw %>%
  mutate(
    county_fips = as.character(geography),
    state_fips = substr(county_fips, 1, 2),
    # Continuous time variable (year-quarter)
    yq = year + (quarter - 1) / 4,
    # Calendar quarter integer for FE
    cal_quarter = paste0(year, "Q", quarter)
  )

# ---------------------------------------------------------------------------
# Treatment assignment: credit check ban states and timing
# ---------------------------------------------------------------------------
ban_states <- tribble(
  ~state_fips, ~ban_year, ~ban_quarter, ~state_name,
  "53", 2007, 3, "Washington",
  "15", 2009, 3, "Hawaii",
  "41", 2010, 1, "Oregon",
  "17", 2010, 1, "Illinois",
  "06", 2011, 1, "California",
  "24", 2011, 4, "Maryland",
  "09", 2011, 4, "Connecticut",
  "11", 2011, 2, "DC",
  "50", 2012, 3, "Vermont",
  "32", 2013, 4, "Nevada",
  "08", 2013, 3, "Colorado"
)

# Create treatment timing variable (year-quarter of ban)
ban_states <- ban_states %>%
  mutate(treat_yq = ban_year + (ban_quarter - 1) / 4)

# Merge treatment info
df <- df %>%
  left_join(ban_states %>% select(state_fips, treat_yq, ban_year, state_name),
            by = "state_fips") %>%
  mutate(
    ban_state = !is.na(treat_yq),
    # For CS estimator: first treatment period (0 for never-treated)
    first_treat_yr = if_else(ban_state, ban_year, 0L),
    # Post indicator
    post = if_else(ban_state & yq >= treat_yq, 1L, 0L),
    # Race indicators
    black = if_else(race == "A2", 1L, 0L),
    # Outcome variables
    log_hirn = log(pmax(HirN, 1)),
    asinh_hirn = asinh(HirN),
    log_emp = log(pmax(Emp, 1)),
    asinh_emp = asinh(Emp),
    log_earn_hir = log(pmax(EarnHirNS, 1))
  )

# ---------------------------------------------------------------------------
# Construct DDD panel: Black-White gap at county-quarter level
# ---------------------------------------------------------------------------
# For the CS estimator, we need a unit-level panel
# Unit = county × industry, outcome = Black-White hiring gap

df_wide <- df %>%
  filter(!is.na(HirN)) %>%
  select(county_fips, state_fips, year, quarter, yq, cal_quarter,
         race, industry, HirN, EarnHirNS, Emp, EarnS,
         ban_state, first_treat_yr, treat_yq, post, black,
         log_hirn, asinh_hirn, log_emp, log_earn_hir) %>%
  # Create a unique panel ID
  mutate(panel_id = paste(county_fips, industry, sep = "_"))

# ---------------------------------------------------------------------------
# Collapse to county-industry-quarter-race level (already should be unique)
# ---------------------------------------------------------------------------
df_panel <- df_wide %>%
  group_by(county_fips, state_fips, industry, year, quarter, yq, cal_quarter,
           race, ban_state, first_treat_yr) %>%
  summarise(
    HirN = sum(HirN, na.rm = TRUE),
    EarnHirNS = weighted.mean(EarnHirNS, w = pmax(HirN, 1), na.rm = TRUE),
    Emp = sum(Emp, na.rm = TRUE),
    EarnS = weighted.mean(EarnS, w = pmax(Emp, 1), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_hirn = log(pmax(HirN, 1)),
    asinh_hirn = asinh(HirN),
    log_emp = log(pmax(Emp, 1)),
    asinh_emp = asinh(Emp),
    log_earn_hir = log(pmax(EarnHirNS, 1)),
    black = if_else(race == "A2", 1L, 0L),
    post = if_else(ban_state & yq >= first_treat_yr, 1L, 0L),
    panel_id = paste(county_fips, industry, race, sep = "_"),
    # Integer time for CS
    time_int = (year - 2002) * 4 + quarter,
    # First treatment period for CS (integer)
    first_treat_int = if_else(first_treat_yr > 0,
                              (first_treat_yr - 2002) * 4 + 1L,
                              0L)
  )

# ---------------------------------------------------------------------------
# Summary stats
# ---------------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %s\n", format(nrow(df_panel), big.mark = ",")))
cat(sprintf("Counties: %d\n", n_distinct(df_panel$county_fips)))
cat(sprintf("States: %d\n", n_distinct(df_panel$state_fips)))
cat(sprintf("Ban states: %d\n",
            n_distinct(df_panel$state_fips[df_panel$ban_state])))
cat(sprintf("Ban counties: %d\n",
            n_distinct(df_panel$county_fips[df_panel$ban_state])))
cat(sprintf("Quarters: %d\n", n_distinct(df_panel$cal_quarter)))
cat(sprintf("Year range: %d - %d\n", min(df_panel$year), max(df_panel$year)))

cat("\n=== By industry ===\n")
df_panel %>%
  group_by(industry) %>%
  summarise(
    n = n(),
    counties = n_distinct(county_fips),
    mean_hirn = mean(HirN, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\n=== By race ===\n")
df_panel %>%
  group_by(race) %>%
  summarise(
    n = n(),
    mean_hirn = mean(HirN, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ---------------------------------------------------------------------------
# Save clean data
# ---------------------------------------------------------------------------
arrow::write_parquet(df_panel, "../data/analysis_panel.parquet")
cat(sprintf("\nSaved analysis panel: %s rows\n",
            format(nrow(df_panel), big.mark = ",")))

# Also save the ban_states reference
saveRDS(ban_states, "../data/ban_states.rds")
