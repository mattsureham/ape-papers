# 05_tables.R — Generate all tables for the paper
# EU Late Payment Directive & Small Firm Survival (apep_0938)

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")
pre_stats <- readRDS("../data/pre_stats.rds")
loo_results <- readRDS("../data/loo_results.rds")
robust_models <- readRDS("../data/robust_models.rds")

# ================================================================
# Table 1: Summary Statistics
# ================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Panel A: Pre-directive (2010-2012), Panel B: Post-directive (2014-2020)
summ_tab <- panel |>
  filter(!is.na(death_rate)) |>
  mutate(period = ifelse(year < 2014, "Pre-Directive (2010--2012)",
                         "Post-Directive (2014--2020)")) |>
  group_by(period, small) |>
  summarise(
    `Death Rate` = sprintf("%.2f", mean(death_rate, na.rm = TRUE)),
    `(SD)` = sprintf("(%.2f)", sd(death_rate, na.rm = TRUE)),
    `Birth Rate` = sprintf("%.2f", mean(birth_rate, na.rm = TRUE)),
    `Survival Rate (3yr)` = sprintf("%.2f", mean(surv_rate_3yr, na.rm = TRUE)),
    N = n(),
    .groups = "drop"
  ) |>
  mutate(
    `Firm Size` = ifelse(small == 1, "Small (0--9)", "Large (10+)")
  ) |>
  select(period, `Firm Size`, `Death Rate`, `(SD)`, `Birth Rate`,
         `Survival Rate (3yr)`, N)

# Write LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Firm Demographics by Size Class and Period}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{llccccc}\n")
cat("\\hline\\hline\n")
cat("Period & Firm Size & Death Rate & (SD) & Birth Rate & Survival (3yr) & N \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(summ_tab)) {
  row <- summ_tab[i, ]
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
              row$period, row$`Firm Size`, row$`Death Rate`, row$`(SD)`,
              row$`Birth Rate`, row$`Survival Rate (3yr)`,
              format(row$N, big.mark = ",")))
  if (i == 2) cat("\\hline\n")
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Death rate is the number of enterprise deaths as a percentage of active enterprises. Birth rate is enterprise births as a percentage of active enterprises. Survival rate (3yr) is the percentage of enterprises born in $t-3$ that survived to year $t$. Small firms have 0--9 employees; large firms have 10 or more. Source: Eurostat Business Demography (bd\\_9bd\\_sz\\_cl\\_r2), 28 EU member states.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 1 written to tables/tab1_summary.tex\n")

# ================================================================
# Table 2: Main Triple-Diff Results
# ================================================================

cat("=== Generating Table 2: Main Results ===\n")

# Extract coefficients for main table
extract_triple <- function(model, coef_name = "post:pay_delay_z:small") {
  cf <- coef(model)
  se_vals <- se(model)
  pv <- pvalue(model)
  idx <- which(names(cf) == coef_name)
  if (length(idx) == 0) {
    # Try alternative naming
    idx <- grep("pay_delay_z.*small|small.*pay_delay_z", names(cf))
    if (length(idx) == 0) return(list(est = NA, se = NA, pval = NA))
    idx <- idx[1]
  }
  list(est = cf[idx], se = se_vals[idx], pval = pv[idx],
       n = nobs(model), r2 = r2(model, type = "ar2"))
}

# Columns: (1) Death Rate - continuous, (2) Death Rate - binary,
# (3) Survival Rate - continuous, (4) Survival Rate - binary

res1 <- extract_triple(models$death_continuous)
res2 <- extract_triple(models$death_binary, "post:high_delay:small")
res3 <- extract_triple(models$surv_continuous)
res4 <- extract_triple(models$surv_binary, "post:high_delay:small")

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{The Late Payment Directive and Firm Demographics: Triple-Difference Estimates}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Death Rate} & \\multicolumn{2}{c}{Survival Rate (3yr)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

cat(sprintf("Post $\\times$ Delay $\\times$ Small & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
            res1$est, stars(res1$pval),
            res2$est, stars(res2$pval),
            res3$est, stars(res3$pval),
            res4$est, stars(res4$pval)))

cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            res1$se, res2$se, res3$se, res4$se))

