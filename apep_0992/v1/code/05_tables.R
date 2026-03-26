# 05_tables.R — Generate all LaTeX tables
# APEP Working Paper apep_0992

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
load("data/main_results.RData")
load("data/robustness_results.RData")

# ==========================================================================
# TABLE 1: Summary Statistics
# ==========================================================================
cat("Generating Table 1: Summary Statistics\n")

# Overall summary by crop
sum_stats <- panel[, .(
  N = .N,
  Mean = mean(planted_area),
  SD = sd(planted_area),
  Median = median(planted_area),
  Min = min(planted_area),
  Max = max(planted_area)
), by = crop]
sum_stats <- sum_stats[order(crop)]

# Pre vs post means
pre_post <- panel[, .(mean_area = mean(planted_area)), by = .(crop, post)]
pre_post_wide <- dcast(pre_post, crop ~ post, value.var = "mean_area")
setnames(pre_post_wide, c("crop", "Pre_Mean", "Post_Mean"))
pre_post_wide[, Change_Pct := round(100 * (Post_Mean - Pre_Mean) / Pre_Mean, 1)]

sum_merged <- merge(sum_stats, pre_post_wide, by = "crop")

# Format table
tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Planted Area by Crop (Hectares)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lrrrrrrrr}\n",
  "\\toprule\n",
  "Crop & N & Mean & SD & Median & Pre-Reform & Post-Reform & \\% Change & Tax Cut \\\\\n",
  " & & & & & Mean & Mean & & (pp) \\\\\n",
  "\\midrule\n"
)

# Add rows
tax_cuts <- c(Corn = 20, Soybean = 5, Sunflower = 32, Wheat = 23)
for (i in 1:nrow(sum_merged)) {
  cr <- sum_merged$crop[i]
  tab1 <- paste0(tab1,
    sprintf("%s & %s & %s & %s & %s & %s & %s & %s & %d \\\\\n",
      cr,
      format(sum_merged$N[i], big.mark = ","),
      format(round(sum_merged$Mean[i]), big.mark = ","),
      format(round(sum_merged$SD[i]), big.mark = ","),
      format(round(sum_merged$Median[i]), big.mark = ","),
      format(round(sum_merged$Pre_Mean[i]), big.mark = ","),
      format(round(sum_merged$Post_Mean[i]), big.mark = ","),
      sprintf("%+.1f", sum_merged$Change_Pct[i]),
      tax_cuts[cr]
    )
  )
}

tab1 <- paste0(tab1,
  "\\midrule\n",
  sprintf("Total & %s & & & & & & & \\\\\n",
    format(nrow(panel), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\end{threeparttable}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize \\textit{Notes:} Department-crop-campaign level observations from MAGyP Estimaciones Agr\\'{i}colas, ",
  "campaigns 2010/11--2019/20. Treated crops (wheat, corn, sunflower) had export taxes eliminated ",
  "in December 2015; soybean taxes were reduced by 5 percentage points only. ",
  "Pre-reform: 2010/11--2014/15; Post-reform: 2015/16--2019/20. ",
  sprintf("Panel covers %d departments across %d provinces.}\n",
    uniqueN(panel$dept_id), uniqueN(panel$province_id)),
  "\\end{table}\n"
)

writeLines(tab1, "tables/tab1_summary.tex")
cat("  Written: tables/tab1_summary.tex\n")

# ==========================================================================
# TABLE 2: Main Results
# ==========================================================================
cat("Generating Table 2: Main Results\n")

# Extract coefficients
get_coef_row <- function(model, varname = "treat_post") {
  cf <- coef(model)[varname]
  se_val <- se(model)[varname]
  pv <- pvalue(model)[varname]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(coef = cf, se = se_val, pval = pv, stars = stars,
       n = model$nobs, r2 = fitstat(model, "r2")$r2)
}

r1 <- get_coef_row(m1)
r2 <- get_coef_row(m2)
r3 <- get_coef_row(m3)
r4 <- get_coef_row(m4)
r5 <- get_coef_row(m5)

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Export Tax Elimination on Planted Area}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & \\multicolumn{4}{c}{Log(Planted Area)} & Log(Production) \\\\\n",
  "\\midrule\n",
  sprintf("Treated $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
    r1$coef, r1$stars, r2$coef, r2$stars, r3$coef, r3$stars,
    r4$coef, r4$stars, r5$coef, r5$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
    r1$se, r2$se, r3$se, r4$se, r5$se),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
    format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
    format(r3$n, big.mark = ","), format(r4$n, big.mark = ","),
    format(r5$n, big.mark = ",")),
  "Dept FE & Yes & Yes & & & \\\\\n",
  "Year FE & Yes & Yes & & & \\\\\n",
  "Crop FE & & Yes & & & \\\\\n",
  "Dept $\\times$ Crop FE & & & Yes & Yes & Yes \\\\\n",
  "Dept $\\times$ Year FE & & & & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. ",
  "Standard errors clustered at the department level in parentheses. ",
  "The dependent variable is the natural log of planted area (hectares) in columns (1)--(4) ",
  "and log of production (metric tons) in column (5). ",
  "\\textit{Treated} equals one for wheat, corn, and sunflower (export taxes eliminated) ",
  "and zero for soybeans (tax reduced 5pp only). ",
  "\\textit{Post} equals one for campaigns 2015/16 onward. ",
  "Column (4) is the preferred specification with the full set of two-way fixed effects.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, "tables/tab2_main.tex")
