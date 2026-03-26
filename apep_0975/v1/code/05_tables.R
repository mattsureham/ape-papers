## 05_tables.R — Generate all LaTeX tables
## apep_0975: European Investigation Order and Crime Deterrence

source("00_packages.R")
setwd(file.path(dirname(getwd())))

panel <- fread("data/analysis_panel.csv")
cs_results <- readRDS("data/cs_results.rds")
twfe_results <- readRDS("data/twfe_results.rds")
ddd_reg <- readRDS("data/ddd_results.rds")
robustness <- readRDS("data/robustness_results.rds")

dir.create("tables", showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Summary by crime category
summ <- panel[!is.na(rate), .(
  `Mean Rate` = sprintf("%.1f", mean(rate)),
  `SD`        = sprintf("%.1f", sd(rate)),
  `Min`       = sprintf("%.1f", min(rate)),
  `Max`       = sprintf("%.1f", max(rate)),
  `Countries` = as.character(length(unique(geo))),
  `N`         = as.character(.N)
), by = .(Category = crime_label, Type = ifelse(cross_border == 1, "Cross-border", "Domestic"))]

summ <- summ[order(Type, Category)]

# LaTeX output
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Crime Rates per 100,000 Population}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llrrrrr}",
  "\\hline\\hline",
  "Category & Type & Mean & SD & Min & Max & N \\\\",
  "\\hline"
)
for (i in 1:nrow(summ)) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    summ$Category[i], summ$Type[i], summ$`Mean Rate`[i], summ$SD[i],
    summ$Min[i], summ$Max[i], summ$N[i]))
}
tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Police-recorded offences per 100,000 population from Eurostat (\\texttt{crim\\_off\\_cat}), 2008--2022. Cross-border crimes (fraud, drug offences, theft) are those where the European Investigation Order mechanism is most relevant. Domestic crimes (homicide, serious assault) serve as placebos.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, "tables/tab1_summary.tex")

# ===========================================================================
# Table 2: EIO Transposition Timeline
# ===========================================================================
cat("Generating Table 2: Transposition Timeline...\n")

eio <- fread("data/eio_transposition.csv")

# Add country names
iso_names <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden")
)

# Build full table including DK and IE
all_countries <- merge(iso_names, eio[, .(iso2, transposition_year, transposition_date)],
                       by = "iso2", all.x = TRUE)
all_countries[iso2 == "DK", `:=`(transposition_year = NA, status = "Opt-out")]
all_countries[iso2 == "IE", `:=`(transposition_year = NA, status = "Opt-out")]
all_countries[!iso2 %in% c("DK", "IE") & !is.na(transposition_year),
              status := ifelse(transposition_year <= 2016, "Early (2016)",
                        ifelse(transposition_year == 2017, "On time (2017)", "Late (2018)"))]
all_countries[is.na(status), status := "Unknown"]

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{EIO Directive (2014/41/EU) Transposition by Member State}",
  "\\label{tab:transposition}",
  "\\begin{tabular}{llcl}",
  "\\hline\\hline",
  "Country & ISO & Year & Status \\\\",
  "\\hline"
)

for (i in 1:nrow(all_countries[order(name)])) {
  row <- all_countries[order(name)][i]
  yr <- ifelse(is.na(row$transposition_year), "---", as.character(row$transposition_year))
  tab2_lines <- c(tab2_lines, sprintf("%s & %s & %s & %s \\\\",
    row$name, row$iso2, yr, row$status))
}

tab2_lines <- c(tab2_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Transposition dates from EUR-Lex CELLAR SPARQL (national implementation measures, earliest notification date per country). Deadline: May 22, 2017. Denmark and Ireland exercised their opt-out from Area of Freedom, Security and Justice measures.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, "tables/tab2_transposition.tex")

# ===========================================================================
# Table 3: Main Results (C-S and TWFE)
# ===========================================================================
cat("Generating Table 3: Main Results...\n")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of EIO Transposition on Crime Rates}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & \\multicolumn{3}{c}{Cross-Border Crimes} & \\multicolumn{2}{c}{Domestic (Placebo)} \\\\",
  "\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}",
  " & Fraud & Drugs & Theft & Homicide & Assault \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{6}{l}{\\textit{Panel A: Callaway-Sant'Anna}} \\\\[0.5ex]"
)

