## 04_robustness.R — Robustness checks and placebo tests
## apep_0840: Competing News IV and Swiss Referendum Turnout

source("00_packages.R")

cat("Loading analysis panel and results...\n")
panel <- fread("../data/analysis_panel.csv")
panel[, votedate := as.Date(votedate)]
load("../data/regression_results.RData")

panel_clean <- panel[!is.na(salience_score) & !is.na(turnout_pct)]
panel_clean[, lang_year := paste0(lang_region, "_", vote_year)]

# Recompute item salience
vote_avg_turnout <- panel_clean[, .(item_avg_turnout = mean(turnout_pct, na.rm = TRUE)),
                                 by = .(votedate, name)]
panel_clean <- merge(panel_clean, vote_avg_turnout, by = c("votedate", "name"), all.x = TRUE)
panel_clean[, high_salience := item_avg_turnout >= median(item_avg_turnout, na.rm = TRUE)]

# ============================================================================
# ROBUSTNESS 1: 14-day pre-vote window
# ============================================================================

cat("\n=== 14-day window ===\n")
panel_clean[, salience_14d_std := (salience_score_14d - mean(salience_score_14d, na.rm = TRUE)) /
              sd(salience_score_14d, na.rm = TRUE)]

rob_14d <- feols(turnout_pct ~ salience_14d_std | bfs_id + votedate,
                 data = panel_clean[!is.na(salience_14d_std)],
                 vcov = ~votedate + lang_region)
etable(rob_14d)

# ============================================================================
# ROBUSTNESS 2: Placebo — swap French and German salience
# (If French municipalities get German salience and vice versa, effect should vanish)
# ============================================================================

cat("\n=== Placebo: Swapped language salience ===\n")

# Merge the other language's salience as placebo
disasters <- fread("../data/disaster_instrument.csv")
dis_7d <- disasters[window == "7day"]

# Create placebo: for French municipalities use German salience, vice versa
dis_placebo <- rbind(
  dis_7d[source_lang == "de", .(vote_date, source_lang_orig = "de",
                                 placebo_lang = "fr",
                                 placebo_salience = salience_score)],
  dis_7d[source_lang == "fr", .(vote_date, source_lang_orig = "fr",
                                 placebo_lang = "de",
                                 placebo_salience = salience_score)]
)

panel_placebo <- merge(
  panel_clean,
  dis_placebo[, .(vote_date = as.Date(vote_date), lang_region = placebo_lang,
                  placebo_salience)],
  by.x = c("votedate", "lang_region"),
  by.y = c("vote_date", "lang_region"),
  all.x = TRUE
)

panel_placebo[, placebo_std := (placebo_salience - mean(placebo_salience, na.rm = TRUE)) /
                sd(placebo_salience, na.rm = TRUE)]

rob_placebo <- feols(turnout_pct ~ placebo_std | bfs_id + votedate,
                     data = panel_placebo[!is.na(placebo_std)],
                     vcov = ~votedate + lang_region)
cat("Placebo (wrong language salience → turnout):\n")
etable(rob_placebo)

# ============================================================================
# ROBUSTNESS 3: French vs German separately
# ============================================================================

cat("\n=== By language region (muni FE only — salience constant within lang×date) ===\n")
rob_de <- feols(turnout_pct ~ salience_std | bfs_id,
                data = panel_clean[lang_region == "de"],
                vcov = ~votedate)
rob_fr <- feols(turnout_pct ~ salience_std | bfs_id,
                data = panel_clean[lang_region == "fr"],
                vcov = ~votedate)

etable(rob_de, rob_fr, headers = c("German", "French"))

# ============================================================================
# ROBUSTNESS 4: Exclude COVID period (2020-2021)
# ============================================================================

cat("\n=== Excluding COVID period ===\n")
rob_nocovid <- feols(turnout_pct ~ salience_std | bfs_id + votedate,
                     data = panel_clean[vote_year < 2020 | vote_year > 2021],
                     vcov = ~votedate + lang_region)
etable(rob_nocovid)

# ============================================================================
# Save robustness results
# ============================================================================

save(rob_14d, rob_placebo, rob_de, rob_fr, rob_nocovid,
     file = "../data/robustness_results.RData")
cat("\nSaved robustness_results.RData\n")
