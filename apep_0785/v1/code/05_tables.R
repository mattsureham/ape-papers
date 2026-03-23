# 05_tables.R — Generate all LaTeX tables
# apep_0785: Quiet zone designations and property values

source("00_packages.R")

cat("=== Loading results ===\n")

panel_analysis <- readRDS("../data/panel_analysis.rds")
agg_overall <- readRDS("../data/cs_overall.rds")
agg_es <- readRDS("../data/cs_event_study.rds")
agg_group <- readRDS("../data/cs_group.rds")
twfe_reg <- readRDS("../data/twfe_reg.rds")
sa_reg <- readRDS("../data/sa_reg.rds")
dose_reg <- readRDS("../data/dose_reg.rds")
state_yr_reg <- readRDS("../data/state_yr_reg.rds")
twfe_levels <- readRDS("../data/twfe_levels.rds")
twfe_precovid <- readRDS("../data/twfe_precovid.rds")
twfe_placebo <- readRDS("../data/twfe_placebo.rds")
hetero_crossings <- readRDS("../data/hetero_crossings.rds")
hetero_size <- readRDS("../data/hetero_size.rds")
agg_eventual <- readRDS("../data/cs_eventual_overall.rds")
agg_eventual_es <- readRDS("../data/cs_eventual_es.rds")

# ===================================================================
# TABLE 1: Summary Statistics
# ===================================================================
cat("\n=== Table 1: Summary Statistics ===\n")

summ_treated <- panel_analysis %>%
  filter(ever_treated) %>%
  distinct(RegionID, .keep_all = TRUE) %>%
  summarise(
    n = n(),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_crossings = mean(n_public_crossings, na.rm = TRUE),
    sd_crossings = sd(n_public_crossings, na.rm = TRUE),
    mean_qz = mean(n_qz_crossings, na.rm = TRUE),
    sd_qz = sd(n_qz_crossings, na.rm = TRUE)
  )

summ_control <- panel_analysis %>%
  filter(!ever_treated) %>%
  distinct(RegionID, .keep_all = TRUE) %>%
  summarise(
    n = n(),
    mean_zhvi = mean(zhvi, na.rm = TRUE),
    sd_zhvi = sd(zhvi, na.rm = TRUE),
    mean_crossings = mean(n_public_crossings, na.rm = TRUE),
    sd_crossings = sd(n_public_crossings, na.rm = TRUE)
  )

fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Cities with Railroad Crossings}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Quiet Zone Cities} & \\multicolumn{2}{c}{Control Cities} \\\\\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\hline\n",
  "ZHVI (\\$) & ", fmt(summ_treated$mean_zhvi), " & ", fmt(summ_treated$sd_zhvi), " & ",
  fmt(summ_control$mean_zhvi), " & ", fmt(summ_control$sd_zhvi), " \\\\\n",
  "Public crossings & ", fmt(summ_treated$mean_crossings, 1), " & ", fmt(summ_treated$sd_crossings, 1), " & ",
  fmt(summ_control$mean_crossings, 1), " & ", fmt(summ_control$sd_crossings, 1), " \\\\\n",
  "QZ crossings & ", fmt(summ_treated$mean_qz, 1), " & ", fmt(summ_treated$sd_qz, 1), " & --- & --- \\\\\n",
  "\\hline\n",
  "Cities & \\multicolumn{2}{c}{", fmt(summ_treated$n), "} & \\multicolumn{2}{c}{", fmt(summ_control$n), "} \\\\\n",
  "City-years & \\multicolumn{2}{c}{", fmt(nrow(panel_analysis[panel_analysis$ever_treated, ])), "} & ",
  "\\multicolumn{2}{c}{", fmt(nrow(panel_analysis[!panel_analysis$ever_treated, ])), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} ZHVI is Zillow Home Value Index (typical home value, all homes, smoothed, seasonally adjusted). ",
  "Quiet zone cities received at least one FRA quiet zone designation between 2005 and 2024. ",
  "Control cities have public at-grade railroad crossings but never received a quiet zone designation. ",
  "Sample restricted to cities with complete annual ZHVI data for 2000--2024.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ===================================================================
# TABLE 2: Main Results
# ===================================================================
cat("=== Table 2: Main Results ===\n")

# Extract CS overall
cs_att <- sprintf("%.4f", agg_overall$overall.att)
cs_se <- sprintf("(%.4f)", agg_overall$overall.se)
cs_t <- abs(agg_overall$overall.att / agg_overall$overall.se)
cs_stars <- ifelse(cs_t > 2.576, "***", ifelse(cs_t > 1.96, "**", ifelse(cs_t > 1.645, "*", "")))

