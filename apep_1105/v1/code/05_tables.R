# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_1105: Treatment Dividend of Supply-Side Opioid Restrictions
# =============================================================================
source("00_packages.R")

df <- fread("../data/analysis_dataset.csv")
load("../data/models.RData")
load("../data/robustness_models.RData")

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Define variables and labels
tab1_vars <- data.table(
  var = c("hcp_share", "pills_per_cap", "mat_rate", "methadone_rate",
          "buprenorphine_rate", "sud_placebo_rate",
          "population", "poverty_rate", "pct_black", "pct_hispanic", "median_age"),
  label = c("HCP share of opioid prescriptions", "Opioid pills per capita (2006--2012)",
            "MAT claims per 1,000 pop./month", "Methadone claims per 1,000 pop./month",
            "Buprenorphine claims per 1,000 pop./month", "Non-opioid SUD claims per 1,000 pop./month",
            "Population (2019)", "Poverty rate", "Share Black", "Share Hispanic", "Median age"),
  panel = c(rep("A", 6), rep("B", 5))
)

make_sumstat_row <- function(x, label) {
  sprintf("  %s & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          label, mean(x, na.rm=TRUE), sd(x, na.rm=TRUE),
          quantile(x, 0.25, na.rm=TRUE), median(x, na.rm=TRUE),
          quantile(x, 0.75, na.rm=TRUE))
}

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "  & Mean & SD & P25 & Median & P75 \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Key Variables}} \\\\[3pt]"
)

for (i in 1:nrow(tab1_vars)) {
  if (tab1_vars$panel[i] == "B" && tab1_vars$panel[i-1] == "A") {
    tab1_lines <- c(tab1_lines, "\\addlinespace[6pt]",
                    "\\multicolumn{6}{l}{\\textit{Panel B: County Controls}} \\\\[3pt]")
  }
  x <- df[[tab1_vars$var[i]]]
  if (tab1_vars$var[i] == "population") {
    row <- sprintf("  %s & %s & %s & %s & %s & %s \\\\",
                   tab1_vars$label[i],
                   format(round(mean(x, na.rm=TRUE)), big.mark=","),
                   format(round(sd(x, na.rm=TRUE)), big.mark=","),
                   format(round(quantile(x, 0.25, na.rm=TRUE)), big.mark=","),
                   format(round(median(x, na.rm=TRUE)), big.mark=","),
                   format(round(quantile(x, 0.75, na.rm=TRUE)), big.mark=","))
  } else {
    row <- make_sumstat_row(x, tab1_vars$label[i])
  }
  tab1_lines <- c(tab1_lines, row)
}

tab1_lines <- c(tab1_lines,
  "\\hline",
  sprintf("\\multicolumn{6}{l}{\\textit{N} = %s counties} \\\\", format(nrow(df), big.mark=",")),
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Panel A reports the instrument (HCP share from ARCOS 2006--2012), Medicaid MAT utilization outcomes (T-MSIS 2018--2024), and a placebo outcome. Panel B reports county-level controls from ACS 2019. HCP share is the county's hydrocodone combination product share of total opioid pill shipments.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_sumstats.tex")

# =============================================================================
# Table 2: Balance Test
# =============================================================================
cat("Generating Table 2: Balance Test...\n")

bal_labels <- c("Poverty rate" = "poverty_rate", "Share Black" = "pct_black",
                "Share Hispanic" = "pct_hispanic", "Median age" = "median_age",
                "Log population" = "log_pop")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Balance Test: County Characteristics and HCP Share}",
  "\\label{tab:balance}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "  Dependent variable & Coefficient & Std. error & $p$-value \\\\",
  "\\hline"
)

for (nm in names(bal_labels)) {
  v <- bal_labels[nm]
  b <- balance_results[[v]]
  stars <- ifelse(b$pval < 0.01, "***", ifelse(b$pval < 0.05, "**", ifelse(b$pval < 0.1, "*", "")))
  tab2_lines <- c(tab2_lines,
    sprintf("  %s & %.4f%s & (%.4f) & %.3f \\\\", nm, b$coef, stars, b$se, b$pval))
}

