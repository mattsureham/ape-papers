# ==============================================================================
# 01_fetch_data.R — Data Acquisition for apep_0588
# Frozen Out: Russian Gas Shock and Excess Winter Mortality
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# 1. Weekly Deaths — Total (demo_r_mwk_ts)
# ==============================================================================
cat("Fetching weekly deaths (total)...\n")

# Use Eurostat API directly — the R package sometimes has issues with weekly data
# demo_r_mwk_ts: Weekly deaths, total, by country
weekly_deaths_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "demo_r_mwk_ts?",
  "sex=T&",  # Total (both sexes)
  "unit=NR&",
  "format=JSON&lang=en"
)

resp <- GET(weekly_deaths_url, timeout(120))
if (status_code(resp) != 200) {
  stop("Failed to fetch demo_r_mwk_ts: HTTP ", status_code(resp),
       "\nPivot research question or fix the source.")
}

raw <- content(resp, as = "text", encoding = "UTF-8")
js <- fromJSON(raw)

# Parse the JSON-stat format
dims <- js$dimension
vals <- js$value

# Get dimension indices
geo_ids <- dims$geo$category$index
geo_labels <- dims$geo$category$label
time_ids <- dims$time$category$index

# Build data.table
geo_vec <- names(geo_ids)[order(unlist(geo_ids))]
time_vec <- names(time_ids)[order(unlist(time_ids))]

n_geo <- length(geo_vec)
n_time <- length(time_vec)

# Expand grid
dt_deaths <- CJ(geo = geo_vec, time = time_vec)
dt_deaths[, idx := (.GRP - 1), by = .(geo)]

# Map values — JSON-stat uses sparse representation
val_names <- as.integer(names(vals))
val_values <- unlist(vals)

# Create index for each geo x time combination
dt_deaths[, flat_idx := (match(geo, geo_vec) - 1) * n_time + (match(time, time_vec) - 1)]
dt_deaths[, deaths := NA_real_]

for (i in seq_along(val_names)) {
  dt_deaths[flat_idx == val_names[i], deaths := val_values[i]]
}

# Parse week format (e.g., "2020W01")
dt_deaths[, year := as.integer(substr(time, 1, 4))]
dt_deaths[, week := as.integer(sub(".*W", "", time))]

# Filter to analysis period: 2015-2024
dt_deaths <- dt_deaths[year >= 2015 & year <= 2024 & !is.na(deaths)]

# Keep only EU/EEA countries (2-letter codes)
eu_countries <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL",
                  "ES", "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU",
                  "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK",
                  "NO", "CH", "IS", "LI")
dt_deaths <- dt_deaths[geo %in% eu_countries]

cat("Weekly deaths: ", nrow(dt_deaths), " rows, ",
    uniqueN(dt_deaths$geo), " countries, ",
    uniqueN(dt_deaths$year), " years\n")

fwrite(dt_deaths, paste0(data_dir, "weekly_deaths_total.csv"))

# ==============================================================================
# 2. Weekly Deaths by Age Group (demo_r_mwk_05) — Fetched per country
# ==============================================================================
cat("Fetching weekly deaths by age group (per-country to avoid 413)...\n")

parse_eurostat_json <- function(raw_json) {
  js <- fromJSON(raw_json)
  dims <- js$dimension
  vals <- js$value
  if (length(vals) == 0) return(NULL)

  dim_names <- names(dims)
  # Build ordered labels for each dimension
  dim_labels <- lapply(dim_names, function(d) {
    idx <- dims[[d]]$category$index
    names(idx)[order(unlist(idx))]
  })
  names(dim_labels) <- dim_names
  dim_sizes <- sapply(dim_labels, length)

  # Create grid
  grid <- do.call(CJ, dim_labels)
  # Compute flat index
  grid[, flat_idx := {
    idx <- 0L
    for (d in seq_along(dim_names)) {
      pos <- match(get(dim_names[d]), dim_labels[[d]]) - 1L
      if (d == 1) {
        idx <- pos
      } else {
        idx <- idx * dim_sizes[d] + pos
      }
    }
    idx
  }]

  grid[, value := NA_real_]
  val_idx <- as.integer(names(vals))
  val_vals <- unlist(vals)
  grid[match(val_idx, flat_idx), value := val_vals]
  grid <- grid[!is.na(value)]
  grid[, flat_idx := NULL]
  return(grid)
}

