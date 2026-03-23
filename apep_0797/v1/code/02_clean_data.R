# 02_clean_data.R — Clean and harmonize WFP food price data
# APEP paper apep_0797: ECOWAS Sanctions and Food Market Fragmentation in Niger

source("00_packages.R")

data_dir <- "../data"

# ---- Read raw data ----
ner <- fread(file.path(data_dir, "niger_raw.csv"))
bfa <- fread(file.path(data_dir, "bfa_raw.csv"))

# ---- Parse dates ----
ner[, date_parsed := as.Date(date, origin = "1970-01-01")]
bfa[, date_parsed := as.Date(date, origin = "1970-01-01")]

# ---- Add country identifiers ----
ner[, country := "Niger"]
bfa[, country := "Burkina Faso"]

# ---- Harmonize commodity names ----
# We need comparable commodities across both countries
# Key categories: rice (imported/tradable), millet (local), sorghum (local), cowpeas/beans (local)

ner[, commodity_clean := fcase(
  commodity == "Rice (imported)", "Rice (imported)",
  commodity == "Rice (local)", "Rice (local)",
  commodity == "Millet", "Millet",
  commodity == "Sorghum", "Sorghum",
  commodity == "Sorghum (local)", "Sorghum",
  commodity == "Beans (niebe)", "Cowpeas",
  commodity == "Maize", "Maize",
  default = NA_character_
)]

bfa[, commodity_clean := fcase(
  commodity == "Rice (imported)", "Rice (imported)",
  commodity == "Rice (local)", "Rice (local)",
  commodity == "Millet", "Millet",
  commodity == "Sorghum (white)", "Sorghum",
  commodity == "Sorghum (local)", "Sorghum",
  commodity == "Sorghum", "Sorghum",
  commodity == "Beans (niebe)", "Cowpeas",
  commodity == "Maize (white)", "Maize",
  commodity == "Maize", "Maize",
  default = NA_character_
)]

# ---- Filter ----
# Keep: retail prices, per KG, study period (2021-2024), harmonized commodities
ner_clean <- ner[
  pricetype == "Retail" & unit == "KG" &
  date_parsed >= "2021-01-01" & date_parsed <= "2024-12-31" &
  !is.na(commodity_clean) & !is.na(price) & price > 0
]

bfa_clean <- bfa[
  pricetype == "Retail" & unit == "KG" &
  date_parsed >= "2021-01-01" & date_parsed <= "2024-12-31" &
  !is.na(commodity_clean) & !is.na(price) & price > 0
]

# ---- Combine ----
cols_keep <- c("date_parsed", "country", "admin1", "market", "commodity_clean",
               "price", "usdprice", "latitude", "longitude")
combined <- rbindlist(list(ner_clean[, ..cols_keep], bfa_clean[, ..cols_keep]))

# ---- Create time variables ----
combined[, `:=`(
  year = year(date_parsed),
  month = month(date_parsed),
  ym = format(date_parsed, "%Y-%m"),
  year_month = as.numeric(year(date_parsed)) + (month(date_parsed) - 1) / 12
)]

# ---- Create treatment indicators ----
# Sanctions imposed: August 6, 2023
# Sanctions partially lifted: February 2024
combined[, `:=`(
  post_sanctions = as.integer(date_parsed >= "2023-08-01"),
  niger = as.integer(country == "Niger"),
  tradable = as.integer(commodity_clean %in% c("Rice (imported)", "Rice (local)")),
  sanctions_period = fcase(
    date_parsed < "2023-08-01", "Pre-sanctions",
    date_parsed >= "2023-08-01" & date_parsed < "2024-02-01", "Full sanctions",
    date_parsed >= "2024-02-01", "Post-partial-lift",
    default = NA_character_
  )
)]

# ---- Create market-commodity ID ----
combined[, market_commodity := paste(country, market, commodity_clean, sep = "_")]

# ---- Create relative month variable for event study ----
# Treatment month = August 2023
combined[, event_month := (year - 2023) * 12 + (month - 8)]

# ---- Log prices ----
combined[, ln_price := log(price)]

# ---- Summary statistics ----
message("\n=== CLEANED DATA SUMMARY ===")
message(sprintf("Total observations: %d", nrow(combined)))
message(sprintf("Niger observations: %d", sum(combined$niger)))
message(sprintf("Burkina Faso observations: %d", sum(1 - combined$niger)))
message(sprintf("Date range: %s to %s", min(combined$date_parsed), max(combined$date_parsed)))
message(sprintf("Markets: Niger=%d, BFA=%d",
  length(unique(combined[niger == 1, market])),
  length(unique(combined[niger == 0, market]))))
message(sprintf("Commodities: %s", paste(sort(unique(combined$commodity_clean)), collapse = ", ")))

# Cross-tab of observations
message("\nObservations by country x commodity:")
print(combined[, .N, by = .(country, commodity_clean)][order(country, commodity_clean)])

message("\nObservations by sanctions period x country:")
print(combined[, .N, by = .(sanctions_period, country)][order(sanctions_period, country)])

# ---- Save ----
fwrite(combined, file.path(data_dir, "analysis_panel.csv"))
message("\nSaved analysis panel to data/analysis_panel.csv")
message(sprintf("Final panel: %d obs, %d market-commodity pairs",
  nrow(combined), length(unique(combined$market_commodity))))
