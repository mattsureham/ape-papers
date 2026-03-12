## 03_main_analysis.R — Main regressions
## apep_0603: Local Fiscal Multiplier of Poland's Family 500+

source("00_packages.R")

df <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)

cat(sprintf("Analysis panel: %d powiats × %d years\n",
            n_distinct(df$powiat_id), n_distinct(df$year)))

## ------------------------------------------------------------------
## 1. BASELINE DiD — Treatment intensity × Post
## ------------------------------------------------------------------

## Primary outcomes
outcomes <- c("biz_rate", "unemp_rate", "birth_rate",
              "marriage_rate", "infant_mortality_per1k")
outcome_labels <- c("New Business\nReg. per 10K", "Unemployment\nRate (%)",
                     "Birth Rate\nper 1,000", "Marriage Rate\nper 1,000",
                     "Infant Mortality\nper 1,000")

## Baseline: powiat + year FE, cluster at powiat
models_baseline <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_post | powiat_id + year"))
  models_baseline[[y]] <- feols(fml, data = df, cluster = ~powiat_id)
}

cat("\n=== BASELINE RESULTS ===\n")
for (i in seq_along(outcomes)) {
  cat(sprintf("\n%s:\n", outcome_labels[i]))
  print(summary(models_baseline[[outcomes[i]]]))
}

## ------------------------------------------------------------------
## 2. EVENT STUDY — Pre-trend assessment
## ------------------------------------------------------------------

## Create event-time dummies interacted with intensity
df <- df %>%
  mutate(
    et = factor(event_time, levels = sort(unique(event_time)))
  )

es_models <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ i(et, intensity, ref = -1) | powiat_id + year"))
  es_models[[y]] <- feols(fml, data = df, cluster = ~powiat_id)
}

cat("\n=== EVENT STUDY RESULTS ===\n")
for (i in seq_along(outcomes)) {
  cat(sprintf("\n%s:\n", outcome_labels[i]))
  s <- summary(es_models[[outcomes[i]]])
  print(coeftable(s))
}

## ------------------------------------------------------------------
## 3. TWO-SHOCK SPECIFICATION
## ------------------------------------------------------------------
## Separate Phase I (2016) and Phase II (2019) effects

models_twoshock <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_post + treat_post2 | powiat_id + year"))
  models_twoshock[[y]] <- feols(fml, data = df, cluster = ~powiat_id)
}

cat("\n=== TWO-SHOCK RESULTS ===\n")
for (i in seq_along(outcomes)) {
  cat(sprintf("\n%s:\n", outcome_labels[i]))
  print(summary(models_twoshock[[outcomes[i]]]))
}

## ------------------------------------------------------------------
## 4. VOIVODESHIP × YEAR FE (absorb regional trends)
## ------------------------------------------------------------------

models_voi <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ treat_post | powiat_id + voivodeship^year"))
  models_voi[[y]] <- feols(fml, data = df, cluster = ~powiat_id)
}

cat("\n=== VOIVODESHIP × YEAR FE ===\n")
for (i in seq_along(outcomes)) {
  cat(sprintf("\n%s:\n", outcome_labels[i]))
  print(summary(models_voi[[outcomes[i]]]))
}

## ------------------------------------------------------------------
## 5. SAVE RESULTS FOR TABLES
## ------------------------------------------------------------------

# Extract coefficients for main table
results_table <- tibble(
  outcome = outcome_labels,
  outcome_var = outcomes
)

for (spec in c("baseline", "voi")) {
  mlist <- if (spec == "baseline") models_baseline else models_voi
  for (i in seq_along(outcomes)) {
    y <- outcomes[i]
    ct <- coeftable(mlist[[y]])
    results_table[[paste0("beta_", spec)]][i] <- ct["treat_post", "Estimate"]
    results_table[[paste0("se_", spec)]][i] <- ct["treat_post", "Std. Error"]
    results_table[[paste0("pval_", spec)]][i] <- ct["treat_post", "Pr(>|t|)"]
  }
}

write_csv(results_table, "../data/main_results.csv")

## ------------------------------------------------------------------
## 6. WRITE DIAGNOSTICS
## ------------------------------------------------------------------

# Get sample size info
n_treated <- nrow(df %>% filter(post2016 == 1) %>% distinct(powiat_id))
n_pre <- length(unique(df$year[df$year < 2016]))
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_powiats = n_distinct(df$powiat_id),
  n_years = n_distinct(df$year),
  treatment_var = "birth_rate_2015 (or household composition)",
  outcomes = outcomes,
  main_coef_biz = coeftable(models_baseline[["biz_rate"]])["treat_post", "Estimate"],
  main_se_biz = coeftable(models_baseline[["biz_rate"]])["treat_post", "Std. Error"],
  main_coef_unemp = coeftable(models_baseline[["unemp_rate"]])["treat_post", "Estimate"],
  main_se_unemp = coeftable(models_baseline[["unemp_rate"]])["treat_post", "Std. Error"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

## ------------------------------------------------------------------
## 7. SAVE MODELS FOR ROBUSTNESS SCRIPT
## ------------------------------------------------------------------
save(models_baseline, models_voi, models_twoshock, es_models,
     df, outcomes, outcome_labels,
     file = "../data/main_models.RData")
cat("Models saved to data/main_models.RData\n")
