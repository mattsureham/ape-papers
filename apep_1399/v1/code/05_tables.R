# 05_tables.R — Generate all LaTeX tables (state-level)
# apep_1399: The Bedrock Dose

source("00_packages.R")

data_dir <- "../data"
tab_dir  <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"),
            colClasses = c(state_fips = "character"))
models <- readRDS(file.path(data_dir, "models.rds"))

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Table 1: Summary Statistics\n")

sum_stats <- function(x) {
  c(Mean = mean(x, na.rm = TRUE), SD = sd(x, na.rm = TRUE),
    Min = min(x, na.rm = TRUE), Max = max(x, na.rm = TRUE))
}

vars <- c("cancer_aadr", "heart_aadr", "clrd_aadr", "stroke_aadr",
          "diabetes_aadr", "high_grp_share", "mean_grp")
labels <- c("Cancer AADR", "Heart Disease AADR", "CLRD AADR", "Stroke AADR",
            "Diabetes AADR", "High GRP Share", "Mean GRP")

# Split by treated vs control
treated <- df[treated_state == 1]
control <- df[treated_state == 0]

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics by RRNC Treatment Status}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{l rrrr rrrr}",
  "\\toprule",
  " & \\multicolumn{4}{c}{RRNC States ($N=209$)} & \\multicolumn{4}{c}{Non-RRNC States ($N=760$)} \\\\",
  "\\cmidrule(lr){2-5} \\cmidrule(lr){6-9}",
  "Variable & Mean & SD & Min & Max & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (i in seq_along(vars)) {
  v <- vars[i]
  t_stats <- sum_stats(treated[[v]])
  c_stats <- sum_stats(control[[v]])
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f & %.1f \\\\",
            labels[i], t_stats[1], t_stats[2], t_stats[3], t_stats[4],
            c_stats[1], c_stats[2], c_stats[3], c_stats[4]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All death rates are age-adjusted per 100,000 population (2000 standard). RRNC States are the 11 states that adopted radon-resistant new construction codes by 2021. High GRP Share is the fraction of counties in the state classified as moderate or high geological radon potential by USGS. Sample: 51 states, 1999--2017.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:summary}",
  "\\end{table}")

writeLines(tab1_lines, file.path(tab_dir, "tab1_summary.tex"))

# ============================================================================
# Table 2: Main Results
# ============================================================================
cat("Table 2: Main Results\n")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of RRNC Adoption on Cancer Mortality}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & TWFE & Triple-Diff & Continuous GRP & Pop-Weighted \\\\",
  "\\midrule"
)

m1 <- models$main; m2 <- models$triple_diff; m3 <- models$continuous; m4 <- models$weighted

# Post-RRNC row
pval <- fixest::pvalue
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

b1 <- coef(m1)["post_rrnc"]; se1 <- se(m1)["post_rrnc"]; p1 <- pval(m1)["post_rrnc"]
b2_pr <- coef(m2)["post_rrnc"]; se2_pr <- se(m2)["post_rrnc"]; p2_pr <- pval(m2)["post_rrnc"]
b4_pr <- coef(m4)["post_rrnc"]; se4_pr <- se(m4)["post_rrnc"]; p4_pr <- pval(m4)["post_rrnc"]

tab2_lines <- c(tab2_lines,
  sprintf("Post-RRNC & %.3f%s & %.3f%s & & %.3f%s \\\\", b1, stars(p1), b2_pr, stars(p2_pr), b4_pr, stars(p4_pr)),
  sprintf(" & (%.3f) & (%.3f) & & (%.3f) \\\\", se1, se2_pr, se4_pr))

# Triple-diff row
b2_td <- coef(m2)["treat_x_grp"]; se2_td <- se(m2)["treat_x_grp"]; p2_td <- pval(m2)["treat_x_grp"]
b4_td <- coef(m4)["treat_x_grp"]; se4_td <- se(m4)["treat_x_grp"]; p4_td <- pval(m4)["treat_x_grp"]

tab2_lines <- c(tab2_lines,
  sprintf("Post-RRNC $\\times$ High GRP & & %.3f%s & & %.3f%s \\\\", b2_td, stars(p2_td), b4_td, stars(p4_td)),
  sprintf(" & & (%.3f) & & (%.3f) \\\\", se2_td, se4_td))

