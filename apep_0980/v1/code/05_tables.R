# =============================================================================
# 05_tables.R — Generate LaTeX tables
# apep_0980: IRA Energy Community Bonus Credit and County-Level Labor Markets
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"

# Load results
panel <- arrow::read_parquet(file.path(DATA_DIR, "analysis_panel.parquet"))
setDT(panel)
panel[, time_idx := (year - 2018) * 4 + quarter]
main_sample <- panel[cohort != "no_unemp_data"]
treat <- fread(file.path(DATA_DIR, "treatment_assignment.csv"))

load(file.path(DATA_DIR, "main_results.RData"))
cs_loaded <- tryCatch(load(file.path(DATA_DIR, "cs_results.RData")), error = function(e) NULL)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

# Panel A: County characteristics by treatment status
summ_list <- list()
for (grp in c("Treated", "Never-Treated (FF)", "Never-Treated (Non-FF)")) {
  if (grp == "Treated") {
    sub <- main_sample[cohort %in% c("always_treated", "treated_2023_only", "treated_2024_only")]
  } else if (grp == "Never-Treated (FF)") {
    sub <- main_sample[cohort == "never_treated_ff"]
  } else {
    sub <- main_sample[cohort == "never_treated"]
  }

  # Pre-treatment period only (2018-2022)
  pre <- sub[year <= 2022]

  for (s in c("23", "22", "21")) {
    sname <- c("23" = "Construction", "22" = "Utilities", "21" = "Mining")[[s]]
    sec <- pre[industry == s]
    summ_list[[paste(grp, sname)]] <- data.table(
      Group = grp,
      Sector = sname,
      Counties = uniqueN(sec$county_fips),
      Mean_Emp = mean(sec$Emp, na.rm = TRUE),
      SD_Emp = sd(sec$Emp, na.rm = TRUE),
      Mean_Earn = mean(sec$EarnS, na.rm = TRUE),
      Obs = nrow(sec)
    )
  }
}

summ_dt <- rbindlist(summ_list)
cat("Summary statistics:\n")
print(summ_dt)

# Write LaTeX table 1
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics: Pre-Treatment Employment by Sector and Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llrrrr}",
  "\\toprule",
  "Group & Sector & Counties & Mean Emp. & SD Emp. & Mean Earnings \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(summ_dt))) {
  r <- summ_dt[i]
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %d & %s & %s & \\$%s \\\\",
    r$Group, r$Sector, r$Counties,
    format(round(r$Mean_Emp, 0), big.mark = ","),
    format(round(r$SD_Emp, 0), big.mark = ","),
    format(round(r$Mean_Earn, 0), big.mark = ",")
  ))
  if (i %% 3 == 0 && i < nrow(summ_dt)) tab1_lines <- c(tab1_lines, "\\addlinespace")
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Pre-treatment period (2018Q1--2022Q4). Treated counties meet both the fossil fuel employment threshold ($\\geq 0.17\\%$) and the unemployment criterion ($\\geq$ national average). FF controls meet the employment threshold only. Employment is beginning-of-quarter count; earnings are average monthly earnings (\\$). Source: QWI (LEHD), BLS LAUS, FRED.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# =============================================================================
# Table 2: Main TWFE Results (all sectors)
# =============================================================================
cat("\n=== Table 2: Main Results ===\n")

sectors <- c("23", "22", "21", "31-33", "44-45", "72")
sector_labels <- c("Construction", "Utilities", "Mining",
                    "Manufacturing", "Retail", "Accommodation")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Effect of Energy Community Designation on Sector Employment}",
  "\\label{tab:main}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  paste0(" & ", paste(sector_labels, collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%d)", 1:6), collapse = " & "), " \\\\"),
  "\\midrule"
)

# Employment results
betas <- sapply(sectors, function(s) {
  if (!is.null(twfe_results[[s]])) round(coef(twfe_results[[s]])["treated"], 4) else NA
})
ses <- sapply(sectors, function(s) {
  if (!is.null(twfe_results[[s]])) round(se(twfe_results[[s]])["treated"], 4) else NA
})
stars <- sapply(sectors, function(s) {
  if (!is.null(twfe_results[[s]])) {
    p <- pvalue(twfe_results[[s]])["treated"]
    if (p < 0.01) return("***")
    if (p < 0.05) return("**")
    if (p < 0.1) return("*")
  }
  return("")
})

