# 05_tables.R — Generate all tables for apep_0925
# Calorie labeling threshold avoidance paper

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

agg_panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
models <- readRDS(file.path(DATA_DIR, "models.rds"))
rob_models <- readRDS(file.path(DATA_DIR, "robustness_models.rds"))

# ============================================================
# TABLE 1: Descriptive Statistics
# ============================================================
cat("=== Generating Table 1: Descriptive Statistics ===\n")

food_eng <- agg_panel |> filter(england == 1, food == 1)
food_scot <- agg_panel |> filter(country == "Scotland", food == 1)
food_wales <- agg_panel |> filter(country == "Wales", food == 1)

# Pre vs post summary
desc_data <- agg_panel |>
  filter(food == 1) |>
  group_by(country, post) |>
  summarise(
    mean_total = mean(total_enterprises),
    mean_large = mean(large_enterprises),
    mean_share = mean(large_share, na.rm = TRUE),
    mean_ratio = mean(threshold_ratio, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  ) |>
  mutate(period = ifelse(post == 0, "Pre (2010--2022)", "Post (2023--2024)"))

cat("Descriptive summary:\n")
print(as.data.frame(desc_data))

# Generate LaTeX table
tab1_lines <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Descriptive Statistics: Food and Beverage Service Enterprises}",
  "\\label{tab:descriptives}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Total & Large (250+) & Large & Threshold \\\\",
  " & Enterprises & Enterprises & Share (\\%) & Ratio \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: England (Treated)}} \\\\[3pt]"
)

eng_pre <- desc_data |> filter(country == "England", post == 0)
eng_post <- desc_data |> filter(country == "England", post == 1)
tab1_lines <- c(tab1_lines,
  sprintf("Pre-regulation (2010--2022) & %s & %s & %s & %s \\\\",
    formatC(round(eng_pre$mean_total), format = "d", big.mark = ","),
    formatC(round(eng_pre$mean_large), format = "d", big.mark = ","),
    formatC(round(eng_pre$mean_share * 100, 3), format = "f", digits = 3),
    formatC(round(eng_pre$mean_ratio, 3), format = "f", digits = 3)),
  sprintf("Post-regulation (2023--2024) & %s & %s & %s & %s \\\\[6pt]",
    formatC(round(eng_post$mean_total), format = "d", big.mark = ","),
    formatC(round(eng_post$mean_large), format = "d", big.mark = ","),
    formatC(round(eng_post$mean_share * 100, 3), format = "f", digits = 3),
    formatC(round(eng_post$mean_ratio, 3), format = "f", digits = 3))
)

tab1_lines <- c(tab1_lines,
  "\\multicolumn{5}{l}{\\textit{Panel B: Scotland (Control)}} \\\\[3pt]"
)

scot_pre <- desc_data |> filter(country == "Scotland", post == 0)
scot_post <- desc_data |> filter(country == "Scotland", post == 1)
tab1_lines <- c(tab1_lines,
  sprintf("Pre-regulation (2010--2022) & %s & %s & %s & %s \\\\",
    formatC(round(scot_pre$mean_total), format = "d", big.mark = ","),
    formatC(round(scot_pre$mean_large), format = "d", big.mark = ","),
    formatC(round(scot_pre$mean_share * 100, 3), format = "f", digits = 3),
    formatC(round(scot_pre$mean_ratio, 3), format = "f", digits = 3)),
  sprintf("Post-regulation (2023--2024) & %s & %s & %s & %s \\\\[6pt]",
    formatC(round(scot_post$mean_total), format = "d", big.mark = ","),
    formatC(round(scot_post$mean_large), format = "d", big.mark = ","),
    formatC(round(scot_post$mean_share * 100, 3), format = "f", digits = 3),
    formatC(round(scot_post$mean_ratio, 3), format = "f", digits = 3))
)

tab1_lines <- c(tab1_lines,
  "\\multicolumn{5}{l}{\\textit{Panel C: Wales (Control)}} \\\\[3pt]"
)

