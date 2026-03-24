# 05_tables.R — Generate all tables (including SDE appendix)
# apep_0870: Upload Filter Tax

source("code/00_packages.R")

df <- fread("data/panel_csdid.csv")
load("data/cs_results.RData")
load("data/cs_share_results.RData")
load("data/twfe_results.RData")
load("data/cs_placebo_results.RData")

diag <- jsonlite::fromJSON("data/diagnostics.json")

dir.create("tables", showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

message("Generating Table 1: Summary Statistics...")

# Pre-treatment period stats
pre_data <- df[is.na(transposition_year) | year < transposition_year]
post_data <- df[!is.na(transposition_year) & year >= transposition_year]

sumstats <- data.table(
  Variable = c("ICT Employment (thousands)", "Financial Employment (thousands)",
               "Total Employment (thousands)", "ICT Employment Share",
               "GDP per capita (EUR)", "Population (thousands)"),
  `Mean (Pre)` = c(
    mean(pre_data$emp_j, na.rm = TRUE),
    mean(pre_data$emp_k, na.rm = TRUE),
    mean(pre_data$emp_total, na.rm = TRUE),
    mean(pre_data$share_j, na.rm = TRUE),
    mean(pre_data$gdp_pc, na.rm = TRUE),
    mean(pre_data$population / 1000, na.rm = TRUE)
  ),
  `SD (Pre)` = c(
    sd(pre_data$emp_j, na.rm = TRUE),
    sd(pre_data$emp_k, na.rm = TRUE),
    sd(pre_data$emp_total, na.rm = TRUE),
    sd(pre_data$share_j, na.rm = TRUE),
    sd(pre_data$gdp_pc, na.rm = TRUE),
    sd(pre_data$population / 1000, na.rm = TRUE)
  ),
  `Mean (Post)` = c(
    mean(post_data$emp_j, na.rm = TRUE),
    mean(post_data$emp_k, na.rm = TRUE),
    mean(post_data$emp_total, na.rm = TRUE),
    mean(post_data$share_j, na.rm = TRUE),
    mean(post_data$gdp_pc, na.rm = TRUE),
    mean(post_data$population / 1000, na.rm = TRUE)
  ),
  N = c(rep(nrow(df), 6))
)

# Format numbers
for (col in c("Mean (Pre)", "SD (Pre)", "Mean (Post)")) {
  sumstats[[col]] <- sprintf("%.2f", sumstats[[col]])
}
sumstats$N <- format(sumstats$N, big.mark = ",")

# LaTeX output
cat("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:sumstats}
\\begin{tabular}{lcccc}
\\toprule
& \\multicolumn{2}{c}{Pre-Transposition} & Post-Transposition & \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-4}
Variable & Mean & SD & Mean & N \\\\
\\midrule\n",
file = "tables/tab1_sumstats.tex")

for (i in 1:nrow(sumstats)) {
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              sumstats$Variable[i], sumstats$`Mean (Pre)`[i],
              sumstats$`SD (Pre)`[i], sumstats$`Mean (Post)`[i],
              sumstats$N[i]),
      file = "tables/tab1_sumstats.tex", append = TRUE)
}

cat("\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Employment measured in thousands. Panel of NUTS2 regions across 27 EU member states plus Norway, Switzerland, and Iceland (EEA controls), 2015--2023. ICT Employment = NACE Section J (Information and Communication). Financial Employment = NACE Section K (Financial and Insurance Activities). Pre-transposition defined relative to each country's transposition date of EU Copyright Directive Article 17.
\\end{tablenotes}
\\end{table}\n",
file = "tables/tab1_sumstats.tex", append = TRUE)

message("  Saved: tables/tab1_sumstats.tex")

# ============================================================================
# Table 2: Main Results — CS-DiD and TWFE
# ============================================================================

message("Generating Table 2: Main Results...")

cs_att <- cs_agg$overall.att
cs_se  <- cs_agg$overall.se
cs_share_att <- cs_share_agg$overall.att
cs_share_se  <- cs_share_agg$overall.se
twfe_coef <- coef(twfe_main)["treated"]
twfe_se   <- sqrt(vcov(twfe_main)["treated", "treated"])
twfe_ctrl_coef <- coef(twfe_ctrl)["treated"]
twfe_ctrl_se   <- sqrt(vcov(twfe_ctrl)["treated", "treated"])

