# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_1070: H-2A Guestworker Expansion and Farm Worker Displacement
# =============================================================================

source("00_packages.R")

results_main <- readRDS("../data/results_main.rds")
results_iv <- readRDS("../data/results_iv.rds")
results_robust <- readRDS("../data/results_robustness.rds")
results_event <- readRDS("../data/results_event.rds")
pre_sd <- readRDS("../data/pre_treatment_sd.rds")
df <- readRDS("../data/analysis_panel.rds")

dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

df_emp <- df %>% filter(!is.na(emp) & emp > 0)

# Panel A: Hispanic workers in agriculture
hisp <- df_emp %>% filter(hispanic == 1)
non_hisp <- df_emp %>% filter(hispanic == 0)

make_sumstat_row <- function(data, varname, label) {
  vals <- data[[varname]]
  vals <- vals[!is.na(vals) & is.finite(vals)]
  data.frame(
    Variable = label,
    Mean = round(mean(vals), 2),
    SD = round(sd(vals), 2),
    P25 = round(quantile(vals, 0.25), 2),
    Median = round(quantile(vals, 0.50), 2),
    P75 = round(quantile(vals, 0.75), 2),
    N = format(length(vals), big.mark = ",")
  )
}

panel_a <- bind_rows(
  make_sumstat_row(hisp, "emp", "Employment"),
  make_sumstat_row(hisp, "earnings", "Quarterly earnings (\\$)"),
  make_sumstat_row(hisp, "separations", "Separations"),
  make_sumstat_row(hisp, "hires", "All hires"),
  make_sumstat_row(hisp, "h2a_positions", "H-2A certified positions")
)

panel_b <- bind_rows(
  make_sumstat_row(non_hisp, "emp", "Employment"),
  make_sumstat_row(non_hisp, "earnings", "Quarterly earnings (\\$)"),
  make_sumstat_row(non_hisp, "separations", "Separations"),
  make_sumstat_row(non_hisp, "hires", "All hires"),
  make_sumstat_row(non_hisp, "h2a_positions", "H-2A certified positions")
)

# Build LaTeX table
tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: QWI Agriculture Employment by Ethnicity}\n",
  "\\label{tab:sumstats}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & P25 & Median & P75 & N \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Hispanic Workers (NAICS 11)}} \\\\\n"
)
for (i in 1:nrow(panel_a)) {
  tab1 <- paste0(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
                                panel_a$Variable[i], panel_a$Mean[i], panel_a$SD[i],
                                panel_a$P25[i], panel_a$Median[i], panel_a$P75[i], panel_a$N[i]))
}
tab1 <- paste0(tab1,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Non-Hispanic Workers (NAICS 11)}} \\\\\n"
)
for (i in 1:nrow(panel_b)) {
  tab1 <- paste0(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
                                panel_b$Variable[i], panel_b$Mean[i], panel_b$SD[i],
                                panel_b$P25[i], panel_b$Median[i], panel_b$P75[i], panel_b$N[i]))
}
tab1 <- paste0(tab1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Unit of observation is county $\\times$ quarter $\\times$ ethnicity in NAICS 11 (agriculture). ",
  "Sample: 2010--2023. Employment = beginning-of-quarter count; earnings = average monthly earnings of stable workers; ",
  "separations and hires are quarterly flows. H-2A certified positions from DOL Foreign Labor Certification ",
  "disclosure files, aggregated to county-year. Source: Census QWI and DOL FLC.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ---------------------------------------------------------------------------
# Table 2: Main DDD Results
# ---------------------------------------------------------------------------
cat("Generating Table 2: Main DDD Results...\n")

# Extract coefficients and SEs from main models
extract_coef <- function(model, coef_name = "ln_h2a:hispanic::1") {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model)))
  idx <- grep(coef_name, names(cf), fixed = TRUE)
  if (length(idx) == 0) {
    # Try alternative names
    idx <- grep("hispanic.*1", names(cf))
  }
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA, stars = ""))
  b <- cf[idx[1]]
  s <- se[idx[1]]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, stars = stars)
}

m_coefs <- lapply(results_main, extract_coef)
iv_coefs <- lapply(results_iv, extract_coef)

