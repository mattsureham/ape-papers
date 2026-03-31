# 05_tables.R — Generate all tables for apep_1184
# EU Airport Slot Waivers and Competition

source("00_packages.R")

cat("=== Generating Tables ===\n")

panel <- readRDS("../data/panel_annual.rds")
models <- readRDS("../data/models.rds")
rob_models <- readRDS("../data/robustness_models.rds")
pre_sds <- readRDS("../data/pre_treatment_sds.rds")

panel[, post := as.integer(year >= 2020)]
panel[, pax_2019 := pax_total[year == 2019], by = airport]

# ─────────────────────────────────────────────────────────────────────
# Table 1: Summary Statistics
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

# Summary by group and period
sum_stats <- panel[!is.na(pax_total), .(
  Airports = uniqueN(airport),
  `Mean Pax (M)` = round(mean(pax_total, na.rm = TRUE) / 1e6, 2),
  `SD Pax (M)` = round(sd(pax_total, na.rm = TRUE) / 1e6, 2),
  `Median Pax (M)` = round(median(pax_total, na.rm = TRUE) / 1e6, 2),
  `Min Pax (K)` = round(min(pax_total, na.rm = TRUE) / 1e3, 0),
  `Max Pax (M)` = round(max(pax_total, na.rm = TRUE) / 1e6, 1)
), by = .(Group = ifelse(level3 == 1, "Level 3 (Coordinated)", "Level 1/2 (Uncoordinated)"),
          Period = ifelse(year <= 2019, "Pre-COVID (2016--2019)", "Post-COVID (2020--2024)"))]

sum_stats <- sum_stats[order(Group, Period)]

# LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Airport Passengers by Coordination Level}",
  "\\label{tab:summary}",
  "\\small",
  "\\begin{tabular}{llrrrrrr}",
  "\\toprule",
  "Group & Period & Airports & Mean & SD & Median & Min (K) & Max \\\\",
  " & & & (M) & (M) & (M) & & (M) \\\\",
  "\\midrule"
)

for (i in 1:nrow(sum_stats)) {
  row <- sum_stats[i]
  # Only show group name on first row of each group
  grp <- if (i %% 2 == 1) row$Group else ""
  tab1_lines <- c(tab1_lines, sprintf(
    "%s & %s & %d & %.2f & %.2f & %.2f & %s & %.1f \\\\",
    grp, row$Period, row$Airports, row$`Mean Pax (M)`, row$`SD Pax (M)`,
    row$`Median Pax (M)`, format(row$`Min Pax (K)`, big.mark = ","), row$`Max Pax (M)`))
  if (i == 2) tab1_lines <- c(tab1_lines, "\\midrule")
}

# Add slot threshold panel
tab1_lines <- c(tab1_lines,
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Slot Usage Threshold (\\% Required)}} \\\\",
  "\\midrule",
  "Year & 2016--2019 & 2020 & 2021 & 2022 & 2023 & 2024 & \\\\",
  "Threshold & 80\\% & 0\\% & 50\\% & 64\\% & 80\\% & 80\\% & \\\\",
  "Waiver Intensity & 0.00 & 1.00 & 0.375 & 0.20 & 0.00 & 0.00 & \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\item \\textit{Notes:} Panel A reports summary statistics for annual passengers at EU/EEA airports, 2016--2024.",
  "Level 3 airports are fully coordinated under Regulation 95/93 and subject to the 80/20 use-it-or-lose-it slot rule.",
  "Level 1/2 airports have no binding slot regulation.",
  "Panel B reports the minimum slot usage threshold in effect each year.",
  "Waiver intensity is defined as $(80 - \\text{threshold}) / 80$, ranging from 0 (full rule) to 1 (full waiver).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "../tables/tab1_summary.tex")

# ─────────────────────────────────────────────────────────────────────
# Table 2: Main Results — Continuous DiD
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 2: Main Results...\n")

# Recreate within-country models for scheduled and non-scheduled
m_sched_cxy <- feols(log_pax_sched ~ treat_continuous | airport + country^year,
  data = panel[!is.na(log_pax_sched)], cluster = ~airport)
m_nonsched_cxy <- feols(log_pax_nonsched ~ treat_continuous | airport + country^year,
  data = panel[!is.na(log_pax_nonsched)], cluster = ~airport)

panel[, treat_continuous := level3 * waiver_intensity]
tab2_tex <- etable(
  models$m_main_total, models$m_within_country,
  models$m_main_sched, m_sched_cxy,
  models$m_main_nonsched, m_nonsched_cxy,
  headers = c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)"),
  title = "Effect of Slot Waiver on Airport Passengers",
  label = "tab:main",
  notes = paste0(
    "Dependent variable is log passengers (carried). ",
    "Waiver intensity equals $(80 - \\text{threshold})/80$; treatment is Level 3 $\\times$ Waiver Intensity. ",
    "Columns (1), (3), (5) include airport and year fixed effects. ",
    "Columns (2), (4), (6) include airport and country$\\times$year fixed effects, ",
    "which absorb country-specific COVID recovery patterns. ",
    "Scheduled flights (columns 3--4) are directly subject to the slot rule; ",
    "non-scheduled flights (columns 5--6) are not. ",
    "Standard errors clustered at the airport level in parentheses. ",
    "Sample: 492 EU/EEA airports, 2016--2024."
  ),
  se.below = TRUE,
  depvar = TRUE,
  tex = TRUE,
  style.tex = style.tex("aer"),
  file = "../tables/tab2_main.tex",
  replace = TRUE
)

