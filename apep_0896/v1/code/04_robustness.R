# 04_robustness.R — Robustness checks
# apep_0896: Does the Right to Repair Create Repairers?

source("00_packages.R")

load("../data/main_results.RData")

# ══════════════════════════════════════════════════════════
# 1. LEAVE-ONE-OUT: Drop each treated state
# ══════════════════════════════════════════════════════════

cat("=== Leave-One-Out Analysis (Establishments) ===\n")
treated_states <- unique(df$state_abbr[df$rtr_state == 1])

loo_results <- list()
for (drop_state in treated_states) {
  df_loo <- df %>% filter(state_abbr != drop_state)
  # Re-index state_id
  df_loo <- df_loo %>% mutate(state_id = as.numeric(as.factor(state_fips)))

  cs_loo <- att_gt(
    yname = "log_estabs",
    tname = "time_q",
    idname = "state_id",
    gname = "first_treat_q",
    data = df_loo,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )
  agg_loo <- aggte(cs_loo, type = "simple")
  loo_results[[drop_state]] <- data.frame(
    dropped = drop_state,
    att = agg_loo$overall.att,
    se = agg_loo$overall.se,
    p = 2 * pnorm(-abs(agg_loo$overall.att / agg_loo$overall.se))
  )
  cat(sprintf("  Drop %s: ATT=%.4f (SE=%.4f, p=%.4f)\n",
    drop_state, agg_loo$overall.att, agg_loo$overall.se,
    2 * pnorm(-abs(agg_loo$overall.att / agg_loo$overall.se))))
}

loo_df <- bind_rows(loo_results)

# ══════════════════════════════════════════════════════════
# 2. LEAVE-ONE-OUT: Wages (key result)
# ══════════════════════════════════════════════════════════

cat("\n=== Leave-One-Out Analysis (Wages) ===\n")
loo_wage_results <- list()
for (drop_state in treated_states) {
  df_loo <- df %>% filter(state_abbr != drop_state) %>%
    mutate(state_id = as.numeric(as.factor(state_fips)))

  cs_loo <- att_gt(
    yname = "log_avg_wage",
    tname = "time_q",
    idname = "state_id",
    gname = "first_treat_q",
    data = df_loo,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )
  agg_loo <- aggte(cs_loo, type = "simple")
  loo_wage_results[[drop_state]] <- data.frame(
    dropped = drop_state,
    att = agg_loo$overall.att,
    se = agg_loo$overall.se,
    p = 2 * pnorm(-abs(agg_loo$overall.att / agg_loo$overall.se))
  )
  cat(sprintf("  Drop %s: ATT=%.4f (SE=%.4f, p=%.4f)\n",
    drop_state, agg_loo$overall.att, agg_loo$overall.se,
    2 * pnorm(-abs(agg_loo$overall.att / agg_loo$overall.se))))
}

loo_wage_df <- bind_rows(loo_wage_results)

# ══════════════════════════════════════════════════════════
# 3. COHORT-SPECIFIC ATTs
# ══════════════════════════════════════════════════════════

cat("\n=== Cohort-Specific ATTs ===\n")
agg_estabs_group <- aggte(cs_estabs, type = "group")
cat("Establishments by cohort:\n")
print(data.frame(
  group = agg_estabs_group$egt,
  att = round(agg_estabs_group$att.egt, 4),
  se = round(agg_estabs_group$se.egt, 4)
))

agg_emp_group <- aggte(cs_emp, type = "group")
cat("\nEmployment by cohort:\n")
print(data.frame(
  group = agg_emp_group$egt,
  att = round(agg_emp_group$att.egt, 4),
  se = round(agg_emp_group$se.egt, 4)
))

agg_wage_group <- aggte(cs_wage, type = "group")
cat("\nWages by cohort:\n")
print(data.frame(
  group = agg_wage_group$egt,
  att = round(agg_wage_group$att.egt, 4),
  se = round(agg_wage_group$se.egt, 4)
))

# ══════════════════════════════════════════════════════════
# 4. WILD CLUSTER BOOTSTRAP (few treated clusters concern)
# ══════════════════════════════════════════════════════════

cat("\n=== Wild Cluster Bootstrap (TWFE) ===\n")
# With only 5 treated states, cluster-robust SEs may be unreliable
# Use wild cluster bootstrap for inference
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  wcb_estabs <- boottest(twfe_estabs, param = "treated",
    B = 9999, clustid = "state_id", type = "rademacher")
  cat(sprintf("WCB p-value (estabs): %.4f [CI: %.4f, %.4f]\n",
    wcb_estabs$p_val, wcb_estabs$conf_int[1], wcb_estabs$conf_int[2]))

  wcb_emp <- boottest(twfe_emp, param = "treated",
    B = 9999, clustid = "state_id", type = "rademacher")
  cat(sprintf("WCB p-value (emp): %.4f [CI: %.4f, %.4f]\n",
    wcb_emp$p_val, wcb_emp$conf_int[1], wcb_emp$conf_int[2]))

  wcb_wage <- boottest(twfe_wage, param = "treated",
    B = 9999, clustid = "state_id", type = "rademacher")
  cat(sprintf("WCB p-value (wage): %.4f [CI: %.4f, %.4f]\n",
    wcb_wage$p_val, wcb_wage$conf_int[1], wcb_wage$conf_int[2]))
} else {
  cat("fwildclusterboot not available, skipping WCB.\n")
}

