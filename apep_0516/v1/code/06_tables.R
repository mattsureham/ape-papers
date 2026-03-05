## ============================================================
## 06_tables.R — Generate all tables
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
TAB_DIR <- "../tables"
dir.create(TAB_DIR, showWarnings = FALSE)

# Load models
models_main <- readRDS(file.path(DATA_DIR, "models_main.rds"))
models_rob <- readRDS(file.path(DATA_DIR, "models_robustness.rds"))
panel <- fread(file.path(DATA_DIR, "panel_main.csv"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================

sumstats <- panel[zone_group %in% c("B1", "B2/C"),
  .(
    med_price_m2 = median(price_m2, na.rm = TRUE),
    mean_price_m2 = mean(price_m2, na.rm = TRUE),
    sd_price_m2 = sd(price_m2, na.rm = TRUE),
    mean_transactions = mean(n_transactions, na.rm = TRUE),
    mean_vefa_share = mean(vefa_share, na.rm = TRUE),
    n_communes = uniqueN(code_commune),
    n_obs = .N
  ),
  by = .(zone_group, period = fifelse(year < 2018, "Pre (2014-2017)", "Post (2018-2024)"))
]

fwrite(sumstats, file.path(DATA_DIR, "table1_sumstats.csv"))

# LaTeX output
sink(file.path(TAB_DIR, "table1_sumstats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Zone and Period}\n")
cat("\\label{tab:sumstats}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{llrrrrrrr}\n")
cat("\\toprule\n")
cat("Zone & Period & Med.\\ Price/m\\textsuperscript{2} & Mean Price/m\\textsuperscript{2} & SD & Trans./Year & VEFA Share & Communes & Obs.\\ \\\\\n")
cat("\\midrule\n")
for (i in seq_len(nrow(sumstats))) {
  row <- sumstats[i]
  cat(sprintf("%s & %s & %s & %s & %s & %.1f & %.3f & %s & %s \\\\\n",
    row$zone_group, row$period,
    formatC(row$med_price_m2, format = "f", digits = 0, big.mark = ","),
    formatC(row$mean_price_m2, format = "f", digits = 0, big.mark = ","),
    formatC(row$sd_price_m2, format = "f", digits = 0, big.mark = ","),
    row$mean_transactions,
    row$mean_vefa_share,
    formatC(row$n_communes, big.mark = ","),
    formatC(row$n_obs, big.mark = ",")))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} DVF transaction data aggregated to commune-year. ")
cat("B2/C = treated zones (lost PTZ/Pinel in 2018). B1 = control zone (retained subsidies). ")
cat("VEFA = Vente en l'\\'Etat Futur d'Ach\\`evement (off-plan new construction). ")
cat("Price per m\\textsuperscript{2} based on apartment transactions.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

# ============================================================
# Table 2: Main DiD Results
# ============================================================

main_models <- list(
  "All Residential" = models_main$did_simple,
  "New-Build" = models_main$did_vefa,
  "Existing" = models_main$did_existing,
  "Volume" = models_main$vol_did,
  "Two-Stage" = models_main$did_twostage
)

# Use modelsummary for LaTeX
msummary(main_models,
  output = file.path(TAB_DIR, "table2_main_did.tex"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "did" = "Treated $\\times$ Post",
    "treated:post_2018" = "Treated $\\times$ Post 2018",
    "treated:post_2020" = "Treated $\\times$ Post 2020"
  ),
  gof_map = c("nobs", "r.squared", "FE: code_commune", "FE: year"),
  title = "Main Difference-in-Differences Results",
  notes = c("Dependent variable: log price per m$^2$ (columns 1-3, 5), log transactions (column 4).",
            "Clustered standard errors at d\\'epartement level in parentheses."),
  escape = FALSE
)

# Also save coefficients as CSV
main_coefs <- data.table(
  model = names(main_models),
  coef = sapply(main_models, function(m) coef(m)[1]),
  se = sapply(main_models, function(m) sqrt(diag(vcov(m)))[1]),
  n = sapply(main_models, function(m) m$nobs)
)
fwrite(main_coefs, file.path(DATA_DIR, "table2_main_coefs.csv"))

# ============================================================
# Table 3: Robustness
# ============================================================

rob_models <- list(
  "Baseline" = models_main$did_simple,
  "Border Sample" = models_main$did_border,
  "No COVID" = models_rob$did_nocovid,
  "Pre-COVID" = models_rob$did_precovid,
  "Alt. Control (A/Abis)" = models_rob$did_alt,
  "Trimmed" = models_rob$did_trimmed,
  "Intensity" = models_rob$did_intensity
)

msummary(rob_models,
  output = file.path(TAB_DIR, "table3_robustness.tex"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c(
    "did" = "Treated $\\times$ Post",
    "intensity_did" = "VEFA Share $\\times$ Post"
  ),
  gof_map = c("nobs", "r.squared"),
  title = "Robustness Checks",
  notes = c("Dependent variable: log price per m$^2$.",
            "Clustered standard errors at d\\'epartement level in parentheses."),
  escape = FALSE
)

# Save robustness coefficients as CSV
rob_coefs <- data.table(
  model = names(rob_models),
  coef = sapply(rob_models, function(m) coef(m)[1]),
  se = sapply(rob_models, function(m) sqrt(diag(vcov(m)))[1]),
  n = sapply(rob_models, function(m) m$nobs)
)
fwrite(rob_coefs, file.path(DATA_DIR, "table3_robustness_coefs.csv"))

# ============================================================
# Table 4: House Prices
# ============================================================

house_models <- list(
  "Apartments (price/m2)" = models_main$did_simple,
  "Houses (total price)" = models_main$did_house
)

msummary(house_models,
  output = file.path(TAB_DIR, "table4_housing_type.tex"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  coef_map = c("did" = "Treated $\\times$ Post"),
  gof_map = c("nobs", "r.squared"),
  title = "Price Effects by Housing Type",
  notes = c("Column 1: log apartment price per m$^2$. Column 2: log median house transaction value.",
            "Clustered standard errors at d\\'epartement level in parentheses."),
  escape = FALSE
)

cat("All tables saved to", TAB_DIR, "\n")