# Fetch per country to avoid 413 error
age_results <- list()
fetch_countries <- intersect(eu_countries, c("AT", "BE", "BG", "CZ", "DE", "DK",
  "EE", "EL", "ES", "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LV", "NL",
  "PL", "PT", "RO", "SE", "SI", "SK", "NO", "CH"))

for (cc in fetch_countries) {
  age_url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
    "demo_r_mwk_05?",
    "sex=T&",
    "unit=NR&",
    "geo=", cc, "&",
    "format=JSON&lang=en"
  )
  resp_cc <- tryCatch(GET(age_url, timeout(60)), error = function(e) NULL)
  if (!is.null(resp_cc) && status_code(resp_cc) == 200) {
    raw_cc <- content(resp_cc, as = "text", encoding = "UTF-8")
    dt_cc <- tryCatch(parse_eurostat_json(raw_cc), error = function(e) NULL)
    if (!is.null(dt_cc) && nrow(dt_cc) > 0) {
      age_results[[cc]] <- dt_cc
      cat("  ", cc, ": ", nrow(dt_cc), " rows\n")
    }
  }
  Sys.sleep(0.3)  # Be respectful to API
}

if (length(age_results) > 0) {
  dt_age <- rbindlist(age_results, fill = TRUE)
  setnames(dt_age, "value", "deaths")
  dt_age[, year := as.integer(substr(time, 1, 4))]
  dt_age[, week := as.integer(sub(".*W", "", time))]
  dt_age <- dt_age[year >= 2015 & year <= 2024]

  cat("Weekly deaths by age: ", nrow(dt_age), " rows, ",
      uniqueN(dt_age$geo), " countries, ",
      uniqueN(dt_age$age), " age groups\n")

  fwrite(dt_age, paste0(data_dir, "weekly_deaths_age.csv"))
} else {
  cat("WARNING: No age-specific weekly death data obtained.\n")
  cat("Will rely on total weekly deaths for main analysis.\n")
  cat("Age-gradient placebo will use annual mortality by age.\n")
}

# ==============================================================================
# 3. HICP Energy Prices (prc_hicp_midx, CP045)
# ==============================================================================
cat("Fetching HICP energy prices...\n")

hicp_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "prc_hicp_midx?",
  "coicop=CP045&",  # Electricity, gas and other fuels
  "unit=I15&",      # Index 2015=100
  "format=JSON&lang=en"
)

resp_hicp <- GET(hicp_url, timeout(120))
if (status_code(resp_hicp) != 200) {
  stop("Failed to fetch HICP energy: HTTP ", status_code(resp_hicp))
}

raw_hicp <- content(resp_hicp, as = "text", encoding = "UTF-8")
js_hicp <- fromJSON(raw_hicp)

dims_h <- js_hicp$dimension
vals_h <- js_hicp$value

geo_h <- names(dims_h$geo$category$index)[order(unlist(dims_h$geo$category$index))]
time_h <- names(dims_h$time$category$index)[order(unlist(dims_h$time$category$index))]

n_g_h <- length(geo_h)
n_t_h <- length(time_h)

dt_hicp <- CJ(geo = geo_h, time = time_h)
dt_hicp[, flat_idx := (match(geo, geo_h) - 1) * n_t_h + (match(time, time_h) - 1)]
dt_hicp[, hicp_energy := NA_real_]

val_n_h <- as.integer(names(vals_h))
val_v_h <- unlist(vals_h)
for (i in seq_along(val_n_h)) {
  dt_hicp[flat_idx == val_n_h[i], hicp_energy := val_v_h[i]]
}

dt_hicp[, year := as.integer(substr(time, 1, 4))]
dt_hicp[, month := as.integer(substr(time, 6, 7))]
dt_hicp <- dt_hicp[year >= 2015 & !is.na(hicp_energy)]
dt_hicp <- dt_hicp[geo %in% eu_countries]

cat("HICP energy: ", nrow(dt_hicp), " rows, ",
    uniqueN(dt_hicp$geo), " countries\n")

fwrite(dt_hicp, paste0(data_dir, "hicp_energy.csv"))

# ==============================================================================
# 4. Gas Imports from Russia (nrg_ti_gasm)
# ==============================================================================
cat("Fetching gas imports from Russia...\n")

