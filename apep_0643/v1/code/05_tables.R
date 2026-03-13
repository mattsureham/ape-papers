# =============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE
# apep_0643: PFL Border County Pairs
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
stacked_all <- readRDS("../data/stacked_all.rds")

female_all <- stacked_all %>%
  filter(sex == 2) %>%
  mutate(
    ln_emp = ifelse(Emp > 0, log(Emp), NA_real_),
    ln_earn = ifelse(EarnS > 0, log(EarnS), NA_real_),
    ln_hir = ifelse(HirA > 0, log(HirA), NA_real_),
    ln_sep = ifelse(Sep > 0, log(Sep), NA_real_),
    hire_rate = ifelse(Emp > 0, HirA / Emp, NA_real_),
    sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_),
    pfl = treated * post,
    pair_wave = paste0(pair_id, "_", wave),
    time_wave = paste0(yq_str, "_", wave)
  )

# ---- TABLE 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics...\n")

# Pre-treatment summary stats by treated/control
pre_data <- female_all %>% filter(post == 0)

sum_stats <- pre_data %>%
  group_by(treated) %>%
  summarise(
    across(c(Emp, EarnS, HirA, Sep, FrmJbGn, FrmJbLs),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE)),
           .names = "{.col}_{.fn}"),
    N = n(),
    .groups = "drop"
  )

# Format as LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Pre-Treatment Summary Statistics: Border County Pairs}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{PFL Counties} & \\multicolumn{2}{c}{Control Counties} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline"
)

vars <- c("Emp", "EarnS", "HirA", "Sep", "FrmJbGn", "FrmJbLs")
labels <- c("Employment", "Avg. Monthly Earnings (\\$)",
            "All Hires", "Separations",
            "Firm Job Gains", "Firm Job Losses")

treated_row <- sum_stats %>% filter(treated == 1)
control_row <- sum_stats %>% filter(treated == 0)

for (i in seq_along(vars)) {
  v <- vars[i]
  t_mean <- treated_row[[paste0(v, "_mean")]]
  t_sd <- treated_row[[paste0(v, "_sd")]]
  c_mean <- control_row[[paste0(v, "_mean")]]
  c_sd <- control_row[[paste0(v, "_sd")]]

  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s & %s \\\\",
            labels[i],
            format(round(t_mean, 0), big.mark = ","),
            format(round(t_sd, 0), big.mark = ","),
            format(round(c_mean, 0), big.mark = ","),
            format(round(c_sd, 0), big.mark = ",")))
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("County-quarter obs. & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(sum(pre_data$treated == 1), big.mark = ","),
          format(sum(pre_data$treated == 0), big.mark = ",")),
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          n_distinct(pre_data$fips[pre_data$treated == 1]),
          n_distinct(pre_data$fips[pre_data$treated == 0])),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Pre-treatment means and standard deviations for female workers in all private-sector industries. PFL counties are those in states that adopted paid family leave (NJ, NY, WA); control counties are contiguous counties across the state border in non-PFL states (PA, DE, VT, ID). Data: Census QWI, county-quarter level. Employment is beginning-of-quarter count. Earnings are average monthly.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

# ---- TABLE 2: Main Results ----
cat("Generating Table 2: Main Results...\n")

m <- results$main

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Paid Family Leave on Female Labor Market Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & ln(Emp) & ln(Earn) & ln(Hires) & ln(Sep) & Hire Rate & Sep Rate \\\\",
  "\\hline"
)

# Extract coefficients
models <- list(m$m1, m$m2, m$m3, m$m4, m$m5, m$m6)
coefs <- sapply(models, function(mod) coef(mod)["pfl"])
ses <- sapply(models, function(mod) se(mod)["pfl"])
pvals <- sapply(models, function(mod) pvalue(mod)["pfl"])
ns <- sapply(models, nobs)

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Coefficient row
coef_str <- paste(sapply(seq_along(coefs), function(i) {
  sprintf("%.4f%s", coefs[i], stars(pvals[i]))
}), collapse = " & ")
tab2_lines <- c(tab2_lines, sprintf("PFL $\\times$ Post & %s \\\\", coef_str))

# SE row
se_str <- paste(sprintf("(%.4f)", ses), collapse = " & ")
tab2_lines <- c(tab2_lines, sprintf(" & %s \\\\", se_str))

