## 04_robustness.R — Robustness checks and placebo tests
## apep_0533: Salary History Bans and the Gender Earnings Gap

source("00_packages.R")

df <- fread(file.path(data_dir, "analysis_aggregate.csv"))
df_ind <- fread(file.path(data_dir, "analysis_industry.csv"))

# ============================================================
# 1. Bacon Decomposition
# ============================================================

cat("=== Bacon Decomposition ===\n")

# Need a balanced panel indicator
bacon_data <- copy(df)
bacon_data[, treat_timing := fifelse(treated, ban_period, 10000L)]

# Use sunab (Sun & Abraham) as a robustness estimator
sa_hir <- feols(log_ratio_hir ~ sunab(treat_timing, period) | state + period,
                data = bacon_data[treat_timing != 10000L | treated == FALSE],
                cluster = ~state)

cat("Sun-Abraham estimator (new hires):\n")
print(summary(sa_hir))

# ============================================================
# 2. Industry-Level Heterogeneity
# ============================================================

cat("\n=== Industry Heterogeneity ===\n")

# Male-dominated industries
ind_male_dom <- feols(log_ratio_hir ~ post | state + period,
                      data = df_ind[male_dominated == TRUE],
                      cluster = ~state)

# Female-dominated industries
ind_female_dom <- feols(log_ratio_hir ~ post | state + period,
                        data = df_ind[female_dominated == TRUE],
                        cluster = ~state)

# High-wage industries
ind_high_wage <- feols(log_ratio_hir ~ post | state + period,
                       data = df_ind[high_wage == TRUE],
                       cluster = ~state)

cat("Male-dominated industries:\n")
print(summary(ind_male_dom))
cat("\nFemale-dominated industries:\n")
print(summary(ind_female_dom))
cat("\nHigh-wage industries:\n")
print(summary(ind_high_wage))

# Industry-by-industry regressions
industries <- unique(df_ind$industry)
ind_results <- list()
for (ind in industries) {
  sub <- df_ind[industry == ind & !is.na(log_ratio_hir) & is.finite(log_ratio_hir)]
  if (nrow(sub) < 100) next
  m <- tryCatch(
    feols(log_ratio_hir ~ post | state + period, data = sub, cluster = ~state),
    error = function(e) NULL
  )
  if (!is.null(m)) {
    ind_results[[ind]] <- data.table(
      industry = ind,
      coef = coef(m)["post"],
      se = se(m)["post"],
      n = nrow(sub)
    )
  }
}
ind_results_dt <- rbindlist(ind_results)
ind_results_dt[, ci_lower := coef - 1.96 * se]
ind_results_dt[, ci_upper := coef + 1.96 * se]
fwrite(ind_results_dt, file.path(data_dir, "industry_heterogeneity.csv"))

cat("\nIndustry-level results:\n")
print(ind_results_dt[order(-coef)])

# ============================================================
# 3. Exclude states with bundled pay transparency laws
# ============================================================

cat("\n=== Exclude Bundled States (CO, CA, WA) ===\n")

bundled_states <- c("08", "06", "53")  # CO, CA, WA
df_nobundle <- df[!state %in% bundled_states]

twfe_nobundle <- feols(log_ratio_hir ~ post | state + period,
                       data = df_nobundle, cluster = ~state)
cat("TWFE excl. CO/CA/WA:\n")
print(summary(twfe_nobundle))

# ============================================================
# 4. Composition Test: Female share by demographic groups
# ============================================================

cat("\n=== Composition Test: Female Hire Share ===\n")

twfe_comp <- feols(female_hire_share ~ post | state + period,
                   data = df, cluster = ~state)
cat("Female hire share:\n")
print(summary(twfe_comp))

# Female employment share
twfe_emp_share <- feols(female_emp_share ~ post | state + period,
                        data = df, cluster = ~state)
cat("\nFemale employment share:\n")
print(summary(twfe_emp_share))

# ============================================================
# 5. Randomization Inference
# ============================================================

cat("\n=== Randomization Inference ===\n")

# Get the actual TWFE coefficient
actual_coef <- coef(feols(log_ratio_hir ~ post | state + period,
                          data = df))["post"]

# Permute treatment across states
set.seed(42)
n_perms <- 500
states_list <- unique(df$state)
n_treated <- uniqueN(df[treated == TRUE]$state)

