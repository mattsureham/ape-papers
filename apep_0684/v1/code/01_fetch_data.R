## 01_fetch_data.R — Fetch EIA data via API
## MATS Compliance Bifurcation (apep_0684)

source("00_packages.R")

EIA_API_KEY <- Sys.getenv("EIA_API_KEY")
if (EIA_API_KEY == "") stop("EIA_API_KEY not set in environment. Source .env first")

data_dir <- "../data"
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------
# 1. Facility-Fuel API: Plant-level annual generation and fuel consumption
#    This is the CORE dataset — gives us generation + heat rate for ALL
#    coal plants (including those that later retired) from 2001-2024
# -----------------------------------------------------------------------
cat("=== Fetching EIA Facility-Fuel Data (Annual Coal Generation) ===\n")

fetch_facility_fuel <- function(api_key, fuel, start_year, end_year, offset = 0, length = 5000) {
  url <- "https://api.eia.gov/v2/electricity/facility-fuel/data/"
  params <- list(
    api_key = api_key,
    frequency = "annual",
    `data[0]` = "generation",
    `data[1]` = "consumption-for-eg-btu",
    `data[2]` = "total-consumption-btu",
    `facets[fuel2002][]` = fuel,
    `facets[primeMover][]` = "ST",
    start = as.character(start_year),
    end = as.character(end_year),
    offset = offset,
    length = length
  )
  resp <- GET(url, query = params)
  if (status_code(resp) != 200) {
    warning(sprintf("API error for fuel %s: status %d", fuel, status_code(resp)))
    return(NULL)
  }
  content(resp, as = "parsed")
}

coal_fuels <- c("BIT", "SUB", "LIG")
all_facility_records <- list()

for (fuel in coal_fuels) {
  cat(sprintf("  Fetching %s...\n", fuel))
  offset <- 0
  fuel_count <- 0

  repeat {
    result <- fetch_facility_fuel(EIA_API_KEY, fuel, 2001, 2024, offset = offset, length = 5000)
    if (is.null(result)) break

    records <- result$response$data
    if (length(records) == 0) break

    all_facility_records <- c(all_facility_records, records)
    fuel_count <- fuel_count + length(records)
    total_avail <- as.integer(result$response$total)
    cat(sprintf("    %s: %d / %d\n", fuel, fuel_count, total_avail))

    if (fuel_count >= total_avail) break
    offset <- offset + 5000
    Sys.sleep(0.3)
  }
  cat(sprintf("  %s total: %d records\n", fuel, fuel_count))
}

cat(sprintf("\nTotal facility-fuel records: %d\n", length(all_facility_records)))
if (length(all_facility_records) == 0) stop("FATAL: No facility-fuel records from EIA API")

facility_fuel <- bind_rows(lapply(all_facility_records, function(r) {
  tibble(
    year = as.integer(r$period %||% NA),
    plant_id = as.character(r$plantCode %||% NA),
    plant_name = as.character(r$plantName %||% NA),
    fuel_code = as.character(r$fuel2002 %||% NA),
    fuel_desc = as.character(r$fuelTypeDescription %||% NA),
    state = as.character(r$state %||% NA),
    state_name = as.character(r$stateDescription %||% NA),
    prime_mover = as.character(r$primeMover %||% NA),
    generation_mwh = as.numeric(r$generation %||% NA),
    consumption_btu = as.numeric(r$`consumption-for-eg-btu` %||% NA),
    total_consumption_btu = as.numeric(r$`total-consumption-btu` %||% NA)
  )
}))

# Aggregate to plant-year level (some plants have multiple fuel types)
plant_year <- facility_fuel %>%
  group_by(year, plant_id, plant_name, state, state_name) %>%
  summarise(
    generation_mwh = sum(generation_mwh, na.rm = TRUE),
    consumption_btu = sum(consumption_btu, na.rm = TRUE),
    total_consumption_btu = sum(total_consumption_btu, na.rm = TRUE),
    fuel_codes = paste(unique(fuel_code), collapse = ","),
    .groups = "drop"
  ) %>%
  mutate(
    heat_rate = ifelse(generation_mwh > 0, consumption_btu / generation_mwh, NA)
  )

