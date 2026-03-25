# 04_robustness.R — Robustness checks and placebos
# PCC Electoral Cycles and Crime Investigation Quality (apep_0909)

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load data
# ============================================================================
force_quarter <- readRDS(file.path(data_dir, "force_quarter.rds"))
panel_wide <- readRDS(file.path(data_dir, "panel_wide.rds"))
force_quarter[force_name == "London, City of", pcc := 0L]
panel_wide[force_name == "London, City of", pcc := 0L]

# Rebuild stacked dataset
election_yqs <- c(2012.75, 2016.25, 2021.25, 2024.25)

stacked_list <- list()
for (idx in 2:4) {
  e_yq <- election_yqs[idx]
  dt_e <- force_quarter[round((yq - e_yq) * 4) >= -8 & round((yq - e_yq) * 4) <= 7]
  dt_e <- copy(dt_e)
  dt_e[, cohort := idx]
  dt_e[, event_time := round((yq - e_yq) * 4)]
  dt_e[, cohort_force := paste0(force_name, "_c", idx)]
  dt_e[, cohort_yq := paste0(yq, "_c", idx)]
  dt_e[, pre_elect := fifelse(event_time >= -4 & event_time <= -1, 1L, 0L)]
  dt_e[, post_elect := fifelse(event_time >= 0 & event_time <= 3, 1L, 0L)]
  dt_e[, pcc_pre := pcc * pre_elect]
  dt_e[, pcc_post := pcc * post_elect]
  stacked_list[[idx]] <- dt_e
}
stacked <- rbindlist(stacked_list)

# ============================================================================
# 2. Wild cluster bootstrap (small number of clusters)
# ============================================================================
cat("=== Wild Cluster Bootstrap ===\n")

# Main specification with WCB inference
main_charge <- feols(
  charged_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)

tryCatch({
  boot_pre <- fwildclusterboot::boottest(
    main_charge, param = "pcc_pre",
    clustid = stacked$force_name,
    B = 9999, type = "webb", seed = 42
  )
  cat("WCB — pcc_pre (charge rate):\n")
  print(summary(boot_pre))

  boot_post <- fwildclusterboot::boottest(
    main_charge, param = "pcc_post",
    clustid = stacked$force_name,
    B = 9999, type = "webb", seed = 42
  )
  cat("\nWCB — pcc_post (charge rate):\n")
  print(summary(boot_post))
}, error = function(e) cat(sprintf("WCB error: %s\n", e$message)))

# Same for no-suspect rate
main_nosuspect <- feols(
  no_suspect_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)

tryCatch({
  boot_pre_ns <- fwildclusterboot::boottest(
    main_nosuspect, param = "pcc_pre",
    clustid = stacked$force_name,
    B = 9999, type = "webb", seed = 42
  )
  cat("\nWCB — pcc_pre (no suspect rate):\n")
  print(summary(boot_pre_ns))
}, error = function(e) cat(sprintf("WCB error: %s\n", e$message)))

# ============================================================================
# 3. Drug offence placebo
# ============================================================================
cat("\n=== Drug Offence Placebo ===\n")

# Drug offences have LOW discretion in charge decisions (possession = charge)
# If electoral cycles affect charge rates, drugs should NOT show the effect

# Build offence-level panel for drug vs other offences
panel_wide[force_name == "London, City of", pcc := 0L]

# Aggregate to force × offence group × quarter
# Focus on drugs vs all other offence groups
drug_panel <- panel_wide[offence_group == "Drug offences"]
other_panel <- panel_wide[offence_group != "Drug offences",
  .(charged = sum(charged, na.rm = TRUE),
    no_suspect = sum(no_suspect, na.rm = TRUE),
    total_outcomes = sum(total_outcomes, na.rm = TRUE)),
  by = .(force_name, cal_year, cal_quarter, yq, pcc)
]

drug_panel[, charged_rate := fifelse(total_outcomes > 0,
                                      charged / total_outcomes, NA_real_)]
other_panel[, charged_rate := fifelse(total_outcomes > 0,
                                       charged / total_outcomes, NA_real_)]

# Stack for drug offences
drug_stacked <- list()
for (idx in 2:4) {
  e_yq <- election_yqs[idx]
  dt_e <- drug_panel[round((yq - e_yq) * 4) >= -8 & round((yq - e_yq) * 4) <= 7]
  dt_e <- copy(dt_e)
  dt_e[, cohort := idx]
  dt_e[, event_time := round((yq - e_yq) * 4)]
  dt_e[, cohort_force := paste0(force_name, "_c", idx)]
  dt_e[, cohort_yq := paste0(yq, "_c", idx)]
  dt_e[, pre_elect := fifelse(event_time >= -4 & event_time <= -1, 1L, 0L)]
  dt_e[, pcc_pre := pcc * pre_elect]
  dt_e[, post_elect := fifelse(event_time >= 0 & event_time <= 3, 1L, 0L)]
  dt_e[, pcc_post := pcc * post_elect]
  drug_stacked[[idx]] <- dt_e
}
drug_stack <- rbindlist(drug_stacked)

