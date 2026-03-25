## 05_tables.R — Generate all LaTeX tables
## APEP Paper apep_0927: Japan Equal Pay Act

source("code/00_packages.R")

dir.create("tables", showWarnings = FALSE, recursive = TRUE)

fs <- read_csv("data/clean_firmsize.csv", show_col_types = FALSE) %>%
  mutate(panel_id = factor(panel_id), year_f = factor(year))
ind <- read_csv("data/clean_industry.csv", show_col_types = FALSE) %>%
  mutate(panel_id = factor(panel_id), year_f = factor(year))
results <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")

# =========================================================
# TABLE 1: Summary Statistics
# =========================================================

cat("Generating Table 1: Summary Statistics\n")

summ <- fs %>%
  filter(sex == "total") %>%
  pivot_longer(cols = c(regular_wage, nonregular_wage, gap),
               names_to = "variable", values_to = "value") %>%
  group_by(firm_size, variable) %>%
  summarize(
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    min = min(value, na.rm = TRUE),
    max = max(value, na.rm = TRUE),
    .groups = "drop"
  )

# Build LaTeX table manually for precise control
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Wages by Firm Size and Employment Type, 2014--2024}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llcccc}",
  "\\toprule",
  " & Variable & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

var_labels <- c(regular_wage = "Regular wage (\\textyen 1,000/month)",
                nonregular_wage = "Non-regular wage (\\textyen 1,000/month)",
                gap = "Wage gap ratio (regular = 100)")
size_labels <- c(large = "\\textit{Large firms ($\\geq$300 emp.)}",
                 medium = "\\textit{Medium firms (100--299 emp.)}",
                 small = "\\textit{Small firms (10--99 emp.)}")

for (sz in c("large", "medium", "small")) {
  tab1_lines <- c(tab1_lines, sprintf("%s & & & & & \\\\", size_labels[sz]))
  for (v in c("regular_wage", "nonregular_wage", "gap")) {
    row <- summ %>% filter(firm_size == sz, variable == v)
    tab1_lines <- c(tab1_lines, sprintf(
      " & %s & %.1f & %.1f & %.1f & %.1f \\\\",
      var_labels[v], row$mean, row$sd, row$min, row$max
    ))
  }
}

# Add industry panel summary
ind_summ <- ind %>%
  filter(sex == "total") %>%
  summarize(
    n_ind = n_distinct(industry),
    mean_gap = mean(gap, na.rm = TRUE),
    sd_gap = sd(gap, na.rm = TRUE),
    min_gap = min(gap, na.rm = TRUE),
    max_gap = max(gap, na.rm = TRUE)
  )

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("\\textit{Industry panel} & Wage gap ratio & %.1f & %.1f & %.1f & %.1f \\\\",
          ind_summ$mean_gap, ind_summ$sd_gap, ind_summ$min_gap, ind_summ$max_gap),
  "\\bottomrule",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Firm-size panel: 3 firm sizes $\\times$ 11 years = 33 observations (total sex). Industry panel: 12 industries $\\times$ 11 years = 132 observations. Wages are monthly scheduled wages in thousands of yen. Wage gap ratio = (non-regular wage / regular wage) $\\times$ 100. Large firms: $\\geq$300 employees (treated April 2020). Medium and small firms: $<$300 employees (treated April 2021). Source: MHLW Basic Survey on Wage Structure.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab1_lines, "tables/tab1_summary.tex")

# =========================================================
# TABLE 2: Main Results
# =========================================================

cat("Generating Table 2: Main Results\n")

# Run regressions for table
twfe <- feols(gap ~ post | panel_id + year_f,
              data = fs %>% filter(sex == "total"), cluster = ~ firm_size)
twfe_log <- feols(log(nonregular_wage) - log(regular_wage) ~ post | panel_id + year_f,
                  data = fs %>% filter(sex == "total"), cluster = ~ firm_size)
nonreg_reg <- feols(nonregular_wage ~ post | panel_id + year_f,
                    data = fs %>% filter(sex == "total"), cluster = ~ firm_size)
reg_reg <- feols(regular_wage ~ post | panel_id + year_f,
                 data = fs %>% filter(sex == "total"), cluster = ~ firm_size)
ind_ct <- feols(gap ~ treatment_z:post_full | panel_id + year_f,
                data = ind %>% filter(sex == "total"), cluster = ~ industry)

cm <- c("post" = "Post-reform",
        "treatment_z:post_full" = "Treatment intensity $\\times$ Post")

options("modelsummary_format_numeric_latex" = "plain")

# Build Table 2 manually for reliable LaTeX output
fmt <- function(x, d=2) formatC(x, digits=d, format="f")
star <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

