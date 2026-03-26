## 05_tables.R — Generate all LaTeX tables
## APEP-0991: EU Landing Obligation

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results.rds")
rob <- readRDS("../data/robustness.rds")
sumstats <- readRDS("../data/sumstats.rds")

# Create post indicator
panel <- panel %>%
  mutate(post = as.integer(is_eu & year >= treat_year))

cat("=== Generating Tables ===\n")

# ======================================================================
# TABLE 1: Summary Statistics
# ======================================================================
cat("\n--- Table 1: Summary Statistics ---\n")

sumstat_tbl <- panel %>%
  group_by(treatment_group) %>%
  summarise(
    `N (country-years)` = n(),
    `Countries` = n_distinct(country),
    `Mean Catch (tonnes)` = formatC(mean(total_catch), format = "d", big.mark = ","),
    `SD Catch (tonnes)` = formatC(round(sd(total_catch)), format = "d", big.mark = ","),
    `Mean Log Catch` = sprintf("%.2f", mean(log_catch)),
    `SD Log Catch` = sprintf("%.2f", sd(log_catch)),
    `Treatment Year` = first(treat_year),
    .groups = "drop"
  ) %>%
  arrange(treatment_group)

# LaTeX table
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Species Group}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{tabular}{lccccccc}\n")
cat("\\hline\\hline\n")
cat("Species Group & N & Countries & Mean Catch & SD Catch & Mean Log & SD Log & LO Year \\\\\n")
cat(" & & & (tonnes) & (tonnes) & Catch & Catch & \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(sumstat_tbl)) {
  row <- sumstat_tbl[i, ]
  grp_label <- tools::toTitleCase(as.character(row$treatment_group))
  cat(sprintf("%s & %d & %d & %s & %s & %s & %s & %d \\\\\n",
              grp_label, row$`N (country-years)`, row$Countries,
              row$`Mean Catch (tonnes)`, row$`SD Catch (tonnes)`,
              row$`Mean Log Catch`, row$`SD Log Catch`, row$`Treatment Year`))
}
cat("\\hline\n")
cat(sprintf("Total & %d & %d & & & & & \\\\\n",
            nrow(panel), n_distinct(panel$country)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Unit of observation is country $\\times$ species group $\\times$ year. ")
cat("Panel spans 2000--2024 (25 years). EU countries: BE, DE, DK, EE, ES, FI, FR, IE, LT, LV, NL, PL, PT, SE, UK. ")
cat("Non-EU controls: Norway and Iceland (ICES Area 27). Species classified into Landing Obligation treatment cohorts: ")
cat("pelagic (herring, mackerel, sprat; treated January 2015), demersal (cod, haddock, sole, hake, plaice, Norway lobster; ")
cat("treated January 2016), and other regulated species (treated January 2019).\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab1_summary.tex written\n")

# ======================================================================
# TABLE 2: Main Results — TWFE by Species Group
# ======================================================================
cat("\n--- Table 2: Main Results ---\n")

# Extract coefficients
main_coef <- coef(results$twfe_catch)["post"]
main_se <- se(results$twfe_catch)["post"]
main_pval <- pvalue(results$twfe_catch)["post"]

pel_coef <- coef(results$twfe_pelagic)["post"]
pel_se <- se(results$twfe_pelagic)["post"]
pel_pval <- pvalue(results$twfe_pelagic)["post"]

dem_coef <- coef(results$twfe_demersal)["post"]
dem_se <- se(results$twfe_demersal)["post"]
dem_pval <- pvalue(results$twfe_demersal)["post"]

oth_coef <- coef(results$twfe_other)["post"]
oth_se <- se(results$twfe_other)["post"]
oth_pval <- pvalue(results$twfe_other)["post"]

sat_coef <- coef(results$twfe_sat)["post"]
sat_se <- se(results$twfe_sat)["post"]

stars <- function(p) {
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

format_coef <- function(b, s, p) {
  sprintf("%.3f%s", b, stars(p))
}

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of the Landing Obligation on Log Catches}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & All Species & Pelagic & Demersal & Other & Saturated FE \\\\\n")
cat("\\hline\n")
cat(sprintf("Post $\\times$ EU & %s & %s & %s & %s & %s \\\\\n",
            format_coef(main_coef, main_se, main_pval),
            format_coef(pel_coef, pel_se, pel_pval),
            format_coef(dem_coef, dem_se, dem_pval),
            format_coef(oth_coef, oth_se, oth_pval),
            format_coef(sat_coef, sat_se, pvalue(results$twfe_sat)["post"])))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            main_se, pel_se, dem_se, oth_se, sat_se))
cat("\\hline\n")
cat(sprintf("Unit FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & Yes & Yes & Yes & --- \\\\\n"))
cat(sprintf("Country $\\times$ Year FE & --- & --- & --- & --- & Yes \\\\\n"))
cat(sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
            nobs(results$twfe_catch), nobs(results$twfe_pelagic),
            nobs(results$twfe_demersal), nobs(results$twfe_other),
            nobs(results$twfe_sat)))
