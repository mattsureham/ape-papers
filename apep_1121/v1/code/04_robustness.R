## 04_robustness.R — Robustness checks
## Paper: apep_1121 — Swiss cantonal debt brakes and spending composition

source("00_packages.R")

cat("=== Robustness checks ===\n")

analysis_df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)

# Main sample: exclude pre-1990 adopters
analysis_main <- analysis_df %>%
  filter(first_treat_cs == 0 | first_treat_cs >= 1990)

func_names_map <- c("2"="Education", "4"="Health", "5"="Social",
                     "6"="Transport", "0"="Administration", "1"="Security",
                     "8"="Economy", "3"="Culture")

# ---------------------------------------------------------------
# 1. WILD CLUSTER BOOTSTRAP (24 clusters → conservative inference)
# ---------------------------------------------------------------

cat("\n=== Wild cluster bootstrap (WCR) ===\n")

# Focus on the two largest functions (education, social) and two
# with the largest point estimates (administration, transport)
key_functions <- c("2", "5", "0", "6")

wcb_results <- list()

for (fc in key_functions) {
  cat(sprintf("\n--- %s ---\n", func_names_map[fc]))
  df_func <- analysis_main %>% filter(func_code == fc)

  twfe_fit <- feols(share ~ treat_post | canton_id + year,
                    data = df_func, cluster = ~canton_id)

  # Wild cluster bootstrap
  boot_result <- tryCatch({
    boottest(
      twfe_fit,
      param = "treat_post",
      B = 9999,
      clustid = "canton_id",
      type = "mammen"
    )
  }, error = function(e) {
    cat("  WCB failed:", e$message, "\n")
    NULL
  })

  if (!is.null(boot_result)) {
    cat(sprintf("  TWFE coef: %.3f, Cluster SE: %.3f\n",
                coef(twfe_fit)["treat_post"],
                sqrt(vcov(twfe_fit)["treat_post", "treat_post"])))
    cat(sprintf("  WCB p-value: %.3f\n", boot_result$p_val))
    cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n",
                boot_result$conf_int[1], boot_result$conf_int[2]))
    wcb_results[[fc]] <- boot_result
  }
}

# ---------------------------------------------------------------
# 2. INCLUDING PRE-1990 ADOPTERS AS ALWAYS-TREATED
# ---------------------------------------------------------------

cat("\n\n=== Sensitivity: Including pre-1990 adopters ===\n")

# Full sample with SG and FR
analysis_full <- analysis_df

# For TWFE: pre-1990 adopters are always treated (treat_post = 1 always)
for (fc in key_functions) {
  df_func <- analysis_full %>% filter(func_code == fc)

  twfe_full <- feols(share ~ treat_post | canton_id + year,
                     data = df_func, cluster = ~canton_id)

  cat(sprintf("  %s: coef=%.3f, se=%.3f, p=%.3f\n",
              func_names_map[fc],
              coef(twfe_full)["treat_post"],
              sqrt(vcov(twfe_full)["treat_post", "treat_post"]),
              pvalue(twfe_full)["treat_post"]))
}

# ---------------------------------------------------------------
# 3. HARD VS SOFT RULES (TRIPLE-DIFFERENCE)
# ---------------------------------------------------------------

cat("\n=== Triple-difference: Hard vs Soft rules ===\n")

analysis_main <- analysis_main %>%
  mutate(
    hard_rule = as.integer(rule_type == "hard"),
    hard_treat_post = hard_rule * treat_post
  )

for (fc in key_functions) {
  df_func <- analysis_main %>% filter(func_code == fc)

  triple_fit <- feols(share ~ treat_post + hard_treat_post | canton_id + year,
                      data = df_func, cluster = ~canton_id)

  cat(sprintf("  %s: Soft ATT=%.3f (p=%.3f), Hard additional=%.3f (p=%.3f)\n",
              func_names_map[fc],
              coef(triple_fit)["treat_post"],
              pvalue(triple_fit)["treat_post"],
              coef(triple_fit)["hard_treat_post"],
              pvalue(triple_fit)["hard_treat_post"]))
}

# ---------------------------------------------------------------
# 4. LEVEL EFFECTS (per-capita expenditure, not shares)
# ---------------------------------------------------------------

