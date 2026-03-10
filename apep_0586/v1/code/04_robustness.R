# ==============================================================================
# 04_robustness.R — Robustness checks
# apep_0586: Winning the Peace
# ==============================================================================

source("00_packages.R")

set.seed(42)
df <- fread("../data/analysis_sample.csv")
# Same 30% sample as main analysis for consistency
sample_idx <- sample(nrow(df), size = floor(nrow(df) * 0.30))
df <- df[sample_idx]
gc()

main_sample <- df[cohort_group %in% c("draft_eligible", "older_control")]
main_sample[, birth_year := as.factor(birth_year)]
main_sample[, statefip_1940 := as.factor(statefip_1940)]

cat("Robustness sample:", nrow(main_sample), "\n")

# ==============================================================================
# 1. Leave-One-Out: Drop each state
# ==============================================================================

cat("\n=== LEAVE-ONE-OUT ===\n")

states <- unique(as.numeric(as.character(main_sample$statefip_1940)))
loo_results <- list()

for (s in states) {
  sub <- main_sample[as.numeric(as.character(statefip_1940)) != s]
  fit <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
                 occscore_1940 + white + married_1940 + farm_1940_d + native_born |
                 statefip_1940 + birth_year,
               data = sub, cluster = ~statefip_1940)
  loo_results[[as.character(s)]] <- data.table(
    dropped_state = s,
    coef = coef(fit)["mob_x_draft"],
    se = se(fit)["mob_x_draft"],
    n = fit$nobs
  )
}

loo_dt <- rbindlist(loo_results)
cat("LOO range:", round(range(loo_dt$coef), 4), "\n")
cat("Full-sample coef falls within LOO range:",
    any(loo_dt$coef > 0) & any(loo_dt$coef > 0), "\n")
fwrite(loo_dt, "../data/leave_one_out.csv")

# ==============================================================================
# 2. Randomization Inference
# ==============================================================================

cat("\n=== RANDOMIZATION INFERENCE ===\n")

# Baseline: compute actual test statistic
base_fit <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
                    occscore_1940 + white + married_1940 + farm_1940_d + native_born |
                    statefip_1940 + birth_year,
                  data = main_sample, cluster = ~statefip_1940)
actual_t <- coef(base_fit)["mob_x_draft"] / se(base_fit)["mob_x_draft"]

# Permute mobilization exposure across states
set.seed(20260310)
n_perms <- 1000
perm_t <- numeric(n_perms)

# Get unique state-level data
state_mob <- unique(main_sample[, .(statefip_1940, mob_exposure_std, mob_x_draft)])
state_vals <- unique(main_sample[, .(statefip_1940 = as.character(statefip_1940),
                                      mob_exposure_std)])

for (i in 1:n_perms) {
  if (i %% 100 == 0) cat("  Permutation", i, "of", n_perms, "\n")

  # Shuffle mob_exposure across states
  perm_mob <- state_vals[, .(statefip_1940,
                              mob_perm = sample(mob_exposure_std))]

  # Merge back and create interaction
  temp <- merge(main_sample[, .(delta_occscore_40_50, educ_years_1940,
                                 occscore_1940, white, married_1940,
                                 farm_1940_d, native_born, draft_eligible,
                                 statefip_1940, birth_year)],
                perm_mob,
                by = "statefip_1940")
  temp[, mob_x_draft_perm := mob_perm * draft_eligible]

  fit_perm <- tryCatch({
    feols(delta_occscore_40_50 ~ mob_x_draft_perm + educ_years_1940 +
            occscore_1940 + white + married_1940 + farm_1940_d + native_born |
            statefip_1940 + birth_year,
          data = temp, cluster = ~statefip_1940)
  }, error = function(e) NULL)

  if (!is.null(fit_perm)) {
    perm_t[i] <- coef(fit_perm)["mob_x_draft_perm"] / se(fit_perm)["mob_x_draft_perm"]
  } else {
    perm_t[i] <- NA
  }
}

perm_t <- perm_t[!is.na(perm_t)]
ri_pval <- mean(abs(perm_t) >= abs(actual_t))
cat("RI p-value:", ri_pval, "(actual t =", round(actual_t, 3), ")\n")

ri_results <- data.table(
  actual_t = actual_t,
  ri_pval = ri_pval,
  n_perms = length(perm_t),
  perm_t_mean = mean(perm_t),
  perm_t_sd = sd(perm_t)
)
fwrite(ri_results, "../data/ri_results.csv")

# Save permutation distribution for figure
fwrite(data.table(perm_t = perm_t), "../data/ri_distribution.csv")

# ==============================================================================
# 3. Alternative Cohort Definitions
# ==============================================================================

cat("\n=== ALTERNATIVE COHORT DEFINITIONS ===\n")

alt_cohort_results <- list()

# Alt 1: Broader draft-eligible (1910-1922)
df_alt1 <- df[birth_year >= 1895 & birth_year <= 1922]
df_alt1[, draft_elig_alt := as.integer(as.numeric(as.character(birth_year)) >= 1910)]
df_alt1[, mob_x_draft_alt := mob_exposure_std * draft_elig_alt]
df_alt1[, birth_year := as.factor(birth_year)]
df_alt1[, statefip_1940 := as.factor(statefip_1940)]

