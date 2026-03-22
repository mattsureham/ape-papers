## 04_robustness.R — Robustness checks and validation
## apep_0741: Hands-Free Driving Laws and Fatal Crashes at State Borders

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

## ---- Load data ----
load(file.path(data_dir, "analysis_results.RData"))
cat("Loaded analysis results.\n")

## ---- 1. Donut RDD: Exclude crashes within 2km of border ----
cat("\n=== Donut RDD (exclude <2km from border) ===\n")

cm_donut <- county_month[mean_dist >= 2 & mean_dist <= 30]

m_donut <- feols(n_crashes ~ treated_side * post | pair_id + YEAR:MONTH,
                 data = cm_donut, cluster = ~STATE + COUNTY)

cat("Donut (2-30km): coef =", round(coef(m_donut)["treated_side:post"], 4),
    "se =", round(se(m_donut)["treated_side:post"], 4), "\n")

m_donut_phone <- feols(n_phone ~ treated_side * post | pair_id + YEAR:MONTH,
                       data = cm_donut, cluster = ~STATE + COUNTY)

cat("Donut phone:    coef =", round(coef(m_donut_phone)["treated_side:post"], 4),
    "se =", round(se(m_donut_phone)["treated_side:post"], 4), "\n")

## ---- 2. Pre-treatment falsification ----
cat("\n=== Pre-treatment falsification ===\n")

# Use only pre-treatment data and assign a placebo treatment 2 years before actual
cm_pre <- county_month[post == 0]

# Create placebo post indicator (2 years before actual treatment)
cm_pre[, placebo_post := as.integer(
  YEAR > (treat_year - 2) |
  (YEAR == (treat_year - 2) & MONTH >= treat_month)
)]

m_placebo <- feols(n_crashes ~ treated_side * placebo_post | pair_id + YEAR:MONTH,
                   data = cm_pre, cluster = ~STATE + COUNTY)

cat("Placebo (2yr prior): coef =", round(coef(m_placebo)["treated_side:placebo_post"], 4),
    "se =", round(se(m_placebo)["treated_side:placebo_post"], 4),
    "p =", round(pvalue(m_placebo)["treated_side:placebo_post"], 4), "\n")

## ---- 3. Pair-by-pair estimates ----
cat("\n=== Pair-by-pair estimates (30km) ===\n")

pair_results <- list()
cm30 <- county_month[mean_dist <= 30]

for (pid in sort(unique(cm30$pair_id))) {
  sub <- cm30[pair_id == pid]
  if (nrow(sub) < 10 || length(unique(sub$treated_side)) < 2) next

  m <- tryCatch(
    feols(n_crashes ~ treated_side * post | YEAR:MONTH,
          data = sub, cluster = ~STATE + COUNTY),
    error = function(e) NULL
  )

  if (!is.null(m)) {
    pair_results[[as.character(pid)]] <- data.table(
      pair_id = pid,
      treated = sub$treated_abbr[1],
      control = sub$control_abbr[1],
      coef = coef(m)["treated_side:post"],
      se = se(m)["treated_side:post"],
      pval = pvalue(m)["treated_side:post"],
      n_obs = nrow(sub)
    )
    cat("  Pair", pid, "(", sub$treated_abbr[1], "-", sub$control_abbr[1], "):",
        "coef =", round(coef(m)["treated_side:post"], 4),
        "se =", round(se(m)["treated_side:post"], 4), "\n")
  }
}

pair_dt <- rbindlist(pair_results)
cat("\nPair estimates computed:", nrow(pair_dt), "\n")

## ---- 4. Drunk driving placebo ----
cat("\n=== Drunk driving placebo ===\n")

# Drunk driving should NOT respond to cellphone bans
# n_drunk already in county_month from 02_clean_data.R
m_drunk <- feols(n_drunk ~ treated_side * post | pair_id + YEAR:MONTH,
                 data = cm30, cluster = ~STATE + COUNTY)

cat("Drunk driving: coef =", round(coef(m_drunk)["treated_side:post"], 4),
    "se =", round(se(m_drunk)["treated_side:post"], 4),
    "p =", round(pvalue(m_drunk)["treated_side:post"], 4), "\n")

