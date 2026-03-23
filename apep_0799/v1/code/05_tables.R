## ==========================================================================
## 05_tables.R — Generate LaTeX tables (including SDE appendix)
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

source("code/00_packages.R")

load("data/models.RData")
load("data/robustness.RData")
diag <- fromJSON("data/diagnostics.json")

dir.create("tables", showWarnings = FALSE)

## =====================================================================
## TABLE 1: Summary Statistics
## =====================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

summ_vars <- c("ntl_mean", "n_shutdowns", "total_shutdown_days",
               "any_shutdown", "any_exam_shutdown", "shutdown_intensity")
panel[, shutdown_intensity := total_shutdown_days / 365]

summ_list <- lapply(summ_vars, function(v) {
  data.table(
    Variable = v,
    Mean = round(mean(panel[[v]], na.rm = TRUE), 3),
    SD = round(sd(panel[[v]], na.rm = TRUE), 3),
    Min = round(min(panel[[v]], na.rm = TRUE), 3),
    Max = round(max(panel[[v]], na.rm = TRUE), 3)
  )
})
summ_full <- rbindlist(summ_list)

# Prettier names
summ_full[Variable == "ntl_mean", Variable := "Nighttime lights (radiance)"]
summ_full[Variable == "n_shutdowns", Variable := "Number of shutdowns"]
summ_full[Variable == "total_shutdown_days", Variable := "Total shutdown days"]
summ_full[Variable == "any_shutdown", Variable := "Any shutdown"]
summ_full[Variable == "any_exam_shutdown", Variable := "Any exam shutdown"]
summ_full[Variable == "shutdown_intensity", Variable := "Shutdown intensity (days/365)"]

# LaTeX table
tex_summ <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  paste0(apply(summ_full, 1, function(r) {
    paste(r, collapse = " & ")
  }), " \\\\", collapse = "\n"),
  "\n\\hline\n",
  paste0("\\multicolumn{5}{l}{\\footnotesize $N = ",
         format(nrow(panel), big.mark = ","),
         "$ district-year observations, ",
         diag$n_districts, " districts, ",
         diag$n_years, " years (2014--2022).} \\\\\n"),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{table}\n"
)

writeLines(tex_summ, "tables/tab1_summary.tex")

## =====================================================================
## TABLE 2: Main Results
## =====================================================================

cat("=== Generating Table 2: Main Results ===\n")

tab2 <- etable(m1, m2, m3, m4, m5, m6,
               headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
               dict = c(any_shutdown = "Any Shutdown",
                        shutdown_intensity = "Shutdown Intensity (days/365)"),
               se.below = TRUE,
               fixef.group = list("District FE" = "GID_2",
                                  "Year FE" = "^year$",
                                  "State $\\times$ Year FE" = "NAME_1"),
               notes = paste0("Standard errors clustered at district level in parentheses. ",
                              "Columns (5)--(6) exclude Jammu \\& Kashmir. ",
                              "Dependent variable: $\\log(\\text{NTL} + 0.01)$. ",
                              "$N = ", format(nrow(panel), big.mark = ","), "$."),
               title = "Internet Shutdowns and Nighttime Lights",
               label = "tab:main",
               style.tex = style.tex("aer"),
               tex = TRUE,
               file = "tables/tab2_main.tex",
               replace = TRUE)

## =====================================================================
## TABLE 3: Exam Shutdowns
## =====================================================================

cat("=== Generating Table 3: Exam Shutdowns ===\n")

panel[, exam_intensity := exam_shutdown_days / 365]
panel[, nonexam_intensity := (total_shutdown_days - exam_shutdown_days) / 365]

