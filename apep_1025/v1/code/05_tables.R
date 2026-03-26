## 05_tables.R — Generate all tables for paper
## apep_1025: Residential Neonicotinoid Bans and Bird Populations

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("Generating Table 1: Summary Statistics\n")

## Pre-treatment period (2000-2015)
pre <- panel[Year <= 2015]

## Compute stats by diet guild and treatment status
sum_stats <- pre[, .(
  `Mean Abundance` = sprintf("%.1f", mean(total_count)),
  `SD Abundance` = sprintf("%.1f", sd(total_count)),
  `Mean Species` = sprintf("%.1f", mean(n_species)),
  `SD Species` = sprintf("%.1f", sd(n_species)),
  `Routes` = as.character(uniqueN(route_id)),
  `Route-Years` = formatC(as.integer(.N), format = "d", big.mark = ",")
), by = .(diet_guild, Group = fifelse(treat_year > 0, "Treated", "Control"))]

setorder(sum_stats, diet_guild, -Group)

## Build LaTeX table manually for full control
tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Pre-Treatment Period (2000--2015)}",
  "\\label{tab:summary}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  " & & \\multicolumn{2}{c}{Bird Abundance} & \\multicolumn{2}{c}{Species Richness} & & \\\\",
  "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}",
  "Guild & Group & Mean & SD & Mean & SD & Routes & Route-Years \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i]
  guild_label <- fifelse(row$diet_guild == "insectivore", "Insectivore", "Non-insectivore")
  if (i %in% c(3)) guild_label <- ""  ## Suppress repeated guild labels
  if (i == 2) guild_label <- ""
  if (i == 1) guild_label <- "Insectivore"
  if (i == 3) guild_label <- "Non-insectivore"
  tab1 <- c(tab1, sprintf("%s & %s & %s & %s & %s & %s & %s & %s \\\\",
    guild_label, row$Group,
    row$`Mean Abundance`, row$`SD Abundance`,
    row$`Mean Species`, row$`SD Species`,
    row$Routes, row$`Route-Years`))
  if (i == 2) tab1 <- c(tab1, "\\midrule")
}

tab1 <- c(tab1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Pre-treatment summary statistics for BBS routes surveyed 2000--2015. Treated routes are in states that enacted consumer neonicotinoid restrictions by 2021. Bird abundance is the total count across 50 stops per route. Species richness is the number of unique species observed. Insectivores include Passeriformes (excluding Fringillidae, Corvidae, Cardinalidae, Icteridae, Passeridae), Piciformes, Caprimulgiformes, Cuculiformes. Non-insectivores include Anseriformes, Accipitriformes, Falconiformes, Strigiformes, Columbiformes, Galliformes, Charadriiformes, Pelecaniformes, and granivorous passerine families.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

## ============================================================
## Table 2: Treatment Cohorts
## ============================================================
cat("Generating Table 2: Treatment Cohorts\n")

cohort_info <- data.table(
  State = c("Maryland", "Connecticut", "Maine", "Vermont", "Massachusetts",
            "New Jersey", "New York", "Rhode Island", "Colorado", "Nevada",
            "California", "Washington"),
  Abbreviation = c("MD", "CT", "ME", "VT", "MA", "NJ", "NY", "RI", "CO", "NV", "CA", "WA"),
  Year = c(2016, 2016, 2018, 2019, 2021, 2022, 2022, 2022, 2023, 2023, 2024, 2024),
  Type = c("Ban", "Ban", "Ban", "Ban", "Ban", "Ban", "Ban+Ag", "Ban", "Ban", "Ban", "Ban", "Ban")
)

## Count routes per state from actual data
route_counts <- panel[treat_year > 0 & diet_guild == "insectivore",
                       .(Routes = uniqueN(route_id)),
                       by = .(state_abbr, treat_year)]
cohort_info <- merge(cohort_info, route_counts,
                     by.x = c("Abbreviation", "Year"),
                     by.y = c("state_abbr", "treat_year"), all.x = TRUE)
cohort_info[is.na(Routes), Routes := 0]

## Post-treatment years in data
cohort_info[, `Post Years` := pmax(0, 2021 - Year + 1)]

setorder(cohort_info, Year, State)

tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Consumer Neonicotinoid Restriction Cohorts}",
  "\\label{tab:cohorts}",
  "\\begin{tabular}{llcccl}",
  "\\toprule",
  "State & Year & Routes & Post Years & Restriction Type \\\\",
  "\\midrule"
)

for (i in 1:nrow(cohort_info)) {
  row <- cohort_info[i]
  tab2 <- c(tab2, sprintf("%s & %d & %d & %d & %s \\\\",
    row$State, row$Year, row$Routes, row$`Post Years`, row$Type))
}

