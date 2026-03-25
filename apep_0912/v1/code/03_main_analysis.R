## ── 03_main_analysis.R ───────────────────────────────────────────
## Main DiD estimation: within-market across-commodity price effects
## of India's July 2023 rice export ban
## ──────────────────────────────────────────────────────────────────

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
ban_ym <- 202307

## ── 1. Main Specification: Triple-DiD ───────────────────────────

cat("=== Main Specifications ===\n")

# Specification 1: Simple Rice × Post (pooled)
m1 <- feols(log_price ~ rice_post | market_key + ym, data = panel,
            cluster = ~country)
cat("\n--- Model 1: Rice × Post (market + time FE) ---\n")
cat("Coef:", round(coef(m1)["rice_post"], 4),
    "SE:", round(se(m1)["rice_post"], 4),
    "p:", round(pvalue(m1)["rice_post"], 4), "\n")

# Specification 2: Triple-DiD (market + time FE)
m2 <- feols(log_price ~ rice_post_intensity + rice_post |
              market_key + ym,
            data = panel, cluster = ~country)
cat("\n--- Model 2: Triple-DiD (market + time FE) ---\n")
print(summary(m2))

# Specification 3: Market×Time FE + Commodity FE
m3 <- feols(log_price ~ rice_post_intensity + rice_post |
              mkt_ym + commodity,
            data = panel, cluster = ~country)
cat("\n--- Model 3: Market×Time + Commodity FE ---\n")
print(summary(m3))

# Specification 4: Market×Time + Country×Commodity FE (preferred)
panel[, country_commodity := paste0(country, "_", commodity)]
m4 <- feols(log_price ~ rice_post_intensity |
              mkt_ym + country_commodity,
            data = panel, cluster = ~country)
cat("\n--- Model 4: Market×Time + Country×Commodity FE (preferred) ---\n")
print(summary(m4))

## ── 2. Event Study ──────────────────────────────────────────────
## Use market + commodity FE (not market×time) to allow time variation

cat("\n=== Event Study ===\n")

# Monthly event time relative to July 2023
# Bin into 3-month quarters for cleaner estimates
panel[, event_q := floor(event_month / 3)]
panel[, event_q_trim := pmax(pmin(event_q, 8), -8)]

# Event study: interact event-time dummies with rice indicator
# Country×Commodity FE absorb level differences
# Market FE absorb market-specific levels
es_model <- feols(log_price ~ i(event_q_trim, i.rice, ref = -1) |
                    market_key + ym + country_commodity,
                  data = panel, cluster = ~country)
cat("Event study (Rice vs Control, all countries):\n")
print(summary(es_model))

# Event study with treatment intensity
# Use market + year-month + commodity FE (not market×time)
es_intensity <- feols(log_price ~ i(event_q_trim, india_share, ref = -1):rice |
                        market_key + ym + commodity,
                      data = panel, cluster = ~country)
cat("\nEvent study (intensity, rice×india_share×event_q):\n")
print(summary(es_intensity))

