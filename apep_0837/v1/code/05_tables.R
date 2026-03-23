# 05_tables.R — Generate all tables for the paper
source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")
robustness <- readRDS("../data/robustness.rds")

# ============================================================================
# Table 1: Descriptive Statistics — Long hours by country-occupation group
# ============================================================================
cat("Generating Table 1: Descriptive statistics...\n")

desc <- panel %>%
  group_by(conn_group, france) %>%
  summarise(
    mean_long_hours = mean(long_hours_pct, na.rm = TRUE),
    sd_long_hours = sd(long_hours_pct, na.rm = TRUE),
    mean_usual_hours = mean(usual_hours, na.rm = TRUE),
    sd_usual_hours = sd(usual_hours, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    group = paste0(ifelse(france == 1, "France", "Controls"), " — ", conn_group)
  ) %>%
  arrange(desc(france), desc(conn_group))

# Pre/post comparison for France high-connectivity
fr_high_pre <- panel %>%
  filter(france == 1, conn_group == "High", year < 2017) %>%
  summarise(mean = mean(long_hours_pct, na.rm = TRUE))
fr_high_post <- panel %>%
  filter(france == 1, conn_group == "High", year >= 2017) %>%
  summarise(mean = mean(long_hours_pct, na.rm = TRUE))
ctrl_high_pre <- panel %>%
  filter(france == 0, conn_group == "High", year < 2017) %>%
  summarise(mean = mean(long_hours_pct, na.rm = TRUE))
ctrl_high_post <- panel %>%
  filter(france == 0, conn_group == "High", year >= 2017) %>%
  summarise(mean = mean(long_hours_pct, na.rm = TRUE))

# Build LaTeX table
tab1_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Descriptive Statistics: Share Working $>$48 Hours per Week (\\%)}",
  "\\label{tab:descriptive}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-R2D (2010--2016)} & \\multicolumn{2}{c}{Post-R2D (2017--2024)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & Mean & SD & Mean & SD \\\\",
  "\\midrule",
  "\\textit{France} & & & & \\\\")

for (cg in c("High", "Medium", "Low")) {
  pre_stats <- panel %>% filter(france == 1, conn_group == cg, year < 2017) %>%
    summarise(m = mean(long_hours_pct, na.rm = TRUE), s = sd(long_hours_pct, na.rm = TRUE))
  post_stats <- panel %>% filter(france == 1, conn_group == cg, year >= 2017) %>%
    summarise(m = mean(long_hours_pct, na.rm = TRUE), s = sd(long_hours_pct, na.rm = TRUE))
  tab1_lines <- c(tab1_lines,
    sprintf("\\quad %s-connectivity & %.1f & %.1f & %.1f & %.1f \\\\",
            cg, pre_stats$m, pre_stats$s, post_stats$m, post_stats$s))
}

tab1_lines <- c(tab1_lines,
  "\\addlinespace",
  "\\textit{Control countries} & & & & \\\\")

for (cg in c("High", "Medium", "Low")) {
  pre_stats <- panel %>% filter(france == 0, conn_group == cg, year < 2017) %>%
    summarise(m = mean(long_hours_pct, na.rm = TRUE), s = sd(long_hours_pct, na.rm = TRUE))
  post_stats <- panel %>% filter(france == 0, conn_group == cg, year >= 2017) %>%
    summarise(m = mean(long_hours_pct, na.rm = TRUE), s = sd(long_hours_pct, na.rm = TRUE))
  tab1_lines <- c(tab1_lines,
    sprintf("\\quad %s-connectivity & %.1f & %.1f & %.1f & %.1f \\\\",
            cg, pre_stats$m, pre_stats$s, post_stats$m, post_stats$s))
}

tab1_lines <- c(tab1_lines,
  "\\addlinespace",
  sprintf("\\textit{Raw DD (High-conn.)} & \\multicolumn{2}{c}{%.1f} & \\multicolumn{2}{c}{%.1f} \\\\",
          fr_high_pre$mean - ctrl_high_pre$mean,
          fr_high_post$mean - ctrl_high_post$mean),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} High-connectivity = ISCO 1--3 (Managers, Professionals, Technicians);",
  "Medium = ISCO 5 (Services/Sales); Low = ISCO 7--9 (Craft, Plant operators, Elementary).",
  "Control countries: Germany, Netherlands, Austria, Finland, Denmark, Czech Republic, Poland, Hungary.",
  "Source: Eurostat \\texttt{lfsa\\_qoe\\_3a2}. $N = 945$ country-occupation-year cells.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab1_lines, "../tables/tab1_descriptive.tex")

