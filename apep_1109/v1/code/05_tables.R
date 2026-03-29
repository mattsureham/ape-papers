## 05_tables.R — Generate all LaTeX tables including SDE appendix
## apep_1109: Crop Insurance and Deaths of Despair

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")
table_dir <- file.path(dirname(getwd()), "tables")
dir.create(table_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "models.RData"))
load(file.path(data_dir, "robustness_models.RData"))

ag2 <- panel[ag_county == 1 & !is.na(pdsi_growing)]
ag2[, indem_pc := indemnity / pop]

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

cat("=== Table 1: Summary Statistics ===\n")

# Agricultural counties
sum_ag <- ag[, .(
  Variable = c("Drug overdose death rate (per 100K)",
               "Crop insurance indemnity per capita ($)",
               "Crop insurance premium per capita ($)",
               "Growing-season PDSI",
               "Drought indicator (PDSI < -2)",
               "County population",
               "Rural county share"),
  Mean = c(mean(od_rate, na.rm=T), mean(indemnity/pop, na.rm=T),
           mean(premium/pop, na.rm=T), mean(pdsi_growing, na.rm=T),
           mean(drought, na.rm=T), mean(pop, na.rm=T),
           mean(rural, na.rm=T)),
  SD = c(sd(od_rate, na.rm=T), sd(indemnity/pop, na.rm=T),
         sd(premium/pop, na.rm=T), sd(pdsi_growing, na.rm=T),
         sd(drought, na.rm=T), sd(pop, na.rm=T),
         sd(rural, na.rm=T)),
  Min = c(min(od_rate, na.rm=T), min(indemnity/pop, na.rm=T),
          min(premium/pop, na.rm=T), min(pdsi_growing, na.rm=T),
          0, min(pop, na.rm=T), 0),
  Max = c(max(od_rate, na.rm=T), max(indemnity/pop, na.rm=T),
          max(premium/pop, na.rm=T), max(pdsi_growing, na.rm=T),
          1, max(pop, na.rm=T), 1)
)]

# Format numbers
fmt <- function(x, d = 1) formatC(x, format = "f", digits = d, big.mark = ",")

tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics: Agricultural Counties, 2003--2021}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrrrr}",
  "\\hline\\hline",
  " & Mean & SD & Min & Max & N \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{6}{l}{\\textit{Panel A: Outcomes and Treatment}} \\\\[0.3ex]",
  sprintf("Drug overdose death rate (per 100K) & %s & %s & %s & %s & %s \\\\",
          fmt(sum_ag$Mean[1]), fmt(sum_ag$SD[1]), fmt(sum_ag$Min[1]),
          fmt(sum_ag$Max[1]), fmt(nrow(ag), 0)),
  sprintf("Crop insurance indemnity per capita (\\$) & %s & %s & %s & %s & %s \\\\",
          fmt(sum_ag$Mean[2], 0), fmt(sum_ag$SD[2], 0), fmt(sum_ag$Min[2], 0),
          fmt(sum_ag$Max[2], 0), fmt(nrow(ag), 0)),
  sprintf("Crop insurance premium per capita (\\$) & %s & %s & %s & %s & %s \\\\",
          fmt(sum_ag$Mean[3], 0), fmt(sum_ag$SD[3], 0), fmt(sum_ag$Min[3], 0),
          fmt(sum_ag$Max[3], 0), fmt(nrow(ag), 0)),
  "\\\\[-1.8ex]",
  "\\multicolumn{6}{l}{\\textit{Panel B: Instrument and Controls}} \\\\[0.3ex]",
  sprintf("Growing-season PDSI & %s & %s & %s & %s & %s \\\\",
          fmt(sum_ag$Mean[4], 2), fmt(sum_ag$SD[4], 2), fmt(sum_ag$Min[4], 2),
          fmt(sum_ag$Max[4], 2), fmt(nrow(ag), 0)),
  sprintf("Drought indicator (PDSI $< -2$) & %s & %s & 0 & 1 & %s \\\\",
          fmt(sum_ag$Mean[5], 3), fmt(sum_ag$SD[5], 3), fmt(nrow(ag), 0)),
  sprintf("County population & %s & %s & %s & %s & %s \\\\",
          fmt(sum_ag$Mean[6], 0), fmt(sum_ag$SD[6], 0), fmt(sum_ag$Min[6], 0),
          fmt(sum_ag$Max[6], 0), fmt(nrow(ag), 0)),
  sprintf("Rural county share & %s & %s & 0 & 1 & %s \\\\",
          fmt(sum_ag$Mean[7], 3), fmt(sum_ag$SD[7], 3), fmt(nrow(ag), 0)),
  "\\hline\\hline",
  "\\multicolumn{6}{p{0.95\\textwidth}}{\\footnotesize \\textit{Notes:}",
  "Unit of observation is county-year. Agricultural counties defined as those",
  "appearing in USDA RMA crop insurance records for at least 10 of 19 years.",
  "Drug overdose death rates from NCHS model-based estimates (CDC dataset rpvx-m2md),",
  "which use a Bayesian hierarchical model to provide stable estimates even for small",
  "rural counties. PDSI is the Palmer Drought Severity Index averaged over the",
  "April--September growing season from NOAA climate divisions mapped to counties.",
  "Values below $-2$ indicate severe drought. $N = $ \\Sexpr{nrow(ag)} county-years",
  sprintf("across %s counties.}", fmt(n_distinct(ag$fips5), 0)),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab1_lines, file.path(table_dir, "tab1_summary.tex"))
