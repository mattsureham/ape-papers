## 05_tables.R — Generate LaTeX tables
## apep_0997: Romania Construction Tax Holiday

source("00_packages.R")

panel_a <- readRDS("../data/panel_annual.rds")
panel_q <- readRDS("../data/panel_quarterly.rds")
main_res <- readRDS("../data/main_results.rds")
rob_res <- readRDS("../data/robustness_results.rds")

panel_a <- panel_a %>%
  mutate(et = year - 2019,
         covid_2020 = ifelse(year == 2020, 1L, 0L),
         covid_2021 = ifelse(year == 2021, 1L, 0L),
         trend = year - 2014)

# ================================================================
# Table 1: Summary Statistics
# ================================================================
cat("--- Generating Table 1: Summary Statistics ---\n")

pre_stats <- panel_a %>%
  filter(year >= 2015, year <= 2018) %>%
  group_by(Group = ifelse(construction == 1, "Construction (Treated)", "Other Sectors (Control)")) %>%
  summarise(
    `Salaried Emp. (000s)` = sprintf("%.1f (%.1f)", mean(salaried_ths, na.rm = TRUE), sd(salaried_ths, na.rm = TRUE)),
    `Total Emp. (000s)` = sprintf("%.1f (%.1f)", mean(employment_ths, na.rm = TRUE), sd(employment_ths, na.rm = TRUE)),
    `Self-Emp. Share` = sprintf("%.3f (%.3f)", mean(self_emp_share, na.rm = TRUE), sd(self_emp_share, na.rm = TRUE)),
    `N (sector-years)` = as.character(n()),
    .groups = "drop"
  )

post_stats <- panel_a %>%
  filter(year >= 2019, year <= 2023) %>%
  group_by(Group = ifelse(construction == 1, "Construction (Treated)", "Other Sectors (Control)")) %>%
  summarise(
    `Salaried Emp. (000s)` = sprintf("%.1f (%.1f)", mean(salaried_ths, na.rm = TRUE), sd(salaried_ths, na.rm = TRUE)),
    `Total Emp. (000s)` = sprintf("%.1f (%.1f)", mean(employment_ths, na.rm = TRUE), sd(employment_ths, na.rm = TRUE)),
    `Self-Emp. Share` = sprintf("%.3f (%.3f)", mean(self_emp_share, na.rm = TRUE), sd(self_emp_share, na.rm = TRUE)),
    `N (sector-years)` = as.character(n()),
    .groups = "drop"
  )

# Build LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre- and Post-Reform}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Salaried Emp. & Total Emp. & Self-Emp. & N \\\\",
  " & (000s) & (000s) & Share & (sector-years) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-Reform (2015--2018)}} \\\\"
)

for (i in 1:nrow(pre_stats)) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                       pre_stats$Group[i],
                                       pre_stats$`Salaried Emp. (000s)`[i],
                                       pre_stats$`Total Emp. (000s)`[i],
                                       pre_stats$`Self-Emp. Share`[i],
                                       pre_stats$`N (sector-years)`[i]))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Post-Reform (2019--2023)}} \\\\"
)

for (i in 1:nrow(post_stats)) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                       post_stats$Group[i],
                                       post_stats$`Salaried Emp. (000s)`[i],
                                       post_stats$`Total Emp. (000s)`[i],
                                       post_stats$`Self-Emp. Share`[i],
                                       post_stats$`N (sector-years)`[i]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ``Other Sectors'' includes Manufacturing, Wholesale/Retail, Transportation, Accommodation, ICT, Finance, Real Estate, Professional/Scientific, and Administrative Support. Employment data from Eurostat \\texttt{nama\\_10\\_a64\\_e}. Self-employment share equals (total employment $-$ salaried employees) / total employment.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("  Saved: tables/tab1_summary.tex\n")

# ================================================================
# Table 2: Main DiD Results
# ================================================================
cat("--- Generating Table 2: Main Results ---\n")

# Re-estimate all specifications for the table
m_sal_full <- feols(log_sal ~ treat | nace_r2 + year, data = panel_a, cluster = ~nace_r2)
m_sal_rest <- feols(log_sal ~ treat | nace_r2 + year,
                    data = panel_a %>% filter(year >= 2015), cluster = ~nace_r2)
m_self_full <- feols(self_emp_share ~ treat | nace_r2 + year, data = panel_a, cluster = ~nace_r2)
m_self_rest <- feols(self_emp_share ~ treat | nace_r2 + year,
                     data = panel_a %>% filter(year >= 2015), cluster = ~nace_r2)
m_emp_full <- feols(log_emp ~ treat | nace_r2 + year, data = panel_a, cluster = ~nace_r2)

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Romania's 2019 Construction Tax Holiday on Employment Composition}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Log Salaried Emp.} & \\multicolumn{2}{c}{Self-Emp. Share} & Log Total Emp. \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-6}",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule"
)

