## 03_main_analysis.R — Main regressions
source("00_packages.R")

cat("=== Main analysis ===\n")

df <- read_parquet("../data/analysis_panel.parquet")
edu_df <- read_parquet("../data/edu_analysis_panel.parquet")

# ------------------------------------------------------------------
# 1. CS-DiD: Aggregate effect on new-hire earnings in licensed sectors
# ------------------------------------------------------------------
cat("\n--- Panel A: CS-DiD on licensed sectors ---\n")

lic_df <- df %>% filter(licensed == 1)

# State-quarter level for CS-DiD
lic_state <- lic_df %>%
  group_by(state_fips, year, quarter, yq, treat_yq) %>%
  summarise(
    log_earn_hir = {
      v <- !is.na(earn_hir) & !is.na(hir_n) & hir_n > 0
      if (sum(v) == 0) NA_real_ else log(weighted.mean(earn_hir[v], hir_n[v]))
    },
    hire_rate = {
      v <- !is.na(hir_n) & !is.na(emp) & emp > 0
      if (sum(v) == 0) NA_real_ else sum(hir_n[v]) / sum(emp[v])
    },
    emp = sum(emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(is.finite(log_earn_hir))

# CS-DiD for new-hire earnings
cs_earn <- att_gt(
  yname = "log_earn_hir",
  tname = "yq",
  idname = "state_fips",
  gname = "treat_yq",
  data = as.data.frame(lic_state %>% mutate(state_fips = as.numeric(state_fips))),
  control_group = "nevertreated",
  base_period = "universal"
)
cs_earn_agg <- aggte(cs_earn, type = "simple")
cat("CS-DiD licensed earnings ATT:", round(cs_earn_agg$overall.att, 4),
    "SE:", round(cs_earn_agg$overall.se, 4), "\n")

# CS-DiD for hire rate
cs_hire <- att_gt(
  yname = "hire_rate",
  tname = "yq",
  idname = "state_fips",
  gname = "treat_yq",
  data = as.data.frame(lic_state %>% mutate(state_fips = as.numeric(state_fips))),
  control_group = "nevertreated",
  base_period = "universal"
)
cs_hire_agg <- aggte(cs_hire, type = "simple")
cat("CS-DiD licensed hire rate ATT:", round(cs_hire_agg$overall.att, 4),
    "SE:", round(cs_hire_agg$overall.se, 4), "\n")

# Event study
cs_es <- aggte(cs_earn, type = "dynamic", min_e = -8, max_e = 12)

# ------------------------------------------------------------------
# 2. Triple-Difference: Licensed × Post × Treated
# ------------------------------------------------------------------
cat("\n--- Panel B: Triple-difference ---\n")

# Main DDD specification
# Y = α_s + γ_{i×t} + β₁(post × licensed) + controls + ε
# With state FE and industry×quarter FE

ddd_earn <- feols(
  log_earn_hir ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = df,
  cluster = ~state_fips,
  weights = ~hir_n
)

ddd_earn_avg <- feols(
  log_earn_s ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = df,
  cluster = ~state_fips,
  weights = ~emp
)

ddd_hire <- feols(
  hire_rate ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = df,
  cluster = ~state_fips,
  weights = ~emp
)

ddd_sep <- feols(
  sep_rate ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = df,
  cluster = ~state_fips,
  weights = ~emp
)

ddd_jc <- feols(
  jc_rate ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = df,
  cluster = ~state_fips,
  weights = ~emp
)

ddd_jd <- feols(
  jd_rate ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = df,
  cluster = ~state_fips,
  weights = ~emp
)

# Print DDD results
cat("\nDDD Results (post:licensed interaction):\n")
cat("New-hire earnings:", round(coef(ddd_earn)["post:licensed"], 4),
    "SE:", round(se(ddd_earn)["post:licensed"], 4), "\n")
cat("Avg earnings:", round(coef(ddd_earn_avg)["post:licensed"], 4),
    "SE:", round(se(ddd_earn_avg)["post:licensed"], 4), "\n")
cat("Hire rate:", round(coef(ddd_hire)["post:licensed"], 4),
    "SE:", round(se(ddd_hire)["post:licensed"], 4), "\n")
cat("Separation rate:", round(coef(ddd_sep)["post:licensed"], 4),
    "SE:", round(se(ddd_sep)["post:licensed"], 4), "\n")
cat("Job creation:", round(coef(ddd_jc)["post:licensed"], 4),
    "SE:", round(se(ddd_jc)["post:licensed"], 4), "\n")
cat("Job destruction:", round(coef(ddd_jd)["post:licensed"], 4),
    "SE:", round(se(ddd_jd)["post:licensed"], 4), "\n")

# ------------------------------------------------------------------
# 3. Save results
# ------------------------------------------------------------------
save(cs_earn_agg, cs_hire_agg, cs_es,
     ddd_earn, ddd_earn_avg, ddd_hire, ddd_sep, ddd_jc, ddd_jd,
     file = "../data/main_results.RData")

# Write diagnostics.json
n_treated <- length(unique(df$state_fips[df$treated == 1]))
n_pre <- length(unique(df$yq[df$yq < min(df$treat_yq[df$treat_yq > 0])]))
jsonlite::write_json(list(
  n_treated = n_treated * length(unique(df$industry)),  # state × industry cells
  n_pre = n_pre,
  n_obs = nrow(df)
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Treated states:", n_treated, "\n")
cat("Panel obs:", nrow(df), "\n")
