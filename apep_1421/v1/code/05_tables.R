## ── 05_tables.R ────────────────────────────────────────────────
## Generate all LaTeX tables
## ────────────────────────────────────────────────────────────────

source("00_packages.R")

out_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

results <- readRDS(file.path(out_dir, "main_results.rds"))
robust  <- readRDS(file.path(out_dir, "robustness_results.rds"))
panel   <- readRDS(file.path(out_dir, "panel.rds"))

## ═══════════════════════════════════════════════════════════════
## Table 1: Summary Statistics
## ═══════════════════════════════════════════════════════════════

ss <- results$sumstats
# Format for LaTeX
lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Mining vs.\\ Non-Mining Districts (Pre-Treatment)}",
  "\\label{tab:sumstats}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Mining Districts} & \\multicolumn{2}{c}{Non-Mining Districts} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(ss)) {
  lines <- c(lines, sprintf("%s & %.3f & %.3f & %.3f & %.3f \\\\",
                            ss$Variable[i],
                            ss$Mining_Mean[i], ss$Mining_SD[i],
                            ss$NonMining_Mean[i], ss$NonMining_SD[i]))
}

n_mining <- uniqueN(panel[is_mining == 1 & year < 2015]$dist_id)
n_nonmining <- uniqueN(panel[is_mining == 0 & year < 2015]$dist_id)

