# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds") |>
  filter(foreign_pop > 0, !is.na(nat_rate), is.finite(nat_rate)) |>
  mutate(
    event_time = year - 2004,
    event_time_binned = case_when(
      event_time <= -10 ~ -10L,
      event_time >= 15 ~ 15L,
      TRUE ~ as.integer(event_time)
    ),
    any_nat = as.integer(naturalizations > 0)
  )

full_panel <- readRDS("../data/full_panel.rds") |>
  filter(foreign_pop > 0, !is.na(nat_rate), is.finite(nat_rate)) |>
  mutate(any_nat = as.integer(naturalizations > 0))

# =============================================================================
# 1. PLACEBO OUTCOMES — Births and Deaths (should NOT respond to ruling)
# =============================================================================

cat("=== PLACEBO OUTCOMES ===\n")

# We need to fetch birth and death data for the placebo test
# These are components 1 (births) and 2 (deaths) in the BFS data
# For now, use the foreign population growth as a pseudo-placebo

# Placebo: foreign population share (shouldn't change discontinuously at ruling)
m_placebo_fpop <- feols(foreign_share ~ ballot:post | bfs_nr + year,
                         data = panel |> mutate(foreign_share = foreign_pop / total_pop * 100),
                         cluster = ~canton_abbr)

# Placebo: total population growth
panel <- panel |>
  group_by(bfs_nr) |>
  mutate(pop_growth = (total_pop - lag(total_pop)) / lag(total_pop) * 100) |>
  ungroup()

m_placebo_pop <- feols(pop_growth ~ ballot:post | bfs_nr + year,
                        data = panel |> filter(!is.na(pop_growth)),
                        cluster = ~canton_abbr)

cat("Placebo: Foreign population share\n")
summary(m_placebo_fpop)
cat("\nPlacebo: Population growth\n")
summary(m_placebo_pop)

# =============================================================================
# 2. ALTERNATIVE TREATMENT TIMING
# =============================================================================

cat("\n=== ALTERNATIVE TREATMENT TIMING ===\n")

# Test robustness to post-period definition: 2003 vs 2004 vs 2005
for (cutoff in c(2003, 2004, 2005)) {
  m <- feols(nat_rate ~ ballot:I(year >= cutoff) | bfs_nr + year + canton_abbr[year],
             data = panel, cluster = ~canton_abbr)
  cat(sprintf("Cutoff %d: coef = %.3f (SE = %.3f)\n",
              cutoff, coef(m)[1], se(m)[1]))
}

# =============================================================================
# 3. INCLUDE MIXED CANTONS
# =============================================================================

cat("\n=== INCLUDING MIXED CANTONS ===\n")

# Robustness: include BE, FR, VS, GR, UR as "mixed" treatment
# Treat German-speaking parts as treated, French/Italian as control
# Simple version: include them all as control

full_panel_robust <- full_panel |>
  mutate(
    ballot = as.integer(treatment_group == "ballot"),
    post = as.integer(year >= 2004)
  )

m_full <- feols(nat_rate ~ ballot:post | bfs_nr + year,
                data = full_panel_robust, cluster = ~canton_abbr)

m_full_trends <- feols(nat_rate ~ ballot:post | bfs_nr + year + canton_abbr[year],
                        data = full_panel_robust, cluster = ~canton_abbr)

cat("Full sample (mixed as control):\n")
etable(m_full, m_full_trends)

# =============================================================================
# 4. DROP ONE CANTON AT A TIME (Leave-One-Out)
# =============================================================================

cat("\n=== LEAVE-ONE-OUT (Ballot Cantons) ===\n")

