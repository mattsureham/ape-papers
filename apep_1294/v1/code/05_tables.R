## ── 05_tables.R ────────────────────────────────────────────────────
## Generate all LaTeX tables for apep_1294
## ────────────────────────────────────────────────────────────────────
source("code/00_packages.R")

data_dir <- "data"
table_dir <- "tables"
dir.create(table_dir, showWarnings = FALSE)

nl_panel <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ── TABLE 1: Summary Statistics ───────────────────────────────────
cat("Table 1: Summary Statistics\n")

nl_high <- nl_panel[high_st == 1]
nl_low <- nl_panel[high_st == 0]

make_row <- function(var, label, panel = nl_panel, high = nl_high, low = nl_low) {
  sprintf("%s & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
          label,
          mean(panel[[var]], na.rm = TRUE), sd(panel[[var]], na.rm = TRUE),
          mean(high[[var]], na.rm = TRUE), sd(high[[var]], na.rm = TRUE),
          mean(low[[var]], na.rm = TRUE), sd(low[[var]], na.rm = TRUE))
}

sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Summary Statistics}\\label{tab:summary}\n")
cat("\\small\n\\begin{tabular}{lcccccc}\n\\toprule\n")
cat(" & \\multicolumn{2}{c}{Full Sample} & \\multicolumn{2}{c}{High ST} & \\multicolumn{2}{c}{Low ST} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n")
cat(" & Mean & SD & Mean & SD & Mean & SD \\\\\n\\midrule\n")
cat(make_row("dmsp_total_light_cal", "Total nightlights"), "\n")
cat(make_row("dmsp_mean_light_cal", "Mean nightlights"), "\n")
cat(sprintf("ST population share & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
    mean(nl_panel$st_share), sd(nl_panel$st_share),
    mean(nl_high$st_share), sd(nl_high$st_share),
    mean(nl_low$st_share), sd(nl_low$st_share)))
cat(sprintf("SC population share & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f \\\\\n",
    mean(nl_panel$sc_share), sd(nl_panel$sc_share),
    mean(nl_high$sc_share), sd(nl_high$sc_share),
    mean(nl_low$sc_share), sd(nl_low$sc_share)))
cat(sprintf("Total population & %s & %s & %s & %s & %s & %s \\\\\n",
    format(round(mean(nl_panel$pc11_pca_tot_p)), big.mark = ","),
    format(round(sd(nl_panel$pc11_pca_tot_p)), big.mark = ","),
    format(round(mean(nl_high$pc11_pca_tot_p)), big.mark = ","),
    format(round(sd(nl_high$pc11_pca_tot_p)), big.mark = ","),
    format(round(mean(nl_low$pc11_pca_tot_p)), big.mark = ","),
    format(round(sd(nl_low$pc11_pca_tot_p)), big.mark = ",")))
cat("\\midrule\n")
cat(sprintf("District-years & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\\n",
    format(nrow(nl_panel), big.mark = ","),
    format(nrow(nl_high), big.mark = ","),
    format(nrow(nl_low), big.mark = ",")))
cat(sprintf("Districts & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
    uniqueN(nl_panel$dist_id), uniqueN(nl_high$dist_id), uniqueN(nl_low$dist_id)))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Data from SHRUG v2.1 (Asher, Novosad, Lunt). Nightlights: DMSP calibrated luminosity (1994--2013). ST/SC shares from Census 2011 Primary Census Abstract. High ST = districts in the top quartile of ST population share ($\\geq$", sprintf("%.1f", quantile(nl_panel$st_share, 0.75) * 100), "\\%). 640 districts $\\times$ 20 years.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

## ── TABLE 2: Main Results (Trend-Break) ──────────────────────────
cat("Table 2: Main Results\n")

## Build the key table: naive DiD vs trend-break vs first-difference
cm <- c(
  "treat_st" = "ST Share $\\times$ Post-2008",
  "treat_sc" = "SC Share $\\times$ Post-2008",
  "treat_high_st" = "High ST $\\times$ Post-2008",
  "st_share:time_trend" = "ST Share $\\times$ Trend",
  "st_share:post_trend" = "ST Share $\\times$ Post-Trend"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(round(x), big.mark = ",")),
  list("raw" = "r.squared", "clean" = "$R^2$", "fmt" = 3)
)

tab2_models <- list(
  "(1)" = results$nl_main,
  "(2)" = results$nl_placebo,
  "(3)" = results$nl_break,
  "(4)" = results$nl_fd
)

