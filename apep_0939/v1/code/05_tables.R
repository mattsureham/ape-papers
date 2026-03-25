## 05_tables.R — Generate all LaTeX tables
## apep_0939: Employment Costs of Seismicity Regulation

library(tidyverse)
library(fixest)

data_dir <- "data"
if (!dir.exists(data_dir)) data_dir <- "../data"

tables_dir <- "tables"
if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE)

# Load models and results
models <- readRDS(file.path(data_dir, "models.rds"))
rob_models <- readRDS(file.path(data_dir, "robustness_models.rds"))

panel_total <- read_csv(file.path(data_dir, "panel_total.csv"), show_col_types = FALSE)
panel_213   <- read_csv(file.path(data_dir, "panel_213.csv"), show_col_types = FALSE)
panel_211   <- read_csv(file.path(data_dir, "panel_211.csv"), show_col_types = FALSE)
panel_retail <- read_csv(file.path(data_dir, "panel_retail.csv"), show_col_types = FALSE)
panel_food   <- read_csv(file.path(data_dir, "panel_food.csv"), show_col_types = FALSE)

# Helper: format coefficient with stars
fmt_coef <- function(est, se, pval) {
  stars <- ""
  if (!is.na(pval)) {
    if (pval < 0.01) stars <- "^{***}"
    else if (pval < 0.05) stars <- "^{**}"
    else if (pval < 0.10) stars <- "^{*}"
  }
  sprintf("$%s%s$", formatC(est, format = "f", digits = 4), stars)
}

fmt_se <- function(se) {
  sprintf("(%s)", formatC(se, format = "f", digits = 4))
}

# ===========================================================================
# Table 1: Summary Statistics
# ===========================================================================
cat("=== Table 1: Summary Statistics ===\n")

pre_data <- panel_total %>%
  filter(year <= 2015) %>%
  group_by(county_fips, treated_county) %>%
  summarise(
    mean_emp = mean(emp, na.rm = TRUE),
    mean_wage = mean(avg_wkly_wage, na.rm = TRUE),
    mean_estabs = mean(estabs, na.rm = TRUE),
    .groups = "drop"
  )

mining_213 <- panel_213 %>%
  filter(year <= 2015) %>%
  group_by(county_fips) %>%
  summarise(mining_support_emp = mean(emp, na.rm = TRUE), .groups = "drop")

extraction_211 <- panel_211 %>%
  filter(year <= 2015) %>%
  group_by(county_fips) %>%
  summarise(extraction_emp = mean(emp, na.rm = TRUE), .groups = "drop")

pre_summary <- pre_data %>%
  left_join(mining_213, by = "county_fips") %>%
  left_join(extraction_211, by = "county_fips") %>%
  mutate(across(c(mining_support_emp, extraction_emp), ~replace_na(.x, 0)))

sum_by_group <- function(df, var) {
  df %>% group_by(treated_county) %>%
    summarise(mean = mean(.data[[var]], na.rm = TRUE),
              sd = sd(.data[[var]], na.rm = TRUE), .groups = "drop")
}

vars <- c("mean_emp", "mean_wage", "mean_estabs", "mining_support_emp", "extraction_emp")
var_labels <- c("Total Employment", "Avg Weekly Wage (\\$)",
                "Establishments", "Mining Support Emp (213)", "Oil/Gas Extraction Emp (211)")

tab1_rows <- character()
for (i in seq_along(vars)) {
  s <- sum_by_group(pre_summary, vars[i])
  tr <- s %>% filter(treated_county == 1)
  ct <- s %>% filter(treated_county == 0)
  tab1_rows <- c(tab1_rows, sprintf(
    "%s & %s & %s & %s & %s \\\\",
    var_labels[i],
    formatC(tr$mean, format = "f", digits = 0, big.mark = ","),
    formatC(tr$sd, format = "f", digits = 0, big.mark = ","),
    formatC(ct$mean, format = "f", digits = 0, big.mark = ","),
    formatC(ct$sd, format = "f", digits = 0, big.mark = ",")))
}

n_treated <- nrow(pre_summary %>% filter(treated_county == 1))
n_control <- nrow(pre_summary %>% filter(treated_county == 0))

tab1_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Pre-Treatment Summary Statistics (2014--2015)}\n",
  "\\label{tab:summary}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\toprule\n",
  " & \\multicolumn{2}{c}{Regulated Counties} & \\multicolumn{2}{c}{Control Counties} \\\\\n",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n",
  " & Mean & SD & Mean & SD \\\\\n",
  "\\midrule\n",
  paste(tab1_rows, collapse = "\n"), "\n",
  "\\midrule\n",
  sprintf("Counties & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} \\\\\n",
          n_treated, n_control),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Pre-treatment county-level averages (2014--2015). ",
  "Regulated counties had Arbuckle formation disposal wells subject to OCC volume ",
  "reduction directives. Control counties had no regulated disposal wells. ",
  "Employment and establishments from BLS QCEW (private sector).\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab1_tex, file.path(tables_dir, "tab1_summary.tex"))
