# =============================================================================
# 05_tables.R — Generate all LaTeX tables including SDE appendix
# =============================================================================

source("00_packages.R")

cat("=== Loading results ===\n")
panel <- readRDS("../data/analysis_panel.rds")
setDT(panel)
main <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")
excluded <- panel[excluded_start == TRUE]

# =========================================================================
# TABLE 1: Summary Statistics
# =========================================================================
cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-SSA period stats by race for excluded workers
pre_excluded <- excluded[post_ssa == 0]

summ_tab <- pre_excluded[, .(
  N = .N,
  Mean_Age = round(mean(age_start), 1),
  Pct_Domestic = round(mean(excl_type == "domestic") * 100, 1),
  Pct_FarmLabor = round(mean(excl_type == "farm_labor") * 100, 1),
  Pct_Farmer = round(mean(excl_type == "farmer") * 100, 1),
  Mean_SEI = round(mean(sei_start, na.rm = TRUE), 1),
  Switch_Rate = round(mean(switch_to_covered) * 100, 1),
  Pct_South = round(mean(south) * 100, 1),
  Pct_Mover = round(mean(mover, na.rm = TRUE) * 100, 1)
), by = .(Race = fifelse(black == 1, "Black", "White"))]

# Create LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Workers in SSA-Excluded Occupations, 1920}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & White & Black \\\\",
  "\\hline",
  sprintf("Observations & %s & %s \\\\", format(summ_tab[Race == "White", N], big.mark = ","),
    format(summ_tab[Race == "Black", N], big.mark = ",")),
  sprintf("Mean age & %.1f & %.1f \\\\", summ_tab[Race == "White", Mean_Age],
    summ_tab[Race == "Black", Mean_Age]),
  sprintf("\\%% Domestic service & %.1f & %.1f \\\\", summ_tab[Race == "White", Pct_Domestic],
    summ_tab[Race == "Black", Pct_Domestic]),
  sprintf("\\%% Farm laborers & %.1f & %.1f \\\\", summ_tab[Race == "White", Pct_FarmLabor],
    summ_tab[Race == "Black", Pct_FarmLabor]),
  sprintf("\\%% Farmers/farm managers & %.1f & %.1f \\\\", summ_tab[Race == "White", Pct_Farmer],
    summ_tab[Race == "Black", Pct_Farmer]),
  sprintf("Mean SEI score & %.1f & %.1f \\\\", summ_tab[Race == "White", Mean_SEI],
    summ_tab[Race == "Black", Mean_SEI]),
  sprintf("Switch to covered occ. (\\%%) & %.1f & %.1f \\\\", summ_tab[Race == "White", Switch_Rate],
    summ_tab[Race == "Black", Switch_Rate]),
  sprintf("\\%% in South & %.1f & %.1f \\\\", summ_tab[Race == "White", Pct_South],
    summ_tab[Race == "Black", Pct_South]),
  sprintf("\\%% interstate mover & %.1f & %.1f \\\\", summ_tab[Race == "White", Pct_Mover],
    summ_tab[Race == "Black", Pct_Mover]),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Sample restricted to working-age individuals (15--64) in SSA-excluded occupations (agricultural, domestic service) in the 1920 Census, linked across three censuses (1920--1930--1940) via the IPUMS Machine Learning Panel. SEI is the Duncan Socioeconomic Index. ``Switch to covered occupation'' indicates transition from an excluded to a covered occupation during the 1920--1930 decade.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, "../tables/tab1_summary.tex")

# =========================================================================
# TABLE 2: Main DiD Results
# =========================================================================
cat("=== Generating Table 2: Main Results ===\n")

get_coef_row <- function(model, var_name, label) {
  b <- coef(model)[var_name]
  s <- se(model)[var_name]
  p <- pvalue(model)[var_name]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  sprintf("%s & %.4f%s \\\\", label, b, stars)
}

