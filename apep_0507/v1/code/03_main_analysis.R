# =============================================================================
# 03_main_analysis.R — Main DiD estimation
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

source("00_packages.R")

# =============================================================================
# STEP 1: Load analysis panel
# =============================================================================

cat("\n=== Loading analysis panel ===\n")
panel <- fread(file.path(DATA_DIR, "panel_vote.csv"))
annual <- fread(file.path(DATA_DIR, "panel_annual.csv"))

cat("  Vote-level panel: ", nrow(panel), " obs, ",
    uniqueN(panel$current_bfs), " municipalities\n")
cat("  Annual panel: ", nrow(annual), " obs, ",
    uniqueN(annual$current_bfs), " municipalities\n")

# Ensure proper types
panel[, vote_date := as.Date(vote_date)]
annual[, current_bfs := as.factor(current_bfs)]

# Create vote-date string for FE (matches data frequency)
panel[, vdate := as.character(vote_date)]

# =============================================================================
# STEP 2: Two-way fixed effects (TWFE) — Baseline
# =============================================================================

cat("\n=== TWFE Baseline ===\n")

# Model 1: Municipality + vote-date FE
m1 <- feols(turnout_pct ~ post_merger | current_bfs + vdate,
            data = panel, cluster = ~current_bfs)

# Model 2: Municipality + canton×vote-date FE
m2 <- feols(turnout_pct ~ post_merger | current_bfs + canton^vdate,
            data = panel, cluster = ~current_bfs)

# Model 3: With population control
m3 <- feols(turnout_pct ~ post_merger + log(population + 1) |
              current_bfs + canton^vdate,
            data = panel[population > 0], cluster = ~current_bfs)

cat("  TWFE results:\n")
cat("  Model 1 (muni + year FE): ", round(coef(m1)["post_mergerTRUE"], 3), "\n")
cat("  Model 2 (muni + canton*year FE): ", round(coef(m2)["post_mergerTRUE"], 3), "\n")
cat("  Model 3 (+ log pop): ", round(coef(m3)["post_mergerTRUE"], 3), "\n")

# =============================================================================
# STEP 3: Sun-Abraham decomposition (fixest::sunab)
# =============================================================================

cat("\n=== Sun-Abraham Decomposition ===\n")

# Create cohort variable for sunab: first_merger_year for treated, large number for never-treated
panel[, cohort := fifelse(ever_merged, first_merger_year, 10000L)]

# sunab requires numeric time and cohort (event time defined in years)
# Vote-date FE absorbs date-specific shocks; event time is year-level
sa1 <- feols(turnout_pct ~ sunab(cohort, vote_year) | current_bfs + vdate,
             data = panel, cluster = ~current_bfs)

sa2 <- feols(turnout_pct ~ sunab(cohort, vote_year) | current_bfs + canton^vdate,
             data = panel, cluster = ~current_bfs)

# Extract aggregated ATT using summary(..., agg = "ATT")
sa1_agg <- summary(sa1, agg = "ATT")
sa2_agg <- summary(sa2, agg = "ATT")
cat("  Sun-Abraham ATT (muni + year): ", round(coef(sa1_agg)["ATT"], 3), "\n")
cat("  Sun-Abraham ATT (muni + canton*year): ", round(coef(sa2_agg)["ATT"], 3), "\n")

# =============================================================================
# STEP 4: Callaway-Sant'Anna (2021)
# =============================================================================

cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for CS-DiD
cs_data <- copy(annual)
cs_data[, id := as.integer(as.factor(current_bfs))]
cs_data[, gvar := as.integer(g)]  # 0 for never-treated

# Ensure balanced-ish panel: keep years with decent coverage
year_counts <- cs_data[, .N, by = vote_year][order(vote_year)]
cat("  Year coverage:\n")
print(year_counts)

