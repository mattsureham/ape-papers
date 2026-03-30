## 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
## apep_1156: Mexico AVGM and Domestic Violence Reporting

source("00_packages.R")

# -------------------------------------------------------------------
# 1. Load DV panel
# -------------------------------------------------------------------
dv <- fread("../data/dv_panel.csv")
cat(sprintf("DV panel: %d rows, %d municipalities, %d periods\n",
            nrow(dv), uniqueN(dv$mun_id), uniqueN(dv$t)))

# -------------------------------------------------------------------
# 2. Aggregate to state-month level for CS-DiD
# -------------------------------------------------------------------
# Municipality-level with 2486 units × 132 periods is feasible for
# att_gt, but state-month gives cleaner clusters and faster estimation.
# We run municipality-level as robustness.

state_panel <- dv[, .(
  y_raw = sum(y_raw),
  n_munis = uniqueN(mun_id)
), by = .(state_code, state_name, t, g)]

# asinh of state total
state_panel[, y := asinh(y_raw)]

cat(sprintf("State-month panel: %d rows, %d states, %d periods\n",
            nrow(state_panel), uniqueN(state_panel$state_code),
            uniqueN(state_panel$t)))

# -------------------------------------------------------------------
# 3. CS-DiD: Primary specification (DV, state-month)
# -------------------------------------------------------------------
cat("\n=== Callaway-Sant'Anna: Domestic Violence (state-month) ===\n")