# WCB p-values
wcb_pvals <- rep("", 6)
if (!is.null(robustness$wcb_emp)) {
  wcb_pvals[1] <- sprintf("[%.3f]", robustness$wcb_emp$p_val)
}
if (!is.null(robustness$wcb_earn)) {
  wcb_pvals[2] <- sprintf("[%.3f]", robustness$wcb_earn$p_val)
}
if (any(nchar(wcb_pvals) > 0)) {
  wcb_str <- paste(wcb_pvals, collapse = " & ")
  tab2_lines <- c(tab2_lines, sprintf(" & %s \\\\", wcb_str))
}

# Means
pre_means <- female_all %>%
  filter(post == 0) %>%
  summarise(
    across(c(Emp, EarnS, HirA, Sep, hire_rate, sep_rate),
           ~mean(.x, na.rm = TRUE))
  )

mean_str <- sprintf("%.0f & %.0f & %.0f & %.0f & %.3f & %.3f",
                    pre_means$Emp, pre_means$EarnS, pre_means$HirA,
                    pre_means$Sep, pre_means$hire_rate, pre_means$sep_rate)

tab2_lines <- c(tab2_lines,
  "\\hline",
  sprintf("Pre-treatment mean & %s \\\\", mean_str),
  sprintf("Observations & %s \\\\",
          paste(format(ns, big.mark = ","), collapse = " & ")),
  "County-pair $\\times$ wave FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter $\\times$ wave FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Clusters (states) & %d & %d & %d & %d & %d & %d \\\\",
          n_distinct(female_all$state_fips), n_distinct(female_all$state_fips),
          n_distinct(female_all$state_fips), n_distinct(female_all$state_fips),
          n_distinct(female_all$state_fips), n_distinct(female_all$state_fips)),
  "\\hline\\hline",
  "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Each column reports the coefficient on PFL $\\times$ Post from a stacked border-county-pair difference-in-differences specification. Three PFL adoption waves are stacked: NJ (2009Q3), NY (2018Q1), WA (2020Q1). Each treated border county is paired with its adjacent control county across the state line. Standard errors clustered at the state level in parentheses. Wild cluster bootstrap $p$-values using Webb weights in brackets where available. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ---- TABLE 3: Event Study Coefficients ----
cat("Generating Table 3: Event Study...\n")

es <- robustness$es_model
es_coefs <- coef(es)
es_ses <- se(es)
es_pvals <- pvalue(es)

# Extract event-time coefficients
et_names <- names(es_coefs)[grep("et_binned", names(es_coefs))]
# Names are like "et_binned::-9:treated" — extract the number between :: and :treated
et_vals <- as.integer(gsub("et_binned::(-?[0-9]+):treated", "\\1", et_names))
ord <- order(et_vals)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Female Employment at PFL Border Counties}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Event Quarter & Coefficient & Std. Error & 95\\% CI \\\\",
  "\\hline"
)

for (idx in ord) {
  nm <- et_names[idx]
  et <- et_vals[idx]
  b <- es_coefs[nm]
  s <- es_ses[nm]
  p <- es_pvals[nm]
  ci_lo <- b - 1.96 * s
  ci_hi <- b + 1.96 * s
  label <- ifelse(et == -9, "$\\leq -9$",
           ifelse(et == 13, "$\\geq 13$",
           ifelse(et == -1, "$-1$ (ref.)", as.character(et))))
  if (et == -1) {
    tab3_lines <- c(tab3_lines,
      sprintf("%s & 0 & --- & --- \\\\", label))
  } else {
    tab3_lines <- c(tab3_lines,
      sprintf("%s & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
              label, b, stars(p), s, ci_lo, ci_hi))
  }
}

# F-test for pre-trends
ftest_str <- ""
if (!is.null(robustness$pre_wald)) {
  ftest_str <- sprintf("$F = %.2f$, $p = %.3f$",
                       robustness$pre_wald$stat, robustness$pre_wald$p)
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  sprintf("Joint pre-trend $F$-test & \\multicolumn{3}{c}{%s} \\\\", ftest_str),
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\",
          format(nobs(es), big.mark = ",")),
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Event-study coefficients from the stacked border-county-pair specification. The dependent variable is log female employment. Event quarter $-1$ is the reference period. Endpoints are binned ($\\leq -9$ and $\\geq 13$). Standard errors clustered at the state level. The $F$-test reports joint significance of all pre-treatment coefficients.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ---- TABLE 4: Heterogeneity (Industry and Education) ----
cat("Generating Table 4: Heterogeneity...\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Industry and Education: Female Employment}",
  "\\label{tab:heterogeneity}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Coefficient & Std. Error & Observations \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: By Industry}} \\\\"
)