fit_alt1 <- feols(delta_occscore_40_50 ~ mob_x_draft_alt + educ_years_1940 +
                    occscore_1940 + white + married_1940 + farm_1940_d + native_born |
                    statefip_1940 + birth_year,
                  data = df_alt1, cluster = ~statefip_1940)

# Alt 2: Narrower (1917-1922, youngest and most likely drafted)
df_alt2 <- df[cohort_group %in% c("draft_eligible", "older_control")]
df_alt2[, draft_elig_narrow := as.integer(as.numeric(as.character(birth_year)) >= 1917)]
df_alt2[, mob_x_draft_narrow := mob_exposure_std * draft_elig_narrow]
df_alt2[, birth_year := as.factor(birth_year)]
df_alt2[, statefip_1940 := as.factor(statefip_1940)]

fit_alt2 <- feols(delta_occscore_40_50 ~ mob_x_draft_narrow + educ_years_1940 +
                    occscore_1940 + white + married_1940 + farm_1940_d + native_born |
                    statefip_1940 + birth_year,
                  data = df_alt2, cluster = ~statefip_1940)

alt_cohort_results <- data.table(
  definition = c("Main (1915-1922)", "Broad (1910-1922)", "Narrow (1917-1922)"),
  coef = c(coef(base_fit)["mob_x_draft"],
           coef(fit_alt1)["mob_x_draft_alt"],
           coef(fit_alt2)["mob_x_draft_narrow"]),
  se = c(se(base_fit)["mob_x_draft"],
         se(fit_alt1)["mob_x_draft_alt"],
         se(fit_alt2)["mob_x_draft_narrow"]),
  n = c(base_fit$nobs, fit_alt1$nobs, fit_alt2$nobs)
)
cat("Alternative cohort results:\n")
print(alt_cohort_results)
fwrite(alt_cohort_results, "../data/alt_cohort_results.csv")

# ==============================================================================
# 4. Migration Controls
# ==============================================================================

cat("\n=== MIGRATION CONTROLS ===\n")

# Control for inter-state migration
fit_mig <- feols(delta_occscore_40_50 ~ mob_x_draft + mover_40_50 +
                   educ_years_1940 + occscore_1940 + white + married_1940 +
                   farm_1940_d + native_born |
                   statefip_1940 + birth_year,
                 data = main_sample, cluster = ~statefip_1940)

# Drop movers entirely
fit_stayers <- feols(delta_occscore_40_50 ~ mob_x_draft + educ_years_1940 +
                       occscore_1940 + white + married_1940 + farm_1940_d + native_born |
                       statefip_1940 + birth_year,
                     data = main_sample[mover_40_50 == 0], cluster = ~statefip_1940)

migration_results <- data.table(
  spec = c("control_for_moving", "stayers_only"),
  coef = c(coef(fit_mig)["mob_x_draft"], coef(fit_stayers)["mob_x_draft"]),
  se = c(se(fit_mig)["mob_x_draft"], se(fit_stayers)["mob_x_draft"]),
  n = c(fit_mig$nobs, fit_stayers$nobs)
)
cat("Migration controls:\n")
print(migration_results)
fwrite(migration_results, "../data/migration_results.csv")

# ==============================================================================
# 5. Compile robustness summary
# ==============================================================================

robustness_summary <- rbind(
  data.table(test = "Main estimate", coef = coef(base_fit)["mob_x_draft"],
             se = se(base_fit)["mob_x_draft"], n = base_fit$nobs,
             detail = "Preferred specification"),
  data.table(test = "LOO range", coef = median(loo_dt$coef),
             se = sd(loo_dt$coef), n = nrow(loo_dt),
             detail = paste("Range:", paste(round(range(loo_dt$coef), 4), collapse = " to "))),
  data.table(test = "RI p-value", coef = actual_t,
             se = ri_pval, n = length(perm_t),
             detail = paste("p =", round(ri_pval, 4))),
  data.table(test = "Broad cohort", coef = coef(fit_alt1)["mob_x_draft_alt"],
             se = se(fit_alt1)["mob_x_draft_alt"], n = fit_alt1$nobs,
             detail = "Draft-eligible: 1910-1922"),
  data.table(test = "Narrow cohort", coef = coef(fit_alt2)["mob_x_draft_narrow"],
             se = se(fit_alt2)["mob_x_draft_narrow"], n = fit_alt2$nobs,
             detail = "Draft-eligible: 1917-1922"),
  data.table(test = "Control migration", coef = coef(fit_mig)["mob_x_draft"],
             se = se(fit_mig)["mob_x_draft"], n = fit_mig$nobs,
             detail = "Add mover_40_50 control"),
  data.table(test = "Stayers only", coef = coef(fit_stayers)["mob_x_draft"],
             se = se(fit_stayers)["mob_x_draft"], n = fit_stayers$nobs,
             detail = "Drop inter-state movers")
)

fwrite(robustness_summary, "../data/robustness_summary.csv")
cat("\nRobustness checks complete.\n")
print(robustness_summary[, .(test, coef = round(coef, 4), se = round(se, 4), n)])