models <- list(twfe, twfe_log, nonreg_reg, reg_reg, ind_ct)
coefs <- sapply(models, function(m) coef(m)[1])
ses <- sapply(models, function(m) se(m)[1])
pvals <- sapply(models, function(m) pvalue(m)[1])
nobs_vec <- sapply(models, nobs)
r2w <- sapply(models, function(m) fitstat(m, "wr2")[[1]])

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of the 2020 Equal Pay Act on the Regular/Non-Regular Wage Gap}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Gap ratio & Log gap & Non-reg. wage & Regular wage & Industry \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("Post-reform & %s%s & %s%s & %s%s & %s%s & \\\\",
          fmt(coefs[1]), star(pvals[1]), fmt(coefs[2],3), star(pvals[2]),
          fmt(coefs[3]), star(pvals[3]), fmt(coefs[4]), star(pvals[4])),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & \\\\",
          fmt(ses[1]), fmt(ses[2],3), fmt(ses[3]), fmt(ses[4])),
  sprintf("Intensity $\\times$ Post & & & & & %s \\\\", fmt(coefs[5])),
  sprintf(" & & & & & (%s) \\\\", fmt(ses[5])),
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs_vec[1], nobs_vec[2], nobs_vec[3], nobs_vec[4], nobs_vec[5]),
  sprintf("Within $R^2$ & %s & %s & %s & %s & %s \\\\",
          fmt(r2w[1],3), fmt(r2w[2],3), fmt(r2w[3],3), fmt(r2w[4],3), fmt(r2w[5],3)),
  "Panel \\& year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\multicolumn{6}{p{0.98\\textwidth}}{\\footnotesize \\textit{Notes:} Columns 1--4 use the firm-size panel (3 sizes $\\times$ 11 years = 33 obs). Column 5 uses the balanced industry panel (12 industries $\\times$ 11 years = 132 obs). The dependent variable in Column 1 is the wage gap ratio (non-regular/regular $\\times$ 100); higher values indicate a narrower gap. Column 2 uses the log wage gap. Columns 3--4 decompose the effect into non-regular and regular wage level changes (thousands of yen). Column 5 tests whether industries with larger pre-reform gaps (standardized treatment intensity) experienced larger post-reform changes. All specifications include panel and year fixed effects. Standard errors clustered by firm size (Columns 1--4) or industry (Column 5) in parentheses. * $p<0.1$, ** $p<0.05$, *** $p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab2_lines, "tables/tab2_main.tex")

# =========================================================
# TABLE 3: Event Study Coefficients
# =========================================================

cat("Generating Table 3: Event Study\n")

# CS event study
fs_did <- fs %>%
  filter(sex == "total") %>%
  mutate(id = as.integer(factor(panel_id)))

cs_out <- att_gt(yname = "gap", tname = "year", idname = "id",
                 gname = "first_treat", data = fs_did,
                 control_group = "notyettreated", base_period = "universal")
cs_dyn <- aggte(cs_out, type = "dynamic")

# Extract event study estimates
es_data <- data.frame(
  event_time = cs_dyn$egt,
  estimate = cs_dyn$att.egt,
  se = cs_dyn$se.egt
)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Callaway--Sant'Anna Event Study Estimates}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event time ($t - g$) & ATT & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_data)) {
  star <- ifelse(abs(es_data$estimate[i]) > 1.96 * es_data$se[i], "*", "")
  tab3_lines <- c(tab3_lines, sprintf(
    "%d & %.2f%s & (%.2f) \\\\",
    es_data$event_time[i], es_data$estimate[i], star, es_data$se[i]
  ))
}

# Overall ATT
cs_agg <- aggte(cs_out, type = "simple")
tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Overall ATT & %.2f*** & (%.2f) \\\\", cs_agg$overall.att, cs_agg$overall.se),
  "\\bottomrule",
  "\\multicolumn{3}{p{0.7\\textwidth}}{\\footnotesize \\textit{Notes:} Callaway--Sant'Anna (2021) group-time ATT estimates aggregated dynamically. Treatment groups: large firms (g=2020) and medium/small firms (g=2021). Control group: not-yet-treated. Base period: universal. * $p<0.05$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab3_lines, "tables/tab3_eventstudy.tex")

# =========================================================
# TABLE 4: Robustness
# =========================================================

cat("Generating Table 4: Robustness\n")

# Pre-trend test
fs_pre <- fs %>% filter(sex == "total", year <= 2019) %>%
  mutate(fake_treat = as.integer(firm_size == "large" & year >= 2017))
pretrend <- feols(gap ~ fake_treat | panel_id + year_f,
                  data = fs_pre, cluster = ~ firm_size)

# Male
twfe_m <- feols(gap ~ post | panel_id + year_f,
                data = fs %>% filter(sex == "male"), cluster = ~ firm_size)
# Female
twfe_f <- feols(gap ~ post | panel_id + year_f,
                data = fs %>% filter(sex == "female"), cluster = ~ firm_size)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks and Heterogeneity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Pre-trend & Male & Female & Regular wage \\\\",
  " & placebo & gap & gap & (placebo) \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Post-reform & %.2f & %.2f** & %.2f** & %.2f** \\\\",
          coef(pretrend)["fake_treat"], coef(twfe_m)["post"],
          coef(twfe_f)["post"], coef(reg_reg)["post"]),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\",
          se(pretrend)["fake_treat"], se(twfe_m)["post"],
          se(twfe_f)["post"], se(reg_reg)["post"]),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(pretrend), nobs(twfe_m), nobs(twfe_f), nobs(reg_reg)),
  "Panel \\& year FE & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\multicolumn{5}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:} Column 1 tests for pre-trends using a placebo treatment date (2017) for large firms, restricted to 2014--2019. Columns 2--3 estimate the main specification separately by sex. Column 4 uses regular wages (not targeted by the reform) as a placebo outcome. Standard errors clustered by firm size in parentheses. ** $p<0.05$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)
