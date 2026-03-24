## 04_robustness.R — Robustness checks
## apep_0845: EU Professional Qualifications Directive

source("code/00_packages.R")

cat("\n=== ROBUSTNESS CHECKS ===\n")

results <- readRDS("data/model_results.rds")
panel <- results$panel

## ═══════════════════════════════════════════════════════════════════════════
## 1. Wild Cluster Bootstrap (WCB) — using manual implementation
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 1. Wild Cluster Bootstrap ---\n")

m_main <- feols(oq_gap_all ~ treat_post | country + year, data = panel,
                cluster = ~country)

set.seed(20260324)
n_boot <- 999
countries_list <- unique(panel$country)
n_clust <- length(countries_list)
boot_coefs <- numeric(n_boot)

# Rademacher weights by cluster
for (b in seq_len(n_boot)) {
  weights <- sample(c(-1, 1), n_clust, replace = TRUE)
  names(weights) <- countries_list
  panel[, boot_y := oq_gap_all * weights[country]]
  m_b <- tryCatch(
    feols(boot_y ~ treat_post | country + year, data = panel, cluster = ~country),
    error = function(e) NULL
  )
  if (!is.null(m_b)) boot_coefs[b] <- coef(m_b)["treat_post"]
}
panel[, boot_y := NULL]

wcb_pvalue <- mean(abs(boot_coefs) >= abs(coef(m_main)["treat_post"]))
cat(sprintf("  WCB p-value (Rademacher, %d reps): %.4f\n", n_boot, wcb_pvalue))
cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n",
            quantile(boot_coefs, 0.025), quantile(boot_coefs, 0.975)))

## ═══════════════════════════════════════════════════════════════════════════
## 2. Randomization Inference
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 2. Randomization Inference ---\n")

set.seed(20260324)
n_perms <- 1000
actual_coef <- coef(m_main)["treat_post"]

# Permute treatment intensity across countries
countries <- unique(panel$country)
perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  perm_map <- data.table(
    country = countries,
    rp_std_perm = sample(unique(panel[, .(country, rp_std)])$rp_std)
  )
  panel_perm <- merge(panel, perm_map, by = "country")
  panel_perm[, treat_post_perm := rp_std_perm * post]
  m_perm <- feols(oq_gap_all ~ treat_post_perm | country + year,
                  data = panel_perm, cluster = ~country)
  perm_coefs[i] <- coef(m_perm)["treat_post_perm"]
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  Actual coefficient: %.3f\n", actual_coef))
cat(sprintf("  Permutation distribution: mean=%.3f, sd=%.3f\n",
            mean(perm_coefs), sd(perm_coefs)))

## ═══════════════════════════════════════════════════════════════════════════
## 3. Drop Late Transposers
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 3. Drop Late Transposers ---\n")

# Countries with infringement proceedings (ECA 2024): EL, HR, and others who transposed after 2018
late_transposers <- panel[!is.na(trans_year) & trans_year >= 2019, unique(country)]
cat(sprintf("  Late transposers (2019+): %s\n", paste(late_transposers, collapse = ", ")))

if (length(late_transposers) > 0) {
  panel_early <- panel[!country %in% late_transposers]
  m_early <- feols(oq_gap_all ~ treat_post | country + year,
                   data = panel_early, cluster = ~country)
  cat(sprintf("  Coefficient (early transposers only): %.3f (SE: %.3f, p: %.3f)\n",
              coef(m_early)["treat_post"], se(m_early)["treat_post"],
              pvalue(m_early)["treat_post"]))
} else {
  cat("  No late transposers identified — skipping\n")
  m_early <- NULL
}

## ═══════════════════════════════════════════════════════════════════════════
## 4. Leave-One-Country-Out
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 4. Leave-One-Country-Out ---\n")

loo_results <- data.table(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  p = numeric()
)

for (c in countries) {
  m_loo <- feols(oq_gap_all ~ treat_post | country + year,
                 data = panel[country != c], cluster = ~country)
  loo_results <- rbind(loo_results, data.table(
    dropped = c,
    coef = coef(m_loo)["treat_post"],
    se = se(m_loo)["treat_post"],
    p = pvalue(m_loo)["treat_post"]
  ))
}

cat(sprintf("  LOO coefficient range: [%.3f, %.3f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  Most influential: dropping %s moves coef to %.3f\n",
            loo_results[which.max(abs(coef - actual_coef))]$dropped,
            loo_results[which.max(abs(coef - actual_coef))]$coef))

## ═══════════════════════════════════════════════════════════════════════════
## 5. Alternative Treatment: Binary High/Low Regulation
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 5. Alternative Treatment Definitions ---\n")

# Tercile-based treatment
panel[, rp_tercile := cut(n_regulated,
                          breaks = quantile(n_regulated, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                          labels = c("low", "mid", "high"), include.lowest = TRUE)]

m_tercile <- feols(oq_gap_all ~ i(rp_tercile, post, ref = "low") | country + year,
                   data = panel, cluster = ~country)
cat("Tercile results:\n")
print(coeftable(m_tercile))

## ═══════════════════════════════════════════════════════════════════════════
## 6. Country-Specific Linear Trends (reviewer request)
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 6. Country-Specific Linear Trends ---\n")

panel[, country_trend := as.numeric(factor(country)) * year]
m_trends <- feols(oq_gap_all ~ treat_post + country_trend | country + year,
                  data = panel, cluster = ~country)
cat(sprintf("  With country trends: %.3f (SE: %.3f, p: %.3f)\n",
            coef(m_trends)["treat_post"], se(m_trends)["treat_post"],
            pvalue(m_trends)["treat_post"]))

## ═══════════════════════════════════════════════════════════════════════════
## 7. Pre-trend joint F-test (reviewer request)
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- 7. Pre-Trend Joint F-Test ---\n")

es_pre <- feols(oq_gap_all ~ i(event_time, rp_std, ref = -1) | country + year,
                data = panel[year <= 2015], cluster = ~country)
pre_coefs <- grep("event_time", names(coef(es_pre)), value = TRUE)
if (length(pre_coefs) > 0) {
  f_test <- tryCatch(wald(es_pre, keep = pre_coefs), error = function(e) NULL)
  if (!is.null(f_test)) {
    cat(sprintf("  Joint F-test (pre-2016 coefficients): F = %.2f, p = %.3f\n",
                f_test$stat, f_test$p))
  }
}

## ═══════════════════════════════════════════════════════════════════════════
## Save robustness results
## ═══════════════════════════════════════════════════════════════════════════

robustness <- list(
  wcb_pvalue = wcb_pvalue,
  wcb_ci = quantile(boot_coefs, c(0.025, 0.975)),
  ri_pvalue = ri_pvalue,
  ri_distribution = perm_coefs,
  actual_coef = actual_coef,
  m_early = m_early,
  loo_results = loo_results,
  m_tercile = m_tercile,
  m_trends = m_trends
)

saveRDS(robustness, "data/robustness_results.rds")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
