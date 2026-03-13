## 05_tables.R — Generate all LaTeX tables
## apep_0658

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")
results <- readRDS("../data/results.rds")
rob <- readRDS("../data/robustness_results.rds")

panel$county <- substr(panel$muni_code, 1, 2)

## =====================================================
## TABLE 1: Summary Statistics
## =====================================================
cat("Generating Table 1: Summary Statistics\n")

treat_vals <- panel %>%
  distinct(muni_code, sec_share_2021, high_exposure)

sumstats <- panel %>%
  summarise(
    `Building permits` = sprintf("%.1f", mean(permits_started, na.rm = TRUE)),
    `SD` = sprintf("(%.1f)", sd(permits_started, na.rm = TRUE)),
    `New enterprises` = sprintf("%.1f", mean(new_enterprises, na.rm = TRUE)),
    `SD2` = sprintf("(%.1f)", sd(new_enterprises, na.rm = TRUE)),
    `Out-migration` = sprintf("%.1f", mean(out_migration, na.rm = TRUE)),
    `SD3` = sprintf("(%.1f)", sd(out_migration, na.rm = TRUE)),
    `Net migration` = sprintf("%.1f", mean(net_migration, na.rm = TRUE)),
    `SD4` = sprintf("(%.1f)", sd(net_migration, na.rm = TRUE))
  )

# Build summary stats table manually for LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Pre-reform (2020--21)} & \\multicolumn{2}{c}{Post-reform (2022--24)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Low exposure & High exposure & Low exposure & High exposure \\\\"
)

