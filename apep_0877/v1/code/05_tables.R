## 05_tables.R — Generate all LaTeX tables
## apep_0877: Croatia 2013 Fiscalization

source("code/00_packages.R")

cat("=== Generating Tables ===\n")

# Load results
results_vat <- readRDS("data/results_vat.rds")
results_sector <- readRDS("data/results_sector.rds")
results_ddd <- readRDS("data/results_ddd.rds")
robustness <- readRDS("data/robustness_all.rds")
sde_inputs <- readRDS("data/sde_inputs.rds")
panel_vat <- readRDS("data/panel_vat.rds")
panel_gva <- readRDS("data/panel_gva.rds")

# ===============================================================
# TABLE 1: Summary Statistics
# ===============================================================
cat("Generating Table 1: Summary Statistics...\n")

# Pre vs post for Croatia and controls
sumstat <- panel_vat %>%
  mutate(group = ifelse(country == "HR", "Croatia", "Controls"),
         period = ifelse(year < 2013, "Pre (2008--2012)", "Post (2013--2023)")) %>%
  group_by(group, period) %>%
  summarise(
    mean_vat = mean(vat_gdp, na.rm = TRUE),
    sd_vat = sd(vat_gdp, na.rm = TRUE),
    mean_gdp = mean(gdp_growth, na.rm = TRUE),
    mean_unemp = mean(unemp_rate, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

# Format table
tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: VAT Revenue and Macroeconomic Conditions}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Croatia} & \\multicolumn{2}{c}{Control Countries} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Pre & Post & Pre & Post \\\\\n",
  "\\hline\n"
)

hr_pre <- sumstat %>% filter(group == "Croatia", period == "Pre (2008--2012)")
hr_post <- sumstat %>% filter(group == "Croatia", period == "Post (2013--2023)")
ct_pre <- sumstat %>% filter(group == "Controls", period == "Pre (2008--2012)")
ct_post <- sumstat %>% filter(group == "Controls", period == "Post (2013--2023)")

