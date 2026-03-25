## 04_robustness.R — Robustness checks
## Denmark Parallel Society Designation and Displacement (apep_0940)

library(data.table)
library(fixest)
library(sandwich)

cat("=== Robustness checks for apep_0940 ===\n")

panel <- fread("data/panel.csv")
panel[, mun_code_num := as.integer(mun_code)]

# -------------------------------------------------------------------
# 1. Wild cluster bootstrap (few treated clusters concern)
# -------------------------------------------------------------------
cat("\n--- Wild cluster bootstrap ---\n")

m1 <- feols(nw_share ~ treat_post | mun_code_num + year,
            data = panel, cluster = ~mun_code_num)

# Use fixest's built-in bootstrap
set.seed(42)
m1_boot <- feols(nw_share ~ treat_post | mun_code_num + year,
                 data = panel, cluster = ~mun_code_num,
                 ssc = ssc(adj = TRUE, fixef.K = "nested"))

# Randomization inference: permute treatment assignment
cat("\nRandomization inference (500 permutations)...\n")
set.seed(42)
treated_munis <- unique(panel$mun_code[panel$treated == 1])
n_treated <- length(treated_munis)
all_munis <- unique(panel$mun_code)

ri_coefs <- numeric(500)
for (i in 1:500) {
  fake_treated <- sample(all_munis, n_treated)
  panel[, fake_treat := as.integer(mun_code %in% fake_treated)]
  panel[, fake_tp := fake_treat * post]
  m_fake <- feols(nw_share ~ fake_tp | mun_code_num + year,
                  data = panel, cluster = ~mun_code_num)
  ri_coefs[i] <- coef(m_fake)["fake_tp"]
}
panel[, c("fake_treat", "fake_tp") := NULL]

actual_coef <- coef(m1)["treat_post"]
ri_pval <- mean(abs(ri_coefs) >= abs(actual_coef))
cat(sprintf("  Actual coefficient: %.5f\n", actual_coef))
cat(sprintf("  RI p-value (two-sided): %.3f\n", ri_pval))
cat(sprintf("  RI 95%% CI: [%.5f, %.5f]\n",
            quantile(ri_coefs, 0.025), quantile(ri_coefs, 0.975)))

# -------------------------------------------------------------------
# 2. Placebo test: Danish-origin population
# -------------------------------------------------------------------
cat("\n--- Placebo: Danish-origin population ---\n")

panel[, danish_share := danish / total]
m_placebo <- feols(danish_share ~ treat_post | mun_code_num + year,
                   data = panel, cluster = ~mun_code_num)
cat("Placebo (Danish-origin share):\n")
print(summary(m_placebo))

# -------------------------------------------------------------------
# 3. Pre-trend test (joint F-test on pre-treatment leads)
# -------------------------------------------------------------------
cat("\n--- Pre-trend joint test ---\n")

panel_es <- panel[year >= 2010]
es_full <- feols(nw_share ~ i(event_time, treated, ref = -1) | mun_code_num + year,
                 data = panel_es, cluster = ~mun_code_num)

# Test pre-treatment coefficients jointly = 0
pre_coefs <- grep("event_time::-", names(coef(es_full)), value = TRUE)
pre_coefs <- pre_coefs[!grepl("::-1$", pre_coefs)]  # exclude reference
if (length(pre_coefs) > 0) {
  pre_test <- wald(es_full, pre_coefs)
  cat("Joint F-test on pre-treatment leads:\n")
  print(pre_test)
}

# -------------------------------------------------------------------
# 4. Leave-one-out: drop each treated municipality
# -------------------------------------------------------------------
cat("\n--- Leave-one-out sensitivity ---\n")

treated_munis_codes <- unique(panel$mun_code[panel$treated == 1])
loo_results <- data.table(
  dropped_mun = character(),
  coef = numeric(),
  se = numeric()
)

for (mc in treated_munis_codes) {
  panel_loo <- panel[mun_code != mc]
  m_loo <- feols(nw_share ~ treat_post | mun_code_num + year,
                 data = panel_loo, cluster = ~mun_code_num)
  loo_results <- rbind(loo_results, data.table(
    dropped_mun = mc,
    coef = coef(m_loo)["treat_post"],
    se = sqrt(vcov(m_loo)["treat_post", "treat_post"])
  ))
}

cat("Leave-one-out results (NW share):\n")
cat(sprintf("  Full sample: %.5f\n", actual_coef))
cat(sprintf("  LOO range:   [%.5f, %.5f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  LOO mean:    %.5f\n", mean(loo_results$coef)))

# -------------------------------------------------------------------
# 5. Alternative treatment timing (2018 vs 2019)
# -------------------------------------------------------------------
cat("\n--- Alternative treatment timing ---\n")

panel[, post_2018 := as.integer(year >= 2018)]
panel[, tp_2018 := treated * post_2018]

m_alt <- feols(nw_share ~ tp_2018 | mun_code_num + year,
               data = panel, cluster = ~mun_code_num)
cat("Treatment starting 2018 (vs 2019 baseline):\n")
print(summary(m_alt))
panel[, c("post_2018", "tp_2018") := NULL]

# -------------------------------------------------------------------
# 6. Restrict to urban municipalities (population > 20,000)
# -------------------------------------------------------------------
cat("\n--- Urban municipalities only ---\n")

pop_2018 <- panel[year == 2018, .(total_2018 = total), by = mun_code]
urban_munis <- pop_2018[total_2018 > 20000]$mun_code

m_urban <- feols(nw_share ~ treat_post | mun_code_num + year,
                 data = panel[mun_code %in% urban_munis],
                 cluster = ~mun_code_num)
cat(sprintf("Urban only (%d municipalities):\n", length(urban_munis)))
print(summary(m_urban))

# -------------------------------------------------------------------
# 7. Save robustness results
# -------------------------------------------------------------------
rob_results <- list(
  ri_pval = ri_pval,
  ri_coefs = ri_coefs,
  placebo_coef = coef(m_placebo)["treat_post"],
  placebo_pval = summary(m_placebo)$coeftable["treat_post", "Pr(>|t|)"],
  loo_range = c(min(loo_results$coef), max(loo_results$coef)),
  loo_mean = mean(loo_results$coef),
  alt_timing_coef = coef(m_alt)["tp_2018"],
  urban_coef = coef(m_urban)["treat_post"]
)

saveRDS(rob_results, "data/robustness_results.rds")
saveRDS(loo_results, "data/loo_results.rds")
saveRDS(m_placebo, "data/m_placebo.rds")
saveRDS(m_urban, "data/m_urban.rds")

cat("\n=== Robustness checks complete ===\n")