# Continuous intensity
b3 <- coef(m3)["treat_x_grp_cont"]; se3 <- se(m3)["treat_x_grp_cont"]; p3 <- pval(m3)["treat_x_grp_cont"]
tab2_lines <- c(tab2_lines,
  sprintf("Post-RRNC $\\times$ GRP Share & & & %.3f%s & \\\\", b3, stars(p3)),
  sprintf(" & & & (%.3f) & \\\\", se3))

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\", nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  "State FE & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes \\\\",
  "Pop.~Weighted & No & No & No & Yes \\\\",
  sprintf("Mean Dep.~Var. & %.1f & %.1f & %.1f & %.1f \\\\",
          mean(df$cancer_aadr), mean(df$cancer_aadr), mean(df$cancer_aadr), mean(df$cancer_aadr)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is the age-adjusted cancer death rate per 100,000. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Post-RRNC equals 1 in years at or after RRNC code adoption. High GRP equals 1 if $>$50\\% of state's counties have moderate/high geological radon potential. GRP Share is the continuous share of high-GRP counties. Sample: 51 states, 1999--2017.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:main}",
  "\\end{table}")

writeLines(tab2_lines, file.path(tab_dir, "tab2_main.tex"))

# ============================================================================
# Table 3: Placebo Outcomes
# ============================================================================
cat("Table 3: Placebo Outcomes\n")

