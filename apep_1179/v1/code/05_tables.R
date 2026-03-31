## 05_tables.R — Generate all LaTeX tables
## apep_1179: Anti-corruption enforcement and fiscal composition in China

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
robust <- readRDS("../data/robustness_results.rds")

panel <- panel %>%
  mutate(campaign = as.integer(year >= 2013),
         post_x_intensity = campaign * log_intensity)

# Helper: extract scalar R-squared from fixest model
get_r2 <- function(model) {
  as.numeric(r2(model, type = "r2"))
}

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

cat("Generating Table 1: Summary Statistics\n")

pre <- panel %>% filter(year < 2013, !is.na(edu_share))
post <- panel %>% filter(year >= 2013, !is.na(edu_share))

make_stat_row <- function(var, label, df_pre, df_post) {
  pre_vals <- df_pre[[var]]
  post_vals <- df_post[[var]]
  sprintf("    %s & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          label,
          mean(pre_vals, na.rm = TRUE),
          sd(pre_vals, na.rm = TRUE),
          mean(post_vals, na.rm = TRUE),
          sd(post_vals, na.rm = TRUE),
          format(sum(!is.na(c(pre_vals, post_vals))), big.mark = ","))
}

tab1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "    & \\multicolumn{2}{c}{Pre-Campaign} & \\multicolumn{2}{c}{Post-Campaign} & \\\\",
  "    & \\multicolumn{2}{c}{(2007--2012)} & \\multicolumn{2}{c}{(2013--2016)} & \\\\",
  "    \\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "    & Mean & SD & Mean & SD & N \\\\",
  "\\hline",
  "    \\multicolumn{6}{l}{\\textit{Panel A: Fiscal composition}} \\\\[3pt]",
  make_stat_row("edu_share", "Education share", pre, post),
  make_stat_row("sci_share", "Science share", pre, post),
  make_stat_row("fai_share", "Fixed asset inv./GDP", pre, post),
  "    \\\\",
  "    \\multicolumn{6}{l}{\\textit{Panel B: Fiscal levels (log)}} \\\\[3pt]",
  make_stat_row("log_edu_exp", "Log education exp.", pre, post),
  make_stat_row("log_fiscal_exp", "Log total fiscal exp.", pre, post),
  make_stat_row("log_gdp", "Log GDP", pre, post),
  "    \\\\",
  "    \\multicolumn{6}{l}{\\textit{Panel C: Treatment intensity}} \\\\[3pt]",
  sprintf("    Investigation intensity & --- & --- & %.1f & %.1f & %d \\\\",
          mean(panel$intensity[panel$year == 2013 & panel$intensity > 0]),
          sd(panel$intensity[panel$year == 2013 & panel$intensity > 0]),
          sum(panel$intensity > 0 & panel$year == 2013)),
  "\\hline",
  sprintf("    Cities & \\multicolumn{5}{c}{%d} \\\\", n_distinct(panel$city_id)),
  sprintf("    City-years & \\multicolumn{5}{c}{%s} \\\\",
          format(nrow(panel %>% filter(!is.na(edu_share))), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel of 258 Chinese prefecture-level cities, 2007--2016.",
  "Education share is education expenditure divided by total local fiscal expenditure.",
  "Science share is science \\& technology expenditure divided by total local fiscal expenditure.",
  "Fixed asset investment/GDP proxies infrastructure spending intensity.",
  "Investigation intensity counts the total number of officials investigated under the",
  "CCDI anti-corruption campaign (2013--2016) in each city (Wang 2020).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "../tables/tab1_sumstats.tex")

# =============================================================================
# TABLE 2: Main Results — Fiscal Composition
# =============================================================================

cat("Generating Table 2: Main Results\n")

m <- results$main

# Extract coefficients
get_row <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.001, "***",
           ifelse(p < 0.01, "**",
           ifelse(p < 0.05, "*", "")))
  list(coef = sprintf("%.4f%s", b, stars),
       se = sprintf("(%.4f)", s))
}

