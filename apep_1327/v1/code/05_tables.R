## ============================================================================
## 05_tables.R — All tables for apep_1327
## ============================================================================

source("00_packages.R")

DATA <- "../data"
TABLES <- "../tables"
dir.create(TABLES, showWarnings = FALSE)

panel <- readRDS(file.path(DATA, "panel_clean.rds"))
models <- readRDS(file.path(DATA, "models.rds"))
robust_models <- readRDS(file.path(DATA, "robust_models.rds"))
pre_stats <- readRDS(file.path(DATA, "pre_stats.rds"))
diagnostics <- fromJSON(file.path(DATA, "diagnostics.json"))

## ---- Table 1: Summary Statistics ----
cat("Table 1...\n")
tp <- panel[ever_treated == TRUE]
cp <- panel[control == TRUE]

make_row <- function(label, var, tp, cp) {
  sprintf("%s & %.1f & (%.1f) & %.1f & (%.1f) \\\\",
          label, mean(tp[[var]], na.rm = TRUE), sd(tp[[var]], na.rm = TRUE),
          mean(cp[[var]], na.rm = TRUE), sd(cp[[var]], na.rm = TRUE))
}

tab1 <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Summary Statistics: ZIP-Month Panel}\n\\label{tab:sumstats}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated ZIPs} & \\multicolumn{2}{c}{Control ZIPs} \\\\\n",
  " & Mean & (SD) & Mean & (SD) \\\\\n\\hline\n",
  make_row("Pharmacy claims (J-codes)", "pharmacy_claims", tp, cp), "\n",
  make_row("Pharmacy beneficiaries", "pharmacy_beneficiaries", tp, cp), "\n",
  make_row("Pharmacy spending (\\$)", "pharmacy_paid", tp, cp), "\n",
  make_row("ED visit claims", "ed_claims", tp, cp), "\n",
  "\\hline\n",
  sprintf("ZIP codes & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(uniqueN(tp$zip5), big.mark = ","), format(uniqueN(cp$zip5), big.mark = ",")),
  sprintf("ZIP $\\times$ months & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nrow(tp), big.mark = ","), format(nrow(cp), big.mark = ",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Unit of observation is ZIP code $\\times$ month (January 2018--December 2024). ",
  "Treated ZIPs experienced at least one chain pharmacy (CVS, Walgreens, or Rite Aid) billing cessation ",
  "in T-MSIS during the sample period. Control ZIPs have chain pharmacy presence but no billing cessation. ",
  "Pharmacy claims are Medicaid J-code (injectable drug) claims billed by chain pharmacy NPIs. ",
  "ED visits are E/M codes 99281--99285 billed by all providers in the ZIP.\n",
  "\\end{tablenotes}\\end{threeparttable}\n\\end{table}")
writeLines(tab1, file.path(TABLES, "tab1_sumstats.tex"))

## ---- Table 2: Main DiD ----
cat("Table 2...\n")
tab2 <- capture.output(
  etable(models$static_pharmacy, models$static_beneficiaries,
         models$static_ed, models$static_paid,
         headers = c("Pharmacy\\\\Claims", "Pharmacy\\\\Beneficiaries",
                      "ED\\\\Visits", "Pharmacy\\\\Spending"),
         dict = c("postTRUE" = "Post-closure"),
         style.tex = style.tex(main = "aer", depvar.title = "",
                                fixef.title = "\\midrule", fixef.suffix = " FE",
                                yesNo = c("Yes", "No")),
         tex = TRUE, fitstat = ~ n + r2, se.below = TRUE,
         title = "Chain Pharmacy Closure and Medicaid Utilization",
         label = "tab:main")
)
tab2_note <- paste0(
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Each column reports a separate regression with ZIP and year-month ",
  "fixed effects. Standard errors clustered at the ZIP level in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. ",
  "Outcomes are in logs ($\\ln(Y+1)$). Post-closure equals one after the first chain pharmacy ",
  "billing cessation in the ZIP.\n",
  "\\end{tablenotes}\n")
writeLines(gsub("\\\\end\\{table\\}", paste0(tab2_note, "\\\\end{table}"),
                paste(tab2, collapse = "\n")),
           file.path(TABLES, "tab2_main.tex"))

## ---- Table 3: Event Study ----
cat("Table 3...\n")
tab3 <- capture.output(
  etable(models$es_pharmacy, models$es_ed,
         headers = c("Pharmacy\\\\Claims", "ED\\\\Visits"),
         dict = c("et_binpre_12plus" = "Pre $>$ 12 months",
                   "et_binpre_12_to_7" = "Pre 7--12 months",
                   "et_binpost_0_to_5" = "Post 0--5 months",
                   "et_binpost_6_to_11" = "Post 6--11 months",
                   "et_binpost_12plus" = "Post $>$ 12 months"),
         style.tex = style.tex(main = "aer", depvar.title = "",
                                fixef.title = "\\midrule", fixef.suffix = " FE",
                                yesNo = c("Yes", "No")),
         tex = TRUE, fitstat = ~ n + r2, se.below = TRUE,
         title = "Event Study: Binned Estimates Around Chain Pharmacy Closure",
         label = "tab:eventstudy")
)
tab3_note <- paste0(
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Reference period is 1--6 months before closure. ",
  "Sample restricted to treated ZIPs only. ZIP and year-month fixed effects included. ",
  "Standard errors clustered at ZIP level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n")
writeLines(gsub("\\\\end\\{table\\}", paste0(tab3_note, "\\\\end{table}"),
                paste(tab3, collapse = "\n")),
           file.path(TABLES, "tab3_eventstudy.tex"))

## ---- Table 4: Heterogeneity ----
cat("Table 4...\n")
tab4 <- capture.output(
  etable(models$het_last, models$het_not_last,
         models$het_ed_last, models$het_ed_notlast,
         headers = c("Pharmacy\\\\Last Closed", "Pharmacy\\\\Others Remain",
                      "ED\\\\Last Closed", "ED\\\\Others Remain"),
         dict = c("postTRUE" = "Post-closure"),
         style.tex = style.tex(main = "aer", depvar.title = "",
                                fixef.title = "\\midrule", fixef.suffix = " FE",
                                yesNo = c("Yes", "No")),
         tex = TRUE, fitstat = ~ n + r2, se.below = TRUE,
         title = "Heterogeneity: Last Chain Pharmacy Standing",
         label = "tab:het")
)
tab4_note <- paste0(
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} ``Last Closed'' restricts to ZIPs where all chain pharmacy NPIs ",
  "ceased billing. ``Others Remain'' restricts to ZIPs retaining at least one active chain pharmacy NPI. ",
  "Both subsamples include the full set of control ZIPs. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n")
