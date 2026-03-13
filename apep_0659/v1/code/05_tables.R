# ==============================================================================
# 05_tables.R — Generate all LaTeX tables
# The Enclave as Insurance and Trap
# ==============================================================================

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")

df <- readRDS("../data/analysis_sample.rds")
main_models <- readRDS("../data/main_models.rds")
mech_models <- readRDS("../data/mech_models.rds")
natl_results <- readRDS("../data/natl_results.rds")
robustness <- readRDS("../data/robustness_models.rds")

df <- df %>%
  mutate(
    coethnic_share_z = (coethnic_share - mean(coethnic_share)) / sd(coethnic_share),
    high_selfempl_natl = as.integer(natl_selfempl_rate > median(natl_selfempl_rate, na.rm = TRUE))
  )

# --------------------------------------------------------------------------
# Table 1: Summary Statistics
# --------------------------------------------------------------------------

cat("Generating Table 1: Summary Statistics...\n")

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Mean & SD & N \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Outcome variables}} \\\\[3pt]"
)

# Helper function
fmt_row <- function(label, var, data = df) {
  vals <- data[[var]]
  vals <- vals[!is.na(vals)]
  sprintf("%s & %.2f & (%.2f) & %s \\\\", label,
          mean(vals), sd(vals), format(length(vals), big.mark = ","))
}

tab1_lines <- c(tab1_lines,
  fmt_row("Occ.\\ score (1920)", "occscore_1920"),
  fmt_row("Occ.\\ score (1930)", "occscore_1930"),
  fmt_row("Occ.\\ score (1940)", "occscore_1940"),
  fmt_row("$\\Delta$ Occ.\\ score (1930--1940)", "delta_occscore_bust"),
  fmt_row("Downgrade (1930--1940)", "downgrade_bust"),
  fmt_row("Large downgrade ($>$10 pts)", "large_downgrade_bust"),
  fmt_row("Lost homeownership", "lost_home"),
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel B: Treatment and controls}} \\\\[3pt]",
  fmt_row("Co-ethnic share (1920)", "coethnic_share"),
  fmt_row("Age (1920)", "age_1920"),
  fmt_row("Self-employed (1920)", "selfempl_1920"),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}\\footnotesize",
  sprintf("\\textit{Notes:} Sample consists of %s European-born males aged 25--45 in 1920, linked across the 1920, 1930, and 1940 U.S.\\ censuses via the IPUMS Machine Learning Panel (MLP). Co-ethnic share is the fraction of the county's working-age male population born in the same European country, measured in 1920. ``Downgrade'' indicates the individual's 1940 occupational income score is below their 1930 score. N = %s individuals from %d nationalities across %s counties.",
          format(nrow(df), big.mark = ","),
          format(nrow(df), big.mark = ","),
          n_distinct(df$nationality),
          format(n_distinct(df$county_id), big.mark = ",")),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# --------------------------------------------------------------------------
# Table 2: Main Results — Boom vs Bust
# --------------------------------------------------------------------------

cat("Generating Table 2: Main Results (Boom vs Bust)...\n")

modelsummary(
  list(
    "(1) Bust" = main_models$m1,
    "(2) Bust" = main_models$m2,
    "(3) Downgrade" = main_models$m3,
    "(4) Lost home" = main_models$m5,
    "(5) Boom" = robustness$placebo
  ),
  coef_map = c(
    "coethnic_share_z" = "Co-ethnic share (std)",
    "age_1920" = "Age",
    "I(age_1920^2)" = "Age sq.",
    "in_school_1920" = "In school",
    "selfempl_1920" = "Self-employed",
    "occscore_1920" = "Occ. score (1920)"
  ),
  gof_map = c("nobs", "r.squared"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Enclave Density and Occupational Mobility: Boom vs.\\ Bust \\label{tab:main}",
  notes = list("Columns (1)--(4): Depression era (1930--1940). Column (5): Boom era (1920--1930). Co-ethnic share standardized (mean zero, unit SD). Nationality and state FE. SE clustered at county level."),
  output = "../tables/tab2_main.tex",
  escape = FALSE
)

# --------------------------------------------------------------------------
# Table 3: Nationality-Specific Effects — Boom vs Bust
# --------------------------------------------------------------------------

cat("Generating Table 3: Nationality-specific boom vs bust...\n")

# Merge boom and bust results
placebo_natl <- robustness$placebo_natl

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Enclave Paradox: Boom-Era Trap, Bust-Era Insurance}",
  "\\label{tab:paradox}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  " & \\multicolumn{2}{c}{Boom (1920--30)} & \\multicolumn{2}{c}{Bust (1930--40)} & & \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Nationality & $\\hat{\\beta}$ & SE & $\\hat{\\beta}$ & SE & Reversal & Self-empl. \\\\",
  "\\hline"
)

