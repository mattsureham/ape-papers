## 05_tables.R — Generate all LaTeX tables (including SDE appendix)
## apep_0867: Upload Filters and the Creative Economy

source("00_packages.R")

panel <- readRDS("../data/panel_balanced.rds")
results <- readRDS("../data/main_results.rds")
diagnostics <- read_json("../data/diagnostics.json")
es_coefs <- readRDS("../data/event_study_coefs.rds")
loo_results <- readRDS("../data/loo_results.rds")

cat("=== Generating Tables ===\n")

# -------------------------------------------------------------------
# Table 1: Summary Statistics
# -------------------------------------------------------------------
cat("\n--- Table 1: Summary Statistics ---\n")

panel_j <- panel %>% filter(nace == "J")
panel_k <- panel %>% filter(nace == "K")

sum_stats <- bind_rows(
  panel_j %>%
    filter(first_treat == 0 | year < first_treat) %>%
    summarise(
      Variable = "NACE J Employment (thousands)",
      Mean = sprintf("%.1f", mean(employment, na.rm = TRUE)),
      SD = sprintf("%.1f", sd(employment, na.rm = TRUE)),
      Min = sprintf("%.1f", min(employment, na.rm = TRUE)),
      Max = sprintf("%.1f", max(employment, na.rm = TRUE)),
      N = as.character(n())
    ),
  panel_j %>%
    filter(first_treat == 0 | year < first_treat) %>%
    summarise(
      Variable = "NACE J Employment Share (\\%)",
      Mean = sprintf("%.2f", mean(empl_share, na.rm = TRUE)),
      SD = sprintf("%.2f", sd(empl_share, na.rm = TRUE)),
      Min = sprintf("%.2f", min(empl_share, na.rm = TRUE)),
      Max = sprintf("%.2f", max(empl_share, na.rm = TRUE)),
      N = as.character(n())
    ),
  panel_j %>%
    filter(first_treat == 0 | year < first_treat) %>%
    summarise(
      Variable = "Log NACE J Employment",
      Mean = sprintf("%.2f", mean(log_empl, na.rm = TRUE)),
      SD = sprintf("%.2f", sd(log_empl, na.rm = TRUE)),
      Min = sprintf("%.2f", min(log_empl, na.rm = TRUE)),
      Max = sprintf("%.2f", max(log_empl, na.rm = TRUE)),
      N = as.character(n())
    ),
  panel_k %>%
    filter(first_treat == 0 | year < first_treat) %>%
    summarise(
      Variable = "NACE K Employment (thousands)",
      Mean = sprintf("%.1f", mean(employment, na.rm = TRUE)),
      SD = sprintf("%.1f", sd(employment, na.rm = TRUE)),
      Min = sprintf("%.1f", min(employment, na.rm = TRUE)),
      Max = sprintf("%.1f", max(employment, na.rm = TRUE)),
      N = as.character(n())
    ),
  panel %>%
    filter(nace == "J", first_treat == 0 | year < first_treat) %>%
    summarise(
      Variable = "Total Employment (thousands)",
      Mean = sprintf("%.1f", mean(total_employment, na.rm = TRUE)),
      SD = sprintf("%.1f", sd(total_employment, na.rm = TRUE)),
      Min = sprintf("%.1f", min(total_employment, na.rm = TRUE)),
      Max = sprintf("%.1f", max(total_employment, na.rm = TRUE)),
      N = as.character(n())
    )
)

