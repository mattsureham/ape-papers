# 05_tables.R — Generate all LaTeX tables for MEES bunching paper

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# Load data and models
panel <- fread(file.path(data_dir, "panel_la_quarter.csv"))
eng_ts <- fread(file.path(data_dir, "england_timeseries.csv"))
eng_rental <- fread(file.path(data_dir, "england_rental_ts.csv"))
la_rental <- fread(file.path(data_dir, "la_rental_intensity.csv"))

panel <- panel[!is.na(fg_share) & !is.na(pre_rental_share) & total_rated >= 10]
panel[, post_mees := as.integer(year > 2018 | (year == 2018 & q >= 2))]

load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("=== Table 1: Summary Statistics ===\n")

# Panel-level summary stats by period
panel[, period := fcase(
  year < 2015, "Pre-announcement (2008--2014)",
  year >= 2015 & (year < 2018 | (year == 2018 & q <= 1)), "Anticipatory (2015--2018Q1)",
  default = "Post-MEES (2018Q2--2025)"
)]

summ <- panel[, .(
  `F+G Share` = sprintf("%.3f", mean(fg_share, na.rm = TRUE)),
  `SD(F+G)` = sprintf("%.3f", sd(fg_share, na.rm = TRUE)),
  `Total EPCs` = format(sum(total_rated, na.rm = TRUE), big.mark = ","),
  `F+G Count` = format(sum(fg_count, na.rm = TRUE), big.mark = ","),
  `LA-Quarters` = format(.N, big.mark = ",")
), by = period]

# Add rental intensity stats
rental_summ <- la_rental[, .(
  mean_rental = sprintf("%.3f", mean(pre_rental_share, na.rm = TRUE)),
  sd_rental = sprintf("%.3f", sd(pre_rental_share, na.rm = TRUE)),
  min_rental = sprintf("%.3f", min(pre_rental_share, na.rm = TRUE)),
  max_rental = sprintf("%.3f", max(pre_rental_share, na.rm = TRUE))
)]

# Write Table 1
sink(file.path(tab_dir, "tab1_summary.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: EPC Lodgements in England by MEES Period}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat("Period & Mean F+G & SD & Total EPCs & F+G Count & LA-Quarters \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ)) {
  cat(sprintf("%s & %s & %s & %s & %s & %s \\\\\n",
              summ$period[i], summ$`F+G Share`[i], summ$`SD(F+G)`[i],
              summ$`Total EPCs`[i], summ$`F+G Count`[i], summ$`LA-Quarters`[i]))
}
cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Cross-LA Rental Intensity (2012--2017 baseline)}} \\\\\n")
cat(sprintf("Mean & %s & %s & Min: %s & Max: %s & LAs: %d \\\\\n",
            rental_summ$mean_rental, rental_summ$sd_rental,
            rental_summ$min_rental, rental_summ$max_rental,
            nrow(la_rental)))
