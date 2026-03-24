# ============================================================
# 05_tables.R — Generate LaTeX tables
# apep_0874: Feeding the Supply Side
# ============================================================

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and results
panel <- readRDS(file.path(data_dir, "panel.rds"))
sumstats_table <- readRDS(file.path(data_dir, "sumstats_table.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
robust <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Helper: format numbers
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits, big.mark = ",")
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
fmt_se <- function(x, digits = 3) paste0("(", formatC(x, format = "f", digits = digits), ")")

# Helper: significance stars
stars <- function(pval) {
  if (is.na(pval)) return("")
  if (pval < 0.01) return("***")
  if (pval < 0.05) return("**")
  if (pval < 0.10) return("*")
  return("")
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

n_obs <- nrow(panel)
n_counties <- uniqueN(panel$fips)
n_quarters <- uniqueN(panel$yq)

tab1 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Variable & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule"
)

for (i in 1:nrow(sumstats_table)) {
  row <- sumstats_table[i, ]
  # Format based on variable type
  if (grepl("Population|income|stores", row$Variable, ignore.case = TRUE)) {
    line <- paste0(row$Variable, " & ", fmt(row$Mean, 1), " & ", fmt(row$SD, 1),
                   " & ", fmt(row$Min, 0), " & ", fmt(row$Max, 0), " \\\\")
  } else if (grepl("rate|Rate", row$Variable)) {
    line <- paste0(row$Variable, " & ", fmt(row$Mean, 3), " & ", fmt(row$SD, 3),
                   " & ", fmt(row$Min, 3), " & ", fmt(row$Max, 3), " \\\\")
  } else {
    line <- paste0(row$Variable, " & ", fmt(row$Mean, 2), " & ", fmt(row$SD, 2),
                   " & ", fmt(row$Min, 2), " & ", fmt(row$Max, 2), " \\\\")
  }
  tab1 <- c(tab1, line)
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item Notes: N = ", fmt_int(n_obs), " county-quarter observations from ",
         fmt_int(n_counties), " counties over ", n_quarters, " quarters (2016Q1--2024Q4). ",
         "Authorization rate is new SNAP retailer authorizations per 1,000 existing stores. ",
         "Treatment intensity is the county's ACS 2019 SNAP participation rate multiplied by \\$36.24 ",
         "(the per-person monthly benefit increase from the October 2021 Thrifty Food Plan revision). ",
         "Counties with fewer than 5 baseline stores are excluded."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))
cat("  Written tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

extract_coef <- function(mod, var = "did_continuous") {
  b <- coef(mod)[var]
  s <- se(mod)[var]
  p <- pvalue(mod)[var]
  list(b = b, se = s, p = p)
}

# Extract from each model
m1c <- extract_coef(results$m1_count)
m2c <- extract_coef(results$m2_count)
m3c <- extract_coef(results$m3_count)
m4c <- extract_coef(results$m4_count)
m1r <- extract_coef(results$m1_rate)
m2r <- extract_coef(results$m2_rate)
m3r <- extract_coef(results$m3_rate)
m4r <- extract_coef(results$m4_rate)

tab2 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of TFP Benefit Increase on New SNAP Retailer Authorizations}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: New authorizations (count)}} \\\\[3pt]",
  paste0("SNAP Rate $\\times$ Post & ",
         fmt(m1c$b, 4), stars(m1c$p), " & ",
         fmt(m2c$b, 4), stars(m2c$p), " & ",
         fmt(m3c$b, 4), stars(m3c$p), " & ",
         fmt(m4c$b, 4), stars(m4c$p), " \\\\"),
  paste0(" & ", fmt_se(m1c$se, 4), " & ", fmt_se(m2c$se, 4), " & ",
         fmt_se(m3c$se, 4), " & ", fmt_se(m4c$se, 4), " \\\\"),
  paste0("N & ", fmt_int(nobs(results$m1_count)), " & ", fmt_int(nobs(results$m2_count)),
         " & ", fmt_int(nobs(results$m3_count)), " & ", fmt_int(nobs(results$m4_count)), " \\\\"),
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Authorization rate (per 1,000 stores)}} \\\\[3pt]",
  paste0("SNAP Rate $\\times$ Post & ",
         fmt(m1r$b, 4), stars(m1r$p), " & ",
         fmt(m2r$b, 4), stars(m2r$p), " & ",
         fmt(m3r$b, 4), stars(m3r$p), " & ",
         fmt(m4r$b, 4), stars(m4r$p), " \\\\"),
  paste0(" & ", fmt_se(m1r$se, 4), " & ", fmt_se(m2r$se, 4), " & ",
         fmt_se(m3r$se, 4), " & ", fmt_se(m4r$se, 4), " \\\\"),
  paste0("N & ", fmt_int(nobs(results$m1_rate)), " & ", fmt_int(nobs(results$m2_rate)),
         " & ", fmt_int(nobs(results$m3_rate)), " & ", fmt_int(nobs(results$m4_rate)), " \\\\"),
  "\\midrule",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & --- & Yes \\\\",
  "State $\\times$ Quarter FE & --- & --- & Yes & --- \\\\",
  "EA control & --- & Yes & --- & Yes \\\\",
  "Demographic controls & --- & --- & --- & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item Notes: Standard errors clustered at county level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "The dependent variable in Panel A is the count of new SNAP retailer authorizations per county-quarter. ",
         "Panel B normalizes by baseline store count (per 1,000 existing stores). ",
         "The coefficient on SNAP Rate $\\times$ Post represents the differential change in new authorizations ",
         "for a one-unit increase in treatment intensity (county SNAP rate $\\times$ \\$36.24 monthly benefit increase). ",
         "Column (1): county and quarter FE. Column (2): adds EA active indicator. ",
         "Column (3): replaces quarter FE with state $\\times$ quarter FE (absorbs all state-level shocks including EA). ",
         "Column (4): adds poverty rate, percent Black, and log population interacted with post."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))
