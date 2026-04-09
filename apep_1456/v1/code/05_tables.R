# 05_tables.R — Generate all LaTeX tables
# APEP 1456: DPA Enforcement Intensity and Startup Survival

source("00_packages.R")

cat("=== Generating tables for APEP 1456 ===\n")

results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robust_results.rds")
ict_panel <- readRDS("../data/ict_panel.rds")
construction_panel <- readRDS("../data/construction_panel.rds")
enforcement_panel <- readRDS("../data/enforcement_panel.rds")
first_enforcement <- readRDS("../data/first_enforcement.rds")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("Generating Table 1: Summary Statistics...\n")

# Pre-period stats (2014-2017) for ICT
pre_ict <- ict_panel %>%
  filter(year >= 2014, year <= 2017)

# Split by early vs late enforcers
early_geos <- first_enforcement %>% filter(first_fine_year <= 2019) %>% pull(geo)
late_geos <- first_enforcement %>% filter(first_fine_year > 2019 | is.na(first_fine_year)) %>% pull(geo)
# Include never-treated in late
late_geos <- c(late_geos, setdiff(
  unique(ict_panel$geo),
  c(early_geos, first_enforcement$geo)
))

compute_stats <- function(data, varname) {
  vals <- data[[varname]]
  vals <- vals[!is.na(vals)]
  c(mean = mean(vals), sd = sd(vals), n = length(vals))
}

vars_of_interest <- c("surv_1yr", "birth_rate", "avg_size_births", "surv_3yr")
var_labels <- c("1-year survival rate (\\%)", "Enterprise birth rate (\\%)",
                "Avg. employees at birth", "3-year survival rate (\\%)")

# Build table rows
rows <- list()
for (i in seq_along(vars_of_interest)) {
  v <- vars_of_interest[i]
  all_s <- compute_stats(pre_ict, v)
  early_s <- compute_stats(pre_ict %>% filter(geo %in% early_geos), v)
  late_s <- compute_stats(pre_ict %>% filter(geo %in% late_geos), v)

  rows[[i]] <- sprintf(
    "%s & %.2f & (%.2f) & %.2f & (%.2f) & %.2f & (%.2f) \\\\",
    var_labels[i],
    all_s["mean"], all_s["sd"],
    early_s["mean"], early_s["sd"],
    late_s["mean"], late_s["sd"]
  )
}

# Add enforcement stats
enf_stats_early <- enforcement_panel %>%
  filter(geo %in% early_geos, year >= 2018, year <= 2021) %>%
  summarise(mean_fines = mean(n_fines), sd_fines = sd(n_fines))
enf_stats_late <- enforcement_panel %>%
  filter(geo %in% late_geos, year >= 2018, year <= 2021) %>%
  summarise(mean_fines = mean(n_fines), sd_fines = sd(n_fines))

n_early <- length(early_geos)
n_late <- length(late_geos)

