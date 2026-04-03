# 05_tables.R — Generate all LaTeX tables (hand-built for compatibility)
# apep_1344: The Potency Arms Race

source("00_packages.R")

cat("=== Loading models and data ===\n")
models <- readRDS("../data/models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
analysis_df <- readRDS("../data/analysis_clean.rds")
panel_df <- readRDS("../data/panel_clean.rds")

# Helper: format coefficient with stars
fmt_coef <- function(model, varname, vcov_type = ~BUYER_STATE) {
  b <- coef(model)[varname]
  se <- sqrt(vcov(model, vcov = vcov_type)[varname, varname])
  p <- fixest::pvalue(model, vcov = vcov_type)[varname]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  sprintf("%.3f%s", b, stars)
}

fmt_se <- function(model, varname, vcov_type = ~BUYER_STATE) {
  se <- sqrt(vcov(model, vcov = vcov_type)[varname, varname])
  sprintf("(%.3f)", se)
}

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Table 1: Summary Statistics ===\n")

mk_row <- function(label, x) {
  sprintf("%s & %.3f & %.3f & %.3f & %.3f & %d \\\\",
          label, mean(x, na.rm=T), sd(x, na.rm=T), min(x, na.rm=T), max(x, na.rm=T), sum(!is.na(x)))
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:sumstats}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & $N$ \\\\",
  "\\hline",
  mk_row("Mallinckrodt Oxy Share, 2006", analysis_df$malli_share_2006),
  mk_row("MME/Pill, Pre (2006--07)", analysis_df$mme_per_pill_pre),
  mk_row("MME/Pill, Post (2009--10)", analysis_df$mme_per_pill_post),
  mk_row("$\\Delta$ MME/Pill", analysis_df$delta_mme),
  mk_row("High-Dose Share, Pre", analysis_df$high_dose_share_pre),
  mk_row("$\\Delta$ High-Dose Share", analysis_df$delta_high_dose),
  sprintf("Oxy Pills (1000s), Pre & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          mean(analysis_df$total_pills_pre/1000), sd(analysis_df$total_pills_pre/1000),
          min(analysis_df$total_pills_pre/1000), max(analysis_df$total_pills_pre/1000), nrow(analysis_df)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}\\small\\item \\textit{Notes:} Unit of observation is a U.S.\\ county. Sample restricted to counties with $\\geq$1,000 oxycodone pills in both pre (2006--07) and post (2009--10) periods. MME/Pill is milligram morphine equivalents per oxycodone pill. High-Dose Share is the fraction of oxycodone pills with dose strength $\\geq$20mg. $N$ = 3,043 counties.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1, "../tables/tab1_sumstats.tex")
cat("Table 1 written.\n")

# ============================================================
# TABLE 2: First Stage
# ============================================================
cat("\n=== Table 2: First Stage ===\n")

v <- "malli_share_2006"
fs1 <- models$fs1; fs2 <- models$fs2; fs3 <- models$fs3
fs4 <- models$fs4; fs5 <- models$fs5

# For fs1, use heteroskedasticity-robust SE
fs1_se <- sqrt(vcov(fs1, vcov = "hetero")[v, v])
fs1_b <- coef(fs1)[v]
fs1_p <- 2 * pt(-abs(fs1_b/fs1_se), df = nobs(fs1) - 2)
fs1_stars <- ifelse(fs1_p < 0.01, "^{***}", ifelse(fs1_p < 0.05, "^{**}", ifelse(fs1_p < 0.1, "^{*}", "")))

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{First Stage: Mallinckrodt Share Predicts Potency Escalation}",
  "\\label{tab:first_stage}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & $\\Delta$ MME/Pill & $\\Delta$ MME/Pill & $\\Delta$ MME/Pill & $\\Delta$ HD Share & $\\Delta$ NDC \\\\",
  "\\hline",
  sprintf("Mallinckrodt Share, 2006 & %s%s & %s & %s & %s & %s \\\\",
          sprintf("%.3f", fs1_b), fs1_stars,
          fmt_coef(fs2, v), fmt_coef(fs3, v),
          fmt_coef(fs4, v), fmt_coef(fs5, v)),
  sprintf(" & (%.3f) & %s & %s & %s & %s \\\\",
          fs1_se, fmt_se(fs2, v), fmt_se(fs3, v), fmt_se(fs4, v), fmt_se(fs5, v)),
  " & & & & & \\\\",
  sprintf("MME/Pill, Pre & & & %s & & \\\\", fmt_coef(fs3, "mme_per_pill_pre")),
  sprintf(" & & & %s & & \\\\", fmt_se(fs3, "mme_per_pill_pre")),
  sprintf("Log Pills, Pre & & & %s & & \\\\", fmt_coef(fs3, "log_pills_pre")),
  sprintf(" & & & %s & & \\\\", fmt_se(fs3, "log_pills_pre")),
  "\\hline",
  sprintf("$N$ & %d & %d & %d & %d & %d \\\\",
          nobs(fs1), nobs(fs2), nobs(fs3), nobs(fs4), nobs(fs5)),
  sprintf("$R^2$ & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(fs1, "r2")$r2, fitstat(fs2, "r2")$r2, fitstat(fs3, "r2")$r2,
          fitstat(fs4, "r2")$r2, fitstat(fs5, "r2")$r2),
  "State FE & No & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}\\small\\item \\textit{Notes:} Each column reports OLS regressions of the 2006/07-to-2009/10 change in the dependent variable on 2006 county-level Mallinckrodt oxycodone market share. Standard errors in parentheses: column (1) uses heteroskedasticity-robust SEs; columns (2)--(5) cluster at the state level. HD Share is the fraction of pills with dose strength $\\geq$20mg. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab2, "../tables/tab2_first_stage.tex")
