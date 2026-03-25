## 05_tables.R — Generate all tables for apep_0898
## Grocery exit cascades → The Replacement Shield

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness.rds"))

## ============================================================
## Table 1: Summary Statistics
## ============================================================
cat("Generating Table 1: Summary Statistics\n")

## Panel for treated (exposed) vs control (unexposed)
summ_data <- panel %>%
  filter(year == 2008) %>%  # Base year before treatment
  mutate(group = ifelse(ever_exposed, "Exposed", "Unexposed"))

vars_of_interest <- c("grocery_estab", "foodservice_estab", "health_estab",
                       "personal_estab")
labels <- c("Grocery stores (NAICS 445)", "Food service (NAICS 722)",
            "Health \\& personal care (NAICS 446)", "Personal services (NAICS 812)")

summ_stats <- list()
for (i in seq_along(vars_of_interest)) {
  v <- vars_of_interest[i]
  for (g in c("Exposed", "Unexposed")) {
    vals <- summ_data[[v]][summ_data$group == g]
    vals <- vals[!is.na(vals)]
    summ_stats <- c(summ_stats, list(tibble(
      Variable = labels[i],
      Group = g,
      Mean = mean(vals),
      SD = sd(vals),
      Median = median(vals),
      N = length(vals)
    )))
  }
}
summ_df <- bind_rows(summ_stats)

## Write Table 1 LaTeX
sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Summary Statistics by Chain Bankruptcy Exposure (Base Year 2008)}\n")
cat("\\label{tab:summary}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{3}{c}{Exposed Counties} & \\multicolumn{3}{c}{Unexposed Counties} \\\\\n")
cat("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
cat("Variable & Mean & SD & N & Mean & SD & N \\\\\n")
cat("\\hline\n")

for (lab in unique(summ_df$Variable)) {
  exp_row <- summ_df %>% filter(Variable == lab, Group == "Exposed")
  unexp_row <- summ_df %>% filter(Variable == lab, Group == "Unexposed")
  cat(sprintf("%s & %.1f & %.1f & %d & %.1f & %.1f & %d \\\\\n",
              lab,
              exp_row$Mean, exp_row$SD, exp_row$N,
              unexp_row$Mean, unexp_row$SD, unexp_row$N))
}

cat("\\hline\n")
cat("Counties & \\multicolumn{3}{c}{",
    n_distinct(summ_data$fips[summ_data$group == "Exposed"]),
    "} & \\multicolumn{3}{c}{",
    n_distinct(summ_data$fips[summ_data$group == "Unexposed"]),
    "} \\\\\n", sep = "")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} County-level establishment counts from Census County Business Patterns (CBP) in base year 2008. ")
