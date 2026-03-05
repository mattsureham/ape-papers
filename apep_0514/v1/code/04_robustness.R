##########################################################################
# 04_robustness.R — Robustness checks
# Paper: The Price of Pork — France's Dual-Mandate Ban
# apep_0514
##########################################################################

source("00_packages.R")

data_dir <- "../data/"

circo <- readRDS(paste0(data_dir, "analysis_panel.rds"))
commune <- readRDS(paste0(data_dir, "commune_panel.rds"))

# Panel years: 2008-2017 (DGFiP) + 2020, 2023 (OFGL)
# Treatment: post = year >= 2018

# ============================================================================
# 1. DGFiP-ONLY PANEL (2008-2017, BALANCED)
# ============================================================================
cat("\n=== Robustness 1: DGFiP-only balanced panel 2008-2017 ===\n")

circo_dgfip <- circo %>%
  filter(year >= 2008 & year <= 2017) %>%
  mutate(
    post = as.integer(year >= 2017),
    treated = is_cumulard_maire * post
  )

r1_invest <- feols(invest_pc ~ treated | circo_id + year,
                   data = circo_dgfip, cluster = ~circo_id)
r1_equip <- feols(equip_pc ~ treated | circo_id + year,
                  data = circo_dgfip, cluster = ~circo_id)
r1_opex <- feols(charges_pc ~ treated | circo_id + year,
                 data = circo_dgfip, cluster = ~circo_id)

cat("  DGFiP-only results (post = 2017):\n")
etable(r1_invest, r1_equip, r1_opex,
       headers = c("Invest PC", "Equip PC", "OpEx PC"))

# ============================================================================
# 2. PLACEBO TEST: FAKE BAN AT 2012
# ============================================================================
cat("\n=== Robustness 2: Placebo test (fake ban at 2012) ===\n")

circo_placebo <- circo %>%
  filter(year >= 2008 & year <= 2016) %>%
  mutate(
    post_placebo = as.integer(year >= 2012),
    treated_placebo = is_cumulard_maire * post_placebo
  )

r2_invest <- feols(invest_pc ~ treated_placebo | circo_id + year,
                   data = circo_placebo, cluster = ~circo_id)
r2_equip <- feols(equip_pc ~ treated_placebo | circo_id + year,
                  data = circo_placebo, cluster = ~circo_id)
r2_opex <- feols(charges_pc ~ treated_placebo | circo_id + year,
                 data = circo_placebo, cluster = ~circo_id)

cat("  Placebo results (should be null):\n")
etable(r2_invest, r2_equip, r2_opex,
       headers = c("Invest PC", "Equip PC", "OpEx PC"))

# ============================================================================
# 3. COMMUNE-LEVEL WITH POPULATION CONTROLS
# ============================================================================
cat("\n=== Robustness 3: Commune-level with population controls ===\n")

commune_main <- commune %>%
  mutate(
    post = as.integer(year >= 2018),
    treated = is_cumulard_maire * post,
    pop_bin = cut(population, breaks = c(0, 500, 2000, 10000, 50000, Inf),
                  labels = c("<500", "500-2k", "2k-10k", "10k-50k", ">50k"))
  )

# With population bin × year FE
r3_invest <- feols(invest_pc ~ treated | code_insee + year^pop_bin,
                   data = commune_main, cluster = ~circo_id)
r3_equip <- feols(equip_pc ~ treated | code_insee + year^pop_bin,
                  data = commune_main, cluster = ~circo_id)
r3_opex <- feols(charges_pc ~ treated | code_insee + year^pop_bin,
                 data = commune_main, cluster = ~circo_id)

etable(r3_invest, r3_equip, r3_opex,
       headers = c("Invest PC", "Equip PC", "OpEx PC"))

# ============================================================================
# 4. TRIPLE-DIFFERENCE: CUMULARD × POST × RURAL
# ============================================================================
cat("\n=== Robustness 4: Triple-difference (rural interaction) ===\n")

# Define rural as population < 2000
commune_ddd <- commune_main %>%
  mutate(
    rural = as.integer(population < 2000),
    treated_rural = treated * rural
  )

r4_invest <- feols(invest_pc ~ treated + treated_rural | code_insee + year,
                   data = commune_ddd, cluster = ~circo_id)
