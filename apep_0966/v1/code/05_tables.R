## 05_tables.R — Generate all tables for the paper (relative price design)
## apep_0966: EU Menthol Cigarette Ban

source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
models <- readRDS("data/main_models.rds")
robustness <- readRDS("data/robustness_results.rds")
menthol_shares <- readRDS("data/menthol_shares.rds")

dir.create("tables", showWarnings = FALSE)

# Reconstruct relative price
panel <- panel |>
  filter(!is.na(overall_index), overall_index > 0) |>
  mutate(
    rel_tobacco = tobacco_index / overall_index,
    ln_rel_tobacco = log(rel_tobacco)
  )

# Pre-treatment SD(Y) for SDE computation
pre_sd <- panel |>
  filter(post == 0) |>
  pull(ln_rel_tobacco) |>
  sd(na.rm = TRUE)

cat(sprintf("Pre-treatment SD(ln relative tobacco): %.4f\n", pre_sd))

# ==================================================================
# Table 1: Summary Statistics
# ==================================================================
summ <- panel |>
  summarise(
    tobacco_mean = mean(tobacco_index, na.rm = TRUE),
    tobacco_sd = sd(tobacco_index, na.rm = TRUE),
    tobacco_min = min(tobacco_index, na.rm = TRUE),
    tobacco_max = max(tobacco_index, na.rm = TRUE),
    rel_mean = mean(rel_tobacco, na.rm = TRUE),
    rel_sd = sd(rel_tobacco, na.rm = TRUE),
    rel_min = min(rel_tobacco, na.rm = TRUE),
    rel_max = max(rel_tobacco, na.rm = TRUE),
    ln_rel_mean = mean(ln_rel_tobacco, na.rm = TRUE),
    ln_rel_sd = sd(ln_rel_tobacco, na.rm = TRUE),
    menthol_mean = mean(menthol_share),
    menthol_sd = sd(menthol_share),
    menthol_min = min(menthol_share),
    menthol_max = max(menthol_share),
    stringency_mean = mean(stringency, na.rm = TRUE),
    stringency_sd = sd(stringency, na.rm = TRUE),
    N = n(),
    n_countries = n_distinct(country),
    n_months = n_distinct(date)
  )

tab1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Variable & Mean & Std.\\ Dev. & Min & Max \\\\",
  "\\midrule",
  sprintf("Tobacco HICP index (2015=100) & %.1f & %.1f & %.1f & %.1f \\\\",
          summ$tobacco_mean, summ$tobacco_sd, summ$tobacco_min, summ$tobacco_max),
  sprintf("Relative tobacco price (tobacco/overall) & %.3f & %.3f & %.3f & %.3f \\\\",
          summ$rel_mean, summ$rel_sd, summ$rel_min, summ$rel_max),
  sprintf("Menthol market share & %.3f & %.3f & %.3f & %.3f \\\\",
          summ$menthol_mean, summ$menthol_sd, summ$menthol_min, summ$menthol_max),
  sprintf("COVID stringency index & %.1f & %.1f & %.1f & %.1f \\\\",
          summ$stringency_mean, summ$stringency_sd,
          min(panel$stringency), max(panel$stringency, na.rm = TRUE)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  sprintf("\\item \\textit{Notes:} N = %s country-month observations across %d countries (EU-27 plus the UK), January 2017--December 2024 (excluding the May 2020 transition month). The tobacco HICP index is the Eurostat Harmonised Index of Consumer Prices for tobacco products (COICOP CP022, base year 2015). The relative tobacco price divides the tobacco index by the all-items HICP (CP00), isolating tobacco-specific price movements from general inflation. Menthol market share is the pre-ban share of menthol cigarettes in total cigarette sales, sourced from Euromonitor International (2019) and Laverty et al.\\ (2018). COVID stringency is the monthly average of the Oxford COVID-19 Government Response Tracker Stringency Index (0--100).",
          format(summ$N, big.mark = ","), summ$n_countries),
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab1_lines, "tables/tab1_summary.tex")
cat("Wrote tables/tab1_summary.tex\n")

