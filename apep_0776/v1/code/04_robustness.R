# ==============================================================================
# 04_robustness.R — Robustness Checks
# Paper: Working Themselves to Death? (apep_0776)
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

robustness <- list()

# ---- 1. Levels instead of logs ----
cat("--- Levels specification ---\n")
robustness$levels <- feols(death_rate ~ treat | geo + year,
                           data = panel, cluster = ~geo)
cat(sprintf("  Levels: coef=%.3f, SE=%.3f\n",
            coef(robustness$levels)[1], sqrt(vcov(robustness$levels)[1,1])))

# ---- 2. Region-specific trends ----
cat("--- Region-specific linear trends ---\n")
panel <- panel %>%
  mutate(geo_trend = as.numeric(factor(geo)) * year)

robustness$trends <- feols(log_death_rate ~ treat | geo + year + geo[year],
                           data = panel, cluster = ~geo)
cat(sprintf("  With trends: coef=%.5f, SE=%.5f\n",
            coef(robustness$trends)[1], sqrt(vcov(robustness$trends)[1,1])))

# ---- 3. Exclude outlier regions (top/bottom bite) ----
cat("--- Exclude extreme regions ---\n")
extreme_regions <- panel %>%
  distinct(geo, fbite) %>%
  arrange(fbite) %>%
  slice(c(1:2, (n()-1):n())) %>%
  pull(geo)

robustness$no_extreme <- feols(log_death_rate ~ treat | geo + year,
                               data = filter(panel, !(geo %in% extreme_regions)),
                               cluster = ~geo)
cat(sprintf("  No extremes: coef=%.5f, SE=%.5f\n",
            coef(robustness$no_extreme)[1], sqrt(vcov(robustness$no_extreme)[1,1])))

# ---- 4. Shorter pre-period (2005-2011) ----
cat("--- Shorter pre-period ---\n")
robustness$short_pre <- feols(log_death_rate ~ treat | geo + year,
                              data = filter(panel, year >= 2005),
                              cluster = ~geo)
cat(sprintf("  Short pre: coef=%.5f, SE=%.5f\n",
            coef(robustness$short_pre)[1], sqrt(vcov(robustness$short_pre)[1,1])))

# ---- 5. Female-only (highest dose) ----
cat("--- Female only (max dose) ---\n")
robustness$female_only <- feols(log_death_rate ~ treat | geo + year,
                                data = filter(panel, sex == "F"),
                                cluster = ~geo)
cat(sprintf("  Female only: coef=%.5f, SE=%.5f\n",
            coef(robustness$female_only)[1], sqrt(vcov(robustness$female_only)[1,1])))

# ---- 6. Save ----
saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
