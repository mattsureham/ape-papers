## 03_main_analysis.R — Main DiD regressions
## apep_0658
##
## CRITICAL: Norway's 2020 municipal merger creates a structural break.
## Pre-2020 data uses different geographic boundaries.
## PRIMARY SPECIFICATION: 2020-2024 panel (post-merger geography only).
## This gives 2 pre-reform years (2020-2021) and 3 post-reform years (2022-2024).

source("00_packages.R")

panel_full <- readRDS("../data/panel.rds")
cat("Full panel:", nrow(panel_full), "obs\n")

## =====================================================
## RESTRICT TO POST-MERGER PERIOD (2020-2024)
## =====================================================
panel <- panel_full %>% filter(year >= 2020, year <= 2024)
cat("Post-merger panel:", nrow(panel), "obs,", n_distinct(panel$muni_code), "municipalities\n")
cat("Pre-reform (2020-2021):", sum(panel$post == 0), "\n")
cat("Post-reform (2022-2024):", sum(panel$post == 1), "\n")

## =====================================================
## SUMMARY STATISTICS
## =====================================================
cat("\n=== SUMMARY STATISTICS ===\n")

# Treatment variable
cat("Treatment (secondary share of assessed dwelling value, 2021):\n")
treat_vals <- unique(panel[, c("muni_code", "sec_share_2021")])
print(summary(treat_vals$sec_share_2021))
cat("SD:", sd(treat_vals$sec_share_2021), "\n")