tab_data <- placebo_natl %>%
  filter(!is.na(beta_boom)) %>%
  mutate(
    reversal = beta_bust - beta_boom,
    selfempl = natl_results$selfempl_rate[match(nationality, natl_results$nationality)]
  ) %>%
  arrange(desc(reversal))

for (i in seq_len(nrow(tab_data))) {
  r <- tab_data[i, ]
  boom_star <- ifelse(abs(r$beta_boom / r$se_boom) > 1.96, "*", "")
  bust_star <- ifelse(abs(r$beta_bust / r$se_bust) > 1.96, "*", "")
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %.3f%s & (%.3f) & %.3f%s & (%.3f) & %.3f & %.1f\\%% \\\\",
            r$nationality, r$beta_boom, boom_star, r$se_boom,
            r$beta_bust, bust_star, r$se_bust,
            r$reversal, r$selfempl * 100))
}

tab3_lines <- c(tab3_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}\\footnotesize",
  "\\textit{Notes:} Each cell reports the coefficient on standardized co-ethnic share from a nationality-specific regression, with state fixed effects and individual controls (age, age$^2$, self-employment status, 1920 occupational score). ``Reversal'' = $\\hat{\\beta}_{\\text{bust}} - \\hat{\\beta}_{\\text{boom}}$. Positive reversal indicates enclaves performed relatively better during the Depression than during the boom. Self-employment rate is the fraction of co-ethnic working-age males who were self-employed in 1920. Standard errors clustered at the county level. $^{*}p<0.05$.",
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_paradox.tex")

# --------------------------------------------------------------------------
# Table 4: Mechanism — Self-Employment Interaction
# --------------------------------------------------------------------------

cat("Generating Table 4: Mechanism...\n")

