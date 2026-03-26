## 05_tables.R — Generate all LaTeX tables
## APEP paper apep_1001: Poland Sunday Trading Ban and Traffic Accidents

source("00_packages.R")

cat("=== Generating Tables ===\n")

# Load data and models
daily <- fread("../data/daily_voivodeship.csv")
daily[, date := as.Date(date)]
sundays <- daily[is_sunday == TRUE]

main_models <- readRDS("../data/main_models.rds")
het_models <- readRDS("../data/heterogeneity_models.rds")
ddd_model <- readRDS("../data/ddd_model.rds")
hourly_results <- readRDS("../data/hourly_results.rds")
robustness <- readRDS("../data/robustness_models.rds")

# Helper: format number with significance stars
fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("--- Table 1: Summary Statistics ---\n")

trading <- sundays[is_trading_sunday == TRUE]
non_trading <- sundays[non_trading == TRUE]

vars <- c("accidents", "pedestrian", "vehicle_collision", "intoxicated")
labels <- c("Total accidents", "Pedestrian accidents", "Vehicle collisions", "Alcohol-involved")

tab1_rows <- character()
for (i in seq_along(vars)) {
  v <- vars[i]
  t_mean <- mean(trading[[v]], na.rm = TRUE)
  t_sd <- sd(trading[[v]], na.rm = TRUE)
  nt_mean <- mean(non_trading[[v]], na.rm = TRUE)
  nt_sd <- sd(non_trading[[v]], na.rm = TRUE)
  diff <- nt_mean - t_mean
  # t-test for difference
  tt <- t.test(non_trading[[v]], trading[[v]])
  p <- tt$p.value
  tab1_rows <- c(tab1_rows, sprintf(
    "  %s & %.2f & (%.2f) & %.2f & (%.2f) & %.2f%s \\\\",
    labels[i], t_mean, t_sd, nt_mean, nt_sd, diff, stars(p)
  ))
}

n_trading_days <- uniqueN(trading$date)
n_nontrad_days <- uniqueN(non_trading$date)

tab1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Summary Statistics: Trading vs.~Non-Trading Sundays}\n",
  "\\label{tab:summary}\n",
  "\\begin{tabular}{lccccc}\n",
  "\\hline\\hline\n",
  " & \\multicolumn{2}{c}{Trading} & \\multicolumn{2}{c}{Non-Trading} & \\\\\n",
  " & Mean & (SD) & Mean & (SD) & Difference \\\\\n",
  "\\hline\n",
  paste(tab1_rows, collapse = "\n"), "\n",
  "\\hline\n",
  sprintf("  Voivodeship-days & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\\\\n",
          nrow(trading), nrow(non_trading)),
  sprintf("  Unique Sundays & \\multicolumn{2}{c}{%d} & \\multicolumn{2}{c}{%d} & \\\\\n",
          n_trading_days, n_nontrad_days),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Unit of observation is voivodeship $\\times$ Sunday. ",
  "Trading Sundays are legislatively designated days when retail shops may open ",
  "under Poland's Act of 10 January 2018 (Phase 3, 2020--2023: $\\sim$7 per year). ",
  "Non-trading Sundays ($\\sim$45 per year) are subject to the ban. ",
  "Difference = Non-Trading $-$ Trading. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$ from two-sample $t$-tests.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab1, "../tables/tab1_summary.tex")

# ============================================================
# TABLE 2: Main Poisson Results
# ============================================================
cat("--- Table 2: Main Poisson Results ---\n")

models <- list(main_models$m1, main_models$m2, main_models$m3, main_models$m4)
col_labels <- c("(1)", "(2)", "(3)", "(4)")

# Extract coefficients
coefs <- sapply(models, function(m) coef(m)["non_tradingTRUE"])
ses <- sapply(models, function(m) se(m)["non_tradingTRUE"])
pvals <- sapply(models, function(m) pvalue(m)["non_tradingTRUE"])
irrs <- exp(coefs)
nobs <- sapply(models, function(m) m$nobs)

tab2_coef_row <- paste0("  Non-trading Sunday",
                        paste0(sprintf(" & %s%s", fmt(coefs, 4), sapply(pvals, stars)), collapse = ""),
                        " \\\\")
tab2_se_row <- paste0("  ",
                      paste0(sprintf(" & (%s)", fmt(ses, 4)), collapse = ""),
                      " \\\\")
tab2_irr_row <- paste0("  \\emph{Incidence rate ratio}",
                       paste0(sprintf(" & [%s]", fmt(irrs, 3)), collapse = ""),
                       " \\\\")
