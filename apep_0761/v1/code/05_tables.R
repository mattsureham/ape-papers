## 05_tables.R — Generate all tables (including SDE)
## apep_0761: Post-Dobbs Healthcare Labor Reallocation

source("00_packages.R")

panel <- readRDS("../data/panel.rds") %>%
  mutate(post = as.integer(post_dobbs))
results <- readRDS("../data/results.rds")
rob_results <- readRDS("../data/rob_results.rds")

# ── Helper functions ──
get_treat_coef <- function(fit) {
  cnames <- names(coef(fit))
  idx <- grep("1:treated|treated:1", cnames)
  if (length(idx) == 0) idx <- grep("treated", cnames)
  if (length(idx) == 0) stop("Cannot find treatment coefficient in: ", paste(cnames, collapse = ", "))
  idx <- idx[1]
  list(b = coef(fit)[idx], se = sqrt(diag(vcov(fit)))[idx])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

pval <- function(b, se) 2 * pnorm(-abs(b / se))

fmt_coef <- function(b, se) {
  p <- pval(b, se)
  paste0(sprintf("%.3f", b), stars(p))
}

fmt_se <- function(se) paste0("(", sprintf("%.3f", se), ")")

# ══════════════════════════════════════════════════════════════════
# Table 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════

fp_data <- panel %>% filter(industry == "62141")

summ <- fp_data %>%
  filter(!post_dobbs) %>%
  group_by(group) %>%
  summarise(
    `Mean Emp` = sprintf("%.1f", mean(Emp, na.rm = TRUE)),
    `SD Emp` = sprintf("%.1f", sd(Emp, na.rm = TRUE)),
    `Mean Earn` = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    `SD Earn` = sprintf("%.0f", sd(EarnS, na.rm = TRUE)),
    N = as.character(n()),
    States = as.character(n_distinct(state_fips)),
    .groups = "drop"
  )

summ_all <- fp_data %>%
  summarise(
    group = "Full Sample",
    `Mean Emp` = sprintf("%.1f", mean(Emp, na.rm = TRUE)),
    `SD Emp` = sprintf("%.1f", sd(Emp, na.rm = TRUE)),
    `Mean Earn` = sprintf("%.0f", mean(EarnS, na.rm = TRUE)),
    `SD Earn` = sprintf("%.0f", sd(EarnS, na.rm = TRUE)),
    N = as.character(n()),
    States = as.character(n_distinct(state_fips))
  )

summ_final <- bind_rows(summ, summ_all)

tab1 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics: Family Planning Centers (NAICS 62141)}\n",
  "\\label{tab:summary}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n\\toprule\n",
  " & Mean Emp & SD Emp & Mean Earn (\\$) & SD Earn & N & States \\\\\n\\midrule\n"
)

for (i in seq_len(nrow(summ_final))) {
  r <- summ_final[i, ]
  tab1 <- paste0(tab1, r$group, " & ", r$`Mean Emp`, " & ", r$`SD Emp`, " & ",
                 r$`Mean Earn`, " & ", r$`SD Earn`, " & ", r$N, " & ", r$States, " \\\\\n")
}

