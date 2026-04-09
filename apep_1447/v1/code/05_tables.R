## 05_tables.R — Generate all tables for paper
source("00_packages.R")

panel <- read_csv("../data/panel_clean.csv", show_col_types = FALSE)
load("../data/main_results.RData")
load("../data/robustness_results.RData")

options("modelsummary_format_numeric_latex" = "plain")
options(modelsummary_factory_latex = "kableExtra")
cat("=== Generating Tables ===\n")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("Table 1: Summary statistics...\n")

tab1_data <- panel %>%
  filter(year <= 2015) %>%
  group_by(high_kaitz) %>%
  summarise(
    across(c(unemp_rate, lfp_rate, emp_rate, min_wage, grdp_pc),
           list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE))),
    n_prov = n_distinct(prov_id),
    n_obs = n(),
    .groups = "drop"
  )

# Full sample stats
full_stats <- panel %>%
  filter(year <= 2015) %>%
  summarise(
    across(c(unemp_rate, lfp_rate, emp_rate, min_wage, grdp_pc),
           list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE))),
    n_prov = n_distinct(prov_id),
    n_obs = n()
  )

# LaTeX table
tab1_tex <- sprintf("
\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Reform Province Characteristics (2011--2015)}
\\label{tab:summary}
\\begin{tabular}{lcccccc}
\\hline\\hline
 & \\multicolumn{2}{c}{High Kaitz} & \\multicolumn{2}{c}{Low Kaitz} & \\multicolumn{2}{c}{Full Sample} \\\\
 & Mean & SD & Mean & SD & Mean & SD \\\\
\\hline
Unemployment rate (\\%%) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\
LFP rate (\\%%) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\
Employment rate (\\%%) & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\
Min.\\ wage (IDR 000s) & %.0f & %.0f & %.0f & %.0f & %.0f & %.0f \\\\
GRDP per capita (IDR mn) & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\
\\hline
Provinces & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
Province-years & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Pre-reform (2011--2015) means and standard deviations by treatment group. High Kaitz provinces are those with above-median 2015--2016 minimum wage increase under PP78/2015. Minimum wages are provincial UMP (\\textit{Upah Minimum Provinsi}) in thousands of IDR. GRDP per capita at constant 2010 prices in millions of IDR. Employment rate = LFP $\\times$ (1 $-$ unemployment rate/100). Source: BPS \\textit{Statistik Indonesia} yearbooks 2012--2020.
\\end{tablenotes}
\\end{table}
",
tab1_data$unemp_rate_mean[2], tab1_data$unemp_rate_sd[2],
tab1_data$unemp_rate_mean[1], tab1_data$unemp_rate_sd[1],
full_stats$unemp_rate_mean, full_stats$unemp_rate_sd,
tab1_data$lfp_rate_mean[2], tab1_data$lfp_rate_sd[2],
tab1_data$lfp_rate_mean[1], tab1_data$lfp_rate_sd[1],
full_stats$lfp_rate_mean, full_stats$lfp_rate_sd,
tab1_data$emp_rate_mean[2], tab1_data$emp_rate_sd[2],
tab1_data$emp_rate_mean[1], tab1_data$emp_rate_sd[1],
full_stats$emp_rate_mean, full_stats$emp_rate_sd,
tab1_data$min_wage_mean[2], tab1_data$min_wage_sd[2],
tab1_data$min_wage_mean[1], tab1_data$min_wage_sd[1],
full_stats$min_wage_mean, full_stats$min_wage_sd,
tab1_data$grdp_pc_mean[2], tab1_data$grdp_pc_sd[2],
tab1_data$grdp_pc_mean[1], tab1_data$grdp_pc_sd[1],
full_stats$grdp_pc_mean, full_stats$grdp_pc_sd,
tab1_data$n_prov[2], tab1_data$n_prov[1], full_stats$n_prov,
tab1_data$n_obs[2], tab1_data$n_obs[1], full_stats$n_obs)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main DiD Results
# ---------------------------------------------------------------
cat("Table 2: Main results...\n")

# Use modelsummary for clean output
tab2_models <- list(
  "Log MW" = m1_mw,
  "Unemp. Rate" = m1_unemp,
  "LFP Rate" = m1_lfp,
  "Emp. Rate" = m1_emp
)

tab2_notes <- "\\textit{Notes:} Each column reports a separate regression of the outcome on Kaitz $\\times$ Post, with province and year fixed effects. Kaitz is the 2015--2016 minimum wage increase under PP78/2015 (continuous). Post = 1 for 2016--2019. Standard errors clustered at the province level in parentheses. Sample: 34 provinces $\\times$ 9 years (2011--2019) = 306 province-year observations. Source: BPS \\textit{Statistik Indonesia} yearbooks. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."

