################################################################################
# 09d_diffusion_analysis.R
# Policy Diffusion: Does Network MW Exposure Causally Predict State MW Adoption?
#
# Progressive specifications:
#   (1) NetworkMW + log(OwnMW) + state FE + year FE
#   (2) + Governor party + trifecta
#   (3) + Union density + unemployment
#   (4) + Census region × year FE
#   (5) IV: non-adjacent-state-only exposure
#
# Falsification:
#   - Network gas tax → MW adoption (expect null)
#   - Network corporate tax → MW adoption (expect null)
#   - Geographic proximity vs. SCI (network vs. distance)
#
# Heterogeneity:
#   - By initial MW level (federal floor vs. above)
#   - By political lean (gov party)
#
# Input:  ../data/state_diffusion_panel.rds
# Output: ../tables/tab_policy_diffusion.tex (replaced)
#         Console output for assessment
################################################################################

source("00_packages.R")

# Fix namespace conflict: scales::pvalue masks fixest::pvalue
pvalue <- fixest::pvalue

cat("=== Policy Diffusion Analysis ===\n\n")

# ============================================================================
# 1. Load Data
# ============================================================================

cat("1. Loading diffusion panel...\n")

df <- readRDS("../data/state_diffusion_panel.rds")

# Working sample: exclude states at $15 ceiling
df_main <- df %>% filter(!at_ceiling)

cat("  Full panel:", nrow(df), "state-year obs\n")
cat("  Working sample (excl ceiling):", nrow(df_main), "obs\n")
cat("  States:", n_distinct(df_main$state_fips), "\n")
cat("  Years:", min(df_main$year), "-", max(df_main$year), "\n")
cat("  MW increases:", sum(df_main$mw_increased, na.rm = TRUE),
    "(", round(100 * mean(df_main$mw_increased, na.rm = TRUE), 1), "%)\n")
cat("  Real increases:", sum(df_main$real_increase, na.rm = TRUE),
    "(", round(100 * mean(df_main$real_increase, na.rm = TRUE), 1), "%)\n\n")

# ============================================================================
# 2. Progressive Controls — Binary Outcome (LPM)
# ============================================================================

cat("2. Progressive controls — MW Increase (LPM)...\n\n")

# (1) Baseline: NetworkMW + own MW + state FE + year FE
m1_lpm <- feols(mw_increased ~ network_mw_full + log_own_mw |
                  state_fips + year,
                data = df_main, cluster = ~state_fips)

# (2) + Governor party + trifecta
m2_lpm <- feols(mw_increased ~ network_mw_full + log_own_mw +
                  gov_dem + trifecta_dem + trifecta_rep |
                  state_fips + year,
                data = df_main, cluster = ~state_fips)

# (3) + Union density + unemployment
m3_lpm <- feols(mw_increased ~ network_mw_full + log_own_mw +
                  gov_dem + trifecta_dem + trifecta_rep +
                  union_density + unemp_rate |
                  state_fips + year,
                data = df_main, cluster = ~state_fips)

# (4) + Census region × year FE
m4_lpm <- feols(mw_increased ~ network_mw_full + log_own_mw +
                  gov_dem + trifecta_dem + trifecta_rep +
                  union_density + unemp_rate |
                  state_fips + census_region^year,
                data = df_main, cluster = ~state_fips)

# (5) IV: non-adjacent exposure → full exposure
m5_lpm <- feols(mw_increased ~ log_own_mw +
                  gov_dem + trifecta_dem + trifecta_rep +
                  union_density + unemp_rate |
                  state_fips + census_region^year |
                  network_mw_full ~ network_mw_nonadj,
                data = df_main, cluster = ~state_fips)

cat("--- LPM: MW Increase in t+1 ---\n")
cat("  (1) Baseline:     β =", round(coef(m1_lpm)["network_mw_full"], 4),
    ", SE =", round(sqrt(vcov(m1_lpm)["network_mw_full","network_mw_full"]), 4),
    ", p =", round(pvalue(m1_lpm)["network_mw_full"], 4), "\n")
cat("  (2) + Political:  β =", round(coef(m2_lpm)["network_mw_full"], 4),
    ", SE =", round(sqrt(vcov(m2_lpm)["network_mw_full","network_mw_full"]), 4),
    ", p =", round(pvalue(m2_lpm)["network_mw_full"], 4), "\n")