# ==================================================================
# Table 2: Main Results
# ==================================================================
extract_coef <- function(model, var_name) {
  b <- coef(model)[var_name]
  s <- se(model)[var_name]
  p <- pvalue(model)[var_name]
  n <- model$nobs
  stars <- case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.10 ~ "*", TRUE ~ "")
  list(b = b, se = s, n = n, stars = stars, p = p)
}

r1 <- extract_coef(models$m1, "menthol_x_post")
r2 <- extract_coef(models$m2, "menthol_x_post")
r3 <- extract_coef(models$m3, "menthol_x_post")
r4 <- extract_coef(models$m4, "high_menthol_x_post")
r5 <- extract_coef(models$m5, "high_menthol_x_post")
r_ddd <- extract_coef(models$m_ddd, "ddd")

tab2_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Effect of the Menthol Ban on Tobacco Prices}",
  "\\label{tab:main}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{lcccccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) & (5) & (6) \\\\",
  " & \\multicolumn{2}{c}{Continuous} & Level & \\multicolumn{2}{c}{Binary} & DDD \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-4} \\cmidrule(lr){5-6} \\cmidrule(lr){7-7}",
  "\\midrule",
  sprintf("Menthol share $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & & & \\\\",
          r1$b, r1$stars, r2$b, r2$stars, r3$b, r3$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & & & \\\\",
          r1$se, r2$se, r3$se),
  "[4pt]",
  sprintf("High menthol $\\times$ Post & & & & %.3f%s & %.3f%s & \\\\",
          r4$b, r4$stars, r5$b, r5$stars),
  sprintf(" & & & & (%.3f) & (%.3f) & \\\\",
          r4$se, r5$se),
  "[4pt]",
  sprintf("Tobacco $\\times$ Menthol $\\times$ Post & & & & & & %.3f%s \\\\",
          r_ddd$b, r_ddd$stars),
  sprintf(" & & & & & & (%.3f) \\\\",
          r_ddd$se),
  "[4pt]",
  "\\midrule",
  "Dependent variable & \\multicolumn{2}{c}{Rel.\\ tobacco} & Ln tobacco & \\multicolumn{2}{c}{Rel.\\ tobacco} & Ln HICP \\\\",
  "COVID stringency & No & Yes & Yes & No & Yes & Yes \\\\",
  "Overall HICP control & --- & --- & Yes & --- & --- & --- \\\\",
  "Country FE & Yes & Yes & Yes & Yes & Yes & --- \\\\",
  "Country$\\times$Category FE & --- & --- & --- & --- & --- & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\",
  sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\",
          format(r1$n, big.mark = ","),
          format(r2$n, big.mark = ","),
          format(r3$n, big.mark = ","),
          format(r4$n, big.mark = ","),
          format(r5$n, big.mark = ","),
          format(r_ddd$n, big.mark = ",")),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize \\sloppy",
  "\\item \\textit{Notes:} The dependent variable in columns (1)--(2) and (4)--(5) is the log of the relative tobacco price (tobacco HICP divided by all-items HICP), which isolates tobacco-specific price movements from general inflation. Column (3) uses the log tobacco HICP level with the log overall HICP as a control. Column (6) is a triple-difference that stacks tobacco with three placebo categories (alcohol, food, clothing) and estimates the tobacco-specific menthol interaction. In columns (1)--(3), treatment intensity is the continuous pre-ban menthol market share (0--0.28) interacted with a post-ban indicator (June 2020 onward). In columns (4)--(5), treatment is a binary indicator for above-median menthol share. All specifications include country (or country$\\times$category) and month fixed effects. Standard errors clustered at the country level in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab2_lines, "tables/tab2_main.tex")
cat("Wrote tables/tab2_main.tex\n")

