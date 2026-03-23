# ==============================================================================
# 05_tables.R — Table Generation
# Paper: The Credential Equity Trap (apep_0791)
# ==============================================================================

source("00_packages.R")

panel <- readRDS(file.path("..", "data", "analysis_panel.rds"))
models <- readRDS(file.path("..", "data", "main_models.rds"))
rob_models <- readRDS(file.path("..", "data", "robustness_models.rds"))

out_dir <- file.path("..", "tables")
dir.create(out_dir, showWarnings = FALSE)

# Helper functions
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

fmt_coef <- function(coef, p) sprintf("%.4f%s", coef, stars(p))
fmt_se <- function(se) sprintf("(%.4f)", se)

# Extract GE and repeal coefficients from feols model
extract_dd <- function(mod) {
  cf <- coeftable(mod)
  rn <- rownames(cf)
  ge_idx <- grep("ge_active", rn)[1]
  rep_idx <- grep("post_repeal|fake_post", rn)[1]
  list(
    ge_b = cf[ge_idx, "Estimate"],
    ge_se = cf[ge_idx, "Std. Error"],
    ge_p = cf[ge_idx, "Pr(>|t|)"],
    rep_b = if (!is.na(rep_idx)) cf[rep_idx, "Estimate"] else NA,
    rep_se = if (!is.na(rep_idx)) cf[rep_idx, "Std. Error"] else NA,
    rep_p = if (!is.na(rep_idx)) cf[rep_idx, "Pr(>|t|)"] else NA,
    n = nobs(mod),
    r2 = fitstat(mod, "r2")$r2
  )
}

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================
cat("Generating Table 1: Summary Statistics...\n")

fp <- panel[forprofit == 1]
pub <- panel[forprofit == 0]
pre_fp <- panel[forprofit == 1 & year <= 2014]
pre_pub <- panel[forprofit == 0 & year <= 2014]

