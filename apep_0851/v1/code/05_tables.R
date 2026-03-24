## 05_tables.R — Generate all LaTeX tables
## apep_0851: Abolishing the Tax Haven Next Door

source("00_packages.R")

load("../data/models.RData")
load("../data/robustness_models.RData")
main_res <- read_json("../data/main_results.json")
rob_res <- read_json("../data/robustness_results.json")

dir.create("../tables", showWarnings = FALSE)

# -----------------------------------------------------------------------
# Table 1: Summary Statistics
# -----------------------------------------------------------------------
cat("=== Table 1: Summary Statistics ===\n")

summ_data <- df %>%
  mutate(Group = ifelse(treated == 1, "Portugal", "Controls")) %>%
  group_by(Group) %>%
  summarize(
    N = n(),
    Countries = n_distinct(country),
    Mean = mean(hpi, na.rm = TRUE),
    SD = sd(hpi, na.rm = TRUE),
    Min = min(hpi, na.rm = TRUE),
    Max = max(hpi, na.rm = TRUE),
    .groups = "drop"
  )

# Pre vs Post split
summ_pre_post <- df %>%
  mutate(
    Group = ifelse(treated == 1, "Portugal", "Controls"),
    Period = ifelse(post_announce == 1, "Post", "Pre")
  ) %>%
  group_by(Group, Period) %>%
  summarize(
    N = n(),
    `Mean HPI` = mean(hpi, na.rm = TRUE),
    `SD HPI` = sd(hpi, na.rm = TRUE),
    `Mean log HPI` = mean(log_hpi, na.rm = TRUE),
    `SD log HPI` = sd(log_hpi, na.rm = TRUE),
    .groups = "drop"
  )

# Write Table 1 LaTeX
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: House Price Index by Country Group and Period}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Group & Period & N & Countries & Mean HPI & SD HPI & Mean log HPI \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(summ_pre_post))) {
  r <- summ_pre_post[i, ]
  nc <- ifelse(r$Group == "Portugal", 1, length(unique(df$country[df$treated == 0])))
  tab1_tex <- paste0(tab1_tex,
    r$Group, " & ", r$Period, " & ",
    format(r$N, big.mark = ","), " & ", nc, " & ",
    sprintf("%.1f", r$`Mean HPI`), " & ",
    sprintf("%.1f", r$`SD HPI`), " & ",
    sprintf("%.3f", r$`Mean log HPI`), " \\\\\n"
  )
}

tab1_tex <- paste0(tab1_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} House Price Index from Eurostat (prc\\_hpi\\_q), base 2015 = 100, total purchases. ",
  "Portugal is the treated country; controls are ", length(unique(df$country[df$treated == 0])),
  " EU member states. Pre-period: 2010Q1--2023Q2; Post-period: 2023Q3--latest available. ",
  "The NHR termination was announced September 6, 2023, effective January 1, 2024.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# -----------------------------------------------------------------------
# Table 2: Main DiD Results
# -----------------------------------------------------------------------
cat("=== Table 2: Main Results ===\n")

# Extract coefficients from each model
get_coef_row <- function(mod, varname) {
  cf <- coef(mod)[varname]
  s <- se(mod)[varname]
  p <- pvalue(mod)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(coef = cf, se = s, pval = p, stars = stars, n = nobs(mod))
}

r1 <- get_coef_row(m1, "treated:post_announce")
r2 <- get_coef_row(m2, "treated:post_effective")
r3 <- get_coef_row(m_south, "treated:post_announce")
r4 <- get_coef_row(m_north, "treated:post_announce")

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of NHR Termination on House Prices}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Full Sample & Full Sample & Southern EU & Northern/Western EU \\\\\n",
  "\\midrule\n",
  "Portugal $\\times$ Post & ",
  sprintf("%.4f%s", r1$coef, r1$stars), " & ",
  sprintf("%.4f%s", r2$coef, r2$stars), " & ",
  sprintf("%.4f%s", r3$coef, r3$stars), " & ",
  sprintf("%.4f%s", r4$coef, r4$stars), " \\\\\n",
  " & (", sprintf("%.4f", r1$se), ") & (",
  sprintf("%.4f", r2$se), ") & (",
  sprintf("%.4f", r3$se), ") & (",
  sprintf("%.4f", r4$se), ") \\\\\n",
  "\\midrule\n",
  "Post definition & Announce & Effective & Announce & Announce \\\\\n",
  "Country FE & Yes & Yes & Yes & Yes \\\\\n",
  "Quarter FE & Yes & Yes & Yes & Yes \\\\\n",
  "Countries & ", length(unique(df$country)), " & ",
  length(unique(df$country)), " & ",
  length(unique(df$country[df$country %in% c("PT", "ES", "IT", "EL", "CY", "MT")])), " & ",
  length(unique(df$country[df$country %in% c("PT", "NL", "IE", "BE", "FI", "AT", "DE", "FR", "LU")])), " \\\\\n",
  "N & ", format(r1$n, big.mark = ","), " & ",
  format(r2$n, big.mark = ","), " & ",
  format(nobs(m_south), big.mark = ","), " & ",
  format(nobs(m_north), big.mark = ","), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Dependent variable is log House Price Index (Eurostat, 2015 = 100). ",
  "Column (1) uses the announcement date (2023Q3) as the treatment cutoff; column (2) uses the effective date (2024Q1). ",
  "Columns (3)--(4) restrict the control group to Southern and Northern/Western EU countries, respectively. ",
  "Standard errors clustered at the country level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")

