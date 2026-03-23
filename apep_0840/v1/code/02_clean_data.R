## 02_clean_data.R — Clean and merge referendum, disaster, and metadata
## apep_0840: Competing News IV and Swiss Referendum Turnout

source("00_packages.R")

# ============================================================================
# 1. Clean referendum data
# ============================================================================

cat("Loading referendum data...\n")
ref <- fread("../data/referendum_raw.csv")
cat(sprintf("  Raw: %d rows\n", nrow(ref)))

# Rename columns to English
setnames(ref, old = c("mun_id", "mun_name", "jaStimmenInProzent",
                       "stimmbeteiligungInProzent", "anzahlStimmberechtigte",
                       "eingelegteStimmzettel"),
         new = c("bfs_id", "municipality", "yes_pct",
                 "turnout_pct", "eligible_voters", "ballots_cast"),
         skip_absent = TRUE)

# Parse vote date
ref[, votedate := as.Date(votedate)]
ref[, vote_year := year(votedate)]

# Create unique ballot item identifier
ref[, ballot_id := paste0(as.integer(factor(paste(name, votedate))))]

# Assign language region based on canton (numeric BFS canton IDs)
# French: GE=25, VD=22, NE=24, JU=26
# Italian: TI=21
# Bilingual, classified by dominant: FR=10 (fr), VS=23 (fr), BE=2 (de), GR=18 (de)
fr_cantons <- c(25, 22, 24, 26, 10, 23)  # GE, VD, NE, JU, FR, VS
it_cantons <- c(21)  # TI

ref[, lang_region := fcase(
  canton_id %in% fr_cantons, "fr",
  canton_id %in% it_cantons, "it",
  default = "de"
)]

# Drop Italian-speaking (too few for separate language instrument)
ref[, include_main := lang_region %in% c("de", "fr")]

cat(sprintf("  Language split: de=%d, fr=%d, it=%d\n",
    sum(ref$lang_region == "de"), sum(ref$lang_region == "fr"),
    sum(ref$lang_region == "it")))
cat(sprintf("  Main sample (de+fr): %d obs\n", sum(ref$include_main)))

# ============================================================================
# 2. Load and merge disaster instrument
# ============================================================================

cat("\nLoading disaster instrument...\n")
disasters <- fread("../data/disaster_instrument.csv")

# Use the 7-day window as primary instrument
dis_7d <- disasters[window == "7day", .(
  vote_date = as.Date(vote_date),
  source_lang,
  n_earthquakes,
  n_large_earthquakes,
  max_magnitude,
  salience_score,
  salience_large,
  total_magnitude
)]

# Also get 14-day for robustness
dis_14d <- disasters[window == "14day", .(
  vote_date = as.Date(vote_date),
  source_lang,
  salience_score_14d = salience_score,
  salience_large_14d = salience_large
)]

dis_merged <- merge(dis_7d, dis_14d, by = c("vote_date", "source_lang"))

cat(sprintf("  Disaster data: %d vote-date × language obs\n", nrow(dis_merged)))
cat(sprintf("  Salience score range: %.1f to %.1f\n",
    min(dis_merged$salience_score), max(dis_merged$salience_score)))

# Construct the differential instrument:
# For each vote date, compute the DIFFERENCE in salience between French and German media
# This is the within-vote-date variation that identifies the effect
dis_wide <- dcast(dis_merged, vote_date ~ source_lang,
                  value.var = c("salience_score", "salience_large",
                                "n_earthquakes", "total_magnitude",
                                "salience_score_14d"))

dis_wide[, salience_diff := salience_score_fr - salience_score_de]
cat(sprintf("  Fr-De salience differential range: %.1f to %.1f\n",
    min(dis_wide$salience_diff), max(dis_wide$salience_diff)))

# ============================================================================
# 3. Load Swissvotes metadata
# ============================================================================

cat("\nLoading Swissvotes ballot metadata...\n")
sv <- fread("../data/swissvotes_raw.csv")
sv[, datum := as.Date(datum, format = "%d.%m.%Y")]

# Policy domain classification
sv[, n_domains := rowSums(!is.na(.SD)), .SDcols = c("d1e1", "d2e1", "d3e1")]
sv[, govt_recommends_yes := (br.pos == 1)]

# Items per vote date (from swissvotes)
sv_datecount <- sv[datum >= as.Date("2015-01-01"), .(n_items_sv = .N), by = datum]

# ============================================================================
# 4. Merge all datasets
# ============================================================================

cat("\nMerging datasets...\n")

