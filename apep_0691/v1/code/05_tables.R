## 05_tables.R — Generate all LaTeX tables (plain booktabs format)
## APEP-0691: Sugar Tax Without Sticker Shock

source("00_packages.R")

# Load data
dental  <- fread("../data/dental_panel.csv")
obesity <- fread("../data/obesity_panel.csv")
copd    <- fread("../data/copd_panel.csv")

# Treatment coding
dental[, post_reform := as.integer(year >= 2018)]
dental[, transition := as.integer(year == 2016)]
dental[, post := as.integer(year >= 2018)]
dental[, post_full := as.integer(year >= 2021)]
dental[, year_factor := factor(year)]
dental[, trend := year - 2014]
dental[, trend_imd := trend * imd_std]

obesity[, post_announce := as.integer(year >= 2016)]
obesity[, post_implement := as.integer(year >= 2018)]
obesity[, year_factor := factor(year)]
obesity[, trend := year - 2015]
obesity[, trend_imd := trend * imd_std]

copd[, post_announce := as.integer(year >= 2016)]
copd[, post_implement := as.integer(year >= 2018)]
copd[, year_factor := factor(year)]

# Helper: format coefficient with stars
fmt_coef <- function(est, se, p) {
  stars <- ""
  if (p < 0.01) stars <- "^{***}"
  else if (p < 0.05) stars <- "^{**}"
  else if (p < 0.10) stars <- "^{*}"
  paste0(sprintf("%.3f", est), "$", stars, "$")
}

fmt_se <- function(se) paste0("(", sprintf("%.3f", se), ")")

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================

dental_pre <- dental[year <= 2014]
dental_post <- dental[year >= 2018]
obesity_pre <- obesity[year <= 2015]
obesity_post <- obesity[year >= 2016 & year != 2020]

tab1_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Childhood Health Outcomes by Deprivation}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llrrccccc}",
  "\\toprule",
  " & Period & LAs & Obs & Mean & SD & Q1 & Q5 & Gap \\\\",
  "\\midrule",
  "\\multicolumn{9}{l}{\\textit{Panel A: Dental Decay in 5-Year-Olds (\\%)}} \\\\"
)

for (subset_data in list(list(dental_pre, "Pre-SDIL (2007--2014)"),
                          list(dental_post, "Post-SDIL (2018--2023)"))) {
  d <- subset_data[[1]]
  label <- subset_data[[2]]
  tab1_tex <- c(tab1_tex, paste0(
    " & ", label, " & ",
    length(unique(d$area_code)), " & ",
    format(nrow(d), big.mark = ","), " & ",
    sprintf("%.1f", mean(d$value, na.rm = TRUE)), " & ",
    sprintf("%.1f", sd(d$value, na.rm = TRUE)), " & ",
    sprintf("%.1f", mean(d$value[d$imd_quintile == 1], na.rm = TRUE)), " & ",
    sprintf("%.1f", mean(d$value[d$imd_quintile == 5], na.rm = TRUE)), " & ",
    sprintf("%.1f", mean(d$value[d$imd_quintile == 5], na.rm = TRUE) -
              mean(d$value[d$imd_quintile == 1], na.rm = TRUE)), " \\\\"
  ))
}

tab1_tex <- c(tab1_tex,
              "[0.3em]",
              "\\multicolumn{9}{l}{\\textit{Panel B: Childhood Obesity, Reception Year (\\%)}} \\\\")

for (subset_data in list(list(obesity_pre, "Pre-SDIL (2006--2015)"),
                          list(obesity_post, "Post-SDIL (2016--2024, excl.\\ 2020)"))) {
  d <- subset_data[[1]]
  label <- subset_data[[2]]
  tab1_tex <- c(tab1_tex, paste0(
    " & ", label, " & ",
    length(unique(d$area_code)), " & ",
    format(nrow(d), big.mark = ","), " & ",
    sprintf("%.1f", mean(d$value, na.rm = TRUE)), " & ",
    sprintf("%.1f", sd(d$value, na.rm = TRUE)), " & ",
    sprintf("%.1f", mean(d$value[d$imd_quintile == 1], na.rm = TRUE)), " & ",
    sprintf("%.1f", mean(d$value[d$imd_quintile == 5], na.rm = TRUE)), " & ",
    sprintf("%.1f", mean(d$value[d$imd_quintile == 5], na.rm = TRUE) -
              mean(d$value[d$imd_quintile == 1], na.rm = TRUE)), " \\\\"
  ))
}

