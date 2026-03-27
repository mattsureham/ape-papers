# 05_tables.R — Generate all tables for apep_1061
# Polish abortion ruling border-distance DiD

source("00_packages.R")

panel <- readRDS("../data/panel_nuts2.rds")
models <- readRDS("../data/models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
summ_stats <- readRDS("../data/summ_stats.rds")

# ---------------------------------------------------------------
# Table 1: Summary Statistics
# ---------------------------------------------------------------
cat("=== Generating Table 1: Summary Statistics ===\n")

pre <- panel[panel$year >= 2015 & panel$year <= 2020, ]
post_data <- panel[panel$year >= 2021, ]

# Build summary stat rows
vars_to_summarize <- list(
  list(var = "tfr", label = "Total Fertility Rate"),
  list(var = "dist_min_km", label = "Distance to nearest clinic (km)")
)

if ("gdp_pc" %in% names(panel)) {
  vars_to_summarize <- c(vars_to_summarize,
    list(list(var = "gdp_pc", label = "GDP per capita (EUR)")))
}
if ("unemp_rate" %in% names(panel)) {
  vars_to_summarize <- c(vars_to_summarize,
    list(list(var = "unemp_rate", label = "Unemployment rate (\\%)")))
}
if ("population" %in% names(panel)) {
  vars_to_summarize <- c(vars_to_summarize,
    list(list(var = "population", label = "Population")))
}

tab1_rows <- ""
for (v in vars_to_summarize) {
  pre_vals <- pre[[v$var]]
  post_vals <- post_data[[v$var]]
  pre_vals <- pre_vals[!is.na(pre_vals)]
  post_vals <- post_vals[!is.na(post_vals)]

  if (v$var == "population") {
    tab1_rows <- paste0(tab1_rows, sprintf(
      "%s & %s & %s & %s & %s \\\\\n",
      v$label,
      formatC(round(mean(pre_vals)), format = "d", big.mark = ","),
      formatC(round(sd(pre_vals)), format = "d", big.mark = ","),
      formatC(round(mean(post_vals)), format = "d", big.mark = ","),
      formatC(round(sd(post_vals)), format = "d", big.mark = ",")))
  } else {
    tab1_rows <- paste0(tab1_rows, sprintf(
      "%s & %.3f & %.3f & %.3f & %.3f \\\\\n",
      v$label, mean(pre_vals), sd(pre_vals), mean(post_vals), sd(post_vals)))
  }
}

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Pre-treatment (2015--2020)} & \\multicolumn{2}{c}{Post-treatment (2021--2023)} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  "Variable & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  tab1_rows,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} Panel of %d Polish NUTS2 voivodships, 2015--2023. ",
          length(unique(panel$geo))),
  "Distance is geodesic distance from voivodship capital to nearest accessible abortion clinic ",
  "in Germany or Czech Republic. TFR is the total fertility rate from Eurostat (demo\\_r\\_find2). ",
  sprintf("N = %d voivodship-year observations.\n", nrow(panel[panel$year >= 2015, ])),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ---------------------------------------------------------------
# Table 2: Main Results
# ---------------------------------------------------------------
cat("=== Generating Table 2: Main Results ===\n")

m1 <- models$m1
m2 <- models$m2
m3 <- models$m3
m4 <- models$m4

# Extract coefficients manually for precise control
extract_coef <- function(model, var_name) {
  cf <- coef(model)
  se_vals <- se(model)
  pv <- pvalue(model)
  idx <- grep(var_name, names(cf), fixed = TRUE)
  if (length(idx) == 0) idx <- grep(var_name, names(cf))
  if (length(idx) == 0) return(list(b = NA, se = NA, p = NA))
  list(b = cf[idx[1]], se = se_vals[idx[1]], p = pv[idx[1]])
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.10) return("$^{*}$")
  return("")
}

# Main coefficient rows
r1 <- extract_coef(m1, "post_x_dist")
r3 <- extract_coef(m3, "post_x_dist_std")

# For m4 (binary), extract the post × far interaction
r4 <- extract_coef(m4, "far_from_border")

# Build table
tab2_body <- ""

# Row 1: Post × Distance (km)
tab2_body <- paste0(tab2_body, sprintf(
  "Post $\\times$ Distance (km) & %.6f%s & %s & & \\\\\n",
  r1$b, stars(r1$p),
  if (!is.null(m2)) {
    r2 <- extract_coef(m2, "post_x_dist")
    sprintf("%.6f%s", r2$b, stars(r2$p))
  } else ""))

tab2_body <- paste0(tab2_body, sprintf(
  " & (%.6f) & %s & & \\\\\n",
  r1$se,
  if (!is.null(m2)) sprintf("(%.6f)", extract_coef(m2, "post_x_dist")$se) else ""))

# Row 2: Post × Distance (std)
tab2_body <- paste0(tab2_body, sprintf(
  "Post $\\times$ Distance (std) & & & %.4f%s & \\\\\n",
  r3$b, stars(r3$p)))
tab2_body <- paste0(tab2_body, sprintf(
  " & & & (%.4f) & \\\\\n", r3$se))

