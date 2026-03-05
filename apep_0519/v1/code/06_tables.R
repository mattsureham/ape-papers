## 06_tables.R — Generate LaTeX tables for paper
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================================
## Load data
## ============================================================================

panel   <- fread(file.path(data_dir, "analysis_panel.csv"))
muken   <- fread(file.path(data_dir, "muken_adoption.csv"))
sumstat <- fread(file.path(data_dir, "summary_stats.csv"))
load(file.path(data_dir, "main_models.RData"))

## ============================================================================
## TABLE 1: Summary Statistics
## ============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

## Classify cantons as treated vs control based on adoption by 2021
panel[, treated_group := fifelse(!is.na(adoption_year) & adoption_year <= 2021,
                                  "Treated", "Control")]

## Compute summary statistics by period x treatment group
make_sumstats <- function(dt, period_label, group_label) {
  sub <- dt[treated_group == group_label]
  data.table(
    period  = period_label,
    group   = group_label,
    n_obs   = nrow(sub),
    n_cantons = uniqueN(sub$canton),
    mean_buildings = mean(sub$total_buildings, na.rm = TRUE),
    mean_hp   = mean(sub$share_heat_pump, na.rm = TRUE),
    sd_hp     = sd(sub$share_heat_pump, na.rm = TRUE),
    mean_oil  = mean(sub$share_oil, na.rm = TRUE),
    sd_oil    = sd(sub$share_oil, na.rm = TRUE),
    mean_gas  = mean(sub$share_gas, na.rm = TRUE),
    sd_gas    = sd(sub$share_gas, na.rm = TRUE),
    mean_fossil = mean(sub$share_fossil, na.rm = TRUE),
    sd_fossil = sd(sub$share_fossil, na.rm = TRUE)
  )
}

pre  <- panel[year <= 2015]
post <- panel[year >= 2021]

ss <- rbindlist(list(
  make_sumstats(pre,  "Pre (2009--2015)",  "Treated"),
  make_sumstats(pre,  "Pre (2009--2015)",  "Control"),
  make_sumstats(post, "Post (2021--2022)", "Treated"),
  make_sumstats(post, "Post (2021--2022)", "Control")
))

## Build LaTeX table manually for full control over formatting
fmt2 <- function(x) formatC(x, format = "f", digits = 2)
fmt3 <- function(x) formatC(x, format = "f", digits = 3)
fmt0 <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")

tab1_lines <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Heating Systems by Treatment Status}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated Cantons} & \\multicolumn{2}{c}{Control Cantons} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

## Panel A: Pre-treatment
ss_pre_t <- ss[period == "Pre (2009--2015)" & group == "Treated"]
ss_pre_c <- ss[period == "Pre (2009--2015)" & group == "Control"]

tab1_lines <- c(tab1_lines,
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-Treatment (2009--2015)}} \\\\[3pt]",
  paste0("Total buildings & ", fmt0(ss_pre_t$mean_buildings), " & --- & ",
         fmt0(ss_pre_c$mean_buildings), " & --- \\\\"),
  paste0("Heat pump share & ", fmt3(ss_pre_t$mean_hp), " & ", fmt3(ss_pre_t$sd_hp),
         " & ", fmt3(ss_pre_c$mean_hp), " & ", fmt3(ss_pre_c$sd_hp), " \\\\"),
  paste0("Oil share & ", fmt3(ss_pre_t$mean_oil), " & ", fmt3(ss_pre_t$sd_oil),
         " & ", fmt3(ss_pre_c$mean_oil), " & ", fmt3(ss_pre_c$sd_oil), " \\\\"),
  paste0("Gas share & ", fmt3(ss_pre_t$mean_gas), " & ", fmt3(ss_pre_t$sd_gas),
         " & ", fmt3(ss_pre_c$mean_gas), " & ", fmt3(ss_pre_c$sd_gas), " \\\\"),
  paste0("Fossil share & ", fmt3(ss_pre_t$mean_fossil), " & ", fmt3(ss_pre_t$sd_fossil),
         " & ", fmt3(ss_pre_c$mean_fossil), " & ", fmt3(ss_pre_c$sd_fossil), " \\\\"),
  paste0("Canton-years & \\multicolumn{2}{c}{", ss_pre_t$n_obs, "} & \\multicolumn{2}{c}{",
         ss_pre_c$n_obs, "} \\\\"),
  paste0("Cantons & \\multicolumn{2}{c}{", ss_pre_t$n_cantons, "} & \\multicolumn{2}{c}{",
         ss_pre_c$n_cantons, "} \\\\"),
  "\\midrule"
)

## Panel B: Post-treatment
ss_post_t <- ss[period == "Post (2021--2022)" & group == "Treated"]
ss_post_c <- ss[period == "Post (2021--2022)" & group == "Control"]