tab1_tex <- c(tab1_tex,
              "\\bottomrule",
              "\\end{tabular}",
              "\\par\\vspace{0.3em}",
              "{\\footnotesize \\textit{Notes:} Dental decay is the percentage of 5-year-olds with experience of visually obvious dental decay, from the National Dental Epidemiology Programme (NDEP). Childhood obesity is the percentage of Reception-year children (age 4--5) classified as overweight or obese (BMI $\\geq$ 85th centile), from the National Child Measurement Programme (NCMP). Q1 = least deprived IMD 2019 quintile; Q5 = most deprived. Gap = Q5 mean $-$ Q1 mean. COVID year 2020/21 excluded from obesity post-period due to incomplete NCMP data collection.}",
              "\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ============================================================================
# Table 2: Main Results — Dental Decay
# ============================================================================

m1 <- feols(value ~ post_reform:imd_std | area_code + year_factor,
            data = dental, cluster = ~area_code)
m2 <- feols(value ~ transition:imd_std + post:imd_std | area_code + year_factor,
            data = dental, cluster = ~area_code)
m3 <- feols(value ~ post_full:imd_std | area_code + year_factor,
            data = dental, cluster = ~area_code)
m4 <- feols(value ~ post_reform:imd_std + trend_imd | area_code + year_factor,
            data = dental, cluster = ~area_code)

# Extract coefficients
get_coef <- function(mod, var) {
  ct <- coeftable(mod)
  idx <- which(rownames(ct) == var)
  if (length(idx) == 0) return(list(est = NA, se = NA, p = NA))
  list(est = ct[idx, 1], se = ct[idx, 2], p = ct[idx, 4])
}

tab2_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of the SDIL on Dental Decay in 5-Year-Olds}",
  "\\label{tab:dental}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

# Row: Post-Reform × Deprivation
r1 <- get_coef(m1, "post_reform:imd_std")
r4 <- get_coef(m4, "post_reform:imd_std")
tab2_tex <- c(tab2_tex,
              paste0("Post-Reform $\\times$ Deprivation & ",
                     fmt_coef(r1$est, r1$se, r1$p), " & & & ",
                     fmt_coef(r4$est, r4$se, r4$p), " \\\\"),
              paste0(" & ", fmt_se(r1$se), " & & & ", fmt_se(r4$se), " \\\\"),
              "[0.3em]")

# Row: Transition × Deprivation
r2t <- get_coef(m2, "transition:imd_std")
tab2_tex <- c(tab2_tex,
              paste0("Transition $\\times$ Deprivation & & ",
                     fmt_coef(r2t$est, r2t$se, r2t$p), " & & \\\\"),
              paste0(" & & ", fmt_se(r2t$se), " & & \\\\"),
              "[0.3em]")

# Row: Post-Implementation × Deprivation
r2p <- get_coef(m2, "imd_std:post")
tab2_tex <- c(tab2_tex,
              paste0("Post-Implementation $\\times$ Dep. & & ",
                     fmt_coef(r2p$est, r2p$se, r2p$p), " & & \\\\"),
              paste0(" & & ", fmt_se(r2p$se), " & & \\\\"),
              "[0.3em]")

# Row: Full Exposure × Deprivation
r3 <- get_coef(m3, "post_full:imd_std")
tab2_tex <- c(tab2_tex,
              paste0("Full Exposure $\\times$ Deprivation & & & ",
                     fmt_coef(r3$est, r3$se, r3$p), " & \\\\"),
              paste0(" & & & ", fmt_se(r3$se), " & \\\\"),
              "[0.3em]")

# Row: Trend × Deprivation
r4t <- get_coef(m4, "trend_imd")
tab2_tex <- c(tab2_tex,
              paste0("Trend $\\times$ Deprivation & & & & ",
                     fmt_coef(r4t$est, r4t$se, r4t$p), " \\\\"),
              paste0(" & & & & ", fmt_se(r4t$se), " \\\\"))