writeLines(gsub("\\\\end\\{table\\}", paste0(tab4_note, "\\\\end{table}"),
                paste(tab4, collapse = "\n")),
           file.path(TABLES, "tab4_heterogeneity.tex"))

## ---- Table 5: Robustness ----
cat("Table 5...\n")
tab5 <- capture.output(
  etable(models$static_pharmacy, robust_models$asinh_pharmacy,
         robust_models$precovid, robust_models$postcovid,
         headers = c("Log\\\\(Baseline)", "Asinh\\\\(Pharmacy)",
                      "Pre-COVID\\\\(2018--2019)", "Post-COVID\\\\(2021--2024)"),
         dict = c("postTRUE" = "Post-closure"),
         style.tex = style.tex(main = "aer", depvar.title = "",
                                fixef.title = "\\midrule", fixef.suffix = " FE",
                                yesNo = c("Yes", "No")),
         tex = TRUE, fitstat = ~ n + r2, se.below = TRUE,
         title = "Robustness Checks: Alternative Specifications and Sample Periods",
         label = "tab:robust")
)
tab5_note <- paste0(
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline from Table~\\ref{tab:main}. ",
  "Column (2) uses the inverse hyperbolic sine transformation. ",
  "Columns (3)--(4) restrict the sample to pre-COVID and post-COVID periods. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n")
writeLines(gsub("\\\\end\\{table\\}", paste0(tab5_note, "\\\\end{table}"),
                paste(tab5, collapse = "\n")),
           file.path(TABLES, "tab5_robustness.tex"))