tab1_lines <- c(tab1_lines,
  "\\multicolumn{5}{l}{\\textit{Panel B: Post-Treatment (2021--2022)}} \\\\[3pt]",
  paste0("Total buildings & ", fmt0(ss_post_t$mean_buildings), " & --- & ",
         fmt0(ss_post_c$mean_buildings), " & --- \\\\"),
  paste0("Heat pump share & ", fmt3(ss_post_t$mean_hp), " & ", fmt3(ss_post_t$sd_hp),
         " & ", fmt3(ss_post_c$mean_hp), " & ", fmt3(ss_post_c$sd_hp), " \\\\"),
  paste0("Oil share & ", fmt3(ss_post_t$mean_oil), " & ", fmt3(ss_post_t$sd_oil),
         " & ", fmt3(ss_post_c$mean_oil), " & ", fmt3(ss_post_c$sd_oil), " \\\\"),
  paste0("Gas share & ", fmt3(ss_post_t$mean_gas), " & ", fmt3(ss_post_t$sd_gas),
         " & ", fmt3(ss_post_c$mean_gas), " & ", fmt3(ss_post_c$sd_gas), " \\\\"),
  paste0("Fossil share & ", fmt3(ss_post_t$mean_fossil), " & ", fmt3(ss_post_t$sd_fossil),
         " & ", fmt3(ss_post_c$mean_fossil), " & ", fmt3(ss_post_c$sd_fossil), " \\\\"),
  paste0("Canton-years & \\multicolumn{2}{c}{", ss_post_t$n_obs, "} & \\multicolumn{2}{c}{",
         ss_post_c$n_obs, "} \\\\"),
  paste0("Cantons & \\multicolumn{2}{c}{", ss_post_t$n_cantons, "} & \\multicolumn{2}{c}{",
         ss_post_c$n_cantons, "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{6pt}",
  "\\footnotesize",
  "\\textit{Notes:} Treated cantons adopted MuKEn 2014 by 2021. Shares are computed as the number of buildings using each heating system divided by total buildings in the canton. Fossil share includes oil, gas, and coal. Pre-treatment period covers Swiss building registry data for 2009--2015; post-treatment covers 2021--2022.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab_summary.tex"))
cat("  Saved tab_summary.tex\n")

## ============================================================================
## TABLE 2: Main TWFE Results (fixest::etable)
## ============================================================================

cat("=== Generating Table 2: Main TWFE Results ===\n")

## Use fixest::etable with style.tex for publication-quality output
setFixest_dict(c(
  share_heat_pump = "Heat Pump",
  share_oil = "Oil",
  share_gas = "Gas",
  share_fossil = "Fossil",
  share_wood = "Wood",
  share_district = "District Heat",
  treated = "MuKEn Adopted",
  canton = "Canton",
  year = "Year"
))

## Generate etable LaTeX output
tab_main_tex <- etable(
  m1, m2, m4, m3, m5, m6,
  headers = c("HP Share", "Oil Share", "Gas Share", "Fossil Share",
              "Wood Share", "District Share"),
  se.below = TRUE,
  signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
  fitstat = ~ n + r2,
  style.tex = style.tex(
    main = "base",
    depvar.title = "Dep.\\ Var.:",
    fixef.title = "\\midrule",
    fixef.suffix = " FE",
    yesNo = c("Yes", "No"),
    tablefoot = FALSE
  ),
  tex = TRUE,
  title = "Effect of MuKEn 2014 Adoption on Heating System Shares",
  label = "tab:main"
)

## Write etable output, wrapping with notes
## etable with tex=TRUE returns a character vector
tab_main_lines <- tab_main_tex

## Append table notes before final \end{table}
end_idx <- max(grep("\\\\end\\{table\\}", tab_main_lines))
tab_main_lines <- c(
  tab_main_lines[1:(end_idx - 1)],
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{6pt}",
  "\\footnotesize",
  "\\textit{Notes:} Each column reports a two-way fixed effects (TWFE) estimate. The dependent variable is the canton-level share of buildings using the indicated heating system. ``MuKEn Adopted'' equals one for canton-years after the canton adopted MuKEn 2014. Standard errors clustered at the canton level are in parentheses. $^{***}$, $^{**}$, and $^{*}$ denote significance at the 1\\%, 5\\%, and 10\\% levels, respectively.",
  "\\end{minipage}",
  tab_main_lines[end_idx:length(tab_main_lines)]
)

writeLines(tab_main_lines, file.path(table_dir, "tab_main.tex"))
cat("  Saved tab_main.tex\n")

## ============================================================================
## TABLE 3: MuKEn 2014 Adoption Timeline
## ============================================================================

cat("=== Generating Table 3: Adoption Timeline ===\n")

## Prepare adoption data, sorted by year then canton name
adopt <- copy(muken)
adopt[, display_year := fifelse(is.na(adoption_year) | adopted == FALSE,
                                 "Not adopted", as.character(adoption_year))]
