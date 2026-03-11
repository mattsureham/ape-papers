# ==============================================================================
# 06_tables.R — Generate all LaTeX tables
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

# Load data and models
mir_panel <- fread(file.path(data_dir, "mir_panel.csv"))
hpi_panel <- fread(file.path(data_dir, "hpi_panel.csv"))
transposition <- fread(file.path(data_dir, "mcd_transposition.csv"))
transposition[, transposition_date := as.Date(transposition_date)]
load(file.path(data_dir, "main_models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

overall_rate <- fread(file.path(data_dir, "overall_rate.csv"))
overall_hpi <- fread(file.path(data_dir, "overall_hpi.csv"))

# Recreate quarterly panel for summary stats
mir_panel[, yr := year(as.Date(date))]
mir_panel[, qtr := quarter(as.Date(date))]
mir_panel[, yq_idx := (yr - 2005) * 4 + qtr]

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================
cat("Table 1: Summary statistics\n")

# Mortgage rates
rate_stats <- mir_panel[!is.na(rate), .(
  Variable = "Mortgage rate (%)",
  N = .N,
  Mean = round(mean(rate), 2),
  SD = round(sd(rate), 2),
  Min = round(min(rate), 2),
  Max = round(max(rate), 2),
  Countries = uniqueN(country)
)]

# Consumer credit rate
cons_stats <- mir_panel[!is.na(consumer_rate), .(
  Variable = "Consumer credit rate (%)",
  N = .N,
  Mean = round(mean(consumer_rate), 2),
  SD = round(sd(consumer_rate), 2),
  Min = round(min(consumer_rate), 2),
  Max = round(max(consumer_rate), 2),
  Countries = uniqueN(country)
)]

# HPI
hpi_stats <- hpi_panel[!is.na(log_hpi), .(
  Variable = "Log house price index",
  N = .N,
  Mean = round(mean(log_hpi), 2),
  SD = round(sd(log_hpi), 2),
  Min = round(min(log_hpi), 2),
  Max = round(max(log_hpi), 2),
  Countries = uniqueN(country)
)]

sumstats <- rbindlist(list(rate_stats, cons_stats, hpi_stats))

tab1 <- kable(sumstats, format = "latex", booktabs = TRUE,
              caption = "Summary Statistics",
              label = "sumstats",
              align = c("l", rep("c", 6))) |>
  kable_styling(latex_options = "hold_position")

writeLines(tab1, file.path(tab_dir, "tab1_sumstats.tex"))

# ==============================================================================
# Table 2: Main Results — CS-DiD and TWFE
# ==============================================================================
cat("Table 2: Main results\n")

# Build results table manually
main_results <- data.table(
  Outcome = c("Mortgage rate (pp)", "Log house price index"),
  `SA-IW ATT` = c(
    paste0(round(overall_rate$att, 3), " (", round(overall_rate$se, 3), ")"),
    paste0(round(overall_hpi$att, 3), " (", round(overall_hpi$se, 3), ")")
  ),
  `TWFE` = c(
    paste0(round(coef(twfe_rate)["treated"], 3), " (",
           round(sqrt(diag(vcov(twfe_rate)))["treated"], 3), ")"),
    paste0(round(coef(twfe_hpi)["treated"], 3), " (",
           round(sqrt(diag(vcov(twfe_hpi)))["treated"], 3), ")")
  )
)

tab2 <- kable(main_results, format = "latex", booktabs = TRUE,
              caption = "Main Results: Effect of MCD Transposition",
              label = "main_results",
              align = c("l", "c", "c"),
              escape = FALSE) |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "Standard errors clustered at country level in parentheses. SA-IW uses Sun and Abraham (2021) interaction-weighted estimator. TWFE includes country and time fixed effects.",
           general_title = "Notes:", footnote_as_chunk = TRUE)

writeLines(tab2, file.path(tab_dir, "tab2_main.tex"))

# ==============================================================================
# Table 3: Transposition Dates
# ==============================================================================
cat("Table 3: Transposition dates\n")

trans_tab <- transposition[!is.na(transposition_date)][order(transposition_date)]
trans_tab[, `On Time` := fifelse(transposition_date <= as.Date("2016-03-21"), "Yes", "No")]
trans_tab[, `Date` := as.character(transposition_date)]
trans_tab[, Country := iso2]

tab3 <- kable(trans_tab[, .(Country, Date, `On Time`)],
              format = "latex", booktabs = TRUE,
              caption = "MCD Transposition Dates by Member State",
              label = "transposition",
              align = c("l", "c", "c")) |>
  kable_styling(latex_options = c("hold_position"))

writeLines(tab3, file.path(tab_dir, "tab3_transposition.tex"))

# ==============================================================================
# Table 4: Robustness — Multiple Specifications
# ==============================================================================
cat("Table 4: Robustness\n")

# Collect robustness results
ri_data <- fread(file.path(data_dir, "ri_rate.csv"))
placebo_data <- fread(file.path(data_dir, "temporal_placebo.csv"))
wcb_file <- file.path(data_dir, "wcb_rate.csv")

robust_rows <- list(
  data.table(
    Check = "Baseline CS-DiD",
    Estimate = round(overall_rate$att, 3),
    SE = round(overall_rate$se, 3),
    `p-value` = ""
  ),
  data.table(
    Check = "TWFE",
    Estimate = round(coef(twfe_rate)["treated"], 3),
    SE = round(sqrt(diag(vcov(twfe_rate)))["treated"], 3),
    `p-value` = ""
  ),
  data.table(
    Check = "Sun-Abraham IW",
    Estimate = {
      sa <- fread(file.path(data_dir, "sunab_rate_coefs.csv"))
      post <- sa[rel_time >= 0 & rel_time <= 36]
      round(mean(post$att, na.rm = TRUE), 3)
    },
    SE = "",
    `p-value` = ""
  ),
  data.table(
    Check = "Randomization inference",
    Estimate = round(ri_data$actual[1], 3),
    SE = "",
    `p-value` = as.character(round(ri_data$ri_p[1], 3))
  ),
  data.table(
    Check = "Temporal placebo (2yr prior)",
    Estimate = round(placebo_data$estimate, 3),
    SE = round(placebo_data$se, 3),
    `p-value` = ""
  )
)

if (file.exists(wcb_file)) {
  wcb <- fread(wcb_file)
  robust_rows <- c(robust_rows, list(data.table(
    Check = "Wild cluster bootstrap",
    Estimate = "",
    SE = "",
    `p-value` = as.character(round(wcb$wcb_p, 3))
  )))
}

robust_dt <- rbindlist(robust_rows, fill = TRUE)

tab4 <- kable(robust_dt, format = "latex", booktabs = TRUE,
              caption = "Robustness Checks: Mortgage Rate",
              label = "robustness",
              align = c("l", "c", "c", "c")) |>
  kable_styling(latex_options = "hold_position")

writeLines(tab4, file.path(tab_dir, "tab4_robustness.tex"))

# ==============================================================================
# Table 5: Heterogeneity
# ==============================================================================
cat("Table 5: Heterogeneity\n")

het_reg_data <- fread(file.path(data_dir, "het_regulation.csv"))
het_boom_data <- fread(file.path(data_dir, "het_boom.csv"))

het_table <- data.table(
  Dimension = c(
    "Pre-existing regulation: Treated",
    "Pre-existing regulation: Treated x Stringent",
    "Housing boom: Treated",
    "Housing boom: Treated x Boom"
  ),
  Estimate = c(
    round(het_reg_data[term == "treated", estimate], 3),
    round(het_reg_data[term == "treated:stringent_pre", estimate], 3),
    round(het_boom_data[term == "treated", estimate], 3),
    round(het_boom_data[term == "treated:boom", estimate], 3)
  ),
  SE = c(
    round(het_reg_data[term == "treated", se], 3),
    round(het_reg_data[term == "treated:stringent_pre", se], 3),
    round(het_boom_data[term == "treated", se], 3),
    round(het_boom_data[term == "treated:boom", se], 3)
  )
)

tab5 <- kable(het_table, format = "latex", booktabs = TRUE,
              caption = "Heterogeneity Analysis: Mortgage Rates",
              label = "heterogeneity",
              align = c("l", "c", "c")) |>
  kable_styling(latex_options = "hold_position") |>
  footnote(general = "All specifications include country and time fixed effects. Standard errors clustered at country level.",
           general_title = "Notes:", footnote_as_chunk = TRUE)

writeLines(tab5, file.path(tab_dir, "tab5_heterogeneity.tex"))

# ==============================================================================
# Table F1: Standardized Effect Sizes (Appendix F)
# ==============================================================================
cat("Table F1: Standardized effect sizes\n")

# Extract beta and SE from model objects
beta_rate <- coef(twfe_rate)["treated"]
se_rate <- sqrt(diag(vcov(twfe_rate)))["treated"]
sd_y_rate <- mir_panel[!is.na(rate), sd(rate)]

beta_hpi <- coef(twfe_hpi)["treated"]
se_hpi <- sqrt(diag(vcov(twfe_hpi)))["treated"]
sd_y_hpi <- hpi_panel[!is.na(log_hpi), sd(log_hpi)]

classify_sde <- function(sde) {
  if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
}

sde_table <- data.table(
  Outcome = c("Mortgage rate", "Log house price index"),
  Specification = c("Table 2, TWFE", "Table 2, TWFE"),
  Beta = round(c(beta_rate, beta_hpi), 4),
  `SD(Y)` = round(c(sd_y_rate, sd_y_hpi), 4),
  SDE = round(c(beta_rate / sd_y_rate, beta_hpi / sd_y_hpi), 4),
  `SE(SDE)` = round(c(se_rate / sd_y_rate, se_hpi / sd_y_hpi), 4),
  Classification = c(
    classify_sde(beta_rate / sd_y_rate),
    classify_sde(beta_hpi / sd_y_hpi)
  )
)

sde_notes <- paste0(
  "This table reports standardized effect sizes for the main outcomes. ",
  "The research question is whether the EU Mortgage Credit Directive (2014/17/EU), ",
  "which imposed mandatory creditworthiness assessments on mortgage lenders, ",
  "affected mortgage lending conditions and house prices across EU member states. ",
  "Data: ECB MIR (monthly mortgage rates and volumes, ", uniqueN(mir_panel$country),
  " euro area countries, 2010--2021) and Eurostat prc\\_hpi\\_q (quarterly house price index, ",
  uniqueN(hpi_panel$country), " EU countries, 2005--2021). ",
  "Unit of observation: country-month (rates/volumes) or country-quarter (HPI). ",
  "N = ", nrow(mir_panel[!is.na(rate)]), " (rates), ",
  nrow(hpi_panel[!is.na(log_hpi)]), " (HPI). ",
  "Estimation: TWFE with country and time fixed effects, standard errors clustered at country level. ",
  "Treatment is binary (0/1 transposition indicator). ",
  "SDE = $\\hat{\\beta}$ / SD(Y). SE(SDE) = SE($\\hat{\\beta}$) / SD(Y). ",
  "Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance."
)

tabF1 <- kable(sde_table, format = "latex", booktabs = TRUE,
               caption = "Standardized Effect Sizes",
               label = "sde",
               align = c("l", "l", rep("c", 5)),
               escape = FALSE) |>
  kable_styling(latex_options = c("hold_position", "scale_down")) |>
  footnote(general = sde_notes, general_title = "Notes:", footnote_as_chunk = TRUE,
           escape = FALSE)

writeLines(tabF1, file.path(tab_dir, "tabF1_sde.tex"))

cat("\nAll tables generated.\n")
