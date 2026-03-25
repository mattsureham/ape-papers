## 05_tables.R — Generate all LaTeX tables
## apep_0942: Dominican Republic MIPYME Procurement Set-Asides

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))
rob <- readRDS(file.path(data_dir, "robustness.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================

# Pre-period means by treatment intensity tercile
panel[, tercile := cut(delta_mipyme,
                       breaks = quantile(delta_mipyme, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
                       labels = c("Low", "Medium", "High"),
                       include.lowest = TRUE)]

summ <- panel[post == 0, .(
  `Processes/Quarter` = mean(n_processes),
  `Unique Suppliers/Quarter` = mean(n_unique_suppliers),
  `HHI` = mean(hhi, na.rm = TRUE),
  `Share First-Time Winners` = mean(share_first_time, na.rm = TRUE),
  `MIPYME Share (Pre)` = mean(mipyme_share),
  `$\\Delta$ MIPYME Share (pp)` = mean(delta_mipyme) * 100
), by = tercile]

# Also compute full sample means
full_pre <- panel[post == 0, .(
  tercile = "All",
  `Processes/Quarter` = mean(n_processes),
  `Unique Suppliers/Quarter` = mean(n_unique_suppliers),
  `HHI` = mean(hhi, na.rm = TRUE),
  `Share First-Time Winners` = mean(share_first_time, na.rm = TRUE),
  `MIPYME Share (Pre)` = mean(mipyme_share),
  `$\\Delta$ MIPYME Share (pp)` = mean(delta_mipyme) * 100
)]
summ <- rbind(summ, full_pre)

# Format
n_agencies <- panel[post == 0, .(n = uniqueN(agency)), by = tercile]
n_all <- data.table(tercile = "All", n = uniqueN(panel$agency))
n_agencies <- rbind(n_agencies, n_all)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics by Treatment Intensity}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Low & Medium & High & All \\\\\n",
  " & ($\\Delta$MIPYME $\\leq$ ", round(quantile(panel$delta_mipyme, 1/3, na.rm=TRUE)*100, 1), "pp)",
  " & (", round(quantile(panel$delta_mipyme, 1/3, na.rm=TRUE)*100, 1), "--",
  round(quantile(panel$delta_mipyme, 2/3, na.rm=TRUE)*100, 1), "pp)",
  " & ($>$ ", round(quantile(panel$delta_mipyme, 2/3, na.rm=TRUE)*100, 1), "pp)",
  " & \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Pre-Period Means (2016Q1--2020Q2)}} \\\\\n",
  "Agencies & ", paste(n_agencies$n, collapse = " & "), " \\\\\n",
  "Processes/quarter & ", paste(round(summ$`Processes/Quarter`, 1), collapse = " & "), " \\\\\n",
  "Unique suppliers/quarter & ", paste(round(summ$`Unique Suppliers/Quarter`, 1), collapse = " & "), " \\\\\n",
  "HHI & ", paste(round(summ$HHI, 3), collapse = " & "), " \\\\\n",
  "Share first-time winners & ", paste(round(summ$`Share First-Time Winners`, 3), collapse = " & "), " \\\\\n",
  "MIPYME share (pre) & ", paste(round(summ$`MIPYME Share (Pre)` * 100, 1), collapse = " & "), "\\% \\\\\n",
  "$\\Delta$ MIPYME share (pp) & ", paste(round(summ$`$\\Delta$ MIPYME Share (pp)`, 1), collapse = " & "), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Treatment intensity terciles based on the change in MIPYME-directed procurement share from pre-period (2016Q1--2020Q2) to post-period (2020Q3--2025Q4). HHI is the Herfindahl-Hirschman Index of contract concentration within agency-quarter. Sample restricted to agencies with at least 4 quarters in both pre- and post-periods (256 agencies, 8,415 agency-quarter observations).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

## ============================================================
## Table 2: Main Results
## ============================================================

m1 <- results$main$m1
m2 <- results$main$m2
m3 <- results$main$m3
m4 <- results$main$m4
m5 <- results$main$m5

stars <- function(p) {
  if (p < 0.001) "***"
  else if (p < 0.01) "**"
  else if (p < 0.05) "*"
  else ""
}

fmt_coef <- function(m, var = "delta_mipyme:post") {
  b <- coef(m)[var]
  s <- se(m)[var]
  p <- pvalue(m)[var]
  paste0(formatC(b, format = "f", digits = 4), stars(p))
}

fmt_se <- function(m, var = "delta_mipyme:post") {
  s <- se(m)[var]
  paste0("(", formatC(s, format = "f", digits = 4), ")")
}

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of MIPYME Set-Aside Enforcement on Supplier Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Log & & Share & Share & Share \\\\\n",
  " & Suppliers & HHI & First-Time & New Firm & MIPYME \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  "$\\Delta$MIPYME $\\times$ Post",
  " & ", fmt_coef(m1),
  " & ", fmt_coef(m2),
  " & ", fmt_coef(m3),
  " & ", fmt_coef(m4),
  " & ", fmt_coef(m5), " \\\\\n",
  " & ", fmt_se(m1),
  " & ", fmt_se(m2),
  " & ", fmt_se(m3),
  " & ", fmt_se(m4),
  " & ", fmt_se(m5), " \\\\\n",
  "\\hline\n",
  "Agency FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Observations & ", formatC(nobs(m1), big.mark = ","),
  " & ", formatC(nobs(m2), big.mark = ","),
  " & ", formatC(nobs(m3), big.mark = ","),
  " & ", formatC(nobs(m4), big.mark = ","),
  " & ", formatC(nobs(m5), big.mark = ","), " \\\\\n",
  "Agencies & 256 & 256 & 256 & 256 & 256 \\\\\n",
  "Pre-period mean & ",
  round(mean(panel$log_suppliers[panel$post == 0]), 3), " & ",
  round(mean(panel$hhi[panel$post == 0], na.rm = TRUE), 3), " & ",
  round(mean(panel$share_first_time[panel$post == 0], na.rm = TRUE), 3), " & ",
  round(mean(panel$share_new_firm[panel$post == 0], na.rm = TRUE), 3), " & ",
  round(mean(panel$share_mipyme_supplier[panel$post == 0], na.rm = TRUE), 3), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports a separate OLS regression. The treatment variable $\\Delta$MIPYME is the change in each agency's MIPYME-directed procurement share from pre-period (2016Q1--2020Q2) to post-period (2020Q3--2025Q4), interacted with a post-treatment indicator. Standard errors clustered at the agency level in parentheses. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(table_dir, "tab2_main.tex"))

## ============================================================
## Table 3: Robustness
## ============================================================

m_base <- results$main$m1
m_trend <- rob$trend_control
m_placebo <- rob$placebo
m_het_large <- rob$het_large
m_het_small <- rob$het_small

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks: Log Unique Suppliers}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Baseline & Trend & Placebo & Large & Small \\\\\n",
  " & & Control & (Pre-Only) & Agencies & Agencies \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\hline\n",
  "Treatment $\\times$ Post",
  " & ", fmt_coef(m_base),
  " & ", fmt_coef(m_trend),
  " & ", formatC(coef(m_placebo)["fake_delta:fake_post"], format = "f", digits = 4), stars(pvalue(m_placebo)["fake_delta:fake_post"]),
  " & ", fmt_coef(m_het_large),
  " & ", fmt_coef(m_het_small), " \\\\\n",
  " & ", fmt_se(m_base),
  " & ", fmt_se(m_trend),
  " & (", formatC(se(m_placebo)["fake_delta:fake_post"], format = "f", digits = 4), ")",
  " & ", fmt_se(m_het_large),
  " & ", fmt_se(m_het_small), " \\\\\n",
  "\\hline\n",
  "Agency FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Agency trend & No & Yes & No & No & No \\\\\n",
  "Observations",
  " & ", formatC(nobs(m_base), big.mark = ","),
  " & ", formatC(nobs(m_trend), big.mark = ","),
  " & ", formatC(nobs(m_placebo), big.mark = ","),
  " & ", formatC(nobs(m_het_large), big.mark = ","),
  " & ", formatC(nobs(m_het_small), big.mark = ","), " \\\\\n",
  "Agencies & 256 & 256 & 161",
  " & ", uniqueN(panel$agency[panel$large_agency == 1]),
  " & ", uniqueN(panel$agency[panel$large_agency == 0]), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column 1 reproduces the baseline from Table \\ref{tab:main}. Column 2 adds agency-specific linear time trends estimated from the pre-period. Column 3 runs a placebo test using only pre-treatment data (2016Q1--2020Q2) with a fake treatment date at 2018Q3. Columns 4--5 split the sample by pre-period procurement volume (above/below median). Standard errors clustered at the agency level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(table_dir, "tab3_robust.tex"))

