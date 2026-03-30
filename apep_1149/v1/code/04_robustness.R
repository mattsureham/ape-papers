# ==============================================================================
# 04_robustness.R — Placebo tests, donut holes, alternative specifications
# ==============================================================================

source("00_packages.R")
library(fixest)

panel <- fread("../data/analysis_panel.csv")

# =============================================================================
# Robustness 1: Placebo Distributor (McKesson pre-share as treatment)
# =============================================================================

pre_mckesson <- panel[post == 0,
  .(mckesson_pre_pills = sum(McKesson, na.rm = TRUE),
    total_pre_pills = sum(total_pills, na.rm = TRUE)),
  by = county_id]
pre_mckesson[, mckesson_share_pre := mckesson_pre_pills / total_pre_pills]
pre_mckesson[is.nan(mckesson_share_pre), mckesson_share_pre := 0]

panel <- merge(panel, pre_mckesson[, .(county_id, mckesson_share_pre)],
               by = "county_id", all.x = TRUE)

placebo_m1 <- feols(log_total_pills ~ mckesson_share_pre:post | county_id + period,
                    data = panel, cluster = ~state)

cat("\n=== Placebo: McKesson Share → Total Pills ===\n")
etable(placebo_m1, se.below = TRUE)

# =============================================================================
# Robustness 2: Donut Hole — Drop FL, WA, NJ
# =============================================================================

panel_donut <- panel[!(state %in% c("FL", "WA", "NJ"))]

donut_m1 <- feols(log_total_pills ~ cardinal_share:post | county_id + period,
                  data = panel_donut, cluster = ~state)
donut_m2 <- feols(log_cardinal ~ cardinal_share:post | county_id + period,
                  data = panel_donut, cluster = ~state)

cat("\n=== Donut Hole: Excluding FL, WA, NJ ===\n")
etable(donut_m1, donut_m2, se.below = TRUE)

# =============================================================================
# Robustness 3: Binary Treatment (High Cardinal Share >= 0.20)
# =============================================================================

panel[, high_cardinal := as.integer(cardinal_share >= 0.20)]

binary_m1 <- feols(log_total_pills ~ high_cardinal:post | county_id + period,
                   data = panel, cluster = ~state)
binary_m2 <- feols(log_cardinal ~ high_cardinal:post | county_id + period,
                   data = panel, cluster = ~state)

cat("\n=== Binary Treatment (High Cardinal >=20%) ===\n")
etable(binary_m1, binary_m2, se.below = TRUE)

# =============================================================================
# Robustness 4: Pre-trend Falsification (pre-treatment only, period 4 as fake cutoff)
# =============================================================================

pre_panel <- panel[post == 0]
pre_panel[, fake_post := as.integer(period >= 5)]  # 2007Q1 onward vs 2006

pretrend_test <- feols(log_total_pills ~ cardinal_share:fake_post | county_id + period,
                       data = pre_panel, cluster = ~state)

cat("\n=== Pre-trend Test (2006 vs 2007, both pre-treatment) ===\n")
etable(pretrend_test, se.below = TRUE)

# Save
save(placebo_m1, donut_m1, donut_m2, binary_m1, binary_m2,
     pretrend_test,
     file = "../data/robustness_results.RData")

cat("\nRobustness checks complete.\n")