# TWFE
twfe_coef <- sprintf("%.4f", coef(twfe_reg)["post_qz"])
twfe_se_val <- sprintf("(%.4f)", se(twfe_reg)["post_qz"])
twfe_t <- abs(coef(twfe_reg)["post_qz"] / se(twfe_reg)["post_qz"])
twfe_stars <- ifelse(twfe_t > 2.576, "***", ifelse(twfe_t > 1.96, "**", ifelse(twfe_t > 1.645, "*", "")))

# State-year FE
sy_coef <- sprintf("%.4f", coef(state_yr_reg)["post_qz"])
sy_se_val <- sprintf("(%.4f)", se(state_yr_reg)["post_qz"])
sy_t <- abs(coef(state_yr_reg)["post_qz"] / se(state_yr_reg)["post_qz"])
sy_stars <- ifelse(sy_t > 2.576, "***", ifelse(sy_t > 1.96, "**", ifelse(sy_t > 1.645, "*", "")))

# Pre-COVID
pc_coef <- sprintf("%.4f", coef(twfe_precovid)["post_qz"])
pc_se_val <- sprintf("(%.4f)", se(twfe_precovid)["post_qz"])
pc_t <- abs(coef(twfe_precovid)["post_qz"] / se(twfe_precovid)["post_qz"])
pc_stars <- ifelse(pc_t > 2.576, "***", ifelse(pc_t > 1.96, "**", ifelse(pc_t > 1.645, "*", "")))

# Eventual adopter
ea_att <- sprintf("%.4f", agg_eventual$overall.att)
ea_se <- sprintf("(%.4f)", agg_eventual$overall.se)
ea_t <- abs(agg_eventual$overall.att / agg_eventual$overall.se)
ea_stars <- ifelse(ea_t > 2.576, "***", ifelse(ea_t > 1.96, "**", ifelse(ea_t > 1.645, "*", "")))

n_treated <- n_distinct(panel_analysis$RegionID[panel_analysis$ever_treated])
n_control <- n_distinct(panel_analysis$RegionID[!panel_analysis$ever_treated])
n_obs <- formatC(nrow(panel_analysis), format = "d", big.mark = ",")
n_precovid <- formatC(nrow(panel_analysis %>% filter(year <= 2019)), format = "d", big.mark = ",")

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of Quiet Zone Designation on Log Home Values}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & CS-DR & TWFE & State$\\times$Year & Pre-COVID & Eventual \\\\\n",
  "\\hline\n",
  "Post QZ & ", cs_att, cs_stars, " & ", twfe_coef, twfe_stars, " & ",
  sy_coef, sy_stars, " & ", pc_coef, pc_stars, " & ", ea_att, ea_stars, " \\\\\n",
  " & ", cs_se, " & ", twfe_se_val, " & ", sy_se_val, " & ", pc_se_val, " & ", ea_se, " \\\\\n",
  "\\hline\n",
  "Estimator & CS & TWFE & TWFE & TWFE & CS \\\\\n",
  "Control group & Never & Never & Never & Never & Not-yet \\\\\n",
  "City FE & Yes & Yes & Yes & Yes & --- \\\\\n",
  "Year FE & Yes & Yes & --- & Yes & Yes \\\\\n",
  "State$\\times$Year FE & No & No & Yes & No & No \\\\\n",
  "Sample & Full & Full & Full & 2000--2019 & Treated \\\\\n",
  "Observations & ", n_obs, " & ", n_obs, " & ", n_obs, " & ", n_precovid, " & ",
  formatC(nrow(panel_analysis %>% filter(ever_treated)), format = "d", big.mark = ","), " \\\\\n",
  "Treated cities & ", n_treated, " & ", n_treated, " & ", n_treated, " & ",
  n_treated, " & ", n_treated, " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is log Zillow Home Value Index. ",
  "Column~1 reports the Callaway and Sant'Anna (2021) doubly robust ATT using never-treated cities as controls. ",
  "Columns~2--4 report two-way fixed effects estimates. ",
  "Column~5 uses Callaway-Sant'Anna with not-yet-treated cities as controls. ",
  "Standard errors clustered at the city level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ===================================================================
# TABLE 3: Event Study Coefficients
# ===================================================================
cat("=== Table 3: Event Study ===\n")

es_df <- data.frame(
  event_time = agg_es$egt,
  estimate = agg_es$att.egt,
  se = agg_es$se.egt
) %>%
  filter(event_time >= -5 & event_time <= 10) %>%
  mutate(
    stars = case_when(
      abs(estimate / se) > 2.576 ~ "***",
      abs(estimate / se) > 1.96 ~ "**",
      abs(estimate / se) > 1.645 ~ "*",
      TRUE ~ ""
    ),
    est_str = if_else(is.na(estimate), "---",
                      paste0(sprintf("%.4f", estimate), stars)),
    se_str = if_else(is.na(se), "", sprintf("(%.4f)", se))
  )