modelsummary(tab2_models,
             output = "../tables/tab2_main.tex",
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c("kaitz_x_post" = "Kaitz $\\times$ Post"),
             gof_map = c("nobs", "r.squared", "FE: prov_id", "FE: year"),
             title = "Effect of PP78/2015 Formula Wage on Labor Market Outcomes",
             notes = tab2_notes,
             escape = FALSE)

# ---------------------------------------------------------------
# Table 3: Binary Treatment and Controls
# ---------------------------------------------------------------
cat("Table 3: Binary treatment and controls...\n")

tab3_models <- list(
  "(1) Unemp" = m2_unemp,
  "(2) LFP" = m2_lfp,
  "(3) Emp" = m2_emp,
  "(4) Unemp+Ctrl" = m3_unemp,
  "(5) LFP+Ctrl" = m3_lfp,
  "(6) Emp+Ctrl" = m3_emp
)

tab3_notes <- "\\textit{Notes:} Columns (1)--(3) use binary treatment (High Kaitz = above-median 2015--2016 wage increase). Columns (4)--(6) add log GRDP per capita as a time-varying control to the continuous Kaitz specification. All models include province and year fixed effects. Standard errors clustered at the province level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."

modelsummary(tab3_models,
             output = "../tables/tab3_binary.tex",
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             gof_map = c("nobs", "r.squared"),
             title = "Binary Treatment and Controlled Specifications",
             notes = tab3_notes,
             escape = FALSE)

# ---------------------------------------------------------------
# Table 4: Robustness Checks
# ---------------------------------------------------------------
cat("Table 4: Robustness...\n")

tab4_models <- list(
  "(1) Base Unemp" = m1_unemp,
  "(2) Excl Java" = r1_unemp,
  "(3) Excl Resource" = r2_unemp,
  "(4) Placebo" = r4_unemp,
  "(5) Wage Bite" = r5_unemp
)

tab4_notes <- "\\textit{Notes:} Column (1): baseline continuous Kaitz specification. Column (2): excludes Java and Bali provinces (7 provinces). Column (3): excludes resource-dependent provinces (Riau, East/North Kalimantan, West Papua, Papua). Column (4): placebo test using 2013 as fake treatment year (pre-period only, 2011--2015). Column (5): uses 2015 wage bite (MW/GRDP) as alternative treatment intensity. All specifications include province and year fixed effects with standard errors clustered at the province level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."

modelsummary(tab4_models,
             output = "../tables/tab4_robustness.tex",
             stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
             coef_map = c("kaitz_x_post" = "Treatment $\\times$ Post",
                          "kaitz_x_placebo" = "Treatment $\\times$ Post",
                          "bite_x_post" = "Treatment $\\times$ Post"),
             gof_map = c("nobs", "r.squared"),
             title = "Robustness: Unemployment Rate",
             notes = tab4_notes,
             escape = FALSE)

# ---------------------------------------------------------------
# Table F1: SDE Appendix Table (MANDATORY)
# ---------------------------------------------------------------
cat("Table F1: Standardized Effect Sizes...\n")

# Compute SDE for main outcomes
# SDE = β / SD(Y) for binary treatment
# For continuous: SDE = β × SD(X) / SD(Y)

pre_panel <- panel %>% filter(year < 2016)

sd_unemp <- sd(pre_panel$unemp_rate)
sd_lfp <- sd(pre_panel$lfp_rate)
sd_emp <- sd(pre_panel$emp_rate)
sd_kaitz <- sd(pre_panel$kaitz_actual)

# Main results: continuous treatment
beta_unemp <- coef(m1_unemp)["kaitz_x_post"]
se_unemp <- se(m1_unemp)["kaitz_x_post"]
beta_lfp <- coef(m1_lfp)["kaitz_x_post"]
se_lfp <- se(m1_lfp)["kaitz_x_post"]
beta_emp <- coef(m1_emp)["kaitz_x_post"]
se_emp <- se(m1_emp)["kaitz_x_post"]

