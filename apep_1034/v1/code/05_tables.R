## 05_tables.R — Generate all LaTeX tables (including SDE)
## apep_1034: Norway Wind Resource Rent Tax
## Main specification: Model 3 (sector-specific linear trend)

source("00_packages.R")

# ============================================================
# Load results
# ============================================================
monthly_panel <- readRDS("../data/monthly_panel.rds")
county_panel <- readRDS("../data/county_panel.rds")
sumstats <- readRDS("../data/sumstats_monthly.rds")
pre_stats <- readRDS("../data/pre_stats.rds")
results <- readRDS("../data/model_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")

dir.create("../tables", showWarnings = FALSE)

# ============================================================
# SDE classification function
# ============================================================
classify_sde <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("Generating Table 1: Summary Statistics...\n")

sumstat_detail <- monthly_panel %>%
  mutate(period = ifelse(post == 0, "Pre (2018--2022)", "Post (2023--2024)")) %>%
  group_by(sector, period) %>%
  summarise(
    n = n(),
    mean = mean(gwh, na.rm = TRUE),
    sd = sd(gwh, na.rm = TRUE),
    min = min(gwh, na.rm = TRUE),
    max = max(gwh, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(sector), period)

tab1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Monthly Electricity Production (GWh)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{llccccc}\n",
  "\\toprule\n",
  "Sector & Period & N & Mean & Std.\\ Dev. & Min & Max \\\\\n",
  "\\midrule\n"
)

for (i in seq_len(nrow(sumstat_detail))) {
  r <- sumstat_detail[i, ]
  sector_label <- ifelse(r$sector == "wind", "Wind", "Hydropower")
  tab1 <- paste0(tab1, sprintf("%s & %s & %d & %s & %s & %s & %s \\\\\n",
                                sector_label, r$period, r$n,
                                format(round(r$mean, 1), big.mark = ","),
                                format(round(r$sd, 1), big.mark = ","),
                                format(round(r$min, 1), big.mark = ","),
                                format(round(r$max, 1), big.mark = ",")))
  if (i == 2) tab1 <- paste0(tab1, "\\midrule\n")
}

tab1 <- paste0(tab1,
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Monthly electricity production in gigawatt-hours (GWh) from Statistics Norway ",
  "(SSB Table 14091). Pre-period: January 2018 through December 2022. Post-period: January 2023 through ",
  "December 2024. Wind = onshore wind power. Hydropower = conventional hydroelectric power. ",
  "N = ", nrow(monthly_panel), " sector-month observations.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# Table 2: Main DiD Results
# ============================================================
cat("Generating Table 2: Main DiD Results...\n")

m1 <- results$m1  # levels
m2 <- results$m2  # log, no trends
m3 <- results$m3  # log, with trends (MAIN)
m_growth <- rob_results$m_growth  # growth rate

get_coef_str <- function(model, var) {
  b <- coef(model)[var]
  s <- se(model)[var]
  p <- pvalue(model)[var]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))
  c(sprintf("%.3f%s", b, stars), sprintf("(%.3f)", s))
}

c1 <- get_coef_str(m1, "treat")
c2 <- get_coef_str(m2, "treat")
c3 <- get_coef_str(m3, "treat")
c4 <- get_coef_str(m_growth, "treat")

# Implied percent changes
pct_m3 <- sprintf("%.1f\\%%", (exp(coef(m3)["treat"]) - 1) * 100)
pct_gr <- sprintf("%.1f pp", coef(m_growth)["treat"] * 100)