# ══════════════════════════════════════════════════════════
# 5. LEVEL OUTCOMES (not logs)
# ══════════════════════════════════════════════════════════

cat("\n=== Level Outcomes (not logs) ===\n")
cs_estabs_level <- att_gt(
  yname = "estabs",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)
agg_estabs_level <- aggte(cs_estabs_level, type = "simple")
cat(sprintf("ATT (estabs, levels): %.2f (SE: %.2f)\n",
  agg_estabs_level$overall.att, agg_estabs_level$overall.se))

cs_emp_level <- att_gt(
  yname = "emp",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)
agg_emp_level <- aggte(cs_emp_level, type = "simple")
cat(sprintf("ATT (emp, levels): %.2f (SE: %.2f)\n",
  agg_emp_level$overall.att, agg_emp_level$overall.se))

# ══════════════════════════════════════════════════════════
# 6. HETEROGENEITY: Large vs small pre-existing repair sectors
# ══════════════════════════════════════════════════════════

cat("\n=== Heterogeneity: Pre-existing sector size ===\n")
# Calculate pre-treatment median employment share
pre_emp <- df %>%
  filter(time_q < 19) %>%  # Before any treatment
  group_by(state_fips, state_abbr) %>%
  summarise(pre_emp_8112 = mean(emp, na.rm = TRUE), .groups = "drop")

med_emp <- median(pre_emp$pre_emp_8112)
cat(sprintf("Median pre-treatment NAICS 8112 employment: %.1f\n", med_emp))

pre_emp <- pre_emp %>%
  mutate(large_sector = ifelse(pre_emp_8112 >= med_emp, 1, 0))

df_het <- df %>%
  left_join(pre_emp %>% select(state_fips, large_sector), by = "state_fips")

# Large pre-existing sector
df_large <- df_het %>% filter(large_sector == 1) %>%
  mutate(state_id = as.numeric(as.factor(state_fips)))
cs_large <- att_gt(
  yname = "log_emp",
  tname = "time_q", idname = "state_id", gname = "first_treat_q",
  data = df_large, control_group = "nevertreated",
  anticipation = 0, base_period = "universal"
)
agg_large <- aggte(cs_large, type = "simple")
cat(sprintf("Large sector ATT (emp): %.4f (SE: %.4f)\n",
  agg_large$overall.att, agg_large$overall.se))

# Small pre-existing sector
df_small <- df_het %>% filter(large_sector == 0) %>%
  mutate(state_id = as.numeric(as.factor(state_fips)))
cs_small <- att_gt(
  yname = "log_emp",
  tname = "time_q", idname = "state_id", gname = "first_treat_q",
  data = df_small, control_group = "nevertreated",
  anticipation = 0, base_period = "universal"
)
agg_small <- aggte(cs_small, type = "simple")
cat(sprintf("Small sector ATT (emp): %.4f (SE: %.4f)\n",
  agg_small$overall.att, agg_small$overall.se))

# Wage heterogeneity
cs_large_wage <- att_gt(
  yname = "log_avg_wage",
  tname = "time_q", idname = "state_id", gname = "first_treat_q",
  data = df_large, control_group = "nevertreated",
  anticipation = 0, base_period = "universal"
)
agg_large_wage <- aggte(cs_large_wage, type = "simple")
cat(sprintf("Large sector ATT (wage): %.4f (SE: %.4f)\n",
  agg_large_wage$overall.att, agg_large_wage$overall.se))

cs_small_wage <- att_gt(
  yname = "log_avg_wage",
  tname = "time_q", idname = "state_id", gname = "first_treat_q",
  data = df_small, control_group = "nevertreated",
  anticipation = 0, base_period = "universal"
)
agg_small_wage <- aggte(cs_small_wage, type = "simple")
cat(sprintf("Small sector ATT (wage): %.4f (SE: %.4f)\n",
  agg_small_wage$overall.att, agg_small_wage$overall.se))

# ══════════════════════════════════════════════════════════
# 7. SAVE ALL ROBUSTNESS RESULTS
# ══════════════════════════════════════════════════════════

save(
  loo_df, loo_wage_df,
  agg_estabs_group, agg_emp_group, agg_wage_group,
  agg_estabs_level, agg_emp_level,
  agg_large, agg_small, agg_large_wage, agg_small_wage,
  pre_emp, med_emp,
  cs_estabs_level, cs_emp_level,
  file = "../data/robustness_results.RData"
)

cat("\nRobustness results saved.\n")