# SDE for continuous treatment: β × SD(X) / SD(Y)
sde_unemp <- beta_unemp * sd_kaitz / sd_unemp
se_sde_unemp <- se_unemp * sd_kaitz / sd_unemp
sde_lfp <- beta_lfp * sd_kaitz / sd_lfp
se_sde_lfp <- se_lfp * sd_kaitz / sd_lfp
sde_emp <- beta_emp * sd_kaitz / sd_emp
se_sde_emp <- se_emp * sd_kaitz / sd_emp

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
pooled_rows <- data.frame(
  Outcome = c("Unemployment rate", "LFP rate", "Employment rate"),
  Beta = c(beta_unemp, beta_lfp, beta_emp),
  SE = c(se_unemp, se_lfp, se_emp),
  SD_Y = c(sd_unemp, sd_lfp, sd_emp),
  SDE = c(sde_unemp, sde_lfp, sde_emp),
  SE_SDE = c(se_sde_unemp, se_sde_lfp, se_sde_emp),
  stringsAsFactors = FALSE
)
pooled_rows$Classification <- sapply(pooled_rows$SDE, classify_sde)

# Panel B: Heterogeneous (excl Java vs Java only)
# Java/Bali subsample
java_bali_ids <- c(31, 32, 33, 34, 35, 36, 51)

m_java_unemp <- feols(unemp_rate ~ kaitz_x_post | prov_id + year,
                      data = panel %>% filter(prov_id %in% java_bali_ids),
                      cluster = ~prov_id)
m_outer_unemp <- feols(unemp_rate ~ kaitz_x_post | prov_id + year,
                       data = panel %>% filter(!(prov_id %in% java_bali_ids)),
                       cluster = ~prov_id)

pre_java <- panel %>% filter(year < 2016, prov_id %in% java_bali_ids)
pre_outer <- panel %>% filter(year < 2016, !(prov_id %in% java_bali_ids))

sde_java <- coef(m_java_unemp) * sd(pre_java$kaitz_actual) / sd(pre_java$unemp_rate)
se_sde_java <- se(m_java_unemp) * sd(pre_java$kaitz_actual) / sd(pre_java$unemp_rate)
sde_outer <- coef(m_outer_unemp) * sd(pre_outer$kaitz_actual) / sd(pre_outer$unemp_rate)
se_sde_outer <- se(m_outer_unemp) * sd(pre_outer$kaitz_actual) / sd(pre_outer$unemp_rate)

het_rows <- data.frame(
  Outcome = c("Unemp. rate (Java/Bali)", "Unemp. rate (Outer Islands)"),
  Beta = c(coef(m_java_unemp), coef(m_outer_unemp)),
  SE = c(se(m_java_unemp), se(m_outer_unemp)),
  SD_Y = c(sd(pre_java$unemp_rate), sd(pre_outer$unemp_rate)),
  SDE = c(sde_java, sde_outer),
  SE_SDE = c(se_sde_java, se_sde_outer),
  stringsAsFactors = FALSE
)
het_rows$Classification <- sapply(het_rows$SDE, classify_sde)

# Generate LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Indonesia. ",
  "\\textbf{Research question:} Does replacing discretionary district-level minimum wage negotiations with a binding national formula (PP78/2015) affect provincial unemployment, labor force participation, and employment rates? ",
  "\\textbf{Policy mechanism:} PP78/2015 replaced annual wage council negotiations with a mechanical formula tying minimum wage growth to national CPI inflation plus GDP growth, removing local discretion and creating binding upward shocks in provinces where the formula exceeded the prior negotiated wage. ",
  "\\textbf{Outcome definition:} Province-level open unemployment rate (Tingkat Pengangguran Terbuka) from BPS August SAKERNAS round; labor force participation rate (TPAK); employment rate (LFP $\\times$ (1 $-$ unemployment rate/100)). ",
  "\\textbf{Treatment:} Continuous Kaitz index measuring the proportional 2015--2016 minimum wage increase under the PP78 formula. ",
  "\\textbf{Data:} BPS \\textit{Statistik Indonesia} yearbooks 2012--2020, 34 provinces, 2011--2019, 306 province-year observations. ",
  "\\textbf{Method:} Two-way fixed effects (province + year) with continuous treatment intensity; standard errors clustered at province level with wild cluster bootstrap. ",
  "\\textbf{Sample:} All 34 Indonesian provinces; Panel B splits Java/Bali (7 provinces, high urbanization and manufacturing share) vs.\\ Outer Islands (27 provinces, more agricultural and informal). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of the Kaitz index. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

format_row <- function(r) {
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s",
          r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification)
}

tabF1_tex <- paste0(
"\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
", paste(sapply(1:nrow(pooled_rows), function(i) format_row(pooled_rows[i,])), collapse = " \\\\\n"),
" \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Java/Bali vs.\\ Outer Islands)}} \\\\
", paste(sapply(1:nrow(het_rows), function(i) format_row(het_rows[i,])), collapse = " \\\\\n"),
" \\\\
\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{table}
")

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_binary.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