tab1 <- paste0(tab1,
  sprintf("VAT/GDP (\\%%) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          hr_pre$mean_vat, hr_post$mean_vat, ct_pre$mean_vat, ct_post$mean_vat),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          hr_pre$sd_vat, hr_post$sd_vat, ct_pre$sd_vat, ct_post$sd_vat),
  sprintf("GDP growth (\\%%) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          hr_pre$mean_gdp, hr_post$mean_gdp, ct_pre$mean_gdp, ct_post$mean_gdp),
  sprintf("Unemployment (\\%%) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          hr_pre$mean_unemp, hr_post$mean_unemp, ct_pre$mean_unemp, ct_post$mean_unemp),
  sprintf("Country-years & %d & %d & %d & %d \\\\\n",
          hr_pre$n, hr_post$n, ct_pre$n, ct_post$n),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ",
  "Croatia is the treated country; control countries are Austria, Hungary, Romania, Slovakia, and Slovenia. ",
  "Pre-period: 2008--2012; post-period: 2013--2023. ",
  "VAT revenue as percentage of GDP from Eurostat \\texttt{gov\\_10a\\_taxag}. ",
  "GDP growth and unemployment from Eurostat national accounts and labor force survey.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "tables/tab1_sumstats.tex")
cat("  Saved tables/tab1_sumstats.tex\n")

# ===============================================================
# TABLE 2: Main Results — Cross-Country DiD
# ===============================================================
cat("Generating Table 2: Cross-Country DiD...\n")

m1a <- results_vat$basic
m1b <- results_vat$controls

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Fiscalization on VAT Revenue: Cross-Country Difference-in-Differences}\n",
  "\\label{tab:main_did}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{4}{c}{Dependent Variable: VAT/GDP (\\%)} \\\\\n",
  "\\cmidrule(lr){2-5}\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  sprintf("Croatia $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
          coef(m1a)["treat"], ifelse(pvalue(m1a)["treat"] < 0.01, "***",
            ifelse(pvalue(m1a)["treat"] < 0.05, "**",
              ifelse(pvalue(m1a)["treat"] < 0.1, "*", ""))),
          coef(m1b)["treat"], ifelse(pvalue(m1b)["treat"] < 0.01, "***",
            ifelse(pvalue(m1b)["treat"] < 0.05, "**",
              ifelse(pvalue(m1b)["treat"] < 0.1, "*", ""))),
          coef(robustness$no_hungary)["treat"],
            ifelse(pvalue(robustness$no_hungary)["treat"] < 0.01, "***",
              ifelse(pvalue(robustness$no_hungary)["treat"] < 0.05, "**",
                ifelse(pvalue(robustness$no_hungary)["treat"] < 0.1, "*", ""))),
          coef(robustness$short_window)["treat"],
            ifelse(pvalue(robustness$short_window)["treat"] < 0.01, "***",
              ifelse(pvalue(robustness$short_window)["treat"] < 0.05, "**",
                ifelse(pvalue(robustness$short_window)["treat"] < 0.1, "*", "")))),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
          se(m1a)["treat"], se(m1b)["treat"],
          se(robustness$no_hungary)["treat"],
          se(robustness$short_window)["treat"]),
  "GDP growth &  & Yes &  &  \\\\\n",
  "Unemployment &  & Yes &  &  \\\\\n",
  "Drop Hungary &  &  & Yes &  \\\\\n",
  "Short window (2013--16) &  &  &  & Yes \\\\\n",
  "\\hline\n",
  "Country FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d & %d \\\\\n",
          nobs(m1a), nobs(m1b), nobs(robustness$no_hungary),
          nobs(robustness$short_window)),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m1a, "wr2")[[1]], fitstat(m1b, "wr2")[[1]],
          fitstat(robustness$no_hungary, "wr2")[[1]],
          fitstat(robustness$short_window, "wr2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$. ",
  "The dependent variable is VAT revenue as a percentage of GDP. ",
  "Croatia introduced mandatory electronic cash register fiscalization in 2013. ",
  "Control countries: Austria, Hungary, Romania, Slovakia, and Slovenia (column 3 excludes Hungary). ",
  "Column (4) restricts the post-period to 2013--2016.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "tables/tab2_main_did.tex")
cat("  Saved tables/tab2_main_did.tex\n")

# ===============================================================
# TABLE 3: Triple Difference + Sector Results
# ===============================================================
cat("Generating Table 3: Sector-Level Results...\n")

m2a <- results_sector$basic
m2b <- results_sector$by_phase
m3a <- results_ddd$full_fe

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Sector-Level Effects of Fiscalization on Gross Value Added}\n",
  "\\label{tab:sector}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{3}{c}{Dependent Variable: Log GVA} \\\\\n",
  "\\cmidrule(lr){2-4}\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Within Croatia & By Phase & Triple Diff \\\\\n",
  "\\hline\n",
  sprintf("Treated $\\times$ Post & %.3f &  & %.3f%s \\\\\n",
          coef(m2a)["sector_treat"], coef(m3a)["ddd"],
          ifelse(pvalue(m3a)["ddd"] < 0.01, "***",
            ifelse(pvalue(m3a)["ddd"] < 0.05, "**",
              ifelse(pvalue(m3a)["ddd"] < 0.1, "*", "")))),
  sprintf(" & (%.3f) &  & (%.3f) \\\\\n",
          se(m2a)["sector_treat"], se(m3a)["ddd"]),
  sprintf("Phase 1 (Hospitality) $\\times$ Post &  & %.3f%s &  \\\\\n",
          coef(m2b)["phase1_treat"],
          ifelse(pvalue(m2b)["phase1_treat"] < 0.01, "***",
            ifelse(pvalue(m2b)["phase1_treat"] < 0.05, "**",
              ifelse(pvalue(m2b)["phase1_treat"] < 0.1, "*", "")))),
  sprintf(" &  & (%.3f) &  \\\\\n", se(m2b)["phase1_treat"]),
  sprintf("Phase 2 (Retail) $\\times$ Post &  & %.3f &  \\\\\n",
          coef(m2b)["phase2_treat"]),
  sprintf(" &  & (%.3f) &  \\\\\n", se(m2b)["phase2_treat"]),
  sprintf("Phase 3 (Other) $\\times$ Post &  & %.3f &  \\\\\n",
          coef(m2b)["phase3_treat"]),
  sprintf(" &  & (%.3f) &  \\\\\n", se(m2b)["phase3_treat"]),
  "\\hline\n",
  "Sector FE & Yes & Yes &  \\\\\n",
  "Year FE & Yes & Yes &  \\\\\n",
  "Country$\\times$Sector FE &  &  & Yes \\\\\n",
  "Country$\\times$Year FE &  &  & Yes \\\\\n",
  "Sector$\\times$Year FE &  &  & Yes \\\\\n",
  sprintf("Observations & %d & %d & %d \\\\\n",
          nobs(m2a), nobs(m2b), nobs(m3a)),
  sprintf("$R^2$ (within) & %.3f & %.3f & %.3f \\\\\n",
          fitstat(m2a, "wr2")[[1]], fitstat(m2b, "wr2")[[1]],
          fitstat(m3a, "wr2")[[1]]),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Columns (1)--(2) use Croatia-only data; standard errors clustered at the sector level. ",
  "Column (3) uses all six countries; standard errors clustered at the country level. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$. ",
  "The dependent variable is log gross value added (current prices, millions EUR) from Eurostat national accounts (NACE A64). ",
  "Phase 1 sectors (accommodation, food/beverage) were treated January 1, 2013; ",
  "Phase 2 (wholesale, retail, motor vehicles) April 1; Phase 3 (all remaining) July 1. ",
  "Never-treated sectors: agriculture, finance, real estate, public administration. ",
  "Column (3) includes country$\\times$sector, country$\\times$year, and sector$\\times$year fixed effects, ",
  "netting out all two-way confounds.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "tables/tab3_sector.tex")
