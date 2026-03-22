## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")
data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel_final.rds"))
main_results <- readRDS(file.path(data_dir, "main_results.rds"))
controlled <- readRDS(file.path(data_dir, "controlled_results.rds"))
triple <- readRDS(file.path(data_dir, "triple_results.rds"))
precovid <- readRDS(file.path(data_dir, "precovid_results.rds"))
nocovid <- readRDS(file.path(data_dir, "nocovid_results.rds"))
summ <- readRDS(file.path(data_dir, "summary_stats.rds"))

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

pre <- panel %>% filter(post == 0)

vars <- c("total_rate", "theft_rate", "violence_rate", "robbery_rate",
          "damage_rate", "shoplifting_rate", "drugs_rate", "betting_density", "food_density")
var_labels <- c("Total crime rate", "Theft rate", "Violence rate", "Robbery rate",
                "Criminal damage rate", "Shoplifting rate", "Drug offence rate",
                "Betting shop density", "Food service density")

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Crime rates (per 10,000 population, quarterly)}} \\\\"
)

for (i in 1:7) {
  v <- vars[i]
  vals <- pre[[v]]
  tab1_lines <- c(tab1_lines, sprintf("%s & %.1f & %.1f & %.1f & %.1f \\\\",
    var_labels[i], mean(vals, na.rm=T), sd(vals, na.rm=T),
    min(vals, na.rm=T), max(vals, na.rm=T)))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treatment intensity (per 10,000 population)}} \\\\")

for (i in 8:9) {
  v <- vars[i]
  vals <- pre[[v]]
  if (all(is.na(vals))) vals <- panel[[v]]
  tab1_lines <- c(tab1_lines, sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
    var_labels[i], mean(vals, na.rm=T), sd(vals, na.rm=T),
    min(vals, na.rm=T), max(vals, na.rm=T)))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\begin{tablenotes}[flushleft]\\footnotesize"),
  sprintf("\\item \\textit{Notes:} Pre-treatment period (Q2 2015--Q1 2019), %d police force areas. Crime rates are quarterly recorded offences per 10,000 resident population. Betting shop density is the mean 2016--2018 count of SIC 92 (Gambling and betting) local business units per 10,000 population, aggregated from local authorities to police force areas using NOMIS UK Business Counts. Food service density is SIC 56 (Food and beverage service activities) businesses per 10,000 population.",
    length(unique(pre$force))),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main DiD + Controlled Specification
# ============================================================================
cat("=== Generating Table 2: Main Results ===\n")

outcome_names <- c("total_rate", "theft_rate", "violence_rate",
                   "shoplifting_rate", "damage_rate", "drugs_rate")
col_labels <- c("Total", "Theft", "Violence", "Shoplifting", "Damage", "Drugs")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of FOBT Stake Reduction on Crime Rates}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  sprintf("\\begin{adjustbox}{max width=\\textwidth}"),
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(col_labels)), collapse="")),
  "\\toprule",
  paste0(" & ", paste(col_labels, collapse=" & "), " \\\\"),
  paste0(" & ", paste(paste0("(", 1:length(col_labels), ")"), collapse=" & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Baseline DiD}} \\\\"
)

# Panel A: uncontrolled
row_beta <- " Betting density $\\times$ Post"
row_se <- ""
for (v in outcome_names) {
  b <- coef(main_results[[v]])[1]
  s <- se(main_results[[v]])[1]
  p <- pvalue(main_results[[v]])[1]
  row_beta <- paste0(row_beta, sprintf(" & %.3f%s", b, stars(p)))
  row_se <- paste0(row_se, sprintf(" & (%.3f)", s))
}
tab2_lines <- c(tab2_lines, paste0(row_beta, " \\\\"), paste0(row_se, " \\\\"))

# Panel B: controlled
tab2_lines <- c(tab2_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Controlled for food service density}} \\\\"
)

row_beta <- " Betting density $\\times$ Post"
row_se <- ""
row_food <- " Food density $\\times$ Post"
row_food_se <- ""
for (v in outcome_names) {
  b <- coef(controlled[[v]])[1]
  s <- se(controlled[[v]])[1]
  p <- pvalue(controlled[[v]])[1]
  row_beta <- paste0(row_beta, sprintf(" & %.3f%s", b, stars(p)))
  row_se <- paste0(row_se, sprintf(" & (%.3f)", s))
  bf <- coef(controlled[[v]])[2]
  sf <- se(controlled[[v]])[2]
  pf <- pvalue(controlled[[v]])[2]
  row_food <- paste0(row_food, sprintf(" & %.3f%s", bf, stars(pf)))
  row_food_se <- paste0(row_food_se, sprintf(" & (%.3f)", sf))
}
tab2_lines <- c(tab2_lines,
  paste0(row_beta, " \\\\"), paste0(row_se, " \\\\"),
  paste0(row_food, " \\\\"), paste0(row_food_se, " \\\\"))