tab2_n_row <- paste0("  Observations",
                     paste0(sprintf(" & %s", formatC(nobs, format = "d", big.mark = ",")), collapse = ""),
                     " \\\\")

tab2 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Effect of Sunday Trading Ban on Road Accidents}\n",
  "\\label{tab:main}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & (1) & (2) & (3) & (4) \\\\\n",
  "\\hline\n",
  tab2_coef_row, "\n",
  tab2_se_row, "\n",
  tab2_irr_row, "\n",
  "\\hline\n",
  "  Voivodeship FE & Yes & Yes & Yes & Yes \\\\\n",
  "  Month FE & & Yes & Yes & Yes \\\\\n",
  "  Year FE & & & Yes & Yes \\\\\n",
  "  Weather controls & & & & Yes \\\\\n",
  tab2_n_row, "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Poisson pseudo-maximum likelihood estimates. ",
  "Dependent variable is the daily count of road traffic accidents at the voivodeship level. ",
  "Non-trading Sunday is an indicator for Sundays when retail trading is prohibited. ",
  "Standard errors clustered at the voivodeship level in parentheses. ",
  "Incidence rate ratios in brackets. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab2, "../tables/tab2_main.tex")

# ============================================================
# TABLE 3: Heterogeneity by Accident Type
# ============================================================
cat("--- Table 3: Heterogeneity ---\n")

het_list <- list(het_models$m_ped, het_models$m_veh, het_models$m_intox)
het_labels <- c("Pedestrian", "Vehicle collision", "Alcohol-involved")

het_coefs <- sapply(het_list, function(m) coef(m)["non_tradingTRUE"])
het_ses <- sapply(het_list, function(m) se(m)["non_tradingTRUE"])
het_pvals <- sapply(het_list, function(m) pvalue(m)["non_tradingTRUE"])
het_irrs <- exp(het_coefs)
het_nobs <- sapply(het_list, function(m) m$nobs)

tab3_rows <- character()
for (i in seq_along(het_labels)) {
  tab3_rows <- c(tab3_rows,
    sprintf("  %s & %s%s & (%s) & [%s] & %s \\\\",
            het_labels[i], fmt(het_coefs[i], 4), stars(het_pvals[i]),
            fmt(het_ses[i], 4), fmt(het_irrs[i], 3),
            formatC(het_nobs[i], format = "d", big.mark = ",")))
}

tab3 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Heterogeneous Effects by Accident Type}\n",
  "\\label{tab:heterogeneity}\n",
  "\\begin{tabular}{lcccc}\n",
  "\\hline\\hline\n",
  " & Coefficient & (SE) & [IRR] & Obs. \\\\\n",
  "\\hline\n",
  paste(tab3_rows, collapse = "\n"), "\n",
  "\\hline\n",
  "  Voivodeship FE & \\multicolumn{4}{c}{Yes} \\\\\n",
  "  Month + Year FE & \\multicolumn{4}{c}{Yes} \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Each row is a separate Poisson regression with the indicated ",
  "accident-type count as dependent variable. All specifications include voivodeship, month, ",
  "and year fixed effects. Standard errors clustered at the voivodeship level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab3, "../tables/tab3_heterogeneity.tex")

# ============================================================
# TABLE 4: Hourly Displacement (DDD)
# ============================================================
cat("--- Table 4: Hourly DDD ---\n")

ddd_vars <- c("non_trading_num", "shop_hours_num", "non_trading_num:shop_hours_num")
ddd_labels <- c("Non-trading Sunday", "Shopping hours (10--17)", "Non-trading $\\times$ Shopping hours")
ddd_coefs <- coef(ddd_model)[ddd_vars]
ddd_ses <- se(ddd_model)[ddd_vars]
ddd_pvals <- pvalue(ddd_model)[ddd_vars]

# Also show hour-bin results
tab4_main_rows <- character()
for (i in seq_along(ddd_vars)) {
  tab4_main_rows <- c(tab4_main_rows,
    sprintf("  %s & %s%s \\\\", ddd_labels[i],
            fmt(ddd_coefs[i], 4), stars(ddd_pvals[i])),
    sprintf("   & (%s) \\\\", fmt(ddd_ses[i], 4)))
}

