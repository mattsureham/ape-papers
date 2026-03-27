# ==============================================================================
# 03_main_analysis.R — Primary regressions
# apep_1058: The Networked Bank Run
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

analysis <- readRDS(file.path(data_dir, "analysis.rds"))

cat(sprintf("Analysis dataset: %d counties, %d states\n",
            nrow(analysis), n_distinct(analysis$state_fips)))

# ==============================================================================
# 1. Main specification: Deposit change on NetworkExposure
# ==============================================================================
cat("\n=== Main specifications ===\n")

# Model 1: Bivariate
m1 <- feols(dlog_dep_2223 ~ network_exposure_std,
            data = analysis, cluster = ~state_fips)

# Model 2: + geographic controls
m2 <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc + same_state_ca,
            data = analysis, cluster = ~state_fips)

# Model 3: + county controls
m3 <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc + same_state_ca +
              log_pop + log_income + tech_share,
            data = analysis, cluster = ~state_fips)

# Model 4: + pre-trend control
m4 <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc + same_state_ca +
              log_pop + log_income + tech_share + pre_trend,
            data = analysis, cluster = ~state_fips)

# Model 5: State FE (preferred)
m5 <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
              log_pop + log_income + tech_share + pre_trend | state_fips,
            data = analysis, cluster = ~state_fips)

cat("\n--- Model summaries ---\n")
etable(m1, m2, m3, m4, m5,
       se.below = TRUE,
       keep = "%network_exposure_std",
       dict = c(network_exposure_std = "Network Exposure (std)"))

# ==============================================================================
# 2. Generate Table 1: Main results
# ==============================================================================
cat("\n=== Generating Table 1: Main Results ===\n")

tab1_tex <- etable(m1, m2, m3, m4, m5,
                   se.below = TRUE,
                   dict = c(
                     network_exposure_std = "Network Exposure (std.)",
                     log_dist_to_sc = "Log Distance to SV",
                     same_state_ca = "California",
                     log_pop = "Log Population",
                     log_income = "Log Income",
                     tech_share = "Tech Emp. Share",
                     pre_trend = "Pre-Crisis Trend"
                   ),
                   fitstat = ~ n + r2,
                   style.tex = style.tex("aer"),
                   tex = TRUE,
                   title = "Social Connectedness and Deposit Flight During the 2023 Banking Panic",
                   label = "tab:main",
                   notes = paste0(
                     "Dependent variable: log change in county deposits (June 2022 to June 2023). ",
                     "Network Exposure is the SCI-weighted SVB deposit share, standardized to mean zero and unit variance. ",
                     "All models cluster standard errors at the state level. ",
                     "Column (5) includes state fixed effects."
                   ))

writeLines(tab1_tex, file.path(tables_dir, "tab1_main.tex"))

# ==============================================================================
# 3. Pre-trend / Placebo tests
# ==============================================================================
cat("\n=== Pre-trend placebo regressions ===\n")

# Same specification (Model 5) applied to pre-period deposit changes
p0a <- feols(dlog_dep_1718 ~ network_exposure_std + log_dist_to_sc +
               log_pop + log_income + tech_share | state_fips,
             data = analysis, cluster = ~state_fips)

p0b <- feols(dlog_dep_1819 ~ network_exposure_std + log_dist_to_sc +
               log_pop + log_income + tech_share | state_fips,
             data = analysis, cluster = ~state_fips)

p1 <- feols(dlog_dep_1920 ~ network_exposure_std + log_dist_to_sc +
              log_pop + log_income + tech_share | state_fips,
            data = analysis, cluster = ~state_fips)

p2 <- feols(dlog_dep_2021 ~ network_exposure_std + log_dist_to_sc +
              log_pop + log_income + tech_share | state_fips,
            data = analysis, cluster = ~state_fips)

p3 <- feols(dlog_dep_2122 ~ network_exposure_std + log_dist_to_sc +
              log_pop + log_income + tech_share | state_fips,
            data = analysis, cluster = ~state_fips)

cat("\nPlacebo results (Network Exposure coefficient):\n")
cat(sprintf("  2017-2018: %.5f (SE: %.5f)\n", coef(p0a)["network_exposure_std"], se(p0a)["network_exposure_std"]))
cat(sprintf("  2018-2019: %.5f (SE: %.5f)\n", coef(p0b)["network_exposure_std"], se(p0b)["network_exposure_std"]))
cat(sprintf("  2019-2020: %.5f (SE: %.5f)\n", coef(p1)["network_exposure_std"], se(p1)["network_exposure_std"]))
cat(sprintf("  2020-2021: %.5f (SE: %.5f)\n", coef(p2)["network_exposure_std"], se(p2)["network_exposure_std"]))
cat(sprintf("  2021-2022: %.5f (SE: %.5f)\n", coef(p3)["network_exposure_std"], se(p3)["network_exposure_std"]))
cat(sprintf("  2022-2023: %.5f (SE: %.5f) [MAIN]\n", coef(m5)["network_exposure_std"], se(m5)["network_exposure_std"]))

