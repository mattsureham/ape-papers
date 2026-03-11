## 02_clean_data.R — Construct analysis panel
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load raw data
# ============================================================

imports_raw <- fread(file.path(data_dir, "census_port_imports_raw.csv"))
canal_data  <- fread(file.path(data_dir, "canal_transits.csv"))
gas_data    <- fread(file.path(data_dir, "fred_gas_prices.csv"))

cat(sprintf("Loaded: %s import rows, %d canal months, %d gas months\n",
            format(nrow(imports_raw), big.mark = ","),
            nrow(canal_data), nrow(gas_data)))

# ============================================================
# 2. Filter out aggregate country codes
# ============================================================

# Census data includes aggregate rows (TOTAL, APEC, OECD, ASIA, etc.)
# These have CTY_CODEs like "-", "0003", "0014", "0020-0027", "1XXX", "4XXX", "5XXX"
# Keep only individual country codes (4-digit, no X, not starting with 00)

imports_raw[, is_aggregate := grepl("X", CTY_CODE) |
              CTY_CODE == "-" |
              (nchar(CTY_CODE) == 4 & substr(CTY_CODE, 1, 2) == "00") |
              CTY_CODE %in% c("0003", "0014")]

cat(sprintf("Aggregate rows: %s (%.1f%%)\n",
            format(sum(imports_raw$is_aggregate), big.mark = ","),
            100 * mean(imports_raw$is_aggregate)))

imports <- imports_raw[is_aggregate == FALSE]
cat(sprintf("Individual country rows: %s\n", format(nrow(imports), big.mark = ",")))

# ============================================================
# 3. Define Canal-dependent country groups
# ============================================================

# Canal-dependent origins: Asian countries whose exports to US East/Gulf
# typically transit the Panama Canal (Asia → Pacific → Canal → Atlantic → East Coast)
canal_dependent_countries <- c(
  "5700",  # China
  "5880",  # Japan
  "5800",  # South Korea
  "5520",  # Vietnam
  "5830",  # Taiwan
  "5600",  # Thailand
  "5410",  # Indonesia
  "5500",  # Malaysia
  "5730",  # Philippines
  "5330",  # India
  "5350",  # Bangladesh
  "5310",  # Pakistan
  "5490",  # Singapore
  "5460",  # Cambodia
  "5370"   # Sri Lanka
)

# European countries (Atlantic route — no Canal needed for US trade)
european_countries <- c(
  "4280",  # Germany
  "4190",  # UK
  "4279",  # France
  "4759",  # Italy
  "4220",  # Netherlands
  "4240",  # Belgium
  "4210",  # Ireland
  "4380",  # Spain
  "4060",  # Sweden
  "4270",  # Switzerland
  "4050",  # Denmark
  "4090",  # Norway
  "4290",  # Austria
  "4620"   # Poland
)

# Western Hemisphere (land-border / short Atlantic — no Canal needed)
americas_countries <- c(
  "1220",  # Canada
  "2010",  # Mexico
  "2770",  # Brazil
  "2050",  # Colombia
  "2080",  # Chile
  "2360",  # Argentina
  "2450"   # Peru
)

imports[, origin_group := fcase(
  CTY_CODE %in% canal_dependent_countries, "Canal_dependent",
  CTY_CODE %in% european_countries, "European",
  CTY_CODE %in% americas_countries, "Americas",
  default = "Other"
)]

cat("\nOrigin group distribution:\n")
print(imports[, .(n = .N, total_val = sum(GEN_VAL_MO, na.rm = TRUE) / 1e9),
              by = origin_group][order(-total_val)])

# ============================================================
# 4. Classify ports by coast using port names
# ============================================================

# Use port names for reliable coastal classification
# East Coast states: ME, NH, MA, RI, CT, NY, NJ, PA, DE, MD, VA, NC, SC, GA, FL (Atlantic)
east_coast_states <- c("ME", "NH", "MA", "RI", "CT", "NY", "NJ", "PA",
                        "DE", "MD", "VA", "NC", "SC", "GA")
# FL is split — Miami/Everglades/Jacksonville = East, Tampa = Gulf

