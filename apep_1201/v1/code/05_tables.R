# ============================================================================
# apep_1201: When the Anchor Drops
# 05_tables.R - Summary, results, and SDE tables
# ============================================================================

source("code/00_packages.R")

dt <- safe_read_parquet("data/derived/analysis_panel.parquet")
dt <- dt[!is.na(exit_next_year)]

post_exit <- readRDS("data/derived/model_post_exit.rds")
post_exit_3y <- readRDS("data/derived/model_post_exit_3y.rds")
post_deposits <- readRDS("data/derived/model_post_deposits.rds")
small_branch_sample <- readRDS("data/derived/model_small_branch_sample.rds")
only_2018 <- readRDS("data/derived/model_only_2018.rds")

summary_dt <- rbindlist(list(
  dt[, .(
    Variable = "Branch exit next year",
    Mean = mean(exit_next_year, na.rm = TRUE),
    `Std. Dev.` = sd(exit_next_year, na.rm = TRUE),
    Min = min(exit_next_year, na.rm = TRUE),
    Max = max(exit_next_year, na.rm = TRUE)
  )],
  dt[, .(
    Variable = "Log deposits",
    Mean = mean(ln_deposits, na.rm = TRUE),
    `Std. Dev.` = sd(ln_deposits, na.rm = TRUE),
    Min = min(ln_deposits, na.rm = TRUE),
    Max = max(ln_deposits, na.rm = TRUE)
  )],
  dt[!is.na(exit_within_3y), .(
    Variable = "Branch exit within 3 years",
    Mean = mean(exit_within_3y, na.rm = TRUE),
    `Std. Dev.` = sd(exit_within_3y, na.rm = TRUE),
    Min = min(exit_within_3y, na.rm = TRUE),
    Max = max(exit_within_3y, na.rm = TRUE)
  )],
  dt[, .(
    Variable = "Distance to exit (miles)",
    Mean = mean(distance_miles, na.rm = TRUE),
    `Std. Dev.` = sd(distance_miles, na.rm = TRUE),
    Min = min(distance_miles, na.rm = TRUE),
    Max = max(distance_miles, na.rm = TRUE)
  )]
), fill = TRUE)

fmt <- function(x) sprintf("%.3f", x)

summary_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lrrrr}",
  "\\toprule",
  "Variable & Mean & Std. Dev. & Min & Max \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summary_dt))) {
  summary_lines <- c(
    summary_lines,
    sprintf(
      "%s & %s & %s & %s & %s \\\\",
      summary_dt$Variable[i],
      fmt(summary_dt$Mean[i]),
      fmt(summary_dt$`Std. Dev.`[i]),
      fmt(summary_dt$Min[i]),
      fmt(summary_dt$Max[i])
    )
  )
}

summary_lines <- c(
  summary_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item Notes: %s branch-year observations from %s unique bank branches matched to bankruptcy-linked supermarket exits between 2010 and 2024. Branch exit equals one if a branch disappears from the FDIC Summary of Deposits in the next annual snapshot.", format(nrow(dt), big.mark = ","), format(uniqueN(dt$branch_id), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

write_lines_utf8(summary_lines, "tables/tab_summary.tex")

event_exit <- fread("tables/event_study_exit.csv")
event_exit <- event_exit[, .(
  rel_year,
  estimate = Estimate,
  se = `Std. Error`,
  p = `Pr(>|t|)`
)]

event_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event-Study Estimates for Branch Exit}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{rrrr}",
  "\\toprule",
  "Event time & Estimate & Standard error & p-value \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(event_exit))) {
  event_lines <- c(
    event_lines,
    sprintf(
      "%d & %.4f & %.4f & %.3f \\\\",
      event_exit$rel_year[i],
      event_exit$estimate[i],
      event_exit$se[i],
      event_exit$p[i]
    )
  )
}

event_lines <- c(
  event_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Coefficients come from a branch fixed-effects event study with county-year fixed effects. The omitted event time is one year before the nearby supermarket exit.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:event_exit}",
  "\\end{table}"
)

write_lines_utf8(event_lines, "tables/tab_event_exit.tex")

sde_rows <- data.table(
  Outcome = c(
    "Branch exit next year (pooled)",
    "Branch exit within 3 years (pooled)",
    "Branch exit next year: small branches",
    "Branch exit next year: 2018 bankruptcy wave"
  ),
  beta = c(
    coef(post_exit)[["treated:post"]],
    coef(post_exit_3y)[["treated:post"]],
    coef(small_branch_sample)[["treated:post"]],
    coef(only_2018)[["treated:post"]]
  ),
  se = c(
    se(post_exit)[["treated:post"]],
    se(post_exit_3y)[["treated:post"]],
    se(small_branch_sample)[["treated:post"]],
    se(only_2018)[["treated:post"]]
  )
)

sde_rows[, sd_y := c(
  dt[, sd(exit_next_year, na.rm = TRUE)],
  dt[!is.na(exit_within_3y), sd(exit_within_3y, na.rm = TRUE)],
  dt[small_branch == 1, sd(exit_next_year, na.rm = TRUE)],
  dt[event_year == 2018, sd(exit_next_year, na.rm = TRUE)]
)]
sde_rows[, sde := beta / sd_y]
sde_rows[, sde_se := se / sd_y]
sde_rows[, classification := fifelse(
  sde < -0.15, "Large negative",
  fifelse(
    sde < -0.05, "Moderate negative",
    fifelse(
      sde < -0.005, "Small negative",
      fifelse(
        sde <= 0.005, "Null",
        fifelse(
          sde <= 0.05, "Small positive",
          fifelse(sde <= 0.15, "Moderate positive", "Large positive")
        )
      )
    )
  )
)]

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{p{4.2cm}rrrrrp{2.3cm}}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:2) {
  sde_lines <- c(
    sde_lines,
    sprintf(
      "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
      sde_rows$Outcome[i],
      sde_rows$beta[i],
      sde_rows$se[i],
      sde_rows$sd_y[i],
      sde_rows$sde[i],
      sde_rows$sde_se[i],
      sde_rows$classification[i]
    )
  )
}

sde_lines <- c(
  sde_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\"
)

for (i in 3:4) {
  sde_lines <- c(
    sde_lines,
    sprintf(
      "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
      sde_rows$Outcome[i],
      sde_rows$beta[i],
      sde_rows$se[i],
      sde_rows$sd_y[i],
      sde_rows$sde[i],
      sde_rows$sde_se[i],
      sde_rows$classification[i]
    )
  )
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do bankruptcy-linked supermarket exits increase nearby bank branch closure? ",
  "\\textbf{Policy mechanism:} Grocery stores may act as retail anchors; bankruptcy-driven exits remove recurring foot traffic and trip chaining. ",
  "\\textbf{Outcome definition:} Branch disappearance in the next annual FDIC snapshot or within three annual snapshots. ",
  "\\textbf{Treatment:} Binary indicator for branches within one mile of an exit; controls are branches two to five miles away. ",
  "\\textbf{Data:} FDIC Summary of Deposits and USDA Historical SNAP Retailer Locator Database, 2010--2024; branch-year panel. ",
  "\\textbf{Method:} Branch fixed effects, county-year fixed effects, and county-clustered standard errors. ",
  "\\textbf{Sample:} Branches near A\\&P, Tops, Winn-Dixie, BI-LO, and Harveys exits; the 1--2 mile ring is excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:sde}",
  "\\end{table}"
)

write_lines_utf8(sde_lines, "tables/tabF1_sde.tex")

cat("Tables written.\n")
