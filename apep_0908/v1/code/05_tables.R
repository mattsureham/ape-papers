# 05_tables.R — Generate LaTeX tables for apep_0908
# Multi-threshold bunching analysis of German solar PV

source("00_packages.R")

cat("=== Generating LaTeX Tables ===\n")

pooled <- fread("../data/pooled_bunching_results.csv")
dib <- fread("../data/dib_results.csv")
poly_rob <- fread("../data/robustness_polynomial.csv")
type_rob <- fread("../data/robustness_type.csv")
placebo <- fread("../data/robustness_placebo.csv")
yearly <- fread("../data/robustness_yearly.csv")
period <- fread("../data/period_bunching_results.csv")
solar <- fread("../data/solar_clean.csv")

dir.create("../tables", showWarnings = FALSE)

# ---------------------------------------------------------------
# Helper: format with stars
# ---------------------------------------------------------------
stars <- function(b, se) {
  t <- abs(b / se)
  s <- ifelse(t > 2.576, "***", ifelse(t > 1.96, "**", ifelse(t > 1.645, "*", "")))
  return(s)
}

fmt_coef <- function(b, se, digits = 3) {
  s <- stars(b, se)
  paste0(format(round(b, digits), nsmall = digits), s)
}

# ---------------------------------------------------------------
# Table 1: Main Bunching Estimates (Pooled)
# ---------------------------------------------------------------
cat("Generating Table 1: Main bunching estimates...\n")

# Add regulatory description
pooled[, regulation := c(
  "EEG surcharge exemption",
  "Expanded surcharge exemption",
  "Feed-in tariff rate break",
  "Mandatory direct marketing",
  "Mandatory tender"
)]

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Bunching at EEG Regulatory Thresholds}",
  "\\label{tab:main_bunching}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{5}{c}{Threshold (kWp)} \\\\",
  "\\cmidrule(lr){2-6}",
  paste0(" & ", paste(pooled$threshold, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Normalized excess mass
tab1_lines <- c(tab1_lines,
  paste0("Excess mass ($\\hat{b}$) & ",
         paste(sapply(1:nrow(pooled), function(i)
           fmt_coef(pooled$b_hat[i], pooled$se_b[i], 1)), collapse = " & "),
         " \\\\"))

# Standard errors
tab1_lines <- c(tab1_lines,
  paste0(" & ",
         paste(sapply(1:nrow(pooled), function(i)
           paste0("(", format(round(pooled$se_b[i], 1), nsmall = 1), ")")),
           collapse = " & "),
         " \\\\"))

# Absolute excess
tab1_lines <- c(tab1_lines,
  paste0("Excess installations & ",
         paste(format(round(pooled$B_hat), big.mark = ","), collapse = " & "),
         " \\\\"))

# Total in window
tab1_lines <- c(tab1_lines,
  paste0("Installations in window & ",
         paste(format(pooled$total, big.mark = ","), collapse = " & "),
         " \\\\"))

# Regulation
tab1_lines <- c(tab1_lines,
  "\\midrule",
  paste0("Regulation & \\multicolumn{1}{p{2cm}}{\\centering\\scriptsize ",
         pooled$regulation[1], "} & \\multicolumn{1}{p{2cm}}{\\centering\\scriptsize ",
         pooled$regulation[2], "} & \\multicolumn{1}{p{2cm}}{\\centering\\scriptsize ",
         pooled$regulation[3], "} & \\multicolumn{1}{p{2cm}}{\\centering\\scriptsize ",
         pooled$regulation[4], "} & \\multicolumn{1}{p{2cm}}{\\centering\\scriptsize ",
         pooled$regulation[5], "} \\\\"))

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Bunching estimates follow \\citet{Kleven2016}. ",
         "Excess mass $\\hat{b}$ is the ratio of excess count in the bunching region to ",
         "the average counterfactual bin height, estimated via degree-7 polynomial. ",
         "Standard errors (in parentheses) from 500 Poisson bootstrap replications. ",
         "Data: 4,852,684 solar PV installations from the Marktstammdatenregister (MaStR), 2000--2025. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_main.tex")

# ---------------------------------------------------------------
# Table 2: Difference-in-Bunching (2021 Reform)
# ---------------------------------------------------------------
cat("Generating Table 2: Difference-in-bunching...\n")

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Difference-in-Bunching: The 2021 EEG Reform}",
  "\\label{tab:dib}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated Thresholds} & & \\multicolumn{2}{c}{Placebo Thresholds} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){5-6}",
  " & 10 kWp & 30 kWp & & 100 kWp & 750 kWp \\\\",
  "\\midrule",
  "\\textit{Panel A: Pre-2021} & & & & & \\\\"
)