cat("  Saved tab1_summary.tex\n")

# ============================================================
# TABLE 2: Main Results (OLS, First Stage, IV)
# ============================================================

cat("\n=== Table 2: Main IV Results ===\n")

# Extract key statistics
get_stats <- function(mod, var) {
  cf <- coef(mod)[var]
  s <- se(mod)[var]
  t <- cf / s
  p <- 2 * pt(abs(t), df = Inf, lower.tail = FALSE)
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.1, "^{*}", "")))
  list(coef = cf, se = s, stars = stars, n = nobs(mod))
}

ols_s <- get_stats(ols1, "indem_pc_w")
ols2_s <- get_stats(ols2, "indem_pc_w")
fs_s <- get_stats(fs1, "pdsi_growing")
rf_s <- get_stats(rf1, "pdsi_growing")
iv_s <- get_stats(iv1, "fit_indem_pc_w")
iv2_s <- get_stats(iv2, "fit_indem_pc_w")

fs_f_val <- summary(fs1)$coeftable["pdsi_growing", "t value"]^2

tab2_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{The Effect of Crop Insurance Indemnity on Drug Overdose Deaths}",
  "\\label{tab:main}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{3}{l}{\\textit{Panel A: OLS}} \\\\[0.3ex]",
  sprintf("Indemnity per capita & %s%s & %s%s \\\\",
          fmt(ols_s$coef, 4), ols_s$stars, fmt(ols2_s$coef, 4), ols2_s$stars),
  sprintf(" & (%s) & (%s) \\\\",
          fmt(ols_s$se, 4), fmt(ols2_s$se, 4)),
  "\\\\[-1.8ex]",
  "\\multicolumn{3}{l}{\\textit{Panel B: First Stage (Dep. Var.: Indemnity per capita)}} \\\\[0.3ex]",
  sprintf("Growing-season PDSI & %s%s & %s%s \\\\",
          fmt(fs_s$coef, 2), fs_s$stars,
          fmt(get_stats(fs2, "pdsi_growing")$coef, 2),
          get_stats(fs2, "pdsi_growing")$stars),
  sprintf(" & (%s) & (%s) \\\\",
          fmt(fs_s$se, 2), fmt(get_stats(fs2, "pdsi_growing")$se, 2)),
  sprintf("Clustered $F$-statistic & %s & \\\\", fmt(fs_f_val, 1)),
  "\\\\[-1.8ex]",
  "\\multicolumn{3}{l}{\\textit{Panel C: Reduced Form (Dep. Var.: OD Rate)}} \\\\[0.3ex]",
  sprintf("Growing-season PDSI & %s & \\\\",
          fmt(rf_s$coef, 4)),
  sprintf(" & (%s) & \\\\", fmt(rf_s$se, 4)),
  "\\\\[-1.8ex]",
  "\\multicolumn{3}{l}{\\textit{Panel D: IV/2SLS}} \\\\[0.3ex]",
  sprintf("Indemnity per capita & %s & %s \\\\",
          fmt(iv_s$coef, 4), fmt(iv2_s$coef, 4)),
  sprintf(" & (%s) & (%s) \\\\",
          fmt(iv_s$se, 4), fmt(iv2_s$se, 4)),
  "\\\\[-1.8ex]",
  "\\hline",
  "County FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  "Population control & No & Yes \\\\",
  sprintf("Observations & %s & %s \\\\", fmt(ols_s$n, 0), fmt(ols2_s$n, 0)),
  sprintf("Counties & %s & %s \\\\",
          fmt(n_distinct(ag$fips5), 0), fmt(n_distinct(ag$fips5), 0)),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:}",
  "Standard errors clustered at the state level in parentheses.",
  "$^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.1$.",
  "The instrument is the growing-season (April--September) Palmer Drought Severity",
  "Index (PDSI) from NOAA climate divisions. More negative PDSI indicates more",
  "severe drought. The first stage confirms that drought drives indemnity payments;",
  "the reduced form shows drought does not significantly affect overdose death rates.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab2_lines, file.path(table_dir, "tab2_main.tex"))
