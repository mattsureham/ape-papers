## 02_clean_data.R — Construct analysis panels from extracted CSV data
## APEP Paper apep_0927: Japan Equal Pay Act

source("code/00_packages.R")

cat("=== Loading and cleaning data ===\n")

# --- Load firm-size panel ---
fs <- read_csv("data/panel_firmsize.csv", show_col_types = FALSE) %>%
  mutate(
    # Treatment timing: large firms April 2020, medium+small April 2021
    # Since data is annual, we use year 2020 as first treated year for large
    first_treat = case_when(
      firm_size == "large"  ~ 2020L,
      firm_size == "medium" ~ 2021L,
      firm_size == "small"  ~ 2021L,
    ),
    # Post-treatment indicator
    post = as.integer(year >= first_treat),
    # Panel ID (firm_size × sex)
    panel_id = paste(firm_size, sex, sep = "_"),
    # Compute wage gap as ratio if not already provided
    computed_gap = nonregular_wage / regular_wage * 100,
    # Use reported gap, fall back to computed
    gap = coalesce(wage_gap, computed_gap)
  )

# Verify data integrity
stopifnot("No missing regular wages" = sum(is.na(fs$regular_wage)) == 0)
stopifnot("No missing nonregular wages" = sum(is.na(fs$nonregular_wage)) == 0)
stopifnot("All years present" = length(unique(fs$year)) == 11)
stopifnot("All firm sizes present" = all(c("large","medium","small") %in% fs$firm_size))
stopifnot("All sex groups present" = all(c("total","male","female") %in% fs$sex))

cat(sprintf("Firm-size panel: %d obs, %d years, %d panels\n",
            nrow(fs), n_distinct(fs$year), n_distinct(fs$panel_id)))

# --- Load industry panel ---
ind <- read_csv("data/panel_industry.csv", show_col_types = FALSE) %>%
  mutate(
    # All industries treated in both waves (reform is universal)
    # Treatment intensity = pre-reform non-regular employment share
    # We'll compute this below
    panel_id = paste(industry, sex, sep = "_"),
    computed_gap = nonregular_wage / regular_wage * 100,
    gap = coalesce(wage_gap, computed_gap),
    # Post-reform indicator (all firms: use 2021 as "full treatment" year)
    post_full = as.integer(year >= 2021),
    # Partial treatment (large firms only): 2020
    post_partial = as.integer(year >= 2020)
  )

# Count industries per year
ind_counts <- ind %>% filter(sex == "total") %>% count(year)
cat("\nIndustry counts by year:\n")
print(ind_counts)

# Balanced panel: keep only industries present in ALL years
balanced_ind <- ind %>%
  filter(sex == "total") %>%
  group_by(industry) %>%
  filter(n() == 11) %>%
  pull(industry) %>%
  unique()

cat(sprintf("\nIndustries present in all 11 years: %d\n", length(balanced_ind)))
cat("Industries:", paste(balanced_ind, collapse = ", "), "\n")

ind_balanced <- ind %>% filter(industry %in% balanced_ind)
cat(sprintf("Balanced industry panel: %d obs\n", nrow(ind_balanced)))

# --- Compute treatment intensity for industry panel ---
# Pre-reform mean gap (2014-2019) as intensity measure
# Lower gap ratio = larger treatment intensity (more scope for reform to narrow gap)
pre_reform_gap <- ind_balanced %>%
  filter(year <= 2019, sex == "total") %>%
  group_by(industry) %>%
  summarize(
    pre_gap = mean(gap, na.rm = TRUE),
    pre_nonreg_wage = mean(nonregular_wage, na.rm = TRUE),
    pre_reg_wage = mean(regular_wage, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    # Treatment intensity: industries with LOWER gap (more inequality) are more treated
    treatment_intensity = 100 - pre_gap,
    # Standardize for regression
    treatment_z = (treatment_intensity - mean(treatment_intensity)) / sd(treatment_intensity)
  )

cat("\nPre-reform wage gap by industry (total):\n")
print(pre_reform_gap %>% arrange(pre_gap) %>% select(industry, pre_gap, treatment_intensity))

ind_balanced <- ind_balanced %>%
  left_join(pre_reform_gap %>% select(industry, treatment_intensity, treatment_z),
            by = "industry")

# --- Save cleaned data ---
write_csv(fs, "data/clean_firmsize.csv")
write_csv(ind_balanced, "data/clean_industry.csv")

cat("\n=== Data summary ===\n")
cat("Firm-size panel (primary):\n")
cat(sprintf("  Obs: %d | Panels: %d | Years: %d-%d\n",
            nrow(fs), n_distinct(fs$panel_id), min(fs$year), max(fs$year)))
cat(sprintf("  Pre-periods: %d (2014-2019)\n", sum(unique(fs$year) < 2020)))
cat(sprintf("  Treatment groups: large (2020), medium+small (2021)\n"))

cat("\nIndustry panel (supplementary):\n")
cat(sprintf("  Obs: %d | Industries: %d | Years: %d-%d\n",
            nrow(ind_balanced), n_distinct(ind_balanced$industry),
            min(ind_balanced$year), max(ind_balanced$year)))

# Summary statistics table
cat("\n=== Summary Statistics ===\n")
fs %>%
  filter(sex == "total") %>%
  group_by(firm_size) %>%
  summarize(
    n = n(),
    mean_reg = mean(regular_wage),
    mean_nonreg = mean(nonregular_wage),
    mean_gap = mean(gap, na.rm = TRUE),
    sd_gap = sd(gap, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()
