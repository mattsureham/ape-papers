## 03_main_analysis.R — Main DiD analysis for apep_1114
## Dutch Piekbelasters: Continuous treatment DiD + adverse selection test

source("00_packages.R")

cat("=== Main Analysis ===\n\n")

panel <- readRDS("../data/analysis_panel.rds")

# Drop municipalities with NA exposure
panel <- panel |> filter(!is.na(high_exposure))

cat("Panel: ", nrow(panel), " obs, ", n_distinct(panel$muni_code),
    " municipalities, ", n_distinct(panel$year), " years\n\n")

# ---------------------------------------------------------------
# 1. Main DiD: Farm exit (continuous treatment intensity)
# ---------------------------------------------------------------
cat("--- 1. Continuous Treatment DiD: Farm Counts ---\n")

# Specification 1: Log farms ~ exposure × post_2019 + exposure × post_2023
m1_farms <- feols(
  log_farms ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)
cat("Model 1 (log farms):\n")
print(summary(m1_farms))

# Specification 2: Log livestock units
m1_lu <- feols(
  log_livestock ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_livestock)),
  cluster = ~muni_code
)
cat("\nModel 2 (log livestock units):\n")
print(summary(m1_lu))

# Specification 3: Livestock per farm (intensive margin)
m1_intensive <- feols(
  livestock_per_farm ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(livestock_per_farm)),
  cluster = ~muni_code
)
cat("\nModel 3 (livestock per farm — intensive margin):\n")
print(summary(m1_intensive))

# ---------------------------------------------------------------
# 2. Binary treatment DiD
# ---------------------------------------------------------------
cat("\n--- 2. Binary Treatment DiD ---\n")

m2_farms <- feols(
  log_farms ~ high_exposure:post_2019 + high_exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)
cat("Binary DiD (log farms):\n")
print(summary(m2_farms))

m2_lu <- feols(
  log_livestock ~ high_exposure:post_2019 + high_exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_livestock)),
  cluster = ~muni_code
)
cat("\nBinary DiD (log livestock):\n")
print(summary(m2_lu))

m2_intensive <- feols(
  livestock_per_farm ~ high_exposure:post_2019 + high_exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(livestock_per_farm)),
  cluster = ~muni_code
)
cat("\nBinary DiD (livestock per farm):\n")
print(summary(m2_intensive))

# ---------------------------------------------------------------
# 3. Event study (year-by-year, binary treatment)
# ---------------------------------------------------------------
cat("\n--- 3. Event Study ---\n")

# Create event-time interactions, omitting 2018 as reference year
panel <- panel |>
  mutate(event_year = year - 2019)

m3_es <- feols(
  log_farms ~ i(event_year, high_exposure, ref = -1) |
    muni_code + year,
  data = panel |> filter(!is.na(log_farms)),
  cluster = ~muni_code
)
cat("Event study (log farms):\n")
print(summary(m3_es))

m3_es_lu <- feols(
  log_livestock ~ i(event_year, high_exposure, ref = -1) |
    muni_code + year,
  data = panel |> filter(!is.na(log_livestock)),
  cluster = ~muni_code
)
cat("\nEvent study (log livestock):\n")
print(summary(m3_es_lu))

# ---------------------------------------------------------------
# 4. Adverse selection test
# ---------------------------------------------------------------
cat("\n--- 4. Adverse Selection Test ---\n")

# The adverse selection hypothesis: after the buyout, farms that exit
# are disproportionately low-intensity. This implies:
# - Farm counts decline (extensive margin) → β_farms < 0
# - But livestock per remaining farm INCREASES (intensive margin) → β_intensive > 0
# - Total livestock declines LESS than proportional to farm exits

# Compute the ratio of livestock elasticity to farm elasticity
# If adverse selection: |β_lu| < |β_farms| (livestock falls less than farms)
cat("Adverse selection signature:\n")
cat("  Farm exit coefficient (post-2023):", coef(m1_farms)["exposure:post_2023"], "\n")
cat("  Livestock coefficient (post-2023):", coef(m1_lu)["exposure:post_2023"], "\n")

if (!is.na(coef(m1_farms)["exposure:post_2023"]) &
    !is.na(coef(m1_lu)["exposure:post_2023"])) {
  ratio <- coef(m1_lu)["exposure:post_2023"] / coef(m1_farms)["exposure:post_2023"]
  cat("  Elasticity ratio (livestock/farms):", round(ratio, 3), "\n")
  cat("  If ratio < 1: adverse selection (low-intensity farms disproportionately exit)\n")
  cat("  If ratio ≈ 1: proportional exit (no selection)\n")
  cat("  If ratio > 1: positive selection (high-intensity farms exit)\n")
}

# Also test directly: intensive margin (livestock per farm)
cat("\n  Intensive margin (LU/farm) post-2023:",
    coef(m1_intensive)["exposure:post_2023"], "\n")
cat("  If positive: remaining farms are more intensive → adverse selection confirmed\n")

# ---------------------------------------------------------------
# 5. Decomposition by livestock type
# ---------------------------------------------------------------
cat("\n--- 5. Decomposition by Livestock Type ---\n")

panel <- panel |>
  mutate(
    log_cattle = ifelse(cattle > 0, log(cattle), NA_real_),
    log_pigs = ifelse(pigs > 0, log(pigs), NA_real_),
    log_chickens = ifelse(chickens > 0, log(chickens), NA_real_)
  )

m5_cattle <- feols(
  log_cattle ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_cattle)),
  cluster = ~muni_code
)

m5_pigs <- feols(
  log_pigs ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_pigs)),
  cluster = ~muni_code
)

m5_chickens <- feols(
  log_chickens ~ exposure:post_2019 + exposure:post_2023 |
    muni_code + year,
  data = panel |> filter(!is.na(log_chickens)),
  cluster = ~muni_code
)

cat("Cattle (post-2019):", round(coef(m5_cattle)["exposure:post_2019"], 5),
    " (post-2023):", round(coef(m5_cattle)["exposure:post_2023"], 5), "\n")
cat("Pigs (post-2019):", round(coef(m5_pigs)["exposure:post_2019"], 5),
    " (post-2023):", round(coef(m5_pigs)["exposure:post_2023"], 5), "\n")
cat("Chickens (post-2019):", round(coef(m5_chickens)["exposure:post_2019"], 5),
    " (post-2023):", round(coef(m5_chickens)["exposure:post_2023"], 5), "\n")

# ---------------------------------------------------------------
# 6. Save results
# ---------------------------------------------------------------
cat("\n--- Saving results ---\n")

# Save all models
results <- list(
  m1_farms = m1_farms,
  m1_lu = m1_lu,
  m1_intensive = m1_intensive,
  m2_farms = m2_farms,
  m2_lu = m2_lu,
  m2_intensive = m2_intensive,
  m3_es = m3_es,
  m3_es_lu = m3_es_lu,
  m5_cattle = m5_cattle,
  m5_pigs = m5_pigs,
  m5_chickens = m5_chickens
)
saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json
n_treated <- panel |>
  filter(high_exposure == TRUE) |>
  pull(muni_code) |>
  n_distinct()

n_pre <- panel |>
  filter(year < 2019) |>
  pull(year) |>
  n_distinct()

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel |> filter(!is.na(log_farms))),
  n_municipalities = n_distinct(panel$muni_code),
  n_years = n_distinct(panel$year),
  treatment_start_nitrogen = 2019,
  treatment_start_buyout = 2023
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("Diagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")
cat("\n=== Main analysis complete ===\n")