tab2_tex <- c(tab2_tex,
              "\\midrule",
              paste0("Observations & ", format(nobs(m1), big.mark = ","),
                     " & ", format(nobs(m2), big.mark = ","),
                     " & ", format(nobs(m3), big.mark = ","),
                     " & ", format(nobs(m4), big.mark = ","), " \\\\"),
              paste0("Within $R^2$ & ", sprintf("%.4f", fitstat(m1, "wr2")$wr2),
                     " & ", sprintf("%.4f", fitstat(m2, "wr2")$wr2),
                     " & ", sprintf("%.4f", fitstat(m3, "wr2")$wr2),
                     " & ", sprintf("%.4f", fitstat(m4, "wr2")$wr2), " \\\\"),
              "LA FE & Yes & Yes & Yes & Yes \\\\",
              "Year FE & Yes & Yes & Yes & Yes \\\\",
              "\\bottomrule",
              "\\end{tabular}",
              "\\par\\vspace{0.3em}",
              "{\\footnotesize \\textit{Notes:} Dependent variable is dental decay prevalence (\\%) in 5-year-olds. Deprivation is the standardized IMD 2019 score (mean 0, SD 1). Post-Reform = 1 for 2018/19 onward (reformulation complete). Transition = 2016/17 only (announcement year). Full Exposure = 1 for 2021/22 onward (cohorts with near-complete lifetime exposure to reformulated products). Column (4) adds a linear deprivation-specific time trend. Standard errors clustered by local authority in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.}",
              "\\end{table}")

writeLines(tab2_tex, "../tables/tab2_dental.tex")
cat("Table 2 written.\n")

# ============================================================================
# Table 3: Main Results — Childhood Obesity
# ============================================================================

obesity_nocovid <- obesity[year != 2020]

o1 <- feols(value ~ post_announce:imd_std | area_code + year_factor,
            data = obesity, cluster = ~area_code)
o2 <- feols(value ~ post_announce:imd_std + post_implement:imd_std | area_code + year_factor,
            data = obesity, cluster = ~area_code)
o3 <- feols(value ~ post_announce:imd_std | area_code + year_factor,
            data = obesity_nocovid, cluster = ~area_code)
o4 <- feols(value ~ post_announce:imd_std + trend_imd | area_code + year_factor,
            data = obesity, cluster = ~area_code)

tab3_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of the SDIL on Childhood Obesity (Reception Year)}",
  "\\label{tab:obesity}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule"
)

# Post-Announce
pa1 <- get_coef(o1, "post_announce:imd_std")
pa2 <- get_coef(o2, "post_announce:imd_std")
pa3 <- get_coef(o3, "post_announce:imd_std")
pa4 <- get_coef(o4, "post_announce:imd_std")

tab3_tex <- c(tab3_tex,
              paste0("Post-Announce $\\times$ Deprivation & ",
                     fmt_coef(pa1$est, pa1$se, pa1$p), " & ",
                     fmt_coef(pa2$est, pa2$se, pa2$p), " & ",
                     fmt_coef(pa3$est, pa3$se, pa3$p), " & ",
                     fmt_coef(pa4$est, pa4$se, pa4$p), " \\\\"),
              paste0(" & ", fmt_se(pa1$se), " & ", fmt_se(pa2$se),
                     " & ", fmt_se(pa3$se), " & ", fmt_se(pa4$se), " \\\\"),
              "[0.3em]")

# Post-Implement
pi2 <- get_coef(o2, "imd_std:post_implement")
tab3_tex <- c(tab3_tex,
              paste0("Post-Implement $\\times$ Deprivation & & ",
                     fmt_coef(pi2$est, pi2$se, pi2$p), " & & \\\\"),
              paste0(" & & ", fmt_se(pi2$se), " & & \\\\"),
              "[0.3em]")

# Trend
tr4 <- get_coef(o4, "trend_imd")
tab3_tex <- c(tab3_tex,
              paste0("Trend $\\times$ Deprivation & & & & ",
                     fmt_coef(tr4$est, tr4$se, tr4$p), " \\\\"),
              paste0(" & & & & ", fmt_se(tr4$se), " \\\\"))

