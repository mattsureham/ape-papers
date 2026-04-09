# 05_tables.R — Generate all tables
# PFAS/Karst — apep_1440

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

res <- readRDS(file.path(data_dir, "rd_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))
df <- res$df

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Table 1: Summary Statistics\n")

karst <- df[any_karst == 1]
nonkarst <- df[any_karst == 0]

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
fmtn <- function(x) formatC(x, format = "d", big.mark = ",")

mk_row <- function(var, label, d = 2) {
  k <- karst[[var]]; nk <- nonkarst[[var]]
  k <- k[!is.na(k)]; nk <- nk[!is.na(nk)]
  paste0(label, " & ", fmt(mean(k), d), " & ", fmt(sd(k), d), " & ",
         fmt(mean(nk), d), " & ", fmt(sd(nk), d), " \\\\")
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Summary Statistics by County Karst Geology}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Karst County} & \\multicolumn{2}{c}{Non-Karst County} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  mk_row("any_detect", "Any PFAS detection"),
  mk_row("max_pfas_ppt", "Max PFAS (ppt)", 1),
  mk_row("above_mcl", "Above MCL (4 ppt)", 3),
  mk_row("n_samples", "Number of samples", 0),
  mk_row("n_pfas_compounds", "PFAS compounds tested", 1),
  mk_row("has_gw", "Groundwater source"),
  "\\midrule",
  paste0("Observations & \\multicolumn{2}{c}{", fmtn(nrow(karst)),
         "} & \\multicolumn{2}{c}{", fmtn(nrow(nonkarst)), "} \\\\"),
  paste0("Counties & \\multicolumn{2}{c}{",
         fmtn(length(unique(karst$county_fips))),
         "} & \\multicolumn{2}{c}{",
         fmtn(length(unique(nonkarst$county_fips))), "} \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  paste0("\\item \\textit{Notes:} Unit of observation is a public water system (PWS) ",
         "monitored under EPA's Unregulated Contaminant Monitoring Rule 5 (UCMR5). ",
         "Karst counties are those with any area classified as sinkhole-susceptible ",
         "(SSI bins 3--5) in the USGS sinkhole susceptibility index. ",
         "MCL is the Maximum Contaminant Level of 4 parts per trillion for PFOA and PFOS ",
         "under the 2024 National Primary Drinking Water Regulation."),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)
