# =============================================================================
# 05_tables.R — Generate all tables for apep_1247
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
setDT(panel)

dir.create("../tables", showWarnings = FALSE)

# =============================================================================
# Table 1: Summary Statistics by Pell Tercile
# =============================================================================
message("=== Table 1: Summary Statistics ===")

summ_pre <- panel[year == 2008, .(
  N = .N,
  `Enrollment` = round(mean(enroll_total, na.rm = TRUE)),
  `Black` = round(mean(enroll_black, na.rm = TRUE)),
  `Hispanic` = round(mean(enroll_hisp, na.rm = TRUE)),
  `White` = round(mean(enroll_white, na.rm = TRUE)),
  `Black Share` = round(mean(black_share, na.rm = TRUE), 3),
  `Pell Share` = round(mean(pre_pell_share, na.rm = TRUE), 3)
), by = pell_tercile]

summ_all <- panel[year == 2008, .(
  pell_tercile = "All",
  N = .N,
  `Enrollment` = round(mean(enroll_total, na.rm = TRUE)),
  `Black` = round(mean(enroll_black, na.rm = TRUE)),
  `Hispanic` = round(mean(enroll_hisp, na.rm = TRUE)),
  `White` = round(mean(enroll_white, na.rm = TRUE)),
  `Black Share` = round(mean(black_share, na.rm = TRUE), 3),
  `Pell Share` = round(mean(pre_pell_share, na.rm = TRUE), 3)
)]

summ <- rbind(summ_pre, summ_all, use.names = TRUE)

# Write LaTeX
cat("% Table 1: Summary Statistics
\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics by Pre-ARRA Pell Recipient Intensity (2008)}
\\label{tab:summary}
\\begin{tabular}{lccccccc}
\\toprule
 & Institutions & Enrollment & Black & Hispanic & White & Black & Pell \\\\
 &  & (Total) & Enrollment & Enrollment & Enrollment & Share & Share \\\\
\\midrule\n", file = "../tables/tab1_summary.tex")

for (i in 1:nrow(summ)) {
  row <- summ[i]
  cat(sprintf("%s & %d & %s & %s & %s & %s & %.3f & %.3f \\\\\n",
              as.character(row$pell_tercile), row$N,
              format(row$Enrollment, big.mark = ","),
              format(row$Black, big.mark = ","),
              format(row$Hispanic, big.mark = ","),
              format(row$White, big.mark = ","),
              row$`Black Share`, row$`Pell Share`),
      file = "../tables/tab1_summary.tex", append = TRUE)
  if (i == nrow(summ) - 1) {
    cat("\\midrule\n", file = "../tables/tab1_summary.tex", append = TRUE)
  }
}

