# =============================================================================
# 05_tables.R — Run regressions and generate all LaTeX tables
# =============================================================================

source("00_packages.R")

cat("Reading data...\n")
con <- DBI::dbConnect(duckdb::duckdb())
panel <- DBI::dbGetQuery(con, "SELECT * FROM '../data/clean_panel.parquet'")
DBI::dbDisconnect(con, shutdown = TRUE)
setDT(panel)

dir.create("../tables", showWarnings = FALSE)

# Helpers
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmtint <- function(x) formatC(x, format = "d", big.mark = ",")
stars_str <- function(p) ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.10, "$^{*}$", "")))
classify_sde <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

# ==========================================================================
# RUN ALL REGRESSIONS
# ==========================================================================
cat("Running regressions...\n")

# Main TWFE
m_occ <- feols(occscore ~ treated | histid + year, data = panel, cluster = ~statefip_origin); gc()
m_sei <- feols(sei ~ treated | histid + year, data = panel, cluster = ~statefip_origin); gc()
m_farm <- feols(farm_binary ~ treated | histid + year, data = panel, cluster = ~statefip_origin); gc()
m_lf <- feols(in_labor_force ~ treated | histid + year, data = panel, cluster = ~statefip_origin); gc()

# Sun-Abraham
sa_occ <- feols(occscore ~ sunab(first_treat, year) | histid + year, data = panel, cluster = ~statefip_origin); gc()
sa_sei <- feols(sei ~ sunab(first_treat, year) | histid + year, data = panel, cluster = ~statefip_origin); gc()
sa_farm <- feols(farm_binary ~ sunab(first_treat, year) | histid + year, data = panel, cluster = ~statefip_origin); gc()

# Mechanisms
m_child <- feols(occscore ~ treated | histid + year, data = panel[child_1920 == 1], cluster = ~statefip_origin); gc()
m_head <- feols(occscore ~ treated | histid + year, data = panel[child_1920 == 0], cluster = ~statefip_origin); gc()
m_small <- feols(occscore ~ treated | histid + year, data = panel[small_family_1920 == 1], cluster = ~statefip_origin); gc()
m_large <- feols(occscore ~ treated | histid + year, data = panel[small_family_1920 == 0], cluster = ~statefip_origin); gc()

panel[, farm_1920_base := farm_binary[year == 1920L], by = histid]
m_farm_b <- feols(occscore ~ treated | histid + year, data = panel[farm_1920_base == 1], cluster = ~statefip_origin); gc()
m_nonfarm_b <- feols(occscore ~ treated | histid + year, data = panel[farm_1920_base == 0], cluster = ~statefip_origin); gc()
m_native <- feols(occscore ~ treated | histid + year, data = panel[native_born == 1], cluster = ~statefip_origin); gc()
m_foreign <- feols(occscore ~ treated | histid + year, data = panel[native_born == 0], cluster = ~statefip_origin); gc()

# Robustness
r_emp <- feols(occscore ~ treated | histid + year, data = panel[in_labor_force == 1], cluster = ~statefip_origin); gc()
r_white <- feols(occscore ~ treated | histid + year, data = panel[white == 1], cluster = ~statefip_origin); gc()

panel[, age_1920_base := age[year == 1920L], by = histid]
r_prime <- feols(occscore ~ treated | histid + year, data = panel[age_1920_base >= 30 & age_1920_base <= 45], cluster = ~statefip_origin); gc()
r_wt <- feols(occscore ~ treated | histid + year, data = panel, weights = ~perwt, cluster = ~statefip_origin); gc()
r_homeown <- feols(homeowner ~ treated | histid + year, data = panel, cluster = ~statefip_origin); gc()
panel[, married := as.integer(marst %in% c(1L, 2L))]
r_married <- feols(married ~ treated | histid + year, data = panel, cluster = ~statefip_origin); gc()

cat("All regressions done.\n")

# ==========================================================================
# Helper: make table row
# ==========================================================================
make_row <- function(model, label) {
  b <- coef(model)["treated"]
  s <- se(model)["treated"]
  p <- pvalue(model)["treated"]
  n <- model$nobs
  paste0(label, " & ", fmt(b, 4), stars_str(p), " & (", fmt(s, 4), ") & ", fmtint(n), " \\\\")
}

make_row_sa <- function(model, label) {
  # SA aggregated ATT via coeftable on post-treatment coefficients
  ct <- coeftable(model)
  # Get post-treatment rows (year::0 and year::10)
  post_rows <- grepl("^year::[0-9]", rownames(ct))
  if (sum(post_rows) == 0) {
    return(paste0(label, " & --- & --- & ", fmtint(model$nobs), " \\\\"))
  }
  # Simple average of post-treatment coefficients
  b <- mean(ct[post_rows, 1])
  # SE via delta method approximation (conservative: max SE)
  s <- max(ct[post_rows, 2])
  p <- 2 * pnorm(-abs(b/s))
  paste0(label, " & ", fmt(b, 4), stars_str(p), " & (", fmt(s, 4), ") & ", fmtint(model$nobs), " \\\\")
}

