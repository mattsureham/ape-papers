# =============================================================================
# 05_tables.R — Generate all tables for apep_0779
# =============================================================================

source("00_packages.R")

cat("Loading data and models...\n")
panel <- readRDS("../data/analysis_panel.rds")
main_models <- readRDS("../data/main_models.rds")
robustness <- readRDS("../data/robustness_results.rds")
rob_models <- readRDS("../data/robustness_models.rds")
diagnostics <- jsonlite::read_json("../data/diagnostics.json")

# Ensure tables directory exists
dir.create("../tables", showWarnings = FALSE)

# Helper: format numbers
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)
fmt_int <- function(x) formatC(x, format = "d", big.mark = ",")
stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("Generating Table 1: Summary Statistics...\n")

# Compute summary stats by group
summ <- panel %>%
  group_by(
    Group = case_when(
      female == 1 & young == 1 ~ "Female 25-34",
      female == 1 & young == 0 ~ "Female 45-54",
      female == 0 & young == 1 ~ "Male 25-34",
      female == 0 & young == 0 ~ "Male 45-54"
    )
  ) %>%
  summarise(
    N = n(),
    `Mean Emp` = mean(Emp, na.rm = TRUE),
    `SD Emp` = sd(Emp, na.rm = TRUE),
    `Mean Sep Rate` = mean(sep_rate, na.rm = TRUE),
    `SD Sep Rate` = sd(sep_rate, na.rm = TRUE),
    `Mean Hire Rate` = mean(hire_rate, na.rm = TRUE),
    `SD Hire Rate` = sd(hire_rate, na.rm = TRUE),
    `Mean Earnings` = mean(EarnS, na.rm = TRUE),
    `SD Earnings` = sd(EarnS, na.rm = TRUE),
    .groups = "drop"
  )

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics by Sex and Age Group}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Employment} & \\multicolumn{2}{c}{Sep.\\ Rate} & \\multicolumn{2}{c}{Hire Rate} & \\multicolumn{2}{c}{Earnings (\\$)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}",
  "Group & Mean & SD & Mean & SD & Mean & SD & Mean & SD \\\\"
)

tab1_lines <- c(tab1_lines, "\\midrule")

for (i in 1:nrow(summ)) {
  row <- summ[i, ]
  tab1_lines <- c(tab1_lines, paste0(
    row$Group, " & ",
    fmt_int(round(row$`Mean Emp`)), " & ",
    fmt_int(round(row$`SD Emp`)), " & ",
    fmt(row$`Mean Sep Rate`, 4), " & ",
    fmt(row$`SD Sep Rate`, 4), " & ",
    fmt(row$`Mean Hire Rate`, 4), " & ",
    fmt(row$`SD Hire Rate`, 4), " & ",
    fmt_int(round(row$`Mean Earnings`)), " & ",
    fmt_int(round(row$`SD Earnings`)), " \\\\"
  ))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item Notes: N = ", fmt_int(nrow(panel)),
         " state-quarter-sex-age observations across ",
         length(unique(panel$state_fips)),
         " states, 2000--2022. Employment is beginning-of-quarter count. ",
         "Separation rate = quarterly separations / employment. ",
         "Hire rate = quarterly hires / employment. ",
         "Earnings are average monthly earnings for stable workers. ",
         "Source: Census Quarterly Workforce Indicators (QWI)."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main DDD Results
# =============================================================================
cat("Generating Table 2: Main DDD Results...\n")

m <- main_models
outcomes <- c("Sep.\\ Rate", "Hire Rate", "Log Emp.", "Log Earnings")
models <- list(m$m1_sep, m$m1_hir, m$m1_emp, m$m1_earn)

# Extract coefficients
betas <- sapply(models, function(mod) coef(mod)["ddd"])
ses <- sapply(models, function(mod) se(mod)["ddd"])
pvals <- sapply(models, function(mod) fixest::pvalue(mod)["ddd"])
nobs_v <- sapply(models, nobs)
r2s <- sapply(models, function(mod) fixest::r2(mod, type = "wr2"))

# Also get female_post and young_post
betas_fp <- sapply(models, function(mod) coef(mod)["female_post"])
ses_fp <- sapply(models, function(mod) se(mod)["female_post"])
pvals_fp <- sapply(models, function(mod) fixest::pvalue(mod)["female_post"])

betas_yp <- sapply(models, function(mod) coef(mod)["young_post"])
ses_yp <- sapply(models, function(mod) se(mod)["young_post"])
pvals_yp <- sapply(models, function(mod) fixest::pvalue(mod)["young_post"])

# Mean of dependent variable
dep_means <- c(
  mean(panel$sep_rate, na.rm = TRUE),
  mean(panel$hire_rate, na.rm = TRUE),
  mean(panel$log_emp, na.rm = TRUE),
  mean(panel$log_earn, na.rm = TRUE)
)

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of State Lactation Accommodation Laws on Labor Market Outcomes}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  paste0(" & (1) & (2) & (3) & (4) \\\\"),
  paste0(" & ", paste(outcomes, collapse = " & "), " \\\\"),
  "\\midrule"
)