# Compute group means
group_stats <- panel %>%
  group_by(post, high_exposure) %>%
  summarise(
    permits_m = mean(permits_started, na.rm = TRUE),
    permits_sd = sd(permits_started, na.rm = TRUE),
    ent_m = mean(new_enterprises, na.rm = TRUE),
    ent_sd = sd(new_enterprises, na.rm = TRUE),
    outmig_m = mean(out_migration, na.rm = TRUE),
    outmig_sd = sd(out_migration, na.rm = TRUE),
    netmig_m = mean(net_migration, na.rm = TRUE),
    netmig_sd = sd(net_migration, na.rm = TRUE),
    avg_wt_m = mean(avg_wealth_tax, na.rm = TRUE),
    sec_share_m = mean(sec_share_2021, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(post, high_exposure)

gs <- group_stats

tab1_lines <- c(tab1_lines, "\\hline",
  sprintf("Building permits & %.1f & %.1f & %.1f & %.1f \\\\", gs$permits_m[1], gs$permits_m[2], gs$permits_m[3], gs$permits_m[4]),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\[3pt]", gs$permits_sd[1], gs$permits_sd[2], gs$permits_sd[3], gs$permits_sd[4]),
  sprintf("New enterprises & %.1f & %.1f & %.1f & %.1f \\\\", gs$ent_m[1], gs$ent_m[2], gs$ent_m[3], gs$ent_m[4]),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\[3pt]", gs$ent_sd[1], gs$ent_sd[2], gs$ent_sd[3], gs$ent_sd[4]),
  sprintf("Out-migration & %.1f & %.1f & %.1f & %.1f \\\\", gs$outmig_m[1], gs$outmig_m[2], gs$outmig_m[3], gs$outmig_m[4]),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\[3pt]", gs$outmig_sd[1], gs$outmig_sd[2], gs$outmig_sd[3], gs$outmig_sd[4]),
  sprintf("Net migration & %.1f & %.1f & %.1f & %.1f \\\\", gs$netmig_m[1], gs$netmig_m[2], gs$netmig_m[3], gs$netmig_m[4]),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\[3pt]", gs$netmig_sd[1], gs$netmig_sd[2], gs$netmig_sd[3], gs$netmig_sd[4]),
  sprintf("Avg.\\ wealth tax (NOK) & %.0f & %.0f & %.0f & %.0f \\\\", gs$avg_wt_m[1], gs$avg_wt_m[2], gs$avg_wt_m[3], gs$avg_wt_m[4]),
  sprintf("Secondary dwelling share & %.3f & %.3f & --- & --- \\\\", gs$sec_share_m[1], gs$sec_share_m[2]),
  "\\hline",
  sprintf("Municipalities & \\multicolumn{2}{c}{356} & \\multicolumn{2}{c}{356} \\\\"),
  sprintf("Municipality-years & \\multicolumn{2}{c}{712} & \\multicolumn{2}{c}{1,068} \\\\"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Standard deviations in parentheses. Low (high) exposure municipalities are below (above) the median 2021 secondary dwelling share of assessed tax value (14.5\\%). Building permits and enterprises are annual counts. Migration counts internal moves between municipalities. Wealth tax is average per person (NOK).",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

## =====================================================
## TABLE 2: Main DiD Results
## =====================================================
cat("Generating Table 2: Main Results\n")

# Main specifications
m_p_log <- results$permits_log
m_e_log <- results$enterprises_log
m_m_log <- results$out_migration_log
m_p_cy <- results$county_permits
m_e_cy <- results$county_enterprises
m_m_cy <- results$county_migration

models <- list(m_p_log, m_p_cy, m_e_log, m_e_cy, m_m_log, m_m_cy)

fmt_coef <- function(m) {
  b <- coef(m)["treat_z_x_post"]
  s <- se(m)["treat_z_x_post"]
  t_val <- abs(b / s)
  stars <- ifelse(t_val > 2.576, "***", ifelse(t_val > 1.96, "**", ifelse(t_val > 1.645, "*", "")))
  sprintf("%.3f%s", b, stars)
}
fmt_se <- function(m) sprintf("(%.3f)", se(m)["treat_z_x_post"])
fmt_r2 <- function(m) sprintf("%.3f", fitstat(m, "wr2")[[1]])

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Wealth Tax Reform on Municipal Outcomes}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Log permits} & \\multicolumn{2}{c}{Log enterprises} & \\multicolumn{2}{c}{Log out-migration} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  "\\hline",
  sprintf("Exposure $\\times$ Post & %s & %s & %s & %s & %s & %s \\\\",
    fmt_coef(m_p_log), fmt_coef(m_p_cy), fmt_coef(m_e_log), fmt_coef(m_e_cy),
    fmt_coef(m_m_log), fmt_coef(m_m_cy)),
  sprintf(" & %s & %s & %s & %s & %s & %s \\\\",
    fmt_se(m_p_log), fmt_se(m_p_cy), fmt_se(m_e_log), fmt_se(m_e_cy),
    fmt_se(m_m_log), fmt_se(m_m_cy)),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & --- & Yes & --- & Yes & --- \\\\",
  "County $\\times$ Year FE & --- & Yes & --- & Yes & --- & Yes \\\\",
  sprintf("Within $R^2$ & %s & %s & %s & %s & %s & %s \\\\",
    fmt_r2(m_p_log), fmt_r2(m_p_cy), fmt_r2(m_e_log), fmt_r2(m_e_cy),
    fmt_r2(m_m_log), fmt_r2(m_m_cy)),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
    format(nobs(m_p_log), big.mark=","), format(nobs(m_p_cy), big.mark=","),
    format(nobs(m_e_log), big.mark=","), format(nobs(m_e_cy), big.mark=","),
    format(nobs(m_m_log), big.mark=","), format(nobs(m_m_cy), big.mark=",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Standard errors clustered at the municipality level in parentheses. All outcomes in logs. Exposure is the standardized 2021 secondary dwelling share of total assessed dwelling value. Columns (2), (4), (6) include county $\\times$ year fixed effects. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

## =====================================================
## TABLE 3: Event Study Coefficients
## =====================================================
cat("Generating Table 3: Event Study\n")

# Extract event study coefficients
es_permits <- results$permits_es
es_ent <- results$enterprises_es
es_mig <- results$out_migration_es

es_df <- data.frame(
  Year = c(2020, 2022, 2023, 2024),
  Permits_coef = coef(es_permits),
  Permits_se = se(es_permits),
  Ent_coef = coef(es_ent),
  Ent_se = se(es_ent),
  Mig_coef = coef(es_mig),
  Mig_se = se(es_mig)
)

# Significance stars
add_stars <- function(coef, se) {
  t <- abs(coef / se)
  stars <- ifelse(t > 2.576, "***", ifelse(t > 1.96, "**", ifelse(t > 1.645, "*", "")))
  sprintf("%.3f%s", coef, stars)
}

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Year & Log permits & Log enterprises & Log out-migration \\\\",
  "\\hline",
  sprintf("2020 & %s & %s & %s \\\\",
    add_stars(es_df$Permits_coef[1], es_df$Permits_se[1]),
    add_stars(es_df$Ent_coef[1], es_df$Ent_se[1]),
    add_stars(es_df$Mig_coef[1], es_df$Mig_se[1])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\[3pt]",
    es_df$Permits_se[1], es_df$Ent_se[1], es_df$Mig_se[1]),
  "2021 & \\multicolumn{3}{c}{--- Reference year ---} \\\\[3pt]",
  sprintf("2022 & %s & %s & %s \\\\",
    add_stars(es_df$Permits_coef[2], es_df$Permits_se[2]),
    add_stars(es_df$Ent_coef[2], es_df$Ent_se[2]),
    add_stars(es_df$Mig_coef[2], es_df$Mig_se[2])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\[3pt]",
    es_df$Permits_se[2], es_df$Ent_se[2], es_df$Mig_se[2]),
  sprintf("2023 & %s & %s & %s \\\\",
    add_stars(es_df$Permits_coef[3], es_df$Permits_se[3]),
    add_stars(es_df$Ent_coef[3], es_df$Ent_se[3]),
    add_stars(es_df$Mig_coef[3], es_df$Mig_se[3])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\[3pt]",
    es_df$Permits_se[3], es_df$Ent_se[3], es_df$Mig_se[3]),
  sprintf("2024 & %s & %s & %s \\\\",
    add_stars(es_df$Permits_coef[4], es_df$Permits_se[4]),
    add_stars(es_df$Ent_coef[4], es_df$Ent_se[4]),
    add_stars(es_df$Mig_coef[4], es_df$Mig_se[4])),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) \\\\",
    es_df$Permits_se[4], es_df$Ent_se[4], es_df$Mig_se[4]),
  "\\hline",
  "Municipality FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d \\\\", nobs(es_permits), nobs(es_ent), nobs(es_mig)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Each column reports coefficients from a regression of the outcome on interactions of standardized 2021 secondary dwelling exposure with year indicators, relative to 2021. Standard errors clustered at the municipality level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

## =====================================================
## TABLE 4: Robustness
## =====================================================
cat("Generating Table 4: Robustness\n")

# Collect robustness results
main_c <- coef(results$permits_log)["treat_z_x_post"]
main_s <- se(results$permits_log)["treat_z_x_post"]

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness of Building Permit Results}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Specification & Coefficient & SE \\\\",
  "\\hline",
  sprintf("Main (log, muni + year FE) & %.3f*** & (%.3f) \\\\", main_c, main_s),
  sprintf("County $\\times$ year FE & %.3f*** & (%.3f) \\\\",
    coef(results$county_permits), se(results$county_permits)),
  sprintf("IHS transformation & %.3f*** & (%.3f) \\\\",
    coef(rob$ihs), se(rob$ihs)),
  sprintf("Binary treatment (high vs.\\ low) & %.3f*** & (%.3f) \\\\",
    coef(results$bin_permits), se(results$bin_permits)),
  sprintf("Q4 vs.\\ Q1 only & %.3f*** & (%.3f) \\\\",
    coef(rob$extreme_quartile), se(rob$extreme_quartile)),
  sprintf("Two-way clustering (muni + year) & %.3f & (%.3f) \\\\",
    coef(rob$twoway), se(rob$twoway)),
  sprintf("Placebo (2021 vs.\\ 2020) & %.3f & (%.3f) \\\\",
    coef(rob$placebo), se(rob$placebo)),
  "\\hline",
  sprintf("Randomization inference $p$-value & \\multicolumn{2}{c}{%.3f} \\\\", rob$ri_p_value),
  sprintf("Leave-one-county-out range & \\multicolumn{2}{c}{[%.3f, %.3f]} \\\\",
    min(rob$loo_coefs), max(rob$loo_coefs)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} All specifications use the 2020--2024 municipality panel (356 municipalities). The dependent variable is log building permits except where noted. Exposure is the standardized 2021 secondary dwelling share. The placebo test uses 2020 as pseudo-treatment with 2021 as the post-period. Randomization inference uses 500 permutations of the treatment assignment. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

