## 05_tables.R — Generate all LaTeX tables
## apep_1164: The Formalization Dividend
source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel_clean.rds"))
panel_nc <- readRDS(file.path(data_dir, "panel_no_covid.rds"))
treatment <- readRDS(file.path(data_dir, "treatment_intensity.rds"))
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Pre-treatment (2019) by treatment intensity tercile
panel_2019 <- panel %>%
  filter(year == 2019) %>%
  mutate(
    tercile = cut(ven_share,
                  breaks = quantile(ven_share, c(0, 1/3, 2/3, 1)),
                  labels = c("Low", "Medium", "High"),
                  include.lowest = TRUE)
  )

summ_rows <- panel_2019 %>%
  group_by(tercile) %>%
  summarise(
    N = n(),
    `Ven. Share (\\%)` = sprintf("%.1f", mean(ven_share)),
    `Empl. Rate` = sprintf("%.1f", mean(to, na.rm=TRUE)),
    `Unemp. Rate` = sprintf("%.1f", mean(td, na.rm=TRUE)),
    `Participation` = sprintf("%.1f", mean(tgp, na.rm=TRUE)),
    `Underempl.` = sprintf("%.1f", mean(ts, na.rm=TRUE)),
    `Pop. (000s)` = sprintf("%.0f", mean(pop_total, na.rm=TRUE)),
    .groups = "drop"
  )

# Add full sample row
full_row <- panel_2019 %>%
  summarise(
    tercile = "Full Sample",
    N = n(),
    `Ven. Share (\\%)` = sprintf("%.1f", mean(ven_share)),
    `Empl. Rate` = sprintf("%.1f", mean(to, na.rm=TRUE)),
    `Unemp. Rate` = sprintf("%.1f", mean(td, na.rm=TRUE)),
    `Participation` = sprintf("%.1f", mean(tgp, na.rm=TRUE)),
    `Underempl.` = sprintf("%.1f", mean(ts, na.rm=TRUE)),
    `Pop. (000s)` = sprintf("%.0f", mean(pop_total, na.rm=TRUE))
  )

summ_all <- bind_rows(summ_rows, full_row)

# Write LaTeX
tab1 <- "\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Treatment Department Characteristics (2019)}
\\label{tab:summary}
\\begin{tabular}{lccccccc}
\\hline\\hline
& $N$ & Ven. Share & Empl. & Unemp. & Partic. & Underempl. & Pop. \\\\
& & (\\%) & Rate & Rate & Rate & Rate & (000s) \\\\
\\hline\n"

for (i in 1:nrow(summ_all)) {
  row <- summ_all[i, ]
  tab1 <- paste0(tab1,
    row$tercile, " & ", row$N, " & ", row$`Ven. Share (\\%)`, " & ",
    row$`Empl. Rate`, " & ", row$`Unemp. Rate`, " & ",
    row$Participation, " & ", row$`Underempl.`, " & ",
    row$`Pop. (000s)`, " \\\\\n")
  if (i == nrow(summ_all) - 1) tab1 <- paste0(tab1, "\\hline\n")
}

tab1 <- paste0(tab1, "\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Departments split into terciles by ETPV pre-registration intensity
(registrations per 2019 population). Venezuelan share ranges from 0.4\\% (Caquet\\'a) to
17.4\\% (Norte de Santander). Source: DANE GEIH Department Annex (2024) and
Migraci\\'on Colombia ETPV Registry via datos.gov.co.
\\end{tablenotes}
\\end{table}\n")

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))
cat("Written: tab1_summary.tex\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

# Use modelsummary for clean LaTeX output
mod_list <- list(
  "(1)" = main_models$m2_to,
  "(2)" = main_models$m2_td,
  "(3)" = main_models$m2_tgp,
  "(4)" = main_models$m2_ts
)

# Extract WCB p-values
wcb_row <- data.frame(
  term = "WCB $p$-value",
  `(1)` = sprintf("%.3f", main_models$boot_to$p_val),
  `(2)` = sprintf("%.3f", main_models$boot_td$p_val),
  `(3)` = sprintf("%.3f", main_models$boot_tgp$p_val),
  `(4)` = "---",
  check.names = FALSE
)

tab2_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Effect of ETPV Regularization on Department-Level Labor Market Outcomes}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\hline\\hline
& \\multicolumn{4}{c}{Dependent Variable} \\\\
\\cmidrule(lr){2-5}
& Empl. Rate & Unemp. Rate & Partic. Rate & Underempl. \\\\
& (1) & (2) & (3) & (4) \\\\
\\hline\n"