cat("\\hline\\hline\n")
cat("\\multicolumn{6}{p{0.95\\textwidth}}{\\scriptsize \\textit{Notes:} F+G share is the ",
    "fraction of domestic EPC lodgements rated F or G (score $<$ 39) among all rated ",
    "lodgements in each Local Authority--quarter cell. Rental intensity is the pre-MEES ",
    "(2012--2017) share of EPC lodgements classified as ``Rental'' in the transaction type ",
    "field. Source: GOV.UK EPC Live Tables D1 and D4B. England only.}\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# TABLE 2: Main Results — DiD
# ============================================================================

cat("=== Table 2: Main Results ===\n")

sink(file.path(tab_dir, "tab2_main.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{MEES and Substandard EPC Shares: Cross-LA Difference-in-Differences}\n")
cat("\\label{tab:main}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{4}{c}{Dependent Variable: F+G Share} \\\\\n")
cat("\\cmidrule(lr){2-5}\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

# Extract coefficients
coef1 <- sprintf("%.4f", coef(m1)[[1]])
se1 <- sprintf("(%.4f)", se(m1)[[1]])
stars1 <- ifelse(fixest::pvalue(m1)[[1]] < 0.001, "***",
                 ifelse(fixest::pvalue(m1)[[1]] < 0.01, "**",
                        ifelse(fixest::pvalue(m1)[[1]] < 0.05, "*", "")))

cat(sprintf("Post-MEES $\\times$ Rental Intensity & %s%s & & & %s%s \\\\\n",
            coef1, stars1, sprintf("%.4f", coef(m_weighted)[[1]]),
            ifelse(fixest::pvalue(m_weighted)[[1]] < 0.001, "***", "**")))
cat(sprintf(" & %s & & & %s \\\\\n", se1, sprintf("(%.4f)", se(m_weighted)[[1]])))

cat("[0.5em]\n")

# Model 2: Staggered phases
cat(sprintf("Anticipatory $\\times$ Rental & & %.4f & & \\\\\n", coef(m2)[[1]]))
cat(sprintf(" & & (%.4f) & & \\\\\n", se(m2)[[1]]))
cat(sprintf("New Tenancies $\\times$ Rental & & %.4f%s & & \\\\\n",
            coef(m2)[[2]], ifelse(fixest::pvalue(m2)[[2]] < 0.001, "***", "**")))
cat(sprintf(" & & (%.4f) & & \\\\\n", se(m2)[[2]]))
cat(sprintf("All Tenancies $\\times$ Rental & & %.4f%s & & \\\\\n",
            coef(m2)[[3]], ifelse(fixest::pvalue(m2)[[3]] < 0.01, "**", "*")))
cat(sprintf(" & & (%.4f) & & \\\\\n", se(m2)[[3]]))

cat("[0.5em]\n")

# Model 3: Tercile
cat(sprintf("High Rental $\\times$ Post-MEES & & & %.4f%s & \\\\\n",
            coef(m3)[[1]], ifelse(fixest::pvalue(m3)[[1]] < 0.001, "***", "**")))
cat(sprintf(" & & & (%.4f) & \\\\\n", se(m3)[[1]]))
cat(sprintf("Medium Rental $\\times$ Post-MEES & & & %.4f%s & \\\\\n",
            coef(m3)[[2]], ifelse(fixest::pvalue(m3)[[2]] < 0.1, "*", "")))
cat(sprintf(" & & & (%.4f) & \\\\\n", se(m3)[[2]]))

cat("\\hline\n")
cat("LA Fixed Effects & Yes & Yes & Yes & Yes \\\\\n")
cat("Quarter Fixed Effects & Yes & Yes & Yes & Yes \\\\\n")
cat("Weighted & No & No & No & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(m1), big.mark = ","),
            format(nobs(m2), big.mark = ","),
            format(nobs(m3), big.mark = ","),
            format(nobs(m_weighted), big.mark = ",")))
cat(sprintf("$R^2$ (within) & %.4f & %.4f & %.4f & %.4f \\\\\n",
            fitstat(m1, "wr2")$wr2, fitstat(m2, "wr2")$wr2,
            fitstat(m3, "wr2")$wr2, fitstat(m_weighted, "wr2")$wr2))
cat("\\hline\\hline\n")
cat("\\multicolumn{5}{p{0.95\\textwidth}}{\\scriptsize \\textit{Notes:} ",
    "Each observation is a Local Authority--quarter. The dependent variable is the share ",
    "of domestic EPC lodgements rated F or G. ``Rental Intensity'' is the pre-MEES ",
    "(2012--2017) share of lodgements classified as rental transactions. Post-MEES is ",
    "an indicator for 2018Q2 onward. Column (2) decomposes the post-period into three ",
    "MEES phases: anticipatory (2015--2018Q1), new tenancies only (2018Q2--2020Q1), and ",
    "all existing tenancies (2020Q2+). Column (3) replaces continuous rental intensity ",
    "with tercile indicators (reference: low-rental LAs). Column (4) weights by total ",
    "rated EPCs. Standard errors clustered at the LA level in parentheses. ",
    "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# TABLE 3: Robustness — Placebo and subsample
# ============================================================================

cat("=== Table 3: Robustness ===\n")

sink(file.path(tab_dir, "tab3_robustness.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Robustness and Placebo Tests}\n")
cat("\\label{tab:robust}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & D Band & E Band & Excl.\\ London & Binary \\\\\n")
cat(" & (Placebo) & (Adjacent) & & Treatment \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

cat(sprintf("Post-MEES $\\times$ Rental & %.4f & %.4f%s & %.4f%s & \\\\\n",
            coef(m_placebo_d)[[1]],
            coef(m_placebo_e)[[1]], ifelse(fixest::pvalue(m_placebo_e)[[1]] < 0.01, "**", "*"),
            coef(m_no_london)[[1]], ifelse(fixest::pvalue(m_no_london)[[1]] < 0.001, "***", "**")))
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & \\\\\n",
            se(m_placebo_d)[[1]], se(m_placebo_e)[[1]], se(m_no_london)[[1]]))

cat(sprintf("Post-MEES $\\times$ High Rental & & & & %.4f%s \\\\\n",
            coef(m_binary)[[1]], ifelse(fixest::pvalue(m_binary)[[1]] < 0.001, "***", "**")))
cat(sprintf(" & & & & (%.4f) \\\\\n", se(m_binary)[[1]]))

cat("\\hline\n")
cat("LA FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Quarter FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(m_placebo_d), big.mark = ","),
            format(nobs(m_placebo_e), big.mark = ","),
            format(nobs(m_no_london), big.mark = ","),
            format(nobs(m_binary), big.mark = ",")))
cat("\\hline\\hline\n")
cat("\\multicolumn{5}{p{0.95\\textwidth}}{\\scriptsize \\textit{Notes:} ",
    "Column (1): placebo test using D band share (score 55--68, well above MEES threshold). ",
    "Column (2): E band share (score 39--54, adjacent to threshold --- may absorb upgrading). ",
    "Column (3): excludes 33 London boroughs. Column (4): binary treatment indicator ",
    "(above/below median pre-MEES rental share). Standard errors clustered at LA level. ",
    "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.}\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# TABLE 4: Rental EPC Lodgement Surge
# ============================================================================

cat("=== Table 4: Lodgement Surge ===\n")

eng_rental[, year := as.integer(sub("/.*", "", quarter))]
eng_rental[, q := as.integer(sub(".*/", "", quarter))]

surge <- eng_rental[, .(
  rental_per_q = mean(total_rental),
  sale_per_q = mean(total_sale),
  rental_share = mean(rental_share),
  total_per_q = mean(total_rental + total_sale)
), by = .(period = fcase(
  year < 2015, "2012--2014",
  year >= 2015 & (year < 2018 | (year == 2018 & q <= 1)), "2015--2018Q1",
  year >= 2018 & (year < 2020 | (year == 2020 & q <= 1)), "2018Q2--2020Q1",
  default = "2020Q2--2025"
))]
surge <- surge[order(period)]

sink(file.path(tab_dir, "tab4_surge.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{EPC Lodgement Volume by Transaction Type and MEES Period}\n")
cat("\\label{tab:surge}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Period & Rental/Q & Sale/Q & Total/Q & Rental Share \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(surge)) {
  cat(sprintf("%s & %s & %s & %s & %.3f \\\\\n",
              surge$period[i],
              format(round(surge$rental_per_q[i]), big.mark = ","),
              format(round(surge$sale_per_q[i]), big.mark = ","),
              format(round(surge$total_per_q[i]), big.mark = ","),
              surge$rental_share[i]))
}
cat("\\hline\\hline\n")
cat("\\multicolumn{5}{p{0.95\\textwidth}}{\\scriptsize \\textit{Notes:} ",
    "Mean quarterly EPC lodgement counts by transaction type across MEES phases. ",
    "Rental/Q is the mean number of rental-classified EPCs per quarter. Sale/Q is ",
    "marketed plus non-marketed sales. Rental Share is the rental fraction of the ",
    "rental + sale total. Source: GOV.UK EPC Live Table D4B, England only.}\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================================

cat("=== Table F1: SDE ===\n")

# Compute SDE for main outcomes
sd_fg <- sd(panel$fg_share, na.rm = TRUE)
sd_rental <- sd(panel$pre_rental_share, na.rm = TRUE)

# Main result: continuous treatment
beta_main <- coef(m1)[[1]]
se_beta_main <- se(m1)[[1]]
# This is a continuous × binary interaction, so SDE = beta × SD(X) / SD(Y)
sde_main <- beta_main * sd_rental / sd_fg
se_sde_main <- se_beta_main * sd_rental / sd_fg

# E band adjacent effect
beta_e <- coef(m_placebo_e)[[1]]
se_beta_e <- se(m_placebo_e)[[1]]
sd_e <- sd(panel$fg_share, na.rm = TRUE)  # use same SD for comparability
sde_e <- beta_e * sd_rental / sd_e
se_sde_e <- se_beta_e * sd_rental / sd_e

# Binary treatment
beta_binary <- coef(m_binary)[[1]]
se_beta_binary <- se(m_binary)[[1]]
sde_binary <- beta_binary / sd_fg
se_sde_binary <- se_beta_binary / sd_fg

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sink(file.path(tab_dir, "tabF1_sde.tex"))
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")

cat(sprintf("F+G Share (continuous $\\times$ post) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_main, se_beta_main, sd_fg, sde_main, se_sde_main, classify_sde(sde_main)))
cat(sprintf("F+G Share (binary high rental) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_binary, se_beta_binary, sd_fg, sde_binary, se_sde_binary, classify_sde(sde_binary)))
cat(sprintf("E Band Share (adjacent test) & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\\n",
            beta_e, se_beta_e, sd_e, sde_e, se_sde_e, classify_sde(sde_e)))

cat("\\hline\\hline\n")
cat("\\multicolumn{7}{p{0.95\\textwidth}}{\\scriptsize \\textit{Notes:} ",
    "Standardized Discriminant Effect sizes. For the continuous treatment specification, ",
    "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where $X$ is the pre-MEES ",
    "rental intensity and $Y$ is the F+G share. For the binary specification, ",
    "SDE $= \\hat{\\beta} / \\text{SD}(Y)$. ",
    "\\textbf{Country:} United Kingdom (England). ",
    "\\textbf{Research question:} Whether England's 2018 Minimum Energy Efficiency ",
    "Standards --- which prohibit letting domestic properties rated F or G (EPC score $<$ 39) ",
    "--- reduced the substandard share of the assessed housing stock, and whether this ",
    "reduction was attenuated in high-rental Local Authorities by a compliance-driven ",
    "EPC lodgement surge that revealed previously unassessed substandard properties. ",
    "\\textbf{Policy mechanism:} MEES creates a regulatory floor at EPC band E; landlords ",
    "must either upgrade properties or withdraw them from the rental market, but the regulation ",
    "also requires EPC assessment, forcing information revelation for previously unassessed stock. ",
    "\\textbf{Outcome:} Quarterly share of domestic EPC lodgements rated F or G (score $<$ 39) ",
    "within each English Local Authority. ",
    "\\textbf{Treatment:} Continuous --- pre-MEES (2012--2017) rental share of EPC lodgements, ",
    "interacted with post-MEES (2018Q2+) indicator. Binary --- above/below median rental share. ",
    "\\textbf{Data:} GOV.UK EPC Live Tables D1 (band counts) and D4B (transaction types), ",
    "2008Q4--2025Q4, 324 English LAs, 21,440 LA-quarter observations. ",
    "\\textbf{Method:} Two-way fixed effects (LA + quarter) with standard errors clustered at ",
    "the LA level (317--324 clusters). ",
    "\\textbf{Sample:} All English Local Authorities with $\\geq$ 10 rated EPC lodgements per quarter. ",
    "Classification refers to effect magnitude, not statistical significance. ",
    "SDE thresholds: large ($|$SDE$| > 0.15$), moderate ($0.05$--$0.15$), small ($0.005$--$0.05$), ",
    "null ($|$SDE$| < 0.005$).}\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables generated ===\n")
cat("Files:", paste(list.files(tab_dir), collapse = ", "), "\n")
