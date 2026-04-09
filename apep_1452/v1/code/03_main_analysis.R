## 03_main_analysis.R — Main regressions
source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Main Analysis ===\n")
cat("Panel:", nrow(panel), "obs,", n_distinct(panel$nace), "sectors,",
    n_distinct(panel$quarter), "quarters\n")

# ========================================================================
# 1. Baseline TWFE: log employment on cumulative indexation
# ========================================================================

# Model 1: Basic TWFE
m1 <- feols(log_emp ~ treatment_intensity | nace + quarter,
            data = panel, cluster = ~nace)

cat("\n--- Model 1: Basic TWFE ---\n")
print(summary(m1))

# Model 2: TWFE excluding COVID-affected sectors (I = accommodation/food)
panel_no_covid <- panel |> filter(!nace %in% c("I"))

m2 <- feols(log_emp ~ treatment_intensity | nace + quarter,
            data = panel_no_covid, cluster = ~nace)

cat("\n--- Model 2: Excluding accommodation/food ---\n")
print(summary(m2))

# Model 3: Binary treatment — early (pivot/quarterly) vs late (annual)
panel <- panel |>
  mutate(early = as.integer(regime %in% c("pivot", "quarterly")),
         post_2022 = as.integer(time_q >= 2022.0),
         early_x_post = early * post_2022)

m3 <- feols(log_emp ~ early_x_post | nace + quarter,
            data = panel, cluster = ~nace)

cat("\n--- Model 3: Binary early vs late treatment ---\n")
print(summary(m3))

# ========================================================================
# 2. Event study — quarterly leads and lags relative to 2022-Q1
# ========================================================================
panel <- panel |>
  mutate(
    event_time = round((time_q - 2022.0) * 4),  # quarters relative to 2022-Q1
    event_time = pmax(pmin(event_time, 10), -12)  # truncate at -12 to +10
  )

# Event study for early-treated sectors
m_event <- feols(log_emp ~ i(event_time, early, ref = -1) | nace + quarter,
                 data = panel, cluster = ~nace)

cat("\n--- Event Study ---\n")
print(summary(m_event))

# ========================================================================
# 3. Heterogeneity by sector size
# ========================================================================
# Compute pre-treatment average employment
pre_emp <- panel |>
  filter(time_q < 2022.0) |>
  group_by(nace) |>
  summarise(pre_mean_emp = mean(employment_ths, na.rm = TRUE), .groups = "drop")

panel <- panel |>
  left_join(pre_emp, by = "nace") |>
  mutate(large_sector = as.integer(pre_mean_emp > median(pre_mean_emp, na.rm = TRUE)))

# Interact treatment with sector size instead of splitting
m4 <- feols(log_emp ~ treatment_intensity + treatment_intensity:large_sector | nace + quarter,
            data = panel, cluster = ~nace)

# Also split: private vs public
panel <- panel |>
  mutate(public = as.integer(nace %in% c("O", "P", "Q")))

m4_private <- feols(log_emp ~ treatment_intensity | nace + quarter,
                    data = panel |> filter(public == 0), cluster = ~nace)

# Public sector has only 3 sectors all in same regime — interaction instead
m4_pub_interact <- feols(log_emp ~ treatment_intensity + treatment_intensity:public | nace + quarter,
                         data = panel, cluster = ~nace)

cat("\n--- Heterogeneity: Size interaction ---\n")
print(summary(m4))
cat("\n--- Heterogeneity: Private sector ---\n")
print(summary(m4_private))
cat("\n--- Heterogeneity: Public interaction ---\n")
print(summary(m4_pub_interact))

# ========================================================================
# 4. Save results and diagnostics
# ========================================================================
results <- list(
  m1 = m1,
  m2 = m2,
  m3 = m3,
  m_event = m_event,
  m4 = m4,
  m4_private = m4_private,
  m4_pub_interact = m4_pub_interact
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validate_v1.py
# All sectors receive continuous treatment (cumulative indexation)
# at different intensities — there are no "untreated" sectors
# Report total observations as treated since this is a continuous-treatment design
n_treated <- nrow(panel[panel$treatment_intensity > 0, ])
n_pre <- sum(panel$time_q < 2022.0) / n_distinct(panel$nace)
diagnostics <- list(
  n_treated = n_treated,
  n_pre = round(n_pre),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")

# Save panel for robustness
saveRDS(panel, file.path(data_dir, "analysis_panel_final.rds"))
cat("Main analysis complete.\n")
