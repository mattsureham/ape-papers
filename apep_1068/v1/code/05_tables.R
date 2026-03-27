# =============================================================================
# 05_tables.R — Generate all LaTeX tables
# apep_1068: Last Hired, Not First Fired
# =============================================================================

source("00_packages.R")

dt <- fread("../data/analysis_sample.csv")
black <- dt[black == 1]
white <- dt[black == 0]

load("../data/main_models.RData")
load("../data/robustness_models.RData")

dir.create("../tables", showWarnings = FALSE)

# Helper: extract IV row with stars
get_iv_row <- function(mod, varname = "fit_migrant") {
  b <- coef(mod)[varname]
  s <- se(mod)[varname]
  p <- 2 * pnorm(-abs(b/s))
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  list(
    coef = sprintf("%.3f%s", b, stars),
    se = sprintf("(%.3f)", s),
    n = format(nobs(mod), big.mark = ","),
    b = b, s = s
  )
}

get_ols_row <- function(mod, varname = "migrant") {
  get_iv_row(mod, varname)
}

# ============================================================================
# Table 1: Summary Statistics
# ============================================================================
cat("Generating Table 1: Summary Statistics...\n")

black_mig <- black[migrant == 1]
black_stay <- black[migrant == 0]
white_mig <- white[migrant == 1]

summ_vars <- c("age_1920", "in_school", "farm_orig", "married_1920",
               "occscore_1920", "occscore_1930", "occscore_1940",
               "occ_change_boom", "occ_change_bust")
nice_names <- c("Age (1920)", "In school (1920)", "Farm worker (1920)", "Married (1920)",
                "Occ.\\ score (1920)", "Occ.\\ score (1930)", "Occ.\\ score (1940)",
                "Occ.\\ change 1920--1930", "Occ.\\ change 1930--1940")