## ============================================================
## Table 4: Supplier Decomposition
## ============================================================

decomp <- rob$decomp
decomp <- decomp[order(-share_n)]

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Post-Period Supplier Decomposition}\n",
  "\\label{tab:decomp}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  "Supplier Type & Awards & Share of & Value (B DOP) & Share of \\\\\n",
  " & & Awards & & Value \\\\\n",
  "\\hline\n"
)

for (i in 1:nrow(decomp)) {
  tab4 <- paste0(tab4,
    decomp$supplier_type[i],
    " & ", formatC(decomp$n[i], big.mark = ",", format = "d"),
    " & ", round(decomp$share_n[i] * 100, 1), "\\%",
    " & ", round(decomp$value[i] / 1e9, 1),
    " & ", round(decomp$share_value[i] * 100, 1), "\\%",
    " \\\\\n"
  )
}

tab4 <- paste0(tab4,
  "\\hline\n",
  "Total & ", formatC(sum(decomp$n), big.mark = ",", format = "d"),
  " & 100\\% & ", round(sum(decomp$value) / 1e9, 1),
  " & 100\\% \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Decomposition of post-period (2021--2025) contract awards by supplier type. ``Relabeled'' denotes suppliers that won contracts before August 2020 and are now MIPYME-certified. ``New MIPYME'' denotes suppliers that did not win contracts pre-treatment and are MIPYME-certified. ``New non-MIPYME'' denotes new suppliers without MIPYME certification. ``Continuing non-MIPYME'' denotes pre-existing suppliers without MIPYME certification. Values in billions of Dominican pesos.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(table_dir, "tab4_decomp.tex"))

## ============================================================
## Table 5: Event Study Coefficients
## ============================================================

m_event <- results$event
event_coefs <- data.table(
  year = c(2016:2018, 2020:2025),
  coef = coef(m_event),
  se = se(m_event),
  pval = pvalue(m_event)
)

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Event Study: Year-by-Year Effects on Log Unique Suppliers}\n",
  "\\label{tab:event}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Year $\\times$ $\\Delta$MIPYME & Coefficient & Std.~Error \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\\n"
)

