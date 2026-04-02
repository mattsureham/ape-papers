## 04_robustness.R — Robustness checks for Nigeria cashless policy paper
## APEP Working Paper apep_1323

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== Robustness Checks ===\n")

## ============================================================
## 1. LEAVE-ONE-OUT: Drop each control country
## ============================================================
cat("\n--- Leave-one-out (Branches per 100k) ---\n")

controls <- unique(panel$country[panel$country != "NG"])
loo_results <- data.frame(
  dropped = character(), estimate = numeric(), se = numeric(),
  pvalue = numeric(), stringsAsFactors = FALSE
)

for (cc in controls) {
  panel_loo <- panel %>% filter(country != cc)
  fit <- feols(
    branches_per_100k ~ treat | country_id + year,
    data = panel_loo, cluster = ~country_id
  )
  loo_results <- bind_rows(loo_results, data.frame(
    dropped = cc,
    estimate = coef(fit)["treat"],
    se = se(fit)["treat"],
    pvalue = pvalue(fit)["treat"]
  ))
}

cat("Leave-one-out estimates (branches per 100k):\n")
loo_results <- loo_results %>%
  mutate(sig = ifelse(pvalue < 0.05, "**", ifelse(pvalue < 0.1, "*", "")))
print(loo_results)

cat(sprintf("\nRange: [%.3f, %.3f], all negative: %s\n",
            min(loo_results$estimate), max(loo_results$estimate),
            ifelse(all(loo_results$estimate < 0), "YES", "NO")))

## ============================================================
## 2. RESTRICT TO 2008-2018 (drop COVID years)
## ============================================================
cat("\n--- Restricted sample: 2008-2018 ---\n")

panel_r <- panel %>% filter(year >= 2008, year <= 2018)

m_br_r <- feols(
  branches_per_100k ~ treat | country_id + year,
  data = panel_r, cluster = ~country_id
)
cat("Branches per 100k (2008-2018):\n")
print(summary(m_br_r))

m_atm_r <- feols(
  atm_per_100k ~ treat | country_id + year,
  data = panel_r, cluster = ~country_id
)
cat("ATMs per 100k (2008-2018):\n")
print(summary(m_atm_r))

## ============================================================
## 3. DROP LAGOS-EFFECT YEAR (2012 is Wave 1 = Lagos only)
## ============================================================
## If the branch decline is driven by Lagos pilot only, redefining
## treatment start to 2013 (Wave 2, nationwide expansion) should weaken results
cat("\n--- Alternative treatment timing: 2013 (Wave 2) ---\n")

panel_w2 <- panel %>%
  mutate(
    post_w2 = as.integer(year >= 2013),
    treat_w2 = nigeria * post_w2
  )

m_br_w2 <- feols(
  branches_per_100k ~ treat_w2 | country_id + year,
  data = panel_w2, cluster = ~country_id
)
cat("Branches per 100k (treatment = 2013+):\n")
print(summary(m_br_w2))

## ============================================================
## 4. PLACEBO OUTCOME: GDP growth (should NOT be affected)
## ============================================================
cat("\n--- Placebo: GDP growth ---\n")

m_gdp <- feols(
  gdp_growth ~ treat | country_id + year,
  data = panel, cluster = ~country_id
)
cat("GDP growth placebo:\n")
print(summary(m_gdp))

## ============================================================
## 5. PLACEBO TIMING: Treatment in 2009 (pre-policy)
## ============================================================
cat("\n--- Placebo timing: Treatment in 2009 ---\n")

panel_pt <- panel %>%
  filter(year <= 2011) %>%  # Only pre-treatment period
  mutate(
    placebo_post = as.integer(year >= 2009),
    placebo_treat = nigeria * placebo_post
  )

m_br_pt <- feols(
  branches_per_100k ~ placebo_treat | country_id + year,
  data = panel_pt, cluster = ~country_id
)
cat("Branches per 100k (placebo 2009):\n")
print(summary(m_br_pt))

## ============================================================
## 6. ALTERNATIVE CLUSTERING
## ============================================================
cat("\n--- Alternative inference: HC1 (no clustering) ---\n")

m_br_hc <- feols(
  branches_per_100k ~ treat | country_id + year,
  data = panel, vcov = "hetero"
)
cat("Branches per 100k (heteroskedasticity-robust SE):\n")
print(summary(m_br_hc))

## ============================================================
## 7. INTERNET + MOBILE AS MECHANISM
## ============================================================
cat("\n--- Mechanism: Internet and Mobile Subscriptions ---\n")

m_internet <- feols(
  internet_pct ~ treat | country_id + year,
  data = panel, cluster = ~country_id
)
cat("Internet users (%):\n")
print(summary(m_internet))

m_mobile <- feols(
  mobile_subs ~ treat | country_id + year,
  data = panel, cluster = ~country_id
)
cat("Mobile subscriptions per 100:\n")
print(summary(m_mobile))

## ============================================================
## Save all robustness results
## ============================================================

robustness <- list(
  loo = loo_results,
  restricted = list(branches = m_br_r, atm = m_atm_r),
  wave2 = m_br_w2,
  placebo_gdp = m_gdp,
  placebo_timing = m_br_pt,
  hc_robust = m_br_hc,
  internet = m_internet,
  mobile = m_mobile
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
