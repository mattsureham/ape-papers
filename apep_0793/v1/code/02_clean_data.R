## 02_clean_data.R — Construct analysis dataset
## apep_0793: The Innovation Supply Chain

source("00_packages.R")

# ===========================================================================
# Load raw data
# ===========================================================================
ipeds_county <- readRDS("../data/ipeds_county.rds")
national_stem <- readRDS("../data/national_stem.rds")
qwi_info_sa <- readRDS("../data/qwi_info_sa.rds")
qwi_info_se <- readRDS("../data/qwi_info_se.rds")
qwi_food_sa <- readRDS("../data/qwi_food_sa.rds")

# ===========================================================================
# 1. Annualize QWI (average across quarters)
# ===========================================================================
cat("Annualizing QWI...\n")

# QWI geography is integer county FIPS
qwi_annual <- qwi_info_sa %>%
  mutate(county_fips = sprintf("%05d", as.integer(geography))) %>%
  group_by(county_fips, year) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    emp_end = mean(emp_end, na.rm = TRUE),
    hir_all = sum(hir_all, na.rm = TRUE),
    hir_new = sum(hir_new, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    firm_job_gain = sum(firm_job_gain, na.rm = TRUE),
    firm_job_loss = sum(firm_job_loss, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    n_quarters = n(),
    .groups = "drop"
  ) %>%
  # Only keep county-years with all 4 quarters
  filter(n_quarters == 4)

cat(sprintf("QWI annual Info: %d obs, %d counties\n",
            nrow(qwi_annual), n_distinct(qwi_annual$county_fips)))

# Accommodation/Food placebo (annualized)
qwi_food_annual <- qwi_food_sa %>%
  mutate(county_fips = sprintf("%05d", as.integer(geography))) %>%
  group_by(county_fips, year) %>%
  summarise(
    emp_food = mean(emp, na.rm = TRUE),
    hir_food = sum(hir_all, na.rm = TRUE),
    firm_job_gain_food = sum(firm_job_gain, na.rm = TRUE),
    firm_job_loss_food = sum(firm_job_loss, na.rm = TRUE),
    earn_food = mean(earn_s, na.rm = TRUE),
    n_quarters = n(),
    .groups = "drop"
  ) %>%
  filter(n_quarters == 4) %>%
  select(-n_quarters)

# Education-level QWI for skill premium
# education: E0=All, E1=Less than HS, E2=HS no college, E3=Some college, E4=BA+, E5=Advanced
qwi_edu_annual <- qwi_info_se %>%
  mutate(county_fips = sprintf("%05d", as.integer(geography))) %>%
  filter(education %in% c("E0", "E3", "E4", "E5")) %>%
  group_by(county_fips, year, education) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    earn = mean(earn_s, na.rm = TRUE),
    n_quarters = n(),
    .groups = "drop"
  ) %>%
  filter(n_quarters == 4) %>%
  select(-n_quarters)

# Construct skill premium: (BA+ earnings) / (Some college earnings)
skill_premium <- qwi_edu_annual %>%
  select(county_fips, year, education, emp, earn) %>%
  pivot_wider(
    names_from = education,
    values_from = c(emp, earn),
    names_sep = "_"
  ) %>%
  mutate(
    ba_share = emp_E4 / (emp_E3 + emp_E4 + emp_E5),
    ba_plus_share = (emp_E4 + emp_E5) / emp_E0,
    skill_premium = earn_E4 / earn_E3,
    log_skill_premium = log(earn_E4 / earn_E3)
  ) %>%
  filter(is.finite(log_skill_premium), !is.na(log_skill_premium))

cat(sprintf("Skill premium: %d obs\n", nrow(skill_premium)))

# ===========================================================================
# 2. Construct Bartik instrument
# ===========================================================================
cat("\nConstructing Bartik instrument...\n")

# Base year = 2009
base_year <- 2009

# Share = county's 2009 STEM completions / national 2009 total
national_2009 <- national_stem %>% filter(year == base_year) %>% pull(national_completions)

county_shares <- ipeds_county %>%
  filter(year == base_year) %>%
  mutate(base_share = stem_completions / national_2009) %>%
  select(county_fips, base_share, base_completions = stem_completions)