# DDD coefficient
ddd_names <- names(coef(ddd_est))
ddd_idx <- grep("is_j.*post.*is_eu|post.*is_j.*is_eu|is_eu.*is_j.*post", ddd_names)
if (length(ddd_idx) > 0) {
  ddd_coef <- coef(ddd_est)[ddd_idx[1]]
  ddd_se <- sqrt(vcov(ddd_est)[ddd_idx[1], ddd_idx[1]])
} else {
  ddd_coef <- NA
  ddd_se <- NA
}

# Stars function
stars <- function(coef, se) {
  if (is.na(coef) || is.na(se) || se == 0) return("")
  z <- abs(coef / se)
  if (z > 2.576) return("$^{***}$")
  if (z > 1.960) return("$^{**}$")
  if (z > 1.645) return("$^{*}$")
  return("")
}

cat("\\begin{table}[htbp]
\\centering
\\caption{Effect of Copyright Directive Transposition on ICT Employment}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\toprule
& (1) & (2) & (3) & (4) \\\\
& CS-DiD & TWFE & TWFE+Controls & DDD \\\\
\\midrule
",
sprintf("Treated & %s%s & %s%s & %s%s & \\\\
& (%s) & (%s) & (%s) & \\\\[0.5em]
",
  formatC(cs_att, format = "f", digits = 4), stars(cs_att, cs_se),
  formatC(twfe_coef, format = "f", digits = 4), stars(twfe_coef, twfe_se),
  formatC(twfe_ctrl_coef, format = "f", digits = 4), stars(twfe_ctrl_coef, twfe_ctrl_se),
  formatC(cs_se, format = "f", digits = 4),
  formatC(twfe_se, format = "f", digits = 4),
  formatC(twfe_ctrl_se, format = "f", digits = 4)
),
if (!is.na(ddd_coef)) {
  sprintf("Treated $\\times$ ICT $\\times$ EU & & & & %s%s \\\\
& & & & (%s) \\\\[0.5em]
",
    formatC(ddd_coef, format = "f", digits = 4), stars(ddd_coef, ddd_se),
    formatC(ddd_se, format = "f", digits = 4))
} else { "" },
sprintf("\\midrule
Region FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes \\\\
Sector FE & No & No & No & Yes \\\\
Controls & No & No & Yes & No \\\\
Observations & %s & %s & %s & %s \\\\
Regions & %d & %d & %d & %d \\\\
Clusters (countries) & %d & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
",
  format(nrow(df), big.mark = ","),
  format(nrow(df), big.mark = ","),
  format(nobs(twfe_ctrl), big.mark = ","),
  format(nobs(ddd_est), big.mark = ","),
  uniqueN(df$geo), uniqueN(df$geo),
  uniqueN(df[!is.na(gdp_pc) & gdp_pc > 0, geo]),
  uniqueN(fread("data/panel_long.csv")[nace %in% c("J","K"), geo]),
  uniqueN(df$country), uniqueN(df$country),
  uniqueN(df[!is.na(gdp_pc) & gdp_pc > 0, country]),
  uniqueN(fread("data/panel_long.csv")[nace %in% c("J","K"), country])
),
"\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Dependent variable: log ICT employment (NACE J) in columns (1)--(3); log sectoral employment in column (4). Column (1): Callaway and Sant'Anna (2021) estimator with not-yet-treated control group. Columns (2)--(3): Two-way fixed effects. Column (4): Triple-difference comparing NACE J (ICT) to NACE K (Financial Services) within EU vs.\\ EEA controls, before vs.\\ after transposition. Standard errors clustered at the country level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.
\\end{tablenotes}
\\end{table}\n",
file = "tables/tab2_main.tex")

message("  Saved: tables/tab2_main.tex")

# ============================================================================
# Table 3: Event Study Estimates
# ============================================================================

message("Generating Table 3: Event Study...")