get_se_row <- function(model, var_name) {
  s <- se(model)[var_name]
  sprintf(" & (%.4f) \\\\", s)
}

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Insured Escape: Differential Occupational Sorting After the 1935 Social Security Act}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & All Excluded & All Excluded & All Excluded & All Excluded \\\\",
  "\\hline"
)

# Extract from etable-style output manually
m1 <- main$m1; m2 <- main$m2; m3 <- main$m3; m4 <- main$m4

# Black × Post-SSA (key coefficient)
b1 <- coef(m1)["black:post_ssa"]; s1 <- se(m1)["black:post_ssa"]; p1 <- pvalue(m1)["black:post_ssa"]
b2 <- coef(m2)["black:post_ssa"]; s2 <- se(m2)["black:post_ssa"]; p2 <- pvalue(m2)["black:post_ssa"]
b3 <- coef(m3)["black:excluded_startTRUE:post_ssa"]; s3 <- se(m3)["black:excluded_startTRUE:post_ssa"]; p3 <- pvalue(m3)["black:excluded_startTRUE:post_ssa"]
b4 <- coef(m4)["black:post_ssa"]; s4 <- se(m4)["black:post_ssa"]; p4 <- pvalue(m4)["black:post_ssa"]

stars <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))

tab2_lines <- c(tab2_lines,
  sprintf("Black $\\times$ Post-SSA & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
    b1, stars(p1), b2, stars(p2), b3, stars(p3), b4, stars(p4)),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ \\\\", s1, s2, s3, s4),
  "\\addlinespace",
  # Black main effect
  sprintf("Black & $%.4f%s$ & $%.4f%s$ & & $%.4f%s$ \\\\",
    coef(m1)["black"], stars(pvalue(m1)["black"]),
    coef(m2)["black"], stars(pvalue(m2)["black"]),
    coef(m4)["black"], stars(pvalue(m4)["black"])),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & & $(%.4f)$ \\\\",
    se(m1)["black"], se(m2)["black"], se(m4)["black"]),
  "\\addlinespace",
  "\\hline",
  "Demographic controls & No & Yes & No & Yes \\\\",
  sprintf("Sample & Excluded & Excluded & Full panel & Excluded \\\\"),
  "State FE & Yes & Yes & Yes & \\\\",
  "State $\\times$ Decade FE & No & No & No & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s \\\\",
    format(nobs(m1), big.mark = ","), format(nobs(m2), big.mark = ","),
    format(nobs(m3), big.mark = ","), format(nobs(m4), big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
    r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m4, "r2")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column reports OLS estimates. The dependent variable is an indicator for switching from an SSA-excluded occupation (agricultural, domestic) to a covered occupation during a decade transition. The sample is stacked across two transitions: 1920$\\to$1930 (pre-SSA) and 1930$\\to$1940 (post-SSA). Column (3) uses the full panel including covered-occupation workers and reports the triple interaction Black $\\times$ Excluded $\\times$ Post-SSA. Demographic controls include age-bin, sex, and marital status indicators. Standard errors clustered by state in parentheses. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2_lines, "../tables/tab2_main.tex")

# =========================================================================
# TABLE 3: By Occupation Type
# =========================================================================
cat("=== Generating Table 3: By Occupation Type ===\n")

