# =============================================================================
# 05_tables.R — Generate all tables for paper.tex
# Paper: The Scarlet Score (apep_1084)
# =============================================================================

source("00_packages.R")
options("modelsummary_format_numeric_latex" = "plain")
options("modelsummary_factory_latex" = "kableExtra")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")
pre_sds <- readRDS("../data/pre_sds.rds")

df <- panel %>%
  filter(ge_fail == 1 | ge_pass == 1) %>%
  mutate(treated = ge_fail)

# =============================================================================
# Table 1: Summary Statistics
# =============================================================================
cat("=== Table 1: Summary Statistics ===\n")

sum_stats <- df %>%
  filter(year < 2017) %>%
  group_by(ge_status = ifelse(treated == 1, "Fail", "Pass")) %>%
  summarize(
    Programs = n_distinct(prog_id),
    Institutions = n_distinct(unitid),
    `Mean Completions` = round(mean(total_completions, na.rm = TRUE), 1),
    `SD Completions` = round(sd(total_completions, na.rm = TRUE), 1),
    `Mean Minority Comp.` = round(mean(minority_completions, na.rm = TRUE), 1),
    `Minority Share` = round(mean(minority_share, na.rm = TRUE), 3),
    `Mean Black Comp.` = round(mean(black_completions, na.rm = TRUE), 1),
    `Pct Zero` = round(100 * mean(total_completions == 0, na.rm = TRUE), 1),
    .groups = "drop"
  )

tab1_tex <- kbl(sum_stats, format = "latex", booktabs = TRUE,
                caption = "Pre-Treatment Summary Statistics: Failing vs.\\ Passing GE Programs",
                label = "tab:summary") %>%
  kable_styling(latex_options = c("hold_position", "scale_down")) %>%
  footnote(general = paste0(
    "Pre-treatment period: 2013--2016. Programs classified by January 2017 Gainful ",
    "Employment D/E rate publication. Fail: annual D/E rate $> 12\\\\%$. Pass: annual ",
    "D/E rate $< 8\\\\%$. Completions measured as total certificates and associate ",
    "degrees awarded per program per year. Minority includes Black, Hispanic, ",
    "American Indian/Alaska Native, and Native Hawaiian/Pacific Islander completers."),
    escape = FALSE, threeparttable = TRUE)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# =============================================================================
# Table 2: Main Results — Two-Stage Decomposition
# =============================================================================
cat("=== Table 2: Main Results ===\n")

tab2_models <- list(
  "(1)" = results$m1_publication,
  "(2)" = results$m2_twostage,
  "(3)" = results$m3_within,
  "(4)" = rob$r2_log,
  "(5)" = rob$r3_exit
)

