# 04_robustness.R — Robustness checks for the wietexperiment
# apep_0827: Dutch cannabis supply chain experiment and crime

source("00_packages.R")

df_exp <- readRDS("../data/df_exp.rds")
df_all <- readRDS("../data/df_all.rds")
results <- readRDS("../data/main_results.rds")

df_exp <- df_exp %>%
  mutate(rel_year = year - 2024)

# ============================================================================
# 1. Shorter pre-period (2016-2025) to address early pre-trend divergence
# ============================================================================

cat("=== Robustness 1: Shorter pre-period (2016-2025) ===\n")

df_short <- df_exp %>% filter(year >= 2016)

r1_drug <- feols(DrugTotal_rate ~ treated:post | RegioS + year,
                 data = df_short, vcov = ~RegioS)
r1_soft <- feols(DrugSoft_rate ~ treated:post | RegioS + year,
                 data = df_short, vcov = ~RegioS)
r1_hard <- feols(DrugHard_rate ~ treated:post | RegioS + year,
                 data = df_short, vcov = ~RegioS)
r1_viol <- feols(Violence_rate ~ treated:post | RegioS + year,
                 data = df_short, vcov = ~RegioS)
r1_total <- feols(TotalCrime_rate ~ treated:post | RegioS + year,
                  data = df_short, vcov = ~RegioS)

cat("Drug crime (short pre):", round(coef(r1_drug), 2), "SE:", round(se(r1_drug), 2), "\n")
cat("Soft drug (short pre):", round(coef(r1_soft), 2), "SE:", round(se(r1_soft), 2), "\n")
cat("Hard drug (short pre):", round(coef(r1_hard), 2), "SE:", round(se(r1_hard), 2), "\n")
cat("Violence (short pre):", round(coef(r1_viol), 2), "SE:", round(se(r1_viol), 2), "\n")
cat("Total crime (short pre):", round(coef(r1_total), 2), "SE:", round(se(r1_total), 2), "\n")

# Event study with shorter pre-period
es_short <- feols(DrugTotal_rate ~ i(rel_year, treated, ref = -1) | RegioS + year,
                  data = df_short, vcov = ~RegioS)
cat("\nEvent study (short pre-period):\n")
summary(es_short)

# Pre-trend test for shorter pre-period
pre_test_short <- wald(es_short, "rel_year.*-")
cat("Pre-trend F-test (2016-2023):", round(pre_test_short$stat, 3),
    "p =", round(pre_test_short$p, 4), "\n")

# ============================================================================
# 2. Municipality-specific linear trends
# ============================================================================

cat("\n=== Robustness 2: Municipality-specific trends ===\n")

df_exp <- df_exp %>%
  mutate(mun_trend = as.numeric(year) * as.numeric(factor(RegioS)))

r2_drug <- feols(DrugTotal_rate ~ treated:post | RegioS + year + RegioS[year],
                 data = df_exp, vcov = ~RegioS)
cat("Drug crime (mun trends):", round(coef(r2_drug), 2), "SE:", round(se(r2_drug), 2), "\n")

r2_hard <- feols(DrugHard_rate ~ treated:post | RegioS + year + RegioS[year],
                 data = df_exp, vcov = ~RegioS)
cat("Hard drug (mun trends):", round(coef(r2_hard), 2), "SE:", round(se(r2_hard), 2), "\n")

# ============================================================================
# 3. Permutation inference (reassign treatment among 20 municipalities)
# ============================================================================

cat("\n=== Robustness 3: Permutation Inference ===\n")

set.seed(20260323)
n_perms <- 1000

# Observed DiD estimate
obs_beta <- coef(results$m1_drug)[1]

# Generate permutation distribution
perm_betas <- numeric(n_perms)
mun_ids <- unique(df_exp$RegioS)
n_treat <- 10