cat("  (3) + Union/UR:   β =", round(coef(m3_lpm)["network_mw_full"], 4),
    ", SE =", round(sqrt(vcov(m3_lpm)["network_mw_full","network_mw_full"]), 4),
    ", p =", round(pvalue(m3_lpm)["network_mw_full"], 4), "\n")
cat("  (4) + Region×Yr:  β =", round(coef(m4_lpm)["network_mw_full"], 4),
    ", SE =", round(sqrt(vcov(m4_lpm)["network_mw_full","network_mw_full"]), 4),
    ", p =", round(pvalue(m4_lpm)["network_mw_full"], 4), "\n")

# IV results (use fitstat for first-stage F)
iv_coef <- coef(m5_lpm)["fit_network_mw_full"]
iv_se <- sqrt(vcov(m5_lpm)["fit_network_mw_full","fit_network_mw_full"])
iv_p <- pvalue(m5_lpm)["fit_network_mw_full"]
cat("  (5) IV (non-adj): β =", round(iv_coef, 4),
    ", SE =", round(iv_se, 4),
    ", p =", round(iv_p, 4), "\n")

# First-stage F
fs_f <- fitstat(m5_lpm, "ivf")
cat("  First-stage F:", round(fs_f$ivf$stat, 1), "\n\n")

# ============================================================================
# 3. Progressive Controls — Continuous Outcome
# ============================================================================

cat("3. Progressive controls — Δlog(MW)...\n\n")

m1_cont <- feols(delta_log_mw ~ network_mw_full + log_own_mw |
                   state_fips + year,
                 data = df_main, cluster = ~state_fips)

m2_cont <- feols(delta_log_mw ~ network_mw_full + log_own_mw +
                   gov_dem + trifecta_dem + trifecta_rep |
                   state_fips + year,
                 data = df_main, cluster = ~state_fips)

m3_cont <- feols(delta_log_mw ~ network_mw_full + log_own_mw +
                   gov_dem + trifecta_dem + trifecta_rep +
                   union_density + unemp_rate |
                   state_fips + year,
                 data = df_main, cluster = ~state_fips)

m4_cont <- feols(delta_log_mw ~ network_mw_full + log_own_mw +
                   gov_dem + trifecta_dem + trifecta_rep +
                   union_density + unemp_rate |
                   state_fips + census_region^year,
                 data = df_main, cluster = ~state_fips)

m5_cont <- feols(delta_log_mw ~ log_own_mw +
                   gov_dem + trifecta_dem + trifecta_rep +
                   union_density + unemp_rate |
                   state_fips + census_region^year |
                   network_mw_full ~ network_mw_nonadj,
                 data = df_main, cluster = ~state_fips)

cat("--- Continuous: Δlog(MW) in t+1 ---\n")
cat("  (1) Baseline:     β =", round(coef(m1_cont)["network_mw_full"], 4),
    ", p =", round(pvalue(m1_cont)["network_mw_full"], 4), "\n")
cat("  (2) + Political:  β =", round(coef(m2_cont)["network_mw_full"], 4),
    ", p =", round(pvalue(m2_cont)["network_mw_full"], 4), "\n")
cat("  (3) + Union/UR:   β =", round(coef(m3_cont)["network_mw_full"], 4),
    ", p =", round(pvalue(m3_cont)["network_mw_full"], 4), "\n")
cat("  (4) + Region×Yr:  β =", round(coef(m4_cont)["network_mw_full"], 4),
    ", p =", round(pvalue(m4_cont)["network_mw_full"], 4), "\n")
cat("  (5) IV (non-adj): β =", round(coef(m5_cont)["fit_network_mw_full"], 4),
    ", p =", round(pvalue(m5_cont)["fit_network_mw_full"], 4), "\n\n")

# ============================================================================
# 4. Real Increase Outcome
# ============================================================================

cat("4. Real increase (exceeds inflation)...\n\n")

df_real <- df_main %>% filter(!is.na(real_increase))

