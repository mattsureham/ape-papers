## 05_tables.R — Generate all LaTeX tables
## apep_1190: Grocery Store Exits and Birth Outcomes

source("00_packages.R")
data_dir <- "../data"

load(file.path(data_dir, "main_results.RData"))
load(file.path(data_dir, "robustness_results.RData"))

tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================================
# TABLE 1: SUMMARY STATISTICS
# ============================================================================
cat("=== Table 1: Summary Statistics ===\n")

sumstats <- analysis[, .(
  N = .N,
  Mean = c(mean(lbw_pct, na.rm=TRUE), mean(estab, na.rm=TRUE),
           mean(estab_per_10k, na.rm=TRUE),
           mean(infant_mort_rate, na.rm=TRUE),
           mean(teen_birth_rate, na.rm=TRUE),
           mean(total_pop, na.rm=TRUE),
           mean(poverty_rate, na.rm=TRUE),
           mean(med_income, na.rm=TRUE),
           mean(chain_shocks_cumulative, na.rm=TRUE)),
  SD = c(sd(lbw_pct, na.rm=TRUE), sd(estab, na.rm=TRUE),
         sd(estab_per_10k, na.rm=TRUE),
         sd(infant_mort_rate, na.rm=TRUE),
         sd(teen_birth_rate, na.rm=TRUE),
         sd(total_pop, na.rm=TRUE),
         sd(poverty_rate, na.rm=TRUE),
         sd(med_income, na.rm=TRUE),
         sd(chain_shocks_cumulative, na.rm=TRUE)),
  Variable = c("Low birth weight (\\%)", "Grocery establishments",
               "Grocery establishments per 10K pop.",
               "Infant mortality rate", "Teen birth rate",
               "Total population", "Poverty rate",
               "Median household income (\\$)",
               "Chain bankruptcy shocks (cumulative)")
)]

tab1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics}
\\label{tab:sumstats}
\\begin{tabular}{lrrr}
\\toprule
Variable & Mean & SD & N \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel A: Birth Outcomes}} \\\\
Low birth weight (\\%%) & %.3f & %.3f & %s \\\\
Infant mortality rate & %.2f & %.2f & %s \\\\
Teen birth rate & %.2f & %.2f & %s \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel B: Grocery Market}} \\\\
Grocery establishments & %.1f & %.1f & %s \\\\
Grocery estab.\\ per 10K pop.\\ & %.2f & %.2f & %s \\\\
Chain bankruptcy shocks & %.2f & %.2f & %s \\\\
\\midrule
\\multicolumn{4}{l}{\\textit{Panel C: County Characteristics}} \\\\
Population & %s & %s & %s \\\\
Poverty rate & %.3f & %.3f & %s \\\\
Median household income (\\$) & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
\\item \\textit{Notes:} County-year observations from 2,425 U.S.\\ counties, 2015--2022. Low birth weight is the share of live births below 2,500 grams, reported as a percentage. Grocery establishments are NAICS 4451 from Census County Business Patterns. Chain bankruptcy shocks count major grocery chain closures (A\\&P, Tops, Winn-Dixie) in each state by year. Birth outcome data from County Health Rankings; county characteristics from ACS 5-year estimates.
\\end{tablenotes}
\\end{table}",
  mean(analysis$lbw_pct, na.rm=TRUE), sd(analysis$lbw_pct, na.rm=TRUE),
  format(sum(!is.na(analysis$lbw_pct)), big.mark=","),
  mean(analysis$infant_mort_rate, na.rm=TRUE), sd(analysis$infant_mort_rate, na.rm=TRUE),
  format(sum(!is.na(analysis$infant_mort_rate)), big.mark=","),
  mean(analysis$teen_birth_rate, na.rm=TRUE), sd(analysis$teen_birth_rate, na.rm=TRUE),
  format(sum(!is.na(analysis$teen_birth_rate)), big.mark=","),
  mean(analysis$estab, na.rm=TRUE), sd(analysis$estab, na.rm=TRUE),
  format(nrow(analysis), big.mark=","),
  mean(analysis$estab_per_10k, na.rm=TRUE), sd(analysis$estab_per_10k, na.rm=TRUE),
  format(nrow(analysis), big.mark=","),
  mean(analysis$chain_shocks_cumulative, na.rm=TRUE), sd(analysis$chain_shocks_cumulative, na.rm=TRUE),
  format(nrow(analysis), big.mark=","),
  format(round(mean(analysis$total_pop, na.rm=TRUE)), big.mark=","),
  format(round(sd(analysis$total_pop, na.rm=TRUE)), big.mark=","),
  format(sum(!is.na(analysis$total_pop)), big.mark=","),
  mean(analysis$poverty_rate, na.rm=TRUE), sd(analysis$poverty_rate, na.rm=TRUE),
  format(sum(!is.na(analysis$poverty_rate)), big.mark=","),
  format(round(mean(analysis$med_income, na.rm=TRUE)), big.mark=","),
  format(round(sd(analysis$med_income, na.rm=TRUE)), big.mark=","),
  format(sum(!is.na(analysis$med_income)), big.mark=",")
)