cat("  Written tab2_main.tex\n")

# ============================================================
# TABLE 3: Heterogeneity by Store Type
# ============================================================
cat("=== Table 3: Store Type Heterogeneity ===\n")

ms <- extract_coef(results$m5_super)
mc <- extract_coef(results$m5_conv)
ml <- extract_coef(results$m5_large)
mo <- extract_coef(results$m5_other)
m2c_all <- extract_coef(results$m2_count)

tab3 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Heterogeneity by Store Type}",
  "\\label{tab:storetype}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & All Types & Supermarkets & Convenience & Large Grocery \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  paste0("SNAP Rate $\\times$ Post & ",
         fmt(m2c_all$b, 4), stars(m2c_all$p), " & ",
         fmt(ms$b, 4), stars(ms$p), " & ",
         fmt(mc$b, 4), stars(mc$p), " & ",
         fmt(ml$b, 4), stars(ml$p), " \\\\"),
  paste0(" & ", fmt_se(m2c_all$se, 4), " & ", fmt_se(ms$se, 4), " & ",
         fmt_se(mc$se, 4), " & ", fmt_se(ml$se, 4), " \\\\"),
  paste0("Mean Dep.\\ Var. & ", fmt(mean(panel$new_auths), 2), " & ",
         fmt(mean(panel$new_supermarket), 2), " & ",
         fmt(mean(panel$new_convenience), 2), " & ",
         fmt(mean(panel$new_large), 2), " \\\\"),
  paste0("N & ", fmt_int(nobs(results$m2_count)), " & ", fmt_int(nobs(results$m5_super)),
         " & ", fmt_int(nobs(results$m5_conv)), " & ", fmt_int(nobs(results$m5_large)), " \\\\"),
  "\\midrule",
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\",
  "EA control & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item Notes: Standard errors clustered at county level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "Dependent variable is the count of new SNAP retailer authorizations by store type per county-quarter. ",
         "Supermarkets include stores classified as ``Super Store'' or ``Supermarket'' in the USDA database. ",
         "Convenience includes ``Small Grocery Store'' and ``Convenience Store.'' ",
         "Large Grocery includes ``Medium Grocery Store,'' ``Large Grocery Store,'' ``Combination Grocery/Other,'' and ``Warehouse Food Store.'' ",
         "All specifications include county and quarter fixed effects plus an EA active indicator."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3, file.path(tables_dir, "tab3_storetype.tex"))