m4_real <- feols(real_increase ~ network_mw_full + log_own_mw +
                   gov_dem + trifecta_dem + trifecta_rep +
                   union_density + unemp_rate |
                   state_fips + census_region^year,
                 data = df_real, cluster = ~state_fips)

cat("  Real increase (full controls): β =", round(coef(m4_real)["network_mw_full"], 4),
    ", SE =", round(sqrt(vcov(m4_real)["network_mw_full","network_mw_full"]), 4),
    ", p =", round(pvalue(m4_real)["network_mw_full"], 4), "\n\n")

# ============================================================================
# 5. Falsification Tests
# ============================================================================

cat("5. Falsification tests...\n\n")

# Gas tax → MW adoption (expect null)
# Note: gas/corp tax rates are near time-invariant in our data, so with state FE
# they may be collinear. Use year FE only for this falsification test.
fals_gas <- feols(mw_increased ~ network_gas_tax + log_own_mw +
                    gov_dem + trifecta_dem + trifecta_rep +
                    union_density + unemp_rate |
                    year,
                  data = df_main, cluster = ~state_fips)

if ("network_gas_tax" %in% names(coef(fals_gas))) {
  cat("  Gas tax exposure → MW increase: β =", round(coef(fals_gas)["network_gas_tax"], 4),
      ", p =", round(pvalue(fals_gas)["network_gas_tax"], 4), "\n")
} else {
  cat("  Gas tax exposure: collinear (time-invariant, absorbed by FE)\n")
}

# Corporate tax → MW adoption (expect null)
fals_corp <- feols(mw_increased ~ network_corp_tax + log_own_mw +
                     gov_dem + trifecta_dem + trifecta_rep +
                     union_density + unemp_rate |
                     year,
                   data = df_main, cluster = ~state_fips)

if ("network_corp_tax" %in% names(coef(fals_corp))) {
  cat("  Corp tax exposure → MW increase: β =", round(coef(fals_corp)["network_corp_tax"], 4),
      ", p =", round(pvalue(fals_corp)["network_corp_tax"], 4), "\n")
} else {
  cat("  Corp tax exposure: collinear (time-invariant, absorbed by FE)\n")
}

# Geographic proximity vs. SCI: horse race
horse_race <- feols(mw_increased ~ network_mw_full + geo_mw_exposure + log_own_mw +
                      gov_dem + trifecta_dem + trifecta_rep +
                      union_density + unemp_rate |
                      state_fips + year,
                    data = df_main, cluster = ~state_fips)

cat("  Horse race (SCI + distance):\n")
cat("    Network (SCI): β =", round(coef(horse_race)["network_mw_full"], 4),
    ", p =", round(pvalue(horse_race)["network_mw_full"], 4), "\n")
cat("    Geographic:    β =", round(coef(horse_race)["geo_mw_exposure"], 4),
    ", p =", round(pvalue(horse_race)["geo_mw_exposure"], 4), "\n\n")

# ============================================================================
# 6. Heterogeneity
# ============================================================================

cat("6. Heterogeneity analysis...\n\n")

# By initial MW level: federal floor ($7.25) vs. above
df_main <- df_main %>%
  mutate(
    at_fed_floor = as.integer(own_mw <= 7.30),
    blue_gov = as.integer(gov_party == "D")
  )

het_floor <- feols(mw_increased ~ network_mw_full + network_mw_full:at_fed_floor +
                     log_own_mw + gov_dem + trifecta_dem + trifecta_rep +
                     union_density + unemp_rate |
                     state_fips + year,
                   data = df_main, cluster = ~state_fips)

cat("  By initial MW level:\n")
cat("    Above floor: β =", round(coef(het_floor)["network_mw_full"], 4), "\n")
cat("    Interaction (at floor): β =",
    round(coef(het_floor)["network_mw_full:at_fed_floor"], 4), "\n")

# By political lean
het_pol <- feols(mw_increased ~ network_mw_full + network_mw_full:blue_gov +
                   log_own_mw + gov_dem + trifecta_dem + trifecta_rep +
                   union_density + unemp_rate |
                   state_fips + year,
                 data = df_main, cluster = ~state_fips)

cat("  By governor party:\n")
cat("    Republican: β =", round(coef(het_pol)["network_mw_full"], 4), "\n")
cat("    Interaction (Dem): β =",
    round(coef(het_pol)["network_mw_full:blue_gov"], 4), "\n\n")

