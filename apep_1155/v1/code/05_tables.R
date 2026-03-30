## 05_tables.R — Generate all LaTeX tables for apep_1155
## El Salvador Gang Truce

source("00_packages.R")
data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "panel.rds"))
muni_data <- readRDS(file.path(data_dir, "muni_data.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")
fmt2 <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")
fmt0 <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

pre <- panel[year < 2012]
truce_d <- panel[year %in% c(2012, 2013)]
post_d <- panel[year >= 2014]

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\textit{Panel A: Homicide rate (per 10,000)} \\\\",
  sprintf("Full sample (2002--2021) & %s & %s & %s & %s \\\\",
          fmt2(mean(panel$hom_rate)), fmt2(sd(panel$hom_rate)),
          fmt2(min(panel$hom_rate)), fmt2(max(panel$hom_rate))),
  sprintf("Pre-truce (2002--2011) & %s & %s & & \\\\",
          fmt2(mean(pre$hom_rate)), fmt2(sd(pre$hom_rate))),
  sprintf("Truce (2012--2013) & %s & %s & & \\\\",
          fmt2(mean(truce_d$hom_rate)), fmt2(sd(truce_d$hom_rate))),
  sprintf("Post-collapse (2014--2021) & %s & %s & & \\\\",
          fmt2(mean(post_d$hom_rate)), fmt2(sd(post_d$hom_rate))),
  "\\\\",
  "\\textit{Panel B: Treatment intensity} \\\\",
  sprintf("Gang detentions per 10,000 (2011) & %s & %s & %s & %s \\\\",
          fmt2(mean(muni_data$gang_intensity)), fmt2(sd(muni_data$gang_intensity)),
          fmt2(min(muni_data$gang_intensity)), fmt2(max(muni_data$gang_intensity))),
  sprintf("Any 2011 detentions (=1) & %s & %s & & \\\\",
          fmt2(mean(muni_data$det_2011 > 0)), fmt2(sd(muni_data$det_2011 > 0))),
  sprintf("High-gang municipality (=1) & %s & %s & & \\\\",
          fmt2(mean(muni_data$high_gang)), fmt2(sd(muni_data$high_gang))),
  "\\\\",
  "\\textit{Panel C: Municipality characteristics} \\\\",
  sprintf("Population (2011) & %s & %s & %s & %s \\\\",
          fmt0(round(mean(muni_data$pop_2011, na.rm = TRUE))),
          fmt0(round(sd(muni_data$pop_2011, na.rm = TRUE))),
          fmt0(round(min(muni_data$pop_2011, na.rm = TRUE))),
          fmt0(round(max(muni_data$pop_2011, na.rm = TRUE)))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Panel of %s municipalities observed annually from 2002 to 2021 (N = %s municipality-years). Homicide rates are per 10,000 population from Polic\\'{i}a Nacional Civil and Instituto de Medicina Legal records. Gang intensity is PNC gang-member detentions per 10,000 population in 2011, the last full pre-truce year. Population from ONEC projections.",
          fmt0(uniqueN(panel$muni_id)), fmt0(nrow(panel))),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("=== Table 2: Main Results ===\n")

extract_two <- function(model) {
  ct <- coeftable(model)
  truce_idx <- grep("truce", rownames(ct))
  coll_idx <- grep("collapse|post_collapse", rownames(ct))
  list(
    bt = ct[truce_idx[1], "Estimate"],
    set = ct[truce_idx[1], "Std. Error"],
    pt = ct[truce_idx[1], "Pr(>|t|)"],
    bc = ct[coll_idx[1], "Estimate"],
    sec = ct[coll_idx[1], "Std. Error"],
    pc = ct[coll_idx[1], "Pr(>|t|)"],
    n = nobs(model)
  )
}

m1_c <- extract_two(results$m1)
m2_c <- extract_two(results$m2)
m3_c <- extract_two(results$m3)
m4_c <- extract_two(results$m4)
m5_c <- extract_two(results$m5)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Gang Intensity on Homicide Rates During and After the Truce}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & OLS & Muni FE & Muni+Year FE & Log & Binary \\\\",
  "\\midrule",
  "\\textit{Panel A: Truce period (2012--2013)} \\\\",
  sprintf("Gang intensity $\\times$ Truce & %s%s & %s%s & %s%s & %s%s & \\\\",
          fmt(m1_c$bt, 3), stars(m1_c$pt),
          fmt(m2_c$bt, 3), stars(m2_c$pt),
          fmt(m3_c$bt, 3), stars(m3_c$pt),
          fmt(m4_c$bt, 3), stars(m4_c$pt)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & \\\\",
          fmt(m1_c$set, 3), fmt(m2_c$set, 3), fmt(m3_c$set, 3), fmt(m4_c$set, 3)),
  sprintf("High-gang $\\times$ Truce & & & & & %s%s \\\\",
          fmt(m5_c$bt, 3), stars(m5_c$pt)),
  sprintf(" & & & & & (%s) \\\\", fmt(m5_c$set, 3)),
  "\\\\",
  "\\textit{Panel B: Post-collapse (2014--2021)} \\\\",
  sprintf("Gang intensity $\\times$ Post & %s%s & %s%s & %s%s & %s%s & \\\\",
          fmt(m1_c$bc, 3), stars(m1_c$pc),
          fmt(m2_c$bc, 3), stars(m2_c$pc),
          fmt(m3_c$bc, 3), stars(m3_c$pc),
          fmt(m4_c$bc, 3), stars(m4_c$pc)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) & \\\\",
          fmt(m1_c$sec, 3), fmt(m2_c$sec, 3), fmt(m3_c$sec, 3), fmt(m4_c$sec, 3)),
  sprintf("High-gang $\\times$ Post & & & & & %s%s \\\\",
          fmt(m5_c$bc, 3), stars(m5_c$pc)),
  sprintf(" & & & & & (%s) \\\\", fmt(m5_c$sec, 3)),
  "\\\\",
  "Municipality FE & No & Yes & Yes & Yes & Yes \\\\",
  "Year FE & No & No & Yes & Yes & Yes \\\\",
  sprintf("N & %s & %s & %s & %s & %s \\\\",
          fmt0(m1_c$n), fmt0(m2_c$n), fmt0(m3_c$n), fmt0(m4_c$n), fmt0(m5_c$n)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the municipality level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. The dependent variable is the homicide rate per 10,000 population in columns (1)--(3) and (5), and log(homicide rate + 0.1) in column (4). Gang intensity is standardized 2011 gang-member detentions per 10,000 population. ``Truce'' equals one for 2012--2013. ``Post'' equals one for 2014--2021. Column (5) uses a binary treatment indicator (above-median gang intensity).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("=== Table 3: Event Study ===\n")

es_ct <- coeftable(results$es_cont)
es_rows <- grep("rel_year::", rownames(es_ct))
es_data <- data.table(
  rel_year = as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_ct)[es_rows])),
  beta = es_ct[es_rows, "Estimate"],
  se = es_ct[es_rows, "Std. Error"],
  pval = es_ct[es_rows, "Pr(>|t|)"]
)
es_data <- es_data[order(rel_year)]

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Gang Intensity $\\times$ Year Interactions}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year (relative to 2012) & $\\hat{\\beta}$ & SE & Period \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(es_data))) {
  r <- es_data[i]
  actual_year <- r$rel_year + 2012
  period <- ifelse(actual_year < 2012, "Pre-truce",
                   ifelse(actual_year <= 2013, "Truce", "Post-collapse"))
  lab <- sprintf("$%+d$ (%d)", r$rel_year, actual_year)
  if (r$rel_year == -1) {
    tab3_lines <- c(tab3_lines, sprintf("%s & --- & --- & %s \\\\", lab, period))
  } else {
    tab3_lines <- c(tab3_lines, sprintf(
      "%s & %s%s & (%s) & %s \\\\",
      lab, fmt(r$beta, 3), stars(r$pval), fmt(r$se, 3), period))
  }
}

