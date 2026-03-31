# 03_main_analysis.R — Main DiD analysis for Moldova banking crisis
# apep_1213

source("00_packages.R")

load("../data/analysis_panel.RData")
load("../data/raw_nbs_data.RData")

cat("=== Main Analysis: Moldova Banking Crisis and Firm Employment ===\n")

# ============================================================
# 1. Refine treatment variable
# ============================================================
# Financial enterprise share is a proxy for banking competition.
# HIGHER fin_share = MORE banks = LESS BEM dependence.
# We want "BEM dependence" = inverse. Use banking thinness.
#
# Raions with NA fin_share had ZERO financial enterprises (most BEM-dependent).
# Code them as maximum dependence.

panel_est <- copy(panel)

# For raions with NA (no financial enterprises), set max BEM dependence
max_fin_share <- max(panel_est$fin_share, na.rm = TRUE)
panel_est[is.na(fin_share), fin_share := 0]  # zero financial firms

# BEM dependence = negative of financial competition
# Higher = more BEM-dependent (fewer alternative banks)
panel_est[, bem_dependence := -fin_share]

# Z-score BEM dependence (cross-section, one value per raion)
raion_treat <- unique(panel_est[, .(raion_code, fin_share, bem_dependence)])
mean_bd <- mean(raion_treat$bem_dependence)
sd_bd <- sd(raion_treat$bem_dependence)

panel_est[, bem_dep_z := (bem_dependence - mean_bd) / sd_bd]
panel_est[, bem_dep_z_post := bem_dep_z * post]

# Also: binary treatment — raions in bottom half of financial enterprises
raion_treat[, high_bem_dep := as.integer(fin_share <= median(fin_share))]
panel_est <- merge(panel_est, raion_treat[, .(raion_code, high_bem_dep)],
  by = "raion_code", all.x = TRUE)
panel_est[, high_bem_post := high_bem_dep * post]

cat("Treatment: BEM dependence (higher = more dependent on BEM)\n")
cat(sprintf("  N raions: %d\n", nrow(raion_treat)))
cat(sprintf("  High-BEM raions: %d, Low-BEM raions: %d\n",
    sum(raion_treat$high_bem_dep), sum(1 - raion_treat$high_bem_dep)))

# ============================================================
# 2. Summary statistics
# ============================================================
cat("\n--- Summary statistics ---\n")

summary_stats <- panel_est[, .(
  mean_emp = mean(avg_employees, na.rm = TRUE),
  sd_emp = sd(avg_employees, na.rm = TRUE),
  median_emp = median(avg_employees, na.rm = TRUE),
  mean_enterprises = mean(n_enterprises, na.rm = TRUE),
  mean_turnover = mean(turnover_mln, na.rm = TRUE),
  n_raions = uniqueN(raion_code),
  n = .N
), by = .(period = ifelse(year >= 2015, "Post (2015-2024)", "Pre (2005-2014)"))]

print(summary_stats)

# ============================================================
# 3. Main DiD: BEM dependence × Post
# ============================================================
cat("\n--- Main DiD regressions ---\n")

# Model 1: Basic DiD with raion + year FE
m1 <- feols(log_emp ~ bem_dep_z_post | raion_code + year_f,
            data = panel_est, cluster = ~raion_code)

# Model 2: Add region × year FE (absorbs macro-regional trends)
panel_est[, region_year := paste0(region, "_", year)]
m2 <- feols(log_emp ~ bem_dep_z_post | raion_code + region_year,
            data = panel_est, cluster = ~raion_code)

# Model 3: Log enterprises (extensive margin)
m3 <- feols(log_enterprises ~ bem_dep_z_post | raion_code + year_f,
            data = panel_est, cluster = ~raion_code)

# Model 4: Log enterprises with region × year
m4 <- feols(log_enterprises ~ bem_dep_z_post | raion_code + region_year,
            data = panel_est, cluster = ~raion_code)

# Model 5: Log turnover
m5 <- feols(log_turnover ~ bem_dep_z_post | raion_code + year_f,
            data = panel_est, cluster = ~raion_code)

# Model 6: Log turnover with region × year
m6 <- feols(log_turnover ~ bem_dep_z_post | raion_code + region_year,
            data = panel_est, cluster = ~raion_code)