## ---- SDE Table ----
cat("SDE Table...\n")

get_sde <- function(model, sd_y, label, coef_name = "postTRUE") {
  b <- coef(model)[coef_name]
  s <- se(model)[coef_name]
  sde <- b / sd_y
  se_sde <- s / sd_y
  abs_sde <- abs(sde)
  cls <- if (abs_sde < 0.005) "Null" else
    if (abs_sde < 0.05) paste0(ifelse(sde > 0, "Small positive", "Small negative")) else
    if (abs_sde < 0.15) paste0(ifelse(sde > 0, "Moderate positive", "Moderate negative")) else
    paste0(ifelse(sde > 0, "Large positive", "Large negative"))
  data.table(Outcome = label, beta = b, se = s, sd_y = sd_y,
             sde = sde, se_sde = se_sde, classification = cls)
}

sde_pooled <- rbind(
  get_sde(models$static_pharmacy, pre_stats$sd_pharmacy_claims, "Pharmacy claims (J-codes)"),
  get_sde(models$static_beneficiaries, pre_stats$sd_pharmacy_beneficiaries, "Pharmacy beneficiaries"),
  get_sde(models$static_ed, pre_stats$sd_ed_claims, "ED visit claims")
)

# Heterogeneous: last pharmacy standing
sd_last <- sd(panel[pre_treatment == TRUE & last_pharm == TRUE]$pharmacy_claims, na.rm = TRUE)
sd_notlast <- sd(panel[pre_treatment == TRUE & ever_treated == TRUE & last_pharm == FALSE]$pharmacy_claims, na.rm = TRUE)

sde_het <- rbind(
  get_sde(models$het_last, sd_last, "Pharmacy claims: last chain closed"),
  get_sde(models$het_not_last, sd_notlast, "Pharmacy claims: other chains remain")
)

fmt_row <- function(r) {
  sprintf("  %s & %.3f & (%.3f) & %.1f & %.3f & (%.3f) & %s \\\\",
          r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does chain pharmacy closure (CVS, Walgreens, Rite Aid) reduce Medicaid pharmacy utilization and increase emergency department use in affected ZIP codes? ",
  "\\textbf{Policy mechanism:} Chain pharmacy NPI billing cessation removes a Medicaid-billing pharmacy from the neighborhood; beneficiaries who fail to transfer prescriptions to remaining providers experience medication gaps that may drive acute care utilization. ",
  "\\textbf{Outcome definition:} Pharmacy claims are monthly Medicaid J-code (injectable drug administration) claim counts billed by chain pharmacy NPIs per ZIP; ED visits are monthly E/M codes 99281--99285 claim counts billed by all providers per ZIP; pharmacy beneficiaries are unique Medicaid beneficiaries receiving any J-code service from chain pharmacy NPIs per ZIP-month. ",
  "\\textbf{Treatment:} Binary; equals one after the first chain pharmacy NPI billing cessation in the ZIP. ",
  "\\textbf{Data:} T-MSIS Medicaid Provider Spending (HHS, January 2018--December 2024, 84 months) linked to NPPES for provider geography; ",
  format(diagnostics$n_obs, big.mark = ","), " ZIP-month observations across ",
  format(diagnostics$n_treated, big.mark = ","), " treated and ",
  format(diagnostics$n_control, big.mark = ","), " control ZIPs. ",
  "\\textbf{Method:} Two-way fixed effects (ZIP and year-month); standard errors clustered at ZIP level; binned event study for pre-trend validation; Rite Aid bankruptcy instrument for chain-wide closures. ",
  "\\textbf{Sample:} ZIPs with at least one chain pharmacy NPI billing in T-MSIS and nonzero pharmacy claims during the sample period. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(sapply(1:nrow(sde_pooled), function(i) fmt_row(sde_pooled[i])), collapse = "\n"), "\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Last Chain Pharmacy Standing)}} \\\\\n",
  paste(sapply(1:nrow(sde_het), function(i) fmt_row(sde_het[i])), collapse = "\n"), "\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\\end{threeparttable}\n\\end{table}")
writeLines(sde_tex, file.path(TABLES, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
