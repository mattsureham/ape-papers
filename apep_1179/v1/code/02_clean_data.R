## 02_clean_data.R — Construct analysis panel
## apep_1179: Anti-corruption enforcement and fiscal composition in China

source("00_packages.R")

corr_raw <- readRDS("../data/corruption_raw.rds")
city_raw <- readRDS("../data/city_yearbook_raw.rds")

# =============================================================================
# 1. Construct prefecture-level treatment from corruption data
# =============================================================================

# The CCDI campaign launched formally in December 2012.
# We define treatment at the prefecture level using investigation INTENSITY
# (number of officials investigated) as well as first-year timing.

corr <- corr_raw %>%
  as_tibble() %>%
  filter(!is.na(Year), !is.na(prefectureid)) %>%
  mutate(
    year = as.integer(Year),
    pref_id = as.integer(prefectureid),
    # Extract 4-digit prefecture code
    pref_code = as.integer(substr(sprintf("%06d", pref_id), 1, 4)),
    # Clean prefecture name
    pref_name = gsub('"', '', prefecture)
  )

# Campaign = 2013 onward
campaign <- corr %>%
  filter(year >= 2013)

# Prefecture-level treatment measures
pref_treatment <- campaign %>%
  group_by(pref_code, pref_name) %>%
  summarise(
    first_inv_year = min(year),
    total_inv = n(),
    # Rank-weighted intensity: higher-rank officials = bigger shock
    high_rank_inv = sum(rank >= 7, na.rm = TRUE),
    .groups = "drop"
  )

cat("Prefectures with campaign investigations:", nrow(pref_treatment), "\n")
cat("Treatment timing:\n")
print(table(pref_treatment$first_inv_year))

# =============================================================================
# 2. Clean city yearbook fiscal data
# =============================================================================

city <- city_raw %>%
  transmute(
    city_name = as.character(城市),
    year = as.integer(年份),
    gdp = as.numeric(地区生产总值万元),
    gdp_pc = as.numeric(人均地区生产总值元),
    pop = as.numeric(年平均人口万人),
    fiscal_exp = as.numeric(地方财政一般预算内支出万元),
    fiscal_rev = as.numeric(地方财政一般预算内收入万元),
    edu_exp = as.numeric(教育支出万元),
    sci_exp = as.numeric(科学支出万元),
    fai = as.numeric(固定资产投资总额万元),
    gdp_secondary = as.numeric(第二产业增加值万元),
    gdp_tertiary = as.numeric(第三产业增加值万元),
    hosp_beds = as.numeric(医院卫生院床位数张),
    doctors = as.numeric(医生数人)
  ) %>%
  filter(year >= 2007, year <= 2016) %>%
  mutate(
    city_clean = gsub("市$", "", trimws(city_name))
  )

cat("\nCity panel 2007-2016:", nrow(city), "obs,", n_distinct(city$city_name), "cities\n")

# =============================================================================
# 3. Build concordance (one-to-one: each city maps to one prefecture)
# =============================================================================

# Multiple prefecture codes may share a city name (e.g., municipal districts).
# Keep the code with the MOST investigations (most relevant treatment unit).
pref_for_merge <- pref_treatment %>%
  mutate(city_match = gsub("市$|区$|地区$|自治州$|盟$", "", pref_name)) %>%
  group_by(city_match) %>%
  # If multiple codes map to same city, keep the one with most investigations
  slice_max(total_inv, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(pref_code, city_clean = city_match, first_inv_year, total_inv, high_rank_inv)

# Exact merge
concordance <- pref_for_merge %>%
  filter(city_clean %in% unique(city$city_clean))

cat("Cities matched to corruption data:", nrow(concordance), "\n")

# =============================================================================
# 4. Merge and construct analysis variables
# =============================================================================

panel <- city %>%
  left_join(concordance, by = "city_clean", relationship = "many-to-one") %>%
  mutate(
    # Treatment timing (0 = never-treated for CS estimator)
    first_treat = ifelse(is.na(first_inv_year), 0, first_inv_year),
    # Binary post-treatment
    post = as.integer(first_treat > 0 & year >= first_treat),
    # Treatment intensity: total investigations (0 for never-treated)
    intensity = ifelse(is.na(total_inv), 0, total_inv),
    # Log intensity for dose-response
    log_intensity = log1p(intensity),
    # Fiscal composition outcomes
    edu_share = edu_exp / fiscal_exp,
    sci_share = sci_exp / fiscal_exp,
    fai_share = fai / gdp,
    edu_gdp = edu_exp / gdp,
    # Log outcomes
    log_edu_exp = log(edu_exp),
    log_fiscal_exp = log(fiscal_exp),
    log_fai = log(fai),
    log_gdp = log(gdp),
    # Per-capita outcomes (pop in 10,000s)
    edu_pc = edu_exp / pop,
    fiscal_pc = fiscal_exp / pop,
    beds_pc = hosp_beds / (pop * 10000),  # beds per person
    docs_pc = doctors / (pop * 10000)
  ) %>%
  # Create numeric city ID
  mutate(city_id = as.integer(factor(city_name)))

# Drop cities with > 50% missing fiscal data
city_miss <- panel %>%
  group_by(city_id) %>%
  summarise(pct_miss = mean(is.na(edu_share))) %>%
  filter(pct_miss <= 0.5)

panel <- panel %>% filter(city_id %in% city_miss$city_id)

# =============================================================================
# 5. Panel diagnostics
# =============================================================================

cat("\n=== ANALYSIS PANEL ===\n")
cat("City-years:", nrow(panel), "\n")
cat("Unique cities:", n_distinct(panel$city_id), "\n")
cat("Year range:", range(panel$year), "\n")

# Treatment group sizes
treat_tab <- panel %>%
  filter(year == min(year)) %>%
  count(first_treat, name = "n_cities")
cat("\nTreatment cohorts:\n")
print(treat_tab)

n_treated <- sum(treat_tab$n_cities[treat_tab$first_treat > 0])
n_control <- sum(treat_tab$n_cities[treat_tab$first_treat == 0])
cat(sprintf("\nTreated: %d cities, Never-treated: %d cities\n", n_treated, n_control))
cat("Pre-periods (2007-2012): 6 years\n")

# Intensity distribution (among treated)
treated_panel <- panel %>% filter(first_treat > 0, year == min(year))
cat(sprintf("\nIntensity among treated: mean=%.1f, median=%.0f, max=%d\n",
            mean(treated_panel$intensity),
            median(treated_panel$intensity),
            max(treated_panel$intensity)))

# Check fiscal variable coverage
cat("\nVariable coverage (non-missing %):\n")
vars_check <- c("edu_share", "sci_share", "fai_share", "log_edu_exp", "log_fiscal_exp")
for (v in vars_check) {
  cat(sprintf("  %s: %.1f%%\n", v, 100 * mean(!is.na(panel[[v]]))))
}

# Pre-treatment means by treatment group
cat("\nPre-treatment means (2007-2012):\n")
pre <- panel %>% filter(year < 2013)
pre_means <- pre %>%
  group_by(treated = first_treat > 0) %>%
  summarise(
    edu_share = mean(edu_share, na.rm = TRUE),
    sci_share = mean(sci_share, na.rm = TRUE),
    fai_share = mean(fai_share, na.rm = TRUE),
    log_gdp = mean(log_gdp, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
print(pre_means)

# =============================================================================
# 6. Save
# =============================================================================
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nAnalysis panel saved to data/analysis_panel.rds\n")
