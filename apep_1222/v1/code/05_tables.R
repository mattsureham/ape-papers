## 05_tables.R — Generate all LaTeX tables
## apep_1222: When the Mine Money Stops

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "regression_results.rds"))
diag <- read_json(file.path(data_dir, "diagnostics.json"))

## ================================================================
## Table 1: Summary Statistics
## ================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre-period stats by treatment group
pre <- panel[year < 2021]

stats_fn <- function(dt, group_label) {
  data.frame(
    Group = group_label,
    N_munis = uniqueN(dt$cve_mun),
    Mean_total = mean(dt$total_crime, na.rm = TRUE),
    SD_total = sd(dt$total_crime, na.rm = TRUE),
    Mean_homicide = mean(dt$homicide, na.rm = TRUE),
    SD_homicide = sd(dt$homicide, na.rm = TRUE),
    Mean_robbery = mean(dt$robbery, na.rm = TRUE),
    SD_robbery = sd(dt$robbery, na.rm = TRUE),
    Mean_extortion = mean(dt$extortion, na.rm = TRUE),
    SD_extortion = sd(dt$extortion, na.rm = TRUE),
    Mean_dv = mean(dt$domestic_violence, na.rm = TRUE),
    SD_dv = sd(dt$domestic_violence, na.rm = TRUE)
  )
}

sumstats <- rbind(
  stats_fn(pre[mining == 1], "Mining municipalities"),
  stats_fn(pre[mining == 0], "Non-mining municipalities"),
  stats_fn(pre, "All municipalities")
)

# Format for LaTeX
tab1_rows <- list()
vars <- c("Total crime", "Homicide", "Robbery", "Extortion", "Domestic violence")
mean_cols <- c("Mean_total", "Mean_homicide", "Mean_robbery", "Mean_extortion", "Mean_dv")
sd_cols <- c("SD_total", "SD_homicide", "SD_robbery", "SD_extortion", "SD_dv")

tab1_tex <- "\\begin{table}[H]\n\\centering\n\\caption{Summary Statistics: Pre-Treatment Period (2015--2019)}\n\\label{tab:sumstats}\n"
tab1_tex <- paste0(tab1_tex, "\\begin{adjustbox}{max width=\\textwidth}\n")
tab1_tex <- paste0(tab1_tex, "\\begin{threeparttable}\n")
tab1_tex <- paste0(tab1_tex, "\\begin{tabular}{l cc cc cc}\n\\toprule\n")
tab1_tex <- paste0(tab1_tex, " & \\multicolumn{2}{c}{Mining} & \\multicolumn{2}{c}{Non-Mining} & \\multicolumn{2}{c}{Difference} \\\\\n")
tab1_tex <- paste0(tab1_tex, "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n")
tab1_tex <- paste0(tab1_tex, " & Mean & SD & Mean & SD & Diff. & $p$-value \\\\\n\\midrule\n")

for (j in seq_along(vars)) {
  mn_t <- sumstats[1, mean_cols[j]]
  sd_t <- sumstats[1, sd_cols[j]]
  mn_c <- sumstats[2, mean_cols[j]]
  sd_c <- sumstats[2, sd_cols[j]]

  # t-test for difference
  col_map <- c(Mean_total = "total_crime", Mean_homicide = "homicide",
               Mean_robbery = "robbery", Mean_extortion = "extortion",
               Mean_dv = "domestic_violence")
  col_name <- col_map[mean_cols[j]]
  y_treat <- pre[mining == 1][[col_name]]
  y_ctrl <- pre[mining == 0][[col_name]]
  tt <- t.test(y_treat, y_ctrl)

  tab1_tex <- paste0(tab1_tex, sprintf("%s & %.1f & (%.1f) & %.1f & (%.1f) & %.1f & %.3f \\\\\n",
                                       vars[j], mn_t, sd_t, mn_c, sd_c, mn_t - mn_c, tt$p.value))
}

tab1_tex <- paste0(tab1_tex, "\\midrule\n")
tab1_tex <- paste0(tab1_tex, sprintf("Municipalities & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & & \\\\\n",
                                     sumstats$N_munis[1], sumstats$N_munis[2]))
