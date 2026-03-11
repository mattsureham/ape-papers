# ==============================================================================
# 06_tables.R — Generate all LaTeX tables
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

source("00_packages.R")

# --- Load data and models ---
nga_rice <- fread(file.path(DATA_DIR, "nga_rice.csv"))
nga_rice[, year_month := as.Date(year_month)]
nga_analysis <- fread(file.path(DATA_DIR, "nga_analysis.csv"))
nga_analysis[, year_month := as.Date(year_month)]
market_coords <- fread(file.path(DATA_DIR, "market_coords.csv"))

m_basic <- readRDS(file.path(DATA_DIR, "model_main_basic.rds"))
m_commodity <- readRDS(file.path(DATA_DIR, "model_main_commodity.rds"))
m_continuous <- readRDS(file.path(DATA_DIR, "model_main_continuous.rds"))
m_bins <- readRDS(file.path(DATA_DIR, "model_distance_bins.rds"))

commodity_results <- fread(file.path(DATA_DIR, "commodity_results.csv"))

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================

# Rice prices by period and market type
rice_pre <- nga_rice[post == 0]
rice_post <- nga_rice[post == 1]
rice_border <- nga_rice[border_market == 1]
rice_interior <- nga_rice[border_market == 0]

summary_rows <- data.table(
  Variable = c(
    "\\emph{Full Sample}",
    "\\quad Price (NGN/kg)",
    "\\quad Log Price",
    "\\emph{Pre-Closure (Jan 2017--Jul 2019)}",
    "\\quad Price (NGN/kg)",
    "\\quad Log Price",
    "\\emph{Post-Closure (Aug 2019--Dec 2021)}",
    "\\quad Price (NGN/kg)",
    "\\quad Log Price",
    "\\emph{Border Markets ($<$150km)}",
    "\\quad Price (NGN/kg)",
    "\\quad Log Price",
    "\\quad Dist.~to border (km)",
    "\\emph{Interior Markets ($\\geq$150km)}",
    "\\quad Price (NGN/kg)",
    "\\quad Log Price",
    "\\quad Dist.~to border (km)"
  ),
  N = c(
    "", as.character(c(nrow(nga_rice), nrow(nga_rice))),
    "", as.character(c(nrow(rice_pre), nrow(rice_pre))),
    "", as.character(c(nrow(rice_post), nrow(rice_post))),
    "", as.character(c(nrow(rice_border), nrow(rice_border), nrow(rice_border))),
    "", as.character(c(nrow(rice_interior), nrow(rice_interior), nrow(rice_interior)))
  ),
  Mean = c(
    "", sprintf("%.1f", c(mean(nga_rice$price_per_kg, na.rm=T), mean(nga_rice$log_price, na.rm=T))),
    "", sprintf("%.1f", c(mean(rice_pre$price_per_kg, na.rm=T), mean(rice_pre$log_price, na.rm=T))),
    "", sprintf("%.1f", c(mean(rice_post$price_per_kg, na.rm=T), mean(rice_post$log_price, na.rm=T))),
    "", sprintf("%.1f", c(mean(rice_border$price_per_kg, na.rm=T), mean(rice_border$log_price, na.rm=T), mean(rice_border$dist_to_border_km, na.rm=T))),
    "", sprintf("%.1f", c(mean(rice_interior$price_per_kg, na.rm=T), mean(rice_interior$log_price, na.rm=T), mean(rice_interior$dist_to_border_km, na.rm=T)))
  ),
  SD = c(
    "", sprintf("%.1f", c(sd(nga_rice$price_per_kg, na.rm=T), sd(nga_rice$log_price, na.rm=T))),
    "", sprintf("%.1f", c(sd(rice_pre$price_per_kg, na.rm=T), sd(rice_pre$log_price, na.rm=T))),
    "", sprintf("%.1f", c(sd(rice_post$price_per_kg, na.rm=T), sd(rice_post$log_price, na.rm=T))),
    "", sprintf("%.1f", c(sd(rice_border$price_per_kg, na.rm=T), sd(rice_border$log_price, na.rm=T), sd(rice_border$dist_to_border_km, na.rm=T))),
    "", sprintf("%.1f", c(sd(rice_interior$price_per_kg, na.rm=T), sd(rice_interior$log_price, na.rm=T), sd(rice_interior$dist_to_border_km, na.rm=T)))
  )
)

# Write to LaTeX
tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Rice Prices in Nigerian Markets}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrr}\n",
  "\\toprule\n",
  " & N & Mean & SD \\\\\n",
  "\\midrule\n",
  paste(apply(summary_rows[, .(Variable, N, Mean, SD)], 1,
              function(r) paste(r, collapse = " & ")),
        collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} Data from WFP Global Food Prices Database via Humanitarian Data Exchange. ",
  "Sample restricted to rice commodities in markets with available coordinates, ",
  "January 2017--December 2021. Border markets are defined as those within 150 km of the nearest ",
  "Nigerian land border. The border closure took effect August 20, 2019.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(TAB_DIR, "tab1_summary.tex"))