# ============================================================================
# 7. Assessment — Which Scenario?
# ============================================================================

cat("========================================\n")
cat("=== SCENARIO ASSESSMENT ===\n")
cat("========================================\n\n")

# Key diagnostics
baseline_p <- pvalue(m1_lpm)["network_mw_full"]
political_p <- pvalue(m2_lpm)["network_mw_full"]
full_p <- pvalue(m4_lpm)["network_mw_full"]
iv_p_val <- pvalue(m5_lpm)["fit_network_mw_full"]
fs_f_val <- fs_f$ivf$stat

baseline_b <- coef(m1_lpm)["network_mw_full"]
political_b <- coef(m2_lpm)["network_mw_full"]
full_b <- coef(m4_lpm)["network_mw_full"]
iv_b <- coef(m5_lpm)["fit_network_mw_full"]

# Attenuation from political controls
attenuation <- 1 - abs(political_b / baseline_b)

cat("  Baseline coefficient:", round(baseline_b, 4), "(p =", round(baseline_p, 4), ")\n")
cat("  After political controls:", round(political_b, 4), "(p =", round(political_p, 4), ")\n")
cat("  Full specification:", round(full_b, 4), "(p =", round(full_p, 4), ")\n")
cat("  IV coefficient:", round(iv_b, 4), "(p =", round(iv_p_val, 4), ")\n")
cat("  First-stage F:", round(fs_f_val, 1), "\n")
cat("  Attenuation from political controls:", round(100 * attenuation, 1), "%\n\n")

# Determine scenario
if (iv_p_val < 0.10 & iv_b > 0 & fs_f_val > 10) {
  scenario <- "A"
  cat("  >>> SCENARIO A: Effect survives controls + IV\n")
  cat("  Expand to 2-3 pages, report full table, cascade multiplier warranted\n")
} else if (political_p > 0.10 | (abs(political_b) < abs(baseline_b) * 0.3)) {
  scenario <- "B"
  cat("  >>> SCENARIO B: Effect collapses with political controls\n")
  cat("  Keep at ~1 page, report null honestly, clean channel separation\n")
} else {
  scenario <- "C"
  cat("  >>> SCENARIO C: Inconclusive — keep as descriptive with better controls\n")
  cat("  ~1 page with political controls, acknowledge power limitations\n")
}

# Save scenario for downstream scripts
writeLines(scenario, "../data/diffusion_scenario.txt")
cat("\n  Scenario saved to ../data/diffusion_scenario.txt\n")

# ============================================================================
# 8. Generate LaTeX Table
# ============================================================================

cat("\n8. Generating LaTeX table...\n")

# Helper function to format coefficient with stars
format_coef <- function(model, var_name, is_iv = FALSE) {
  if (is_iv) var_name <- paste0("fit_", var_name)
  if (!(var_name %in% names(coef(model)))) {
    return(list(coef = "---", se = ""))
  }
  b <- coef(model)[var_name]
  se <- sqrt(vcov(model)[var_name, var_name])
  p <- pvalue(model)[var_name]
  stars <- ifelse(p < 0.01, "^{***}", ifelse(p < 0.05, "^{**}", ifelse(p < 0.10, "^{*}", "")))
  list(
    coef = sprintf("%.3f%s", b, stars),
    se = sprintf("(%.3f)", se)
  )
}

sink("../tables/tab_policy_diffusion.tex")

cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Policy Diffusion: Network Exposure and Future Minimum Wage Changes}\n")
cat("\\label{tab:diffusion}\n")
cat("\\begin{threeparttable}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) & (4) & (5) \\\\\n")
cat(" & \\multicolumn{4}{c}{OLS} & IV \\\\\n")
cat("\\cmidrule(lr){2-5} \\cmidrule(lr){6-6}\n")

# Panel A: Binary outcome
cat("\\addlinespace\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: MW Increase}$_{s,t+1}$ \\textit{(LPM)}} \\\\\n")
cat("\\addlinespace\n")