tab2 <- c(tab2,
  "\\midrule",
  sprintf("\\textbf{Total} & & \\textbf{%d} & & \\\\",
    sum(cohort_info$Routes)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Consumer neonicotinoid restrictions enacted by U.S.\\ states through 2024. All bans restrict consumer/residential sale and use; agricultural applications are exempt except in New York (seed-treatment ban effective 2029). Post Years indicates the number of years of post-treatment data available in the BBS sample (through 2021). Routes are the number of Breeding Bird Survey routes in each state meeting the sample selection criterion of at least 10 years of observations.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2, file.path(table_dir, "tab2_cohorts.tex"))

## ============================================================
## Table 3: Main Results
## ============================================================
cat("Generating Table 3: Main Results\n")

## Extract coefficients
twfe_i <- results$twfe_insect
twfe_ni <- results$twfe_noninsect
cs_agg <- results$cs_agg
cs_plac <- results$cs_agg_placebo
ddd <- results$ddd

## Build results table
tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of Consumer Neonicotinoid Restrictions on Bird Abundance}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{TWFE} & \\multicolumn{2}{c}{Callaway-Sant'Anna} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Insectivore & Non-insectivore & Insectivore & Non-insectivore \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  sprintf("Treatment & %s & %s & %s & %s \\\\",
    sprintf("%.4f", coef(twfe_i)["treated"]),
    sprintf("%.4f", coef(twfe_ni)["treated"]),
    sprintf("%.4f", cs_agg$overall.att),
    sprintf("%.4f", cs_plac$overall.att)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\",
    sprintf("%.4f", se(twfe_i)["treated"]),
    sprintf("%.4f", se(twfe_ni)["treated"]),
    sprintf("%.4f", cs_agg$overall.se),
    sprintf("%.4f", cs_plac$overall.se)),
  "\\midrule",
  "Route FE & Yes & Yes & --- & --- \\\\",
  "Year FE & Yes & Yes & --- & --- \\\\",
  "Covariates & No & No & Yes & Yes \\\\",
  "Control group & All & All & Not-yet-treated & Not-yet-treated \\\\",
  "Estimator & TWFE & TWFE & DR & DR \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    formatC(nobs(twfe_i), format = "d", big.mark = ","),
    formatC(nobs(twfe_ni), format = "d", big.mark = ","),
    formatC(nobs(twfe_i), format = "d", big.mark = ","),
    formatC(nobs(twfe_ni), format = "d", big.mark = ",")),
  sprintf("Routes & %s & %s & %s & %s \\\\",
    formatC(uniqueN(panel[diet_guild == "insectivore"]$route_id), format = "d", big.mark = ","),
    formatC(uniqueN(panel[diet_guild == "non_insectivore"]$route_id), format = "d", big.mark = ","),
    formatC(uniqueN(panel[diet_guild == "insectivore"]$route_id), format = "d", big.mark = ","),
    formatC(uniqueN(panel[diet_guild == "non_insectivore"]$route_id), format = "d", big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Dependent variable is log(bird abundance $+$ 1) at the route-year level. Treatment equals one for routes in states that have enacted a consumer neonicotinoid restriction, in years at or after the restriction's effective date. Columns (1)--(2) report two-way fixed effects estimates with route and year fixed effects and standard errors clustered at the state level. Columns (3)--(4) report the aggregated group-time average treatment effect on the treated from Callaway and Sant'Anna (2021), using doubly robust estimation with not-yet-treated units as the control group. Covariates in the CS specification include observer experience and weather conditions (temperature, wind). Significance: * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3, file.path(table_dir, "tab3_main.tex"))

## ============================================================
## Table 4: Robustness
## ============================================================
cat("Generating Table 4: Robustness\n")

## Re-estimate Sun-Abraham (need data in scope for model.matrix)
insect_sa <- copy(panel[diet_guild == "insectivore"])
insect_sa[, cohort := fifelse(treat_year == 0, 10000L, as.integer(treat_year))]
sa_i_fit <- feols(log_count ~ sunab(cohort, Year) | route_id + Year,
                  cluster = ~StateNum, data = insect_sa)

noninsect_sa <- copy(panel[diet_guild == "non_insectivore"])
noninsect_sa[, cohort := fifelse(treat_year == 0, 10000L, as.integer(treat_year))]
sa_ni_fit <- feols(log_count ~ sunab(cohort, Year) | route_id + Year,
                   cluster = ~StateNum, data = noninsect_sa)

sa_i_summ <- summary(sa_i_fit, agg = "ATT")
sa_ni_summ <- summary(sa_ni_fit, agg = "ATT")
sa_i_ct <- coeftable(sa_i_summ)
sa_ni_ct <- coeftable(sa_ni_summ)
sa_i_coef <- sa_i_ct["ATT", "Estimate"]
sa_i_se <- sa_i_ct["ATT", "Std. Error"]
sa_i_pval <- sa_i_ct["ATT", "Pr(>|t|)"]
sa_ni_coef <- sa_ni_ct["ATT", "Estimate"]
sa_ni_se <- sa_ni_ct["ATT", "Std. Error"]
sa_ni_pval <- sa_ni_ct["ATT", "Pr(>|t|)"]

## Species richness
rich_i_coef <- coef(rob$richness_insect)["treated"]
rich_i_se <- se(rob$richness_insect)["treated"]
rich_ni_coef <- coef(rob$richness_noninsect)["treated"]
rich_ni_se <- se(rob$richness_noninsect)["treated"]

## Level specification
level_coef <- coef(rob$level_insect)["treated"]
level_se <- se(rob$level_insect)["treated"]

## DDD
ddd_coef <- coef(ddd)["insectivore:treated"]
ddd_se <- se(ddd)["insectivore:treated"]

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Specification & Estimate & SE & $p$-value \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Main outcome (log abundance)}} \\\\[3pt]",
  sprintf("TWFE, insectivore & %.4f & %.4f & %.3f \\\\",
    coef(twfe_i)["treated"], se(twfe_i)["treated"], pvalue(twfe_i)["treated"]),
  sprintf("CS (DR), insectivore & %.4f & %.4f & --- \\\\",
    cs_agg$overall.att, cs_agg$overall.se),
  sprintf("Sun-Abraham, insectivore & %.4f & %.4f & %.3f \\\\",
    sa_i_coef, sa_i_se, sa_i_pval),
  sprintf("Triple-difference & %.4f & %.4f & %.3f \\\\",
    ddd_coef, ddd_se, pvalue(ddd)["insectivore:treated"]),
  "[6pt]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Alternative outcomes}} \\\\[3pt]",
  sprintf("Species richness, insectivore & %.4f & %.4f & %.3f \\\\",
    rich_i_coef, rich_i_se, pvalue(rob$richness_insect)["treated"]),
  sprintf("Species richness, non-insectivore & %.4f & %.4f & %.3f \\\\",
    rich_ni_coef, rich_ni_se, pvalue(rob$richness_noninsect)["treated"]),
  sprintf("Abundance (levels), insectivore & %.1f & %.1f & %.3f \\\\",
    level_coef, level_se, pvalue(rob$level_insect)["treated"]),
  "[6pt]",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo (non-insectivore, log abundance)}} \\\\[3pt]",
  sprintf("TWFE, non-insectivore & %.4f & %.4f & %.3f \\\\",
    coef(twfe_ni)["treated"], se(twfe_ni)["treated"], pvalue(twfe_ni)["treated"]),
  sprintf("CS (DR), non-insectivore & %.4f & %.4f & --- \\\\",
    cs_plac$overall.att, cs_plac$overall.se),
  sprintf("Sun-Abraham, non-insectivore & %.4f & %.4f & %.3f \\\\",
    sa_ni_coef, sa_ni_se, sa_ni_pval),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} All specifications include route and year fixed effects with standard errors clustered at the state level. Log abundance is log(total bird count $+$ 1) at the route-year level. CS (DR) uses the Callaway and Sant'Anna (2021) doubly robust estimator with not-yet-treated controls. Sun-Abraham reports the interaction-weighted ATT following Sun and Abraham (2021). The triple-difference interacts an insectivore indicator with the treatment indicator, absorbing route$\\times$guild and year$\\times$guild fixed effects. Species richness is log(number of unique species $+$ 1). Abundance in levels reports the raw count effect.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4, file.path(table_dir, "tab4_robustness.tex"))

