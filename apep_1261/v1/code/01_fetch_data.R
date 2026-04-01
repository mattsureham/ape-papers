## 01_fetch_data.R — Fetch Eurostat data for Italy AUU fertility analysis
source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# ---------------------------------------------------------------
# 1. NUTS3 live births (demo_r_gind3) — Italy + EU comparators
# ---------------------------------------------------------------
cat("Fetching NUTS3 births (demo_r_gind3)...\n")
births_raw <- get_eurostat("demo_r_gind3", time_format = "num")

if (is.null(births_raw) || nrow(births_raw) == 0) {
  stop("FATAL: Failed to fetch demo_r_gind3 from Eurostat. Cannot proceed without birth data.")
}
cat(sprintf("  Retrieved %d rows from demo_r_gind3\n", nrow(births_raw)))

# Keep total births (TOTL indicator) for relevant countries
# Italy (IT), Spain (ES), France (FR), Germany (DE), Portugal (PT), Greece (EL)
countries <- c("IT", "ES", "FR", "DE", "PT", "EL")
births <- births_raw %>%
  filter(
    indic_de == "GBIRTHRT",
    str_sub(geo, 1, 2) %in% countries,
    nchar(geo) >= 4  # NUTS3 level (5 chars for most, 4 for some)
  ) %>%
  rename(year = TIME_PERIOD, nuts3 = geo, birth_rate = values) %>%
  filter(year >= 2010 & year <= 2023)

cat(sprintf("  Filtered to %d NUTS3-year observations across %s\n",
            nrow(births), paste(countries, collapse = ", ")))

# Also get absolute birth counts
births_abs <- births_raw %>%
  filter(
    indic_de == "LBIRTH",
    str_sub(geo, 1, 2) %in% countries,
    nchar(geo) >= 4
  ) %>%
  rename(year = TIME_PERIOD, nuts3 = geo, births = values) %>%
  filter(year >= 2010 & year <= 2023)

cat(sprintf("  Birth counts: %d obs\n", nrow(births_abs)))

# ---------------------------------------------------------------
# 2. NUTS3 population (demo_r_pjangroup)
# ---------------------------------------------------------------
cat("Fetching NUTS3 population (demo_r_pjangroup)...\n")
pop_raw <- get_eurostat("demo_r_pjangroup", time_format = "num")

if (is.null(pop_raw) || nrow(pop_raw) == 0) {
  stop("FATAL: Failed to fetch demo_r_pjangroup from Eurostat.")
}
cat(sprintf("  Retrieved %d rows from demo_r_pjangroup\n", nrow(pop_raw)))

# Total population and women of childbearing age (15-49)
pop_total <- pop_raw %>%
  filter(
    sex == "T", age == "TOTAL",
    str_sub(geo, 1, 2) %in% countries,
    nchar(geo) >= 4
  ) %>%
  rename(year = TIME_PERIOD, nuts3 = geo, pop = values) %>%
  select(nuts3, year, pop) %>%
  filter(year >= 2010 & year <= 2023)

pop_women <- pop_raw %>%
  filter(
    sex == "F",
    age %in% c("Y15-19", "Y20-24", "Y25-29", "Y30-34", "Y35-39", "Y40-44", "Y45-49"),
    str_sub(geo, 1, 2) %in% countries,
    nchar(geo) >= 4
  ) %>%
  rename(year = TIME_PERIOD, nuts3 = geo) %>%
  filter(year >= 2010 & year <= 2023) %>%
  group_by(nuts3, year) %>%
  summarise(women_15_49 = sum(values, na.rm = TRUE), .groups = "drop")

cat(sprintf("  Population: %d obs; Women 15-49: %d obs\n",
            nrow(pop_total), nrow(pop_women)))

# ---------------------------------------------------------------
# 3. NUTS2 employment by professional status (lfst_r_lfe2estat)
# ---------------------------------------------------------------
cat("Fetching NUTS2 employment by status (lfst_r_lfe2estat)...\n")
emp_raw <- get_eurostat("lfst_r_lfe2estat", time_format = "num")

if (is.null(emp_raw) || nrow(emp_raw) == 0) {
  stop("FATAL: Failed to fetch lfst_r_lfe2estat from Eurostat.")
}
cat(sprintf("  Retrieved %d rows from lfst_r_lfe2estat\n", nrow(emp_raw)))

# Self-employed (SELF) and total employed (EMP) for Italian NUTS2
it_emp <- emp_raw %>%
  filter(
    str_sub(geo, 1, 2) == "IT",
    nchar(geo) == 4,  # NUTS2
    sex == "T",
    age == "Y15-64",
    wstatus %in% c("SELF", "EMP")
  ) %>%
  rename(year = TIME_PERIOD, nuts2 = geo) %>%
  filter(year >= 2010 & year <= 2023) %>%
  select(nuts2, year, wstatus, values) %>%
  pivot_wider(names_from = wstatus, values_from = values) %>%
  mutate(self_emp_share = SELF / EMP)

