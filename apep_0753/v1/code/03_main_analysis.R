# ============================================================
# 03_main_analysis.R — Main DiD analysis
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

source("00_packages.R")
library(fixest)
library(did)
library(data.table)
library(dplyr)

data_dir <- "../data"

# ----------------------------------------------------------
# 1. Load data
# ----------------------------------------------------------
cat("=== Loading analysis data ===\n")

panel <- readRDS(file.path(data_dir, "panel_by_type.rds"))
agg_panel <- readRDS(file.path(data_dir, "panel_aggregate.rds"))

# ----------------------------------------------------------
# 2. Convenience store panel (primary outcome)
# ----------------------------------------------------------
cat("\n=== Primary Analysis: Convenience Store Exit Rates ===\n")

# Convert state to numeric ID for CS
state_map <- data.table(state = sort(unique(panel$state)),
                        state_id = seq_along(sort(unique(panel$state))))
panel <- merge(panel, state_map, by = "state")
agg_panel <- merge(agg_panel, state_map, by = "state")

conv <- panel[store_type == "convenience"]
cat("  Observations:", nrow(conv), "\n")
cat("  States:", length(unique(conv$state)), "\n")
cat("  Quarters:", length(unique(conv$time_id)), "\n")
cat("  Treatment groups:", length(unique(conv$first_treat)), "\n")
cat("  Group sizes:\n")
print(conv[, .N, by = first_treat][order(first_treat)])

# ----------------------------------------------------------
# 2a. Callaway-Sant'Anna DiD
# ----------------------------------------------------------
cat("\n=== Callaway-Sant'Anna Estimation ===\n")

# CS requires: yname, tname, idname, gname, data
# Group = first treatment period (all states eventually treated)
# Control: not-yet-treated

cs_conv <- att_gt(
  yname = "exit_rate",
  tname = "time_id",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(conv),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\n  Group-time ATTs:\n")
print(summary(cs_conv))

# Aggregate to overall ATT
cs_att <- aggte(cs_conv, type = "simple")
cat("\n  Overall ATT:\n")
print(summary(cs_att))

# Dynamic (event-study) aggregation
cs_es <- aggte(cs_conv, type = "dynamic", min_e = -8, max_e = 8)
cat("\n  Event-study ATTs:\n")
print(summary(cs_es))

# Save CS results
saveRDS(cs_conv, file.path(data_dir, "cs_conv_results.rds"))
saveRDS(cs_att, file.path(data_dir, "cs_att_results.rds"))
saveRDS(cs_es, file.path(data_dir, "cs_es_results.rds"))

# ----------------------------------------------------------
# 2b. TWFE for comparison (with caveat about bias)
# ----------------------------------------------------------
cat("\n=== TWFE Comparison (diagnostic only) ===\n")

twfe_conv <- feols(exit_rate ~ treated | state + time_id,
                   data = conv, cluster = ~state)
cat("  TWFE estimate:\n")
print(summary(twfe_conv))

# Event study with fixest
conv[, rel_time := time_id - first_treat]

# Saturated event-study (Sun-Abraham via sunab)
es_sa <- feols(exit_rate ~ sunab(first_treat, time_id) | state + time_id,
               data = conv, cluster = ~state)
cat("\n  Sun-Abraham event study:\n")
print(summary(es_sa))

saveRDS(twfe_conv, file.path(data_dir, "twfe_conv.rds"))
saveRDS(es_sa, file.path(data_dir, "sunab_conv.rds"))

# ----------------------------------------------------------
# 3. Store-type comparison (DDD placebo)
# ----------------------------------------------------------
cat("\n=== Store-Type Comparison (DDD) ===\n")

# Compare convenience stores (high SNAP dependence) to supermarkets (low dependence)
ddd_data <- panel[store_type %in% c("convenience", "supermarket")]
ddd_data[, snap_dependent := as.integer(store_type == "convenience")]

# Triple-difference: state FE + time FE + store-type FE + treated × snap_dependent
ddd_spec <- feols(exit_rate ~ treated * snap_dependent | state + time_id + store_type,
                  data = ddd_data, cluster = ~state)
cat("  DDD (convenience vs supermarket):\n")
print(summary(ddd_spec))

saveRDS(ddd_spec, file.path(data_dir, "ddd_results.rds"))

# ----------------------------------------------------------
# 4. Aggregate SNAP stores (all types)
# ----------------------------------------------------------
cat("\n=== All SNAP Stores (Aggregate) ===\n")

cs_agg <- att_gt(
  yname = "exit_rate",
  tname = "time_id",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(agg_panel),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cs_agg_att <- aggte(cs_agg, type = "simple")
cat("  Aggregate ATT:\n")
print(summary(cs_agg_att))

saveRDS(cs_agg, file.path(data_dir, "cs_agg_results.rds"))
saveRDS(cs_agg_att, file.path(data_dir, "cs_agg_att.rds"))

# ----------------------------------------------------------
# 5. By store type
# ----------------------------------------------------------
cat("\n=== Store-Type Specific Estimates ===\n")

store_types <- c("convenience", "small_grocery", "supermarket")
type_results <- list()

for (stype in store_types) {
  cat("\n  Store type:", stype, "\n")
  sub <- panel[store_type == stype]

  cs_sub <- att_gt(
    yname = "exit_rate",
    tname = "time_id",
    idname = "state_id",
    gname = "first_treat",
    data = as.data.frame(sub),
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )

  att_sub <- aggte(cs_sub, type = "simple")
  cat("    ATT:", round(att_sub$overall.att, 3),
      " SE:", round(att_sub$overall.se, 3),
      " p:", round(2 * pnorm(-abs(att_sub$overall.att / att_sub$overall.se)), 4), "\n")

  type_results[[stype]] <- list(cs = cs_sub, att = att_sub)
}

saveRDS(type_results, file.path(data_dir, "type_results.rds"))

# ----------------------------------------------------------
# 6. Write diagnostics.json
# ----------------------------------------------------------
cat("\n=== Writing diagnostics ===\n")

# All 51 states are eventually treated (staggered); n_treated = total treated states
diagnostics <- list(
  n_treated = length(unique(conv$state)),  # All 51 states are treated
  n_pre = min(conv$first_treat) - 1,       # Pre-periods for earliest cohort
  n_obs = nrow(conv),
  n_states = length(unique(conv$state)),
  n_quarters = length(unique(conv$time_id)),
  n_retailers_total = 703441,
  n_convenience = 375809,
  outcome_sd_pre = sd(conv$exit_rate[conv$treated == 0], na.rm = TRUE),
  outcome_mean_pre = mean(conv$exit_rate[conv$treated == 0], na.rm = TRUE),
  cs_att = cs_att$overall.att,
  cs_se = cs_att$overall.se
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("  diagnostics.json written\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
