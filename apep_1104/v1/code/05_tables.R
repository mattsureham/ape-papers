# ── 05_tables.R ────────────────────────────────────────────────────
# Generate all LaTeX tables for the 14th FC paper
# ───────────────────────────────────────────────────────────────────
source("code/00_packages.R")

panel <- fread("data/district_panel_clean.csv")
load("data/main_results.RData")
load("data/robustness_results.RData")

# ──────────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ──────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

# Pre-period stats
pre <- panel[year < 2015]
post <- panel[year >= 2015]

summ_vars <- data.table(
  Variable = c(
    "Log total nightlight luminosity",
    "Total nightlight luminosity",
    "Mean nightlight radiance",
    "Number of villages",
    "Population (2011 Census, 000s)",
    "Literacy rate",
    "SC population share",
    "ST population share",
    "Worker participation rate",
    "14th FC windfall (z-score)"
  ),
  Mean_pre = c(
    mean(pre$log_light), mean(pre$total_light), mean(pre$mean_light),
    mean(pre$n_villages), mean(pre$pop_2011/1000),
    mean(pre$lit_rate, na.rm=TRUE), mean(pre$sc_share, na.rm=TRUE),
    mean(pre$st_share, na.rm=TRUE), mean(pre$work_rate, na.rm=TRUE),
    mean(pre$windfall_pc_z)
  ),
  SD_pre = c(
    sd(pre$log_light), sd(pre$total_light), sd(pre$mean_light),
    sd(pre$n_villages), sd(pre$pop_2011/1000),
    sd(pre$lit_rate, na.rm=TRUE), sd(pre$sc_share, na.rm=TRUE),
    sd(pre$st_share, na.rm=TRUE), sd(pre$work_rate, na.rm=TRUE),
    sd(pre$windfall_pc_z)
  ),
  Mean_post = c(
    mean(post$log_light), mean(post$total_light), mean(post$mean_light),
    mean(post$n_villages), mean(post$pop_2011/1000),
    mean(post$lit_rate, na.rm=TRUE), mean(post$sc_share, na.rm=TRUE),
    mean(post$st_share, na.rm=TRUE), mean(post$work_rate, na.rm=TRUE),
    mean(post$windfall_pc_z)
  ),
  SD_post = c(
    sd(post$log_light), sd(post$total_light), sd(post$mean_light),
    sd(post$n_villages), sd(post$pop_2011/1000),
    sd(post$lit_rate, na.rm=TRUE), sd(post$sc_share, na.rm=TRUE),
    sd(post$st_share, na.rm=TRUE), sd(post$work_rate, na.rm=TRUE),
    sd(post$windfall_pc_z)
  )
)

# Format for LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-period (2012--2014)} & \\multicolumn{2}{c}{Post-period (2015--2023)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ_vars)) {
  fmt <- if (summ_vars$Variable[i] %in% c("Total nightlight luminosity", "Number of villages",
                                            "Population (2011 Census, 000s)")) {
    "%.1f"
  } else "%.3f"
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %s & %s & %s \\\\",
    summ_vars$Variable[i],
    sprintf(fmt, summ_vars$Mean_pre[i]),
    sprintf(fmt, summ_vars$SD_pre[i]),
    sprintf(fmt, summ_vars$Mean_post[i]),
    sprintf(fmt, summ_vars$SD_post[i])
  ))
  if (i == 5) tab1_lines <- c(tab1_lines, "\\midrule")
}

