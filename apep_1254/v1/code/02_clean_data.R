## 02_clean_data.R — Construct analysis panel at municipality level
## apep_1254: Portugal Golden Visa Geographic Restriction

source("00_packages.R")

df_raw <- read_csv("../data/ine_bpihe_raw.csv", show_col_types = FALSE)
cat(sprintf("Loaded %d raw INE records.\n", nrow(df_raw)))

# Inspect available region types
cat("\nGeocod length distribution:\n")
print(table(nchar(df_raw$geocod)))

# Filter to "Total" category (all dwelling types)
df_total <- df_raw %>%
  filter(category == "Total" | grepl("^Total", category, ignore.case = TRUE))

cat(sprintf("Total-category records: %d\n", nrow(df_total)))

# Identify geographic levels:
# 1-digit: Country/NUTS1 (e.g., "1" = Continente)
# 2-digit: NUTS2 (e.g., "11" = Norte)
# 3-digit: NUTS3 (e.g., "111" = Alto Minho, "150" = Algarve)
# 7-digit: Municipality (e.g., "1111601" = Arcos de Valdevez)
# 3-char alphanumeric: NUTS3 (e.g., "11A" = AM Porto, "1A0" = Grande Lisboa)

# Municipalities have 7 characters
munic_data <- df_total %>%
  filter(nchar(geocod) == 7)

cat(sprintf("Municipality-level records: %d, covering %d municipalities\n",
            nrow(munic_data), n_distinct(munic_data$geocod)))

# Map municipalities to NUTS3 regions using first 3 digits of geocod
# INE geocoding: first 2-3 chars of municipal code = NUTS3 parent
# However, the mapping is not always straightforward.
# Use NUTS3 prefix approach + manual assignment for metropolitan areas

# NUTS3 regions that lost golden visa eligibility:
# - Área Metropolitana de Lisboa (AML): includes municipalities in Grande Lisboa
#   and Península de Setúbal (NUTS3 codes 1A0, 1B0, or combined 170)
# - Área Metropolitana do Porto (AMP): NUTS3 code 11A
# - Algarve: NUTS3 code 150

# Municipalities in AML (Grande Lisboa + Península de Setúbal):
aml_municipalities <- c(
  # Grande Lisboa
  "1106001", # Amadora
  "1106002", # Cascais
  "1106003", # Lisboa
  "1106004", # Loures
  "1106005", # Mafra
  "1106006", # Odivelas (if available)
  "1106007", # Oeiras
  "1106008", # Sintra
  "1106009", # Vila Franca de Xira
  # Península de Setúbal
  "1507001", # Alcochete
  "1507002", # Almada
  "1507003", # Barreiro
  "1507004", # Moita
  "1507005", # Montijo
  "1507006", # Palmela
  "1507007", # Seixal
  "1507008", # Sesimbra
  "1507009"  # Setúbal
)

# Municipalities in AMP (Área Metropolitana do Porto):
amp_municipalities <- c(
  "1312001", # Arouca
  "1312002", # Espinho
  "1312003", # Gondomar
  "1312004", # Maia
  "1312005", # Matosinhos
  "1312006", # Oliveira de Azeméis (if in AMP)
  "1312007", # Paredes
  "1312008", # Porto
  "1312009", # Póvoa de Varzim
  "1312010", # Santa Maria da Feira
  "1312011", # Santo Tirso
  "1312012", # São João da Madeira
  "1312013", # Trofa
  "1312014", # Vale de Cambra
  "1312015", # Valongo
  "1312016", # Vila do Conde
  "1312017"  # Vila Nova de Gaia
)

# Algarve municipalities (all start with "15" for Algarve NUTS2):
algarve_prefix <- "1508"

# Approach: use the available data to identify treated municipalities
# by matching against known NUTS3 membership

# First, get the NUTS3-level data to identify the region hierarchy
nuts3_data <- df_total %>%
  filter(nchar(geocod) == 3 | geocod %in% c("11A", "11B", "11C", "11D", "11E",
                                              "16I", "16J", "16B", "16D", "16E", "16F",
                                              "1A0", "1B0", "1C1", "1C2", "1C3", "1C4",
                                              "1D1", "1D2", "1D3", "170")) %>%
  distinct(geocod, geodsg)

cat("\nNUTS3 regions:\n")
print(nuts3_data, n = 30)

# Use geodsg name matching to assign treatment at municipality level
# Treated: municipalities whose name appears in Lisbon metro, Porto metro, or Algarve
# More robust: match by geocod prefix patterns from INE

# Get all unique municipalities
all_munic <- munic_data %>% distinct(geocod, geodsg) %>% arrange(geocod)
cat(sprintf("\nTotal unique municipalities: %d\n", nrow(all_munic)))

# Assign treatment based on the geocod prefix pattern
# INE municipality codes: DDCCMMM where DD=district, CC=concelho type, MMM=municipality
# District 11 = Porto metro area (partially)
# District 15 = Lisboa/Setúbal/Algarve (partially)

# More robust: match municipality names against known treated lists
# Let me use the geodsg to check region membership

# Actually, the cleanest approach: use the NUTS3-level ASSIGNMENT and then
# associate each municipality with its NUTS3 parent.
# The INE code structure: municipality geocod prefix maps to NUTS3