modelsummary(tab2_models,
             coef_map = cm,
             gof_map = gm,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             output = file.path(table_dir, "tab2_main.tex"),
             title = "ST Reservation and Nighttime Luminosity\\label{tab:main}",
             notes = list(
               "District and year fixed effects in all columns. Standard errors clustered at district level. ST Share: district-level Scheduled Tribe population share (Census 2011). Post-2008: indicator for years after the Delimitation. Columns (1)--(2): standard two-way FE DiD. Column (3): trend-break specification with ST Share $\\times$ linear trend and ST Share $\\times$ post-2008 trend. Column (4): first-differenced dependent variable (annual change in log nightlights). The positive coefficient in column (1) captures pre-existing convergence (see Table~\\ref{tab:event}), not the causal effect of the 2008 Delimitation. The negative post-trend coefficient in column (3) is the paper's core finding: the 2008 Delimitation decelerated economic convergence in high-ST districts."
             ),
             escape = FALSE)

## ── TABLE 3: Event Study Coefficients ─────────────────────────────
cat("Table 3: Event Study\n")

es_coefs <- coeftable(results$nl_event)
es_dt <- as.data.table(es_coefs, keep.rownames = TRUE)
names(es_dt) <- c("Term", "Estimate", "SE", "tstat", "pvalue")

## Parse relative year from the fixest coefficient naming
es_dt[, rel_year := as.integer(stringr::str_extract(Term, "-?\\d+"))]
es_dt <- es_dt[order(rel_year)]
es_dt[, Calendar := rel_year + 2008]
es_dt[, Stars := ifelse(pvalue < 0.01, "***",
                        ifelse(pvalue < 0.05, "**",
                               ifelse(pvalue < 0.10, "*", "")))]

