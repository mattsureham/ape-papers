## 05_tables.R — Generate all LaTeX tables for apep_1103

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness.rds"))
df <- results$data$df
panel <- readRDS(file.path(data_dir, "panel.rds"))

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════════════
cat("── Table 1: Summary Statistics ──\n")

# Full sample summary
full_vars <- df |>
  summarise(
    `OKP costs per insured (CHF)_mean` = mean(okp_total_pc),
    `OKP costs per insured (CHF)_sd` = sd(okp_total_pc),
    `OKP costs per insured (CHF)_min` = min(okp_total_pc),
    `OKP costs per insured (CHF)_max` = max(okp_total_pc),
    `OKP costs per insured (CHF)_n` = sum(!is.na(okp_total_pc))
  )

# Pre/post comparison
pre_stats <- df |> filter(year <= 2007) |>
  summarise(
    okp_mean = mean(okp_total_pc), okp_sd = sd(okp_total_pc),
    n = n()
  )
post_stats <- df |> filter(year >= 2008) |>
  summarise(
    okp_mean = mean(okp_total_pc), okp_sd = sd(okp_total_pc),
    n = n()
  )

# Key variables
summ_data <- tibble(
  Variable = c(
    "OKP costs per insured (CHF)", "~Pre-reform (2000--2007)", "~Post-reform (2008--2022)",
    "DI rate 2009 (per 1,000)", "Cantons", "Years", "Canton-year observations"
  ),
  Mean = c(
    sprintf("%.0f", mean(df$okp_total_pc)),
    sprintf("%.0f", pre_stats$okp_mean),
    sprintf("%.0f", post_stats$okp_mean),
    sprintf("%.1f", mean(df$di_rate_2009)),
    as.character(length(unique(df$canton))),
    sprintf("%d--%d", min(df$year), max(df$year)),
    as.character(nrow(df))
  ),
  SD = c(
    sprintf("%.0f", sd(df$okp_total_pc)),
    sprintf("%.0f", pre_stats$okp_sd),
    sprintf("%.0f", post_stats$okp_sd),
    sprintf("%.1f", sd(df$di_rate_2009)),
    "", "", ""
  ),
  Min = c(
    sprintf("%.0f", min(df$okp_total_pc)),
    "", "",
    sprintf("%.1f", min(df$di_rate_2009)),
    "", "", ""
  ),
  Max = c(
    sprintf("%.0f", max(df$okp_total_pc)),
    "", "",
    sprintf("%.1f", max(df$di_rate_2009)),
    "", "", ""
  )
)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Variable & Mean & SD & Min & Max \\\\\n",
  "\\midrule\n",
  paste(apply(summ_data, 1, function(r) {
    paste(r, collapse = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel of 26 Swiss cantons, 2000--2022. OKP costs are gross benefits per insured person in the mandatory health insurance (obligatorische Krankenpflegeversicherung), from the BAG Dashboard. DI rate 2009 is disability insurance pension recipients per 1,000 cantonal population, from BFS. Tilde prefix indicates subperiod statistics.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results
# ══════════════════════════════════════════════════════════════════════════════
cat("── Table 2: Main Results ──\n")

m1 <- results$main$m1
m2 <- results$main$m2
m3 <- results$main$m3
m4 <- results$main$m4
m5 <- results$main$m5

# Format regression table manually for control
make_row <- function(models, coef_name, label) {
  betas <- sapply(models, function(m) {
    cf <- coef(m)
    idx <- grep(coef_name, names(cf), fixed = TRUE)
    if (length(idx) == 0) return(c(NA, NA))
    c(cf[idx[1]], se(m)[idx[1]])
  })
  beta_str <- sapply(seq_along(models), function(i) {
    if (is.na(betas[1, i])) return("")
    stars <- ifelse(abs(betas[1, i] / betas[2, i]) > 2.58, "***",
             ifelse(abs(betas[1, i] / betas[2, i]) > 1.96, "**",
             ifelse(abs(betas[1, i] / betas[2, i]) > 1.65, "*", "")))
    sprintf("%.3f%s", betas[1, i], stars)
  })
  se_str <- sapply(seq_along(models), function(i) {
    if (is.na(betas[2, i])) return("")
    sprintf("(%.3f)", betas[2, i])
  })
  list(
    beta = paste(c(label, beta_str), collapse = " & "),
    se = paste(c("", se_str), collapse = " & ")
  )
}

# Build main results table
main_models <- list(m1, m2, m3, m4, m5)
n_obs <- sapply(main_models, function(m) nobs(m))

# Manual table for cleaner control
tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of DI Reform Exposure on OKP Health Costs}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& OKP/insured & log(OKP) & OKP/insured & OKP/insured & log(OKP) \\\\",
  "\\midrule"
)

# Row: DI rate × Post-2008
b1 <- coef(m1)[1]; s1 <- se(m1)[1]
b2 <- coef(m2)[1]; s2 <- se(m2)[1]
b4 <- coef(m4)[1]; s4 <- se(m4)[1]
b5 <- coef(m5)[1]; s5 <- se(m5)[1]

star <- function(b, s) {
  t <- abs(b/s)
  if (t > 2.58) "***" else if (t > 1.96) "**" else if (t > 1.65) "*" else ""
}

tab2_lines <- c(tab2_lines,
  sprintf("DI rate 2009 $\\times$ Post-2008 & %.3f%s & %.5f & & & \\\\",
          b1, star(b1, s1), b2),
  sprintf("& (%.3f) & (%.5f) & & & \\\\", s1, s2),
  "\\\\")

# Row for model 3 (two reforms)
b3a <- coef(m3)[1]; s3a <- se(m3)[1]
b3b <- coef(m3)[2]; s3b <- se(m3)[2]
tab2_lines <- c(tab2_lines,
  sprintf("DI rate 2009 $\\times$ Post-2008 & & & %.3f%s & & \\\\",
          b3a, star(b3a, s3a)),
  sprintf("& & & (%.3f) & & \\\\", s3a),
  sprintf("DI rate 2009 $\\times$ Post-2012 & & & %.3f%s & & \\\\",
          b3b, star(b3b, s3b)),
  sprintf("& & & (%.3f) & & \\\\", s3b),
  "\\\\")

# Row: Standardized dose
tab2_lines <- c(tab2_lines,
  sprintf("DI dose (std.) $\\times$ Post-2008 & & & & %.2f%s & %.5f \\\\",
          b4, star(b4, s4), b5),
  sprintf("& & & & (%.2f) & (%.5f) \\\\", s4, s5))

tab2_lines <- c(tab2_lines,
  "\\midrule",
  "Canton FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5)),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
          fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]], fitstat(m5, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dose-response difference-in-differences. The treatment dose is the 2009 DI pension rate per 1,000 population (columns 1--3) or its standardized version (columns 4--5). Standard errors clustered at the canton level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 3: Cost Decomposition
# ══════════════════════════════════════════════════════════════════════════════
cat("── Table 3: Cost Decomposition ──\n")

decomp <- results$decomposition$summary

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect on OKP Costs by Service Category}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Cost category & $\\hat{\\beta}$ & SE & Mean & Share of total \\\\"  ,
  "\\midrule"
)