r4_equip <- feols(equip_pc ~ treated + treated_rural | code_insee + year,
                  data = commune_ddd, cluster = ~circo_id)

cat("  Triple-diff results:\n")
etable(r4_invest, r4_equip, headers = c("Invest PC", "Equip PC"))

# ============================================================================
# 5. ALTERNATIVE CLUSTERING (DÉPARTEMENT-LEVEL)
# ============================================================================
cat("\n=== Robustness 5: Alternative clustering ===\n")

circo_main <- circo %>%
  mutate(
    post = as.integer(year >= 2018),
    treated = is_cumulard_maire * post,
    code_dep = substr(circo_id, 1, 2)
  )

r5_invest <- feols(invest_pc ~ treated | circo_id + year,
                   data = circo_main, cluster = ~code_dep)
r5_equip <- feols(equip_pc ~ treated | circo_id + year,
                  data = circo_main, cluster = ~code_dep)
r5_opex <- feols(charges_pc ~ treated | circo_id + year,
                 data = circo_main, cluster = ~code_dep)

cat("  Département-clustered results:\n")
etable(r5_invest, r5_equip, r5_opex,
       headers = c("Invest PC", "Equip PC", "OpEx PC"))

# ============================================================================
# 6. EXCLUDING 2020 (COVID YEAR)
# ============================================================================
cat("\n=== Robustness 6: Excluding 2020 (COVID year) ===\n")

circo_no_covid <- circo %>%
  filter(year != 2020) %>%
  mutate(
    post = as.integer(year >= 2018),
    treated = is_cumulard_maire * post
  )

r6_invest <- feols(invest_pc ~ treated | circo_id + year,
                   data = circo_no_covid, cluster = ~circo_id)
r6_equip <- feols(equip_pc ~ treated | circo_id + year,
                  data = circo_no_covid, cluster = ~circo_id)

cat("  Excluding 2020 results (2023 as sole post-treatment year):\n")
etable(r6_invest, r6_equip, headers = c("Invest PC", "Equip PC"))

# ============================================================================
# 7. HONEST DiD (RAMBACHAN-ROTH SENSITIVITY)
# ============================================================================
cat("\n=== Robustness 6: HonestDiD sensitivity ===\n")

# Event study for HonestDiD
circo_es <- circo %>%
  mutate(event_time = year - 2018)

es_for_honest <- feols(invest_pc ~ i(event_time, is_cumulard_maire, ref = -1) |
                         circo_id + year,
                       data = circo_es, cluster = ~circo_id)

# Extract coefficients and variance-covariance matrix for HonestDiD
tryCatch({
  betahat <- coef(es_for_honest)
  sigma <- vcov(es_for_honest)

  # Identify pre and post periods
  pre_idx <- grep("event_time::-[0-9]", names(betahat))
  post_idx <- grep("event_time::[0-9]", names(betahat))

  cat("  Pre-period coefficients:", length(pre_idx), "\n")
  cat("  Post-period coefficients:", length(post_idx), "\n")

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    honest_results <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("  HonestDiD sensitivity results:\n")
    print(honest_results)

    saveRDS(honest_results, paste0(data_dir, "honest_did_results.rds"))
    cat("  Saved honest_did_results.rds\n")
  }
}, error = function(e) {
  cat("  HonestDiD failed:", e$message, "\n")
  cat("  Proceeding without sensitivity analysis.\n")
})

# ============================================================================
# SAVE ALL ROBUSTNESS RESULTS
# ============================================================================
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  dgfip_only = list(invest = r1_invest, equip = r1_equip, opex = r1_opex),
  placebo = list(invest = r2_invest, equip = r2_equip, opex = r2_opex),
  commune_pop = list(invest = r3_invest, equip = r3_equip, opex = r3_opex),
  triple_diff = list(invest = r4_invest, equip = r4_equip),
  dept_cluster = list(invest = r5_invest, equip = r5_equip, opex = r5_opex),
  no_covid = list(invest = r6_invest, equip = r6_equip)
)

saveRDS(robustness, paste0(data_dir, "robustness_results.rds"))
cat("  Saved robustness_results.rds\n")
cat("\n=== 04_robustness.R complete ===\n")
