# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: apep_1187 — Sweden Pay Equity Audit RDD
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
load("../data/models.RData")
load("../data/robustness_models.RData")
sde <- readRDS("../data/sde_inputs.rds")

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ_data <- df %>%
  summarise(
    `Gender Wage Ratio (\\%)` = sprintf("%.1f & %.1f & %.1f & %.1f & %d",
      mean(gap_monthly, na.rm=T), sd(gap_monthly, na.rm=T),
      min(gap_monthly, na.rm=T), max(gap_monthly, na.rm=T), sum(!is.na(gap_monthly))),
    `Monthly Salary, Male (SEK)` = sprintf("%.0f & %.0f & %.0f & %.0f & %d",
      mean(monthly_salary_male, na.rm=T), sd(monthly_salary_male, na.rm=T),
      min(monthly_salary_male, na.rm=T), max(monthly_salary_male, na.rm=T),
      sum(!is.na(monthly_salary_male))),
    `Monthly Salary, Female (SEK)` = sprintf("%.0f & %.0f & %.0f & %.0f & %d",
      mean(monthly_salary_female, na.rm=T), sd(monthly_salary_female, na.rm=T),
      min(monthly_salary_female, na.rm=T), max(monthly_salary_female, na.rm=T),
      sum(!is.na(monthly_salary_female))),
    `Absolute Gap (SEK)` = sprintf("%.0f & %.0f & %.0f & %.0f & %d",
      mean(abs_gap, na.rm=T), sd(abs_gap, na.rm=T),
      min(abs_gap, na.rm=T), max(abs_gap, na.rm=T), sum(!is.na(abs_gap))),
    `Treatment Intensity` = sprintf("%.3f & %.3f & %.3f & %.3f & %d",
      mean(treat_intensity_pre, na.rm=T), sd(treat_intensity_pre, na.rm=T),
      min(treat_intensity_pre, na.rm=T), max(treat_intensity_pre, na.rm=T),
      sum(!is.na(treat_intensity_pre))),
    `Private Sector Share (\\%)` = sprintf("%.1f & %.1f & %.1f & %.1f & %d",
      mean(private_share, na.rm=T), sd(private_share, na.rm=T),
      min(private_share, na.rm=T), max(private_share, na.rm=T),
      sum(!is.na(private_share)))
  )

tex_tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & N \\\\",
  "\\hline",
  "\\multicolumn{6}{l}{\\textit{Panel A: Outcome Variables}} \\\\[3pt]",
  sprintf("Gender Wage Ratio (\\%%) & %s \\\\", summ_data[[1]]),
  sprintf("Monthly Salary, Male (SEK) & %s \\\\", summ_data[[2]]),
  sprintf("Monthly Salary, Female (SEK) & %s \\\\", summ_data[[3]]),
  sprintf("Absolute Gap (SEK) & %s \\\\[6pt]", summ_data[[4]]),
  "\\multicolumn{6}{l}{\\textit{Panel B: Treatment Variables}} \\\\[3pt]",
  sprintf("Treatment Intensity & %s \\\\", summ_data[[5]]),
  sprintf("Private Sector Share (\\%%) & %s \\\\", summ_data[[6]]),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.92\\textwidth}}{\\footnotesize \\textit{Notes:} Unit of observation is industry--year. Gender Wage Ratio is female monthly salary as a percentage of male monthly salary. Treatment Intensity is the pre-reform (2010--2016) average share of firms with 10--19 employees in each NACE 1-letter industry section. Data: Statistics Sweden Wage Structure Survey (AM0110) and Enterprise Register (FDBR07N), 2014--2024. $N = 209$ industry--year observations across 19 NACE sections.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex_tab1, "../tables/tab1_summary.tex")

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("=== Table 2: Main Results ===\n")

