## 03_main_analysis.R — Main econometric analysis
## apep_0641: Salary History Bans and Industry Pay Compression

source("00_packages.R")

cat("=== Running main analysis ===\n")

# ---- Load data ----
qwi <- arrow::read_parquet("../data/analysis_panel.parquet")
gap <- arrow::read_parquet("../data/gender_gap_panel.parquet")
ban_states <- read_csv("../data/ban_states.csv", show_col_types = FALSE)

# ---- Panel A: CS-DiD on Female New-Hire Earnings ----
cat("\n--- Panel A: CS-DiD on log new-hire earnings (women) ---\n")

# Filter to female workers, non-aggregate industry, state-level
fem_panel <- qwi %>%
  filter(female == 1, industry != "00") %>%
  # Collapse to state-quarter level (across industries)
  group_by(state_fips, year, quarter, yq, treat_quarter) %>%
  summarise(
    earn_hir = weighted.mean(earn_hir, hir_n, na.rm = TRUE),
    earn_s = weighted.mean(earn_s, emp, na.rm = TRUE),
    emp = sum(emp, na.rm = TRUE),
    hir_n = sum(hir_n, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_earn_hir = log(earn_hir),
    state_id = as.integer(factor(state_fips))
  ) %>%
  filter(is.finite(log_earn_hir))

cat("Female state-quarter panel:", nrow(fem_panel), "obs,",
    n_distinct(fem_panel$state_fips), "states\n")

# Callaway-Sant'Anna
cs_female <- att_gt(
  yname = "log_earn_hir",
  tname = "yq",
  idname = "state_id",
  gname = "treat_quarter",
  data = as.data.frame(fem_panel),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

cat("\nCS-DiD Female Earnings - Group-time ATTs:\n")
summary(cs_female)

# Event study aggregation
es_female <- aggte(cs_female, type = "dynamic", min_e = -8, max_e = 12)
cat("\nEvent Study (Female Earnings):\n")
summary(es_female)

# Overall ATT
att_female <- aggte(cs_female, type = "simple")
cat("\nOverall ATT (Female Earnings):\n")
summary(att_female)

# ---- Panel B: Triple-Difference (Female vs Male × Post × HighGap) ----
cat("\n--- Panel B: Triple Difference on new-hire earnings ---\n")

# State-industry-sex-quarter panel
ddd_panel <- qwi %>%
  filter(industry != "00") %>%
  group_by(state_fips, industry, female, year, quarter, yq,
           treat_quarter, treated_state, post, high_gap_industry) %>%
  summarise(
    earn_hir = weighted.mean(earn_hir, hir_n, na.rm = TRUE),
    earn_s = weighted.mean(earn_s, emp, na.rm = TRUE),
    emp = sum(emp, na.rm = TRUE),
    hir_n = sum(hir_n, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_earn_hir = log(earn_hir),
    log_earn = log(earn_s),
    hire_rate = hir_n / emp,
    sep_rate = sep / emp
  ) %>%
  filter(is.finite(log_earn_hir), is.finite(log_earn), emp > 0)

cat("DDD panel:", nrow(ddd_panel), "obs\n")

# Triple difference with fixest
# Y = log(earn_hir) ~ female × post × high_gap | state + industry × quarter + ...
ddd_earn <- feols(
  log_earn_hir ~ female:post + female:high_gap_industry +
    post:high_gap_industry + female:post:high_gap_industry |
    state_fips + industry^yq,
  data = ddd_panel,
  cluster = ~state_fips,
  weights = ~hir_n
)

cat("\nTriple-Difference Results (New-Hire Earnings):\n")
summary(ddd_earn)

# DDD on average earnings
ddd_avg_earn <- feols(
  log_earn ~ female:post + female:high_gap_industry +
    post:high_gap_industry + female:post:high_gap_industry |
    state_fips + industry^yq,
  data = ddd_panel,
  cluster = ~state_fips,
  weights = ~emp
)

cat("\nTriple-Difference Results (Average Earnings):\n")
summary(ddd_avg_earn)

# DDD on hiring rate
ddd_hire <- feols(
  hire_rate ~ female:post + female:high_gap_industry +
    post:high_gap_industry + female:post:high_gap_industry |
    state_fips + industry^yq,
  data = ddd_panel,
  cluster = ~state_fips,
  weights = ~emp
)

cat("\nTriple-Difference Results (Hiring Rate):\n")
summary(ddd_hire)

# DDD on separation rate
ddd_sep <- feols(
  sep_rate ~ female:post + female:high_gap_industry +
    post:high_gap_industry + female:post:high_gap_industry |
    state_fips + industry^yq,
  data = ddd_panel,
  cluster = ~state_fips,
  weights = ~emp
)

cat("\nTriple-Difference Results (Separation Rate):\n")
summary(ddd_sep)

# ---- Panel C: Gender gap DiD by industry type ----
cat("\n--- Panel C: Gender gap DiD by industry type ---\n")

# Low-gap industries
gap_low <- gap %>% filter(high_gap_industry == 0)
gap_high <- gap %>% filter(high_gap_industry == 1)

did_gap_low <- feols(
  log_ratio_hir ~ post | state_fips + industry^yq,
  data = gap_low,
  cluster = ~state_fips,
  weights = ~total_emp
)

did_gap_high <- feols(
  log_ratio_hir ~ post | state_fips + industry^yq,
  data = gap_high,
  cluster = ~state_fips,
  weights = ~total_emp
)

cat("\nGender Gap DiD — Low-gap industries:\n")
summary(did_gap_low)

cat("\nGender Gap DiD — High-gap industries:\n")
summary(did_gap_high)

# ---- Save results ----
results <- list(
  cs_female = cs_female,
  es_female = es_female,
  att_female = att_female,
  ddd_earn = ddd_earn,
  ddd_avg_earn = ddd_avg_earn,
  ddd_hire = ddd_hire,
  ddd_sep = ddd_sep,
  did_gap_low = did_gap_low,
  did_gap_high = did_gap_high
)

saveRDS(results, "../data/main_results.rds")

# ---- Write diagnostics.json ----
n_treated_states <- nrow(ban_states)
n_control_states <- n_distinct(qwi$state_fips[qwi$treated_state == 0])
n_pre <- length(unique(qwi$yq[qwi$yq < min(ban_states$treat_quarter)]))
n_obs <- nrow(ddd_panel)

diag <- list(
  n_treated = n_treated_states,
  n_control = n_control_states,
  n_pre = n_pre,
  n_obs = n_obs,
  n_industries = n_distinct(ddd_panel$industry),
  n_state_quarters = n_distinct(paste(ddd_panel$state_fips, ddd_panel$yq))
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics:", jsonlite::toJSON(diag, auto_unbox = TRUE), "\n")