# Let me empirically determine which municipalities belong to treated NUTS3
# by looking at the geocod patterns

cat("\nSample municipality codes by region:\n")
print(head(all_munic, 30))

# The municipal codes have a pattern where the first few digits indicate
# the district and council. Let me map them using the known NUTS3 boundaries.

# Instead of hard-coding, use a simpler approach:
# Match municipality geodsg names against known municipalities in treated regions
# This is more robust than trying to decode the geocod hierarchy

treated_names_patterns <- c(
  # Lisbon metro
  "Lisboa$", "Amadora", "Cascais", "Loures", "Mafra", "Odivelas",
  "Oeiras", "Sintra", "Vila Franca de Xira",
  # Setúbal metro
  "Alcochete", "Almada", "Barreiro", "Moita", "Montijo",
  "Palmela", "Seixal", "Sesimbra", "^Setúbal$", "Set.bal$",
  # Porto metro
  "^Porto$", "Gondomar", "Maia$", "Matosinhos", "Valongo",
  "Vila Nova de Gaia", "Espinho", "Paredes", "Trofa",
  "Santo Tirso", "Póvoa de Varzim", "Vila do Conde",
  "Arouca", "Santa Maria da Feira", "São João da Madeira",
  "Oliveira de Azeméis", "Vale de Cambra",
  # Algarve (all municipalities — exclude Azores Lagoa)
  "Albufeira", "Alcoutim", "Aljezur", "Castro Marim",
  "Faro$", "^Lagoa$", "Lagos", "Loulé", "Monchique",
  "Olhão", "Portimão", "São Brás de Alportel",
  "Silves", "Tavira", "Vila do Bispo", "Vila Real de Santo António"
)

treated_pattern <- paste(treated_names_patterns, collapse = "|")

munic_data <- munic_data %>%
  mutate(
    treated = as.integer(grepl(treated_pattern, geodsg, ignore.case = TRUE)),
    post = as.integer(date >= as.Date("2022-01-01")),
    announcement = as.integer(date >= as.Date("2021-04-01")),
    anticipation = as.integer(date >= as.Date("2021-04-01") & date < as.Date("2022-01-01")),
    event_time = as.integer(12 * (year - 2022) + (month - 1)),
    ym = paste0(year, "-", sprintf("%02d", month)),
    log_value = log(value)
  )

# Check treatment assignment
cat("\nTreatment assignment:\n")
treated_munic <- munic_data %>%
  distinct(geocod, geodsg, treated) %>%
  filter(treated == 1) %>%
  arrange(geodsg)
cat(sprintf("Treated municipalities: %d\n", nrow(treated_munic)))
print(treated_munic, n = 50)

control_munic <- munic_data %>%
  distinct(geocod, geodsg, treated) %>%
  filter(treated == 0) %>%
  arrange(geodsg)
cat(sprintf("Control municipalities: %d\n", nrow(control_munic)))

n_treated <- n_distinct(munic_data$geocod[munic_data$treated == 1])
n_control <- n_distinct(munic_data$geocod[munic_data$treated == 0])

if (n_treated < 10) {
  cat("WARNING: Only", n_treated, "treated municipalities found. Checking names...\n")
  cat("All municipality names:\n")
  print(all_munic$geodsg)
}

stopifnot(n_treated >= 10)
stopifnot(n_control >= 20)

# Create balanced panel check
panel_balance <- munic_data %>%
  group_by(geocod) %>%
  summarise(n_months = n_distinct(date), .groups = "drop")

cat("\nPanel balance:\n")
print(summary(panel_balance$n_months))

# Keep municipalities with at least 80% coverage
expected_months <- n_distinct(munic_data$date)
munic_data <- munic_data %>%
  group_by(geocod) %>%
  filter(n_distinct(date) >= 0.8 * expected_months) %>%
  ungroup()

n_treated_final <- n_distinct(munic_data$geocod[munic_data$treated == 1])
n_control_final <- n_distinct(munic_data$geocod[munic_data$treated == 0])

cat(sprintf("\nAfter balance filter: %d obs, %d municipalities (%d treated, %d control), %d months\n",
            nrow(munic_data), n_distinct(munic_data$geocod),
            n_treated_final, n_control_final, n_distinct(munic_data$date)))

# Assign NUTS3 parent for clustering
# Derive from geocod prefix (first 4 digits map to council/NUTS3)
# For now, use a simple district-level clustering (first 2 digits)
munic_data <- munic_data %>%
  mutate(
    district = substr(geocod, 1, 2),
    nuts3_approx = substr(geocod, 1, 4)
  )

# Pre-treatment summary
pre_data <- munic_data %>% filter(date < as.Date("2022-01-01"))
cat("\nPre-treatment summary by treatment group:\n")
pre_data %>%
  group_by(treated) %>%
  summarise(
    mean_value = mean(value, na.rm = TRUE),
    sd_value = sd(value, na.rm = TRUE),
    median_value = median(value, na.rm = TRUE),
    n_obs = n(),
    n_munic = n_distinct(geocod),
    .groups = "drop"
  ) %>%
  print()

# Save analysis panel
write_csv(munic_data, "../data/analysis_panel.csv")
cat(sprintf("\nSaved municipality-level analysis panel: %d observations\n", nrow(munic_data)))
