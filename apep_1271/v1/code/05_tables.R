# 05_tables.R — Generate all LaTeX tables
# Paper: Mandated to Stay (apep_1271)

source("00_packages.R")

att_table <- fread("../data/att_table.csv")
pre_sds <- fread("../data/pre_sds.csv")
food <- fread("../data/panel_food.csv")
robustness <- readRDS("../data/robustness_results.rds")
results <- readRDS("../data/cs_results.rds")

# Create variable-to-outcome lookup
var_to_label <- c(
  sep_rate = "Separation Rate",
  hirn_rate = "New Hire Rate",
  hirr_rate = "Recall Rate",
  stability = "Stable Employment Share",
  turnover = "Turnover Rate"
)

# Helper: get ATT row by variable name
get_att <- function(varname) {
  label <- var_to_label[varname]
  att_table[outcome == label]
}

# ---- Helper: format coefficient with stars ----
fmt_coef <- function(est, se, digits = 4) {
  pval <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(pval < 0.01, "^{***}", ifelse(pval < 0.05, "^{**}", ifelse(pval < 0.10, "^{*}", "")))
  sprintf("$%s%s$", formatC(est, format = "f", digits = digits), stars)
}

fmt_se <- function(se, digits = 4) {
  sprintf("$(%s)$", formatC(se, format = "f", digits = digits))
}

# ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics\n")

pre <- food[treatment_quarter == 0 | quarter_num < treatment_quarter]
treated_pre <- food[treatment_quarter > 0 & quarter_num < treatment_quarter]
control_pre <- food[treatment_quarter == 0]

vars <- c("Emp", "sep_rate", "hirn_rate", "hirr_rate", "stability", "turnover", "EarnHirNS")
var_labels <- c("Employment", "Separation Rate", "New Hire Rate", "Recall Rate",
                "Stable Employment Share", "Turnover Rate", "New Hire Earnings (\\$)")

sumstat_rows <- character()
for (i in seq_along(vars)) {
  v <- vars[i]
  tm <- mean(treated_pre[[v]], na.rm = TRUE)
  tsd <- sd(treated_pre[[v]], na.rm = TRUE)
  cm <- mean(control_pre[[v]], na.rm = TRUE)
  csd <- sd(control_pre[[v]], na.rm = TRUE)
  diff <- tm - cm

  dig <- if (v %in% c("Emp", "EarnHirNS")) 0 else 4
  sumstat_rows <- c(sumstat_rows, sprintf(
    "%s & %s & %s & %s & %s & %s \\\\",
    var_labels[i],
    formatC(tm, format = "f", digits = dig),
    formatC(tsd, format = "f", digits = dig),
    formatC(cm, format = "f", digits = dig),
    formatC(csd, format = "f", digits = dig),
    formatC(diff, format = "f", digits = dig)
  ))
}

n_treated <- uniqueN(treated_pre$county_fips)
n_control <- uniqueN(control_pre$county_fips)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Food Service (NAICS 722), Pre-Treatment}\n",
  "\\label{tab:sumstats}\n",
  "\\small\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Treated} & \\multicolumn{2}{c}{Control} & \\\\\n",
  " & Mean & SD & Mean & SD & Diff. \\\\\n",
  "\\hline\n",
  paste(sumstat_rows, collapse = "\n"),
  "\n\\hline\n",
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\\\\n", n_treated, n_control),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Pre-treatment means and standard deviations for food service (NAICS 722) counties. ",
  "Treated counties are in states that adopted paid sick leave mandates (CT, CA, MA, OR, VT, AZ, WA, MD, NJ). ",
  "Control counties are in states without statewide mandates through 2022. ",
  "Rates are computed as quarterly flows divided by beginning-of-quarter employment. ",
  "Recall rate = all hires $-$ new hires.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ---- Table 2: Main Results — Four-Way Decomposition ----
cat("Generating Table 2: Main Results\n")

outcomes <- c("sep_rate", "hirn_rate", "hirr_rate", "stability", "turnover")
col_labels <- c("Separations", "New Hires", "Recalls", "Stable Emp.", "Turnover")

# Row 1: ATT estimates
att_row <- paste(sapply(outcomes, function(o) {
  r <- get_att(o)
  if (nrow(r) == 0) return("&")
  fmt_coef(r$att[1], r$se[1])
}), collapse = " & ")

