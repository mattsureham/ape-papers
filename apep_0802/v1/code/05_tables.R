## 05_tables.R — Generate all tables (including SDE)
## apep_0802

source("00_packages.R")

panel_A <- readRDS("../data/panel_A.rds")
panel_B <- readRDS("../data/panel_B.rds")

## Load regression results
did_simple  <- readRDS("../data/did_simple.rds")
did_dosage  <- readRDS("../data/did_dosage.rds")
did_ta      <- readRDS("../data/did_ta.rds")
rob_no_auck <- readRDS("../data/rob_no_auck.rds")
rob_poisson <- readRDS("../data/rob_poisson.rds")
rob_log     <- readRDS("../data/rob_log.rds")

## ========================================================================
## TABLE 1: Summary Statistics
## ========================================================================

# Panel A stats
pre_A <- panel_A[date < as.Date("2021-10-01")]
houses_pre <- pre_A[dwelling_type == "Houses"]
multi_pre  <- pre_A[dwelling_type == "Multi-unit"]

post_A <- panel_A[date >= as.Date("2021-10-01") & date < as.Date("2024-04-01")]
rev_A  <- panel_A[date >= as.Date("2024-04-01")]

# Build summary table
sum_rows <- data.table(
  Variable = c(
    "\\textit{Panel A: Building consents by dwelling type (16 regions, monthly)}",
    "Houses (monthly consents per region)", "", "", "",
    "Multi-unit (monthly consents per region)", "", "", "",
    "Multi-unit share of total", "", "",
    "\\textit{Panel B: Building consents by TA (monthly)}",
    "Consents per TA-month", "",
    "Active rental bonds per 1,000 pop. (Oct 2020)", "",
    "Number of regions", "Number of TAs", "Number of months (Panel A)",
    "Number of months (Panel B)"
  ),
  Statistic = c(
    "", "Mean", "Std. Dev.", "Min", "Max",
    "Mean", "Std. Dev.", "Min", "Max",
    "Pre-policy", "Treatment", "Post-reversal",
    "", "Mean", "Std. Dev.",
    "Mean", "Std. Dev.",
    "", "", "", ""
  ),
  Value = c(
    "",
    sprintf("%.1f", mean(houses_pre$consents)),
    sprintf("%.1f", sd(houses_pre$consents)),
    sprintf("%d", min(houses_pre$consents)),
    sprintf("%d", max(houses_pre$consents)),
    sprintf("%.1f", mean(multi_pre$consents)),
    sprintf("%.1f", sd(multi_pre$consents)),
    sprintf("%d", min(multi_pre$consents)),
    sprintf("%d", max(multi_pre$consents)),
    sprintf("%.3f", sum(pre_A[dwelling_type == "Multi-unit"]$consents) /
              (sum(pre_A[dwelling_type == "Multi-unit"]$consents) +
                 sum(pre_A[dwelling_type == "Houses"]$consents))),
    sprintf("%.3f", sum(post_A[dwelling_type == "Multi-unit"]$consents) /
              (sum(post_A[dwelling_type == "Multi-unit"]$consents) +
                 sum(post_A[dwelling_type == "Houses"]$consents))),
    sprintf("%.3f", sum(rev_A[dwelling_type == "Multi-unit"]$consents) /
              (sum(rev_A[dwelling_type == "Multi-unit"]$consents) +
                 sum(rev_A[dwelling_type == "Houses"]$consents))),
    "",
    sprintf("%.1f", mean(panel_B$consents, na.rm = TRUE)),
    sprintf("%.1f", sd(panel_B$consents, na.rm = TRUE)),
    sprintf("%.1f", mean(unique(panel_B[, .(ta_id, bonds_per_1k)])$bonds_per_1k, na.rm = TRUE)),
    sprintf("%.1f", sd(unique(panel_B[, .(ta_id, bonds_per_1k)])$bonds_per_1k, na.rm = TRUE)),
    sprintf("%d", uniqueN(panel_A$region)),
    sprintf("%d", uniqueN(panel_B$ta)),
    sprintf("%d", uniqueN(panel_A$ym)),
    sprintf("%d", uniqueN(panel_B$ym))
  )
)

