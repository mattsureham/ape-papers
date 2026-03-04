# =============================================================================
# 06_tables.R — All tables
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

source("00_packages.R")

# Helper: extract tabular content from etable (strip table environment)
extract_tabular <- function(tex_lines) {
  start <- grep("\\\\begin\\{tabular\\}", tex_lines)[1]
  end <- grep("\\\\end\\{tabular\\}", tex_lines)
  end <- end[length(end)]
  if (is.na(start) || is.na(end)) return(tex_lines)
  tex_lines[start:end]
}

# =============================================================================
# Load data and results
# =============================================================================

panel <- fread(file.path(DATA_DIR, "panel_vote.csv"))
annual <- fread(file.path(DATA_DIR, "panel_annual.csv"))
panel[, vote_date := as.Date(vote_date)]
panel[, cohort := fifelse(ever_merged, first_merger_year, 10000L)]

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

rob_file <- file.path(DATA_DIR, "robustness_results.rds")
if (file.exists(rob_file)) {
  rob <- readRDS(rob_file)
}

# =============================================================================
# Table 1: Summary statistics (bare tabular — paper.tex wraps in table float)
# =============================================================================

cat("\n=== Table 1: Summary statistics ===\n")

summ_all <- panel[, .(
  N = .N,
  N_muni = uniqueN(current_bfs),
  N_votes = uniqueN(vote_date),
  Mean_turnout = round(mean(turnout_pct, na.rm = TRUE), 1),
  SD_turnout = round(sd(turnout_pct, na.rm = TRUE), 1),
  Mean_eligible = round(mean(eligible_voters, na.rm = TRUE), 0),
  Mean_pop = round(mean(population, na.rm = TRUE), 0)
)]

summ_by_group <- panel[, .(
  N = .N,
  N_muni = uniqueN(current_bfs),
  Mean_turnout = round(mean(turnout_pct, na.rm = TRUE), 1),
  SD_turnout = round(sd(turnout_pct, na.rm = TRUE), 1),
  Mean_eligible = round(mean(eligible_voters, na.rm = TRUE), 0),
  Mean_pop = round(mean(population, na.rm = TRUE), 0)
), by = .(Group = fifelse(ever_merged, "Eventually merged", "Never merged"))]

summ_treated <- panel[ever_merged == TRUE, .(
  N = .N,
  N_muni = uniqueN(current_bfs),
  Mean_turnout = round(mean(turnout_pct, na.rm = TRUE), 1),
  SD_turnout = round(sd(turnout_pct, na.rm = TRUE), 1),
  Mean_eligible = round(mean(eligible_voters, na.rm = TRUE), 0),
  Mean_pop = round(mean(population, na.rm = TRUE), 0)
), by = .(Group = fifelse(post_merger, "Treated (post)", "Treated (pre)"))]

summ_table <- rbind(
  data.table(Group = "Full sample", summ_all[, -c("N_votes")]),
  summ_by_group,
  summ_treated,
  fill = TRUE
)

cat("  Summary statistics:\n")
print(summ_table)

# Bare tabular only (no \begin{table})
summ_tex <- kable(summ_table, format = "latex", booktabs = TRUE,
                  col.names = c("Sample", "Obs.", "Municipalities",
                                "Mean turnout", "SD turnout",
                                "Mean eligible", "Mean pop."))