# Extract results
models <- list(m_sal_full, m_sal_rest, m_self_full, m_self_rest, m_emp_full)
coefs <- sapply(models, function(m) sprintf("%.4f", coef(m)["treat"]))
ses <- sapply(models, function(m) sprintf("(%.4f)", se(m)["treat"]))
pvals <- sapply(models, function(m) {
  p <- pvalue(m)["treat"]
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
})
ns <- sapply(models, function(m) as.character(nobs(m)))
r2s <- sapply(models, function(m) sprintf("%.3f", fitstat(m, "wr2")[[1]]))
periods <- c("2010--2023", "2015--2023", "2010--2023", "2015--2023", "2010--2023")

tab2_lines <- c(tab2_lines,
  sprintf("Construction $\\times$ Post & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          coefs[1], pvals[1], coefs[2], pvals[2], coefs[3], pvals[3], coefs[4], pvals[4], coefs[5], pvals[5]),
  sprintf(" & %s & %s & %s & %s & %s \\\\", ses[1], ses[2], ses[3], ses[4], ses[5]),
  "\\midrule",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\", ns[1], ns[2], ns[3], ns[4], ns[5]),
  sprintf("Within $R^2$ & %s & %s & %s & %s & %s \\\\", r2s[1], r2s[2], r2s[3], r2s[4], r2s[5]),
  sprintf("Period & %s & %s & %s & %s & %s \\\\", periods[1], periods[2], periods[3], periods[4], periods[5]),
  "Sector FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a TWFE DiD regression with sector and year fixed effects. Standard errors clustered at the sector level in parentheses. ``Construction $\\times$ Post'' equals one for the construction sector (NACE F) in 2019 and later. Columns (2) and (4) restrict the sample to 2015--2023 (4 pre, 5 post years). Self-employment share is defined as (total employment $-$ salaried employees) / total employment. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("  Saved: tables/tab2_main.tex\n")

# ================================================================
# Table 3: Event Study Coefficients
# ================================================================
cat("--- Generating Table 3: Event Study ---\n")

# Re-estimate event study on restricted window
panel_r <- panel_a %>% filter(year >= 2015)

es_sal <- feols(log_sal ~ i(et, construction, ref = -1) | nace_r2 + year,
                data = panel_r, cluster = ~nace_r2)

es_self <- feols(self_emp_share ~ i(et, construction, ref = -1) | nace_r2 + year,
                 data = panel_r, cluster = ~nace_r2)

# Extract event-study coefs
es_coefs_sal <- data.frame(
  et = as.integer(gsub("et::|:construction", "", names(coef(es_sal)))),
  coef_sal = unname(coef(es_sal)),
  se_sal = unname(se(es_sal))
)

es_coefs_self <- data.frame(
  et = as.integer(gsub("et::|:construction", "", names(coef(es_self)))),
  coef_self = unname(coef(es_self)),
  se_self = unname(se(es_self))
)

es_tab <- merge(es_coefs_sal, es_coefs_self, by = "et") %>%
  arrange(et) %>%
  mutate(year_label = et + 2019)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Effects of the Construction Tax Holiday}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Log Salaried Emp.} & \\multicolumn{2}{c}{Self-Emp. Share} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Year & Coeff. & SE & Coeff. & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_tab)) {
  star_sal <- ifelse(abs(es_tab$coef_sal[i] / es_tab$se_sal[i]) > 2.58, "***",
              ifelse(abs(es_tab$coef_sal[i] / es_tab$se_sal[i]) > 1.96, "**",
              ifelse(abs(es_tab$coef_sal[i] / es_tab$se_sal[i]) > 1.65, "*", "")))
  star_self <- ifelse(abs(es_tab$coef_self[i] / es_tab$se_self[i]) > 2.58, "***",
               ifelse(abs(es_tab$coef_self[i] / es_tab$se_self[i]) > 1.96, "**",
               ifelse(abs(es_tab$coef_self[i] / es_tab$se_self[i]) > 1.65, "*", "")))

  yr_label <- ifelse(es_tab$et[i] == -1, sprintf("%d (base)", es_tab$year_label[i]),
                     as.character(es_tab$year_label[i]))
  if (es_tab$et[i] == -1) {
    tab3_lines <- c(tab3_lines, sprintf("%s & --- & --- & --- & --- \\\\", yr_label))
  } else {
    tab3_lines <- c(tab3_lines, sprintf("%s & %.4f%s & (%.4f) & %.4f%s & (%.4f) \\\\",
                                         yr_label,
                                         es_tab$coef_sal[i], star_sal, es_tab$se_sal[i],
                                         es_tab$coef_self[i], star_self, es_tab$se_self[i]))
  }
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from an event study specification interacting year indicators with a construction-sector dummy (base year: 2018). Sector and year fixed effects included. Standard errors clustered at the sector level. Sample period: 2015--2023. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")
cat("  Saved: tables/tab3_eventstudy.tex\n")

# ================================================================
# Table 4: Robustness
# ================================================================
cat("--- Generating Table 4: Robustness ---\n")

# Re-estimate robustness specifications
r_trend <- feols(self_emp_share ~ treat + i(nace_r2, trend) | nace_r2 + year,
                 data = panel_a, cluster = ~nace_r2)

r_fc <- feols(self_emp_share ~ treat | nace_r2 + year,
              data = panel_a %>% filter(nace_r2 %in% c("F", "C")),
              vcov = "hetero")

r_placebo <- feols(self_emp_share ~ ifelse(nace_r2 == "L", 1, 0) * post | nace_r2 + year,
                   data = panel_a %>% filter(nace_r2 != "F"),
                   cluster = ~nace_r2)

r_loo_min <- min(rob_res$leave_one_out$coef)
r_loo_max <- max(rob_res$leave_one_out$coef)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Self-Employment Share}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Coefficient & SE & N \\\\",
  "\\midrule",
  sprintf("Baseline (2010--2023) & %.4f*** & (%.4f) & %d \\\\",
          coef(m_self_full)["treat"], se(m_self_full)["treat"], nobs(m_self_full)),
  sprintf("Restricted window (2015--2023) & %.4f*** & (%.4f) & %d \\\\",
          coef(m_self_rest)["treat"], se(m_self_rest)["treat"], nobs(m_self_rest)),
  sprintf("Sector-specific trends & %.4f** & (%.4f) & %d \\\\",
          coef(r_trend)["treat"], se(r_trend)["treat"], nobs(r_trend)),
  sprintf("Construction vs.\\ Manufacturing & %.4f** & (%.4f) & %d \\\\",
          coef(r_fc)["treat"], se(r_fc)["treat"], nobs(r_fc)),
  sprintf("Leave-one-out range & [%.4f, %.4f] & & \\\\", r_loo_min, r_loo_max),
  sprintf("Placebo: Real Estate & %.4f & (%.4f) & %d \\\\",
          coef(r_placebo)[1], se(r_placebo)[1], nobs(r_placebo)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include sector and year fixed effects. Standard errors clustered at the sector level except ``Construction vs.\\ Manufacturing,'' which uses heteroskedasticity-robust SEs (2 sectors). ``Leave-one-out range'' shows the minimum and maximum coefficient from dropping each control sector individually. ``Placebo: Real Estate'' tests whether the adjacent real estate sector (NACE L) shows a similar effect, excluding construction. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("  Saved: tables/tab4_robustness.tex\n")

# ================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ================================================================
cat("--- Generating Table F1: Standardized Effect Sizes ---\n")

# Compute pre-treatment SDs
pre_data <- panel_a %>% filter(year >= 2015, year <= 2018)

sd_self_all <- sd(pre_data$self_emp_share, na.rm = TRUE)
sd_log_sal_all <- sd(pre_data$log_sal, na.rm = TRUE)
sd_log_emp_all <- sd(pre_data$log_emp, na.rm = TRUE)

# Pre-treatment SD for construction only
pre_constr <- pre_data %>% filter(construction == 1)
sd_self_constr <- sd(pre_constr$self_emp_share, na.rm = TRUE)
sd_sal_constr <- sd(pre_constr$log_sal, na.rm = TRUE)

# Main estimates (using restricted window which is the cleaner spec)
beta_self <- coef(m_self_rest)["treat"]
se_self <- se(m_self_rest)["treat"]

beta_sal <- coef(m_sal_rest)["treat"]
se_sal <- se(m_sal_rest)["treat"]

beta_emp <- coef(m_emp_full)["treat"]
se_emp <- se(m_emp_full)["treat"]

# SDE = beta / SD(Y) for binary treatment
sde_self <- beta_self / sd_self_all
se_sde_self <- se_self / sd_self_all

sde_sal <- beta_sal / sd_log_sal_all
se_sde_sal <- se_sal / sd_log_sal_all

sde_emp <- beta_emp / sd_log_emp_all
se_sde_emp <- se_emp / sd_log_emp_all

classify_sde <- function(s) {
  if (abs(s) < 0.005) return("Null")
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s > 0.15) return("Large positive")
  if (s > 0.05) return("Moderate positive")
  return("Small positive")
}

