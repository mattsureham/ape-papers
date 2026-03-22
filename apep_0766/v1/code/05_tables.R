## 05_tables.R — Summary statistics and SDE appendix table
## apep_0766: Council size thresholds and infant mortality in Brazil

source("00_packages.R")
set.seed(20260322)

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. LOAD DATA
# ============================================================
cat("=== Loading data ===\n")
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
res <- readRDS(file.path(data_dir, "main_results.rds"))
main <- res$main
cutoff_dt <- res$cutoff_dt
diagnostics <- res$diagnostics

# ============================================================
# 2. SUMMARY STATISTICS TABLE (Table 4)
# ============================================================
cat("\n=== Generating Table 4: Summary statistics ===\n")

# Compute statistics for full sample and by treatment status
stats_all <- main[, .(
  mean_pop = mean(population),
  sd_pop = sd(population),
  mean_imr = mean(imr, na.rm = TRUE),
  sd_imr = sd(imr, na.rm = TRUE),
  mean_deaths = mean(infant_deaths),
  mean_births = mean(live_births),
  n = .N,
  n_munis = uniqueN(muni_code6)
)]

stats_below <- main[above == 0, .(
  mean_pop = mean(population),
  sd_pop = sd(population),
  mean_imr = mean(imr, na.rm = TRUE),
  sd_imr = sd(imr, na.rm = TRUE),
  mean_deaths = mean(infant_deaths),
  mean_births = mean(live_births),
  n = .N,
  n_munis = uniqueN(muni_code6)
)]

stats_above <- main[above == 1, .(
  mean_pop = mean(population),
  sd_pop = sd(population),
  mean_imr = mean(imr, na.rm = TRUE),
  sd_imr = sd(imr, na.rm = TRUE),
  mean_deaths = mean(infant_deaths),
  mean_births = mean(live_births),
  n = .N,
  n_munis = uniqueN(muni_code6)
)]

