# 05_tables.R — Generate all LaTeX tables
# apep_1282: The Double Squeeze

source("00_packages.R")
load("../data/results.RData")
load("../data/robustness.RData")

cat("=== Generating Tables ===\n")

# ------------------------------------------------------------------
# Table 1: Summary Statistics
# ------------------------------------------------------------------
cat("\n--- Table 1: Summary statistics ---\n")

# Region-level treatment variables
region_vars <- panel |>
  filter(!duplicated(region)) |>
  summarise(
    `Fornero bite (pp)` = sprintf("%.1f & %.1f & %.1f & %.1f",
      mean(fornero_bite), sd(fornero_bite), min(fornero_bite), max(fornero_bite)),
    `RdC take-up (\\%% WAP)` = sprintf("%.2f & %.2f & %.2f & %.2f",
      mean(rdc_rate), sd(rdc_rate), min(rdc_rate), max(rdc_rate))
  )

# Panel outcome variables
panel_pre <- panel |> filter(year < 2012)
panel_post_fornero <- panel |> filter(year >= 2012 & year < 2019)
panel_post_rdc <- panel |> filter(year >= 2019)

sumstat_rows <- function(df, label) {
  data.frame(
    Period = label,
    NEET_mean = mean(df$neet_rate, na.rm = TRUE),
    NEET_sd = sd(df$neet_rate, na.rm = TRUE),
    EmpY_mean = mean(df$emp_youth, na.rm = TRUE),
    EmpY_sd = sd(df$emp_youth, na.rm = TRUE),
    EmpOld_mean = mean(df$emp_older, na.rm = TRUE),
    EmpOld_sd = sd(df$emp_older, na.rm = TRUE),
    N = nrow(df)
  )
}

ss <- rbind(
  sumstat_rows(panel_pre, "Pre-Fornero (2005--2011)"),
  sumstat_rows(panel_post_fornero, "Post-Fornero (2012--2018)"),
  sumstat_rows(panel_post_rdc, "Post-RdC (2019--2023)")
)

# Write LaTeX
tab1 <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics}
\\label{tab:sumstats}
\\begin{threeparttable}
\\begin{tabular}{lccccccc}
\\toprule
 & \\multicolumn{2}{c}{NEET 18--24} & \\multicolumn{2}{c}{Emp.~15--24} & \\multicolumn{2}{c}{Emp.~55--64} & $N$ \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}
Period & Mean & SD & Mean & SD & Mean & SD & \\\\
\\midrule\n"

for (i in seq_len(nrow(ss))) {
  tab1 <- paste0(tab1, sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f & %d \\\\\n",
    ss$Period[i], ss$NEET_mean[i], ss$NEET_sd[i],
    ss$EmpY_mean[i], ss$EmpY_sd[i],
    ss$EmpOld_mean[i], ss$EmpOld_sd[i], ss$N[i]))
}

# Add treatment variable summary
region_only <- panel |> filter(!duplicated(region))
tab1 <- paste0(tab1, "\\midrule\n")
tab1 <- paste0(tab1, "\\multicolumn{8}{l}{\\textit{Treatment variables (region-level)}} \\\\\n")
tab1 <- paste0(tab1, sprintf("Fornero bite (pp) & %.1f & %.1f & & & %.1f & %.1f & %d \\\\\n",
  mean(region_only$fornero_bite), sd(region_only$fornero_bite),
  min(region_only$fornero_bite), max(region_only$fornero_bite),
  n_distinct(panel$region)))
tab1 <- paste0(tab1, sprintf("RdC take-up (\\%% WAP) & %.2f & %.2f & & & %.2f & %.2f & %d \\\\\n",
  mean(region_only$rdc_rate), sd(region_only$rdc_rate),
  min(region_only$rdc_rate), max(region_only$rdc_rate),
  n_distinct(panel$region)))
tab1 <- paste0(tab1, sprintf("Correlation(bite, RdC) & \\multicolumn{6}{c}{%.3f} \\\\\n",
  cor(region_only$fornero_bite, region_only$rdc_rate, use = "complete")))

