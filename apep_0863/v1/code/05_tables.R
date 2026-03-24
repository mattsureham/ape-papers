## 05_tables.R — Generate all LaTeX tables
## apep_0863: The Forecaster Lottery

library(data.table)
library(fixest)
library(modelsummary)
library(kableExtra)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

dir.create("tables", showWarnings = FALSE)

analysis <- fread("data/analysis_tornado_pairs.csv")
analysis <- analysis[!is.na(avg_lt_overall) & !is.na(pair_id)]
analysis[, ef_sq := ef_scale^2]
analysis[, log_pop := log(population + 1)]
analysis[, log_damage := log(damage_property + 1)]
analysis[, any_casualty := as.integer(casualties > 0)]
analysis[, strong_tornado := as.integer(ef_scale >= 2)]

wfo_avg <- fread("data/wfo_averages.csv")


## ============================================================
## Table 1: Summary Statistics
## ============================================================

cat("Generating Table 1: Summary Statistics...\n")

# Panel A: Tornado events
# Fix EF-scale: SPC uses -9 or negative for unknown; set to NA
analysis[ef_scale < 0, ef_scale := NA_integer_]

# Property damage: SPC reports in millions; ensure sensible units
# Cap extreme values for summary stats display
dmg_millions <- analysis$damage_property  # Already in SPC units
# If values look like raw dollars, convert
if (median(dmg_millions, na.rm = TRUE) > 1000) {
  dmg_millions <- dmg_millions / 1e6  # Convert to millions
}

stats_tornado <- data.table(
  Variable = c("Casualties per event", "Injuries per event", "Deaths per event",
               "Any casualty (0/1)",
               "EF-scale (0--5)", "Path length (miles)",
               "Path width (yards)"),
  Mean = c(mean(analysis$casualties, na.rm = TRUE),
           mean(analysis$injuries, na.rm = TRUE),
           mean(analysis$deaths, na.rm = TRUE),
           mean(analysis$any_casualty, na.rm = TRUE),
           mean(analysis$ef_scale, na.rm = TRUE),
           mean(analysis$path_length, na.rm = TRUE),
           mean(analysis$path_width, na.rm = TRUE)),
  SD = c(sd(analysis$casualties, na.rm = TRUE),
         sd(analysis$injuries, na.rm = TRUE),
         sd(analysis$deaths, na.rm = TRUE),
         sd(analysis$any_casualty, na.rm = TRUE),
         sd(analysis$ef_scale, na.rm = TRUE),
         sd(analysis$path_length, na.rm = TRUE),
         sd(analysis$path_width, na.rm = TRUE)),
  N = rep(nrow(analysis), 7)
)

# Panel B: WFO performance
stats_wfo <- data.table(
  Variable = c("Average lead time (min)", "Probability of detection",
               "False alarm ratio", "Critical success index",
               "Total verified events"),
  Mean = c(mean(wfo_avg$avg_lt_overall, na.rm = TRUE),
           mean(wfo_avg$avg_pod_overall, na.rm = TRUE),
           mean(wfo_avg$avg_far_overall, na.rm = TRUE),
           mean(wfo_avg$avg_csi_overall, na.rm = TRUE),
           mean(wfo_avg$total_events, na.rm = TRUE)),
  SD = c(sd(wfo_avg$avg_lt_overall, na.rm = TRUE),
         sd(wfo_avg$avg_pod_overall, na.rm = TRUE),
         sd(wfo_avg$avg_far_overall, na.rm = TRUE),
         sd(wfo_avg$avg_csi_overall, na.rm = TRUE),
         sd(wfo_avg$total_events, na.rm = TRUE)),
  N = rep(nrow(wfo_avg), 5)
)

# Format numbers
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d, big.mark = ",")

# Write LaTeX table
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  "& Mean & SD & $N$ \\\\",
  "\\hline",
  "\\multicolumn{4}{l}{\\textit{Panel A: Tornado Events (2008--2024)}} \\\\[3pt]"
)

for (i in 1:nrow(stats_tornado)) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s \\\\",
    stats_tornado$Variable[i], fmt(stats_tornado$Mean[i]),
    fmt(stats_tornado$SD[i]), format(stats_tornado$N[i], big.mark = ",")))
}

tab1_lines <- c(tab1_lines,
  "\\\\",
  "\\multicolumn{4}{l}{\\textit{Panel B: WFO Performance (106 offices)}} \\\\[3pt]"
)

