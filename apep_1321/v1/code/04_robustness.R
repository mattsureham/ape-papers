# 04_robustness.R — Robustness checks and placebos
source("00_packages.R")

data_dir <- "../data"
panel <- read.csv(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== Robustness Checks ===\n")

# ============================================================================
# 1. Placebo treatment date (2017)
# ============================================================================
cat("\n=== Placebo: Treatment in 2017 (pre-period only) ===\n")

placebo_panel <- panel %>%
  filter(year <= 2018) %>%
  mutate(
    post_placebo = as.integer(year >= 2017),
    treat_post_placebo = intensity_regional * post_placebo
  )

r1 <- feols(log_ntl ~ treat_post_placebo | gid + year,
            data = placebo_panel, cluster = ~region)
cat("Placebo (2017 cutoff): ")
cat(sprintf("beta = %.4f, SE = %.4f, p = %.3f\n",
            coef(r1), se(r1), pvalue(r1)))

# ============================================================================
# 2. Exclude Greater Accra (largest city, potential outlier)
# ============================================================================
cat("\n=== Robustness: Exclude Greater Accra ===\n")

r2 <- feols(log_ntl ~ treat_post | gid + year,
            data = panel %>% filter(region != "Greater Accra"),
            cluster = ~region)
cat("Excluding Greater Accra: ")
cat(sprintf("beta = %.4f, SE = %.4f, p = %.3f\n",
            coef(r2), se(r2), pvalue(r2)))

# ============================================================================
# 3. Exclude Ashanti (second highest treatment)
# ============================================================================
cat("\n=== Robustness: Exclude Ashanti ===\n")

r3 <- feols(log_ntl ~ treat_post | gid + year,
            data = panel %>% filter(region != "Ashanti"),
            cluster = ~region)
cat("Excluding Ashanti: ")
cat(sprintf("beta = %.4f, SE = %.4f, p = %.3f\n",
            coef(r3), se(r3), pvalue(r3)))

# ============================================================================
# 4. Wild cluster bootstrap (few clusters)
# ============================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

# With 16 regions, cluster-robust SEs may be unreliable
# Use wild cluster bootstrap
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  # Refit with standard fixest for boottest
  m_boot <- feols(log_ntl ~ treat_post | gid + year,
                  data = panel, cluster = ~region)

  boot_result <- tryCatch({
    boottest(m_boot, param = "treat_post",
             clustid = ~region, B = 9999,
             type = "rademacher")
  }, error = function(e) {
    cat(sprintf("  Bootstrap error: %s\n", conditionMessage(e)))
    NULL
  })

  if (!is.null(boot_result)) {
    cat("Wild cluster bootstrap (Rademacher, B=9999):\n")
    print(summary(boot_result))
  }
} else {
  cat("  fwildclusterboot not available, skipping\n")
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}

# ============================================================================
# 5. Permutation inference (randomize treatment across regions)
# ============================================================================
cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_perms <- 1000

# Get the actual coefficient
actual_beta <- coef(results$m1_continuous_post2020)

# Get unique region-level intensities
region_intensities <- panel %>%
  select(region, intensity_regional) %>%
  distinct()

perm_betas <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  # Shuffle treatment intensity across regions
  shuffled <- region_intensities
  shuffled$intensity_regional <- sample(shuffled$intensity_regional)

  # Merge back
  perm_panel <- panel %>%
    select(-intensity_regional) %>%
    left_join(shuffled, by = "region") %>%
    mutate(treat_post_perm = intensity_regional * post)

  perm_m <- feols(log_ntl ~ treat_post_perm | gid + year,
                  data = perm_panel, cluster = ~region)
  perm_betas[i] <- coef(perm_m)
}

ri_pvalue <- mean(abs(perm_betas) >= abs(actual_beta))
cat(sprintf("  Actual beta: %.5f\n", actual_beta))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  Permutation distribution: mean=%.5f, sd=%.5f\n",
            mean(perm_betas), sd(perm_betas)))

# ============================================================================
# 6. Alternative specification: Region-level panel
# ============================================================================
cat("\n=== Region-level aggregation ===\n")

region_panel <- panel %>%
  group_by(region, year, intensity_regional, post) %>%
  summarize(
    mean_ntl = mean(ntl_mean, na.rm = TRUE),
    log_mean_ntl = log(mean(ntl_mean, na.rm = TRUE) + 0.01),
    n_districts = n(),
    .groups = "drop"
  ) %>%
  mutate(treat_post = intensity_regional * post)

r6 <- feols(log_mean_ntl ~ treat_post | region + year,
            data = region_panel, cluster = ~region)
cat("Region-level: ")
cat(sprintf("beta = %.4f, SE = %.4f, p = %.3f\n",
            coef(r6), se(r6), pvalue(r6)))

# ============================================================================
# 7. Save all robustness results
# ============================================================================
robustness <- list(
  placebo_2017 = r1,
  excl_accra = r2,
  excl_ashanti = r3,
  region_level = r6,
  ri_pvalue = ri_pvalue,
  ri_betas = perm_betas,
  actual_beta = actual_beta
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
