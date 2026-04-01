# =============================================================================
# 05_tables.R — Generate all LaTeX tables for apep_1246
# =============================================================================

source("00_packages.R")

main_results <- readRDS("../data/main_results.rds")
age_results <- readRDS("../data/age_results.rds")
race_results <- readRDS("../data/race_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
panel_pooled <- readRDS("../data/panel_pooled.rds")
panel_pooled_bal <- readRDS("../data/panel_pooled_bal.rds")
pre_stats <- readRDS("../data/pre_stats.rds")
emp_idx <- readRDS("../data/emp_indices.rds")

dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics\n")

# Compute summary stats by sector and mandate status
summ <- panel_pooled_bal[, .(
  `Mean Emp` = mean(emp, na.rm = TRUE),
  `SD Emp` = sd(emp, na.rm = TRUE),
  `Mean Earnings` = mean(earn, na.rm = TRUE),
  `Sep Rate` = mean(sep_rate, na.rm = TRUE),
  `Hire Rate` = mean(hire_rate, na.rm = TRUE),
  Counties = uniqueN(county_fips),
  `N` = .N
), by = .(Sector = fifelse(industry == "623", "Nursing/Residential (623)",
                           "Social Assistance (624)"),
          Period = fifelse(qtr < 27, "Pre-Mandate", "Post-Mandate"))]

# LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Sector and Period}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{llccccc}\n")
cat("\\hline\\hline\n")
cat("Sector & Period & Mean Emp & SD Emp & Earnings & Sep Rate & Obs \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(summ)) {
  cat(sprintf("%s & %s & %.0f & %.0f & \\$%.0f & %.3f & %s \\\\\n",
              summ$Sector[i], summ$Period[i],
              summ$`Mean Emp`[i], summ$`SD Emp`[i],
              summ$`Mean Earnings`[i], summ$`Sep Rate`[i],
              format(summ$N[i], big.mark = ",")))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Employment is beginning-of-quarter headcount from QWI.\n")
cat("Earnings are average monthly earnings for stable workers.\n")
cat("Separation and hire rates are quarterly flows divided by beginning-of-quarter employment.\n")
cat("Pre-mandate: 2015Q1--2021Q2. Post-mandate: 2021Q3--2024Q4.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# -----------------------------------------------------------------------
# Table 2: Main DDD Results
# -----------------------------------------------------------------------
cat("Generating Table 2: Main DDD Results\n")

ddd_coef <- function(model, param = "has_state_mandate:naics623:post_mandate") {
  b <- coef(model)[param]
  s <- se(model)[param]
  p <- pvalue(model)[param]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = b, se = s, pval = p, stars = stars)
}

models <- list(
  "Log Employment" = main_results$ddd_emp,
  "Separation Rate" = main_results$ddd_sep,
  "Log Earnings" = main_results$ddd_earn,
  "Hire Rate" = main_results$ddd_hire
)

sink("../tables/tab2_ddd.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Triple-Difference Estimates: State Vaccine Mandates and Nursing Home Workforce}\n")
cat("\\label{tab:ddd}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Log Emp & Sep Rate & Log Earn & Hire Rate \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

# DDD coefficient
cat("Mandate $\\times$ NAICS 623 $\\times$ Post")
for (nm in names(models)) {
  r <- ddd_coef(models[[nm]])
  cat(sprintf(" & %.4f%s", r$coef, r$stars))
}
cat(" \\\\\n")

# Standard errors
cat(" ")
for (nm in names(models)) {
  r <- ddd_coef(models[[nm]])
  cat(sprintf(" & (%.4f)", r$se))
}
cat(" \\\\\n")

# Observations
cat("Observations")
for (nm in names(models)) {
  cat(sprintf(" & %s", format(nobs(models[[nm]]), big.mark = ",")))
}
cat(" \\\\\n")

# Fixed effects
cat("County-Sector FE & Yes & Yes & Yes & Yes \\\\\n")
cat("State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\\n")

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Triple-difference estimates comparing NAICS 623 (Nursing \\& Residential Care)")
cat(" to NAICS 624 (Social Assistance) in state-mandate vs.\\ non-mandate states,")
cat(" before and after mandate implementation.")
cat(" Standard errors clustered at the state level in parentheses.")
cat(" $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# -----------------------------------------------------------------------
# Table 3: Demographic Decomposition
# -----------------------------------------------------------------------
cat("Generating Table 3: Demographic Decomposition\n")

sink("../tables/tab3_demographics.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Demographic Decomposition: Who Left Nursing Homes?}\n")
cat("\\label{tab:demographics}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{By Age Group} & \\multicolumn{2}{c}{By Race} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")

# Get DDD coefficient for each age group
age_names <- sort(names(age_results))
race_names <- sort(names(race_results))
max_rows <- max(length(age_names), length(race_names))

cat(" & Group & Coefficient & Group & Coefficient \\\\\n")
cat("\\hline\n")

for (i in seq_len(max_rows)) {
  cat(" ")
  if (i <= length(age_names)) {
    ag <- age_names[i]
    r <- ddd_coef(age_results[[ag]])
    cat(sprintf("& %s & %.4f%s", ag, r$coef, r$stars))
    cat(sprintf(" \\\\\n & & (%.4f)", r$se))
  } else {
    cat("& & ")
  }
  if (i <= length(race_names)) {
    rc <- race_names[i]
    r <- ddd_coef(race_results[[rc]])
    cat(sprintf(" & %s & %.4f%s", rc, r$coef, r$stars))
    cat(sprintf(" \\\\\n & & & & (%.4f)", r$se))
  } else {
    cat(" & & ")
  }
  cat(" \\\\\n")
}

cat("\\hline\n")
cat("County-Sector-Demo FE & \\multicolumn{4}{c}{Yes} \\\\\n")
cat("State $\\times$ Quarter FE & \\multicolumn{4}{c}{Yes} \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each column reports the DDD coefficient")
cat(" (Mandate $\\times$ NAICS 623 $\\times$ Post)")
cat(" from a separate regression estimated on the indicated demographic subgroup.")
cat(" The comparison sector is NAICS 624 (Social Assistance) within the same county-quarter.")
cat(" Standard errors clustered at the state level in parentheses.")
cat(" $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# -----------------------------------------------------------------------
# Table 4: Robustness Checks
# -----------------------------------------------------------------------
cat("Generating Table 4: Robustness\n")

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat(" & Coefficient & SE \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Main specification}} \\\\\n")
r <- ddd_coef(main_results$ddd_emp)
cat(sprintf("DDD (NAICS 623 vs 624) & %.4f%s & (%.4f) \\\\\n", r$coef, r$stars, r$se))

cat("\\multicolumn{3}{l}{\\textit{Panel B: Placebo tests}} \\\\\n")
r621 <- ddd_coef(rob_results$placebo_621, "has_state_mandate:naics621:post_mandate")
cat(sprintf("Placebo: NAICS 621 vs 624 & %.4f%s & (%.4f) \\\\\n", r621$coef, r621$stars, r621$se))
r55 <- ddd_coef(rob_results$placebo_55plus)
cat(sprintf("Placebo: Age 55+ only & %.4f%s & (%.4f) \\\\\n", r55$coef, r55$stars, r55$se))

cat("\\multicolumn{3}{l}{\\textit{Panel C: Alternative estimator}} \\\\\n")
sunab_att <- summary(rob_results$sunab_emp)$coeftable
att_row <- grep("ATT", rownames(sunab_att))
if (length(att_row) > 0) {
  sa_coef <- sunab_att[att_row[1], 1]
  sa_se <- sunab_att[att_row[1], 2]
  sa_p <- sunab_att[att_row[1], 4]
  sa_stars <- ifelse(sa_p < 0.01, "***", ifelse(sa_p < 0.05, "**", ifelse(sa_p < 0.1, "*", "")))
  cat(sprintf("Sun-Abraham ATT (NAICS 623) & %.4f%s & (%.4f) \\\\\n", sa_coef, sa_stars, sa_se))
}

cat("\\multicolumn{3}{l}{\\textit{Panel D: Leave-one-out range}} \\\\\n")
loo <- rob_results$loo_results
cat(sprintf("Min (drop %s) & %.4f & \\\\\n",
            loo[which.min(coef), dropped_state], min(loo$coef)))
cat(sprintf("Max (drop %s) & %.4f & \\\\\n",
            loo[which.max(coef), dropped_state], max(loo$coef)))

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Panel A repeats the main specification from Table~\\ref{tab:ddd}.")
cat(" Panel B shows placebo tests: NAICS 621 (Ambulatory Care, partially covered by mandates)")
cat(" replaces NAICS 623; age 55+ workers (high vaccination rates, expect weaker sieve effect).")
cat(" Panel C uses the Sun-Abraham (2021) estimator within NAICS 623 only.")
cat(" Panel D reports the range of DDD coefficients from leave-one-out exercises")
cat(" dropping each mandate state in turn.")
cat(" Standard errors clustered at the state level.")
cat(" $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# -----------------------------------------------------------------------
# Table 5: Employment Recovery Indices
# -----------------------------------------------------------------------
cat("Generating Table 5: Employment Recovery\n")

# Show 2019Q1, 2020Q2 (trough), 2021Q3 (first mandate), 2022Q4, 2024Q4
# Create yq label first
emp_idx[, yq := paste0(year, "Q", quarter)]

key_qtrs <- emp_idx[yq %in% c("2019Q1", "2020Q2", "2021Q3", "2022Q4") |
                    (year == max(year) & quarter == max(quarter[year == max(year)]))]

sink("../tables/tab5_recovery.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Employment Recovery by Sector and Mandate Status (Index, 2019Q1 = 100)}\n")
cat("\\label{tab:recovery}\n")

# Get unique time periods
periods <- sort(unique(key_qtrs$yq))
ncols <- length(periods)

cat(sprintf("\\begin{tabular}{ll%s}\n", paste(rep("c", ncols), collapse = "")))
cat("\\hline\\hline\n")
cat(sprintf("Sector & Mandate & %s \\\\\n", paste(periods, collapse = " & ")))
cat("\\hline\n")

for (ind in c("623", "624")) {
  for (mand in c(1, 0)) {
    sector_lab <- ifelse(ind == "623", "NAICS 623", "NAICS 624")
    mand_lab <- ifelse(mand == 1, "State", "Federal only")
    cat(sprintf("%s & %s", sector_lab, mand_lab))
    for (p in periods) {
      val <- key_qtrs[industry == ind & has_state_mandate == mand & yq == p, emp_index]
      if (length(val) > 0) {
        cat(sprintf(" & %.1f", val[1]))
      } else {
        cat(" & ---")
      }
    }
    cat(" \\\\\n")
  }
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Employment index normalized to 2019Q1 = 100.")
cat(" NAICS 623: Nursing and Residential Care Facilities.")
cat(" NAICS 624: Social Assistance.")
cat(" ``State'' = states with own vaccine mandate before CMS federal mandate.")
cat(" ``Federal only'' = states where only the CMS mandate applied (effective early 2022).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# -----------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE) — APPENDIX
# -----------------------------------------------------------------------
cat("Generating Table F1: SDE\n")

# Pre-treatment SD of log employment in NAICS 623
pre_623 <- pre_stats[industry == "623"]
sd_log_emp <- pre_623$sd_log_emp
sd_sep_rate <- pre_stats[industry == "623", sd_sep_rate]
sd_earn <- pre_stats[industry == "623", sd_earn]

# Main outcomes
sde_rows <- list()

# 1. Employment (pooled DDD)
b_emp <- coef(main_results$ddd_emp)["has_state_mandate:naics623:post_mandate"]
se_emp <- se(main_results$ddd_emp)["has_state_mandate:naics623:post_mandate"]
sde_emp <- b_emp / sd_log_emp
se_sde_emp <- se_emp / sd_log_emp
sde_rows[["Employment (log)"]] <- list(
  outcome = "Employment (log)", beta = b_emp, se = se_emp,
  sd_y = sd_log_emp, sde = sde_emp, se_sde = se_sde_emp
)

# 2. Separation rate
b_sep <- coef(main_results$ddd_sep)["has_state_mandate:naics623:post_mandate"]
se_sep <- se(main_results$ddd_sep)["has_state_mandate:naics623:post_mandate"]
sde_sep <- b_sep / sd_sep_rate
se_sde_sep <- se_sep / sd_sep_rate
sde_rows[["Separation Rate"]] <- list(
  outcome = "Separation Rate", beta = b_sep, se = se_sep,
  sd_y = sd_sep_rate, sde = sde_sep, se_sde = se_sde_sep
)

# 3. Earnings
b_earn <- coef(main_results$ddd_earn)["has_state_mandate:naics623:post_mandate"]
se_earn <- se(main_results$ddd_earn)["has_state_mandate:naics623:post_mandate"]
sd_log_earn <- pre_623$sd_earn
sde_earn <- b_earn / sd_log_earn
se_sde_earn <- se_earn / sd_log_earn
# Use sd of log_earn from the actual pre-period data
pre_earn_sd <- panel_pooled_bal[industry == "623" & qtr < 27, sd(log_earn, na.rm = TRUE)]
sde_earn_v2 <- b_earn / pre_earn_sd
se_sde_earn_v2 <- se_earn / pre_earn_sd
sde_rows[["Earnings (log)"]] <- list(
  outcome = "Earnings (log)", beta = b_earn, se = se_earn,
  sd_y = pre_earn_sd, sde = sde_earn_v2, se_sde = se_sde_earn_v2
)

# Classify SDE
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

# Panel A: Pooled
sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (nm in names(sde_rows)) {
  r <- sde_rows[[nm]]
  cls <- classify_sde(r$sde)
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, cls))
}

# Panel B: Heterogeneous (age-based sample splits)
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Age Splits)}} \\\\\n")

# Young workers (25-34)
if ("25-34" %in% names(age_results)) {
  b_young <- coef(age_results[["25-34"]])["has_state_mandate:naics623:post_mandate"]
  se_young <- se(age_results[["25-34"]])["has_state_mandate:naics623:post_mandate"]
  # Get pre-treatment SD for this subgroup
  sub_pre <- panel_pooled_bal[industry == "623" & qtr < 27]
  sd_young <- sd(sub_pre$log_emp, na.rm = TRUE)  # approximate
  sde_young <- b_young / sd_young
  se_sde_young <- se_young / sd_young
  cls_young <- classify_sde(sde_young)
  cat(sprintf("Employment (age 25--34) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              b_young, se_young, sd_young, sde_young, se_sde_young, cls_young))
}

# Older workers (55+)
if ("55+" %in% names(age_results)) {
  b_old <- coef(age_results[["55+"]])["has_state_mandate:naics623:post_mandate"]
  se_old <- se(age_results[["55+"]])["has_state_mandate:naics623:post_mandate"]
  sd_old <- sd(sub_pre$log_emp, na.rm = TRUE)
  sde_old <- b_old / sd_old
  se_sde_old <- se_old / sd_old
  cls_old <- classify_sde(sde_old)
  cat(sprintf("Employment (age 55+) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              b_old, se_old, sd_old, sde_old, se_sde_old, cls_old))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did state-level healthcare worker vaccine mandates cause permanent ",
  "employment losses in nursing and residential care facilities (NAICS 623), and did they ",
  "disproportionately push out younger workers? ",
  "\\textbf{Policy mechanism:} State vaccine mandates required healthcare workers in licensed ",
  "facilities to be fully vaccinated against COVID-19 or face termination; workers who refused ",
  "vaccination exited the sector, and the mandates differentially affected demographic groups ",
  "with lower baseline vaccination rates. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter employment from QWI, measuring the ",
  "stock of workers employed in NAICS 623 facilities at each county-quarter. ",
  "\\textbf{Treatment:} Binary --- state adopted its own healthcare worker vaccine mandate before ",
  "the CMS federal mandate took effect. ",
  "\\textbf{Data:} Census QWI (LEHD), county $\\times$ quarter $\\times$ 3-digit NAICS, 2015Q1--2024Q4. ",
  "\\textbf{Method:} Triple-difference (Mandate $\\times$ NAICS 623 $\\times$ Post) with county-sector ",
  "and state $\\times$ quarter fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with at least 90\\% quarter coverage in both NAICS 623 and 624. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("All tables generated in tables/.\n")