md <- main$m5_dom; mfl <- main$m5_fl; mfm <- main$m5_fm

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Insured Escape by Excluded Occupation Type}",
  "\\label{tab:occtype}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) \\\\",
  " & Domestic & Farm Laborers & Farmers \\\\",
  "\\hline",
  sprintf("Black $\\times$ Post-SSA & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
    coef(md)["black:post_ssa"], stars(pvalue(md)["black:post_ssa"]),
    coef(mfl)["black:post_ssa"], stars(pvalue(mfl)["black:post_ssa"]),
    coef(mfm)["black:post_ssa"], stars(pvalue(mfm)["black:post_ssa"])),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ \\\\",
    se(md)["black:post_ssa"], se(mfl)["black:post_ssa"], se(mfm)["black:post_ssa"]),
  "\\addlinespace",
  sprintf("Black & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
    coef(md)["black"], stars(pvalue(md)["black"]),
    coef(mfl)["black"], stars(pvalue(mfl)["black"]),
    coef(mfm)["black"], stars(pvalue(mfm)["black"])),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ \\\\",
    se(md)["black"], se(mfl)["black"], se(mfm)["black"]),
  "\\addlinespace",
  sprintf("Post-SSA & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
    coef(md)["post_ssa"], stars(pvalue(md)["post_ssa"]),
    coef(mfl)["post_ssa"], stars(pvalue(mfl)["post_ssa"]),
    coef(mfm)["post_ssa"], stars(pvalue(mfm)["post_ssa"])),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ \\\\",
    se(md)["post_ssa"], se(mfl)["post_ssa"], se(mfm)["post_ssa"]),
  "\\hline",
  "State FE & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
    format(nobs(md), big.mark = ","), format(nobs(mfl), big.mark = ","),
    format(nobs(mfm), big.mark = ",")),
  sprintf("$R^2$ & %.3f & %.3f & %.3f \\\\",
    r2(md, "r2"), r2(mfl, "r2"), r2(mfm, "r2")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Each column restricts the sample to workers in a specific excluded occupation in the starting census. Domestic service includes private household workers (OCC1950 700--720). Farm laborers include wage workers and unpaid family workers on farms (OCC1950 810--840). Farmers include farm owners and managers (OCC1950 100--123). The dependent variable, sample structure, and standard error clustering follow Table~\\ref{tab:main}. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3_lines, "../tables/tab3_occtype.tex")

# =========================================================================
# TABLE 4: Robustness and Mechanisms
# =========================================================================
cat("=== Generating Table 4: Robustness ===\n")

mp <- robust$placebo; ms <- robust$sei; msd <- robust$sei_dom
mm <- robust$mobility; mmfg <- robust$manufacturing

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Mechanisms and Robustness}",
  "\\label{tab:robust}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & Placebo & SEI Gain & SEI Gain & Mobility & Mfg Entry \\\\",
  " & Covered & All Excl. & Domestic & All Excl. & All Excl. \\\\",
  "\\hline",
  sprintf("Black $\\times$ Post-SSA & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ & $%.4f%s$ \\\\",
    coef(mp)["black:post_ssa"], stars(pvalue(mp)["black:post_ssa"]),
    coef(ms)["black:post_ssa"], stars(pvalue(ms)["black:post_ssa"]),
    coef(msd)["black:post_ssa"], stars(pvalue(msd)["black:post_ssa"]),
    coef(mm)["black:post_ssa"], stars(pvalue(mm)["black:post_ssa"]),
    coef(mmfg)["black:post_ssa"], stars(pvalue(mmfg)["black:post_ssa"])),
  sprintf(" & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ & $(%.4f)$ \\\\",
    se(mp)["black:post_ssa"], se(ms)["black:post_ssa"], se(msd)["black:post_ssa"],
    se(mm)["black:post_ssa"], se(mmfg)["black:post_ssa"]),
  "\\hline",
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\",
    format(nobs(mp), big.mark = ","), format(nobs(ms), big.mark = ","),
    format(nobs(msd), big.mark = ","), format(nobs(mm), big.mark = ","),
    format(nobs(mmfg), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Column (1) reports a placebo test on workers already in covered occupations; the outcome is any occupation change. Columns (2)--(3) use the change in the Duncan Socioeconomic Index (SEI) between censuses. Column (4) uses an indicator for interstate migration. Column (5) uses an indicator for entering manufacturing (craftsmen or operatives, OCC1950 500--690). All specifications include state fixed effects with standard errors clustered by state. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4_lines, "../tables/tab4_robust.tex")

# =========================================================================
# TABLE F1: SDE Appendix
# =========================================================================
cat("=== Generating SDE Table ===\n")