n_dist <- uniqueN(panel$district_id)
n_state <- uniqueN(panel$pc11_state_id)
tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("Districts & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\", n_dist, n_dist),
  sprintf("States & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\", n_state, n_state),
  sprintf("Observations & \\multicolumn{2}{c}{%s} & \\multicolumn{2}{c}{%s} \\\\",
          format(nrow(pre), big.mark=","), format(nrow(post), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  paste0("\\begin{tablenotes}[flushleft]\\footnotesize"),
  paste0("\\item \\textit{Notes:} District-year panel constructed from SHRUG VIIRS nightlights ",
         "(2012--2023) and Census 2011. Nightlight luminosity is the sum of annual VIIRS radiance ",
         "across all grid cells within a district. The 14th FC windfall is the per-capita formula-",
         "predicted transfer, standardized to z-scores. Pre-period is fiscal years before the 14th FC ",
         "implementation (April 2015). Panel restricted to districts observed in all 12 years."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ──────────────────────────────────────────────────────────────────
# TABLE 2: Main Results
# ──────────────────────────────────────────────────────────────────
cat("Generating Table 2: Main Results\n")

get_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.1) return("*")
  return("")
}

# Extract model results
models <- list(m1, m2, m3)
dep_vars <- c("Log total light", "Log mean radiance", "Log total light")
fe_labels <- c("District, Year", "District, Year", "District, Year, State trend")

coef_name <- "windfall_pc_z:post"

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Fiscal Devolution and Nighttime Luminosity}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  paste0(" & ", paste(dep_vars, collapse = " & "), " \\\\"),
  "\\midrule"
)

# Coefficient row
coefs <- sapply(models, function(m) coef(m)[coef_name])
ses <- sapply(models, function(m) se(m)[coef_name])
pvals <- sapply(models, function(m) pvalue(m)[coef_name])
stars <- sapply(pvals, get_stars)

tab2_lines <- c(tab2_lines,
  sprintf("Windfall $\\times$ Post & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", coefs[1]), stars[1],
          sprintf("%.4f", coefs[2]), stars[2],
          sprintf("%.4f", coefs[3]), stars[3]),
  sprintf(" & (%s) & (%s) & (%s) \\\\",
          sprintf("%.4f", ses[1]),
          sprintf("%.4f", ses[2]),
          sprintf("%.4f", ses[3]))
)

# WCB p-value for model 1
if (!is.null(boot_m1)) {
  tab2_lines <- c(tab2_lines,
    sprintf("WCB $p$-value & [%s] & & \\\\",
            sprintf("%.3f", boot_m1$p_val))
  )
}

tab2_lines <- c(tab2_lines,
  "\\midrule",
  sprintf("Fixed effects & %s \\\\", paste(fe_labels, collapse = " & ")),
  sprintf("Observations & %s & %s & %s \\\\",
          format(nobs(m1), big.mark=","),
          format(nobs(m2), big.mark=","),
          format(nobs(m3), big.mark=",")),
  sprintf("Districts & %s & %s & %s \\\\",
          format(n_dist, big.mark=","),
          format(n_dist, big.mark=","),
          format(n_dist, big.mark=",")),
  sprintf("Pre-treatment mean (dep. var.) & %.3f & %.3f & %.3f \\\\",
          mean(pre$log_light), mean(pre$log_mean_light), mean(pre$log_light)),
  sprintf("SD(dep. var., pre) & %.3f & %.3f & %.3f \\\\",
          sd(pre$log_light), sd(pre$log_mean_light), sd(pre$log_light)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Each column reports a separate OLS regression. ",
         "The treatment variable is the state-level per-capita 14th FC windfall ",
         "(standardized, z-score) interacted with a post-2015 indicator. ",
         "Column (1) uses log total district luminosity; column (2) uses log mean ",
         "radiance per grid cell; column (3) adds state-specific linear time trends. ",
         "Standard errors clustered at the state level in parentheses. ",
         "Wild cluster bootstrap (WCB) $p$-values in brackets use Webb weights ",
         "with 9,999 replications. *, **, *** denote significance at 10\\%, 5\\%, 1\\%."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("  Table 2 written.\n")

# ──────────────────────────────────────────────────────────────────
# TABLE 3: Event Study Coefficients
# ──────────────────────────────────────────────────────────────────
cat("Generating Table 3: Event Study\n")

es_coefs <- coeftable(m_es)
es_rows <- grep("event_time", rownames(es_coefs))
es_data <- data.table(
  event_time = as.integer(gsub("event_time::(-?\\d+):windfall_pc_z", "\\1",
                                rownames(es_coefs)[es_rows])),
  coef = es_coefs[es_rows, 1],
  se = es_coefs[es_rows, 2],
  pval = es_coefs[es_rows, 4]
)
es_data <- es_data[order(event_time)]

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Fiscal Devolution and Nighttime Luminosity}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Event time & Coefficient & Std. Error & $p$-value \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_data)) {
  et <- es_data$event_time[i]
  label <- if (et < 0) sprintf("$t %d$", et) else sprintf("$t + %d$", et)
  stars_i <- get_stars(es_data$pval[i])
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s%s & (%s) & %s \\\\",
            label,
            sprintf("%.4f", es_data$coef[i]), stars_i,
            sprintf("%.4f", es_data$se[i]),
            sprintf("%.3f", es_data$pval[i]))
  )
  if (et == -2) {
    tab3_lines <- c(tab3_lines,
      "$t - 1$ (ref.) & --- & --- & --- \\\\",
      "\\midrule")
  }
}