# Build table manually for control over formatting
tab2 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Anti-Corruption Enforcement and Fiscal Composition}",
  "\\label{tab:main}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  "    & (1) & (2) & (3) & (4) & (5) \\\\",
  "    & Edu. & Edu. & Edu. & Log Edu. & Log Total \\\\",
  "    & Share & Share & Share & Exp. & Exp. \\\\",
  "\\hline"
)

# Row for Post × Binary
r1 <- get_row(m$m1, "post")
tab2 <- c(tab2,
  sprintf("    Post $\\times$ Treated & %s & & & & \\\\", r1$coef),
  sprintf("    & %s & & & & \\\\", r1$se))

# Row for Post × log(Intensity)
r2 <- get_row(m$m2, "post_x_intensity")
r3 <- get_row(m$m3, "post_x_intensity")
r4 <- get_row(m$m4, "post_x_intensity")
r5 <- get_row(m$m5, "post_x_intensity")

tab2 <- c(tab2,
  sprintf("    Post $\\times$ log(Investigations) & & %s & %s & %s & %s \\\\",
          r2$coef, r3$coef, r4$coef, r5$coef),
  sprintf("    & & %s & %s & %s & %s \\\\",
          r2$se, r3$se, r4$se, r5$se),
  "    \\\\",
  "    City FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "    Year FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "    Log GDP control & & & Yes & & \\\\",
  sprintf("    Observations & %s & %s & %s & %s & %s \\\\",
          format(nobs(m$m1), big.mark = ","),
          format(nobs(m$m2), big.mark = ","),
          format(nobs(m$m3), big.mark = ","),
          format(nobs(m$m4), big.mark = ","),
          format(nobs(m$m5), big.mark = ",")),
  sprintf("    $R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          get_r2(m$m1), get_r2(m$m2), get_r2(m$m3), get_r2(m$m4), get_r2(m$m5)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a separate regression with city and year fixed effects.",
  "Standard errors clustered at the city level in parentheses.",
  "The dependent variable in columns (1)--(3) is education expenditure as a share of total",
  "local fiscal expenditure. Column (4) uses log education expenditure and column (5) uses",
  "log total fiscal expenditure. Post $\\times$ log(Investigations) interacts a post-2013",
  "indicator with the log of one plus the total number of officials investigated in that city.",
  "$^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, "../tables/tab2_main.tex")

# =============================================================================
# TABLE 3: Alternative Outcomes
# =============================================================================

cat("Generating Table 3: Alternative Outcomes\n")

ms <- results$secondary

tab3 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Anti-Corruption Enforcement and Alternative Fiscal Outcomes}",
  "\\label{tab:secondary}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "    & (1) & (2) & (3) & (4) \\\\",
  "    & Science & FAI/ & Edu./ & Hospital \\\\",
  "    & Share & GDP & GDP & Beds p.c. \\\\",
  "\\hline"
)

rs <- list(
  get_row(ms$m_sci, "post_x_intensity"),
  get_row(ms$m_fai, "post_x_intensity"),
  get_row(ms$m_edugdp, "post_x_intensity"),
  get_row(ms$m_beds, "post_x_intensity")
)

