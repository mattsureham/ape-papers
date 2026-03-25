# 03_main_analysis.R — Main Callaway-Sant'Anna DiD estimation
# apep_0896: Does the Right to Repair Create Repairers?

source("00_packages.R")

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)

# ── Focus on NAICS 8112 (Electronic Repair) ──
df <- panel %>%
  filter(naics_code == "8112") %>%
  mutate(
    state_id = as.numeric(as.factor(state_fips))
  )

cat(sprintf("Analysis sample: %d obs, %d states, %d quarters\n",
  nrow(df), n_distinct(df$state_id), n_distinct(df$time_q)))
cat(sprintf("Treated states: %d, Never-treated: %d\n",
  sum(df$rtr_state[!duplicated(df$state_id)]),
  sum(!df$rtr_state[!duplicated(df$state_id)])))

# ══════════════════════════════════════════════════════════
# 1. CALLAWAY-SANT'ANNA: ESTABLISHMENTS
# ══════════════════════════════════════════════════════════

cat("\n=== CS-DiD: Log Establishments ===\n")
cs_estabs <- att_gt(
  yname = "log_estabs",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

# Overall ATT
agg_estabs <- aggte(cs_estabs, type = "simple")
cat(sprintf("ATT (estabs): %.4f (SE: %.4f, p: %.4f)\n",
  agg_estabs$overall.att, agg_estabs$overall.se,
  2 * pnorm(-abs(agg_estabs$overall.att / agg_estabs$overall.se))))

# Event study
es_estabs <- aggte(cs_estabs, type = "dynamic", min_e = -8, max_e = 8)
cat("Event study estimates (estabs):\n")
print(data.frame(
  e = es_estabs$egt,
  att = round(es_estabs$att.egt, 4),
  se = round(es_estabs$se.egt, 4)
))

# ══════════════════════════════════════════════════════════
# 2. CALLAWAY-SANT'ANNA: EMPLOYMENT
# ══════════════════════════════════════════════════════════

cat("\n=== CS-DiD: Log Employment ===\n")
cs_emp <- att_gt(
  yname = "log_emp",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_emp <- aggte(cs_emp, type = "simple")
cat(sprintf("ATT (emp): %.4f (SE: %.4f, p: %.4f)\n",
  agg_emp$overall.att, agg_emp$overall.se,
  2 * pnorm(-abs(agg_emp$overall.att / agg_emp$overall.se))))

es_emp <- aggte(cs_emp, type = "dynamic", min_e = -8, max_e = 8)
cat("Event study estimates (emp):\n")
print(data.frame(
  e = es_emp$egt,
  att = round(es_emp$att.egt, 4),
  se = round(es_emp$se.egt, 4)
))

# ══════════════════════════════════════════════════════════
# 3. CALLAWAY-SANT'ANNA: WAGES
# ══════════════════════════════════════════════════════════

cat("\n=== CS-DiD: Log Average Weekly Wage ===\n")
cs_wage <- att_gt(
  yname = "log_avg_wage",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_wage <- aggte(cs_wage, type = "simple")
cat(sprintf("ATT (wage): %.4f (SE: %.4f, p: %.4f)\n",
  agg_wage$overall.att, agg_wage$overall.se,
  2 * pnorm(-abs(agg_wage$overall.att / agg_wage$overall.se))))

es_wage <- aggte(cs_wage, type = "dynamic", min_e = -8, max_e = 8)

# ══════════════════════════════════════════════════════════
# 4. PLACEBO: NAICS 8111 (Automotive Repair)
# ══════════════════════════════════════════════════════════

cat("\n=== PLACEBO: NAICS 8111 (Automotive Repair) ===\n")
df_placebo <- panel %>%
  filter(naics_code == "8111") %>%
  mutate(state_id = as.numeric(as.factor(state_fips)))

cs_placebo_estabs <- att_gt(
  yname = "log_estabs",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df_placebo,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_placebo_estabs <- aggte(cs_placebo_estabs, type = "simple")
cat(sprintf("Placebo ATT (auto repair estabs): %.4f (SE: %.4f, p: %.4f)\n",
  agg_placebo_estabs$overall.att, agg_placebo_estabs$overall.se,
  2 * pnorm(-abs(agg_placebo_estabs$overall.att / agg_placebo_estabs$overall.se))))

cs_placebo_emp <- att_gt(
  yname = "log_emp",
  tname = "time_q",
  idname = "state_id",
  gname = "first_treat_q",
  data = df_placebo,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_placebo_emp <- aggte(cs_placebo_emp, type = "simple")
cat(sprintf("Placebo ATT (auto repair emp): %.4f (SE: %.4f, p: %.4f)\n",
  agg_placebo_emp$overall.att, agg_placebo_emp$overall.se,
  2 * pnorm(-abs(agg_placebo_emp$overall.att / agg_placebo_emp$overall.se))))

# ══════════════════════════════════════════════════════════
# 5. TWFE (for comparison / Bacon decomposition context)
# ══════════════════════════════════════════════════════════

cat("\n=== TWFE Comparison ===\n")
twfe_estabs <- feols(log_estabs ~ treated | state_id + time_q, data = df, cluster = ~state_id)
twfe_emp <- feols(log_emp ~ treated | state_id + time_q, data = df, cluster = ~state_id)
twfe_wage <- feols(log_avg_wage ~ treated | state_id + time_q, data = df, cluster = ~state_id)

cat("TWFE estimates:\n")
cat(sprintf("  Estabs: %.4f (SE: %.4f)\n", coef(twfe_estabs), se(twfe_estabs)))
cat(sprintf("  Emp:    %.4f (SE: %.4f)\n", coef(twfe_emp), se(twfe_emp)))
cat(sprintf("  Wage:   %.4f (SE: %.4f)\n", coef(twfe_wage), se(twfe_wage)))

# ══════════════════════════════════════════════════════════
# 6. Sun-Abraham (alternative robust estimator)
# ══════════════════════════════════════════════════════════

cat("\n=== Sun-Abraham (fixest::sunab) ===\n")
df <- df %>%
  mutate(
    cohort = ifelse(first_treat_q == 0, 10000, first_treat_q)
  )

sa_estabs <- feols(log_estabs ~ sunab(cohort, time_q) | state_id + time_q,
  data = df, cluster = ~state_id)
sa_emp <- feols(log_emp ~ sunab(cohort, time_q) | state_id + time_q,
  data = df, cluster = ~state_id)

# Extract SA ATT -- print all coefficients, look for ATT-like summary
cat("Sun-Abraham estabs coefficients:\n")
print(summary(sa_estabs, agg = "ATT"))
cat("\nSun-Abraham emp coefficients:\n")
print(summary(sa_emp, agg = "ATT"))

# ══════════════════════════════════════════════════════════
# 7. SAVE RESULTS
# ══════════════════════════════════════════════════════════

# Save model objects
save(
  cs_estabs, cs_emp, cs_wage,
  agg_estabs, agg_emp, agg_wage,
  es_estabs, es_emp, es_wage,
  cs_placebo_estabs, cs_placebo_emp,
  agg_placebo_estabs, agg_placebo_emp,
  twfe_estabs, twfe_emp, twfe_wage,
  sa_estabs, sa_emp,
  df, df_placebo,
  file = "../data/main_results.RData"
)

# ── Write diagnostics.json ──
# Count treated state-quarter cells (the unit of analysis for the estimator)
n_treated_cells <- nrow(df %>% filter(treated == 1))
diag <- list(
  n_treated = n_treated_cells,
  n_treated_states = n_distinct(df$state_id[df$rtr_state == 1]),
  n_pre = max(df$time_q[df$time_q < min(df$first_treat_q[df$first_treat_q > 0])]),
  n_obs = nrow(df),
  n_states = n_distinct(df$state_id),
  n_quarters = n_distinct(df$time_q),
  att_estabs = agg_estabs$overall.att,
  se_estabs = agg_estabs$overall.se,
  att_emp = agg_emp$overall.att,
  se_emp = agg_emp$overall.se,
  att_wage = agg_wage$overall.att,
  se_wage = agg_wage$overall.se
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nResults saved to data/main_results.RData and data/diagnostics.json\n")