cat("Saved tab1_summary.tex\n")


# ===========================================================================
# Table 2: Main Results — Employment Effects by Industry
# ===========================================================================
cat("=== Table 2: Main Results ===\n")

extract_row <- function(m, var = "post") {
  list(
    coef = coef(m)[var],
    se = se(m)[var],
    pval = pvalue(m)[var],
    n = m$nobs,
    r2 = r2(m, "ar2")
  )
}

m <- list(
  extract_row(models$twfe_total),
  extract_row(models$twfe_213),
  extract_row(models$twfe_211),
  extract_row(models$twfe_retail),
  extract_row(models$twfe_food)
)

tab2_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Employment Effects of Injection Volume Caps by Industry}\n",
  "\\label{tab:main}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Total & Mining & Oil/Gas & Retail & Food \\\\\n",
  " & Private & Support & Extraction & Trade & Services \\\\\n",
  "\\midrule\n",
  sprintf("Regulated $\\times$ Post & %s & %s & %s & %s & %s \\\\\n",
          fmt_coef(m[[1]]$coef, m[[1]]$se, m[[1]]$pval),
          fmt_coef(m[[2]]$coef, m[[2]]$se, m[[2]]$pval),
          fmt_coef(m[[3]]$coef, m[[3]]$se, m[[3]]$pval),
          fmt_coef(m[[4]]$coef, m[[4]]$se, m[[4]]$pval),
          fmt_coef(m[[5]]$coef, m[[5]]$se, m[[5]]$pval)),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          fmt_se(m[[1]]$se), fmt_se(m[[2]]$se), fmt_se(m[[3]]$se),
          fmt_se(m[[4]]$se), fmt_se(m[[5]]$se)),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  "Year-Quarter FE & Yes & Yes & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          formatC(m[[1]]$n, big.mark = ","),
          formatC(m[[2]]$n, big.mark = ","),
          formatC(m[[3]]$n, big.mark = ","),
          formatC(m[[4]]$n, big.mark = ","),
          formatC(m[[5]]$n, big.mark = ",")),
  sprintf("Adj.~$R^2$ & %s & %s & %s & %s & %s \\\\\n",
          formatC(m[[1]]$r2, format = "f", digits = 3),
          formatC(m[[2]]$r2, format = "f", digits = 3),
          formatC(m[[3]]$r2, format = "f", digits = 3),
          formatC(m[[4]]$r2, format = "f", digits = 3),
          formatC(m[[5]]$r2, format = "f", digits = 3)),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Each column reports a TWFE regression of log employment on a ",
  "post-treatment indicator for regulated counties, with county and year-quarter fixed effects. ",
  "Standard errors clustered at the county level in parentheses. ",
  "Regulated counties had Arbuckle disposal wells subject to OCC volume reduction directives ",
  "(OWRA November 2015, OCRA March 2016). ",
  "Columns (4) and (5) are placebo industries. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab2_tex, file.path(tables_dir, "tab2_main.tex"))
cat("Saved tab2_main.tex\n")


# ===========================================================================
# Table 3: Robustness
# ===========================================================================
cat("=== Table 3: Robustness ===\n")

r1 <- extract_row(models$twfe_total)
r2_cont <- extract_row(rob_models$twfe_continuous, "intensity_post")
r3_ctrl <- extract_row(rob_models$twfe_ctrl, "post")
r5_plac <- extract_row(rob_models$twfe_placebo, "fake_post")

# DDD model has different coefficient names
ddd_names <- names(coef(rob_models$twfe_ddd))
ddd_mining_idx <- grep("mining_sector::1", ddd_names)
r4_ddd <- list(
  coef = coef(rob_models$twfe_ddd)[ddd_mining_idx],
  se = se(rob_models$twfe_ddd)[ddd_mining_idx],
  pval = pvalue(rob_models$twfe_ddd)[ddd_mining_idx],
  n = rob_models$twfe_ddd$nobs,
  r2 = r2(rob_models$twfe_ddd, "ar2")
)

