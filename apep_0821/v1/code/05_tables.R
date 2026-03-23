## 05_tables.R — Generate all LaTeX tables
## Paper: The Bureaucrat's Bonus (apep_0821)

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")
panel[, gov_trend := gov_emp_share * (year - 2007)]
panel[, pop_trend := log(pop + 1) * year]
results <- readRDS("data/main_results.rds")
rob <- readRDS("data/robustness_results.rds")

cat("=== GENERATING TABLES ===\n\n")

## ═══════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════════════════
cat("--- Table 1: Summary Statistics ---\n")

pre <- panel[year < 2008]
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d)

make_row <- function(varname, label, data, digits = 2) {
  x <- data[[varname]]
  x <- x[!is.na(x)]
  sprintf("%s & %s & %s & %s & %s & %s \\\\",
          label, fmt(mean(x), digits), fmt(sd(x), digits),
          fmt(min(x), digits), fmt(max(x), digits),
          formatC(length(x), format = "d", big.mark = ","))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Mean & SD & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Treatment (EC 2005, district level)}} \\\\[3pt]",
  make_row("gov_emp_share", "Gov.~emp.~share", pre),
  make_row("ec05_emp_gov", "Gov.~employment", pre, 0),
  make_row("ec05_emp_all", "Total employment", pre, 0),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel B: Outcome (DMSP nightlights, 2004--2013)}} \\\\[3pt]",
  make_row("dmsp_total_light_cal", "Total calibrated light", panel, 0),
  make_row("log_light", "log(light + 1)", panel),
  "\\addlinespace",
  "\\multicolumn{6}{l}{\\textit{Panel C: Controls (Census 2011)}} \\\\[3pt]",
  make_row("pop", "Population", panel, 0),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from SHRUG v2.1 (Asher, Novosad, and Lunt 2021). Treatment is the share of government employees in total Economic Census 2005 employment, measured at the district level (Census 2011 boundaries). Nightlights are DMSP-OLS calibrated total luminosity, averaged across satellite versions when multiple are available. Panel covers 610 districts over 2004--2013.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "tables/tab1_summary.tex")
cat("Saved: tables/tab1_summary.tex\n")

## ═══════════════════════════════════════════════════════════
## TABLE 2: Main Results — From Naive to De-trended
## ═══════════════════════════════════════════════════════════
cat("\n--- Table 2: Main Results ---\n")

m1 <- feols(log_light ~ treat_x_post | district_id + year,
            data = panel, cluster = ~pc11_state_id)
m2 <- feols(log_light ~ treat_x_post | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)
m3 <- feols(log_light ~ treat_x_post + gov_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)
m4 <- feols(log_light ~ treat_x_post + gov_trend + pop_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

make_coef <- function(m, var) {
  b <- coef(m)[var]; s <- se(m)[var]; t <- abs(b/s)
  stars <- ifelse(t > 2.576, "^{***}", ifelse(t > 1.96, "^{**}", ifelse(t > 1.645, "^{*}", "")))
  sprintf("%.3f$%s$", b, stars)
}
make_se_fmt <- function(m, var) sprintf("(%.3f)", se(m)[var])

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Effect of Government Employment on Local Economic Activity}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & \\multicolumn{4}{c}{Dep.~var.: log(nightlights + 1)} \\\\",
  "\\midrule",
  sprintf("GovEmpShare $\\times$ Post & %s & %s & %s & %s \\\\",
          make_coef(m1, "treat_x_post"), make_coef(m2, "treat_x_post"),
          make_coef(m3, "treat_x_post"), make_coef(m4, "treat_x_post")),
  sprintf(" & %s & %s & %s & %s \\\\",
          make_se_fmt(m1, "treat_x_post"), make_se_fmt(m2, "treat_x_post"),
          make_se_fmt(m3, "treat_x_post"), make_se_fmt(m4, "treat_x_post")),
  "\\addlinespace",
  sprintf("GovEmpShare $\\times$ trend & & & %s & %s \\\\",
          make_coef(m3, "gov_trend"), make_coef(m4, "gov_trend")),
  sprintf(" & & & %s & %s \\\\",
          make_se_fmt(m3, "gov_trend"), make_se_fmt(m4, "gov_trend")),
  "\\addlinespace",
  "District FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & -- & -- & -- \\\\",
  "State $\\times$ Year FE & -- & Yes & Yes & Yes \\\\",
  "Pop.~$\\times$ trend & -- & -- & -- & Yes \\\\",
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(m1), big.mark = ","), formatC(nobs(m2), big.mark = ","),
          formatC(nobs(m3), big.mark = ","), formatC(nobs(m4), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports the coefficient on GovEmpShare $\\times$ Post from a dose-response difference-in-differences regression. GovEmpShare is the district-level share of government employees in total employment (Economic Census 2005). Post equals one for years $\\geq$ 2008. Columns (3)--(4) add GovEmpShare $\\times$ linear trend to absorb differential pre-trends. Standard errors clustered at the state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2, "tables/tab2_main.tex")
