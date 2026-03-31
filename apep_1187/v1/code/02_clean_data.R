# =============================================================================
# 02_clean_data.R — Construct analysis dataset
# Paper: apep_1187 — Sweden Pay Equity Audit RDD
# =============================================================================

source("00_packages.R")

# ============================================================================
# 1. CLEAN WAGE DATA (industry × sex × year, 2014-2022)
# ============================================================================
cat("=== Cleaning wage data ===\n")

df_wages <- readRDS("../data/wages_industry_sex.rds")

# Rename columns
names(df_wages) <- c("industry", "sex", "year", "basic_salary", "monthly_salary",
                      "female_pct_male", "private_share")

# Clean types
df_wages$year <- as.integer(df_wages$year)
df_wages$sex <- ifelse(df_wages$sex == "1", "male", "female")

# Reshape: one row per industry × year with male + female wages
wages_wide <- df_wages %>%
  select(industry, sex, year, monthly_salary, basic_salary) %>%
  pivot_wider(
    names_from = sex,
    values_from = c(monthly_salary, basic_salary),
    names_sep = "_"
  )

# Get the female % of male from the original data (sex-invariant, same for both)
wage_ratio <- df_wages %>%
  filter(sex == "male") %>%
  select(industry, year, female_pct_male, private_share)

wages_panel <- wages_wide %>%
  left_join(wage_ratio, by = c("industry", "year"))

# Compute our own gender wage gap measures
wages_panel <- wages_panel %>%
  mutate(
    gap_monthly = monthly_salary_female / monthly_salary_male * 100,
    gap_basic = basic_salary_female / basic_salary_male * 100,
    log_gap = log(monthly_salary_female) - log(monthly_salary_male),
    abs_gap = monthly_salary_male - monthly_salary_female
  )

cat("Wage panel:", nrow(wages_panel), "rows\n")
cat("Industries:", length(unique(wages_panel$industry)), "\n")
cat("Years:", paste(sort(unique(wages_panel$year)), collapse=", "), "\n")

# Add 2023-2024 data if available
df_wages2 <- readRDS("../data/wages_industry_sex_2023.rds")
if (nrow(df_wages2) > 0) {
  # The 2023+ table has different column codes but same structure
  names(df_wages2)[1:4] <- c("industry", "sex", "year",
                              "basic_salary")
  # Column mapping: 000007CQ=basic, 000007CS=monthly, 000007CR=female_pct, 000007CP=private
  df_wages2 <- df_wages2 %>%
    rename(monthly_salary = 5, female_pct_male = 6, private_share = 7) %>%
    select(industry, sex, year, basic_salary, monthly_salary, female_pct_male, private_share)

  df_wages2$year <- as.integer(df_wages2$year)
  df_wages2$sex <- ifelse(df_wages2$sex == "1", "male", "female")

  wages2_wide <- df_wages2 %>%
    select(industry, sex, year, monthly_salary, basic_salary) %>%
    pivot_wider(names_from = sex, values_from = c(monthly_salary, basic_salary),
                names_sep = "_")

  ratio2 <- df_wages2 %>%
    filter(sex == "male") %>%
    select(industry, year, female_pct_male, private_share)

  wages2_panel <- wages2_wide %>%
    left_join(ratio2, by = c("industry", "year")) %>%
    mutate(
      gap_monthly = monthly_salary_female / monthly_salary_male * 100,
      gap_basic = basic_salary_female / basic_salary_male * 100,
      log_gap = log(monthly_salary_female) - log(monthly_salary_male),
      abs_gap = monthly_salary_male - monthly_salary_female
    )

  wages_panel <- bind_rows(wages_panel, wages2_panel)
  cat("Extended panel to", max(wages_panel$year), "\n")
  cat("Total rows:", nrow(wages_panel), "\n")
}

# ============================================================================
# 2. CLEAN FIRM SIZE DATA (industry × size class × year)
# ============================================================================
cat("\n=== Cleaning firm size data ===\n")

df_firms <- readRDS("../data/firm_counts_by_size.rds")
names(df_firms) <- c("industry", "size_class", "year", "n_firms")
df_firms$year <- as.integer(df_firms$year)

# Map size classes to labels
size_labels <- c(
  "SGR0" = "0_employees",
  "SGR1" = "1_4_employees",
  "SGR2" = "5_9_employees",
  "SGR3" = "10_19_employees",
  "SGR4" = "20_49_employees",
  "SGR5" = "50_99_employees",
  "SGR6" = "100_199_employees",
  "SGR7" = "200_499_employees",
  "SGR8" = "500plus_employees"
)
df_firms$size_label <- size_labels[df_firms$size_class]
cat("Size classes found:", paste(unique(df_firms$size_class), collapse=", "), "\n")

# Focus on 1-letter industry codes that match wage data
# Wage data has: SA (all), A-S (1-letter NACE sections)
wage_industries <- unique(wages_panel$industry)
cat("Wage industries:", paste(wage_industries, collapse=", "), "\n")

firm_industries <- unique(df_firms$industry)
matching <- intersect(wage_industries, firm_industries)
cat("Matching industries:", paste(matching, collapse=", "), "\n")

# Keep only matching industries
df_firms_clean <- df_firms %>%
  filter(industry %in% matching, !is.na(n_firms))

cat("Firm data rows after filtering:", nrow(df_firms_clean), "\n")

# ============================================================================
# 3. CONSTRUCT TREATMENT INTENSITY MEASURE
#    Share of firms with 10-19 employees (newly treated by 2017 reform)
#    Measured using PRE-REFORM average (2010-2016) for exogeneity
# ============================================================================
cat("\n=== Constructing treatment intensity ===\n")

