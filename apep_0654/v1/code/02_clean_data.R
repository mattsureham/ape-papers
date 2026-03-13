## 02_clean_data.R — Construct analysis variables
source("00_packages.R")

cat("=== Cleaning data ===\n")

# Load data
state_panel <- read_parquet("../data/state_panel.parquet")
edu_panel <- read_parquet("../data/edu_panel.parquet")
ulr <- read_csv("../data/ulr_treatment_timing.csv", show_col_types = FALSE)

# ------------------------------------------------------------------
# 1. Industry classification: licensed vs. unlicensed
# ------------------------------------------------------------------
# Licensed sectors: healthcare (62), professional services (54),
# construction (23), education (61)
# Placebo/unlicensed sectors: retail (44-45), accommodation/food (72),
# information (51), wholesale (42), transportation (48-49), admin (56)

licensed_industries <- c("62", "54", "23", "61")
placebo_industries <- c("44-45", "72", "51", "42", "48-49", "56")

state_panel <- state_panel %>%
  filter(industry %in% c(licensed_industries, placebo_industries)) %>%
  mutate(
    licensed = ifelse(industry %in% licensed_industries, 1L, 0L),
    yq = year * 4 + quarter
  )

edu_panel <- edu_panel %>%
  filter(industry %in% c(licensed_industries, placebo_industries)) %>%
  mutate(
    licensed = ifelse(industry %in% licensed_industries, 1L, 0L),
    yq = year * 4 + quarter
  )

cat("Industries included:", length(unique(state_panel$industry)), "\n")
cat("Licensed:", paste(licensed_industries, collapse = ", "), "\n")
cat("Unlicensed:", paste(placebo_industries, collapse = ", "), "\n")

# ------------------------------------------------------------------
# 2. Merge treatment timing
# ------------------------------------------------------------------
# Never-treated states get treat_yq = 0 for CS-DiD
state_panel <- state_panel %>%
  left_join(ulr %>% select(state_fips, treat_yq), by = "state_fips") %>%
  mutate(
    treat_yq = replace_na(treat_yq, 0L),
    treated = ifelse(treat_yq > 0, 1L, 0L),
    post = ifelse(treat_yq > 0 & yq >= treat_yq, 1L, 0L)
  )

edu_panel <- edu_panel %>%
  left_join(ulr %>% select(state_fips, treat_yq), by = "state_fips") %>%
  mutate(
    treat_yq = replace_na(treat_yq, 0L),
    treated = ifelse(treat_yq > 0, 1L, 0L),
    post = ifelse(treat_yq > 0 & yq >= treat_yq, 1L, 0L)
  )

# ------------------------------------------------------------------
# 3. Construct outcome variables
# ------------------------------------------------------------------
state_panel <- state_panel %>%
  mutate(
    log_earn_hir = log(earn_hir),
    log_earn_s = log(earn_s),
    hire_rate = hir_n / emp,
    sep_rate = sep / emp,
    jc_rate = frm_jb_gn / emp,   # job creation rate
    jd_rate = frm_jb_ls / emp,   # job destruction rate
    net_jc_rate = (frm_jb_gn - frm_jb_ls) / emp,  # net job creation
    turn_rate = turnover / emp
  ) %>%
  filter(
    is.finite(log_earn_hir),
    is.finite(hire_rate),
    emp > 0
  )

edu_panel <- edu_panel %>%
  mutate(
    log_earn_hir = log(earn_hir),
    hire_rate = hir_n / emp,
    sep_rate = sep / emp,
    jc_rate = frm_jb_gn / emp,
    jd_rate = frm_jb_ls / emp
  ) %>%
  filter(
    is.finite(log_earn_hir),
    emp > 0
  )

# ------------------------------------------------------------------
# 4. Summary statistics
# ------------------------------------------------------------------
cat("\n=== Panel summary ===\n")
cat("State-industry-quarter obs:", nrow(state_panel), "\n")
cat("States:", length(unique(state_panel$state_fips)), "\n")
cat("Treated states:", sum(state_panel$treated[!duplicated(state_panel$state_fips)]), "\n")
cat("Never-treated:", sum(!state_panel$treated[!duplicated(state_panel$state_fips)]), "\n")
cat("Quarters:", length(unique(state_panel$yq)), "\n")
cat("Industries:", length(unique(state_panel$industry)), "\n")

# Summary by treatment status and sector type
summ <- state_panel %>%
  group_by(treated, licensed) %>%
  summarise(
    n = n(),
    mean_emp = mean(emp, na.rm = TRUE),
    mean_earn_hir = mean(earn_hir, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    mean_jc_rate = mean(jc_rate, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    .groups = "drop"
  )
print(summ)

# ------------------------------------------------------------------
# 5. Save analysis-ready panels
# ------------------------------------------------------------------
write_parquet(state_panel, "../data/analysis_panel.parquet")
write_parquet(edu_panel, "../data/edu_analysis_panel.parquet")

cat("\n=== Clean data saved ===\n")
cat("Analysis panel:", nrow(state_panel), "rows\n")
cat("Education panel:", nrow(edu_panel), "rows\n")