# Write LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{llr}\n")
cat("\\toprule\n")
cat("Variable & Statistic & Value \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(sum_rows))) {
  r <- sum_rows[i]
  if (grepl("Panel", r$Variable)) {
    cat("\\midrule\n")
    cat("\\multicolumn{3}{l}{", r$Variable, "} \\\\\n")
  } else if (r$Statistic == "" & r$Value == "") {
    next
  } else {
    cat(r$Variable, " & ", r$Statistic, " & ", r$Value, " \\\\\n")
  }
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()
cat("✓ Table 1 written\n")

## ========================================================================
## TABLE 2: Main Results — Dwelling-type DiD
## ========================================================================

etable(did_simple, did_dosage, rob_no_auck,
       headers = c("Simple DiD", "Dosage DiD", "Excl. Auckland"),
       tex = TRUE,
       style.tex = style.tex("aer"),
       fitstat = c("n", "r2", "ar2"),
       file = "../tables/tab2_main_results.tex", replace = TRUE,
       title = "The Effect of Mortgage Interest Deductibility Removal on Building Consents",
       label = "tab:main",
       notes = "Standard errors clustered at the region level in parentheses. The dependent variable is monthly building consents. Multi-unit includes apartments, townhouses, and flats. The treatment period is October 2021--March 2024 (deductibility removal phase-out). The reversal period begins April 2024 (deductibility restoration). The new-build premium equals the percentage-point tax advantage of new builds over existing rental properties.")
cat("✓ Table 2 written\n")

## ========================================================================
## TABLE 3: Cross-TA Results
## ========================================================================

etable(did_ta,
       headers = "Cross-TA DiD",
       tex = TRUE,
       style.tex = style.tex("aer"),
       fitstat = c("n", "r2"),
       file = "../tables/tab3_cross_ta.tex", replace = TRUE,
       title = "Cross-TA Rental Intensity and Building Consents",
       label = "tab:cross_ta",
       notes = "Standard errors clustered at the TA level. Exposure is standardized pre-reform (October 2020) active rental bonds per 1,000 population.")
cat("✓ Table 3 written\n")

## ========================================================================
## TABLE 4: Robustness Checks
## ========================================================================

etable(did_simple, rob_poisson, rob_log,
       headers = c("OLS (baseline)", "Poisson", "Log(consents+1)"),
       tex = TRUE,
       style.tex = style.tex("aer"),
       fitstat = c("n", "r2"),
       file = "../tables/tab4_robustness.tex", replace = TRUE,
       title = "Robustness: Alternative Functional Forms",
       label = "tab:robustness",
       notes = "All specifications include region $\\times$ dwelling-type and month fixed effects. Standard errors clustered at the region level.")
cat("✓ Table 4 written\n")

## ========================================================================
## TABLE F1: Standardized Effect Size (SDE) — MANDATORY
## ========================================================================

# Get main coefficients from simple DiD
coef_post <- coef(did_simple)["multi:post"]
se_post <- sqrt(vcov(did_simple)["multi:post", "multi:post"])

coef_rev <- coef(did_simple)["multi:reversal"]
se_rev <- sqrt(vcov(did_simple)["multi:reversal", "multi:reversal"])

# SD of outcome (multi-unit consents) in pre-period
sd_y_pre <- sd(panel_A[dwelling_type == "Multi-unit" &
                         date < as.Date("2021-10-01")]$consents)

# SDE = beta / SD(Y)
sde_post <- coef_post / sd_y_pre
sde_se_post <- se_post / sd_y_pre

sde_rev <- coef_rev / sd_y_pre
sde_se_rev <- se_rev / sd_y_pre

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Also compute for dosage specification
coef_dosage <- coef(did_dosage)["multi:new_build_premium"]
se_dosage <- sqrt(vcov(did_dosage)["multi:new_build_premium", "multi:new_build_premium"])
# For continuous treatment: SDE = beta × SD(X) / SD(Y)
sd_premium <- sd(panel_A[date >= as.Date("2021-10-01") &
                           date < as.Date("2024-04-01")]$new_build_premium)
sde_dosage <- coef_dosage * sd_premium / sd_y_pre
sde_se_dosage <- se_dosage * sd_premium / sd_y_pre

# Build SDE table
sde_rows <- data.table(
  Outcome = c(
    "Multi-unit consents (treatment period)",
    "Multi-unit consents (reversal period)",
    "Multi-unit consents (dosage)"
  ),
  Beta = c(coef_post, coef_rev, coef_dosage),
  SE = c(se_post, se_rev, se_dosage),
  SD_Y = c(sd_y_pre, sd_y_pre, sd_y_pre),
  SDE = c(sde_post, sde_rev, sde_dosage),
  SE_SDE = c(sde_se_post, sde_se_rev, sde_se_dosage),
  Classification = c(classify_sde(sde_post), classify_sde(sde_rev),
                     classify_sde(sde_dosage))
)

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} New Zealand. ",
  "\\textbf{Research question:} Does removing mortgage interest deductibility for existing ",
  "rental properties while exempting new builds shift housing construction toward ",
  "multi-unit dwellings? ",
  "\\textbf{Policy mechanism:} The Taxation (Annual Rates for 2021--22) Act phased out mortgage ",
  "interest deductions for existing rental properties from October 2021 (100\\% to 0\\% by April 2024) ",
  "while granting 20-year full deductibility to properties with Code Compliance Certificates issued ",
  "after 27 March 2020, creating a tax wedge favoring new construction over existing rental stock. ",
  "\\textbf{Outcome definition:} Monthly count of new dwelling building consents by dwelling type ",
  "(multi-unit: apartments, townhouses, flats) from Stats NZ Building Consents Issued series. ",
  "\\textbf{Treatment:} Binary (pre/post October 2021) and continuous (new-build premium: ",
  "percentage-point deductibility advantage of new builds, varying 0--0.75 across policy phases). ",
  "\\textbf{Data:} Stats NZ Building Consents Issued, monthly, 16 regions $\\times$ 2 dwelling types, ",
  "January 2021--January 2026, $N = ", nrow(panel_A), "$. ",
  "\\textbf{Method:} Two-way fixed effects DiD (region $\\times$ dwelling-type and month FE), ",
  "standard errors clustered at the region level. ",
  "\\textbf{Sample:} All 16 New Zealand regions; multi-unit (apartments, townhouses, flats) versus ",
  "houses as within-region control. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of multi-unit consents. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i]
  cat(sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\\n",
              r$Outcome, r$Beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{itemize}[leftmargin=*,nosep]\n")
cat(sde_notes, "\n")
cat("\\end{itemize}\n")
cat("\\end{table}\n")
sink()
cat("✓ Table F1 (SDE) written\n")

cat("\n✓ All tables generated.\n")
