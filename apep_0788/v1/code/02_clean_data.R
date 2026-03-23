## 02_clean_data.R — Construct analysis panel from raw Comtrade data
## Paper: Carbon Border Deflection (apep_0788)

source("00_packages.R")

# --- Load raw data ---
trade_raw <- readRDS("../data/trade_raw.rds")
cat(sprintf("Raw data: %d records\n", nrow(trade_raw)))

# --- Parse period to date ---
trade <- trade_raw |>
  mutate(
    year  = as.integer(substr(period, 1, 4)),
    month = as.integer(substr(period, 5, 6)),
    date  = as.Date(sprintf("%s-%s-01", substr(period, 1, 4), substr(period, 5, 6))),
    ym    = as.numeric(year) + (as.numeric(month) - 1) / 12
  )

# --- Classify products ---
trade <- trade |>
  mutate(
    hs2 = as.character(cmd_code),
    cbam_covered = case_when(
      hs2 == "72" ~ 1L,   # Iron and steel — CBAM covered
      hs2 == "76" ~ 1L,   # Aluminium — CBAM covered
      hs2 == "73" ~ 0L,   # Articles of iron/steel — NOT covered (placebo)
      TRUE ~ NA_integer_
    ),
    product_label = case_when(
      hs2 == "72" ~ "Iron & Steel (HS 72)",
      hs2 == "73" ~ "Steel Articles (HS 73)",
      hs2 == "76" ~ "Aluminium (HS 76)",
      TRUE ~ "Other"
    )
  ) |>
  filter(!is.na(cbam_covered))

# --- Classify destinations ---
trade <- trade |>
  mutate(
    dest = case_when(
      importer == "EU27_2020" ~ "EU",
      importer == "USA"       ~ "US",
      importer == "JPN"       ~ "JP",
      importer == "GBR"       ~ "UK",
      TRUE ~ importer
    ),
    eu_dest = as.integer(dest == "EU")
  )

# --- Classify exporters ---
# Map partner codes to clean names
exporter_map <- c(
  "156" = "CHN", "356" = "IND", "792" = "TUR",
  "643" = "RUS", "804" = "UKR", "704" = "VNM",
  "490" = "TWN", "076" = "BRA", "76" = "BRA"
)

# Also map by partner_desc for robustness
desc_map <- c(
  "China" = "CHN", "India" = "IND", "Türkiye" = "TUR", "Turkey" = "TUR",
  "Russian Federation" = "RUS", "Ukraine" = "UKR", "Viet Nam" = "VNM",
  "Other Asia, nes" = "TWN", "Brazil" = "BRA"
)

trade <- trade |>
  mutate(
    exporter = exporter_map[as.character(partner_code)],
    exporter = ifelse(is.na(exporter), desc_map[partner_desc], exporter)
  ) |>
  filter(!is.na(exporter))

# Carbon intensity (tCO2 per tonne crude steel, World Steel Association 2022)
carbon_intensity <- tibble(
  exporter = c("CHN", "IND", "TUR", "RUS", "UKR", "VNM", "TWN", "BRA"),
  co2_intensity = c(1.83, 2.00, 1.10, 1.55, 1.70, 1.75, 0.95, 0.85)
)

trade <- trade |> left_join(carbon_intensity, by = "exporter")

# --- Aggregate to one record per exporter × destination × HS2 × month ---
# API may return sub-records (CIF/FOB, re-exports, etc.)
cat(sprintf("Before aggregation: %d records\n", nrow(trade)))

trade <- trade |>
  group_by(period, year, month, date, ym, exporter, dest, eu_dest,
           hs2, cbam_covered, product_label, co2_intensity) |>
  summarise(
    primary_value = sum(primary_value, na.rm = TRUE),
    net_wgt = sum(net_wgt, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("After aggregation: %d records\n", nrow(trade)))

# --- Treatment variables ---
# CBAM transitional phase began October 1, 2023
treatment_date <- as.Date("2023-10-01")

trade <- trade |>
  mutate(
    post = as.integer(date >= treatment_date),
    # Triple interaction: Post × EU × Covered
    post_eu_covered = post * eu_dest * cbam_covered,
    # Double interactions
    post_eu = post * eu_dest,
    post_covered = post * cbam_covered,
    eu_covered = eu_dest * cbam_covered,
    # Event time (months relative to Sep 2023)
    event_time = 12L * (year - 2023L) + (month - 9L),
    # High carbon intensity indicator (above median)
    high_carbon = as.integer(co2_intensity > median(co2_intensity, na.rm = TRUE))
  )

# --- Trade value: handle zeros and create log ---
trade <- trade |>
  mutate(
    trade_value = ifelse(is.na(primary_value), 0, primary_value),
    trade_value_m = trade_value / 1e6,  # Millions USD
    log_trade = log(trade_value + 1),
    trade_weight = ifelse(is.na(net_wgt), 0, net_wgt),
    trade_weight_kt = trade_weight / 1e6  # Kilotonnes
  )

# --- Create cell identifiers for fixed effects ---
trade <- trade |>
  mutate(
    cell_id = paste(exporter, dest, hs2, sep = "_"),
    exp_month = paste(exporter, period, sep = "_"),
    dest_month = paste(dest, period, sep = "_"),
    prod_month = paste(hs2, period, sep = "_"),
    exp_dest = paste(exporter, dest, sep = "_"),
    exp_prod = paste(exporter, hs2, sep = "_"),
    dest_prod = paste(dest, hs2, sep = "_")
  )

# --- Summary statistics ---
cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(trade)))
cat(sprintf("Unique cells (exp × dest × prod): %d\n", n_distinct(trade$cell_id)))
cat(sprintf("Exporters: %s\n", paste(sort(unique(trade$exporter)), collapse = ", ")))
cat(sprintf("Destinations: %s\n", paste(sort(unique(trade$dest)), collapse = ", ")))
cat(sprintf("Products (HS): %s\n", paste(sort(unique(trade$hs2)), collapse = ", ")))
cat(sprintf("Period: %s to %s\n", min(trade$date), max(trade$date)))
cat(sprintf("Pre-CBAM obs: %d\n", sum(trade$post == 0)))
cat(sprintf("Post-CBAM obs: %d\n", sum(trade$post == 1)))
cat(sprintf("Mean trade value (M USD): %.2f\n", mean(trade$trade_value_m, na.rm = TRUE)))
cat(sprintf("Share zero trade: %.1f%%\n", 100 * mean(trade$trade_value == 0)))

# Check balance
balance <- trade |>
  group_by(dest, hs2) |>
  summarise(
    n_months = n_distinct(period),
    n_exporters = n_distinct(exporter),
    mean_value = mean(trade_value_m, na.rm = TRUE),
    .groups = "drop"
  )
print(balance)

# --- Save analysis dataset ---
saveRDS(trade, "../data/trade_panel.rds")
cat(sprintf("\nAnalysis panel saved: data/trade_panel.rds (%d rows)\n", nrow(trade)))