cat("Main results (1 SD increase in BEM dependence):\n")
cat("Log employment:\n")
cat(sprintf("  Raion + Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m1)[1], se(m1)[1], pvalue(m1)[1]))
cat(sprintf("  + Region×Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m2)[1], se(m2)[1], pvalue(m2)[1]))
cat("Log enterprises:\n")
cat(sprintf("  Raion + Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m3)[1], se(m3)[1], pvalue(m3)[1]))
cat(sprintf("  + Region×Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m4)[1], se(m4)[1], pvalue(m4)[1]))
cat("Log turnover:\n")
cat(sprintf("  Raion + Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m5)[1], se(m5)[1], pvalue(m5)[1]))
cat(sprintf("  + Region×Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m6)[1], se(m6)[1], pvalue(m6)[1]))

# ============================================================
# 4. Event study
# ============================================================
cat("\n--- Event study ---\n")

# With raion + year FE
m_event1 <- feols(log_emp ~ i(year, bem_dep_z, ref = 2014) | raion_code + year_f,
                  data = panel_est, cluster = ~raion_code)

# With region × year FE
m_event2 <- feols(log_emp ~ i(year, bem_dep_z, ref = 2014) | raion_code + region_year,
                  data = panel_est, cluster = ~raion_code)

# Extract event study coefficients (use region × year version)
ec <- data.table(
  year = as.integer(gsub("year::", "", gsub(":bem_dep_z", "", names(coef(m_event2))))),
  coef = coef(m_event2),
  se = se(m_event2)
)
ec[, ci_lo := coef - 1.96 * se]
ec[, ci_hi := coef + 1.96 * se]
ec <- rbind(ec, data.table(year = 2014, coef = 0, se = 0, ci_lo = 0, ci_hi = 0))
setorder(ec, year)

cat("Event study (BEM dependence × year, region×year FE):\n")
print(ec[, .(year, coef = round(coef, 4), se = round(se, 4),
  sig = ifelse(abs(coef/se) > 1.96, "***", ifelse(abs(coef/se) > 1.65, "*", "")))])

# Pre-trend test (with region × year FE)
pre_coefs_names <- names(coef(m_event2))[grepl("200[5-9]|201[0-3]", names(coef(m_event2)))]
if (length(pre_coefs_names) > 0) {
  pre_test <- wald(m_event2, keep = pre_coefs_names)
  cat(sprintf("\nJoint pre-trend test (region×year FE): F = %.3f, p = %.4f\n",
      pre_test$stat, pre_test$p))
}

# ============================================================
# 5. Binary treatment DiD
# ============================================================
cat("\n--- Binary treatment DiD ---\n")

m_bin1 <- feols(log_emp ~ high_bem_post | raion_code + year_f,
                data = panel_est, cluster = ~raion_code)
m_bin2 <- feols(log_emp ~ high_bem_post | raion_code + region_year,
                data = panel_est, cluster = ~raion_code)

cat(sprintf("Binary (high vs low BEM dependence):\n"))
cat(sprintf("  Raion + Year FE: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_bin1)[1], se(m_bin1)[1], pvalue(m_bin1)[1]))
cat(sprintf("  + Region×Year: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_bin2)[1], se(m_bin2)[1], pvalue(m_bin2)[1]))

# ============================================================
# 6. Mechanism: Financial sector outcome
# ============================================================
cat("\n--- Mechanism: Financial sector enterprises ---\n")

# Combine pre (sector J) and post (sector K) financial enterprise counts
fin_pre_panel <- dt_sector_pre[sector == "J" & indicator == "n_enterprises",
  .(raion_code, year, fin_enterprises = value)]
fin_post_panel <- dt_sector_post[sector == "K" & indicator == "n_enterprises",
  .(raion_code, year, fin_enterprises = value)]

fin_panel <- rbind(fin_pre_panel, fin_post_panel)
fin_panel <- merge(fin_panel, unique(panel_est[, .(raion_code, bem_dep_z, region)]),
  by = "raion_code")
fin_panel[, post := as.integer(year >= 2015)]
fin_panel[, bem_dep_z_post := bem_dep_z * post]
fin_panel[, year_f := factor(year)]
fin_panel[, region_year := paste0(region, "_", year)]
fin_panel[, log_fin_ent := log(pmax(fin_enterprises, 1))]

m_fin1 <- feols(log_fin_ent ~ bem_dep_z_post | raion_code + year_f,
                data = fin_panel, cluster = ~raion_code)

cat(sprintf("  Financial enterprises: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_fin1)[1], se(m_fin1)[1], pvalue(m_fin1)[1]))

# ============================================================
# 7. Save results
# ============================================================
results <- list(
  main_models = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
  event_study = list(basic = m_event1, region_yr = m_event2),
  event_coefs = ec,
  binary = list(m_bin1 = m_bin1, m_bin2 = m_bin2),
  mechanism = list(fin_sector = m_fin1),
  summary_stats = summary_stats,
  treat_dist = raion_treat
)

save(results, panel_est, file = "../data/main_results.RData")

# Write diagnostics.json
# Continuous treatment: all 35 raions treated at varying intensity
diagnostics <- list(
  n_treated = uniqueN(panel_est$raion_code),
  n_pre = length(2005:2014),
  n_obs = nrow(panel_est)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
    diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("Main analysis complete.\n")
