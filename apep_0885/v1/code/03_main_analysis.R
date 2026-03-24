## 03_main_analysis.R — Main DiD analysis
## APEP-0885: Gotthard Base Tunnel and Regional Economic Integration

source("00_packages.R")

DATA_DIR <- "../data"

panel_canton <- readRDS(file.path(DATA_DIR, "panel_canton.rds"))
panel_muni <- readRDS(file.path(DATA_DIR, "panel_muni.rds"))
panel_tourism <- readRDS(file.path(DATA_DIR, "panel_tourism_canton.rds"))

## ============================================================================
## 1. Descriptive Statistics
## ============================================================================

cat("=== Descriptive Statistics ===\n")

# Pre-treatment means (1994-2016)
pre_means <- panel_canton %>%
  filter(year < 2017, in_sample == 1) %>%
  group_by(is_ticino) %>%
  summarise(
    mean_construction = mean(construction, na.rm = TRUE),
    mean_construction_pc = mean(construction_pc, na.rm = TRUE),
    mean_investment = mean(investment, na.rm = TRUE),
    sd_construction_pc = sd(construction_pc, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  )
cat("\nPre-treatment construction means (Ticino vs Alpine Controls):\n")
print(pre_means)

# Tourism pre-treatment means
pre_tourism <- panel_tourism %>%
  filter(year < 2017, in_sample == 1) %>%
  group_by(is_ticino) %>%
  summarise(
    mean_nights_total = mean(nights_total, na.rm = TRUE),
    mean_nights_swiss = mean(nights_swiss, na.rm = TRUE),
    mean_nights_german = mean(nights_german, na.rm = TRUE),
    sd_nights_total = sd(nights_total, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPre-treatment tourism means:\n")
print(pre_tourism)

## ============================================================================
## 2. Main DiD — Canton Level Construction
## ============================================================================

cat("\n=== Main DiD Regressions (Canton Level) ===\n")

# Restrict to Ticino + alpine controls for primary analysis
sample_canton <- panel_canton %>% filter(in_sample == 1)

# Model 1: Simple DiD — log construction
m1 <- feols(log_construction ~ treat_post | canton + year,
            data = sample_canton,
            cluster = ~canton)

# Model 2: Log investment
m2 <- feols(log_investment ~ treat_post | canton + year,
            data = sample_canton,
            cluster = ~canton)

# Model 3: Log new construction
m3 <- feols(log_new_construction ~ treat_post | canton + year,
            data = sample_canton,
            cluster = ~canton)

# Model 4: Log Hochbau (building construction)
m4 <- feols(log_hochbau ~ treat_post | canton + year,
            data = sample_canton,
            cluster = ~canton)

cat("\n--- Table 1: Main DiD Results (Canton Level) ---\n")
etable(m1, m2, m3, m4,
       headers = c("Total", "Investment", "New Constr.", "Building"),
       se.below = TRUE)

## ============================================================================
## 3. Event Study — Canton Level
## ============================================================================

cat("\n=== Event Study (Canton Level) ===\n")

# Create event-time dummies
sample_canton <- sample_canton %>%
  mutate(
    # Trim event time at -10 and +6
    rel_year_trim = pmax(pmin(rel_year, 6), -10),
    event_time = factor(rel_year_trim)
  )

# Event study with fixest::i()
es1 <- feols(log_construction ~ i(rel_year_trim, is_ticino, ref = -1) | canton + year,
             data = sample_canton,
             cluster = ~canton)

cat("\nEvent study coefficients:\n")
print(coeftable(es1))

# Save event study for later plotting
es_coefs <- data.frame(
  rel_year = as.numeric(gsub("rel_year_trim::", "", names(coef(es1)))),
  estimate = coef(es1),
  se = sqrt(diag(vcov(es1)))
) %>%
  mutate(
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  )

# Add the reference period
es_coefs <- bind_rows(
  es_coefs,
  data.frame(rel_year = -1, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
) %>%
  arrange(rel_year)

saveRDS(es_coefs, file.path(DATA_DIR, "event_study_coefs.rds"))

## ============================================================================
## 4. Municipal Level DiD
## ============================================================================

cat("\n=== Municipal Level DiD ===\n")

# Model 5: Municipal level
m5 <- feols(log_construction ~ treat_post | muni_id + year,
            data = panel_muni,
            cluster = ~canton)

cat("\nMunicipal DiD:\n")
etable(m5, se.below = TRUE)

# Municipal event study
panel_muni <- panel_muni %>%
  mutate(rel_year_trim = pmax(pmin(rel_year, 6), -10))

es_muni <- feols(log_construction ~ i(rel_year_trim, is_ticino, ref = -1) | muni_id + year,
                 data = panel_muni,
                 cluster = ~canton)

cat("\nMunicipal event study coefficients:\n")
print(coeftable(es_muni))

# Save municipal event study
es_muni_coefs <- data.frame(
  rel_year = as.numeric(gsub("rel_year_trim::", "", names(coef(es_muni)))),
  estimate = coef(es_muni),
  se = sqrt(diag(vcov(es_muni)))
) %>%
  mutate(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)

es_muni_coefs <- bind_rows(
  es_muni_coefs,
  data.frame(rel_year = -1, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
) %>% arrange(rel_year)

saveRDS(es_muni_coefs, file.path(DATA_DIR, "event_study_muni_coefs.rds"))

## ============================================================================
## 5. Tourism DiD (Canton Level)
## ============================================================================

cat("\n=== Tourism DiD (Canton Level) ===\n")

sample_tourism <- panel_tourism %>% filter(in_sample == 1)

# Model 6: Total overnight stays
m6 <- feols(log_nights_total ~ treat_post | canton_abbr + year,
            data = sample_tourism,
            cluster = ~canton_abbr)

# Model 7: Swiss tourists (mechanism — these travel via tunnel)
m7 <- feols(log_nights_swiss ~ treat_post | canton_abbr + year,
            data = sample_tourism,
            cluster = ~canton_abbr)

# Model 8: German tourists (mechanism — also arrive from north)
m8 <- feols(log_nights_german ~ treat_post | canton_abbr + year,
            data = sample_tourism,
            cluster = ~canton_abbr)

# Model 9: Italian tourists (falsification — arrive from south)
m9 <- feols(log_nights_italian ~ treat_post | canton_abbr + year,
            data = sample_tourism,
            cluster = ~canton_abbr)

cat("\n--- Table 3: Tourism DiD (Canton Level) ---\n")
etable(m6, m7, m8, m9,
       headers = c("Total", "Swiss", "German", "Italian"),
       se.below = TRUE)

## ============================================================================
## 6. Broader Comparison (All 26 Cantons)
## ============================================================================

cat("\n=== Full Sample DiD (All 26 Cantons) ===\n")

m_full <- feols(log_construction ~ treat_post | canton + year,
                data = panel_canton,
                cluster = ~canton)

cat("Full-sample DiD:\n")
etable(m_full, se.below = TRUE)

## ============================================================================
## 7. Save All Models
## ============================================================================

models <- list(
  m1_total = m1, m2_investment = m2, m3_new = m3, m4_hochbau = m4,
  m5_muni = m5, m6_tourism_total = m6, m7_tourism_swiss = m7,
  m8_tourism_german = m8, m9_tourism_italian = m9, m_full = m_full,
  es_canton = es1, es_muni = es_muni
)
saveRDS(models, file.path(DATA_DIR, "main_models.rds"))

## ============================================================================
## 8. Write diagnostics.json
## ============================================================================

diagnostics <- list(
  n_treated = n_distinct(panel_muni$muni_id[panel_muni$is_ticino == 1]),
  n_pre = length(unique(panel_canton$year[panel_canton$year < 2017])),
  n_obs = nrow(panel_muni),
  n_cantons = n_distinct(panel_canton$canton[panel_canton$in_sample == 1]),
  n_municipalities = n_distinct(panel_muni$muni_id),
  treatment_year = 2017,
  outcome = "log_construction_expenditure",
  method = "DiD_TWFE"
)

jsonlite::write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

cat("\n=== Main Analysis Complete ===\n")
