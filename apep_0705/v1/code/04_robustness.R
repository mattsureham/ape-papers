## 04_robustness.R — Robustness checks and sensitivity
## APEP-0705: Sweden's RUT Household Services Deduction

source("00_packages.R")

data_dir <- "../data"

panel        <- readRDS(file.path(data_dir, "panel_income.rds"))
emp_panel    <- readRDS(file.path(data_dir, "panel_employment.rds"))
emprate_panel <- readRDS(file.path(data_dir, "panel_emprate.rds"))
treatment_df <- readRDS(file.path(data_dir, "treatment_intensity.rds"))

panel <- panel %>% filter(!is.na(mean_income), mean_income > 0)

## ============================================================
## 1. MUNICIPALITY-SPECIFIC LINEAR TRENDS
## ============================================================
cat("=== Robustness: Municipality-specific linear trends ===\n")

panel <- panel %>%
  mutate(
    trend = year - 2006,
    year_factor = factor(year)
  )

# Add municipality-specific linear trends to absorb pre-reform convergence
did_trends <- feols(
  log_mean_income ~ treat_x_post | region[trend] + year,
  data = panel,
  cluster = ~region
)

cat("With municipality-specific linear trends:\n")
print(summary(did_trends))

## ============================================================
## 2. QUARTILE-BASED DiD (non-parametric treatment)
## ============================================================
cat("\n=== Robustness: Quartile-based treatment ===\n")

# Use top-quartile vs bottom-quartile as binary treatment
panel_q <- panel %>%
  filter(income_quartile %in% c(1, 4)) %>%
  mutate(
    treated = as.integer(income_quartile == 4),
    treat_post = treated * post
  )

did_binary <- feols(
  log_mean_income ~ treat_post | region + year,
  data = panel_q,
  cluster = ~region
)

cat("Binary treatment (Q4 vs Q1):\n")
print(summary(did_binary))

## ============================================================
## 3. DROPPING STOCKHOLM METROPOLITAN AREA
## ============================================================
cat("\n=== Robustness: Excluding Stockholm county ===\n")

# Stockholm municipality codes start with 01
muni_map <- readRDS(file.path(data_dir, "municipality_names.rds")) %>%
  mutate(county = substr(code, 1, 2))

sthlm_munis <- muni_map$name[muni_map$county == "01"]
panel_no_sthlm <- panel %>%
  filter(!region %in% sthlm_munis)

did_no_sthlm <- feols(
  log_mean_income ~ treat_x_post | region + year,
  data = panel_no_sthlm,
  cluster = ~region
)

cat("Excluding Stockholm county:\n")
print(summary(did_no_sthlm))

## ============================================================
## 4. ALTERNATIVE TREATMENT INTENSITY: Median income
## ============================================================
cat("\n=== Robustness: Median income as treatment intensity ===\n")

income_df <- readRDS(file.path(data_dir, "income_municipality.rds"))

# Reconstruct treatment using median income 2006
# Need to re-fetch median income... use the stored data
# The income_df already has it if we fetched both content codes
# Check if median_income exists
if ("median_income" %in% names(income_df)) {
  med_treat <- income_df %>%
    filter(year == 2006, !is.na(median_income)) %>%
    select(region, median_income_2006 = median_income) %>%
    mutate(
      treat_med = (median_income_2006 - mean(median_income_2006)) /
                   sd(median_income_2006)
    )

  panel_med <- panel %>%
    left_join(med_treat, by = "region") %>%
    filter(!is.na(treat_med)) %>%
    mutate(treat_med_post = treat_med * post)

  did_median <- feols(
    log_mean_income ~ treat_med_post | region + year,
    data = panel_med,
    cluster = ~region
  )

  cat("Using median income as treatment intensity:\n")
  print(summary(did_median))
} else {
  cat("Median income not available in data — skipping\n")
}

## ============================================================
## 5. EMPLOYMENT: Comparison of M+N vs other sectors
## ============================================================
cat("\n=== Sector comparison: M+N vs Manufacturing vs Hotels ===\n")

mn_label <- unique(emp_panel$sector)[grepl("professional", unique(emp_panel$sector))]
mfg_label <- unique(emp_panel$sector)[grepl("mining", unique(emp_panel$sector))]
hotel_label <- unique(emp_panel$sector)[grepl("hotels", unique(emp_panel$sector))]

# Stack sectors for comparison
sector_compare <- emp_panel %>%
  filter(sector %in% c(mn_label, mfg_label, hotel_label), emp > 0) %>%
  mutate(
    sector_type = case_when(
      sector == mn_label ~ "services_mn",
      sector == mfg_label ~ "manufacturing",
      sector == hotel_label ~ "hospitality"
    ),
    post_2012 = as.integer(year >= 2012)
  )

# Run within each sector
for (s in c("services_mn", "manufacturing", "hospitality")) {
  cat("\n", toupper(s), ":\n")
  mod <- feols(
    log_emp ~ treat_intensity:post_2012 | region + year,
    data = sector_compare %>% filter(sector_type == s),
    cluster = ~region
  )
  cat("  Coef:", round(coef(mod), 4), ", SE:", round(se(mod), 4),
      ", p:", round(pvalue(mod), 4), "\n")
}

## ============================================================
## 6. PERMUTATION TEST (Fisher randomization inference)
## ============================================================
cat("\n=== Permutation test ===\n")

set.seed(42)
n_perms <- 999
actual_coef <- coef(feols(
  log_mean_income ~ treat_x_post | region + year,
  data = panel
))["treat_x_post"]

perm_coefs <- numeric(n_perms)
muni_list <- unique(panel$region)

for (p in seq_len(n_perms)) {
  # Shuffle treatment intensity across municipalities
  perm_treat <- treatment_df %>%
    mutate(treat_intensity = sample(treat_intensity))

  perm_panel <- panel %>%
    select(-treat_intensity, -treat_x_post) %>%
    left_join(perm_treat %>% select(region, treat_intensity), by = "region") %>%
    mutate(treat_x_post = treat_intensity * post)

  perm_mod <- feols(
    log_mean_income ~ treat_x_post | region + year,
    data = perm_panel
  )
  perm_coefs[p] <- coef(perm_mod)["treat_x_post"]

  if (p %% 100 == 0) cat("  Permutation", p, "\n")
}

ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Randomization inference p-value:", ri_pvalue, "\n")
cat("Actual coefficient:", round(actual_coef, 5), "\n")
cat("Permutation distribution: mean =", round(mean(perm_coefs), 5),
    ", sd =", round(sd(perm_coefs), 5), "\n")

## ============================================================
## SAVE ROBUSTNESS RESULTS
## ============================================================
robustness <- list(
  trends = did_trends,
  binary_q = did_binary,
  no_stockholm = did_no_sthlm,
  ri_pvalue = ri_pvalue,
  ri_actual = actual_coef,
  ri_distribution = perm_coefs
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