tab2 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of Wind Resource Rent Tax Announcement on Electricity Production}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & GWh & Log GWh & Log GWh & $\\Delta$ Log GWh \\\\\n",
  " & Levels & No trend & Trend-adjusted & Growth rate \\\\\n",
  "\\midrule\n",
  sprintf("Wind $\\times$ Post & %s & %s & %s & %s \\\\\n", c1[1], c2[1], c3[1], c4[1]),
  sprintf("                    & %s & %s & %s & %s \\\\\n", c1[2], c2[2], c3[2], c4[2]),
  " & & & & \\\\\n",
  sprintf("Implied change & & & %s & %s \\\\\n", pct_m3, pct_gr),
  " & & & & \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m_growth), big.mark = ",")),
  "Fixed effects & Sector, Month & Sector, Month & Sector, Month & Sector, Month \\\\\n",
  "Sector trend & No & No & Linear & No \\\\\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Difference-in-differences estimates of the effect of Norway's December 2022 ",
  "resource rent tax announcement on electricity production. Treatment group: onshore wind power. ",
  "Control group: hydropower. All columns use the national monthly panel (January 2018--December 2024). ",
  "Column (1): levels in GWh. Column (2): log GWh without trend adjustment. ",
  "Column (3): log GWh with a sector-specific linear time trend (preferred specification). ",
  "Column (4): year-over-year change in log GWh (12-month difference). ",
  "Post = January 2023 onward. ``Implied change'' translates the coefficient to percentage terms ",
  "(column 3) or percentage-point growth change (column 4). ",
  "Standard errors in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# Table 3: Robustness and Placebo Tests
# ============================================================
cat("Generating Table 3: Robustness...\n")

rob <- rob_results

fmt_rob <- function(label, beta, se_val, pval = NA) {
  if (is.na(pval)) pval <- 2 * pnorm(-abs(beta / se_val))
  stars <- ifelse(pval < 0.01, "***", ifelse(pval < 0.05, "**", ifelse(pval < 0.10, "*", "")))
  sprintf("%s & %.3f%s & (%.3f) \\\\\n", label, beta, stars, se_val)
}

tab3 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness Checks and Placebo Tests}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcc}\n",
  "\\toprule\n",
  "Specification & Estimate & Std.\\ Error \\\\\n",
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel A: Main and alternative specifications}} \\\\\n",
  fmt_rob("Main (log GWh, linear trend)", coef(results$m3)["treat"], se(results$m3)["treat"],
          pvalue(results$m3)["treat"]),
  fmt_rob("Quadratic sector trend", rob$quadratic$beta, rob$quadratic$se),
  fmt_rob("Year-over-year growth rate", rob$growth_rate$beta, rob$growth_rate$se),
  fmt_rob("Uncertainty window only (2023)",
          rob$uncertainty_window$beta, rob$uncertainty_window$se),
  fmt_rob("Post-enactment only (2024+)",
          rob$enactment_only$beta, rob$enactment_only$se),
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel B: Placebo treatment dates (trend-adjusted)}} \\\\\n"
)

for (pd in names(rob$placebo)) {
  p <- rob$placebo[[pd]]
  tab3 <- paste0(tab3, fmt_rob(sprintf("Placebo: %s", pd), p$beta, p$se, p$pval))
}

if (!is.na(rob$cross_country$beta)) {
  tab3 <- paste0(tab3,
    "\\midrule\n",
    "\\multicolumn{3}{l}{\\textit{Panel C: Cross-country placebo}} \\\\\n",
    fmt_rob("Norway vs.\\ Sweden/Denmark wind (with trends)",
            rob$cross_country$beta, rob$cross_country$se)
  )
}