# Merge referendum with disaster instrument
panel <- merge(ref[include_main == TRUE],
               dis_merged,
               by.x = c("votedate", "lang_region"),
               by.y = c("vote_date", "source_lang"),
               all.x = TRUE)

cat(sprintf("  After disaster merge: %d obs (%.1f%% with instrument)\n",
    nrow(panel), 100 * mean(!is.na(panel$salience_score))))

# Number of items on same date
panel[, n_items_on_date := uniqueN(name), by = votedate]

# ============================================================================
# 5. Construct analysis variables
# ============================================================================

# Standardize instrument for interpretability
panel[, salience_std := (salience_score - mean(salience_score, na.rm = TRUE)) /
        sd(salience_score, na.rm = TRUE)]
panel[, salience_large_std := (salience_large - mean(salience_large, na.rm = TRUE)) /
        sd(salience_large, na.rm = TRUE)]

# Log salience (for semi-elasticity interpretation)
panel[, log_salience := log(salience_score + 1)]

# Interaction: language × year
panel[, lang_year := paste0(lang_region, "_", vote_year)]

# ============================================================================
# 6. Summary statistics
# ============================================================================

cat("\n=== Final Panel Summary ===\n")
cat(sprintf("  Observations: %d\n", nrow(panel)))
cat(sprintf("  Municipalities: %d\n", uniqueN(panel$bfs_id)))
cat(sprintf("  Vote dates: %d\n", uniqueN(panel$votedate)))
cat(sprintf("  Ballot items: %d\n", uniqueN(panel$name)))
cat(sprintf("  Language regions: %s\n", paste(unique(panel$lang_region), collapse=", ")))

cat("\nKey variables:\n")
for (v in c("turnout_pct", "yes_pct", "salience_score", "n_earthquakes",
            "max_magnitude", "eligible_voters")) {
  vals <- panel[[v]]
  cat(sprintf("  %-20s: mean=%.2f, sd=%.2f, min=%.2f, max=%.2f, NA=%d\n",
      v, mean(vals, na.rm=T), sd(vals, na.rm=T),
      min(vals, na.rm=T), max(vals, na.rm=T), sum(is.na(vals))))
}

# Save summary stats
summ_vars <- data.table(
  Variable = c("Turnout (\\%)", "Yes vote share (\\%)",
               "Earthquake salience (7-day)", "No. earthquakes M5.0+ (7-day)",
               "Max magnitude (7-day)", "Eligible voters",
               "Items on ballot"),
  N = as.integer(c(sum(!is.na(panel$turnout_pct)), sum(!is.na(panel$yes_pct)),
      sum(!is.na(panel$salience_score)), sum(!is.na(panel$n_earthquakes)),
      sum(!is.na(panel$max_magnitude)), sum(!is.na(panel$eligible_voters)),
      sum(!is.na(panel$n_items_on_date)))),
  Mean = c(mean(panel$turnout_pct, na.rm=T), mean(panel$yes_pct, na.rm=T),
           mean(panel$salience_score, na.rm=T), mean(panel$n_earthquakes, na.rm=T),
           mean(panel$max_magnitude, na.rm=T), mean(panel$eligible_voters, na.rm=T),
           mean(panel$n_items_on_date, na.rm=T)),
  SD = c(sd(panel$turnout_pct, na.rm=T), sd(panel$yes_pct, na.rm=T),
         sd(panel$salience_score, na.rm=T), sd(panel$n_earthquakes, na.rm=T),
         sd(panel$max_magnitude, na.rm=T), sd(panel$eligible_voters, na.rm=T),
         sd(panel$n_items_on_date, na.rm=T)),
  Min = c(min(panel$turnout_pct, na.rm=T), min(panel$yes_pct, na.rm=T),
          min(panel$salience_score, na.rm=T), min(panel$n_earthquakes, na.rm=T),
          min(panel$max_magnitude, na.rm=T), min(panel$eligible_voters, na.rm=T),
          min(panel$n_items_on_date, na.rm=T)),
  Max = c(max(panel$turnout_pct, na.rm=T), max(panel$yes_pct, na.rm=T),
          max(panel$salience_score, na.rm=T), max(panel$n_earthquakes, na.rm=T),
          max(panel$max_magnitude, na.rm=T), max(panel$eligible_voters, na.rm=T),
          max(panel$n_items_on_date, na.rm=T))
)

fwrite(summ_vars, "../data/summary_stats.csv")
fwrite(panel, "../data/analysis_panel.csv")
cat("\nSaved analysis_panel.csv and summary_stats.csv\n")