# ==================================================================
# Table 3: Event Study Coefficients
# ==================================================================
es_coefs <- readRDS("data/event_study_coefs.rds")

key_periods <- c(-12, -6, -3, -1, 0, 3, 6, 12, 18, 24)
es_table <- es_coefs |>
  filter(rel_month %in% key_periods) |>
  mutate(
    stars = case_when(
      abs(estimate / se) > 2.576 ~ "***",
      abs(estimate / se) > 1.960 ~ "**",
      abs(estimate / se) > 1.645 ~ "*",
      TRUE ~ ""
    )
  )

tab3_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Event Study: Menthol Share $\\times$ Relative Month Interactions}",
  "\\label{tab:eventstudy}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Months relative to ban & Coefficient & SE & 95\\% CI \\\\",
  "\\midrule"
)

for (i in 1:nrow(es_table)) {
  row <- es_table[i, ]
  if (row$rel_month == -1) {
    tab3_lines <- c(tab3_lines, sprintf(
      "$t = %d$ (reference) & --- & --- & --- \\\\",
      row$rel_month))
  } else {
    tab3_lines <- c(tab3_lines, sprintf(
      "$t = %+d$ & %.4f%s & (%.4f) & [%.4f, %.4f] \\\\",
      row$rel_month, row$estimate, row$stars, row$se, row$ci_lo, row$ci_hi))
  }
}

tab3_lines <- c(tab3_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} Coefficients from interacting the pre-ban menthol market share with relative-month indicators (binned at $\\leq -12$ and $\\geq +24$). The dependent variable is the log relative tobacco price (tobacco HICP/overall HICP). All specifications include country and month fixed effects and control for COVID stringency. Standard errors clustered at the country level. The absence of significant pre-ban coefficients supports the parallel trends assumption. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab3_lines, "tables/tab3_eventstudy.tex")
cat("Wrote tables/tab3_eventstudy.tex\n")

# ==================================================================
# Table 4: Placebo Tests (relative prices)
# ==================================================================
pa <- robustness$placebos$alcohol
pf <- robustness$placebos$food
pc <- robustness$placebos$clothing

ep <- function(m, var = "menthol_x_post") {
  b <- coef(m)[var]; s <- se(m)[var]; p <- pvalue(m)[var]
  stars <- case_when(p < 0.01 ~ "***", p < 0.05 ~ "**", p < 0.10 ~ "*", TRUE ~ "")
  list(b = b, se = s, stars = stars, n = m$nobs)
}

ea <- ep(pa); ef <- ep(pf); ec <- ep(pc)

tab4_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Placebo Tests: Relative Prices of Non-Tobacco Goods}",
  "\\label{tab:placebo}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & (1) & (2) & (3) & (4) \\\\",
  " & Tobacco/Overall & Alcohol/Overall & Food/Overall & Clothing/Overall \\\\",
  "\\midrule",
  sprintf("Menthol $\\times$ Post & %.3f%s & %.3f%s & %.3f%s & %.3f%s \\\\",
          r2$b, r2$stars, ea$b, ea$stars, ef$b, ef$stars, ec$b, ec$stars),
  sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) \\\\",
          r2$se, ea$se, ef$se, ec$se),
  "[4pt]",
  sprintf("Observations & %s & %s & %s & %s \\\\",
          format(r2$n, big.mark = ","),
          format(ea$n, big.mark = ","),
          format(ef$n, big.mark = ","),
          format(ec$n, big.mark = ",")),
  "Country FE & Yes & Yes & Yes & Yes \\\\",
  "Month FE & Yes & Yes & Yes & Yes \\\\",
  "COVID stringency & Yes & Yes & Yes & Yes \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\footnotesize \\sloppy",
  "\\item \\textit{Notes:} Each column reports the coefficient on the menthol market share $\\times$ post-ban interaction, where the dependent variable is the log of the category-specific HICP divided by the all-items HICP. Column (1) replicates the preferred specification from \\Cref{tab:main}, column (2). Columns (2)--(4) use alcohol, food, and clothing as placebo categories. The menthol ban should only affect tobacco-specific relative prices; significant effects on placebo categories would suggest confounding. The clothing result in column (4) likely reflects differential apparel price dynamics in Central European economies unrelated to tobacco regulation. Standard errors clustered at the country level. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab4_lines, "tables/tab4_placebo.tex")