cat("  Written tab3_storetype.tex\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

# Placebo
rp_c <- extract_coef(robust$placebo_count, "did_placebo")
rp_r <- extract_coef(robust$placebo_rate, "did_placebo")
# No early EA
rne_c <- extract_coef(robust$no_early_count)
rne_r <- extract_coef(robust$no_early_rate)
# Poverty treatment
rpov_c <- extract_coef(robust$poverty_count, "did_poverty")
rpov_r <- extract_coef(robust$poverty_rate, "did_poverty")
# Weighted
rwt_c <- extract_coef(robust$weighted_count)
rwt_r <- extract_coef(robust$weighted_rate)
# Post-EA
if (!is.null(robust$post_ea_count)) {
  rpea_c <- extract_coef(robust$post_ea_count, "did_clean")
  rpea_r <- extract_coef(robust$post_ea_rate, "did_clean")
} else {
  rpea_c <- list(b = NA, se = NA, p = NA)
  rpea_r <- list(b = NA, se = NA, p = NA)
}

format_cell <- function(est) {
  if (is.na(est$b)) return("---")
  paste0(fmt(est$b, 4), stars(est$p))
}
format_se_cell <- function(est) {
  if (is.na(est$se)) return("")
  fmt_se(est$se, 4)
}

tab4 <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Baseline & Placebo & Excl.\\ Early & Post-EA & Pop.-Weighted \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: New authorizations (count)}} \\\\[3pt]",
  paste0("Treatment $\\times$ Post & ",
         format_cell(m2c), " & ", format_cell(rp_c), " & ",
         format_cell(rne_c), " & ", format_cell(rpea_c), " & ",
         format_cell(rwt_c), " \\\\"),
  paste0(" & ", format_se_cell(m2c), " & ", format_se_cell(rp_c), " & ",
         format_se_cell(rne_c), " & ", format_se_cell(rpea_c), " & ",
         format_se_cell(rwt_c), " \\\\"),
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Authorization rate (per 1,000 stores)}} \\\\[3pt]",
  paste0("Treatment $\\times$ Post & ",
         format_cell(m2r), " & ", format_cell(rp_r), " & ",
         format_cell(rne_r), " & ", format_cell(rpea_r), " & ",
         format_cell(rwt_r), " \\\\"),
  paste0(" & ", format_se_cell(m2r), " & ", format_se_cell(rp_r), " & ",
         format_se_cell(rne_r), " & ", format_se_cell(rpea_r), " & ",
         format_se_cell(rwt_r), " \\\\"),
  "\\midrule",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "EA control & Yes & Yes & Yes & --- & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item Notes: Standard errors clustered at county level in parentheses. ",
         "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
         "Column (1): preferred specification from Table~\\ref{tab:main}. ",
         "Column (2): placebo test with fake treatment date of 2019Q4 using only pre-TFP data. ",
         "Column (3): excludes 18 states that ended Emergency Allotments before universal termination. ",
         "Column (4): restricts post-period to 2023Q2+ when all EA had ended, isolating the permanent TFP effect. ",
         "Column (5): population-weighted regression."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))