# Add reference year
tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("N & \\multicolumn{3}{c}{%s} \\\\", fmt0(nobs(results$es_cont))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each row reports the coefficient on the interaction of standardized gang intensity with a year dummy relative to 2012 (truce start). Municipality and year fixed effects included. Standard errors clustered at the municipality level. The reference period is 2011 ($k = -1$).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_eventstudy.tex"))

# ============================================================
# Table 4: Robustness
# ============================================================
cat("=== Table 4: Robustness ===\n")

# Extract coefficients from robustness models
r_dept <- coeftable(rob$m_dept_yr)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Truce ($\\hat{\\beta}_1$)} & \\multicolumn{2}{c}{Post-collapse ($\\hat{\\beta}_2$)} & N \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Specification & Coef. & SE & Coef. & SE & \\\\",
  "\\midrule"
)

# Preferred
ct3 <- coeftable(results$m3)
tab4_lines <- c(tab4_lines, sprintf(
  "Preferred (muni+year FE) & %s%s & (%s) & %s%s & (%s) & %s \\\\",
  fmt(ct3[1,1], 3), stars(ct3[1,4]), fmt(ct3[1,2], 3),
  fmt(ct3[2,1], 3), stars(ct3[2,4]), fmt(ct3[2,2], 3), fmt0(nobs(results$m3))))