total_mean <- mean(df$okp_total_pc, na.rm = TRUE)
for (i in 1:nrow(decomp)) {
  ct <- decomp$cost_type[i]
  b <- decomp$beta[i]
  s <- decomp$se[i]
  my <- decomp$mean_y[i]
  st <- star(b, s)
  share <- my / total_mean * 100
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %.3f%s & (%.3f) & %.0f & %.1f\\%% \\\\",
            ct, b, st, s, my, share))
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Total & %.3f%s & (%.3f) & %.0f & 100\\%% \\\\",
          coef(results$main$m1)[1], star(coef(results$main$m1)[1], se(results$main$m1)[1]),
          se(results$main$m1)[1], total_mean),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient from a separate regression of the cost category on DI rate 2009 $\\times$ Post-2008, with canton and year fixed effects. Standard errors clustered at the canton level. Mean is the sample average of the cost category in CHF per insured person. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:decomp}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_decomp.tex"))
cat("  Saved tab3_decomp.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 4: Robustness
# ══════════════════════════════════════════════════════════════════════════════
cat("── Table 4: Robustness ──\n")

rob_specs <- list(
  list(label = "Baseline", model = results$main$m1),
  list(label = "Canton-specific trends", model = robustness$canton_trends),
  list(label = "Exclude GE and TI", model = robustness$excl_outliers),
  list(label = "Shorter pre-period (2004+)", model = robustness$short_pre),
  list(label = "Log specification", model = robustness$log_spec)
)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & $\\hat{\\beta}$ & SE & $N$ \\\\",
  "\\midrule"
)

for (spec in rob_specs) {
  m <- spec$model
  b <- coef(m)[grep("di_rate_2009.*post_2008|di_rate_2009:post_2008", names(coef(m)))]
  if (length(b) == 0) b <- coef(m)[1]
  s <- se(m)[1]
  st <- star(b, s)
  fmt <- ifelse(abs(b) < 1, "%.5f", "%.3f")
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s%s & (%s) & %d \\\\",
            spec$label, sprintf(fmt, b), st, sprintf(fmt, s), nobs(m)))
}

# Add placebo
bp <- coef(robustness$placebo)[1]
sp <- se(robustness$placebo)[1]
tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Placebo: Post-2004 (pre-reform only) & %.3f & (%.3f) & %d \\\\",
          bp, sp, nobs(robustness$placebo)),
  sprintf("Jackknife range & [%.3f, %.3f] & & \\\\",
          min(robustness$jackknife$betas), max(robustness$jackknife$betas)))

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include canton and year fixed effects with standard errors clustered at the canton level. The baseline coefficient reports the effect of DI rate 2009 $\\times$ Post-2008 on OKP costs per insured. The placebo test restricts the sample to 2000--2007 and uses a false reform date of 2004. Jackknife range reports the coefficient range from 26 leave-one-canton-out regressions. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robust}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))
cat("  Saved tab4_robust.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 5: Heterogeneity
# ══════════════════════════════════════════════════════════════════════════════
cat("── Table 5: Heterogeneity ──\n")

het_specs <- list(
  list(label = "Full sample", model = results$main$m1),
  list(label = "German-speaking cantons", model = results$heterogeneity$german),
  list(label = "French/Italian cantons", model = results$heterogeneity$latin),
  list(label = "High-cost cantons (pre-reform)", model = results$heterogeneity$high_cost),
  list(label = "Low-cost cantons (pre-reform)", model = results$heterogeneity$low_cost)
)

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity by Canton Characteristics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Sample & $\\hat{\\beta}$ & SE & $N$ & Cantons \\\\",
  "\\midrule"
)

