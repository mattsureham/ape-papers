## 06_tables.R — Generate all tables
## apep_0513: Welsh 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Load Results
# ============================================================
cat("=== Loading results ===\n")

panel <- fread(file.path(data_dir, "panel_pfa_month.csv"))
panel[, ym := as.Date(ym)]
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# 2. Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

pre_panel <- panel[ym < as.Date("2023-09-01")]
post_panel <- panel[ym >= as.Date("2023-09-01")]

# Pre-period means by nation
pre_stats <- pre_panel[, .(
  mean_collisions = mean(collisions),
  sd_collisions = sd(collisions),
  mean_ksi = mean(ksi),
  sd_ksi = sd(ksi),
  n_months = n_distinct(ym)
), by = nation]

post_stats <- post_panel[, .(
  mean_collisions = mean(collisions),
  sd_collisions = sd(collisions),
  mean_ksi = mean(ksi),
  sd_ksi = sd(ksi),
  n_months = n_distinct(ym)
), by = nation]

# LaTeX table
sink(file.path(tables_dir, "tab1_summary_stats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Collisions on 20--30 mph Roads}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Pre-Treatment} & \\multicolumn{2}{c}{Post-Treatment} \\\\\n")
cat(" & \\multicolumn{2}{c}{(Jan 2019--Aug 2023)} & \\multicolumn{2}{c}{(Sep 2023--Dec 2024)} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Wales & England & Wales & England \\\\\n")
cat("\\hline\n")

w_pre <- pre_stats[nation == "Wales"]
e_pre <- pre_stats[nation == "England"]
w_post <- post_stats[nation == "Wales"]
e_post <- post_stats[nation == "England"]

cat(sprintf("Mean collisions/PFA-month & %.1f & %.1f & %.1f & %.1f \\\\\n",
            w_pre$mean_collisions, e_pre$mean_collisions,
            w_post$mean_collisions, e_post$mean_collisions))
cat(sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
            w_pre$sd_collisions, e_pre$sd_collisions,
            w_post$sd_collisions, e_post$sd_collisions))
cat(sprintf("Mean KSI/PFA-month & %.1f & %.1f & %.1f & %.1f \\\\\n",
            w_pre$mean_ksi, e_pre$mean_ksi,
            w_post$mean_ksi, e_post$mean_ksi))
cat(sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\\n",
            w_pre$sd_ksi, e_pre$sd_ksi,
            w_post$sd_ksi, e_post$sd_ksi))
cat(sprintf("PFA-months & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
            nrow(pre_panel), nrow(post_panel)))
cat(sprintf("N PFAs & \\multicolumn{2}{c}{%d (%d Welsh, %d English)} & \\multicolumn{2}{c}{} \\\\\n",
            n_distinct(panel$pfa),
            n_distinct(panel[welsh == 1]$pfa),
            n_distinct(panel[welsh == 0]$pfa)))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\smallskip\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} Standard deviations in parentheses. Sample restricted to collisions on roads with posted speed limits of 20 or 30 mph. Pre-treatment period: January 2019 through August 2023. Post-treatment period: September 2023 through the latest available month. PFA = Police Force Area. KSI = Killed or Seriously Injured.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tab1_summary_stats.tex\n")

# ============================================================
# 3. Table 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main DiD Results ===\n")