se_row <- paste(sapply(outcomes, function(o) {
  r <- get_att(o)
  if (nrow(r) == 0) return("&")
  fmt_se(r$se[1])
}), collapse = " & ")

# Pre-treatment means
pre_means <- sapply(outcomes, function(o) {
  formatC(mean(food[treatment_quarter == 0 | quarter_num < treatment_quarter][[o]], na.rm = TRUE),
          format = "f", digits = 4)
})
mean_row <- paste(pre_means, collapse = " & ")

# Percentage effect
pct_row <- paste(sapply(outcomes, function(o) {
  r <- get_att(o)
  m <- mean(food[treatment_quarter == 0 | quarter_num < treatment_quarter][[o]], na.rm = TRUE)
  if (nrow(r) == 0 || m == 0) return("&")
  sprintf("%.1f\\%%", 100 * r$att[1] / m)
}), collapse = " & ")

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Paid Sick Leave Mandates and Food Service Turnover: Four-Way Decomposition}\n",
  "\\label{tab:main}\n",
  "\\small\n",
  "\\begin{tabular}{l", paste(rep("c", 5), collapse = ""), "}\n",
  "\\hline\\hline\n",
  " & ", paste(col_labels, collapse = " & "), " \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "ATT & ", att_row, " \\\\\n",
  " & ", se_row, " \\\\\n",
  "\\addlinespace\n",
  "Pre-treatment mean & ", mean_row, " \\\\\n",
  "\\% effect & ", pct_row, " \\\\\n",
  "\\addlinespace\n",
  sprintf("Counties & \\multicolumn{5}{c}{%d} \\\\\n", uniqueN(food$county_fips)),
  sprintf("County-quarters & \\multicolumn{5}{c}{%s} \\\\\n", format(nrow(food), big.mark = ",")),
  sprintf("Treated states & \\multicolumn{5}{c}{%d} \\\\\n", uniqueN(food[treatment_quarter > 0, state_fips])),
  "Estimator & \\multicolumn{5}{c}{Callaway--Sant'Anna (2021)} \\\\\n",
  "Control group & \\multicolumn{5}{c}{Not-yet-treated} \\\\\n",
  "Clustering & \\multicolumn{5}{c}{State} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) staggered DiD estimates of paid sick leave mandates on food service (NAICS 722) worker flows. ",
  "The ATT is the overall simple-weighted average of group-time treatment effects. ",
  "Rates are quarterly flows per beginning-of-quarter worker. ",
  "Recall rate = all hires $-$ new hires. ",
  "Standard errors clustered at state level in parentheses. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ---- Table 3: Robustness ----
cat("Generating Table 3: Robustness\n")

main_outcomes <- c("sep_rate", "hirn_rate", "hirr_rate", "stability")
rob_col_labels <- c("Separations", "New Hires", "Recalls", "Stable Emp.")

# Panel A: Never-treated controls
nt <- robustness$never_treated
nt_att_row <- paste(sapply(main_outcomes, function(o) fmt_coef(nt[[o]]$att, nt[[o]]$se)), collapse = " & ")
nt_se_row <- paste(sapply(main_outcomes, function(o) fmt_se(nt[[o]]$se)), collapse = " & ")

# Panel B: Exclude CT
ct <- robustness$exclude_ct
ct_att_row <- paste(sapply(main_outcomes, function(o) fmt_coef(ct[[o]]$att, ct[[o]]$se)), collapse = " & ")
ct_se_row <- paste(sapply(main_outcomes, function(o) fmt_se(ct[[o]]$se)), collapse = " & ")

