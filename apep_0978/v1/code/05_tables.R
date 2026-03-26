## 05_tables.R — Generate all LaTeX tables
## apep_0978: From Rice Paddies to Solar Panels

source("00_packages.R")

df <- read_csv("../data/clean_panel.csv", show_col_types = FALSE)
results <- readRDS("../data/main_results.rds")
rob <- readRDS("../data/robustness_results.rds")

## -------------------------------------------------------------------------
## Table 1: Summary Statistics (pre-treatment, 2005-2011)
## -------------------------------------------------------------------------

cat("=== Generating Table 1: Summary Statistics ===\n")

df_pre <- df %>% filter(year <= 2011)

## Compute statistics
make_row <- function(data, var, label) {
  vals <- data[[var]]
  vals <- vals[!is.na(vals)]
  sprintf("%s & %.0f & %.0f & %.0f & %.0f \\\\",
          label, mean(vals), sd(vals), min(vals), max(vals))
}

tab1_rows <- c(
  make_row(df_pre, "cultivated_land_total", "Cultivated land (ha)"),
  make_row(df_pre, "paddy_area", "Paddy area (ha)"),
  make_row(df_pre, "field_area", "Upland field area (ha)"),
  sprintf("Upland share & %.3f & %.3f & %.3f & %.3f \\\\",
          mean(df_pre$upland_share_tv, na.rm = TRUE),
          sd(df_pre$upland_share_tv, na.rm = TRUE),
          min(df_pre$upland_share_tv, na.rm = TRUE),
          max(df_pre$upland_share_tv, na.rm = TRUE)),
  make_row(df_pre, "farm_households_total", "Farm households")
)

n_obs_pre <- nrow(df_pre)
n_pref <- n_distinct(df_pre$area_code)

tab1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Pre-FIT Period (2005--2011)}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lrrrr}\n",
  "\\toprule\n",
  "Variable & Mean & Std.\\ Dev. & Min & Max \\\\\n",
  "\\midrule\n",
  paste(tab1_rows, collapse = "\n"),
  "\n\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sprintf("\\item \\textit{Notes:} N = %s prefecture-year observations across %d prefectures, 2005--2011. Cultivated land area and subcomponents from MAFF Cultivated Land Survey via Japan e-Stat. Population from Japan Statistical Yearbook. Farm households include both commercial and self-sufficient categories.\n",
          format(n_obs_pre, big.mark = ","), n_pref),
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:summary}\n",
  "\\end{table}\n"
)

writeLines(tab1_tex, "../tables/tab1_summary.tex")
cat("  Saved tables/tab1_summary.tex\n")

## -------------------------------------------------------------------------
## Table 2: Main Results
## -------------------------------------------------------------------------

cat("=== Generating Table 2: Main Results ===\n")

m1 <- results$m1
m2 <- results$m2
m3 <- results$m3
m4 <- results$m4
m_binary <- results$m_binary

## Extract coefficients
get_coef_row <- function(model, varname) {
  b <- coef(model)[varname]
  s <- se(model)[varname]
  p <- pvalue(model)[varname]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  list(b = b, se = s, p = p, stars = stars,
       b_str = sprintf("%.6f%s", b, stars),
       se_str = sprintf("(%.6f)", s))
}

r1 <- get_coef_row(m1, "treatment_intensity")
r2 <- get_coef_row(m2, "treatment_intensity")
r3 <- get_coef_row(m3, "treatment_intensity")
r4 <- get_coef_row(m4, "treatment_intensity")

