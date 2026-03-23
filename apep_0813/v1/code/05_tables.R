# 05_tables.R — Generate all LaTeX tables for NFA reform paper
# apep_0813/v1

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- readRDS("data/panel_clean.rds")
sumstats <- readRDS("data/sumstats.rds")
models <- readRDS("data/models.rds")
robustness <- readRDS("data/robustness.rds")
es_coefs <- readRDS("data/event_study_coefs.rds")

cat("=== Generating LaTeX tables ===\n")

# -------------------------------------------------------------------
# Table 1: Summary Statistics
# -------------------------------------------------------------------
cat("\n--- Table 1: Summary Statistics ---\n")

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrrr}\n",
  "\\toprule\n",
  "Variable & N & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sumstats)) {
  row <- sumstats[i]
  tab1 <- paste0(tab1, sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
                                row$Variable, format(row$N, big.mark = ","),
                                row$Mean, row$SD, row$Min, row$Max))
}

tab1 <- paste0(tab1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of 26 Swiss cantons, 2001--2024 (624 canton-year observations). ",
  "Migration rates are inter-cantonal flows per 1,000 population (January 1 stock). ",
  "NFA intensity is $(100 - \\text{Ressourcenindex}_{2008})/100$, where the Ressourcenindex ",
  "measures standardized cantonal tax potential relative to the national average. ",
  "Positive values indicate resource-weak cantons that receive equalization transfers; ",
  "negative values indicate resource-strong cantons that contribute. ",
  "Source: Swiss Federal Statistical Office (BFS) PXWeb API and Federal Finance ",
  "Administration (EFV) Wirksamkeitsbericht.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1, "tables/tab1_summary.tex")
cat("Wrote tables/tab1_summary.tex\n")

# -------------------------------------------------------------------
# Table 2: Main Results
# -------------------------------------------------------------------
cat("\n--- Table 2: Main Results ---\n")

# Extract coefficients and SEs
get_coef <- function(m, var = "intensity_post") {
  b <- coef(m)[var]
  s <- sqrt(diag(vcov(m)))[var]
  p <- pvalue(m)[var]
  n <- m$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, s = s, p = p, n = n, stars = stars)
}

r1 <- get_coef(models$m1_net)
r2 <- get_coef(models$m1_in)
r3 <- get_coef(models$m1_out)
r4 <- get_coef(models$m1_pop)

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of NFA Equalization on Inter-cantonal Migration and Population Growth}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Net Migration & In-Migration & Out-Migration & Pop.~Growth \\\\\n",
  " & Rate & Rate & Rate & (\\%) \\\\\n",
  "\\midrule\n",
  sprintf("NFA Intensity $\\times$ Post & %s%s & %s%s & %s%s & %s%s \\\\\n",
          formatC(r1$b, format = "f", digits = 3), r1$stars,
          formatC(r2$b, format = "f", digits = 3), r2$stars,
          formatC(r3$b, format = "f", digits = 3), r3$stars,
          formatC(r4$b, format = "f", digits = 3), r4$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          formatC(r1$s, format = "f", digits = 3),
          formatC(r2$s, format = "f", digits = 3),
          formatC(r3$s, format = "f", digits = 3),
          formatC(r4$s, format = "f", digits = 3)),
  " \\\\\n",
  "Canton FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","), format(r4$n, big.mark = ",")),
  sprintf("Cantons & 26 & 26 & 26 & 26 \\\\\n"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the canton level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "The treatment variable is NFA Intensity $\\times$ Post, where NFA Intensity $= (100 - ",
  "\\text{Ressourcenindex}_{2008})/100$ (time-invariant) and Post $= \\mathbf{1}[\\text{year} ",
  "\\geq 2008]$. Columns (1)--(3) report inter-cantonal migration rates per 1,000 population. ",
  "Column (4) reports annual population growth in percent. ",
  "A positive coefficient indicates that cantons with higher equalization receipts ",
  "experienced larger increases in the outcome after 2008.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2, "tables/tab2_main.tex")
cat("Wrote tables/tab2_main.tex\n")

# -------------------------------------------------------------------
# Table 3: Event Study Coefficients
# -------------------------------------------------------------------
cat("\n--- Table 3: Event Study ---\n")

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: NFA Intensity and Net Migration Rate}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Event Time & Coefficient & SE & 95\\% CI \\\\\n",
  "\\midrule\n"
)

# Add reference year
tab3 <- paste0(tab3, "$t = -1$ (ref.) & --- & --- & --- \\\\\n")

