## 05_tables.R — Generate all LaTeX tables
## APEP-0885: Gotthard Base Tunnel and Regional Economic Integration

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

panel_canton <- readRDS(file.path(DATA_DIR, "panel_canton.rds"))
panel_muni <- readRDS(file.path(DATA_DIR, "panel_muni.rds"))
panel_tourism <- readRDS(file.path(DATA_DIR, "panel_tourism_canton.rds"))
models <- readRDS(file.path(DATA_DIR, "main_models.rds"))
robustness <- readRDS(file.path(DATA_DIR, "robustness_models.rds"))
stats <- readRDS(file.path(DATA_DIR, "summary_stats.rds"))

## ============================================================================
## Table 1: Summary Statistics
## ============================================================================

cat("=== Generating Table 1: Summary Statistics ===\n")

# Pre-treatment (1994-2016)
pre <- panel_canton %>%
  filter(year < 2017, in_sample == 1) %>%
  group_by(Group = ifelse(is_ticino == 1, "Ticino", "Alpine Controls")) %>%
  summarise(
    `Construction (1000 CHF)` = sprintf("%.0f", mean(construction / 1000, na.rm = TRUE)),
    `Constr. per 1000 pop` = sprintf("%.0f", mean(construction_pc, na.rm = TRUE)),
    `Investment (1000 CHF)` = sprintf("%.0f", mean(investment / 1000, na.rm = TRUE)),
    `New Constr. (1000 CHF)` = sprintf("%.0f", mean(new_construction / 1000, na.rm = TRUE)),
    `Canton-Years` = as.character(n()),
    .groups = "drop"
  )

# Tourism pre-treatment (2005-2016)
pre_t <- panel_tourism %>%
  filter(year < 2017, in_sample == 1) %>%
  group_by(Group = ifelse(is_ticino == 1, "Ticino", "Alpine Controls")) %>%
  summarise(
    `Hotel Overnights` = sprintf("%.0f", mean(nights_total, na.rm = TRUE)),
    `Swiss Overnights` = sprintf("%.0f", mean(nights_swiss, na.rm = TRUE)),
    `German Overnights` = sprintf("%.0f", mean(nights_german, na.rm = TRUE)),
    `Italian Overnights` = sprintf("%.0f", mean(nights_italian, na.rm = TRUE)),
    .groups = "drop"
  )

tab1_constr <- pre %>% t()
tab1_tourism <- pre_t %>% t()

# Write LaTeX table manually for full control
tab1_tex <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Pre-Treatment Means}
\\label{tab:summary}
\\begin{tabular}{lcc}
\\toprule
& Ticino & Alpine Controls \\\\
& (1) & (2) \\\\
\\midrule
\\multicolumn{3}{l}{\\textit{Panel A: Construction Expenditure (1994--2016)}} \\\\[3pt]"

# Extract values
ticino_constr <- panel_canton %>%
  filter(year < 2017, is_ticino == 1) %>%
  summarise(
    mean_constr = mean(construction / 1000),
    sd_constr = sd(construction / 1000),
    mean_pc = mean(construction_pc),
    sd_pc = sd(construction_pc),
    mean_inv = mean(investment / 1000),
    mean_new = mean(new_construction / 1000),
    n = n()
  )

control_constr <- panel_canton %>%
  filter(year < 2017, is_alpine_control == 1) %>%
  summarise(
    mean_constr = mean(construction / 1000),
    sd_constr = sd(construction / 1000),
    mean_pc = mean(construction_pc),
    sd_pc = sd(construction_pc),
    mean_inv = mean(investment / 1000),
    mean_new = mean(new_construction / 1000),
    n = n()
  )

