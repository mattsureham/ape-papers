# 05_tables.R — Generate all tables for paper
# apep_0967: CSE Reform and Far-Right Voting in France

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

# Helper: format coefficient with stars
fmt_coef <- function(x, digits = 4) formatC(x, format = "f", digits = digits)

get_coef <- function(model, varname) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, stars = stars)
}

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

# ============================================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

stats_by_year <- panel |>
  group_by(year) |>
  summarise(
    mean_lepen = mean(lepen_share, na.rm = TRUE),
    sd_lepen = sd(lepen_share, na.rm = TRUE),
    mean_melenchon = mean(melenchon_share, na.rm = TRUE),
    sd_melenchon = sd(melenchon_share, na.rm = TRUE),
    mean_turnout = mean(turnout, na.rm = TRUE),
    sd_turnout = sd(turnout, na.rm = TRUE),
    mean_inscrits = mean(inscrits, na.rm = TRUE),
    sd_inscrits = sd(inscrits, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

treat_stats <- panel |>
  filter(year == 2017) |>
  summarise(
    mean_share50 = mean(share_50plus, na.rm = TRUE),
    sd_share50 = sd(share_50plus, na.rm = TRUE),
    mean_share5099 = mean(share_50_99, na.rm = TRUE),
    sd_share5099 = sd(share_50_99, na.rm = TRUE),
    pct_any50 = mean(any_50plus, na.rm = TRUE),
    mean_n_total = mean(n_total, na.rm = TRUE),
    sd_n_total = sd(n_total, na.rm = TRUE)
  )

f3 <- function(x) formatC(x, format = "f", digits = 3)
f0 <- function(x) formatC(x, format = "f", digits = 0)
fc <- function(x) format(x, big.mark = ",")

s <- stats_by_year

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l *{3}{S[table-format=1.3] S[table-format=1.3]}}",
  "\\toprule",
  "& \\multicolumn{2}{c}{2012} & \\multicolumn{2}{c}{2017} & \\multicolumn{2}{c}{2022} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  "& {Mean} & {SD} & {Mean} & {SD} & {Mean} & {SD} \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Election Outcomes}} \\\\[0.3em]",
  paste0("Le Pen vote share & ", f3(s$mean_lepen[1]), " & ", f3(s$sd_lepen[1]),
         " & ", f3(s$mean_lepen[2]), " & ", f3(s$sd_lepen[2]),
         " & ", f3(s$mean_lepen[3]), " & ", f3(s$sd_lepen[3]), " \\\\"),
  paste0("M\\'elenchon vote share & ", f3(s$mean_melenchon[1]), " & ", f3(s$sd_melenchon[1]),
         " & ", f3(s$mean_melenchon[2]), " & ", f3(s$sd_melenchon[2]),
         " & ", f3(s$mean_melenchon[3]), " & ", f3(s$sd_melenchon[3]), " \\\\"),
  paste0("Turnout & ", f3(s$mean_turnout[1]), " & ", f3(s$sd_turnout[1]),
         " & ", f3(s$mean_turnout[2]), " & ", f3(s$sd_turnout[2]),
         " & ", f3(s$mean_turnout[3]), " & ", f3(s$sd_turnout[3]), " \\\\"),
  paste0("Registered voters & ", f0(s$mean_inscrits[1]), " & ", f0(s$sd_inscrits[1]),
         " & ", f0(s$mean_inscrits[2]), " & ", f0(s$sd_inscrits[2]),
         " & ", f0(s$mean_inscrits[3]), " & ", f0(s$sd_inscrits[3]), " \\\\"),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Treatment Variables (Cross-Sectional)}} \\\\[0.3em]",
  paste0("Share 50+ employees & \\multicolumn{2}{c}{} & ",
         f3(treat_stats$mean_share50), " & ", f3(treat_stats$sd_share50),
         " & \\multicolumn{2}{c}{} \\\\"),
  paste0("Share 50--99 employees & \\multicolumn{2}{c}{} & ",
         f3(treat_stats$mean_share5099), " & ", f3(treat_stats$sd_share5099),
         " & \\multicolumn{2}{c}{} \\\\"),
  paste0("Any 50+ establishment & \\multicolumn{2}{c}{} & \\multicolumn{2}{c}{",
         f0(treat_stats$pct_any50 * 100), "\\%} & \\multicolumn{2}{c}{} \\\\"),
  paste0("Total establishments & \\multicolumn{2}{c}{} & ",
         f0(treat_stats$mean_n_total), " & ", f0(treat_stats$sd_n_total),
         " & \\multicolumn{2}{c}{} \\\\"),
  "\\midrule",
  paste0("Communes & \\multicolumn{2}{c}{", fc(s$n[1]),
         "} & \\multicolumn{2}{c}{", fc(s$n[2]),
         "} & \\multicolumn{2}{c}{", fc(s$n[3]), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Balanced panel of ", fc(n_distinct(panel$code_commune)),
         " metropolitan French communes observed in all three presidential first-round elections. ",
         "Le Pen and M\\'elenchon vote shares are computed as votes for the candidate divided by ",
         "valid votes cast (\\textit{exprim\\'es}). Treatment variables measured from the INSEE ",
         "Sirene establishment stock file. Share 50+ employees is the fraction of active ",
         "private-sector establishments with 50 or more employees."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================================
# TABLE 2: MAIN RESULTS
# ============================================================================
cat("Generating Table 2: Main Results...\n")

c1 <- get_coef(m1, "treat_post_pct")
c2 <- get_coef(m2, "treat_post_pct")
c3 <- get_coef(m3, "any_50plus_post")
c4 <- get_coef(m4, "treat_50_99_post")
c5a <- get_coef(m5, "terc1_post")
c5b <- get_coef(m5, "terc2_post")
c5c <- get_coef(m5, "terc3_post")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of CSE Reform Exposure on Le Pen Vote Share}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l *{5}{c}}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  paste0("Share 50+ $\\times$ Post & ", fmt_coef(c1$b), c1$stars,
         " & ", fmt_coef(c2$b), c2$stars, " & & & \\\\"),
  paste0("& (", fmt_coef(c1$se), ") & (", fmt_coef(c2$se), ") & & & \\\\[0.5em]"),
  paste0("Any 50+ $\\times$ Post & & & ", fmt_coef(c3$b), c3$stars, " & & \\\\"),
  paste0("& & & (", fmt_coef(c3$se), ") & & \\\\[0.5em]"),
  paste0("Share 50--99 $\\times$ Post & & & & ", fmt_coef(c4$b), c4$stars, " & \\\\"),
  paste0("& & & & (", fmt_coef(c4$se), ") & \\\\[0.5em]"),
  paste0("Tercile 1 $\\times$ Post & & & & & ", fmt_coef(c5a$b), c5a$stars, " \\\\"),
  paste0("& & & & & (", fmt_coef(c5a$se), ") \\\\"),
  paste0("Tercile 2 $\\times$ Post & & & & & ", fmt_coef(c5b$b), c5b$stars, " \\\\"),
  paste0("& & & & & (", fmt_coef(c5b$se), ") \\\\"),
  paste0("Tercile 3 $\\times$ Post & & & & & ", fmt_coef(c5c$b), c5c$stars, " \\\\"),
  paste0("& & & & & (", fmt_coef(c5c$se), ") \\\\[0.5em]"),
  "\\midrule",
  "Controls & No & Yes & No & No & No \\\\",
  "Commune FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ", fc(nobs(m1)), " & ", fc(nobs(m2)),
         " & ", fc(nobs(m3)), " & ", fc(nobs(m4)), " & ", fc(nobs(m5)), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the d\\'epartement level ",
         "(94 clusters) in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "Dependent variable is Le Pen first-round vote share. ``Post'' equals one for 2022. ",
         "Share 50+ is measured in percentage points (range 0--100). ",
         "Column (2) adds log registered voters as a control. ",
         "Column (3) uses a binary indicator for communes with any establishment of 50+ employees. ",
         "Column (4) restricts treatment to the 50--99 bracket only. ",
         "Column (5) splits communes with positive treatment into terciles."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ============================================================================