# Extract coefficient info
get_coef_row <- function(model, var_name, digits = 3) {
  b <- coef(model)[var_name]
  s <- se(model)[var_name]
  p <- pvalue(model)[var_name]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}",
           ifelse(p < 0.1, "^{*}", "")))
  list(
    coef = sprintf("%.%df%s", digits, b, stars),
    se = sprintf("(%.%df)", digits, s),
    b = b, s = s, p = p
  )
}

# Build table manually for precise control
tex_tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Pay Equity Audit Mandate on the Gender Wage Gap}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Wage Ratio (\\%)} & Log Gap & Absolute Gap \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\hline"
)

# Row for post_treat coefficient
b1 <- coef(m1)["post_treat"]; s1 <- se(m1)["post_treat"]; p1 <- pvalue(m1)["post_treat"]
b4 <- coef(m4)["post_treat"]; s4 <- se(m4)["post_treat"]; p4 <- pvalue(m4)["post_treat"]
b3 <- coef(m3)["post_treat"]; s3 <- se(m3)["post_treat"]; p3 <- pvalue(m3)["post_treat"]
b5 <- coef(m5)["post_treat"]; s5 <- se(m5)["post_treat"]; p5 <- pvalue(m5)["post_treat"]

star <- function(p) ifelse(p<0.01,"^{***}",ifelse(p<0.05,"^{**}",ifelse(p<0.1,"^{*}","")))

tex_tab2 <- c(tex_tab2,
  sprintf("$\\text{Post}_{t} \\times \\text{TreatIntensity}_{i}$ & $%.2f%s$ & $%.2f%s$ & $%.4f%s$ & $%.0f%s$ \\\\",
          b1, star(p1), b4, star(p4), b3, star(p3), b5, star(p5)),
  sprintf(" & $(%.2f)$ & $(%.2f)$ & $(%.4f)$ & $(%.0f)$ \\\\[6pt]",
          s1, s4, s3, s5),
  "Outcome & Monthly & Basic & Log & SEK \\\\",
  sprintf("Industry FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\", nobs(m1), nobs(m4), nobs(m3), nobs(m5)),
  sprintf("$R^2$ (within) & %.4f & %.4f & %.4f & %.4f \\\\",
          fitstat(m1, "wr2")$wr2, fitstat(m4, "wr2")$wr2,
          fitstat(m3, "wr2")$wr2, fitstat(m5, "wr2")$wr2),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.92\\textwidth}}{\\footnotesize \\textit{Notes:} Each column reports the coefficient on $\\text{Post}_{t} \\times \\text{TreatIntensity}_{i}$, where $\\text{Post}_{t} = \\mathbf{1}[t \\geq 2017]$ and $\\text{TreatIntensity}_{i}$ is the pre-reform (2010--2016) share of firms with 10--19 employees in industry $i$. Columns (1)--(2): female salary as percentage of male salary (monthly and basic). Column (3): log female minus log male salary. Column (4): absolute male--female salary gap in SEK. Standard errors clustered by industry in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex_tab2, "../tables/tab2_main.tex")

# ============================================================================
# TABLE 3: Event Study Coefficients
# ============================================================================
cat("=== Table 3: Event Study ===\n")

es_coefs <- coef(m_es)
es_ses <- se(m_es)
es_pvals <- pvalue(m_es)

# Extract year labels
es_names <- names(es_coefs)
es_years <- as.integer(gsub(".*year::(\\d{4}).*", "\\1", es_names))

tex_tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Year-Specific Effects on Gender Wage Ratio}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Year $\\times$ Treatment Intensity & Coefficient & Std. Error \\\\",
  "\\hline"
)

for (j in seq_along(es_coefs)) {
  yr <- es_years[j]
  pre_post <- ifelse(yr < 2017, "\\textit{(pre)}", "\\textit{(post)}")
  tex_tab3 <- c(tex_tab3,
    sprintf("%d %s & $%.2f%s$ & $(%.2f)$ \\\\",
            yr, pre_post, es_coefs[j], star(es_pvals[j]), es_ses[j]))
}

