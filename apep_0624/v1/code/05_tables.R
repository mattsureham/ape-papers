# 05_tables.R — Generate all LaTeX tables
# apep_0624: Canada Carbon Backstop and Facility-Level Emissions

source("00_packages.R")

cat("=== Loading results ===\n")
df_bal <- fread("../data/balanced_panel.csv")
main <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
refined <- readRDS("../data/refined_results.rds")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

df_bal[, co2e_k := total_co2e / 1000]

# Pre-treatment stats by group
pre <- df_bal[year < 2019]
post <- df_bal[year >= 2019]

# Compute stats
stats_fn <- function(dt, group_name) {
  dt[, .(
    Group = group_name,
    `N (facility-years)` = .N,
    Facilities = uniqueN(facility_id),
    `Mean emissions (kt CO2e)` = round(mean(total_co2e / 1000, na.rm = TRUE), 1),
    `Median emissions (kt CO2e)` = round(median(total_co2e / 1000, na.rm = TRUE), 1),
    `SD emissions (kt CO2e)` = round(sd(total_co2e / 1000, na.rm = TRUE), 1),
    `Mean CO2 (kt)` = round(mean(co2_tonnes / 1000, na.rm = TRUE), 1),
    `Mean CH4 (kt CO2e)` = round(mean(ch4_co2e / 1000, na.rm = TRUE), 1)
  )]
}

s1 <- stats_fn(pre[backstop == 1], "Backstop (pre)")
s2 <- stats_fn(pre[backstop == 0], "Own-pricing (pre)")
s3 <- stats_fn(post[backstop == 1], "Backstop (post)")
s4 <- stats_fn(post[backstop == 0], "Own-pricing (post)")

stats <- rbindlist(list(s1, s2, s3, s4))

# Build LaTeX table
tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Facility-Level Emissions by Treatment Group}\n",
  "\\label{tab:sumstats}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Backstop} & \\multicolumn{2}{c}{Own-Pricing} \\\\\n",
  " & Pre-2019 & Post-2019 & Pre-2019 & Post-2019 \\\\\n",
  "\\hline\n",
  sprintf("Facility-years & %s & %s & %s & %s \\\\\n",
          format(s1$`N (facility-years)`, big.mark = ","),
          format(s3$`N (facility-years)`, big.mark = ","),
          format(s2$`N (facility-years)`, big.mark = ","),
          format(s4$`N (facility-years)`, big.mark = ",")),
  sprintf("Unique facilities & %s & %s & %s & %s \\\\\n",
          s1$Facilities, s3$Facilities, s2$Facilities, s4$Facilities),
  sprintf("Mean emissions (kt CO$_2$e) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          s1$`Mean emissions (kt CO2e)`, s3$`Mean emissions (kt CO2e)`,
          s2$`Mean emissions (kt CO2e)`, s4$`Mean emissions (kt CO2e)`),
  sprintf("Median emissions (kt CO$_2$e) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          s1$`Median emissions (kt CO2e)`, s3$`Median emissions (kt CO2e)`,
          s2$`Median emissions (kt CO2e)`, s4$`Median emissions (kt CO2e)`),
  sprintf("SD emissions (kt CO$_2$e) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          s1$`SD emissions (kt CO2e)`, s3$`SD emissions (kt CO2e)`,
          s2$`SD emissions (kt CO2e)`, s4$`SD emissions (kt CO2e)`),
  sprintf("Mean CO$_2$ (kt) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          s1$`Mean CO2 (kt)`, s3$`Mean CO2 (kt)`,
          s2$`Mean CO2 (kt)`, s4$`Mean CO2 (kt)`),
  sprintf("Mean CH$_4$ (kt CO$_2$e) & %.1f & %.1f & %.1f & %.1f \\\\\n",
          s1$`Mean CH4 (kt CO2e)`, s3$`Mean CH4 (kt CO2e)`,
          s2$`Mean CH4 (kt CO2e)`, s4$`Mean CH4 (kt CO2e)`),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} Summary statistics for ECCC GHGRP facility-level emissions data, ",
  "2004--2023 balanced panel (facilities observed both pre and post-2019). ",
  "Backstop provinces: Ontario, Saskatchewan, Manitoba, New Brunswick (received federal carbon pricing backstop April 2019). ",
  "Own-pricing provinces: British Columbia (carbon tax since 2008), Quebec (cap-and-trade since 2013), Alberta (SGER/CCIR/TIER since 2007). ",
  "kt = kilotonnes. CO$_2$e = carbon dioxide equivalent.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ============================================================
