# 05_tables.R — Generate all LaTeX tables
# apep_0819: Media salience and disaster recovery in India

source("00_packages.R")

cat("=== GENERATING TABLES ===\n")

panel <- fread("data/analysis_panel.csv")
load("data/main_results.RData")
load("data/robustness_results.RData")

dir.create("../tables", showWarnings = FALSE, recursive = TRUE)

# ══════════════════════════════════════════════════════════════════════
# TABLE 1: Summary Statistics
# ══════════════════════════════════════════════════════════════════════

cat("Table 1: Summary statistics...\n")

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics}\n",
  "\\label{tab:summ}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Mean & SD & Min & Max \\\\\n",
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel A: Outcome}} \\\\\n",
  sprintf("Nightlights forward growth (log) & %.3f & %.3f & %.3f & %.3f \\\\\n",
          mean(panel$nl_forward_growth, na.rm=TRUE), sd(panel$nl_forward_growth, na.rm=TRUE),
          min(panel$nl_forward_growth, na.rm=TRUE), max(panel$nl_forward_growth, na.rm=TRUE)),
  sprintf("Nightlights level (mean radiance) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          mean(panel$nl_mean, na.rm=TRUE), sd(panel$nl_mean, na.rm=TRUE),
          min(panel$nl_mean, na.rm=TRUE), max(panel$nl_mean, na.rm=TRUE)),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel B: Treatment variables}} \\\\\n",
  sprintf("Monsoon rain anomaly (z-score) & %.3f & %.3f & %.3f & %.3f \\\\\n",
          mean(panel$rain_anomaly, na.rm=TRUE), sd(panel$rain_anomaly, na.rm=TRUE),
          min(panel$rain_anomaly, na.rm=TRUE), max(panel$rain_anomaly, na.rm=TRUE)),
  sprintf("Flood exposed (rain anomaly $> 0$) & %.3f & %.3f & 0 & 1 \\\\\n",
          mean(panel$flood_exposed, na.rm=TRUE), sd(panel$flood_exposed, na.rm=TRUE)),
  sprintf("Monsoon precipitation (mm/day) & %.2f & %.2f & %.2f & %.2f \\\\\n",
          mean(panel$monsoon_precip, na.rm=TRUE), sd(panel$monsoon_precip, na.rm=TRUE),
          min(panel$monsoon_precip, na.rm=TRUE), max(panel$monsoon_precip, na.rm=TRUE)),
  sprintf("Competing news index (0--1) & %.3f & %.3f & %.2f & %.2f \\\\\n",
          mean(panel$competing_index, na.rm=TRUE), sd(panel$competing_index, na.rm=TRUE),
          min(panel$competing_index, na.rm=TRUE), max(panel$competing_index, na.rm=TRUE)),
  "\\hline\n",
  "\\multicolumn{5}{l}{\\textit{Panel C: District controls (Census 2011)}} \\\\\n",
  sprintf("Log population & %.2f & %.2f & %.2f & %.2f \\\\\n",
          mean(panel$log_pop, na.rm=TRUE), sd(panel$log_pop, na.rm=TRUE),
          min(panel$log_pop, na.rm=TRUE), max(panel$log_pop, na.rm=TRUE)),
  sprintf("Literacy rate & %.3f & %.3f & %.3f & %.3f \\\\\n",
          mean(panel$lit_rate, na.rm=TRUE), sd(panel$lit_rate, na.rm=TRUE),
          min(panel$lit_rate, na.rm=TRUE), max(panel$lit_rate, na.rm=TRUE)),
  sprintf("SC/ST share & %.3f & %.3f & %.3f & %.3f \\\\\n",
          mean(panel$sc_share + panel$st_share, na.rm=TRUE),
          sd(panel$sc_share + panel$st_share, na.rm=TRUE),
          min(panel$sc_share + panel$st_share, na.rm=TRUE),
          max(panel$sc_share + panel$st_share, na.rm=TRUE)),
  "\\hline\\hline\n",
  sprintf("\\multicolumn{5}{l}{\\textit{Observations: %s district-years; %d districts; %d states; %d years}}\n",
          format(nrow(panel), big.mark=","), uniqueN(panel$dist_id),
          uniqueN(panel$pc11_state_id), uniqueN(panel$year)),
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  "\\item \\textit{Notes:} Unit of observation is district-year. Nightlights forward growth is ",
  "$\\log(\\text{NL}_{t+1} + 0.01) - \\log(\\text{NL}_t + 0.01)$. Monsoon rain anomaly is the ",
  "z-score of June--September precipitation relative to the state's 2012--2021 mean. ",
  "Competing news index is a hand-coded annual measure of major global media events during ",
  "monsoon season (Olympics, FIFA World Cup, major international crises), scaled 0--1.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")

