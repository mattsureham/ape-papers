## 05_tables.R — Generate all tables for apep_0809
source("00_packages.R")
if (basename(getwd()) == "code") setwd("..")

dir.create("tables", showWarnings = FALSE)

main <- readRDS("data/main_results.rds")
robust <- readRDS("data/robustness_results.rds")
df <- readRDS("data/analysis_panel.rds")
df <- df |>
  mutate(
    high_exposure = share_construction + coalesce(share_agriculture, 0),
    post = as.integer(year >= 2007)
  )

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

summ <- df |>
  summarise(
    across(c(fn_vote_share, high_exposure, share_construction,
             bartik_exposure, unemp_rate, china_shock),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)),
           .names = "{.col}__{.fn}")
  ) |>
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_sep = "__") |>
  pivot_wider(names_from = stat, values_from = value)

var_labels <- c(
  "fn_vote_share" = "FN/RN Vote Share (\\%)",
  "high_exposure" = "Posted Worker Exposure (constr.+agric.)",
  "share_construction" = "Construction Employment Share",
  "bartik_exposure" = "Bartik Instrument",
  "unemp_rate" = "Unemployment Rate (\\%)",
  "china_shock" = "China Import Shock"
)

tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Mean & SD & Min & Max \\\\",
  "\\midrule"
)

for (v in names(var_labels)) {
  row <- summ |> filter(variable == v)
  if (nrow(row) == 1) {
    tab1_lines <- c(tab1_lines, sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f \\\\",
      var_labels[v], row$mean, row$sd, row$min, row$max
    ))
  }
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{4}{c}{%d} \\\\", nrow(df)),
  sprintf("D\\'epartements & \\multicolumn{4}{c}{%d} \\\\", n_distinct(df$dept_code)),
  sprintf("Elections & \\multicolumn{4}{c}{%d} \\\\", n_distinct(df$year)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Panel of 96 metropolitan French d\\'epartements across six presidential elections (1995--2022). Posted Worker Exposure is the sum of pre-enlargement construction and agriculture employment shares. The Bartik Instrument interacts these shares with national posted worker inflow changes by sector. China Import Shock is the interaction of national Chinese import penetration with pre-enlargement manufacturing share.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

# ============================================================================
# TABLE 2: Main Results
# ============================================================================
cat("\n=== Table 2: Main Results ===\n")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{EU Posted Worker Exposure and Far-Right Voting}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & OLS & FE & FE+Controls & DiD \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Bartik Exposure}} \\\\[3pt]"
)

# Extract coefficients
b1 <- coef(main$m1_ols)["bartik_exposure"]
se1 <- se(main$m1_ols)["bartik_exposure"]
b2 <- coef(main$m2_ols)["bartik_exposure"]
se2 <- se(main$m2_ols)["bartik_exposure"]
b3 <- coef(main$m3_ols)["bartik_exposure"]
se3 <- se(main$m3_ols)["bartik_exposure"]

# DiD coefficient
m_did <- feols(fn_vote_share ~ high_exposure:post | dept_code + year,
               data = df, cluster = ~dept_code)
b4 <- coef(m_did)["high_exposure:post"]
se4 <- se(m_did)["high_exposure:post"]

stars <- function(b, se) {
  p <- 2 * pnorm(-abs(b / se))
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  return("")
}

tab2_lines <- c(tab2_lines,
  sprintf("Bartik Exposure & %.3f%s & %.3f%s & %.3f%s & \\\\",
          b1, stars(b1, se1), b2, stars(b2, se2), b3, stars(b3, se3)),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & \\\\[3pt]", se1, se2, se3),
  sprintf("Exposure $\\times$ Post & & & & %.2f%s \\\\", b4, stars(b4, se4)),
  sprintf(" & & & & (%.2f) \\\\", se4),
  "\\midrule",
  sprintf("D\\'epartement FE & No & Yes & Yes & Yes \\\\"),
  sprintf("Year FE & No & Yes & Yes & Yes \\\\"),
  sprintf("Controls & No & No & Yes & No \\\\"),
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(main$m1_ols), nobs(main$m2_ols), nobs(main$m3_ols), nobs(m_did)),
  sprintf("$R^2$ (within) & & %.3f & %.3f & %.3f \\\\",
          fitstat(main$m2_ols, "wr2")$wr2,
          fitstat(main$m3_ols, "wr2")$wr2,
          fitstat(m_did, "wr2")$wr2),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is FN/RN first-round presidential vote share (\\%). Bartik Exposure is the shift-share instrument using pre-enlargement sectoral composition and national posted worker inflows. Exposure $\\times$ Post interacts pre-enlargement construction plus agriculture employment share with a post-2007 indicator. Controls include unemployment rate and China import shock. Standard errors clustered at d\\'epartement level in parentheses. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("  Written tables/tab2_main.tex\n")

