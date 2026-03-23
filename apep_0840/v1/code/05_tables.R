## 05_tables.R — Generate all LaTeX tables
## apep_0840: Competing News IV and Swiss Referendum Turnout

source("00_packages.R")

load("../data/regression_results.RData")
load("../data/robustness_results.RData")
summ <- fread("../data/summary_stats.csv")

dir.create("../tables", showWarnings = FALSE)

# Force modelsummary to use kableExtra backend (not tabularray/tinytable)
options("modelsummary_format_numeric_latex" = "plain")
options("modelsummary_factory_latex" = "kableExtra")

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================

cat("Generating Table 1: Summary Statistics...\n")

summ[, `:=`(
  Mean = formatC(Mean, format = "f", digits = 2),
  SD = formatC(SD, format = "f", digits = 2),
  Min = formatC(Min, format = "f", digits = 2),
  Max = formatC(Max, format = "f", digits = 2),
  N = formatC(N, format = "d", big.mark = ",")
)]

tab1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Variable & N & Mean & SD & Min & Max \\\\",
  "\\midrule",
  "\\textit{Panel A: Referendum outcomes} & & & & & \\\\",
  paste(apply(summ[1:2,], 1, function(r) {
    paste(r["Variable"], "&", r["N"], "&", r["Mean"], "&", r["SD"], "&", r["Min"], "&", r["Max"], "\\\\")
  }), collapse = "\n"),
  "\\addlinespace",
  "\\textit{Panel B: Earthquake salience (instrument)} & & & & & \\\\",
  paste(apply(summ[3:5,], 1, function(r) {
    paste(r["Variable"], "&", r["N"], "&", r["Mean"], "&", r["SD"], "&", r["Min"], "&", r["Max"], "\\\\")
  }), collapse = "\n"),
  "\\addlinespace",
  "\\textit{Panel C: Municipality characteristics} & & & & & \\\\",
  paste(apply(summ[6:7,], 1, function(r) {
    paste(r["Variable"], "&", r["N"], "&", r["Mean"], "&", r["SD"], "&", r["Min"], "&", r["Max"], "\\\\")
  }), collapse = "\n"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Sample covers 30 Swiss federal referendum dates (2015--2024) at the municipality level for French- and German-speaking regions. Earthquake salience is the magnitude-weighted inverse-distance score of global M5.0+ earthquakes to language-specific media-market centroids in the 7 days before each vote. $N$ = municipality $\\times$ ballot-item observations.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Saved tab1_summary.tex\n")

# ============================================================================
# TABLE 2: Reduced Form — Earthquake Salience and Turnout
# ============================================================================

cat("Generating Table 2: Reduced-form results...\n")

cm <- c(
  "salience_std" = "Earthquake salience (std.)",
  "log_salience" = "Log(salience + 1)",
  "salience_large_std" = "Large EQ salience (std.)",
  "n_earthquakes" = "No. earthquakes",
  "max_magnitude" = "Max magnitude"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) formatC(x, format = "d", big.mark = ",")),
  list("raw" = "r.squared", "clean" = "R$^2$", "fmt" = 3),
  list("raw" = "adj.r.squared", "clean" = "Adj. R$^2$", "fmt" = 3)
)

modelsummary(
  list("(1)" = ols1, "(2)" = ols2, "(3)" = ols3, "(4)" = ols4),
  output = "../tables/tab2_reduced_form.tex",
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Foreign Earthquakes and Referendum Turnout: Reduced-Form Estimates \\label{tab:reduced}",
  notes = list(
    "Standard errors multi-way clustered by vote date and language region in parentheses.",
    "Earthquake salience is standardized (mean 0, SD 1). A one-SD increase represents a shift from a typical pre-vote seismic period to one with substantially more earthquake activity near the municipality's media market.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$"
  ),
  add_rows = data.frame(
    term = c("Municipality FE", "Vote-date FE", "Language $\\times$ Year FE"),
    `X1.` = c("", "", ""),
    `X2.` = c("$\\checkmark$", "", ""),
    `X3.` = c("$\\checkmark$", "$\\checkmark$", ""),
    `X4.` = c("$\\checkmark$", "$\\checkmark$", "$\\checkmark$")
  ),
  escape = FALSE
)

cat("  Saved tab2_reduced_form.tex\n")

# ============================================================================
# TABLE 3: Alternative Instruments
# ============================================================================