cat(sprintf("Counties with 2009 STEM completions: %d\n", nrow(county_shares)))
cat(sprintf("Share distribution: min=%.6f, median=%.6f, max=%.4f\n",
            min(county_shares$base_share), median(county_shares$base_share),
            max(county_shares$base_share)))

# Shift = national growth rate relative to 2009
national_growth <- national_stem %>%
  mutate(shift = national_completions / national_2009)

# Bartik IV: Z_ct = share_c × shift_t
bartik <- county_shares %>%
  crossing(national_growth %>% select(year, shift, national_completions)) %>%
  mutate(
    bartik_iv = base_share * shift,
    predicted_completions = base_completions * shift
  )

cat(sprintf("Bartik IV: %d obs\n", nrow(bartik)))

# ===========================================================================
# 3. Merge everything
# ===========================================================================
cat("\nMerging datasets...\n")

# Merge IPEDS completions with Bartik IV
panel <- bartik %>%
  select(county_fips, year, base_share, bartik_iv, predicted_completions) %>%
  left_join(
    ipeds_county %>% select(county_fips, year, stem_completions, n_institutions),
    by = c("county_fips", "year")
  ) %>%
  # Fill in zeros for years with no completions
  mutate(stem_completions = replace_na(stem_completions, 0))

# Merge with QWI Information sector
panel <- panel %>%
  inner_join(qwi_annual %>% select(-n_quarters), by = c("county_fips", "year"))

cat(sprintf("After QWI Info merge: %d obs, %d counties\n",
            nrow(panel), n_distinct(panel$county_fips)))

# Merge with Food placebo
panel <- panel %>%
  left_join(qwi_food_annual, by = c("county_fips", "year"))

# Merge with skill premium
panel <- panel %>%
  left_join(
    skill_premium %>% select(county_fips, year, ba_plus_share, skill_premium, log_skill_premium),
    by = c("county_fips", "year")
  )

# Add state FIPS for clustering
panel <- panel %>%
  mutate(state_fips = substr(county_fips, 1, 2))

# ===========================================================================
# 4. Create log outcomes and per-capita variables
# ===========================================================================
panel <- panel %>%
  mutate(
    log_emp = log(emp + 1),
    log_earn = log(earn_s),
    log_hir = log(hir_all + 1),
    log_stem = log(stem_completions + 1),
    firm_net_gain = firm_job_gain - firm_job_loss,
    firm_job_gain_rate = firm_job_gain / (emp + 1),
    firm_job_loss_rate = firm_job_loss / (emp + 1),
    # Log food outcomes for placebo
    log_emp_food = log(emp_food + 1),
    log_earn_food = log(earn_food)
  )

# ===========================================================================
# 5. Filter to balanced panel where possible
# ===========================================================================
# Keep counties with data in both early (2009-2011) and late (2019-2022) periods
counties_early <- panel %>% filter(year >= 2009, year <= 2011) %>% distinct(county_fips)
counties_late <- panel %>% filter(year >= 2019, year <= 2022) %>% distinct(county_fips)
balanced_counties <- inner_join(counties_early, counties_late, by = "county_fips")

panel_balanced <- panel %>%
  filter(county_fips %in% balanced_counties$county_fips, year >= 2009)

cat(sprintf("\nFinal balanced panel: %d obs, %d counties, years %d-%d\n",
            nrow(panel_balanced), n_distinct(panel_balanced$county_fips),
            min(panel_balanced$year), max(panel_balanced$year)))

# ===========================================================================
# 6. Summary statistics
# ===========================================================================
cat("\n=== Summary Statistics ===\n")
cat(sprintf("N counties: %d\n", n_distinct(panel_balanced$county_fips)))
cat(sprintf("N states: %d\n", n_distinct(panel_balanced$state_fips)))
cat(sprintf("Mean STEM completions: %.1f\n", mean(panel_balanced$stem_completions)))
cat(sprintf("Mean Info employment: %.1f\n", mean(panel_balanced$emp, na.rm = TRUE)))
cat(sprintf("Mean Info earnings: $%.0f\n", mean(panel_balanced$earn_s, na.rm = TRUE)))

# ===========================================================================
# 7. Save
# ===========================================================================
saveRDS(panel_balanced, "../data/panel.rds")
saveRDS(panel, "../data/panel_full.rds")
saveRDS(county_shares, "../data/county_shares.rds")

cat("\nAnalysis datasets saved.\n")