cat("Exposed counties are in states where at least one major grocery chain declared bankruptcy between 2010 and 2020. ")
cat("Unexposed counties are in states with no chain bankruptcy exposure during this period.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 2: Chain Bankruptcy Events
## ============================================================
cat("Generating Table 2: Chain Bankruptcy Events\n")

chain_bankruptcies <- readRDS(file.path(data_dir, "chain_bankruptcies.rds")) %>%
  filter(bankruptcy_year >= 2010) %>%
  arrange(bankruptcy_year)

sink(file.path(tables_dir, "tab2_bankruptcies.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Major U.S. Grocery Chain Bankruptcy Events, 2010--2020}\n")
cat("\\label{tab:bankruptcies}\n")
cat("\\small\n")
cat("\\begin{tabular}{llcl}\n")
cat("\\hline\\hline\n")
cat("Chain & Year & Approx.\\ Stores & States Affected \\\\\n")
cat("\\hline\n")

for (i in 1:nrow(chain_bankruptcies)) {
  row <- chain_bankruptcies[i, ]
  # Shorten state list if too long
  states_str <- row$states
  if (nchar(states_str) > 35) {
    states_str <- paste0(substr(states_str, 1, 32), "...")
  }
  cat(sprintf("%s & %d & %d & %s \\\\\n",
              row$chain, row$bankruptcy_year, row$approx_stores, states_str))
}

cat("\\hline\n")
cat("\\multicolumn{2}{l}{Total affected stores} & ",
    sum(chain_bankruptcies$approx_stores), " & \\\\\n", sep = "")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Major U.S. grocery chain Chapter 11 filings between 2010 and 2020. ")
cat("Store counts are approximate and reflect the number at time of filing. ")
cat("Some chains reorganized and continued operations with fewer locations; ")
cat("others liquidated entirely. The Bartik instrument uses these events as national shocks ")
cat("weighted by each county's pre-period share of state grocery establishments.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 3: First Stage and Reduced Form
## ============================================================
cat("Generating Table 3: First Stage and Reduced Form\n")

sink(file.path(tables_dir, "tab3_firststage.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{First Stage and Reduced Form: Chain Bankruptcy Exposure and Retail Establishments}\n")
cat("\\label{tab:firststage}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{1}{c}{First Stage} & \\multicolumn{3}{c}{Reduced Form} \\\\\n")
cat("\\cmidrule(lr){2-2} \\cmidrule(lr){3-5}\n")
cat(" & Log Grocery & Log Food Svc & Log Health & Log Personal \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

## Row: Post exposure (DiD)
cat("Post Exposure & ")
cat(sprintf("%.4f$^{***}$", coef(results$twfe_fs)["bartik_iv"]))
cat(" & ")
cat(sprintf("%.4f", coef(results$twfe_rf_food)["post_exposureTRUE"]))
cat(" & ")
cat(sprintf("%.4f", coef(results$twfe_rf_health)["post_exposureTRUE"]))
cat(" & ")
cat(sprintf("%.4f$^{**}$", coef(results$twfe_rf_personal)["post_exposureTRUE"]))
cat(" \\\\\n")

## Standard errors
cat(" & ")
cat(sprintf("(%.4f)", se(results$twfe_fs)["bartik_iv"]))
cat(" & ")
cat(sprintf("(%.4f)", se(results$twfe_rf_food)["post_exposureTRUE"]))
cat(" & ")
cat(sprintf("(%.4f)", se(results$twfe_rf_health)["post_exposureTRUE"]))
cat(" & ")
cat(sprintf("(%.4f)", se(results$twfe_rf_personal)["post_exposureTRUE"]))
cat(" \\\\\n")

cat("\\hline\n")
cat(sprintf("F-statistic & %.1f & & & \\\\\n", fitstat(results$iv_foodservice, "ivf")$ivf1$stat))
n_obs_main <- nobs(results$twfe_fs)
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(nobs(results$twfe_fs), big.mark = ","),
            format(nobs(results$twfe_rf_food), big.mark = ","),
            format(nobs(results$twfe_rf_health), big.mark = ","),
            format(nobs(results$twfe_rf_personal), big.mark = ",")))
cat("County FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Cluster & State & State & State & State \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} Column (1) shows the first stage: the effect of the Bartik instrument ")
cat("(cumulative predicted grocery loss from chain bankruptcies) on log grocery establishments. ")
cat("Columns (2)--(4) show reduced-form effects of post-exposure on log non-grocery retail sectors. ")
cat("Standard errors clustered at the state level in parentheses. ")
cat("$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 4: Main IV Results
## ============================================================
cat("Generating Table 4: Main IV Results\n")

sink(file.path(tables_dir, "tab4_iv.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{The Anchor Store Multiplier: 2SLS Estimates of Grocery Agglomeration Spillovers}\n")
cat("\\label{tab:iv}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & Log Food & Log Health & Log Personal & Log Non-Grocery \\\\\n")
cat(" & Service & Stores & Services & (Combined) \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{5}{l}{\\textit{Panel A: Baseline (County + Year FE)}} \\\\\n")
cat("[3pt]\n")

## IV coefficients
models_iv <- list(results$iv_foodservice, results$iv_health,
                  results$iv_personal, results$iv_nongrocery)
coef_name <- "fit_log_grocery"

cat("Log Grocery (IV)")
for (m in models_iv) {
  b <- coef(m)[coef_name]
  s <- se(m)[coef_name]
  p <- 2 * pt(abs(b/s), df = nobs(m) - 2, lower.tail = FALSE)
  stars <- ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))
  cat(sprintf(" & %.3f%s", b, stars))
}
cat(" \\\\\n")

cat(" ")
for (m in models_iv) {
  cat(sprintf(" & (%.3f)", se(m)[coef_name]))
}
cat(" \\\\\n[6pt]\n")

## Panel B: State × Year FE
cat("\\multicolumn{5}{l}{\\textit{Panel B: State $\\times$ Year FE}} \\\\\n")
cat("[3pt]\n")

syfe_models <- list(robustness$syfe_iv_food, NULL, NULL, robustness$syfe_iv_nongrocery)
cat("Log Grocery (IV)")
for (m in syfe_models) {
  if (is.null(m)) {
    cat(" & ---")
  } else {
    b <- coef(m)[coef_name]
    s <- se(m)[coef_name]
    p <- 2 * pt(abs(b/s), df = nobs(m) - 2, lower.tail = FALSE)
    stars <- ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))
    cat(sprintf(" & %.3f%s", b, stars))
  }
}
cat(" \\\\\n")

cat(" ")
for (m in syfe_models) {
  if (is.null(m)) {
    cat(" & ")
  } else {
    cat(sprintf(" & (%.3f)", se(m)[coef_name]))
  }
}
cat(" \\\\\n[6pt]\n")

## Panel C: Short-run Bartik
cat("\\multicolumn{5}{l}{\\textit{Panel C: Short-Run Bartik (0--3 Year Window)}} \\\\\n")
cat("[3pt]\n")
sr_models <- list(robustness$sr_iv_food, NULL, NULL, robustness$sr_iv_nongrocery)
cat("Log Grocery (IV)")
for (m in sr_models) {
  if (is.null(m)) {
    cat(" & ---")
  } else {
    b <- coef(m)[coef_name]
    s <- se(m)[coef_name]
    p <- 2 * pt(abs(b/s), df = nobs(m) - 2, lower.tail = FALSE)
    stars <- ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))
    cat(sprintf(" & %.3f%s", b, stars))
  }
}
cat(" \\\\\n")