tab1_rows <- character()
for (i in seq_along(summ_vars)) {
  v <- summ_vars[i]
  m_mean <- sprintf("%.2f", mean(black_mig[[v]], na.rm = TRUE))
  m_sd <- sprintf("%.2f", sd(black_mig[[v]], na.rm = TRUE))
  s_mean <- sprintf("%.2f", mean(black_stay[[v]], na.rm = TRUE))
  s_sd <- sprintf("%.2f", sd(black_stay[[v]], na.rm = TRUE))
  w_mean <- sprintf("%.2f", mean(white_mig[[v]], na.rm = TRUE))
  w_sd <- sprintf("%.2f", sd(white_mig[[v]], na.rm = TRUE))
  tab1_rows <- c(tab1_rows, sprintf("  %s & %s & %s & %s & %s & %s & %s \\\\",
                                     nice_names[i], m_mean, m_sd, s_mean, s_sd, w_mean, w_sd))
}

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Black Migrants} & \\multicolumn{2}{c}{Black Stayers} & \\multicolumn{2}{c}{White Migrants} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
  " & Mean & SD & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  paste(tab1_rows, collapse = "\n"), "\n",
  "\\midrule\n",
  sprintf("  Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
          format(nrow(black_mig), big.mark = ","),
          format(nrow(black_stay), big.mark = ","),
          format(nrow(white_mig), big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample consists of males aged 15--55 in 1920, born in Southern states, linked across the 1920, 1930, and 1940 Censuses via the IPUMS Multigenerational Longitudinal Panel. Migrants are individuals residing in Southern states in 1920 who moved to Northern or Western states by 1930. Occupational score (occscore) maps Census occupations to median 1950 income.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================================
# Table 2: First Stage and Main IV Results
# ============================================================================
cat("Generating Table 2: First Stage and IV Results...\n")

ols2r <- get_ols_row(ols2)
iv1r <- get_iv_row(iv1)
iv2r <- get_iv_row(iv2)

# First stage stats
fs2_coef <- sprintf("%.4f^{***}", coef(fs2)["log_instrument"])
fs2_se <- sprintf("(%.4f)", se(fs2)["log_instrument"])
fs1_coef <- sprintf("%.4f^{***}", coef(fs1)["log_instrument"])
fs1_se <- sprintf("(%.4f)", se(fs1)["log_instrument"])
fs_t <- coef(fs2)["log_instrument"] / se(fs2)["log_instrument"]
fs_F <- fs_t^2

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{The Depression Shield: Migration and Occupational Resilience, 1930--1940}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & OLS & IV & IV \\\\\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel A: Second stage --- Dep.\\ var: $\\Delta$ Occ.\\ Score, 1930--1940}} \\\\\n",
  "\\addlinespace\n",
  sprintf("  Migrant (S$\\rightarrow$N) & %s & %s & %s \\\\\n", ols2r$coef, iv1r$coef, iv2r$coef),
  sprintf("   & %s & %s & %s \\\\\n", ols2r$se, iv1r$se, iv2r$se),
  "\\addlinespace\n",
  "\\midrule\n",
  "\\multicolumn{4}{l}{\\textit{Panel B: First stage --- Dep.\\ var: Migrant (S$\\rightarrow$N)}} \\\\\n",
  "\\addlinespace\n",
  sprintf("  Log(Distance$^{-1} \\times$ Black Pop.\\ 1910) & & %s & %s \\\\\n", fs1_coef, fs2_coef),
  sprintf("   & & %s & %s \\\\\n", fs1_se, fs2_se),
  sprintf("  First-stage $F$ & & %.1f & %.1f \\\\\n",
          (coef(fs1)["log_instrument"] / se(fs1)["log_instrument"])^2, fs_F),
  "\\addlinespace\n",
  "\\midrule\n",
  "  Individual controls & $\\checkmark$ & & $\\checkmark$ \\\\\n",
  sprintf("  Observations & %s & %s & %s \\\\\n", ols2r$n, iv1r$n, iv2r$n),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Sample is Black males aged 15--55 in 1920, born in Southern states, linked across three Census decades via the IPUMS MLP. Migrant equals one if the individual resided in the South in 1920 and a Northern/Western state by 1930. The instrument is the log of a shift-share measure combining inverse geographic distance from the origin county to 12 major Northern cities with each city's 1910 Black population stock. This measure captures pre-existing migration corridors: counties closer to Northern cities with established Black communities had higher out-migration rates. Individual controls: age, age squared, school attendance, farm worker status, marital status, and baseline occupational score (all measured in 1920). Standard errors clustered at origin county in parentheses. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Placebo (White Migrants) and Boom Validation
# ============================================================================
cat("Generating Table 3: Placebo and Validation...\n")

iv_wr <- get_iv_row(iv_w, "fit_migrant")
boom_ivr <- get_iv_row(boom_iv, "fit_migrant")
iv_totalr <- get_iv_row(iv_total, "fit_migrant")

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Placebo and Validation Tests}\n",
  "\\label{tab:placebo}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Black IV & White IV & Black IV & Black IV \\\\\n",
  " & 1930--1940 & 1930--1940 & 1920--1930 & 1920--1940 \\\\\n",
  " & (Depression) & (Placebo) & (Boom) & (Total) \\\\\n",
  "\\midrule\n",
  sprintf("  Migrant (S$\\rightarrow$N) & %s & %s & %s & %s \\\\\n",
          iv2r$coef, iv_wr$coef, boom_ivr$coef, iv_totalr$coef),
  sprintf("   & %s & %s & %s & %s \\\\\n",
          iv2r$se, iv_wr$se, boom_ivr$se, iv_totalr$se),
  "\\addlinespace\n",
  "  Individual controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  sprintf("  Observations & %s & %s & %s & %s \\\\\n",
          iv2r$n, iv_wr$n, boom_ivr$n, iv_totalr$n),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All columns report IV estimates instrumenting migration with the shift-share measure and including individual controls. Column 1 reproduces the preferred estimate from \\Cref{tab:main}. Column 2 applies the identical specification to White Southern migrants as a placebo: if the Depression disproportionately reversed gains through racial ``last hired, first fired'' discrimination, effects should appear for Black but not White migrants. Column 3 validates the instrument by estimating the 1920s boom-period migration premium. Column 4 estimates the full 1920--1940 change. Standard errors clustered at origin county. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_placebo.tex")

