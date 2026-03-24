# 03_main_analysis.R — Main regressions
# APEP-0869: The Litigation Tax on Biometrics

source("00_packages.R")

# ============================================================
# Load analysis panel
# ============================================================

df <- fread("../data/analysis_panel.csv")
df_border <- fread("../data/border_panel.csv")

cat(sprintf("Full panel: %d rows\n", nrow(df)))
cat(sprintf("Border panel: %d rows\n", nrow(df_border)))

# ============================================================
# Exclude "total" sector from DiD (used for descriptive only)
# ============================================================

df_did <- df[sector != "total"]
df_border_did <- df_border[sector != "total"]

# Create interaction terms
df_did[, il_exposed := illinois * exposed]
df_did[, il_post := illinois * post]
df_did[, exposed_post := exposed * post]
df_did[, triple := illinois * exposed * post]

df_border_did[, il_exposed := illinois * exposed]
df_border_did[, il_post := illinois * post]
df_border_did[, exposed_post := exposed * post]
df_border_did[, triple := illinois * exposed * post]

# ============================================================
# TABLE 1: Triple-difference — All counties in target states
# Y_{cit} = β₁(IL × Exposed × Post) + county_sector FE + quarter FE + ε
# ============================================================

cat("\n=== MAIN RESULTS: TRIPLE-DIFFERENCE ===\n\n")

# Model 1: Employment (all counties)
m1_emp_all <- feols(log_emp ~ triple + il_post + exposed_post + il_exposed |
                      county_sector + yearqtr,
                    data = df_did,
                    cluster = ~state_fips)

# Model 2: Establishments (all counties)
m1_estab_all <- feols(log_estab ~ triple + il_post + exposed_post + il_exposed |
                        county_sector + yearqtr,
                      data = df_did,
                      cluster = ~state_fips)

# Model 3: Wages (all counties)
m1_wage_all <- feols(log_wage ~ triple + il_post + exposed_post + il_exposed |
                       county_sector + yearqtr,
                     data = df_did,
                     cluster = ~state_fips)

cat("--- All counties ---\n")
cat("Employment:\n"); print(coeftable(m1_emp_all))
cat("\nEstablishments:\n"); print(coeftable(m1_estab_all))
cat("\nWages:\n"); print(coeftable(m1_wage_all))

# ============================================================
# TABLE 2: Triple-difference — Border counties only
# ============================================================

cat("\n=== BORDER COUNTY RESULTS ===\n\n")

# Model 4: Employment (border only)
m1_emp_border <- feols(log_emp ~ triple + il_post + exposed_post + il_exposed |
                         county_sector + yearqtr,
                       data = df_border_did,
                       cluster = ~state_fips)

# Model 5: Establishments (border only)
m1_estab_border <- feols(log_estab ~ triple + il_post + exposed_post + il_exposed |
                           county_sector + yearqtr,
                         data = df_border_did,
                         cluster = ~state_fips)

# Model 6: Wages (border only)
m1_wage_border <- feols(log_wage ~ triple + il_post + exposed_post + il_exposed |
                          county_sector + yearqtr,
                        data = df_border_did,
                        cluster = ~state_fips)

cat("--- Border counties ---\n")
cat("Employment:\n"); print(coeftable(m1_emp_border))
cat("\nEstablishments:\n"); print(coeftable(m1_estab_border))
cat("\nWages:\n"); print(coeftable(m1_wage_border))

# ============================================================
# TABLE 3: Event study — quarterly leads and lags
# Separate event studies for exposed vs exempt industries in IL vs control
# ============================================================

cat("\n=== EVENT STUDY ===\n\n")

# Create event time indicators
# Omit Q4 2018 (event_q = -1) as reference
df_border_did[, event_q_fac := factor(event_q)]

# Event study: triple interaction with event time dummies
# Y = Σ_k β_k × (IL × Exposed × 1{t=k}) + county_sector FE + quarter FE

# Create the interaction terms for each event period
event_times <- sort(unique(df_border_did$event_q))
# Remove reference period (event_q = -1, which is 2018Q4)
event_times_no_ref <- event_times[event_times != -1]

# Build event study formula dynamically
for (k in event_times_no_ref) {
  varname <- paste0("ev_", ifelse(k < 0, paste0("m", abs(k)), k))
  df_border_did[, (varname) := fifelse(event_q == k, 1L, 0L)]
  df_border_did[, paste0("triple_", varname) := get(varname) * illinois * exposed]
}

# Event study regression
ev_vars <- paste0("triple_ev_",
                  ifelse(event_times_no_ref < 0,
                         paste0("m", abs(event_times_no_ref)),
                         event_times_no_ref))
ev_formula <- as.formula(paste0("log_emp ~ ", paste(ev_vars, collapse = " + "),
                                " | county_sector + yearqtr"))

m_event <- feols(ev_formula, data = df_border_did, cluster = ~state_fips)
cat("Event study coefficients:\n")
print(coeftable(m_event))

# ============================================================
# Save model objects for tables script
# ============================================================

save(m1_emp_all, m1_estab_all, m1_wage_all,
     m1_emp_border, m1_estab_border, m1_wage_border,
     m_event,
     file = "../data/main_models.RData")

# ============================================================
# Write diagnostics.json for validate_v1.py
# ============================================================

n_treated_counties <- uniqueN(df_border_did[illinois == 1]$area_fips)
n_pre_periods <- length(unique(df_border_did[post == 0]$yearqtr))
n_obs <- nrow(df_border_did)

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre_periods,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_counties, n_pre_periods, n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
