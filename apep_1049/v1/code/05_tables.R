# 05_tables.R — Generate all LaTeX tables
# apep_1049: EU Single-Use Plastics Directive

source("00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
dir.create("tables", showWarnings = FALSE)

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
message("=== Table 1: Summary Statistics ===")

# Pre-treatment (2006-2019) and post-treatment statistics
pre <- panel[year <= 2019]
post <- panel[year > 2019]

make_row <- function(var, label, data) {
  x <- data[[var]]
  x <- x[!is.na(x)]
  sprintf("  %s & %.1f & %.1f & %.1f & %.1f & %d \\\\",
          label, mean(x), sd(x), min(x), max(x), length(x))
}

vars <- list(
  c("plastic_pc", "Plastic packaging (kg/person)"),
  c("paper_pc", "Paper/cardboard packaging (kg/person)"),
  c("glass_pc", "Glass packaging (kg/person)"),
  c("metal_pc", "Metal packaging (kg/person)"),
  c("total_pc", "Total packaging (kg/person)"),
  c("plastic_share", "Plastic share of total")
)

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Packaging Waste by Material}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "  & Mean & SD & Min & Max & N \\\\",
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel A: Pre-Treatment (2006--2019)}} \\\\[3pt]"
)

for (v in vars) {
  tab1_lines <- c(tab1_lines, make_row(v[1], v[2], pre))
}

tab1_lines <- c(tab1_lines,
  "\\midrule",
  "\\multicolumn{6}{l}{\\textit{Panel B: Post-Treatment (2020--2023)}} \\\\[3pt]"
)

for (v in vars) {
  tab1_lines <- c(tab1_lines, make_row(v[1], v[2], post))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from Eurostat \\texttt{env\\_waspac}, 27 EU member states, 2006--2023. Per-capita measures computed using Eurostat \\texttt{demo\\_pjan} population data. Plastic share equals plastic packaging waste divided by total packaging waste.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
message("Table 1 written to tables/tab1_summary.tex")

# ===========================================================================
# Table 2: Transposition Timeline
# ===========================================================================
message("\n=== Table 2: Transposition Timeline ===")

transposition <- readRDS("data/transposition.rds")
eu27_ref <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE"),
  name = c("Austria","Belgium","Bulgaria","Croatia","Cyprus","Czechia",
           "Denmark","Estonia","Finland","France","Germany","Greece",
           "Hungary","Ireland","Italy","Latvia","Lithuania","Luxembourg",
           "Malta","Netherlands","Poland","Portugal","Romania","Slovakia",
           "Slovenia","Spain","Sweden")
)

trans_tab <- merge(transposition[!is.na(iso2)], eu27_ref, by = "iso2")
trans_tab <- trans_tab[order(transposition_date)]

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{SUP Directive Transposition Timeline}",
  "\\label{tab:transposition}",
  "\\begin{tabular}{llcc}",
  "\\toprule",
  "  Country & Transposition Date & Effective Year & N Measures \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(trans_tab))) {
  tab2_lines <- c(tab2_lines, sprintf("  %s & %s & %d & %d \\\\",
    trans_tab$name[i],
    format(trans_tab$transposition_date[i], "%B %Y"),
    trans_tab$effective_year[i],
    trans_tab$n_measures[i]
  ))
}

