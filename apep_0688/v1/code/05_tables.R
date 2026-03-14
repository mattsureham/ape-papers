## 05_tables.R — Generate all tables
source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

knife <- fread(file.path(data_dir, "knife_panel_clean.csv"))

## Load model objects
twfe_knife <- readRDS(file.path(data_dir, "twfe_knife.rds"))
att_knife  <- readRDS(file.path(data_dir, "att_knife.rds"))
net_mod    <- readRDS(file.path(data_dir, "net_effect_model.rds"))
spill_mod  <- readRDS(file.path(data_dir, "spillover_model.rds"))
twfe_firearm <- readRDS(file.path(data_dir, "twfe_firearm.rds"))
twfe_precovid <- readRDS(file.path(data_dir, "twfe_precovid.rds"))
twfe_nomet  <- readRDS(file.path(data_dir, "twfe_nomet.rds"))
twfe_log    <- readRDS(file.path(data_dir, "twfe_log.rds"))
ri_results  <- readRDS(file.path(data_dir, "ri_results.rds"))
boot_results <- readRDS(file.path(data_dir, "cluster_bootstrap.rds"))

add_stars <- function(est, se) {
  p <- 2 * pnorm(-abs(est / se))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  paste0(sprintf("%.2f", est), stars)
}

## ─────────────────────────────────────────────────────────────────────────────
## Table 1: Summary Statistics
## ─────────────────────────────────────────────────────────────────────────────
cat("=== Table 1 ===\n")

pre <- knife[year_end < 2020]
summ <- pre[, .(
  `Mean Knife Rate` = sprintf("%.1f", mean(knife_rate, na.rm = TRUE)),
  `SD` = sprintf("%.1f", sd(knife_rate, na.rm = TRUE)),
  `Mean Pop. (000s)` = sprintf("%.0f", mean(population/1000, na.rm = TRUE)),
  Forces = as.character(uniqueN(force_std)),
  `Force-Years` = as.character(.N)
), by = force_type]

## Reorder
summ <- summ[match(c("VRU", "Boundary", "Interior"), summ$force_type)]

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics by Force Classification}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & Mean Knife & & Mean Pop. & & Force- \\\\\n",
  "Force Type & Crime Rate & SD & (000s) & Forces & Years \\\\\n",
  "\\midrule\n",
  paste0("VRU & ", summ[1, `Mean Knife Rate`], " & ", summ[1, SD], " & ",
         summ[1, `Mean Pop. (000s)`], " & ", summ[1, Forces], " & ", summ[1, `Force-Years`], " \\\\\n"),
  paste0("Boundary & ", summ[2, `Mean Knife Rate`], " & ", summ[2, SD], " & ",
         summ[2, `Mean Pop. (000s)`], " & ", summ[2, Forces], " & ", summ[2, `Force-Years`], " \\\\\n"),
  paste0("Interior & ", summ[3, `Mean Knife Rate`], " & ", summ[3, SD], " & ",
         summ[3, `Mean Pop. (000s)`], " & ", summ[3, Forces], " & ", summ[3, `Force-Years`], " \\\\\n"),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Knife crime rate per 100,000 population. Pre-treatment period: financial years ending 2011--2019. VRU forces received Home Office Serious Violence Fund grants beginning April 2019. Boundary forces are untreated forces sharing a geographic border with at least one VRU force. Interior forces share no borders with VRU forces. Source: ONS Police Force Area Data Tables.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1, file.path(tables_dir, "tab1_summary.tex"))

## ─────────────────────────────────────────────────────────────────────────────
## Table 2: Main Results — Direct Effect
## ─────────────────────────────────────────────────────────────────────────────
cat("=== Table 2 ===\n")