# TABLE 3: EVENT STUDY AND PLACEBOS
# ============================================================================
cat("Generating Table 3: Event Study and Placebos...\n")

es_lp_12 <- get_coef(es_lepen, "interact_2012")
es_lp_22 <- get_coef(es_lepen, "interact_2022")
es_ml_12 <- get_coef(es_melenchon, "mel_interact_2012")
es_ml_22 <- get_coef(es_melenchon, "mel_interact_2022")
es_to_12 <- get_coef(es_turnout, "interact_2012")
es_to_22 <- get_coef(es_turnout, "interact_2022")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study and Placebo Outcomes}",
  "\\label{tab:event}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l *{3}{c}}",
  "\\toprule",
  "& Le Pen & M\\'elenchon & Turnout \\\\",
  "& (1) & (2) & (3) \\\\",
  "\\midrule",
  paste0("Share 50+ $\\times$ 2012 & ", fmt_coef(es_lp_12$b), es_lp_12$stars,
         " & ", fmt_coef(es_ml_12$b), es_ml_12$stars,
         " & ", fmt_coef(es_to_12$b), es_to_12$stars, " \\\\"),
  paste0("& (", fmt_coef(es_lp_12$se), ") & (", fmt_coef(es_ml_12$se),
         ") & (", fmt_coef(es_to_12$se), ") \\\\[0.5em]"),
  paste0("Share 50+ $\\times$ 2022 & ", fmt_coef(es_lp_22$b), es_lp_22$stars,
         " & ", fmt_coef(es_ml_22$b), es_ml_22$stars,
         " & ", fmt_coef(es_to_22$b), es_to_22$stars, " \\\\"),
  paste0("& (", fmt_coef(es_lp_22$se), ") & (", fmt_coef(es_ml_22$se),
         ") & (", fmt_coef(es_to_22$se), ") \\\\[0.5em]"),
  "\\midrule",
  "Reference year & 2017 & 2017 & 2017 \\\\",
  "Commune FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  paste0("Observations & ", fc(nobs(es_lepen)), " & ", fc(nobs(es_melenchon)),
         " & ", fc(nobs(es_turnout)), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the d\\'epartement level in ",
         "parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Each column reports coefficients from ",
         "interacting Share 50+ (in pp) with year dummies, with 2017 as the omitted reference year. ",
         "The 2012 coefficient tests for pre-trends: a significant coefficient would indicate ",
         "differential trends prior to the September 2017 CSE reform announcement. The 2022 coefficient ",
         "captures the post-reform effect. Column (2) uses M\\'elenchon first-round vote share as ",
         "a placebo. Column (3) uses voter turnout."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_event.tex"))