cat(sprintf("$R^2$ (within) & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
            fitstat(results$twfe_catch, "wr2")$wr2,
            fitstat(results$twfe_pelagic, "wr2")$wr2,
            fitstat(results$twfe_demersal, "wr2")$wr2,
            fitstat(results$twfe_other, "wr2")$wr2,
            fitstat(results$twfe_sat, "wr2")$wr2))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Dependent variable is log total catches (tonnes) at the country $\\times$ species group $\\times$ year level. ")
cat("``Post $\\times$ EU'' equals one for EU member states in years after their species group's Landing Obligation activation ")
cat("(pelagic: 2015; demersal: 2016; other: 2019). Column (5) replaces year fixed effects with country $\\times$ year fixed effects, ")
cat("identifying from within-country across-species-group variation only (EU countries only). ")
cat("Standard errors clustered by country in parentheses. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab2_main.tex written\n")

# ======================================================================
# TABLE 3: Robustness — Placebo, DDD, Levels
# ======================================================================
cat("\n--- Table 3: Robustness ---\n")

plac_coef <- coef(rob$placebo_fit)["placebo_post"]
plac_se <- se(rob$placebo_fit)["placebo_post"]
plac_pval <- pvalue(rob$placebo_fit)["placebo_post"]

levels_coef <- coef(rob$twfe_levels)["post"]
levels_se <- se(rob$twfe_levels)["post"]
levels_pval <- pvalue(rob$twfe_levels)["post"]

ddd_coef <- coef(rob$ddd_fit)["is_euTRUE:is_demersal:post_2016"]
ddd_se <- se(rob$ddd_fit)["is_euTRUE:is_demersal:post_2016"]
ddd_pval <- pvalue(rob$ddd_fit)["is_euTRUE:is_demersal:post_2016"]

# Non-EU placebo from main results
noneu_coef <- coef(results$placebo_reg)["pseudo_post"]
noneu_se <- se(results$placebo_reg)["pseudo_post"]
noneu_pval <- pvalue(results$placebo_reg)["pseudo_post"]

sink("../tables/tab3_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat(" & Placebo 2012 & Non-EU Placebo & DDD & Levels \\\\\n")
cat(" & (Demersal, pre-LO) & (Norway, Iceland) & (EU $\\times$ Dem. $\\times$ Post) & (Tonnes) \\\\\n")
cat("\\hline\n")
cat(sprintf("Treatment & %s & %s & %s & %s \\\\\n",
            format_coef(plac_coef, plac_se, plac_pval),
            format_coef(noneu_coef, noneu_se, noneu_pval),
            format_coef(ddd_coef, ddd_se, ddd_pval),
            sprintf("$-$%s%s", formatC(abs(levels_coef), format = "d", big.mark = ","), stars(levels_pval))))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%s) \\\\\n",
            plac_se, noneu_se, ddd_se,
            formatC(round(levels_se), format = "d", big.mark = ",")))
cat("\\hline\n")
cat(sprintf("Observations & %d & %d & %d & %d \\\\\n",
            nobs(rob$placebo_fit), nobs(results$placebo_reg),
            nobs(rob$ddd_fit), nobs(rob$twfe_levels)))
cat(sprintf("Sample & Demersal & Non-EU & Pelagic + & Demersal \\\\\n"))
cat(sprintf("       & pre-2016 & all years & Demersal & all years \\\\\n"))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Column (1) assigns placebo treatment at 2012 using only demersal data from 2000--2015 (before actual LO). ")
cat("Column (2) applies the EU treatment timing to non-EU countries (Norway, Iceland) fishing the same ICES Area 27 waters. ")
cat("Column (3) estimates a triple difference: EU membership $\\times$ demersal species group $\\times$ post-2016. ")
cat("Column (4) reports the TWFE estimate in levels (tonnes) for demersal species. ")
cat("All specifications include unit and year fixed effects. Standard errors clustered by country. ")
cat("$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab3_robustness.tex written\n")

# ======================================================================
# TABLE 4: Leave-One-Country-Out
# ======================================================================
cat("\n--- Table 4: Leave-One-Out ---\n")

loo <- rob$loo_results %>% arrange(coef)