cat("Table 2 written.\n")

# ============================================================
# TABLE 3: Event Study
# ============================================================
cat("\n=== Table 3: Event Study ===\n")

es_model <- models$es_model
es_ct <- coeftable(es_model, vcov = ~BUYER_STATE)
years <- c(2006, 2008, 2009, 2010, 2011, 2012)

get_es <- function(yr) {
  cn <- sprintf("year::%d:malli_share_2006", yr)
  if (cn %in% rownames(es_ct)) {
    b <- es_ct[cn, "Estimate"]
    se <- es_ct[cn, "Std. Error"]
    p <- es_ct[cn, "Pr(>|t|)"]
    stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
    return(sprintf("%.3f%s & (%.3f)", b, stars, se))
  }
  return("--- & ---")
}

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Mallinckrodt Share $\\times$ Year Interactions}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  "Year & $\\hat{\\beta}_t$ & SE \\\\",
  "\\hline",
  sprintf("2006 & %s \\\\", get_es(2006)),
  "2007 (base) & --- & --- \\\\",
  sprintf("2008 & %s \\\\", get_es(2008)),
  sprintf("2009 & %s \\\\", get_es(2009)),
  sprintf("2010 & %s \\\\", get_es(2010)),
  sprintf("2011 & %s \\\\", get_es(2011)),
  sprintf("2012 & %s \\\\", get_es(2012)),
  "\\hline",
  sprintf("Counties & \\multicolumn{2}{c}{%s} \\\\",
          format(n_distinct(panel_df$county_id), big.mark = ",")),
  sprintf("County-Years & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(panel_df), big.mark = ",")),
  "County FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}\\small\\item \\textit{Notes:} Regression of county-year MME per oxycodone pill on interactions of 2006 Mallinckrodt share with year indicators, with county and year FE. Omitted year: 2007 (pre-expansion). SEs clustered by state. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab3, "../tables/tab3_eventstudy.tex")
cat("Table 3 written.\n")

# ============================================================
# TABLE 4: Robustness
# ============================================================
cat("\n=== Table 4: Robustness ===\n")

r1 <- models$fs2                     # Baseline
r2 <- rob_models$placebo_hydro       # Hydrocodone
r3 <- rob_models$bal1                # Balance: pre MME
r4 <- rob_models$alt_high_dose       # Alt: HD share
r5 <- rob_models$dose_40plus         # 40mg+

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness: Placebo, Balance, and Alternative Measures}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) & (5) \\\\",
  " & $\\Delta$ MME/Pill & $\\Delta$ Hydro & MME/Pill & $\\Delta$ HD Share & $\\Delta$ 40mg+ \\\\",
  " & Baseline & Placebo & (Pre-Period) & ($\\geq$20mg) & Share \\\\",
  "\\hline",
  sprintf("Malli Share, 2006 & %s & %s & %s & %s & %s \\\\",
          fmt_coef(r1, v), fmt_coef(r2, v), fmt_coef(r3, v), fmt_coef(r4, v), fmt_coef(r5, v)),
  sprintf(" & %s & %s & %s & %s & %s \\\\",
          fmt_se(r1, v), fmt_se(r2, v), fmt_se(r3, v), fmt_se(r4, v), fmt_se(r5, v)),
  "\\hline",
  sprintf("$N$ & %d & %d & %d & %d & %d \\\\",
          nobs(r1), nobs(r2), nobs(r3), nobs(r4), nobs(r5)),
  "State FE & Yes & Yes & Yes & Yes & Yes \\\\",
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}\\small\\item \\textit{Notes:} All specifications include state FE with SEs clustered by state. (1) Baseline first stage. (2) Hydrocodone placebo: Mallinckrodt did not expand hydrocodone lines, so the instrument should not predict hydrocodone potency. (3) Balance: 2006 Mallinckrodt share vs.~pre-period potency. (4) Alternative outcome: $\\Delta$ high-dose share ($\\geq$20mg). (5) $\\Delta$ share of 40mg+ pills. $^{*}p<0.1$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab4, "../tables/tab4_robustness.tex")
cat("Table 4 written.\n")

