## ── 04_robustness.R ──────────────────────────────────────────────
## Robustness checks for India rice export ban analysis
## ──────────────────────────────────────────────────────────────────

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
ban_ym <- 202307
panel[, country_commodity := paste0(country, "_", commodity)]

cat("=== Robustness Checks ===\n")

## ── 1. Alternative Clustering ───────────────────────────────────

# Main: clustered at country
r_country <- feols(log_price ~ rice_post_intensity |
                     mkt_ym + country_commodity,
                   data = panel, cluster = ~country)

# Alt 1: two-way clustering (country + year-month)
r_twoway <- feols(log_price ~ rice_post_intensity |
                    mkt_ym + country_commodity,
                  data = panel, cluster = ~country + ym)

# Alt 2: market-level clustering
r_market <- feols(log_price ~ rice_post_intensity |
                    mkt_ym + country_commodity,
                  data = panel, cluster = ~market_key)

cat("Clustering comparison:\n")
cat("  Country:     ", round(coef(r_country), 4), "(",
    round(se(r_country), 4), ")\n")
cat("  Two-way:     ", round(coef(r_twoway), 4), "(",
    round(se(r_twoway), 4), ")\n")
cat("  Market:      ", round(coef(r_market), 4), "(",
    round(se(r_market), 4), ")\n")

## ── 2. Wild Cluster Bootstrap ───────────────────────────────────

cat("\n=== Wild Cluster Bootstrap ===\n")

# Wild cluster bootstrap requires singleton-free model
# Use simpler FE structure: market + ym + commodity (no singletons)
r_simple <- feols(log_price ~ rice_post_intensity + rice_post |
                    market_key + ym + commodity,
                  data = panel, cluster = ~country)

if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  tryCatch({
    boot_res <- boottest(r_simple, param = "rice_post_intensity",
                          B = 999, clustid = "country", type = "webb")
    cat("Bootstrap p-value:", round(boot_res$p_val, 4), "\n")
    cat("Bootstrap CI:", round(boot_res$conf_int, 4), "\n")
  }, error = function(e) {
    cat("Bootstrap failed:", conditionMessage(e), "\n")
    cat("Proceeding with analytical SEs.\n")
  })
} else {
  cat("fwildclusterboot not available. Skipping.\n")
}

## ── 3. Exclude Top/Bottom Price Outliers ────────────────────────

cat("\n=== Outlier Robustness ===\n")

# Trim top/bottom 1% of USD prices
q01 <- quantile(panel$usdprice, 0.01, na.rm = TRUE)
q99 <- quantile(panel$usdprice, 0.99, na.rm = TRUE)
panel_trim <- panel[usdprice >= q01 & usdprice <= q99]

r_trim <- feols(log_price ~ rice_post_intensity |
                  mkt_ym + country_commodity,
                data = panel_trim, cluster = ~country)
cat("Trimmed (1-99%):", round(coef(r_trim), 4), "(",
    round(se(r_trim), 4), ") N=", nobs(r_trim), "\n")

## ── 4. Control for Commodity-Specific Trends ────────────────────

cat("\n=== Commodity Trend Controls ===\n")

# Add commodity × linear time trend
panel[, time_trend := (year - 2021) * 12 + month]
panel[, commodity_trend := paste0(commodity, "_trend")]

r_trend <- feols(log_price ~ rice_post_intensity + commodity:time_trend |
                   mkt_ym + country_commodity,
                 data = panel, cluster = ~country)
cat("With commodity trends:", round(coef(r_trend)["rice_post_intensity"], 4),
    "(", round(se(r_trend)["rice_post_intensity"], 4), ")\n")

## ── 5. Continuous Treatment Intensity Bins ──────────────────────

cat("\n=== Treatment Intensity Bins ===\n")

# Create quartile bins of India share (among countries with share > 0)
panel[india_share > 0, dep_q := cut(india_share,
                                     breaks = quantile(india_share, c(0, 0.25, 0.5, 0.75, 1)),
                                     labels = c("Q1", "Q2", "Q3", "Q4"),
                                     include.lowest = TRUE)]
panel[india_share == 0, dep_q := "Zero"]

for (q in c("Q1", "Q2", "Q3", "Q4", "Zero")) {
  sub <- panel[dep_q == q]
  if (nrow(sub) > 100 && uniqueN(sub$country) > 1) {
    r_q <- feols(log_price ~ rice_post | mkt_ym + commodity,
                 data = sub, cluster = ~country)
    cat("  ", q, ": Coef=", round(coef(r_q)["rice_post"], 4),
        "SE=", round(se(r_q)["rice_post"], 4),
        "Countries=", uniqueN(sub$country), "\n")
  }
}

## ── 6. Leave-One-Country-Out ────────────────────────────────────

cat("\n=== Leave-One-Country-Out ===\n")

countries <- unique(panel$country)
loo_coefs <- numeric(length(countries))
names(loo_coefs) <- countries

for (i in seq_along(countries)) {
  sub <- panel[country != countries[i]]
  r_loo <- feols(log_price ~ rice_post_intensity |
                   mkt_ym + country_commodity,
                 data = sub, cluster = ~country)
  loo_coefs[i] <- coef(r_loo)["rice_post_intensity"]
}

cat("Leave-one-out range:", round(range(loo_coefs), 4), "\n")
cat("Leave-one-out mean:", round(mean(loo_coefs), 4), "\n")
cat("Most influential countries (largest deviation from full sample):\n")
deviations <- abs(loo_coefs - coef(r_country)["rice_post_intensity"])
top_devs <- sort(deviations, decreasing = TRUE)[1:5]
for (c in names(top_devs)) {
  cat("  Without", c, ":", round(loo_coefs[c], 4),
      "(deviation:", round(top_devs[c], 4), ")\n")
}

## ── 7. Store Robustness Results ─────────────────────────────────

rob_results <- list(
  r_country = r_country, r_twoway = r_twoway, r_market = r_market,
  r_trim = r_trim, r_trend = r_trend,
  loo_coefs = loo_coefs
)
saveRDS(rob_results, "data/robustness_results.rds")
cat("\nRobustness results saved.\n")
