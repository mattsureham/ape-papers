source("00_packages.R")

cat("=== Constructing analysis panel ===\n")

# --- Load raw data ---
emp_de <- readRDS("../data/eurostat_employment_nuts3.rds")
gdp_de <- readRDS("../data/eurostat_gdp_nuts3.rds")
pop_de <- readRDS("../data/eurostat_population_nuts3.rds")
unemp_de <- readRDS("../data/eurostat_unemployment_nuts2.rds")
foreign_de <- readRDS("../data/eurostat_foreign_pop_nuts3.rds")

# --- Treatment assignment ---
# Control = NUTS-3 regions in Agenturbezirke that RETAINED the Vorrangpruefung
#
# Mecklenburg-Vorpommern: ALL 5 Agenturbezirke retained it.
# All MV NUTS-3 codes start with DE80.
#
# NRW Ruhr: 7 Agenturbezirke retained it (Bochum, Dortmund, Duisburg, Essen,
# Gelsenkirchen, Oberhausen, Recklinghausen). These are kreisfreie Staedte
# and Kreise in the Ruhr area.
#
# Bavaria: 11 Agenturbezirke retained it. These span Kreise around each named city.
# We map conservatively using the NUTS-3 codes for the cities and their surrounding Kreise.

# MV: all DE80x codes
mv_nuts3 <- emp_de %>%
  filter(str_detect(geo, "^DE80")) %>%
  distinct(geo) %>%
  pull(geo)

# NRW Ruhr cities and their Kreise (NUTS-3 codes)
# DEA51 = Bochum, DEA52 = Dortmund, DEA12 = Duisburg, DEA13 = Essen
# DEA32 = Gelsenkirchen, DEA14 = Oberhausen (Muelheim), DEA36 = Recklinghausen
# Also include surrounding Ruhr Kreise that fall under these Agenturbezirke
nrw_ruhr_nuts3 <- c(
  "DEA51",  # Bochum
  "DEA52",  # Dortmund
  "DEA12",  # Duisburg
  "DEA13",  # Essen
  "DEA32",  # Gelsenkirchen
  "DEA16",  # Oberhausen
  "DEA36",  # Recklinghausen (Kreis)
  "DEA53",  # Hagen (under Bochum Agenturbezirk)
  "DEA54",  # Hamm (under Dortmund Agenturbezirk)
  "DEA55",  # Herne (under Gelsenkirchen Agenturbezirk)
  "DEA15",  # Muelheim an der Ruhr (under Oberhausen Agenturbezirk)
  "DEA17",  # Krefeld (under Duisburg Agenturbezirk)
  "DEA31"   # Bottrop (under Recklinghausen Agenturbezirk)
)

# Bavaria: 11 Agenturbezirke retained based on unemployment > 3.6%
# Each named Agenturbezirk encompasses the city and surrounding Kreise
bavaria_retained_nuts3 <- c(
  # Aschaffenburg
  "DE261", "DE264",
  # Bayreuth-Hof
  "DE242", "DE244", "DE249", "DE24A", "DE24D",
  # Bamberg-Coburg
  "DE241", "DE243", "DE245", "DE24B", "DE24C",
  # Fuerth
  "DE258", "DE25A", "DE25B",
  # Nuernberg
  "DE254", "DE259", "DE25C",
  # Schweinfurt
  "DE262", "DE268", "DE269", "DE26A",
  # Weiden
  "DE233", "DE239", "DE23A",
  # Augsburg
  "DE271", "DE275", "DE276",
  # Muenchen
  "DE212", "DE21F", "DE21H", "DE21K",
  # Passau
  "DE222", "DE228",
  # Traunstein
  "DE21M", "DE21N", "DE229"
)

# Combine all control NUTS-3 codes
control_nuts3 <- unique(c(mv_nuts3, nrw_ruhr_nuts3, bavaria_retained_nuts3))

cat(sprintf("Control NUTS-3 codes: %d\n", length(control_nuts3)))
cat(sprintf("  MV: %d, NRW Ruhr: %d, Bavaria: %d\n",
            length(mv_nuts3), length(nrw_ruhr_nuts3), length(bavaria_retained_nuts3)))

# --- Build panel ---
all_nuts3 <- emp_de %>% distinct(geo) %>% pull(geo)
cat(sprintf("Total German NUTS-3 regions in data: %d\n", length(all_nuts3)))

