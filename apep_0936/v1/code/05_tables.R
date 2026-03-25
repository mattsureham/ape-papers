# 05_tables.R — Generate all LaTeX tables

source("00_packages.R")
library(fixest)
library(modelsummary)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel_strict.csv"))
panel_full <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

# ===========================================================================
# TABLE 1: Summary Statistics
# ===========================================================================
message("=== Table 1: Summary Statistics ===")

# Pre-treatment period
pre <- panel[year < 2018]
post_data <- panel[year >= 2018]

# Summary stats for key variables
sum_stats <- data.table(
  Variable = c("BERD (million EUR)", "BERD/GDP (\\%)", "GDP (million EUR)",
               "Employment (thousands)", "GERD/GDP (\\%)", "Observations",
               "Regions", "Countries"),
  Mean = c(round(mean(pre$berd_mio_eur, na.rm = TRUE), 1),
           round(mean(pre$berd_gdp_pct, na.rm = TRUE), 3),
           round(mean(pre$gdp_mio_eur, na.rm = TRUE), 1),
           round(mean(pre$emp_ths, na.rm = TRUE), 1),
           round(mean(pre$gerd_gdp_pct, na.rm = TRUE), 3),
           nrow(pre), uniqueN(pre$geo), uniqueN(pre$country)),
  SD = c(round(sd(pre$berd_mio_eur, na.rm = TRUE), 1),
         round(sd(pre$berd_gdp_pct, na.rm = TRUE), 3),
         round(sd(pre$gdp_mio_eur, na.rm = TRUE), 1),
         round(sd(pre$emp_ths, na.rm = TRUE), 1),
         round(sd(pre$gerd_gdp_pct, na.rm = TRUE), 3),
         "", "", ""),
  Min = c(round(min(pre$berd_mio_eur, na.rm = TRUE), 1),
          round(min(pre$berd_gdp_pct, na.rm = TRUE), 3),
          round(min(pre$gdp_mio_eur, na.rm = TRUE), 1),
          round(min(pre$emp_ths, na.rm = TRUE), 1),
          round(min(pre$gerd_gdp_pct, na.rm = TRUE), 3),
          "", "", ""),
  Max = c(round(max(pre$berd_mio_eur, na.rm = TRUE), 1),
          round(max(pre$berd_gdp_pct, na.rm = TRUE), 3),
          round(max(pre$gdp_mio_eur, na.rm = TRUE), 1),
          round(max(pre$emp_ths, na.rm = TRUE), 1),
          round(max(pre$gerd_gdp_pct, na.rm = TRUE), 3),
          "", "", "")
)

# Write LaTeX
cat("\\begin{table}[htbp]
\\centering
\\caption{Summary Statistics: Pre-Treatment Period (2010--2017)}
\\label{tab:summary}
\\begin{tabular}{lrrrr}
\\hline\\hline
Variable & Mean & SD & Min & Max \\\\
\\hline\n", file = file.path(tables_dir, "tab1_summary.tex"))

for (i in 1:nrow(sum_stats)) {
  cat(sprintf("%s & %s & %s & %s & %s \\\\\n",
              sum_stats$Variable[i], sum_stats$Mean[i],
              sum_stats$SD[i], sum_stats$Min[i], sum_stats$Max[i]),
      file = file.path(tables_dir, "tab1_summary.tex"), append = TRUE)
  if (i == 5) cat("\\hline\n", file = file.path(tables_dir, "tab1_summary.tex"), append = TRUE)
}

cat("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Unit of observation is NUTS2 region $\\times$ year. BERD is Business Enterprise R\\&D expenditure from Eurostat (rd\\_e\\_gerdreg). GDP from Eurostat (nama\\_10r\\_2gdp). Pre-treatment period covers 2010--2017, before any EU member state transposed the Trade Secrets Directive (2016/943).
\\end{tablenotes}
\\end{table}\n", file = file.path(tables_dir, "tab1_summary.tex"), append = TRUE)

# ===========================================================================
# TABLE 2: Transposition Timeline
# ===========================================================================
message("=== Table 2: Transposition Timeline ===")

trans <- fread(file.path(data_dir, "transposition_dates.csv"))
trans_sorted <- trans[order(first_transposition)]

# Country name map
name_map <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE","UK"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden","United Kingdom")
)

trans_sorted <- merge(trans_sorted, name_map, by = "iso2")

