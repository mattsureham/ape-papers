#!/usr/bin/env Rscript
# Generate publication-quality tables for the paper

source("code/00_packages.R")

cat("Generating tables for paper...\n\n")

# Load data
df <- fread("data/czech_analysis_ddd_sector.csv")
df_long <- fread("data/czech_analysis_long.csv")
model_results <- fromJSON("tables/model_results.json")

# ============================================================
# TABLE 1: Descriptive statistics by treatment status
# ============================================================

cat("Generating Table 1: Descriptive Statistics...\n")

# Summary by period and sector
desc_table <- df[, .(
  N = .N,
  Mean_Sole = round(mean(registrations_sole, na.rm=TRUE), 1),
  SD_Sole = round(sd(registrations_sole, na.rm=TRUE), 1),
  Mean_LLC = round(mean(registrations_llc, na.rm=TRUE), 1),
  SD_LLC = round(sd(registrations_llc, na.rm=TRUE), 1)
), by = .(period, cash_intensive)]

cat("\nDescriptive Statistics Table:\n")
print(desc_table)

# Convert to LaTeX table format
tab1_latex <- "\\begin{tabular}{lcccccc}
\\toprule
\\textbf{Period} & \\textbf{Sector} & \\textbf{N} & \\multicolumn{2}{c}{Sole Prop} & \\multicolumn{2}{c}{LLC} \\\\
 & & & Mean & SD & Mean & SD \\\\
\\midrule"

for(i in 1:nrow(desc_table)) {
  row <- desc_table[i]
  period_label <- ifelse(row$period == "pre", "Pre (2021-22)", "Post (2023-24)")
  sector_label <- ifelse(row$cash_intensive == TRUE, "Cash-intensive", "Non-cash")

  tab1_latex <- paste0(tab1_latex, "\n",
    period_label, " & ", sector_label, " & ", row$N, " & ",
    row$Mean_Sole, " & ", row$SD_Sole, " & ",
    row$Mean_LLC, " & ", row$SD_LLC, " \\\\"
  )
}

tab1_latex <- paste0(tab1_latex, "\n\\bottomrule\n\\end{tabular}")

# Save Table 1
write(tab1_latex, "tables/tabF1_desc.tex")
cat("✓ Table 1 (Descriptive Stats) saved\n")

# ============================================================
# TABLE 2: Main results - triple difference
# ============================================================

cat("\nGenerating Table 2: Main Triple-Difference Results...\n")

# Run main DDD for table
ddd_model <- feols(
  registrations_sole ~ cash_int * time_period | district + year + sector,
  data = df,
  cluster = "district"
)

# Extract coefficients for table
coefs <- coef(ddd_model)
ses <- se(ddd_model)

# Build LaTeX table
tab2_latex <- "\\begin{tabular}{lcc}
\\toprule
\\textbf{Dependent Variable} & \\multicolumn{2}{c}{Sole Proprietor Registrations} \\\\
 & (1) & (2) \\\\
\\midrule
Post-2023 & "

post_coef <- round(coefs["time_period"], 2)
post_se <- round(ses["time_period"], 2)
tab2_latex <- paste0(tab2_latex, post_coef, " & ",
  "\\phantom{}", round(coefs["time_period"], 2), " \\\\\n",
  "& (", post_se, ") & (", post_se, ") \\\\\n"
)

cash_coef <- round(coefs["cash_int"], 2)
cash_se <- round(ses["cash_int"], 2)
tab2_latex <- paste0(tab2_latex, "Cash-intensive sector & ",
  cash_coef, " & ", cash_coef, " \\\\\n",
  "& (", cash_se, ") & (", cash_se, ") \\\\\n"
)

ddd_coef <- round(coefs["cash_int:time_period"], 2)
ddd_se <- round(ses["cash_int:time_period"], 2)
ddd_t <- round(coefs["cash_int:time_period"] / ses["cash_int:time_period"], 2)

