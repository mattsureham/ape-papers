# =============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE appendix
# =============================================================================

source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")
models   <- readRDS("../data/models.rds")

tables_dir <- "../tables"

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------
pre_data <- analysis %>% filter(year <= 2016)

treated  <- pre_data %>% filter(has_closure == 1)
control  <- pre_data %>% filter(has_closure == 0)

vars <- c("cc_total", "cc_black", "cc_hispanic", "cc_white",
          "closed_total", "n_closed_inst")
labels <- c("CC Total Enrollment", "CC Black Enrollment",
            "CC Hispanic Enrollment", "CC White Enrollment",
            "Displaced FP Enrollment", "Closed FP Institutions")

# Build summary table
sum_rows <- lapply(seq_along(vars), function(i) {
  v <- vars[i]
  tibble(
    Variable = labels[i],
    `Treated Mean` = sprintf("%.1f", mean(treated[[v]], na.rm = TRUE)),
    `Treated SD`   = sprintf("%.1f", sd(treated[[v]], na.rm = TRUE)),
    `Control Mean`  = sprintf("%.1f", mean(control[[v]], na.rm = TRUE)),
    `Control SD`    = sprintf("%.1f", sd(control[[v]], na.rm = TRUE))
  )
})
sum_df <- bind_rows(sum_rows)

n_treated_counties <- n_distinct(treated$county_fips)
n_control_counties <- n_distinct(control$county_fips)

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-Period (2010--2016)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{l cc cc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Control} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n"
)

for (i in 1:nrow(sum_df)) {
  tab1_tex <- paste0(tab1_tex,
    sum_df$Variable[i], " & ",
    sum_df$`Treated Mean`[i], " & ", sum_df$`Treated SD`[i], " & ",
    sum_df$`Control Mean`[i], " & ", sum_df$`Control SD`[i], " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "Counties & \\multicolumn{2}{c}{", n_treated_counties, "} & \\multicolumn{2}{c}{", n_control_counties, "} \\\\\n",
  "County-years & \\multicolumn{2}{c}{", nrow(treated), "} & \\multicolumn{2}{c}{", nrow(control), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Treated counties contain at least one for-profit institution that closed between 2015 and 2018. ",
  "Control counties have community colleges but no for-profit closures. ",
  "CC enrollment is total undergraduate enrollment at public 2-year institutions. ",
  "Displaced FP enrollment is total 2015 enrollment at for-profit institutions that closed by 2018. ",
  "Source: IPEDS.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ---------------------------------------------------------------------------
# Table 2: Main Results — Continuous Treatment DiD
# ---------------------------------------------------------------------------
tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{For-Profit Closures and Community College Enrollment}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{l cccc}\n",
  "\\toprule\n",
  " & Total & Black & Hispanic & White \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\midrule\n"
)

# Extract coefficients
get_coef_row <- function(model, varname, label) {
  b <- coef(model)[varname]
  se_val <- sqrt(vcov(model)[varname, varname])
  pval <- 2 * pnorm(-abs(b / se_val))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  list(b = b, se = se_val, stars = stars)
}

m_list <- list(models$m_total, models$m_black, models$m_hispanic, models$m_white)
coef_name <- "log_displaced:post"

bs <- sapply(m_list, function(m) {
  r <- get_coef_row(m, coef_name, "")
  sprintf("%.4f%s", r$b, r$stars)
})
ses <- sapply(m_list, function(m) {
  r <- get_coef_row(m, coef_name, "")
  sprintf("(%.4f)", r$se)
})

tab2_tex <- paste0(tab2_tex,
  "$\\ln(\\text{Displaced}) \\times \\text{Post}$ & ",
  paste(bs, collapse = " & "), " \\\\\n",
  " & ", paste(ses, collapse = " & "), " \\\\\n"
)

# Add N, R2, FE
ns <- sapply(m_list, function(m) format(m$nobs, big.mark = ","))
r2s <- sapply(m_list, function(m) sprintf("%.3f", fitstat(m, "r2")$r2))

tab2_tex <- paste0(tab2_tex,
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", paste(ns, collapse = " & "), " \\\\\n",
  "$R^2$ & ", paste(r2s, collapse = " & "), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports a separate DiD regression. ",
  "The dependent variable is log community college enrollment by race. ",
  "$\\ln(\\text{Displaced})$ = $\\ln(1 + \\text{2015 enrollment at for-profit institutions that closed by 2018})$ in each county. ",
  "Post = 1 for academic years 2017--2022. ",
  "Standard errors clustered at the state level in parentheses. ",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Table 2 written.\n")

# ---------------------------------------------------------------------------
# Table 3: Robustness — Binary treatment, pre-COVID, levels
# ---------------------------------------------------------------------------
tab3_models <- list(
  models$m_bin_total, models$m_bin_black,
  models$m_precov, models$m_precov_black,
  models$m_levels, models$m_levels_black
)

coef_names <- c(rep("has_closure:post", 2),
                rep("log_displaced:post", 2),
                rep("log_displaced:post", 2))

headers <- c("Total", "Black", "Total", "Black", "Total", "Black")

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{l cc cc cc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Binary Treatment} & \\multicolumn{2}{c}{Pre-COVID} & \\multicolumn{2}{c}{Levels} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
  " & ", paste(headers, collapse = " & "), " \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\midrule\n"
)

bs3 <- character(6)
ses3 <- character(6)
for (i in 1:6) {
  r <- get_coef_row(tab3_models[[i]], coef_names[i], "")
  bs3[i] <- sprintf("%.4f%s", r$b, r$stars)
  ses3[i] <- sprintf("(%.4f)", r$se)
}

treat_label <- ifelse(1:6 <= 2, "$\\text{Closure} \\times \\text{Post}$",
                      "$\\ln(\\text{Disp.}) \\times \\text{Post}$")

tab3_tex <- paste0(tab3_tex,
  "Treatment $\\times$ Post & ",
  paste(bs3, collapse = " & "), " \\\\\n",
  " & ", paste(ses3, collapse = " & "), " \\\\\n",
  "\\midrule\n",
  "County FE & ", paste(rep("Yes", 6), collapse = " & "), " \\\\\n",
  "Year FE & ", paste(rep("Yes", 6), collapse = " & "), " \\\\\n",
  "Sample & Full & Full & $\\leq$2019 & $\\leq$2019 & Full & Full \\\\\n",
  "Dep. var. & Log & Log & Log & Log & Level & Level \\\\\n",
  "Observations & ",
  paste(sapply(tab3_models, function(m) format(m$nobs, big.mark = ",")), collapse = " & "),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Columns (1)--(2) use a binary treatment indicator (any closure in county). ",
  "Columns (3)--(4) restrict the sample to 2010--2019 (pre-COVID). ",
  "Columns (5)--(6) use enrollment levels rather than logs. ",
  "Standard errors clustered at the state level in parentheses. ",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(tables_dir, "tab3_robust.tex"))
cat("Table 3 written.\n")

# ---------------------------------------------------------------------------
# Table 4: Triple Difference + Placebo
# ---------------------------------------------------------------------------
m_ddd <- models$m_ddd
m_placebo <- models$m_placebo

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Triple Difference and Placebo Test}\n",
  "\\label{tab:ddd}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{l cc}\n",
  "\\toprule\n",
  " & DDD & Placebo \\\\\n",
  " & (1) & (2) \\\\\n",
  "\\midrule\n"
)

