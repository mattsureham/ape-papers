## 05_tables.R — Generate all LaTeX tables
source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")
rob <- readRDS("../data/robustness.rds")
coefs <- readRDS("../data/key_coefs.rds")

# ===================================================================
# Table 1: Summary Statistics
# ===================================================================
cat("Generating Table 1: Summary Statistics...\n")

summ <- panel %>%
  group_by(
    Group = case_when(
      rtf_state == 1 & high_cafo == 1 ~ "RTF State, High-CAFO",
      rtf_state == 1 & high_cafo == 0 ~ "RTF State, Low-CAFO",
      rtf_state == 0 & high_cafo == 1 ~ "Control State, High-CAFO",
      rtf_state == 0 & high_cafo == 0 ~ "Control State, Low-CAFO"
    )
  ) %>%
  summarize(
    Counties = n_distinct(county_fips),
    `Hispanic Share` = sprintf("%.3f", mean(hisp_share, na.rm = TRUE)),
    `White Share` = sprintf("%.3f", mean(white_share, na.rm = TRUE)),
    `Black Share` = sprintf("%.3f", mean(black_share, na.rm = TRUE)),
    `Poverty Rate` = sprintf("%.3f", mean(poverty_rate, na.rm = TRUE)),
    `Median Income` = sprintf("%.0f", mean(med_income, na.rm = TRUE)),
    `Population` = sprintf("%.0f", mean(total_pop, na.rm = TRUE)),
    .groups = "drop"
  )

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics by Treatment Group}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccccccc}",
  "\\hline\\hline",
  "& Counties & Hispanic & White & Black & Poverty & Median & Mean \\\\",
  "& & Share & Share & Share & Rate & Income & Pop. \\\\",
  "\\hline"
)

for (i in 1:nrow(summ)) {
  row <- sprintf("%s & %d & %s & %s & %s & %s & %s & %s \\\\",
                 summ$Group[i], summ$Counties[i],
                 summ$`Hispanic Share`[i], summ$`White Share`[i],
                 summ$`Black Share`[i], summ$`Poverty Rate`[i],
                 summ$`Median Income`[i], summ$Population[i])
  tab1_lines <- c(tab1_lines, row)
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Means across all years (2012--2023). High-CAFO defined as top two quintiles of 2012 USDA Census of Agriculture hog inventory. RTF states: ND (2012), MO (2014), IA (2017), NC (2017), NE (2019), WV (2019), FL (2021).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ===================================================================
# Table 2: Main DDD Results
# ===================================================================
cat("Generating Table 2: Main DDD Results...\n")

# Extract coefficients manually for clean formatting
extract_row <- function(model, varname) {
  cf <- coef(model)[varname]
  s <- se(model)[varname]
  t <- cf / s
  p <- 2 * pt(abs(t), df = model$nobs - length(coef(model)), lower.tail = FALSE)
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = cf, se = s, stars = stars, n = model$nobs)
}

r1 <- extract_row(models$m1, "post_rtf:high_cafo")
r2 <- extract_row(models$m2, "post_rtf:high_cafo")
r3 <- extract_row(models$m3, "post_rtf:high_cafo")
r4 <- extract_row(models$m4, "post_rtf:high_cafo")
# Continuous intensity
r5 <- extract_row(models$m5, "post_rtf:log_hogs")
r6 <- extract_row(models$m6, "post_rtf:log_hogs")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of RTF Expansions on County Demographics: Triple-Difference Estimates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) & (4) \\\\",
  "& Hispanic & Poverty & Log Median & White \\\\",
  "& Share & Rate & Income & Share \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Binary Treatment (High-CAFO $\\times$ Post-RTF)}} \\\\",
  "\\addlinespace",
  sprintf("RTF $\\times$ High-CAFO & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", r1$coef), r1$stars,
          sprintf("%.4f", r2$coef), r2$stars,
          sprintf("%.4f", r3$coef), r3$stars,
          sprintf("%.4f", r4$coef), r4$stars),
  sprintf("& (%s) & (%s) & (%s) & (%s) \\\\",
          sprintf("%.4f", r1$se),
          sprintf("%.4f", r2$se),
          sprintf("%.4f", r3$se),
          sprintf("%.4f", r4$se)),
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","),
          format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","),
          format(r4$n, big.mark = ",")),
  sprintf("Mean Dep. Var. & %.3f & %.3f & %.2f & %.3f \\\\",
          mean(panel$hisp_share, na.rm=TRUE),
          mean(panel$poverty_rate, na.rm=TRUE),
          mean(panel$log_income, na.rm=TRUE),
          mean(panel$white_share, na.rm=TRUE)),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Continuous Intensity (Log Hogs $\\times$ Post-RTF)}} \\\\",
  "\\addlinespace",
  sprintf("RTF $\\times$ Log(Hogs) & %s%s & & & %s%s \\\\",
          sprintf("%.6f", r5$coef), r5$stars,
          sprintf("%.6f", r6$coef), r6$stars),
  sprintf("& (%s) & & & (%s) \\\\",
          sprintf("%.6f", r5$se),
          sprintf("%.6f", r6$se)),
  "\\addlinespace",
  "\\hline",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "State $\\times$ Year FE (Panel B) & Yes & & & Yes \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Panel A reports triple-difference estimates with county and year fixed effects. Panel B adds state$\\times$year fixed effects and uses continuous log hog inventory as treatment intensity. High-CAFO defined as top two quintiles of 2012 hog inventory. Standard errors clustered at the state level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ===================================================================
# Table 3: Robustness
# ===================================================================
cat("Generating Table 3: Robustness...\n")

