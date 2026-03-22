## 05_tables.R — Generate all LaTeX tables (including SDE)
source("00_packages.R")

analysis    <- readRDS("../data/analysis.rds")
main_res    <- readRDS("../data/main_results.rds")
rob_res     <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ---- Table 1: Summary Statistics ----
cat("Generating Table 1: Summary Statistics\n")

vars_summ <- analysis %>%
  filter(!is.na(poverty_rate)) %>%
  summarise(
    N = n(),
    conv_mean = mean(convenience, na.rm = TRUE),
    conv_sd   = sd(convenience, na.rm = TRUE),
    super_mean = mean(supermarket, na.rm = TRUE),
    super_sd   = sd(supermarket, na.rm = TRUE),
    total_mean = mean(total_food, na.rm = TRUE),
    total_sd   = sd(total_food, na.rm = TRUE),
    cshare_mean = mean(conv_share_pre, na.rm = TRUE),
    cshare_sd   = sd(conv_share_pre, na.rm = TRUE),
    pov_mean  = mean(poverty_rate, na.rm = TRUE),
    pov_sd    = sd(poverty_rate, na.rm = TRUE),
    noveh_mean = mean(no_veh_share, na.rm = TRUE),
    noveh_sd   = sd(no_veh_share, na.rm = TRUE),
    pop_mean  = mean(total_pop, na.rm = TRUE),
    pop_sd    = sd(total_pop, na.rm = TRUE)
  )

tab1_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Variable & Mean & Std.\\ Dev. \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Food Retailers (county-year)}} \\\\[2pt]
Convenience stores (NAICS 445120) & %.2f & %.2f \\\\
Supermarkets (NAICS 445110) & %.2f & %.2f \\\\
Total food retailers & %.2f & %.2f \\\\
Pre-reform convenience share & %.3f & %.3f \\\\[4pt]
\\multicolumn{3}{l}{\\textit{Panel B: County Demographics (ACS 2015)}} \\\\[2pt]
Poverty rate & %.3f & %.3f \\\\
Share without vehicle & %.3f & %.3f \\\\
Population & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} N = %s county-year observations across %d counties and %d years (2010--2021). Convenience stores are NAICS 445120 (convenience retailers). Supermarkets are NAICS 445110 (supermarkets and other grocery, except convenience). Pre-reform convenience share is the 2015 ratio of convenience stores to total food retailers in each county. County demographics from the American Community Survey 5-year estimates (2011--2015).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  vars_summ$conv_mean, vars_summ$conv_sd,
  vars_summ$super_mean, vars_summ$super_sd,
  vars_summ$total_mean, vars_summ$total_sd,
  vars_summ$cshare_mean, vars_summ$cshare_sd,
  vars_summ$pov_mean, vars_summ$pov_sd,
  vars_summ$noveh_mean, vars_summ$noveh_sd,
  format(round(vars_summ$pop_mean), big.mark = ","),
  format(round(vars_summ$pop_sd), big.mark = ","),
  format(vars_summ$N, big.mark = ","),
  n_distinct(analysis$fips[!is.na(analysis$poverty_rate)]),
  n_distinct(analysis$year)
)
writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ---- Table 2: Main Results ----
cat("Generating Table 2: Main Results\n")

# Extract coefficients
get_coef <- function(model, var = "treat") {
  cf <- coef(model)[var]
  se <- se(model)[var]
  pv <- pvalue(model)[var]
  n  <- model$nobs
  stars <- ifelse(pv < 0.01, "$^{***}$", ifelse(pv < 0.05, "$^{**}$", ifelse(pv < 0.10, "$^{*}$", "")))
  list(cf = cf, se = se, pv = pv, n = n, stars = stars)
}

r1 <- get_coef(main_res$m1)
r2 <- get_coef(main_res$m2)
r3 <- get_coef(main_res$m3)
r4 <- get_coef(main_res$m4)
r5 <- get_coef(main_res$m5)

tab2_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Effect of SNAP Stocking Rule Exposure on Food Retailers}
\\label{tab:main}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& \\multicolumn{3}{c}{OLS: log(1 + Establishments)} & \\multicolumn{2}{c}{Poisson QMLE} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}
& (1) & (2) & (3) & (4) & (5) \\\\
& Convenience & Supermarkets & Total & Convenience & Supermarkets \\\\
\\midrule
ConvShare$_{c}^{\\text{pre}}$ $\\times$ Post & %.4f%s & %.4f%s & %.4f%s & %.4f%s & %.4f%s \\\\
& (%.4f) & (%.4f) & (%.4f) & (%.4f) & (%.4f) \\\\[4pt]
County FE & Yes & Yes & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & Yes & Yes & Yes \\\\
Observations & %s & %s & %s & %s & %s \\\\
Clusters (states) & %d & %d & %d & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ConvShare$_{c}^{\\text{pre}}$ is the 2015 share of convenience stores (NAICS 445120) among all food retailers in county~$c$. Post~$= 1$ for years 2018--2021. Columns~(1)--(3): OLS with log$(1 + \\text{estab.})$; columns~(4)--(5): Poisson QMLE. Supermarkets serve as a within-unit placebo.
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
",
  r1$cf, r1$stars, r2$cf, r2$stars, r3$cf, r3$stars, r4$cf, r4$stars, r5$cf, r5$stars,
  r1$se, r2$se, r3$se, r4$se, r5$se,
  format(r1$n, big.mark = ","),
  format(r2$n, big.mark = ","),
  format(r3$n, big.mark = ","),
  format(r4$n, big.mark = ","),
  format(r5$n, big.mark = ","),
  n_distinct(substr(analysis$fips, 1, 2)),
  n_distinct(substr(analysis$fips, 1, 2)),
  n_distinct(substr(analysis$fips, 1, 2)),
  n_distinct(substr(analysis$fips, 1, 2)),
  n_distinct(substr(analysis$fips, 1, 2))
)
writeLines(tab2_tex, "../tables/tab2_main.tex")

