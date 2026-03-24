# 05_tables.R — Generate all LaTeX tables
# apep_0871: NIS2 Cybersecurity Regulation and Enterprise Security Investment

source("00_packages.R")

# ===========================================================================
# Load data and results
# ===========================================================================
panel_clean <- readRDS("../data/panel_clean.rds")
idx_data <- readRDS("../data/index_panel.rds")
indicator_labels <- readRDS("../data/indicator_labels.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

# Helper: format coefficient with stars
fmt_coef <- function(beta, pval) {
  stars <- ifelse(pval < 0.01, "^{***}",
           ifelse(pval < 0.05, "^{**}",
           ifelse(pval < 0.10, "^{*}", "")))
  sprintf("%.2f%s", beta, stars)
}

fmt_se <- function(se_val) sprintf("(%.2f)", se_val)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
message("Generating Table 1: Summary Statistics...")

did_sample <- idx_data[size_emp %in% c("10-49", "50-249")]

# Summary stats by size class
summ_tab <- did_sample[, .(
  Mean = round(mean(security_index, na.rm = TRUE), 1),
  SD = round(sd(security_index, na.rm = TRUE), 1),
  Min = round(min(security_index, na.rm = TRUE), 1),
  Max = round(max(security_index, na.rm = TRUE), 1),
  N = .N
), by = .(size_emp)]

# Category indices
cat_summ <- did_sample[, .(
  compliance_mean = round(mean(compliance_index, na.rm = TRUE), 1),
  compliance_sd = round(sd(compliance_index, na.rm = TRUE), 1),
  technical_mean = round(mean(technical_index, na.rm = TRUE), 1),
  technical_sd = round(sd(technical_index, na.rm = TRUE), 1),
  training_mean = round(mean(training_index, na.rm = TRUE), 1),
  training_sd = round(sd(training_index, na.rm = TRUE), 1)
), by = size_emp]

# Also compute means by year for the table
yearly_means <- did_sample[, .(
  idx_2019 = round(mean(security_index[year == 2019], na.rm = TRUE), 1),
  idx_2022 = round(mean(security_index[year == 2022], na.rm = TRUE), 1),
  idx_2024 = round(mean(security_index[year == 2024], na.rm = TRUE), 1)
), by = size_emp]

tab1_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Enterprise Cybersecurity Measures}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Small (10--49 empl.)} & \\multicolumn{3}{c}{Medium (50--249 empl.)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & 2019 & 2022 & 2024 & 2019 & 2022 & 2024 \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Security Category Indices (\\% of enterprises)}} \\\\[3pt]"
)

# Get year-size means for each category
for (cat_name in c("compliance_index", "technical_index", "training_index")) {
  cat_label <- gsub("_index", "", cat_name)
  cat_label <- paste0(toupper(substr(cat_label, 1, 1)), substr(cat_label, 2, nchar(cat_label)))
  vals <- did_sample[, .(val = round(mean(get(cat_name), na.rm = TRUE), 1)),
                     by = .(size_emp, year)]
  s19 <- vals[size_emp == "10-49" & year == 2019, val]
  s22 <- vals[size_emp == "10-49" & year == 2022, val]
  s24 <- vals[size_emp == "10-49" & year == 2024, val]
  m19 <- vals[size_emp == "50-249" & year == 2019, val]
  m22 <- vals[size_emp == "50-249" & year == 2022, val]
  m24 <- vals[size_emp == "50-249" & year == 2024, val]

  tab1_tex <- c(tab1_tex, sprintf("%s measures & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
                                  cat_label, s19, s22, s24, m19, m22, m24))
}

# Overall index
vals_ov <- did_sample[, .(val = round(mean(security_index, na.rm = TRUE), 1)),
                      by = .(size_emp, year)]
tab1_tex <- c(tab1_tex, "[3pt]",
  sprintf("Overall security index & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
          vals_ov[size_emp == "10-49" & year == 2019, val],
          vals_ov[size_emp == "10-49" & year == 2022, val],
          vals_ov[size_emp == "10-49" & year == 2024, val],
          vals_ov[size_emp == "50-249" & year == 2019, val],
          vals_ov[size_emp == "50-249" & year == 2022, val],
          vals_ov[size_emp == "50-249" & year == 2024, val]),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Selected Individual Measures (\\% of enterprises)}} \\\\[3pt]"
)

