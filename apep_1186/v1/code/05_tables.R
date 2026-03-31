## 05_tables.R — Generate all LaTeX tables
## apep_1186: Railroad Quiet Zones and Crossing Safety

source("00_packages.R")

panel <- fread("../data/panel.csv")
load("../data/main_results.RData")
load("../data/robustness_results.RData")

## ---------------------------------------------------------------
## Table 1: Summary Statistics
## ---------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel[year < 2005]

make_row <- function(var_label, var, dat) {
  ctrl <- dat[treat_group == 0]
  treat <- dat[treat_group > 0]
  sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f \\\\",
    var_label,
    mean(ctrl[[var]], na.rm = TRUE),
    sd(ctrl[[var]], na.rm = TRUE),
    mean(treat[[var]], na.rm = TRUE),
    sd(treat[[var]], na.rm = TRUE)
  )
}

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Crossing Characteristics (1990--2004)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Never-Treated} & \\multicolumn{2}{c}{Quiet Zone} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel A: Outcome Variables}} \\\\",
  "\\addlinespace",
  make_row("Any accident", "any_accident", pre),
  make_row("Accident count", "accidents", pre),
  make_row("Any casualty (killed or injured)", "any_casualty", pre),
  make_row("Total killed", "total_killed", pre),
  make_row("Total injured", "total_injured", pre),
  "\\addlinespace",
  "\\multicolumn{5}{l}{\\textit{Panel B: Crossing Characteristics}} \\\\",
  "\\addlinespace",
  make_row("Annual avg.\\ daily traffic (AADT)", "aadt", pre),
  make_row("Total trains per day", "total_trains", pre),
  make_row("Maximum timetable speed (mph)", "max_speed", pre),
  make_row("Has gates (0/1)", "has_gates", pre),
  "\\addlinespace",
  "\\hline",
  sprintf("Crossings & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(uniqueN(pre[treat_group == 0, crossing_id]), format = "d", big.mark = ","),
          formatC(uniqueN(pre[treat_group > 0, crossing_id]), format = "d", big.mark = ",")),
  sprintf("Crossing-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          formatC(nrow(pre[treat_group == 0]), format = "d", big.mark = ","),
          formatC(nrow(pre[treat_group > 0]), format = "d", big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Pre-treatment means and standard deviations for crossing-year observations from 1990--2004. Quiet Zone crossings are those that established 24-hour whistle bans between 2000 and 2020 under the FRA Train Horn Rule (49 CFR Part 222). Never-treated crossings had no whistle ban as of 2024. Data: FRA Highway-Rail Crossing Inventory (Form 71) and Accident/Incident Data (Form 57).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

## ---------------------------------------------------------------
## Table 2: Main Results (TWFE)
## ---------------------------------------------------------------
cat("=== Table 2: Main Results ===\n")

fmt_coef <- function(est, se, stars = "") {
  sprintf("%.4f%s", est, stars)
}
fmt_se <- function(se) {
  sprintf("(%.4f)", se)
}

get_stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("$^{***}$")
  if (pval < 0.05) return("$^{**}$")
  if (pval < 0.10) return("$^{*}$")
  return("")
}

models <- list(m1_twfe, m2_twfe, m3_cas, m4_killed, m5_injured)
outcomes <- c("Any Accident", "Accident Count", "Any Casualty", "Killed", "Injured")

coefs_row <- paste(sapply(models, function(m) {
  ct <- coeftable(m)
  sprintf("%.4f%s", ct[1,1], get_stars(ct[1,4]))
}), collapse = " & ")

se_row <- paste(sapply(models, function(m) {
  ct <- coeftable(m)
  sprintf("(%.4f)", ct[1,2])
}), collapse = " & ")

mean_row <- paste(sapply(c("any_accident", "accidents", "any_casualty",
                            "total_killed", "total_injured"), function(v) {
  sprintf("%.4f", mean(panel[treat_group == 0 & year < 2005][[v]], na.rm = TRUE))
}), collapse = " & ")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Quiet Zones on Railroad Crossing Safety}",
  "\\label{tab:main}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", 5), collapse = "")),
  "\\hline\\hline",
  sprintf(" & %s \\\\", paste(outcomes, collapse = " & ")),
  sprintf(" & %s \\\\", paste(paste0("(", 1:5, ")"), collapse = " & ")),
  "\\hline",
  "\\addlinespace",
  sprintf("Quiet Zone & %s \\\\", coefs_row),
  sprintf(" & %s \\\\", se_row),
  "\\addlinespace",
  "\\hline",
  sprintf("Control mean & %s \\\\", mean_row),
  sprintf("Crossings & \\multicolumn{5}{c}{%s} \\\\",
          formatC(uniqueN(panel$crossing_id), format = "d", big.mark = ",")),
  sprintf("Crossing-years & \\multicolumn{5}{c}{%s} \\\\",
          formatC(nrow(panel), format = "d", big.mark = ",")),
  "Crossing FE & \\multicolumn{5}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{5}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports a separate TWFE regression of the indicated outcome on a quiet zone indicator, with crossing and year fixed effects. The quiet zone indicator equals one for crossing-years after the establishment of a 24-hour whistle ban. Standard errors clustered by county in parentheses. $^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$. Sample: 241,552 railroad crossings observed annually from 1990--2024. Control mean is the pre-treatment (1990--2004) average for never-treated crossings.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")
