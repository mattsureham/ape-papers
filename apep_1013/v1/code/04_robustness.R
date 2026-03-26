# 04_robustness.R — Robustness checks for Egypt energy reform paper

library(dplyr)
library(tidyr)
library(fixest)
library(fwildclusterboot)

data_dir <- file.path(dirname(getwd()), "data")
sector_panel <- readRDS(file.path(data_dir, "sector_panel.rds"))
panel <- readRDS(file.path(data_dir, "product_panel.rds"))

# Reconstruct variables
sector_panel <- sector_panel %>%
  mutate(
    treat_binary_x_post = treat_binary * post,
    treat_x_post = treat_cont * post,
    rel_year = year - 2013,
    rel_year_capped = pmin(pmax(rel_year, -5L), 8L),
    treat_hi = as.integer(energy_group == "high")
  )

panel <- panel %>%
  mutate(treat_x_post = energy_intensity * post)

# ============================================================
# 1. RESTRICTED SAMPLE (2009-2023) — drop commodity boom years
# ============================================================
cat("=== Robustness 1: Restricted sample (2009-2023) ===\n")

sp_restricted <- sector_panel %>% filter(year >= 2009)

m_r1 <- feols(log_exports ~ treat_x_post | isic2 + year,
              data = sp_restricted, cluster = ~isic2)
cat("Continuous DiD (2009-2023):\n")
print(summary(m_r1))

# Pre-trends test on restricted sample
pre_restricted <- sp_restricted %>% filter(year < 2014)
m_pretrend_r <- feols(log_exports ~ i(year, treat_cont) | isic2 + year,
                      data = pre_restricted, cluster = ~isic2)
cat("\nPre-trends (2009-2013):\n")
print(summary(m_pretrend_r))
cat("Wald test:\n")
print(wald(m_pretrend_r, "year"))

# ============================================================
# 2. SECTOR-SPECIFIC LINEAR TRENDS
# ============================================================
cat("\n=== Robustness 2: Sector-specific linear trends ===\n")

sector_panel <- sector_panel %>%
  mutate(trend = year - 2005)

m_r2 <- feols(log_exports ~ treat_x_post + i(isic2, trend) | isic2 + year,
              data = sector_panel, cluster = ~isic2)
cat("Continuous DiD with sector trends:\n")
print(summary(m_r2, keep = "treat_x_post"))

# ============================================================
# 3. WILD CLUSTER BOOTSTRAP (few clusters)
# ============================================================
cat("\n=== Robustness 3: Wild cluster bootstrap ===\n")

# Main specification with WCB
m_main <- feols(log_exports ~ treat_x_post | isic2 + year,
                data = sector_panel, cluster = ~isic2)

# Using fwildclusterboot
lm_for_boot <- lm(log_exports ~ treat_x_post + factor(isic2) + factor(year),
                   data = sector_panel)

