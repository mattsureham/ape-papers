# 04_robustness.R — Robustness checks
# Japan Heisei Municipal Merger Fiscal Cliff (apep_0836)

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))

# Compute log outcomes and treatment variables
panel[, log_sfd_pc := log(sfd_pc + 1)]
panel[, log_sfr_pc := log(sfr_pc + 1)]
panel[, log_lat_pc := log(lat_pc + 1)]
panel[, log_std_scale_pc := log(std_scale_pc + 1)]
panel[, post_phaseout := fifelse(merged == TRUE & event_time >= 0, 1L, 0L)]
panel[, cohort := fifelse(merged == TRUE, phaseout_start_fy, Inf)]

# ============================================================
# 1. Restricted event window (clean pre-trends)
# ============================================================
cat("=== Robustness: Restricted Event Window (-3 to +5) ===\n")

# Focus on the clean pre-trend window where nearly all cohorts contribute
panel_restricted <- panel[
  (merged == TRUE & event_time >= -3 & event_time <= 5) |
  never_merged == TRUE
]

rob_sfd <- feols(
  log_sfd_pc ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel_restricted,
  cluster = ~muni_code
)

rob_lat <- feols(
  log_lat_pc ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel_restricted,
  cluster = ~muni_code
)

rob_sfr <- feols(
  log_sfr_pc ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel_restricted,
  cluster = ~muni_code
)

cat("Restricted window - SFD:\n")
summary(rob_sfd)

# ============================================================
# 2. Callaway-Sant'Anna estimator
# ============================================================
cat("\n=== Robustness: Callaway & Sant'Anna (2021) ===\n")

# CS requires: first.treat = 0 for never-treated, > 0 for treated
panel_cs <- copy(panel)
panel_cs[, first_treat := fifelse(merged == TRUE, phaseout_start_fy, 0L)]

# CS estimator for SFD
cs_sfd <- att_gt(
  yname = "log_sfd_pc",
  tname = "fiscal_year",
  idname = "muni_code_num",
  gname = "first_treat",
  data = panel_cs[, muni_code_num := as.integer(as.factor(muni_code))],
  control_group = "nevertreated",
  est_method = "reg",
  base_period = "universal"
)

cat("C&S aggregate ATT (SFD):\n")
agg_cs_sfd <- aggte(cs_sfd, type = "simple")
summary(agg_cs_sfd)

# CS for LAT
cs_lat <- att_gt(
  yname = "log_lat_pc",
  tname = "fiscal_year",
  idname = "muni_code_num",
  gname = "first_treat",
  data = panel_cs,
  control_group = "nevertreated",
  est_method = "reg",
  base_period = "universal"
)

cat("C&S aggregate ATT (LAT):\n")
agg_cs_lat <- aggte(cs_lat, type = "simple")
summary(agg_cs_lat)

# CS event study
cs_es_sfd <- aggte(cs_sfd, type = "dynamic", min_e = -3, max_e = 5)
cat("\nC&S Event Study (SFD):\n")
summary(cs_es_sfd)

# ============================================================
# 3. Heterogeneity by merger cohort
# ============================================================
cat("\n=== Heterogeneity: By Merger Cohort ===\n")

# Split by major cohorts: FY2003-2004 vs FY2005
panel[merged == TRUE, cohort_group := fcase(
  merge_fy <= 2004, "Early (<=2004)",
  merge_fy == 2005, "Peak (2005)",
  merge_fy >= 2006, "Late (>=2006)"
)]

for (grp in c("Early (<=2004)", "Peak (2005)", "Late (>=2006)")) {
  sample <- panel[(merged == TRUE & cohort_group == grp) | never_merged == TRUE]
  if (uniqueN(sample$muni_code[sample$merged == TRUE]) < 10) next

  est <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
               data = sample, cluster = ~muni_code)
  cat(sprintf("  %s (N_treated=%d): coef=%.4f, se=%.4f, p=%.4f\n",
              grp, uniqueN(sample$muni_code[sample$merged == TRUE]),
              coef(est), se(est), pvalue(est)))
}

# ============================================================
# 4. Heterogeneity by pre-merger LAT dependence
# ============================================================
cat("\n=== Heterogeneity: By Pre-Merger LAT Dependence ===\n")

# Compute pre-phase-out LAT share for each merged municipality
pre_lat <- panel[merged == TRUE & event_time < 0, .(
  pre_lat_share = mean(lat_share, na.rm = TRUE)
), by = muni_code]

panel <- merge(panel, pre_lat, by = "muni_code", all.x = TRUE)

# Split at median
med_lat <- median(pre_lat$pre_lat_share, na.rm = TRUE)
panel[, high_lat_dep := pre_lat_share >= med_lat]

for (dep in c(TRUE, FALSE)) {
  lab <- ifelse(dep, "High LAT dependence", "Low LAT dependence")
  sample <- panel[(merged == TRUE & high_lat_dep == dep) | never_merged == TRUE]
  n_tr <- uniqueN(sample$muni_code[sample$merged == TRUE])
  if (n_tr < 10) next

  est <- feols(log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
               data = sample, cluster = ~muni_code)
  cat(sprintf("  %s (N=%d): coef=%.4f, se=%.4f\n", lab, n_tr, coef(est), se(est)))
}

# ============================================================
# 5. Placebo: Never-merged municipalities with pseudo treatment
# ============================================================
cat("\n=== Placebo: Pseudo-Treatment for Never-Merged ===\n")

# Assign random phase-out years to never-merged municipalities
# using the same distribution as actual phase-out years
set.seed(42)
never_merged_ids <- unique(panel$muni_code[panel$never_merged == TRUE])
actual_cohort_dist <- panel[merged == TRUE, .(n = .N), by = phaseout_start_fy]
actual_cohort_dist[, prob := n / sum(n)]

pseudo_cohorts <- data.table(
  muni_code = never_merged_ids,
  pseudo_phaseout = sample(
    actual_cohort_dist$phaseout_start_fy,
    length(never_merged_ids),
    replace = TRUE,
    prob = actual_cohort_dist$prob
  )
)

panel_placebo <- merge(
  panel[never_merged == TRUE],
  pseudo_cohorts, by = "muni_code"
)
panel_placebo[, pseudo_post := fifelse(fiscal_year >= pseudo_phaseout, 1L, 0L)]

placebo_est <- feols(
  log_sfd_pc ~ pseudo_post | muni_code + fiscal_year,
  data = panel_placebo,
  cluster = ~muni_code
)
cat("Placebo test (never-merged with pseudo treatment):\n")
cat(sprintf("  coef=%.4f, se=%.4f, p=%.4f\n",
            coef(placebo_est), se(placebo_est), pvalue(placebo_est)))

# ============================================================
# 6. Save robustness results
# ============================================================
saveRDS(list(
  rob_sfd = rob_sfd, rob_lat = rob_lat, rob_sfr = rob_sfr,
  cs_sfd = cs_sfd, cs_lat = cs_lat,
  agg_cs_sfd = agg_cs_sfd, agg_cs_lat = agg_cs_lat,
  placebo_est = placebo_est
), file.path(data_dir, "robustness_models.rds"))

# Update panel with heterogeneity variables
saveRDS(panel, file.path(data_dir, "panel_clean.rds"))

cat("\n=== Robustness checks complete ===\n")