cat("\\hline\n")
cat(sprintf("Intensity measure & Continuous & Binary & Continuous & Binary \\\\\n"))
cat("Country $\\times$ Size FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Country $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Size $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(res1$n, big.mark = ","),
            format(res2$n, big.mark = ","),
            format(res3$n, big.mark = ","),
            format(res4$n, big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Each column reports the triple-difference coefficient ($\\hat{\\beta}_1$) from the specification $Y_{cst} = \\alpha_{cs} + \\alpha_{ct} + \\alpha_{st} + \\beta_1 \\text{Post}_t \\times \\text{Delay}_c \\times \\text{Small}_s + \\beta_2 \\text{Post}_t \\times \\text{Delay}_c + \\beta_3 \\text{Post}_t \\times \\text{Small}_s + \\beta_4 \\text{Delay}_c \\times \\text{Small}_s + \\varepsilon_{cst}$. ``Continuous'' uses standardized average B2B payment days; ``Binary'' uses an above-median indicator. Small firms have 0--9 employees. Standard errors clustered at the country level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 2 written to tables/tab2_main.tex\n")

# ================================================================
# Table 3: Event Study Coefficients
# ================================================================

cat("=== Generating Table 3: Event Study ===\n")

es_coefs <- readRDS("../data/es_coefs_death.rds")

sink("../tables/tab3_event_study.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Event Study: Triple-Interaction Coefficients by Year}\n")
cat("\\label{tab:eventstudy}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Year Relative to Directive & Estimate & SE & 95\\% CI \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(es_coefs)) {
  row <- es_coefs[i, ]
  cat(sprintf("%+d & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
              row$rel_year,
              row$estimate, stars(row$pval),
              row$se,
              row$ci_lo, row$ci_hi))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Coefficients on the year-specific triple interaction (Year $\\times$ PayDelay$_z$ $\\times$ Small), from the event-study specification of the death rate equation. Year 0 (2013) is the omitted reference year. Standard errors clustered at the country level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 3 written to tables/tab3_event_study.tex\n")

# ================================================================
# Table 4: Robustness — Leave-One-Out and Alternative Specifications
# ================================================================

cat("=== Generating Table 4: Robustness ===\n")

# Extract robustness results
micro_res <- extract_triple(robust_models$micro_vs_large,
                            "post:pay_delay_z:micro")
raw_res <- extract_triple(robust_models$raw_intensity,
                          "post:I(avg_payment_days/10):small")

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Alternative Specifications for Firm Death Rate}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Baseline & Micro (0) vs & Raw Pay Days & Leave-One-Out \\\\\n")
cat(" &  & Large (10+) & (per 10 days) & Range \\\\\n")
cat("\\hline\n")

cat(sprintf("Triple-diff $\\hat{\\beta}_1$ & %.3f%s & %.3f%s & %.3f%s & [%.3f, %.3f] \\\\\n",
            res1$est, stars(res1$pval),
            micro_res$est, stars(micro_res$pval),
            raw_res$est, stars(raw_res$pval),
            min(loo_results$estimate), max(loo_results$estimate)))

cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & \\\\\n",
            res1$se, micro_res$se, raw_res$se))

cat("\\hline\n")
cat(sprintf("Observations & %s & %s & %s & --- \\\\\n",
            format(res1$n, big.mark = ","),
            format(micro_res$n, big.mark = ","),
            format(raw_res$n, big.mark = ",")))
cat(sprintf("Countries & 28 & 28 & 28 & 27 each \\\\\n"))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat("\\item \\textit{Notes:} Column (1) reproduces the baseline triple-difference on standardized payment delay. Column (2) restricts to micro firms (0 employees) vs.\\ large (10+). Column (3) uses raw average payment days divided by 10 as the intensity measure. Column (4) shows the range of the baseline coefficient when dropping each country in turn. All specifications include country$\\times$size, country$\\times$year, and size$\\times$year fixed effects. Standard errors clustered at the country level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 4 written to tables/tab4_robustness.tex\n")

# ================================================================
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ================================================================

cat("=== Generating SDE Table ===\n")

# Compute SDEs
compute_sde <- function(beta, se_beta, sd_y) {
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  classify <- function(s) {
    if (is.na(s)) return("---")
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s <= 0.005) return("Null")
    if (s <= 0.05) return("Small positive")
    if (s <= 0.15) return("Moderate positive")
    return("Large positive")
  }
  list(sde = sde, se_sde = se_sde, class = classify(sde))
}

# Panel A: Pooled
sde_death <- compute_sde(res1$est, res1$se, pre_stats$sd_death)
sde_surv <- compute_sde(res3$est, res3$se, pre_stats$sd_surv)