# TABLE 2: Main DiD Results + DDD
# ============================================================
cat("\n=== Table 2: Main Results ===\n")

# Extract coefficients and SEs
get_row <- function(model, label, extra = list()) {
  cf <- coef(model)
  ses <- se(model)
  pv <- pvalue(model)
  tp <- "treat_post"
  if (!tp %in% names(cf)) tp <- names(cf)[1]
  c(list(
    label = label,
    coef = cf[tp],
    se = ses[tp],
    pval = pv[tp],
    n = model$nobs,
    r2w = fitstat(model, "wr2")$wr2
  ), extra)
}

r1 <- get_row(main$m2, "All sectors", list(spec = "(1)"))
r2 <- get_row(main$m3, "All sectors, sector$\\times$year FE", list(spec = "(2)"))
r3 <- get_row(refined$m_no_util, "Excluding utilities", list(spec = "(3)"))
r4 <- get_row(refined$m_eite, "EITE sectors only", list(spec = "(4)"))

# DDD model has two coefficients
ddd <- refined$m_ddd
ddd_cf <- coef(ddd)
ddd_se <- se(ddd)
ddd_pv <- pvalue(ddd)

stars_fn <- function(p) {
  if (p < 0.01) "***"
  else if (p < 0.05) "**"
  else if (p < 0.1) "*"
  else ""
}

format_coef <- function(cf, se, pval) {
  sprintf("%.4f%s", cf, stars_fn(pval))
}

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Federal Carbon Backstop on Facility-Level Emissions}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & All & All & Excl. & EITE & DDD \\\\\n",
  " & sectors & sectors & utilities & only & \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{6}{l}{\\textit{Dependent variable: log(emissions, tonnes CO$_2$e)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("Backstop $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
          format_coef(r1$coef, r1$se, r1$pval),
          format_coef(r2$coef, r2$se, r2$pval),
          format_coef(r3$coef, r3$se, r3$pval),
          format_coef(r4$coef, r4$se, r4$pval),
          format_coef(ddd_cf["treat_post"], ddd_se["treat_post"], ddd_pv["treat_post"])),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
          r1$se, r2$se, r3$se, r4$se, ddd_se["treat_post"]),
  sprintf("Backstop $\\times$ Post $\\times$ Utility & & & & & %s \\\\\n",
          format_coef(ddd_cf["treat_post:utility"], ddd_se["treat_post:utility"],
                      ddd_pv["treat_post:utility"])),
  sprintf(" & & & & & (%.4f) \\\\\n", ddd_se["treat_post:utility"]),
  "\\addlinespace\n",
  sprintf("Implied \\%% change & %.1f\\%% & %.1f\\%% & %.1f\\%% & %.1f\\%% & %.1f\\%% \\\\\n",
          (exp(r1$coef) - 1) * 100, (exp(r2$coef) - 1) * 100,
          (exp(r3$coef) - 1) * 100, (exp(r4$coef) - 1) * 100,
          (exp(ddd_cf["treat_post"]) - 1) * 100),
  "\\hline\n",
  "Facility FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & & Yes & Yes & \\\\\n",
  "Sector $\\times$ Year FE & & Yes & & & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          format(r1$n, big.mark = ","), format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","), format(r4$n, big.mark = ","),
          format(ddd$nobs, big.mark = ",")),
  "Clusters (provinces) & 7 & 7 & 7 & 7 & 7 \\\\\n",
  sprintf("Within $R^2$ & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
          r1$r2w, r2$r2w, r3$r2w, r4$r2w, fitstat(ddd, "wr2")$wr2),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\small\n",
  "\\item \\textit{Notes:} OLS estimates with facility and year (or sector$\\times$year) fixed effects. ",
  "Dependent variable is log total emissions (tonnes CO$_2$e). ",
  "Backstop provinces (ON, SK, MB, NB) received federal carbon pricing backstop in April 2019; ",
  "own-pricing provinces (BC, QC, AB) had pre-existing carbon pricing systems. ",
  "Column (3) excludes utilities (NAICS 22), which include Ontario's coal-fired generators phased out before 2019. ",
  "Column (4) restricts to energy-intensive trade-exposed sectors (mining/oil/gas and manufacturing). ",
  "Column (5) is a triple difference interacting the backstop effect with a utilities sector indicator. ",
  "Standard errors clustered at the province level in parentheses. ",
  "Balanced panel of facilities observed both pre and post-2019, 2004--2023. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: Event Study Coefficients (short panel, 2017-2023)
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

