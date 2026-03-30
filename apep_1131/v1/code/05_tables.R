# 05_tables.R — Generate all LaTeX tables
# apep_1131: The Hollow Safety Net

source("00_packages.R")

load("../data/models.RData")
load("../data/robustness.RData")

tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

# Helper: format significance stars
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

vars_to_summarize <- c("timeliness_14d", "timeliness_21d", "bartik_shock",
                        "staff_per_1000", "annual_initial_claims", "workload_n")
var_labels <- c("First payment timeliness (\\% within 14 days)",
                "First payment timeliness (\\% within 21 days)",
                "Bartik predicted employment shock",
                "State govt. FTE per 1,000 private workers",
                "Annual UI initial claims",
                "BTQ total workload")

ss <- panel %>%
  summarise(across(all_of(vars_to_summarize),
                   list(mean = ~mean(., na.rm = TRUE),
                        sd   = ~sd(., na.rm = TRUE),
                        min  = ~min(., na.rm = TRUE),
                        max  = ~max(., na.rm = TRUE))))

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Variable & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule"
)

for (i in seq_along(vars_to_summarize)) {
  v <- vars_to_summarize[i]
  m  <- ss[[paste0(v, "_mean")]]
  s  <- ss[[paste0(v, "_sd")]]
  mn <- ss[[paste0(v, "_min")]]
  mx <- ss[[paste0(v, "_max")]]
  if (v == "annual_initial_claims") {
    tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                         var_labels[i], fmt_int(m), fmt_int(s), fmt_int(mn), fmt_int(mx)))
  } else {
    tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s & %s \\\\",
                                         var_labels[i], fmt(m, 1), fmt(s, 1), fmt(mn, 1), fmt(mx, 1)))
  }
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s state-year observations covering %d states and %d years (%d--%d). Timeliness is the share of intrastate UI first payments made within the specified number of days from the first compensable week, from DOL BTQ Category 1 reports. Bartik shock is the predicted state employment change from pre-recession (2006) industry composition interacted with leave-one-out national industry growth. State government FTE from Census ASPEP 2007. Initial claims from DOL ETA 539.",
          fmt_int(nrow(panel)), n_distinct(panel$state_fips), n_distinct(panel$year),
          min(panel$year), max(panel$year)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tab_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: First Stage and Reduced Form
# ============================================================================
cat("=== Table 2: First Stage and Reduced Form ===\n")

# Extract coefficients
rf1_b <- coef(rf1)["bartik_shock"]; rf1_se <- se(rf1)["bartik_shock"]; rf1_p <- pvalue(rf1)["bartik_shock"]
rf2_b <- coef(rf2)["bartik_shock"]; rf2_se <- se(rf2)["bartik_shock"]; rf2_p <- pvalue(rf2)["bartik_shock"]
rf2_int_b <- coef(rf2)["bartik_x_thinness"]; rf2_int_se <- se(rf2)["bartik_x_thinness"]; rf2_int_p <- pvalue(rf2)["bartik_x_thinness"]
fs1_b <- coef(fs1)["bartik_shock"]; fs1_se <- se(fs1)["bartik_shock"]; fs1_p <- pvalue(fs1)["bartik_shock"]
f_stat <- fitstat(iv1, "ivf")$ivf1$stat

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{First Stage and Reduced Form}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & \\multicolumn{2}{c}{Timeliness (\\% $\\leq$ 14 days)} & log(Claims) \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4}",
  " & Reduced Form & Reduced Form & First Stage \\\\",
  "\\midrule",
  sprintf("Bartik shock & %s%s & %s%s & %s%s \\\\",
          fmt(rf1_b, 1), stars(rf1_p), fmt(rf2_b, 1), stars(rf2_p),
          fmt(fs1_b, 1), stars(fs1_p)),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
          fmt(rf1_se, 1), fmt(rf2_se, 1), fmt(fs1_se, 1)),
  " & & & \\\\",
  sprintf("Bartik $\\times$ Thinness & & %s%s & \\\\",
          fmt(rf2_int_b, 2), stars(rf2_int_p)),
  sprintf(" & & (%s) & \\\\", fmt(rf2_int_se, 2)),
  "\\midrule",
  "State FE & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          fmt_int(nobs(rf1)), fmt_int(nobs(rf2)), fmt_int(nobs(fs1))),
  sprintf("First-stage $F$ & & & %.1f \\\\", f_stat),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Columns (1)--(2) report reduced-form regressions of 14-day first payment timeliness on the Bartik predicted employment shock. Column (3) reports the first stage: Bartik shock predicting log annual initial claims. Thinness is the negative of state government FTE per 1,000 private workers in 2007 (higher = thinner staffing). The Bartik instrument uses 2006 industry employment shares interacted with leave-one-out national industry employment growth.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:firststage}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tab_dir, "tab2_firststage.tex"))