cat("Generating Table 3: Alternative instruments...\n")

cm3 <- c(
  "log_salience" = "Log(salience + 1)",
  "salience_large_std" = "Large EQ salience (std.)",
  "n_earthquakes:is_french" = "EQ count $\\times$ French",
  "salience_score" = "Raw salience score"
)

modelsummary(
  list("Log" = ols_log, "Large EQ" = ols_large,
       "Count$\\times$Fr" = ols_interact, "Raw" = ols_raw),
  output = "../tables/tab3_instruments.tex",
  coef_map = cm3,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Alternative Earthquake Measures and Turnout \\label{tab:altinst}",
  notes = list(
    "Standard errors multi-way clustered by vote date and language region in parentheses.",
    "All specifications include municipality and vote-date fixed effects.",
    "Col. (1): Log of language-specific salience + 1. Col. (2): Only M6.5+ earthquakes.",
    "Col. (3): Earthquake count interacted with French dummy. Col. (4): Raw (unstandardized) salience.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$"
  ),
  add_rows = data.frame(
    term = c("Municipality FE", "Vote-date FE"),
    `Log` = c("$\\checkmark$", "$\\checkmark$"),
    `Large.EQ` = c("$\\checkmark$", "$\\checkmark$"),
    `Count..Fr` = c("$\\checkmark$", "$\\checkmark$"),
    `Raw` = c("$\\checkmark$", "$\\checkmark$")
  ),
  escape = FALSE
)

cat("  Saved tab3_instruments.tex\n")

# ============================================================================
# TABLE 4: Heterogeneity and Mechanisms
# ============================================================================

cat("Generating Table 4: Heterogeneity...\n")

modelsummary(
  list("High Sal." = het_high, "Low Sal." = het_low, "Yes \\%" = yes1),
  output = "../tables/tab4_heterogeneity.tex",
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Heterogeneity by Ballot-Item Salience and Effect on Vote Outcomes \\label{tab:het}",
  notes = list(
    "Standard errors multi-way clustered by vote date and language region in parentheses.",
    "Cols. (1)--(2): Turnout as DV, split at median item salience (measured by average turnout for the item).",
    "Col. (3): Yes vote share as DV. All specifications include municipality and vote-date FE.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$"
  ),
  add_rows = data.frame(
    term = c("Municipality FE", "Vote-date FE", "Dep. variable"),
    `High.Sal.` = c("$\\checkmark$", "$\\checkmark$", "Turnout"),
    `Low.Sal.` = c("$\\checkmark$", "$\\checkmark$", "Turnout"),
    `Yes..` = c("$\\checkmark$", "$\\checkmark$", "Yes \\%")
  ),
  escape = FALSE
)

cat("  Saved tab4_heterogeneity.tex\n")

# ============================================================================
# TABLE 5: Robustness
# ============================================================================

cat("Generating Table 5: Robustness...\n")

rob_cm <- c(
  "salience_std" = "Earthquake salience (std.)",
  "salience_14d_std" = "Earthquake salience 14-day (std.)",
  "placebo_std" = "Placebo salience (wrong language, std.)"
)

modelsummary(
  list("14-Day" = rob_14d, "Placebo" = rob_placebo,
       "German" = rob_de, "French" = rob_fr, "No COVID" = rob_nocovid),
  output = "../tables/tab5_robustness.tex",
  coef_map = rob_cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Robustness: Alternative Windows, Placebo, Subsamples \\label{tab:robust}",
  notes = list(
    "Standard errors clustered by vote date (and language region where applicable) in parentheses.",
    "Col. (1): 14-day pre-vote window. Col. (2): Placebo using wrong-language salience.",
    "Cols. (3)--(4): Separate estimates by language region. Col. (5): Excluding 2020--2021 (COVID).",
    "All specifications include municipality and vote-date fixed effects.",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$"
  ),
  add_rows = data.frame(
    term = c("Municipality FE", "Vote-date FE"),
    `X14.Day` = c("$\\checkmark$", "$\\checkmark$"),
    `Placebo` = c("$\\checkmark$", "$\\checkmark$"),
    `German` = c("$\\checkmark$", "$\\checkmark$"),
    `French` = c("$\\checkmark$", "$\\checkmark$"),
    `No.COVID` = c("$\\checkmark$", "$\\checkmark$")
  ),
  escape = FALSE
)