writeLines(tab1, file.path(table_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results
# ============================================================
cat("Table 2: Main Results\n")

etable(res$m1_detect, res$m2_detect, res$m4_level, res$m6_level, res$m5_mcl,
       headers = c("(1)", "(2)", "(3)", "(4)", "(5)"),
       depvar = TRUE,
       se.below = TRUE,
       fitstat = c("n", "wr2"),
       tex = TRUE,
       file = file.path(table_dir, "tab2_main.tex"),
       replace = TRUE,
       title = "Karst Geology and PFAS Contamination",
       label = "tab:main",
       notes = paste0("Unit of observation: public water system (PWS). ",
                       "All specifications include state fixed effects. ",
                       "Standard errors clustered at the county level in parentheses. ",
                       "Any Karst is a binary indicator for counties with positive karst area. ",
                       "Karst Fraction is the share of county area classified as sinkhole-susceptible. ",
                       "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."))

# ============================================================
# Table 3: Groundwater vs Surface Water
# ============================================================
cat("Table 3: Groundwater vs Surface Water\n")

models_gw <- list(res$m_gw1, res$m_gw2, res$m_gw3, res$m_gw4)
if (!is.null(res$m_sw)) models_gw <- c(models_gw, list(res$m_sw))

etable(models_gw,
       headers = if (!is.null(res$m_sw)) c("(1)", "(2)", "(3)", "(4)", "(5)") else c("(1)", "(2)", "(3)", "(4)"),
       depvar = TRUE,
       se.below = TRUE,
       fitstat = c("n", "wr2"),
       tex = TRUE,
       file = file.path(table_dir, "tab3_gw_sw.tex"),
       replace = TRUE,
       title = "Groundwater Systems vs.~Surface Water Placebo",
       label = "tab:gw_sw",
       notes = paste0("Columns 1--4: groundwater PWSs only. ",
                       if (!is.null(res$m_sw)) "Column 5: surface water PWSs (placebo). " else "",
                       "Karst geology should transmit PFAS through groundwater conduit flow but not surface water. ",
                       "All specifications include state fixed effects. ",
                       "Standard errors clustered at the county level. ",
                       "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."))

# ============================================================
# Table 4: Robustness
# ============================================================
cat("Table 4: Robustness\n")

rob_models <- list(res$m1_detect, rob$m_log, rob$m_state_cluster, rob$m_bins)
rob_models <- rob_models[!sapply(rob_models, is.null)]

etable(rob_models,
       depvar = TRUE,
       se.below = TRUE,
       fitstat = c("n", "wr2"),
       tex = TRUE,
       file = file.path(table_dir, "tab4_robust.tex"),
       replace = TRUE,
       title = "Robustness Checks",
       label = "tab:robust",
       notes = paste0("Column 1: baseline (county-clustered SEs). ",
                       "Column 2: log(PFAS+1) outcome. ",
                       "Column 3: state-clustered SEs. ",
                       "Column 4: karst fraction bins. ",
                       "All include state fixed effects. ",
                       "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."))

# ============================================================
# Table F1: SDE
# ============================================================
cat("Table F1: Standardized Effect Sizes\n")

compute_sde <- function(model, var_name, outcome_vec, label) {
  beta <- coef(model)[var_name]
  se_b <- se(model)[var_name]
  sd_y <- sd(outcome_vec, na.rm = TRUE)
  sde <- beta / sd_y
  se_sde <- se_b / sd_y

  classify <- function(s) {
    if (abs(s) > 0.15) ifelse(s > 0, "Large positive", "Large negative")
    else if (abs(s) > 0.05) ifelse(s > 0, "Moderate positive", "Moderate negative")
    else if (abs(s) > 0.005) ifelse(s > 0, "Small positive", "Small negative")
    else "Null"
  }

  data.frame(outcome = label, beta = beta, se = se_b, sd_y = sd_y,
             sde = sde, se_sde = se_sde, class = classify(sde))
}

sde_pooled <- rbind(
  compute_sde(res$m1_detect, "any_karst", df$any_detect, "Any PFAS Detection"),
  compute_sde(res$m4_level, "any_karst", df$max_pfas_ppt, "Max PFAS Level (ppt)"),
  compute_sde(res$m5_mcl, "any_karst", df$above_mcl, "Above MCL (4 ppt)")
)

df_gw <- df[has_gw == 1]
sde_gw <- rbind(
  compute_sde(res$m_gw1, "any_karst", df_gw$any_detect, "Any Detection (Groundwater)"),
  compute_sde(res$m_gw3, "any_karst", df_gw$max_pfas_ppt, "Max PFAS (Groundwater)")
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does karst geology cause higher PFAS contamination in public drinking water systems, by enabling rapid underground transport of PFAS from anthropogenic sources through soluble bedrock conduits? ",
  "\\textbf{Policy mechanism:} Karst aquifers contain dissolution-enlarged conduits that transmit contaminants at meters per day, bypassing the soil adsorption and slow matrix diffusion (centimeters per year) that filter PFAS in non-karst formations; the 2024 EPA PFAS rule sets Maximum Contaminant Levels at 4 parts per trillion. ",
  "\\textbf{Outcome definition:} Three measures of PFAS contamination at the public water system level: binary indicator for any detection above the minimum reporting level, maximum detected concentration in parts per trillion across all monitored PFAS analytes, and binary indicator for exceeding the 4 ppt MCL. ",
  "\\textbf{Treatment:} Binary indicator for whether the county contains karst geology (sinkhole susceptibility index bins 3--5 from USGS). ",
  "\\textbf{Data:} EPA Unregulated Contaminant Monitoring Rule 5 (UCMR5) cross-section merged with USGS county-level sinkhole susceptibility index via Census ZCTA-to-county crosswalk; unit of observation is a public water system. ",
  "\\textbf{Method:} OLS with state fixed effects, standard errors clustered at the county level (fixest). ",
  "\\textbf{Sample:} Public water systems monitored for PFAS under UCMR5 that could be matched to counties with karst geology data; continental United States. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the unconditional ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\begin{threeparttable}",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled (All PWSs)}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_pooled))) {
  tabF1 <- c(tabF1, sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
                             sde_pooled$outcome[i], sde_pooled$beta[i], sde_pooled$se[i],
                             sde_pooled$sd_y[i], sde_pooled$sde[i], sde_pooled$se_sde[i],
                             sde_pooled$class[i]))
}

tabF1 <- c(tabF1,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Groundwater Subsample)}} \\\\[3pt]"
)

for (i in seq_len(nrow(sde_gw))) {
  tabF1 <- c(tabF1, sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
                             sde_gw$outcome[i], sde_gw$beta[i], sde_gw$se[i],
                             sde_gw$sd_y[i], sde_gw$sde[i], sde_gw$se_sde[i],
                             sde_gw$class[i]))
}

tabF1 <- c(tabF1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tabF1, file.path(table_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