cat("  Written: tables/tab2_main.tex\n")

# ==========================================================================
# TABLE 3: Crop-Specific Effects + Heterogeneity
# ==========================================================================
cat("Generating Table 3: Crop-Specific Effects\n")

cs <- function(model, varname) {
  cf <- coef(model)[varname]
  se_val <- se(model)[varname]
  pv <- pvalue(model)[varname]
  stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
  list(coef = cf, se = se_val, stars = stars)
}

w <- cs(m6, "wheat_post")
c_r <- cs(m6, "corn_post")
s <- cs(m6, "sunflower_post")
hh <- get_coef_row(m_het_high)
hl <- get_coef_row(m_het_low)

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Crop-Specific Effects and Heterogeneity by Initial Soybean Concentration}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & \\multicolumn{4}{c}{Log(Planted Area)} \\\\\n",
  " & Crop-Specific & & High Soy & Low Soy \\\\\n",
  " & Effects & Area Share & Concentration & Concentration \\\\\n",
  "\\midrule\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Crop-Specific Effects}} \\\\\n",
  sprintf("Wheat $\\times$ Post & %.3f%s & & & \\\\\n", w$coef, w$stars),
  sprintf(" & (%.3f) & & & \\\\\n", w$se),
  sprintf("Corn $\\times$ Post & %.3f%s & & & \\\\\n", c_r$coef, c_r$stars),
  sprintf(" & (%.3f) & & & \\\\\n", c_r$se),
  sprintf("Sunflower $\\times$ Post & %.3f%s & & & \\\\\n", s$coef, s$stars),
  sprintf(" & (%.3f) & & & \\\\\n", s$se),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Area Share Outcome}} \\\\\n",
  sprintf("Treated $\\times$ Post & & %.4f%s & & \\\\\n",
    coef(m_share)["treat_post"],
    ifelse(pvalue(m_share)["treat_post"] < 0.01, "***",
           ifelse(pvalue(m_share)["treat_post"] < 0.05, "**",
                  ifelse(pvalue(m_share)["treat_post"] < 0.1, "*", "")))),
  sprintf(" & & (%.4f) & & \\\\\n", se(m_share)["treat_post"]),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: Heterogeneity by Pre-Reform Soybean Share}} \\\\\n",
  sprintf("Treated $\\times$ Post & & & %.3f%s & %.3f%s \\\\\n",
    hh$coef, hh$stars, hl$coef, hl$stars),
  sprintf(" & & & (%.3f) & (%.3f) \\\\\n", hh$se, hl$se),
  "\\addlinespace\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
    format(m6$nobs, big.mark = ","), format(m_share$nobs, big.mark = ","),
    format(m_het_high$nobs, big.mark = ","), format(m_het_low$nobs, big.mark = ",")),
  "Dept $\\times$ Crop FE & Yes & Yes & Yes & Yes \\\\\n",
  "Dept $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. ",
  "Standard errors clustered at the department level. ",
  "Panel A shows separate treatment effects for each liberalized crop relative to soybeans. ",
  "Panel B uses crop area share within each department-year as the outcome. ",
  "Panel C splits the sample at the median pre-reform soybean share ",
  sprintf("(median = %.1f\\%%).\n", 100 * median(panel$pre_soy_share, na.rm = TRUE)),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, "tables/tab3_heterogeneity.tex")
cat("  Written: tables/tab3_heterogeneity.tex\n")

# ==========================================================================
# TABLE 4: Robustness
# ==========================================================================
cat("Generating Table 4: Robustness\n")

rob_results <- list(
  main = get_coef_row(m4),
  prov_clust = get_coef_row(r1_province),
  twoway_clust = get_coef_row(r1_twoway),
  narrow = get_coef_row(r2_narrow),
  wide = get_coef_row(r2_wide),
  placebo = get_coef_row(r3_placebo, "fake_treat_post"),
  levels = get_coef_row(r4_levels),
  nopampa = get_coef_row(r6_nopampa),
  pampa = get_coef_row(r6_pampa),
  nosunflower = get_coef_row(r7_nosunflower)
)

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llrrr}\n",
  "\\toprule\n",
  "Specification & Variation & Estimate & SE & N \\\\\n",
  "\\midrule\n"
)