# ============================================================================
# Table 2: Main Results — Triple-Difference
# ============================================================================
cat("Generating Table 2: Main DDD results...\n")

tab2_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Effect of France's Right-to-Disconnect Law on Working Hours}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Long hours ($>$48h)} & \\multicolumn{2}{c}{Usual hours} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  " & (1) & (2) & (3) & (4) \\\\",
  "\\midrule")

# Model 1: Full DDD long hours
c1 <- coef(models$m1)["france_high_post"]
s1 <- se(models$m1)["france_high_post"]
# Model 3: DD high-connectivity only
c3 <- coef(models$m3)["france_post"]
s3 <- se(models$m3)["france_post"]
# Model 2: Full DDD usual hours
c2 <- coef(models$m2)["france_high_post"]
s2 <- se(models$m2)["france_high_post"]
# Model 4: DD low-connectivity only
c4 <- coef(models$m4)["france_post"]
s4 <- se(models$m4)["france_post"]

stars <- function(p) {
  if (p < 0.01) return("$^{***}$")
  if (p < 0.05) return("$^{**}$")
  if (p < 0.1) return("$^{*}$")
  return("")
}

p1 <- pvalue(models$m1)["france_high_post"]
p2 <- pvalue(models$m2)["france_high_post"]
p3 <- pvalue(models$m3)["france_post"]
p4 <- pvalue(models$m4)["france_post"]

tab2_lines <- c(tab2_lines,
  sprintf("France $\\times$ High-conn. $\\times$ Post & %.3f%s & & %.3f%s & \\\\",
          c1, stars(p1), c2, stars(p2)),
  sprintf(" & (%.3f) & & (%.3f) & \\\\", s1, s2),
  "\\addlinespace",
  sprintf("France $\\times$ Post & & %.3f%s & & %.3f%s \\\\",
          c3, stars(p3), c4, stars(p4)),
  sprintf(" & & (%.3f) & & (%.3f) \\\\", s3, s4),
  "\\addlinespace",
  "\\midrule",
  "Sample & Full & High only & Full & Low only \\\\",
  sprintf("Observations & %d & %d & %d & %d \\\\",
          nobs(models$m1), nobs(models$m3), nobs(models$m2), nobs(models$m4)),
  "Country-occ. FE & Yes & Yes & Yes & Yes \\\\",
  "Country-year FE & Yes & & Yes & \\\\",
  "Occ.-year FE & Yes & Yes & Yes & Yes \\\\",
  sprintf("Adj.\\ $R^2$ & %.3f & %.3f & %.3f & %.3f \\\\",
          fitstat(models$m1, "ar2")[[1]], fitstat(models$m3, "ar2")[[1]],
          fitstat(models$m2, "ar2")[[1]], fitstat(models$m4, "ar2")[[1]]),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Standard errors clustered at the country level in parentheses.",
  "Columns (1) and (3) report the triple-difference estimate: France $\\times$ High-connectivity $\\times$ Post-2017.",
  "Columns (2) and (4) report simple difference-in-differences for high- and low-connectivity subsamples.",
  "High-connectivity = ISCO 1--3; Low-connectivity = ISCO 7--9.",
  "Control countries: DE, NL, AT, FI, DK, CZ, PL, HU (no R2D legislation).",
  "$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab2_lines, "../tables/tab2_main.tex")

# ============================================================================
# Table 3: Event Study Coefficients
# ============================================================================
cat("Generating Table 3: Event study...\n")

m_event <- models$m_event
ec <- data.frame(
  coef_name = names(coef(m_event)),
  estimate = as.numeric(coef(m_event)),
  se = as.numeric(se(m_event)),
  pval = as.numeric(pvalue(m_event))
)

# Parse event times from names like "event_time::-7:france * high_conn"
ec$event_time <- as.integer(str_extract(ec$coef_name, "-?\\d+"))
ec <- ec %>%
  filter(!is.na(event_time)) %>%
  mutate(year = event_time + 2017) %>%
  arrange(event_time)

tab3_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Event Study: Year-by-Year Triple-Difference Coefficients}",
  "\\label{tab:event}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Year & Estimate & SE & 95\\% CI \\\\",
  "\\midrule")

