## 05_tables.R — Generate all tables for apep_0729

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

df <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ============================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

summ_all <- df[, .(
  Variable = "Voter turnout (\\%)",
  Mean = sprintf("%.1f", mean(turnout, na.rm = TRUE)),
  SD = sprintf("%.1f", sd(turnout, na.rm = TRUE)),
  Min = sprintf("%.1f", min(turnout, na.rm = TRUE)),
  Max = sprintf("%.1f", max(turnout, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
)]

summ_treated <- df[treated == TRUE, .(
  Variable = "\\quad Subsidized municipalities",
  Mean = sprintf("%.1f", mean(turnout, na.rm = TRUE)),
  SD = sprintf("%.1f", sd(turnout, na.rm = TRUE)),
  Min = sprintf("%.1f", min(turnout, na.rm = TRUE)),
  Max = sprintf("%.1f", max(turnout, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
)]

summ_control <- df[treated == FALSE, .(
  Variable = "\\quad Non-subsidized municipalities",
  Mean = sprintf("%.1f", mean(turnout, na.rm = TRUE)),
  SD = sprintf("%.1f", sd(turnout, na.rm = TRUE)),
  Min = sprintf("%.1f", min(turnout, na.rm = TRUE)),
  Max = sprintf("%.1f", max(turnout, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
)]

summ_pop <- df[, .(
  Variable = "Population (2021)",
  Mean = format(round(mean(population_2021, na.rm = TRUE)), big.mark = ","),
  SD = format(round(sd(population_2021, na.rm = TRUE)), big.mark = ","),
  Min = format(round(min(population_2021, na.rm = TRUE)), big.mark = ","),
  Max = format(round(max(population_2021, na.rm = TRUE)), big.mark = ","),
  N = format(uniqueN(region_code), big.mark = ",")
)]

summ_subsidy_treated <- df[treated == TRUE, .(
  Variable = "Subsidy per capita (NOK)",
  Mean = sprintf("%.0f", mean(subsidy_per_capita, na.rm = TRUE)),
  SD = sprintf("%.0f", sd(subsidy_per_capita, na.rm = TRUE)),
  Min = sprintf("%.0f", min(subsidy_per_capita[subsidy_per_capita > 0], na.rm = TRUE)),
  Max = sprintf("%.0f", max(subsidy_per_capita, na.rm = TRUE)),
  N = format(uniqueN(region_code), big.mark = ",")
)]

summ_storting <- df[election_type == "storting", .(
  Variable = "Storting election turnout (\\%)",
  Mean = sprintf("%.1f", mean(turnout, na.rm = TRUE)),
  SD = sprintf("%.1f", sd(turnout, na.rm = TRUE)),
  Min = sprintf("%.1f", min(turnout, na.rm = TRUE)),
  Max = sprintf("%.1f", max(turnout, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
)]

summ_local <- df[election_type == "local", .(
  Variable = "Local election turnout (\\%)",
  Mean = sprintf("%.1f", mean(turnout, na.rm = TRUE)),
  SD = sprintf("%.1f", sd(turnout, na.rm = TRUE)),
  Min = sprintf("%.1f", min(turnout, na.rm = TRUE)),
  Max = sprintf("%.1f", max(turnout, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
)]

summ <- rbind(summ_all, summ_treated, summ_control,
              summ_storting, summ_local,
              summ_pop, summ_subsidy_treated)

tab1_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max & N \\\\\n",
  "\\hline\n",
  paste(apply(summ, 1, function(row) paste(row, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Municipality-election panel, 2001--2025. ",
  "Subsidized municipalities are those with at least one newspaper receiving ",
  "Medietilsynet produksjonstilskudd in 2021. Subsidy per capita is total ",
  "annual subsidy divided by 2021 population. Storting elections are held ",
  "every four years (2001--2025); local elections every four years (2003--2023).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1_latex, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# TABLE 2: MAIN RESULTS (PROGRESSIVE SPECIFICATION)
# ============================================================
cat("Generating Table 2: Main Results...\n")

tab2_models <- list(
  "(1)" = results$m1,
  "(2)" = results$m2,
  "(3)" = results$m3,
  "(4)" = results$m4,
  "(5)" = results$m6
)

# Build Table 2 manually using etable
etable(results$m1, results$m2, results$m3, results$m4, results$m6,
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       dict = c(treatedTRUE = "Subsidized municipality", log_pop = "Log population"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + r2 + ar2,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_main.tex"),
       title = "Press Subsidies and Voter Turnout",
       label = "tab:main",
       notes = c("Municipality-election panel, 2001--2025. Dependent variable: voter turnout (\\\\%).",
                 "Standard errors clustered at municipality level in parentheses.",
                 "Treatment: municipality has at least one newspaper receiving produksjonstilskudd (2021).")
)

# ============================================================
# TABLE 3: ELECTION TYPE HETEROGENEITY
# ============================================================
cat("Generating Table 3: Election Type Heterogeneity...\n")

tab3_models <- list(
  "All" = results$m4,
  "Storting" = results$m_storting,
  "Local" = results$m_local
)

etable(results$m4, results$m_storting, results$m_local,
       headers = c("All", "Storting", "Local"),
       dict = c(treatedTRUE = "Subsidized municipality", log_pop = "Log population"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + ar2,
       tex = TRUE,
       file = file.path(tables_dir, "tab3_election_type.tex"),
       title = "Press Subsidies and Turnout by Election Type",
       label = "tab:election_type",
       notes = c("All specifications include year and county fixed effects.",
                 "Standard errors clustered at municipality level.")
)

# ============================================================
# TABLE 4: ROBUSTNESS
# ============================================================
cat("Generating Table 4: Robustness...\n")

tab4_models <- list(
  "Main" = results$m4,
  "Pop. quartile" = rob$r1_pop_quartile,
  "Trimmed" = rob$r3_trimmed,
  "Pre-2017" = rob$r7a_pre2017,
  "Post-2017" = rob$r7b_post2017
)

etable(results$m4, rob$r1_pop_quartile, rob$r3_trimmed,
       rob$r7a_pre2017, rob$r7b_post2017,
       headers = c("Main", "Pop Q.", "Trimmed", "Pre-2017", "Post-2017"),
       dict = c(treatedTRUE = "Subsidized municipality", log_pop = "Log population"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + ar2,
       tex = TRUE,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       title = "Robustness Checks",
       label = "tab:robustness",
       notes = c("All specifications include year and county fixed effects with clustered SEs.",
                 "Col.~2 adds population quartile FE. Col.~3 trims top/bottom 5\\\\% by population.",
                 "Cols.~4--5 split sample at 2017.")
)

# ============================================================
# TABLE 5: SUBSIDY INTENSITY
# ============================================================
cat("Generating Table 5: Subsidy Intensity...\n")

tab5_models <- list(
  "Binary" = results$m4,
  "NOK/capita" = results$m7,
  "Log(subsidy+1)" = results$m9,
  "N papers" = rob$r6_n_papers
)

etable(results$m4, results$m7, results$m9, rob$r6_n_papers,
       headers = c("Binary", "NOK/cap", "Log", "N papers"),
       dict = c(treatedTRUE = "Subsidized (binary)",
                subsidy_per_capita = "Subsidy per capita (NOK)",
                log_subsidy = "Log(subsidy per capita + 1)",
                n_subsidized_papers = "N subsidized papers",
                log_pop = "Log population"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10),
       fitstat = ~ n + ar2,
       tex = TRUE,
       file = file.path(tables_dir, "tab5_intensity.tex"),
       title = "Treatment Intensity: Subsidy Amount and Number of Papers",
       label = "tab:intensity",
       notes = c("Year and county FE with municipality-clustered SEs.",
                 "Mean subsidy per capita among treated: 179 NOK.")
)

# ============================================================
# TABLE F1: STANDARDIZED EFFECT SIZES (SDE) — MANDATORY APPENDIX
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Main coefficients
beta_all <- coef(results$m4)["treatedTRUE"]
se_all <- sqrt(vcov(results$m4)["treatedTRUE","treatedTRUE"])
sd_all <- results$sd_overall

beta_storting <- coef(results$m_storting)["treatedTRUE"]
se_storting <- sqrt(vcov(results$m_storting)["treatedTRUE","treatedTRUE"])
sd_storting <- results$sd_storting

beta_local <- coef(results$m_local)["treatedTRUE"]
se_local <- sqrt(vcov(results$m_local)["treatedTRUE","treatedTRUE"])
sd_local <- results$sd_local

# Subsidy per capita (continuous treatment)
beta_sub <- coef(results$m7)["subsidy_per_capita"]
se_sub <- sqrt(vcov(results$m7)["subsidy_per_capita","subsidy_per_capita"])
sd_x_sub <- sd(df$subsidy_per_capita, na.rm = TRUE)

# SDE calculations
sde_all <- beta_all / sd_all
sde_se_all <- se_all / sd_all
sde_storting <- beta_storting / sd_storting
sde_se_storting <- se_storting / sd_storting
sde_local <- beta_local / sd_local
sde_se_local <- se_local / sd_local
# Continuous: SDE = beta * SD(X) / SD(Y)
sde_sub <- beta_sub * sd_x_sub / sd_all
sde_se_sub <- se_sub * sd_x_sub / sd_all

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- data.frame(
  Outcome = c(
    "Turnout (all elections)",
    "Turnout (Storting)",
    "Turnout (local)",
    "Turnout (subsidy intensity)"
  ),
  Beta = c(sprintf("%.3f", beta_all), sprintf("%.3f", beta_storting),
           sprintf("%.3f", beta_local), sprintf("%.5f", beta_sub)),
  SE = c(sprintf("%.3f", se_all), sprintf("%.3f", se_storting),
         sprintf("%.3f", se_local), sprintf("%.5f", se_sub)),
  SD_Y = c(sprintf("%.3f", sd_all), sprintf("%.3f", sd_storting),
           sprintf("%.3f", sd_local), sprintf("%.3f", sd_all)),
  SDE = c(sprintf("%.3f", sde_all), sprintf("%.3f", sde_storting),
          sprintf("%.3f", sde_local), sprintf("%.3f", sde_sub)),
  SE_SDE = c(sprintf("%.3f", sde_se_all), sprintf("%.3f", sde_se_storting),
             sprintf("%.3f", sde_se_local), sprintf("%.3f", sde_se_sub)),
  Classification = c(classify_sde(sde_all), classify_sde(sde_storting),
                      classify_sde(sde_local), classify_sde(sde_sub))
)

# LaTeX SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Norway. ",
  "\\textbf{Research question:} Does government production subsidy (produksjonstilskudd) for local ",
  "newspapers affect voter turnout in Norwegian municipalities? ",
  "\\textbf{Policy mechanism:} The subsidy provides annual grants of 1--42 million NOK to newspapers ",
  "that are not the market leader in their municipality, conditional on 50\\% subscription-based ",
  "circulation and capped at 40\\% of operating costs, aiming to preserve media pluralism. ",
  "\\textbf{Outcome definition:} Municipality-level voter turnout (percentage of eligible voters casting ballots) ",
  "in Storting (national parliament) and municipal council elections. ",
  "\\textbf{Treatment:} Binary indicator for municipality having at least one newspaper receiving ",
  "produksjonstilskudd in 2021; continuous treatment measured as total subsidy per capita in NOK. ",
  "\\textbf{Data:} Statistics Norway (SSB) API tables 08243 and 09475 for turnout (2001--2025), ",
  "Medietilsynet produksjonstilskudd records (2021) for subsidy data; 356 municipalities, 1,930 observations. ",
  "\\textbf{Method:} OLS with year and county fixed effects, standard errors clustered at municipality level. ",
  "\\textbf{Sample:} Norwegian municipalities with non-missing turnout and population data, 2001--2025. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the cross-municipality ",
  "standard deviation of turnout. For continuous treatment (row 4), SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

tabF1_latex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste(apply(sde_rows, 1, function(row) paste(row, collapse = " & ")), collapse = " \\\\\n"),
  " \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1_latex, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated in: ", tables_dir, "\n")
cat("  tab1_summary.tex\n")
cat("  tab2_main.tex\n")
cat("  tab3_election_type.tex\n")
cat("  tab4_robustness.tex\n")
cat("  tab5_intensity.tex\n")
cat("  tabF1_sde.tex\n")