# Footer
tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Observations & %s \\\\",
    paste(rep(format(nrow(panel), big.mark=","), length(col_labels)), collapse=" & ")),
  sprintf("PFAs & %s \\\\",
    paste(rep(length(unique(panel$force)), length(col_labels)), collapse=" & ")),
  "PFA FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{6}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Each column reports a separate regression of the quarterly crime rate (per 10,000) on betting shop density (pre-treatment mean per 10,000) interacted with a post-April-2019 indicator. Panel B adds food service density (SIC 56) interacted with post as a control for general business density trends. Standard errors clustered at the PFA level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Triple-Difference
# ============================================================================
cat("=== Generating Table 3: Triple-Difference ===\n")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple-Difference: Acquisitive vs.\\ Non-Acquisitive Crime}",
  "\\label{tab:triple}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Theft vs.\\ Violence & Shoplifting vs.\\ Drugs \\\\",
  " & (1) & (2) \\\\",
  "\\midrule"
)

# Theft vs Violence
tv <- triple$theft_vs_violence
b_tv <- coef(tv)["triple"]
se_tv <- se(tv)["triple"]
p_tv <- pvalue(tv)["triple"]
b2_tv <- coef(tv)["bet_post"]
se2_tv <- se(tv)["bet_post"]
p2_tv <- pvalue(tv)["bet_post"]

# Shoplifting vs Drugs
sd_mod <- triple$shoplifting_vs_drugs
b_sd <- coef(sd_mod)["triple"]
se_sd <- se(sd_mod)["triple"]
p_sd <- pvalue(sd_mod)["triple"]
b2_sd <- coef(sd_mod)["bet_post"]
se2_sd <- se(sd_mod)["bet_post"]
p2_sd <- pvalue(sd_mod)["bet_post"]

tab3_lines <- c(tab3_lines,
  sprintf("Acquisitive $\\times$ Density $\\times$ Post & %.3f%s & %.3f%s \\\\",
          b_tv, stars(p_tv), b_sd, stars(p_sd)),
  sprintf(" & (%.3f) & (%.3f) \\\\", se_tv, se_sd),
  sprintf("Density $\\times$ Post & %.3f%s & %.3f%s \\\\",
          b2_tv, stars(p2_tv), b2_sd, stars(p2_sd)),
  sprintf(" & (%.3f) & (%.3f) \\\\", se2_tv, se2_sd),
  "\\midrule",
  sprintf("Observations & %s & %s \\\\",
    format(nobs(tv), big.mark=","), format(nobs(sd_mod), big.mark=",")),
  "PFA $\\times$ Crime FE & Yes & Yes \\\\",
  "Quarter $\\times$ Crime FE & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} Triple-difference regressions. Column (1) stacks theft and violence rates; column (2) stacks shoplifting and drug offence rates. The triple interaction tests whether acquisitive crime changed differentially relative to non-acquisitive crime in areas with higher pre-treatment betting density after April 2019. Negative coefficients indicate that acquisitive crime fell more (or rose less) than non-acquisitive crime. Standard errors clustered at PFA level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab3_lines, file.path(table_dir, "tab3_triple.tex"))

# ============================================================================
# Table 4: Robustness — Pre-COVID and No-COVID
# ============================================================================
cat("=== Generating Table 4: Robustness ===\n")

rob_outcomes <- c("theft_rate", "violence_rate", "shoplifting_rate", "drugs_rate")
rob_labels <- c("Theft", "Violence", "Shoplifting", "Drugs")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Alternative Sample Windows}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", 4), collapse="")),
  "\\toprule",
  paste0(" & ", paste(rob_labels, collapse=" & "), " \\\\"),
  paste0(" & ", paste(paste0("(", 1:4, ")"), collapse=" & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Full sample (controlled)}} \\\\"
)

# Panel A: full controlled
row <- " Betting density $\\times$ Post"
row_se_txt <- ""
for (v in rob_outcomes) {
  b <- coef(controlled[[v]])[1]; s <- se(controlled[[v]])[1]; p <- pvalue(controlled[[v]])[1]
  row <- paste0(row, sprintf(" & %.3f%s", b, stars(p)))
  row_se_txt <- paste0(row_se_txt, sprintf(" & (%.3f)", s))
}
tab4_lines <- c(tab4_lines, paste0(row, " \\\\"), paste0(row_se_txt, " \\\\"))

# Panel B: Pre-COVID
tab4_lines <- c(tab4_lines, "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Pre-COVID (Q2 2015--Q1 2020)}} \\\\")
row <- " Betting density $\\times$ Post"
row_se_txt <- ""
for (v in rob_outcomes) {
  b <- coef(precovid[[v]])[1]; s <- se(precovid[[v]])[1]; p <- pvalue(precovid[[v]])[1]
  row <- paste0(row, sprintf(" & %.3f%s", b, stars(p)))
  row_se_txt <- paste0(row_se_txt, sprintf(" & (%.3f)", s))
}
tab4_lines <- c(tab4_lines, paste0(row, " \\\\"), paste0(row_se_txt, " \\\\"))

# Panel C: Excl COVID
tab4_lines <- c(tab4_lines, "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel C: Excluding COVID quarters (Q2 2020--Q1 2021)}} \\\\")
row <- " Betting density $\\times$ Post"
row_se_txt <- ""
for (v in rob_outcomes) {
  b <- coef(nocovid[[v]])[1]; s <- se(nocovid[[v]])[1]; p <- pvalue(nocovid[[v]])[1]
  row <- paste0(row, sprintf(" & %.3f%s", b, stars(p)))
  row_se_txt <- paste0(row_se_txt, sprintf(" & (%.3f)", s))
}
tab4_lines <- c(tab4_lines, paste0(row, " \\\\"), paste0(row_se_txt, " \\\\"))

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "Food density control & \\multicolumn{4}{c}{Yes} \\\\",
  "PFA FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{4}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  "\\item \\textit{Notes:} All specifications include food service density $\\times$ post control, PFA and quarter fixed effects, with standard errors clustered at the PFA level. Panel B restricts to quarters before Q2 2020 (before COVID lockdowns). Panel C drops the four COVID quarters (Q2 2020--Q1 2021). $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab4_lines, file.path(table_dir, "tab4_robust.tex"))

