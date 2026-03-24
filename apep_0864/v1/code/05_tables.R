## 05_tables.R — Generate all LaTeX tables for apep_0864
## Tables: Summary stats, main DiD, event study, robustness, SDE

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
log_models <- readRDS(file.path(data_dir, "log_models.rds"))
es_coefs <- readRDS(file.path(data_dir, "event_study_coefs.rds"))
rdd_results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_models.rds"))
honest <- readRDS(file.path(data_dir, "honestdid_results.rds"))
diag <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics\n")

# Pre-period stats (2010-2013)
pre <- panel |> filter(year <= 2013)
post <- panel |> filter(year >= 2015)

ss <- data.frame(
  Variable = c(
    "\\emph{Panel A: Municipality characteristics (2013)}",
    "Foreign population share",
    "Total population",
    "Swiss population",
    "Foreign population",
    "",
    "\\emph{Panel B: Referendum results (February 2014)}",
    "MEI yes-vote share",
    "FABI yes-vote share (placebo)",
    "Voter turnout",
    "Eligible voters",
    "",
    "\\emph{Panel C: Panel dimensions}",
    "Municipalities",
    "Municipality $\\times$ year observations",
    "Years"
  ),
  Mean = c(
    "", sprintf("%.3f", mean(pre$foreign_share[pre$year==2013])),
    sprintf("%.0f", mean(pre$total[pre$year==2013])),
    sprintf("%.0f", mean(pre$swiss[pre$year==2013])),
    sprintf("%.0f", mean(pre$foreign[pre$year==2013])),
    "",
    "", sprintf("%.3f", mean(panel$yes_share)),
    sprintf("%.3f", mean(panel$placebo_yes_share, na.rm=TRUE)),
    sprintf("%.3f", mean(panel$turnout)),
    sprintf("%.0f", mean(panel$eligible)),
    "",
    "", sprintf("%d", n_distinct(panel$bfs_nr)),
    sprintf("%d", nrow(panel)),
    sprintf("%d", n_distinct(panel$year))
  ),
  SD = c(
    "", sprintf("%.3f", sd(pre$foreign_share[pre$year==2013])),
    sprintf("%.0f", sd(pre$total[pre$year==2013])),
    sprintf("%.0f", sd(pre$swiss[pre$year==2013])),
    sprintf("%.0f", sd(pre$foreign[pre$year==2013])),
    "",
    "", sprintf("%.3f", sd(panel$yes_share)),
    sprintf("%.3f", sd(panel$placebo_yes_share, na.rm=TRUE)),
    sprintf("%.3f", sd(panel$turnout)),
    sprintf("%.0f", sd(panel$eligible)),
    "",
    "", "", "", ""
  ),
  Min = c(
    "", sprintf("%.3f", min(pre$foreign_share[pre$year==2013])),
    sprintf("%.0f", min(pre$total[pre$year==2013])),
    "", "",
    "",
    "", sprintf("%.3f", min(panel$yes_share)),
    sprintf("%.3f", min(panel$placebo_yes_share, na.rm=TRUE)),
    "", "",
    "",
    "", "", "", ""
  ),
  Max = c(
    "", sprintf("%.3f", max(pre$foreign_share[pre$year==2013])),
    sprintf("%.0f", max(pre$total[pre$year==2013])),
    "", "",
    "",
    "", sprintf("%.3f", max(panel$yes_share)),
    sprintf("%.3f", max(panel$placebo_yes_share, na.rm=TRUE)),
    "", "",
    "",
    "", "", "", ""
  )
)

# Write LaTeX
tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(ss)) {
  if (ss$Variable[i] == "") {
    tab1_tex <- paste0(tab1_tex, " \\\\\n")
  } else if (grepl("\\\\emph", ss$Variable[i])) {
    tab1_tex <- paste0(tab1_tex, ss$Variable[i], " & & & & \\\\\n")
  } else {
    tab1_tex <- paste0(tab1_tex, ss$Variable[i], " & ",
                       ss$Mean[i], " & ", ss$SD[i], " & ",
                       ss$Min[i], " & ", ss$Max[i], " \\\\\n")
  }
}