tab1 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: ICT Sector Business Demography, Pre-Enforcement Period (2014--2017)}\n",
  "\\label{tab:sumstats}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{All EU} & \\multicolumn{2}{c}{Early Enforcers} & \\multicolumn{2}{c}{Late Enforcers} \\\\\n",
  " & Mean & (SD) & Mean & (SD) & Mean & (SD) \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: ICT Startup Outcomes}} \\\\\n",
  paste(rows, collapse = "\n"), "\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Enforcement Intensity (2018--2021)}} \\\\\n",
  sprintf("Annual GDPR fines & & & %.1f & (%.1f) & %.1f & (%.1f) \\\\",
          enf_stats_early$mean_fines, enf_stats_early$sd_fines,
          enf_stats_late$mean_fines, enf_stats_late$sd_fines), "\n",
  sprintf("Countries & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          n_early + n_late, n_early, n_late), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Eurostat business demography (\\texttt{bd\\_9bd\\_sz\\_cl\\_r2}), NACE J (Information and Communication). ",
  "Early enforcers issued their first GDPR fine by end of 2019; late enforcers began enforcement in 2020 or later. ",
  "Panel A reports pre-enforcement means and standard deviations for the four ICT startup outcomes. ",
  "Panel B reports post-GDPR enforcement intensity.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# ---------------------------------------------------------------
# Table 2: Main Results — TWFE and CS-DiD
# ---------------------------------------------------------------
cat("Generating Table 2: Main Results...\n")

# Extract CS-DiD ATTs
cs_att_surv <- results$agg_surv1$overall.att
cs_se_surv <- results$agg_surv1$overall.se
cs_att_birth <- results$agg_birth$overall.att
cs_se_birth <- results$agg_birth$overall.se
cs_att_size <- results$agg_size$overall.att
cs_se_size <- results$agg_size$overall.se

# TWFE coefficients
twfe_coefs <- function(model) {
  cf <- coef(model)
  se <- sqrt(diag(vcov(model, type = "cluster")))
  list(beta = cf[1], se = se[1])
}

tw1 <- twfe_coefs(results$twfe$m1)
tw2 <- twfe_coefs(results$twfe$m2)
tw4 <- twfe_coefs(results$twfe$m4)
tw5 <- twfe_coefs(results$twfe$m5)
tw6 <- twfe_coefs(results$twfe$m6)

stars <- function(beta, se) {
  p <- 2 * pnorm(-abs(beta / se))
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

fmt <- function(x) formatC(x, format = "f", digits = 3)

tab2 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of DPA Enforcement on ICT Startup Outcomes}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{1-Year Survival} & \\multicolumn{2}{c}{Birth Rate} & \\multicolumn{2}{c}{Avg. Size} \\\\\n",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Two-Way Fixed Effects}} \\\\\n",
  sprintf("Post-enforcement & %s%s & %s%s & %s%s & %s%s & %s%s & \\\\",
          fmt(tw1$beta), stars(tw1$beta, tw1$se),
          fmt(tw2$beta), stars(tw2$beta, tw2$se),
          fmt(tw4$beta), stars(tw4$beta, tw4$se),
          fmt(tw5$beta), stars(tw5$beta, tw5$se),
          fmt(tw6$beta), stars(tw6$beta, tw6$se)), "\n",
  sprintf(" & (%s) & (%s) & (%s) & (%s) & (%s) & \\\\",
          fmt(tw1$se), fmt(tw2$se), fmt(tw4$se), fmt(tw5$se), fmt(tw6$se)), "\n",
  "Controls & No & Yes & No & Yes & No & \\\\\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Callaway--Sant'Anna}} \\\\\n",
  sprintf("ATT & %s%s & & %s%s & & %s%s & \\\\",
          fmt(cs_att_surv), stars(cs_att_surv, cs_se_surv),
          fmt(cs_att_birth), stars(cs_att_birth, cs_se_birth),
          fmt(cs_att_size), stars(cs_att_size, cs_se_size)), "\n",
  sprintf(" & (%s) & & (%s) & & (%s) & \\\\",
          fmt(cs_se_surv), fmt(cs_se_birth), fmt(cs_se_size)), "\n",
  "\\hline\n",
  sprintf("Country FE & Yes & Yes & Yes & Yes & Yes & \\\\\n"),
  sprintf("Year FE & Yes & Yes & Yes & Yes & Yes & \\\\\n"),
  sprintf("Observations & %d & %d & %d & %d & %d & \\\\\n",
          nobs(results$twfe$m1), nobs(results$twfe$m2),
          nobs(results$twfe$m4), nobs(results$twfe$m5),
          nobs(results$twfe$m6)), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} The dependent variable is indicated in the column header. ",
  "Post-enforcement is a binary indicator equal to one from the year a country's DPA issued its first GDPR fine. ",
  "Panel A reports TWFE estimates with country and year fixed effects; standard errors clustered by country in parentheses. ",
  "Panel B reports Callaway--Sant'Anna (2021) ATT estimates using not-yet-treated or never-treated controls. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ---------------------------------------------------------------
# Table 3: Robustness
# ---------------------------------------------------------------
cat("Generating Table 3: Robustness...\n")

rb_placebo <- twfe_coefs(robust$placebo_surv)
rb_nocovid <- twfe_coefs(robust$nocovid_surv)
rb_cont <- twfe_coefs(robust$cont_surv)

# Pre-placebo
if (!is.null(robust$preplacebo_surv)) {
  rb_preplacebo <- twfe_coefs(robust$preplacebo_surv)
} else {
  rb_preplacebo <- list(beta = NA, se = NA)
}

# 3-year survival
if (!is.null(robust$surv3_model)) {
  rb_surv3 <- twfe_coefs(robust$surv3_model)
} else {
  rb_surv3 <- list(beta = NA, se = NA)
}