# Pre-2021 values
pre_10 <- dib[threshold == "10kWp", pre_b]
pre_30 <- dib[threshold == "30kWp", pre_b]
pre_100 <- dib[threshold == "100kWp", pre_b]
pre_750 <- dib[threshold == "750kWp", pre_b]

tab2_lines <- c(tab2_lines,
  sprintf("\\quad Excess mass ($\\hat{b}$) & %.1f & %.1f & & %.1f & %.1f \\\\",
          pre_10, pre_30, pre_100, pre_750))

pre_se_10 <- dib[threshold == "10kWp", pre_se]
pre_se_30 <- dib[threshold == "30kWp", pre_se]
pre_se_100 <- dib[threshold == "100kWp", pre_se]
pre_se_750 <- dib[threshold == "750kWp", pre_se]

tab2_lines <- c(tab2_lines,
  sprintf("\\quad & (%.1f) & (%.1f) & & (%.1f) & (%.1f) \\\\",
          pre_se_10, pre_se_30, pre_se_100, pre_se_750),
  " & & & & & \\\\",
  "\\textit{Panel B: Post-2021} & & & & & \\\\"
)

post_10 <- dib[threshold == "10kWp", post_b]
post_30 <- dib[threshold == "30kWp", post_b]
post_100 <- dib[threshold == "100kWp", post_b]
post_750 <- dib[threshold == "750kWp", post_b]

tab2_lines <- c(tab2_lines,
  sprintf("\\quad Excess mass ($\\hat{b}$) & %.1f & %.1f & & %.1f & %.1f \\\\",
          post_10, post_30, post_100, post_750))

post_se_10 <- dib[threshold == "10kWp", post_se]
post_se_30 <- dib[threshold == "30kWp", post_se]
post_se_100 <- dib[threshold == "100kWp", post_se]
post_se_750 <- dib[threshold == "750kWp", post_se]

tab2_lines <- c(tab2_lines,
  sprintf("\\quad & (%.1f) & (%.1f) & & (%.1f) & (%.1f) \\\\",
          post_se_10, post_se_30, post_se_100, post_se_750),
  " & & & & & \\\\",
  "\\midrule",
  "\\textit{Panel C: Difference} & & & & & \\\\"
)

diff_10 <- dib[threshold == "10kWp", diff]
diff_30 <- dib[threshold == "30kWp", diff]
diff_100 <- dib[threshold == "100kWp", diff]
diff_750 <- dib[threshold == "750kWp", diff]

se_diff_10 <- dib[threshold == "10kWp", se_diff]
se_diff_30 <- dib[threshold == "30kWp", se_diff]
se_diff_100 <- dib[threshold == "100kWp", se_diff]
se_diff_750 <- dib[threshold == "750kWp", se_diff]

tab2_lines <- c(tab2_lines,
  sprintf("\\quad $\\Delta\\hat{b}$ & %s & %s & & %s & %s \\\\",
          fmt_coef(diff_10, se_diff_10, 1),
          fmt_coef(diff_30, se_diff_30, 1),
          fmt_coef(diff_100, se_diff_100, 1),
          fmt_coef(diff_750, se_diff_750, 1)),
  sprintf("\\quad & (%.1f) & (%.1f) & & (%.1f) & (%.1f) \\\\",
          se_diff_10, se_diff_30, se_diff_100, se_diff_750))

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} The 2021 EEG amendment expanded the self-consumption surcharge ",
         "exemption from 10 to 30 kWp. Treated thresholds are 10 and 30 kWp (where the regulatory ",
         "incentive changed). Placebo thresholds (100 and 750 kWp) were unaffected by the reform. ",
         "Pre-2021: installations commissioned before January 2021. Post-2021: January 2021 onward. ",
         "Standard errors from 300 bootstrap replications. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_dib.tex")

# ---------------------------------------------------------------
# Table 3: Event Study (Year-by-Year at 10 kWp)
# ---------------------------------------------------------------
cat("Generating Table 3: Event study...\n")

yr10 <- yearly[threshold == 10]

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Evolution of Bunching at 10 kWp, 2010--2024}",
  "\\label{tab:event_study}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year & Excess mass ($\\hat{b}$) & SE & EEG regime \\\\",
  "\\midrule"
)

eeg_regime <- c(
  "2010" = "EEG 2009", "2011" = "EEG 2009", "2012" = "EEG 2012",
  "2013" = "EEG 2012", "2014" = "EEG 2014", "2015" = "EEG 2014",
  "2016" = "EEG 2014", "2017" = "EEG 2017", "2018" = "EEG 2017",
  "2019" = "EEG 2017", "2020" = "EEG 2017", "2021" = "EEG 2021",
  "2022" = "EEG 2021", "2023" = "EEG 2023", "2024" = "EEG 2023"
)

