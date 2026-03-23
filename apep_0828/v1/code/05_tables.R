## 05_tables.R — Generate all LaTeX tables for apep_0828

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) script_dir <- dirname(normalizePath(script_path)) else script_dir <- getwd()
source(file.path(script_dir, "00_packages.R"))
setwd(dirname(script_dir))

panel <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")
smart <- fread("data/smart_sections.csv")

cat("=== TABLE 1: Summary Statistics ===\n")

# Panel means by treatment status
pre_smart <- panel[unit_type == "smart" & year < open_year]
post_smart <- panel[unit_type == "smart" & year >= open_year]
ctrl <- panel[unit_type == "conventional"]

make_row <- function(var, label) {
  sprintf("  %s & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\",
    label,
    mean(pre_smart[[var]], na.rm = TRUE),
    sd(pre_smart[[var]], na.rm = TRUE),
    mean(post_smart[[var]], na.rm = TRUE),
    sd(post_smart[[var]], na.rm = TRUE),
    mean(ctrl[[var]], na.rm = TRUE),
    sd(ctrl[[var]], na.rm = TRUE))
}

tab1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Collision Rates by Section Type}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Smart (Pre)} & \\multicolumn{2}{c}{Smart (Post)} & \\multicolumn{2}{c}{Conventional} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & Mean & SD & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  make_row("rate_total", "Collisions per mile"),
  make_row("rate_ks", "KSI per mile"),
  make_row("rate_fatal", "Fatalities per mile"),
  make_row("n_collisions", "Collisions per year"),
  make_row("n_fatal", "Fatal collisions per year"),
  sprintf("  Observations & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          nrow(pre_smart), nrow(post_smart), nrow(ctrl)),
  sprintf("  Sections/motorways & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\",
          length(unique(pre_smart$unit_id)), length(unique(post_smart$unit_id)),
          length(unique(ctrl$unit_id))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel of 14 smart motorway sections and 18 conventional motorway controls, 2000--2023. Smart (Pre) and Smart (Post) refer to observations before and after conversion to smart configuration. Collision rates are per mile of motorway per year. KSI = killed or seriously injured. Data: DfT STATS19.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1, "tables/tab1_summary.tex")
cat("  Written tables/tab1_summary.tex\n")

cat("\n=== TABLE 2: Main Results ===\n")

# Extract results
cs_att <- results$cs_overall$att
cs_se <- results$cs_overall$se
twfe_coef <- results$twfe$coef
twfe_se <- results$twfe$se
twfe_ks_coef <- results$twfe_ks$coef
twfe_ks_se <- results$twfe_ks$se
twfe_fatal_coef <- results$twfe_fatal$coef
twfe_fatal_se <- results$twfe_fatal$se
cs_ks <- results$cs_ks$att
cs_ks_se <- results$cs_ks$se
cs_fatal <- results$cs_fatal$att
cs_fatal_se <- results$cs_fatal$se

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.1) return("^{*}")
  return("")
}

# Significance for CS estimates
cs_p <- 2 * pnorm(-abs(cs_att / cs_se))
cs_ks_p <- 2 * pnorm(-abs(cs_ks / cs_ks_se))
cs_fatal_p <- 2 * pnorm(-abs(cs_fatal / cs_fatal_se))

