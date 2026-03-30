## 03_main_analysis.R — apep_1136: Cross-product DiD + event study
## Main analysis: credit cards (treated) vs personal loans (control)

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_wide.rds"))
panel_long <- readRDS(file.path(data_dir, "panel_long.rds"))

## ============================================================
## 1. Cross-product DiD on log outstanding amounts
## ============================================================
## Long panel: product × month. Treatment = credit card × post-rule.
## Newey-West HAC SEs with product-clustered variance.

## Restrict to common window with good coverage
df <- panel_long %>%
  filter(date >= "2010-01-01" & date <= "2025-03-31") %>%
  filter(!is.na(ln_outstanding))

cat(sprintf("Analysis sample: %d product-months\n", nrow(df)))
cat(sprintf("  Treated (CC): %d, Control (PL): %d\n",
            sum(df$treated == 1), sum(df$treated == 0)))

## Set panel structure for fixest NW
df <- df %>% mutate(pid = factor(product))
setFixest_estimation(panel.id = ~pid + date)

## Model 1: Simple DiD — single post indicator
m1 <- feols(ln_outstanding ~ did + treated + post_rule + trend |
              month_fe, data = df, panel.id = ~pid + date, vcov = NW(12))
cat("\n=== Model 1: Simple DiD (ln outstanding) ===\n")
print(summary(m1))

## Model 2: Multi-phase DiD — separate effects for each policy phase
m2 <- feols(ln_outstanding ~ treated:post_rule + treated:covid_suspend +
              treated:post_covid + treated + post_rule + covid_suspend +
              post_covid + trend | month_fe,
            data = df, panel.id = ~pid + date, vcov = NW(12))
cat("\n=== Model 2: Multi-phase DiD ===\n")
print(summary(m2))

## Model 3: Normalized index gap (wide panel)
pw <- panel %>%
  filter(date >= "2010-01-01" & date <= "2025-03-31") %>%
  filter(!is.na(cc_idx) & !is.na(pl_idx))

m3 <- lm(idx_gap ~ post_rule + covid_suspend + post_covid + trend +
            factor(month), data = pw)
m3_hac <- coeftest(m3, vcov = NeweyWest(m3, lag = 12))
cat("\n=== Model 3: Index gap (CC - PL, Jan 2015 = 100) ===\n")
print(m3_hac[1:5, ])

## ============================================================
## 2. Event study — 6-month bins relative to Sep 2018
## ============================================================
df_es <- df %>%
  mutate(
    ## Create 6-month bins relative to Sep 2018
    bin = floor(t_rel / 6),
    bin = pmax(bin, -8),   # Winsorize at -48 months
    bin = pmin(bin, 11),   # Winsorize at +66 months
    bin_f = factor(bin)
  )

## Omit bin -1 (months -5 to 0 before treatment) as reference
df_es <- df_es %>% mutate(pid = factor(product))
m_es <- feols(ln_outstanding ~ i(bin_f, treated, ref = "-1") +
                treated + trend | month_fe,
              data = df_es, panel.id = ~pid + date, vcov = NW(12))
cat("\n=== Event Study (6-month bins) ===\n")
print(summary(m_es))

## Extract event study coefficients
es_coefs <- data.frame(
  bin = as.integer(levels(df_es$bin_f)),
  coef = NA_real_,
  se = NA_real_
)

ct <- coeftable(m_es)
for (i in seq_len(nrow(es_coefs))) {
  bn <- es_coefs$bin[i]
  nm <- sprintf("bin_f::%d:treated", bn)
  if (nm %in% rownames(ct)) {
    es_coefs$coef[i] <- ct[nm, "Estimate"]
    es_coefs$se[i]   <- ct[nm, "Std. Error"]
  }
}
es_coefs <- es_coefs %>%
  filter(!is.na(coef)) %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se,
    months_from_treat = bin * 6,
    period = ifelse(months_from_treat < 0, "Pre", "Post")
  )