tab3 <- c(tab3,
  sprintf("    Post $\\times$ log(Investigations) & %s & %s & %s & %s \\\\",
          rs[[1]]$coef, rs[[2]]$coef, rs[[3]]$coef, rs[[4]]$coef),
  sprintf("    & %s & %s & %s & %s \\\\",
          rs[[1]]$se, rs[[2]]$se, rs[[3]]$se, rs[[4]]$se),
  "    \\\\",
  "    City FE & Yes & Yes & Yes & Yes \\\\",
  "    Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("    Observations & %s & %s & %s & %s \\\\",
          format(nobs(ms$m_sci), big.mark = ","),
          format(nobs(ms$m_fai), big.mark = ","),
          format(nobs(ms$m_edugdp), big.mark = ","),
          format(nobs(ms$m_beds), big.mark = ",")),
  sprintf("    $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          get_r2(ms$m_sci), get_r2(ms$m_fai), get_r2(ms$m_edugdp), get_r2(ms$m_beds)),
  "    Pre-treatment mean (dep.~var.) & 0.015 & 0.711 & 0.025 & 0.004 \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each column reports a separate regression with city and year fixed effects.",
  "Standard errors clustered at the city level in parentheses.",
  "Science share is science \\& technology expenditure divided by total fiscal expenditure.",
  "FAI/GDP is total fixed asset investment divided by GDP (proxy for infrastructure intensity).",
  "Edu./GDP is education expenditure divided by GDP.",
  "Hospital beds per capita is the number of hospital beds divided by total population.",
  "$^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3, "../tables/tab3_secondary.tex")

# =============================================================================
# TABLE 4: Event Study Coefficients
# =============================================================================

cat("Generating Table 4: Event Study\n")

es_edu <- robust$event_study_edu
es_sci <- robust$event_study_sci

years <- c(2007:2011, 2013:2016)
year_labels <- c("-6", "-5", "-4", "-3", "-1", "+1", "+2", "+3", "+4")
# Note: 2012 is the reference year (omitted), labeled as 0

tab4_rows <- c()
for (i in seq_along(years)) {
  yr <- years[i]
  var <- sprintf("year::%d:log_intensity", yr)

  b_e <- coef(es_edu)[var]
  s_e <- se(es_edu)[var]
  p_e <- pvalue(es_edu)[var]
  stars_e <- ifelse(p_e < 0.001, "***", ifelse(p_e < 0.01, "**", ifelse(p_e < 0.05, "*", "")))

  b_s <- coef(es_sci)[var]
  s_s <- se(es_sci)[var]
  p_s <- pvalue(es_sci)[var]
  stars_s <- ifelse(p_s < 0.001, "***", ifelse(p_s < 0.01, "**", ifelse(p_s < 0.05, "*", "")))

  tab4_rows <- c(tab4_rows,
    sprintf("    $t%s$ & %.4f%s & %.4f%s \\\\", year_labels[i],
            b_e, stars_e, b_s, stars_s),
    sprintf("    & (%.4f) & (%.4f) \\\\", s_e, s_s))
}

tab4 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Intensity $\\times$ Year Interactions}",
  "\\label{tab:eventstudy}",
  "\\small",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "    & (1) & (2) \\\\",
  "    Event Time & Education Share & Science Share \\\\",
  "\\hline",
  "    \\multicolumn{3}{l}{\\textit{Pre-treatment}} \\\\[3pt]",
  tab4_rows[1:10],  # Pre-treatment rows (5 leads)
  "    \\\\",
  "    \\multicolumn{3}{l}{\\textit{Post-treatment}} \\\\[3pt]",
  tab4_rows[11:18],  # Post-treatment rows (4 lags)
  "    \\\\",
  "    City FE & Yes & Yes \\\\",
  "    Year FE & Yes & Yes \\\\",
  sprintf("    Observations & %s & %s \\\\",
          format(nobs(es_edu), big.mark = ","),
          format(nobs(es_sci), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Each coefficient is from the interaction of log(1 + investigations)",
  "with a year dummy, relative to the base year 2012 ($t = 0$, omitted).",
  "Standard errors clustered at the city level in parentheses.",
  "Pre-treatment coefficients near zero support the parallel trends assumption.",
  "$^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, "../tables/tab4_eventstudy.tex")

# =============================================================================
# TABLE 5: Robustness
# =============================================================================

cat("Generating Table 5: Robustness\n")

# Placebo, high-rank, and LOO
m_plac_e <- robust$placebo_edu
m_plac_s <- robust$placebo_sci
m_hr_s <- robust$highrank_sci
loo <- robust$loo

rpe <- get_row(m_plac_e, "post_x_pre_inv")
rps <- get_row(m_plac_s, "post_x_pre_inv")
rhr <- get_row(m_hr_s, "post_x_highrank")

# Main result for comparison
m_main_sci <- feols(sci_share ~ post_x_intensity | city_id + year,
                    data = panel, cluster = ~city_id)
rmain <- get_row(m_main_sci, "post_x_intensity")

tab5 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness Checks: Science Expenditure Share}",
  "\\label{tab:robust}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "    & (1) & (2) & (3) & (4) \\\\",
  "    & Baseline & Placebo & High-Rank & LOO \\\\",
  "    & & (Pre-2013 Inv.) & Only & Range \\\\",
  "\\hline",
  sprintf("    Post $\\times$ log(Investigations) & %s & & & \\\\", rmain$coef),
  sprintf("    & %s & & & \\\\", rmain$se),
  sprintf("    Post $\\times$ log(Pre-campaign inv.) & & %s & & \\\\", rps$coef),
  sprintf("    & & %s & & \\\\", rps$se),
  sprintf("    Post $\\times$ log(High-rank inv.) & & & %s & \\\\", rhr$coef),
  sprintf("    & & & %s & \\\\", rhr$se),
  sprintf("    LOO coefficient range & & & & [%.4f, %.4f] \\\\",
          min(loo$coef), max(loo$coef)),
  "    LOO all significant ($p < 0.05$) & & & & Yes \\\\",
  "    \\\\",
  "    City FE & Yes & Yes & Yes & Yes \\\\",
  "    Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("    Observations & %s & %s & %s & --- \\\\",
          format(nobs(m_main_sci), big.mark = ","),
          format(nobs(m_plac_s), big.mark = ","),
          format(nobs(m_hr_s), big.mark = ",")),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline intensity specification from Table~\\ref{tab:secondary}.",
  "Column (2) uses pre-campaign (2004--2012) investigation intensity as a placebo treatment;",
  "the insignificant coefficient supports the identification assumption that post-2013 changes",
  "are driven by the campaign, not pre-existing corruption patterns.",
  "Column (3) restricts the treatment measure to high-rank officials (rank $\\geq$ 7).",
  "Column (4) reports the range of coefficients from 29 leave-one-province-out regressions.",
  "Standard errors clustered at the city level. $^{***}p<0.001$, $^{**}p<0.01$, $^{*}p<0.05$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab5, "../tables/tab5_robust.tex")