tab1 <- paste0(tab1,
  "\\bottomrule\n\\end{tabular}\n\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Pre-Dobbs period (2015Q1--2022Q2). Employment is beginning-of-quarter ",
  "count from Census QWI. Earnings are average monthly earnings. Ban states: AL, AR, ID, KY, LA, MS, MO, ",
  "ND, OK, SD, TN, TX, WV, WY (14 states with trigger or near-immediate bans). ",
  "Receiving states: IL, CO, KS, NM, NC, VA, MN, MT, NE (border non-ban states absorbing cross-state demand). ",
  "States with partial or contested bans (GA, IN, SC, OH) assigned to control group.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ══════════════════════════════════════════════════════════════════
# Table 2: Main Results
# ══════════════════════════════════════════════════════════════════

tc_ban <- get_treat_coef(results$twfe_ban)
tc_recv <- get_treat_coef(results$twfe_recv)
tc_phys <- get_treat_coef(results$twfe_phys)
tc_plac <- get_treat_coef(results$twfe_placebo)

n_fp_ban <- nobs(results$twfe_ban)
n_fp_recv <- nobs(results$twfe_recv)
n_phys <- nobs(results$twfe_phys)
n_dental <- nobs(results$twfe_placebo)

nc_ban <- n_distinct(panel$state_fips[panel$industry == "62141" & panel$group %in% c("Ban", "Control")])
nc_recv <- n_distinct(panel$state_fips[panel$industry == "62141" & panel$group %in% c("Receiving", "Control")])

tab2 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Effect of Abortion Bans on Healthcare Employment}\n",
  "\\label{tab:main}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & \\multicolumn{2}{c}{Family Planning (62141)} & Physicians & Dental \\\\\n",
  " & Ban States & Receiving & Ban States & Ban States \\\\\n",
  "\\midrule\n",
  "Ban/Recv $\\times$ Post & ",
    fmt_coef(tc_ban$b, tc_ban$se), " & ",
    fmt_coef(tc_recv$b, tc_recv$se), " & ",
    fmt_coef(tc_phys$b, tc_phys$se), " & ",
    fmt_coef(tc_plac$b, tc_plac$se), " \\\\\n",
  " & ", fmt_se(tc_ban$se), " & ",
    fmt_se(tc_recv$se), " & ",
    fmt_se(tc_phys$se), " & ",
    fmt_se(tc_plac$se), " \\\\\n",
  "\\midrule\n",
  "State FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "N & ", format(n_fp_ban, big.mark = ","), " & ",
    format(n_fp_recv, big.mark = ","), " & ",
    format(n_phys, big.mark = ","), " & ",
    format(n_dental, big.mark = ","), " \\\\\n",
  "Clusters & ", nc_ban, " & ", nc_recv, " & ", nc_ban, " & ", nc_ban, " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(employment $+$ 1). Columns (1)--(2) show effects on ",
  "family planning centers (NAICS 62141). Column (3) shows effects on physician offices (NAICS 6211). ",
  "Column (4) is the placebo: dental and optometry offices (NAICS 6213), which have no reproductive health ",
  "mechanism. Post = 2022Q3 onwards. Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ══════════════════════════════════════════════════════════════════
# Table 3: Triple-Difference Results
# ══════════════════════════════════════════════════════════════════

ddd_coefs <- coef(results$ddd_ban)
ddd_ses <- sqrt(diag(vcov(results$ddd_ban)))
ddd_term <- grep("treated:repro_health:post", names(ddd_coefs), value = TRUE)[1]

ddd_recv_coefs <- coef(results$ddd_recv)
ddd_recv_ses <- sqrt(diag(vcov(results$ddd_recv)))

n_ddd_ban <- nobs(results$ddd_ban)
n_ddd_recv <- nobs(results$ddd_recv)

tab3 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Triple-Difference: Ban/Receiving $\\times$ Family Planning $\\times$ Post-Dobbs}\n",
  "\\label{tab:ddd}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & Ban States & Receiving States \\\\\n",
  "\\midrule\n",
  "Ban/Recv $\\times$ FP $\\times$ Post & ",
    fmt_coef(ddd_coefs[ddd_term], ddd_ses[ddd_term]), " & ",
    fmt_coef(ddd_recv_coefs[ddd_term], ddd_recv_ses[ddd_term]), " \\\\\n",
  " & ", fmt_se(ddd_ses[ddd_term]), " & ",
    fmt_se(ddd_recv_ses[ddd_term]), " \\\\\n",
  "\\midrule\n",
  "State FE & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes \\\\\n",
  "Industry FE & Yes & Yes \\\\\n",
  "N & ", format(n_ddd_ban, big.mark = ","), " & ",
    format(n_ddd_recv, big.mark = ","), " \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log(employment $+$ 1). Triple-difference compares ",
  "family planning (NAICS 62141) to dental/optometry (NAICS 6213, placebo) in ban/receiving states ",
  "vs.\\ control states, before and after Dobbs (2022Q3). Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_ddd.tex")
cat("Table 3 written.\n")

# ══════════════════════════════════════════════════════════════════
# Table 4: Robustness
# ══════════════════════════════════════════════════════════════════

specs <- list(
  list(name = "Baseline (log)", model = results$twfe_ban),
  list(name = "Levels", model = rob_results$levels_ban),
  list(name = "Strict controls", model = rob_results$strict_ban),
  list(name = "Outpatient (6214)", model = rob_results$twfe_outpat),
  list(name = "Other Ambulatory (6219)", model = rob_results$twfe_amb)
)