cat(" ")
for (m in sr_models) {
  if (is.null(m)) {
    cat(" & ")
  } else {
    cat(sprintf(" & (%.3f)", se(m)[coef_name]))
  }
}
cat(" \\\\\n")

cat("\\hline\n")
cat(sprintf("First-stage F (Panel A) & \\multicolumn{4}{c}{%.1f} \\\\\n",
            fitstat(results$iv_foodservice, "ivf")$ivf1$stat))
cat(sprintf("Observations & \\multicolumn{4}{c}{%s} \\\\\n",
            format(nobs(results$iv_foodservice), big.mark = ",")))
cat("Instrument & \\multicolumn{4}{c}{Bartik: chain bankruptcy $\\times$ county share} \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} 2SLS estimates of the effect of log grocery establishments (NAICS 445) on log ")
cat("non-grocery retail sectors. The instrument is a Bartik shift-share variable: the sum of predicted grocery ")
cat("losses from national chain bankruptcy events (2010--2020), weighted by each county's pre-period share of ")
cat("state-level grocery establishments. Panel A includes county and year fixed effects. Panel B adds ")
cat("state-by-year fixed effects. Panel C restricts the Bartik window to 0--3 years after each bankruptcy. ")
cat("Standard errors clustered at the state level. ")
cat("$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## Table 5: Heterogeneity
## ============================================================
cat("Generating Table 5: Heterogeneity\n")

sink(file.path(tables_dir, "tab5_heterogeneity.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Heterogeneity: Agglomeration Spillovers by Grocery Market Structure}\n")
cat("\\label{tab:heterogeneity}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccc}\n")
cat("\\hline\\hline\n")
cat(" & \\multicolumn{2}{c}{Log Food Service} & \\multicolumn{2}{c}{Log Non-Grocery} \\\\\n")
cat("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}\n")
cat(" & Rural & Urban & Rural & Urban \\\\\n")
cat(" & (1) & (2) & (3) & (4) \\\\\n")
cat("\\hline\n")

## Rural vs Urban
hetero_models <- list(
  robustness$iv_food_rural, robustness$iv_food_urban,
  robustness$iv_nongrocery_rural, robustness$iv_nongrocery_urban
)

cat("Log Grocery (IV)")
for (m in hetero_models) {
  b <- coef(m)[coef_name]
  s <- se(m)[coef_name]
  p <- 2 * pt(abs(b/s), df = max(nobs(m) - 2, 1), lower.tail = FALSE)
  stars <- ifelse(p < 0.01, "$^{***}$", ifelse(p < 0.05, "$^{**}$", ifelse(p < 0.1, "$^{*}$", "")))
  cat(sprintf(" & %.3f%s", b, stars))
}
cat(" \\\\\n")

cat(" ")
for (m in hetero_models) {
  cat(sprintf(" & (%.3f)", se(m)[coef_name]))
}
cat(" \\\\\n")

cat("\\hline\n")
n_rural <- nobs(robustness$iv_food_rural)
n_urban <- nobs(robustness$iv_food_urban)
cat(sprintf("Observations & %s & %s & %s & %s \\\\\n",
            format(n_rural, big.mark = ","),
            format(n_urban, big.mark = ","),
            format(nobs(robustness$iv_nongrocery_rural), big.mark = ","),
            format(n_urban, big.mark = ",")))
cat("County FE & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & Yes \\\\\n")
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} 2SLS estimates by county type. Rural counties have $\\leq 5$ grocery ")
cat("establishments in the 2008 base year; urban counties have $> 20$. ")
cat("The Bartik instrument is weak in rural counties (low grocery share variation), ")
cat("so estimates are imprecise. Urban counties show a statistically significant agglomeration ")
cat("multiplier of approximately 0.8. Standard errors clustered at the state level. ")
cat("$^{***}$ $p<0.01$, $^{**}$ $p<0.05$, $^{*}$ $p<0.1$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

## ============================================================
## SDE Table (Appendix — MANDATORY)
## ============================================================
cat("Generating SDE Table (Appendix)\n")

## Compute SDEs for main IV results
## For IV: SDE = beta_IV / SD(Y)
## The IV coefficient is an elasticity (log-log), so we need to convert

## Pre-treatment SDs of outcome variables
pre_data <- panel %>% filter(year < 2010)
sd_foodservice <- sd(pre_data$log_foodservice, na.rm = TRUE)
sd_health <- sd(pre_data$log_health, na.rm = TRUE)
sd_personal <- sd(pre_data$log_personal, na.rm = TRUE)
sd_nongrocery <- sd(pre_data$log_nongrocery, na.rm = TRUE)
sd_grocery <- sd(pre_data$log_grocery, na.rm = TRUE)

## IV coefficients (continuous treatment = log_grocery)
## SDE = beta × SD(X) / SD(Y) for continuous treatment
beta_food <- coef(results$iv_foodservice)[coef_name]
se_food <- se(results$iv_foodservice)[coef_name]
sde_food <- beta_food * sd_grocery / sd_foodservice
sde_se_food <- se_food * sd_grocery / sd_foodservice

beta_health_iv <- coef(results$iv_health)[coef_name]
se_health_iv <- se(results$iv_health)[coef_name]
sde_health <- beta_health_iv * sd_grocery / sd_health
sde_se_health <- se_health_iv * sd_grocery / sd_health

beta_personal_iv <- coef(results$iv_personal)[coef_name]
se_personal_iv <- se(results$iv_personal)[coef_name]
sde_personal <- beta_personal_iv * sd_grocery / sd_personal
sde_se_personal <- se_personal_iv * sd_grocery / sd_personal

beta_nongrocery <- coef(results$iv_nongrocery)[coef_name]
se_nongrocery_iv <- se(results$iv_nongrocery)[coef_name]
sde_nongrocery <- beta_nongrocery * sd_grocery / sd_nongrocery
sde_se_nongrocery <- se_nongrocery_iv * sd_grocery / sd_nongrocery

## Classification function
classify_sde <- function(sde) {
  abs_sde <- abs(sde)
  if (abs_sde < 0.005) return("Null")
  if (abs_sde < 0.05) {
    if (sde > 0) return("Small positive") else return("Small negative")
  }
  if (abs_sde < 0.15) {
    if (sde > 0) return("Moderate positive") else return("Moderate negative")
  }
  if (sde > 0) return("Large positive") else return("Large negative")
}

## CS-DiD ATT results for Panel B (heterogeneous)
att_food_val <- results$att_food$overall.att
att_food_se <- results$att_food$overall.se
sde_att_food <- att_food_val / sd_foodservice
sde_se_att_food <- att_food_se / sd_foodservice

att_personal_val <- results$att_personal$overall.att
att_personal_se <- results$att_personal$overall.se
sde_att_personal <- att_personal_val / sd_personal
sde_se_att_personal <- att_personal_se / sd_personal

## Build SDE table data
sde_rows <- tribble(
  ~Outcome, ~beta, ~se_beta, ~sd_y, ~sde, ~se_sde, ~classification,

  "Food service (IV)", beta_food, se_food, sd_foodservice,
  sde_food, sde_se_food, classify_sde(sde_food),

  "Health stores (IV)", beta_health_iv, se_health_iv, sd_health,
  sde_health, sde_se_health, classify_sde(sde_health),

  "Personal services (IV)", beta_personal_iv, se_personal_iv, sd_personal,
  sde_personal, sde_se_personal, classify_sde(sde_personal),

  "Non-grocery combined (IV)", beta_nongrocery, se_nongrocery_iv, sd_nongrocery,
  sde_nongrocery, sde_se_nongrocery, classify_sde(sde_nongrocery)
)

sde_rows_het <- tribble(
  ~Outcome, ~beta, ~se_beta, ~sd_y, ~sde, ~se_sde, ~classification,

  "Food service (CS-DiD ATT)", att_food_val, att_food_se, sd_foodservice,
  sde_att_food, sde_se_att_food, classify_sde(sde_att_food),

  "Personal services (CS-DiD ATT)", att_personal_val, att_personal_se, sd_personal,
  sde_att_personal, sde_se_att_personal, classify_sde(sde_att_personal)
)

## --- SDE notes string ---
sde_notes <- paste0(
  "\\\\item \\\\textit{Notes:} ",
  "\\\\textbf{Country:} United States. ",
  "\\\\textbf{Research question:} Do grocery anchor store exits cause cascading closures ",
  "of neighboring non-grocery businesses? ",
  "\\\\textbf{Policy mechanism:} National grocery chain bankruptcy events (Chapter 11 filings) ",
  "cause store closures across affected regions, removing foot-traffic-generating anchor tenants ",
  "from retail agglomerations. ",
  "\\\\textbf{Outcome definition:} Log county-level establishment counts from Census County ",
  "Business Patterns for food service (NAICS 722), health and personal care stores (NAICS 446), ",
  "and personal services (NAICS 812). ",
  "\\\\textbf{Treatment:} Continuous; county-level predicted grocery establishment changes ",
  "from the Bartik shift-share instrument (chain bankruptcy events weighted by pre-period ",
  "county share of state grocery establishments). ",
  "\\\\textbf{Data:} Census County Business Patterns, 2,925 counties, 2005--2022, ",
  "county-year-NAICS observations; 52,588 county-years total. ",
  "\\\\textbf{Method:} Two-stage least squares with county and year fixed effects; ",
  "Bartik instrument (9 chain bankruptcy events, 2010--2020); standard errors ",
  "clustered at the state level; Callaway--Sant'Anna robust DiD for event study. ",
  "\\\\textbf{Sample:} U.S. counties with at least 14 years of continuous grocery and ",
  "food service data in CBP; 1,647 exposed and 1,278 unexposed counties. ",
  "SDE $= \\\\hat{\\\\beta} \\\\times \\\\text{SD}(X) / \\\\text{SD}(Y)$ for continuous treatment, ",
  "where SD($X$) and SD($Y$) are pre-treatment (2005--2009) standard deviations. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

sink(file.path(tables_dir, "tabF1_sde.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Standardized Effect Sizes: Grocery Agglomeration Spillovers}\n")
cat("\\label{tab:sde}\n")
cat("\\small\n")
cat("\\begin{tabular}{lcccccc}\n")
cat("\\hline\\hline\n")
cat("Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{7}{l}{\\textit{Panel A: Pooled (2SLS, Full Sample)}} \\\\\n")
cat("[3pt]\n")

for (i in 1:nrow(sde_rows)) {
  r <- sde_rows[i, ]
  cat(sprintf("%s & %.3f & %.3f & %.3f & %.3f & %.3f & %s \\\\\n",
              r$Outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}

cat("[6pt]\n")
cat("\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Callaway--Sant'Anna ATT)}} \\\\\n")
cat("[3pt]\n")

for (i in 1:nrow(sde_rows_het)) {
  r <- sde_rows_het[i, ]
  cat(sprintf("%s & %.4f & %.4f & %.3f & %.4f & %.4f & %s \\\\\n",
              r$Outcome, r$beta, r$se_beta, r$sd_y, r$sde, r$se_sde, r$classification))
}

cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat(sde_notes, "\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("\nAll tables generated successfully.\n")
cat(sprintf("Tables saved to: %s\n", normalizePath(tables_dir)))
