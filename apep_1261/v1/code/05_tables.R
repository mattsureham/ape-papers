## 05_tables.R — Generate all tables for Italy AUU fertility paper
source("00_packages.R")

cat("=== Generating Tables ===\n")

it_panel <- readRDS("../data/italy_panel.rds")
full_panel <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
loo_results <- readRDS("../data/loo_results.rds")

# Add needed variables
it_panel <- it_panel %>%
  mutate(
    selfemp_tercile = ntile(self_emp_share_2019, 3),
    south = as.integer(str_sub(nuts2, 1, 3) %in% c("ITF", "ITG")),
    selfemp_q = ntile(self_emp_share_2019, 4),
    selfemp_q2 = as.integer(selfemp_q == 2),
    selfemp_q3 = as.integer(selfemp_q == 3),
    selfemp_q4 = as.integer(selfemp_q == 4)
  )

it_short <- it_panel %>% filter(year >= 2015)

# ================================================================
# TABLE 1: Summary Statistics
# ================================================================
cat("\n--- Table 1: Summary Statistics ---\n")

pre <- it_panel %>% filter(year < 2022)
post <- it_panel %>% filter(year >= 2022)

summ_stats <- function(d, label) {
  tibble(
    Panel = label,
    `Mean birth rate` = sprintf("%.2f", mean(d$birth_rate, na.rm = TRUE)),
    `SD birth rate` = sprintf("%.2f", sd(d$birth_rate, na.rm = TRUE)),
    `Mean SE share` = sprintf("%.3f", mean(d$self_emp_share_2019, na.rm = TRUE)),
    `Mean unemp rate` = sprintf("%.1f", mean(d$unemp_rate, na.rm = TRUE)),
    `N (NUTS3)` = as.character(n_distinct(d$nuts3)),
    `Obs` = as.character(nrow(d))
  )
}

tab1_data <- bind_rows(
  summ_stats(pre, "Pre-reform (2010--2021)"),
  summ_stats(post, "Post-reform (2022--2023)"),
  summ_stats(pre %>% filter(selfemp_tercile == 3), "High SE tercile, pre"),
  summ_stats(pre %>% filter(selfemp_tercile == 1), "Low SE tercile, pre")
)

# LaTeX output
tab1_tex <- "\\begin{table}[t]
\\centering
\\caption{Summary Statistics: Italian NUTS3 Provinces}
\\label{tab:sumstats}
\\small
\\begin{tabular}{lcccccc}
\\toprule
& Birth Rate & SD & SE Share & Unemp. & NUTS3 & Obs. \\\\
\\midrule\n"

for (i in 1:nrow(tab1_data)) {
  row <- tab1_data[i,]
  tab1_tex <- paste0(tab1_tex, sprintf("%s & %s & %s & %s & %s & %s & %s \\\\\n",
                                        row$Panel, row$`Mean birth rate`, row$`SD birth rate`,
                                        row$`Mean SE share`, row$`Mean unemp rate`,
                                        row$`N (NUTS3)`, row$Obs))
}

tab1_tex <- paste0(tab1_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Birth rate is crude live births per 1,000 population from Eurostat \\texttt{demo\\_r\\_gind3}. SE Share is the 2019 self-employment share (employees classified as self-employed relative to total employed, ages 15--64) from Eurostat \\texttt{lfst\\_r\\_lfe2estat} at the NUTS2 level. Unemployment rate from Eurostat \\texttt{lfst\\_r\\_lfu3rt}. High (Low) SE tercile includes the top (bottom) third of NUTS2 regions by 2019 self-employment share. Sample: 136 Italian NUTS3 provinces, 2010--2023.
\\end{tablenotes}
\\end{table}")

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Table 1 written.\n")

# ================================================================
# TABLE 2: Main Results (DD specifications)
# ================================================================
cat("\n--- Table 2: Main DD Results ---\n")

# Run models
m1_full <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                 data = it_panel, cluster = ~nuts2)
m2_ctrl <- feols(birth_rate ~ dd_post_selfemp + unemp_rate + log(gdp_mio + 1) |
                   nuts3 + year,
                 data = it_panel, cluster = ~nuts2)
m3_short <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                  data = it_short, cluster = ~nuts2)
m4_short_ctrl <- feols(birth_rate ~ dd_post_selfemp + unemp_rate + log(gdp_mio + 1) |
                         nuts3 + year,
                       data = it_short, cluster = ~nuts2)