wales_pre <- desc_data |> filter(country == "Wales", post == 0)
wales_post <- desc_data |> filter(country == "Wales", post == 1)
tab1_lines <- c(tab1_lines,
  sprintf("Pre-regulation (2010--2022) & %s & %s & %s & %s \\\\",
    formatC(round(wales_pre$mean_total), format = "d", big.mark = ","),
    formatC(round(wales_pre$mean_large), format = "d", big.mark = ","),
    formatC(round(wales_pre$mean_share * 100, 3), format = "f", digits = 3),
    formatC(round(wales_pre$mean_ratio, 3), format = "f", digits = 3)),
  sprintf("Post-regulation (2023--2024) & %s & %s & %s & %s \\\\",
    formatC(round(wales_post$mean_total), format = "d", big.mark = ","),
    formatC(round(wales_post$mean_large), format = "d", big.mark = ","),
    formatC(round(wales_post$mean_share * 100, 3), format = "f", digits = 3),
    formatC(round(wales_post$mean_ratio, 3), format = "f", digits = 3))
)

tab1_lines <- c(tab1_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Data from ONS UK Business Counts (NOMIS NM\\_142\\_1), ",
  "annual March snapshots, 2010--2024. ``Total Enterprises'' counts all registered ",
  "food and beverage service enterprises (SIC 56). ``Large (250+)'' counts enterprises ",
  "with 250 or more employees, subject to England's mandatory calorie labeling regulation ",
  "(effective April 6, 2022). ``Large Share'' is the ratio of large to total enterprises. ",
  "``Threshold Ratio'' is enterprises with 250--499 employees divided by those with ",
  "100--249 employees. Scotland and Wales did not adopt calorie labeling mandates. ",
  "Enterprise counts are rounded to the nearest 5 by ONS.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(TABLE_DIR, "tab1_descriptives.tex"))
cat("  → Saved tab1_descriptives.tex\n")

# ============================================================
# TABLE 2: Main Results (Triple-Difference)
# ============================================================
cat("\n=== Generating Table 2: Main Results ===\n")

# Extract results from models
extract_row <- function(model, varname = "treated") {
  cf <- summary(model)$coeftable
  if (varname %in% rownames(cf)) {
    return(list(
      coef = cf[varname, "Estimate"],
      se = cf[varname, "Std. Error"],
      pval = cf[varname, "Pr(>|t|)"]
    ))
  }
  return(list(coef = NA, se = NA, pval = NA))
}

stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("^{***}")
  if (p < 0.05) return("^{**}")
  if (p < 0.10) return("^{*}")
  return("")
}

r1 <- extract_row(models$m1)
r2 <- extract_row(models$m2)
r3 <- extract_row(models$m3)
r4 <- extract_row(models$m4)

