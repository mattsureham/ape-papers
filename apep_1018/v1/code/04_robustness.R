## 04_robustness.R — Robustness checks and placebos
## apep_1018: The Spotlight Effect on Safety Reporting

source("00_packages.R")

cat("=== Loading data ===\n")
panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)

panel <- panel %>%
  mutate(cell_id = factor(cell_id), yearqtr_f = factor(yearqtr),
         state = factor(state), naics2 = factor(naics2))

# --------------------------------------------------------------------------
# 1. Cross-Sector Placebo (KEY identification test)
# --------------------------------------------------------------------------
cat("\n=== Cross-Sector Placebo ===\n")

# If reporting contagion is sector-specific, cross-sector peer SIR
# (same state, different sector) should have a weaker or null effect

panel <- panel %>%
  select(-any_of(c("total_state_sir", "cross_sector_peer",
                    "peer_sir_lead1", "peer_sir_lag1", "peer_sir_lag2")))

cross_sector <- panel %>%
  group_by(state, year, qtr) %>%
  summarize(total_state_sir = sum(sir_count), .groups = "drop")

panel <- panel %>%
  left_join(cross_sector, by = c("state", "year", "qtr")) %>%
  mutate(cross_sector_peer = total_state_sir - sir_count)

m_placebo <- feols(sir_count ~ cross_sector_peer | cell_id + yearqtr_f,
                   data = panel, cluster = ~state)
cat("Cross-sector placebo:\n")
summary(m_placebo)

# Horse race
m_horse <- feols(sir_count ~ peer_sir + cross_sector_peer |
                 cell_id + yearqtr_f, data = panel, cluster = ~state)
cat("\nHorse race:\n")
summary(m_horse)

# --------------------------------------------------------------------------
# 2. Lead Placebo (future SIR shouldn't predict current)
# --------------------------------------------------------------------------
cat("\n=== Lead Placebo ===\n")

panel <- panel %>%
  arrange(cell_id, year, qtr) %>%
  group_by(cell_id) %>%
  mutate(
    peer_sir_lead1 = dplyr::lead(peer_sir, 1),
    peer_sir_lag1 = dplyr::lag(peer_sir, 1),
    peer_sir_lag2 = dplyr::lag(peer_sir, 2)
  ) %>%
  ungroup()

m_lead <- feols(sir_count ~ peer_sir_lead1 | cell_id + yearqtr_f,
                data = panel, cluster = ~state)
cat("Lead placebo (future → current):\n")
summary(m_lead)

# Lag structure
m_lags <- feols(sir_count ~ peer_sir + peer_sir_lag1 + peer_sir_lag2 |
                cell_id + yearqtr_f, data = panel, cluster = ~state)
cat("\nLag structure:\n")
summary(m_lags)

# --------------------------------------------------------------------------
# 3. Exclude COVID (2020-2021)
# --------------------------------------------------------------------------
cat("\n=== Excluding COVID ===\n")

m_nocovid <- feols(sir_count ~ peer_sir | cell_id + yearqtr_f,
                   data = panel %>% filter(year < 2020 | year > 2021),
                   cluster = ~state)
cat("No COVID:\n")
summary(m_nocovid)

# --------------------------------------------------------------------------
# 4. Alternative clustering
# --------------------------------------------------------------------------
cat("\n=== Alternative Clustering ===\n")

m_clust_sector <- feols(sir_count ~ peer_sir | cell_id + yearqtr_f,
                        data = panel, cluster = ~naics2)
m_clust_twoway <- feols(sir_count ~ peer_sir | cell_id + yearqtr_f,
                        data = panel, cluster = ~state + yearqtr_f)

cat("Clustered at sector:\n"); summary(m_clust_sector)
cat("\nTwo-way (state × quarter):\n"); summary(m_clust_twoway)

# --------------------------------------------------------------------------
# 5. Save
# --------------------------------------------------------------------------
robust <- list(
  placebo_cross = m_placebo,
  horse_race = m_horse,
  lead_placebo = m_lead,
  lag_structure = m_lags,
  no_covid = m_nocovid,
  cluster_sector = m_clust_sector,
  cluster_twoway = m_clust_twoway
)

saveRDS(robust, "../data/robustness_results.rds")
write_csv(panel, "../data/analysis_panel.csv")

cat("\n=== Robustness complete ===\n")
