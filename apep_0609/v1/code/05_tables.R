# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_0609: Wayfair Economic Nexus and Retail-Warehouse Reallocation
# ==============================================================================

source("00_packages.R")

results <- readRDS("../data/results_main.rds")
robustness <- readRDS("../data/results_robustness.rds")

# Helper: format coefficient with stars
fmt_coef <- function(est, se, digits = 3) {
  p <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  paste0(formatC(est, format = "f", digits = digits), stars)
}

fmt_se <- function(se, digits = 3) {
  paste0("(", formatC(se, format = "f", digits = digits), ")")
}

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

sp <- results$state_panel

# Pre-period stats (2014-2018 Q2)
pre <- sp %>% filter(yq < 20183)

summ_stats <- tibble(
  Variable = c(
    "Retail employment (thousands)", "Warehouse employment (thousands)",
    "Retail/warehouse ratio", "Log retail/warehouse ratio",
    "Retail job creation rate", "Retail job destruction rate",
    "Warehouse job creation rate", "Warehouse job destruction rate",
    "State sales tax rate (\\%)"
  ),
  Mean = c(
    round(mean(pre$retail_emp / 1000), 1),
    round(mean(pre$wh_emp / 1000), 1),
    round(mean(pre$retail_emp / pre$wh_emp), 2),
    round(mean(pre$log_ratio), 2),
    round(mean(pre$retail_creation_rate, na.rm = TRUE), 3),
    round(mean(pre$retail_destruction_rate, na.rm = TRUE), 3),
    round(mean(pre$wh_creation_rate, na.rm = TRUE), 3),
    round(mean(pre$wh_destruction_rate, na.rm = TRUE), 3),
    round(mean(pre$sales_tax_rate, na.rm = TRUE), 2)
  ),
  SD = c(
    round(sd(pre$retail_emp / 1000), 1),
    round(sd(pre$wh_emp / 1000), 1),
    round(sd(pre$retail_emp / pre$wh_emp), 2),
    round(sd(pre$log_ratio), 2),
    round(sd(pre$retail_creation_rate, na.rm = TRUE), 3),
    round(sd(pre$retail_destruction_rate, na.rm = TRUE), 3),
    round(sd(pre$wh_creation_rate, na.rm = TRUE), 3),
    round(sd(pre$wh_destruction_rate, na.rm = TRUE), 3),
    round(sd(pre$sales_tax_rate, na.rm = TRUE), 2)
  )
)

# Add N
n_states <- n_distinct(sp$state_abbr)
n_treated <- results$diagnostics$n_treated
n_never <- n_states - n_treated
n_sq <- nrow(sp)

tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: State-Quarter Panel, Pre-Period (2014Q1--2018Q2)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "& Mean & SD \\\\",
  "\\hline"
)

for (i in seq_len(nrow(summ_stats))) {
  tab1_tex <- c(tab1_tex, sprintf("%s & %s & %s \\\\",
                                   summ_stats$Variable[i],
                                   summ_stats$Mean[i],
                                   summ_stats$SD[i]))
}