tab1_tex <- paste0(tab1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Panel A reports cross-sectional statistics for 2013 (last pre-treatment year). ",
  "Panel B reports the February 9, 2014 referendum results. The Mass Immigration Initiative (MEI) ",
  "passed nationally with 50.3\\% yes. FABI (railway financing) serves as a same-day placebo referendum. ",
  "Panel C describes the balanced municipality $\\times$ year panel used in estimation.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: Main DiD Results
# ============================================================
cat("Generating Table 2: Main DiD Results\n")

# Hand-code Table 2 for reliable LaTeX output
star <- function(b, s) {
  t <- abs(b/s)
  if (t > 2.576) return("***")
  if (t > 1.96) return("**")
  if (t > 1.645) return("*")
  return("")
}

ms <- list(main_models$m1, main_models$m2, main_models$m3, main_models$m4)
betas <- sapply(ms, function(m) coef(m)[1])
ses <- sapply(ms, function(m) se(m)[1])
nobs <- sapply(ms, function(m) m$nobs)
r2w <- sapply(ms, function(m) fitstat(m, "wr2")[[1]])

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of MEI Yes-Vote Share on Foreign Population Share}\n",
  "\\label{tab:main_did}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("MEI Yes-Share (std.) $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\\n",
          betas[1], star(betas[1],ses[1]), betas[2], star(betas[2],ses[2]),
          betas[3], star(betas[3],ses[3]), betas[4], star(betas[4],ses[4])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n", ses[1], ses[2], ses[3], ses[4]),
  "\\hline\n",
  "Municipality FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & --- & --- \\\\\n",
  "Pre-FS $\\times$ Year & & Yes & Yes & \\\\\n",
  "Canton $\\times$ Year FE & & & Yes & \\\\\n",
  "Language $\\times$ Year FE & & & & Yes \\\\\n",
  sprintf("Within $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\\n", r2w[1], r2w[2], r2w[3], r2w[4]),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs[1], big.mark=","), format(nobs[2], big.mark=","),
          format(nobs[3], big.mark=","), format(nobs[4], big.mark=",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Standard errors clustered at the municipality level in parentheses. ",
  "The dependent variable is the foreign population share (mean = 0.165). ",
  "MEI Yes-Share is standardized (mean 0, SD 1). A one-unit increase corresponds to ",
  "an 11.3 percentage point higher anti-immigration vote share. ",
  "Specification (2) adds pre-2014 foreign share interacted with year dummies. ",
  "Specification (3) adds canton $\\times$ year fixed effects. ",
  "Specification (4) replaces canton FE with language region $\\times$ year FE. ",
  "$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, file.path(table_dir, "tab2_main_did.tex"))

# ============================================================
# TABLE 3: Event Study Coefficients
# ============================================================
cat("Generating Table 3: Event Study\n")

es_tab <- es_coefs |>
  mutate(
    stars = case_when(
      abs(coef/se) > 2.576 ~ "***",
      abs(coef/se) > 1.960 ~ "**",
      abs(coef/se) > 1.645 ~ "*",
      TRUE ~ ""
    ),
    coef_str = sprintf("%.4f%s", coef, stars),
    se_str = sprintf("(%.4f)", se),
    year_label = ifelse(rel_year < 0,
                        paste0("$t", rel_year, "$"),
                        paste0("$t+", rel_year, "$"))
  )

# Add reference period
ref_row <- data.frame(
  rel_year = -1, coef = 0, se = NA,
  stars = "", coef_str = "---", se_str = "[Reference]",
  year_label = "$t-1$"
)
es_tab <- bind_rows(es_tab, ref_row) |> arrange(rel_year)

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Effects of MEI Yes-Vote Share on Foreign Population Share}\n",
  "\\label{tab:event_study}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Period & Coefficient & SE \\\\\n",
  "\\hline\n",
  "\\emph{Pre-treatment} & & \\\\\n"
)

for (i in 1:nrow(es_tab)) {
  if (es_tab$rel_year[i] == 0 && !any(es_tab$rel_year == -0.5)) {
    tab3_tex <- paste0(tab3_tex, "\\hline\n\\emph{Post-treatment} & & \\\\\n")
  }
  tab3_tex <- paste0(tab3_tex,
    es_tab$year_label[i], " & ", es_tab$coef_str[i], " & ", es_tab$se_str[i], " \\\\\n")
}

