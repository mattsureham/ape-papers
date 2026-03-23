# =============================================================================
# 03_main_analysis.R — Triple-Difference: Black × Excluded × Post-SSA
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- readRDS("../data/analysis_panel.rds")
setDT(panel)
cat("Panel:", format(nrow(panel), big.mark = ","), "obs\n")

excluded <- panel[excluded_start == TRUE]
cat("Excluded-occupation sample:", format(nrow(excluded), big.mark = ","), "\n")

# -------------------------------------------------------------------------
# Model 1: Basic DiD — Black × Post-SSA (excluded workers only)
# -------------------------------------------------------------------------
cat("\n=== Model 1: Basic DiD (excluded workers only) ===\n")
m1 <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded, vcov = ~state_start)
summary(m1)

# -------------------------------------------------------------------------
# Model 2: DiD with demographic controls
# -------------------------------------------------------------------------
cat("\n=== Model 2: DiD + Controls ===\n")
m2 <- feols(switch_to_covered ~ black * post_ssa +
  i(age_bin) + i(sex) + i(marst_start) | state_start,
  data = excluded, vcov = ~state_start)

# -------------------------------------------------------------------------
# Model 3: Triple-Diff (full panel: excluded + covered workers)
# -------------------------------------------------------------------------
cat("\n=== Model 3: Triple-Diff ===\n")
m3 <- feols(switch_to_covered ~ black * excluded_start * post_ssa |
  state_start,
  data = panel, vcov = ~state_start)

# -------------------------------------------------------------------------
# Model 4: DiD with state × decade FE (excluded workers only, avoids memory)
# -------------------------------------------------------------------------
cat("\n=== Model 4: DiD + State×Decade FE + Controls ===\n")
m4 <- feols(switch_to_covered ~ black * post_ssa +
  i(age_bin) + i(sex) | state_start^post_ssa,
  data = excluded, vcov = ~state_start)

# -------------------------------------------------------------------------
# Model 5: By excluded occupation type
# -------------------------------------------------------------------------
cat("\n=== Model 5: By Occupation Type ===\n")
m5_dom <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[excl_type == "domestic"], vcov = ~state_start)
m5_fl <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[excl_type == "farm_labor"], vcov = ~state_start)
m5_fm <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[excl_type == "farmer"], vcov = ~state_start)

cat("Domestic  Black×Post:", sprintf("%.4f (%.4f)", coef(m5_dom)["black:post_ssa"], se(m5_dom)["black:post_ssa"]), "\n")
cat("FarmLabor Black×Post:", sprintf("%.4f (%.4f)", coef(m5_fl)["black:post_ssa"], se(m5_fl)["black:post_ssa"]), "\n")
cat("Farmer    Black×Post:", sprintf("%.4f (%.4f)", coef(m5_fm)["black:post_ssa"], se(m5_fm)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# Model 6: Age heterogeneity — young vs old
# -------------------------------------------------------------------------
cat("\n=== Model 6: Age Heterogeneity ===\n")
m6 <- feols(switch_to_covered ~ black * post_ssa * young | state_start,
  data = excluded, vcov = ~state_start)

cat("Triple (Young × Black × Post):", sprintf("%.4f (%.4f)",
  coef(m6)["black:post_ssa:young"], se(m6)["black:post_ssa:young"]), "\n")

# -------------------------------------------------------------------------
# Print comparison tables
# -------------------------------------------------------------------------
cat("\n========== TABLE 1: MAIN RESULTS ==========\n")
etable(m1, m2, m3, m4,
  headers = c("DiD", "DiD+Ctrl", "DDD", "DiD+St×Dec"),
  keep = c("black", "post_ssa", "excluded", ":"),
  se.below = TRUE,
  fitstat = c("n", "r2"))

cat("\n========== TABLE 2: BY OCCUPATION TYPE ==========\n")
etable(m5_dom, m5_fl, m5_fm,
  headers = c("Domestic", "Farm Labor", "Farmer"),
  keep = c("black", "post_ssa", ":"),
  se.below = TRUE,
  fitstat = c("n", "r2"))

cat("\n========== TABLE 3: AGE HETEROGENEITY ==========\n")
etable(m6,
  keep = c("black", "post_ssa", "young", ":"),
  se.below = TRUE,
  fitstat = c("n", "r2"))

# -------------------------------------------------------------------------
# SD(Y) for SDE calculation
# -------------------------------------------------------------------------
sd_y_pre <- sd(excluded[post_ssa == 0, switch_to_covered])
cat("\nSD(Y) pre-treatment:", round(sd_y_pre, 4), "\n")
cat("Mean(Y) pre-treatment:", round(mean(excluded[post_ssa == 0, switch_to_covered]), 4), "\n")

# -------------------------------------------------------------------------
# Save results
# -------------------------------------------------------------------------
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  m5_dom = m5_dom, m5_fl = m5_fl, m5_fm = m5_fm,
  m6 = m6,
  sd_y_pre = sd_y_pre
)
saveRDS(results, "../data/main_results.rds")

# Diagnostics for validator
diag <- list(
  n_treated = sum(panel$black == 1 & panel$excluded_start == TRUE),
  n_pre = 1L,
  n_obs = nrow(panel)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