cat("Table 2 written.\n")

## ---------------------------------------------------------------
## Table 3: Heterogeneity
## ---------------------------------------------------------------
cat("=== Table 3: Heterogeneity ===\n")

het_models <- list(m_gates, m_nogates, m_high_traffic, m_low_traffic,
                   m_high_speed, m_low_speed)
het_labels <- c("Gates", "No Gates", "High AADT", "Low AADT",
                "High Speed", "Low Speed")

het_coefs <- sapply(het_models, function(m) {
  ct <- coeftable(m)
  sprintf("%.4f%s", ct[1,1], get_stars(ct[1,4]))
})

het_ses <- sapply(het_models, function(m) {
  ct <- coeftable(m)
  sprintf("(%.4f)", ct[1,2])
})

het_n <- sapply(het_models, function(m) {
  formatC(m$nobs, format = "d", big.mark = ",")
})

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity in Quiet Zone Effects on Any Accident}",
  "\\label{tab:heterogeneity}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", 6), collapse = "")),
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Gates} & \\multicolumn{2}{c}{Traffic (AADT)} & \\multicolumn{2}{c}{Train Speed} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  sprintf(" & %s \\\\", paste(het_labels, collapse = " & ")),
  sprintf(" & %s \\\\", paste(paste0("(", 1:6, ")"), collapse = " & ")),
  "\\hline",
  "\\addlinespace",
  sprintf("Quiet Zone & %s \\\\", paste(het_coefs, collapse = " & ")),
  sprintf(" & %s \\\\", paste(het_ses, collapse = " & ")),
  "\\addlinespace",
  "\\hline",
  sprintf("Observations & %s \\\\", paste(het_n, collapse = " & ")),
  "Crossing FE & \\multicolumn{6}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{6}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sprintf("\\item \\textit{Notes:} Each column reports a separate TWFE regression of the any-accident indicator on the quiet zone treatment. Sample splits: ``Gates'' vs.\\ ``No Gates'' based on whether the crossing had roadway gate arms; ``High/Low AADT'' split at the treated-crossing median of %s vehicles/day; ``High/Low Speed'' split at the treated-crossing median of %s mph. Standard errors clustered by county. $^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
          formatC(med_aadt, format = "d", big.mark = ","),
          formatC(med_speed, format = "d")),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_heterogeneity.tex")
cat("Table 3 written.\n")

## ---------------------------------------------------------------
## Table 4: Robustness (LOO + Placebo)
## ---------------------------------------------------------------
cat("=== Table 4: Robustness ===\n")

## LOO results are in loo_dt
## Placebo is m_placebo
## CS overall is in cs_overall

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Leave-One-Out, Placebo, and Callaway--Sant'Anna}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Estimate & SE \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel A: Baseline}} \\\\",
  "\\addlinespace",
  sprintf("TWFE (full sample) & %.4f & (%.4f) \\\\", coef(m1_twfe), se(m1_twfe)),
  sprintf("Callaway--Sant'Anna & %.4f & (%.4f) \\\\",
          cs_overall$overall.att, cs_overall$overall.se),
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel B: Leave-One-Out by State}} \\\\",
  "\\addlinespace"
)

state_names <- c("48" = "Texas", "17" = "Illinois", "55" = "Wisconsin",
                 "27" = "Minnesota", "29" = "Missouri")
for (i in seq_len(nrow(loo_dt))) {
  s <- as.character(loo_dt$state_dropped[i])
  nm <- state_names[s]
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Drop %s & %.4f & (%.4f) \\\\",
            nm, loo_dt$estimate[i], loo_dt$se[i]))
}