es <- cs_event
es_dt <- data.table(
  `Event Time` = es$egt,
  ATT = formatC(es$att.egt, format = "f", digits = 4),
  SE = formatC(es$se.egt, format = "f", digits = 4),
  CI_lo = formatC(es$att.egt - 1.96 * es$se.egt, format = "f", digits = 4),
  CI_hi = formatC(es$att.egt + 1.96 * es$se.egt, format = "f", digits = 4)
)

cat("\\begin{table}[htbp]
\\centering
\\caption{Event Study: Dynamic Treatment Effects of Copyright Directive Transposition}
\\label{tab:eventstudy}
\\begin{tabular}{rcccc}
\\toprule
Event Time & ATT & SE & \\multicolumn{2}{c}{95\\% CI} \\\\
\\midrule\n",
file = "tables/tab3_eventstudy.tex")

for (i in 1:nrow(es_dt)) {
  sep <- if (es_dt$`Event Time`[i] == 0) "\\midrule\n" else ""
  cat(sprintf("%s%s & %s & %s & [%s, & %s] \\\\\n",
              sep,
              es_dt$`Event Time`[i], es_dt$ATT[i], es_dt$SE[i],
              es_dt$CI_lo[i], es_dt$CI_hi[i]),
      file = "tables/tab3_eventstudy.tex", append = TRUE)
}

cat("\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic treatment effect estimates. Event time 0 is the year of national transposition. Negative event times are pre-transposition periods (parallel trends test). Control group: not-yet-treated regions. Simultaneous 95\\% confidence intervals based on 1,000 bootstrap iterations clustered at the country level.
\\end{tablenotes}
\\end{table}\n",
file = "tables/tab3_eventstudy.tex", append = TRUE)

message("  Saved: tables/tab3_eventstudy.tex")

# ============================================================================
# Table 4: Robustness — Leave-One-Out and Placebo
# ============================================================================

message("Generating Table 4: Robustness...")

loo <- fread("data/leave_one_out.csv")

cs_placebo_att <- cs_placebo_agg$overall.att
cs_placebo_se  <- cs_placebo_agg$overall.se

# Load never-treated results if available
cs_never_att <- cs_never_se <- NA
if (file.exists("data/cs_never_results.RData")) {
  load("data/cs_never_results.RData")
  cs_never_att <- cs_never_agg$overall.att
  cs_never_se  <- cs_never_agg$overall.se
}

cat("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{lcc}
\\toprule
Specification & ATT & SE \\\\
\\midrule
\\textit{Panel A: Alternative Specifications} & & \\\\[0.3em]
Baseline (CS-DiD, not-yet-treated) & ",
formatC(cs_att, format = "f", digits = 4), " & ",
formatC(cs_se, format = "f", digits = 4), " \\\\\n",
if (!is.na(cs_never_att)) {
  paste0("CS-DiD (never-treated control) & ",
         formatC(cs_never_att, format = "f", digits = 4), " & ",
         formatC(cs_never_se, format = "f", digits = 4), " \\\\\n")
} else { "" },
"ICT employment share & ",
formatC(cs_share_att, format = "f", digits = 4), " & ",
formatC(cs_share_se, format = "f", digits = 4), " \\\\[0.5em]
\\textit{Panel B: Placebo (Financial Services)} & & \\\\[0.3em]
NACE K (Financial \\& Insurance) & ",
formatC(cs_placebo_att, format = "f", digits = 4), " & ",
formatC(cs_placebo_se, format = "f", digits = 4), " \\\\[0.5em]
\\textit{Panel C: Leave-One-Country-Out} & & \\\\[0.3em]\n",
file = "tables/tab4_robustness.tex")

# LOO entries
for (i in 1:nrow(loo)) {
  cat(sprintf("Drop %s & %s & %s \\\\\n",
              loo$dropped[i],
              formatC(loo$att[i], format = "f", digits = 4),
              formatC(loo$se[i], format = "f", digits = 4)),
      file = "tables/tab4_robustness.tex", append = TRUE)
}

