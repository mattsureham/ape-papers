# 02_clean_data.R — Clean and prepare analysis dataset
# apep_0637: Patent Examiner Leniency & Defensive Patenting

source("00_packages.R")

# Load BigQuery extract
csv_path <- "../data/analysis_dataset.csv"
if (!file.exists(csv_path)) {
  stop("FATAL: analysis_dataset.csv not found. Run 01_fetch_data.py first.")
}

cat("Loading analysis dataset...\n")
df <- read_csv(csv_path, show_col_types = FALSE)
cat(sprintf("  Raw: %s observations\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 1. Basic cleaning
# ============================================================================

# Ensure key variables are properly typed
df <- df %>%
  mutate(
    granted = as.integer(granted),
    examiner_id = as.character(examiner_id),
    examiner_art_unit = as.character(examiner_art_unit),
    filing_year = as.integer(filing_year),
    examiner_leniency = as.numeric(examiner_leniency),
    # Create art-unit × year identifier for FE
    au_year = paste0(examiner_art_unit, "_", filing_year)
  )

# Drop observations with missing leniency
df <- df %>% filter(!is.na(examiner_leniency))
cat(sprintf("  After dropping missing leniency: %s\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 2. Examiner-level filters
# ============================================================================

# Require minimum 10 cases per examiner × art-unit × year for reliable LOO
df <- df %>% filter(exam_n_cases >= 10)
cat(sprintf("  After min 10 cases filter: %s\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 3. Construct outcome variables
# ============================================================================

# Technology class for outcome
if ("uspc_class" %in% names(df)) {
  df <- df %>% filter(!is.na(uspc_class) & uspc_class != "")
  cat(sprintf("  After non-missing USPC class: %s\n", format(nrow(df), big.mark = ",")))
  tech_class_var <- "uspc_class"
} else {
  # Fallback to art unit
  tech_class_var <- "examiner_art_unit"
  cat("  Using art unit as technology class (USPC class not available)\n")
}

# Log outcome variables (add 1 to handle zeros)
outcome_vars <- c("class_filings_t1", "class_filings_t2", "class_filings_t3",
                   "class_filings_2yr", "class_filings_3yr")

for (v in outcome_vars) {
  if (v %in% names(df)) {
    df[[paste0("log_", v)]] <- log(df[[v]] + 1)
  }
}

# Asinh transformation (handles zeros better than log(x+1))
for (v in outcome_vars) {
  if (v %in% names(df)) {
    df[[paste0("asinh_", v)]] <- asinh(df[[v]])
  }
}

# ============================================================================
# 4. Additional controls
# ============================================================================

# Small entity indicator
if ("small_entity_indicator" %in% names(df)) {
  df$small_entity <- as.integer(!is.na(df$small_entity_indicator) &
                                  df$small_entity_indicator == 1)
} else {
  df$small_entity <- 0L
}

# ============================================================================
# 5. Within-art-unit leniency residual (for IV strength check)
# ============================================================================

# Residualize leniency against art-unit × year means
au_year_means <- df %>%
  group_by(au_year) %>%
  summarise(
    mean_leniency = mean(examiner_leniency, na.rm = TRUE),
    sd_leniency = sd(examiner_leniency, na.rm = TRUE),
    n_apps = n(),
    n_examiners = n_distinct(examiner_id),
    grant_rate = mean(granted),
    .groups = "drop"
  )

df <- df %>%
  left_join(au_year_means, by = "au_year")

# Residual leniency = within-AU-year variation
df$leniency_resid <- df$examiner_leniency - df$mean_leniency

# ============================================================================
# 6. Sample restrictions for analysis
# ============================================================================

# Require at least 2 examiners per AU-year (for within-AU variation)
df <- df %>% filter(n_examiners >= 2)
cat(sprintf("  After min 2 examiners per AU-year: %s\n", format(nrow(df), big.mark = ",")))

# Final filing year restriction (2008-2015 for outcome windows)
df <- df %>% filter(filing_year >= 2008 & filing_year <= 2015)
cat(sprintf("  Final analysis sample (2008-2015): %s\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 7. Summary statistics
# ============================================================================

cat("\n=== SAMPLE SUMMARY ===\n")
cat(sprintf("Observations: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("Unique examiners: %s\n", format(n_distinct(df$examiner_id), big.mark = ",")))
cat(sprintf("Unique art units: %s\n", format(n_distinct(df$examiner_art_unit), big.mark = ",")))
if ("uspc_class" %in% names(df)) {
  cat(sprintf("Unique USPC classes: %s\n", format(n_distinct(df$uspc_class), big.mark = ",")))
}
cat(sprintf("AU-year cells: %s\n", format(n_distinct(df$au_year), big.mark = ",")))
cat(sprintf("Grant rate: %.3f\n", mean(df$granted)))
cat(sprintf("Mean examiner leniency: %.3f (SD: %.3f)\n",
            mean(df$examiner_leniency), sd(df$examiner_leniency)))
cat(sprintf("Mean within-AU-year SD of leniency: %.3f\n",
            mean(au_year_means$sd_leniency, na.rm = TRUE)))

if ("class_filings_t1" %in% names(df)) {
  cat(sprintf("Mean class filings t+1: %.0f (SD: %.0f)\n",
              mean(df$class_filings_t1, na.rm = TRUE),
              sd(df$class_filings_t1, na.rm = TRUE)))
}

# ============================================================================
# 8. Save analysis dataset
# ============================================================================

saveRDS(df, "../data/analysis_clean.rds")
cat("\nSaved cleaned dataset to data/analysis_clean.rds\n")