# ============================================================================
# Table 3: Main IV Results
# ============================================================================
cat("=== Table 3: Main IV Results ===\n")

iv1_b <- coef(iv1)["fit_log_claims"]; iv1_se <- se(iv1)["fit_log_claims"]; iv1_p <- pvalue(iv1)["fit_log_claims"]
iv2_b <- coef(iv2)["fit_claims_per_staff"]; iv2_se <- se(iv2)["fit_claims_per_staff"]; iv2_p <- pvalue(iv2)["fit_claims_per_staff"]
iv_thin_b <- coef(iv_thin)["fit_log_claims"]; iv_thin_se <- se(iv_thin)["fit_log_claims"]; iv_thin_p <- pvalue(iv_thin)["fit_log_claims"]
iv_thick_b <- coef(iv_thick)["fit_log_claims"]; iv_thick_se <- se(iv_thick)["fit_log_claims"]; iv_thick_p <- pvalue(iv_thick)["fit_log_claims"]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{The Effect of Claims Surges on First Payment Timeliness (2SLS)}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & \\multicolumn{4}{c}{Timeliness (\\% paid $\\leq$ 14 days)} \\\\",
  "\\cmidrule(lr){2-5}",
  " & Full sample & Full sample & Thin states & Thick states \\\\",
  "\\midrule",
  sprintf("log(Initial claims) & %s%s & & %s%s & %s%s \\\\",
          fmt(iv1_b, 2), stars(iv1_p),
          fmt(iv_thin_b, 2), stars(iv_thin_p),
          fmt(iv_thick_b, 2), stars(iv_thick_p)),
  sprintf(" & (%s) & & (%s) & (%s) \\\\",
          fmt(iv1_se, 2), fmt(iv_thin_se, 2), fmt(iv_thick_se, 2)),
  " & & & & \\\\",
  sprintf("Claims per staff & & %s%s & & \\\\",
          fmt(iv2_b, 3), stars(iv2_p)),
  sprintf(" & & (%s) & & \\\\", fmt(iv2_se, 3)),
  "\\midrule",
  "Instrument & Bartik & Bartik & Bartik & Bartik \\\\",
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          fmt_int(nobs(iv1)), fmt_int(nobs(iv2)), fmt_int(nobs(iv_thin)), fmt_int(nobs(iv_thick))),
  sprintf("First-stage $F$ & %.1f & %.1f & %.1f & %.1f \\\\",
          fitstat(iv1, "ivf")$ivf1$stat, fitstat(iv2, "ivf")$ivf1$stat,
          fitstat(iv_thin, "ivf")$ivf1$stat, fitstat(iv_thick, "ivf")$ivf1$stat),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} 2SLS estimates. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The dependent variable is the share of intrastate UI first payments made within 14 days of the first compensable week. In columns (1), (3)--(4), the endogenous variable is log annual initial claims, instrumented by the Bartik predicted employment shock. Column (2) uses claims per state government staff member as the endogenous variable. Thin (thick) states are those below (above) the median of 2007 state government FTE per 1,000 private workers.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tab_dir, "tab3_main.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("=== Table 4: Robustness ===\n")