cat("  Written tab4_robustness.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Main outcome: new authorizations (count)
beta_count <- coef(results$m2_count)["did_continuous"]
se_count <- se(results$m2_count)["did_continuous"]
sd_y_count <- sd(panel$new_auths, na.rm = TRUE)
sd_x <- sd(panel$did_continuous[panel$did_continuous > 0], na.rm = TRUE)
# For continuous treatment: SDE = beta * SD(X) / SD(Y)
if (is.na(sd_x) || sd_x == 0) sd_x <- sd(panel$treatment_intensity, na.rm = TRUE)
sde_count <- beta_count * sd_x / sd_y_count
se_sde_count <- se_count * sd_x / sd_y_count

# Main outcome: authorization rate
beta_rate <- coef(results$m2_rate)["did_continuous"]
se_rate <- se(results$m2_rate)["did_continuous"]
sd_y_rate <- sd(panel$auth_rate, na.rm = TRUE)
sde_rate <- beta_rate * sd_x / sd_y_rate
se_sde_rate <- se_rate * sd_x / sd_y_rate

# Recreate grouping variables for SD calculations
panel[, high_snap := as.integer(snap_rate > median(snap_rate, na.rm = TRUE))]
panel[, urban := as.integer(population > 50000)]

# Heterogeneity: High-SNAP counties
beta_high <- coef(results$m_high)["did_continuous"]
se_high <- se(results$m_high)["did_continuous"]
sd_y_high <- sd(panel[high_snap == 1]$new_auths, na.rm = TRUE)
sd_x_high <- sd(panel[high_snap == 1]$treatment_intensity, na.rm = TRUE)
sde_high <- beta_high * sd_x_high / sd_y_high
se_sde_high <- se_high * sd_x_high / sd_y_high

# Heterogeneity: Urban counties
beta_urban <- coef(results$m_urban)["did_continuous"]
se_urban <- se(results$m_urban)["did_continuous"]
sd_y_urban <- sd(panel[urban == 1]$new_auths, na.rm = TRUE)
sd_x_urban <- sd(panel[urban == 1]$treatment_intensity, na.rm = TRUE)
sde_urban <- beta_urban * sd_x_urban / sd_y_urban
se_sde_urban <- se_urban * sd_x_urban / sd_y_urban

# Classification
classify <- function(s) {
  if (is.na(s)) return("---")
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

sde_tab <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llccccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  paste0("New auths (count) & Preferred & ", fmt(beta_count, 4), " & ", fmt(sd_x, 2),
         " & ", fmt(sd_y_count, 2), " & ", fmt(sde_count, 4), " & ", fmt(se_sde_count, 4),
         " & ", classify(sde_count), " \\\\"),
  paste0("Auth rate (per 1k) & Preferred & ", fmt(beta_rate, 4), " & ", fmt(sd_x, 2),
         " & ", fmt(sd_y_rate, 2), " & ", fmt(sde_rate, 4), " & ", fmt(se_sde_rate, 4),
         " & ", classify(sde_rate), " \\\\"),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  paste0("New auths (count) & High-SNAP counties & ", fmt(beta_high, 4), " & ", fmt(sd_x_high, 2),
         " & ", fmt(sd_y_high, 2), " & ", fmt(sde_high, 4), " & ", fmt(se_sde_high, 4),
         " & ", classify(sde_high), " \\\\"),
  paste0("New auths (count) & Urban counties & ", fmt(beta_urban, 4), " & ", fmt(sd_x_urban, 2),
         " & ", fmt(sd_y_urban, 2), " & ", fmt(sde_urban, 4), " & ", fmt(se_sde_urban, 4),
         " & ", classify(sde_urban), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes.",
  "For continuous treatments, SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$, which gives the effect of a one-standard-deviation change in the treatment variable, measured in standard deviations of the outcome.",
  "SD($Y$) and SD($X$) are unconditional standard deviations from the summary statistics (Table~\\ref{tab:summary}), before conditioning on fixed effects.",
  "",
  "\\textbf{Country:} United States.",
  "\\textbf{Research question:} Whether the permanent 21\\% increase in SNAP benefits from the October 2021 Thrifty Food Plan revision attracted new food retailers to counties with high SNAP participation.",
  "\\textbf{Policy mechanism:} The Thrifty Food Plan revision permanently raised maximum SNAP benefits by 21\\%, injecting approximately \\$36 billion per year in additional food purchasing power to 42 million SNAP recipients, with larger per-capita shocks in counties with higher SNAP participation rates.",
  "\\textbf{Outcome definition:} Quarterly count of new SNAP retailer authorizations per county from the USDA SNAP Retailer Historical Database, measuring food store entry into the SNAP program.",
  "\\textbf{Treatment:} Continuous; county-level treatment intensity equals the ACS 2019 SNAP household participation rate multiplied by the per-person monthly benefit increase (\\$36.24), measured in dollars per person per month.",
  "\\textbf{Data:} USDA SNAP Retailer Historical Database (703,000 stores, 2005--2025) merged with ACS 2019 5-year county estimates; county-quarter panel from 2016Q1 to 2024Q4.",
  "\\textbf{Method:} Continuous difference-in-differences with county and quarter fixed effects, controlling for Emergency Allotment status; standard errors clustered at county level.",
  "\\textbf{Sample:} U.S. counties with at least 5 baseline SNAP-authorized stores and non-missing ACS SNAP participation data.",
  "",
  "Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$).",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}"
)

writeLines(sde_tab, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Written tabF1_sde.tex\n")

cat("\n=== All Tables Complete ===\n")
