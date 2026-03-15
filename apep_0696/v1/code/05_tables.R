## 05_tables.R — Generate all tables
## apep_0696: FPM fiscal windfalls and agricultural expansion in Brazil

library(tidyverse)
library(fixest)
library(modelsummary)
library(kableExtra)
library(jsonlite)

options("modelsummary_format_numeric_latex" = "plain")

# Run from the v1/ directory (e.g., Rscript code/$(basename $0))
dir.create("tables", showWarnings = FALSE)

## ─────────────────────────────────────────────────────────────────────────────
## Load data and results
## ─────────────────────────────────────────────────────────────────────────────
df_cross   <- read_csv("data/cross_section_rdd.csv",
                       col_types = cols(mun_code = col_character()))
df_stacked <- read_csv("data/stacked_multicutoff.csv",
                       col_types = cols(mun_code = col_character()))
df_panel   <- read_csv("data/panel_clean.csv",
                       col_types = cols(mun_code = col_character()))
pop_all    <- read_csv("data/population.csv",
                       col_types = cols(mun_code = col_character()))
fpm_sched  <- read_csv("data/fpm_schedule.csv")

models  <- readRDS("data/models.rds")
rob     <- readRDS("data/robustness_results.rds")

h_opt <- models$h_opt
amazon_states <- c("11", "12", "13", "14", "15", "16", "17")

df_stacked_bw <- models$df_stacked_bw %>%
  mutate(
    state_code = substr(mun_code, 1, 2),
    amazon = as.integer(state_code %in% amazon_states),
    above_k_num = as.numeric(above_k)
  )

## ─────────────────────────────────────────────────────────────────────────────
## Re-estimate all model objects
## ─────────────────────────────────────────────────────────────────────────────
cat("Re-estimating models...\n")
main_bw <- df_stacked_bw

m1 <- feols(
  avg_log_crop ~ above_k_num + run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = main_bw, weights = ~w_tri, cluster = ~mun_code
)
m2 <- feols(
  avg_log_crop ~ above_k_num + run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = main_bw %>% filter(amazon == 0), weights = ~w_tri, cluster = ~mun_code
)
m3 <- feols(
  avg_log_crop ~ above_k_num + run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = main_bw %>% filter(amazon == 1), weights = ~w_tri, cluster = ~mun_code
)

# Panel DiD
fpm_thresholds <- fpm_sched$pop_min[-1]
assign_fpm <- function(pop, fpm_sched) {
  bracket <- findInterval(pop, c(0, fpm_sched$pop_min[-1]))
  fpm_sched$coeff[bracket]
}
pop_2000 <- pop_all %>% filter(year == 2000) %>%
  transmute(mun_code, pop_2000 = pop,
            bracket_2000 = findInterval(pop, c(0, fpm_thresholds)),
            coeff_2000 = assign_fpm(pop, fpm_sched))
pop_2010 <- pop_all %>% filter(year == 2010) %>%
  transmute(mun_code, pop_2010 = pop,
            bracket_2010 = findInterval(pop, c(0, fpm_thresholds)),
            coeff_2010 = assign_fpm(pop, fpm_sched))
crossers <- pop_2000 %>% inner_join(pop_2010, by = "mun_code") %>%
  mutate(
    bracket_change = bracket_2010 - bracket_2000,
    crossed_up = as.integer(bracket_change > 0),
    stayed = as.integer(bracket_change == 0),
    n_brackets_crossed = pmax(0, bracket_change)
  )
df_did <- df_panel %>%
  inner_join(crossers, by = "mun_code") %>%
  mutate(post_2010 = as.integer(year >= 2010),
         treat_post = crossed_up * post_2010,
         intensive  = n_brackets_crossed * post_2010)
df_did_sample <- df_did %>% filter(stayed == 1 | crossed_up == 1)

p1 <- feols(log_crop_area ~ treat_post | mun_code + year,
            data = df_did_sample, cluster = ~mun_code)
p2 <- feols(log_crop_area ~ intensive | mun_code + year,
            data = df_did_sample, cluster = ~mun_code)
p3 <- feols(log_crop_area ~ treat_post | mun_code + year,
            data = df_did_sample %>%
              mutate(state_code = substr(mun_code, 1, 2),
                     amazon = state_code %in% amazon_states) %>%
              filter(amazon),
            cluster = ~mun_code)