# Panel C: Retail placebo
rp <- robustness$retail_placebo
rp_att_row <- paste(c(
  fmt_coef(rp[["sep_rate"]]$att, rp[["sep_rate"]]$se),
  fmt_coef(rp[["hirn_rate"]]$att, rp[["hirn_rate"]]$se),
  "---", "---"
), collapse = " & ")
rp_se_row <- paste(c(
  fmt_se(rp[["sep_rate"]]$se),
  fmt_se(rp[["hirn_rate"]]$se),
  "", ""
), collapse = " & ")

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\small\n",
  "\\begin{tabular}{l", paste(rep("c", 4), collapse = ""), "}\n",
  "\\hline\\hline\n",
  " & ", paste(rob_col_labels, collapse = " & "), " \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Never-treated controls only}} \\\\\n",
  "\\addlinespace\n",
  "ATT & ", nt_att_row, " \\\\\n",
  " & ", nt_se_row, " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Exclude Connecticut}} \\\\\n",
  "\\addlinespace\n",
  "ATT & ", ct_att_row, " \\\\\n",
  " & ", ct_se_row, " \\\\\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Retail sector placebo (NAICS 44--45)}} \\\\\n",
  "\\addlinespace\n",
  "ATT & ", rp_att_row, " \\\\\n",
  " & ", rp_se_row, " \\\\\n",
  "\\addlinespace\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Panel A uses only never-treated states as controls. ",
  "Panel B excludes Connecticut, whose mandate covers only service workers at firms with 50+ employees. ",
  "Panel C applies the same design to retail (NAICS 44--45), where paid sick leave should have smaller effects due to higher baseline voluntary coverage. ",
  "All specifications use Callaway--Sant'Anna (2021). Standard errors clustered at state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# ---- Table 4: Age Heterogeneity ----
cat("Generating Table 4: Age Heterogeneity\n")

age_res <- robustness$age_heterogeneity

age_rows <- character()
for (ag in c("young_19_24", "prime_25_54")) {
  ag_label <- if (ag == "young_19_24") "Young (19--24)" else "Prime-age (25--54)"
  att_vals <- sapply(main_outcomes, function(o) {
    key <- paste0(ag, "_", o)
    if (!is.null(age_res[[key]])) fmt_coef(age_res[[key]]$att, age_res[[key]]$se) else "---"
  })
  se_vals <- sapply(main_outcomes, function(o) {
    key <- paste0(ag, "_", o)
    if (!is.null(age_res[[key]])) fmt_se(age_res[[key]]$se) else ""
  })
  age_rows <- c(age_rows,
    sprintf("%s & %s \\\\", ag_label, paste(att_vals, collapse = " & ")),
    sprintf(" & %s \\\\", paste(se_vals, collapse = " & ")),
    "\\addlinespace"
  )
}

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Age Heterogeneity in Food Service}\n",
  "\\label{tab:age}\n",
  "\\small\n",
  "\\begin{tabular}{l", paste(rep("c", 4), collapse = ""), "}\n",
  "\\hline\\hline\n",
  " & ", paste(rob_col_labels, collapse = " & "), " \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  paste(age_rows, collapse = "\n"),
  "\n\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Callaway--Sant'Anna estimates by age group in food service (NAICS 722). ",
  "Young workers (19--24) have the lowest pre-mandate voluntary sick leave coverage and are predicted to show the largest effects. ",
  "The sample is split by age group and each specification is estimated separately. ",
  "Counties with age-group employment $<$ 20 in any quarter are dropped. ",
  "Standard errors clustered at state level. ",
  "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_age.tex")

# ---- Table F1: Standardized Effect Size (SDE) Appendix ----
cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE = beta_hat / SD(Y) for main outcomes
sde_outcomes <- c("sep_rate", "hirn_rate", "hirr_rate", "stability")
sde_labels <- c("Separation Rate", "New Hire Rate", "Recall Rate", "Stable Employment Share")

sde_rows <- data.table(
  Outcome = sde_labels,
  beta = sapply(sde_outcomes, function(o) {
    r <- get_att(o)
    if (nrow(r) > 0) r$att[1] else NA_real_
  }),
  se_beta = sapply(sde_outcomes, function(o) {
    r <- get_att(o)
    if (nrow(r) > 0) r$se[1] else NA_real_
  }),
  sd_y = sapply(sde_outcomes, function(o) {
    label <- var_to_label[o]
    r <- pre_sds[outcome == label]
    if (nrow(r) > 0) r$pre_sd[1] else NA_real_
  })
)