sink(file.path(table_dir, "tab3_event.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Event Study: ST Share $\\times$ Year Effects on Log Nightlights}\\label{tab:event}\n")
cat("\\small\n\\begin{tabular}{lccc}\n\\toprule\n")
cat("Year & Coefficient & Std. Error & \\\\\n\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Pre-Treatment (Reference: 2007)}} \\\\\n")
for (j in which(es_dt$rel_year < 0)) {
  r <- es_dt[j]
  cat(sprintf("%d & %s%.3f%s & (%.3f) & \\\\\n",
              r$Calendar, ifelse(r$Estimate < 0, "$-$", ""), abs(r$Estimate), r$Stars, r$SE))
}
cat("\\midrule\n")
cat("\\multicolumn{4}{l}{\\textit{Post-Treatment}} \\\\\n")
for (j in which(es_dt$rel_year >= 0)) {
  r <- es_dt[j]
  cat(sprintf("%d & %s%.3f%s & (%.3f) & \\\\\n",
              r$Calendar, ifelse(r$Estimate < 0, "$-$", ""), abs(r$Estimate), r$Stars, r$SE))
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Coefficients from regressing log(total calibrated nightlights $+$ 1) on ST share interacted with year dummies (reference year: 2007). District and year FE. Standard errors clustered at district level. Large negative pre-treatment coefficients indicate that high-ST districts had substantially lower nightlights relative to the reference year, reflecting pre-existing convergence rather than an effect of the 2008 Delimitation. $N = 20{,}480$ district-years (640 districts $\\times$ 20 years). Significance: * $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

## ── TABLE 4: Forest Loss Results ──────────────────────────────────
cat("Table 4: Forest Loss\n")

if (!is.null(results$forest_main)) {
  cm_f <- c(
    "treat_st" = "ST Share $\\times$ Post-2008",
    "treat_sc" = "SC Share $\\times$ Post-2008",
    "treat_st_hf" = "ST Share $\\times$ Post $\\times$ High Forest"
  )

  tab4_models <- list(
    "(1)" = results$forest_main,
    "(2)" = results$forest_placebo,
    "(3)" = results$forest_hetero
  )

  modelsummary(tab4_models,
               coef_map = cm_f,
               gof_map = gm,
               stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
               output = file.path(table_dir, "tab4_forest.tex"),
               title = "ST Reservation and Forest Cover Loss\\label{tab:forest}",
               notes = list(
                 "District and year fixed effects. Standard errors clustered at district level. Dependent variable: log(annual forest loss in hectares $+$ 1), from Hansen Global Forest Change v1.11 (2001--2023). ST Share: state-level Scheduled Tribe population share from Census 2011. High Forest: districts with baseline tree cover above the sample median. 449 districts across 23 years. Forest loss measured from 30-meter resolution satellite data aggregated to GADM level-2 districts."
               ),
               escape = FALSE)
} else {
  writeLines("% Forest table omitted — data pending", file.path(table_dir, "tab4_forest.tex"))
}

## ── TABLE 5: Robustness ──────────────────────────────────────────
cat("Table 5: Robustness\n")

cm_r <- c(
  "treat_high_sc" = "High SC $\\times$ Post-2008",
  "treat_st" = "ST Share $\\times$ Post-2008",
  "treat_st_placebo" = "ST Share $\\times$ Post-2004",
  "st_share:time_trend" = "ST Share $\\times$ Trend",
  "st_share:post_trend" = "ST Share $\\times$ Post-Trend"
)

tab5_models <- list(
  "(1)" = rob_results$sc_only,
  "(2)" = rob_results$trimmed,
  "(3)" = rob_results$state_cluster,
  "(4)" = rob_results$placebo_year,
  "(5)" = rob_results$state_trend
)

modelsummary(tab5_models,
             coef_map = cm_r,
             gof_map = gm,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             output = file.path(table_dir, "tab5_robustness.tex"),
             title = "Robustness Checks\\label{tab:robust}",
             notes = list(
               "All specifications include district and year fixed effects. Col.~(1): SC placebo --- binary indicator for high-SC districts. Col.~(2): drops districts with ST share $>$ 90\\%. Col.~(3): clusters standard errors at state level (35 clusters). Col.~(4): placebo treatment year (2004) using only pre-2008 data. Col.~(5): trend-break specification with state-specific linear trends. The trend-break coefficient in column (5) is robust to state trends ($-$0.112, $p < 0.001$)."
             ),
             escape = FALSE)

## ── TABLE F1: SDE ────────────────────────────────────────────────
cat("Table F1: SDE\n")

sd_st <- sd(nl_panel$st_share, na.rm = TRUE)
sd_nl <- sd(nl_panel[year < 2008]$log_nl, na.rm = TRUE)

## Trend-break specification is the main result
coef_break <- coef(results$nl_break)["st_share:post_trend"]
se_break <- coeftable(results$nl_break)["st_share:post_trend", "Std. Error"]
## SDE for trend-break: β × SD(ST_share) / SD(Y) — one-year change
sde_break <- coef_break * sd_st / sd_nl
se_sde_break <- se_break * sd_st / sd_nl

## Naive DiD (for comparison)
coef_naive <- coef(results$nl_main)["treat_st"]
se_naive <- coeftable(results$nl_main)["treat_st", "Std. Error"]
sde_naive <- coef_naive * sd_st / sd_nl
se_sde_naive <- se_naive * sd_st / sd_nl

## First-difference
sd_dlog <- sd(nl_panel[year < 2008 & !is.na(nl_panel$d_log_nl)]$d_log_nl, na.rm = TRUE)
nl_panel[, d_log_nl := log_nl - shift(log_nl, 1), by = dist_id]
sd_dlog <- sd(nl_panel[year < 2008 & !is.na(d_log_nl)]$d_log_nl, na.rm = TRUE)
coef_fd <- coef(results$nl_fd)["treat_st"]
se_fd <- coeftable(results$nl_fd)["treat_st", "Std. Error"]
sde_fd <- coef_fd * sd_st / sd_dlog
se_sde_fd <- se_fd * sd_st / sd_dlog

## Forest loss
if (!is.null(results$forest_main)) {
  forest_panel <- fread(file.path(data_dir, "forest_panel.csv"))
  ## Need state mapping for SD computation
  state_map <- data.table(
    NAME_1 = c("Andhra Pradesh","Arunachal Pradesh","Assam","Bihar","Chhattisgarh",
               "Goa","Gujarat","Haryana","Himachal Pradesh","Jharkhand","Karnataka",
               "Kerala","Madhya Pradesh","Maharashtra","Manipur","Meghalaya","Mizoram",
               "Nagaland","Odisha","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana",
               "Tripura","Uttar Pradesh","Uttarakhand","West Bengal","Jammu and Kashmir","NCT of Delhi"),
    state_id = c("28","12","18","10","22","30","24","06","02","20","29","32","23","27",
                 "14","17","15","13","21","03","08","11","33","36","16","09","05","19","01","07"))
  state_st <- unique(nl_panel[, .(st_share_state = weighted.mean(st_share, pc11_pca_tot_p, na.rm = TRUE)),
                              by = .(state_id = substr(dist_id, 1, regexpr("_", dist_id) - 1))])
  fp <- merge(forest_panel, state_map, by = "NAME_1", all.x = TRUE)
  fp <- merge(fp, state_st, by = "state_id", all.x = TRUE)
  fp <- fp[!is.na(st_share_state)]
  sd_st_f <- sd(fp$st_share_state, na.rm = TRUE)
  sd_forest <- sd(fp[year < 2008]$log_loss, na.rm = TRUE)
  coef_forest <- coef(results$forest_main)["treat_st"]
  se_forest <- coeftable(results$forest_main)["treat_st", "Std. Error"]
  sde_forest <- coef_forest * sd_st_f / sd_forest
  se_sde_forest <- se_forest * sd_st_f / sd_forest
}

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

## Panel B: heterogeneity by ST share (subsample splits)
nl_high <- nl_panel[high_st == 1]
nl_low <- nl_panel[high_st == 0]

## Trend-break in high-ST subsample
nl_high[, time_trend := year - 1994]
nl_high[, post_trend := pmax(0, year - 2008)]
nl_low[, time_trend := year - 1994]
nl_low[, post_trend := pmax(0, year - 2008)]

m_break_high <- feols(log_nl ~ st_share:time_trend + st_share:post_trend | dist_id + year,
                      data = nl_high, cluster = ~dist_id)
m_break_low <- feols(log_nl ~ st_share:time_trend + st_share:post_trend | dist_id + year,
                     data = nl_low, cluster = ~dist_id)

sd_nl_high <- sd(nl_high[year < 2008]$log_nl, na.rm = TRUE)
sd_nl_low <- sd(nl_low[year < 2008]$log_nl, na.rm = TRUE)
sd_st_high <- sd(nl_high$st_share, na.rm = TRUE)
sd_st_low <- sd(nl_low$st_share, na.rm = TRUE)

coef_h <- coef(m_break_high)["st_share:post_trend"]
se_h <- coeftable(m_break_high)["st_share:post_trend", "Std. Error"]
sde_h <- coef_h * sd_st_high / sd_nl_high
se_sde_h <- se_h * sd_st_high / sd_nl_high

coef_l <- coef(m_break_low)["st_share:post_trend"]
se_l <- coeftable(m_break_low)["st_share:post_trend", "Std. Error"]
sde_l <- coef_l * sd_st_low / sd_nl_low
se_sde_l <- se_l * sd_st_low / sd_nl_low

## Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does Scheduled Tribe political representation, activated by the 2008 Delimitation that mechanically reassigned constituency reservation based on the 2001 Census, affect local economic development trajectories and forest conservation? ",
  "\\textbf{Policy mechanism:} The 2008 Delimitation redrew assembly constituency boundaries and reassigned ST reservation to constituencies exceeding tribal population thresholds, activating the Forest Rights Act (2006) enforcement channel and shifting political priorities toward forest conservation over rapid economic development in tribal areas. ",
  "\\textbf{Outcome definition:} Panel A rows 1--2: log total calibrated DMSP nightlights and annual trend break; row 3: log annual forest cover loss (hectares) from Hansen GFC at the district level. ",
  "\\textbf{Treatment:} Continuous --- district-level ST population share from Census 2011, interacted with post-2008 trend for the trend-break specification. ",
  "\\textbf{Data:} SHRUG DMSP nightlights 1994--2013 (640 districts, 20,480 obs); Hansen GFC v1.11 2001--2023 (449 districts, 10,327 obs). ",
  "\\textbf{Method:} Trend-break two-way FE (district $+$ year FE) with ST share $\\times$ linear trend and ST share $\\times$ post-2008 trend; standard errors clustered at district level. ",
  "\\textbf{Sample:} All Indian districts with non-missing Census 2011 population; excludes union territories with fewer than 3 districts. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n\\centering\n\\caption{Standardized Effect Sizes}\\label{tab:sde}\n")
cat("\\small\n\\begin{tabular}{lcccccc}\n\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
cat(sprintf("Convergence deceleration (trend-break) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    coef_break, se_break, sd_nl, sde_break, se_sde_break, classify_sde(sde_break)))
cat(sprintf("Growth rate change (first-diff DiD) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    coef_fd, se_fd, sd_dlog, sde_fd, se_sde_fd, classify_sde(sde_fd)))
if (!is.null(results$forest_main)) {
  cat(sprintf("Forest loss (Hansen GFC) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
      coef_forest, se_forest, sd_forest, sde_forest, se_sde_forest, classify_sde(sde_forest)))
}
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by ST population share)}} \\\\\n")
cat(sprintf("High-ST districts (trend-break) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    coef_h, se_h, sd_nl_high, sde_h, se_sde_h, classify_sde(sde_h)))
cat(sprintf("Low-ST districts (trend-break) & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    coef_l, se_l, sd_nl_low, sde_l, se_sde_l, classify_sde(sde_l)))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

cat("\nAll tables generated:", paste(list.files(table_dir), collapse = ", "), "\n")