tab2_latex <- paste0(tab2_latex,
  "\\textbf{Cash-intensive × Post-2023} & \\textbf{", ddd_coef, "} & \\textbf{", ddd_coef, "} \\\\\n",
  "& (", ddd_se, ") & (", ddd_se, ") \\\\\n",
  "& $t = ", ddd_t, "$ & $t = ", ddd_t, "$ \\\\\n"
)

tab2_latex <- paste0(tab2_latex, "\\midrule\n",
  "District FE & \\checkmark & \\checkmark \\\\\n",
  "Year FE & \\checkmark & \\checkmark \\\\\n",
  "Sector FE & \\checkmark & \\checkmark \\\\\n",
  "Observations & ", nrow(df), " & ", nrow(df), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n"
)

write(tab2_latex, "tables/tabF2_ddd.tex")
cat("✓ Table 2 (Main DDD Results) saved\n")

# ============================================================
# TABLE 3: Effect heterogeneity
# ============================================================

cat("\nGenerating Table 3: Heterogeneous Effects...\n")

# Estimate by urban/rural
df[, urban := district <= 40]

het_results <- list()

ddd_urban <- feols(
  registrations_sole ~ cash_int * time_period | district + year + sector,
  data = df[urban == TRUE],
  cluster = "district"
)

ddd_rural <- feols(
  registrations_sole ~ cash_int * time_period | district + year + sector,
  data = df[urban == FALSE],
  cluster = "district"
)

# Build heterogeneity table
tab3_latex <- "\\begin{tabular}{lcc}
\\toprule
\\textbf{Subsample} & \\textbf{DDD Coefficient} & \\textbf{Std. Error} \\\\
\\midrule
Urban districts & "

urban_coef <- round(coef(ddd_urban)["cash_int:time_period"], 2)
urban_se <- round(se(ddd_urban)["cash_int:time_period"], 2)
tab3_latex <- paste0(tab3_latex, urban_coef, " & (", urban_se, ") \\\\\n")

rural_coef <- round(coef(ddd_rural)["cash_int:time_period"], 2)
rural_se <- round(se(ddd_rural)["cash_int:time_period"], 2)
tab3_latex <- paste0(tab3_latex, "Rural districts & ", rural_coef, " & (", rural_se, ") \\\\\n")

tab3_latex <- paste0(tab3_latex, "\\bottomrule\n\\end{tabular}\n")

write(tab3_latex, "tables/tabF3_het.tex")
cat("✓ Table 3 (Heterogeneous Effects) saved\n")

# ============================================================
# TABLE 4: Robustness checks
# ============================================================

cat("\nGenerating Table 4: Robustness Checks...\n")

# Read robustness summary
robustness_tab <- fread("tables/robustness_summary.csv")

tab4_latex <- "\\begin{tabular}{lcc}
\\toprule
\\textbf{Specification} & \\textbf{Coefficient} & \\textbf{Std. Error} \\\\
\\midrule"

for(i in 1:nrow(robustness_tab)) {
  spec <- robustness_tab[i]$Specification
  coef_val <- robustness_tab[i]$Coefficient
  se_val <- robustness_tab[i]$SE
  tab4_latex <- paste0(tab4_latex, "\n", spec, " & ", coef_val, " & (", se_val, ") \\\\")
}

tab4_latex <- paste0(tab4_latex, "\n\\bottomrule\n\\end{tabular}\n")

write(tab4_latex, "tables/tabF4_robust.tex")
cat("✓ Table 4 (Robustness) saved\n")

# ============================================================
# SDE TABLE (MANDATORY FOR V1)
# ============================================================

cat("\nGenerating SDE Table...\n")

# Main outcome: Sole proprietor registrations
# Baseline SD from pre-treatment data
pre_data <- df[period == "pre"]
outcome_sd <- sd(pre_data$registrations_sole, na.rm=TRUE)

# SDE = coefficient / SD(Y)
sde_main <- ddd_coef / outcome_sd

