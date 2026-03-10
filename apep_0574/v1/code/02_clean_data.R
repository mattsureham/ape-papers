## 02_clean_data.R — Merge datasets and construct analysis panels
## APEP-0574: Gas Shock Import Substitution
## Inputs:  trade_annual.csv, production_monthly.csv, bec_monthly_trade.csv,
##          gas_dependence.csv, sitc_classification.csv, nace_classification.csv
## Outputs: trade_panel.csv, production_panel.csv, bec_panel.csv, summary_stats.csv

source("00_packages.R")

data_dir <- "../data/"

# =====================================================================
# 1. READ RAW DATA
# =====================================================================
cat("=== Reading raw data ===\n")

trade     <- fread(file.path(data_dir, "trade_annual.csv"))
prod      <- fread(file.path(data_dir, "production_monthly.csv"))
bec       <- fread(file.path(data_dir, "bec_monthly_trade.csv"))
gas_dep   <- fread(file.path(data_dir, "gas_dependence.csv"))
sitc_cls  <- fread(file.path(data_dir, "sitc_classification.csv"))
nace_cls  <- fread(file.path(data_dir, "nace_classification.csv"))

cat(sprintf("  trade_annual:       %d rows\n", nrow(trade)))
cat(sprintf("  production_monthly: %d rows\n", nrow(prod)))
cat(sprintf("  bec_monthly_trade:  %d rows\n", nrow(bec)))
cat(sprintf("  gas_dependence:     %d rows\n", nrow(gas_dep)))

# =====================================================================
# 2. TRADE PANEL (annual: SITC × country × year)
# =====================================================================
cat("\n=== Constructing trade panel ===\n")

# Drop TOTAL and SITC3 (fuels themselves) — keep product groups only
trade_panel <- trade[sitc06 != "TOTAL" & sitc06 != "SITC3"]

# Merge gas dependence
trade_panel <- merge(trade_panel, gas_dep[, .(geo, russian_gas_share, gas_tpes_share,
                                               gas_exposure, country_name)],
                     by = "geo", all.x = TRUE)

# Merge SITC classification
trade_panel <- merge(trade_panel, sitc_cls[, .(sitc06, product_label, energy_intensive)],
                     by = "sitc06", all.x = TRUE)

# Drop observations with missing energy_intensive classification
trade_panel <- trade_panel[!is.na(energy_intensive)]

# Construct key variables
trade_panel[, `:=`(
  log_imports     = log(pmax(import_mio_eur, 0.01)),  # Floor at 0.01 to avoid log(0)
  post_shock      = as.integer(year >= 2022),
  gas_dep         = russian_gas_share,                 # Main treatment: continuous
  gas_dep_binary  = as.integer(russian_gas_share > median(gas_dep$russian_gas_share)),
  ei              = as.integer(energy_intensive == 1)
)]

# Interaction terms
trade_panel[, `:=`(
  gas_x_ei          = gas_dep * ei,
  gas_x_post        = gas_dep * post_shock,
  ei_x_post         = ei * post_shock,
  gas_x_ei_x_post   = gas_dep * ei * post_shock
)]

# Fixed-effect identifiers
trade_panel[, `:=`(
  country_year  = paste0(geo, "_", year),
  sitc_year     = paste0(sitc06, "_", year),
  country_sitc  = paste0(geo, "_", sitc06)
)]

# Period splits for persistence test
trade_panel[, period := fcase(
  year < 2022,  "pre",
  year == 2022, "shock",
  year >= 2023, "post_norm"
)]
trade_panel[, shock_year    := as.integer(year == 2022)]
trade_panel[, post_norm     := as.integer(year >= 2023)]

cat(sprintf("Trade panel: %d rows, %d countries, %d SITC groups, years %d-%d\n",
            nrow(trade_panel), uniqueN(trade_panel$geo),
            uniqueN(trade_panel$sitc06),
            min(trade_panel$year), max(trade_panel$year)))

fwrite(trade_panel, file.path(data_dir, "trade_panel.csv"))

