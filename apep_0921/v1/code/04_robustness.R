## 04_robustness.R — Robustness checks and additional tests
## apep_0917: Civil Asset Forfeiture Regulatory Leakage

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "agency_panel.rds")) %>%
  filter(state != "NC") %>%
  mutate(agency_id = as.integer(factor(ncic_cd)))

results <- readRDS(file.path(data_dir, "results.rds"))

cat("=== Robustness Checks ===\n")

## ---------- 1. State-level analysis (more power) ----------
cat("\n--- 1. State-level DiD ---\n")
state_df <- readRDS(file.path(data_dir, "state_panel.rds")) %>%
  filter(state != "NC")

# TWFE state-level
twfe_state_log <- feols(log_total_es ~ post_reform | state + fy,
                        data = state_df, cluster = ~state)
cat("State-level TWFE (log total ES):\n")
summary(twfe_state_log)

twfe_state_share <- feols(share_participating ~ post_reform | state + fy,
                          data = state_df, cluster = ~state)
cat("\nState-level TWFE (share participating):\n")
summary(twfe_state_share)

twfe_state_n <- feols(n_agencies ~ post_reform | state + fy,
                      data = state_df, cluster = ~state)
cat("\nState-level TWFE (N agencies filing):\n")
summary(twfe_state_n)

## ---------- 2. Sun-Abraham estimator (fixest) ----------
cat("\n--- 2. Sun-Abraham (fixest) ---\n")

# Create cohort variable for sunab()
df_sunab <- df %>%
  mutate(cohort = ifelse(first_treat == 0, Inf, first_treat))

sa_log <- feols(log_es_funds ~ sunab(cohort, fy) | ncic_cd + fy,
                data = df_sunab, cluster = ~state)
cat("Sun-Abraham (log ES funds):\n")
summary(sa_log)

sa_ext <- feols(has_es ~ sunab(cohort, fy) | ncic_cd + fy,
                data = df_sunab, cluster = ~state)
cat("\nSun-Abraham (participation):\n")
summary(sa_ext)

## ---------- 3. Leave-one-state-out ----------
cat("\n--- 3. Leave-one-state-out ---\n")
states <- unique(df$state)
loo_coefs <- numeric(length(states))
names(loo_coefs) <- states

for (s in states) {
  fit <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
               data = df %>% filter(state != s), cluster = ~state)
  loo_coefs[s] <- coef(fit)["post_reform"]
}

cat("LOO coefficient range:", round(range(loo_coefs), 4), "\n")
cat("LOO mean:", round(mean(loo_coefs), 4), "\n")
cat("Full sample coefficient:", round(coef(results$twfe_log)["post_reform"], 4), "\n")

# Find most influential states
sorted_loo <- sort(loo_coefs)
cat("Most negative (drop state):", names(sorted_loo)[1], "=", round(sorted_loo[1], 4), "\n")
cat("Most positive (drop state):", names(sorted_loo)[length(sorted_loo)], "=",
    round(sorted_loo[length(sorted_loo)], 4), "\n")

## ---------- 4. Placebo: agencies in never-reformed states ----------
cat("\n--- 4. Placebo: random treatment assignment ---\n")
set.seed(42)
# Assign random reform years to never-reformed states
never_states <- unique(df$state[df$first_treat == 0])
actual_reform_years <- unique(df$first_treat[df$first_treat > 0])

df_placebo <- df %>%
  filter(first_treat == 0) %>%
  mutate(
    fake_reform_year = sample(actual_reform_years, n(), replace = TRUE),
    fake_post = ifelse(fy >= fake_reform_year, 1L, 0L)
  )

placebo_fit <- feols(log_es_funds ~ fake_post | ncic_cd + fy,
                     data = df_placebo, cluster = ~state)
cat("Placebo (never-reformed states, random treatment):\n")
summary(placebo_fit)

## ---------- 5. Inverse hyperbolic sine transformation ----------
cat("\n--- 5. IHS transformation ---\n")
df <- df %>%
  mutate(ihs_es_funds = log(es_funds + sqrt(es_funds^2 + 1)))

twfe_ihs <- feols(ihs_es_funds ~ post_reform | ncic_cd + fy,
                  data = df, cluster = ~state)
cat("TWFE (IHS ES funds):\n")
summary(twfe_ihs)

## ---------- 6. Balanced sub-panel ----------
cat("\n--- 6. Balanced sub-panel (agencies in all 16 years) ---\n")
agency_years <- df %>% group_by(ncic_cd) %>% summarize(n = n(), .groups = "drop")
balanced_ids <- agency_years$ncic_cd[agency_years$n == 16]
cat("Agencies in all 16 years:", length(balanced_ids), "\n")

if (length(balanced_ids) > 50) {
  df_balanced <- df %>% filter(ncic_cd %in% balanced_ids)
  twfe_balanced <- feols(log_es_funds ~ post_reform | ncic_cd + fy,
                         data = df_balanced, cluster = ~state)
  cat("Balanced TWFE (log ES funds):\n")
  summary(twfe_balanced)
} else {
  cat("Too few fully balanced agencies for separate estimation.\n")
}

## ---------- 7. Minimum Detectable Effect (MDE) ----------
cat("\n--- 7. Power analysis: MDE ---\n")
pre_sd <- readRDS(file.path(data_dir, "pre_treat_stats.rds"))

# For TWFE with 50 clusters
twfe_se <- sqrt(diag(vcov(results$twfe_log)))["post_reform"]
mde_twfe <- 2.8 * twfe_se  # power ≈ 80% at α = 0.05

# For CS-DiD
cs_se <- results$cs_log_agg$overall.se
mde_cs <- 2.8 * cs_se

cat("TWFE SE:", round(twfe_se, 4), "→ MDE:", round(mde_twfe, 4), "log points\n")
cat("  In %:", round((exp(mde_twfe) - 1) * 100, 1), "%\n")
cat("CS-DiD SE:", round(cs_se, 4), "→ MDE:", round(mde_cs, 4), "log points\n")
cat("  In %:", round((exp(mde_cs) - 1) * 100, 1), "%\n")
cat("Pre-treatment SD(log ES):", round(pre_sd$sd_log_es, 4), "\n")
cat("MDE in SDE terms (TWFE):", round(mde_twfe / pre_sd$sd_log_es, 4), "\n")

## ---------- Save robustness results ----------
rob_results <- list(
  twfe_state_log = twfe_state_log,
  twfe_state_share = twfe_state_share,
  twfe_state_n = twfe_state_n,
  sa_log = sa_log,
  sa_ext = sa_ext,
  loo_coefs = loo_coefs,
  placebo_fit = placebo_fit,
  twfe_ihs = twfe_ihs,
  mde_twfe = mde_twfe,
  mde_cs = mde_cs
)

saveRDS(rob_results, file.path(data_dir, "rob_results.rds"))

cat("\n=== Robustness checks complete ===\n")