cat("  Saved tab2_main.tex\n")

# ============================================================
# TABLE 3: Triple Difference (Insurance Buffer)
# ============================================================

cat("\n=== Table 3: Insurance Buffer Triple-Difference ===\n")

td_s <- get_stats(td1, "drought")
tdhi_s <- get_stats(td1, "drought_x_highins")

tab3_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Insurance Buffer: Drought, Insurance Penetration, and Overdose Deaths}",
  "\\label{tab:triplediff}",
  "\\begin{tabular}{lcc}",
  "\\hline\\hline",
  " & (1) & (2) \\\\",
  " & OD Rate & OD Rate \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  sprintf("Drought (PDSI $< -2$) & %s & %s \\\\",
          fmt(coef(td1)["drought"], 3), fmt(coef(td2)["drought"], 3)),
  sprintf(" & (%s) & (%s) \\\\",
          fmt(se(td1)["drought"], 3), fmt(se(td2)["drought"], 3)),
  sprintf("Drought $\\times$ High Insurance & %s & %s \\\\",
          fmt(coef(td1)["drought_x_highins"], 3),
          fmt(coef(td2)["drought:high_insurance"], 3)),
  sprintf(" & (%s) & (%s) \\\\",
          fmt(se(td1)["drought_x_highins"], 3),
          fmt(se(td2)["drought:high_insurance"], 3)),
  "\\\\[-1.8ex]",
  "\\hline",
  "County FE & Yes & Yes \\\\",
  "Year FE & Yes & Yes \\\\",
  "Population control & No & Yes \\\\",
  sprintf("Observations & %s & %s \\\\",
          fmt(nobs(td1), 0), fmt(nobs(td2), 0)),
  "\\hline\\hline",
  "\\multicolumn{3}{p{0.85\\textwidth}}{\\footnotesize \\textit{Notes:}",
  "Standard errors clustered at the state level in parentheses.",
  "High Insurance defined as counties in the top two quintiles of pre-period",
  "(2003--2007) average crop insurance premium per capita. Drought defined as",
  "growing-season PDSI below $-2$. The ``despair insurance'' hypothesis predicts",
  "a \\textit{negative} interaction: high-insurance counties should be buffered",
  "from drought-induced overdose increases. The positive but insignificant",
  "interaction contradicts this hypothesis.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab3_lines, file.path(table_dir, "tab3_triplediff.tex"))