# LaTeX table
tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & Full Sample & Below Threshold & Above Threshold \\\\\n",
  "\\midrule\n",
  sprintf("Population & %s & %s & %s \\\\\n",
          format(round(stats_all$mean_pop), big.mark = ","),
          format(round(stats_below$mean_pop), big.mark = ","),
          format(round(stats_above$mean_pop), big.mark = ",")),
  sprintf(" & (%s) & (%s) & (%s) \\\\\n",
          format(round(stats_all$sd_pop), big.mark = ","),
          format(round(stats_below$sd_pop), big.mark = ","),
          format(round(stats_above$sd_pop), big.mark = ",")),
  sprintf("IMR (per 1,000) & %.2f & %.2f & %.2f \\\\\n",
          stats_all$mean_imr, stats_below$mean_imr, stats_above$mean_imr),
  sprintf(" & (%.2f) & (%.2f) & (%.2f) \\\\\n",
          stats_all$sd_imr, stats_below$sd_imr, stats_above$sd_imr),
  sprintf("Infant deaths & %.1f & %.1f & %.1f \\\\\n",
          stats_all$mean_deaths, stats_below$mean_deaths, stats_above$mean_deaths),
  sprintf("Live births & %.0f & %.0f & %.0f \\\\\n",
          stats_all$mean_births, stats_below$mean_births, stats_above$mean_births),
  "\\midrule\n",
  sprintf("Municipality-years & %s & %s & %s \\\\\n",
          format(stats_all$n, big.mark = ","),
          format(stats_below$n, big.mark = ","),
          format(stats_above$n, big.mark = ",")),
  sprintf("Municipalities & %s & %s & %s \\\\\n",
          format(stats_all$n_munis, big.mark = ","),
          format(stats_below$n_munis, big.mark = ","),
          format(stats_above$n_munis, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Standard deviations in parentheses. ",
  "``Below threshold'' and ``above threshold'' refer to municipality-years where ",
  "population falls below or above the nearest constitutional cutoff for council size. ",
  "IMR is infant deaths per 1,000 live births. ",
  "Sample restricted to the five most populated cutoffs (15,000; 30,000; 50,000; 80,000; 120,000).\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, file.path(tables_dir, "tab4_summary.tex"))
cat("Table 4 saved.\n")

# ============================================================
# 3. SDE APPENDIX TABLE (tabF1_sde.tex) — MANDATORY
# ============================================================
cat("\n=== Generating SDE Appendix Table ===\n")

# Compute SDE for the pooled estimate
# SDE = beta_hat / SD(Y)
# For binary treatment (above/below threshold): SDE = beta / SD(IMR)

beta_hat <- diagnostics$pooled_estimate
se_beta <- diagnostics$pooled_se
sd_y <- diagnostics$sd_imr

sde <- beta_hat / sd_y
se_sde <- se_beta / sd_y

# Classification (7-bucket)
classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_class <- classify_sde(sde)

# Also compute SDE for cutoff-specific estimates
sde_rows <- list()

# Pooled
sde_rows[["pooled"]] <- data.table(
  outcome = "IMR (pooled, 5 cutoffs)",
  beta = beta_hat,
  se = se_beta,
  sd_y = sd_y,
  sde = sde,
  se_sde = se_sde,
  classification = sde_class
)

# Per-cutoff (up to 5 more rows for max 6 total)
for (i in seq_len(min(nrow(cutoff_dt), 5))) {
  r <- cutoff_dt[i]
  # Use overall SD(Y) for comparability
  sde_i <- r$coef / sd_y
  se_sde_i <- r$se_robust / sd_y
  sde_rows[[as.character(r$cutoff)]] <- data.table(
    outcome = sprintf("IMR (cutoff %s)", format(r$cutoff, big.mark = ",")),
    beta = r$coef,
    se = r$se_robust,
    sd_y = sd_y,
    sde = sde_i,
    se_sde = se_sde_i,
    classification = classify_sde(sde_i)
  )
}

sde_dt <- rbindlist(sde_rows)

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Brazil. ",
  "\\textbf{Research question:} Does crossing a constitutional population threshold that increases minimum city council size by two seats causally reduce infant mortality? ",
  "\\textbf{Policy mechanism:} Brazilian Constitution Article 29 (amended by EC 58/2009) mandates minimum numbers of city council members (vereadores) at discrete population thresholds; crossing a threshold mechanically adds two legislative seats, potentially increasing oversight of municipal health spending and primary care delivery. ",
  "\\textbf{Outcome definition:} Infant mortality rate---deaths of children under age one per 1,000 live births---from the Brazilian Mortality Information System (SIM) and Live Birth Information System (SINASC). ",
  "\\textbf{Treatment:} Binary indicator for municipal population exceeding the nearest constitutional threshold, which triggers a two-seat increase in minimum council size. ",
  "\\textbf{Data:} IBGE municipal population estimates, DATASUS SIM and SINASC vital statistics, ",
  format(diagnostics$n_obs, big.mark = ","), " municipality-year observations across ",
  format(diagnostics$n_municipalities, big.mark = ","), " municipalities, 2001--2020. ",
  "\\textbf{Method:} Multi-cutoff regression discontinuity design following Cattaneo et al.\\ (2016); local polynomial estimation with triangular kernel and CCT (2014) optimal bandwidth; standard errors clustered at the municipality level. ",
  "\\textbf{Sample:} Restricted to five constitutional thresholds (15,000; 30,000; 50,000; 80,000; 120,000 inhabitants) where sufficient mass exists on both sides of the cutoff; municipality-years with zero live births excluded. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pooled ",
  "standard deviation of the infant mortality rate. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build LaTeX table
sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(sde_dt))) {
  r <- sde_dt[i]
  sde_tex <- paste0(sde_tex, sprintf(
    "%s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
    r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification
  ))
}

sde_tex <- paste0(
  sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("SDE table saved.\n")

cat(sprintf("\nSDE Summary:\n"))
cat(sprintf("  Pooled beta: %.3f, SD(Y): %.2f, SDE: %.4f\n", beta_hat, sd_y, sde))
cat(sprintf("  Classification: %s\n", sde_class))

cat("\n=== All tables complete ===\n")