# Dept x Year FE
tab4_lines <- c(tab4_lines, sprintf(
  "Dept $\\times$ Year FE & %s%s & (%s) & %s%s & (%s) & %s \\\\",
  fmt(r_dept[1,1], 3), stars(r_dept[1,4]), fmt(r_dept[1,2], 3),
  fmt(r_dept[2,1], 3), stars(r_dept[2,4]), fmt(r_dept[2,2], 3), fmt0(nobs(rob$m_dept_yr))))

# Log outcome
r_log <- coeftable(rob$m_log)
tab4_lines <- c(tab4_lines, sprintf(
  "Log(hom rate + 0.1) & %s%s & (%s) & %s%s & (%s) & %s \\\\",
  fmt(r_log[1,1], 3), stars(r_log[1,4]), fmt(r_log[1,2], 3),
  fmt(r_log[2,1], 3), stars(r_log[2,4]), fmt(r_log[2,2], 3), fmt0(nobs(rob$m_log))))

# Placebo 2005
r_p05 <- coeftable(rob$placebo_2005)
tab4_lines <- c(tab4_lines, sprintf(
  "Placebo truce: 2005 & %s%s & (%s) & %s%s & (%s) & %s \\\\",
  fmt(r_p05[1,1], 3), stars(r_p05[1,4]), fmt(r_p05[1,2], 3),
  fmt(r_p05[2,1], 3), stars(r_p05[2,4]), fmt(r_p05[2,2], 3), fmt0(nobs(rob$placebo_2005))))

# Placebo 2008
r_p08 <- coeftable(rob$placebo_2008)
tab4_lines <- c(tab4_lines, sprintf(
  "Placebo truce: 2008 & %s%s & (%s) & %s%s & (%s) & %s \\\\",
  fmt(r_p08[1,1], 3), stars(r_p08[1,4]), fmt(r_p08[1,2], 3),
  fmt(r_p08[2,1], 3), stars(r_p08[2,4]), fmt(r_p08[2,2], 3), fmt0(nobs(rob$placebo_2008))))

# LODO range
lodo <- rob$lodo_results
tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Leave-one-dept-out range & [%s, %s] & & [%s, %s] & & \\\\",
          fmt(min(lodo$beta_truce), 3), fmt(max(lodo$beta_truce), 3),
          fmt(min(lodo$beta_collapse), 3), fmt(max(lodo$beta_collapse), 3)))

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications include municipality and year fixed effects unless noted. Standard errors clustered at the municipality level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01. Placebo tests use only pre-2012 data with the truce assigned to alternative years. The department $\\times$ year FE specification absorbs all department-level time-varying shocks, isolating within-department variation in gang intensity.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Main estimates
ct3 <- coeftable(results$m3)
beta_truce <- ct3[1, "Estimate"]
se_truce <- ct3[1, "Std. Error"]
beta_collapse <- ct3[2, "Estimate"]
se_collapse <- ct3[2, "Std. Error"]

sd_y <- sd(panel$hom_rate, na.rm = TRUE)
sd_x <- sd(panel$gang_intensity_std, na.rm = TRUE)  # ~1 since standardized

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_truce <- beta_truce * sd_x / sd_y
se_sde_truce <- se_truce * sd_x / sd_y
sde_collapse <- beta_collapse * sd_x / sd_y
se_sde_collapse <- se_collapse * sd_x / sd_y

