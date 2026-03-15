## 03_main_analysis.R — Main DiD analysis
## apep_0693: The Price of Privacy

source("00_packages.R")

# ------------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------------
df <- readRDS("../data/bfs_quarterly_clean.rds")

cat(sprintf("Panel: %d obs, %d states, %d quarters\n",
            nrow(df), n_distinct(df$state), n_distinct(df$yq)))

# ------------------------------------------------------------------
# 2. TWFE baseline (for comparison — will show bias if heterogeneous)
# ------------------------------------------------------------------
cat("\n=== TWFE Baseline ===\n")

twfe_ba <- feols(log_ba ~ treated | state_id + yq, data = df, cluster = ~state_id)
twfe_hba <- feols(log_hba ~ treated | state_id + yq, data = df, cluster = ~state_id)
twfe_cba <- feols(log_cba ~ treated | state_id + yq, data = df, cluster = ~state_id)

cat("TWFE log(BA):\n"); print(summary(twfe_ba))
cat("TWFE log(HBA):\n"); print(summary(twfe_hba))

# ------------------------------------------------------------------
# 3. Callaway-Sant'Anna CS-DiD (preferred estimator)
# ------------------------------------------------------------------
cat("\n=== Callaway-Sant'Anna CS-DiD ===\n")

# Main specification: total business applications
cs_ba <- att_gt(
  yname = "log_ba",
  tname = "yq",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  base_period = "universal"
)

cat("CS-DiD ATT(g,t) computed. Aggregating...\n")

# Overall ATT
agg_ba <- aggte(cs_ba, type = "simple")
cat("\n--- Overall ATT (log BA) ---\n")
print(summary(agg_ba))

# Dynamic event study
es_ba <- aggte(cs_ba, type = "dynamic", min_e = -12, max_e = 8)
cat("\n--- Event Study (log BA) ---\n")
print(summary(es_ba))

# Group-level ATT
group_ba <- aggte(cs_ba, type = "group")
cat("\n--- Group ATT (log BA) ---\n")
print(summary(group_ba))

# ------------------------------------------------------------------
# 4. CS-DiD for alternative outcomes
# ------------------------------------------------------------------
# High-propensity business applications
cs_hba <- att_gt(
  yname = "log_hba",
  tname = "yq",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_hba <- aggte(cs_hba, type = "simple")
es_hba <- aggte(cs_hba, type = "dynamic", min_e = -12, max_e = 8)

cat("\n--- Overall ATT (log HBA) ---\n")
print(summary(agg_hba))

# Corporate business applications
cs_cba <- att_gt(
  yname = "log_cba",
  tname = "yq",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_cba <- aggte(cs_cba, type = "simple")
es_cba <- aggte(cs_cba, type = "dynamic", min_e = -12, max_e = 8)

cat("\n--- Overall ATT (log CBA) ---\n")
print(summary(agg_cba))

# With planned wages
cs_wba <- att_gt(
  yname = "log_wba",
  tname = "yq",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_wba <- aggte(cs_wba, type = "simple")
es_wba <- aggte(cs_wba, type = "dynamic", min_e = -12, max_e = 8)

cat("\n--- Overall ATT (log WBA) ---\n")
print(summary(agg_wba))

# ------------------------------------------------------------------
# 5. Save results
# ------------------------------------------------------------------
results <- list(
  twfe_ba = twfe_ba,
  twfe_hba = twfe_hba,
  twfe_cba = twfe_cba,
  cs_ba = cs_ba,
  cs_hba = cs_hba,
  cs_cba = cs_cba,
  cs_wba = cs_wba,
  agg_ba = agg_ba,
  agg_hba = agg_hba,
  agg_cba = agg_cba,
  agg_wba = agg_wba,
  es_ba = es_ba,
  es_hba = es_hba,
  es_cba = es_cba,
  es_wba = es_wba,
  group_ba = group_ba
)
saveRDS(results, "../data/main_results.rds")

# ------------------------------------------------------------------
# 6. Write diagnostics for validator
# ------------------------------------------------------------------
n_treated <- n_distinct(df$state[df$first_treat_q > 0])
n_pre <- length(unique(df$yq[df$yq < min(df$first_treat_q[df$first_treat_q > 0])]))
n_obs <- nrow(df)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Main analysis complete.\n")
