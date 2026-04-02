# ==============================================================================
# 05_tables.R — Generate LaTeX tables
# ==============================================================================

source("00_packages.R")
DATA_DIR <- "../data"
TABLE_DIR <- "../tables"

cat("=== Loading results ===\n")
panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
panel <- panel %>%
  filter(has_tmdl_data) %>%
  mutate(
    station_num = as.numeric(factor(station_id)),
    huc8_num = as.numeric(factor(huc8)),
    post = as.numeric(year >= 2010)
  )

results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
rob <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))

# ---- Table 1: Summary Statistics ----
cat("\n=== Table 1: Summary Statistics ===\n")

summ <- panel %>%
  mutate(Period = ifelse(year < 2010, "Pre-TMDL (2000-2009)", "Post-TMDL (2010-2023)")) %>%
  group_by(Period) %>%
  summarize(
    `Mean DO (mg/L)` = sprintf("%.2f", mean(do_mean)),
    `SD DO` = sprintf("%.2f", sd(do_mean)),
    `Min DO` = sprintf("%.2f", min(do_mean)),
    `Stations` = format(n_distinct(station_id), big.mark = ","),
    `Station-Years` = format(n(), big.mark = ","),
    .groups = "drop"
  )

# By TMDL coverage
summ_tmdl <- panel %>%
  mutate(
    TMDL = ifelse(high_tmdl == 1, "High TMDL Coverage", "Low TMDL Coverage"),
    Period = ifelse(year < 2010, "Pre", "Post")
  ) %>%
  group_by(TMDL, Period) %>%
  summarize(
    mean_do = sprintf("%.2f", mean(do_mean)),
    n = format(n(), big.mark = ","),
    .groups = "drop"
  )

tab1_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Dissolved Oxygen by TMDL Coverage}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{High TMDL Coverage} & \\multicolumn{2}{c}{Low TMDL Coverage} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean DO & N & Mean DO & N \\\\\n",
  "\\midrule\n"
)

# Fill in from summ_tmdl
for (period in c("Pre", "Post")) {
  high <- summ_tmdl %>% filter(TMDL == "High TMDL Coverage", Period == period)
  low <- summ_tmdl %>% filter(TMDL == "Low TMDL Coverage", Period == period)
  period_label <- ifelse(period == "Pre", "Pre-TMDL (2000--2009)", "Post-TMDL (2010--2023)")
  tab1_tex <- paste0(tab1_tex,
    period_label, " & ", high$mean_do, " & ", high$n, " & ", low$mean_do, " & ", low$n, " \\\\\n")
}

# Add overall stats
tab1_tex <- paste0(tab1_tex,
  "\\midrule\n",
  "Stations & \\multicolumn{2}{c}{", format(n_distinct(panel$station_id[panel$high_tmdl == 1]), big.mark = ","),
  "} & \\multicolumn{2}{c}{", format(n_distinct(panel$station_id[panel$high_tmdl == 0]), big.mark = ","), "} \\\\\n",
  "HUC8 Watersheds & \\multicolumn{2}{c}{", n_distinct(panel$huc8[panel$high_tmdl == 1]),
  "} & \\multicolumn{2}{c}{", n_distinct(panel$huc8[panel$high_tmdl == 0]), "} \\\\\n",
  "Mean TMDL Share & \\multicolumn{2}{c}{",
  sprintf("%.2f", mean(panel$tmdl_share[panel$high_tmdl == 1], na.rm = TRUE)),
  "} & \\multicolumn{2}{c}{",
  sprintf("%.2f", mean(panel$tmdl_share[panel$high_tmdl == 0], na.rm = TRUE)),
  "} \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  "\\item \\textit{Notes:} Summary statistics for dissolved oxygen (DO) readings ",
  "from the EPA Water Quality Portal, 2000--2023. Stations are matched to HUC8 ",
  "watersheds and classified by TMDL coverage using EPA ATTAINS data. High TMDL ",
  "Coverage denotes stations in HUC8 watersheds where the share of impaired ",
  "assessment units with completed TMDLs exceeds the sample median. ",
  "DO measured in mg/L.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("Table 1 written.\n")


# ---- Table 2: Main Results ----
cat("\n=== Table 2: Main Results ===\n")

tab2_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Effect of TMDL Coverage on Dissolved Oxygen}\n",
  "\\label{tab:main}\n"
)