# Gulf Coast states: FL (Gulf side), AL, MS, LA, TX
gulf_states <- c("AL", "MS", "LA")
# TX is split — Houston/Port Arthur = Gulf, Laredo = land border

# West Coast states: CA, OR, WA, AK, HI
west_coast_states <- c("CA", "OR", "WA")

# Extract state abbreviation from port name
imports[, state := gsub(".*,\\s*", "", PORT_NAME)]
imports[, state := trimws(state)]

# Classify by state
imports[, coast := fcase(
  state %in% east_coast_states, "East Coast",
  state %in% c("FL") & grepl("MIAMI|EVERGLADES|JACKSONVILLE|PALM|CANAVERAL|FERNANDINA",
                               PORT_NAME, ignore.case = TRUE), "East Coast",
  state %in% c("FL") & grepl("TAMPA|PENSACOLA|PANAMA CITY|MOBILE|KEY WEST",
                               PORT_NAME, ignore.case = TRUE), "Gulf Coast",
  state %in% c("FL"), "East Coast",  # default FL to East
  state %in% gulf_states, "Gulf Coast",
  state %in% c("TX") & grepl("HOUSTON|GALVESTON|PORT ARTHUR|BEAUMONT|CORPUS|BROWNSVILLE|FREEPORT|SABINE",
                               PORT_NAME, ignore.case = TRUE), "Gulf Coast",
  state %in% c("TX"), "Gulf Coast",  # default TX to Gulf
  state %in% west_coast_states, "West Coast",
  default = "Other"
)]

cat("\nPort classification by coast:\n")
print(imports[, .(n_rows = .N, n_ports = uniqueN(PORT)), by = coast])

# ============================================================
# 5. Aggregate to port x month level
# ============================================================

# Total imports by port-month (only individual countries)
port_month_total <- imports[, .(
  total_imports = sum(GEN_VAL_MO, na.rm = TRUE),
  n_countries = uniqueN(CTY_CODE)
), by = .(PORT, PORT_NAME, year_month, coast)]

# Imports by origin group x port x month
port_month_origin <- imports[, .(
  imports = sum(GEN_VAL_MO, na.rm = TRUE)
), by = .(PORT, PORT_NAME, year_month, coast, origin_group)]

# Pivot to wide
port_month_origin_wide <- dcast(port_month_origin,
  PORT + PORT_NAME + year_month + coast ~ origin_group,
  value.var = "imports", fill = 0)

# Merge
panel <- merge(port_month_total, port_month_origin_wide,
               by = c("PORT", "PORT_NAME", "year_month", "coast"),
               all.x = TRUE)

for (col in c("Canal_dependent", "European", "Americas", "Other")) {
  if (col %in% names(panel)) {
    set(panel, which(is.na(panel[[col]])), col, 0)
  }
}

# ============================================================
# 6. Construct treatment intensity (Canal share)
# ============================================================

panel[, year := as.integer(substr(year_month, 1, 4))]
panel[, month := as.integer(substr(year_month, 6, 7))]
panel[, date := as.Date(paste0(year_month, "-01"))]

# Pre-drought Asian import share (2019 + 2021 + 2022, skip COVID 2020)
pre_drought <- panel[year %in% c(2019, 2021, 2022)]
asian_share_by_port <- pre_drought[, .(
  asian_imports_pre = sum(Canal_dependent, na.rm = TRUE),
  total_imports_pre = sum(total_imports, na.rm = TRUE)
), by = PORT]

asian_share_by_port[, asian_share := fifelse(
  total_imports_pre > 0,
  asian_imports_pre / total_imports_pre,
  0
)]

panel <- merge(panel, asian_share_by_port[, .(PORT, asian_share)],
               by = "PORT", all.x = TRUE)

# CRITICAL: Canal exposure = Asian share × East/Gulf Coast indicator
# Asian imports at West Coast ports arrive via direct trans-Pacific (NOT the Canal)
# Asian imports at East/Gulf Coast ports transit the Canal
# So Canal dependence = how much of your trade comes from Asia × whether you're
# on the coast that uses the Canal for that trade
panel[, is_canal_coast := fifelse(coast %in% c("East Coast", "Gulf Coast"), 1, 0)]
panel[, canal_share := asian_share * is_canal_coast]

