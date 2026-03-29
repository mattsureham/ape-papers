## 02_clean_data.R — Variable construction for twin study
## APEP-1116: The Patent Office Lottery

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")

# ── 1. Load twin pairs ──────────────────────────────────────────────────
cat("Loading twin pairs...\n")
twins <- fread(file.path(data_dir, "twin_pairs.csv"))
cat(sprintf("  Raw twin pairs: %s\n", format(nrow(twins), big.mark = ",")))

# ── 2. Load examiner grant rates ────────────────────────────────────────
cat("Loading examiner grant rates...\n")
exam_rates <- fread(file.path(data_dir, "examiner_grant_rates.csv"))

# ── 3. Compute leave-one-out examiner leniency ─────────────────────────
# For each child application, compute the child examiner's grant rate
# EXCLUDING the current application (leave-one-out)
cat("Computing leave-one-out leniency...\n")

# Aggregate examiner-level stats across all AU-years
exam_overall <- exam_rates[, .(
  total_apps = sum(n_apps),
  total_granted = sum(n_granted)
), by = examiner_id]

# Child application grant indicator
twins[, child_granted := as.integer(child_disposal == "ISS")]
twins[, parent_granted := as.integer(parent_disposal == "ISS")]

# Merge examiner totals for child examiner
twins <- merge(twins, exam_overall,
               by.x = "child_examiner_id", by.y = "examiner_id",
               all.x = TRUE)

# Leave-one-out: remove current app from examiner's record
twins[, child_exam_loo_rate := fifelse(
  total_apps > 1,
  (total_granted - child_granted) / (total_apps - 1),
  NA_real_
)]

# Clean up
twins[, c("total_apps", "total_granted") := NULL]

# Also compute parent examiner leniency (not LOO — parent is not in child's record)
twins <- merge(twins, exam_overall,
               by.x = "parent_examiner_id", by.y = "examiner_id",
               all.x = TRUE, suffixes = c("", "_parent"))
twins[, parent_exam_rate := fifelse(
  total_apps > 1,
  total_granted / total_apps,
  NA_real_
)]
twins[, c("total_apps", "total_granted") := NULL]

# ── 4. Restrict to analysis sample ─────────────────────────────────────
cat("Constructing analysis sample...\n")

# Key restrictions:
# (a) Same art unit (within-AU comparison)
# (b) Non-missing leniency
# (c) Filing years 1998-2015 (allow time for disposition)
analysis <- twins[
  same_art_unit == 1 &
  !is.na(child_exam_loo_rate) &
  child_filing_year >= 1998 &
  child_filing_year <= 2015
]

cat(sprintf("  Analysis sample: %s pairs\n",
            format(nrow(analysis), big.mark = ",")))

# ── 5. Create key variables ────────────────────────────────────────────
# Small entity indicator (child)
analysis[, small_entity := as.integer(child_small_entity == "1")]

# Reassignment indicator
analysis[, reassigned := as.integer(diff_examiner == 1)]

# Technology center (first 2 digits of art unit, as string)
analysis[, tech_center := substr(as.character(child_art_unit), 1, 2)]

# Art-unit × filing-year fixed effect
analysis[, au_year := paste0(child_art_unit, "_", child_filing_year)]

# Standardize leniency within AU-year for interpretability
analysis[, leniency_z := (child_exam_loo_rate - mean(child_exam_loo_rate, na.rm = TRUE)) /
           sd(child_exam_loo_rate, na.rm = TRUE),
         by = au_year]

# ── 6. Summary statistics ──────────────────────────────────────────────
cat("\n=== ANALYSIS SAMPLE SUMMARY ===\n")
cat(sprintf("Total same-AU pairs: %s\n",
            format(nrow(analysis), big.mark = ",")))
cat(sprintf("  Reassigned (diff examiner): %s (%.1f%%)\n",
            format(sum(analysis$reassigned), big.mark = ","),
            100 * mean(analysis$reassigned)))
cat(sprintf("  Same examiner: %s (%.1f%%)\n",
            format(sum(1 - analysis$reassigned), big.mark = ","),
            100 * (1 - mean(analysis$reassigned))))
cat(sprintf("  Small entity: %.1f%%\n", 100 * mean(analysis$small_entity)))
cat(sprintf("  Child granted: %.1f%%\n", 100 * mean(analysis$child_granted)))
cat(sprintf("  Discordant: %.1f%%\n", 100 * mean(analysis$discordant)))
cat(sprintf("  Discordance (reassigned): %.1f%%\n",
            100 * mean(analysis$discordant[analysis$reassigned == 1])))
cat(sprintf("  Discordance (same exam): %.1f%%\n",
            100 * mean(analysis$discordant[analysis$reassigned == 0])))
cat(sprintf("  Leniency mean: %.3f, SD: %.3f\n",
            mean(analysis$child_exam_loo_rate, na.rm = TRUE),
            sd(analysis$child_exam_loo_rate, na.rm = TRUE)))
cat(sprintf("  Unique art units: %d\n", uniqueN(analysis$child_art_unit)))
cat(sprintf("  Unique examiners (child): %d\n", uniqueN(analysis$child_examiner_id)))
cat(sprintf("  Filing years: %d-%d\n", min(analysis$child_filing_year), max(analysis$child_filing_year)))

# ── 7. Save cleaned data ───────────────────────────────────────────────
fwrite(analysis, file.path(data_dir, "analysis_sample.csv"))
cat(sprintf("\nSaved analysis sample: %s rows\n",
            format(nrow(analysis), big.mark = ",")))