cat("  Saved tables/tab3_sector.tex\n")

# ===============================================================
# TABLE 4: Robustness — Leave-One-Out + Placebo
# ===============================================================
cat("Generating Table 4: Robustness...\n")

loo <- robustness$loo

country_names <- c(SK = "Slovakia", AT = "Austria", SI = "Slovenia",
                   RO = "Romania", HU = "Hungary")

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Leave-One-Out and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  "\\multicolumn{3}{c}{\\textit{Panel A: Leave-One-Out (Cross-Country DiD)}} \\\\\n",
  "\\hline\n",
  "Dropped Country & $\\hat{\\beta}$ & SE \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(loo))) {
  stars <- ifelse(loo$pval[i] < 0.01, "***",
              ifelse(loo$pval[i] < 0.05, "**",
                ifelse(loo$pval[i] < 0.1, "*", "")))
  tab4 <- paste0(tab4,
    sprintf("%s & %.3f%s & (%.3f) \\\\\n",
            country_names[loo$dropped[i]], loo$beta[i], stars, loo$se[i]))
}

# Placebo and pre-trend
placebo_beta <- coef(robustness$placebo)["fake_treat"]
placebo_se <- se(robustness$placebo)["fake_treat"]
placebo_p <- pvalue(robustness$placebo)["fake_treat"]

pretrend_beta <- coef(robustness$pre_trend)["croatia:year"]
pretrend_se <- se(robustness$pre_trend)["croatia:year"]
pretrend_p <- pvalue(robustness$pre_trend)["croatia:year"]

exempt_beta <- coef(robustness$exempt_placebo)["croatia_post"]
exempt_se <- se(robustness$exempt_placebo)["croatia_post"]