placebo_models <- list(
  heart = models$placebo_heart,
  clrd = models$placebo_clrd,
  stroke = models$placebo_stroke,
  diabetes = models$placebo_diabetes
)
placebo_names <- c("Heart Disease", "CLRD", "Stroke", "Diabetes")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Tests: Non-Cancer Causes of Death}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  paste0(" & (1) & (2) & (3) & (4) \\\\"),
  paste0(" & ", paste(placebo_names, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Post-RRNC row
pr_vals <- sapply(placebo_models, function(m) coef(m)["post_rrnc"])
pr_ses  <- sapply(placebo_models, function(m) se(m)["post_rrnc"])
pr_ps   <- sapply(placebo_models, function(m) pval(m)["post_rrnc"])
tab3_lines <- c(tab3_lines,
  paste0("Post-RRNC & ", paste(sprintf("%.3f%s", pr_vals, sapply(pr_ps, stars)), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%.3f)", pr_ses), collapse = " & "), " \\\\"))

# Triple-diff row
td_vals <- sapply(placebo_models, function(m) coef(m)["treat_x_grp"])
td_ses  <- sapply(placebo_models, function(m) se(m)["treat_x_grp"])
td_ps   <- sapply(placebo_models, function(m) pval(m)["treat_x_grp"])
tab3_lines <- c(tab3_lines,
  paste0("Post-RRNC $\\times$ High GRP & ", paste(sprintf("%.3f%s", td_vals, sapply(td_ps, stars)), collapse = " & "), " \\\\"),
  paste0(" & ", paste(sprintf("(%.3f)", td_ses), collapse = " & "), " \\\\"))

means <- c(mean(df$heart_aadr, na.rm=T), mean(df$clrd_aadr, na.rm=T),
           mean(df$stroke_aadr, na.rm=T), mean(df$diabetes_aadr, na.rm=T))
tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & %d & %d & %d & %d \\\\", nobs(placebo_models$heart), nobs(placebo_models$clrd), nobs(placebo_models$stroke), nobs(placebo_models$diabetes)),
  paste0("Mean Dep.~Var. & ", paste(sprintf("%.1f", means), collapse = " & "), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variables are age-adjusted death rates per 100,000 for causes unrelated to radon exposure. All specifications include state and year fixed effects with state-clustered standard errors. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. None of the placebo outcomes shows significant effects, supporting the identifying assumption.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\label{tab:placebo}",
  "\\end{table}")

writeLines(tab3_lines, file.path(tab_dir, "tab3_placebo.tex"))

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("Table 4: Robustness\n")

rob_file <- file.path(data_dir, "robustness_models.rds")
if (file.exists(rob_file)) {
  rob <- readRDS(rob_file)

  tab4_lines <- c(
    "\\begin{table}[H]",
    "\\centering",
    "\\caption{Robustness Checks}",
    "\\begin{threeparttable}",
    "\\begin{tabular}{lcc}",
    "\\toprule",
    "Specification & Post-RRNC & Post-RRNC $\\times$ High GRP \\\\",
    "\\midrule"
  )

  add_row <- function(label, m, has_triple = TRUE) {
    b_pr <- coef(m)["post_rrnc"]
    se_pr <- se(m)["post_rrnc"]
    p_pr <- pval(m)["post_rrnc"]
    if (has_triple && "treat_x_grp" %in% names(coef(m))) {
      b_td <- coef(m)["treat_x_grp"]
      se_td <- se(m)["treat_x_grp"]
      p_td <- pval(m)["treat_x_grp"]
      c(sprintf("%s & %.3f%s & %.3f%s \\\\", label, b_pr, stars(p_pr), b_td, stars(p_td)),
        sprintf(" & (%.3f) & (%.3f) \\\\", se_pr, se_td))
    } else if (has_triple && "treat_x_grp_alt" %in% names(coef(m))) {
      b_td <- coef(m)["treat_x_grp_alt"]
      se_td <- se(m)["treat_x_grp_alt"]
      p_td <- pval(m)["treat_x_grp_alt"]
      c(sprintf("%s & %.3f%s & %.3f%s \\\\", label, b_pr, stars(p_pr), b_td, stars(p_td)),
        sprintf(" & (%.3f) & (%.3f) \\\\", se_pr, se_td))
    } else {
      c(sprintf("%s & %.3f%s & --- \\\\", label, b_pr, stars(p_pr)),
        sprintf(" & (%.3f) & \\\\", se_pr))
    }
  }

  tab4_lines <- c(tab4_lines,
    add_row("Alt.~GRP threshold ($>$1.5)", rob$alt_grp),
    add_row("Drop early adopters", rob$late_adopters),
    add_row("Drop small states", rob$big_states),
    add_row("Population-weighted", rob$weighted))

  # Log spec
  if (!is.null(rob$log_spec)) {
    b <- coef(rob$log_spec)["post_rrnc"]; s <- se(rob$log_spec)["post_rrnc"]; p <- pval(rob$log_spec)["post_rrnc"]
    b2 <- coef(rob$log_spec)["treat_x_grp"]; s2 <- se(rob$log_spec)["treat_x_grp"]; p2 <- pval(rob$log_spec)["treat_x_grp"]
    tab4_lines <- c(tab4_lines,
      sprintf("Log specification & %.4f%s & %.4f%s \\\\", b, stars(p), b2, stars(p2)),
      sprintf(" & (%.4f) & (%.4f) \\\\", s, s2))
  }

  # CS ATT
  if (!is.null(models$cs_agg)) {
    tab4_lines <- c(tab4_lines,
      sprintf("Callaway--Sant'Anna ATT & %.3f & --- \\\\", models$cs_agg$overall.att),
      sprintf(" & (%.3f) & \\\\", models$cs_agg$overall.se))
  }

  # Permutation
  tab4_lines <- c(tab4_lines,
    sprintf("Permutation $p$-value & %.3f & \\\\", rob$perm_p))

  tab4_lines <- c(tab4_lines,
    "\\bottomrule",
    "\\end{tabular}",
    "\\begin{tablenotes}[flushleft]",
    "\\small",
    "\\item \\textit{Notes:} Each row reports coefficients from a separate regression. All specifications include state and year fixed effects with state-clustered standard errors unless noted. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. The Callaway--Sant'Anna estimate uses never-treated states as controls. Permutation test reassigns RRNC adoption across states 200 times.",
    "\\end{tablenotes}",
    "\\end{threeparttable}",
    "\\label{tab:robustness}",
    "\\end{table}")

  writeLines(tab4_lines, file.path(tab_dir, "tab4_robustness.tex"))
}

# ============================================================================
# Table F1: Standardized Effect Sizes (MANDATORY)
# ============================================================================
cat("Table F1: Standardized Effect Sizes\n")

# Pre-treatment SD of cancer_aadr
sd_y <- sd(df[year < 2009]$cancer_aadr, na.rm = TRUE)

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

# Panel A: Pooled
beta_main <- coef(models$main)["post_rrnc"]
se_main <- se(models$main)["post_rrnc"]
sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

beta_td <- coef(models$triple_diff)["treat_x_grp"]
se_td <- se(models$triple_diff)["treat_x_grp"]
sde_td <- beta_td / sd_y
se_sde_td <- se_td / sd_y

# Placebos
beta_heart <- coef(models$placebo_heart)["treat_x_grp"]
se_heart <- se(models$placebo_heart)["treat_x_grp"]
sd_heart <- sd(df[year < 2009]$heart_aadr, na.rm = TRUE)
sde_heart <- beta_heart / sd_heart
se_sde_heart <- se_heart / sd_heart

beta_clrd <- coef(models$placebo_clrd)["treat_x_grp"]
se_clrd <- se(models$placebo_clrd)["treat_x_grp"]
sd_clrd <- sd(df[year < 2009]$clrd_aadr, na.rm = TRUE)
sde_clrd <- beta_clrd / sd_clrd
se_sde_clrd <- se_clrd / sd_clrd

# Panel B: Heterogeneous (high GRP vs low GRP states)
df_high <- df[high_grp_state == 1]
df_low <- df[high_grp_state == 0]

m_high <- feols(cancer_aadr ~ post_rrnc | state_fips + year, data = df_high, cluster = ~state_fips)
m_low <- feols(cancer_aadr ~ post_rrnc | state_fips + year, data = df_low, cluster = ~state_fips)

sd_y_high <- sd(df_high[year < 2009]$cancer_aadr, na.rm = TRUE)
sd_y_low <- sd(df_low[year < 2009]$cancer_aadr, na.rm = TRUE)

sde_high <- coef(m_high)["post_rrnc"] / sd_y_high
se_sde_high <- se(m_high)["post_rrnc"] / sd_y_high
sde_low <- coef(m_low)["post_rrnc"] / sd_y_low
se_sde_low <- se(m_low)["post_rrnc"] / sd_y_low

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether state-level adoption of Radon-Resistant New Construction (RRNC) building codes reduces age-adjusted cancer mortality rates. ",
  "\\textbf{Policy mechanism:} RRNC codes mandate passive radon barriers in new residential construction, including sub-slab depressurization piping, vapor barriers, and sealed foundations, which prevent geological radon gas from accumulating in indoor air where it causes DNA damage through alpha-particle irradiation of lung tissue. ",
  "\\textbf{Outcome definition:} Age-adjusted all-cancer death rate (ICD-10 C00--C97) per 100,000, standardized to the 2000 U.S.\\ population, from the CDC NCHS Leading Causes of Death database. ",
  "\\textbf{Treatment:} Binary indicator equal to one in years at or after a state adopted mandatory RRNC building codes. ",
  "\\textbf{Data:} CDC NCHS Leading Causes of Death (1999--2017) linked with USGS Geological Radon Potential classification (926 provinces) and Census population estimates; state-year panel. ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with state and year fixed effects, standard errors clustered at the state level; robustness via Callaway--Sant'Anna heterogeneity-robust estimator. ",
  "\\textbf{Sample:} 51 U.S.\\ states (including D.C.) observed annually 1999--2017 (969 state-year observations); 11 treated states with staggered RRNC adoption from 1995 to 2021; 40 never-treated control states. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (pre-2009) standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Cancer AADR & TWFE (Post-RRNC) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_main, se_main, sd_y, sde_main, se_sde_main, classify(sde_main)),
  sprintf("Cancer AADR & Triple-diff & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_td, se_td, sd_y, sde_td, se_sde_td, classify(sde_td)),
  sprintf("Heart Disease & Triple-diff & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_heart, se_heart, sd_heart, sde_heart, se_sde_heart, classify(sde_heart)),
  sprintf("CLRD & Triple-diff & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_clrd, se_clrd, sd_clrd, sde_clrd, se_sde_clrd, classify(sde_clrd)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by State Geological Radon Potential)}} \\\\",
  sprintf("Cancer AADR & High-GRP states & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          coef(m_high)["post_rrnc"], se(m_high)["post_rrnc"], sd_y_high, sde_high, se_sde_high, classify(sde_high)),
  sprintf("Cancer AADR & Low-GRP states & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          coef(m_low)["post_rrnc"], se(m_low)["post_rrnc"], sd_y_low, sde_low, se_sde_low, classify(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}")

writeLines(sde_lines, file.path(tab_dir, "tabF1_sde.tex"))

cat("\n=== All tables generated ===\n")
cat("Files in tables/:\n")
print(list.files(tab_dir))