cs_dv <- att_gt(
  yname = "y",
  tname = "t",
  idname = "state_code",
  gname = "g",
  data = as.data.frame(state_panel),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

cat("Group-time ATTs computed.\n")

# Aggregate: simple ATT
agg_simple <- aggte(cs_dv, type = "simple")
cat(sprintf("\nSimple ATT: %.4f (SE: %.4f)\n",
            agg_simple$overall.att, agg_simple$overall.se))

# Aggregate: dynamic (event study)
agg_dynamic <- aggte(cs_dv, type = "dynamic", min_e = -24, max_e = 60)
cat("Dynamic aggregation computed.\n")

# Save CS results
saveRDS(cs_dv, "../data/cs_dv_state.rds")
saveRDS(agg_simple, "../data/cs_dv_simple.rds")
saveRDS(agg_dynamic, "../data/cs_dv_dynamic.rds")

# -------------------------------------------------------------------
# 4. TWFE comparison (for reference, not primary)
# -------------------------------------------------------------------
cat("\n=== TWFE comparison ===\n")
twfe_dv <- feols(y ~ treated_post | state_code + t,
                 data = dv[, .(y = asinh(sum(y_raw)),
                               treated_post = max(treated_post)),
                           by = .(state_code, t)],
                 cluster = ~state_code)
cat("TWFE estimate:\n")
print(summary(twfe_dv)$coefficients)

# -------------------------------------------------------------------
# 5. Feminicide outcome (secondary)
# -------------------------------------------------------------------
cat("\n=== CS-DiD: Feminicide (state-month) ===\n")
fem <- fread("../data/fem_panel.csv")
fem_state <- fem[, .(y_raw = sum(y_raw)), by = .(state_code, t, g)]
fem_state[, y := asinh(y_raw)]

cs_fem <- att_gt(
  yname = "y",
  tname = "t",
  idname = "state_code",
  gname = "g",
  data = as.data.frame(fem_state),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

agg_fem_simple <- aggte(cs_fem, type = "simple")
cat(sprintf("Feminicide ATT: %.4f (SE: %.4f)\n",
            agg_fem_simple$overall.att, agg_fem_simple$overall.se))

agg_fem_dynamic <- aggte(cs_fem, type = "dynamic", min_e = -24, max_e = 60)

saveRDS(cs_fem, "../data/cs_fem_state.rds")
saveRDS(agg_fem_simple, "../data/cs_fem_simple.rds")
saveRDS(agg_fem_dynamic, "../data/cs_fem_dynamic.rds")

# -------------------------------------------------------------------
# 6. Property crime placebo
# -------------------------------------------------------------------
cat("\n=== CS-DiD: Property crime placebo (state-month) ===\n")
prop <- fread("../data/prop_panel.csv")
prop_state <- prop[, .(y_raw = sum(y_raw)), by = .(state_code, t, g)]
prop_state[, y := asinh(y_raw)]

cs_prop <- att_gt(
  yname = "y",
  tname = "t",
  idname = "state_code",
  gname = "g",
  data = as.data.frame(prop_state),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

agg_prop_simple <- aggte(cs_prop, type = "simple")
cat(sprintf("Property crime ATT: %.4f (SE: %.4f)\n",
            agg_prop_simple$overall.att, agg_prop_simple$overall.se))

saveRDS(cs_prop, "../data/cs_prop_state.rds")
saveRDS(agg_prop_simple, "../data/cs_prop_simple.rds")

# -------------------------------------------------------------------
# 7. Sexual abuse outcome
# -------------------------------------------------------------------
cat("\n=== CS-DiD: Sexual abuse (state-month) ===\n")
abuse <- fread("../data/abuse_panel.csv")
abuse_state <- abuse[, .(y_raw = sum(y_raw)), by = .(state_code, t, g)]
abuse_state[, y := asinh(y_raw)]

cs_abuse <- att_gt(
  yname = "y",
  tname = "t",
  idname = "state_code",
  gname = "g",
  data = as.data.frame(abuse_state),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

agg_abuse_simple <- aggte(cs_abuse, type = "simple")
cat(sprintf("Sexual abuse ATT: %.4f (SE: %.4f)\n",
            agg_abuse_simple$overall.att, agg_abuse_simple$overall.se))

saveRDS(cs_abuse, "../data/cs_abuse_state.rds")
saveRDS(agg_abuse_simple, "../data/cs_abuse_simple.rds")

# -------------------------------------------------------------------
# 8. Summary table
# -------------------------------------------------------------------
cat("\n\n========== SUMMARY ==========\n")
results <- data.table(
  outcome = c("Domestic violence", "Feminicide",
              "Property crime (placebo)", "Sexual abuse"),
  att = c(agg_simple$overall.att, agg_fem_simple$overall.att,
          agg_prop_simple$overall.att, agg_abuse_simple$overall.att),
  se = c(agg_simple$overall.se, agg_fem_simple$overall.se,
         agg_prop_simple$overall.se, agg_abuse_simple$overall.se)
)
results[, t_stat := att / se]
results[, p_val := 2 * pnorm(-abs(t_stat))]
results[, sig := ifelse(p_val < 0.01, "***",
                        ifelse(p_val < 0.05, "**",
                               ifelse(p_val < 0.1, "*", "")))]
print(results)

# -------------------------------------------------------------------
# 9. Write diagnostics.json
# -------------------------------------------------------------------
diag <- list(
  n_treated = length(unique(dv$state_code[dv$g > 0])),
  n_pre = min(table(unique(dv[g > 0, .(state_code, g)])$g)),
  n_obs = nrow(state_panel),
  n_municipalities = uniqueN(dv$mun_id),
  n_states = uniqueN(dv$state_code),
  n_treated_states = uniqueN(dv$state_code[dv$g > 0]),
  n_control_states = uniqueN(dv$state_code[dv$g == 0]),
  n_periods = uniqueN(dv$t),
  dv_att = agg_simple$overall.att,
  dv_se = agg_simple$overall.se,
  fem_att = agg_fem_simple$overall.att,
  fem_se = agg_fem_simple$overall.se,
  prop_att = agg_prop_simple$overall.att,
  prop_se = agg_prop_simple$overall.se,
  pre_sd_dv_asinh = sd(dv[treated_post == 0 & (g == 0 | ym < avgm_ym),
                          asinh(sum(y_raw)),
                          by = .(state_code, t)]$V1)
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nWrote diagnostics.json\n")
