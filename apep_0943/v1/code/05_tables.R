# 05_tables.R — Generate all LaTeX tables for apep_0943
source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
results <- readRDS("../data/results.rds")
rob <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

cat("=== Generating Tables ===\n\n")

# Helper: format number with stars
fmt_coef <- function(est, se, df = Inf) {
  p <- 2 * pt(-abs(est/se), df = df)
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  sprintf("%.3f%s", est, stars)
}

fmt_se <- function(se) sprintf("(%.3f)", se)

# ==========================================================================
# TABLE 1: Summary Statistics
# ==========================================================================
cat("--- Table 1: Summary Statistics ---\n")

sum_vars <- panel[, .(
  `New buildings (count)` = new_buildings,
  `New buildings per 1,000 pop.` = new_bld_pc,
  `Population (thousands)` = population,
  `CO2 Act yes share (\\%)` = co2_yes,
  `Climate Act 2023 yes share (\\%)` = klg23_yes,
  `Adopted cantonal climate law` = has_policy_cum
)]

sum_stats <- data.table(
  Variable = names(sum_vars),
  Mean = sapply(sum_vars, mean, na.rm = TRUE),
  SD = sapply(sum_vars, sd, na.rm = TRUE),
  Min = sapply(sum_vars, min, na.rm = TRUE),
  Max = sapply(sum_vars, max, na.rm = TRUE)
)

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l S[table-format=4.2] S[table-format=3.2] S[table-format=4.2] S[table-format=4.2]}",
  "\\toprule",
  "Variable & {Mean} & {Std. Dev.} & {Min} & {Max} \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_stats)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\",
            sum_stats$Variable[i], sum_stats$Mean[i], sum_stats$SD[i],
            sum_stats$Min[i], sum_stats$Max[i]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %d canton-year observations (26 cantons $\\times$ 11 years, 2013--2023). CO2 Act yes share is the cantonal percentage voting yes on the June 13, 2021 referendum. Climate law adoption equals one if the canton adopted new climate legislation by that year.", nrow(panel)),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")
cat("Table 1 written.\n")

# ==========================================================================
# TABLE 2: Climate Policy Adoption
# ==========================================================================
cat("--- Table 2: Policy Adoption ---\n")

lpm <- results$lpm_adoption
lpm_coef <- coef(lpm)["co2_frac"]
lpm_se <- sqrt(diag(vcov(lpm)))["co2_frac"]

# Also run with Energy Act as instrument
lpm2 <- lm(adopted_climate_law ~ energy_frac, data = panel[year == 2022])
lpm2_coef <- coef(lpm2)["energy_frac"]
lpm2_se <- sqrt(diag(vcov(lpm2)))["energy_frac"]

# Both together
lpm3 <- lm(adopted_climate_law ~ co2_frac + immig_frac, data = panel[year == 2022])
lpm3_coef_co2 <- coef(lpm3)["co2_frac"]
lpm3_se_co2 <- sqrt(diag(vcov(lpm3)))["co2_frac"]
lpm3_coef_imm <- coef(lpm3)["immig_frac"]
lpm3_se_imm <- sqrt(diag(vcov(lpm3)))["immig_frac"]

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Cross-Sectional Predictors of Cantonal Climate Law Adoption}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "& (1) & (2) & (3) \\\\",
  "\\midrule",
  sprintf("CO2 Act yes share & %s & & %s \\\\", fmt_coef(lpm_coef, lpm_se, 24), fmt_coef(lpm3_coef_co2, lpm3_se_co2, 23)),
  sprintf("& %s & & %s \\\\", fmt_se(lpm_se), fmt_se(lpm3_se_co2)),
  sprintf("Energy Act 2017 yes share & & %s & \\\\", fmt_coef(lpm2_coef, lpm2_se, 24)),
  sprintf("& & %s & \\\\", fmt_se(lpm2_se)),
  sprintf("Immigration Init. yes share & & & %s \\\\", fmt_coef(lpm3_coef_imm, lpm3_se_imm, 23)),
  sprintf("& & & %s \\\\", fmt_se(lpm3_se_imm)),
  "\\midrule",
  sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\", summary(lpm)$r.squared, summary(lpm2)$r.squared, summary(lpm3)$r.squared),
  "N & 26 & 26 & 26 \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Linear probability models. Dependent variable equals one if the canton adopted new climate legislation between the CO2 Act rejection (June 2021) and end of 2023. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:adoption}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_adoption.tex")
cat("Table 2 written.\n")

# ==========================================================================
# TABLE 3: Main DiD Results
# ==========================================================================
cat("--- Table 3: Main DiD Results ---\n")

m1 <- results$did_levels
m2 <- results$did_std
m3 <- results$did_binary
m4 <- results$did_log
m5 <- results$did_popcontrol

# Extract coefficients
models <- list(m1, m2, m3, m4, m5)
main_vars <- c("treat_post", "treat_std_post", "treat_high_post", "treat_post", "treat_post")
dep_vars <- c("Levels", "Std. treatment", "Binary treat.", "Log", "Pop. control")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of CO2 Act Rejection on New Building Construction}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  sprintf("& %s \\\\", paste(dep_vars, collapse = " & ")),
  "\\midrule"
)