sink(file.path(tables_dir, "tab2_main_results.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Wales's 20 mph Default Speed Limit on Road Collisions}\n")
cat("\\label{tab:main}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat(" & All & All & KSI & Fatal & Serious & Slight \\\\\n")
cat(" & log & level & log & log & log & log \\\\\n")
cat("\\hline\n")

models <- list(results$basic_did, results$level_did, results$ksi_did,
               results$fatal_did, results$serious_did, results$slight_did)

# Coefficients
coefs <- sapply(models, function(m) coef(m)["treat"])
ses <- sapply(models, function(m) se(m)["treat"])
pvals <- sapply(models, function(m) fixest::pvalue(m)["treat"])
nobs_vec <- sapply(models, nobs)

stars <- ifelse(pvals < 0.01, "^{***}", ifelse(pvals < 0.05, "^{**}", ifelse(pvals < 0.1, "^{*}", "")))

cat(sprintf("Welsh $\\times$ Post & %s \\\\\n",
            paste(sprintf("%.3f%s", coefs, stars), collapse = " & ")))
cat(sprintf(" & %s \\\\\n",
            paste(sprintf("(%.3f)", ses), collapse = " & ")))

# Implied percentage changes (for log models)
pct_changes <- (exp(coefs) - 1) * 100
pct_changes[2] <- NA  # Level model
cat(sprintf("Implied \\%% change & %s \\\\\n",
            paste(ifelse(is.na(pct_changes), "--",
                         sprintf("%.1f\\%%", pct_changes)), collapse = " & ")))

# Randomization inference p-value
ri_p <- rep("--", 6)
ri_p[1] <- sprintf("%.3f", rob_results$ri_pvalue)
cat(sprintf("RI $p$-value & %s \\\\\n", paste(ri_p, collapse = " & ")))

cat("\\hline\n")
cat(sprintf("Observations & %s \\\\\n",
            paste(format(nobs_vec, big.mark = ","), collapse = " & ")))
cat("PFA FE & \\multicolumn{6}{c}{Yes} \\\\\n")
cat("Year-month FE & \\multicolumn{6}{c}{Yes} \\\\\n")
cat(sprintf("Clusters (PFAs) & \\multicolumn{6}{c}{%d} \\\\\n", n_distinct(panel$pfa)))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\smallskip\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Standard errors clustered at the police force area level in parentheses. Randomization inference (RI) $p$-value from 999 permutations of PFA treatment assignment (two-sided). The dependent variable is log(collisions + 1) unless noted. Column (2) uses level counts. The sample includes all collisions on roads with 20 or 30 mph speed limits. Welsh $\\times$ Post equals one for Welsh PFAs in September 2023 and later.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tab2_main_results.tex\n")

# ============================================================
# 4. Table 3: Robustness and Placebo Tests
# ============================================================
cat("=== Table 3: Robustness ===\n")

sink(file.path(tables_dir, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks and Placebo Tests}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat(" & Baseline & Excl. COVID & Border only & Nation trends & Poisson & Fake date \\\\\n")
cat("\\hline\n")

# Gather coefficients
base_c <- coef(results$basic_did)["treat"]
base_se <- se(results$basic_did)["treat"]
base_p <- fixest::pvalue(results$basic_did)["treat"]

r1_c <- coef(rob_results$excl_covid)["treat"]
r1_se <- se(rob_results$excl_covid)["treat"]
r1_p <- fixest::pvalue(rob_results$excl_covid)["treat"]

r2_c <- coef(rob_results$border_only)["treat"]
r2_se <- se(rob_results$border_only)["treat"]
r2_p <- fixest::pvalue(rob_results$border_only)["treat"]

r3_c <- coef(rob_results$nation_trends)["treat"]
r3_se <- se(rob_results$nation_trends)["treat"]
r3_p <- fixest::pvalue(rob_results$nation_trends)["treat"]

if (!is.null(rob_results$poisson)) {
  r4_c <- coef(rob_results$poisson)["treat"]
  r4_se <- se(rob_results$poisson)["treat"]
  r4_p <- fixest::pvalue(rob_results$poisson)["treat"]
} else {
  r4_c <- NA; r4_se <- NA; r4_p <- NA
}

r5_c <- coef(rob_results$placebo_fake_date)["fake_treat"]
r5_se <- se(rob_results$placebo_fake_date)["fake_treat"]
r5_p <- fixest::pvalue(rob_results$placebo_fake_date)["fake_treat"]

all_c <- c(base_c, r1_c, r2_c, r3_c, r4_c, r5_c)
all_se <- c(base_se, r1_se, r2_se, r3_se, r4_se, r5_se)
all_p <- c(base_p, r1_p, r2_p, r3_p, r4_p, r5_p)

stars_r <- ifelse(is.na(all_p), "",
                  ifelse(all_p < 0.01, "^{***}",
                         ifelse(all_p < 0.05, "^{**}",
                                ifelse(all_p < 0.1, "^{*}", ""))))

cat(sprintf("Treatment & %s \\\\\n",
            paste(ifelse(is.na(all_c), "--", sprintf("%.3f%s", all_c, stars_r)), collapse = " & ")))
cat(sprintf(" & %s \\\\\n",
            paste(ifelse(is.na(all_se), "", sprintf("(%.3f)", all_se)), collapse = " & ")))

cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Placebo tests:}} \\\\\n")

# Placebo: 40+ mph roads
ph_c <- coef(rob_results$placebo_high_speed)["treat"]
ph_se <- se(rob_results$placebo_high_speed)["treat"]
ph_p <- fixest::pvalue(rob_results$placebo_high_speed)["treat"]
ph_star <- ifelse(ph_p < 0.01, "^{***}", ifelse(ph_p < 0.05, "^{**}", ifelse(ph_p < 0.1, "^{*}", "")))
cat(sprintf("40+ mph roads & \\multicolumn{6}{c}{%.3f%s (%.3f)} \\\\\n", ph_c, ph_star, ph_se))

# Placebo: Scotland
ps_c <- coef(rob_results$placebo_scotland)["treat"]
ps_se <- se(rob_results$placebo_scotland)["treat"]
ps_p <- fixest::pvalue(rob_results$placebo_scotland)["treat"]
ps_star <- ifelse(ps_p < 0.01, "^{***}", ifelse(ps_p < 0.05, "^{**}", ifelse(ps_p < 0.1, "^{*}", "")))
cat(sprintf("Scotland vs England & \\multicolumn{6}{c}{%.3f%s (%.3f)} \\\\\n", ps_c, ps_star, ps_se))

# RI
cat(sprintf("RI $p$-value & \\multicolumn{6}{c}{%.3f} \\\\\n", rob_results$ri_pvalue))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\smallskip\n")
cat("\\begin{minipage}{\\textwidth}\n")
cat("\\footnotesize\n")
cat("\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. All specifications include PFA and year-month fixed effects with PFA-clustered standard errors (except Column 5, Poisson quasi-ML). Column (2) drops 2020--2021. Column (3) restricts to Welsh and English border PFAs. Column (4) adds nation-specific linear time trends. Column (6) uses a placebo treatment date of September 2022 on the pre-treatment sample. The 40+ mph roads placebo tests the same DiD on collisions occurring on roads with speed limits of 40 mph or higher. Scotland vs England tests for differential change in Scottish relative to English collisions (Scotland had no speed limit change). RI $p$-value from 999 permutations of PFA treatment assignment.\n")
cat("\\end{minipage}\n")
cat("\\end{table}\n")
sink()

cat("  Saved tab3_robustness.tex\n")

# ============================================================
# 5. Table 4: Property Value DiD (if available)
# ============================================================
cat("=== Table 4: Property Value DiD ===\n")

pv_file <- file.path(data_dir, "property_results.rds")
if (file.exists(pv_file)) {
  pv_results <- readRDS(pv_file)

  sink(file.path(tables_dir, "tab4_property_values.tex"))
  cat("\\begin{table}[htbp]\n")
  cat("\\centering\n")
  cat("\\caption{Effect of 20 mph Default on Residential Property Prices}\n")
  cat("\\label{tab:property}\n")
  cat("\\begin{adjustbox}{max width=\\textwidth}\n")
  cat("\\begin{tabular}{lcc}\n")
  cat("\\hline\\hline\n")
  cat(" & (1) & (2) \\\\\n")
  cat(" & Basic & With controls \\\\\n")
  cat("\\hline\n")

  pv1 <- pv_results$pv_basic
  pv2 <- pv_results$pv_controls

  pv1_c <- coef(pv1)["treat"]; pv1_se <- se(pv1)["treat"]; pv1_p <- fixest::pvalue(pv1)["treat"]
  pv2_c <- coef(pv2)["treat"]; pv2_se <- se(pv2)["treat"]; pv2_p <- fixest::pvalue(pv2)["treat"]

  s1 <- ifelse(pv1_p < 0.01, "^{***}", ifelse(pv1_p < 0.05, "^{**}", ifelse(pv1_p < 0.1, "^{*}", "")))
  s2 <- ifelse(pv2_p < 0.01, "^{***}", ifelse(pv2_p < 0.05, "^{**}", ifelse(pv2_p < 0.1, "^{*}", "")))

  cat(sprintf("Welsh $\\times$ Post & %.4f%s & %.4f%s \\\\\n", pv1_c, s1, pv2_c, s2))
  cat(sprintf(" & (%.4f) & (%.4f) \\\\\n", pv1_se, pv2_se))
  cat(sprintf("Implied \\%% change & %.2f\\%% & %.2f\\%% \\\\\n",
              (exp(pv1_c) - 1) * 100, (exp(pv2_c) - 1) * 100))

  cat("\\hline\n")
  cat(sprintf("Observations & %s & %s \\\\\n",
              format(nobs(pv1), big.mark = ","), format(nobs(pv2), big.mark = ",")))
  cat("District FE & Yes & Yes \\\\\n")
  cat("Year-quarter FE & Yes & Yes \\\\\n")
  cat("Property controls & No & Yes \\\\\n")

  cat("\\hline\\hline\n")
  cat("\\end{tabular}\n")
  cat("\\end{adjustbox}\n")
  cat("\\smallskip\n")
  cat("\\begin{minipage}{\\textwidth}\n")
  cat("\\footnotesize\n")
  cat("\\textit{Notes:} $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$. Standard errors clustered at the district level. Dependent variable: log(transaction price). Sample: standard residential transactions (PPD Category A) in England and Wales, excluding SY postcode area (which straddles the border). Welsh $\\times$ Post equals one for Welsh postcodes after September 2023. Property controls in Column (2): new build indicator, freehold indicator, property type (detached, semi-detached, terraced, flat).\n")
  cat("\\end{minipage}\n")
  cat("\\end{table}\n")
  sink()

  cat("  Saved tab4_property_values.tex\n")
} else {
  cat("  No property results available — skipping Table 4.\n")
}

cat("\n=== All tables generated ===\n")