ballot_cantons <- unique(panel$canton_abbr[panel$ballot == 1])
loo_results <- data.frame(
  dropped_canton = character(),
  estimate = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (ct in ballot_cantons) {
  m_loo <- feols(nat_rate ~ ballot:post | bfs_nr + year + canton_abbr[year],
                 data = panel |> filter(canton_abbr != ct),
                 cluster = ~canton_abbr)
  loo_results <- rbind(loo_results, data.frame(
    dropped_canton = ct,
    estimate = coef(m_loo)[1],
    se = se(m_loo)[1]
  ))
}

cat("Leave-one-out results (preferred spec with canton trends):\n")
print(loo_results |> arrange(estimate))
cat(sprintf("\nRange: [%.2f, %.2f]\n", min(loo_results$estimate), max(loo_results$estimate)))

saveRDS(loo_results, "../data/loo_results.rds")

# =============================================================================
# 5. HONESTDID SENSITIVITY
# =============================================================================

cat("\n=== HONESTDID SENSITIVITY ===\n")

# Run on the baseline event study (without canton trends, for the formal test)
es_base <- feols(nat_rate ~ i(event_time_binned, ballot, ref = -1) | bfs_nr + year,
                 data = panel, cluster = ~canton_abbr)

tryCatch({
  # Extract pre-treatment and post-treatment coefficients
  coef_names <- names(coef(es_base))
  pre_idx <- grep("::-[0-9]+:", coef_names)
  post_idx <- grep("::[0-9]+:", coef_names)

  betahat <- coef(es_base)
  sigma <- vcov(es_base)

  # HonestDiD requires the event study coefficients
  # l_vec = vector picking out the post-treatment coefficient of interest
  # We want to create bounds on the ATT

  honest_result <- HonestDiD::createSensitivityResults(
    betahat = betahat,
    sigma = sigma,
    numPrePeriods = length(pre_idx),
    numPostPeriods = length(post_idx),
    Mvec = seq(0, 0.05, by = 0.01)
  )

  cat("HonestDiD sensitivity results:\n")
  print(honest_result)
  saveRDS(honest_result, "../data/honestdid_results.rds")

}, error = function(e) {
  cat("HonestDiD error:", conditionMessage(e), "\n")
  cat("Proceeding without HonestDiD bounds.\n")
})

# =============================================================================
# 6. MUNICIPALITY SIZE HETEROGENEITY
# =============================================================================

cat("\n=== SIZE HETEROGENEITY ===\n")

# Compute pre-treatment median population
pre_median_pop <- panel |>
  filter(year < 2004) |>
  group_by(bfs_nr) |>
  summarize(median_pop = median(total_pop, na.rm = TRUE)) |>
  mutate(large = as.integer(median_pop > median(median_pop)))

panel <- panel |> left_join(pre_median_pop, by = "bfs_nr")

m_small <- feols(nat_rate ~ ballot:post | bfs_nr + year + canton_abbr[year],
                 data = panel |> filter(large == 0), cluster = ~canton_abbr)
m_large <- feols(nat_rate ~ ballot:post | bfs_nr + year + canton_abbr[year],
                 data = panel |> filter(large == 1), cluster = ~canton_abbr)

cat("Small municipalities (<median pop):\n")
summary(m_small)
cat("\nLarge municipalities (>median pop):\n")
summary(m_large)

# =============================================================================
# 7. POPULATION-WEIGHTED REGRESSION
# =============================================================================

cat("\n=== POPULATION-WEIGHTED ===\n")

m_weighted <- feols(nat_rate ~ ballot:post | bfs_nr + year + canton_abbr[year],
                    data = panel, weights = ~total_pop, cluster = ~canton_abbr)

cat("Population-weighted results:\n")
summary(m_weighted)

# =============================================================================
# 8. WINSORIZE OUTLIERS
# =============================================================================

cat("\n=== WINSORIZED (1st/99th percentile) ===\n")

p01 <- quantile(panel$nat_rate, 0.01, na.rm = TRUE)
p99 <- quantile(panel$nat_rate, 0.99, na.rm = TRUE)

panel_wins <- panel |>
  mutate(nat_rate_w = pmin(pmax(nat_rate, p01), p99))

m_wins <- feols(nat_rate_w ~ ballot:post | bfs_nr + year + canton_abbr[year],
                data = panel_wins, cluster = ~canton_abbr)

cat("Winsorized results:\n")
summary(m_wins)

# Save all robustness results
saveRDS(list(
  placebo_fpop = m_placebo_fpop,
  placebo_pop = m_placebo_pop,
  full_sample = m_full,
  full_trends = m_full_trends,
  small = m_small,
  large = m_large,
  weighted = m_weighted,
  winsorized = m_wins
), "../data/robustness_results.rds")

cat("\n04_robustness.R complete.\n")
