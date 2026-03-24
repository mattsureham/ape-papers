# 04_robustness.R — Robustness checks
# apep_0871: NIS2 Cybersecurity Regulation and Enterprise Security Investment

source("00_packages.R")

# ===========================================================================
# 1. Load data
# ===========================================================================
panel_clean <- readRDS("../data/panel_clean.rds")
idx_data <- readRDS("../data/index_panel.rds")
indicator_labels <- readRDS("../data/indicator_labels.rds")

did_sample <- idx_data[size_emp %in% c("10-49", "50-249")]
did_sample[, triple := as.integer(medium_firm == 1 & post == 1 & transposed == 1)]

# ===========================================================================
# 2. Alternative clustering: Wild cluster bootstrap (Cameron, Gelbach, Miller)
# ===========================================================================
message("=== Wild Cluster Bootstrap (27 clusters) ===")

# With 27 clusters, CR1 may over-reject. Use wild bootstrap.
# fixest's boottest via fwildclusterboot
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  m_base <- feols(security_index ~ treat_post | geo_size + geo_year,
                  data = did_sample, cluster = ~geo)

  boot_result <- tryCatch(
    boottest(m_base, param = "treat_post", clustid = ~geo,
             B = 9999, type = "mammen"),
    error = function(e) {
      message("  Wild bootstrap failed: ", e$message)
      NULL
    }
  )

  if (!is.null(boot_result)) {
    message(sprintf("  Wild bootstrap p-value: %.3f", boot_result$p_val))
    message(sprintf("  Wild bootstrap CI: [%.2f, %.2f]",
                    boot_result$conf_int[1], boot_result$conf_int[2]))
  }
} else {
  message("  fwildclusterboot not installed — skipping wild bootstrap")
}

# ===========================================================================
# 3. Leave-one-out: Drop each country sequentially
# ===========================================================================
message("\n=== Leave-One-Out Sensitivity ===")

countries <- unique(did_sample$geo)
loo_results <- list()

for (cty in countries) {
  loo_data <- did_sample[geo != cty]
  m_loo <- feols(security_index ~ treat_post | geo_size + geo_year,
                 data = loo_data, cluster = ~geo)
  loo_results[[cty]] <- data.table(
    dropped = cty,
    beta = coef(m_loo)["treat_post"],
    se = se(m_loo)["treat_post"],
    pval = pvalue(m_loo)["treat_post"]
  )
}

loo_dt <- rbindlist(loo_results)
message(sprintf("  LOO β range: [%.2f, %.2f]",
                min(loo_dt$beta), max(loo_dt$beta)))
message(sprintf("  LOO p range: [%.3f, %.3f]",
                min(loo_dt$pval), max(loo_dt$pval)))

# ===========================================================================
# 4. Placebo: 2019 vs 2022 (both pre-NIS2)
# ===========================================================================
message("\n=== Placebo Test: 2019 vs 2022 (pre-NIS2) ===")

placebo_data <- idx_data[size_emp %in% c("10-49", "50-249") & year %in% c(2019, 2022)]
placebo_data[, `:=`(
  placebo_post = as.integer(year == 2022),
  placebo_treat = as.integer(size_emp == "50-249" & year == 2022),
  geo_size_p = paste0(geo, "_", size_emp)
)]

m_placebo <- feols(security_index ~ placebo_treat | geo_size_p + year,
                   data = placebo_data, cluster = ~geo)

message("Placebo DiD (medium × 2022, base 2019):")
print(summary(m_placebo))

# ===========================================================================
# 5. Alternative control group: 10-249 vs GE250
# ===========================================================================
message("\n=== Alternative: GE250 Treatment Intensity ===")

# Here we test whether GE250 firms (already under NIS1, intensified by NIS2)
# show a stronger effect than medium firms
alt_sample <- idx_data[size_emp %in% c("10-49", "GE250") & year %in% c(2019, 2022, 2024)]
alt_sample[, `:=`(
  alt_treat_post = as.integer(size_emp == "GE250" & year >= 2024),
  geo_size_a = paste0(geo, "_", size_emp),
  geo_year_a = paste0(geo, "_", year)
)]

m_alt <- feols(security_index ~ alt_treat_post | geo_size_a + geo_year_a,
               data = alt_sample, cluster = ~geo)

message("Large (GE250) vs Small (10-49) DiD:")
print(summary(m_alt))

# ===========================================================================
# 6. DDD robustness: Leave out each transposed country
# ===========================================================================
message("\n=== DDD Leave-One-Out (transposed countries) ===")

transposed_countries <- c("BE", "HR", "HU", "IT", "LV", "LT")
ddd_loo <- list()

for (cty in transposed_countries) {
  loo_data <- did_sample[geo != cty]
  loo_data[, triple_loo := as.integer(medium_firm == 1 & post == 1 & transposed == 1)]
  m_loo <- feols(security_index ~ treat_post + triple_loo | geo_size + geo_year,
                 data = loo_data, cluster = ~geo)
  ddd_loo[[cty]] <- data.table(
    dropped = cty,
    beta_did = coef(m_loo)["treat_post"],
    beta_triple = coef(m_loo)["triple_loo"],
    se_triple = se(m_loo)["triple_loo"],
    pval_triple = pvalue(m_loo)["triple_loo"]
  )
  message(sprintf("  Drop %s: β_triple = %.2f (%.2f), p = %.3f",
                  cty, coef(m_loo)["triple_loo"],
                  se(m_loo)["triple_loo"],
                  pvalue(m_loo)["triple_loo"]))
}

ddd_loo_dt <- rbindlist(ddd_loo)

# ===========================================================================
# 7. Save robustness results
# ===========================================================================

rob_results <- list(
  loo = loo_dt,
  placebo = m_placebo,
  alt_control = m_alt,
  ddd_loo = ddd_loo_dt
)

saveRDS(rob_results, "../data/robustness_results.rds")
message("\nRobustness checks complete.")