for (i in 1:3) {
  tab5 <- paste0(tab5,
    event_coefs$year[i],
    " & ", formatC(event_coefs$coef[i], format = "f", digits = 3), stars(event_coefs$pval[i]),
    " & (", formatC(event_coefs$se[i], format = "f", digits = 3), ") \\\\\n"
  )
}

tab5 <- paste0(tab5,
  "2019 (ref.) & --- & --- \\\\\n",
  "\\hline\n",
  "\\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\\n"
)

for (i in 4:nrow(event_coefs)) {
  tab5 <- paste0(tab5,
    event_coefs$year[i],
    " & ", formatC(event_coefs$coef[i], format = "f", digits = 3), stars(event_coefs$pval[i]),
    " & (", formatC(event_coefs$se[i], format = "f", digits = 3), ") \\\\\n"
  )
}

tab5 <- paste0(tab5,
  "\\hline\n",
  "Agency FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Quarter FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Observations & \\multicolumn{2}{c}{", formatC(nobs(m_event), big.mark = ","), "} \\\\\n",
  "Pre-trend F-test p-value & \\multicolumn{2}{c}{",
  round(wald(m_event, paste0("year_factor::", 2016:2018, ":delta_mipyme"))$p, 3), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each coefficient is the interaction of year indicators with agency-level $\\Delta$MIPYME (change in MIPYME-directed share from pre to post). Reference year is 2019. Standard errors clustered at the agency level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5, file.path(table_dir, "tab5_event.tex"))

## ============================================================
## Table F1: Standardized Effect Sizes (SDE Appendix)
## ============================================================

# Compute SDE for main outcomes
# SDE = beta / SD(Y) for binary treatment; here continuous: SDE = beta * SD(X) / SD(Y)
sd_delta <- sd(panel$delta_mipyme[panel$post == 0], na.rm = TRUE)

compute_sde <- function(model, outcome_var, var_name = "delta_mipyme:post") {
  b <- coef(model)[var_name]
  se_b <- se(model)[var_name]
  sd_y <- sd(panel[[outcome_var]][panel$post == 0], na.rm = TRUE)
  sde <- b * sd_delta / sd_y
  se_sde <- se_b * sd_delta / sd_y
  list(b = b, se_b = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde)
}

sde_suppliers <- compute_sde(results$main$m1, "log_suppliers")
sde_hhi <- compute_sde(results$main$m2, "hhi")
sde_firsttime <- compute_sde(results$main$m3, "share_first_time")
sde_mipyme <- compute_sde(results$main$m5, "share_mipyme_supplier")

