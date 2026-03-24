# =============================================================================
# 02_clean_data.R — Construct analysis sample
# Paper: apep_0879 — MW and racial composition of hiring
# =============================================================================

source("00_packages.R")

qwi_raw <- readRDS("../data/qwi_raw.rds")
mw_panel <- readRDS("../data/mw_panel.rds")

# ---------------------------------------------------------------------------
# 1. Focus on Black (A2) and White (A1) workers, all ethnicities
# ---------------------------------------------------------------------------
# QWI race codes: A0=All, A1=White, A2=Black, A3=AIAN, A4=Asian, A5=NHPI, A7=Two+
# Ethnicity: A0=All, A1=Not Hispanic, A2=Hispanic

df <- qwi_raw %>%
  filter(race %in% c("A1", "A2"), ethnicity == "A0") %>%
  mutate(
    race_label = ifelse(race == "A1", "White", "Black"),
    year_q = year + (quarter - 1) / 4,
    time_period = (year - 2005) * 4 + quarter  # sequential quarter index
  )

cat(sprintf("After race filter: %s rows\n", format(nrow(df), big.mark = ",")))

# ---------------------------------------------------------------------------
# 2. Pivot to wide format: one row per county-quarter-industry
# ---------------------------------------------------------------------------
df_wide <- df %>%
  select(county_fips, state_fips, year, quarter, time_period, year_q,
         industry, race_label, HirN, Sep, Emp, EarnS) %>%
  pivot_wider(
    id_cols = c(county_fips, state_fips, year, quarter, time_period, year_q, industry),
    names_from = race_label,
    values_from = c(HirN, Sep, Emp, EarnS),
    values_fn = sum
  )

cat(sprintf("Wide format: %s rows\n", format(nrow(df_wide), big.mark = ",")))

# ---------------------------------------------------------------------------
# 3. Construct outcome variables
# ---------------------------------------------------------------------------
df_wide <- df_wide %>%
  mutate(
    # Black share of new hires
    total_hires = HirN_Black + HirN_White,
    black_hire_share = ifelse(total_hires > 0, HirN_Black / total_hires, NA_real_),

    # Black-White earnings ratio
    bw_earn_ratio = ifelse(EarnS_White > 0 & EarnS_Black > 0,
                            EarnS_Black / EarnS_White, NA_real_),

    # Black separation rate
    black_sep_rate = ifelse(Emp_Black > 0, Sep_Black / Emp_Black, NA_real_),

    # White separation rate (for comparison)
    white_sep_rate = ifelse(Emp_White > 0, Sep_White / Emp_White, NA_real_)
  )

# ---------------------------------------------------------------------------
# 4. Merge treatment timing
# ---------------------------------------------------------------------------
df_wide <- df_wide %>%
  left_join(mw_panel, by = "state_fips") %>%
  filter(!is.na(first_treat_year))  # drop unclassified states

