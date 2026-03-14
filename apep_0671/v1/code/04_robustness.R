# =============================================================================
# 04_robustness.R — Robustness checks and heterogeneity
# =============================================================================

source("00_packages.R")

main <- fread("../data/analysis_main.csv")

cat(sprintf("Main panel: %s obs\n", format(nrow(main), big.mark=",")))

# ─────────────────────────────────────────────────────────────────────────────
# Heterogeneity by initial skill level
# ─────────────────────────────────────────────────────────────────────────────

m_low <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
               data = main[skill_group == "low_skill"], cluster = ~county_id)

m_mid <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
               data = main[skill_group == "mid_skill"], cluster = ~county_id)

m_high <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                data = main[skill_group == "high_skill"], cluster = ~county_id)

cat("\n=== HETEROGENEITY BY SKILL ===\n")
etable(m_low, m_mid, m_high, se = "cluster",
       headers = c("Low-Skill", "Mid-Skill", "High-Skill"))

# ─────────────────────────────────────────────────────────────────────────────
# Heterogeneity by race
# ─────────────────────────────────────────────────────────────────────────────

m_white <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + literate | statefip_1920 + occ1950_1920,
                 data = main[white == 1], cluster = ~county_id)

m_nonwhite <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + literate | statefip_1920 + occ1950_1920,
                    data = main[white == 0], cluster = ~county_id)

cat("\n=== HETEROGENEITY BY RACE ===\n")
etable(m_white, m_nonwhite, se = "cluster", headers = c("White", "Non-White"))

# ─────────────────────────────────────────────────────────────────────────────
# Upgrading by skill group
# ─────────────────────────────────────────────────────────────────────────────

m_up_low <- feols(upgraded ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                  data = main[skill_group == "low_skill"], cluster = ~county_id)

m_up_mid <- feols(upgraded ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                  data = main[skill_group == "mid_skill"], cluster = ~county_id)

m_up_high <- feols(upgraded ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                   data = main[skill_group == "high_skill"], cluster = ~county_id)

cat("\n=== UPGRADING BY SKILL GROUP ===\n")
etable(m_up_low, m_up_mid, m_up_high, se = "cluster")

# ─────────────────────────────────────────────────────────────────────────────
# Trimmed exposure (5-95%)
# ─────────────────────────────────────────────────────────────────────────────

p5 <- quantile(main$restricted_share, 0.05)
p95 <- quantile(main$restricted_share, 0.95)

m_trimmed <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                   data = main[restricted_share >= p5 & restricted_share <= p95],
                   cluster = ~county_id)

cat("\n=== TRIMMED EXPOSURE (5-95%) ===\n")
etable(m_trimmed, se = "cluster")

# ─────────────────────────────────────────────────────────────────────────────
# State-level clustering
# ─────────────────────────────────────────────────────────────────────────────

m_state_cluster <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                         data = main, cluster = ~statefip_1920)

cat("\n=== STATE-LEVEL CLUSTERING ===\n")
etable(m_state_cluster, se = "cluster")

# ─────────────────────────────────────────────────────────────────────────────
# Population-weighted
# ─────────────────────────────────────────────────────────────────────────────

m_weighted <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                    data = main, weights = ~total_pop, cluster = ~county_id)

cat("\n=== POPULATION-WEIGHTED ===\n")
etable(m_weighted, se = "cluster")

# ─────────────────────────────────────────────────────────────────────────────
# Age subgroups
# ─────────────────────────────────────────────────────────────────────────────

m_young <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                 data = main[age_1920 <= 30], cluster = ~county_id)

m_prime <- feols(d_occscore ~ restricted_share + age_1920 + I(age_1920^2) + white + literate | statefip_1920 + occ1950_1920,
                 data = main[age_1920 > 30], cluster = ~county_id)

cat("\n=== BY AGE GROUP ===\n")
etable(m_young, m_prime, se = "cluster", headers = c("Young (18-30)", "Prime (31-55)"))

# ─────────────────────────────────────────────────────────────────────────────
# Save
# ─────────────────────────────────────────────────────────────────────────────

robustness <- list(
  by_skill = list(low = m_low, mid = m_mid, high = m_high),
  by_race = list(white = m_white, nonwhite = m_nonwhite),
  by_skill_upgrade = list(low = m_up_low, mid = m_up_mid, high = m_up_high),
  trimmed = m_trimmed,
  state_cluster = m_state_cluster,
  weighted = m_weighted,
  by_age = list(young = m_young, prime = m_prime)
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