# ==========================================================================
# TABLE 1: Summary Statistics
# ==========================================================================
cat("Writing Table 1...\n")

base <- panel[year == 1920]

vars_table <- list(
  c("age", "Age", 1),
  c("occscore", "Occupational income score", 1),
  c("sei", "Socioeconomic index", 1),
  c("farm_binary", "Farm resident (\\%)", 100),
  c("in_labor_force", "In labor force (\\%)", 100),
  c("child_1920", "Co-resident child (\\%)", 100),
  c("homeowner", "Homeowner (\\%)", 100),
  c("native_born", "Native-born (\\%)", 100),
  c("white", "White (\\%)", 100)
)

summ_lines <- ""
for (v in vars_table) {
  vname <- v[[1]]; label <- v[[2]]; mult <- as.numeric(v[[3]])
  me <- mean(base[first_treat == 1930][[vname]], na.rm = TRUE) * mult
  ml <- mean(base[first_treat == 1940][[vname]], na.rm = TRUE) * mult
  mc <- mean(base[first_treat == 0][[vname]], na.rm = TRUE) * mult
  ma <- mean(base[[vname]], na.rm = TRUE) * mult
  sa <- sd(base[[vname]], na.rm = TRUE) * mult
  summ_lines <- paste0(summ_lines,
    label, " & ", fmt(me, 1), " & ", fmt(ml, 1), " & ", fmt(mc, 1),
    " & ", fmt(ma, 1), " & ", fmt(sa, 1), " \\\\\n")
}

tab1 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Summary Statistics: Men Aged 25--50 in 1920}\n\\label{tab:summary}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lccccc}\n\\toprule\n",
  " & Early & Late & Never & \\multicolumn{2}{c}{Full sample} \\\\\n",
  " & adopters & adopters & treated & Mean & SD \\\\\n\\midrule\n",
  summ_lines,
  "\\midrule\n",
  "Observations & ", fmtint(nrow(base[first_treat == 1930])), " & ",
  fmtint(nrow(base[first_treat == 1940])), " & ",
  fmtint(nrow(base[first_treat == 0])), " & \\multicolumn{2}{c}{",
  fmtint(nrow(base)), "} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Baseline (1920) characteristics of men aged 25--50 ",
  "linked across three censuses (1920, 1930, 1940) via the IPUMS Multigenerational ",
  "Longitudinal Panel. Early adopters: 10 states with pension laws before 1930. ",
  "Late adopters: 18 states adopting 1930--1935. Never treated: 20 states without ",
  "old-age pensions before the Social Security Act.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ==========================================================================
# TABLE 2: Main Results
# ==========================================================================
cat("Writing Table 2...\n")

tab2 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Effect of State Old-Age Pensions on Labor Market Outcomes}\n\\label{tab:main}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lccc}\n\\toprule\n",
  " & Coefficient & SE & Observations \\\\\n\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: TWFE with Individual Fixed Effects}} \\\\\n",
  make_row(m_occ, "Occupational income score"), "\n",
  make_row(m_sei, "Socioeconomic index"), "\n",
  make_row(m_farm, "Farm resident"), "\n",
  make_row(m_lf, "In labor force"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Sun--Abraham Heterogeneity-Robust}} \\\\\n",
  make_row_sa(sa_occ, "Occupational income score"), "\n",
  make_row_sa(sa_sei, "Socioeconomic index"), "\n",
  make_row_sa(sa_farm, "Farm resident"), "\n",
  "\\midrule\n",
  "Individual FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Clustering & \\multicolumn{3}{c}{State (1920 residence)} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the treatment indicator ",
  "(= 1 if the man's 1920 state had adopted an old-age pension law by the census year). ",
  "Panel A: two-way fixed effects. Panel B: \\citet{sunAbraham2021} heterogeneity-robust ",
  "estimator (average of post-treatment cohort-time effects; conservative SE). ",
  "Standard errors clustered at state of 1920 residence. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ==========================================================================
# TABLE 3: Mechanisms
# ==========================================================================
cat("Writing Table 3...\n")

tab3 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Mechanisms: Heterogeneous Effects on Occupational Income Score}\n\\label{tab:mechanisms}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lccc}\n\\toprule\n",
  " & Coefficient & SE & Observations \\\\\n\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Co-residence with parents in 1920}} \\\\\n",
  make_row(m_child, "Co-resident children"), "\n",
  make_row(m_head, "Others (heads, spouses)"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Family size in 1920}} \\\\\n",
  make_row(m_small, "Small family ($\\leq$ 3 members)"), "\n",
  make_row(m_large, "Large family ($>$ 3 members)"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel C: Baseline sector in 1920}} \\\\\n",
  make_row(m_farm_b, "Farm workers"), "\n",
  make_row(m_nonfarm_b, "Non-farm workers"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel D: Nativity}} \\\\\n",
  make_row(m_native, "Native-born"), "\n",
  make_row(m_foreign, "Foreign-born"), "\n",
  "\\midrule\n",
  "Individual FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Each panel splits the sample by a baseline (1920) characteristic. ",
  "Co-resident children: men living as children in their parents' household (IPUMS relate = 3, 4). ",
  "If pensions relieve eldercare, effects should be larger for co-resident children and small families. ",
  "Standard errors clustered at the state level. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_mechanisms.tex")