# Table 2: Pre-trend placebos (show 3 representative + main for space)
tab2_tex <- etable(p0a, p1, p3, m5,
                   se.below = TRUE,
                   keep = "%network_exposure_std",
                   dict = c(network_exposure_std = "Network Exposure (std.)"),
                   headers = c("2017--2018", "2019--2020",
                               "2021--2022", "2022--2023"),
                   fitstat = ~ n + r2,
                   style.tex = style.tex("aer"),
                   tex = TRUE,
                   title = "Pre-Trend Placebo Tests: Network Exposure and Deposit Changes",
                   label = "tab:placebo",
                   notes = paste0(
                     "Each column regresses the log change in county deposits for the indicated year pair ",
                     "on Network Exposure (standardized), with the same controls as column (5) of Table 1. ",
                     "State fixed effects and state-clustered SEs in all columns. ",
                     "Columns (1)--(3) are placebo tests; column (4) is the main estimate."
                   ))

writeLines(tab2_tex, file.path(tables_dir, "tab2_placebo.tex"))

# ==============================================================================
# 4. Heterogeneity: by bank vulnerability
# ==============================================================================
cat("\n=== Heterogeneity analysis ===\n")

# Split by median pre-crisis deposit level (proxy for bank size/vulnerability)
analysis <- analysis %>%
  mutate(
    high_deposits = as.integer(deposits_2022 > median(deposits_2022, na.rm=TRUE)),
    high_tech = as.integer(tech_share > median(tech_share[tech_share > 0], na.rm=TRUE))
  )

# Interact network exposure with high_deposits
h1 <- feols(dlog_dep_2223 ~ network_exposure_std * high_deposits + log_dist_to_sc +
              log_pop + log_income + tech_share + pre_trend | state_fips,
            data = analysis, cluster = ~state_fips)

# Interact with tech share
h2 <- feols(dlog_dep_2223 ~ network_exposure_std * high_tech + log_dist_to_sc +
              log_pop + log_income + pre_trend | state_fips,
            data = analysis, cluster = ~state_fips)

# Sample split: high vs low deposit counties
h3_high <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                   log_pop + log_income + tech_share + pre_trend | state_fips,
                 data = filter(analysis, high_deposits == 1), cluster = ~state_fips)

h3_low <- feols(dlog_dep_2223 ~ network_exposure_std + log_dist_to_sc +
                  log_pop + log_income + tech_share + pre_trend | state_fips,
                data = filter(analysis, high_deposits == 0), cluster = ~state_fips)

cat("\nHeterogeneity results:\n")
cat(sprintf("  High deposit counties: %.5f (SE: %.5f), N=%d\n",
            coef(h3_high)["network_exposure_std"], se(h3_high)["network_exposure_std"], nobs(h3_high)))
cat(sprintf("  Low deposit counties:  %.5f (SE: %.5f), N=%d\n",
            coef(h3_low)["network_exposure_std"], se(h3_low)["network_exposure_std"], nobs(h3_low)))

# Table 3: Heterogeneity
tab3_tex <- etable(m5, h1, h2, h3_high, h3_low,
                   se.below = TRUE,
                   keep = c("%network_exposure_std", "%network_exposure_std:high_deposits",
                            "%network_exposure_std:high_tech"),
                   dict = c(
                     network_exposure_std = "Network Exposure (std.)",
                     "network_exposure_std:high_deposits" = "Net. Exp. $\\times$ High Deposits",
                     "network_exposure_std:high_tech" = "Net. Exp. $\\times$ High Tech"
                   ),
                   headers = c("Baseline", "Interact.: Dep.", "Interact.: Tech",
                               "High Dep.", "Low Dep."),
                   fitstat = ~ n + r2,
                   style.tex = style.tex("aer"),
                   tex = TRUE,
                   title = "Heterogeneity: Network Exposure by County Characteristics",
                   label = "tab:hetero",
                   notes = paste0(
                     "Column (1) reproduces the baseline. Columns (2)--(3) interact Network Exposure ",
                     "with indicators for above-median county deposits and above-median tech employment share. ",
                     "Columns (4)--(5) split the sample at median 2022 deposits. ",
                     "All specifications include state FE and state-clustered SEs."
                   ))

writeLines(tab3_tex, file.path(tables_dir, "tab3_hetero.tex"))

# ==============================================================================
# 5. Save diagnostics.json
# ==============================================================================
cat("\n=== Writing diagnostics ===\n")

# The "treatment" here is continuous, but we report analogous counts
# n_treated = counties above median exposure (as a measure of effective treatment)
n_above_median <- sum(analysis$network_exposure_std > 0)
# n_pre = number of pre-period years (2017-2018, 2018-2019, 2019-2020, 2020-2021, 2021-2022)
n_pre <- 5

diagnostics <- list(
  n_treated = n_above_median,
  n_pre = n_pre,
  n_obs = nrow(analysis),
  n_states = n_distinct(analysis$state_fips),
  main_coef = unname(coef(m5)["network_exposure_std"]),
  main_se = unname(se(m5)["network_exposure_std"]),
  main_pval = unname(pvalue(m5)["network_exposure_std"]),
  outcome_sd = sd(analysis$dlog_dep_2223),
  outcome_mean = mean(analysis$dlog_dep_2223),
  exposure_sd = sd(analysis$network_exposure),
  exposure_mean = mean(analysis$network_exposure)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("Main coefficient: %.5f (SE: %.5f, p=%.4f)\n",
            diagnostics$main_coef, diagnostics$main_se, diagnostics$main_pval))
cat(sprintf("Outcome SD: %.4f\n", diagnostics$outcome_sd))

# Save main regression objects for SDE table
saveRDS(list(m5 = m5, analysis = analysis, diagnostics = diagnostics),
        file.path(data_dir, "main_results.rds"))

cat("\n=== Main analysis complete ===\n")
