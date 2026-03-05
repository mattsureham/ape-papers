##########################################################################
# 03_main_analysis.R — Primary DiD analysis
# Paper: The Price of Pork — France's Dual-Mandate Ban
# apep_0514
#
# The dual-mandate ban was enacted Feb 2014 (Loi organique n°2014-125)
# and took effect at the June 2017 legislative elections. Deputies who
# were also mayors had to resign one mandate.
#
# Treatment timing: post = year >= 2018 (2017 budgets precede June elections)
# Panel: DGFiP 2008-2017 (pre) + OFGL 2020, 2023 (post)
# Panel is unbalanced in post-period: OFGL 2018-2019 data quality is unusable.
#
# Estimates:
#   1. Two-period DiD (pre/post 2018)
#   2. Event-study specification (year-by-year coefficients)
##########################################################################

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# LOAD DATA
# ============================================================================
cat("\n=== Loading analysis panels ===\n")

circo <- readRDS(paste0(data_dir, "analysis_panel.rds"))
commune <- readRDS(paste0(data_dir, "commune_panel.rds"))

cat("  Constituency panel:", nrow(circo), "obs,", n_distinct(circo$circo_id), "constituencies\n")
cat("  Years available:", paste(sort(unique(circo$year)), collapse = ", "), "\n")
cat("  Commune panel:", nrow(commune), "obs,", n_distinct(commune$code_insee), "communes\n")

# ============================================================================
# PRIMARY SPECIFICATION: CONSTITUENCY-LEVEL DiD
# ============================================================================
cat("\n=== Primary Specification: Constituency-Level DiD ===\n")

# Use all available years: 2008-2017 (DGFiP) + 2020, 2023 (OFGL)
# Post = year >= 2018 (first full fiscal year after June 2017 elections)
circo_main <- circo %>%
  mutate(
    post = as.integer(year >= 2018),
    treated = is_cumulard_maire * post
  )

cat("  Analysis window:", paste(sort(unique(circo_main$year)), collapse = ", "), "\n")
cat("  Observations:", nrow(circo_main), "\n")
cat("  Pre-period obs:", sum(circo_main$post == 0), "\n")
cat("  Post-period obs:", sum(circo_main$post == 1), "\n")
cat("  Constituencies:", n_distinct(circo_main$circo_id), "\n")
cat("  Cumulard constituencies:", n_distinct(circo_main$circo_id[circo_main$is_cumulard_maire == 1]), "\n")
cat("  Non-cumulard constituencies:", n_distinct(circo_main$circo_id[circo_main$is_cumulard_maire == 0]), "\n")

# --- Model 1: Investment per capita ---
cat("\n--- Model 1: Investment per capita ---\n")
m1 <- feols(invest_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m1)

# --- Model 2: Equipment expenditure per capita ---
cat("\n--- Model 2: Equipment expenditure per capita ---\n")
m2 <- feols(equip_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m2)

# --- Model 3: State grants (dotations) per capita ---
cat("\n--- Model 3: State grants per capita ---\n")
m3 <- feols(dotation_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m3)

# --- Model 4: Total operating expenditure per capita ---
cat("\n--- Model 4: Operating expenditure per capita ---\n")
m4 <- feols(charges_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m4)

# --- Model 5: Total revenue per capita ---
cat("\n--- Model 5: Revenue per capita ---\n")
m5 <- feols(produits_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m5)

# --- Model 6: Debt per capita ---
cat("\n--- Model 6: Debt per capita ---\n")
m6 <- feols(dette_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m6)

# --- Model 7: Log investment per capita ---
cat("\n--- Model 7: Log investment per capita ---\n")
m7 <- feols(log_invest_pc ~ treated | circo_id + year,
            data = circo_main, cluster = ~circo_id)
summary(m7)

# Combined table
cat("\n=== Combined Results Table ===\n")
etable(m1, m2, m3, m4, m5, m6, m7,
       headers = c("Invest PC", "Equip PC", "Grants PC", "OpEx PC",
                    "Revenue PC", "Debt PC", "Log Invest PC"),
       se.below = TRUE)

# ============================================================================
# EVENT STUDY SPECIFICATION
# ============================================================================
cat("\n=== Event Study Specification ===\n")

# Event time: relative to 2018 (first full post-treatment year)
# Base year = 2017 (last pre-treatment year, event_time = -1)
circo_es <- circo %>%
  mutate(
    event_time = year - 2018
  )

cat("  Event times:", paste(sort(unique(circo_es$event_time)), collapse = ", "), "\n")