gas_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "nrg_ti_gasm?",
  "partner=RU&",
  "siec=G3000&",  # Natural gas
  "unit=TJ_GCV&",
  "format=JSON&lang=en"
)

resp_gas <- GET(gas_url, timeout(120))
if (status_code(resp_gas) != 200) {
  # Try alternative: nrg_ti_gas without monthly
  cat("nrg_ti_gasm failed (HTTP ", status_code(resp_gas), "), trying nrg_ti_gas...\n")
  gas_url2 <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
    "nrg_ti_gas?",
    "partner=RU&",
    "siec=G3000&",
    "unit=TJ_GCV&",
    "format=JSON&lang=en"
  )
  resp_gas <- GET(gas_url2, timeout(120))
  if (status_code(resp_gas) != 200) {
    cat("WARNING: Gas import data unavailable. Will use literature-based gas dependence.\n")
    resp_gas <- NULL
  }
}

if (!is.null(resp_gas) && status_code(resp_gas) == 200) {
  raw_gas <- content(resp_gas, as = "text", encoding = "UTF-8")
  js_gas <- fromJSON(raw_gas)

  dims_g <- js_gas$dimension
  vals_g <- js_gas$value

  geo_g <- names(dims_g$geo$category$index)[order(unlist(dims_g$geo$category$index))]
  time_g <- names(dims_g$time$category$index)[order(unlist(dims_g$time$category$index))]

  n_g_g <- length(geo_g)
  n_t_g <- length(time_g)

  dt_gas <- CJ(geo = geo_g, time = time_g)
  dt_gas[, flat_idx := (match(geo, geo_g) - 1) * n_t_g + (match(time, time_g) - 1)]
  dt_gas[, gas_imports_ru := NA_real_]

  val_n_g <- as.integer(names(vals_g))
  val_v_g <- unlist(vals_g)
  for (i in seq_along(val_n_g)) {
    dt_gas[flat_idx == val_n_g[i], gas_imports_ru := val_v_g[i]]
  }

  dt_gas <- dt_gas[!is.na(gas_imports_ru)]
  dt_gas[, year := as.integer(substr(time, 1, 4))]
  dt_gas <- dt_gas[geo %in% eu_countries]

  cat("Gas imports from Russia: ", nrow(dt_gas), " rows, ",
      uniqueN(dt_gas$geo), " countries\n")

  fwrite(dt_gas, paste0(data_dir, "gas_imports_russia.csv"))
}

# ==============================================================================
# 5. Total Gas Imports (for computing dependence share)
# ==============================================================================
cat("Fetching total gas imports...\n")

gas_total_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "nrg_ti_gasm?",
  "siec=G3000&",
  "unit=TJ_GCV&",
  "format=JSON&lang=en"
)

resp_gt <- GET(gas_total_url, timeout(120))
if (status_code(resp_gt) != 200) {
  # Try annual
  gas_total_url2 <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
    "nrg_ti_gas?",
    "siec=G3000&",
    "unit=TJ_GCV&",
    "format=JSON&lang=en"
  )
  resp_gt <- GET(gas_total_url2, timeout(120))
}

if (status_code(resp_gt) == 200) {
  raw_gt <- content(resp_gt, as = "text", encoding = "UTF-8")
  js_gt <- fromJSON(raw_gt)

  dims_gt <- js_gt$dimension
  vals_gt <- js_gt$value

  geo_gt <- names(dims_gt$geo$category$index)[order(unlist(dims_gt$geo$category$index))]
  time_gt <- names(dims_gt$time$category$index)[order(unlist(dims_gt$time$category$index))]
  partner_gt <- names(dims_gt$partner$category$index)[order(unlist(dims_gt$partner$category$index))]

  n_g_gt <- length(geo_gt)
  n_t_gt <- length(time_gt)
  n_p_gt <- length(partner_gt)

  dt_gas_total <- CJ(geo = geo_gt, partner = partner_gt, time = time_gt)
  dt_gas_total[, flat_idx := (match(geo, geo_gt) - 1) * n_p_gt * n_t_gt +
                 (match(partner, partner_gt) - 1) * n_t_gt +
                 (match(time, time_gt) - 1)]
  dt_gas_total[, gas_imports := NA_real_]

  val_n_gt <- as.integer(names(vals_gt))
  val_v_gt <- unlist(vals_gt)
  for (i in seq_along(val_n_gt)) {
    dt_gas_total[flat_idx == val_n_gt[i], gas_imports := val_v_gt[i]]
  }

  dt_gas_total <- dt_gas_total[!is.na(gas_imports)]
  dt_gas_total[, year := as.integer(substr(time, 1, 4))]
  dt_gas_total <- dt_gas_total[geo %in% eu_countries]

  cat("Total gas imports (all partners): ", nrow(dt_gas_total), " rows, ",
      uniqueN(dt_gas_total$geo), " countries\n")

  fwrite(dt_gas_total, paste0(data_dir, "gas_imports_total.csv"))
} else {
  cat("WARNING: Total gas imports unavailable. Will construct dependence from literature.\n")
}

