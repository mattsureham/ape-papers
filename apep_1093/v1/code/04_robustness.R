# 04_robustness.R — Robustness checks and event study
# Pay Transparency Laws and the Racial New-Hire Earnings Gap

source("00_packages.R")

# ---- Load data ----
df_gap <- readRDS("../data/qwi_gap.rds")
df <- readRDS("../data/qwi_clean.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ====================================================================
# 1. Event Study — leads and lags for parallel trends
# ====================================================================

cat("--- 1. Event study on B-W gap ---\n")

# Create event time variable (quarters relative to adoption)
df_gap_es <- df_gap %>%
  filter(treated_state == 1 | treated_state == 0) %>%
  mutate(
    event_time = case_when(
      treated_state == 0 ~ -1000L,  # never-treated placeholder
      TRUE ~ time_index - first_treat
    )
  ) %>%
  filter(treated_state == 0 | (event_time >= -8 & event_time <= 8))

# Bin endpoints
df_gap_es <- df_gap_es %>%
  mutate(
    event_time_binned = case_when(
      treated_state == 0 ~ NA_integer_,
      event_time <= -8 ~ -8L,
      event_time >= 8 ~ 8L,
      TRUE ~ event_time
    )
  )

# Event study using fixest::sunab-style manual leads/lags
# Reference period: event_time = -1
m_es <- feols(
  bw_gap ~ i(event_time_binned, ref = -1) |
    panel_id + time_index,
  data = df_gap_es %>% filter(treated_state == 1),
  cluster = ~state_fips
)

cat("\nEvent study coefficients:\n")
print(summary(m_es))

# Save event study for plotting
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$event_time <- as.integer(gsub("event_time_binned::", "", rownames(es_coefs)))
saveRDS(es_coefs, "../data/event_study_coefs.rds")
saveRDS(m_es, "../data/event_study_model.rds")

# ====================================================================
# 2. Wild cluster bootstrap (few treated clusters)
# ====================================================================

cat("\n--- 2. Wild cluster bootstrap ---\n")

results <- readRDS("../data/main_results.rds")

# Wild bootstrap the main gap DiD
tryCatch({
  boot_gap <- boottest(
    results$m3_gap_did,
    param = "treated_state:post",
    B = 999,
    clustid = ~state_fips,
    type = "webb"
  )
  cat("Wild cluster bootstrap p-value (gap DiD):", boot_gap$p_val, "\n")
  cat("95% CI:", boot_gap$conf_int, "\n")
  saveRDS(boot_gap, "../data/boot_gap_did.rds")
}, error = function(e) {
  cat("Wild bootstrap error:", e$message, "\n")
  cat("Falling back to standard clustered SEs.\n")
})

# ====================================================================
# 3. Drop Colorado (earliest adopter)
# ====================================================================

cat("\n--- 3. Drop Colorado ---\n")

df_gap_noco <- df_gap %>% filter(state_fips != "08")

m_noco <- feols(
  bw_gap ~ treated_state:post |
    panel_id + time_index,
  data = df_gap_noco,
  cluster = ~state_fips
)
cat("Gap DiD without Colorado:\n")
print(summary(m_noco))

# ====================================================================
# 4. Never-treated controls only
# ====================================================================

cat("\n--- 4. Never-treated controls only ---\n")

# Keep only CO (earliest, longest post) + never-treated
df_gap_nt <- df_gap %>%
  filter(treated_state == 0 |
    (treated_state == 1 & state_fips == "08"))

m_nt <- feols(
  bw_gap ~ treated_state:post |
    panel_id + time_index,
  data = df_gap_nt,
  cluster = ~state_fips
)
cat("Gap DiD (CO vs never-treated only):\n")
print(summary(m_nt))

# ====================================================================
# 5. Placebo: use separations instead of new-hire earnings
# ====================================================================

cat("\n--- 5. Placebo: separations ---\n")

df_gap_sep <- df %>%
  filter(!is.na(Sep) & Sep > 0) %>%
  select(county_fips, state_fips, industry, high_dispersion, year, quarter,
         time_index, yq, race, Sep, treated_state, post, first_treat) %>%
  pivot_wider(
    id_cols = c(county_fips, state_fips, industry, high_dispersion, year,
                quarter, time_index, yq, treated_state, post, first_treat),
    names_from = race,
    values_from = Sep,
    names_prefix = "Sep_"
  ) %>%
  filter(!is.na(Sep_Black) & !is.na(Sep_White) & Sep_Black > 0 & Sep_White > 0) %>%
  mutate(
    bw_sep_gap = log(Sep_Black) - log(Sep_White),
    panel_id = paste(county_fips, industry, sep = "_")
  )

m_sep_placebo <- feols(
  bw_sep_gap ~ treated_state:post |
    panel_id + time_index,
  data = df_gap_sep,
  cluster = ~state_fips
)
cat("Separation gap (placebo):\n")
print(summary(m_sep_placebo))

# ====================================================================
# 6. Industry-specific effects
# ====================================================================

cat("\n--- 6. Industry-specific DiD on B-W gap ---\n")

industries <- unique(df_gap$industry)
industry_results <- list()

for (ind in industries) {
  df_ind <- df_gap %>% filter(industry == ind)
  if (nrow(df_ind) < 100) next
  m_ind <- tryCatch(
    feols(bw_gap ~ treated_state:post | panel_id + time_index,
          data = df_ind, cluster = ~state_fips),
    error = function(e) NULL
  )
  if (!is.null(m_ind)) {
    industry_results[[ind]] <- m_ind
    cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.4f\n",
        ind, coef(m_ind), se(m_ind), pvalue(m_ind)))
  }
}

saveRDS(industry_results, "../data/industry_results.rds")

# ====================================================================
# Save all robustness results
# ====================================================================

robust_results <- list(
  event_study = m_es,
  no_colorado = m_noco,
  never_treated = m_nt,
  sep_placebo = m_sep_placebo,
  industry = industry_results
)
saveRDS(robust_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
