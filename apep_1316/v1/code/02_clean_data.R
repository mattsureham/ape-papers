# 02_clean_data.R — Construct analysis dataset
# apep_1316: BVA Judge Leniency IV

source("00_packages.R")

DATA_DIR <- "../data"
decisions <- read_csv(file.path(DATA_DIR, "bva_decisions_parsed.csv"),
                      show_col_types = FALSE)

cat(sprintf("Raw parsed decisions: %d\n", nrow(decisions)))

# --- Focus on substantive decisions (grant or deny) ---
# Remands are procedural (send back to RO) — not a final merit decision.
# For the leniency IV, we want the VLJ's propensity to GRANT vs DENY on the merits.
# Include remands in a sensitivity check but exclude from main analysis.
decisions <- decisions |>
  mutate(
    # Binary: did the VLJ grant at least one issue?
    grant = as.integer(outcome == "granted"),
    # Broader: favorable outcome (grant or partial)
    favorable = as.integer(outcome %in% c("granted")),
    # Year indicators
    year = year(decision_date),
    month = month(decision_date),
    year_month = paste0(year, "-", sprintf("%02d", month))
  )

# --- VLJ-level statistics ---
vlj_stats <- decisions |>
  group_by(vlj_name) |>
  summarize(
    n_cases = n(),
    n_grants = sum(grant),
    grant_rate = mean(grant),
    n_denied = sum(outcome == "denied"),
    n_remanded = sum(outcome == "remanded"),
    .groups = "drop"
  ) |>
  arrange(desc(n_cases))

cat(sprintf("\nVLJ summary (before filters):\n"))
cat(sprintf("  Total VLJs: %d\n", nrow(vlj_stats)))
cat(sprintf("  Median cases per VLJ: %.0f\n", median(vlj_stats$n_cases)))
cat(sprintf("  Grant rate range: %.1f%% - %.1f%%\n",
            min(vlj_stats$grant_rate) * 100, max(vlj_stats$grant_rate) * 100))

# --- Filter: Keep VLJs with at least 30 cases (for reliable leniency) ---
min_cases <- 30
active_vljs <- vlj_stats |> filter(n_cases >= min_cases)
cat(sprintf("  VLJs with >= %d cases: %d\n", min_cases, nrow(active_vljs)))

decisions <- decisions |>
  filter(vlj_name %in% active_vljs$vlj_name)

cat(sprintf("Decisions after VLJ filter: %d\n", nrow(decisions)))

# --- Construct leave-one-out leniency ---
# For each case i assigned to VLJ j, leniency = (sum of grants by j excluding i) / (N_j - 1)
decisions <- decisions |>
  group_by(vlj_name) |>
  mutate(
    vlj_total_grants = sum(grant),
    vlj_total_cases = n(),
    leniency_loo = (vlj_total_grants - grant) / (vlj_total_cases - 1)
  ) |>
  ungroup()

# --- Regional Office cleaning ---
# Standardize RO names
decisions <- decisions |>
  mutate(
    ro_clean = str_to_title(regional_office) |>
      str_replace_all("\\s+", " ") |>
      str_trim()
  )

ro_counts <- decisions |> count(ro_clean, sort = TRUE)
cat(sprintf("\nRegional Offices: %d unique\n", nrow(ro_counts)))
cat("Top 10 ROs:\n")
print(head(ro_counts, 10))

# --- Add RO fixed effects (only for ROs with sufficient cases) ---
ro_min <- 20
ro_keep <- ro_counts |> filter(n >= ro_min) |> pull(ro_clean)
decisions <- decisions |>
  mutate(ro_fe = ifelse(ro_clean %in% ro_keep, ro_clean, "Other"))

# --- Issue category cleaning ---
cat("\nIssue category distribution:\n")
print(table(decisions$issue_category))

# --- Save analysis dataset ---
analysis_data <- decisions |>
  select(citation, decision_date, fiscal_year, year, month, year_month,
         vlj_name, outcome, grant, favorable, n_issues, issue_category,
         regional_office, ro_clean, ro_fe,
         leniency_loo, vlj_total_cases, vlj_total_grants)

write_csv(analysis_data, file.path(DATA_DIR, "analysis_data.csv"))
cat(sprintf("\nSaved analysis dataset: %d observations\n", nrow(analysis_data)))

# Also save VLJ stats for tables
write_csv(active_vljs, file.path(DATA_DIR, "vlj_stats.csv"))