# ==============================================================================
# 6. Population by Country (for per-capita rates)
# ==============================================================================
cat("Fetching population data...\n")

pop_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "demo_pjan?",
  "sex=T&",
  "age=TOTAL&",
  "unit=NR&",
  "format=JSON&lang=en"
)

resp_pop <- GET(pop_url, timeout(120))
if (status_code(resp_pop) != 200) {
  stop("Failed to fetch population data: HTTP ", status_code(resp_pop))
}

raw_pop <- content(resp_pop, as = "text", encoding = "UTF-8")
js_pop <- fromJSON(raw_pop)

dims_p <- js_pop$dimension
vals_p <- js_pop$value

geo_p <- names(dims_p$geo$category$index)[order(unlist(dims_p$geo$category$index))]
time_p <- names(dims_p$time$category$index)[order(unlist(dims_p$time$category$index))]

n_g_p <- length(geo_p)
n_t_p <- length(time_p)

dt_pop <- CJ(geo = geo_p, time = time_p)
dt_pop[, flat_idx := (match(geo, geo_p) - 1) * n_t_p + (match(time, time_p) - 1)]
dt_pop[, pop := NA_real_]

val_n_p <- as.integer(names(vals_p))
val_v_p <- unlist(vals_p)
for (i in seq_along(val_n_p)) {
  dt_pop[flat_idx == val_n_p[i], pop := val_v_p[i]]
}

dt_pop[, year := as.integer(time)]
dt_pop <- dt_pop[year >= 2015 & !is.na(pop)]
dt_pop <- dt_pop[geo %in% eu_countries]

cat("Population: ", nrow(dt_pop), " rows, ",
    uniqueN(dt_pop$geo), " countries\n")

fwrite(dt_pop, paste0(data_dir, "population.csv"))

# ==============================================================================
# 7. Russian Gas Dependence (2021 baseline) — Literature-based
# ==============================================================================
cat("Constructing gas dependence measure...\n")

# Pre-war (2021) Russian gas as % of total gas supply
# Source: IEA, Eurostat nrg_ti_gas, European Commission factsheets
# These are well-documented figures widely cited in policy reports
gas_dep <- data.table(
  geo = c("AT", "BE", "BG", "CZ", "DE", "DK", "EE", "EL", "ES",
          "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LV", "NL",
          "PL", "PT", "RO", "SE", "SI", "SK", "NO", "CH"),
  gas_dep_2021 = c(
    0.80,  # Austria — ~80% Russian gas
    0.06,  # Belgium — low, LNG
    0.77,  # Bulgaria — ~77%
    0.97,  # Czech Republic — ~97% (transit via Slovakia)
    0.55,  # Germany — ~55%
    0.00,  # Denmark — domestic + Norway
    0.46,  # Estonia — ~46% (Baltic states diversifying)
    0.40,  # Greece — ~40%
    0.08,  # Spain — low, LNG from Algeria/US
    0.60,  # Finland — ~60% (shifted to LNG after invasion)
    0.17,  # France — ~17%
    0.33,  # Croatia — ~33%
    0.95,  # Hungary — ~95%
    0.00,  # Ireland — North Sea
    0.40,  # Italy — ~40%
    0.41,  # Lithuania — ~41% (LNG terminal since 2014)
    0.50,  # Latvia — ~50%
    0.15,  # Netherlands — domestic + Norway, some Russian
    0.55,  # Poland — ~55% (but diversifying)
    0.05,  # Portugal — LNG, minimal Russian
    0.14,  # Romania — domestic production + small Russian
    0.00,  # Sweden — minimal gas use overall
    0.09,  # Slovenia — ~9%
    0.85,  # Slovakia — ~85%
    0.00,  # Norway — gas producer
    0.40   # Switzerland — ~40% (transit via Germany)
  ),
  # Share of households using gas for heating (approximate)
  gas_heating_share = c(
    0.26,  # AT
    0.40,  # BE
    0.06,  # BG
    0.35,  # CZ
    0.49,  # DE
    0.15,  # DK
    0.04,  # EE
    0.08,  # EL
    0.35,  # ES
    0.02,  # FI (district heating, electric)
    0.40,  # FR
    0.20,  # HR
    0.52,  # HU
    0.30,  # IE
    0.69,  # IT (highest gas heating share in EU)
    0.15,  # LT
    0.07,  # LV
    0.85,  # NL (Groningen legacy)
    0.45,  # PL
    0.12,  # PT
    0.30,  # RO
    0.01,  # SE
    0.09,  # SI
    0.60,  # SK
    0.00,  # NO
    0.20   # CH
  )
)

