## 02_clean_data.R — Merge and clean all data sources
## Paper: Cottage Food Law Liberalization and Micro-Entrepreneurship (apep_0853)

source("00_packages.R")
load("../data/raw_data.RData")

# =============================================================================
# Clean Nonemployer Statistics (NAICS 311)
# =============================================================================

nes_311_clean <- nes_311 %>%
  mutate(
    state_fips = state,
    estab_311 = as.numeric(NESTAB),
    receipts_311 = as.numeric(NRCPTOT),
    year = as.integer(year)
  ) %>%
  select(state_fips, year, estab_311, receipts_311)

cat("NES 311 cleaned:", nrow(nes_311_clean), "obs\n")

# Clean NAICS 3118 (bakeries/tortilla) for mechanism
nes_3118_clean <- nes_3118 %>%
  mutate(
    state_fips = state,
    estab_3118 = as.numeric(NESTAB),
    receipts_3118 = as.numeric(NRCPTOT),
    year = as.integer(year)
  ) %>%
  select(state_fips, year, estab_3118, receipts_3118)

cat("NES 3118 cleaned:", nrow(nes_3118_clean), "obs\n")

# =============================================================================
# Clean County Business Patterns (placebo)
# =============================================================================

cbp_clean <- cbp_311 %>%
  mutate(
    state_fips = state,
    employer_estab_311 = as.numeric(ESTAB),
    employer_emp_311 = as.numeric(EMP),
    year = as.integer(year)
  ) %>%
  select(state_fips, year, employer_estab_311, employer_emp_311)

cat("CBP 311 cleaned:", nrow(cbp_clean), "obs\n")

# =============================================================================
# Clean population data
# =============================================================================

pop_clean <- pop_all %>%
  mutate(
    state_fips = state,
    population = as.numeric(B01001_001E),
    year = as.integer(year)
  ) %>%
  select(state_fips, year, population)

cat("Population cleaned:", nrow(pop_clean), "obs\n")

# =============================================================================
# Merge everything
# =============================================================================

panel <- nes_311_clean %>%
  left_join(nes_3118_clean, by = c("state_fips", "year")) %>%
  left_join(cbp_clean, by = c("state_fips", "year")) %>%
  left_join(pop_clean, by = c("state_fips", "year")) %>%
  left_join(
    treatment_data %>% select(state_fips, state_abbr, state_name, treat_year, event_type),
    by = "state_fips"
  )

# Construct treatment variables
panel <- panel %>%
  mutate(
    # Binary post-treatment indicator (only for in-panel treatments)
    treated = ifelse(!is.na(treat_year) & treat_year >= 2012 & year >= treat_year, 1L, 0L),
    # Group variable for CS DiD: treat_year for treated (in panel), 0 for never/always-treated
    # States treated before panel start (2012) have no pre-treatment obs, so assign g=0
    g = ifelse(!is.na(treat_year) & treat_year >= 2012, treat_year, 0L),
    # Per-capita outcomes (per 100K population)
    estab_311_pc = estab_311 / population * 100000,
    estab_3118_pc = estab_3118 / population * 100000,
    receipts_311_pc = receipts_311 / population * 100000,
    employer_estab_311_pc = employer_estab_311 / population * 100000,
    # Log outcomes
    ln_estab_311 = log(estab_311 + 1),
    ln_estab_3118 = log(estab_3118 + 1),
    ln_receipts_311 = log(receipts_311 + 1),
    ln_employer_estab_311 = log(employer_estab_311 + 1),
    # Numeric state ID for fixest
    state_id = as.numeric(as.factor(state_fips))
  )

# Verify panel structure
cat("\n=== Panel Summary ===\n")
cat("States:", n_distinct(panel$state_fips), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Total obs:", nrow(panel), "\n")
cat("Treated states (in-panel events):", sum(!is.na(treatment_data$treat_year)), "\n")
cat("Treatment years:", paste(sort(unique(panel$g[panel$g > 0])), collapse = ", "), "\n")
cat("Pre-panel / never-treated:", sum(is.na(treatment_data$treat_year)), "\n")

# Check for missing data
cat("\nMissing data:\n")
cat("  estab_311:", sum(is.na(panel$estab_311)), "\n")
cat("  population:", sum(is.na(panel$population)), "\n")
cat("  estab_3118:", sum(is.na(panel$estab_3118)), "\n")

# Drop observations with missing key variables
panel <- panel %>%
  filter(!is.na(estab_311) & !is.na(population) & population > 0)

cat("\nFinal panel:", nrow(panel), "obs across",
    n_distinct(panel$state_fips), "states and",
    n_distinct(panel$year), "years\n")

# =============================================================================
# Save cleaned panel
# =============================================================================

save(panel, file = "../data/analysis_panel.RData")
write_csv(panel, "../data/analysis_panel.csv")
cat("Cleaned panel saved.\n")