es_short <- robust$es_short
es_cf <- coeftable(es_short)
es_dt <- data.table(
  year = as.integer(gsub("year::|:backstop", "", rownames(es_cf))),
  estimate = es_cf[, 1],
  se = es_cf[, 2],
  pval = es_cf[, 4]
)

# Also get the no-utility event study
es_noutil <- refined$es_no_util
es_noutil_cf <- coeftable(es_noutil)
es_noutil_dt <- data.table(
  year = as.integer(gsub("year::|:backstop", "", rownames(es_noutil_cf))),
  estimate_nu = es_noutil_cf[, 1],
  se_nu = es_noutil_cf[, 2],
  pval_nu = es_noutil_cf[, 4]
)

# Merge
es_merged <- merge(es_dt, es_noutil_dt, by = "year", all = TRUE)
es_merged <- es_merged[order(year)]

# Add reference year
ref_row <- data.table(year = 2018, estimate = 0, se = NA, pval = NA,
                      estimate_nu = 0, se_nu = NA, pval_nu = NA)
es_merged <- rbind(es_merged, ref_row)[order(year)]

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Backstop Effect by Year}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{All Sectors} & \\multicolumn{2}{c}{Excl. Utilities} \\\\",
  "Year & Estimate & SE & Estimate & SE \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_merged))) {
  r <- es_merged[i]
  if (r$year == 2018) {
    tab3_lines <- c(tab3_lines,
                    sprintf("%d & [ref.] & & [ref.] & \\\\", r$year))
  } else {
    s1_str <- if (!is.na(r$pval)) sprintf("%.4f%s", r$estimate, stars_fn(r$pval)) else ""
    s1_se <- if (!is.na(r$se)) sprintf("(%.4f)", r$se) else ""
    s2_str <- if (!is.na(r$pval_nu)) sprintf("%.4f%s", r$estimate_nu, stars_fn(r$pval_nu)) else ""
    s2_se <- if (!is.na(r$se_nu)) sprintf("(%.4f)", r$se_nu) else ""
    tab3_lines <- c(tab3_lines,
                    sprintf("%d & %s & %s & %s & %s \\\\", r$year, s1_str, s1_se, s2_str, s2_se))
  }
  if (r$year == 2018) tab3_lines <- c(tab3_lines, "\\hline")
}

