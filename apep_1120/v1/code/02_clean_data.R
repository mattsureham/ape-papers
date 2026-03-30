# apep_1120 - Romanian 2014 EU-2 Restriction Lifting
# 02_clean_data.R - Construct analysis panel and treatment variable

source("code/00_packages.R")

data_dir <- "data"

# ============================================================
# NUTS3-to-county crosswalk
# Romanian NUTS3 codes map 1:1 to counties (judete)
# ============================================================
nuts3_county <- data.frame(
  geo = c("RO111","RO112","RO113","RO114","RO115","RO116",
          "RO121","RO122","RO123","RO124","RO125","RO126",
          "RO211","RO212","RO213","RO214","RO215","RO216",
          "RO221","RO222","RO223","RO224","RO225","RO226",
          "RO311","RO312","RO313","RO314","RO315","RO316","RO317",
          "RO321","RO322",
          "RO411","RO412","RO413","RO414","RO415",
          "RO421","RO422","RO423","RO424"),
  county = c("Bihor","Bistrita-Nasaud","Cluj","Maramures","Satu Mare","Salaj",
             "Alba","Brasov","Covasna","Harghita","Mures","Sibiu",
             "Bacau","Botosani","Iasi","Neamt","Suceava","Vaslui",
             "Braila","Buzau","Constanta","Galati","Tulcea","Vrancea",
             "Arges","Calarasi","Dambovita","Giurgiu","Ialomita","Prahova","Teleorman",
             "Bucuresti","Ilfov",
             "Dolj","Gorj","Mehedinti","Olt","Valcea",
             "Arad","Caras-Severin","Hunedoara","Timis"),
  nuts2 = c(rep("RO11",6), rep("RO12",6), rep("RO21",6), rep("RO22",6),
            rep("RO31",7), rep("RO32",2), rep("RO41",5), rep("RO42",4)),
  region = c(rep("Nord-Vest",6), rep("Centru",6), rep("Nord-Est",6), rep("Sud-Est",6),
             rep("Sud-Muntenia",7), rep("Bucuresti-Ilfov",2), rep("Sud-Vest Oltenia",5),
             rep("Vest",4)),
  stringsAsFactors = FALSE
)

# West/NW indicator (geographically closest to Germany/Austria)
nuts3_county$west_nw <- nuts3_county$region %in% c("Nord-Vest", "Vest", "Centru")

cat("County crosswalk: ", nrow(nuts3_county), " counties\n")

# ============================================================
# 1. GDP per capita panel (proxy for wages)
# ============================================================
cat("\nBuilding GDP per capita panel...\n")

gdp_raw <- readRDS(file.path(data_dir, "eurostat_gdp_nuts3.rds"))

# Use EUR per inhabitant
gdp <- gdp_raw %>%
  filter(unit == "EUR_HAB") %>%
  select(geo, year = TIME_PERIOD, gdp_pc = values) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2000, year <= 2024) %>%
  inner_join(nuts3_county, by = "geo")

cat(sprintf("  GDP panel: %d obs, %d counties, years %d-%d\n",
            nrow(gdp), length(unique(gdp$geo)), min(gdp$year), max(gdp$year)))

# ============================================================
# 2. Population panel
# ============================================================
cat("\nBuilding population panel...\n")

pop_raw <- readRDS(file.path(data_dir, "eurostat_pop_nuts3.rds"))

pop <- pop_raw %>%
  filter(sex == "T", age == "TOTAL") %>%
  select(geo, year = TIME_PERIOD, population = values) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2000, year <= 2024) %>%
  inner_join(nuts3_county, by = "geo")

cat(sprintf("  Population panel: %d obs, %d counties, years %d-%d\n",
            nrow(pop), length(unique(pop$geo)), min(pop$year), max(pop$year)))

# ============================================================
# 3. Employment by sector panel
# ============================================================
cat("\nBuilding employment by sector panel...\n")

empsec_raw <- readRDS(file.path(data_dir, "eurostat_empsec_nuts3.rds"))

# Total employment
emp_total <- empsec_raw %>%
  filter(nace_r2 == "TOTAL", wstatus == "EMP") %>%
  select(geo, year = TIME_PERIOD, employment = values) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2000, year <= 2024) %>%
  inner_join(nuts3_county, by = "geo")

cat(sprintf("  Employment panel: %d obs, %d counties\n",
            nrow(emp_total), length(unique(emp_total$geo))))

# Construction share (NACE F) — proxy for Germany-bound labor type
emp_construction <- empsec_raw %>%
  filter(nace_r2 == "F", wstatus == "EMP") %>%
  select(geo, year = TIME_PERIOD, emp_construction = values) %>%
  mutate(year = as.integer(year))

