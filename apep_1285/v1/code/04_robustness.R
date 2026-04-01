## 04_robustness.R — Robustness checks and placebo tests
## APEP-1285: AEOI Shock and Swiss Real Estate

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

cat("=== Robustness Checks ===\n")

# ---- Apartments only, main sample ----
df_ew <- df %>%
  filter(property_type == "EW", year >= 2005, year <= 2023)

# ---- R1: Exclude 2015-2016 (CHF floor removal period) ----
cat("\n--- R1: Exclude 2015-2016 ---\n")
df_r1 <- df_ew %>% filter(!(year %in% c(2015, 2016)))
m_r1 <- feols(log_price ~ treat_x_post | region + year,
              data = df_r1, cluster = ~region)
cat(sprintf("  β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_r1)["treat_x_post"], se(m_r1)["treat_x_post"],
            pvalue(m_r1)["treat_x_post"]))

# ---- R2: Pre-COVID only (2005-2019) ----
cat("\n--- R2: Pre-COVID (2005-2019) ---\n")
df_r2 <- df_ew %>% filter(year <= 2019)
m_r2 <- feols(log_price ~ treat_x_post | region + year,
              data = df_r2, cluster = ~region)
cat(sprintf("  β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_r2)["treat_x_post"], se(m_r2)["treat_x_post"],
            pvalue(m_r2)["treat_x_post"]))

# ---- R3: Extended pre-period (1990-2023) ----
cat("\n--- R3: Extended pre-period (1990-2023) ---\n")
df_r3 <- df %>%
  filter(property_type == "EW", year >= 1990, year <= 2023)
m_r3 <- feols(log_price ~ treat_x_post | region + year,
              data = df_r3, cluster = ~region)
cat(sprintf("  β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_r3)["treat_x_post"], se(m_r3)["treat_x_post"],
            pvalue(m_r3)["treat_x_post"]))

# ---- R4: Houses (EH) instead of apartments ----
cat("\n--- R4: Houses (EH) ---\n")
df_r4 <- df %>%
  filter(property_type == "EH", year >= 2005, year <= 2023)
m_r4 <- feols(log_price ~ treat_x_post | region + year,
              data = df_r4, cluster = ~region)
cat(sprintf("  β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_r4)["treat_x_post"], se(m_r4)["treat_x_post"],
            pvalue(m_r4)["treat_x_post"]))

# ---- R5: Rental housing (MW) as placebo ----
# Rental prices should be less affected by wealth repatriation
# (rental market driven by flow demand, not asset demand)
cat("\n--- R5: Rental Housing Placebo (MW) ---\n")
df_r5 <- df %>%
  filter(property_type == "MW", year >= 2005, year <= 2023)
m_r5 <- feols(log_price ~ treat_x_post | region + year,
              data = df_r5, cluster = ~region)
cat(sprintf("  β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_r5)["treat_x_post"], se(m_r5)["treat_x_post"],
            pvalue(m_r5)["treat_x_post"]))

# ---- P1: Permutation Inference ----
cat("\n--- Permutation Inference (1000 draws) ---\n")
set.seed(42)
n_perm <- 1000
true_coef <- coef(feols(log_price ~ treat_x_post | region + year,
                        data = df_ew))["treat_x_post"]

# Permute treatment intensity across regions
regions <- unique(df_ew$region)
perm_coefs <- numeric(n_perm)

for (i in 1:n_perm) {
  # Shuffle banking_share across regions
  perm_map <- data.frame(
    region = regions,
    perm_banking = sample(unique(df_ew$banking_share[match(regions, df_ew$region)]))
  )
  df_perm <- df_ew %>%
    left_join(perm_map, by = "region") %>%
    mutate(perm_treat_x_post = perm_banking * post)

  m_perm <- feols(log_price ~ perm_treat_x_post | region + year,
                  data = df_perm)
  perm_coefs[i] <- coef(m_perm)["perm_treat_x_post"]
}

perm_pval <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("  True coefficient: %.4f\n", true_coef))
cat(sprintf("  Permutation p-value (two-sided): %.3f\n", perm_pval))
cat(sprintf("  Permutation distribution: mean = %.4f, sd = %.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

# ---- P2: Placebo treatment date (2012) ----
cat("\n--- Placebo Treatment Date (2012 instead of 2017) ---\n")
df_placebo <- df %>%
  filter(property_type == "EW", year >= 2005, year <= 2016) %>%
  mutate(
    placebo_post = as.integer(year >= 2012),
    placebo_treat = treat_intensity * placebo_post
  )
m_placebo <- feols(log_price ~ placebo_treat | region + year,
                   data = df_placebo, cluster = ~region)
cat(sprintf("  β = %.4f (SE = %.4f), p = %.3f\n",
            coef(m_placebo)["placebo_treat"], se(m_placebo)["placebo_treat"],
            pvalue(m_placebo)["placebo_treat"]))

# ---- Leave-one-out (LOO) ----
cat("\n--- Leave-One-Out Sensitivity ---\n")
loo_results <- data.frame(
  dropped_region = character(),
  coef = numeric(),
  se = numeric(),
  pval = numeric(),
  stringsAsFactors = FALSE
)

for (r in regions) {
  df_loo <- df_ew %>% filter(region != r)
  m_loo <- feols(log_price ~ treat_x_post | region + year,
                 data = df_loo, cluster = ~region)
  loo_results <- rbind(loo_results, data.frame(
    dropped_region = r,
    coef = coef(m_loo)["treat_x_post"],
    se = se(m_loo)["treat_x_post"],
    pval = pvalue(m_loo)["treat_x_post"]
  ))
}
cat("LOO results:\n")
print(loo_results)

# ---- Save all robustness results ----
saveRDS(list(
  r1_excl_chf = m_r1,
  r2_pre_covid = m_r2,
  r3_extended = m_r3,
  r4_houses = m_r4,
  r5_rental_placebo = m_r5,
  perm_pval = perm_pval,
  perm_coefs = perm_coefs,
  placebo_2012 = m_placebo,
  loo = loo_results,
  true_coef = true_coef
), "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
