# ==============================================================================
# 04_robustness.R — Robustness checks and placebos
# Paper: The Recertification Ripple (apep_0968)
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
load(file.path(data_dir, "main_models.RData"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# =============================================================================
# R1: Non-IES placebo — run main spec on non-IES states only
# The coefficient on recert_intensity should capture the full effect
# (no interaction needed since IES=0 for all)
# =============================================================================

cat("--- R1: Non-IES placebo ---\n")

df_non_ies <- df_main %>% filter(ies_status == 0)
df_ies <- df_main %>% filter(ies_status == 1)

r1_non_ies <- feols(abs_pct_change ~ recert_intensity |
                      state_abbr + ym_factor,
                    data = df_non_ies,
                    cluster = ~state_abbr)

r1_ies <- feols(abs_pct_change ~ recert_intensity |
                  state_abbr + ym_factor,
                data = df_ies,
                cluster = ~state_abbr)

cat("Non-IES states (placebo — should be ≤0):\n")
print(summary(r1_non_ies))
cat("\nIES states (should be positive):\n")
print(summary(r1_ies))

# =============================================================================
# R2: Leave-one-out — drop each IES state individually
# =============================================================================

cat("\n--- R2: Leave-one-out sensitivity ---\n")

ies_states <- unique(df_main$state_abbr[df_main$ies_status == 1])
loo_results <- data.frame(
  dropped_state = character(),
  coef = numeric(),
  se = numeric(),
  p_value = numeric(),
  stringsAsFactors = FALSE
)

for (st in ies_states) {
  df_loo <- df_main %>% filter(state_abbr != st)
  m_loo <- feols(abs_pct_change ~ recert_intensity * ies_status |
                   state_abbr + ym_factor,
                 data = df_loo,
                 cluster = ~state_abbr,
                 warn = FALSE)
  coefs <- coeftable(m_loo)
  idx <- grep("recert_intensity:ies_status", rownames(coefs))
  if (length(idx) > 0) {
    loo_results <- rbind(loo_results, data.frame(
      dropped_state = st,
      coef = coefs[idx, 1],
      se = coefs[idx, 2],
      p_value = coefs[idx, 4],
      stringsAsFactors = FALSE
    ))
  }
}

cat(sprintf("Leave-one-out: min coef = %.3f, max coef = %.3f\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("All significant at 5%%? %s\n",
            ifelse(all(loo_results$p_value < 0.05), "YES", "NO")))
cat("Most influential states (largest change from baseline 2.381):\n")
loo_results <- loo_results %>%
  mutate(delta = abs(coef - 2.381)) %>%
  arrange(desc(delta))
print(head(loo_results, 5))

# =============================================================================
# R3: Randomization inference — permute IES status across states
# =============================================================================

cat("\n--- R3: Randomization inference ---\n")

set.seed(42)
n_perm <- 1000
true_coef <- coeftable(m1a)["recert_intensity:ies_status", 1]
perm_coefs <- numeric(n_perm)

for (i in seq_len(n_perm)) {
  # Randomly reassign IES status to states (preserving count)
  state_ies <- df_main %>%
    distinct(state_abbr, ies_status)
  state_ies$ies_perm <- sample(state_ies$ies_status)

  df_perm <- df_main %>%
    select(-ies_status) %>%
    left_join(state_ies %>% select(state_abbr, ies_perm), by = "state_abbr") %>%
    rename(ies_status = ies_perm)

  m_perm <- tryCatch(
    feols(abs_pct_change ~ recert_intensity * ies_status |
            state_abbr + ym_factor,
          data = df_perm,
          cluster = ~state_abbr,
          warn = FALSE),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    ct <- coeftable(m_perm)
    idx <- grep("recert_intensity:ies_status", rownames(ct))
    if (length(idx) > 0) perm_coefs[i] <- ct[idx, 1]
  }
}

ri_p <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("True coefficient: %.3f\n", true_coef))
cat(sprintf("RI p-value (1000 permutations): %.4f\n", ri_p))
cat(sprintf("Permuted coef distribution: mean=%.3f, sd=%.3f, [%.3f, %.3f]\n",
            mean(perm_coefs), sd(perm_coefs), min(perm_coefs), max(perm_coefs)))

# =============================================================================
# R4: Alternative outcome — log enrollment level changes
# =============================================================================

cat("\n--- R4: Log enrollment changes ---\n")

df_log <- df_main %>%
  mutate(
    log_enroll = log(medicaid_enrollment),
    delta_log = log_enroll - lag(log_enroll)
  ) %>%
  filter(!is.na(delta_log))

r4 <- feols(abs(delta_log) ~ recert_intensity * ies_status |
              state_abbr + ym_factor,
            data = df_log,
            cluster = ~state_abbr)

cat("Log enrollment changes:\n")
print(summary(r4))

# =============================================================================
# R5: Pre-COVID only (Jan 2018 – Feb 2020)
# =============================================================================

cat("\n--- R5: Pre-COVID only ---\n")

df_precovid <- df_main %>%
  filter(year < 2020 | (year == 2020 & month <= 2))

r5 <- feols(abs_pct_change ~ recert_intensity * ies_status |
              state_abbr + ym_factor,
            data = df_precovid,
            cluster = ~state_abbr)

cat("Pre-COVID only:\n")
print(summary(r5))

# =============================================================================
# R6: Heterogeneity — Expansion vs Non-Expansion (split sample)
# =============================================================================

cat("\n--- R6: Expansion status heterogeneity ---\n")

df_main <- df_main %>%
  mutate(expanded = ifelse(expanded_medicaid == "Y", 1, 0))

# Check group sizes
cat("Expansion × IES crosstab:\n")
print(table(df_main %>% distinct(state_abbr, expanded, ies_status) %>% select(expanded, ies_status)))

r6_expanded <- feols(abs_pct_change ~ recert_intensity * ies_status |
                       state_abbr + ym_factor,
                     data = df_main %>% filter(expanded == 1),
                     cluster = ~state_abbr)

cat("\nExpansion states:\n")
print(summary(r6_expanded))

# Non-expansion: might have too few IES states — check first
n_nonexp_ies <- n_distinct(df_main$state_abbr[df_main$expanded == 0 & df_main$ies_status == 1])
cat(sprintf("\nNon-expansion IES states: %d\n", n_nonexp_ies))

if (n_nonexp_ies >= 5) {
  r6_nonexpanded <- feols(abs_pct_change ~ recert_intensity * ies_status |
                            state_abbr + ym_factor,
                          data = df_main %>% filter(expanded == 0),
                          cluster = ~state_abbr)
  cat("Non-expansion states:\n")
  print(summary(r6_nonexpanded))
} else {
  cat("Too few non-expansion IES states for reliable split.\n")
  r6_nonexpanded <- NULL
}

# =============================================================================
# Save robustness objects
# =============================================================================

save(r1_non_ies, r1_ies, loo_results, ri_p, perm_coefs, true_coef,
     r4, r5, r6_expanded, r6_nonexpanded,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nAll robustness checks complete.\n")
