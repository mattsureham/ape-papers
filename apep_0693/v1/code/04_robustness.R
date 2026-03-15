## 04_robustness.R — Robustness checks
## apep_0693: The Price of Privacy

source("00_packages.R")

df <- readRDS("../data/bfs_quarterly_clean.rds")
results <- readRDS("../data/main_results.rds")

# ------------------------------------------------------------------
# 1. Exclude California (COVID overlap with CCPA Jan 2020)
# ------------------------------------------------------------------
cat("\n=== Robustness: Exclude California ===\n")

df_no_ca <- df %>% filter(state != "CA")

# Recalculate state IDs for the subset
state_ids_noca <- df_no_ca %>%
  distinct(state) %>%
  arrange(state) %>%
  mutate(state_id_noca = row_number())

df_no_ca <- df_no_ca %>%
  left_join(state_ids_noca, by = "state")

cs_no_ca <- att_gt(
  yname = "log_ba",
  tname = "yq",
  idname = "state_id_noca",
  gname = "first_treat_q",
  data = df_no_ca,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_no_ca <- aggte(cs_no_ca, type = "simple")
cat("Exclude CA ATT:\n"); print(summary(agg_no_ca))

# ------------------------------------------------------------------
# 2. Donut-hole: Exclude COVID shock (2020Q1-Q2)
# ------------------------------------------------------------------
cat("\n=== Robustness: Donut-Hole (Exclude 2020Q1-Q2) ===\n")

df_donut <- df %>%
  filter(!(year == 2020 & quarter %in% c(1, 2)))

# Recalculate state IDs
state_ids_donut <- df_donut %>%
  distinct(state) %>%
  arrange(state) %>%
  mutate(state_id_donut = row_number())

df_donut <- df_donut %>%
  left_join(state_ids_donut, by = "state")

cs_donut <- att_gt(
  yname = "log_ba",
  tname = "yq",
  idname = "state_id_donut",
  gname = "first_treat_q",
  data = df_donut,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_donut <- aggte(cs_donut, type = "simple")
cat("Donut ATT:\n"); print(summary(agg_donut))

# ------------------------------------------------------------------
# 3. Leave-one-out: Drop each treated state
# ------------------------------------------------------------------
cat("\n=== Robustness: Leave-One-Out ===\n")

treated_states <- df %>%
  filter(first_treat_q > 0) %>%
  distinct(state) %>%
  pull(state)

loo_results <- tibble(
  dropped_state = character(),
  att = numeric(),
  se = numeric()
)

for (s in treated_states) {
  df_loo <- df %>% filter(state != s)

  # Recalculate IDs
  sid_loo <- df_loo %>%
    distinct(state) %>%
    arrange(state) %>%
    mutate(sid = row_number())
  df_loo <- df_loo %>% left_join(sid_loo, by = "state")

  cs_loo <- tryCatch({
    att_gt(
      yname = "log_ba",
      tname = "yq",
      idname = "sid",
      gname = "first_treat_q",
      data = df_loo,
      control_group = "nevertreated",
      base_period = "universal"
    )
  }, error = function(e) {
    cat(sprintf("  LOO failed for %s: %s\n", s, e$message))
    return(NULL)
  })

  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results <- bind_rows(loo_results, tibble(
      dropped_state = s,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    ))
    cat(sprintf("  Drop %s: ATT=%.4f (SE=%.4f)\n", s, agg_loo$overall.att, agg_loo$overall.se))
  }
}

# ------------------------------------------------------------------
# 4. Sun-Abraham estimator (alternative heterogeneity-robust)
# ------------------------------------------------------------------
cat("\n=== Robustness: Sun-Abraham (fixest) ===\n")

df_sa <- df %>%
  mutate(
    first_treat_sa = ifelse(first_treat_q == 0, 10000L, first_treat_q)
  )

sa_ba <- feols(log_ba ~ sunab(first_treat_sa, yq) | state_id + yq,
               data = df_sa, cluster = ~state_id)
cat("Sun-Abraham log(BA):\n")
print(summary(sa_ba))

# ------------------------------------------------------------------
# 5. Not-yet-treated as control group (alternative)
# ------------------------------------------------------------------
cat("\n=== Robustness: Not-Yet-Treated Controls ===\n")

cs_nyt <- att_gt(
  yname = "log_ba",
  tname = "yq",
  idname = "state_id",
  gname = "first_treat_q",
  data = df,
  control_group = "notyettreated",
  base_period = "universal"
)
agg_nyt <- aggte(cs_nyt, type = "simple")
cat("Not-yet-treated ATT:\n"); print(summary(agg_nyt))

# ------------------------------------------------------------------
# 6. Wild cluster bootstrap (for inference with ~50 clusters)
# ------------------------------------------------------------------
cat("\n=== Robustness: Wild Cluster Bootstrap ===\n")

twfe_for_boot <- feols(log_ba ~ treated | state_id + yq, data = df, cluster = ~state_id)

boot_pval <- tryCatch({
  boot_res <- boottest(
    twfe_for_boot,
    param = "treated",
    B = 999,
    clustid = "state_id",
    type = "webb"
  )
  cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_res$p_val))
  cat(sprintf("Wild bootstrap CI: [%.4f, %.4f]\n", boot_res$conf_int[1], boot_res$conf_int[2]))
  boot_res$p_val
}, error = function(e) {
  cat(sprintf("Bootstrap failed: %s\n", e$message))
  NA_real_
})

# ------------------------------------------------------------------
# 7. Save robustness results
# ------------------------------------------------------------------
robust <- list(
  no_ca = agg_no_ca,
  donut = agg_donut,
  loo = loo_results,
  sa_ba = sa_ba,
  nyt = agg_nyt,
  boot_pval = boot_pval
)
saveRDS(robust, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