tab2_lines <- c(tab2_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Log Employment}} \\\\",
  "\\addlinespace",
  paste0("Treated & ",
    paste(sprintf("%0.4f%s", betas, stars), collapse = " & "), " \\\\"),
  paste0(" & ",
    paste(sprintf("(%0.4f)", ses), collapse = " & "), " \\\\")
)

# Earnings results
betas_e <- sapply(sectors, function(s) {
  if (!is.null(twfe_earn[[s]])) round(coef(twfe_earn[[s]])["treated"], 4) else NA
})
ses_e <- sapply(sectors, function(s) {
  if (!is.null(twfe_earn[[s]])) round(se(twfe_earn[[s]])["treated"], 4) else NA
})
stars_e <- sapply(sectors, function(s) {
  if (!is.null(twfe_earn[[s]])) {
    p <- pvalue(twfe_earn[[s]])["treated"]
    if (p < 0.01) return("***")
    if (p < 0.05) return("**")
    if (p < 0.1) return("*")
    return("")
  }
  return("")
})

tab2_lines <- c(tab2_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Log Earnings}} \\\\",
  "\\addlinespace",
  paste0("Treated & ",
    paste(sprintf("%0.4f%s", betas_e, stars_e), collapse = " & "), " \\\\"),
  paste0(" & ",
    paste(sprintf("(%0.4f)", ses_e), collapse = " & "), " \\\\")
)

# Observation counts
ns <- sapply(sectors, function(s) {
  if (!is.null(twfe_results[[s]])) format(twfe_results[[s]]$nobs, big.mark = ",") else "---"
})

tab2_lines <- c(tab2_lines,
  "\\addlinespace", "\\midrule",
  paste0("Observations & ", paste(ns, collapse = " & "), " \\\\"),
  "County FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Clustering & \\multicolumn{6}{c}{State} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Difference-in-differences estimates of energy community designation on log sector employment (Panel A) and log average monthly earnings (Panel B). Treatment defined as county meeting both the fossil fuel employment share ($\\geq 0.17\\%$, predetermined 2018--2022 average from QWI NAICS 21) and unemployment rate ($\\geq$ national average, from FRED/LAUS) criteria. Treatment begins Q2 2023 (IRS Notice 2023-29). Standard errors clustered at the state level in parentheses. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$. Source: QWI (LEHD) 2018Q1--2025Q1.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(TABLE_DIR, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# =============================================================================
# Table 3: Robustness — Within-FF and Post-COVID
# =============================================================================
cat("\n=== Table 3: Robustness ===\n")

# Re-run the regressions for the table
rob_specs <- list()
for (s in c("23", "21")) {
  sname <- c("23" = "Construction", "21" = "Mining")[[s]]

  # Within-FF
  ff_only <- main_sample[cohort %in% c("always_treated", "treated_2023_only",
                                        "treated_2024_only", "never_treated_ff") &
                          industry == s & !is.na(Emp)]
  rob_specs[[paste0(s, "_ff")]] <- feols(log_emp ~ treated | county_fips + time,
                                          data = ff_only, cluster = ~state_fips)

  # Post-COVID
  post <- main_sample[year >= 2021 & industry == s & !is.na(Emp)]
  rob_specs[[paste0(s, "_post")]] <- feols(log_emp ~ treated | county_fips + time,
                                            data = post, cluster = ~state_fips)
}

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Robustness: Alternative Samples and Control Groups}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Construction} & \\multicolumn{2}{c}{Mining} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & FF-Only & Post-COVID & FF-Only & Post-COVID \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

specs <- c("23_ff", "23_post", "21_ff", "21_post")
b <- sapply(specs, function(x) round(coef(rob_specs[[x]])["treated"], 4))
s <- sapply(specs, function(x) round(se(rob_specs[[x]])["treated"], 4))
st <- sapply(specs, function(x) {
  p <- pvalue(rob_specs[[x]])["treated"]
  if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
})
n <- sapply(specs, function(x) format(rob_specs[[x]]$nobs, big.mark = ","))

