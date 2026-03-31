# 03_main_analysis.R — Triple-difference estimation
# Asian × Customer-Facing × Asian Population Share (pre-determined)

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")

cat("=== MAIN ANALYSIS: Triple-Difference (DDD) ===\n\n")

# ────────────────────────────────────────────────────────────
# Main DDD specification:
# Y_{s,r,j,t} = β (Asian_r × CF_j × PostCOVID_t × AsianShare_s) + FEs + ε
# FEs: state×quarter, race×sector, state×sector, race×quarter
# Clustering: state level (51 clusters)
#
# The triple-difference absorbs:
# - State-quarter shocks (state×quarter FE)
# - Race-specific sector patterns (race×sector FE)
# - State-specific sector trends (state×sector FE)
# - National race-specific time trends (race×quarter FE)
# ────────────────────────────────────────────────────────────

# ── Table 2: Main DDD Results ──

# Model 1: Binary DDD (Asian × CF × Post-COVID)
m1 <- feols(log_emp ~ asian:customer_facing:post_covid |
              state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
            data = panel, cluster = ~state_fips)

# Model 2: Continuous DDD with Asian population share
# Asian × CF × Post-COVID × Asian Share (standardized)
m2 <- feols(log_emp ~ asian:customer_facing:post_covid:asian_share_std |
              state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
            data = panel, cluster = ~state_fips)

# Model 3: Hires — continuous DDD
m3 <- feols(log_hires ~ asian:customer_facing:post_covid:asian_share_std |
              state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
            data = panel, cluster = ~state_fips)

# Model 4: Separations — continuous DDD
m4 <- feols(log_sep ~ asian:customer_facing:post_covid:asian_share_std |
              state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
            data = panel, cluster = ~state_fips)

# Model 5: Earnings — continuous DDD
m5 <- feols(log_earn ~ asian:customer_facing:post_covid:asian_share_std |
              state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
            data = panel, cluster = ~state_fips)

cat("\n── Model 1: Binary DDD ──\n")
print(summary(m1))
cat("\n── Model 2: Continuous DDD (Employment) ──\n")
print(summary(m2))
cat("\n── Model 3: Continuous DDD (Hires) ──\n")
print(summary(m3))
cat("\n── Model 4: Continuous DDD (Separations) ──\n")
print(summary(m4))
cat("\n── Model 5: Continuous DDD (Earnings) ──\n")
print(summary(m5))

# ── Table 3: Event Study ──
# Quarterly DDD coefficients: Asian × CF × event_time dummies
# Reference: 2019Q4 (event_time = -1)

# Create interaction variable for event study
panel[, asian_cf := asian * customer_facing]

es_model <- feols(log_emp ~ i(event_time, asian_cf, ref = -1) |
                    state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                  data = panel, cluster = ~state_fips)

cat("\n── Event Study ──\n")
print(summary(es_model))

# Extract coefficients
es_coefs <- as.data.table(coeftable(es_model), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
es_coefs <- es_coefs[grepl("event_time", term)]
es_coefs[, event_time := as.numeric(gsub(".*::", "", gsub(":.*$", "",
                                          gsub("event_time::", "", term))))]

cat("\n── Event Study Coefficients ──\n")
print(es_coefs[order(event_time), .(event_time, estimate, se, pval)])

# ── Table 4: Reallocation to Knowledge Sectors ──
panel[, knowledge := as.integer(sector_type == "knowledge")]

m_realloc <- feols(log_emp ~ asian:knowledge:post_covid |
                     state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                   data = panel, cluster = ~state_fips)

m_realloc_cont <- feols(log_emp ~ asian:knowledge:post_covid:asian_share_std |
                           state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                         data = panel, cluster = ~state_fips)

cat("\n── Reallocation: Knowledge sectors ──\n")
cat("Binary:\n"); print(summary(m_realloc))
cat("Continuous:\n"); print(summary(m_realloc_cont))

# ── Save results ──
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_model = es_model,
  m_realloc = m_realloc, m_realloc_cont = m_realloc_cont,
  es_coefs = es_coefs
)
saveRDS(results, "../data/main_results.rds")

# ── Diagnostics ──
n_treated <- uniqueN(panel[asian == 1 & customer_facing == 1 & post_covid == 1, state_fips])
n_pre <- uniqueN(panel[yrqtr < 2020, yrqtr])
n_obs <- nrow(panel)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_states = uniqueN(panel$state_fips),
  n_quarters = uniqueN(panel$yrqtr)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
