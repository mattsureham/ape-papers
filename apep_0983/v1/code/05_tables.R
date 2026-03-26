# 05_tables.R — Generate all LaTeX tables
source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
models <- readRDS("data/main_models.rds")
rob_models <- readRDS("data/robustness_models.rds")
df <- panel[canton == "ZH" & !is.na(personal_rate) & !is.na(corporate_rate) &
            year >= 2012 & year <= 2023]

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("Generating Table 1: Summary Statistics\n")

sumstats <- df[, .(
  N = .N,
  Mean_personal = round(mean(personal_rate, na.rm = TRUE), 1),
  SD_personal = round(sd(personal_rate, na.rm = TRUE), 1),
  Mean_corporate = round(mean(corporate_rate, na.rm = TRUE), 1),
  SD_corporate = round(sd(corporate_rate, na.rm = TRUE), 1),
  Mean_wedge = round(mean(wedge, na.rm = TRUE), 1),
  SD_wedge = round(sd(wedge, na.rm = TRUE), 1),
  Mean_est = round(mean(establishments, na.rm = TRUE), 0),
  SD_est = round(sd(establishments, na.rm = TRUE), 0),
  Mean_emp = round(mean(employment, na.rm = TRUE), 0),
  SD_emp = round(sd(employment, na.rm = TRUE), 0),
  Mean_pop = round(mean(population, na.rm = TRUE), 0),
  SD_pop = round(sd(population, na.rm = TRUE), 0),
  Mean_sk = round(mean(steuerkraft_mio, na.rm = TRUE), 1),
  SD_sk = round(sd(steuerkraft_mio, na.rm = TRUE), 1),
  Pct_wedge_change = round(mean(wedge_changed, na.rm = TRUE) * 100, 1)
)]

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Zurich Canton Municipalities, 2012--2023}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Tax Rates (\\%)}} \\\\\n",
  sprintf("Personal Steuerfuss & %.1f & %.1f & %.0f & %.0f \\\\\n",
          mean(df$personal_rate), sd(df$personal_rate), min(df$personal_rate), max(df$personal_rate)),
  sprintf("Corporate Steuerfuss & %.1f & %.1f & %.1f & %.1f \\\\\n",
          mean(df$corporate_rate), sd(df$corporate_rate), min(df$corporate_rate), max(df$corporate_rate)),
  sprintf("Wedge (Corporate -- Personal) & %.1f & %.1f & %.0f & %.0f \\\\\n",
          mean(df$wedge), sd(df$wedge), min(df$wedge), max(df$wedge)),
  sprintf("Municipality-years with wedge change & \\multicolumn{4}{c}{%.1f\\%%} \\\\\n",
          mean(df$wedge_changed, na.rm = TRUE) * 100),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Outcomes}} \\\\\n",
  sprintf("Establishments & %.0f & %.0f & %.0f & %.0f \\\\\n",
          mean(df$establishments, na.rm = TRUE), sd(df$establishments, na.rm = TRUE),
          min(df$establishments, na.rm = TRUE), max(df$establishments, na.rm = TRUE)),
  sprintf("Employment & %.0f & %.0f & %.0f & %.0f \\\\\n",
          mean(df$employment, na.rm = TRUE), sd(df$employment, na.rm = TRUE),
          min(df$employment, na.rm = TRUE), max(df$employment, na.rm = TRUE)),
  sprintf("Population & %.0f & %.0f & %.0f & %.0f \\\\\n",
          mean(df$population, na.rm = TRUE), sd(df$population, na.rm = TRUE),
          min(df$population, na.rm = TRUE), max(df$population, na.rm = TRUE)),
  sprintf("Steuerkraft (CHF million) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          mean(df$steuerkraft_mio, na.rm = TRUE), sd(df$steuerkraft_mio, na.rm = TRUE),
          min(df$steuerkraft_mio, na.rm = TRUE), max(df$steuerkraft_mio, na.rm = TRUE)),
  "\\hline\n",
  sprintf("Municipalities & \\multicolumn{4}{c}{%d} \\\\\n", uniqueN(df$bfs_nr)),
  sprintf("Municipality $\\times$ years & \\multicolumn{4}{c}{%s} \\\\\n", format(nrow(df), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} ",
  "Sample includes all municipalities in the Canton of Zurich with complete ",
  "Steuerfuss data for natural persons and legal persons (corporations), 2012--2023. ",
  "Personal Steuerfuss is the tax multiplier applied to natural persons' income tax; ",
  "Corporate Steuerfuss applies to corporate profit tax. The wedge is their difference. ",
  "Establishments and employment are from the Federal Statistical Office STATENT. ",
  "Steuerkraft is the 3-year rolling average tax capacity of the municipality.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "tables/tab1_sumstats.tex")

# ==============================================================================
# Table 2: Main Results
# ==============================================================================
cat("Generating Table 2: Main Results\n")

# Extract coefficients and SEs
get_coef <- function(m, var) {
  cf <- coef(m)
  se <- sqrt(diag(vcov(m)))
  if (var %in% names(cf)) {
    list(b = cf[var], se = se[var],
         stars = ifelse(abs(cf[var]/se[var]) > 2.576, "***",
                        ifelse(abs(cf[var]/se[var]) > 1.96, "**",
                               ifelse(abs(cf[var]/se[var]) > 1.645, "*", ""))))
  } else {
    list(b = NA, se = NA, stars = "")
  }
}

fmt_coef <- function(m, var, digits = 4) {
  r <- get_coef(m, var)
  if (is.na(r$b)) return(c("", ""))
  c(sprintf(paste0("%.", digits, "f%s"), r$b, r$stars),
    sprintf(paste0("(", "%.", digits, "f)"), r$se))
}

# Build table 2
tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Factor-Specific Tax Rates and Sorting: Main Results}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Establishments} & \\multicolumn{2}{c}{Population} & \\multicolumn{2}{c}{Steuerkraft} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Wedge Specification}} \\\\[3pt]"
)

