# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# apep_1070: H-2A Guestworker Expansion and Farm Worker Displacement
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
placebo_df <- readRDS("../data/placebo_panel.rds")

# ---------------------------------------------------------------------------
# 1. Placebo industries: Construction (23) and Food Service (72)
# ---------------------------------------------------------------------------
# These industries employ many Hispanic workers but are NOT served by H-2A.
# If our DDD captures a real H-2A effect (not a general Hispanic labor trend),
# we should see null effects in these industries.

cat("=== PLACEBO: CONSTRUCTION (NAICS 23) ===\n")

placebo_23 <- placebo_df %>%
  filter(industry == "23" & !is.na(emp) & emp > 0)

m_placebo_23 <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = placebo_23,
  cluster = ~county_fips
)
summary(m_placebo_23)

cat("\n=== PLACEBO: FOOD SERVICE (NAICS 72) ===\n")

placebo_72 <- placebo_df %>%
  filter(industry == "72" & !is.na(emp) & emp > 0)

m_placebo_72 <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = placebo_72,
  cluster = ~county_fips
)
summary(m_placebo_72)

# ---------------------------------------------------------------------------
# 2. Leave-one-state-out (LOSO) robustness
# ---------------------------------------------------------------------------
cat("\n=== LEAVE-ONE-STATE-OUT ===\n")

df_emp <- df %>% filter(!is.na(emp) & emp > 0)

top_states <- df_emp %>%
  filter(hispanic == 1) %>%
  group_by(state_fips) %>%
  summarise(total_h2a = sum(h2a_positions)) %>%
  arrange(desc(total_h2a)) %>%
  head(5) %>%
  pull(state_fips)

loso_results <- list()
for (st in top_states) {
  m_loso <- feols(
    log(emp) ~ ln_h2a:i(hispanic) |
      county_eth + quarter_eth + state_quarter,
    data = df_emp %>% filter(state_fips != st),
    cluster = ~county_fips
  )
  coef_val <- coef(m_loso)["ln_h2a:hispanic::1"]
  se_val <- sqrt(vcov(m_loso)["ln_h2a:hispanic::1", "ln_h2a:hispanic::1"])
  loso_results[[st]] <- data.frame(
    state_dropped = st,
    coef = coef_val,
    se = se_val,
    stringsAsFactors = FALSE
  )
  cat(sprintf("  Drop state %s: β = %.4f (SE = %.4f)\n", st, coef_val, se_val))
}

loso_df <- bind_rows(loso_results)

# ---------------------------------------------------------------------------
# 3. Alternative clustering: state level
# ---------------------------------------------------------------------------
cat("\n=== ALTERNATIVE CLUSTERING: STATE ===\n")

m_state_cluster <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_emp,
  cluster = ~state_fips
)
summary(m_state_cluster)

# ---------------------------------------------------------------------------
# 4. Levels specification (not logs)
# ---------------------------------------------------------------------------
cat("\n=== LEVELS SPECIFICATION ===\n")

m_levels <- feols(
  emp ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_emp,
  cluster = ~county_fips
)
summary(m_levels)

# ---------------------------------------------------------------------------
# 5. Excluding COVID period (2020-2021)
# ---------------------------------------------------------------------------
cat("\n=== EXCLUDING COVID (2020-2021) ===\n")

m_no_covid <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_emp %>% filter(!(year %in% c(2020, 2021))),
  cluster = ~county_fips
)
summary(m_no_covid)

# ---------------------------------------------------------------------------
# Save all robustness results
# ---------------------------------------------------------------------------
results_robust <- list(
  placebo_23 = m_placebo_23,
  placebo_72 = m_placebo_72,
  loso = loso_df,
  state_cluster = m_state_cluster,
  levels = m_levels,
  no_covid = m_no_covid
)

saveRDS(results_robust, "../data/results_robustness.rds")
cat("\nRobustness checks complete.\n")