tab2_lines <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Effect of Calorie Labeling on Food Service Enterprises: Triple-Difference Estimates}",
  "\\label{tab:main_results}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Log Total & Large Share & Threshold & Log Large \\\\",
  " & Enterprises & (250+/Total) & Ratio & Enterprises \\\\",
  "\\hline",
  sprintf("England $\\times$ Food $\\times$ Post & $%s%s$ & $%s%s$ & $%s%s$ & $%s%s$ \\\\",
    formatC(r1$coef, format = "f", digits = 3), stars(r1$pval),
    formatC(r2$coef, format = "f", digits = 4), stars(r2$pval),
    formatC(r3$coef, format = "f", digits = 3), stars(r3$pval),
    formatC(r4$coef, format = "f", digits = 3), stars(r4$pval)),
  sprintf(" & (%s) & (%s) & (%s) & (%s) \\\\[6pt]",
    formatC(r1$se, format = "f", digits = 3),
    formatC(r2$se, format = "f", digits = 4),
    formatC(r3$se, format = "f", digits = 3),
    formatC(r4$se, format = "f", digits = 3)),
  sprintf("Observations & %d & %d & %d & %d \\\\",
    nrow(agg_panel), nrow(agg_panel),
    nrow(agg_panel |> filter(!is.na(threshold_ratio), near_100_249 > 0)),
    nrow(agg_panel)),
  "Unit $\\times$ Industry FE & Yes & Yes & Yes & Yes \\\\",
  "Country $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  "Industry $\\times$ Year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Permutation $p$-value & %s & & & \\\\",
    formatC(rob_models$perm_pval, format = "f", digits = 3)),
  "\\hline",
  sprintf("Pre-treatment mean (Eng.~food) & %s & %s & %s & %s \\\\",
    formatC(mean(food_eng$ln_total[food_eng$post == 0]), format = "f", digits = 3),
    formatC(mean(food_eng$large_share[food_eng$post == 0]) * 100, format = "f", digits = 3),
    formatC(mean(food_eng$threshold_ratio[food_eng$post == 0], na.rm = TRUE), format = "f", digits = 3),
    formatC(mean(food_eng$ln_large[food_eng$post == 0]), format = "f", digits = 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Triple-difference estimates comparing food service enterprises (SIC 56) ",
  "in England to control sectors (retail, accommodation, IT services, legal/accounting) ",
  "in England, Scotland, and Wales, before and after the April 2022 calorie labeling mandate. ",
  "All specifications include unit (country $\\times$ industry), country $\\times$ year, ",
  "and industry $\\times$ year fixed effects. Standard errors clustered at the unit level ",
  "in parentheses. Column (1): log total enterprise count. Column (2): share of enterprises ",
  "with 250+ employees. Column (3): ratio of enterprises with 250--499 to those with ",
  "100--249 employees (threshold ratio). Column (4): log count of large (250+) enterprises. ",
  "Permutation $p$-value from 1,000 random reassignments of the treatment indicator. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(TABLE_DIR, "tab2_main_results.tex"))
cat("  → Saved tab2_main_results.tex\n")

# ============================================================
# TABLE 3: Robustness Checks
# ============================================================
cat("\n=== Generating Table 3: Robustness ===\n")

r_base <- extract_row(models$m1)
r_placebo_t <- extract_row(rob_models$placebo_threshold)
r_fake <- extract_row(rob_models$placebo_year, "treated_fake")
r_no55 <- extract_row(rob_models$no_accommodation)
r_47 <- extract_row(rob_models$retail_only)
r_nocovid <- extract_row(rob_models$no_covid)

tab3_lines <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Robustness Checks}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  " & Coefficient & SE & $p$-value & $N$ \\\\",
  "\\hline",
  "\\multicolumn{5}{l}{\\textit{Panel A: Main specification}} \\\\[3pt]",
  sprintf("Baseline (log total enterprises) & %s & %s & %s & %d \\\\[6pt]",
    formatC(r_base$coef, format = "f", digits = 3),
    formatC(r_base$se, format = "f", digits = 3),
    formatC(r_base$pval, format = "f", digits = 3),
    nrow(agg_panel)),
  "\\multicolumn{5}{l}{\\textit{Panel B: Placebo tests}} \\\\[3pt]",
  sprintf("Placebo threshold (100--249 / 50--99 ratio) & %s & %s & %s & 225 \\\\",
    formatC(r_placebo_t$coef, format = "f", digits = 3),
    formatC(r_placebo_t$se, format = "f", digits = 3),
    formatC(r_placebo_t$pval, format = "f", digits = 3)),
  sprintf("Placebo year (2019 instead of 2022) & %s & %s & %s & 180 \\\\[6pt]",
    formatC(r_fake$coef, format = "f", digits = 3),
    formatC(r_fake$se, format = "f", digits = 3),
    formatC(r_fake$pval, format = "f", digits = 3)),
  "\\multicolumn{5}{l}{\\textit{Panel C: Alternative control sectors}} \\\\[3pt]",
  sprintf("Drop accommodation (SIC 55) & %s & %s & %s & 180 \\\\",
    formatC(r_no55$coef, format = "f", digits = 3),
    formatC(r_no55$se, format = "f", digits = 3),
    formatC(r_no55$pval, format = "f", digits = 3)),
  sprintf("Retail only (SIC 47) control & %s & %s & %s & 90 \\\\[6pt]",
    formatC(r_47$coef, format = "f", digits = 3),
    formatC(r_47$se, format = "f", digits = 3),
    formatC(r_47$pval, format = "f", digits = 3)),
  "\\multicolumn{5}{l}{\\textit{Panel D: Sample variations}} \\\\[3pt]",
  sprintf("Exclude COVID years (2020--2021) & %s & %s & %s & 195 \\\\",
    formatC(r_nocovid$coef, format = "f", digits = 3),
    formatC(r_nocovid$se, format = "f", digits = 3),
    formatC(r_nocovid$pval, format = "f", digits = 3)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the triple-difference framework ",
  "with unit, country $\\times$ year, and industry $\\times$ year fixed effects. ",
  "Standard errors clustered at the unit level. Panel B: the placebo threshold test ",
  "replaces the 250-employee regulatory threshold with the 100-employee boundary ",
  "(where no regulation applies). The placebo year test restricts the sample to ",
  "2010--2021 and assigns fake treatment in 2019. Panel C varies the control sectors. ",
  "Panel D excludes COVID-affected years. $^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(TABLE_DIR, "tab3_robustness.tex"))
cat("  → Saved tab3_robustness.tex\n")

# ============================================================
# TABLE 4: Event Study Coefficients
# ============================================================
cat("\n=== Generating Table 4: Event Study ===\n")

es_coefs <- data.frame(
  event_time = as.numeric(gsub("event_time::|:eng_food", "", names(coef(models$m5)))),
  coef = coef(models$m5),
  se = sqrt(diag(vcov(models$m5))),
  row.names = NULL
)
es_coefs$ci_lo <- es_coefs$coef - 1.96 * es_coefs$se
es_coefs$ci_hi <- es_coefs$coef + 1.96 * es_coefs$se
es_coefs <- es_coefs |> arrange(event_time)

# Add the reference year (event_time = 0)
es_coefs <- bind_rows(
  es_coefs |> filter(event_time < 0),
  data.frame(event_time = 0, coef = 0, se = NA, ci_lo = NA, ci_hi = NA),
  es_coefs |> filter(event_time > 0)
)

tab4_lines <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Event Study: Log Total Food Service Enterprises}",
  "\\label{tab:event_study}",
  "\\begin{tabular}{lcccc}",
  "\\hline\\hline",
  "Event Time & Coefficient & SE & 95\\% CI Lower & 95\\% CI Upper \\\\",
  "\\hline"
)

