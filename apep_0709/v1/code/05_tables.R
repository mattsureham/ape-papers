# 05_tables.R — Generate all LaTeX tables
# apep_0709: Markets Under Fire

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
cs_att <- readRDS(file.path(data_dir, "cs_att.rds"))
cs_dynamic <- readRDS(file.path(data_dir, "cs_dynamic.rds"))
cs_by_type <- readRDS(file.path(data_dir, "cs_by_type.rds"))
market_treatment <- readRDS(file.path(data_dir, "market_treatment.rds"))
outcome_sds <- readRDS(file.path(data_dir, "outcome_sds.rds"))
radius_results <- readRDS(file.path(data_dir, "radius_results.rds"))
diagnostics <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))

sa_fit <- readRDS(file.path(data_dir, "sa_fit.rds"))
intensity_fit <- readRDS(file.path(data_dir, "intensity_fit.rds"))

# Helper for stars
stars <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

# By treatment status
summ_treated <- panel[treated == TRUE, .(
  Mean_T = mean(price, na.rm = TRUE),
  SD_T = sd(price, na.rm = TRUE),
  N_T = .N
), by = commodity_clean]

summ_control <- panel[treated == FALSE, .(
  Mean_C = mean(price, na.rm = TRUE),
  SD_C = sd(price, na.rm = TRUE),
  N_C = .N
), by = commodity_clean]

summ <- merge(summ_treated, summ_control, by = "commodity_clean")
summ <- summ[order(commodity_clean)]

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics: Food Prices by Commodity and Treatment Status}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Treated Markets} & & \\multicolumn{2}{c}{Never-Treated Markets} & \\\\",
  "\\cmidrule{2-3} \\cmidrule{5-6}",
  "Commodity & Mean & SD & & Mean & SD & Obs. \\\\",
  "\\midrule"
)

for (i in 1:nrow(summ)) {
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %.0f & %.0f & & %.0f & %.0f & %s \\\\",
    summ$commodity_clean[i],
    summ$Mean_T[i], summ$SD_T[i],
    summ$Mean_C[i], summ$SD_C[i],
    format(summ$N_T[i] + summ$N_C[i], big.mark = ",")
  ))
}

# Add overall row
tab1_lines <- c(tab1_lines,
  "\\midrule",
  sprintf("All commodities & %.0f & %.0f & & %.0f & %.0f & %s \\\\",
          mean(panel[treated == TRUE]$price), sd(panel[treated == TRUE]$price),
          mean(panel[treated == FALSE]$price), sd(panel[treated == FALSE]$price),
          format(nrow(panel), big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} Prices in CFA francs per kilogram from WFP Global Food Prices Database, 2012--2023. Treated markets are those with at least one UCDP conflict event within 50km. %d markets are treated (staggered onset 2016--2022); %d markets are never-treated. N = %s market-commodity-month observations.",
          sum(market_treatment$treated), sum(!market_treatment$treated),
          format(nrow(panel), big.mark = ",")),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: Main Results — CS ATT
# ============================================================
cat("Generating Table 2: Main Results...\n")

cs_p <- 2 * pnorm(-abs(cs_att$overall.att / cs_att$overall.se))

# Sun-Abraham ATT
sa_coefs <- coef(sa_fit)
sa_ses <- se(sa_fit)
sa_names <- names(sa_coefs)
# sunab names are like "t_q::5" where the number is relative period
sa_rel <- as.numeric(gsub(".*::", "", sa_names))
sa_post_idx <- which(sa_rel >= 0)
sa_att_mean <- mean(sa_coefs[sa_post_idx])
# Approximate SE via delta method (SE of mean of coefficients)
sa_att_se <- sqrt(mean(sa_ses[sa_post_idx]^2) / length(sa_post_idx))
sa_att_p <- 2 * pnorm(-abs(sa_att_mean / sa_att_se))

# TWFE for comparison
twfe_data <- panel[, .(log_price = mean(log_price, na.rm = TRUE)),
                    by = .(market_id, ym, treated, post,
                           t = as.integer(ym - min(ym)) + 1)]
twfe_fit <- feols(log_price ~ post | market_id + t, data = twfe_data, cluster = ~market_id)
twfe_coef <- coef(twfe_fit)["postTRUE"]
twfe_se <- se(twfe_fit)["postTRUE"]
twfe_p <- pvalue(twfe_fit)["postTRUE"]

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of Conflict on Food Prices}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & CS ATT & Sun--Abraham & TWFE \\\\",
  "\\midrule",
  sprintf("Conflict exposure & %s%s & %s%s & %s%s \\\\",
          sprintf("%.4f", cs_att$overall.att), stars(cs_p),
          sprintf("%.4f", sa_att_mean), stars(sa_att_p),
          sprintf("%.4f", twfe_coef), stars(twfe_p)),
  sprintf(" & (%.4f) & (%.4f) & (%.4f) \\\\",
          cs_att$overall.se, sa_att_se, twfe_se),
  "\\\\",
  sprintf("Markets & %d & %d & %d \\\\",
          diagnostics$n_markets, diagnostics$n_markets, diagnostics$n_markets),
  sprintf("Treated markets & %d & %d & %d \\\\",
          diagnostics$n_treated, diagnostics$n_treated, diagnostics$n_treated),
  sprintf("Observations & %s & %s & %s \\\\",
          format(3072, big.mark = ","),
          format(3072, big.mark = ","),
          format(3072, big.mark = ",")),
  "Market FE & Yes & Yes & Yes \\\\",
  "Time FE & Yes & Yes & Yes \\\\",
  "Control group & Not-yet-treated & Not-yet-treated & All \\\\",
  "Estimator & Callaway--Sant'Anna & Sun--Abraham & TWFE \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dependent variable is log food price (CFA/kg), aggregated to market-quarter level. Treatment is defined as the first UCDP conflict event within 50km of the market. Column (1) reports the Callaway and Sant'Anna (2021) aggregated ATT using not-yet-treated markets as the comparison group. Column (2) reports the Sun and Abraham (2021) interaction-weighted estimator; the reported coefficient and SE are the mean and approximate SE of post-treatment event-time coefficients. Column (3) reports standard TWFE for comparison. Standard errors clustered at the market level in parentheses. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(tables_dir, "tab2_main.tex"))

