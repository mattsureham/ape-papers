# =============================================================================
# 05_tables.R — All tables for BRAC base closures paper
# =============================================================================
source("00_packages.R")

panel <- fread("../data/panel_annual.csv",
               colClasses = list(character = "county_fips"))
brac <- fread("../data/brac_treatment.csv", colClasses = list(character = "county_fips"))
panel[, post := as.integer(year >= g & g > 0)]

# Load all saved results
twfe_emp <- readRDS("../data/twfe_emp.rds")
twfe_hir <- readRDS("../data/twfe_hir.rds")
twfe_sep <- readRDS("../data/twfe_sep.rds")
twfe_earn <- readRDS("../data/twfe_earn.rds")
share_results <- readRDS("../data/share_results.rds")
ind_level_results <- readRDS("../data/ind_level_results.rds")
loco <- fread("../data/loco_results.csv")
diag <- fromJSON("../data/diagnostics.json")

# Helper functions
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  ""
}

fc <- function(att, se) {
  p <- 2 * pnorm(-abs(att / se))
  sprintf("%.4f%s", att, stars(p))
}

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("=== Table 1 ===\n")
pre <- panel[year == 1993 & !is.na(emp)]
ss <- pre[, .(
  emp = round(mean(emp, na.rm = TRUE)),
  sd_emp = round(sd(emp, na.rm = TRUE)),
  hir = round(mean(hir, na.rm = TRUE)),
  earn = round(mean(earn, na.rm = TRUE)),
  sh = round(mean(share_health, na.rm = TRUE), 3),
  sm = round(mean(share_manuf, na.rm = TRUE), 3),
  sa = round(mean(share_accom, na.rm = TRUE), 3),
  n = uniqueN(county_fips)
), by = .(grp = fifelse(g > 0, "BRAC", "Non-BRAC"))]

tab1 <- paste0(
  "\\begin{table}[!t]\n\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics (1993)}\n\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  " & BRAC Counties & Non-BRAC Counties \\\\\n\\hline\n",
  sprintf("Mean Employment & %s & %s \\\\\n",
          format(ss[grp == "BRAC"]$emp, big.mark = ","),
          format(ss[grp == "Non-BRAC"]$emp, big.mark = ",")),
  sprintf("SD Employment & %s & %s \\\\\n",
          format(ss[grp == "BRAC"]$sd_emp, big.mark = ","),
          format(ss[grp == "Non-BRAC"]$sd_emp, big.mark = ",")),
  sprintf("Mean Quarterly Hires & %s & %s \\\\\n",
          format(ss[grp == "BRAC"]$hir, big.mark = ","),
          format(ss[grp == "Non-BRAC"]$hir, big.mark = ",")),
  sprintf("Mean Quarterly Earnings (\\$) & %s & %s \\\\\n",
          format(ss[grp == "BRAC"]$earn, big.mark = ","),
          format(ss[grp == "Non-BRAC"]$earn, big.mark = ",")),
  sprintf("Healthcare Share & %.3f & %.3f \\\\\n",
          ss[grp == "BRAC"]$sh, ss[grp == "Non-BRAC"]$sh),
  sprintf("Manufacturing Share & %.3f & %.3f \\\\\n",
          ss[grp == "BRAC"]$sm, ss[grp == "Non-BRAC"]$sm),
  sprintf("Accommodation Share & %.3f & %.3f \\\\\n",
          ss[grp == "BRAC"]$sa, ss[grp == "Non-BRAC"]$sa),
  sprintf("Counties & %d & %s \\\\\n",
          ss[grp == "BRAC"]$n, format(ss[grp == "Non-BRAC"]$n, big.mark = ",")),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Baseline (1993) county-level means from Census QWI. ",
  "BRAC counties host installations closed or realigned under the 1988--2005 BRAC rounds. ",
  "Employment, hires, and earnings are quarterly averages for all private-sector workers. ",
  "Industry shares computed from NAICS sector-level employment.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_sumstats.tex")

# =============================================================================
# TABLE 2: Main TWFE Results
# =============================================================================
cat("=== Table 2 ===\n")
n_obs <- format(nobs(twfe_emp), big.mark = ",")