# Donut and placebo
df_donut <- df_stacked_bw %>% filter(abs(run_var_k) >= 0.01)
m_donut <- feols(
  avg_log_crop ~ above_k_num + run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = df_donut, weights = ~w_tri, cluster = ~mun_code
)
pre_cross <- df_panel %>%
  filter(year <= 2004) %>%
  group_by(mun_code) %>%
  summarise(avg_log_crop_pre = mean(log(crop_area_ha + 1), na.rm = TRUE), .groups = "drop")
df_stacked_pre <- df_stacked %>%
  filter(abs(run_var_k) <= h_opt) %>%
  left_join(pre_cross, by = "mun_code") %>%
  mutate(w_tri = 1 - abs(run_var_k) / h_opt, above_k_num = as.numeric(above_k)) %>%
  filter(!is.na(avg_log_crop_pre))
m_placebo <- feols(
  avg_log_crop_pre ~ above_k_num + run_var_k:I(above_k_num == 0) +
    run_var_k:I(above_k_num == 1) | k_index,
  data = df_stacked_pre, weights = ~w_tri, cluster = ~mun_code
)

cat("All models estimated.\n")

## ─────────────────────────────────────────────────────────────────────────────
## Helper: wrap latex_tabular output in full table environment
## ─────────────────────────────────────────────────────────────────────────────
wrap_table <- function(ms_obj, caption, label, notes, add_small = TRUE) {
  body <- as.character(ms_obj)
  c(
    "\\begin{table}[htbp]",
    if (add_small) "\\small",
    "\\centering",
    sprintf("\\caption{%s}", caption),
    sprintf("\\label{tab:%s}", label),
    body,
    "\\begin{minipage}{0.95\\textwidth}",
    "\\vspace{4pt}\\scriptsize",
    paste0("\\textit{Notes:} ", notes),
    "\\end{minipage}",
    "\\end{table}"
  )
}

## ─────────────────────────────────────────────────────────────────────────────
## Table 1: Summary Statistics
## ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 1: Summary Statistics...\n")

summ_by_side <- df_stacked_bw %>%
  mutate(above_label = ifelse(above_k_num == 1, "Above Threshold", "Below Threshold")) %>%
  group_by(above_label) %>%
  summarise(
    N = n(),
    `Mean Pop. (000)` = mean(pop / 1000, na.rm = TRUE),
    `Crop Area (ha)` = mean(avg_crop_area, na.rm = TRUE),
    `Log Crop Area`  = mean(avg_log_crop, na.rm = TRUE),
    .groups = "drop"
  )
summ_all <- df_stacked_bw %>%
  summarise(
    above_label = "Full Sample",
    N = n(),
    `Mean Pop. (000)` = mean(pop / 1000, na.rm = TRUE),
    `Crop Area (ha)` = mean(avg_crop_area, na.rm = TRUE),
    `Log Crop Area`  = mean(avg_log_crop, na.rm = TRUE)
  )
tab1 <- bind_rows(summ_by_side, summ_all) %>%
  mutate(across(where(is.numeric), ~ round(., 2)))