# ============================================================
# Table 3: Heterogeneity by Commodity Type
# ============================================================
cat("Generating Table 3: Heterogeneity by Commodity Type...\n")

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Conflict Effects by Commodity Type: The Market Disruption Channel}",
  "\\label{tab:mechanism}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Local Cereals & Imported Rice & Protein/Legumes \\\\",
  " & (Millet, Sorghum, Maize) & & (Cowpeas, Groundnuts) \\\\",
  "\\midrule"
)

for (ctype in c("Local cereal", "Imported", "Protein/legume")) {
  col_label <- switch(ctype,
    "Local cereal" = "(1)",
    "Imported" = "(2)",
    "Protein/legume" = "(3)"
  )

  if (!is.null(cs_by_type[[ctype]])) {
    att <- cs_by_type[[ctype]]$overall.att
    se_val <- cs_by_type[[ctype]]$overall.se
    p_val <- 2 * pnorm(-abs(att / se_val))
  } else {
    att <- NA; se_val <- NA; p_val <- NA
  }

  if (!is.na(att)) {
    tab3_lines <- c(tab3_lines,
      sprintf("Conflict exposure & %.4f%s & & \\\\", att, stars(p_val)),
      sprintf(" & (%.4f) & & \\\\", se_val)
    )
  }
}

# Build proper table with all three columns
types_order <- c("Local cereal", "Imported", "Protein/legume")
atts <- sapply(types_order, function(ct) {
  if (!is.null(cs_by_type[[ct]])) cs_by_type[[ct]]$overall.att else NA
})
ses <- sapply(types_order, function(ct) {
  if (!is.null(cs_by_type[[ct]])) cs_by_type[[ct]]$overall.se else NA
})
ps <- sapply(types_order, function(ct) {
  if (!is.null(cs_by_type[[ct]])) 2 * pnorm(-abs(cs_by_type[[ct]]$overall.att / cs_by_type[[ct]]$overall.se)) else NA
})

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Conflict Effects by Commodity Type: The Market Disruption Channel}",
  "\\label{tab:mechanism}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & Local Cereals & Imported Rice & Protein/Legumes \\\\",
  "\\midrule",
  sprintf("Conflict exposure & %s & %s & %s \\\\",
          ifelse(!is.na(atts[1]), sprintf("%.4f%s", atts[1], stars(ps[1])), "---"),
          ifelse(!is.na(atts[2]), sprintf("%.4f%s", atts[2], stars(ps[2])), "---"),
          ifelse(!is.na(atts[3]), sprintf("%.4f%s", atts[3], stars(ps[3])), "---")),
  sprintf(" & %s & %s & %s \\\\",
          ifelse(!is.na(ses[1]), sprintf("(%.4f)", ses[1]), ""),
          ifelse(!is.na(ses[2]), sprintf("(%.4f)", ses[2]), ""),
          ifelse(!is.na(ses[3]), sprintf("(%.4f)", ses[3]), "")),
  "\\\\",
  "Estimator & CS ATT & CS ATT & CS ATT \\\\",
  "Control group & Not-yet-treated & Not-yet-treated & Not-yet-treated \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Each column reports the Callaway and Sant'Anna (2021) ATT estimated separately by commodity type. Local cereals include millet, sorghum, and maize (locally produced, bulky, transport-sensitive). Imported rice arrives via international supply chains less disrupted by local violence. Protein/legumes (cowpeas, groundnuts) are locally produced but higher value-to-weight. Standard errors clustered at the market level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(tables_dir, "tab3_mechanism.tex"))

