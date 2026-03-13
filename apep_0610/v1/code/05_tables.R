## 05_tables.R — Generate all LaTeX tables
## apep_0610: The Marginal Birth

library(data.table)
library(fixest)
library(did)
library(modelsummary)

panel <- fread("data/analysis_panel.csv")
cs_results   <- readRDS("data/cs_results.rds")
twfe_results <- readRDS("data/twfe_results.rds")
sa_results   <- readRDS("data/sa_results.rds")
hetero_results <- readRDS("data/hetero_results.rds")
placebo_results <- readRDS("data/placebo_results.rds")
notx_results  <- readRDS("data/notx_results.rds")
narrow_results <- readRDS("data/narrow_results.rds")
nocovid_results <- readRDS("data/nocovid_results.rds")

dir.create("tables", showWarnings = FALSE)

# ====================================================================
# TABLE 1: Summary Statistics
# ====================================================================
cat("Generating Table 1: Summary Statistics\n")

pre <- panel[year <= 2022]
ban_states <- pre[first_treat > 0]
ctrl_states <- pre[first_treat == 0]

sumstats <- function(dt, vars) {
  sapply(vars, function(v) {
    x <- dt[[v]]
    x <- x[!is.na(x)]
    c(mean = mean(x), sd = sd(x), min = min(x), max = max(x), n = length(x))
  })
}

vars <- c("total_births", "unmarried_share", "lbw_share", "preterm_share", "teen_share")
labels <- c("Total births", "Unmarried share", "Low birthweight share",
            "Preterm share", "Teen birth share")

all_stats <- sumstats(pre, vars)
ban_stats <- sumstats(ban_states, vars)
ctrl_stats <- sumstats(ctrl_states, vars)

lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Birth Outcomes by Treatment Status, 2016--2022}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Ban States} & \\multicolumn{2}{c}{Control States} & \\multicolumn{2}{c}{Difference} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Diff. & SE \\\\"
)

for (i in seq_along(vars)) {
  v <- vars[i]
  bm <- ban_stats["mean", v]
  bs <- ban_stats["sd", v]
  cm <- ctrl_stats["mean", v]
  cs <- ctrl_stats["sd", v]
  diff <- bm - cm
  bn <- ban_stats["n", v]
  cn <- ctrl_stats["n", v]
  se_diff <- sqrt(bs^2/bn + cs^2/cn)

  if (v == "total_births") {
    fmt <- "%.0f"
  } else {
    fmt <- "%.3f"
  }

  line <- sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
                  labels[i],
                  sprintf(fmt, bm), sprintf(fmt, bs),
                  sprintf(fmt, cm), sprintf(fmt, cs),
                  sprintf(fmt, diff), sprintf(fmt, se_diff))
  lines <- c(lines, line)
}

lines <- c(lines,
  "\\midrule",
  sprintf("State-years & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & & \\\\",
          nrow(ban_states), nrow(ctrl_states)),
  sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & & \\\\",
          uniqueN(ban_states$state_abbr), uniqueN(ctrl_states$state_abbr)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Pre-treatment period (2016--2022). Ban states include %d states with total bans or gestational limits enacted after \\textit{Dobbs v.\\ Jackson} (June 2022). Control states are %d states with no new restrictions. Source: Annie E.\\ Casey Foundation Kids Count Data Center / CDC NVSS.",
          uniqueN(ban_states$state_abbr), uniqueN(ctrl_states$state_abbr)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

writeLines(lines, "tables/tab1_summary.tex")
cat("  Saved tables/tab1_summary.tex\n")

# ====================================================================
# TABLE 2: Main CS-DiD Results
# ====================================================================
cat("Generating Table 2: Main CS-DiD Results\n")

main_vars <- c("log_births", "unmarried_share", "lbw_share", "preterm_share", "teen_share")
main_labels <- c("Log Births", "Unmarried", "LBW", "Preterm", "Teen")

lines2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Post-\\textit{Dobbs} Abortion Bans on Birth Composition}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0(" & ", paste(paste0("(", seq_along(main_labels), ")"), collapse = " & "), " \\\\"),
  paste0(" & ", paste(main_labels, collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\"
)

# Panel A: CS-DiD
coef_cells <- c()
se_cells   <- c()
for (v in main_vars) {
  if (!is.null(cs_results[[v]])) {
    att <- cs_results[[v]]$att_overall
    coef_val <- att$overall.att
    se_val   <- att$overall.se
    p_val    <- 2 * pnorm(-abs(coef_val / se_val))
    stars    <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.10, "^{*}", "")))
    coef_cells <- c(coef_cells, sprintf("$%.4f%s$", coef_val, stars))
    se_cells   <- c(se_cells, sprintf("(%.4f)", se_val))
  } else {
    coef_cells <- c(coef_cells, "---")
    se_cells   <- c(se_cells, "")
  }
}