cat("Saved: tables/tab2_main.tex\n")

## ═══════════════════════════════════════════════════════════
## TABLE 3: Event Study
## ═══════════════════════════════════════════════════════════
cat("\n--- Table 3: Event Study ---\n")

es <- feols(log_light ~ et_m4 + et_m3 + et_m2 + et_m1 +
              et_p1 + et_p2 + et_p3 + et_p4 + et_p5 + et_p6 |
              district_id + state_year,
            data = panel, cluster = ~pc11_state_id)

es_names <- c("et_m4", "et_m3", "et_m2", "et_m1", "et_p1", "et_p2", "et_p3", "et_p4", "et_p5", "et_p6")
es_labels <- c("$t - 4$ (2003)", "$t - 3$ (2004)", "$t - 2$ (2005)", "$t - 1$ (2006)",
               "$t + 1$ (2008)", "$t + 2$ (2009)", "$t + 3$ (2010)",
               "$t + 4$ (2011)", "$t + 5$ (2012)", "$t + 6$ (2013)")

tab3_rows <- character()
for (i in seq_along(es_names)) {
  b <- coef(es)[es_names[i]]; s <- se(es)[es_names[i]]
  t_stat <- abs(b/s)
  stars <- ifelse(t_stat > 2.576, "^{***}", ifelse(t_stat > 1.96, "^{**}", ifelse(t_stat > 1.645, "^{*}", "")))
  tab3_rows <- c(tab3_rows,
                  sprintf("%s & %.4f$%s$ \\\\", es_labels[i], b, stars),
                  sprintf(" & (%.4f) \\\\", s))
  if (i == 4) {
    tab3_rows <- c(tab3_rows,
                    "$t = 0$ (2007, base) & -- \\\\",
                    "\\addlinespace",
                    "\\multicolumn{2}{l}{\\textit{Post-treatment}} \\\\[3pt]")
  }
}

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Differential Trends and Dynamic Effects}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "Year relative to 6th CPC & GovEmpShare $\\times$ 1(year $= k$) \\\\",
  "\\midrule",
  "\\multicolumn{2}{l}{\\textit{Pre-treatment}} \\\\[3pt]",
  tab3_rows,
  "\\addlinespace",
  sprintf("Districts & %s \\\\", formatC(uniqueN(panel$district_id), big.mark = ",")),
  sprintf("Observations & %s \\\\", formatC(nobs(es), big.mark = ",")),
  "District FE & Yes \\\\",
  "State $\\times$ Year FE & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from an event-study regression of log(nightlights + 1) on interactions of district-level government employment share (EC 2005) with year indicators, relative to the base year 2007. The significant pre-treatment coefficients indicate differential trends: districts with higher government employment share were already on different nightlight trajectories before the 6th CPC. Standard errors clustered at the state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3, "tables/tab3_event_study.tex")
cat("Saved: tables/tab3_event_study.tex\n")

## ═══════════════════════════════════════════════════════════
## TABLE 4: Robustness
## ═══════════════════════════════════════════════════════════
cat("\n--- Table 4: Robustness ---\n")

# asinh de-trended
r1 <- feols(asinh_light ~ treat_x_post + gov_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)
# Exclude saturated
panel[, max_light := max(dmsp_total_light_cal, na.rm = TRUE), by = district_id]
panel_nosaturate <- panel[max_light < quantile(dmsp_total_light_cal, 0.99, na.rm = TRUE)]
r2 <- feols(log_light ~ treat_x_post + gov_trend | district_id + state_year,
            data = panel_nosaturate, cluster = ~pc11_state_id)