# DDD row
tab2_lines <- c(tab2_lines,
  paste0("Female $\\times$ Young $\\times$ Post & ",
    paste(sapply(1:4, function(i)
      paste0(fmt(betas[i], 4), stars(pvals[i]))), collapse = " & "),
    " \\\\"),
  paste0(" & ",
    paste(sapply(1:4, function(i)
      paste0("(", fmt(ses[i], 4), ")")), collapse = " & "),
    " \\\\"),
  "[0.5em]"
)

# Female x Post row
tab2_lines <- c(tab2_lines,
  paste0("Female $\\times$ Post & ",
    paste(sapply(1:4, function(i)
      paste0(fmt(betas_fp[i], 4), stars(pvals_fp[i]))), collapse = " & "),
    " \\\\"),
  paste0(" & ",
    paste(sapply(1:4, function(i)
      paste0("(", fmt(ses_fp[i], 4), ")")), collapse = " & "),
    " \\\\"),
  "[0.5em]"
)

# Young x Post row
tab2_lines <- c(tab2_lines,
  paste0("Young $\\times$ Post & ",
    paste(sapply(1:4, function(i)
      paste0(fmt(betas_yp[i], 4), stars(pvals_yp[i]))), collapse = " & "),
    " \\\\"),
  paste0(" & ",
    paste(sapply(1:4, function(i)
      paste0("(", fmt(ses_yp[i], 4), ")")), collapse = " & "),
    " \\\\")
)