# Selected individual measures
sel_indics <- c("E_SECPOL2", "E_SECMRASS", "E_SECMDENC", "E_SECMLOG",
                "E_SECMUIBM", "E_SECMTST", "E_SECAWCTP", "E_SECAWCONT")
sel_labels <- c("Security policy documented", "Risk assessment conducted",
                "Data encryption used", "Log file maintenance",
                "Biometric authentication", "Security testing conducted",
                "Staff training provided", "Mandatory training/obligations")

for (i in seq_along(sel_indics)) {
  ind_vals <- panel_clean[indic_is == sel_indics[i] &
                          size_emp %in% c("10-49", "50-249") &
                          year %in% c(2019, 2022, 2024),
                          .(val = round(mean(values, na.rm = TRUE), 1)),
                          by = .(size_emp, year)]
  s19 <- ind_vals[size_emp == "10-49" & year == 2019, val]
  s22 <- ind_vals[size_emp == "10-49" & year == 2022, val]
  s24 <- ind_vals[size_emp == "10-49" & year == 2024, val]
  m19 <- ind_vals[size_emp == "50-249" & year == 2019, val]
  m22 <- ind_vals[size_emp == "50-249" & year == 2022, val]
  m24 <- ind_vals[size_emp == "50-249" & year == 2024, val]
  tab1_tex <- c(tab1_tex,
    sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
            sel_labels[i],
            ifelse(length(s19), s19, NA),
            ifelse(length(s22), s22, NA),
            ifelse(length(s24), s24, NA),
            ifelse(length(m19), m19, NA),
            ifelse(length(m22), m22, NA),
            ifelse(length(m24), m24, NA)))
}

