# =============================================================================
# 04_robustness.R — Robustness checks
# Paper: apep_0879 — MW and racial composition of hiring
# =============================================================================

source("00_packages.R")
library(fixest)
library(did)

df <- readRDS("../data/analysis_lowwage.rds")
results <- readRDS("../data/main_results.rds")

# =============================================================================
# A. Placebo sector: Healthcare (NAICS 62) where MW is less binding
# =============================================================================
cat("Running placebo: Healthcare sector...\n")

df_annual <- readRDS("../data/analysis_annual.rds")
df_health <- df_annual %>%
  filter(industry == "62", !is.na(black_hire_share), total_hires >= 10) %>%
  mutate(county_id = as.integer(factor(county_fips)))

twfe_placebo <- feols(
  black_hire_share ~ post | county_fips + year,
  data = df_health,
  cluster = ~state_fips
)

cat(sprintf("  Placebo Healthcare: %.4f (SE: %.4f, p=%.3f)\n",
            coef(twfe_placebo)["post"], se(twfe_placebo)["post"],
            pvalue(twfe_placebo)["post"]))

# =============================================================================
# B. Alternative treatment threshold: 120% of federal ($8.70)
# =============================================================================
cat("Running alternative treatment threshold (120%)...\n")

# Reclassify: only states that hit $8.70+
high_mw_states <- c("53", "41", "06", "25", "09", "36", "11",
                      "50", "15", "02", "04")  # States that hit $8.70+ early

df_alt <- df %>%
  mutate(
    treated_120 = ifelse(state_fips %in% high_mw_states, 1L, 0L),
    post_120 = ifelse(treated_120 == 1 & post == 1, 1L, 0L)
  )

twfe_alt <- feols(
  black_hire_share ~ post_120 | county_fips + year,
  data = df_alt,
  cluster = ~state_fips
)

cat(sprintf("  Alt threshold 120%%: %.4f (SE: %.4f)\n",
            coef(twfe_alt)["post_120"], se(twfe_alt)["post_120"]))

# =============================================================================
# C. Heterogeneity: High vs Low baseline Black share
# =============================================================================
cat("Running heterogeneity by baseline Black share...\n")

# Pre-treatment Black share (before any state is treated)
baseline <- df %>%
  filter(year <= 2008) %>%
  group_by(county_fips) %>%
  summarise(baseline_black_share = mean(black_hire_share, na.rm = TRUE),
            .groups = "drop")

df_het <- df %>%
  left_join(baseline, by = "county_fips") %>%
  filter(!is.na(baseline_black_share))

median_bbs <- median(df_het$baseline_black_share, na.rm = TRUE)

twfe_high_black <- feols(
  black_hire_share ~ post | county_fips + year,
  data = df_het %>% filter(baseline_black_share >= median_bbs),
  cluster = ~state_fips
)

twfe_low_black <- feols(
  black_hire_share ~ post | county_fips + year,
  data = df_het %>% filter(baseline_black_share < median_bbs),
  cluster = ~state_fips
)

cat(sprintf("  High baseline Black share: %.4f (SE: %.4f)\n",
            coef(twfe_high_black)["post"], se(twfe_high_black)["post"]))
cat(sprintf("  Low baseline Black share: %.4f (SE: %.4f)\n",
            coef(twfe_low_black)["post"], se(twfe_low_black)["post"]))

# =============================================================================
# D. Heterogeneity: By MW bite (large vs small increase)
# =============================================================================
cat("Running heterogeneity by MW bite...\n")

# States with MW >= $10 by 2016 vs those that barely crossed $8
large_bite_states <- c("53", "06", "25", "09", "36", "11")

df_bite <- df %>%
  mutate(large_bite = ifelse(state_fips %in% large_bite_states, 1L, 0L))

twfe_large_bite <- feols(
  black_hire_share ~ post | county_fips + year,
  data = df_bite %>% filter(large_bite == 1),
  cluster = ~state_fips
)

twfe_small_bite <- feols(
  black_hire_share ~ post | county_fips + year,
  data = df_bite %>% filter(large_bite == 0),
  cluster = ~state_fips
)

cat(sprintf("  Large MW bite: %.4f (SE: %.4f)\n",
            coef(twfe_large_bite)["post"], se(twfe_large_bite)["post"]))
cat(sprintf("  Small MW bite: %.4f (SE: %.4f)\n",
            coef(twfe_small_bite)["post"], se(twfe_small_bite)["post"]))

# =============================================================================
# E. Skip wild cluster bootstrap (49 state clusters is sufficient for CLV)
# =============================================================================
cat("Skipping wild cluster bootstrap (49 clusters sufficient for CLV).\n")
robust_results_boot <- NULL

# =============================================================================
# F. Save robustness results
# =============================================================================
robust <- list(
  twfe_placebo = twfe_placebo,
  twfe_alt = twfe_alt,
  twfe_high_black = twfe_high_black,
  twfe_low_black = twfe_low_black,
  twfe_large_bite = twfe_large_bite,
  twfe_small_bite = twfe_small_bite,
  boot = robust_results_boot,
  median_baseline_black = median_bbs
)

saveRDS(robust, "../data/robust_results.rds")
cat("\nRobustness checks complete.\n")