# ==========================================================================
# TABLE 4: Robustness
# ==========================================================================
cat("Writing Table 4...\n")

tab4 <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Robustness Checks}\n\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lccc}\n\\toprule\n",
  " & Coefficient & SE & Observations \\\\\n\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Alternative samples}} \\\\\n",
  make_row(m_occ, "Baseline (all men 25--50)"), "\n",
  make_row(r_emp, "Employed only"), "\n",
  make_row(r_white, "White men only"), "\n",
  make_row(r_prime, "Ages 30--45 in 1920"), "\n",
  make_row(r_wt, "Person-weight weighted"), "\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: Placebo outcomes}} \\\\\n",
  make_row(r_homeown, "Homeownership"), "\n",
  make_row(r_married, "Married"), "\n",
  "\\midrule\n",
  "Individual FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Panel A re-estimates the TWFE specification on alternative samples. ",
  "Panel B tests outcomes that pensions should not directly affect for working-age men. ",
  "Standard errors clustered at the state level. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robustness.tex")

# ==========================================================================
# TABLE F1: SDE
# ==========================================================================
cat("Writing SDE table...\n")

sd_occ <- sd(panel[year == 1920]$occscore, na.rm = TRUE)
sd_sei <- sd(panel[year == 1920]$sei, na.rm = TRUE)
sd_farm <- sd(panel[year == 1920]$farm_binary, na.rm = TRUE)
sd_occ_child <- sd(panel[year == 1920 & child_1920 == 1]$occscore, na.rm = TRUE)
sd_occ_head <- sd(panel[year == 1920 & child_1920 == 0]$occscore, na.rm = TRUE)

make_sde_row <- function(model, label, sd_y) {
  b <- coef(model)["treated"]
  s <- se(model)["treated"]
  sde <- b / sd_y
  se_sde <- s / sd_y
  cls <- classify_sde(sde)
  paste0(label, " & ", fmt(b, 4), " & (", fmt(s, 4), ") & ",
         fmt(sd_y, 2), " & ", fmt(sde, 4), " & (", fmt(se_sde, 4), ") & ",
         cls, " \\\\")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state old-age pension laws adopted during 1923--1935 ",
  "improve occupational outcomes for working-age men by relieving informal eldercare ",
  "obligations? ",
  "\\textbf{Policy mechanism:} State old-age pensions provided means-tested cash ",
  "transfers to elderly residents (typically aged 65--70+), reducing their dependence ",
  "on co-resident adult children for financial support and thereby potentially freeing ",
  "children to pursue occupational upgrading and geographic mobility. ",
  "\\textbf{Outcome definition:} Occupational income score (occscore) from IPUMS, ",
  "assigning the median total income of each occupation's workers in 1950 to all ",
  "census years; socioeconomic index (SEI); and farm residence indicator. ",
  "\\textbf{Treatment:} Binary; equals one if a man's 1920 state of residence had ",
  "adopted an old-age pension law by the census year. ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel (MLP), linking ",
  "individuals across the 1920, 1930, and 1940 decennial censuses; men aged 25--50 ",
  "in 1920 with valid three-decade links; N = ", fmtint(uniqueN(panel$histid)),
  " unique individuals. ",
  "\\textbf{Method:} Two-way fixed effects (individual and year) with staggered ",
  "adoption across 28 states; Sun--Abraham heterogeneity-robust estimator reported ",
  "alongside TWFE; standard errors clustered at the state of 1920 residence. ",
  "\\textbf{Sample:} Men aged 25--50 in 1920, linked across all three census decades ",
  "with consistent age progression ($\\pm$2 years). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "(1920) standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), ",
  "Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[H]\n\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n\\label{tab:sde}\n",
  "\\begin{threeparttable}\n\\begin{tabular}{lcccccc}\n\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  make_sde_row(m_occ, "Occ.\\ income score", sd_occ), "\n",
  make_sde_row(m_sei, "Socioeconomic index", sd_sei), "\n",
  make_sde_row(m_farm, "Farm resident", sd_farm), "\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by 1920 co-residence)}} \\\\\n",
  make_sde_row(m_child, "Occ.\\ score (co-resident children)", sd_occ_child), "\n",
  make_sde_row(m_head, "Occ.\\ score (others)", sd_occ_head), "\n",
  "\\bottomrule\n\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n"
)
writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("\nAll tables written.\n")