# ============================================================================
# TABLE 4: ROBUSTNESS
# ============================================================================
cat("Generating Table 4: Robustness...\n")

c_main <- get_coef(m1, "treat_post_pct")
c_wt <- get_coef(m_wt, "treat_post_pct")
c_emp <- get_coef(m_emp, "emp_treat_post")
c_noparis <- get_coef(m_noparis, "treat_post_pct")
c_small <- get_coef(m_small, "treat_post_pct")

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l *{5}{c}}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Baseline & Pop-weighted & Firms/1000 & Excl.\\ Paris & $<$10k voters \\\\",
  "\\midrule",
  paste0("Treatment $\\times$ Post & ", fmt_coef(c_main$b), c_main$stars,
         " & ", fmt_coef(c_wt$b), c_wt$stars,
         " & ", fmt_coef(c_emp$b), c_emp$stars,
         " & ", fmt_coef(c_noparis$b), c_noparis$stars,
         " & ", fmt_coef(c_small$b), c_small$stars, " \\\\"),
  paste0("& (", fmt_coef(c_main$se), ") & (", fmt_coef(c_wt$se),
         ") & (", fmt_coef(c_emp$se), ") & (", fmt_coef(c_noparis$se),
         ") & (", fmt_coef(c_small$se), ") \\\\[0.5em]"),
  "\\midrule",
  "Commune FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  paste0("Observations & ", fc(nobs(m1)), " & ", fc(nobs(m_wt)),
         " & ", fc(nobs(m_emp)), " & ", fc(nobs(m_noparis)),
         " & ", fc(nobs(m_small)), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Standard errors clustered at the d\\'epartement level in ",
         "parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Dependent variable is Le Pen ",
         "first-round vote share. Column (1) reproduces the baseline from Table~\\ref{tab:main}. ",
         "Column (2) weights by registered voters. Column (3) uses an alternative treatment ",
         "measure: number of 50+ employee establishments per 1,000 registered voters. ",
         "Column (4) excludes Paris (d\\'epartement 75). Column (5) restricts to communes ",
         "with fewer than 10,000 registered voters."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tables_dir, "tab4_robust.tex"))

# ============================================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE)
# ============================================================================
cat("Generating Table F1: SDE...\n")