tab2_lines <- c(tab2_lines,
  "\\hline",
  "  State FE & Yes & & \\\\",
  sprintf("  Counties & %s & & \\\\", format(nrow(df), big.mark=",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Each row reports a separate regression of the county characteristic on HCP share, conditional on state fixed effects. Robust standard errors clustered at the state level. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_balance.tex")

# =============================================================================
# Table 3: Main Results
# =============================================================================
cat("Generating Table 3: Main Results...\n")

models_main <- list(m1, m2, m3, m4, m5)
dep_labels <- c("MAT rate", "MAT rate", "MAT rate", "MAT rate", "Log MAT rate")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Treatment Dividend: HCP Share and Medicaid MAT Utilization}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "  & (1) & (2) & (3) & (4) & (5) \\\\",
  sprintf("  & %s \\\\", paste(dep_labels, collapse = " & ")),
  "\\hline"
)

# HCP share coefficient
coefs <- sapply(models_main, function(m) coef(m)["hcp_share"])
ses <- sapply(models_main, function(m) sqrt(vcov(m)["hcp_share", "hcp_share"]))
pvals <- sapply(models_main, function(m) pvalue(m)["hcp_share"])
stars_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab3_lines <- c(tab3_lines,
  sprintf("  HCP share & %s \\\\",
          paste(sprintf("%.3f%s", coefs, stars_fn(pvals)), collapse = " & ")),
  sprintf("  & %s \\\\",
          paste(sprintf("(%.3f)", ses), collapse = " & ")),
  "\\addlinespace[4pt]",
  sprintf("  State FE & No & Yes & Yes & Yes & Yes \\\\"),
  sprintf("  Controls & No & No & Yes & Yes & Yes \\\\"),
  sprintf("  Urban indicator & No & No & No & Yes & Yes \\\\"),
  sprintf("  Observations & %s \\\\",
          paste(sapply(models_main, function(m) format(nobs(m), big.mark=",")), collapse = " & ")),
  sprintf("  $R^2$ & %s \\\\",
          paste(sprintf("%.3f", sapply(models_main, function(m) fitstat(m, "r2")$r2)), collapse = " & ")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is MAT claims per 1,000 population per month (cols.\\ 1--4) or log thereof (col.\\ 5). HCP share is the county's pre-rescheduling (2006--2012) hydrocodone combination product share of total ARCOS opioid shipments. Controls include log population, poverty rate, share Black, share Hispanic, median age, and pre-rescheduling pills per capita. Robust standard errors clustered at the state level in parentheses. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")

# =============================================================================
# Table 4: Placebo and Treatment Modality Decomposition
# =============================================================================
cat("Generating Table 4: Placebo and Mechanism...\n")

models_mech <- list(m4, m_placebo, m_meth, m_bup, m_nalt)
mech_labels <- c("Total MAT", "Non-opioid SUD", "Methadone", "Buprenorphine", "Naltrexone")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo Test and Treatment Modality Decomposition}",
  "\\label{tab:mechanism}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "  & (1) & (2) & (3) & (4) & (5) \\\\",
  sprintf("  & %s \\\\", paste(mech_labels, collapse = " & ")),
  "\\hline"
)

coefs_m <- sapply(models_mech, function(m) coef(m)["hcp_share"])
ses_m <- sapply(models_mech, function(m) sqrt(vcov(m)["hcp_share", "hcp_share"]))
pvals_m <- sapply(models_mech, function(m) pvalue(m)["hcp_share"])