# Extract event study coefficients for the rice==1 interactions
es_coefs <- as.data.table(coeftable(es_model), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
es_coefs[, event_q := as.integer(gsub(".*::", "", gsub(":rice::1", "", term)))]
es_coefs <- es_coefs[grepl("rice::1", term)]
es_coefs <- es_coefs[!is.na(event_q)][order(event_q)]

cat("\nEvent study coefficients (Rice indicator):\n")
print(es_coefs[, .(event_q, estimate = round(estimate, 4),
                    se = round(se, 4), pval = round(pval, 3))])

## ── 3. Heterogeneity Analysis ───────────────────────────────────

cat("\n=== Heterogeneity ===\n")

# 3a. High vs Low dependence (sample split)
dep_median <- median(panel[india_share > 0]$india_share)
panel[, high_dep := as.integer(india_share > dep_median)]

m_high <- feols(log_price ~ rice_post | mkt_ym + commodity,
                data = panel[high_dep == 1], cluster = ~country)
m_low <- feols(log_price ~ rice_post | mkt_ym + commodity,
               data = panel[high_dep == 0], cluster = ~country)

cat("\nHigh India dependence (share >", round(dep_median, 2), "):\n")
cat("  Coef:", round(coef(m_high)["rice_post"], 4),
    "SE:", round(se(m_high)["rice_post"], 4),
    "N:", nobs(m_high), "\n")

cat("Low India dependence:\n")
cat("  Coef:", round(coef(m_low)["rice_post"], 4),
    "SE:", round(se(m_low)["rice_post"], 4),
    "N:", nobs(m_low), "\n")

# 3b. By region
panel[, region := countrycode(country, "iso3c", "region", warn = FALSE)]
region_tab <- panel[, .(n = .N, n_countries = uniqueN(country),
                         mean_dep = round(mean(india_share), 3)),
                     by = region]
cat("\nRegions in sample:\n")
print(region_tab)

## ── 4. Placebo Tests ────────────────────────────────────────────

cat("\n=== Placebo Tests ===\n")

# 4a. Exporter placebo: rice-exporting countries should see ~0
exporters <- c("THA", "VNM", "PAK", "MMR", "KHM")
panel[, is_exporter := country %in% exporters]
n_exp <- sum(panel$is_exporter)

if (n_exp > 100) {
  m_exp <- feols(log_price ~ rice_post | market_key + ym + commodity,
                 data = panel[is_exporter == TRUE], cluster = ~country)
  cat("Exporter placebo (should be ~0):\n")
  cat("  Coef:", round(coef(m_exp)["rice_post"], 4),
      "SE:", round(se(m_exp)["rice_post"], 4), "N:", n_exp, "\n")
} else {
  cat("Insufficient exporter data (N=", n_exp, ").\n")
  m_exp <- NULL
}

# 4b. Pre-ban placebo: fake treatment at Jan 2022
panel_pre <- copy(panel[ym < ban_ym])
panel_pre[, fake_post := as.integer(ym >= 202201)]
panel_pre[, fake_rice_post := rice * fake_post]
panel_pre[, fake_intensity := rice * fake_post * india_share]

m_plac <- feols(log_price ~ fake_intensity + fake_rice_post |
                  market_key + ym + commodity,
                data = panel_pre, cluster = ~country)
cat("\nPre-ban placebo (fake treatment Jan 2022):\n")
cat("  Intensity:", round(coef(m_plac)["fake_intensity"], 4),
    "SE:", round(se(m_plac)["fake_intensity"], 4), "\n")
cat("  Rice×Post:", round(coef(m_plac)["fake_rice_post"], 4),
    "SE:", round(se(m_plac)["fake_rice_post"], 4), "\n")

# 4c. Reversal: October 2024 partial lifting
panel[, post_rev := as.integer(ym >= 202410)]
panel[, rice_rev := rice * post_rev]
panel[, rice_rev_int := rice * post_rev * india_share]

m_rev <- feols(log_price ~ rice_post_intensity + rice_rev_int +
                 rice_post + rice_rev |
                 mkt_ym + commodity,
               data = panel, cluster = ~country)
cat("\nReversal test (Oct 2024):\n")
print(summary(m_rev))

## ── 5. Summary Statistics Table Data ────────────────────────────

cat("\n=== Summary Statistics ===\n")

# Pre-ban rice prices
pre_rice <- panel[post == 0 & rice == 1]
post_rice <- panel[post == 1 & rice == 1]
pre_ctrl <- panel[post == 0 & rice == 0]
post_ctrl <- panel[post == 1 & rice == 0]

sumstats <- data.table(
  Variable = c("USD Price (Rice, Pre-Ban)", "USD Price (Rice, Post-Ban)",
                "USD Price (Control, Pre-Ban)", "USD Price (Control, Post-Ban)",
                "India Import Share", "Log Price"),
  Mean = c(mean(pre_rice$usdprice), mean(post_rice$usdprice),
           mean(pre_ctrl$usdprice), mean(post_ctrl$usdprice),
           mean(panel$india_share), mean(panel$log_price)),
  SD = c(sd(pre_rice$usdprice), sd(post_rice$usdprice),
         sd(pre_ctrl$usdprice), sd(post_ctrl$usdprice),
         sd(panel$india_share), sd(panel$log_price)),
  N = c(nrow(pre_rice), nrow(post_rice),
        nrow(pre_ctrl), nrow(post_ctrl),
        nrow(panel), nrow(panel))
)
cat("\n")
print(sumstats[, .(Variable, Mean = round(Mean, 3), SD = round(SD, 3), N)])

# SD of Y for SDE calculation
sd_y_pre <- sd(panel[post == 0]$log_price)
cat("\nSD of log_price (pre-ban):", round(sd_y_pre, 4), "\n")

## ── 6. Store Results ────────────────────────────────────────────

results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4,
  es_model = es_model, es_intensity = es_intensity, es_coefs = es_coefs,
  m_high = m_high, m_low = m_low,
  m_plac = m_plac, m_rev = m_rev,
  m_exp = m_exp,
  sumstats = sumstats,
  sd_y_pre = sd_y_pre,
  dep_median = dep_median
)
saveRDS(results, "data/main_results.rds")
cat("\nResults saved to data/main_results.rds\n")

## ── 7. Write diagnostics.json ───────────────────────────────────

diagnostics <- list(
  n_treated = uniqueN(panel[india_share > 0.10]$country),
  n_pre = uniqueN(panel[post == 0]$ym),
  n_obs = nrow(panel),
  n_countries = uniqueN(panel$country),
  n_markets = uniqueN(panel$market_key),
  n_rice_obs = sum(panel$rice == 1),
  n_control_obs = sum(panel$rice == 0),
  main_coef = round(coef(m4)["rice_post_intensity"], 4),
  main_se = round(se(m4)["rice_post_intensity"], 4)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved to data/diagnostics.json\n")