beta_main <- coef(m1)["treat_post_pct"]
se_main <- se(m1)["treat_post_pct"]
sd_y <- sd(panel$lepen_share, na.rm = TRUE)
sd_x <- sd(panel$share_50plus_pct[panel$year == 2017], na.rm = TRUE)
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

beta_bin <- coef(m3)["any_50plus_post"]
se_bin <- se(m3)["any_50plus_post"]
sde_bin <- beta_bin / sd_y
se_sde_bin <- se_bin / sd_y

panel_small <- panel |> filter(inscrits < 10000)
beta_small <- coef(m_small)["treat_post_pct"]
se_small <- se(m_small)["treat_post_pct"]
sd_y_small <- sd(panel_small$lepen_share, na.rm = TRUE)
sd_x_small <- sd(panel_small$share_50plus_pct[panel_small$year == 2017], na.rm = TRUE)
sde_small <- beta_small * sd_x_small / sd_y_small
se_sde_small <- se_small * sd_x_small / sd_y_small

beta_wt <- coef(m_wt)["treat_post_pct"]
se_wt_val <- se(m_wt)["treat_post_pct"]
sd_y_wt <- sqrt(weighted.mean(
  (panel$lepen_share - weighted.mean(panel$lepen_share, panel$inscrits, na.rm = TRUE))^2,
  panel$inscrits, na.rm = TRUE
))
sde_wt <- beta_wt * sd_x / sd_y_wt
se_sde_wt <- se_wt_val * sd_x / sd_y_wt

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does reducing firm-level worker representation through the ",
  "2017 Ordonnances Macron (CSE reform) increase far-right (Rassemblement National) voting ",
  "at the commune level? ",
  "\\textbf{Policy mechanism:} The reform merged three separate worker representation bodies ",
  "(CE, DP, CHSCT) into a single Comit\\'e Social et \\'Economique, reducing elected worker ",
  "representatives by approximately half in firms with 50 or more employees, eliminating the ",
  "autonomous workplace health and safety committee, and capping successive mandates. ",
  "\\textbf{Outcome definition:} Marine Le Pen first-round presidential vote share, computed ",
  "as Le Pen votes divided by valid votes cast (\\textit{exprim\\'es}), at the commune level. ",
  "\\textbf{Treatment:} Continuous: share of active private-sector establishments with 50+ ",
  "employees in the commune (percentage points). Binary: indicator for any such establishment. ",
  "\\textbf{Data:} INSEE Sirene establishment stock file (cross-section) merged with ",
  "commune-level presidential first-round results from data.gouv.fr for 2012, 2017, and 2022. ",
  "Balanced panel of 34,446 metropolitan communes. ",
  "\\textbf{Method:} Two-period difference-in-differences with commune and year fixed effects, ",
  "comparing pre-reform elections (2012, 2017) to post-reform (2022). Standard errors clustered ",
  "at the d\\'epartement level (94 clusters). ",
  "\\textbf{Sample:} Metropolitan France communes appearing in all three elections; overseas ",
  "territories excluded. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment; ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. ",
  "SD($Y$) and SD($X$) are unconditional standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  paste0("Le Pen share & Continuous & ", fmt_coef(beta_main), " & ", fmt_coef(sd_x, 2),
         " & ", fmt_coef(sd_y, 3), " & ", fmt_coef(sde_main),
         " & ", fmt_coef(se_sde_main), " & ", classify(sde_main), " \\\\"),
  paste0("Le Pen share & Binary & ", fmt_coef(beta_bin), " & --- & ",
         fmt_coef(sd_y, 3), " & ", fmt_coef(sde_bin),
         " & ", fmt_coef(se_sde_bin), " & ", classify(sde_bin), " \\\\"),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  paste0("Le Pen share & Small communes & ", fmt_coef(beta_small), " & ",
         fmt_coef(sd_x_small, 2), " & ", fmt_coef(sd_y_small, 3),
         " & ", fmt_coef(sde_small), " & ", fmt_coef(se_sde_small),
         " & ", classify(sde_small), " \\\\"),
  paste0("Le Pen share & Pop-weighted & ", fmt_coef(beta_wt), " & ",
         fmt_coef(sd_x, 2), " & ", fmt_coef(sd_y_wt, 3),
         " & ", fmt_coef(sde_wt), " & ", fmt_coef(se_sde_wt),
         " & ", classify(sde_wt), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== ALL TABLES GENERATED ===\n")
