## 05_tables.R — Generate all LaTeX tables
## apep_0616: Police Austerity and Criminal Justice Quality

suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
})

data_dir <- "data"
tab_dir <- "tables"
dir.create(tab_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
robust <- readRDS(file.path(data_dir, "robustness_models.rds"))
offgroup <- readRDS(file.path(data_dir, "offgroup_outcomes.rds"))
officers <- readRDS(file.path(data_dir, "officers_panel.rds"))

main <- panel |>
  filter(year >= 2014, year <= 2021) |>
  mutate(charge_rate_pct = charge_rate * 100)

std_force <- function(x) str_trim(str_to_lower(x))

# Helper: format coefficient with stars
fmt_coef <- function(b, p) {
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  sprintf("%.3f%s", b, stars)
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1 ===\n")

terciles <- main |>
  filter(year == 2015) |>
  group_by(officer_cut_tercile) |>
  summarise(n = n(), cut = mean(pct_officer_cut), off = mean(officers_fte),
            cr = mean(charge_rate_pct), .groups = "drop")

tab1 <- paste0(
"\\begin{table}[ht]
\\centering
\\caption{Summary Statistics: Police Force Areas in England and Wales}
\\label{tab:sumstats}
\\begin{tabular}{lcccc}
\\hline\\hline
 & All & Large Cuts & Medium Cuts & Small Cuts \\\\
\\hline
Forces & 42 & ", terciles$n[1], " & ", terciles$n[2], " & ", terciles$n[3], " \\\\
Officer cut 2010--15 (\\%) & ", sprintf("%.1f", mean(main$pct_officer_cut)),
" & ", sprintf("%.1f", terciles$cut[1]),
" & ", sprintf("%.1f", terciles$cut[2]),
" & ", sprintf("%.1f", terciles$cut[3]), " \\\\
Mean officer FTE & ", sprintf("%.0f", mean(main$officers_fte)),
" & ", sprintf("%.0f", terciles$off[1]),
" & ", sprintf("%.0f", terciles$off[2]),
" & ", sprintf("%.0f", terciles$off[3]), " \\\\
Mean charge rate (\\%) & ", sprintf("%.1f", mean(main$charge_rate_pct)),
" & ", sprintf("%.1f", terciles$cr[1]),
" & ", sprintf("%.1f", terciles$cr[2]),
" & ", sprintf("%.1f", terciles$cr[3]), " \\\\
Mean recorded outcomes & ", sprintf("%.0f", mean(main$total_outcomes)),
" & & & \\\\
Years & \\multicolumn{4}{c}{2014--2021} \\\\
Observations & \\multicolumn{4}{c}{", nrow(main), "} \\\\
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.92\\textwidth}
\\vspace{3pt}
\\small\\textit{Notes:} Panel of 42 police force areas in England and Wales, 2014--2021. Terciles defined by the percentage change in officer FTE between March 2010 and March 2015. Large cuts: $>$15.6\\% reduction; medium cuts: 10.2--14.9\\%; small cuts: $<$10.2\\%. Charge rate is the share of recorded crime outcomes resulting in a charge or summons under the Home Office outcomes framework. Source: Home Office Police Workforce and Crime Outcomes open data.
\\end{minipage}
\\end{table}
")

writeLines(tab1, file.path(tab_dir, "tab1_sumstats.tex"))

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("=== Table 2 ===\n")

m1 <- feols(charge_rate_pct ~ log(officers_fte) | force_name + year,
            data = main, cluster = ~force_name)
m2 <- feols(charge_rate_pct ~ log(officers_fte) + log(total_outcomes) | force_name + year,
            data = main, cluster = ~force_name)
m3 <- feols(charge_rate_pct ~ log(officers_fte) | force_name + region^year,
            data = main, cluster = ~force_name)

extended <- panel |> filter(year >= 2007, year <= 2021, charged > 0) |>
  mutate(log_charges = log(charged))
m4 <- feols(log_charges ~ log(officers_fte) | force_name + year,
            data = extended, cluster = ~force_name)

tab2 <- paste0(
"\\begin{table}[ht]
\\centering
\\caption{Police Officers and Criminal Justice Outcomes}
\\label{tab:main}
\\begin{tabular}{lcccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) \\\\
 & Charge rate & Charge rate & Charge rate & log(Charges) \\\\
\\hline
log(Officer FTE) & ", fmt_coef(coef(m1), pvalue(m1)),
" & ", fmt_coef(coef(m2)[1], pvalue(m2)[1]),
" & ", fmt_coef(coef(m3), pvalue(m3)),
" & ", fmt_coef(coef(m4), pvalue(m4)), " \\\\
 & (", sprintf("%.3f", se(m1)), ")",
" & (", sprintf("%.3f", se(m2)[1]), ")",
" & (", sprintf("%.3f", se(m3)), ")",
" & (", sprintf("%.3f", se(m4)), ") \\\\[6pt]
log(Recorded outcomes) & & ", fmt_coef(coef(m2)[2], pvalue(m2)[2]), " & & \\\\
 & & (", sprintf("%.3f", se(m2)[2]), ") & & \\\\[6pt]
\\hline
Force FE & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & & Yes \\\\
Region $\\times$ Year FE & & & Yes & \\\\
Panel & 2014--21 & 2014--21 & 2014--21 & 2007--21 \\\\
Observations & ", nobs(m1), " & ", nobs(m2), " & ", nobs(m3), " & ", nobs(m4), " \\\\
Within $R^2$ & ", sprintf("%.3f", fitstat(m1, 'wr2')$wr2),
" & ", sprintf("%.3f", fitstat(m2, 'wr2')$wr2),
" & ", sprintf("%.3f", fitstat(m3, 'wr2')$wr2),
" & ", sprintf("%.3f", fitstat(m4, 'wr2')$wr2), " \\\\
\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.92\\textwidth}
\\vspace{3pt}
\\small\\textit{Notes:} Standard errors clustered by police force area in parentheses. Columns (1)--(3): dependent variable is charge rate (\\%), the share of recorded outcomes resulting in a charge or summons. Column (4): dependent variable is the natural log of total charges/summonses, using the extended panel covering both the historical detection framework and the current outcomes framework. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{minipage}
\\end{table}
")

writeLines(tab2, file.path(tab_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Offense Group Heterogeneity
# ============================================================================
cat("=== Table 3 ===\n")

og_panel <- offgroup |>
  mutate(force_std = std_force(force_name), year = fy_start) |>
  inner_join(officers |> mutate(force_std = std_force(force_name)),
             by = c("force_std", "year")) |>
  filter(year >= 2014, year <= 2021, total_outcomes > 100) |>
  mutate(charge_rate_pct = charge_rate * 100)

groups <- c("Sexual offences", "Violence against the person", "Robbery",
            "Public order offences", "Theft offences", "Criminal damage and arson",
            "Drug offences", "Possession of weapons offences")

labels <- c("Sexual offences", "Violence against the person", "Robbery",
            "Public order offences", "Theft offences", "Criminal damage \\& arson",
            "Drug offences", "Weapons possession")

categories <- c("Investigation", "Investigation", "Investigation",
                "Investigation", "Volume", "Volume",
                "Proactive", "Proactive")

tab3_body <- ""
prev_cat <- ""
for (i in seq_along(groups)) {
  sub <- og_panel |> filter(offence_group == groups[i])
  m <- feols(charge_rate_pct ~ log(officers_fte) | force_name.x + year,
             data = sub, cluster = ~force_name.x)
  mcr <- mean(sub$charge_rate_pct, na.rm = TRUE)

  if (categories[i] != prev_cat) {
    cat_label <- switch(categories[i],
      "Investigation" = "\\textit{Investigation-intensive}",
      "Volume" = "\\textit{Volume crime}",
      "Proactive" = "\\textit{Proactive policing}")
    tab3_body <- paste0(tab3_body, cat_label, " & & & & \\\\\n")
    prev_cat <- categories[i]
  }

  tab3_body <- paste0(tab3_body, sprintf(
    "\\quad %s & %.1f & %s & (%.2f) & %d \\\\\n",
    labels[i], mcr, fmt_coef(coef(m), pvalue(m)), se(m), nobs(m)
  ))
}

tab3 <- paste0(
"\\begin{table}[ht]
\\centering
\\caption{Officer Reductions and Charge Rates by Offense Type}
\\label{tab:heterogeneity}
\\begin{tabular}{lcccc}
\\hline\\hline
Offense group & Mean rate (\\%) & $\\hat{\\beta}$ & SE & N \\\\
\\hline
", tab3_body,
"\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.92\\textwidth}
\\vspace{3pt}
\\small\\textit{Notes:} Each row reports a separate regression of charge rate (\\%) on log officer FTE with force and year fixed effects. Standard errors clustered by force in parentheses. $\\hat{\\beta}$ is the estimated percentage point change in the charge rate for a 1\\% increase in officers. Investigation-intensive crimes require sustained detective work; volume crimes are reported by the public; proactive policing crimes are detected through officer-initiated activity. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{minipage}
\\end{table}
")

writeLines(tab3, file.path(tab_dir, "tab3_heterogeneity.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Table 4 ===\n")

specs <- list(
  list("Baseline", m1),
  list("Excl.\\ Metropolitan Police", robust$r1),
  list("Excl.\\ all London forces", robust$r2),
  list("Excl.\\ 2020 (COVID)", robust$r3),
  list("Region $\\times$ year FE", robust$r4),
  list("Headcount (not FTE)", robust$r5),
  list("Control: log(crimes)", robust$r7)
)

tab4_body <- ""
for (s in specs) {
  b <- coef(s[[2]])[1]; p <- pvalue(s[[2]])[1]; se_val <- se(s[[2]])[1]
  tab4_body <- paste0(tab4_body, sprintf(
    "%s & %s & (%.3f) & %d \\\\\n",
    s[[1]], fmt_coef(b, p), se_val, nobs(s[[2]])
  ))
}

tab4 <- paste0(
"\\begin{table}[ht]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{tabular}{lccc}
\\hline\\hline
Specification & $\\hat{\\beta}$ & SE & N \\\\
\\hline
", tab4_body,
"\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.92\\textwidth}
\\vspace{3pt}
\\small\\textit{Notes:} Dependent variable is charge rate (\\%) in all specifications. All include force and year fixed effects unless noted. Standard errors clustered by force area in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{minipage}
\\end{table}
")

writeLines(tab4, file.path(tab_dir, "tab4_robustness.tex"))

# ============================================================================
# Table F1: SDE
# ============================================================================
cat("=== Table F1: SDE ===\n")

main2 <- main |> mutate(log_off = log(officers_fte))
sd_x <- sd(main2$log_off); sd_y <- sd(main2$charge_rate_pct)

ext2 <- extended |> mutate(log_off = log(officers_fte))
sd_x_ext <- sd(ext2$log_off); sd_y_ext <- sd(ext2$log_charges)

classify_sde <- function(s) {
  if (s > 0.15) "Large positive" else if (s > 0.05) "Moderate positive"
  else if (s > 0.005) "Small positive" else if (s > -0.005) "Null"
  else if (s > -0.05) "Small negative" else if (s > -0.15) "Moderate negative"
  else "Large negative"
}

sde_data <- list()

# Row 1: charge rate
b <- coef(m1); s <- se(m1)
sde_data[[1]] <- c("Charge rate (\\%)", b, s, sd_y, b*sd_x/sd_y, s*sd_x/sd_y, classify_sde(b*sd_x/sd_y))

# Row 2: log charges
b <- coef(m4); s <- se(m4)
sde_data[[2]] <- c("log(Charges)", b, s, sd_y_ext, b*sd_x_ext/sd_y_ext, s*sd_x_ext/sd_y_ext, classify_sde(b*sd_x_ext/sd_y_ext))

# Offense groups
for (g in c("Violence against the person", "Sexual offences", "Theft offences", "Drug offences")) {
  sub <- og_panel |> filter(offence_group == g) |> mutate(log_off = log(officers_fte))
  m <- feols(charge_rate_pct ~ log(officers_fte) | force_name.x + year,
             data = sub, cluster = ~force_name.x)
  b <- coef(m); s <- se(m)
  sd_yg <- sd(sub$charge_rate_pct, na.rm = TRUE)
  sd_xg <- sd(sub$log_off)
  short <- gsub(" against the person", "", g)
  sde_data[[length(sde_data)+1]] <- c(paste0("Charge rate: ", tolower(short)),
    b, s, sd_yg, b*sd_xg/sd_yg, s*sd_xg/sd_yg, classify_sde(b*sd_xg/sd_yg))
}

sde_body <- ""
for (row in sde_data) {
  sde_body <- paste0(sde_body, sprintf(
    "%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
    row[1], as.numeric(row[2]), as.numeric(row[3]), as.numeric(row[4]),
    as.numeric(row[5]), as.numeric(row[6]), row[7]
  ))
}

tabF1 <- paste0(
"\\begin{table}[ht]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
", sde_body,
"\\hline\\hline
\\end{tabular}
\\begin{minipage}{0.95\\textwidth}
\\vspace{3pt}
\\small\\textit{Notes:} This paper estimates the effect of police officer reductions on criminal justice quality in England and Wales, 2014--2021. Treatment: within-force variation in log officer FTE (continuous). Method: two-way fixed effects with force and year FE, clustered SEs. SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment. N = 334 force-years (main); N = 628 (extended, row 2). Classification refers to magnitude of the point estimate, not statistical significance. Source: Home Office open data.
\\end{minipage}
\\end{table}
")

writeLines(tabF1, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables saved:\n")
for (f in list.files(tab_dir)) cat("  ", f, "\n")