# Use fixest etable for clean formatting
etable(results$m1, results$m2, results$m4, results$m5,
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab2_main.tex"),
       replace = TRUE,
       title = "Effect of TMDL Coverage on Dissolved Oxygen",
       label = "tab:main",
       headers = c("Station", "Station", "HUC8", "HUC8"),
       dict = c(
         "tmdl_share:post" = "TMDL Share $\\times$ Post",
         "high_tmdl:post" = "High TMDL $\\times$ Post",
         "do_mean" = "Mean DO (mg/L)"
       ),
       notes = paste0(
         "Station-year panel, 2000--2023. Dependent variable is mean annual dissolved oxygen (mg/L). ",
         "TMDL Share is the proportion of impaired assessment units in the station's HUC8 watershed ",
         "with completed TMDLs (IR Category 4A). High TMDL is a binary indicator for above-median TMDL share. ",
         "Post = 1 for years $\\geq$ 2010. All specifications include station (or HUC8) and year fixed effects. ",
         "Standard errors clustered at the HUC8 level in parentheses. ",
         "Significance: $^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$."
       ),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = c("n", "r2"))

cat("Table 2 written.\n")


# ---- Table 3: Robustness ----
cat("\n=== Table 3: Robustness ===\n")

etable(rob$alt_cutoffs[["2008"]], rob$alt_cutoffs[["2010"]], rob$alt_cutoffs[["2012"]],
       rob$winsorized, rob$weighted,
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab3_robustness.tex"),
       replace = TRUE,
       title = "Robustness: Alternative Specifications",
       label = "tab:robust",
       headers = c("Post$\\geq$2008", "Post$\\geq$2010", "Post$\\geq$2012",
                    "Winsorized", "Weighted"),
       notes = paste0(
         "Each column reports the coefficient on TMDL Share $\\times$ Post from the main specification ",
         "(station and year FE, clustered at HUC8). Columns 1--3 vary the post-period cutoff year. ",
         "Column 4 winsorizes DO at the 1st and 99th percentiles. ",
         "Column 5 weights by annual monitoring frequency."
       ),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = c("n", "r2"))

cat("Table 3 written.\n")


# ---- Table 4: Placebo Test ----
cat("\n=== Table 4: Placebo ===\n")

etable(rob$placebo,
       tex = TRUE,
       file = file.path(TABLE_DIR, "tab4_placebo.tex"),
       replace = TRUE,
       title = "Placebo Test: Pre-Period Only (2000--2009)",
       label = "tab:placebo",
       headers = "Placebo Post$\\geq$2005",
       notes = paste0(
         "Sample restricted to 2000--2009. Placebo post-period begins in 2005. ",
         "A null coefficient supports the parallel trends assumption: ",
         "high- and low-TMDL-coverage watersheds followed similar DO trajectories ",
         "before the TMDL program's primary implementation period."
       ),
       depvar = FALSE,
       se.below = TRUE,
       fitstat = c("n", "r2"))

cat("Table 4 written.\n")


# ---- SDE Table (Appendix) ----
cat("\n=== SDE Table (Appendix) ===\n")

# Compute standardized effect sizes
sd_y_pre <- sd(panel$do_mean[panel$year < 2010], na.rm = TRUE)

# Main coefficient (continuous treatment)
beta_main <- coef(results$m1)["tmdl_share:post"]
se_main <- sqrt(vcov(results$m1)["tmdl_share:post", "tmdl_share:post"])
sde_main <- beta_main / sd_y_pre
se_sde_main <- se_main / sd_y_pre

# Binary treatment coefficient
beta_bin <- coef(results$m2)["high_tmdl:post"]
se_bin <- sqrt(vcov(results$m2)["high_tmdl:post", "high_tmdl:post"])
sde_bin <- beta_bin / sd_y_pre
se_sde_bin <- se_bin / sd_y_pre

classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_rows <- data.frame(
  Panel = c("A", "A"),
  Outcome = c("Mean DO (continuous TMDL)", "Mean DO (binary TMDL)"),
  Beta = c(sprintf("%.4f", beta_main), sprintf("%.4f", beta_bin)),
  SE = c(sprintf("%.4f", se_main), sprintf("%.4f", se_bin)),
  SD_Y = c(sprintf("%.2f", sd_y_pre), sprintf("%.2f", sd_y_pre)),
  SDE = c(sprintf("%.4f", sde_main), sprintf("%.4f", sde_bin)),
  SE_SDE = c(sprintf("%.4f", se_sde_main), sprintf("%.4f", se_sde_bin)),
  Classification = c(classify_sde(sde_main), classify_sde(sde_bin))
)

# Add heterogeneity panel (split by state)
panel_va <- panel %>% filter(grepl("^USGS-0[1-4]", station_id))  # VA sites
panel_nc <- panel %>% filter(grepl("^USGS-0[5-9]|^21", station_id))  # NC sites approximate

# VA subset
if (nrow(panel_va) > 100) {
  m_va <- tryCatch(
    feols(do_mean ~ tmdl_share:post | station_num + year, data = panel_va, cluster = ~huc8_num),
    error = function(e) NULL
  )
  if (!is.null(m_va)) {
    beta_va <- coef(m_va)["tmdl_share:post"]
    se_va <- sqrt(vcov(m_va)["tmdl_share:post", "tmdl_share:post"])
    sd_y_va <- sd(panel_va$do_mean[panel_va$year < 2010], na.rm = TRUE)
    sde_va <- beta_va / sd_y_va
    se_sde_va <- se_va / sd_y_va
    sde_rows <- rbind(sde_rows, data.frame(
      Panel = "B", Outcome = "Mean DO (Virginia)",
      Beta = sprintf("%.4f", beta_va), SE = sprintf("%.4f", se_va),
      SD_Y = sprintf("%.2f", sd_y_va), SDE = sprintf("%.4f", sde_va),
      SE_SDE = sprintf("%.4f", se_sde_va), Classification = classify_sde(sde_va)
    ))
  }
}

# Build LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does TMDL establishment under CWA Section 303(d) improve ",
  "dissolved oxygen levels in impaired waterbody segments? ",
  "\\textbf{Policy mechanism:} TMDLs set maximum allowable pollutant loading for impaired ",
  "waters, triggering permit revisions (NPDES), best management practices, and nonpoint source ",
  "reduction plans that collectively reduce pollution inflows. ",
  "\\textbf{Outcome definition:} Mean annual dissolved oxygen (mg/L) at USGS monitoring stations, ",
  "measuring the oxygen available in surface water for aquatic life. ",
  "\\textbf{Treatment:} Continuous --- share of impaired assessment units in the station's HUC8 ",
  "watershed with completed TMDLs (IR Category 4A vs. 5). ",
  "\\textbf{Data:} EPA Water Quality Portal and ATTAINS, 2000--2023, station-year panel. ",
  "\\textbf{Method:} TWFE with station and year fixed effects, standard errors clustered at HUC8. ",
  "\\textbf{Sample:} Stations in HUC8 watersheds containing impaired assessment units in Virginia ",
  "and North Carolina; restricted to stations with $\\geq$2 annual readings. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[t]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{tabular}{llcccccl}\n",
  "\\toprule\n",
  " & Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\\n"
)

for (i in which(sde_rows$Panel == "A")) {
  sde_tex <- paste0(sde_tex,
    " & ", sde_rows$Outcome[i], " & ", sde_rows$Beta[i], " & ", sde_rows$SE[i],
    " & ", sde_rows$SD_Y[i], " & ", sde_rows$SDE[i], " & ", sde_rows$SE_SDE[i],
    " & ", sde_rows$Classification[i], " \\\\\n")
}

if (any(sde_rows$Panel == "B")) {
  sde_tex <- paste0(sde_tex,
    "\\midrule\n",
    "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\\n")
  for (i in which(sde_rows$Panel == "B")) {
    sde_tex <- paste0(sde_tex,
      " & ", sde_rows$Outcome[i], " & ", sde_rows$Beta[i], " & ", sde_rows$SE[i],
      " & ", sde_rows$SD_Y[i], " & ", sde_rows$SDE[i], " & ", sde_rows$SE_SDE[i],
      " & ", sde_rows$Classification[i], " \\\\\n")
  }
}

sde_tex <- paste0(sde_tex,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)

writeLines(sde_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("SDE table written.\n")

cat("\n=== All tables generated ===\n")