tab2_lines <- c(tab2_lines,
  "\\midrule",
  paste0("State $\\times$ Sex $\\times$ Age FE & Yes & Yes & Yes & Yes \\\\"),
  paste0("Sex $\\times$ Age $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\"),
  paste0("State $\\times$ Quarter FE & Yes & Yes & Yes & Yes \\\\"),
  paste0("Mean dep.\\ var.\\ & ",
    paste(sapply(dep_means, function(x) fmt(x, 3)), collapse = " & "), " \\\\"),
  paste0("$R^2$ (within) & ",
    paste(sapply(r2s, function(x) fmt(x, 3)), collapse = " & "), " \\\\"),
  paste0("N & ",
    paste(sapply(nobs_v, fmt_int), collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the state level in parentheses.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "The coefficient of interest is Female $\\times$ Young $\\times$ Post, which captures the",
  "differential effect of state lactation accommodation laws on women of childbearing",
  "age (25--34) relative to men and to older women (45--54).",
  "All specifications include state $\\times$ sex $\\times$ age group,",
  "sex $\\times$ age group $\\times$ quarter, and state $\\times$ quarter fixed effects.",
  paste0("Sample: ", length(unique(panel$state_fips)), " states, 2000Q1--2022Q4, quarterly."),
  "Source: Census QWI.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Placebo Tests
# =============================================================================
cat("Generating Table 3: Placebo Tests...\n")

# Placebo male 25-34
pm_beta <- coef(rob_models$m_placebo_male)["post_treat"]
pm_se <- se(rob_models$m_placebo_male)["post_treat"]
pm_p <- fixest::pvalue(rob_models$m_placebo_male)["post_treat"]
pm_n <- nobs(rob_models$m_placebo_male)

# Placebo female 45-54
pf_beta <- coef(rob_models$m_placebo_female_old)["post_treat"]
pf_se <- se(rob_models$m_placebo_female_old)["post_treat"]
pf_p <- fixest::pvalue(rob_models$m_placebo_female_old)["post_treat"]
pf_n <- nobs(rob_models$m_placebo_female_old)

# Actual female 25-34 DD for comparison
f_young <- panel %>% filter(female == 1, young == 1)
m_actual <- feols(
  sep_rate ~ post_treat | state_fips + t_int,
  data = f_young,
  cluster = ~state_fips
)
fa_beta <- coef(m_actual)["post_treat"]
fa_se <- se(m_actual)["post_treat"]
fa_p <- fixest::pvalue(m_actual)["post_treat"]
fa_n <- nobs(m_actual)

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Tests: Separation Rate}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Female 25--34 & Male 25--34 & Female 45--54 \\\\",
  " & (Treatment) & (Placebo) & (Placebo) \\\\",
  "\\midrule",
  paste0("Post $\\times$ Treated & ",
    fmt(fa_beta, 4), stars(fa_p), " & ",
    fmt(pm_beta, 4), stars(pm_p), " & ",
    fmt(pf_beta, 4), stars(pf_p), " \\\\"),
  paste0(" & (", fmt(fa_se, 4), ") & (", fmt(pm_se, 4), ") & (", fmt(pf_se, 4), ") \\\\"),
  "\\midrule",
  paste0("State FE & Yes & Yes & Yes \\\\"),
  paste0("Quarter FE & Yes & Yes & Yes \\\\"),
  paste0("N & ", fmt_int(fa_n), " & ", fmt_int(pm_n), " & ", fmt_int(pf_n), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the state level in parentheses.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "Column (1) shows the DD estimate for the treatment group (women of childbearing age).",
  "Columns (2) and (3) show placebo tests for groups that should not be affected:",
  "men of the same age, and women past childbearing age.",
  "Null effects on placebo groups support the identifying assumption.",
  "Source: Census QWI.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:placebo}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_placebo.tex")

# =============================================================================
# Table 4: Robustness — Alternative specifications
# =============================================================================
cat("Generating Table 4: Robustness...\n")

# No early adopters
ne_beta <- coef(rob_models$m_no_early)["ddd"]
ne_se <- se(rob_models$m_no_early)["ddd"]
ne_p <- fixest::pvalue(rob_models$m_no_early)["ddd"]
ne_n <- nobs(rob_models$m_no_early)

# Parsimonious DDD
p_beta <- coef(main_models$m2_sep)["ddd"]
p_se <- se(main_models$m2_sep)["ddd"]
p_p <- fixest::pvalue(main_models$m2_sep)["ddd"]
p_n <- nobs(main_models$m2_sep)

# CS ATT
cs_att <- robustness$cs_att
cs_beta <- if (!is.null(cs_att)) cs_att$att else NA
cs_se_val <- if (!is.null(cs_att)) cs_att$se else NA

# Main for comparison
main_beta <- coef(main_models$m1_sep)["ddd"]
main_se <- se(main_models$m1_sep)["ddd"]
main_p <- fixest::pvalue(main_models$m1_sep)["ddd"]
main_n <- nobs(main_models$m1_sep)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Specifications for Separation Rate}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Baseline & Parsimonious & Excl.\\ Early & CS ATT \\\\",
  " & DDD & DDD & Adopters & (F 25--34) \\\\",
  "\\midrule",
  paste0("Treatment effect & ",
    fmt(main_beta, 4), stars(main_p), " & ",
    fmt(p_beta, 4), stars(p_p), " & ",
    fmt(ne_beta, 4), stars(ne_p), " & ",
    ifelse(!is.na(cs_beta), fmt(cs_beta, 4), "---"), " \\\\"),
  paste0(" & (",
    fmt(main_se, 4), ") & (",
    fmt(p_se, 4), ") & (",
    fmt(ne_se, 4), ") & ",
    ifelse(!is.na(cs_se_val), paste0("(", fmt(cs_se_val, 4), ")"), "(---)"), " \\\\"),
  "\\midrule",
  "State $\\times$ Sex $\\times$ Age FE & Yes & No & Yes & --- \\\\",
  "Sex $\\times$ Age $\\times$ Qtr FE & Yes & No & Yes & --- \\\\",
  "State $\\times$ Qtr FE & Yes & No & Yes & --- \\\\",
  "State + Qtr FE & --- & Yes & --- & Yes \\\\",
  paste0("N & ", fmt_int(main_n), " & ", fmt_int(p_n), " & ", fmt_int(ne_n),
    " & ", ifelse(!is.null(cs_att), fmt_int(nrow(panel %>% filter(female == 1, young == 1))), "---"), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Standard errors clustered at the state level in parentheses.",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "Column (1) reproduces the baseline DDD from Table~\\ref{tab:main}.",
  "Column (2) uses a parsimonious specification with state and quarter FE only.",
  "Column (3) excludes states that adopted before 2001 (TX, UT, MN, GA, HI).",
  "Column (4) reports the Callaway and Sant'Anna (2021) ATT for the female 25--34 subsample,",
  "using not-yet-treated states as controls.",
  "Source: Census QWI.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:robust}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robust.tex")

# =============================================================================
# Table 5: Treatment Timing
# =============================================================================
cat("Generating Table 5: Treatment Timing...\n")

treat_laws <- readRDS("../data/treatment_laws.rds")
state_info <- tibble(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56),
  state_name = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

treated <- treat_laws %>%
  filter(!is.na(treat_year)) %>%
  left_join(state_info, by = "state_fips") %>%
  arrange(treat_year) %>%
  mutate(state_display = ifelse(!is.na(state_name), state_name, state_abbr))

# Group by year
year_groups <- treated %>%
  group_by(treat_year) %>%
  summarise(states = paste(state_display, collapse = ", "), n = n(), .groups = "drop")

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{State Lactation Accommodation Law Adoption Timing}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{clc}",
  "\\toprule",
  "Year & States & $N$ \\\\",
  "\\midrule"
)

for (i in 1:nrow(year_groups)) {
  yg <- year_groups[i, ]
  tab5_lines <- c(tab5_lines,
    paste0(yg$treat_year, " & ", yg$states, " & ", yg$n, " \\\\"))
}

tab5_lines <- c(tab5_lines,
  "\\midrule",
  paste0("Total treated & & ", sum(year_groups$n), " \\\\"),
  paste0("Never treated & & ", nrow(treat_laws) - sum(!is.na(treat_laws$treat_year)), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item Notes: Year indicates when the state lactation accommodation law was enacted.",
  "Laws require employers to provide break time and private space for nursing mothers.",
  "Never-treated states had no state-level lactation accommodation law by 2022.",
  "The federal Break Time for Nursing Mothers Act (ACA \\S4207, March 2010) provided a",
  "national floor for hourly workers; state laws typically provide broader coverage.",
  "Sources: National Conference of State Legislatures (NCSL).",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:timing}",
  "\\end{table}"
)

writeLines(tab5_lines, "../tables/tab5_timing.tex")

# =============================================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# =============================================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Extract beta and SE from main models
classify_sde <- function(s) {
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

sde_outcomes <- c("Separation rate", "Hire rate", "Log employment", "Log earnings")
sde_betas <- sapply(models, function(mod) unname(coef(mod)["ddd"]))
sde_ses <- sapply(models, function(mod) unname(se(mod)["ddd"]))
sde_sdy <- c(
  sd(panel$sep_rate, na.rm = TRUE),
  sd(panel$hire_rate, na.rm = TRUE),
  sd(panel$log_emp, na.rm = TRUE),
  sd(panel$log_earn, na.rm = TRUE)
)
sde_vals <- sde_betas / sde_sdy
sde_se_vals <- sde_ses / sde_sdy
sde_class <- classify_sde(sde_vals)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:4) {
  tabF1_lines <- c(tabF1_lines, paste0(
    sde_outcomes[i], " & DDD & ",
    fmt(sde_betas[i], 4), " & --- & ",
    fmt(sde_sdy[i], 4), " & ",
    fmt(sde_vals[i], 4), " & ",
    fmt(sde_se_vals[i], 4), " & ",
    sde_class[i], " \\\\"
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\emph{Notes:} This table reports standardized effect sizes (SDE)",
  "to facilitate cross-study comparison of treatment effect magnitudes.",
  "For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$)",
  "column is marked ``---''.",
  "SD($Y$) is the unconditional standard deviation from the summary",
  "statistics (Table~\\ref{tab:summary}), before conditioning on fixed effects.",
  "",
  "\\textbf{Country:} United States.",
  "\\textbf{Research question:} Whether state lactation accommodation laws reduce maternal separation rates and improve employment retention for women of childbearing age.",
  "\\textbf{Policy mechanism:} State laws require employers to provide reasonable break time and a private, non-bathroom space for nursing mothers to express breast milk during the workday, reducing the conflict between breastfeeding and continued employment.",
  "\\textbf{Outcome definition:} Quarterly separation rate (separations divided by beginning-of-quarter employment), hire rate, log employment, and log earnings from Census QWI administrative records.",
  "\\textbf{Treatment:} Binary indicator for state adoption of a lactation accommodation law (staggered, 1995--2022).",
  paste0("\\textbf{Data:} Census Quarterly Workforce Indicators (QWI), 2000--2022, state-quarter-sex-age group level, N = ", fmt_int(nrow(panel)), "."),
  "\\textbf{Method:} Triple-difference (female vs.\\ male $\\times$ age 25--34 vs.\\ 45--54 $\\times$ post-law) with three-way interacted fixed effects and state-clustered standard errors.",
  paste0("\\textbf{Sample:} ", length(unique(panel$state_fips)), " US states and DC, 2000Q1--2022Q4. Treatment group: women aged 25--34 in states with lactation accommodation laws. Control groups: men (same age), older women (45--54), and never-treated states."),
  "",
  "Classification labels refer to the magnitude of the standardized point estimate,",
  "not to statistical significance. ``Null'' denotes a near-zero effect size",
  "($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated successfully.\n")
cat("Files written to tables/:\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_placebo.tex\n")
cat("  tab4_robust.tex\n")
cat("  tab5_timing.tex\n")
cat("  tabF1_sde.tex\n")
cat("Done.\n")
