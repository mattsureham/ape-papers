## 03_main_analysis.R — Main regressions: Panic of 1907 → occupational scarring
## Method: First-difference with state-level treatment
##
## IDENTIFICATION NOTE: panic_severity is a state-level variable, so state FE
## absorb it. The estimation strategy uses:
##   (a) Cross-state comparisons with individual controls (no state FE)
##   (b) DDD: panic_severity x banking_dependent sector (with state FE)
## The DDD is the core identification: within-state, across-sector variation
## in exposure to the financial panic, absorbing all state-level confounders.

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_data.rds"))

cat("=== Analysis data loaded ===\n")
cat("Observations:", formatC(nrow(panel), big.mark = ","), "\n")

# ============================================================================
# 1. Cross-state specifications (treatment varies at state level)
# ============================================================================
cat("\n=== Cross-state specifications ===\n")

# Model 1: No controls
m1 <- feols(delta_occscore ~ panic_severity,
            data = panel, cluster = ~statefip_1900)
cat("Model 1 (bivariate):\n")
print(summary(m1))

# Model 2: With individual controls
m2 <- feols(delta_occscore ~ panic_severity + age_1900 + age_1900_sq +
              white + foreign_born + literate_1900 + married_1900 + occscore_1900,
            data = panel, cluster = ~statefip_1900)
cat("\nModel 2 (controls):\n")
print(summary(m2))

# Model 3: Factor treatment (dose-response)
m3 <- feols(delta_occscore ~ i(panic_severity, ref = 1) + age_1900 + age_1900_sq +
              white + foreign_born + literate_1900 + married_1900 + occscore_1900,
            data = panel, cluster = ~statefip_1900)
cat("\nModel 3 (factor treatment):\n")
print(summary(m3))

# Model 4: With county farm share (urbanization control)
m4 <- feols(delta_occscore ~ panic_severity + county_farm_share +
              age_1900 + age_1900_sq + white + foreign_born +
              literate_1900 + married_1900 + occscore_1900,
            data = panel, cluster = ~statefip_1900)
cat("\nModel 4 (+ county farm share):\n")
print(summary(m4))

# ============================================================================
# 2. DDD: panic_severity x banking_dependent (WITH state FE — core ID)
# ============================================================================
cat("\n=== DDD: Panic severity x Banking-dependent sector (STATE FE) ===\n")
cat("This is the core identification strategy.\n")
cat("State FE absorb all state-level confounders.\n")
cat("The interaction exploits within-state, across-sector variation.\n\n")

# Model 5: DDD with state FE (MAIN SPECIFICATION)
m5_ddd <- feols(delta_occscore ~ panic_severity * banking_dependent +
                  age_1900 + age_1900_sq + white + foreign_born +
                  literate_1900 + married_1900 + occscore_1900 |
                  statefip_1900,
                data = panel, cluster = ~statefip_1900)
cat("DDD model (ordinal):\n")
print(summary(m5_ddd))

# Model 5b: Factor treatment DDD
m5b_ddd <- feols(delta_occscore ~ i(panic_severity, ref = 1) * banking_dependent +
                   age_1900 + age_1900_sq + white + foreign_born +
                   literate_1900 + married_1900 + occscore_1900 |
                   statefip_1900,
                 data = panel, cluster = ~statefip_1900)
cat("\nDDD model (factor):\n")
print(summary(m5b_ddd))

# Model 5c: County FE version (absorbs county-level confounders)
m5c_county <- feols(delta_occscore ~ panic_severity * banking_dependent +
                      age_1900 + age_1900_sq + white + foreign_born +
                      literate_1900 + married_1900 + occscore_1900 |
                      statefip_1900 + county_1900,
                    data = panel, cluster = ~statefip_1900)
cat("\nDDD with county FE:\n")
print(summary(m5c_county))

# ============================================================================
# 3. Heterogeneity by age group
# ============================================================================
cat("\n=== Heterogeneity by age ===\n")

# Young workers: DDD
m6_young <- feols(delta_occscore ~ panic_severity * banking_dependent +
                    age_1900 + age_1900_sq + white + foreign_born +
                    literate_1900 + married_1900 + occscore_1900 |
                    statefip_1900,
                  data = panel[age_group == "Young (18-30)"],
                  cluster = ~statefip_1900)
cat("Young (18-30) DDD:\n")
print(summary(m6_young))

# Older workers: DDD
m6_old <- feols(delta_occscore ~ panic_severity * banking_dependent +
                  age_1900 + age_1900_sq + white + foreign_born +
                  literate_1900 + married_1900 + occscore_1900 |
                  statefip_1900,
                data = panel[age_group == "Old (31-50)"],
                cluster = ~statefip_1900)
cat("\nOld (31-50) DDD:\n")
print(summary(m6_old))

# Cross-state by age
m6_young_xs <- feols(delta_occscore ~ panic_severity +
                       age_1900 + age_1900_sq + white + foreign_born +
                       literate_1900 + married_1900 + occscore_1900,
                     data = panel[age_group == "Young (18-30)"],
                     cluster = ~statefip_1900)

m6_old_xs <- feols(delta_occscore ~ panic_severity +
                     age_1900 + age_1900_sq + white + foreign_born +
                     literate_1900 + married_1900 + occscore_1900,
                   data = panel[age_group == "Old (31-50)"],
                   cluster = ~statefip_1900)

# ============================================================================
# 4. Mechanism: Home ownership loss
# ============================================================================
cat("\n=== Mechanism: Home ownership loss ===\n")

# Cross-state
m7_own_xs <- feols(delta_ownership ~ panic_severity +
                     age_1900 + age_1900_sq + white + foreign_born +
                     literate_1900 + married_1900 + occscore_1900,
                   data = panel, cluster = ~statefip_1900)