tab2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Smart Motorway Conversion on Collision Rates}",
  "\\label{tab:main_results}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Total Collisions} & \\multicolumn{2}{c}{KSI} & \\multicolumn{2}{c}{Fatal} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}",
  " & CS & TWFE & CS & TWFE & CS & TWFE \\\\",
  "\\midrule",
  sprintf("  Smart $\\times$ Post & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ & $%.3f%s$ \\\\",
    cs_att, stars(cs_p), twfe_coef, stars(results$twfe$pval),
    cs_ks, stars(cs_ks_p), twfe_ks_coef, stars(results$twfe_ks$pval),
    cs_fatal, stars(cs_fatal_p), twfe_fatal_coef, stars(results$twfe_fatal$pval)),
  sprintf("   & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
    cs_se, twfe_se, cs_ks_se, twfe_ks_se, cs_fatal_se, twfe_fatal_se),
  "  \\midrule",
  sprintf("  Pre-treatment mean & \\multicolumn{2}{c}{%.2f} & \\multicolumn{2}{c}{%.2f} & \\multicolumn{2}{c}{%.2f} \\\\",
    mean(pre_smart$rate_total), mean(pre_smart$rate_ks), mean(pre_smart$rate_fatal)),
  "  Section \\& year FE & \\multicolumn{6}{c}{Yes} \\\\",
  "  Clustering & \\multicolumn{6}{c}{Section level} \\\\",
  sprintf("  Observations & \\multicolumn{6}{c}{%d} \\\\", nrow(panel)),
  sprintf("  Sections & \\multicolumn{6}{c}{%d} \\\\", length(unique(panel$unit_id))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Outcome is collisions per mile per year. CS = Callaway-Sant'Anna (2021) with not-yet-treated controls. TWFE = two-way fixed effects with section and year fixed effects. KSI = killed or seriously injured. Standard errors clustered at the section level in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2, "tables/tab2_main_results.tex")
cat("  Written tables/tab2_main_results.tex\n")

cat("\n=== TABLE 3: Robustness ===\n")

pois_pct <- (exp(results$poisson$coef) - 1) * 100

tab3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\small",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Estimate & SE & $p$-value & $N$ \\\\",
  "\\midrule",
  sprintf("  \\textit{Panel A: Alternative specifications} & & & & \\\\"),
  sprintf("  \\quad Baseline TWFE & %.3f & %.3f & %.4f & %d \\\\",
    twfe_coef, twfe_se, results$twfe$pval, nrow(panel)),
  sprintf("  \\quad Donut-hole (excl.\\ conversion year) & %.3f & %.3f & %.4f & %d \\\\",
    results$twfe_donut$coef, results$twfe_donut$se, results$twfe_donut$pval, nrow(panel) - 14),
  sprintf("  \\quad Pre-COVID sample (2000--2019) & %.3f & %.3f & %.4f & %d \\\\",
    results$twfe_precovid$coef, results$twfe_precovid$se, results$twfe_precovid$pval,
    nrow(panel[year <= 2019])),
  sprintf("  \\quad Poisson (count outcome) & %.3f & %.3f & %.4f & %d \\\\",
    results$poisson$coef, results$poisson$se, results$poisson$pval, nrow(panel)),
  "  \\midrule",
  sprintf("  \\textit{Panel B: Inference} & & & & \\\\"),
  sprintf("  \\quad TWFE cluster-robust SE & %.3f & %.3f & %.4f & \\\\",
    twfe_coef, twfe_se, results$twfe$pval),
  sprintf("  \\quad Wild cluster bootstrap & %.3f & --- & %.4f & \\\\",
    twfe_coef, results$wild_boot_pval),
  "  \\midrule",
  sprintf("  \\textit{Panel C: Severity composition} & & & & \\\\"),
  sprintf("  \\quad KSI share (TWFE) & %.4f & %.4f & %.4f & %d \\\\",
    results$severity_composition$coef, results$severity_composition$se,
    results$severity_composition$pval, nrow(panel)),
  "  \\midrule",
  sprintf("  \\textit{Panel D: Leave-one-out range} & & & & \\\\"),
  sprintf("  \\quad Minimum & %.3f & & & \\\\", results$loo_range[1]),
  sprintf("  \\quad Maximum & %.3f & & & \\\\", results$loo_range[2]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports TWFE estimates with section and year fixed effects, clustered at section level. Donut-hole drops the first year of smart conversion. Poisson reports the log-linear coefficient ($e^{\\hat{\\beta}} - 1 =$ %.1f\\%%). Panel B reports alternative inference methods. Panel C tests whether severity composition changes (share of collisions that are KSI). Panel D shows the range of TWFE coefficients when each treated section is dropped in turn.",
  "\\end{tablenotes}",
  "\\end{table}"
)
# Fix the Poisson percentage in notes
tab3[length(tab3) - 2] <- gsub("%.1f", sprintf("%.1f", pois_pct), tab3[length(tab3) - 2])

writeLines(tab3, "tables/tab3_robustness.tex")
cat("  Written tables/tab3_robustness.tex\n")

cat("\n=== TABLE 4: ALR vs DHSR ===\n")

# Get CS results for subgroups
# Re-run from saved objects
cs_alr <- att_gt(yname = "rate_total", tname = "time_period", gname = "cohort",
                  idname = "unit_id_num",
                  data = {
                    p <- panel
                    p[, unit_id_num := as.integer(as.factor(unit_id))]
                    alr_ids <- p[type == "ALR" & !duplicated(unit_id)]$unit_id_num
                    ctrl_ids <- p[cohort == 0 & !duplicated(unit_id)]$unit_id_num
                    as.data.frame(p[unit_id_num %in% c(alr_ids, ctrl_ids)])
                  },
                  control_group = "notyettreated", anticipation = 0, base_period = "varying")
cs_alr_agg <- aggte(cs_alr, type = "simple")

cs_dhsr <- att_gt(yname = "rate_total", tname = "time_period", gname = "cohort",
                   idname = "unit_id_num",
                   data = {
                     p <- panel
                     p[, unit_id_num := as.integer(as.factor(unit_id))]
                     dhsr_ids <- p[type == "DHSR" & !duplicated(unit_id)]$unit_id_num
                     ctrl_ids <- p[cohort == 0 & !duplicated(unit_id)]$unit_id_num
                     as.data.frame(p[unit_id_num %in% c(dhsr_ids, ctrl_ids)])
                   },
                   control_group = "notyettreated", anticipation = 0, base_period = "varying")
cs_dhsr_agg <- aggte(cs_dhsr, type = "simple")

tab4 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Heterogeneity by Smart Motorway Type}",
  "\\label{tab:heterogeneity}",
  "\\small",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & All Smart & ALR & DHSR \\\\",
  "\\midrule",
  sprintf("  CS ATT & $%.3f$ & $%.3f$ & $%.3f$ \\\\",
    results$cs_overall$att, cs_alr_agg$overall.att, cs_dhsr_agg$overall.att),
  sprintf("   & (%.3f) & (%.3f) & (%.3f) \\\\",
    results$cs_overall$se, cs_alr_agg$overall.se, cs_dhsr_agg$overall.se),
  sprintf("  Treated sections & %d & %d & %d \\\\",
    length(unique(panel[cohort > 0]$unit_id)),
    length(unique(panel[type == "ALR" & cohort > 0]$unit_id)),
    length(unique(panel[type == "DHSR" & cohort > 0]$unit_id))),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} CS = Callaway-Sant'Anna (2021). ALR = All Lane Running (hard shoulder permanently removed). DHSR = Dynamic Hard Shoulder Running (hard shoulder opened during peak hours). Standard errors in parentheses.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4, "tables/tab4_heterogeneity.tex")