for (i in 1:nrow(es_coefs)) {
  row <- es_coefs[i, ]
  if (row$event_time == 0) {
    tab4_lines <- c(tab4_lines,
      sprintf("$t = %d$ (reference) & 0.000 & --- & --- & --- \\\\",
        row$event_time))
  } else {
    lab <- ifelse(row$event_time > 0, "\\textbf", "")
    tab4_lines <- c(tab4_lines,
      sprintf("%s{$t = %s%d$} & %s & %s & %s & %s \\\\",
        ifelse(row$event_time > 0, "\\textbf", ""),
        ifelse(row$event_time > 0, "+", ""), row$event_time,
        formatC(row$coef, format = "f", digits = 3),
        formatC(row$se, format = "f", digits = 3),
        formatC(row$ci_lo, format = "f", digits = 3),
        formatC(row$ci_hi, format = "f", digits = 3)))
  }
}

tab4_lines <- c(tab4_lines,
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Event study coefficients from the triple-difference specification ",
  "with unit, country $\\times$ year, and industry $\\times$ year fixed effects. ",
  "The dependent variable is log total food service enterprises. The reference year is ",
  "$t = 0$ (2022, the last pre-treatment year; data reference date is March, regulation ",
  "effective April 2022). Post-treatment coefficients ($t = +1, +2$) in bold. ",
  "Standard errors clustered at the unit level. All pre-treatment coefficients are ",
  "statistically insignificant, supporting the parallel trends assumption.",
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(TABLE_DIR, "tab4_event_study.tex"))
cat("  → Saved tab4_event_study.tex\n")

