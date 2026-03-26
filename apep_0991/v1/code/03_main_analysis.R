## 03_main_analysis.R — Main econometric analysis
## APEP-0991: EU Landing Obligation

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
cat("=== Main Analysis: EU Landing Obligation ===\n")
cat(sprintf("Panel: %d obs, %d units, years %d-%d\n",
            nrow(panel), n_distinct(panel$unit_id),
            min(panel$year), max(panel$year)))

# ======================================================================
# 1. TWFE baseline (for comparison)
# ======================================================================
cat("\n--- 1. TWFE Baseline ---\n")

# Create post indicator
panel <- panel %>%
  mutate(
    post = as.integer(is_eu & year >= treat_year),
    rel_year = if_else(is_eu, year - treat_year, NA_real_)
  )

# TWFE with country x species-group FE + year FE
twfe_catch <- feols(
  log_catch ~ post | unit_num + year,
  data = panel,
  cluster = ~country
)
cat("TWFE — log catches:\n")
summary(twfe_catch)

# ======================================================================
# 2. Callaway-Sant'Anna (2021) — staggered DiD
# ======================================================================
cat("\n--- 2. Callaway-Sant'Anna ---\n")

# Prepare data: CS-DiD needs balanced panel or at least consistent id/time
cs_data <- panel %>%
  select(unit_num, year, log_catch, first_treat, country, treatment_group,
         total_catch, landing_ratio) %>%
  # Ensure no duplicates

  distinct(unit_num, year, .keep_all = TRUE)

# Check data structure
cat(sprintf("CS data: %d obs, %d units, first_treat values: %s\n",
            nrow(cs_data), n_distinct(cs_data$unit_num),
            paste(sort(unique(cs_data$first_treat)), collapse = ", ")))

# Main CS-DiD: log catches
cs_catch <- att_gt(
  yname = "log_catch",
  tname = "year",
  idname = "unit_num",
  gname = "first_treat",
  data = cs_data,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)

cat("\nCS-DiD group-time ATTs (log catches):\n")
summary(cs_catch)

# Aggregate: overall ATT
cs_overall <- aggte(cs_catch, type = "simple")
cat("\nOverall ATT (log catches):\n")
summary(cs_overall)

# Event study aggregation
cs_es <- aggte(cs_catch, type = "dynamic", min_e = -10, max_e = 8)
cat("\nEvent study (log catches):\n")
summary(cs_es)

# ======================================================================
# 3. Landing ratio analysis
# ======================================================================
cat("\n--- 3. Landing Ratio Analysis ---\n")

# Check landing ratio availability
cat(sprintf("Landing ratio: %d non-NA obs out of %d\n",
            sum(!is.na(panel$landing_ratio)), nrow(panel)))

panel_lr <- panel %>% filter(!is.na(landing_ratio))

if (nrow(panel_lr) > 100) {
  twfe_lr <- feols(
    landing_ratio ~ post | unit_num + year,
    data = panel_lr,
    cluster = ~country
  )
  cat("TWFE — landing ratio:\n")
  summary(twfe_lr)
} else {
  cat("Insufficient landing ratio data. Skipping.\n")
  twfe_lr <- NULL
}

# ======================================================================
# 4. Heterogeneity: Pelagic vs Demersal
# ======================================================================
cat("\n--- 4. Heterogeneity by Species Group ---\n")

# Demersal species have the "choke problem" — mixed fisheries mean
# bycatch quotas bind before target species quotas
twfe_pelagic <- feols(
  log_catch ~ post | unit_num + year,
  data = panel %>% filter(treatment_group == "pelagic"),
  cluster = ~country
)

twfe_demersal <- feols(
  log_catch ~ post | unit_num + year,
  data = panel %>% filter(treatment_group == "demersal"),
  cluster = ~country
)

twfe_other <- feols(
  log_catch ~ post | unit_num + year,
  data = panel %>% filter(treatment_group == "other"),
  cluster = ~country
)

cat("Pelagic (treated 2015):\n")
summary(twfe_pelagic)
cat("Demersal (treated 2016) — choke-species group:\n")
summary(twfe_demersal)
cat("Other (treated 2019):\n")
summary(twfe_other)

# ======================================================================
# 5. Non-EU placebo (Norway + Iceland)
# ======================================================================
cat("\n--- 5. Non-EU Placebo ---\n")

# Create pseudo-treatment for non-EU: assign them the same timing
# as EU countries but they should show no effect
placebo_data <- panel %>%
  filter(!is_eu) %>%
  mutate(
    # Assign pseudo treatment year matching the species-group timing
    pseudo_post = as.integer(year >= treat_year)
  )

if (nrow(placebo_data) > 20) {
  placebo_reg <- feols(
    log_catch ~ pseudo_post | unit_num + year,
    data = placebo_data,
    cluster = ~country
  )
  cat("Placebo — non-EU countries (Norway, Iceland):\n")
  summary(placebo_reg)
} else {
  cat("Insufficient non-EU data for placebo test.\n")
  placebo_reg <- NULL
}

# ======================================================================
# 6. TWFE with country x year FE (absorbs country-level shocks)
# ======================================================================
cat("\n--- 6. Saturated FE Specification ---\n")

# Country x year FE absorbs all country-level time-varying confounders
# Identification comes purely from within-country across-species-group variation
twfe_sat <- feols(
  log_catch ~ post | unit_num + country^year,
  data = panel %>% filter(is_eu),  # EU-only for country x year FE
  cluster = ~country
)
cat("Saturated FE (country x year) — EU only:\n")
summary(twfe_sat)

# ======================================================================
# 7. Save results
# ======================================================================
cat("\n=== Saving results ===\n")

results <- list(
  twfe_catch = twfe_catch,
  cs_catch = cs_catch,
  cs_overall = cs_overall,
  cs_es = cs_es,
  twfe_lr = twfe_lr,
  twfe_pelagic = twfe_pelagic,
  twfe_demersal = twfe_demersal,
  twfe_other = twfe_other,
  placebo_reg = placebo_reg,
  twfe_sat = twfe_sat
)
saveRDS(results, "../data/results.rds")

# ======================================================================
# 8. Diagnostics for validation
# ======================================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(panel$unit_num[panel$is_eu]),
  n_pre = length(unique(panel$year[panel$year < 2015])),
  n_obs = nrow(panel),
  n_clusters = n_distinct(panel$country),
  att_overall = cs_overall$overall.att,
  att_se = cs_overall$overall.se,
  twfe_coef = coef(twfe_catch)["post"],
  twfe_se = se(twfe_catch)["post"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("Diagnostics:\n")
cat(sprintf("  Treated units: %d\n", diagnostics$n_treated))
cat(sprintf("  Pre-periods: %d\n", diagnostics$n_pre))
cat(sprintf("  Total obs: %d\n", diagnostics$n_obs))
cat(sprintf("  CS-DiD overall ATT: %.4f (SE: %.4f)\n",
            diagnostics$att_overall, diagnostics$att_se))
cat(sprintf("  TWFE coefficient: %.4f (SE: %.4f)\n",
            diagnostics$twfe_coef, diagnostics$twfe_se))

cat("\n=== Main analysis complete ===\n")