tab1_tex <- paste0(tab1_tex, sprintf("Municipality $\\times$ years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & & \\\\\n",
                                     format(sumstats$N_munis[1] * 5, big.mark = ","),
                                     format(sumstats$N_munis[2] * 5, big.mark = ",")))
tab1_tex <- paste0(tab1_tex, "\\bottomrule\n\\end{tabular}\n")
tab1_tex <- paste0(tab1_tex, "\\begin{tablenotes}[flushleft]\\footnotesize\n")
tab1_tex <- paste0(tab1_tex, "\\item \\textit{Notes:} Pre-treatment period is 2015--2019. Mining municipalities are those that received Fondo Minero allocations according to SEDATU 2017 distribution data. Crime counts are annual municipality-level totals from SESNSP. Standard deviations in parentheses. $p$-values from two-sample $t$-tests for equality of means.\n")
tab1_tex <- paste0(tab1_tex, "\\end{tablenotes}\n\\end{threeparttable}\n")
tab1_tex <- paste0(tab1_tex, "\\end{adjustbox}\n\\end{table}\n")
writeLines(tab1_tex, file.path(tables_dir, "tab1_sumstats.tex"))

## ================================================================
## Table 2: Main DiD Results
## ================================================================
cat("Generating Table 2: Main DiD Results...\n")

setFixest_dict(c(
  "mining:post" = "Mining $\\times$ Post",
  "log_total" = "Log(Total Crime)",
  "log_homicide" = "Log(Homicide)",
  "log_robbery" = "Log(Robbery)",
  "log_extortion" = "Log(Extortion)",
  "log_dv" = "Log(Dom.\\ Violence)"
))

etable(results$did_total, results$did_homicide, results$did_robbery,
       results$did_extortion, results$did_dv,
       headers = c("Total Crime", "Homicide", "Robbery", "Extortion", "Dom. Violence"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       notes = paste0("\\textit{Notes:} Each column reports a separate TWFE DiD regression of log(crime + 1) on the interaction of a mining municipality indicator with a post-2020 indicator. All specifications include municipality and year fixed effects. Standard errors clustered at the state level (", diag$n_clusters, " clusters) in parentheses. Mining municipalities are those that received Fondo Minero allocations (SEDATU 2017). The post period begins in 2021, following the November 2020 decree eliminating the fund. Sample: 2015--2025. *** $p<0.01$, ** $p<0.05$, * $p<0.1$."),
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main_did.tex"),
       replace = TRUE,
       label = "tab:main_did",
       title = "Effect of Fondo Minero Elimination on Municipal Crime")

## ================================================================
## Table 3: Event Study Coefficients
## ================================================================
cat("Generating Table 3: Event Study...\n")

es <- results$es_total
es_ct <- coeftable(es)
es_df <- data.frame(
  event_time = as.integer(gsub(".*::(-?\\d+):.*", "\\1", rownames(es_ct))),
  estimate = es_ct[, "Estimate"],
  se = es_ct[, "Std. Error"],
  pval = es_ct[, "Pr(>|t|)"]
)
es_df <- es_df[order(es_df$event_time), ]
es_df$stars <- ifelse(es_df$pval < 0.01, "***",
                      ifelse(es_df$pval < 0.05, "**",
                             ifelse(es_df$pval < 0.1, "*", "")))

tab3_tex <- "\\begin{table}[H]\n\\centering\n\\caption{Event-Study Estimates: Total Crime}\n\\label{tab:event_study}\n"
tab3_tex <- paste0(tab3_tex, "\\begin{threeparttable}\n")
tab3_tex <- paste0(tab3_tex, "\\begin{tabular}{l c c c}\n\\toprule\n")
tab3_tex <- paste0(tab3_tex, "Event Time & Estimate & SE & 95\\% CI \\\\\n\\midrule\n")

for (i in seq_len(nrow(es_df))) {
  et <- es_df$event_time[i]
  est <- es_df$estimate[i]
  se_val <- es_df$se[i]
  ci_lo <- est - 1.96 * se_val
  ci_hi <- est + 1.96 * se_val
  label <- ifelse(et == -1, "$t-1$ (ref.)", sprintf("$t%+d$", et))
  if (et == -1) {
    tab3_tex <- paste0(tab3_tex, sprintf("%s & --- & --- & --- \\\\\n", label))
  } else {
    tab3_tex <- paste0(tab3_tex, sprintf("%s & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\\n",
                                         label, est, es_df$stars[i], se_val, ci_lo, ci_hi))
  }
}

tab3_tex <- paste0(tab3_tex, "\\midrule\n")
tab3_tex <- paste0(tab3_tex, sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\\n",
                                     format(nobs(es), big.mark = ",")))
