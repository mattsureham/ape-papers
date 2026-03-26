# 03_main_analysis.R — Primary specifications
# Ban the Box and the Black Employment Gap (apep_1012)

source("00_packages.R")

df <- fread("../data/analysis_long.csv")
df_wide <- fread("../data/analysis_wide.csv")

# ============================================================
# 1. TWFE Triple-Difference (main specification)
# ============================================================
m1_emp <- feols(ln_emp ~ post_btb:black + post_btb + black |
                  county_fips + time_id,
                data = df, cluster = ~state_fips)

m1_hira <- feols(ln_hira ~ post_btb:black + post_btb + black |
                   county_fips + time_id,
                 data = df, cluster = ~state_fips)

m1_hirn <- feols(ln_hirn ~ post_btb:black + post_btb + black |
                   county_fips + time_id,
                 data = df, cluster = ~state_fips)

m1_emps <- feols(ln_emps ~ post_btb:black + post_btb + black |
                   county_fips + time_id,
                 data = df, cluster = ~state_fips)

message("=== TWFE Triple-Difference Results ===")
message(sprintf("Employment:    β = %.4f (SE = %.4f, t = %.2f)", coef(m1_emp)["post_btb:black"], se(m1_emp)["post_btb:black"], tstat(m1_emp)["post_btb:black"]))
message(sprintf("All Hires:     β = %.4f (SE = %.4f, t = %.2f)", coef(m1_hira)["post_btb:black"], se(m1_hira)["post_btb:black"], tstat(m1_hira)["post_btb:black"]))
message(sprintf("New Hires:     β = %.4f (SE = %.4f, t = %.2f)", coef(m1_hirn)["post_btb:black"], se(m1_hirn)["post_btb:black"], tstat(m1_hirn)["post_btb:black"]))
message(sprintf("FQ Employment: β = %.4f (SE = %.4f, t = %.2f)", coef(m1_emps)["post_btb:black"], se(m1_emps)["post_btb:black"], tstat(m1_emps)["post_btb:black"]))

# ============================================================
# 2. Sun-Abraham event study at state level (treatment level)
# ============================================================
# Treatment varies at state level, so aggregate to state×race×quarter
# This is more appropriate for SA and avoids memory issues

state_panel <- df[, .(
  emp = sum(Emp, na.rm = TRUE),
  hira = sum(HirA, na.rm = TRUE),
  hirn = sum(HirN, na.rm = TRUE),
  emps = sum(EmpS, na.rm = TRUE),
  n_counties = uniqueN(county_fips)
), by = .(state_fips, race, time_id, year, quarter, treated_state, post_btb, cohort, btb_time_id)]

state_panel[, ln_emp := log(emp + 1)]
state_panel[, ln_hirn := log(hirn + 1)]
state_panel[, ln_emps := log(emps + 1)]
state_panel[, black := fifelse(race == "A2", 1L, 0L)]
state_panel[, sa_cohort := fifelse(treated_state, btb_time_id, 10000L)]

# SA on Black workers
message("Running Sun-Abraham on state-level Black employment...")
sa_black <- feols(ln_emp ~ sunab(sa_cohort, time_id) | state_fips + time_id,
                  data = state_panel[race == "A2"], cluster = ~state_fips)

# SA on White workers (placebo)
message("Running Sun-Abraham on state-level White employment...")
sa_white <- feols(ln_emp ~ sunab(sa_cohort, time_id) | state_fips + time_id,
                  data = state_panel[race == "A1"], cluster = ~state_fips)

# Extract event-study coefficients
extract_sa <- function(model, label) {
  ct <- as.data.table(coeftable(model), keep.rownames = "term")
  setnames(ct, c("term", "estimate", "se", "t_stat", "p_value"))
  ct[, event_time := as.integer(gsub(".*::(-?[0-9]+):.*|.*::(-?[0-9]+)", "\\1\\2", term))]
  ct <- ct[!is.na(event_time)]
  ct[, label := label]
  return(ct)
}

sa_black_dt <- extract_sa(sa_black, "Black")
sa_white_dt <- extract_sa(sa_white, "White")

# Aggregate ATTs
sa_black_agg <- summary(sa_black, agg = "ATT")
sa_white_agg <- summary(sa_white, agg = "ATT")

