# =============================================================================
# 03_main_analysis.R — DDD regressions: E-Verify × Hispanic × Construction
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
everify_states <- readRDS("../data/everify_states.rds")

cat("Analysis panel:", nrow(panel), "rows,", n_distinct(panel$county_fips), "counties\n")

# =============================================================================
# TABLE 1: DDD Results — Main Flow Decomposition
# =============================================================================

# DDD specification:
# Y_{c,e,i,t} = β (Hispanic × Construction × Post) + county×quarter FE
#                + ethnicity×industry×quarter FE + ε
# Cluster SE at state level

outcomes <- c("hire_rate_w", "sep_rate_w", "recall_rate_w", "stability_rate_w", "earn_new_hire")
outcome_labels <- c("New Hire Rate", "Separation Rate", "Recall Rate",
                     "Stability Rate", "New Hire Earnings ($)")

# Only use treated + never-treated states (drop states with partial mandates)
analysis_df <- panel |>
  mutate(
    hisp = as.integer(is_hispanic),
    constr = as.integer(is_construction),
    post = as.integer(post_mandate),
    # Unique cell identifiers for FEs
    county_yq = interaction(county_fips, yq, drop = TRUE),
    eth_ind_yq = interaction(is_hispanic, is_construction, yq, drop = TRUE)
  )

cat("\n--- Running DDD regressions ---\n")

ddd_models <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  cat("  Estimating:", outcome_labels[i], "...\n")

  fml <- as.formula(paste0(
    y, " ~ hisp_x_constr_x_post + hisp_x_post + constr_x_post",
    " | county_fips^yq + is_hispanic^is_construction^yq"
  ))

  ddd_models[[i]] <- feols(
    fml,
    data = analysis_df,
    cluster = ~state_id
  )
}
names(ddd_models) <- outcome_labels

cat("\n--- DDD Results (β on Hispanic × Construction × Post) ---\n")
for (i in seq_along(ddd_models)) {
  coef_val <- coef(ddd_models[[i]])["hisp_x_constr_x_post"]
  se_val <- se(ddd_models[[i]])["hisp_x_constr_x_post"]
  pval <- pvalue(ddd_models[[i]])["hisp_x_constr_x_post"]
  cat(sprintf("  %-25s: β = %8.4f (SE = %6.4f, p = %5.3f)\n",
              outcome_labels[i], coef_val, se_val, pval))
}

# =============================================================================
# TABLE 2: Event Study — Dynamic DDD
# =============================================================================

cat("\n--- Running Event Study (DDD) ---\n")

# Create relative time for treated states, centered on mandate date
# For DDD event study, we use treated-state counties only
# and compare Hispanic-construction to other groups over relative time

es_df <- analysis_df |>
  filter(treated_state) |>
  mutate(
    rel_q = rel_quarter,
    # Bin endpoints
    rel_q_binned = case_when(
      rel_q <= -8 ~ -8L,
      rel_q >= 12 ~ 12L,
      TRUE ~ rel_q
    )
  ) |>
  filter(!is.na(rel_q_binned))

# Reference period: rel_q = -1
es_df <- es_df |>
  mutate(rel_q_factor = relevel(factor(rel_q_binned), ref = as.character(-1L)))

# Event study: hire rate
cat("  Event study: hire rate...\n")
es_hire <- feols(
  hire_rate_w ~ i(rel_q_binned, hisp_x_constr, ref = -1) |
    county_fips^yq + is_hispanic^is_construction^yq,
  data = es_df,
  cluster = ~state_id
)

# Event study: separation rate
cat("  Event study: separation rate...\n")
es_sep <- feols(
  sep_rate_w ~ i(rel_q_binned, hisp_x_constr, ref = -1) |
    county_fips^yq + is_hispanic^is_construction^yq,
  data = es_df,
  cluster = ~state_id
)

# Event study: stability rate
cat("  Event study: stability rate...\n")
es_stab <- feols(
  stability_rate_w ~ i(rel_q_binned, hisp_x_constr, ref = -1) |
    county_fips^yq + is_hispanic^is_construction^yq,
  data = es_df,
  cluster = ~state_id
)

# Save event study data for plotting
es_results <- bind_rows(
  iplot(es_hire, only.params = TRUE) |>
    as_tibble() |>
    mutate(outcome = "New Hire Rate"),
  iplot(es_sep, only.params = TRUE) |>
    as_tibble() |>
    mutate(outcome = "Separation Rate"),
  iplot(es_stab, only.params = TRUE) |>
    as_tibble() |>
    mutate(outcome = "Stability Rate")
)

saveRDS(es_results, "../data/event_study_results.rds")
cat("Event study results saved.\n")

# =============================================================================
# TABLE 3: Simple DD — Hispanic construction in treated vs control states
# =============================================================================

cat("\n--- Running Simple DD (Hispanic construction only) ---\n")

hisp_constr_df <- analysis_df |>
  filter(is_hispanic & is_construction)

dd_models <- list()
for (i in seq_along(outcomes[1:4])) {
  y <- outcomes[i]
  dd_models[[i]] <- feols(
    as.formula(paste0(y, " ~ post_mandate | county_fips + yq")),
    data = hisp_constr_df,
    cluster = ~state_id
  )
}
names(dd_models) <- outcome_labels[1:4]

cat("  Simple DD results (Hispanic construction):\n")
for (i in seq_along(dd_models)) {
  coef_val <- coef(dd_models[[i]])["post_mandateTRUE"]
  se_val <- se(dd_models[[i]])["post_mandateTRUE"]
  cat(sprintf("  %-25s: β = %8.4f (SE = %6.4f)\n",
              outcome_labels[i], coef_val, se_val))
}

# =============================================================================
# DIAGNOSTICS
# =============================================================================

n_treated_counties <- n_distinct(panel$county_fips[panel$treated_state])
n_pre <- panel |>
  filter(treated_state & is_construction & is_hispanic & !post_mandate) |>
  distinct(year, quarter) |>
  nrow()

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = nrow(analysis_df),
  n_counties = n_distinct(analysis_df$county_fips),
  n_states_treated = n_distinct(everify_states$state_fips),
  n_states_control = n_distinct(analysis_df$state_fips[!analysis_df$treated_state]),
  treatment_waves = sort(unique(everify_states$mandate_year)),
  ddd_coefs = sapply(ddd_models, function(m) coef(m)["hisp_x_constr_x_post"]),
  ddd_se = sapply(ddd_models, function(m) se(m)["hisp_x_constr_x_post"]),
  ddd_pval = sapply(ddd_models, function(m) pvalue(m)["hisp_x_constr_x_post"])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

# Save all models
saveRDS(ddd_models, "../data/ddd_models.rds")
saveRDS(dd_models, "../data/dd_models.rds")
saveRDS(list(hire = es_hire, sep = es_sep, stability = es_stab), "../data/es_models.rds")

cat("All models saved.\n")
cat("Done.\n")