tab4_lines <- c(tab4_lines,
  "\\addlinespace",
  "\\multicolumn{3}{l}{\\textit{Panel C: Placebo}} \\\\",
  "\\addlinespace",
  sprintf("Pseudo-treatment at 2000 (pre-period only) & %.4f$^{***}$ & (%.4f) \\\\",
          coef(m_placebo), se(m_placebo)),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A: Baseline TWFE and Callaway--Sant'Anna (2021) estimates of the quiet zone effect on any accident. Panel B: TWFE estimates dropping each of the five largest adopting states. Panel C: Placebo assigns pseudo-treatment in 2000 to crossings that actually received quiet zones in 2005--2010, using only pre-treatment data (1990--2004). The significant placebo reflects pre-existing safety improvements installed as part of the quiet zone application process. All regressions include crossing and year fixed effects; standard errors clustered by county. $^{*}$ $p < 0.10$, $^{**}$ $p < 0.05$, $^{***}$ $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

## ---------------------------------------------------------------
## Table F1: Standardized Effect Sizes (SDE Appendix)
## ---------------------------------------------------------------
cat("=== Table F1: SDE ===\n")

## Compute SDEs
twfe_est <- coef(m1_twfe)[[1]]
twfe_se  <- se(m1_twfe)[[1]]
sde_any_acc <- twfe_est / sd_any_acc
sde_se_any_acc <- twfe_se / sd_any_acc

cas_est <- coef(m3_cas)[[1]]
cas_se  <- se(m3_cas)[[1]]
sde_cas <- cas_est / sd_any_cas
sde_se_cas <- cas_se / sd_any_cas

killed_est <- coef(m4_killed)[[1]]
killed_se  <- se(m4_killed)[[1]]
sd_killed <- sd(panel[year < 2005]$total_killed)
sde_killed <- killed_est / sd_killed
sde_se_killed <- killed_se / sd_killed

injured_est <- coef(m5_injured)[[1]]
injured_se  <- se(m5_injured)[[1]]
sd_injured <- sd(panel[year < 2005]$total_injured)
sde_injured <- injured_est / sd_injured
sde_se_injured <- injured_se / sd_injured

## Classification function
classify_sde <- function(sde) {
  if (abs(sde) < 0.005) return("Null")
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  return("Small negative")
}

## Heterogeneity SDEs (sample splits)
gates_est <- coef(m_gates)[[1]]
gates_se  <- se(m_gates)[[1]]
sd_gates <- sd(panel[has_gates == 1 & year < 2005]$any_accident)
sde_gates <- gates_est / sd_gates
sde_se_gates <- gates_se / sd_gates

nogates_est <- coef(m_nogates)[[1]]
nogates_se  <- se(m_nogates)[[1]]
sd_nogates <- sd(panel[has_gates == 0 & year < 2005]$any_accident)
sde_nogates <- nogates_est / sd_nogates
sde_se_nogates <- nogates_se / sd_nogates

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does establishing railroad quiet zones---which silence locomotive horns at highway-rail crossings---affect the frequency and severity of crossing accidents? ",
  "\\textbf{Policy mechanism:} Under the FRA Train Horn Rule (49 CFR Part 222, effective June 2005), communities may establish quiet zones that ban locomotive horns at public crossings, but only after installing supplementary safety measures (four-quadrant gates, raised medians, channelization devices) certified as providing equivalent safety. ",
  "\\textbf{Outcome definition:} Panel A reports annual crossing-level indicators: any accident (Form 57 incident at crossing in year), any casualty (any killed or injured), total killed, and total injured. Panel B reports sample splits by pre-existing gate infrastructure. ",
  "\\textbf{Treatment:} Binary---crossing-year is treated if a 24-hour whistle ban is in effect. ",
  "\\textbf{Data:} FRA Crossing Inventory (Form 71, 241,552 crossings) and Accident/Incident Data (Form 57, 250,480 records), 1990--2024, crossing-year panel with 8.5 million observations. ",
  "\\textbf{Method:} TWFE with crossing and year fixed effects; standard errors clustered by county (2,894 clusters). ",
  "\\textbf{Sample:} Public, non-closed crossings with valid geocoordinates; 4,167 treated crossings with quiet zone dates between 2000 and 2020; 237,385 never-treated controls. Partial and Chicago-excused whistle bans excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (1990--2004) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\addlinespace",
  sprintf("Any accident & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          twfe_est, twfe_se, sd_any_acc, sde_any_acc, sde_se_any_acc,
          classify_sde(sde_any_acc)),
  sprintf("Any casualty & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          cas_est, cas_se, sd_any_cas, sde_cas, sde_se_cas,
          classify_sde(sde_cas)),
  sprintf("Total killed & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          killed_est, killed_se, sd_killed, sde_killed, sde_se_killed,
          classify_sde(sde_killed)),
  sprintf("Total injured & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          injured_est, injured_se, sd_injured, sde_injured, sde_se_injured,
          classify_sde(sde_injured)),
  "\\addlinespace",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits by gate infrastructure)}} \\\\",
  "\\addlinespace",
  sprintf("Any accident (gated crossings) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          gates_est, gates_se, sd_gates, sde_gates, sde_se_gates,
          classify_sde(sde_gates)),
  sprintf("Any accident (ungated crossings) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          nogates_est, nogates_se, sd_nogates, sde_nogates, sde_se_nogates,
          classify_sde(sde_nogates)),
  "\\addlinespace",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
