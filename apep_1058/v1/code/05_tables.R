# ==============================================================================
# 05_tables.R — Summary statistics and SDE appendix table
# apep_1058: The Networked Bank Run
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- readRDS(file.path(data_dir, "analysis.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
m5 <- results$m5
diagnostics <- results$diagnostics

# ==============================================================================
# 1. Summary Statistics (Table 5)
# ==============================================================================
cat("=== Generating summary statistics table ===\n")

sum_vars <- analysis %>%
  summarise(
    across(
      c(dlog_dep_2223, network_exposure, network_exposure_std,
        dist_to_sc_km, tech_share, deposits_2022, population_2022),
      list(
        mean = ~mean(., na.rm=TRUE),
        sd = ~sd(., na.rm=TRUE),
        min = ~min(., na.rm=TRUE),
        max = ~max(., na.rm=TRUE),
        p25 = ~quantile(., 0.25, na.rm=TRUE),
        p75 = ~quantile(., 0.75, na.rm=TRUE)
      ),
      .names = "{.col}__{.fn}"
    )
  )

# Reshape to long format
var_labels <- c(
  dlog_dep_2223 = "$\\Delta$ Log Deposits (2022--2023)",
  network_exposure = "Network Exposure (raw)",
  network_exposure_std = "Network Exposure (std.)",
  dist_to_sc_km = "Distance to SV (km)",
  tech_share = "Tech Employment Share",
  deposits_2022 = "Deposits 2022 (\\$000s)",
  population_2022 = "Population (2022)"
)

sum_table <- data.frame(
  Variable = character(),
  Mean = numeric(),
  SD = numeric(),
  P25 = numeric(),
  P75 = numeric(),
  stringsAsFactors = FALSE
)

for (v in names(var_labels)) {
  sum_table <- rbind(sum_table, data.frame(
    Variable = var_labels[v],
    Mean = sum_vars[[paste0(v, "__mean")]],
    SD = sum_vars[[paste0(v, "__sd")]],
    P25 = sum_vars[[paste0(v, "__p25")]],
    P75 = sum_vars[[paste0(v, "__p75")]],
    stringsAsFactors = FALSE
  ))
}

# Write LaTeX
tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Variable & Mean & SD & P25 & P75 \\\\",
  "\\hline"
)

for (i in 1:nrow(sum_table)) {
  row <- sum_table[i, ]
  fmt <- function(x) {
    if (abs(x) >= 1000) format(round(x, 0), big.mark=",")
    else if (abs(x) >= 1) sprintf("%.3f", x)
    else sprintf("%.4f", x)
  }
  tex_lines <- c(tex_lines, sprintf(
    "%s & %s & %s & %s & %s \\\\",
    row$Variable, fmt(row$Mean), fmt(row$SD), fmt(row$P25), fmt(row$P75)
  ))
}

tex_lines <- c(tex_lines,
  "\\hline",
  sprintf("\\multicolumn{5}{l}{\\footnotesize $N = %s$ counties across %d states.} \\\\",
          format(nrow(analysis), big.mark=","), n_distinct(analysis$state_fips)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tex_lines, file.path(tables_dir, "tab5_sumstats.tex"))

# ==============================================================================
# 2. SDE Appendix Table (MANDATORY)
# ==============================================================================
cat("\n=== Generating SDE table ===\n")

# Compute SDE for main outcome
beta_main <- diagnostics$main_coef
se_main <- diagnostics$main_se
sd_y <- diagnostics$outcome_sd

# SDE = beta / SD(Y) — but beta is for standardized X, so this is already
# "a 1-SD increase in X changes Y by beta, and SDE = beta / SD(Y)"
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity: high vs low deposit counties
analysis_high <- filter(analysis, deposits_2022 > median(analysis$deposits_2022))
analysis_low <- filter(analysis, deposits_2022 <= median(analysis$deposits_2022))

h_high <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                  log_pop + log_income + tech_share + pre_trend | state_fips,
                data = analysis_high, cluster = ~state_fips)

h_low <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                 log_pop + log_income + tech_share + pre_trend | state_fips,
               data = analysis_low, cluster = ~state_fips)