cat("\\midrule
LOO range & [",
formatC(min(loo$att), format = "f", digits = 4), ", ",
formatC(max(loo$att), format = "f", digits = 4), "] & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Panel A shows the main CS-DiD estimate alongside alternative specifications. Panel B applies the same CS-DiD estimator to NACE K (Financial and Insurance Activities) as a placebo outcome unaffected by Article 17. Panel C sequentially drops each EU member state. All standard errors from 1,000 bootstrap iterations clustered at the country level.
\\end{tablenotes}
\\end{table}\n",
file = "tables/tab4_robustness.tex", append = TRUE)

message("  Saved: tables/tab4_robustness.tex")

# ============================================================================
# Table 5: Transposition Timeline
# ============================================================================

message("Generating Table 5: Transposition Timeline...")

trans <- fread("data/transposition_dates.csv")
trans <- trans[!is.na(transposition_year)][order(transposition_year, iso2)]

# Merge with country names
country_names <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden")
)
trans <- merge(trans, country_names, by = "iso2")

cat("\\begin{table}[htbp]
\\centering
\\caption{Copyright Directive 2019/790 Transposition Timeline}
\\label{tab:timeline}
\\begin{tabular}{lccc}
\\toprule
Member State & Transposition Year & N Measures & Cohort \\\\
\\midrule\n",
file = "tables/tab5_timeline.tex")

for (i in 1:nrow(trans)) {
  cohort_label <- switch(as.character(trans$transposition_year[i]),
    "2020" = "Early",
    "2021" = "On-time",
    "2022" = "Late",
    "2023" = "Very late",
    "2024" = "Very late",
    "Late"
  )
  cat(sprintf("%s & %d & %s & %s \\\\\n",
              trans$name[i], trans$transposition_year[i],
              if (!is.na(trans$n_measures[i])) as.character(trans$n_measures[i]) else "--",
              cohort_label),
      file = "tables/tab5_timeline.tex", append = TRUE)
}

cat("\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Transposition dates from EUR-Lex National Implementation Measures database. Transposition year defined as the calendar year of the earliest national measure notified to the European Commission. The directive deadline was June 7, 2021. ``Early'' = before deadline; ``On-time'' = deadline year; ``Late'' = 1 year after deadline; ``Very late'' = 2+ years after deadline.
\\end{tablenotes}
\\end{table}\n",
file = "tables/tab5_timeline.tex", append = TRUE)

message("  Saved: tables/tab5_timeline.tex")

# ============================================================================
# SDE Appendix Table (MANDATORY)
# ============================================================================

message("Generating SDE Appendix Table...")

# Compute SDE for main outcomes
sd_y_pre <- diag$sd_y_pre

# Panel A: Pooled results
sde_pooled <- data.table(
  Outcome = c("Log ICT Employment", "ICT Employment Share"),
  beta = c(cs_att, cs_share_att),
  se = c(cs_se, cs_share_se),
  sd_y = c(sd_y_pre, sd(df[group == 0 | year < group, share_j], na.rm = TRUE))
)
sde_pooled[, sde := beta / sd_y]
sde_pooled[, se_sde := se / sd_y]
sde_pooled[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  sde > 0.15, "Large positive"
)]

# Panel B: Heterogeneous — split by early vs late transposers
early_ids <- unique(df[transposition_year <= 2021, id])
late_ids  <- unique(df[transposition_year > 2021, id])

# CS-DiD for early adopters
df_early <- df[id %in% early_ids | group == 0]
df_early[, id_sub := as.integer(factor(geo))]
cs_early <- tryCatch({
  cs_e <- att_gt(yname = "log_emp_j", tname = "year", idname = "id_sub", gname = "group",
                 data = as.data.frame(df_early),
                 control_group = "notyettreated", anticipation = 0,
                 base_period = "universal", bstrap = TRUE, biters = 500)
  aggte(cs_e, type = "simple")
}, error = function(e) { list(overall.att = NA, overall.se = NA) })

# CS-DiD for late adopters
df_late <- df[id %in% late_ids | group == 0]
df_late[, id_sub := as.integer(factor(geo))]
cs_late <- tryCatch({
  cs_l <- att_gt(yname = "log_emp_j", tname = "year", idname = "id_sub", gname = "group",
                 data = as.data.frame(df_late),
                 control_group = "notyettreated", anticipation = 0,
                 base_period = "universal", bstrap = TRUE, biters = 500)
  aggte(cs_l, type = "simple")
}, error = function(e) { list(overall.att = NA, overall.se = NA) })

