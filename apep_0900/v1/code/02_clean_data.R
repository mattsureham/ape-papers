# 02_clean_data.R — Clean and construct analysis panel
# apep_0900: CBAM product-scope loophole

source("00_packages.R")

trade_raw <- fread("../data/trade_raw.csv")
cat(sprintf("Raw data: %d rows\n", nrow(trade_raw)))

# --- Inspect columns ---
cat("Columns:", paste(names(trade_raw), collapse = ", "), "\n")
cat("Partner codes:", paste(sort(unique(trade_raw$partnerCode)), collapse = ", "), "\n")
cat("Years:", paste(sort(unique(trade_raw$period)), collapse = ", "), "\n")
cat("Flow codes:", paste(unique(trade_raw$flowCode), collapse = ", "), "\n")

# --- Keep imports only and select relevant columns ---
dt <- trade_raw[flowCode == "M"]
cat(sprintf("Import rows: %d\n", nrow(dt)))

# Select and rename key variables
dt <- dt[, .(
  year = as.integer(period),
  partner_code = as.character(partnerCode),
  partner_name = partner2Desc,
  hs4 = cmdCode,
  hs4_desc = cmdDesc,
  value_usd = as.numeric(primaryValue),
  qty_kg = as.numeric(ifelse(is.na(netWgt), qty, netWgt))
)]

# --- Classify products ---
dt[, hs2 := substr(hs4, 1, 2)]

# CBAM coverage classification
dt[, covered := fcase(
  hs2 == "72", 1L,                                     # Iron & steel: covered
  hs4 %in% c("7601", "7602", "7603"), 1L,              # Unwrought aluminum: covered
  hs2 == "73", 0L,                                     # Articles of iron/steel: exempt
  hs4 %in% sprintf("%04d", 7604:7616), 0L,             # Aluminum articles: exempt
  default = NA_integer_
)]

# Drop unclassified (shouldn't happen but be safe)
dt <- dt[!is.na(covered)]
cat(sprintf("After CBAM classification: %d rows\n", nrow(dt)))

# Material group (for within-material comparisons)
dt[, material := fcase(
  hs2 %in% c("72", "73"), "iron_steel",
  hs2 == "76", "aluminum",
  default = NA_character_
)]

# --- Classify partners by carbon intensity ---
# High-carbon: China, India, Turkey, Russia, Ukraine, Vietnam
# Low-carbon: Japan, South Korea, Brazil
high_carbon_codes <- c("156", "356", "792", "643", "804", "704")
low_carbon_codes <- c("392", "410", "076")

dt[, high_carbon := fcase(
  partner_code %in% high_carbon_codes, 1L,
  partner_code %in% low_carbon_codes, 0L,
  default = NA_integer_
)]

dt <- dt[!is.na(high_carbon)]
cat(sprintf("After partner classification: %d rows\n", nrow(dt)))

# --- Treatment timing ---
# CBAM transitional phase: October 1, 2023
# With annual data, 2024 is the clear post year, 2023 is mixed
# Conservative: post = 2024+ (full year under CBAM)
# Aggressive: post = 2023+ (CBAM announced well before Oct 2023)
# We use 2024 as post, with 2023 as a transition year in robustness
dt[, post := as.integer(year >= 2024)]
dt[, post_broad := as.integer(year >= 2023)]  # For robustness

# --- Aggregate to product-partner-year level ---
# Some HS4 codes may have multiple entries per partner-year; aggregate
panel <- dt[, .(
  value_usd = sum(value_usd, na.rm = TRUE),
  qty_kg = sum(qty_kg, na.rm = TRUE),
  n_hs4 = uniqueN(hs4)
), by = .(year, partner_code, partner_name, hs2, covered, material, high_carbon, post, post_broad)]

cat(sprintf("\nPanel dimensions: %d rows\n", nrow(panel)))
cat(sprintf("  Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
cat(sprintf("  Partners: %d\n", uniqueN(panel$partner_code)))
cat(sprintf("  HS2 codes: %s\n", paste(sort(unique(panel$hs2)), collapse = ", ")))

# --- Create log variables ---
panel[, log_value := log(value_usd + 1)]
panel[, log_qty := log(qty_kg + 1)]

# Also create the full HS4-level panel for richer analysis
panel_hs4 <- dt[, .(
  value_usd = sum(value_usd, na.rm = TRUE),
  qty_kg = sum(qty_kg, na.rm = TRUE)
), by = .(year, partner_code, partner_name, hs4, hs4_desc, hs2, covered, material, high_carbon, post, post_broad)]

panel_hs4[, log_value := log(value_usd + 1)]
panel_hs4[, log_qty := log(qty_kg + 1)]

cat(sprintf("\nHS4 panel: %d rows, %d products, %d partners\n",
            nrow(panel_hs4), uniqueN(panel_hs4$hs4), uniqueN(panel_hs4$partner_code)))

# --- Summary statistics ---
cat("\n=== Summary by Coverage Status ===\n")
print(panel[, .(
  mean_value_M = mean(value_usd) / 1e6,
  total_value_B = sum(value_usd) / 1e9,
  n_obs = .N
), by = .(covered, year)][order(covered, year)])

cat("\n=== Summary by Coverage × High Carbon ===\n")
print(panel[, .(
  mean_value_M = round(mean(value_usd) / 1e6, 1),
  n = .N
), by = .(covered, high_carbon)][order(covered, high_carbon)])

# --- Save ---
fwrite(panel, "../data/panel_hs2.csv")
fwrite(panel_hs4, "../data/panel_hs4.csv")
cat("\nSaved: data/panel_hs2.csv, data/panel_hs4.csv\n")

cat("\n=== Cleaning complete ===\n")
