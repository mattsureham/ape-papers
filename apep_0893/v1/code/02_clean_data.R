## 02_clean_data.R — Clean and construct analysis dataset
## Match proposed rules to final rules via RIN; build agency-semester panel.

source("00_packages.R")

DATA_DIR <- "../data"

# ---------------------------------------------------------------------------
# Load raw data
# ---------------------------------------------------------------------------
proposed_df <- readRDS(file.path(DATA_DIR, "proposed_rules.rds"))
rule_df     <- readRDS(file.path(DATA_DIR, "final_rules.rds"))

cat(sprintf("Loaded %d proposed rules, %d final rules.\n", nrow(proposed_df), nrow(rule_df)))

# ---------------------------------------------------------------------------
# Extract primary agency (first listed agency)
# ---------------------------------------------------------------------------
proposed_df <- proposed_df |>
  mutate(
    primary_agency = str_extract(agency_slugs, "^[^;]+"),
    year  = year(publication_date),
    month = month(publication_date),
    semester = ifelse(month <= 6, 1, 2),
    year_sem = year + (semester - 1) * 0.5
  )

rule_df <- rule_df |>
  mutate(
    primary_agency = str_extract(agency_slugs, "^[^;]+"),
    year  = year(publication_date),
    month = month(publication_date),
    semester = ifelse(month <= 6, 1, 2),
    year_sem = year + (semester - 1) * 0.5
  )

# ---------------------------------------------------------------------------
# Unnest RINs for matching
# ---------------------------------------------------------------------------
# Proposed rules with RINs
proposed_rin <- proposed_df |>
  filter(rins != "" & !is.na(rins)) |>
  separate_rows(rins, sep = ";") |>
  filter(rins != "") |>
  rename(rin = rins, nprm_date = publication_date, nprm_doc = document_number) |>
  select(rin, nprm_date, nprm_doc, primary_agency, significant, year, semester, year_sem)

# Final rules with RINs
rule_rin <- rule_df |>
  filter(rins != "" & !is.na(rins)) |>
  separate_rows(rins, sep = ";") |>
  filter(rins != "") |>
  rename(rin = rins, final_date = publication_date, final_doc = document_number) |>
  select(rin, final_date, final_doc)

cat(sprintf("Proposed rules with RIN: %d\n", nrow(proposed_rin)))
cat(sprintf("Final rules with RIN: %d\n", nrow(rule_rin)))

# ---------------------------------------------------------------------------
# Match NPRMs to final rules
# ---------------------------------------------------------------------------
# For each NPRM-RIN, find the earliest final rule with the same RIN after the NPRM date
matched <- proposed_rin |>
  inner_join(rule_rin, by = "rin", relationship = "many-to-many") |>
  filter(final_date > nprm_date) |>
  group_by(nprm_doc, rin) |>
  slice_min(final_date, n = 1, with_ties = FALSE) |>
  ungroup()

matched <- matched |>
  mutate(
    duration_days = as.numeric(difftime(final_date, nprm_date, units = "days")),
    completed = TRUE
  )

cat(sprintf("Matched NPRM→Final pairs: %d\n", nrow(matched)))
cat(sprintf("Median duration: %.0f days\n", median(matched$duration_days)))

# ---------------------------------------------------------------------------
# Build NPRM-level dataset (all NPRMs, with completion indicator)
# ---------------------------------------------------------------------------
# Flag completed NPRMs (those with a matching final rule)
completed_nprms <- matched |>
  select(nprm_doc, duration_days, final_date, completed) |>
  distinct(nprm_doc, .keep_all = TRUE)

nprm_panel <- proposed_rin |>
  distinct(nprm_doc, .keep_all = TRUE) |>
  left_join(completed_nprms, by = "nprm_doc") |>
  mutate(
    completed = replace_na(completed, FALSE),
    duration_days = replace_na(duration_days, NA_real_)
  )

cat(sprintf("NPRM panel: %d rules, %d completed (%.1f%%)\n",
            nrow(nprm_panel), sum(nprm_panel$completed),
            100 * mean(nprm_panel$completed)))