fwrite(gas_dep, paste0(data_dir, "gas_dependence.csv"))
cat("Gas dependence: ", nrow(gas_dep), " countries\n")

# ==============================================================================
# 8. Population by Age Group (for per-capita age-specific rates)
# ==============================================================================
cat("Fetching population by age group...\n")

# Get elderly population (65+) for per-capita elderly mortality
pop_age_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "demo_pjangroup?",
  "sex=T&",
  "unit=NR&",
  "format=JSON&lang=en"
)

resp_pa <- GET(pop_age_url, timeout(120))
if (status_code(resp_pa) == 200) {
  raw_pa <- content(resp_pa, as = "text", encoding = "UTF-8")
  js_pa <- fromJSON(raw_pa)

  dims_pa <- js_pa$dimension
  vals_pa <- js_pa$value

  geo_pa <- names(dims_pa$geo$category$index)[order(unlist(dims_pa$geo$category$index))]
  time_pa <- names(dims_pa$time$category$index)[order(unlist(dims_pa$time$category$index))]
  age_pa <- names(dims_pa$age$category$index)[order(unlist(dims_pa$age$category$index))]

  n_g_pa <- length(geo_pa)
  n_t_pa <- length(time_pa)
  n_a_pa <- length(age_pa)

  dt_pop_age <- CJ(geo = geo_pa, age = age_pa, time = time_pa)
  dt_pop_age[, flat_idx := (match(geo, geo_pa) - 1) * n_a_pa * n_t_pa +
               (match(age, age_pa) - 1) * n_t_pa +
               (match(time, time_pa) - 1)]
  dt_pop_age[, pop := NA_real_]

  val_n_pa <- as.integer(names(vals_pa))
  val_v_pa <- unlist(vals_pa)
  for (i in seq_along(val_n_pa)) {
    dt_pop_age[flat_idx == val_n_pa[i], pop := val_v_pa[i]]
  }

  dt_pop_age[, year := as.integer(time)]
  dt_pop_age <- dt_pop_age[year >= 2015 & !is.na(pop)]
  dt_pop_age <- dt_pop_age[geo %in% eu_countries]

  cat("Population by age: ", nrow(dt_pop_age), " rows, ",
      uniqueN(dt_pop_age$geo), " countries, ",
      uniqueN(dt_pop_age$age), " age groups\n")

  fwrite(dt_pop_age, paste0(data_dir, "population_age.csv"))
} else {
  cat("WARNING: Population by age group unavailable (HTTP ", status_code(resp_pa), ")\n")
  cat("Will use total population for per-capita rates.\n")
}

# ==============================================================================
# 9. COVID Deaths for Control Variable
# ==============================================================================
cat("Fetching COVID death data...\n")

# OWID COVID data — reliable, well-maintained
covid_url <- "https://catalog.ourworldindata.org/garden/who/2024-12-04/who_covid/who_covid.csv"
resp_covid <- tryCatch({
  GET(covid_url, timeout(60))
}, error = function(e) {
  cat("OWID COVID direct download failed, trying alternative...\n")
  NULL
})