tab1_tex <- c(tab1_tex,
  "\\midrule",
  sprintf("Countries & \\multicolumn{3}{c}{%d} & \\multicolumn{3}{c}{%d} \\\\",
          uniqueN(did_sample[size_emp == "10-49", geo]),
          uniqueN(did_sample[size_emp == "50-249", geo])),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Values are the share of enterprises (\\%) adopting each cybersecurity measure. Data from Eurostat ICT Security Survey (\\texttt{isoc\\_cisce\\_ra}), covering enterprises in NACE sectors C10--S951 excluding finance. Small firms: 10--49 employees (NIS2 exempt). Medium firms: 50--249 employees (newly NIS2-regulated). The overall security index averages 15 individual measures. N = 27 EU member states per cell.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ===========================================================================
# Table 2: Main DiD and DDD Results
# ===========================================================================
message("Generating Table 2: Main DiD and DDD Results...")

m1 <- results$m1_basic
m2 <- results$m1_full
m3 <- results$m_ddd
m4 <- results$m_dosage

tab2_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of NIS2 on Enterprise Cybersecurity Investment}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & DiD & DiD & DDD & Dosage \\\\",
  "\\midrule",
  sprintf("Medium $\\times$ Post & %s & %s & %s & %s \\\\",
          fmt_coef(coef(m1)["treat_post"], pvalue(m1)["treat_post"]),
          fmt_coef(coef(m2)["treat_post"], pvalue(m2)["treat_post"]),
          fmt_coef(coef(m3)["treat_post"], pvalue(m3)["treat_post"]),
          fmt_coef(coef(m4)["medium_post"], pvalue(m4)["medium_post"])),
  sprintf(" & %s & %s & %s & %s \\\\",
          fmt_se(se(m1)["treat_post"]),
          fmt_se(se(m2)["treat_post"]),
          fmt_se(se(m3)["treat_post"]),
          fmt_se(se(m4)["medium_post"])),
  sprintf("Medium $\\times$ Post $\\times$ Transposed & & & %s & \\\\",
          fmt_coef(coef(m3)["triple"], pvalue(m3)["triple"])),
  sprintf(" & & & %s & \\\\",
          fmt_se(se(m3)["triple"])),
  sprintf("Large $\\times$ Post & & & & %s \\\\",
          fmt_coef(coef(m4)["large_post"], pvalue(m4)["large_post"])),
  sprintf(" & & & & %s \\\\",
          fmt_se(se(m4)["large_post"])),
  "\\midrule",
  "Country FE & Yes & & & \\\\",
  "Size FE & Yes & & & \\\\",
  "Year FE & Yes & & & \\\\",
  "Country $\\times$ Size FE & & Yes & Yes & Yes \\\\",
  "Country $\\times$ Year FE & & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "wr2")[[1]], fitstat(m2, "wr2")[[1]],
          fitstat(m3, "wr2")[[1]], fitstat(m4, "wr2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variable is the overall cybersecurity security index ",
         "(average of 15 individual measures, in percentage points). ",
         "Medium firms (50--249 employees) are newly regulated under NIS2; small firms (10--49) are exempt. ",
         "Column (3) interacts with an indicator for countries that completed NIS2 transposition by the October 2024 deadline ",
         "(Belgium, Croatia, Hungary, Italy, Latvia, Lithuania). ",
         "Column (4) adds large firms ($\\geq$250 employees), already regulated under NIS1 and subject to intensified NIS2 requirements. ",
         "Standard errors clustered at the country level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ===========================================================================
# Table 3: Category-Level Decomposition
# ===========================================================================
message("Generating Table 3: Category Decomposition...")

mc <- results$m_compliance
mt <- results$m_technical
mtr <- results$m_training
mc_d <- results$m_ddd_compliance
mt_d <- results$m_ddd_technical
mtr_d <- results$m_ddd_training

tab3_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{NIS2 Effects by Security Category: Compliance Theater or Real Investment?}",
  "\\label{tab:categories}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{DiD} & \\multicolumn{3}{c}{DDD (Transposed)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Compliance & Technical & Training & Compliance & Technical & Training \\\\",
  "\\midrule",
  sprintf("Medium $\\times$ Post & %s & %s & %s & %s & %s & %s \\\\",
          fmt_coef(coef(mc)["treat_post"], pvalue(mc)["treat_post"]),
          fmt_coef(coef(mt)["treat_post"], pvalue(mt)["treat_post"]),
          fmt_coef(coef(mtr)["treat_post"], pvalue(mtr)["treat_post"]),
          fmt_coef(coef(mc_d)["treat_post"], pvalue(mc_d)["treat_post"]),
          fmt_coef(coef(mt_d)["treat_post"], pvalue(mt_d)["treat_post"]),
          fmt_coef(coef(mtr_d)["treat_post"], pvalue(mtr_d)["treat_post"])),
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\",
          fmt_se(se(mc)["treat_post"]),
          fmt_se(se(mt)["treat_post"]),
          fmt_se(se(mtr)["treat_post"]),
          fmt_se(se(mc_d)["treat_post"]),
          fmt_se(se(mt_d)["treat_post"]),
          fmt_se(se(mtr_d)["treat_post"])),
  sprintf("Med. $\\times$ Post $\\times$ Transposed & & & & %s & %s & %s \\\\",
          fmt_coef(coef(mc_d)["triple"], pvalue(mc_d)["triple"]),
          fmt_coef(coef(mt_d)["triple"], pvalue(mt_d)["triple"]),
          fmt_coef(coef(mtr_d)["triple"], pvalue(mtr_d)["triple"])),
  sprintf(" & & & & %s & %s & %s \\\\",
          fmt_se(se(mc_d)["triple"]),
          fmt_se(se(mt_d)["triple"]),
          fmt_se(se(mtr_d)["triple"])),
  "\\midrule",
  "Country $\\times$ Size FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Country $\\times$ Year FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d & %d \\\\",
          nobs(mc), nobs(mt), nobs(mtr),
          nobs(mc_d), nobs(mt_d), nobs(mtr_d)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Dependent variables are category-specific cybersecurity indices (percentage points). ",
         "Compliance index averages security policy documentation, risk assessment, and off-site backup. ",
         "Technical index averages encryption, VPN, log maintenance, biometric authentication, network access control, strong passwords, and security testing. ",
         "Training index averages any awareness activities, staff training provided, mandatory training, voluntary training, and awareness combined with policy. ",
         "All specifications include country$\\times$size and country$\\times$year fixed effects with country-clustered standard errors. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab3_tex, "../tables/tab3_categories.tex")