# DDD
full_panel_clean <- full_panel %>%
  filter(!is.na(birth_rate)) %>%
  mutate(
    italy = as.integer(str_sub(nuts3, 1, 2) == "IT"),
    selfemp_for_ddd = ifelse(str_sub(nuts3, 1, 2) == "IT", self_emp_share_2019, 0),
    post = as.integer(year >= 2022)
  )
m5_ddd <- feols(birth_rate ~ post:italy + post:selfemp_for_ddd |
                  nuts3 + year,
                data = full_panel_clean, cluster = ~nuts2)

# Format table
models_list <- list(m1_full, m2_ctrl, m3_short, m4_short_ctrl, m5_ddd)
col_labels <- c("(1)", "(2)", "(3)", "(4)", "(5)")

tab2_tex <- "\\begin{table}[t]
\\centering
\\caption{Effect of AUU on Birth Rates: Difference-in-Differences}
\\label{tab:main}
\\small
\\begin{tabular}{lccccc}
\\toprule
& \\multicolumn{4}{c}{Italy Only (DD)} & DDD \\\\
\\cmidrule(lr){2-5} \\cmidrule(lr){6-6}
& (1) & (2) & (3) & (4) & (5) \\\\
\\midrule\n"

# Post x SE Share coefficient
for (i in 1:5) {
  m <- models_list[[i]]
  coef_name <- if (i <= 4) "dd_post_selfemp" else "post:selfemp_for_ddd"
  b <- coef(m)[[coef_name]]
  s <- se(m)[[coef_name]]
  p <- pvalue(m)[[coef_name]]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  if (i == 1) {
    tab2_tex <- paste0(tab2_tex, sprintf("Post $\\times$ SE Share"))
  }
  tab2_tex <- paste0(tab2_tex, sprintf(" & %.3f%s", b, stars))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# SEs
for (i in 1:5) {
  m <- models_list[[i]]
  coef_name <- if (i <= 4) "dd_post_selfemp" else "post:selfemp_for_ddd"
  s <- se(m)[[coef_name]]
  tab2_tex <- paste0(tab2_tex, sprintf(" & (%.3f)", s))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

# Post x Italy (for DDD)
tab2_tex <- paste0(tab2_tex, "Post $\\times$ Italy & & & & ")
b_it <- coef(m5_ddd)[["post:italy"]]
s_it <- se(m5_ddd)[["post:italy"]]
p_it <- pvalue(m5_ddd)[["post:italy"]]
stars_it <- ifelse(p_it < 0.01, "^{***}", ifelse(p_it < 0.05, "^{**}", ifelse(p_it < 0.1, "^{*}", "")))
tab2_tex <- paste0(tab2_tex, sprintf("& %.3f%s \\\\\n", b_it, stars_it))
tab2_tex <- paste0(tab2_tex, sprintf(" & & & & & (%.3f) \\\\\n", s_it))

tab2_tex <- paste0(tab2_tex, "\\midrule\n")
tab2_tex <- paste0(tab2_tex, "Controls & No & Yes & No & Yes & No \\\\\n")
tab2_tex <- paste0(tab2_tex, "Window & 2010--23 & 2010--23 & 2015--23 & 2015--23 & 2010--23 \\\\\n")
tab2_tex <- paste0(tab2_tex, "EU comparators & No & No & No & No & Yes \\\\\n")

# Obs and R2
for (i in 1:5) {
  m <- models_list[[i]]
  if (i == 1) tab2_tex <- paste0(tab2_tex, "Observations")
  tab2_tex <- paste0(tab2_tex, sprintf(" & %s", format(m$nobs, big.mark = ",")))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

for (i in 1:5) {
  m <- models_list[[i]]
  if (i == 1) tab2_tex <- paste0(tab2_tex, "Within $R^2$")
  tab2_tex <- paste0(tab2_tex, sprintf(" & %.3f", fitstat(m, "wr2")$wr2))
}
tab2_tex <- paste0(tab2_tex, " \\\\\n")

tab2_tex <- paste0(tab2_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Dependent variable is the crude birth rate (live births per 1,000 population) at the NUTS3 level. Post $\\times$ SE Share is the interaction of a post-2022 indicator with the 2019 self-employment share at the NUTS2 level. Columns (1)--(4) use the Italian sample only (136 NUTS3 provinces). Column (5) adds 768 NUTS3 regions from Spain, France, Germany, Portugal, and Greece as a control group for Italy's aggregate trend. Controls include the NUTS2 unemployment rate and log GDP. All specifications include NUTS3 and year fixed effects. Standard errors clustered at the NUTS2 level (21 Italian regions; 174 regions in column 5) in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.
\\end{tablenotes}
\\end{table}")

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  Table 2 written.\n")

# ================================================================
# TABLE 3: Robustness and Heterogeneity
# ================================================================
cat("\n--- Table 3: Robustness ---\n")

# Placebo 2018
m_plac18 <- rob_results$placebo_2018
# Placebo 2019
m_plac19 <- rob_results$placebo_2019
# South/North
m_south <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                 data = it_panel %>% filter(south == 1), cluster = ~nuts2)
m_north <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                 data = it_panel %>% filter(south == 0), cluster = ~nuts2)
# Quartile
m_quart <- feols(birth_rate ~ post:selfemp_q2 + post:selfemp_q3 + post:selfemp_q4 |
                   nuts3 + year,
                 data = it_panel, cluster = ~nuts2)

tab3_tex <- "\\begin{table}[t]
\\centering
\\caption{Robustness Checks and Heterogeneity}
\\label{tab:robust}
\\small
\\begin{tabular}{lccccc}
\\toprule
& \\multicolumn{2}{c}{Placebo} & \\multicolumn{2}{c}{Geography} & Dose- \\\\
& 2018 & 2019 & North & South & Response \\\\
& (1) & (2) & (3) & (4) & (5) \\\\
\\midrule\n"

# Placebo coefficients
b1 <- coef(m_plac18)[[1]]; s1 <- se(m_plac18)[[1]]; p1 <- pvalue(m_plac18)[[1]]
b2 <- coef(m_plac19)[[1]]; s2 <- se(m_plac19)[[1]]; p2 <- pvalue(m_plac19)[[1]]
b3 <- coef(m_north)[[1]]; s3 <- se(m_north)[[1]]; p3 <- pvalue(m_north)[[1]]
b4 <- coef(m_south)[[1]]; s4 <- se(m_south)[[1]]; p4 <- pvalue(m_south)[[1]]

star <- function(p) ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))

