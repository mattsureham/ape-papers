## 05_tables.R — Generate all tables including SDE appendix
## Child Labor Law Relaxations and Teen Employment

source("00_packages.R")

# --- Load results ---
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
all_ind <- readRDS("../data/all_industry_panel.rds")
setDT(all_ind)
ind_panel <- readRDS("../data/industry_panel.rds")
setDT(ind_panel)

cat("=== GENERATING TABLES ===\n\n")

# =========================================================================
# Table 1: Summary Statistics
# =========================================================================
cat("--- Table 1: Summary Statistics ---\n")

ddd_data <- all_ind[agegrp %in% c("A01", "A03")]

# Pre-treatment summary
pre <- ddd_data[post == 0]

sum_stats <- pre[, .(
  mean_emp = mean(Emp, na.rm = TRUE),
  sd_emp = sd(Emp, na.rm = TRUE),
  mean_hires = mean(HirA, na.rm = TRUE),
  sd_hires = sd(HirA, na.rm = TRUE),
  mean_earns = mean(EarnS, na.rm = TRUE),
  sd_earns = sd(EarnS, na.rm = TRUE),
  n = .N
), by = .(teen, treated)]

# Format as LaTeX
sum_stats[, group := fcase(
  teen == 1 & treated == 1, "Treated Teens",
  teen == 1 & treated == 0, "Control Teens",
  teen == 0 & treated == 1, "Treated Adults",
  teen == 0 & treated == 0, "Control Adults"
)]

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Hires} & \\multicolumn{2}{c}{Earnings (\\$)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "Group & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (g in c("Treated Teens", "Control Teens", "Treated Adults", "Control Adults")) {
  row <- sum_stats[group == g]
  if (nrow(row) == 0) next
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    g,
    format(round(row$mean_emp), big.mark = ","),
    format(round(row$sd_emp), big.mark = ","),
    format(round(row$mean_hires), big.mark = ","),
    format(round(row$sd_hires), big.mark = ","),
    format(round(row$mean_earns), big.mark = ","),
    format(round(row$sd_earns), big.mark = ",")
  ))
}

# DD comparison (treated-control gap)
pre_gap <- pre[, .(mean_emp = mean(Emp, na.rm = TRUE)), by = .(teen, treated)]
pre_gap_w <- dcast(pre_gap, teen ~ treated, value.var = "mean_emp")
setnames(pre_gap_w, c("0", "1"), c("control", "treated"))
pre_gap_w[, gap := treated - control]

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("\\multicolumn{7}{l}{\\textit{Pre-treatment observations: %s (treated), %s (control)}} \\\\",
          format(sum_stats[treated == 1, sum(n)], big.mark = ","),
          format(sum_stats[treated == 0, sum(n)], big.mark = ",")),
  sprintf("\\multicolumn{7}{l}{\\textit{States: 6 treated (2 cohorts), %d control}} \\\\",
          uniqueN(all_ind[treated == 0]$statefip)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment period is 2019Q1--2022Q2 for Cohort 1 (NJ, NH) and 2019Q1--2023Q2 for Cohort 2 (AR, FL, IA, IN). Employment and hires are quarterly state-level totals from the QWI. Earnings are average monthly earnings. Teens are ages 14--18 (QWI age group A01); adults are ages 25--34 (A03).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Saved tables/tab1_summary.tex\n")

# =========================================================================
# Table 2: Main DDD Results
# =========================================================================
cat("--- Table 2: Main DDD Results ---\n")

# Extract coefficients
extract_ddd <- function(model, label) {
  b <- coef(model)["ddd"]
  s <- se(model)["ddd"]
  p <- pvalue(model)["ddd"]
  n <- model$nobs
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(label = label, coef = b, se = s, pval = p, stars = stars, n = n)
}

main_rows <- list(
  extract_ddd(results$ddd_main, "Log Employment"),
  extract_ddd(results$ddd_hires, "Log Hires"),
  extract_ddd(results$ddd_sep, "Log Separations"),
  extract_ddd(results$ddd_earn, "Log Earnings")
)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Child Labor Law Relaxations on Teen Employment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Outcome & Coefficient & SE & $p$-value & $N$ \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: All Industries}} \\\\"
)

for (r in main_rows) {
  tab2_lines <- c(tab2_lines, sprintf(
    "%s & %.4f%s & (%.4f) & %.3f & %s \\\\",
    r$label, r$coef, r$stars, r$se, r$pval,
    format(r$n, big.mark = ",")
  ))
}

# Industry heterogeneity
tab2_lines <- c(tab2_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: By Industry Type (Log Employment)}} \\\\"
)

het_rows <- list(
  extract_ddd(results$ddd_high_teen, "High-teen industries"),
  extract_ddd(results$ddd_low_teen, "Low-teen industries"),
  extract_ddd(results$ddd_food, "Food service (NAICS 72)"),
  extract_ddd(results$ddd_retail, "Retail (NAICS 44-45)")
)