# Total firms per industry-year (excluding 0-employee "firms")
firm_totals <- df_firms_clean %>%
  filter(size_class != "SGR0") %>%  # exclude 0-employee
  group_by(industry, year) %>%
  summarise(total_firms = sum(n_firms, na.rm = TRUE), .groups = "drop")

# Firms in the 10-19 employee bin (newly treated)
firms_10_19 <- df_firms_clean %>%
  filter(size_class == "SGR3") %>%
  select(industry, year, n_firms_10_19 = n_firms)

# Firms in 1-9 employee bin (never treated under this reform)
firms_1_9 <- df_firms_clean %>%
  filter(size_class %in% c("SGR1", "SGR2")) %>%
  group_by(industry, year) %>%
  summarise(n_firms_1_9 = sum(n_firms, na.rm = TRUE), .groups = "drop")

# Firms in 20-49 employee bin (always treated — control)
firms_20_49 <- df_firms_clean %>%
  filter(size_class == "SGR4") %>%
  select(industry, year, n_firms_20_49 = n_firms)

# Merge
firm_composition <- firm_totals %>%
  left_join(firms_10_19, by = c("industry", "year")) %>%
  left_join(firms_1_9, by = c("industry", "year")) %>%
  left_join(firms_20_49, by = c("industry", "year")) %>%
  mutate(
    share_10_19 = n_firms_10_19 / total_firms,
    share_1_9 = n_firms_1_9 / total_firms,
    share_20_49 = n_firms_20_49 / total_firms,
    # Treatment intensity = share newly treated / (share newly + never treated)
    treat_intensity = n_firms_10_19 / (n_firms_10_19 + n_firms_1_9)
  )

# Pre-reform (2010-2016) average for time-invariant treatment intensity
treat_pre <- firm_composition %>%
  filter(year >= 2010, year <= 2016) %>%
  group_by(industry) %>%
  summarise(
    treat_intensity_pre = mean(treat_intensity, na.rm = TRUE),
    share_10_19_pre = mean(share_10_19, na.rm = TRUE),
    share_1_9_pre = mean(share_1_9, na.rm = TRUE),
    total_firms_pre = mean(total_firms, na.rm = TRUE),
    .groups = "drop"
  )

cat("Treatment intensity (pre-reform averages):\n")
print(treat_pre %>% arrange(desc(treat_intensity_pre)))

# ============================================================================
# 4. MERGE INTO FINAL ANALYSIS PANEL
# ============================================================================
cat("\n=== Merging analysis panel ===\n")

analysis_panel <- wages_panel %>%
  filter(industry != "SA") %>%  # Drop aggregate "all industries" row
  left_join(treat_pre, by = "industry") %>%
  left_join(
    firm_composition %>% select(industry, year, total_firms, n_firms_10_19, n_firms_1_9),
    by = c("industry", "year")
  ) %>%
  mutate(
    post = as.integer(year >= 2017),
    post_treat = post * treat_intensity_pre,
    # Standardize treatment intensity
    treat_std = (treat_intensity_pre - mean(treat_intensity_pre, na.rm = TRUE)) /
                sd(treat_intensity_pre, na.rm = TRUE),
    post_treat_std = post * treat_std
  ) %>%
  filter(!is.na(treat_intensity_pre))

cat("Analysis panel:", nrow(analysis_panel), "rows\n")
cat("Industries:", length(unique(analysis_panel$industry)), "\n")
cat("Years:", paste(sort(unique(analysis_panel$year)), collapse=", "), "\n")
cat("Treatment intensity range:", sprintf("%.3f to %.3f",
    min(analysis_panel$treat_intensity_pre, na.rm=TRUE),
    max(analysis_panel$treat_intensity_pre, na.rm=TRUE)), "\n")

# Summary stats
cat("\n=== Summary Statistics ===\n")
cat("Gender wage ratio (female/male × 100):\n")
cat(sprintf("  Mean: %.1f%%\n", mean(analysis_panel$gap_monthly, na.rm=TRUE)))
cat(sprintf("  SD:   %.1f%%\n", sd(analysis_panel$gap_monthly, na.rm=TRUE)))
cat(sprintf("  Min:  %.1f%%\n", min(analysis_panel$gap_monthly, na.rm=TRUE)))
cat(sprintf("  Max:  %.1f%%\n", max(analysis_panel$gap_monthly, na.rm=TRUE)))

cat("\nMonthly salary (male, SEK):\n")
cat(sprintf("  Mean: %s\n", format(mean(analysis_panel$monthly_salary_male, na.rm=TRUE), big.mark=",")))
cat(sprintf("  SD:   %s\n", format(sd(analysis_panel$monthly_salary_male, na.rm=TRUE), big.mark=",")))

cat("\nMonthly salary (female, SEK):\n")
cat(sprintf("  Mean: %s\n", format(mean(analysis_panel$monthly_salary_female, na.rm=TRUE), big.mark=",")))

# Save
saveRDS(analysis_panel, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")

# Also save the raw wage ratio time series for aggregate plots
agg_ratio <- readRDS("../data/wage_ratio_standardized.rds")
names(agg_ratio) <- c("year", "std_weighted", "unweighted")
agg_ratio$year <- as.integer(agg_ratio$year)
saveRDS(agg_ratio, "../data/agg_wage_ratio.rds")
cat("Saved aggregate wage ratio.\n")