tab1_str <- tab1 %>%
  rename(`Group` = above_label) %>%
  kable(
    format = "latex", booktabs = TRUE, escape = FALSE,
    caption = "Summary Statistics for RDD Sample",
    label = "tab1_summary",
    digits = c(0, 0, 1, 0, 2),
    align = c("l", rep("r", 4))
  ) %>%
  kable_styling(font_size = 10) %>%
  footnote(
    general = paste0(
      "Notes: Sample is municipality-threshold pairs within the MSE-optimal bandwidth of ",
      round(h_opt * 100, 1), "\\\\% of each FPM population threshold. ",
      "Crop area is the average area planted (hectares) of annual crops, 2005--2015, from IBGE PAM. ",
      "``Above Threshold'' indicates municipalities whose 2000 census population exceeds the relevant FPM threshold. ",
      "Brazil has 17 FPM population thresholds; the stacked dataset includes each municipality once per nearby threshold."),
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  as.character()
writeLines(tab1_str, "tables/tab1_summary.tex")
cat("Table 1 saved.\n")

## ─────────────────────────────────────────────────────────────────────────────
## Table 2: Main RDD Results
## ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 2: Main RDD Results...\n")

models_main <- list("Full Sample" = m1, "Non-Amazon" = m2, "Amazon" = m3)
cm <- c("above_k_num" = "Above FPM Threshold")

ms2 <- modelsummary(
  models_main,
  coef_map = cm,
  gof_map = list(
    list(raw = "nobs", clean = "Observations", fmt = 0),
    list(raw = "r.squared", clean = "R$^2$", fmt = 3)
  ),
  stars = c("*" = .1, "**" = .05, "***" = .01),
  output = "latex_tabular", escape = FALSE,
  add_rows = data.frame(
    term = c("Threshold FE", "Bandwidth"),
    `Full Sample` = c("Yes", paste0(round(h_opt * 100, 1), "\\%")),
    `Non-Amazon` = c("Yes", paste0(round(h_opt * 100, 1), "\\%")),
    Amazon = c("Yes", paste0(round(h_opt * 100, 1), "\\%")),
    check.names = FALSE
  )
)
tab2_notes <- paste0(
  "Dependent variable is log average crop area (hectares) planted, 2005--2015. ",
  "Sample is municipality-threshold pairs within the MSE-optimal bandwidth (", round(h_opt * 100, 1), "\\% of threshold). ",
  "``Above FPM Threshold'' indicates municipalities whose 2000 census population exceeds the relevant FPM population cutoff, ",
  "entitling them to a higher FPM coefficient (0.2 increment). ",
  "All specifications include threshold fixed effects and local linear polynomials on each side with triangular kernel weights. ",
  "Amazon states: AC, AM, AP, PA, RO, RR, TO. ",
  "Standard errors clustered by municipality. *** p$<$0.01, ** p$<$0.05, * p$<$0.1."
)
writeLines(
  wrap_table(ms2,
    caption = "FPM Thresholds and Agricultural Expansion: Multi-Cutoff RDD",
    label = "tab2_main_rdd",
    notes = tab2_notes),
  "tables/tab2_main_rdd.tex"
)
cat("Table 2 saved.\n")

## ─────────────────────────────────────────────────────────────────────────────
## Table 3: Panel DiD — Threshold Crossers
## ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 3: Panel DiD...\n")

models_did <- list(
  "Binary" = p1,
  "Intensive Margin" = p2,
  "Amazon" = p3
)
cm_did <- c("treat_post" = "Crossed Threshold $\\times$ Post-2010",
            "intensive"  = "Brackets Crossed $\\times$ Post-2010")

ms3 <- modelsummary(
  models_did,
  coef_map = cm_did,
  gof_map = list(
    list(raw = "nobs", clean = "Observations", fmt = 0),
    list(raw = "r.squared", clean = "R$^2$", fmt = 3)
  ),
  stars = c("*" = .1, "**" = .05, "***" = .01),
  output = "latex_tabular", escape = FALSE,
  add_rows = data.frame(
    term = c("Municipality FE", "Year FE"),
    Binary = c("Yes", "Yes"),
    `Intensive Margin` = c("Yes", "Yes"),
    Amazon = c("Yes", "Yes"),
    check.names = FALSE
  )
)
tab3_notes <- paste0(
  "Dependent variable is log annual crop area planted (hectares). ",
  "Sample: municipalities in the same FPM bracket across both censuses (stayed) or that crossed to a higher bracket between 2000 and 2010 (crossers). ",
  "``Crossed Threshold'' = 1 if a municipality moved to a higher FPM bracket between the 2000 and 2010 censuses. ",
  "``Brackets Crossed'' is the number of brackets gained. ",
  "All specifications include municipality and year fixed effects. ",
  "Crossers: 1,357 municipalities. Stayers: 4,015 municipalities. Annual data: 2000--2019. ",
  "Column (3) restricts to Amazon-biome states. ",
  "Standard errors clustered by municipality. *** p$<$0.01, ** p$<$0.05, * p$<$0.1."
)
writeLines(
  wrap_table(ms3,
    caption = "Panel DiD: Municipalities Crossing FPM Thresholds, 2000--2019",
    label = "tab3_panel_did",
    notes = tab3_notes),
  "tables/tab3_panel_did.tex"
)
cat("Table 3 saved.\n")

## ─────────────────────────────────────────────────────────────────────────────
## Table 4: Bandwidth Sensitivity and Density Tests
## ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 4: Bandwidth sensitivity...\n")

bw_results <- list()
for (h in c(0.10, 0.15, 0.20, 0.25, 0.30)) {
  df_h <- df_stacked %>%
    filter(abs(run_var_k) <= h) %>%
    mutate(w_tri = 1 - abs(run_var_k) / h, above_k_num = as.numeric(above_k))
  fit <- tryCatch(feols(
    avg_log_crop ~ above_k_num + run_var_k:I(above_k_num == 0) +
      run_var_k:I(above_k_num == 1) | k_index,
    data = df_h, weights = ~w_tri, cluster = ~mun_code
  ), error = function(e) NULL)
  if (!is.null(fit)) {
    bw_results[[as.character(h)]] <- data.frame(
      bandwidth = paste0(round(h * 100), "\\%"),
      n_obs = nrow(df_h),
      coef = round(coef(fit)["above_k_num"], 4),
      se = round(se(fit)["above_k_num"], 4)
    )
  }
}
bw_tab <- bind_rows(bw_results)

tab4_tex <- c(
  "\\begin{table}[htbp]",
  "\\small",
  "\\centering",
  "\\caption{Bandwidth Sensitivity and Density Tests}",
  "\\label{tab:tab4_sensitivity}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Bandwidth sensitivity (stacked multi-cutoff OLS)}} \\\\",
  "\\midrule",
  "Bandwidth & N (obs.) & Estimate & (SE) \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(bw_tab))) {
  tab4_tex <- c(tab4_tex,
    sprintf("%s & %s & %.4f & (%.4f) \\\\",
            bw_tab$bandwidth[i],
            formatC(bw_tab$n_obs[i], format = "d", big.mark = ","),
            bw_tab$coef[i],
            bw_tab$se[i]))
}
tab4_tex <- c(tab4_tex,
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel B: Density test for manipulation at thresholds}} \\\\",
  "\\midrule",
  sprintf("Thresholds significant at p$<$0.05 & \\multicolumn{3}{c}{%d of 17} \\\\",
          rob$n_sig_density),
  "Thresholds with manipulation & \\multicolumn{3}{c}{1, 3, 17 (pop.~10,189; 16,981; 156,217)} \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{4pt}\\scriptsize",
  paste0("\\textit{Notes:} Panel A shows the stacked multi-cutoff OLS estimate of crossing an FPM population threshold on log crop area, ",
         "varying the kernel bandwidth as a fraction of each threshold value. ",
         "Triangular kernel weights and threshold fixed effects throughout. ",
         "The main specification uses the MSE-optimal bandwidth of ", round(h_opt * 100, 1), "\\%. ",
         "Standard errors clustered by municipality. ",
         "Panel B reports McCrary-style density tests (\\texttt{rddensity}) at each of the 17 FPM thresholds individually. ",
         "Only 3 of 17 thresholds reject the null of no manipulation at the 5\\% level, ",
         "providing limited evidence of systematic sorting into higher FPM brackets."),
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(tab4_tex, "tables/tab4_sensitivity.tex")
cat("Table 4 saved.\n")