rob_labels <- c(
  main = "Baseline (preferred)",
  prov_clust = "Province-clustered SEs",
  twoway_clust = "Two-way clustered SEs",
  narrow = "Narrow window (2012--2017)",
  wide = "Wide window (2008--2019)",
  placebo = "Placebo reform (2012)",
  levels = "Levels (hectares)",
  nopampa = "Excluding Pampa H\\'{u}meda",
  pampa = "Pampa H\\'{u}meda only",
  nosunflower = "Excluding sunflower"
)

for (nm in names(rob_results)) {
  r <- rob_results[[nm]]
  tab4 <- paste0(tab4,
    sprintf("%s & & %.3f%s & %.3f & %s \\\\\n",
      rob_labels[nm], r$coef, r$stars, r$se, format(r$n, big.mark = ",")))
}

tab4 <- paste0(tab4,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. ",
  "All specifications include department$\\times$crop and department$\\times$year ",
  "fixed effects unless noted. Baseline uses log(planted area) with department-clustered SEs. ",
  "The placebo test places a fake reform at 2012 using only pre-reform data (2010--2014). ",
  "Pampa H\\'{u}meda includes Buenos Aires, C\\'{o}rdoba, Santa Fe, Entre R\\'{i}os, and La Pampa.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4, "tables/tab4_robustness.tex")
cat("  Written: tables/tab4_robustness.tex\n")

# ==========================================================================
# TABLE F1: SDE (Standardized Effect Sizes)
# ==========================================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

# Get SD(Y) for the full sample (unconditional)
sd_planted <- sd(panel$log_planted)
sd_production <- sd(panel$log_production)

# Classify function
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

# Pooled effects (from preferred spec m4 and m5)
beta_area <- coef(m4)["treat_post"]
se_area <- se(m4)["treat_post"]
sde_area <- beta_area / sd_planted
se_sde_area <- se_area / sd_planted

beta_prod <- coef(m5)["treat_post"]
se_prod <- se(m5)["treat_post"]
sde_prod <- beta_prod / sd_production
se_sde_prod <- se_prod / sd_production

# Heterogeneity (high vs low soybean concentration)
beta_high <- coef(m_het_high)["treat_post"]
se_high <- se(m_het_high)["treat_post"]
sd_high <- sd(panel[high_soy == 1]$log_planted)
sde_high <- beta_high / sd_high
se_sde_high <- se_high / sd_high

beta_low <- coef(m_het_low)["treat_post"]
se_low <- se(m_het_low)["treat_post"]
sd_low <- sd(panel[high_soy == 0]$log_planted)
sde_low <- beta_low / sd_low
se_sde_low <- se_low / sd_low

# SDE notes string
sde_notes <- paste0(
  "\\textit{Notes:} ",
  "\\textbf{Country:} Argentina. ",
  "\\textbf{Research question:} Does differential elimination of export taxes across crops cause reallocation of planted area away from the still-taxed crop toward newly liberalized crops? ",
  "\\textbf{Policy mechanism:} In December 2015, presidential decrees eliminated export taxes (retenciones) on wheat, corn, and sunflower while only reducing soybean export taxes by five percentage points, creating a differential incentive to shift acreage toward the newly liberalized crops. ",
  "\\textbf{Outcome definition:} Log of planted area in hectares at the department-crop-campaign level, from MAGyP Estimaciones Agr\\'{i}colas administrative records. ",
  "\\textbf{Treatment:} Binary indicator equal to one for crops whose export taxes were fully eliminated (wheat, corn, sunflower) and zero for soybeans (tax reduced by five percentage points only). ",
  "\\textbf{Data:} MAGyP Estimaciones Agr\\'{i}colas, campaigns 2010/11--2019/20, department-crop-campaign unit, ",
  sprintf("%s observations across %d departments. ", format(nrow(panel), big.mark = ","), uniqueN(panel$dept_id)),
  "\\textbf{Method:} Difference-in-differences with department$\\times$crop and department$\\times$year fixed effects; standard errors clustered at department level. ",
  "\\textbf{Sample:} Departments growing all four focal crops (soybean, wheat, corn, sunflower) with at least four observations in both the pre-reform and post-reform periods. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log planted area. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("Log(Planted Area) & Preferred DDD & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
    beta_area, se_area, sd_planted, sde_area, se_sde_area, classify_sde(sde_area)),
  sprintf("Log(Production) & Preferred DDD & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
    beta_prod, se_prod, sd_production, sde_prod, se_sde_prod, classify_sde(sde_prod)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by Pre-Reform Soybean Concentration)}} \\\\\n",
  sprintf("Log(Planted Area) & High soy share & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
    beta_high, se_high, sd_high, sde_high, se_sde_high, classify_sde(sde_high)),
  sprintf("Log(Planted Area) & Low soy share & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
    beta_low, se_low, sd_low, sde_low, se_sde_low, classify_sde(sde_low)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\end{threeparttable}\n",
  "\\par\\vspace{0.3em}\n",
  "{\\footnotesize ", sde_notes, "}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("  Written: tables/tabF1_sde.tex\n")

cat("\nAll tables generated successfully.\n")