tab2_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Effect of FIT Subsidies on Cultivated Land}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  " & Total Land & Total Land & Paddy & Upland \\\\\n",
  "\\midrule\n",
  sprintf("FIT Rate $\\times$ Upland Share & %s & %s & %s & %s \\\\\n",
          r1$b_str, r2$b_str, r3$b_str, r4$b_str),
  sprintf(" & %s & %s & %s & %s \\\\\n",
          r1$se_str, r2$se_str, r3$se_str, r4$se_str),
  "\\addlinespace\n",
  "Farm HH control & No & Yes & No & No \\\\\n",
  "Prefecture FE & Yes & Yes & Yes & Yes \\\\\n",
  "Year FE & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s \\\\\n",
          format(nobs(m1), big.mark = ","),
          format(nobs(m2), big.mark = ","),
          format(nobs(m3), big.mark = ","),
          format(nobs(m4), big.mark = ",")),
  sprintf("R$^2$ (within) & %.4f & %.4f & %.4f & %.4f \\\\\n",
          fitstat(m1, "wr2")$wr2, fitstat(m2, "wr2")$wr2,
          fitstat(m3, "wr2")$wr2, fitstat(m4, "wr2")$wr2),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Standard errors clustered at the prefecture level in parentheses. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "The dependent variable is the log of cultivated land area (hectares) by type. ",
  "Treatment intensity is the interaction of the national FIT rate (Yen/kWh) with the prefecture's pre-FIT (2009--2011) upland field share. ",
  "Columns (1)--(2) use total cultivated land; column (3) uses paddy area (placebo); column (4) uses upland field area. ",
  "Sample: 47 Japanese prefectures, 2005--2022.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:main}\n",
  "\\end{table}\n"
)

writeLines(tab2_tex, "../tables/tab2_main.tex")
cat("  Saved tables/tab2_main.tex\n")

## -------------------------------------------------------------------------
## Table 3: Event Study Coefficients
## -------------------------------------------------------------------------

cat("=== Generating Table 3: Event Study ===\n")

m_es <- results$m_es
es_ct <- as.data.frame(coeftable(m_es))
es_ct$term <- rownames(es_ct)

## Parse relative year from term names
es_ct <- es_ct %>%
  mutate(
    rel_year = as.numeric(gsub(".*::([-0-9]+).*", "\\1", term))
  ) %>%
  filter(!is.na(rel_year)) %>%
  arrange(rel_year)

## Add reference year
ref_row <- tibble(rel_year = -1, Estimate = 0, `Std. Error` = NA,
                  `t value` = NA, `Pr(>|t|)` = NA, term = "ref")
es_ct <- bind_rows(es_ct, ref_row) %>% arrange(rel_year)

## Format table
es_rows <- es_ct %>%
  mutate(
    stars = case_when(
      is.na(`Pr(>|t|)`) ~ "",
      `Pr(>|t|)` < 0.01 ~ "***",
      `Pr(>|t|)` < 0.05 ~ "**",
      `Pr(>|t|)` < 0.1 ~ "*",
      TRUE ~ ""
    ),
    yr_label = ifelse(rel_year >= 0,
                      sprintf("$t+%d$ (%d)", rel_year, 2012 + rel_year),
                      sprintf("$t%d$ (%d)", rel_year, 2012 + rel_year)),
    coef_str = ifelse(is.na(`Std. Error`),
                      "---",
                      sprintf("%.6f%s", Estimate, stars)),
    se_str = ifelse(is.na(`Std. Error`), "", sprintf("(%.6f)", `Std. Error`))
  )

es_body <- paste(
  sprintf("%s & %s \\\\\n & %s \\\\", es_rows$yr_label, es_rows$coef_str, es_rows$se_str),
  collapse = "\n\\addlinespace\n"
)

tab3_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Event Study: Interaction of Upland Share with Year Indicators}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lc}\n",
  "\\toprule\n",
  "Year (relative to FIT) & Upland Share $\\times$ Year \\\\\n",
  "\\midrule\n",
  es_body, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Coefficients from regressing log cultivated land on interactions of pre-FIT upland share with year indicators, with prefecture and year fixed effects. ",
  "Base year: $t-1$ (2011). Standard errors clustered at the prefecture level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:eventstudy}\n",
  "\\end{table}\n"
)

writeLines(tab3_tex, "../tables/tab3_eventstudy.tex")
cat("  Saved tables/tab3_eventstudy.tex\n")