tab3 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robust}\n",
  "\\begin{tabular}{lcc}\n",
  "\\hline\\hline\n",
  " & Coefficient & SE \\\\\n",
  "\\hline\n",
  sprintf("\\textit{Baseline (ICT, 1-yr survival)} & %s%s & (%s) \\\\",
          fmt(tw1$beta), stars(tw1$beta, tw1$se), fmt(tw1$se)), "\n",
  sprintf("\\textit{Placebo: Construction sector} & %s%s & (%s) \\\\",
          fmt(rb_placebo$beta), stars(rb_placebo$beta, rb_placebo$se),
          fmt(rb_placebo$se)), "\n",
  sprintf("\\textit{Excluding 2020 (COVID)} & %s%s & (%s) \\\\",
          fmt(rb_nocovid$beta), stars(rb_nocovid$beta, rb_nocovid$se),
          fmt(rb_nocovid$se)), "\n",
  ifelse(!is.na(rb_preplacebo$beta),
         sprintf("\\textit{Pre-2018 placebo (fake 2016)} & %s%s & (%s) \\\\",
                 fmt(rb_preplacebo$beta), stars(rb_preplacebo$beta, rb_preplacebo$se),
                 fmt(rb_preplacebo$se)),
         "\\textit{Pre-2018 placebo (fake 2016)} & --- & --- \\\\"), "\n",
  sprintf("\\textit{Continuous: cum. fines/GDP} & %s%s & (%s) \\\\",
          fmt(rb_cont$beta), stars(rb_cont$beta, rb_cont$se),
          fmt(rb_cont$se)), "\n",
  ifelse(!is.na(rb_surv3$beta),
         sprintf("\\textit{3-year survival rate} & %s%s & (%s) \\\\",
                 fmt(rb_surv3$beta), stars(rb_surv3$beta, rb_surv3$se),
                 fmt(rb_surv3$se)),
         "\\textit{3-year survival rate} & --- & --- \\\\"), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on the enforcement indicator from a separate TWFE regression with country and year fixed effects. ",
  "Standard errors clustered by country in parentheses. ",
  "The placebo uses Construction (NACE F) as the dependent sector. ",
  "The pre-2018 placebo assigns enforcement groups their actual cohort but shifts treatment to 2016. ",
  "Continuous treatment uses cumulative fines per billion EUR GDP. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robust.tex")

# ---------------------------------------------------------------
# Table 4: Mechanism — Selection vs Chilling
# ---------------------------------------------------------------
cat("Generating Table 4: Mechanism...\n")

# The mechanism table shows birth rate, survival, and size together
# to distinguish selection from chilling
tab4 <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Mechanism Test: Selection vs.\\ Chilling Effect}\n",
  "\\label{tab:mechanism}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Birth Rate & 1-Year Survival & Avg.\\ Size at Birth \\\\\n",
  " & (1) & (2) & (3) \\\\\n",
  "\\hline\n",
  sprintf("Post-enforcement & %s%s & %s%s & %s%s \\\\",
          fmt(tw4$beta), stars(tw4$beta, tw4$se),
          fmt(tw1$beta), stars(tw1$beta, tw1$se),
          fmt(tw6$beta), stars(tw6$beta, tw6$se)), "\n",
  sprintf(" & (%s) & (%s) & (%s) \\\\",
          fmt(tw4$se), fmt(tw1$se), fmt(tw6$se)), "\n",
  "\\hline\n",
  sprintf("Pre-enforcement mean & %.2f & %.2f & %.2f \\\\",
          results$pre_stats$mean_birth_rate,
          results$pre_stats$mean_surv_1yr,
          results$pre_stats$mean_avg_size), "\n",
  sprintf("Country FE & Yes & Yes & Yes \\\\\n"),
  sprintf("Year FE & Yes & Yes & Yes \\\\\n"),
  sprintf("Observations & %d & %d & %d \\\\",
          nobs(results$twfe$m4), nobs(results$twfe$m1),
          nobs(results$twfe$m6)), "\n",
  "\\hline\n",
  "\\multicolumn{4}{l}{\\textit{Interpretation:}} \\\\\n",
  "\\multicolumn{4}{l}{Selection: Birth $\\downarrow$, Survival $\\uparrow$, Size $\\uparrow$} \\\\\n",
  "\\multicolumn{4}{l}{Chilling: Birth $\\downarrow$, Survival $\\downarrow$, Size $\\downarrow$ or $=$} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} This table tests between two mechanisms through which DPA enforcement could affect the ICT startup ecosystem. ",
  "Under the selection hypothesis, enforcement raises the compliance bar, deterring marginal entrants while improving survivor quality. ",
  "Under the chilling hypothesis, enforcement suppresses entry without improving outcomes for survivors. ",
  "All specifications include country and year fixed effects with standard errors clustered by country. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_mechanism.tex")

# ---------------------------------------------------------------
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# ---------------------------------------------------------------
cat("Generating Table F1: SDE...\n")

# Compute SDE for main outcomes
# SDE = beta / SD(Y_pre)
compute_sde <- function(beta, se, sd_y) {
  sde <- beta / sd_y
  se_sde <- se / sd_y
  bucket <- case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde <= 0.005 ~ "Null",
    sde <= 0.05 ~ "Small positive",
    sde <= 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
  list(sde = sde, se_sde = se_sde, bucket = bucket)
}

# Pre-treatment SDs
sd_surv <- results$pre_stats$sd_surv_1yr
sd_birth <- results$pre_stats$sd_birth_rate
sd_size <- results$pre_stats$sd_avg_size

