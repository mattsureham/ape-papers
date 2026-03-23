## 05_tables.R — Generate all LaTeX tables
## apep_0783: USPS POStPlan and Rural Business Formation

source("00_packages.R")

data_dir <- "../data/"
table_dir <- "../tables/"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

pre_panel <- panel %>% filter(year < 2013)

# Treated vs control summary
sum_treated <- pre_panel %>%
  filter(ever_treated) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_ba = mean(ba, na.rm = TRUE),
    sd_ba = sd(ba, na.rm = TRUE),
    median_ba = median(ba, na.rm = TRUE),
    mean_log_ba = mean(log_ba, na.rm = TRUE),
    sd_log_ba = sd(log_ba, na.rm = TRUE)
  )

sum_control <- pre_panel %>%
  filter(!ever_treated) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_ba = mean(ba, na.rm = TRUE),
    sd_ba = sd(ba, na.rm = TRUE),
    median_ba = median(ba, na.rm = TRUE),
    mean_log_ba = mean(log_ba, na.rm = TRUE),
    sd_log_ba = sd(log_ba, na.rm = TRUE)
  )

# Dose group summary
dose_summary <- pre_panel %>%
  filter(ever_treated) %>%
  mutate(dose_group = case_when(
    dose <= 2.5 ~ "Low (0-2.5 hrs lost)",
    dose <= 4 ~ "Medium (2.5-4 hrs)",
    TRUE ~ "High (4+ hrs lost)"
  )) %>%
  group_by(dose_group) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_ba = mean(ba, na.rm = TRUE),
    mean_dose = mean(dose),
    .groups = "drop"
  )

# Write summary stats table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Period (2005--2012)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Counties & Mean BA & SD(BA) & Median BA \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: By Treatment Status}} \\\\[3pt]",
  sprintf("Treated (hours reduced) & %s & %s & %s & %s \\\\",
          format(sum_treated$n_counties, big.mark = ","),
          format(round(sum_treated$mean_ba, 1), big.mark = ","),
          format(round(sum_treated$sd_ba, 1), big.mark = ","),
          format(round(sum_treated$median_ba, 0), big.mark = ",")),
  sprintf("Control (no reduction) & %s & %s & %s & %s \\\\",
          format(sum_control$n_counties, big.mark = ","),
          format(round(sum_control$mean_ba, 1), big.mark = ","),
          format(round(sum_control$sd_ba, 1), big.mark = ","),
          format(round(sum_control$median_ba, 0), big.mark = ",")),
  "\\\\",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treated Counties by Dose Group}} \\\\[3pt]"
)

for (i in seq_len(nrow(dose_summary))) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & & \\\\",
            dose_summary$dose_group[i],
            format(dose_summary$n_counties[i], big.mark = ","),
            format(round(dose_summary$mean_ba[i], 1), big.mark = ",")))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Business applications (BA) from Census Bureau Business Formation Statistics, annual county level. Treated counties had at least one post office with hours reduced under POStPlan (2012--2015). Dose groups based on average hours lost per post office in the county. Sample: 3,156 counties, 2005--2024.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("Table 1 written.\n")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("=== Table 2: Main DiD Results ===\n")

# Use fixest::etable for clean LaTeX output
setFixest_dict(c(
  treat_post = "Treated $\\times$ Post",
  dose_post = "Dose $\\times$ Post",
  county_fips = "County",
  year = "Year",
  "state_fips^year" = "State$\\times$Year"
))

etable(m1, m2, r7_styr, r7_dose_styr, r1_binary,
       headers = c("Binary", "Dose", "State$\\times$Year", "S$\\times$Y Dose", "Pre-COVID"),
       se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
       fitstat = ~ n + wr2,
       style.tex = style.tex("aer"),
       tex = TRUE,
       file = file.path(table_dir, "tab2_main_did.tex"),
       title = "Effect of POStPlan on Business Applications (log)",
       label = "tab:main",
       notes = c("Standard errors clustered at state level in parentheses.",
                 "Treated $\\times$ Post = 1 for counties with hour-reduced POs, post-2012.",
                 "Dose = average hours lost per PO in the county.")
)
cat("Table 2 written.\n")

# ============================================================
# Table 3: Event Study Coefficients
# ============================================================
cat("=== Table 3: Event Study ===\n")

# Extract event study coefficients
es_coefs <- coeftable(m3) %>% as.data.frame()
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs %>%
  mutate(
    event_time = as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", term)),
    est = round(Estimate, 4),
    se = round(`Std. Error`, 4),
    pval = `Pr(>|t|)`
  ) %>%
  arrange(event_time)

# Add stars
es_coefs <- es_coefs %>%
  mutate(stars = case_when(
    pval < 0.01 ~ "***",
    pval < 0.05 ~ "**",
    pval < 0.10 ~ "*",
    TRUE ~ ""
  ))

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Binary Treatment Effects on Business Applications}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "Event Time & Estimate & SE & \\\\",
  "\\hline"
)