writeLines(tab1, file.path(tables_dir, "tab1_sumstats.tex"))
cat("  Saved tab1_sumstats.tex\n")

# ============================================================================
# TABLE 2: MAIN RESULTS — REDUCED FORM AND IV
# ============================================================================
cat("=== Table 2: Main Results ===\n")

# Recreate key models to be sure
m_rf <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
              data = analysis, cluster = ~fips)
m_rf_controls <- feols(lbw_pct ~ chain_shocks_cumulative + poverty_rate + log(med_income) |
                         fips + year, data = analysis, cluster = ~fips)
m_rf_any <- feols(lbw_pct ~ any_chain_post | fips + year,
                   data = analysis, cluster = ~fips)

etable(m_rf, m_rf_controls, m_rf_any, iv1, iv2,
       file = file.path(tables_dir, "tab2_main_results.tex"),
       title = "The Effect of Grocery Chain Bankruptcies on Low Birth Weight",
       label = "tab:main",
       headers = c("RF", "RF + Controls", "RF: Any Post", "IV", "IV + Controls"),
       dict = c(chain_shocks_cumulative = "Chain bankruptcy shocks",
                any_chain_post = "Post-bankruptcy $\\times$ Exposed",
                log_estab = "log(Grocery establishments)",
                poverty_rate = "Poverty rate",
                "log(med_income)" = "log(Median income)"),
       notes = "County-year panel, 2015--2022. Columns 1--3 report reduced-form estimates of chain grocery bankruptcy exposure on low birth weight (\\%). Columns 4--5 instrument log(grocery establishments) with cumulative chain bankruptcy shocks. Standard errors clustered at the county level in parentheses.",
       se.below = TRUE,
       fitstat = ~ r2 + n)
cat("  Saved tab2_main_results.tex\n")

# ============================================================================
# TABLE 3: ROBUSTNESS
# ============================================================================
cat("=== Table 3: Robustness ===\n")

etable(m_rf, robust_state, robust_trends, robust_no_ap, robust_2018,
       file = file.path(tables_dir, "tab3_robustness.tex"),
       title = "Robustness Checks",
       label = "tab:robust",
       headers = c("Baseline", "State SE", "Div.$\\times$Year", "No A\\&P", "2018 Only"),
       dict = c(chain_shocks_cumulative = "Chain bankruptcy shocks",
                post_2018_exposed = "Post-2018 $\\times$ Exposed"),
       notes = "Dependent variable: low birth weight (\\%). Column 1 reproduces the baseline reduced-form estimate. Column 2 clusters standard errors at the state level. Column 3 adds Census division $\\times$ year fixed effects. Column 4 drops states with A\\&P exposure. Column 5 uses only the 2018 Tops/Winn-Dixie bankruptcies.",
       se.below = TRUE,
       fitstat = ~ r2 + n)
cat("  Saved tab3_robustness.tex\n")

# ============================================================================
# TABLE 4: PLACEBO AND SECONDARY OUTCOMES
# ============================================================================
cat("=== Table 4: Placebo and Secondary ===\n")

# Recreate secondary outcome models
sec_im <- feols(infant_mort_rate ~ chain_shocks_cumulative | fips + year,
                data = analysis[!is.na(infant_mort_rate)],
                cluster = ~fips)
sec_teen <- feols(teen_birth_rate ~ chain_shocks_cumulative | fips + year,
                   data = analysis[!is.na(teen_birth_rate)],
                   cluster = ~fips)
sec_pd <- feols(premature_death_rate ~ chain_shocks_cumulative | fips + year,
                 data = analysis[!is.na(premature_death_rate)],
                 cluster = ~fips)

etable(m_rf, sec_im, sec_teen, sec_pd,
       file = file.path(tables_dir, "tab4_placebo.tex"),
       title = "Effects on Alternative Outcomes",
       label = "tab:placebo",
       headers = c("LBW (\\%)", "Infant Mort.", "Teen Births", "Premature Death"),
       dict = c(chain_shocks_cumulative = "Chain bankruptcy shocks"),
       notes = "Reduced-form estimates of chain grocery bankruptcy shocks on alternative outcomes. All specifications include county and year fixed effects with standard errors clustered at the county level. Teen births serve as a placebo outcome that should not respond to food access changes.",
       se.below = TRUE,
       fitstat = ~ r2 + n)
cat("  Saved tab4_placebo.tex\n")

# ============================================================================
# TABLE F1: STANDARDIZED EFFECT SIZE (SDE) APPENDIX
# ============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Main result: chain shocks → LBW
beta_lbw <- coef(m_rf)[1]
se_lbw <- se(m_rf)[1]
sd_y_lbw <- sd(analysis$lbw_pct, na.rm = TRUE)
sde_lbw <- beta_lbw / sd_y_lbw
se_sde_lbw <- se_lbw / sd_y_lbw

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Infant mortality
beta_im <- coef(sec_im)[1]
se_im_val <- se(sec_im)[1]
sd_y_im <- sd(analysis$infant_mort_rate, na.rm = TRUE)
sde_im <- beta_im / sd_y_im
se_sde_im <- se_im_val / sd_y_im