tab3_tex <- paste0(tab3_tex, sprintf("Municipalities & \\multicolumn{3}{c}{%d} \\\\\n",
                                     uniqueN(panel$cve_mun)))
tab3_tex <- paste0(tab3_tex, "Municipality FE & \\multicolumn{3}{c}{Yes} \\\\\n")
tab3_tex <- paste0(tab3_tex, "Year FE & \\multicolumn{3}{c}{Yes} \\\\\n")
tab3_tex <- paste0(tab3_tex, "\\bottomrule\n\\end{tabular}\n")
tab3_tex <- paste0(tab3_tex, "\\begin{tablenotes}[flushleft]\\footnotesize\n")
tab3_tex <- paste0(tab3_tex, "\\item \\textit{Notes:} Event-study estimates from a TWFE regression of log(total crime + 1) on interactions of the mining municipality indicator with year dummies, relative to $t-1$ (2019). Standard errors clustered at the state level in parentheses. 95\\% confidence intervals in brackets. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.\n")
tab3_tex <- paste0(tab3_tex, "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
writeLines(tab3_tex, file.path(tables_dir, "tab3_event_study.tex"))

## ================================================================
## Table 4: Robustness
## ================================================================
cat("Generating Table 4: Robustness...\n")

# Collect robustness results
rob_specs <- list(
  "Baseline" = results$did_total,
  "State $\\times$ Year FE" = results$did_stateyear,
  "High allocation $\\times$ Post" = results$did_dose,
  "Placebo (2018)" = results$did_placebo
)

tab4_tex <- "\\begin{table}[H]\n\\centering\n\\caption{Robustness Checks}\n\\label{tab:robustness}\n"
tab4_tex <- paste0(tab4_tex, "\\begin{adjustbox}{max width=\\textwidth}\n")
tab4_tex <- paste0(tab4_tex, "\\begin{threeparttable}\n")
tab4_tex <- paste0(tab4_tex, "\\begin{tabular}{l cccc}\n\\toprule\n")
tab4_tex <- paste0(tab4_tex, " & (1) & (2) & (3) & (4) \\\\\n")
tab4_tex <- paste0(tab4_tex, " & Baseline & State$\\times$Year FE & Dose-Response & Placebo \\\\\n\\midrule\n")

# Row 1: Mining × Post (or equivalent)
specs <- list(results$did_total, results$did_stateyear, results$did_dose, results$did_placebo)
for (s in seq_along(specs)) {
  ct <- coeftable(specs[[s]])
  for (r in seq_len(nrow(ct))) {
    est <- ct[r, "Estimate"]
    se_val <- ct[r, "Std. Error"]
    pv <- ct[r, "Pr(>|t|)"]
    stars <- ifelse(pv < 0.01, "***", ifelse(pv < 0.05, "**", ifelse(pv < 0.1, "*", "")))
    rname <- rownames(ct)[r]
    # We'll build the table manually below
  }
}

# Simpler approach: write each specification's key coefficient
write_spec_row <- function(spec, label) {
  ct <- coeftable(spec)
  n <- nobs(spec)
  coefs <- ct[, "Estimate"]
  ses <- ct[, "Std. Error"]
  pvs <- ct[, "Pr(>|t|)"]
  stars_fn <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

  rows <- ""
  for (r in seq_len(nrow(ct))) {
    rn <- gsub("_", "\\\\_", rownames(ct)[r])
    rn <- gsub(":", " $\\\\times$ ", rn)
    rows <- paste0(rows, sprintf("%s & %.4f%s \\\\\n", rn, coefs[r], stars_fn(pvs[r])))
    rows <- paste0(rows, sprintf(" & (%.4f) \\\\\n", ses[r]))
  }
  rows
}

# Build table with etable for cleaner output
etable(results$did_total, results$did_stateyear, results$did_dose, results$did_placebo,
       headers = c("Baseline", "State$\\times$Year FE", "Dose-Response", "Placebo (2018)"),
       se.below = TRUE,
       fitstat = c("n", "r2"),
       style.tex = style.tex("aer"),
       notes = "\\textit{Notes:} Column (1) reproduces the baseline specification from Table 2. Column (2) replaces year fixed effects with state $\\times$ year fixed effects. Column (3) splits the treatment into high-allocation (above-median) and low-allocation municipalities. Column (4) tests for a placebo effect at 2018 using only pre-treatment data (2015--2019). All specifications include municipality fixed effects. Standard errors clustered at the state level in parentheses. *** $p<0.01$, ** $p<0.05$, * $p<0.1$.",
       tex = TRUE,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       replace = TRUE,
       label = "tab:robustness",
       title = "Robustness Checks")

## ================================================================
## Table F1: Standardized Effect Sizes (SDE) — Appendix
## ================================================================
cat("Generating SDE table...\n")

# Compute SDE for main outcomes
sd_y_pre <- panel[mining == 1 & year < 2021,
                  .(sd_log_total = sd(log_total, na.rm = TRUE),
                    sd_log_homicide = sd(log_homicide, na.rm = TRUE),
                    sd_log_robbery = sd(log_robbery, na.rm = TRUE),
                    sd_log_extortion = sd(log_extortion, na.rm = TRUE),
                    sd_log_dv = sd(log_dv, na.rm = TRUE))]

sde_rows <- data.frame(
  Outcome = c("Total crime", "Homicide", "Robbery", "Extortion"),
  beta = c(coef(results$did_total)[[1]],
           coef(results$did_homicide)[[1]],
           coef(results$did_robbery)[[1]],
           coef(results$did_extortion)[[1]]),
  se_beta = c(se(results$did_total)[[1]],
              se(results$did_homicide)[[1]],
              se(results$did_robbery)[[1]],
              se(results$did_extortion)[[1]]),
  sd_y = c(sd_y_pre$sd_log_total,
           sd_y_pre$sd_log_homicide,
           sd_y_pre$sd_log_robbery,
           sd_y_pre$sd_log_extortion),
  stringsAsFactors = FALSE
)

sde_rows$sde <- sde_rows$beta / sde_rows$sd_y
sde_rows$se_sde <- sde_rows$se_beta / sde_rows$sd_y

# Classification
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}
sde_rows$classification <- classify_sde(sde_rows$sde)

