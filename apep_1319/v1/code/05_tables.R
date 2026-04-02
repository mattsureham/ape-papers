# 05_tables.R — SDE Table for apep_1319
# Standardized effect sizes for ASB toolkit consolidation

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# Load main and robustness results
main <- readRDS(file.path(data_dir, "main_results.rds"))
df <- main$df
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================================
# Standardized Effect Sizes
# ============================================================================

cat("=== Computing Standardized Effect Sizes ===\n")

# Pre-reform standard deviations
pre_sd_asb <- sd(df[post == 0]$asb_rate, na.rm = TRUE)
pre_sd_burglary <- sd(df[post == 0]$burglary_rate, na.rm = TRUE)
pre_sd_log_asb <- sd(df[post == 0]$log_asb_rate, na.rm = TRUE)

# Main outcome: ASB rate (standardized treatment)
# For continuous treatment with standardized X: SDE = beta / SD(Y)
# Beta already represents 1-SD change in treatment
beta_main <- coef(main$m1)["post_asbo_std"]
se_main <- sqrt(vcov(main$m1)["post_asbo_std", "post_asbo_std"])

sde_main <- beta_main / pre_sd_asb
se_sde_main <- se_main / pre_sd_asb

# Log outcome
beta_log <- coef(main$m3)["post_asbo_std"]
se_log <- sqrt(vcov(main$m3)["post_asbo_std", "post_asbo_std"])
sde_log <- beta_log / pre_sd_log_asb
se_sde_log <- se_log / pre_sd_log_asb

# Placebo: burglary rate
beta_placebo <- coef(rob$m_placebo)["post_asbo_std"]
se_placebo <- sqrt(vcov(rob$m_placebo)["post_asbo_std", "post_asbo_std"])
sde_placebo <- beta_placebo / pre_sd_burglary
se_sde_placebo <- se_placebo / pre_sd_burglary

# Classification function
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

cat(sprintf("Main SDE: %.4f (%s)\n", sde_main, classify_sde(sde_main)))
cat(sprintf("Log SDE: %.4f (%s)\n", sde_log, classify_sde(sde_log)))
cat(sprintf("Placebo SDE: %.4f (%s)\n", sde_placebo, classify_sde(sde_placebo)))

# ============================================================================
# Panel B: Heterogeneity (sample splits)
# ============================================================================

# Split 1: Urban vs rural forces (using population as proxy)
median_pop <- median(df[, first(population_2014), by = cjs_area]$V1)
df[, urban := as.integer(population_2014 >= median_pop)]

m_urban <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
                 data = df[urban == 1], cluster = ~cjs_area)
m_rural <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
                 data = df[urban == 0], cluster = ~cjs_area)

pre_sd_urban <- sd(df[post == 0 & urban == 1]$asb_rate, na.rm = TRUE)
pre_sd_rural <- sd(df[post == 0 & urban == 0]$asb_rate, na.rm = TRUE)

beta_urban <- coef(m_urban)["post_asbo_std"]
se_urban <- sqrt(vcov(m_urban)["post_asbo_std", "post_asbo_std"])
sde_urban <- beta_urban / pre_sd_urban
se_sde_urban <- se_urban / pre_sd_urban

beta_rural <- coef(m_rural)["post_asbo_std"]
se_rural <- sqrt(vcov(m_rural)["post_asbo_std", "post_asbo_std"])
sde_rural <- beta_rural / pre_sd_rural
se_sde_rural <- se_rural / pre_sd_rural

cat(sprintf("Urban SDE: %.4f (%s)\n", sde_urban, classify_sde(sde_urban)))
cat(sprintf("Rural SDE: %.4f (%s)\n", sde_rural, classify_sde(sde_rural)))

# ============================================================================
# Write SDE Table (tabF1_sde.tex)
# ============================================================================

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England and Wales). ",
  "\\textbf{Research question:} Does consolidating fragmented anti-social behaviour enforcement tools ",
  "into a streamlined framework reduce disorder, and do areas most reliant on the old toolkit experience the largest disruption? ",
  "\\textbf{Policy mechanism:} The Anti-Social Behaviour, Crime and Policing Act 2014 replaced 19 enforcement ",
  "tools (including ASBOs, dispersal orders, and crack house closures) with 6 streamlined powers, requiring ",
  "police forces to retrain staff, revise protocols, and adopt unfamiliar legal instruments. ",
  "\\textbf{Outcome definition:} Monthly anti-social behaviour incidents per 100,000 population from data.police.uk, ",
  "covering all police-recorded ASB incidents by force area. ",
  "\\textbf{Treatment:} Continuous; pre-reform cumulative ASBO issuance rate per 100,000 population (1999--2013), ",
  "standardized to mean zero and unit variance. ",
  "\\textbf{Data:} UK Police API (data.police.uk), May 2013--December 2019; Home Office ASBO Statistics 1999--2013; ",
  "ONS mid-2014 population estimates. 42 police force areas observed monthly. ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with force area and year-month fixed effects. ",
  "Standard errors clustered by police force area; permutation inference (1,000 draws) as supplementary check. ",
  "\\textbf{Sample:} All 42 police force areas in England and Wales; October 2014 excluded as partial treatment month. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("ASB rate per 100k & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_main, se_main, pre_sd_asb, sde_main, se_sde_main, classify_sde(sde_main)))
cat(sprintf("Log ASB rate & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta_log, se_log, pre_sd_log_asb, sde_log, se_sde_log, classify_sde(sde_log)))
cat(sprintf("Burglary rate (placebo) & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_placebo, se_placebo, pre_sd_burglary, sde_placebo, se_sde_placebo, classify_sde(sde_placebo)))
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\\n")
cat(sprintf("Urban forces & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_urban, se_urban, pre_sd_urban, sde_urban, se_sde_urban, classify_sde(sde_urban)))
cat(sprintf("Rural forces & %.3f & %.3f & %.1f & %.4f & %.4f & %s \\\\\n",
            beta_rural, se_rural, pre_sd_rural, sde_rural, se_sde_rural, classify_sde(sde_rural)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("SDE table (tabF1_sde.tex) saved.\n")
cat("All tables complete.\n")
