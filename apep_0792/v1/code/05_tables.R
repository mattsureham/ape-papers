## 05_tables.R — Generate LaTeX tables for Colombia-Venezuela trade collapse paper
source("00_packages.R")

cat("=== Generating Tables ===\n")

## ---- Load results ----
main   <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
panel  <- fread("../data/sector_panel.csv")
pre    <- fread("../data/pre_shares.csv")

dir.create("../tables", showWarnings = FALSE)

## Helper: format coefficient with stars
star <- function(b, p) {
  s <- ""
  if (p < 0.01) s <- "***"
  else if (p < 0.05) s <- "**"
  else if (p < 0.10) s <- "*"
  paste0(formatC(b, format = "f", digits = 3), s)
}

## ============================================================
## Table 1: Summary Statistics by HS Sector
## ============================================================
cat("Writing Table 1: Summary statistics\n")

panel[, sector_id := as.integer(factor(sector))]

## Compute average export levels pre-crisis (2005-2008) and post-crisis (2015-2019)
pre_avg <- panel[year %in% 2005:2008, .(
  exports_pre = mean(world_exports, na.rm = TRUE)
), by = sector]

post_avg <- panel[year %in% 2015:2019, .(
  exports_post = mean(world_exports, na.rm = TRUE)
), by = sector]

summ <- merge(pre, pre_avg, by = "sector")
summ <- merge(summ, post_avg, by = "sector")
summ <- summ[order(-ven_share_pre)]

## Clean sector labels
summ[, label := gsub("^\\d+-\\d+_", "", sector)]