cs_est <- att_knife$overall.att
cs_se <- att_knife$overall.se
twfe_est <- coef(twfe_knife)["vru_post"]
twfe_se <- sqrt(vcov(twfe_knife)["vru_post","vru_post"])
precovid_est <- coef(twfe_precovid)["vru_post"]
precovid_se <- sqrt(vcov(twfe_precovid)["vru_post","vru_post"])
log_est <- coef(twfe_log)["vru_post"]
log_se <- sqrt(vcov(twfe_log)["vru_post","vru_post"])
nomet_est <- coef(twfe_nomet)["vru_post"]
nomet_se <- sqrt(vcov(twfe_nomet)["vru_post","vru_post"])

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Violence Reduction Units on Knife Crime}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  "\\midrule\n",
  "VRU $\\times$ Post & ", add_stars(cs_est, cs_se), " & ", add_stars(twfe_est, twfe_se),
  " & ", add_stars(precovid_est, precovid_se), " & ", add_stars(log_est, log_se),
  " & ", add_stars(nomet_est, nomet_se), " \\\\\n",
  " & (", sprintf("%.2f", cs_se), ") & (", sprintf("%.2f", twfe_se),
  ") & (", sprintf("%.2f", precovid_se), ") & (", sprintf("%.2f", log_se),
  ") & (", sprintf("%.2f", nomet_se), ") \\\\\n",
  "[0.5em]\n",
  "Observations & ", nobs(twfe_knife), " & ", nobs(twfe_knife), " & ", nobs(twfe_precovid),
  " & ", nobs(twfe_log), " & ", nobs(twfe_nomet), " \\\\\n",
  "Forces & 42 & 42 & 42 & 42 & 41 \\\\\n",
  "Treated Forces & 20 & 20 & 20 & 20 & 19 \\\\\n",
  "Estimator & CS-DiD & TWFE & TWFE & TWFE & TWFE \\\\\n",
  "Pre-COVID Only & No & No & Yes & No & No \\\\\n",
  "Dep. Var. & Level & Level & Level & Log & Level \\\\\n",
  "Dep. Var. Mean & ", sprintf("%.1f", mean(knife[vru==1 & year_end<2020, knife_rate], na.rm=TRUE)),
  " & & & & \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable: knife crime rate per 100,000 population (columns 1--3, 5) or log(rate + 1) (column 4). Column 1 reports the Callaway and Sant'Anna (2021) aggregated ATT. Columns 2--5 report TWFE estimates with force and year fixed effects. Column 3 restricts to financial years ending 2011--2020 (pre-COVID). Column 5 excludes the Metropolitan Police. Standard errors clustered at the police force area level in parentheses. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2, file.path(tables_dir, "tab2_main.tex"))

## ─────────────────────────────────────────────────────────────────────────────
## Table 3: Spillover Analysis
## ─────────────────────────────────────────────────────────────────────────────
cat("=== Table 3 ===\n")

net_vru <- coef(net_mod)["vru_post"]
net_vru_se <- sqrt(vcov(net_mod)["vru_post","vru_post"])
net_bnd <- coef(net_mod)["boundary_post"]
net_bnd_se <- sqrt(vcov(net_mod)["boundary_post","boundary_post"])