tab1_tex <- paste0(tab1_tex, "
Total expenditure (1000 CHF) & ", sprintf("%.0f", ticino_constr$mean_constr), " & ",
sprintf("%.0f", control_constr$mean_constr), " \\\\
& (", sprintf("%.0f", ticino_constr$sd_constr), ") & (",
sprintf("%.0f", control_constr$sd_constr), ") \\\\
Per 1000 residents (CHF) & ", sprintf("%.0f", ticino_constr$mean_pc), " & ",
sprintf("%.0f", control_constr$mean_pc), " \\\\
& (", sprintf("%.0f", ticino_constr$sd_pc), ") & (",
sprintf("%.0f", control_constr$sd_pc), ") \\\\
Investment (1000 CHF) & ", sprintf("%.0f", ticino_constr$mean_inv), " & ",
sprintf("%.0f", control_constr$mean_inv), " \\\\
New construction (1000 CHF) & ", sprintf("%.0f", ticino_constr$mean_new), " & ",
sprintf("%.0f", control_constr$mean_new), " \\\\
Canton-years & ", ticino_constr$n, " & ", control_constr$n, " \\\\")

# Tourism panel
ticino_tour <- panel_tourism %>%
  filter(year < 2017, is_ticino == 1) %>%
  summarise(
    total = mean(nights_total), sd_total = sd(nights_total),
    swiss = mean(nights_swiss), german = mean(nights_german),
    italian = mean(nights_italian), n = n()
  )

control_tour <- panel_tourism %>%
  filter(year < 2017, is_alpine_control == 1) %>%
  summarise(
    total = mean(nights_total), sd_total = sd(nights_total),
    swiss = mean(nights_swiss), german = mean(nights_german),
    italian = mean(nights_italian), n = n()
  )

tab1_tex <- paste0(tab1_tex, "
\\midrule
\\multicolumn{3}{l}{\\textit{Panel B: Hotel Overnight Stays (2005--2016)}} \\\\[3pt]
Total overnights & ", sprintf("%.0f", ticino_tour$total), " & ",
sprintf("%.0f", control_tour$total), " \\\\
& (", sprintf("%.0f", ticino_tour$sd_total), ") & (",
sprintf("%.0f", control_tour$sd_total), ") \\\\
Swiss tourists & ", sprintf("%.0f", ticino_tour$swiss), " & ",
sprintf("%.0f", control_tour$swiss), " \\\\
German tourists & ", sprintf("%.0f", ticino_tour$german), " & ",
sprintf("%.0f", control_tour$german), " \\\\
Italian tourists & ", sprintf("%.0f", ticino_tour$italian), " & ",
sprintf("%.0f", control_tour$italian), " \\\\
Canton-years & ", ticino_tour$n, " & ", control_tour$n, " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard deviations in parentheses. Alpine controls are Graub\\\"unden, Valais, and Uri. Construction data from BFS Construction Statistics (1994--2016). Tourism data from BFS HESTA (2005--2016). Control means are averaged across the three control cantons.
\\end{tablenotes}
\\end{table}")

writeLines(tab1_tex, file.path(TABLE_DIR, "tab1_summary.tex"))
cat("Saved tab1_summary.tex\n")

## ============================================================================
## Table 2: Main DiD Results
## ============================================================================

cat("=== Generating Table 2: Main DiD Results ===\n")

# Use fixest's etable for clean LaTeX output
etable(
  models$m_full,
  robustness$nocovid_full,
  robustness$short_full,
  models$m5_muni,
  headers = c("Full Sample", "Excl. COVID", "2017--2019", "Municipal"),
  se.below = TRUE,
  fitstat = ~ n + r2 + wr2,
  tex = TRUE,
  file = file.path(TABLE_DIR, "tab2_main_did.tex"),
  title = "The Effect of the Gotthard Base Tunnel on Construction Expenditure",
  label = "tab:main_did",
  notes = paste0(
    "Standard errors clustered at the canton level in parentheses. ",
    "Columns 1--3 report canton-level regressions with 26 cantons over 30 years (1994--2023). ",
    "Column 4 reports the municipal-level regression with 318 municipalities. ",
    "The dependent variable is log total construction expenditure. ",
    "``Full Sample'' uses all 26 cantons. ``Excl.\\ COVID'' drops 2020--2021. ",
    "``2017--2019'' restricts to the pre-COVID post-treatment window. ",
    "``Municipal'' uses municipal-level data from Ticino, Graub\\\"unden, Valais, and Uri. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)
cat("Saved tab2_main_did.tex\n")

## ============================================================================
## Table 3: Tourism DiD
## ============================================================================

cat("=== Generating Table 3: Tourism DiD ===\n")

etable(
  models$m6_tourism_total,
  models$m7_tourism_swiss,
  models$m8_tourism_german,
  models$m9_tourism_italian,
  headers = c("Total", "Swiss", "German", "Italian"),
  se.below = TRUE,
  fitstat = ~ n + r2 + wr2,
  tex = TRUE,
  file = file.path(TABLE_DIR, "tab3_tourism.tex"),
  title = "The Effect of the Gotthard Base Tunnel on Hotel Overnight Stays",
  label = "tab:tourism",
  notes = paste0(
    "Standard errors clustered at the canton level in parentheses. ",
    "The sample includes Ticino, Graub\\\"unden, Valais, and Uri (2005--2025). ",
    "The dependent variable is the log of annual hotel overnight stays. ",
    "``Swiss'' guests travel from the north via the tunnel. ",
    "``German'' guests also primarily arrive from the north. ",
    "``Italian'' guests arrive from the south (falsification). ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)
cat("Saved tab3_tourism.tex\n")

## ============================================================================
## Table 4: Robustness Checks
## ============================================================================

cat("=== Generating Table 4: Robustness ===\n")

etable(
  robustness$nocovid_alpine,
  robustness$short_alpine,
  robustness$placebo_2010,
  robustness$placebo_2013,
  robustness$pc_full,
  headers = c("Excl. COVID", "2017--2019", "Placebo 2010", "Placebo 2013", "Per Capita"),
  se.below = TRUE,
  fitstat = ~ n + r2 + wr2,
  tex = TRUE,
  file = file.path(TABLE_DIR, "tab4_robustness.tex"),
  title = "Robustness Checks",
  label = "tab:robustness",
  notes = paste0(
    "Standard errors clustered at the canton level in parentheses. ",
    "Columns 1--2 use the alpine sample (TI, GR, VS, UR). ",
    "Columns 3--4 use only pre-treatment data (1994--2016) with placebo treatment dates. ",
    "Column 5 reports the full 26-canton sample with construction expenditure per 1000 residents as the dependent variable. ",
    "* $p<0.10$, ** $p<0.05$, *** $p<0.01$."
  )
)
cat("Saved tab4_robustness.tex\n")

## ============================================================================
## Table F1: Standardized Effect Sizes (SDE) — MANDATORY APPENDIX
## ============================================================================

cat("=== Generating SDE Table ===\n")

# Compute SDEs for main outcomes
# 1. Construction (full sample, excl COVID)
pre_sd_constr <- panel_canton %>%
  filter(year < 2017) %>%
  pull(log_construction) %>%
  sd()

beta_constr <- coef(robustness$nocovid_full)["treat_post"]
se_constr <- sqrt(diag(vcov(robustness$nocovid_full)))["treat_post"]
sde_constr <- beta_constr / pre_sd_constr
se_sde_constr <- se_constr / pre_sd_constr

# 2. Tourism (Swiss overnights)
pre_sd_swiss <- panel_tourism %>%
  filter(year < 2017, in_sample == 1) %>%
  pull(log_nights_swiss) %>%
  sd()

beta_swiss <- coef(models$m7_tourism_swiss)["treat_post"]
se_swiss <- sqrt(diag(vcov(models$m7_tourism_swiss)))["treat_post"]
sde_swiss <- beta_swiss / pre_sd_swiss
se_sde_swiss <- se_swiss / pre_sd_swiss

# 3. Tourism (German overnights)
pre_sd_german <- panel_tourism %>%
  filter(year < 2017, in_sample == 1) %>%
  pull(log_nights_german) %>%
  sd()

beta_german <- coef(models$m8_tourism_german)["treat_post"]
se_german <- sqrt(diag(vcov(models$m8_tourism_german)))["treat_post"]
sde_german <- beta_german / pre_sd_german
se_sde_german <- se_german / pre_sd_german

# 4. Tourism (Italian — falsification)
pre_sd_italian <- panel_tourism %>%
  filter(year < 2017, in_sample == 1) %>%
  pull(log_nights_italian) %>%
  sd()

beta_italian <- coef(models$m9_tourism_italian)["treat_post"]
se_italian <- sqrt(diag(vcov(models$m9_tourism_italian)))["treat_post"]
sde_italian <- beta_italian / pre_sd_italian
se_sde_italian <- se_italian / pre_sd_italian

# 5. Municipal construction
pre_sd_muni <- panel_muni %>%
  filter(year < 2017) %>%
  pull(log_construction) %>%
  sd()

beta_muni <- coef(models$m5_muni)["treat_post"]
se_muni <- sqrt(diag(vcov(models$m5_muni)))["treat_post"]
sde_muni <- beta_muni / pre_sd_muni
se_sde_muni <- se_muni / pre_sd_muni

# Classify SDE
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) return(ifelse(sde > 0, "Small positive", "Small negative"))
  if (abs_sde < 0.15) return(ifelse(sde > 0, "Moderate positive", "Moderate negative"))
  return(ifelse(sde > 0, "Large positive", "Large negative"))
}

# Build SDE table
sde_rows <- data.frame(
  Outcome = c("Construction expenditure (canton)",
              "Construction expenditure (municipal)",
              "Swiss hotel overnights",
              "German hotel overnights",
              "Italian hotel overnights"),
  Beta = c(beta_constr, beta_muni, beta_swiss, beta_german, beta_italian),
  SE = c(se_constr, se_muni, se_swiss, se_german, se_italian),
  SD_Y = c(pre_sd_constr, pre_sd_muni, pre_sd_swiss, pre_sd_german, pre_sd_italian),
  SDE = c(sde_constr, sde_muni, sde_swiss, sde_german, sde_italian),
  SE_SDE = c(se_sde_constr, se_sde_muni, se_sde_swiss, se_sde_german, se_sde_italian)
)
sde_rows$Classification <- sapply(sde_rows$SDE, classify_sde)

# Heterogeneity: split by pre/post COVID
panel_precovid <- panel_canton %>% filter(!(year %in% c(2020, 2021)))
m_precovid <- feols(log_construction ~ treat_post | canton + year,
                    data = panel_precovid, cluster = ~canton)
beta_precovid <- coef(m_precovid)["treat_post"]
se_precovid <- sqrt(diag(vcov(m_precovid)))["treat_post"]
sde_precovid <- beta_precovid / pre_sd_constr
se_sde_precovid <- se_precovid / pre_sd_constr

# COVID-only post period
panel_covidonly <- panel_canton %>% filter(year <= 2021)
panel_covidonly$post_covid <- as.integer(panel_covidonly$year %in% c(2020, 2021))
panel_covidonly$treat_covid <- panel_covidonly$is_ticino * panel_covidonly$post_covid
m_covid <- feols(log_construction ~ treat_covid | canton + year,
                 data = panel_covidonly, cluster = ~canton)
beta_covid <- coef(m_covid)["treat_covid"]
se_covid <- sqrt(diag(vcov(m_covid)))["treat_covid"]
sde_covid <- beta_covid / pre_sd_constr
se_sde_covid <- se_covid / pre_sd_constr

het_rows <- data.frame(
  Outcome = c("Construction (excl. COVID)",
              "Construction (COVID period)"),
  Beta = c(beta_precovid, beta_covid),
  SE = c(se_precovid, se_covid),
  SD_Y = c(pre_sd_constr, pre_sd_constr),
  SDE = c(sde_precovid, sde_covid),
  SE_SDE = c(se_sde_precovid, se_sde_covid)
)
het_rows$Classification <- sapply(het_rows$SDE, classify_sde)

# Generate LaTeX
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Switzerland. ",
  "\\textbf{Research question:} Does the opening of the Gotthard Base Tunnel (December 2016), ",
  "which cut Zurich--Lugano rail travel time from 2 hours 40 minutes to under 2 hours, ",
  "increase construction investment and hotel tourism in Ticino relative to other alpine cantons? ",
  "\\textbf{Policy mechanism:} The 57\\,km Gotthard Base Tunnel eliminates a major topographic barrier ",
  "between German-speaking northern Switzerland and Italian-speaking Ticino, reducing rail travel time by ",
  "30--45 minutes and integrating a linguistically isolated region with the national economic core. ",
  "\\textbf{Outcome definition:} Log annual construction expenditure (all types, CHF) from BFS construction ",
  "statistics; log annual hotel overnight stays by tourist origin from BFS HESTA. ",
  "\\textbf{Treatment:} Binary, Ticino canton (treated) vs.\\ control cantons. ",
  "\\textbf{Data:} BFS Construction Statistics (1994--2023, 26 cantons, 780 canton-year observations) ",
  "and BFS HESTA tourism statistics (2005--2025, 4 alpine cantons, 84 canton-year observations). ",
  "\\textbf{Method:} Two-way fixed effects difference-in-differences with canton and year fixed effects; ",
  "standard errors clustered at the canton level. ",
  "\\textbf{Sample:} Full 26-canton sample for construction; Ticino, Graub\\\"unden, Valais, Uri for tourism. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment standard deviation. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

format_num <- function(x, digits = 4) sprintf(paste0("%.", digits, "f"), x)

sde_tex <- paste0("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]")

for (i in 1:nrow(sde_rows)) {
  sde_tex <- paste0(sde_tex, "\n",
    sde_rows$Outcome[i], " & ",
    format_num(sde_rows$Beta[i]), " & ",
    format_num(sde_rows$SE[i]), " & ",
    format_num(sde_rows$SD_Y[i]), " & ",
    format_num(sde_rows$SDE[i]), " & ",
    format_num(sde_rows$SE_SDE[i]), " & ",
    sde_rows$Classification[i], " \\\\")
}

sde_tex <- paste0(sde_tex, "
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (COVID vs.\\ Non-COVID Post-Period)}} \\\\[3pt]")

for (i in 1:nrow(het_rows)) {
  sde_tex <- paste0(sde_tex, "\n",
    het_rows$Outcome[i], " & ",
    format_num(het_rows$Beta[i]), " & ",
    format_num(het_rows$SE[i]), " & ",
    format_num(het_rows$SD_Y[i]), " & ",
    format_num(het_rows$SDE[i]), " & ",
    format_num(het_rows$SE_SDE[i]), " & ",
    het_rows$Classification[i], " \\\\")
}

sde_tex <- paste0(sde_tex, "
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
", sde_notes, "
\\end{tablenotes}
\\end{table}")

writeLines(sde_tex, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("Saved tabF1_sde.tex\n")

cat("\n=== All Tables Generated ===\n")