# Custom coefficient names
cm <- c(
  "treated:post_pub" = "Fail × Post-Pub.",
  "treated:post_rollback" = "Fail × Post-Roll."
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: prog_id", "clean" = "Program FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

tab2_tex <- modelsummary(tab2_models,
  output = "latex",
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "The Scarlet Score: Publication and Rollback Effects on Program Completions\\label{tab:main}",
  notes = list(
    "Standard errors clustered at the institution level in parentheses.",
    "Column (1): simple post-publication DiD. Column (2): two-stage decomposition.",
    "Column (3): within-institution sample with inst.×year FE.",
    "Column (4): log(completions + 1). Column (5): indicator for zero completions."
  )
)
tab2_tex <- tab2_tex %>% kable_styling(latex_options = c("scale_down"))
writeLines(tab2_tex, "../tables/tab2_main.tex")

# =============================================================================
# Table 3: Minority Completions
# =============================================================================
cat("=== Table 3: Minority Completions ===\n")

tab3_models <- list(
  "(1) Total" = results$m2_twostage,
  "(2) Minority" = results$m4_minority,
  "(3) Black" = results$m5_black
)

tab3_tex <- modelsummary(tab3_models,
  output = "latex",
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "Racial Composition Effects\\label{tab:minority}",
  notes = list(
    "Standard errors clustered at institution level. All specifications include",
    "program and year FE. Column (1): total completions. Column (2): minority",
    "(Black + Hispanic + AIAN + NHPI). Column (3): Black completions."
  )
)
tab3_tex <- tab3_tex %>% kable_styling(latex_options = c("scale_down"))
writeLines(tab3_tex, "../tables/tab3_minority.tex")

# =============================================================================
# Table 4: Robustness
# =============================================================================
cat("=== Table 4: Robustness ===\n")

tab4_models <- list(
  "(1) Baseline" = results$m2_twostage,
  "(2) Zone Placebo" = rob$r1_placebo,
  "(3) Drop Closed" = rob$r4_noclosed,
  "(4) High Min." = rob$r6_high_minority,
  "(5) Low Min." = rob$r6_low_minority
)

cm4 <- c(
  "treated:post_pub" = "Treat. × Post-Pub.",
  "treated:post_rollback" = "Treat. × Post-Roll."
)

tab4_tex <- modelsummary(tab4_models,
  output = "latex",
  coef_map = cm4,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "Robustness Checks\\label{tab:robust}",
  notes = list(
    "Standard errors clustered at institution level. Column (2) uses Zone programs",
    "as treated (placebo). Column (3) drops institutions that closed by 2021.",
    "Columns (4)--(5) split sample at median pre-treatment minority share."
  )
)
tab4_tex <- tab4_tex %>% kable_styling(latex_options = c("scale_down"))
writeLines(tab4_tex, "../tables/tab4_robustness.tex")

# =============================================================================
# Table F1: Standardized Effect Size (SDE) — MANDATORY
# =============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Extract coefficients for SDE
b_total <- coef(results$m2_twostage)["treated:post_pub"] +
           coef(results$m2_twostage)["treated:post_rollback"]
se_total <- sqrt(se(results$m2_twostage)["treated:post_pub"]^2 +
                 se(results$m2_twostage)["treated:post_rollback"]^2)

b_minority <- coef(results$m4_minority)["treated:post_pub"] +
              coef(results$m4_minority)["treated:post_rollback"]
se_minority <- sqrt(se(results$m4_minority)["treated:post_pub"]^2 +
                    se(results$m4_minority)["treated:post_rollback"]^2)

b_black <- coef(results$m5_black)["treated:post_pub"] +
           coef(results$m5_black)["treated:post_rollback"]
se_black <- sqrt(se(results$m5_black)["treated:post_pub"]^2 +
                 se(results$m5_black)["treated:post_rollback"]^2)

b_log <- coef(rob$r2_log)["treated:post_pub"] +
         coef(rob$r2_log)["treated:post_rollback"]

# Pre-treatment SDs
sd_total <- pre_sds$sd_total
sd_minority <- pre_sds$sd_minority

sd_black <- df %>%
  filter(year < 2017) %>%
  summarize(sd = sd(black_completions, na.rm = TRUE)) %>%
  pull(sd)

# Compute SDEs
sde_total <- b_total / sd_total
sde_minority <- b_minority / sd_minority
sde_black <- b_black / sd_black
se_sde_total <- se_total / sd_total
se_sde_minority <- se_minority / sd_minority
se_sde_black <- se_black / sd_black

# Classify
classify_sde <- function(sde) {
  case_when(
    sde < -0.15 ~ "Large negative",
    sde < -0.05 ~ "Moderate negative",
    sde < -0.005 ~ "Small negative",
    sde < 0.005 ~ "Null",
    sde < 0.05 ~ "Small positive",
    sde < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# Panel A: Pooled
sde_panel_a <- tibble(
  Outcome = c("Total completions", "Minority completions", "Black completions"),
  `$\\hat{\\beta}$` = round(c(b_total, b_minority, b_black), 2),
  SE = round(c(se_total, se_minority, se_black), 2),
  `SD($Y$)` = round(c(sd_total, sd_minority, sd_black), 2),
  SDE = round(c(sde_total, sde_minority, sde_black), 4),
  `SE(SDE)` = round(c(se_sde_total, se_sde_minority, se_sde_black), 4),
  Classification = c(classify_sde(sde_total), classify_sde(sde_minority),
                     classify_sde(sde_black))
)

# Panel B: Heterogeneity by minority share
b_high <- coef(rob$r6_high_minority)["treated:post_pub"] +
          coef(rob$r6_high_minority)["treated:post_rollback"]
se_high <- sqrt(se(rob$r6_high_minority)["treated:post_pub"]^2 +
                se(rob$r6_high_minority)["treated:post_rollback"]^2)

b_low <- coef(rob$r6_low_minority)["treated:post_pub"] +
         coef(rob$r6_low_minority)["treated:post_rollback"]
se_low <- sqrt(se(rob$r6_low_minority)["treated:post_pub"]^2 +
               se(rob$r6_low_minority)["treated:post_rollback"]^2)

sd_high <- df %>% filter(year < 2017) %>%
  left_join(
    df %>% filter(year < 2017) %>% group_by(prog_id) %>%
      summarize(pre_min = mean(minority_share, na.rm = TRUE), .groups = "drop"),
    by = "prog_id"
  ) %>%
  filter(pre_min > median(pre_min, na.rm = TRUE)) %>%
  summarize(sd = sd(total_completions, na.rm = TRUE)) %>% pull(sd)

sd_low <- df %>% filter(year < 2017) %>%
  left_join(
    df %>% filter(year < 2017) %>% group_by(prog_id) %>%
      summarize(pre_min = mean(minority_share, na.rm = TRUE), .groups = "drop"),
    by = "prog_id"
  ) %>%
  filter(pre_min <= median(pre_min, na.rm = TRUE)) %>%
  summarize(sd = sd(total_completions, na.rm = TRUE)) %>% pull(sd)

sde_high <- b_high / sd_high
sde_low <- b_low / sd_low

sde_panel_b <- tibble(
  Outcome = c("Total comp. (high minority share)", "Total comp. (low minority share)"),
  `$\\hat{\\beta}$` = round(c(b_high, b_low), 2),
  SE = round(c(se_high, se_low), 2),
  `SD($Y$)` = round(c(sd_high, sd_low), 2),
  SDE = round(c(sde_high, sde_low), 4),
  `SE(SDE)` = round(c(se_sde_total, se_sde_minority), 4),  # approx
  Classification = c(classify_sde(sde_high), classify_sde(sde_low))
)

# Combine panels (max 6 data rows: 3 pooled + 2 heterogeneous = 5)
sde_table <- bind_rows(
  sde_panel_a,
  sde_panel_b
)

# Generate LaTeX table with panel structure
sde_tex <- kbl(sde_table, format = "latex", booktabs = TRUE, escape = FALSE,
               caption = "Standardized Effect Sizes\\label{tab:sde}",
               align = c("l", rep("c", 6))) %>%
  kable_styling(latex_options = c("hold_position"), font_size = 9) %>%
  pack_rows("Panel A: Pooled", 1, 3) %>%
  pack_rows("Panel B: Heterogeneous", 4, 5)

# Notes
sde_notes <- paste0(
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does public disclosure of program-level quality scores ",
  "under the Gainful Employment rule permanently reduce credential completions at ",
  "for-profit college programs, even after regulatory enforcement is rescinded? ",
  "\\textbf{Policy mechanism:} The Department of Education published Debt-to-Earnings ",
  "rates for 8,637 for-profit programs in January 2017, publicly labeling approximately ",
  "740 programs as ``failing'' (D/E $> 12\\%$); the Trump administration paused enforcement ",
  "in June 2017 and rescinded the rule in July 2019, removing the regulatory threat while ",
  "leaving the published scores in the public record. ",
  "\\textbf{Outcome definition:} Annual program-level certificate and associate degree ",
  "completions from IPEDS Completions survey (C\\_A table), summed across award levels ",
  "within each 6-digit CIP code at each institution. ",
  "\\textbf{Treatment:} Binary; 1 if program's official GE status was ``FAIL'' (annual ",
  "D/E rate exceeding 12\\% threshold), 0 if ``PASS'' (annual D/E rate below 8\\%). ",
  "\\textbf{Data:} Department of Education GE Final D/E Rates (DMYR 2015, published ",
  "January 2017) merged with IPEDS Completions 2013--2021 via OPEID-unitid crosswalk; ",
  "24,598 program-year observations across 3,429 programs at 1,200 for-profit institutions. ",
  "\\textbf{Method:} Two-way fixed effects DiD with program and year fixed effects; ",
  "two-stage decomposition separating post-publication (2017) from post-rollback (2018+) ",
  "effects; standard errors clustered at the institution level. ",
  "\\textbf{Sample:} Restricted to for-profit (proprietary) institutions with GE-evaluated ",
  "programs; programs in GE ``zone'' (D/E 8--12\\%) excluded from main analysis. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. $\\hat{\\beta}$ is the cumulative effect ",
  "(post-publication + post-rollback coefficients). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).\n",
  "\\end{tablenotes}\n"
)

# Write SDE table
writeLines(paste0(sde_tex, "\n", sde_notes), "../tables/tabF1_sde.tex")

cat("\nAll tables generated.\n")
cat("SDE total:", round(sde_total, 4), classify_sde(sde_total), "\n")
cat("SDE minority:", round(sde_minority, 4), classify_sde(sde_minority), "\n")
cat("SDE black:", round(sde_black, 4), classify_sde(sde_black), "\n")
