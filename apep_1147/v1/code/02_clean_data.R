## ── 02_clean_data.R ───────────────────────────────────────────────────────
## Clean QWI data and construct analysis panel
## ───────────────────────────────────────────────────────────────────────────

source("00_packages.R")

df_all <- readRDS("../data/qwi_race_all_industries.rds")
df_mfg <- readRDS("../data/qwi_race_manufacturing.rds")

## ── RTW treatment coding ─────────────────────────────────────────────────
rtw_timing <- data.frame(
  state_fips = c("18", "26", "55", "54"),
  state_name = c("Indiana", "Michigan", "Wisconsin", "West Virginia"),
  rtw_year = c(2012, 2013, 2015, 2016),
  rtw_quarter = c(1, 1, 1, 3),  # Q1 2012, Q1 2013, Q1 2015, Q3 2016
  stringsAsFactors = FALSE
)

# Convert to a single time index: year * 4 + quarter
rtw_timing$first_treat <- rtw_timing$rtw_year * 4 + rtw_timing$rtw_quarter

comparison_fips <- c("17", "39", "27", "42", "36")
comp_names <- c("Illinois", "Ohio", "Minnesota", "Pennsylvania", "New York")

## ── Build analysis panel ─────────────────────────────────────────────────
build_panel <- function(df, label = "all") {
  panel <- df %>%
    mutate(
      state_fips = substr(geography, 1, 2),
      county_fips = geography,
      time = year * 4 + quarter,
      race_label = case_when(
        race == "A1" ~ "White",
        race == "A2" ~ "Black",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(race_label)) %>%
    # Drop observations with missing earnings or employment
    filter(!is.na(EarnS) & EarnS > 0 & !is.na(Emp) & Emp > 0) %>%
    # Add treatment info
    left_join(rtw_timing %>% select(state_fips, rtw_year, first_treat),
              by = "state_fips") %>%
    mutate(
      treated_state = state_fips %in% rtw_timing$state_fips,
      # For CS DiD: first_treat = 0 for never-treated
      first_treat = ifelse(is.na(first_treat), 0, first_treat),
      rtw_year = ifelse(is.na(rtw_year), 0, rtw_year),
      # Post indicator
      post = case_when(
        !treated_state ~ 0L,
        time >= first_treat ~ 1L,
        TRUE ~ 0L
      ),
      # Log earnings
      log_earn = log(EarnS),
      # County-race unit ID
      unit_id = paste0(county_fips, "_", race),
      # Numeric unit for CS DiD
      unit_num = as.integer(factor(unit_id)),
      # Black indicator
      black = as.integer(race == "A2"),
      # Separation rate
      sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_)
    )

  cat(sprintf("\n[%s] Panel dimensions:\n", label))
  cat(sprintf("  Counties: %d\n", n_distinct(panel$county_fips)))
  cat(sprintf("  States:   %d\n", n_distinct(panel$state_fips)))
  cat(sprintf("  Periods:  %d-%d\n", min(panel$time), max(panel$time)))
  cat(sprintf("  Obs:      %d\n", nrow(panel)))

  return(panel)
}

panel_all <- build_panel(df_all, "All industries")
panel_mfg <- build_panel(df_mfg, "Manufacturing")

## ── Restrict to balanced-ish sample ──────────────────────────────────────
# Keep counties with data for both races in at least 20 quarters pre-treatment
min_pre_quarters <- 20
min_year <- 2005  # Start from 2005 for cleaner panel

panel_all <- panel_all %>% filter(year >= min_year & year <= 2023)
panel_mfg <- panel_mfg %>% filter(year >= min_year & year <= 2023)

# Identify counties with both races present
county_race_coverage <- panel_all %>%
  filter(year <= 2011) %>%  # Pre-period for earliest treated state
  group_by(county_fips, race_label) %>%
  summarise(n_qtrs = n(), .groups = "drop") %>%
  filter(n_qtrs >= min_pre_quarters) %>%
  group_by(county_fips) %>%
  filter(n() == 2) %>%  # Both races present

  ungroup()

balanced_counties <- unique(county_race_coverage$county_fips)
cat(sprintf("\nCounties with both races (≥%d pre-quarters): %d\n",
            min_pre_quarters, length(balanced_counties)))

panel_all <- panel_all %>% filter(county_fips %in% balanced_counties)
panel_mfg <- panel_mfg %>% filter(county_fips %in% balanced_counties)

## ── Create state-level aggregates for summary stats ──────────────────────
state_panel <- panel_all %>%
  group_by(state_fips, year, quarter, time, race_label, treated_state,
           rtw_year, first_treat) %>%
  summarise(
    earn = weighted.mean(EarnS, w = Emp, na.rm = TRUE),
    emp = sum(Emp, na.rm = TRUE),
    hires = sum(HirA, na.rm = TRUE),
    seps = sum(Sep, na.rm = TRUE),
    n_counties = n(),
    .groups = "drop"
  ) %>%
  mutate(
    log_earn = log(earn),
    sep_rate = seps / emp,
    post = ifelse(rtw_year > 0 & year >= rtw_year, 1L, 0L)
  )

## ── Summary statistics ──────────────────────────────────────────────────
cat("\n=== Summary Statistics ===\n")
panel_all %>%
  group_by(treated_state, race_label) %>%
  summarise(
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  print()

## ── Save ─────────────────────────────────────────────────────────────────
saveRDS(panel_all, "../data/panel_all.rds")
saveRDS(panel_mfg, "../data/panel_mfg.rds")
saveRDS(state_panel, "../data/state_panel.rds")

cat("\nCleaned panels saved.\n")
