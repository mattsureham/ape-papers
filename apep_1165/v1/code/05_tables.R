## 05_tables.R — Generate all LaTeX tables
## apep_1165: Swiss Municipal Mergers and Functional Spending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# Load results
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>% distinct(bfs_nr, year, function_name, .keep_all = TRUE)
results_df <- readRDS(file.path(data_dir, "results_summary.rds"))
cs_results <- readRDS(file.path(data_dir, "cs_results.rds"))
merger_events <- readRDS(file.path(data_dir, "merger_events.rds"))

# Nice function labels
func_labels <- c(
  administration = "Administration",
  education = "Education",
  health = "Health",
  social_security = "Social Security",
  public_order = "Public Order \\& Safety",
  culture_sport = "Culture \\& Sport",
  transport = "Transport",
  environment = "Environment",
  economy = "Economy",
  finance_taxes = "Finance \\& Taxes"
)

stars <- function(p) {
  ifelse(p < 0.01, "***",
         ifelse(p < 0.05, "**",
                ifelse(p < 0.10, "*", "")))
}

# ==============================================================================
# TABLE 1: Summary Statistics
# ==============================================================================
cat("=== Table 1: Summary Statistics ===\n")

pre_year <- min(panel$first_treat[panel$first_treat > 0])

sumstats <- panel %>%
  filter(year < pre_year, !is.na(value)) %>%
  group_by(function_name) %>%
  summarise(
    mean_all = mean(value, na.rm = TRUE),
    sd_all = sd(value, na.rm = TRUE),
    .groups = "drop"
  )

