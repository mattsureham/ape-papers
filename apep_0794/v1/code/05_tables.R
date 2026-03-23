# =============================================================================
# 05_tables.R — Generate all tables
# APEP Paper apep_0794: Testing Without Tests
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results.rds")
rob <- readRDS("../data/robustness_results.rds")
panel <- panel %>% mutate(log_apps = ifelse(applicants_total > 0, log(applicants_total), NA_real_))
treated <- panel %>% filter(test_required_2019 == 1, !is.na(sat_intensity))

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================

make_sum_row <- function(df, var, label) {
  x <- df[[var]]
  x <- x[!is.na(x)]
  sprintf("%s & %.3f & %.3f & %d \\\\", label, mean(x), sd(x), length(x))
}

pre_treat <- panel %>% filter(year <= 2019, test_required_2019 == 1)
pre_ctrl <- panel %>% filter(year <= 2019, test_required_2019 == 0)

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Means (2014--2019)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Test-Required (N=1,084)} & \\multicolumn{3}{c}{Not Required (N=927)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Mean & SD & Obs & Mean & SD & Obs \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Enrollment Composition}} \\\\"
)

vars_a <- list(
  c("share_black", "Black share"),
  c("share_hispanic", "Hispanic share"),
  c("share_white", "White share"),
  c("share_asian", "Asian share"),
  c("share_urm", "URM share"),
  c("eftotlt", "Total enrollment")
)

for (v in vars_a) {
  t_vals <- pre_treat[[v[1]]][!is.na(pre_treat[[v[1]]])]
  c_vals <- pre_ctrl[[v[1]]][!is.na(pre_ctrl[[v[1]]])]
  if (v[1] == "eftotlt") {
    tab1 <- c(tab1, sprintf("%s & %.0f & %.0f & %s & %.0f & %.0f & %s \\\\",
              v[2], mean(t_vals), sd(t_vals), format(length(t_vals), big.mark=","),
              mean(c_vals), sd(c_vals), format(length(c_vals), big.mark=",")))
  } else {
    tab1 <- c(tab1, sprintf("%s & %.3f & %.3f & %s & %.3f & %.3f & %s \\\\",
              v[2], mean(t_vals), sd(t_vals), format(length(t_vals), big.mark=","),
              mean(c_vals), sd(c_vals), format(length(c_vals), big.mark=",")))
  }
}

tab1 <- c(tab1,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Admissions}} \\\\")

vars_b <- list(
  c("admit_rate", "Admission rate"),
  c("yield_rate", "Yield rate"),
  c("applicants_total", "Applications")
)

for (v in vars_b) {
  t_vals <- pre_treat[[v[1]]][!is.na(pre_treat[[v[1]]])]
  c_vals <- pre_ctrl[[v[1]]][!is.na(pre_ctrl[[v[1]]])]
  if (v[1] == "applicants_total") {
    tab1 <- c(tab1, sprintf("%s & %.0f & %.0f & %s & %.0f & %.0f & %s \\\\",
              v[2], mean(t_vals), sd(t_vals), format(length(t_vals), big.mark=","),
              mean(c_vals), sd(c_vals), format(length(c_vals), big.mark=",")))
  } else {
    tab1 <- c(tab1, sprintf("%s & %.3f & %.3f & %s & %.3f & %.3f & %s \\\\",
              v[2], mean(t_vals), sd(t_vals), format(length(t_vals), big.mark=","),
              mean(c_vals), sd(c_vals), format(length(c_vals), big.mark=",")))
  }
}

tab1 <- c(tab1,
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel C: Selectivity (Test-Required Only)}} \\\\")

sat_vals <- pre_treat$sat_composite_25[!is.na(pre_treat$sat_composite_25) & pre_treat$year == 2019]
tab1 <- c(tab1,
  sprintf("SAT composite 25th pctile & %.0f & %.0f & %d & --- & --- & --- \\\\",
          mean(sat_vals), sd(sat_vals), length(sat_vals)),
  sprintf("SAT composite 25th: Q1 & \\multicolumn{2}{c}{$\\leq$ %d} & %d & & & \\\\",
          as.integer(quantile(sat_vals, 0.25)), sum(sat_vals <= quantile(sat_vals, 0.25))),
  sprintf("SAT composite 25th: Q4 & \\multicolumn{2}{c}{$\\geq$ %d} & %d & & & \\\\",
          as.integer(quantile(sat_vals, 0.75)), sum(sat_vals >= quantile(sat_vals, 0.75)))
)