## ============================================================
## Table 5: Leave-One-State-Out
## ============================================================
cat("Generating Table 5: Leave-One-State-Out\n")

loso <- rob$loso

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Leave-One-State-Out: TWFE Sensitivity}",
  "\\label{tab:loso}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "State Dropped & Coefficient & SE & $p$-value \\\\",
  "\\midrule",
  sprintf("None (baseline) & %.4f & %.4f & %.3f \\\\",
    coef(twfe_i)["treated"], se(twfe_i)["treated"], pvalue(twfe_i)["treated"])
)

for (i in 1:nrow(loso)) {
  row <- loso[i]
  tab5 <- c(tab5, sprintf("%s & %.4f & %.4f & %.3f \\\\",
    row$dropped, row$coef, row$se, row$pval))
}

tab5 <- c(tab5,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Each row drops all routes in the indicated state and re-estimates the TWFE specification from Table~\\ref{tab:main}, column (1). Only states with post-treatment observations (effective date $\\leq$ 2021) are jackknifed. Standard errors clustered at the state level.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab5, file.path(table_dir, "tab5_loso.tex"))

## ============================================================
## Table F1: Standardized Effect Sizes (SDE) — Appendix
## ============================================================
cat("Generating Table F1: Standardized Effect Sizes\n")