message("=== Sun-Abraham Aggregated ATT (state level) ===")
message(sprintf("Black Employment ATT: %.4f (SE = %.4f)", coef(sa_black_agg), se(sa_black_agg)))
message(sprintf("White Employment ATT: %.4f (SE = %.4f)", coef(sa_white_agg), se(sa_white_agg)))
message(sprintf("Implied triple-diff:  %.4f", as.numeric(coef(sa_black_agg)) - as.numeric(coef(sa_white_agg))))

# Pre-trend check
pre_black <- sa_black_dt[event_time < -1]
if (nrow(pre_black) > 0) {
  message(sprintf("Black pre-trend: %d/%d significant at 5%%",
                  sum(pre_black$p_value < 0.05), nrow(pre_black)))
}

# Save event study data
es_combined <- rbind(sa_black_dt, sa_white_dt)
fwrite(es_combined, "../data/sa_event_study.csv")

# ============================================================
# 3. SA for hiring flows (mechanism)
# ============================================================
sa_hirn_black <- feols(ln_hirn ~ sunab(sa_cohort, time_id) | state_fips + time_id,
                       data = state_panel[race == "A2"], cluster = ~state_fips)
sa_hirn_agg <- summary(sa_hirn_black, agg = "ATT")
message(sprintf("Black New Hires ATT:  %.4f (SE = %.4f)", coef(sa_hirn_agg), se(sa_hirn_agg)))

sa_emps_black <- feols(ln_emps ~ sunab(sa_cohort, time_id) | state_fips + time_id,
                       data = state_panel[race == "A2"], cluster = ~state_fips)
sa_emps_agg <- summary(sa_emps_black, agg = "ATT")
message(sprintf("Black FQ Emp ATT:     %.4f (SE = %.4f)", coef(sa_emps_agg), se(sa_emps_agg)))

# ============================================================
# 4. TWFE Event Study (county level, for pre-trends)
# ============================================================
# Bin event times at -12 and +12
df_wide[, et_bin := fifelse(!is.na(event_time) & event_time < -12, -12L,
                     fifelse(!is.na(event_time) & event_time > 12, 12L, event_time))]

m_event <- feols(bw_emp_ratio ~ i(et_bin, ref = -1) | county_fips + time_id,
                 data = df_wide[treated_state == TRUE & !is.na(event_time)],
                 cluster = ~state_fips)

es_coefs <- as.data.table(coeftable(m_event), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "t_stat", "p_value"))
es_coefs[, event_time := as.integer(gsub(".*::(-?[0-9]+).*", "\\1", term))]
fwrite(es_coefs[!is.na(event_time)], "../data/twfe_event_study.csv")

pre_coefs <- es_coefs[event_time < -1 & !is.na(event_time)]
message(sprintf("TWFE event study pre-trend: %d/%d significant at 5%%",
                sum(pre_coefs$p_value < 0.05), nrow(pre_coefs)))

# ============================================================
# 5. Save results
# ============================================================
results <- list(
  twfe = list(
    emp = summary(m1_emp),
    hira = summary(m1_hira),
    hirn = summary(m1_hirn),
    emps = summary(m1_emps)
  ),
  sa_att = list(
    black_emp = list(att = as.numeric(coef(sa_black_agg)), se = as.numeric(se(sa_black_agg))),
    white_emp = list(att = as.numeric(coef(sa_white_agg)), se = as.numeric(se(sa_white_agg))),
    black_hirn = list(att = as.numeric(coef(sa_hirn_agg)), se = as.numeric(se(sa_hirn_agg))),
    black_emps = list(att = as.numeric(coef(sa_emps_agg)), se = as.numeric(se(sa_emps_agg)))
  ),
  sa_event = es_combined
)

saveRDS(results, "../data/main_results.rds")

# ============================================================
# 6. Diagnostics for validation
# ============================================================
n_treated_counties <- uniqueN(df[treated_state == TRUE]$county_fips)
n_pre <- uniqueN(df[time_id < min(df[treated_state == TRUE]$btb_time_id, na.rm = TRUE)]$time_id)
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = n_obs
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
message(sprintf("Diagnostics: %d treated counties, %d pre-periods, %s total obs",
                n_treated_counties, n_pre, format(n_obs, big.mark = ",")))

message("Main analysis complete.")