# ---------------------------------------------------------------------------
# Compute treatment intensity: pre-2017 share of "significant" NPRMs per agency
# ---------------------------------------------------------------------------
agency_intensity <- nprm_panel |>
  filter(year >= 2008 & year <= 2016) |>
  group_by(primary_agency) |>
  summarise(
    n_nprm_pre  = n(),
    n_sig_pre   = sum(significant, na.rm = TRUE),
    sig_share   = n_sig_pre / n_nprm_pre,
    .groups = "drop"
  ) |>
  filter(n_nprm_pre >= 10)  # agencies with non-trivial rulemaking

cat(sprintf("\nAgencies with ≥10 pre-2017 NPRMs: %d\n", nrow(agency_intensity)))
cat("Top 10 by significance share:\n")
print(agency_intensity |> arrange(desc(sig_share)) |> head(10))

# ---------------------------------------------------------------------------
# Build agency-semester panel (2010-2024)
# ---------------------------------------------------------------------------
# Filter to agencies with sufficient pre-period activity
valid_agencies <- agency_intensity$primary_agency

# Create complete panel skeleton
semesters <- tibble(
  year = rep(2010:2024, each = 2),
  semester = rep(1:2, times = 15)
) |>
  mutate(year_sem = year + (semester - 1) * 0.5)

panel_skeleton <- expand_grid(
  primary_agency = valid_agencies,
  semesters
)

# Aggregate NPRMs to agency-semester level
nprm_agg <- nprm_panel |>
  filter(primary_agency %in% valid_agencies & year >= 2010 & year <= 2024) |>
  group_by(primary_agency, year, semester) |>
  summarise(
    n_nprm           = n(),
    n_completed      = sum(completed, na.rm = TRUE),
    n_significant    = sum(significant, na.rm = TRUE),
    mean_duration    = mean(duration_days, na.rm = TRUE),
    median_duration  = median(duration_days, na.rm = TRUE),
    completion_rate  = mean(completed, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(year_sem = year + (semester - 1) * 0.5)

# Merge into panel
panel <- panel_skeleton |>
  left_join(nprm_agg, by = c("primary_agency", "year", "semester", "year_sem")) |>
  left_join(agency_intensity |> select(primary_agency, sig_share, n_nprm_pre),
            by = "primary_agency") |>
  mutate(
    n_nprm = replace_na(n_nprm, 0),
    n_completed = replace_na(n_completed, 0),
    n_significant = replace_na(n_significant, 0),
    completion_rate = replace_na(completion_rate, NA_real_),
    # Treatment variables
    post_eo13771 = as.integer(year_sem >= 2017),
    post_rescind = as.integer(year_sem >= 2021.5),
    # Continuous treatment interaction
    treat_eo = post_eo13771 * sig_share,
    treat_rescind = post_rescind * sig_share,
    # Log NPRM count (for extensive margin)
    log_nprm = log(n_nprm + 1),
    # Time index for event study
    time_idx = (year - 2017) * 2 + semester - 1  # centered at 2017H1 = 0
  )

cat(sprintf("\nFinal panel: %d agency-semester observations\n", nrow(panel)))
cat(sprintf("  Agencies: %d\n", n_distinct(panel$primary_agency)))
cat(sprintf("  Semesters: %d (%d-%d)\n", n_distinct(panel$year_sem),
            min(panel$year), max(panel$year)))

# ---------------------------------------------------------------------------
# Save analysis dataset
# ---------------------------------------------------------------------------
saveRDS(panel, file.path(DATA_DIR, "analysis_panel.rds"))
saveRDS(nprm_panel, file.path(DATA_DIR, "nprm_panel.rds"))
saveRDS(agency_intensity, file.path(DATA_DIR, "agency_intensity.rds"))

write_csv(panel, file.path(DATA_DIR, "analysis_panel.csv"))

cat("\nAnalysis datasets saved.\n")

# ---------------------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat(sprintf("Mean sig_share: %.3f (SD: %.3f)\n",
            mean(agency_intensity$sig_share), sd(agency_intensity$sig_share)))
cat(sprintf("Mean NPRMs per agency-semester: %.1f\n",
            mean(panel$n_nprm)))
cat(sprintf("Mean completion rate: %.3f\n",
            mean(panel$completion_rate, na.rm = TRUE)))
cat(sprintf("Mean duration (completed): %.0f days\n",
            mean(panel$mean_duration, na.rm = TRUE)))