for (i in 1:nrow(stats_wfo)) {
  tab1_lines <- c(tab1_lines, sprintf("%s & %s & %s & %s \\\\",
    stats_wfo$Variable[i], fmt(stats_wfo$Mean[i]),
    fmt(stats_wfo$SD[i]), format(stats_wfo$N[i], big.mark = ",")))
}

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  "\\item \\textit{Notes:} Panel A reports tornado-event-level statistics for the boundary-pair analysis sample.",
  "Each tornado appears once per boundary pair its county belongs to.",
  "Panel B reports Weather Forecast Office (WFO) performance metrics from the Iowa Environmental Mesonet",
  "verification database, averaged over 2008--2024. Lead time is the average minutes between warning issuance",
  "and tornado touchdown. POD is the fraction of tornadoes that received a warning. FAR is the fraction of",
  "warnings not verified by a tornado. CSI combines POD and FAR: CSI = hits / (hits + misses + false alarms).",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")


## ============================================================
## Table 2: Primary Results — Lead Time and Casualties
## ============================================================

cat("Generating Table 2: Primary Results...\n")

m1 <- feols(casualties ~ avg_lt_overall | 0,
            data = analysis, cluster = ~wfo + year)
m2 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | 0,
            data = analysis, cluster = ~wfo + year)
m3 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id,
            data = analysis, cluster = ~wfo + year)
m4 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
            data = analysis, cluster = ~wfo + year)
m5 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width + log_pop | pair_id + year,
            data = analysis, cluster = ~wfo + year)

dict_vars <- c(
  avg_lt_overall = "Avg. lead time (min)",
  ef_scale = "EF-scale",
  ef_sq = "EF-scale$^2$",
  path_length = "Path length (mi)",
  path_width = "Path width (yd)",
  log_pop = "Log population"
)

etable(m1, m2, m3, m4, m5,
       dict = dict_vars,
       keep = c("%avg_lt_overall", "%ef_scale", "%path_length", "%log_pop"),
       order = c("%avg_lt_overall"),
       fixef.group = list("Boundary-pair FE" = "pair_id", "Year FE" = "year"),
       se.below = TRUE,
       depvar = FALSE,
       title = "WFO Lead Time and Tornado Casualties: Boundary-Pair Design",
       label = "tab:main",
       notes = paste0("Each observation is a tornado event x boundary pair. ",
                      "Dependent variable: total casualties (injuries + deaths). ",
                      "Lead time: WFO-level mean minutes between warning and touchdown, 2008-2024. ",
                      "SE clustered by WFO and year. ",
                      "Tornado controls: EF-scale, EF-scale squared, path length, path width."),
       style.tex = style.tex("aer"),
       file = "tables/tab2_main.tex",
       replace = TRUE)


## ============================================================
## Table 3: Outcome Decomposition and Placebos
## ============================================================

cat("Generating Table 3: Outcomes & Placebos...\n")