# Row 3: Post × Far from border
tab2_body <- paste0(tab2_body, sprintf(
  "Post $\\times$ Far & & & & %.4f%s \\\\\n",
  r4$b, stars(r4$p)))
tab2_body <- paste0(tab2_body, sprintf(
  " & & & & (%.4f) \\\\\n", r4$se))

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Abortion Ruling on Fertility: Border Distance Gradient}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Baseline & Controls & Standardized & Binary \\\\\n",
  "\\midrule\n",
  tab2_body,
  "\\midrule\n",
  sprintf("Region FE & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("Year FE & Yes & Yes & Yes & Yes \\\\\n"),
  sprintf("Controls & No & Yes & No & No \\\\\n"),
  sprintf("Observations & %d & %d & %d & %d \\\\\n",
          nobs(m1),
          if (!is.null(m2)) nobs(m2) else nobs(m1),
          nobs(m3), nobs(m4)),
  sprintf("Regions & %d & %d & %d & %d \\\\\n",
          length(unique(panel$geo)), length(unique(panel$geo)),
          length(unique(panel$geo)), length(unique(panel$geo))),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Standard errors clustered at the voivodship level in parentheses. ",
  "Dependent variable is the total fertility rate (TFR). ",
  "Column (1) shows the baseline continuous-treatment DiD: the coefficient on ",
  "Post $\\times$ Distance gives the differential TFR change per additional kilometer ",
  "from the nearest border clinic after 2021. ",
  "Column (2) adds GDP per capita and unemployment rate as controls. ",
  "Column (3) standardizes distance (mean 0, SD 1). ",
  "Column (4) splits regions above/below median distance. ",
  "Treatment date: January 27, 2021 (Constitutional Tribunal ruling K 1/20 effective).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ---------------------------------------------------------------
# Table 3: Event Study Coefficients
# ---------------------------------------------------------------
cat("=== Generating Table 3: Event Study ===\n")

m_es <- models$m_es
es_coefs <- coef(m_es)
es_se <- se(m_es)
es_pv <- pvalue(m_es)

# Parse event time from coefficient names
es_names <- names(es_coefs)
es_times <- as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", es_names))

es_df <- data.frame(
  event_time = es_times,
  coef = es_coefs,
  se = es_se,
  pval = es_pv,
  stringsAsFactors = FALSE
)
es_df <- es_df[order(es_df$event_time), ]

tab3_body <- ""
for (i in seq_len(nrow(es_df))) {
  et <- es_df$event_time[i]
  lab <- if (et < 0) sprintf("$t%d$", et) else sprintf("$t+%d$", et)
  tab3_body <- paste0(tab3_body, sprintf(
    "%s & %.4f%s & (%.4f) \\\\\n",
    lab, es_df$coef[i], stars(es_df$pval[i]), es_df$se[i]))
}

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Distance Gradient by Year}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Event time & Coefficient & SE \\\\\n",
  "\\midrule\n",
  tab3_body,
  "\\midrule\n",
  "Reference period & \\multicolumn{2}{c}{$t-1$ (2020)} \\\\\n",
  sprintf("Observations & \\multicolumn{2}{c}{%d} \\\\\n", nobs(m_es)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Standard errors clustered at the voivodship level. ",
  "Each coefficient is the interaction of standardized distance (mean 0, SD 1) ",
  "with an event-time indicator. Reference period is $t-1$ (2020). ",
  "Pre-treatment coefficients ($t-8$ through $t-2$) test parallel pre-trends. ",
  "Post-treatment coefficients ($t+0$ through $t+2$) capture the distance gradient effect.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:event_study}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_event_study.tex")

# ---------------------------------------------------------------
# Table 4: Robustness
# ---------------------------------------------------------------
cat("=== Generating Table 4: Robustness ===\n")

extract_rob <- function(model, label) {
  cf <- coef(model)
  se_v <- se(model)
  pv <- pvalue(model)
  # Find the main treatment variable
  idx <- grep("post_x_dist|fake_post_x_dist", names(cf))
  if (length(idx) == 0) idx <- 1
  data.frame(
    spec = label,
    coef = cf[idx[1]],
    se = se_v[idx[1]],
    pval = pv[idx[1]],
    n = nobs(model),
    stringsAsFactors = FALSE
  )
}

rob_rows <- rbind(
  extract_rob(models$m1, "Baseline"),
  extract_rob(rob_models$m_de, "German clinics only"),
  extract_rob(rob_models$m_cz, "Czech clinics only"),
  extract_rob(rob_models$m_no2020, "Excluding 2020"),
  extract_rob(rob_models$m_short, "2017--2023 only"),
  extract_rob(rob_models$m_placebo, "Placebo: 2018 treatment"),
  extract_rob(rob_models$m_placebo17, "Placebo: 2017 treatment")
)

if (!is.null(rob_models$m_weighted)) {
  rob_rows <- rbind(rob_rows,
    extract_rob(rob_models$m_weighted, "Population-weighted"))
}