tab3 <- paste0(tab3,
  "\\midrule\n",
  "\\multicolumn{3}{l}{\\textit{Panel D: Heterogeneity by season}} \\\\\n",
  fmt_rob("Winter (Oct--Mar)", rob$winter$beta, rob$winter$se),
  fmt_rob("Summer (Apr--Sep)", rob$summer$beta, rob$summer$se),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications in Panels A, B, and D include sector-specific linear time ",
  "trends unless otherwise noted. Panel A shows the main estimate under alternative specifications. ",
  "``Uncertainty window'' restricts the post-period to January--December 2023 (between announcement ",
  "and enactment). ``Post-enactment'' drops 2023 and compares pre-announcement to January 2024 onward. ",
  "Panel B reports placebo DiD estimates using false treatment dates within the pre-period; the ",
  "null results confirm the validity of the trend-adjusted specification. ",
  "Panel C uses Eurostat monthly data comparing Norwegian wind production growth to Sweden and Denmark. ",
  "Panel D splits the sample by season. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tab3, "../tables/tab3_robustness.tex")

# ============================================================
# Table 4: Cross-country comparison (descriptive)
# ============================================================
cat("Generating Table 4: Cross-country comparison...\n")

eurostat_file_path <- "../data/eurostat_panel.rds"
has_eurostat <- file.exists(eurostat_file_path)

if (has_eurostat) {
  eurostat_panel <- readRDS("../data/eurostat_panel.rds")

  euro_annual <- eurostat_panel %>%
    group_by(country, year) %>%
    summarise(total_gwh = sum(gwh, na.rm = TRUE), .groups = "drop") %>%
    group_by(country) %>%
    arrange(year) %>%
    mutate(growth_pct = (total_gwh / dplyr::lag(total_gwh) - 1) * 100) %>%
    ungroup() %>%
    filter(year >= 2020) %>%
    select(country, year, total_gwh, growth_pct)

  tab4 <- paste0(
    "\\begin{table}[H]\n",
    "\\centering\n",
    "\\caption{Wind Production Growth: Norway vs.\\ Nordic Comparators}\n",
    "\\label{tab:cross_country}\n",
    "\\begin{threeparttable}\n",
    "\\begin{tabular}{lcccccc}\n",
    "\\toprule\n",
    " & \\multicolumn{2}{c}{Norway} & \\multicolumn{2}{c}{Sweden} & \\multicolumn{2}{c}{Denmark} \\\\\n",
    "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7}\n",
    "Year & GWh & Growth & GWh & Growth & GWh & Growth \\\\\n",
    "\\midrule\n"
  )

  for (y in 2020:2024) {
    no <- euro_annual %>% filter(country == "NO", year == y)
    se <- euro_annual %>% filter(country == "SE", year == y)
    dk <- euro_annual %>% filter(country == "DK", year == y)

    fmt_g <- function(x) ifelse(is.na(x$growth_pct), "---",
                                sprintf("%+.1f\\%%", x$growth_pct))

    tab4 <- paste0(tab4, sprintf("%d & %s & %s & %s & %s & %s & %s \\\\\n",
                                  y,
                                  format(round(no$total_gwh), big.mark = ","),
                                  fmt_g(no),
                                  format(round(se$total_gwh), big.mark = ","),
                                  fmt_g(se),
                                  format(round(dk$total_gwh), big.mark = ","),
                                  fmt_g(dk)))
    if (y == 2022) tab4 <- paste0(tab4, "\\midrule\n")
  }

  tab4 <- paste0(tab4,
    "\\bottomrule\n",
    "\\end{tabular}\n",
    "\\begin{tablenotes}[flushleft]\n",
    "\\small\n",
    "\\item \\textit{Notes:} Annual wind power production (GWh) and year-over-year growth rates from Eurostat ",
    "(dataset nrg\\_cb\\_pem). Norway announced a resource rent tax on onshore wind in December 2022 ",
    "(horizontal line). Sweden and Denmark imposed no comparable tax. Norwegian wind production declined ",
    "in 2023 while Swedish and Danish wind production continued growing.\n",
    "\\end{tablenotes}\n",
    "\\end{threeparttable}\n",
    "\\end{table}\n"
  )

  writeLines(tab4, "../tables/tab4_cross_country.tex")
}

# ============================================================
# Table F1: Standardized Effect Sizes (SDE) — MANDATORY
# ============================================================
cat("Generating Table F1: Standardized Effect Sizes...\n")

# Main estimate from Model 3 (trend-adjusted)
m3 <- results$m3
beta_pooled <- coef(m3)["treat"]
se_pooled <- se(m3)["treat"]
sd_y <- pre_stats$pre_sd_log[pre_stats$sector == "wind"]

sde_pooled <- beta_pooled / sd_y
se_sde_pooled <- se_pooled / sd_y

# Heterogeneity: winter vs summer (trend-adjusted)
beta_winter <- rob_results$winter$beta
se_winter <- rob_results$winter$se
beta_summer <- rob_results$summer$beta
se_summer <- rob_results$summer$se

# Pre-treatment SD for winter/summer
monthly_panel_s <- monthly_panel %>%
  mutate(winter = as.integer(month %in% c(10, 11, 12, 1, 2, 3)))

sd_y_winter <- sd(monthly_panel_s$log_gwh[monthly_panel_s$sector == "wind" &
                    monthly_panel_s$post == 0 & monthly_panel_s$winter == 1], na.rm = TRUE)
sd_y_summer <- sd(monthly_panel_s$log_gwh[monthly_panel_s$sector == "wind" &
                    monthly_panel_s$post == 0 & monthly_panel_s$winter == 0], na.rm = TRUE)

sde_winter <- beta_winter / sd_y_winter
se_sde_winter <- se_winter / sd_y_winter
sde_summer <- beta_summer / sd_y_summer
se_sde_summer <- se_summer / sd_y_summer

# Format rows
fmt_sde_row <- function(outcome, beta, se_b, sd_y_val, sde_val, se_sde_val) {
  class_label <- classify_sde(sde_val)
  sprintf("%s & %.3f & (%.3f) & %.3f & %.3f & (%.3f) & %s \\\\\n",
          outcome, beta, se_b, sd_y_val, sde_val, se_sde_val, class_label)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Norway. ",
  "\\textbf{Research question:} Whether the surprise announcement of a resource rent tax on onshore wind power ",
  "chilled renewable energy production relative to the untaxed hydropower sector. ",
  "\\textbf{Policy mechanism:} In December 2022 the Norwegian government announced a 40\\% effective resource rent ",
  "tax on onshore wind power revenue, creating regulatory uncertainty for 12 months until final enactment at a ",
  "reduced 25\\% rate in January 2024; existing projects faced retroactive application and new projects confronted ",
  "fundamentally altered investment economics. ",
  "\\textbf{Outcome definition:} Log monthly electricity production in GWh from Statistics Norway Table 14091, ",
  "measuring gross generation by energy source; the estimand is the deviation from a sector-specific linear trend. ",
  "\\textbf{Treatment:} Binary; wind sector (treated) vs.\\ hydropower sector (control) after December 2022 announcement. ",
  "\\textbf{Data:} Statistics Norway (SSB) Table 14091, monthly electricity production by source, January 2018--December 2024, ",
  "168 sector-month observations. ",
  "\\textbf{Method:} Two-way fixed effects DiD with sector and month fixed effects plus a sector-specific linear ",
  "time trend; single sharp treatment date (no staggered adoption). ",
  "\\textbf{Sample:} National monthly production for wind and hydropower sectors; all Norwegian onshore generation included. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation of log monthly production for the wind sector. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  fmt_sde_row("Wind production (log GWh)", beta_pooled, se_pooled, sd_y, sde_pooled, se_sde_pooled),
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by season)}} \\\\\n",
  fmt_sde_row("Winter months (Oct--Mar)", beta_winter, se_winter, sd_y_winter, sde_winter, se_sde_winter),
  fmt_sde_row("Summer months (Apr--Sep)", beta_summer, se_summer, sd_y_summer, sde_summer, se_sde_summer),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\\sloppy\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1, "../tables/tabF1_sde.tex")

# Print SDE values
cat("\n=== SDE SUMMARY ===\n")
cat(sprintf("Pooled:  beta=%.3f, SD(Y)=%.3f, SDE = %.4f (%s)\n",
            beta_pooled, sd_y, sde_pooled, classify_sde(sde_pooled)))
cat(sprintf("Winter:  beta=%.3f, SD(Y)=%.3f, SDE = %.4f (%s)\n",
            beta_winter, sd_y_winter, sde_winter, classify_sde(sde_winter)))
cat(sprintf("Summer:  beta=%.3f, SD(Y)=%.3f, SDE = %.4f (%s)\n",
            beta_summer, sd_y_summer, sde_summer, classify_sde(sde_summer)))

cat("\n=== ALL TABLES GENERATED ===\n")