## =====================================================
## TABLE 5: Dose-Response (Quartiles)
## =====================================================
cat("Generating Table 5: Dose-Response\n")

m_q <- results$quartile_permits

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Dose-Response: Building Permits by Treatment Quartile}",
  "\\label{tab:dose}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Treatment quartile & Coefficient & SE \\\\",
  "\\hline",
  "Q1 (lowest secondary share) & \\multicolumn{2}{c}{--- Reference ---} \\\\",
  sprintf("Q2 $\\times$ Post & %.3f** & (%.3f) \\\\",
    coef(m_q)["treat_q::2:post"], se(m_q)["treat_q::2:post"]),
  sprintf("Q3 $\\times$ Post & %.3f*** & (%.3f) \\\\",
    coef(m_q)["treat_q::3:post"], se(m_q)["treat_q::3:post"]),
  sprintf("Q4 $\\times$ Post & %.3f*** & (%.3f) \\\\",
    coef(m_q)["treat_q::4:post"], se(m_q)["treat_q::4:post"]),
  "\\hline",
  "Municipality FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nobs(m_q), big.mark=",")),
  sprintf("Within $R^2$ & \\multicolumn{2}{c}{%.3f} \\\\", fitstat(m_q, "wr2")[[1]]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} Dependent variable is log building permits. Treatment quartiles defined by the 2021 secondary dwelling share of total assessed dwelling value. Q1 (lowest): 7.2--11.3\\%; Q2: 11.3--14.5\\%; Q3: 14.5--17.4\\%; Q4 (highest): 17.4--31.5\\%. Standard errors clustered at the municipality level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_dose.tex")