tex_tab3 <- c(tex_tab3,
  "\\hline",
  "Reference year & \\multicolumn{2}{c}{2016} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%d} \\\\", nobs(m_es)),
  "Industry FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Each row reports the coefficient on $\\mathbf{1}[\\text{Year}=t] \\times \\text{TreatIntensity}_{i}$, with 2016 as the omitted reference year. The outcome is the gender wage ratio (female salary as \\% of male). Standard errors clustered by industry. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex_tab3, "../tables/tab3_eventstudy.tex")

# ============================================================================
# TABLE 4: Robustness Checks
# ============================================================================
cat("=== Table 4: Robustness ===\n")

bp <- coef(m_placebo)["post_placebo"]; sp <- se(m_placebo)["post_placebo"]
pp <- pvalue(m_placebo)["post_placebo"]

bt <- coef(m_timing)["fake_post_treat"]; st <- se(m_timing)["fake_post_treat"]
pt <- pvalue(m_timing)["fake_post_treat"]

bgf <- coef(m_growth_f)["post_treat"]; sgf <- se(m_growth_f)["post_treat"]
pgf <- pvalue(m_growth_f)["post_treat"]

bgm <- coef(m_growth_m)["post_treat"]; sgm <- se(m_growth_m)["post_treat"]
pgm <- pvalue(m_growth_m)["post_treat"]

bw <- coef(m_weighted)["post_treat"]; sw <- se(m_weighted)["post_treat"]
pw <- pvalue(m_weighted)["post_treat"]

bb <- coef(m_basic)["post_treat"]; sb <- se(m_basic)["post_treat"]
pb <- pvalue(m_basic)["post_treat"]

tex_tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{llccc}",
  "\\hline\\hline",
  "Panel & Specification & Coefficient & SE & N \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Placebo Tests}} \\\\[3pt]",
  sprintf("& Placebo treatment (20--49 empl.) & $%.2f%s$ & $(%.2f)$ & %d \\\\",
          bp, star(pp), sp, nobs(m_placebo)),
  sprintf("& Placebo timing (fake reform 2015) & $%.2f%s$ & $(%.2f)$ & %d \\\\[6pt]",
          bt, star(pt), st, nobs(m_timing)),
  "\\multicolumn{5}{l}{\\textit{Panel B: Wage Growth Decomposition}} \\\\[3pt]",
  sprintf("& Female wage growth & $%.2f%s$ & $(%.2f)$ & %d \\\\",
          bgf, star(pgf), sgf, nobs(m_growth_f)),
  sprintf("& Male wage growth & $%.2f%s$ & $(%.2f)$ & %d \\\\[6pt]",
          bgm, star(pgm), sgm, nobs(m_growth_m)),
  "\\multicolumn{5}{l}{\\textit{Panel C: Alternative Specifications}} \\\\[3pt]",
  sprintf("& Employment-weighted & $%.2f%s$ & $(%.2f)$ & %d \\\\",
          bw, star(pw), sw, nobs(m_weighted)),
  sprintf("& Basic salary gap & $%.2f%s$ & $(%.2f)$ & %d \\\\",
          bb, star(pb), sb, nobs(m_basic)),
  sprintf("& Leave-one-out range & \\multicolumn{3}{c}{$[%.2f, \\; %.2f]$} \\\\",
          min(loo_coefs), max(loo_coefs)),
  "\\hline\\hline",
  "\\multicolumn{5}{p{0.92\\textwidth}}{\\footnotesize \\textit{Notes:} All regressions include industry and year fixed effects with standard errors clustered by industry. Panel A tests the specificity of the treatment measure: placebo treatment uses the share of firms with 20--49 employees (always subject to the mandate); placebo timing applies a fake reform date in the pre-period. Panel B decomposes the gap change into female and male wage growth. Panel C shows sensitivity to weighting, outcome definition, and individual industry influence. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex_tab4, "../tables/tab4_robustness.tex")