tab3 <- etable(m_exam1, m_exam2, m_exam3, m_exam4,
               headers = c("(1)", "(2)", "(3)", "(4)"),
               dict = c(any_exam_shutdown = "Exam Shutdown",
                        exam_intensity = "Exam Intensity",
                        nonexam_intensity = "Non-Exam Intensity"),
               se.below = TRUE,
               fixef.group = list("District FE" = "GID_2",
                                  "Year FE" = "^year$",
                                  "State $\\times$ Year FE" = "NAME_1"),
               notes = paste0("Exam shutdowns are imposed to prevent cheating during ",
                              "competitive examinations (REET, RPSC, board exams). ",
                              "These are driven by exam calendars, not economic conditions. ",
                              "Standard errors clustered at district level."),
               title = "Exam-Triggered Shutdowns: Plausibly Exogenous Variation",
               label = "tab:exam",
               style.tex = style.tex("aer"),
               tex = TRUE,
               file = "tables/tab3_exam.tex",
               replace = TRUE)

## =====================================================================
## TABLE 4: Heterogeneity
## =====================================================================

cat("=== Generating Table 4: Heterogeneity ===\n")

tab4 <- etable(m_het1, m_het2, m_het3,
               headers = c("Duration", "Cause", "Frequency"),
               dict = c(short_shutdown = "Short ($\\leq$ 30 days)",
                        long_shutdown = "Long ($>$ 30 days)",
                        protest_shutdown = "Protest-Triggered",
                        political_shutdown = "Political-Triggered",
                        any_exam_shutdown = "Exam-Triggered",
                        few_shutdowns = "Few (1--4 per year)",
                        many_shutdowns = "Many ($\\geq$ 5 per year)"),
               se.below = TRUE,
               fixef.group = list("District FE" = "GID_2",
                                  "State $\\times$ Year FE" = "NAME_1"),
               notes = paste0("All specifications include district and state $\\times$ year ",
                              "fixed effects. Standard errors clustered at district level."),
               title = "Heterogeneity by Shutdown Duration, Cause, and Frequency",
               label = "tab:het",
               style.tex = style.tex("aer"),
               tex = TRUE,
               file = "tables/tab4_heterogeneity.tex",
               replace = TRUE)

## =====================================================================
## TABLE 5: Robustness
## =====================================================================

cat("=== Generating Table 5: Robustness ===\n")

tab5 <- etable(m_level, m_ihs, m_placebo, m_dose,
               headers = c("Level", "IHS", "Placebo", "Dose-Response"),
               se.below = TRUE,
               fixef.group = list("District FE" = "GID_2",
                                  "Year FE" = "^year$",
                                  "State $\\times$ Year FE" = "NAME_1"),
               notes = paste0("Column (1): dependent variable in levels (mean radiance). ",
                              "Column (2): inverse hyperbolic sine transform. ",
                              "Column (3): placebo test using pre-period (2014--2016) data ",
                              "with treatment assigned based on future shutdown status. ",
                              "Column (4): dose-response with shutdown duration categories. ",
                              "All SEs clustered at district level."),
               title = "Robustness Checks",
               label = "tab:robust",
               style.tex = style.tex("aer"),
               tex = TRUE,
               file = "tables/tab5_robustness.tex",
               replace = TRUE)

## =====================================================================
## APPENDIX TABLE F1: Standardized Effect Sizes (SDE)
## =====================================================================

cat("=== Generating SDE Table (Appendix) ===\n")

# Compute SDE for main outcomes
sd_y <- sd(panel$log_ntl, na.rm = TRUE)

sde_rows <- data.table(
  Outcome = character(),
  beta = numeric(),
  se_beta = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character()
)

# Classification function
classify_sde <- function(sde_val) {
  abs_sde <- abs(sde_val)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde_val < 0) return("Small negative") else return("Small positive")
  }
  if (abs_sde < 0.15) {
    if (sde_val < 0) return("Moderate negative") else return("Moderate positive")
  }
  if (sde_val < 0) return("Large negative") else return("Large positive")
}

# Main specification: any_shutdown with state×year FE
b3 <- coef(m3)["any_shutdown"]
se3 <- se(m3)["any_shutdown"]
sde3 <- b3 / sd_y
se_sde3 <- se3 / sd_y

sde_rows <- rbind(sde_rows, data.table(
  Outcome = "Log nighttime lights (any shutdown)",
  beta = b3, se_beta = se3, sd_y = sd_y,
  sde = sde3, se_sde = se_sde3,
  classification = classify_sde(sde3)
))

