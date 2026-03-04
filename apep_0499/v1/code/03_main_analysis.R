## 03_main_analysis.R — Primary DiD and DDD regressions
## apep_0499: Action Cœur de Ville and Property Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ==============================================================
# 1. Load data
# ==============================================================
cat("Loading cleaned data...\n")
panel <- readRDS(file.path(data_dir, "commune_year_panel.rds"))
dvf_res <- readRDS(file.path(data_dir, "dvf_residential_clean.rds"))

cat(sprintf("Panel: %d commune-years | %d unique communes | %d ACV\n",
            nrow(panel), n_distinct(panel$commune),
            n_distinct(panel$commune[panel$treated])))

# ==============================================================
# 2. Summary Statistics
# ==============================================================
cat("\n--- Summary Statistics ---\n")

# Pre-treatment means by group
pre_stats <- panel %>%
  filter(year < 2018) %>%
  group_by(treated) %>%
  summarise(
    n_communes = n_distinct(commune),
    mean_price_m2 = mean(mean_price_m2, na.rm = TRUE),
    mean_n_trans = mean(n_transactions, na.rm = TRUE),
    mean_area = mean(mean_area, na.rm = TRUE),
    pct_apt = mean(pct_apartment, na.rm = TRUE),
    .groups = "drop"
  )

print(pre_stats)

# Save summary stats table
sumstats <- panel %>%
  filter(year < 2018) %>%
  mutate(group = if_else(treated, "ACV Cities", "Control Cities")) %>%
  group_by(group) %>%
  summarise(
    `N Communes` = n_distinct(commune),
    `Mean Price/m² (€)` = round(mean(mean_price_m2, na.rm = TRUE), 0),
    `Median Price/m² (€)` = round(median(median_price_m2, na.rm = TRUE), 0),
    `Mean Transactions/Year` = round(mean(n_transactions, na.rm = TRUE), 1),
    `Pct Apartments` = round(100 * mean(pct_apartment, na.rm = TRUE), 1),
    `Mean Area (m²)` = round(mean(mean_area, na.rm = TRUE), 1),
    .groups = "drop"
  )

write_csv(sumstats, file.path(tables_dir, "summary_statistics.csv"))

# ==============================================================
# 3. Main DiD: Commune-Year Panel
# ==============================================================
cat("\n--- Main DiD Regressions ---\n")

# Model 1: Basic DiD (no FE)
m1 <- feols(log_mean_price_m2 ~ treat_post,
            data = panel,
            cluster = ~commune)

# Model 2: Commune + Year FE
m2 <- feols(log_mean_price_m2 ~ treat_post | commune + year,
            data = panel,
            cluster = ~commune)

# Model 3: Commune + Year FE + département × year trends
m3 <- feols(log_mean_price_m2 ~ treat_post | commune + departement^year,
            data = panel,
            cluster = ~commune)

# Model 4: Transaction volume
m4 <- feols(log_n_trans ~ treat_post | commune + year,
            data = panel,
            cluster = ~commune)

# Display results
cat("\n=== MAIN RESULTS ===\n")
etable(m1, m2, m3, m4,
       headers = c("Basic", "Commune+Year FE", "Dep×Year FE", "Volume"),
       se.below = TRUE)

# ==============================================================
# 4. Event Study
# ==============================================================
cat("\n--- Event Study ---\n")

# Create relative time indicators
panel <- panel %>%
  mutate(
    rel_year = year - 2018,
    # Bin endpoints
    rel_year_binned = case_when(
      rel_year <= -4 ~ -4,
      rel_year >= 6 ~ 6,
      TRUE ~ rel_year
    )
  )

# Event study with fixest
es <- feols(log_mean_price_m2 ~ i(rel_year_binned, treated, ref = -1) |
              commune + year,
            data = panel,
            cluster = ~commune)

cat("Event study coefficients:\n")
print(coeftable(es))

# Save event study coefficients for plotting
es_coefs <- as_tibble(coeftable(es)) %>%
  mutate(
    rel_year = as.integer(str_extract(rownames(coeftable(es)), "-?\\d+")),
    estimate = Estimate,
    se = `Std. Error`,
    ci_low = estimate - 1.96 * se,
    ci_high = estimate + 1.96 * se
  ) %>%
  select(rel_year, estimate, se, ci_low, ci_high)

# Add the reference period
es_coefs <- bind_rows(
  es_coefs,
  tibble(rel_year = -1, estimate = 0, se = 0, ci_low = 0, ci_high = 0)
) %>%
  arrange(rel_year)

write_csv(es_coefs, file.path(tables_dir, "event_study_coefs.csv"))

# ==============================================================
# 5. Transaction-Level Regressions
# ==============================================================
cat("\n--- Transaction-Level Regressions ---\n")

# Model 5: Transaction-level with property controls
m5 <- feols(log_price_m2 ~ treat_post + log(area) + i(broad_type) |
              commune_full + year,
            data = dvf_res,
            cluster = ~commune_full)

# Model 6: Transaction-level, département × year FE
m6 <- feols(log_price_m2 ~ treat_post + log(area) + i(broad_type) |
              commune_full + departement^year,
            data = dvf_res,
            cluster = ~commune_full)

cat("\n=== TRANSACTION-LEVEL RESULTS ===\n")
etable(m5, m6,
       headers = c("Commune+Year FE", "Dep×Year FE"),
       se.below = TRUE)

# ==============================================================
# 6. Heterogeneity by Property Type
# ==============================================================
cat("\n--- Heterogeneity by Property Type ---\n")

# Apartments
m_apt <- feols(log_price_m2 ~ treat_post + log(area) | commune_full + year,
               data = dvf_res %>% filter(broad_type == "Apartment"),
               cluster = ~commune_full)

# Houses
m_house <- feols(log_price_m2 ~ treat_post + log(area) | commune_full + year,
                 data = dvf_res %>% filter(broad_type == "House"),
                 cluster = ~commune_full)

etable(m_apt, m_house,
       headers = c("Apartments", "Houses"),
       se.below = TRUE)

# ==============================================================
# 7. Save regression results
# ==============================================================

# Main results table
models <- list(
  "Basic DiD" = m1,
  "Commune + Year FE" = m2,
  "Dep × Year FE" = m3,
  "Transaction Volume" = m4,
  "Transaction-Level" = m5,
  "Trans-Level Dep×Year" = m6
)

# Save as CSV for LaTeX
main_results <- map_dfr(names(models), function(name) {
  m <- models[[name]]
  ct <- coeftable(m)
  # Get treat_post row
  row_idx <- grep("treat_post", rownames(ct))
  if (length(row_idx) > 0) {
    tibble(
      model = name,
      coefficient = ct[row_idx[1], "Estimate"],
      std_error = ct[row_idx[1], "Std. Error"],
      t_stat = ct[row_idx[1], "t value"],
      p_value = ct[row_idx[1], "Pr(>|t|)"],
      n_obs = nobs(m),
      r2 = fitstat(m, "r2")[[1]]
    )
  }
})

write_csv(main_results, file.path(tables_dir, "main_results.csv"))

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Results saved to tables/\n")
