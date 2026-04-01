# =============================================================================
# 02_clean_data.R — Clean and construct analysis variables
# Paper: apep_1283 — Prevailing Wage Repeals and the Racial Earnings Gap
# =============================================================================

source("00_packages.R")

df_raw <- readRDS("../data/qwi_raw.rds")

# ---------------------------------------------------------------------------
# Filter to state-level, all-firm-ages aggregate
# ---------------------------------------------------------------------------
# geo_level "S" = state; agg_level 1573 = state × industry3 × race (all firms)
# agg_level 1581 includes firm age breakdowns → duplicates
df_raw <- df_raw %>%
  filter(geo_level == "S", agg_level == 1573)

cat("After filtering to state-level aggregates:", nrow(df_raw), "rows\n")

# ---------------------------------------------------------------------------
# Treatment assignment
# ---------------------------------------------------------------------------
treatment_info <- tribble(
  ~state_abbr, ~repeal_yq,
  "in", 2015.75,
  "wv", 2016.00,
  "ky", 2017.00,
  "ar", 2017.00,
  "wi", 2017.75,
  "mi", 2018.25
)

# Create year-quarter numeric: 2015Q1 = 2015.00, Q2 = 2015.25, etc.
df <- df_raw %>%
  mutate(
    industry_int = as.integer(industry),
    yq = year + (quarter - 1) / 4
  )

# Merge treatment info
df <- df %>%
  left_join(treatment_info, by = "state_abbr") %>%
  mutate(
    treated_state = !is.na(repeal_yq),
    # For Callaway-Sant'Anna: first_treat must be numeric period index
    # Convert yq to integer period: quarters since 2010Q1
    period = as.integer(round((yq - 2010) * 4)) + 1L,
    first_treat_period = ifelse(treated_state,
      as.integer(round((repeal_yq - 2010) * 4)) + 1L, 0L)
  )

# ---------------------------------------------------------------------------
# Construction subsector classification
# ---------------------------------------------------------------------------
df <- df %>%
  mutate(
    sector = case_when(
      industry_int == 236 ~ "Building (236)",
      industry_int == 237 ~ "Heavy/Civil (237)",
      industry_int == 238 ~ "Specialty Trades (238)",
      industry_int %in% c(311, 332, 336) ~ "Manufacturing",
      TRUE ~ "Other"
    ),
    is_construction = industry_int %in% c(236, 237, 238),
    is_public_construction = industry_int == 237
  )

# ---------------------------------------------------------------------------
# Construct B/W earnings ratio at state × quarter × industry level
# ---------------------------------------------------------------------------
# Pivot: one row per state × quarter × industry with White and Black earnings
df_wide <- df %>%
  filter(race %in% c("A1", "A2")) %>%
  select(state_abbr, year, quarter, yq, period, industry_int, sector,
         is_construction, is_public_construction, race, EarnS, Emp,
         treated_state, repeal_yq, first_treat_period) %>%
  pivot_wider(
    names_from = race,
    values_from = c(EarnS, Emp),
    names_sep = "_"
  ) %>%
  rename(
    earn_white = EarnS_A1,
    earn_black = EarnS_A2,
    emp_white = Emp_A1,
    emp_black = Emp_A2
  )

# Compute B/W earnings ratio (drop cells where either is missing/zero)
df_analysis <- df_wide %>%
  filter(!is.na(earn_white) & !is.na(earn_black)) %>%
  filter(earn_white > 0 & earn_black > 0) %>%
  mutate(
    bw_ratio = earn_black / earn_white,
    ln_earn_black = log(earn_black),
    ln_earn_white = log(earn_white),
    ln_bw_gap = ln_earn_black - ln_earn_white,
    total_emp = ifelse(is.na(emp_white), 0, emp_white) +
                ifelse(is.na(emp_black), 0, emp_black)
  )

# ---------------------------------------------------------------------------
# Aggregate to state × quarter for main analysis
# (weighted by total employment in each industry)
# ---------------------------------------------------------------------------