# ============================================================================
# Table F1: Standardized Effect Size (SDE)
# ============================================================================
cat("=== Generating SDE Table ===\n")

# Compute SDE for key outcomes using the controlled specification
pre_data <- panel %>% filter(post == 0)

sde_outcomes <- c("theft_rate", "violence_rate", "shoplifting_rate", "drugs_rate")
sde_labels <- c("Theft offences", "Violence against person",
                "Shoplifting", "Drug offences")

sde_rows <- list()
for (i in seq_along(sde_outcomes)) {
  v <- sde_outcomes[i]
  beta <- coef(controlled[[v]])[1]
  se_beta <- se(controlled[[v]])[1]
  sd_y <- sd(pre_data[[v]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classification <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )

  sde_rows[[i]] <- data.frame(
    outcome = sde_labels[i],
    beta = beta, se = se_beta, sd_y = sd_y,
    sde = sde, se_sde = se_sde,
    classification = classification,
    stringsAsFactors = FALSE
  )
}

sde_df <- bind_rows(sde_rows)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Does the reduction of fixed odds betting terminal maximum stakes from 100 to 2 pounds affect neighborhood crime composition? ",
  "\\textbf{Policy mechanism:} The April 2019 FOBT stake reduction eliminated high-stakes electronic roulette gambling in betting shops, ",
  "reducing gambling revenue by approximately 50 percent and triggering over 700 betting shop closures within two years. ",
  "\\textbf{Outcome definition:} Quarterly police-recorded offences per 10,000 resident population by offence group, as published in Home Office Police Recorded Crime open data tables. ",
  "\\textbf{Treatment:} Continuous; pre-treatment (2016--2018 mean) gambling and betting business establishments (SIC 92) per 10,000 population at the police force area level. ",
  "\\textbf{Data:} Home Office Police Recorded Crime PFA tables (2015--2025) merged with NOMIS UK Business Counts and mid-year population estimates, 38 police force areas, 40 quarters. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with food service density control, PFA and quarter fixed effects, standard errors clustered at PFA level. ",
  "\\textbf{Sample:} All geographic police force areas in England and Wales excluding City of London (extreme outlier with 61 businesses per 10,000 vs next highest 4.2). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_df)) {
  r <- sde_df[i, ]
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_lines <- c(sde_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(sde_lines, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files:", paste(list.files(table_dir, pattern = "\\.tex$"), collapse = ", "), "\n")
