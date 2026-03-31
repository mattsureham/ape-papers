# 02_clean_data.R — Construct analysis panel for apep_1184
# EU Airport Slot Waivers and Competition

source("00_packages.R")

cat("=== Building analysis panel ===\n")

# ─────────────────────────────────────────────────────────────────────
# 1. Load raw data
# ─────────────────────────────────────────────────────────────────────
avia_total <- readRDS("../data/avia_total_annual.rds")
avia_sched <- readRDS("../data/avia_sched_annual.rds")
avia_nonsched <- readRDS("../data/avia_nonsched_annual.rds")

dt_total <- as.data.table(avia_total)
dt_sched <- as.data.table(avia_sched)
dt_nonsched <- as.data.table(avia_nonsched)

# Parse year
dt_total[, year := as.integer(time)]
dt_sched[, year := as.integer(time)]
dt_nonsched[, year := as.integer(time)]

# ─────────────────────────────────────────────────────────────────────
# 2. Level 3 (Fully Coordinated) Airport Classification
#    Based on EUACA/ACI slot coordination lists
#    These airports must comply with the 80/20 use-it-or-lose-it rule
#    Level 3 status was assigned pre-COVID based on congestion
# ─────────────────────────────────────────────────────────────────────

# Major Level 3 coordinated airports in the EU/EEA
# Source: EUACA coordination lists, Regulation 95/93 registry
# Using ICAO codes as they appear in Eurostat (CC_ICAO format)
level3_airports <- c(
  # Germany
  "DE_EDDF",  # Frankfurt
  "DE_EDDM",  # Munich
  "DE_EDDB",  # Berlin Brandenburg (BER, opened Oct 2020)
  "DE_EDDL",  # Düsseldorf
  "DE_EDDH",  # Hamburg
  "DE_EDDS",  # Stuttgart
  "DE_EDDC",  # Dresden (was level 3 for summer seasons)
  "DE_EDDP",  # Leipzig
  "DE_EDDK",  # Cologne/Bonn
  "DE_EDDW",  # Bremen (seasonal)
  # France
  "FR_LFPG",  # Paris CDG
  "FR_LFPO",  # Paris Orly
  "FR_LFML",  # Marseille
  "FR_LFLL",  # Lyon
  "FR_LFMN",  # Nice
  "FR_LFBD",  # Bordeaux
  "FR_LFBO",  # Toulouse
  # Netherlands
  "NL_EHAM",  # Amsterdam Schiphol
  # Spain
  "ES_LEMD",  # Madrid
  "ES_LEBL",  # Barcelona
  "ES_LEPA",  # Palma de Mallorca
  "ES_LEMG",  # Malaga
  "ES_GCLP",  # Gran Canaria
  "ES_GCFV",  # Fuerteventura
  "ES_GCTS",  # Tenerife Sur
  "ES_LEAL",  # Alicante
  "ES_LEIB",  # Ibiza
  # Italy
  "IT_LIRF",  # Rome Fiumicino
  "IT_LIMC",  # Milan Malpensa
  "IT_LIME",  # Milan Bergamo
  "IT_LIPZ",  # Venice
  "IT_LIRN",  # Naples
  "IT_LICC",  # Catania
  "IT_LIPE",  # Bologna
  # UK (pre-Brexit, still in Eurostat data through 2019)
  "UK_EGLL",  # London Heathrow
  "UK_EGKK",  # London Gatwick
  "UK_EGSS",  # London Stansted
  "UK_EGCC",  # Manchester
  # Ireland
  "IE_EIDW",  # Dublin
  # Portugal
  "PT_LPPT",  # Lisbon
  "PT_LPFR",  # Faro
  # Austria
  "AT_LOWW",  # Vienna
  # Belgium
  "BE_EBBR",  # Brussels
  # Greece
  "EL_LGAV",  # Athens
  "EL_LGIR",  # Heraklion
  "EL_LGTS",  # Thessaloniki
  # Sweden
  "SE_ESSA",  # Stockholm Arlanda
  # Denmark
  "DK_EKCH",  # Copenhagen
  # Finland
  "FI_EFHK",  # Helsinki
  # Czech Republic
  "CZ_LKPR",  # Prague
  # Poland
  "PL_EPWA",  # Warsaw
  "PL_EPKK",  # Krakow
  # Romania
  "RO_LROP",  # Bucharest
  # Hungary
  "HU_LHBP",  # Budapest
  # Croatia
  "HR_LDDU",  # Dubrovnik
  "HR_LDZA",  # Zagreb
  # Norway (EEA)
  "NO_ENGM",  # Oslo Gardermoen
  # Switzerland (EEA/bilateral)
  "CH_LSZH",  # Zurich
  "CH_LSGG",  # Geneva
  # Cyprus
  "CY_LCLK",  # Larnaca
  # Malta
  "MT_LMML",  # Malta
  # Luxembourg
  "LU_ELLX",  # Luxembourg
  # Bulgaria
  "BG_LBSF",  # Sofia
  # Latvia
  "LV_EVRA",  # Riga
  # Lithuania
  "LT_EYVI",  # Vilnius
  # Estonia
  "EE_EETN",  # Tallinn
  # Slovakia
  "SK_LZIB",  # Bratislava
  # Slovenia
  "SI_LJLJ"   # Ljubljana
)