classify <- function(s) {
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

# Heterogeneity: urban vs rural (population split)
med_pop <- median(muni_data$pop_2011, na.rm = TRUE)
panel[, urban := as.integer(pop_2011 > med_pop)]

m_urban <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                   muni_id + year,
                 data = panel[urban == 1], cluster = ~muni_id)
m_rural <- feols(hom_rate ~ gang_intensity_std:truce + gang_intensity_std:post_collapse |
                   muni_id + year,
                 data = panel[urban == 0], cluster = ~muni_id)

ct_u <- coeftable(m_urban)
ct_r <- coeftable(m_rural)
sd_y_u <- sd(panel[urban == 1]$hom_rate, na.rm = TRUE)
sd_y_r <- sd(panel[urban == 0]$hom_rate, na.rm = TRUE)

sde_u_truce <- ct_u[1,1] * sd_x / sd_y_u
se_sde_u <- ct_u[1,2] * sd_x / sd_y_u
sde_r_truce <- ct_r[1,1] * sd_x / sd_y_r
se_sde_r <- ct_r[1,2] * sd_x / sd_y_r

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} El Salvador. ",
  "\\textbf{Research question:} Did the 2012 gang truce between MS-13 and Barrio 18 differentially reduce homicide rates in municipalities with greater pre-truce gang presence, and did violence rebound after the truce collapsed in 2014? ",
  "\\textbf{Policy mechanism:} The March 2012 truce was a government-brokered cease-fire between the two largest gangs, which reduced gang-on-gang violence and territorial fighting; the truce collapsed in mid-2014 under political pressure, removing the constraint on inter-gang violence. ",
  "\\textbf{Outcome definition:} Annual homicide rate per 10,000 population at the municipality level, combining Polic\\'{i}a Nacional Civil records (2002--2007, 2014--2021) and Instituto de Medicina Legal records (2008--2013). ",
  "\\textbf{Treatment:} Continuous --- gang-member detentions per 10,000 population in 2011, standardized to mean zero and unit variance; measures pre-truce gang presence at the municipality level. ",
  "\\textbf{Data:} PLOS ONE supplementary data (DOI: 10.1371/journal.pone.0330215), 2002--2021, municipality-year observations; N = ",
  fmt0(nrow(panel)), " across ", fmt0(uniqueN(panel$muni_id)), " municipalities. ",
  "\\textbf{Method:} Continuous difference-in-differences with municipality and year fixed effects; standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} All El Salvador municipalities with non-missing homicide data observed annually 2002--2021; treatment intensity varies continuously based on 2011 gang detention records. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Hom.\\ rate & Truce (2012--13) & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_truce, 3), fmt(sd_x, 3), fmt(sd_y, 3),
          fmt(sde_truce, 4), fmt(se_sde_truce, 4), classify(sde_truce)),
  sprintf("Hom.\\ rate & Post-collapse & %s & %s & %s & %s & %s & %s \\\\",
          fmt(beta_collapse, 3), fmt(sd_x, 3), fmt(sd_y, 3),
          fmt(sde_collapse, 4), fmt(se_sde_collapse, 4), classify(sde_collapse)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (truce effect)}} \\\\",
  sprintf("Hom.\\ rate & Urban munis & %s & %s & %s & %s & %s & %s \\\\",
          fmt(ct_u[1,1], 3), fmt(sd_x, 3), fmt(sd_y_u, 3),
          fmt(sde_u_truce, 4), fmt(se_sde_u, 4), classify(sde_u_truce)),
  sprintf("Hom.\\ rate & Rural munis & %s & %s & %s & %s & %s & %s \\\\",
          fmt(ct_r[1,1], 3), fmt(sd_x, 3), fmt(sd_y_r, 3),
          fmt(sde_r_truce, 4), fmt(se_sde_r, 4), classify(sde_r_truce)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))

cat("=== All tables generated ===\n")
cat(sprintf("  Files: %s\n", paste(list.files(table_dir, pattern = "\\.tex$"), collapse = ", ")))