# LOO results
loo_df <- read_csv("../data/loo_results.csv", show_col_types = FALSE)

# Placebo
if (!is.null(placebo)) {
  placebo_b <- coef(placebo)["bartik_shock"]
  placebo_se <- se(placebo)["bartik_shock"]
  placebo_p <- pvalue(placebo)["bartik_shock"]
} else {
  placebo_b <- NA; placebo_se <- NA; placebo_p <- NA
}

# Alternative outcomes
alt7_b <- coef(alt_7d)["fit_log_claims"]; alt7_se <- se(alt_7d)["fit_log_claims"]; alt7_p <- pvalue(alt_7d)["fit_log_claims"]
alt21_b <- coef(alt_21d)["fit_log_claims"]; alt21_se <- se(alt_21d)["fit_log_claims"]; alt21_p <- pvalue(alt_21d)["fit_log_claims"]

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Coefficient & SE \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: Baseline (Table 3, Col. 1)}} \\\\",
  sprintf("\\quad log(Initial claims) & %s%s & (%s) \\\\",
          fmt(iv1_b, 2), stars(iv1_p), fmt(iv1_se, 2)),
  " & & \\\\",
  "\\multicolumn{3}{l}{\\textit{Panel B: Leave-one-industry-out}} \\\\"
)

for (i in 1:nrow(loo_df)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Drop %s & %s & (%s) \\\\",
            loo_df$dropped[i], fmt(loo_df$coef[i], 2), fmt(loo_df$se[i], 2)))
}

tab4_lines <- c(tab4_lines,
  " & & \\\\",
  "\\multicolumn{3}{l}{\\textit{Panel C: Alternative outcome thresholds (2SLS)}} \\\\",
  sprintf("\\quad 7-day timeliness & %s%s & (%s) \\\\", fmt(alt7_b, 2), stars(alt7_p), fmt(alt7_se, 2)),
  sprintf("\\quad 21-day timeliness & %s%s & (%s) \\\\", fmt(alt21_b, 2), stars(alt21_p), fmt(alt21_se, 2)),
  " & & \\\\",
  "\\multicolumn{3}{l}{\\textit{Panel D: Placebo (pre-recession, 2006--2007)}} \\\\"
)

if (!is.na(placebo_b)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Bartik shock (reduced form) & %s%s & (%s) \\\\",
            fmt(placebo_b, 1), stars(placebo_p), fmt(placebo_se, 1)))
} else {
  tab4_lines <- c(tab4_lines, "\\quad Insufficient pre-period data & --- & --- \\\\")
}

# WCB if available
if (!is.null(wcb)) {
  tab4_lines <- c(tab4_lines,
    " & & \\\\",
    "\\multicolumn{3}{l}{\\textit{Panel E: Wild cluster bootstrap}} \\\\",
    sprintf("\\quad 95\\%% CI & \\multicolumn{2}{c}{[%s, %s]} \\\\",
            fmt(wcb$ci_lower, 2), fmt(wcb$ci_upper, 2)),
    sprintf("\\quad $p$-value & \\multicolumn{2}{c}{%s} \\\\", fmt(wcb$p_value, 4)))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Panel A repeats the baseline 2SLS estimate. Panel B drops the highest-Rotemberg-weight industry and re-estimates. Panel C uses alternative timeliness thresholds (7-day, 21-day). Panel D runs the reduced form on pre-recession years only (placebo test). Panel E reports wild cluster bootstrap confidence intervals. All specifications include state and year fixed effects with standard errors clustered at the state level.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robust}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tab_dir, "tab4_robustness.tex"))

# ============================================================================
# Table 5 (Appendix): Standardized Effect Sizes
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Primary outcome: timeliness_14d
sd_y <- sd(panel$timeliness_14d)
sd_claims <- sd(panel$log_claims, na.rm = TRUE)