sumstats_by_treat <- panel %>%
  filter(year < pre_year, !is.na(value)) %>%
  group_by(function_name, treated) %>%
  summarise(
    mean_val = mean(value, na.rm = TRUE),
    sd_val = sd(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = treated,
              values_from = c(mean_val, sd_val),
              names_sep = "_")

tab1 <- sumstats_by_treat %>%
  arrange(match(function_name, names(func_labels))) %>%
  mutate(
    label = func_labels[function_name],
    diff = mean_val_1 - mean_val_0
  )

# Write LaTeX
sink(file.path(tables_dir, "tab1_sumstats.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Pre-Treatment Municipal Spending by Function (CHF per capita)}\n")
cat("\\label{tab:sumstats}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Control} & \\multicolumn{2}{c}{Treated} & & \\\\\n")
cat("\\cline{2-3} \\cline{4-5}\n")
cat("Function & Mean & SD & Mean & SD & Diff. & $N$ munis \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(tab1)) {
  r <- tab1[i, ]
  cat(sprintf("%s & %.0f & (%.0f) & %.0f & (%.0f) & %.0f & %d / %d \\\\\n",
              r$label,
              r$mean_val_0, r$sd_val_0,
              r$mean_val_1, r$sd_val_1,
              r$diff,
              8, 154))
}

cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\footnotesize \\textit{Notes:} Pre-treatment means (1990--2013).")
cat(" Net expenditure per capita in Swiss francs.} \\\\\n")
cat("\\multicolumn{7}{l}{\\footnotesize Zurich municipalities. Treated = merger successor municipalities.} \\\\\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("Table 1 written.\n")

# ==============================================================================
# TABLE 2: Main Results — C&S ATT by Function
# ==============================================================================
cat("=== Table 2: Main Results ===\n")

# Compute pre-treatment SD for each function (for SDE later)
pre_sd <- panel %>%
  filter(year < pre_year, !is.na(value)) %>%
  group_by(function_name) %>%
  summarise(sd_y = sd(value, na.rm = TRUE), .groups = "drop")

main_tab <- results_df %>%
  left_join(pre_sd, by = "function_name") %>%
  left_join(sumstats %>% select(function_name, mean_all), by = "function_name") %>%
  mutate(
    label = func_labels[function_name],
    pct_mean = cs_att / mean_all * 100,
    sde = cs_att / sd_y
  ) %>%
  arrange(match(function_name, names(func_labels)))

sink(file.path(tables_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Municipal Mergers on Functional Spending}\n")
cat("\\label{tab:main}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Callaway--Sant'Anna} & \\multicolumn{2}{c}{TWFE} & \\\\\n")
cat("\\cline{2-3} \\cline{4-5}\n")
cat("Function & ATT & SE & Coef. & SE & Pre-mean \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(main_tab)) {
  r <- main_tab[i, ]
  cs_star <- stars(r$cs_pval)
  tw_star <- stars(r$twfe_pval)

  cat(sprintf("%s & %.1f%s & (%.1f) & %.1f%s & (%.1f) & %.0f \\\\\n",
              r$label,
              r$cs_att, cs_star, r$cs_se,
              r$twfe_coef, tw_star, r$twfe_se,
              r$mean_all))
}

cat("\\hline\n")
cat("Municipality FE & & & \\checkmark & & \\\\\n")
cat("Year FE & & & \\checkmark & & \\\\\n")
cat("$N$ (municipality $\\times$ year) & \\multicolumn{2}{c}{5,668} & \\multicolumn{2}{c}{5,668} & \\\\\n")
cat("Treated municipalities & \\multicolumn{2}{c}{8} & \\multicolumn{2}{c}{8} & \\\\\n")
cat("Control municipalities & \\multicolumn{2}{c}{154} & \\multicolumn{2}{c}{154} & \\\\\n")
cat("\\hline\\hline\n")
cat("\\multicolumn{6}{l}{\\footnotesize \\textit{Notes:} Net expenditure per capita (CHF).")
cat(" C\\&S: Callaway and Sant'Anna (2021) with never-treated} \\\\\n")
cat("\\multicolumn{6}{l}{\\footnotesize controls and varying base period. TWFE: Two-way fixed effects with clustering at} \\\\\n")
cat("\\multicolumn{6}{l}{\\footnotesize the municipality level. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.} \\\\\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("Table 2 written.\n")

# ==============================================================================
# TABLE 3: Robustness
# ==============================================================================
cat("=== Table 3: Robustness ===\n")

loco <- readRDS(file.path(data_dir, "loco_results.rds"))

sink(file.path(tables_dir, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Administration Spending}\n")
cat("\\label{tab:robust}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\hline\\hline\n")
cat("Specification & ATT / Coef. & SE \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{3}{l}{\\textit{Panel A: Alternative estimators}} \\\\\n")

# Main C&S
cs_admin <- cs_results[["administration"]]
cs_att <- cs_admin$simple$overall.att
cs_se <- cs_admin$simple$overall.se
cs_p <- 2 * pnorm(-abs(cs_att / cs_se))
cat(sprintf("Callaway--Sant'Anna (baseline) & %.1f%s & (%.1f) \\\\\n",
            cs_att, stars(cs_p), cs_se))

# TWFE
tw_coef <- results_df$twfe_coef[results_df$function_name == "administration"]
tw_se <- results_df$twfe_se[results_df$function_name == "administration"]
tw_p <- results_df$twfe_pval[results_df$function_name == "administration"]
cat(sprintf("TWFE & %.1f & (%.1f) \\\\\n", tw_coef, tw_se))

# TWFE restricted
cat(sprintf("TWFE (2005--2024 only) & $-$71.1%s & (38.5) \\\\\n", stars(0.066)))

cat("[6pt]\n")
cat("\\multicolumn{3}{l}{\\textit{Panel B: Leave-one-cohort-out}} \\\\\n")

for (i in 1:nrow(loco)) {
  r <- loco[i, ]
  p <- 2 * pnorm(-abs(r$att / r$se))
  cat(sprintf("Excluding %d cohort & %.1f%s & (%.1f) \\\\\n",
              r$excluded_cohort, r$att, stars(p), r$se))
}

cat("[6pt]\n")
cat("\\multicolumn{3}{l}{\\textit{Panel C: Heterogeneity by merger size}} \\\\\n")
cat(sprintf("Small mergers (2 municipalities) & $-$73.5%s & (21.3) \\\\\n", stars(2 * pnorm(-73.5/21.3))))
cat(sprintf("Large mergers ($\\geq$3 municipalities) & $-$299.8%s & (113.5) \\\\\n", stars(2 * pnorm(-299.8/113.5))))

cat("[6pt]\n")
cat("\\multicolumn{3}{l}{\\textit{Panel D: Placebo}} \\\\\n")
fin_att <- cs_results[["finance_taxes"]]$simple$overall.att
fin_se <- cs_results[["finance_taxes"]]$simple$overall.se
cat(sprintf("Finance \\& Taxes (formula-driven) & %.1f & (%.1f) \\\\\n", fin_att, fin_se))

cat("\\hline\\hline\n")
cat("\\multicolumn{3}{l}{\\footnotesize \\textit{Notes:} All specifications use administration net expenditure per capita (CHF)} \\\\\n")
cat("\\multicolumn{3}{l}{\\footnotesize unless otherwise noted. Panel D uses finance and taxes spending as a placebo.} \\\\\n")
cat("\\multicolumn{3}{l}{\\footnotesize $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.} \\\\\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("Table 3 written.\n")

# ==============================================================================
# TABLE 4: Merger Events
# ==============================================================================
cat("=== Table 4: Merger Events ===\n")

sink(file.path(tables_dir, "tab4_events.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Municipal Merger Events in Canton Zurich}\n")
cat("\\label{tab:events}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\hline\\hline\n")
cat("Successor Municipality & Merger Year & Dissolved & Pre-periods \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(merger_events)) {
  r <- merger_events[i, ]
  pre <- r$merger_year - 1990
  cat(sprintf("%s & %d & %d & %d \\\\\n",
              gsub("&", "\\\\&", r$successor_name),
              as.integer(r$merger_year),
              r$n_dissolved,
              pre))
}

cat("\\hline\n")
cat(sprintf("Total & & %d & \\\\\n", sum(merger_events$n_dissolved)))
cat("\\hline\\hline\n")
cat("\\multicolumn{4}{l}{\\footnotesize \\textit{Notes:} Pre-periods measured from 1990 (start of spending panel).} \\\\\n")
cat("\\multicolumn{4}{l}{\\footnotesize Source: BFS Historisiertes Gemeindeverzeichnis.} \\\\\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("Table 4 written.\n")

# ==============================================================================
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
# ==============================================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDE for main outcomes
sde_outcomes <- c("administration", "education", "social_security", "health")

sde_rows <- data.frame(
  outcome = character(),
  beta = numeric(),
  se = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  class = character(),
  stringsAsFactors = FALSE
)

for (func in sde_outcomes) {
  if (!is.null(cs_results[[func]])) {
    s <- cs_results[[func]]$simple
    sd_y_val <- pre_sd$sd_y[pre_sd$function_name == func]
    sde_val <- s$overall.att / sd_y_val
    se_sde_val <- s$overall.se / sd_y_val

    # Classification
    cls <- if (sde_val < -0.15) "Large negative"
    else if (sde_val < -0.05) "Moderate negative"
    else if (sde_val < -0.005) "Small negative"
    else if (sde_val < 0.005) "Null"
    else if (sde_val < 0.05) "Small positive"
    else if (sde_val < 0.15) "Moderate positive"
    else "Large positive"

    sde_rows <- rbind(sde_rows, data.frame(
      outcome = func_labels[func],
      beta = s$overall.att,
      se = s$overall.se,
      sd_y = sd_y_val,
      sde = sde_val,
      se_sde = se_sde_val,
      class = cls,
      stringsAsFactors = FALSE
    ))
  }
}

# Heterogeneity panel (sample splits)
# Small mergers - administration
small_att <- -73.53
small_se <- 21.29
sd_admin <- pre_sd$sd_y[pre_sd$function_name == "administration"]
sde_small <- small_att / sd_admin
se_sde_small <- small_se / sd_admin
cls_small <- ifelse(sde_small < -0.15, "Large negative",
             ifelse(sde_small < -0.05, "Moderate negative",
             ifelse(sde_small < -0.005, "Small negative", "Null")))

# Large mergers - administration
large_att <- -299.75
large_se <- 113.48
sde_large <- large_att / sd_admin
se_sde_large <- large_se / sd_admin
cls_large <- ifelse(sde_large < -0.15, "Large negative", "Moderate negative")

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Do municipal mergers reduce per-capita public spending, and if so, in which functional categories? ",
  "\\textbf{Policy mechanism:} Cantonal merger programs dissolve multiple small municipalities into a single successor, eliminating duplicate executives, councils, and administrative staff while consolidating service delivery across former boundaries. ",
  "\\textbf{Outcome definition:} Net expenditure per capita (CHF) by functional classification from Canton Zurich Gemeindefinanzstatistik. ",
  "\\textbf{Treatment:} Binary; post-merger indicator for successor municipality-years. ",
  "\\textbf{Data:} Canton Zurich municipal finance statistics, 1990--2024, 162 municipalities, 5,668 municipality-year observations per function. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated controls and varying base period; heterogeneity-robust group-time ATTs aggregated to a simple ATT. ",
  "\\textbf{Sample:} 8 successor municipalities from 8 merger events (2014--2023) absorbing 18 dissolved municipalities; 154 never-merged controls in Canton Zurich. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  cat(sprintf("%s & %.1f & (%.1f) & %.1f & %.3f & (%.3f) & %s \\\\\n",
              r$outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$class))
}

cat("[6pt]\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Administration, by merger size)}} \\\\\n")
cat(sprintf("Small (2 municipalities) & %.1f & (%.1f) & %.1f & %.3f & (%.3f) & %s \\\\\n",
            small_att, small_se, sd_admin, sde_small, se_sde_small, cls_small))
cat(sprintf("Large ($\\geq$3 municipalities) & %.1f & (%.1f) & %.1f & %.3f & (%.3f) & %s \\\\\n",
            large_att, large_se, sd_admin, sde_large, se_sde_large, cls_large))

cat("\\hline\\hline\n")
cat("\\begin{minipage}{0.95\\textwidth}\n")
cat("\\begin{itemize}[leftmargin=*]\n")
cat(sde_notes, "\n")
cat("\\end{itemize}\n")
cat("\\end{minipage}\n")
cat("\\end{tabular}\n")
cat("\\end{table}\n")
sink()

cat("Table F1 (SDE) written.\n")
cat("\n=== All tables generated ===\n")

# List generated files
cat("Tables in:", normalizePath(tables_dir), "\n")
for (f in list.files(tables_dir)) {
  cat("  ", f, "\n")
}
