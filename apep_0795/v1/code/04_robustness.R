# =============================================================================
# 04_robustness.R — Robustness Checks and Placebos
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- readRDS("../data/analysis_panel.rds")
setDT(panel)
excluded <- panel[excluded_start == TRUE]

# -------------------------------------------------------------------------
# 1. Placebo: Covered workers (no SSA switching incentive)
# -------------------------------------------------------------------------
cat("\n=== 1. Placebo: Covered Workers ===\n")
covered <- panel[excluded_start == FALSE]
placebo <- feols(occ_changed ~ black * post_ssa | state_start,
  data = covered, vcov = ~state_start)
cat("Covered workers (any occ change):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(placebo)["black:post_ssa"],
  se(placebo)["black:post_ssa"],
  pvalue(placebo)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# 2. SEI occupational upgrading (mechanism: workers upgrading, not just moving)
# -------------------------------------------------------------------------
cat("\n=== 2. SEI Gain (Occupational Upgrading) ===\n")
m_sei <- feols(sei_gain ~ black * post_ssa | state_start,
  data = excluded, vcov = ~state_start)
cat("SEI gain (excluded workers):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(m_sei)["black:post_ssa"],
  se(m_sei)["black:post_ssa"],
  pvalue(m_sei)["black:post_ssa"]), "\n")

# SEI gain for domestic workers
m_sei_dom <- feols(sei_gain ~ black * post_ssa | state_start,
  data = excluded[excl_type == "domestic"], vcov = ~state_start)
cat("SEI gain (domestic workers):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(m_sei_dom)["black:post_ssa"],
  se(m_sei_dom)["black:post_ssa"],
  pvalue(m_sei_dom)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# 3. Geographic mobility (interstate moves)
# -------------------------------------------------------------------------
cat("\n=== 3. Geographic Mobility ===\n")
m_move <- feols(mover ~ black * post_ssa | state_start,
  data = excluded, vcov = ~state_start)
cat("Interstate move (excluded workers):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(m_move)["black:post_ssa"],
  se(m_move)["black:post_ssa"],
  pvalue(m_move)["black:post_ssa"]), "\n")

# Mobility for domestic workers
m_move_dom <- feols(mover ~ black * post_ssa | state_start,
  data = excluded[excl_type == "domestic"], vcov = ~state_start)
cat("Interstate move (domestic workers):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(m_move_dom)["black:post_ssa"],
  se(m_move_dom)["black:post_ssa"],
  pvalue(m_move_dom)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# 4. South vs Non-South
# -------------------------------------------------------------------------
cat("\n=== 4. South vs Non-South ===\n")
m_s <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[south == 1], vcov = ~state_start)
m_ns <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[south == 0], vcov = ~state_start)
cat("South only:\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f)", coef(m_s)["black:post_ssa"], se(m_s)["black:post_ssa"]), "\n")
cat("Non-South:\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f)", coef(m_ns)["black:post_ssa"], se(m_ns)["black:post_ssa"]), "\n")

# South for domestic workers
m_s_dom <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[south == 1 & excl_type == "domestic"], vcov = ~state_start)
m_ns_dom <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = excluded[south == 0 & excl_type == "domestic"], vcov = ~state_start)
cat("Domestic — South:\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f)", coef(m_s_dom)["black:post_ssa"], se(m_s_dom)["black:post_ssa"]), "\n")
cat("Domestic — Non-South:\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f)", coef(m_ns_dom)["black:post_ssa"], se(m_ns_dom)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# 5. Manufacturing entry (specific covered sector)
# -------------------------------------------------------------------------
cat("\n=== 5. Manufacturing Entry ===\n")
m_mfg <- feols(enter_manufacturing ~ black * post_ssa | state_start,
  data = excluded, vcov = ~state_start)
cat("Enter manufacturing (excluded workers):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(m_mfg)["black:post_ssa"],
  se(m_mfg)["black:post_ssa"],
  pvalue(m_mfg)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# 6. Wage workers only (drop self-employed farmers)
# -------------------------------------------------------------------------
cat("\n=== 6. Wage Workers Only ===\n")
wage <- excluded[excl_type != "farmer"]
m_wage <- feols(switch_to_covered ~ black * post_ssa | state_start,
  data = wage, vcov = ~state_start)
cat("Wage workers only (domestic + farm labor):\n")
cat("  Black × PostSSA:", sprintf("%.4f (%.4f, p=%.4f)",
  coef(m_wage)["black:post_ssa"],
  se(m_wage)["black:post_ssa"],
  pvalue(m_wage)["black:post_ssa"]), "\n")

# -------------------------------------------------------------------------
# Summary table
# -------------------------------------------------------------------------
cat("\n========== ROBUSTNESS SUMMARY ==========\n")
etable(placebo, m_sei, m_move, m_mfg,
  headers = c("Placebo", "SEI Gain", "Mobility", "Mfg Entry"),
  keep = c("black:post_ssa"),
  se.below = TRUE,
  fitstat = c("n", "r2"))

# -------------------------------------------------------------------------
# Save robustness results
# -------------------------------------------------------------------------
robust <- list(
  placebo = placebo, sei = m_sei, sei_dom = m_sei_dom,
  mobility = m_move, mobility_dom = m_move_dom,
  south = m_s, nonsouth = m_ns,
  south_dom = m_s_dom, nonsouth_dom = m_ns_dom,
  manufacturing = m_mfg, wage_only = m_wage
)
saveRDS(robust, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