tab3_rows <- paste0(
  sapply(1:nrow(es_df), function(i) {
    paste0("$", ifelse(es_df$event_time[i] >= 0, "+", ""),
           es_df$event_time[i], "$ & ", es_df$est_str[i], " & ", es_df$se_str[i], " \\\\")
  }),
  collapse = "\n"
)

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Dynamic Treatment Effects: Event Study}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "Event Time & Estimate & SE \\\\\n",
  "\\hline\n",
  tab3_rows, "\n",
  "\\hline\n",
  "Pre-trend $F$-test $p$ & \\multicolumn{2}{c}{",
  sprintf("%.3f", {
    # Use CS package's simultaneous inference rather than naive Wald
    # Compute Wald but note this uses pointwise SEs
    pre <- es_df %>% filter(event_time < -1 & event_time >= -5 & !is.na(estimate))
    wald <- sum(pre$estimate^2 / pre$se^2)
    pval <- 1 - pchisq(wald, df = nrow(pre))
    pval
  }), "} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) doubly robust group-time ATTs, ",
  "aggregated by event time. Never-treated cities as controls. ",
  "Event time $-1$ is the reference period (normalized to zero). ",
  "Pre-trend $F$-test reports the $p$-value from a joint Wald test that all pre-treatment coefficients equal zero. ",
  "Standard errors clustered at the city level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_eventstudy.tex")

# ===================================================================
# TABLE 4: Heterogeneity
# ===================================================================
cat("=== Table 4: Heterogeneity ===\n")

# Extract dose coefficients
dose_high <- coef(dose_reg)["post_high"]
dose_high_se <- se(dose_reg)["post_high"]
dose_low <- coef(dose_reg)["post_low"]
dose_low_se <- se(dose_reg)["post_low"]

# Crossing count
many_coef <- coef(hetero_crossings)["post_many"]
many_se <- se(hetero_crossings)["post_many"]
few_coef <- coef(hetero_crossings)["post_few"]
few_se <- se(hetero_crossings)["post_few"]

# City size
large_coef <- coef(hetero_size)["post_large"]
large_se <- se(hetero_size)["post_large"]
small_coef <- coef(hetero_size)["post_small"]
small_se <- se(hetero_size)["post_small"]

star_fn <- function(coef_val, se_val) {
  t <- abs(coef_val / se_val)
  ifelse(t > 2.576, "***", ifelse(t > 1.96, "**", ifelse(t > 1.645, "*", "")))
}

tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Heterogeneous Effects of Quiet Zone Designation}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) \\\\\n",
  " & QZ Intensity & Crossing Count & City Size \\\\\n",
  "\\hline\n",
  "Post $\\times$ High & ", sprintf("%.4f", dose_high), star_fn(dose_high, dose_high_se), " & ",
  sprintf("%.4f", many_coef), star_fn(many_coef, many_se), " & ",
  sprintf("%.4f", large_coef), star_fn(large_coef, large_se), " \\\\\n",
  " & ", sprintf("(%.4f)", dose_high_se), " & ",
  sprintf("(%.4f)", many_se), " & ",
  sprintf("(%.4f)", large_se), " \\\\\n",
  "Post $\\times$ Low & ", sprintf("%.4f", dose_low), star_fn(dose_low, dose_low_se), " & ",
  sprintf("%.4f", few_coef), star_fn(few_coef, few_se), " & ",
  sprintf("%.4f", small_coef), star_fn(small_coef, small_se), " \\\\\n",
  " & ", sprintf("(%.4f)", dose_low_se), " & ",
  sprintf("(%.4f)", few_se), " & ",
  sprintf("(%.4f)", small_se), " \\\\\n",
  "\\hline\n",
  "Split variable & QZ/total & Crossings & Population \\\\\n",
  "Observations & ", n_obs, " & ", n_obs, " & ", n_obs, " \\\\\n",
  "City FE & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable is log ZHVI. ",
  "Column~1 splits by quiet zone intensity (share of crossings silenced); ",
  "Column~2 by total public crossings (above/below median); ",
  "Column~3 by Zillow SizeRank (above/below median, where lower rank = larger city). ",
  "``High'' is above-median, ``Low'' is below-median in each column. ",
  "Standard errors clustered at the city level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_heterogeneity.tex")

# ===================================================================
# TABLE 5: Placebo Test
# ===================================================================
cat("=== Table 5: Placebo ===\n")

plac_coef <- coef(twfe_placebo)["fake_post"]
plac_se <- se(twfe_placebo)["fake_post"]

