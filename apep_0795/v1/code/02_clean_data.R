# =============================================================================
# 02_clean_data.R — Reshape MLP panel into stacked decade-transition format
# =============================================================================
# Creates a panel with two observations per individual (1920→1930 and 1930→1940),
# allowing the triple-diff: Black × Excluded × Post-SSA
# =============================================================================

source("00_packages.R")

cat("=== Loading MLP panel ===\n")
df <- readRDS("../data/mlp_panel.rds")
setDT(df)
cat("Loaded:", format(nrow(df), big.mark = ","), "individuals\n")

# -------------------------------------------------------------------------
# Create stacked panel: two decade transitions per individual
# -------------------------------------------------------------------------

# Transition 1: 1920 → 1930 (pre-SSA)
t1 <- df[, .(
  histid = histid_1930,
  decade = "1920_1930",
  post_ssa = 0L,
  race = race_1930,
  black = black,
  age_start = age_1920,
  sex = sex_1920,
  state_start = statefip_1920,
  county_start = countyicp_1920,
  occ_start = occ1950_1920,
  occ_end = occ1950_1930,
  occ_cat_start = occ_cat_1920,
  occ_cat_end = occ_cat_1930,
  excluded_start = excluded_1920,
  sei_start = sei_1920,
  occscore_start = occscore_1920,
  sei_end = sei_1930,
  occscore_end = occscore_1930,
  marst_start = marst_1920,
  bpl = bpl_1920,
  mover = mover_20_30,
  switch_to_covered = switch_to_covered_20_30
)]

# Transition 2: 1930 → 1940 (post-SSA)
t2 <- df[, .(
  histid = histid_1930,
  decade = "1930_1940",
  post_ssa = 1L,
  race = race_1930,
  black = black,
  age_start = age_1930,
  sex = sex_1930,
  state_start = statefip_1930,
  county_start = countyicp_1930,
  occ_start = occ1950_1930,
  occ_end = occ1950_1940,
  occ_cat_start = occ_cat_1930,
  occ_cat_end = occ_cat_1940,
  excluded_start = excluded_1930,
  sei_start = sei_1930,
  occscore_start = occscore_1930,
  sei_end = sei_1940,
  occscore_end = occscore_1940,
  marst_start = marst_1930,
  bpl = bpl_1930,
  mover = mover_30_40,
  switch_to_covered = switch_to_covered_30_40
)]

panel <- rbindlist(list(t1, t2))
cat("Stacked panel:", format(nrow(panel), big.mark = ","), "person-decade observations\n")

# -------------------------------------------------------------------------
# Additional variables for analysis
# -------------------------------------------------------------------------

# Detailed excluded category
panel[, excl_type := fifelse(occ_cat_start == "farmer", "farmer",
  fifelse(occ_cat_start == "farm_labor", "farm_labor",
    fifelse(occ_cat_start == "domestic", "domestic", "covered")))]

# Age bins for heterogeneity (at start of decade)
panel[, age_bin := cut(age_start, breaks = c(14, 24, 34, 44, 54, 65),
  labels = c("15-24", "25-34", "35-44", "45-54", "55-64"))]

# Young worker indicator (under 45 — long pension horizon in 1935)
panel[, young := as.integer(age_start < 45)]

# Occupation change indicator (any change, not just excluded→covered)
panel[, occ_changed := as.integer(occ_start != occ_end)]

# Occupational upgrading: SEI improvement
panel[, sei_gain := sei_end - sei_start]
panel[, upgraded := as.integer(sei_end > sei_start)]

# State-level controls: create state×county identifier
panel[, state_county := paste0(state_start, "_", county_start)]

# -------------------------------------------------------------------------
# Summary tables for the stacked panel
# -------------------------------------------------------------------------
cat("\n=== Key Statistics ===\n")
cat("--- Switching Rates by Race × Occupation × Decade ---\n")
summary_tab <- panel[excluded_start == TRUE,
  .(switch_rate = mean(switch_to_covered, na.rm = TRUE),
    n = .N),
  by = .(black, excl_type, post_ssa)]
print(summary_tab[order(black, excl_type, post_ssa)])

cat("\n--- Triple-Diff Preview ---\n")
dd <- panel[excluded_start == TRUE,
  .(switch_rate = mean(switch_to_covered, na.rm = TRUE)),
  by = .(black, post_ssa)]
print(dd[order(black, post_ssa)])

# Calculate raw DD
w_pre <- dd[black == 0 & post_ssa == 0, switch_rate]
w_post <- dd[black == 0 & post_ssa == 1, switch_rate]
b_pre <- dd[black == 1 & post_ssa == 0, switch_rate]
b_post <- dd[black == 1 & post_ssa == 1, switch_rate]

cat(sprintf("\nRaw DiD (excluded workers only):\n"))
cat(sprintf("  White: %.3f → %.3f (change: %.3f)\n", w_pre, w_post, w_post - w_pre))
cat(sprintf("  Black: %.3f → %.3f (change: %.3f)\n", b_pre, b_post, b_post - b_pre))
cat(sprintf("  DD: %.3f\n", (b_post - b_pre) - (w_post - w_pre)))

# -------------------------------------------------------------------------
# Save cleaned panel
# -------------------------------------------------------------------------
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis panel to data/analysis_panel.rds\n")
cat("Observations:", format(nrow(panel), big.mark = ","), "\n")