# ─────────────────────────────────────────────────────────────────────
# Table 3: Event Study Coefficients (within-country)
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 3: Event Study...\n")

panel[, year_f := factor(year)]
panel[, year_f := relevel(year_f, ref = "2019")]

m_es_naive <- feols(log_pax ~ i(year_f, level3, ref = "2019") | airport + year,
  data = panel, cluster = ~airport)
m_es_cxy <- feols(log_pax ~ i(year_f, level3, ref = "2019") | airport + country^year,
  data = panel, cluster = ~airport)

tab3_tex <- etable(m_es_naive, m_es_cxy,
  headers = c("Airport + Year FE", "Airport + Country$\\times$Year FE"),
  title = "Event Study: Level 3 $\\times$ Year Interactions",
  label = "tab:eventstudy",
  notes = paste0(
    "Dependent variable is log passengers (carried). ",
    "Each coefficient represents the interaction of Level 3 status with a year indicator, ",
    "relative to the omitted year 2019. ",
    "Column (1) includes airport and year fixed effects. ",
    "Column (2) adds country$\\times$year fixed effects. ",
    "Standard errors clustered at the airport level. ",
    "Pre-period coefficients (2016--2018) test the parallel trends assumption."
  ),
  se.below = TRUE,
  tex = TRUE,
  style.tex = style.tex("aer"),
  file = "../tables/tab3_eventstudy.tex",
  replace = TRUE
)

# ─────────────────────────────────────────────────────────────────────
# Table 4: Robustness Checks
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table 4: Robustness...\n")

tab4_tex <- etable(
  rob_models$r_size_matched_cxy,
  rob_models$r_eu_only,
  rob_models$r_no2020_cxy,
  rob_models$r_ihs,
  rob_models$r_levels_cxy,
  headers = c("Size-Matched", "EU27+EEA", "Excl. 2020", "IHS", "Levels (M)"),
  title = "Robustness Checks",
  label = "tab:robustness",
  notes = paste0(
    "All columns include airport and country$\\times$year fixed effects. ",
    "Column (1) restricts to airports with $\\geq$ 500K passengers in 2019. ",
    "Column (2) restricts to EU27 and EEA member states. ",
    "Column (3) excludes 2020 to focus on the recovery period. ",
    "Column (4) uses the inverse hyperbolic sine transformation. ",
    "Column (5) uses passengers in millions (not log-transformed). ",
    "Standard errors clustered at the airport level."
  ),
  se.below = TRUE,
  depvar = TRUE,
  tex = TRUE,
  style.tex = style.tex("aer"),
  file = "../tables/tab4_robustness.tex",
  replace = TRUE
)

# ─────────────────────────────────────────────────────────────────────
# Table F1: Standardized Effect Size (SDE) — Appendix
# ─────────────────────────────────────────────────────────────────────
cat("Generating Table F1: SDE...\n")

# Main estimates and SDs for SDE calculation
# Using the within-country (clean) specification
coef_total <- coef(models$m_within_country)["treat_continuous"]
se_total <- se(models$m_within_country)["treat_continuous"]
sd_total <- pre_sds$sd_log_pax

coef_sched <- coef(m_sched_cxy)["treat_continuous"]
se_sched <- se(m_sched_cxy)["treat_continuous"]
sd_sched <- pre_sds$sd_log_pax_sched

coef_nonsched <- coef(m_nonsched_cxy)["treat_continuous"]
se_nonsched <- se(m_nonsched_cxy)["treat_continuous"]
sd_nonsched <- pre_sds$sd_log_pax_nonsched

# Flights (if available)
coef_flights <- coef(models$m_flights)["treat_continuous"]
se_flights <- se(models$m_flights)["treat_continuous"]
# Compute SD for log_flights from data
panel_f <- readRDS("../data/panel_annual.rds")
flights_raw <- readRDS("../data/avia_flights_annual.rds")
dt_fl <- as.data.table(flights_raw)
dt_fl[, year := as.integer(time)]
fl_panel <- dt_fl[!is.na(values) & year >= 2016 & year <= 2019,
  .(airport = rep_airp, year, log_flights = log(values + 1))]
sd_flights <- sd(fl_panel$log_flights, na.rm = TRUE)