tab3_lines <- c(tab3_lines,
  paste0("Treated & ", paste(sprintf("%0.4f%s", b, st), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%0.4f)", s), collapse = " & "), " \\\\"),
  "\\addlinespace", "\\midrule",
  paste0("Observations & ", paste(n, collapse = " & "), " \\\\"),
  "County FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Quarter FE & \\multicolumn{4}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} FF-Only restricts the sample to counties meeting the fossil fuel employment threshold, comparing treated (unemployment $\\geq$ national average) vs.~near-miss controls (unemployment $<$ national average). Post-COVID restricts to 2021Q1--2025Q1. Standard errors clustered at the state level. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(TABLE_DIR, "tab3_robustness.tex"))
cat("  Saved tab3_robustness.tex\n")

# =============================================================================
# Table 4: Callaway-Sant'Anna Event Study
# =============================================================================
cat("\n=== Table 4: CS Dynamic Effects ===\n")

if (!is.null(cs_loaded) && exists("cs_dyn")) {
  tab4_lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\begin{threeparttable}",
    "\\caption{Callaway-Sant'Anna Dynamic Treatment Effects: Construction Employment}",
    "\\label{tab:cs_dynamic}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    "Event Time & ATT & SE \\\\",
    "\\midrule"
  )

  for (j in seq_along(cs_dyn$egt)) {
    e <- cs_dyn$egt[j]
    att <- cs_dyn$att.egt[j]
    se_val <- cs_dyn$se.egt[j]
    star <- ""
    if (!is.na(se_val) && se_val > 0) {
      p <- 2 * pnorm(-abs(att / se_val))
      if (p < 0.01) star <- "***"
      else if (p < 0.05) star <- "**"
      else if (p < 0.1) star <- "*"
    }
    label <- ifelse(e < 0, sprintf("$e = %d$", e), sprintf("$e = +%d$", e))
    if (e == 0) label <- "$e = 0$"
    tab4_lines <- c(tab4_lines,
      sprintf("%s & %0.4f%s & (%0.4f) \\\\", label, att, star, se_val))
    if (e == -1) tab4_lines <- c(tab4_lines, "\\midrule")
  }

  # Simple ATT
  tab4_lines <- c(tab4_lines,
    "\\midrule",
    sprintf("\\textbf{Overall ATT} & \\textbf{%0.4f%s} & \\textbf{(%0.4f)} \\\\",
            cs_simple$overall.att,
            ifelse(abs(cs_simple$overall.att / cs_simple$overall.se) > 1.96, "**",
                   ifelse(abs(cs_simple$overall.att / cs_simple$overall.se) > 1.645, "*", "")),
            cs_simple$overall.se),
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]\\small",
    "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) group-time average treatment effects on the treated, aggregated dynamically. Outcome: log construction employment. Reference period: $e = -1$. Comparison group: not-yet-treated. 255 treated counties, 1,896 never-treated counties. $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\end{table}"
  )

  writeLines(tab4_lines, file.path(TABLE_DIR, "tab4_cs_dynamic.tex"))
  cat("  Saved tab4_cs_dynamic.tex\n")
} else {
  cat("  CS results not available, skipping Table 4\n")
}