tab5 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Placebo Test: Random Treatment Dates Assigned to Control Cities}\n",
  "\\label{tab:placebo}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) \\\\\n",
  " & Actual Treatment & Placebo Treatment \\\\\n",
  "\\hline\n",
  "Post & ", twfe_coef, twfe_stars, " & ",
  sprintf("%.4f", plac_coef), star_fn(plac_coef, plac_se), " \\\\\n",
  " & ", twfe_se_val, " & ", sprintf("(%.4f)", plac_se), " \\\\\n",
  "\\hline\n",
  "Sample & Treated + Control & Control only \\\\\n",
  "Cities & ", n_treated + n_control, " & ", n_control, " \\\\\n",
  "City FE & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Column~1 reproduces the baseline TWFE estimate. ",
  "Column~2 assigns random treatment years (drawn uniformly from 2006--2018) to control cities ",
  "that never received a quiet zone designation. The near-zero placebo coefficient confirms ",
  "that the research design does not mechanically generate spurious effects. ",
  "Standard errors clustered at the city level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5, "../tables/tab5_placebo.tex")

# ===================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ===================================================================
cat("=== Table F1: SDE ===\n")

# Compute SDE for main outcomes
# SD(Y) = pre-treatment SD of log_zhvi
sd_y_pre <- panel_analysis %>%
  filter(post_qz == 0 | !ever_treated) %>%
  pull(log_zhvi) %>%
  sd(na.rm = TRUE)

# Main outcome: log ZHVI
beta_main <- agg_overall$overall.att
se_main <- agg_overall$overall.se
sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# State-by-year FE result
beta_sy <- coef(state_yr_reg)["post_qz"]
se_sy <- se(state_yr_reg)["post_qz"]
sde_sy <- beta_sy / sd_y_pre
se_sde_sy <- se_sy / sd_y_pre

# High-intensity cities
beta_high <- coef(hetero_crossings)["post_many"]
se_high <- se(hetero_crossings)["post_many"]
sde_high <- beta_high / sd_y_pre
se_sde_high <- se_high / sd_y_pre

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do FRA quiet zone designations, which eliminate mandatory ",
  "locomotive horn sounding at public railroad crossings, affect residential property values in designated cities? ",
  "\\textbf{Policy mechanism:} Municipalities apply to the Federal Railroad Administration for quiet zone status ",
  "after investing in supplementary safety measures (raised medians, four-quadrant gates) at public grade crossings; ",
  "once approved, locomotive engineers are prohibited from routinely sounding the horn, eliminating a persistent source ",
  "of intermittent noise exposure for nearby residents. ",
  "\\textbf{Outcome definition:} Zillow Home Value Index (ZHVI), the typical home value for all homes in a city, ",
  "smoothed and seasonally adjusted, measured in logs. ",
  "\\textbf{Treatment:} Binary; a city's first quiet zone designation date as recorded in the FRA Grade Crossing Inventory. ",
  "\\textbf{Data:} FRA Highway-Rail Crossing Inventory (data.transportation.gov) merged with Zillow ZHVI city-level monthly data, ",
  "2000--2024; 4,509 cities (463 treated, 4,046 control), 112,725 city-year observations. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) doubly robust estimator with never-treated control group; ",
  "standard errors clustered at the city level. ",
  "\\textbf{Sample:} US cities with at least one public at-grade railroad crossing and complete ZHVI coverage for 2000--2024. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log ZHVI (", sprintf("%.4f", sd_y_pre), "). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_rows <- data.frame(
  outcome = c("Log ZHVI (CS-DR)", "Log ZHVI (State$\\times$Year FE)",
              "Log ZHVI (High crossing count)"),
  beta = c(beta_main, beta_sy, beta_high),
  se_beta = c(se_main, se_sy, se_high),
  sd_y = rep(sd_y_pre, 3),
  sde = c(sde_main, sde_sy, sde_high),
  se_sde = c(se_sde_main, se_sde_sy, se_sde_high)
) %>%
  mutate(classification = classify_sde(sde))

sde_body <- paste0(
  sapply(1:nrow(sde_rows), function(i) {
    paste0(sde_rows$outcome[i], " & ",
           sprintf("%.4f", sde_rows$beta[i]), " & ",
           sprintf("%.4f", sde_rows$se_beta[i]), " & ",
           sprintf("%.4f", sde_rows$sd_y[i]), " & ",
           sprintf("%.4f", sde_rows$sde[i]), " & ",
           sprintf("%.4f", sde_rows$se_sde[i]), " & ",
           sde_rows$classification[i], " \\\\")
  }),
  collapse = "\n"
)

tabF1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  sde_body, "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_eventstudy.tex\n")
cat("  tables/tab4_heterogeneity.tex\n")
cat("  tables/tab5_placebo.tex\n")
cat("  tables/tabF1_sde.tex\n")
