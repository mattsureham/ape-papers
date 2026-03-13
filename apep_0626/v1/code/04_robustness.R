## ============================================================================
## 04_robustness.R — Robustness Checks for apep_0626
## ============================================================================

source("code/00_packages.R")

data_dir <- "data"

cat("=== Loading data ===\n")
dt <- readRDS(file.path(data_dir, "clean_1920_1930.rds"))

## --------------------------------------------------------------------------
## 1. Placebo test: 1910-1920 (pre-quota period)
## --------------------------------------------------------------------------

cat("\n=== Placebo test (1910-1920) ===\n")

if (file.exists(file.path(data_dir, "clean_placebo.rds"))) {
  dt_p <- readRDS(file.path(data_dir, "clean_placebo.rds"))
  cat(sprintf("Placebo N: %s\n", format(nrow(dt_p), big.mark = ",")))

  ## Test 1: Does 1920 exposure predict 1910-1920 changes?
  ## (If yes, exposure correlates with pre-existing trends → bad)
  m_placebo_1 <- feols(delta_occscore ~ quota_exposure + age_1910 + I(age_1910^2) +
                          literate + urban | statefip_1910,
                        data = dt_p, lean = TRUE,
                        cluster = ~statefip_1910 + countyicp_1910)

  ## Test 2: Does 1910 exposure predict 1910-1920 changes?
  m_placebo_2 <- feols(delta_occscore ~ quota_exposure_1910 + age_1910 + I(age_1910^2) +
                          literate + urban | statefip_1910,
                        data = dt_p, lean = TRUE,
                        cluster = ~statefip_1910 + countyicp_1910)

  ## Test 3: Full controls matching main spec (state + occupation FE)
  m_placebo_full <- feols(delta_occscore ~ quota_exposure + age_1910 + I(age_1910^2) +
                            literate + urban | statefip_1910 + occ1950_1910,
                          data = dt_p, lean = TRUE,
                          cluster = ~statefip_1910 + countyicp_1910)

  ## Test 4: Upgrading indicator
  m_placebo_upgrade <- feols(upgraded ~ quota_exposure + age_1910 + I(age_1910^2) +
                               literate + urban | statefip_1910,
                             data = dt_p, lean = TRUE,
                             cluster = ~statefip_1910 + countyicp_1910)

  cat("\n--- Placebo results ---\n")
  etable(m_placebo_1, m_placebo_2, m_placebo_full, m_placebo_upgrade)

  saveRDS(list(m_placebo_1 = m_placebo_1, m_placebo_2 = m_placebo_2,
               m_placebo_full = m_placebo_full,
               m_placebo_upgrade = m_placebo_upgrade),
          file.path(data_dir, "placebo_models.rds"))

  rm(dt_p); gc()
} else {
  cat("WARNING: No placebo data available\n")
}

## --------------------------------------------------------------------------
## 2. Leave-one-origin-out
## --------------------------------------------------------------------------

cat("\n=== Leave-one-origin-out ===\n")

## Load county exposure with individual origin shares
county_exp <- readRDS(file.path(data_dir, "county_exposure.rds"))

origins <- c("italy", "russia", "poland", "austria", "hungary", "czech")
loo_results <- data.table(
  dropped_origin = character(),
  coef = numeric(),
  se = numeric(),
  n = integer()
)

for (origin in origins) {
  cat(sprintf("  Dropping %s...\n", origin))

  ## Recompute exposure excluding this origin
  origin_col <- paste0("share_", origin)
  county_exp[, loo_exposure := quota_exposure - get(origin_col)]

  ## Merge updated exposure
  dt_loo <- merge(dt[, -c("quota_exposure"), with = FALSE],
    county_exp[, .(STATEFIP, COUNTYICP, loo_exposure = quota_exposure - get(origin_col))],
    by.x = c("statefip_1920", "countyicp_1920"),
    by.y = c("STATEFIP", "COUNTYICP"),
    all.x = FALSE
  )

  m_loo <- feols(delta_occscore ~ loo_exposure + age_1920 + I(age_1920^2) +
                   literate + urban + log_pop | statefip_1920 + occ1950_1920,
                 data = dt_loo, lean = TRUE,
                 cluster = ~statefip_1920 + countyicp_1920)

  loo_results <- rbind(loo_results, data.table(
    dropped_origin = origin,
    coef = coef(m_loo)["loo_exposure"],
    se = se(m_loo)["loo_exposure"],
    n = nobs(m_loo)
  ))

  rm(dt_loo); gc()
}

cat("\n--- Leave-one-origin-out results ---\n")
print(loo_results)

saveRDS(loo_results, file.path(data_dir, "loo_results.rds"))

## --------------------------------------------------------------------------
## 3. Alternative clustering: state-level only
## --------------------------------------------------------------------------

cat("\n=== Alternative clustering ===\n")

## State-level clustering (conservative)
m_state_cluster <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
                           literate + urban + log_pop | statefip_1920 + occ1950_1920,
                         data = dt, lean = TRUE,
                         cluster = ~statefip_1920)

## Conley spatial SEs would be ideal but computationally prohibitive with 8M obs
## Instead, report both county and state clustering

cat("\n--- County vs state clustering ---\n")
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
cat(sprintf("County-clustered SE: %.4f\n", se(main_models$m4)["quota_exposure"]))
cat(sprintf("State-clustered SE:  %.4f\n", se(m_state_cluster)["quota_exposure"]))

saveRDS(m_state_cluster, file.path(data_dir, "model_state_cluster.rds"))

## --------------------------------------------------------------------------
## 4. Non-movers subsample (controls for sorting)
## --------------------------------------------------------------------------

cat("\n=== Non-movers subsample ===\n")

m_nonmover <- feols(delta_occscore ~ quota_exposure + age_1920 + I(age_1920^2) +
                      literate + urban + log_pop | statefip_1920 + occ1950_1920,
                    data = dt[moved == 0], lean = TRUE,
                    cluster = ~statefip_1920 + countyicp_1920)

cat(sprintf("Non-movers: N = %s, coef = %.4f (SE = %.4f)\n",
    format(nobs(m_nonmover), big.mark = ","),
    coef(m_nonmover)["quota_exposure"],
    se(m_nonmover)["quota_exposure"]))

saveRDS(m_nonmover, file.path(data_dir, "model_nonmover.rds"))

## --------------------------------------------------------------------------
## 5. Dose-response: quintile specification
## --------------------------------------------------------------------------

cat("\n=== Dose-response ===\n")

dt[, exp_quintile := cut(quota_exposure,
  breaks = quantile(quota_exposure, probs = seq(0, 1, 0.2)),
  labels = paste0("Q", 1:5),
  include.lowest = TRUE
)]

m_quintile <- feols(delta_occscore ~ i(exp_quintile, ref = "Q1") +
                      age_1920 + I(age_1920^2) + literate + urban + log_pop |
                      statefip_1920 + occ1950_1920,
                    data = dt, lean = TRUE,
                    cluster = ~statefip_1920 + countyicp_1920)

cat("\n--- Quintile specification ---\n")
etable(m_quintile)

saveRDS(m_quintile, file.path(data_dir, "model_quintile.rds"))

cat("\n=== Robustness checks complete ===\n")