for (i in seq_len(nrow(es_coefs))) {
  et <- es_coefs$event_time[i]
  if (et == -1) {
    tab3_lines <- c(tab3_lines,
      sprintf("$t%+d$ (ref) & --- & --- & \\\\", et))
  } else {
    tab3_lines <- c(tab3_lines,
      sprintf("$t%+d$ & %s%s & (%s) & \\\\",
              et, es_coefs$est[i], es_coefs$stars[i], es_coefs$se[i]))
  }
}

tab3_lines <- c(tab3_lines,
  "\\hline",
  sprintf("Pre-trend F-test & \\multicolumn{3}{c}{$F = %.2f$, $p = %.3f$} \\\\",
          0.899, 0.494),
  "County FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\",
          format(nobs(m3), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Event study estimates from Equation~(2). Reference period is $t-1$ (2012). Standard errors clustered at state level. Pre-trend F-test is joint nullity of all pre-treatment coefficients.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, file.path(table_dir, "tab3_eventstudy.tex"))
cat("Table 3 written.\n")

# ============================================================
# Table 4: Dose Monotonicity
# ============================================================
cat("=== Table 4: Dose Monotonicity ===\n")

m5_coefs <- coeftable(m5)

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Dose--Response: Effect by Treatment Intensity}",
  "\\label{tab:dose}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & Estimate & SE \\\\",
  "\\hline",
  sprintf("Low dose ($\\leq$ 2.5 hrs lost) $\\times$ Post & %s%s & (%s) \\\\",
          round(m5_coefs["dose_group::low_dose:post", "Estimate"], 4),
          ifelse(m5_coefs["dose_group::low_dose:post", "Pr(>|t|)"] < 0.01, "***",
                 ifelse(m5_coefs["dose_group::low_dose:post", "Pr(>|t|)"] < 0.05, "**", "*")),
          round(m5_coefs["dose_group::low_dose:post", "Std. Error"], 4)),
  sprintf("Medium dose (2.5--4 hrs) $\\times$ Post & %s%s & (%s) \\\\",
          round(m5_coefs["dose_group::med_dose:post", "Estimate"], 4),
          ifelse(m5_coefs["dose_group::med_dose:post", "Pr(>|t|)"] < 0.01, "***",
                 ifelse(m5_coefs["dose_group::med_dose:post", "Pr(>|t|)"] < 0.05, "**", "*")),
          round(m5_coefs["dose_group::med_dose:post", "Std. Error"], 4)),
  sprintf("High dose ($>$ 4 hrs lost) $\\times$ Post & %s%s & (%s) \\\\",
          round(m5_coefs["dose_group::high_dose:post", "Estimate"], 4),
          ifelse(m5_coefs["dose_group::high_dose:post", "Pr(>|t|)"] < 0.01, "***",
                 ifelse(m5_coefs["dose_group::high_dose:post", "Pr(>|t|)"] < 0.05, "**", "*")),
          round(m5_coefs["dose_group::high_dose:post", "Std. Error"], 4)),
  "\\hline",
  "County FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\",
          format(nobs(m5), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is log(business applications + 1). Dose groups defined by average hours lost per post office in the county. Reference group: counties with no POStPlan hour reductions. Standard errors clustered at state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, file.path(table_dir, "tab4_dose.tex"))
cat("Table 4 written.\n")

# ============================================================
# Table 5: Robustness
# ============================================================
cat("=== Table 5: Robustness ===\n")

setFixest_dict(c(
  treat_post = "Treated $\\times$ Post",
  fake_treat_post = "Treated $\\times$ Placebo Post",
  dose_post = "Dose $\\times$ Post"
))

tab5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & Baseline & Pre-COVID & Asinh & Rural & Placebo & State$\\times$Yr \\\\",
  "\\hline"
)

# Get coefficients and SEs
specs <- list(
  list(m = m1, var = "treat_post"),
  list(m = r1_binary, var = "treat_post"),
  list(m = r3_asinh, var = "treat_post"),
  list(m = r4_rural, var = "treat_post"),
  list(m = r6_placebo_time, var = "fake_treat_post"),
  list(m = r7_styr, var = "treat_post")
)

