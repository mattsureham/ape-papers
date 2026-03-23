## 02_clean_data.R — Construct analysis datasets
## APEP Working Paper apep_0817

source("00_packages.R")

cat("=== Constructing Analysis Data ===\n")

# ---- Load raw data ----
disasters <- readRDS("../data/disasters.rds")
housing <- readRDS("../data/housing_owners.rds")
ihp_intake <- readRDS("../data/ihp_intake.rds")

cat(sprintf("Disasters: %d\n", nrow(disasters)))
cat(sprintf("Housing records: %d\n", nrow(housing)))
cat(sprintf("IHP intake records: %d\n", nrow(ihp_intake)))

# ---- 1. City-level Housing panel (main analysis dataset) ----
cat("\n1. Building city-level housing panel...\n")

# Aggregate housing to disaster-city level
housing_city <- housing |>
  group_by(disasterNumber, city, state) |>
  summarise(
    valid_registrations = sum(validRegistrations, na.rm = TRUE),
    avg_fema_damage = weighted.mean(averageFemaInspectedDamage,
                                     validRegistrations, na.rm = TRUE),
    total_damage = sum(totalDamage, na.rm = TRUE),
    approved_assistance = sum(approvedForFemaAssistance, na.rm = TRUE),
    total_ihp_amount = sum(totalApprovedIhpAmount, na.rm = TRUE),
    total_max_grants = sum(totalMaxGrants, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(valid_registrations > 0)

cat(sprintf("  City-disaster obs: %d\n", nrow(housing_city)))

# ---- 2. IHP intake aggregation ----
cat("\n2. Building IHP intake panel...\n")

ihp_city <- ihp_intake |>
  group_by(disasterNumber, city, state) |>
  summarise(
    total_registrations = sum(totalValidRegistrations, na.rm = TRUE),
    ihp_amount = sum(ihpAmount, na.rm = TRUE),
    ha_amount = sum(haAmount, na.rm = TRUE),
    ona_amount = sum(onaAmount, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(total_registrations > 0)

cat(sprintf("  IHP city-disaster obs: %d\n", nrow(ihp_city)))

# ---- 3. Merge datasets ----
cat("\n3. Merging datasets...\n")

# Merge housing and IHP intake on disaster-city
analysis_city <- housing_city |>
  left_join(ihp_city, by = c("disasterNumber", "city", "state")) |>
  left_join(disasters |> select(disasterNumber, declarationDate, incidentBeginDate,
                                 incidentType, declaration_lag, year,
                                 concurrent_disasters, recent_declarations,
                                 n_counties,
                                 disaster_state = state),
            by = "disasterNumber")

# Compute per-registrant outcomes
analysis_city <- analysis_city |>
  mutate(
    ihp_per_reg = total_ihp_amount / valid_registrations,
    approval_rate = approved_assistance / valid_registrations,
    ha_per_reg = ha_amount / total_registrations,
    log_ihp_per_reg = log(pmax(ihp_per_reg, 1)),
    log_declaration_lag = log(pmax(declaration_lag, 1)),
    log_damage = log(pmax(avg_fema_damage, 1)),
    is_hurricane = as.integer(incidentType == "Hurricane"),
    is_flood = as.integer(incidentType == "Flood"),
    is_severe_storm = as.integer(grepl("Severe Storm", incidentType)),
    # Major hurricane dummy (for robustness exclusion)
    major_hurricane = disasterNumber %in% c(
      1603, 1604,  # Sandy 2012
      4332,        # Harvey 2017
      4335, 4336, 4337, 4339,  # Irma 2017
      4339, 4340,  # Maria 2017
      4337,        # Maria 2017
      4399,        # Michael 2018
      4485,        # Laura 2020
      4611,        # Ian 2022
      4673         # Idalia 2023
    )
  )

cat(sprintf("  Analysis obs: %d\n", nrow(analysis_city)))
cat(sprintf("  Disasters represented: %d\n", n_distinct(analysis_city$disasterNumber)))

# ---- 4. Disaster-level dataset ----
cat("\n4. Building disaster-level dataset...\n")

analysis_disaster <- analysis_city |>
  group_by(disasterNumber) |>
  summarise(
    declaration_lag = first(declaration_lag),
    log_declaration_lag = first(log_declaration_lag),
    concurrent_disasters = first(concurrent_disasters),
    recent_declarations = first(recent_declarations),
    incidentType = first(incidentType),
    year = first(year),
    disaster_state = first(disaster_state),
    n_counties = first(n_counties),
    is_hurricane = first(is_hurricane),
    is_flood = first(is_flood),
    is_severe_storm = first(is_severe_storm),
    major_hurricane = first(major_hurricane),
    # Outcomes (disaster-level aggregates)
    total_registrations = sum(valid_registrations, na.rm = TRUE),
    total_ihp = sum(total_ihp_amount, na.rm = TRUE),
    mean_ihp_per_reg = weighted.mean(ihp_per_reg, valid_registrations, na.rm = TRUE),
    mean_approval_rate = weighted.mean(approval_rate, valid_registrations, na.rm = TRUE),
    mean_damage = weighted.mean(avg_fema_damage, valid_registrations, na.rm = TRUE),
    n_cities = n(),
    .groups = "drop"
  ) |>
  mutate(
    log_mean_ihp = log(pmax(mean_ihp_per_reg, 1)),
    log_total_reg = log(pmax(total_registrations, 1)),
    log_mean_damage = log(pmax(mean_damage, 1))
  )

cat(sprintf("  Disaster-level obs: %d\n", nrow(analysis_disaster)))

# ---- 5. Summary statistics ----
cat("\n5. Summary statistics...\n")

cat("\n  --- Disaster-level ---\n")
cat(sprintf("  Declaration lag: mean=%.1f, SD=%.1f, p25=%.0f, p50=%.0f, p75=%.0f\n",
            mean(analysis_disaster$declaration_lag),
            sd(analysis_disaster$declaration_lag),
            quantile(analysis_disaster$declaration_lag, 0.25),
            quantile(analysis_disaster$declaration_lag, 0.50),
            quantile(analysis_disaster$declaration_lag, 0.75)))
cat(sprintf("  IHP per registrant: mean=$%.0f, SD=$%.0f\n",
            mean(analysis_disaster$mean_ihp_per_reg, na.rm=TRUE),
            sd(analysis_disaster$mean_ihp_per_reg, na.rm=TRUE)))
cat(sprintf("  Approval rate: mean=%.1f%%, SD=%.1f%%\n",
            mean(analysis_disaster$mean_approval_rate, na.rm=TRUE)*100,
            sd(analysis_disaster$mean_approval_rate, na.rm=TRUE)*100))
cat(sprintf("  Avg damage: mean=$%.0f, SD=$%.0f\n",
            mean(analysis_disaster$mean_damage, na.rm=TRUE),
            sd(analysis_disaster$mean_damage, na.rm=TRUE)))
cat(sprintf("  IV (concurrent): mean=%.1f, SD=%.1f\n",
            mean(analysis_disaster$concurrent_disasters),
            sd(analysis_disaster$concurrent_disasters)))

cat("\n  --- By incident type ---\n")
analysis_disaster |>
  group_by(incidentType) |>
  summarise(n = n(),
            mean_lag = mean(declaration_lag),
            mean_ihp = mean(mean_ihp_per_reg, na.rm=TRUE),
            .groups = "drop") |>
  arrange(desc(n)) |>
  head(8) |>
  print()

# ---- 6. Save analysis data ----
cat("\n6. Saving analysis data...\n")
saveRDS(analysis_city, "../data/analysis_city.rds")
saveRDS(analysis_disaster, "../data/analysis_disaster.rds")

cat("\n=== Data construction complete ===\n")