for (i in seq_len(nrow(ec))) {
  yr <- ec$year[i]
  est <- ec$estimate[i]
  s <- ec$se[i]
  ci_lo <- est - 1.96 * s
  ci_hi <- est + 1.96 * s
  st <- stars(ec$pval[i])
  marker <- ifelse(yr == 2016, " (ref.)", "")
  if (yr == 2016) next  # skip reference year
  prefix <- ifelse(yr == 2017, "\\addlinespace\n", "")
  tab3_lines <- c(tab3_lines,
    sprintf("%s%d & %.2f%s & (%.2f) & [%.2f, %.2f] \\\\",
            prefix, yr, est, st, s, ci_lo, ci_hi))
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from interacting France $\\times$ High-connectivity with year dummies.",
  "Reference year: 2016 (year before R2D law). Standard errors clustered at country level.",
  "95\\% CI based on cluster-robust $t$-distribution.",
  "$^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab3_lines, "../tables/tab3_event.tex")

# ============================================================================
# Table 4: Robustness checks
# ============================================================================
cat("Generating Table 4: Robustness...\n")

rob <- robustness
tab4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & Estimate & SE & $p$-value & $N$ \\\\",
  "\\midrule",
  "\\textit{Panel A: Main result} & & & & \\\\")

# Main
tab4_lines <- c(tab4_lines,
  sprintf("\\quad Baseline DDD & %.3f & (%.3f) & %.3f & %d \\\\",
          coef(models$m1)["france_high_post"], se(models$m1)["france_high_post"],
          pvalue(models$m1)["france_high_post"], nobs(models$m1)),
  sprintf("\\quad Permutation $p$-value & & & %.3f & \\\\", rob$perm_pval))

# Robustness
tab4_lines <- c(tab4_lines,
  "\\addlinespace",
  "\\textit{Panel B: Robustness} & & & & \\\\",
  sprintf("\\quad Exclude COVID (2020--21) & %.3f & (%.3f) & %.3f & %d \\\\",
          coef(rob$nocovid)["france_high_post"], se(rob$nocovid)["france_high_post"],
          pvalue(rob$nocovid)["france_high_post"], nobs(rob$nocovid)),
  sprintf("\\quad Usual weekly hours & %.3f & (%.3f) & %.3f & %d \\\\",
          coef(models$m2)["france_high_post"], se(models$m2)["france_high_post"],
          pvalue(models$m2)["france_high_post"], nobs(models$m2)))

# Placebos
tab4_lines <- c(tab4_lines,
  "\\addlinespace",
  "\\textit{Panel C: Placebo tests} & & & & \\\\",
  sprintf("\\quad Germany as treated & %.3f%s & (%.3f) & %.3f & %d \\\\",
          coef(rob$placebo_de)["germany_high_post"],
          stars(pvalue(rob$placebo_de)["germany_high_post"]),
          se(rob$placebo_de)["germany_high_post"],
          pvalue(rob$placebo_de)["germany_high_post"], nobs(rob$placebo_de)),
  sprintf("\\quad Medium-conn. placebo & %.3f%s & (%.3f) & %.3f & %d \\\\",
          coef(rob$placebo_mid)["france_mid_post"],
          stars(pvalue(rob$placebo_mid)["france_mid_post"]),
          se(rob$placebo_mid)["france_mid_post"],
          pvalue(rob$placebo_mid)["france_mid_post"], nobs(rob$placebo_mid)))

if (!is.null(rob$spain)) {
  tab4_lines <- c(tab4_lines,
    sprintf("\\quad Spain R2D (2018) & %.3f & (%.3f) & %.3f & %d \\\\",
            coef(rob$spain)["spain_high_post"], se(rob$spain)["spain_high_post"],
            pvalue(rob$spain)["spain_high_post"], nobs(rob$spain)))
}

# Pre-trend
tab4_lines <- c(tab4_lines,
  sprintf("\\quad Pre-trend (fake 2014) & %.3f & (%.3f) & %.3f & %d \\\\",
          coef(rob$pretrend)["france_high_fakepost"], se(rob$pretrend)["france_high_fakepost"],
          pvalue(rob$pretrend)["france_high_fakepost"], nobs(rob$pretrend)))