m_cas <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
m_inj <- feols(injuries ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
m_dth <- feols(deaths ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
m_any <- feols(any_casualty ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
m_dam <- feols(log_damage ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)

etable(m_cas, m_inj, m_dth, m_any, m_dam,
       dict = c(dict_vars,
                casualties = "Casualties", injuries = "Injuries", deaths = "Deaths",
                any_casualty = "Any casualty", log_damage = "Log damage"),
       keep = "%avg_lt_overall",
       headers = c("Casualties", "Injuries", "Deaths", "Any casualty", "Log damage"),
       fixef.group = list("Pair + Year FE" = "pair_id|year"),
       se.below = TRUE,
       title = "Outcome Decomposition and Placebo Tests",
       label = "tab:outcomes",
       notes = paste0("Columns 1-4: human casualty outcomes. ",
                      "Column 5: placebo (property damage cannot be prevented by warnings). ",
                      "All include boundary-pair and year FE with tornado controls. ",
                      "SE clustered by WFO and year."),
       style.tex = style.tex("aer"),
       file = "tables/tab3_outcomes.tex",
       replace = TRUE)


## ============================================================
## Table 4: Mechanism — FAR and CSI
## ============================================================

cat("Generating Table 4: FAR Mechanism...\n")

# Test whether FAR mediates the lead time → casualty relationship
m_far <- feols(casualties ~ avg_far_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
m_csi <- feols(casualties ~ avg_csi_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
m_both <- feols(casualties ~ avg_lt_overall + avg_far_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                data = analysis, cluster = ~wfo + year)
m_pod <- feols(casualties ~ avg_pod_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)

dict_mech <- c(dict_vars,
               avg_far_overall = "False alarm ratio",
               avg_csi_overall = "Critical success index",
               avg_pod_overall = "Probability of detection")

etable(m4, m_far, m_both, m_pod, m_csi,
       dict = dict_mech,
       keep = c("%avg_lt_overall", "%avg_far_overall", "%avg_pod_overall", "%avg_csi_overall"),
       fixef.group = list("Pair + Year FE" = "pair_id|year"),
       se.below = TRUE,
       depvar = FALSE,
       title = "The Warning Paradox: Lead Time, False Alarms, and Casualties",
       label = "tab:mechanism",
       notes = paste0("All include boundary-pair and year FE with tornado controls. ",
                      "FAR: fraction of warnings not verified. ",
                      "CSI = hits / (hits + misses + false alarms). ",
                      "Column 3: lead time and FAR simultaneously. ",
                      "SE clustered by WFO and year."),
       style.tex = style.tex("aer"),
       file = "tables/tab4_mechanism.tex",
       replace = TRUE)


## ============================================================
## Table 5: Heterogeneity — EF-scale and Mobile Homes
## ============================================================

cat("Generating Table 5: Heterogeneity...\n")

analysis[, high_mobile := as.integer(mobile_share > median(mobile_share, na.rm = TRUE))]

m_ef01 <- feols(casualties ~ avg_lt_overall + ef_scale + path_length + path_width | pair_id + year,
                data = analysis[ef_scale <= 1], cluster = ~wfo + year)
m_ef2p <- feols(casualties ~ avg_lt_overall + ef_scale + path_length + path_width | pair_id + year,
                data = analysis[ef_scale >= 2], cluster = ~wfo + year)
m_mob_lo <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                  data = analysis[high_mobile == 0], cluster = ~wfo + year)
m_mob_hi <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                  data = analysis[high_mobile == 1], cluster = ~wfo + year)

etable(m_ef01, m_ef2p, m_mob_lo, m_mob_hi,
       dict = dict_vars,
       keep = "%avg_lt_overall",
       headers = c("EF0--1", "EF2+", "Low mobile", "High mobile"),
       fixef.group = list("Pair + Year FE" = "pair_id|year"),
       se.below = TRUE,
       depvar = FALSE,
       title = "Heterogeneity: Tornado Intensity and Mobile Home Exposure",
       label = "tab:het",
       notes = paste0("Sample splits by tornado intensity and county mobile home share. ",
                      "High mobile: above sample median. ",
                      "All include boundary-pair and year FE with tornado controls. ",
                      "SE clustered by WFO and year."),
       style.tex = style.tex("aer"),
       file = "tables/tab5_heterogeneity.tex",
       replace = TRUE)


## ============================================================
## Table F1: Standardized Effect Sizes (SDE)
## ============================================================

cat("Generating SDE table...\n")

# Compute SDEs
sd_cas <- sd(analysis$casualties, na.rm = TRUE)
sd_inj <- sd(analysis$injuries, na.rm = TRUE)
sd_dth <- sd(analysis$deaths, na.rm = TRUE)
sd_any <- sd(analysis$any_casualty, na.rm = TRUE)

# Primary specification coefficients
coef_cas <- coef(m4)["avg_lt_overall"]
se_cas <- sqrt(vcov(m4)["avg_lt_overall", "avg_lt_overall"])
coef_inj <- coef(m_inj)["avg_lt_overall"]
se_inj <- sqrt(vcov(m_inj)["avg_lt_overall", "avg_lt_overall"])
coef_dth <- coef(m_dth)["avg_lt_overall"]
se_dth <- sqrt(vcov(m_dth)["avg_lt_overall", "avg_lt_overall"])
coef_any <- coef(m_any)["avg_lt_overall"]
se_any <- sqrt(vcov(m_any)["avg_lt_overall", "avg_lt_overall"])

sde_cas <- coef_cas / sd_cas
se_sde_cas <- se_cas / sd_cas
sde_inj <- coef_inj / sd_inj
se_sde_inj <- se_inj / sd_inj
sde_dth <- coef_dth / sd_dth
se_sde_dth <- se_dth / sd_dth
sde_any <- coef_any / sd_any
se_sde_any <- se_any / sd_any

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde < 0.005) return("Null")
  if (sde < 0.05) return("Small positive")
  if (sde < 0.15) return("Moderate positive")
  return("Large positive")
}

# Panel A: Pooled
sde_rows_a <- data.table(
  Outcome = c("Total casualties", "Total injuries", "Total deaths", "Any casualty"),
  Beta = c(coef_cas, coef_inj, coef_dth, coef_any),
  SE = c(se_cas, se_inj, se_dth, se_any),
  SD_Y = c(sd_cas, sd_inj, sd_dth, sd_any),
  SDE = c(sde_cas, sde_inj, sde_dth, sde_any),
  SE_SDE = c(se_sde_cas, se_sde_inj, se_sde_dth, se_sde_any),
  Classification = c(classify(sde_cas), classify(sde_inj), classify(sde_dth), classify(sde_any))
)

# Panel B: Heterogeneous (EF2+ subsample)
coef_ef2 <- coef(m_ef2p)["avg_lt_overall"]
se_ef2 <- sqrt(vcov(m_ef2p)["avg_lt_overall", "avg_lt_overall"])
sd_cas_ef2 <- sd(analysis[ef_scale >= 2]$casualties, na.rm = TRUE)
sde_ef2 <- coef_ef2 / sd_cas_ef2
se_sde_ef2 <- se_ef2 / sd_cas_ef2

coef_mob <- coef(m_mob_hi)["avg_lt_overall"]
se_mob <- sqrt(vcov(m_mob_hi)["avg_lt_overall", "avg_lt_overall"])
sd_cas_mob <- sd(analysis[high_mobile == 1]$casualties, na.rm = TRUE)
sde_mob <- coef_mob / sd_cas_mob
se_sde_mob <- se_mob / sd_cas_mob

sde_rows_b <- data.table(
  Outcome = c("Casualties, EF2+ tornadoes", "Casualties, high-mobile-home counties"),
  Beta = c(coef_ef2, coef_mob),
  SE = c(se_ef2, se_mob),
  SD_Y = c(sd_cas_ef2, sd_cas_mob),
  SDE = c(sde_ef2, sde_mob),
  SE_SDE = c(se_sde_ef2, se_sde_mob),
  Classification = c(classify(sde_ef2), classify(sde_mob))
)

# Build LaTeX table
fmt2 <- function(x) formatC(x, format = "f", digits = 4)
fmt3 <- function(x) formatC(x, format = "f", digits = 3)

sde_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]"
)