sink(file.path(out_dir, "tab1_summary.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Summary Statistics: Sub-Bachelor Completions by Institution Type}\n")
cat("\\label{tab:summary}\n\\begin{threeparttable}\n")
cat("\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lrrrrrr}\n\\toprule\n")
cat(" & \\multicolumn{3}{c}{For-Profit} & \\multicolumn{3}{c}{Public 2-Year} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat(" & Mean & SD & N & Mean & SD & N \\\\\n\\midrule\n")

vars <- list(
  list("Total Completions", "total_comp"),
  list("Black Completions", "black_comp"),
  list("Hispanic Completions", "hisp_comp"),
  list("White Completions", "white_comp"),
  list("Minority Share", "minority_share")
)

for (v in vars) {
  fp_vals <- fp[[v[[2]]]]
  pub_vals <- pub[[v[[2]]]]
  cat(sprintf("%s & %.1f & %.1f & %s & %.1f & %.1f & %s \\\\\n",
              v[[1]],
              mean(fp_vals, na.rm=T), sd(fp_vals, na.rm=T),
              format(sum(!is.na(fp_vals)), big.mark=","),
              mean(pub_vals, na.rm=T), sd(pub_vals, na.rm=T),
              format(sum(!is.na(pub_vals)), big.mark=",")))
}

cat("\\midrule\n")
cat(sprintf("Institutions & \\multicolumn{3}{c}{%s} & \\multicolumn{3}{c}{%s} \\\\\n",
            format(uniqueN(fp$unitid), big.mark=","),
            format(uniqueN(pub$unitid), big.mark=",")))
cat(sprintf("Years & \\multicolumn{3}{c}{%d--%d} & \\multicolumn{3}{c}{%d--%d} \\\\\n",
            min(fp$year), max(fp$year), min(pub$year), max(pub$year)))
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Sub-bachelor completions include certificates ($<$1 year, 1--2 years) and associate's degrees. Minority share is (Black + Hispanic) / Total completions. For-profit institutions have IPEDS control$=$3; public 2-year institutions have sector$=$4. Sample restricted to institutions with at least 10 completions in any year.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ==============================================================================
# TABLE 2: Main DD Results
# ==============================================================================
cat("Generating Table 2: Main DD Results...\n")

mods <- list(models$total, models$share, models$minority, models$white)
labels <- c("Log Total", "Minority Share", "Log Minority", "Log White")

sink(file.path(out_dir, "tab2_main.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Main Results: Effect of GE Rule on For-Profit Completions}\n")
cat("\\label{tab:main}\n\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n\\toprule\n")
cat(sprintf(" & (%d) & (%d) & (%d) & (%d) \\\\\n", 1, 2, 3, 4))
cat(sprintf(" & %s & %s & %s & %s \\\\\n", labels[1], labels[2], labels[3], labels[4]))
cat("\\midrule\n")

rows <- lapply(mods, extract_dd)

cat("For-Profit $\\times$ GE Active")
for (r in rows) cat(sprintf(" & %s", fmt_coef(r$ge_b, r$ge_p)))
cat(" \\\\\n")
for (r in rows) cat(sprintf(" & %s", fmt_se(r$ge_se)))
cat(" \\\\\n[0.5em]\n")

cat("For-Profit $\\times$ Post-Repeal")
for (r in rows) cat(sprintf(" & %s", fmt_coef(r$rep_b, r$rep_p)))
cat(" \\\\\n")
for (r in rows) cat(sprintf(" & %s", fmt_se(r$rep_se)))
cat(" \\\\\n\\midrule\n")

cat("Institution FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations"))
for (r in rows) cat(sprintf(" & %s", format(r$n, big.mark=",")))
cat(" \\\\\n")
cat(sprintf("$R^2$"))
for (r in rows) cat(sprintf(" & %.3f", r$r2))
cat(" \\\\\n\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Standard errors clustered at the institution level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. GE Active $=$ 2015--2018; Post-Repeal $=$ 2019--2023; reference period: 2007--2014. Sample: for-profit and public 2-year institutions. Column (4) uses white completions as a within-sector placebo: white completions declined more than minority completions at for-profits, so the minority share mechanically rose.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ==============================================================================
# TABLE 3: Event Study Coefficients
# ==============================================================================
cat("Generating Table 3: Event Study...\n")

ev_cf <- coeftable(models$event)
ev_years <- as.integer(gsub("year::(\\d+):forprofit", "\\1", rownames(ev_cf)))

sink(file.path(out_dir, "tab3_event.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Event Study: For-Profit $\\times$ Year Interactions on Minority Share}\n")
cat("\\label{tab:event}\n\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n\\toprule\n")
cat("Year & Coefficient & SE & 95\\% CI \\\\\n\\midrule\n")

for (i in seq_along(ev_years)) {
  yr <- ev_years[i]
  b <- ev_cf[i, "Estimate"]
  se <- ev_cf[i, "Std. Error"]
  p <- ev_cf[i, "Pr(>|t|)"]
  ci_lo <- b - 1.96 * se
  ci_hi <- b + 1.96 * se
  marker <- ""
  if (yr == 2015) marker <- " \\hline"
  cat(sprintf("%d & %s & %.4f & [%.4f, %.4f] \\\\%s\n",
              yr, fmt_coef(b, p), se, ci_lo, ci_hi, marker))
}

cat("\\midrule\n")
cat("Reference year & \\multicolumn{3}{c}{2014} \\\\\n")
cat(sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\\n", format(nobs(models$event), big.mark=",")))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Each coefficient represents the interaction of For-Profit $\\times$ Year relative to 2014. Standard errors clustered at the institution level. The horizontal line separates the pre-treatment period (2007--2014) from the GE-active and post-repeal periods (2015--2023). Coefficients for 2008--2010 show large pre-existing trends driven by Great Recession enrollment dynamics at for-profit colleges. From 2011--2014 the pre-trend is approximately flat.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ==============================================================================
# TABLE 4: Robustness
# ==============================================================================
cat("Generating Table 4: Robustness...\n")

rob_specs <- list(
  list(mod = rob_models$state_year_fe, label = "State $\\times$ Yr FE"),
  list(mod = rob_models$clean_pretrends, label = "Drop 2008--10"),
  list(mod = rob_models$all_awards, label = "All Awards"),
  list(mod = rob_models$intensive, label = "Intensive")
)

sink(file.path(out_dir, "tab4_robustness.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Robustness: Minority Completion Share}\n")
cat("\\label{tab:robustness}\n\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n\\toprule\n")
for (i in seq_along(rob_specs)) cat(sprintf(" & (%d)", i))
cat(" \\\\\n")
for (rs in rob_specs) cat(sprintf(" & %s", rs$label))
cat(" \\\\\n\\midrule\n")

rrows <- lapply(rob_specs, function(rs) extract_dd(rs$mod))

cat("For-Profit $\\times$ GE Active")
for (r in rrows) cat(sprintf(" & %s", fmt_coef(r$ge_b, r$ge_p)))
cat(" \\\\\n")
for (r in rrows) cat(sprintf(" & %s", fmt_se(r$ge_se)))
cat(" \\\\\n[0.5em]\n")

cat("For-Profit $\\times$ Post-Repeal")
for (r in rrows) cat(sprintf(" & %s", fmt_coef(r$rep_b, r$rep_p)))
cat(" \\\\\n")
for (r in rrows) cat(sprintf(" & %s", fmt_se(r$rep_se)))
cat(" \\\\\n\\midrule\n")

cat(sprintf("Observations"))
for (r in rrows) cat(sprintf(" & %s", format(r$n, big.mark=",")))
cat(" \\\\\n\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item \\textit{Notes:} Dependent variable: minority share of sub-bachelor completions (cols.\\ 1, 2, 4) or all completions (col.\\ 3). Standard errors clustered at institution level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$. Column (2) drops 2008--2010 to address Great Recession pre-trends (see Table~\\ref{tab:event}). Column (4) restricts to institution-years with positive minority completions.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (SDE)
# ==============================================================================
cat("Generating SDE table...\n")

# Use the clean-sample specification as the preferred estimate
clean_mod <- rob_models$clean_pretrends
clean_cf <- coeftable(clean_mod)

# For SDE, use unconditional SD from full panel
sde_outcomes <- list(
  list(label = "Minority Share", mod = clean_mod,
       sd_y = sd(panel$minority_share, na.rm = TRUE)),
  list(label = "Log Minority Comp.", mod = models$minority,
       sd_y = sd(panel$log_minority, na.rm = TRUE)),
  list(label = "Log Total Comp.", mod = models$total,
       sd_y = sd(panel$log_total, na.rm = TRUE))
)

classify <- function(sde_val) {
  if (sde_val < -0.15) return("Large negative")
  if (sde_val < -0.05) return("Moderate negative")
  if (sde_val < -0.005) return("Small negative")
  if (sde_val < 0.005) return("Null")
  if (sde_val < 0.05) return("Small positive")
  if (sde_val < 0.15) return("Moderate positive")
  return("Large positive")
}

sde_rows <- lapply(sde_outcomes, function(s) {
  cf <- coeftable(s$mod)
  ge_idx <- grep("ge_active", rownames(cf))[1]
  beta <- cf[ge_idx, "Estimate"]
  se_beta <- cf[ge_idx, "Std. Error"]
  sde <- beta / s$sd_y
  se_sde <- se_beta / s$sd_y
  data.frame(Outcome = s$label, Beta = beta, SE = se_beta,
             SD_Y = s$sd_y, SDE = sde, SE_SDE = se_sde,
             Classification = classify(sde))
})
sde_df <- do.call(rbind, sde_rows)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the Gainful Employment Rule, which imposed debt-to-earnings tests on for-profit college programs threatening federal aid eligibility, alter the racial composition of sub-bachelor credential attainment at for-profit institutions relative to public two-year colleges? ",
  "\\textbf{Policy mechanism:} The GE Rule imposed program-level debt-to-earnings ratio thresholds; programs failing two of three annual assessments lost Title IV eligibility, potentially closing pathways disproportionately used by minority students. The Trump administration repealed the rule effective July 2019. ",
  "\\textbf{Outcome definition:} Minority share is Black non-Hispanic plus Hispanic completers divided by total completers in sub-bachelor awards (certificates and associate's degrees) from IPEDS completions survey; log completions are log(count $+ 1$). ",
  "\\textbf{Treatment:} Binary; institution is for-profit during the GE-active period (2015--2018). ",
  sprintf("\\textbf{Data:} IPEDS completions by race and award level, 2011--2023 (preferred sample dropping Great Recession years with pre-existing trends), institution-year panel, %s for-profit and %s public two-year institutions, %s institution-year observations. ",
          format(uniqueN(panel[forprofit == 1 & year >= 2011, unitid]), big.mark = ","),
          format(uniqueN(panel[forprofit == 0 & year >= 2011, unitid]), big.mark = ","),
          format(nrow(panel[year >= 2011]), big.mark = ",")),
  "\\textbf{Method:} Difference-in-differences with institution and year fixed effects; standard errors clustered at the institution level. ",
  "\\textbf{Sample:} Degree-granting for-profit and public two-year institutions reporting sub-bachelor completions in IPEDS, restricted to institutions with at least 10 completions in any year; preferred specification drops 2008--2010 to address Great Recession pre-trends. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(out_dir, "tabF1_sde.tex"))
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Standardized Effect Sizes for Main Outcomes}\n")
cat("\\label{tab:sde}\n\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccl}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
for (i in seq_len(nrow(sde_df))) {
  cat(sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
              sde_df$Outcome[i], sde_df$Beta[i], sde_df$SE[i], sde_df$SD_Y[i],
              sde_df$SDE[i], sde_df$SE_SDE[i], sde_df$Classification[i]))
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\end{table}\n")
sink()

cat("All tables generated.\n")