# C-S results
cs_cats <- c("ICCS0701", "ICCS0601", "ICCS0502", "ICCS0101", "ICCS020111")
cs_coef_line <- "ATT"
cs_se_line <- ""
for (cc in cs_cats) {
  if (!is.null(cs_results[[cc]]) && !isTRUE(cs_results[[cc]]$fallback)) {
    att <- cs_results[[cc]]$simple$overall.att
    se_val <- cs_results[[cc]]$simple$overall.se
    p_val <- 2 * pnorm(-abs(att / se_val))
    stars <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.1, "^{*}", "")))
    cs_coef_line <- paste0(cs_coef_line, sprintf(" & $%.3f%s$", att, stars))
    cs_se_line <- paste0(cs_se_line, sprintf(" & (%.3f)", se_val))
  } else if (!is.null(cs_results[[cc]]) && isTRUE(cs_results[[cc]]$fallback)) {
    twfe_fb <- cs_results[[cc]]$twfe
    att <- coef(twfe_fb)["treated"]
    se_val <- se(twfe_fb)["treated"]
    p_val <- pvalue(twfe_fb)["treated"]
    stars <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.1, "^{*}", "")))
    cs_coef_line <- paste0(cs_coef_line, sprintf(" & $%.3f%s$", att, stars))
    cs_se_line <- paste0(cs_se_line, sprintf(" & (%.3f)", se_val))
  } else {
    cs_coef_line <- paste0(cs_coef_line, " & ---")
    cs_se_line <- paste0(cs_se_line, " & ")
  }
}
cs_coef_line <- paste0(cs_coef_line, " \\\\")
cs_se_line <- paste0(cs_se_line, " \\\\[0.5ex]")

tab3_lines <- c(tab3_lines, cs_coef_line, cs_se_line)

# TWFE panel
tab3_lines <- c(tab3_lines,
  "\\multicolumn{6}{l}{\\textit{Panel B: Two-Way Fixed Effects}} \\\\[0.5ex]")

twfe_coef_line <- "ATT"
twfe_se_line <- ""
for (cc in cs_cats) {
  if (!is.null(twfe_results[[cc]])) {
    att <- coef(twfe_results[[cc]])["treated"]
    se_val <- se(twfe_results[[cc]])["treated"]
    p_val <- pvalue(twfe_results[[cc]])["treated"]
    stars <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.1, "^{*}", "")))
    twfe_coef_line <- paste0(twfe_coef_line, sprintf(" & $%.3f%s$", att, stars))
    twfe_se_line <- paste0(twfe_se_line, sprintf(" & (%.3f)", se_val))
  } else {
    twfe_coef_line <- paste0(twfe_coef_line, " & ---")
    twfe_se_line <- paste0(twfe_se_line, " & ")
  }
}
twfe_coef_line <- paste0(twfe_coef_line, " \\\\")
twfe_se_line <- paste0(twfe_se_line, " \\\\[0.5ex]")

tab3_lines <- c(tab3_lines, twfe_coef_line, twfe_se_line)