tab1 <- paste0(tab1, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Employment rates and NEET rates from Eurostat (lfst\\_r\\_lfe2emprt, edat\\_lfse\\_22). Fornero bite is the change in the 55--64 employment rate from 2010 to 2014. RdC take-up is the number of RdC/PdC recipient households per 100 working-age persons in 2019 (INPS). Panel covers 21 Italian NUTS2 regions, 2005--2023 (19 years, 399 region-years).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tab1, "../tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

# ------------------------------------------------------------------
# Table 2: Main Results — Triple Difference
# ------------------------------------------------------------------
cat("\n--- Table 2: Main results ---\n")

# Collect models
models <- list(
  "(1)" = results$phase1_neet,
  "(2)" = results$phase1_emp,
  "(3)" = results$phase2_neet,
  "(4)" = results$phase2_emp,
  "(5)" = results$phase2_ya
)

# Extract coefficients manually for precise control
extract_row <- function(model, varname) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = sprintf("%.3f%s", b, stars), se = sprintf("(%.3f)", s))
}

tab2 <- "\\begin{table}[t]
\\centering
\\caption{The Double Squeeze: Sequential Labor Shocks and Youth Outcomes}
\\label{tab:main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & \\multicolumn{2}{c}{Phase 1 (2005--2018)} & \\multicolumn{3}{c}{Phase 2 (2005--2023)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-6}
 & NEET & Emp.~15--24 & NEET & Emp.~15--24 & Emp.~25--34 \\\\
 & (1) & (2) & (3) & (4) & (5) \\\\
\\midrule\n"

# Fornero × Post
for (i in seq_along(models)) {
  var <- "fornero_x_post_sd"
  if (var %in% names(coef(models[[i]]))) {
    r <- extract_row(models[[i]], var)
    if (i == 1) tab2 <- paste0(tab2, "Fornero $\\times$ Post")
    tab2 <- paste0(tab2, " & ", r$coef)
  } else {
    tab2 <- paste0(tab2, " & ")
  }
}
tab2 <- paste0(tab2, " \\\\\n")
for (i in seq_along(models)) {
  var <- "fornero_x_post_sd"
  if (var %in% names(coef(models[[i]]))) {
    r <- extract_row(models[[i]], var)
    tab2 <- paste0(tab2, " & ", r$se)
  } else {
    tab2 <- paste0(tab2, " & ")
  }
}
tab2 <- paste0(tab2, " \\\\\n")

# RdC × Post
tab2 <- paste0(tab2, "RdC $\\times$ Post & & ")
for (i in 3:5) {
  var <- "rdc_x_post_sd"
  r <- extract_row(models[[i]], var)
  tab2 <- paste0(tab2, " & ", r$coef)
}
tab2 <- paste0(tab2, " \\\\\n & & ")
for (i in 3:5) {
  var <- "rdc_x_post_sd"
  r <- extract_row(models[[i]], var)
  tab2 <- paste0(tab2, " & ", r$se)
}
tab2 <- paste0(tab2, " \\\\\n")

# Triple interaction
tab2 <- paste0(tab2, "Fornero $\\times$ RdC $\\times$ Post & & ")
for (i in 3:5) {
  var <- "triple_sd"
  r <- extract_row(models[[i]], var)
  tab2 <- paste0(tab2, " & ", r$coef)
}
tab2 <- paste0(tab2, " \\\\\n & & ")
for (i in 3:5) {
  var <- "triple_sd"
  r <- extract_row(models[[i]], var)
  tab2 <- paste0(tab2, " & ", r$se)
}
tab2 <- paste0(tab2, " \\\\\n")

# Footer
tab2 <- paste0(tab2, "\\midrule\n")
tab2 <- paste0(tab2, sprintf("Region FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
tab2 <- paste0(tab2, sprintf("Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
tab2 <- paste0(tab2, sprintf("Regions & %d & %d & %d & %d & %d \\\\\n",
  n_distinct(panel |> filter(year <= 2018) |> pull(region)),
  n_distinct(panel |> filter(year <= 2018) |> pull(region)),
  n_distinct(panel$region), n_distinct(panel$region), n_distinct(panel$region)))

n_p1 <- nrow(panel |> filter(year <= 2018))
n_p2 <- nrow(panel)
tab2 <- paste0(tab2, sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
  n_p1, n_p1, n_p2, n_p2, n_p2))

tab2 <- paste0(tab2, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All treatment variables standardized (zero mean, unit variance). Fornero bite is the change in 55--64 employment rate 2010--2014. RdC rate is recipient households per working-age person in 2019. Standard errors clustered at the NUTS2 region level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tab2, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

# ------------------------------------------------------------------
# Table 3: Robustness
# ------------------------------------------------------------------
cat("\n--- Table 3: Robustness ---\n")

rob_models <- list(
  "(1)" = results$phase2_neet,
  "(2)" = robustness$placebo_prime,
  "(3)" = robustness$placebo_older,
  "(4)" = robustness$alt_bite,
  "(5)" = robustness$nocovid
)

rob_labels <- c("NEET 18--24", "Emp.~45--54", "Emp.~55--64",
                "NEET (alt.~bite)", "NEET (excl.~COVID)")

tab3 <- "\\begin{table}[t]
\\centering
\\caption{Robustness: Placebo Outcomes, Alternative Bite, and COVID Exclusion}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
 & Main & \\multicolumn{2}{c}{Placebo outcomes} & Alt.~bite & Excl.~COVID \\\\
\\cmidrule(lr){3-4}
 & NEET & Emp.~45--54 & Emp.~55--64 & NEET & NEET \\\\
 & (1) & (2) & (3) & (4) & (5) \\\\
\\midrule\n"

# Triple coefficient row
triple_vars <- c("triple_sd", "triple_sd", "triple_sd", "triple_alt", "triple_sd")

tab3 <- paste0(tab3, "Triple interaction")
for (i in seq_along(rob_models)) {
  v <- triple_vars[i]
  if (v %in% names(coef(rob_models[[i]]))) {
    r <- extract_row(rob_models[[i]], v)
    tab3 <- paste0(tab3, " & ", r$coef)
  } else {
    tab3 <- paste0(tab3, " & ---")
  }
}
tab3 <- paste0(tab3, " \\\\\n")

tab3 <- paste0(tab3, "")
for (i in seq_along(rob_models)) {
  v <- triple_vars[i]
  if (v %in% names(coef(rob_models[[i]]))) {
    r <- extract_row(rob_models[[i]], v)
    tab3 <- paste0(tab3, " & ", r$se)
  } else {
    tab3 <- paste0(tab3, " & ")
  }
}
tab3 <- paste0(tab3, " \\\\\n")

# LOO range
loo_min <- min(robustness$loo$coef)
loo_max <- max(robustness$loo$coef)

tab3 <- paste0(tab3, "\\midrule\n")
tab3 <- paste0(tab3, sprintf("Leave-one-out range & [%.3f, %.3f] & & & & \\\\\n", loo_min, loo_max))
tab3 <- paste0(tab3, sprintf("Permutation $p$-value & %.3f & & & & \\\\\n", robustness$perm_pval))

if (!is.null(results$boot_neet)) {
  tab3 <- paste0(tab3, sprintf("WCB $p$-value & %.3f & & & & \\\\\n", results$boot_neet$p_val))
}

tab3 <- paste0(tab3, "Region \\& Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
tab3 <- paste0(tab3, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column 1 reproduces the main NEET specification. Columns 2--3 use placebo outcomes that should not respond to the double squeeze mechanism. Column 4 uses the 2010--2016 change in 55--64 employment as an alternative Fornero bite measure. Column 5 drops 2020--2021. WCB: Webb six-point wild cluster bootstrap with 9,999 replications. Permutation: 1,000 random reassignments of both treatment vectors. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tab3, "../tables/tab3_robustness.tex")
cat("Table 3 written.\n")

# ------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE Appendix)
# ------------------------------------------------------------------
cat("\n--- Table F1: Standardized Effect Sizes ---\n")

# Get pre-treatment SDs
pre_panel <- panel |> filter(year < 2012)

sd_neet_pre <- sd(pre_panel$neet_rate, na.rm = TRUE)
sd_emp_youth_pre <- sd(pre_panel$emp_youth, na.rm = TRUE)
sd_emp_ya_pre <- sd(pre_panel$emp_young_adult, na.rm = TRUE)
sd_emp_prime_pre <- sd(pre_panel$emp_prime, na.rm = TRUE)

# For continuous treatment, SDE = beta * SD(X) / SD(Y)
# Since we already standardized X, SDE = beta / SD(Y)
compute_sde <- function(model, varname, sd_y) {
  b <- coef(model)[varname]
  se_b <- se(model)[varname]
  sde <- b / sd_y
  se_sde <- se_b / sd_y
  classify <- function(s) {
    if (s > 0.15) return("Large positive")
    if (s > 0.05) return("Moderate positive")
    if (s > 0.005) return("Small positive")
    if (s > -0.005) return("Null")
    if (s > -0.05) return("Small negative")
    if (s > -0.15) return("Moderate negative")
    return("Large negative")
  }
  list(beta = b, se_beta = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde,
       class = classify(sde))
}

# Panel A: Pooled (triple interaction coefficient)
sde_neet <- compute_sde(results$phase2_neet, "triple_sd", sd_neet_pre)
sde_emp_y <- compute_sde(results$phase2_emp, "triple_sd", sd_emp_youth_pre)
sde_emp_ya <- compute_sde(results$phase2_ya, "triple_sd", sd_emp_ya_pre)

# Panel B: Heterogeneous — split by North/South
south_regions <- c("ITF1", "ITF2", "ITF3", "ITF4", "ITF5", "ITF6", "ITG1", "ITG2")

panel_south <- panel |> filter(region %in% south_regions)
panel_north <- panel |> filter(!region %in% south_regions)

m_south <- feols(neet_rate ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                 | region + year, data = panel_south, cluster = ~region)
m_north <- feols(neet_rate ~ fornero_x_post_sd + rdc_x_post_sd + triple_sd
                 | region + year, data = panel_north, cluster = ~region)

sd_neet_south <- sd(panel_south$neet_rate[panel_south$year < 2012], na.rm = TRUE)
sd_neet_north <- sd(panel_north$neet_rate[panel_north$year < 2012], na.rm = TRUE)

sde_south <- compute_sde(m_south, "triple_sd", sd_neet_south)
sde_north <- compute_sde(m_north, "triple_sd", sd_neet_north)

# Build SDE table
sde_row <- function(outcome, s) {
  sprintf("%s & %.3f & %.3f & %.2f & %.3f & %.3f & %s",
    outcome, s$beta, s$se_beta, s$sd_y, s$sde, s$se_sde, s$class)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Italy. ",
  "\\textbf{Research question:} Do the Fornero pension reform (2012) and Reddito di Cittadinanza (2019) produce non-additive effects on youth labor market disengagement? ",
  "\\textbf{Policy mechanism:} The Fornero reform raised retirement ages, forcing older workers to remain employed and potentially blocking entry-level positions for youth; the RdC provided minimum income transfers to low-income households, potentially reducing job search intensity among young adults. ",
  "\\textbf{Outcome definition:} NEET rate (not in employment, education, or training) for persons aged 18--24, from Eurostat Labour Force Survey (edat\\_lfse\\_22). ",
  "\\textbf{Treatment:} Continuous interaction of two standardized region-level intensities: Fornero bite (change in 55--64 employment rate 2010--2014) and RdC take-up (recipient households per working-age person, 2019). ",
  "\\textbf{Data:} Eurostat NUTS2 regional employment and NEET statistics, 21 Italian regions, 2005--2023 (399 region-years). INPS RdC administrative data for treatment intensity. ",
  "\\textbf{Method:} Continuous triple-difference with region and year fixed effects; clustered standard errors with wild cluster bootstrap (Webb, 9,999 draws) and permutation inference (1,000 draws). ",
  "\\textbf{Sample:} All 21 Italian NUTS2 regions observed annually 2005--2023; no sample restrictions. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2005--2011) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- "\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes: The Double Squeeze}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"

tabF1 <- paste0(tabF1, sde_row("NEET 18--24", sde_neet), " \\\\\n")
tabF1 <- paste0(tabF1, sde_row("Employment 15--24", sde_emp_y), " \\\\\n")
tabF1 <- paste0(tabF1, sde_row("Employment 25--34", sde_emp_ya), " \\\\\n")

tabF1 <- paste0(tabF1, "\\midrule\n")
tabF1 <- paste0(tabF1, "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (NEET 18--24)}} \\\\\n")
tabF1 <- paste0(tabF1, sde_row("South \\& Islands", sde_south), " \\\\\n")
tabF1 <- paste0(tabF1, sde_row("Centre \\& North", sde_north), " \\\\\n")

tabF1 <- paste0(tabF1, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{threeparttable}
\\end{table}\n")

writeLines(tabF1, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
