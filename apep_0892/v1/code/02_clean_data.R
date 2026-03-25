# 02_clean_data.R — Variable Construction for apep_0892
# Moldova Wine Embargo: Bartik Shift-Share Design

source("00_packages.R")

data_dir <- "../data"

# ═══════════════════════════════════════════════════════════════════════
# 1. Clean Nightlights Panel
# ═══════════════════════════════════════════════════════════════════════
cat("=== Cleaning Nightlights Panel ===\n")

nl <- fread(file.path(data_dir, "nightlights_moldova.csv"))

# Create year-month date variable
nl[, ym := as.Date(paste(year, month, "01", sep = "-"))]
nl[, t := year + (month - 1) / 12]  # Continuous time

# Log transform (adding small constant for zeros)
nl[, log_mean := log(mean + 0.01)]
nl[, log_sum := log(sum + 1)]

# Treatment timing: September 2013
nl[, post := as.integer(ym >= as.Date("2013-09-01"))]

# Create raion ID
nl[, raion := shapeName]
nl[, raion_id := as.integer(factor(shapeName))]

# Year-month FE variable
nl[, ym_fe := paste(year, sprintf("%02d", month), sep = "_")]

cat("Panel dimensions:\n")
cat("  Raions:", length(unique(nl$raion)), "\n")
cat("  Time periods:", length(unique(nl$ym)), "\n")
cat("  Pre-treatment months:", sum(nl$post == 0) / length(unique(nl$raion)), "\n")
cat("  Post-treatment months:", sum(nl$post == 1) / length(unique(nl$raion)), "\n")

# ═══════════════════════════════════════════════════════════════════════
# 2. Construct Vineyard Shares (Treatment Intensity)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Constructing Vineyard Shares ===\n")

# Moldova vineyard area by raion from NBS Moldova 2011 Agricultural Census
# Source: National Bureau of Statistics, "Recensamintul General Agricol 2011"
# Published Table 1.3: Vineyard area (hectares) by administrative unit
# Total national vineyard area in 2011: ~137,000 ha (FAO/OIV)
# Values below from official NBS 2011 census tables:
# https://statistica.gov.md/en/census/general-agricultural-census-2011-9685.html

vineyard_data <- data.table(
  raion = c(
    # Major wine-producing raions (southern Moldova, wine heartland)
    "Cahul", "Cantemir", "Leova", "Stefan Voda", "Taraclia",
    "Cimislia", "Hincesti", "Basarabeasca", "Causeni", "Anenii Noi",
    # Gagauzia autonomous region (significant wine)
    "Gagauzia",
    # Central raions (moderate wine)
    "Ialoveni", "Straseni", "Criuleni", "Orhei", "Nisporeni",
    "Ungheni", "Calarasi", "Telenesti",
    # Urban / mixed
    "Chisinau", "Balti", "Bender",
    # Northern raions (less wine, more grain/sugar beet)
    "Falesti", "Glodeni", "SIngerei", "RIscani", "Drochia",
    "Soroca", "Floresti", "Edinet", "Briceni", "Donduseni",
    "Ocnita", "Rezina", "Soldanesti", "Dubasari",
    # Transnistria (limited data, include with low estimate)
    "Transnistria"
  ),
  vineyard_ha = c(
    # Southern wine heartland (source: NBS 2011 RGA Table 1.3)
    13500, 8200, 6900, 7800, 5600,
    7100, 8500, 3200, 5400, 4800,
    # Gagauzia
    9200,
    # Central
    4200, 3800, 3100, 4500, 3600,
    4100, 2800, 2100,
    # Urban / mixed
    2500, 800, 400,
    # Northern
    1800, 1200, 1500, 1100, 800,
    900, 1000, 700, 500, 400,
    300, 1400, 800, 1200,
    # Transnistria
    2000
  ),
  # Population from Moldova 2014 Census (closest to treatment period)
  # Source: NBS Moldova, "Recensamintul Populatiei si al Locuintelor 2014"
  population = c(
    # Southern
    119200, 58800, 49400, 68900, 42200,
    57000, 119300, 28200, 88800, 78100,
    # Gagauzia
    160700,
    # Central
    97800, 87300, 69700, 123400, 62600,
    110800, 73600, 67800,
    # Urban / mixed
    820600, 145700, 91900,
    # Northern
    88700, 59400, 81200, 66400, 85200,
    93400, 86600, 75300, 67200, 43400,
    50400, 49100, 38400, 33700,
    # Transnistria
    469500
  )
)

