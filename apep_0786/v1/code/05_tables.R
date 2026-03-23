## 05_tables.R — Generate all LaTeX tables including SDE appendix
## APEP paper apep_0786: HMDA Reporting Exemption and Minority Lending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and models
bw <- as.data.table(arrow::read_parquet(file.path(data_dir, "panel_bw.parquet")))
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

vars_to_summarize <- c("deny_gap", "deny_black", "deny_white",
                        "apps_black", "apps_white", "total_volume",
                        "income_black", "income_white")

# Overall and by exempt status
make_sumstats <- function(d, label) {
  sapply(vars_to_summarize, function(v) {
    x <- d[[v]]
    c(mean = mean(x, na.rm = TRUE),
      sd = sd(x, na.rm = TRUE),
      N = sum(!is.na(x)))
  }) |> t() |> as.data.frame()
}

ss_all <- make_sumstats(bw, "All")
ss_exempt <- make_sumstats(bw[exempt == 1], "Exempt")
ss_nonexempt <- make_sumstats(bw[exempt == 0], "Non-exempt")

# Build LaTeX
var_labels <- c(
  "Black--White denial gap",
  "Black denial rate",
  "White denial rate",
  "Black applications (N)",
  "White applications (N)",
  "Total applications",
  "Black applicant income (\\$000s)",
  "White applicant income (\\$000s)"
)

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Lender-County-Year Panel}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "& \\multicolumn{2}{c}{All} & \\multicolumn{2}{c}{Exempt} & \\multicolumn{2}{c}{Non-Exempt} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "& Mean & SD & Mean & SD & Mean & SD \\\\"
)

tab1_lines <- c(tab1_lines, "\\midrule")