# Heterogeneous effects (large vs small agencies)
sde_large <- {
  b <- coef(rob$het_large)["delta_mipyme:post"]
  se_b <- se(rob$het_large)["delta_mipyme:post"]
  sd_y <- sd(panel$log_suppliers[panel$post == 0 & panel$large_agency == 1], na.rm = TRUE)
  sd_x <- sd(panel$delta_mipyme[panel$post == 0 & panel$large_agency == 1], na.rm = TRUE)
  sde <- b * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  list(b = b, se_b = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde)
}

sde_small <- {
  b <- coef(rob$het_small)["delta_mipyme:post"]
  se_b <- se(rob$het_small)["delta_mipyme:post"]
  sd_y <- sd(panel$log_suppliers[panel$post == 0 & panel$large_agency == 0], na.rm = TRUE)
  sd_x <- sd(panel$delta_mipyme[panel$post == 0 & panel$large_agency == 0], na.rm = TRUE)
  sde <- b * sd_x / sd_y
  se_sde <- se_b * sd_x / sd_y
  list(b = b, se_b = se_b, sd_y = sd_y, sde = sde, se_sde = se_sde)
}

classify_sde <- function(sde) {
  if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
}

# Build SDE table
sde_rows <- list(
  list("Log unique suppliers", sde_suppliers),
  list("HHI (concentration)", sde_hhi),
  list("Share first-time winners", sde_firsttime),
  list("Share MIPYME suppliers", sde_mipyme)
)

sde_het_rows <- list(
  list("Log suppliers (large agencies)", sde_large),
  list("Log suppliers (small agencies)", sde_small)
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Dominican Republic. ",
  "\\textbf{Research question:} Does enforcement of a dormant government procurement set-aside mandate for micro, small, and medium enterprises (MIPYMEs) expand small firm access to public contracts or merely relabel incumbent suppliers? ",
  "\\textbf{Policy mechanism:} The 20\\% MIPYME procurement reservation (Decree 543-12, enacted 2012) was unenforced until August 2020, when a presidential transition brought aggressive compliance pressure; agencies shifted from 3\\% to 17\\% MIPYME-directed procurement, with cross-agency variation in compliance intensity ranging from 0 to 71 percentage points. ",
  "\\textbf{Outcome definition:} Log of unique suppliers winning contracts per agency-quarter, Herfindahl-Hirschman Index of contract concentration, share of first-time contract winners, and share of MIPYME-certified suppliers among winners. ",
  "\\textbf{Treatment:} Continuous; change in MIPYME-directed procurement share (percentage points) from pre-period to post-period at the agency level. ",
  "\\textbf{Data:} DGCP (Direcci\\'on General de Contrataciones P\\'ublicas) open data, 2016--2025, agency-quarter panel, 8,415 observations across 256 agencies; 655,000 contract awards linked to 132,000 registered suppliers. ",
  "\\textbf{Method:} Generalized difference-in-differences with continuous treatment intensity, agency and quarter fixed effects, standard errors clustered at the agency level. ",
  "\\textbf{Sample:} Government agencies with at least 4 quarters of data in both pre- (2016Q1--2020Q2) and post-periods (2020Q3--2025Q4); 256 of 669 agencies meet this threshold. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(\\Delta\\text{MIPYME}) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (row in sde_rows) {
  s <- row[[2]]
  tabF1 <- paste0(tabF1,
    row[[1]],
    " & ", formatC(s$b, format = "f", digits = 4),
    " & ", formatC(s$se_b, format = "f", digits = 4),
    " & ", formatC(s$sd_y, format = "f", digits = 4),
    " & ", formatC(s$sde, format = "f", digits = 4),
    " & ", formatC(s$se_sde, format = "f", digits = 4),
    " & ", classify_sde(s$sde),
    " \\\\\n"
  )
}

tabF1 <- paste0(tabF1,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by agency size)}} \\\\\n"
)

for (row in sde_het_rows) {
  s <- row[[2]]
  tabF1 <- paste0(tabF1,
    row[[1]],
    " & ", formatC(s$b, format = "f", digits = 4),
    " & ", formatC(s$se_b, format = "f", digits = 4),
    " & ", formatC(s$sd_y, format = "f", digits = 4),
    " & ", formatC(s$sde, format = "f", digits = 4),
    " & ", formatC(s$se_sde, format = "f", digits = 4),
    " & ", classify_sde(s$sde),
    " \\\\\n"
  )
}

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("All tables generated successfully.\n")