tab1 <- c(tab1,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from IPEDS 2014--2023. Test-required = institutions requiring SAT/ACT for admission in 2019 (IPEDS admcon7=1). Not required includes test-optional (admcon7=3,5) and test-recommended (admcon7=2). URM = Black + Hispanic + American Indian/Alaska Native + Native Hawaiian/Pacific Islander. SAT composite = EBRW 25th + Math 25th percentile.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# =============================================================================
# Table 2: Main DiD Results
# =============================================================================

tab2_models <- list(
  results$binary_did$black,
  results$binary_did$hispanic,
  results$binary_did$urm,
  results$admissions$apps,
  results$admissions$admit,
  results$admissions$yield
)

# Custom table
tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Test-Optional Admissions and Enrollment Composition: Binary DiD}",
  "\\label{tab:main_binary}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & Black & Hispanic & URM & Log & Admission & Yield \\\\",
  " & share & share & share & apps & rate & rate \\\\",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline"
)

# Extract coefficients
coefs <- sapply(tab2_models, function(m) {
  cf <- coef(m)
  se <- sqrt(diag(vcov(m)))
  pv <- summary(m)$coeftable[, 4]
  stars <- ifelse(pv < 0.01, "^{***}", ifelse(pv < 0.05, "^{**}", ifelse(pv < 0.1, "^{*}", "")))
  list(coef = cf[1], se = se[1], stars = stars[1])
})

coef_row <- paste0("Required $\\times$ Post")
for (i in 1:6) {
  coef_row <- paste0(coef_row, " & $", sprintf("%.4f", coefs[1, ][[i]]), coefs[3, ][[i]], "$")
}
coef_row <- paste0(coef_row, " \\\\")

se_row <- ""
for (i in 1:6) {
  se_row <- paste0(se_row, " & (", sprintf("%.4f", coefs[2, ][[i]]), ")")
}
se_row <- paste0(se_row, " \\\\")

tab2 <- c(tab2, coef_row, se_row, "\\hline")

# Add N and R2
n_row <- "Observations"
r2_row <- "Within $R^2$"
for (i in 1:6) {
  n_row <- paste0(n_row, " & ", format(tab2_models[[i]]$nobs, big.mark = ","))
  r2_row <- paste0(r2_row, " & ", sprintf("%.4f", fitstat(tab2_models[[i]], "wr2")[[1]]))
}
n_row <- paste0(n_row, " \\\\")
r2_row <- paste0(r2_row, " \\\\")

tab2 <- c(tab2, n_row, r2_row,
  "Inst. FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Clustering & \\multicolumn{6}{c}{Institution} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate regression of the outcome on the interaction of test-required status (2019) with a post-2020 indicator. All specifications include institution and year fixed effects. Standard errors clustered at the institution level in parentheses. $^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2, "../tables/tab2_binary_did.tex")
cat("Table 2 written.\n")

# =============================================================================
# Table 3: Intensity DiD (within treated)
# =============================================================================

int_models <- list(
  results$intensity_did$black,
  results$intensity_did$hispanic,
  results$intensity_did$urm
)

# Also add state-year FE versions
int_models_rob <- list(
  rob$state_year_fe$black,
  rob$state_year_fe$hispanic,
  rob$weighted$black
)

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Selectivity Intensity and Black Enrollment: Within Test-Required Schools}",
  "\\label{tab:intensity}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Baseline} & \\multicolumn{3}{c}{Robustness} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}",
  " & Black & Hispanic & URM & State$\\times$Year & State$\\times$Year & Weighted \\\\",
  " & share & share & share & (Black) & (Hispanic) & (Black) \\\\",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline"
)

all_m <- c(int_models, int_models_rob)

coef_row3 <- "SAT intensity $\\times$ Post"
se_row3 <- ""
for (i in seq_along(all_m)) {
  cf <- coef(all_m[[i]])
  se <- sqrt(diag(vcov(all_m[[i]])))
  pv <- summary(all_m[[i]])$coeftable[, 4]
  stars <- ifelse(pv[1] < 0.01, "^{***}", ifelse(pv[1] < 0.05, "^{**}", ifelse(pv[1] < 0.1, "^{*}", "")))
  coef_row3 <- paste0(coef_row3, " & $", sprintf("%.4f", cf[1]), stars, "$")
  se_row3 <- paste0(se_row3, " & (", sprintf("%.4f", se[1]), ")")
}
coef_row3 <- paste0(coef_row3, " \\\\")
se_row3 <- paste0(se_row3, " \\\\")

n_row3 <- "Observations"
for (i in seq_along(all_m)) {
  n_row3 <- paste0(n_row3, " & ", format(all_m[[i]]$nobs, big.mark = ","))
}
n_row3 <- paste0(n_row3, " \\\\")