tab4 <- paste0(tab4,
  "\\hline\n",
  "\\multicolumn{3}{c}{\\textit{Panel B: Placebo and Pre-Trend Tests}} \\\\\n",
  "\\hline\n",
  "Test & $\\hat{\\beta}$ & SE \\\\\n",
  "\\hline\n",
  sprintf("Fake treatment (2010) & %.3f & (%.3f) \\\\\n",
          placebo_beta, placebo_se),
  sprintf("Pre-trend (Croatia $\\times$ year) & %.3f & (%.3f) \\\\\n",
          pretrend_beta, pretrend_se),
  sprintf("Exempt sectors (placebo DDD) & %.3f%s & (%.3f) \\\\\n",
          exempt_beta,
          ifelse(abs(exempt_beta / exempt_se) > 2.58, "***",
            ifelse(abs(exempt_beta / exempt_se) > 1.96, "**",
              ifelse(abs(exempt_beta / exempt_se) > 1.65, "*", ""))),
          exempt_se),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Panel A drops one control country at a time; ",
  "dependent variable is VAT/GDP (\\%); standard errors clustered at the country level. ",
  "Panel B tests for pre-existing trends and placebo effects. ",
  "The fake treatment test assigns treatment in 2010 using only pre-2013 data. ",
  "The pre-trend test interacts Croatia with a linear time trend in the pre-period. ",
  "The exempt-sector test estimates a Croatia $\\times$ Post effect using only permanently exempt sectors ",
  "(agriculture, finance, real estate, public administration) and captures Croatia-specific macro trends ",
  "that the triple difference in Table~\\ref{tab:sector} nets out. ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "tables/tab4_robustness.tex")
cat("  Saved tables/tab4_robustness.tex\n")

# ===============================================================
# TABLE 5: Event Study Coefficients
# ===============================================================
cat("Generating Table 5: Event Study...\n")

es <- results_vat$es_coefs
# Fix event_time extraction
es$event_time <- as.integer(gsub("event_time::([-0-9]+):croatia", "\\1", rownames(es)))

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Event Study: Year-by-Year Treatment Effects on VAT/GDP}\n",
  "\\label{tab:eventstudy}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  "Year Relative to & Coefficient & SE & 95\\% CI \\\\\n",
  "Treatment & & & \\\\\n",
  "\\hline\n"
)

for (i in seq_len(nrow(es))) {
  et <- es$event_time[i]
  beta <- es$Estimate[i]
  se_val <- es$`Std. Error`[i]
  ci_lo <- beta - 1.96 * se_val
  ci_hi <- beta + 1.96 * se_val
  stars <- ifelse(es$`Pr(>|t|)`[i] < 0.01, "***",
              ifelse(es$`Pr(>|t|)`[i] < 0.05, "**",
                ifelse(es$`Pr(>|t|)`[i] < 0.1, "*", "")))
  label <- ifelse(et == -1, "\\textit{(reference)}", "")
  if (et == -1) next  # Skip reference year
  tab5 <- paste0(tab5,
    sprintf("$t %s %d$ & %.3f%s & (%.3f) & [%.3f, %.3f] \\\\\n",
            ifelse(et >= 0, "=", "="), et, beta, stars, se_val, ci_lo, ci_hi))
}