sink("../tables/tab4_loo.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Leave-One-Country-Out: Demersal Catches}\n")
cat("\\label{tab:loo}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat("Dropped Country & Coefficient & Std. Error & $p$-value & Sig. \\\\\n")
cat("\\hline\n")
for (i in 1:nrow(loo)) {
  row <- loo[i, ]
  cat(sprintf("%s & %.3f & %.3f & %.3f & %s \\\\\n",
              row$dropped, row$coef, row$se, row$pval, stars(row$pval)))
}
cat("\\hline\n")
cat(sprintf("Full sample & %.3f & %.3f & %.3f & %s \\\\\n",
            dem_coef, dem_se, dem_pval, stars(dem_pval)))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Each row drops one EU country and re-estimates the TWFE specification from Table~\\ref{tab:main}, Column (3). ")
cat("Dependent variable is log demersal catches. All estimates include unit and year fixed effects, clustered by country. ")
cat("All 15 coefficients remain negative, ranging from $-1.342$ to $-0.859$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tab4_loo.tex written\n")

# ======================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ======================================================================
cat("\n--- Table F1: SDE Appendix ---\n")

# Compute SDE for main outcomes
panel_dem <- panel %>% filter(treatment_group == "demersal")
panel_pel <- panel %>% filter(treatment_group == "pelagic")
panel_oth <- panel %>% filter(treatment_group == "other")

# Pre-treatment SD for each outcome
sd_dem_pre <- sd(panel_dem$log_catch[panel_dem$year < 2016], na.rm = TRUE)
sd_pel_pre <- sd(panel_pel$log_catch[panel_pel$year < 2015], na.rm = TRUE)
sd_oth_pre <- sd(panel_oth$log_catch[panel_oth$year < 2019], na.rm = TRUE)
sd_all_pre <- sd(panel$log_catch[panel$year < 2015], na.rm = TRUE)

# SDE = beta / SD(Y)
sde_all <- main_coef / sd_all_pre
sde_all_se <- main_se / sd_all_pre
sde_dem <- dem_coef / sd_dem_pre
sde_dem_se <- dem_se / sd_dem_pre
sde_pel <- pel_coef / sd_pel_pre
sde_pel_se <- pel_se / sd_pel_pre
sde_oth <- oth_coef / sd_oth_pre
sde_oth_se <- oth_se / sd_oth_pre

# DDD SDE
sd_ddd_pre <- sd(panel$log_catch[panel$treatment_group %in% c("pelagic", "demersal") & panel$year < 2016], na.rm = TRUE)
sde_ddd <- ddd_coef / sd_ddd_pre
sde_ddd_se <- ddd_se / sd_ddd_pre

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Build SDE table
sde_rows <- data.frame(
  outcome = c("Log catches (all)", "Log catches (demersal)", "Log catches (pelagic)",
              "Log catches (other)", "DDD (EU $\\times$ demersal $\\times$ post)"),
  beta = c(main_coef, dem_coef, pel_coef, oth_coef, ddd_coef),
  se_beta = c(main_se, dem_se, pel_se, oth_se, ddd_se),
  sd_y = c(sd_all_pre, sd_dem_pre, sd_pel_pre, sd_oth_pre, sd_ddd_pre),
  sde = c(sde_all, sde_dem, sde_pel, sde_oth, sde_ddd),
  se_sde = c(sde_all_se, sde_dem_se, sde_pel_se, sde_oth_se, sde_ddd_se),
  stringsAsFactors = FALSE
) %>%
  mutate(classification = sapply(sde, classify))

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (15 member states with significant Atlantic fisheries: ",
  "BE, DE, DK, EE, ES, FI, FR, IE, LT, LV, NL, PL, PT, SE, UK). ",
  "\\textbf{Research question:} Does the EU Landing Obligation (discard ban) reduce total catches through ",
  "choke-species constraints in mixed fisheries, and does this effect differ between single-species pelagic ",
  "and mixed demersal fisheries? ",
  "\\textbf{Policy mechanism:} The Landing Obligation (Regulation 1380/2013, Article 15) requires all catches of ",
  "regulated species to be landed and counted against quotas, replacing the prior practice of discarding unwanted ",
  "fish at sea; in mixed demersal fisheries, low-quota bycatch species become binding constraints that force vessels ",
  "to stop fishing before exhausting target-species quotas (the ``choke species'' problem). ",
  "\\textbf{Outcome definition:} Log total catches (tonnes) by country $\\times$ species group $\\times$ year, ",
  "from Eurostat fish\\_ca\\_main. ",
  "\\textbf{Treatment:} Binary; Landing Obligation activation staggered by species group (pelagic 2015, demersal 2016, ",
  "other 2019). ",
  "\\textbf{Data:} Eurostat fisheries statistics (fish\\_ca\\_main), 2000--2024, country $\\times$ species group $\\times$ ",
  "year; 1,252 observations across 51 units (45 treated EU, 6 non-EU control). ",
  "\\textbf{Method:} TWFE with unit and year fixed effects; triple-difference (EU $\\times$ demersal $\\times$ post) ",
  "for mechanism test; standard errors clustered by country. ",
  "\\textbf{Sample:} EU member states with Atlantic fisheries plus Norway and Iceland as controls; ",
  "species classified into Landing Obligation treatment cohorts based on phased implementation schedule. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("\\multicolumn{7}{l}{\\textbf{Panel A: Pooled}} \\\\\n")
cat("\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
for (i in c(1, 5)) {
  row <- sde_rows[i, ]
  cat(sprintf("%s & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
              row$outcome, row$beta, row$se_beta, row$sd_y,
              row$sde, row$se_sde, row$classification))
}
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textbf{Panel B: Heterogeneous (by species group)}} \\\\\n")
cat("\\hline\n")
for (i in c(2, 3)) {
  row <- sde_rows[i, ]
  cat(sprintf("%s & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\\n",
              row$outcome, row$beta, row$se_beta, row$sd_y,
              row$sde, row$se_sde, row$classification))
}
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()
cat("  tabF1_sde.tex written\n")

cat("\n=== All tables generated ===\n")
