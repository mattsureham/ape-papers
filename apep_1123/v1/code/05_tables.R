## 05_tables.R — Generate all tables
## APEP-1123: The Registration Effect

source("00_packages.R")

cat("=== Generating Tables ===\n")

df <- read_csv("data/trials_analysis.csv", show_col_types = FALSE)
df_comp <- read_csv("data/trials_completed.csv", show_col_types = FALSE)
load("data/main_models.RData")
load("data/robustness_models.RData")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n--- Table 1: Summary Statistics ---\n")

summ <- df |>
  mutate(period = ifelse(post == 1, "Post (2008--2015)", "Pre (2003--2007)")) |>
  group_by(phase_group, period) |>
  summarise(
    N = n(),
    `Completed (\\%)` = sprintf("%.1f", 100 * mean(overall_status %in% c("COMPLETED", "TERMINATED"), na.rm = TRUE)),
    `Has Results (\\%)` = sprintf("%.1f", 100 * mean(has_results_posted, na.rm = TRUE)),
    `Primary Outcomes` = sprintf("%.2f", mean(n_primary, na.rm = TRUE)),
    `Enrollment` = sprintf("%.0f", mean(enrollment, na.rm = TRUE)),
    `Industry (\\%)` = sprintf("%.1f", 100 * mean(is_industry, na.rm = TRUE)),
    `US Site (\\%)` = sprintf("%.1f", 100 * mean(has_us_site, na.rm = TRUE)),
    .groups = "drop"
  )

# Create LaTeX table
tab1_header <- paste(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Clinical Trials by Phase and Period}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llccccccc}",
  "\\toprule",
  "Phase & Period & N & Completed & Results & Primary & Enrollment & Industry & US Site \\\\",
  " & & & (\\%) & (\\%) & Outcomes & (mean) & (\\%) & (\\%) \\\\",
  "\\midrule",
  sep = "\n"
)

tab1_rows <- ""
for (i in 1:nrow(summ)) {
  row <- summ[i, ]
  tab1_rows <- paste0(tab1_rows,
    sprintf("%s & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
            row$phase_group, row$period, format(row$N, big.mark = ","),
            row$`Completed (\\%)`, row$`Has Results (\\%)`,
            row$`Primary Outcomes`, row$Enrollment,
            row$`Industry (\\%)`, row$`US Site (\\%)`))
  if (i == 2) tab1_rows <- paste0(tab1_rows, "\\midrule\n")
}

tab1_footer <- paste(
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample includes all interventional clinical trials registered on ClinicalTrials.gov with start dates between 2003 and 2015. Phase 1 trials (control group) are exempt from FDAAA 801 reporting requirements. Phase 2/3 trials (treatment group) were mandated to register and report results after September 2007. ``Completed'' includes trials with status Completed or Terminated. ``Results'' indicates whether results have been posted to the registry. ``Primary Outcomes'' is the number of pre-specified primary outcome measures at registration.",
  "\\end{tablenotes}",
  "\\end{table}",
  sep = "\n"
)

writeLines(paste0(tab1_header, tab1_rows, tab1_footer), "tables/tab1_summary.tex")
cat("  Table 1 saved.\n")

# ============================================================
# TABLE 2: Main DiD Results — Results Reporting
# ============================================================
cat("\n--- Table 2: Main DiD ---\n")

# Build table manually with fixest etable
tab2 <- etable(m1_base, m1_yfe, m1_ctrl, m1_full,
               se.below = TRUE,
               keep = c("%treat_post", "%treated", "%is_industry", "%log_enrollment"),
               dict = c(treat_post = "Phase 2/3 $\\times$ Post",
                        treated = "Phase 2/3",
                        is_industry = "Industry Sponsor",
                        log_enrollment = "Log(Enrollment)"),
               fixef.group = list("Year FE" = "start_year",
                                  "Purpose FE" = "primary_purpose"),
               fitstat = c("n", "r2"),
               tex = TRUE,
               file = "tables/tab2_main_did.tex",
               title = "Effect of FDAAA 801 on Results Reporting",
               label = "tab:main_did",
               replace = TRUE)

# Add notes
tab2_notes <- paste0(
  "\n\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is an indicator for whether the trial has posted results to ClinicalTrials.gov. ",
  "Sample restricted to completed or terminated interventional trials started between 2003 and 2015. ",
  "Phase 2/3 trials were subject to FDAAA 801 mandatory reporting after September 2007; Phase 1 trials were exempt. ",
  "Standard errors clustered by start year in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n"
)
tab2_file <- readLines("tables/tab2_main_did.tex")
tab2_file <- c(tab2_file[1:(length(tab2_file)-1)], tab2_notes, tab2_file[length(tab2_file)])
writeLines(tab2_file, "tables/tab2_main_did.tex")