tab5 <- paste0(tab5,
  "$t = -1$ & \\multicolumn{3}{c}{\\textit{(reference)}} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  "\\item \\textit{Notes:} Estimated from Equation~(2) with country and year fixed effects. ",
  "Standard errors clustered at the country level. ",
  "The dependent variable is VAT/GDP (\\%). ",
  "$t = -1$ (2012) is the reference year. ",
  "Croatia introduced fiscalization in January 2013 ($t = 0$). ",
  "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab5, "tables/tab5_eventstudy.tex")
cat("  Saved tables/tab5_eventstudy.tex\n")

# ===============================================================
# TABLE F1: Standardized Effect Size (SDE) — Appendix
# ===============================================================
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
# 1. VAT/GDP (cross-country DiD)
vat_sde <- sde_inputs$vat_beta / sde_inputs$vat_sd_y
vat_sde_se <- sde_inputs$vat_se / sde_inputs$vat_sd_y

# 2. Log GVA — within Croatia sector DiD
gva_sde <- sde_inputs$gva_beta / sde_inputs$gva_sd_y
gva_sde_se <- sde_inputs$gva_se / sde_inputs$gva_sd_y

# 3. Triple difference
ddd_sd_y <- sd(panel_gva$log_gva[panel_gva$year < 2013], na.rm = TRUE)
ddd_sde <- sde_inputs$ddd_beta / ddd_sd_y
ddd_sde_se <- sde_inputs$ddd_se / ddd_sd_y

# 4. Phase 1 (hospitality) — within Croatia
m2b <- results_sector$by_phase
phase1_beta <- coef(m2b)["phase1_treat"]
phase1_se <- se(m2b)["phase1_treat"]
phase1_sde <- phase1_beta / sde_inputs$gva_sd_y
phase1_sde_se <- phase1_se / sde_inputs$gva_sd_y

classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

sde_rows <- data.frame(
  outcome = c("VAT/GDP (\\%)", "Log GVA (sector DiD)",
              "Log GVA (triple diff)", "Log GVA (Phase 1: hospitality)"),
  beta = c(sde_inputs$vat_beta, sde_inputs$gva_beta,
           sde_inputs$ddd_beta, phase1_beta),
  se_beta = c(sde_inputs$vat_se, sde_inputs$gva_se,
              sde_inputs$ddd_se, phase1_se),
  sd_y = c(sde_inputs$vat_sd_y, sde_inputs$gva_sd_y,
           ddd_sd_y, sde_inputs$gva_sd_y),
  sde = c(vat_sde, gva_sde, ddd_sde, phase1_sde),
  sde_se = c(vat_sde_se, gva_sde_se, ddd_sde_se, phase1_sde_se)
)
sde_rows$classification <- classify_sde(sde_rows$sde)

# Heterogeneity: Phase 1 vs Phase 2+3
het_rows <- data.frame(
  outcome = c("Phase 1 (hospitality)", "Phase 2--3 (retail, other)"),
  beta = c(phase1_beta,
           (coef(m2b)["phase2_treat"] + coef(m2b)["phase3_treat"]) / 2),
  se_beta = c(phase1_se,
              sqrt(se(m2b)["phase2_treat"]^2 + se(m2b)["phase3_treat"]^2) / 2),
  sd_y = rep(sde_inputs$gva_sd_y, 2),
  sde = c(phase1_sde,
          ((coef(m2b)["phase2_treat"] + coef(m2b)["phase3_treat"]) / 2) /
            sde_inputs$gva_sd_y),
  sde_se = c(phase1_sde_se,
             (sqrt(se(m2b)["phase2_treat"]^2 + se(m2b)["phase3_treat"]^2) / 2) /
               sde_inputs$gva_sd_y)
)
het_rows$classification <- classify_sde(het_rows$sde)

# Build LaTeX table
tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in seq_len(nrow(sde_rows))) {
  tabF1 <- paste0(tabF1,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            sde_rows$outcome[i], sde_rows$beta[i], sde_rows$se_beta[i],
            sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$sde_se[i],
            sde_rows$classification[i]))
}

tabF1 <- paste0(tabF1,
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Within-Croatia Log GVA)}} \\\\\n"
)

for (i in seq_len(nrow(het_rows))) {
  tabF1 <- paste0(tabF1,
    sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
            het_rows$outcome[i], het_rows$beta[i], het_rows$se_beta[i],
            het_rows$sd_y[i], het_rows$sde[i], het_rows$sde_se[i],
            het_rows$classification[i]))
}

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Croatia. ",
  "\\textbf{Research question:} Did mandatory electronic cash register fiscalization increase reported business activity and VAT compliance in Croatia? ",
  "\\textbf{Policy mechanism:} The 2013 Law on Fiscalization of Cash Transactions required all cash-receiving businesses to install certified electronic cash registers transmitting real-time data to the Tax Administration and issue digitally-signed receipts, eliminating opportunities to suppress cash sales. ",
  "\\textbf{Outcome definition:} Panel A rows 1: VAT revenue as percentage of GDP from Eurostat government revenue statistics; rows 2--4: log gross value added in current prices by NACE section from Eurostat national accounts. ",
  "\\textbf{Treatment:} Binary; country-level in cross-country DiD, sector-level in within-Croatia and triple-difference specifications. ",
  "\\textbf{Data:} Eurostat \\texttt{gov\\_10a\\_taxag} and \\texttt{nama\\_10\\_a64}, 2008--2023, country$\\times$sector$\\times$year panel with 6 countries and 21 NACE sections (2,096 observations). ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences and triple difference (country$\\times$sector + country$\\times$year + sector$\\times$year FE); standard errors clustered at the country level (cross-country) or sector level (within-Croatia). ",
  "\\textbf{Sample:} Croatia (treated) vs.\\ Austria, Hungary, Romania, Slovakia, and Slovenia (controls); within Croatia, treated sectors (hospitality, retail, industry, services) vs.\\ permanently exempt sectors (agriculture, finance, real estate, public administration). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(tabF1,
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