tab3_tex <- paste0(tab3_tex, sprintf("Post $\\times$ SE Share & %.3f%s & %.3f%s & %.3f%s & %.3f%s & \\\\\n",
                                      b1, star(p1), b2, star(p2), b3, star(p3), b4, star(p4)))
tab3_tex <- paste0(tab3_tex, sprintf(" & (%.3f) & (%.3f) & (%.3f) & (%.3f) & \\\\\n", s1, s2, s3, s4))

# Quartile dummies
bq2 <- coef(m_quart)[["post:selfemp_q2"]]; sq2 <- se(m_quart)[["post:selfemp_q2"]]; pq2 <- pvalue(m_quart)[["post:selfemp_q2"]]
bq3 <- coef(m_quart)[["post:selfemp_q3"]]; sq3 <- se(m_quart)[["post:selfemp_q3"]]; pq3 <- pvalue(m_quart)[["post:selfemp_q3"]]
bq4 <- coef(m_quart)[["post:selfemp_q4"]]; sq4 <- se(m_quart)[["post:selfemp_q4"]]; pq4 <- pvalue(m_quart)[["post:selfemp_q4"]]

tab3_tex <- paste0(tab3_tex, sprintf("Post $\\times$ Q2 & & & & & %.3f%s \\\\\n", bq2, star(pq2)))
tab3_tex <- paste0(tab3_tex, sprintf(" & & & & & (%.3f) \\\\\n", sq2))
tab3_tex <- paste0(tab3_tex, sprintf("Post $\\times$ Q3 & & & & & %.3f%s \\\\\n", bq3, star(pq3)))
tab3_tex <- paste0(tab3_tex, sprintf(" & & & & & (%.3f) \\\\\n", sq3))
tab3_tex <- paste0(tab3_tex, sprintf("Post $\\times$ Q4 & & & & & %.3f%s \\\\\n", bq4, star(pq4)))
tab3_tex <- paste0(tab3_tex, sprintf(" & & & & & (%.3f) \\\\\n", sq4))

tab3_tex <- paste0(tab3_tex, "\\midrule\n")
tab3_tex <- paste0(tab3_tex, sprintf("Window & 2010--21 & 2010--21 & 2010--23 & 2010--23 & 2010--23 \\\\\n"))
tab3_tex <- paste0(tab3_tex, sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
                                      format(m_plac18$nobs, big.mark=","),
                                      format(m_plac19$nobs, big.mark=","),
                                      format(m_north$nobs, big.mark=","),
                                      format(m_south$nobs, big.mark=","),
                                      format(m_quart$nobs, big.mark=",")))