tab3_lines <- c(tab3_lines,
                "\\hline\\hline",
                "\\end{tabular}",
                "\\begin{tablenotes}",
                "\\small",
                paste0("\\item \\textit{Notes:} Event study coefficients from facility-year panel regressions ",
                       "with facility and year fixed effects. All-sectors panel (left) uses 2017--2023 balanced sample; ",
                       "excluding-utilities panel (right) uses 2009--2023 balanced sample. ",
                       "Reference year: 2018 (last year before federal backstop). ",
                       "Standard errors clustered at the province level. ",
                       "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
                "\\end{tablenotes}",
                "\\end{table}")

writeLines(tab3_lines, "../tables/tab3_eventstudy.tex")

# ============================================================
# TABLE 4: Mechanism — Gas and Sector Decomposition
# ============================================================
cat("\n=== Table 4: Mechanism ===\n")

m_co2 <- robust$m_co2
m_ch4 <- robust$m_ch4
m_n2o <- robust$m_n2o

# Sector results
sect_res <- robust$sector_results

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Mechanism Decomposition: Gas Type and Sector Heterogeneity}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Estimate & SE & $N$ & Facilities \\\\\n",
  "\\hline\n",
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: By greenhouse gas}} \\\\\n",
  "\\addlinespace\n",
  sprintf("CO$_2$ (combustion) & %s & (%.4f) & %s & \\\\\n",
          format_coef(coef(m_co2)[1], se(m_co2)[1], pvalue(m_co2)[1]),
          se(m_co2)[1], format(m_co2$nobs, big.mark = ",")),
  sprintf("CH$_4$ (process/fugitive) & %s & (%.4f) & %s & \\\\\n",
          format_coef(coef(m_ch4)[1], se(m_ch4)[1], pvalue(m_ch4)[1]),
          se(m_ch4)[1], format(m_ch4$nobs, big.mark = ",")),
  sprintf("N$_2$O & %s & (%.4f) & %s & \\\\\n",
          format_coef(coef(m_n2o)[1], se(m_n2o)[1], pvalue(m_n2o)[1]),
          se(m_n2o)[1], format(m_n2o$nobs, big.mark = ",")),
  "\\addlinespace\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: By sector}} \\\\\n",
  "\\addlinespace\n"
)

for (s_name in c("Mining & Oil/Gas", "Manufacturing", "Utilities",
                 "Waste & Public Admin", "Other")) {
  if (s_name %in% names(sect_res)) {
    sr <- sect_res[[s_name]]
    pv <- 2 * pnorm(-abs(sr$coef / sr$se))
    tab4 <- paste0(tab4,
                   sprintf("%s & %s & (%.4f) & %s & %d \\\\\n",
                           s_name,
                           format_coef(sr$coef, sr$se, pv),
                           sr$se, format(sr$n, big.mark = ","), sr$n_fac))
  }
}

tab4 <- paste0(tab4,
               "\\hline\\hline\n",
               "\\end{tabular}\n",
               "\\begin{tablenotes}\n",
               "\\small\n",
               "\\item \\textit{Notes:} Each row reports the coefficient on Backstop $\\times$ Post from a separate ",
               "facility-year panel regression with facility and year fixed effects. ",
               "Panel A decomposes by gas type; Panel B by 2-digit NAICS sector. ",
               "The dependent variable is log emissions in the relevant category (tonnes CO$_2$e for CH$_4$ and N$_2$O; ",
               "tonnes CO$_2$ for combustion CO$_2$). ",
               "The large utilities effect reflects Ontario's coal-fired electricity phase-out (completed 2014), ",
               "not the 2019 carbon backstop. ",
               "Balanced panel, 2004--2023. Standard errors clustered by province. ",
               "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
               "\\end{tablenotes}\n",
               "\\end{table}\n")

writeLines(tab4, "../tables/tab4_mechanism.tex")

# ============================================================
# TABLE 5: Robustness
# ============================================================
cat("\n=== Table 5: Robustness ===\n")

m_short <- robust$m_short
m_no_on <- robust$m_no_on
m_no_ab <- robust$m_no_ab
m_placebo <- robust$m_placebo
m_nutil_short <- refined$m_no_util_short

