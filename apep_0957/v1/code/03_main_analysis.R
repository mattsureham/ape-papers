## 03_main_analysis.R — Triple-difference DiD analysis
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
cat(sprintf("Analysis panel: %d rows\n", nrow(df)))

# Ensure numeric treatment indicators
df <- df %>%
  mutate(
    has_eitc = as.integer(has_eitc),
    naics56 = as.integer(naics56),
    hispanic = as.integer(hispanic)
  )

# ============================================================================
# A) TWFE Triple-Difference (baseline specification)
# ============================================================================
cat("\n=== A) TWFE Triple-Difference ===\n")

# Full triple-diff with high-dimensional FEs
m1 <- feols(
  ln_emp ~ has_eitc:naics56:hispanic +
    has_eitc:naics56 + has_eitc:hispanic + naics56:hispanic |
    state_fips^year + ind_2d^year + state_fips^ind_2d^ethnicity,
  data = df,
  cluster = ~state_fips
)
cat("Model 1 (TWFE triple-diff, ln_emp):\n")
summary(m1)

# Hiring
m2 <- feols(
  ln_hire ~ has_eitc:naics56:hispanic +
    has_eitc:naics56 + has_eitc:hispanic + naics56:hispanic |
    state_fips^year + ind_2d^year + state_fips^ind_2d^ethnicity,
  data = df,
  cluster = ~state_fips
)
cat("\nModel 2 (TWFE triple-diff, ln_hire):\n")
summary(m2)

# Separations
m3 <- feols(
  ln_sep ~ has_eitc:naics56:hispanic +
    has_eitc:naics56 + has_eitc:hispanic + naics56:hispanic |
    state_fips^year + ind_2d^year + state_fips^ind_2d^ethnicity,
  data = df,
  cluster = ~state_fips
)
cat("\nModel 3 (TWFE triple-diff, ln_sep):\n")
summary(m3)

# Earnings — only for states/cells with nonmissing ln_earn
df_earn <- df %>% filter(!is.na(ln_earn) & is.finite(ln_earn))
cat(sprintf("\nEarnings sample: %d rows (%.1f%% of full panel)\n",
            nrow(df_earn), 100 * nrow(df_earn) / nrow(df)))

if (nrow(df_earn) > 1000 & length(unique(df_earn$ln_earn)) > 1) {
  m4 <- feols(
    ln_earn ~ has_eitc:naics56:hispanic +
      has_eitc:naics56 + has_eitc:hispanic + naics56:hispanic |
      state_fips^year + ind_2d^year + state_fips^ind_2d^ethnicity,
    data = df_earn,
    cluster = ~state_fips
  )
  cat("Model 4 (TWFE triple-diff, ln_earn):\n")
  summary(m4)
} else {
  cat("Insufficient earnings data — skipping earnings regression.\n")
  m4 <- NULL
}

# ============================================================================
# B) Callaway-Sant'Anna on the Hispanic × NAICS 56 cell
# ============================================================================
cat("\n=== B) Callaway-Sant'Anna (Hispanic × NAICS 56) ===\n")

cs_data <- df %>%
  filter(hispanic == 1 & naics56 == 1) %>%
  mutate(
    first_treat_cs = case_when(
      first_treat == 0 ~ 0L,
      first_treat < 2000 ~ 0L,     # Pre-period adopters treated as always-treated
      TRUE ~ as.integer(first_treat)
    )
  )

cat(sprintf("CS data: %d state-years, %d states\n", nrow(cs_data), n_distinct(cs_data$state_fips)))
cat(sprintf("CS treated groups (post-2000 adopters): %d\n",
            n_distinct(cs_data$state_fips[cs_data$first_treat_cs > 0])))
cat(sprintf("CS never-treated (+ pre-2000): %d\n",
            n_distinct(cs_data$state_fips[cs_data$first_treat_cs == 0])))

cs_out <- att_gt(
  yname = "ln_emp",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat_cs",
  data = cs_data,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cat("\nCS group-time ATTs:\n")
summary(cs_out)

cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS simple ATT:\n")
summary(cs_agg)

cs_es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 10)
cat("\nCS event study:\n")
summary(cs_es)

# ============================================================================
# C) Within NAICS 56: Hispanic vs non-Hispanic DiD
# ============================================================================
cat("\n=== C) Within NAICS-56 DiD (Hispanic vs Non-Hispanic) ===\n")

naics56_data <- df %>%
  filter(naics56 == 1) %>%
  mutate(treat_cell = has_eitc * hispanic)

m5 <- feols(
  ln_emp ~ treat_cell + has_eitc + hispanic |
    state_fips^year + ethnicity^year,
  data = naics56_data,
  cluster = ~state_fips
)
cat("Model 5 (within-NAICS56 DiD):\n")
summary(m5)

# ============================================================================
# D) Placebo: Non-Hispanic workers in NAICS 56
# ============================================================================
cat("\n=== D) Placebo: Non-Hispanic only in NAICS 56 ===\n")

placebo_data <- df %>%
  filter(hispanic == 0 & naics56 == 1) %>%
  mutate(
    first_treat_cs = case_when(
      first_treat == 0 ~ 0L,
      first_treat < 2000 ~ 0L,
      TRUE ~ as.integer(first_treat)
    )
  )

cs_placebo <- att_gt(
  yname = "ln_emp",
  tname = "year",
  idname = "state_fips",
  gname = "first_treat_cs",
  data = placebo_data,
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cs_placebo_agg <- aggte(cs_placebo, type = "simple")
cat("Placebo (non-Hispanic, NAICS 56) simple ATT:\n")
summary(cs_placebo_agg)

# ============================================================================
# Save results
# ============================================================================

results <- list(
  twfe_emp  = m1,
  twfe_hire = m2,
  twfe_sep  = m3,
  twfe_earn = m4,
  cs_out    = cs_out,
  cs_agg    = cs_agg,
  cs_es     = cs_es,
  within56  = m5,
  placebo   = cs_placebo_agg
)
saveRDS(results, "../data/main_results.rds")

# --- Diagnostics JSON for validator ---
n_treated_states <- n_distinct(df$state_fips[df$first_treat > 0 & df$first_treat >= 2000])
# For pre-periods, use the median adoption year among post-2000 adopters
median_eitc_year <- median(df$eitc_year[df$eitc_year >= 2000], na.rm = TRUE)
n_pre <- length(unique(df$year[df$year < median_eitc_year]))
diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = nrow(df)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("=== Main analysis complete ===\n")