# Get N and R² for each model
get_stats <- function(model) {
  list(
    n = nobs(model),
    r2 = fitstat(model, "r2")$r2,
    n_counties = length(unique(model$fixef_sizes))
  )
}

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{H-2A Expansion and Hispanic Agricultural Employment: Triple-Difference Estimates}\n",
  "\\label{tab:main}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{4}{c}{Dependent Variable (log)} \\\\\n",
  "\\cmidrule(lr){2-5}\n",
  " & Employment & Earnings & Separations & Hires \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: OLS Triple-Difference}} \\\\\n",
  sprintf("ln(H-2A) $\\times$ Hispanic & %s%s & %s%s & %s%s & %s%s \\\\\n",
          format(round(m_coefs$emp$b, 4), nsmall = 4), m_coefs$emp$stars,
          format(round(m_coefs$earn$b, 4), nsmall = 4), m_coefs$earn$stars,
          format(round(m_coefs$sep$b, 4), nsmall = 4), m_coefs$sep$stars,
          format(round(m_coefs$hire$b, 4), nsmall = 4), m_coefs$hire$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          format(round(m_coefs$emp$se, 4), nsmall = 4),
          format(round(m_coefs$earn$se, 4), nsmall = 4),
          format(round(m_coefs$sep$se, 4), nsmall = 4),
          format(round(m_coefs$hire$se, 4), nsmall = 4)),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(results_main$emp), big.mark = ","),
          format(nobs(results_main$earn), big.mark = ","),
          format(nobs(results_main$sep), big.mark = ","),
          format(nobs(results_main$hire), big.mark = ",")),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Bartik IV}} \\\\\n",
  sprintf("ln(H-2A) $\\times$ Hispanic & %s%s & %s%s & & \\\\\n",
          format(round(iv_coefs$emp$b, 4), nsmall = 4), iv_coefs$emp$stars,
          format(round(iv_coefs$earn$b, 4), nsmall = 4), iv_coefs$earn$stars),
  sprintf(" & (%s) & (%s) & & \\\\\n",
          format(round(iv_coefs$emp$se, 4), nsmall = 4),
          format(round(iv_coefs$earn$se, 4), nsmall = 4)),
  sprintf("Observations & %s & %s & & \\\\\n",
          format(nobs(results_iv$emp), big.mark = ","),
          format(nobs(results_iv$earn), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each column reports the coefficient on ln(H-2A certified positions) $\\times$ Hispanic from ",
  "a triple-difference specification with county $\\times$ ethnicity, quarter $\\times$ ethnicity, and state $\\times$ ",
  "quarter fixed effects. Panel B instruments ln(H-2A) with a Bartik shift-share: county's 2018 H-2A share $\\times$ ",
  "national H-2A growth. Standard errors clustered at county level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ---------------------------------------------------------------------------
# Table 3: Placebo Tests
# ---------------------------------------------------------------------------
cat("Generating Table 3: Placebo Tests...\n")

p23 <- extract_coef(results_robust$placebo_23)
p72 <- extract_coef(results_robust$placebo_72)

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Placebo Tests: Non-H-2A Industries}\n",
  "\\label{tab:placebo}\n",
  "\\small\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Agriculture & Construction & Food Service \\\\\n",
  " & NAICS 11 & NAICS 23 & NAICS 72 \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  sprintf("ln(H-2A) $\\times$ Hispanic & %s%s & %s%s & %s%s \\\\\n",
          format(round(m_coefs$emp$b, 4), nsmall = 4), m_coefs$emp$stars,
          format(round(p23$b, 4), nsmall = 4), p23$stars,
          format(round(p72$b, 4), nsmall = 4), p72$stars),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format(round(m_coefs$emp$se, 4), nsmall = 4),
          format(round(p23$se, 4), nsmall = 4),
          format(round(p72$se, 4), nsmall = 4)),
  sprintf("Observations & %s & %s & %s \\\\\n",
          format(nobs(results_main$emp), big.mark = ","),
          format(nobs(results_robust$placebo_23), big.mark = ","),
          format(nobs(results_robust$placebo_72), big.mark = ",")),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable: log employment. Each column reports the DDD coefficient on ln(H-2A) ",
  "$\\times$ Hispanic from the same specification as Table~\\ref{tab:main}. Construction (NAICS 23) and food service ",
  "(NAICS 72) employ many Hispanic workers but are not served by the H-2A program. Null effects in columns (2)--(3) ",
  "support the interpretation that the agriculture result reflects H-2A-specific displacement rather than broader ",
  "Hispanic labor market trends. Standard errors clustered at county level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_placebo.tex")

# ---------------------------------------------------------------------------
# Table 4: Robustness Checks
# ---------------------------------------------------------------------------
cat("Generating Table 4: Robustness...\n")

r_state <- extract_coef(results_robust$state_cluster)
r_nocovid <- extract_coef(results_robust$no_covid)