for (r in het_rows) {
  tab2_lines <- c(tab2_lines, sprintf(
    "%s & %.4f%s & (%.4f) & %.3f & %s \\\\",
    r$label, r$coef, r$stars, r$se, r$pval,
    format(r$n, big.mark = ",")
  ))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each cell reports the triple-difference coefficient ($\\hat{\\beta}_{DDD}$) from a specification with state$\\times$age, time$\\times$age, and state$\\times$time fixed effects. Standard errors clustered at the state level in parentheses. Teen workers are ages 14--18; control age group is 25--34. Treatment states: NJ and NH (Q3 2022), AR, FL, IA, and IN (Q3 2023). High-teen industries: food service, retail, arts/entertainment, other services. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Saved tables/tab2_main.tex\n")

# =========================================================================
# Table 3: Robustness Checks
# =========================================================================
cat("--- Table 3: Robustness ---\n")

rob_rows <- list()

# Wild cluster bootstrap
if (!is.null(robustness$boot_ddd)) {
  rob_rows[[length(rob_rows) + 1]] <- sprintf(
    "Wild cluster bootstrap & %.4f & [%.4f, %.4f] & %.3f \\\\",
    coef(results$ddd_main)["ddd"],
    robustness$boot_ddd$conf_int[1], robustness$boot_ddd$conf_int[2],
    robustness$boot_ddd$p_val
  )
}

# Placebo age
rob_rows[[length(rob_rows) + 1]] <- sprintf(
  "Placebo: Adults 35--44 vs 25--34 & %.4f & (%.4f) & %.3f \\\\",
  coef(robustness$placebo_age)["ddd_placebo"],
  se(robustness$placebo_age)["ddd_placebo"],
  pvalue(robustness$placebo_age)["ddd_placebo"]
)

# Placebo industry
rob_rows[[length(rob_rows) + 1]] <- sprintf(
  "Placebo: Finance (NAICS 52) & %.4f & (%.4f) & %.3f \\\\",
  coef(robustness$placebo_finance)["ddd"],
  se(robustness$placebo_finance)["ddd"],
  pvalue(robustness$placebo_finance)["ddd"]
)

# Alternative age control
rob_rows[[length(rob_rows) + 1]] <- sprintf(
  "Alt.\\ control: Ages 19--21 & %.4f & (%.4f) & %.3f \\\\",
  coef(robustness$ddd_alt_age)["ddd"],
  se(robustness$ddd_alt_age)["ddd"],
  pvalue(robustness$ddd_alt_age)["ddd"]
)

# CS overall ATT
rob_rows[[length(rob_rows) + 1]] <- sprintf(
  "Callaway--Sant'Anna ATT & %.4f & (%.4f) & %.3f \\\\",
  results$agg$overall.att,
  results$agg$overall.se,
  ifelse(abs(results$agg$overall.att / results$agg$overall.se) > 2.576, 0.001,
         ifelse(abs(results$agg$overall.att / results$agg$overall.se) > 1.96, 0.01,
                ifelse(abs(results$agg$overall.att / results$agg$overall.se) > 1.645, 0.05, 0.5)))
)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Estimate & SE / CI & $p$-value \\\\",
  "\\midrule",
  paste(rob_rows, collapse = "\n"),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Leave-one-out (dropping each treated state):}} \\\\"
)

for (i in 1:nrow(robustness$loo_results)) {
  r <- robustness$loo_results[i, ]
  tab3_lines <- c(tab3_lines, sprintf(
    "\\quad Drop %s & %.4f & (%.4f) & %.3f \\\\",
    r$dropped, r$coef, r$se, r$pval
  ))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the same sample and fixed-effect structure as Table~\\ref{tab:main} Panel A unless noted. Wild cluster bootstrap uses 9,999 iterations with Webb weights. Callaway--Sant'Anna uses the doubly robust estimator with never-treated control group. Leave-one-out drops one treated state at a time. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robustness.tex")
cat("  Saved tables/tab3_robustness.tex\n")

# =========================================================================
# Table 4: Event Study Coefficients
# =========================================================================
cat("--- Table 4: Event Study ---\n")

es_model <- robustness$es_ddd
es_coefs <- coef(es_model)
es_ses <- se(es_model)
es_pvals <- pvalue(es_model)

# Extract relative time indicators
es_names <- names(es_coefs)
es_idx <- grep("rel_time_bin", es_names)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study Triple-Difference Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Relative Quarter & Coefficient & SE & $p$-value \\\\",
  "\\midrule"
)