panel <- emp_de %>%
  rename(year = time) %>%
  left_join(gdp_de %>% rename(year = time), by = c("geo", "year")) %>%
  left_join(pop_de %>% rename(year = time), by = c("geo", "year")) %>%
  mutate(
    nuts2 = str_sub(geo, 1, 4),
    state = str_sub(geo, 1, 3)
  ) %>%
  left_join(unemp_de %>% rename(year = time, nuts2 = geo_nuts2), by = c("nuts2", "year"))

if (nrow(foreign_de) > 0) {
  panel <- panel %>%
    left_join(foreign_de %>% rename(year = time), by = c("geo", "year"))
} else {
  panel$foreign_total <- NA_real_
  panel$national <- NA_real_
  panel$non_eu_foreign <- NA_real_
}

panel <- panel %>%
  mutate(
    suspended = if_else(geo %in% control_nuts3, 0L, 1L),
    post = if_else(year >= 2017, 1L, 0L),
    treat_post = suspended * post
  )

# Create state labels
state_labels <- c(
  "DE1" = "Baden-Wuerttemberg", "DE2" = "Bayern", "DE3" = "Berlin",
  "DE4" = "Brandenburg", "DE5" = "Bremen", "DE6" = "Hamburg",
  "DE7" = "Hessen", "DE8" = "Mecklenburg-Vorpommern", "DE9" = "Niedersachsen",
  "DEA" = "Nordrhein-Westfalen", "DEB" = "Rheinland-Pfalz", "DEC" = "Saarland",
  "DED" = "Sachsen", "DEE" = "Sachsen-Anhalt", "DEF" = "Schleswig-Holstein",
  "DEG" = "Thueringen"
)
panel$state_name <- state_labels[panel$state]

# Control group type
panel <- panel %>%
  mutate(
    control_type = case_when(
      suspended == 1 ~ "treated",
      state == "DE8" ~ "MV",
      state == "DEA" & geo %in% nrw_ruhr_nuts3 ~ "NRW_Ruhr",
      state == "DE2" & geo %in% bavaria_retained_nuts3 ~ "Bavaria",
      TRUE ~ "treated"
    )
  )

# Derived outcomes
panel <- panel %>%
  mutate(
    emp_per_capita = if_else(!is.na(pop) & pop > 0,
                            emp_ths * 1000 / pop, NA_real_),
    gdp_per_capita = if_else(!is.na(pop) & pop > 0,
                            gdp_mio * 1e6 / pop, NA_real_),
    foreign_share = if_else(!is.na(pop) & pop > 0 & !is.na(foreign_total),
                           foreign_total / pop, NA_real_),
    log_emp = log(emp_ths),
    log_gdp = if_else(!is.na(gdp_mio) & gdp_mio > 0, log(gdp_mio), NA_real_),
    log_pop = if_else(!is.na(pop) & pop > 0, log(pop), NA_real_)
  )

# Bavaria RDD running variable: distance from 3.6% unemployment threshold
# Use 2015 unemployment (last pre-treatment year available at NUTS-2)
bavaria_unemp_2015 <- unemp_de %>%
  filter(time == 2015, str_detect(geo_nuts2, "^DE2")) %>%
  mutate(unemp_dist_36 = unemp_rate - 3.6)

panel <- panel %>%
  left_join(
    bavaria_unemp_2015 %>% select(nuts2 = geo_nuts2, unemp_dist_36),
    by = "nuts2"
  )

# --- Validate panel ---
n_treated <- panel %>% filter(suspended == 1) %>% distinct(geo) %>% nrow()
n_control <- panel %>% filter(suspended == 0) %>% distinct(geo) %>% nrow()
n_years <- n_distinct(panel$year)

cat(sprintf("\n=== Panel constructed ===\n"))
cat(sprintf("Treated NUTS-3: %d\n", n_treated))
cat(sprintf("Control NUTS-3: %d\n", n_control))
cat(sprintf("Years: %d (%d-%d)\n", n_years, min(panel$year), max(panel$year)))
cat(sprintf("Total obs: %d\n", nrow(panel)))

stopifnot("Need >=20 treated units" = n_treated >= 20)
stopifnot("Need >=5 pre-treatment years" = sum(unique(panel$year) < 2017) >= 4)

# Treatment-control balance check
balance <- panel %>%
  filter(year == 2015) %>%
  group_by(suspended) %>%
  summarise(
    n = n(),
    mean_emp = mean(emp_ths, na.rm = TRUE),
    mean_gdp = mean(gdp_mio, na.rm = TRUE),
    mean_pop = mean(pop, na.rm = TRUE),
    mean_unemp = mean(unemp_rate, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPre-treatment balance (2015):\n")
print(balance)

saveRDS(panel, "../data/analysis_panel.rds")
cat("\nPanel saved to data/analysis_panel.rds\n")