# Row 1: Coefficient
coefs_row <- sapply(1:5, function(i) {
  v <- main_vars[i]
  b <- coef(models[[i]])[v]
  s <- sqrt(diag(vcov(models[[i]])))[v]
  fmt_coef(b, s, models[[i]]$nobs - models[[i]]$nparams)
})
tab3_lines <- c(tab3_lines,
  sprintf("CO2 vote $\\times$ Post & %s \\\\", paste(coefs_row, collapse = " & ")))

# Row 2: SE
ses_row <- sapply(1:5, function(i) {
  v <- main_vars[i]
  s <- sqrt(diag(vcov(models[[i]])))[v]
  fmt_se(s)
})
tab3_lines <- c(tab3_lines,
  sprintf("& %s \\\\", paste(ses_row, collapse = " & ")))

# Log(population) for model 5
tab3_lines <- c(tab3_lines,
  "\\\\",
  sprintf("log(population) & & & & & %s \\\\",
          fmt_coef(coef(m5)["log(population)"],
                   sqrt(diag(vcov(m5)))["log(population)"])),
  sprintf("& & & & & %s \\\\",
          fmt_se(sqrt(diag(vcov(m5)))["log(population)"])))

# Footer
tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          m1$nobs, m2$nobs, m3$nobs, m4$nobs, m5$nobs),
  "Canton FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Adj. $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(m1, "ar2")[[1]], fitstat(m2, "ar2")[[1]],
          fitstat(m3, "ar2")[[1]], fitstat(m4, "ar2")[[1]],
          fitstat(m5, "ar2")[[1]]),
  "Clusters & 26 & 26 & 26 & 26 & 26 \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is new residential buildings per 1,000 population (columns 1--3, 5) or log new buildings per capita (column 4). CO2 vote is the cantonal CO2 Act yes share (0--1). Post equals one for 2022--2023. Column 2 standardizes the vote share (mean zero, unit variance). Column 3 uses a binary indicator for above-median CO2 support. Standard errors clustered at the canton level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_main.tex")
cat("Table 3 written.\n")

# ==========================================================================
# TABLE 4: Event Study Coefficients
# ==========================================================================
cat("--- Table 4: Event Study ---\n")

es <- results$es_coefs

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: CO2 Vote Share $\\times$ Event-Time Interactions}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Event time & Year & Coefficient & Std. Error & 95\\% CI \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Pre-treatment}} \\\\"
)

years <- c(2013:2019, 2022:2023)
for (i in 1:nrow(es)) {
  prefix <- ifelse(es$event_time[i] >= 0, "\\textit{Post-treatment}", "")
  if (es$event_time[i] == 0) {
    tab4_lines <- c(tab4_lines,
      "\\midrule",
      "\\multicolumn{5}{l}{\\textit{Post-treatment (omitted: $t=-1$, year 2021)}} \\\\")
  }
  tab4_lines <- c(tab4_lines,
    sprintf("$t = %d$ & %d & %s & %.3f & [%.3f, %.3f] \\\\",
            es$event_time[i], years[i],
            fmt_coef(es$coef[i], es$se[i]),
            es$se[i], es$ci_lo[i], es$ci_hi[i]))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{4}{c}{%d} \\\\", results$event_study$nobs),
  "Canton FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{4}{c}{Yes} \\\\",
  "Clusters & \\multicolumn{4}{c}{26} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each coefficient is the interaction of CO2 Act cantonal yes share with an event-time indicator. The omitted period is $t = -1$ (2021, the year of the referendum). Dependent variable: new residential buildings per 1,000 population. Standard errors clustered at the canton level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:eventstudy}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_eventstudy.tex")
cat("Table 4 written.\n")

# ==========================================================================
# TABLE 5: Robustness
# ==========================================================================
cat("--- Table 5: Robustness ---\n")

rob_models <- list(
  results$did_levels,       # Main
  rob$placebo_immigration,  # Placebo treatment
  rob$placebo_popgrowth,    # Placebo outcome
  rob$robust_se,            # HC robust
  rob$energy_act            # Energy Act treatment
)
rob_vars <- c("treat_post", "immig_post", "treat_post", "treat_post", "energy_post")
rob_labels <- c("Main", "Placebo: Immigration", "Placebo: Pop. growth",
                "HC robust SE", "Energy Act 2017")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "& (1) & (2) & (3) & (4) & (5) \\\\",
  sprintf("& %s \\\\", paste(rob_labels, collapse = " & ")),
  "\\midrule"
)

rob_coefs <- sapply(1:5, function(i) {
  b <- coef(rob_models[[i]])[rob_vars[i]]
  s <- sqrt(diag(vcov(rob_models[[i]])))[rob_vars[i]]
  fmt_coef(b, s)
})
rob_ses <- sapply(1:5, function(i) {
  s <- sqrt(diag(vcov(rob_models[[i]])))[rob_vars[i]]
  fmt_se(s)
})

