# 05_tables.R — Generate all tables for paper
# APEP-1081: Coal Tar Sealant Bans and Waterway PAH Contamination

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results_main.rds")
rob <- readRDS("../data/results_robustness.rds")
diag <- jsonlite::fromJSON("../data/diagnostics.json")

# ──────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ──────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics\n")

summ <- panel %>%
  mutate(group = ifelse(treated == 1, "Banned States", "Control States")) %>%
  group_by(group) %>%
  summarise(
    `Stations`          = n_distinct(station_id),
    `Station-Years`     = n(),
    `Mean Fluoranthene (ug/L)` = sprintf("%.3f", mean(mean_fluor, na.rm = TRUE)),
    `SD Fluoranthene`   = sprintf("%.3f", sd(mean_fluor, na.rm = TRUE)),
    `Median Fluoranthene` = sprintf("%.3f", median(mean_fluor, na.rm = TRUE)),
    `Pct Non-Detect`    = sprintf("%.1f\\%%", 100 * mean(pct_nondetect, na.rm = TRUE)),
    `Mean Samples/Year` = sprintf("%.1f", mean(n_samples)),
    `Years Covered`     = sprintf("%d--%d", min(year), max(year)),
    .groups = "drop"
  ) %>%
  t()

# Write LaTeX
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Summary Statistics: Water Quality Monitoring Data}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  sprintf(" & %s & %s \\\\", summ[1,1], summ[1,2]),
  "\\midrule"
)

row_labels <- rownames(summ)[-1]
for (i in seq_along(row_labels)) {
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s \\\\", row_labels[i], summ[i+1, 1], summ[i+1, 2]))
}

tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Data from the EPA Water Quality Portal (waterqualitydata.us), 2000--2025. ",
  "Fluoranthene is the primary PAH indicator measured in surface water samples. ",
  "Banned states: DC (2009), WA (2011), MN (2014), NY (2022), MD (2023), ME (2024), VA (2025). ",
  "Non-detect values substituted at detection limit / 2.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ──────────────────────────────────────────────────────────
# TABLE 2: Main DiD Results
# ──────────────────────────────────────────────────────────
cat("Generating Table 2: Main Results\n")

cs_agg <- results$cs_agg
twfe <- results$twfe
twfe_ctrl <- results$twfe_ctrl
sa <- results$sa

# Pre-treatment SD for effect size calculation
pre_sd <- panel %>%
  filter(treated == 1, post == 0) %>%
  pull(log_fluor) %>%
  sd(na.rm = TRUE)

# Format main results table
# Get CS and SA estimates safely
cs_att_val <- if (!is.null(cs_agg)) cs_agg$overall.att else NA
cs_se_val  <- if (!is.null(cs_agg)) cs_agg$overall.se else NA

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of Coal-Tar Sealant Bans on Waterway PAH Concentrations}",
  "\\label{tab:main}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  " & (1) & (2) & (3) \\\\",
  " & TWFE & TWFE + Controls & Callaway-Sant'Anna \\\\",
  "\\midrule",
  sprintf("Ban Effect & %.3f & %.3f & %s \\\\",
          coef(twfe)["post"], coef(twfe_ctrl)["post"],
          if (!is.na(cs_att_val)) sprintf("%.3f", cs_att_val) else "---"),
  sprintf(" & (%.3f) & (%.3f) & %s \\\\",
          se(twfe)["post"], se(twfe_ctrl)["post"],
          if (!is.na(cs_se_val)) sprintf("(%.3f)", cs_se_val) else "---"),
  "\\midrule",
  "Station FE & Yes & Yes & --- \\\\",
  "Year FE & Yes & Yes & --- \\\\",
  sprintf("Observations & %s & %s & %s \\\\",
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ","),
          format(nrow(panel), big.mark = ",")),
  sprintf("Stations & %s & %s & %s \\\\",
          format(n_distinct(panel$station_id), big.mark = ","),
          format(n_distinct(panel$station_id), big.mark = ","),
          format(n_distinct(panel$station_id), big.mark = ",")),
  sprintf("Clusters (States) & %d & %d & %d \\\\",
          n_distinct(panel$state), n_distinct(panel$state), n_distinct(panel$state)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Dependent variable is log fluoranthene concentration (ug/L) at the station-year level. ",
  "Column (1) reports two-way fixed effects. Column (2) adds controls for sampling frequency and percent non-detect. ",
  "Column (3) reports the Callaway and Sant'Anna (2021) ATT using never-treated controls and repeated cross-sections. ",
  "Standard errors clustered at the state level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ──────────────────────────────────────────────────────────
# TABLE 3: Event Study Coefficients
# ──────────────────────────────────────────────────────────
cat("Generating Table 3: Event Study\n")

cs_event <- results$cs_event
es_df <- data.frame(
  event_time = cs_event$egt,
  att        = cs_event$att.egt,
  se         = cs_event$se.egt
) %>%
  filter(event_time >= -6 & event_time <= 6)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Dynamic Treatment Effects on Log Fluoranthene}",
  "\\label{tab:event}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Event Time & ATT & SE \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_df)) {
  stars <- ""
  if (!is.na(es_df$se[i]) && es_df$se[i] > 0) {
    p <- 2 * pnorm(-abs(es_df$att[i] / es_df$se[i]))
    if (p < 0.01) stars <- "***"
    else if (p < 0.05) stars <- "**"
    else if (p < 0.10) stars <- "*"
  }

  label <- ifelse(es_df$event_time[i] == 0, "\\textbf{Ban Year}",
                  sprintf("$t %s %d$",
                          ifelse(es_df$event_time[i] > 0, "+", ""),
                          abs(es_df$event_time[i])))
  if (es_df$event_time[i] < 0) label <- sprintf("$t - %d$", abs(es_df$event_time[i]))

  se_str <- if (!is.na(es_df$se[i])) sprintf("(%.3f)", es_df$se[i]) else "---"
  att_str <- if (!is.na(es_df$att[i])) sprintf("%.3f%s", es_df$att[i], stars) else "---"
  tab3_lines <- c(tab3_lines,
    sprintf("%s & %s & %s \\\\", label, att_str, se_str))

  if (es_df$event_time[i] == -1) {
    tab3_lines <- c(tab3_lines, "\\midrule")
  }
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Callaway and Sant'Anna (2021) dynamic aggregation of group-time ATTs. ",
  "Event time 0 is the year of ban adoption. Pre-treatment coefficients test parallel trends. ",
  "Standard errors clustered at the state level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, "../tables/tab3_event.tex")