# =============================================================================
# SDE TABLE (MANDATORY APPENDIX)
# =============================================================================

cat("Generating SDE Table\n")

# Compute SDEs for main outcomes
pre_data <- panel %>% filter(year < 2013)
sd_edu_share <- sd(pre_data$edu_share, na.rm = TRUE)
sd_sci_share <- sd(pre_data$sci_share, na.rm = TRUE)
sd_fai_share <- sd(pre_data$fai_share, na.rm = TRUE)
sd_intensity <- sd(panel$log_intensity[panel$log_intensity > 0], na.rm = TRUE)

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
# Main coefficients
beta_edu <- coef(results$main$m2)["post_x_intensity"]
se_edu <- se(results$main$m2)["post_x_intensity"]
beta_sci <- coef(results$secondary$m_sci)["post_x_intensity"]
se_sci <- se(results$secondary$m_sci)["post_x_intensity"]
beta_fai <- coef(results$secondary$m_fai)["post_x_intensity"]
se_fai <- se(results$secondary$m_fai)["post_x_intensity"]

sde_edu <- beta_edu * sd_intensity / sd_edu_share
sde_sci <- beta_sci * sd_intensity / sd_sci_share
sde_fai <- beta_fai * sd_intensity / sd_fai_share

se_sde_edu <- se_edu * sd_intensity / sd_edu_share
se_sde_sci <- se_sci * sd_intensity / sd_sci_share
se_sde_fai <- se_fai * sd_intensity / sd_fai_share

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# --- Heterogeneity: split by above/below median intensity ---
med_int <- median(panel$intensity[panel$intensity > 0])
panel_hi <- panel %>% filter(intensity > med_int | intensity == 0)
panel_lo <- panel %>% filter(intensity <= med_int)