drug_placebo <- feols(
  charged_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = drug_stack,
  cluster = ~force_name
)
cat("Drug offence placebo — Charge rate:\n")
summary(drug_placebo)

# ============================================================================
# 4. Leave-one-out sensitivity
# ============================================================================
cat("\n=== Leave-one-out sensitivity ===\n")

all_forces <- unique(stacked$force_name)
loo_results <- data.table(
  dropped_force = character(),
  pre_coef = numeric(),
  pre_se = numeric(),
  post_coef = numeric(),
  post_se = numeric()
)

for (f in all_forces) {
  dt_loo <- stacked[force_name != f]
  m_loo <- feols(
    charged_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
    data = dt_loo,
    cluster = ~force_name
  )
  loo_results <- rbind(loo_results, data.table(
    dropped_force = f,
    pre_coef = coef(m_loo)["pcc_pre"],
    pre_se = se(m_loo)["pcc_pre"],
    post_coef = coef(m_loo)["pcc_post"],
    post_se = se(m_loo)["pcc_post"]
  ))
}

cat(sprintf("LOO charge rate — pre_coef: min=%.4f, max=%.4f, mean=%.4f\n",
            min(loo_results$pre_coef), max(loo_results$pre_coef),
            mean(loo_results$pre_coef)))
cat(sprintf("LOO charge rate — post_coef: min=%.4f, max=%.4f, mean=%.4f\n",
            min(loo_results$post_coef), max(loo_results$post_coef),
            mean(loo_results$post_coef)))

# Check if any single force drives the result
cat("\nMost influential forces (pre-election effect):\n")
print(loo_results[order(abs(pre_coef - mean(pre_coef)), decreasing = TRUE)][1:5])

# ============================================================================
# 5. Excluding COVID period (Election 3, 2021)
# ============================================================================
cat("\n=== Excluding COVID Election (2021) ===\n")

stacked_no_covid <- stacked[cohort != 3]

no_covid_charge <- feols(
  charged_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked_no_covid,
  cluster = ~force_name
)
cat("No COVID — Charge rate:\n")
summary(no_covid_charge)

no_covid_nosuspect <- feols(
  no_suspect_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked_no_covid,
  cluster = ~force_name
)
cat("\nNo COVID — No suspect rate:\n")
summary(no_covid_nosuspect)

# ============================================================================
# 6. Offence-group heterogeneity
# ============================================================================
cat("\n=== Offence-group heterogeneity ===\n")

# High-discretion offences (violence, sexual offences) vs low-discretion (theft)
# If electoral cycles affect charge decisions, the effect should concentrate
# in high-discretion offences where investigators have more leeway

# Build offence-level stacked panel
offence_groups <- unique(panel_wide$offence_group)
cat(sprintf("Offence groups: %s\n", paste(offence_groups, collapse = ", ")))

offence_results <- data.table(
  offence_group = character(),
  pre_coef = numeric(),
  pre_se = numeric(),
  pre_p = numeric(),
  post_coef = numeric(),
  post_se = numeric(),
  post_p = numeric()
)

for (og in offence_groups) {
  og_data <- panel_wide[offence_group == og]
  og_stacked <- list()
  for (idx in 2:4) {
    e_yq <- election_yqs[idx]
    dt_e <- og_data[round((yq - e_yq) * 4) >= -8 & round((yq - e_yq) * 4) <= 7]
    dt_e <- copy(dt_e)
    dt_e[, cohort := idx]
    dt_e[, event_time := round((yq - e_yq) * 4)]
    dt_e[, cohort_force := paste0(force_name, "_c", idx)]
    dt_e[, cohort_yq := paste0(yq, "_c", idx)]
    dt_e[, pre_elect := fifelse(event_time >= -4 & event_time <= -1, 1L, 0L)]
    dt_e[, pcc_pre := pcc * pre_elect]
    dt_e[, post_elect := fifelse(event_time >= 0 & event_time <= 3, 1L, 0L)]
    dt_e[, pcc_post := pcc * post_elect]
    og_stacked[[idx]] <- dt_e
  }
  og_stack <- rbindlist(og_stacked)

  tryCatch({
    m <- feols(
      charged_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
      data = og_stack,
      cluster = ~force_name
    )
    offence_results <- rbind(offence_results, data.table(
      offence_group = og,
      pre_coef = coef(m)["pcc_pre"],
      pre_se = se(m)["pcc_pre"],
      pre_p = pvalue(m)["pcc_pre"],
      post_coef = if ("pcc_post" %in% names(coef(m))) coef(m)["pcc_post"] else NA,
      post_se = if ("pcc_post" %in% names(se(m))) se(m)["pcc_post"] else NA,
      post_p = if ("pcc_post" %in% names(pvalue(m))) pvalue(m)["pcc_post"] else NA
    ))
  }, error = function(e) NULL)
}

cat("\nOffence-group heterogeneity (charge rate):\n")
print(offence_results[order(pre_coef)])

# ============================================================================
# 7. Save robustness results
# ============================================================================
rob_results <- list(
  drug_placebo = drug_placebo,
  loo_results = loo_results,
  no_covid_charge = no_covid_charge,
  no_covid_nosuspect = no_covid_nosuspect,
  offence_results = offence_results
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
