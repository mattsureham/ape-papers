# =============================================================================
# 02_clean_data.R — Construct analysis panel for apep_0848
# =============================================================================

source("00_packages.R")

df_sa <- readRDS("../data/qwi_sa_raw.rds")
treatment <- readRDS("../data/treatment_assignment.rds")

# --- Extract state FIPS from county geography code ---
# QWI geography is county FIPS (5-digit, stored as integer)
df_sa <- df_sa %>%
  mutate(
    geography_str = sprintf("%05d", as.integer(geography)),
    state_fips = substr(geography_str, 1, 2),
    county_fips = geography_str,
    yearqtr = year + (quarter - 1) / 4
  )

# --- Keep only states in our treatment assignment ---
df_sa <- df_sa %>%
  filter(state_fips %in% treatment$state_fips)

message(sprintf("After state filter: %s rows", format(nrow(df_sa), big.mark = ",")))

# --- Merge treatment assignment ---
df_sa <- df_sa %>%
  left_join(treatment, by = "state_fips")

# --- Create treatment indicator ---
df_sa <- df_sa %>%
  mutate(
    treated = as.integer(yearqtr >= adopt_yearqtr),
    # For C&S: first_treat as integer period
    # Convert yearqtr to integer period: 2014Q1 = 1, 2014Q2 = 2, etc.
    period = as.integer((year - 2014) * 4 + quarter),
    first_treat_period = case_when(
      group == "founding" ~ as.integer((2018 - 2014) * 4 + 1),  # period 17
      group == "later" ~ as.integer((adopt_yearqtr - 2014) * 4 + 1),
      group == "never" ~ 0L  # never-treated
    ),
    # Healthcare indicator
    is_healthcare = industry %in% c("621", "622", "623"),
    # Sector grouping for placebo
    sector = case_when(
      industry %in% c("621", "622", "623") ~ "Healthcare",
      industry %in% c("441", "442", "443", "444", "445", "446", "447", "448", "449") ~ "Retail",
      industry %in% c("721", "722") ~ "Accommodation/Food",
      TRUE ~ "Other"
    ),
    # Industry label
    industry_label = case_when(
      industry == "621" ~ "Ambulatory Care",
      industry == "622" ~ "Hospitals",
      industry == "623" ~ "Nursing/Residential",
      sector == "Retail" ~ "Retail Trade",
      sector == "Accommodation/Food" ~ "Accommodation/Food",
      TRUE ~ industry
    )
  )

# --- Drop suppressed cells ---
# Status flags: 1 = published, everything else is suppressed or missing
df_sa <- df_sa %>%
  filter(!is.na(Emp), Emp > 0)

message(sprintf("After dropping suppressed: %s rows", format(nrow(df_sa), big.mark = ",")))

# --- Aggregate to county × quarter × industry ---
# Already at this level (sex=0, agegrp=A00), but verify
panel <- df_sa %>%
  group_by(county_fips, state_fips, industry, year, quarter, period,
           group, first_treat_period, treated, is_healthcare, sector, industry_label,
           yearqtr, adopt_yearqtr) %>%
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    HirA = sum(HirA, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    EarnS = weighted.mean(EarnS, w = Emp, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    TurnOvrS = sum(TurnOvrS, na.rm = TRUE),
    .groups = "drop"
  )

# --- Construct rates ---
panel <- panel %>%
  mutate(
    hire_rate = HirA / Emp,
    new_hire_rate = HirN / Emp,
    sep_rate = Sep / Emp,
    turnover_rate = TurnOvrS / Emp,
    log_emp = log(Emp),
    log_earn = log(EarnS)
  ) %>%
  # Winsorize extreme rates (likely small-cell noise)
  mutate(across(c(hire_rate, new_hire_rate, sep_rate, turnover_rate),
                ~ pmin(pmax(., 0), 1)))

# --- Require balanced-ish panel: at least 12 pre-treatment quarters ---
county_industry_counts <- panel %>%
  filter(yearqtr < 2018) %>%
  group_by(county_fips, industry) %>%
  summarise(n_pre = n(), .groups = "drop")

balanced_units <- county_industry_counts %>%
  filter(n_pre >= 12) %>%
  select(county_fips, industry)

panel <- panel %>%
  semi_join(balanced_units, by = c("county_fips", "industry"))

message(sprintf("After balance filter: %s rows, %d county-industry units",
                format(nrow(panel), big.mark = ","),
                nrow(balanced_units)))

# --- Create healthcare-only panel for main analysis ---
panel_hc <- panel %>% filter(is_healthcare)
panel_placebo <- panel %>% filter(!is_healthcare)

# --- Summary stats ---
summary_stats <- panel_hc %>%
  group_by(industry_label) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    n_obs = n(),
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    mean_turnover = mean(turnover_rate, na.rm = TRUE),
    sd_turnover = sd(turnover_rate, na.rm = TRUE),
    .groups = "drop"
  )

print(summary_stats)

# --- Save ---
saveRDS(panel, "../data/panel_full.rds")
saveRDS(panel_hc, "../data/panel_healthcare.rds")
saveRDS(panel_placebo, "../data/panel_placebo.rds")
saveRDS(summary_stats, "../data/summary_stats.rds")

message("Panel construction complete.")
message(sprintf("  Healthcare panel: %s rows, %d counties",
                format(nrow(panel_hc), big.mark = ","),
                n_distinct(panel_hc$county_fips)))
message(sprintf("  Placebo panel: %s rows",
                format(nrow(panel_placebo), big.mark = ",")))
