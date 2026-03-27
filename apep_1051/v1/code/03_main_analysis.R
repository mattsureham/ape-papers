# 03_main_analysis.R — Main econometric analysis
# apep_1051: CRP Cap Reduction and Land-Use Transitions

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "obs,", n_distinct(panel$fips), "counties\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Pre obs:", sum(panel$year < 2014), "| Post:", sum(panel$year >= 2014), "\n")

# ============================================================
# 1. SUMMARY STATISTICS
# ============================================================

# Pre-treatment summary (2006-2013)
pre <- panel %>% filter(year < 2014)

cat("\n=== PRE-TREATMENT SUMMARY (2006-2013) ===\n")
cat("Total planted acres: mean =", round(mean(pre$total_planted)), ", sd =",
    round(sd(pre$total_planted)), "\n")
cat("Corn: mean =", round(mean(pre$corn)), ", sd =", round(sd(pre$corn)), "\n")
cat("Soybeans: mean =", round(mean(pre$soybeans)), ", sd =", round(sd(pre$soybeans)), "\n")
cat("Wheat: mean =", round(mean(pre$wheat)), ", sd =", round(sd(pre$wheat)), "\n")
cat("Treatment intensity: mean =", round(mean(pre$treatment), 4),
    ", sd =", round(sd(pre$treatment), 4), "\n")

# ============================================================
# 2. MAIN SPECIFICATION — Continuous-treatment DiD
# ============================================================

# Y_ct = alpha_c + gamma_st + beta * (CRP_loss_share_c * Post_t) + epsilon_ct
# Outcome: total planted crop acres (corn + soybeans + wheat)
# Treatment: CRP loss as share of total cropland (continuous)
# FEs: county + state*year

cat("\n=== MAIN RESULTS ===\n")

# Specification 1: County FE + Year FE
m1 <- feols(total_planted ~ treat_x_post | fips + year,
            data = panel, cluster = "state_fips")

# Specification 2: County FE + State-Year FE (preferred)
m2 <- feols(total_planted ~ treat_x_post | fips + state_fips^year,
            data = panel, cluster = "state_fips")

# Specification 3: Planted share (normalized by total cropland)
m3 <- feols(planted_share ~ treat_x_post | fips + state_fips^year,
            data = panel, cluster = "state_fips")

# Specification 4: Log planted acres
m4 <- feols(ln_planted ~ treat_x_post | fips + state_fips^year,
            data = panel, cluster = "state_fips")

cat("Model 1 (County+Year FE): beta =", round(coef(m2)["treat_x_post"], 1),
    ", se =", round(sqrt(vcov(m2)["treat_x_post", "treat_x_post"]), 1), "\n")
cat("Model 2 (County+State*Year FE): beta =", round(coef(m2)["treat_x_post"], 1),
    ", se =", round(sqrt(vcov(m2)["treat_x_post", "treat_x_post"]), 1), "\n")

etable(m1, m2, m3, m4, headers = c("Levels", "State*Year", "Share", "Log"))

# ============================================================
# 3. EVENT STUDY — Dynamic effects
# ============================================================

cat("\n=== EVENT STUDY ===\n")

# Create event-time indicators (relative to 2014)
panel <- panel %>%
  mutate(
    event_time = year - 2014,
    # Bin at endpoints
    event_time_binned = case_when(
      event_time <= -5 ~ -5L,
      event_time >= 8 ~ 8L,
      TRUE ~ as.integer(event_time)
    )
  )

# Event study: interact treatment intensity with event-time dummies
# Base period: t = -1 (year 2013)
es <- feols(total_planted ~ i(event_time_binned, treatment, ref = -1) |
              fips + state_fips^year,
            data = panel, cluster = "state_fips")

cat("Event study coefficients:\n")
print(summary(es))

# ============================================================
# 4. INDIVIDUAL CROP OUTCOMES
# ============================================================

cat("\n=== CROP-SPECIFIC RESULTS ===\n")

m_corn <- feols(corn ~ treat_x_post | fips + state_fips^year,
                data = panel, cluster = "state_fips")

m_soy <- feols(soybeans ~ treat_x_post | fips + state_fips^year,
               data = panel, cluster = "state_fips")

m_wheat <- feols(wheat ~ treat_x_post | fips + state_fips^year,
                 data = panel, cluster = "state_fips")

m_hay <- feols(hay ~ treat_x_post | fips + state_fips^year,
               data = panel, cluster = "state_fips")

etable(m_corn, m_soy, m_wheat, m_hay,
       headers = c("Corn", "Soybeans", "Wheat", "Hay"))

# ============================================================
# 5. SAVE RESULTS
# ============================================================

results <- list(
  main = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
  event_study = es,
  crops = list(corn = m_corn, soy = m_soy, wheat = m_wheat, hay = m_hay),
  panel = panel
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Diagnostics for validator
diagnostics <- list(
  n_treated = n_distinct(panel$fips[panel$treatment > median(panel$treatment[panel$treatment > 0])]),
  n_pre = length(unique(panel$year[panel$year < 2014])),
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$fips),
  n_states = n_distinct(panel$state_fips)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nDiagnostics:\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")
cat("  n_counties:", diagnostics$n_counties, "\n")
cat("  n_states:", diagnostics$n_states, "\n")
