# =============================================================================
# 04_robustness.R — Robustness checks
# =============================================================================

source("00_packages.R")

analysis      <- readRDS("../data/analysis.rds")
analysis_long <- readRDS("../data/analysis_long.rds")
models        <- readRDS("../data/models.rds")

# ---------------------------------------------------------------------------
# 1. Conley SE check (wider clustering)
# ---------------------------------------------------------------------------
cat("--- Alternative clustering: state-year ---\n")
m1_alt <- feols(log_cc_total ~ log_displaced:post | county_fips + year,
                data = analysis,
                cluster = ~state_fips + year)
cat("State+Year clustered SE:\n")
print(summary(m1_alt))

# ---------------------------------------------------------------------------
# 2. Alternative treatment definition: top quartile of displacement
# ---------------------------------------------------------------------------
q75 <- quantile(analysis$closed_total[analysis$year == 2015 & analysis$closed_total > 0],
                0.75, na.rm = TRUE)

analysis <- analysis %>%
  mutate(high_exposure = as.integer(closed_total >= q75 & closed_total > 0))

m_high <- feols(log_cc_total ~ high_exposure:post | county_fips + year,
                data = analysis,
                cluster = ~state_fips)

m_high_black <- feols(log_cc_black ~ high_exposure:post | county_fips + year,
                      data = analysis,
                      cluster = ~state_fips)

cat("\n--- High-Exposure Counties ---\n")
etable(m_high, m_high_black,
       headers = c("Total", "Black"),
       se.below = TRUE)

# ---------------------------------------------------------------------------
# 3. Drop 2020+ (COVID contamination)
# ---------------------------------------------------------------------------
analysis_pre_covid <- analysis %>% filter(year <= 2019)

m_precov <- feols(log_cc_total ~ log_displaced:post | county_fips + year,
                  data = analysis_pre_covid,
                  cluster = ~state_fips)

m_precov_black <- feols(log_cc_black ~ log_displaced:post | county_fips + year,
                        data = analysis_pre_covid,
                        cluster = ~state_fips)

cat("\n--- Pre-COVID Sample (2010-2019) ---\n")
etable(m_precov, m_precov_black,
       headers = c("Total", "Black"),
       se.below = TRUE)

# ---------------------------------------------------------------------------
# 4. Levels specification (not logs)
# ---------------------------------------------------------------------------
m_levels <- feols(cc_total ~ log_displaced:post | county_fips + year,
                  data = analysis,
                  cluster = ~state_fips)

m_levels_black <- feols(cc_black ~ log_displaced:post | county_fips + year,
                        data = analysis,
                        cluster = ~state_fips)

cat("\n--- Levels Specification ---\n")
etable(m_levels, m_levels_black,
       headers = c("Total", "Black"),
       se.below = TRUE)

# ---------------------------------------------------------------------------
# 5. Leave-one-state-out
# ---------------------------------------------------------------------------
states <- unique(analysis$state_fips)
loso_coefs <- numeric(length(states))
names(loso_coefs) <- states

for (i in seq_along(states)) {
  df_loo <- analysis %>% filter(state_fips != states[i])
  m_loo <- feols(log_cc_total ~ log_displaced:post | county_fips + year,
                 data = df_loo,
                 cluster = ~state_fips)
  loso_coefs[i] <- coef(m_loo)["log_displaced:post"]
}

cat("\n--- Leave-One-State-Out ---\n")
cat("Mean coefficient:", mean(loso_coefs), "\n")
cat("Range:", range(loso_coefs), "\n")
cat("Full sample coef:", coef(models$m_total)["log_displaced:post"], "\n")

# ---------------------------------------------------------------------------
# 6. Save updated models
# ---------------------------------------------------------------------------
models$m_high <- m_high
models$m_high_black <- m_high_black
models$m_precov <- m_precov
models$m_precov_black <- m_precov_black
models$m_levels <- m_levels
models$m_levels_black <- m_levels_black
models$loso_coefs <- loso_coefs

saveRDS(models, "../data/models.rds")
saveRDS(analysis, "../data/analysis.rds")

cat("\nRobustness checks complete.\n")