tab2_lines <- c(tab2_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Transposition dates from CELLAR SPARQL (earliest entry-into-force of national implementation measures for Directive 2019/904). Effective year assigns countries transposing before July to the same calendar year and those transposing July--December to the following year. N Measures is the number of distinct national implementation measures notified to the Commission.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_transposition.tex")
message("Table 2 written")

# ===========================================================================
# Table 3: Main Results — Callaway-Sant'Anna ATT
# ===========================================================================
message("\n=== Table 3: Main Results ===")

agg_plastic <- readRDS("data/agg_simple_plastic.rds")
agg_paper <- readRDS("data/agg_simple_paper.rds")
agg_share <- readRDS("data/agg_simple_share.rds")
agg_glass <- readRDS("data/agg_simple_glass.rds")
agg_metal <- readRDS("data/agg_simple_metal.rds")
agg_total <- readRDS("data/agg_simple_total.rds")

# Stars function
stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

pval <- function(att, se) 2 * pnorm(-abs(att / se))

make_result_row <- function(label, agg_obj) {
  att <- agg_obj$overall.att
  se <- agg_obj$overall.se
  p <- pval(att, se)
  s <- stars(p)
  sprintf("  %s & %.2f%s & (%.2f) & [%.2f, %.2f] \\\\",
          label, att, s, se, att - 1.96 * se, att + 1.96 * se)
}

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Effect of SUP Directive on Packaging Waste: Callaway-Sant'Anna Estimates}",
  "\\label{tab:main_results}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "  Outcome & ATT & SE & 95\\% CI \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Targeted Materials}} \\\\[3pt]",
  make_result_row("Plastic packaging (kg/person)", agg_plastic),
  make_result_row("Plastic share of total", agg_share),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Substitution Channel}} \\\\[3pt]",
  make_result_row("Paper/cardboard packaging (kg/person)", agg_paper),
  make_result_row("Total packaging (kg/person)", agg_total),
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel C: Placebo Outcomes (Not Targeted)}} \\\\[3pt]",
  make_result_row("Glass packaging (kg/person)", agg_glass),
  make_result_row("Metal packaging (kg/person)", agg_metal),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Callaway-Sant'Anna (2021) doubly robust estimates using not-yet-treated countries as the comparison group. Standard errors computed via multiplier bootstrap (1,000 iterations). Panel C reports placebo outcomes: glass and metal packaging are not targeted by Directive 2019/904 and should show no effect if the research design is valid.",
  "\\item $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_main_results.tex")
message("Table 3 written")

# ===========================================================================
# Table 4: Robustness
# ===========================================================================
message("\n=== Table 4: Robustness ===")

rob_results <- list()

# Main specification
rob_results[["Baseline (per capita, not-yet-treated)"]] <- agg_plastic

# Never-treated
if (file.exists("data/rob_nevertreated.rds")) {
  rob_results[["Never-treated control group"]] <- readRDS("data/rob_nevertreated.rds")
}

# Levels
rob_results[["Levels (tonnes)"]] <- readRDS("data/rob_levels.rds")

# Log
rob_results[["Log outcome"]] <- readRDS("data/rob_log.rds")

# GDP control
rob_results[["With GDP per capita control"]] <- readRDS("data/rob_gdp_control.rds")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness: Effect on Plastic Packaging Waste}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "  Specification & ATT & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (nm in names(rob_results)) {
  obj <- rob_results[[nm]]
  att <- obj$overall.att
  se <- obj$overall.se
  p <- pval(att, se)
  s <- stars(p)
  tab4_lines <- c(tab4_lines,
    sprintf("  %s & %.2f%s & (%.2f) & [%.2f, %.2f] \\\\",
            nm, att, s, se, att - 1.96 * se, att + 1.96 * se))
}

# Add TWFE and Sun-Abraham from fixest
twfe <- readRDS("data/twfe_plastic.rds")
sa <- readRDS("data/sa_plastic.rds")

# TWFE
twfe_coef <- coef(twfe)["treated"]
twfe_se <- sqrt(vcov(twfe)["treated", "treated"])
twfe_p <- 2 * pnorm(-abs(twfe_coef / twfe_se))
tab4_lines <- c(tab4_lines,
  sprintf("  TWFE & %.2f%s & (%.2f) & [%.2f, %.2f] \\\\",
          twfe_coef, stars(twfe_p), twfe_se,
          twfe_coef - 1.96 * twfe_se, twfe_coef + 1.96 * twfe_se))

# Sun-Abraham overall
sa_att <- mean(coef(sa)[grepl("::", names(coef(sa))) & !grepl(":-", names(coef(sa)))])
tab4_lines <- c(tab4_lines,
  sprintf("  Sun-Abraham (post-treatment avg) & %.2f & & \\\\", sa_att))

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use plastic packaging waste as the outcome. Baseline is Callaway-Sant'Anna doubly robust with not-yet-treated controls and per-capita outcome. TWFE is two-way fixed effects (country + year) clustered at the country level. Sun-Abraham reports the average of post-treatment event-study coefficients.",
  "\\item $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_robustness.tex")