# ============================================================================
# TABLE 3: Event Study
# ============================================================================
cat("\n=== Table 3: Event Study ===\n")

ec <- robust$event_coefs

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Posted Worker Exposure $\\times$ Election Year}",
  "\\label{tab:event}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Election Year & Coefficient & SE & Period \\\\",
  "\\midrule"
)

for (i in 1:nrow(ec)) {
  period <- ifelse(ec$year[i] <= 2002, "Pre-enlargement",
            ifelse(ec$year[i] <= 2007, "Post-A8", "Post-A8+A2"))
  if (ec$year[i] == 2002) {
    tab3_lines <- c(tab3_lines,
      sprintf("%d & [Reference] & & %s \\\\", ec$year[i], period))
  } else {
    s <- stars(ec$coef[i], ec$se[i])
    tab3_lines <- c(tab3_lines,
      sprintf("%d & %.2f%s & (%.2f) & %s \\\\", ec$year[i], ec$coef[i], s, ec$se[i], period))
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{3}{c}{%d} \\\\", 572),
  "D\\'epartement FE & \\multicolumn{3}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{3}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Coefficients from interacting pre-enlargement posted worker exposure (construction + agriculture share) with election year indicators. Reference year is 2002 (last pre-enlargement election). Standard errors clustered at d\\'epartement level. The pre-enlargement coefficient (1995) tests for differential pre-trends. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_event.tex")
cat("  Written tables/tab3_event.tex\n")

# ============================================================================
# TABLE 4: Robustness
# ============================================================================
cat("\n=== Table 4: Robustness ===\n")

# Sector decomposition + controls + clustering
tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Construction & Agriculture & Manufacturing & China & No Paris/ \\\\",
  " & Only & Only & (Placebo) & Control & Corsica \\\\",
  "\\midrule"
)

b_c <- coef(robust$m_constr)[grep("share_construction", names(coef(robust$m_constr)))]
se_c <- se(robust$m_constr)[grep("share_construction", names(se(robust$m_constr)))]

b_a <- coef(robust$m_agric)[1]
se_a <- se(robust$m_agric)[1]

b_m <- coef(robust$m_manuf)[1]
se_m <- se(robust$m_manuf)[1]

b_ch <- coef(robust$m_china)[grep("high_exposure", names(coef(robust$m_china)))]
se_ch <- se(robust$m_china)[grep("high_exposure", names(se(robust$m_china)))]

b_no <- coef(robust$m_no_outlier)[1]
se_no <- se(robust$m_no_outlier)[1]