# ---- Table 3: Event Study Coefficients ----
cat("Generating Table 3: Event Study\n")

es_ols  <- main_res$es_ols
es_coef <- coef(es_ols)
es_se   <- se(es_ols)
es_pv   <- pvalue(es_ols)
es_names <- names(es_coef)

# Parse event times
event_times <- as.integer(gsub("event_fac::(-?[0-9]+):conv_share_pre", "\\1", es_names))
es_df <- data.frame(
  k     = event_times,
  beta  = es_coef,
  se    = es_se,
  pv    = es_pv,
  stars = ifelse(es_pv < 0.01, "$^{***}$", ifelse(es_pv < 0.05, "$^{**}$", ifelse(es_pv < 0.10, "$^{*}$", "")))
)
es_df <- es_df %>% arrange(k)

# Build table rows
es_rows <- paste(
  sapply(1:nrow(es_df), function(i) {
    sprintf("$k = %d$ & %.4f%s & (%.4f) \\\\", es_df$k[i], es_df$beta[i], es_df$stars[i], es_df$se[i])
  }),
  collapse = "\n"
)

tab3_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Event Study: Dynamic Effects of Stocking Rule Exposure on Convenience Stores}
\\label{tab:event}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
Event Time ($k$) & Coefficient & SE \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Coefficients from interacting year dummies with pre-reform convenience store share (ConvShare$_{c}^{\\text{pre}}$). Reference period: $k = -1$ (2017). Dependent variable: log$(1 + \\text{convenience stores})$. County and year fixed effects included. Standard errors clustered at the state level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
", es_rows)
writeLines(tab3_tex, "../tables/tab3_event.tex")

# ---- Table 4: Heterogeneity ----
cat("Generating Table 4: Heterogeneity\n")

r_rural <- get_coef(rob_res$het_rural, "treat")
r_rural_int <- get_coef(rob_res$het_rural, "I(treat * rural_safe)")
r_pov <- get_coef(rob_res$het_pov, "treat")
r_pov_int <- get_coef(rob_res$het_pov, "I(treat * high_pov)")

tab4_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Heterogeneity: Rural Status and Poverty}
\\label{tab:hetero}
\\begin{threeparttable}
\\begin{tabular}{lcc}
\\toprule
& (1) & (2) \\\\
& Rural/Urban & High/Low Poverty \\\\
\\midrule
ConvShare$^{\\text{pre}} \\times$ Post & %.4f%s & %.4f%s \\\\
& (%.4f) & (%.4f) \\\\[4pt]
ConvShare$^{\\text{pre}} \\times$ Post $\\times$ Rural & %.4f%s & \\\\
& (%.4f) & \\\\[4pt]
ConvShare$^{\\text{pre}} \\times$ Post $\\times$ High Poverty & & %.4f%s \\\\
& & (%.4f) \\\\[4pt]
County FE & Yes & Yes \\\\
Year FE & Yes & Yes \\\\
Observations & %s & %s \\\\
Clusters (states) & %d & %d \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Dependent variable: log$(1 + \\text{convenience stores})$. Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Rural is defined as USDA Rural--Urban Continuum Code $\\geq 4$. High poverty is defined as county poverty rate above the sample median (ACS 2015).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  r_rural$cf, r_rural$stars, r_pov$cf, r_pov$stars,
  r_rural$se, r_pov$se,
  r_rural_int$cf, r_rural_int$stars,
  r_rural_int$se,
  r_pov_int$cf, r_pov_int$stars,
  r_pov_int$se,
  format(rob_res$het_rural$nobs, big.mark = ","),
  format(rob_res$het_pov$nobs, big.mark = ","),
  n_distinct(substr(analysis$fips, 1, 2)),
  n_distinct(substr(analysis$fips, 1, 2))
)
writeLines(tab4_tex, "../tables/tab4_hetero.tex")

# ---- Table 5: Robustness ----
cat("Generating Table 5: Robustness\n")

r_placebo <- get_coef(rob_res$placebo, "fake_treat")
r_level   <- get_coef(rob_res$m_level, "treat")
r_styr    <- get_coef(rob_res$m_styr, "treat")