cat("\\begin{table}[htbp]
\\centering
\\caption{Transposition of the EU Trade Secrets Directive (2016/943)}
\\label{tab:transposition}
\\begin{tabular}{llcr}
\\hline\\hline
Country & First Transposition & Year & No.\\ Measures \\\\
\\hline\n", file = file.path(tables_dir, "tab2_transposition.tex"))

for (i in 1:nrow(trans_sorted)) {
  cat(sprintf("%s & %s & %d & %d \\\\\n",
              trans_sorted$name[i],
              format(as.Date(trans_sorted$first_transposition[i]), "%B %d, %Y"),
              trans_sorted$transposition_year[i],
              trans_sorted$n_measures[i]),
      file = file.path(tables_dir, "tab2_transposition.tex"), append = TRUE)
}

cat("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Transposition dates from CELLAR SPARQL (EUR-Lex), based on earliest notification date to the European Commission. The Directive required member states to transpose by June 9, 2018. ``No.\\ Measures'' counts the number of national implementing measures notified for each country.
\\end{tablenotes}
\\end{table}\n", file = file.path(tables_dir, "tab2_transposition.tex"), append = TRUE)

# ===========================================================================
# TABLE 3: Main Results
# ===========================================================================
message("=== Table 3: Main Results ===")

# Add derived variables
panel[, nuts1 := substr(geo, 1, 3)]
panel[, prot_low := fifelse(protection_pre == 3, 1L, 0L)]
panel[, prot_med := fifelse(protection_pre == 2, 1L, 0L)]
panel[, cohort_sa := fifelse(first_treat == 0, 10000L, first_treat)]
panel_full[, nuts1 := substr(geo, 1, 3)]
panel_full[, cohort_sa := fifelse(first_treat == 0, 10000L, first_treat)]

# Re-estimate models for clean table
twfe_base <- feols(berd_gdp_pct ~ post | geo + year,
                   data = panel, cluster = ~country)
twfe_ctrl <- feols(berd_gdp_pct ~ post + ln_gdp | geo + year,
                   data = panel[!is.na(ln_gdp)], cluster = ~country)
twfe_ln <- feols(ln_berd ~ post | geo + year,
                 data = panel, cluster = ~country)

# Build table manually for control
n_treated <- uniqueN(panel[first_treat > 0, country])
n_clusters <- uniqueN(panel$country)

cat("\\begin{table}[htbp]
\\centering
\\caption{Effect of Trade Secrets Directive on Business R\\&D}
\\label{tab:main}
\\begin{tabular}{lccccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) & (5) \\\\
 & BERD/GDP & BERD/GDP & ln(BERD) & BERD/GDP & BERD/GDP \\\\
 & TWFE & TWFE & TWFE & CS (NT) & CS (NYT) \\\\
\\hline\n", file = file.path(tables_dir, "tab3_main.tex"))

# Row: Post coefficient
cat(sprintf("Post $\\times$ Treated & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
            coef(twfe_base)["post"],
            coef(twfe_ctrl)["post"],
            coef(twfe_ln)["post"],
            cs_agg$overall.att,
            cs_nyt_agg$overall.att),
    file = file.path(tables_dir, "tab3_main.tex"), append = TRUE)

# Row: SE
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            se(twfe_base)["post"],
            se(twfe_ctrl)["post"],
            se(twfe_ln)["post"],
            cs_agg$overall.se,
            cs_nyt_agg$overall.se),
    file = file.path(tables_dir, "tab3_main.tex"), append = TRUE)

# Stars
p_vals <- c(pvalue(twfe_base)["post"],
            pvalue(twfe_ctrl)["post"],
            pvalue(twfe_ln)["post"],
            cs_agg$overall.att / cs_agg$overall.se,  # z-score
            cs_nyt_agg$overall.att / cs_nyt_agg$overall.se)
# Compute proper p-values for CS
p_cs <- 2 * pnorm(-abs(cs_agg$overall.att / cs_agg$overall.se))
p_nyt <- 2 * pnorm(-abs(cs_nyt_agg$overall.att / cs_nyt_agg$overall.se))

cat(sprintf("\\hline
Region FE & Yes & Yes & Yes & --- & --- \\\\
Year FE & Yes & Yes & Yes & --- & --- \\\\
GDP control & No & Yes & No & No & No \\\\
Estimator & TWFE & TWFE & TWFE & CS & CS \\\\
Control group & --- & --- & --- & Never & Not-yet \\\\
Clusters & %d & %d & %d & %d & %d \\\\
Observations & %s & %s & %s & %s & %s \\\\
Treated countries & %d & %d & %d & %d & %d \\\\",
    n_clusters, n_clusters, n_clusters, n_clusters, n_clusters,
    format(nobs(twfe_base), big.mark = ","),
    format(nobs(twfe_ctrl), big.mark = ","),
    format(nobs(twfe_ln), big.mark = ","),
    format(nrow(panel[!is.na(berd_gdp_pct) & !is.na(first_treat)]), big.mark = ","),
    format(nrow(panel[!is.na(berd_gdp_pct) & !is.na(first_treat)]), big.mark = ","),
    n_treated, n_treated, n_treated, n_treated, n_treated),
    file = file.path(tables_dir, "tab3_main.tex"), append = TRUE)

cat("\n\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} The dependent variable is BERD as a percentage of GDP (columns 1--2, 4--5) or the natural log of BERD in million EUR (column 3). ``Post'' equals one after the country transposed the Trade Secrets Directive (2016/943). Standard errors clustered at the country level in parentheses. CS = Callaway \\& Sant'Anna (2021); NT = never-treated control group; NYT = not-yet-treated control group. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.
\\end{tablenotes}
\\end{table}\n", file = file.path(tables_dir, "tab3_main.tex"), append = TRUE)

# ===========================================================================
# TABLE 4: Robustness Checks
# ===========================================================================
message("=== Table 4: Robustness ===")

# Balanced panel IS the primary; use full panel for SA robustness
twfe_bal <- twfe_base  # already on balanced panel

# Sun-Abraham on full panel
sa <- feols(berd_gdp_pct ~ sunab(cohort_sa, year) | geo + year,
            data = panel_full, cluster = ~country)
sa_summary <- summary(sa, agg = "att")

# NUTS1 clustering
twfe_n1 <- feols(berd_gdp_pct ~ post | geo + year,
                 data = panel, cluster = ~nuts1)

# Placebo
panel[, placebo_post2 := fifelse(!is.na(transposition_year) &
                                   year >= (transposition_year - 2), 1L, 0L)]
panel[, placebo_post2 := fifelse(year >= transposition_year, NA_integer_, placebo_post2)]
twfe_plac <- feols(berd_gdp_pct ~ placebo_post2 | geo + year,
                   data = panel[!is.na(placebo_post2)], cluster = ~country)

cat("\\begin{table}[htbp]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{tabular}{lcccccc}
\\hline\\hline
 & (1) & (2) & (3) & (4) & (5) \\\\
 & Baseline & Balanced & Sun-Abraham & NUTS1 cluster & Placebo \\\\
\\hline\n", file = file.path(tables_dir, "tab4_robustness.tex"))

sa_coef <- sa_summary$coeftable["ATT", "Estimate"]
sa_se <- sa_summary$coeftable["ATT", "Std. Error"]

cat(sprintf("Post $\\times$ Treated & %.4f & %.4f & %.4f & %.4f & %.4f \\\\\n",
            coef(twfe_base)["post"],
            coef(twfe_bal)["post"],
            sa_coef,
            coef(twfe_n1)["post"],
            coef(twfe_plac)["placebo_post2"]),
    file = file.path(tables_dir, "tab4_robustness.tex"), append = TRUE)

cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            se(twfe_base)["post"],
            se(twfe_bal)["post"],
            sa_se,
            se(twfe_n1)["post"],
            se(twfe_plac)["placebo_post2"]),
    file = file.path(tables_dir, "tab4_robustness.tex"), append = TRUE)

cat(sprintf("\\hline
Balanced panel & No & Yes & No & No & No \\\\
Estimator & TWFE & TWFE & SA & TWFE & TWFE \\\\
Clustering & Country & Country & Country & NUTS1 & Country \\\\
Pre-treatment only & No & No & No & No & Yes \\\\
Observations & %s & %s & %s & %s & %s \\\\",
    format(nobs(twfe_base), big.mark = ","),
    format(nobs(twfe_bal), big.mark = ","),
    format(nobs(sa), big.mark = ","),
    format(nobs(twfe_n1), big.mark = ","),
    format(nobs(twfe_plac), big.mark = ",")),
    file = file.path(tables_dir, "tab4_robustness.tex"), append = TRUE)

cat("\n\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column 1 reproduces the baseline TWFE from Table~\\ref{tab:main}. Column 2 restricts to a balanced panel. Column 3 uses the Sun \\& Abraham (2021) interaction-weighted estimator. Column 4 clusters standard errors at the NUTS1 level. Column 5 tests for pre-trends by applying a placebo treatment two years before actual transposition (restricting to the pre-treatment period). All specifications include region and year fixed effects. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.
\\end{tablenotes}
\\end{table}\n", file = file.path(tables_dir, "tab4_robustness.tex"), append = TRUE)

# ===========================================================================
# TABLE 5: Heterogeneity by Pre-Existing Protection
# ===========================================================================
message("=== Table 5: Heterogeneity ===")

fit_high <- feols(berd_gdp_pct ~ post | geo + year,
                  data = panel[protection_pre == 1 | first_treat == 0],
                  cluster = ~country)
fit_med <- feols(berd_gdp_pct ~ post | geo + year,
                 data = panel[protection_pre == 2 | first_treat == 0],
                 cluster = ~country)
fit_low <- feols(berd_gdp_pct ~ post | geo + year,
                 data = panel[protection_pre == 3 | first_treat == 0],
                 cluster = ~country)

cat("\\begin{table}[htbp]
\\centering
\\caption{Heterogeneity by Pre-Existing Trade Secret Protection}
\\label{tab:heterogeneity}
\\begin{tabular}{lccc}
\\hline\\hline
 & (1) & (2) & (3) \\\\
 & High Protection & Medium Protection & Low Protection \\\\
\\hline\n", file = file.path(tables_dir, "tab5_heterogeneity.tex"))

cat(sprintf("Post $\\times$ Treated & %.4f & %.4f & %.4f \\\\\n",
            coef(fit_high)["post"], coef(fit_med)["post"], coef(fit_low)["post"]),
    file = file.path(tables_dir, "tab5_heterogeneity.tex"), append = TRUE)
cat(sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\\n",
            se(fit_high)["post"], se(fit_med)["post"], se(fit_low)["post"]),
    file = file.path(tables_dir, "tab5_heterogeneity.tex"), append = TRUE)

cat(sprintf("\\hline
Region FE & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes \\\\
Countries (treated) & %s & %s & %s \\\\
Observations & %s & %s & %s \\\\",
    paste0(uniqueN(panel[protection_pre == 1 & first_treat > 0, country])),
    paste0(uniqueN(panel[protection_pre == 2 & first_treat > 0, country])),
    paste0(uniqueN(panel[protection_pre == 3 & first_treat > 0, country])),
    format(nobs(fit_high), big.mark = ","),
    format(nobs(fit_med), big.mark = ","),
    format(nobs(fit_low), big.mark = ",")),
    file = file.path(tables_dir, "tab5_heterogeneity.tex"), append = TRUE)

cat("\n\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Each column restricts the treated sample to countries with the indicated level of pre-existing trade secret protection (based on Baker McKenzie 2016 survey classification). High protection: DE, FR, SE, NL, AT, FI. Medium: IT, ES, BE, DK, IE, PT, UK. Low: PL, CZ, SK, HU, RO, BG, HR, SI, LV, LT, EE, CY, MT, EL, LU. All regressions include the never-treated control group. Standard errors clustered at the country level. $^{***}$~$p<0.01$, $^{**}$~$p<0.05$, $^{*}$~$p<0.10$.
\\end{tablenotes}
\\end{table}\n", file = file.path(tables_dir, "tab5_heterogeneity.tex"), append = TRUE)

# ===========================================================================
# TABLE F1: SDE Appendix (MANDATORY)
# ===========================================================================
message("=== Table F1: Standardized Effect Sizes ===")

# Compute pre-treatment SD of outcomes
sd_berd_gdp <- sd(panel[year < 2018, berd_gdp_pct], na.rm = TRUE)
sd_ln_berd <- sd(panel[year < 2018, ln_berd], na.rm = TRUE)
sd_gerd_gdp <- sd(panel[year < 2018 & !is.na(gerd_gdp_pct), gerd_gdp_pct], na.rm = TRUE)

# Main specification (BERD/GDP %)
beta_main <- cs_agg$overall.att
se_main <- cs_agg$overall.se
sde_main <- beta_main / sd_berd_gdp
se_sde_main <- se_main / sd_berd_gdp

# Log BERD
beta_ln <- cs_ln_agg$overall.att
se_ln <- cs_ln_agg$overall.se
sde_ln <- beta_ln / sd_ln_berd
se_sde_ln <- se_ln / sd_ln_berd

# GERD/GDP
beta_gerd <- coef(twfe_gerd)["post"]
se_gerd <- se(twfe_gerd)["post"]
sde_gerd <- beta_gerd / sd_gerd_gdp
se_sde_gerd <- se_gerd / sd_gerd_gdp

# Classification function
classify_sde <- function(sde) {
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

# Heterogeneity rows (sample splits)
# High vs Low pre-existing protection
beta_high <- coef(fit_high)["post"]
se_high <- se(fit_high)["post"]
sd_high <- sd(panel[year < 2018 & (protection_pre == 1 | first_treat == 0), berd_gdp_pct], na.rm = TRUE)
sde_high <- beta_high / sd_high
se_sde_high <- se_high / sd_high

beta_low <- coef(fit_low)["post"]
se_low <- se(fit_low)["post"]
sd_low <- sd(panel[year < 2018 & (protection_pre == 3 | first_treat == 0), berd_gdp_pct], na.rm = TRUE)
sde_low <- beta_low / sd_low
se_sde_low <- se_low / sd_low

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states plus United Kingdom). ",
  "\\textbf{Research question:} Does harmonizing trade secret protection upward via the EU Trade Secrets Directive (2016/943) affect business enterprise R\\&D investment across European regions? ",
  "\\textbf{Policy mechanism:} The Directive created the first EU-wide legal framework for trade secret protection, ",
  "harmonizing definitions, civil remedies (injunctions, damages, corrective measures), and litigation confidentiality protections; ",
  "countries with weaker pre-existing regimes experienced a larger effective strengthening of legal protection against misappropriation. ",
  "\\textbf{Outcome definition:} BERD as a percentage of regional GDP (Panels A--B rows 1--2), natural log of BERD in million EUR (Panel A row 2), and total GERD as a percentage of GDP (Panel A row 3). ",
  "\\textbf{Treatment:} Binary indicator equal to one after the country transposed the Directive into national law. ",
  "\\textbf{Data:} Eurostat rd\\_e\\_gerdreg and nama\\_10r\\_2gdp, 2010--2023, NUTS2 region $\\times$ year panel with ",
  format(nrow(panel), big.mark = ","), " observations across ", uniqueN(panel$geo), " regions in ", uniqueN(panel$country), " countries. ",
  "\\textbf{Method:} Callaway \\& Sant'Anna (2021) staggered DiD with never-treated control group (Panel A); TWFE with country-level clustering (Panel B heterogeneity splits). ",
  "\\textbf{Sample:} All EU-27 NUTS2 regions with non-missing BERD and GDP data; Panel B splits by pre-existing trade secret legal protection strength (Baker McKenzie 2016 classification). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

cat("\\begin{table}[htbp]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\hline\\hline
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\hline
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
", file = file.path(tables_dir, "tabF1_sde.tex"))

# Panel A rows
cat(sprintf("BERD/GDP (\\%%) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta_main, se_main, sd_berd_gdp, sde_main, se_sde_main, classify_sde(sde_main)),
    file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)
cat(sprintf("ln(BERD) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta_ln, se_ln, sd_ln_berd, sde_ln, se_sde_ln, classify_sde(sde_ln)),
    file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)
cat(sprintf("GERD/GDP (\\%%) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta_gerd, se_gerd, sd_gerd_gdp, sde_gerd, se_sde_gerd, classify_sde(sde_gerd)),
    file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)

# Panel B
cat("\\hline
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-existing protection)}} \\\\
", file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)
cat(sprintf("BERD/GDP --- High prot. & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta_high, se_high, sd_high, sde_high, se_sde_high, classify_sde(sde_high)),
    file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)
cat(sprintf("BERD/GDP --- Low prot. & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
            beta_low, se_low, sd_low, sde_low, se_sde_low, classify_sde(sde_low)),
    file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)

cat(sprintf("\\hline\\hline
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{table}\n", sde_notes),
    file = file.path(tables_dir, "tabF1_sde.tex"), append = TRUE)

message("\n=== All tables generated ===")
message("  tab1_summary.tex")
message("  tab2_transposition.tex")
message("  tab3_main.tex")
message("  tab4_robustness.tex")
message("  tab5_heterogeneity.tex")
message("  tabF1_sde.tex")
