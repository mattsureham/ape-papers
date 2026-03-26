# 04b_inference.R — Randomization inference for six-cluster problem
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry
#
# With only 6 state clusters, asymptotic inference is unreliable.
# This script implements two forms of randomization inference:
# 1. Permute the treatment STATE (assign "Illinois" to each control state)
# 2. Permute the treatment TIMING (assign Rosenbach to random quarters)

source("00_packages.R")

df_border <- fread("../data/border_panel.csv")
df_border <- df_border[sector != "total"]

cat("=== RANDOMIZATION INFERENCE ===\n")

# ============================================================
# Part 1: Permute treatment state
# ============================================================

cat("\n--- Permuting Treatment State ---\n")

# Actual estimate
m_actual <- feols(log_emp ~ triple_cont + il_post + exposure_post + il_exposure |
                    county_sector + yearqtr,
                  data = df_border, cluster = ~state_fips)
actual_coef <- coef(m_actual)["triple_cont"]
cat(sprintf("Actual estimate: %.4f\n", actual_coef))

# Placebo: assign treatment to each control state in turn
control_states <- unique(df_border[illinois == 0]$state_fips)
placebo_state_coefs <- numeric(length(control_states))

for (i in seq_along(control_states)) {
  st <- control_states[i]
  df_perm <- copy(df_border)

  # Reassign "treated state" to control state st
  df_perm[, illinois_perm := fifelse(state_fips == st, 1L, 0L)]
  df_perm[, triple_perm := illinois_perm * post * bio_exposure_std]
  df_perm[, il_post_perm := illinois_perm * post]
  df_perm[, il_exp_perm := illinois_perm * bio_exposure_std]

  m_perm <- tryCatch(
    feols(log_emp ~ triple_perm + il_post_perm + exposure_post + il_exp_perm |
            county_sector + yearqtr,
          data = df_perm, cluster = ~state_fips),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    placebo_state_coefs[i] <- coef(m_perm)["triple_perm"]
  } else {
    placebo_state_coefs[i] <- NA
  }

  cat(sprintf("  State %s: β=%.4f\n", st, placebo_state_coefs[i]))
}

# RI p-value: fraction of placebos as extreme as actual (two-sided)
all_coefs_state <- c(actual_coef, placebo_state_coefs[!is.na(placebo_state_coefs)])
ri_pval_state <- mean(abs(all_coefs_state) >= abs(actual_coef))
cat(sprintf("\nRI p-value (state permutation): %.3f (%d/%d as extreme)\n",
            ri_pval_state,
            sum(abs(all_coefs_state) >= abs(actual_coef)),
            length(all_coefs_state)))

# ============================================================
# Part 2: Permute treatment timing
# ============================================================

cat("\n--- Permuting Treatment Timing ---\n")

# Assign Rosenbach to random quarters in the pre-period
# This tests whether any arbitrary quarter shows a similar break
placebo_quarters <- unique(df_border[post == 0]$yearqtr)
# Remove first 4 quarters (need enough pre-period) and last 2
placebo_quarters <- placebo_quarters[3:(length(placebo_quarters) - 2)]

placebo_time_coefs <- numeric(length(placebo_quarters))

for (i in seq_along(placebo_quarters)) {
  pq <- placebo_quarters[i]
  df_perm <- copy(df_border)

  # Create fake post indicator
  pq_year <- as.integer(substr(pq, 1, 4))
  pq_qtr <- as.integer(substr(pq, 6, 6))
  df_perm[, post_fake := fifelse(year > pq_year | (year == pq_year & qtr >= pq_qtr), 1L, 0L)]
  df_perm[, triple_fake := illinois * post_fake * bio_exposure_std]
  df_perm[, il_post_fake := illinois * post_fake]
  df_perm[, exp_post_fake := bio_exposure_std * post_fake]

  m_perm <- tryCatch(
    feols(log_emp ~ triple_fake + il_post_fake + exp_post_fake + il_exposure |
            county_sector + yearqtr,
          data = df_perm, cluster = ~state_fips),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    placebo_time_coefs[i] <- coef(m_perm)["triple_fake"]
  } else {
    placebo_time_coefs[i] <- NA
  }
}

# RI p-value (timing)
all_coefs_time <- c(actual_coef, placebo_time_coefs[!is.na(placebo_time_coefs)])
ri_pval_time <- mean(abs(all_coefs_time) >= abs(actual_coef))
cat(sprintf("RI p-value (timing permutation): %.3f (%d/%d as extreme)\n",
            ri_pval_time,
            sum(abs(all_coefs_time) >= abs(actual_coef)),
            length(all_coefs_time)))

# ============================================================
# Save results
# ============================================================

ri_results <- data.table(
  type = c(rep("state", length(all_coefs_state) - 1),
           rep("timing", length(all_coefs_time) - 1),
           "actual"),
  coef = c(placebo_state_coefs[!is.na(placebo_state_coefs)],
           placebo_time_coefs[!is.na(placebo_time_coefs)],
           actual_coef)
)

fwrite(ri_results, "../data/randomization_inference.csv")

ri_summary <- list(
  actual_coef = actual_coef,
  ri_pval_state = ri_pval_state,
  ri_pval_time = ri_pval_time,
  n_state_permutations = sum(!is.na(placebo_state_coefs)),
  n_time_permutations = sum(!is.na(placebo_time_coefs))
)
jsonlite::write_json(ri_summary, "../data/ri_summary.json", auto_unbox = TRUE)

cat("\n=== RANDOMIZATION INFERENCE COMPLETE ===\n")
cat(sprintf("Summary: actual=%.4f, RI p(state)=%.3f, RI p(time)=%.3f\n",
            actual_coef, ri_pval_state, ri_pval_time))