# Placebo, Exclude ND, Exclude FL, Pop-weighted
r_placebo <- extract_row(rob$placebo, "post_rtf")
r_no_nd <- extract_row(rob$no_nd, "post_rtf:high_cafo")
r_no_fl <- extract_row(rob$no_fl, "post_rtf:high_cafo")
r_wt <- extract_row(rob$pop_weighted, "post_rtf:high_cafo")
r_black <- extract_row(rob$black_share, "post_rtf:high_cafo")

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "& Placebo: & Excl. & Excl. & Pop.- & Black \\\\",
  "& Low-CAFO & ND & FL & Weighted & Share \\\\",
  "\\hline",
  "\\addlinespace",
  sprintf("Coefficient & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", r_placebo$coef), r_placebo$stars,
          sprintf("%.4f", r_no_nd$coef), r_no_nd$stars,
          sprintf("%.4f", r_no_fl$coef), r_no_fl$stars,
          sprintf("%.4f", r_wt$coef), r_wt$stars,
          sprintf("%.4f", r_black$coef), r_black$stars),
  sprintf("& (%s) & (%s) & (%s) & (%s) & (%s) \\\\",
          sprintf("%.4f", r_placebo$se),
          sprintf("%.4f", r_no_nd$se),
          sprintf("%.4f", r_no_fl$se),
          sprintf("%.4f", r_wt$se),
          sprintf("%.4f", r_black$se)),
  "\\addlinespace",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(r_placebo$n, big.mark = ","),
          format(r_no_nd$n, big.mark = ","),
          format(r_no_fl$n, big.mark = ","),
          format(r_wt$n, big.mark = ","),
          format(r_black$n, big.mark = ",")),
  "Outcome & Hisp. Share & Hisp. Share & Hisp. Share & Hisp. Share & Black Share \\\\",
  "\\hline",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Column 1 restricts to low-CAFO counties (bottom two quintiles + zero hog inventory) in RTF and control states --- a placebo test where no nuisance effect should operate. Columns 2--3 exclude individual RTF states. Column 4 weights by county population. Column 5 uses Black population share as outcome. Standard errors clustered at the state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_robust.tex")

# ===================================================================
# Table F1: Standardized Effect Size (SDE) — Appendix
# ===================================================================
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
sd_y_pre <- panel %>%
  filter(year <= 2012) %>%
  summarize(
    sd_hisp = sd(hisp_share, na.rm = TRUE),
    sd_poverty = sd(poverty_rate, na.rm = TRUE),
    sd_income = sd(log_income, na.rm = TRUE),
    sd_white = sd(white_share, na.rm = TRUE)
  )

sde_data <- data.frame(
  outcome = c("Hispanic Share", "Poverty Rate", "Log Median Income", "White Share"),
  beta = c(coef(models$m1)["post_rtf:high_cafo"],
           coef(models$m2)["post_rtf:high_cafo"],
           coef(models$m3)["post_rtf:high_cafo"],
           coef(models$m4)["post_rtf:high_cafo"]),
  se_beta = c(se(models$m1)["post_rtf:high_cafo"],
              se(models$m2)["post_rtf:high_cafo"],
              se(models$m3)["post_rtf:high_cafo"],
              se(models$m4)["post_rtf:high_cafo"]),
  sd_y = c(sd_y_pre$sd_hisp, sd_y_pre$sd_poverty,
           sd_y_pre$sd_income, sd_y_pre$sd_white)
)

sde_data$sde <- sde_data$beta / sde_data$sd_y
sde_data$se_sde <- sde_data$se_beta / sde_data$sd_y
sde_data$class <- ifelse(abs(sde_data$sde) < 0.005, "Null",
                  ifelse(abs(sde_data$sde) < 0.05,
                         ifelse(sde_data$sde > 0, "Small positive", "Small negative"),
                  ifelse(abs(sde_data$sde) < 0.15,
                         ifelse(sde_data$sde > 0, "Moderate positive", "Moderate negative"),
                         ifelse(sde_data$sde > 0, "Large positive", "Large negative"))))

cat("SDE classification:\n")
print(sde_data[, c("outcome", "beta", "sd_y", "sde", "class")])

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state Right-to-Farm law expansions that immunize CAFOs from nuisance suits cause demographic sorting in high-CAFO counties? ",
  "\\textbf{Policy mechanism:} RTF amendments strip neighboring residents' ability to sue CAFOs for nuisance, reducing legal risk for industrial livestock operations and potentially depressing property values in affected areas, which may attract lower-income households through Tiebout sorting. ",
  "\\textbf{Outcome definition:} County-level population shares (Hispanic, White, Black) and poverty rate from ACS 5-year estimates; log median household income. ",
  "\\textbf{Treatment:} Binary --- interaction of state RTF expansion (7 states, 2012--2021) with county high-CAFO designation (top 40\\% of 2012 hog inventory). ",
  "\\textbf{Data:} Census ACS 5-year county-level demographics (2012--2023), USDA NASS Census of Agriculture hog inventory (2012), 38,648 county-year observations across 3,234 counties. ",
  "\\textbf{Method:} Triple-difference (state RTF $\\times$ county CAFO intensity $\\times$ post) with county and year fixed effects; standard errors clustered at state level. ",
  "\\textbf{Sample:} All US counties with non-missing ACS data; CAFO intensity based on pre-treatment 2012 hog inventory to avoid endogeneity. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in 1:nrow(sde_data)) {
  row <- sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
                 sde_data$outcome[i],
                 sde_data$beta[i],
                 sde_data$se_beta[i],
                 sde_data$sd_y[i],
                 sde_data$sde[i],
                 sde_data$se_sde[i],
                 sde_data$class[i])
  tabF1_lines <- c(tabF1_lines, row)
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