for (spec in het_specs) {
  m <- spec$model
  b <- coef(m)[1]; s <- se(m)[1]; st <- star(b, s)
  nc <- length(unique(model.matrix(m, type = "fixef")[, 1]))
  tab5_lines <- c(tab5_lines,
    sprintf("%s & %.3f%s & (%.3f) & %d & %d \\\\",
            spec$label, b, st, s, nobs(m), nc))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on DI rate 2009 $\\times$ Post-2008 from a separate regression on the indicated subsample. All specifications include canton and year FE with canton-clustered SEs. High/low cost split uses the median of pre-reform (2000--2007) average OKP costs. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:heterogeneity}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_heterogeneity.tex"))
cat("  Saved tab5_heterogeneity.tex\n")

# ══════════════════════════════════════════════════════════════════════════════
# SDE TABLE (Mandatory — Appendix F)
# ══════════════════════════════════════════════════════════════════════════════
cat("── SDE Table ──\n")

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

# Main outcome: OKP total per-capita
beta_main <- coef(results$main$m4)[1]  # Standardized dose
se_main <- se(results$main$m4)[1]
sd_y <- sd(df$okp_total_pc)
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Heterogeneity: German vs French/Italian
beta_german <- coef(results$heterogeneity$german)[1]
se_german <- se(results$heterogeneity$german)[1]
sd_y_german <- sd(df$okp_total_pc[df$german == 1])
# Use raw dose coefficient, scale by SD(dose) for SDE
sd_dose <- sd(df$di_rate_2009)
sde_german <- beta_german * sd_dose / sd_y_german
se_sde_german <- se_german * sd_dose / sd_y_german

beta_latin <- coef(results$heterogeneity$latin)[1]
se_latin <- se(results$heterogeneity$latin)[1]
sd_y_latin <- sd(df$okp_total_pc[df$german == 0])
sde_latin <- beta_latin * sd_dose / sd_y_latin
se_sde_latin <- se_latin * sd_dose / sd_y_latin

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Whether Switzerland's disability insurance reforms (5th revision 2008, 6a revision 2012), which shifted from compensating disability to preventing it through early intervention and reintegration, affected mandatory health insurance (OKP) per-capita costs. ",
  "\\textbf{Policy mechanism:} The IV reforms introduced early intervention measures, integration programs, and vocational rehabilitation to keep individuals with health limitations in the labor force rather than granting disability pensions, potentially altering their use of health services through changed health trajectories or substitution from disability benefits to medical treatment. ",
  "\\textbf{Outcome definition:} OKP gross benefits per insured person (Bruttoleistungen pro Versicherten), measuring total mandatory health insurance spending per capita in Swiss francs. ",
  "\\textbf{Treatment:} Continuous; DI pension rate per 1,000 cantonal population in 2009 (standardized, mean zero, SD one), measuring pre-reform disability burden and thus exposure to the reforms. ",
  "\\textbf{Data:} BAG Dashboard Krankenversicherung OKP (health costs, 1997--2024) merged with BFS PXWeb IV statistics (disability, 2009--2024); 26 cantons, 2000--2022, 598 canton-year observations. ",
  "\\textbf{Method:} Dose-response difference-in-differences with canton and year fixed effects; standard errors clustered at canton level. ",
  "\\textbf{Sample:} 26 Swiss cantons, excluding 2023--2024 due to potentially incomplete reporting; the analysis exploits cross-canton variation in disability insurance burden as a continuous treatment dose. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of OKP costs per insured. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("OKP costs/insured & Std.\\ dose $\\times$ Post-2008 & %.2f & %.0f & %.4f & %.4f & %s \\\\",
          beta_main, sd_y, sde_main, se_sde_main, classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("~~German-speaking & DI rate $\\times$ Post-2008 & %.3f & %.0f & %.4f & %.4f & %s \\\\",
          beta_german, sd_y_german, sde_german, se_sde_german, classify_sde(sde_german)),
  sprintf("~~French/Italian & DI rate $\\times$ Post-2008 & %.3f & %.0f & %.4f & %.4f & %s \\\\",
          beta_latin, sd_y_latin, sde_latin, se_sde_latin, classify_sde(sde_latin)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_tab, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n══ All tables generated ══\n")
cat("Files in tables/:\n")
for (f in list.files(tables_dir, pattern = "\\.tex$")) {
  cat("  ", f, "\n")
}