# ===========================================================================
# Table 4: Individual Indicator Results (Selected)
# ===========================================================================
message("Generating Table 4: Individual Indicator Results...")

indic_dt <- results$indic_results

# Select key indicators
key_indics <- c("E_SECPOL2", "E_SECMRASS", "E_SECMDENC", "E_SECMUIBM",
                "E_SECMLOG", "E_SECMTST", "E_SECAWCTP", "E_SECAWCONT")
key_dt <- indic_dt[indic_is %in% key_indics]
key_dt[, ord := match(indic_is, key_indics)]
setorder(key_dt, ord)

tab4_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{NIS2 Effects on Individual Security Measures}",
  "\\label{tab:individual}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Measure & Category & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & $p$-value \\\\",
  "\\midrule"
)

for (i in 1:nrow(key_dt)) {
  row <- key_dt[i]
  sde_val <- row$beta / row$sd_y
  tab4_tex <- c(tab4_tex,
    sprintf("%s & %s & %.2f & %.2f & %.1f & %.3f & %.3f \\\\",
            row$label, row$category, row$beta, row$se,
            row$sd_y, sde_val, row$pval))
}

tab4_tex <- c(tab4_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Each row reports the DiD coefficient from a separate regression of the individual ",
         "measure (\\% of enterprises) on Medium$\\times$Post with country$\\times$size and country$\\times$year fixed effects, ",
         "clustered at the country level. SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
         "N = 162 (27 countries $\\times$ 2 size classes $\\times$ 3 years) per regression. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab4_tex, "../tables/tab4_individual.tex")

# ===========================================================================
# Table 5: Robustness
# ===========================================================================
message("Generating Table 5: Robustness...")

loo_dt <- rob_results$loo
m_placebo <- rob_results$placebo
ddd_loo_dt <- rob_results$ddd_loo

tab5_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & $\\hat{\\beta}$ & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: DiD Sensitivity}} \\\\[3pt]",
  sprintf("Baseline DiD & %s & %s \\\\",
          fmt_coef(coef(results$m1_full)["treat_post"],
                   pvalue(results$m1_full)["treat_post"]),
          fmt_se(se(results$m1_full)["treat_post"])),
  sprintf("Placebo (2019 vs 2022) & %s & %s \\\\",
          fmt_coef(coef(m_placebo)["placebo_treat"],
                   pvalue(m_placebo)["placebo_treat"]),
          fmt_se(se(m_placebo)["placebo_treat"])),
  sprintf("Leave-one-out range & [%.2f, %.2f] & \\\\",
          min(loo_dt$beta), max(loo_dt$beta)),
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel B: DDD Leave-One-Out (dropping each transposed country)}} \\\\[3pt]"
)

for (i in 1:nrow(ddd_loo_dt)) {
  row <- ddd_loo_dt[i]
  tab5_tex <- c(tab5_tex,
    sprintf("Drop %s & %s & %s \\\\",
            row$dropped,
            fmt_coef(row$beta_triple, row$pval_triple),
            fmt_se(row$se_triple)))
}

