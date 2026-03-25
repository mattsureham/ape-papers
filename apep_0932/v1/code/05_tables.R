# 05_tables.R — Generate all tables for paper
# apep_0932: New Deal Work Relief and Racial Occupational Mobility

source("00_packages.R")

cat("Loading data and models...\n")
df <- readRDS("../data/analysis_sample.rds")
load("../data/main_models.RData")
load("../data/robustness_models.RData")

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================
cat("\nGenerating Table 1: Summary Statistics...\n")

# Panel A: Full sample by race
summ <- df[, .(
  `Occ. Score 1920` = sprintf("%.2f", mean(occscore_1920, na.rm = TRUE)),
  `Occ. Score 1930` = sprintf("%.2f", mean(occscore_1930, na.rm = TRUE)),
  `Occ. Score 1940` = sprintf("%.2f", mean(occscore_1940, na.rm = TRUE)),
  `$\\Delta$ Occ. 1930--40` = sprintf("%.2f", mean(d_occscore_30_40, na.rm = TRUE)),
  `SEI 1930` = sprintf("%.2f", mean(sei_1930, na.rm = TRUE)),
  `SEI 1940` = sprintf("%.2f", mean(sei_1940, na.rm = TRUE)),
  `Age 1930` = sprintf("%.1f", mean(age_1930, na.rm = TRUE)),
  `Farm Worker` = sprintf("%.3f", mean(farm_1930 == 2, na.rm = TRUE)),
  `ND Spending p.c.` = sprintf("%.1f", mean(ndexp_pc, na.rm = TRUE)),
  N = format(.N, big.mark = ",")
), by = .(Race = ifelse(black == 1, "Black", "White"))]

# Transpose for LaTeX
vars <- setdiff(names(summ), "Race")
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & White & Black \\\\",
  "\\midrule"
)
for (v in vars) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s \\\\",
                                       gsub("\\$", "$", v, fixed = FALSE),
                                       summ[Race == "White", get(v)],
                                       summ[Race == "Black", get(v)]))
}
tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Sample consists of men aged 18--55 in 1930, linked across the 1920, 1930, and 1940 full-count censuses via the IPUMS Machine Learning Panel (MLP v2). Occupational score (OCCSCORE) is the Duncan socioeconomic index mapping 1950-coded occupations to median income. New Deal spending per capita is total federal grants (WPA, FERA, CWA, and other programs) from Fishback, Kantor, and Wallis (2003) at the county level. Farm Worker = share in agricultural occupations in 1930.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# =============================================================================
# TABLE 2: Main DDD Results
# =============================================================================
cat("Generating Table 2: Main Results...\n")

# Extract coefficients manually for clean table
extract_coef <- function(model, pattern = "black.*ndexp|black.*high") {
  cn <- grep(pattern, names(coef(model)), value = TRUE)
  if (length(cn) == 0) return(list(est = NA, se = NA, p = NA))
  est <- coef(model)[cn[1]]
  se <- sqrt(vcov(model)[cn[1], cn[1]])
  p <- 2 * pnorm(-abs(est / se))
  list(est = est, se = se, p = p)
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

r1 <- extract_coef(m1, "black.*high")
r2 <- extract_coef(m2)
r3 <- extract_coef(m3)
r4 <- extract_coef(m4)

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{New Deal Spending and the Black--White Occupational Mobility Gap}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Dep. var.: $\\Delta$ Occupational Score, 1930--1940}} \\\\[6pt]",
  sprintf("Black $\\times$ ND Spending & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", r1$est), stars(r1$p),
          sprintf("%.4f", r2$est), stars(r2$p),
          sprintf("%.4f", r3$est), stars(r3$p),
          sprintf("%.4f", r4$est), stars(r4$p)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          r1$se, r2$se, r3$se, r4$se),
  "State FE & Yes & & & \\\\",
  "County FE & & Yes & Yes & Yes \\\\",
  "Age FE & Yes & Yes & Yes & Yes \\\\",
  "Occupation FE (1930) & & & Yes & Yes \\\\",
  "Nativity + Marital FE & & & & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m4), big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m4, "r2")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports OLS estimates of the triple-difference specification where the dependent variable is the change in occupational score (OCCSCORE) between 1930 and 1940 for individual men linked across the full-count censuses via the IPUMS MLP v2 crosswalk. Column (1) uses a binary high-ND indicator (top tercile of per capita New Deal spending); columns (2)--(4) use standardized continuous spending. Standard errors clustered at the 1930 county level in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# =============================================================================
