# 05_tables.R — Generate all LaTeX tables
# apep_0946: EECC transposition and consumer telecom prices

source("00_packages.R")

# ===========================================================================
# 1. Load all estimation results
# ===========================================================================

panel <- fread("../data/panel_main.csv")
diag <- fromJSON("../data/diagnostics.json")
overall <- readRDS("../data/overall.rds")
overall_log <- readRDS("../data/overall_log.rds")
group_atts <- readRDS("../data/group_atts.rds")
es <- readRDS("../data/es.rds")
twfe <- readRDS("../data/twfe.rds")
twfe_log <- readRDS("../data/twfe_log.rds")
placebo_results <- readRDS("../data/placebo_results.rds")
overall_bb <- readRDS("../data/overall_broadband.rds")
overall_nyt <- readRDS("../data/overall_nyt.rds")
loco_results <- readRDS("../data/loco_results.rds")

dir.create("../tables", showWarnings = FALSE)

# Helper: format with stars
add_stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  paste0(formatC(est, format = "f", digits = 3), stars)
}

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================

cat("Generating Table 1: Summary Statistics\n")

# Pre-treatment stats (2014-2019)
pre <- panel[year <= 2019]
post <- panel[year >= 2020]

# Treated vs never-treated pre-treatment
pre_treated <- pre[first_treat > 0]
pre_never <- pre[first_treat == 0]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Communications Price Index (CP08)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-treatment (2014--2019)}} \\\\[3pt]",
  sprintf("All countries & %s & %s & %s & %s \\\\",
    formatC(mean(pre$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(sd(pre$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(min(pre$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(max(pre$cp08, na.rm = TRUE), format = "f", digits = 1)),
  sprintf("Treated ($N = %d$) & %s & %s & %s & %s \\\\",
    uniqueN(pre_treated$geo),
    formatC(mean(pre_treated$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(sd(pre_treated$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(min(pre_treated$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(max(pre_treated$cp08, na.rm = TRUE), format = "f", digits = 1)),
  sprintf("Never-treated ($N = %d$) & %s & %s & %s & %s \\\\",
    uniqueN(pre_never$geo),
    formatC(mean(pre_never$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(sd(pre_never$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(min(pre_never$cp08, na.rm = TRUE), format = "f", digits = 1),
    formatC(max(pre_never$cp08, na.rm = TRUE), format = "f", digits = 1)),
  "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treatment cohort sizes}} \\\\[3pt]",
  sprintf("On-time (2020) & \\multicolumn{4}{l}{%d countries: DK, EL, HU} \\\\",
    uniqueN(panel[first_treat == 2020]$geo)),
  sprintf("Early (2021) & \\multicolumn{4}{l}{%d countries: AT, BG, CZ, DE, FI, FR, LU, MT} \\\\",
    uniqueN(panel[first_treat == 2021]$geo)),
  sprintf("Late (2022) & \\multicolumn{4}{l}{%d countries: BE, CY, EE, ES, HR, LV, NL, PT, RO, SE, SI} \\\\",
    uniqueN(panel[first_treat == 2022]$geo)),
  sprintf("Very late (2023) & \\multicolumn{4}{l}{%d country: IE} \\\\",
    uniqueN(panel[first_treat == 2023]$geo)),
  sprintf("Never-treated & \\multicolumn{4}{l}{%d countries: CH, IT, LT, NO, PL, SK} \\\\",
    uniqueN(panel[first_treat == 0]$geo)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Communications CPI (COICOP CP08) from Eurostat HICP, annual average index (2015 = 100). Sample: 29 countries (EU-27 plus Norway and Switzerland), 2014--2024. Treatment is the year of formal transposition of EU Directive 2018/1972 (European Electronic Communications Code). Countries transposing after 2023 or outside the EU (CH, NO) are classified as never-treated.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ===========================================================================
# Table 2: Main Results (CS-DiD)
# ===========================================================================

cat("Generating Table 2: Main Results\n")

# Group-level ATTs
g_atts <- data.table(
  group = group_atts$egt,
  att = group_atts$att.egt,
  se = group_atts$se.egt
)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of EECC Transposition on Communications Prices}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & CS-DiD & CS-DiD (log) & TWFE & TWFE (log) \\\\",
  "\\hline",
  sprintf("ATT & %s & %s & %s & %s \\\\",
    add_stars(overall$overall.att, overall$overall.se),
    add_stars(overall_log$overall.att, overall_log$overall.se),
    add_stars(coef(twfe)["post"], se(twfe)["post"]),
    add_stars(coef(twfe_log)["post"], se(twfe_log)["post"])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    formatC(overall$overall.se, format = "f", digits = 3),
    formatC(overall_log$overall.se, format = "f", digits = 4),
    formatC(se(twfe)["post"], format = "f", digits = 3),
    formatC(se(twfe_log)["post"], format = "f", digits = 4)),
  "[6pt]",
  "\\multicolumn{5}{l}{\\textit{Group-level ATTs (CS-DiD, level):}} \\\\[3pt]"
)

for (i in seq_len(nrow(g_atts))) {
  tab2_lines <- c(tab2_lines,
    sprintf("\\quad Cohort %d & %s & & & \\\\",
      g_atts$group[i],
      add_stars(g_atts$att[i], g_atts$se[i])),
    sprintf(" & (%s) & & & \\\\",
      formatC(g_atts$se[i], format = "f", digits = 3))
  )
}

tab2_lines <- c(tab2_lines,
  "[6pt]",
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nrow(panel), nrow(panel), nrow(panel), nrow(panel)),
  sprintf("Countries & %d & %d & %d & %d \\\\",
    uniqueN(panel$geo), uniqueN(panel$geo),
    uniqueN(panel$geo), uniqueN(panel$geo)),
  "Estimator & CS & CS & TWFE & TWFE \\\\",
  "Control group & Never-treated & Never-treated & --- & --- \\\\",
  "Clustering & Country & Country & Country & Country \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns (1)--(2) report the overall ATT from Callaway and Sant'Anna (2021) using never-treated countries as the comparison group. Column (1) uses the level of CP08; column (2) uses log(CP08). Columns (3)--(4) report standard TWFE estimates for comparison. Standard errors (in parentheses) are clustered at the country level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, "../tables/tab2_main.tex")

# ===========================================================================
# Table 3: Event Study Coefficients
# ===========================================================================

cat("Generating Table 3: Event Study\n")

es_dt <- data.table(
  event_time = es$egt,
  att = es$att.egt,
  se = es$se.egt
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Communications CPI Relative to EECC Transposition}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Event time & ATT & SE & 95\\% CI \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_dt))) {
  ci_lo <- es_dt$att[i] - 1.96 * es_dt$se[i]
  ci_hi <- es_dt$att[i] + 1.96 * es_dt$se[i]
  tab3_lines <- c(tab3_lines,
    sprintf("$t %s %d$ & %s & (%s) & [%s, %s] \\\\",
      ifelse(es_dt$event_time[i] >= 0, "+", "-"),
      abs(es_dt$event_time[i]),
      add_stars(es_dt$att[i], es_dt$se[i]),
      formatC(es_dt$se[i], format = "f", digits = 3),
      formatC(ci_lo, format = "f", digits = 3),
      formatC(ci_hi, format = "f", digits = 3))
  )
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event-study estimates from Callaway and Sant'Anna (2021). Event time 0 is the year of EECC transposition. Comparison group: never-treated countries. Standard errors clustered at the country level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ===========================================================================
# Table 4: Robustness and Placebo Tests
# ===========================================================================

cat("Generating Table 4: Robustness\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & ATT & SE \\\\",
  "\\hline",
  "\\multicolumn{3}{l}{\\textit{Panel A: Alternative specifications}} \\\\[3pt]",
  sprintf("Not-yet-treated comparison & %s & (%s) \\\\",
    add_stars(overall_nyt$overall.att, overall_nyt$overall.se),
    formatC(overall_nyt$overall.se, format = "f", digits = 3)),
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel B: Leave-one-cohort-out}} \\\\[3pt]"
)

for (nm in names(loco_results)) {
  r <- loco_results[[nm]]
  tab4_lines <- c(tab4_lines,
    sprintf("Excluding cohort %d & %s & (%s) \\\\",
      r$cohort_excluded,
      add_stars(r$att, r$se),
      formatC(r$se, format = "f", digits = 3))
  )
}

tab4_lines <- c(tab4_lines,
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel C: Placebo outcomes}} \\\\[3pt]",
  sprintf("Food (CP011) & %s & (%s) \\\\",
    add_stars(placebo_results$food$att, placebo_results$food$se),
    formatC(placebo_results$food$se, format = "f", digits = 3)),
  sprintf("Transport (CP07) & %s & (%s) \\\\",
    add_stars(placebo_results$transport$att, placebo_results$transport$se),
    formatC(placebo_results$transport$se, format = "f", digits = 3)),
  sprintf("Housing (CP04) & %s & (%s) \\\\",
    add_stars(placebo_results$housing$att, placebo_results$housing$se),
    formatC(placebo_results$housing$se, format = "f", digits = 3)),
  "[6pt]",
  "\\multicolumn{3}{l}{\\textit{Panel D: Secondary outcome}} \\\\[3pt]",
  sprintf("Broadband subscriptions & %s & (%s) \\\\",
    add_stars(overall_bb$overall.att, overall_bb$overall.se),
    formatC(overall_bb$overall.se, format = "f", digits = 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All estimates use Callaway and Sant'Anna (2021). Panel A uses not-yet-treated countries as the comparison group (baseline uses never-treated). Panel B drops one treatment cohort at a time. Panel C applies the same treatment timing to non-communications HICP categories; a valid design should show no effect on these unrelated prices. Panel D estimates the effect on fixed broadband subscriptions per 100 people (World Bank). Standard errors clustered at the country level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ===========================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ===========================================================================

cat("Generating Table F1: SDE\n")

pre_sd_y <- panel[year <= 2019, sd(cp08, na.rm = TRUE)]
pre_sd_y_bb <- fread("../data/panel_broadband.csv")[year <= 2019, sd(broadband, na.rm = TRUE)]

# Main outcome SDE
sde_main <- overall$overall.att / pre_sd_y
sde_se_main <- overall$overall.se / pre_sd_y

# Broadband SDE
sde_bb <- overall_bb$overall.att / pre_sd_y_bb
sde_se_bb <- overall_bb$overall.se / pre_sd_y_bb

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: early (2020-2021) vs late (2022-2023) transposers
early_countries <- panel[first_treat %in% c(2020, 2021), unique(geo)]
late_countries <- panel[first_treat %in% c(2022, 2023), unique(geo)]

panel_early <- panel[geo %in% c(early_countries, panel[first_treat == 0, unique(geo)])]
panel_early[, country_id := as.integer(factor(geo))]
panel_late <- panel[geo %in% c(late_countries, panel[first_treat == 0, unique(geo)])]
panel_late[, country_id := as.integer(factor(geo))]

cs_early <- att_gt(yname = "cp08", tname = "year", idname = "country_id",
                   gname = "first_treat", data = as.data.frame(panel_early),
                   control_group = "notyettreated", base_period = "universal")
overall_early <- aggte(cs_early, type = "simple")

cs_late <- att_gt(yname = "cp08", tname = "year", idname = "country_id",
                  gname = "first_treat", data = as.data.frame(panel_late),
                  control_group = "notyettreated", base_period = "universal")
overall_late <- aggte(cs_late, type = "simple")

sde_early <- overall_early$overall.att / pre_sd_y
sde_se_early <- overall_early$overall.se / pre_sd_y
sde_late <- overall_late$overall.att / pre_sd_y
sde_se_late <- overall_late$overall.se / pre_sd_y

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states plus Norway and Switzerland as non-EU comparators). ",
  "\\textbf{Research question:} Does transposing the EU Electronic Communications Code (Directive 2018/1972) ",
  "into national law reduce consumer telecommunications prices? ",
  "\\textbf{Policy mechanism:} The EECC mandates enhanced wholesale access to very-high-capacity networks, ",
  "one-business-day number portability, 5G spectrum harmonization, and anti-lock-in contractual requirements, ",
  "increasing retail competition and reducing switching costs for consumers. ",
  "\\textbf{Outcome definition:} Eurostat Harmonised Index of Consumer Prices for Communications (COICOP CP08), ",
  "annual average index with 2015 as the base year, measuring the price of telephone, internet, and postal services. ",
  "\\textbf{Treatment:} Binary indicator equal to one from the year a member state formally transposed the EECC ",
  "into national law, as confirmed by notification to the European Commission. ",
  "\\textbf{Data:} Eurostat HICP (prc\\_hicp\\_aind), 29 countries, 2014--2024, country-year panel, ",
  formatC(nrow(panel), big.mark = ","), " observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences with never-treated ",
  "comparison group; standard errors clustered at the country level. ",
  "\\textbf{Sample:} EU-27 member states plus Norway and Switzerland; four late-transposing EU members ",
  "(IT, LT, PL, SK) and two non-EU countries (NO, CH) serve as the never-treated comparison group. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Communications CPI & %s & %s & %s & %s & %s & %s \\\\",
    formatC(overall$overall.att, format = "f", digits = 3),
    formatC(overall$overall.se, format = "f", digits = 3),
    formatC(pre_sd_y, format = "f", digits = 2),
    formatC(sde_main, format = "f", digits = 3),
    formatC(sde_se_main, format = "f", digits = 3),
    classify_sde(sde_main)),
  sprintf("Broadband subs. & %s & %s & %s & %s & %s & %s \\\\",
    formatC(overall_bb$overall.att, format = "f", digits = 3),
    formatC(overall_bb$overall.se, format = "f", digits = 3),
    formatC(pre_sd_y_bb, format = "f", digits = 2),
    formatC(sde_bb, format = "f", digits = 3),
    formatC(sde_se_bb, format = "f", digits = 3),
    classify_sde(sde_bb)),
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]",
  sprintf("Early transposers (2020--21) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(overall_early$overall.att, format = "f", digits = 3),
    formatC(overall_early$overall.se, format = "f", digits = 3),
    formatC(pre_sd_y, format = "f", digits = 2),
    formatC(sde_early, format = "f", digits = 3),
    formatC(sde_se_early, format = "f", digits = 3),
    classify_sde(sde_early)),
  sprintf("Late transposers (2022--23) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(overall_late$overall.att, format = "f", digits = 3),
    formatC(overall_late$overall.se, format = "f", digits = 3),
    formatC(pre_sd_y, format = "f", digits = 2),
    formatC(sde_late, format = "f", digits = 3),
    formatC(sde_se_late, format = "f", digits = 3),
    classify_sde(sde_late)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables written to tables/\n")