# Panel A: Pooled
cat("SDE Table — Panel A (Pooled):\n")
print(sde_rows[, c("Outcome", "beta", "se_beta", "sd_y", "sde", "se_sde", "classification")])

# Panel B: Heterogeneous (high vs low allocation)
median_alloc <- median(panel[mining == 1 & allocation_2017 > 0]$allocation_2017)
panel[, high_mining := as.integer(allocation_2017 > median_alloc)]
panel[, low_mining := as.integer(mining == 1 & allocation_2017 <= median_alloc)]

did_total_high <- feols(log_total ~ mining:post | cve_mun + year,
                        data = panel[high_mining == 1 | mining == 0],
                        cluster = ~state_code)
did_total_low <- feols(log_total ~ mining:post | cve_mun + year,
                       data = panel[low_mining == 1 | (mining == 0)],
                       cluster = ~state_code)

if (TRUE) {
  sd_high <- sd(panel[high_mining == 1 & year < 2021]$log_total, na.rm = TRUE)
  sd_low <- sd(panel[low_mining == 1 & year < 2021]$log_total, na.rm = TRUE)

  het_rows <- data.frame(
    Outcome = c("Total crime (high alloc.)", "Total crime (low alloc.)"),
    beta = c(coef(did_total_high)[[1]], coef(did_total_low)[[1]]),
    se_beta = c(se(did_total_high)[[1]], se(did_total_low)[[1]]),
    sd_y = c(sd_high, sd_low),
    stringsAsFactors = FALSE
  )
  het_rows$sde <- het_rows$beta / het_rows$sd_y
  het_rows$se_sde <- het_rows$se_beta / het_rows$sd_y
  het_rows$classification <- classify_sde(het_rows$sde)

  all_sde <- rbind(sde_rows, het_rows)
} else {
  all_sde <- sde_rows
}