# ============================================================================
# TABLE 5: Heterogeneity
# ============================================================================
cat("=== Table 5: Heterogeneity ===\n")

bh1 <- coef(m_hetero)["post_treat"]; sh1 <- se(m_hetero)["post_treat"]
ph1 <- pvalue(m_hetero)["post_treat"]
bh2 <- coef(m_hetero)["post_treat:high_private"]
sh2 <- se(m_hetero)["post_treat:high_private"]
ph2 <- pvalue(m_hetero)["post_treat:high_private"]

bf1 <- coef(m_fem)["post_treat"]; sf1 <- se(m_fem)["post_treat"]
pf1 <- pvalue(m_fem)["post_treat"]
bf2 <- coef(m_fem)["post_treat:fem_dominated"]
sf2 <- se(m_fem)["post_treat:fem_dominated"]
pf2 <- pvalue(m_fem)["post_treat:fem_dominated"]

tex_tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity by Industry Characteristics}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & Private Sector & Gender Composition \\\\",
  "\\hline",
  sprintf("$\\text{Post} \\times \\text{TreatIntensity}$ & $%.2f%s$ & $%.2f%s$ \\\\",
          bh1, star(ph1), bf1, star(pf1)),
  sprintf(" & $(%.2f)$ & $(%.2f)$ \\\\[3pt]", sh1, sf1),
  sprintf("$\\text{Post} \\times \\text{TreatIntensity} \\times \\text{HighPrivate}$ & $%.2f%s$ & \\\\",
          bh2, star(ph2)),
  sprintf(" & $(%.2f)$ & \\\\[3pt]", sh2),
  sprintf("$\\text{Post} \\times \\text{TreatIntensity} \\times \\text{FemDominated}$ & & $%.2f%s$ \\\\",
          bf2, star(pf2)),
  sprintf(" & & $(%.2f)$ \\\\[6pt]", sf2),
  "Industry FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  sprintf("Observations & %d & %d \\\\", nobs(m_hetero), nobs(m_fem)),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:} Column (1) interacts treatment intensity with an indicator for industries with above-median private sector employment share. Column (2) interacts with an indicator for industries with above-median pre-reform gender wage ratio (i.e., more gender-equal industries). Standard errors clustered by industry in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex_tab5, "../tables/tab5_heterogeneity.tex")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Continuous treatment: SDE = β × SD(X) / SD(Y)
sd_x <- sde$sd_treat  # SD of treatment intensity

# Panel A: Pooled
sde_monthly <- coef(m1)["post_treat"] * sd_x / sde$pre_sd_gap
se_sde_monthly <- se(m1)["post_treat"] * sd_x / sde$pre_sd_gap

sde_basic <- coef(m4)["post_treat"] * sd_x / sde$pre_sd_gap
se_sde_basic <- se(m4)["post_treat"] * sd_x / sde$pre_sd_gap

sde_abs <- coef(m5)["post_treat"] * sd_x / sde$pre_sd_abs
se_sde_abs <- se(m5)["post_treat"] * sd_x / sde$pre_sd_abs

classify <- function(sde_val) {
  if (is.na(sde_val)) return("---")
  if (sde_val < -0.15) "Large negative"
  else if (sde_val < -0.05) "Moderate negative"
  else if (sde_val < -0.005) "Small negative"
  else if (sde_val <= 0.005) "Null"
  else if (sde_val <= 0.05) "Small positive"
  else if (sde_val <= 0.15) "Moderate positive"
  else "Large positive"
}

# Panel B: Heterogeneity (sample splits)
# Recreate high_private indicator
median_priv <- median(df$private_share, na.rm = TRUE)
df$high_private <- as.integer(df$private_share > median_priv)
df_hp <- df %>% filter(high_private == 1, !is.na(private_share))
df_lp <- df %>% filter(high_private == 0, !is.na(private_share))