# DDD coefficients
ddd_coefs <- coef(m_ddd)
ddd_ses <- sqrt(diag(vcov(m_ddd)))

for (nm in names(ddd_coefs)) {
  pval <- 2 * pnorm(-abs(ddd_coefs[nm] / ddd_ses[nm]))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  clean_name <- gsub(":", " $\\\\times$ ", nm)
  clean_name <- gsub("log_displaced", "$\\\\ln(\\\\text{Disp.})$", clean_name)
  tab4_tex <- paste0(tab4_tex,
    clean_name, " & ",
    sprintf("%.4f%s", ddd_coefs[nm], stars), " & \\\\\n",
    " & (", sprintf("%.4f", ddd_ses[nm]), ") & \\\\\n"
  )
}

# Placebo
plac_b <- coef(m_placebo)["log_displaced:post"]
plac_se <- sqrt(vcov(m_placebo)["log_displaced:post", "log_displaced:post"])
plac_pval <- 2 * pnorm(-abs(plac_b / plac_se))
plac_stars <- ifelse(plac_pval < 0.01, "***", ifelse(plac_pval < 0.05, "**", ifelse(plac_pval < 0.10, "*", "")))

tab4_tex <- paste0(tab4_tex,
  "\\midrule\n",
  "$\\ln(\\text{Disp.}) \\times \\text{Post}$ & & ",
  sprintf("%.4f%s", plac_b, plac_stars), " \\\\\n",
  " & & (", sprintf("%.4f", plac_se), ") \\\\\n",
  "\\midrule\n",
  "Dep. var. & Log CC Enroll & Log 4-Yr Pub \\\\\n",
  "Panel & Race $\\times$ County & County \\\\\n",
  "FE & County$\\times$Race, Year$\\times$Race & County, Year \\\\\n",
  "Observations & ", format(m_ddd$nobs, big.mark = ","),
  " & ", format(m_placebo$nobs, big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Column (1) estimates a triple-difference: displacement $\\times$ post $\\times$ minority (Black/Hispanic vs.~White). ",
  "Column (2) tests the placebo: 4-year public university enrollment should not respond to for-profit closures. ",
  "Standard errors clustered at the state level. ",
  "\\sym{*} $p<0.10$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_ddd_placebo.tex"))