tab4_lines <- c(tab4_lines,
  sprintf("  HCP share & %s \\\\",
          paste(sprintf("%.4f%s", coefs_m, stars_fn(pvals_m)), collapse = " & ")),
  sprintf("  & %s \\\\",
          paste(sprintf("(%.4f)", ses_m), collapse = " & ")),
  "\\addlinespace[4pt]",
  sprintf("  Dep.\\ var.\\ mean & %s \\\\",
          paste(sprintf("%.3f",
                c(mean(df$mat_rate), mean(df$sud_placebo_rate),
                  mean(df$methadone_rate), mean(df$buprenorphine_rate),
                  mean(df$naltrexone_rate))), collapse = " & ")),
  "  State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "  Controls & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("  Observations & %s \\\\",
          paste(sapply(models_mech, function(m) format(nobs(m), big.mark=",")), collapse = " & ")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Column 1 reproduces the preferred specification from Table \\ref{tab:main}. Column 2 reports the placebo test using non-opioid SUD treatment claims (H0015, H0016). Columns 3--5 decompose total MAT into methadone (H0020), buprenorphine (J0571--J0575), and naltrexone (J2315). All specifications include state FE and the full control set. Robust standard errors clustered at the state level. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_mechanism.tex")

# =============================================================================
# Table 5: Robustness
# =============================================================================
cat("Generating Table 5: Robustness...\n")

rob_models <- list(m4, m_donut, m_wt, m_urban, m_rural)
rob_labels <- c("Baseline", "Donut", "Pop-weighted", "Urban", "Rural")

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "  & (1) & (2) & (3) & (4) & (5) \\\\",
  sprintf("  & %s \\\\", paste(rob_labels, collapse = " & ")),
  "\\hline"
)

coefs_r <- sapply(rob_models, function(m) coef(m)["hcp_share"])
ses_r <- sapply(rob_models, function(m) sqrt(vcov(m)["hcp_share", "hcp_share"]))
pvals_r <- sapply(rob_models, function(m) pvalue(m)["hcp_share"])

tab5_lines <- c(tab5_lines,
  sprintf("  HCP share & %s \\\\",
          paste(sprintf("%.3f%s", coefs_r, stars_fn(pvals_r)), collapse = " & ")),
  sprintf("  & %s \\\\",
          paste(sprintf("(%.3f)", ses_r), collapse = " & ")),
  "\\addlinespace[4pt]",
  sprintf("  Drop extreme deciles & No & Yes & No & No & No \\\\"),
  sprintf("  Population weights & No & No & Yes & No & No \\\\"),
  "  State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "  Controls & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("  Observations & %s \\\\",
          paste(sapply(rob_models, function(m) format(nobs(m), big.mark=",")), collapse = " & ")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Column 1 reproduces the baseline from Table \\ref{tab:main}, col.\\ 4. Column 2 drops the top and bottom deciles of HCP share. Column 3 weights by county population. Columns 4--5 split the sample by urban/rural classification. All specifications include state FE and the full control set. Robust standard errors clustered at the state level. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")

# =============================================================================
# SDE Table (Appendix — MANDATORY)
# =============================================================================
cat("Generating SDE table...\n")

# Compute SDEs for main outcomes
sde_outcomes <- list(
  list(name = "Total MAT", model = m4, var = "mat_rate"),
  list(name = "Methadone", model = m_meth, var = "methadone_rate"),
  list(name = "Buprenorphine", model = m_bup, var = "buprenorphine_rate"),
  list(name = "Non-opioid SUD (placebo)", model = m_placebo, var = "sud_placebo_rate")
)

sde_rows_pooled <- list()
for (out in sde_outcomes) {
  beta <- coef(out$model)["hcp_share"]
  se_beta <- sqrt(vcov(out$model)["hcp_share", "hcp_share"])
  sd_y <- sd(df[[out$var]], na.rm = TRUE)
  sd_x <- sd(df$hcp_share, na.rm = TRUE)
  # Continuous treatment: SDE = beta * SD(X) / SD(Y)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classify <- function(s) {
    if (s < -0.15) "Large negative"
    else if (s < -0.05) "Moderate negative"
    else if (s < -0.005) "Small negative"
    else if (s <= 0.005) "Null"
    else if (s <= 0.05) "Small positive"
    else if (s <= 0.15) "Moderate positive"
    else "Large positive"
  }

  sde_rows_pooled[[length(sde_rows_pooled) + 1]] <- data.table(
    Outcome = out$name,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    class = classify(sde)
  )
}
sde_pooled <- rbindlist(sde_rows_pooled)

# Heterogeneity panel: Urban vs Rural for total MAT
sde_het <- list()
for (split_info in list(
  list(name = "Total MAT (Urban)", model = m_urban, sub = df[urban == 1]),
  list(name = "Total MAT (Rural)", model = m_rural, sub = df[urban == 0])
)) {
  beta <- coef(split_info$model)["hcp_share"]
  se_beta <- sqrt(vcov(split_info$model)["hcp_share", "hcp_share"])
  sd_y <- sd(split_info$sub$mat_rate, na.rm = TRUE)
  sd_x <- sd(split_info$sub$hcp_share, na.rm = TRUE)
  sde <- beta * sd_x / sd_y
  se_sde <- se_beta * sd_x / sd_y

  classify <- function(s) {
    if (s < -0.15) "Large negative"
    else if (s < -0.05) "Moderate negative"
    else if (s < -0.005) "Small negative"
    else if (s <= 0.005) "Null"
    else if (s <= 0.05) "Small positive"
    else if (s <= 0.15) "Moderate positive"
    else "Large positive"
  }

  sde_het[[length(sde_het) + 1]] <- data.table(
    Outcome = split_info$name,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    class = classify(sde)
  )
}
sde_het_dt <- rbindlist(sde_het)

# Build SDE LaTeX
make_sde_row <- function(r) {
  sprintf("  %s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 2014 federal rescheduling of hydrocodone combination products from Schedule III to Schedule II affect county-level Medicaid-funded medication-assisted treatment utilization? ",
  "\\textbf{Policy mechanism:} The DEA rescheduling eliminated phone-in prescriptions, prohibited refills, and capped supply at 30 days for hydrocodone combination products, which constituted approximately 75\\% of prescription opioid volume, creating a county-level supply shock proportional to pre-existing hydrocodone dependence. ",
  "\\textbf{Outcome definition:} Monthly Medicaid MAT claims (methadone H0020, buprenorphine J0571--J0575, naltrexone J2315) per 1,000 county population, from T-MSIS 2018--2024. ",
  "\\textbf{Treatment:} Continuous; county-level hydrocodone combination product share of total ARCOS opioid shipments (2006--2012 average). ",
  "\\textbf{Data:} DEA ARCOS transaction-level pill shipments (2006--2012, 178M rows), CMS T-MSIS Medicaid claims (2018--2024, 227M rows), provider NPIs geocoded to counties via NPPES, ACS 2019 county controls. ",
  "\\textbf{Method:} Cross-sectional shift-share reduced form with state fixed effects, robust standard errors clustered at state level. ",
  "\\textbf{Sample:} US counties with $>$100,000 ARCOS pill shipments and matched T-MSIS MAT providers; ", sprintf("%d", nrow(df)), " counties across ", sprintf("%d", uniqueN(df$state_fips)), " states. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment where SD($X$) is the cross-county standard deviation of HCP share and SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in 1:nrow(sde_pooled)) {
  sde_lines <- c(sde_lines, make_sde_row(sde_pooled[i]))
}

sde_lines <- c(sde_lines,
  "\\addlinespace[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Urban/Rural Split)}} \\\\[3pt]"
)

for (i in 1:nrow(sde_het_dt)) {
  sde_lines <- c(sde_lines, make_sde_row(sde_het_dt[i]))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("Files:\n")
cat(paste(list.files("../tables/"), collapse = "\n"), "\n")
