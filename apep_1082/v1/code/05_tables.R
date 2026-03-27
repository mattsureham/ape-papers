##############################################################################
# 05_tables.R — Generate all LaTeX tables including SDE appendix
# APEP-1082: The Lottery Channel
##############################################################################

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ===========================================================================
# Load data and models
# ===========================================================================

cy <- read_csv(file.path(data_dir, "country_year_panel.csv"),
               show_col_types = FALSE)
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

has_recent <- file.exists(file.path(data_dir, "recent_models.RData"))
if (has_recent) load(file.path(data_dir, "recent_models.RData"))

diag <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment means by group
pre_treated <- cy %>%
  filter(treated_country == 1, post == 0)
pre_control <- cy %>%
  filter(treated_country == 0)
post_treated <- cy %>%
  filter(treated_country == 1, post == 1)

make_stats <- function(df, label) {
  df %>%
    summarise(
      Group = label,
      `College (\\%)` = sprintf("%.1f", weighted.mean(pct_college, w = total_weight, na.rm = TRUE)),
      `Grad Degree (\\%)` = sprintf("%.1f", weighted.mean(pct_grad, w = total_weight, na.rm = TRUE)),
      `HS Diploma (\\%)` = sprintf("%.1f", weighted.mean(pct_hs, w = total_weight, na.rm = TRUE)),
      `Mean Log Wage` = sprintf("%.2f", weighted.mean(mean_ln_wage, w = total_weight, na.rm = TRUE)),
      `Mean Age` = sprintf("%.1f", weighted.mean(mean_age, w = total_weight, na.rm = TRUE)),
      `Female (\\%)` = sprintf("%.1f", weighted.mean(pct_female, w = total_weight, na.rm = TRUE)),
      `Country-Years` = as.character(n()),
      Countries = as.character(n_distinct(country))
    )
}

tab1_data <- bind_rows(
  make_stats(pre_treated, "Treated (pre)"),
  make_stats(post_treated, "Treated (post)"),
  make_stats(pre_control, "Control")
)

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Immigrant Characteristics by Treatment Status}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & College & Grad & HS & Mean Log & Mean & Female & Country- \\\\",
  " & (\\%) & (\\%) & (\\%) & Wage & Age & (\\%) & Years \\\\",
  "\\midrule"
)

for (i in 1:nrow(tab1_data)) {
  row <- tab1_data[i, ]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s \\\\",
    row$Group, row$`College (\\%)`, row$`Grad Degree (\\%)`,
    row$`HS Diploma (\\%)`, row$`Mean Log Wage`, row$`Mean Age`,
    row$`Female (\\%)`, row$`Country-Years`
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Working-age (25--64) foreign-born individuals from treated and control countries. Treated countries: those losing Diversity Visa eligibility. Control: persistently eligible countries from similar regions. Statistics weighted by ACS person weights (PWGTP). Pre-treatment: years before country-specific eligibility loss. Source: ACS 1-year PUMS, 2005--2023.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ===========================================================================
# Table 2: Main DiD Results
# ===========================================================================

cat("=== Generating Table 2: Main Results ===\n")

# Extract coefficients and SEs
get_stats <- function(model, name) {
  coefs <- coeftable(model)
  idx <- which(rownames(coefs) == "post")
  if (length(idx) == 0) return(NULL)
  data.frame(
    spec = name,
    coef = coefs[idx, "Estimate"],
    se = coefs[idx, "Std. Error"],
    pval = coefs[idx, "Pr(>|t|)"],
    n = model$nobs,
    r2 = fitstat(model, "r2")$r2
  )
}

results <- list()
results[[1]] <- get_stats(m1, "College (\\%)")
results[[2]] <- get_stats(m2, "Grad Degree (\\%)")
results[[3]] <- get_stats(m3, "Log Wages")

if (has_recent) {
  results[[4]] <- get_stats(m4, "College, Recent")
  results[[5]] <- get_stats(m5, "Grad, Recent")
  results[[6]] <- get_stats(m6, "Wages, Recent")
}

results_df <- bind_rows(results)

# Format stars
add_stars <- function(coef, pval) {
  stars <- ifelse(pval < 0.01, "***",
           ifelse(pval < 0.05, "**",
           ifelse(pval < 0.10, "*", "")))
  sprintf("%.2f%s", coef, stars)
}

# Build table
tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Losing DV Eligibility on Immigrant Characteristics}",
  "\\label{tab:main}",
  "\\small"
)