cat(sprintf("  Italian NUTS2 employment: %d obs\n", nrow(it_emp)))

# Pre-reform (2019) self-employment share — the treatment intensity variable
selfemp_2019 <- it_emp %>%
  filter(year == 2019) %>%
  select(nuts2, self_emp_share_2019 = self_emp_share)

cat("  Pre-reform self-employment shares (2019):\n")
print(selfemp_2019 %>% arrange(desc(self_emp_share_2019)))

# ---------------------------------------------------------------
# 4. National births by birth order (demo_fordagec)
# ---------------------------------------------------------------
cat("Fetching national births by order (demo_fordagec)...\n")
order_raw <- get_eurostat("demo_fordagec", time_format = "num")

if (is.null(order_raw) || nrow(order_raw) == 0) {
  cat("  WARNING: demo_fordagec not available. Trying demo_fasec...\n")
  order_raw <- get_eurostat("demo_fasec", time_format = "num")
}

if (!is.null(order_raw) && nrow(order_raw) > 0) {
  it_births_order <- order_raw %>%
    filter(geo == "IT", TIME_PERIOD >= 2010) %>%
    rename(year = TIME_PERIOD)
  cat(sprintf("  Birth order data: %d obs\n", nrow(it_births_order)))
  saveRDS(it_births_order, "../data/births_by_order.rds")
} else {
  cat("  WARNING: Birth order data not available. Will proceed without parity decomposition.\n")
}

# ---------------------------------------------------------------
# 5. Regional controls (GDP, unemployment)
# ---------------------------------------------------------------
cat("Fetching regional GDP (nama_10r_2gdp)...\n")
gdp_raw <- get_eurostat("nama_10r_2gdp", time_format = "num")
if (!is.null(gdp_raw) && nrow(gdp_raw) > 0) {
  gdp <- gdp_raw %>%
    filter(
      unit == "MIO_EUR",
      str_sub(geo, 1, 2) %in% countries,
      nchar(geo) == 4  # NUTS2
    ) %>%
    rename(year = TIME_PERIOD, nuts2 = geo, gdp_mio = values) %>%
    filter(year >= 2010 & year <= 2023) %>%
    select(nuts2, year, gdp_mio)
  cat(sprintf("  GDP: %d obs\n", nrow(gdp)))
} else {
  cat("  WARNING: GDP data not available.\n")
  gdp <- tibble(nuts2 = character(), year = numeric(), gdp_mio = numeric())
}

cat("Fetching unemployment rates (lfst_r_lfu3rt)...\n")
unemp_raw <- get_eurostat("lfst_r_lfu3rt", time_format = "num")
if (!is.null(unemp_raw) && nrow(unemp_raw) > 0) {
  unemp <- unemp_raw %>%
    filter(
      sex == "T", age == "Y15-74",
      isced11 == "TOTAL" | isced11 == "NRP",
      str_sub(geo, 1, 2) %in% countries,
      nchar(geo) == 4
    ) %>%
    rename(year = TIME_PERIOD, nuts2 = geo, unemp_rate = values) %>%
    filter(year >= 2010 & year <= 2023) %>%
    select(nuts2, year, unemp_rate) %>%
    distinct(nuts2, year, .keep_all = TRUE)
  cat(sprintf("  Unemployment: %d obs\n", nrow(unemp)))
} else {
  cat("  WARNING: Unemployment data not available.\n")
  unemp <- tibble(nuts2 = character(), year = numeric(), unemp_rate = numeric())
}

# ---------------------------------------------------------------
# Save all data
# ---------------------------------------------------------------
cat("\nSaving data files...\n")
saveRDS(births, "../data/nuts3_birth_rates.rds")
saveRDS(births_abs, "../data/nuts3_birth_counts.rds")
saveRDS(pop_total, "../data/nuts3_population.rds")
saveRDS(pop_women, "../data/nuts3_women_15_49.rds")
saveRDS(it_emp, "../data/nuts2_employment.rds")
saveRDS(selfemp_2019, "../data/selfemp_2019.rds")
saveRDS(gdp, "../data/nuts2_gdp.rds")
saveRDS(unemp, "../data/nuts2_unemployment.rds")

cat("=== Data fetch complete ===\n")
cat(sprintf("NUTS3 birth rates: %d obs\n", nrow(births)))
cat(sprintf("Italian NUTS2 regions with self-employment data: %d\n", nrow(selfemp_2019)))