cat("Ownership change (cross-state):\n")
print(summary(m7_own_xs))

# DDD with state FE
m7_own_ddd <- feols(delta_ownership ~ panic_severity * banking_dependent +
                      age_1900 + age_1900_sq + white + foreign_born +
                      literate_1900 + married_1900 + occscore_1900 |
                      statefip_1900,
                    data = panel, cluster = ~statefip_1900)
cat("\nOwnership DDD:\n")
print(summary(m7_own_ddd))

# ============================================================================
# 5. Falsification: Agricultural workers (should show smaller effects)
# ============================================================================
cat("\n=== Falsification: Agricultural vs Non-agricultural workers ===\n")

m8_ag <- feols(delta_occscore ~ panic_severity +
                 age_1900 + age_1900_sq + white + foreign_born +
                 literate_1900 + married_1900 + occscore_1900,
               data = panel[sector == "Agriculture"],
               cluster = ~statefip_1900)
cat("Agriculture only (cross-state):\n")
print(summary(m8_ag))

m8_nonag <- feols(delta_occscore ~ panic_severity +
                    age_1900 + age_1900_sq + white + foreign_born +
                    literate_1900 + married_1900 + occscore_1900,
                  data = panel[sector != "Agriculture"],
                  cluster = ~statefip_1900)
cat("\nNon-agriculture (cross-state):\n")
print(summary(m8_nonag))

# Banking-dependent only (strongest expected effect)
m8_bank <- feols(delta_occscore ~ panic_severity +
                   age_1900 + age_1900_sq + white + foreign_born +
                   literate_1900 + married_1900 + occscore_1900,
                 data = panel[banking_dependent == TRUE],
                 cluster = ~statefip_1900)
cat("\nBanking-dependent only (cross-state):\n")
print(summary(m8_bank))

# ============================================================================
# 6. Save all results
# ============================================================================
cat("\n=== Saving results ===\n")

results <- list(
  # Cross-state
  m1_bivariate = m1,
  m2_controls = m2,
  m3_factor = m3,
  m4_urban = m4,
  # DDD (core identification)
  m5_ddd = m5_ddd,
  m5b_ddd_factor = m5b_ddd,
  m5c_county_ddd = m5c_county,
  # Heterogeneity
  m6_young_ddd = m6_young,
  m6_old_ddd = m6_old,
  m6_young_xs = m6_young_xs,
  m6_old_xs = m6_old_xs,
  # Mechanisms
  m7_ownership_xs = m7_own_xs,
  m7_ownership_ddd = m7_own_ddd,
  # Falsification
  m8_agriculture = m8_ag,
  m8_nonag = m8_nonag,
  m8_banking = m8_bank
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================================
# 7. Diagnostics JSON
# ============================================================================
n_treated_states <- length(unique(panel[panic_severity >= 2, statefip_1900]))
n_core_states <- length(unique(panel[panic_severity == 3, statefip_1900]))

# Get DDD interaction coefficient (the key result)
ddd_coef_name <- "panic_severity:banking_dependentTRUE"
ddd_b <- coef(m5_ddd)[ddd_coef_name]
ddd_se <- se(m5_ddd)[ddd_coef_name]
ddd_pval <- pvalue(m5_ddd)[ddd_coef_name]

# Cross-state main coefficient
xs_b <- coef(m2)["panic_severity"]
xs_se <- se(m2)["panic_severity"]
xs_pval <- pvalue(m2)["panic_severity"]

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = 7L,  # 1900-1907 pre-period
  n_obs = nrow(panel),
  n_states = length(unique(panel$statefip_1900)),
  n_core_states = n_core_states,
  n_moderate_states = length(unique(panel[panic_severity == 2, statefip_1900])),
  # Cross-state main result
  xs_coef = xs_b,
  xs_se = xs_se,
  xs_pval = xs_pval,
  # DDD interaction (core identification)
  ddd_interaction = ddd_b,
  ddd_interaction_se = ddd_se,
  ddd_interaction_pval = ddd_pval,
  # Falsification
  ag_coef = coef(m8_ag)["panic_severity"],
  ag_se = se(m8_ag)["panic_severity"],
  nonag_coef = coef(m8_nonag)["panic_severity"],
  nonag_se = se(m8_nonag)["panic_severity"],
  # Ownership mechanism
  own_xs_coef = coef(m7_own_xs)["panic_severity"],
  own_xs_se = se(m7_own_xs)["panic_severity"]
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Key Results Summary ===\n")
cat("Cross-state (panic_severity):", round(xs_b, 4),
    "(SE:", round(xs_se, 4), ", p=", round(xs_pval, 4), ")\n")
cat("DDD interaction (panic x banking_dep):", round(ddd_b, 4),
    "(SE:", round(ddd_se, 4), ", p=", round(ddd_pval, 6), ")\n")
cat("Agriculture (falsification):", round(coef(m8_ag)["panic_severity"], 4),
    "(SE:", round(se(m8_ag)["panic_severity"], 4), ")\n")
cat("Non-agriculture:", round(coef(m8_nonag)["panic_severity"], 4),
    "(SE:", round(se(m8_nonag)["panic_severity"], 4), ")\n")
cat("Banking-dependent:", round(coef(m8_bank)["panic_severity"], 4),
    "(SE:", round(se(m8_bank)["panic_severity"], 4), ")\n")
cat("Ownership (cross-state):", round(coef(m7_own_xs)["panic_severity"], 5),
    "(SE:", round(se(m7_own_xs)["panic_severity"], 5), ")\n")
cat("\nDiagnostics saved.\n")