ind_labels <- c("62" = "Healthcare (NAICS 62)",
                "44-45" = "Retail Trade (NAICS 44-45)",
                "72" = "Accommodation \\& Food (NAICS 72)")

for (ind_code in c("62", "44-45", "72")) {
  if (!is.null(results$industry[[ind_code]])) {
    mod <- results$industry[[ind_code]]
    b <- coef(mod)["pfl"]
    s <- se(mod)["pfl"]
    p <- pvalue(mod)["pfl"]
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.4f%s & (%.4f) & %s \\\\",
              ind_labels[ind_code], b, stars(p), s,
              format(nobs(mod), big.mark = ",")))
  }
}

tab4_lines <- c(tab4_lines,
  "\\\\",
  "\\multicolumn{4}{l}{\\textit{Panel B: By Education}} \\\\"
)

edu_labels <- c("E1" = "Less than High School",
                "E2" = "High School or Equivalent",
                "E3" = "Some College or Associate's",
                "E4" = "Bachelor's Degree or Higher")

for (edu_code in c("E1", "E2", "E3", "E4")) {
  if (!is.null(results$education[[edu_code]])) {
    mod <- results$education[[edu_code]]
    b <- coef(mod)["pfl"]
    s <- se(mod)["pfl"]
    p <- pvalue(mod)["pfl"]
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %.4f%s & (%.4f) & %s \\\\",
              edu_labels[edu_code], b, stars(p), s,
              format(nobs(mod), big.mark = ",")))
  }
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Each row reports the PFL $\\times$ Post coefficient from a separate stacked border-county-pair regression. All specifications include county-pair $\\times$ wave and quarter $\\times$ wave fixed effects. Standard errors clustered at the state level in parentheses. $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_heterogeneity.tex")

# ---- TABLE 5: Robustness ----
cat("Generating Table 5: Robustness...\n")

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Female Employment}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Coefficient & Std. Error & Observations \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Main and Placebo}} \\\\"
)

# Main result
b_main <- coef(results$main$m1)["pfl"]
s_main <- se(results$main$m1)["pfl"]
p_main <- pvalue(results$main$m1)["pfl"]
tab5_lines <- c(tab5_lines,
  sprintf("Main: Female, all industries & %.4f%s & (%.4f) & %s \\\\",
          b_main, stars(p_main), s_main,
          format(nobs(results$main$m1), big.mark = ",")))

# Male placebo
b_male <- coef(results$male_placebo$emp)["pfl"]
s_male <- se(results$male_placebo$emp)["pfl"]
p_male <- pvalue(results$male_placebo$emp)["pfl"]
tab5_lines <- c(tab5_lines,
  sprintf("Placebo: Male, all industries & %.4f%s & (%.4f) & %s \\\\",
          b_male, stars(p_male), s_male,
          format(nobs(results$male_placebo$emp), big.mark = ",")))

tab5_lines <- c(tab5_lines,
  "\\\\",
  "\\multicolumn{4}{l}{\\textit{Panel B: Wave-Specific Estimates}} \\\\"
)

for (wn in c("NJ", "NY", "WA")) {
  if (!is.null(results$wave_specific[[wn]])) {
    mod <- results$wave_specific[[wn]]
    b <- coef(mod)["pfl"]
    s <- se(mod)["pfl"]
    p <- pvalue(mod)["pfl"]
    tab5_lines <- c(tab5_lines,
      sprintf("%s wave only & %.4f%s & (%.4f) & %s \\\\",
              wn, b, stars(p), s, format(nobs(mod), big.mark = ",")))
  }
}

tab5_lines <- c(tab5_lines,
  "\\\\",
  "\\multicolumn{4}{l}{\\textit{Panel C: Leave-One-Wave-Out}} \\\\"
)

