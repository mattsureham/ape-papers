# ==============================================================================
# 03_main_analysis.R — Event-study DiD (quarterly) + Distributor Decomposition
# ==============================================================================

source("00_packages.R")
library(fixest)

panel <- fread("../data/analysis_panel.csv")
cat(sprintf("Panel loaded: %d rows, %d counties, %d quarters\n",
            nrow(panel), uniqueN(panel$county_id), uniqueN(panel$period)))

# =============================================================================
# Main DiD — Effect on Total Pills (Waterbed Test)
# =============================================================================

# Col 1: County FE + Period FE
m1 <- feols(log_total_pills ~ cardinal_share:post | county_id + period,
            data = panel, cluster = ~state)

# Col 2: Add state-period FE
m2 <- feols(log_total_pills ~ cardinal_share:post | county_id + state^period,
            data = panel, cluster = ~state)

# Col 3: Cardinal pills only (should decline)
m3 <- feols(log_cardinal ~ cardinal_share:post | county_id + period,
            data = panel, cluster = ~state)

# Col 4: McKesson pills (should increase — waterbed)
m4 <- feols(log_mckesson ~ cardinal_share:post | county_id + period,
            data = panel, cluster = ~state)

# Col 5: AmerisourceBergen pills
m5 <- feols(log_amerisource ~ cardinal_share:post | county_id + period,
            data = panel, cluster = ~state)

cat("\n=== Main Results: Total Pills (Waterbed Test) ===\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Total", "Total+StatePd", "Cardinal", "McKesson", "Amerisource"),
       se.below = TRUE)

# =============================================================================
# Event Study — Quarter-by-Quarter (reference = period 8 = 2007Q4)
# =============================================================================

# Use annual resolution for cleaner display (aggregate within year)
panel[, year_factor := factor(year)]

es_total <- feols(log_total_pills ~ cardinal_share:i(year_factor, ref = "2007") |
                    county_id + period,
                  data = panel, cluster = ~state)

es_cardinal <- feols(log_cardinal ~ cardinal_share:i(year_factor, ref = "2007") |
                       county_id + period,
                     data = panel, cluster = ~state)

es_mckesson <- feols(log_mckesson ~ cardinal_share:i(year_factor, ref = "2007") |
                       county_id + period,
                     data = panel, cluster = ~state)

cat("\n=== Event Study: Total Pills (annual interactions) ===\n")
etable(es_total, se.below = TRUE)

# =============================================================================
# Market Share Reallocation
# =============================================================================

m_cs <- feols(cardinal_share_t ~ cardinal_share:post | county_id + period,
              data = panel, cluster = ~state)
m_ms <- feols(mckesson_share_t ~ cardinal_share:post | county_id + period,
              data = panel, cluster = ~state)
m_as <- feols(amerisource_share_t ~ cardinal_share:post | county_id + period,
              data = panel, cluster = ~state)

cat("\n=== Market Share Reallocation ===\n")
etable(m_cs, m_ms, m_as, se.below = TRUE)

# =============================================================================
# Diagnostics
# =============================================================================

n_treated <- uniqueN(panel[cardinal_share >= 0.20]$county_id)
n_pre <- length(unique(panel[post == 0]$period))  # 8 pre-treatment quarters
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = uniqueN(panel$county_id),
  n_periods = uniqueN(panel$period),
  total_pills_billions = sum(panel$total_pills, na.rm = TRUE) / 1e9
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# Save model objects
save(m1, m2, m3, m4, m5, es_total, es_cardinal, es_mckesson,
     m_cs, m_ms, m_as, panel,
     file = "../data/model_results.RData")

cat("\nMain analysis complete.\n")