tab3_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness: Alternative Specifications}\n",
  "\\label{tab:robustness}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) & (4) & (5) \\\\\n",
  " & Baseline & Continuous & Oil & DDD: Mining & Placebo \\\\\n",
  " & TWFE & Intensity & Control & vs.~Retail & 2015 Q1 \\\\\n",
  "\\midrule\n",
  sprintf("Treatment & %s & %s & %s & %s & %s \\\\\n",
          fmt_coef(r1$coef, r1$se, r1$pval),
          fmt_coef(r2_cont$coef, r2_cont$se, r2_cont$pval),
          fmt_coef(r3_ctrl$coef, r3_ctrl$se, r3_ctrl$pval),
          fmt_coef(r4_ddd$coef, r4_ddd$se, r4_ddd$pval),
          fmt_coef(r5_plac$coef, r5_plac$se, r5_plac$pval)),
  sprintf(" & %s & %s & %s & %s & %s \\\\\n",
          fmt_se(r1$se), fmt_se(r2_cont$se), fmt_se(r3_ctrl$se),
          fmt_se(r4_ddd$se), fmt_se(r5_plac$se)),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes & C$\\times$S & Yes \\\\\n",
  "Year-Quarter FE & Yes & Yes & Yes & YQ$\\times$S & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s & %s & %s \\\\\n",
          formatC(r1$n, big.mark = ","),
          formatC(r2_cont$n, big.mark = ","),
          formatC(r3_ctrl$n, big.mark = ","),
          formatC(r4_ddd$n, big.mark = ","),
          formatC(r5_plac$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} Column (1) reproduces the baseline. ",
  "Column (2) uses continuous treatment (pre-directive mining share $\\times$ post). ",
  "Column (3) controls for oil extraction share $\\times$ time trend. ",
  "Column (4) reports the triple-difference coefficient on regulated $\\times$ post $\\times$ mining sector, ",
  "comparing NAICS 213 to retail within the same counties. ",
  "Column (5) is a placebo with fake treatment in 2015~Q1 on the pre-treatment sample. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab3_tex, file.path(tables_dir, "tab3_robustness.tex"))
cat("Saved tab3_robustness.tex\n")


# ===========================================================================
# Table 4: Wage Effects
# ===========================================================================
cat("=== Table 4: Wages ===\n")

panel_total_w <- panel_total %>% mutate(log_wage = log(avg_wkly_wage))
panel_213_w <- panel_213 %>% mutate(log_wage = log(avg_wkly_wage))
panel_211_w <- panel_211 %>% mutate(log_wage = log(avg_wkly_wage))

twfe_wage_total <- feols(log_wage ~ post | county_fips + yq,
                          data = panel_total_w %>% filter(is.finite(log_wage)),
                          cluster = ~county_fips)
twfe_wage_213 <- feols(log_wage ~ post | county_fips + yq,
                        data = panel_213_w %>% filter(is.finite(log_wage)),
                        cluster = ~county_fips)
twfe_wage_211 <- feols(log_wage ~ post | county_fips + yq,
                        data = panel_211_w %>% filter(is.finite(log_wage)),
                        cluster = ~county_fips)

wm <- list(
  extract_row(twfe_wage_total),
  extract_row(twfe_wage_213),
  extract_row(twfe_wage_211)
)

tab4_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Wage Effects of Injection Volume Caps}\n",
  "\\label{tab:wages}\n",
  "\\begin{threeparttable}\n",
  "\\begin{tabular}{lccc}\n",
  "\\toprule\n",
  " & (1) & (2) & (3) \\\\\n",
  " & Total Private & Mining Support & Oil/Gas Extraction \\\\\n",
  "\\midrule\n",
  sprintf("Regulated $\\times$ Post & %s & %s & %s \\\\\n",
          fmt_coef(wm[[1]]$coef, wm[[1]]$se, wm[[1]]$pval),
          fmt_coef(wm[[2]]$coef, wm[[2]]$se, wm[[2]]$pval),
          fmt_coef(wm[[3]]$coef, wm[[3]]$se, wm[[3]]$pval)),
  sprintf(" & %s & %s & %s \\\\\n",
          fmt_se(wm[[1]]$se), fmt_se(wm[[2]]$se), fmt_se(wm[[3]]$se)),
  "\\midrule\n",
  "County FE & Yes & Yes & Yes \\\\\n",
  "Year-Quarter FE & Yes & Yes & Yes \\\\\n",
  sprintf("Observations & %s & %s & %s \\\\\n",
          formatC(wm[[1]]$n, big.mark = ","),
          formatC(wm[[2]]$n, big.mark = ","),
          formatC(wm[[3]]$n, big.mark = ",")),
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  "\\item \\textit{Notes:} TWFE regressions of log average weekly wage on the post-treatment indicator. ",
  "County and year-quarter fixed effects. Standard errors clustered at the county level. ",
  "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$.\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(tab4_tex, file.path(tables_dir, "tab4_wages.tex"))
cat("Saved tab4_wages.tex\n")


# ===========================================================================
# Table F1: SDE Appendix (MANDATORY)
# ===========================================================================
cat("=== Table F1: SDE ===\n")