# =====================================================================
# 3. PRODUCTION PANEL (monthly: NACE × country × month)
# =====================================================================
cat("\n=== Constructing production panel ===\n")

# Drop total manufacturing (C) for now — keep individual sectors
prod_panel <- prod[nace_r2 != "C"]

# Merge gas dependence
prod_panel <- merge(prod_panel, gas_dep[, .(geo, russian_gas_share, gas_tpes_share,
                                             gas_exposure, country_name)],
                    by = "geo", all.x = TRUE)

# Merge NACE classification
prod_panel <- merge(prod_panel, nace_cls[nace_r2 != "C",
                                          .(nace_r2, sector_label, energy_intensive,
                                            energy_intensity_mj)],
                    by = "nace_r2", all.x = TRUE)

# Drop observations with missing classification
prod_panel <- prod_panel[!is.na(energy_intensive)]

# Key variables
prod_panel[, `:=`(
  gas_dep     = russian_gas_share,
  ei          = as.integer(energy_intensive == 1),
  post_shock  = as.integer(year >= 2022 | (year == 2022 & month >= 2))
)]
# Actually: the shock is Feb 2022. Redefine post_shock properly
prod_panel[, post_shock := as.integer(
  (year == 2022 & month >= 3) | (year > 2022)  # March 2022 onward (first full post-invasion month)
)]

# Event study: months relative to Feb 2022
prod_panel[, `:=`(
  time_num   = (year - 2019) * 12 + month,         # continuous month index
  shock_month = (2022 - 2019) * 12 + 2              # Feb 2022 = month 38
)]
prod_panel[, rel_month := time_num - shock_month]

# Create event study dummies (relative to t=-1, i.e., Jan 2022)
# Bin endpoints: anything before -24 or after +24
prod_panel[, rel_month_binned := pmax(pmin(rel_month, 30), -24)]

# Fixed-effect identifiers
prod_panel[, `:=`(
  country_nace   = paste0(geo, "_", nace_r2),
  nace_ym        = paste0(nace_r2, "_", ym),
  country_ym     = paste0(geo, "_", ym)
)]

cat(sprintf("Production panel: %d rows, %d countries, %d sectors, %s to %s\n",
            nrow(prod_panel), uniqueN(prod_panel$geo),
            uniqueN(prod_panel$nace_r2),
            min(prod_panel$ym), max(prod_panel$ym)))

fwrite(prod_panel, file.path(data_dir, "production_panel.csv"))

# =====================================================================
# 4. BEC MONTHLY TRADE PANEL
# =====================================================================
cat("\n=== Constructing BEC panel ===\n")

bec_panel <- copy(bec)

# Merge gas dependence
bec_panel <- merge(bec_panel, gas_dep[, .(geo, russian_gas_share, gas_tpes_share,
                                           gas_exposure, country_name)],
                   by = "geo", all.x = TRUE)

bec_panel[, `:=`(
  gas_dep     = russian_gas_share,
  year_num    = as.integer(substr(ym, 1, 4)),
  month_num   = as.integer(substr(ym, 6, 7))
)]

# Event time relative to Feb 2022
bec_panel[, `:=`(
  time_num   = (year_num - 2019) * 12 + month_num,
  shock_month = (2022 - 2019) * 12 + 2
)]
bec_panel[, rel_month := time_num - shock_month]
bec_panel[, rel_month_binned := pmax(pmin(rel_month, 30), -24)]

# Log trade value
bec_panel[, log_trade := log(pmax(trade_val, 0.01))]

# Intermediate goods indicator
bec_panel[, intermediate := as.integer(bclas_bec == "INT")]

# Post-shock
bec_panel[, post_shock := as.integer(rel_month >= 1)]

# FE identifiers
bec_panel[, `:=`(
  country_bec  = paste0(geo, "_", bclas_bec),
  bec_ym       = paste0(bclas_bec, "_", ym),
  country_ym   = paste0(geo, "_", ym)
)]