lines2 <- c(lines2,
  paste0("Ban enacted & ", paste(coef_cells, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_cells, collapse = " & "), " \\\\[0.5em]")
)

# Panel B: TWFE
lines2 <- c(lines2,
  "\\multicolumn{6}{l}{\\textit{Panel B: TWFE}} \\\\"
)

coef_cells_twfe <- c()
se_cells_twfe   <- c()
for (v in main_vars) {
  if (!is.null(twfe_results[[v]])) {
    fit <- twfe_results[[v]]
    coef_val <- coef(fit)["treated"]
    se_val   <- se(fit)["treated"]
    p_val    <- pvalue(fit)["treated"]
    stars    <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.10, "^{*}", "")))
    coef_cells_twfe <- c(coef_cells_twfe, sprintf("$%.4f%s$", coef_val, stars))
    se_cells_twfe   <- c(se_cells_twfe, sprintf("(%.4f)", se_val))
  } else {
    coef_cells_twfe <- c(coef_cells_twfe, "---")
    se_cells_twfe   <- c(se_cells_twfe, "")
  }
}

lines2 <- c(lines2,
  paste0("Ban enacted & ", paste(coef_cells_twfe, collapse = " & "), " \\\\"),
  paste0(" & ", paste(se_cells_twfe, collapse = " & "), " \\\\[0.5em]")
)

# Footer
n_obs <- nrow(panel[!is.na(unmarried_share)])
n_states <- uniqueN(panel$state_abbr)
n_treated <- uniqueN(panel[first_treat > 0]$state_abbr)

lines2 <- c(lines2,
  "\\midrule",
  sprintf("Observations & \\multicolumn{5}{c}{%d} \\\\", n_obs),
  sprintf("States & \\multicolumn{5}{c}{%d} \\\\", n_states),
  sprintf("Treated states & \\multicolumn{5}{c}{%d} \\\\", n_treated),
  "State \\& year FE & \\multicolumn{5}{c}{Yes} \\\\",
  "Clustering & \\multicolumn{5}{c}{State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports Callaway-Sant'Anna (2021) overall ATT estimates with never-treated states as controls. Panel B reports TWFE estimates. Standard errors clustered at the state level in parentheses. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$. Sample: 51 states (including DC), 2016--2023. Outcome variables in columns (2)--(5) are shares of total births.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)

writeLines(lines2, "tables/tab2_main.tex")
cat("  Saved tables/tab2_main.tex\n")

# ====================================================================
# TABLE 3: Event Study Coefficients
# ====================================================================
cat("Generating Table 3: Event Study\n")

es_vars <- c("unmarried_share", "lbw_share", "preterm_share", "teen_share")
es_labels <- c("Unmarried", "LBW", "Preterm", "Teen")

es_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Dynamic Treatment Effects: Event Study Coefficients}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  paste0("Event time & ", paste(es_labels, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Collect event study data
es_data <- list()
for (v in es_vars) {
  if (!is.null(cs_results[[v]])) {
    es <- cs_results[[v]]$att_dynamic
    es_data[[v]] <- data.table(egt = es$egt, att = es$att.egt, se = es$se.egt)
  }
}

if (length(es_data) > 0) {
  # Get all event times
  all_egt <- sort(unique(unlist(lapply(es_data, function(x) x$egt))))

  for (k in all_egt) {
    cells <- c()
    se_cells_es <- c()
    for (v in es_vars) {
      if (!is.null(es_data[[v]])) {
        row <- es_data[[v]][egt == k]
        if (nrow(row) == 1) {
          p_val <- 2 * pnorm(-abs(row$att / row$se))
          stars <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.10, "^{*}", "")))
          cells <- c(cells, sprintf("$%.4f%s$", row$att, stars))
          se_cells_es <- c(se_cells_es, sprintf("(%.4f)", row$se))
        } else {
          cells <- c(cells, "---")
          se_cells_es <- c(se_cells_es, "")
        }
      } else {
        cells <- c(cells, "---")
        se_cells_es <- c(se_cells_es, "")
      }
    }
    es_lines <- c(es_lines,
      sprintf("$k = %+d$ & %s \\\\", k, paste(cells, collapse = " & ")),
      sprintf(" & %s \\\\%s", paste(se_cells_es, collapse = " & "),
              ifelse(k == -1, "[0.3em]", ""))
    )
  }
}