# ==============================================================================
# TABLE 2: Main Results
# ==============================================================================

# Use modelsummary for main regression table
models_main <- list(
  "(1)" = m_basic,
  "(2)" = m_commodity,
  "(3)" = m_continuous,
  "(4)" = m_bins
)

modelsummary(
  models_main,
  output = file.path(TAB_DIR, "tab2_main_results.tex"),
  stars = c('*' = .1, '**' = .05, '***' = .01),
  coef_rename = c(
    "border_market:post" = "Border $\\times$ Post",
    "inv_dist:post" = "(1/Distance) $\\times$ Post",
    "dist_bin::0-100km:post" = "0--100km $\\times$ Post",
    "dist_bin::100-200km:post" = "100--200km $\\times$ Post"
  ),
  gof_map = c("nobs", "r.squared"),
  title = "Effect of Border Closure on Rice Prices\\label{tab:main}",
  notes = c(
    "Standard errors clustered at the market level in parentheses.",
    "* p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
    "All specifications include market and month fixed effects.",
    "Column (1): binary treatment (border market $<$150km).",
    "Column (2): adds commodity (rice subtype) fixed effects.",
    "Column (3): continuous treatment using inverse distance.",
    "Column (4): distance bins relative to 200+ km reference."
  ),
  escape = FALSE
)

# ==============================================================================
# TABLE 3: Commodity Heterogeneity
# ==============================================================================

# Only include commodities with actual results
tab3_rows <- commodity_results[!is.na(estimate), .(
  Commodity = c("Rice", "Maize", "Sorghum", "Millet")[
    match(commodity, c("rice", "maize", "sorghum", "millet"))],
  Estimate = sprintf("%.4f", estimate),
  SE = sprintf("(%.4f)", se),
  N = formatC(n, format = "d", big.mark = ","),
  Markets = as.character(n_markets)
)]

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Border Closure Effects by Commodity Type}\n",
  "\\label{tab:commodity}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Commodity & Estimate & SE & N & Markets \\\\\n",
  "\\midrule\n",
  paste(apply(tab3_rows, 1, function(r) paste(r, collapse = " & ")),
        collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} Each row reports a separate DiD regression of log price on ",
  "Border Market $\\times$ Post, with market and month fixed effects. ",
  "Standard errors clustered at the market level. ",
  "* p$<$0.10, ** p$<$0.05, *** p$<$0.01.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, file.path(TAB_DIR, "tab3_commodity.tex"))

# ==============================================================================
# TABLE 4: Robustness summary
# ==============================================================================

# Collect robustness results
window_res <- fread(file.path(DATA_DIR, "robustness_windows.csv"))
threshold_res <- fread(file.path(DATA_DIR, "robustness_thresholds.csv"))
ri_res <- fread(file.path(DATA_DIR, "robustness_ri.csv"))
placebo_timing <- fread(file.path(DATA_DIR, "robustness_placebo_timing.csv"))

# Main estimate
main_est <- coef(m_basic)["border_market:post"]
main_se <- se(m_basic)["border_market:post"]

# Exclude 250km threshold (only 1 control market)
threshold_valid <- threshold_res[threshold_km <= 200]