set.seed(42)
wcb <- tryCatch({
  boottest(
    lm_for_boot,
    param = "treat_x_post",
    clustid = ~isic2,
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(wcb)) {
  cat("Wild cluster bootstrap results:\n")
  print(summary(wcb))
  cat(sprintf("WCB p-value: %.4f\n", wcb$p_val))
}

# ============================================================
# 4. PLACEBO: Non-manufacturing exports (agriculture HS 01-24)
# ============================================================
cat("\n=== Robustness 4: Placebo — agricultural exports ===\n")

# Agriculture products should NOT be affected by industrial energy reform
comtrade <- readRDS(file.path(data_dir, "comtrade_egypt_exports.rds"))

ag_exports <- comtrade %>%
  mutate(
    hs2 = substr(gsub("[^0-9]", "", cmdCode), 1, 2),
    hs2_num = as.integer(hs2)
  ) %>%
  filter(hs2_num >= 1 & hs2_num <= 24) %>%
  group_by(year = as.integer(period)) %>%
  summarise(
    total_ag_exports = sum(primaryValue, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    post = as.integer(year >= 2014),
    log_ag_exports = log(total_ag_exports + 1)
  )

# Total manufacturing exports by energy group
manuf_exports <- sector_panel %>%
  group_by(year, energy_group) %>%
  summarise(
    total_manuf_exports = sum(exp(log_exports) - 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = energy_group, values_from = total_manuf_exports,
              names_prefix = "exports_")

combined <- ag_exports %>%
  left_join(manuf_exports, by = "year")

cat("Agriculture vs Manufacturing exports comparison:\n")
print(combined %>% select(year, log_ag_exports, exports_high, exports_low))

# ============================================================
# 5. HETEROGENEITY: By sector size
# ============================================================
cat("\n=== Robustness 5: Heterogeneity by pre-reform export level ===\n")

# Median split on pre-reform export level
median_exports <- sector_panel %>%
  filter(year < 2014) %>%
  group_by(isic2) %>%
  summarise(mean_pre_exports = mean(log_exports, na.rm = TRUE)) %>%
  pull(mean_pre_exports) %>%
  median()

sector_panel <- sector_panel %>%
  left_join(
    sector_panel %>%
      filter(year < 2014) %>%
      group_by(isic2) %>%
      summarise(mean_pre_exports = mean(log_exports, na.rm = TRUE)),
    by = "isic2"
  ) %>%
  mutate(large_sector = as.integer(mean_pre_exports > median_exports))

m_r5_large <- feols(log_exports ~ treat_x_post | isic2 + year,
                    data = sector_panel %>% filter(large_sector == 1),
                    cluster = ~isic2)
m_r5_small <- feols(log_exports ~ treat_x_post | isic2 + year,
                    data = sector_panel %>% filter(large_sector == 0),
                    cluster = ~isic2)

cat("Large export sectors:\n")
print(summary(m_r5_large))
cat("\nSmall export sectors:\n")
print(summary(m_r5_small))

# ============================================================
# 6. ALTERNATIVE OUTCOME: Export weight (quantity)
# ============================================================
cat("\n=== Robustness 6: Export weight (net weight) ===\n")

# Use netWgt from Comtrade as quantity proxy
hs_isic <- readRDS(file.path(data_dir, "hs_to_isic.rds"))
energy_int <- readRDS(file.path(data_dir, "energy_intensity.rds"))

weight_panel <- comtrade %>%
  mutate(
    hs2 = substr(gsub("[^0-9]", "", cmdCode), 1, 2),
    year = as.integer(period)
  ) %>%
  filter(as.integer(hs2) >= 25 & as.integer(hs2) <= 96) %>%
  left_join(hs_isic, by = "hs2") %>%
  left_join(energy_int, by = "isic2") %>%
  filter(!is.na(energy_intensity)) %>%
  group_by(isic2, sector_name, energy_intensity, energy_group, year) %>%
  summarise(
    total_weight = sum(netWgt, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(total_weight > 0) %>%
  mutate(
    log_weight = log(total_weight),
    post = as.integer(year >= 2014),
    treat_x_post = energy_intensity * post
  )

if (nrow(weight_panel) > 0) {
  m_r6 <- feols(log_weight ~ treat_x_post | isic2 + year,
                data = weight_panel, cluster = ~isic2)
  cat("Continuous DiD on log(weight):\n")
  print(summary(m_r6))
} else {
  cat("No valid weight data available. Skipping.\n")
  m_r6 <- NULL
}

# ============================================================
# 7. EVENT STUDY ON RESTRICTED SAMPLE (2009-2023)
# ============================================================
cat("\n=== Event study on restricted sample ===\n")

sp_restricted <- sp_restricted %>%
  mutate(
    rel_year = year - 2013,
    rel_year_capped = pmin(pmax(rel_year, -4L), 8L)
  )

m_es_r <- feols(log_exports ~ i(rel_year_capped, treat_cont, ref = 0) |
                  isic2 + year,
                data = sp_restricted, cluster = ~isic2)
cat("Event study (2009-2023, continuous treatment):\n")
print(summary(m_es_r))

# ============================================================
# Save robustness results
# ============================================================
rob_results <- list(
  restricted_sample = list(
    coef = coef(m_r1)["treat_x_post"],
    se = sqrt(vcov(m_r1)["treat_x_post", "treat_x_post"]),
    pval = summary(m_r1)$coeftable["treat_x_post", "Pr(>|t|)"]
  ),
  sector_trends = list(
    coef = coef(m_r2)["treat_x_post"],
    se = sqrt(vcov(m_r2)["treat_x_post", "treat_x_post"]),
    pval = summary(m_r2)$coeftable["treat_x_post", "Pr(>|t|)"]
  ),
  wcb_pval = if (!is.null(wcb)) wcb$p_val else NA,
  weight_outcome = if (!is.null(m_r6)) list(
    coef = coef(m_r6)["treat_x_post"],
    se = sqrt(vcov(m_r6)["treat_x_post", "treat_x_post"]),
    pval = summary(m_r6)$coeftable["treat_x_post", "Pr(>|t|)"]
  ) else list(coef = NA, se = NA, pval = NA)
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
saveRDS(list(m_r1 = m_r1, m_r2 = m_r2, m_r5_large = m_r5_large,
             m_r5_small = m_r5_small, m_es_r = m_es_r),
        file.path(data_dir, "robustness_models.rds"))

cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat(sprintf("Restricted sample (2009+): %.3f (p=%.3f)\n",
            rob_results$restricted_sample$coef, rob_results$restricted_sample$pval))
cat(sprintf("Sector trends: %.3f (p=%.3f)\n",
            rob_results$sector_trends$coef, rob_results$sector_trends$pval))
cat(sprintf("WCB p-value: %.4f\n", rob_results$wcb_pval))
cat(sprintf("Weight outcome: %.3f (p=%.3f)\n",
            rob_results$weight_outcome$coef, rob_results$weight_outcome$pval))

cat("\nRobustness checks complete.\n")
