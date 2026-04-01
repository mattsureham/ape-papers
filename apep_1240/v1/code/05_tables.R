## ── 05_tables.R ────────────────────────────────────────────────
## Generate all tables for the paper

source("00_packages.R")

data_dir <- "../data"
table_dir <- "../tables"
dir.create(table_dir, showWarnings = FALSE)

wells_long <- fread(file.path(data_dir, "wells_long_clean.csv"))
district_panel <- fread(file.path(data_dir, "district_panel_clean.csv"))
assessment_data <- fread(file.path(data_dir, "assessment_rounds.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

## ── Table 1: Summary Statistics ─────────────────────────────────
cat("=== Table 1: Summary Statistics ===\n")

# Well-level stats by treatment group
wells_annual <- wells_long[, .(
  mean_depth = mean(depth_to_water, na.rm = TRUE)
), by = .(WLCODE, STATE, DISTRICT, year, treated, post, treat_post)]
setorder(wells_annual, WLCODE, year)
wells_annual[, delta_depth := mean_depth - shift(mean_depth, 1), by = WLCODE]

sumstats <- rbind(
  # Panel A: Full sample
  data.table(
    panel = "Full sample",
    variable = c("Depth to water (m)", "Annual change (m/yr)",
                 "Wells", "Districts", "States", "Years"),
    value = c(
      sprintf("%.2f", mean(wells_long$depth_to_water, na.rm = TRUE)),
      sprintf("%.3f", mean(wells_annual$delta_depth, na.rm = TRUE)),
      format(uniqueN(wells_long$WLCODE), big.mark = ","),
      format(uniqueN(wells_long[, paste(STATE, DISTRICT)]), big.mark = ","),
      as.character(uniqueN(wells_long$STATE)),
      as.character(uniqueN(wells_long$year))
    ),
    sd = c(
      sprintf("[%.2f]", sd(wells_long$depth_to_water, na.rm = TRUE)),
      sprintf("[%.3f]", sd(wells_annual$delta_depth, na.rm = TRUE)),
      "", "", "", ""
    )
  ),
  # Panel B: Treated states
  data.table(
    panel = "Treated states",
    variable = c("Depth to water (m)", "Annual change (m/yr)",
                 "OE share (2013)", "Wells"),
    value = c(
      sprintf("%.2f", mean(wells_long[treated == TRUE, depth_to_water], na.rm = TRUE)),
      sprintf("%.3f", mean(wells_annual[treated == TRUE, delta_depth], na.rm = TRUE)),
      sprintf("%.3f", mean(assessment_data[round == 2013 &
        state_code %in% wells_long[treated == TRUE, unique(STATE)], oe_share])),
      format(uniqueN(wells_long[treated == TRUE, WLCODE]), big.mark = ",")
    ),
    sd = c(
      sprintf("[%.2f]", sd(wells_long[treated == TRUE, depth_to_water], na.rm = TRUE)),
      sprintf("[%.3f]", sd(wells_annual[treated == TRUE, delta_depth], na.rm = TRUE)),
      "", ""
    )
  ),
  # Panel C: Control states
  data.table(
    panel = "Control states",
    variable = c("Depth to water (m)", "Annual change (m/yr)",
                 "OE share (2013)", "Wells"),
    value = c(
      sprintf("%.2f", mean(wells_long[treated == FALSE, depth_to_water], na.rm = TRUE)),
      sprintf("%.3f", mean(wells_annual[treated == FALSE, delta_depth], na.rm = TRUE)),
      sprintf("%.3f", mean(assessment_data[round == 2013 &
        state_code %in% wells_long[treated == FALSE, unique(STATE)], oe_share])),
      format(uniqueN(wells_long[treated == FALSE, WLCODE]), big.mark = ",")
    ),
    sd = c(
      sprintf("[%.2f]", sd(wells_long[treated == FALSE, depth_to_water], na.rm = TRUE)),
      sprintf("[%.3f]", sd(wells_annual[treated == FALSE, delta_depth], na.rm = TRUE)),
      "", ""
    )
  )
)

# Write LaTeX
sink(file.path(table_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics: Groundwater Monitoring Wells, 1996--2017}\n")
cat("\\label{tab:summary}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcc}\n")
cat("\\toprule\n")
cat("& Mean & SD \\\\\n")
cat("\\midrule\n")

for (p in unique(sumstats$panel)) {
  cat(sprintf("\\multicolumn{3}{l}{\\textit{%s}} \\\\\n", p))
  sub <- sumstats[panel == p]
  for (i in 1:nrow(sub)) {
    cat(sprintf("\\quad %s & %s & %s \\\\\n",
                sub$variable[i], sub$value[i], sub$sd[i]))
  }
  if (p != tail(unique(sumstats$panel), 1)) cat("\\addlinespace\n")
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Data from CGWB quarterly monitoring wells (craigdsouza/cgwb).\n")
cat("Depth to water measured in meters below ground level; higher values indicate\n")
cat("greater depletion. Annual change computed as year-over-year difference in\n")
cat("well-level annual mean depth. Treated states are those where the share of\n")
cat("overexploited blocks exceeded 15\\% by the 2013 CGWB assessment round\n")
cat("(Rajasthan, Punjab, Haryana, Tamil Nadu, Karnataka). Standard deviations\n")
cat("in brackets.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ── Table 2: Main Results ───────────────────────────────────────
cat("=== Table 2: Main Results ===\n")

# Recreate depletion rate regression for table
wells_annual2 <- wells_long[, .(
  mean_depth = mean(depth_to_water, na.rm = TRUE)
), by = .(WLCODE, STATE, DISTRICT, year, oe_share, treated, post,
          treat_post, first_high_round)]
setorder(wells_annual2, WLCODE, year)
wells_annual2[, delta_depth := mean_depth - shift(mean_depth, 1), by = WLCODE]

# Column 1: Well-level TWFE (levels)
fit_c1 <- results$well_level

# Column 2: District-level TWFE (levels)
fit_c2 <- results$twfe_bin

# Column 3: Well-level depletion rate
fit_c3 <- results$depletion_rate

# Column 4: Continuous treatment (oe_share) — levels
fit_c4 <- results$well_cont

# Column 5: Continuous treatment — district level
fit_c5 <- results$twfe_cont

# Build table manually for precise control
sink(file.path(table_dir, "tab2_main.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Effect of Overexploitation Classification on Groundwater Depth}\n")
cat("\\label{tab:main}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat("& \\multicolumn{3}{c}{Binary Treatment} & \\multicolumn{2}{c}{Continuous Treatment} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}\n")
cat("& (1) & (2) & (3) & (4) & (5) \\\\\n")
cat("& Well level & District & $\\Delta$ Depth & Well level & District \\\\\n")
cat("\\midrule\n")

# Row 1: Treatment coefficient
cat(sprintf("Treated $\\times$ Post & %s & %s & %s & & \\\\\n",
  sprintf("%.3f", coef(fit_c1)),
  sprintf("%.3f", coef(fit_c2)),
  sprintf("%.3f", coef(fit_c3))))
cat(sprintf("& (%s) & (%s) & (%s) & & \\\\\n",
  sprintf("%.3f", se(fit_c1)),
  sprintf("%.3f", se(fit_c2)),
  sprintf("%.3f", se(fit_c3))))

cat("\\addlinespace\n")

# Row 2: Continuous treatment
cat(sprintf("OE Share & & & & %s & %s \\\\\n",
  sprintf("%.3f", coef(fit_c4)),
  sprintf("%.3f", coef(fit_c5))))
cat(sprintf("& & & & (%s) & (%s) \\\\\n",
  sprintf("%.3f", se(fit_c4)),
  sprintf("%.3f", se(fit_c5))))

cat("\\addlinespace\n")
cat("\\midrule\n")

# Fixed effects
cat("Well FE & Yes & & Yes & Yes & \\\\\n")
cat("District FE & & Yes & & & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes & Yes \\\\\n")

cat("\\addlinespace\n")

# Sample info
cat(sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
  format(nobs(fit_c1), big.mark = ","),
  format(nobs(fit_c2), big.mark = ","),
  format(nobs(fit_c3), big.mark = ","),
  format(nobs(fit_c4), big.mark = ","),
  format(nobs(fit_c5), big.mark = ",")))

cat(sprintf("Clusters (states) & %d & %d & %d & %d & %d \\\\\n",
  length(unique(wells_long$STATE)),
  length(unique(district_panel$STATE)),
  length(unique(wells_long$STATE)),
  length(unique(wells_long[!is.na(oe_share), STATE])),
  length(unique(district_panel[!is.na(oe_share), STATE]))))

cat(sprintf("Dep. var. mean & %.2f & %.2f & %.3f & %.2f & %.2f \\\\\n",
  mean(wells_long$depth_to_water, na.rm = TRUE),
  mean(district_panel$mean_depth, na.rm = TRUE),
  mean(wells_annual2$delta_depth, na.rm = TRUE),
  mean(wells_long[!is.na(oe_share), depth_to_water], na.rm = TRUE),
  mean(district_panel[!is.na(oe_share), mean_depth], na.rm = TRUE)))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Columns (1)--(3) use binary treatment: an indicator for\n")
cat("states where $>$15\\% of CGWB assessment blocks are classified as overexploited\n")
cat("by the relevant assessment round, interacted with a post-classification indicator.\n")
cat("Columns (4)--(5) use the continuous share of overexploited blocks in each state.\n")
cat("Column (3) uses the annual change in depth (depletion rate) as the outcome.\n")
cat("Standard errors clustered at the state level in parentheses.\n")
cat("\\sym{*} $p<0.1$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ── Table 3: Robustness Checks ──────────────────────────────────
cat("=== Table 3: Robustness ===\n")

# Compile robustness results
rob_tab <- data.table(
  specification = c(
    "Main: well-level TWFE",
    "Surge states (>5pp $\\Delta$OE)",
    "Adjacent-state pairs only",
    "Pre-monsoon (Q2) only",
    "Post-monsoon (Q4) only",
    "Placebo: 2000 timing (pre-2004 only)"
  ),
  coef = c(
    coef(results$well_level),
    coef(rob_results$surge),
    coef(rob_results$adjacent),
    coef(rob_results$premonsoon),
    coef(rob_results$postmonsoon),
    coef(rob_results$placebo)
  ),
  se = c(
    se(results$well_level),
    se(rob_results$surge),
    se(rob_results$adjacent),
    se(rob_results$premonsoon),
    se(rob_results$postmonsoon),
    se(rob_results$placebo)
  ),
  pval = c(
    pvalue(results$well_level),
    pvalue(rob_results$surge),
    pvalue(rob_results$adjacent),
    pvalue(rob_results$premonsoon),
    pvalue(rob_results$postmonsoon),
    pvalue(rob_results$placebo)
  ),
  nobs = c(
    nobs(results$well_level),
    nobs(rob_results$surge),
    nobs(rob_results$adjacent),
    nobs(rob_results$premonsoon),
    nobs(rob_results$postmonsoon),
    nobs(rob_results$placebo)
  )
)

# Add significance stars
rob_tab[, stars := fifelse(pval < 0.01, "***",
                  fifelse(pval < 0.05, "**",
                  fifelse(pval < 0.1, "*", "")))]

sink(file.path(table_dir, "tab3_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness: Alternative Specifications and Samples}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\toprule\n")
cat("Specification & Coefficient & SE & $p$-value & $N$ \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(rob_tab)) {
  cat(sprintf("%s & %s%s & (%s) & [%s] & %s \\\\\n",
    rob_tab$specification[i],
    sprintf("%.3f", rob_tab$coef[i]),
    rob_tab$stars[i],
    sprintf("%.3f", rob_tab$se[i]),
    sprintf("%.3f", rob_tab$pval[i]),
    format(rob_tab$nobs[i], big.mark = ",")))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} All specifications include well and year fixed effects\n")
cat("with standard errors clustered at the state level. The dependent variable is\n")
cat("depth to water (meters below ground level). Surge states are those with\n")
cat("$>$5 percentage-point increase in overexploited block share between the 2004\n")
cat("and 2013 CGWB assessment rounds. Adjacent-state pairs restrict the sample to\n")
cat("geographic neighbors of treated states. The placebo test applies a fake\n")
cat("treatment date of 2000 using only pre-2004 data.\n")
cat("\\sym{*} $p<0.1$, \\sym{**} $p<0.05$, \\sym{***} $p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ── Table 4: Assessment Round Classification ────────────────────
cat("=== Table 4: Assessment Rounds ===\n")

# Show the expansion of overexploited blocks across rounds
assessment_display <- dcast(assessment_data[state_code %in%
  c("RJ", "PB", "HR", "TN", "KA", "GJ", "MP", "UP", "AP", "TG")],
  state_code + n_total_blocks ~ round,
  value.var = "n_overexploited")

# Map state codes to names
state_names <- c(
  RJ = "Rajasthan", PB = "Punjab", HR = "Haryana", TN = "Tamil Nadu",
  KA = "Karnataka", GJ = "Gujarat", MP = "Madhya Pradesh",
  UP = "Uttar Pradesh", AP = "Andhra Pradesh", TG = "Telangana"
)
assessment_display[, State := state_names[state_code]]
setorder(assessment_display, -`2013`)

sink(file.path(table_dir, "tab4_assessment.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Overexploited Blocks by State and CGWB Assessment Round}\n")
cat("\\label{tab:assessment}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("State & Total & \\multicolumn{5}{c}{Overexploited Blocks} \\\\\n")
cat("\\cmidrule(lr){3-7}\n")
cat("& Blocks & 2004 & 2009 & 2011 & 2013 & 2017 \\\\\n")
cat("\\midrule\n")

for (i in 1:nrow(assessment_display)) {
  row <- assessment_display[i]
  cat(sprintf("%s & %d & %d & %d & %d & %d & %d \\\\\n",
    row$State, row$n_total_blocks,
    row$`2004`, row$`2009`, row$`2011`, row$`2013`, row$`2017`))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Number of assessment blocks classified as\n")
cat("``overexploited'' (groundwater extraction $>$ 100\\% of recharge) by CGWB\n")
cat("Dynamic Ground Water Resources assessments. Telangana was created from\n")
cat("Andhra Pradesh in 2014; its 2017 count reflects blocks previously counted\n")
cat("under Andhra Pradesh. Only states with $\\geq$15 overexploited blocks shown.\n")
cat("Source: CGWB Dynamic Ground Water Resources of India reports.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

## ── Table F1: SDE Appendix (MANDATORY) ──────────────────────────
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Compute SDEs for main outcomes
# Use pre-treatment SD (pre-2004 for first-treated cohort)
pre_sd_depth <- sd(wells_long[year < 2004, depth_to_water], na.rm = TRUE)
pre_sd_delta <- sd(wells_annual2[year < 2004 & !is.na(delta_depth), delta_depth], na.rm = TRUE)

# SDE = beta / SD(Y)
sde_data <- data.table(
  outcome = c(
    "Depth to water (m)",
    "Depth to water (m)",
    "Annual change in depth (m/yr)"
  ),
  panel = c("A", "A", "A"),
  beta = c(
    coef(results$well_level),
    coef(results$well_cont),
    coef(results$depletion_rate)
  ),
  se_beta = c(
    se(results$well_level),
    se(results$well_cont),
    se(results$depletion_rate)
  ),
  sd_y = c(pre_sd_depth, pre_sd_depth, pre_sd_delta),
  treatment = c("Binary", "Continuous (OE share)", "Binary")
)

sde_data[, sde := beta / sd_y]
sde_data[, se_sde := se_beta / sd_y]

# Classification
sde_data[, classification := fifelse(
  abs(sde) < 0.005, "Null",
  fifelse(abs(sde) < 0.05,
    fifelse(sde > 0, "Small positive", "Small negative"),
    fifelse(abs(sde) < 0.15,
      fifelse(sde > 0, "Moderate positive", "Moderate negative"),
      fifelse(sde > 0, "Large positive", "Large negative"))))]

# Panel B: Heterogeneous (by well type)
wells_annual_type <- wells_long[, .(
  mean_depth = mean(depth_to_water, na.rm = TRUE)
), by = .(WLCODE, STATE, SITE_TYPE, year, treated, post, treat_post)]
setorder(wells_annual_type, WLCODE, year)
wells_annual_type[, delta_depth := mean_depth - shift(mean_depth, 1), by = WLCODE]

# Dug wells vs bore wells
fit_dug <- feols(depth_to_water ~ treat_post | WLCODE + year,
                 data = wells_long[SITE_TYPE == "Dug Well"],
                 cluster = ~STATE)
fit_bore <- feols(depth_to_water ~ treat_post | WLCODE + year,
                  data = wells_long[SITE_TYPE == "Bore Well"],
                  cluster = ~STATE)

sde_hetero <- data.table(
  outcome = c("Depth: Dug wells", "Depth: Bore wells"),
  panel = c("B", "B"),
  beta = c(coef(fit_dug), coef(fit_bore)),
  se_beta = c(se(fit_dug), se(fit_bore)),
  sd_y = c(
    sd(wells_long[SITE_TYPE == "Dug Well" & year < 2004, depth_to_water], na.rm = TRUE),
    sd(wells_long[SITE_TYPE == "Bore Well" & year < 2004, depth_to_water], na.rm = TRUE)
  ),
  treatment = c("Binary", "Binary")
)
sde_hetero[, sde := beta / sd_y]
sde_hetero[, se_sde := se_beta / sd_y]
sde_hetero[, classification := fifelse(
  abs(sde) < 0.005, "Null",
  fifelse(abs(sde) < 0.05,
    fifelse(sde > 0, "Small positive", "Small negative"),
    fifelse(abs(sde) < 0.15,
      fifelse(sde > 0, "Moderate positive", "Moderate negative"),
      fifelse(sde > 0, "Large positive", "Large negative"))))]

sde_all <- rbind(sde_data, sde_hetero)

# Write SDE table
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does formal classification of groundwater blocks as ",
  "overexploited by the Central Ground Water Board reduce groundwater depletion rates? ",
  "\\textbf{Policy mechanism:} CGWB assessment rounds (2004, 2009, 2011, 2013, 2017) ",
  "classify blocks by extraction-to-recharge ratio; overexploited blocks ($>$100\\%) ",
  "trigger mandatory No-Objection Certificate requirements for non-drinking extraction, ",
  "enforced by the Central Ground Water Authority. ",
  "\\textbf{Outcome definition:} Depth to water in meters below ground level measured ",
  "at CGWB quarterly monitoring wells; higher values indicate greater depletion. ",
  "Annual change computed as year-over-year difference in well-level mean depth. ",
  "\\textbf{Treatment:} Binary indicator for states exceeding 15\\% overexploited block ",
  "share by the relevant assessment round, or continuous state-level overexploited share. ",
  "\\textbf{Data:} CGWB monitoring wells (craigdsouza/cgwb), 1996--2017, quarterly, ",
  "28,074 wells across 24 states, 964,117 well-quarter observations. ",
  "\\textbf{Method:} TWFE difference-in-differences with well and year fixed effects; ",
  "standard errors clustered at the state level (24 clusters). ",
  "\\textbf{Sample:} All CGWB monitoring wells with non-missing depth readings; ",
  "extreme values ($<$-5m or $>$200m) excluded as measurement error. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

sink(file.path(table_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")

for (i in which(sde_all$panel == "A")) {
  row <- sde_all[i]
  cat(sprintf("\\quad %s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
    row$outcome, row$beta, row$se_beta, row$sd_y,
    row$sde, row$se_sde, row$classification))
}

cat("\\addlinespace\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: By well type}} \\\\\n")

for (i in which(sde_all$panel == "B")) {
  row <- sde_all[i]
  cat(sprintf("\\quad %s & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\\n",
    row$outcome, row$beta, row$se_beta, row$sd_y,
    row$sde, row$se_sde, row$classification))
}

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("\n=== All tables generated ===\n")
cat("Files in", table_dir, ":\n")
print(list.files(table_dir))
