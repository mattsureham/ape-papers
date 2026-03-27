## 04_robustness.R — Robustness checks and mechanism tests
## apep_1090: The Compliance Trap

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel_balanced.rds"))

# Re-add standardized CS share
panel <- panel %>%
  mutate(
    cs_share_std = (cs_share - mean(cs_share, na.rm = TRUE)) / sd(cs_share, na.rm = TRUE),
    snap_rate_pct = snap_rate * 100,
    poverty_rate_pct = poverty_rate * 100
  )

# ============================================================
# 1. Dose-Response: Tercile interactions
# ============================================================
cat("=== Dose-Response by Tercile ===\n")

panel <- panel %>%
  mutate(
    cs_tercile = ntile(cs_share, 3),
    cs_q2 = as.integer(cs_tercile == 2),
    cs_q3 = as.integer(cs_tercile == 3)
  )

dose <- feols(
  snap_rate_pct ~ cs_q2:post + cs_q3:post | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
)

cat("Dose-response (ref = low CS share tercile):\n")
etable(dose, se.below = TRUE)

# ============================================================
# 2. Heterogeneity: Urban vs Rural
# ============================================================
cat("\n=== Urban/Rural Heterogeneity ===\n")

# Define rural as counties with population < median
pop_median <- median(panel$population[panel$year == 2017], na.rm = TRUE)
panel <- panel %>%
  mutate(
    rural = as.integer(population < pop_median),
    urban = 1 - rural
  )

rural_m <- feols(
  snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% filter(rural == 1),
  cluster = ~ state_fips
)

urban_m <- feols(
  snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% filter(urban == 1),
  cluster = ~ state_fips
)

cat("Rural counties:\n")
etable(rural_m, se.below = TRUE)
cat("Urban counties:\n")
etable(urban_m, se.below = TRUE)

# ============================================================
# 3. Heterogeneity: High vs Low Poverty
# ============================================================
cat("\n=== High/Low Poverty Heterogeneity ===\n")

pov_median <- median(panel$poverty_rate[panel$year == 2017], na.rm = TRUE)
panel <- panel %>%
  mutate(high_poverty = as.integer(poverty_rate > pov_median))

high_pov_m <- feols(
  snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% filter(high_poverty == 1),
  cluster = ~ state_fips
)

low_pov_m <- feols(
  snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel %>% filter(high_poverty == 0),
  cluster = ~ state_fips
)

cat("High poverty counties:\n")
etable(high_pov_m, se.below = TRUE)
cat("Low poverty counties:\n")
etable(low_pov_m, se.below = TRUE)

# ============================================================
# 4. Permutation / Randomization Inference
# ============================================================
cat("\n=== Randomization Inference ===\n")

# Permute CS share across counties 500 times
set.seed(42)
n_perms <- 500
true_coef <- coef(feols(
  snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
))[["cs_share_std:post"]]

perm_coefs <- numeric(n_perms)
county_ids <- unique(panel$fips)

for (i in seq_len(n_perms)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms, "\n")

  # Shuffle CS share assignment across counties
  perm_map <- data.frame(
    fips = county_ids,
    cs_share_perm = sample(panel$cs_share_std[match(county_ids, panel$fips)])
  )

  panel_perm <- panel %>%
    left_join(perm_map, by = "fips") %>%
    mutate(treat_perm = cs_share_perm * post)

  m_perm <- tryCatch(
    feols(snap_rate_pct ~ treat_perm | fips + state_fips^year,
          data = panel_perm, cluster = ~ state_fips),
    error = function(e) NULL
  )

  perm_coefs[i] <- if (!is.null(m_perm)) coef(m_perm)[["treat_perm"]] else NA
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pvalue <- mean(abs(perm_coefs) >= abs(true_coef))
cat("True coefficient:", round(true_coef, 4), "\n")
cat("RI p-value (two-sided):", round(ri_pvalue, 4), "\n")
cat("Permutations completed:", length(perm_coefs), "\n")

# ============================================================
# 5. Leave-One-State-Out
# ============================================================
cat("\n=== Leave-One-State-Out ===\n")

states <- unique(panel$state_fips)
loso_coefs <- numeric(length(states))
names(loso_coefs) <- states

for (st in states) {
  m_loso <- tryCatch(
    feols(snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
          data = panel %>% filter(state_fips != st),
          cluster = ~ state_fips),
    error = function(e) NULL
  )
  loso_coefs[st] <- if (!is.null(m_loso)) coef(m_loso)[["cs_share_std:post"]] else NA
}

loso_coefs <- loso_coefs[!is.na(loso_coefs)]
cat("LOSO coefficient range: [", round(min(loso_coefs), 4), ",",
    round(max(loso_coefs), 4), "]\n")
cat("LOSO mean:", round(mean(loso_coefs), 4), "\n")
cat("All estimates negative:", all(loso_coefs < 0), "\n")

# ============================================================
# 6. Alternative treatment dates (placebo timing)
# ============================================================
# ============================================================
# 5b. County-specific linear trends
# ============================================================
cat("\n=== County-Specific Linear Trends ===\n")

panel <- panel %>%
  mutate(year_centered = year - 2017)

trend_m <- feols(
  snap_rate_pct ~ cs_share_std:post + year_centered:factor(fips) | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
)

cat("With county-specific linear trends:\n")
cat("  Coef:", round(coef(trend_m)[["cs_share_std:post"]], 4), "\n")
cat("  SE:", round(se(trend_m)[["cs_share_std:post"]], 4), "\n")

cat("\n=== Placebo Timing Tests ===\n")

# Test fake treatment in 2016 and 2017
for (fake_year in c(2016, 2017)) {
  panel_fake <- panel %>%
    filter(year <= 2018) %>%
    mutate(fake_post = as.integer(year >= fake_year))

  m_fake <- tryCatch(
    feols(snap_rate_pct ~ cs_share_std:fake_post | fips + state_fips^year,
          data = panel_fake,
          cluster = ~ state_fips),
    error = function(e) NULL
  )

  if (!is.null(m_fake)) {
    cat("Fake treatment", fake_year, ": coef =",
        round(coef(m_fake)[[1]], 4), ", SE =",
        round(se(m_fake)[[1]], 4), "\n")
  }
}

# ============================================================
# 7. Save robustness results
# ============================================================
robustness <- list(
  dose_response = dose,
  rural = rural_m,
  urban = urban_m,
  high_poverty = high_pov_m,
  low_poverty = low_pov_m,
  ri_pvalue = ri_pvalue,
  ri_n_perms = length(perm_coefs),
  loso_coefs = loso_coefs,
  true_coef = true_coef
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
