# apep_1120 - Romanian 2014 EU-2 Restriction Lifting
# 03_main_analysis.R - Main regressions + first stage + event study

source("code/00_packages.R")

data_dir <- "data"

# ============================================================
# Load and prepare data
# ============================================================
cat("Loading data...\n")

# Employment by sector (2000-2024, full coverage)
empsec <- readRDS(file.path(data_dir, "eurostat_empsec_nuts3.rds"))

# Population (1995-2025)
pop_raw <- readRDS(file.path(data_dir, "eurostat_pop_nuts3.rds"))

# GDP (2000-2001 + 2012-2024)
gdp_raw <- readRDS(file.path(data_dir, "eurostat_gdp_nuts3.rds"))

# County crosswalk
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
  region = c(rep("Nord-Vest",6), rep("Centru",6), rep("Nord-Est",6), rep("Sud-Est",6),
             rep("Sud-Muntenia",7), rep("Bucuresti-Ilfov",2), rep("Sud-Vest Oltenia",5),
             rep("Vest",4)),
  west = c(rep(1,6), rep(1,6), rep(0,6), rep(0,6), rep(0,7), rep(0,2), rep(0,5), rep(1,4)),
  stringsAsFactors = FALSE
)

# ============================================================
# Build employment panel
# ============================================================
cat("Building employment panel...\n")

# Total employment
emp <- empsec %>%
  filter(nace_r2 == "TOTAL", wstatus == "EMP") %>%
  select(geo, year = TIME_PERIOD, employment = values) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2000, year <= 2024)

# Construction (NACE F)
emp_f <- empsec %>%
  filter(nace_r2 == "F", wstatus == "EMP") %>%
  select(geo, year = TIME_PERIOD, emp_constr = values) %>%
  mutate(year = as.integer(year))

# Agriculture (NACE A)
emp_a <- empsec %>%
  filter(nace_r2 == "A", wstatus == "EMP") %>%
  select(geo, year = TIME_PERIOD, emp_agri = values) %>%
  mutate(year = as.integer(year))

# Population
pop <- pop_raw %>%
  filter(sex == "T", age == "TOTAL") %>%
  select(geo, year = TIME_PERIOD, population = values) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2000, year <= 2024)

# GDP per capita (limited years)
gdp <- gdp_raw %>%
  filter(unit == "EUR_HAB") %>%
  select(geo, year = TIME_PERIOD, gdp_pc = values) %>%
  mutate(year = as.integer(year))

# ============================================================
# Construct θ: population decline 2002-2013
# ============================================================
cat("Constructing theta (exposure variable)...\n")

theta_data <- pop %>%
  filter(year %in% c(2002, 2013)) %>%
  tidyr::pivot_wider(names_from = year, values_from = population, names_prefix = "pop_") %>%
  mutate(theta = (pop_2002 - pop_2013) / pop_2002) %>%
  select(geo, theta)

# Merge and build panel
panel <- emp %>%
  inner_join(nuts3_county, by = "geo") %>%
  left_join(pop %>% select(geo, year, population), by = c("geo", "year")) %>%
  left_join(emp_f %>% select(geo, year, emp_constr), by = c("geo", "year")) %>%
  left_join(emp_a %>% select(geo, year, emp_agri), by = c("geo", "year")) %>%
  left_join(gdp %>% select(geo, year, gdp_pc), by = c("geo", "year")) %>%
  left_join(theta_data, by = "geo") %>%
  mutate(
    post = as.integer(year >= 2014),
    theta_x_post = theta * post,
    log_emp = log(employment),
    log_pop = log(population),
    log_gdp_pc = ifelse(!is.na(gdp_pc), log(gdp_pc), NA),
    emp_rate = employment / population * 1000,
    constr_share = emp_constr / employment
  ) %>%
  filter(year >= 2008)  # Focus on 2008-2024 (6 pre, 11 post)

cat(sprintf("Panel: %d obs, %d counties, years %d-%d\n",
            nrow(panel), length(unique(panel$geo)),
            min(panel$year), max(panel$year)))

# Split by theta
panel$high_theta <- as.integer(panel$theta > median(panel$theta, na.rm = TRUE))

cat(sprintf("  High-theta counties: %d, Low-theta counties: %d\n",
            sum(panel$high_theta == 1 & panel$year == 2008),
            sum(panel$high_theta == 0 & panel$year == 2008)))

