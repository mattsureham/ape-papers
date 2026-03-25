# 04_robustness.R — Robustness checks
# APEP Working Paper apep_0917

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# ============================================================
# 1. State-level aggregation (cleaner, fewer zeros)
# ============================================================
cat("=== STATE-LEVEL AGGREGATION ===\n")

state_panel <- panel[, .(
  total_es_revenue = sum(es_total_revenue, na.rm = TRUE),
  mean_es_revenue  = mean(es_total_revenue, na.rm = TRUE),
  n_agencies       = .N,
  n_positive       = sum(has_es_revenue),
  pct_positive     = mean(has_es_revenue)
), by = .(NCIC_ST, FORM_FY, reform_year, reform_type, reform_strength,
          post_reform, strong_reform, anti_circumvention)]

state_panel[, asinh_total := asinh(total_es_revenue)]
state_panel[, log_total := log(total_es_revenue + 1)]
state_panel[, asinh_mean := asinh(mean_es_revenue)]
state_panel[, state_id := as.integer(as.factor(NCIC_ST))]

cat("State-year panel:", nrow(state_panel), "obs,",
    length(unique(state_panel$NCIC_ST)), "states\n")

# TWFE on state-level aggregated data
twfe_state_total <- feols(asinh_total ~ post_reform | NCIC_ST + FORM_FY,
                           data = state_panel, cluster = "NCIC_ST")
cat("\nTWFE state-level (asinh total ES revenue):\n")
print(summary(twfe_state_total))

twfe_state_mean <- feols(asinh_mean ~ post_reform | NCIC_ST + FORM_FY,
                          data = state_panel, cluster = "NCIC_ST")
cat("TWFE state-level (asinh mean ES revenue per agency):\n")
print(summary(twfe_state_mean))

twfe_state_pct <- feols(pct_positive ~ post_reform | NCIC_ST + FORM_FY,
                         data = state_panel, cluster = "NCIC_ST")
cat("TWFE state-level (pct agencies with positive ES):\n")
print(summary(twfe_state_pct))

# ============================================================
# 2. Leave-one-state-out (TWFE, agency-level)
# ============================================================
cat("\n=== LEAVE-ONE-STATE-OUT ===\n")

states_list <- unique(panel$NCIC_ST)
loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (s in states_list) {
  fit <- feols(asinh_es_revenue ~ post_reform | agency_id + FORM_FY,
               data = panel[NCIC_ST != s], cluster = "NCIC_ST")
  loo_results <- rbind(loo_results, data.frame(
    dropped = s,
    coef = coef(fit)["post_reform"],
    se = sqrt(diag(vcov(fit)))["post_reform"]
  ))
}
cat("LOO range:", round(range(loo_results$coef), 4), "\n")
cat("LOO mean:", round(mean(loo_results$coef), 4), "\n")

# ============================================================
# 3. Alternative functional forms
# ============================================================
cat("\n=== ALTERNATIVE FUNCTIONAL FORMS ===\n")

# Log(revenue + 1)
twfe_log <- feols(log_es_revenue ~ post_reform | agency_id + FORM_FY,
                   data = panel, cluster = "NCIC_ST")
cat("TWFE log(revenue+1):\n")
print(summary(twfe_log))

# Level (revenue in $1000s)
panel[, es_revenue_1k := es_total_revenue / 1000]
twfe_level <- feols(es_revenue_1k ~ post_reform | agency_id + FORM_FY,
                     data = panel, cluster = "NCIC_ST")
cat("TWFE level ($1000s):\n")
print(summary(twfe_level))

# ============================================================
# 4. Balanced panel (agencies present all 9 years)
# ============================================================
cat("\n=== BALANCED PANEL ===\n")

agency_counts <- panel[, .N, by = agency_id]
balanced_ids <- agency_counts[N == 9, agency_id]
panel_balanced <- panel[agency_id %in% balanced_ids]
cat("Balanced panel:", nrow(panel_balanced), "obs (",
    length(balanced_ids), "agencies present all 9 FYs)\n")

twfe_balanced <- feols(asinh_es_revenue ~ post_reform | agency_id + FORM_FY,
                        data = panel_balanced, cluster = "NCIC_ST")
cat("TWFE balanced panel:\n")
print(summary(twfe_balanced))

# ============================================================
# 5. Dropping early cohorts (2014-2015, always treated in data)
# ============================================================
cat("\n=== DROP EARLY COHORTS ===\n")

panel_late <- panel[reform_year == 0 | reform_year >= 2016]
cat("Late-cohort panel:", nrow(panel_late), "obs\n")

twfe_late <- feols(asinh_es_revenue ~ post_reform | agency_id + FORM_FY,
                    data = panel_late, cluster = "NCIC_ST")
cat("TWFE late cohorts only:\n")
print(summary(twfe_late))

# CS-DiD on late cohorts only
cs_late <- att_gt(
  yname = "asinh_es_revenue",
  tname = "FORM_FY", idname = "agency_id", gname = "reform_year",
  data = as.data.frame(panel_late),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE, biters = 1000
)
agg_late <- aggte(cs_late, type = "simple")
cat("CS-DiD late cohorts ATT:\n")
print(summary(agg_late))

# ============================================================
# 6. Wild cluster bootstrap — skip (51 clusters sufficient for CRSE)
# ============================================================
cat("\n=== INFERENCE NOTE ===\n")
cat("51 state clusters — standard cluster-robust SEs valid.\n")
cat("No wild cluster bootstrap needed.\n")

# ============================================================
# Save robustness results
# ============================================================
rob_results <- list(
  twfe_state_total = twfe_state_total,
  twfe_state_mean = twfe_state_mean,
  twfe_state_pct = twfe_state_pct,
  loo_results = loo_results,
  twfe_log = twfe_log,
  twfe_level = twfe_level,
  twfe_balanced = twfe_balanced,
  twfe_late = twfe_late,
  cs_late = cs_late,
  agg_late = agg_late
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nROBUSTNESS COMPLETE\n")