perm_coefs <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  if (i %% 100 == 0) cat(sprintf("  RI iteration %d/%d\n", i, n_perms))

  # Randomly assign treatment to same number of states
  fake_treated <- sample(states_list, n_treated)
  df_perm <- copy(df)

  # Assign fake treatment using original timing distribution (with replacement)
  real_timings <- unique(df[treated == TRUE, .(state, ban_period)])$ban_period
  fake_timings <- sample(real_timings, n_treated, replace = TRUE)

  df_perm[, fake_post := 0L]
  for (j in seq_along(fake_treated)) {
    df_perm[state == fake_treated[j] & period >= fake_timings[j],
            fake_post := 1L]
  }

  m <- tryCatch(
    feols(log_ratio_hir ~ fake_post | state + period, data = df_perm),
    error = function(e) NULL
  )
  perm_coefs[i] <- if (!is.null(m)) coef(m)["fake_post"] else NA
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_p <- mean(abs(perm_coefs) >= abs(actual_coef))

cat(sprintf("Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("RI p-value (two-sided): %.4f\n", ri_p))
cat(sprintf("RI distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

# Save RI distribution
ri_data <- data.table(perm_coef = perm_coefs,
                      actual = actual_coef,
                      ri_p = ri_p)
fwrite(ri_data, file.path(data_dir, "ri_distribution.csv"))

# ============================================================
# 6. Pre-trend test: joint significance
# ============================================================

cat("\n=== Pre-trend Formal Test ===\n")

# Event study with TWFE (relative time indicators)
df[, rel_time := period - ban_period]
df[treated == FALSE, rel_time := -1L]  # normalize untreated to base

# Create event time dummies (binned at -12 and +12)
df[, rel_time_bin := pmin(pmax(rel_time, -12L), 12L)]

es_twfe <- feols(log_ratio_hir ~ i(rel_time_bin, ref = -1) | state + period,
                 data = df[treated == TRUE | (treated == FALSE)],
                 cluster = ~state)

# Extract pre-treatment coefficients
pre_coefs <- coef(es_twfe)[grep("rel_time_bin::-[2-9]|rel_time_bin::-1[0-2]",
                                 names(coef(es_twfe)))]
pre_se <- se(es_twfe)[grep("rel_time_bin::-[2-9]|rel_time_bin::-1[0-2]",
                            names(se(es_twfe)))]

if (length(pre_coefs) > 0) {
  # Joint F-test
  f_stat <- sum((pre_coefs / pre_se)^2) / length(pre_coefs)
  f_p <- 1 - pf(f_stat, length(pre_coefs), Inf)
  cat(sprintf("Pre-trend F-stat: %.2f (p = %.4f, df = %d)\n",
              f_stat, f_p, length(pre_coefs)))
}

# Save TWFE event study data
es_twfe_data <- data.table(
  event_time = as.integer(gsub("rel_time_bin::", "", names(coef(es_twfe)))),
  coef = coef(es_twfe),
  se = se(es_twfe)
)
es_twfe_data[, ci_lower := coef - 1.96 * se]
es_twfe_data[, ci_upper := coef + 1.96 * se]
fwrite(es_twfe_data, file.path(data_dir, "event_study_twfe.csv"))

# ============================================================
# Save all robustness results
# ============================================================

rob_results <- data.table(
  test = c("Sun-Abraham (new hires)", "Male-dominated industries",
           "Female-dominated industries", "High-wage industries",
           "Excl. bundled (CO/CA/WA)", "Female hire share",
           "Female emp share", "RI p-value"),
  coef = c(
    {
      sa_coefs <- coef(sa_hir)
      post_names <- grep("^period::[0-9]", names(sa_coefs), value = TRUE)
      if (length(post_names) > 0) mean(sa_coefs[post_names]) else NA
    },
    coef(ind_male_dom)["post"],
    coef(ind_female_dom)["post"],
    coef(ind_high_wage)["post"],
    coef(twfe_nobundle)["post"],
    coef(twfe_comp)["post"],
    coef(twfe_emp_share)["post"],
    ri_p
  ),
  se = c(
    {
      sa_ses <- se(sa_hir)
      post_names_se <- grep("^period::[0-9]", names(sa_ses), value = TRUE)
      if (length(post_names_se) > 0) sqrt(mean(sa_ses[post_names_se]^2)) else NA
    },
    se(ind_male_dom)["post"],
    se(ind_female_dom)["post"],
    se(ind_high_wage)["post"],
    se(twfe_nobundle)["post"],
    se(twfe_comp)["post"],
    se(twfe_emp_share)["post"],
    NA
  ),
  n = c(
    nobs(sa_hir),
    nobs(ind_male_dom),
    nobs(ind_female_dom),
    nobs(ind_high_wage),
    nobs(twfe_nobundle),
    nobs(twfe_comp),
    nobs(twfe_emp_share),
    nrow(df)
  )
)

fwrite(rob_results, file.path(data_dir, "robustness_results.csv"))

save(sa_hir, ind_male_dom, ind_female_dom, ind_high_wage,
     twfe_nobundle, twfe_comp, twfe_emp_share,
     file = file.path(data_dir, "robustness_regressions.RData"))

cat("\nRobustness checks complete.\n")