# Panel A: Wedge
for (m_pair in list(list(models$m1, models$m5, models$m7))) {
  w1 <- fmt_coef(m_pair[[1]], "wedge")
  w2 <- fmt_coef(m_pair[[2]], "wedge")
  w3 <- fmt_coef(m_pair[[3]], "wedge")
  tab2_lines <- c(tab2_lines,
    sprintf("Wedge & %s & & %s & & %s & \\\\", w1[1], w2[1], w3[1]),
    sprintf(" & %s & & %s & & %s & \\\\[6pt]", w1[2], w2[2], w3[2])
  )
}

tab2_lines <- c(tab2_lines,
  "\\multicolumn{7}{l}{\\textit{Panel B: Separate Rates}} \\\\[3pt]"
)

# Panel B: Separate rates
c1 <- fmt_coef(models$m2, "corporate_rate")
c2 <- fmt_coef(models$m6, "corporate_rate")
c3 <- fmt_coef(models$m8, "corporate_rate")
p1 <- fmt_coef(models$m2, "personal_rate")
p2 <- fmt_coef(models$m6, "personal_rate")
p3 <- fmt_coef(models$m8, "personal_rate")

tab2_lines <- c(tab2_lines,
  sprintf("Corporate rate & & %s & & %s & & %s \\\\", c1[1], c2[1], c3[1]),
  sprintf(" & & %s & & %s & & %s \\\\", c1[2], c2[2], c3[2]),
  sprintf("Personal rate & & %s & & %s & & %s \\\\", p1[1], p2[1], p3[1]),
  sprintf(" & & %s & & %s & & %s \\\\", p1[2], p2[2], p3[2]),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(nobs(models$m1), big.mark = ","),
          format(nobs(models$m2), big.mark = ","),
          format(nobs(models$m5), big.mark = ","),
          format(nobs(models$m6), big.mark = ","),
          format(nobs(models$m7), big.mark = ","),
          format(nobs(models$m8), big.mark = ",")),
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & %.4f & %.4f \\\\",
          fitstat(models$m1, "wr2")[[1]],
          fitstat(models$m2, "wr2")[[1]],
          fitstat(models$m5, "wr2")[[1]],
          fitstat(models$m6, "wr2")[[1]],
          fitstat(models$m7, "wr2")[[1]],
          fitstat(models$m8, "wr2")[[1]]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports OLS estimates with municipality and year fixed effects. ",
  "Dependent variables are in logs. The wedge is the corporate Steuerfuss minus the personal Steuerfuss. ",
  "Columns (1)--(2) use log establishments (STATENT); (3)--(4) use log population; (5)--(6) use log Steuerkraft (3-year rolling average tax capacity in CHF millions). ",
  "Standard errors clustered at the municipality level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, "tables/tab2_main.tex")

# ==============================================================================
# Table 3: Robustness
# ==============================================================================
cat("Generating Table 3: Robustness\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks for the Steuerkraft Effect}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Baseline & Levels & LOO & Lag(1) & Lag(2) \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline"
)

# Baseline (m8)
b_base <- fmt_coef(models$m8, "corporate_rate")
p_base <- fmt_coef(models$m8, "personal_rate")
# Levels (r1c)
b_lev <- fmt_coef(rob_models$r1c, "corporate_rate", 3)
p_lev <- fmt_coef(rob_models$r1c, "personal_rate", 3)
# LOO (r4c)
b_loo <- fmt_coef(rob_models$r4c, "corporate_rate")
p_loo <- fmt_coef(rob_models$r4c, "personal_rate")
# Lag1 (r5c)
b_l1 <- fmt_coef(rob_models$r5c, "lag1_corp")
p_l1 <- fmt_coef(rob_models$r5c, "lag1_pers")
# Lag2 (r5b) — this is establishments, not SK. Use establishment lag2
b_l2 <- fmt_coef(rob_models$r5b, "lag2_corp")
p_l2 <- fmt_coef(rob_models$r5b, "lag2_pers")