## =====================================================
## TABLE F1: Standardized Effect Size (SDE) — APPENDIX
## =====================================================
cat("Generating Table F1: SDE\n")

# Compute SDEs
outcomes <- list(
  list(name = "Building permits", coef_name = "treat_z_x_post",
       model = results$permits_log, y_var = "log_permits",
       beta_raw = coef(results$permits_level)["treat_z_x_post"],
       se_raw = se(results$permits_level)["treat_z_x_post"],
       sd_y = sd(panel$permits_started, na.rm = TRUE)),
  list(name = "New enterprises", coef_name = "treat_z_x_post",
       model = results$enterprises_log, y_var = "log_enterprises",
       beta_raw = coef(results$enterprises_log)["treat_z_x_post"],
       se_raw = se(results$enterprises_log)["treat_z_x_post"],
       sd_y = sd(panel$log_enterprises, na.rm = TRUE)),
  list(name = "Out-migration", coef_name = "treat_z_x_post",
       model = results$out_migration_log, y_var = "log_out_migration",
       beta_raw = coef(results$out_migration_log)["treat_z_x_post"],
       se_raw = se(results$out_migration_log)["treat_z_x_post"],
       sd_y = sd(panel$log_out_migration, na.rm = TRUE)),
  list(name = "Net migration", coef_name = "treat_z_x_post",
       model = results$net_migration, y_var = "net_migration",
       beta_raw = coef(results$net_migration)["treat_z_x_post"],
       se_raw = se(results$net_migration)["treat_z_x_post"],
       sd_y = sd(panel$net_migration, na.rm = TRUE))
)

# Since treatment is already standardized (1 SD = 1 unit of treat_z),
# SDE = beta / SD(Y) (already a 1-SD-of-X change)
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- sapply(outcomes, function(o) {
  sde <- o$beta_raw / o$sd_y
  se_sde <- o$se_raw / o$sd_y
  class <- classify_sde(sde)
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          o$name, o$beta_raw, o$se_raw, o$sd_y, sde, se_sde, class)
})

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  sde_rows,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{0.3em}",
  "\\footnotesize \\textit{Notes:} This table reports standardized effect sizes for the main outcomes. The research question is whether Norway's 2022 wealth tax reform on secondary dwellings affected municipal housing supply and population dynamics. Data source: Statistics Norway (SSB), 356 municipalities, 2020--2024. Method: continuous-treatment difference-in-differences with municipality and year fixed effects. Treatment is the standardized 2021 secondary dwelling share of assessed value ($N = 1{,}780$ municipality-years). The standardized effect (SDE) equals $\\hat{\\beta}/\\text{SD}(Y)$ since treatment is already standardized. Classification refers to effect magnitude, not statistical significance.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
for (f in list.files("../tables/", pattern = "\\.tex$")) {
  cat(sprintf("  tables/%s\n", f))
}