# Generate LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics (Pre-Treatment)}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  "Variable & Mean & SD & Min & Max & N \\\\\n",
  "\\hline\n",
  paste(apply(sum_stats, 1, function(row) {
    paste(row, collapse = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Pre-treatment sample includes all country-year observations before national ",
  "transposition of Directive 2019/790 Article 17 and all observations from never-treated countries ",
  "(Norway, Switzerland, Iceland, Poland). Employment in thousands. NACE J = Information and ",
  "Communication; NACE K = Financial and Insurance Activities. Data: Eurostat LFS (lfsa\\_egan2), 2015--2023.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# -------------------------------------------------------------------
# Table 2: Main Results (CS-DiD + DDD)
# -------------------------------------------------------------------
cat("\n--- Table 2: Main Results ---\n")

# Extract CS-DiD results
cs_level_att <- results$agg_simple$overall.att
cs_level_se <- results$agg_simple$overall.se
cs_log_att <- results$agg_log_simple$overall.att
cs_log_se <- results$agg_log_simple$overall.se
cs_share_att <- results$agg_share_simple$overall.att
cs_share_se <- results$agg_share_simple$overall.se

# Stars function
stars <- function(coef, se) {
  z <- abs(coef / se)
  if (z > 2.576) return("$^{***}$")
  if (z > 1.960) return("$^{**}$")
  if (z > 1.645) return("$^{*}$")
  return("")
}

# Extract DDD results
ddd_level_coef <- coef(results$ddd_model)["did_treat"]
ddd_level_se <- se(results$ddd_model)["did_treat"]
ddd_log_coef <- coef(results$ddd_log)["did_treat"]
ddd_log_se <- se(results$ddd_log)["did_treat"]
ddd_share_coef <- coef(results$ddd_share)["did_treat"]
ddd_share_se <- se(results$ddd_share)["did_treat"]

n_j <- nrow(panel_j)
n_ddd <- nrow(panel)
n_countries <- n_distinct(panel$country)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Copyright Directive Transposition on Information-Sector Employment}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Callaway--Sant'Anna DiD} & \\multicolumn{3}{c}{Triple-Difference} \\\\\n",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n",
  " & Levels & Log & Share & Levels & Log & Share \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n",
  sprintf("ATT & %.1f%s & %.4f%s & %.3f%s & %.1f%s & %.4f%s & %.3f%s \\\\\n",
          cs_level_att, stars(cs_level_att, cs_level_se),
          cs_log_att, stars(cs_log_att, cs_log_se),
          cs_share_att, stars(cs_share_att, cs_share_se),
          ddd_level_coef, stars(ddd_level_coef, ddd_level_se),
          ddd_log_coef, stars(ddd_log_coef, ddd_log_se),
          ddd_share_coef, stars(ddd_share_coef, ddd_share_se)),
  sprintf(" & (%.1f) & (%.4f) & (%.3f) & (%.1f) & (%.4f) & (%.3f) \\\\\n",
          cs_level_se, cs_log_se, cs_share_se,
          ddd_level_se, ddd_log_se, ddd_share_se),
  "\\hline\n",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
          format(n_j, big.mark = ","), format(n_j, big.mark = ","),
          format(n_j, big.mark = ","),
          format(n_ddd, big.mark = ","), format(n_ddd, big.mark = ","),
          format(n_ddd, big.mark = ",")),
  sprintf("Countries & %d & %d & %d & %d & %d & %d \\\\\n",
          n_countries, n_countries, n_countries,
          n_countries, n_countries, n_countries),
  "Estimator & CS & CS & CS & TWFE & TWFE & TWFE \\\\\n",
  "Control group & Never-treated & Never-treated & Never-treated & ",
  "NACE K & NACE K & NACE K \\\\\n",
  "Clustering & Country & Country & Country & Country & Country & Country \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Columns 1--3 report Callaway and Sant'Anna (2021) ATT estimates for ",
  "NACE J (Information and Communication) employment using never-treated countries as controls. ",
  "Columns 4--6 report triple-difference estimates comparing NACE J (treated sector) to NACE K ",
  "(Financial and Insurance, control sector) within the same country-year cell. ",
  "Treatment is national transposition of EU Copyright Directive 2019/790 Article 17. ",
  "Standard errors clustered at the country level in parentheses. ",
  "$^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# -------------------------------------------------------------------
# Table 3: Event Study Coefficients
# -------------------------------------------------------------------
cat("\n--- Table 3: Event Study ---\n")

es_sorted <- es_coefs %>%
  filter(!is.na(event_time)) %>%
  arrange(event_time) %>%
  mutate(
    star = mapply(stars, Estimate, `Std. Error`),
    est_str = sprintf("%.4f%s", Estimate, star),
    se_str = sprintf("(%.4f)", `Std. Error`)
  )

tab3_body <- paste(
  apply(es_sorted, 1, function(row) {
    sprintf("$t %+d$ & %s \\\\", as.integer(row["event_time"]),
            row["est_str"])
  }),
  collapse = "\n"
)
tab3_se <- paste(
  apply(es_sorted, 1, function(row) {
    sprintf(" & %s \\\\", row["se_str"])
  }),
  collapse = "\n"
)

# Interleave estimates and SEs
tab3_rows <- character(0)
for (i in seq_len(nrow(es_sorted))) {
  tab3_rows <- c(tab3_rows,
    sprintf("$t %+d$ & %s \\\\", es_sorted$event_time[i], es_sorted$est_str[i]),
    sprintf(" & %s \\\\", es_sorted$se_str[i])
  )
}

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Log NACE J Employment (Sun--Abraham)}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lc}\n",
  "\\hline\\hline\n",
  "Event Time & Log Employment \\\\\n",
  "\\hline\n",
  paste(tab3_rows, collapse = "\n"),
  "\n\\hline\n",
  sprintf("Observations & %s \\\\\n", format(n_j, big.mark = ",")),
  sprintf("Countries & %d \\\\\n", n_countries),
  "Pre-trend $F$-test $p$ & ",
  tryCatch({
    pt <- readRDS("../data/pretrend_test.rds")
    sprintf("%.3f", pt$p)
  }, error = function(e) "---"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Sun and Abraham (2021) interaction-weighted event study estimates. ",
  "Outcome: log employment in NACE J (Information and Communication). ",
  "Standard errors clustered at country level in parentheses. ",
  "$^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_event_study.tex")