tab5_tex <- c(tab5_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Panel A tests the main DiD robustness. The placebo test uses 2019 vs 2022 ",
         "(both pre-NIS2). Leave-one-out drops each of 27 EU countries and re-estimates. ",
         "Panel B tests the DDD triple interaction (Medium$\\times$Post$\\times$Transposed) stability by ",
         "sequentially dropping each of the six countries that transposed by the October 2024 deadline. ",
         "All specifications include country$\\times$size and country$\\times$year fixed effects with country-clustered SEs. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(tab5_tex, "../tables/tab5_robustness.tex")

# ===========================================================================
# SDE Table (Mandatory Appendix)
# ===========================================================================
message("Generating SDE Table...")

# Main outcome: security index
m_main <- results$m1_full
beta_main <- coef(m_main)["treat_post"]
se_main <- se(m_main)["treat_post"]
sd_y_main <- sd(did_sample$security_index, na.rm = TRUE)
sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

# Training index
m_train <- results$m_training
beta_train <- coef(m_train)["treat_post"]
se_train <- se(m_train)["treat_post"]
sd_y_train <- sd(did_sample$training_index, na.rm = TRUE)
sde_train <- beta_train / sd_y_train
se_sde_train <- se_train / sd_y_train

# Staff training (individual)
staff_row <- results$indic_results[indic_is == "E_SECAWCTP"]
sde_staff <- staff_row$beta / staff_row$sd_y
se_sde_staff <- staff_row$se / staff_row$sd_y

# Biometric auth (individual)
bio_row <- results$indic_results[indic_is == "E_SECMUIBM"]
sde_bio <- bio_row$beta / bio_row$sd_y
se_sde_bio <- bio_row$se / bio_row$sd_y

# DDD triple: security index
m_ddd <- results$m_ddd
beta_ddd <- coef(m_ddd)["triple"]
se_ddd <- se(m_ddd)["triple"]
sde_ddd <- beta_ddd / sd_y_main
se_sde_ddd <- se_ddd / sd_y_main

classify <- function(s) {
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

# Build SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Does the EU NIS2 Directive's cybersecurity regulation for medium-sized enterprises ",
  "change security investment behavior relative to exempt small firms? ",
  "\\textbf{Policy mechanism:} NIS2 (Directive 2022/2555) imposes mandatory risk assessment, incident reporting ",
  "within 24 hours, supply chain security obligations, and staff cybersecurity training on enterprises with 50 or more ",
  "employees, while exempting firms below this threshold; transposition varied across member states with only six completing by the October 2024 deadline. ",
  "\\textbf{Outcome definition:} Share of enterprises (percentage points) adopting specific cybersecurity measures, ",
  "as reported in the Eurostat ICT Security Survey. ",
  "\\textbf{Treatment:} Binary---enterprises with 50--249 employees (newly NIS2-regulated) vs.\\ 10--49 employees (exempt). ",
  "\\textbf{Data:} Eurostat \\texttt{isoc\\_cisce\\_ra}, waves 2019, 2022, 2024; 27 EU countries $\\times$ 2 size classes $\\times$ 3 years = 162 observations. ",
  "\\textbf{Method:} Difference-in-differences with country$\\times$size and country$\\times$year fixed effects; standard errors clustered at the country level. ",
  "\\textbf{Sample:} All EU-27 member states with non-missing data; enterprises in NACE C10--S951 excluding financial sector. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Security index & DiD & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          beta_main, se_main, sd_y_main, sde_main, se_sde_main, classify(sde_main)),
  sprintf("Training index & DiD & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          beta_train, se_train, sd_y_train, sde_train, se_sde_train, classify(sde_train)),
  sprintf("Staff training & DiD & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          staff_row$beta, staff_row$se, staff_row$sd_y, sde_staff, se_sde_staff, classify(sde_staff)),
  sprintf("Biometric auth. & DiD & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          bio_row$beta, bio_row$se, bio_row$sd_y, sde_bio, se_sde_bio, classify(sde_bio)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (Transposed vs.\\ Non-Transposed Countries)}} \\\\",
  sprintf("Security index & DDD triple & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          beta_ddd, se_ddd, sd_y_main, sde_ddd, se_sde_ddd, classify(sde_ddd)),
  # Non-transposed countries: just the DiD term from DDD
  sprintf("Security index & DiD (non-transp.) & %.2f & %.2f & %.1f & %.3f & %.3f & %s \\\\",
          coef(m_ddd)["treat_post"], se(m_ddd)["treat_post"], sd_y_main,
          coef(m_ddd)["treat_post"] / sd_y_main,
          se(m_ddd)["treat_post"] / sd_y_main,
          classify(coef(m_ddd)["treat_post"] / sd_y_main)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

message("\nAll tables generated.")