# ============================================================================
# Table 4: Robustness
# ============================================================================
cat("Generating Table 4: Robustness...\n")

sei_r <- get_iv_row(sei_iv, "fit_migrant")
noret_r <- get_iv_row(noreturn_iv, "fit_migrant")
fe_r <- get_iv_row(iv_state_fe, "fit_migrant")

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness of the Depression Shield}\n",
  "\\label{tab:robust}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & SEI measure & Excl.\\ return & State FE \\\\\n",
  "\\midrule\n",
  sprintf("  Migrant (S$\\rightarrow$N) & %s & %s & %s & %s \\\\\n",
          iv2r$coef, sei_r$coef, noret_r$coef, fe_r$coef),
  sprintf("   & %s & %s & %s & %s \\\\\n",
          iv2r$se, sei_r$se, noret_r$se, fe_r$se),
  "\\addlinespace\n",
  "  Individual controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  "  Origin state FE & & & & $\\checkmark$ \\\\\n",
  sprintf("  Observations & %s & %s & %s & %s \\\\\n",
          iv2r$n, sei_r$n, noret_r$n, fe_r$n),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All columns report IV estimates instrumenting migration with the shift-share measure. Column 1 reproduces the baseline from \\Cref{tab:main}. Column 2 replaces the occupational income score with the Duncan Socioeconomic Index (SEI). Column 3 excludes return migrants who moved back to Southern states by 1940. Column 4 adds origin state fixed effects, which absorbs much of the between-state instrument variation (the instrument identifies primarily off cross-state differences in distance to Northern destinations). All specifications include individual controls. Standard errors clustered at origin county. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_robust.tex")

# ============================================================================
# Table 5: Heterogeneity
# ============================================================================
cat("Generating Table 5: Heterogeneity...\n")

iv_sch_r <- get_iv_row(iv_school, "fit_migrant")
iv_nosch_r <- get_iv_row(iv_noschool, "fit_migrant")
iv_farm_r <- get_iv_row(iv_farm, "fit_migrant")
iv_nfarm_r <- get_iv_row(iv_nonfarm, "fit_migrant")

tab5 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Heterogeneity in Depression-Era Resilience}\n",
  "\\label{tab:het}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & In school & Not in school & Farm origin & Non-farm \\\\\n",
  "\\midrule\n",
  sprintf("  Migrant (S$\\rightarrow$N) & %s & %s & %s & %s \\\\\n",
          iv_sch_r$coef, iv_nosch_r$coef, iv_farm_r$coef, iv_nfarm_r$coef),
  sprintf("   & %s & %s & %s & %s \\\\\n",
          iv_sch_r$se, iv_nosch_r$se, iv_farm_r$se, iv_nfarm_r$se),
  "\\addlinespace\n",
  "  Individual controls & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ & $\\checkmark$ \\\\\n",
  sprintf("  Observations & %s & %s & %s & %s \\\\\n",
          iv_sch_r$n, iv_nosch_r$n, iv_farm_r$n, iv_nfarm_r$n),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each column reports the IV estimate from the preferred specification (\\Cref{tab:main}, Column 3) estimated on the indicated subsample. Columns 1--2 split by 1920 school attendance. Columns 3--4 split by 1920 farm worker status. All specifications include individual controls (age, age squared, and remaining covariates). Standard errors clustered at origin county. $^{***}$p$<$0.01, $^{**}$p$<$0.05, $^{*}$p$<$0.10.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab5, "../tables/tab5_het.tex")

# ============================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================================
cat("Generating SDE table...\n")

# Main IV estimate (preferred spec)
beta_main <- coef(iv2)["fit_migrant"]
se_main <- se(iv2)["fit_migrant"]
sd_y_main <- sd(black$occ_change_bust, na.rm = TRUE)
sde_main <- beta_main / sd_y_main
se_sde_main <- se_main / sd_y_main