for (i in 1:nrow(es_coefs)) {
  row <- es_coefs[i]
  p_val <- 2 * pnorm(-abs(row$coef / row$se))
  stars <- ifelse(p_val < 0.01, "***", ifelse(p_val < 0.05, "**",
                  ifelse(p_val < 0.1, "*", "")))
  tab3 <- paste0(tab3, sprintf("$t = %+d$ & %s%s & (%s) & [%s, %s] \\\\\n",
                                row$event_time,
                                formatC(row$coef, format = "f", digits = 3), stars,
                                formatC(row$se, format = "f", digits = 3),
                                formatC(row$ci_lo, format = "f", digits = 3),
                                formatC(row$ci_hi, format = "f", digits = 3)))
}

tab3 <- paste0(tab3,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from estimating $Y_{ct} = \\alpha_c + \\alpha_t + ",
  "\\sum_k \\beta_k (\\text{NFA Intensity}_c \\times \\mathbf{1}[t = k]) + \\varepsilon_{ct}$, ",
  "where the outcome is the net inter-cantonal migration rate per 1,000 population. ",
  "The omitted category is $t = -1$ (2007). Standard errors clustered at the canton level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)

writeLines(tab3, "tables/tab3_eventstudy.tex")
cat("Wrote tables/tab3_eventstudy.tex\n")

# -------------------------------------------------------------------
# Table 4: Robustness
# -------------------------------------------------------------------
cat("\n--- Table 4: Robustness ---\n")

# Main spec for reference
m_main <- feols(net_migration_rate ~ intensity_post | canton_id + year,
                data = panel, cluster = ~canton_id)
r_main <- get_coef(m_main)
r_nz <- get_coef(robustness$excl_nearzero)
r_zug <- get_coef(robustness$excl_zug)
r_trends <- get_coef(robustness$canton_trends)
r_binary <- get_coef(models$m3_net, var = "recipient_post")

# Wild cluster bootstrap p-values
wcb_p <- if (!is.null(models$boot_net)) formatC(models$boot_net$p_val, format = "f", digits = 3) else "---"
ri_p <- formatC(robustness$ri_pvalue, format = "f", digits = 3)

# Placebo coefficients
r_p2004 <- get_coef(robustness$placebo_2004, var = "placebo_interact")
r_p2006 <- get_coef(robustness$placebo_2006, var = "placebo_interact")

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Coef. & SE & $p$ & WCB $p$ & $N$ \\\\\n",
  "\\midrule\n",
  "\\multicolumn{6}{l}{\\textit{Panel A: Main specification and alternatives}} \\\\\n",
  sprintf("Baseline (continuous intensity) & %s%s & (%s) & %s & %s & %s \\\\\n",
          formatC(r_main$b, format = "f", digits = 3), r_main$stars,
          formatC(r_main$s, format = "f", digits = 3),
          formatC(r_main$p, format = "f", digits = 3),
          wcb_p, format(r_main$n, big.mark = ",")),
  sprintf("Binary treatment (recipient vs.~payer) & %s%s & (%s) & %s & --- & %s \\\\\n",
          formatC(r_binary$b, format = "f", digits = 3), r_binary$stars,
          formatC(r_binary$s, format = "f", digits = 3),
          formatC(r_binary$p, format = "f", digits = 3),
          format(r_binary$n, big.mark = ",")),
  sprintf("Excluding near-zero cantons & %s%s & (%s) & %s & --- & %s \\\\\n",
          formatC(r_nz$b, format = "f", digits = 3), r_nz$stars,
          formatC(r_nz$s, format = "f", digits = 3),
          formatC(r_nz$p, format = "f", digits = 3),
          format(r_nz$n, big.mark = ",")),
  sprintf("Excluding Zug & %s%s & (%s) & %s & --- & %s \\\\\n",
          formatC(r_zug$b, format = "f", digits = 3), r_zug$stars,
          formatC(r_zug$s, format = "f", digits = 3),
          formatC(r_zug$p, format = "f", digits = 3),
          format(r_zug$n, big.mark = ",")),
  sprintf("Canton-specific trends & %s%s & (%s) & %s & --- & %s \\\\\n",
          formatC(r_trends$b, format = "f", digits = 3), r_trends$stars,
          formatC(r_trends$s, format = "f", digits = 3),
          formatC(r_trends$p, format = "f", digits = 3),
          format(r_trends$n, big.mark = ",")),
  " \\\\\n",
  "\\multicolumn{6}{l}{\\textit{Panel B: Inference}} \\\\\n",
  sprintf("Randomization inference ($p$-value) & \\multicolumn{4}{c}{%s} & 1,000 perms \\\\\n", ri_p),
  " \\\\\n",
  "\\multicolumn{6}{l}{\\textit{Panel C: Placebo tests (pre-NFA data only)}} \\\\\n",
  sprintf("Placebo cutoff: 2004 & %s%s & (%s) & %s & --- & %s \\\\\n",
          formatC(r_p2004$b, format = "f", digits = 3), r_p2004$stars,
          formatC(r_p2004$s, format = "f", digits = 3),
          formatC(r_p2004$p, format = "f", digits = 3),
          format(r_p2004$n, big.mark = ",")),
  sprintf("Placebo cutoff: 2006 & %s%s & (%s) & %s & --- & %s \\\\\n",
          formatC(r_p2006$b, format = "f", digits = 3), r_p2006$stars,
          formatC(r_p2006$s, format = "f", digits = 3),
          formatC(r_p2006$p, format = "f", digits = 3),
          format(r_p2006$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Outcome is net inter-cantonal migration rate per 1,000 population. ",
  "Panel A reports coefficient estimates under alternative specifications. The baseline uses ",
  "continuous NFA intensity $\\times$ Post with canton and year fixed effects. ",
  "The binary specification classifies cantons as recipients (Ressourcenindex $< 95$) or ",
  "payers (Ressourcenindex $> 105$), excluding 2 near-zero cantons. ",
  "WCB $p$ = wild cluster bootstrap $p$-value (Rademacher weights, 9,999 iterations). ",
  "Panel C uses only pre-NFA observations (2001--2007) with placebo treatment cutoffs. ",
  "Standard errors clustered at the canton level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robustness}\n",
  "\\end{table}\n"
)

writeLines(tab4, "tables/tab4_robustness.tex")
cat("Wrote tables/tab4_robustness.tex\n")

# -------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE)
# -------------------------------------------------------------------
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

# Compute SDE for main outcomes
# Treatment is continuous: SDE = beta * SD(X) / SD(Y)
sd_x <- sd(panel$nfa_intensity)

outcomes <- list(
  list(name = "Net migration rate", model = models$m1_net,
       var = "intensity_post", y = panel$net_migration_rate),
  list(name = "In-migration rate", model = models$m1_in,
       var = "intensity_post", y = panel$in_migration_rate),
  list(name = "Out-migration rate", model = models$m1_out,
       var = "intensity_post", y = panel$out_migration_rate),
  list(name = "Population growth", model = models$m1_pop,
       var = "intensity_post", y = panel[!is.na(pop_growth), pop_growth])
)

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

sde_rows <- ""
for (o in outcomes) {
  beta <- coef(o$model)[o$var]
  se_beta <- sqrt(diag(vcov(o$model)))[o$var]
  sd_y <- sd(o$y, na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y
  class_label <- classify_sde(sde)

  sde_rows <- paste0(sde_rows, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\\n",
    o$name,
    formatC(beta, format = "f", digits = 3),
    formatC(sd_x, format = "f", digits = 3),
    formatC(sd_y, format = "f", digits = 3),
    formatC(sde, format = "f", digits = 4),
    formatC(se_sde, format = "f", digits = 4),
    class_label
  ))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Whether Switzerland's 2008 Neuer Finanzausgleich (NFA) reform, ",
  "which replaced earmarked conditional federal transfers with unconditional block grants, ",
  "altered inter-cantonal migration patterns among the 26 Swiss cantons. ",
  "\\textbf{Policy mechanism:} The NFA abolished the 1959 system of earmarked federal-cantonal ",
  "cost sharing and replaced it with formula-based unconditional resource equalization ",
  "(Ressourcenausgleich) and burden-sharing (Lastenausgleich), redistributing CHF 3.5--4 billion ",
  "annually from resource-strong to resource-weak cantons based on standardized tax potential. ",
  "\\textbf{Outcome definition:} Net inter-cantonal migration rate per 1,000 permanent resident ",
  "population (January 1 stock), computed as in-migrants minus out-migrants from other cantons, ",
  "from the BFS demographic balance database. ",
  "\\textbf{Treatment:} Continuous; NFA intensity $= (100 - \\text{Ressourcenindex}_{2008})/100$, ",
  "measuring the proportional deviation of cantonal tax potential from the national average. ",
  "\\textbf{Data:} BFS PXWeb demographic balance API (px-x-0102020000\\_101), 2001--2024, ",
  "canton-year panel, 624 observations across 26 cantons. ",
  "\\textbf{Method:} Two-way fixed effects (canton + year) with continuous treatment intensity ",
  "interacted with a post-2008 indicator; standard errors clustered at the canton level; ",
  "wild cluster bootstrap and randomization inference for robustness. ",
  "\\textbf{Sample:} All 26 Swiss cantons, 2001--2024 (7 pre-reform years, 17 post-reform years). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) and SD($Y$) are ",
  "unconditional standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  sde_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:sde}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("Wrote tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
