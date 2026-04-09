## 05_tables.R — Generate all tables for the paper
source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE)

dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt[, date := as.Date(date)]
res <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

# ==== Table 1: Summary Statistics ====
tab1_data <- dt[, .(
  `Fishing Hours` = round(mean(fishing_hours), 1),
  `SD` = round(sd(fishing_hours), 1),
  `Hours/Vessel` = round(mean(fifelse(mmsi_present > 0, fishing_hours/mmsi_present, 0)), 2),
  `Vessels/Day` = round(mean(mmsi_present), 0),
  `Days` = uniqueN(date),
  `N` = format(.N, big.mark = ",")
), by = .(Fleet = fleet_type)]

tab1_tex <- kable(tab1_data, format = "latex", booktabs = TRUE,
                  caption = "Summary Statistics: Daily Squid Jigging Effort by Fleet Type",
                  label = "tab:summary") |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "Data: Global Fishing Watch v3.0 (2020, 2022). Unit of observation is flag-day. Fishing Hours is total hours classified as fishing. Hours/Vessel divides fishing hours by the number of distinct MMSI identifiers present. Chinese fleet classified as subsidized following Sala et al.\\ (2018); Korean, Taiwanese, and Japanese fleets as comparator (unsubsidized).",
           threeparttable = TRUE)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))

# ==== Table 2: Main Results ====
etable(res$m1, res$m2, res$m4, res$m5,
       title = "The Lunar Productivity Cycle and Squid Jigging Effort",
       headers = c("Pooled", "Heterogeneous", "Extensive", "Intensive"),
       dict = c(lunar_fraction = "Lunar Illumination",
                lunar_x_subsidized = "Lunar $\\times$ Subsidized",
                any_fishing = "Any Fishing",
                log_fishing_hours = "$\\log$(Fishing Hours)",
                log_hours_per_vessel = "$\\log$(Hours/Vessel)"),
       label = "tab:main",
       notes = "All specifications include flag and year-month fixed effects. Standard errors clustered at the day level in parentheses. Lunar Illumination is the moon's illuminated fraction (0 = new moon, 1 = full moon). Subsidized = Chinese fleet. Columns (1)-(2) and (4) use log(outcome + 1). Column (3) is a linear probability model for any fishing activity.",
       se.below = TRUE,
       fitstat = ~ n + r2,
       file = file.path(tables_dir, "tab2_main.tex"),
       replace = TRUE)

# ==== Table 3: By-Flag Results ====
if (length(res$flag_results) >= 2) {
  etable(res$flag_results,
         title = "Lunar Cycle Effects by Flag State",
         dict = c(lunar_fraction = "Lunar Illumination"),
         label = "tab:byflag",
         notes = "Each column estimates the lunar effect separately for one flag state. All specifications include year-month fixed effects. Standard errors clustered at the day level. CHN = China (subsidized), KOR = South Korea, TWN = Taiwan, JPN = Japan (unsubsidized comparators).",
         se.below = TRUE,
         fitstat = ~ n + r2,
         file = file.path(tables_dir, "tab3_byflag.tex"),
         replace = TRUE)
}

# ==== Table 4: Robustness ====
etable(rob$r1, rob$r2, rob$r4,
       title = "Robustness Checks",
       headers = c("Quadratic", "DOW FE", "Levels"),
       dict = c(lunar_fraction = "Lunar Illumination",
                lunar_sq = "Lunar$^2$",
                lunar_x_subsidized = "Lunar $\\times$ Subsidized",
                fishing_hours = "Fishing Hours",
                log_fishing_hours = "$\\log$(Fishing Hours)"),
       label = "tab:robust",
       notes = "Column (1) adds a quadratic lunar term. Column (2) adds day-of-week fixed effects. Column (3) uses fishing hours in levels rather than logs. All include flag and year-month fixed effects with day-clustered standard errors.",
       se.below = TRUE,
       fitstat = ~ n + r2,
       file = file.path(tables_dir, "tab4_robust.tex"),
       replace = TRUE)

# ==== Table F1: Standardized Effect Sizes (SDE) ====
# Compute SDEs from main results
beta_pooled <- coef(res$m1)["lunar_fraction"]
se_pooled <- se(res$m1)["lunar_fraction"]
beta_interact <- coef(res$m2)["lunar_x_subsidized"]
se_interact <- se(res$m2)["lunar_x_subsidized"]
beta_ext <- coef(res$m4)["lunar_fraction"]
se_ext <- se(res$m4)["lunar_fraction"]

# For continuous treatment: SDE = beta * SD(X) / SD(Y)
sd_lunar <- sd(dt$lunar_fraction)
sd_y <- res$sd_y_all
sd_y_log <- sd(dt$log_fishing_hours)

# Panel A: Pooled
sde_pooled <- beta_pooled * sd_lunar / sd_y_log
se_sde_pooled <- abs(se_pooled * sd_lunar / sd_y_log)

sde_ext <- beta_ext * sd_lunar / sd(dt$any_fishing)
se_sde_ext <- abs(se_ext * sd_lunar / sd(dt$any_fishing))

# Panel B: Heterogeneous (interaction term)
sd_interact <- sd(dt$lunar_x_subsidized)
sde_interact <- beta_interact * sd_interact / sd_y_log
se_sde_interact <- abs(se_interact * sd_interact / sd_y_log)