# ══════════════════════════════════════════════════════════════════════
# TABLE 2: Main Results
# ══════════════════════════════════════════════════════════════════════

cat("Table 2: Main results...\n")

# Use modelsummary for clean regression table
models_main <- list(
  "(1)" = m1, "(2)" = m2, "(3)" = m3, "(4)" = m4, "(5)" = m5
)

cm <- c(
  "flood_exposed" = "Flood exposed",
  "flood_x_competing" = "Flood $\\times$ Competing",
  "rain_anomaly" = "Rain anomaly",
  "rain_x_competing" = "Rain $\\times$ Competing",
  "flood_x_sports" = "Flood $\\times$ Sports event",
  "rain_x_sports" = "Rain $\\times$ Sports event",
  "rain_anomaly:log_pop" = "Rain $\\times$ Log pop.",
  "rain_anomaly:lit_rate" = "Rain $\\times$ Literacy",
  "rain_anomaly:sc_share" = "Rain $\\times$ SC share"
)

gm <- list(
  list("raw" = "nobs", "clean" = "Observations", "fmt" = function(x) format(x, big.mark = ",")),
  list("raw" = "r.squared.within", "clean" = "Within $R^2$", "fmt" = 3),
  list("raw" = "FE: dist_id", "clean" = "District FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No")),
  list("raw" = "FE: year", "clean" = "Year FE", "fmt" = function(x) ifelse(x == "X", "Yes", "No"))
)

options("modelsummary_format_numeric_latex" = "plain")

modelsummary(
  models_main,
  output = "../tables/tab2_main.tex",
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "The Salience Gap: Monsoon Floods and Nightlights Recovery",
  notes = list(
    "Dependent variable: log nightlights forward growth.",
    "Standard errors clustered at the state level in parentheses.",
    "* p < 0.10, ** p < 0.05, *** p < 0.01."
  )
)