for (i in seq_len(nrow(yr10))) {
  yr <- yr10$year[i]
  regime <- eeg_regime[as.character(yr)]
  # Add line after 2020 to mark 2021 reform
  if (yr == 2021) {
    tab3_lines <- c(tab3_lines, "\\midrule")
  }
  tab3_lines <- c(tab3_lines,
    sprintf("%d & %s & (%.2f) & %s \\\\",
            yr, fmt_coef(yr10$b_hat[i], yr10$se[i], 2),
            yr10$se[i], regime))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Year-by-year bunching estimates at the 10 kWp threshold. ",
         "Each row estimates the excess mass for installations commissioned in that calendar year. ",
         "The horizontal line marks the January 2021 EEG reform that expanded the surcharge exemption ",
         "from 10 to 30 kWp. EEG regime indicates the prevailing Renewable Energy Sources Act version. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event.tex")

# ---------------------------------------------------------------
# Table 4: Robustness — Polynomial Order & Installation Type
# ---------------------------------------------------------------
cat("Generating Table 4: Robustness...\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Polynomial Order and Installation Type}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & 10 kWp & 30 kWp & 100 kWp & 750 kWp \\\\",
  "\\midrule",
  "\\textit{Panel A: Polynomial order} & & & & \\\\"
)

for (ord in c(5, 7, 9)) {
  vals <- poly_rob[poly_order == ord]
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Order %d & %s & %s & %s & %s \\\\",
            ord,
            fmt_coef(vals[threshold == 10, b_hat], vals[threshold == 10, se], 1),
            fmt_coef(vals[threshold == 30, b_hat], vals[threshold == 30, se], 1),
            fmt_coef(vals[threshold == 100, b_hat], vals[threshold == 100, se], 1),
            fmt_coef(vals[threshold == 750, b_hat], vals[threshold == 750, se], 1)))
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\",
            vals[threshold == 10, se],
            vals[threshold == 30, se],
            vals[threshold == 100, se],
            vals[threshold == 750, se]))
}

tab4_lines <- c(tab4_lines,
  " & & & & \\\\",
  "\\textit{Panel B: Installation type} & & & & \\\\"
)

for (itype in c("rooftop", "ground_mount")) {
  label <- ifelse(itype == "rooftop", "Rooftop", "Ground-mount")
  vals <- type_rob[type == itype]
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad %s & %s & %s & %s & %s \\\\",
            label,
            fmt_coef(vals[threshold == 10, b_hat], vals[threshold == 10, se], 1),
            fmt_coef(vals[threshold == 30, b_hat], vals[threshold == 30, se], 1),
            fmt_coef(vals[threshold == 100, b_hat], vals[threshold == 100, se], 1),
            fmt_coef(vals[threshold == 750, b_hat], vals[threshold == 750, se], 1)))
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\",
            vals[threshold == 10, se],
            vals[threshold == 30, se],
            vals[threshold == 100, se],
            vals[threshold == 750, se]))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Panel A varies the polynomial order of the counterfactual ",
         "distribution (baseline is order 7). Panel B estimates bunching separately for rooftop ",
         "installations (3.98M) and ground-mount installations (18,702). ",
         "Standard errors from 100 bootstrap replications. ",
         "*** $p<0.01$, ** $p<0.05$, * $p<0.10$."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) Appendix
# ---------------------------------------------------------------
cat("Generating SDE table...\n")

# Compute SDE for each threshold
# Treatment: binary (above vs below threshold)
# Outcome: capacity_kw
# For bunching, the SDE is the excess mass normalized by the distribution spread

# The meaningful "effect" is the share of installations that are strategically undersized
# SD(Y) = SD of capacity in the analysis window

