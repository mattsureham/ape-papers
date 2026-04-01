# 07_sde_table.R — Generate SDE appendix table

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
pre_sd <- readRDS(file.path(data_dir, "pre_sd_ndvi.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cf_k_lin <- coef(results$m2_kharif_lin)["flood_x_post"]
cf_r_lin <- coef(results$m2_rabi_lin)["flood_x_post"]
cf_pool_lin <- coef(results$m1_linear)["flood_x_post"]

delta <- 10
sde_pool <- (cf_pool_lin * delta) / pre_sd
sde_kharif <- (cf_k_lin * delta) / pre_sd
sde_rabi <- (cf_r_lin * delta) / pre_sd

se_k <- summary(results$m2_kharif_lin)$coeftable["flood_x_post", 2]
se_r <- summary(results$m2_rabi_lin)$coeftable["flood_x_post", 2]
se_pool <- summary(results$m1_linear)$coeftable["flood_x_post", 2]

sde_se_pool <- (se_pool * delta) / pre_sd
sde_se_kharif <- (se_k * delta) / pre_sd
sde_se_rabi <- (se_r * delta) / pre_sd

con <- file(file.path(tab_dir, "tabF1_sde.tex"), "w")
writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "\\\\[-1.8ex]",
  " & Pooled & Kharif & Rabi \\\\",
  "\\hline",
  sprintf("Coefficient (per 1pp) & %.6f & %.6f & %.6f \\\\", cf_pool_lin, cf_k_lin, cf_r_lin),
  sprintf(" & (%.6f) & (%.6f) & (%.6f) \\\\", se_pool, se_k, se_r),
  sprintf("SDE (10pp increase) & %.4f & %.4f & %.4f \\\\", sde_pool, sde_kharif, sde_rabi),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\", sde_se_pool, sde_se_kharif, sde_se_rabi),
  sprintf("Pre-treatment SD(NDVI) & \\multicolumn{3}{c}{%.4f} \\\\", pre_sd),
  "Treatment benchmark & \\multicolumn{3}{c}{10 percentage points} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "\\small",
  "\\textit{Notes:} Standardized effect sizes computed as (coefficient $\\times$ treatment benchmark) / pre-treatment SD(NDVI). Treatment benchmark is a 10 percentage point increase in flood intensity. Coefficients from linear continuous treatment DiD with tehsil and season-year fixed effects. Standard errors clustered at district level in parentheses.",
  "\\end{table}"
), con)
close(con)

cat("SDE table written.\n")
cat("SDE values: Pooled =", round(sde_pool, 4),
    ", Kharif =", round(sde_kharif, 4),
    ", Rabi =", round(sde_rabi, 4), "\n")