es_lines <- c(es_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dynamic ATT estimates from Callaway-Sant'Anna (2021). Event time $k$ is years relative to treatment. $k=0$ is the first year with potentially affected births. Never-treated states as controls. Standard errors clustered at the state level. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:event_study}",
  "\\end{table}"
)

writeLines(es_lines, "tables/tab3_event_study.tex")
cat("  Saved tables/tab3_event_study.tex\n")

# ====================================================================
# TABLE 4: Robustness
# ====================================================================
cat("Generating Table 4: Robustness\n")

rob_vars <- c("unmarried_share", "lbw_share", "preterm_share", "teen_share")
rob_labels <- c("Unmarried", "LBW", "Preterm", "Teen")

rob_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  paste0(" & ", paste(paste0("(", 1:4, ")"), collapse = " & "), " \\\\"),
  paste0(" & ", paste(rob_labels, collapse = " & "), " \\\\"),
  "\\midrule"
)

rob_row <- function(label, result_list, coef_name = "treated") {
  cells <- c()
  se_c  <- c()
  for (v in rob_vars) {
    if (!is.null(result_list[[v]])) {
      fit <- result_list[[v]]
      cn <- intersect(coef_name, names(coef(fit)))
      if (length(cn) > 0) {
        cv <- coef(fit)[cn[1]]
        sv <- se(fit)[cn[1]]
        pv <- pvalue(fit)[cn[1]]
        stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.10, "^{*}", "")))
        cells <- c(cells, sprintf("$%.4f%s$", cv, stars))
        se_c  <- c(se_c, sprintf("(%.4f)", sv))
      } else {
        cells <- c(cells, "---"); se_c <- c(se_c, "")
      }
    } else {
      cells <- c(cells, "---"); se_c <- c(se_c, "")
    }
  }
  c(
    sprintf("%s & %s \\\\", label, paste(cells, collapse = " & ")),
    sprintf(" & %s \\\\[0.3em]", paste(se_c, collapse = " & "))
  )
}

rob_lines <- c(rob_lines,
  rob_row("Temporal placebo (2019)", placebo_results, "treated_placebo"),
  rob_row("Drop Texas", notx_results, "treated"),
  rob_row("Total bans only", narrow_results, "treated_narrow"),
  rob_row("Drop COVID years", nocovid_results, "treated")
)

rob_lines <- c(rob_lines,
  "\\midrule",
  "State \\& year FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Clustering & \\multicolumn{4}{c}{State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports the TWFE DiD coefficient. Row 1: temporal placebo assigning fake treatment in 2019 using pre-Dobbs data (2016--2021). Row 2: drops Texas (SB8 exposure from September 2021). Row 3: restricts treatment to total ban states only. Row 4: drops 2020--2021 (COVID years). Standard errors clustered at the state level. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robustness}",
  "\\end{table}"
)

writeLines(rob_lines, "tables/tab4_robustness.tex")
cat("  Saved tables/tab4_robustness.tex\n")

# ====================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ====================================================================
cat("Generating Table F1: SDE\n")

classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_vars <- c("unmarried_share", "lbw_share", "preterm_share", "teen_share")
sde_labels <- c("Unmarried birth share", "Low birthweight share",
                "Preterm birth share", "Teen birth share")

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in seq_along(sde_vars)) {
  v <- sde_vars[i]
  if (!is.null(cs_results[[v]])) {
    att    <- cs_results[[v]]$att_overall
    beta   <- att$overall.att
    se_b   <- att$overall.se
    sd_y   <- sd(panel[[v]], na.rm = TRUE)
    sde    <- beta / sd_y
    se_sde <- se_b / sd_y
    cls    <- classify_sde(sde)

    sde_lines <- c(sde_lines,
      sprintf("%s & CS-DiD & %.4f & --- & %.4f & %.3f & %.3f & %s \\\\",
              sde_labels[i], beta, sd_y, sde, se_sde, cls))
  }
}

n_treated_states <- uniqueN(panel[first_treat > 0]$state_abbr)
n_obs <- nrow(panel[!is.na(unmarried_share)])

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\par\\vspace{0.3em}",
  sprintf("{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison. For binary treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) is the unconditional standard deviation from the full sample. \\textbf{Research question:} Do post-\\emph{Dobbs} state abortion bans shift birth composition? \\textbf{Treatment:} Binary indicator for state having enacted a total ban or restrictive gestational limit following \\emph{Dobbs v.\\ Jackson} (June 2022). \\textbf{Data:} Kids Count Data Center / CDC NVSS, 2016--2023, state-year panel ($N=%d$, %d states, %d treated). \\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD, state-clustered SEs. Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes $|$SDE$| < 0.005$.}",
          n_obs, uniqueN(panel$state_abbr), n_treated_states),
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