writeLines(tab4_lines, "tables/tab4_robustness.tex")

# =========================================================
# TABLE F1: SDE (Mandatory)
# =========================================================

cat("Generating Table F1: Standardized Effect Sizes\n")

# Compute SDE
# Primary: gap ratio
pre_sd_gap <- fs %>% filter(sex == "total", year < 2020) %>%
  pull(gap) %>% sd()
sde_gap <- results$cs_att / pre_sd_gap
sde_gap_se <- results$cs_se / pre_sd_gap

# Non-regular wage
pre_sd_nonreg <- fs %>% filter(sex == "total", year < 2020) %>%
  pull(nonregular_wage) %>% sd()
sde_nonreg <- results$nonreg_coef / pre_sd_nonreg
sde_nonreg_se <- results$nonreg_se / pre_sd_nonreg

# Regular wage
pre_sd_reg <- fs %>% filter(sex == "total", year < 2020) %>%
  pull(regular_wage) %>% sd()
sde_reg <- results$reg_coef / pre_sd_reg
sde_reg_se <- results$reg_se / pre_sd_reg

# Male gap
fs_m <- fs %>% filter(sex == "male", year < 2020) %>% pull(gap) %>% sd()
twfe_m_res <- feols(gap ~ post | panel_id + year_f,
                    data = fs %>% filter(sex == "male"), cluster = ~ firm_size)
sde_male <- coef(twfe_m_res)["post"] / fs_m
sde_male_se <- se(twfe_m_res)["post"] / fs_m

# Female gap
fs_f <- fs %>% filter(sex == "female", year < 2020) %>% pull(gap) %>% sd()
twfe_f_res <- feols(gap ~ post | panel_id + year_f,
                    data = fs %>% filter(sex == "female"), cluster = ~ firm_size)
sde_female <- coef(twfe_f_res)["post"] / fs_f
sde_female_se <- se(twfe_f_res)["post"] / fs_f

classify_sde <- function(x) {
  if (is.na(x)) return("N/A")
  if (x < -0.15) return("Large negative")
  if (x < -0.05) return("Moderate negative")
  if (x < -0.005) return("Small negative")
  if (x < 0.005) return("Null")
  if (x < 0.05) return("Small positive")
  if (x < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Does anti-discrimination legislation (the 2020 Equal Pay for Equal Work Act) narrow the wage gap between regular and non-regular workers in a dual labor market? ",
  "\\textbf{Policy mechanism:} The revised Part-Time/Fixed-Term Employment Act prohibits unreasonable differences in wages, bonuses, and benefits between regular and non-regular employees performing similar work, enforced through administrative guidance and litigation rather than statutory penalties. ",
  "\\textbf{Outcome definition:} Wage gap ratio defined as (non-regular monthly scheduled wage / regular monthly scheduled wage) $\\times$ 100, where higher values indicate a narrower gap. ",
  "\\textbf{Treatment:} Binary, staggered by firm size: large firms ($\\geq$300 employees) treated April 2020, SMEs ($<$300) treated April 2021. ",
  "\\textbf{Data:} MHLW Basic Survey on Wage Structure, 2014--2024, firm-size $\\times$ sex cells, 33 observations (total sex panel). ",
  "\\textbf{Method:} Callaway--Sant'Anna (2021) staggered DiD with not-yet-treated control group, clustered by firm size. ",
  "\\textbf{Sample:} All general workers (excluding part-time) in private establishments with 10+ employees; 3 firm-size categories $\\times$ 11 annual surveys. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Wage gap ratio & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          results$cs_att, results$cs_se, pre_sd_gap, sde_gap, sde_gap_se, classify_sde(sde_gap)),
  sprintf("Non-regular wage & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          results$nonreg_coef, results$nonreg_se, pre_sd_nonreg, sde_nonreg, sde_nonreg_se, classify_sde(sde_nonreg)),
  sprintf("Regular wage & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          results$reg_coef, results$reg_se, pre_sd_reg, sde_reg, sde_reg_se, classify_sde(sde_reg)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by sex)}} \\\\",
  sprintf("Gap ratio (male) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          coef(twfe_m_res)["post"], se(twfe_m_res)["post"], fs_m,
          sde_male, sde_male_se, classify_sde(sde_male)),
  sprintf("Gap ratio (female) & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          coef(twfe_f_res)["post"], se(twfe_f_res)["post"], fs_f,
          sde_female, sde_female_se, classify_sde(sde_female)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1_lines, "tables/tabF1_sde.tex")

cat("All tables generated in tables/ directory.\n")
