# 03_main_analysis.R — Main DiD regressions and event study
# apep_0681: IR35 Off-Payroll Reforms

source("00_packages.R")

panel <- read_csv("../data/analysis_panel.csv", show_col_types = FALSE)
cat(sprintf("Panel: %d rows\n", nrow(panel)))

# ---- Ensure factor variables ----
panel <- panel |>
  mutate(
    la_code  = as.factor(la_code),
    sic_code = as.factor(sic_code),
    unit_id  = as.factor(unit_id),
    year_f   = as.factor(year)
  )

# ============================================================
# 1. MAIN DiD: Two-reform specification
# ============================================================
# Y = log(companies) in LA i, sector s, year t
# Treat × Post2017 captures public sector reform
# Treat × Post2021 captures private sector extension
# FE: LA×year (absorbs all local shocks) + sector (absorbs level differences)

cat("\n=== MAIN SPECIFICATION ===\n")

# Model 1: Simple DiD with sector + year FE
m1 <- feols(log_companies ~ treat_post2017 + treat_post2021 |
              sic_code + year_f,
            data = panel, cluster = ~sic_code)

# Model 2: Add LA FE
m2 <- feols(log_companies ~ treat_post2017 + treat_post2021 |
              sic_code + year_f + la_code,
            data = panel, cluster = ~sic_code)

# Model 3: LA × year FE (preferred — absorbs all local time-varying shocks)
m3 <- feols(log_companies ~ treat_post2017 + treat_post2021 |
              sic_code + la_code^year_f,
            data = panel, cluster = ~sic_code)

# Model 4: Unit FE + year FE (within-unit over time)
m4 <- feols(log_companies ~ treat_post2017 + treat_post2021 |
              unit_id + year_f,
            data = panel, cluster = ~sic_code)

cat("Model 1 (Sector + Year FE):\n")
summary(m1)
cat("\nModel 2 (Sector + Year + LA FE):\n")
summary(m2)
cat("\nModel 3 (Sector + LA×Year FE) [preferred]:\n")
summary(m3)
cat("\nModel 4 (Unit + Year FE):\n")
summary(m4)

# ============================================================
# 2. EVENT STUDY
# ============================================================
# Use 2019 as base year (last pre-private-reform year, 2 years after public reform)
# This shows the full trajectory

cat("\n=== EVENT STUDY ===\n")

panel <- panel |>
  mutate(event_time = year - 2021)  # Relative to private sector reform

# Event study with LA×year FE
es <- feols(log_companies ~ i(event_time, treated, ref = -2) |
              sic_code + la_code^year_f,
            data = panel, cluster = ~sic_code)

cat("Event study (ref = -2, i.e. 2019):\n")
summary(es)

# Save event study coefficients
es_coefs <- as.data.frame(coeftable(es))
es_coefs$term <- rownames(es_coefs)
write_csv(es_coefs, "../data/event_study_coefs.csv")

# ============================================================
# 3. ORGANIZATIONAL FORM DECOMPOSITION
# ============================================================
# Does the decline in companies show up as:
# (a) Rise in sole proprietorships (structural shift)?
# (b) Net decline in total enterprises (exit to payroll employment)?

cat("\n=== ORGANIZATIONAL FORM DECOMPOSITION ===\n")

# Sole proprietorships
m_sole <- feols(log_sole_props ~ treat_post2017 + treat_post2021 |
                  sic_code + la_code^year_f,
                data = panel, cluster = ~sic_code)

# Total enterprises
m_total <- feols(log_total ~ treat_post2017 + treat_post2021 |
                   sic_code + la_code^year_f,
                 data = panel, cluster = ~sic_code)

# Company share
m_share <- feols(company_share ~ treat_post2017 + treat_post2021 |
                   sic_code + la_code^year_f,
                 data = panel, cluster = ~sic_code)

cat("Sole proprietors:\n")
summary(m_sole)
cat("\nTotal enterprises:\n")
summary(m_total)
cat("\nCompany share:\n")
summary(m_share)

# ============================================================
# 4. HETEROGENEITY: By treatment sector
# ============================================================

cat("\n=== SECTOR-SPECIFIC EFFECTS ===\n")

# Create sector-specific treatment indicators
panel <- panel |>
  mutate(
    is_it     = as.integer(sic_code == 62),
    is_consult = as.integer(sic_code == 70),
    is_arch   = as.integer(sic_code == 71),
    is_employ = as.integer(sic_code == 78)
  )

m_het <- feols(log_companies ~
                 i(is_it, post_2021) +
                 i(is_consult, post_2021) +
                 i(is_arch, post_2021) +
                 i(is_employ, post_2021) |
                 sic_code + la_code^year_f,
               data = panel, cluster = ~sic_code)

cat("Sector-specific effects (post-2021):\n")
summary(m_het)

# ============================================================
# 5. WRITE DIAGNOSTICS
# ============================================================

n_treated_units <- n_distinct(panel$unit_id[panel$treated == 1])
n_control_units <- n_distinct(panel$unit_id[panel$treated == 0])
n_pre <- sum(sort(unique(panel$year)) < 2021)  # Pre-private sector reform (main treatment)
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_units,
  n_control = n_control_units,
  n_pre = n_pre,
  n_obs = n_obs,
  n_years = n_distinct(panel$year),
  n_las = n_distinct(panel$la_code),
  n_sectors = n_distinct(panel$sic_code),
  main_coef_post2017 = coef(m3)["treat_post2017"],
  main_se_post2017 = se(m3)["treat_post2017"],
  main_coef_post2021 = coef(m3)["treat_post2021"],
  main_se_post2021 = se(m3)["treat_post2021"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nSaved: data/diagnostics.json\n")

# Save model objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, es = es,
             m_sole = m_sole, m_total = m_total, m_share = m_share,
             m_het = m_het),
        "../data/models.rds")
cat("Saved: data/models.rds\n")