# Panel A: Pooled (IV estimate)
beta_iv <- coef(iv1)["fit_log_claims"]
se_iv <- se(iv1)["fit_log_claims"]
sde_iv <- beta_iv * sd_claims / sd_y  # continuous treatment
se_sde_iv <- se_iv * sd_claims / sd_y

# Panel B: Heterogeneous (thin vs thick)
beta_thin <- coef(iv_thin)["fit_log_claims"]
se_thin <- se(iv_thin)["fit_log_claims"]
sd_y_thin <- sd(panel$timeliness_14d[panel$thin_state == TRUE])
sd_claims_thin <- sd(panel$log_claims[panel$thin_state == TRUE], na.rm = TRUE)
sde_thin <- beta_thin * sd_claims_thin / sd_y_thin
se_sde_thin <- se_thin * sd_claims_thin / sd_y_thin

beta_thick <- coef(iv_thick)["fit_log_claims"]
se_thick <- se(iv_thick)["fit_log_claims"]
sd_y_thick <- sd(panel$timeliness_14d[panel$thin_state == FALSE])
sd_claims_thick <- sd(panel$log_claims[panel$thin_state == FALSE], na.rm = TRUE)
sde_thick <- beta_thick * sd_claims_thick / sd_y_thick
se_sde_thick <- se_thick * sd_claims_thick / sd_y_thick

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does recession-driven erosion of state administrative capacity cause delays in unemployment insurance first payments to workers? ",
  "\\textbf{Policy mechanism:} During the Great Recession, state UI agencies faced simultaneous demand surges (initial claims more than doubled nationally) and staffing constraints (hiring freezes, furloughs, and declining federal administrative funding), creating a capacity bottleneck that degraded payment processing speed. ",
  "\\textbf{Outcome definition:} First payment timeliness---the share of intrastate UI first payments made within 14 days of the first compensable week, from DOL Benefits Timeliness and Quality (BTQ) Category 1 reports. ",
  "\\textbf{Treatment:} Continuous---log annual initial UI claims, instrumented by a Bartik (shift-share) predicted employment shock constructed from 2006 industry employment shares and leave-one-out national industry growth. ",
  "\\textbf{Data:} DOL BTQ reports, Census QWI, Census ASPEP, DOL ETA 539; state-year panel, 2006--2012, 49 states, 343 observations. ",
  "\\textbf{Method:} 2SLS with Bartik instrument, state and year fixed effects, standard errors clustered at the state level; robustness via leave-one-industry-out and wild cluster bootstrap. ",
  "\\textbf{Sample:} 49 U.S.\\ states with complete BTQ timeliness data, ASPEP government employment, and QWI industry coverage for 2006--2012. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of log initial claims and SD($Y$) is the unconditional standard deviation of 14-day timeliness. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Timeliness ($\\leq$14d) & 2SLS, full sample & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_iv, 2), fmt(sd_claims, 2), fmt(sd_y, 1),
          fmt(sde_iv, 3), fmt(se_sde_iv, 3), classify(sde_iv)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (sample splits by pre-recession staffing)}} \\\\",
  sprintf("Timeliness ($\\leq$14d) & Thin states & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_thin, 2), fmt(sd_claims_thin, 2), fmt(sd_y_thin, 1),
          fmt(sde_thin, 3), fmt(se_sde_thin, 3), classify(sde_thin)),
  sprintf("Timeliness ($\\leq$14d) & Thick states & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_thick, 2), fmt(sd_claims_thick, 2), fmt(sd_y_thick, 1),
          fmt(sde_thick, 3), fmt(se_sde_thick, 3), classify(sde_thick)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tabF1_lines, file.path(tab_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat(paste("  ", list.files(tab_dir, pattern = "\\.tex$"), collapse = "\n"), "\n")
