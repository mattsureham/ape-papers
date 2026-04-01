# 04_robustness.R — Robustness checks
# apep_1282: The Double Squeeze

source("00_packages.R")
load("../data/results.RData")

cat("=== Robustness Checks ===\n")

# ------------------------------------------------------------------
# 1. Placebo outcome: Prime-age employment (45-54)
# ------------------------------------------------------------------
cat("\n--- Placebo: Prime-age employment 45-54 ---\n")

rob_placebo <- feols(emp_prime ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                     | region + year,
                     data = panel, cluster = ~region)
cat("Placebo (45-54 employment):\n")
summary(rob_placebo)

# ------------------------------------------------------------------
# 2. Placebo outcome: Older worker employment (55-64)
# ------------------------------------------------------------------
cat("\n--- Placebo: Older worker employment 55-64 ---\n")

rob_older <- feols(emp_older ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                   | region + year,
                   data = panel, cluster = ~region)
cat("Placebo (55-64 employment):\n")
summary(rob_older)

# ------------------------------------------------------------------
# 3. Alternative Fornero bite: 2010-2016 change
# ------------------------------------------------------------------
cat("\n--- Alternative Fornero bite (2010-2016) ---\n")

load("../data/raw_data.RData")

emp55_64 <- emp |> filter(age == "Y55-64")
fb_alt_pre <- emp55_64 |> filter(year == 2010) |> select(region, emp_2010 = emp_rate)
fb_alt_post <- emp55_64 |> filter(year == 2016) |> select(region, emp_2016 = emp_rate)

fornero_alt <- inner_join(fb_alt_pre, fb_alt_post, by = "region") |>
  mutate(fornero_alt = emp_2016 - emp_2010,
         fornero_alt_sd = (fornero_alt - mean(fornero_alt, na.rm = TRUE)) /
           sd(fornero_alt, na.rm = TRUE))

panel_alt <- panel |>
  left_join(fornero_alt |> select(region, fornero_alt_sd), by = "region") |>
  mutate(
    fornero_alt_x_post = fornero_alt_sd * post_fornero,
    triple_alt = fornero_alt_sd * rdc_rate_sd * post_rdc
  )

rob_alt_bite <- feols(neet_rate ~ fornero_alt_x_post + rdc_x_post_sd + triple_alt
                      | region + year,
                      data = panel_alt, cluster = ~region)
cat("Alternative Fornero bite (2010-2016):\n")
summary(rob_alt_bite)

# ------------------------------------------------------------------
# 4. Leave-one-region-out sensitivity
# ------------------------------------------------------------------
cat("\n--- Leave-one-out: Triple coefficient stability ---\n")

regions <- unique(panel$region)
loo_results <- data.frame(
  excluded = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (r in regions) {
  m_loo <- feols(neet_rate ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                 | region + year,
                 data = panel |> filter(region != r),
                 cluster = ~region)
  loo_results <- rbind(loo_results, data.frame(
    excluded = r,
    coef = coef(m_loo)["triple_sd"],
    se = se(m_loo)["triple_sd"],
    stringsAsFactors = FALSE
  ))
}

cat("Leave-one-out range for triple coefficient (NEET):\n")
cat(sprintf("  Min: %.3f (excl %s)\n", min(loo_results$coef),
            loo_results$excluded[which.min(loo_results$coef)]))
cat(sprintf("  Max: %.3f (excl %s)\n", max(loo_results$coef),
            loo_results$excluded[which.max(loo_results$coef)]))
cat(sprintf("  Full sample: %.3f\n", coef(results$phase2_neet)["triple_sd"]))

# ------------------------------------------------------------------
# 5. Excluding COVID years (2020-2021)
# ------------------------------------------------------------------
cat("\n--- Excluding COVID years (2020-2021) ---\n")

rob_nocovid <- feols(neet_rate ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                     | region + year,
                     data = panel |> filter(!(year %in% c(2020, 2021))),
                     cluster = ~region)
cat("Excluding 2020-2021:\n")
summary(rob_nocovid)

# ------------------------------------------------------------------
# 6. Permutation inference on triple coefficient
# ------------------------------------------------------------------
cat("\n--- Permutation inference ---\n")

set.seed(123)
n_perms <- 1000
actual_coef <- coef(results$phase2_neet)["triple_sd"]

perm_coefs <- numeric(n_perms)
region_data <- panel |>
  select(region, fornero_bite_sd, rdc_rate_sd) |>
  distinct()

for (i in seq_len(n_perms)) {
  # Shuffle both treatment assignments across regions
  perm_fb <- sample(region_data$fornero_bite_sd)
  perm_rdc <- sample(region_data$rdc_rate_sd)

  perm_map <- data.frame(
    region = region_data$region,
    perm_fb_sd = perm_fb,
    perm_rdc_sd = perm_rdc,
    stringsAsFactors = FALSE
  )

  panel_perm <- panel |>
    left_join(perm_map, by = "region") |>
    mutate(
      perm_fb_post = perm_fb_sd * post_fornero,
      perm_rdc_post = perm_rdc_sd * post_rdc,
      perm_triple = perm_fb_sd * perm_rdc_sd * post_rdc
    )

  m_perm <- tryCatch({
    feols(neet_rate ~ perm_fb_post + perm_rdc_post + perm_triple
          | region + year,
          data = panel_perm, cluster = ~region)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    perm_coefs[i] <- coef(m_perm)["perm_triple"]
  } else {
    perm_coefs[i] <- NA
  }
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
perm_pval <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("Permutation p-value (two-sided, %d permutations): %.4f\n",
            length(perm_coefs), perm_pval))
cat(sprintf("Actual coefficient: %.3f\n", actual_coef))
cat(sprintf("Permutation distribution: mean=%.3f, sd=%.3f\n",
            mean(perm_coefs), sd(perm_coefs)))

# ------------------------------------------------------------------
# Save robustness results
# ------------------------------------------------------------------
robustness <- list(
  placebo_prime = rob_placebo,
  placebo_older = rob_older,
  alt_bite = rob_alt_bite,
  loo = loo_results,
  nocovid = rob_nocovid,
  perm_pval = perm_pval,
  perm_coefs = perm_coefs,
  actual_coef = actual_coef
)

save(robustness, file = "../data/robustness.RData")
cat("\nRobustness results saved.\n")
