# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# Paper: The Admissions Illusion (apep_1113)
# ==============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
summ <- readRDS("../data/summary_stats.rds")

# ==============================================================================
# TABLE 1: Summary Statistics by Selectivity Tier
# ==============================================================================

cat("Generating Table 1: Summary Statistics\n")

# Pre-SFFA means (2019-2022)
tab1_data <- df %>%
  filter(year >= 2019, year <= 2022) %>%
  group_by(selectivity_tier) %>%
  summarise(
    N = n_distinct(unitid),
    `Mean Enrollment` = sprintf("%.0f", mean(total_enroll)),
    `Black (\\%%)` = sprintf("%.1f", mean(black_share, na.rm = TRUE)),
    `Hispanic (\\%%)` = sprintf("%.1f", mean(hispanic_share, na.rm = TRUE)),
    `Asian (\\%%)` = sprintf("%.1f", mean(asian_share, na.rm = TRUE)),
    `White (\\%%)` = sprintf("%.1f", mean(white_share, na.rm = TRUE)),
    `URM (\\%%)` = sprintf("%.1f", mean(urm_share, na.rm = TRUE)),
    `Admit Rate (\\%%)` = sprintf("%.1f", mean(avg_admit_rate)),
    .groups = "drop"
  )

# Add overall row
overall <- df %>%
  filter(year >= 2019, year <= 2022) %>%
  summarise(
    selectivity_tier = "All institutions",
    N = n_distinct(unitid),
    `Mean Enrollment` = sprintf("%.0f", mean(total_enroll)),
    `Black (\\%%)` = sprintf("%.1f", mean(black_share, na.rm = TRUE)),
    `Hispanic (\\%%)` = sprintf("%.1f", mean(hispanic_share, na.rm = TRUE)),
    `Asian (\\%%)` = sprintf("%.1f", mean(asian_share, na.rm = TRUE)),
    `White (\\%%)` = sprintf("%.1f", mean(white_share, na.rm = TRUE)),
    `URM (\\%%)` = sprintf("%.1f", mean(urm_share, na.rm = TRUE)),
    `Admit Rate (\\%%)` = sprintf("%.1f", mean(avg_admit_rate))
  )

tab1_data <- bind_rows(tab1_data, overall)

# Write LaTeX
sink("../tables/tab1_summary.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Pre-SFFA Enrollment Composition by Institutional Selectivity}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrrrr}\n")
cat("\\toprule\n")
cat("Selectivity Tier & N & Enrollment & Black & Hispanic & Asian & White & URM & Admit Rate \\\\\n")
cat(" & & (mean) & (\\%) & (\\%) & (\\%) & (\\%) & (\\%) & (\\%) \\\\\n")
cat("\\midrule\n")
for (i in 1:nrow(tab1_data)) {
  row <- tab1_data[i, ]
  if (i == nrow(tab1_data)) cat("\\midrule\n")
  cat(sprintf("%s & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n",
      as.character(row$selectivity_tier), row$N, row$`Mean Enrollment`,
      row$`Black (\\%%)`, row$`Hispanic (\\%%)`, row$`Asian (\\%%)`,
      row$`White (\\%%)`, row$`URM (\\%%)`, row$`Admit Rate (\\%%)`))
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Pre-SFFA means (2019--2022). URM = Black + Hispanic. Selectivity based on average admission rate. Sample restricted to Title IV degree-granting institutions with $\\geq$100 undergraduate enrollment. Source: IPEDS 12-month enrollment survey.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE 2: Main Results — Continuous Intensity DiD
# ==============================================================================

cat("Generating Table 2: Main Results\n")

sink("../tables/tab2_main.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of SFFA on Enrollment Composition: Continuous Intensity DiD}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & URM & Black & Hispanic & Asian & White \\\\\n")
cat(" & Share & Share & Share & Share & Share \\\\\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("\\midrule\n")

outcomes <- c("urm_share", "black_share", "hispanic_share", "asian_share", "white_share")
betas <- sapply(outcomes, function(y) coef(results$models_main[[y]])[1])
ses <- sapply(outcomes, function(y) se(results$models_main[[y]])[1])
pvals <- sapply(outcomes, function(y) pvalue(results$models_main[[y]])[1])
stars <- ifelse(pvals < 0.01, "***", ifelse(pvals < 0.05, "**", ifelse(pvals < 0.1, "*", "")))

cat(sprintf("Intensity $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
    betas[1], stars[1], betas[2], stars[2], betas[3], stars[3],
    betas[4], stars[4], betas[5], stars[5]))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
    ses[1], ses[2], ses[3], ses[4], ses[5]))