sde_het <- data.table(
  Outcome = c("Log ICT Emp (Early Adopters)", "Log ICT Emp (Late Adopters)"),
  beta = c(cs_early$overall.att, cs_late$overall.att),
  se = c(cs_early$overall.se, cs_late$overall.se),
  sd_y = rep(sd_y_pre, 2)
)
sde_het[, sde := beta / sd_y]
sde_het[, se_sde := se / sd_y]
sde_het[, classification := fcase(
  sde < -0.15, "Large negative",
  sde < -0.05, "Moderate negative",
  sde < -0.005, "Small negative",
  sde <= 0.005, "Null",
  sde <= 0.05, "Small positive",
  sde <= 0.15, "Moderate positive",
  sde > 0.15, "Large positive"
)]

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states plus Norway, Switzerland, and Iceland as EEA controls). ",
  "\\textbf{Research question:} Does mandatory platform copyright compliance under EU Copyright Directive Article 17 affect information-sector employment? ",
  "\\textbf{Policy mechanism:} Article 17 requires online content-sharing service providers to obtain authorization from rights holders or implement content recognition technology (``upload filters''), raising platform compliance costs while potentially strengthening copyright enforcement and creator revenues. ",
  "\\textbf{Outcome definition:} Log employment in NACE Section J (Information and Communication) at the NUTS2 regional level, measured in thousands of workers from Eurostat Labour Force Survey. ",
  "\\textbf{Treatment:} Binary indicator equal to one in and after the year a member state transposed Directive 2019/790 into national law. ",
  "\\textbf{Data:} Eurostat LFS (lfst\\_r\\_lfe2en2), 2015--2023, NUTS2 region-year panel, ",
  format(nrow(df), big.mark = ","), " observations across ", uniqueN(df$geo), " regions in ", uniqueN(df$country), " countries. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with not-yet-treated control group; standard errors from 1,000 bootstrap iterations clustered at the country level (27 clusters). ",
  "\\textbf{Sample:} NUTS2 regions with at least 6 years of non-missing NACE J employment data; excludes regions with zero ICT employment. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
cat("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\textit{Panel A: Pooled} & & & & & & \\\\[0.3em]\n",
file = "tables/tabF1_sde.tex")

for (i in 1:nrow(sde_pooled)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              sde_pooled$Outcome[i],
              formatC(sde_pooled$beta[i], format = "f", digits = 4),
              formatC(sde_pooled$se[i], format = "f", digits = 4),
              formatC(sde_pooled$sd_y[i], format = "f", digits = 4),
              formatC(sde_pooled$sde[i], format = "f", digits = 4),
              formatC(sde_pooled$se_sde[i], format = "f", digits = 4),
              sde_pooled$classification[i]),
      file = "tables/tabF1_sde.tex", append = TRUE)
}

cat("\\\\[-0.3em]
\\textit{Panel B: Heterogeneous (Early vs.\\ Late Adopters)} & & & & & & \\\\[0.3em]\n",
file = "tables/tabF1_sde.tex", append = TRUE)

for (i in 1:nrow(sde_het)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              sde_het$Outcome[i],
              formatC(sde_het$beta[i], format = "f", digits = 4),
              formatC(sde_het$se[i], format = "f", digits = 4),
              formatC(sde_het$sd_y[i], format = "f", digits = 4),
              formatC(sde_het$sde[i], format = "f", digits = 4),
              formatC(sde_het$se_sde[i], format = "f", digits = 4),
              sde_het$classification[i]),
      file = "tables/tabF1_sde.tex", append = TRUE)
}

cat(paste0("\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
", sde_notes, "
\\end{tablenotes}
\\end{table}\n"),
file = "tables/tabF1_sde.tex", append = TRUE)

message("  Saved: tables/tabF1_sde.tex")

message("\n=== All tables generated ===")
message("Files in tables/:")
message(paste(" ", list.files("tables/"), collapse = "\n"))