# ─────────────────────────────────────────────────────────────────────
# 3. Construct treatment variables
# ─────────────────────────────────────────────────────────────────────

# Slot threshold by year (annual)
# Pre-COVID: 80% constant
# 2020: 0% (full waiver, March-December)
# 2021: 50% (summer season), ~25% weighted annual
# 2022: 64% (summer), 75% (winter) → ~67% weighted
# 2023: 80% restored (summer 2023 onwards)
# We approximate the annual average threshold
slot_threshold <- data.table(
  year = 2016:2024,
  threshold = c(80, 80, 80, 80,  # 2016-2019: constant
                0,               # 2020: full waiver
                50,              # 2021: 50% summer
                64,              # 2022: 64% summer, 75% winter
                80,              # 2023: restored
                80)              # 2024: restored
)

# Deviation from pre-COVID norm (80%)
slot_threshold[, threshold_gap := 80 - threshold]
# Normalized treatment intensity (0 = full rule, 1 = full waiver)
slot_threshold[, waiver_intensity := threshold_gap / 80]

# ─────────────────────────────────────────────────────────────────────
# 4. Merge and construct analysis panel
# ─────────────────────────────────────────────────────────────────────

# Total passengers panel
panel <- dt_total[!is.na(values) & year >= 2016 & year <= 2024,
  .(airport = rep_airp, year, pax_total = values)]

# Add scheduled passengers
sched <- dt_sched[!is.na(values) & year >= 2016 & year <= 2024,
  .(airport = rep_airp, year, pax_sched = values)]
panel <- merge(panel, sched, by = c("airport", "year"), all.x = TRUE)

# Add non-scheduled passengers
nonsched <- dt_nonsched[!is.na(values) & year >= 2016 & year <= 2024,
  .(airport = rep_airp, year, pax_nonsched = values)]
panel <- merge(panel, nonsched, by = c("airport", "year"), all.x = TRUE)

# Add Level 3 indicator
panel[, level3 := as.integer(airport %in% level3_airports)]

# Merge slot threshold
panel <- merge(panel, slot_threshold, by = "year", all.x = TRUE)

# Treatment: Level3 × threshold
panel[, treat_continuous := level3 * waiver_intensity]

# Extract country code from airport code (first 2 characters)
panel[, country := substr(airport, 1, 2)]

# Log passengers (add 1 for zeros)
panel[, log_pax := log(pax_total + 1)]
panel[, log_pax_sched := log(pax_sched + 1)]
panel[, log_pax_nonsched := log(pax_nonsched + 1)]

# Pre-treatment passenger share (for heterogeneity)
panel[, pax_2019 := pax_total[year == 2019], by = airport]

# ─────────────────────────────────────────────────────────────────────
# 5. Drop UK airports post-Brexit (left EU Jan 2020)
#    UK airports are no longer subject to EU slot regulation after 2019
# ─────────────────────────────────────────────────────────────────────
cat("UK airports before drop:", sum(panel$country == "UK"), "obs\n")
# Keep UK in pre-period for comparison, but they should NOT be in
# Level 3 treatment group post-2019 since they're under UK CAA rules
panel[country == "UK" & year >= 2020, level3 := 0L]
panel[country == "UK" & year >= 2020, treat_continuous := 0]

# Also handle Switzerland (bilateral agreement, similar rules but separate)
# and Norway/Iceland (EEA — they follow EU slot rules)
# Keep CH and NO in treatment as they follow equivalent rules via EEA/bilateral

