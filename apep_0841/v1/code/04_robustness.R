## 04_robustness.R — Robustness checks
## apep_0841: Poland 500+ and Female Labor Supply

source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- readRDS("../data/analysis_panel.rds")
pl <- panel[panel$poland == 1, ]

# ─── 1. Male Employment (Placebo Outcome) ──────────────────────────────────
cat("\n--- 1. Male employment as placebo outcome ---\n")

r1_simple <- feols(emp_rate_m ~ poland_post | nuts2 + year,
                   data = panel[!is.na(panel$emp_rate_m), ], cluster = ~nuts2)
cat("Male emp × Poland×Post:\n")
print(summary(r1_simple))

r1_intensity <- feols(emp_rate_m ~ intensity_post | nuts2 + year,
                      data = pl[!is.na(pl$emp_rate_m), ], cluster = ~nuts2)
cat("Male emp × Intensity×Post (Poland only):\n")
print(summary(r1_intensity))

# ─── 2. Placebo Treatment Years ────────────────────────────────────────────
cat("\n--- 2. Placebo treatment years ---\n")

pre_panel <- panel[panel$year <= 2018, ]

placebo_results <- list()
for (placebo_year in c(2014, 2016, 2017)) {
  pre_panel$placebo_post <- as.integer(pre_panel$year >= placebo_year)
  pre_panel$placebo_poland_post <- pre_panel$poland * pre_panel$placebo_post

  r_placebo <- feols(emp_rate_f ~ placebo_poland_post | nuts2 + year,
                     data = pre_panel, cluster = ~nuts2)

  placebo_results[[as.character(placebo_year)]] <- list(
    year = placebo_year,
    coef = coef(r_placebo)["placebo_poland_post"],
    se = sqrt(diag(vcov(r_placebo)))["placebo_poland_post"],
    pval = summary(r_placebo)$coeftable["placebo_poland_post", "Pr(>|t|)"]
  )
  cat(sprintf("  Placebo %d: coef=%.3f, se=%.3f, p=%.3f\n",
              placebo_year,
              placebo_results[[as.character(placebo_year)]]$coef,
              placebo_results[[as.character(placebo_year)]]$se,
              placebo_results[[as.character(placebo_year)]]$pval))
}

# ─── 3. Permutation Inference ──────────────────────────────────────────────
cat("\n--- 3. Permutation inference (Poland-only intensity DiD) ---\n")

# With 16 clusters, use permutation/randomization inference
m_for_boot <- feols(emp_rate_f ~ intensity_post | nuts2 + year,
                    data = pl, cluster = ~nuts2)

# Simple permutation test: shuffle treatment intensity across regions
set.seed(42)
n_perms <- 999
actual_coef <- coef(m_for_boot)["intensity_post"]
perm_coefs <- numeric(n_perms)

for (p in 1:n_perms) {
  pl_perm <- pl
  # Shuffle treatment intensity across regions
  region_ti <- unique(pl[, c("nuts2", "treat_intensity_std")])
  region_ti$treat_intensity_std <- sample(region_ti$treat_intensity_std)
  pl_perm$treat_intensity_std <- region_ti$treat_intensity_std[
    match(pl_perm$nuts2, region_ti$nuts2)]
  pl_perm$intensity_post <- pl_perm$treat_intensity_std * pl_perm$post2019

  m_perm <- feols(emp_rate_f ~ intensity_post | nuts2 + year,
                  data = pl_perm, cluster = ~nuts2)
  perm_coefs[p] <- coef(m_perm)["intensity_post"]
}

perm_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("  Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("  Permutation p-value (two-sided): %.4f\n", perm_p))
boot_p <- perm_p

# ─── 4. Leave-One-Region-Out ──────────────────────────────────────────────
cat("\n--- 4. Leave-one-region-out sensitivity ---\n")

pl_regions <- unique(pl$nuts2)
loo_coefs <- numeric(length(pl_regions))
names(loo_coefs) <- pl_regions

for (i in seq_along(pl_regions)) {
  loo_data <- pl[pl$nuts2 != pl_regions[i], ]
  loo_m <- feols(emp_rate_f ~ intensity_post | nuts2 + year,
                 data = loo_data, cluster = ~nuts2)
  loo_coefs[i] <- coef(loo_m)["intensity_post"]
}

cat(sprintf("  LOO coefficient range: [%.3f, %.3f]\n",
            min(loo_coefs), max(loo_coefs)))
cat(sprintf("  Full sample coefficient: %.3f\n",
            coef(m_for_boot)["intensity_post"]))

# ─── 5. Drop Romania and Bulgaria (more different economies) ──────────────
cat("\n--- 5. Restricted control group (CZ, SK, HU only) ---\n")

panel_restricted <- panel[panel$country %in% c("PL", "CZ", "SK", "HU"), ]
r5 <- feols(emp_rate_f ~ poland_post | nuts2 + year,
            data = panel_restricted, cluster = ~nuts2)
cat("Poland×Post (CZ/SK/HU controls only):\n")
print(summary(r5))

# ─── 6. Exclude COVID years ──────────────────────────────────────────────
cat("\n--- 6. Exclude 2020-2021 (COVID years) ---\n")

panel_nocovid <- panel[!panel$year %in% c(2020, 2021), ]
r6 <- feols(emp_rate_f ~ poland_post | nuts2 + year,
            data = panel_nocovid, cluster = ~nuts2)
cat("Poland×Post (excluding 2020-2021):\n")
print(summary(r6))

# ─── Save robustness results ──────────────────────────────────────────────
rob_results <- list(
  male_placebo_simple = r1_simple,
  male_placebo_intensity = r1_intensity,
  placebo_years = placebo_results,
  permutation_p = if (exists("boot_p")) boot_p else NA,
  loo_range = range(loo_coefs),
  restricted_controls = r5,
  no_covid = r6
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