# CS-DiD with never-treated as control
tryCatch({
  cs_out <- att_gt(
    yname = "turnout_pct",
    tname = "vote_year",
    idname = "id",
    gname = "gvar",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "varying"
  )

  cat("  CS-DiD group-time ATTs computed\n")
  cat("  Number of group-time ATTs: ", length(cs_out$att), "\n")

  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("  Overall ATT: ", round(cs_agg$overall.att, 3),
      " (SE: ", round(cs_agg$overall.se, 3), ")\n")

  # Aggregate to event-time
  cs_es <- aggte(cs_out, type = "dynamic", min_e = -10, max_e = 15)
  cat("  Event-study ATTs computed (e = -10 to 15)\n")

  # Aggregate by cohort group
  cs_group <- aggte(cs_out, type = "group")
  cat("  Group-level ATTs computed\n")

  # Save results
  saveRDS(cs_out, file.path(DATA_DIR, "cs_did_raw.rds"))
  saveRDS(cs_agg, file.path(DATA_DIR, "cs_agg.rds"))
  saveRDS(cs_es, file.path(DATA_DIR, "cs_es.rds"))
  saveRDS(cs_group, file.path(DATA_DIR, "cs_group.rds"))
}, error = function(e) {
  cat("  CS-DiD failed: ", e$message, "\n")
  cat("  Falling back to fixest sunab only.\n")
})

# =============================================================================
# STEP 5: Event-study plot data from Sun-Abraham
# =============================================================================

cat("\n=== Event-study coefficients ===\n")

# Extract event-study coefficients from sunab
# sunab coefficients are named like "cohort::rel_year"
ct <- summary(sa2)$coeftable
es_coefs <- data.table(
  term = rownames(ct),
  estimate = ct[, "Estimate"],
  se = ct[, "Std. Error"],
  tstat = ct[, "t value"],
  pvalue = ct[, "Pr(>|t|)"]
)

# Parse event time from term names (format: "cohort::rel_year" or just "rel_year")
es_coefs[, rel_year := as.integer(gsub(".*::(-?[0-9]+)$", "\\1", term))]
es_coefs <- es_coefs[!is.na(rel_year)]

# Average across cohorts for same rel_year
es_agg <- es_coefs[, .(estimate = mean(estimate), se = mean(se)),
                   by = rel_year][order(rel_year)]

cat("  Event-study coefficients: ", nrow(es_agg), " periods\n")

fwrite(es_agg, file.path(DATA_DIR, "event_study_coefs.csv"))

# =============================================================================
# STEP 6: Pre-trend test
# =============================================================================

cat("\n=== Pre-trend tests ===\n")

# F-test for joint significance of pre-treatment coefficients
pre_terms <- es_coefs[rel_year < 0, term]
if (length(pre_terms) > 0) {
  tryCatch({
    wald_test <- wald(sa2, keep = pre_terms)
    cat("  Pre-trend Wald test p-value: ", round(wald_test$p, 4), "\n")
    cat("  Pre-trend F-stat: ", round(wald_test$stat, 2), "\n")
  }, error = function(e) {
    cat("  Wald test error: ", e$message, "\n")
    # Manual pre-trend test: average pre-treatment coefficient
    pre_avg <- mean(es_coefs[rel_year < 0, estimate])
    cat("  Mean pre-treatment coefficient: ", round(pre_avg, 3), "\n")
  })
}

# =============================================================================
# STEP 7: Save TWFE results for tables
# =============================================================================

cat("\n=== Saving results ===\n")

results_list <- list(
  twfe_1 = m1,
  twfe_2 = m2,
  twfe_3 = m3,
  sunab_1 = sa1,
  sunab_2 = sa2
)
saveRDS(results_list, file.path(DATA_DIR, "main_results.rds"))

# Save Sun-Abraham ATT summaries as simple data (avoids memory issues when loading)
sa_summary <- data.table(
  model = c("SA (muni + year FE)", "SA (muni + canton*year FE)"),
  att = c(coef(sa1_agg)["ATT"], coef(sa2_agg)["ATT"]),
  se = c(se(sa1_agg)["ATT"], se(sa2_agg)["ATT"]),
  n = c(sa1$nobs, sa2$nobs),
  wr2 = c(fitstat(sa1, "wr2")[[1]], fitstat(sa2, "wr2")[[1]])
)
fwrite(sa_summary, file.path(DATA_DIR, "sunab_att_summary.csv"))
cat("  Saved sunab_att_summary.csv\n")

# Summary table
cat("\n=== Results Summary ===\n")
cat("  TWFE models:\n")
etable(m1, m2, m3)
cat("\n  Sun-Abraham aggregated ATTs:\n")
etable(sa1_agg, sa2_agg, headers = c("SA (1)", "SA (2)"))

cat("\nMain analysis complete.\n")