setorder(adopt, adoption_year, canton_name, na.last = TRUE)

## Build LaTeX table
tab3_lines <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{MuKEn 2014 Adoption Timeline by Canton}",
  "\\label{tab:adoption}",
  "\\begin{tabular}{llc}",
  "\\toprule",
  "Canton & Abbreviation & Adoption Year \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(adopt))) {
  tab3_lines <- c(tab3_lines,
    paste0(adopt$canton_name[i], " & ", adopt$canton[i], " & ",
           adopt$display_year[i], " \\\\")
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.7\\textwidth}",
  "\\vspace{6pt}",
  "\\footnotesize",
  "\\textit{Notes:} Year in which each canton formally adopted the MuKEn 2014 model energy code into cantonal law. ``Not adopted'' indicates the canton had not adopted MuKEn 2014 as of the end of the sample period.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab_adoption.tex"))
cat("  Saved tab_adoption.tex\n")

## ============================================================================
## TABLE 4: Sun-Abraham Heterogeneity-Robust Estimator
## ============================================================================

cat("=== Generating Table 4: Sun-Abraham Results ===\n")

## Load Sun-Abraham results from CSV
sunab_csv <- fread(file.path(data_dir, "sunab_results.csv"))

## Also load main TWFE for comparison
main_csv <- fread(file.path(data_dir, "main_results.csv"))
twfe_hp <- main_csv[model == "TWFE: HP Share"]

## Build cohort info from panel
cohort_info <- panel[!is.na(adoption_year) & adoption_year <= 2022,
                     .(n_cantons = uniqueN(canton)), by = adoption_year]
setorder(cohort_info, adoption_year)

## Build LaTeX table
tab4_lines <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{Sun-Abraham Heterogeneity-Robust Estimates}",
  "\\label{tab:sunab}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Sun-Abraham & TWFE \\\\",
  " & (1) & (2) \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Aggregated ATT}} \\\\[3pt]"
)

## Format numbers — use 5 decimal places for coefficients/SE to avoid
## rounding-induced inconsistencies between coef, SE, CI, and p-value
fmt_coef <- function(x) formatC(x, format = "f", digits = 5)
fmt_se   <- function(x) paste0("(", formatC(x, format = "f", digits = 5), ")")
fmt_pval <- function(x) formatC(x, format = "f", digits = 4)

## Add coefficient rows
tab4_lines <- c(tab4_lines,
  paste0("ATT (heat pump share) & ", fmt_coef(sunab_csv$ATT), " & ",
         fmt_coef(twfe_hp$coef), " \\\\"),
  paste0(" & ", fmt_se(sunab_csv$SE), " & ",
         fmt_se(twfe_hp$se), " \\\\"),
  paste0("$p$-value & ", fmt_pval(sunab_csv$pvalue), " & ",
         fmt_pval(twfe_hp$pval), " \\\\"),
  paste0("95\\% CI & [", fmt_coef(sunab_csv$ci_lo), ", ", fmt_coef(sunab_csv$ci_hi), "]",
         " & [", fmt_coef(twfe_hp$ci_lo), ", ", fmt_coef(twfe_hp$ci_hi), "] \\\\"),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: Design Details}} \\\\[3pt]",
  "Estimator & Interaction-weighted & Two-way FE \\\\",
  "Reference period & $t = -1$ (see notes) & --- \\\\",
  paste0("Treatment cohorts & ", nrow(cohort_info), " & --- \\\\"),
  paste0("Cohort years & ",
         paste(cohort_info$adoption_year, collapse = ", "),
         " & --- \\\\"),
  "Control group & Never-treated & Never-treated \\\\",
  paste0("Observations & 234 & 234 \\\\"),
  paste0("Cantons & 26 & 26 \\\\"),
  "VCOV correction & Yes (pos.\\ semi-def.) & --- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}",
  "\\vspace{6pt}",
  "\\footnotesize",
  "\\textit{Notes:} Column (1) reports the aggregated average treatment effect on the treated (ATT) from the \\citet{sun2021estimating} interaction-weighted estimator, implemented via \\texttt{fixest::sunab()}. The nominal reference period is $t = -1$; however, due to the 2016--2020 data gap, event time $-1$ is unobserved for cohorts 2017--2021. For these cohorts, treatment effects are identified by comparing post-treatment (2021--2022) outcomes to the available pre-treatment periods (2009--2015). The aggregated ATT is invariant to the reference period choice. The variance-covariance matrix required positive semi-definiteness correction. Column (2) reports the standard TWFE estimate for comparison. Standard errors clustered at the canton level in parentheses. All coefficients are in share units (multiply by 100 for percentage points).",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab_sunab.tex"))
cat("  Saved tab_sunab.tex\n")

cat("\nAll tables generated successfully.\n")