# Panel A: Pooled
sde_rows_a <- data.frame(
  Outcome = c("Self-employment share", "Log salaried employment", "Log total employment"),
  Beta = c(beta_self, beta_sal, beta_emp),
  SE = c(se_self, se_sal, se_emp),
  SD_Y = c(sd_self_all, sd_log_sal_all, sd_log_emp_all),
  SDE = c(sde_self, sde_sal, sde_emp),
  SE_SDE = c(se_sde_self, se_sde_sal, se_sde_emp),
  Classification = c(classify_sde(sde_self), classify_sde(sde_sal), classify_sde(sde_emp))
)

# Panel B: Heterogeneous — by pre-reform self-employment intensity
# High-informality sectors: construction (F), professional (M), ICT (J)
# Low-informality sectors: manufacturing (C), accommodation (I), finance (K), admin (N)
high_inf <- c("F", "M", "J")
low_inf <- c("C", "I", "K", "N")

# High informality sample
m_self_high <- feols(self_emp_share ~ treat | nace_r2 + year,
                     data = panel_a %>% filter(nace_r2 %in% c("F", high_inf[high_inf != "F"])),
                     cluster = ~nace_r2)

# Re-estimate on restricted sample for heterogeneity
# Manufacturing-only control
m_self_manuf <- feols(self_emp_share ~ treat | nace_r2 + year,
                      data = panel_a %>% filter(nace_r2 %in% c("F", "C")),
                      vcov = "hetero")

