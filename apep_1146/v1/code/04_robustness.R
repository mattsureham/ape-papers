# 04_robustness.R — Robustness checks

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ══════════════════════════════════════════════════════════════
# 1. PLACEBO TREATMENT DATES
# ══════════════════════════════════════════════════════════════
cat("--- Placebo treatment dates ---\n")

# Placebo 1: 12 months earlier (March 2020)
df_plac1 <- df %>%
  filter(date <= as.Date("2021-02-01")) %>%
  mutate(post_placebo = as.integer(date >= as.Date("2020-03-01")))

plac1 <- feols(new_abs_mom ~ treated:post_placebo | city_id + time_id,
               data = df_plac1, cluster = ~city_id)
cat("Placebo (March 2020):\n")
print(summary(plac1))

# Placebo 2: 18 months earlier (September 2019)
df_plac2 <- df %>%
  filter(date <= as.Date("2021-02-01")) %>%
  mutate(post_placebo = as.integer(date >= as.Date("2019-09-01")))

plac2 <- feols(new_abs_mom ~ treated:post_placebo | city_id + time_id,
               data = df_plac2, cluster = ~city_id)
cat("\nPlacebo (September 2019):\n")
print(summary(plac2))

# ══════════════════════════════════════════════════════════════
# 2. DROP TIER-1 CITIES
# ══════════════════════════════════════════════════════════════
cat("\n--- Exclude Tier-1 cities ---\n")

df_no_t1 <- df %>% filter(tier1 == 0)
rob_no_t1 <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                    data = df_no_t1, cluster = ~city_id)
cat("Without Tier-1 cities (", n_distinct(df_no_t1$city_en), " cities):\n")
print(summary(rob_no_t1))

# ══════════════════════════════════════════════════════════════
# 3. ALTERNATIVE VOLATILITY MEASURES
# ══════════════════════════════════════════════════════════════
cat("\n--- Alternative volatility measures ---\n")

# Squared MoM
rob_sq <- feols(new_mom_sq ~ treated:post | city_id + time_id,
                data = df, cluster = ~city_id)
cat("Squared MoM:\n")
print(summary(rob_sq))

# 3-month rolling SD (drops first 2 obs per city)
rob_vol3 <- feols(new_vol_3m ~ treated:post | city_id + time_id,
                  data = df %>% filter(!is.na(new_vol_3m)),
                  cluster = ~city_id)
cat("\n3-month rolling SD:\n")
print(summary(rob_vol3))

# ══════════════════════════════════════════════════════════════
# 4. ALTERNATIVE SAMPLE WINDOWS
# ══════════════════════════════════════════════════════════════
cat("\n--- Alternative sample windows ---\n")

# Narrower: 12 months pre/post
df_narrow <- df %>%
  filter(date >= as.Date("2020-03-01") & date <= as.Date("2022-02-01"))
rob_narrow <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                    data = df_narrow, cluster = ~city_id)
cat("12-month window:\n")
print(summary(rob_narrow))

# Wider: full sample 2011-2023
df_full <- readRDS("../data/full_panel.rds") %>%
  filter(!is.na(new_house_mom)) %>%
  mutate(
    new_mom_pct = new_house_mom - 100,
    new_abs_mom = abs(new_mom_pct),
    post = as.integer(date >= as.Date("2021-03-01")),
    city_id = as.integer(factor(city_en)),
    time_id = as.integer(factor(date))
  )

rob_full <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                  data = df_full, cluster = ~city_id)
cat("\nFull sample (2011-2023+):\n")
print(summary(rob_full))

# ══════════════════════════════════════════════════════════════
# 5. LEAVE-ONE-OUT (drop each treated city)
# ══════════════════════════════════════════════════════════════
cat("\n--- Leave-one-out ---\n")

treated_cities <- unique(df$city_en[df$treated == 1])
loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (city in treated_cities) {
  df_loo <- df %>% filter(city_en != city)
  m_loo <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                 data = df_loo, cluster = ~city_id)
  loo_results <- rbind(loo_results, data.frame(
    dropped = city,
    coef = coef(m_loo)["treated:post"],
    se = se(m_loo)["treated:post"]
  ))
}

cat("Leave-one-out range:\n")
cat("  Min coef:", min(loo_results$coef), "\n")
cat("  Max coef:", max(loo_results$coef), "\n")
cat("  Main coef:", coef(results$m1)["treated:post"], "\n")

# ══════════════════════════════════════════════════════════════
# 6. HETEROGENEITY
# ══════════════════════════════════════════════════════════════
cat("\n--- Heterogeneity ---\n")

# Tier-1 vs Tier-2 treated cities
df_t1_treated <- df %>% filter(treated == 1, tier1 == 1)
df_t2_treated <- df %>% filter(treated == 1, tier1 == 0)

# Add untreated cities to each for the DiD
df_het_t1 <- bind_rows(df_t1_treated, df %>% filter(treated == 0))
df_het_t2 <- bind_rows(df_t2_treated, df %>% filter(treated == 0))

het_t1 <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                data = df_het_t1, cluster = ~city_id)
het_t2 <- feols(new_abs_mom ~ treated:post | city_id + time_id,
                data = df_het_t2, cluster = ~city_id)

cat("Tier-1 cities only:\n")
print(summary(het_t1))
cat("\nTier-2 cities only:\n")
print(summary(het_t2))

# ══════════════════════════════════════════════════════════════
# SAVE ROBUSTNESS RESULTS
# ══════════════════════════════════════════════════════════════
rob_results <- list(
  plac1 = plac1, plac2 = plac2,
  rob_no_t1 = rob_no_t1,
  rob_sq = rob_sq, rob_vol3 = rob_vol3,
  rob_narrow = rob_narrow, rob_full = rob_full,
  loo_results = loo_results,
  het_t1 = het_t1, het_t2 = het_t2
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