tab5_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robust}
\\begin{threeparttable}
\\begin{tabular}{lccc}
\\toprule
& (1) & (2) & (3) \\\\
& Placebo (2014) & Level & State $\\times$ Year FE \\\\
\\midrule
ConvShare$^{\\text{pre}} \\times$ Post & %.4f%s & %.4f%s & %.4f%s \\\\
& (%.4f) & (%.4f) & (%.4f) \\\\[4pt]
Sample & Pre-period only & Full & Full \\\\
Outcome & log(1+conv) & Levels & log(1+conv) \\\\
County FE & Yes & Yes & Yes \\\\
Year FE & Yes & Yes & State$\\times$Year \\\\
Observations & %s & %s & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Column (1) uses a placebo treatment date of 2014, restricted to the pre-reform period (2010--2017). Column (2) uses convenience store counts in levels rather than logs. Column (3) replaces year fixed effects with state $\\times$ year fixed effects.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}
",
  r_placebo$cf, r_placebo$stars, r_level$cf, r_level$stars, r_styr$cf, r_styr$stars,
  r_placebo$se, r_level$se, r_styr$se,
  format(rob_res$placebo$nobs, big.mark = ","),
  format(rob_res$m_level$nobs, big.mark = ","),
  format(rob_res$m_styr$nobs, big.mark = ",")
)
writeLines(tab5_tex, "../tables/tab5_robust.tex")

# ---- SDE Table (Appendix) ----
cat("Generating SDE Table\n")

# Preferred specification: State × Year FE (most credible given pre-trend concerns)
# (1) Convenience stores — OLS log with state×year FE
beta_conv  <- coef(rob_res$m_styr)["treat"]
se_conv    <- se(rob_res$m_styr)["treat"]
sd_y_conv  <- sd(analysis$log_conv, na.rm = TRUE)
sde_conv   <- beta_conv / sd_y_conv
se_sde_conv <- se_conv / sd_y_conv

# (2) Supermarkets — OLS log with county+year FE (placebo)
beta_super  <- coef(main_res$m2)["treat"]
se_super    <- se(main_res$m2)["treat"]
sd_y_super  <- sd(analysis$log_super, na.rm = TRUE)
sde_super   <- beta_super / sd_y_super
se_sde_super <- se_super / sd_y_super

# (3) Total food retailers — OLS log with county+year FE
beta_total  <- coef(main_res$m3)["treat"]
se_total    <- se(main_res$m3)["treat"]
sd_y_total  <- sd(analysis$log_total, na.rm = TRUE)
sde_total   <- beta_total / sd_y_total
se_sde_total <- se_total / sd_y_total

classify <- function(s) dplyr::case_when(
  s < -0.15  ~ "Large negative",
  s < -0.05  ~ "Moderate negative",
  s < -0.005 ~ "Small negative",
  s <  0.005 ~ "Null",
  s <  0.05  ~ "Small positive",
  s <  0.15  ~ "Moderate positive",
  TRUE       ~ "Large positive"
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} \\footnotesize ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does tightening SNAP retailer stocking requirements ",
  "reduce food retail access by causing small-format retailer exits in U.S.\\ counties? ",
  "\\textbf{Policy mechanism:} The 2016 USDA Final Rule (effective January 2018) increased ",
  "minimum stocking requirements for SNAP-authorized retailers from 3 to 7 varieties in each ",
  "of 4 staple food categories, imposing disproportionate compliance costs on convenience stores ",
  "and small groceries that lack shelf space and refrigeration for expanded produce and dairy inventories. ",
  "\\textbf{Outcome definition:} Log of one plus the number of food retail establishments in a county-year, ",
  "measured separately for convenience retailers (NAICS 445120) and supermarkets (NAICS 445110). ",
  "\\textbf{Treatment:} Continuous; the pre-reform (2015) share of convenience stores among all food ",
  "retailers in each county, interacted with a post-2018 indicator. ",
  "\\textbf{Data:} Census County Business Patterns, 2010--2021, county-year observations, ",
  format(nrow(analysis), big.mark = ","), " total observations across ",
  format(n_distinct(analysis$fips), big.mark = ","), " counties. ",
  "\\textbf{Method:} OLS with county and state-by-year fixed effects (preferred specification); standard errors clustered at the state level. ",
  "\\textbf{Sample:} All U.S.\\ counties with at least one food retailer in any sample year; ",
  "excludes counties with suppressed CBP data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- sprintf("
\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{threeparttable}
\\begin{tabular}{llccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
Convenience stores & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Supermarkets (placebo) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
Total food retailers & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
%s
\\end{tablenotes}
\\end{threeparttable}
\\end{adjustbox}
\\end{table}
",
  beta_conv, se_conv, sd_y_conv, sde_conv, se_sde_conv, classify(sde_conv),
  beta_super, se_super, sd_y_super, sde_super, se_sde_super, classify(sde_super),
  beta_total, se_total, sd_y_total, sde_total, se_sde_total, classify(sde_total),
  sde_notes
)
writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