robustness_rows <- rbind(
  data.table(Test = "Main specification", Estimate = main_est, SE = main_se,
             N = nrow(nga_rice),
             Inference = sprintf("p = %.3f", 2 * pnorm(-abs(main_est/main_se)))),
  data.table(Test = paste0("Window: ", window_res$window),
             Estimate = window_res$estimate, SE = window_res$se,
             N = window_res$n,
             Inference = sprintf("p = %.3f", 2 * pnorm(-abs(window_res$estimate/window_res$se)))),
  data.table(Test = paste0("Threshold: ", threshold_valid$threshold_km, "km"),
             Estimate = threshold_valid$estimate, SE = threshold_valid$se,
             N = nrow(nga_rice),
             Inference = sprintf("p = %.3f", 2 * pnorm(-abs(threshold_valid$estimate/threshold_valid$se)))),
  data.table(Test = "Randomization inference",
             Estimate = ri_res$actual_estimate, SE = NA_real_,
             N = nrow(nga_rice),
             Inference = sprintf("RI p = %.3f", ri_res$ri_p_value)),
  data.table(Test = "Placebo timing (Aug 2018)",
             Estimate = placebo_timing$estimate, SE = placebo_timing$se,
             N = placebo_timing$n,
             Inference = sprintf("p = %.3f", 2 * pnorm(-abs(placebo_timing$estimate/placebo_timing$se))))
)

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness of Main Rice Price Results}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  "Specification & Estimate & SE & N & Inference \\\\\n",
  "\\midrule\n",
  paste(apply(robustness_rows, 1, function(r) {
    paste(r[1],
          ifelse(is.na(as.numeric(r[2])), "---", sprintf("%.4f", as.numeric(r[2]))),
          ifelse(is.na(as.numeric(r[3])), "---", sprintf("(%.4f)", as.numeric(r[3]))),
          formatC(as.numeric(r[4]), format = "d", big.mark = ","),
          r[5], sep = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} All specifications estimate the effect of border closure on log rice prices. ",
  "Main specification: market and month FE, SEs clustered at market level. ",
  "Window restrictions vary the pre/post sample length. ",
  "Threshold alternatives vary the border/interior cutoff distance. ",
  "RI p-value from 1,000 permutations of border/interior assignment. ",
  "Placebo timing applies a fake shock in August 2018 using pre-closure data only.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(TAB_DIR, "tab4_robustness.tex"))

# ==============================================================================
# TABLE F1: Standardized Effect Sizes
# ==============================================================================

# Extract main estimate and compute SDE
beta_main <- coef(m_basic)["border_market:post"]
se_main <- se(m_basic)["border_market:post"]
sd_y <- sd(nga_rice$log_price, na.rm = TRUE)

sde_main <- beta_main / sd_y
se_sde_main <- se_main / sd_y

classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# Get commodity-specific SDEs
sde_rows <- list()
sde_rows[["rice"]] <- data.table(
  Outcome = "Log rice price",
  Spec = "Table 2, Col. 1",
  Beta = beta_main,
  SD_Y = sd_y,
  SDE = sde_main,
  SE_SDE = se_sde_main,
  Classification = classify_sde(sde_main)
)

# Add maize and sorghum if available
for (cg in c("maize", "sorghum")) {
  cr <- commodity_results[commodity == cg]
  if (nrow(cr) > 0 & !is.na(cr$estimate)) {
    cg_data <- nga_analysis[commodity_group == cg]
    sd_y_cg <- sd(log(cg_data$price[cg_data$price > 0]), na.rm = TRUE)
    if (!is.na(sd_y_cg) & sd_y_cg > 0) {
      sde_rows[[cg]] <- data.table(
        Outcome = paste0("Log ", cg, " price"),
        Spec = "Table 3",
        Beta = cr$estimate,
        SD_Y = sd_y_cg,
        SDE = cr$estimate / sd_y_cg,
        SE_SDE = cr$se / sd_y_cg,
        Classification = classify_sde(cr$estimate / sd_y_cg)
      )
    }
  }
}

sde_dt <- rbindlist(sde_rows)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  paste(apply(sde_dt, 1, function(r) {
    paste(r[1], r[2],
          sprintf("%.4f", as.numeric(r[3])),
          sprintf("%.3f", as.numeric(r[4])),
          sprintf("%.4f", as.numeric(r[5])),
          sprintf("%.4f", as.numeric(r[6])),
          r[7], sep = " & ")
  }), collapse = " \\\\\n"),
  " \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\emph{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study ",
  "comparison of treatment effect magnitudes. For the binary (0/1) border market treatment, ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and SE(SDE) $= \\text{SE}(\\hat{\\beta}) / \\text{SD}(Y)$. ",
  "SD($Y$) is the unconditional standard deviation of the log price outcome from Table~\\ref{tab:summary}.\n",
  "\\item \\textbf{Research question:} Does Nigeria's 2019 land border closure increase food prices ",
  "in border-proximate markets relative to interior markets?\n",
  "\\item \\textbf{Treatment:} Binary (0/1) indicator for markets within 150\\,km of the nearest land border.\n",
  "\\item \\textbf{Data:} WFP Global Food Prices Database (HDX), monthly market-level observations, 2017--2021.\n",
  "\\item \\textbf{Method:} Difference-in-differences with market and month fixed effects, standard errors ",
  "clustered at the market level.\n",
  "\\item \\textbf{Sample:} Nigerian markets with rice/cereal price data and available geographic coordinates.\n",
  "\\item Classification thresholds: large negative ($<$$-$0.15), moderate negative ($-$0.15 to $-$0.05), ",
  "small negative ($-$0.05 to $-$0.005), null ($-$0.005 to 0.005), small positive (0.005 to 0.05), ",
  "moderate positive (0.05 to 0.15), large positive ($>$0.15). ",
  "Classification labels refer to the magnitude of the standardized point estimate, ",
  "not to statistical significance. ``Null'' denotes a near-zero effect size ",
  "($|$SDE$|$ $<$ 0.005), not a failure to reject a null hypothesis.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{adjustbox}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, file.path(TAB_DIR, "tabF1_sde.tex"))

cat("All tables saved to:", TAB_DIR, "\n")
