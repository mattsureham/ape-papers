# ==============================================================================
# 03_main_analysis.R — Main specifications
# Paper: The Admissions Illusion (apep_1113)
# ==============================================================================

source("00_packages.R")
df <- readRDS("../data/analysis_panel.rds")

# ==============================================================================
# SPECIFICATION 1: Continuous intensity DiD
# Y_it = α_i + γ_t + β(Intensity_i × Post_t) + ε_it
# ==============================================================================

cat("=== SPECIFICATION 1: Continuous Intensity DiD ===\n\n")

# Main outcomes: URM share, Black share, Hispanic share, Asian share, White share
outcomes <- c("urm_share", "black_share", "hispanic_share", "asian_share", "white_share")
outcome_labels <- c("URM Share", "Black Share", "Hispanic Share", "Asian Share", "White Share")

# Estimate for each outcome
models_main <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ intensity_x_post | unitid + year"))
  models_main[[y]] <- feols(fml, data = df, cluster = ~state)
  cat(sprintf("%s: β = %.3f (SE = %.3f), p = %.4f\n",
      outcome_labels[i],
      coef(models_main[[y]])[1],
      se(models_main[[y]])[1],
      pvalue(models_main[[y]])[1]))
}

# ==============================================================================
# SPECIFICATION 2: Event study with intensity interaction
# Y_it = α_i + Σ_k β_k (Intensity_i × 1{t=k}) + ε_it
# Reference year: 2022 (last pre-SFFA year)
# ==============================================================================

cat("\n=== SPECIFICATION 2: Event Study ===\n\n")

df <- df %>%
  mutate(rel_year = year - 2023)  # Center at SFFA decision year

# URM share event study
es_urm <- feols(urm_share ~ i(rel_year, intensity, ref = -1) | unitid + year,
                data = df, cluster = ~state)

cat("Event study coefficients (URM share):\n")
print(summary(es_urm))

# Black share event study
es_black <- feols(black_share ~ i(rel_year, intensity, ref = -1) | unitid + year,
                  data = df, cluster = ~state)

# Hispanic share event study
es_hisp <- feols(hispanic_share ~ i(rel_year, intensity, ref = -1) | unitid + year,
                 data = df, cluster = ~state)

# Asian share event study
es_asian <- feols(asian_share ~ i(rel_year, intensity, ref = -1) | unitid + year,
                  data = df, cluster = ~state)

# White share event study
es_white <- feols(white_share ~ i(rel_year, intensity, ref = -1) | unitid + year,
                  data = df, cluster = ~state)

# ==============================================================================
# SPECIFICATION 3: Triple-difference (selectivity × post × URM)
# Reshape to race-level panel
# ==============================================================================

cat("\n=== SPECIFICATION 3: Triple-Difference ===\n\n")

# Create race-level panel: URM vs non-URM shares
df_race <- df %>%
  select(unitid, year, state, intensity, post, selectivity_tier,
         prior_ban, is_hbcu, is_public, total_enroll,
         black_share, hispanic_share, asian_share, white_share, urm_share) %>%
  pivot_longer(
    cols = c(urm_share, white_share),
    names_to = "race_group",
    values_to = "share"
  ) %>%
  mutate(
    is_urm = as.integer(race_group == "urm_share"),
    intensity_x_post_x_urm = intensity * post * is_urm,
    intensity_x_post = intensity * post,
    intensity_x_urm = intensity * is_urm,
    post_x_urm = post * is_urm
  )

# DDD: intensity × post × URM
ddd_model <- feols(share ~ intensity_x_post_x_urm + intensity_x_post +
                     post_x_urm + intensity_x_urm | unitid^is_urm + year^is_urm,
                   data = df_race, cluster = ~state)

cat("DDD (Intensity × Post × URM):\n")
print(summary(ddd_model))

# ==============================================================================
# SPECIFICATION 4: By selectivity tier
# ==============================================================================

cat("\n=== SPECIFICATION 4: By Selectivity Tier ===\n\n")

models_tier <- list()
for (tier in levels(df$selectivity_tier)) {
  sub <- df %>% filter(selectivity_tier == tier)
  if (n_distinct(sub$unitid) < 10) next
  # Use intensity × post within tier (post alone is collinear with year FE)
  m <- feols(urm_share ~ intensity_x_post | unitid + year, data = sub, cluster = ~state)
  models_tier[[tier]] <- m
  cat(sprintf("%s (N=%d): β = %.3f (SE = %.3f)\n",
      tier, n_distinct(sub$unitid), coef(m)[1], se(m)[1]))
}

# ==============================================================================
# Save results
# ==============================================================================

results <- list(
  models_main = models_main,
  es_urm = es_urm,
  es_black = es_black,
  es_hisp = es_hisp,
  es_asian = es_asian,
  es_white = es_white,
  ddd_model = ddd_model,
  models_tier = models_tier
)
saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validator
n_post_states <- n_distinct(df$state[df$year == 2024])
n_pre <- length(unique(df$year[df$year < 2024]))

diagnostics <- list(
  n_treated = n_distinct(df$unitid[df$intensity > median(df$intensity)]),
  n_pre = n_pre,
  n_obs = nrow(df)
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
    diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("Main analysis complete.\n")