tab1_tex <- c(tab1_tex,
  "\\hline",
  sprintf("States & \\multicolumn{2}{c}{%d (%d treated, %d never-treated)} \\\\",
          n_states, n_treated, n_never),
  sprintf("State-quarters & \\multicolumn{2}{c}{%s} \\\\",
          format(n_sq, big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-period defined as 2014Q1--2018Q2 (before first Wayfair-era nexus law effective date). Retail = NAICS 44--45; warehouse = NAICS 48--49. Job creation/destruction rates are firm-level rates from QWI (positions at expanding/contracting establishments divided by total employment). Sales tax rate is the state-level general rate.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ==============================================================================
# TABLE 2: Main Results — CS-DiD and Sun-Abraham
# ==============================================================================

# Extract CS-DiD results
cs_att <- results$agg_ratio$overall.att
cs_se <- results$agg_ratio$overall.se
cs_ret_att <- results$agg_retail$overall.att
cs_ret_se <- results$agg_retail$overall.se
cs_wh_att <- results$agg_wh$overall.att
cs_wh_se <- results$agg_wh$overall.se

# Sun-Abraham ATT (first post-treatment coefficient)
sa_coefs_ratio <- coef(results$sa_ratio)
sa_se_ratio <- sqrt(diag(vcov(results$sa_ratio)))
sa_coefs_retail <- coef(results$sa_retail)
sa_se_retail <- sqrt(diag(vcov(results$sa_retail)))
sa_coefs_wh <- coef(results$sa_wh)
sa_se_wh <- sqrt(diag(vcov(results$sa_wh)))

# Average post-treatment effect
post_idx <- grepl("^t::[0-9]", names(sa_coefs_ratio))
sa_avg_ratio <- mean(sa_coefs_ratio[post_idx])
sa_avg_se_ratio <- sqrt(mean(sa_se_ratio[post_idx]^2))  # Approximate

post_idx_ret <- grepl("^t::[0-9]", names(sa_coefs_retail))
sa_avg_retail <- mean(sa_coefs_retail[post_idx_ret])
sa_avg_se_retail <- sqrt(mean(sa_se_retail[post_idx_ret]^2))

post_idx_wh <- grepl("^t::[0-9]", names(sa_coefs_wh))
sa_avg_wh <- mean(sa_coefs_wh[post_idx_wh])
sa_avg_se_wh <- sqrt(mean(sa_se_wh[post_idx_wh]^2))

# DDD
ddd_coef <- coef(results$ddd)[1]
ddd_se <- sqrt(diag(vcov(results$ddd)))[1]

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Economic Nexus Laws on Employment Composition}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "& Log(Retail/Wh.) & Log(Retail) & Log(Warehouse) \\\\",
  "& (1) & (2) & (3) \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{4}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\[0.5ex]",
  sprintf("ATT & %s & %s & %s \\\\",
          fmt_coef(cs_att, cs_se, 4), fmt_coef(cs_ret_att, cs_ret_se, 4),
          fmt_coef(cs_wh_att, cs_wh_se, 4)),
  sprintf("& %s & %s & %s \\\\",
          fmt_se(cs_se, 4), fmt_se(cs_ret_se, 4), fmt_se(cs_wh_se, 4)),
  "\\\\[-1.8ex]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Sun-Abraham (avg post)}} \\\\[0.5ex]",
  sprintf("ATT & %s & %s & %s \\\\",
          fmt_coef(sa_avg_ratio, sa_avg_se_ratio, 4),
          fmt_coef(sa_avg_retail, sa_avg_se_retail, 4),
          fmt_coef(sa_avg_wh, sa_avg_se_wh, 4)),
  sprintf("& %s & %s & %s \\\\",
          fmt_se(sa_avg_se_ratio, 4), fmt_se(sa_avg_se_retail, 4),
          fmt_se(sa_avg_se_wh, 4)),
  "\\hline",
  sprintf("State-quarters & %s & %s & %s \\\\",
          format(nrow(results$state_panel), big.mark = ","),
          format(nrow(results$state_panel), big.mark = ","),
          format(nrow(results$state_panel), big.mark = ",")),
  sprintf("States & %d & %d & %d \\\\", n_states, n_states, n_states),
  "State \\& quarter FE & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} Panel A reports the simple aggregate ATT from Callaway and Sant'Anna (2021) with never-treated states as the control group. Panel B reports the average post-treatment coefficient from the Sun and Abraham (2021) interaction-weighted estimator implemented via \\texttt{fixest::sunab()}. Standard errors clustered at the state level in parentheses. Retail = NAICS 44--45; warehouse = NAICS 48--49. Sample: %d states, 2014Q1--2023Q4. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.", n_states),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# ==============================================================================
# TABLE 3: Triple Difference + Dose Response + Firm Dynamics
# ==============================================================================

# Firm dynamics
fd_creation <- coef(results$sa_retail_creation)
fd_creation_se <- sqrt(diag(vcov(results$sa_retail_creation)))
fd_destr <- coef(results$sa_retail_destruction)
fd_destr_se <- sqrt(diag(vcov(results$sa_retail_destruction)))

post_cr <- grepl("^t::[0-9]", names(fd_creation))
avg_creation <- mean(fd_creation[post_cr])
se_creation <- sqrt(mean(fd_creation_se[post_cr]^2))

post_de <- grepl("^t::[0-9]", names(fd_destr))
avg_destruction <- mean(fd_destr[post_de])
se_destruction <- sqrt(mean(fd_destr_se[post_de]^2))

# Dose-response
dose_coef <- coef(results$dose_ratio)[1]
dose_se <- sqrt(diag(vcov(results$dose_ratio)))[1]

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Mechanisms: Triple Difference, Dose-Response, and Firm Dynamics}",
  "\\label{tab:mechanism}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "& DDD & Dose-Response & Retail & Retail \\\\",
  "& Log(Emp) & Log(Ret./Wh.) & Creation Rate & Destruction Rate \\\\",
  "& (1) & (2) & (3) & (4) \\\\",
  "\\hline",
  sprintf("Treatment & %s & %s & %s & %s \\\\",
          fmt_coef(ddd_coef, ddd_se, 4),
          fmt_coef(dose_coef, dose_se, 4),
          fmt_coef(avg_creation, se_creation, 4),
          fmt_coef(avg_destruction, se_destruction, 4)),
  sprintf("& %s & %s & %s & %s \\\\",
          fmt_se(ddd_se, 4), fmt_se(dose_se, 4),
          fmt_se(se_creation, 4), fmt_se(se_destruction, 4)),
  "\\hline",
  "State \\& quarter FE & Yes & Yes & Yes & Yes \\\\",
  "Sector FE & Yes & --- & --- & --- \\\\",
  "Clustering & State & State & State & State \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Column (1): triple-difference comparing retail (NAICS 44--45) against healthcare (NAICS 62) and education (NAICS 61) within the same state-quarter, with state$\\times$sector, quarter$\\times$sector, and state$\\times$quarter fixed effects. Column (2): state sales tax rate $\\times$ post interaction; coefficient represents the effect of a 1 percentage point higher tax rate. Columns (3)--(4): Sun-Abraham average post-treatment effects on QWI firm-level job creation and destruction rates in retail. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_tex, "../tables/tab3_mechanism.tex")

