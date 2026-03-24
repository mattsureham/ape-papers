## 02_clean_data.R — Clean and construct analysis panel
## APEP-0884: The World's Highest Minimum Wage

source("00_packages.R")

# ============================================================================
# Load raw data
# ============================================================================

statent_codes <- readRDS("../data/statent_raw_codes.rds")
statent_labels <- readRDS("../data/statent_raw_labels.rds")
udemo_codes <- readRDS("../data/udemo_raw_codes.rds")
udemo_labels <- readRDS("../data/udemo_raw_labels.rds")

cat("STATENT:", nrow(statent_codes), "rows\n")
cat("UDEMO:", nrow(udemo_codes), "rows\n")

# Check column names and structure
cat("\nSTATENT columns:\n")
str(statent_codes)
cat("\nSTATENT label columns:\n")
str(statent_labels)

# ============================================================================
# Clean STATENT: establishments, employment, FTE by canton x NOGA x year
# ============================================================================

# Rename columns for clarity
names(statent_codes) <- c("year", "canton_code", "noga_code", "variable_code", "value")
names(statent_labels) <- c("year", "canton_name", "noga_name", "variable_name", "value")

# Merge code and label info
statent <- statent_codes %>%
  mutate(
    canton_name = statent_labels$canton_name,
    noga_name = statent_labels$noga_name,
    variable_name = statent_labels$variable_name,
    year = as.integer(year),
    value = as.numeric(value)
  )

cat("\nCantons available:\n")
print(sort(unique(statent$canton_code)))
cat("Canton names:\n")
print(unique(statent[, c("canton_code", "canton_name")]) %>% arrange(canton_code))

cat("\nObservation units:\n")
print(unique(statent[, c("variable_code", "variable_name")]))

cat("\nYears:", sort(unique(statent$year)), "\n")

# ============================================================================
# Filter to Geneva (25) and Vaud (22) + keep all comparison cantons
# For DDD, we need: GE, VD, and a broader set for robustness
# ============================================================================

# Identify Geneva and Vaud canton codes
ge_code <- statent %>% filter(grepl("Gen", canton_name)) %>% pull(canton_code) %>% unique()
vd_code <- statent %>% filter(grepl("Vaud", canton_name)) %>% pull(canton_code) %>% unique()

cat("\nGeneva code:", ge_code, "\n")
cat("Vaud code:", vd_code, "\n")

# Main analysis panel: GE and VD
main_cantons <- c(ge_code, vd_code)

# Wider panel for robustness (neighboring cantons)
# FR = Fribourg, VS = Valais, NE = Neuchatel, JU = Jura
neighbor_cantons <- statent %>%
  filter(grepl("Fribourg|Valais|Neuch|Jura", canton_name)) %>%
  pull(canton_code) %>%
  unique()

cat("Neighbor cantons:", neighbor_cantons, "\n")

# ============================================================================
# Reshape STATENT: pivot wider on variable_code
# Variables: 1=Establishments, 2=Employed, 5=FTE
# ============================================================================

statent_wide <- statent %>%
  filter(variable_code %in% c("1", "2", "5")) %>%
  mutate(
    var_label = case_when(
      variable_code == "1" ~ "establishments",
      variable_code == "2" ~ "employment",
      variable_code == "5" ~ "fte"
    )
  ) %>%
  select(year, canton_code, canton_name, noga_code, noga_name, var_label, value) %>%
  pivot_wider(
    names_from = var_label,
    values_from = value
  )

cat("\nWide STATENT:", nrow(statent_wide), "rows\n")
cat("Sample:\n")
print(head(statent_wide %>% filter(canton_code %in% main_cantons), 10))

# ============================================================================
# Extract NOGA 2-digit code from noga_code field
# The noga_code contains the NOGA division number
# ============================================================================

# Check NOGA code format
cat("\nSample NOGA codes:\n")
print(head(unique(statent_wide$noga_code), 20))
cat("\nSample NOGA names:\n")
print(head(unique(statent_wide$noga_name), 20))

# Extract the 2-digit NOGA code
statent_wide <- statent_wide %>%
  mutate(
    noga2 = as.integer(str_extract(noga_code, "\\d+")),
    # Also extract from noga_name as backup
    noga2_from_name = as.integer(str_extract(noga_name, "^\\d+"))
  ) %>%
  mutate(noga2 = coalesce(noga2, noga2_from_name))

cat("\nNOGA 2-digit codes found:\n")
print(sort(unique(statent_wide$noga2)))

# ============================================================================
# Classify sectors by minimum wage bite
# High-bite: sectors where ≥20% workers earn below CHF 23/hr
# Low-bite: sectors where <5% workers earn below CHF 23/hr
# ============================================================================

# Based on Swiss wage structure survey (LSE/SESS) and industry knowledge:
# High-bite sectors (low-wage intensive):
high_bite_noga <- c(
  55,  # Accommodation
  56,  # Food and beverage service activities
  47,  # Retail trade (except motor vehicles)
  96,  # Other personal service activities
  81,  # Services to buildings and landscape activities
  79,  # Travel agency, tour operator
  93   # Sports activities and amusement
)

# Low-bite sectors (high-wage, minimal impact):
low_bite_noga <- c(
  64,  # Financial service activities
  65,  # Insurance
  62,  # Computer programming, consultancy
  21,  # Manufacture of pharmaceuticals
  72,  # Scientific research and development
  69,  # Legal and accounting activities
  61,  # Telecommunications
  63   # Information service activities
)

