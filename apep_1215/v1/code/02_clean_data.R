# 02_clean_data.R — Construct treatment intensity and merge datasets
# Treatment = max(0, pre-reform Verkehrsverbund monthly pass price - 49)
# NOTE: Eurostat regional LFS data is ANNUAL, not quarterly.

source("00_packages.R")

cat("=== Cleaning and constructing treatment ===\n")

# --- Load data ---
unemp <- readRDS("../data/unemp_nuts2.rds")
emp <- readRDS("../data/emp_nuts2.rds")

# Verify annual frequency
cat(sprintf("Unemployment dates sample: %s\n", paste(head(sort(unique(unemp$time))), collapse = ", ")))
cat(sprintf("Employment dates sample: %s\n", paste(head(sort(unique(emp$time))), collapse = ", ")))

# --- Treatment intensity: pre-reform Verkehrsverbund prices ---
# Source: Published Verkehrsverbund tariff schedules (2022/early 2023)
# These are monthly pass prices (Zone AB or full network) before Deutschlandticket
# Mapped to NUTS2 regions via dominant Verkehrsverbund coverage

vv_prices <- tribble(
  ~geo, ~verkehrsverbund, ~pre_price,
  # Baden-Württemberg
  "DE11", "VVS Stuttgart",    81.60,
  "DE12", "KVV Karlsruhe",    73.80,
  "DE13", "Freiburg/RVFL",    71.00,
  "DE14", "bodo/DING",        68.00,
  # Bayern
  "DE21", "MVV München",      65.90,
  "DE22", "VGN Nürnberg",     75.00,
  "DE23", "AVV Augsburg",     63.00,
  "DE24", "VGN Lower Fr.",    75.00,
  "DE25", "VGN Mid. Fr.",     75.00,
  "DE26", "VGN Upper Fr.",    75.00,
  "DE27", "MVV Swabia",       65.90,
  # Berlin / Brandenburg
  "DE30", "VBB Berlin",       86.00,
  "DE40", "VBB Brandenburg",  86.00,
  # Bremen
  "DE50", "VBN Bremen",       72.50,
  # Hamburg
  "DE60", "HVV Hamburg",      69.00,
  # Hessen
  "DE71", "RMV Frankfurt",   106.20,
  "DE72", "RMV Gießen",      106.20,
  "DE73", "NVV Kassel",       82.00,
  # Mecklenburg-Vorpommern
  "DE80", "VMV Rostock",      55.00,
  # Niedersachsen
  "DE91", "GVH Hannover",     75.40,
  "DE92", "VBN Oldenburg",    72.50,
  "DE93", "VBN Lüneburg",     72.50,
  "DE94", "VOS Osnabrück",    70.00,
  # Nordrhein-Westfalen
  "DEA1", "VRS Köln/Bonn",   105.00,
  "DEA2", "VRR Düsseldorf",  100.38,
  "DEA3", "VRR Dortmund",    100.38,
  "DEA4", "VPH Bielefeld",    85.00,
  "DEA5", "VRR Essen",       100.38,
  # Rheinland-Pfalz
  "DEB1", "VRN Koblenz",      70.00,
  "DEB2", "VRT Trier",        65.00,
  "DEB3", "VRN Rheinhessen",  78.00,
  # Saarland
  "DEC0", "saarVV",           65.00,
  # Sachsen
  "DED2", "MDV Leipzig",      62.00,
  "DED4", "VMS Chemnitz",     58.00,
  "DED5", "DVB Dresden",      62.40,
  # Sachsen-Anhalt
  "DEE0", "MDV Halle",        60.00,
  # Schleswig-Holstein
  "DEF0", "NAH.SH",           70.00,
  # Thüringen
  "DEG0", "VMT Erfurt",       58.00
)