cat("\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} Statistics computed from IPEDS 12-month enrollment survey and Student Financial Aid survey for 2-year public institutions observed in the analysis sample. Pell terciles defined by pre-ARRA (2007--08 average) Pell recipient share. Enrollment figures are annual headcounts. Black Share is the fraction of total enrollment identified as Black or African American. Pell Share is the fraction of undergraduates receiving Pell Grants.
\\end{tablenotes}
\\end{table}\n", file = "../tables/tab1_summary.tex", append = TRUE)

# =============================================================================
# Table 2: Main Bartik DiD Results
# =============================================================================
message("=== Table 2: Main Results ===")

etable(results$static_black, results$static_hisp,
       results$static_white, results$static_total,
       headers = c("Log Black", "Log Hispanic", "Log White", "Log Total"),
       depvar = FALSE,
       fixef.group = list("Institution FE" = "unitid", "Year FE" = "year"),
       se.below = TRUE,
       dict = c("pre_pell_share:post" = "Pell Share $\\times$ Post"),
       notes = paste0("\\\\textit{Notes:} Each column reports a separate regression of log enrollment ",
                      "on the interaction of pre-ARRA Pell recipient share (2007--08 average) with a ",
                      "post-2008 indicator, with institution and year fixed effects. Standard errors ",
                      "clustered at the institution level in parentheses. Sample: 1,291 two-year public ",
                      "colleges, 2002--2015. * $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       title = "ARRA Pell Grant Expansion and Log Enrollment by Race",
       label = "tab:main",
       tex = TRUE, file = "../tables/tab2_main.tex",
       replace = TRUE)

# =============================================================================
# Table 3: Black Enrollment Share — Main + Robustness
# =============================================================================
message("=== Table 3: Black Share Results ===")

etable(results$share_black, rob$state_black_share,
       rob$winsor_black, rob$tercile_share,
       headers = c("Baseline", "State SE", "Winsorized", "Tercile"),
       depvar = FALSE,
       fixef.group = list("Institution FE" = "unitid", "Year FE" = "year"),
       se.below = TRUE,
       dict = c("pre_pell_share:post" = "Pell Share $\\times$ Post",
                "high_pell:post" = "High Pell $\\times$ Post"),
       notes = paste0("\\\\textit{Notes:} Dependent variable is the Black enrollment share. ",
                      "Column (1) is the baseline with institution-clustered SEs. Column (2) clusters ",
                      "at the state level. Column (3) excludes institutions with Pell share below 0.05 ",
                      "or above 0.80. Column (4) compares top vs.\\\\ bottom Pell tercile (binary treatment). ",
                      "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       title = "Black Enrollment Share: Robustness",
       label = "tab:robustness",
       tex = TRUE, file = "../tables/tab3_robustness.tex",
       replace = TRUE)

# =============================================================================
# Table 4: Active vs Phase-out + Triple Difference
# =============================================================================
message("=== Table 4: Dynamic Estimates ===")

etable(results$active_black, results$active_hisp, results$active_white,
       rob$ddd,
       headers = c("Black", "Hispanic", "White", "DDD (B vs W)"),
       depvar = FALSE,
       se.below = TRUE,
       dict = c("pre_pell_share:arra_active" = "Pell Share $\\times$ ARRA Active",
                "pre_pell_share:arra_phaseout" = "Pell Share $\\times$ Phase-out",
                "minority:pre_pell_share:post" = "Black $\\times$ Pell $\\times$ Post",
                "minority:post" = "Black $\\times$ Post"),
       notes = paste0("\\\\textit{Notes:} Columns (1)--(3) decompose the post-ARRA effect into ARRA active ",
                      "(2009--2011) and phase-out (2012--2015) periods. Column (4) is a triple-difference ",
                      "stacking Black and White enrollment within institution-year cells. ",
                      "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
       title = "Dynamic Effects and Triple-Difference",
       label = "tab:dynamic",
       tex = TRUE, file = "../tables/tab4_dynamic.tex",
       replace = TRUE)

# =============================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# =============================================================================
message("=== Table F1: SDE ===")

# Compute SDEs for main outcomes
panel[, event_time := year - 2008]

# Pre-treatment SD of outcomes (2002-2008)
pre_sd <- panel[year <= 2008, .(
  sd_black_share = sd(black_share, na.rm = TRUE),
  sd_log_black = sd(log_enroll_black, na.rm = TRUE),
  sd_log_total = sd(log_enroll_total, na.rm = TRUE)
)]

# SD of treatment variable
sd_x <- sd(panel$pre_pell_share, na.rm = TRUE)

# Main estimates and SEs
beta_share <- coef(results$share_black)[[1]]
se_share <- sqrt(vcov(results$share_black)[[1, 1]])
beta_log_black <- coef(results$static_black)[[1]]
se_log_black <- sqrt(vcov(results$static_black)[[1, 1]])
beta_log_total <- coef(results$static_total)[[1]]
se_log_total <- sqrt(vcov(results$static_total)[[1, 1]])

# For continuous treatment: SDE = beta × SD(X) / SD(Y)
sde_share <- beta_share * sd_x / pre_sd$sd_black_share
sde_se_share <- se_share * sd_x / pre_sd$sd_black_share

sde_log_black <- beta_log_black * sd_x / pre_sd$sd_log_black
sde_se_log_black <- se_log_black * sd_x / pre_sd$sd_log_black

sde_log_total <- beta_log_total * sd_x / pre_sd$sd_log_total
sde_se_log_total <- se_log_total * sd_x / pre_sd$sd_log_total

# Classify
classify_sde <- function(s) {
  if (s > 0.15) return("Large positive")
  if (s > 0.05) return("Moderate positive")
  if (s > 0.005) return("Small positive")
  if (s > -0.005) return("Null")
  if (s > -0.05) return("Small negative")
  if (s > -0.15) return("Moderate negative")
  return("Large negative")
}

# Heterogeneity: Large vs Small institutions (median split on 2008 enrollment)
med_enroll <- panel[year == 2008, median(enroll_total, na.rm = TRUE)]
panel[, large_inst := as.integer(enroll_total > med_enroll)]

# By pre-2008 enrollment
base_size <- panel[year == 2008, .(base_enroll = enroll_total), by = unitid]
panel <- merge(panel, base_size, by = "unitid", all.x = TRUE)
panel[, large_inst := as.integer(base_enroll > med_enroll)]

large_mod <- feols(black_share ~ pre_pell_share:post | unitid + year,
                   data = panel[large_inst == 1], cluster = ~unitid)
small_mod <- feols(black_share ~ pre_pell_share:post | unitid + year,
                   data = panel[large_inst == 0], cluster = ~unitid)

pre_sd_large <- panel[large_inst == 1 & year <= 2008, sd(black_share, na.rm = TRUE)]
pre_sd_small <- panel[large_inst == 0 & year <= 2008, sd(black_share, na.rm = TRUE)]
sd_x_large <- panel[large_inst == 1, sd(pre_pell_share, na.rm = TRUE)]
sd_x_small <- panel[large_inst == 0, sd(pre_pell_share, na.rm = TRUE)]

beta_large <- coef(large_mod)[[1]]
se_large <- sqrt(vcov(large_mod)[[1, 1]])
beta_small <- coef(small_mod)[[1]]
se_small <- sqrt(vcov(small_mod)[[1, 1]])

sde_large <- beta_large * sd_x_large / pre_sd_large
sde_se_large <- se_large * sd_x_large / pre_sd_large
sde_small <- beta_small * sd_x_small / pre_sd_small
sde_se_small <- se_small * sd_x_small / pre_sd_small

# Build SDE table
sde_rows <- data.frame(
  Panel = c(rep("A: Pooled", 3), rep("B: Heterogeneous", 2)),
  Outcome = c("Black enrollment share", "Log Black enrollment", "Log total enrollment",
              "Black share (Large colleges)", "Black share (Small colleges)"),
  Beta = c(beta_share, beta_log_black, beta_log_total, beta_large, beta_small),
  SE = c(se_share, se_log_black, se_log_total, se_large, se_small),
  SD_Y = c(pre_sd$sd_black_share, pre_sd$sd_log_black, pre_sd$sd_log_total,
           pre_sd_large, pre_sd_small),
  SDE = c(sde_share, sde_log_black, sde_log_total, sde_large, sde_small),
  SE_SDE = c(sde_se_share, sde_se_log_black, sde_se_log_total, sde_se_large, sde_se_small),
  stringsAsFactors = FALSE
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the 2009 ARRA Pell Grant maximum award increase ",
  "($619, +13.1\\%) differentially affect Black enrollment at community colleges with ",
  "higher pre-existing Pell recipient intensity? ",
  "\\textbf{Policy mechanism:} ARRA increased the maximum Pell Grant from \\$4,731 to ",
  "\\$5,350 and expanded the auto-zero Expected Family Contribution threshold from \\$20,000 ",
  "to \\$30,000, disproportionately benefiting low-income students at institutions with ",
  "high Pell recipient concentration. ",
  "\\textbf{Outcome definition:} Black enrollment share (Panel A, row 1) is the fraction ",
  "of total 12-month headcount enrollment identified as Black or African American in IPEDS; ",
  "log Black enrollment is ln(Black headcount + 1). ",
  "\\textbf{Treatment:} Continuous; pre-ARRA (2007--08) Pell recipient share interacted ",
  "with post-2008 indicator (Bartik intensity design). ",
  "\\textbf{Data:} IPEDS 12-month enrollment and Student Financial Aid surveys, 2002--2015, ",
  "1,291 two-year public institutions, 16,848 institution-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (institution + year), standard errors clustered ",
  "at institution level. ",
  "\\textbf{Sample:} Two-year public colleges observed in at least 5 of 14 years with non-missing ",
  "pre-ARRA Pell share; Panel B splits at median 2008 enrollment. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-sectional ",
  "standard deviation of pre-ARRA Pell share and SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("% Table F1: Standardized Effect Sizes
\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
\\midrule\n", file = "../tables/tabF1_sde.tex")

for (i in 1:nrow(sde_rows)) {
  if (i == 4) {
    cat("\\midrule\n\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Institution Size)}} \\\\\n\\midrule\n",
        file = "../tables/tabF1_sde.tex", append = TRUE)
  }
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              sde_rows$Outcome[i],
              sde_rows$Beta[i], sde_rows$SE[i], sde_rows$SD_Y[i],
              sde_rows$SDE[i], sde_rows$SE_SDE[i], sde_rows$Classification[i]),
      file = "../tables/tabF1_sde.tex", append = TRUE)
}

cat(sprintf("\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
%s
\\end{tablenotes}
\\end{table}\n", sde_notes), file = "../tables/tabF1_sde.tex", append = TRUE)

message("All tables written to ../tables/")
message("Files:")
message("  tab1_summary.tex")
message("  tab2_main.tex")
message("  tab3_robustness.tex")
message("  tab4_dynamic.tex")
message("  tabF1_sde.tex")