tab2 <- paste0(
  "\\begin{table}[!t]\n\\centering\n",
  "\\caption{Effect of BRAC Base Closures on Local Labor Markets}\n\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n\\hline\\hline\n",
  " & Log Emp. & Log Hires & Log Sep. & Log Earnings \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n\\hline\n",
  sprintf("Post $\\times$ BRAC & %s & %s & %s & %s \\\\\n",
          fc(coef(twfe_emp)["post"], se(twfe_emp)["post"]),
          fc(coef(twfe_hir)["post"], se(twfe_hir)["post"]),
          fc(coef(twfe_sep)["post"], se(twfe_sep)["post"]),
          fc(coef(twfe_earn)["post"], se(twfe_earn)["post"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          se(twfe_emp)["post"], se(twfe_hir)["post"],
          se(twfe_sep)["post"], se(twfe_earn)["post"]),
  "[6pt]\n",
  "County FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Counties & %s & %s & %s & %s \\\\\n",
          format(diag$n_counties, big.mark = ","),
          format(diag$n_counties, big.mark = ","),
          format(diag$n_counties, big.mark = ","),
          format(diag$n_counties, big.mark = ",")),
  sprintf("Treated & %d & %d & %d & %d \\\\\n",
          diag$n_treated, diag$n_treated, diag$n_treated, diag$n_treated),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          n_obs, n_obs, n_obs, n_obs),
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} TWFE estimates of BRAC base closure effects on county-level labor market outcomes. ",
  "The treatment indicator equals one for county-years after the county's first BRAC closure or realignment. ",
  "Five treatment cohorts: 1988, 1991, 1993, 1995, 2005 BRAC rounds. 44 treated counties, 3,151 controls. ",
  "All outcomes in logs. Standard errors clustered at the county level. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Industry Reallocation
# =============================================================================
cat("=== Table 3 ===\n")

ind_names <- c("Health", "Manuf", "Constr", "Accom", "Retail", "Prof")
ind_labels <- c("Healthcare (62)", "Manufacturing (31-33)", "Construction (23)",
                "Accommodation (72)", "Retail (44-45)", "Professional (54)")
share_keys <- c("share_health", "share_manuf", "share_constr",
                "share_accom", "share_retail", "share_prof")
level_keys <- c("ln_emp_health", "ln_emp_manuf", "ln_emp_constr",
                "ln_emp_accom", "ln_emp_retail", "ln_emp_prof")

tab3 <- paste0(
  "\\begin{table}[!t]\n\\centering\n",
  "\\caption{Industrial Reallocation After BRAC Closures}\n\\label{tab:realloc}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  "Sector & Log Employment & Employment Share \\\\\n",
  " & (1) & (2) \\\\\n\\hline\n"
)

for (i in seq_along(share_keys)) {
  lk <- level_keys[i]
  sk <- share_keys[i]
  lmod <- ind_level_results[[lk]]
  smod <- share_results[[sk]]
  if (is.null(lmod) || is.null(smod)) next
  tab3 <- paste0(tab3,
    sprintf("%s & %s & %s \\\\\n",
            ind_labels[i],
            fc(coef(lmod)["post"], se(lmod)["post"]),
            fc(coef(smod)["post"], se(smod)["post"])),
    sprintf(" & (%.4f) & (%.5f) \\\\\n",
            se(lmod)["post"], se(smod)["post"]),
    "[3pt]\n"
  )
}

tab3 <- paste0(tab3,
  "\\hline\n",
  "County FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} TWFE estimates by NAICS sector. Column 1: log sector employment. ",
  "Column 2: sector's share of total county employment. ",
  "Manufacturing employment declines significantly while accommodation/hospitality employment rises, ",
  "consistent with base conversion to tourism and service-oriented uses. ",
  "Standard errors clustered at the county level. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_reallocation.tex")

