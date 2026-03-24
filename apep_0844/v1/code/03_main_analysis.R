# 03_main_analysis.R — Continuous treatment DiD with event study
# apep_0844: State Disinvestment and Enrollment Composition
#
# Design: States that cut per-student HE appropriations more during the
# Great Recession (2008-2012) serve as "treated" with continuous intensity.
# Event study traces out differential trends by cut intensity.

source("00_packages.R")

panel <- fread("../data/panel.csv")
cat("Panel loaded:", nrow(panel), "rows,", uniqueN(panel$UNITID), "institutions\n")

# ============================================================================
# Sample restrictions
# ============================================================================
panel <- panel[nchar(state) == 2 &
               !state %in% c("AS", "GU", "MH", "FM", "MP", "PW", "PR", "VI")]

# CPI deflator (base: 2022)
cpi <- data.table(
  year = 2004:2022,
  cpi = c(188.9, 195.3, 201.6, 207.3, 215.3, 214.5, 218.1,
          224.9, 229.6, 233.0, 236.7, 237.0, 240.0, 245.1, 251.1,
          255.7, 251.7, 258.8, 292.7)
)
cpi[, deflator := max(cpi) / cpi]
panel <- merge(panel, cpi, by = "year", all.x = TRUE)

# Real variables
panel[, real_tuition := tuition_instate * deflator]
panel[, real_approp_ps := approp_per_student * deflator]
panel[, log_real_tuition := log(pmax(real_tuition, 1))]
panel[, log_real_approp_ps := log(pmax(real_approp_ps, 1))]

# ============================================================================
# Construct treatment intensity: state-level appropriation change
# ============================================================================
# Pre-recession peak (2007-2008 average) vs trough (2011-2012 average)
state_pre <- panel[year %in% 2007:2008 & !is.na(real_approp_ps) & real_approp_ps > 0,
                   .(pre_approp = mean(real_approp_ps, na.rm = TRUE)),
                   by = state]
state_post <- panel[year %in% 2011:2012 & !is.na(real_approp_ps) & real_approp_ps > 0,
                    .(post_approp = mean(real_approp_ps, na.rm = TRUE)),
                    by = state]
state_cut <- merge(state_pre, state_post, by = "state")
state_cut[, cut_pct := (post_approp - pre_approp) / pre_approp]
state_cut[, cut_intensity := -cut_pct]  # Positive = bigger cut

cat("\n=== State-level appropriation cuts (2007/08 → 2011/12) ===\n")
cat("  Mean cut:", round(mean(state_cut$cut_pct, na.rm = TRUE) * 100, 1), "%\n")
cat("  Median cut:", round(median(state_cut$cut_pct, na.rm = TRUE) * 100, 1), "%\n")
cat("  SD:", round(sd(state_cut$cut_pct, na.rm = TRUE) * 100, 1), "pp\n")
cat("  Range:", round(min(state_cut$cut_pct, na.rm = TRUE) * 100, 1), "to",
    round(max(state_cut$cut_pct, na.rm = TRUE) * 100, 1), "%\n")
cat("  States with >20% cut:", sum(state_cut$cut_pct < -0.20, na.rm = TRUE), "\n")
cat("  States with >30% cut:", sum(state_cut$cut_pct < -0.30, na.rm = TRUE), "\n")

panel <- merge(panel, state_cut[, .(state, cut_intensity)], by = "state", all.x = TRUE)

# ============================================================================
# Analysis sample
# ============================================================================
analysis <- panel[!is.na(real_tuition) & !is.na(real_approp_ps) &
                  real_approp_ps > 0 & real_tuition > 0 &
                  !is.na(EFTOTLT) & EFTOTLT > 100 &
                  !is.na(cut_intensity) &
                  year >= 2004]

cat("\nAnalysis sample:", nrow(analysis), "obs,",
    uniqueN(analysis$UNITID), "institutions,",
    uniqueN(analysis$state), "states\n")

# ============================================================================
# Table 1: Summary statistics by cut intensity tercile
# ============================================================================
cat("\n=== Summary Statistics ===\n")

# Classify states into terciles of cut intensity
tercile_breaks <- quantile(state_cut$cut_intensity, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE)
state_cut[, tercile := cut(cut_intensity, breaks = tercile_breaks,
                           labels = c("Low cut", "Medium cut", "High cut"),
                           include.lowest = TRUE)]
analysis <- merge(analysis, state_cut[, .(state, tercile)], by = "state", all.x = TRUE)

# Pre-recession means by tercile
pre_summary <- analysis[year %in% 2004:2008, .(
  tuition = mean(real_tuition, na.rm = TRUE),
  approp_ps = mean(real_approp_ps, na.rm = TRUE),
  pell_share = mean(pell_share, na.rm = TRUE),
  enrollment = mean(EFTOTLT, na.rm = TRUE),
  black_share = mean(black_share, na.rm = TRUE),
  hispanic_share = mean(hispanic_share, na.rm = TRUE),
  nonres_share = mean(nonres_share, na.rm = TRUE),
  n_inst = uniqueN(UNITID)
), by = tercile]
cat("\nPre-Recession (2004-2008) by Cut Tercile:\n")
print(pre_summary)

# ============================================================================
# DiD: Continuous treatment × post
# ============================================================================
cat("\n=== Continuous Treatment DiD ===\n")

# Post indicator: recession begins 2009
analysis[, post := as.integer(year >= 2009)]