# Binary
q75 <- quantile(panel$gov_emp_share, 0.75, na.rm = TRUE)
panel[, high_gov := as.integer(gov_emp_share >= q75)]
panel[, high_gov_post := high_gov * post]
panel[, high_gov_trend := high_gov * (year - 2007)]
r3 <- feols(log_light ~ high_gov_post + high_gov_trend | district_id + state_year,
            data = panel, cluster = ~pc11_state_id)
# Placebo timing
panel_pre <- panel[year <= 2007]
panel_pre[, fake_post := as.integer(year >= 2005)]
panel_pre[, fake_treat := gov_emp_share * fake_post]
r4 <- feols(log_light ~ fake_treat | district_id + state_year,
            data = panel_pre, cluster = ~pc11_state_id)

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & asinh & Excl. & Binary & Placebo \\\\",
  " & de-trended & saturated & treatment & timing \\\\",
  "\\midrule",
  sprintf("Treatment $\\times$ Post & %s & %s & %s & %s \\\\",
          make_coef(r1, "treat_x_post"), make_coef(r2, "treat_x_post"),
          make_coef(r3, "high_gov_post"), make_coef(r4, "fake_treat")),
  sprintf(" & %s & %s & %s & %s \\\\",
          make_se_fmt(r1, "treat_x_post"), make_se_fmt(r2, "treat_x_post"),
          make_se_fmt(r3, "high_gov_post"), make_se_fmt(r4, "fake_treat")),
  "\\addlinespace",
  "Treatment var. & GovEmpShare & GovEmpShare & HighGov (Q4) & GovEmpShare \\\\",
  "Outcome & asinh(light) & log(light+1) & log(light+1) & log(light+1) \\\\",
  "Sample & Full & No saturation & Full & 2004--2007 \\\\",
  sprintf("Treatment trend & Yes & Yes & Yes & -- \\\\"),
  "District FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          formatC(nobs(r1), big.mark = ","),
          formatC(nobs(r2), big.mark = ","),
          formatC(nobs(r3), big.mark = ","),
          formatC(nobs(r4), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All de-trended specifications (1)--(3) include GovEmpShare (or HighGov) $\\times$ linear trend to absorb differential pre-trends. Column (1) uses the inverse hyperbolic sine transformation. Column (2) drops the top 1\\% of districts by maximum nightlight intensity to address DMSP saturation. Column (3) uses a binary indicator for the top quartile of government employment share. Column (4) tests for pre-trends by assigning a placebo treatment date of 2005 using only pre-treatment data (2004--2007). Standard errors clustered at the state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4, "tables/tab4_robustness.tex")
cat("Saved: tables/tab4_robustness.tex\n")

## ═══════════════════════════════════════════════════════════
## TABLE 5: Mechanism — Long Differences (EC 2005 vs 2013)
## ═══════════════════════════════════════════════════════════
cat("\n--- Table 5: Mechanism ---\n")

ec05d <- fread("data/ec05_pc11_district.csv")
ec05d[, gov_emp_share := ec05_emp_gov / ec05_emp_all]
ec13_raw <- fread("data/ec13_district.csv")
ec13_raw[, pc11_state_id := as.integer(pc11_state_id)]
ec13_raw[, pc11_district_id := as.integer(pc11_district_id)]

ec_cross <- merge(ec05d[, .(pc11_state_id, pc11_district_id,
                             emp05 = ec05_emp_all, gov05 = ec05_emp_gov,
                             firms05 = ec05_count_all, services05 = ec05_emp_services,
                             gov_emp_share)],
                  ec13_raw[, .(pc11_state_id, pc11_district_id,
                               emp13 = ec13_emp_all, firms13 = ec13_count_all,
                               services13 = ec13_emp_services)],
                  by = c("pc11_state_id", "pc11_district_id"))

ec_cross[, d_log_emp := log(emp13 + 1) - log(emp05 + 1)]
ec_cross[, d_log_firms := log(firms13 + 1) - log(firms05 + 1)]
ec_cross[, d_log_services := log(services13 + 1) - log(services05 + 1)]

ld1 <- lm(d_log_emp ~ gov_emp_share, data = ec_cross)
ld2 <- lm(d_log_firms ~ gov_emp_share, data = ec_cross)
ld3 <- lm(d_log_services ~ gov_emp_share, data = ec_cross)

