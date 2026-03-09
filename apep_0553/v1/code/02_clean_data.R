## 02_clean_data.R — Construct analysis panel from raw Comtrade data
## apep_0553: Do Export Controls Have Teeth?

source("00_packages.R")

DATA_DIR <- "../data"

## ============================================================
## Load raw data
## ============================================================

trade_raw <- fread(file.path(DATA_DIR, "comtrade_raw.csv"))
chpl_codes <- fread(file.path(DATA_DIR, "chpl_codes.csv"))
reporters <- fread(file.path(DATA_DIR, "reporter_codes.csv"))

cat("Raw data loaded:", nrow(trade_raw), "rows\n")

## ============================================================
## Clean and standardize
## ============================================================

# Keep only HS6-level observations (drop HS4 aggregates if any)
trade_raw[, hs_len := nchar(hs6)]
trade <- trade_raw[hs_len == 6]
cat("After HS6 filter:", nrow(trade), "rows\n")

# Ensure numeric values
trade[, fob_value := as.numeric(fob_value)]
trade[is.na(fob_value), fob_value := 0]

## ============================================================
## Construct HS2 chapter for within-chapter controls
## ============================================================

trade[, hs2 := substr(hs6, 1, 2)]
trade[, hs4 := substr(hs6, 1, 4)]

## ============================================================
## Treatment definitions
## ============================================================

# 1. Transit vs. control country
trade[, is_transit := role == "transit"]
trade[, is_western := role == "western"]

# 2. CHPL product (already marked in fetch)
# Verify
trade[, is_chpl := hs6 %in% chpl_codes$hs6]

# 3. Tier classification
trade <- merge(trade, chpl_codes[, .(hs6, tier)], by = "hs6", all.x = TRUE,
               suffixes = c("", ".new"))
# Use the new tier if available
if ("tier.new" %in% names(trade)) {
  trade[!is.na(tier.new), tier := tier.new]
  trade[, tier.new := NULL]
}
trade[is.na(tier), tier := "non_CHPL"]

# Tier priority grouping
trade[, tier_group := fcase(
  tier %in% c("Tier1", "Tier2"), "Tier1_2",
  tier %in% c("Tier3A", "Tier3B"), "Tier3",
  tier %in% c("Tier4A", "Tier4B"), "Tier4",
  default = "non_CHPL"
)]

## ============================================================
## Time period definitions
## ============================================================

trade[, period := fcase(
  year <= 2021, "pre_sanctions",
  year == 2022, "sanctions_no_chpl",
  year == 2023, "chpl_partial",     # CHPL introduced May 2023
  year == 2024, "chpl_full",        # Full year under CHPL
  default = NA_character_
)]

trade[, post_sanctions := as.integer(year >= 2022)]
trade[, post_chpl := as.integer(year >= 2024)]
# Note: 2023 is partial CHPL — we use 2024 as the clean post-CHPL year

## ============================================================
## Build balanced panel at country × product × year level
## ============================================================

# Create full grid of all country × product × year combinations
all_combos <- CJ(
  reporter_code = unique(trade$reporter_code),
  hs6 = unique(trade$hs6),
  year = 2015:2024
)

# Merge with actual trade data
panel <- merge(all_combos, trade, by = c("reporter_code", "hs6", "year"), all.x = TRUE)

# Fill zeros for missing observations (no trade = zero trade)
panel[is.na(fob_value), fob_value := 0]

# Fill country metadata
panel <- merge(panel, reporters, by.x = "reporter_code", by.y = "code", all.x = TRUE,
               suffixes = c("", ".rep"))
if ("name" %in% names(panel) & !"reporter_name" %in% names(panel)) {
  setnames(panel, "name", "reporter_name")
}

# Fill product metadata
panel[, is_chpl := hs6 %in% chpl_codes$hs6]
panel <- merge(panel, chpl_codes[, .(hs6, tier)], by = "hs6", all.x = TRUE,
               suffixes = c("", ".chpl"))