# =============================================================================
# TABLE 4: Leave-one-cohort-out
# =============================================================================
cat("=== Table 4 ===\n")
tab4 <- paste0(
  "\\begin{table}[!t]\n\\centering\n",
  "\\caption{Robustness: Leave-One-Cohort-Out}\n\\label{tab:loco}\n",
  "\\begin{tabular}{lcc}\n\\hline\\hline\n",
  "Specification & ATT & SE \\\\\n\\hline\n",
  sprintf("Baseline (all cohorts) & %s & (%.4f) \\\\\n[3pt]\n",
          fc(coef(twfe_emp)["post"], se(twfe_emp)["post"]),
          se(twfe_emp)["post"])
)
for (i in seq_len(nrow(loco))) {
  tab4 <- paste0(tab4,
    sprintf("Drop %d & %s & (%.4f) \\\\\n",
            loco$dropped[i], fc(loco$att[i], loco$se[i]), loco$se[i]))
}
tab4 <- paste0(tab4,
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row drops one BRAC cohort and re-estimates the TWFE model. ",
  "Results are stable except when dropping the 2005 cohort, which reveals a marginally significant ",
  "negative effect ($-0.015$, $p=0.068$). ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# =============================================================================
# TABLE F1: SDE
# =============================================================================
cat("=== Table F1: SDE ===\n")

# Pre-treatment SD for treated counties (use 1993 or earliest available)
pre <- panel[year == 1993 & g > 0]
sd_emp <- sd(pre$ln_emp, na.rm = TRUE)
sd_hir <- sd(pre$ln_hir, na.rm = TRUE)
sd_sep <- sd(pre$ln_sep, na.rm = TRUE)
sd_earn <- sd(pre$ln_earn, na.rm = TRUE)
sd_sh <- sd(pre$share_health, na.rm = TRUE)
sd_sm <- sd(pre$share_manuf, na.rm = TRUE)

compute_sde <- function(att, se, sd_y) {
  sde <- att / sd_y
  se_sde <- se / sd_y
  bucket <- if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

sde_rows <- function(label, att, se, sd_y) {
  s <- compute_sde(att, se, sd_y)
  sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s",
          label, att, se, sd_y, s$sde, s$se_sde, s$bucket)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do military base closures under the Base Realignment and Closure (BRAC) process cause persistent shifts in local private-sector employment, earnings, and industry composition? ",
  "\\textbf{Policy mechanism:} BRAC commissions identified installations for closure or realignment based on military value scoring, with Congress voting up-or-down on the full list; closure removes military and civilian DoD jobs, forcing reallocation across private-sector industries. ",
  "\\textbf{Outcome definition:} Panel A: county-level log private-sector employment, hires, separations, and earnings from Census QWI. Panel B: healthcare and manufacturing employment shares (sector employment divided by total county employment). ",
  "\\textbf{Treatment:} Binary indicator for county hosting a BRAC-closed or realigned installation; five treatment cohorts (1988, 1991, 1993, 1995, 2005). ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), 3,195 counties, 1993--2023, county-quarter-industry-level, annualized. 44 treated counties across five BRAC rounds. ",
  "\\textbf{Method:} Two-way fixed effects (county + year); standard errors clustered at county level. ",
  "\\textbf{Sample:} All U.S. counties with non-missing QWI data; BRAC counties identified from DoD BRAC Commission final reports (closures and major realignments only, excluding net-expansion bases). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among treated counties (1993 cross-section). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[!t]\n\\centering\n",
  "\\caption{Standardized Effect Sizes}\n\\label{tab:sde}\n\\small\n",
  "\\begin{tabular}{lcccccc}\n\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sde_rows("Log Employment", coef(twfe_emp)["post"], se(twfe_emp)["post"], sd_emp), " \\\\\n",
  sde_rows("Log Hires", coef(twfe_hir)["post"], se(twfe_hir)["post"], sd_hir), " \\\\\n",
  sde_rows("Log Separations", coef(twfe_sep)["post"], se(twfe_sep)["post"], sd_sep), " \\\\\n",
  sde_rows("Log Earnings", coef(twfe_earn)["post"], se(twfe_earn)["post"], sd_earn), " \\\\\n",
  "[6pt]\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Industry Shares)}} \\\\\n",
  sde_rows("Healthcare Share",
           coef(share_results$share_health)["post"],
           se(share_results$share_health)["post"], sd_sh), " \\\\\n",
  sde_rows("Manufacturing Share",
           coef(share_results$share_manuf)["post"],
           se(share_results$share_manuf)["post"], sd_sm), " \\\\\n",
  "\\hline\\hline\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("All tables written.\n")