# Panel B: Heterogeneous — micro (0 emp) vs small (1-9)
# Split: micro firms only
panel_micro_only <- panel |>
  filter(sizeclas == "0", !is.na(death_rate))
panel_small_only <- panel |>
  filter(sizeclas %in% c("1-4", "5-9"),
         !is.na(death_rate))

m_micro_death <- tryCatch({
  feols(
    death_rate ~ post:pay_delay_z |
      geo + year,
    data = panel_micro_only,
    cluster = ~geo
  )
}, error = function(e) NULL)

m_small19_death <- tryCatch({
  feols(
    death_rate ~ post:pay_delay_z |
      geo + year,
    data = panel_small_only,
    cluster = ~geo
  )
}, error = function(e) NULL)

sd_death_micro <- sd(panel_micro_only$death_rate[panel_micro_only$year < 2014], na.rm = TRUE)
sd_death_small19 <- sd(panel_small_only$death_rate[panel_small_only$year < 2014], na.rm = TRUE)

if (!is.null(m_micro_death)) {
  micro_coef <- coef(m_micro_death)["post:pay_delay_z"]
  micro_se <- se(m_micro_death)["post:pay_delay_z"]
  sde_micro <- compute_sde(micro_coef, micro_se, sd_death_micro)
} else {
  micro_coef <- NA; micro_se <- NA; sde_micro <- list(sde = NA, se_sde = NA, class = "---")
}

if (!is.null(m_small19_death)) {
  small19_coef <- coef(m_small19_death)["post:pay_delay_z"]
  small19_se <- se(m_small19_death)["post:pay_delay_z"]
  sde_small19 <- compute_sde(small19_coef, small19_se, sd_death_small19)
} else {
  small19_coef <- NA; small19_se <- NA; sde_small19 <- list(sde = NA, se_sde = NA, class = "---")
}

# --- SDE notes string (single backslash in R = literal \ in output) ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (28 member states). ",
  "\\textbf{Research question:} Does the EU Late Payment Directive (2011/7/EU), ",
  "which mandated 30-day public-authority payment terms, improve small firm survival ",
  "in countries with pre-existing cultures of slow payment? ",
  "\\textbf{Policy mechanism:} The directive imposed a maximum 30-day payment ",
  "deadline for public authorities, automatic entitlement to 8\\%+ late-payment ",
  "interest, and EUR~40 flat-rate compensation per late invoice, creating legal ",
  "tools to shift bargaining power toward creditor firms. ",
  "\\textbf{Outcome definition:} Enterprise death rate from Eurostat Business ",
  "Demography (bd\\_9bd\\_sz\\_cl\\_r2), measuring annual enterprise deaths ",
  "as a percentage of active enterprises by country, size class, and year. ",
  "\\textbf{Treatment:} Continuous: standardized pre-directive average B2B payment ",
  "days by country (mean zero, unit variance), interacted with a small-firm indicator ",
  "(0--9 employees). ",
  "\\textbf{Data:} Eurostat Business Demography, 28 EU countries, 2010--2020, ",
  "country$\\times$size-class$\\times$year panel. ",
  "\\textbf{Method:} Triple-difference (time $\\times$ payment-culture intensity ",
  "$\\times$ firm-size class) with country$\\times$size, country$\\times$year, ",
  "and size$\\times$year fixed effects; standard errors clustered at country level. ",
  "\\textbf{Sample:} All EU-28 member states with non-missing business demography ",
  "data; size classes 0, 1--4, 5--9, 10+ employees. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

cat(sprintf("Death Rate & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            res1$est, res1$se, pre_stats$sd_death,
            sde_death$sde, sde_death$se_sde, sde_death$class))
cat(sprintf("Survival Rate (3yr) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
            res3$est, res3$se, pre_stats$sd_surv,
            sde_surv$sde, sde_surv$se_sde, sde_surv$class))

cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by firm size subsample)}} \\\\\n")

if (!is.na(micro_coef)) {
  cat(sprintf("Death Rate: Micro (0 emp) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
              micro_coef, micro_se, sd_death_micro,
              sde_micro$sde, sde_micro$se_sde, sde_micro$class))
}
if (!is.na(small19_coef)) {
  cat(sprintf("Death Rate: Small (1--9 emp) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
              small19_coef, small19_se, sd_death_small19,
              sde_small19$sde, sde_small19$se_sde, sde_small19$class))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\footnotesize\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("SDE table written to tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