cat("\\midrule\n")
cat(sprintf("Pre-SFFA mean (selective) & %.1f & %.1f & %.1f & %.1f & %.1f \\\\\n",
    mean(df$urm_share[df$selectivity_q >= 3 & df$year <= 2022], na.rm = TRUE),
    mean(df$black_share[df$selectivity_q >= 3 & df$year <= 2022], na.rm = TRUE),
    mean(df$hispanic_share[df$selectivity_q >= 3 & df$year <= 2022], na.rm = TRUE),
    mean(df$asian_share[df$selectivity_q >= 3 & df$year <= 2022], na.rm = TRUE),
    mean(df$white_share[df$selectivity_q >= 3 & df$year <= 2022], na.rm = TRUE)))

n_inst <- n_distinct(df$unitid)
n_obs <- nrow(df)
cat(sprintf("Institution FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Clustered SE (state) & Yes & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Institutions & %s & %s & %s & %s & %s \\\\\n",
    format(n_inst, big.mark = ","), format(n_inst, big.mark = ","),
    format(n_inst, big.mark = ","), format(n_inst, big.mark = ","),
    format(n_inst, big.mark = ",")))
cat(sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
    format(n_obs, big.mark = ","), format(n_obs, big.mark = ","),
    format(n_obs, big.mark = ","), format(n_obs, big.mark = ","),
    format(n_obs, big.mark = ",")))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Each column reports a separate regression of racial enrollment share (percentage points) on the interaction of treatment intensity (1 $-$ pre-SFFA admission rate) and a post-2024 indicator. Institution and year fixed effects included. Standard errors clustered at the state level in parentheses. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE 3: Effect by Selectivity Tier
# ==============================================================================

cat("Generating Table 3: By Selectivity Tier\n")

sink("../tables/tab3_tiers.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{SFFA Effects on URM Enrollment Share by Selectivity Tier}\n")
cat("\\label{tab:tiers}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat(" & Highly Selective & Selective & Moderate & Open Access \\\\\n")
cat(" & ($<$25\\%) & (25--50\\%) & (50--75\\%) & (75\\%+) \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\midrule\n")

tiers <- levels(df$selectivity_tier)
for (tier in tiers) {
  m <- results$models_tier[[tier]]
  if (!is.null(m)) {
    b <- coef(m)[1]; s <- se(m)[1]; p <- pvalue(m)[1]
    star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  } else {
    b <- NA; s <- NA; star <- ""
  }
}

# Re-extract in order
betas_t <- c(); ses_t <- c(); stars_t <- c(); ns_t <- c()
for (tier in tiers) {
  m <- results$models_tier[[tier]]
  if (!is.null(m)) {
    betas_t <- c(betas_t, coef(m)[1])
    ses_t <- c(ses_t, se(m)[1])
    p <- pvalue(m)[1]
    stars_t <- c(stars_t, ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))))
    ns_t <- c(ns_t, m$nobs)
  } else {
    betas_t <- c(betas_t, NA); ses_t <- c(ses_t, NA); stars_t <- c(stars_t, ""); ns_t <- c(ns_t, NA)
  }
}

cat(sprintf("Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\\n",
    betas_t[1], stars_t[1], betas_t[2], stars_t[2],
    betas_t[3], stars_t[3], betas_t[4], stars_t[4]))
cat(sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
    ses_t[1], ses_t[2], ses_t[3], ses_t[4]))

cat("\\midrule\n")

# Pre-SFFA means
for (i in seq_along(tiers)) {
  tier_mean <- mean(df$urm_share[df$selectivity_tier == tiers[i] & df$year <= 2022], na.rm = TRUE)
  if (i == 1) cat(sprintf("Pre-SFFA URM mean & %.1f", tier_mean))
  else cat(sprintf(" & %.1f", tier_mean))
}
cat(" \\\\\n")

cat(sprintf("Institution FE & Yes & Yes & Yes & Yes \\\\\n"))
cat(sprintf("Year FE & Yes & Yes & Yes & Yes \\\\\n"))

