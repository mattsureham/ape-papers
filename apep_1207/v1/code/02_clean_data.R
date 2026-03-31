# 02_clean_data.R — Clean and construct analysis datasets
# apep_1207: Thailand Rice Pledging Scheme Collapse

source("00_packages.R")

cat("=== Cleaning data ===\n")

# --- 1. Load raw data ---
wb_raw <- read_csv("../data/wb_raw.csv", show_col_types = FALSE)
rice_prices <- read_csv("../data/rice_prices.csv", show_col_types = FALSE)

# --- 2. Rename and select variables ---
panel <- wb_raw %>%
  transmute(
    country = country,
    iso2c = iso2c,
    year = year,
    cereal_prod = AG.PRD.CREL.MT,
    agri_va_pct = NV.AGR.TOTL.ZS,
    agri_va_const = NV.AGR.TOTL.KD,
    agri_empl_pct = SL.AGR.EMPL.ZS,
    poverty = SI.POV.NAHC,
    rural_pct = SP.RUR.TOTL.ZS,
    gdp_pc = NY.GDP.PCAP.KD,
    cereal_land = AG.LND.CREL.HA,
    cereal_yield = AG.YLD.CREL.KG,
    industry_va_pct = NV.IND.TOTL.ZS,
    services_va_pct = NV.SRV.TOTL.ZS
  ) %>%
  filter(year >= 2003, year <= 2022) %>%
  left_join(rice_prices, by = "year")

# --- 3. Check data coverage ---
coverage <- panel %>%
  group_by(iso2c) %>%
  summarise(
    n_years = n_distinct(year),
    cereal_coverage = sum(!is.na(cereal_prod)),
    agri_va_coverage = sum(!is.na(agri_va_pct)),
    empl_coverage = sum(!is.na(agri_empl_pct)),
    .groups = "drop"
  )

cat("Data coverage by country:\n")
print(as.data.frame(coverage))

# --- 4. Restrict to analysis period and countries with adequate coverage ---
# Analysis window: 2005-2020 (8 pre-treatment years, 7 post-treatment years)
# Treatment onset: 2014 (scheme collapsed late 2013, payments stopped)

analysis_years <- 2005:2020

panel_clean <- panel %>%
  filter(year %in% analysis_years) %>%
  group_by(iso2c) %>%
  # Require at least 12 of 16 years for cereal production
  filter(sum(!is.na(cereal_prod)) >= 12) %>%
  ungroup()

countries_in <- n_distinct(panel_clean$iso2c)
cat(sprintf("\nCountries with adequate cereal data: %d\n", countries_in))
stopifnot("Need at least 8 donor countries" = countries_in >= 9)

# --- 5. Construct analysis variables ---
panel_clean <- panel_clean %>%
  mutate(
    treated = as.integer(iso2c == "TH"),
    post = as.integer(year >= 2014),
    treat_x_post = treated * post,
    country_id = as.integer(factor(iso2c))
  ) %>%
  group_by(iso2c) %>%
  mutate(
    # Normalize cereal production to 2010 = 100 for cross-country comparability
    cereal_2010 = cereal_prod[year == 2010][1],
    cereal_index = (cereal_prod / cereal_2010) * 100,

    # Log cereal production
    ln_cereal = log(cereal_prod),

    # Log GDP per capita
    ln_gdp_pc = log(gdp_pc),

    # Cereal yield index (2010 = 100)
    yield_2010 = cereal_yield[year == 2010][1],
    yield_index = (cereal_yield / yield_2010) * 100,

    # Food production index already standardized by WB (2014-2016 = 100)

    # Log agri VA
    ln_agri_va = log(agri_va_const)
  ) %>%
  ungroup()

# --- 6. Create SCM-formatted dataset ---
# For augsynth: need balanced panel for key outcome
scm_data <- panel_clean %>%
  filter(!is.na(cereal_index)) %>%
  select(iso2c, country, year, treated,
         cereal_index, ln_cereal, cereal_prod,
         agri_va_pct, agri_empl_pct, cereal_yield,
         yield_index, gdp_pc, ln_gdp_pc,
         rural_pct, rice_price_usd, cereal_land,
         industry_va_pct, services_va_pct, ln_agri_va) %>%
  # Ensure balanced panel
  group_by(iso2c) %>%
  filter(n() == length(analysis_years)) %>%
  ungroup()

n_countries_scm <- n_distinct(scm_data$iso2c)
n_years_scm <- n_distinct(scm_data$year)
cat(sprintf("\nSCM balanced panel: %d countries x %d years = %d obs.\n",
            n_countries_scm, n_years_scm, nrow(scm_data)))
stopifnot("Need balanced panel" = nrow(scm_data) == n_countries_scm * n_years_scm)
stopifnot("Thailand must be in panel" = "TH" %in% scm_data$iso2c)

# --- 7. Summary statistics ---
cat("\n=== Thailand key outcomes ===\n")
th_summary <- scm_data %>%
  filter(iso2c == "TH") %>%
  select(year, cereal_prod, cereal_index, agri_va_pct, agri_empl_pct, cereal_yield)

print(as.data.frame(th_summary))

# Pre-post comparison for Thailand
th_pre <- scm_data %>% filter(iso2c == "TH", year < 2014)
th_post <- scm_data %>% filter(iso2c == "TH", year >= 2014)

cat(sprintf("\nThailand pre-collapse (2005-2013):\n"))
cat(sprintf("  Avg cereal prod: %.0f MT\n", mean(th_pre$cereal_prod, na.rm = TRUE)))
cat(sprintf("  Avg cereal index: %.1f\n", mean(th_pre$cereal_index, na.rm = TRUE)))
cat(sprintf("  Avg agri VA %%: %.2f%%\n", mean(th_pre$agri_va_pct, na.rm = TRUE)))

cat(sprintf("\nThailand post-collapse (2014-2020):\n"))
cat(sprintf("  Avg cereal prod: %.0f MT\n", mean(th_post$cereal_prod, na.rm = TRUE)))
cat(sprintf("  Avg cereal index: %.1f\n", mean(th_post$cereal_index, na.rm = TRUE)))
cat(sprintf("  Avg agri VA %%: %.2f%%\n", mean(th_post$agri_va_pct, na.rm = TRUE)))

# --- 8. Save ---
write_csv(panel_clean, "../data/panel_clean.csv")
write_csv(scm_data, "../data/scm_panel.csv")

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("  Full panel: %d obs\n", nrow(panel_clean)))
cat(sprintf("  SCM panel: %d obs (%d countries)\n", nrow(scm_data), n_countries_scm))