# ─────────────────────────────────────────────────────────────────────
# 6. Quarterly panel (if available)
# ─────────────────────────────────────────────────────────────────────
if (file.exists("../data/avia_quarterly.rds")) {
  cat("Building quarterly panel...\n")
  dt_q <- as.data.table(readRDS("../data/avia_quarterly.rds"))

  # Parse quarter
  dt_q[, year := as.integer(substr(time, 1, 4))]
  dt_q[, quarter := as.integer(gsub(".*Q", "", time))]
  dt_q[, yq := year + (quarter - 1) / 4]

  panel_q <- dt_q[!is.na(values) & year >= 2016 & year <= 2024,
    .(airport = rep_airp, year, quarter, yq, pax_total = values)]

  panel_q[, level3 := as.integer(airport %in% level3_airports)]
  panel_q[, country := substr(airport, 1, 2)]

  # UK post-Brexit adjustment
  panel_q[country == "UK" & year >= 2020, level3 := 0L]

  # Quarterly slot thresholds (more precise than annual)
  # 2020Q1: 80% (pre-waiver through mid-March)
  # 2020Q2-Q4: 0%
  # 2021Q1: 0% (winter season extension)
  # 2021Q2-Q3: 50% (summer 2021)
  # 2021Q4: 50% (winter 2021/22)
  # 2022Q1: 50% (winter 2021/22 continued)
  # 2022Q2-Q3: 64% (summer 2022)
  # 2022Q4: 75% (winter 2022/23)
  # 2023Q1: 75% (winter 2022/23 continued)
  # 2023Q2+: 80% (restored)
  q_thresholds <- data.table(
    year = c(rep(2016:2019, each = 4),
             2020, 2020, 2020, 2020,
             2021, 2021, 2021, 2021,
             2022, 2022, 2022, 2022,
             2023, 2023, 2023, 2023,
             2024, 2024, 2024, 2024),
    quarter = rep(1:4, 9),
    threshold_q = c(rep(80, 16),          # 2016-2019
                    80, 0, 0, 0,           # 2020
                    0, 50, 50, 50,         # 2021
                    50, 64, 64, 75,        # 2022
                    75, 80, 80, 80,        # 2023
                    80, 80, 80, 80)        # 2024
  )
  q_thresholds[, waiver_intensity_q := (80 - threshold_q) / 80]

  panel_q <- merge(panel_q, q_thresholds, by = c("year", "quarter"), all.x = TRUE)
  panel_q[, treat_continuous := level3 * waiver_intensity_q]
  panel_q[, log_pax := log(pax_total + 1)]

  saveRDS(panel_q, "../data/panel_quarterly.rds")
  cat(sprintf("Quarterly panel: %d obs, %d airports, %d quarters\n",
      nrow(panel_q), length(unique(panel_q$airport)),
      length(unique(panel_q$yq))))
}

# ─────────────────────────────────────────────────────────────────────
# 7. Summary statistics
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
cat(sprintf("Total obs: %d\n", nrow(panel)))
cat(sprintf("Airports: %d (Level 3: %d, Level 1/2: %d)\n",
    length(unique(panel$airport)),
    length(unique(panel[level3 == 1]$airport)),
    length(unique(panel[level3 == 0]$airport))))
cat(sprintf("Years: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("Countries: %d\n", length(unique(panel$country))))

# Level 3 airports actually in the data
level3_in_data <- unique(panel[level3 == 1]$airport)
cat(sprintf("\nLevel 3 airports in data: %d\n", length(level3_in_data)))
cat("Missing Level 3 airports:\n")
missing <- setdiff(level3_airports, unique(panel$airport))
if (length(missing) > 0) cat("  ", paste(missing, collapse = ", "), "\n")

# Mean passengers by group and period
cat("\nMean annual passengers (millions):\n")
print(panel[, .(mean_pax_M = mean(pax_total, na.rm=TRUE) / 1e6,
               airports = .N),
  by = .(level3, period = ifelse(year <= 2019, "Pre-COVID", "Post-COVID"))][
    order(level3, period)])

# ─────────────────────────────────────────────────────────────────────
# 8. Save analysis panel
# ─────────────────────────────────────────────────────────────────────
saveRDS(panel, "../data/panel_annual.rds")
cat("\nSaved panel_annual.rds\n")

cat("\n=== Panel construction complete ===\n")