for (i in es_idx) {
  name <- es_names[i]
  # Parse relative time from name
  rt <- gsub(".*rel_time_bin::", "", name)
  rt <- gsub(":.*", "", rt)
  stars <- ifelse(es_pvals[i] < 0.01, "***",
                  ifelse(es_pvals[i] < 0.05, "**",
                         ifelse(es_pvals[i] < 0.1, "*", "")))
  tab4_lines <- c(tab4_lines, sprintf(
    "$t%s$ & %.4f%s & (%.4f) & %.3f \\\\",
    ifelse(as.numeric(rt) >= 0, paste0("+", rt), rt),
    es_coefs[i], stars, es_ses[i], es_pvals[i]
  ))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Estimates from a triple-difference event study interacting relative-time-to-treatment indicators with the teen$\\times$treated indicator. Reference period is $t-1$. State$\\times$age, time$\\times$age, and state$\\times$time fixed effects included. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("  Saved tables/tab4_eventstudy.tex\n")

# =========================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# =========================================================================
cat("--- Table F1: SDE Appendix ---\n")

# Helper function
compute_sde <- function(model, var_name, outcome_label, data, outcome_col) {
  b <- coef(model)[var_name]
  s <- se(model)[var_name]

  # For log outcomes, SDE = β / SD(log(Y))
  pre_data <- data[post == 0 & teen == 1]
  sd_y <- sd(pre_data[[outcome_col]], na.rm = TRUE)

  sde <- b / sd_y
  se_sde <- s / sd_y

  # Classification
  classify <- function(x) {
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x < 0.005) return("Null")
    if (x < 0.05) return("Small positive")
    if (x < 0.15) return("Moderate positive")
    return("Large positive")
  }

  list(
    outcome = outcome_label,
    beta = b,
    se = s,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    class = classify(sde)
  )
}

ddd_data <- all_ind[agegrp %in% c("A01", "A03")]
ddd_data[, treat_post := treated * post]
ddd_data[, treat_teen := treated * teen]
ddd_data[, post_teen := post * teen]
ddd_data[, ddd := treated * post * teen]

# Panel A: Pooled estimates
sde_emp <- compute_sde(results$ddd_main, "ddd", "Employment", ddd_data, "log_emp")
sde_hires <- compute_sde(results$ddd_hires, "ddd", "Hires", ddd_data, "log_hires")
sde_sep <- compute_sde(results$ddd_sep, "ddd", "Separations", ddd_data, "log_sep")
sde_earn <- compute_sde(results$ddd_earn, "ddd", "Earnings", ddd_data, "log_earns")

pooled <- list(sde_emp, sde_hires, sde_sep, sde_earn)

# Panel B: Heterogeneous (industry splits)
ind_ddd <- readRDS("../data/industry_panel.rds")
setDT(ind_ddd)
ind_ddd <- ind_ddd[agegrp %in% c("A01", "A03")]
ind_ddd[, treat_post := treated * post]
ind_ddd[, treat_teen := treated * teen]
ind_ddd[, post_teen := post * teen]
ind_ddd[, ddd := treated * post * teen]

sde_high <- compute_sde(results$ddd_high_teen, "ddd", "High-teen industries",
                         ind_ddd[high_teen_industry == 1], "log_emp")
sde_low <- compute_sde(results$ddd_low_teen, "ddd", "Low-teen industries",
                        ind_ddd[high_teen_industry == 0], "log_emp")

hetero <- list(sde_high, sde_low)

# Build LaTeX
sde_row <- function(r) {
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
          r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state-level child labor law relaxations (2022--2023) increased teen employment, hires, separations, or earnings relative to adults in treated versus control states. ",
  "\\textbf{Policy mechanism:} Six states expanded permissible work hours, eliminated work-permit requirements, or allowed parental consent to override hour limits for workers aged 14--18, reducing regulatory barriers to teen employment in covered industries. ",
  "\\textbf{Outcome definition:} Log of quarterly beginning-of-quarter employment (Emp), all hires (HirA), separations (Sep), and average monthly earnings (EarnS) from the Quarterly Workforce Indicators. ",
  "\\textbf{Treatment:} Binary; state adopted a child labor law relaxation in Q3 2022 (NJ, NH) or Q3 2023 (AR, FL, IA, IN). ",
  "\\textbf{Data:} Census QWI state $\\times$ age-group $\\times$ industry $\\times$ quarter panel, 2019Q1--2025Q2, 50 states and DC. ",
  "\\textbf{Method:} Triple-difference (state $\\times$ time $\\times$ age group) with state$\\times$age, time$\\times$age, and state$\\times$time fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} All private-sector employment; teens aged 14--18 (QWI A01) versus adults aged 25--34 (A03); six treated states, 44 never-treated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome for teen workers in treated states. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (r in pooled) {
  tabF1_lines <- c(tabF1_lines, paste0(sde_row(r), " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Industry Splits)}} \\\\"
)

for (r in hetero) {
  tabF1_lines <- c(tabF1_lines, paste0(sde_row(r), " \\\\"))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
