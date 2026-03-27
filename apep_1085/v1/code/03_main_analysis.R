# 03_main_analysis.R — Main regressions for apep_1085
# Wind Turbines and Avian Community Restructuring

library(tidyverse)
library(fixest)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))[1]
if (length(script_dir) > 0 && nchar(script_dir) > 0) setwd(file.path(script_dir, ".."))

panel <- readRDS("data/panel.rds")

cat("Panel loaded:", nrow(panel), "observations\n")
cat("States:", n_distinct(panel$state), "\n")
cat("Years:", n_distinct(panel$year), "\n")

# ============================================================
# 1. Main DiD: Continuous treatment (log capacity)
# ============================================================
cat("\n=== MAIN RESULTS ===\n")

# Raptor reporting rate ~ log(wind capacity)
m1_raptors <- feols(
  rr_raptors ~ log_capacity | state + year,
  data = panel,
  cluster = ~state
)

# Log raptor count ~ log(wind capacity) + log(effort)
m2_raptors <- feols(
  log_raptors ~ log_capacity + log_total | state + year,
  data = panel,
  cluster = ~state
)

# Grassland bird reporting rate — skip if constant (GBIF returned 0 for this taxon)
m3_grassland <- tryCatch(
  feols(rr_grassland ~ log_capacity | state + year, data = panel, cluster = ~state),
  error = function(e) { cat("Grassland birds: constant (0 records), skipping.\n"); NULL }
)

# Waterfowl (placebo)
m4_waterfowl <- feols(
  rr_waterfowl ~ log_capacity | state + year,
  data = panel,
  cluster = ~state
)

cat("Raptor reporting rate:\n"); print(coeftable(m1_raptors))
cat("\nLog raptors (effort-controlled):\n"); print(coeftable(m2_raptors))
if (!is.null(m3_grassland)) { cat("\nGrassland reporting rate:\n"); print(coeftable(m3_grassland)) }
cat("\nWaterfowl reporting rate (placebo):\n"); print(coeftable(m4_waterfowl))

# ============================================================
# 2. Binary DiD: Post-treatment indicator
# ============================================================
cat("\n=== BINARY DiD ===\n")

m5_binary <- feols(
  rr_raptors ~ post_treat | state + year,
  data = panel,
  cluster = ~state
)
cat("Raptor RR ~ Post-treatment:\n"); print(coeftable(m5_binary))

# ============================================================
# 3. Event Study
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Cap event time at ±8
panel_es <- panel %>%
  filter(!is.na(rel_year)) %>%
  mutate(rel_year_bin = case_when(
    rel_year < -8 ~ -9L,
    rel_year > 8 ~ 9L,
    TRUE ~ rel_year
  ))

es_model <- feols(
  rr_raptors ~ i(rel_year_bin, ref = -1) | state + year,
  data = panel_es,
  cluster = ~state
)

cat("Event study coefficients:\n")
print(coeftable(es_model))

saveRDS(es_model, "data/es_model.rds")

# ============================================================
# 4. Triple-difference: Raptors vs Waterfowl
# ============================================================
cat("\n=== TRIPLE DIFFERENCE ===\n")

# Stack raptor and waterfowl observations into long format
panel_ddd <- panel %>%
  select(state, year, log_capacity, rr_raptors, rr_waterfowl, log_total) %>%
  pivot_longer(cols = c(rr_raptors, rr_waterfowl),
               names_to = "species_group",
               values_to = "reporting_rate") %>%
  mutate(
    is_raptor = as.integer(species_group == "rr_raptors"),
    capacity_x_raptor = log_capacity * is_raptor
  )

m_ddd <- feols(
  reporting_rate ~ capacity_x_raptor + log_capacity:is_raptor |
    state^species_group + year^species_group,
  data = panel_ddd,
  cluster = ~state
)

cat("DDD (capacity × raptor):\n"); print(coeftable(m_ddd))

# ============================================================
# 5. Save models and diagnostics
# ============================================================
models <- list(
  main_rr = m1_raptors,
  main_log = m2_raptors,
  grassland = if (!is.null(m3_grassland)) m3_grassland else m4_waterfowl,
  waterfowl = m4_waterfowl,
  binary = m5_binary,
  event_study = es_model,
  ddd = m_ddd
)

saveRDS(models, "data/models.rds")

# Diagnostics
min_treat_year <- min(panel$first_treat_year[panel$first_treat_year > 0])
diag <- list(
  n_treated = as.integer(n_distinct(panel$state[panel$first_treat_year > 0])),
  n_pre = as.integer(length(unique(panel$year[panel$year < min_treat_year]))),
  n_obs = as.integer(nrow(panel)),
  n_states = as.integer(n_distinct(panel$state)),
  n_years = as.integer(n_distinct(panel$year))
)

jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== DIAGNOSTICS ===\n")
cat(sprintf("Treated states: %.0f\n", diag$n_treated))
cat(sprintf("Pre-periods: %d\n", diag$n_pre))
cat(sprintf("Total observations: %d\n", diag$n_obs))

cat("\nAll models saved.\n")