cat("  Saved tab3_triplediff.tex\n")

# ============================================================
# TABLE 4: Robustness and Placebo Tests
# ============================================================

cat("\n=== Table 4: Robustness ===\n")

tab4_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Robustness and Placebo Tests}",
  "\\label{tab:robustness}",
  "\\begin{tabular}{lccc}",
  "\\hline\\hline",
  " & Coefficient & SE & $N$ \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{4}{l}{\\textit{Panel A: IV/2SLS Sensitivity}} \\\\[0.3ex]",
  sprintf("Main specification & %s & (%s) & %s \\\\",
          fmt(coef(iv1)["fit_indem_pc_w"], 4),
          fmt(se(iv1)["fit_indem_pc_w"], 4),
          fmt(nobs(iv1), 0)),
  sprintf("Exclude COVID (2003--2019) & %s & (%s) & %s \\\\",
          fmt(coef(iv_nocovid)["fit_indem_pc_w"], 4),
          fmt(se(iv_nocovid)["fit_indem_pc_w"], 4),
          fmt(nobs(iv_nocovid), 0)),
  sprintf("Rural counties only & %s & (%s) & %s \\\\",
          fmt(coef(iv_rural_only)["fit_indem_pc_w"], 4),
          fmt(se(iv_rural_only)["fit_indem_pc_w"], 4),
          fmt(nobs(iv_rural_only), 0)),
  sprintf("Pre-opioid (2003--2010) & %s & (%s) & %s \\\\",
          fmt(coef(iv_early)["fit_indem_pc_w"], 4),
          fmt(se(iv_early)["fit_indem_pc_w"], 4),
          fmt(nobs(iv_early), 0)),
  sprintf("Opioid era (2011--2021) & %s & (%s) & %s \\\\",
          fmt(coef(iv_late)["fit_indem_pc_w"], 4),
          fmt(se(iv_late)["fit_indem_pc_w"], 4),
          fmt(nobs(iv_late), 0)),
  "\\\\[-1.8ex]",
  "\\multicolumn{4}{l}{\\textit{Panel B: Reduced-Form Placebos}} \\\\[0.3ex]",
  sprintf("Non-agricultural counties & %s & (%s) & %s \\\\",
          fmt(coef(rf_nonag)["pdsi_growing"], 4),
          fmt(se(rf_nonag)["pdsi_growing"], 4),
          fmt(nobs(rf_nonag), 0)),
  sprintf("Severe drought binary (PDSI $< -3$) & %s & (%s) & %s \\\\",
          fmt(coef(rf_binary)["severe_drought"], 3),
          fmt(se(rf_binary)["severe_drought"], 3),
          fmt(nobs(rf_binary), 0)),
  "\\hline\\hline",
  "\\multicolumn{4}{p{0.90\\textwidth}}{\\footnotesize \\textit{Notes:}",
  "Panel A reports IV/2SLS coefficients of indemnity per capita on overdose death",
  "rate, instrumented by growing-season PDSI. All specifications include county and",
  "year fixed effects with standard errors clustered at the state level. Panel B reports",
  "reduced-form coefficients of PDSI on overdose death rate. The non-agricultural",
  "county placebo confirms that PDSI does not affect overdose rates through non-income channels.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tab4_lines, file.path(table_dir, "tab4_robustness.tex"))
cat("  Saved tab4_robustness.tex\n")

# ============================================================
# TABLE F1: Standardized Effect Size (SDE) Appendix
# ============================================================

cat("\n=== Table F1: SDE Appendix ===\n")

