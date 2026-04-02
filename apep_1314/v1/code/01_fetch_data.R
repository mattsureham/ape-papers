## 01_fetch_data.R — Fetch all data sources
## apep_1314: The Prudential Backlash
source("00_packages.R")
setwd("..")

# ============================================================================
# 1. Eurostat — NUTS2 employment by NACE section (financial sector)
# ============================================================================
cat("=== Fetching Eurostat NUTS2 employment data ===\n")

# lfst_r_lfe2en2: Employment by NACE Rev. 2 activity, NUTS 2 regions
emp_raw <- eurostat::get_eurostat("lfst_r_lfe2en2", time_format = "num")
stopifnot("Eurostat employment data must have rows" = nrow(emp_raw) > 0)
cat(sprintf("  Raw employment data: %d rows\n", nrow(emp_raw)))

# Filter to NACE K (financial) and TOTAL, working age, both sexes
emp <- emp_raw |>
  filter(nace_r2 %in% c("K", "TOTAL"),
         age == "Y15-64",
         sex == "T",
         nchar(geo) == 4) |>  # NUTS2 = 4 chars
  select(geo, TIME_PERIOD, nace_r2, values) |>
  rename(nuts2 = geo, year = TIME_PERIOD) |>
  pivot_wider(names_from = nace_r2, values_from = values) |>
  rename(emp_financial = K, emp_total = TOTAL) |>
  mutate(fin_share = emp_financial / emp_total,
         country = substr(nuts2, 1, 2)) |>
  filter(!is.na(emp_financial), !is.na(emp_total))

cat(sprintf("  Cleaned: %d NUTS2-year obs, %d NUTS2 regions, years %d-%d\n",
            nrow(emp), n_distinct(emp$nuts2),
            min(emp$year), max(emp$year)))
stopifnot("Must have NUTS2 employment data" = nrow(emp) > 100)

fwrite(emp, "data/eurostat_employment.csv")

# ============================================================================
# 2. Eurostat — Business demography at NUTS3 (enterprise births/deaths)
# ============================================================================
cat("\n=== Fetching Eurostat business demography data ===\n")

# bd_enace2_r3: Enterprise births/deaths by NACE at NUTS3
bd_raw <- eurostat::get_eurostat("bd_enace2_r3", time_format = "num")
cat(sprintf("  Business demography raw: %d rows\n", nrow(bd_raw)))

# Focus on NACE K (financial) and total, at NUTS2 level
bd <- bd_raw |>
  filter(nace_r2 %in% c("K", "B-S_X_K642"),  # K = financial, B-S_X_K642 = total business
         nchar(geo) == 4,  # NUTS2
         indic_sb %in% c("V11910", "V11920")) |>  # births, deaths
  select(geo, TIME_PERIOD, nace_r2, indic_sb, values) |>
  rename(nuts2 = geo, year = TIME_PERIOD) |>
  mutate(country = substr(nuts2, 1, 2)) |>
  filter(!is.na(values))

cat(sprintf("  Business demography cleaned: %d NUTS2-year obs\n", nrow(bd)))
fwrite(bd, "data/eurostat_business_demography.csv")

# ============================================================================
# 4. Eurostat — NUTS2 control variables
# ============================================================================
cat("\n=== Fetching Eurostat control variables ===\n")

# 4a. Population by age group (elderly share)
cat("  Fetching population...\n")
pop_raw <- eurostat::get_eurostat("demo_r_d2jan", time_format = "num")

# Ages are single-year (Y0, Y1, ..., Y99, TOTAL). Compute 65+ by summing.
pop_ages <- as.numeric(gsub("Y", "", grep("^Y[0-9]+$", unique(pop_raw$age), value = TRUE)))
ages_65plus <- paste0("Y", pop_ages[pop_ages >= 65])

pop <- pop_raw |>
  filter(sex == "T",
         age %in% c("TOTAL", ages_65plus),
         nchar(geo) == 4) |>
  select(geo, TIME_PERIOD, age, values) |>
  rename(nuts2 = geo, year = TIME_PERIOD) |>
  mutate(age_group = ifelse(age == "TOTAL", "total", "elderly")) |>
  group_by(nuts2, year, age_group) |>
  summarise(pop = sum(values, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = age_group, values_from = pop) |>
  rename(pop_total = total, pop_65plus = elderly) |>
  mutate(elderly_share = pop_65plus / pop_total,
         country = substr(nuts2, 1, 2)) |>
  filter(!is.na(pop_total), pop_total > 0)

cat(sprintf("  Population: %d NUTS2-year obs\n", nrow(pop)))
fwrite(pop, "data/eurostat_population.csv")

# 4b. GDP per capita at NUTS2
cat("  Fetching GDP per capita...\n")
gdp_raw <- eurostat::get_eurostat("nama_10r_2gdp", time_format = "num")
gdp <- gdp_raw |>
  filter(unit == "EUR_HAB",
         nchar(geo) == 4) |>
  select(geo, TIME_PERIOD, values) |>
  rename(nuts2 = geo, year = TIME_PERIOD, gdp_pc = values) |>
  mutate(country = substr(nuts2, 1, 2)) |>
  filter(!is.na(gdp_pc))

cat(sprintf("  GDP per capita: %d NUTS2-year obs\n", nrow(gdp)))
fwrite(gdp, "data/eurostat_gdp.csv")

# 4c. Unemployment rate at NUTS2
cat("  Fetching unemployment...\n")
unemp_raw <- eurostat::get_eurostat("lfst_r_lfu3rt", time_format = "num")
unemp <- unemp_raw |>
  filter(sex == "T",
         age == "Y15-74",
         isced11 == "TOTAL",
         nchar(geo) == 4) |>
  select(geo, TIME_PERIOD, values) |>
  rename(nuts2 = geo, year = TIME_PERIOD, unemp_rate = values) |>
  mutate(country = substr(nuts2, 1, 2)) |>
  filter(!is.na(unemp_rate))

cat(sprintf("  Unemployment: %d NUTS2-year obs\n", nrow(unemp)))
fwrite(unemp, "data/eurostat_unemployment.csv")

cat("\n=== All data fetched successfully ===\n")
cat(sprintf("  Total files: %d\n", length(list.files("data/"))))