# -----------------------------------------------------------------------
# Table 3: Event Study Coefficients
# -----------------------------------------------------------------------
cat("=== Table 3: Event Study ===\n")

es_cf <- as.data.frame(coeftable(es_model))
es_cf$term <- rownames(es_cf)

# Parse event time from coefficient names
es_cf <- es_cf %>%
  filter(grepl("et_binned", term)) %>%
  mutate(
    event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", term)),
    stars = case_when(
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.10 ~ "*",
      TRUE ~ ""
    )
  ) %>%
  arrange(event_time)

tab3_rows <- ""
for (i in seq_len(nrow(es_cf))) {
  r <- es_cf[i, ]
  # Convert event_time to calendar quarter
  cal_yq <- 2023.5 + r$event_time / 4
  cal_label <- paste0(floor(cal_yq), "Q", round((cal_yq %% 1) * 4) + 1)
  tab3_rows <- paste0(tab3_rows,
    "$t = ", r$event_time, "$ (", cal_label, ") & ",
    sprintf("%.4f%s", r$Estimate, r$stars), " & (",
    sprintf("%.4f", r$`Std. Error`), ") \\\\\n"
  )
}

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Dynamic Effects of NHR Termination on House Prices}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Event Quarter & Coefficient & Std. Error \\\\\n",
  "\\midrule\n",
  tab3_rows,
  "\\midrule\n",
  "Reference & \\multicolumn{2}{c}{$t = -1$ (2023Q2)} \\\\\n",
  "Country FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "Quarter FE & \\multicolumn{2}{c}{Yes} \\\\\n",
  "N & \\multicolumn{2}{c}{", format(nobs(es_model), big.mark = ","), "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Event study coefficients from a regression of log HPI on interactions ",
  "of the Portugal indicator with event-time dummies, plus country and quarter fixed effects. ",
  "Event time 0 corresponds to the NHR termination announcement (2023Q3). ",
  "Reference period is $t = -1$ (2023Q2). Endpoints are binned at $t \\leq -12$ and $t \\geq 8$. ",
  "Standard errors clustered at the country level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:event}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_event_study.tex")

# -----------------------------------------------------------------------
# Table 4: Robustness
# -----------------------------------------------------------------------
cat("=== Table 4: Robustness ===\n")

rob_rows <- tibble(
  Specification = c(
    "Baseline (Full sample, post-announce)",
    "Post-effective date only (2024Q1+)",
    "Iberian + neighbors only (PT, ES, FR, IT)",
    "Country-specific linear trends",
    "Short window (through 2024Q2)",
    "Placebo: fake shock at 2021Q3",
    "Placebo: fake shock at 2020Q3"
  ),
  Coefficient = c(
    main_res$main_coef, main_res$effective_coef,
    rob_res$iberian_coef, rob_res$trends_coef, rob_res$short_coef,
    rob_res$placebo_2021_coef, rob_res$placebo_2020_coef
  ),
  SE = c(
    main_res$main_se, main_res$effective_se,
    rob_res$iberian_se, rob_res$trends_se, rob_res$short_se,
    rob_res$placebo_2021_se, rob_res$placebo_2020_se
  )
) %>%
  mutate(
    pval = 2 * pnorm(-abs(Coefficient / SE)),
    stars = case_when(pval < 0.01 ~ "***", pval < 0.05 ~ "**", pval < 0.10 ~ "*", TRUE ~ "")
  )