message("Table 4 written")

# ===========================================================================
# Table F1: Standardized Effect Size (SDE) Appendix
# ===========================================================================
message("\n=== Table F1: SDE Appendix ===")

# Compute SDE for main outcomes
# SDE = beta / SD(Y_pre) for binary treatment
pre_panel <- panel[year <= 2019]

compute_sde <- function(agg_obj, outcome_var, label) {
  att <- agg_obj$overall.att
  se <- agg_obj$overall.se
  sd_y <- sd(pre_panel[[outcome_var]], na.rm = TRUE)
  sde <- att / sd_y
  se_sde <- se / sd_y

  # Classification
  cls <- if (sde < -0.15) "Large negative"
    else if (sde < -0.05) "Moderate negative"
    else if (sde < -0.005) "Small negative"
    else if (sde <= 0.005) "Null"
    else if (sde <= 0.05) "Small positive"
    else if (sde <= 0.15) "Moderate positive"
    else "Large positive"

  data.table(
    Outcome = label,
    beta = att,
    se = se,
    sd_y = sd_y,
    sde = sde,
    se_sde = se_sde,
    classification = cls
  )
}

sde_rows <- rbind(
  compute_sde(agg_plastic, "plastic_pc", "Plastic packaging (kg/person)"),
  compute_sde(agg_paper, "paper_pc", "Paper/cardboard packaging (kg/person)"),
  compute_sde(agg_share, "plastic_share", "Plastic share of total"),
  compute_sde(agg_total, "total_pc", "Total packaging (kg/person)")
)

# Heterogeneity: split by GDP tercile (high vs low income EU countries)
gdp_pre <- panel[year == 2019 & !is.na(gdp_pc), .(geo, gdp_pc)]
med_gdp <- median(gdp_pre$gdp_pc)
high_gdp_countries <- gdp_pre[gdp_pc >= med_gdp, geo]
low_gdp_countries <- gdp_pre[gdp_pc < med_gdp, geo]

# Re-estimate for high-income subset
cs_high <- panel[geo %in% high_gdp_countries & !is.na(plastic_pc) & !is.na(first_treat)]
cs_high[, country_id_h := as.integer(factor(geo))]

cs_high_fit <- tryCatch({
  att_gt(yname = "plastic_pc", tname = "year", idname = "country_id_h",
         gname = "first_treat", data = cs_high, control_group = "notyettreated",
         est_method = "dr", bstrap = TRUE, biters = 500)
}, error = function(e) NULL)

if (!is.null(cs_high_fit)) {
  agg_high <- aggte(cs_high_fit, type = "simple")
  sd_y_high <- sd(pre_panel[geo %in% high_gdp_countries]$plastic_pc, na.rm = TRUE)
  sde_high <- agg_high$overall.att / sd_y_high
  se_sde_high <- agg_high$overall.se / sd_y_high

  cls_high <- if (sde_high < -0.15) "Large negative"
    else if (sde_high < -0.05) "Moderate negative"
    else if (sde_high < -0.005) "Small negative"
    else if (sde_high <= 0.005) "Null"
    else if (sde_high <= 0.05) "Small positive"
    else if (sde_high <= 0.15) "Moderate positive"
    else "Large positive"

  sde_row_high <- data.table(
    Outcome = "Plastic (kg/person), high-income EU",
    beta = agg_high$overall.att,
    se = agg_high$overall.se,
    sd_y = sd_y_high,
    sde = sde_high,
    se_sde = se_sde_high,
    classification = cls_high
  )
} else {
  sde_row_high <- data.table(
    Outcome = "Plastic (kg/person), high-income EU",
    beta = NA, se = NA, sd_y = NA, sde = NA, se_sde = NA, classification = "N/A"
  )
}

# Low-income subset
cs_low <- panel[geo %in% low_gdp_countries & !is.na(plastic_pc) & !is.na(first_treat)]
cs_low[, country_id_l := as.integer(factor(geo))]