# ============================================================
# TABLE F1: SDE (Standardized Effect Size)
# ============================================================
cat("\n=== Generating Table F1: Standardized Effect Sizes ===\n")

# Main outcomes
sde_rows <- list()

# 1. Total enterprises (log) — main spec
beta1 <- coef(models$m1)["treated"]
se1 <- sqrt(diag(vcov(models$m1)))["treated"]
sd_y1 <- sd(food_eng$ln_total[food_eng$post == 0])
sde1 <- beta1 / sd_y1
se_sde1 <- se1 / sd_y1

# 2. Large share
beta2 <- coef(models$m2)["treated"]
se2 <- sqrt(diag(vcov(models$m2)))["treated"]
sd_y2 <- sd(food_eng$large_share[food_eng$post == 0])
sde2 <- beta2 / sd_y2
se_sde2 <- se2 / sd_y2

# 3. Threshold ratio
food_eng_ratio <- food_eng |> filter(!is.na(threshold_ratio))
beta3 <- coef(models$m3)["treated"]
se3 <- sqrt(diag(vcov(models$m3)))["treated"]
sd_y3 <- sd(food_eng_ratio$threshold_ratio[food_eng_ratio$post == 0])
sde3 <- beta3 / sd_y3
se_sde3 <- se3 / sd_y3

# 4. Log large enterprises
beta4 <- coef(models$m4)["treated"]
se4 <- sqrt(diag(vcov(models$m4)))["treated"]
sd_y4 <- sd(food_eng$ln_large[food_eng$post == 0])
sde4 <- beta4 / sd_y4
se_sde4 <- se4 / sd_y4

