## 02_clean_data.R — Construct analysis panel
## apep_1172: Cage-Free Egg Mandates

source("00_packages.R")

layers_panel <- readRDS("../data/nass_egg_panel.rds")
bls_prices <- readRDS("../data/bls_egg_prices.rds")

# ============================================================
# Treatment assignment
# ============================================================

# Cage-free mandate effective dates (month eggs must be cage-free)
mandate_dates <- tribble(
  ~state, ~mandate_date,    ~cohort_year,
  "CA",   "2022-01-01",     2022,
  "MA",   "2023-01-01",     2023,
  "WA",   "2024-01-01",     2024,
  "OR",   "2024-01-01",     2024,
  "NV",   "2024-01-01",     2024,
  "CO",   "2025-01-01",     2025,
  "AZ",   "2025-01-01",     2025,
  "MI",   "2025-01-01",     2025,
  "UT",   "2025-01-01",     2025
) %>%
  mutate(mandate_date = as.Date(mandate_date))

# RI effective 2026 — not yet treated during our sample
# We keep RI in the control group (not-yet-treated)

cat("Treatment states:", paste(mandate_dates$state, collapse = ", "), "\n")
cat("Cohorts:", paste(unique(mandate_dates$cohort_year), collapse = ", "), "\n")

# ============================================================
# Merge treatment into production panel
# ============================================================

# Create a numeric time index (months since Jan 2010)
analysis <- layers_panel %>%
  left_join(mandate_dates, by = "state") %>%
  mutate(
    treated_state = !is.na(mandate_date),
    post = ifelse(treated_state & date >= mandate_date, 1, 0),
    # For CS estimator: first treatment period (in month index)
    time_index = (year - 2010) * 12 + month,
    first_treat_month = ifelse(
      treated_state,
      (cohort_year - 2010) * 12 + 1,  # January of cohort year
      0  # Never-treated
    )
  )

cat("\nPanel summary:\n")
cat("  Total state-months:", nrow(analysis), "\n")
cat("  Treated states in data:", sum(analysis$treated_state & !duplicated(analysis$state)), "\n")
cat("  Control states in data:", sum(!analysis$treated_state & !duplicated(analysis$state)), "\n")

# Check which treated states are in the NASS data
treated_in_data <- analysis %>%
  filter(treated_state) %>%
  distinct(state)
cat("  Treated states present:", paste(treated_in_data$state, collapse = ", "), "\n")

missing_treated <- setdiff(mandate_dates$state, treated_in_data$state)
if (length(missing_treated) > 0) {
  cat("  WARNING: Treated states NOT in NASS data:", paste(missing_treated, collapse = ", "), "\n")
  cat("  (Small states may not report monthly to NASS)\n")
}

# ============================================================
# Log-transform production outcomes
# ============================================================

analysis <- analysis %>%
  mutate(
    ln_layers = log(avg_layers_k),
    ln_production = log(production_eggs),
    ln_eggs_per_100 = log(eggs_per_100)
  ) %>%
  filter(!is.na(avg_layers_k))  # Drop state-months with missing production data

cat("  After dropping missing:", nrow(analysis), "state-months\n")

# ============================================================
# Create state numeric ID for fixest/did
# ============================================================

analysis <- analysis %>%
  mutate(state_id = as.integer(factor(state)))

# ============================================================
# Assign states to BLS regions for price analysis
# ============================================================

state_region <- tribble(
  ~state, ~bls_region,
  # Northeast
  "CT", "Northeast", "ME", "Northeast", "MA", "Northeast",
  "NH", "Northeast", "NJ", "Northeast", "NY", "Northeast",
  "PA", "Northeast", "RI", "Northeast", "VT", "Northeast",
  # Midwest
  "IL", "Midwest", "IN", "Midwest", "IA", "Midwest",
  "KS", "Midwest", "MI", "Midwest", "MN", "Midwest",
  "MO", "Midwest", "NE", "Midwest", "ND", "Midwest",
  "OH", "Midwest", "SD", "Midwest", "WI", "Midwest",
  # South
  "AL", "South", "AR", "South", "DE", "South",
  "FL", "South", "GA", "South", "KY", "South",
  "LA", "South", "MD", "South", "MS", "South",
  "NC", "South", "OK", "South", "SC", "South",
  "TN", "South", "TX", "South", "VA", "South",
  "WV", "South", "DC", "South",
  # West
  "AK", "West", "AZ", "West", "CA", "West",
  "CO", "West", "HI", "West", "ID", "West",
  "MT", "West", "NV", "West", "NM", "West",
  "OR", "West", "UT", "West", "WA", "West",
  "WY", "West"
)

# Create region-level price panel
price_panel <- bls_prices %>%
  filter(region != "US")

cat("\nPrice panel:", nrow(price_panel), "region-months\n")

# ============================================================
# Summary statistics
# ============================================================

cat("\n=== Summary Statistics ===\n")

# Pre-treatment means by treatment status
pre_means <- analysis %>%
  filter(date < as.Date("2022-01-01")) %>%
  group_by(treated_state) %>%
  summarise(
    mean_layers = mean(avg_layers_k, na.rm = TRUE),
    sd_layers = sd(avg_layers_k, na.rm = TRUE),
    mean_production = mean(production_eggs, na.rm = TRUE),
    sd_production = sd(production_eggs, na.rm = TRUE),
    mean_eggs_per = mean(eggs_per_100, na.rm = TRUE),
    sd_eggs_per = sd(eggs_per_100, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

print(pre_means)

# ============================================================
# Save analysis data
# ============================================================

saveRDS(analysis, "../data/analysis_panel.rds")
saveRDS(price_panel, "../data/price_panel.rds")
write_csv(analysis, "../data/analysis_panel.csv")

cat("\n=== Cleaning complete ===\n")
cat("Analysis panel:", nrow(analysis), "state-months\n")
cat("States:", n_distinct(analysis$state), "\n")
cat("Treated states in data:", n_distinct(analysis$state[analysis$treated_state]), "\n")
cat("Date range:", as.character(min(analysis$date)), "to", as.character(max(analysis$date)), "\n")