tab3_tex <- c(tab3_tex,
              "\\midrule",
              paste0("Observations & ", format(nobs(o1), big.mark = ","),
                     " & ", format(nobs(o2), big.mark = ","),
                     " & ", format(nobs(o3), big.mark = ","),
                     " & ", format(nobs(o4), big.mark = ","), " \\\\"),
              paste0("Within $R^2$ & ", sprintf("%.4f", fitstat(o1, "wr2")$wr2),
                     " & ", sprintf("%.4f", fitstat(o2, "wr2")$wr2),
                     " & ", sprintf("%.4f", fitstat(o3, "wr2")$wr2),
                     " & ", sprintf("%.4f", fitstat(o4, "wr2")$wr2), " \\\\"),
              "Excl.\\ COVID & No & No & Yes & No \\\\",
              "LA FE & Yes & Yes & Yes & Yes \\\\",
              "Year FE & Yes & Yes & Yes & Yes \\\\",
              "\\bottomrule",
              "\\end{tabular}",
              "\\par\\vspace{0.3em}",
              "{\\footnotesize \\textit{Notes:} Dependent variable is the percentage of Reception-year children classified as overweight or obese. Deprivation is the standardized IMD 2019 score. Post-Announce = 1 for 2016/17 onward. Post-Implement = 1 for 2018/19 onward. Column (3) drops the 2020/21 COVID year. Column (4) adds a linear deprivation-specific time trend. The positive coefficients indicate the deprivation gradient in childhood obesity \\textit{widened} after the SDIL announcement. Standard errors clustered by LA in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.}",
              "\\end{table}")

writeLines(tab3_tex, "../tables/tab3_obesity.tex")
cat("Table 3 written.\n")

# ============================================================================
# Table 4: Placebo and Event Study Diagnostics
# ============================================================================

copd_precovid <- copd[year <= 2019]
copd_precovid[, year_factor := factor(year)]

c1 <- feols(value ~ post_announce:imd_std + post_implement:imd_std | area_code + year_factor,
            data = copd_precovid, cluster = ~area_code)
c1_ct <- coeftable(c1)

# Dental event study
dental[, year_rel := factor(year, levels = c(2014, 2007, 2011, 2016, 2018, 2021, 2023))]
es_d <- feols(value ~ year_rel:imd_std | area_code + year_factor,
              data = dental, cluster = ~area_code)
es_d_ct <- coeftable(es_d)

# Obesity event study
obesity[, year_rel := relevel(year_factor, ref = "2015")]
es_o <- feols(value ~ year_rel:imd_std | area_code + year_factor,
              data = obesity, cluster = ~area_code)
es_o_ct <- coeftable(es_o)

get_es <- function(ct, varname) {
  idx <- which(rownames(ct) == varname)
  if (length(idx) == 0) return(list(est = NA, se = NA, p = NA))
  list(est = ct[idx, 1], se = ct[idx, 2], p = ct[idx, 4])
}

tab4_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Placebo and Pre-Trend Diagnostics}",
  "\\label{tab:placebo}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Dental Decay & Childhood Obesity \\\\",
  "\\midrule",
  "\\multicolumn{3}{l}{\\textit{Panel A: COPD Emergency Admissions Placebo (per 100,000; 2010--2019)}} \\\\"
)

tab4_tex <- c(tab4_tex,
              paste0("Post-Announce $\\times$ Dep. & \\multicolumn{2}{c}{",
                     sprintf("%.2f", c1_ct[1, 1]), "} \\\\"),
              paste0(" & \\multicolumn{2}{c}{(", sprintf("%.2f", c1_ct[1, 2]), ")} \\\\"),
              paste0("Post-Implement $\\times$ Dep. & \\multicolumn{2}{c}{",
                     sprintf("%.2f", c1_ct[2, 1]), "} \\\\"),
              paste0(" & \\multicolumn{2}{c}{(", sprintf("%.2f", c1_ct[2, 2]), ")} \\\\"),
              "[0.5em]",
              "\\multicolumn{3}{l}{\\textit{Panel B: Pre-Period Event Study Coefficients ($\\beta_t \\times$ IMD)}} \\\\",
              "Reference year: & 2014 & 2015 \\\\")

# Dental pre-periods
for (yr in c(2007, 2011)) {
  r <- get_es(es_d_ct, paste0("year_rel", yr, ":imd_std"))
  if (!is.na(r$est)) {
    tab4_tex <- c(tab4_tex,
                  paste0(yr, " & ", fmt_coef(r$est, r$se, r$p), " & \\\\"),
                  paste0(" & ", fmt_se(r$se), " & \\\\"))
  }
}

# Obesity pre-periods (selected)
for (yr in c(2008, 2010, 2012, 2014)) {
  r <- get_es(es_o_ct, paste0("year_rel", yr, ":imd_std"))
  if (!is.na(r$est)) {
    tab4_tex <- c(tab4_tex,
                  paste0(yr, " & & ", fmt_coef(r$est, r$se, r$p), " \\\\"),
                  paste0(" & & ", fmt_se(r$se), " \\\\"))
  }
}