tab5_lines <- c(tab5_lines,
  sprintf("Treatment $\\times$ Post & %s \\\\", paste(rob_coefs, collapse = " & ")),
  sprintf("& %s \\\\", paste(rob_ses, collapse = " & ")),
  "\\midrule",
  sprintf("Dep. variable & %s \\\\",
          paste(c("New bld/1K", "New bld/1K", "Pop. growth", "New bld/1K", "New bld/1K"), collapse = " & ")),
  sprintf("Treatment variable & %s \\\\",
          paste(c("CO2 vote", "Immig. vote", "CO2 vote", "CO2 vote", "Energy vote"), collapse = " & ")),
  sprintf("N & %s \\\\", paste(sapply(rob_models, function(m) m$nobs), collapse = " & ")),
  "Canton FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Column 1 replicates the main specification. Column 2 uses the 2014 Mass Immigration Initiative cantonal yes share as a placebo treatment (negatively correlated with CO2 support). Column 3 uses population growth as a placebo outcome. Column 4 uses heteroskedasticity-robust standard errors instead of canton clustering. Column 5 uses the 2017 Energy Act yes share as an alternative treatment measure. Standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robustness}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_robustness.tex")
cat("Table 5 written.\n")

# ==========================================================================
# TABLE F1: SDE Table (Appendix)
# ==========================================================================
cat("--- Table F1: Standardized Effect Sizes ---\n")

# Extract main estimates
m_main <- results$did_levels
beta_main <- coef(m_main)["treat_post"]
se_main <- sqrt(diag(vcov(m_main)))["treat_post"]
sd_y <- sd(panel$new_bld_pc)

# The treatment is continuous (CO2 vote fraction)
sd_x <- sd(panel$co2_frac)

# SDE for continuous treatment: beta * SD(X) / SD(Y)
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

# Classification
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

cat(sprintf("  Main SDE: %.4f (classification: %s)\n", sde_main, classify(sde_main)))

# Heterogeneity: Urban vs Rural cantons
urban_cantons <- c("ZH", "BE", "BS", "GE", "VD", "LU", "SG", "AG", "BL", "SO", "FR", "TI", "ZG")
rural_cantons <- setdiff(unique(panel$canton), urban_cantons)

m_urban <- feols(new_bld_pc ~ treat_post | canton + year,
                 data = panel[canton %in% urban_cantons], cluster = ~canton)
m_rural <- feols(new_bld_pc ~ treat_post | canton + year,
                 data = panel[canton %in% rural_cantons], cluster = ~canton)

beta_urban <- coef(m_urban)["treat_post"]
se_urban <- sqrt(diag(vcov(m_urban)))["treat_post"]
sd_y_urban <- sd(panel[canton %in% urban_cantons]$new_bld_pc)
sd_x_urban <- sd(panel[canton %in% urban_cantons]$co2_frac)
sde_urban <- beta_urban * sd_x_urban / sd_y_urban
se_sde_urban <- se_urban * sd_x_urban / sd_y_urban

beta_rural <- coef(m_rural)["treat_post"]
se_rural <- sqrt(diag(vcov(m_rural)))["treat_post"]
sd_y_rural <- sd(panel[canton %in% rural_cantons]$new_bld_pc)
sd_x_rural <- sd(panel[canton %in% rural_cantons]$co2_frac)
sde_rural <- beta_rural * sd_x_rural / sd_y_rural
se_sde_rural <- se_rural * sd_x_rural / sd_y_rural

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the rejection of a national climate referendum trigger compensatory building activity in pro-climate jurisdictions? ",
  "\\textbf{Policy mechanism:} The June 2021 CO2 Act referendum failure created a federal policy vacuum; ",
  "pro-climate cantons subsequently adopted independent climate legislation (fossil heating bans, climate neutrality targets), ",
  "incentivizing building energy transitions and new energy-efficient construction. ",
  "\\textbf{Outcome definition:} New residential buildings permitted per 1,000 cantonal population, from the BFS building register (GWR). ",
  "\\textbf{Treatment:} Continuous---cantonal CO2 Act yes vote share (range 33.8\\%--66.6\\%), interacted with a post-rejection indicator. ",
  "\\textbf{Data:} BFS Gebäude- und Wohnungsregister (GWR) new buildings, 26 cantons, 2013--2023 (286 canton-years). ",
  "\\textbf{Method:} Two-way fixed effects (canton + year), canton-clustered standard errors. ",
  "\\textbf{Sample:} All 26 Swiss cantons; no sample restrictions. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-cantonal standard deviation of the CO2 Act yes share and SD($Y$) is the unconditional standard deviation of new buildings per capita. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("New bld/1K pop. & Main DiD & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_main, sd_x, sd_y, sde_main, se_sde_main, classify(sde_main)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("New bld/1K pop. & Urban cantons & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_urban, sd_x_urban, sd_y_urban, sde_urban, se_sde_urban, classify(sde_urban)),
  sprintf("New bld/1K pop. & Rural cantons & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_rural, sd_x_rural, sd_y_rural, sde_rural, se_sde_rural, classify(sde_rural)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
cat(paste(list.files("../tables/"), collapse = "\n"), "\n")
