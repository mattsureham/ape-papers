# 03_main_analysis.R — Main regressions for NFA reform analysis
# apep_0813/v1

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- readRDS("data/panel_clean.rds")
cat("=== Main Analysis: NFA Reform and Inter-cantonal Migration ===\n\n")

# -------------------------------------------------------------------
# 1. Continuous treatment intensity DiD
# -------------------------------------------------------------------
# Y_{ct} = α_c + α_t + β × (NFA_intensity_c × Post_t) + ε_{ct}
# NFA_intensity = (100 - Ressourcenindex_2008) / 100
# Positive intensity = resource-weak canton (receives transfers)
# β > 0 → NFA equalization increased net migration to recipient cantons

cat("--- Model 1: Continuous intensity DiD ---\n")

# Main spec: net migration rate
m1_net <- feols(net_migration_rate ~ intensity_post | canton_id + year,
                data = panel, cluster = ~canton_id)

# In-migration rate
m1_in <- feols(in_migration_rate ~ intensity_post | canton_id + year,
               data = panel, cluster = ~canton_id)

# Out-migration rate
m1_out <- feols(out_migration_rate ~ intensity_post | canton_id + year,
                data = panel, cluster = ~canton_id)

# Population growth
m1_pop <- feols(pop_growth ~ intensity_post | canton_id + year,
                data = panel[!is.na(pop_growth)], cluster = ~canton_id)

cat("Net migration rate:\n")
print(summary(m1_net))
cat("\nIn-migration rate:\n")
print(summary(m1_in))
cat("\nOut-migration rate:\n")
print(summary(m1_out))
cat("\nPopulation growth:\n")
print(summary(m1_pop))

# -------------------------------------------------------------------
# 2. Event study (continuous intensity)
# -------------------------------------------------------------------
cat("\n--- Model 2: Event study ---\n")

# Create event-time interaction terms
# Drop year 2007 (event_time = -1) as reference
panel[, et_factor := factor(event_time)]

m2_net <- feols(net_migration_rate ~ i(event_time, nfa_intensity, ref = -1) |
                  canton_id + year,
                data = panel, cluster = ~canton_id)

cat("Event study (net migration rate × NFA intensity):\n")
print(summary(m2_net))

# Save event study coefficients for table
es_coefs <- data.table(
  event_time = as.integer(names(coef(m2_net))),
  coef = coef(m2_net),
  se = sqrt(diag(vcov(m2_net)))
)
# Extract event_time from coefficient names properly
es_names <- names(coef(m2_net))
es_coefs <- data.table(
  name = es_names,
  coef = as.numeric(coef(m2_net)),
  se = as.numeric(sqrt(diag(vcov(m2_net))))
)
# Parse event time from names like "event_time::-7:nfa_intensity"
es_coefs[, event_time := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", name))]
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]
setorder(es_coefs, event_time)

cat("\nEvent study coefficients:\n")
print(es_coefs[, .(event_time, coef = round(coef, 3), se = round(se, 3),
                    ci_lo = round(ci_lo, 3), ci_hi = round(ci_hi, 3))])

# Pre-trend test: joint significance of pre-period coefficients
pre_coefs <- es_coefs[event_time < -1]
if (nrow(pre_coefs) > 0) {
  # F-test for joint significance of pre-period effects
  pre_terms <- paste0("event_time::", pre_coefs$event_time, ":nfa_intensity")
  pre_test <- tryCatch({
    wald(m2_net, keep = "event_time::-[2-9]|event_time::-[0-9]{2}")
  }, error = function(e) {
    cat("Wald test error (non-fatal):", e$message, "\n")
    NULL
  })
  if (!is.null(pre_test)) {
    cat("\nPre-trend Wald test (H0: all pre-period coefficients = 0):\n")
    print(pre_test)
  }
}

saveRDS(es_coefs, "data/event_study_coefs.rds")

# -------------------------------------------------------------------
# 3. Binary treatment DiD (robustness)
# -------------------------------------------------------------------
cat("\n--- Model 3: Binary treatment DiD ---\n")

# Exclude near-zero cantons for cleaner comparison
panel_binary <- panel[nfa_group != "near_zero"]
panel_binary[, recipient_post := recipient * post]

m3_net <- feols(net_migration_rate ~ recipient_post | canton_id + year,
                data = panel_binary, cluster = ~canton_id)

m3_in <- feols(in_migration_rate ~ recipient_post | canton_id + year,
               data = panel_binary, cluster = ~canton_id)

cat("Binary DiD (recipient vs payer, excluding near-zero):\n")
cat("Net migration rate:\n")
print(summary(m3_net))
cat("\nIn-migration rate:\n")
print(summary(m3_in))

# -------------------------------------------------------------------
# 4. Wild cluster bootstrap (26 cantons → use WCB for inference)
# -------------------------------------------------------------------
cat("\n--- Model 4: Wild cluster bootstrap ---\n")

# Boot main specification
boot_net <- tryCatch({
  boottest(m1_net, param = "intensity_post", clustid = "canton_id",
           B = 9999, type = "rademacher")
}, error = function(e) {
  cat("WCB error:", e$message, "\n")
  NULL
})

if (!is.null(boot_net)) {
  cat("Wild cluster bootstrap for intensity_post (net migration):\n")
  cat(sprintf("  Point estimate: %.3f\n", coef(m1_net)["intensity_post"]))
  cat(sprintf("  WCB p-value: %.4f\n", boot_net$p_val))
  cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n",
              boot_net$conf_int[1], boot_net$conf_int[2]))
}

boot_pop <- tryCatch({
  boottest(m1_pop, param = "intensity_post", clustid = "canton_id",
           B = 9999, type = "rademacher")
}, error = function(e) {
  cat("WCB error for pop growth:", e$message, "\n")
  NULL
})

if (!is.null(boot_pop)) {
  cat("\nWild cluster bootstrap for intensity_post (pop growth):\n")
  cat(sprintf("  Point estimate: %.3f\n", coef(m1_pop)["intensity_post"]))
  cat(sprintf("  WCB p-value: %.4f\n", boot_pop$p_val))
  cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n",
              boot_pop$conf_int[1], boot_pop$conf_int[2]))
}

# -------------------------------------------------------------------
# 5. Save results for diagnostics
# -------------------------------------------------------------------
cat("\n--- Saving diagnostics ---\n")

# diagnostics.json for validate_v1.py
# In a continuous treatment DiD, all cantons receive treatment (varying intensity).
# Count all cantons with non-zero NFA intensity as "treated units".
n_treated <- uniqueN(panel[abs(nfa_intensity) > 0.005, canton_id])
n_pre <- uniqueN(panel[year < 2008, year])
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_cantons = uniqueN(panel$canton_id),
  n_years = uniqueN(panel$year),
  main_coef = round(coef(m1_net)["intensity_post"], 4),
  main_se = round(sqrt(diag(vcov(m1_net)))["intensity_post"], 4)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Saved data/diagnostics.json\n")

# Save model objects
saveRDS(list(
  m1_net = m1_net, m1_in = m1_in, m1_out = m1_out, m1_pop = m1_pop,
  m2_net = m2_net,
  m3_net = m3_net, m3_in = m3_in,
  boot_net = boot_net, boot_pop = boot_pop
), "data/models.rds")

cat("\n=== Main analysis complete ===\n")
