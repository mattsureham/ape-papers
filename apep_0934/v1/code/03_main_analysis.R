# 03_main_analysis.R — Main analysis for apep_0934
# Effect of community wind ownership on property values and green voting
source("00_packages.R")

data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
election <- readRDS(file.path(data_dir, "election_panel.rds"))
muni_treat <- readRDS(file.path(data_dir, "muni_treatment.rds"))

# ============================================================================
# DESIGN: Staggered DiD using continuous treatment intensity
# ============================================================================
# Treatment: new onshore wind capacity (MW) installed in municipality during
# 2017-2020, under Denmark's køberetsordning (purchase-right scheme)
#
# Using ALL municipalities as the sample:
# - 49 "newly treated" (received new wind 2017-2020)
# - 35 "always treated" (had wind pre-2016, no new installs → control group)
# - 14 "never treated" (no wind at all → control group)
# - 1 "post-policy" (excluded — too few)
#
# Control group (49 munis) = always_treated + never_treated
# This is preferable because always_treated munis share wind-suitable geography

# Drop post-policy municipality (only 1)
panel <- panel %>% filter(treatment_group != "post_policy")

# Create analysis variables
panel <- panel %>%
  mutate(
    treated = ifelse(treatment_group == "newly_treated", 1L, 0L),
    # For CS-DiD: cohort year (0 = never treated)
    g = ifelse(treatment_group == "newly_treated" & !is.na(first_new_install),
               first_new_install, 0L),
    muni_id = as.integer(factor(municipality_no))
  )

cat("=== Sample Summary ===\n")
cat(sprintf("  Total obs: %d\n", nrow(panel)))
cat(sprintf("  Municipalities: %d (treated: %d, control: %d)\n",
            n_distinct(panel$municipality_no),
            sum(panel$treated == 1 & panel$year == 2020),
            sum(panel$treated == 0 & panel$year == 2020)))
cat(sprintf("  Years: %d - %d\n", min(panel$year), max(panel$year)))

# Pre-treatment balance check
cat("\n=== Pre-treatment Balance (2016) ===\n")
balance <- panel %>%
  filter(year == 2016) %>%
  group_by(treated) %>%
  summarize(
    n = n(),
    avg_prop_value = mean(avg_property_value, na.rm = TRUE),
    avg_pop = mean(population, na.rm = TRUE),
    avg_income = mean(avg_income, na.rm = TRUE),
    avg_wind_mw = mean(onshore_wind_mw, na.rm = TRUE),
    .groups = "drop"
  )
print(balance)

# ============================================================================
# SPECIFICATION 1: TWFE — Binary treatment
# ============================================================================
cat("\n=== TWFE: Binary Treatment on Log Property Values ===\n")

# Need to restrict to years where we have wind data (2016+) for post_treatment
# But property data goes back to 2004, giving us pre-trends

twfe_binary <- feols(log_property ~ post_treatment |
                       municipality_no + year,
                     data = panel,
                     cluster = ~municipality_no)

cat("TWFE (binary treatment):\n")
summary(twfe_binary)

# ============================================================================
# SPECIFICATION 2: TWFE — Continuous treatment intensity
# ============================================================================
cat("\n=== TWFE: Continuous Treatment (new MW installed) ===\n")

twfe_continuous <- feols(log_property ~ treatment_intensity |
                           municipality_no + year,
                         data = panel,
                         cluster = ~municipality_no)

cat("TWFE (continuous treatment):\n")
summary(twfe_continuous)

# ============================================================================
# SPECIFICATION 3: Callaway-Sant'Anna (2021)
# ============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for did package
cs_data <- panel %>%
  filter(!is.na(log_property)) %>%
  mutate(
    id = muni_id,
    period = year,
    G = g  # 0 = never treated
  ) %>%
  as.data.frame()

# CS-DiD with never-treated + already-treated as comparison
cs_result <- att_gt(
  yname = "log_property",
  tname = "period",
  idname = "id",
  gname = "G",
  data = cs_data,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "reg",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("CS-DiD group-time ATTs:\n")
summary(cs_result)

# Aggregate to overall ATT
cs_agg <- aggte(cs_result, type = "simple")
cat("\nCS-DiD overall ATT:\n")
summary(cs_agg)

# Dynamic effects (event study)
cs_dynamic <- aggte(cs_result, type = "dynamic", min_e = -6, max_e = 6)
cat("\nCS-DiD dynamic effects:\n")
summary(cs_dynamic)

# ============================================================================
# SPECIFICATION 4: Event study (fixest sunab)
# ============================================================================
cat("\n=== Event study (Sun-Abraham via fixest) ===\n")

# Sun-Abraham event study
panel_es <- panel %>%
  mutate(
    # For sunab: treatment cohort (Inf = never treated)
    cohort_sa = ifelse(g == 0, Inf, g),
    # Relative time
    rel_time = year - ifelse(g > 0, g, NA_integer_)
  )

es_sa <- feols(log_property ~ sunab(cohort_sa, year) |
                 municipality_no + year,
               data = panel_es,
               cluster = ~municipality_no)

cat("Sun-Abraham event study:\n")
summary(es_sa)

# ============================================================================
# SPECIFICATION 5: Election outcomes — Green vote share
# ============================================================================
cat("\n=== Election outcomes ===\n")

# Merge election data with treatment (excluding post_policy)
elec_panel <- election %>%
  filter(!is.na(treatment_group), treatment_group != "post_policy") %>%
  mutate(
    treated = ifelse(treatment_group == "newly_treated", 1L, 0L),
    g = ifelse(treatment_group == "newly_treated" & !is.na(first_new_install),
               first_new_install, 0L)
  )

cat(sprintf("  Election obs: %d (%d munis × %d elections)\n",
            nrow(elec_panel), n_distinct(elec_panel$municipality_no),
            n_distinct(elec_panel$year)))

# TWFE on green vote share
elec_twfe <- feols(green_share ~ post_treatment |
                     municipality_no + year,
                   data = elec_panel,
                   cluster = ~municipality_no)

cat("TWFE on green vote share:\n")
summary(elec_twfe)

# ============================================================================
# SAVE RESULTS
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  twfe_binary = twfe_binary,
  twfe_continuous = twfe_continuous,
  cs_result = cs_result,
  cs_agg = cs_agg,
  cs_dynamic = cs_dynamic,
  es_sa = es_sa,
  elec_twfe = elec_twfe,
  balance = balance
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validation
diagnostics <- list(
  n_treated = sum(panel$treated == 1 & panel$year == 2020),
  n_pre = length(unique(panel$year[panel$year < 2017])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat(sprintf("  diagnostics.json: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("\n=== Main analysis complete ===\n")