for (wn in c("NJ", "NY", "WA")) {
  if (!is.null(robustness$loo[[wn]])) {
    mod <- robustness$loo[[wn]]
    b <- coef(mod)["pfl"]
    s <- se(mod)["pfl"]
    p <- pvalue(mod)["pfl"]
    tab5_lines <- c(tab5_lines,
      sprintf("Drop %s & %.4f%s & (%.4f) & %s \\\\",
              wn, b, stars(p), s, format(nobs(mod), big.mark = ",")))
  }
}

tab5_lines <- c(tab5_lines,
  "\\\\",
  "\\multicolumn{4}{l}{\\textit{Panel D: Alternative Clustering}} \\\\"
)

# Pair-clustered
b_pair <- coef(robustness$pair_cluster)["pfl"]
s_pair <- se(robustness$pair_cluster)["pfl"]
p_pair <- pvalue(robustness$pair_cluster)["pfl"]
tab5_lines <- c(tab5_lines,
  sprintf("Cluster: county pair & %.4f%s & (%.4f) & %s \\\\",
          b_pair, stars(p_pair), s_pair,
          format(nobs(robustness$pair_cluster), big.mark = ",")))

# County-clustered
b_cty <- coef(robustness$county_cluster)["pfl"]
s_cty <- se(robustness$county_cluster)["pfl"]
p_cty <- pvalue(robustness$county_cluster)["pfl"]
tab5_lines <- c(tab5_lines,
  sprintf("Cluster: county & %.4f%s & (%.4f) & %s \\\\",
          b_cty, stars(p_cty), s_cty,
          format(nobs(robustness$county_cluster), big.mark = ",")))

tab5_lines <- c(tab5_lines,
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} All specifications report the PFL $\\times$ Post coefficient for log female employment with county-pair $\\times$ wave and quarter $\\times$ wave fixed effects. Panel A compares the main female result with a male placebo. Panel B shows wave-specific estimates. Panel C drops each wave in turn. Panel D varies the clustering level (main specification clusters at the state level). $^{*}p<0.10$; $^{**}p<0.05$; $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")

# ---- SDE TABLE (MANDATORY) ----
cat("Generating SDE table...\n")

# Compute SDE for main outcomes
outcomes <- c("ln_emp", "ln_earn", "ln_hir", "ln_sep", "hire_rate", "sep_rate")
outcome_labels <- c("Log Employment", "Log Earnings",
                     "Log Hires", "Log Separations",
                     "Hire Rate", "Separation Rate")

sde_rows <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  mod <- results$main[[paste0("m", i)]]
  b <- as.numeric(coef(mod)["pfl"])
  s <- as.numeric(se(mod)["pfl"])

  # SD of outcome in pre-treatment period
  sd_y <- sd(female_all[[y]][female_all$post == 0], na.rm = TRUE)

  # For log outcomes, SDE = beta (since treatment is binary and outcome is in logs)
  # For level outcomes, SDE = beta / SD(Y)
  if (grepl("^ln_", y)) {
    sde <- b  # Already in log points ≈ proportional change
    se_sde <- s
  } else {
    sde <- b / sd_y
    se_sde <- s / sd_y
  }

  # Classification
  classify <- function(x) {
    if (is.na(x)) return("---")
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x <= 0.005) return("Null")
    if (x <= 0.05) return("Small positive")
    if (x <= 0.15) return("Moderate positive")
    return("Large positive")
  }

  sde_rows[[i]] <- data.frame(
    outcome = outcome_labels[i],
    beta = b,
    se = s,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde),
    stringsAsFactors = FALSE
  )
}

sde_df <- bind_rows(sde_rows)

# Write LaTeX
sde_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(sde_df)) {
  r <- sde_df[i, ]
  sde_lines <- c(sde_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Standardized effect sizes from the main stacked border-county-pair specification. For log outcomes, SDE equals the coefficient (approximate proportional change). For rate outcomes, SDE = $\\hat{\\beta} / \\text{SD}(Y)$. SD($Y$) computed from pre-treatment observations. Classification follows the 7-bucket scheme: Large ($|\\text{SDE}| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$). Classification refers to effect magnitude, not statistical significance. Research question: Does state paid family leave affect female labor market dynamics at state borders? Data: Census QWI county-quarter panel. Method: Stacked border-county-pair DiD across three PFL adoption waves (NJ 2009, NY 2018, WA 2020). Treatment: Binary (PFL state vs. adjacent non-PFL state county).} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