sde_surv <- compute_sde(tw1$beta, tw1$se, sd_surv)
sde_birth <- compute_sde(tw4$beta, tw4$se, sd_birth)
sde_size <- compute_sde(tw6$beta, tw6$se, sd_size)

# Panel B: Heterogeneous — early vs late enforcers
# Rerun for early enforcers only
early_data <- ict_panel %>%
  filter(year >= 2014, year <= 2021, !is.na(surv_1yr),
         geo %in% early_geos | first_fine_year >= 9999L)

if (nrow(early_data) > 20) {
  m_early_surv <- feols(surv_1yr ~ post_enforcement | geo + year,
                        data = early_data, cluster = ~geo)
  early_coef <- twfe_coefs(m_early_surv)
  sde_early_surv <- compute_sde(early_coef$beta, early_coef$se, sd_surv)
} else {
  sde_early_surv <- list(sde = NA, se_sde = NA, bucket = "---")
  early_coef <- list(beta = NA, se = NA)
}

# Late enforcers
late_data <- ict_panel %>%
  filter(year >= 2014, year <= 2021, !is.na(surv_1yr),
         geo %in% late_geos | first_fine_year >= 9999L)

if (nrow(late_data) > 20) {
  m_late_surv <- feols(surv_1yr ~ post_enforcement | geo + year,
                       data = late_data, cluster = ~geo)
  late_coef <- twfe_coefs(m_late_surv)
  sde_late_surv <- compute_sde(late_coef$beta, late_coef$se, sd_surv)
} else {
  sde_late_surv <- list(sde = NA, se_sde = NA, bucket = "---")
  late_coef <- list(beta = NA, se = NA)
}

fmt2 <- function(x) ifelse(is.na(x), "---", formatC(x, format = "f", digits = 3))

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states). ",
  "\\textbf{Research question:} Does the intensity of GDPR enforcement by national Data Protection Authorities affect ICT startup survival rates? ",
  "\\textbf{Policy mechanism:} GDPR mandates identical data protection obligations across all EU members, but national DPAs enforce with vastly different intensity---Spain issued 594 fines by 2023 while Ireland issued 6---creating within-EU variation in de facto regulatory burden on data-intensive firms. ",
  "\\textbf{Outcome definition:} One-year survival rate from Eurostat business demography (bd\\_9bd\\_sz\\_cl\\_r2, indicator V97041), measuring the share of newly born ICT enterprises (NACE J) surviving at least one year. ",
  "\\textbf{Treatment:} Binary indicator equal to one from the year a country's DPA issued its first GDPR fine. ",
  "\\textbf{Data:} Eurostat business demography and GDPR Enforcement Tracker, 2014--2021, country-year panel. ",
  sprintf("\\textbf{Method:} TWFE with country and year fixed effects, standard errors clustered by country; Panel B splits by enforcement cohort timing (early: first fine by 2019, N=%d countries; late: first fine 2020+, N=%d countries). ", n_early, n_late),
  sprintf("\\textbf{Sample:} 27 EU member states, %d country-year observations; restricted to years with non-missing Eurostat business demography data. ", nobs(results$twfe$m1)),
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2014--2017) ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
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
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("1-year survival & %s & %s & %s & %s & %s & %s \\\\",
          fmt2(tw1$beta), fmt2(tw1$se), fmt2(sd_surv),
          fmt2(sde_surv$sde), fmt2(sde_surv$se_sde), sde_surv$bucket), "\n",
  sprintf("Birth rate & %s & %s & %s & %s & %s & %s \\\\",
          fmt2(tw4$beta), fmt2(tw4$se), fmt2(sd_birth),
          fmt2(sde_birth$sde), fmt2(sde_birth$se_sde), sde_birth$bucket), "\n",
  sprintf("Avg.\\ size at birth & %s & %s & %s & %s & %s & %s \\\\",
          fmt2(tw6$beta), fmt2(tw6$se), fmt2(sd_size),
          fmt2(sde_size$sde), fmt2(sde_size$se_sde), sde_size$bucket), "\n",
  "\\hline\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by enforcement cohort)}} \\\\\n",
  sprintf("1-yr surv.\\ (early enforcers) & %s & %s & %s & %s & %s & %s \\\\",
          fmt2(early_coef$beta), fmt2(early_coef$se), fmt2(sd_surv),
          fmt2(sde_early_surv$sde), fmt2(sde_early_surv$se_sde), sde_early_surv$bucket), "\n",
  sprintf("1-yr surv.\\ (late enforcers) & %s & %s & %s & %s & %s & %s \\\\",
          fmt2(late_coef$beta), fmt2(late_coef$se), fmt2(sd_surv),
          fmt2(sde_late_surv$sde), fmt2(sde_late_surv$se_sde), sde_late_surv$bucket), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("=== All tables generated ===\n")