# Manufacturing share (NACE C)
emp_manufacturing <- empsec_raw %>%
  filter(nace_r2 == "C", wstatus == "EMP") %>%
  select(geo, year = TIME_PERIOD, emp_manufacturing = values) %>%
  mutate(year = as.integer(year))

# ============================================================
# 4. Construct exposure variable θ
# ============================================================
cat("\nConstructing exposure variable theta...\n")

# Approach: Use population decline 2002-2013 as proxy for emigration intensity
# Counties that lost more population (relative to natural change) had more emigration
# This is pre-determined relative to the 2014 shock

pop_wide <- pop %>%
  select(geo, county, year, population) %>%
  filter(year %in% c(2002, 2007, 2013)) %>%
  pivot_wider(names_from = year, values_from = population, names_prefix = "pop_")

# Population change 2002-2013 (net emigration proxy)
pop_wide <- pop_wide %>%
  mutate(
    pop_decline_02_13 = (pop_2002 - pop_2013) / pop_2002,  # Fraction lost
    pop_decline_02_07 = (pop_2002 - pop_2007) / pop_2002,  # Pre-accession
    pop_decline_07_13 = (pop_2007 - pop_2013) / pop_2007   # Post-accession, pre-2014
  )

# Alternative: Use WEST/NW geographic indicator as instrument
# Counties in NW/West regions are historically Germany-oriented
# This is purely geographic and pre-determined

# Merge exposure into county data
county_theta <- pop_wide %>%
  select(geo, county, pop_decline_02_13, pop_decline_02_07, pop_decline_07_13)

cat("  Theta statistics (population decline 2002-2013):\n")
cat(sprintf("    Mean: %.3f, SD: %.3f, Min: %.3f, Max: %.3f\n",
            mean(county_theta$pop_decline_02_13, na.rm = TRUE),
            sd(county_theta$pop_decline_02_13, na.rm = TRUE),
            min(county_theta$pop_decline_02_13, na.rm = TRUE),
            max(county_theta$pop_decline_02_13, na.rm = TRUE)))

# ============================================================
# 5. Merge into analysis panel
# ============================================================
cat("\nMerging analysis panel...\n")

panel <- gdp %>%
  select(geo, county, region, west_nw, year, gdp_pc) %>%
  left_join(emp_total %>% select(geo, year, employment), by = c("geo", "year")) %>%
  left_join(pop %>% select(geo, year, population), by = c("geo", "year")) %>%
  left_join(emp_construction %>% select(geo, year, emp_construction), by = c("geo", "year")) %>%
  left_join(emp_manufacturing %>% select(geo, year, emp_manufacturing), by = c("geo", "year")) %>%
  left_join(county_theta %>% select(geo, pop_decline_02_13, pop_decline_07_13), by = "geo") %>%
  mutate(
    post2014 = as.integer(year >= 2014),
    theta_x_post = pop_decline_02_13 * post2014,
    log_gdp_pc = log(gdp_pc),
    log_employment = log(employment),
    log_population = log(population),
    construction_share = emp_construction / employment,
    manufacturing_share = emp_manufacturing / employment,
    emp_per_cap = employment / population * 1000
  )

cat(sprintf("  Analysis panel: %d obs, %d counties, %d years\n",
            nrow(panel), length(unique(panel$geo)), length(unique(panel$year))))

# Check balance
year_counts <- panel %>% group_by(year) %>% summarize(n = n(), .groups = "drop")
cat("  Observations per year:\n")
for (i in 1:nrow(year_counts)) {
  cat(sprintf("    %d: %d counties\n", year_counts$year[i], year_counts$n[i]))
}

# ============================================================
# 6. Save panel
# ============================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
write.csv(panel, file.path(data_dir, "analysis_panel.csv"), row.names = FALSE)
cat(sprintf("\nSaved analysis_panel.rds (%d rows)\n", nrow(panel)))

# ============================================================
# 7. Diagnostics
# ============================================================
n_treated <- sum(panel$pop_decline_02_13 > median(panel$pop_decline_02_13, na.rm = TRUE), na.rm = TRUE)
n_pre <- length(unique(panel$year[panel$year < 2014]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = length(unique(panel$geo)),
  year_range = paste(range(panel$year), collapse = "-"),
  theta_variable = "pop_decline_02_13"
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics:\n")
cat(sprintf("  n_treated (above-median theta): %d\n", n_treated))
cat(sprintf("  n_pre: %d years\n", n_pre))
cat(sprintf("  n_obs: %d\n", n_obs))