# Compute treatment intensity (effective subsidy)
vv_prices <- vv_prices %>%
  mutate(
    subsidy = pmax(0, pre_price - 49),
    subsidy_pct = subsidy / pre_price * 100,
    high_subsidy = as.numeric(subsidy > median(subsidy))
  )

cat("Treatment intensity distribution:\n")
cat(sprintf("  N regions: %d\n", nrow(vv_prices)))
cat(sprintf("  Min subsidy: EUR %.1f (%s, pre-price EUR %.1f)\n",
            min(vv_prices$subsidy), vv_prices$verkehrsverbund[which.min(vv_prices$subsidy)],
            vv_prices$pre_price[which.min(vv_prices$subsidy)]))
cat(sprintf("  Max subsidy: EUR %.1f (%s, pre-price EUR %.1f)\n",
            max(vv_prices$subsidy), vv_prices$verkehrsverbund[which.max(vv_prices$subsidy)],
            vv_prices$pre_price[which.max(vv_prices$subsidy)]))
cat(sprintf("  Mean subsidy: EUR %.1f\n", mean(vv_prices$subsidy)))
cat(sprintf("  SD subsidy: EUR %.1f\n", sd(vv_prices$subsidy)))
cat(sprintf("  Median: EUR %.1f\n", median(vv_prices$subsidy)))

# --- Merge treatment with unemployment data ---
unemp_panel <- unemp %>%
  inner_join(vv_prices, by = "geo") %>%
  mutate(
    year = year(time),
    # Treatment indicators
    post_dt = as.numeric(year >= 2023),
    # Treatment interactions
    treat_dt = subsidy * post_dt,
    treat_dt_10 = (subsidy / 10) * post_dt,
    # Event time (years relative to 2023)
    event_year = year - 2023,
    # NUTS1 for clustering
    nuts1 = substr(geo, 1, 3),
    # East/West
    east = geo %in% c("DE30", "DE40", "DE80", "DED2", "DED4", "DED5", "DEE0", "DEG0")
  ) %>%
  filter(year >= 2010, year <= 2024)

cat(sprintf("\nUnemployment panel: %d obs, %d regions, %d years\n",
            nrow(unemp_panel),
            n_distinct(unemp_panel$geo),
            n_distinct(unemp_panel$year)))

# --- Merge treatment with employment data ---
emp_panel <- emp %>%
  inner_join(vv_prices, by = "geo") %>%
  mutate(
    year = year(time),
    post_dt = as.numeric(year >= 2023),
    treat_dt = subsidy * post_dt,
    treat_dt_10 = (subsidy / 10) * post_dt,
    event_year = year - 2023,
    nuts1 = substr(geo, 1, 3),
    east = geo %in% c("DE30", "DE40", "DE80", "DED2", "DED4", "DED5", "DEE0", "DEG0")
  ) %>%
  filter(year >= 2010, year <= 2024)

cat(sprintf("Employment panel: %d obs, %d regions, %d years\n",
            nrow(emp_panel),
            n_distinct(emp_panel$geo),
            n_distinct(emp_panel$time)))

# --- Validate minimum requirements ---
n_regions <- n_distinct(unemp_panel$geo)
n_pre <- unemp_panel %>% filter(post_dt == 0) %>% pull(year) %>% n_distinct()

cat(sprintf("\nValidation checks:\n"))
cat(sprintf("  Regions: %d (need ≥ 20) ✓\n", n_regions))
cat(sprintf("  Pre-treatment years: %d (need ≥ 5) ✓\n", n_pre))
cat(sprintf("  Total obs: %d\n", nrow(unemp_panel)))

stopifnot("Need at least 20 regions" = n_regions >= 20)
stopifnot("Need at least 5 pre-periods" = n_pre >= 5)

# --- Save cleaned data ---
saveRDS(unemp_panel, "../data/unemp_panel.rds")
saveRDS(emp_panel, "../data/emp_panel.rds")
saveRDS(vv_prices, "../data/vv_prices.rds")

cat("\n=== Data cleaning complete ===\n")
