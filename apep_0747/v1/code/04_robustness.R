## 04_robustness.R — Robustness checks and placebo tests
source("00_packages.R")

panel <- readRDS("../data/panel.rds")
panel$state_fips_f <- as.factor(panel$state_fips)

# ===================================================================
# 1. Placebo: Low-CAFO counties in RTF states
# ===================================================================
cat("=== Placebo: Low-CAFO Counties ===\n")

# If RTF drives sorting specifically through CAFO nuisance, low-CAFO
# counties in treated states should show no effect
panel_low <- panel %>%
  filter(hog_quintile <= 2 | hog_quintile == 0)  # Bottom 40% + zero hog counties

m_placebo <- feols(
  hisp_share ~ post_rtf |
    county_fips + year,
  data = panel_low,
  cluster = ~state_fips
)
cat("Placebo (low-CAFO counties, Hispanic share):\n")
summary(m_placebo)

m_placebo_w <- feols(
  white_share ~ post_rtf |
    county_fips + year,
  data = panel_low,
  cluster = ~state_fips
)
cat("\nPlacebo (low-CAFO counties, White share):\n")
summary(m_placebo_w)

# ===================================================================
# 2. Alternative CAFO threshold: top quintile only
# ===================================================================
cat("\n=== Alternative CAFO Thresholds ===\n")

panel$top_quintile <- as.integer(panel$hog_quintile == 5)

m_q5 <- feols(
  hisp_share ~ post_rtf:top_quintile + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("Top quintile only (Hispanic share):\n")
summary(m_q5)

# Terciles
panel$hog_tercile <- ifelse(panel$hog_quintile == 0, 0L,
                            ntile(panel$hog_inv_2012[panel$hog_quintile > 0],
                                  3)[match(panel$county_fips,
                                           panel$county_fips[panel$hog_quintile > 0])])
panel$high_cafo_t3 <- as.integer(panel$hog_tercile == 3)

m_t3 <- feols(
  hisp_share ~ post_rtf:high_cafo_t3 + post_rtf |
    county_fips + year,
  data = panel %>% filter(!is.na(high_cafo_t3)),
  cluster = ~state_fips
)
cat("\nTop tercile (Hispanic share):\n")
summary(m_t3)

# ===================================================================
# 3. Black share (additional outcome)
# ===================================================================
cat("\n=== Additional Outcome: Black Share ===\n")

m_black <- feols(
  black_share ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips
)
cat("Black Share DDD:\n")
summary(m_black)

# ===================================================================
# 4. Population-weighted regression
# ===================================================================
cat("\n=== Population-Weighted ===\n")

m_wt <- feols(
  hisp_share ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel,
  cluster = ~state_fips,
  weights = ~total_pop
)
cat("Weighted Hispanic Share DDD:\n")
summary(m_wt)

# ===================================================================
# 5. Exclude early RTF state (ND 2012) — sensitivity to single state
# ===================================================================
cat("\n=== Exclude North Dakota ===\n")

m_no_nd <- feols(
  hisp_share ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel %>% filter(state_fips != "38"),
  cluster = ~state_fips
)
cat("Exclude ND (Hispanic share):\n")
summary(m_no_nd)

# ===================================================================
# 6. Exclude Florida (latest adopter, very different demographics)
# ===================================================================
cat("\n=== Exclude Florida ===\n")

m_no_fl <- feols(
  hisp_share ~ post_rtf:high_cafo + post_rtf |
    county_fips + year,
  data = panel %>% filter(state_fips != "12"),
  cluster = ~state_fips
)
cat("Exclude FL (Hispanic share):\n")
summary(m_no_fl)

# ===================================================================
# 7. Save robustness results
# ===================================================================
rob <- list(
  placebo = m_placebo,
  placebo_w = m_placebo_w,
  top_quintile = m_q5,
  top_tercile = m_t3,
  black_share = m_black,
  pop_weighted = m_wt,
  no_nd = m_no_nd,
  no_fl = m_no_fl
)
saveRDS(rob, "../data/robustness.rds")
cat("\nRobustness results saved.\n")