lines <- c(lines,
  "\\midrule",
  sprintf("Districts & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\", n_mining, n_nonmining),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Pre-treatment means (2012--2014) for districts with and without mining employment in Economic Census 2013. Nightlight intensity is VIIRS annual mean radiance. Mining employment is from SHRUG Economic Census 2013 (\\texttt{ec13\\_emp\\_pub\\_mines}). Population and demographic variables from Census 2011.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(lines, file.path(tab_dir, "tab1_sumstats.tex"))

## ═══════════════════════════════════════════════════════════════
## Table 2: Main Results
## ═══════════════════════════════════════════════════════════════

tex_main <- capture.output(
  etable(results$m1, results$m2, results$m3, results$m4,
         tex = TRUE,
         title = "Effect of DMF Revenue on Nightlight Intensity",
         label = "tab:main",
         headers = c("Binary", "Log Mining", "Mining Share", "State$\\times$Year FE"),
         se.below = TRUE,
         notes = paste0("\\textit{Notes:} Dependent variable is log VIIRS nightlight intensity. ",
                        "Binary = mining district indicator $\\times$ post-2015. ",
                        "Log Mining = log(mining employment + 1) $\\times$ post-2015. ",
                        "Mining Share = mining employment share $\\times$ post-2015. ",
                        "Column (4) adds state $\\times$ year fixed effects. ",
                        "All specifications include district and year fixed effects. ",
                        "Standard errors clustered at state level in parentheses. ",
                        "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
         fitstat = ~ n + r2 + wr2)
)
writeLines(tex_main, file.path(tab_dir, "tab2_main.tex"))

## ═══════════════════════════════════════════════════════════════
## Table 3: Event Study
## ═══════════════════════════════════════════════════════════════

es <- results$es
es_coefs <- coeftable(es)
es_rows <- rownames(es_coefs)
# Parse relative year from coefficient names
parse_year <- function(x) {
  m <- regmatches(x, regexpr("-?[0-9]+", x))
  as.integer(m)
}

es_dt <- data.table(
  rel_year = sapply(es_rows, parse_year),
  coef = es_coefs[, 1],
  se = es_coefs[, 2],
  pval = es_coefs[, 4]
)
es_dt <- es_dt[order(rel_year)]

# Add reference year
es_dt <- rbind(data.table(rel_year = -1, coef = 0, se = NA, pval = NA), es_dt)
es_dt <- es_dt[order(rel_year)]

# Stars
es_dt[, stars := ifelse(is.na(pval), "", ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", ""))))]

es_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Effects of Mining Intensity on Nightlights}",
  "\\label{tab:eventstudy}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Year Relative to 2015 & Coefficient & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_dt)) {
  yr_label <- ifelse(es_dt$rel_year[i] == -1, "$-1$ (ref.)",
                     paste0("$", ifelse(es_dt$rel_year[i] > 0, "+", ""), es_dt$rel_year[i], "$"))
  if (is.na(es_dt$se[i])) {
    es_lines <- c(es_lines, sprintf("%s & --- & --- \\\\", yr_label))
  } else {
    es_lines <- c(es_lines, sprintf("%s & %.4f%s & (%.4f) \\\\",
                                    yr_label, es_dt$coef[i], es_dt$stars[i], es_dt$se[i]))
  }
}

es_lines <- c(es_lines,
  "\\midrule",
  sprintf("Observations & \\multicolumn{2}{c}{%s} \\\\", format(nrow(panel), big.mark = ",")),
  sprintf("Districts & \\multicolumn{2}{c}{%d} \\\\", uniqueN(panel$dist_id)),
  "District FE & \\multicolumn{2}{c}{Yes} \\\\",
  "Year FE & \\multicolumn{2}{c}{Yes} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Coefficients from interacting log mining employment with year indicators (base year: $t = -1$, i.e., 2014). Dependent variable is log nightlight intensity. District and year fixed effects included. Standard errors clustered at state level. $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(es_lines, file.path(tab_dir, "tab3_eventstudy.tex"))

## ═══════════════════════════════════════════════════════════════
## Table 4: Robustness
## ═══════════════════════════════════════════════════════════════

tex_robust <- capture.output(
  etable(robust$placebo, robust$trim, robust$alt_outcome, robust$top_states, robust$spillover,
         tex = TRUE,
         title = "Robustness Checks",
         label = "tab:robust",
         headers = c("Placebo 2013", "Trimmed", "Total Light", "Top 6 States", "Spillover"),
         se.below = TRUE,
         notes = paste0("\\textit{Notes:} Column (1): placebo test with fake treatment in 2013, pre-treatment data only. ",
                        "Column (2): drops districts in top decile of mining employment. ",
                        "Column (3): uses log total light (sum) as outcome. ",
                        "Column (4): restricts to top 6 mining states (Odisha, Jharkhand, Chhattisgarh, Rajasthan, MP, Telangana). ",
                        "Column (5): tests for spillovers to non-mining districts in mining states. ",
                        "Standard errors clustered at state level. ",
                        "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."),
         fitstat = ~ n + wr2)
)
writeLines(tex_robust, file.path(tab_dir, "tab4_robust.tex"))

## ═══════════════════════════════════════════════════════════════
## Table F1: Standardized Effect Sizes (SDE) — Appendix
## ═══════════════════════════════════════════════════════════════

# Compute SDEs from main specification (m2: log mining × post)
m2 <- results$m2
beta_main <- coef(m2)["treat_log"]
se_main <- se(m2)["treat_log"]

# SD of outcome in pre-treatment period
sd_y_pre <- sd(panel[year < 2015]$log_light, na.rm = TRUE)

# For binary treatment (m1)
beta_bin <- coef(results$m1)["treat_binary"]
se_bin <- se(results$m1)["treat_binary"]

# SDE = beta / SD(Y)
sde_main <- beta_main / sd_y_pre
sde_se_main <- se_main / sd_y_pre
sde_bin <- beta_bin / sd_y_pre
sde_se_bin <- se_bin / sd_y_pre

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

## ── Panel B: Heterogeneity by ST share (above/below median) ───
med_st <- median(panel$st_share, na.rm = TRUE)
panel[, high_st := as.integer(st_share > med_st)]

m_high_st <- feols(log_light ~ treat_log | dist_id + year,
                   data = panel[high_st == 1], cluster = ~state_id)
m_low_st <- feols(log_light ~ treat_log | dist_id + year,
                  data = panel[high_st == 0], cluster = ~state_id)

beta_hst <- coef(m_high_st)["treat_log"]
se_hst <- se(m_high_st)["treat_log"]
sde_hst <- beta_hst / sd_y_pre
sde_se_hst <- se_hst / sd_y_pre

beta_lst <- coef(m_low_st)["treat_log"]
se_lst <- se(m_low_st)["treat_log"]
sde_lst <- beta_lst / sd_y_pre
sde_se_lst <- se_lst / sd_y_pre

## ── SDE Notes ──────────────────────────────────────────────────
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does mandated redistribution of mineral royalties through District Mineral Foundations improve local economic activity in mining-affected districts? ",
  "\\textbf{Policy mechanism:} The 2015 MMDR Amendment requires mining leaseholders to contribute 30\\% (pre-2015 leases) or 10\\% (post-2015 leases) of royalties to DMFs in each mining district, with 70\\% earmarked for water, health, education, and environment and 30\\% for physical infrastructure. ",
  "\\textbf{Outcome definition:} Log mean annual VIIRS nightlight radiance at the district level, a satellite-based proxy for local economic activity. ",
  "\\textbf{Treatment:} Continuous; log mining employment from Economic Census 2013 interacted with post-2015 indicator (dose-response), and binary mining district indicator. ",
  "\\textbf{Data:} SHRUG v2.1 (Harvard Dataverse), 640 districts, 2012--2021, district-year panel (6,400 obs). ",
  "\\textbf{Method:} Two-way fixed effects (district + year), standard errors clustered at state level (35 clusters). ",
  "\\textbf{Sample:} All Indian districts in SHRUG with non-missing VIIRS nightlights and Census 2011 population data. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log nightlight intensity. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

## ── Write SDE table ────────────────────────────────────────────
sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Log nightlights (dose) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, sde_se_main, classify_sde(sde_main)),
  sprintf("Log nightlights (binary) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_bin, se_bin, sd_y_pre, sde_bin, sde_se_bin, classify_sde(sde_bin)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by Scheduled Tribe share)}} \\\\",
  sprintf("High ST share districts & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_hst, se_hst, sd_y_pre, sde_hst, sde_se_hst, classify_sde(sde_hst)),
  sprintf("Low ST share districts & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_lst, se_lst, sd_y_pre, sde_lst, sde_se_lst, classify_sde(sde_lst)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, file.path(tab_dir, "tabF1_sde.tex"))

cat("All tables generated.\n")