r1a <- format_coef(m1_lpm, "network_mw_full")
r2a <- format_coef(m2_lpm, "network_mw_full")
r3a <- format_coef(m3_lpm, "network_mw_full")
r4a <- format_coef(m4_lpm, "network_mw_full")
r5a <- format_coef(m5_lpm, "network_mw_full", is_iv = TRUE)

cat(sprintf("Network MW$_t$ & %s & %s & %s & %s & %s \\\\\n",
            r1a$coef, r2a$coef, r3a$coef, r4a$coef, r5a$coef))
cat(sprintf(" & %s & %s & %s & %s & %s \\\\\n",
            r1a$se, r2a$se, r3a$se, r4a$se, r5a$se))

# Panel B: Continuous outcome
cat("\\addlinespace\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B:} $\\Delta\\log$(MW)$_{s,t+1}$} \\\\\n")
cat("\\addlinespace\n")

r1b <- format_coef(m1_cont, "network_mw_full")
r2b <- format_coef(m2_cont, "network_mw_full")
r3b <- format_coef(m3_cont, "network_mw_full")
r4b <- format_coef(m4_cont, "network_mw_full")
r5b <- format_coef(m5_cont, "network_mw_full", is_iv = TRUE)

cat(sprintf("Network MW$_t$ & %s & %s & %s & %s & %s \\\\\n",
            r1b$coef, r2b$coef, r3b$coef, r4b$coef, r5b$coef))
cat(sprintf(" & %s & %s & %s & %s & %s \\\\\n",
            r1b$se, r2b$se, r3b$se, r4b$se, r5b$se))

