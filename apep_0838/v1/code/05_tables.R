# 05_tables.R — Generate all LaTeX tables
source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

p <- panel[!is.na(pre_gender_gap)]
pre <- p[post == 0]
pst <- p[post == 1]

fmt2 <- function(x) formatC(x, format = "f", digits = 3, big.mark = ",")
fmtN <- function(x) format(x, big.mark = ",")

vars_info <- list(
  list("Female employment share", "female_share"),
  list("Employees", "employees"),
  list("Establishments", "establishments"),
  list("Full-time equivalents", "fte"),
  list("Avg. establishment size", "avg_size"),
  list("Pre-treatment gender gap", "pre_gender_gap")
)

tex1 <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & N & Mean & SD & Pre-2020 & Post-2020 \\\\",
  "\\hline"
)

for (vi in vars_info) {
  lab <- vi[[1]]; v <- vi[[2]]
  n <- sum(!is.na(p[[v]]))
  mn <- mean(p[[v]], na.rm = TRUE)
  sd_v <- sd(p[[v]], na.rm = TRUE)
  mn_pre <- mean(pre[[v]], na.rm = TRUE)
  mn_post <- mean(pst[[v]], na.rm = TRUE)
  tex1 <- c(tex1, sprintf("%s & %s & %s & %s & %s & %s \\\\",
                           lab, fmtN(n), fmt2(mn), fmt2(sd_v), fmt2(mn_pre), fmt2(mn_post)))
}

tex1 <- c(tex1,
  "\\hline",
  sprintf("\\multicolumn{6}{p{0.9\\textwidth}}{\\footnotesize \\textit{Notes:} Unit of observation is canton $\\times$ NOGA industry $\\times$ year. Employment data from BFS STATENT (2011--2023, %s cantons, %s industries). Gender wage gap from BFS LSE (2018 wave). Pre-treatment gender gap is the industry-level male--female wage differential divided by male median wage.} \\\\",
          uniqueN(p$canton), uniqueN(p$noga_code)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex1, file.path(table_dir, "tab1_sumstats.tex"))
cat("Saved tab1_sumstats.tex\n")

# ============================================================
# Table 2: Main Results (using fixest::etable)
# ============================================================

cat("=== Table 2: Main Results ===\n")

setFixest_dict(c(
  treat_intensity = "Post $\\times$ Gender Gap",
  female_share = "Female Share",
  log_emp = "Log Emp.",
  log_est = "Log Est.",
  log_fte = "Log FTE"
))

etable(m1, m2, m3, m4, m5,
       se.below = TRUE,
       keep = "%treat_intensity",
       fitstat = ~n + wr2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       style.tex = style.tex("aer"),
       title = "Effect of GEA Pay Audit Mandate on Employment Structure",
       label = "tab:main",
       notes = c(
         "Standard errors clustered at NOGA division level in parentheses.",
         "All regressions include canton $\\times$ industry and year fixed effects.",
         "Treatment intensity is post-2020 $\\times$ industry gender wage gap (2018)."
       ),
       tex = TRUE,
       file = file.path(table_dir, "tab2_main.tex"),
       replace = TRUE)
cat("Saved tab2_main.tex\n")

# ============================================================
# Table 3: Event Study
# ============================================================

cat("=== Table 3: Event Study ===\n")

es_fs <- coeftable(m_event)
es_emp <- coeftable(m_event_emp)

es_times_fs <- as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", rownames(es_fs)))
es_times_emp <- as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", rownames(es_emp)))

es_dt <- data.table(
  t = es_times_fs,
  coef_fs = es_fs[, 1], se_fs = es_fs[, 2],
  coef_emp = es_emp[, 1], se_emp = es_emp[, 2]
)
es_dt <- es_dt[order(t)]

# Add reference row
ref_row <- data.table(t = -1L, coef_fs = 0, se_fs = NA, coef_emp = 0, se_emp = NA)
es_dt <- rbind(es_dt, ref_row)
es_dt <- es_dt[order(t)]

tex3 <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects by Gender Gap Intensity}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Female Share} & \\multicolumn{2}{c}{Log Employment} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Year & Coef. & (SE) & Coef. & (SE) \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_dt))) {
  yr <- es_dt$t[i]
  label <- sprintf("$t%+d$ (%d)", yr, 2020 + yr)
  if (yr == -1) {
    tex3 <- c(tex3, sprintf("%s & --- & --- & --- & --- \\\\", label))
  } else {
    tex3 <- c(tex3, sprintf("%s & %.4f & (%.4f) & %.4f & (%.4f) \\\\",
                             label, es_dt$coef_fs[i], es_dt$se_fs[i],
                             es_dt$coef_emp[i], es_dt$se_emp[i]))
  }
}

