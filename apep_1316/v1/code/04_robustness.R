# 04_robustness.R — Robustness checks for VLJ leniency design
# apep_1316: BVA Judge Leniency IV

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"

df <- read_csv(file.path(DATA_DIR, "analysis_data.csv"), show_col_types = FALSE)
load(file.path(DATA_DIR, "model_objects.RData"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# =============================================================================
# 1. PLACEBO: Leniency should not predict REMAND (procedural, not merit)
# =============================================================================
cat("--- Placebo: Leniency → Remand (should be ~0 or negative) ---\n")
df_all <- read_csv(file.path(DATA_DIR, "bva_decisions_parsed.csv"), show_col_types = FALSE) |>
  mutate(
    decision_date = as.Date(decision_date),
    year = year(decision_date),
    grant = as.integer(outcome == "granted"),
    remand = as.integer(outcome == "remanded")
  )

# Recalculate leniency on the full sample
df_all <- df_all |>
  filter(vlj_name %in% unique(df$vlj_name)) |>
  group_by(vlj_name) |>
  mutate(
    vlj_total_grants = sum(grant, na.rm = TRUE),
    vlj_total_cases = n(),
    leniency_loo = (vlj_total_grants - grant) / (vlj_total_cases - 1)
  ) |>
  ungroup() |>
  mutate(
    ro_clean = str_to_title(regional_office) |> str_replace_all("\\s+", " ") |> str_trim()
  )

# Identify RO FE groups
ro_counts <- df_all |> count(ro_clean, sort = TRUE)
ro_keep <- ro_counts |> filter(n >= 20) |> pull(ro_clean)
df_all <- df_all |> mutate(ro_fe = ifelse(ro_clean %in% ro_keep, ro_clean, "Other"))

placebo_remand <- feols(remand ~ leniency_loo | year + ro_fe,
                        data = df_all, vcov = ~vlj_name)
cat(sprintf("  Leniency → Remand: β=%.3f (SE=%.3f, p=%.3f)\n",
            coef(placebo_remand)["leniency_loo"],
            se(placebo_remand)["leniency_loo"],
            pvalue(placebo_remand)["leniency_loo"]))

# =============================================================================
# 2. ALTERNATIVE LENIENCY MEASURES
# =============================================================================
cat("\n--- Alternative leniency measures ---\n")

# 2a. Leniency excluding same issue category
df <- df |>
  group_by(vlj_name, issue_category) |>
  mutate(
    vlj_issue_grants = sum(grant),
    vlj_issue_cases = n()
  ) |>
  group_by(vlj_name) |>
  mutate(
    leniency_excl_issue = (vlj_total_grants - vlj_issue_grants) /
      (vlj_total_cases - vlj_issue_cases)
  ) |>
  ungroup()

# Replace NaN/Inf with NA
df <- df |> mutate(leniency_excl_issue = ifelse(is.finite(leniency_excl_issue),
                                                 leniency_excl_issue, NA))

alt_1 <- feols(grant ~ leniency_excl_issue | year + ro_fe + issue_category,
               data = df |> filter(!is.na(leniency_excl_issue)),
               vcov = ~vlj_name)
cat(sprintf("  Excluding same issue: β=%.3f (SE=%.3f, F=%.1f)\n",
            coef(alt_1)["leniency_excl_issue"],
            se(alt_1)["leniency_excl_issue"],
            (coef(alt_1)["leniency_excl_issue"] / se(alt_1)["leniency_excl_issue"])^2))

# 2b. Leniency from other year only (cross-year validation)
df <- df |>
  group_by(vlj_name, year) |>
  mutate(
    vlj_year_grants = sum(grant),
    vlj_year_cases = n()
  ) |>
  group_by(vlj_name) |>
  mutate(
    leniency_other_year = (vlj_total_grants - vlj_year_grants) /
      (vlj_total_cases - vlj_year_cases)
  ) |>
  ungroup()

df <- df |> mutate(leniency_other_year = ifelse(is.finite(leniency_other_year),
                                                  leniency_other_year, NA))

alt_2 <- feols(grant ~ leniency_other_year | year + ro_fe + issue_category,
               data = df |> filter(!is.na(leniency_other_year)),
               vcov = ~vlj_name)
cat(sprintf("  Other-year leniency:  β=%.3f (SE=%.3f, F=%.1f)\n",
            coef(alt_2)["leniency_other_year"],
            se(alt_2)["leniency_other_year"],
            (coef(alt_2)["leniency_other_year"] / se(alt_2)["leniency_other_year"])^2))

# =============================================================================
# 3. LEAVE-ONE-OUT BY VLJ: Sensitivity to individual judges
# =============================================================================
cat("\n--- Leave-one-out VLJ sensitivity ---\n")

vljs <- unique(df$vlj_name)
loo_betas <- numeric(length(vljs))
for (i in seq_along(vljs)) {
  sub <- df |> filter(vlj_name != vljs[i])
  # Recalculate LOO leniency
  sub <- sub |>
    group_by(vlj_name) |>
    mutate(
      loo_grants = sum(grant),
      loo_n = n(),
      loo_len = (loo_grants - grant) / (loo_n - 1)
    ) |>
    ungroup()
  m <- feols(grant ~ loo_len | year, data = sub, vcov = ~vlj_name)
  loo_betas[i] <- coef(m)["loo_len"]
}

cat(sprintf("  LOO beta range: [%.3f, %.3f]\n", min(loo_betas), max(loo_betas)))
cat(sprintf("  LOO beta mean:  %.3f\n", mean(loo_betas)))
cat(sprintf("  LOO beta SD:    %.3f\n", sd(loo_betas)))

# =============================================================================
# 4. CLUSTERING ALTERNATIVES
# =============================================================================
cat("\n--- Alternative clustering ---\n")

# Cluster by RO instead of VLJ
alt_cluster_ro <- feols(grant ~ leniency_loo | year + ro_fe + issue_category,
                        data = df, vcov = ~ro_fe)
cat(sprintf("  Cluster by RO:   β=%.3f (SE=%.3f)\n",
            coef(alt_cluster_ro)["leniency_loo"],
            se(alt_cluster_ro)["leniency_loo"]))

# Two-way clustering: VLJ + year-month
df <- df |> mutate(ym = paste0(year, "-", sprintf("%02d", month)))
alt_cluster_2way <- feols(grant ~ leniency_loo | year + ro_fe + issue_category,
                          data = df, vcov = ~vlj_name + ym)
cat(sprintf("  Two-way (VLJ+YM): β=%.3f (SE=%.3f)\n",
            coef(alt_cluster_2way)["leniency_loo"],
            se(alt_cluster_2way)["leniency_loo"]))

# HC1 robust (no clustering)
alt_robust <- feols(grant ~ leniency_loo | year + ro_fe + issue_category,
                    data = df, vcov = "HC1")
cat(sprintf("  HC1 robust:      β=%.3f (SE=%.3f)\n",
            coef(alt_robust)["leniency_loo"],
            se(alt_robust)["leniency_loo"]))

# =============================================================================
# 5. MINIMUM CASELOAD SENSITIVITY
# =============================================================================
cat("\n--- Minimum caseload sensitivity ---\n")
for (min_n in c(20, 50, 75, 100, 150)) {
  vlj_keep <- df |> count(vlj_name) |> filter(n >= min_n) |> pull(vlj_name)
  sub <- df |> filter(vlj_name %in% vlj_keep)
  # Recalculate LOO
  sub <- sub |>
    group_by(vlj_name) |>
    mutate(loo_len = (sum(grant) - grant) / (n() - 1)) |>
    ungroup()
  m <- feols(grant ~ loo_len | year + ro_fe + issue_category,
             data = sub, vcov = ~vlj_name)
  cat(sprintf("  Min %3d cases: β=%.3f (SE=%.3f), N=%d, VLJs=%d\n",
              min_n, coef(m)["loo_len"], se(m)["loo_len"],
              nrow(sub), length(vlj_keep)))
}

# =============================================================================
# SAVE ROBUSTNESS OBJECTS
# =============================================================================
save(placebo_remand, alt_1, alt_2,
     loo_betas, alt_cluster_ro, alt_cluster_2way, alt_robust,
     file = file.path(DATA_DIR, "robustness_objects.RData"))

cat("\nRobustness checks complete.\n")