tab3_tex <- paste0(tab3_tex, "\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Columns (1)--(2) report placebo tests using pseudo-treatment dates of 2018 and 2019 on pre-reform data only (2010--2021). Columns (3)--(4) split the sample into Northern (82 provinces in ITC/ITH/ITI NUTS2 regions) and Southern Italy (54 provinces in ITF/ITG NUTS2 regions). Column (5) replaces the continuous self-employment share with quartile dummies (Q1 = lowest self-employment, reference). All specifications include NUTS3 and year fixed effects. Standard errors clustered at the NUTS2 level in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.
\\end{tablenotes}
\\end{table}")

writeLines(tab3_tex, "../tables/tab3_robust.tex")
cat("  Table 3 written.\n")

# ================================================================
# TABLE 4: Event Study Coefficients
# ================================================================
cat("\n--- Table 4: Event Study ---\n")

m_es <- feols(birth_rate ~ i(year, self_emp_share_2019, ref = 2021) |
                nuts3 + year,
              data = it_short, cluster = ~nuts2)

es_coefs <- broom::tidy(m_es) %>%
  mutate(
    year_num = as.numeric(str_extract(term, "\\d{4}")),
    stars = case_when(
      p.value < 0.01 ~ "^{***}",
      p.value < 0.05 ~ "^{**}",
      p.value < 0.10 ~ "^{*}",
      TRUE ~ ""
    )
  ) %>%
  filter(!is.na(year_num)) %>%
  arrange(year_num)

tab4_tex <- "\\begin{table}[t]
\\centering
\\caption{Event Study: Year-by-Year Interactions with Self-Employment Share}
\\label{tab:event}
\\small
\\begin{tabular}{lcc}
\\toprule
Year & Coefficient & Std. Error \\\\
\\midrule\n"

for (i in 1:nrow(es_coefs)) {
  r <- es_coefs[i,]
  rel_yr <- r$year_num - 2022
  yr_label <- if (r$year_num == 2021) "2021 (ref.)" else as.character(r$year_num)
  tab4_tex <- paste0(tab4_tex, sprintf("%s & %.3f%s & (%.3f) \\\\\n",
                                        yr_label, r$estimate, r$stars, r$std.error))
}

# Add reference year
tab4_tex <- paste0(tab4_tex, "2021 (ref.) & 0.000 & --- \\\\
\\midrule
Post-treatment mean & \\multicolumn{2}{c}{",
sprintf("%.3f", mean(c(es_coefs$estimate[es_coefs$year_num >= 2022]))),
"} \\\\
LOO range & \\multicolumn{2}{c}{[",
sprintf("%.2f, %.2f", rob_results$loo_range[1], rob_results$loo_range[2]),
"]} \\\\
WCB $p$-value & \\multicolumn{2}{c}{0.111} \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
\\item \\textit{Notes:} Each row reports the coefficient on the interaction of a year dummy with the 2019 NUTS2 self-employment share, from a single regression of birth rate on year$\\times$SE\\_share interactions with NUTS3 and year fixed effects. Sample: 136 Italian NUTS3 provinces, 2015--2023. Reference year is 2021 (last pre-reform year). LOO range reports the range of the main DD coefficient when each NUTS2 region is sequentially dropped. WCB reports the wild cluster bootstrap $p$-value (Webb weights, 9,999 iterations). Standard errors clustered at the NUTS2 level (21 regions) in parentheses. $^{*}$~$p<0.10$, $^{**}$~$p<0.05$, $^{***}$~$p<0.01$.
\\end{tablenotes}
\\end{table}")

writeLines(tab4_tex, "../tables/tab4_event.tex")
cat("  Table 4 written.\n")

# ================================================================
# TABLE F1: Standardized Effect Size (SDE) — APPENDIX
# ================================================================
cat("\n--- Table F1: Standardized Effect Size ---\n")

# Main specification: shorter window
m_main <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                data = it_short, cluster = ~nuts2)
beta_main <- coef(m_main)[[1]]
se_main <- se(m_main)[[1]]

# Pre-treatment SD of birth rate
sd_y_pre <- sd(it_short$birth_rate[it_short$year < 2022], na.rm = TRUE)

# SD of treatment variable (self-employment share)
sd_x <- sd(it_short$self_emp_share_2019[it_short$year < 2022], na.rm = TRUE)

# SDE for continuous treatment: beta * SD(X) / SD(Y)
sde_main <- beta_main * sd_x / sd_y_pre
se_sde_main <- se_main * sd_x / sd_y_pre

classify_sde <- function(sde) {
  if (sde > 0.15) return("Large positive")
  if (sde > 0.05) return("Moderate positive")
  if (sde > 0.005) return("Small positive")
  if (sde > -0.005) return("Null")
  if (sde > -0.05) return("Small negative")
  if (sde > -0.15) return("Moderate negative")
  return("Large negative")
}

# South subsample
m_south_short <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                       data = it_short %>% filter(south == 1), cluster = ~nuts2)
beta_south <- coef(m_south_short)[[1]]
se_south <- se(m_south_short)[[1]]
sd_y_south <- sd(it_short$birth_rate[it_short$year < 2022 & it_short$south == 1], na.rm = TRUE)
sd_x_south <- sd(it_short$self_emp_share_2019[it_short$year < 2022 & it_short$south == 1], na.rm = TRUE)
sde_south <- beta_south * sd_x_south / sd_y_south
se_sde_south <- se_south * sd_x_south / sd_y_south

# North subsample
m_north_short <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                       data = it_short %>% filter(south == 0), cluster = ~nuts2)
beta_north <- coef(m_north_short)[[1]]
se_north <- se(m_north_short)[[1]]
sd_y_north <- sd(it_short$birth_rate[it_short$year < 2022 & it_short$south == 0], na.rm = TRUE)
sd_x_north <- sd(it_short$self_emp_share_2019[it_short$year < 2022 & it_short$south == 0], na.rm = TRUE)
sde_north <- beta_north * sd_x_north / sd_y_north
se_sde_north <- se_north * sd_x_north / sd_y_north

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Italy. ",
  "\\textbf{Research question:} Does extending child benefits to previously excluded self-employed families raise fertility at the regional level? ",
  "\\textbf{Policy mechanism:} Italy's March 2022 Assegno Unico Universale replaced eight fragmented family transfers with a single universal child benefit (EUR 50--175 per month per child), extending coverage from 87\\% to 100\\% of families; the self-employed and unemployed, previously excluded from the main family allowance (ANF), gained new eligibility. ",
  "\\textbf{Outcome definition:} Crude birth rate, defined as live births per 1,000 population at the NUTS3 province level, from Eurostat \\texttt{demo\\_r\\_gind3}. ",
  "\\textbf{Treatment:} Continuous; the 2019 NUTS2-level self-employment share (proportion of workers aged 15--64 classified as self-employed), proxying the share of families gaining new benefit access. ",
  "\\textbf{Data:} Eurostat regional demographics and labor force statistics, 2015--2023, 136 Italian NUTS3 provinces (1,182 province-year observations). ",
  "\\textbf{Method:} Difference-in-differences with continuous treatment intensity; NUTS3 and year fixed effects; standard errors clustered at the NUTS2 level (21 regions). ",
  "\\textbf{Sample:} All 136 Italian NUTS3 provinces with non-missing birth rate and self-employment data; no provinces excluded. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, where SD($X$) and SD($Y$) are pre-treatment standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0("\\begin{table}[t]
\\centering
\\caption{Standardized Effect Sizes}
\\label{tab:sde}
\\small
\\begin{tabular}{lcccccc}
\\toprule
Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\
Birth rate (all) & ", sprintf("%.3f & %.3f & %.3f & %.3f & %.3f & %s",
  beta_main, se_main, sd_y_pre, sde_main, se_sde_main, classify_sde(sde_main)),
" \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Sample Splits)}} \\\\
Birth rate (South) & ", sprintf("%.3f & %.3f & %.3f & %.3f & %.3f & %s",
  beta_south, se_south, sd_y_south, sde_south, se_sde_south, classify_sde(sde_south)),
" \\\\
Birth rate (North) & ", sprintf("%.3f & %.3f & %.3f & %.3f & %.3f & %s",
  beta_north, se_north, sd_y_north, sde_north, se_sde_north, classify_sde(sde_north)),
" \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}
", sde_notes, "
\\end{tablenotes}
\\end{table}")

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Table F1 (SDE) written.\n")

cat("\n=== All tables generated ===\n")