# =============================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# =============================================================================
cat("\n=== Table F1: SDE Appendix ===\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y) where SD(Y) is pre-treatment SD

compute_sde <- function(dt, sector, outcome = "log_emp") {
  pre <- dt[industry == sector & year <= 2022 & !is.na(get(outcome))]
  sd_y <- sd(pre[[outcome]], na.rm = TRUE)
  mod <- twfe_results[[sector]]
  if (is.null(mod)) return(NULL)
  beta <- coef(mod)["treated"]
  se_beta <- se(mod)["treated"]
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  # Classification
  classify <- function(x) {
    if (x > 0.15) return("Large positive")
    if (x > 0.05) return("Moderate positive")
    if (x > 0.005) return("Small positive")
    if (x > -0.005) return("Null")
    if (x > -0.05) return("Small negative")
    if (x > -0.15) return("Moderate negative")
    return("Large negative")
  }

  list(beta = beta, se = se_beta, sd_y = sd_y, sde = sde, se_sde = se_sde,
       class = classify(sde))
}

sde_results <- list()
sde_labels <- c("23" = "Construction", "22" = "Utilities", "21" = "Mining",
                "31-33" = "Manufacturing")
for (s in names(sde_labels)) {
  res <- compute_sde(main_sample, s)
  if (!is.null(res)) sde_results[[s]] <- res
}

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the IRA's energy community bonus tax credit (10pp ITC/PTC adder for clean energy projects in fossil-fuel-dependent counties) increase sector-level employment in designated communities? ",
  "\\textbf{Policy mechanism:} The Inflation Reduction Act Section 45(b)(11) provides a 10 percentage point bonus on clean energy investment and production tax credits for projects located in Metropolitan Statistical Areas meeting both a fossil fuel employment share threshold and an unemployment rate threshold, channeling clean energy investment toward economically distressed fossil-fuel-dependent communities. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter employment count from QWI (Quarterly Workforce Indicators) by NAICS sector at the county level. ",
  "\\textbf{Treatment:} Binary; county's MSA meets both fossil fuel employment share $\\geq 0.17\\%$ (predetermined 2018--2022 average) and annual unemployment rate $\\geq$ national average. ",
  "\\textbf{Data:} QWI LEHD via Census Bureau, county $\\times$ quarter $\\times$ NAICS sector, 2018Q1--2025Q1, 2,509 counties, 411,440 sector-county-quarter observations. ",
  "\\textbf{Method:} Two-way fixed effects (county + quarter FE), standard errors clustered at state level; robustness via Callaway-Sant'Anna (2021). ",
  "\\textbf{Sample:} Counties with non-missing QWI employment data excluding those above the fossil fuel threshold but lacking FRED unemployment data (655 counties excluded). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Panel A: Pooled effects
tab_f1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace"
)

for (s in names(sde_results)) {
  r <- sde_results[[s]]
  tab_f1_lines <- c(tab_f1_lines, sprintf(
    "%s & %0.4f & %0.4f & %0.4f & %0.4f & %0.4f & %s \\\\",
    sde_labels[[s]], r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class
  ))
}

# Panel B: Heterogeneous — FF-only vs full sample
tab_f1_lines <- c(tab_f1_lines,
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Within Fossil Fuel Counties)}} \\\\",
  "\\addlinespace"
)

# FF-only construction
ff_constr <- main_sample[cohort %in% c("always_treated", "treated_2023_only",
                                        "treated_2024_only", "never_treated_ff") &
                          industry == "23" & !is.na(Emp)]
pre_ff <- ff_constr[year <= 2022]
sd_ff <- sd(pre_ff$log_emp, na.rm = TRUE)
mod_ff <- feols(log_emp ~ treated | county_fips + time, data = ff_constr, cluster = ~state_fips)
sde_ff <- coef(mod_ff)["treated"] / sd_ff
se_sde_ff <- se(mod_ff)["treated"] / sd_ff

classify_sde <- function(x) {
  if (x > 0.15) "Large positive"
  else if (x > 0.05) "Moderate positive"
  else if (x > 0.005) "Small positive"
  else if (x > -0.005) "Null"
  else if (x > -0.05) "Small negative"
  else if (x > -0.15) "Moderate negative"
  else "Large negative"
}

tab_f1_lines <- c(tab_f1_lines, sprintf(
  "Construction (FF-only) & %0.4f & %0.4f & %0.4f & %0.4f & %0.4f & %s \\\\",
  coef(mod_ff)["treated"], se(mod_ff)["treated"], sd_ff, sde_ff, se_sde_ff,
  classify_sde(sde_ff)
))

# Post-COVID construction
post_constr <- main_sample[year >= 2021 & industry == "23" & !is.na(Emp)]
pre_post <- post_constr[year <= 2022]
sd_post <- sd(pre_post$log_emp, na.rm = TRUE)
mod_post <- feols(log_emp ~ treated | county_fips + time, data = post_constr, cluster = ~state_fips)
sde_post <- coef(mod_post)["treated"] / sd_post
se_sde_post <- se(mod_post)["treated"] / sd_post

tab_f1_lines <- c(tab_f1_lines, sprintf(
  "Construction (Post-2020) & %0.4f & %0.4f & %0.4f & %0.4f & %0.4f & %s \\\\",
  coef(mod_post)["treated"], se(mod_post)["treated"], sd_post, sde_post, se_sde_post,
  classify_sde(sde_post)
))

tab_f1_lines <- c(tab_f1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab_f1_lines, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