# Generate LaTeX
n_treated_total <- uniqueN(panel[mining == 1]$cve_mun)
n_obs_total <- nrow(panel)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Mexico. ",
  "\\textbf{Research question:} Does the abrupt elimination of earmarked mining revenue transfers (Fondo Minero) to approximately ", n_treated_total,
  " mining municipalities increase local crime? ",
  "\\textbf{Policy mechanism:} Mexico's November 2020 decree extinguished the Fondo Minero, which since 2014 had distributed 2--6 billion pesos annually from a 7.5\\% special mining tax to municipalities hosting mining operations, funding local infrastructure, social programs, and public safety. The elimination redirected 85\\% of revenue to the federal education ministry, stripping mining communities of dedicated fiscal transfers. ",
  "\\textbf{Outcome definition:} Log of annual municipal crime counts plus one, from SESNSP administrative records covering all reported crimes by type and municipality. ",
  "\\textbf{Treatment:} Binary indicator for municipalities that received Fondo Minero allocations (SEDATU 2017 distribution data). ",
  "\\textbf{Data:} SESNSP municipal crime data (2015--2025, ", format(n_obs_total, big.mark = ","), " municipality-year observations, ",
  uniqueN(panel$cve_mun), " municipalities) combined with SEDATU Fondo Minero distribution records. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with municipality and year fixed effects; standard errors clustered at the state level (", diag$n_clusters, " clusters). ",
  "\\textbf{Sample:} All Mexican municipalities with SESNSP crime data, 2015--2025; mining municipalities defined by Fondo Minero receipt. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among treated municipalities. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- "\\begin{table}[H]\n\\centering\n\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n"
sde_tex <- paste0(sde_tex, "\\begin{adjustbox}{max width=\\textwidth}\n")
sde_tex <- paste0(sde_tex, "\\begin{threeparttable}\n")
sde_tex <- paste0(sde_tex, "\\begin{tabular}{l cccccc}\n\\toprule\n")
sde_tex <- paste0(sde_tex, "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
sde_tex <- paste0(sde_tex, "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (i in seq_len(nrow(sde_rows))) {
  sde_tex <- paste0(sde_tex, sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
                                     sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se_beta[i],
                                     sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i],
                                     sde_rows$classification[i]))
}

if (exists("het_rows")) {
  sde_tex <- paste0(sde_tex, "\\midrule\n")
  sde_tex <- paste0(sde_tex, "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by allocation intensity)}} \\\\\n")
  for (i in seq_len(nrow(het_rows))) {
    sde_tex <- paste0(sde_tex, sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
                                       het_rows$Outcome[i], het_rows$beta[i], het_rows$se_beta[i],
                                       het_rows$sd_y[i], het_rows$sde[i], het_rows$se_sde[i],
                                       het_rows$classification[i]))
  }
}

sde_tex <- paste0(sde_tex, "\\bottomrule\n\\end{tabular}\n")
sde_tex <- paste0(sde_tex, "\\begin{tablenotes}[flushleft]\\footnotesize\n")
sde_tex <- paste0(sde_tex, sde_notes, "\n")
sde_tex <- paste0(sde_tex, "\\end{tablenotes}\n\\end{threeparttable}\n")
sde_tex <- paste0(sde_tex, "\\end{adjustbox}\n\\end{table}\n")

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("All tables generated in tables/ directory.\n")
cat(sprintf("  tab1_sumstats.tex\n  tab2_main_did.tex\n  tab3_event_study.tex\n  tab4_robustness.tex\n  tabF1_sde.tex\n"))