tab3 <- c(tab3, coef_row3, se_row3, "\\hline", n_row3,
  "Inst. FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Year FE & Yes & Yes & Yes & --- & --- & Yes \\\\",
  "State$\\times$Year FE & --- & --- & --- & Yes & Yes & --- \\\\",
  "Enrl. weights & --- & --- & --- & --- & --- & Yes \\\\",
  "Clustering & \\multicolumn{6}{c}{Institution} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sample restricted to institutions that required SAT/ACT in 2019 and reported SAT scores (N=1,023). SAT intensity = standardized pre-COVID SAT 25th percentile composite score (mean 0, SD 1 among treated). Columns 4--5 replace year FE with state-by-year FE. Column 6 weights by 2019 enrollment. $^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3, "../tables/tab3_intensity.tex")
cat("Table 3 written.\n")

# =============================================================================
# Table 4: Placebo and Heterogeneity
# =============================================================================

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Placebo, Heterogeneity, and Triple-Difference}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Placebo & \\multicolumn{3}{c}{SAT Quartile} & Triple \\\\",
  " & (Controls) & Q2 & Q3 & Q4 & Diff \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Dependent variable: Black enrollment share}} \\\\"
)

# Placebo
plac <- rob$state_year_fe  # Use the placebo from file
# Actually, load placebo separately
panel_ctrl <- panel %>% filter(test_required_2019 == 0) %>%
  filter(!is.na(sat_composite_25_adm)) %>%
  group_by(unitid) %>%
  mutate(sat_intensity_ctrl = (sat_composite_25_adm -
           mean(sat_composite_25_adm[year == 2019], na.rm = TRUE)) /
           sd(sat_composite_25_adm, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(!is.na(sat_intensity_ctrl), is.finite(sat_intensity_ctrl)) %>%
  mutate(post = as.integer(year >= 2020))

plac_m <- feols(share_black ~ sat_intensity_ctrl:post | unitid + year,
                data = panel_ctrl, cluster = ~unitid)

# SAT quartile
q_m <- feols(share_black ~ i(sat_quartile, post, ref = 1) | unitid + year,
             data = treated, cluster = ~unitid)

# Triple diff
panel_sat <- panel %>%
  filter(!is.na(sat_composite_25_adm)) %>%
  group_by(unitid) %>%
  mutate(sat_2019 = first(sat_composite_25_adm[year == 2019])) %>%
  ungroup() %>%
  filter(!is.na(sat_2019)) %>%
  mutate(sat_std = (sat_2019 - mean(sat_2019[year == 2019])) / sd(sat_2019[year == 2019]))

ddd_m <- feols(share_black ~ test_required_2019:sat_std:post +
                 test_required_2019:post + sat_std:post | unitid + year,
               data = panel_sat, cluster = ~unitid)

# Build row
cf_plac <- coef(plac_m)[1]
se_plac <- sqrt(diag(vcov(plac_m)))[1]
pv_plac <- summary(plac_m)$coeftable[1, 4]
st_plac <- ifelse(pv_plac < 0.01, "^{***}", ifelse(pv_plac < 0.05, "^{**}", ifelse(pv_plac < 0.1, "^{*}", "")))

q_cf <- coef(q_m)
q_se <- sqrt(diag(vcov(q_m)))
q_pv <- summary(q_m)$coeftable[, 4]

# Triple diff - the interaction term
ddd_cf <- coef(ddd_m)
ddd_se <- sqrt(diag(vcov(ddd_m)))
ddd_pv <- summary(ddd_m)$coeftable[, 4]
# The triple interaction is the third coefficient
ddd_idx <- 3

ddd_stars <- ifelse(ddd_pv[ddd_idx] < 0.01, "^{***}", ifelse(ddd_pv[ddd_idx] < 0.05, "^{**}",
                    ifelse(ddd_pv[ddd_idx] < 0.1, "^{*}", "")))

row1 <- sprintf("Intensity $\\times$ Post & $%.4f%s$ & & & & \\\\",
                cf_plac, st_plac)
se1 <- sprintf(" & (%.4f) & & & & \\\\", se_plac)

# Quartile rows
q_stars <- ifelse(q_pv < 0.01, "^{***}", ifelse(q_pv < 0.05, "^{**}", ifelse(q_pv < 0.1, "^{*}", "")))

row_q <- sprintf("Q$k$ $\\times$ Post & & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & \\\\",
                 q_cf[1], q_stars[1], q_cf[2], q_stars[2], q_cf[3], q_stars[3])
se_q <- sprintf(" & & (%.4f) & (%.4f) & (%.4f) & \\\\", q_se[1], q_se[2], q_se[3])

row_ddd <- sprintf("Req $\\times$ Intensity $\\times$ Post & & & & & $%.4f%s$ \\\\",
                   ddd_cf[ddd_idx], ddd_stars)
se_ddd <- sprintf(" & & & & & (%.4f) \\\\", ddd_se[ddd_idx])

tab4 <- c(tab4, row1, se1, row_q, se_q, row_ddd, se_ddd, "\\hline",
  sprintf("Observations & %s & \\multicolumn{3}{c}{%s} & %s \\\\",
          format(plac_m$nobs, big.mark = ","),
          format(q_m$nobs, big.mark = ","),
          format(ddd_m$nobs, big.mark = ",")),
  "Sample & Controls & \\multicolumn{3}{c}{Treated} & Both \\\\",
  "Inst. FE & \\multicolumn{5}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{5}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column 1: placebo test among already-test-optional institutions (SAT intensity should not predict Black share changes). Columns 2--4: SAT quartile dummies (reference: Q1, least selective) interacted with post among treated schools. Column 5: triple-difference using full sample. $^{*} p<0.10$, $^{**} p<0.05$, $^{***} p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# =============================================================================

# Main outcomes from intensity DiD
sde_outcomes <- data.frame(
  outcome = c("Black enrollment share", "Hispanic enrollment share",
              "URM enrollment share", "Log applications"),
  stringsAsFactors = FALSE
)

# Get coefficients from intensity models + binary applications model
models_sde <- list(
  results$intensity_did$black,
  results$intensity_did$hispanic,
  results$intensity_did$urm,
  results$admissions$apps
)

# Compute pre-treatment SD of Y for each outcome
sd_black_pre <- sd(treated$share_black[treated$year <= 2019], na.rm = TRUE)
sd_hisp_pre <- sd(treated$share_hispanic[treated$year <= 2019], na.rm = TRUE)
sd_urm_pre <- sd(treated$share_urm[treated$year <= 2019], na.rm = TRUE)
sd_logapps_pre <- sd(panel$log_apps[panel$year <= 2019], na.rm = TRUE)

sd_y <- c(sd_black_pre, sd_hisp_pre, sd_urm_pre, sd_logapps_pre)

sde_rows <- list()
for (i in 1:4) {
  cf <- coef(models_sde[[i]])[1]
  se <- sqrt(diag(vcov(models_sde[[i]])))[1]
  sde <- cf / sd_y[i]
  sde_se <- se / sd_y[i]

  class_label <- if (abs(sde) > 0.15) {
    if (sde > 0) "Large positive" else "Large negative"
  } else if (abs(sde) > 0.05) {
    if (sde > 0) "Moderate positive" else "Moderate negative"
  } else if (abs(sde) > 0.005) {
    if (sde > 0) "Small positive" else "Small negative"
  } else {
    "Null"
  }

  sde_rows[[i]] <- sprintf("%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
                           sde_outcomes$outcome[i], cf, se, sd_y[i], sde, sde_se, class_label)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does removing SAT/ACT admissions requirements change the racial composition of college enrollment at test-requiring institutions? ",
  "\\textbf{Policy mechanism:} COVID-19 forced virtually all 1,084 US institutions that required SAT/ACT in 2019 to drop testing requirements by 2020, eliminating a screening barrier that disproportionately affected Black and Hispanic applicants due to well-documented standardized test score gaps. ",
  "\\textbf{Outcome definition:} Undergraduate enrollment shares by race (Black, Hispanic, URM) from IPEDS Fall Enrollment survey; log total applications from IPEDS Admissions survey. ",
  "\\textbf{Treatment:} Continuous --- standardized pre-COVID SAT 25th percentile composite score (mean 0, SD 1) measuring institutional selectivity and test reliance intensity. ",
  "\\textbf{Data:} IPEDS 2014--2023, institution-year panel, 1,023 test-required institutions with SAT scores, 10,115 observations. ",
  "\\textbf{Method:} Two-way fixed effects (institution + year), standard errors clustered at institution level. ",
  "\\textbf{Sample:} Four-year degree-granting institutions that required SAT/ACT for admission in fall 2019 (IPEDS admcon7=1), restricted to those reporting SAT 25th percentile scores. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) = 1 (standardized treatment) so SDE $= \\hat{\\beta} / \\text{SD}(Y)$, with SD($Y$) computed from the pre-treatment distribution (2014--2019). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  unlist(sde_rows),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables complete.\n")