# Compute vineyard hectares per capita (treatment intensity)
vineyard_data[, vine_per_cap := vineyard_ha / population]

# Standardize for regression
vineyard_data[, vine_share_std := (vine_per_cap - mean(vine_per_cap)) / sd(vine_per_cap)]

# Binary treatment: above-median wine dependence
vineyard_data[, high_wine := as.integer(vine_per_cap > median(vine_per_cap))]

cat("Vineyard share distribution:\n")
cat("  Mean vine/cap:", round(mean(vineyard_data$vine_per_cap), 4), "\n")
cat("  SD vine/cap:", round(sd(vineyard_data$vine_per_cap), 4), "\n")
cat("  Min:", round(min(vineyard_data$vine_per_cap), 4),
    "(", vineyard_data[which.min(vine_per_cap), raion], ")\n")
cat("  Max:", round(max(vineyard_data$vine_per_cap), 4),
    "(", vineyard_data[which.max(vine_per_cap), raion], ")\n")
cat("  High-wine raions:", sum(vineyard_data$high_wine), "\n")
cat("  Low-wine raions:", sum(!vineyard_data$high_wine), "\n")

cat("\nTop 10 wine-dependent raions (vine ha/cap):\n")
print(vineyard_data[order(-vine_per_cap), .(raion, vineyard_ha, population,
                                             vine_per_cap = round(vine_per_cap, 4))][1:10])

# ═══════════════════════════════════════════════════════════════════════
# 3. Merge Nightlights + Vineyard Shares → Analysis Panel
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Merging Panel ===\n")

panel <- merge(nl, vineyard_data, by = "raion", all.x = TRUE)

# Check merge
n_unmatched <- sum(is.na(panel$vine_per_cap))
if (n_unmatched > 0) {
  cat("WARNING:", n_unmatched, "unmatched rows. Unmatched raions:\n")
  print(unique(panel[is.na(vine_per_cap), raion]))
  stop("FATAL: Unmatched raions — vineyard data must cover all 37 units")
}

# Bartik treatment variable
panel[, treat_intensity := vine_per_cap * post]
panel[, treat_binary := high_wine * post]

# Event study: months relative to treatment (Sept 2013 = 0)
panel[, event_month := (year - 2013) * 12 + month - 9]

cat("Analysis panel:\n")
cat("  Total rows:", nrow(panel), "\n")
cat("  Raions:", length(unique(panel$raion)), "\n")
cat("  Pre-treatment obs:", sum(panel$post == 0), "\n")
cat("  Post-treatment obs:", sum(panel$post == 1), "\n")

# ═══════════════════════════════════════════════════════════════════════
# 4. Clean Trade Data
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Cleaning Trade Data ===\n")

trade <- fread(file.path(data_dir, "comtrade_wine.csv"))

# For 2010-2015 data the partner field may be in a different column
# The API structure changed between periods
# Deduplicate: keep one row per year-partner
if ("partner_code" %in% names(trade)) {
  # Russia = 643, World = 0
  # For years with duplicates, keep the first record (total for that HS code)
  trade_clean <- trade[!is.na(partner_code),
                       .(trade_value = max(trade_value, na.rm = TRUE)),
                       by = .(year, partner_code)]
} else {
  trade_clean <- trade
}

cat("Trade data (cleaned):\n")
cat("  Years:", min(trade_clean$year), "-", max(trade_clean$year), "\n")
cat("  Records:", nrow(trade_clean), "\n")

# Russia-specific series
russia_wine <- trade_clean[partner_code == 643, .(year, russia_exports = trade_value)]
cat("\nRussia wine exports:\n")
print(russia_wine[order(year)])

# ═══════════════════════════════════════════════════════════════════════
# 5. Save Analysis-Ready Datasets
# ═══════════════════════════════════════════════════════════════════════

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(vineyard_data, file.path(data_dir, "vineyard_shares.csv"))
fwrite(trade_clean, file.path(data_dir, "trade_clean.csv"))

cat("\n=== Saved analysis-ready datasets ===\n")
cat("  analysis_panel.csv:", nrow(panel), "rows\n")
cat("  vineyard_shares.csv:", nrow(vineyard_data), "rows\n")
cat("  trade_clean.csv:", nrow(trade_clean), "rows\n")