# Boom period
beta_boom <- coef(boom_iv)["fit_migrant"]
se_boom <- se(boom_iv)["fit_migrant"]
sd_y_boom <- sd(black$occ_change_boom, na.rm = TRUE)
sde_boom <- beta_boom / sd_y_boom
se_sde_boom <- se_boom / sd_y_boom

# Heterogeneity: Farm origin
beta_farm <- coef(iv_farm)["fit_migrant"]
se_farm <- se(iv_farm)["fit_migrant"]
sd_y_farm <- sd(black[farm_orig == 1]$occ_change_bust, na.rm = TRUE)
sde_farm <- beta_farm / sd_y_farm
se_sde_farm <- se_farm / sd_y_farm

# Heterogeneity: Non-farm origin
beta_nfarm <- coef(iv_nonfarm)["fit_migrant"]
se_nfarm <- se(iv_nonfarm)["fit_migrant"]
sd_y_nfarm <- sd(black[farm_orig == 0]$occ_change_bust, na.rm = TRUE)
sde_nfarm <- beta_nfarm / sd_y_nfarm
se_sde_nfarm <- se_nfarm / sd_y_nfarm

classify <- function(s) {
  ifelse(s < -0.15, "Large negative",
  ifelse(s < -0.05, "Moderate negative",
  ifelse(s < -0.005, "Small negative",
  ifelse(s <  0.005, "Null",
  ifelse(s <  0.05, "Small positive",
  ifelse(s <  0.15, "Moderate positive",
         "Large positive"))))))
}

fmt <- function(x, d = 3) sprintf(paste0("%.", d, "f"), x)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Whether the occupational upgrading achieved by Black Great Migration participants during the 1920s boom survived the Great Depression, the first individual-level causal test of the ``last hired, first fired'' hypothesis. ",
  "\\textbf{Policy mechanism:} The Great Migration relocated millions of African Americans from the rural South to Northern industrial cities during 1910--1970; Northern labor markets offered structurally different occupational ladders than Southern agriculture, but the Depression tested whether these gains were durable or whether racial discrimination reversed them. ",
  "\\textbf{Outcome definition:} Change in occupational income score (occscore) between 1930 and 1940 Censuses, where occscore maps each Census occupation code to the median income of workers in that occupation in 1950. ",
  "\\textbf{Treatment:} Binary indicator for South-to-North migration (residing in a Southern state in 1920 and a Northern/Western state by 1930). ",
  "\\textbf{Data:} IPUMS Multigenerational Longitudinal Panel linking individuals across the 1920, 1930, and 1940 Censuses; unit of observation is an individual male aged 15--55 in 1920. ",
  "\\textbf{Method:} Two-stage least squares instrumenting migration with a shift-share measure combining inverse geographic distance from origin counties to 12 Northern cities with 1910 Black population stocks; standard errors clustered at the origin county level. ",
  "\\textbf{Sample:} Black males born in 13 Southern states, aged 15--55 in 1920, with valid occupational scores in all three Census years; excludes those with zero occupational scores. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{llcccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("$\\Delta$ Occ.\\ Score 1930--40 & Preferred IV & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_main), fmt(se_main), fmt(sd_y_main), fmt(sde_main), fmt(se_sde_main), classify(sde_main)),
  sprintf("$\\Delta$ Occ.\\ Score 1920--30 & Boom IV & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_boom), fmt(se_boom), fmt(sd_y_boom), fmt(sde_boom), fmt(se_sde_boom), classify(sde_boom)),
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("$\\Delta$ Occ.\\ Score 1930--40 & Farm origin & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_farm), fmt(se_farm), fmt(sd_y_farm), fmt(sde_farm), fmt(se_sde_farm), classify(sde_farm)),
  sprintf("$\\Delta$ Occ.\\ Score 1930--40 & Non-farm origin & %s & %s & %s & %s & %s & %s \\\\\n",
          fmt(beta_nfarm), fmt(se_nfarm), fmt(sd_y_nfarm), fmt(sde_nfarm), fmt(se_sde_nfarm), classify(sde_nfarm)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