cat("\n=== Level effects: log per-capita expenditure ===\n")

# We don't have population data directly, but we can test levels
for (fc in key_functions) {
  df_func <- analysis_main %>%
    filter(func_code == fc, expenditure > 0)

  level_fit <- feols(log(expenditure) ~ treat_post | canton_id + year,
                     data = df_func, cluster = ~canton_id)

  cat(sprintf("  %s: coef=%.3f, se=%.3f, p=%.3f\n",
              func_names_map[fc],
              coef(level_fit)["treat_post"],
              sqrt(vcov(level_fit)["treat_post", "treat_post"]),
              pvalue(level_fit)["treat_post"]))
}

# Total expenditure level
df_total <- analysis_main %>%
  filter(func_code == "2") %>%  # Just need one row per canton-year
  mutate(log_total = log(total_expenditure))

total_fit <- feols(log_total ~ treat_post | canton_id + year,
                   data = df_total, cluster = ~canton_id)

cat(sprintf("  TOTAL: coef=%.3f, se=%.3f, p=%.3f\n",
            coef(total_fit)["treat_post"],
            sqrt(vcov(total_fit)["treat_post", "treat_post"]),
            pvalue(total_fit)["treat_post"]))

# ---------------------------------------------------------------
# 5. PLACEBO: PRE-TREATMENT TRENDS (lead coefficients)
# ---------------------------------------------------------------

cat("\n=== Pre-treatment trends (leads in TWFE) ===\n")

for (fc in c("2", "6")) {  # Education and Transport (main outcomes)
  df_func <- analysis_main %>%
    filter(func_code == fc) %>%
    mutate(
      event_time = ifelse(first_treat_cs > 0, year - first_treat_cs, NA),
      # Bin event time
      et_bin = case_when(
        is.na(event_time) ~ NA_character_,
        event_time <= -5 ~ "pre5plus",
        event_time == -4 ~ "pre4",
        event_time == -3 ~ "pre3",
        event_time == -2 ~ "pre2",
        event_time == -1 ~ "pre1",
        event_time == 0 ~ "post0",
        event_time == 1 ~ "post1",
        event_time == 2 ~ "post2",
        event_time >= 3 & event_time <= 5 ~ "post3to5",
        event_time >= 6 ~ "post6plus"
      )
    ) %>%
    mutate(et_bin = factor(et_bin, levels = c("pre5plus", "pre4", "pre3", "pre2",
                                               "pre1", "post0", "post1", "post2",
                                               "post3to5", "post6plus")))

  # Drop never-treated from event study (they don't have event time)
  df_es <- df_func %>% filter(!is.na(et_bin))

  es_fit <- feols(share ~ et_bin | canton_id + year,
                  data = df_es, cluster = ~canton_id,
                  ref = "pre1")

  cat(sprintf("\n  %s event study coefficients:\n", func_names_map[fc]))
  print(coeftable(es_fit)[, 1:4])
}

# ---------------------------------------------------------------
# 6. HERFINDAHL INDEX OF SPENDING CONCENTRATION
# ---------------------------------------------------------------

cat("\n=== Herfindahl index of spending concentration ===\n")

hhi_df <- analysis_main %>%
  filter(func_code != "total") %>%
  group_by(canton, year, canton_id, first_treat_cs, treat_post) %>%
  summarise(
    hhi = sum((share/100)^2, na.rm = TRUE),
    .groups = "drop"
  )

hhi_fit <- feols(hhi ~ treat_post | canton_id + year,
                 data = hhi_df, cluster = ~canton_id)

cat(sprintf("  HHI: coef=%.5f, se=%.5f, p=%.3f\n",
            coef(hhi_fit)["treat_post"],
            sqrt(vcov(hhi_fit)["treat_post", "treat_post"]),
            pvalue(hhi_fit)["treat_post"]))
cat(sprintf("  Mean HHI: %.4f, SD: %.4f\n",
            mean(hhi_df$hhi), sd(hhi_df$hhi)))

# ---------------------------------------------------------------
# 7. SAVE ROBUSTNESS RESULTS
# ---------------------------------------------------------------

saveRDS(wcb_results, "../data/wcb_results.rds")

cat("\n=== Robustness checks complete ===\n")