tab4 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Within-Day Displacement: Trading Ban and Shopping Hours}\n",
  "\\label{tab:ddd}\n",
  "\\begin{tabular}{lc}\n",
  "\\hline\\hline\n",
  " & Accidents \\\\\n",
  "\\hline\n",
  "\\emph{Panel A: Triple-difference} & \\\\\n",
  paste(tab4_main_rows, collapse = "\n"), "\n",
  "\\hline\n",
  "\\emph{Panel B: By time of day} & IRR \\\\\n",
  paste(sapply(1:nrow(hourly_results), function(i) {
    hr <- hourly_results[i]
    sprintf("  %s & %s%s \\\\", gsub("_", " ", hr$hour_bin),
            fmt(hr$irr, 3),
            stars(2 * pnorm(-abs(hr$coef / hr$se))))
  }), collapse = "\n"), "\n",
  "\\hline\n",
  sprintf("  Observations & %s \\\\\n",
          formatC(ddd_model$nobs, format = "d", big.mark = ",")),
  "  Voivodeship FE & Yes \\\\\n",
  "  Hour + Month + Year FE & Yes \\\\\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} Panel A reports Poisson estimates from a triple-difference ",
  "specification: Non-trading Sunday $\\times$ Shopping hours (10:00--17:59) with ",
  "voivodeship, hour, month, and year fixed effects. Panel B reports incidence rate ratios ",
  "from separate regressions by time-of-day bin. ",
  "Standard errors clustered at the voivodeship level. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab4, "../tables/tab4_ddd.tex")

# ============================================================
# TABLE 5: Robustness
# ============================================================
cat("--- Table 5: Robustness ---\n")

# Preferred specification for reference
pref_coef <- coef(main_models$m3)["non_tradingTRUE"]
pref_se <- se(main_models$m3)["non_tradingTRUE"]
pref_p <- pvalue(main_models$m3)["non_tradingTRUE"]
pref_irr <- exp(pref_coef)

# Saturday placebo
sat_coef <- coef(robustness$sat_placebo)["non_trading_sat"]
sat_se <- se(robustness$sat_placebo)["non_trading_sat"]
sat_p <- pvalue(robustness$sat_placebo)["non_trading_sat"]
sat_irr <- exp(sat_coef)

# Exclude holidays
hol_coef <- coef(robustness$noholiday)["non_trading_num"]
hol_se <- se(robustness$noholiday)["non_trading_num"]
hol_p <- pvalue(robustness$noholiday)["non_trading_num"]
hol_irr <- exp(hol_coef)

# Friday placebo
fri_coef <- coef(robustness$fri_placebo)["non_trading_fri"]
fri_se <- se(robustness$fri_placebo)["non_trading_fri"]
fri_p <- pvalue(robustness$fri_placebo)["non_trading_fri"]
fri_irr <- exp(fri_coef)

# NB
nb_coef <- if (!is.null(robustness$nb)) coef(robustness$nb)["non_trading_num"] else NA
nb_se <- if (!is.null(robustness$nb)) summary(robustness$nb)$coefficients["non_trading_num", "Std. Error"] else NA
nb_p <- if (!is.null(robustness$nb)) summary(robustness$nb)$coefficients["non_trading_num", "Pr(>|z|)"] else NA
nb_irr <- if (!is.na(nb_coef)) exp(nb_coef) else NA

# LOO range
loo_min <- min(robustness$loo$irr)
loo_max <- max(robustness$loo$irr)

# WCB
wcb_p <- if (!is.null(robustness$wcb)) robustness$wcb$p_value else NA

robust_rows <- c(
  sprintf("  Preferred (Poisson, voiv+month+year FE) & %s%s & (%s) & [%s] \\\\",
          fmt(pref_coef, 4), stars(pref_p), fmt(pref_se, 4), fmt(pref_irr, 3)),
  sprintf("  Saturday placebo & %s%s & (%s) & [%s] \\\\",
          fmt(sat_coef, 4), stars(sat_p), fmt(sat_se, 4), fmt(sat_irr, 3)),
  sprintf("  Friday placebo & %s%s & (%s) & [%s] \\\\",
          fmt(fri_coef, 4), stars(fri_p), fmt(fri_se, 4), fmt(fri_irr, 3)),
  sprintf("  Exclude holiday windows & %s%s & (%s) & [%s] \\\\",
          fmt(hol_coef, 4), stars(hol_p), fmt(hol_se, 4), fmt(hol_irr, 3))
)
if (!is.na(nb_coef)) {
  robust_rows <- c(robust_rows,
    sprintf("  Negative binomial & %s%s & (%s) & [%s] \\\\",
            fmt(nb_coef, 4), stars(nb_p), fmt(nb_se, 4), fmt(nb_irr, 3)))
}