# Event study: investment per capita
cat("\n--- Event Study: Investment per capita ---\n")
es_invest <- feols(invest_pc ~ i(event_time, is_cumulard_maire, ref = -1) |
                     circo_id + year,
                   data = circo_es, cluster = ~circo_id)
summary(es_invest)

# Event study: equipment per capita
cat("\n--- Event Study: Equipment per capita ---\n")
es_equip <- feols(equip_pc ~ i(event_time, is_cumulard_maire, ref = -1) |
                    circo_id + year,
                  data = circo_es, cluster = ~circo_id)
summary(es_equip)

# Event study: grants per capita
cat("\n--- Event Study: Grants per capita ---\n")
es_grants <- feols(dotation_pc ~ i(event_time, is_cumulard_maire, ref = -1) |
                     circo_id + year,
                   data = circo_es, cluster = ~circo_id)
summary(es_grants)

# Event study: operating expenditure per capita
cat("\n--- Event Study: Operating expenditure per capita ---\n")
es_opex <- feols(charges_pc ~ i(event_time, is_cumulard_maire, ref = -1) |
                   circo_id + year,
                 data = circo_es, cluster = ~circo_id)
summary(es_opex)

# ============================================================================
# JOINT F-TESTS ON PRE-TREATMENT COEFFICIENTS
# ============================================================================
cat("\n=== Joint F-Tests on Pre-Treatment Coefficients ===\n")

# Extract pre-treatment coefficient names (negative event times, excluding ref=-1)
pre_coefs_invest <- grep("event_time::-[0-9]", names(coef(es_invest)), value = TRUE)
pre_coefs_equip <- grep("event_time::-[0-9]", names(coef(es_equip)), value = TRUE)
pre_coefs_grants <- grep("event_time::-[0-9]", names(coef(es_grants)), value = TRUE)
pre_coefs_opex <- grep("event_time::-[0-9]", names(coef(es_opex)), value = TRUE)

f_invest <- wald(es_invest, pre_coefs_invest)
f_equip <- wald(es_equip, pre_coefs_equip)
f_grants <- wald(es_grants, pre_coefs_grants)
f_opex <- wald(es_opex, pre_coefs_opex)

cat("  Joint F-test (pre-trends = 0):\n")
cat("    Investment: F =", round(f_invest$stat, 3), ", p =", round(f_invest$p, 3), "\n")
cat("    Equipment:  F =", round(f_equip$stat, 3), ", p =", round(f_equip$p, 3), "\n")
cat("    Grants:     F =", round(f_grants$stat, 3), ", p =", round(f_grants$p, 3), "\n")
cat("    OpEx:       F =", round(f_opex$stat, 3), ", p =", round(f_opex$p, 3), "\n")

# Save F-test results for paper
f_tests <- list(
  invest = list(stat = f_invest$stat, p = f_invest$p),
  equip = list(stat = f_equip$stat, p = f_equip$p),
  grants = list(stat = f_grants$stat, p = f_grants$p),
  opex = list(stat = f_opex$stat, p = f_opex$p)
)
saveRDS(f_tests, paste0(data_dir, "f_tests_pretrends.rds"))

# ============================================================================
# COMMUNE-LEVEL SPECIFICATION (ROBUSTNESS)
# ============================================================================
cat("\n=== Commune-Level Specification ===\n")

commune_main <- commune %>%
  mutate(
    post = as.integer(year >= 2018),
    treated = is_cumulard_maire * post
  )

# Commune-level with constituency-clustered SEs
cat("\n--- Commune-level: Investment per capita ---\n")
mc1 <- feols(invest_pc ~ treated | code_insee + year,
             data = commune_main, cluster = ~circo_id)
summary(mc1)

cat("\n--- Commune-level: Equipment per capita ---\n")
mc2 <- feols(equip_pc ~ treated | code_insee + year,
             data = commune_main, cluster = ~circo_id)
summary(mc2)

cat("\n--- Commune-level: Grants per capita ---\n")
mc3 <- feols(dotation_pc ~ treated | code_insee + year,
             data = commune_main, cluster = ~circo_id)
summary(mc3)

# ============================================================================
# SAVE RESULTS
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  # Primary DiD
  m_invest = m1, m_equip = m2, m_grants = m3,
  m_opex = m4, m_revenue = m5, m_debt = m6, m_log_invest = m7,
  # Event studies
  es_invest = es_invest, es_equip = es_equip,
  es_grants = es_grants, es_opex = es_opex,
  # Commune-level
  mc_invest = mc1, mc_equip = mc2, mc_grants = mc3
)

saveRDS(results, paste0(data_dir, "main_results.rds"))
cat("  Saved main_results.rds\n")
cat("\n=== 03_main_analysis.R complete ===\n")