## -------------------------------------------------------------------------
## Table 4: Robustness
## -------------------------------------------------------------------------

cat("=== Generating Table 4: Robustness ===\n")

## Collect all robustness specs
specs <- list(
  list(name = "Baseline", model = results$m1),
  list(name = "Excl.\\ Tokyo", model = rob$loo$Tokyo),
  list(name = "Excl.\\ Hokkaido", model = rob$loo$Hokkaido),
  list(name = "Excl.\\ Okinawa", model = rob$loo$Okinawa),
  list(name = "2008--2018 window", model = rob$narrow),
  list(name = "Pre-amendment (2005--2016)", model = rob$pre17),
  list(name = "Land weighted", model = rob$weighted),
  list(name = "Pref.\\ trends", model = rob$trend)
)

rob_rows <- sapply(specs, function(s) {
  b <- coef(s$model)["treatment_intensity"]
  se_val <- se(s$model)["treatment_intensity"]
  p <- pvalue(s$model)["treatment_intensity"]
  stars <- ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
  n <- nobs(s$model)
  sprintf("%s & %.6f%s & (%.6f) & %s \\\\",
          s$name, b, stars, se_val, format(n, big.mark = ","))
})

tab4_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Robustness of Main Results}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  "Specification & Coefficient & Std.\\ Error & N \\\\\n",
  "\\midrule\n",
  paste(rob_rows, collapse = "\n"),
  sprintf("\n\\addlinespace\nRI $p$-value & \\multicolumn{3}{c}{%.3f (1,000 permutations)} \\\\\n",
          rob$ri_p),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row reports the coefficient on FIT Rate $\\times$ Upland Share from a separate regression of log cultivated land with prefecture and year fixed effects. ",
  "Standard errors clustered at the prefecture level. ",
  "* $p<0.10$, ** $p<0.05$, *** $p<0.01$. ",
  "RI $p$-value from 1,000 permutations of upland share assignments across prefectures.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\label{tab:robustness}\n",
  "\\end{table}\n"
)

writeLines(tab4_tex, "../tables/tab4_robustness.tex")
cat("  Saved tables/tab4_robustness.tex\n")

## -------------------------------------------------------------------------
## Table F1: Standardized Effect Sizes (SDE)
## -------------------------------------------------------------------------

cat("=== Generating Table F1: SDE ===\n")