for (i in 1:nrow(sde_rows_a)) {
  r <- sde_rows_a[i]
  sde_lines <- c(sde_lines, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    r$Outcome, fmt2(r$Beta), fmt2(r$SE), fmt3(r$SD_Y), fmt2(r$SDE), fmt2(r$SE_SDE), r$Classification))
}

sde_lines <- c(sde_lines,
  "\\\\",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\[3pt]"
)

for (i in 1:nrow(sde_rows_b)) {
  r <- sde_rows_b[i]
  sde_lines <- c(sde_lines, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\",
    r$Outcome, fmt2(r$Beta), fmt2(r$SE), fmt3(r$SD_Y), fmt2(r$SDE), fmt2(r$SE_SDE), r$Classification))
}

# Notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does the quality of tornado warnings issued by NWS Weather Forecast Offices, ",
  "as measured by average lead time, causally affect tornado casualties in adjacent counties assigned to different offices? ",
  "\\textbf{Policy mechanism:} The 122 NWS Weather Forecast Offices were assigned fixed County Warning Areas ",
  "during the 1990s modernization following administrative convenience rather than tornado risk, creating persistent ",
  "differences in warning performance across arbitrary boundaries. ",
  "\\textbf{Outcome definition:} Total casualties (injuries plus deaths) per tornado event from the SPC Storm Data. ",
  "\\textbf{Treatment:} Continuous; WFO-level average lead time in minutes between warning issuance and tornado ",
  "touchdown, averaged over 2008--2024 from IEM verification data. ",
  "\\textbf{Data:} SPC tornado records (2008--2024), IEM Cow verification data, NWS CWA shapefiles, and ",
  "Census ACS; 21,346 tornado-event-by-boundary-pair observations across 1,602 pairs and 106 WFOs. ",
  "\\textbf{Method:} OLS with boundary-pair and year fixed effects, two-way clustering by WFO and year. ",
  "\\textbf{Sample:} US tornado events in counties adjacent to a WFO boundary, restricted to county-level ",
  "records with valid FIPS and coordinates. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the full-sample standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_lines <- c(sde_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(sde_lines, "tables/tabF1_sde.tex")


cat("\nAll tables generated.\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_outcomes.tex\n")
cat("  tables/tab4_mechanism.tex\n")
cat("  tables/tab5_heterogeneity.tex\n")
cat("  tables/tabF1_sde.tex\n")
