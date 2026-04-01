# =============================================================================
# 03_main_analysis.R — Main estimation
# apep_1243: Municipal Consolidation and Residential Sorting in Switzerland
# =============================================================================

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, current_bfs := as.factor(current_bfs)]
panel[, cohort := fifelse(ever_merged, first_merger_year, 10000L)]

outcomes <- c(
  foreign_share = "Foreign population share",
  log_foreign = "Log foreign population",
  foreign_growth = "Foreign population growth rate",
  foreign_share_change = "Change in foreign population share"
)

main_models <- list()
att_summary <- list()
event_studies <- list()

for (outcome in names(outcomes)) {
  cat("\n=== Outcome:", outcomes[[outcome]], "===\n")

  m_twfe <- feols(
    as.formula(sprintf("%s ~ post_merger | current_bfs + year", outcome)),
    data = panel,
    cluster = ~current_bfs
  )

  m_twfe_cy <- feols(
    as.formula(sprintf("%s ~ post_merger | current_bfs + canton^year", outcome)),
    data = panel,
    cluster = ~current_bfs
  )

  m_sa <- feols(
    as.formula(sprintf("%s ~ sunab(cohort, year) | current_bfs + year", outcome)),
    data = panel,
    cluster = ~current_bfs
  )
  sa_agg <- summary(m_sa, agg = "ATT")

  ct <- summary(m_sa)$coeftable
  es_dt <- data.table(
    term = rownames(ct),
    estimate = ct[, "Estimate"],
    se = ct[, "Std. Error"]
  )
  es_dt[, rel_year := suppressWarnings(as.integer(gsub(".*::(-?[0-9]+)$", "\\1", term)))]
  es_dt <- es_dt[!is.na(rel_year)][order(rel_year)]
  es_dt[, outcome := outcome]

  main_models[[paste0(outcome, "_twfe")]] <- m_twfe
  main_models[[paste0(outcome, "_twfe_cy")]] <- m_twfe_cy
  main_models[[paste0(outcome, "_sa")]] <- m_sa

  att_summary[[outcome]] <- data.table(
    outcome = outcome,
    label = outcomes[[outcome]],
    model = c("TWFE", "TWFE_CY", "SUNAB_ATT"),
    estimate = c(
      coef(m_twfe)["post_mergerTRUE"],
      coef(m_twfe_cy)["post_mergerTRUE"],
      coef(sa_agg)["ATT"]
    ),
    se = c(
      summary(m_twfe)$coeftable["post_mergerTRUE", "Std. Error"],
      summary(m_twfe_cy)$coeftable["post_mergerTRUE", "Std. Error"],
      se(sa_agg)["ATT"]
    )
  )

  event_studies[[outcome]] <- es_dt
}

att_summary_dt <- rbindlist(att_summary, fill = TRUE)
event_study_dt <- rbindlist(event_studies, fill = TRUE)

fwrite(att_summary_dt, file.path(DATA_DIR, "att_summary.csv"))
fwrite(event_study_dt, file.path(DATA_DIR, "event_study.csv"))
saveRDS(main_models, file.path(DATA_DIR, "main_results.rds"))

cat("\n=== Pre-trend check for primary outcome ===\n")
primary_es <- event_study_dt[outcome == "foreign_share" & rel_year < 0]
cat("Mean pre-treatment coefficient:", round(mean(primary_es$estimate, na.rm = TRUE), 4), "\n")

cat("\nMain analysis complete.\n")