cat("  Written tables/tab4_heterogeneity.tex\n")

cat("\n=== TABLE F1: Standardized Effect Sizes (SDE) ===\n")

# Compute SDEs
# SDE = β̂ / SD(Y_pre)
sd_total_pre <- sd(panel[unit_type == "smart" & year < open_year]$rate_total, na.rm = TRUE)
sd_ks_pre <- sd(panel[unit_type == "smart" & year < open_year]$rate_ks, na.rm = TRUE)
sd_fatal_pre <- sd(panel[unit_type == "smart" & year < open_year]$rate_fatal, na.rm = TRUE)

sde_total <- twfe_coef / sd_total_pre
sde_ks <- twfe_ks_coef / sd_ks_pre
sde_fatal <- twfe_fatal_coef / sd_fatal_pre

se_sde_total <- twfe_se / sd_total_pre
se_sde_ks <- twfe_ks_se / sd_ks_pre
se_sde_fatal <- twfe_fatal_se / sd_fatal_pre

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom. ",
  "\\textbf{Research question:} Do smart motorway conversions---which remove the hard shoulder to create additional running lanes---affect collision rates on English motorways? ",
  "\\textbf{Policy mechanism:} National Highways converts conventional motorway sections to smart configurations by permanently removing the hard shoulder (All Lane Running) or opening it during peak traffic (Dynamic Hard Shoulder Running), adding lane capacity while relying on electronic detection and variable speed limits for incident management. ",
  "\\textbf{Outcome definition:} Annual collision rate per mile of motorway section, from DfT STATS19 police-reported personal-injury collisions geocoded to motorway segments; KSI is the subset classified as fatal or serious. ",
  "\\textbf{Treatment:} Binary indicator for whether a motorway section has been converted to smart configuration in a given year. ",
  "\\textbf{Data:} DfT STATS19 collision records (2000--2023), 140,809 motorway collisions across 14 smart and 18 conventional motorway sections, 768 section-year observations. ",
  "\\textbf{Method:} Staggered difference-in-differences with section and year fixed effects, standard errors clustered at section level; Callaway-Sant'Anna (2021) and Poisson as robustness. ",
  "\\textbf{Sample:} English motorway sections with at least 50 recorded collisions over the study period; conventional motorways with at least 500 total collisions used as controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  sprintf("  Total collisions/mile & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
    twfe_coef, twfe_se, sd_total_pre, sde_total, se_sde_total, classify_sde(sde_total)),
  sprintf("  KSI/mile & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
    twfe_ks_coef, twfe_ks_se, sd_ks_pre, sde_ks, se_sde_ks, classify_sde(sde_ks)),
  sprintf("  Fatal/mile & %.3f & %.3f & %.2f & %.3f & %.3f & %s \\\\",
    twfe_fatal_coef, twfe_fatal_se, sd_fatal_pre, sde_fatal, se_sde_fatal, classify_sde(sde_fatal)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("  Written tables/tabF1_sde.tex\n")

cat(sprintf("\n  SDE total: %.3f (%s)\n", sde_total, classify_sde(sde_total)))
cat(sprintf("  SDE KSI: %.3f (%s)\n", sde_ks, classify_sde(sde_ks)))
cat(sprintf("  SDE fatal: %.3f (%s)\n", sde_fatal, classify_sde(sde_fatal)))

cat("\n=== All tables generated ===\n")