# ============================================================
# Table 4: Robustness — Alternative Radii
# ============================================================
cat("Generating Table 4: Robustness...\n")

# Combine main + alternative radius results
all_radii <- c("50" = list(list(att = cs_att$overall.att, se = cs_att$overall.se,
                                n_treated = diagnostics$n_treated,
                                n_control = diagnostics$n_never_treated)))
for (r in names(radius_results)) {
  all_radii[[r]] <- radius_results[[r]]
}

# Add intensity result
int_coef <- coef(intensity_fit)[1]
int_se <- se(intensity_fit)[1]
int_p <- pvalue(intensity_fit)[1]

radii_order <- c("30", "50", "75", "100")
radii_present <- radii_order[radii_order %in% names(all_radii)]

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Treatment Definitions}",
  "\\label{tab:robustness}",
  "\\begin{threeparttable}",
  sprintf("\\begin{tabular}{l%s}", paste(rep("c", length(radii_present) + 1), collapse = "")),
  "\\toprule"
)

# Column headers
col_nums <- paste(sprintf("(%d)", 1:(length(radii_present) + 1)), collapse = " & ")
tab4_lines <- c(tab4_lines, sprintf(" & %s \\\\", col_nums))

col_labels <- c(paste0(radii_present, "km radius"), "Intensity")
tab4_lines <- c(tab4_lines,
  sprintf(" & %s \\\\", paste(col_labels, collapse = " & ")),
  "\\midrule"
)

# Coefficients
coef_cells <- sapply(radii_present, function(r) {
  a <- all_radii[[r]]
  p <- 2 * pnorm(-abs(a$att / a$se))
  sprintf("%.4f%s", a$att, stars(p))
})
coef_cells <- c(coef_cells, sprintf("%.4f%s", int_coef, stars(int_p)))
tab4_lines <- c(tab4_lines, sprintf("Conflict exposure & %s \\\\",
                                     paste(coef_cells, collapse = " & ")))

# SEs
se_cells <- sapply(radii_present, function(r) sprintf("(%.4f)", all_radii[[r]]$se))
se_cells <- c(se_cells, sprintf("(%.4f)", int_se))
tab4_lines <- c(tab4_lines, sprintf(" & %s \\\\", paste(se_cells, collapse = " & ")))

tab4_lines <- c(tab4_lines,
  "\\\\",
  sprintf("Treatment & %s \\\\",
          paste(c(rep("Binary onset", length(radii_present)), "Log(cum. events)"), collapse = " & ")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Columns (1)--(2) vary the radius for defining conflict exposure using Callaway and Sant'Anna (2021) with not-yet-treated controls. Column (3) uses log cumulative UCDP events within 50km as a continuous intensity measure with market and time fixed effects. Standard errors clustered at the market level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(tables_dir, "tab4_robustness.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

sd_y <- outcome_sds$sd_log_price_pre  # Pre-treatment SD of log price

# Main outcomes for SDE
sde_rows <- data.frame(
  Outcome = character(),
  Spec = character(),
  beta = numeric(),
  se_beta = numeric(),
  sd_y = numeric(),
  sde = numeric(),
  se_sde = numeric(),
  classification = character(),
  stringsAsFactors = FALSE
)

# Helper
classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15 ~ "Large negative",
    s < -0.05 ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s < 0.005 ~ "Null",
    s < 0.05 ~ "Small positive",
    s < 0.15 ~ "Moderate positive",
    TRUE ~ "Large positive"
  )
}

# 1. Overall CS ATT
sde_rows <- rbind(sde_rows, data.frame(
  Outcome = "Log food price (all)",
  Spec = "CS ATT",
  beta = cs_att$overall.att,
  se_beta = cs_att$overall.se,
  sd_y = sd_y,
  sde = cs_att$overall.att / sd_y,
  se_sde = cs_att$overall.se / sd_y,
  classification = classify_sde(cs_att$overall.att / sd_y)
))

