# =============================================================================
# 02_clean_data.R — Merge EITC timing, construct analysis panel
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/qwi_raw.rds")

# --- State FIPS extraction ---
df$state_fips <- as.integer(substr(sprintf("%05d", df$fips_county), 1, 2))

# --- State EITC adoption timing ---
# Sources: Tax Policy Center, NCSL state EITC database
# These are the years each state's EITC supplement first applied to tax returns
eitc_timing <- tribble(
  ~state_fips, ~state_abbr, ~eitc_year,
  # Pre-QWI adopters (always-treated, will exclude)
  24, "MD", 1987,
  55, "WI", 1989,
  50, "VT", 1990,
  27, "MN", 1991,
  36, "NY", 1994,
  44, "RI", 1997,
  25, "MA", 1997,
  41, "OR", 1997,
  17, "IL", 2000,
  20, "KS", 1998,
  34, "NJ", 2000,
  # Within-QWI adopters (treatment cohorts)
  10, "DE", 2006,
  31, "NE", 2006,
  51, "VA", 2006,
  35, "NM", 2007,
  22, "LA", 2008,
  26, "MI", 2008,
  09, "CT", 2011,
  39, "OH", 2013,
  06, "CA", 2015,
  15, "HI", 2018,
  45, "SC", 2018,
  # DC
  11, "DC", 2000,
  # Additional adopters
  04, "AZ", 2006,  # nonrefundable, small
  18, "IN", 1999,
  23, "ME", 2000,
  29, "MO", 2023,  # outside window
  47, "TN", 2023,  # outside window
  53, "WA", 2008,
  19, "IA", 1990,
  08, "CO", 1999
)

# Classify states
always_treated <- eitc_timing$state_fips[eitc_timing$eitc_year < 2001]
treated_in_window <- eitc_timing %>%
  filter(eitc_year >= 2001, eitc_year <= 2018) %>%
  select(state_fips, eitc_year)

# All 51 state FIPS
all_states <- unique(df$state_fips)

# Never-treated: states without any state EITC by 2018
never_treated <- setdiff(all_states, eitc_timing$state_fips)

cat("Always-treated states (excluded):", length(always_treated), "\n")
cat("Treated in QWI window:", nrow(treated_in_window), "\n")
cat("Never-treated states:", length(never_treated), "\n")

# --- Filter to analysis sample ---
# Exclude always-treated states
df <- df %>% filter(!state_fips %in% always_treated)

# Merge treatment timing
df <- df %>%
  left_join(treated_in_window, by = "state_fips") %>%
  mutate(
    eitc_year = replace_na(eitc_year, 0L),  # 0 = never-treated for CS DiD
    treated = eitc_year > 0
  )

# --- Construct time variable (year-quarter as integer) ---
df$yq <- df$year * 10 + df$quarter

# For CS DiD, collapse to annual to reduce noise
df_annual <- df %>%
  filter(!is.na(emp), !is.na(earn_avg)) %>%
  group_by(state_fips, fips_county, industry, race, year, eitc_year, treated) %>%
  summarize(
    earn_avg = weighted.mean(earn_avg, w = emp),
    emp = mean(emp),
    hires = sum(hires, na.rm = TRUE),
    separations = sum(separations, na.rm = TRUE),
    turnover = mean(turnover, na.rm = TRUE),
    .groups = "drop"
  )

# --- Create county-industry-race unit ID ---
df_annual$unit_id <- paste(df_annual$fips_county, df_annual$industry, df_annual$race, sep = "_")

# --- Create key analysis variables ---
df_annual <- df_annual %>%
  mutate(
    log_emp = log(emp + 1),
    log_earn = log(earn_avg + 1),
    black = as.integer(race == "A2"),
    industry_label = case_when(
      industry == "72" ~ "Accommodation/Food",
      industry == "44-45" ~ "Retail",
      industry == "62" ~ "Healthcare",
      TRUE ~ industry
    )
  )

# --- Summary statistics ---
cat("\n=== Analysis Panel ===\n")
cat("Rows:", nrow(df_annual), "\n")
cat("Counties:", n_distinct(df_annual$fips_county), "\n")
cat("States:", n_distinct(df_annual$state_fips), "\n")
cat("Years:", range(df_annual$year), "\n")
cat("Treatment cohorts:", sort(unique(df_annual$eitc_year[df_annual$eitc_year > 0])), "\n")
cat("Never-treated counties:", n_distinct(df_annual$fips_county[df_annual$eitc_year == 0]), "\n")
cat("Treated counties:", n_distinct(df_annual$fips_county[df_annual$eitc_year > 0]), "\n")

# --- Save ---
saveRDS(df_annual, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")
