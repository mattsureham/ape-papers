## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0939: Employment Costs of Seismicity Regulation

library(tidyverse)
library(fixest)
library(did)
library(fwildclusterboot)

data_dir <- "data"
if (!dir.exists(data_dir)) data_dir <- "../data"

cat("=== Loading panels ===\n")
panel_total <- read_csv(file.path(data_dir, "panel_total.csv"), show_col_types = FALSE)
panel_213   <- read_csv(file.path(data_dir, "panel_213.csv"), show_col_types = FALSE)
panel_211   <- read_csv(file.path(data_dir, "panel_211.csv"), show_col_types = FALSE)
panel_retail <- read_csv(file.path(data_dir, "panel_retail.csv"), show_col_types = FALSE)

# ===========================================================================
# 1. Wild Cluster Bootstrap — Address few-cluster concern
# ===========================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

# TWFE baseline for total employment
twfe_total <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_total,
  cluster = ~county_fips
)

# Wild cluster bootstrap
wcb_total <- tryCatch({
  boot_feols <- boottest(
    twfe_total,
    param = "post",
    B = 9999,
    clustid = "county_fips",
    type = "webb"
  )
  cat("Wild Cluster Bootstrap — Total Employment:\n")
  cat(sprintf("  Point estimate: %.4f\n", boot_feols$point_estimate))
  cat(sprintf("  CI (95%%): [%.4f, %.4f]\n", boot_feols$conf_int[1], boot_feols$conf_int[2]))
  cat(sprintf("  p-value: %.4f\n", boot_feols$p_val))
  boot_feols
}, error = function(e) {
  cat(sprintf("  WCB error: %s\n", e$message))
  NULL
})

# WCB for NAICS 213
twfe_213 <- feols(
  log_emp ~ post | county_fips + yq,
  data = panel_213,
  cluster = ~county_fips
)

wcb_213 <- tryCatch({
  boot_213 <- boottest(
    twfe_213,
    param = "post",
    B = 9999,
    clustid = "county_fips",
    type = "webb"
  )
  cat("\nWild Cluster Bootstrap — NAICS 213:\n")
  cat(sprintf("  Point estimate: %.4f\n", boot_213$point_estimate))
  cat(sprintf("  CI (95%%): [%.4f, %.4f]\n", boot_213$conf_int[1], boot_213$conf_int[2]))
  cat(sprintf("  p-value: %.4f\n", boot_213$p_val))
  boot_213
}, error = function(e) {
  cat(sprintf("  WCB 213 error: %s\n", e$message))
  NULL
})


# ===========================================================================
# 2. Leave-one-out — Drop each treated county
# ===========================================================================
cat("\n=== Leave-One-Out Sensitivity ===\n")

treated_counties <- unique(panel_total$county_fips[panel_total$treated_county == 1])

loo_results <- map_dfr(treated_counties, function(drop_fips) {
  df_loo <- panel_total %>% filter(county_fips != drop_fips)
  m <- feols(log_emp ~ post | county_fips + yq, data = df_loo, cluster = ~county_fips)
  tibble(
    dropped_county = drop_fips,
    coef = coef(m)["post"],
    se = se(m)["post"],
    pval = pvalue(m)["post"]
  )
})

cat("Leave-one-out results (total employment):\n")
cat(sprintf("  Full sample: %.4f\n", coef(twfe_total)["post"]))
cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  LOO mean: %.4f\n", mean(loo_results$coef)))

write_csv(loo_results, file.path(data_dir, "loo_results.csv"))


# ===========================================================================
# 3. Alternative treatment definition — Continuous intensity
# ===========================================================================
cat("\n=== Continuous Treatment Intensity ===\n")

# Use pre-directive (2012-2014) mining employment share as treatment intensity
pre_mining <- panel_213 %>%
  filter(year >= 2012 & year <= 2014) %>%
  group_by(county_fips) %>%
  summarise(pre_mining_emp = mean(emp, na.rm = TRUE), .groups = "drop")

pre_total <- panel_total %>%
  filter(year >= 2012 & year <= 2014) %>%
  group_by(county_fips) %>%
  summarise(pre_total_emp = mean(emp, na.rm = TRUE), .groups = "drop")

mining_share <- pre_mining %>%
  left_join(pre_total, by = "county_fips") %>%
  mutate(mining_share = pre_mining_emp / pre_total_emp)

panel_total_cont <- panel_total %>%
  left_join(mining_share %>% select(county_fips, mining_share), by = "county_fips") %>%
  mutate(
    mining_share = replace_na(mining_share, 0),
    # Continuous treatment: mining share × post
    intensity_post = mining_share * post
  )

twfe_continuous <- feols(
  log_emp ~ intensity_post | county_fips + yq,
  data = panel_total_cont,
  cluster = ~county_fips
)
cat("Continuous treatment (mining share × post):\n")
print(summary(twfe_continuous))