tab3_lines <- c(tab3_lines,
  "\\midrule",
  sprintf("Joint pre-trend $F$-test $p$-value & \\multicolumn{3}{c}{see text} \\\\"),
  sprintf("Observations & \\multicolumn{3}{c}{%s} \\\\", format(nobs(m_es), big.mark=",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} Event study regression of log total district luminosity ",
         "on interactions between the state-level per-capita 14th FC windfall (z-score) ",
         "and event-time indicators, with $t - 1$ (2014) as the omitted reference year. ",
         "District and year fixed effects included. Standard errors clustered at the state level."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_event_study.tex")
cat("  Table 3 written.\n")

# ──────────────────────────────────────────────────────────────────
# TABLE 4: Robustness
# ──────────────────────────────────────────────────────────────────
cat("Generating Table 4: Robustness\n")

rob_models <- list(m1, m_placebo, m_no_demon, m_twoway,
                    m_viirs_only, m_viirs_trends,
                    het_q1, het_q4)
rob_names <- c("Baseline (combined panel)", "Placebo (DMSP 2008--2013)",
               "Excl.\\ 2017 (demonetization)", "Two-way cluster",
               "VIIRS only (2012--2023)", "VIIRS only + state trends",
               "Q1: Darkest districts", "Q4: Brightest districts")
rob_coef_names <- rep("windfall_pc_z:post", 8)
# For placebo the coef name differs
rob_coef_names[2] <- "windfall_pc_z:post_placebo"

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Heterogeneity}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Coefficient & SE & $p$-value & $N$ \\\\",
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel A: Robustness}} \\\\[3pt]"
)

for (i in 1:6) {
  cf <- tryCatch(coef(rob_models[[i]])[rob_coef_names[i]], error = function(e) NA)
  s <- tryCatch(se(rob_models[[i]])[rob_coef_names[i]], error = function(e) NA)
  p <- tryCatch(pvalue(rob_models[[i]])[rob_coef_names[i]], error = function(e) NA)
  n <- tryCatch(nobs(rob_models[[i]]), error = function(e) NA)
  stars_i <- get_stars(p)
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s%s & (%s) & %s & %s \\\\",
            rob_names[i],
            sprintf("%.4f", cf), stars_i,
            sprintf("%.4f", s),
            sprintf("%.3f", p),
            format(n, big.mark=","))
  )
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\multicolumn{5}{l}{\\textit{Panel B: Heterogeneity by baseline luminosity}} \\\\[3pt]"
)

for (i in 7:8) {
  cf <- coef(rob_models[[i]])[rob_coef_names[i]]
  s <- se(rob_models[[i]])[rob_coef_names[i]]
  p <- pvalue(rob_models[[i]])[rob_coef_names[i]]
  n <- nobs(rob_models[[i]])
  stars_i <- get_stars(p)
  tab4_lines <- c(tab4_lines,
    sprintf("%s & %s%s & (%s) & %s & %s \\\\",
            rob_names[i],
            sprintf("%.4f", cf), stars_i,
            sprintf("%.4f", s),
            sprintf("%.3f", p),
            format(n, big.mark=","))
  )
}