# Outcome means by period and treatment group
cat("\nOutcome means by period and exposure:\n")
panel %>%
  group_by(Period = ifelse(post == 1, "Post (2022-24)", "Pre (2020-21)"),
           Exposure = ifelse(high_exposure == 1, "High", "Low")) %>%
  summarise(
    Permits = mean(permits_started, na.rm = TRUE),
    Enterprises = mean(new_enterprises, na.rm = TRUE),
    OutMig = mean(out_migration, na.rm = TRUE),
    AvgWT = mean(avg_wealth_tax, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(Period), Exposure) %>%
  print()

## =====================================================
## 1. FIRST STAGE: Wealth Tax Response
## =====================================================
cat("\n=== FIRST STAGE ===\n")

fs1 <- feols(avg_wealth_tax ~ treat_z_x_post | muni_code + year,
             data = panel, cluster = ~muni_code)
cat("Wealth tax ~ treatment x post:\n")
summary(fs1)

## =====================================================
## 2. MAIN SPECIFICATION: Building Permits
## =====================================================
cat("\n=== BUILDING PERMITS ===\n")

# Level
m1_level <- feols(permits_started ~ treat_z_x_post | muni_code + year,
                  data = panel, cluster = ~muni_code)
summary(m1_level)

# Log
m1_log <- feols(log_permits ~ treat_z_x_post | muni_code + year,
                data = panel, cluster = ~muni_code)
summary(m1_log)

# Event study (ref = 2021)
m1_es <- feols(log_permits ~ i(year, treat_z, ref = 2021) | muni_code + year,
               data = panel, cluster = ~muni_code)
cat("Event study (permits):\n")
summary(m1_es)

## =====================================================
## 3. ENTERPRISES
## =====================================================
cat("\n=== ENTERPRISES ===\n")

m2_log <- feols(log_enterprises ~ treat_z_x_post | muni_code + year,
                data = panel, cluster = ~muni_code)
summary(m2_log)

m2_es <- feols(log_enterprises ~ i(year, treat_z, ref = 2021) | muni_code + year,
               data = panel, cluster = ~muni_code)
cat("Event study (enterprises):\n")
summary(m2_es)

## =====================================================
## 4. OUT-MIGRATION
## =====================================================
cat("\n=== OUT-MIGRATION ===\n")

m3_log <- feols(log_out_migration ~ treat_z_x_post | muni_code + year,
                data = panel, cluster = ~muni_code)
summary(m3_log)

m3_es <- feols(log_out_migration ~ i(year, treat_z, ref = 2021) | muni_code + year,
               data = panel, cluster = ~muni_code)
cat("Event study (out-migration):\n")
summary(m3_es)

## Net migration (level)
m4 <- feols(net_migration ~ treat_z_x_post | muni_code + year,
            data = panel, cluster = ~muni_code)
summary(m4)

## =====================================================
## 5. BINARY TREATMENT
## =====================================================
cat("\n=== BINARY TREATMENT ===\n")

m_bin1 <- feols(log_permits ~ i(high_exposure, post, ref = 0) | muni_code + year,
                data = panel, cluster = ~muni_code)
m_bin2 <- feols(log_enterprises ~ i(high_exposure, post, ref = 0) | muni_code + year,
                data = panel, cluster = ~muni_code)
m_bin3 <- feols(log_out_migration ~ i(high_exposure, post, ref = 0) | muni_code + year,
                data = panel, cluster = ~muni_code)

cat("Binary DiD results:\n")
cat(sprintf("  Permits:     %.3f (%.3f), t=%.2f\n",
    coef(m_bin1), se(m_bin1), coef(m_bin1)/se(m_bin1)))
cat(sprintf("  Enterprises: %.3f (%.3f), t=%.2f\n",
    coef(m_bin2), se(m_bin2), coef(m_bin2)/se(m_bin2)))
cat(sprintf("  Out-mig:     %.3f (%.3f), t=%.2f\n",
    coef(m_bin3), se(m_bin3), coef(m_bin3)/se(m_bin3)))

## =====================================================
## 6. COUNTY x YEAR FE
## =====================================================
cat("\n=== COUNTY x YEAR FE ===\n")

panel$county <- substr(panel$muni_code, 1, 2)

m_cy1 <- feols(log_permits ~ treat_z_x_post | muni_code + county^year,
               data = panel, cluster = ~muni_code)
m_cy2 <- feols(log_enterprises ~ treat_z_x_post | muni_code + county^year,
               data = panel, cluster = ~muni_code)
m_cy3 <- feols(log_out_migration ~ treat_z_x_post | muni_code + county^year,
               data = panel, cluster = ~muni_code)

cat("With county x year FE:\n")
cat(sprintf("  Permits:     %.3f (%.3f), t=%.2f\n",
    coef(m_cy1), se(m_cy1), coef(m_cy1)/se(m_cy1)))
cat(sprintf("  Enterprises: %.3f (%.3f), t=%.2f\n",
    coef(m_cy2), se(m_cy2), coef(m_cy2)/se(m_cy2)))
cat(sprintf("  Out-mig:     %.3f (%.3f), t=%.2f\n",
    coef(m_cy3), se(m_cy3), coef(m_cy3)/se(m_cy3)))

## =====================================================
## 7. QUARTILE TREATMENT (DOSE-RESPONSE)
## =====================================================
cat("\n=== DOSE-RESPONSE (QUARTILES) ===\n")

panel$treat_q <- ntile(panel$sec_share_2021, 4)

m_q1 <- feols(log_permits ~ i(treat_q, post, ref = 1) | muni_code + year,
              data = panel, cluster = ~muni_code)
cat("Permits by treatment quartile (ref = Q1):\n")
summary(m_q1)

## =====================================================
## SAVE RESULTS
## =====================================================
results <- list(
  first_stage = fs1,
  permits_level = m1_level,
  permits_log = m1_log,
  permits_es = m1_es,
  enterprises_log = m2_log,
  enterprises_es = m2_es,
  out_migration_log = m3_log,
  out_migration_es = m3_es,
  net_migration = m4,
  bin_permits = m_bin1,
  bin_enterprises = m_bin2,
  bin_migration = m_bin3,
  county_permits = m_cy1,
  county_enterprises = m_cy2,
  county_migration = m_cy3,
  quartile_permits = m_q1
)
saveRDS(results, "../data/results.rds")

## DIAGNOSTICS
n_treated <- sum(panel$high_exposure == 1 & panel$year == 2022)
n_pre <- length(unique(panel$year[panel$post == 0]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_municipalities = n_distinct(panel$muni_code),
  n_years = n_distinct(panel$year),
  treatment_sd = sd(panel$sec_share_2021, na.rm = TRUE),
  outcome_sd_permits = sd(panel$permits_started, na.rm = TRUE),
  main_coef_permits = coef(m1_log)["treat_z_x_post"],
  main_se_permits = se(m1_log)["treat_z_x_post"],
  main_coef_ent = coef(m2_log)["treat_z_x_post"],
  main_se_ent = se(m2_log)["treat_z_x_post"],
  main_coef_mig = coef(m3_log)["treat_z_x_post"],
  main_se_mig = se(m3_log)["treat_z_x_post"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save panel for robustness
saveRDS(panel, "../data/panel_main.rds")

cat("\n=== DIAGNOSTICS ===\n")
cat("N treated:", n_treated, "\n")
cat("N pre-periods:", n_pre, "\n")
cat("N obs:", n_obs, "\n")
cat("Permits coef:", diagnostics$main_coef_permits, "\n")
cat("Permits SE:", diagnostics$main_se_permits, "\n")

cat("\n=== Main analysis complete ===\n")
