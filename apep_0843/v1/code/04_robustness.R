## 04_robustness.R — Robustness checks
## apep_0843: RON Laws and New Business Formation

source("00_packages.R")

panel <- readRDS("../data/panel_primary.rds")
panel_ext <- readRDS("../data/panel_extended.rds")
results <- readRDS("../data/main_results.rds")

panel <- panel %>% mutate(state_id = as.integer(factor(state)))
panel_ext <- panel_ext %>% mutate(state_id = as.integer(factor(state)))

cat("=== Robustness Checks ===\n\n")

# ------------------------------------------------------------------
# 1. Not-yet-treated control group
# ------------------------------------------------------------------
cat("--- R1: Not-yet-treated control group ---\n")

cs_nyt <- att_gt(
  yname       = "log_BA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "notyettreated",
  anticipation  = 0,
  base_period   = "varying"
)

agg_nyt <- aggte(cs_nyt, type = "simple")
cat("ATT (not-yet-treated):\n")
summary(agg_nyt)

# ------------------------------------------------------------------
# 2. Leave-one-cohort-out
# ------------------------------------------------------------------
cat("\n--- R2: Leave-one-cohort-out ---\n")

ron_treat <- readRDS("../data/ron_treatment.rds")
cohorts <- unique(year(ron_treat$ron_date))

loco_results <- list()

for (cohort_year in cohorts) {
  cat("  Dropping cohort:", cohort_year, "\n")

  # States in this cohort
  drop_states <- ron_treat %>%
    filter(year(ron_date) == cohort_year) %>%
    pull(state)

  panel_loco <- panel %>%
    filter(!(state %in% drop_states)) %>%
    mutate(state_id = as.integer(factor(state)))

  cs_loco <- att_gt(
    yname       = "log_BA",
    tname       = "time_index",
    idname      = "state_id",
    gname       = "first_treat",
    data        = panel_loco,
    control_group = "nevertreated",
    anticipation  = 0,
    base_period   = "varying"
  )

  agg_loco <- aggte(cs_loco, type = "simple")
  loco_results[[as.character(cohort_year)]] <- list(
    cohort = cohort_year,
    n_dropped = length(drop_states),
    att = agg_loco$overall.att,
    se  = agg_loco$overall.se
  )

  cat("    ATT:", round(agg_loco$overall.att, 4),
      "SE:", round(agg_loco$overall.se, 4), "\n")
}

# ------------------------------------------------------------------
# 3. Anticipation (1 month)
# ------------------------------------------------------------------
cat("\n--- R3: Anticipation = 1 month ---\n")

cs_antic <- att_gt(
  yname       = "log_BA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "nevertreated",
  anticipation  = 1,
  base_period   = "varying"
)

agg_antic <- aggte(cs_antic, type = "simple")
cat("ATT (1-month anticipation):\n")
summary(agg_antic)

# ------------------------------------------------------------------
# 4. Extended sample through 2024 (includes COVID era)
# ------------------------------------------------------------------
cat("\n--- R4: Extended sample through 2024 ---\n")

cs_ext <- att_gt(
  yname       = "log_BA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel_ext,
  control_group = "nevertreated",
  anticipation  = 0,
  base_period   = "varying"
)

agg_ext <- aggte(cs_ext, type = "simple")
cat("ATT (extended through 2024):\n")
summary(agg_ext)

# ------------------------------------------------------------------
# 5. Levels instead of logs
# ------------------------------------------------------------------
cat("\n--- R5: BA in levels (not logs) ---\n")

cs_levels <- att_gt(
  yname       = "BA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "nevertreated",
  anticipation  = 0,
  base_period   = "varying"
)

agg_levels <- aggte(cs_levels, type = "simple")
cat("ATT (levels):\n")
summary(agg_levels)

# ------------------------------------------------------------------
# 6. HonestDiD / Rambachan-Roth sensitivity
# ------------------------------------------------------------------
cat("\n--- R6: HonestDiD sensitivity analysis ---\n")

# Get event study for HonestDiD
es_ba <- results$es_ba

# Extract pre-treatment coefficients and variance-covariance
# HonestDiD works with fixest event studies; we'll use TWFE event study
# as the input since HonestDiD integrates best with fixest

# Create relative time variable
panel <- panel %>%
  mutate(
    rel_time = if_else(first_treat > 0,
                       time_index - first_treat,
                       NA_integer_)
  )

# TWFE event study for HonestDiD input
twfe_es <- feols(
  log_BA ~ i(rel_time, ref = -1) | state_id + time_index,
  data = panel %>% filter(!is.na(rel_time) | first_treat == 0) %>%
    mutate(rel_time = if_else(is.na(rel_time), -999L, rel_time)),
  cluster = ~state_id
)

# HonestDiD sensitivity
honest_result <- tryCatch({
  betahat <- coef(twfe_es)
  sigma <- vcov(twfe_es)

  # Keep only event-time coefficients (exclude the -999 bin)
  keep <- !grepl("-999", names(betahat))
  betahat <- betahat[keep]
  sigma <- sigma[keep, keep]

  # Determine pre/post periods
  event_times <- as.numeric(gsub("rel_time::", "", names(betahat)))
  pre_idx <- which(event_times < -1)
  post_idx <- which(event_times >= 0)

  if (length(pre_idx) > 0 && length(post_idx) > 0) {
    delta_rm_results <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("HonestDiD sensitivity analysis complete.\n")
    delta_rm_results
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
  cat("Proceeding without HonestDiD results.\n")
  NULL
})

# ------------------------------------------------------------------
# Save robustness results
# ------------------------------------------------------------------
robust <- list(
  nyt        = list(att = agg_nyt$overall.att, se = agg_nyt$overall.se),
  loco       = loco_results,
  antic      = list(att = agg_antic$overall.att, se = agg_antic$overall.se),
  extended   = list(att = agg_ext$overall.att, se = agg_ext$overall.se),
  levels     = list(att = agg_levels$overall.att, se = agg_levels$overall.se),
  honest_did = honest_result
)

saveRDS(robust, "../data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