modelsummary(
  list(
    "(1) Binary" = mech_models$m_mech1,
    "(2) Continuous" = mech_models$m_mech2,
    "(3) County FE" = robustness$county_mech,
    "(4) County FE" = robustness$county_fe
  ),
  coef_map = c(
    "coethnic_share_z" = "Co-ethnic share (std)",
    "high_selfempl_natl" = "High self-empl. nationality",
    "coethnic_share_z:high_selfempl_natl" = "Co-ethnic x High self-empl.",
    "natl_selfempl_rate" = "Natl. self-empl. rate",
    "coethnic_share_z:natl_selfempl_rate" = "Co-ethnic x Self-empl. rate"
  ),
  gof_map = c("nobs", "r.squared"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Mechanism: Self-Employment Networks and Enclave Insurance \\label{tab:mechanism}",
  notes = list("Dep. var: change in occ. score (1930--1940). Nationality and state FE (cols 1-2), county FE (cols 3-4). SE clustered at county."),
  output = "../tables/tab4_mechanism.tex",
  escape = FALSE
)

# --------------------------------------------------------------------------
# Table 5: Robustness
# --------------------------------------------------------------------------

cat("Generating Table 5: Robustness...\n")

modelsummary(
  list(
    "(1) Bust" = robustness$bust,
    "(2) Boom" = robustness$placebo,
    "(3) Log" = robustness$log,
    "(4) Quintile" = robustness$quintile,
    "(5) County FE" = robustness$county_fe
  ),
  coef_map = c(
    "coethnic_share_z" = "Co-ethnic share (std)",
    "log_coethnic" = "Log co-ethnic share",
    "enclave_quintile::2" = "Quintile 2",
    "enclave_quintile::3" = "Quintile 3",
    "enclave_quintile::4" = "Quintile 4",
    "enclave_quintile::5" = "Quintile 5 (densest)"
  ),
  gof_map = c("nobs", "r.squared"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Robustness: Alternative Specifications \\label{tab:robustness}",
  notes = list("Dep. var: change in occ. score. All with individual controls and nationality FE (except col. 5). SE clustered at county."),
  output = "../tables/tab5_robustness.tex",
  escape = FALSE
)

# --------------------------------------------------------------------------
# SDE Appendix Table
# --------------------------------------------------------------------------

cat("Generating SDE table...\n")

sd_y_occ <- sd(df$delta_occscore_bust)
sd_y_down <- sd(df$downgrade_bust)
sd_y_home <- sd(df$lost_home, na.rm = TRUE)

b_occ <- coef(main_models$m2)["coethnic_share_z"]
se_occ <- se(main_models$m2)["coethnic_share_z"]
b_down <- coef(main_models$m3)["coethnic_share_z"]
se_down <- se(main_models$m3)["coethnic_share_z"]
b_home <- coef(main_models$m5)["coethnic_share_z"]
se_home <- se(main_models$m5)["coethnic_share_z"]

# Boom-period effect (placebo)
sd_y_boom <- sd(readRDS("../data/panel_boom.rds") %>%
  filter(!is.na(occscore_1920) & occscore_1920 > 0,
         !is.na(occscore_1930) & occscore_1930 > 0) %>%
  mutate(d = occscore_1930 - occscore_1920) %>%
  pull(d))
b_boom <- coef(robustness$placebo)["coethnic_share_z"]
se_boom <- se(robustness$placebo)["coethnic_share_z"]

sde_rows <- tibble(
  Outcome = c(
    "$\\Delta$ Occ.\\ score (bust, pooled)",
    "Downgrade probability (bust)",
    "Homeownership loss (bust)",
    "$\\Delta$ Occ.\\ score (boom, placebo)"
  ),
  beta = c(b_occ, b_down, b_home, b_boom),
  SE = c(se_occ, se_down, se_home, se_boom),
  SD_Y = c(sd_y_occ, sd_y_down, sd_y_home, sd_y_boom),
  SDE = beta / SD_Y,
  SE_SDE = SE / SD_Y
) %>%
  mutate(
    Classification = case_when(
      SDE < -0.15 ~ "Large negative",
      SDE < -0.05 ~ "Moderate negative",
      SDE < -0.005 ~ "Small negative",
      SDE <= 0.005 ~ "Null",
      SDE <= 0.05 ~ "Small positive",
      SDE <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    )
  )

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline"
)

for (i in seq_len(nrow(sde_rows))) {
  r <- sde_rows[i, ]
  sde_lines <- c(sde_lines,
    sprintf("%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
            r$Outcome, r$beta, r$SE, r$SD_Y, r$SDE, r$SE_SDE, r$Classification))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{minipage}{0.92\\textwidth}\\footnotesize",
  sprintf("\\textit{Notes:} Standardized effect sizes (SDE) computed as $\\hat{\\beta} / \\text{SD}(Y)$ since the treatment variable (co-ethnic share) is already standardized to unit variance. The research question is whether ethnic residential concentration insulates or amplifies occupational losses during the Great Depression. Data: IPUMS Machine Learning Panel (MLP) linking 1920, 1930, and 1940 full-count U.S.\\ censuses. Method: OLS with nationality and state fixed effects. Sample: %s European-born males across %d nationalities. Treatment: continuous co-ethnic county share (standardized). Classification refers to effect magnitude, not statistical significance.",
          format(nrow(df), big.mark = ","), n_distinct(df$nationality)),
  "\\end{minipage}",
  "\\end{table}"
)

writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