# Main specification: Y_it = α_i + δ_t + β(cut_intensity × post) + ε_it
# 1. Tuition
did_tuition <- feols(log_real_tuition ~ cut_intensity:post |
                     UNITID + year,
                     data = analysis,
                     cluster = ~state)
cat("DiD — log tuition:\n")
print(summary(did_tuition))

# 2. Pell share
did_pell <- feols(pell_share ~ cut_intensity:post |
                  UNITID + year,
                  data = analysis[!is.na(pell_share)],
                  cluster = ~state)
cat("\nDiD — Pell share:\n")
print(summary(did_pell))

# 3. Nonresident share
did_nonres <- feols(nonres_share ~ cut_intensity:post |
                    UNITID + year,
                    data = analysis[!is.na(nonres_share)],
                    cluster = ~state)

# 4. Total enrollment
did_enroll <- feols(log_enrollment ~ cut_intensity:post |
                    UNITID + year,
                    data = analysis,
                    cluster = ~state)

# 5. Minority share (Black + Hispanic)
did_minority <- feols(minority_share ~ cut_intensity:post |
                      UNITID + year,
                      data = analysis[!is.na(minority_share)],
                      cluster = ~state)

# ============================================================================
# Event Study: trace out dynamics
# ============================================================================
cat("\n=== Event Study ===\n")

# Reference year: 2008 (last pre-recession year)
analysis[, year_f := factor(year)]
analysis[, year_f := relevel(year_f, ref = "2008")]

# Event study for each outcome
es_tuition <- feols(log_real_tuition ~ i(year_f, cut_intensity, ref = "2008") |
                    UNITID + year,
                    data = analysis,
                    cluster = ~state)

es_pell <- feols(pell_share ~ i(year_f, cut_intensity, ref = "2008") |
                 UNITID + year,
                 data = analysis[!is.na(pell_share)],
                 cluster = ~state)

es_nonres <- feols(nonres_share ~ i(year_f, cut_intensity, ref = "2008") |
                   UNITID + year,
                   data = analysis[!is.na(nonres_share)],
                   cluster = ~state)

es_enroll <- feols(log_enrollment ~ i(year_f, cut_intensity, ref = "2008") |
                   UNITID + year,
                   data = analysis,
                   cluster = ~state)

es_minority <- feols(minority_share ~ i(year_f, cut_intensity, ref = "2008") |
                     UNITID + year,
                     data = analysis[!is.na(minority_share)],
                     cluster = ~state)

# Print event study coefficients for key outcomes
cat("\nEvent study — Tuition:\n")
es_t <- coeftable(es_tuition)
for (i in 1:nrow(es_t)) {
  cat(sprintf("  %s: %+.4f (%.4f) %s\n",
              rownames(es_t)[i], es_t[i,1], es_t[i,2],
              ifelse(es_t[i,4] < 0.05, "**", ifelse(es_t[i,4] < 0.1, "*", ""))))
}

cat("\nEvent study — Pell share:\n")
es_p <- coeftable(es_pell)
for (i in 1:nrow(es_p)) {
  cat(sprintf("  %s: %+.4f (%.4f) %s\n",
              rownames(es_p)[i], es_p[i,1], es_p[i,2],
              ifelse(es_p[i,4] < 0.05, "**", ifelse(es_p[i,4] < 0.1, "*", ""))))
}

cat("\nEvent study — Nonresident share:\n")
es_n <- coeftable(es_nonres)
for (i in 1:nrow(es_n)) {
  cat(sprintf("  %s: %+.4f (%.4f) %s\n",
              rownames(es_n)[i], es_n[i,1], es_n[i,2],
              ifelse(es_n[i,4] < 0.05, "**", ifelse(es_n[i,4] < 0.1, "*", ""))))
}

# ============================================================================
# Save results
# ============================================================================
results <- list(
  did_tuition = did_tuition,
  did_pell = did_pell,
  did_nonres = did_nonres,
  did_enroll = did_enroll,
  did_minority = did_minority,
  es_tuition = es_tuition,
  es_pell = es_pell,
  es_nonres = es_nonres,
  es_enroll = es_enroll,
  es_minority = es_minority,
  state_cut = state_cut
)
saveRDS(results, "../data/main_results.rds")

# KEY RESULTS SUMMARY
cat("\n=== KEY RESULTS SUMMARY ===\n")
cat("  Design: Continuous treatment DiD (cut intensity × post-2009)\n")
cat("  Observations:", nrow(analysis), "\n")
cat("  Institutions:", uniqueN(analysis$UNITID), "\n")
cat("  States:", uniqueN(analysis$state), "\n\n")
fmt <- function(m) {
  ct <- coeftable(m)
  sprintf("%+.4f (%.4f) p=%.3f", ct[1,1], ct[1,2], ct[1,4])
}
cat("  Log tuition:     ", fmt(did_tuition), "\n")
cat("  Pell share:      ", fmt(did_pell), "\n")
cat("  Nonres share:    ", fmt(did_nonres), "\n")
cat("  Log enrollment:  ", fmt(did_enroll), "\n")
cat("  Minority share:  ", fmt(did_minority), "\n")

# Update diagnostics
n_high_cut <- sum(state_cut$cut_intensity > median(state_cut$cut_intensity, na.rm = TRUE),
                  na.rm = TRUE)
diag <- list(
  n_treated = n_high_cut,
  n_pre = length(2004:2008),
  n_obs = nrow(analysis),
  n_institutions = uniqueN(analysis$UNITID),
  n_states = uniqueN(analysis$state)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