## ─────────────────────────────────────────────────────────────────────────────
## Table 5: Robustness Checks
## ─────────────────────────────────────────────────────────────────────────────
cat("Generating Table 5: Robustness checks...\n")

models_rob <- list(
  "Main" = m1,
  "Donut ($|x|<$1\\%)" = m_donut,
  "Pre-period Placebo" = m_placebo
)
cm_rob <- c("above_k_num" = "Above FPM Threshold")

ms5 <- modelsummary(
  models_rob,
  coef_map = cm_rob,
  gof_map = list(
    list(raw = "nobs", clean = "Observations", fmt = 0)
  ),
  stars = c("*" = .1, "**" = .05, "***" = .01),
  output = "latex_tabular", escape = FALSE,
  add_rows = data.frame(
    term = c("Threshold FE", "Period"),
    Main = c("Yes", "2005--2015"),
    `Donut` = c("Yes", "2005--2015"),
    `Pre-period` = c("Yes", "2000--2004"),
    check.names = FALSE
  )
)
tab5_notes <- paste0(
  "All specifications use the stacked multi-cutoff dataset with triangular kernel weights and threshold fixed effects. ",
  "Column (1) repeats the main specification from Table 2. ",
  "Column (2) excludes municipality-threshold pairs within 1\\% of each cutoff (donut-hole test for manipulation). ",
  "Column (3) uses average log crop area in 2000--2004 as the outcome; ",
  "a significant estimate here would indicate pre-existing differences at the threshold. ",
  "The pre-period placebo estimate is comparable in magnitude to the main estimate, ",
  "suggesting baseline sorting that limits causal interpretation of the cross-sectional RDD. ",
  "The panel DiD (Table 3) addresses this by using within-municipality variation. ",
  "Standard errors clustered by municipality. *** p$<$0.01, ** p$<$0.05, * p$<$0.1."
)
writeLines(
  wrap_table(ms5,
    caption = "Robustness Checks: Donut-Hole and Pre-Period Placebo",
    label = "tab5_robustness",
    notes = tab5_notes),
  "tables/tab5_robustness.tex"
)
cat("Table 5 saved.\n")

