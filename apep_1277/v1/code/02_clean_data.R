# =============================================================================
# 02_clean_data.R — Construct analysis panel
# Minimum Wages and the Racial Hiring Gap (apep_1277)
# =============================================================================

source("00_packages.R")
data_dir <- "../data/"

# Load raw data
qwi_state <- readRDS(paste0(data_dir, "qwi_state_race.rds"))
qwi_county <- readRDS(paste0(data_dir, "qwi_county_race.rds"))
qwi_industry <- readRDS(paste0(data_dir, "qwi_industry_race.rds"))
mw_raw <- read_csv(paste0(data_dir, "mw_raw.csv"), show_col_types = FALSE)
state_info <- readRDS(paste0(data_dir, "state_info.rds"))

# =============================================================================
# 1. Clean MW panel — quarterly state-level effective minimum wage
# =============================================================================
cat("Constructing quarterly MW panel...\n")

# MW data has columns: year, state (name), state_mw, federal_mw, effective_mw
# Join via state name to get FIPS
mw_panel <- mw_raw %>%
  left_join(state_info %>% select(state_name, state_fips),
            by = c("state" = "state_name")) %>%
  filter(!is.na(state_fips)) %>%
  mutate(
    eff_mw = effective_mw,
    fed_mw = federal_mw
  ) %>%
  select(state_fips, year, eff_mw, fed_mw) %>%
  distinct()

cat("  MW panel:", nrow(mw_panel), "state-years\n")
cat("  States in MW panel:", length(unique(mw_panel$state_fips)), "\n")

# Expand to quarterly (MW is annual effective rate)
mw_quarterly <- mw_panel %>%
  crossing(quarter = 1:4) %>%
  arrange(state_fips, year, quarter) %>%
  mutate(
    time_id = (year - 2005) * 4 + quarter,  # Quarterly time index
    above_federal = as.integer(eff_mw > fed_mw + 0.01),
    mw_gap = eff_mw - fed_mw  # Dollar gap above federal
  )

# =============================================================================
# 2. Define treatment cohorts (first quarter MW exceeds federal)
# =============================================================================
cat("Defining treatment cohorts...\n")

# Treatment = first quarter where state MW > federal (by >$0.25 to avoid rounding)
treatment_timing <- mw_quarterly %>%
  filter(above_federal == 1) %>%
  group_by(state_fips) %>%
  summarise(first_treat_time = min(time_id), .groups = "drop")

# States never above federal in sample = never treated
never_treated <- setdiff(unique(mw_quarterly$state_fips), treatment_timing$state_fips)
cat("  Never-treated states:", length(never_treated), "\n")
cat("  Treated states:", nrow(treatment_timing), "\n")

# Add to quarterly panel
mw_quarterly <- mw_quarterly %>%
  left_join(treatment_timing, by = "state_fips") %>%
  mutate(first_treat_time = ifelse(is.na(first_treat_time), 0, first_treat_time))

# =============================================================================
# 3. Merge QWI state data with MW panel
# =============================================================================
cat("Merging state-level QWI with MW panel...\n")

analysis_state <- qwi_state %>%
  mutate(
    state_fips = as.character(state_fips),
    time_id = (year - 2005) * 4 + quarter
  ) %>%
  inner_join(mw_quarterly, by = c("state_fips", "year", "quarter", "time_id")) %>%
  mutate(
    black = as.integer(race == "A2"),
    log_hires = log(pmax(hires, 1)),
    log_emp = log(pmax(emp, 1)),
    log_seps = log(pmax(seps, 1)),
    state_race_id = paste0(state_fips, "_", race)
  ) %>%
  filter(hires > 0, emp > 0)

cat("  Analysis panel rows:", nrow(analysis_state), "\n")
cat("  State × race units:", length(unique(analysis_state$state_race_id)), "\n")

# =============================================================================
# 4. County-level Kaitz index for DDD
# =============================================================================
cat("Computing county-level Kaitz index...\n")

# Pre-period average earnings by county (2005-2009, before MW wave)
county_baseline <- qwi_county %>%
  filter(year >= 2005, year <= 2009) %>%
  group_by(county_fips, state_fips) %>%
  summarise(
    baseline_earnings = weighted.mean(avg_earnings, emp, na.rm = TRUE),
    baseline_emp = mean(emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(baseline_earnings), baseline_earnings > 0)

cat("  Counties with baseline earnings:", nrow(county_baseline), "\n")

# County-level analysis panel
analysis_county <- qwi_county %>%
  mutate(time_id = (year - 2005) * 4 + quarter) %>%
  inner_join(mw_quarterly %>% select(state_fips, year, quarter, time_id,
                                      eff_mw, fed_mw, above_federal, first_treat_time, mw_gap),
             by = c("state_fips", "year", "quarter", "time_id")) %>%
  inner_join(county_baseline %>% select(county_fips, baseline_earnings),
             by = "county_fips") %>%
  mutate(
    kaitz = eff_mw / (baseline_earnings / (13 * 40)),  # Quarterly earnings → hourly approx
    black = as.integer(race == "A2"),
    log_hires = log(pmax(hires, 1)),
    post = as.integer(time_id >= first_treat_time & first_treat_time > 0),
    county_race_id = paste0(county_fips, "_", race)
  ) %>%
  filter(hires > 0)

# Terciles of Kaitz index for DDD
kaitz_cuts <- quantile(county_baseline$baseline_earnings, probs = c(1/3, 2/3), na.rm = TRUE)
analysis_county <- analysis_county %>%
  mutate(
    high_bite = as.integer(baseline_earnings <= kaitz_cuts[1])  # Low earnings = high MW bite
  )

cat("  County analysis rows:", nrow(analysis_county), "\n")
cat("  High-bite counties:", sum(analysis_county$high_bite == 1 & !duplicated(analysis_county$county_fips)), "\n")

# =============================================================================
# 5. Industry-level panel for mechanism/placebo
# =============================================================================
cat("Building industry-level panel...\n")

analysis_industry <- qwi_industry %>%
  mutate(
    state_fips = as.character(state_fips),
    time_id = (year - 2005) * 4 + quarter,
    black = as.integer(race == "A2"),
    low_wage_industry = as.integer(industry %in% c("44-45", "72")),
    log_hires = log(pmax(hires, 1))
  ) %>%
  inner_join(mw_quarterly %>% select(state_fips, year, quarter, time_id,
                                      eff_mw, above_federal, first_treat_time),
             by = c("state_fips", "year", "quarter", "time_id")) %>%
  filter(hires > 0) %>%
  mutate(
    post = as.integer(time_id >= first_treat_time & first_treat_time > 0),
    state_ind_race_id = paste0(state_fips, "_", industry, "_", race)
  )

cat("  Industry panel rows:", nrow(analysis_industry), "\n")

# =============================================================================
# Save analysis datasets
# =============================================================================
saveRDS(analysis_state, paste0(data_dir, "analysis_state.rds"))
saveRDS(analysis_county, paste0(data_dir, "analysis_county.rds"))
saveRDS(analysis_industry, paste0(data_dir, "analysis_industry.rds"))
saveRDS(mw_quarterly, paste0(data_dir, "mw_quarterly.rds"))

cat("\n=== Clean data complete ===\n")
cat("  State panel:", nrow(analysis_state), "rows,",
    length(unique(analysis_state$state_race_id)), "units\n")
cat("  County panel:", nrow(analysis_county), "rows\n")
cat("  Industry panel:", nrow(analysis_industry), "rows\n")
