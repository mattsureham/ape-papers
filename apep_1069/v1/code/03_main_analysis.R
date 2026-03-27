## 03_main_analysis.R — Main DiD analysis
## apep_1069: The Compensation Cliff

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================================
# 1. Load Analysis Data
# ============================================================================
cat("=== Loading analysis data ===\n")
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel: ", nrow(panel), " obs, ", n_distinct(panel$buurt_code), " buurten\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Treated:", sum(panel$treated_median == 1 & panel$year == 2019), "buurten\n")
cat("Control:", sum(panel$treated_median == 0 & panel$year == 2019), "buurten\n")

# ============================================================================
# 2. Summary Statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

# Pre-treatment summary by treatment group
summ <- panel %>%
  filter(year <= 2020) %>%
  group_by(treated_median) %>%
  summarise(
    n_buurten = n_distinct(buurt_code),
    mean_woz = mean(woz, na.rm = TRUE),
    sd_woz = sd(woz, na.rm = TRUE),
    mean_dwellings = mean(n_dwellings, na.rm = TRUE),
    mean_owner_pct = mean(pct_owner, na.rm = TRUE),
    mean_cum_pga = mean(cum_pga, na.rm = TRUE),
    mean_n_eq_10km = mean(n_earthquakes_10km, na.rm = TRUE),
    .groups = "drop"
  )

print(summ)

# Pre-treatment SD(Y) for SDE calculation
pre_panel <- panel %>% filter(year <= 2020)
sd_y_pre <- sd(pre_panel$woz, na.rm = TRUE)
sd_y_pre_log <- sd(pre_panel$log_woz, na.rm = TRUE)
cat("\nPre-treatment SD(WOZ):", round(sd_y_pre, 2), "thousand EUR\n")
cat("Pre-treatment SD(log WOZ):", round(sd_y_pre_log, 4), "\n")

# ============================================================================
# 3. Main DiD Specification
# ============================================================================
cat("\n=== Main DiD Results ===\n")

# Spec 1: Simple DiD (binary treatment × post)
did1 <- feols(woz ~ treated_median:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

# Spec 2: Log WOZ
did2 <- feols(log_woz ~ treated_median:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

# Spec 3: Continuous treatment (log cumulative PGA × post)
did3 <- feols(woz ~ log_cum_pga:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

# Spec 4: Continuous treatment, log WOZ
did4 <- feols(log_woz ~ log_cum_pga:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

cat("DiD (binary, levels):\n")
summary(did1)

cat("\nDiD (binary, log):\n")
summary(did2)

cat("\nDiD (continuous, levels):\n")
summary(did3)

cat("\nDiD (continuous, log):\n")
summary(did4)

# ============================================================================
# 4. Event Study
# ============================================================================
cat("\n=== Event Study ===\n")

# Create year indicators relative to 2020 (last pre-treatment year)
panel <- panel %>%
  mutate(
    rel_year = year - 2020,
    year_factor = factor(year)
  )

# Event study with binary treatment
es1 <- feols(woz ~ i(year_factor, treated_median, ref = "2020") |
               buurt_code + year,
             data = panel, cluster = ~buurt_code)

cat("Event study (levels):\n")
summary(es1)

# Event study with log WOZ
es2 <- feols(log_woz ~ i(year_factor, treated_median, ref = "2020") |
               buurt_code + year,
             data = panel, cluster = ~buurt_code)

cat("\nEvent study (log):\n")
summary(es2)

# Extract event study coefficients for later plotting
es_coefs <- data.frame(
  year = as.numeric(gsub("year_factor::|:treated_median", "",
                         names(coef(es1)))),
  coef_level = coef(es1),
  se_level = sqrt(diag(vcov(es1))),
  coef_log = coef(es2),
  se_log = sqrt(diag(vcov(es2)))
)
# Add reference year
es_coefs <- bind_rows(
  es_coefs,
  data.frame(year = 2020, coef_level = 0, se_level = 0,
             coef_log = 0, se_log = 0)
) %>% arrange(year)

cat("\nEvent study coefficients:\n")
print(es_coefs)

saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# ============================================================================
# 5. Tercile Heterogeneity
# ============================================================================
cat("\n=== Heterogeneity by Exposure Tercile ===\n")

# Tercile-specific effects (T2 and T3 vs T1)
panel <- panel %>%
  mutate(
    tercile_2 = as.integer(exposure_tercile == 2),
    tercile_3 = as.integer(exposure_tercile == 3)
  )

het1 <- feols(woz ~ tercile_2:post + tercile_3:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

het2 <- feols(log_woz ~ tercile_2:post + tercile_3:post | buurt_code + year,
              data = panel, cluster = ~buurt_code)

cat("Tercile effects (levels):\n")
summary(het1)

cat("\nTercile effects (log):\n")
summary(het2)

# ============================================================================
# 6. Save Results for Tables
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  did_binary_levels = did1,
  did_binary_log = did2,
  did_continuous_levels = did3,
  did_continuous_log = did4,
  es_levels = es1,
  es_log = es2,
  het_levels = het1,
  het_log = het2,
  summary_stats = summ,
  sd_y_pre = sd_y_pre,
  sd_y_pre_log = sd_y_pre_log,
  es_coefs = es_coefs,
  n_treated = sum(panel$treated_median == 1 & panel$year == 2019),
  n_control = sum(panel$treated_median == 0 & panel$year == 2019),
  n_obs = nrow(panel),
  n_buurten = n_distinct(panel$buurt_code)
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validator
diagnostics <- list(
  n_treated = results$n_treated,
  n_pre = length(unique(panel$year[panel$year <= 2020])),
  n_obs = results$n_obs
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("diagnostics.json:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")

cat("\n=== Main analysis complete ===\n")