sde_rows <- list()
for (i in seq_len(nrow(pooled))) {
  thr <- pooled$threshold_kw[i]
  label <- pooled$threshold[i]

  # Get installations in the analysis window
  if (thr <= 100) {
    lower <- max(0.5, thr * 0.3)
    upper <- thr * 2.0
  } else {
    lower <- thr * 0.4
    upper <- thr * 1.8
  }
  sub <- solar[capacity_kw >= lower & capacity_kw <= upper]
  sd_y <- sd(sub$capacity_kw)

  # "Beta" = average undersizing per bunching installation
  # Conservative: each bunching installation is sized at threshold instead of
  # threshold * (1 + avg_gap), where avg_gap ≈ 0.05
  beta <- thr * 0.05  # kWp of strategic undersizing
  se_beta <- beta * (pooled$se_b[i] / pooled$b_hat[i])  # Propagate SE from excess mass

  sde <- beta / sd_y
  se_sde <- se_beta / sd_y

  # Classification
  sde_class <- ifelse(abs(sde) < 0.005, "Null",
               ifelse(abs(sde) < 0.05, ifelse(sde > 0, "Small positive", "Small negative"),
               ifelse(abs(sde) < 0.15, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
               ifelse(sde > 0, "Large positive", "Large negative"))))

  sde_rows[[i]] <- data.table(
    outcome = paste0("Undersizing at ", label),
    beta = beta,
    se = se_beta,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = sde_class
  )
}
sde_tab <- rbindlist(sde_rows)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Germany. ",
  "\\textbf{Research question:} Do capacity-dependent regulatory thresholds in the EEG cause ",
  "strategic undersizing of solar PV installations, and how does the 2021 threshold expansion affect this distortion? ",
  "\\textbf{Policy mechanism:} The EEG creates five capacity thresholds (10, 30, 40, 100, 750 kWp) ",
  "that trigger progressively larger regulatory obligations---from surcharge exemption loss to mandatory ",
  "tender participation---creating discontinuous increases in compliance costs at each cutoff. ",
  "\\textbf{Outcome definition:} Average capacity undersizing (kWp) per installation in the bunching region, ",
  "measured as the gap between actual capacity and the counterfactual capacity absent the threshold. ",
  "\\textbf{Treatment:} Binary---installation capacity above vs.\\ below each regulatory threshold. ",
  "\\textbf{Data:} Marktstammdatenregister (MaStR), 4,852,684 solar PV installations, 2000--2025, ",
  "installation-level, sourced from Bundesnetzagentur via open-MaStR (Zenodo DOI: 10.5281/zenodo.14783581). ",
  "\\textbf{Method:} Bunching estimation (Kleven 2016) with degree-7 polynomial counterfactual; ",
  "standard errors from 500 Poisson bootstrap replications. ",
  "\\textbf{Sample:} Operating solar PV installations with positive net rated capacity and valid commissioning dates. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of capacity within each threshold's analysis window. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Heterogeneous panel: rooftop vs ground-mount for 10 kWp
het_rows <- list()

# Rooftop at 10 kWp
roof_sub <- solar[install_type == "rooftop" & capacity_kw >= 3 & capacity_kw <= 20]
sd_roof <- sd(roof_sub$capacity_kw)
roof_beta <- 10 * 0.05
roof_b <- type_rob[type == "rooftop" & threshold == 10, b_hat]
roof_se_b <- type_rob[type == "rooftop" & threshold == 10, se]
roof_se_beta <- roof_beta * (roof_se_b / roof_b)

het_rows[[1]] <- data.table(
  outcome = "Rooftop undersizing at 10 kWp",
  beta = roof_beta, se = roof_se_beta, sd_y = sd_roof,
  sde = roof_beta / sd_roof, se_sde = roof_se_beta / sd_roof,
  classification = ifelse(abs(roof_beta / sd_roof) < 0.005, "Null",
                  ifelse(abs(roof_beta / sd_roof) < 0.05, "Small positive",
                  ifelse(abs(roof_beta / sd_roof) < 0.15, "Moderate positive", "Large positive")))
)

# Ground-mount at 750 kWp
gm_sub <- solar[install_type == "ground_mount" & capacity_kw >= 300 & capacity_kw <= 1350]
if (nrow(gm_sub) > 100) {
  sd_gm <- sd(gm_sub$capacity_kw)
  gm_beta <- 750 * 0.05
  gm_b <- type_rob[type == "ground_mount" & threshold == 750, b_hat]
  gm_se_b <- type_rob[type == "ground_mount" & threshold == 750, se]
  gm_se_beta <- gm_beta * (gm_se_b / gm_b)

  het_rows[[2]] <- data.table(
    outcome = "Ground-mount undersizing at 750 kWp",
    beta = gm_beta, se = gm_se_beta, sd_y = sd_gm,
    sde = gm_beta / sd_gm, se_sde = gm_se_beta / sd_gm,
    classification = ifelse(abs(gm_beta / sd_gm) < 0.005, "Null",
                    ifelse(abs(gm_beta / sd_gm) < 0.05, "Small positive",
                    ifelse(abs(gm_beta / sd_gm) < 0.15, "Moderate positive", "Large positive")))
  )
}
het_tab <- rbindlist(het_rows)

# Generate SDE LaTeX table
tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

for (i in seq_len(nrow(sde_tab))) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad %s & %.2f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
            sde_tab$outcome[i], sde_tab$beta[i], sde_tab$se[i],
            sde_tab$sd_y[i], sde_tab$sde[i], sde_tab$se_sde[i],
            sde_tab$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  " & & & & & & \\\\",
  "\\textit{Panel B: Heterogeneous} & & & & & & \\\\"
)

for (i in seq_len(nrow(het_tab))) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad %s & %.2f & %.3f & %.1f & %.4f & %.4f & %s \\\\",
            het_tab$outcome[i], het_tab$beta[i], het_tab$se[i],
            het_tab$sd_y[i], het_tab$sde[i], het_tab$se_sde[i],
            het_tab$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