# Exam shutdown
b_exam <- coef(m_exam2)["any_exam_shutdown"]
se_exam <- se(m_exam2)["any_exam_shutdown"]
sde_exam <- b_exam / sd_y

sde_rows <- rbind(sde_rows, data.table(
  Outcome = "Log nighttime lights (exam shutdown)",
  beta = b_exam, se_beta = se_exam, sd_y = sd_y,
  sde = sde_exam, se_sde = se_exam / sd_y,
  classification = classify_sde(sde_exam)
))

# Excluding J&K
b5 <- coef(m5)["any_shutdown"]
se5 <- se(m5)["any_shutdown"]
sd_y_nojk <- sd(panel[is_jk == 0, log_ntl], na.rm = TRUE)
sde5 <- b5 / sd_y_nojk

sde_rows <- rbind(sde_rows, data.table(
  Outcome = "Log nighttime lights (excl. J\\&K)",
  beta = b5, se_beta = se5, sd_y = sd_y_nojk,
  sde = sde5, se_sde = se5 / sd_y_nojk,
  classification = classify_sde(sde5)
))

# Continuous treatment (shutdown intensity)
b4 <- coef(m4)["shutdown_intensity"]
se4 <- se(m4)["shutdown_intensity"]
sd_x <- sd(panel$shutdown_intensity[panel$shutdown_intensity > 0], na.rm = TRUE)
sde4 <- b4 * sd_x / sd_y

sde_rows <- rbind(sde_rows, data.table(
  Outcome = "Log nighttime lights (intensity)",
  beta = b4, se_beta = se4, sd_y = sd_y,
  sde = sde4, se_sde = se4 * sd_x / sd_y,
  classification = classify_sde(sde4)
))

# Format SDE table
sde_rows[, `:=`(
  beta_fmt = sprintf("%.4f", beta),
  se_fmt = sprintf("%.4f", se_beta),
  sd_y_fmt = sprintf("%.3f", sd_y),
  sde_fmt = sprintf("%.4f", sde),
  se_sde_fmt = sprintf("%.4f", se_sde)
)]

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Do government-imposed internet shutdowns reduce ",
  "local economic activity, as measured by satellite-detected nighttime lights? ",
  "\\textbf{Policy mechanism:} State and district authorities order telecommunications ",
  "providers to suspend internet services under Section 144 CrPC or the Telecom ",
  "Suspension Rules 2017, cutting digital access for hours to months and disrupting ",
  "commerce, communication, and information flows. ",
  "\\textbf{Outcome definition:} Annual mean nighttime radiance from VIIRS Black Marble ",
  "(VNP46A4) composites at the district level, log-transformed. ",
  "\\textbf{Treatment:} Binary indicator for any internet shutdown in a district-year, ",
  "or continuous shutdown intensity (total shutdown days divided by 365). ",
  "\\textbf{Data:} Internet Shutdown Tracker (Koning 2023) matched to GADM Level 2 ",
  "districts, merged with NASA VIIRS VNP46A4, 2014--2022, district-year panel, $N = ",
  format(nrow(panel), big.mark = ","), "$ observations. ",
  "\\textbf{Method:} TWFE with district and state $\\times$ year fixed effects; ",
  "standard errors clustered at district level; exam-triggered shutdowns as ",
  "plausibly exogenous subsample. ",
  "\\textbf{Sample:} All Indian districts with non-missing VIIRS data; ",
  uniqueN(panel[any_shutdown == 1, GID_2]), " treated districts across ",
  length(unique(panel$year)), " years. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table
tex_sde <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste0(apply(sde_rows[, .(Outcome, beta_fmt, se_fmt, sd_y_fmt,
                             sde_fmt, se_sde_fmt, classification)], 1,
               function(r) paste(r, collapse = " & ")),
         " \\\\", collapse = "\n"),
  "\n\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize\n",
  "\\begin{itemize}[leftmargin=*,nosep]\n",
  sde_notes, "\n",
  "\\end{itemize}}\n",
  "\\end{table}\n"
)

writeLines(tex_sde, "tables/tabF1_sde.tex")
cat("All tables saved to tables/\n")
cat("Files:", paste(list.files("tables/"), collapse = ", "), "\n")