sp_bnd <- coef(spill_mod)["boundary_post"]
sp_bnd_se <- sqrt(vcov(spill_mod)["boundary_post","boundary_post"])

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Displacement vs.\\ Deterrence: Spillovers at Force Boundaries}\n",
  "\\label{tab:spillover}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  " & (1) & (2) \\\\\n",
  " & All Forces & Untreated Only \\\\\n",
  "\\midrule\n",
  "\\emph{Panel A: Direct Effect} & & \\\\\n",
  "VRU $\\times$ Post & ", add_stars(net_vru, net_vru_se), " & \\\\\n",
  " & (", sprintf("%.2f", net_vru_se), ") & \\\\\n",
  "[0.5em]\n",
  "\\emph{Panel B: Spillover} & & \\\\\n",
  "Boundary $\\times$ Post & ", add_stars(net_bnd, net_bnd_se), " & ",
  add_stars(sp_bnd, sp_bnd_se), " \\\\\n",
  " & (", sprintf("%.2f", net_bnd_se), ") & (", sprintf("%.2f", sp_bnd_se), ") \\\\\n",
  "[0.5em]\n",
  "Observations & ", nobs(net_mod), " & ", nobs(spill_mod), " \\\\\n",
  "Forces & 42 & 22 \\\\\n",
  "RI $p$-value (spillover) & ", sprintf("%.3f", ri_results$spillover$p),
  " & ", sprintf("%.3f", ri_results$spillover$p), " \\\\\n",
  "Bootstrap $p$-value & ", sprintf("%.3f", boot_results$p),
  " & ", sprintf("%.3f", boot_results$p), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable: knife crime rate per 100,000. Column 1 includes all 42 forces; column 2 restricts to untreated forces only (22 forces). Boundary forces share a geographic border with at least one VRU force. If VRUs displace crime, the boundary coefficient should be positive; if VRUs deter crime regionally, the coefficient should be negative. Randomization inference permutes VRU assignment across forces (1,000 permutations). Cluster bootstrap resamples forces with replacement (999 replications). All specifications include force and year fixed effects. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3, file.path(tables_dir, "tab3_spillover.tex"))

## ─────────────────────────────────────────────────────────────────────────────
## Table 4: Robustness Summary
## ─────────────────────────────────────────────────────────────────────────────
cat("=== Table 4 ===\n")

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness of Spillover Estimate}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE & $p$-value \\\\\n",
  "\\midrule\n",
  "\\emph{Direct effect (VRU forces)} & & & \\\\\n",
  "TWFE & ", sprintf("%.2f", twfe_est), " & ", sprintf("%.2f", twfe_se),
  " & ", sprintf("%.3f", 2*pnorm(-abs(twfe_est/twfe_se))), " \\\\\n",
  "Callaway-Sant'Anna & ", sprintf("%.2f", cs_est), " & ", sprintf("%.2f", cs_se),
  " & ", sprintf("%.3f", 2*pnorm(-abs(cs_est/cs_se))), " \\\\\n",
  "Log(rate + 1) & ", sprintf("%.3f", log_est), " & ", sprintf("%.3f", log_se),
  " & ", sprintf("%.3f", 2*pnorm(-abs(log_est/log_se))), " \\\\\n",
  "Pre-COVID only & ", sprintf("%.2f", precovid_est), " & ", sprintf("%.2f", precovid_se),
  " & ", sprintf("%.3f", 2*pnorm(-abs(precovid_est/precovid_se))), " \\\\\n",
  "Excl.\\ Met Police & ", sprintf("%.2f", nomet_est), " & ", sprintf("%.2f", nomet_se),
  " & ", sprintf("%.3f", 2*pnorm(-abs(nomet_est/nomet_se))), " \\\\\n",
  "Randomization inference & ", sprintf("%.2f", ri_results$direct$actual),
  " & --- & ", sprintf("%.3f", ri_results$direct$p), " \\\\\n",
  "[0.5em]\n",
  "\\emph{Spillover (boundary forces)} & & & \\\\\n",
  "TWFE & ", sprintf("%.2f", sp_bnd), " & ", sprintf("%.2f", sp_bnd_se),
  " & ", sprintf("%.3f", 2*pnorm(-abs(sp_bnd/sp_bnd_se))), " \\\\\n",
  "Randomization inference & ", sprintf("%.2f", ri_results$spillover$actual),
  " & --- & ", sprintf("%.3f", ri_results$spillover$p), " \\\\\n",
  "Cluster bootstrap & ", sprintf("%.2f", ri_results$spillover$actual),
  " & ", sprintf("%.2f", boot_results$se), " & ", sprintf("%.3f", boot_results$p), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Dependent variable: knife crime rate per 100,000 (levels) or log(rate + 1). Direct effect estimates use all 42 forces; spillover estimates use 22 untreated forces only. Randomization inference permutes treatment assignment (1,000 draws); cluster bootstrap resamples forces with replacement (999 draws).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4, file.path(tables_dir, "tab4_robustness.tex"))