tab4_tex <- c(tab4_tex,
              "[0.5em]",
              "\\multicolumn{3}{l}{\\textit{Panel C: Post-SDIL Event Study Coefficients}} \\\\")

for (yr in c(2018, 2021, 2023)) {
  d_r <- get_es(es_d_ct, paste0("year_rel", yr, ":imd_std"))
  o_r <- get_es(es_o_ct, paste0("year_rel", yr, ":imd_std"))
  d_val <- if (!is.na(d_r$est)) fmt_coef(d_r$est, d_r$se, d_r$p) else ""
  d_se <- if (!is.na(d_r$se)) fmt_se(d_r$se) else ""
  o_val <- if (!is.na(o_r$est)) fmt_coef(o_r$est, o_r$se, o_r$p) else ""
  o_se <- if (!is.na(o_r$se)) fmt_se(o_r$se) else ""
  tab4_tex <- c(tab4_tex,
                paste0(yr, " & ", d_val, " & ", o_val, " \\\\"),
                paste0(" & ", d_se, " & ", o_se, " \\\\"))
}

tab4_tex <- c(tab4_tex,
              "\\midrule",
              "LA FE & Yes & Yes \\\\",
              "Year FE & Yes & Yes \\\\",
              "\\bottomrule",
              "\\end{tabular}",
              "\\par\\vspace{0.3em}",
              "{\\footnotesize \\textit{Notes:} Panel A reports coefficients from regressing COPD emergency admissions (per 100,000) on Post-Announce and Post-Implement interacted with standardized IMD, limited to pre-COVID years (2010--2019). Neither coefficient is statistically significant, confirming the placebo. Panels B and C report event study coefficients ($\\beta_t \\times$ IMD) with 2014 (dental) and 2015 (obesity) as reference years. Dental pre-period coefficients fluctuate around zero. Obesity pre-period coefficients are negative and significant, indicating a pre-existing trend toward \\textit{narrowing} of the deprivation gradient prior to the SDIL. Standard errors clustered by LA in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.}",
              "\\end{table}")

writeLines(tab4_tex, "../tables/tab4_placebo.tex")
cat("Table 4 written.\n")

# ============================================================================
# Table 5: Quintile-Level Changes
# ============================================================================