# Extract coefficients
mods <- list(main_models$m2_to, main_models$m2_td, main_models$m2_tgp, main_models$m2_ts)
coefs <- sapply(mods, function(m) coef(m)["treat_intensity"])
ses <- sapply(mods, function(m) se(m)["treat_intensity"])
pvals <- sapply(mods, function(m) pvalue(m)["treat_intensity"])
stars <- ifelse(pvals < 0.01, "***", ifelse(pvals < 0.05, "**", ifelse(pvals < 0.1, "*", "")))

tab2_tex <- paste0(tab2_tex,
  "Ven. Share $\\times$ Post & ",
  paste(sprintf("%.3f%s", coefs, stars), collapse = " & "), " \\\\\n",
  " & ", paste(sprintf("(%.3f)", ses), collapse = " & "), " \\\\\n",
  " & ", paste(sprintf("[%.3f]", c(main_models$boot_to$p_val,
                                    main_models$boot_td$p_val,
                                    main_models$boot_tgp$p_val, NA)), collapse = " & "), " \\\\\n")

# Fixed effects and stats
n_obs <- sapply(mods, function(m) m$nobs)
r2w <- sapply(mods, function(m) round(fitstat(m, "wr2")[[1]], 3))

tab2_tex <- paste0(tab2_tex,
  "\\hline\n",
  "Department FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", paste(n_obs, collapse = " & "), " \\\\\n",
  "Within $R^2$ & ", paste(sprintf("%.3f", r2w), collapse = " & "), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Each column reports a separate regression of the dependent variable on ",
  "the interaction of pre-treatment Venezuelan share (ETPV registrations per population) with a ",
  "post-2021 indicator. Panel of 23 Colombian departments, 2015--2024, excluding 2020 (COVID). ",
  "Clustered standard errors by department in parentheses. Wild cluster bootstrap $p$-values ",
  "(Webb weights, 9{,}999 iterations) in brackets. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tab2_tex, file.path(table_dir, "tab2_main.tex"))
cat("Written: tab2_main.tex\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

es_to <- coeftable(main_models$m3_to)
es_td <- coeftable(main_models$m3_td)

# Build event study table
tab3_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Event Study: Year-by-Year Effects of Venezuelan Concentration}
\\label{tab:eventstudy}
\\begin{tabular}{lcccc}
\\hline\\hline
& \\multicolumn{2}{c}{Employment Rate} & \\multicolumn{2}{c}{Unemployment Rate} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
Event Year & Coeff. & SE & Coeff. & SE \\\\
\\hline\n"

event_labels <- c("$t-6$ (2015)", "$t-5$ (2016)", "$t-4$ (2017)",
                   "$t-3$ (2018)", "$t-2$ (2019)", "$t$ (2021)",
                   "$t+1$ (2022)", "$t+2$ (2023)", "$t+3$ (2024)")
# ref year is -2 (2019), so coefficients are for -6,-5,-4,-3, 0,1,2,3

for (i in 1:nrow(es_to)) {
  label <- event_labels[i]
  to_coef <- sprintf("%.3f", es_to[i, 1])
  to_se <- sprintf("(%.3f)", es_to[i, 2])
  td_coef <- sprintf("%.3f", es_td[i, 1])
  td_se <- sprintf("(%.3f)", es_td[i, 2])

  tab3_tex <- paste0(tab3_tex, label, " & ", to_coef, " & ", to_se,
                     " & ", td_coef, " & ", td_se, " \\\\\n")
}

# Add reference year
tab3_tex <- paste0(tab3_tex[1],
  sub("\\$t-3\\$", "$t-2$ (2019) & \\\\multicolumn{4}{c}{Reference Year} \\\\\\\\\n$t-3$",
      tab3_tex))

tab3_tex <- paste0(tab3_tex,
  "\\hline\n",
  "Pre-trend $F$-test & \\multicolumn{2}{c}{$p = 0.291$} & \\multicolumn{2}{c}{$p = 0.273$} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Coefficients from regressing the outcome on interactions of Venezuelan ",
  "share with year dummies, with department and year fixed effects. Reference year is 2019 ",
  "($t-2$). 2020 excluded due to COVID. Pre-trend $F$-test reports the $p$-value from testing ",
  "that all pre-treatment interactions equal zero. Standard errors clustered by department.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tab3_tex, file.path(table_dir, "tab3_eventstudy.tex"))
cat("Written: tab3_eventstudy.tex\n")

# ============================================================
# Table 4: Robustness Checks
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

rob_specs <- data.frame(
  Specification = c(
    "Baseline (excl. 2020)",
    "Including 2020",
    "Dept.-specific trends",
    "Binary treatment",
    "Top quartile treatment",
    "Excl. Norte de Santander",
    "Excl. NdS + La Guajira",
    "Placebo (2018 treatment)"
  ),
  Coef = c(
    coef(main_models$m2_to)["treat_intensity"],
    coef(main_models$m1_to)["treat_intensity"],
    coef(rob_models$m_trends_to)["treat_intensity"],
    coef(rob_models$m_binary)["high_ven_post"],
    coef(rob_models$m_q4)["treat_quartile"],
    coef(rob_models$m_loo_to)["treat_intensity"],
    NA,  # will fill
    coef(rob_models$m_placebo_to)["treat_placebo"]
  ),
  SE = c(
    se(main_models$m2_to)["treat_intensity"],
    se(main_models$m1_to)["treat_intensity"],
    se(rob_models$m_trends_to)["treat_intensity"],
    se(rob_models$m_binary)["high_ven_post"],
    se(rob_models$m_q4)["treat_quartile"],
    se(rob_models$m_loo_to)["treat_intensity"],
    NA,
    se(rob_models$m_placebo_to)["treat_placebo"]
  ),
  N = c(207, 230, 207, 207, 207, 198, NA, 138),
  stringsAsFactors = FALSE
)

# Fill in LOO2 values
panel_nc2 <- readRDS(file.path(data_dir, "panel_no_covid.rds")) %>%
  filter(!department %in% c("Norte de Santander", "La Guajira"))
m_loo2 <- feols(to ~ treat_intensity | dept_fe + year_fe,
                data = panel_nc2 %>% mutate(treat_intensity = ven_share * as.integer(year >= 2021),
                                            dept_fe = factor(department), year_fe = factor(year)),
                cluster = ~department)
rob_specs$Coef[7] <- coef(m_loo2)["treat_intensity"]
rob_specs$SE[7] <- se(m_loo2)["treat_intensity"]
rob_specs$N[7] <- nobs(m_loo2)

tab4_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks: Employment Rate}
\\label{tab:robustness}
\\begin{tabular}{lccc}
\\hline\\hline
Specification & Coefficient & SE & $N$ \\\\
\\hline\n"

for (i in 1:nrow(rob_specs)) {
  pval <- 2 * pt(-abs(rob_specs$Coef[i] / rob_specs$SE[i]), df = 22)
  star <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.1, "*", "")))
  tab4_tex <- paste0(tab4_tex,
    rob_specs$Specification[i], " & ",
    sprintf("%.3f%s", rob_specs$Coef[i], star), " & ",
    sprintf("(%.3f)", rob_specs$SE[i]), " & ",
    rob_specs$N[i], " \\\\\n")
}

