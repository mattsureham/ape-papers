source("00_packages.R")

cat("=== Fetching Eurostat NUTS-3 data for Germany ===\n")

# --- 1. NUTS-3 Employment (nama_10r_3empers) ---
cat("\n--- Employment (NUTS-3, total, 2012-2021) ---\n")
emp_raw <- get_eurostat("nama_10r_3empers",
  filters = list(
    nace_r2 = "TOTAL",
    wstatus  = "EMP",
    unit     = "THS"
  ),
  time_format = "num",
  cache = FALSE
)
emp_de <- emp_raw %>%
  filter(str_detect(geo, "^DE"), nchar(geo) == 5, time >= 2012, time <= 2021) %>%
  select(geo, time, emp_ths = values)

cat(sprintf("  Employment: %d records, %d NUTS-3 regions\n",
            nrow(emp_de), n_distinct(emp_de$geo)))

stopifnot("No employment data" = nrow(emp_de) > 0)

# --- 2. NUTS-3 GDP (nama_10r_3gdp) ---
cat("\n--- GDP (NUTS-3, 2012-2021) ---\n")
gdp_raw <- get_eurostat("nama_10r_3gdp",
  filters = list(unit = "MIO_EUR"),
  time_format = "num",
  cache = FALSE
)
gdp_de <- gdp_raw %>%
  filter(str_detect(geo, "^DE"), nchar(geo) == 5, time >= 2012, time <= 2021) %>%
  select(geo, time, gdp_mio = values)

cat(sprintf("  GDP: %d records, %d NUTS-3 regions\n",
            nrow(gdp_de), n_distinct(gdp_de$geo)))

# --- 3. NUTS-3 Population (demo_r_pjangrp3) ---
cat("\n--- Population (NUTS-3, 2012-2021) ---\n")
pop_raw <- get_eurostat("demo_r_pjangrp3",
  filters = list(sex = "T", age = "TOTAL"),
  time_format = "num",
  cache = FALSE
)
pop_de <- pop_raw %>%
  filter(str_detect(geo, "^DE"), nchar(geo) == 5, time >= 2012, time <= 2021) %>%
  select(geo, time, pop = values)

cat(sprintf("  Population: %d records, %d NUTS-3 regions\n",
            nrow(pop_de), n_distinct(pop_de$geo)))

# --- 4. NUTS-2 Unemployment (lfst_r_lfu3rt) ---
cat("\n--- Unemployment rate (NUTS-2, 2012-2021) ---\n")
unemp_raw <- get_eurostat("lfst_r_lfu3rt",
  filters = list(sex = "T", age = "Y15-74", isced11 = "TOTAL", unit = "PC"),
  time_format = "num",
  cache = FALSE
)
unemp_de <- unemp_raw %>%
  filter(str_detect(geo, "^DE"), nchar(geo) == 4, time >= 2012, time <= 2021) %>%
  select(geo_nuts2 = geo, time, unemp_rate = values)

cat(sprintf("  Unemployment: %d records, %d NUTS-2 regions\n",
            nrow(unemp_de), n_distinct(unemp_de$geo_nuts2)))

# --- 5. NUTS-3 Foreign-citizen population (migr_pop1ctz) ---
cat("\n--- Foreign-citizen population (NUTS-3, 2012-2021) ---\n")
foreign_raw <- get_eurostat("migr_pop1ctz",
  filters = list(sex = "T", age = "TOTAL"),
  time_format = "num",
  cache = FALSE
)

foreign_de <- foreign_raw %>%
  filter(str_detect(geo, "^DE"), nchar(geo) == 5, time >= 2012, time <= 2021) %>%
  mutate(citizen_type = case_when(
    citizen == "NAT" ~ "national",
    citizen == "EU27_2020_FOR" ~ "eu_foreign",
    citizen == "NEU27_2020_FOR" ~ "non_eu_foreign",
    citizen == "FOR" ~ "foreign_total",
    TRUE ~ "other"
  )) %>%
  filter(citizen_type %in% c("national", "foreign_total", "non_eu_foreign")) %>%
  select(geo, time, citizen_type, pop_ctz = values) %>%
  pivot_wider(names_from = citizen_type, values_from = pop_ctz)

cat(sprintf("  Foreign pop: %d records, %d NUTS-3 regions\n",
            nrow(foreign_de), n_distinct(foreign_de$geo)))

# --- Save ---
saveRDS(emp_de, "../data/eurostat_employment_nuts3.rds")
saveRDS(gdp_de, "../data/eurostat_gdp_nuts3.rds")
saveRDS(pop_de, "../data/eurostat_population_nuts3.rds")
saveRDS(unemp_de, "../data/eurostat_unemployment_nuts2.rds")
saveRDS(foreign_de, "../data/eurostat_foreign_pop_nuts3.rds")

cat("\n=== All Eurostat data saved ===\n")
cat(sprintf("NUTS-3 regions in employment data: %d\n", n_distinct(emp_de$geo)))
cat(sprintf("Year range: %d-%d\n", min(emp_de$time), max(emp_de$time)))