# TABLE 3: Heterogeneity — South vs Non-South, Farm vs Non-Farm
# =============================================================================
cat("Generating Table 3: Heterogeneity...\n")

rs <- extract_coef(m_south)
rn <- extract_coef(m_north)
rf <- extract_coef(m_farm)
rnf <- extract_coef(m_nonfarm)

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Heterogeneity: Geography and Occupation}",
  "\\label{tab:hetero}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & South & Non-South & Farm & Non-Farm \\\\",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Dep. var.: $\\Delta$ Occupational Score, 1930--1940}} \\\\[6pt]",
  sprintf("Black $\\times$ ND Spending & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", rs$est), stars(rs$p),
          sprintf("%.4f", rn$est), stars(rn$p),
          sprintf("%.4f", rf$est), stars(rf$p),
          sprintf("%.4f", rnf$est), stars(rnf$p)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          rs$se, rn$se, rf$se, rnf$se),
  "County FE & Yes & Yes & Yes & Yes \\\\",
  "Age FE & Yes & Yes & Yes & Yes \\\\",
  "Occupation FE (1930) & Yes & Yes & & \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(nobs(m_south), big.mark = ","),
          format(nobs(m_north), big.mark = ","),
          format(nobs(m_farm), big.mark = ","),
          format(nobs(m_nonfarm), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Columns (1)--(2) split by Census region: South includes former Confederate states plus border states. Columns (3)--(4) split by 1930 farm worker status. All specifications include county and age fixed effects with standard errors clustered at the county level. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, file.path(tables_dir, "tab3_heterogeneity.tex"))

# =============================================================================
# TABLE 4: Robustness — Pre-trend, Placebo, Alternative Outcomes
# =============================================================================
cat("Generating Table 4: Robustness...\n")

rpre <- extract_coef(m_pre)
rwomen <- extract_coef(m_women)
rsei <- extract_coef(m_sei)
rwage <- extract_coef(m_wage)
rmove <- extract_coef(m_move)

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  " & Pre-Trend & Placebo & $\\Delta$ SEI & Log Wage & Moved \\\\",
  " & 1920--30 & Women & 1930--40 & 1940 & 1930--40 \\\\",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  "\\midrule",
  sprintf("Black $\\times$ ND & %s%s & %s%s & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", rpre$est), stars(rpre$p),
          sprintf("%.4f", rwomen$est), stars(rwomen$p),
          sprintf("%.4f", rsei$est), stars(rsei$p),
          sprintf("%.4f", rwage$est), stars(rwage$p),
          sprintf("%.4f", rmove$est), stars(rmove$p)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[6pt]",
          rpre$se, rwomen$se, rsei$se, rwage$se, rmove$se),
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m_pre), big.mark = ","),
          format(nobs(m_women), big.mark = ","),
          format(nobs(m_sei), big.mark = ","),
          format(nobs(m_wage), big.mark = ","),
          format(nobs(m_move), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Column (1) tests parallel pre-trends using 1920--1930 occupational score changes as outcome. Column (2) uses women as a placebo group (WPA work relief was overwhelmingly male). Columns (3)--(5) use alternative outcomes: socioeconomic index change, log 1940 wage income, and interstate migration. All specifications include county and age FE; columns (1) and (3)--(5) also include 1930 occupation FE. SEs clustered at the county level. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))