## ─────────────────────────────────────────────────────────────────────────────
## Table F1: Standardized Effect Sizes
## ─────────────────────────────────────────────────────────────────────────────
cat("=== Table F1 (SDE) ===\n")

sd_y_vru <- sd(knife[vru == 1 & year_end < 2020, knife_rate], na.rm = TRUE)
sd_y_bnd <- sd(knife[boundary == 1 & year_end < 2020, knife_rate], na.rm = TRUE)

## SDE for direct and spillover
sde_direct <- twfe_est / sd_y_vru
se_sde_direct <- twfe_se / sd_y_vru
sde_spill <- sp_bnd / sd_y_bnd
se_sde_spill <- sp_bnd_se / sd_y_bnd

classify <- function(x) {
  if (abs(x) <= 0.005) return("Null")
  if (abs(x) <= 0.05) return(paste(ifelse(x > 0, "Small positive", "Small negative")))
  if (abs(x) <= 0.15) return(paste(ifelse(x > 0, "Moderate positive", "Moderate negative")))
  return(paste(ifelse(x > 0, "Large positive", "Large negative")))
}

## Firearm
firearm_est <- coef(twfe_firearm)["vru_post"]
firearm_se <- sqrt(vcov(twfe_firearm)["vru_post","vru_post"])
firearm_clean <- fread(file.path(data_dir, "firearm_panel_clean.csv"))
sd_y_firearm <- sd(firearm_clean[vru == 1 & year_end < 2020, firearm_rate], na.rm = TRUE)
sde_firearm <- firearm_est / sd_y_firearm
se_sde_firearm <- firearm_se / sd_y_firearm

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD(Y) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\emph{Direct effect (VRU forces)} & & & & & & \\\\\n",
  "Knife crime & ", sprintf("%.2f", twfe_est), " & ", sprintf("%.2f", twfe_se),
  " & ", sprintf("%.1f", sd_y_vru), " & ", sprintf("%.3f", sde_direct),
  " & ", sprintf("%.3f", se_sde_direct), " & ", classify(sde_direct), " \\\\\n",
  "Firearm offences & ", sprintf("%.2f", firearm_est), " & ", sprintf("%.2f", firearm_se),
  " & ", sprintf("%.1f", sd_y_firearm), " & ", sprintf("%.3f", sde_firearm),
  " & ", sprintf("%.3f", se_sde_firearm), " & ", classify(sde_firearm), " \\\\\n",
  "[0.5em]\n",
  "\\emph{Spillover (boundary forces)} & & & & & & \\\\\n",
  "Knife crime & ", sprintf("%.2f", sp_bnd), " & ", sprintf("%.2f", sp_bnd_se),
  " & ", sprintf("%.1f", sd_y_bnd), " & ", sprintf("%.3f", sde_spill),
  " & ", sprintf("%.3f", se_sde_spill), " & ", classify(sde_spill), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} SDE = $\\hat{\\beta}$ / SD(Y), where SD(Y) is the pre-treatment standard deviation. Classification: Large ($|\\text{SDE}| > 0.15$), Moderate ($0.05 < |\\text{SDE}| \\leq 0.15$), Small ($0.005 < |\\text{SDE}| \\leq 0.05$), Null ($|\\text{SDE}| \\leq 0.005$). Classifications refer to magnitude, not statistical significance. Research question: Do Violence Reduction Units reduce or displace knife crime? Data: ONS Police Force Area Data Tables, financial years ending 2011--2025. Method: TWFE DiD. Sample: 42 police force areas $\\times$ 15 years. Treatment: VRU funding (20 forces from April 2019/2022).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