# Calculate SDEs for key outcomes
sd_switch_pre <- sd(excluded[post_ssa == 0, switch_to_covered])
sd_switch_dom_pre <- sd(excluded[post_ssa == 0 & excl_type == "domestic", switch_to_covered])
sd_sei_pre <- sd(excluded[post_ssa == 0, sei_gain], na.rm = TRUE)
sd_sei_dom_pre <- sd(excluded[post_ssa == 0 & excl_type == "domestic", sei_gain], na.rm = TRUE)
sd_mfg_pre <- sd(excluded[post_ssa == 0, enter_manufacturing])

sde_rows <- data.frame(
  Outcome = c(
    "Switch to covered (all excluded)",
    "Switch to covered (domestic)",
    "SEI gain (all excluded)",
    "SEI gain (domestic)",
    "Manufacturing entry (all excluded)"
  ),
  beta = c(
    coef(main$m1)["black:post_ssa"],
    coef(main$m5_dom)["black:post_ssa"],
    coef(robust$sei)["black:post_ssa"],
    coef(robust$sei_dom)["black:post_ssa"],
    coef(robust$manufacturing)["black:post_ssa"]
  ),
  se_beta = c(
    se(main$m1)["black:post_ssa"],
    se(main$m5_dom)["black:post_ssa"],
    se(robust$sei)["black:post_ssa"],
    se(robust$sei_dom)["black:post_ssa"],
    se(robust$manufacturing)["black:post_ssa"]
  ),
  sd_y = c(sd_switch_pre, sd_switch_dom_pre, sd_sei_pre, sd_sei_dom_pre, sd_mfg_pre),
  stringsAsFactors = FALSE
)

sde_rows$sde <- sde_rows$beta / sde_rows$sd_y
sde_rows$se_sde <- sde_rows$se_beta / sde_rows$sd_y
sde_rows$class <- ifelse(sde_rows$sde > 0.15, "Large positive",
  ifelse(sde_rows$sde > 0.05, "Moderate positive",
    ifelse(sde_rows$sde > 0.005, "Small positive",
      ifelse(sde_rows$sde > -0.005, "Null",
        ifelse(sde_rows$sde > -0.05, "Small negative",
          ifelse(sde_rows$sde > -0.15, "Moderate negative", "Large negative"))))))

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did the 1935 Social Security Act's exclusion of agricultural and domestic workers cause Black workers in those occupations to sort into covered occupations at higher rates than comparable white workers? ",
  "\\textbf{Policy mechanism:} The Social Security Act of 1935 excluded agricultural laborers and domestic servants from Old-Age Insurance coverage, affecting 60\\% of Black workers but only 27\\% of white workers; the 10-year pension promise created forward-looking incentives for workers in excluded occupations to switch to covered employment. ",
  "\\textbf{Outcome definition:} Indicator for transitioning from an SSA-excluded occupation (agricultural, domestic service) to a covered occupation during a decade transition, measured using harmonized OCC1950 codes across linked census records. ",
  "\\textbf{Treatment:} Binary; individual is Black and in an excluded occupation during the post-SSA period (1930--1940 transition). ",
  "\\textbf{Data:} IPUMS Machine Learning Linked Panel, 1920--1930--1940 linked census records, 34.7 million individuals; analysis sample restricted to working-age (15--64) individuals with valid occupations in all three censuses, yielding 5.3 million person-decade observations for the excluded-worker sample. ",
  "\\textbf{Method:} Difference-in-differences comparing Black vs.\\ white workers in excluded occupations across the 1920--1930 (pre-SSA) and 1930--1940 (post-SSA) decade transitions; state fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Workers aged 15--64 in SSA-excluded occupations (farmers/farm managers OCC1950 100--123, farm laborers 810--840, domestic service 700--720) with valid linked census records across all three decades. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
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

for (i in 1:nrow(sde_rows)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
    sde_rows$Outcome[i], sde_rows$beta[i], sde_rows$se_beta[i],
    sde_rows$sd_y[i], sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$class[i]
  ))
}

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_lines, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_occtype.tex\n")
cat("  tables/tab4_robust.tex\n")
cat("  tables/tabF1_sde.tex\n")