cat(sprintf("BEC panel: %d rows, %d countries, %d BEC categories\n",
            nrow(bec_panel), uniqueN(bec_panel$geo),
            uniqueN(bec_panel$bclas_bec)))

fwrite(bec_panel, file.path(data_dir, "bec_panel.csv"))

# =====================================================================
# 5. SUMMARY STATISTICS
# =====================================================================
cat("\n=== Computing summary statistics ===\n")

# Trade panel statistics
trade_stats <- trade_panel[, .(
  variable   = c("import_mio_eur", "log_imports", "gas_dep", "energy_intensive", "post_shock"),
  mean       = c(mean(import_mio_eur, na.rm = TRUE), mean(log_imports, na.rm = TRUE),
                 mean(gas_dep, na.rm = TRUE), mean(ei, na.rm = TRUE),
                 mean(post_shock, na.rm = TRUE)),
  sd         = c(sd(import_mio_eur, na.rm = TRUE), sd(log_imports, na.rm = TRUE),
                 sd(gas_dep, na.rm = TRUE), sd(ei, na.rm = TRUE),
                 sd(post_shock, na.rm = TRUE)),
  min        = c(min(import_mio_eur, na.rm = TRUE), min(log_imports, na.rm = TRUE),
                 min(gas_dep, na.rm = TRUE), min(ei, na.rm = TRUE),
                 min(post_shock, na.rm = TRUE)),
  max        = c(max(import_mio_eur, na.rm = TRUE), max(log_imports, na.rm = TRUE),
                 max(gas_dep, na.rm = TRUE), max(ei, na.rm = TRUE),
                 max(post_shock, na.rm = TRUE)),
  n          = c(sum(!is.na(import_mio_eur)), sum(!is.na(log_imports)),
                 sum(!is.na(gas_dep)), sum(!is.na(ei)),
                 sum(!is.na(post_shock))),
  panel      = "trade"
)]

# Production panel statistics (restricted to non-missing production index for consistency)
prod_panel_nm <- prod_panel[!is.na(prod_index)]
prod_stats <- prod_panel_nm[, .(
  variable   = c("prod_index", "gas_dep", "energy_intensive",
                 "energy_intensity_mj", "post_shock"),
  mean       = c(mean(prod_index), mean(gas_dep),
                 mean(ei), mean(energy_intensity_mj),
                 mean(post_shock)),
  sd         = c(sd(prod_index), sd(gas_dep),
                 sd(ei), sd(energy_intensity_mj),
                 sd(post_shock)),
  min        = c(min(prod_index), min(gas_dep),
                 min(ei), min(energy_intensity_mj),
                 min(post_shock)),
  max        = c(max(prod_index), max(gas_dep),
                 max(ei), max(energy_intensity_mj),
                 max(post_shock)),
  n          = c(.N, .N, .N, .N, .N),
  panel      = "production"
)]

summary_stats <- rbind(trade_stats, prod_stats)
fwrite(summary_stats, file.path(data_dir, "summary_stats.csv"))

cat(sprintf("Summary statistics: %d rows saved\n", nrow(summary_stats)))

# =====================================================================
# PANEL DIAGNOSTICS
# =====================================================================
cat("\n=== Panel diagnostics ===\n")

# Trade panel balance
trade_balance <- trade_panel[, .N, by = .(geo, sitc06)]
cat(sprintf("Trade panel: %d country-product cells, median obs per cell = %d\n",
            nrow(trade_balance), median(trade_balance$N)))

# Production panel balance
prod_balance <- prod_panel[, .N, by = .(geo, nace_r2)]
cat(sprintf("Production panel: %d country-sector cells, median obs per cell = %d\n",
            nrow(prod_balance), median(prod_balance$N)))

# Gas dependence variation
cat("\nGas dependence distribution:\n")
gas_dep[order(-russian_gas_share), .(geo, russian_gas_share, gas_exposure)][1:10] |> print()

cat("\n=== 02_clean_data.R COMPLETE ===\n")
