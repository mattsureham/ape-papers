# =============================================================================
# 03_main_analysis.R — DDD estimation for apep_0779
# =============================================================================

source("00_packages.R")
library(fixest)
library(dplyr)

cat("Loading analysis panel...\n")
panel <- readRDS("../data/analysis_panel.rds")

cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("N states:", length(unique(panel$state_fips)), "\n")

# -------------------------------------------------------------------------
# Main DDD specification
# -------------------------------------------------------------------------
# Y ~ female x young x post_treat | state^sex^agegrp + sex^agegrp^t_int + state^t_int
# Cluster at state level

cat("\n=== Main DDD Results ===\n")

# (1) Separation rate
cat("\n--- Separation Rate ---\n")
m1_sep <- feols(
  sep_rate ~ ddd + female_post + young_post + female_young |
    state_fips^sex^agegrp + sex^agegrp^t_int + state_fips^t_int,
  data = panel,
  cluster = ~state_fips
)
cat("DDD coefficient (sep_rate):", coef(m1_sep)["ddd"], "\n")
cat("SE:", se(m1_sep)["ddd"], "\n")
cat("p-value:", pvalue(m1_sep)["ddd"], "\n")

# (2) Hire rate
cat("\n--- Hire Rate ---\n")
m1_hir <- feols(
  hire_rate ~ ddd + female_post + young_post + female_young |
    state_fips^sex^agegrp + sex^agegrp^t_int + state_fips^t_int,
  data = panel,
  cluster = ~state_fips
)
cat("DDD coefficient (hire_rate):", coef(m1_hir)["ddd"], "\n")
cat("SE:", se(m1_hir)["ddd"], "\n")
cat("p-value:", pvalue(m1_hir)["ddd"], "\n")

# (3) Log employment
cat("\n--- Log Employment ---\n")
m1_emp <- feols(
  log_emp ~ ddd + female_post + young_post + female_young |
    state_fips^sex^agegrp + sex^agegrp^t_int + state_fips^t_int,
  data = panel,
  cluster = ~state_fips
)
cat("DDD coefficient (log_emp):", coef(m1_emp)["ddd"], "\n")
cat("SE:", se(m1_emp)["ddd"], "\n")
cat("p-value:", pvalue(m1_emp)["ddd"], "\n")

# (4) Log earnings
cat("\n--- Log Earnings ---\n")
m1_earn <- feols(
  log_earn ~ ddd + female_post + young_post + female_young |
    state_fips^sex^agegrp + sex^agegrp^t_int + state_fips^t_int,
  data = panel,
  cluster = ~state_fips
)
cat("DDD coefficient (log_earn):", coef(m1_earn)["ddd"], "\n")
cat("SE:", se(m1_earn)["ddd"], "\n")
cat("p-value:", pvalue(m1_earn)["ddd"], "\n")

# -------------------------------------------------------------------------
# Parsimonious specification (fewer FE for comparison)
# -------------------------------------------------------------------------
cat("\n=== Parsimonious DDD (state + quarter FE only) ===\n")

m2_sep <- feols(
  sep_rate ~ ddd + female_post + young_post + female_young +
    female + young + post_treat |
    state_fips + t_int,
  data = panel,
  cluster = ~state_fips
)
cat("DDD coefficient (sep_rate, parsimonious):", coef(m2_sep)["ddd"], "\n")

# -------------------------------------------------------------------------
# Save results
# -------------------------------------------------------------------------
cat("\n=== Saving Results ===\n")

# Save model objects
saveRDS(
  list(
    m1_sep = m1_sep,
    m1_hir = m1_hir,
    m1_emp = m1_emp,
    m1_earn = m1_earn,
    m2_sep = m2_sep
  ),
  "../data/main_models.rds"
)

# Write diagnostics.json
diagnostics <- list(
  paper_id = "apep_0779",
  n_obs = nrow(panel),
  n_states = length(unique(panel$state_fips)),
  n_treated_states = length(unique(panel$state_fips[panel$ever_treated == 1])),
  n_control_states = length(unique(panel$state_fips[panel$ever_treated == 0])),
  n_quarters = length(unique(panel$t_int)),
  year_range = paste(min(panel$year), max(panel$year), sep = "-"),
  main_results = list(
    sep_rate = list(
      beta = unname(coef(m1_sep)["ddd"]),
      se = unname(se(m1_sep)["ddd"]),
      pvalue = unname(pvalue(m1_sep)["ddd"]),
      r2_within = summary(m1_sep)$r2
    ),
    hire_rate = list(
      beta = unname(coef(m1_hir)["ddd"]),
      se = unname(se(m1_hir)["ddd"]),
      pvalue = unname(pvalue(m1_hir)["ddd"])
    ),
    log_emp = list(
      beta = unname(coef(m1_emp)["ddd"]),
      se = unname(se(m1_emp)["ddd"]),
      pvalue = unname(pvalue(m1_emp)["ddd"])
    ),
    log_earn = list(
      beta = unname(coef(m1_earn)["ddd"]),
      se = unname(se(m1_earn)["ddd"]),
      pvalue = unname(pvalue(m1_earn)["ddd"])
    )
  )
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", pretty = TRUE, auto_unbox = TRUE)
cat("Saved diagnostics.json and main_models.rds\n")
cat("Done.\n")
