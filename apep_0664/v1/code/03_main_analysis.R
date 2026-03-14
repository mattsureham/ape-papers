## 03_main_analysis.R — Main DiD and Triple-DiD analysis
## apep_0664: Finland Competitiveness Pact

source("code/00_packages.R")

panel <- readRDS("data/panel.rds")

cat("=== Main Analysis ===\n")

## ---- 1. Simple DiD: Finland vs Nordic peers, pre vs post 2017 ----
# Outcome: log total hours worked
# FE: sector-country + country-year (for DDD, sector-country + year)

# Model 1: Basic DiD (country FE + year FE + sector FE)
m1 <- feols(ln_hours ~ treat_did | country + year + sector,
            data = panel, cluster = ~country)

# Model 2: DiD with sector-country FE + year FE
m2 <- feols(ln_hours ~ treat_did | country_sector + year,
            data = panel, cluster = ~country)

# Model 3: Triple-DiD: additional public sector effect
m3 <- feols(ln_hours ~ treat_did + triple_did | country_sector + year,
            data = panel, cluster = ~country)

# Model 4: Log hours per worker
m4 <- feols(ln_hours_pw ~ treat_did | country_sector + year,
            data = panel, cluster = ~country)

# Model 5: Log employment
m5 <- feols(ln_employment ~ treat_did | country_sector + year,
            data = panel, cluster = ~country)

cat("\n--- Model summaries ---\n")
cat("M1 (Basic DiD, ln_hours):\n")
print(summary(m1))
cat("\nM2 (Sector-Country FE, ln_hours):\n")
print(summary(m2))
cat("\nM3 (Triple-DiD, ln_hours):\n")
print(summary(m3))
cat("\nM4 (Hours per worker):\n")
print(summary(m4))
cat("\nM5 (Employment):\n")
print(summary(m5))

## ---- 2. Event Study ----
# Create event-time dummies interacted with Finland indicator
# Omit t = -1 (2016)
panel <- panel %>%
  mutate(rel_time_factor = factor(rel_time))

es_hours <- feols(ln_hours ~ i(rel_time, finland, ref = -1) | country_sector + year,
                  data = panel, cluster = ~country)

cat("\n--- Event Study (ln_hours) ---\n")
print(summary(es_hours))

## ---- 3. Productivity analysis ----
panel_prod <- panel %>% filter(!is.na(ln_productivity))

m_prod <- feols(ln_productivity ~ treat_did | country_sector + year,
                data = panel_prod, cluster = ~country)

cat("\n--- Productivity DiD ---\n")
print(summary(m_prod))

## ---- 4. Save results ----
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_hours = es_hours, m_prod = m_prod
)
saveRDS(results, "data/results_main.rds")

## ---- 5. Diagnostics for validator ----
# n_treated: Finnish sector-year observations in post period (treated observations)
diag <- list(
  n_treated = nrow(panel[panel$finland == 1 & panel$post == 1, ]),
  n_pre = length(unique(panel$year[panel$year < 2017])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics:", paste(names(diag), "=", diag, collapse = ", "), "\n")
cat("Main analysis complete.\n")