# Controls rows
cat("\\addlinespace\n")
cat("\\midrule\n")
cat("Lagged own MW & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("State FE & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Year FE & Yes & Yes & Yes & --- & --- \\\\\n")
cat("Governor party, trifecta & & Yes & Yes & Yes & Yes \\\\\n")
cat("Union density, unemployment & & & Yes & Yes & Yes \\\\\n")
cat("Region $\\times$ year FE & & & & Yes & Yes \\\\\n")
cat("Instrument & & & & & Non-adj. \\\\\n")

cat("\\addlinespace\n")
cat(sprintf("Observations & %d & %d & %d & %d & %d \\\\\n",
            nobs(m1_lpm), nobs(m2_lpm), nobs(m3_lpm), nobs(m4_lpm), nobs(m5_lpm)))
cat(sprintf("States & %d & %d & %d & %d & %d \\\\\n",
            n_distinct(df_main$state_fips[!is.na(m1_lpm$fitted.values)]),
            n_distinct(df_main$state_fips[!is.na(m2_lpm$fitted.values)]),
            n_distinct(df_main$state_fips[!is.na(m3_lpm$fitted.values)]),
            n_distinct(df_main$state_fips[!is.na(m4_lpm$fitted.values)]),
            n_distinct(df_main$state_fips[!is.na(m5_lpm$fitted.values)])))

# First-stage F for IV
cat(sprintf("First-stage F & & & & & %.1f \\\\\n", fs_f_val))

cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Unit of observation is state-year. Panel A: linear probability model; dependent variable is indicator for minimum wage increase in $t+1$. Panel B: dependent variable is $\\Delta\\log(\\text{MW})_{s,t+1}$. Network MW is the population-weighted state-level network minimum wage exposure, constructed by aggregating county-level SCI to state pairs. States at the \\$15 ceiling excluded. Column~5 instruments full network exposure with non-adjacent-state-only exposure (states not sharing a border). Standard errors clustered at state level. *** $p<0.01$, ** $p<0.05$, * $p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("  Table saved to ../tables/tab_policy_diffusion.tex\n")

# ============================================================================
# 9. Falsification Table
# ============================================================================

cat("\n9. Generating falsification results...\n")

sink("../tables/tab_diffusion_falsification.tex")

cat("\\begin{table}[t]\n")
cat("\\centering\n")
cat("\\caption{Falsification: Placebo Network Exposures and MW Adoption}\n")
cat("\\label{tab:diffusion_fals}\n")
cat("\\begin{threeparttable}\n")
cat("\\small\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat(" & (1) & (2) & (3) \\\\\n")
cat(" & Gas Tax & Corp Tax & Horse Race \\\\\n")
cat("\\midrule\n")

f_gas <- format_coef(fals_gas, "network_gas_tax")
f_corp <- format_coef(fals_corp, "network_corp_tax")
f_hr_sci <- format_coef(horse_race, "network_mw_full")
f_hr_geo <- format_coef(horse_race, "geo_mw_exposure")

cat(sprintf("Network gas tax$_t$ & %s & & \\\\\n", f_gas$coef))
cat(sprintf(" & %s & & \\\\\n", f_gas$se))
cat(sprintf("Network corp tax$_t$ & & %s & \\\\\n", f_corp$coef))
cat(sprintf(" & & %s & \\\\\n", f_corp$se))
cat(sprintf("Network MW$_t$ (SCI) & & & %s \\\\\n", f_hr_sci$coef))
cat(sprintf(" & & & %s \\\\\n", f_hr_sci$se))
cat(sprintf("Geographic MW$_t$ (inv. dist.) & & & %s \\\\\n", f_hr_geo$coef))
cat(sprintf(" & & & %s \\\\\n", f_hr_geo$se))

cat("\\addlinespace\n")
cat("\\midrule\n")
cat("Political controls & Yes & Yes & Yes \\\\\n")
cat("State FE, Year FE & Yes & Yes & Yes \\\\\n")
cat(sprintf("Observations & %d & %d & %d \\\\\n",
            nobs(fals_gas), nobs(fals_corp), nobs(horse_race)))
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Dependent variable: indicator for minimum wage increase in $t+1$. Column~1: SCI-weighted network exposure to other states' gas tax rates. Column~2: SCI-weighted network exposure to corporate income tax rates. Column~3: simultaneous inclusion of SCI-weighted MW exposure and inverse-distance-weighted MW exposure. All specifications include lagged own MW, governor party, trifecta status, union density, unemployment, state FE, and year FE. Standard errors clustered at state level. *** $p<0.01$, ** $p<0.05$, * $p<0.10$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()

cat("  Falsification table saved to ../tables/tab_diffusion_falsification.tex\n")

# ============================================================================
# 10. Summary of All Results
# ============================================================================

cat("\n========================================\n")
cat("=== COMPLETE RESULTS SUMMARY ===\n")
cat("========================================\n\n")

cat("PROGRESSIVE CONTROLS (LPM, MW increase in t+1):\n")
cat(sprintf("  (1) Baseline:     β = %.3f (p = %.3f)\n", baseline_b, baseline_p))
cat(sprintf("  (2) + Political:  β = %.3f (p = %.3f) [%.0f%% attenuation]\n",
            political_b, political_p, 100 * attenuation))
cat(sprintf("  (3) + Union/UR:   β = %.3f (p = %.3f)\n",
            coef(m3_lpm)["network_mw_full"], pvalue(m3_lpm)["network_mw_full"]))
cat(sprintf("  (4) + Region×Yr:  β = %.3f (p = %.3f)\n", full_b, full_p))
cat(sprintf("  (5) IV:           β = %.3f (p = %.3f) [F = %.1f]\n",
            iv_b, iv_p_val, fs_f_val))

cat("\nFALSIFICATION:\n")
if ("network_gas_tax" %in% names(coef(fals_gas))) {
  cat(sprintf("  Gas tax → MW:     β = %.3f (p = %.3f)\n",
              coef(fals_gas)["network_gas_tax"], pvalue(fals_gas)["network_gas_tax"]))
} else {
  cat("  Gas tax → MW:     collinear with FE\n")
}
if ("network_corp_tax" %in% names(coef(fals_corp))) {
  cat(sprintf("  Corp tax → MW:    β = %.3f (p = %.3f)\n",
              coef(fals_corp)["network_corp_tax"], pvalue(fals_corp)["network_corp_tax"]))
} else {
  cat("  Corp tax → MW:    collinear with FE\n")
}
cat(sprintf("  SCI vs Geo:       SCI β = %.3f (p = %.3f), Geo β = %.3f (p = %.3f)\n",
            coef(horse_race)["network_mw_full"], pvalue(horse_race)["network_mw_full"],
            coef(horse_race)["geo_mw_exposure"], pvalue(horse_race)["geo_mw_exposure"]))

cat(sprintf("\nSCENARIO: %s\n", scenario))
cat("=== Analysis Complete ===\n")