writeLines(summ_tex, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# =============================================================================
# Table 2: Main TWFE results (bare tabular)
# =============================================================================

cat("\n=== Table 2: Main results ===\n")

# Capture etable output, strip table environment
twfe_full <- etable(
  results$twfe_1, results$twfe_2, results$twfe_3,
  headers = c("(1)", "(2)", "(3)"),
  se.below = TRUE,
  fitstat = c("n", "wr2"),
  depvar = FALSE,
  dict = c(
    "post_mergerTRUE" = "Post-merger",
    "log(population + 1)" = "Log(population)",
    "current_bfs" = "Municipality",
    "vdate" = "Vote date",
    "canton" = "Canton"
  ),
  tex = TRUE
)
twfe_lines <- extract_tabular(twfe_full)
writeLines(twfe_lines, file.path(TABLE_DIR, "tab2_main_results.tex"))
cat("  Saved tab2_main_results.tex\n")

# =============================================================================
# Table 2b: Sun-Abraham ATT (bare tabular)
# =============================================================================

sa_summ_file <- file.path(DATA_DIR, "sunab_att_summary.csv")
if (file.exists(sa_summ_file)) {
  sa_summ <- fread(sa_summ_file)
  sa_table <- data.table(
    ` ` = c("ATT", "", "Observations", "Within R$^2$"),
    `(4)` = c(sprintf("%.3f***", sa_summ$att[1]),
              sprintf("(%.3f)", sa_summ$se[1]),
              format(sa_summ$n[1], big.mark = ","),
              sprintf("%.4f", sa_summ$wr2[1])),
    `(5)` = c(sprintf("%.3f***", sa_summ$att[2]),
              sprintf("(%.3f)", sa_summ$se[2]),
              format(sa_summ$n[2], big.mark = ","),
              sprintf("%.4f", sa_summ$wr2[2]))
  )
  sa_tex <- kable(sa_table, format = "latex", booktabs = TRUE, escape = FALSE)
  writeLines(sa_tex, file.path(TABLE_DIR, "tab2b_sunab_results.tex"))
  cat("  Saved tab2b_sunab_results.tex\n")
} else {
  cat("  WARNING: sunab_att_summary.csv not found\n")
}

# =============================================================================
# Table 3: CS-DiD results (bare tabular)
# =============================================================================

cat("\n=== Table 3: CS-DiD results ===\n")

cs_agg_file <- file.path(DATA_DIR, "cs_agg.rds")
if (file.exists(cs_agg_file)) {
  cs_agg <- readRDS(cs_agg_file)

  # Count observations used in CS-DiD (from annual panel)
  cs_n <- nrow(annual[!is.na(turnout_pct)])

  cs_table <- data.table(
    Estimator = c("Overall ATT", "Confidence interval", "Observations"),
    Estimate = c(
      sprintf("%.3f", cs_agg$overall.att),
      sprintf("[%.3f, %.3f]",
              cs_agg$overall.att - 1.96 * cs_agg$overall.se,
              cs_agg$overall.att + 1.96 * cs_agg$overall.se),
      format(cs_n, big.mark = ",")
    ),
    SE = c(sprintf("(%.3f)", cs_agg$overall.se), "", "")
  )

  cs_tex <- kable(cs_table, format = "latex", booktabs = TRUE)
  writeLines(cs_tex, file.path(TABLE_DIR, "tab3_cs_did.tex"))
  cat("  Saved tab3_cs_did.tex\n")
}

# =============================================================================
# Table 4: Robustness checks (bare tabular)
# =============================================================================

cat("\n=== Table 4: Robustness ===\n")

if (exists("rob")) {
  rob_full <- etable(
    rob$canton_cluster, rob$twoway_cluster,
    rob$post2000, rob$german, rob$latin,
    headers = c("Canton SE", "Two-way SE", "Post-2000", "German CH", "Latin CH"),
    se.below = TRUE,
    fitstat = c("n", "wr2"),
    depvar = FALSE,
    dict = c(
      "post_mergerTRUE" = "Post-merger",
      "current_bfs" = "Municipality",
      "vdate" = "Vote date",
      "canton" = "Canton"
    ),
    tex = TRUE
  )
  rob_lines <- extract_tabular(rob_full)
  writeLines(rob_lines, file.path(TABLE_DIR, "tab4_robustness.tex"))
  cat("  Saved tab4_robustness.tex\n")
}

# =============================================================================
# Table 5: Heterogeneity (bare tabular)
# =============================================================================

cat("\n=== Table 5: Heterogeneity ===\n")

if (exists("rob")) {
  het_full <- etable(
    rob$het_size, rob$het_pop, rob$dynamic,
    headers = c("Merger size", "Population", "Dynamic"),
    se.below = TRUE,
    fitstat = c("n", "wr2"),
    depvar = FALSE,
    dict = c(
      "post_mergerTRUE" = "Post-merger",
      "large_mergerTRUE" = "Large merger ($\\geq$ 3)",
      "post_mergerTRUE:large_mergerTRUE" = "Post-merger $\\times$ Large",
      "small_muniTRUE" = "Small municipality",
      "post_mergerTRUE:small_muniTRUE" = "Post-merger $\\times$ Small",
      "event_binimmediate" = "Immediate (0--2 years)",
      "event_binmedium_run" = "Medium-run (3--5 years)",
      "event_binlong_run" = "Long-run (6+ years)",
      "current_bfs" = "Municipality",
      "vdate" = "Vote date",
      "canton" = "Canton"
    ),
    tex = TRUE
  )
  het_lines <- extract_tabular(het_full)
  writeLines(het_lines, file.path(TABLE_DIR, "tab5_heterogeneity.tex"))
  cat("  Saved tab5_heterogeneity.tex\n")
}

cat("\nAll tables generated.\n")