# =============================================================================
# TABLE F1: Standardized Effect Size (SDE) — MANDATORY APPENDIX
# =============================================================================
cat("Generating Table F1: SDE...\n")

# Calculate SDE for main outcomes
sd_y_occ <- sd(df[, d_occscore_30_40], na.rm = TRUE)
sd_y_sei <- sd(df[, d_sei_30_40], na.rm = TRUE)
sd_y_wage <- sd(df[!is.na(log_incwage), log_incwage], na.rm = TRUE)
sd_y_move <- sd(df[, moved_30_40], na.rm = TRUE)
sd_x <- 1  # Already standardized

# Main results (from m3 — preferred specification)
get_sde <- function(model, sd_y, pattern = "black.*ndexp") {
  cn <- grep(pattern, names(coef(model)), value = TRUE)
  if (length(cn) == 0) return(list(beta = NA, se = NA, sde = NA, se_sde = NA, class = NA))
  beta <- coef(model)[cn[1]]
  se_beta <- sqrt(vcov(model)[cn[1], cn[1]])
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  # Classification
  cl <- if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
  list(beta = beta, se = se_beta, sd_y = sd_y, sde = sde, se_sde = se_sde, class = cl)
}

# Panel A: Pooled
sde_occ <- get_sde(m3, sd_y_occ)
sde_sei <- get_sde(m_sei, sd_y_sei)
sde_wage <- get_sde(m_wage, sd_y_wage)
sde_move <- get_sde(m_move, sd_y_move)

# Panel B: Heterogeneous (South vs Non-South)
sde_south <- get_sde(m_south, sd(df[south == 1, d_occscore_30_40], na.rm = TRUE))
sde_north <- get_sde(m_north, sd(df[south == 0, d_occscore_30_40], na.rm = TRUE))

# Format SDE table row
sde_row <- function(label, s) {
  sprintf("%s & %.4f & %.4f & %.2f & %.4f & %.4f & %s \\\\",
          label, s$beta, s$se, s$sd_y, s$sde, s$se_sde, s$class)
}

# SDE notes (for oracle training data)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did New Deal work relief programs (WPA/FERA, 1933--1943) differentially affect Black versus White men's occupational mobility during the Great Depression? ",
  "\\textbf{Policy mechanism:} Federal work relief programs disbursed approximately \\$11 billion across 3,000 counties, providing temporary public employment during the Depression; federal law prohibited racial discrimination but local administrators controlled eligibility, creating county-level variation in de facto racial access. ",
  "\\textbf{Outcome definition:} Change in occupational income score (OCCSCORE, mapping 1950-coded occupations to median income, range 0--80) between 1930 and 1940 censuses. ",
  "\\textbf{Treatment:} Continuous county-level per capita New Deal grants (standardized, mean zero, SD one). ",
  "\\textbf{Data:} IPUMS MLP v2 linked full-count census records (1920--1930--1940), Fishback--Kantor--Wallis county-level New Deal spending, men aged 18--55 in 1930. ",
  "\\textbf{Method:} Triple-difference (race $\\times$ ND spending $\\times$ post), county and occupation FE, SEs clustered at county. ",
  "\\textbf{Sample:} Men aged 18--55 in 1930 with valid occupational scores in both 1930 and 1940, linked via MLP crosswalk, in counties with Fishback spending data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[4pt]",
  sde_row("$\\Delta$ Occ. Score", sde_occ),
  sde_row("$\\Delta$ SEI", sde_sei),
  sde_row("Log Wage (1940)", sde_wage),
  sde_row("Interstate Move", sde_move),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Geography)}} \\\\[4pt]",
  sde_row("$\\Delta$ Occ. Score (South)", sde_south),
  sde_row("$\\Delta$ Occ. Score (Non-South)", sde_north),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tabF1_lines, file.path(tables_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
cat(sprintf("  Tables written to: %s/\n", normalizePath(tables_dir)))