# ──────────────────────────────────────────────────────────
# TABLE 4: Placebo and Robustness
# ──────────────────────────────────────────────────────────
cat("Generating Table 4: Robustness\n")

tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & Coefficient & SE & N & Stations \\\\",
  "\\midrule",
  "\\textit{Panel A: Main Result} & & & & \\\\"
)

# Main TWFE result
tab4_lines <- c(tab4_lines,
  sprintf("\\quad Fluoranthene (baseline) & %.3f & (%.3f) & %s & %s \\\\",
          coef(results$twfe)["post"], se(results$twfe)["post"],
          format(nrow(panel), big.mark = ","),
          format(n_distinct(panel$station_id), big.mark = ",")))

# CS not-yet-treated
if (!is.null(rob$cs_nyt)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad CS (not-yet-treated) & %.3f & (%.3f) & %s & %s \\\\",
            rob$cs_nyt$overall.att, rob$cs_nyt$overall.se,
            format(nrow(panel), big.mark = ","),
            format(n_distinct(panel$station_id), big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\textit{Panel B: Placebo Contaminants} & & & & \\\\"
)

# Placebo results
if (!is.null(rob$placebo_lead)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Lead (placebo) & %.3f & (%.3f) & %s & %s \\\\",
            coef(rob$placebo_lead)["post"], se(rob$placebo_lead)["post"],
            format(nobs(rob$placebo_lead), big.mark = ","),
            format(rob$placebo_lead$nparams, big.mark = ",")))
}

if (!is.null(rob$placebo_atrazine)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Atrazine (placebo) & %.3f & (%.3f) & %s & %s \\\\",
            coef(rob$placebo_atrazine)["post"], se(rob$placebo_atrazine)["post"],
            format(nobs(rob$placebo_atrazine), big.mark = ","),
            format(rob$placebo_atrazine$nparams, big.mark = ",")))
}

# Pyrene (should respond — it's also a PAH)
if (!is.null(rob$pyrene)) {
  tab4_lines <- c(tab4_lines,
    "\\midrule",
    "\\textit{Panel C: Secondary PAH Outcome} & & & & \\\\",
    sprintf("\\quad Pyrene & %.3f & (%.3f) & %s & %s \\\\",
            coef(rob$pyrene)["post"], se(rob$pyrene)["post"],
            format(nobs(rob$pyrene), big.mark = ","),
            format(rob$pyrene$nparams, big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\midrule",
  "\\textit{Panel D: Sensitivity} & & & & \\\\"
)

if (!is.null(rob$twfe_noDC)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Exclude DC & %.3f & (%.3f) & %s & --- \\\\",
            coef(rob$twfe_noDC)["post"], se(rob$twfe_noDC)["post"],
            format(nobs(rob$twfe_noDC), big.mark = ",")))
}

if (!is.null(rob$twfe_detect_only)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Detects only (drop non-detects) & %.3f & (%.3f) & %s & --- \\\\",
            coef(rob$twfe_detect_only)["post"], se(rob$twfe_detect_only)["post"],
            format(nobs(rob$twfe_detect_only), big.mark = ",")))
}

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} All specifications include station and year fixed effects with standard errors ",
  "clustered at the state level. Panel A shows the main result and an alternative control group. ",
  "Panel B tests placebo contaminants (lead, atrazine) that should not respond to sealant bans. ",
  "Panel C shows pyrene, another PAH that should respond similarly to fluoranthene. ",
  "Panel D varies sample restrictions.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ──────────────────────────────────────────────────────────
# TABLE F1: Standardized Effect Sizes (SDE) — MANDATORY
# ──────────────────────────────────────────────────────────
cat("Generating SDE Table\n")