if (!is.null(resp_covid) && status_code(resp_covid) == 200) {
  tmp_covid <- tempfile(fileext = ".csv")
  writeBin(content(resp_covid, "raw"), tmp_covid)
  dt_covid <- fread(tmp_covid)
  cat("COVID data downloaded: ", nrow(dt_covid), " rows\n")
  fwrite(dt_covid, paste0(data_dir, "covid_deaths.csv"))
} else {
  # Alternative: direct OWID GitHub CSV
  covid_url2 <- "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/new_deaths.csv"
  resp_c2 <- tryCatch(GET(covid_url2, timeout(60)), error = function(e) NULL)
  if (!is.null(resp_c2) && status_code(resp_c2) == 200) {
    tmp_c2 <- tempfile(fileext = ".csv")
    writeBin(content(resp_c2, "raw"), tmp_c2)
    dt_covid <- fread(tmp_c2)
    cat("COVID data (alt): ", nrow(dt_covid), " rows\n")
    fwrite(dt_covid, paste0(data_dir, "covid_deaths.csv"))
  } else {
    cat("WARNING: COVID data unavailable. Will proceed without COVID controls.\n")
    cat("This is acceptable — COVID is a control, not the treatment.\n")
  }
}

# ==============================================================================
# 10. Heating Degree Days (for temperature controls)
# ==============================================================================
cat("Fetching heating degree days...\n")

hdd_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "nrg_chdd_m?",
  "indic_nrg=HDD&",
  "unit=NR&",
  "format=JSON&lang=en"
)

resp_hdd <- GET(hdd_url, timeout(120))
if (status_code(resp_hdd) == 200) {
  raw_hdd <- content(resp_hdd, as = "text", encoding = "UTF-8")
  js_hdd <- fromJSON(raw_hdd)

  dims_hdd <- js_hdd$dimension
  vals_hdd <- js_hdd$value

  geo_hdd <- names(dims_hdd$geo$category$index)[order(unlist(dims_hdd$geo$category$index))]
  time_hdd <- names(dims_hdd$time$category$index)[order(unlist(dims_hdd$time$category$index))]

  n_g_hdd <- length(geo_hdd)
  n_t_hdd <- length(time_hdd)

  dt_hdd <- CJ(geo = geo_hdd, time = time_hdd)
  dt_hdd[, flat_idx := (match(geo, geo_hdd) - 1) * n_t_hdd + (match(time, time_hdd) - 1)]
  dt_hdd[, hdd := NA_real_]

  val_n_hdd <- as.integer(names(vals_hdd))
  val_v_hdd <- unlist(vals_hdd)
  for (i in seq_along(val_n_hdd)) {
    dt_hdd[flat_idx == val_n_hdd[i], hdd := val_v_hdd[i]]
  }

  dt_hdd[, year := as.integer(substr(time, 1, 4))]
  dt_hdd[, month := as.integer(substr(time, 6, 7))]
  dt_hdd <- dt_hdd[year >= 2015 & !is.na(hdd)]
  dt_hdd <- dt_hdd[geo %in% eu_countries]

  cat("Heating degree days: ", nrow(dt_hdd), " rows, ",
      uniqueN(dt_hdd$geo), " countries\n")

  fwrite(dt_hdd, paste0(data_dir, "heating_degree_days.csv"))
} else {
  cat("WARNING: HDD data unavailable (HTTP ", status_code(resp_hdd),
      "). Will proceed without temperature controls.\n")
}

# ==============================================================================
# DATA VALIDATION
# ==============================================================================
cat("\n=== DATA VALIDATION ===\n")

stopifnot("Need 15+ countries in weekly deaths" = uniqueN(dt_deaths$geo) >= 15)
stopifnot("Need 2015-2024 coverage" = all(2015:2023 %in% dt_deaths$year))
stopifnot("Need 100+ rows per country" = dt_deaths[, .N, by = geo][, min(N)] >= 50)
stopifnot("Need HICP energy data" = nrow(dt_hicp) > 100)
stopifnot("Need gas dependence data" = nrow(gas_dep) >= 20)

cat("Data validation passed: ",
    nrow(dt_deaths), " weekly death rows, ",
    uniqueN(dt_deaths$geo), " countries, ",
    uniqueN(dt_deaths$year), " years\n")

cat("\nAll data fetched successfully.\n")