for (i in seq_along(vars_to_summarize)) {
  row <- sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
                 var_labels[i],
                 ss_all[i, "mean"], ss_all[i, "sd"],
                 ss_exempt[i, "mean"], ss_exempt[i, "sd"],
                 ss_nonexempt[i, "mean"], ss_nonexempt[i, "sd"])
  tab1_lines <- c(tab1_lines, row)
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  sprintf("\\begin{tablenotes}[flushleft]\\small"),
  sprintf("\\item \\textit{Notes:} Unit of observation is lender-county-year. N = %s (exempt = %s, non-exempt = %s). Sample restricted to counties with both exempt and non-exempt lenders and lender-county-years with $\\geq$ 5 applications from both Black and White borrowers. Conventional first-lien home purchase loans, 2018--2022.",
          format(nrow(bw), big.mark = ","),
          format(nrow(bw[exempt == 1]), big.mark = ","),
          format(nrow(bw[exempt == 0]), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ---------------------------------------------------------------
# Table 2: Main Results (5 columns)
# ---------------------------------------------------------------
cat("Generating Table 2: Main Results...\n")

# Extract coefficients for main results table
extract_row <- function(model, varname = "exempt") {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  n <- nobs(model)
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  list(b = b, s = s, stars = stars, n = n)
}

models <- list(m1, m2, m3, m4, m5)
model_labels <- c("(1)", "(2)", "(3)", "(4)", "(5)")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{The Detection Gap: HMDA Reporting Exemption and Racial Denial Disparities}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste0("& ", paste(model_labels, collapse = " & "), " \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Dependent variable: Black--White denial rate gap}} \\\\"
)

# Exempt coefficient row
coefs <- lapply(models, extract_row)
coef_row <- paste0("Exempt & ",
  paste(sapply(coefs, function(x) sprintf("%.4f%s", x$b, x$stars)), collapse = " & "),
  " \\\\")
se_row <- paste0("& ",
  paste(sapply(coefs, function(x) sprintf("(%.4f)", x$s)), collapse = " & "),
  " \\\\")

tab2_lines <- c(tab2_lines, coef_row, se_row, "\\\\")

# Fixed effects rows
tab2_lines <- c(tab2_lines,
  "County FE & & Yes & & & Yes \\\\",
  "Year FE & & Yes & & & \\\\",
  "County $\\times$ Year FE & & & Yes & Yes & \\\\",
  "State $\\times$ Year FE & & & & & Yes \\\\",
  "Controls & & & & Yes & Yes \\\\",
  "\\midrule"
)

# N row
n_row <- paste0("N & ",
  paste(sapply(coefs, function(x) format(x$n, big.mark = ",")), collapse = " & "),
  " \\\\")
tab2_lines <- c(tab2_lines, n_row)

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the county level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. The dependent variable is the Black--White denial rate gap (Black denial rate minus White denial rate) at the lender-county-year level. ``Exempt'' is an indicator for lenders exempted from expanded HMDA reporting under EGRRCPA Section 104. Controls include the Black-to-White applicant income ratio and log total application volume. Sample: conventional first-lien home purchase loans with $\\geq$ 5 applications per race group, in counties with both exempt and non-exempt lenders, 2018--2022.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ---------------------------------------------------------------
# Table 3: Mechanism — Separate Black and White denial rates
# ---------------------------------------------------------------
cat("Generating Table 3: Mechanism...\n")

r_black <- extract_row(m_black)
r_white <- extract_row(m_white)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Mechanism: Exempt Lenders' Denial Rates by Race}",
  "\\label{tab:mechanism}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "& Black Denial Rate & White Denial Rate \\\\",
  "& (1) & (2) \\\\",
  "\\midrule",
  sprintf("Exempt & %.4f%s & %.4f%s \\\\", r_black$b, r_black$stars, r_white$b, r_white$stars),
  sprintf("& (%.4f) & (%.4f) \\\\", r_black$s, r_white$s),
  "\\\\",
  "County $\\times$ Year FE & Yes & Yes \\\\",
  "Controls & Yes & Yes \\\\",
  "\\midrule",
  sprintf("N & %s & %s \\\\", format(r_black$n, big.mark = ","), format(r_white$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the county level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. County $\\times$ year fixed effects and controls (income ratio, log volume) included. Sample as in Table~\\ref{tab:main}.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_mechanism.tex"))

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("Generating Table 4: Robustness...\n")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications and Placebo Tests}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "& Coefficient & SE & N & Specification \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Alternative clustering}} \\\\"
)

# State clustering
r_st <- extract_row(m_state_cl)
tab4_lines <- c(tab4_lines,
  sprintf("State-clustered SE & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
          r_st$b, r_st$stars, r_st$s, format(r_st$n, big.mark = ",")))

# Two-way
r_tw <- extract_row(m_twoway)
tab4_lines <- c(tab4_lines,
  sprintf("Two-way clustering & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
          r_tw$b, r_tw$stars, r_tw$s, format(r_tw$n, big.mark = ",")))

tab4_lines <- c(tab4_lines,
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Heterogeneity by lender size}} \\\\"
)

r_sm <- extract_row(m_small)
r_lg <- extract_row(m_large)
tab4_lines <- c(tab4_lines,
  sprintf("Small lenders (Q1--Q2) & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
          r_sm$b, r_sm$stars, r_sm$s, format(r_sm$n, big.mark = ",")),
  sprintf("Large lenders (Q3--Q4) & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
          r_lg$b, r_lg$stars, r_lg$s, format(r_lg$n, big.mark = ",")))

tab4_lines <- c(tab4_lines,
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel C: Placebo and alternative outcomes}} \\\\"
)

# Asian-White placebo
if (!is.null(m_placebo_aw)) {
  r_aw <- extract_row(m_placebo_aw)
  tab4_lines <- c(tab4_lines,
    sprintf("Asian--White gap (placebo) & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
            r_aw$b, r_aw$stars, r_aw$s, format(r_aw$n, big.mark = ",")))
}

# Minority share
r_sh <- extract_row(m_share)
tab4_lines <- c(tab4_lines,
  sprintf("Black application share & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
          r_sh$b, r_sh$stars, r_sh$s, format(r_sh$n, big.mark = ",")))

# Winsorized
r_w <- extract_row(m_wins)
tab4_lines <- c(tab4_lines,
  sprintf("Winsorized gap (1\\%%) & %.4f%s & (%.4f) & %s & County$\\times$Year FE \\\\",
          r_w$b, r_w$stars, r_w$s, format(r_w$n, big.mark = ",")))

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} All specifications include county $\\times$ year fixed effects and controls (income ratio, log volume) unless noted. Standard errors in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Panel A varies the clustering level. Panel B splits the sample by lender-year total application volume quartile. Panel C reports placebo tests (Asian--White gap should not respond if effect is specific to Black-White discrimination) and alternative outcome measures.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))