tab4_tex <- paste0(tab4_tex,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the treatment variable from a ",
  "separate regression of the employment rate (TO) with department and year fixed effects. ",
  "``Binary treatment'' uses an above-median Venezuelan share indicator. ``Top quartile'' uses ",
  "the highest-concentration quartile. Placebo uses a 2018 treatment date on pre-period data only. ",
  "Standard errors clustered by department. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))
cat("Written: tab4_robustness.tex\n")

# ============================================================
# Table 5: Heterogeneity
# ============================================================
cat("\n=== Table 5: Heterogeneity ===\n")

tab5_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity: Employment Effects by Baseline Labor Market Conditions}
\\label{tab:heterogeneity}
\\begin{tabular}{lcc}
\\hline\\hline
& \\multicolumn{2}{c}{Employment Rate} \\\\
\\cmidrule(lr){2-3}
& By Baseline & By Baseline \\\\
& Underempl. & Employment \\\\
& (1) & (2) \\\\
\\hline\n"

# Extract from heterogeneity models
het1 <- rob_models$m_het_to
het2 <- rob_models$m_het_emp

coef1_main <- coef(het1)["treat_intensity"]
se1_main <- se(het1)["treat_intensity"]
coef1_int <- coef(het1)["treat_intensity:high_informal"]
se1_int <- se(het1)["treat_intensity:high_informal"]