cat(sprintf("Plant-year panel: %d rows, %d unique plants, years %d-%d\n",
            nrow(plant_year), n_distinct(plant_year$plant_id),
            min(plant_year$year, na.rm = TRUE), max(plant_year$year, na.rm = TRUE)))

saveRDS(plant_year, file.path(data_dir, "coal_plant_year.rds"))
saveRDS(facility_fuel, file.path(data_dir, "facility_fuel_raw.rds"))

# -----------------------------------------------------------------------
# 2. Operating Generator Capacity: Current generators with characteristics
# -----------------------------------------------------------------------
cat("\n=== Fetching Operating Coal Generators ===\n")

fetch_eia_generators <- function(api_key, fuel_type, state_id, offset = 0, length = 5000) {
  url <- "https://api.eia.gov/v2/electricity/operating-generator-capacity/data/"
  params <- list(
    api_key = api_key,
    frequency = "monthly",
    `data[0]` = "nameplate-capacity-mw",
    `data[1]` = "net-summer-capacity-mw",
    `data[2]` = "operating-year-month",
    `data[3]` = "county",
    `data[4]` = "latitude",
    `data[5]` = "longitude",
    `facets[energy_source_code][]` = fuel_type,
    `facets[stateid][]` = state_id,
    start = "2025-11",
    end = "2025-12",
    offset = offset,
    length = length
  )
  resp <- GET(url, query = params)
  if (status_code(resp) != 200) {
    return(NULL)
  }
  content(resp, as = "parsed")
}

# Get list of states with coal plants from facility-fuel data
coal_states <- unique(plant_year$state)
coal_states <- coal_states[!is.na(coal_states) & nchar(coal_states) == 2]
cat(sprintf("  Querying %d coal states...\n", length(coal_states)))

gen_records <- list()
for (fuel in c("BIT", "SUB", "LIG")) {
  for (st in coal_states) {
    result <- fetch_eia_generators(EIA_API_KEY, fuel, st, offset = 0, length = 5000)
    if (is.null(result)) next
    records <- result$response$data
    if (length(records) > 0) {
      gen_records <- c(gen_records, records)
    }
    Sys.sleep(0.15)
  }
  cat(sprintf("  %s: cumulative %d records\n", fuel, length(gen_records)))
}

cat(sprintf("Total generator records: %d\n", length(gen_records)))

if (length(gen_records) == 0) {
  cat("WARNING: No generator records retrieved. Will use facility-fuel data only.\n")
  operating_gens <- tibble(
    plant_id = character(), generator_id = character(), state = character(),
    county = character(), nameplate_mw = numeric(), operating_year = character(),
    latitude = numeric(), longitude = numeric()
  )
  saveRDS(operating_gens, file.path(data_dir, "operating_coal_generators.rds"))
} else {

operating_gens <- bind_rows(lapply(gen_records, function(r) {
  tibble(
    period = as.character(r$period %||% NA),
    plant_id = as.character(r$plantid %||% NA),
    plant_name = as.character(r$plantName %||% NA),
    generator_id = as.character(r$generatorid %||% NA),
    state = as.character(r$stateid %||% NA),
    state_name = as.character(r$stateName %||% NA),
    county = as.character(r$county %||% NA),
    status = as.character(r$status %||% NA),
    status_desc = as.character(r$statusDescription %||% NA),
    nameplate_mw = as.numeric(r$`nameplate-capacity-mw` %||% NA),
    summer_mw = as.numeric(r$`net-summer-capacity-mw` %||% NA),
    fuel_code = as.character(r$energy_source_code %||% NA),
    operating_year = as.character(r$`operating-year-month` %||% NA),
    sector = as.character(r$sectorName %||% NA),
    entity_name = as.character(r$entityName %||% NA),
    balancing_auth = as.character(r$balancing_authority_code %||% NA),
    technology = as.character(r$technology %||% NA),
    latitude = as.numeric(r$latitude %||% NA),
    longitude = as.numeric(r$longitude %||% NA)
  )
}))

# Keep most recent snapshot per generator
operating_gens <- operating_gens %>%
  group_by(plant_id, generator_id) %>%
  filter(period == max(period)) %>%
  ungroup()

cat(sprintf("Operating coal generators: %d plant-generator combos, %d plants\n",
            nrow(operating_gens), n_distinct(operating_gens$plant_id)))

saveRDS(operating_gens, file.path(data_dir, "operating_coal_generators.rds"))
}  # end else for gen_records