# Create annual version for CS DiD (which works better with annual data)
df_annual <- df_wide %>%
  group_by(county_fips, state_fips, year, industry, first_treat_year) %>%
  summarise(
    HirN_Black = sum(HirN_Black, na.rm = TRUE),
    HirN_White = sum(HirN_White, na.rm = TRUE),
    Sep_Black = sum(Sep_Black, na.rm = TRUE),
    Sep_White = sum(Sep_White, na.rm = TRUE),
    Emp_Black = mean(Emp_Black, na.rm = TRUE),
    Emp_White = mean(Emp_White, na.rm = TRUE),
    EarnS_Black = mean(EarnS_Black, na.rm = TRUE),
    EarnS_White = mean(EarnS_White, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    total_hires = HirN_Black + HirN_White,
    black_hire_share = ifelse(total_hires > 0, HirN_Black / total_hires, NA_real_),
    bw_earn_ratio = ifelse(EarnS_White > 0 & EarnS_Black > 0,
                            EarnS_Black / EarnS_White, NA_real_),
    black_sep_rate = ifelse(Emp_Black > 0, Sep_Black / Emp_Black, NA_real_),
    # Post indicator
    post = ifelse(first_treat_year > 0 & year >= first_treat_year, 1L, 0L),
    treated = ifelse(first_treat_year > 0, 1L, 0L)
  )

# ---------------------------------------------------------------------------
# 5. Focus on low-wage industries for main analysis
# ---------------------------------------------------------------------------
# MW-exposed: 72 (Accommodation/Food), 44-45 (Retail)
df_lowwage <- df_annual %>%
  filter(industry %in% c("72", "44-45")) %>%
  group_by(county_fips, state_fips, year, first_treat_year, treated, post) %>%
  summarise(
    HirN_Black = sum(HirN_Black, na.rm = TRUE),
    HirN_White = sum(HirN_White, na.rm = TRUE),
    Sep_Black = sum(Sep_Black, na.rm = TRUE),
    Sep_White = sum(Sep_White, na.rm = TRUE),
    Emp_Black = sum(Emp_Black, na.rm = TRUE),
    Emp_White = sum(Emp_White, na.rm = TRUE),
    EarnS_Black = mean(EarnS_Black, na.rm = TRUE),
    EarnS_White = mean(EarnS_White, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    total_hires = HirN_Black + HirN_White,
    black_hire_share = ifelse(total_hires > 0, HirN_Black / total_hires, NA_real_),
    bw_earn_ratio = ifelse(EarnS_White > 0 & EarnS_Black > 0,
                            EarnS_Black / EarnS_White, NA_real_),
    black_sep_rate = ifelse(Emp_Black > 0, Sep_Black / Emp_Black, NA_real_)
  )

# Drop observations with missing outcomes or tiny cells
df_lowwage <- df_lowwage %>%
  filter(!is.na(black_hire_share), total_hires >= 10)

cat(sprintf("Analysis sample (low-wage): %s county-year obs\n",
            format(nrow(df_lowwage), big.mark = ",")))
cat(sprintf("  Treated counties: %d\n", n_distinct(df_lowwage$county_fips[df_lowwage$treated == 1])))
cat(sprintf("  Never-treated counties: %d\n", n_distinct(df_lowwage$county_fips[df_lowwage$treated == 0])))
cat(sprintf("  Years: %d to %d\n", min(df_lowwage$year), max(df_lowwage$year)))

# ---------------------------------------------------------------------------
# 6. Triple-diff dataset: include non-exposed sectors
# ---------------------------------------------------------------------------
df_triple <- df_annual %>%
  mutate(
    mw_exposed = ifelse(industry %in% c("72", "44-45"), 1L, 0L)
  ) %>%
  filter(!is.na(black_hire_share), total_hires >= 10)

# ---------------------------------------------------------------------------
# 7. Summary statistics
# ---------------------------------------------------------------------------
sumstats <- df_lowwage %>%
  summarise(
    mean_bhs = mean(black_hire_share, na.rm = TRUE),
    sd_bhs = sd(black_hire_share, na.rm = TRUE),
    mean_bwer = mean(bw_earn_ratio, na.rm = TRUE),
    sd_bwer = sd(bw_earn_ratio, na.rm = TRUE),
    mean_bsr = mean(black_sep_rate, na.rm = TRUE),
    sd_bsr = sd(black_sep_rate, na.rm = TRUE),
    mean_hires = mean(total_hires, na.rm = TRUE),
    sd_hires = sd(total_hires, na.rm = TRUE),
    n_obs = n(),
    n_counties = n_distinct(county_fips),
    n_states = n_distinct(state_fips),
    n_years = n_distinct(year)
  )

cat("\n--- Summary Statistics ---\n")
print(sumstats)

# ---------------------------------------------------------------------------
# 8. Save
# ---------------------------------------------------------------------------
saveRDS(df_lowwage, "../data/analysis_lowwage.rds")
saveRDS(df_triple, "../data/analysis_triple.rds")
saveRDS(df_annual, "../data/analysis_annual.rds")
saveRDS(sumstats, "../data/sumstats.rds")

cat("\nCleaning complete.\n")