tab5 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Robustness Checks}\n",
  "\\label{tab:robustness}\n",
  "\\begin{tabular}{lccc}\n",
  "\\hline\\hline\n",
  " & Coefficient & (SE) & [IRR] \\\\\n",
  "\\hline\n",
  paste(robust_rows, collapse = "\n"), "\n",
  "\\hline\n",
  sprintf("  Leave-one-voivodeship-out IRR range & \\multicolumn{3}{c}{[%s, %s]} \\\\\n",
          fmt(loo_min, 3), fmt(loo_max, 3)),
  ifelse(!is.na(wcb_p),
         sprintf("  Wild cluster bootstrap $p$-value & \\multicolumn{3}{c}{%s} \\\\\n", fmt(wcb_p, 4)),
         ""),
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\small\n",
  "\\item \\textit{Notes:} All specifications include voivodeship, month, and year fixed effects ",
  "unless noted. Saturday and Friday placebos assign pseudo-treatment status based on the adjacent ",
  "Sunday's trading status. Holiday windows exclude two weeks around Christmas and Easter. ",
  "Wild cluster bootstrap uses Webb weights with 9,999 replications. ",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tab5, "../tables/tab5_robustness.tex")

# ============================================================
# SDE TABLE (Appendix F1)
# ============================================================
cat("--- SDE Table ---\n")

# Get SD(Y) from trading Sundays (pre-treatment baseline)
sd_y_total <- sd(trading$accidents)
sd_y_ped <- sd(trading$pedestrian)

# Main estimate
beta_main <- coef(main_models$m3)["non_tradingTRUE"]
se_main <- se(main_models$m3)["non_tradingTRUE"]

# For Poisson: marginal effect ≈ β × mean(Y)
# SDE = marginal_effect / SD(Y) ≈ β × mean(Y) / SD(Y)
mean_y <- mean(sundays$accidents)
marginal_effect <- beta_main * mean_y
sde_total <- marginal_effect / sd_y_total
se_sde_total <- (se_main * mean_y) / sd_y_total

# Pedestrian
beta_ped <- coef(het_models$m_ped)["non_tradingTRUE"]
se_ped <- se(het_models$m_ped)["non_tradingTRUE"]
mean_y_ped <- mean(sundays$pedestrian)
marginal_ped <- beta_ped * mean_y_ped
sde_ped <- marginal_ped / sd_y_ped
se_sde_ped <- (se_ped * mean_y_ped) / sd_y_ped

# Vehicle collision
sd_y_veh <- sd(trading$vehicle_collision)
beta_veh <- coef(het_models$m_veh)["non_tradingTRUE"]
se_veh <- se(het_models$m_veh)["non_tradingTRUE"]
mean_y_veh <- mean(sundays$vehicle_collision)
marginal_veh <- beta_veh * mean_y_veh
sde_veh <- marginal_veh / sd_y_veh
se_sde_veh <- (se_veh * mean_y_veh) / sd_y_veh

# Classify SDE
classify_sde <- function(sde) {
  if (sde < -0.15) "Large negative"
  else if (sde < -0.05) "Moderate negative"
  else if (sde < -0.005) "Small negative"
  else if (sde <= 0.005) "Null"
  else if (sde <= 0.05) "Small positive"
  else if (sde <= 0.15) "Moderate positive"
  else "Large positive"
}

# Add factor variables for subsample regressions
sundays[, voivodeship_f := as.factor(voivodeship)]
sundays[, month_f := as.factor(month)]
sundays[, year_f := as.factor(year)]
sundays[, non_trading_num := as.numeric(non_trading)]
sundays[, accidents := as.numeric(accidents)]

# Heterogeneity: urban voivodeships (top 5 by density)
# Using population density proxy: voivodeships with highest accident counts
voiv_counts <- sundays[, .(total = sum(accidents)), by = voivodeship]
urban_voivs <- voiv_counts[order(-total)][1:5]$voivodeship
rural_voivs <- voiv_counts[order(-total)][6:16]$voivodeship

sun_urban <- sundays[voivodeship %in% urban_voivs]
sun_rural <- sundays[voivodeship %in% rural_voivs]

# Urban model
m_urban <- fepois(accidents ~ non_trading_num | voivodeship_f + month_f + year_f,
                  data = sun_urban, vcov = ~voivodeship_f)
beta_urban <- coef(m_urban)["non_trading_num"]
se_urban <- se(m_urban)["non_trading_num"]
sd_y_urban <- sd(sun_urban[is_trading_sunday == TRUE]$accidents)
mean_y_urban <- mean(sun_urban$accidents)
sde_urban <- (beta_urban * mean_y_urban) / sd_y_urban
se_sde_urban <- (se_urban * mean_y_urban) / sd_y_urban

