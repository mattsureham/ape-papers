# =============================================================================
# 04_robustness.R — Robustness checks for FTS DDD
# =============================================================================
source("00_packages.R")

panel <- read_csv("../data/panel_main.csv", show_col_types = FALSE)
load("../data/models.RData")

panel <- panel %>%
  mutate(
    state_drug = paste(state_name, drug_type, sep = "_"),
    drug_year = paste(drug_type, year, sep = "_"),
    state_year = paste(state_name, year, sep = "_")
  )

# =============================================================================
# ROBUSTNESS 1: Alternative clustering (state x drug)
# =============================================================================
r1 <- feols(death_rate ~ post_x_high |
              state_drug + drug_year + state_year,
            data = panel,
            cluster = ~ state_drug)

cat("=== R1: State x Drug clustering ===\n")
summary(r1)

# =============================================================================
# ROBUSTNESS 2: Log deaths (intensive margin)
# =============================================================================
panel_log <- panel %>%
  filter(deaths > 0) %>%
  mutate(log_deaths = log(deaths))

r2 <- feols(log_deaths ~ post_x_high |
              state_drug + drug_year + state_year,
            data = panel_log,
            cluster = ~ state_name)

cat("\n=== R2: Log deaths ===\n")
summary(r2)

# =============================================================================
# ROBUSTNESS 3: Leave-one-out by state (check no single state drives result)
# =============================================================================
states <- unique(panel$state_name)
loo_results <- map_dfr(states, function(s) {
  m <- feols(death_rate ~ post_x_high |
               state_drug + drug_year + state_year,
             data = filter(panel, state_name != s),
             cluster = ~ state_name)
  tibble(
    excluded_state = s,
    beta = coef(m)["post_x_high"],
    se = se(m)["post_x_high"]
  )
})

cat("\n=== R3: Leave-one-out ===\n")
cat("Range of DDD betas:", round(range(loo_results$beta), 3), "\n")
cat("Mean:", round(mean(loo_results$beta), 3), "\n")
cat("Most influential exclusion:", loo_results$excluded_state[which.max(abs(loo_results$beta - mean(loo_results$beta)))], "\n")

write_csv(loo_results, "../data/loo_results.csv")

# =============================================================================
# ROBUSTNESS 4: Randomization inference (permute FTS timing)
# =============================================================================
set.seed(42)
n_perms <- 500

# Get the actual DDD coefficient
actual_beta <- coef(m1)["post_x_high"]

# Permute treatment timing across states
treated_states <- unique(panel$state_name[panel$fts_year < 9999])
all_fts_years <- unique(panel$fts_year[panel$fts_year < 9999])

ri_betas <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  perm_panel <- panel
  # Randomly reassign FTS years among treated states
  perm_years <- sample(rep(all_fts_years, length.out = length(treated_states)))
  perm_map <- tibble(state_name = treated_states, perm_fts_year = perm_years)

  perm_panel <- perm_panel %>%
    left_join(perm_map, by = "state_name") %>%
    mutate(
      perm_fts_year = ifelse(is.na(perm_fts_year), 9999L, perm_fts_year),
      post_fts_perm = as.integer(year >= perm_fts_year),
      post_x_high_perm = post_fts_perm * high_contam
    )

  m_perm <- tryCatch(
    feols(death_rate ~ post_x_high_perm |
            state_drug + drug_year + state_year,
          data = perm_panel,
          cluster = ~ state_name),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    ri_betas[i] <- coef(m_perm)["post_x_high_perm"]
  } else {
    ri_betas[i] <- NA_real_
  }
  if (i %% 100 == 0) cat("  RI permutation", i, "of", n_perms, "\n")
}

ri_betas <- ri_betas[!is.na(ri_betas)]
ri_pvalue <- mean(abs(ri_betas) >= abs(actual_beta))

cat("\n=== R4: Randomization Inference ===\n")
cat("Actual DDD beta:", round(actual_beta, 3), "\n")
cat("RI p-value (two-sided):", round(ri_pvalue, 3), "\n")
cat("RI distribution: mean =", round(mean(ri_betas), 3),
    ", sd =", round(sd(ri_betas), 3), "\n")

# =============================================================================
# ROBUSTNESS 5: Psychostimulants as a third category
# =============================================================================
panel_full <- read_csv("../data/panel_full.csv", show_col_types = FALSE)
panel_psych <- panel_full %>%
  filter(drug_type == "Psychostimulants") %>%
  mutate(
    fts_year = ifelse(is.na(fts_year), 9999L, fts_year),
    post_fts = as.integer(year >= fts_year)
  )

r5 <- feols(death_rate ~ post_fts |
              state_name + year,
            data = panel_psych,
            cluster = ~ state_name)

cat("\n=== R5: Psychostimulant placebo ===\n")
summary(r5)

# Save robustness objects
save(r1, r2, r5, loo_results, ri_betas, ri_pvalue, actual_beta,
     file = "../data/robustness.RData")

message("Robustness checks complete.")