tab4_body <- ""
for (i in seq_len(nrow(rob_rows))) {
  r <- rob_rows[i, ]
  tab4_body <- paste0(tab4_body,
    r$Specification, " & ",
    sprintf("%.4f%s", r$Coefficient, r$stars), " & (",
    sprintf("%.4f", r$SE), ") \\\\\n"
  )
}

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & Coefficient & Std. Error \\\\\n",
  "\\midrule\n",
  tab4_body,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the Portugal $\\times$ Post coefficient from a separate regression. ",
  "Dependent variable is log HPI. All regressions include country and quarter fixed effects. ",
  "Standard errors clustered at the country level in parentheses. ",
  "Placebo tests use only pre-announcement data (through 2023Q2) with a fake treatment date. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robust}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# -----------------------------------------------------------------------
# Table F1: Standardized Effect Sizes (SDE)
# -----------------------------------------------------------------------
cat("=== Table F1: Standardized Effect Sizes ===\n")

sd_y <- sd(df$log_hpi, na.rm = TRUE)

# Pooled
beta_main <- coef(m1)["treated:post_announce"]
se_main <- se(m1)["treated:post_announce"]
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

# Heterogeneity: Southern EU subsample
beta_south <- coef(m_south)["treated:post_announce"]
se_south_val <- se(m_south)["treated:post_announce"]
sd_y_south <- sd(df$log_hpi[df$country %in% c("PT", "ES", "IT", "EL", "CY", "MT")], na.rm = TRUE)
sde_south <- beta_south / sd_y_south
se_sde_south <- se_south_val / sd_y_south

# Heterogeneity: Northern/Western EU subsample
beta_north <- coef(m_north)["treated:post_announce"]
se_north_val <- se(m_north)["treated:post_announce"]
sd_y_north <- sd(df$log_hpi[df$country %in% c("PT", "NL", "IE", "BE", "FI", "AT", "DE", "FR", "LU")], na.rm = TRUE)
sde_north <- beta_north / sd_y_north
se_sde_north <- se_north_val / sd_y_north

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Portugal (treated) versus 15 EU member state controls. ",
  "\\textbf{Research question:} Whether the abrupt termination of a preferential tax regime for foreign residents ",
  "reduced residential house prices in the treated country relative to untreated EU peers. ",
  "\\textbf{Policy mechanism:} The Non-Habitual Resident regime granted new foreign tax residents a flat 20\\% income ",
  "tax rate and exemption on most foreign-sourced income for 10 years, attracting over 74,000 beneficiaries ",
  "who concentrated in premium housing markets; its abolition removed the tax incentive for new arrivals ",
  "and signaled regime instability to existing beneficiaries. ",
  "\\textbf{Outcome definition:} Log Eurostat House Price Index (prc\\_hpi\\_q), base 2015 = 100, ",
  "measuring quarterly residential property transaction prices across all purchase types. ",
  "\\textbf{Treatment:} Binary; Portugal after the NHR termination announcement (2023Q3) versus all other periods and countries. ",
  "\\textbf{Data:} Eurostat quarterly HPI, 2010Q1--2025Q3, 16 EU countries, ",
  format(nobs(m1), big.mark = ","), " country-quarter observations. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with country and quarter fixed effects; ",
  "standard errors clustered at the country level. ",
  "\\textbf{Sample:} EU member states with continuous quarterly HPI coverage from 2010; ",
  "excludes non-EU countries and states with missing data gaps. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional standard deviation of log HPI ",
  "across the full sample. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  "Log HPI & Full sample & ",
  sprintf("%.4f", beta_main), " & ", sprintf("%.4f", se_main), " & ",
  sprintf("%.3f", sd_y), " & ", sprintf("%.3f", sde_main), " & ",
  sprintf("%.3f", se_sde_main), " & ", classify(sde_main), " \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  "Log HPI & Southern EU & ",
  sprintf("%.4f", beta_south), " & ", sprintf("%.4f", se_south_val), " & ",
  sprintf("%.3f", sd_y_south), " & ", sprintf("%.3f", sde_south), " & ",
  sprintf("%.3f", se_sde_south), " & ", classify(sde_south), " \\\\\n",
  "Log HPI & Northern/W. EU & ",
  sprintf("%.4f", beta_north), " & ", sprintf("%.4f", se_north_val), " & ",
  sprintf("%.3f", sd_y_north), " & ", sprintf("%.3f", sde_north), " & ",
  sprintf("%.3f", se_sde_north), " & ", classify(sde_north), " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_event_study.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
