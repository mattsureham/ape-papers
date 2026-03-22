## 05_tables.R — Generate all LaTeX tables
## Paper: apep_0738 — Franc Shock and Retail Desertification

source("code/00_packages.R")

models <- readRDS("data/model_objects.rds")
robust_models <- readRDS("data/robustness_models.rds")
canton_panel <- fread("data/canton_retail_panel.csv")
muni_panel <- fread("data/municipal_panel.csv")
es_coefs <- fread("data/event_study_coefs.csv")

dir.create("tables", showWarnings = FALSE)

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

pre_data <- canton_panel[year <= 2014]
border_pre <- pre_data[border == 1]
interior_pre <- pre_data[border == 0]

make_stat_row <- function(var, label, dt_b, dt_i) {
  sprintf("%s & %.0f & %.0f & %.0f & %.0f \\\\",
          label,
          mean(dt_b[[var]], na.rm = TRUE),
          sd(dt_b[[var]], na.rm = TRUE),
          mean(dt_i[[var]], na.rm = TRUE),
          sd(dt_i[[var]], na.rm = TRUE))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Means (2011--2014)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Border Cantons} & \\multicolumn{2}{c}{Interior Cantons} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  make_stat_row("retail_est", "Retail establishments", border_pre, interior_pre),
  make_stat_row("retail_emp", "Retail employment", border_pre, interior_pre),
  make_stat_row("nontrad_est", "Non-tradable establishments", border_pre, interior_pre),
  make_stat_row("hosp_est", "Hospitality establishments", border_pre, interior_pre),
  make_stat_row("total_est", "Total establishments", border_pre, interior_pre),
  sprintf("Retail share (\\%%) & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(border_pre$retail_share, na.rm = TRUE) * 100,
          sd(border_pre$retail_share, na.rm = TRUE) * 100,
          mean(interior_pre$retail_share, na.rm = TRUE) * 100,
          sd(interior_pre$retail_share, na.rm = TRUE) * 100),
  "\\midrule",
  sprintf("Cantons & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          uniqueN(border_pre$canton), uniqueN(interior_pre$canton)),
  sprintf("Canton-years & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(border_pre), nrow(interior_pre)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Summary statistics for the pre-treatment period (2011--2014). Border cantons are those sharing a land border with an EU/EFTA country (border exposure $> 0$). Data from the Swiss Federal Statistical Office (BFS) Structural Business Statistics (STATENT).",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("=== Generating Table 2: Main DiD Results ===\n")

# Use etable from fixest
etable(models$m1, models$m2, models$m3, models$m4,
       tex = TRUE,
       file = "tables/tab2_main_did.tex",
       title = "The Franc Shock and Retail Sector Outcomes",
       label = "tab:main_did",
       headers = c("Log Estab.", "Log Estab.", "Log Employ.", "Retail Share"),
       notes = paste0("All specifications include canton and year fixed effects. ",
                      "Column (1) uses continuous border exposure (0--1 scale). ",
                      "Column (2) uses a binary border indicator. ",
                      "Columns (3)--(4) use continuous exposure. ",
                      "Standard errors clustered at the canton level in parentheses. ",
                      "Data: BFS STATENT 2011--2023, 26 cantons. ",
                      "The treatment is the January 15, 2015 removal of the EUR/CHF 1.20 floor. ",
                      "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$."),
       depvar = TRUE,
       se = "cluster",
       fitstat = ~ n + r2 + wr2)

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("=== Generating Table 3: Event Study ===\n")

# Extract event study coefficients using fixest iplot data
extract_es <- function(model, prefix = "") {
  ct <- coeftable(model)
  nms <- rownames(ct)
  # Parse event times from names like "event_time::-4:border_exposure"
  ets <- as.integer(gsub(".*event_time::(-?\\d+).*", "\\1", nms))
  dt <- data.table(
    event_time = ets,
    coef = ct[, 1],
    se = ct[, 2],
    p = ct[, 4]
  )
  dt[, stars := fcase(p < 0.01, "***", p < 0.05, "**", p < 0.10, "*", default = "")]
  # Add base year
  dt <- rbind(dt, data.table(event_time = -1L, coef = 0, se = NA_real_, p = NA_real_, stars = ""))
  dt <- dt[order(event_time)]
  if (nchar(prefix) > 0) setnames(dt, c("coef","se","p","stars"), paste0(prefix, c("coef","se","p","stars")))
  dt
}

es_est <- extract_es(models$es1)
es_emp <- extract_es(models$es2, prefix = "emp_")

es_merged <- cbind(es_est, es_emp[, !c("event_time"), with = FALSE])

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Retail Outcomes $\\times$ Border Exposure}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Log Establishments} & \\multicolumn{2}{c}{Log Employment} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Year ($t - 2015$) & Coefficient & SE & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_merged)) {
  r <- es_merged[i]
  yr_label <- ifelse(r$event_time == -1, "$-1$ (base)", sprintf("$%+d$", r$event_time))
  if (r$event_time == -1) {
    tab3_lines <- c(tab3_lines, sprintf("%s & --- & --- & --- & --- \\\\", yr_label))
  } else {
    tab3_lines <- c(tab3_lines,
      sprintf("%s & %.4f%s & (%.4f) & %.4f%s & (%.4f) \\\\",
              yr_label, r$coef, r$stars, r$se,
              r$emp_coef, r$emp_stars, r$emp_se))
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nobs(models$es1), nobs(models$es2)),
  "Canton FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Event study coefficients from $\\log Y_{ct} = \\alpha_c + \\gamma_t + \\sum_{\\tau \\neq -1} \\beta_\\tau \\cdot \\text{BorderExposure}_c \\cdot \\mathbf{1}[t - 2015 = \\tau] + \\varepsilon_{ct}$. Border exposure is a continuous measure (0--1) of cantonal proximity to cross-border retail shopping. Base year: 2014 ($\\tau = -1$). Standard errors clustered at the canton level. $^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, "tables/tab3_event_study.tex")

# ============================================================
# Table 4: Robustness and Placebos
# ============================================================
cat("=== Generating Table 4: Robustness ===\n")

etable(models$m1,
       robust_models$placebo_nontrad,
       robust_models$placebo_hosp,
       robust_models$dose_model,
       tex = TRUE,
       file = "tables/tab4_robustness.tex",
       title = "Robustness Checks and Placebo Tests",
       label = "tab:robustness",
       headers = c("Retail", "Non-Tradable", "Hospitality", "Dose-Response"),
       notes = paste0("Column (1) reproduces the main result for comparison. ",
                      "Columns (2)--(3) use non-tradable (education, health, public administration; NOGA 84--88) ",
                      "and hospitality (NOGA 55--56) establishments as placebo outcomes. ",
                      "Column (4) splits border cantons into high ($\\geq 0.7$) and medium ($0.15$--$0.69$) exposure. ",
                      "All specifications include canton and year fixed effects. ",
                      "Standard errors clustered at the canton level. ",
                      "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$."),
       depvar = TRUE,
       se = "cluster",
       fitstat = ~ n + r2 + wr2)

# ============================================================
# Table 5 (Appendix): SDE Table
# ============================================================
cat("=== Generating SDE Table ===\n")

# Compute SDE for main outcomes
# SDE = beta_hat / SD(Y) for binary treatment, or
# SDE = beta_hat * SD(X) / SD(Y) for continuous treatment
pre_canton <- canton_panel[year <= 2014]
sd_log_retail_est <- sd(pre_canton$log_retail_est, na.rm = TRUE)
sd_log_retail_emp <- sd(pre_canton$log_retail_emp, na.rm = TRUE)
sd_retail_share <- sd(pre_canton$retail_share, na.rm = TRUE)
sd_border_exp <- sd(canton_panel$border_exposure, na.rm = TRUE)

# Main results
beta_est <- coef(models$m1)["border_exposure:post"]
se_est <- se(models$m1)["border_exposure:post"]
sde_est <- beta_est * sd_border_exp / sd_log_retail_est
sde_se_est <- se_est * sd_border_exp / sd_log_retail_est

beta_emp <- coef(models$m3)["border_exposure:post"]
se_emp <- se(models$m3)["border_exposure:post"]
sde_emp <- beta_emp * sd_border_exp / sd_log_retail_emp
sde_se_emp <- se_emp * sd_border_exp / sd_log_retail_emp

beta_share <- coef(models$m4)["border_exposure:post"]
se_share <- se(models$m4)["border_exposure:post"]
sde_share <- beta_share * sd_border_exp / sd_retail_share
sde_se_share <- se_share * sd_border_exp / sd_retail_share

# Classification function
classify_sde <- function(s) {
  abs_s <- abs(s)
  if (abs_s < 0.005) return("Null")
  if (abs_s < 0.05) {
    if (s > 0) return("Small positive") else return("Small negative")
  }
  if (abs_s < 0.15) {
    if (s > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (s > 0) return("Large positive") else return("Large negative")
}

sde_rows <- data.table(
  outcome = c("Log retail establishments",
              "Log retail employment",
              "Retail establishment share"),
  beta = c(beta_est, beta_emp, beta_share),
  se = c(se_est, se_emp, se_share),
  sd_y = c(sd_log_retail_est, sd_log_retail_emp, sd_retail_share),
  sde = c(sde_est, sde_emp, sde_share),
  sde_se = c(sde_se_est, sde_se_emp, sde_se_share)
)
sde_rows[, classification := sapply(sde, classify_sde)]

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does an unexpected, large exchange rate appreciation cause permanent retail firm destruction in border municipalities by making cross-border shopping cheaper? ",
  "\\textbf{Policy mechanism:} The Swiss National Bank's January 2015 removal of the EUR/CHF 1.20 floor caused an overnight franc appreciation of approximately 15 percent, ",
  "making goods in neighboring EU countries correspondingly cheaper for Swiss consumers and triggering a surge in cross-border shopping that reduced revenue for domestic retailers. ",
  "\\textbf{Outcome definition:} Log number of retail trade establishments (NOGA division 47) and retail employment from the BFS Structural Business Statistics (STATENT) census, ",
  "plus retail establishment share of total establishments. ",
  "\\textbf{Treatment:} Continuous cantonal border exposure (0--1 scale measuring proximity to accessible cross-border shopping). ",
  "\\textbf{Data:} BFS STATENT, 2011--2023, 26 cantons observed annually. ",
  "\\textbf{Method:} Two-way fixed effects DiD (canton + year FE), standard errors clustered at the canton level, wild cluster bootstrap for few-cluster inference. ",
  "\\textbf{Sample:} All 26 Swiss cantons; 14 border cantons (exposure $> 0$) vs.\\ 12 interior cantons. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional standard deviation of border exposure ",
  "and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tab_sde <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i]
  tab_sde <- c(tab_sde,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            r$outcome, r$beta, r$se, r$sd_y, r$sde, r$sde_se, r$classification))
}

tab_sde <- c(tab_sde,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab_sde, "tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