# ---------------------------------------------------------------
# Table 5: Event Study Coefficients
# ---------------------------------------------------------------
cat("Generating Table 5: Event Study...\n")

ct <- coeftable(m_event)
event_rows <- grep("year_f", rownames(ct))

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Year-by-Year Exempt Lender Effect on Black--White Denial Gap}",
  "\\label{tab:event}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Year & Coefficient & SE & $t$-stat & $p$-value \\\\",
  "\\midrule",
  "2018 (reference) & --- & --- & --- & --- \\\\"
)

for (i in event_rows) {
  yr_label <- gsub("year_f|:exempt", "", rownames(ct)[i])
  yr_label <- gsub("::", " $\\\\times$ ", yr_label)
  tab5_lines <- c(tab5_lines,
    sprintf("%s & %.4f & (%.4f) & %.2f & %.3f \\\\",
            yr_label, ct[i, 1], ct[i, 2], ct[i, 3], ct[i, 4]))
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  sprintf("N & \\multicolumn{4}{c}{%s} \\\\", format(nobs(m_event), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Coefficients from interaction of year dummies with exempt indicator (reference year: 2018). County $\\times$ year FE, income ratio, and log volume controls included. Standard errors clustered at the county level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_event.tex"))

# ---------------------------------------------------------------
# SDE Table (Appendix F1) — MANDATORY
# ---------------------------------------------------------------
cat("Generating SDE Table...\n")

sde_data <- readRDS(file.path(data_dir, "sde_data.rds"))

# SDE computation: β / SD(Y) for binary treatment
sde_gap <- sde_data$beta_gap / sde_data$sd_deny_gap
se_sde_gap <- sde_data$se_gap / sde_data$sd_deny_gap

sde_black <- sde_data$beta_black / sde_data$sd_deny_black
se_sde_black <- sde_data$se_black / sde_data$sd_deny_black

sde_white <- sde_data$beta_white / sde_data$sd_deny_white
se_sde_white <- sde_data$se_white / sde_data$sd_deny_white

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

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does exempting small mortgage lenders from expanded HMDA reporting requirements widen racial disparities in mortgage denial rates? ",
  "\\textbf{Policy mechanism:} EGRRCPA Section 104 (May 2018) exempted depository institutions originating fewer than 500 closed-end mortgages from reporting interest rates, debt-to-income ratios, and loan costs in their HMDA filings, reducing public scrutiny of their lending decisions while leaving core application-level data (race, action taken, loan amount) still reported. ",
  "\\textbf{Outcome definition:} Black--White denial rate gap, computed as the difference between Black and White conventional first-lien home purchase mortgage denial rates at the lender-county-year level. ",
  "\\textbf{Treatment:} Binary indicator for EGRRCPA-exempt lender status, identified via ``Exempt'' markers in total loan cost reporting fields. ",
  "\\textbf{Data:} CFPB HMDA Loan Application Register, 2018--2022, lender-county-year panel with separate denial rates by applicant race. ",
  "\\textbf{Method:} OLS with county $\\times$ year fixed effects, controlling for Black-to-White applicant income ratio and log total application volume; standard errors clustered at county level. ",
  "\\textbf{Sample:} Conventional first-lien home purchase loans at lender-county-years with at least 5 Black and 5 White applications, in counties containing both exempt and non-exempt lenders. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("Black--White denial gap & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          sde_data$beta_gap, sde_data$se_gap, sde_data$sd_deny_gap,
          sde_gap, se_sde_gap, classify(sde_gap)),
  sprintf("Black denial rate & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          sde_data$beta_black, sde_data$se_black, sde_data$sd_deny_black,
          sde_black, se_sde_black, classify(sde_black)),
  sprintf("White denial rate & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          sde_data$beta_white, sde_data$se_white, sde_data$sd_deny_white,
          sde_white, se_sde_white, classify(sde_white)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(sde_tab, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat("Files in tables/:\n")
print(list.files(tables_dir, pattern = "\\.tex$"))
