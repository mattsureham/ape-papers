## 05_tables.R — Generate all LaTeX tables for PSL paper
## apep_0704: Paid Sick Leave and Worker Separation Dynamics

source("00_packages.R")

cat("=== Generating LaTeX tables ===\n")

# ── Load results ──
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
qwi_main <- readRDS("../data/qwi_main.rds")

# ────────────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ────────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

hi_exp <- qwi_main %>% filter(high_exposure, !post)

# Panel A: By treatment status
panel_a <- hi_exp %>%
  group_by(Group = ifelse(treated_state, "Treated", "Control")) %>%
  summarise(
    States = n_distinct(state_abbr),
    `Obs.` = n(),
    `Sep. Rate` = sprintf("%.2f", mean(sep_rate, na.rm = TRUE)),
    `(SD)` = sprintf("(%.2f)", sd(sep_rate, na.rm = TRUE)),
    `Hire Rate` = sprintf("%.2f", mean(hire_rate, na.rm = TRUE)),
    `Emp. (000s)` = sprintf("%.0f", mean(Emp, na.rm = TRUE) / 1000),
    .groups = "drop"
  )

# Panel B: By industry
panel_b <- hi_exp %>%
  group_by(Industry = ind_group) %>%
  summarise(
    `Obs.` = n(),
    `Sep. Rate` = sprintf("%.2f", mean(sep_rate, na.rm = TRUE)),
    `(SD)` = sprintf("(%.2f)", sd(sep_rate, na.rm = TRUE)),
    `Hire Rate` = sprintf("%.2f", mean(hire_rate, na.rm = TRUE)),
    `Emp. (000s)` = sprintf("%.0f", mean(Emp, na.rm = TRUE) / 1000),
    .groups = "drop"
  )

tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: High-Exposure Industries, Pre-Treatment}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & States & Obs. & Sep.\\ Rate & (SD) & Hire Rate & Emp.\\ (000s) \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: By Treatment Status}} \\\\[3pt]",
  paste0("Treated (PSL) & ", panel_a$States[2], " & ",
         panel_a$`Obs.`[2], " & ", panel_a$`Sep. Rate`[2], " & ",
         panel_a$`(SD)`[2], " & ", panel_a$`Hire Rate`[2], " & ",
         panel_a$`Emp. (000s)`[2], " \\\\"),
  paste0("Control & ", panel_a$States[1], " & ",
         panel_a$`Obs.`[1], " & ", panel_a$`Sep. Rate`[1], " & ",
         panel_a$`(SD)`[1], " & ", panel_a$`Hire Rate`[1], " & ",
         panel_a$`Emp. (000s)`[1], " \\\\[6pt]"),
  "\\multicolumn{7}{l}{\\textit{Panel B: By Industry}} \\\\[3pt]",
  paste0(panel_b$Industry[1], " & --- & ", panel_b$`Obs.`[1], " & ",
         panel_b$`Sep. Rate`[1], " & ", panel_b$`(SD)`[1], " & ",
         panel_b$`Hire Rate`[1], " & ", panel_b$`Emp. (000s)`[1], " \\\\"),
  paste0(panel_b$Industry[2], " & --- & ", panel_b$`Obs.`[2], " & ",
         panel_b$`Sep. Rate`[2], " & ", panel_b$`(SD)`[2], " & ",
         panel_b$`Hire Rate`[2], " & ", panel_b$`Emp. (000s)`[2], " \\\\"),
  paste0(panel_b$Industry[3], " & --- & ", panel_b$`Obs.`[3], " & ",
         panel_b$`Sep. Rate`[3], " & ", panel_b$`(SD)`[3], " & ",
         panel_b$`Hire Rate`[3], " & ", panel_b$`Emp. (000s)`[3], " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment averages for high-exposure industries (Accommodation/Food, Healthcare, Retail) in the QWI. Sep.\\ Rate and Hire Rate are per 100 workers per quarter. Sample: state$\\times$industry$\\times$quarter, 2005--2011 (pre-first-treatment).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_tex, "../tables/tab1_sumstats.tex")

# ────────────────────────────────────────────────────────────────────
# TABLE 2: Main DDD Results
# ────────────────────────────────────────────────────────────────────
cat("Generating Table 2: Main DDD Results...\n")

# Generate DDD table manually for clean LaTeX
ddd_models <- list(results$ddd_sep, results$ddd_hire, results$ddd_newhire, results$ddd_turnover)
ddd_names <- c("Sep. Rate", "Hire Rate", "New Hire Rate", "Turnover")

tab2_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Triple-Difference: Effect of PSL Mandates on Worker Flows}",
  "\\label{tab:ddd}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  paste0(" & ", paste(ddd_names, collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Treated $\\times$ Post $\\times$ High-Exp. & ",
         paste(sapply(seq_along(ddd_models), function(i) {
           b <- coef(ddd_models[[i]])
           s <- se(ddd_models[[i]])
           p <- pvalue(ddd_models[[i]])
           stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
           sprintf("%.3f%s", b, stars)
         }), collapse = " & "),
         " \\\\"),
  paste0(" & ",
         paste(sapply(ddd_models, function(m) sprintf("(%.3f)", se(m))), collapse = " & "),
         " \\\\[6pt]"),
  paste0("State $\\times$ Industry FE & ", paste(rep("Yes", 4), collapse = " & "), " \\\\"),
  paste0("State $\\times$ Quarter FE & ", paste(rep("Yes", 4), collapse = " & "), " \\\\"),
  paste0("Industry $\\times$ Quarter FE & ", paste(rep("Yes", 4), collapse = " & "), " \\\\"),
  paste0("Clustering & ", paste(rep("State", 4), collapse = " & "), " \\\\"),
  paste0("Observations & ", paste(sapply(ddd_models, function(m) format(nobs(m), big.mark = ",")), collapse = " & "), " \\\\"),
  paste0("$R^2$ & ", paste(sapply(ddd_models, function(m) sprintf("%.3f", r2(m, "r2"))), collapse = " & "), " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variables are per 100 workers per quarter (columns 1--3) or turnover rate (column 4). High-exposure industries: Accommodation/Food (NAICS 72), Retail (44--45), Healthcare (62). Low-exposure: Finance (52), Professional Services (54). State-clustered standard errors in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_tex, "../tables/tab2_ddd.tex")

# ────────────────────────────────────────────────────────────────────
# TABLE 3: Industry Heterogeneity
# ────────────────────────────────────────────────────────────────────
cat("Generating Table 3: Industry Heterogeneity...\n")

# Generate industry table manually
ind_mods <- rob$ind_results
ind_names <- c("Accomm./Food", "Retail", "Healthcare")

tab3_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Industry Decomposition: Separation Rate Effects by Sector}",
  "\\label{tab:industry}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  paste0(" & ", paste(ind_names, collapse = " & "), " \\\\"),
  "\\hline",
  paste0("Treated $\\times$ Post $\\times$ Industry & ",
         paste(sapply(names(ind_mods), function(nm) {
           m <- ind_mods[[nm]]
           p <- pvalue(m)
           stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
           sprintf("%.3f%s", coef(m), stars)
         }), collapse = " & "),
         " \\\\"),
  paste0(" & ",
         paste(sapply(names(ind_mods), function(nm) sprintf("(%.3f)", se(ind_mods[[nm]]))),
               collapse = " & "),
         " \\\\[6pt]"),
  paste0("Three-Way FE & ", paste(rep("Yes", 3), collapse = " & "), " \\\\"),
  paste0("Clustering & ", paste(rep("State", 3), collapse = " & "), " \\\\"),
  paste0("Observations & ",
         paste(sapply(names(ind_mods), function(nm) format(nobs(ind_mods[[nm]]), big.mark = ",")),
               collapse = " & "),
         " \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column estimates the DDD separately for one high-exposure industry against Finance and Professional Services as controls. Dependent variable: quarterly separation rate per 100 workers. State-clustered standard errors in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_tex, "../tables/tab3_industry.tex")

# ────────────────────────────────────────────────────────────────────
# TABLE 4: Age Heterogeneity
# ────────────────────────────────────────────────────────────────────
cat("Generating Table 4: Age Heterogeneity...\n")

age_tab <- data.frame(
  `Age Group` = character(),
  Coefficient = character(),
  SE = character(),
  N = character(),
  stringsAsFactors = FALSE
)

for (ag in names(rob$age_results)) {
  mod <- rob$age_results[[ag]]
  stars <- ifelse(pvalue(mod) < 0.01, "***",
           ifelse(pvalue(mod) < 0.05, "**",
           ifelse(pvalue(mod) < 0.1, "*", "")))
  age_tab <- rbind(age_tab, data.frame(
    Age = ag,
    Coefficient = sprintf("%.3f%s", coef(mod), stars),
    SE = sprintf("(%.3f)", se(mod)),
    N = format(nobs(mod), big.mark = ","),
    stringsAsFactors = FALSE
  ))
}

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Age Heterogeneity: DDD Separation Rate Effects by Age Group}",
  "\\label{tab:age}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Age Group & Coefficient & SE & Obs. \\\\",
  "\\hline",
  apply(age_tab, 1, function(r) paste(r, collapse = " & ") %>% paste0(" \\\\")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row estimates the DDD (Treated $\\times$ Post $\\times$ High-Exposure) for a single age group. Dependent variable: quarterly separation rate per 100 workers. Three-way fixed effects and state-clustered standard errors throughout. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_tex, "../tables/tab4_age.tex")

# ────────────────────────────────────────────────────────────────────
# TABLE 5: Robustness
# ────────────────────────────────────────────────────────────────────
cat("Generating Table 5: Robustness...\n")

