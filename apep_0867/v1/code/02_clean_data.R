## 02_clean_data.R — Merge employment + transposition, build analysis panel
## apep_0867: Upload Filters and the Creative Economy

source("00_packages.R")

# --- Load data ---
empl <- readRDS("../data/empl_country.rds")
empl_total <- readRDS("../data/empl_total.rds")
transposition <- readRDS("../data/transposition.rds")

cat("=== Building analysis panel ===\n")

# --- Merge employment with transposition ---
# Keep only countries in our transposition dataset
panel <- empl %>%
  inner_join(transposition %>% select(country, treatment_year), by = "country") %>%
  left_join(empl_total, by = c("country", "year"))

cat(sprintf("Panel after merge: %d rows, %d countries\n",
            nrow(panel), n_distinct(panel$country)))

# --- Compute employment shares ---
panel <- panel %>%
  mutate(
    empl_share = employment / total_employment * 100
  )

# --- Create treatment indicator ---
# For CS-DiD: first_treat = treatment_year (0 for never-treated)
# Treated indicator: 1 if year >= treatment_year and treatment_year > 0
panel <- panel %>%
  mutate(
    first_treat = treatment_year,
    treated = as.integer(first_treat > 0 & year >= first_treat)
  )

# --- Create DDD variables ---
# is_info = 1 for NACE J (affected), 0 for NACE K (unaffected)
panel <- panel %>%
  mutate(
    is_info = as.integer(nace == "J"),
    did_treat = treated * is_info  # DDD interaction
  )

# --- Log employment ---
panel <- panel %>%
  mutate(
    log_empl = log(employment + 1)
  )

# --- Summary statistics ---
cat("\n--- Panel Summary ---\n")
cat(sprintf("Countries: %d\n", n_distinct(panel$country)))
cat(sprintf("Years: %s\n", paste(range(panel$year), collapse = "-")))
cat(sprintf("Observations: %d\n", nrow(panel)))

cat("\nBy sector:\n")
panel %>%
  group_by(nace) %>%
  summarise(
    n = n(),
    mean_empl = mean(employment, na.rm = TRUE),
    sd_empl = sd(employment, na.rm = TRUE),
    mean_share = mean(empl_share, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

cat("\nTreatment cohorts:\n")
panel %>%
  filter(nace == "J") %>%
  distinct(country, first_treat) %>%
  count(first_treat, name = "n_countries") %>%
  print()

# --- Balance check ---
# Check for missing values
n_missing <- sum(is.na(panel$employment))
cat(sprintf("\nMissing employment values: %d\n", n_missing))

# Drop rows with missing employment
panel <- panel %>% filter(!is.na(employment))

# --- Create balanced panel for CS-DiD (country-level, NACE J only) ---
panel_j <- panel %>% filter(nace == "J")
panel_k <- panel %>% filter(nace == "K")

# Check balance
years_per_country <- panel_j %>%
  group_by(country) %>%
  summarise(n_years = n_distinct(year), .groups = "drop")

cat("\nYears per country (NACE J):\n")
print(table(years_per_country$n_years))

# Keep only countries with all 9 years for balanced panel
balanced_countries <- years_per_country %>%
  filter(n_years == max(n_years)) %>%
  pull(country)

panel_balanced <- panel %>%
  filter(country %in% balanced_countries)

cat(sprintf("\nBalanced panel: %d countries, %d obs\n",
            n_distinct(panel_balanced$country), nrow(panel_balanced)))

# --- Save ---
saveRDS(panel, "../data/panel_full.rds")
saveRDS(panel_balanced, "../data/panel_balanced.rds")

cat("\n=== Panel construction complete ===\n")
