# =============================================================================
# 02_clean_data.R — Construct treatment variables and analysis sample
# =============================================================================

source("00_packages.R")

df_raw <- arrow::read_parquet("../data/qwi_rh_ns_raw.parquet")

# --- Filter to state-level observations ---
df_state <- df_raw %>% filter(geo_level == "S")
cat(sprintf("State-level rows: %s (from %s total)\n",
            format(nrow(df_state), big.mark = ","),
            format(nrow(df_raw), big.mark = ",")))
rm(df_raw); gc()

# --- State FIPS as zero-padded string ---
df_state <- df_state %>%
  mutate(state_fips = sprintf("%02d", as.integer(geography)))

# --- Race/ethnicity coding ---
# QWI rh codes: race A0=All, A1=White, A2=Black, A3=AIAN, A4=Asian, A5=NHPI, A7=Two+
#               ethnicity A0=All, A1=Not Hispanic, A2=Hispanic
df_state <- df_state %>%
  mutate(
    race_group = case_when(
      race == "A1" & ethnicity == "A0" ~ "White",       # White, all ethnicities
      race == "A2" & ethnicity == "A0" ~ "Black",       # Black, all ethnicities
      race == "A0" & ethnicity == "A2" ~ "Hispanic",    # All races, Hispanic
      race == "A0" & ethnicity == "A1" ~ "NonHispanic", # All races, Not Hispanic
      race == "A0" & ethnicity == "A0" ~ "All",         # All races, all ethnicities
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(race_group))

cat(sprintf("After race filtering: %s rows\n", format(nrow(df_state), big.mark = ",")))

# --- Treatment classification ---
# One Fair Wage states: never allowed a tip credit
ofw_states <- c("02", "06", "27", "30", "32", "41", "53")

# Reform states with specific timing
reform_timing <- tibble(
  state_fips = c("04", "11", "26"),
  reform_year = c(2017, 2023, 2024),
  reform_quarter = c(1, 2, 1),
  state_name = c("Arizona", "DC", "Michigan")
)

# Low-tipped states ($2.13 federal floor)
low_tipped <- c("01", "05", "12", "13", "18", "19", "20", "21",
                "22", "28", "29", "31", "35", "37", "38", "40",
                "42", "45", "46", "47", "48", "49", "50", "51",
                "54", "55", "56")

df_state <- df_state %>%
  mutate(
    year = as.integer(year),
    quarter = as.integer(quarter),
    time_q = year + (quarter - 1) / 4,
    yearq = paste0(year, "Q", quarter),
    tipped_group = case_when(
      state_fips %in% ofw_states ~ "OFW",
      state_fips %in% reform_timing$state_fips ~ "Reform",
      state_fips %in% low_tipped ~ "LowTipped",
      TRUE ~ "Other"
    ),
    food_services = as.integer(industry == "72"),
    is_treatment_industry = industry == "72"
  ) %>%
  left_join(reform_timing, by = "state_fips")

# Post-reform indicator
df_state <- df_state %>%
  mutate(
    post_reform = case_when(
      state_fips == "04" & (year > 2017 | (year == 2017 & quarter >= 1)) ~ 1L,
      state_fips == "11" & (year > 2023 | (year == 2023 & quarter >= 2)) ~ 1L,
      state_fips == "26" & (year > 2024 | (year == 2024 & quarter >= 1)) ~ 1L,
      TRUE ~ 0L
    ),
    first_treat = case_when(
      state_fips == "04" ~ 2017L,
      state_fips == "11" ~ 2023L,
      state_fips == "26" ~ 2024L,
      TRUE ~ 0L
    )
  )

# --- Earnings ratio construction ---
earn_wide <- df_state %>%
  filter(race_group %in% c("White", "Black", "Hispanic", "NonHispanic", "All")) %>%
  select(state_fips, year, quarter, time_q, yearq, industry, race_group,
         EarnS, Emp, HirA, Sep, tipped_group, food_services,
         is_treatment_industry, post_reform, first_treat) %>%
  filter(!is.na(EarnS), EarnS > 0, !is.na(Emp), Emp > 0)

cat(sprintf("Earn wide sample: %s rows\n", format(nrow(earn_wide), big.mark = ",")))

# Pivot to get earnings by race as columns
earn_ratios <- earn_wide %>%
  select(state_fips, year, quarter, time_q, yearq, industry, race_group, EarnS, Emp) %>%
  pivot_wider(
    names_from = race_group,
    values_from = c(EarnS, Emp),
    names_sep = "_"
  ) %>%
  mutate(
    bw_ratio = EarnS_Black / EarnS_White,
    hisp_ratio = EarnS_Hispanic / EarnS_NonHispanic,
    ln_earn_black = log(EarnS_Black),
    ln_earn_white = log(EarnS_White),
    ln_earn_hisp = log(EarnS_Hispanic),
    ln_earn_all = log(EarnS_All),
    ln_bw_gap = ln_earn_black - ln_earn_white,
    ln_hisp_gap = ln_earn_hisp - log(EarnS_NonHispanic)
  )

# Rejoin treatment info
earn_ratios <- earn_ratios %>%
  left_join(
    df_state %>%
      select(state_fips, year, quarter, industry, tipped_group,
             food_services, is_treatment_industry, post_reform, first_treat) %>%
      distinct(),
    by = c("state_fips", "year", "quarter", "industry")
  )

# Filter to analysis sample
analysis <- earn_ratios %>%
  filter(year >= 2005, year <= 2024) %>%
  filter(industry %in% c("72", "44-45")) %>%
  filter(!is.na(bw_ratio)) %>%
  group_by(state_fips) %>%
  filter(n() >= 20) %>%
  ungroup()

cat(sprintf("\nAnalysis sample: %s obs, %d states, %d quarters\n",
            format(nrow(analysis), big.mark = ","),
            n_distinct(analysis$state_fips),
            n_distinct(analysis$yearq)))

# Quick sanity check
cat("\n=== Pre-reform B-W ratio by group (NAICS 72) ===\n")
analysis %>%
  filter(year <= 2016, industry == "72") %>%
  group_by(tipped_group) %>%
  summarise(
    n = n(),
    states = n_distinct(state_fips),
    bw_ratio = mean(bw_ratio, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Placebo sample
placebo <- earn_ratios %>%
  filter(year >= 2005, year <= 2024) %>%
  filter(industry %in% c("62", "54")) %>%
  filter(!is.na(bw_ratio))

# Save long-format data for employment regressions
earn_long_save <- earn_wide %>%
  filter(year >= 2005, year <= 2024)

# Save
arrow::write_parquet(analysis, "../data/analysis_sample.parquet")
arrow::write_parquet(placebo, "../data/placebo_sample.parquet")
arrow::write_parquet(earn_long_save, "../data/earn_long.parquet")

cat(sprintf("\nSaved:\n  analysis: %s obs\n  placebo: %s obs\n  earn_long: %s obs\n",
            format(nrow(analysis), big.mark = ","),
            format(nrow(placebo), big.mark = ","),
            format(nrow(earn_long_save), big.mark = ",")))