cat("  Table 2 saved.\n")

# ============================================================
# TABLE 3: Mechanism — Primary Outcomes and Reporting Lag
# ============================================================
cat("\n--- Table 3: Mechanism ---\n")

tab3 <- etable(m2_base, m2_ctrl, m2_full, m_has_po,
               se.below = TRUE,
               keep = c("%treat_post", "%treated"),
               dict = c(treat_post = "Phase 2/3 $\\times$ Post",
                        treated = "Phase 2/3"),
               headers = list("^:_:" = c("Primary Outcome Count",
                                          "Primary Outcome Count",
                                          "Primary Outcome Count",
                                          "Has Primary Outcome")),
               fixef.group = list("Year FE" = "start_year",
                                  "Purpose FE" = "primary_purpose"),
               fitstat = c("n", "r2"),
               tex = TRUE,
               file = "tables/tab3_mechanism.tex",
               title = "Effect of FDAAA 801 on Outcome Pre-specification",
               label = "tab:mechanism",
               replace = TRUE)

tab3_notes <- paste0(
  "\n\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Columns (1)--(3): dependent variable is the number of primary outcomes pre-specified at registration. ",
  "Column (4): dependent variable is an indicator for having at least one pre-specified primary outcome. ",
  "Sample includes all interventional trials (not restricted to completed) started between 2003 and 2015. ",
  "Standard errors clustered by start year in parentheses. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n"
)
tab3_file <- readLines("tables/tab3_mechanism.tex")
tab3_file <- c(tab3_file[1:(length(tab3_file)-1)], tab3_notes, tab3_file[length(tab3_file)])
writeLines(tab3_file, "tables/tab3_mechanism.tex")

cat("  Table 3 saved.\n")

# ============================================================
# TABLE 4: Heterogeneity by Sponsor & Geography
# ============================================================
cat("\n--- Table 4: Heterogeneity ---\n")

tab4 <- etable(m_industry, m_nonindustry, m_us, m_nonus,
               se.below = TRUE,
               keep = c("%treat_post", "%treated"),
               dict = c(treat_post = "Phase 2/3 $\\times$ Post",
                        treated = "Phase 2/3"),
               headers = list("^:_:" = c("Industry", "Non-Industry",
                                          "US Sites", "Non-US")),
               fixef.group = list("Year FE" = "start_year"),
               fitstat = c("n", "r2"),
               tex = TRUE,
               file = "tables/tab4_heterogeneity.tex",
               title = "Heterogeneity in FDAAA 801 Effects by Sponsor Type and Geography",
               label = "tab:hetero",
               replace = TRUE)

tab4_notes <- paste0(
  "\n\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is an indicator for results posting. ",
  "Sample restricted to completed or terminated interventional trials (2003--2015). ",
  "Columns (1)--(2) split by lead sponsor class (Industry vs.~NIH/Other/Academic). ",
  "Columns (3)--(4) split by whether the trial includes at least one US site. ",
  "FDAAA 801 is a US law; non-US trials are subject to it only if they involve FDA-regulated products. ",
  "Standard errors clustered by start year. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n"
)
tab4_file <- readLines("tables/tab4_heterogeneity.tex")
tab4_file <- c(tab4_file[1:(length(tab4_file)-1)], tab4_notes, tab4_file[length(tab4_file)])
writeLines(tab4_file, "tables/tab4_heterogeneity.tex")

cat("  Table 4 saved.\n")

# ============================================================
# TABLE 5: Robustness
# ============================================================
cat("\n--- Table 5: Robustness ---\n")

tab5 <- etable(m_placebo, m_donut, m_narrow, m_p2, m_p3,
               se.below = TRUE,
               keep = c("%fake_treat_post", "%treat_post", "%treat_post_p2", "%treat_post_p3"),
               dict = c(fake_treat_post = "Phase 2/3 $\\times$ Fake Post",
                        treat_post = "Phase 2/3 $\\times$ Post",
                        treat_post_p2 = "Phase 2 $\\times$ Post",
                        treat_post_p3 = "Phase 3 $\\times$ Post"),
               headers = list("^:_:" = c("Placebo", "Donut",
                                          "Narrow", "Ph2 vs 1",
                                          "Ph3 vs 1")),
               fixef.group = list("Year FE" = "start_year"),
               fitstat = c("n", "r2"),
               tex = TRUE,
               file = "tables/tab5_robustness.tex",
               title = "Robustness Checks",
               label = "tab:robust",
               replace = TRUE)