# Levels spec
levels_coef <- extract_coef(results_robust$levels)

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\small\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Baseline & State & Excl.\\ COVID & Levels \\\\\n",
  " & & cluster & (2020--21) & \\\\\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("ln(H-2A) $\\times$ Hispanic & %s%s & %s%s & %s%s & %s%s \\\\\n",
          format(round(m_coefs$emp$b, 4), nsmall = 4), m_coefs$emp$stars,
          format(round(r_state$b, 4), nsmall = 4), r_state$stars,
          format(round(r_nocovid$b, 4), nsmall = 4), r_nocovid$stars,
          format(round(levels_coef$b, 2), nsmall = 2), levels_coef$stars),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\\n",
          format(round(m_coefs$emp$se, 4), nsmall = 4),
          format(round(r_state$se, 4), nsmall = 4),
          format(round(r_nocovid$se, 4), nsmall = 4),
          format(round(levels_coef$se, 2), nsmall = 2)),
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(results_main$emp), big.mark = ","),
          format(nobs(results_main$emp), big.mark = ","),
          format(nobs(results_robust$no_covid), big.mark = ","),
          format(nobs(results_robust$levels), big.mark = ",")),
  "Dep.\\ var.\\ & log & log & log & level \\\\\n",
  "Clustering & county & state & county & county \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Dependent variable: employment in NAICS 11 (agriculture). Column (1) reproduces the baseline ",
  "from Table~\\ref{tab:main}. Column (2) clusters at state level. Column (3) drops 2020--2021 to exclude COVID labor ",
  "disruptions. Column (4) uses employment in levels rather than logs. All specifications include county $\\times$ ",
  "ethnicity, quarter $\\times$ ethnicity, and state $\\times$ quarter fixed effects. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robust.tex")

# ---------------------------------------------------------------------------
# Table 5: Event Study (Period-binned)
# ---------------------------------------------------------------------------
cat("Generating Table 5: Event Study...\n")

event_coefs <- coef(results_event)
event_se <- sqrt(diag(vcov(results_event)))

# Extract the period-specific DDD coefficients
event_names <- names(event_coefs)
cat("Event study coefficient names:\n")
print(event_names)

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: H-2A Expansion Effects by Period}\n",
  "\\label{tab:event}\n",
  "\\small\n",
  "\\begin{tabular}{lc}\n",
  "\\hline\\hline\n",
  " & log(Employment) \\\\\n",
  "\\hline\n"
)

for (i in seq_along(event_coefs)) {
  nm <- event_names[i]
  b <- event_coefs[i]
  s <- event_se[i]
  p <- 2 * pnorm(-abs(b / s))
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  # Clean up name for display
  display_name <- gsub("period::", "", nm)
  display_name <- gsub(":ln_h2a:hispanic::1", "", display_name)
  tab5 <- paste0(tab5,
    sprintf("%s & %s%s \\\\\n", display_name,
            format(round(b, 4), nsmall = 4), stars),
    sprintf(" & (%s) \\\\\n", format(round(s, 4), nsmall = 4))
  )
}

tab5 <- paste0(tab5,
  sprintf("Observations & %s \\\\\n", format(nobs(results_event), big.mark = ",")),
  "Reference period & Pre (2010--13) \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the DDD coefficient on ln(H-2A) $\\times$ Hispanic interacted with ",
  "period indicators, relative to the pre-expansion period (2010--2013). The specification includes county $\\times$ ",
  "ethnicity, quarter $\\times$ ethnicity, and state $\\times$ quarter fixed effects. Standard errors clustered at ",
  "county level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5, "../tables/tab5_event.tex")

# ---------------------------------------------------------------------------
# SDE Table (Appendix F1)
# ---------------------------------------------------------------------------
cat("Generating SDE Table (tabF1_sde.tex)...\n")

# SDE = β̂ / SD(Y) for continuous treatment
# For continuous treatment: SDE = β̂ × SD(X) / SD(Y)
# Here X = ln(H-2A), Y = log outcome

sd_x <- as.numeric(pre_sd$sd_ln_h2a)

compute_sde <- function(model, sd_y, coef_name = "ln_h2a:hispanic::1") {
  r <- extract_coef(model, coef_name)
  if (is.na(r$b)) return(list(beta = NA, se = NA, sd_y = NA, sde = NA, se_sde = NA, class = ""))
  sde <- r$b * sd_x / sd_y
  se_sde <- r$se * sd_x / sd_y
  abs_sde <- abs(sde)
  class_label <- ifelse(abs_sde > 0.15, ifelse(sde > 0, "Large positive", "Large negative"),
                  ifelse(abs_sde > 0.05, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
                  ifelse(abs_sde > 0.005, ifelse(sde > 0, "Small positive", "Small negative"),
                  "Null")))
  list(beta = r$b, se = r$se, sd_y = sd_y, sde = sde, se_sde = se_sde, class = class_label)
}

sde_emp <- compute_sde(results_main$emp, as.numeric(pre_sd$sd_ln_emp))
sde_earn <- compute_sde(results_main$earn, as.numeric(pre_sd$sd_ln_earn))
sde_sep <- compute_sde(results_main$sep, as.numeric(pre_sd$sd_ln_sep))
sde_hire <- compute_sde(results_main$hire, as.numeric(pre_sd$sd_ln_hire))

# Panel B: Heterogeneity — split by initial H-2A intensity
# High H-2A counties: initial_h2a > median among treated
df_emp_full <- df %>% filter(!is.na(emp) & emp > 0)
med_h2a <- median(df_emp_full$initial_h2a[df_emp_full$initial_h2a > 0], na.rm = TRUE)

df_high <- df_emp_full %>% filter(initial_h2a >= med_h2a & initial_h2a > 0)
df_low <- df_emp_full %>% filter(initial_h2a < med_h2a | initial_h2a == 0)

m_high <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_high,
  cluster = ~county_fips
)

