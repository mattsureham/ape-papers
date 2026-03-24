## 03_main_analysis.R — Primary specifications and event studies
## Paper: Cottage Food Law Liberalization and Micro-Entrepreneurship (apep_0853)

source("00_packages.R")
load("../data/analysis_panel.RData")

# =============================================================================
# TABLE 1: Summary Statistics
# =============================================================================

# Pre-treatment means by treatment status
summ_stats <- panel %>%
  mutate(treated_ever = g > 0) %>%
  group_by(treated_ever) %>%
  summarise(
    n_states = n_distinct(state_fips),
    mean_estab_311 = mean(estab_311, na.rm = TRUE),
    sd_estab_311 = sd(estab_311, na.rm = TRUE),
    mean_estab_311_pc = mean(estab_311_pc, na.rm = TRUE),
    sd_estab_311_pc = sd(estab_311_pc, na.rm = TRUE),
    mean_estab_3118 = mean(estab_3118, na.rm = TRUE),
    sd_estab_3118 = sd(estab_3118, na.rm = TRUE),
    mean_employer_estab = mean(employer_estab_311, na.rm = TRUE),
    sd_employer_estab = sd(employer_estab_311, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Summary Statistics ===\n")
print(summ_stats)

# =============================================================================
# PRIMARY SPECIFICATION: TWFE (baseline)
# =============================================================================

cat("\n=== TWFE Results ===\n")

# Model 1: Log nonemployer establishments (NAICS 311)
twfe_estab <- feols(ln_estab_311 ~ treated | state_fips + year,
                     data = panel, cluster = ~state_fips)
cat("\nModel 1: Log Nonemployer Establishments (NAICS 311)\n")
summary(twfe_estab)

# Model 2: Per-capita nonemployer establishments
twfe_estab_pc <- feols(estab_311_pc ~ treated | state_fips + year,
                        data = panel, cluster = ~state_fips)
cat("\nModel 2: Nonemployer Establishments per 100K\n")
summary(twfe_estab_pc)

# Model 3: Log receipts
twfe_receipts <- feols(ln_receipts_311 ~ treated | state_fips + year,
                        data = panel, cluster = ~state_fips)
cat("\nModel 3: Log Receipts (NAICS 311)\n")
summary(twfe_receipts)

# =============================================================================
# CALLAWAY-SANT'ANNA (2021) — robust to heterogeneous effects
# =============================================================================

cat("\n=== Callaway-Sant'Anna DiD ===\n")

# CS requires: yname, gname, idname, tname
# Consolidate thin cohorts into broader bins to avoid singular matrices
# 2012 cohort is already treated from panel start — assign to comparison (g=0)
cs_data <- panel %>%
  mutate(
    state_num = as.integer(as.factor(state_fips)),
    g_cs = as.numeric(g),
    # Move 2012 cohort to comparison (treated from first panel year, no pre-treatment obs)
    g_cs = ifelse(g_cs == 2012, 0, g_cs)
  )

cat("CS cohort sizes:\n")
print(table(cs_data$g_cs[!duplicated(cs_data$state_fips)]))

# ATT(g,t) estimation
cs_estab <- att_gt(
  yname = "ln_estab_311",
  gname = "g_cs",
  idname = "state_num",
  tname = "year",
  data = cs_data,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\nCS ATT(g,t) summary:\n")
summary(cs_estab)

# Aggregate to simple ATT
cs_agg_simple <- aggte(cs_estab, type = "simple")
cat("\nCS Simple ATT:\n")
summary(cs_agg_simple)

# Aggregate to event-study
cs_agg_event <- aggte(cs_estab, type = "dynamic", min_e = -5, max_e = 5)
cat("\nCS Event Study:\n")
summary(cs_agg_event)

# =============================================================================
# CS DiD for per-capita establishments
# =============================================================================

cs_estab_pc <- att_gt(
  yname = "estab_311_pc",
  gname = "g_cs",
  idname = "state_num",
  tname = "year",
  data = cs_data,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cs_agg_pc <- aggte(cs_estab_pc, type = "simple")
cat("\nCS Simple ATT (per capita):\n")
summary(cs_agg_pc)

cs_event_pc <- aggte(cs_estab_pc, type = "dynamic", min_e = -5, max_e = 5)

# =============================================================================
# CS DiD for log receipts
# =============================================================================

cs_receipts <- att_gt(
  yname = "ln_receipts_311",
  gname = "g_cs",
  idname = "state_num",
  tname = "year",
  data = cs_data,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cs_agg_receipts <- aggte(cs_receipts, type = "simple")
cat("\nCS Simple ATT (log receipts):\n")
summary(cs_agg_receipts)

# =============================================================================
# MECHANISM: Bakeries (NAICS 3118) vs total food manufacturing
# =============================================================================

cat("\n=== Mechanism: Bakeries ===\n")

cs_data_mech <- cs_data %>% filter(!is.na(estab_3118) & !is.na(ln_estab_3118))

if (nrow(cs_data_mech) > 50) {
  cs_bakery <- att_gt(
    yname = "ln_estab_3118",
    gname = "g_cs",
    idname = "state_num",
    tname = "year",
    data = cs_data_mech,
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )

  cs_agg_bakery <- aggte(cs_bakery, type = "simple")
  cat("\nCS Simple ATT (bakeries):\n")
  summary(cs_agg_bakery)
} else {
  cat("Insufficient bakery data for CS estimation.\n")
  cs_bakery <- NULL
  cs_agg_bakery <- NULL
}

# =============================================================================
# PLACEBO: Employer establishments (NAICS 311)
# =============================================================================

cat("\n=== Placebo: Employer Establishments ===\n")

cs_data_placebo <- cs_data %>% filter(!is.na(employer_estab_311) & !is.na(ln_employer_estab_311))

if (nrow(cs_data_placebo) > 50) {
  cs_placebo <- att_gt(
    yname = "ln_employer_estab_311",
    gname = "g_cs",
    idname = "state_num",
    tname = "year",
    data = cs_data_placebo,
    control_group = "notyettreated",
    anticipation = 0,
    est_method = "dr",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )

  cs_agg_placebo <- aggte(cs_placebo, type = "simple")
  cat("\nCS Simple ATT (employer placebo):\n")
  summary(cs_agg_placebo)

  cs_event_placebo <- aggte(cs_placebo, type = "dynamic", min_e = -5, max_e = 5)
} else {
  cat("Insufficient employer data for CS estimation.\n")
  cs_placebo <- NULL
  cs_agg_placebo <- NULL
  cs_event_placebo <- NULL
}

# =============================================================================
# SAVE RESULTS
# =============================================================================

save(twfe_estab, twfe_estab_pc, twfe_receipts,
     cs_estab, cs_agg_simple, cs_agg_event,
     cs_estab_pc, cs_agg_pc, cs_event_pc,
     cs_receipts, cs_agg_receipts,
     cs_bakery, cs_agg_bakery,
     cs_placebo, cs_agg_placebo, cs_event_placebo,
     summ_stats,
     file = "../data/main_results.RData")

# Write diagnostics.json for validation
# Count treated states in CS framework (g_cs > 0)
n_treated_states <- n_distinct(cs_data$state_fips[cs_data$g_cs > 0])
# Pre-periods from event study (number of pre-treatment lags estimated)
n_pre_computed <- sum(cs_agg_event$egt < 0)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre_computed,
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")
cat(sprintf("  n_treated = %d, n_pre = %d, n_obs = %d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\nMain analysis complete.\n")
