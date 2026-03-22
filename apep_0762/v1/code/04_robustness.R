## =============================================================================
## 04_robustness.R — Robustness checks
## apep_0762
## =============================================================================

source("00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

## ---- R1: Alternative control group (not-yet-treated) ----
cat("\n=== R1: Not-yet-treated control group ===\n")

cs_nyt <- att_gt(
  yname = "log_zhvi",
  tname = "year",
  idname = "zip_id",
  gname = "first_treat",
  data = df,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying"
)

agg_nyt <- aggte(cs_nyt, type = "simple")
cat(sprintf("  Not-yet-treated ATT: %.4f (SE: %.4f)\n",
            agg_nyt$overall.att, agg_nyt$overall.se))

es_nyt <- aggte(cs_nyt, type = "dynamic", min_e = -10, max_e = 10)

## ---- R2: Exclude tourism-heavy communities ----
cat("\n=== R2: Exclude tourism hubs (Sedona, Flagstaff, Tucson) ===\n")

tourism_zips <- df %>%
  filter(community %in% c("Sedona", "Flagstaff", "Tucson")) %>%
  pull(zip_code) %>% unique()

df_no_tourism <- df %>% filter(!zip_code %in% tourism_zips)

if (n_distinct(df_no_tourism$first_treat[df_no_tourism$first_treat > 0]) >= 2) {
  cs_no_tourism <- att_gt(
    yname = "log_zhvi",
    tname = "year",
    idname = "zip_id",
    gname = "first_treat",
    data = df_no_tourism,
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "varying"
  )
  agg_no_tourism <- aggte(cs_no_tourism, type = "simple")
  cat(sprintf("  Excl. tourism ATT: %.4f (SE: %.4f)\n",
              agg_no_tourism$overall.att, agg_no_tourism$overall.se))
} else {
  agg_no_tourism <- list(overall.att = NA, overall.se = NA)
  cat("  Too few cohorts after exclusion — skipping.\n")
}

## ---- R3: Anticipation (allow 1-year anticipation) ----
cat("\n=== R3: 1-year anticipation ===\n")

cs_antic <- att_gt(
  yname = "log_zhvi",
  tname = "year",
  idname = "zip_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  anticipation = 1,
  est_method = "dr",
  base_period = "varying"
)

agg_antic <- aggte(cs_antic, type = "simple")
cat(sprintf("  Anticipation(1) ATT: %.4f (SE: %.4f)\n",
            agg_antic$overall.att, agg_antic$overall.se))

## ---- R4: ZHVI in levels (not logs) ----
cat("\n=== R4: ZHVI in levels ===\n")

cs_levels <- att_gt(
  yname = "zhvi",
  tname = "year",
  idname = "zip_id",
  gname = "first_treat",
  data = df,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying"
)

agg_levels <- aggte(cs_levels, type = "simple")
cat(sprintf("  Levels ATT: $%.0f (SE: $%.0f)\n",
            agg_levels$overall.att, agg_levels$overall.se))

## ---- R5: Randomization inference for few-cluster robustness ----
cat("\n=== R5: Randomization inference (permutation of treatment) ===\n")

twfe <- results$twfe
twfe_est <- coef(twfe)["post"]

## Permute treatment assignment across zip codes 999 times
set.seed(42)
n_perms <- 999
perm_ests <- numeric(n_perms)

zip_ids <- unique(df$zip_code)
treated_ids <- unique(df$zip_code[df$treated == 1])
n_treated <- length(treated_ids)

for (p in 1:n_perms) {
  fake_treated <- sample(zip_ids, n_treated)
  df_perm <- df %>%
    mutate(post_perm = ifelse(zip_code %in% fake_treated & year >= first_treat & first_treat > 0, 1, 0))
  # Use a simplified placebo — reassign post indicator
  df_perm$post_perm <- ifelse(df_perm$zip_code %in% fake_treated, df_perm$post, 0)
  fit_perm <- tryCatch(
    feols(log_zhvi ~ post_perm | zip_id + year, data = df_perm, cluster = ~zip_code),
    error = function(e) NULL
  )
  if (!is.null(fit_perm)) {
    perm_ests[p] <- coef(fit_perm)["post_perm"]
  } else {
    perm_ests[p] <- NA
  }
}

perm_ests <- perm_ests[!is.na(perm_ests)]
ri_p <- mean(abs(perm_ests) >= abs(twfe_est))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_p))
cat(sprintf("  TWFE point estimate: %.4f\n", twfe_est))

boot_result <- list(p_val = ri_p, ci_lower = NA, ci_upper = NA)

## ---- R6: Placebo treatment (shift treatment 5 years early) ----
cat("\n=== R6: Placebo test (5-year early treatment) ===\n")

df_placebo <- df %>%
  mutate(
    first_treat_placebo = ifelse(first_treat > 0, first_treat - 5, 0),
    post_placebo = ifelse(first_treat > 0 & year >= first_treat - 5 & year < first_treat, 1, 0)
  ) %>%
  filter(year < min(first_treat[first_treat > 0]))  # Only pre-treatment period

if (n_distinct(df_placebo$first_treat_placebo[df_placebo$first_treat_placebo > 0]) >= 2 &&
    nrow(df_placebo) > 100) {
  cs_placebo <- tryCatch({
    att_gt(
      yname = "log_zhvi",
      tname = "year",
      idname = "zip_id",
      gname = "first_treat_placebo",
      data = df_placebo,
      control_group = "nevertreated",
      anticipation = 0,
      est_method = "dr",
      base_period = "varying"
    )
  }, error = function(e) {
    cat(sprintf("  Placebo error: %s\n", e$message))
    NULL
  })

  if (!is.null(cs_placebo)) {
    agg_placebo <- aggte(cs_placebo, type = "simple")
    cat(sprintf("  Placebo ATT: %.4f (SE: %.4f)\n",
                agg_placebo$overall.att, agg_placebo$overall.se))
  } else {
    agg_placebo <- list(overall.att = NA, overall.se = NA)
  }
} else {
  agg_placebo <- list(overall.att = NA, overall.se = NA)
  cat("  Insufficient pre-treatment data for placebo.\n")
}

## ---- Save robustness results ----
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  nyt = list(att = agg_nyt$overall.att, se = agg_nyt$overall.se, es = es_nyt),
  no_tourism = list(att = agg_no_tourism$overall.att, se = agg_no_tourism$overall.se),
  anticipation = list(att = agg_antic$overall.att, se = agg_antic$overall.se),
  levels = list(att = agg_levels$overall.att, se = agg_levels$overall.se),
  wcb = if (!is.null(boot_result)) list(
    p_val = boot_result$p_val,
    ci_lower = boot_result$conf_int[1],
    ci_upper = boot_result$conf_int[2]
  ) else NULL,
  placebo = list(att = agg_placebo$overall.att, se = agg_placebo$overall.se)
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("  Saved: robustness_results.rds\n")
cat("  DONE.\n")
