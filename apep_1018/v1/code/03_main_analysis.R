## 03_main_analysis.R — Main regressions (OLS + mechanisms)
## apep_1018: The Spotlight Effect on Safety Reporting
## Design: cell FE + quarter FE. ID: cross-sector placebo, lead test,
## inspection-visibility mechanism, injury-type gradient.

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat("Panel:", nrow(panel), "obs\n")

panel <- panel %>%
  mutate(
    cell_id = factor(cell_id),
    naics2 = factor(naics2),
    state = factor(state),
    yearqtr_f = factor(yearqtr)
  )

# --------------------------------------------------------------------------
# 1. OLS: Peer SIR → Own SIR
# --------------------------------------------------------------------------
cat("\n=== OLS: Peer SIR Effect ===\n")

# Baseline: cell FE + quarter FE, clustered at state
m1 <- feols(sir_count ~ peer_sir | cell_id + yearqtr_f,
            data = panel, cluster = ~state)

# Log-log
m2 <- feols(log_sir ~ log_peer_sir | cell_id + yearqtr_f,
            data = panel, cluster = ~state)

# Rate
panel_rate <- panel %>% filter(!is.na(sir_rate) & is.finite(sir_rate))
m3 <- feols(sir_rate ~ peer_sir | cell_id + yearqtr_f,
            data = panel_rate, cluster = ~state)

# State × quarter FE (absorbs state-level shocks)
m4 <- feols(sir_count ~ peer_sir | cell_id + state^yearqtr_f,
            data = panel, cluster = ~naics2)

cat("\nOLS Results:\n")
etable(m1, m2, m3, m4,
       headers = c("Count", "Log-Log", "Rate", "State×Qtr FE"))

# --------------------------------------------------------------------------
# 2. Mechanism: Injury Type (Amputations more newsworthy)
# --------------------------------------------------------------------------
cat("\n=== Mechanism: Injury Severity ===\n")

sir_raw <- read_csv("../data/sir_processed.csv", show_col_types = FALSE) %>%
  mutate(naics2 = as.character(naics2),
         has_insp = as.integer(!is.na(inspection) & inspection != "" &
                               inspection != "0"))

# Remove any leftover columns from previous runs
panel <- panel %>%
  select(-any_of(c("amp_count", "hosp_count", "insp_count", "uninsp_count",
                    "nat_amps", "nat_hosps", "nat_insp", "nat_uninsp",
                    "peer_amps", "peer_hosps", "peer_insp", "peer_uninsp",
                    "sector_avg_sir", "high_risk")))

# Compute peer amps and peer hosps at sector × OTHER-state level
type_panel <- sir_raw %>%
  filter(!is.na(naics2), !is.na(state),
         naics2 %in% levels(panel$naics2),
         state %in% levels(panel$state)) %>%
  group_by(naics2, state, event_year, event_quarter) %>%
  summarize(
    amp_count = sum(amputation > 0, na.rm = TRUE),
    hosp_count = sum(hospitalized > 0 & amputation == 0, na.rm = TRUE),
    insp_count = sum(has_insp),
    uninsp_count = sum(!has_insp),
    .groups = "drop"
  ) %>%
  rename(year = event_year, qtr = event_quarter)

# National sector-quarter totals
type_national <- type_panel %>%
  group_by(naics2, year, qtr) %>%
  summarize(
    nat_amps = sum(amp_count),
    nat_hosps = sum(hosp_count),
    nat_insp = sum(insp_count),
    nat_uninsp = sum(uninsp_count),
    .groups = "drop"
  )

# State-sector-quarter own counts
panel <- panel %>%
  left_join(type_panel %>% select(naics2, state, year, qtr,
                                  amp_count, hosp_count, insp_count, uninsp_count),
            by = c("naics2", "state", "year", "qtr")) %>%
  mutate(across(c(amp_count, hosp_count, insp_count, uninsp_count),
                ~replace_na(., 0))) %>%
  left_join(type_national, by = c("naics2", "year", "qtr")) %>%
  mutate(across(c(nat_amps, nat_hosps, nat_insp, nat_uninsp),
                ~replace_na(., 0))) %>%
  mutate(
    # Leave-out peer: national minus own state
    peer_amps = nat_amps - amp_count,
    peer_hosps = nat_hosps - hosp_count,
    peer_insp = nat_insp - insp_count,
    peer_uninsp = nat_uninsp - uninsp_count
  )

# Amputations (gruesome, newsworthy) vs hospitalizations (less salient)
m_type <- feols(sir_count ~ peer_amps + peer_hosps | cell_id + yearqtr_f,
                data = panel, cluster = ~state)
cat("Amputation vs hospitalization peer effect:\n")
summary(m_type)

# --------------------------------------------------------------------------
# 3. Mechanism: Inspection Visibility
# --------------------------------------------------------------------------
cat("\n=== Mechanism: Inspection Visibility ===\n")

m_insp <- feols(sir_count ~ peer_insp + peer_uninsp | cell_id + yearqtr_f,
                data = panel, cluster = ~state)
cat("Inspected vs uninspected peer events:\n")
summary(m_insp)

# --------------------------------------------------------------------------
# 4. Sector Heterogeneity
# --------------------------------------------------------------------------
cat("\n=== Sector Heterogeneity ===\n")

# Use high-risk vs low-risk sector split (median SIR rate)
sector_risk <- panel %>%
  group_by(naics2) %>%
  summarize(sector_avg_sir = mean(sir_count), .groups = "drop")

panel <- panel %>%
  left_join(sector_risk, by = "naics2") %>%
  mutate(high_risk = as.integer(sector_avg_sir > median(sector_avg_sir)))

m_het <- feols(sir_count ~ peer_sir * high_risk | cell_id + yearqtr_f,
               data = panel, cluster = ~state)
cat("High-risk vs low-risk sector interaction:\n")
summary(m_het)

# Also: split sample at high/low risk
m_highrisk <- feols(sir_count ~ peer_sir | cell_id + yearqtr_f,
                    data = panel[panel$high_risk == 1, ], cluster = ~state)
m_lowrisk <- feols(sir_count ~ peer_sir | cell_id + yearqtr_f,
                   data = panel[panel$high_risk == 0, ], cluster = ~state)

cat("\nHigh-risk sectors:\n"); summary(m_highrisk)
cat("\nLow-risk sectors:\n"); summary(m_lowrisk)

# --------------------------------------------------------------------------
# 5. Save
# --------------------------------------------------------------------------
results <- list(
  ols_baseline = m1,
  ols_log = m2,
  ols_rate = m3,
  ols_stateqtr = m4,
  mech_injury_type = m_type,
  mech_inspection = m_insp,
  het_interaction = m_het,
  het_highrisk = m_highrisk,
  het_lowrisk = m_lowrisk
)

saveRDS(results, "../data/main_results.rds")
write_csv(panel, "../data/analysis_panel.csv")

diag <- list(
  n_treated = n_distinct(panel$cell_id[panel$sir_count > 0]),
  n_pre = length(unique(panel$year[panel$year < 2020])),
  n_obs = nrow(panel),
  n_sectors = n_distinct(panel$naics2),
  n_states = n_distinct(panel$state),
  n_quarters = n_distinct(panel$yearqtr)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Analysis complete ===\n")
