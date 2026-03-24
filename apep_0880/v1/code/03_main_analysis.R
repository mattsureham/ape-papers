## 03_main_analysis.R — Main DiD analysis of CRMA on mineral import diversification
## APEP paper apep_0880

source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- readRDS("../data/panel.rds")

cat(sprintf("Panel: %d obs, %d minerals, %d years\n",
            nrow(panel), n_distinct(panel$mineral), n_distinct(panel$year)))

# ---------------------------------------------------------------
# Model 1: Continuous-treatment DiD (main specification)
# HHI_mt = α + β(PreHHI_m × Post_t) + mineral FE + year FE + ε
# β < 0 implies more-concentrated minerals diversified more post-CRMA
# ---------------------------------------------------------------
cat("\n--- Model 1: Continuous-Treatment DiD ---\n")

m1_ols <- feols(hhi ~ treat_continuous | hs_code + year,
                data = panel,
                cluster = ~hs_code)
cat("OLS with mineral + year FE:\n")
print(summary(m1_ols))

# ---------------------------------------------------------------
# Model 2: Binary treatment DiD (above/below 65% threshold)
# ---------------------------------------------------------------
cat("\n--- Model 2: Binary Treatment DiD ---\n")

m2_binary <- feols(hhi ~ treat_binary | hs_code + year,
                   data = panel,
                   cluster = ~hs_code)
cat("Binary (>65%) treatment:\n")
print(summary(m2_binary))

# ---------------------------------------------------------------
# Model 3: Continuous treatment on alternative outcomes
# ---------------------------------------------------------------
cat("\n--- Model 3: Alternative Outcomes ---\n")

# Top-country share
m3a <- feols(top_share ~ treat_continuous | hs_code + year,
             data = panel,
             cluster = ~hs_code)

# Number of sources
m3b <- feols(n_sources ~ treat_continuous | hs_code + year,
             data = panel,
             cluster = ~hs_code)

# Log HHI (semi-elasticity)
m3c <- feols(log_hhi ~ treat_continuous | hs_code + year,
             data = panel,
             cluster = ~hs_code)

cat("Top share:\n"); print(summary(m3a))
cat("N sources:\n"); print(summary(m3b))
cat("Log HHI:\n"); print(summary(m3c))

# ---------------------------------------------------------------
# Model 4: Dual-shock decomposition (CRMA vs China export controls)
# ---------------------------------------------------------------
cat("\n--- Model 4: Dual-Shock Decomposition ---\n")

m4 <- feols(hhi ~ treat_continuous + china_dep:post_crma +
              treat_continuous:china_dep | hs_code + year,
            data = panel,
            cluster = ~hs_code)
cat("With China interaction:\n")
print(summary(m4))

# ---------------------------------------------------------------
# Model 5: Dynamic specification (event study)
# ---------------------------------------------------------------
cat("\n--- Model 5: Event Study ---\n")

panel <- panel %>%
  mutate(
    # Create year dummies interacted with pre-CRMA HHI
    yr_2018 = pre_hhi * as.integer(year == 2018),
    yr_2019 = pre_hhi * as.integer(year == 2019),
    yr_2020 = pre_hhi * as.integer(year == 2020),
    # 2021 is omitted (reference year, one year pre-proposal)
    yr_2022 = pre_hhi * as.integer(year == 2022),
    yr_2023 = pre_hhi * as.integer(year == 2023),
    yr_2024 = pre_hhi * as.integer(year == 2024)
  )

m5_event <- feols(hhi ~ yr_2018 + yr_2019 + yr_2020 +
                    yr_2022 + yr_2023 + yr_2024 | hs_code + year,
                  data = panel,
                  cluster = ~hs_code)
cat("Event study coefficients:\n")
print(summary(m5_event))

# ---------------------------------------------------------------
# Save results
# ---------------------------------------------------------------
results <- list(
  m1_continuous = m1_ols,
  m2_binary = m2_binary,
  m3a_topshare = m3a,
  m3b_nsources = m3b,
  m3c_loghhi = m3c,
  m4_china = m4,
  m5_event = m5_event
)
saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------
# Write diagnostics.json for validate_v1.py
# ---------------------------------------------------------------
n_treated <- sum(panel$high_concentration == 1 & panel$year == 2022, na.rm = TRUE)
n_pre <- length(unique(panel$year[panel$year < 2023]))
n_obs <- nrow(panel)

diag <- list(
  # Continuous-treatment design: all minerals with non-zero pre-CRMA HHI are treated
  n_treated = n_distinct(panel$mineral[!is.na(panel$pre_hhi) & panel$pre_hhi > 0]),
  n_pre = n_pre,
  n_obs = n_obs
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Main analysis complete ===\n")
