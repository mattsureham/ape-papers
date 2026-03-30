## 02_clean_data.R — Clean and construct analysis variables
## APEP-1123: The Registration Effect

source("00_packages.R")

cat("=== Cleaning data ===\n")

df <- read_csv("data/trials_raw.csv", show_col_types = FALSE)
cat(sprintf("Raw trials: %d\n", nrow(df)))

# Parse dates
parse_ct_date <- function(x) {
  # ClinicalTrials.gov dates come as "YYYY-MM-DD", "YYYY-MM", "YYYY", or other
  x <- as.character(x)
  out <- as.Date(rep(NA, length(x)))
  valid <- !is.na(x) & nchar(x) >= 4

  # Full date
  full <- valid & grepl("^\\d{4}-\\d{2}-\\d{2}$", x)
  if (any(full)) out[full] <- as.Date(x[full], format = "%Y-%m-%d")

  # Month only
  month_only <- valid & grepl("^\\d{4}-\\d{2}$", x) & !full
  if (any(month_only)) out[month_only] <- as.Date(paste0(x[month_only], "-01"), format = "%Y-%m-%d")

  # Year only
  year_only <- valid & grepl("^\\d{4}$", x) & !full & !month_only
  if (any(year_only)) out[year_only] <- as.Date(paste0(x[year_only], "-01-01"), format = "%Y-%m-%d")

  out
}

df <- df |>
  mutate(
    start_dt = parse_ct_date(start_date),
    completion_dt = parse_ct_date(completion_date),
    primary_completion_dt = parse_ct_date(primary_completion_date),
    results_post_dt = parse_ct_date(results_first_post_date),
    start_year = year(start_dt)
  )

# Phase classification for DiD
df <- df |>
  mutate(
    phase_group = case_when(
      phase == "PHASE1" ~ "Phase 1",
      phase == "EARLY_PHASE1" ~ "Phase 1",
      phase %in% c("PHASE2", "PHASE3", "PHASE2/PHASE3") ~ "Phase 2/3",
      phase == "PHASE1/PHASE2" ~ "Phase 1/2",
      TRUE ~ "Other"
    )
  )

# Focus on Phase 1 (control) and Phase 2/3 (treated)
# Exclude Phase 1/2 (ambiguous treatment status)
df_analysis <- df |>
  filter(
    phase_group %in% c("Phase 1", "Phase 2/3"),
    start_year >= 2003,
    start_year <= 2015
  )

cat(sprintf("Analysis sample (2003-2015, Phase 1 + Phase 2/3): %d\n", nrow(df_analysis)))

# Construct DiD variables
df_analysis <- df_analysis |>
  mutate(
    # Treatment indicator
    treated = as.integer(phase_group == "Phase 2/3"),
    # Post indicator (FDAAA 801 signed Sept 2007; effective for new trials)
    post = as.integer(start_year >= 2008),
    # Interaction
    treat_post = treated * post,
    # Outcome 1: Has results posted
    has_results_posted = as.integer(!is.na(results_post_dt)),
    # Outcome 2: Days to results posting (from primary completion)
    days_to_results = as.numeric(difftime(results_post_dt,
                                           coalesce(primary_completion_dt, completion_dt),
                                           units = "days")),
    # Outcome 3: Number of primary outcomes
    n_primary = n_primary_outcomes,
    # Sponsor type
    is_industry = as.integer(sponsor_class == "INDUSTRY"),
    is_nih = as.integer(sponsor_class == "NIH"),
    # Completed trial (for results reporting analysis)
    is_completed = as.integer(overall_status %in% c("COMPLETED", "TERMINATED")),
    # Enrollment (log)
    log_enrollment = log(pmax(enrollment, 1, na.rm = TRUE)),
    # Condition category (first word as rough grouping)
    condition_broad = str_extract(condition_first, "^[A-Za-z]+")
  )

# For results reporting: restrict to completed/terminated trials
df_completed <- df_analysis |>
  filter(is_completed == 1)

cat(sprintf("Completed/terminated trials: %d\n", nrow(df_completed)))
cat(sprintf("  With results posted: %d (%.1f%%)\n",
            sum(df_completed$has_results_posted),
            100 * mean(df_completed$has_results_posted)))

# Summary statistics
cat("\n=== Summary by phase group and period ===\n")
df_analysis |>
  group_by(phase_group, post) |>
  summarise(
    n = n(),
    pct_completed = mean(is_completed, na.rm = TRUE),
    pct_has_results = mean(has_results_posted, na.rm = TRUE),
    mean_primary_outcomes = mean(n_primary, na.rm = TRUE),
    mean_enrollment = mean(enrollment, na.rm = TRUE),
    pct_industry = mean(is_industry, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# Save analysis datasets
write_csv(df_analysis, "data/trials_analysis.csv")
write_csv(df_completed, "data/trials_completed.csv")

cat(sprintf("\nSaved analysis data: %d trials\n", nrow(df_analysis)))
cat(sprintf("Saved completed data: %d trials\n", nrow(df_completed)))

cat("\n=== Cleaning complete ===\n")