sd_y_high <- sd(analysis_high$dlog_dep_2223)
sd_y_low <- sd(analysis_low$dlog_dep_2223)

sde_high <- coef(h_high)["network_exposure_std"] / sd_y_high
se_sde_high <- se(h_high)["network_exposure_std"] / sd_y_high
sde_low <- coef(h_low)["network_exposure_std"] / sd_y_low
se_sde_low <- se(h_low)["network_exposure_std"] / sd_y_low

# Build SDE table
sde_rows <- list(
  list(outcome = "$\\Delta$ Log Deposits", beta = beta_main, se = se_main,
       sd_y = sd_y, sde = sde_main, se_sde = se_sde_main,
       panel = "A", label = "Pooled"),
  list(outcome = "$\\Delta$ Log Deposits (High Dep.)", beta = unname(coef(h_high)["network_exposure_std"]),
       se = unname(se(h_high)["network_exposure_std"]), sd_y = sd_y_high,
       sde = unname(sde_high), se_sde = unname(se_sde_high),
       panel = "B", label = "High deposits"),
  list(outcome = "$\\Delta$ Log Deposits (Low Dep.)", beta = unname(coef(h_low)["network_exposure_std"]),
       se = unname(se(h_low)["network_exposure_std"]), sd_y = sd_y_low,
       sde = unname(sde_low), se_sde = unname(se_sde_low),
       panel = "B", label = "Low deposits")
)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does social connectedness to Silicon Valley predict deposit reallocation ",
  "at non-failed banks during the March 2023 banking panic, beyond geographic proximity and local economic structure? ",
  "\\textbf{Policy mechanism:} The failure of Silicon Valley Bank (SVB) on March 10, 2023 triggered ",
  "a nationwide banking panic; counties with stronger real social ties to SVB's geographic footprint ",
  "may have received private information about SVB's specific vulnerabilities, enabling depositors to ",
  "reallocate funds from failed institutions to surviving local banks rather than panicking indiscriminately. ",
  "\\textbf{Outcome definition:} Log change in county-level deposits at non-failed banks (excluding SVB, ",
  "Signature Bank, and First Republic Bank) from FDIC Summary of Deposits, June 2022 to June 2023. ",
  "\\textbf{Treatment:} Continuous; SCI-weighted SVB deposit market share, standardized to unit variance. ",
  "\\textbf{Data:} FDIC Summary of Deposits (branch-level, annual June 30) merged with Meta Social ",
  "Connectedness Index (county-pair level), 2017--2023, county-level cross-section. ",
  "\\textbf{Method:} OLS with state fixed effects, controlling for log distance to Silicon Valley, ",
  "population, income, tech employment share, and pre-crisis deposit trends; standard errors clustered at state level. ",
  "\\textbf{Sample:} Continental US counties with non-missing deposits in both 2022 and 2023 and ",
  "available SCI data; Panel B splits at median 2022 deposit level. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Generate LaTeX
sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\"
)

for (row in sde_rows) {
  if (row$panel == "B" && row$label == "High deposits") {
    sde_tex <- c(sde_tex,
      "\\hline",
      "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by county deposit level)}} \\\\"
    )
  }
  sde_tex <- c(sde_tex, sprintf(
    "%s & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
    row$outcome, row$beta, row$se, row$sd_y, row$sde, row$se_sde,
    classify_sde(row$sde)
  ))
}

sde_tex <- c(sde_tex,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{itemize}[leftmargin=*,nosep]",
  sde_notes,
  "\\end{itemize}",
  "\\end{table}"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))

cat("SDE table written to tables/tabF1_sde.tex\n")
cat(sprintf("Main SDE: %.3f (%s)\n", sde_main, classify_sde(sde_main)))

cat("\n=== All tables generated ===\n")