statent_wide <- statent_wide %>%
  mutate(
    bite_group = case_when(
      noga2 %in% high_bite_noga ~ "high_bite",
      noga2 %in% low_bite_noga ~ "low_bite",
      TRUE ~ "medium"
    ),
    # Treatment indicators
    geneva = as.integer(canton_code == ge_code),
    post = as.integer(year >= 2021),  # Full calendar years: 2021+ are treated
    # Geneva minimum wage effective Nov 2020, so first full year is 2021
    treat_ddd = as.integer(canton_code == ge_code & year >= 2021 &
                             bite_group == "high_bite")
  )

# ============================================================================
# Construct sector-level aggregates for DDD
# ============================================================================

# Panel at canton × NOGA × year level (drop total/aggregate NOGA codes)
panel <- statent_wide %>%
  filter(
    canton_code %in% c(main_cantons, neighbor_cantons),
    !is.na(noga2),
    noga2 >= 5  # Drop agriculture (01-03) and mining aggregates
  ) %>%
  arrange(canton_code, noga2, year)

cat("\nPanel dimensions:", nrow(panel), "rows\n")
cat("Cantons:", length(unique(panel$canton_code)), "\n")
cat("NOGA sectors:", length(unique(panel$noga2)), "\n")
cat("Years:", length(unique(panel$year)), "\n")

# Create panel ID
panel <- panel %>%
  mutate(
    canton_noga = paste0(canton_code, "_", noga2),
    canton_year = paste0(canton_code, "_", year),
    noga_year = paste0(noga2, "_", year)
  )

# ============================================================================
# Summary statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")

# Geneva vs Vaud, pre-treatment
pre_summary <- panel %>%
  filter(canton_code %in% main_cantons, year <= 2019) %>%
  group_by(canton_name, bite_group) %>%
  summarise(
    n_sectors = n_distinct(noga2),
    mean_establishments = mean(establishments, na.rm = TRUE),
    mean_employment = mean(employment, na.rm = TRUE),
    mean_fte = mean(fte, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment means (2011-2019):\n")
print(pre_summary)

# Check balance: Geneva vs Vaud high-bite trends
trend_check <- panel %>%
  filter(canton_code %in% main_cantons, bite_group %in% c("high_bite", "low_bite")) %>%
  group_by(canton_name, bite_group, year) %>%
  summarise(
    total_employment = sum(employment, na.rm = TRUE),
    total_establishments = sum(establishments, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nTrends by canton and bite group:\n")
print(trend_check %>% arrange(bite_group, canton_name, year))

# ============================================================================
# Clean UDEMO: firm births and deaths by canton, sector, size
# ============================================================================

names(udemo_codes) <- c("variable_code", "canton_code", "sector_code", "size_code", "year", "value")
names(udemo_labels) <- c("variable_name", "canton_name", "sector_name", "size_name", "year", "value")

udemo <- udemo_codes %>%
  mutate(
    canton_name = udemo_labels$canton_name,
    variable_name = udemo_labels$variable_name,
    sector_name = udemo_labels$sector_name,
    size_name = udemo_labels$size_name,
    year = as.integer(year),
    value = as.numeric(value)
  )

cat("\nUDEMO variables:\n")
print(unique(udemo[, c("variable_code", "variable_name")]))

# Pivot UDEMO wider: births, deaths, active stock
udemo_wide <- udemo %>%
  filter(canton_code %in% c(
    sprintf("%02d", as.integer(main_cantons)),
    main_cantons
  )) %>%
  mutate(
    var_label = case_when(
      variable_code == "1" ~ "active_firms",
      variable_code == "2" ~ "births",
      variable_code == "3" ~ "closures",
      variable_code == "4" ~ "active_emp",
      variable_code == "5" ~ "birth_emp",
      variable_code == "6" ~ "closure_emp"
    )
  ) %>%
  select(year, canton_code, canton_name, sector_name, size_name, var_label, value) %>%
  pivot_wider(names_from = var_label, values_from = value)

cat("\nUDEMO wide:", nrow(udemo_wide), "rows\n")
cat("Sample:\n")
print(head(udemo_wide, 10))

# Aggregate UDEMO by canton and year (sum over sizes and sectors)
udemo_agg <- udemo_wide %>%
  group_by(year, canton_code, canton_name) %>%
  summarise(
    across(c(active_firms, births, closures, active_emp, birth_emp, closure_emp),
           ~sum(.x, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  mutate(
    birth_rate = births / active_firms * 100,
    closure_rate = closures / active_firms * 100,
    net_creation = births - closures,
    geneva = as.integer(canton_code %in% c(ge_code, sprintf("%02d", as.integer(ge_code)))),
    post = as.integer(year >= 2021)
  )

cat("\nUDEMO aggregated:\n")
print(udemo_agg)

# ============================================================================
# Save clean panel data
# ============================================================================

saveRDS(panel, "../data/panel_statent.rds")
saveRDS(udemo_agg, "../data/panel_udemo.rds")
saveRDS(trend_check, "../data/trend_check.rds")

# Save as CSV for replication
write.csv(panel, "../data/panel_statent.csv", row.names = FALSE)
write.csv(udemo_agg, "../data/panel_udemo.csv", row.names = FALSE)

cat("\n=== Clean data saved ===\n")
cat("Panel STATENT:", nrow(panel), "obs\n")
cat("Panel UDEMO:", nrow(udemo_agg), "obs\n")