# State × quarter × sector level (for mechanism test)
df_sector <- df_analysis %>%
  filter(is_construction) %>%
  group_by(state_abbr, year, quarter, yq, period, sector, industry_int,
           is_public_construction, treated_state, repeal_yq, first_treat_period) %>%
  summarise(
    bw_ratio = weighted.mean(bw_ratio, total_emp, na.rm = TRUE),
    earn_black = weighted.mean(earn_black, emp_black, na.rm = TRUE),
    earn_white = weighted.mean(earn_white, emp_white, na.rm = TRUE),
    emp_black = sum(emp_black, na.rm = TRUE),
    emp_white = sum(emp_white, na.rm = TRUE),
    total_emp = sum(total_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(ln_bw_gap = log(earn_black) - log(earn_white))

# State × quarter level (all construction combined)
df_state <- df_analysis %>%
  filter(is_construction) %>%
  group_by(state_abbr, year, quarter, yq, period,
           treated_state, repeal_yq, first_treat_period) %>%
  summarise(
    bw_ratio = weighted.mean(bw_ratio, total_emp, na.rm = TRUE),
    earn_black = weighted.mean(earn_black, emp_black, na.rm = TRUE),
    earn_white = weighted.mean(earn_white, emp_white, na.rm = TRUE),
    emp_black = sum(emp_black, na.rm = TRUE),
    emp_white = sum(emp_white, na.rm = TRUE),
    total_emp = sum(total_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(ln_bw_gap = log(earn_black) - log(earn_white))

# Manufacturing placebo (state × quarter)
df_mfg <- df_analysis %>%
  filter(!is_construction) %>%
  group_by(state_abbr, year, quarter, yq, period,
           treated_state, repeal_yq, first_treat_period) %>%
  summarise(
    bw_ratio = weighted.mean(bw_ratio, total_emp, na.rm = TRUE),
    earn_black = weighted.mean(earn_black, emp_black, na.rm = TRUE),
    earn_white = weighted.mean(earn_white, emp_white, na.rm = TRUE),
    emp_black = sum(emp_black, na.rm = TRUE),
    emp_white = sum(emp_white, na.rm = TRUE),
    total_emp = sum(total_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(ln_bw_gap = log(earn_black) - log(earn_white))

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------
cat("\n=== Data Summary ===\n")
cat("State-quarter panel (construction):", nrow(df_state), "rows\n")
cat("  Treated states:", n_distinct(df_state$state_abbr[df_state$treated_state]), "\n")
cat("  Control states:", n_distinct(df_state$state_abbr[!df_state$treated_state]), "\n")
cat("  Quarters:", n_distinct(df_state$period), "\n")
cat("  B/W ratio: mean =", round(mean(df_state$bw_ratio, na.rm=TRUE), 3),
    "sd =", round(sd(df_state$bw_ratio, na.rm=TRUE), 3), "\n")

cat("\nSector panel:", nrow(df_sector), "rows\n")
cat("  NAICS 237 (public) obs:", sum(df_sector$industry_int == 237), "\n")
cat("  NAICS 236 (building) obs:", sum(df_sector$industry_int == 236), "\n")
cat("  NAICS 238 (specialty) obs:", sum(df_sector$industry_int == 238), "\n")

cat("\nManufacturing placebo:", nrow(df_mfg), "rows\n")

# Assertions
stopifnot(
  "Need >= 20 treated state-quarters" =
    sum(df_state$treated_state & df_state$period >= min(df_state$first_treat_period[df_state$treated_state])) >= 20,
  "Need >= 5 pre-treatment periods" =
    (min(df_state$first_treat_period[df_state$treated_state]) - min(df_state$period)) >= 5,
  "B/W ratio should be between 0.3 and 1.5" =
    all(df_state$bw_ratio > 0.3 & df_state$bw_ratio < 1.5, na.rm = TRUE)
)

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------
saveRDS(df_state, "../data/analysis_state.rds")
saveRDS(df_sector, "../data/analysis_sector.rds")
saveRDS(df_mfg, "../data/analysis_mfg.rds")
saveRDS(df_analysis, "../data/analysis_cell.rds")

cat("\nAll analysis datasets saved.\n")