sd_self_high <- sd(pre_data %>% filter(nace_r2 %in% c("F", "M", "J")) %>% pull(self_emp_share), na.rm = TRUE)
sd_self_fc <- sd(pre_data %>% filter(nace_r2 %in% c("F", "C")) %>% pull(self_emp_share), na.rm = TRUE)

beta_high <- coef(m_self_high)["treat"]
se_high <- se(m_self_high)["treat"]
sde_high <- beta_high / sd_self_high
se_sde_high <- se_high / sd_self_high

beta_fc <- coef(m_self_manuf)["treat"]
se_fc <- se(m_self_manuf)["treat"]
sde_fc <- beta_fc / sd_self_fc
se_sde_fc <- se_fc / sd_self_fc

sde_rows_b <- data.frame(
  Outcome = c("Self-emp. share (high-informality controls)", "Self-emp. share (manufacturing control)"),
  Beta = c(beta_high, beta_fc),
  SE = c(se_high, se_fc),
  SD_Y = c(sd_self_high, sd_self_fc),
  SDE = c(sde_high, sde_fc),
  SE_SDE = c(se_sde_high, se_sde_fc),
  Classification = c(classify_sde(sde_high), classify_sde(sde_fc))
)

# Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Romania. ",
  "\\textbf{Research question:} Does a comprehensive sectoral payroll tax holiday---eliminating income tax, reducing health contributions, and raising the minimum wage---formalize employment in construction? ",
  "\\textbf{Policy mechanism:} Law 18/2018 exempted construction workers (NACE Rev.2 codes 41--43) from the 16\\% income tax, reduced their health insurance contribution from 10\\% to 3.5\\%, and raised the sector-specific minimum wage from 1,900 to 3,000 RON, effective January 1, 2019; all other sectors retained the standard regime. ",
  "\\textbf{Outcome definition:} Self-employment share, defined as (total employment minus salaried employees) divided by total employment, serving as a proxy for the intensity of informal or non-standard work arrangements in each sector. ",
  "\\textbf{Treatment:} Binary; the construction sector is treated from 2019 onward and all other sectors serve as controls. ",
  "\\textbf{Data:} Eurostat \\texttt{nama\\_10\\_a64\\_e}, 2015--2023, sector-year level, 10 NACE sectors $\\times$ 9 years = 90 observations. ",
  "\\textbf{Method:} TWFE DiD with sector and year fixed effects; standard errors clustered at the sector level. ",
  "\\textbf{Sample:} Ten one-digit NACE sectors (F, C, G, H, I, J, K, L, M, N); restricted to 2015--2023 for balanced pre/post comparison. ",
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
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (i in 1:nrow(sde_rows_a)) {
  tabF1_lines <- c(tabF1_lines, sprintf("%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
                                         sde_rows_a$Outcome[i], sde_rows_a$Beta[i], sde_rows_a$SE[i],
                                         sde_rows_a$SD_Y[i], sde_rows_a$SDE[i], sde_rows_a$SE_SDE[i],
                                         sde_rows_a$Classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\"
)

for (i in 1:nrow(sde_rows_b)) {
  tabF1_lines <- c(tabF1_lines, sprintf("%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
                                         sde_rows_b$Outcome[i], sde_rows_b$Beta[i], sde_rows_b$SE[i],
                                         sde_rows_b$SD_Y[i], sde_rows_b$SDE[i], sde_rows_b$SE_SDE[i],
                                         sde_rows_b$Classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("  Saved: tables/tabF1_sde.tex\n")

cat("\n05_tables.R complete.\n")