cat("  Saved tab5_robustness.tex\n")

# ============================================================================
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ============================================================================

cat("Generating Table F1: SDE...\n")

# Main effect: salience_std → turnout (ols3)
beta_turnout <- coef(ols3)["salience_std"]
se_turnout <- sqrt(vcov(ols3)["salience_std", "salience_std"])
sd_turnout <- sd(panel_clean$turnout_pct, na.rm = TRUE)
# Continuous treatment (already standardized to SD=1)
sde_turnout <- beta_turnout / sd_turnout
se_sde_turnout <- abs(se_turnout / sd_turnout)

# Yes vote share
beta_yes <- coef(yes1)["salience_std"]
se_yes <- sqrt(vcov(yes1)["salience_std", "salience_std"])
sd_yes <- sd(panel_clean$yes_pct, na.rm = TRUE)
sde_yes <- beta_yes / sd_yes
se_sde_yes <- abs(se_yes / sd_yes)

# Low salience items
beta_low <- coef(het_low)["salience_std"]
se_low <- sqrt(vcov(het_low)["salience_std", "salience_std"])
sd_low <- sd(panel_clean[high_salience == FALSE]$turnout_pct, na.rm = TRUE)
sde_low <- beta_low / sd_low
se_sde_low <- abs(se_low / sd_low)

classify_sde <- function(sde) {
  if (is.na(sde)) return("N/A")
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

sde_rows <- data.frame(
  Outcome = c("Turnout (\\%)", "Yes vote share (\\%)", "Turnout, low-salience items"),
  Beta = c(formatC(beta_turnout, format = "f", digits = 3),
           formatC(beta_yes, format = "f", digits = 3),
           formatC(beta_low, format = "f", digits = 3)),
  SE = c(formatC(se_turnout, format = "f", digits = 3),
         formatC(se_yes, format = "f", digits = 3),
         formatC(se_low, format = "f", digits = 3)),
  SD_Y = c(formatC(sd_turnout, format = "f", digits = 2),
           formatC(sd_yes, format = "f", digits = 2),
           formatC(sd_low, format = "f", digits = 2)),
  SDE = c(formatC(sde_turnout, format = "f", digits = 4),
          formatC(sde_yes, format = "f", digits = 4),
          formatC(sde_low, format = "f", digits = 4)),
  SE_SDE = c(formatC(se_sde_turnout, format = "f", digits = 4),
             formatC(se_sde_yes, format = "f", digits = 4),
             formatC(se_sde_low, format = "f", digits = 4)),
  Classification = c(classify_sde(sde_turnout),
                     classify_sde(sde_yes),
                     classify_sde(sde_low)),
  stringsAsFactors = FALSE
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does exogenous competing news from foreign earthquakes reduce voter turnout in Swiss federal referendums? ",
  "\\textbf{Policy mechanism:} Foreign earthquakes attract media coverage in language-specific news markets ",
  "(French-language media covers earthquakes near Francophone regions more intensely; German-language media covers those near Germanic regions), ",
  "crowding out referendum coverage and raising information costs for voters. ",
  "\\textbf{Outcome definition:} Turnout is the percentage of eligible voters casting a ballot in each municipality for each referendum item; ",
  "yes vote share is the percentage of valid ballots cast in favor. ",
  "\\textbf{Treatment:} Continuous; earthquake salience is a magnitude-weighted inverse-distance score of global M5.0+ earthquakes ",
  "to language-specific media-market centroids, standardized to mean zero and unit variance. ",
  "\\textbf{Data:} Swiss Federal Statistical Office via swissdd (referendum results) and USGS FDSNWS (earthquake catalog), ",
  "2015--2024, municipality $\\times$ ballot-item level, approximately 170,000 observations. ",
  "\\textbf{Method:} OLS with municipality and vote-date fixed effects; standard errors multi-way clustered ",
  "by vote date and language region. ",
  "\\textbf{Sample:} French- and German-speaking Swiss municipalities; Italian-speaking municipalities excluded (small sample). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ since treatment is already standardized (SD$(X) = 1$). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  paste(apply(sde_rows, 1, function(r) {
    paste(r["Outcome"], "&", r["Beta"], "&", r["SE"], "&", r["SD_Y"],
          "&", r["SDE"], "&", r["SE_SDE"], "&", r["Classification"], "\\\\")
  }), collapse = "\n"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