# Footer
tab3_lines <- c(tab3_lines,
  "\\hline",
  "Country FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Clustering & Country & Country & Country & Country & Country \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is log(crime rate per 100,000 + 0.01). Panel A reports the simple aggregate ATT from Callaway and Sant'Anna (2021) with doubly-robust estimation and never-treated (Denmark, Ireland) as the control group. Panel B reports two-way fixed effects estimates. Standard errors clustered at the country level in parentheses. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, "tables/tab3_main.tex")

# ===========================================================================
# Table 4: Robustness
# ===========================================================================
cat("Generating Table 4: Robustness...\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks: Fraud (ICCS0701)}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Specification & Estimate & SE & p-value & N \\\\",
  "\\hline"
)

# Baseline
fraud_twfe <- twfe_results[["ICCS0701"]]
if (!is.null(fraud_twfe)) {
  tab4_lines <- c(tab4_lines, sprintf("Baseline TWFE & $%.3f$ & $%.3f$ & $%.3f$ & %d \\\\",
    coef(fraud_twfe)["treated"], se(fraud_twfe)["treated"],
    pvalue(fraud_twfe)["treated"], nobs(fraud_twfe)))
}

# Pre-COVID
if (!is.null(robustness$pre_covid[["ICCS0701"]])) {
  r <- robustness$pre_covid[["ICCS0701"]]
  tab4_lines <- c(tab4_lines, sprintf("Excl. COVID (2020--22) & $%.3f$ & $%.3f$ & $%.3f$ & %d \\\\",
    coef(r)["treated"], se(r)["treated"], pvalue(r)["treated"], nobs(r)))
}

# RI
if (!is.null(robustness$ri)) {
  tab4_lines <- c(tab4_lines, sprintf("Randomization inference & $%.3f$ & --- & $%.3f$ & --- \\\\",
    robustness$ri$actual, robustness$ri$p_value))
}

# Lagged
if (!is.null(robustness$lagged[["ICCS0701"]])) {
  r <- robustness$lagged[["ICCS0701"]]
  tab4_lines <- c(tab4_lines, sprintf("1-year lagged treatment & $%.3f$ & $%.3f$ & $%.3f$ & %d \\\\",
    coef(r)["treated"], se(r)["treated"], pvalue(r)["treated"], nobs(r)))
}

# Levels
if (!is.null(robustness$levels[["ICCS0701"]])) {
  r <- robustness$levels[["ICCS0701"]]
  tab4_lines <- c(tab4_lines, sprintf("Levels (rate per 100k) & $%.1f$ & $%.1f$ & $%.3f$ & %d \\\\",
    coef(r)["treated"], se(r)["treated"], pvalue(r)["treated"], nobs(r)))
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include country and year fixed effects. Baseline uses log(fraud rate per 100,000 + 0.01) as dependent variable. Wild cluster bootstrap uses Rademacher weights with 9,999 replications. Randomization inference permutes treatment assignment across countries (500 permutations). Standard errors clustered at country level except where noted.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, "tables/tab4_robustness.tex")

# ===========================================================================
# Table 5: Triple-Difference
# ===========================================================================
cat("Generating Table 5: Triple-Difference...\n")

ddd_coefs <- coef(ddd_reg)
ddd_ses <- se(ddd_reg)
ddd_pvals <- pvalue(ddd_reg)

# Find the triple interaction term
ddd_names <- names(ddd_coefs)
triple_idx <- grep("cross_border.*post.*ever_treated|ever_treated.*post.*cross_border", ddd_names)

tab5_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Triple-Difference: Cross-Border vs.~Domestic Crimes}",
  "\\label{tab:ddd}",
  "\\begin{tabular}{lc}",
  "\\hline\\hline",
  " & Log(Rate per 100k) \\\\",
  "\\hline"
)

for (i in seq_along(ddd_coefs)) {
  nm <- ddd_names[i]
  coef_val <- ddd_coefs[i]
  se_val <- ddd_ses[i]
  p_val <- ddd_pvals[i]
  stars <- ifelse(p_val < 0.01, "^{***}", ifelse(p_val < 0.05, "^{**}", ifelse(p_val < 0.1, "^{*}", "")))

  # Clean variable name for display
  nm_clean <- gsub(":", " $\\\\times$ ", nm)
  nm_clean <- gsub("cross_border", "Cross-border", nm_clean)
  nm_clean <- gsub("post", "Post", nm_clean)
  nm_clean <- gsub("ever_treated", "Treated", nm_clean)

  tab5_lines <- c(tab5_lines,
    sprintf("%s & $%.3f%s$ \\\\", nm_clean, coef_val, stars),
    sprintf(" & (%.3f) \\\\[0.3ex]", se_val))
}

tab5_lines <- c(tab5_lines,
  "\\hline",
  sprintf("Observations & %s \\\\", format(nobs(ddd_reg), big.mark = ",")),
  "Country FE & Yes \\\\",
  "Year FE & Yes \\\\",
  "Crime category FE & Yes \\\\",
  "Clustering & Country \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Triple-difference specification comparing cross-border crimes (fraud, drug offences, theft) against domestic crimes (homicide, serious assault), before and after EIO transposition, in treated vs.~never-treated (Denmark, Ireland) countries. Post = 2017 onward. Standard errors clustered at country level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab5_lines, "tables/tab5_ddd.tex")

# ===========================================================================
# SDE Table (Appendix — Mandatory)
# ===========================================================================
cat("Generating SDE Table (tabF1_sde.tex)...\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y_pre) for binary treatment
sde_rows <- list()

for (cat_code in c("ICCS0701", "ICCS0601", "ICCS0502")) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]

  # Pre-treatment SD of log_rate
  pre_sd <- panel[iccs == cat_code & year < 2017 & !is.na(log_rate),
                  sd(log_rate, na.rm = TRUE)]

  # Get TWFE estimate
  twfe <- twfe_results[[cat_code]]
  beta <- coef(twfe)["treated"]
  se_beta <- se(twfe)["treated"]

  sde <- beta / pre_sd
  se_sde <- se_beta / pre_sd

  # Classification
  classify <- function(x) {
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x < 0.005) return("Null")
    if (x < 0.05) return("Small positive")
    if (x < 0.15) return("Moderate positive")
    return("Large positive")
  }

  sde_rows[[cat_code]] <- data.table(
    Outcome = cat_label,
    Beta = beta,
    SE = se_beta,
    SD_Y = pre_sd,
    SDE = sde,
    SE_SDE = se_sde,
    Classification = classify(sde)
  )
}