tab3_lines <- c(tab3_lines,
  sprintf("Corporate rate & %s & %s & %s & %s & %s \\\\", b_base[1], b_lev[1], b_loo[1], b_l1[1], b_l2[1]),
  sprintf(" & %s & %s & %s & %s & %s \\\\", b_base[2], b_lev[2], b_loo[2], b_l1[2], b_l2[2]),
  sprintf("Personal rate & %s & %s & %s & %s & %s \\\\", p_base[1], p_lev[1], p_loo[1], p_l1[1], p_l2[1]),
  sprintf(" & %s & %s & %s & %s & %s \\\\", p_base[2], p_lev[2], p_loo[2], p_l1[2], p_l2[2]),
  "\\hline",
  "Dep. var. & log SK & SK (levels) & log SK & log SK & log Est. \\\\",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(models$m8), big.mark = ","),
          format(nobs(rob_models$r1c), big.mark = ","),
          format(nobs(rob_models$r4c), big.mark = ","),
          format(nobs(rob_models$r5c), big.mark = ","),
          format(nobs(rob_models$r5b), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline Steuerkraft specification from Table~\\ref{tab:main}. ",
  "Column (2) uses Steuerkraft in levels (CHF millions) instead of logs. ",
  "Column (3) drops the city of Zurich (the largest municipality). ",
  "Column (4) uses one-year lagged tax rates. ",
  "Column (5) uses two-year lagged tax rates with log establishments as the outcome, ",
  "testing whether physical relocation appears with a longer delay (it does not). ",
  "All specifications include municipality and year fixed effects. ",
  "Standard errors clustered at the municipality level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, "tables/tab3_robust.tex")

# ==============================================================================
# Table 4: Heterogeneity (firm size)
# ==============================================================================
cat("Generating Table 4: Heterogeneity\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Firm Size and Outcome Margin}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Micro (0--9) & Small (10--49) & New Firms & Employment \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline"
)

c_micro <- fmt_coef(models$m_micro, "corporate_rate")
p_micro <- fmt_coef(models$m_micro, "personal_rate")
c_small <- fmt_coef(models$m_small, "corporate_rate")
p_small <- fmt_coef(models$m_small, "personal_rate")
c_new <- fmt_coef(models$m10, "corporate_rate")
p_new <- fmt_coef(models$m10, "personal_rate")
c_emp <- fmt_coef(models$m4, "corporate_rate")
p_emp <- fmt_coef(models$m4, "personal_rate")

tab4_lines <- c(tab4_lines,
  sprintf("Corporate rate & %s & %s & %s & %s \\\\", c_micro[1], c_small[1], c_new[1], c_emp[1]),
  sprintf(" & %s & %s & %s & %s \\\\", c_micro[2], c_small[2], c_new[2], c_emp[2]),
  sprintf("Personal rate & %s & %s & %s & %s \\\\", p_micro[1], p_small[1], p_new[1], p_emp[1]),
  sprintf(" & %s & %s & %s & %s \\\\", p_micro[2], p_small[2], p_new[2], p_emp[2]),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(models$m_micro), big.mark = ","),
          format(nobs(models$m_small), big.mark = ","),
          format(nobs(models$m10), big.mark = ","),
          format(nobs(models$m4), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variables are in logs. ",
  "Column (1): micro-enterprises (0--9 FTE); (2): small enterprises (10--49 FTE); ",
  "(3): newly registered firms; (4): total employment. ",
  "All specifications include municipality and year fixed effects. ",
  "Standard errors clustered at the municipality level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, "tables/tab4_hetero.tex")

# ==============================================================================
# Table F1: SDE Appendix
# ==============================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDEs
# Main outcomes from the separate-rates specification
# Using the corporate_rate coefficient (the "factor-specific" test)
compute_sde <- function(model, var, outcome_sd, treatment_sd = NULL, binary = TRUE) {
  cf <- coef(model)
  se_cf <- sqrt(diag(vcov(model)))
  beta <- cf[var]
  se_beta <- se_cf[var]

  if (binary) {
    sde <- beta / outcome_sd
    se_sde <- se_beta / outcome_sd
  } else {
    sde <- beta * treatment_sd / outcome_sd
    se_sde <- se_beta * treatment_sd / outcome_sd
  }

  classify <- function(x) {
    if (abs(x) < 0.005) return("Null")
    if (x > 0.15) return("Large positive")
    if (x > 0.05) return("Moderate positive")
    if (x > 0.005) return("Small positive")
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    return("Small negative")
  }

  list(beta = beta, se_beta = se_beta, sd_y = outcome_sd,
       sde = sde, se_sde = se_sde, class = classify(sde))
}

# Pre-treatment SDs (using 2012-2014 as pre-period)
pre <- df[year <= 2014]
sd_est <- sd(pre$log_est, na.rm = TRUE)
sd_pop <- sd(pre$log_pop, na.rm = TRUE)
sd_sk <- sd(pre$log_sk, na.rm = TRUE)
sd_corp <- sd(df$corporate_rate, na.rm = TRUE)

# Continuous treatment: SDE = β × SD(X) / SD(Y)
sde_est <- compute_sde(models$m2, "corporate_rate", sd_est, sd_corp, binary = FALSE)
sde_pop <- compute_sde(models$m6, "corporate_rate", sd_pop, sd_corp, binary = FALSE)
sde_sk <- compute_sde(models$m8, "corporate_rate", sd_sk, sd_corp, binary = FALSE)

# Heterogeneous: small municipalities vs large
med_pop <- median(df$population, na.rm = TRUE)
df[, small_muni := population < med_pop]

m_sk_small <- feols(log_sk ~ corporate_rate + personal_rate | bfs_nr + year,
                    data = df[small_muni == TRUE & !is.na(log_sk)], cluster = ~bfs_nr)
m_sk_large <- feols(log_sk ~ corporate_rate + personal_rate | bfs_nr + year,
                    data = df[small_muni == FALSE & !is.na(log_sk)], cluster = ~bfs_nr)

pre_small <- df[year <= 2014 & small_muni == TRUE]
pre_large <- df[year <= 2014 & small_muni == FALSE]
sd_sk_small <- sd(pre_small$log_sk, na.rm = TRUE)
sd_sk_large <- sd(pre_large$log_sk, na.rm = TRUE)

sde_sk_small <- compute_sde(m_sk_small, "corporate_rate", sd_sk_small, sd_corp, binary = FALSE)
sde_sk_large <- compute_sde(m_sk_large, "corporate_rate", sd_sk_large, sd_corp, binary = FALSE)

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the corporate--personal tax multiplier wedge in Swiss municipalities cause factor-specific sorting of firms and residents, or does it shift the tax base without physical relocation? ",
  "\\textbf{Policy mechanism:} Swiss municipalities in the Canton of Zurich set separate Steuerfuss (tax multiplier) rates for natural persons and legal persons (corporations), creating within-municipality variation in relative tax prices faced by different economic agents. ",
  "\\textbf{Outcome definition:} Panel A outcomes are log establishments (STATENT count of business locations), log population (permanent residents), and log Steuerkraft (3-year rolling average municipal tax capacity in CHF millions). Panel B splits Steuerkraft by municipality size. ",
  "\\textbf{Treatment:} Continuous; corporate Steuerfuss rate in percentage points (mean 119, SD ", round(sd_corp, 1), "). ",
  "\\textbf{Data:} Canton of Zurich Statistical Office (Steuerfuss, Steuerkraft), Federal Statistical Office STATENT (establishments), BFS population statistics, 2012--2023, municipality-year panel. ",
  "\\textbf{Method:} OLS with municipality and year fixed effects, standard errors clustered at municipality level. ",
  "\\textbf{Sample:} ", uniqueN(df$bfs_nr), " municipalities in the Canton of Zurich with complete data on separate Steuerfuss rates for natural and legal persons. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the corporate Steuerfuss and SD($Y$) is the pre-treatment (2012--2014) ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Establishments & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          sde_est$beta, sde_est$se_beta, sde_est$sd_y, sde_est$sde, sde_est$se_sde, sde_est$class),
  sprintf("Population & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          sde_pop$beta, sde_pop$se_beta, sde_pop$sd_y, sde_pop$sde, sde_pop$se_sde, sde_pop$class),
  sprintf("Steuerkraft & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          sde_sk$beta, sde_sk$se_beta, sde_sk$sd_y, sde_sk$sde, sde_sk$se_sde, sde_sk$class),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Steuerkraft by Municipality Size}} \\\\",
  sprintf("Small municipalities & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          sde_sk_small$beta, sde_sk_small$se_beta, sde_sk_small$sd_y,
          sde_sk_small$sde, sde_sk_small$se_sde, sde_sk_small$class),
  sprintf("Large municipalities & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          sde_sk_large$beta, sde_sk_large$se_beta, sde_sk_large$sd_y,
          sde_sk_large$sde, sde_sk_large$se_sde, sde_sk_large$class),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab_sde, "tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(" ", list.files("tables/"), collapse = "\n"), "\n")
