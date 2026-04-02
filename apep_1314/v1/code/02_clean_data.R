## 02_clean_data.R — Construct analysis panel
## apep_1314: The Prudential Drag
source("00_packages.R")
setwd("..")

# ============================================================================
# Load raw data
# ============================================================================
emp   <- fread("data/eurostat_employment.csv")
bd    <- fread("data/eurostat_business_demography.csv")
pop   <- fread("data/eurostat_population.csv")
gdp   <- fread("data/eurostat_gdp.csv")
unemp <- fread("data/eurostat_unemployment.csv")

cat("=== Building analysis panel ===\n")

# ============================================================================
# 1. Construct Bartik instrument
# ============================================================================

# Share: pre-shock (2008) financial employment share at NUTS2 level
shares_2008 <- emp |>
  filter(year == 2008, !is.na(fin_share)) |>
  select(nuts2, country, fin_share_2008 = fin_share,
         emp_fin_2008 = emp_financial, emp_total_2008 = emp_total)

cat(sprintf("Pre-shock shares: %d NUTS2 regions with 2008 financial employment\n",
            nrow(shares_2008)))

# Shift: country-level change in financial employment (leave-one-out)
# For each region r in country c, the shift is the change in total NACE K
# employment in country c EXCLUDING region r (Borusyak, Hull, Jaravel 2022)
country_fin_emp <- emp |>
  filter(!is.na(emp_financial)) |>
  group_by(country, year) |>
  summarise(total_fin_country = sum(emp_financial, na.rm = TRUE),
            n_regions = n(),
            .groups = "drop")

# Merge region-level and country-level, compute leave-one-out shift
emp_shift <- emp |>
  filter(!is.na(emp_financial)) |>
  left_join(country_fin_emp, by = c("country", "year")) |>
  mutate(fin_loo = total_fin_country - emp_financial)  # leave-one-out

# Compute shift relative to 2008 baseline
baseline_loo <- emp_shift |>
  filter(year == 2008) |>
  select(nuts2, fin_loo_2008 = fin_loo)

emp_shift <- emp_shift |>
  left_join(baseline_loo, by = "nuts2") |>
  mutate(shift = (fin_loo - fin_loo_2008) / fin_loo_2008)  # pct change

cat(sprintf("Shift variable: %d obs across %d countries\n",
            nrow(emp_shift), n_distinct(emp_shift$country)))

# ============================================================================
# 2. Construct outcome variables
# ============================================================================

# Outcome 1: Non-financial employment (total - financial)
emp_outcomes <- emp |>
  mutate(emp_nonfin = emp_total - emp_financial) |>
  select(nuts2, year, country, emp_total, emp_financial, emp_nonfin)

# Outcome 2: Unemployment rate
unemp_out <- unemp |>
  select(nuts2, year, unemp_rate)

# Outcome 3: GDP per capita (log)
gdp_out <- gdp |>
  select(nuts2, year, gdp_pc) |>
  mutate(log_gdp_pc = log(gdp_pc))

# ============================================================================
# 3. Merge into analysis panel
# ============================================================================

# EU-27 country codes (exclude UK post-Brexit, keep Croatia from 2013)
eu_countries <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "ES",
                  "FI", "FR", "EL", "HR", "HU", "IE", "IT", "LT", "LU",
                  "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK")

panel <- shares_2008 |>
  filter(country %in% eu_countries) |>
  # Cross with years
  cross_join(tibble(year = 2008:2023)) |>
  # Merge outcomes
  left_join(emp_outcomes, by = c("nuts2", "year", "country")) |>
  left_join(unemp_out, by = c("nuts2", "year")) |>
  left_join(gdp_out, by = c("nuts2", "year")) |>
  # Merge shift
  left_join(emp_shift |> select(nuts2, year, shift), by = c("nuts2", "year")) |>
  # Merge controls
  left_join(pop |> select(nuts2, year, pop_total, elderly_share),
            by = c("nuts2", "year")) |>
  # Construct Bartik instrument: share_2008 × shift
  mutate(bartik = fin_share_2008 * shift) |>
  # Eurozone dummy (for heterogeneity)
  mutate(eurozone = country %in% c("AT", "BE", "CY", "DE", "EE", "ES",
                                    "FI", "FR", "EL", "HR", "IE", "IT",
                                    "LT", "LU", "LV", "MT", "NL", "PT",
                                    "SI", "SK")) |>
  # Post-CRD IV indicator (2014+)
  mutate(post_crd = as.integer(year >= 2014)) |>
  # Compute changes from 2008 baseline
  group_by(nuts2) |>
  mutate(
    emp_total_2008_val = emp_total[year == 2008][1],
    unemp_2008_val = unemp_rate[year == 2008][1],
    gdp_pc_2008_val = gdp_pc[year == 2008][1],
    # Changes relative to 2008
    d_emp_total = (emp_total - emp_total_2008_val) / emp_total_2008_val * 100,
    d_unemp = unemp_rate - unemp_2008_val,
    d_log_gdp = log_gdp_pc - log(gdp_pc_2008_val)
  ) |>
  ungroup()

# Filter to regions with complete pre-treatment data
panel <- panel |>
  filter(!is.na(fin_share_2008), fin_share_2008 > 0)

cat(sprintf("\n=== Analysis panel ===\n"))
cat(sprintf("  Observations: %d\n", nrow(panel)))
cat(sprintf("  NUTS2 regions: %d\n", n_distinct(panel$nuts2)))
cat(sprintf("  Countries: %d\n", n_distinct(panel$country)))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Mean fin_share_2008: %.4f\n", mean(panel$fin_share_2008)))
cat(sprintf("  SD fin_share_2008: %.4f\n", sd(panel$fin_share_2008)))

# Summary stats
cat(sprintf("\n  Non-missing obs by outcome:\n"))
cat(sprintf("    Employment: %d\n", sum(!is.na(panel$d_emp_total))))
cat(sprintf("    Unemployment: %d\n", sum(!is.na(panel$d_unemp))))
cat(sprintf("    GDP per capita: %d\n", sum(!is.na(panel$d_log_gdp))))

fwrite(panel, "data/analysis_panel.csv")
cat("\n=== Panel saved to data/analysis_panel.csv ===\n")