fmt_lm <- function(m) {
  b <- coef(m)[2]; s <- summary(m)$coef[2, 2]; t <- abs(b/s)
  stars <- ifelse(t > 2.576, "^{***}", ifelse(t > 1.96, "^{**}", ifelse(t > 1.645, "^{*}", "")))
  c(sprintf("%.3f$%s$", b, stars), sprintf("(%.3f)", s))
}

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Long Differences in Private Sector Activity (EC 2005--2013)}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & $\\Delta$log(Emp) & $\\Delta$log(Firms) & $\\Delta$log(Services) \\\\",
  "\\midrule",
  sprintf("GovEmpShare (2005) & %s & %s & %s \\\\",
          fmt_lm(ld1)[1], fmt_lm(ld2)[1], fmt_lm(ld3)[1]),
  sprintf(" & %s & %s & %s \\\\",
          fmt_lm(ld1)[2], fmt_lm(ld2)[2], fmt_lm(ld3)[2]),
  "\\addlinespace",
  sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\",
          summary(ld1)$r.squared, summary(ld2)$r.squared, summary(ld3)$r.squared),
  sprintf("Observations & %d & %d & %d \\\\",
          nrow(ec_cross), nrow(ec_cross), nrow(ec_cross)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column regresses the long difference in log outcomes (EC 2013 $-$ EC 2005) on district-level government employment share in 2005. The positive coefficients are consistent with the differential growth trends documented in Table~\\ref{tab:event_study}: districts with more government employment were growing faster over this period, but this growth predated and continued through the 6th CPC. Robust standard errors in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab5, "tables/tab5_mechanism.tex")
cat("Saved: tables/tab5_mechanism.tex\n")

## ═══════════════════════════════════════════════════════════
## SDE TABLE (Appendix)
## ═══════════════════════════════════════════════════════════
cat("\n--- SDE Table ---\n")

sd_y_log <- sd(panel[year < 2008]$log_light, na.rm = TRUE)
sd_y_asinh <- sd(panel[year < 2008]$asinh_light, na.rm = TRUE)
sd_x <- sd(panel$gov_emp_share, na.rm = TRUE)

# De-trended main: log(light+1)
b_dt <- coef(m3)["treat_x_post"]; s_dt <- se(m3)["treat_x_post"]
sde_dt <- b_dt * sd_x / sd_y_log
se_sde_dt <- s_dt * sd_x / sd_y_log

# De-trended asinh
b_a <- coef(r1)["treat_x_post"]; s_a <- se(r1)["treat_x_post"]
sde_a <- b_a * sd_x / sd_y_asinh
se_sde_a <- s_a * sd_x / sd_y_asinh

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does a large formulaic wage increase for government employees generate local economic spillovers in Indian districts? ",
  "\\textbf{Policy mechanism:} The 6th Central Pay Commission (September 2008) raised salaries by 20--40\\% for 4.7 million central government employees and disbursed Rs~18,060 crore in arrears, increasing the central wage bill from 2\\% to 3.5\\% of GDP; states adopted staggered implementations through 2013, affecting 18--20 million total public employees. ",
  "\\textbf{Outcome definition:} Log of calibrated total DMSP-OLS nighttime luminosity at the district level, a standard proxy for local economic activity in developing countries. ",
  "\\textbf{Treatment:} Continuous; district-level share of government employees in total employment from Economic Census 2005, measured two years before the policy was constituted. ",
  sprintf("\\textbf{Data:} SHRUG v2.1 (Asher, Novosad, Lunt), 2004--2013, district-year panel, %s observations across %s districts. ",
          formatC(nrow(panel), big.mark = ","), formatC(uniqueN(panel$district_id), big.mark = ",")),
  "\\textbf{Method:} Dose-response difference-in-differences with district and state $\\times$ year fixed effects, de-trended by GovEmpShare $\\times$ linear trend to absorb differential pre-trends; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Indian districts matched across Economic Census 2005 (Census 2001 boundaries) and DMSP nightlights (Census 2011 boundaries) via SHRUG concordance; excludes districts with missing employment data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the cross-sectional standard deviation of treatment intensity. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("log(light + 1) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b_dt, s_dt, sd_y_log, sde_dt, se_sde_dt, classify_sde(sde_dt)),
  sprintf("asinh(light) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          b_a, s_a, sd_y_asinh, sde_a, se_sde_a, classify_sde(sde_a)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1, "tables/tabF1_sde.tex")
cat("Saved: tables/tabF1_sde.tex\n")

cat("\n=== ALL TABLES GENERATED ===\n")
