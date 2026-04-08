# 05_tables.R — Generate LaTeX tables for apep_1426
# TV News Amplification and Workplace Safety Deterrence

source("./code/00_packages.R")

DATA_DIR <- "./data"
TABLE_DIR <- "./tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, week := as.Date(week)]

# Load results
main_results <- jsonlite::fromJSON(file.path(DATA_DIR, "main_results.json"))
rob_results <- jsonlite::fromJSON(file.path(DATA_DIR, "robustness_results.json"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

summ_vars <- panel[, .(
  Variable = c("Safety Coverage (% airtime)", "Safety Segments (count)",
               "Stations Covering Safety", "Mega-Event Coverage (% airtime)",
               "Olympics Week", "Super Bowl Week",
               "Pre-Scheduled Event Week"),
  Mean = c(mean(total_safety_coverage), mean(total_safety_segments),
           mean(n_stations_covering), mean(total_mega_events),
           mean(olympics_week), mean(superbowl_week),
           mean(prescheduled_event)),
  SD = c(sd(total_safety_coverage), sd(total_safety_segments),
         sd(n_stations_covering), sd(total_mega_events),
         sd(olympics_week), sd(superbowl_week),
         sd(prescheduled_event)),
  Min = c(min(total_safety_coverage), min(total_safety_segments),
          min(n_stations_covering), min(total_mega_events),
          min(olympics_week), min(superbowl_week),
          min(prescheduled_event)),
  Max = c(max(total_safety_coverage), max(total_safety_segments),
          max(n_stations_covering), max(total_mega_events),
          max(olympics_week), max(superbowl_week),
          max(prescheduled_event))
)]

# Format numbers
for (col in c("Mean", "SD", "Min", "Max")) {
  summ_vars[, (col) := sprintf("%.3f", get(col))]
}

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: TV News Coverage, 2015--2023}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  paste0("\\emph{Panel A: TV News Coverage} & & & & \\\\\n"),
  paste(apply(summ_vars[1:3], 1, function(r) {
    paste(r, collapse = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "[0.5em]\n",
  paste0("\\emph{Panel B: Competing News (Instrument)} & & & & \\\\\n"),
  paste(apply(summ_vars[4:7], 1, function(r) {
    paste(r, collapse = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\n",
  sprintf("Observations & \\multicolumn{4}{c}{%d weeks} \\\\\n", nrow(panel)),
  sprintf("Period & \\multicolumn{4}{c}{%s -- %s} \\\\\n",
          format(min(panel$week), "%B %Y"), format(max(panel$week), "%B %Y")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{flushleft}\\small\n",
  "Notes: Unit of observation is the week. Safety Coverage measures the percentage of total TV airtime devoted to workplace safety topics across six major networks (CNN, Fox News, MSNBC, CNBC, BBC News, Fox Business). Data from GDELT Television Explorer API.\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("  Table 1 saved.\n")

# ============================================================
# Table 2: First Stage — Mega-Events Crowd Out Safety Coverage
# ============================================================
cat("=== Table 2: First Stage ===\n")

fs1 <- feols(total_safety_coverage ~ prescheduled_event | year + quarter,
             data = panel)
fs2 <- feols(total_safety_coverage ~ olympics_week | year + quarter,
             data = panel)
fs3 <- feols(total_safety_coverage ~ superbowl_week | year + quarter,
             data = panel)
fs4 <- feols(total_safety_coverage ~ olympics_week + superbowl_week |
               year + quarter, data = panel)
fs5 <- feols(total_safety_coverage ~ total_mega_events | year + quarter,
             data = panel)

tab2_models <- list(fs1, fs2, fs3, fs4, fs5)
tab2_file <- file.path(TABLE_DIR, "tab2_first_stage.tex")

etable(tab2_models,
       file = tab2_file,
       title = "First Stage: Pre-Scheduled Events and TV Safety Coverage",
       label = "tab:first_stage",
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       dict = c(prescheduled_event = "Any Pre-Scheduled Event",
                olympics_week = "Olympics Week",
                superbowl_week = "Super Bowl Week",
                total_mega_events = "Mega-Event Coverage"),
       fitstat = c("n", "r2", "f"),
       se.below = TRUE,
       notes = "Notes: Dependent variable is weekly safety coverage (\\% of airtime). Pre-scheduled events include Olympics (Rio 2016, PyeongChang 2018, Tokyo 2021, Beijing 2022) and Super Bowl (2015--2023). Year and quarter fixed effects included. Standard errors in parentheses.",
       style.tex = style.tex("aer"))

cat("  Table 2 saved.\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("=== Table 3: Event Study ===\n")

es_file <- file.path(DATA_DIR, "event_study_coefs.csv")
if (file.exists(es_file)) {
  es_coefs <- fread(es_file)
  es_coefs[, sig := fifelse(abs(estimate/se) > 1.96, "*", "")]

  tab3_tex <- paste0(
    "\\begin{table}[htbp]\n",
    "\\centering\n",
    "\\caption{Event Study: Safety Coverage Around Olympic Events}\n",
    "\\label{tab:event_study}\n",
    "\\begin{tabular}{lccc}\n",
    "\\hline\\hline\n",
    "Weeks Relative & Estimate & SE & 95\\% CI \\\\\n",
    "to Olympics & & & \\\\\n",
    "\\hline\n",
    paste(apply(es_coefs[order(rel_week)], 1, function(r) {
      sprintf("%+d & %.3f%s & (%.3f) & [%.3f, %.3f]",
              as.integer(r["rel_week"]),
              as.numeric(r["estimate"]), r["sig"],
              as.numeric(r["se"]),
              as.numeric(r["ci_low"]), as.numeric(r["ci_high"]))
    }), collapse = " \\\\\n"),
    " \\\\\n",
    "\\hline\\hline\n",
    "\\end{tabular}\n",
    "\\begin{flushleft}\\small\n",
    "Notes: Estimates from regressing weekly safety coverage on indicators for weeks relative to Olympic opening ceremonies. Reference period: one week before opening ceremony ($t = -1$). Year fixed effects included. * indicates significance at the 5\\% level.\n",
    "\\end{flushleft}\n",
    "\\end{table}\n"
  )

  writeLines(tab3_tex, file.path(TABLE_DIR, "tab3_event_study.tex"))
  cat("  Table 3 saved.\n")
} else {
  cat("  Event study data not available. Skipping Table 3.\n")
}

# ============================================================
# Table 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

# Collect robustness specifications
panel[, time_index := as.integer(week - min(week))]
panel[, month_factor := factor(month(week))]

rob_specs <- list(
  feols(total_safety_coverage ~ prescheduled_event | year + quarter, data = panel),
  feols(total_safety_coverage ~ prescheduled_event + time_index | year, data = panel),
  feols(total_safety_coverage ~ prescheduled_event | year + month_factor, data = panel),
  feols(total_safety_coverage ~ olympics_week | year + quarter, data = panel)
)

# Add event window variants
panel[, event_exact := 0L]
olympics_exact <- as.Date(c("2016-08-08", "2018-02-12", "2021-07-26", "2022-02-07"))
superbowl_exact <- as.Date(c(
  "2015-02-02", "2016-02-08", "2017-02-06", "2018-02-05",
  "2019-02-04", "2020-02-03", "2021-02-08", "2022-02-14", "2023-02-13"
))
for (d in c(olympics_exact, superbowl_exact)) {
  panel[abs(as.integer(week - d)) <= 7, event_exact := 1L]
}
rob_specs[[5]] <- feols(total_safety_coverage ~ event_exact | year + quarter, data = panel)

tab4_file <- file.path(TABLE_DIR, "tab4_robustness.tex")
etable(rob_specs,
       file = tab4_file,
       title = "Robustness: Alternative Specifications",
       label = "tab:robustness",
       headers = c("Baseline", "Linear Trend", "Month FE", "Olympics Only", "Exact Window"),
       dict = c(prescheduled_event = "Pre-Scheduled Event",
                olympics_week = "Olympics Week",
                event_exact = "Event Week (exact)",
                time_index = "Time Trend"),
       fitstat = c("n", "r2"),
       se.below = TRUE,
       notes = "Notes: Dependent variable is weekly safety coverage. Column 1 is the baseline specification. Column 2 adds a linear time trend. Column 3 replaces quarter FE with month FE. Column 4 uses only Olympics as the event. Column 5 restricts the event window to the exact event week (±1 week). Standard errors in parentheses.",
       style.tex = style.tex("aer"))

cat("  Table 4 saved.\n")

# ============================================================
# Table F1: SDE Appendix (Mandatory)
# ============================================================
cat("=== Table F1: SDE Appendix ===\n")

# For the SDE table, we need: outcome, beta, SE, SD(Y), SDE, SE(SDE), classification
# Since our main outcome is safety coverage (not violations), we construct SDE
# for the media crowding-out effect

main_spec <- feols(total_safety_coverage ~ prescheduled_event |
                     year + quarter, data = panel)
beta_hat <- coef(main_spec)[["prescheduled_event"]]
se_hat <- sqrt(vcov(main_spec)["prescheduled_event", "prescheduled_event"])
sd_y <- sd(panel$total_safety_coverage)
sde <- beta_hat / sd_y
se_sde <- se_hat / sd_y

classify_sde <- function(x) {
  ax <- abs(x)
  if (ax > 0.15) return("Large")
  if (ax > 0.05) return("Moderate")
  if (ax > 0.005) return("Small")
  return("Null")
}

# Panel A: Pooled
sde_rows_a <- data.table(
  Outcome = c("Safety Coverage (all networks)",
              "Safety Segments (count)"),
  Beta = c(beta_hat,
           coef(feols(total_safety_segments ~ prescheduled_event |
                        year + quarter, data = panel))[["prescheduled_event"]]),
  SE = c(se_hat,
         sqrt(vcov(feols(total_safety_segments ~ prescheduled_event |
                           year + quarter, data = panel))["prescheduled_event", "prescheduled_event"])),
  SD_Y = c(sd(panel$total_safety_coverage),
           sd(panel$total_safety_segments))
)
sde_rows_a[, `:=`(
  SDE = Beta / SD_Y,
  SE_SDE = SE / SD_Y
)]
sde_rows_a[, Classification := sapply(SDE, classify_sde)]

# Panel B: Heterogeneous (by network type — if station data available)
safety_weekly <- fread(file.path(DATA_DIR, "gdelt_tv_safety.csv"))
if (nrow(safety_weekly) > 0) {
  safety_weekly[, date := as.Date(as.character(date), format = "%Y%m%d")]
  safety_weekly[, week := floor_date(date, "week", week_start = 1)]

  cable_news <- safety_weekly[station %in% c("CNN", "FOXNEWS", "MSNBC")]
  cable_weekly <- cable_news[, .(safety_coverage = sum(value)), by = .(week, station)]

  fox_weekly <- cable_weekly[station == "FOXNEWS",
                             .(fox_safety = sum(safety_coverage)), by = week]
  cnn_weekly <- cable_weekly[station == "CNN",
                             .(cnn_safety = sum(safety_coverage)), by = week]

  panel_het <- merge(panel, fox_weekly, by = "week", all.x = TRUE)
  panel_het <- merge(panel_het, cnn_weekly, by = "week", all.x = TRUE)
  setnafill(panel_het, fill = 0, cols = c("fox_safety", "cnn_safety"))

  het_fox <- feols(fox_safety ~ prescheduled_event | year + quarter,
                   data = panel_het)
  het_cnn <- feols(cnn_safety ~ prescheduled_event | year + quarter,
                   data = panel_het)

  sde_rows_b <- data.table(
    Outcome = c("Fox News Safety Coverage",
                "CNN Safety Coverage"),
    Beta = c(coef(het_fox)[["prescheduled_event"]],
             coef(het_cnn)[["prescheduled_event"]]),
    SE = c(sqrt(vcov(het_fox)["prescheduled_event", "prescheduled_event"]),
           sqrt(vcov(het_cnn)["prescheduled_event", "prescheduled_event"])),
    SD_Y = c(sd(panel_het$fox_safety),
             sd(panel_het$cnn_safety))
  )
  sde_rows_b[, `:=`(SDE = Beta / SD_Y, SE_SDE = SE / SD_Y)]
  sde_rows_b[, Classification := sapply(SDE, classify_sde)]
} else {
  sde_rows_b <- data.table(
    Outcome = c("Cable News Safety Coverage", "Broadcast Safety Coverage"),
    Beta = NA_real_, SE = NA_real_, SD_Y = NA_real_,
    SDE = NA_real_, SE_SDE = NA_real_, Classification = "N/A"
  )
}

# Build SDE table
fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "---", sprintf(paste0("%.", digits, "f"), x))
}

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Distributional Effects}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\emph{Panel A: Pooled} & & & & & & \\\\\n",
  paste(apply(sde_rows_a, 1, function(r) {
    sprintf("%s & %s & %s & %s & %s & %s & %s",
            r["Outcome"],
            fmt_num(as.numeric(r["Beta"])),
            fmt_num(as.numeric(r["SE"])),
            fmt_num(as.numeric(r["SD_Y"])),
            fmt_num(as.numeric(r["SDE"])),
            fmt_num(as.numeric(r["SE_SDE"])),
            r["Classification"])
  }), collapse = " \\\\\n"),
  " \\\\\n[0.5em]\n",
  "\\emph{Panel B: Heterogeneous} & & & & & & \\\\\n",
  paste(apply(sde_rows_b, 1, function(r) {
    sprintf("%s & %s & %s & %s & %s & %s & %s",
            r["Outcome"],
            fmt_num(as.numeric(r["Beta"])),
            fmt_num(as.numeric(r["SE"])),
            fmt_num(as.numeric(r["SD_Y"])),
            fmt_num(as.numeric(r["SDE"])),
            fmt_num(as.numeric(r["SE_SDE"])),
            r["Classification"])
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{flushleft}\\small\n",
  "\\textbf{Country:} United States.\n",
  "\\textbf{Research question:} Does organic TV news coverage of workplace safety incidents deter OSHA violations?\n",
  "\\textbf{Policy mechanism:} Media visibility amplifies regulatory deterrence by informing employers of enforcement consequences.\n",
  "\\textbf{Outcome definition:} TV airtime devoted to workplace safety topics (\\% of total broadcast time).\n",
  "\\textbf{Treatment:} Pre-scheduled mega-events (Olympics, Super Bowl) that crowd out safety coverage.\n",
  "\\textbf{Data:} GDELT Television Explorer API, 2015--2023; six major US TV networks.\n",
  "\\textbf{Method:} Instrumental variables using competing-news (Eisensee-Str\\\"omberg 2007).\n",
  "\\textbf{Sample:} 470 weeks $\\times$ 6 stations (national weekly panel).\n",
  "Classification refers to magnitude, not statistical significance. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
  "Large: $|\\text{SDE}| > 0.15$; Moderate: $0.05$--$0.15$; Small: $0.005$--$0.05$; Null: $< 0.005$.\n",
  "\\end{flushleft}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
