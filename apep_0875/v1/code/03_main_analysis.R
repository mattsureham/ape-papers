# =============================================================================
# 03_main_analysis.R — Main event study and DiD estimates
# =============================================================================

source("00_packages.R")

survival_panel <- readRDS("../data/survival_panel.rds")
cip_panel <- readRDS("../data/cip_panel.rds")

# =============================================================================
# 1. MAIN SPECIFICATION: Event Study — Program Survival
# =============================================================================
cat("=== Main Event Study: Program Survival ===\n")

# Use programs that existed in 2013 (last full pre-GE year) as the cohort
cohort_2013 <- survival_panel %>%
  filter(year == 2013, alive == 1) %>%
  distinct(program_id)

# Build cohort panel
cohort_panel <- survival_panel %>%
  filter(program_id %in% cohort_2013$program_id, year >= 2010) %>%
  mutate(
    # Event time relative to 2015 (GE effective)
    event_time = year - 2015,
    # Factor for event study (omit -1 as reference)
    event_time_f = factor(event_time),
    # Cluster ID
    state_sector = paste(state, for_profit, sep = "_")
  )

cat(sprintf("Cohort 2013: %s programs (%s FP, %s Public)\n",
            format(n_distinct(cohort_panel$program_id), big.mark = ","),
            format(sum(cohort_panel$for_profit == 1 & cohort_panel$year == 2013), big.mark = ","),
            format(sum(cohort_panel$for_profit == 0 & cohort_panel$year == 2013), big.mark = ",")))

# Event study with fixest
# Y = alive (0/1); interaction of for_profit × event_time dummies
# FE: program_id (absorbs level differences), year (absorbs common trends)
# Cluster: state level
est_event <- feols(
  alive ~ i(event_time, for_profit, ref = -1) | program_id + year,
  data = cohort_panel,
  cluster = ~state
)
cat("\nEvent Study Estimates:\n")
summary(est_event)

# =============================================================================
# 2. STATIC DiD: Pre-GE (2010-2014) vs Post-GE (2015-2019) vs Post-Repeal (2020-2023)
# =============================================================================
cat("\n=== Static DiD ===\n")

cohort_panel <- cohort_panel %>%
  mutate(
    period = case_when(
      year <= 2014 ~ "Pre-GE",
      year <= 2019 ~ "Post-GE",
      TRUE ~ "Post-Repeal"
    ),
    post_ge = as.integer(year >= 2015),
    post_repeal = as.integer(year >= 2020)
  )

# Two-period DiD
est_did_simple <- feols(
  alive ~ for_profit:post_ge | program_id + year,
  data = cohort_panel,
  cluster = ~state
)

# Three-period DiD (GE + Repeal)
est_did_3period <- feols(
  alive ~ for_profit:post_ge + for_profit:post_repeal | program_id + year,
  data = cohort_panel,
  cluster = ~state
)

cat("Two-period DiD (Pre vs Post-GE):\n")
summary(est_did_simple)
cat("\nThree-period DiD (Pre vs Post-GE vs Post-Repeal):\n")
summary(est_did_3period)

# =============================================================================
# 3. COMPLETIONS ANALYSIS: Log completions for surviving programs
# =============================================================================
cat("\n=== Completions Analysis (Intensive Margin) ===\n")

# Among programs that survive, do completions decline?
completions_data <- readRDS("../data/ipeds_completions.rds") %>%
  inner_join(readRDS("../data/ipeds_institutions.rds") %>%
               select(unitid, year, control, state),
             by = c("unitid", "year")) %>%
  mutate(
    for_profit = as.integer(control == 3),
    program_id = paste(unitid, cipcode, award_level, sep = "_"),
    log_completions = log(pmax(total_completions, 1))
  ) %>%
  filter(program_id %in% cohort_2013$program_id,
         year >= 2010, total_completions > 0) %>%
  mutate(
    event_time = year - 2015,
    post_ge = as.integer(year >= 2015)
  )

est_completions <- feols(
  log_completions ~ i(event_time, for_profit, ref = -1) | program_id + year,
  data = completions_data,
  cluster = ~state
)

est_completions_did <- feols(
  log_completions ~ for_profit:post_ge | program_id + year,
  data = completions_data,
  cluster = ~state
)

cat("Completions event study:\n")
summary(est_completions)
cat("\nCompletions DiD:\n")
summary(est_completions_did)

# =============================================================================
# 4. CIP-LEVEL ANALYSIS: Program counts by field
# =============================================================================
cat("\n=== CIP-Level Analysis ===\n")

cip_panel <- cip_panel %>%
  mutate(
    log_programs = log(pmax(n_programs, 1)),
    log_completions = log(pmax(total_completions, 1)),
    post_ge = as.integer(year >= 2015),
    cip_sector = paste(cip2, for_profit, sep = "_")
  )

est_cip <- feols(
  log_programs ~ i(year, for_profit, ref = 2014) | cip_sector + year,
  data = cip_panel,
  cluster = ~cip2
)

cat("CIP-level program count event study:\n")
summary(est_cip)

# =============================================================================
# 5. SAVE RESULTS AND DIAGNOSTICS
# =============================================================================

# Diagnostics for validator
n_treated <- sum(cohort_panel$for_profit == 1 & cohort_panel$year == 2013)
n_control <- sum(cohort_panel$for_profit == 0 & cohort_panel$year == 2013)
n_pre <- length(unique(cohort_panel$year[cohort_panel$year < 2015]))
n_obs <- nrow(cohort_panel)
n_clusters <- n_distinct(cohort_panel$state)

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = n_pre,
  n_obs = n_obs,
  n_clusters = n_clusters
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: %d treated, %d control, %d pre-periods, %s obs, %d clusters\n",
            n_treated, n_control, n_pre, format(n_obs, big.mark = ","), n_clusters))

# Save model objects
saveRDS(est_event, "../data/est_event.rds")
saveRDS(est_did_simple, "../data/est_did_simple.rds")
saveRDS(est_did_3period, "../data/est_did_3period.rds")
saveRDS(est_completions, "../data/est_completions.rds")
saveRDS(est_completions_did, "../data/est_completions_did.rds")
saveRDS(est_cip, "../data/est_cip.rds")
saveRDS(cohort_panel, "../data/cohort_panel.rds")

cat("\nMain analysis complete.\n")
