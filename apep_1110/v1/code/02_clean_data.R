# 02_clean_data.R — Construct analysis panel
# APEP paper apep_1110: UK Sugar Tax and Childhood Dental Decay

source("code/00_packages.R")

# ============================================================================
# 1. Load raw data
# ============================================================================
dental_raw <- read_csv("data/dental_extractions_raw.csv", show_col_types = FALSE)
imd_raw    <- read_csv("data/imd_raw.csv", show_col_types = FALSE)
obesity_raw <- read_csv("data/obesity_raw.csv", show_col_types = FALSE)

# ============================================================================
# 2. Clean dental decay data — filter to upper-tier LAs
# ============================================================================
dental <- dental_raw %>%
  filter(`Area Type` %in% c("County", "UA")) %>%
  select(area_code = `Area Code`,
         area_name = `Area Name`,
         area_type = `Area Type`,
         time_period = `Time period`,
         decay_pct = Value,
         count = Count,
         denominator = Denominator,
         lower_ci = `Lower CI 95.0 limit`,
         upper_ci = `Upper CI 95.0 limit`) %>%
  filter(!is.na(decay_pct))

# Create numeric year variable (start year of academic year)
dental <- dental %>%
  mutate(year = as.numeric(substr(time_period, 1, 4)))

cat("Dental data: ", nrow(dental), " LA-year observations\n")
cat("LAs: ", n_distinct(dental$area_code), "\n")
cat("Years: ", paste(sort(unique(dental$year)), collapse = ", "), "\n")

# ============================================================================
# 3. Clean IMD data — single 2019 cross-section
# ============================================================================
imd <- imd_raw %>%
  filter(`Area Type` %in% c("County", "UA")) %>%
  select(area_code = `Area Code`,
         imd_score = Value) %>%
  filter(!is.na(imd_score))

cat("\nIMD: ", nrow(imd), " LAs with deprivation scores\n")
cat("Range: ", min(imd$imd_score), " to ", max(imd$imd_score), "\n")

# ============================================================================
# 4. Clean childhood obesity data (Year 6)
# ============================================================================
obesity <- obesity_raw %>%
  filter(`Area Type` %in% c("County", "UA")) %>%
  select(area_code = `Area Code`,
         time_period = `Time period`,
         obesity_pct = Value) %>%
  filter(!is.na(obesity_pct)) %>%
  mutate(year = as.numeric(substr(time_period, 1, 4)))

# Use the most recent pre-treatment obesity rate as a control
obesity_pre <- obesity %>%
  filter(year <= 2017) %>%
  group_by(area_code) %>%
  slice_max(year, n = 1) %>%
  ungroup() %>%
  select(area_code, obesity_pct_pre = obesity_pct)

cat("\nObesity controls: ", nrow(obesity_pre), " LAs with pre-treatment obesity rates\n")

# ============================================================================
# 5. Merge into analysis panel
# ============================================================================
panel <- dental %>%
  left_join(imd, by = "area_code") %>%
  left_join(obesity_pre, by = "area_code")

# Drop LAs without IMD
panel <- panel %>% filter(!is.na(imd_score))

cat("\n=== Analysis Panel ===\n")
cat("Observations: ", nrow(panel), "\n")
cat("LAs: ", n_distinct(panel$area_code), "\n")
cat("Time periods: ", paste(sort(unique(panel$year)), collapse = ", "), "\n")

# ============================================================================
# 6. Create treatment variables
# ============================================================================
# SDIL implemented April 2018
# Survey years: 2007, 2011, 2014, 2016, 2018, 2021, 2023
# Post-treatment: 2018/19 onward (first survey fully after implementation)
# Note: 2016/17 is after announcement (March 2016) but before implementation
#   → treat as transition/anticipation period

panel <- panel %>%
  mutate(
    # Binary post indicator
    post = ifelse(year >= 2018, 1, 0),

    # Continuous treatment intensity (IMD score, standardized)
    imd_std = (imd_score - mean(imd_score)) / sd(imd_score),

    # Interaction: DiD coefficient
    post_x_imd = post * imd_std,

    # Event time relative to SDIL implementation (2018)
    # For event study
    event_time = case_when(
      year == 2007 ~ -3,  # reference: furthest pre-period
      year == 2011 ~ -2,
      year == 2014 ~ -1,  # last clean pre-period
      year == 2016 ~ 0,   # announcement period (transition)
      year == 2018 ~ 1,   # first post-implementation
      year == 2021 ~ 2,   # post (COVID-affected)
      year == 2023 ~ 3    # post
    ),

    # Quadratic IMD for nonlinear effects
    imd_std_sq = imd_std^2,

    # IMD quartiles for heterogeneity
    imd_quartile = ntile(imd_score, 4)
  )

cat("\n=== Treatment variable summary ===\n")
cat("Post==1 observations: ", sum(panel$post), "\n")
cat("Post==0 observations: ", sum(panel$post == 0), "\n")
cat("IMD std range: ", round(range(panel$imd_std), 2), "\n")

# ============================================================================
# 7. Summary statistics for balanced panel check
# ============================================================================
balance <- panel %>%
  group_by(year) %>%
  summarise(
    n_la = n(),
    mean_decay = round(mean(decay_pct, na.rm = TRUE), 1),
    sd_decay = round(sd(decay_pct, na.rm = TRUE), 1),
    mean_imd = round(mean(imd_score, na.rm = TRUE), 1)
  )

cat("\n=== Panel balance ===\n")
print(as.data.frame(balance))

# ============================================================================
# 8. Save analysis dataset
# ============================================================================
write_csv(panel, "data/analysis_panel.csv")
cat("\nSaved analysis_panel.csv (", nrow(panel), " rows)\n")

# Also save summary for later tables
saveRDS(list(
  panel = panel,
  balance = balance,
  n_la = n_distinct(panel$area_code),
  n_obs = nrow(panel),
  years = sort(unique(panel$year)),
  imd_range = range(panel$imd_score)
), "data/panel_summary.rds")
cat("Saved panel_summary.rds\n")