if ("tier.chpl" %in% names(panel)) {
  panel[is.na(tier) & !is.na(tier.chpl), tier := tier.chpl]
  panel[, tier.chpl := NULL]
}
panel[is.na(tier), tier := "non_CHPL"]

panel[, tier_group := fcase(
  tier %in% c("Tier1", "Tier2"), "Tier1_2",
  tier %in% c("Tier3A", "Tier3B"), "Tier3",
  tier %in% c("Tier4A", "Tier4B"), "Tier4",
  default = "non_CHPL"
)]

# Fill role
panel <- merge(panel, reporters[, .(code, role)], by.x = "reporter_code", by.y = "code",
               all.x = TRUE, suffixes = c("", ".role2"))
if ("role.role2" %in% names(panel)) {
  panel[is.na(role) & !is.na(role.role2), role := role.role2]
  panel[, role.role2 := NULL]
}

panel[, is_transit := role == "transit"]
panel[, is_western := role == "western"]
panel[, hs2 := substr(hs6, 1, 2)]
panel[, hs4 := substr(hs6, 1, 4)]
panel[, post_sanctions := as.integer(year >= 2022)]
panel[, post_chpl := as.integer(year >= 2024)]
panel[, period := fcase(
  year <= 2021, "pre_sanctions",
  year == 2022, "sanctions_no_chpl",
  year == 2023, "chpl_partial",
  year == 2024, "chpl_full",
  default = NA_character_
)]

## ============================================================
## Outcome transformations
## ============================================================

panel[, log_trade := log(fob_value + 1)]
panel[, asinh_trade := asinh(fob_value)]
panel[, trade_positive := as.integer(fob_value > 0)]

## ============================================================
## Fixed effect identifiers
## ============================================================

panel[, cp := paste0(reporter_code, "_", hs6)]     # country × product
panel[, ct := paste0(reporter_code, "_", year)]     # country × year
panel[, pt := paste0(hs6, "_", year)]               # product × year
panel[, cpt_id := .GRP, by = .(reporter_code, hs6)] # panel ID

## ============================================================
## Summary statistics
## ============================================================

cat("\n=== Panel Summary ===\n")
cat("Total observations:", nrow(panel), "\n")
cat("Countries:", length(unique(panel$reporter_code)), "\n")
cat("Products (HS6):", length(unique(panel$hs6)), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("\nBy role:\n")
print(panel[, .(n_obs = .N, n_products = uniqueN(hs6),
                mean_trade = mean(fob_value),
                pct_positive = mean(trade_positive) * 100),
            by = role])
cat("\nBy CHPL status:\n")
print(panel[, .(n_obs = .N, mean_trade = mean(fob_value),
                pct_positive = mean(trade_positive) * 100),
            by = .(is_chpl, period)])

## ============================================================
## Aggregate panels for country-level analysis
## ============================================================

# Country × year × CHPL status panel
country_panel <- panel[, .(
  total_trade = sum(fob_value, na.rm = TRUE),
  n_products_traded = sum(trade_positive),
  n_products = .N,
  mean_trade = mean(fob_value, na.rm = TRUE)
), by = .(reporter_code, reporter_name, role, is_transit, year, is_chpl, tier_group, period)]

country_panel[, log_total := log(total_trade + 1)]
country_panel[, asinh_total := asinh(total_trade)]
country_panel[, post_sanctions := as.integer(year >= 2022)]
country_panel[, post_chpl := as.integer(year >= 2024)]

## ============================================================
## Save clean data
## ============================================================

fwrite(panel, file.path(DATA_DIR, "panel_hs6.csv"))
fwrite(country_panel, file.path(DATA_DIR, "panel_country.csv"))

cat("\nSaved panel_hs6.csv:", nrow(panel), "rows\n")
cat("Saved panel_country.csv:", nrow(country_panel), "rows\n")

## === VALIDATION ===
stopifnot("Panel must have transit countries" = any(panel$is_transit))
stopifnot("Panel must have CHPL products" = any(panel$is_chpl))
stopifnot("Panel must have 5+ years" = length(unique(panel$year)) >= 5)
cat("\nClean data validation passed.\n")
