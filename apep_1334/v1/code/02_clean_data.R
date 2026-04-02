##############################################################################
# 02_clean_data.R — Construct examiner leniency instrument + clean data
# Paper: "Paper Patents and Real Markets" (apep_1334)
##############################################################################

source("code/00_packages.R")

cat("=== Loading data ===\n")
df <- as.data.table(read_parquet("data/patent_market_data.parquet"))
cat(sprintf("  Loaded %s applications\n", format(nrow(df), big.mark = ",")))

# Create key variables
df[, granted := as.integer(disposal_type == "ISS")]
df[, small_entity := as.integer(small_entity_indicator == "1")]
df[, collateralized := as.integer(has_security)]

# -----------------------------------------------------------------------
# Step 1: Create art-unit x filing-year cells
# -----------------------------------------------------------------------
cat("\n=== Creating cells ===\n")

# 3-digit art unit (technology center)
df[, art_unit_3 := substr(examiner_art_unit, 1, 3)]
df[, cell := paste(examiner_art_unit, filing_year, sep = "_")]

# Cell sizes
cell_sizes <- df[, .N, by = cell]
cat(sprintf("  Cells: %s\n", format(nrow(cell_sizes), big.mark = ",")))
cat(sprintf("  Median cell size: %d\n", median(cell_sizes$N)))

# -----------------------------------------------------------------------
# Step 2: Construct leave-one-out examiner grant rate
# -----------------------------------------------------------------------
cat("\n=== Constructing examiner leniency instrument ===\n")

# Examiner-level stats within art-unit x filing-year
# LOO: for each application, examiner grant rate excluding that application
df[, examiner_cell := paste(examiner_id, cell, sep = "_")]

# Count grants and total per examiner-cell
examiner_cell_stats <- df[, .(
  n_apps = .N,
  n_grants = sum(granted)
), by = .(examiner_id, cell)]

df <- merge(df, examiner_cell_stats,
            by = c("examiner_id", "cell"), all.x = TRUE)

# Leave-one-out: (total grants in cell for examiner - this app's grant) / (total apps - 1)
df[, loo_grant_rate := fifelse(
  n_apps > 1,
  (n_grants - granted) / (n_apps - 1),
  NA_real_
)]

# Drop examiners with only 1 app in cell (no LOO possible)
n_before <- nrow(df)
df <- df[!is.na(loo_grant_rate)]
cat(sprintf("  Dropped %s apps (single-app examiner-cells)\n",
            format(n_before - nrow(df), big.mark = ",")))

# -----------------------------------------------------------------------
# Step 3: Filter to examiners with sufficient caseload
# -----------------------------------------------------------------------
cat("\n=== Filtering by examiner caseload ===\n")

# Require examiner has 50+ total resolved apps (across all cells)
examiner_total <- df[, .(total_apps = .N), by = examiner_id]
experienced <- examiner_total[total_apps >= 50, examiner_id]
cat(sprintf("  Examiners with 50+ apps: %s of %s\n",
            format(length(experienced), big.mark = ","),
            format(nrow(examiner_total), big.mark = ",")))

n_before <- nrow(df)
df <- df[examiner_id %in% experienced]
cat(sprintf("  Dropped %s apps (inexperienced examiners)\n",
            format(n_before - nrow(df), big.mark = ",")))

# -----------------------------------------------------------------------
# Step 4: Summary statistics
# -----------------------------------------------------------------------
cat("\n=== Summary statistics ===\n")
cat(sprintf("  Final sample: %s applications\n", format(nrow(df), big.mark = ",")))
cat(sprintf("  Examiners: %s\n", format(uniqueN(df$examiner_id), big.mark = ",")))
cat(sprintf("  Art units: %s\n", format(uniqueN(df$examiner_art_unit), big.mark = ",")))
cat(sprintf("  Filing years: %d - %d\n", min(df$filing_year), max(df$filing_year)))
cat(sprintf("  Grant rate: %.3f\n", mean(df$granted)))
cat(sprintf("  LOO leniency: mean=%.3f, sd=%.3f, p10=%.3f, p90=%.3f\n",
            mean(df$loo_grant_rate),
            sd(df$loo_grant_rate),
            quantile(df$loo_grant_rate, 0.10),
            quantile(df$loo_grant_rate, 0.90)))
cat(sprintf("  Market transfer rate: %.3f\n", mean(df$market_transfer)))
cat(sprintf("    Granted: %.3f\n", mean(df$market_transfer[df$granted == 1])))
cat(sprintf("    Abandoned: %.3f\n", mean(df$market_transfer[df$granted == 0])))
cat(sprintf("  Security interest rate: %.3f\n", mean(df$collateralized)))
cat(sprintf("    Granted: %.3f\n", mean(df$collateralized[df$granted == 1])))
cat(sprintf("    Abandoned: %.3f\n", mean(df$collateralized[df$granted == 0])))
cat(sprintf("  Small entity share: %.3f\n", mean(df$small_entity, na.rm = TRUE)))

# -----------------------------------------------------------------------
# Step 5: Save cleaned data
# -----------------------------------------------------------------------
cat("\n=== Saving cleaned data ===\n")
write_parquet(df, "data/analysis_data.parquet")
cat("Saved data/analysis_data.parquet\n")