sde_rows[, SDE := beta / sd_y]
sde_rows[, SE_SDE := se_beta / sd_y]
sde_rows[, Classification := fcase(
  SDE < -0.15, "Large negative",
  SDE < -0.05, "Moderate negative",
  SDE < -0.005, "Small negative",
  SDE <= 0.005, "Null",
  SDE <= 0.05, "Small positive",
  SDE <= 0.15, "Moderate positive",
  SDE > 0.15, "Large positive"
)]

# Panel B: Age heterogeneity (young vs prime-age for separation rate)
sde_het_rows <- list()
for (ag in c("young_19_24", "prime_25_54")) {
  key <- paste0(ag, "_sep_rate")
  if (!is.null(age_res[[key]])) {
    ag_label <- if (ag == "young_19_24") "Sep. Rate: Young (19--24)" else "Sep. Rate: Prime-age (25--54)"
    b <- age_res[[key]]$att
    s <- age_res[[key]]$se
    sd_y <- sd(food[treatment_quarter == 0 | quarter_num < treatment_quarter, sep_rate], na.rm = TRUE)
    sde_val <- b / sd_y
    sde_het_rows[[ag]] <- data.table(
      Outcome = ag_label, beta = b, se_beta = s, sd_y = sd_y,
      SDE = sde_val, SE_SDE = s / sd_y,
      Classification = fcase(
        sde_val < -0.15, "Large negative",
        sde_val < -0.05, "Moderate negative",
        sde_val < -0.005, "Small negative",
        sde_val <= 0.005, "Null",
        sde_val <= 0.05, "Small positive",
        sde_val <= 0.15, "Moderate positive",
        sde_val > 0.15, "Large positive"
      )
    )
  }
}
sde_het <- rbindlist(sde_het_rows)

# Format SDE table
fmt_sde_row <- function(r) {
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          r$Outcome,
          formatC(r$beta, format = "f", digits = 5),
          formatC(r$se_beta, format = "f", digits = 5),
          formatC(r$sd_y, format = "f", digits = 4),
          formatC(r$SDE, format = "f", digits = 4),
          formatC(r$SE_SDE, format = "f", digits = 4),
          r$Classification)
}

panel_a_rows <- paste(apply(sde_rows, 1, function(r) {
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
          r["Outcome"],
          formatC(as.numeric(r["beta"]), format = "f", digits = 5),
          formatC(as.numeric(r["se_beta"]), format = "f", digits = 5),
          formatC(as.numeric(r["sd_y"]), format = "f", digits = 4),
          formatC(as.numeric(r["SDE"]), format = "f", digits = 4),
          formatC(as.numeric(r["SE_SDE"]), format = "f", digits = 4),
          r["Classification"])
}), collapse = "\n")

panel_b_rows <- paste(apply(sde_het, 1, function(r) {
  sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
          r["Outcome"],
          formatC(as.numeric(r["beta"]), format = "f", digits = 5),
          formatC(as.numeric(r["se_beta"]), format = "f", digits = 5),
          formatC(as.numeric(r["sd_y"]), format = "f", digits = 4),
          formatC(as.numeric(r["SDE"]), format = "f", digits = 4),
          formatC(as.numeric(r["SE_SDE"]), format = "f", digits = 4),
          r["Classification"])
}), collapse = "\n")

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level paid sick leave mandates reduce labor market turnover in food service, and through which worker-flow channels? ",
  "\\textbf{Policy mechanism:} State laws require employers to provide paid sick days to workers, reducing presenteeism pressure that otherwise drives voluntary separations in high-turnover industries like food service. ",
  "\\textbf{Outcome definition:} Quarterly worker flow rates from the Census QWI: separation rate (Sep/Emp), new hire rate (HirN/Emp), recall rate ((HirA$-$HirN)/Emp), and stable employment share (EmpS/Emp). ",
  "\\textbf{Treatment:} Binary; indicator for state having an active paid sick leave mandate. ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI/LEHD), 2005--2022, county-quarter level, food service sector (NAICS 722). ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with not-yet-treated controls; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with food service employment $\\geq$ 50 in all quarters; 9 treated states with mandates effective 2012--2019. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "\\addlinespace\n",
  panel_a_rows, "\n",
  "\\addlinespace\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Age Groups)}} \\\\\n",
  "\\addlinespace\n",
  panel_b_rows, "\n",
  "\\addlinespace\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated. 05_tables.R completed successfully.\n")
