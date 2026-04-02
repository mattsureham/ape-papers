## 04_robustness.R — Robustness checks
## APEP apep_1331: The No-Advice Trap

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================
# 1. Exclude COVID quarters (Q1-Q2 2020 calendar = FY Q4 2019/20 - Q1 2020/21)
# COVID lockdowns disrupted FOS operations starting March 2020
# ============================================================

cat("--- R1: Excluding COVID quarters ---\n")
panel_nocovid <- panel %>%
  filter(!(time_index >= 2020.0 & time_index <= 2020.5))

m_nocovid_level <- feols(new_complaints ~ did | product_category + time_index,
                         data = panel_nocovid)
m_nocovid_uphold <- feols(uphold_rate ~ did | product_category + time_index,
                          data = panel_nocovid %>% filter(!is.na(uphold_rate)))

cat("Level (excl. COVID):\n")
print(summary(m_nocovid_level))
cat("Uphold rate (excl. COVID):\n")
print(summary(m_nocovid_uphold))

# ============================================================
# 2. Each control separately
# ============================================================

cat("\n--- R2: Pairwise DiD (each control separately) ---\n")

controls <- c("Annuities", "Personal Pensions", "SIPP")
pairwise_results <- list()

for (ctrl in controls) {
  pair_data <- panel %>%
    filter(product_category %in% c("DB Transfer", ctrl))

  m_pair <- feols(new_complaints ~ did | product_category + time_index,
                  data = pair_data)
  m_pair_uph <- feols(uphold_rate ~ did | product_category + time_index,
                      data = pair_data %>% filter(!is.na(uphold_rate)))

  pairwise_results[[ctrl]] <- list(
    level = m_pair,
    uphold = m_pair_uph
  )

  cat(sprintf("\nDB Transfer vs %s:\n", ctrl))
  cat(sprintf("  Level: beta=%.1f, SE=%.1f, p=%.3f\n",
              coef(m_pair)["did"],
              sqrt(diag(vcov(m_pair)))["did"],
              pvalue(m_pair)["did"]))
  cat(sprintf("  Uphold: beta=%.3f, SE=%.3f, p=%.3f\n",
              coef(m_pair_uph)["did"],
              sqrt(diag(vcov(m_pair_uph)))["did"],
              pvalue(m_pair_uph)["did"]))
}

# ============================================================
# 3. Placebo: Annuities as "treated" (should show no effect)
# ============================================================

cat("\n--- R3: Placebo test (Annuities as pseudo-treated) ---\n")
panel_placebo <- panel %>%
  filter(product_category %in% c("Annuities", "Personal Pensions", "SIPP")) %>%
  mutate(
    placebo_treated = as.integer(product_category == "Annuities"),
    placebo_did = placebo_treated * post
  )

m_placebo <- feols(uphold_rate ~ placebo_did | product_category + time_index,
                   data = panel_placebo %>% filter(!is.na(uphold_rate)))

cat("Placebo (Annuities as treated):\n")
cat(sprintf("  Uphold: beta=%.3f, SE=%.3f, p=%.3f\n",
            coef(m_placebo)["placebo_did"],
            sqrt(diag(vcov(m_placebo)))["placebo_did"],
            pvalue(m_placebo)["placebo_did"]))

# ============================================================
# 4. Pre-post comparison for treated product only
# ============================================================

cat("\n--- R4: Pre-post for DB Transfer only ---\n")
db_only <- panel %>% filter(product_category == "DB Transfer")
m_prepost <- lm(new_complaints ~ post, data = db_only)
m_prepost_uph <- lm(uphold_rate ~ post, data = db_only %>% filter(!is.na(uphold_rate)))

cat("DB Transfer pre-post (no controls):\n")
cat(sprintf("  Level: beta=%.1f, SE=%.1f, p=%.3f\n",
            coef(m_prepost)["post"],
            summary(m_prepost)$coefficients["post", "Std. Error"],
            summary(m_prepost)$coefficients["post", "Pr(>|t|)"]))
cat(sprintf("  Uphold: beta=%.3f, SE=%.3f, p=%.3f\n",
            coef(m_prepost_uph)["post"],
            summary(m_prepost_uph)$coefficients["post", "Std. Error"],
            summary(m_prepost_uph)$coefficients["post", "Pr(>|t|)"]))

# ============================================================
# 5. Event study for uphold rate (main interest)
# ============================================================

cat("\n--- R5: Event study (uphold rate) ---\n")

panel_uph <- panel %>%
  filter(!is.na(uphold_rate)) %>%
  mutate(
    event_time = round((time_index - 2020.75) * 4),
    event_time_bin = case_when(
      event_time <= -8 ~ -8L,
      event_time >= 8 ~ 8L,
      TRUE ~ as.integer(event_time)
    )
  )

m_es_uph <- feols(uphold_rate ~ i(event_time_bin, treated, ref = -1) |
                     product_category + time_index,
                   data = panel_uph)

cat("Uphold rate event study:\n")
print(summary(m_es_uph))

# ============================================================
# 6. Save robustness results
# ============================================================

rob_results <- list(
  nocovid_level = m_nocovid_level,
  nocovid_uphold = m_nocovid_uphold,
  pairwise = pairwise_results,
  placebo = m_placebo,
  prepost_level = m_prepost,
  prepost_uphold = m_prepost_uph,
  es_uphold = m_es_uph
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
