## 04_robustness.R — Robustness checks
## apep_0877: Croatia 2013 Fiscalization

source("code/00_packages.R")

cat("=== Robustness Checks ===\n")

panel_vat <- readRDS("data/panel_vat.rds")
panel_gva <- readRDS("data/panel_gva.rds")

# ---------------------------------------------------------------
# 1. Leave-one-out: Drop each control country
# ---------------------------------------------------------------
cat("\n--- Leave-one-out (cross-country DiD) ---\n")

controls <- c("SK", "AT", "SI", "RO", "HU")
loo_results <- list()

for (cc in controls) {
  d_loo <- panel_vat %>% filter(country != cc)
  m_loo <- feols(vat_gdp ~ treat | country + year,
                 data = d_loo, cluster = ~country)
  loo_results[[cc]] <- data.frame(
    dropped = cc,
    beta = coef(m_loo)["treat"],
    se = se(m_loo)["treat"],
    pval = pvalue(m_loo)["treat"]
  )
  cat(sprintf("  Drop %s: β = %.3f (SE = %.3f, p = %.3f)\n",
              cc, coef(m_loo)["treat"], se(m_loo)["treat"], pvalue(m_loo)["treat"]))
}

loo_df <- do.call(rbind, loo_results)
saveRDS(loo_df, "data/robustness_loo.rds")

# ---------------------------------------------------------------
# 2. Pre-treatment placebo: Fake treatment in 2010
# ---------------------------------------------------------------
cat("\n--- Placebo test: Fake treatment in 2010 ---\n")

placebo_vat <- panel_vat %>%
  filter(year <= 2012) %>%
  mutate(
    fake_post = as.integer(year >= 2010),
    fake_treat = croatia * fake_post
  )

m_placebo <- feols(vat_gdp ~ fake_treat | country + year,
                   data = placebo_vat, cluster = ~country)
cat("Placebo (treatment in 2010):\n")
summary(m_placebo)

saveRDS(m_placebo, "data/robustness_placebo.rds")

# ---------------------------------------------------------------
# 3. Exclude 2020 (COVID year)
# ---------------------------------------------------------------
cat("\n--- Exclude 2020 (COVID) ---\n")

m_nocovid <- feols(vat_gdp ~ treat | country + year,
                   data = panel_vat %>% filter(year != 2020),
                   cluster = ~country)
cat("Exclude 2020:\n")
summary(m_nocovid)

# ---------------------------------------------------------------
# 4. Pre-2013 only (for parallel trends test)
# ---------------------------------------------------------------
cat("\n--- Pre-treatment balance ---\n")

# Test: Croatia's VAT/GDP trend = controls' trend before 2013
pre_data <- panel_vat %>% filter(year < 2013)
m_pretrend <- feols(vat_gdp ~ croatia:year | country + year,
                    data = pre_data, cluster = ~country)
cat("Pre-trend test (Croatia × year interaction):\n")
summary(m_pretrend)

# ---------------------------------------------------------------
# 5. Drop Hungary (which also saw VAT increase)
# ---------------------------------------------------------------
cat("\n--- Drop Hungary (concurrent fiscal changes) ---\n")

m_nohu <- feols(vat_gdp ~ treat | country + year,
                data = panel_vat %>% filter(country != "HU"),
                cluster = ~country)
cat("Drop Hungary:\n")
summary(m_nohu)

# ---------------------------------------------------------------
# 6. Shorter post-window (2013-2016 only)
# ---------------------------------------------------------------
cat("\n--- Shorter post-window (2013-2016) ---\n")

m_short <- feols(vat_gdp ~ treat | country + year,
                 data = panel_vat %>% filter(year <= 2016),
                 cluster = ~country)
cat("Short window (2013-2016):\n")
summary(m_short)

# ---------------------------------------------------------------
# 7. Phase 1+2 only DDD (pre-EU accession sectors)
# ---------------------------------------------------------------
cat("\n--- Phase 1+2 only triple diff (pre-EU accession) ---\n")

# Exclude Phase 3 sectors (treated Jul 1 = same day as EU accession)
panel_gva_p12 <- panel_gva %>%
  filter(phase != 3) %>%
  mutate(
    country_sector = paste(country, nace, sep = "_"),
    country_year = paste(country, year, sep = "_"),
    sector_year = paste(nace, year, sep = "_"),
    ddd = as.integer(treated == 1 & croatia == 1 & post == 1)
  )

m_phase12 <- feols(log_gva ~ ddd | country_sector + country_year + sector_year,
                   data = panel_gva_p12, cluster = ~country)
cat("Phase 1+2 only DDD:\n")
summary(m_phase12)

# ---------------------------------------------------------------
# 8. Triple-diff placebo: Exempt sectors should show no effect
# ---------------------------------------------------------------
cat("\n--- Triple-diff placebo: Exempt sectors ---\n")

# Restrict to never-treated sectors in Croatia — should see no effect
# relative to never-treated sectors in control countries
exempt_gva <- panel_gva %>%
  filter(treated == 0) %>%
  mutate(
    croatia_post = as.integer(croatia == 1 & post == 1),
    country_sector = paste(country, nace, sep = "_")
  )

m_exempt <- feols(log_gva ~ croatia_post | country_sector + year,
                  data = exempt_gva, cluster = ~country)
cat("Exempt sectors (placebo):\n")
summary(m_exempt)

# ---------------------------------------------------------------
# 8. Wild cluster bootstrap (for small N clusters)
# ---------------------------------------------------------------
cat("\n--- Wild cluster bootstrap (cross-country DiD) ---\n")

# Since we only have 6 clusters, use wild cluster bootstrap
# Using the boot package for a manual wild bootstrap
set.seed(42)
n_boot <- 999

# Full sample basic DiD
m_full <- feols(vat_gdp ~ treat | country + year,
                data = panel_vat)
beta_hat <- coef(m_full)["treat"]
resid_full <- residuals(m_full)

countries_vec <- unique(panel_vat$country)
n_countries <- length(countries_vec)

boot_betas <- numeric(n_boot)
for (b in seq_len(n_boot)) {
  # Rademacher weights at cluster level
  weights <- sample(c(-1, 1), n_countries, replace = TRUE)
  names(weights) <- countries_vec

  # Apply weights to residuals
  panel_boot <- panel_vat %>%
    mutate(
      w = weights[country],
      vat_boot = fitted(m_full) + w * resid_full
    )

  m_boot <- feols(vat_boot ~ treat | country + year,
                  data = panel_boot)
  boot_betas[b] <- coef(m_boot)["treat"]
}

# Bootstrap p-value (two-sided)
boot_se <- sd(boot_betas)
boot_pval <- mean(abs(boot_betas - mean(boot_betas)) >= abs(beta_hat - mean(boot_betas)))
cat(sprintf("Wild bootstrap: β = %.3f, SE_boot = %.3f, p_boot = %.3f\n",
            beta_hat, boot_se, boot_pval))

# Store all robustness results
robustness <- list(
  loo = loo_df,
  placebo = m_placebo,
  no_covid = m_nocovid,
  pre_trend = m_pretrend,
  no_hungary = m_nohu,
  short_window = m_short,
  phase12_ddd = m_phase12,
  exempt_placebo = m_exempt,
  bootstrap = list(beta = beta_hat, se_boot = boot_se, p_boot = boot_pval)
)
saveRDS(robustness, "data/robustness_all.rds")

cat("\n=== Robustness checks complete ===\n")