# LOO range
tab4_lines <- c(tab4_lines,
  "\\midrule",
  sprintf("Leave-one-state-out range & [%.4f, %.4f] & & & \\\\",
          min(loo_results$coef), max(loo_results$coef)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  paste0("\\item \\textit{Notes:} All specifications include district and year fixed effects ",
         "with SEs clustered at the state level, except where noted. ",
         "The placebo test applies the 14th FC windfall variable to DMSP nightlights (2008--2013) ",
         "with a false treatment date of 2011. ",
         "Q1 and Q4 refer to the bottom and top quartiles of pre-treatment (2012--2014) mean ",
         "district luminosity. *, **, *** denote significance at 10\\%, 5\\%, 1\\%."),
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robustness.tex")
cat("  Table 4 written.\n")

# ──────────────────────────────────────────────────────────────────
# TABLE F1: Standardized Effect Sizes (SDE Appendix)
# ──────────────────────────────────────────────────────────────────
cat("Generating Table F1: SDE\n")

# Pre-treatment SD of outcome
sd_y_pre <- sd(panel[year < 2015, log_light])

# Preferred estimate: m3 (trend-adjusted, given pre-trend failure in m1)
beta_main <- coef(m3)["windfall_pc_z:post"]
se_main <- se(m3)["windfall_pc_z:post"]

# Treatment is already standardized (z-score), so SDE = beta / SD(Y)
# (since a 1-SD increase in windfall is the treatment)
sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

classify_sde <- function(x) {
  ax <- abs(x)
  if (ax < 0.005) return("Null")
  if (ax < 0.05) return(if (x > 0) "Small positive" else "Small negative")
  if (ax < 0.15) return(if (x > 0) "Moderate positive" else "Moderate negative")
  return(if (x > 0) "Large positive" else "Large negative")
}

# Panel B: Heterogeneity (sample splits)
beta_q1 <- coef(het_q1)["windfall_pc_z:post"]
se_q1 <- se(het_q1)["windfall_pc_z:post"]
sd_y_q1 <- sd(panel[light_quartile == "Q1_darkest" & year < 2015, log_light])
sde_q1 <- beta_q1 / sd_y_q1
se_sde_q1 <- se_q1 / sd_y_q1

beta_q4 <- coef(het_q4)["windfall_pc_z:post"]
se_q4 <- se(het_q4)["windfall_pc_z:post"]
sd_y_q4 <- sd(panel[light_quartile == "Q4_brightest" & year < 2015, log_light])
sde_q4 <- beta_q4 / sd_y_q4
se_sde_q4 <- se_q4 / sd_y_q4

# SDE notes (for Oracle training data)
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does formula-driven fiscal devolution from the central ",
  "government to state governments increase local economic activity at the district level? ",
  "\\textbf{Policy mechanism:} The 14th Finance Commission (April 2015) raised Indian states' ",
  "share of central tax revenue from 32\\% to 42\\%, with allocation shares determined by a ",
  "predetermined formula weighting income distance (50\\%), population (17.5\\%), area (15\\%), ",
  "forest cover (7.5\\%), and demographic performance (10\\%), thereby channeling larger per-capita ",
  "windfalls to poorer and more remote states while simultaneously reducing tied grants. ",
  "\\textbf{Outcome definition:} Log total nighttime luminosity (VIIRS annual sum) at the district level, ",
  "a standard proxy for local economic activity. ",
  "\\textbf{Treatment:} Continuous---state-level per-capita formula-predicted fiscal windfall, ",
  "standardized to z-scores; a one-unit increase corresponds to one standard deviation in ",
  "cross-state windfall intensity. ",
  "\\textbf{Data:} SHRUG VIIRS nightlights (2012--2023), Census 2011 PCA, and 14th/13th FC ",
  "official devolution shares; district-year panel; ",
  sprintf("%s observations across %d districts in %d states. ",
          format(nrow(panel), big.mark=","), n_dist, n_state),
  "\\textbf{Method:} Continuous treatment DiD with district and year fixed effects; ",
  "standard errors clustered at the state level (28 clusters) with wild cluster bootstrap ",
  "(Webb weights, 9,999 replications). ",
  "\\textbf{Sample:} Balanced panel of districts observed in all 12 years (2012--2023); ",
  "Telangana excluded (carved from Andhra Pradesh in 2014); always-dark districts dropped. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Log total luminosity & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]",
  sprintf("Q1 districts (darkest) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_q1, se_q1, sd_y_q1, sde_q1, se_sde_q1, classify_sde(sde_q1)),
  sprintf("Q4 districts (brightest) & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
          beta_q4, se_q4, sd_y_q4, sde_q4, se_sde_q4, classify_sde(sde_q4)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\footnotesize",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("\nAll tables generated.\n")