for (i in 1:n_perms) {
  # Randomly assign 10 of 20 municipalities as "treated"
  perm_treat <- sample(mun_ids, n_treat)
  df_perm <- df_exp %>%
    mutate(
      perm_treated = if_else(RegioS %in% perm_treat, 1L, 0L),
      perm_tp = perm_treated * post
    )

  m_perm <- tryCatch({
    feols(DrugTotal_rate ~ perm_tp | RegioS + year,
          data = df_perm, vcov = ~RegioS)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    perm_betas[i] <- coef(m_perm)[1]
  } else {
    perm_betas[i] <- NA
  }
}

perm_betas <- perm_betas[!is.na(perm_betas)]
perm_pvalue <- mean(abs(perm_betas) >= abs(obs_beta))
cat(sprintf("Observed beta: %.2f\n", obs_beta))
cat(sprintf("Permutation p-value (two-sided): %.4f (from %d permutations)\n",
            perm_pvalue, length(perm_betas)))
cat(sprintf("Permutation distribution: mean=%.2f, sd=%.2f, 5th=%.2f, 95th=%.2f\n",
            mean(perm_betas), sd(perm_betas),
            quantile(perm_betas, 0.05), quantile(perm_betas, 0.95)))

# ============================================================================
# 4. SCM for aggregate treatment unit
# ============================================================================

cat("\n=== Robustness 4: Synthetic Control (Aggregate) ===\n")

# Aggregate treatment municipalities to one unit
df_scm_treat <- df_all %>%
  filter(!is.na(treated), treated == 1) %>%
  group_by(year) %>%
  summarise(
    DrugTotal_rate = weighted.mean(DrugTotal_rate, population, na.rm = TRUE),
    population = sum(population, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(RegioS = "TREAT_AGG", mun_id = 999L)

# Donor pool: all non-experiment municipalities with complete data
donor_ids <- df_all %>%
  filter(is.na(treated)) %>%
  group_by(RegioS) %>%
  summarise(n_years = n_distinct(year), .groups = "drop") %>%
  filter(n_years >= 14) %>%  # Need most years
  pull(RegioS)

df_scm_donors <- df_all %>%
  filter(RegioS %in% donor_ids, !is.na(DrugTotal_rate)) %>%
  group_by(RegioS) %>%
  filter(n() >= 14) %>%
  ungroup() %>%
  mutate(mun_id = as.integer(factor(RegioS)))

# Combine
df_scm <- bind_rows(
  df_scm_treat,
  df_scm_donors %>% select(RegioS, year, DrugTotal_rate, population, mun_id)
)

# Assign numeric IDs
id_map <- df_scm %>% distinct(RegioS) %>% mutate(unit_id = row_number())
df_scm <- df_scm %>% left_join(id_map, by = "RegioS")

treat_id <- id_map %>% filter(RegioS == "TREAT_AGG") %>% pull(unit_id)
donor_unit_ids <- id_map %>% filter(RegioS != "TREAT_AGG") %>% pull(unit_id)

# Run SCM
cat(sprintf("SCM: %d donor municipalities, treatment unit ID: %d\n",
            length(donor_unit_ids), treat_id))

# Prepare Synth dataprep
tryCatch({
  dataprep_out <- dataprep(
    foo = as.data.frame(df_scm),
    predictors = "DrugTotal_rate",
    predictors.op = "mean",
    time.predictors.prior = 2010:2023,
    dependent = "DrugTotal_rate",
    unit.variable = "unit_id",
    time.variable = "year",
    treatment.identifier = treat_id,
    controls.identifier = donor_unit_ids[1:min(50, length(donor_unit_ids))],  # Cap at 50 donors
    time.optimize.ssr = 2010:2023,
    time.plot = 2010:2025
  )

  synth_out <- synth(dataprep_out, optimxmethod = "Nelder-Mead")

  # Extract synthetic vs actual
  synth_tables <- synth.tab(dataprep.res = dataprep_out, synth.res = synth_out)

  # Post-treatment gap
  gaps <- dataprep_out$Y1plot - (dataprep_out$Y0plot %*% synth_out$solution.w)
  post_gaps <- gaps[rownames(gaps) %in% as.character(2024:2025), ]

  cat("\nSCM Results:\n")
  cat(sprintf("Pre-treatment MSPE: %.4f\n", synth_out$loss.v[1]))
  cat("Post-treatment gaps (treatment - synthetic):\n")
  print(post_gaps)
  cat(sprintf("Average post-treatment gap: %.2f\n", mean(post_gaps)))

  # Save SCM results
  saveRDS(list(
    dataprep = dataprep_out,
    synth = synth_out,
    gaps = gaps,
    post_gaps = post_gaps
  ), "../data/scm_results.rds")

}, error = function(e) {
  cat("SCM error:", conditionMessage(e), "\n")
  cat("Proceeding without SCM robustness.\n")
})

# ============================================================================
# 5. Placebo outcome: property crime
# ============================================================================

cat("\n=== Robustness 5: Placebo Outcome (Property Crime) ===\n")

if ("Property_rate" %in% names(df_exp)) {
  r5_prop <- feols(Property_rate ~ treated:post | RegioS + year,
                   data = df_exp, vcov = ~RegioS)
  cat("Property crime (placebo):", round(coef(r5_prop), 2),
      "SE:", round(se(r5_prop), 2),
      "p:", round(pvalue(r5_prop), 4), "\n")
} else {
  cat("Property crime not available as separate variable.\n")
}

# ============================================================================
# 6. Excluding COVID years (2020-2021)
# ============================================================================

cat("\n=== Robustness 6: Excluding COVID years ===\n")

df_nocovid <- df_exp %>% filter(!year %in% c(2020, 2021))

r6_drug <- feols(DrugTotal_rate ~ treated:post | RegioS + year,
                 data = df_nocovid, vcov = ~RegioS)
cat("Drug crime (no COVID):", round(coef(r6_drug), 2), "SE:", round(se(r6_drug), 2), "\n")

r6_hard <- feols(DrugHard_rate ~ treated:post | RegioS + year,
                 data = df_nocovid, vcov = ~RegioS)
cat("Hard drug (no COVID):", round(coef(r6_hard), 2), "SE:", round(se(r6_hard), 2), "\n")

# ============================================================================
# Store all robustness results
# ============================================================================

rob_results <- list(
  short_pre = list(drug = r1_drug, soft = r1_soft, hard = r1_hard,
                   viol = r1_viol, total = r1_total),
  mun_trends = list(drug = r2_drug, hard = r2_hard),
  permutation = list(obs_beta = obs_beta, perm_pvalue = perm_pvalue,
                     perm_betas = perm_betas),
  no_covid = list(drug = r6_drug, hard = r6_hard)
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness analysis complete.\n")
