## 04_robustness.R — Robustness checks
## APEP-0991: EU Landing Obligation

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results.rds")

cat("=== Robustness Checks ===\n")

# Create post indicator (same as main)
panel <- panel %>%
  mutate(
    post = as.integer(is_eu & year >= treat_year),
    rel_year = if_else(is_eu, year - treat_year, NA_real_)
  )

# ======================================================================
# 1. Pre-trend test: event study using full panel with demersal interaction
# ======================================================================
cat("\n--- 1. Event Study for Demersal ---\n")

# Use full EU panel — demersal rel_year interacted with demersal indicator
# Non-demersal units and year FE absorb common trends
panel_es <- panel %>%
  filter(is_eu) %>%
  mutate(
    is_demersal = as.integer(treatment_group == "demersal"),
    # Relative year: for all EU units based on their group's treatment year
    rel_year = year - treat_year,
    # Cap at reasonable window
    rel_year_capped = pmax(pmin(rel_year, 8), -10)
  )

es_demersal <- feols(
  log_catch ~ i(rel_year_capped, is_demersal, ref = -1) | unit_num + year,
  data = panel_es,
  cluster = ~country
)
cat("Event study — demersal catches (interacted with full panel):\n")
summary(es_demersal)

# ======================================================================
# 2. Wild cluster bootstrap (few clusters)
# ======================================================================
cat("\n--- 2. Wild Cluster Bootstrap ---\n")

# Main demersal specification with WCB
demersal <- panel %>% filter(treatment_group == "demersal")
twfe_demersal_wcb <- feols(
  log_catch ~ post | unit_num + year,
  data = demersal,
  cluster = ~country
)

# Use boottest from fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_result <- boottest(
    twfe_demersal_wcb,
    param = "post",
    clustid = ~country,
    B = 9999,
    type = "rademacher"
  )
  cat("Wild cluster bootstrap for demersal post coefficient:\n")
  print(summary(boot_result))
  wcb_pval <- boot_result$p_val
} else {
  cat("fwildclusterboot not available. Installing...\n")
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  library(fwildclusterboot)
  boot_result <- boottest(
    twfe_demersal_wcb,
    param = "post",
    clustid = ~country,
    B = 9999,
    type = "rademacher"
  )
  cat("Wild cluster bootstrap for demersal post coefficient:\n")
  print(summary(boot_result))
  wcb_pval <- boot_result$p_val
}

# ======================================================================
# 3. Leave-one-country-out
# ======================================================================
cat("\n--- 3. Leave-One-Country-Out ---\n")

eu_demersal <- panel %>% filter(treatment_group == "demersal", is_eu)
countries <- unique(eu_demersal$country)

loo_results <- data.frame()
for (cty in countries) {
  loo_data <- panel %>% filter(treatment_group == "demersal", country != cty)
  loo_fit <- feols(
    log_catch ~ post | unit_num + year,
    data = loo_data,
    cluster = ~country
  )
  loo_results <- bind_rows(loo_results, data.frame(
    dropped = cty,
    coef = coef(loo_fit)["post"],
    se = se(loo_fit)["post"],
    pval = pvalue(loo_fit)["post"]
  ))
}

cat("Leave-one-country-out (demersal):\n")
print(loo_results %>% arrange(coef))
cat(sprintf("  Range: [%.3f, %.3f]\n", min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  All negative: %s\n", all(loo_results$coef < 0)))

# ======================================================================
# 4. Placebo treatment year (2012 instead of 2016 for demersal)
# ======================================================================
cat("\n--- 4. Placebo Treatment Year ---\n")

placebo_year <- panel %>%
  filter(treatment_group == "demersal", year < 2016) %>%
  mutate(
    placebo_post = as.integer(is_eu & year >= 2012)
  )

placebo_fit <- feols(
  log_catch ~ placebo_post | unit_num + year,
  data = placebo_year,
  cluster = ~country
)
cat("Placebo treatment at 2012 (demersal, pre-period only):\n")
summary(placebo_fit)

# ======================================================================
# 5. Levels specification (catch in tonnes, not logs)
# ======================================================================
cat("\n--- 5. Levels Specification ---\n")

twfe_levels <- feols(
  total_catch ~ post | unit_num + year,
  data = panel %>% filter(treatment_group == "demersal"),
  cluster = ~country
)
cat("TWFE in levels — demersal catches (tonnes):\n")
summary(twfe_levels)

# ======================================================================
# 6. Triple-difference: EU × demersal × post
# ======================================================================
cat("\n--- 6. Triple Difference ---\n")

# DDD: demersal vs pelagic, EU vs non-EU, pre vs post
ddd_data <- panel %>%
  filter(treatment_group %in% c("pelagic", "demersal")) %>%
  mutate(
    is_demersal = as.integer(treatment_group == "demersal"),
    post_2016 = as.integer(year >= 2016)
  )

ddd_fit <- feols(
  log_catch ~ is_eu:is_demersal:post_2016 +
    is_eu:post_2016 + is_demersal:post_2016 + is_eu:is_demersal |
    unit_num + year,
  data = ddd_data,
  cluster = ~country
)
cat("DDD: EU x Demersal x Post-2016:\n")
summary(ddd_fit)

# ======================================================================
# Save robustness results
# ======================================================================
cat("\n=== Saving robustness results ===\n")

rob <- list(
  es_demersal = es_demersal,
  wcb_pval = if (exists("wcb_pval")) wcb_pval else NA,
  loo_results = loo_results,
  placebo_fit = placebo_fit,
  twfe_levels = twfe_levels,
  ddd_fit = ddd_fit
)
saveRDS(rob, "../data/robustness.rds")

cat("=== Robustness checks complete ===\n")