tab4_lines <- c(tab4_lines,
  sprintf("Sector $\\times$ Post & %.1f%s & %.1f%s & %.1f%s & %.1f%s & %.1f%s \\\\",
          b_c, stars(b_c, se_c), b_a, stars(b_a, se_a), b_m, stars(b_m, se_m),
          b_ch, stars(b_ch, se_ch), b_no, stars(b_no, se_no)),
  sprintf(" & (%.1f) & (%.1f) & (%.1f) & (%.1f) & (%.1f) \\\\",
          se_c, se_a, se_m, se_ch, se_no),
  "\\midrule",
  "D\\'epartement FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %d & %d & %d & %d & %d \\\\",
          nobs(robust$m_constr), nobs(robust$m_agric), nobs(robust$m_manuf),
          nobs(robust$m_china), nobs(robust$m_no_outlier)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Dependent variable is FN/RN first-round vote share (\\%). Columns (1)--(3) decompose exposure by sector: construction and agriculture shares predict far-right support, while manufacturing share (column 3) serves as a within-d\\'epartement placebo since posted workers concentrate in non-tradable sectors. Column (4) adds the China import shock as a control. Column (5) excludes Paris and Corsica. Standard errors clustered at d\\'epartement level. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robust.tex")
cat("  Written tables/tab4_robust.tex\n")

# ============================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# ============================================================================
cat("\n=== Table F1: Standardized Effect Size ===\n")

# Main specification: DiD (high_exposure × post)
m_main <- feols(fn_vote_share ~ high_exposure:post | dept_code + year,
                data = df, cluster = ~dept_code)

# Pre-treatment SD of FN vote share (1995 + 2002)
sd_y_pre <- sd(df$fn_vote_share[df$year <= 2002])
sd_x <- sd(df$high_exposure, na.rm = TRUE)

# For continuous treatment: SDE = β × SD(X) / SD(Y)
beta_main <- coef(m_main)["high_exposure:post"]
se_main <- se(m_main)["high_exposure:post"]
sde_main <- beta_main * sd_x / sd_y_pre
se_sde_main <- se_main * sd_x / sd_y_pre

# Classification
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  sign <- ifelse(sde >= 0, "positive", "negative")
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(paste0("Small ", sign))
  if (abs_sde < 0.15) return(paste0("Moderate ", sign))
  return(paste0("Large ", sign))
}

# Build SDE table
sde_rows <- tibble(
  outcome = "FN/RN Vote Share",
  beta = beta_main,
  se = se_main,
  sd_y = sd_y_pre,
  sde = sde_main,
  se_sde = se_sde_main,
  classification = classify_sde(sde_main)
)

cat(sprintf("  β = %.2f, SE = %.2f, SD(Y) = %.2f, SD(X) = %.4f\n",
            beta_main, se_main, sd_y_pre, sd_x))
cat(sprintf("  SDE = %.3f, Classification: %s\n", sde_main, sde_rows$classification))

# Generate LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France. ",
  "\\textbf{Research question:} Does increased labor market competition from EU posted workers, driven by EU enlargement in 2004 and 2007, cause higher support for the far-right Front National/Rassemblement National in French d\\'epartements? ",
  "\\textbf{Policy mechanism:} EU enlargement in 2004 (A8 accession) and 2007 (A2 accession) dramatically expanded the pool of workers who could be temporarily posted to France under the EU Posted Workers Directive (96/71/EC), creating labor market competition concentrated in non-tradable sectors (construction, agriculture) where native workers cannot relocate to avoid competition. ",
  "\\textbf{Outcome definition:} First-round presidential election vote share (percent of expressed votes) for the Front National (1995--2012) or Rassemblement National (2017--2022) candidate. ",
  "\\textbf{Treatment:} Continuous; pre-enlargement d\\'epartement-level employment share in construction plus agriculture (mean = 0.11, SD = 0.029). ",
  "\\textbf{Data:} Eurostat regional accounts (employment by NACE sector, NUTS2, 2000--2004), Minist\\`ere de l'Int\\'erieur/data.gouv.fr presidential election results (d\\'epartement level, 1995--2022), DARES posted worker declarations (national by sector, 2000--2022). Panel: 96 d\\'epartements $\\times$ 6 elections = 572 observations. ",
  "\\textbf{Method:} Difference-in-differences interacting pre-enlargement sectoral exposure with post-2007 indicator, d\\'epartement and election year fixed effects, standard errors clustered at d\\'epartement level. ",
  "\\textbf{Sample:} 96 metropolitan French d\\'epartements (excluding overseas territories); all six first-round presidential elections 1995--2022. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "(1995--2002) standard deviation and SD($X$) is the cross-sectional standard deviation of exposure. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("%s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
          sde_rows$outcome, sde_rows$beta, sde_rows$se, sde_rows$sd_y,
          sde_rows$sde, sde_rows$se_sde, sde_rows$classification),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
print(list.files("tables"))