m_low <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_low,
  cluster = ~county_fips
)

sde_high <- compute_sde(m_high, as.numeric(pre_sd$sd_ln_emp))
sde_low <- compute_sde(m_low, as.numeric(pre_sd$sd_ln_emp))

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the expansion of H-2A temporary agricultural guestworker ",
  "certifications displace Hispanic domestic workers in agriculture or complement the existing labor force? ",
  "\\textbf{Policy mechanism:} The H-2A program allows U.S. agricultural employers to petition the Department ",
  "of Labor for certification to hire foreign workers on temporary seasonal visas; certified positions tripled ",
  "from 85,000 (2012) to 372,000 (2022), creating county-level variation in foreign temporary labor supply ",
  "that potentially substitutes for or complements domestic Hispanic farm workers. ",
  "\\textbf{Outcome definition:} Log beginning-of-quarter employment count, log average quarterly earnings ",
  "of stable workers, log quarterly separations, and log quarterly all-hires from Census QWI for NAICS 11 ",
  "(agriculture, forestry, fishing, hunting). ",
  "\\textbf{Treatment:} Continuous log of county-level H-2A certified positions from DOL Foreign Labor ",
  "Certification disclosure files, interacted with Hispanic ethnicity indicator. ",
  "\\textbf{Data:} Census Quarterly Workforce Indicators (QWI) race/ethnicity panel and DOL H-2A disclosure ",
  "files, 2010--2023, county $\\times$ quarter $\\times$ ethnicity cells. ",
  "\\textbf{Method:} Triple-difference (county $\\times$ quarter $\\times$ ethnicity) with county-ethnicity, ",
  "quarter-ethnicity, and state-quarter fixed effects; standard errors clustered at county level. ",
  "\\textbf{Sample:} U.S. counties with non-suppressed QWI employment data in NAICS 11 for both Hispanic ",
  "and non-Hispanic workers. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the pre-treatment standard deviation ",
  "of ln(H-2A + 1) and SD($Y$) is the pre-treatment standard deviation of the log outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

format_sde_row <- function(label, sde_obj) {
  sprintf("%s & %s & %s & %s & %s & %s & %s",
          label,
          format(round(sde_obj$beta, 4), nsmall = 4),
          format(round(sde_obj$se, 4), nsmall = 4),
          format(round(sde_obj$sd_y, 3), nsmall = 3),
          format(round(sde_obj$sde, 4), nsmall = 4),
          format(round(sde_obj$se_sde, 4), nsmall = 4),
          sde_obj$class)
}

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\small\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  format_sde_row("Employment", sde_emp), " \\\\\n",
  format_sde_row("Earnings", sde_earn), " \\\\\n",
  format_sde_row("Separations", sde_sep), " \\\\\n",
  format_sde_row("Hires", sde_hire), " \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by initial H-2A intensity)}} \\\\\n",
  format_sde_row("Employment (high H-2A)", sde_high), " \\\\\n",
  format_sde_row("Employment (low H-2A)", sde_low), " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("  tables/tab1_sumstats.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_placebo.tex\n")
cat("  tables/tab4_robust.tex\n")
cat("  tables/tab5_event.tex\n")
cat("  tables/tabF1_sde.tex\n")