## ---- 5. Wild cluster bootstrap (few clusters) ----
cat("\n=== Wild cluster bootstrap ===\n")

# Use pair-level clustering for conservative inference
m_pair_cluster <- feols(n_crashes ~ treated_side * post | pair_id + YEAR:MONTH,
                        data = cm30, cluster = ~pair_id)

cat("Pair-clustered: coef =", round(coef(m_pair_cluster)["treated_side:post"], 4),
    "se =", round(se(m_pair_cluster)["treated_side:post"], 4), "\n")

# Randomization inference: permute treatment assignment across pairs
set.seed(42)
n_perms <- 999
obs_coef <- coef(m_pair_cluster)["treated_side:post"]

ri_coefs <- replicate(n_perms, {
  cm_perm <- copy(cm30)
  # Randomly reassign treated_side within each pair
  pair_ids <- unique(cm_perm$pair_id)
  for (pid in pair_ids) {
    idx <- cm_perm$pair_id == pid
    cm_perm[idx, treated_side := sample(treated_side)]
  }
  cm_perm[, post_treat := treated_side * post]
  m_p <- tryCatch(
    feols(n_crashes ~ post_treat + treated_side + post | pair_id + YEAR:MONTH,
          data = cm_perm, cluster = ~pair_id),
    error = function(e) NULL
  )
  if (!is.null(m_p)) coef(m_p)["post_treat"] else NA_real_
})

ri_pval <- mean(abs(ri_coefs) >= abs(obs_coef), na.rm = TRUE)
cat("  RI p-value (999 permutations):", round(ri_pval, 4), "\n")

boot_result <- list(p_val = ri_pval, ci = quantile(ri_coefs, c(0.025, 0.975), na.rm = TRUE))

## ---- 6. Distance polynomial controls ----
cat("\n=== Distance polynomial controls ===\n")

# Add distance controls to the regression
m_dist_linear <- feols(n_crashes ~ treated_side * post + signed_dist |
                         pair_id + YEAR:MONTH,
                       data = cm30, cluster = ~STATE + COUNTY)

cm30[, signed_dist2 := signed_dist^2]
m_dist_quad <- feols(n_crashes ~ treated_side * post + signed_dist + signed_dist2 |
                       pair_id + YEAR:MONTH,
                     data = cm30, cluster = ~STATE + COUNTY)

cat("Linear dist control: coef =", round(coef(m_dist_linear)["treated_side:post"], 4),
    "se =", round(se(m_dist_linear)["treated_side:post"], 4), "\n")
cat("Quadratic dist control: coef =", round(coef(m_dist_quad)["treated_side:post"], 4),
    "se =", round(se(m_dist_quad)["treated_side:post"], 4), "\n")

## ---- Save robustness results ----
robustness <- list(
  donut = list(coef = coef(m_donut)["treated_side:post"],
               se = se(m_donut)["treated_side:post"]),
  placebo_pre = list(coef = coef(m_placebo)["treated_side:placebo_post"],
                     se = se(m_placebo)["treated_side:placebo_post"],
                     pval = pvalue(m_placebo)["treated_side:placebo_post"]),
  drunk_placebo = list(coef = coef(m_drunk)["treated_side:post"],
                       se = se(m_drunk)["treated_side:post"],
                       pval = pvalue(m_drunk)["treated_side:post"]),
  pair_estimates = pair_dt,
  boot_result = if (!is.null(boot_result)) list(
    pval = boot_result$p_val,
    ci = boot_result$conf_int
  ) else NULL,
  dist_linear = list(coef = coef(m_dist_linear)["treated_side:post"],
                     se = se(m_dist_linear)["treated_side:post"]),
  dist_quad = list(coef = coef(m_dist_quad)["treated_side:post"],
                   se = se(m_dist_quad)["treated_side:post"])
)

save(robustness, pair_dt, m_donut, m_donut_phone, m_placebo, m_drunk,
     m_pair_cluster, boot_result, m_dist_linear, m_dist_quad,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\nRobustness results saved.\n")
cat("Done.\n")