# ==============================================================================
# TABLE 4: Robustness — Pre-COVID, Placebos, Age
# ==============================================================================

# Pre-COVID
pc_ratio <- coef(robustness$sa_ratio_precovid)
pc_se <- sqrt(diag(vcov(robustness$sa_ratio_precovid)))
post_pc <- grepl("^t::[0-9]", names(pc_ratio))
avg_pc <- mean(pc_ratio[post_pc])
se_pc <- sqrt(mean(pc_se[post_pc]^2))

# Healthcare placebo
hc_coef <- coef(robustness$sa_healthcare)
hc_se <- sqrt(diag(vcov(robustness$sa_healthcare)))
post_hc <- grepl("^t::[0-9]", names(hc_coef))
avg_hc <- mean(hc_coef[post_hc])
se_hc <- sqrt(mean(hc_se[post_hc]^2))

# Education placebo
ed_coef <- coef(robustness$sa_education)
ed_se <- sqrt(diag(vcov(robustness$sa_education)))
post_ed <- grepl("^t::[0-9]", names(ed_coef))
avg_ed <- mean(ed_coef[post_ed])
se_ed <- sqrt(mean(ed_se[post_ed]^2))

# Young workers
y_coef <- coef(robustness$sa_young)
y_se <- sqrt(diag(vcov(robustness$sa_young)))
post_y <- grepl("^t::[0-9]", names(y_coef))
avg_young <- mean(y_coef[post_y])
se_young <- sqrt(mean(y_se[post_y]^2))

# Prime workers
p_coef <- coef(robustness$sa_prime)
p_se <- sqrt(diag(vcov(robustness$sa_prime)))
post_p <- grepl("^t::[0-9]", names(p_coef))
avg_prime <- mean(p_coef[post_p])
se_prime <- sqrt(mean(p_se[post_p]^2))