# ============================================================
# TABLE F1: SDE
# ============================================================
cat("\n=== Table F1: SDE ===\n")

sd_y_mme <- sd(analysis_df$delta_mme, na.rm = TRUE)
sd_y_hd <- sd(analysis_df$delta_high_dose, na.rm = TRUE)
sd_x <- sd(analysis_df$malli_share_2006)

fs2_b <- coef(models$fs2)[v]
fs2_se <- sqrt(vcov(models$fs2, vcov = ~BUYER_STATE)[v, v])
fs4_b <- coef(models$fs4)[v]
fs4_se <- sqrt(vcov(models$fs4, vcov = ~BUYER_STATE)[v, v])

sde_mme <- fs2_b * sd_x / sd_y_mme
sde_mme_se <- fs2_se * sd_x / sd_y_mme
sde_hd <- fs4_b * sd_x / sd_y_hd
sde_hd_se <- fs4_se * sd_x / sd_y_hd

classify <- function(s) {
  a <- abs(s)
  if (a < 0.005) return("Null")
  if (a < 0.05) return(ifelse(s > 0, "Small positive", "Small negative"))
  if (a < 0.15) return(ifelse(s > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(s > 0, "Large positive", "Large negative"))
}

# Heterogeneity by county size
above <- analysis_df %>% filter(total_pills_pre >= median(total_pills_pre))
below <- analysis_df %>% filter(total_pills_pre < median(total_pills_pre))
ha <- feols(delta_mme ~ malli_share_2006 | BUYER_STATE, data = above, vcov = ~BUYER_STATE)
hb <- feols(delta_mme ~ malli_share_2006 | BUYER_STATE, data = below, vcov = ~BUYER_STATE)

sde_a <- coef(ha)[v] * sd(above$malli_share_2006) / sd(above$delta_mme, na.rm=T)
sde_a_se <- sqrt(vcov(ha)[v,v]) * sd(above$malli_share_2006) / sd(above$delta_mme, na.rm=T)
sde_b <- coef(hb)[v] * sd(below$malli_share_2006) / sd(below$delta_mme, na.rm=T)
sde_b_se <- sqrt(vcov(hb)[v,v]) * sd(below$malli_share_2006) / sd(below$delta_mme, na.rm=T)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does generic manufacturer product-line expansion into high-dose opioid formulations increase county-level prescription opioid potency? ",
  "\\textbf{Policy mechanism:} Mallinckrodt Pharmaceuticals launched 20mg, 40mg, and 80mg immediate-release oxycodone tablets in 2007--2008, nearly doubling the number of oxycodone products nationally and offering high-dose generics without abuse-deterrent properties, competing with Purdue's OxyContin at lower wholesale prices. ",
  "\\textbf{Outcome definition:} Change in average milligram morphine equivalents (MME) per oxycodone pill shipped to each county, measuring the potency composition of the local opioid supply. ",
  "\\textbf{Treatment:} Continuous; 2006 county-level Mallinckrodt share of oxycodone pills (shift-share instrument using pre-period distributor relationships as shares and the national product expansion as the shift). ",
  "\\textbf{Data:} DEA ARCOS transaction-level opioid shipment records, 2006--2012, covering 178 million transactions aggregated to the county-year level; sample restricted to counties with at least 1,000 oxycodone pills in both pre and post periods ($N$ = ", nrow(analysis_df), " counties). ",
  "\\textbf{Method:} OLS long-difference (2006/07 to 2009/10) with state fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Counties with $\\geq$1,000 oxycodone pills in both the pre-period (2006--07) and post-period (2009--10); covers ", n_distinct(analysis_df$BUYER_STATE), " states. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the cross-county standard deviation of 2006 Mallinckrodt share and SD($Y$) is the cross-county standard deviation of the dependent variable. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("$\\Delta$ MME/Pill & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          fs2_b, fs2_se, sd_y_mme, sde_mme, sde_mme_se, classify(sde_mme)),
  sprintf("$\\Delta$ High-Dose Share & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
          fs4_b, fs4_se, sd_y_hd, sde_hd, sde_hd_se, classify(sde_hd)),
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by county oxycodone volume)}} \\\\",
  sprintf("Large counties ($\\Delta$ MME) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(ha)[v], sqrt(vcov(ha)[v,v]), sd(above$delta_mme, na.rm=T),
          sde_a, sde_a_se, classify(sde_a)),
  sprintf("Small counties ($\\Delta$ MME) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          coef(hb)[v], sqrt(vcov(hb)[v,v]), sd(below$delta_mme, na.rm=T),
          sde_b, sde_b_se, classify(sde_b)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(sde_tab, "../tables/tabF1_sde.tex")
cat("Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