# Combine robustness checks into a single table
rob_tab_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks: DDD Separation Rate}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Specification & Coef. & SE & $p$-value & Obs. \\\\",
  "\\hline",
  sprintf("Baseline DDD & %.3f & %.3f & %.3f & %s \\\\",
          coef(results$ddd_sep), se(results$ddd_sep),
          pvalue(results$ddd_sep), format(nobs(results$ddd_sep), big.mark = ",")),
  sprintf("Excl.\\ COVID (2020Q1--2021Q2) & %.3f & %.3f & %.3f & %s \\\\",
          coef(rob$ddd_nocovid), se(rob$ddd_nocovid),
          pvalue(rob$ddd_nocovid), format(nobs(rob$ddd_nocovid), big.mark = ",")),
  sprintf("Placebo: Finance + Prof.\\ Svcs. & %.3f & %.3f & %.3f & %s \\\\",
          coef(rob$placebo_mod), se(rob$placebo_mod),
          pvalue(rob$placebo_mod), format(nobs(rob$placebo_mod), big.mark = ",")),
  sprintf("Leave-one-out range & [%.3f, %.3f] & --- & --- & --- \\\\",
          min(rob$loo_results$coef), max(rob$loo_results$coef)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include state$\\times$industry, state$\\times$quarter, and industry$\\times$quarter fixed effects with state-clustered standard errors. Placebo uses only Finance (NAICS 52) and Professional Services (54) industries. Leave-one-out shows the coefficient range when each treated state is dropped in turn.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(rob_tab_tex, "../tables/tab5_robustness.tex")

# ────────────────────────────────────────────────────────────────────
# SDE TABLE (Appendix F1)
# ────────────────────────────────────────────────────────────────────
cat("Generating SDE Table...\n")

sd_y_sep <- results$sd_sep
sd_y_hire <- results$sd_hire

# Main outcomes from DDD
sde_data <- data.frame(
  Outcome = c("Separation Rate (All High-Exp.)",
               "Separation Rate (Retail)",
               "Separation Rate (14--18)",
               "Separation Rate (19--21)",
               "Hire Rate (All High-Exp.)",
               "Turnover Rate"),
  Beta = c(coef(results$ddd_sep),
           coef(rob$ind_results[["Retail"]]),
           coef(rob$age_results[["14-18"]]),
           coef(rob$age_results[["19-21"]]),
           coef(results$ddd_hire),
           coef(results$ddd_turnover)),
  SE_beta = c(se(results$ddd_sep),
              se(rob$ind_results[["Retail"]]),
              se(rob$age_results[["14-18"]]),
              se(rob$age_results[["19-21"]]),
              se(results$ddd_hire),
              se(results$ddd_turnover)),
  SD_Y = c(sd_y_sep, sd_y_sep,
           sd(qwi_main$sep_rate[qwi_main$high_exposure & !qwi_main$post &
                                 qwi_main$treated_state], na.rm = TRUE),
           sd(qwi_main$sep_rate[qwi_main$high_exposure & !qwi_main$post &
                                 qwi_main$treated_state], na.rm = TRUE),
           sd_y_hire,
           sd(qwi_main$turnover_rate[qwi_main$high_exposure & !qwi_main$post &
                                      qwi_main$treated_state], na.rm = TRUE)),
  stringsAsFactors = FALSE
)

sde_data$SDE <- sde_data$Beta / sde_data$SD_Y
sde_data$SE_SDE <- sde_data$SE_beta / sde_data$SD_Y
sde_data$Classification <- ifelse(sde_data$SDE < -0.15, "Large negative",
                           ifelse(sde_data$SDE < -0.05, "Moderate negative",
                           ifelse(sde_data$SDE < -0.005, "Small negative",
                           ifelse(sde_data$SDE < 0.005, "Null",
                           ifelse(sde_data$SDE < 0.05, "Small positive",
                           ifelse(sde_data$SDE < 0.15, "Moderate positive",
                                  "Large positive"))))))

sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  apply(sde_data, 1, function(r) {
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            r[1], as.numeric(r[2]), as.numeric(r[3]), as.numeric(r[4]),
            as.numeric(r[5]), as.numeric(r[6]), r[7])
  }),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} \\textbf{Country:} United States. ",
         "\\textbf{Research question:} Do mandatory paid sick leave (PSL) laws reduce worker separations in high-exposure service industries? ",
         "\\textbf{Policy mechanism:} State PSL mandates require employers to provide paid time off for illness, preventive care, or care of family members, typically accruing at 1 hour per 30--40 hours worked, with annual caps of 24--72 hours. Before mandates, workers in Accommodation/Food, Retail, and Healthcare industries had the lowest rates of employer-provided PSL and the highest separation rates. ",
         "\\textbf{Outcome definition:} Quarterly separation rate per 100 workers from the Quarterly Workforce Indicators (QWI). ",
         "\\textbf{Treatment:} Binary; state adopted mandatory PSL law. ",
         "\\textbf{Data:} Census LEHD QWI, state$\\times$industry$\\times$quarter, 2005--2023, 51 states. ",
         "\\textbf{Method:} Triple-difference (treated state $\\times$ post $\\times$ high-exposure industry) with three-way fixed effects. State-clustered SEs. ",
         "\\textbf{Sample:} 19,075 state-industry-quarter observations; 16 treated states, 35 controls; 5 NAICS sectors. ",
         "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation among treated states. ",
         "Classification refers to magnitude, not statistical significance: ",
         "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."),
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("SDE classifications:\n")
print(sde_data[, c("Outcome", "SDE", "Classification")])

cat("\n=== All tables generated ===\n")
