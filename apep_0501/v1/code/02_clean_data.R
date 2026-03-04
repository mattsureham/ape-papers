## 02_clean_data.R — Build analysis panel from raw data
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

source("00_packages.R")

DATA_DIR <- "../data"

# =============================================================================
# 1. LOAD RAW DATA
# =============================================================================

cat("=== Loading raw data ===\n")

referendum <- fread(file.path(DATA_DIR, "referendum_panel.csv"))
referendum[, vote_date := as.Date(vote_date)]
first_merger <- fread(file.path(DATA_DIR, "first_merger.csv"))
merger_timeline <- fread(file.path(DATA_DIR, "merger_timeline.csv"))

cat(sprintf("Referendum panel: %s rows, %d communes\n",
            format(nrow(referendum), big.mark = ","),
            uniqueN(referendum$commune_code)))
cat(sprintf("Merger successor communes: %d\n", nrow(first_merger)))

# =============================================================================
# 2. FILTER TO COMMUNE-LEVEL DATA
# =============================================================================

cat("\n=== Filtering to commune-level data ===\n")

# The BFS data includes national total, cantons, and districts
# Keep only commune-level entries (labels starting with "......")
# Also exclude special entries (abroad, correspondence, other)
referendum <- referendum[grepl("^[.][.][.][.][.][.]", commune_label)]
referendum <- referendum[!grepl("Ausland|Anderes|Korrespondenz", commune_label)]

cat(sprintf("After filtering to communes: %s rows, %d communes\n",
            format(nrow(referendum), big.mark = ","),
            uniqueN(referendum$commune_code)))

# =============================================================================
# 3. MATCH MERGER TIMELINE TO REFERENDUM COMMUNES
# =============================================================================

cat("\n=== Matching mergers to referendum communes ===\n")

# Match successor_code from merger timeline to commune_code in referendum data
# The successor codes should match current BFS commune numbers
first_merger[, commune_code := as.character(successor_code)]

# Check overlap
overlap <- sum(first_merger$commune_code %in% unique(referendum$commune_code))
cat(sprintf("Merger communes in referendum data: %d / %d\n",
            overlap, nrow(first_merger)))

# Focus on mergers from 2000-2020 (good referendum coverage before and after)
first_merger_focused <- first_merger[first_merger_year >= 2000 & first_merger_year <= 2020]
cat(sprintf("Mergers 2000-2020: %d communes\n", nrow(first_merger_focused)))

# Merge treatment status into referendum panel
analysis_panel <- merge(
  referendum,
  first_merger_focused[, .(commune_code, treatment_year = first_merger_year,
                            n_merger_events, total_absorbed)],
  by = "commune_code", all.x = TRUE
)

# Treatment indicators
analysis_panel[, treated := !is.na(treatment_year)]
analysis_panel[, post := !is.na(treatment_year) & vote_year >= treatment_year]
analysis_panel[treated == TRUE, event_year := vote_year - treatment_year]

cat(sprintf("Analysis panel: %s rows\n", format(nrow(analysis_panel), big.mark = ",")))
cat(sprintf("  Treated communes: %d\n", uniqueN(analysis_panel[treated == TRUE, commune_code])))
cat(sprintf("  Control communes: %d\n", uniqueN(analysis_panel[treated == FALSE, commune_code])))

# Treatment year distribution
if (uniqueN(analysis_panel[treated == TRUE, commune_code]) > 0) {
  cat("\nTreatment year distribution:\n")
  print(analysis_panel[treated == TRUE, uniqueN(commune_code), by = treatment_year][order(treatment_year)])
}

# =============================================================================
# 4. COMPUTE TURNOUT AND CLEAN
# =============================================================================

cat("\n=== Computing turnout variables ===\n")

# Ensure turnout is numeric and bounded
analysis_panel[, turnout := as.numeric(turnout_pct)]
analysis_panel[turnout < 0 | turnout > 100, turnout := NA]

# Compute alternative turnout from eligible and ballots
analysis_panel[, turnout_computed := as.numeric(ballots) / as.numeric(eligible) * 100]
analysis_panel[turnout_computed < 0 | turnout_computed > 100, turnout_computed := NA]

# Use reported turnout if available, computed otherwise
analysis_panel[, turnout_final := fifelse(!is.na(turnout), turnout, turnout_computed)]

# Yes share
analysis_panel[, yes_share := as.numeric(yes_pct)]

# Log eligible voters
analysis_panel[, log_eligible := log(as.numeric(eligible) + 1)]

# Remove missing turnout observations
n_before <- nrow(analysis_panel)
analysis_panel <- analysis_panel[!is.na(turnout_final) & !is.na(vote_year)]
cat(sprintf("Dropped %d rows with missing turnout (%.1f%%)\n",
            n_before - nrow(analysis_panel),
            (n_before - nrow(analysis_panel)) / n_before * 100))

# Create numeric commune ID for fixest
analysis_panel[, commune_id := as.integer(factor(commune_code))]
analysis_panel[, vote_id := as.integer(factor(vote_date))]

# =============================================================================
# 5. SAVE ANALYSIS PANEL
# =============================================================================

cat("\n=== Saving analysis panel ===\n")

fwrite(analysis_panel, file.path(DATA_DIR, "analysis_panel.csv"))

# Save summary statistics
summary_stats <- data.table(
  statistic = c("N_observations", "N_communes", "N_treated", "N_control",
                "N_votes", "Year_min", "Year_max",
                "Turnout_mean", "Turnout_sd",
                "Eligible_mean", "Eligible_median"),
  value = c(
    nrow(analysis_panel),
    uniqueN(analysis_panel$commune_code),
    uniqueN(analysis_panel[treated == TRUE, commune_code]),
    uniqueN(analysis_panel[treated == FALSE, commune_code]),
    uniqueN(analysis_panel$vote_date),
    min(analysis_panel$vote_year, na.rm = TRUE),
    max(analysis_panel$vote_year, na.rm = TRUE),
    round(mean(analysis_panel$turnout_final, na.rm = TRUE), 2),
    round(sd(analysis_panel$turnout_final, na.rm = TRUE), 2),
    round(mean(as.numeric(analysis_panel$eligible), na.rm = TRUE), 0),
    round(median(as.numeric(analysis_panel$eligible), na.rm = TRUE), 0)
  )
)
fwrite(summary_stats, file.path(DATA_DIR, "summary_stats.csv"))
print(summary_stats)

cat("\nPanel construction complete.\n")