# Rural model
m_rural <- fepois(accidents ~ non_trading_num | voivodeship_f + month_f + year_f,
                  data = sun_rural, vcov = ~voivodeship_f)
beta_rural <- coef(m_rural)["non_trading_num"]
se_rural <- se(m_rural)["non_trading_num"]
sd_y_rural <- sd(sun_rural[is_trading_sunday == TRUE]$accidents)
mean_y_rural <- mean(sun_rural$accidents)
sde_rural <- (beta_rural * mean_y_rural) / sd_y_rural
se_sde_rural <- (se_rural * mean_y_rural) / sd_y_rural

sde_rows <- list(
  list("Total accidents", beta_main, se_main, sd_y_total, sde_total, se_sde_total),
  list("Pedestrian accidents", beta_ped, se_ped, sd_y_ped, sde_ped, se_sde_ped),
  list("Vehicle collisions", beta_veh, se_veh, sd_y_veh, sde_veh, se_sde_veh)
)

sde_het_rows <- list(
  list("Urban voivodeships", beta_urban, se_urban, sd_y_urban, sde_urban, se_sde_urban),
  list("Rural voivodeships", beta_rural, se_rural, sd_y_rural, sde_rural, se_sde_rural)
)

make_sde_row <- function(r) {
  sprintf("  %s & %s & %s & %s & %s & %s & %s \\\\",
          r[[1]], fmt(r[[2]], 4), fmt(r[[3]], 4), fmt(r[[4]], 2),
          fmt(r[[5]], 4), fmt(r[[6]], 4), classify_sde(r[[5]]))
}

sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} Poland. ",
  "\\textbf{Research question:} Does prohibiting Sunday retail trading increase road traffic accidents by displacing consumer activity toward more travel-intensive leisure? ",
  "\\textbf{Policy mechanism:} The Act of 10 January 2018 (Phase 3) prohibits retail trading on approximately 45 of 52 Sundays per year, with 7 legislatively designated exempt Sundays; the ban forces a reallocation of Sunday time from enclosed shopping environments to outdoor and travel-based activities. ",
  "\\textbf{Outcome definition:} Daily count of police-recorded road traffic accidents (SEWIK database) per voivodeship, including all severity levels. ",
  "\\textbf{Treatment:} Binary indicator for non-trading (ban-affected) Sundays versus trading (exempt) Sundays. ",
  "\\textbf{Data:} SEWIK police accident records from Zenodo, 2020--2023, aggregated to voivodeship-Sunday level ($N \\approx 3{,}300$ voivodeship-days from 16 voivodeships $\\times$ 209 Sundays). ",
  "\\textbf{Method:} Poisson pseudo-maximum likelihood with voivodeship, month, and year fixed effects; standard errors clustered at the voivodeship level (16 clusters), supplemented by wild cluster bootstrap. ",
  "\\textbf{Sample:} All Sundays in the Phase 3 period (2020--2023); trading Sundays serve as the within-year counterfactual for non-trading Sundays in the same voivodeship and month. ",
  "SDE $= \\hat{\\beta} \\times \\bar{Y} / \\text{SD}(Y)$ where $\\bar{Y}$ is the sample mean and SD($Y$) is the ",
  "standard deviation of the dependent variable among trading (exempt) Sundays. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
  "\\begin{table}[htbp]\n",
  "\\centering\n",
  "\\caption{Standardized Effect Sizes}\n",
  "\\label{tab:sde}\n",
  "\\begin{adjustbox}{max width=\\textwidth}\n",
  "\\begin{tabular}{lcccccc}\n",
  "\\hline\\hline\n",
  " & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\\n",
  "\\hline\n",
  "\\emph{Panel A: Pooled} & & & & & & \\\\\n",
  paste(sapply(sde_rows, make_sde_row), collapse = "\n"), "\n",
  "\\hline\n",
  "\\emph{Panel B: Heterogeneous (Urban/Rural)} & & & & & & \\\\\n",
  paste(sapply(sde_het_rows, make_sde_row), collapse = "\n"), "\n",
  "\\hline\\hline\n",
  "\\end{tabular}\n",
  "\\end{adjustbox}\n",
  "\\begin{tablenotes}[flushleft]\n",
  "\\footnotesize\n",
  sde_notes, "\n",
  "\\end{tablenotes}\n",
  "\\end{table}\n"
)
writeLines(tabF1, "../tables/tabF1_sde.tex")

cat("\n=== All tables generated ===\n")
cat("Tables written to ../tables/:\n")
cat(paste(list.files("../tables/", pattern = "\\.tex$"), collapse = "\n"))
cat("\n")