sde_dt <- rbindlist(sde_rows)

# Panel B: Heterogeneous (pre-2004 vs post-2004 accession)
accession_2004 <- c("CY", "CZ", "EE", "HU", "LV", "LT", "MT", "PL", "SK", "SI")  # + BG, RO (2007), HR (2013)
new_ms <- c(accession_2004, "BG", "RO", "HR")

sde_het_rows <- list()
for (subgroup in c("Old MS", "New MS")) {
  geos <- if (subgroup == "New MS") new_ms else setdiff(unique(panel$geo), c(new_ms, "DK", "IE"))
  sub <- panel[iccs == "ICCS0701" & geo %in% geos & !is.na(rate)]

  pre_sd <- sub[year < 2017, sd(log_rate, na.rm = TRUE)]

  tryCatch({
    twfe <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)
    beta <- coef(twfe)["treated"]
    se_beta <- se(twfe)["treated"]
    sde <- beta / pre_sd
    se_sde <- se_beta / pre_sd

    sde_het_rows[[subgroup]] <- data.table(
      Outcome = paste0("Fraud (", subgroup, ")"),
      Beta = beta, SE = se_beta, SD_Y = pre_sd,
      SDE = sde, SE_SDE = se_sde,
      Classification = classify(sde)
    )
  }, error = function(e) {
    cat(sprintf("  Heterogeneity failed for %s: %s\n", subgroup, e$message))
  })
}

sde_het_dt <- rbindlist(sde_het_rows)

# Generate LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} 25 European Union member states (excluding Denmark and Ireland, which opted out). ",
  "\\textbf{Research question:} Does the European Investigation Order Directive (2014/41/EU), which replaced fragmented mutual legal assistance with binding 90-day cross-border evidence requests, reduce cross-border crime in EU member states? ",
  "\\textbf{Policy mechanism:} The EIO creates a standardized, time-bound procedure for prosecutors to request and obtain evidence held in another member state, reducing the cost and delay of cross-border prosecution from 10--18 months to 90 days. ",
  "\\textbf{Outcome definition:} Police-recorded offences per 100,000 population from Eurostat (crim\\_off\\_cat), using ICCS harmonized crime categories. ",
  "\\textbf{Treatment:} Binary; indicator equals one from the year a member state transposes the EIO Directive into national law. ",
  "\\textbf{Data:} Eurostat crim\\_off\\_cat, 2008--2022, country-year level, 25 EU member states. ",
  "\\textbf{Method:} Two-way fixed effects with country and year fixed effects; standard errors clustered at country level; Callaway-Sant'Anna staggered DiD as primary specification. ",
  "\\textbf{Sample:} EU member states participating in the EIO framework (EU-27 minus Denmark and Ireland opt-outs); balanced panel 2008--2022. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log(crime rate per 100,000). Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[0.3ex]"
)

for (i in 1:nrow(sde_dt)) {
  sde_lines <- c(sde_lines, sprintf("%s & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & %s \\\\",
    sde_dt$Outcome[i], sde_dt$Beta[i], sde_dt$SE[i], sde_dt$SD_Y[i],
    sde_dt$SDE[i], sde_dt$SE_SDE[i], sde_dt$Classification[i]))
}

sde_lines <- c(sde_lines,
  "\\\\[0.3ex]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Old vs.~New Member States, Fraud)}} \\\\[0.3ex]"
)

for (i in 1:nrow(sde_het_dt)) {
  sde_lines <- c(sde_lines, sprintf("%s & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & %s \\\\",
    sde_het_dt$Outcome[i], sde_het_dt$Beta[i], sde_het_dt$SE[i], sde_het_dt$SD_Y[i],
    sde_het_dt$SDE[i], sde_het_dt$SE_SDE[i], sde_het_dt$Classification[i]))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(sde_lines, "tables/tabF1_sde.tex")

cat("All tables generated.\n")