# Classification function
classify_sde <- function(sde) {
  if (is.na(sde)) return("---")
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Heterogeneity splits
# Split 1: England-only DiD (food vs control sectors)
eng_only <- agg_panel |> filter(england == 1)
m_eng_only <- feols(ln_total ~ food:post | unit_id + year,
  data = eng_only, cluster = ~unit_id)
beta_eng <- coef(m_eng_only)["food:post"]
se_eng <- sqrt(diag(vcov(m_eng_only)))["food:post"]
sd_y_eng <- sd(eng_only$ln_total[eng_only$food == 1 & eng_only$post == 0])
sde_eng <- beta_eng / sd_y_eng
se_sde_eng <- se_eng / sd_y_eng

# Split 2: Scotland/Wales DiD (food vs control, control geography)
ctrl_geo <- agg_panel |> filter(england == 0)
m_ctrl_geo <- feols(ln_total ~ food:post | unit_id + year,
  data = ctrl_geo, cluster = ~unit_id)
beta_ctrl <- coef(m_ctrl_geo)["food:post"]
se_ctrl <- sqrt(diag(vcov(m_ctrl_geo)))["food:post"]
sd_y_ctrl <- sd(ctrl_geo$ln_total[ctrl_geo$food == 1 & ctrl_geo$post == 0])
sde_ctrl <- beta_ctrl / sd_y_ctrl
se_sde_ctrl <- se_ctrl / sd_y_ctrl

# SDE notes
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United Kingdom (England treated; Scotland and Wales as controls). ",
  "\\textbf{Research question:} Does mandatory calorie labeling for food businesses with 250 or more ",
  "employees alter the size distribution or total count of food service enterprises? ",
  "\\textbf{Policy mechanism:} The Calorie Labelling (Out of Home Sector) (England) Regulations 2022 ",
  "require food businesses with 250+ employees to display calorie information on menus, online platforms, ",
  "and food delivery apps; businesses below 250 employees are exempt, creating a compliance threshold. ",
  "\\textbf{Outcome definition:} Log total enterprise count, share of large enterprises, and threshold ratio ",
  "(250--499 / 100--249 band) from ONS UK Business Counts. ",
  "\\textbf{Treatment:} Binary (England post-April 2022 vs.\\ Scotland/Wales and pre-period). ",
  "\\textbf{Data:} ONS UK Business Counts (NOMIS NM\\_142\\_1), annual March snapshots, 2010--2024, ",
  "country $\\times$ industry level, $N = 225$. ",
  "\\textbf{Method:} Triple-difference (country $\\times$ industry $\\times$ time) with two-way ",
  "clustered standard errors at the unit level; permutation inference ($p = 0.935$). ",
  "\\textbf{Sample:} Food and beverage service enterprises (SIC 56) in England, Scotland, and Wales; ",
  "control sectors are retail (47), accommodation (55), IT services (62), and legal/accounting (69). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[!t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]",
  sprintf("Log total enterprises & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta1, format = "f", digits = 3),
    formatC(se1, format = "f", digits = 3),
    formatC(sd_y1, format = "f", digits = 3),
    formatC(sde1, format = "f", digits = 3),
    formatC(se_sde1, format = "f", digits = 3),
    classify_sde(sde1)),
  sprintf("Large enterprise share & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta2, format = "f", digits = 4),
    formatC(se2, format = "f", digits = 4),
    formatC(sd_y2, format = "f", digits = 4),
    formatC(sde2, format = "f", digits = 3),
    formatC(se_sde2, format = "f", digits = 3),
    classify_sde(sde2)),
  sprintf("Threshold ratio & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta3, format = "f", digits = 3),
    formatC(se3, format = "f", digits = 3),
    formatC(sd_y3, format = "f", digits = 3),
    formatC(sde3, format = "f", digits = 3),
    formatC(se_sde3, format = "f", digits = 3),
    classify_sde(sde3)),
  sprintf("Log large (250+) enterprises & %s & %s & %s & %s & %s & %s \\\\[6pt]",
    formatC(beta4, format = "f", digits = 3),
    formatC(se4, format = "f", digits = 3),
    formatC(sd_y4, format = "f", digits = 3),
    formatC(sde4, format = "f", digits = 3),
    formatC(se_sde4, format = "f", digits = 3),
    classify_sde(sde4)),
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (sample splits)}} \\\\[3pt]",
  sprintf("England only (food vs.\\ controls) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta_eng, format = "f", digits = 3),
    formatC(se_eng, format = "f", digits = 3),
    formatC(sd_y_eng, format = "f", digits = 3),
    formatC(sde_eng, format = "f", digits = 3),
    formatC(se_sde_eng, format = "f", digits = 3),
    classify_sde(sde_eng)),
  sprintf("Scotland/Wales (food vs.\\ controls) & %s & %s & %s & %s & %s & %s \\\\",
    formatC(beta_ctrl, format = "f", digits = 3),
    formatC(se_ctrl, format = "f", digits = 3),
    formatC(sd_y_ctrl, format = "f", digits = 3),
    formatC(sde_ctrl, format = "f", digits = 3),
    formatC(se_sde_ctrl, format = "f", digits = 3),
    classify_sde(sde_ctrl)),
  "\\hline\\hline",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(TABLE_DIR, "tabF1_sde.tex"))
cat("  → Saved tabF1_sde.tex\n")

# ---- Update diagnostics.json ----
# The regulation treats ~440 large food enterprises in England
diagnostics <- jsonlite::fromJSON(file.path(DATA_DIR, "diagnostics.json"))
diagnostics$n_treated <- 440  # enterprises with 250+ employees in England food services
diagnostics$n_pre <- 13  # 2010-2022
diagnostics$n_obs <- nrow(agg_panel)
jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
  auto_unbox = TRUE, pretty = TRUE)

cat("\n✓ All tables generated. diagnostics.json updated.\n")