# ============================================================
# MAIN SPECIFICATION 1: Employment
# log(employment)_ct = alpha_c + lambda_t + beta * (theta_c x Post_t) + eps
# ============================================================
cat("\n=== MAIN RESULTS ===\n")

# Model 1: log employment
m1 <- feols(log_emp ~ theta_x_post | geo + year, data = panel, cluster = ~geo)
cat("\nModel 1: log(Employment) ~ theta x Post\n")
print(summary(m1))

# Model 2: log population
m2 <- feols(log_pop ~ theta_x_post | geo + year, data = panel, cluster = ~geo)
cat("\nModel 2: log(Population) ~ theta x Post\n")
print(summary(m2))

# Model 3: Employment rate
m3 <- feols(emp_rate ~ theta_x_post | geo + year, data = panel, cluster = ~geo)
cat("\nModel 3: Employment rate ~ theta x Post\n")
print(summary(m3))

# Model 4: GDP per capita (limited years: 2012-2024)
panel_gdp <- panel %>% filter(!is.na(log_gdp_pc))
m4 <- feols(log_gdp_pc ~ theta_x_post | geo + year, data = panel_gdp, cluster = ~geo)
cat("\nModel 4: log(GDP per capita) ~ theta x Post (2012-2024 only)\n")
print(summary(m4))

# ============================================================
# EVENT STUDY
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Create year dummies interacted with theta (omit 2013 as base)
panel$year_f <- factor(panel$year)
panel$year_f <- relevel(panel$year_f, ref = "2013")

m_es <- feols(log_emp ~ i(year_f, theta, ref = "2013") | geo + year, data = panel, cluster = ~geo)
cat("\nEvent study: log(Employment) ~ theta x Year\n")
print(summary(m_es))

# ============================================================
# CONTROLS SPECIFICATION
# ============================================================
cat("\n=== WITH CONTROLS ===\n")

# Pre-period characteristics interacted with post
panel <- panel %>%
  group_by(geo) %>%
  mutate(
    initial_emp = employment[year == 2008],
    initial_constr = constr_share[year == 2008]
  ) %>%
  ungroup() %>%
  mutate(
    initial_emp_x_post = log(initial_emp) * post,
    west_x_post = west * post
  )

m5 <- feols(log_emp ~ theta_x_post + initial_emp_x_post + west_x_post | geo + year,
            data = panel, cluster = ~geo)
cat("\nModel 5: With controls (initial employment, west indicator)\n")
print(summary(m5))

# ============================================================
# DDD: Construction vs Services
# ============================================================
cat("\n=== SECTOR HETEROGENEITY ===\n")

# Build sector-level panel
sector_panel <- empsec %>%
  filter(wstatus == "EMP", nace_r2 %in% c("F", "G-I", "C", "O-Q")) %>%
  select(geo, year = TIME_PERIOD, sector = nace_r2, employment = values) %>%
  mutate(year = as.integer(year)) %>%
  filter(year >= 2008) %>%
  inner_join(nuts3_county, by = "geo") %>%
  left_join(theta_data, by = "geo") %>%
  mutate(
    post = as.integer(year >= 2014),
    theta_x_post = theta * post,
    log_emp = log(pmax(employment, 0.01)),
    constr = as.integer(sector == "F"),
    theta_x_post_x_constr = theta * post * constr
  )

m_ddd <- feols(log_emp ~ theta_x_post + theta_x_post_x_constr | geo + year + sector,
               data = sector_panel, cluster = ~geo)
cat("\nDDD: Construction vs other sectors\n")
print(summary(m_ddd))

# ============================================================
# DIAGNOSTICS
# ============================================================
cat("\n=== DIAGNOSTICS ===\n")

diagnostics <- list(
  n_treated = sum(panel$high_theta == 1 & panel$year == 2008, na.rm = TRUE),
  n_pre = length(unique(panel$year[panel$year < 2014])),
  n_obs = nrow(panel),
  n_counties = length(unique(panel$geo)),
  main_coef = coef(m1)["theta_x_post"],
  main_se = sqrt(vcov(m1)["theta_x_post", "theta_x_post"]),
  main_pval = summary(m1)$coeftable["theta_x_post", "Pr(>|t|)"]
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("  Main result (log employment): beta = %.4f (SE = %.4f, p = %.4f)\n",
            diagnostics$main_coef, diagnostics$main_se, diagnostics$main_pval))

# Save key objects for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
             m_es = m_es, m_ddd = m_ddd, panel = panel),
        file.path(data_dir, "main_results.rds"))

cat("\nMain analysis complete.\n")