if (has_recent) {
  tab2_lines <- c(tab2_lines,
    "\\begin{tabular}{lcccccc}",
    "\\toprule",
    " & \\multicolumn{3}{c}{All Immigrants} & \\multicolumn{3}{c}{Recent Arrivals} \\\\",
    "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
    " & College & Grad & Log & College & Grad & Log \\\\",
    " & (\\%) & (\\%) & Wages & (\\%) & (\\%) & Wages \\\\",
    " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
    "\\midrule"
  )

  tab2_lines <- c(tab2_lines,
    sprintf("Post $\\times$ Treated & %s & %s & %s & %s & %s & %s \\\\",
            add_stars(results_df$coef[1], results_df$pval[1]),
            add_stars(results_df$coef[2], results_df$pval[2]),
            add_stars(results_df$coef[3], results_df$pval[3]),
            add_stars(results_df$coef[4], results_df$pval[4]),
            add_stars(results_df$coef[5], results_df$pval[5]),
            add_stars(results_df$coef[6], results_df$pval[6])),
    sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\",
            results_df$se[1], results_df$se[2], results_df$se[3],
            results_df$se[4], results_df$se[5], results_df$se[6]),
    "\\midrule",
    "Country FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
    "Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
    sprintf("Observations & %d & %d & %d & %d & %d & %d \\\\",
            results_df$n[1], results_df$n[2], results_df$n[3],
            results_df$n[4], results_df$n[5], results_df$n[6]),
    sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
            results_df$r2[1], results_df$r2[2], results_df$r2[3],
            results_df$r2[4], results_df$r2[5], results_df$r2[6])
  )
} else {
  tab2_lines <- c(tab2_lines,
    "\\begin{tabular}{lccc}",
    "\\toprule",
    " & College (\\%) & Grad Degree (\\%) & Log Wages \\\\",
    " & (1) & (2) & (3) \\\\",
    "\\midrule",
    sprintf("Post $\\times$ Treated & %s & %s & %s \\\\",
            add_stars(results_df$coef[1], results_df$pval[1]),
            add_stars(results_df$coef[2], results_df$pval[2]),
            add_stars(results_df$coef[3], results_df$pval[3])),
    sprintf(" & (%.2f) & (%.2f) & (%.2f) \\\\",
            results_df$se[1], results_df$se[2], results_df$se[3]),
    "\\midrule",
    "Country FE & Yes & Yes & Yes \\\\",
    "Year FE & Yes & Yes & Yes \\\\",
    sprintf("Observations & %d & %d & %d \\\\",
            results_df$n[1], results_df$n[2], results_df$n[3]),
    sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\",
            results_df$r2[1], results_df$r2[2], results_df$r2[3])
  )
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the coefficient on an indicator equal to one after a country loses DV eligibility, from a TWFE regression with country and year fixed effects. ``All Immigrants'': all working-age (25--64) foreign-born from each country observed in the ACS. ``Recent Arrivals'': those who entered the US within the past 5 years. Weighted by ACS person weights, aggregated to country-year cells. Standard errors clustered at country level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ===========================================================================
# Table 3: Robustness
# ===========================================================================

cat("=== Generating Table 3: Robustness ===\n")

rob_specs <- list()
rob_specs[[1]] <- get_stats(m1, "Baseline")
rob_specs[[2]] <- get_stats(m_africa, "Africa only")
rob_specs[[3]] <- get_stats(m_asia, "Asia only")
rob_specs[[4]] <- get_stats(m_hs, "HS (placebo)")

# CS result
if (file.exists(file.path(data_dir, "cs_models.RData"))) {
  load(file.path(data_dir, "cs_models.RData"))
  rob_specs[[5]] <- data.frame(
    spec = "Callaway-Sant'Anna",
    coef = cs_agg$overall.att,
    se = cs_agg$overall.se,
    pval = 2 * pnorm(-abs(cs_agg$overall.att / cs_agg$overall.se)),
    n = nrow(cy),
    r2 = NA
  )
}

# RI result
ri_file <- file.path(data_dir, "ri_results.csv")
if (file.exists(ri_file)) {
  ri <- read_csv(ri_file, show_col_types = FALSE)
  rob_specs[[6]] <- data.frame(
    spec = "RI $p$-value",
    coef = ri$actual_coef,
    se = NA,
    pval = ri$ri_pvalue,
    n = nrow(cy),
    r2 = NA
  )
}

rob_df <- bind_rows(rob_specs)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Effect on College Share (\\%)}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Specification & Coefficient & SE & $p$-value & $N$ & $R^2$ \\\\",
  "\\midrule"
)

for (i in 1:nrow(rob_df)) {
  r <- rob_df[i, ]
  coef_str <- sprintf("%.2f", r$coef)
  se_str <- ifelse(is.na(r$se), "---", sprintf("%.2f", r$se))
  p_str <- sprintf("%.3f", r$pval)
  n_str <- as.character(r$n)
  r2_str <- ifelse(is.na(r$r2), "---", sprintf("%.3f", r$r2))
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %s & %s & %s & %s \\\\", r$spec, coef_str, se_str, p_str, n_str, r2_str)
  )
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable: share of working-age immigrants with college education (\\%). ``Africa only'' restricts to Nigeria (treated) vs. African control countries. ``Asia only'' restricts to Bangladesh and Pakistan (treated) vs. Asian controls. ``HS (placebo)'' uses high school diploma share as the outcome. ``Callaway-Sant'Anna'' uses the heterogeneity-robust estimator for staggered adoption. ``RI $p$-value'' reports the two-sided randomization inference $p$-value from 1,000 permutations of country treatment assignment. All specifications include country and year fixed effects. Standard errors clustered at country level.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_robustness.tex"))
cat("  Saved tab3_robustness.tex\n")