tab5_notes <- paste0(
  "\n\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column (1): placebo test using pre-period data only (2003--2007) with a fake treatment date of 2006. ",
  "Column (2): donut specification excluding transition years 2007--2008. ",
  "Column (3): narrow window (2005--2010). ",
  "Columns (4)--(5): separate DiD for Phase 2 and Phase 3 trials against Phase 1 control. ",
  "Dependent variable is results posting indicator. ",
  "Standard errors clustered by start year. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n"
)
tab5_file <- readLines("tables/tab5_robustness.tex")
tab5_file <- c(tab5_file[1:(length(tab5_file)-1)], tab5_notes, tab5_file[length(tab5_file)])
writeLines(tab5_file, "tables/tab5_robustness.tex")

cat("  Table 5 saved.\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================
cat("\n--- Table F1: SDE ---\n")

# Compute SDEs for main outcomes
compute_sde <- function(model, outcome_var, data, outcome_label, treat_var = "treat_post") {
  beta <- coef(model)[treat_var]
  se_beta <- se(model)[treat_var]
  # Pre-treatment SD of outcome
  pre_data <- data |> filter(post == 0)
  sd_y <- sd(pre_data[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  classify <- function(s) {
    if (s < -0.15) return("Large negative")
    if (s < -0.05) return("Moderate negative")
    if (s < -0.005) return("Small negative")
    if (s < 0.005) return("Null")
    if (s < 0.05) return("Small positive")
    if (s < 0.15) return("Moderate positive")
    return("Large positive")
  }

  tibble(
    Outcome = outcome_label,
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = classify(sde)
  )
}

sde_rows <- bind_rows(
  compute_sde(m1_full, "has_results_posted", df_comp, "Results Reporting Rate"),
  compute_sde(m2_full, "n_primary", df, "Primary Outcome Count")
)

# Panel B: Heterogeneous (sample splits)
sde_hetero <- bind_rows(
  compute_sde(m_industry, "has_results_posted",
              df_comp |> filter(is_industry == 1),
              "Results Reporting (Industry)"),
  compute_sde(m_nonindustry, "has_results_posted",
              df_comp |> filter(is_industry == 0),
              "Results Reporting (Non-Industry)")
)

# Format SDE table in LaTeX
format_sde_row <- function(r) {
  sprintf("%s & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s",
          r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States (federal law with global registry reach). ",
  "\\textbf{Research question:} Does mandating pre-registration of clinical trial outcomes under FDAAA 801 increase results reporting rates and change outcome pre-specification behavior among Phase 2/3 interventional trials? ",
  "\\textbf{Policy mechanism:} FDAAA 801 (September 2007) requires sponsors of Phase 2+ interventional trials involving FDA-regulated products to register primary outcomes on ClinicalTrials.gov within 21 days of first enrollment and post results within one year of completion, backed by civil penalties up to \\$10,000/day under the 2017 Final Rule. ",
  "\\textbf{Outcome definition:} (1) Results reporting rate: binary indicator for whether a completed trial has posted summary results to ClinicalTrials.gov; (2) Primary outcome count: number of primary outcome measures pre-specified at registration. ",
  "\\textbf{Treatment:} Binary --- Phase 2/3 trials subject to FDAAA 801 mandate vs.\\ Phase 1 trials explicitly exempt. ",
  "\\textbf{Data:} ClinicalTrials.gov registry via API v2, all interventional trials with start dates 2003--2015, trial-level observations. ",
  "\\textbf{Method:} Difference-in-differences with year and primary-purpose fixed effects; standard errors clustered by start year. ",
  "\\textbf{Sample:} Interventional clinical trials registered on ClinicalTrials.gov; results reporting restricted to completed/terminated trials. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  paste(sapply(1:nrow(sde_rows), function(i) paste0(format_sde_row(sde_rows[i,]), " \\\\")),
        collapse = "\n"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sponsor Type)}} \\\\",
  paste(sapply(1:nrow(sde_hetero), function(i) paste0(format_sde_row(sde_hetero[i,]), " \\\\")),
        collapse = "\n"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}",
  sep = "\n"
)

writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("  Table F1 (SDE) saved.\n")

cat("\n=== All tables generated ===\n")