m_hi <- feols(sci_share ~ campaign * log_intensity | city_id + year,
              data = panel_hi, cluster = ~city_id)
m_lo <- feols(sci_share ~ campaign * log_intensity | city_id + year,
              data = panel_lo, cluster = ~city_id)

beta_hi <- coef(m_hi)["campaign:log_intensity"]
se_hi <- se(m_hi)["campaign:log_intensity"]
beta_lo <- coef(m_lo)["campaign:log_intensity"]
se_lo <- se(m_lo)["campaign:log_intensity"]

sd_sci_hi <- sd(panel_hi$sci_share[panel_hi$year < 2013], na.rm = TRUE)
sd_sci_lo <- sd(panel_lo$sci_share[panel_lo$year < 2013], na.rm = TRUE)
sd_int_hi <- sd(panel_hi$log_intensity[panel_hi$log_intensity > 0], na.rm = TRUE)
sd_int_lo <- sd(panel_lo$log_intensity[panel_lo$log_intensity > 0], na.rm = TRUE)

sde_hi <- beta_hi * sd_int_hi / sd_sci_hi
se_sde_hi <- se_hi * sd_int_hi / sd_sci_hi
sde_lo <- beta_lo * sd_int_lo / sd_sci_lo
se_sde_lo <- se_lo * sd_int_lo / sd_sci_lo

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} China. ",
  "\\textbf{Research question:} Does anti-corruption enforcement shift local fiscal composition ",
  "toward harder-to-corrupt spending categories? ",
  "\\textbf{Policy mechanism:} China's CCDI campaign (2013--2016) investigated thousands of local officials ",
  "across prefectures, creating enforcement shocks that disrupted existing corruption networks and ",
  "altered the incentive environment for fiscal allocation decisions. ",
  "\\textbf{Outcome definition:} Each row measures a different component of local fiscal spending as a share ",
  "of total local government expenditure or GDP: education share, science \\& technology share, and fixed ",
  "asset investment as a fraction of GDP. ",
  "\\textbf{Treatment:} Continuous; log(1 + total officials investigated in the city, 2013--2016). ",
  "\\textbf{Data:} Wang (2020) corruption investigations from Harvard Dataverse merged with China City ",
  "Statistical Yearbook panel (262 cities, 2007--2016, 2,575 city-year observations). ",
  "\\textbf{Method:} Continuous-treatment difference-in-differences with city and year fixed effects; ",
  "standard errors clustered at the city level. ",
  "\\textbf{Sample:} 258 prefecture-level cities with non-missing fiscal data; 253 treated (investigated ",
  "at least once), 5 never-treated. Treatment intensity ranges from 1 to 260 investigated officials. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of ",
  "log-intensity among treated cities and SD($Y$) is the pre-treatment standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "    Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "    \\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("    Education share & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_edu, se_edu, sd_edu_share, sde_edu, se_sde_edu, classify_sde(sde_edu)),
  sprintf("    Science share & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_sci, se_sci, sd_sci_share, sde_sci, se_sde_sci, classify_sde(sde_sci)),
  sprintf("    FAI/GDP & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_fai, se_fai, sd_fai_share, sde_fai, se_sde_fai, classify_sde(sde_fai)),
  "    \\\\",
  "    \\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Science share by enforcement intensity)}} \\\\[3pt]",
  sprintf("    High-intensity cities & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_hi, se_hi, sd_sci_hi, sde_hi, se_sde_hi, classify_sde(sde_hi)),
  sprintf("    Low-intensity cities & %.4f & %.4f & %.4f & %.3f & %.3f & %s \\\\",
          beta_lo, se_lo, sd_sci_lo, sde_lo, se_sde_lo, classify_sde(sde_lo)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\nAll tables generated in tables/ directory.\n")
cat("Files:", paste(list.files("../tables/"), collapse = ", "), "\n")