specs <- list(
  list("Short panel (2017--2023)", m_short),
  list("Excluding Ontario", m_no_on),
  list("Excluding Alberta", m_no_ab),
  list("Excl. utilities, short panel", m_nutil_short),
  list("Placebo: fake treatment 2014", m_placebo)
)

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "Specification & Estimate & SE & $p$-value & $N$ & Implied \\% \\\\",
  "\\hline"
)

for (sp in specs) {
  label <- sp[[1]]
  mod <- sp[[2]]
  cf <- coef(mod)[1]
  s <- se(mod)[1]
  p <- pvalue(mod)[1]
  pct <- (exp(cf) - 1) * 100
  tab5_lines <- c(tab5_lines,
                  sprintf("%s & %s & (%.4f) & %.3f & %s & %.1f\\%% \\\\",
                          label, format_coef(cf, s, p), s, p,
                          format(mod$nobs, big.mark = ","), pct))
}

tab5_lines <- c(tab5_lines,
                "\\hline\\hline",
                "\\end{tabular}",
                "\\begin{tablenotes}",
                "\\small",
                paste0("\\item \\textit{Notes:} Each row is a separate facility-year panel regression with ",
                       "facility and year FE, clustered SEs at province level. ",
                       "The short panel (2017--2023) uses consistent GHGRP reporting thresholds (10kt since 2017). ",
                       "The placebo applies a fake treatment date of 2014 to the pre-2019 sample. ",
                       "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."),
                "\\end{tablenotes}",
                "\\end{table}")

writeLines(tab5_lines, "../tables/tab5_robust.tex")

# ============================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("\n=== Table F1: Standardized Effect Sizes ===\n")

sd_y <- sd(df_bal$log_co2e, na.rm = TRUE)

outcomes <- list(
  list("Total emissions (all sectors)", coef(main$m2)[1], se(main$m2)[1]),
  list("Total emissions (excl. utilities)", coef(refined$m_no_util)[1], se(refined$m_no_util)[1]),
  list("CO$_2$ (combustion)", coef(robust$m_co2)[1], se(robust$m_co2)[1]),
  list("CH$_4$ (process/fugitive)", coef(robust$m_ch4)[1], se(robust$m_ch4)[1]),
  list("EITE sectors", coef(refined$m_eite)[1], se(refined$m_eite)[1])
)

sde_classify <- function(sde) {
  if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
}

tabf1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (o in outcomes) {
  sde <- o[[2]] / sd_y
  se_sde <- o[[3]] / sd_y
  cls <- sde_classify(sde)
  tabf1_lines <- c(tabf1_lines,
                   sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
                           o[[1]], o[[2]], o[[3]], sd_y, sde, se_sde, cls))
}

tabf1_lines <- c(tabf1_lines,
                 "\\hline\\hline",
                 "\\end{tabular}",
                 "\\end{adjustbox}",
                 "\\begin{tablenotes}",
                 "\\small",
                 paste0("\\item \\textit{Notes:} Standardized effect sizes (SDE) computed as $\\hat{\\beta} / \\text{SD}(Y)$ ",
                        "where $Y$ is log total facility emissions (tonnes CO$_2$e). ",
                        "The research question is whether Canada's federal carbon pricing backstop (imposed April 2019 on ",
                        "Ontario, Saskatchewan, Manitoba, and New Brunswick) reduced facility-level GHG emissions. ",
                        "Data: ECCC GHGRP facility-level panel, 2004--2023, balanced sample of 1,602 facilities. ",
                        "Method: TWFE DiD with facility and year FE, SEs clustered by province. ",
                        "Classification refers to effect magnitude, not statistical significance. ",
                        "$N = 15{,}287$ facility-year observations."),
                 "\\end{tablenotes}",
                 "\\end{table}")

writeLines(tabf1_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tab1_sumstats.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_eventstudy.tex\n")
cat("  tab4_mechanism.tex\n")
cat("  tab5_robust.tex\n")
cat("  tabF1_sde.tex\n")