cat("Table 3 written.\n")

# -------------------------------------------------------------------
# Table 4: Robustness (Placebo + Wild Bootstrap + LOO)
# -------------------------------------------------------------------
cat("\n--- Table 4: Robustness ---\n")

# Placebo results
placebo_k <- tryCatch(readRDS("../data/placebo_k_result.rds"), error = function(e) NULL)
ri <- tryCatch(readRDS("../data/ri_result.rds"), error = function(e) NULL)

loo_range <- sprintf("[%.4f, %.4f]",
                     min(loo_results$att, na.rm = TRUE),
                     max(loo_results$att, na.rm = TRUE))

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Specification & Estimate & SE / CI \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Main result}} \\\\\n",
  sprintf("CS-DiD (log NACE J) & %.4f%s & (%.4f) \\\\\n",
          cs_log_att, stars(cs_log_att, cs_log_se), cs_log_se),
  sprintf("DDD (log, J vs K) & %.4f%s & (%.4f) \\\\\n",
          ddd_log_coef, stars(ddd_log_coef, ddd_log_se), ddd_log_se),
  "[4pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo tests}} \\\\\n",
  if (!is.null(placebo_k)) {
    sprintf("Placebo: NACE K (Finance) & %.4f%s & (%.4f) \\\\\n",
            placebo_k$overall.att, stars(placebo_k$overall.att, placebo_k$overall.se),
            placebo_k$overall.se)
  } else " Placebo: NACE K (Finance) & --- & --- \\\\\n",
  "[4pt]\n",
  "\\multicolumn{3}{l}{\\textit{Panel C: Inference}} \\\\\n",
  if (!is.null(ri)) {
    sprintf("Randomization Inference $p$ (DDD) & %.4f & \\\\\n", ri$p_value)
  } else "Randomization Inference $p$ (DDD) & --- & \\\\\n",
  sprintf("Leave-one-out range & %s & \\\\\n", loo_range),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A reproduces main estimates. Panel B shows placebo tests: ",
  "NACE K (Financial and Insurance) should be unaffected by the Copyright Directive. ",
  "Panel C reports randomization inference $p$-value (999 permutations of treatment timing across countries) and the range of ",
  "leave-one-country-out CS-DiD estimates. Standard errors clustered at country level.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# -------------------------------------------------------------------
# Table F1: SDE Appendix (Mandatory)
# -------------------------------------------------------------------
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

sd_y_pre_log <- diagnostics$outcome_sd_pre_log
sd_y_pre_share <- diagnostics$outcome_sd_pre_share

# SDE calculations
sde_log <- cs_log_att / sd_y_pre_log
sde_log_se <- cs_log_se / sd_y_pre_log
sde_share <- cs_share_att / sd_y_pre_share
sde_share_se <- cs_share_se / sd_y_pre_share
sde_ddd <- ddd_log_coef / sd_y_pre_log
sde_ddd_se <- ddd_log_se / sd_y_pre_log

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
pooled_rows <- tribble(
  ~Outcome, ~beta, ~se, ~sd_y, ~sde, ~sde_se, ~class,
  "Log NACE J empl. (CS-DiD)",
    cs_log_att, cs_log_se, sd_y_pre_log, sde_log, sde_log_se, classify_sde(sde_log),
  "NACE J share (CS-DiD)",
    cs_share_att, cs_share_se, sd_y_pre_share, sde_share, sde_share_se, classify_sde(sde_share),
  "Log NACE J empl. (DDD)",
    ddd_log_coef, ddd_log_se, sd_y_pre_log, sde_ddd, sde_ddd_se, classify_sde(sde_ddd)
)

# Panel B: Heterogeneous (early vs late transposers)
panel_j_early <- panel %>%
  filter(nace == "J", first_treat > 0, first_treat <= 2021) %>%
  mutate(id = as.integer(factor(country)))

panel_j_late <- panel %>%
  filter(nace == "J", first_treat == 0 | first_treat > 2021) %>%
  mutate(id = as.integer(factor(country)))