# Compute SDEs
sd_od <- sd(ag$od_rate, na.rm = TRUE)
sd_indem <- sd(ag$indem_pc_w, na.rm = TRUE)

# Main IV estimate (continuous treatment -> SDE = beta * SD(X) / SD(Y))
iv_beta <- as.numeric(coef(iv1)["fit_indem_pc_w"])
iv_se_val <- as.numeric(se(iv1)["fit_indem_pc_w"])
sde_iv <- iv_beta * sd_indem / sd_od
sde_iv_se <- iv_se_val * sd_indem / sd_od

# Reduced form (continuous -> SDE = beta * SD(PDSI) / SD(Y))
sd_pdsi <- sd(ag$pdsi_growing, na.rm = TRUE)
rf_beta <- as.numeric(coef(rf1)["pdsi_growing"])
rf_se_val <- as.numeric(se(rf1)["pdsi_growing"])
sde_rf <- rf_beta * sd_pdsi / sd_od
sde_rf_se <- rf_se_val * sd_pdsi / sd_od

# Triple-diff (drought is binary)
td_drought_beta <- as.numeric(coef(td1)["drought"])
td_drought_se <- as.numeric(se(td1)["drought"])
sde_td <- td_drought_beta / sd_od
sde_td_se <- td_drought_se / sd_od

# Insurance buffer interaction (binary)
td_int_beta <- as.numeric(coef(td1)["drought_x_highins"])
td_int_se <- as.numeric(se(td1)["drought_x_highins"])
sde_int <- td_int_beta / sd_od
sde_int_se <- td_int_se / sd_od

classify_sde <- function(s) {
  if (s < -0.15) return("Large negative")
  if (s < -0.05) return("Moderate negative")
  if (s < -0.005) return("Small negative")
  if (s <= 0.005) return("Null")
  if (s <= 0.05) return("Small positive")
  if (s <= 0.15) return("Moderate positive")
  return("Large positive")
}

# Format rows
sde_rows <- data.frame(
  Outcome = c(
    "OD rate (IV: indemnity/cap)",
    "OD rate (RF: PDSI)",
    "OD rate (drought indicator)",
    "OD rate (drought $\\times$ high ins.)"
  ),
  beta = c(iv_beta, rf_beta, td_drought_beta, td_int_beta),
  se = c(iv_se_val, rf_se_val, td_drought_se, td_int_se),
  sd_y = rep(sd_od, 4),
  sde = c(sde_iv, sde_rf, sde_td, sde_int),
  sde_se = c(sde_iv_se, sde_rf_se, sde_td_se, sde_int_se),
  class = sapply(c(sde_iv, sde_rf, sde_td, sde_int), classify_sde),
  stringsAsFactors = FALSE
)

# Heterogeneity: Rural vs non-rural
iv_rural_beta <- as.numeric(coef(iv_rural)["fit_indem_pc_w"])
iv_rural_se <- as.numeric(se(iv_rural)["fit_indem_pc_w"])
sd_od_rural <- sd(ag[rural == 1, od_rate], na.rm = TRUE)
sd_indem_rural <- sd(ag[rural == 1, indem_pc_w], na.rm = TRUE)
sde_rural <- iv_rural_beta * sd_indem_rural / sd_od_rural
sde_rural_se <- iv_rural_se * sd_indem_rural / sd_od_rural

iv_nonrural_beta <- as.numeric(coef(iv_nonrural)["fit_indem_pc_w"])
iv_nonrural_se <- as.numeric(se(iv_nonrural)["fit_indem_pc_w"])
sd_od_nonrural <- sd(ag[rural == 0, od_rate], na.rm = TRUE)
sd_indem_nonrural <- sd(ag[rural == 0, indem_pc_w], na.rm = TRUE)
sde_nonrural <- iv_nonrural_beta * sd_indem_nonrural / sd_od_nonrural
sde_nonrural_se <- iv_nonrural_se * sd_indem_nonrural / sd_od_nonrural