dental_change <- merge(
  dental[year <= 2014, .(pre_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  dental[year >= 2018, .(post_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  by = "imd_quintile"
)
dental_change[, change := post_mean - pre_mean]

obesity_change <- merge(
  obesity[year <= 2015, .(pre_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  obesity[year >= 2016 & year != 2020, .(post_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  by = "imd_quintile"
)
obesity_change[, change := post_mean - pre_mean]

qlabels <- c("Q1 (Least deprived)", "Q2", "Q3", "Q4", "Q5 (Most deprived)")

tab5_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Pre-Post Changes in Health Outcomes by Deprivation Quintile}",
  "\\label{tab:quintile}",
  "\\begin{tabular}{lccccccc}",
  "\\toprule",
  " & \\multicolumn{3}{c}{Dental Decay (\\%)} & & \\multicolumn{3}{c}{Obesity (\\%)} \\\\",
  "\\cmidrule{2-4} \\cmidrule{6-8}",
  "Quintile & Pre & Post & $\\Delta$ & & Pre & Post & $\\Delta$ \\\\",
  "\\midrule"
)

for (q in 1:5) {
  d <- dental_change[imd_quintile == q]
  o <- obesity_change[imd_quintile == q]
  tab5_tex <- c(tab5_tex, paste0(
    qlabels[q], " & ",
    sprintf("%.1f", d$pre_mean), " & ",
    sprintf("%.1f", d$post_mean), " & ",
    sprintf("%.1f", d$change), " & & ",
    sprintf("%.1f", o$pre_mean), " & ",
    sprintf("%.1f", o$post_mean), " & ",
    sprintf("%.1f", o$change), " \\\\"
  ))
}

# Gap row
d_gap_pre <- dental_change[5, pre_mean] - dental_change[1, pre_mean]
d_gap_post <- dental_change[5, post_mean] - dental_change[1, post_mean]
o_gap_pre <- obesity_change[5, pre_mean] - obesity_change[1, pre_mean]
o_gap_post <- obesity_change[5, post_mean] - obesity_change[1, post_mean]

tab5_tex <- c(tab5_tex,
              "\\midrule",
              paste0("Q5 $-$ Q1 Gap & ",
                     sprintf("%.1f", d_gap_pre), " & ",
                     sprintf("%.1f", d_gap_post), " & ",
                     sprintf("%.1f", d_gap_post - d_gap_pre), " & & ",
                     sprintf("%.1f", o_gap_pre), " & ",
                     sprintf("%.1f", o_gap_post), " & ",
                     sprintf("%.1f", o_gap_post - o_gap_pre), " \\\\"),
              "\\bottomrule",
              "\\end{tabular}",
              "\\par\\vspace{0.3em}",
              "{\\footnotesize \\textit{Notes:} Pre-SDIL averages: dental decay 2007--2014 (3 waves), obesity 2006--2015 (10 years). Post-SDIL averages: dental decay 2018--2023 (3 waves), obesity 2016--2024 excluding 2020/21 (8 years). Quintiles based on IMD 2019 deprivation scores. $\\Delta$ = Post $-$ Pre. The Q5$-$Q1 gap measures the absolute health inequality between most and least deprived quintiles. For dental decay, the gap narrowed from 14.0 to 13.9 percentage points. For obesity, the gap widened from 4.3 to 5.3 percentage points.}",
              "\\end{table}")

writeLines(tab5_tex, "../tables/tab5_quintile.tex")
cat("Table 5 written.\n")

# ============================================================================
# SDE Table (tabF1_sde.tex)
# ============================================================================

sd_dental <- sd(dental$value, na.rm = TRUE)
sd_obesity <- sd(obesity$value, na.rm = TRUE)

beta_d <- coef(m1)["post_reform:imd_std"]
se_d <- sqrt(vcov(m1)["post_reform:imd_std", "post_reform:imd_std"])
sde_d <- beta_d / sd_dental
sde_se_d <- se_d / sd_dental

beta_o <- coef(o1)["post_announce:imd_std"]
se_o <- sqrt(vcov(o1)["post_announce:imd_std", "post_announce:imd_std"])
sde_o <- beta_o / sd_obesity
sde_se_o <- se_o / sd_obesity

classify <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_tex <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  paste0("Dental Decay & ", sprintf("%.3f", beta_d), " & ",
         sprintf("%.3f", se_d), " & ", sprintf("%.2f", sd_dental), " & ",
         sprintf("%.4f", sde_d), " & ", sprintf("%.4f", sde_se_d), " & ",
         classify(sde_d), " \\\\"),
  paste0("Childhood Obesity & ", sprintf("%.3f", beta_o), " & ",
         sprintf("%.3f", se_o), " & ", sprintf("%.2f", sd_obesity), " & ",
         sprintf("%.4f", sde_o), " & ", sprintf("%.4f", sde_se_o), " & ",
         classify(sde_o), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  paste0("{\\footnotesize \\textit{Notes:} SDE = $\\hat{\\beta}$ / SD($Y$). ",
         "Treatment intensity is a 1-SD increase in the IMD 2019 deprivation index. ",
         "\\textbf{Research question:} Whether the UK Soft Drinks Industry Levy differentially ",
         "improved childhood health in more-deprived local authorities. ",
         "\\textbf{Data:} PHE/OHID Fingertips; dental decay from the NDEP (348 LAs, 7 waves, 2007--2023); ",
         "obesity from the NCMP (348 LAs, 19 years, 2006--2024). ",
         "\\textbf{Method:} Continuous treatment intensity DiD with LA and year FE; SEs clustered by LA. ",
         "\\textbf{Sample:} $N$ = 2,104 (dental); 5,943 (obesity). ",
         "Classification labels refer to the magnitude of the standardized point estimate, ",
         "not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), ",
         "not a failure to reject a null hypothesis.}"),
  "\\end{table}")

writeLines(sde_tex, "../tables/tabF1_sde.tex")
cat("SDE table written.\n")

# ============================================================================
# Save all regression results for reference
# ============================================================================

all_results <- list(
  dental_main = m1, dental_decomp = m2,
  dental_full = m3, dental_trend = m4,
  obesity_main = o1, obesity_decomp = o2,
  obesity_nocovid = o3, obesity_trend = o4,
  copd_placebo = c1,
  dental_es = es_d, obesity_es = es_o
)
saveRDS(all_results, "../data/regression_results.rds")

cat("\n=== All tables generated successfully ===\n")