tab4_body <- ""
for (i in seq_len(nrow(rob_rows))) {
  tab4_body <- paste0(tab4_body, sprintf(
    "%s & %.6f%s & (%.6f) & %d \\\\\n",
    rob_rows$spec[i], rob_rows$coef[i], stars(rob_rows$pval[i]),
    rob_rows$se[i], rob_rows$n[i]))
}

tab4 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Post $\\times$ Distance & SE & N \\\\\n",
  "\\midrule\n",
  tab4_body,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} * $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "Each row reports the coefficient on Post $\\times$ Distance (km) from a separate regression ",
  "with voivodship and year fixed effects. Standard errors clustered at the voivodship level. ",
  "``German clinics only'' and ``Czech clinics only'' use distance to the nearest clinic in each country. ",
  "``Excluding 2020'' drops the COVID onset year. ",
  "Placebo tests apply a fake treatment date to the pre-treatment period only.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robustness}\n",
  "\\end{table}\n"
)

writeLines(tab4, "../tables/tab4_robustness.tex")

# ---------------------------------------------------------------
# Table F1: SDE (Standardized Effect Sizes)
# ---------------------------------------------------------------
cat("=== Generating Table F1: Standardized Effect Sizes ===\n")

# Main specification coefficients
m1_coef <- coef(models$m1)["post_x_dist"]
m1_se <- se(models$m1)["post_x_dist"]

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sd_y_pre <- sd(panel$tfr[panel$year < 2021])
sd_x <- sd(panel$dist_min_km)

sde_pooled <- m1_coef * sd_x / sd_y_pre
se_sde_pooled <- m1_se * sd_x / sd_y_pre

# Classification function
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

# Panel B: Heterogeneity by urbanization proxy (Warsaw vs rest)
# Split: Warsaw region (PL91/PL92/PL72) vs others
warsaw_regions <- c("PL91", "PL92", "PL72")
panel$urban <- as.integer(panel$geo %in% warsaw_regions)

m_urban <- feols(tfr ~ post_x_dist | geo + year,
                 data = panel[panel$urban == 1, ], cluster = ~geo)
m_rural <- feols(tfr ~ post_x_dist | geo + year,
                 data = panel[panel$urban == 0, ], cluster = ~geo)

# SDE for subgroups
sde_urban <- coef(m_urban)["post_x_dist"] * sd_x / sd_y_pre
se_sde_urban <- se(m_urban)["post_x_dist"] * sd_x / sd_y_pre
sde_rural <- coef(m_rural)["post_x_dist"] * sd_x / sd_y_pre
se_sde_rural <- se(m_rural)["post_x_dist"] * sd_x / sd_y_pre

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Poland. ",
  "\\textbf{Research question:} Does the effective cost of an abortion restriction---determined by ",
  "distance to foreign clinics---shape its demographic impact on fertility? ",
  "\\textbf{Policy mechanism:} Poland's Constitutional Tribunal ruling K~1/20 (October 2020, effective January 2021) ",
  "eliminated abortion on fetal anomaly grounds, which accounted for approximately 97\\% of all legal terminations; ",
  "women in border regions can substitute to clinics in Germany and Czech Republic, while women in interior regions face ",
  "substantially higher travel costs to access services abroad. ",
  "\\textbf{Outcome definition:} Total fertility rate (TFR) from Eurostat demographic indicators at NUTS2 level, ",
  "measuring the average number of children per woman. ",
  "\\textbf{Treatment:} Continuous; geodesic distance in kilometers from voivodship capital to nearest accessible ",
  "abortion clinic in Germany or Czech Republic. ",
  "\\textbf{Data:} Eurostat demo\\_r\\_find2, 2013--2023, voivodship-year panel, ",
  sprintf("%d voivodship-year observations. ", nrow(panel)),
  "\\textbf{Method:} Continuous-treatment difference-in-differences with voivodship and year fixed effects; ",
  "standard errors clustered at the voivodship level; wild cluster bootstrap for inference with few clusters. ",
  "\\textbf{Sample:} All 17 Polish NUTS2 voivodships (complete panel, no restrictions). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of TFR and SD($X$) is the standard deviation of distance. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Build SDE table
tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccccc}\n",
  "\\toprule\n",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sprintf("TFR & Baseline DiD & %.6f & %.6f & %.1f & %.4f & %.4f & %.4f & %s \\\\\n",
          m1_coef, m1_se, sd_x, sd_y_pre, sde_pooled, se_sde_pooled, classify_sde(sde_pooled)),
  "\\midrule\n",
  "\\multicolumn{9}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n",
  sprintf("TFR & Urban voivod. & %.6f & %.6f & %.1f & %.4f & %.4f & %.4f & %s \\\\\n",
          coef(m_urban)["post_x_dist"], se(m_urban)["post_x_dist"],
          sd_x, sd_y_pre, sde_urban, se_sde_urban, classify_sde(sde_urban)),
  sprintf("TFR & Non-urban voivod. & %.6f & %.6f & %.1f & %.4f & %.4f & %.4f & %s \\\\\n",
          coef(m_rural)["post_x_dist"], se(m_rural)["post_x_dist"],
          sd_x, sd_y_pre, sde_rural, se_sde_rural, classify_sde(sde_rural)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files written:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_event_study.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