pre_sd_i <- results$pre_sd_insect
pre_sd_ni <- results$pre_sd_noninsect

## Panel A: Pooled
## Main estimate: CS ATT for insectivore
cs_beta <- cs_agg$overall.att
cs_se <- cs_agg$overall.se
sde_cs <- cs_beta / pre_sd_i
sde_cs_se <- cs_se / pre_sd_i

## TWFE insectivore
twfe_beta <- coef(twfe_i)["treated"]
twfe_se_val <- se(twfe_i)["treated"]
sde_twfe <- twfe_beta / pre_sd_i
sde_twfe_se <- twfe_se_val / pre_sd_i

## Species richness
pre_sd_rich <- panel[Year <= 2015 & diet_guild == "insectivore", sd(log_species)]
rich_beta <- rich_i_coef
rich_se_val <- rich_i_se
sde_rich <- rich_beta / pre_sd_rich
sde_rich_se <- rich_se_val / pre_sd_rich

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

## Panel B: Heterogeneous — early vs late adopters
## Early adopters (2016-2019): MD, CT, ME, VT — have substantial post-treatment data
## Late adopters (2021+): MA, NJ, NY, RI, CO, NV, CA, WA — limited/no post-treatment data
insect_early <- panel[diet_guild == "insectivore" & (treat_year %in% c(2016, 2018, 2019) | treat_year == 0)]
insect_late <- panel[diet_guild == "insectivore" & (treat_year >= 2021 | treat_year == 0)]

twfe_early <- feols(log_count ~ treated | route_id + Year,
                    cluster = ~StateNum, data = insect_early)
twfe_late <- feols(log_count ~ treated | route_id + Year,
                   cluster = ~StateNum, data = insect_late)

pre_sd_early <- insect_early[Year <= 2015, sd(log_count)]
pre_sd_late <- insect_late[Year <= 2015, sd(log_count)]

early_beta <- coef(twfe_early)["treated"]
early_se <- se(twfe_early)["treated"]
sde_early <- early_beta / pre_sd_early
sde_early_se <- early_se / pre_sd_early

late_beta <- coef(twfe_late)["treated"]
late_se <- se(twfe_late)["treated"]
sde_late <- late_beta / pre_sd_late
sde_late_se <- late_se / pre_sd_late

## --- Build SDE table ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do state-level consumer neonicotinoid pesticide restrictions affect insectivorous bird populations along standardized breeding bird survey routes? ",
  "\\textbf{Policy mechanism:} State bans on consumer and residential sale and use of neonicotinoid insecticides, which eliminates residential exposure through lawn and garden applications while agricultural seed treatments and commercial use remain legal. ",
  "\\textbf{Outcome definition:} Log-transformed total abundance of insectivorous bird species counted across 50 standardized roadside stops per BBS route per year. ",
  "\\textbf{Treatment:} Binary indicator equal to one for route-years in states with an active consumer neonicotinoid restriction. ",
  "\\textbf{Data:} USGS North American Breeding Bird Survey, 2000--2021, route-year level, 49,901 observations across 2,932 routes in 49 U.S.\\ states. ",
  "\\textbf{Method:} Two-way fixed effects and Callaway-Sant'Anna (2021) doubly robust estimator with not-yet-treated controls; standard errors clustered at the state level. ",
  "\\textbf{Sample:} U.S.\\ BBS routes observed in at least 10 of 22 years (2000--2021); treatment defined by 12 state-level consumer neonicotinoid restrictions enacted 2016--2024. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lccccccl}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Log abundance (CS) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    cs_beta, cs_se, pre_sd_i, sde_cs, sde_cs_se, classify_sde(sde_cs)),
  sprintf("Log abundance (TWFE) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    twfe_beta, twfe_se_val, pre_sd_i, sde_twfe, sde_twfe_se, classify_sde(sde_twfe)),
  sprintf("Species richness & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    rich_beta, rich_se_val, pre_sd_rich, sde_rich, sde_rich_se, classify_sde(sde_rich)),
  "[6pt]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (TWFE, sample splits)}} \\\\[3pt]",
  sprintf("Early adopters (2016--2019) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    early_beta, early_se, pre_sd_early, sde_early, sde_early_se, classify_sde(sde_early)),
  sprintf("Late adopters (2021+) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    late_beta, late_se, pre_sd_late, sde_late, sde_late_se, classify_sde(sde_late)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables written to", normalizePath(table_dir), "\n")
cat("Files:", paste(list.files(table_dir), collapse = ", "), "\n")