cat("\nAsian import share by coast:\n")
port_as <- unique(panel[, .(PORT, PORT_NAME, coast, asian_share, canal_share)])
print(port_as[, .(mean_asian = mean(asian_share, na.rm=TRUE),
                   mean_canal_exposure = mean(canal_share, na.rm=TRUE),
                   n = .N), by = coast][order(-mean_canal_exposure)])

# ============================================================
# 7. Merge Canal drought data and gas prices
# ============================================================

panel <- merge(panel, canal_data[, .(year_month, drought_intensity, daily_transits, capacity_ratio)],
               by = "year_month", all.x = TRUE)
panel <- merge(panel, gas_data, by = "year_month", all.x = TRUE)

# Treatment interactions
panel[, treatment := canal_share * drought_intensity]
panel[, drought_period := fifelse(year_month >= "2023-07" & year_month <= "2024-08", 1L, 0L)]
panel[, treatment_binary := canal_share * drought_period]

# ============================================================
# 8. Create analysis variables
# ============================================================

panel[, log_imports := log(total_imports + 1)]
panel[, asinh_imports := asinh(total_imports)]
panel[, log_canal_imports := log(Canal_dependent + 1)]
panel[, log_euro_imports := log(European + 1)]
panel[, current_canal_share := fifelse(total_imports > 0, Canal_dependent / total_imports, 0)]

# Time indices
panel[, time_idx := (year - 2019) * 12 + month]
panel[, event_time := time_idx - (4 * 12 + 7)]  # July 2023 = month 55

# ============================================================
# 9. Filter to analysis sample
# ============================================================

# Keep ports on named coasts only
panel <- panel[coast %in% c("East Coast", "Gulf Coast", "West Coast")]

# Keep ports with positive imports in at least 50% of months
port_coverage <- panel[, .(pct_positive = mean(total_imports > 0)), by = PORT]
active_ports <- port_coverage[pct_positive >= 0.5, PORT]

cat(sprintf("\nActive coastal ports: %d of %d\n",
            length(active_ports), uniqueN(panel$PORT)))

panel <- panel[PORT %in% active_ports]

# ============================================================
# 10. Define high/low Canal share groups
# ============================================================

port_shares <- unique(panel[, .(PORT, canal_share)])
median_share <- median(port_shares$canal_share, na.rm = TRUE)
panel[, high_canal := fifelse(canal_share >= median_share, 1L, 0L)]

cat(sprintf("Median canal share: %.4f\n", median_share))
cat(sprintf("High Canal ports: %d, Low Canal ports: %d\n",
            uniqueN(panel[high_canal == 1]$PORT),
            uniqueN(panel[high_canal == 0]$PORT)))

cat(sprintf("\nFinal analysis sample: %s port-months, %d ports\n",
            format(nrow(panel), big.mark = ","),
            uniqueN(panel$PORT)))

# ============================================================
# 11. Save
# ============================================================

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

port_summary <- panel[, .(
  coast = first(coast),
  canal_share = first(canal_share),
  high_canal = first(high_canal),
  mean_monthly_imports = mean(total_imports, na.rm = TRUE),
  mean_canal_imports = mean(Canal_dependent, na.rm = TRUE),
  n_months = .N
), by = .(PORT, PORT_NAME)]
port_summary <- port_summary[order(-canal_share)]
fwrite(port_summary, file.path(data_dir, "port_summary.csv"))

cat("\nTop 15 ports by Canal share:\n")
print(port_summary[1:15, .(PORT_NAME, coast, canal_share = round(canal_share, 3),
                            avg_imports_M = round(mean_monthly_imports / 1e6))])

cat("\nBottom 10 ports by Canal share:\n")
print(tail(port_summary[order(canal_share)], 10)[,
  .(PORT_NAME, coast, canal_share = round(canal_share, 3),
    avg_imports_M = round(mean_monthly_imports / 1e6))])

cat("\n=== Data cleaning complete ===\n")