m_hp <- feols(gap_monthly ~ post_treat | industry + year, data = df_hp, cluster = ~industry)
m_lp <- feols(gap_monthly ~ post_treat | industry + year, data = df_lp, cluster = ~industry)

sd_y_hp <- sd(df_hp$gap_monthly[df_hp$year < 2017], na.rm = TRUE)
sd_y_lp <- sd(df_lp$gap_monthly[df_lp$year < 2017], na.rm = TRUE)

sde_hp <- coef(m_hp)["post_treat"] * sd_x / sd_y_hp
se_sde_hp <- se(m_hp)["post_treat"] * sd_x / sd_y_hp
sde_lp <- coef(m_lp)["post_treat"] * sd_x / sd_y_lp
se_sde_lp <- se(m_lp)["post_treat"] * sd_x / sd_y_lp

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Sweden. ",
  "\\textbf{Research question:} Does mandatory written pay equity auditing for small employers (10--24 employees) reduce the within-industry gender wage gap? ",
  "\\textbf{Policy mechanism:} Sweden's 2016 Discrimination Act amendment (SFS~2016:828) lowered the threshold for compulsory annual pay equity audit documentation from 25 to 10 employees, forcing newly covered firms to identify, document, and plan corrections for gender-based pay differences, subject to inspection by the Equality Ombudsman. ",
  "\\textbf{Outcome definition:} Gender wage ratio---female average monthly salary as a percentage of male average monthly salary, computed within each NACE Rev.~2 one-letter industry section from the SCB Wage Structure Survey. ",
  "\\textbf{Treatment:} Continuous---pre-reform (2010--2016) average share of firms with 10--19 employees in each industry, capturing industry-level exposure to the mandate expansion. ",
  "\\textbf{Data:} Statistics Sweden Wage Structure Survey (AM0110, 2014--2024) and Enterprise Register (FDBR07N, 2008--2025); 19 NACE sections $\\times$ 11 years = 209 industry--year observations. ",
  "\\textbf{Method:} Continuous treatment intensity difference-in-differences with industry and year fixed effects; standard errors clustered by industry. ",
  "\\textbf{Sample:} All 19 NACE Rev.~2 one-letter industry sections in the Swedish private and public sector, excluding the aggregate ``all industries'' category. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-industry standard deviation of treatment intensity and SD($Y$) is the pre-treatment (2014--2016) standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tex_sde <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Monthly wage ratio & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\",
          coef(m1)["post_treat"], se(m1)["post_treat"], sde$pre_sd_gap,
          sde_monthly, se_sde_monthly, classify(sde_monthly)),
  sprintf("Basic salary ratio & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\",
          coef(m4)["post_treat"], se(m4)["post_treat"], sde$pre_sd_gap,
          sde_basic, se_sde_basic, classify(sde_basic)),
  sprintf("Absolute gap (SEK) & %.0f & %.0f & %.0f & %.4f & %.4f & %s \\\\[6pt]",
          coef(m5)["post_treat"], se(m5)["post_treat"], sde$pre_sd_abs,
          sde_abs, se_sde_abs, classify(sde_abs)),
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]",
  sprintf("High private share & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\",
          coef(m_hp)["post_treat"], se(m_hp)["post_treat"], sd_y_hp,
          sde_hp, se_sde_hp, classify(sde_hp)),
  sprintf("Low private share & %.2f & %.2f & %.2f & %.4f & %.4f & %s \\\\",
          coef(m_lp)["post_treat"], se(m_lp)["post_treat"], sd_y_lp,
          sde_lp, se_sde_lp, classify(sde_lp)),
  "\\hline\\hline",
  sprintf("\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\begin{itemize}[leftmargin=*,nosep] %s \\end{itemize}} \\\\", sde_notes),
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tex_sde, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
for (f in list.files("../tables", pattern = "\\.tex$")) {
  cat(sprintf("  ✓ %s\n", f))
}