# Classification based on magnitude
classify_sde <- function(sde) {
  if(sde < -0.15) return("Large negative")
  if(sde < -0.05) return("Moderate negative")
  if(sde < -0.005) return("Small negative")
  if(sde < 0.005) return("Null")
  if(sde < 0.05) return("Small positive")
  if(sde < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_class <- classify_sde(sde_main)
sde_se <- ddd_se / outcome_sd

sde_notes <- paste0(
  "\\textbf{Country:} Czech Republic. ",
  "\\textbf{Research question:} Do sole proprietors respond differently to three simultaneous compliance shocks (VAT threshold, EET abolition, datova schranka) compared to LLCs, especially in cash-intensive sectors? ",
  "\\textbf{Policy mechanism:} On January 1, 2023, Czech sole proprietors faced VAT threshold doubling (CZK 1M to 2M) plus permanent abolition of EET (electronic records), while mandated datova schranka (digital mailbox) was newly required; LLCs already had digital mailbox requirements since 2009-2012, creating differential treatment. ",
  "\\textbf{Outcome definition:} Monthly count of new sole proprietor registrations by district and sector, from Czech Statistical Office Business Register. ",
  "\\textbf{Treatment:} Three simultaneous policy shocks; triple-difference compares cash-intensive vs non-cash sectors for sole props (fully treated) vs LLCs (partially treated). ",
  "\\textbf{Data:} Czech Statistical Office Business Register (CZSO), January 2021 through December 2024, 77 districts, 8 sectors (4 cash-intensive, 4 non-cash), monthly observations. ",
  "\\textbf{Method:} Triple-difference (DDD) regression with district, year, and sector fixed effects; robust clustered standard errors at district level. Specification: Sole Proprietor Registrations = f(post-2023, cash-intensive sector, interaction), identified by comparing (sole prop in cash-intensive sector post-2023) vs (all other combinations). ",
  "\\textbf{Sample:} 2,464 district-sector-month observations across 77 districts and 8 sectors, 48 months (2021-2024). ",
  "SDE = (DDD Coefficient) / SD(Outcome). Classification refers to magnitude, not statistical significance: Large ($|SDE| > 0.15$), Moderate (.05--.15), Small (.005--.05), Null ($< 0.005$)."
)

sde_table <- data.table(
  Outcome = "Monthly sole proprietor registrations",
  Beta = round(ddd_coef, 3),
  SE = round(ddd_se, 3),
  SD_Y = round(outcome_sd, 1),
  SDE = round(sde_main, 3),
  SE_SDE = round(sde_se, 3),
  Classification = sde_class
)

# Format as LaTeX
sde_latex <- "\\begin{tabular}{lrrrrrr}
\\toprule
\\textbf{Outcome} & \\textbf{$\\hat{\\beta}$} & \\textbf{SE} & \\textbf{SD($Y$)} & \\textbf{SDE} & \\textbf{SE(SDE)} & \\textbf{Classification} \\\\
\\midrule"

sde_latex <- paste0(sde_latex, "\n",
  sde_table$Outcome, " & ",
  sde_table$Beta, " & ",
  sde_table$SE, " & ",
  sde_table$SD_Y, " & ",
  sde_table$SDE, " & ",
  sde_table$SE_SDE, " & ",
  sde_table$Classification, " \\\\",
  "\n\\bottomrule",
  "\n\\multicolumn{7}{p{7in}}{\\small \\textit{Notes:} ", sde_notes, "}",
  "\n\\end{tabular}"
)

write(sde_latex, "tables/tabF1_sde.tex")
cat("✓ SDE Table saved to tables/tabF1_sde.tex\n")

# Also save as CSV for reference
fwrite(sde_table, "tables/sde_table.csv")

cat("\n✓ All tables generated successfully\n")
cat("  - tables/tabF1_desc.tex (Descriptive Statistics)\n")
cat("  - tables/tabF2_ddd.tex (Main DDD Results)\n")
cat("  - tables/tabF3_het.tex (Heterogeneous Effects)\n")
cat("  - tables/tabF4_robust.tex (Robustness Checks)\n")
cat("  - tables/tabF1_sde.tex (SDE Table - MANDATORY)\n")