# ===========================================================================
# 4. Placebo test — Pre-treatment fake timing
# ===========================================================================
cat("\n=== Placebo Test (Fake Treatment 2015 Q1) ===\n")

# Use pre-treatment sample with fake treatment date earlier
# Data starts 2014; place fake treatment at 2015 Q1 (yq = 2015*4+1 = 8061)
# Use only 2014 Q1 through the real treatment date
real_first_treat <- min(panel_total$first_treat_yq[panel_total$first_treat_yq > 0])

panel_placebo <- panel_total %>%
  filter(yq < real_first_treat) %>%
  mutate(
    fake_post = if_else(treated_county == 1 & yq >= (2015L * 4L + 1L), 1L, 0L)
  )

# Check that fake_post has variation
cat(sprintf("  Placebo panel: %d obs, fake_post mean = %.3f\n",
            nrow(panel_placebo), mean(panel_placebo$fake_post)))

if (sum(panel_placebo$fake_post) > 0 && sum(panel_placebo$fake_post) < nrow(panel_placebo)) {
  twfe_placebo <- feols(
    log_emp ~ fake_post | county_fips + yq,
    data = panel_placebo,
    cluster = ~county_fips
  )
  cat("Placebo (fake treatment 2015 Q1):\n")
  print(summary(twfe_placebo))
} else {
  cat("  Insufficient variation for placebo test. Using treated × trend instead.\n")
  # Alternative: test for differential pre-trends
  panel_pretrend <- panel_total %>%
    filter(yq < real_first_treat) %>%
    mutate(treated_trend = treated_county * (yq - min(yq)))

  twfe_placebo <- feols(
    log_emp ~ treated_trend | county_fips + yq,
    data = panel_pretrend,
    cluster = ~county_fips
  )
  cat("Pre-trend test (treated × time):\n")
  print(summary(twfe_placebo))
}


# ===========================================================================
# 5. Controlling for pre-period oil extraction share
# ===========================================================================
cat("\n=== Controlling for Oil Extraction Exposure ===\n")

pre_extraction <- panel_211 %>%
  filter(year >= 2012 & year <= 2014) %>%
  group_by(county_fips) %>%
  summarise(pre_extraction_emp = mean(emp, na.rm = TRUE), .groups = "drop")

extraction_share <- pre_extraction %>%
  left_join(pre_total, by = "county_fips") %>%
  mutate(extraction_share = pre_extraction_emp / pre_total_emp)

panel_total_ctrl <- panel_total %>%
  left_join(extraction_share %>% select(county_fips, extraction_share), by = "county_fips") %>%
  mutate(
    extraction_share = replace_na(extraction_share, 0),
    extraction_trend = extraction_share * yq
  )

twfe_ctrl <- feols(
  log_emp ~ post + extraction_trend | county_fips + yq,
  data = panel_total_ctrl,
  cluster = ~county_fips
)
cat("Controlling for extraction share × trend:\n")
print(summary(twfe_ctrl))


# ===========================================================================
# 6. DDD — Mining support vs Retail in same counties
# ===========================================================================
cat("\n=== Triple-Difference (Mining Support vs Retail) ===\n")

# Stack mining support and retail panels
ddd_panel <- bind_rows(
  panel_213 %>% mutate(mining_sector = 1L),
  panel_retail %>% mutate(mining_sector = 0L)
)

twfe_ddd <- feols(
  log_emp ~ post:i(mining_sector) | county_fips^mining_sector + yq^mining_sector,
  data = ddd_panel,
  cluster = ~county_fips
)
cat("DDD (Mining Support vs Retail):\n")
print(summary(twfe_ddd))


# ===========================================================================
# 7. Save robustness results
# ===========================================================================
rob_results <- list(
  wcb_total = if (!is.null(wcb_total))
    list(ci = wcb_total$conf_int, pval = wcb_total$p_val) else NULL,
  wcb_213 = if (!is.null(wcb_213))
    list(ci = wcb_213$conf_int, pval = wcb_213$p_val) else NULL,
  loo_range = c(min(loo_results$coef), max(loo_results$coef)),
  twfe_continuous = list(
    coef = coef(twfe_continuous)["intensity_post"],
    se = se(twfe_continuous)["intensity_post"]
  ),
  twfe_placebo = list(
    coef = coef(twfe_placebo)["fake_post"],
    se = se(twfe_placebo)["fake_post"],
    pval = pvalue(twfe_placebo)["fake_post"]
  ),
  twfe_ctrl = list(
    coef = coef(twfe_ctrl)["post"],
    se = se(twfe_ctrl)["post"]
  ),
  twfe_ddd = list(
    coef = coef(twfe_ddd),
    se = se(twfe_ddd)
  )
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
saveRDS(
  list(
    twfe_continuous = twfe_continuous,
    twfe_placebo = twfe_placebo,
    twfe_ctrl = twfe_ctrl,
    twfe_ddd = twfe_ddd
  ),
  file.path(data_dir, "robustness_models.rds")
)

cat("\nRobustness checks complete.\n")