# By-flag SDEs
sde_rows <- list()
# Pooled
classify_sde <- function(s) {
  if (s < -0.15) "Large negative"
  else if (s < -0.05) "Moderate negative"
  else if (s < -0.005) "Small negative"
  else if (s < 0.005) "Null"
  else if (s < 0.05) "Small positive"
  else if (s < 0.15) "Moderate positive"
  else "Large positive"
}

# Build SDE table
sde_tab <- data.frame(
  Outcome = c(
    "Log fishing hours (pooled)",
    "Any fishing (extensive margin)",
    "Log fishing hours (CHN vs comparator, interaction)"
  ),
  Beta = c(beta_pooled, beta_ext, beta_interact),
  SE = c(se_pooled, se_ext, se_interact),
  SD_Y = c(sd_y_log, sd(dt$any_fishing), sd_y_log),
  SDE = c(sde_pooled, sde_ext, sde_interact),
  SE_SDE = c(se_sde_pooled, se_sde_ext, se_sde_interact)
)
sde_tab$Classification <- sapply(sde_tab$SDE, classify_sde)

# Add heterogeneous rows (Panel B) — CHN separately
if (!is.null(res$flag_results[["CHN"]])) {
  b_chn <- coef(res$flag_results[["CHN"]])["lunar_fraction"]
  se_chn <- se(res$flag_results[["CHN"]])["lunar_fraction"]
  sd_y_chn_log <- sd(dt[flag == "CHN"]$log_fishing_hours)
  sde_chn <- b_chn * sd_lunar / sd_y_chn_log
  se_sde_chn <- abs(se_chn * sd_lunar / sd_y_chn_log)
  sde_tab <- rbind(sde_tab, data.frame(
    Outcome = "Log fishing hours (CHN only)",
    Beta = b_chn, SE = se_chn, SD_Y = sd_y_chn_log,
    SDE = sde_chn, SE_SDE = se_sde_chn,
    Classification = classify_sde(sde_chn)
  ))
}
if (!is.null(res$flag_results[["KOR"]])) {
  b_kor <- coef(res$flag_results[["KOR"]])["lunar_fraction"]
  se_kor <- se(res$flag_results[["KOR"]])["lunar_fraction"]
  sd_y_kor_log <- sd(dt[flag == "KOR"]$log_fishing_hours)
  sde_kor <- b_kor * sd_lunar / sd_y_kor_log
  se_sde_kor <- abs(se_kor * sd_lunar / sd_y_kor_log)
  sde_tab <- rbind(sde_tab, data.frame(
    Outcome = "Log fishing hours (KOR only)",
    Beta = b_kor, SE = se_kor, SD_Y = sd_y_kor_log,
    SDE = sde_kor, SE_SDE = se_sde_kor,
    Classification = classify_sde(sde_kor)
  ))
}

# Format for LaTeX
sde_tab$Beta <- sprintf("%.4f", sde_tab$Beta)
sde_tab$SE <- sprintf("%.4f", sde_tab$SE)
sde_tab$SD_Y <- sprintf("%.3f", as.numeric(sde_tab$SD_Y))
sde_tab$SDE <- sprintf("%.4f", as.numeric(sde_tab$SDE))
sde_tab$SE_SDE <- sprintf("%.4f", as.numeric(sde_tab$SE_SDE))

# Split into panels
panel_a <- sde_tab[1:2, ]
panel_b <- sde_tab[3:nrow(sde_tab), ]

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Global (Chinese, Korean, Taiwanese, Japanese fleets). ",
  "\\textbf{Research question:} Does the lunar cycle --- a perfectly predictable productivity shock for light-based squid fishing --- reduce fishing effort, and do subsidized fleets show muted response compared to unsubsidized fleets? ",
  "\\textbf{Policy mechanism:} Chinese distant-water fishing subsidies (fuel, vessel construction, crew insurance) insulate fleet economics from short-run productivity variation, potentially sustaining effort during biologically unproductive full-moon periods when catch rates approach zero. ",
  "\\textbf{Outcome definition:} Daily aggregate fishing hours from AIS-tracked squid jigging vessels, classified by Global Fishing Watch neural network algorithm. ",
  "\\textbf{Treatment:} Continuous lunar illumination fraction (0 = new moon, 1 = full moon), computed astronomically. ",
  "\\textbf{Data:} Global Fishing Watch v3.0 (Zenodo), 2020 and 2022, flag-day panel for CHN/KOR/TWN/JPN squid jiggers. ",
  "\\textbf{Method:} OLS with flag and year-month fixed effects, standard errors clustered at the day level. Continuous treatment SDE = $\\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$. ",
  "\\textbf{Sample:} Restricted to four major squid jigging nations (China, South Korea, Taiwan, Japan) accounting for over 95\\% of global squid jigging effort. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the sample ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

# Write SDE table
sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\toprule\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n")
for (i in 1:nrow(panel_a)) {
  cat(paste(panel_a[i, ], collapse = " & "), "\\\\\n")
}
cat("\\midrule\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n")
for (i in 1:nrow(panel_b)) {
  cat(paste(panel_b[i, ], collapse = " & "), "\\\\\n")
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables written to", tables_dir, "\n")
cat("Files:", paste(list.files(tables_dir), collapse = ", "), "\n")