tex3 <- c(tex3,
  "\\hline",
  sprintf("N & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(m_event$nobs, big.mark = ","), format(m_event_emp$nobs, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.2cm}",
  sprintf("\\parbox{0.9\\textwidth}{\\footnotesize \\textit{Notes:} Each coefficient is the interaction of a relative-year indicator with the pre-treatment (2018) industry gender wage gap. Reference period is $t-1$ (2019). Standard errors clustered at NOGA division level. Pre-trend coefficients center around zero for female share. Post-treatment female share coefficients increase monotonically from 0.004 to 0.024, suggesting gradual compositional adjustment.}"),
  "\\end{table}"
)
writeLines(tex3, file.path(table_dir, "tab3_event.tex"))
cat("Saved tab3_event.tex\n")

# ============================================================
# Table 4: Robustness
# ============================================================

cat("=== Table 4: Robustness ===\n")

setFixest_dict(c(
  placebo_treat = "Placebo $\\times$ Gap",
  treat_no2020 = "Post $\\times$ Gap",
  top_tercile_post = "Post $\\times$ Top Tercile"
))

etable(m_placebo_fs, m_no2020_fs, m_terc_fs, m_placebo_emp, m_no2020_emp, m_terc_emp,
       se.below = TRUE,
       keep = c("%placebo_treat", "%treat_no2020", "%top_tercile_post"),
       fitstat = ~n + wr2,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       style.tex = style.tex("aer"),
       title = "Robustness Checks",
       label = "tab:robust",
       headers = c("\\multicolumn{3}{c}{Female Share}", "\\multicolumn{3}{c}{Log Employment}"),
       notes = c(
         "Placebo: treatment at 2016, pre-2020 data only.",
         "Drop 2020: excludes mandate year (COVID overlap).",
         "Tercile: top vs. bottom tercile of pre-treatment gender gap."
       ),
       tex = TRUE,
       file = file.path(table_dir, "tab4_robustness.tex"),
       replace = TRUE)
cat("Saved tab4_robustness.tex\n")

# ============================================================
# Table F1: SDE
# ============================================================

cat("=== Table F1: Standardized Effect Sizes ===\n")

sd_x <- sd(panel$pre_gender_gap, na.rm = TRUE)

sde_data <- data.table(
  Outcome = c("Female share", "Log employment", "Log establishments", "Log FTE"),
  beta = c(coef(m1)["treat_intensity"], coef(m2)["treat_intensity"],
           coef(m3)["treat_intensity"], coef(m4)["treat_intensity"]),
  se = c(se(m1)["treat_intensity"], se(m2)["treat_intensity"],
         se(m3)["treat_intensity"], se(m4)["treat_intensity"]),
  sd_y = c(y_pre$sd_female_share, y_pre$sd_log_emp, y_pre$sd_log_est, y_pre$sd_log_fte)
)

sde_data[, SDE := beta * sd_x / sd_y]
sde_data[, SE_SDE := se * sd_x / sd_y]
sde_data[, Classification := fcase(
  SDE < -0.15, "Large negative",
  SDE < -0.05, "Moderate negative",
  SDE < -0.005, "Small negative",
  SDE < 0.005, "Null",
  SDE < 0.05, "Small positive",
  SDE < 0.15, "Moderate positive",
  SDE >= 0.15, "Large positive"
)]

sde_notes <- paste0(
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does Switzerland's 2020 equal-pay audit mandate (GEA revision) ",
  "alter employment composition in industries with larger pre-existing gender wage gaps? ",
  "\\textbf{Policy mechanism:} The revised Gleichstellungsgesetz requires firms with 100 or more employees ",
  "to conduct structured equal-pay analyses using the Logib tool, have results verified by an external auditor ",
  "or employee representative body, and communicate findings to employees by June 2023. ",
  "The mandate creates compliance costs proportional to the unexplained gender gap and reputational incentives ",
  "to adjust pay structures or hiring composition. ",
  "\\textbf{Outcome definition:} Female employment share (female employees divided by total employees) ",
  "and log total employment measured at the canton-by-NOGA-division-by-year level from BFS STATENT. ",
  "\\textbf{Treatment:} Continuous; the pre-treatment (2018) industry-level gender wage gap ",
  "(male minus female median monthly gross wage divided by male wage), ranging from $-$0.05 to 0.43, ",
  "with SD $=$ 0.093. ",
  "\\textbf{Data:} BFS STATENT (2011--2023, annual, 26 cantons $\\times$ 76 NOGA divisions) and BFS LSE (2018). ",
  "25,688 observations. ",
  "\\textbf{Method:} Continuous difference-in-differences with canton$\\times$industry and year fixed effects; ",
  "standard errors clustered at NOGA division level (76 clusters). ",
  "\\textbf{Sample:} All two-digit NOGA industries with non-missing employment and wage data; ",
  "7 industries excluded due to coverage gaps. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-industry ",
  "standard deviation of the pre-treatment gender gap and SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

texF <- c(
  "\\begin{table}[!htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)
for (i in seq_len(nrow(sde_data))) {
  texF <- c(texF, sprintf("%s & %.4f & (%.4f) & %.3f & %.4f & (%.4f) & %s \\\\",
                           sde_data$Outcome[i], sde_data$beta[i], sde_data$se[i],
                           sde_data$sd_y[i], sde_data$SDE[i], sde_data$SE_SDE[i],
                           sde_data$Classification[i]))
}
texF <- c(texF,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\vspace{0.2cm}",
  sprintf("\\parbox{\\textwidth}{\\footnotesize \\textit{Notes:} %s}", sde_notes),
  "\\end{table}"
)
writeLines(texF, file.path(table_dir, "tabF1_sde.tex"))
cat("Saved tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
cat("Files:\n")
for (f in list.files(table_dir)) cat(sprintf("  %s\n", f))