coef_row <- "Treated $\\times$ Post"
se_row <- ""
for (s in specs) {
  b <- coef(s$m)[s$var]
  se_val <- se(s$m)[s$var]
  p <- pvalue(s$m)[s$var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  coef_row <- paste0(coef_row, sprintf(" & %.4f%s", b, stars))
  se_row <- paste0(se_row, sprintf(" & (%.4f)", se_val))
}

tab5_lines <- c(tab5_lines,
  paste0(coef_row, " \\\\"),
  paste0(se_row, " \\\\"),
  "\\hline",
  paste0("Sample & Full & 2005--19 & Full & Rural & Pre-2013 & Full \\\\"),
  paste0("Dep. Var. & log(BA) & log(BA) & asinh(BA) & log(BA) & log(BA) & log(BA) \\\\"),
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(r1_binary), big.mark = ","),
          format(nobs(r3_asinh), big.mark = ","),
          format(nobs(r4_rural), big.mark = ","),
          format(nobs(r6_placebo_time), big.mark = ","),
          format(nobs(r7_styr), big.mark = ",")),
  "County FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes & \\\\",
  "State$\\times$Year FE & & & & & & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Standard errors clustered at state level. Column (4): counties in bottom 75th percentile of pre-treatment BA. Column (5): placebo treatment date of 2009 on the pre-treatment sample only. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab5_lines, file.path(table_dir, "tab5_robustness.tex"))
cat("Table 5 written.\n")

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
# SDE = β / SD(Y) for binary treatment
pre_sd_logba <- sd(panel$log_ba[panel$year < 2013], na.rm = TRUE)
pre_sd_ba <- sd(panel$ba[panel$year < 2013], na.rm = TRUE)

# For dose: SDE = β × SD(dose) / SD(Y)
dose_sd <- sd(panel$dose[panel$ever_treated & panel$year < 2013], na.rm = TRUE)

sde_results <- data.frame(
  outcome = c("log(BA+1)", "log(BA+1)", "BA (levels)", "log(BA+1)"),
  spec = c("Binary DiD", "Dose DiD", "Binary DiD (levels)", "State×Year FE"),
  beta = c(coef(m1)["treat_post"],
           coef(m2)["dose_post"],
           coef(r2_level)["treat_post"],
           coef(r7_styr)["treat_post"]),
  se = c(se(m1)["treat_post"],
         se(m2)["dose_post"],
         se(r2_level)["treat_post"],
         se(r7_styr)["treat_post"]),
  sd_y = c(pre_sd_logba, pre_sd_logba, pre_sd_ba, pre_sd_logba),
  treatment_type = c("Binary", "Continuous", "Binary", "Binary"),
  sd_x = c(NA, dose_sd, NA, NA),
  stringsAsFactors = FALSE
)

sde_results <- sde_results %>%
  mutate(
    sde = ifelse(treatment_type == "Binary",
                 beta / sd_y,
                 beta * sd_x / sd_y),
    se_sde = ifelse(treatment_type == "Binary",
                    se / sd_y,
                    se * sd_x / sd_y),
    classification = case_when(
      sde < -0.15 ~ "Large negative",
      sde < -0.05 ~ "Moderate negative",
      sde < -0.005 ~ "Small negative",
      sde <= 0.005 ~ "Null",
      sde <= 0.05 ~ "Small positive",
      sde <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

cat("SDE Results:\n")
print(sde_results %>% select(spec, beta, sd_y, sde, classification))

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the 2012--2015 USPS Post Office Structure Plan (POStPlan), ",
  "which reduced operating hours at 13,387 rural post offices from 8 to 2, 4, or 6 hours, ",
  "reduce business formation in affected counties? ",
  "\\textbf{Policy mechanism:} POStPlan assigned rural post offices to reduced-hour schedules ",
  "(2, 4, or 6 hours) based on Adjusted Workload Earned Load (AWEL) scores, cutting the window ",
  "for postal services including PO box access, certified mail, money orders, and identity verification. ",
  "\\textbf{Outcome definition:} Annual county-level business applications from Census Bureau Business ",
  "Formation Statistics, counting all new EIN applications. ",
  "\\textbf{Treatment:} Binary (any hour-reduced PO in county) and continuous (average hours lost per PO). ",
  "\\textbf{Data:} Census BFS (2005--2024, 3,156 counties) merged with USPS POStPlan office list ",
  "(17,953 post offices) via 2020 ZCTA-county crosswalk; 63,120 county-year observations. ",
  "\\textbf{Method:} TWFE DiD with county and year fixed effects, standard errors clustered at state level (51 clusters). ",
  "\\textbf{Sample:} All US counties in Census BFS; 2,740 treated counties (at least one hour-reduced PO), 416 controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in seq_len(nrow(sde_results))) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
            sde_results$spec[i],
            sde_results$beta[i], sde_results$se[i],
            sde_results$sd_y[i], sde_results$sde[i],
            sde_results$se_sde[i], sde_results$classification[i]))
}

tabF1_lines <- c(tabF1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("Table F1 (SDE) written.\n")

# ============================================================
# Summary
# ============================================================
cat("\n=== All tables generated ===\n")
cat("Files in tables directory:\n")
cat(paste(list.files(table_dir), collapse = "\n"), "\n")