cat("Table 4 written.\n")

# ---------------------------------------------------------------------------
# SDE Table (Appendix — tabF1_sde.tex)
# ---------------------------------------------------------------------------
# Compute SDE for main outcomes
compute_sde <- function(model, outcome_var, coef_name = "log_displaced:post") {
  beta <- coef(model)[coef_name]
  se_beta <- sqrt(vcov(model)[coef_name, coef_name])
  # SD(Y) = pre-treatment SD of the dependent variable
  pre_data_local <- analysis %>% filter(year <= 2016)
  sd_y <- sd(pre_data_local[[outcome_var]], na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(beta = beta, se = se_beta, sd_y = sd_y, sde = sde, se_sde = se_sde, bucket = bucket)
}

sde_total <- compute_sde(models$m_total, "log_cc_total")
sde_black <- compute_sde(models$m_black, "log_cc_black")
sde_hispanic <- compute_sde(models$m_hispanic, "log_cc_hispanic")
sde_white <- compute_sde(models$m_white, "log_cc_white")

# Panel B: heterogeneous — high vs low exposure counties
# Split at median displaced enrollment among treated counties
median_disp <- median(analysis$closed_total[analysis$closed_total > 0 & analysis$year == 2015])

analysis_high <- analysis %>% filter(closed_total >= median_disp | closed_total == 0)
analysis_low  <- analysis %>% filter(closed_total < median_disp | closed_total == 0)

m_high_sde <- feols(log_cc_total ~ log_displaced:post | county_fips + year,
                    data = analysis_high, cluster = ~state_fips)
m_low_sde  <- feols(log_cc_total ~ log_displaced:post | county_fips + year,
                    data = analysis_low, cluster = ~state_fips)

sde_high <- compute_sde(m_high_sde, "log_cc_total")
sde_low  <- compute_sde(m_low_sde, "log_cc_total")

# Build SDE table
sde_rows_a <- list(
  list("CC Total Enrollment",    sde_total),
  list("CC Black Enrollment",    sde_black),
  list("CC Hispanic Enrollment", sde_hispanic),
  list("CC White Enrollment",    sde_white)
)

sde_rows_b <- list(
  list("CC Total (High Exposure)", sde_high),
  list("CC Total (Low Exposure)",  sde_low)
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{l cccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (row in sde_rows_a) {
  s <- row[[2]]
  sde_tex <- paste0(sde_tex,
    row[[1]], " & ",
    sprintf("%.4f", s$beta), " & ",
    sprintf("%.4f", s$se), " & ",
    sprintf("%.3f", s$sd_y), " & ",
    sprintf("%.4f", s$sde), " & ",
    sprintf("%.4f", s$se_sde), " & ",
    s$bucket, " \\\\\n"
  )
}

sde_tex <- paste0(sde_tex,
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by displacement intensity)}} \\\\\n"
)

for (row in sde_rows_b) {
  s <- row[[2]]
  sde_tex <- paste0(sde_tex,
    row[[1]], " & ",
    sprintf("%.4f", s$beta), " & ",
    sprintf("%.4f", s$se), " & ",
    sprintf("%.3f", s$sd_y), " & ",
    sprintf("%.4f", s$sde), " & ",
    sprintf("%.4f", s$se_sde), " & ",
    s$bucket, " \\\\\n"
  )
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the mass closure of for-profit colleges following the 2016 ACICS accreditation revocation increase enrollment at nearby community colleges, and does absorption differ by race? ",
  "\\textbf{Policy mechanism:} The Department of Education revoked recognition of ACICS, the largest for-profit accreditor, in September 2016, causing approximately 247 institutions enrolling 600,000 students to lose Title IV federal financial aid eligibility and close within 18 months, displacing students who must find alternative educational institutions or exit higher education entirely. ",
  "\\textbf{Outcome definition:} Log undergraduate enrollment at public 2-year institutions (community colleges) aggregated to the county-year level, from IPEDS enrollment tables. ",
  "\\textbf{Treatment:} Continuous: log(1 + total 2015 enrollment at for-profit institutions in the county that closed by 2018). ",
  "\\textbf{Data:} IPEDS institution-year panel, 2010--2022, aggregated to county-year level; approximately 1,200 counties with community colleges over 13 years. ",
  "\\textbf{Method:} Two-way fixed effects DiD with county and year fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with at least one public 2-year institution; treatment counties contain at least one for-profit institution that closed between 2015 and 2018. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table written.\n")

cat("\nAll tables generated.\n")