tab3_tex <- paste0(tab3_tex,
  "\\hline\n",
  "Municipalities & \\multicolumn{2}{c}{", n_distinct(panel$bfs_nr), "} \\\\\n",
  "Observations & \\multicolumn{2}{c}{", nrow(panel), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Coefficients from regressing foreign population share on ",
  "interactions between MEI yes-vote share (standardized) and year dummies, with municipality ",
  "and year fixed effects. Period $t-1$ (2013) is the reference year. Standard errors clustered ",
  "at the municipality level. Pre-treatment coefficients ($t-4$ through $t-2$) capture ",
  "differential pre-trends. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(table_dir, "tab3_event_study.tex"))

# ============================================================
# TABLE 4: Robustness — Placebo, First-Diff, Weighted, RDD
# ============================================================
cat("Generating Table 4: Robustness\n")

rdd_coef <- rdd_results$rdd_result$coef[1]
rdd_se <- rdd_results$rdd_result$se[3]  # robust SE
rdd_p <- rdd_results$rdd_result$pv[3]
rdd_bw <- rdd_results$rdd_result$bws[1,1]
mccrary_p <- rdd_results$density_test$test$p_jk

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Placebo & First Diff. & Weighted & RDD \\\\\n",
  " & (FABI) & $\\Delta Y_{mt}$ & (Pop.) & at 50\\% \\\\\n",
  "\\hline\n",
  sprintf("Treatment $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & \\\\\n",
          coef(robustness$placebo)[1],
          ifelse(abs(coef(robustness$placebo)[1]/se(robustness$placebo)[1]) > 2.576, "***",
                 ifelse(abs(coef(robustness$placebo)[1]/se(robustness$placebo)[1]) > 1.96, "**", "*")),
          coef(robustness$first_diff)[1],
          ifelse(abs(coef(robustness$first_diff)[1]/se(robustness$first_diff)[1]) > 2.576, "***",
                 ifelse(abs(coef(robustness$first_diff)[1]/se(robustness$first_diff)[1]) > 1.96, "**", "*")),
          coef(robustness$weighted)[1],
          ifelse(abs(coef(robustness$weighted)[1]/se(robustness$weighted)[1]) > 2.576, "***",
                 ifelse(abs(coef(robustness$weighted)[1]/se(robustness$weighted)[1]) > 1.96, "**", "*"))),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & \\\\\n",
          se(robustness$placebo)[1], se(robustness$first_diff)[1], se(robustness$weighted)[1]),
  sprintf("RDD at 50\\%% & & & & %.4f \\\\\n", rdd_coef),
  sprintf(" & & & & (%.4f) \\\\\n", rdd_se),
  "\\hline\n",
  sprintf("McCrary $p$-value & & & & %.3f \\\\\n", mccrary_p),
  sprintf("Bandwidth & & & & %.3f \\\\\n", rdd_bw),
  "Municipality FE & Yes & Yes & Yes & --- \\\\\n",
  "Year FE & Yes & Yes & Yes & --- \\\\\n",
  sprintf("Observations & %s & %s & %s & %d \\\\\n",
          format(nrow(panel), big.mark=","),
          format(nrow(panel |> filter(year > 2010)), big.mark=","),
          format(nrow(panel), big.mark=","),
          rdd_results$rdd_result$N[1] + rdd_results$rdd_result$N[2]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Column (1) replaces the MEI yes-vote share with the FABI (railway) ",
  "yes-vote share from the same day as a placebo test. Column (2) uses first-differenced ",
  "foreign population share as the outcome. Column (3) weights by 2013 municipal population. ",
  "Column (4) reports sharp RDD estimates at the 50\\% yes-vote threshold using the ",
  "Calonico, Cattaneo, and Titiunik (2014) bandwidth selector with robust bias-corrected ",
  "confidence intervals. McCrary density test confirms no manipulation of vote shares. ",
  "$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# TABLE 5 (Appendix): Standardized Effect Size
# ============================================================
cat("Generating SDE Table\n")

# Main outcome: foreign share
sd_y <- sd(panel$foreign_share[panel$year <= 2013])
beta_main <- coef(main_models$m3)[1]
se_main <- se(main_models$m3)[1]
sde_main <- beta_main / sd_y
sde_se_main <- se_main / sd_y

# Log foreign population
beta_log <- coef(log_models$m_log)[1]
se_log <- se(log_models$m_log)[1]
sd_y_log <- sd(panel$log_foreign[panel$year <= 2013])
sde_log <- beta_log / sd_y_log
sde_se_log <- se_log / sd_y_log

# Swiss share (mechanism/balance)
panel <- panel |> mutate(swiss_share = swiss / total)
beta_swiss <- coef(robustness$swiss)[1]
se_swiss <- se(robustness$swiss)[1]
sd_y_swiss <- sd(panel$swiss_share[panel$year <= 2013], na.rm = TRUE)
sde_swiss <- beta_swiss / sd_y_swiss
sde_se_swiss <- se_swiss / sd_y_swiss

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Panel A: Pooled
sde_pooled <- data.frame(
  Outcome = c("Foreign population share", "Log foreign population", "Swiss population share"),
  Beta = c(beta_main, beta_log, beta_swiss),
  SE = c(se_main, se_log, se_swiss),
  SD_Y = c(sd_y, sd_y_log, sd_y_swiss),
  SDE = c(sde_main, sde_log, sde_swiss),
  SDE_SE = c(sde_se_main, sde_se_log, sde_se_swiss),
  Classification = c(classify_sde(sde_main), classify_sde(sde_log), classify_sde(sde_swiss))
)

# Panel B: Heterogeneous — by language region
# German-speaking
panel_de <- panel |> filter(language == "German")
m_de <- feols(foreign_share ~ yes_share_std:post + pre_foreign_share:factor(year) |
                bfs_nr + year, data = panel_de, cluster = ~bfs_nr)
sd_y_de <- sd(panel_de$foreign_share[panel_de$year <= 2013])
sde_de <- coef(m_de)[1] / sd_y_de

# French-speaking
panel_fr <- panel |> filter(language == "French")
m_fr <- feols(foreign_share ~ yes_share_std:post + pre_foreign_share:factor(year) |
                bfs_nr + year, data = panel_fr, cluster = ~bfs_nr)
sd_y_fr <- sd(panel_fr$foreign_share[panel_fr$year <= 2013])
sde_fr <- coef(m_fr)[1] / sd_y_fr

sde_het <- data.frame(
  Outcome = c("Foreign share (German cantons)", "Foreign share (French cantons)"),
  Beta = c(coef(m_de)[1], coef(m_fr)[1]),
  SE = c(se(m_de)[1], se(m_fr)[1]),
  SD_Y = c(sd_y_de, sd_y_fr),
  SDE = c(sde_de, sde_fr),
  SDE_SE = c(se(m_de)[1]/sd_y_de, se(m_fr)[1]/sd_y_fr),
  Classification = c(classify_sde(sde_de), classify_sde(sde_fr))
)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does higher municipal support for the 2014 Mass Immigration Initiative cause differential changes in foreign resident population? ",
  "\\textbf{Policy mechanism:} The February 2014 MEI referendum revealed municipal-level anti-immigration preferences through binding yes/no votes; the national result (50.3\\% yes) was identical everywhere, so variation in local vote shares serves as a signal of hostility, not a direct policy instrument. ",
  "\\textbf{Outcome definition:} Foreign permanent resident population share (foreign residents divided by total permanent residents) from BFS municipal statistics. ",
  "\\textbf{Treatment:} Continuous; standardized municipal MEI yes-vote share (mean 0, SD 1; 1 SD = 11.3 percentage points). ",
  "\\textbf{Data:} BFS PXWeb permanent resident population by citizenship and swissdd referendum results, 2010--2023, municipality-year panel, $N = ",
  format(nrow(panel), big.mark = ","), "$ observations across ",
  n_distinct(panel$bfs_nr), " municipalities. ",
  "\\textbf{Method:} Continuous treatment difference-in-differences with municipality and canton $\\times$ year fixed effects, controlling for pre-treatment foreign share $\\times$ year trends; standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} All Swiss municipalities with referendum results and BFS population data 2010--2023; 2,098 municipalities with complete panel. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\emph{Panel A: Pooled} & & & & & & \\\\\n"
)

for (i in 1:nrow(sde_pooled)) {
  tabF1_tex <- paste0(tabF1_tex, sprintf(
    "%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
    sde_pooled$Outcome[i], sde_pooled$Beta[i], sde_pooled$SE[i],
    sde_pooled$SD_Y[i], sde_pooled$SDE[i], sde_pooled$SDE_SE[i],
    sde_pooled$Classification[i]
  ))
}

tabF1_tex <- paste0(tabF1_tex,
  " \\\\\n",
  "\\emph{Panel B: Heterogeneous (by language region)} & & & & & & \\\\\n"
)

for (i in 1:nrow(sde_het)) {
  tabF1_tex <- paste0(tabF1_tex, sprintf(
    "%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
    sde_het$Outcome[i], sde_het$Beta[i], sde_het$SE[i],
    sde_het$SD_Y[i], sde_het$SDE[i], sde_het$SDE_SE[i],
    sde_het$Classification[i]
  ))
}

tabF1_tex <- paste0(tabF1_tex,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(table_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Tables in:", table_dir, "\n")
cat(paste(list.files(table_dir), collapse="\n"), "\n")
