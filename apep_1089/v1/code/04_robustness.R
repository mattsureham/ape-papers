## 04_robustness.R — Robustness checks
## apep_1089: NIS2 Cybersecurity Regulation and Firm Security Investment

source("code/00_packages.R")

cat("=== Robustness Checks ===\n")

# ----------------------------------------------------------------
# 1. Load data
# ----------------------------------------------------------------

indices <- readRDS("data/indices.rds")
indicator_panel <- readRDS("data/indicator_panel.rds")
results <- readRDS("data/main_results.rds")

did_data <- indices %>% filter(size_class %in% c("10-49", "50-249"))

# ----------------------------------------------------------------
# 2. Placebo test: GE250 vs 50-249 (both already under NIS2 regulation)
# ----------------------------------------------------------------

cat("\n--- Placebo: GE250 vs 50-249 (both regulated) ---\n")

# If NIS2 drives the formal compliance increase, it should NOT appear
# when comparing two already-regulated size classes
placebo_data <- indices %>%
  filter(size_class %in% c("50-249", "GE250")) %>%
  mutate(
    placebo_treated = as.integer(size_class == "GE250"),
    placebo_treat_post = placebo_treated * post
  )

m_placebo_tech <- feols(index_technical ~ placebo_treat_post |
                          country + size_factor + country^factor(year),
                        data = placebo_data, cluster = ~country)

m_placebo_formal <- feols(index_formal ~ placebo_treat_post |
                            country + size_factor + country^factor(year),
                          data = placebo_data, cluster = ~country)

cat("Placebo Technical (GE250 vs 50-249):\n")
summary(m_placebo_tech)
cat("Placebo Formal (GE250 vs 50-249):\n")
summary(m_placebo_formal)

# ----------------------------------------------------------------
# 3. Leave-one-out: drop each country
# ----------------------------------------------------------------

cat("\n--- Leave-One-Out by Country ---\n")

countries <- unique(did_data$country)
loo_results <- tibble()

for (ctry in countries) {
  loo_data <- did_data %>% filter(country != ctry)

  m_loo_tech <- tryCatch(
    feols(index_technical ~ treat_post | country + size_factor + country^factor(year),
          data = loo_data, cluster = ~country),
    error = function(e) NULL
  )

  m_loo_formal <- tryCatch(
    feols(index_formal ~ treat_post | country + size_factor + country^factor(year),
          data = loo_data, cluster = ~country),
    error = function(e) NULL
  )

  if (!is.null(m_loo_tech) && !is.null(m_loo_formal)) {
    loo_results <- bind_rows(loo_results, tibble(
      dropped = ctry,
      beta_tech = coef(m_loo_tech)["treat_post"],
      se_tech = se(m_loo_tech)["treat_post"],
      beta_formal = coef(m_loo_formal)["treat_post"],
      se_formal = se(m_loo_formal)["treat_post"]
    ))
  }
}

cat("Leave-one-out results:\n")
cat(sprintf("  Technical: range [%.2f, %.2f], full sample = %.2f\n",
            min(loo_results$beta_tech), max(loo_results$beta_tech),
            coef(results$m3_tech)["treat_post"]))
cat(sprintf("  Formal: range [%.2f, %.2f], full sample = %.2f\n",
            min(loo_results$beta_formal), max(loo_results$beta_formal),
            coef(results$m3_formal)["treat_post"]))

# ----------------------------------------------------------------
# 4. Alternative control: Use 2019 as single pre-period
# ----------------------------------------------------------------

cat("\n--- Alternative: 2019 as single pre-period ---\n")

did_2019_2024 <- did_data %>% filter(year %in% c(2019, 2024))

m_alt_tech <- feols(index_technical ~ treat_post | country + size_factor,
                    data = did_2019_2024, cluster = ~country)

m_alt_formal <- feols(index_formal ~ treat_post | country + size_factor,
                      data = did_2019_2024, cluster = ~country)

cat("2019-2024 only:\n")
etable(m_alt_tech, m_alt_formal, se = "cluster")

# ----------------------------------------------------------------
# 5. Placebo outcome: Security incidents (not compliance targets)
# ----------------------------------------------------------------

cat("\n--- Placebo Outcome: Security Incidents ---\n")

incidents_raw <- tryCatch(readRDS("data/ict_incidents_raw.rds"), error = function(e) NULL)

if (!is.null(incidents_raw)) {
  eu27 <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
            "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
            "NL", "PL", "PT", "RO", "SE", "SI", "SK")

  incidents <- incidents_raw %>%
    filter(
      size_emp %in% c("10-49", "50-249"),
      geo %in% eu27,
      unit == "PC_ENT",
      TIME_PERIOD %in% c(2019, 2022, 2024)
    ) %>%
    rename(country = geo, year = TIME_PERIOD, indicator = indic_is,
           size_class = size_emp, value = values) %>%
    filter(!is.na(value)) %>%
    mutate(
      treated = as.integer(size_class == "50-249"),
      post = as.integer(year == 2024),
      treat_post = treated * post,
      size_factor = factor(size_class)
    )

  # Average incident rate
  inc_index <- incidents %>%
    group_by(country, year, size_class) %>%
    summarize(incident_rate = mean(value, na.rm = TRUE), .groups = "drop") %>%
    mutate(
      treated = as.integer(size_class == "50-249"),
      post = as.integer(year == 2024),
      treat_post = treated * post,
      size_factor = factor(size_class)
    )

  if (nrow(inc_index) > 10) {
    m_incidents <- feols(incident_rate ~ treat_post |
                           country + size_factor + factor(year),
                         data = inc_index, cluster = ~country)
    cat("Incident rate DiD:\n")
    summary(m_incidents)
  } else {
    cat("  Insufficient incident data for analysis.\n")
    m_incidents <- NULL
  }
} else {
  cat("  No incident data available.\n")
  m_incidents <- NULL
}

# ----------------------------------------------------------------
# 6. Indicator-level heterogeneity: Which measures drive the effect?
# ----------------------------------------------------------------

cat("\n--- Indicator Heterogeneity ---\n")

# NIS2 specifically mandates: risk assessment, incident handling,
# supply chain security, encryption, staff training
nis2_mandated <- c("E_SECMRASS", "E_SECMDENC", "E_SECAWCTP", "E_SECPOL2")
nis2_non_mandated <- c("E_SECMOSBU", "E_SECMSPSW", "E_SECMVPN", "E_SECMUIBM")

ind_panel_did <- indicator_panel %>%
  filter(size_class %in% c("10-49", "50-249")) %>%
  mutate(
    mandated = as.integer(indicator %in% nis2_mandated),
    mandate_treat_post = mandated * treat_post
  )

m_mandate <- feols(value ~ treat_post + mandate_treat_post |
                     country + indicator + size_factor + country^factor(year),
                   data = ind_panel_did, cluster = ~country)

cat("Mandated vs non-mandated indicator interaction:\n")
summary(m_mandate)

# ----------------------------------------------------------------
# 7. Save robustness results
# ----------------------------------------------------------------

rob_results <- list(
  placebo_tech = m_placebo_tech,
  placebo_formal = m_placebo_formal,
  loo_results = loo_results,
  alt_tech = m_alt_tech,
  alt_formal = m_alt_formal,
  incidents = m_incidents,
  mandate = m_mandate
)

saveRDS(rob_results, "data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