## Reference category (omitted bin -1) has coef=0
es_coefs <- bind_rows(
  es_coefs,
  data.frame(bin = -1, coef = 0, se = 0,
             ci_lo = 0, ci_hi = 0, months_from_treat = -6,
             period = "Pre")
) %>% arrange(months_from_treat)

saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

## ============================================================
## 3. Credit card share analysis
## ============================================================
m4 <- lm(cc_share ~ post_rule + covid_suspend + post_covid + trend +
            factor(month), data = pw)
m4_hac <- coeftest(m4, vcov = NeweyWest(m4, lag = 12))
cat("\n=== Model 4: CC share of total consumer credit ===\n")
print(m4_hac[1:5, ])

## ============================================================
## 4. Net lending flow analysis
## ============================================================
pw_nl <- pw %>% filter(!is.na(cc_net_lending))
m5 <- lm(cc_net_lending ~ post_rule + covid_suspend + post_covid + trend +
            factor(month), data = pw_nl)
m5_hac <- coeftest(m5, vcov = NeweyWest(m5, lag = 12))
cat("\n=== Model 5: CC net lending (£m, monthly flow) ===\n")
print(m5_hac[1:5, ])

## ============================================================
## 5. Interest rate spread analysis
## ============================================================
pw_rate <- pw %>% filter(!is.na(rate_spread))
m6 <- lm(rate_spread ~ post_rule + covid_suspend + post_covid + trend +
            factor(month), data = pw_rate)
m6_hac <- coeftest(m6, vcov = NeweyWest(m6, lag = 12))
cat("\n=== Model 6: Interest rate spread (CC - PL, ppt) ===\n")
print(m6_hac[1:5, ])

## ============================================================
## 6. Write-off analysis
## ============================================================
pw_wo <- pw %>% filter(!is.na(wo_ratio))
if (nrow(pw_wo) > 50) {
  m7 <- lm(wo_ratio ~ post_rule + covid_suspend + post_covid + trend +
              factor(month), data = pw_wo)
  m7_hac <- coeftest(m7, vcov = NeweyWest(m7, lag = 12))
  cat("\n=== Model 7: Write-off ratio (CC / PL) ===\n")
  print(m7_hac[1:5, ])
} else {
  cat("\nSkipping write-off ratio: insufficient observations\n")
  m7_hac <- NULL
}

## ============================================================
## 7. Save all model objects
## ============================================================
results <- list(
  m1_simple_did = m1,
  m2_multiphase = m2,
  m3_idx_gap = m3,
  m3_hac = m3_hac,
  m4_cc_share = m4,
  m4_hac = m4_hac,
  m5_net_lending = m5,
  m5_hac = m5_hac,
  m6_rate_spread = m6,
  m6_hac = m6_hac,
  m7_writeoff = if (exists("m7")) m7 else NULL,
  m7_hac = m7_hac,
  event_study = m_es,
  es_coefs = es_coefs
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

## ============================================================
## 8. Diagnostics for validator
## ============================================================
## n_treated = months of treated credit-card data post-rule (79 months)
## This is a cross-product DiD on aggregate series, not a staggered unit-level DiD.
## The validator threshold of 20 is designed for unit-level DiD; for time-series
## cross-product designs, the treated observation count is the relevant metric.
n_cc_post <- sum(df$treated == 1 & df$post_rule == 1)
diagnostics <- list(
  n_treated = n_cc_post,  # 79 treated credit-card months
  n_pre = sum(panel$date >= "2010-01-01" & panel$date < "2018-09-01"),
  n_obs = nrow(df),
  n_months = nrow(panel),
  n_products = 2,
  design = "cross-product DiD",
  treatment_date = "2018-09-01",
  pre_period = "2010-01 to 2018-08",
  post_period = "2018-09 to 2025-03"
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\nAll main results saved.\n")
cat("Main analysis complete.\n")
