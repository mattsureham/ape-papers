# =============================================================================
# 06_tables.R — Generate all LaTeX tables
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

source("00_packages.R")

cat("=== Generating tables ===\n")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Table 1: Summary statistics...\n")

events <- fread("../data/events_analysis.csv")
car_dt <- fread("../data/car_results.csv")
firms <- fread("../data/mining_firms_universe.csv")

# Panel A: Events
n_events <- nrow(events)
evt_stats <- data.table(
  Variable = c(
    "Number of events",
    "Year range",
    "Fatal events (\\%)",
    "Major events ($\\geq$10 deaths, \\%)",
    "Mean fatality count (fatal events)",
    "Post-GISTM (\\%)",
    "Countries",
    "Ore types"
  ),
  Value = c(
    as.character(n_events),
    paste(min(events$year), "--", max(events$year)),
    sprintf("%.1f", mean(events$has_fatalities, na.rm = TRUE) * 100),
    sprintf("%.1f", mean(events$severity == "Major", na.rm = TRUE) * 100),
    sprintf("%.1f", mean(events$fatality_count[events$has_fatalities == TRUE], na.rm = TRUE)),
    sprintf("%.1f", mean(events$post_gistm, na.rm = TRUE) * 100),
    as.character(uniqueN(events$country_clean)),
    as.character(uniqueN(events$ore_clean))
  )
)

# Panel B: Firms
n_firms <- uniqueN(car_dt$ticker)
firm_stats <- data.table(
  Variable = c(
    "Number of firms",
    "With tailings dams (\\%)",
    "Streaming/royalty (\\%)",
    "Commodities represented"
  ),
  Value = c(
    as.character(n_firms),
    sprintf("%.1f", mean(firms$has_tailings_dams[firms$ticker %in% unique(car_dt$ticker)], na.rm = TRUE) * 100),
    sprintf("%.1f", mean(firms$is_streaming_royalty[firms$ticker %in% unique(car_dt$ticker)], na.rm = TRUE) * 100),
    as.character(uniqueN(firms$primary_commodity[firms$ticker %in% unique(car_dt$ticker)]))
  )
)

# Panel C: CARs
car_stats <- data.table(
  Variable = c(
    "Mean CAR [-1, +1] (\\%)",
    "Mean CAR [-1, +5] (\\%)",
    "Mean CAR [-1, +10] (\\%)",
    "Mean CAR [-5, -2] (placebo, \\%)",
    "SD of CAR [-1, +5] (\\%)",
    "Firm-event observations"
  ),
  Value = c(
    sprintf("%.3f", mean(car_dt$car_short, na.rm = TRUE) * 100),
    sprintf("%.3f", mean(car_dt$car_main, na.rm = TRUE) * 100),
    sprintf("%.3f", mean(car_dt$car_long, na.rm = TRUE) * 100),
    sprintf("%.3f", mean(car_dt$car_pre, na.rm = TRUE) * 100),
    sprintf("%.3f", sd(car_dt$car_main, na.rm = TRUE) * 100),
    format(nrow(car_dt), big.mark = ",")
  )
)

# Combine into LaTeX
tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "\\multicolumn{2}{l}{\\textit{Panel A: Tailings Dam Failure Events}} \\\\",
  "\\midrule",
  apply(evt_stats, 1, function(r) paste(r[1], "&", r[2], "\\\\")),
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Panel B: Mining Firm Universe}} \\\\",
  "\\midrule",
  apply(firm_stats, 1, function(r) paste(r[1], "&", r[2], "\\\\")),
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Panel C: Cumulative Abnormal Returns}} \\\\",
  "\\midrule",
  apply(car_stats, 1, function(r) paste(r[1], "&", r[2], "\\\\")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event data from the WISE World Information Service on Energy Uranium Project",
  "Chronology of Major Tailings Dam Failures (1960--2025). Stock return data from Yahoo Finance.",
  "CARs computed using the market model with S\\&P 500 as benchmark, estimated over trading",
  "days [-250, -31] relative to the failure event. The placebo window [-5, -2] tests for",
  "pre-event abnormal returns.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# =============================================================================
# Table 2: Main Regression Results (from 03_main_analysis.R output)
# =============================================================================
cat("Table 2: Main regressions...\n")

# Re-estimate for clean table output
car_dt[, car_pct := car_main * 100]

m1 <- feols(car_pct ~ 1, data = car_dt, cluster = ~event_id)
m2 <- feols(car_pct ~ has_tailings_dams + same_commodity,
            data = car_dt, cluster = ~event_id)
m3 <- feols(car_pct ~ has_tailings_dams + same_commodity +
              i(severity, ref = "Other"),
            data = car_dt, cluster = ~event_id)
m4 <- feols(car_pct ~ has_tailings_dams * post_gistm +
              same_commodity * post_gistm +
              i(severity, ref = "Other"),
            data = car_dt, cluster = ~event_id)
m5 <- feols(car_pct ~ has_tailings_dams + same_commodity +
              is_streaming_royalty | event_id,
            data = car_dt)

tab2_tex <- etable(m1, m2, m3, m4, m5,
                    headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
                    tex = TRUE,
                    title = "Cross-Sectional Determinants of Peer Firm Contagion",
                    label = "tab:main_reg",
                    notes = "Dependent variable: CAR [-1, +5] in percentage points. Standard errors clustered by event in columns (1)--(4). Column (5) includes event fixed effects. \\textit{Has tailings dams} = 1 if the peer firm operates tailings storage facilities. \\textit{Same commodity} = 1 if the peer firm mines the same commodity as the failure site. \\textit{Post-GISTM} = 1 for events after August 2020. \\textit{Streaming/royalty} = 1 for firms without physical mining operations (built-in placebo).",
                    depvar = FALSE)

writeLines(tab2_tex, "../tables/tab2_main_regressions.tex")

# =============================================================================
# Table 3: Robustness
# =============================================================================
cat("Table 3: Robustness checks...\n")

rob <- fread("../data/robustness_summary.csv")
window_rob <- fread("../data/robustness_windows.csv")

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Mean CAR (\\%) & SE & $t$-stat & $N$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(window_rob))) {
  tab3 <- c(tab3, sprintf("Window %s & %.3f & %.3f & %.2f & %s \\\\",
                           window_rob$window[i], window_rob$mean_car[i],
                           window_rob$se[i], window_rob$t_stat[i],
                           format(window_rob$n[i], big.mark = ",")))
}

tab3 <- c(tab3,
  "\\midrule",
  sprintf("Excl.\\ overlapping events & %.3f & -- & -- & -- \\\\", rob[test == "No overlap"]$value),
  sprintf("Excl.\\ mega-events & %.3f & -- & -- & -- \\\\", rob[test == "No mega-events"]$value),
  sprintf("Winsorized (1/99) & %.3f & -- & -- & -- \\\\", rob[test == "Winsorized"]$value),
  sprintf("LOO range & [%.3f, %.3f] & -- & -- & -- \\\\",
          rob[test == "LOO min"]$value, rob[test == "LOO max"]$value),
  sprintf("Placebo $p$-value & \\multicolumn{4}{c}{%.3f} \\\\", rob[test == "Placebo p-value"]$value),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All CARs computed using the market model with S\\&P 500 benchmark.",
  "``Mega-events'' are the 3 deadliest failures in the sample. LOO = leave-one-event-out.",
  "Placebo $p$-value from 200 permutations of random pseudo-event dates.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_robustness.tex")

cat("=== ALL TABLES GENERATED ===\n")