coef2_main <- coef(het2)["treat_intensity"]
se2_main <- se(het2)["treat_intensity"]
coef2_int <- coef(het2)["treat_intensity:high_emp"]
se2_int <- se(het2)["treat_intensity:high_emp"]

p1_int <- pvalue(het1)["treat_intensity:high_informal"]
p2_int <- pvalue(het2)["treat_intensity:high_emp"]
star1 <- ifelse(p1_int < 0.01, "***", ifelse(p1_int < 0.05, "**", ifelse(p1_int < 0.1, "*", "")))
star2 <- ifelse(p2_int < 0.01, "***", ifelse(p2_int < 0.05, "**", ifelse(p2_int < 0.1, "*", "")))

tab5_tex <- paste0(tab5_tex,
  "Ven. Share $\\times$ Post & ", sprintf("%.3f", coef1_main), " & ", sprintf("%.3f", coef2_main), " \\\\\n",
  " & (", sprintf("%.3f", se1_main), ") & (", sprintf("%.3f", se2_main), ") \\\\\n",
  "$\\times$ High Baseline & ", sprintf("%.3f%s", coef1_int, star1), " & ", sprintf("%.3f%s", coef2_int, star2), " \\\\\n",
  " & (", sprintf("%.3f", se1_int), ") & (", sprintf("%.3f", se2_int), ") \\\\\n",
  "\\hline\n",
  "Sum: High baseline & ", sprintf("%.3f", coef1_main + coef1_int), " & ", sprintf("%.3f", coef2_main + coef2_int), " \\\\\n",
  "Department FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "Observations & 207 & 207 \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Column (1) interacts the treatment with an indicator for above-median ",
  "baseline (2019) underemployment rate. Column (2) interacts with above-median baseline employment ",
  "rate. ``Sum: High baseline'' reports the total effect for departments with high baseline values. ",
  "Standard errors clustered by department. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tab5_tex, file.path(table_dir, "tab5_heterogeneity.tex"))
cat("Written: tab5_heterogeneity.tex\n")

# ============================================================
# Table F1: SDE Appendix (MANDATORY)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs for main outcomes
# SDE = beta * SD(X) / SD(Y) for continuous treatment
sd_x <- sd(panel_nc$ven_share[panel_nc$post == 0])
sd_y_to <- sd(panel_nc$to[panel_nc$post == 0], na.rm = TRUE)
sd_y_td <- sd(panel_nc$td[panel_nc$post == 0], na.rm = TRUE)
sd_y_tgp <- sd(panel_nc$tgp[panel_nc$post == 0], na.rm = TRUE)

beta_to <- coef(main_models$m2_to)["treat_intensity"]
se_to <- se(main_models$m2_to)["treat_intensity"]
beta_td <- coef(main_models$m2_td)["treat_intensity"]
se_td <- se(main_models$m2_td)["treat_intensity"]
beta_tgp <- coef(main_models$m2_tgp)["treat_intensity"]
se_tgp <- se(main_models$m2_tgp)["treat_intensity"]

sde_to <- beta_to * sd_x / sd_y_to
se_sde_to <- se_to * sd_x / sd_y_to
sde_td <- beta_td * sd_x / sd_y_td
se_sde_td <- se_td * sd_x / sd_y_td
sde_tgp <- beta_tgp * sd_x / sd_y_tgp
se_sde_tgp <- se_tgp * sd_x / sd_y_tgp

classify <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Panel A: Pooled
sde_panel_a <- data.frame(
  Outcome = c("Employment Rate", "Unemployment Rate", "Participation Rate"),
  Beta = c(beta_to, beta_td, beta_tgp),
  SE = c(se_to, se_td, se_tgp),
  SD_Y = c(sd_y_to, sd_y_td, sd_y_tgp),
  SDE = c(sde_to, sde_td, sde_tgp),
  SE_SDE = c(se_sde_to, se_sde_td, se_sde_tgp),
  Classification = c(classify(sde_to), classify(sde_td), classify(sde_tgp))
)

# Panel B: Heterogeneous (by baseline employment)
# High-employment departments: total effect = main + interaction
het_total_to <- coef2_main + coef2_int
het_se_to <- sqrt(se2_main^2 + se2_int^2)  # approximate
sde_het_to <- het_total_to * sd_x / sd_y_to
se_sde_het_to <- het_se_to * sd_x / sd_y_to

# Low-employment departments: main effect only
sde_low_to <- coef2_main * sd_x / sd_y_to
se_sde_low_to <- se2_main * sd_x / sd_y_to

sde_panel_b <- data.frame(
  Outcome = c("Employment Rate (High Baseline)", "Employment Rate (Low Baseline)"),
  Beta = c(het_total_to, coef2_main),
  SE = c(het_se_to, se2_main),
  SD_Y = c(sd_y_to, sd_y_to),
  SDE = c(sde_het_to, sde_low_to),
  SE_SDE = c(se_sde_het_to, se_sde_low_to),
  Classification = c(classify(sde_het_to), classify(sde_low_to))
)

# Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Colombia. ",
  "\\textbf{Research question:} Does mass regularization of Venezuelan immigrants through the ETPV ",
  "program affect aggregate labor market outcomes in Colombian departments? ",
  "\\textbf{Policy mechanism:} The ETPV (Estatuto Temporal de Protecci\\'on para Migrantes Venezolanos) ",
  "granted 10-year work permits to approximately 1.8 million Venezuelan migrants, enabling formal ",
  "employment, social security enrollment, and financial inclusion for a population previously ",
  "working almost entirely in the informal sector. ",
  "\\textbf{Outcome definition:} Employment rate (tasa de ocupaci\\'on), unemployment rate (tasa de ",
  "desocupaci\\'on), and labor force participation rate (tasa global de participaci\\'on) from DANE GEIH. ",
  "\\textbf{Treatment:} Continuous; department-level ETPV pre-registrations per 2019 population, ",
  "interacted with a post-2021 indicator. ",
  "\\textbf{Data:} DANE GEIH Department Annex (2015--2024) and Migraci\\'on Colombia ETPV Registry; ",
  "23 departments, 207 department-year observations (excluding 2020). ",
  "\\textbf{Method:} Two-way fixed effects (department + year) with continuous treatment intensity; ",
  "standard errors clustered by department with wild cluster bootstrap (Webb weights). ",
  "\\textbf{Sample:} All 23 Colombian departments with GEIH coverage, annual frequency, excluding 2020 ",
  "due to COVID lockdown disruptions. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the pre-treatment ",
  "standard deviation of Venezuelan share and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- "\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\hline\n"

for (i in 1:nrow(sde_panel_a)) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_panel_a$Outcome[i], " & ",
    sprintf("%.3f", sde_panel_a$Beta[i]), " & ",
    sprintf("%.3f", sde_panel_a$SE[i]), " & ",
    sprintf("%.2f", sde_panel_a$SD_Y[i]), " & ",
    sprintf("%.4f", sde_panel_a$SDE[i]), " & ",
    sprintf("%.4f", sde_panel_a$SE_SDE[i]), " & ",
    sde_panel_a$Classification[i], " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by baseline employment rate)}} \\\\
\\hline\n")

for (i in 1:nrow(sde_panel_b)) {
  tabF1_tex <- paste0(tabF1_tex,
    sde_panel_b$Outcome[i], " & ",
    sprintf("%.3f", sde_panel_b$Beta[i]), " & ",
    sprintf("%.3f", sde_panel_b$SE[i]), " & ",
    sprintf("%.2f", sde_panel_b$SD_Y[i]), " & ",
    sprintf("%.4f", sde_panel_b$SDE[i]), " & ",
    sprintf("%.4f", sde_panel_b$SE_SDE[i]), " & ",
    sde_panel_b$Classification[i], " \\\\\n")
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{table}\n")

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))
cat("Written: tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