for (i in seq_along(tiers)) {
  n <- n_distinct(df$unitid[df$selectivity_tier == tiers[i]])
  if (i == 1) cat(sprintf("Institutions & %s", format(n, big.mark = ",")))
  else cat(sprintf(" & %s", format(n, big.mark = ",")))
}
cat(" \\\\\n")

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Each column restricts to institutions within the indicated selectivity tier. Dependent variable: URM enrollment share (percentage points). Post = 1 for Fall 2024 enrollment. Standard errors clustered at the state level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE 4: Placebo and Robustness Tests
# ==============================================================================

cat("Generating Table 4: Robustness\n")

sink("../tables/tab4_robustness.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Placebo Tests and Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat(" & Coefficient & SE \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Placebo Tests}} \\\\\n")

# Prior ban placebo
b <- coef(robustness$prior_ban)[1]; s <- se(robustness$prior_ban)[1]
p <- pvalue(robustness$prior_ban)[1]
star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
cat(sprintf("\\quad Prior-ban states & %.3f%s & (%.3f) \\\\\n", b, star, s))

# Non-ban states
b <- coef(robustness$no_ban)[1]; s <- se(robustness$no_ban)[1]
p <- pvalue(robustness$no_ban)[1]
star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
cat(sprintf("\\quad Non-ban states & %.3f%s & (%.3f) \\\\\n", b, star, s))

# HBCU
if (!is.null(robustness$hbcu)) {
  b <- coef(robustness$hbcu)[1]; s <- se(robustness$hbcu)[1]
  p <- pvalue(robustness$hbcu)[1]
  star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  cat(sprintf("\\quad HBCUs & %.3f%s & (%.3f) \\\\\n", b, star, s))
}

cat("\\midrule\n")
cat("\\multicolumn{3}{l}{\\textit{Panel B: Robustness}} \\\\\n")

# Public
b <- coef(robustness$public)[1]; s <- se(robustness$public)[1]
p <- pvalue(robustness$public)[1]
star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
cat(sprintf("\\quad Public institutions & %.3f%s & (%.3f) \\\\\n", b, star, s))

# Private
b <- coef(robustness$private)[1]; s <- se(robustness$private)[1]
p <- pvalue(robustness$private)[1]
star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
cat(sprintf("\\quad Private institutions & %.3f%s & (%.3f) \\\\\n", b, star, s))

# Balanced panel
b <- coef(robustness$balanced)[1]; s <- se(robustness$balanced)[1]
p <- pvalue(robustness$balanced)[1]
star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
cat(sprintf("\\quad Balanced panel & %.3f%s & (%.3f) \\\\\n", b, star, s))