# Early transposers CS-DiD
cs_early <- tryCatch({
  out <- att_gt(yname = "log_empl", tname = "year", idname = "id",
                gname = "first_treat", data = panel_j_early,
                control_group = "nevertreated", anticipation = 0,
                base_period = "universal")
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

# Late transposers CS-DiD
cs_late <- tryCatch({
  out <- att_gt(yname = "log_empl", tname = "year", idname = "id",
                gname = "first_treat", data = panel_j_late,
                control_group = "nevertreated", anticipation = 0,
                base_period = "universal")
  aggte(out, type = "simple")
}, error = function(e) list(overall.att = NA, overall.se = NA))

sde_early <- if (!is.na(cs_early$overall.att)) cs_early$overall.att / sd_y_pre_log else NA
sde_early_se <- if (!is.na(cs_early$overall.se)) cs_early$overall.se / sd_y_pre_log else NA
sde_late <- if (!is.na(cs_late$overall.att)) cs_late$overall.att / sd_y_pre_log else NA
sde_late_se <- if (!is.na(cs_late$overall.se)) cs_late$overall.se / sd_y_pre_log else NA

het_rows <- tribble(
  ~Outcome, ~beta, ~se, ~sd_y, ~sde, ~sde_se, ~class,
  "Early transposers ($\\leq$2021)",
    cs_early$overall.att, cs_early$overall.se, sd_y_pre_log,
    sde_early, sde_early_se,
    if (!is.na(sde_early)) classify_sde(sde_early) else "---",
  "Late transposers ($>$2021)",
    cs_late$overall.att, cs_late$overall.se, sd_y_pre_log,
    sde_late, sde_late_se,
    if (!is.na(sde_late)) classify_sde(sde_late) else "---"
)

# Format helper
fmt <- function(x, d = 4) {
  if (is.na(x)) return("---")
  sprintf(paste0("%.", d, "f"), x)
}

# Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states plus Norway, Switzerland, Iceland as controls). ",
  "\\textbf{Research question:} Does mandatory content-recognition technology (``upload filters'') on platforms, ",
  "as required by the EU Copyright Directive's Article 17, affect information-sector employment? ",
  "\\textbf{Policy mechanism:} Directive 2019/790 Article 17 requires online content-sharing service providers ",
  "to obtain authorization from rights holders for user-uploaded content or implement ``best efforts'' content ",
  "recognition technology, increasing platform compliance costs and potentially shifting content-hosting operations. ",
  "\\textbf{Outcome definition:} Log employment (thousands) in NACE Rev.~2 sector J (Information and Communication) ",
  "from the Eurostat Labour Force Survey; and NACE J employment as a share of total employment. ",
  "\\textbf{Treatment:} Binary; national transposition of Directive 2019/790, staggered across 27 member states ",
  "from December 2020 to August 2024. ",
  "\\textbf{Data:} Eurostat LFS (lfsa\\_egan2), 2015--2023, country-year panel, ",
  sprintf("%d country-year observations. ", diagnostics$n_obs),
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with not-yet-treated controls; triple-difference ",
  "(NACE J vs.\\ NACE K) with country$\\times$sector, sector$\\times$year, and country$\\times$year fixed effects; ",
  "standard errors clustered at country level. ",
  "\\textbf{Sample:} 30 European countries (27 EU + 3 EEA); Poland effectively never-treated (transposed August 2024, ",
  "beyond data window). Panel B splits by transposition timing: early ($\\leq$2021) vs.\\ late ($>$2021). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

make_sde_row <- function(outcome, beta, se, sd_y, sde, sde_se, class_label) {
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          outcome, fmt(as.numeric(beta)), fmt(as.numeric(se)),
          fmt(as.numeric(sd_y)), fmt(as.numeric(sde)), fmt(as.numeric(sde_se)),
          class_label)
}

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(sapply(seq_len(nrow(pooled_rows)), function(i) {
    r <- pooled_rows[i, ]
    make_sde_row(r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$class)
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "[4pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Early vs.\\ Late Transposition)}} \\\\\n",
  paste(sapply(seq_len(nrow(het_rows)), function(i) {
    r <- het_rows[i, ]
    make_sde_row(r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$class)
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

# -------------------------------------------------------------------
# Table 5: Transposition Timeline
# -------------------------------------------------------------------
cat("\n--- Table 5: Transposition Timeline ---\n")

transp <- readRDS("../data/transposition.rds") %>%
  filter(treatment_year > 0) %>%
  arrange(transposition_date)

tab5_rows <- paste(
  apply(transp, 1, function(r) {
    sprintf("%s & %s & %s",
            r["country"], r["transposition_date"], r["treatment_year"])
  }),
  collapse = " \\\\\n"
)

tab5_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Transposition Timeline: Directive 2019/790}\n",
  "\\label{tab:transposition}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Country & Transposition Date & Treatment Year \\\\\n",
  "\\hline\n",
  tab5_rows,
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Transposition dates from EUR-Lex National Implementation Measures. ",
  "Treatment year assigned as the first full calendar year under the new regime: transpositions ",
  "in January--June map to that year; July--December map to the following year. ",
  "Poland (August 2024) is beyond the data window and treated as never-treated. ",
  "Norway, Switzerland, and Iceland (EEA, non-EU) are never-treated controls (not shown).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5_tex, "../tables/tab5_transposition.tex")
cat("Table 5 written.\n")

cat("\n=== All tables generated ===\n")
