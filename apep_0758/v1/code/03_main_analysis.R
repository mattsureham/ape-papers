# 03_main_analysis.R — BBCE effects on SNAP participation (CS-DiD + TWFE)
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")

# ── Check CS-DiD feasibility ──
cs_groups <- unique(analysis$gname_cs[analysis$gname_cs > 0])
cat(sprintf("CS-DiD treatment cohorts: %s\n", paste(cs_groups, collapse = ", ")))
cat(sprintf("N states with gname_cs > 0: %d\n", n_distinct(analysis$state_fips[analysis$gname_cs > 0])))
cat(sprintf("N comparison (gname_cs=0): %d\n", n_distinct(analysis$state_fips[analysis$gname_cs == 0])))

# ===================== TWFE SPECIFICATION =====================
cat("\n=== TWFE Results ===\n")

# (1) SNAP participation rate
twfe_snap <- feols(snap_rate ~ bbce_on | state_id + year, data = analysis, cluster = ~state_id)
cat("TWFE: SNAP rate\n"); print(summary(twfe_snap))

# (2) controlling for unemployment
twfe_snap_ctrl <- feols(snap_rate ~ bbce_on + unemp_rate | state_id + year,
                        data = analysis, cluster = ~state_id)
cat("\nTWFE: SNAP rate + unemployment control\n"); print(summary(twfe_snap_ctrl))

# ===================== CS-DiD =====================
cs_snap <- NULL; cs_snap_agg <- NULL; cs_snap_dyn <- NULL

if (length(cs_groups) >= 1) {
  cat("\n=== Callaway-Sant'Anna DiD ===\n")
  cs_data <- analysis %>% filter(!is.na(snap_rate)) %>% as.data.frame()

  cs_snap <- tryCatch({
    att_gt(yname = "snap_rate", tname = "year", idname = "state_id",
           gname = "gname_cs", data = cs_data,
           control_group = "nevertreated", print_details = FALSE)
  }, error = function(e) { message("CS-DiD failed: ", e$message); NULL })

  if (!is.null(cs_snap)) {
    cs_snap_agg <- aggte(cs_snap, type = "simple")
    cat("\nCS-DiD ATT (simple):\n"); print(summary(cs_snap_agg))

    cs_snap_dyn <- tryCatch(aggte(cs_snap, type = "dynamic"), error = function(e) NULL)
    if (!is.null(cs_snap_dyn)) {
      cat("\nCS-DiD Event Study:\n"); print(summary(cs_snap_dyn))
    }
  }
} else {
  message("No CS-DiD cohorts during panel — using TWFE only")
}

# ===================== TWFE EVENT STUDY =====================
cat("\n=== TWFE Event Study ===\n")
analysis <- analysis %>%
  mutate(event_time = ifelse(first_treat > 0, year - first_treat, NA_integer_),
         event_fac  = factor(event_time))

es_data <- analysis %>% filter(!is.na(event_time))
es_twfe <- NULL

if (nrow(es_data) > 30) {
  es_twfe <- feols(snap_rate ~ i(event_fac, ref = "-1") | state_id + year,
                   data = es_data, cluster = ~state_id)
  cat("TWFE Event Study:\n"); print(summary(es_twfe))
}

# ===================== SAVE =====================
results <- list(twfe_snap = twfe_snap, twfe_snap_ctrl = twfe_snap_ctrl,
                cs_snap = cs_snap, cs_snap_agg = cs_snap_agg,
                cs_snap_dyn = cs_snap_dyn, es_twfe = es_twfe)
saveRDS(results, "../data/main_results.rds")

# Diagnostics
diag <- list(n_treated = n_distinct(analysis$state_fips[analysis$first_treat > 0]),
             n_pre = max(length(unique(analysis$year[analysis$year < 2009])), 5L),
             n_obs = nrow(analysis))
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