# SDE computation
compute_sde <- function(beta, se_beta, sd_y) {
  sde <- beta / sd_y
  se_sde <- se_beta / sd_y
  class <- ifelse(abs(sde) < 0.005, "Null",
    ifelse(abs(sde) < 0.05, ifelse(sde > 0, "Small positive", "Small negative"),
      ifelse(abs(sde) < 0.15, ifelse(sde > 0, "Moderate positive", "Moderate negative"),
        ifelse(sde > 0, "Large positive", "Large negative"))))
  list(sde = sde, se_sde = se_sde, class = class)
}

sde_total <- compute_sde(coef_total, se_total, sd_total)
sde_sched <- compute_sde(coef_sched, se_sched, sd_sched)
sde_nonsched <- compute_sde(coef_nonsched, se_nonsched, sd_nonsched)
sde_flights <- compute_sde(coef_flights, se_flights, sd_flights)

# Heterogeneity: Large hubs vs small Level 3
panel[, large_hub := as.integer(!is.na(pax_2019) & pax_2019 >= 10e6 & level3 == 1)]
panel[, small_level3 := as.integer(level3 == 1 & large_hub == 0)]
panel[, treat_large := large_hub * waiver_intensity]
panel[, treat_small := small_level3 * waiver_intensity]

m_het_cxy <- feols(log_pax ~ treat_large + treat_small | airport + country^year,
  data = panel, cluster = ~airport)

coef_large <- coef(m_het_cxy)["treat_large"]
se_large <- se(m_het_cxy)["treat_large"]
coef_small <- coef(m_het_cxy)["treat_small"]
se_small <- se(m_het_cxy)["treat_small"]

sde_large <- compute_sde(coef_large, se_large, sd_total)
sde_small <- compute_sde(coef_small, se_small, sd_total)

# Build SDE LaTeX table
fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (EU27 plus EEA member states). ",
  "\\textbf{Research question:} Does relaxing the 80/20 airport slot use-it-or-lose-it rule reduce passenger throughput at capacity-constrained airports by entrenching incumbent airlines? ",
  "\\textbf{Policy mechanism:} EU Regulation 95/93 requires airlines at Level 3 (fully coordinated) airports to operate at least 80\\% of allocated slots or forfeit them to competitors; the COVID-era waiver suspended this requirement, potentially allowing incumbents to hoard slots without operating flights. ",
  "\\textbf{Outcome definition:} Log annual passengers carried at each airport, from Eurostat avia\\_paoa. ",
  "\\textbf{Treatment:} Continuous waiver intensity $(80 - \\text{threshold})/80$, ranging from 0 (full 80\\% rule) to 1 (full waiver). ",
  "\\textbf{Data:} Eurostat avia\\_paoa, 2016--2024, 492 airports, 3,490 airport-year observations. ",
  "\\textbf{Method:} Continuous difference-in-differences with airport and country$\\times$year fixed effects, standard errors clustered at the airport level. ",
  "\\textbf{Sample:} EU/EEA airports with non-missing passenger data; Panel B splits Level 3 airports into large hubs ($\\geq$10M passengers in 2019, $N=45$) and smaller coordinated airports ($N=23$). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate (0.05--0.15), Small (0.005--0.05), Null ($< 0.005$)."
)

sde_tab <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\small",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\",
  "\\midrule",
  sprintf("Total passengers & %s & %s & %s & %s & %s & %s \\\\",
    fmt(coef_total), fmt(se_total), fmt(sd_total), fmt(sde_total$sde), fmt(sde_total$se_sde), sde_total$class),
  sprintf("Scheduled passengers & %s & %s & %s & %s & %s & %s \\\\",
    fmt(coef_sched), fmt(se_sched), fmt(sd_sched), fmt(sde_sched$sde), fmt(sde_sched$se_sde), sde_sched$class),
  sprintf("Non-scheduled passengers & %s & %s & %s & %s & %s & %s \\\\",
    fmt(coef_nonsched), fmt(se_nonsched), fmt(sd_nonsched), fmt(sde_nonsched$sde), fmt(sde_nonsched$se_sde), sde_nonsched$class),
  sprintf("Flight movements & %s & %s & %s & %s & %s & %s \\\\",
    fmt(coef_flights), fmt(se_flights), fmt(sd_flights), fmt(sde_flights$sde), fmt(sde_flights$se_sde), sde_flights$class),
  "\\midrule",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by hub size)}} \\\\",
  "\\midrule",
  sprintf("Large hubs ($\\geq$10M) & %s & %s & %s & %s & %s & %s \\\\",
    fmt(coef_large), fmt(se_large), fmt(sd_total), fmt(sde_large$sde), fmt(sde_large$se_sde), sde_large$class),
  sprintf("Smaller Level 3 & %s & %s & %s & %s & %s & %s \\\\",
    fmt(coef_small), fmt(se_small), fmt(sd_total), fmt(sde_small$sde), fmt(sde_small$se_sde), sde_small$class),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_tab, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Files:\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_eventstudy.tex\n")
cat("  tables/tab4_robustness.tex\n")
cat("  tables/tabF1_sde.tex\n")