modelsummary(
  models_main,
  output = "../tables/tab2_main.tex",
  coef_map = cm,
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "The Salience Gap: Monsoon Floods and Nightlights Recovery",
  notes = list(
    "Dependent variable: log nightlights forward growth ($\\log \\text{NL}_{t+1} - \\log \\text{NL}_t$).",
    "Standard errors clustered at the state level in parentheses.",
    "Rain anomaly is the z-score of June--September precipitation.",
    "Competing is a 0--1 index of global media events during monsoon season.",
    "Sports event is a binary indicator for Olympic or FIFA World Cup years.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

# ══════════════════════════════════════════════════════════════════════
# TABLE 3: Robustness
# ══════════════════════════════════════════════════════════════════════

cat("Table 3: Robustness...\n")

models_rob <- list(
  "Drop COVID" = r_nocovid,
  "Dry districts" = r_placebo,
  "Wet districts" = r_wet,
  "Contemp. NL" = r_contemp,
  "Quadratic" = r_nonlin
)

tab3 <- modelsummary(
  models_rob,
  output = "latex",
  coef_map = c(
    "rain_anomaly" = "Rain anomaly",
    "rain_x_competing" = "Rain $\\times$ Competing",
    "rain_sq" = "Rain$^2$",
    "rain_sq_x_competing" = "Rain$^2$ $\\times$ Competing"
  ),
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "Robustness Checks",
  notes = list(
    "All specifications include district and year fixed effects.",
    "Standard errors clustered at the state level in parentheses.",
    "``Drop COVID'' excludes 2020. ``Dry/Wet districts'' split at median avg. rainfall.",
    "``Contemp. NL'' uses same-year nightlights growth as outcome.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

modelsummary(
  models_rob,
  output = "../tables/tab3_robustness.tex",
  coef_map = c(
    "rain_anomaly" = "Rain anomaly",
    "rain_x_competing" = "Rain $\\times$ Competing",
    "rain_sq" = "Rain$^2$",
    "rain_sq_x_competing" = "Rain$^2$ $\\times$ Competing"
  ),
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "Robustness Checks",
  notes = list(
    "All specifications include district and year fixed effects.",
    "Standard errors clustered at the state level in parentheses.",
    "``Drop COVID'' excludes 2020. ``Dry/Wet districts'' split at median avg. rainfall.",
    "``Contemp. NL'' uses same-year nightlights growth as outcome.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

# ══════════════════════════════════════════════════════════════════════
# TABLE 4: Mechanism Tests
# ══════════════════════════════════════════════════════════════════════

cat("Table 4: Mechanism tests...\n")

models_mech <- list(
  "SC/ST interaction" = r_scst,
  "Olympics only" = r_olympics
)

tab4 <- modelsummary(
  models_mech,
  output = "latex",
  coef_map = c(
    "rain_anomaly" = "Rain anomaly",
    "rain_x_competing" = "Rain $\\times$ Competing",
    "rain_x_scst" = "Rain $\\times$ High SC/ST",
    "rain_x_competing_x_scst" = "Rain $\\times$ Competing $\\times$ High SC/ST",
    "rain_x_olympics" = "Rain $\\times$ Olympics year"
  ),
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "Mechanism Tests: Disadvantage and Sporting Events",
  notes = list(
    "All specifications include district and year fixed effects.",
    "Standard errors clustered at the state level in parentheses.",
    "High SC/ST is an indicator for above-median Scheduled Caste/Tribe share.",
    "Olympics year is 1 for years with Summer Olympics during monsoon season.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

modelsummary(
  models_mech,
  output = "../tables/tab4_mechanism.tex",
  coef_map = c(
    "rain_anomaly" = "Rain anomaly",
    "rain_x_competing" = "Rain $\\times$ Competing",
    "rain_x_scst" = "Rain $\\times$ High SC/ST",
    "rain_x_competing_x_scst" = "Rain $\\times$ Competing $\\times$ High SC/ST",
    "rain_x_olympics" = "Rain $\\times$ Olympics year"
  ),
  gof_map = gm,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  escape = FALSE,
  title = "Mechanism Tests: Disadvantage and Sporting Events",
  notes = list(
    "All specifications include district and year fixed effects.",
    "Standard errors clustered at the state level in parentheses.",
    "High SC/ST is an indicator for above-median Scheduled Caste/Tribe share.",
    "Olympics year is 1 for years with Summer Olympics during monsoon season.",
    "* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$."
  )
)

# ══════════════════════════════════════════════════════════════════════
# TABLE F1: Standardized Effect Sizes (SDE)
# ══════════════════════════════════════════════════════════════════════

cat("Table F1: Standardized effect sizes...\n")

# Compute SDE for main outcomes
sd_y <- sd(panel$nl_forward_growth, na.rm = TRUE)
sd_rain <- sd(panel$rain_anomaly, na.rm = TRUE)

# Main results from m4 (rain × sports — cleanest specification)
beta_rain <- coef(m4)["rain_anomaly"]
se_rain <- sqrt(vcov(m4)["rain_anomaly", "rain_anomaly"])

beta_interaction <- coef(m4)["rain_x_sports"]
se_interaction <- sqrt(vcov(m4)["rain_x_sports", "rain_x_sports"])

# SDE for continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_rain <- beta_rain * sd_rain / sd_y
se_sde_rain <- se_rain * sd_rain / sd_y

# For the interaction (binary × continuous): SDE = beta / SD(Y)
sde_interaction <- beta_interaction / sd_y
se_sde_interaction <- se_interaction / sd_y

# From m6 (extreme rain)
beta_extreme <- coef(m6)["extreme_rain"]
se_extreme <- sqrt(vcov(m6)["extreme_rain", "extreme_rain"])
sde_extreme <- beta_extreme / sd_y
se_sde_extreme <- se_extreme / sd_y

# Classification function
classify_sde <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

sde_tab <- data.table(
  Outcome = c(
    "Forward NL growth (rain anomaly)",
    "Forward NL growth (rain $\\times$ sports)",
    "Forward NL growth (extreme rain)"
  ),
  Beta = c(beta_rain, beta_interaction, beta_extreme),
  SE = c(se_rain, se_interaction, se_extreme),
  SD_Y = rep(sd_y, 3),
  SDE = c(sde_rain, sde_interaction, sde_extreme),
  SE_SDE = c(se_sde_rain, se_sde_interaction, se_sde_extreme),
  Classification = c(
    classify_sde(sde_rain),
    classify_sde(sde_interaction),
    classify_sde(sde_extreme)
  )
)

# SDE notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} India. ",
  "\\textbf{Research question:} Does media distraction from competing global events ",
  "worsen economic recovery after monsoon floods in Indian districts? ",
  "\\textbf{Policy mechanism:} India's MGNREGA guarantees 100 days of paid employment ",
  "to every rural household. After monsoon floods, districts ramp up public works for ",
  "rehabilitation. If media salience accelerates bureaucratic response, floods during ",
  "low-salience periods (when global events dominate the news cycle) should show ",
  "slower recovery. ",
  "\\textbf{Outcome definition:} Forward nightlights growth, measured as ",
  "$\\log(\\text{VIIRS mean radiance}_{t+1} + 0.01) - \\log(\\text{VIIRS mean radiance}_t + 0.01)$, ",
  "capturing economic recovery in the year following a monsoon. ",
  "\\textbf{Treatment:} Continuous monsoon rainfall anomaly (z-score of June--September ",
  "precipitation relative to state mean) interacted with competing news intensity ",
  "(binary sports event indicator or continuous 0--1 index). ",
  "\\textbf{Data:} SHRUG VIIRS annual nightlights (2012--2021) at district level, ",
  "NASA POWER monthly precipitation (2012--2021) at state centroids, ",
  "hand-coded competing events calendar from public records. ",
  "5,024 district-years across 628 districts, 29 states, 8 years (2013--2020). ",
  "\\textbf{Method:} OLS with district and year fixed effects. Standard errors ",
  "clustered at the state level (29 clusters). ",
  "\\textbf{Sample:} All rural and urban districts in major Indian states ",
  "(excluding union territories with fewer than 3 districts). ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment; ",
  "$\\hat{\\beta} / \\text{SD}(Y)$ for binary treatment. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  paste0(
    apply(sde_tab, 1, function(r) {
      sprintf("%s & %.4f & %.4f & %.3f & %.3f & %.3f & %s \\\\",
              r[1], as.numeric(r[2]), as.numeric(r[3]), as.numeric(r[4]),
              as.numeric(r[5]), as.numeric(r[6]), r[7])
    }),
    collapse = "\n"
  ), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, "../tables/tabF1_sde.tex")

cat("\n=== ALL TABLES GENERATED ===\n")
cat("  tables/tab1_summary.tex\n")
cat("  tables/tab2_main.tex\n")
cat("  tables/tab3_robustness.tex\n")
cat("  tables/tab4_mechanism.tex\n")
cat("  tables/tabF1_sde.tex\n")