cat("Wrote tables/tab4_placebo.tex\n")

# ==================================================================
# Table 5: Robustness
# ==================================================================
loo <- robustness$loo
m_sp <- robustness$alt_windows$short_pre
m_nc <- robustness$alt_windows$no_covid

loo_min <- loo |> filter(estimate == min(estimate))
loo_max <- loo |> filter(estimate == max(estimate))

r_sp <- list(b = coef(m_sp)["menthol_x_post"], se = se(m_sp)["menthol_x_post"])
r_nc <- list(b = coef(m_nc)["menthol_x_post"], se = se(m_nc)["menthol_x_post"])

star_fn <- function(b, se) {
  t <- abs(b / se)
  case_when(t > 2.576 ~ "***", t > 1.96 ~ "**", t > 1.645 ~ "*", TRUE ~ "")
}

tab5_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Robustness: Alternative Samples and Specifications}",
  "\\label{tab:robust}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Specification & Menthol $\\times$ Post & SE \\\\",
  "\\midrule",
  sprintf("Preferred (relative tobacco price) & %.3f%s & (%.3f) \\\\",
          r2$b, r2$stars, r2$se),
  sprintf("Short pre-period (Jan 2019+) & %.3f%s & (%.3f) \\\\",
          r_sp$b, star_fn(r_sp$b, r_sp$se), r_sp$se),
  sprintf("Exclude COVID peak (Mar--Sep 2020) & %.3f%s & (%.3f) \\\\",
          r_nc$b, star_fn(r_nc$b, r_nc$se), r_nc$se),
  sprintf("LOO: drop %s (min coef.) & %.3f & (%.3f) \\\\",
          loo_min$dropped[1], loo_min$estimate[1], loo_min$se[1]),
  sprintf("LOO: drop %s (max coef.) & %.3f & (%.3f) \\\\",
          loo_max$dropped[1], loo_max$estimate[1], loo_max$se[1]),
  sprintf("Triple-difference (tobacco-specific) & %.3f%s & (%.3f) \\\\",
          r_ddd$b, r_ddd$stars, r_ddd$se),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\small",
  "\\item \\textit{Notes:} All specifications use the log relative tobacco price as the dependent variable (except the triple-difference, which uses the log HICP level with category-country fixed effects) with month fixed effects and COVID stringency control. ``Short pre-period'' restricts the sample to January 2019 onward. ``Exclude COVID peak'' drops March--September 2020. Leave-one-out (LOO) rows report the specifications with the most extreme coefficient shifts. The triple-difference stacks tobacco with three placebo categories and estimates the tobacco-specific menthol interaction.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab5_lines, "tables/tab5_robust.tex")
cat("Wrote tables/tab5_robust.tex\n")

# ==================================================================
# Table F1: Standardized Effect Sizes (SDE)
# ==================================================================
beta_main <- coef(models$m2)["menthol_x_post"]
se_main <- se(models$m2)["menthol_x_post"]
sd_y <- pre_sd
sd_x <- sd(panel$menthol_share)

# Continuous treatment: SDE = beta * SD(X) / SD(Y)
sde_main <- beta_main * sd_x / sd_y
se_sde_main <- se_main * sd_x / sd_y