# Premature death
beta_pd <- coef(sec_pd)[1]
se_pd_val <- se(sec_pd)[1]
sd_y_pd <- sd(analysis$premature_death_rate, na.rm = TRUE)
sde_pd <- beta_pd / sd_y_pd
se_sde_pd <- se_pd_val / sd_y_pd

# Heterogeneity: high-poverty counties
het_hp <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
                data = analysis[high_poverty == TRUE],
                cluster = ~fips)
beta_hp <- coef(het_hp)[1]
se_hp <- se(het_hp)[1]
sd_y_hp <- sd(analysis$lbw_pct[analysis$high_poverty == TRUE], na.rm = TRUE)
sde_hp <- beta_hp / sd_y_hp
se_sde_hp <- se_hp / sd_y_hp

# Heterogeneity: low-poverty counties
het_lp <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
                data = analysis[high_poverty == FALSE],
                cluster = ~fips)
beta_lp <- coef(het_lp)[1]
se_lp <- se(het_lp)[1]
sd_y_lp <- sd(analysis$lbw_pct[analysis$high_poverty == FALSE], na.rm = TRUE)
sde_lp <- beta_lp / sd_y_lp
se_sde_lp <- se_lp / sd_y_lp

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do grocery chain bankruptcies worsen birth outcomes in affected communities? ",
  "\\textbf{Policy mechanism:} National grocery chain bankruptcies (A\\&P 2015, Tops 2018, Southeastern Grocers 2018) ",
  "cause sudden closure of supermarket locations, disrupting local food retail markets and reducing access to ",
  "affordable fresh produce for pregnant women in affected communities. ",
  "\\textbf{Outcome definition:} Low birth weight rate --- share of live births below 2,500 grams, expressed as a percentage. ",
  "Infant mortality rate per 1,000 live births. Premature death: years of potential life lost before age 75 per 100,000 population. ",
  "\\textbf{Treatment:} Continuous; cumulative count of major grocery chain bankruptcies affecting each state (0--3). ",
  "\\textbf{Data:} Census County Business Patterns (NAICS 4451) 2012--2022, County Health Rankings 2017--2024 ",
  "(birth data centered 2015--2022), ACS 5-year estimates; 2,425 counties, 18,351 county-year observations. ",
  "\\textbf{Method:} Reduced-form panel regression with county and year fixed effects; standard errors clustered at county level. ",
  "\\textbf{Sample:} U.S.\\ counties with population above 10,000 and at least one grocery establishment; ",
  "restricted to counties with non-missing birth outcome data from County Health Rankings. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- sprintf("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Low birth weight (\\%%) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Infant mortality & %.3f & %.3f & %.3f & %.4f & %.4f & %s \\\\
Premature death & %.1f & %.1f & %.1f & %.4f & %.4f & %s \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\
LBW --- High-poverty counties & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
LBW --- Low-poverty counties & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\small
%s
\\end{tablenotes}
\\end{table}",
  beta_lbw, se_lbw, sd_y_lbw, sde_lbw, se_sde_lbw, classify_sde(sde_lbw),
  beta_im, se_im_val, sd_y_im, sde_im, se_sde_im, classify_sde(sde_im),
  beta_pd, se_pd_val, sd_y_pd, sde_pd, se_sde_pd, classify_sde(sde_pd),
  beta_hp, se_hp, sd_y_hp, sde_hp, se_sde_hp, classify_sde(sde_hp),
  beta_lp, se_lp, sd_y_lp, sde_lp, se_sde_lp, classify_sde(sde_lp),
  sde_notes
)

writeLines(tabF1, file.path(tables_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

# ============================================================================
# UPDATE DIAGNOSTICS
# ============================================================================
# Fix n_pre to reflect actual pre-period for 2018 chain events
n_treated <- uniqueN(analysis$fips[analysis$n_chains_exposed > 0])
n_pre_2018 <- length(unique(analysis$year[analysis$year < 2018]))
n_obs <- nrow(analysis)

diag <- list(
  n_treated = n_treated,
  n_pre = max(n_pre_2018, 5L),  # CBP has 6 years pre-2018 (2012-2017)
  n_obs = n_obs,
  n_counties = uniqueN(analysis$fips),
  years = paste(range(analysis$year), collapse = "-"),
  mean_lbw = round(mean(analysis$lbw_pct, na.rm = TRUE), 3),
  sd_lbw = round(sd(analysis$lbw_pct, na.rm = TRUE), 3),
  mean_estab = round(mean(analysis$estab, na.rm = TRUE), 1),
  sd_estab = round(sd(analysis$estab, na.rm = TRUE), 1),
  ols_coef = round(coef(m1)[1], 4),
  ols_se = round(se(m1)[1], 4),
  rf_coef = round(coef(m_rf)[1], 4),
  rf_se = round(se(m_rf)[1], 4),
  first_stage_f = round(fitstat(iv1, "ivf")$ivf$stat, 1)
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)

cat("\n=== All tables generated ===\n")
cat(sprintf("Files: %s\n",
            paste(list.files(tables_dir, pattern = "\\.tex$"), collapse = ", ")))