# State-year FE
b <- coef(robustness$state_year)[1]; s <- se(robustness$state_year)[1]
p <- pvalue(robustness$state_year)[1]
star <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
cat(sprintf("\\quad State $\\times$ Year FE & %.3f%s & (%.3f) \\\\\n", b, star, s))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")
cat("\\item \\textit{Notes:} Dependent variable: URM enrollment share (percentage points). Panel A reports intensity $\\times$ post coefficients for subsamples where the SFFA effect should be zero (prior-ban states, HBCUs) or present (non-ban states). Panel B reports the main specification on subsamples (public/private), a balanced panel, and with state $\\times$ year fixed effects. Standard errors clustered at the state level. * $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

# ==============================================================================
# TABLE F1: Standardized Effect Size (SDE) Appendix
# ==============================================================================

cat("Generating Table F1: SDE Appendix\n")

# Compute SDEs for main outcomes
# SD(Y) = pre-treatment standard deviation
pre_df <- df %>% filter(year <= 2022)

sde_results <- data.frame(
  outcome = character(),
  beta = numeric(),
  se_beta = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

outcome_nice <- c("URM Share", "Black Share", "Hispanic Share",
                   "Asian Share", "White Share")
outcomes_list <- c("urm_share", "black_share", "hispanic_share",
                    "asian_share", "white_share")

for (i in seq_along(outcomes_list)) {
  y <- outcomes_list[i]
  m <- results$models_main[[y]]
  b <- coef(m)[1]
  s <- se(m)[1]
  sd_y <- sd(pre_df[[y]], na.rm = TRUE)
  sde_val <- b / sd_y
  se_sde <- s / sd_y

  # Classification
  class_label <- case_when(
    sde_val < -0.15  ~ "Large negative",
    sde_val < -0.05  ~ "Moderate negative",
    sde_val < -0.005 ~ "Small negative",
    sde_val <= 0.005 ~ "Null",
    sde_val <= 0.05  ~ "Small positive",
    sde_val <= 0.15  ~ "Moderate positive",
    TRUE             ~ "Large positive"
  )

  sde_results <- rbind(sde_results, data.frame(
    outcome = outcome_nice[i],
    beta = b,
    se_beta = s,
    sd_y = sd_y,
    sde = sde_val,
    se_sde = se_sde,
    classification = class_label,
    stringsAsFactors = FALSE
  ))
}

# Panel B: Heterogeneous — split by prior-ban vs. non-ban
sde_hetero <- data.frame(
  outcome = character(),
  beta = numeric(),
  se_beta = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

# Non-ban states (where SFFA binds)
sd_y_nonban <- sd(pre_df$urm_share[pre_df$prior_ban == 0], na.rm = TRUE)
b_nonban <- coef(robustness$no_ban)[1]
s_nonban <- se(robustness$no_ban)[1]
sde_nonban <- b_nonban / sd_y_nonban
class_nonban <- case_when(
  sde_nonban < -0.15  ~ "Large negative",
  sde_nonban < -0.05  ~ "Moderate negative",
  sde_nonban < -0.005 ~ "Small negative",
  sde_nonban <= 0.005 ~ "Null",
  sde_nonban <= 0.05  ~ "Small positive",
  sde_nonban <= 0.15  ~ "Moderate positive",
  TRUE                ~ "Large positive"
)
sde_hetero <- rbind(sde_hetero, data.frame(
  outcome = "URM Share (non-ban states)",
  beta = b_nonban, se_beta = s_nonban, sd_y = sd_y_nonban,
  sde = sde_nonban, se_sde = s_nonban / sd_y_nonban,
  classification = class_nonban, stringsAsFactors = FALSE
))

# Prior-ban states (placebo)
sd_y_ban <- sd(pre_df$urm_share[pre_df$prior_ban == 1], na.rm = TRUE)
b_ban <- coef(robustness$prior_ban)[1]
s_ban <- se(robustness$prior_ban)[1]
sde_ban <- b_ban / sd_y_ban
class_ban <- case_when(
  sde_ban < -0.15  ~ "Large negative",
  sde_ban < -0.05  ~ "Moderate negative",
  sde_ban < -0.005 ~ "Small negative",
  sde_ban <= 0.005 ~ "Null",
  sde_ban <= 0.05  ~ "Small positive",
  sde_ban <= 0.15  ~ "Moderate positive",
  TRUE             ~ "Large positive"
)
sde_hetero <- rbind(sde_hetero, data.frame(
  outcome = "URM Share (prior-ban states)",
  beta = b_ban, se_beta = s_ban, sd_y = sd_y_ban,
  sde = sde_ban, se_sde = s_ban / sd_y_ban,
  classification = class_ban, stringsAsFactors = FALSE
))

# Write SDE table
sink("../tables/tabF1_sde.tex")
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (i in 1:nrow(sde_results)) {
  r <- sde_results[i, ]
  cat(sprintf("\\quad %s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
      r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}

cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by prior AA ban status)}} \\\\\n")

for (i in 1:nrow(sde_hetero)) {
  r <- sde_hetero[i, ]
  cat(sprintf("\\quad %s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
      r$outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\\small\n")

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the Supreme Court's June 2023 ban on race-conscious college admissions (SFFA v.\\ Harvard) change the racial composition of undergraduate enrollment, and does the effect vary with institutional selectivity? ",
  "\\textbf{Policy mechanism:} The SFFA decision prohibits universities from considering applicants' race or ethnicity in admissions decisions, removing a tool that selective institutions used to maintain racial diversity in incoming classes. ",
  "\\textbf{Outcome definition:} Underrepresented minority (URM = Black + Hispanic) enrollment share as a percentage of total 12-month unduplicated undergraduate headcount, from IPEDS. ",
  "\\textbf{Treatment:} Continuous; treatment intensity is 1 minus the institution's pre-SFFA average admission rate (2019--2022), capturing the likelihood that the institution practiced race-conscious admissions. ",
  "\\textbf{Data:} IPEDS 12-month enrollment survey (effy), 2017--2024, institution-year panel of degree-granting Title IV institutions with $\\geq$100 undergraduates. ",
  "\\textbf{Method:} Two-way fixed effects (institution + year) with continuous treatment intensity interacted with post-2024 indicator; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Title IV degree-granting institutions with admission rate data for at least 2 of 4 pre-SFFA years and $\\geq$100 undergraduate enrollment; excludes for-profit institutions without admission data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)
cat(sde_notes)
cat("\n")

cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("All tables generated in tables/\n")