cs_low_fit <- tryCatch({
  att_gt(yname = "plastic_pc", tname = "year", idname = "country_id_l",
         gname = "first_treat", data = cs_low, control_group = "notyettreated",
         est_method = "dr", bstrap = TRUE, biters = 500)
}, error = function(e) NULL)

if (!is.null(cs_low_fit)) {
  agg_low <- aggte(cs_low_fit, type = "simple")
  sd_y_low <- sd(pre_panel[geo %in% low_gdp_countries]$plastic_pc, na.rm = TRUE)
  sde_low <- agg_low$overall.att / sd_y_low
  se_sde_low <- agg_low$overall.se / sd_y_low

  cls_low <- if (sde_low < -0.15) "Large negative"
    else if (sde_low < -0.05) "Moderate negative"
    else if (sde_low < -0.005) "Small negative"
    else if (sde_low <= 0.005) "Null"
    else if (sde_low <= 0.05) "Small positive"
    else if (sde_low <= 0.15) "Moderate positive"
    else "Large positive"

  sde_row_low <- data.table(
    Outcome = "Plastic (kg/person), low-income EU",
    beta = agg_low$overall.att,
    se = agg_low$overall.se,
    sd_y = sd_y_low,
    sde = sde_low,
    se_sde = se_sde_low,
    classification = cls_low
  )
} else {
  sde_row_low <- data.table(
    Outcome = "Plastic (kg/person), low-income EU",
    beta = NA, se = NA, sd_y = NA, sde = NA, se_sde = NA, classification = "N/A"
  )
}

sde_all <- rbind(sde_rows, sde_row_high, sde_row_low)

# Build SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} 27 European Union member states. ",
  "\\textbf{Research question:} Whether the EU Single-Use Plastics Directive (2019/904), ",
  "which bans specific plastic products (cutlery, plates, straws, stirrers, EPS containers), ",
  "reduces plastic packaging waste or shifts waste composition toward paper and cardboard alternatives. ",
  "\\textbf{Policy mechanism:} The directive mandates national bans on enumerated single-use plastic ",
  "items and requires member states to transpose the prohibition into domestic law, creating a binding ",
  "supply-side restriction on banned product categories while leaving substitute materials unregulated. ",
  "\\textbf{Outcome definition:} Plastic packaging waste generation in kilograms per person per year, ",
  "from Eurostat \\texttt{env\\_waspac} (waste code W150102). ",
  "\\textbf{Treatment:} Binary; country-year is treated once the national transposition enters into force. ",
  "\\textbf{Data:} Eurostat \\texttt{env\\_waspac} and \\texttt{demo\\_pjan}, 27 EU countries, 2006--2023, ",
  "country-year observations, approximately 450 observations. ",
  "\\textbf{Method:} Callaway-Sant'Anna (2021) doubly robust estimator with not-yet-treated comparison group, ",
  "clustered bootstrap inference at the country level. ",
  "\\textbf{Sample:} All 27 EU member states with available packaging waste data; no exclusions. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment (2006--2019) ",
  "standard deviation of the outcome. Panel A reports pooled estimates for main outcomes. ",
  "Panel B reports heterogeneous effects by GDP per capita (median split, 2019 values). ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "  Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i]
  tabF1_lines <- c(tabF1_lines,
    sprintf("  %s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
            r$Outcome, r$beta, r$se, r$sd_y, r$sde, r$se_sde, r$classification))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (GDP per capita median split)}} \\\\[3pt]"
)

for (r_row in list(sde_row_high, sde_row_low)) {
  if (!is.na(r_row$beta)) {
    tabF1_lines <- c(tabF1_lines,
      sprintf("  %s & %.2f & %.2f & %.2f & %.3f & %.3f & %s \\\\",
              r_row$Outcome, r_row$beta, r_row$se, r_row$sd_y,
              r_row$sde, r_row$se_sde, r_row$classification))
  } else {
    tabF1_lines <- c(tabF1_lines,
      sprintf("  %s & --- & --- & --- & --- & --- & N/A \\\\", r_row$Outcome))
  }
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
message("Table F1 (SDE) written to tables/tabF1_sde.tex")

message("\n=== All tables generated ===")