tab4_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Pre-COVID, Placebo Sectors, and Age-Specific Effects}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "& Pre-COVID & Healthcare & Education & Young Ret. & Prime Ret. \\\\",
  "& Log(Ret./Wh.) & Log(Emp) & Log(Emp) & Log(Emp) & Log(Emp) \\\\",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  "\\hline",
  sprintf("ATT & %s & %s & %s & %s & %s \\\\",
          fmt_coef(avg_pc, se_pc, 4),
          fmt_coef(avg_hc, se_hc, 4),
          fmt_coef(avg_ed, se_ed, 4),
          fmt_coef(avg_young, se_young, 4),
          fmt_coef(avg_prime, se_prime, 4)),
  sprintf("& %s & %s & %s & %s & %s \\\\",
          fmt_se(se_pc, 4), fmt_se(se_hc, 4), fmt_se(se_ed, 4),
          fmt_se(se_young, 4), fmt_se(se_prime, 4)),
  "\\hline",
  sprintf("Perm. $p$-value & \\multicolumn{5}{c}{%s} \\\\", round(robustness$perm_p, 3)),
  "Sample & 2014--2019 & Full & Full & Retail 14--24 & Retail 25--34 \\\\",
  "State \\& quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & State & State & State & State & State \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} All columns report average post-treatment effects from the Sun-Abraham estimator. Column (1) restricts the sample to 2014Q1--2019Q4 to exclude COVID-era confounds. Columns (2)--(3) are placebo tests: healthcare (NAICS 62) and education (NAICS 61) have no online competition and should show null effects. Columns (4)--(5) decompose retail employment by age group. Permutation $p$-value from 500 random reassignments of treatment timing. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ==============================================================================

# Compute SDE for main outcomes
sp <- results$state_panel
sd_ratio <- sd(sp$log_ratio)
sd_retail <- sd(sp$log_retail)
sd_wh <- sd(sp$log_wh)
sd_creation <- sd(sp$retail_creation_rate, na.rm = TRUE)
sd_destruction <- sd(sp$retail_destruction_rate, na.rm = TRUE)

sde_tab <- tibble(
  Outcome = c(
    "Log(retail/warehouse ratio)",
    "Log(retail employment)",
    "Log(warehouse employment)",
    "Retail job creation rate",
    "Retail job destruction rate"
  ),
  beta = c(cs_att, cs_ret_att, cs_wh_att, avg_creation, avg_destruction),
  se = c(cs_se, cs_ret_se, cs_wh_se, se_creation, se_destruction),
  sd_y = c(sd_ratio, sd_retail, sd_wh, sd_creation, sd_destruction)
) %>%
  mutate(
    SDE = beta / sd_y,
    SE_SDE = se / sd_y,
    Classification = case_when(
      SDE < -0.15 ~ "Large negative",
      SDE < -0.05 ~ "Moderate negative",
      SDE < -0.005 ~ "Small negative",
      SDE <= 0.005 ~ "Null",
      SDE <= 0.05 ~ "Small positive",
      SDE <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

tabF1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in seq_len(nrow(sde_tab))) {
  tabF1_tex <- c(tabF1_tex,
    sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
            sde_tab$Outcome[i], sde_tab$beta[i], sde_tab$se[i],
            sde_tab$sd_y[i], sde_tab$SDE[i], sde_tab$SE_SDE[i],
            sde_tab$Classification[i]))
}

tabF1_tex <- c(tabF1_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} This paper studies whether state adoption of economic nexus sales tax laws following \\textit{South Dakota v. Wayfair} (2018) affected the reallocation of employment between retail and warehousing sectors. Data: Quarterly Workforce Indicators (QWI), %d states, 2014Q1--2023Q4. Method: Callaway-Sant'Anna (2021) staggered difference-in-differences. Treatment: binary indicator for state economic nexus law adoption. $N = %s$ state-quarters. SDE = $\\hat{\\beta} / \\text{SD}(Y)$. Classification refers to magnitude, not statistical significance.",
          n_states, format(nrow(sp), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("All tables written to tables/\n")