# ===========================================================================
# Table 4: Leave-One-Out
# ===========================================================================

cat("=== Generating Table 4: Leave-One-Out ===\n")

loo_df <- read_csv(file.path(data_dir, "leave_one_out.csv"),
                   show_col_types = FALSE)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Leave-One-Out: Dropping Each Treated Country}",
  "\\label{tab:loo}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Dropped Country & Coefficient & SE \\\\",
  "\\midrule",
  sprintf("None (baseline) & %.2f & %.2f \\\\", results_df$coef[1], results_df$se[1])
)

for (i in 1:nrow(loo_df)) {
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %.2f & %.2f \\\\", loo_df$dropped[i], loo_df$coef[i], loo_df$se[i])
  )
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row drops one treated country and re-estimates the baseline specification. Dependent variable: college share (\\%). All specifications include country and year FE, clustered SEs.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_loo.tex"))
cat("  Saved tab4_loo.tex\n")

# ===========================================================================
# Table F1: SDE Appendix (MANDATORY)
# ===========================================================================

cat("=== Generating SDE Table ===\n")

# Get pre-treatment SD(Y) for each outcome
sd_y_college <- sd(cy$pct_college[cy$post == 0], na.rm = TRUE)
sd_y_grad <- sd(cy$pct_grad[cy$post == 0], na.rm = TRUE)
sd_y_wage <- sd(cy$mean_ln_wage[cy$post == 0], na.rm = TRUE)

# SDE = beta / SD(Y)
sde_college <- results_df$coef[1] / sd_y_college
sde_grad <- results_df$coef[2] / sd_y_grad
sde_wage <- results_df$coef[3] / sd_y_wage

se_sde_college <- results_df$se[1] / sd_y_college
se_sde_grad <- results_df$se[2] / sd_y_grad
se_sde_wage <- results_df$se[3] / sd_y_wage

# Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Panel A: Pooled
sde_pool <- data.frame(
  outcome = c("College share (\\%)", "Graduate degree share (\\%)", "Log wages"),
  beta = c(results_df$coef[1], results_df$coef[2], results_df$coef[3]),
  se = c(results_df$se[1], results_df$se[2], results_df$se[3]),
  sd_y = c(sd_y_college, sd_y_grad, sd_y_wage),
  sde = c(sde_college, sde_grad, sde_wage),
  se_sde = c(se_sde_college, se_sde_grad, se_sde_wage)
)
sde_pool$class <- sapply(sde_pool$sde, classify_sde)

# Panel B: Heterogeneous (Africa vs Asia subsample splits)
# Africa result
coef_africa <- coeftable(m_africa)["post", "Estimate"]
se_africa <- coeftable(m_africa)["post", "Std. Error"]
sde_africa <- coef_africa / sd_y_college

# Asia result
coef_asia <- coeftable(m_asia)["post", "Estimate"]
se_asia <- coeftable(m_asia)["post", "Std. Error"]
sde_asia <- coef_asia / sd_y_college

sde_het <- data.frame(
  outcome = c("College share — Africa", "College share — Asia"),
  beta = c(coef_africa, coef_asia),
  se = c(se_africa, se_asia),
  sd_y = c(sd_y_college, sd_y_college),
  sde = c(sde_africa, sde_asia),
  se_sde = c(se_africa / sd_y_college, se_asia / sd_y_college)
)
sde_het$class <- sapply(sde_het$sde, classify_sde)

# Build SDE LaTeX table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States (receiving country); treated origin countries include Nigeria, Bangladesh, Brazil, Pakistan, Peru. ",
  "\\textbf{Research question:} Does losing Diversity Visa lottery eligibility reduce the educational attainment and earnings of immigrants from affected countries? ",
  "\\textbf{Policy mechanism:} The DV lottery allocates approximately 50,000 green cards annually by random draw to nationals of low-admission countries; when a country's non-lottery immigration exceeds 50,000 over five years, it loses eligibility, closing the primary pathway for immigrants without family or employer sponsors. ",
  "\\textbf{Outcome definition:} Share of working-age (25--64) foreign-born with bachelor's degree or above (SCHL $\\geq$ 21) from ACS PUMS, and mean log annual wages (WAGP). ",
  "\\textbf{Treatment:} Binary indicator for country losing DV eligibility (threshold crossing). ",
  "\\textbf{Data:} ACS 1-year PUMS, 2005--2023, country-year cells for 19 origin countries. ",
  "\\textbf{Method:} TWFE DiD with country and year FE; standard errors clustered at country level; Callaway--Sant'Anna for staggered robustness. ",
  "\\textbf{Sample:} Working-age foreign-born; 5 treated and 14 control countries; cells with $\\geq 20$ observations. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes: DV Eligibility Loss and Immigrant Selection}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_pool)) {
  r <- sde_pool[i, ]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class)
  )
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by region)}} \\\\"
)

for (i in 1:nrow(sde_het)) {
  r <- sde_het[i, ]
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class)
  )
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