# -----------------------------------------------------------------------
# 3. Retail Electricity Prices (state-level, annual)
# -----------------------------------------------------------------------
cat("\n=== Fetching Retail Electricity Prices ===\n")

fetch_prices <- function(api_key, sector, offset = 0, length = 5000) {
  url <- "https://api.eia.gov/v2/electricity/retail-sales/data/"
  params <- list(
    api_key = api_key,
    frequency = "annual",
    `data[0]` = "price",
    `data[1]` = "revenue",
    `data[2]` = "sales",
    `data[3]` = "customers",
    `facets[sectorid][]` = sector,
    start = "2001",
    end = "2024",
    offset = offset,
    length = length
  )
  resp <- GET(url, query = params)
  if (status_code(resp) != 200) stop("Price API returned status ", status_code(resp))
  content(resp, as = "parsed")
}

# Fetch all sectors: RES (residential), COM (commercial), IND (industrial), ALL
price_records <- list()
for (sector in c("RES", "COM", "IND", "ALL")) {
  cat(sprintf("  Fetching %s prices...\n", sector))
  offset <- 0
  repeat {
    result <- fetch_prices(EIA_API_KEY, sector, offset = offset, length = 5000)
    records <- result$response$data
    if (length(records) == 0) break
    price_records <- c(price_records, records)
    total_avail <- as.integer(result$response$total)
    if (length(price_records) >= total_avail) break
    offset <- offset + 5000
    Sys.sleep(0.3)
  }
}

eia_prices <- bind_rows(lapply(price_records, function(r) {
  tibble(
    year = as.integer(r$period %||% NA),
    state_id = as.character(r$stateid %||% NA),
    state_name = as.character(r$stateDescription %||% NA),
    sector = as.character(r$sectorid %||% NA),
    sector_name = as.character(r$sectorName %||% NA),
    price_cents_kwh = as.numeric(r$price %||% NA),
    revenue_thou = as.numeric(r$revenue %||% NA),
    sales_mwh = as.numeric(r$sales %||% NA),
    customers = as.numeric(r$customers %||% NA)
  )
}))

cat(sprintf("Electricity prices: %d rows, %d states, years %d-%d\n",
            nrow(eia_prices), n_distinct(eia_prices$state_id),
            min(eia_prices$year, na.rm = TRUE), max(eia_prices$year, na.rm = TRUE)))

saveRDS(eia_prices, file.path(data_dir, "eia_retail_prices.rds"))

# -----------------------------------------------------------------------
# 4. State coal generation share (computed from facility-fuel data)
#    We use facility-fuel coal generation / retail sales as coal share proxy
# -----------------------------------------------------------------------
cat("\n=== Computing State Coal Generation Share ===\n")

# State-level coal generation from facility-fuel data
state_coal_gen <- plant_year %>%
  group_by(year, state) %>%
  summarise(coal_gen_mwh = sum(generation_mwh, na.rm = TRUE), .groups = "drop")

# State-level total sales from retail prices (ALL sector)
state_sales <- eia_prices %>%
  filter(sector == "ALL", !is.na(sales_mwh)) %>%
  select(year, state_id, sales_mwh) %>%
  rename(state = state_id)

# Compute coal share = coal generation / total retail sales
state_coal_share <- state_coal_gen %>%
  left_join(state_sales, by = c("year", "state")) %>%
  mutate(coal_share = coal_gen_mwh / sales_mwh)

cat(sprintf("State-coal-share panel: %d rows, %d states\n",
            nrow(state_coal_share), n_distinct(state_coal_share$state)))

saveRDS(state_coal_share, file.path(data_dir, "state_coal_share.rds"))

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("  Coal plant-year panel: %d rows, %d plants\n",
            nrow(plant_year), n_distinct(plant_year$plant_id)))
cat(sprintf("  Operating generators: %d\n", nrow(operating_gens)))
cat(sprintf("  Electricity prices: %d rows\n", nrow(eia_prices)))
cat(sprintf("  State generation: %d rows\n", nrow(state_gen)))
cat("\nAll data fetched successfully from EIA API.\n")