# 2-4. By commodity type
for (ctype in c("Local cereal", "Imported", "Protein/legume")) {
  if (!is.null(cs_by_type[[ctype]])) {
    a <- cs_by_type[[ctype]]
    # Use overall SD for comparability
    sde_rows <- rbind(sde_rows, data.frame(
      Outcome = sprintf("Log price (%s)", ctype),
      Spec = "CS ATT",
      beta = a$overall.att,
      se_beta = a$overall.se,
      sd_y = sd_y,
      sde = a$overall.att / sd_y,
      se_sde = a$overall.se / sd_y,
      classification = classify_sde(a$overall.att / sd_y)
    ))
  }
}

# Build SDE table
sde_notes <- paste0(
  "\\item \\parbox{\\textwidth}{\\textit{Notes:} ",
  "\\textbf{Country:} Burkina Faso. ",
  "\\textbf{Research question:} Does the geographic spread of jihadist violence from Mali into Burkina Faso raise food prices in affected market towns? ",
  "\\textbf{Policy mechanism:} Armed conflict disrupts local supply chains by destroying market infrastructure, displacing farmers and traders, and impeding road transport of bulky agricultural commodities; imported goods arriving via international corridors face less disruption. ",
  "\\textbf{Outcome definition:} Log of monthly retail food price in CFA francs per kilogram, from WFP-monitored markets. ",
  "\\textbf{Treatment:} Binary indicator equal to one from the first month a UCDP-coded conflict event occurs within 50km of the market. ",
  "\\textbf{Data:} WFP Global Food Prices Database and UCDP Georeferenced Event Dataset v24.1, monthly market-level panel 2012--2023, ",
  format(nrow(panel), big.mark = ","), " market-commodity-month observations across ",
  diagnostics$n_markets, " markets. ",
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered difference-in-differences using not-yet-treated markets as controls; standard errors clustered at the market level. ",
  "\\textbf{Sample:} WFP-monitored markets in Burkina Faso with continuous monthly price reporting for major staple commodities (millet, sorghum, maize, rice, cowpeas, groundnuts). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log prices. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$).}"
)

sde_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccc}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)

for (i in 1:nrow(sde_rows)) {
  sde_lines <- c(sde_lines, sprintf(
    "%s & %s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\",
    sde_rows$Outcome[i], sde_rows$Spec[i],
    sde_rows$beta[i], sde_rows$se_beta[i], sde_rows$sd_y[i],
    sde_rows$sde[i], sde_rows$se_sde[i], sde_rows$classification[i]
  ))
}

sde_lines <- c(sde_lines,
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

writeLines(sde_lines, file.path(tables_dir, "tabF1_sde.tex"))

# ============================================================
# Table 5: Event Study Coefficients
# ============================================================
cat("Generating Table 5: Event Study...\n")

es_data <- data.frame(
  event_time = cs_dynamic$egt,
  att = cs_dynamic$att.egt,
  se = cs_dynamic$se.egt
)
es_data$p <- 2 * pnorm(-abs(es_data$att / es_data$se))

# Select key event times for table (-12, -6, -3, -1, 0, 3, 6, 12, 18, 24)
key_times <- c(-12, -6, -3, -1, 0, 3, 6, 12, 18, 24)
es_key <- es_data[es_data$event_time %in% key_times, ]
es_key <- es_key[order(es_key$event_time), ]

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Dynamic Treatment Effects}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Months Relative to Conflict & ATT & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_key)) {
  ci_lo <- es_key$att[i] - 1.96 * es_key$se[i]
  ci_hi <- es_key$att[i] + 1.96 * es_key$se[i]
  tab5_lines <- c(tab5_lines, sprintf(
    "%+d & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
    es_key$event_time[i],
    es_key$att[i], stars(es_key$p[i]),
    es_key$se[i], ci_lo, ci_hi
  ))
}

tab5_lines <- c(tab5_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Dynamic treatment effects from Callaway and Sant'Anna (2021) aggregated by event time. Negative event times are pre-treatment periods; zero is the month of first conflict exposure. Standard errors clustered at the market level. * p$<$0.10, ** p$<$0.05, *** p$<$0.01.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, file.path(tables_dir, "tab5_eventstudy.tex"))

cat("\n=== All tables generated ===\n")
cat(sprintf("Files: %s\n", paste(list.files(tables_dir), collapse = ", ")))