## ─────────────────────────────────────────────────────────────────────────────
## SDE Table (Standardized Effect Sizes)
## ─────────────────────────────────────────────────────────────────────────────
cat("Generating SDE table...\n")

outcomes <- tibble(
  Outcome = c(
    "Log Crop Area (Full Sample, RDD)",
    "Log Crop Area (Non-Amazon, RDD)",
    "Log Crop Area (Amazon, RDD)",
    "Log Crop Area (Panel DiD, Binary)",
    "Log Crop Area (Panel DiD, Intensive)"
  ),
  beta_hat = c(
    coef(m1)["above_k_num"],
    coef(m2)["above_k_num"],
    coef(m3)["above_k_num"],
    rob$did1_coef,
    rob$did2_coef
  ),
  se_hat = c(
    se(m1)["above_k_num"],
    se(m2)["above_k_num"],
    se(m3)["above_k_num"],
    rob$did1_se,
    rob$did2_se
  ),
  sd_y = c(
    sd(df_stacked_bw$avg_log_crop, na.rm = TRUE),
    sd(df_stacked_bw$avg_log_crop[df_stacked_bw$amazon == 0], na.rm = TRUE),
    sd(df_stacked_bw$avg_log_crop[df_stacked_bw$amazon == 1], na.rm = TRUE),
    sd(df_panel$log_crop_area, na.rm = TRUE),
    sd(df_panel$log_crop_area, na.rm = TRUE)
  )
) %>%
  mutate(
    SDE = beta_hat / sd_y,
    SE_SDE = se_hat / sd_y,
    Classification = case_when(
      SDE < -0.15 ~ "Large negative",
      SDE < -0.05 ~ "Moderate negative",
      SDE < -0.005 ~ "Small negative",
      SDE <= 0.005 ~ "Null",
      SDE <= 0.05 ~ "Small positive",
      SDE <= 0.15 ~ "Moderate positive",
      TRUE ~ "Large positive"
    ),
    across(c(beta_hat, se_hat, sd_y, SDE, SE_SDE), ~ round(., 4))
  )

sde_notes <- paste0(
  "Country: Brazil. ",
  "Research question: Does crossing a higher FPM (Fundo de Participa\\c{c}\\~ao dos Munic\\'ipios) ",
  "population threshold --- which triggers a discrete increase in federal-to-municipal fiscal transfers --- ",
  "cause municipalities to expand agricultural production (as measured by annual crop area)? ",
  "Policy mechanism: Brazil\\'s FPM distributes federal income tax revenue to all 5,570 municipalities ",
  "using a coefficient schedule with 17 population thresholds; crossing a threshold raises the municipality\\'s ",
  "transfer coefficient by 0.2 (out of a typical total of 0.6--4.0), yielding an annual windfall of approximately R\\$0.8 million. ",
  "Outcome: Log area planted (hectares) of annual crops from the IBGE Pesquisa Agr\\'icola Municipal (PAM), ",
  "averaged 2005--2015 for the cross-section (RDD), or annual 2000--2019 for the panel (DiD). ",
  "Treatment: Binary indicator for municipality 2000 census population exceeding an FPM threshold (RDD); ",
  "or binary/count of brackets crossed between 2000 and 2010 censuses (panel DiD). ",
  "Data: IBGE PAM (annual crops, 109,493 municipality-year obs.); IBGE Census 2000/2010. ",
  "Method: Cross-sectional stacked multi-cutoff OLS with triangular kernel weights, threshold fixed effects, ",
  "local linear polynomial on each side of cutoff; clustered standard errors by municipality. ",
  "Panel specifications use municipality and year fixed effects. ",
  "Sample: Full sample, Amazon-biome subgroup (AC, AM, AP, PA, RO, RR, TO), and non-Amazon municipalities. ",
  "Classification refers to magnitude of standardized effect size, not statistical significance."
)