compute_sde <- function(panel, model_obj, label) {
  pre_sd <- panel %>%
    filter(yq < min(first_treat_yq[first_treat_yq > 0], na.rm = TRUE)) %>%
    pull(log_emp) %>%
    sd(na.rm = TRUE)
  beta <- coef(model_obj)["post"]
  se_b <- se(model_obj)["post"]
  sde <- beta / pre_sd
  se_sde <- se_b / pre_sd
  classify <- function(x) {
    if (x < -0.15) return("Large negative")
    if (x < -0.05) return("Moderate negative")
    if (x < -0.005) return("Small negative")
    if (x <= 0.005) return("Null")
    if (x <= 0.05) return("Small positive")
    if (x <= 0.15) return("Moderate positive")
    return("Large positive")
  }
  tibble(outcome = label, beta = beta, se = se_b, sd_y = pre_sd,
         sde = sde, se_sde = se_sde, classification = classify(sde))
}

sde_a <- bind_rows(
  compute_sde(panel_total, models$twfe_total, "Total Employment"),
  compute_sde(panel_213, models$twfe_213, "Mining Support (213)"),
  compute_sde(panel_211, models$twfe_211, "Oil/Gas Extraction (211)")
)

# Panel B: OWRA vs OCRA
panel_owra <- panel_total %>% filter(directive_area == "OWRA" | treated_county == 0)
panel_ocra <- panel_total %>% filter(directive_area == "OCRA" | treated_county == 0)
twfe_owra <- feols(log_emp ~ post | county_fips + yq, data = panel_owra, cluster = ~county_fips)
twfe_ocra <- feols(log_emp ~ post | county_fips + yq, data = panel_ocra, cluster = ~county_fips)

sde_b <- bind_rows(
  compute_sde(panel_owra, twfe_owra, "OWRA Counties (Western)"),
  compute_sde(panel_ocra, twfe_ocra, "OCRA Counties (Central)")
)

fmt_sde_row <- function(r) {
  sprintf("%s & %s & (%s) & %s & %s & (%s) & %s \\\\",
          r$outcome,
          formatC(r$beta, format = "f", digits = 4),
          formatC(r$se, format = "f", digits = 4),
          formatC(r$sd_y, format = "f", digits = 3),
          formatC(r$sde, format = "f", digits = 4),
          formatC(r$se_sde, format = "f", digits = 4),
          r$classification)
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Did Oklahoma's geographically targeted wastewater injection volume caps (2015--2017) reduce local employment in regulated counties? ",
  "\\textbf{Policy mechanism:} The Oklahoma Corporation Commission mandated 40\\% reductions in wastewater disposal volumes at Arbuckle formation wells across two geographic areas (OWRA and OCRA), directly curtailing injection well operations that service the oil and gas industry. ",
  "\\textbf{Outcome definition:} Log quarterly county-level employment from BLS QCEW (private sector); total employment for the pooled panel, NAICS 213 (support activities for mining) and NAICS 211 (oil and gas extraction) for industry-specific effects. ",
  "\\textbf{Treatment:} Binary; county has Arbuckle disposal wells subject to OCC volume reduction directives vs.~no regulated wells. ",
  "\\textbf{Data:} BLS QCEW quarterly county-level employment, 77 Oklahoma counties, 2014--2020, approximately 2,100 county-quarter observations. ",
  "\\textbf{Method:} Two-way fixed effects (county + year-quarter FE), standard errors clustered at the county level; robustness via Callaway--Sant'Anna, wild cluster bootstrap, and leave-one-out. ",
  "\\textbf{Sample:} All 77 Oklahoma counties; 20 regulated (with Arbuckle disposal wells) and 57 control counties. Panel B splits regulated counties by directive area: OWRA (10 western counties, treated November 2015) and OCRA (10 central counties, treated March 2016). ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ where SD($Y$) is the pre-treatment ",
  "standard deviation. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sde_tex <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{threeparttable}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\toprule\n",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\\n",
  paste(sapply(1:nrow(sde_a), function(i) fmt_sde_row(sde_a[i,])), collapse = "\n"), "\n",
  "\\midrule\n",
  "\\multicolumn{7}{l}{\\textit{Panel B: By Directive Area (Total Employment)}} \\\\\n",
  paste(sapply(1:nrow(sde_b), function(i) fmt_sde_row(sde_b[i,])), collapse = "\n"), "\n",
  "\\bottomrule\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{threeparttable}\n",
  "\\end{table}\n"
)
writeLines(sde_tex, file.path(tables_dir, "tabF1_sde.tex"))
cat("Saved tabF1_sde.tex\n")

cat("\nAll tables generated.\n")