# --- SDE notes string ---
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does federal crop insurance reduce drug overdose deaths in agricultural counties by stabilizing farm income after weather shocks? ",
  "\\textbf{Policy mechanism:} USDA Risk Management Agency crop insurance subsidizes approximately 60 percent of premiums for weather-indexed revenue protection, paying indemnities when weather-driven crop losses reduce farm revenue below insured thresholds, thereby buffering household income in agricultural communities. ",
  "\\textbf{Outcome definition:} NCHS model-based drug overdose death rate per 100,000 population, using Bayesian hierarchical estimates that provide stable county-level rates even for small rural populations. ",
  "\\textbf{Treatment:} Continuous; crop insurance indemnity payments per capita in dollars, driven by exogenous weather shocks. ",
  "\\textbf{Data:} CDC NCHS model-based estimates (dataset rpvx-m2md), USDA RMA Summary of Business, and NOAA PDSI; county-year panel 2003--2021; 2,685 agricultural counties; 51,024 observations. ",
  "\\textbf{Method:} IV/2SLS with growing-season PDSI as instrument for indemnity per capita; county and year fixed effects; standard errors clustered at the state level. ",
  "\\textbf{Sample:} Agricultural counties defined as appearing in RMA records for at least 10 of 19 years; restricted to continental US counties with non-missing PDSI. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ for continuous treatment, ",
  "SDE $= \\hat{\\beta} / \\text{SD}(Y)$ for binary treatment, ",
  "where SD($Y$) is the full-sample standard deviation of the outcome. ",
  "Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Standardized Effect Sizes}",
  "\\label{tab:sde}",
  "\\begin{tabular}{lcccccc}",
  "\\hline\\hline",
  "Outcome & $\\hat{\\beta}$ & SE & SD($Y$) & SDE & SE(SDE) & Classification \\\\",
  "\\hline",
  "\\\\[-1.8ex]",
  "\\multicolumn{7}{l}{\\textit{Panel A: Pooled}} \\\\[0.3ex]"
)

for (i in 1:nrow(sde_rows)) {
  tabF1_lines <- c(tabF1_lines, sprintf(
    "%s & %s & %s & %s & %s & %s & %s \\\\",
    sde_rows$Outcome[i],
    fmt(sde_rows$beta[i], 4), fmt(sde_rows$se[i], 4),
    fmt(sde_rows$sd_y[i], 2), fmt(sde_rows$sde[i], 4),
    fmt(sde_rows$sde_se[i], 4), sde_rows$class[i]
  ))
}

tabF1_lines <- c(tabF1_lines,
  "\\\\[-1.8ex]",
  "\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneous (Rural vs.\\ Non-Rural)}} \\\\[0.3ex]",
  sprintf("OD rate, rural counties & %s & %s & %s & %s & %s & %s \\\\",
          fmt(iv_rural_beta, 4), fmt(iv_rural_se, 4),
          fmt(sd_od_rural, 2), fmt(sde_rural, 4),
          fmt(sde_rural_se, 4), classify_sde(sde_rural)),
  sprintf("OD rate, non-rural ag.\\ counties & %s & %s & %s & %s & %s & %s \\\\",
          fmt(iv_nonrural_beta, 4), fmt(iv_nonrural_se, 4),
          fmt(sd_od_nonrural, 2), fmt(sde_nonrural, 4),
          fmt(sde_nonrural_se, 4), classify_sde(sde_nonrural)),
  "\\hline\\hline",
  sprintf("\\multicolumn{7}{p{0.95\\textwidth}}{\\footnotesize \\begin{itemize}[leftmargin=*] %s \\end{itemize}}", sde_notes),
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tabF1_lines, file.path(table_dir, "tabF1_sde.tex"))
cat("  Saved tabF1_sde.tex\n")

cat("\n=== All tables generated ===\n")
cat(sprintf("Tables: %s\n", paste(list.files(table_dir), collapse = ", ")))
