### 04_robustness.R
### Kenya Interest Rate Cap and FinTech Substitution
### apep_0702

source("00_packages.R")
setwd("../data")

library(fixest)

# Resolve conflicts: ensure fixest's se() and pvalue() are used, not scales'
se     <- fixest::se
pvalue <- fixest::pvalue

cat("=== Robustness Checks ===\n")

panel_country <- read_csv("panel_country.csv", show_col_types = FALSE)
finaccess_county <- read_csv("finaccess_county_clean.csv", show_col_types = FALSE)
models <- readRDS("models.rds")

# Re-estimate main models here (to avoid RDS deserialization issues)
df_main   <- panel_country %>% filter(!is.na(credit_gdp))
df_lend   <- panel_country %>% filter(!is.na(lending_rate))
df_branch <- panel_country %>% filter(!is.na(branches_100k))
df_npl    <- panel_country %>% filter(!is.na(npl_ratio))

m1_credit <- feols(credit_gdp ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_main, cluster = ~country_code)
m2_lend   <- feols(lending_rate ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_lend, cluster = ~country_code)
m3_branch <- feols(branches_100k ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_branch, cluster = ~country_code)
m4_npl    <- feols(npl_ratio ~ treat_cap_full + treat_repeal | country_code + year,
                   data = df_npl, cluster = ~country_code)

# ===================================================
# R1: Alternative control groups
# ===================================================
cat("\n--- R1: Using only one control country at a time ---\n")

control_countries <- c("UG", "TZ", "RW")
loo_results_cap <- c()
loo_results_repeal <- c()

for (ctl in control_countries) {
  df_loo <- panel_country %>%
    filter(country_code %in% c("KE", ctl), !is.na(credit_gdp))

  m_loo <- feols(
    credit_gdp ~ treat_cap_full + treat_repeal | country_code + year,
    data = df_loo,
    vcov = "hetero"
  )

  loo_results_cap    <- c(loo_results_cap, coef(m_loo)["treat_cap_full"])
  loo_results_repeal <- c(loo_results_repeal, coef(m_loo)["treat_repeal"])

  cat(sprintf("  vs %s: cap=%.3f, repeal=%.3f\n",
              ctl,
              coef(m_loo)["treat_cap_full"],
              coef(m_loo)["treat_repeal"]))
}

# ===================================================
# R2: Alternative treatment timing (cap effective 2016 vs 2017)
# ===================================================
cat("\n--- R2: Alternative treatment timing ---\n")

# Option A: 2016 as first year (partial year)
df_r2a <- panel_country %>%
  filter(!is.na(credit_gdp)) %>%
  mutate(treat_cap_2016 = kenya * as.integer(year >= 2016 & year <= 2019))

m_r2a <- feols(
  credit_gdp ~ treat_cap_2016 + treat_repeal | country_code + year,
  data = df_r2a,
  cluster = ~country_code
)

cat(sprintf("  Cap from 2016: coef=%.3f (SE=%.3f)\n",
            coef(m_r2a)["treat_cap_2016"],
            se(m_r2a)["treat_cap_2016"]))

# Option B: 2017-2018 only (exclude 2019 which is repeal year)
df_r2b <- panel_country %>%
  filter(!is.na(credit_gdp)) %>%
  mutate(treat_cap_short = kenya * as.integer(year %in% 2017:2018))

m_r2b <- feols(
  credit_gdp ~ treat_cap_short | country_code + year,
  data = df_r2b,
  cluster = ~country_code
)

cat(sprintf("  Cap 2017-2018 only: coef=%.3f (SE=%.3f)\n",
            coef(m_r2b)["treat_cap_short"],
            se(m_r2b)["treat_cap_short"]))

# ===================================================
# R3: Controlling for macroeconomic time trends
# ===================================================
cat("\n--- R3: Adding country-specific linear time trends ---\n")

df_r3 <- panel_country %>%
  filter(!is.na(credit_gdp)) %>%
  mutate(year_demeaned = year - mean(year))

m_r3 <- feols(
  credit_gdp ~ treat_cap_full + treat_repeal +
    i(country_code, year_demeaned) |  # country-specific linear trends
    country_code + year,
  data = df_r3,
  cluster = ~country_code
)

cat(sprintf("  With country trends: cap=%.3f (SE=%.3f)\n",
            coef(m_r3)["treat_cap_full"],
            se(m_r3)["treat_cap_full"]))

# ===================================================
# R4: Adding GDP growth control
# ===================================================
cat("\n--- R4: Controlling for GDP growth ---\n")

df_r4 <- panel_country %>%
  filter(!is.na(credit_gdp), !is.na(gdp_growth))

m_r4 <- feols(
  credit_gdp ~ treat_cap_full + treat_repeal + gdp_growth | country_code + year,
  data = df_r4,
  cluster = ~country_code
)

cat(sprintf("  With GDP growth: cap=%.3f (SE=%.3f)\n",
            coef(m_r4)["treat_cap_full"],
            se(m_r4)["treat_cap_full"]))

# ===================================================
# R5: Deposit rate as placebo outcome
# ===================================================
cat("\n--- R5: Deposit rate as mechanism test ---\n")
# The 2016 law also mandated deposit rates >= 70% of CBR
# We should see BOTH lending rate fall AND deposit rate rise

df_r5 <- panel_country %>% filter(!is.na(deposit_rate))

m_r5 <- feols(
  deposit_rate ~ treat_cap_full + treat_repeal | country_code + year,
  data = df_r5,
  cluster = ~country_code
)

cat(sprintf("  Deposit rate (cap): coef=%.3f (SE=%.3f) [expect positive]\n",
            coef(m_r5)["treat_cap_full"],
            se(m_r5)["treat_cap_full"]))

# ===================================================
# R6: Expanded SSA donor pool using Africa data

cat("
--- R6: Skipped (bilateral LOO in R1 is main robustness) ---
")
m_r6 <- NULL

# ===================================================
# Save robustness models
# ===================================================

rob_results <- data.frame(
  spec = c("Baseline (lend. rate)", "vs UG only", "vs TZ only", "vs RW only",
           "Cap from 2016", "Cap 2017-18", "Country trends (credit)",
           "GDP growth ctrl", "Deposit rate"),
  coef_cap = c(
    coef(m2_lend)["treat_cap_full"],  # Use lending rate as main robust spec
    loo_results_cap,
    coef(m_r2a)["treat_cap_2016"],
    coef(m_r2b)["treat_cap_short"],
    coef(m_r3)["treat_cap_full"],
    coef(m_r4)["treat_cap_full"],
    coef(m_r5)["treat_cap_full"]
  ),
  se_cap = c(
    se(m2_lend)["treat_cap_full"],
    rep(NA, 3),  # LOO uses hetero SE
    se(m_r2a)["treat_cap_2016"],
    se(m_r2b)["treat_cap_short"],
    se(m_r3)["treat_cap_full"],
    se(m_r4)["treat_cap_full"],
    se(m_r5)["treat_cap_full"]
  )
)

write_csv(rob_results, "robustness_results.csv")

# Update models RDS with robustness
models$m_r2a <- m_r2a
models$m_r2b <- m_r2b
models$m_r3 <- m_r3
models$m_r4 <- m_r4
models$m_r5 <- m_r5
models$m_r6 <- m_r6
models$rob_results <- rob_results
models$loo_results_cap    <- loo_results_cap
models$loo_results_repeal <- loo_results_repeal

saveRDS(models, "models.rds")

cat("\n=== Robustness Complete ===\n")
