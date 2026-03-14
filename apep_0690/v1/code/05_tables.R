## 05_tables.R — Generate all LaTeX tables
## Paper: apep_0690 — UK Office-to-Residential PD Rights

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

load("regression_results.RData")
load("robustness_results.RData")
if (file.exists("price_results.RData")) load("price_results.RData")
if (file.exists("price_robustness.RData")) load("price_robustness.RData")

tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

panel_clean <- panel[!is.na(office_share)]

# Full panel summary
vars_list <- c("net_additions", "additions_pc", "new_build", "pdr_office",
               "office_share", "AveragePrice", "FlatPrice")

make_sumstat_row <- function(varname, label, data, subset_expr = TRUE) {
  d <- data[eval(parse(text = as.character(subset_expr)))]
  x <- d[[varname]]
  x <- x[!is.na(x)]
  sprintf("%s & %s & %.1f & %.1f & %.1f & %.1f \\\\",
          label, format(length(x), big.mark = ","),
          mean(x), sd(x), min(x), max(x))
}

sumstat_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lrrrrr}",
  "\\hline\\hline",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Housing Supply (2012--2024)}} \\\\",
  sprintf("Net additional dwellings & %s & %.1f & %.1f & %.0f & %.0f \\\\",
          format(sum(!is.na(panel_clean$net_additions)), big.mark = ","),
          mean(panel_clean$net_additions, na.rm = TRUE),
          sd(panel_clean$net_additions, na.rm = TRUE),
          min(panel_clean$net_additions, na.rm = TRUE),
          max(panel_clean$net_additions, na.rm = TRUE)),
  sprintf("Additions per 1,000 pop. & %s & %.2f & %.2f & %.2f & %.2f \\\\",
          format(sum(!is.na(panel_clean$additions_pc)), big.mark = ","),
          mean(panel_clean$additions_pc, na.rm = TRUE),
          sd(panel_clean$additions_pc, na.rm = TRUE),
          min(panel_clean$additions_pc, na.rm = TRUE),
          max(panel_clean$additions_pc, na.rm = TRUE)),
  sprintf("New build dwellings & %s & %.1f & %.1f & %.0f & %.0f \\\\",
          format(sum(!is.na(panel_clean$new_build)), big.mark = ","),
          mean(panel_clean$new_build, na.rm = TRUE),
          sd(panel_clean$new_build, na.rm = TRUE),
          min(panel_clean$new_build, na.rm = TRUE),
          max(panel_clean$new_build, na.rm = TRUE)),
  sprintf("PDR office-to-residential & %s & %.1f & %.1f & %.0f & %.0f \\\\",
          format(sum(!is.na(panel_clean$pdr_office)), big.mark = ","),
          mean(panel_clean$pdr_office, na.rm = TRUE),
          sd(panel_clean$pdr_office, na.rm = TRUE),
          min(panel_clean$pdr_office, na.rm = TRUE),
          max(panel_clean$pdr_office, na.rm = TRUE)),
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel B: Treatment Variable}} \\\\",
  sprintf("Office floorspace share & %s & %.3f & %.3f & %.3f & %.3f \\\\",
          format(sum(!is.na(panel_clean$office_share)), big.mark = ","),
          mean(panel_clean$office_share, na.rm = TRUE),
          sd(panel_clean$office_share, na.rm = TRUE),
          min(panel_clean$office_share, na.rm = TRUE),
          max(panel_clean$office_share, na.rm = TRUE)),
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel C: House Prices (\\pounds)}} \\\\",
  sprintf("Average price & %s & %s & %s & %s & %s \\\\",
          format(sum(!is.na(panel_clean$AveragePrice)), big.mark = ","),
          format(round(mean(panel_clean$AveragePrice, na.rm = TRUE)), big.mark = ","),
          format(round(sd(panel_clean$AveragePrice, na.rm = TRUE)), big.mark = ","),
          format(round(min(panel_clean$AveragePrice, na.rm = TRUE)), big.mark = ","),
          format(round(max(panel_clean$AveragePrice, na.rm = TRUE)), big.mark = ",")),
  sprintf("Flat price & %s & %s & %s & %s & %s \\\\",
          format(sum(!is.na(panel_clean$FlatPrice)), big.mark = ","),
          format(round(mean(panel_clean$FlatPrice, na.rm = TRUE)), big.mark = ","),
          format(round(sd(panel_clean$FlatPrice, na.rm = TRUE)), big.mark = ","),
          format(round(min(panel_clean$FlatPrice, na.rm = TRUE)), big.mark = ","),
          format(round(max(panel_clean$FlatPrice, na.rm = TRUE)), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize",
  "\\textit{Notes:} Panel of 296 English local authorities, 2012--2024. Housing supply data from MHCLG Live Table 123. PDR office-to-residential available from 2015--16 onward. Office floorspace share from VOA Non-Domestic Rating Statistics (2025). House prices from the UK House Price Index (Land Registry). Additions per 1,000 population uses ONS mid-year population estimates.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(sumstat_lines, file.path(tables_dir, "tab1_sumstats.tex"))

# ============================================================
# Table 2: Main Bartik DiD Results
# ============================================================
cat("Generating Table 2: Main Results\n")

etable(m1, m2, m3, m4,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main.tex"),
       replace = TRUE,
       title = "Effect of Office Floorspace Exposure on Housing Supply",
       label = "tab:main",
       headers = c("Net Additions", "Log Additions", "Add./1K Pop", "Log Add./1K"),
       dict = c(office_x_post = "Office Share $\\times$ Post"),
       notes = c(
         "Panel of 296 English local authorities, 2012--2024. Office Share is the pre-existing share of non-domestic floorspace classified as offices (VOA 2025). Post equals one from 2013--14 onward (Class J PD rights introduction). Standard errors clustered at the local authority level in parentheses.",
         "Columns 3--4 drop observations with missing population data."
       ),
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# ============================================================
# Table 3: Price Effects
# ============================================================
cat("Generating Table 3: Price Effects\n")

if (exists("m_avg") && exists("m_flat")) {
  etable(m_avg, m_flat, m_det, m_ter,
         tex = TRUE,
         file = file.path(tables_dir, "tab3_prices.tex"),
         replace = TRUE,
         title = "Effect of Office Floorspace Exposure on House Prices",
         label = "tab:prices",
         headers = c("Average", "Flat", "Detached", "Terraced"),
         dict = c(office_x_post = "Office Share $\\times$ Post"),
         notes = c(
           "Dependent variable is the log of annual average price by local authority and property type, from the UK House Price Index (Land Registry). Office Share and Post defined as in Table \\ref{tab:main}. Standard errors clustered at the local authority level."
         ),
         se.below = TRUE,
         signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))
}

# ============================================================
# Table 4: Robustness — Quartile Effects and Composition
# ============================================================
cat("Generating Table 4: Robustness\n")

etable(m_q_supply, m_comp1, m_fs1, m_placebo_nb,
       tex = TRUE,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       replace = TRUE,
       title = "Robustness: Quartile Effects, Composition, and Placebo",
       label = "tab:robustness",
       headers = c("Add./1K (Quartiles)", "PDR Office Share", "First Stage", "Placebo: New Build"),
       dict = c(
         q2_post = "Q2 $\\times$ Post",
         q3_post = "Q3 $\\times$ Post",
         q4_post = "Q4 $\\times$ Post",
         office_share = "Office Share",
         office_x_post = "Office Share $\\times$ Post"
       ),
       notes = c(
         "Column 1: Quartile dummies of office floorspace share interacted with Post (Q1 = lowest office share is reference). Column 2: PDR office-to-residential share of total additions regressed on office share (2015--2024 only). Column 3: First stage showing office share predicts PDR conversion levels. Column 4: Placebo test using new-build dwellings (should not respond to office stock). All regressions include year fixed effects; columns 1 and 4 also include LA fixed effects. Standard errors clustered at LA level."
       ),
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# ============================================================
# Table 5: Event Study Coefficients
# ============================================================
cat("Generating Table 5: Event Study\n")

es_tab <- es_coefs[, .(
  Year = event_year + 2013,
  `Event Time` = event_year,
  Estimate = sprintf("%.3f", estimate),
  SE = sprintf("(%.3f)", std.error),
  Stars = fifelse(p.value < 0.01, "***",
          fifelse(p.value < 0.05, "**",
          fifelse(p.value < 0.1, "*", "")))
)]

es_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Bartik Coefficients}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{cccc}",
  "\\hline\\hline",
  "Year & Event Time & $\\hat{\\beta}_k$ & SE \\\\",
  "\\hline",
  "2012 & $-1$ & \\multicolumn{2}{c}{(reference)} \\\\",
  paste0(es_tab$Year, " & ", es_tab$`Event Time`, " & ",
         es_tab$Estimate, es_tab$Stars, " & ", es_tab$SE, " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize",
  "\\textit{Notes:} Dependent variable is net additional dwellings per 1,000 population. Each coefficient is the interaction of office floorspace share with a year indicator, normalized to the pre-treatment year 2012 ($k = -1$). LA and year fixed effects included. Standard errors clustered at the LA level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(es_lines, file.path(tables_dir, "tab5_eventstudy.tex"))

# ============================================================
# SDE Table (Appendix)
# ============================================================
cat("Generating SDE Table\n")

# Compute standardized effect sizes
sde_data <- data.table(
  outcome = c("Net additions", "Additions per 1K pop",
              "Log average price", "Log flat price"),
  beta = c(coef(m1)["office_x_post"],
           coef(m3)["office_x_post"],
           coef(m_avg)["office_x_post"],
           coef(m_flat)["office_x_post"]),
  se_beta = c(se(m1)["office_x_post"],
              se(m3)["office_x_post"],
              se(m_avg)["office_x_post"],
              se(m_flat)["office_x_post"]),
  sd_y = c(sd(panel$net_additions, na.rm = TRUE),
           sd(panel$additions_pc, na.rm = TRUE),
           sd(panel$log_AveragePrice, na.rm = TRUE),
           sd(panel$log_FlatPrice, na.rm = TRUE)),
  sd_x = rep(sd(panel$office_share, na.rm = TRUE), 4)
)

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_data[, sde := beta * sd_x / sd_y]
sde_data[, se_sde := se_beta * sd_x / sd_y]

# Classification
classify_sde <- function(s) {
  if (is.na(s)) return("--")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_data[, classification := sapply(sde, classify_sde)]

sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  apply(sde_data, 1, function(row) {
    sprintf("%s & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\",
            row["outcome"],
            as.numeric(row["beta"]), as.numeric(row["se_beta"]),
            as.numeric(row["sd_y"]),
            as.numeric(row["sde"]), as.numeric(row["se_sde"]),
            row["classification"])
  }),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize",
  "\\textit{Notes:} This paper estimates the effect of office floorspace exposure (Bartik-style continuous treatment) on local housing supply and prices in England following the 2013 Class J permitted development rights reform. The identification strategy uses a panel of 296 local authorities over 2012--2024 with LA and year fixed effects, clustering standard errors at the LA level. The sample contains 3,746 LA-year observations. Treatment is continuous (office floorspace share); SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. Classification refers to magnitude of the standardized effect, not statistical significance.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in:", tables_dir, "\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