sink("../tables/tab1_summary.tex")
cat("\\begin{table}[!htbp]\n")
cat("\\centering\n")
cat("\\begin{threeparttable}\n")
cat("\\caption{Summary Statistics: Colombian Export Sectors}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{llrrr}\n")
cat("\\toprule\n")
cat("HS Chapters & Sector & Ven. Share & Pre-Crisis Exports & Post-Crisis Exports \\\\\n")
cat(" & & (2005--08) & (2005--08, \\$1000s) & (2015--19, \\$1000s) \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(summ))) {
  r <- summ[i]
  hs <- gsub("_.*", "", r$sector)
  cat(sprintf("%s & %s & %.3f & %s & %s \\\\\n",
              hs,
              r$label,
              r$ven_share_pre,
              formatC(round(r$exports_pre), format = "d", big.mark = ","),
              formatC(round(r$exports_post), format = "d", big.mark = ",")))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Each row is an HS chapter group. ``Ven.\\ Share'' is the sector's average share of total exports sent to Venezuela during 2005--2008. Pre-crisis and post-crisis export values are period averages in thousands of USD. Data from WITS/UN Comtrade.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 2: Main Results
## ============================================================
cat("Writing Table 2: Main results\n")

fits <- list(main$twfe_world, main$twfe_ven, main$twfe_nonven, main$twfe_growth)
dep_labels <- c("Log Total", "Log Venezuela", "Log Non-Ven.", "Growth Rel. 2008")

## Pre-treatment means of each outcome
premean <- c(
  panel[post == 0, mean(log_world, na.rm = TRUE)],
  panel[post == 0, mean(log_ven, na.rm = TRUE)],
  panel[post == 0, mean(log_nonven, na.rm = TRUE)],
  panel[year >= 2002 & post == 0, mean(growth_world, na.rm = TRUE)]
)

sink("../tables/tab2_main.tex")
cat("\\begin{table}[!htbp]\n")
cat("\\centering\n")
cat("\\begin{threeparttable}\n")
cat("\\caption{Main Results: Effect of Venezuela Dependence on Colombian Sector Exports}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(sprintf(" & (%d) & (%d) & (%d) & (%d) \\\\\n", 1, 2, 3, 4))
cat(sprintf(" & %s & %s & %s & %s \\\\\n",
            dep_labels[1], dep_labels[2], dep_labels[3], dep_labels[4]))
cat("\\midrule\n")

## Coefficient row
cat("Ven.\\ Share$_{\\text{pre}} \\times$ Post")
for (j in seq_along(fits)) {
  b <- coef(fits[[j]])[1]
  p <- fixest::pvalue(fits[[j]])[1]
  cat(sprintf(" & %s", star(b, p)))
}
cat(" \\\\\n")

## SE row
cat(" ")
for (j in seq_along(fits)) {
  s <- se(fits[[j]])[1]
  cat(sprintf(" & (%s)", formatC(s, format = "f", digits = 3)))
}
cat(" \\\\\n")

## p-value row
cat(" ")
for (j in seq_along(fits)) {
  p <- fixest::pvalue(fits[[j]])[1]
  cat(sprintf(" & [%s]", formatC(p, format = "f", digits = 3)))
}
cat(" \\\\\n")

cat("\\addlinespace\n")

## Pre-treatment mean
cat("Pre-treatment mean")
for (j in seq_along(premean)) {
  cat(sprintf(" & %s", formatC(premean[j], format = "f", digits = 3)))
}
cat(" \\\\\n")

## Fixed effects
cat("Sector FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")

## N
cat("Observations")
for (j in seq_along(fits)) {
  cat(sprintf(" & %d", fits[[j]]$nobs))
}
cat(" \\\\\n")

## R-squared
cat("$R^2$")
for (j in seq_along(fits)) {
  cat(sprintf(" & %s", formatC(fitstat(fits[[j]], "r2")[[1]], format = "f", digits = 3)))
}
cat(" \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Each column reports a TWFE regression of the outcome on the interaction of pre-crisis Venezuela export share (continuous, 2005--2008 average) and a post-2009 indicator. Standard errors clustered at the sector level in parentheses; $p$-values in brackets. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 3: Robustness — Total Exports
## ============================================================
cat("Writing Table 3: Robustness\n")

## Collect robustness specifications
rob_specs <- list(
  list(label = "Baseline",              fit = main$twfe_world),
  list(label = "Alt pre-period (2003--07)", fit = robust$fit_alt),
  list(label = "Exclude fuels",         fit = robust$fit_nofuel),
  list(label = "Leave-one-out (drop Animals)", fit = robust$fit_nomax),
  list(label = "Border closure (2015+)", fit = robust$fit_border),
  list(label = "Placebo (post = 2005)", fit = robust$fit_placebo)
)

sink("../tables/tab3_robustness.tex")
cat("\\begin{table}[!htbp]\n")
cat("\\centering\n")
cat("\\begin{threeparttable}\n")
cat("\\caption{Robustness: Effect on Total Exports (Log)}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Specification & Coefficient & SE & $p$-value & $N$ \\\\\n")
cat("\\midrule\n")
for (sp in rob_specs) {
  b <- coef(sp$fit)[1]
  s <- se(sp$fit)[1]
  p <- fixest::pvalue(sp$fit)[1]
  n <- sp$fit$nobs
  cat(sprintf("%s & %s & %s & %s & %d \\\\\n",
              sp$label,
              star(b, p),
              formatC(s, format = "f", digits = 3),
              formatC(p, format = "f", digits = 3),
              n))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} All specifications include sector and year fixed effects with standard errors clustered at the sector level. The dependent variable is log total exports (thousands USD). ``Alt pre-period'' uses 2003--2007 Venezuela shares. ``Leave-one-out'' drops the Animal sector (highest Venezuela share, 73\\%). ``Border closure'' redefines post as 2015+. ``Placebo'' restricts to pre-crisis years with a placebo cutoff at 2005. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 4: Diversification Robustness (Non-Venezuela Exports)
## ============================================================
cat("Writing Table 4: Diversification robustness\n")

div_specs <- list(
  list(label = "Baseline",              fit = main$twfe_nonven),
  list(label = "Exclude fuels",         fit = robust$fit_div_nofuel),
  list(label = "Border closure (2015+)", fit = robust$fit_div_border)
)

sink("../tables/tab4_diversification.tex")
cat("\\begin{table}[!htbp]\n")
cat("\\centering\n")
cat("\\begin{threeparttable}\n")
cat("\\caption{Diversification: Effect on Non-Venezuela Exports (Log)}\n")
cat("\\label{tab:diversification}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Specification & Coefficient & SE & $p$-value & $N$ \\\\\n")
cat("\\midrule\n")
for (sp in div_specs) {
  b <- coef(sp$fit)[1]
  s <- se(sp$fit)[1]
  p <- fixest::pvalue(sp$fit)[1]
  n <- sp$fit$nobs
  cat(sprintf("%s & %s & %s & %s & %d \\\\\n",
              sp$label,
              star(b, p),
              formatC(s, format = "f", digits = 3),
              formatC(p, format = "f", digits = 3),
              n))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} The dependent variable is log non-Venezuela exports (thousands USD). All specifications include sector and year fixed effects with standard errors clustered at the sector level. Across all specifications, the effect on non-Venezuela exports is statistically insignificant, indicating that sectors more dependent on Venezuela did not diversify to alternative markets. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table F1: Standardized Effect Sizes
## ============================================================
cat("Writing Table F1: Standardized effect sizes\n")

## Compute pre-treatment SD of each outcome
panel[, sector_id := as.integer(factor(sector))]
sd_pre <- c(
  panel[post == 0, sd(log_world, na.rm = TRUE)],
  panel[post == 0, sd(log_ven, na.rm = TRUE)],
  panel[post == 0, sd(log_nonven, na.rm = TRUE)],
  panel[year >= 2002 & post == 0, sd(growth_world, na.rm = TRUE)]
)

outcomes   <- c("Total exports", "Venezuela exports", "Non-Ven.\\ exports", "Growth rel.\\ 2008")
betas      <- sapply(fits, function(f) coef(f)[1])
ses        <- sapply(fits, function(f) se(f)[1])
pvals      <- sapply(fits, function(f) fixest::pvalue(f)[1])
sde        <- betas / sd_pre

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[!htbp]\n")
cat("\\centering\n")
cat("\\begin{threeparttable}\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) pre & SDE ($\\hat{\\beta}$/SD) & $p$-value \\\\\n")
cat("\\midrule\n")
for (i in seq_along(outcomes)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
              outcomes[i],
              star(betas[i], pvals[i]),
              formatC(ses[i], format = "f", digits = 3),
              formatC(sd_pre[i], format = "f", digits = 3),
              formatC(sde[i], format = "f", digits = 3),
              formatC(pvals[i], format = "f", digits = 3)))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:}\n")
cat("\\item \\textbf{Country:} Colombia.\n")
cat("\\item \\textbf{Research question:} How losing a dominant trading partner reshapes industrial exports.\n")
cat("\\item \\textbf{Policy mechanism:} Venezuela's economic collapse (PDVSA nationalization, CADIVI controls, hyperinflation, border closure) destroyed Colombia's second-largest export destination.\n")
cat("\\item \\textbf{Outcome definition:} Log annual sector-level export value in thousands USD from WITS/Comtrade.\n")
cat("\\item \\textbf{Treatment:} Continuous --- pre-crisis (2005--2008) sector Venezuela export share.\n")
cat("\\item \\textbf{Data:} WITS/UN Comtrade bilateral trade, 16 HS chapter groups, 2000--2022, 368 sector-year observations.\n")
cat("\\item \\textbf{Method:} TWFE with sector and year fixed effects, standard errors clustered at sector level.\n")
cat("\\item \\textbf{Sample:} 16 HS chapter groups covering all Colombian exports.\n")
cat("\\item SDE is the standardized effect size: $\\hat{\\beta}$ divided by the pre-treatment standard deviation of the outcome variable. Classification of effect sizes follows standard conventions but should be interpreted in the context of this specific application.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables written to ../tables/ ===\n")
cat("Files:\n")
cat(paste(" ", list.files("../tables", pattern = "\\.tex$"), collapse = "\n"), "\n")