tab4_lines <- c(tab4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:} Panel A reports the main triple-difference estimate and its permutation $p$-value (1,000 draws).",
  "Panel B tests sensitivity to COVID exclusion and an alternative outcome variable.",
  "Panel C: Germany placebo assigns fake treatment to Germany (no R2D law);",
  "medium-connectivity placebo uses ISCO 5 (services/sales) vs.~ISCO 7--9;",
  "Spain adopted R2D in 2018; pre-trend test assigns fake treatment at 2014 using 2010--2016 data only.",
  "All specifications include country-occupation, country-year, and occupation-year fixed effects.",
  "Standard errors clustered at country level. $^{*}p<0.1$; $^{**}p<0.05$; $^{***}p<0.01$.",
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tab4_lines, "../tables/tab4_robustness.tex")

# ============================================================================
# Table F1: SDE Appendix
# ============================================================================
cat("Generating SDE table...\n")

# Compute SDEs
sd_y_pre <- sd(panel$long_hours_pct[panel$year < 2017], na.rm = TRUE)
sd_y_usual_pre <- sd(panel$usual_hours[panel$year < 2017], na.rm = TRUE)

beta_lh <- coef(models$m1)["france_high_post"]
se_lh <- se(models$m1)["france_high_post"]
sde_lh <- beta_lh / sd_y_pre
se_sde_lh <- se_lh / sd_y_pre

beta_uh <- coef(models$m2)["france_high_post"]
se_uh <- se(models$m2)["france_high_post"]
sde_uh <- beta_uh / sd_y_usual_pre
se_sde_uh <- se_uh / sd_y_usual_pre

classify <- function(sde) {
  if (sde < -0.15) return("Large negative")
  if (sde < -0.05) return("Moderate negative")
  if (sde < -0.005) return("Small negative")
  if (sde <= 0.005) return("Null")
  if (sde <= 0.05) return("Small positive")
  if (sde <= 0.15) return("Moderate positive")
  return("Large positive")
}

class_lh <- classify(sde_lh)
class_uh <- classify(sde_uh)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} France (treatment); Germany, Netherlands, Austria, Finland, Denmark, ",
  "Czech Republic, Poland, Hungary (controls). ",
  "\\textbf{Research question:} Does mandatory right-to-disconnect legislation reduce long ",
  "working hours among digitally connected workers relative to manually oriented workers? ",
  "\\textbf{Policy mechanism:} The Loi El Khomri (2017) requires firms with 50 or more ",
  "employees to negotiate annually on modalities for disconnecting from digital work ",
  "communications outside working hours, aiming to curb after-hours email culture. ",
  "\\textbf{Outcome definition:} Share of workers reporting more than 48 hours per week ",
  "(Eurostat lfsa\\_qoe\\_3a2) and usual weekly hours for full-time workers (Eurostat lfsa\\_ewhais), ",
  "both measured at the country-occupation-year level. ",
  "\\textbf{Treatment:} Binary (France post-2017 vs.\\ controls), interacted with occupational ",
  "connectivity (high: ISCO 1--3 vs.\\ low: ISCO 7--9). ",
  "\\textbf{Data:} Eurostat Labour Force Survey aggregates, 9 countries, 7 ISCO major groups, ",
  "15 years (2010--2024), $N = 945$ country-occupation-year cells. ",
  "\\textbf{Method:} Triple-difference with country-occupation, country-year, and occupation-year ",
  "fixed effects; standard errors clustered at country level; permutation inference (1,000 draws). ",
  "\\textbf{Sample:} EU countries without R2D legislation during sample period; Spain (2018), ",
  "Portugal (2021), Belgium (2023), Italy excluded as contaminated controls. ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
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
  sprintf("Long hours ($>$48h) & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_lh, se_lh, sd_y_pre, sde_lh, se_sde_lh, class_lh),
  sprintf("Usual weekly hours & %.3f & %.3f & %.2f & %.4f & %.4f & %s \\\\",
          beta_uh, se_uh, sd_y_usual_pre, sde_uh, se_sde_uh, class_uh),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  sde_notes,
  "\\end{tablenotes}",
  "\\end{table}")

writeLines(tabF1_lines, "../tables/tabF1_sde.tex")

cat("All tables generated.\n")
cat(sprintf("SDE long hours: %.4f (%s)\n", sde_lh, class_lh))
cat(sprintf("SDE usual hours: %.4f (%s)\n", sde_uh, class_uh))
cat(sprintf("SD(Y) pre-treatment long hours: %.2f\n", sd_y_pre))
cat(sprintf("SD(Y) pre-treatment usual hours: %.2f\n", sd_y_usual_pre))
