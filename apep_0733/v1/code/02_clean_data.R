## 02_clean_data.R — Clean and construct analysis variables
## Paper: The Fortress Premium (apep_0733)

source("code/00_packages.R")

hesta <- fread("data/hesta_raw.csv")
fx    <- fread("data/fx_chf_eur.csv")

cat(sprintf("Raw HESTA: %d rows, %d cantons, %d origins, years %d-%d\n",
    nrow(hesta), uniqueN(hesta$canton), uniqueN(hesta$origin),
    min(hesta$year), max(hesta$year)))

# --- Classify origins by exchange rate exposure ---

# Eurozone countries (CHF appreciated ~12% against EUR)
eurozone_codes <- c(
  "11",  # Deutschland
  "13",  # Frankreich
  "14",  # Italien
  "15",  # Österreich
  "18",  # Niederlande
  "19",  # Belgien
  "22",  # Spanien
  "23",  # Portugal
  "24",  # Griechenland
  "25",  # Finnland
  "20"   # Luxemburg
)

# Swiss domestic (no FX effect — control group)
swiss_code <- "1"

# Non-euro European (partial FX exposure)
non_euro_europe_codes <- c(
  "16",  # Vereinigtes Königreich
  "17",  # Irland (EUR but separate category)
  "10",  # Baltische Staaten
  "12",  # Skandinavische Länder
  "21",  # Osteuropa
  "26",  # GUS-Staaten
  "27",  # Türkei
  "28"   # Weitere europäische Länder
)

# Non-European / long-haul (minimal CHF/EUR effect)
non_euro_long <- setdiff(
  unique(hesta$origin),
  c(eurozone_codes, swiss_code, non_euro_europe_codes)
)

# Create exposure classification
hesta[, exposure := fcase(
  origin == swiss_code, "swiss",
  origin %in% eurozone_codes, "eurozone",
  origin %in% non_euro_europe_codes, "non_euro_europe",
  default = "non_european"
)]

cat("\nExposure distribution:\n")
print(hesta[, .(
  origins = uniqueN(origin),
  total_nights = sum(nights, na.rm = TRUE),
  share = sum(nights, na.rm = TRUE) / sum(hesta$nights, na.rm = TRUE)
), by = exposure])

# --- Construct time variables ---
hesta[, post := as.integer(year >= 2015 | (year == 2015 & month >= 1))]
# Actually: post if year > 2014. Shock was Jan 15, 2015
hesta[, post := as.integer(year >= 2015)]
hesta[, ym := year * 100 + month]  # year-month numeric
hesta[, date := as.Date(sprintf("%d-%02d-01", year, month))]

# Event time: months relative to Jan 2015
hesta[, event_time := (year - 2015) * 12 + (month - 1)]

# --- Construct within-canton Bartik exposure ---
# Pre-shock (2014) share of each origin in each canton
pre_shares <- hesta[year == 2014, .(
  pre_nights = sum(nights, na.rm = TRUE)
), by = .(canton, origin)]

canton_totals <- pre_shares[, .(canton_total = sum(pre_nights)), by = canton]
pre_shares <- merge(pre_shares, canton_totals, by = "canton")
pre_shares[, share_2014 := pre_nights / canton_total]

# Eurozone share by canton (Bartik weight)
euro_share <- pre_shares[origin %in% eurozone_codes, .(
  euro_share_2014 = sum(share_2014)
), by = canton]

cat("\nEurozone share by canton (2014):\n")
euro_share_labeled <- merge(euro_share,
  unique(hesta[, .(canton, canton_name)]), by = "canton")
print(euro_share_labeled[order(-euro_share_2014)][1:10])

# Merge
hesta <- merge(hesta, euro_share, by = "canton", all.x = TRUE)

# Euro exposed dummy for individual origins
hesta[, euro_exposed := as.integer(origin %in% eurozone_codes)]

# --- Handle zeros and create log outcome ---
# Replace 0/NA with small value for log
hesta[is.na(nights), nights := 0]
hesta[, log_nights := log(pmax(nights, 1))]

# --- Drop 2026 (incomplete year) and keep 2005-2025 ---
hesta <- hesta[year <= 2025]

# --- Merge FX data ---
fx[, year := as.integer(substr(date, 1, 4))]
fx[, month := as.integer(substr(date, 6, 7))]
hesta <- merge(hesta, fx[, .(year, month, chf_per_eur)], by = c("year", "month"), all.x = TRUE)

# Log FX change relative to Dec 2014
dec2014_fx <- fx[year == 2014 & month == 12]$chf_per_eur
hesta[, log_fx_change := log(chf_per_eur / dec2014_fx)]

# --- Create canton-origin panel ID ---
hesta[, co := paste0(canton, "_", origin)]

# --- Summary stats ---
cat("\n=== Analysis Sample Summary ===\n")
cat(sprintf("Rows: %d\n", nrow(hesta)))
cat(sprintf("Years: %d to %d\n", min(hesta$year), max(hesta$year)))
cat(sprintf("Canton-origin pairs: %d\n", uniqueN(hesta$co)))
cat(sprintf("Pre-period months: %d (2005-2014)\n", sum(hesta$year < 2015) / uniqueN(hesta$co)))
cat(sprintf("Post-period months: %d (2015-2025)\n", sum(hesta$year >= 2015) / uniqueN(hesta$co)))

# Aggregate check: total nights by year
annual <- hesta[, .(total = sum(nights, na.rm = TRUE)), by = year]
cat("\nAnnual overnight stays:\n")
print(annual[order(year)])

fwrite(hesta, "data/hesta_clean.csv")
cat("\nSaved data/hesta_clean.csv\n")