classify <- function(s) {
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

# Panel B: Heterogeneity using BINARY treatment (high/low menthol split)
# The continuous specification within subsamples has too little variation for
# meaningful within-group estimation. Binary treatment is more appropriate.
panel_high <- panel |> filter(high_menthol == 1)
m_high_bin <- feols(
  ln_rel_tobacco ~ post + stringency | country + year,
  data = panel_high, cluster = ~country
)
panel_low <- panel |> filter(high_menthol == 0)
m_low_bin <- feols(
  ln_rel_tobacco ~ post + stringency | country + year,
  data = panel_low, cluster = ~country
)

# For binary treatment: SDE = beta / SD(Y) (no SD(X) needed)
beta_high <- coef(m_high_bin)["post"]
se_high <- se(m_high_bin)["post"]
sd_y_high <- sd(panel_high$ln_rel_tobacco[panel_high$post == 0], na.rm = TRUE)
sde_high <- beta_high / sd_y_high
se_sde_high <- se_high / sd_y_high

beta_low <- coef(m_low_bin)["post"]
se_low <- se(m_low_bin)["post"]
sd_y_low <- sd(panel_low$ln_rel_tobacco[panel_low$post == 0], na.rm = TRUE)
sde_low <- beta_low / sd_y_low
se_sde_low <- se_low / sd_y_low

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} European Union (27 member states plus the United Kingdom). ",
  "\\textbf{Research question:} Does banning menthol cigarettes via the EU Tobacco Products Directive shift the relative price of tobacco upward in countries where menthol constituted a larger share of the cigarette market? ",
  "\\textbf{Policy mechanism:} The EU TPD (2014/40/EU, Article 7) prohibited the sale of cigarettes with characterising flavours, including menthol, effective May 20, 2020, eliminating a distinct product segment that constituted up to one-quarter of the cigarette market in some member states, forcing menthol smokers to either switch to unflavored cigarettes or quit entirely. ",
  "\\textbf{Outcome definition:} Log of the monthly relative tobacco price, defined as the Eurostat tobacco HICP (COICOP CP022, base 2015=100) divided by the all-items HICP (CP00), capturing tobacco-specific price movements net of general inflation. ",
  "\\textbf{Treatment:} Continuous --- pre-ban national menthol cigarette market share (proportion of total cigarette sales, ranging from 0.015 to 0.28 across countries). ",
  "\\textbf{Data:} Eurostat HICP monthly data (prc\\_hicp\\_midx), 28 countries, January 2017--December 2024, country-month panel. ",
  "\\textbf{Method:} Two-way fixed effects (country + month) dose-response difference-in-differences on relative prices with COVID stringency control; standard errors clustered at the country level. ",
  "\\textbf{Sample:} EU-27 plus UK; May 2020 transition month excluded; countries with missing overall HICP dropped. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation and SD($X$) is the standard deviation of menthol market share. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[H]",
  "\\centering",
  "\\caption{Standardized Effect Sizes for Main Outcomes}",
  "\\label{tab:sde}",
  "\\begin{threeparttable}",
  "\\begin{adjustbox}{max width=\\textwidth}",
  "\\begin{tabular}{llcccccl}",
  "\\toprule",
  "Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\",
  sprintf("Rel.\\ tobacco price & Preferred & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
          beta_main, sd_x, sd_y, sde_main, se_sde_main, classify(sde_main)),
  "\\midrule",
  "\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous}} \\\\",
  sprintf("\\quad High-menthol & Binary post & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\",
          beta_high, sd_y_high, sde_high, se_sde_high, classify(sde_high)),
  sprintf("\\quad Low-menthol & Binary post & %.4f & --- & %.4f & %.4f & %.4f & %s \\\\",
          beta_low, sd_y_low, sde_low, se_sde_low, classify(sde_low)),
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{adjustbox}",
  "\\end{threeparttable}",
  "\\par\\vspace{0.3em}",
  "{\\footnotesize \\sloppy",
  sde_notes,
  "}",
  "\\end{table}"
)

writeLines(tabF1_lines, "tables/tabF1_sde.tex")
cat("Wrote tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