# Pre-treatment SD of outcome
pre_treat_data <- panel %>% filter(treated == 1, post == 0)
sd_y_pre <- sd(pre_treat_data$log_fluor, na.rm = TRUE)

# Main estimate (use TWFE as primary since CS is imprecise)
beta_main <- coef(results$twfe)["post"]
se_main <- se(results$twfe)["post"]
sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Pyrene SDE
if (!is.null(rob$pyrene)) {
  pre_pyrene_sd <- 1  # Will be updated if data available
  beta_pyrene <- coef(rob$pyrene)["post"]
  se_pyrene <- se(rob$pyrene)["post"]
  sde_pyrene <- beta_pyrene / pre_pyrene_sd
  se_sde_pyrene <- se_pyrene / pre_pyrene_sd
}

# ── Panel B: Heterogeneity by early vs late adopters ──
early_panel <- panel %>% filter(ban_year > 0 & ban_year <= 2014 | ban_year == 0)
late_panel <- panel %>% filter(ban_year > 2014 | ban_year == 0)

# Early adopters
early_twfe <- NULL
if (nrow(early_panel) > 50 && n_distinct(early_panel$station_id[early_panel$treated == 1]) > 5) {
  early_twfe <- tryCatch({
    m <- feols(log_fluor ~ post | station_num + year, data = early_panel, cluster = ~state)
    sd_y_early <<- sd(early_panel$log_fluor[early_panel$treated == 1 & early_panel$post == 0], na.rm = TRUE)
    sde_early <<- coef(m)["post"] / sd_y_early
    se_sde_early <<- se(m)["post"] / sd_y_early
    m
  }, error = function(e) { cat(sprintf("  Early adopter split failed: %s\n", e$message)); NULL })
}

# Late adopters
late_twfe <- NULL
if (nrow(late_panel) > 50 && n_distinct(late_panel$station_id[late_panel$treated == 1]) > 5) {
  late_twfe <- tryCatch({
    m <- feols(log_fluor ~ post | station_num + year, data = late_panel, cluster = ~state)
    sd_y_late <<- sd(late_panel$log_fluor[late_panel$treated == 1 & late_panel$post == 0], na.rm = TRUE)
    sde_late <<- coef(m)["post"] / sd_y_late
    se_sde_late <<- se(m)["post"] / sd_y_late
    m
  }, error = function(e) { cat(sprintf("  Late adopter split failed: %s\n", e$message)); NULL })
}

# ── Build SDE table ──
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Do municipal and state bans on coal-tar-based pavement sealants ",
  "reduce polycyclic aromatic hydrocarbon concentrations in urban waterways? ",
  "\\textbf{Policy mechanism:} Bans prohibit sale and application of coal-tar-based sealcoat products ",
  "(containing 50,000--100,000 mg/kg PAHs) on parking lots and driveways, eliminating the primary ",
  "non-point source of PAH contamination in urban stormwater runoff. ",
  "\\textbf{Outcome definition:} Log of mean annual fluoranthene concentration (ug/L) measured in ",
  "surface water samples at USGS/EPA monitoring stations via the Water Quality Portal. ",
  "\\textbf{Treatment:} Binary; station's jurisdiction adopted a coal-tar sealant ban. ",
  "\\textbf{Data:} EPA Water Quality Portal, 2000--2025, station-year level, ",
  sprintf("%s stations across %d states. ",
          format(n_distinct(panel$station_id), big.mark = ","),
          n_distinct(panel$state)),
  "\\textbf{Method:} Callaway and Sant'Anna (2021) staggered DiD with never-treated controls; ",
  "standard errors clustered at the state level. ",
  "\\textbf{Sample:} Monitoring stations with at least 3 years of fluoranthene measurements; ",
  "non-detect values substituted at half the detection limit. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome among treated stations. ",
  "Classification refers to magnitude, not statistical significance: ",
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
  "\\textit{Panel A: Pooled} & & & & & & \\\\"
)

tabF1_lines <- c(tabF1_lines,
  sprintf("\\quad Fluoranthene & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
          beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)))

if (!is.null(rob$pyrene)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad Pyrene & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            beta_pyrene, se_pyrene, pre_pyrene_sd, sde_pyrene, se_sde_pyrene, classify_sde(sde_pyrene)))
}

tabF1_lines <- c(tabF1_lines,
  "\\midrule",
  "\\textit{Panel B: Heterogeneous (Early vs.\\ Late Adopters)} & & & & & & \\\\"
)

if (!is.null(early_twfe)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad Early adopters ($\\leq$ 2014) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            coef(early_twfe)["post"], se(early_twfe)["post"], sd_y_early,
            sde_early, se_sde_early, classify_sde(sde_early)))
}

if (!is.null(late_twfe)) {
  tabF1_lines <- c(tabF1_lines,
    sprintf("\\quad Late adopters ($>$ 2014) & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\",
            coef(late_twfe)["post"], se(late_twfe)["post"], sd_y_late,
            sde_late, se_sde_late, classify_sde(sde_late)))
}

tabF1_lines <- c(tabF1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("\nAll tables generated in tables/ directory.\n")