## Classification function
classify_sde <- function(s) {
  case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

## Main outcome: total cultivated land
beta_total <- coef(results$m1)["treatment_intensity"]
se_total <- se(results$m1)["treatment_intensity"]
sd_y_total <- sd(df$log_cultivated)
sd_x <- sd(df$treatment_intensity)
sde_total <- beta_total * sd_x / sd_y_total
se_sde_total <- se_total * sd_x / sd_y_total

## Upland field outcome
beta_field <- coef(results$m4)["treatment_intensity"]
se_field <- se(results$m4)["treatment_intensity"]
sd_y_field <- sd(df$log_field)
sde_field <- beta_field * sd_x / sd_y_field
se_sde_field <- se_field * sd_x / sd_y_field

## Paddy outcome (placebo)
beta_paddy <- coef(results$m3)["treatment_intensity"]
se_paddy <- se(results$m3)["treatment_intensity"]
sd_y_paddy <- sd(df$log_paddy)
sde_paddy <- beta_paddy * sd_x / sd_y_paddy
se_sde_paddy <- se_paddy * sd_x / sd_y_paddy

## Heterogeneity: High vs low upland quartiles
df_q4 <- df %>% filter(upland_quartile == "Q4 (high)")
df_q1 <- df %>% filter(upland_quartile == "Q1 (low)")

m_q4 <- feols(log_cultivated ~ treatment_intensity | area_code + year,
              data = df_q4, cluster = ~area_code)
m_q1 <- feols(log_cultivated ~ treatment_intensity | area_code + year,
              data = df_q1, cluster = ~area_code)

beta_q4 <- coef(m_q4)["treatment_intensity"]
se_q4 <- se(m_q4)["treatment_intensity"]
sd_y_q4 <- sd(df_q4$log_cultivated)
sd_x_q4 <- sd(df_q4$treatment_intensity)
sde_q4 <- beta_q4 * sd_x_q4 / sd_y_q4
se_sde_q4 <- se_q4 * sd_x_q4 / sd_y_q4

beta_q1 <- coef(m_q1)["treatment_intensity"]
se_q1 <- se(m_q1)["treatment_intensity"]
sd_y_q1 <- sd(df_q1$log_cultivated)
sd_x_q1 <- sd(df_q1$treatment_intensity)
sde_q1 <- beta_q1 * sd_x_q1 / sd_y_q1
se_sde_q1 <- se_q1 * sd_x_q1 / sd_y_q1

## Build SDE table
sde_rows_a <- sprintf(
  paste0(
    "Total cultivated land & %.6f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    "Upland field area & %.6f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    "Paddy area (placebo) & %.6f & %.4f & %.4f & %.4f & %.4f & %s \\\\"
  ),
  beta_total, sd_x, sd_y_total, sde_total, se_sde_total, classify_sde(sde_total),
  beta_field, sd_x, sd_y_field, sde_field, se_sde_field, classify_sde(sde_field),
  beta_paddy, sd_x, sd_y_paddy, sde_paddy, se_sde_paddy, classify_sde(sde_paddy)
)

sde_rows_b <- sprintf(
  paste0(
    "Total land (Q4 upland) & %.6f & %.4f & %.4f & %.4f & %.4f & %s \\\\\n",
    "Total land (Q1 upland) & %.6f & %.4f & %.4f & %.4f & %.4f & %s \\\\"
  ),
  beta_q4, sd_x_q4, sd_y_q4, sde_q4, se_sde_q4, classify_sde(sde_q4),
  beta_q1, sd_x_q1, sd_y_q1, sde_q1, se_sde_q1, classify_sde(sde_q1)
)

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Japan. ",
  "\\textbf{Research question:} Does Japan's feed-in tariff for solar photovoltaics accelerate the conversion of agricultural land, and does this effect concentrate on upland fields that are easier to convert than irrigated paddy? ",
  "\\textbf{Policy mechanism:} The 2012 Renewable Energy Act guaranteed above-market electricity purchase prices (initially 40 Yen/kWh) for solar PV installations, creating a direct financial incentive for landowners to convert farmland to solar farms; the rate declined roughly 75 percent over the subsequent decade as the program matured. ",
  "\\textbf{Outcome definition:} Log of cultivated land area in hectares, from the MAFF Cultivated Land Survey, separately for total, paddy (irrigated rice), and upland (dry field) categories. ",
  "\\textbf{Treatment:} Continuous interaction of the national FIT rate (Yen/kWh, ranging from 0 pre-2012 to 40 at introduction to 11 by 2022) with the prefecture's pre-FIT share of cultivated land classified as upland field (ranging from 0.04 to 0.98 across prefectures). ",
  "\\textbf{Data:} Japan e-Stat (table 0000010103), 47 prefectures, 2005--2022, 846 prefecture-year observations. ",
  "\\textbf{Method:} Continuous difference-in-differences with prefecture and year fixed effects, standard errors clustered at the prefecture level. ",
  "\\textbf{Sample:} All 47 Japanese prefectures with non-missing cultivated land data; Panel B splits at the 25th and 75th percentiles of pre-FIT upland share. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard deviation of the treatment intensity and SD($Y$) is the unconditional standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_tex <- paste0(
  "\\begin{table}[H]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes for Main Outcomes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  sde_rows_a, "\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (by pre-FIT upland share quartile)}} \\\\\n",
  sde_rows_b, "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)

writeLines(tabF1_tex, "../tables/tabF1_sde.tex")
cat("  Saved tables/tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
