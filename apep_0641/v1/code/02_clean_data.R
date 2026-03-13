## 02_clean_data.R — Construct analysis panel
## apep_0641: Salary History Bans and Industry Pay Compression

source("00_packages.R")

cat("=== Constructing analysis panel ===\n")

# ---- Load data ----
qwi <- arrow::read_parquet("../data/qwi_state_panel.parquet")
ban_states <- read_csv("../data/ban_states.csv", show_col_types = FALSE)

cat("QWI rows:", nrow(qwi), "\n")
cat("Treated states:", nrow(ban_states), "\n")

# ---- Create time variable (continuous quarter) ----
qwi <- qwi %>%
  mutate(
    yq = year * 4 + quarter,
    sex_label = ifelse(sex == "2", "Female", "Male"),
    female = as.integer(sex == "2")
  )

# ---- Merge treatment timing ----
qwi <- qwi %>%
  left_join(ban_states %>% select(state_fips, ban_year, treat_quarter, state_abbr),
            by = "state_fips")

# Never-treated states: set treat_quarter = 0 for CS-DiD
qwi <- qwi %>%
  mutate(
    treated_state = as.integer(!is.na(treat_quarter)),
    treat_quarter = ifelse(is.na(treat_quarter), 0L, treat_quarter),
    post = as.integer(yq >= treat_quarter & treat_quarter > 0)
  )

cat("Treated state obs:", sum(qwi$treated_state == 1), "\n")
cat("Control state obs:", sum(qwi$treated_state == 0), "\n")

# ---- Define industry gender-gap classification ----
# Pre-ban period: 2013-2016
pre_gap <- qwi %>%
  filter(year >= 2013, year <= 2016, industry != "00") %>%
  group_by(industry, sex_label) %>%
  summarise(
    mean_earn = weighted.mean(earn_s, emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = sex_label, values_from = mean_earn) %>%
  mutate(
    gender_gap_pct = (Male - Female) / Male * 100
  ) %>%
  arrange(desc(gender_gap_pct))

cat("\n=== Pre-ban gender earnings gaps by industry ===\n")
print(pre_gap, n = 25)

# High-gap industries: those with pre-ban gap > 20%
high_gap_industries <- pre_gap %>%
  filter(gender_gap_pct > 20) %>%
  pull(industry)

cat("\nHigh-gap industries (>20%):", paste(high_gap_industries, collapse = ", "), "\n")

qwi <- qwi %>%
  mutate(
    high_gap_industry = as.integer(industry %in% high_gap_industries),
    industry_gap_class = ifelse(industry %in% high_gap_industries, "High-gap", "Low-gap")
  )

# ---- Compute key outcomes ----
qwi <- qwi %>%
  mutate(
    hire_rate = hir_n / emp,
    sep_rate = sep / emp,
    log_earn_hir = log(earn_hir),
    log_earn = log(earn_s)
  ) %>%
  # Drop infinite / missing
  filter(
    is.finite(log_earn_hir),
    is.finite(log_earn),
    emp > 0,
    !is.na(earn_hir),
    earn_hir > 0
  )

# ---- Create state-industry-sex-quarter panel ID ----
qwi <- qwi %>%
  mutate(
    panel_id = paste(state_fips, industry, sex, sep = "_")
  )

# ---- Compute gender earnings gap at state-industry-quarter level ----
gender_gap <- qwi %>%
  filter(industry != "00") %>%
  select(state_fips, industry, year, quarter, yq, sex_label,
         earn_hir, earn_s, emp, hir_n, treat_quarter, treated_state, post,
         high_gap_industry) %>%
  pivot_wider(
    names_from = sex_label,
    values_from = c(earn_hir, earn_s, emp, hir_n),
    names_sep = "_"
  ) %>%
  filter(!is.na(earn_hir_Female), !is.na(earn_hir_Male),
         earn_hir_Female > 0, earn_hir_Male > 0) %>%
  mutate(
    log_ratio_hir = log(earn_hir_Female) - log(earn_hir_Male),
    log_ratio_earn = log(earn_s_Female) - log(earn_s_Male),
    gap_pct = (earn_hir_Male - earn_hir_Female) / earn_hir_Male * 100,
    total_emp = emp_Female + emp_Male,
    female_share = emp_Female / total_emp
  )

cat("\nGender gap panel rows:", nrow(gender_gap), "\n")

# ---- Save analysis datasets ----
arrow::write_parquet(qwi, "../data/analysis_panel.parquet")
arrow::write_parquet(gender_gap, "../data/gender_gap_panel.parquet")
write_csv(pre_gap, "../data/pre_ban_gender_gaps.csv")

# ---- Summary statistics for the paper ----
summ <- qwi %>%
  filter(industry != "00") %>%
  group_by(sex_label) %>%
  summarise(
    n = n(),
    mean_earn_hir = mean(earn_hir, na.rm = TRUE),
    sd_earn_hir = sd(earn_hir, na.rm = TRUE),
    mean_earn = mean(earn_s, na.rm = TRUE),
    sd_earn = sd(earn_s, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Summary Statistics ===\n")
print(summ)

# Save summary stats
write_csv(summ, "../data/summary_stats.csv")

cat("\n=== Data cleaning complete ===\n")