sde_tex <- c(
  "\\begin{table}[htbp]",
  "\\small",
  "\\centering",
  "\\caption{Standardized Effect Sizes: FPM Thresholds and Agricultural Expansion}",
  "\\label{tab:tab_sde}",
  "\\begin{tabular}{lrrrrrr}",
  "\\toprule",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(outcomes))) {
  sde_tex <- c(sde_tex,
    sprintf("%s & %.4f & %.4f & %.4f & %.4f & %.4f & %s \\\\",
            outcomes$Outcome[i], outcomes$beta_hat[i], outcomes$se_hat[i],
            outcomes$sd_y[i], outcomes$SDE[i], outcomes$SE_SDE[i],
            outcomes$Classification[i]))
}
sde_tex <- c(sde_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\vspace{4pt}\\scriptsize",
  paste0("\\textit{Notes:} ", sde_notes),
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(sde_tex, "tables/tabF1_sde.tex")
cat("SDE table saved.\n")

## ─────────────────────────────────────────────────────────────────────────────
## Save summary stats for paper text macros
## ─────────────────────────────────────────────────────────────────────────────
text_stats <- list(
  n_municipalities   = n_distinct(df_stacked_bw$mun_code),
  n_obs_stacked      = nrow(df_stacked_bw),
  h_opt_pct          = round(h_opt * 100, 1),
  main_coef          = round(coef(m1)["above_k_num"], 4),
  main_se            = round(se(m1)["above_k_num"], 4),
  main_pval          = round(pvalue(m1)["above_k_num"], 4),
  nonamazon_coef     = round(coef(m2)["above_k_num"], 4),
  nonamazon_se       = round(se(m2)["above_k_num"], 4),
  amazon_coef        = round(coef(m3)["above_k_num"], 4),
  amazon_se          = round(se(m3)["above_k_num"], 4),
  amazon_pct         = round((exp(coef(m3)["above_k_num"]) - 1) * 100, 1),
  donut_coef         = round(coef(m_donut)["above_k_num"], 4),
  donut_se           = round(se(m_donut)["above_k_num"], 4),
  did1_coef          = round(rob$did1_coef, 4),
  did1_se            = round(rob$did1_se, 4),
  did1_pval          = round(pvalue(p1)["treat_post"], 4),
  did2_coef          = round(rob$did2_coef, 4),
  did2_se            = round(rob$did2_se, 4),
  did2_pval          = round(pvalue(p2)["intensive"], 4),
  n_crossers         = rob$n_crossers,
  n_staying          = rob$n_staying,
  n_sig_density      = rob$n_sig_density,
  fpm_jump_mln       = round(models$annual_fpm_jump_mln, 1),
  pct_increase       = round(models$pct_increase * 100, 1),
  mean_crop_above    = round(models$mean_crop_above, 0)
)
write_json(text_stats, "data/text_stats.json", auto_unbox = TRUE)

cat("\nAll tables generated successfully.\n")
cat(sprintf("  Main: %.4f (SE=%.4f, p=%.4f)\n",
            text_stats$main_coef, text_stats$main_se, text_stats$main_pval))
cat(sprintf("  Amazon: %.4f (SE=%.4f), %.1f%%\n",
            text_stats$amazon_coef, text_stats$amazon_se, text_stats$amazon_pct))
cat(sprintf("  Panel DiD binary: %.4f (SE=%.4f, p=%.4f)\n",
            text_stats$did1_coef, text_stats$did1_se, text_stats$did1_pval))
cat(sprintf("  Panel DiD intensive: %.4f (SE=%.4f, p=%.4f)\n",
            text_stats$did2_coef, text_stats$did2_se, text_stats$did2_pval))