tab4_rows <- ""
for (spec in specs) {
  tc <- get_treat_coef(spec$model)
  n_obs <- nobs(spec$model)
  tab4_rows <- paste0(tab4_rows,
    spec$name, " & ", fmt_coef(tc$b, tc$se), " & ", fmt_se(tc$se), " & ",
    format(n_obs, big.mark = ","), " \\\\\n")
}

tab4 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Robustness: Alternative Specifications (Ban States)}\n",
  "\\label{tab:robustness}\n\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n\\toprule\n",
  "Specification & Estimate & SE & N \\\\\n\\midrule\n",
  tab4_rows,
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n\\small\n",
  "\\item \\textit{Notes:} All specifications include state and quarter fixed effects with state-clustered SEs. ",
  "Baseline uses log(Emp $+$ 1) for family planning (62141) in ban vs.\\ control states. ",
  "Strict controls exclude GA, IN, SC, OH. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ══════════════════════════════════════════════════════════════════
# SDE Table (MANDATORY — Appendix F1)
# ══════════════════════════════════════════════════════════════════

classify_sde <- function(s) {
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

# Pre-treatment SDs
sd_fp_ban <- sd(panel$log_emp[panel$industry == "62141" & panel$group %in% c("Ban", "Control") & !panel$post_dobbs], na.rm = TRUE)
sd_fp_recv <- sd(panel$log_emp[panel$industry == "62141" & panel$group %in% c("Receiving", "Control") & !panel$post_dobbs], na.rm = TRUE)
sd_phys <- sd(panel$log_emp[panel$industry == "6211" & panel$group %in% c("Ban", "Control") & !panel$post_dobbs], na.rm = TRUE)
sd_ddd <- sd(panel$log_emp[panel$industry %in% c("62141", "6213") & panel$group %in% c("Ban", "Control") & !panel$post_dobbs], na.rm = TRUE)

sde_rows <- tibble(
  Outcome = c("FP Employment (Ban)", "FP Employment (Receiving)",
              "Physician Employment (Ban)", "FP Employment (DDD, Ban)"),
  beta = c(tc_ban$b, tc_recv$b, tc_phys$b, ddd_coefs[ddd_term]),
  se = c(tc_ban$se, tc_recv$se, tc_phys$se, ddd_ses[ddd_term]),
  sd_y = c(sd_fp_ban, sd_fp_recv, sd_phys, sd_ddd),
  sde = c(tc_ban$b, tc_recv$b, tc_phys$b, ddd_coefs[ddd_term]) /
        c(sd_fp_ban, sd_fp_recv, sd_phys, sd_ddd),
  se_sde = c(tc_ban$se, tc_recv$se, tc_phys$se, ddd_ses[ddd_term]) /
           c(sd_fp_ban, sd_fp_recv, sd_phys, sd_ddd),
  classification = classify_sde(
    c(tc_ban$b, tc_recv$b, tc_phys$b, ddd_coefs[ddd_term]) /
    c(sd_fp_ban, sd_fp_recv, sd_phys, sd_ddd)
  )
)

sde_body <- ""
for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  sde_body <- paste0(sde_body,
    r$Outcome, " & ",
    sprintf("%.4f", r$beta), " & ",
    sprintf("%.4f", r$se), " & --- & ",
    sprintf("%.4f", r$sd_y), " & ",
    sprintf("%.4f", r$sde), " & ",
    sprintf("%.4f", r$se_sde), " & ",
    r$classification, " \\\\\n")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did state-level abortion bans following the Dobbs decision ",
  "cause reallocation of reproductive healthcare employment from ban states to neighboring receiving states? ",
  "\\textbf{Policy mechanism:} Thirteen states had pre-enacted trigger laws that immediately banned ",
  "most abortions upon the Supreme Court's reversal of Roe v.\\ Wade in June 2022, causing family ",
  "planning clinics to close or reduce services in ban states while demand concentrated in bordering non-ban states. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter employment from Census Quarterly Workforce ",
  "Indicators (QWI) for family planning centers (NAICS 62141) and physician offices (NAICS 6211). ",
  "\\textbf{Treatment:} Binary indicator for state abortion ban in effect (ban states) or bordering a ban state (receiving states). ",
  "\\textbf{Data:} Census QWI, 2015Q1--2024Q2, state-quarter level. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with state and quarter fixed effects, state-clustered standard errors. ",
  "\\textbf{Sample:} All US states excluding those with partial or contested bans (GA, IN, SC, OH) from treatment groups. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lccccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n",
  sde_body,
  "\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("SDE table written.\n\nAll tables generated successfully.\n")
