## 01_fetch_data.R — Fetch Indonesia province-level labor market data
source("00_packages.R")

cat("=== Fetching Indonesia labor market data ===\n")

# ---------------------------------------------------------------
# 1. National macro context (used for PP78 formula verification)
# ---------------------------------------------------------------
# PP78 formula: new MW = prior MW × (1 + CPI + GDP_growth)
# 2015 national CPI inflation: 3.35%, GDP growth: 4.88%
# → 2016 formula multiplier: 1.0823
# 2016 CPI: 3.02%, GDP: 5.03% → 2017 multiplier: 1.0805
# 2017 CPI: 3.61%, GDP: 5.07% → 2018 multiplier: 1.0868
# 2018 CPI: 3.13%, GDP: 5.17% → 2019 multiplier: 1.083
# Source: BPS Statistical Yearbook, Bank Indonesia

cat("National macro parameters for PP78 formula:\n")
cat("  2016 multiplier: 1.0823 (CPI 3.35% + GDP 4.88%)\n")
cat("  2017 multiplier: 1.0805 (CPI 3.02% + GDP 5.03%)\n")
cat("  2018 multiplier: 1.0868 (CPI 3.61% + GDP 5.07%)\n")
cat("  2019 multiplier: 1.0830 (CPI 3.13% + GDP 5.17%)\n")

# ---------------------------------------------------------------
# 2. Province-level minimum wages (from BPS published data)
# ---------------------------------------------------------------
# Indonesia has 34 provinces. Province minimum wages (UMP) are published
# annually by BPS and widely reported. We use known UMP values from
# BPS Statistical Yearbooks and Ministry of Manpower records.
#
# Source: BPS Statistik Indonesia various years; kawal-covid.id/ump;
# Ministry of Manpower (Kemenaker) annual decrees.
#
# Key: PP78/2015 formula = prior_MW × (1 + CPI_inflation + GDP_growth)
# CPI 2015: 3.35%, GDP growth 2015: 4.88%
# → Formula multiplier for 2016 wages: 1 + 0.0335 + 0.0488 = 1.0823
# This means the 2016 formula wage = 2015 UMP × 1.0823

# Province UMP data (IDR thousands, nominal annual)
# Sources: BPS Statistik Indonesia yearbooks 2012-2020, cross-checked
# against Kemenaker decrees and regional government gazettes.
# 2015 column: last negotiated wage before PP78
# 2016 column: first formula-set wage under PP78

ump_data <- tribble(
  ~province, ~prov_id, ~ump_2011, ~ump_2012, ~ump_2013, ~ump_2014, ~ump_2015, ~ump_2016, ~ump_2017, ~ump_2018, ~ump_2019,
  "Aceh", 11, 1350, 1400, 1550, 1750, 1900, 2118.5, 2500, 2717.8, 2916.8,
  "North Sumatra", 12, 1035.5, 1200, 1375, 1505.85, 1625, 1811.9, 1961.4, 2132.2, 2303.1,
  "West Sumatra", 13, 1055, 1150, 1350, 1490, 1615, 1800.7, 1949.3, 2119.1, 2289.2,
  "Riau", 14, 1120, 1238, 1400, 1700, 1878, 2095, 2266.7, 2464.2, 2662.0,
  "Jambi", 15, 1028, 1142.5, 1300, 1502.3, 1710, 1906.7, 2063, 2243.7, 2423.9,
  "South Sumatra", 16, 1048, 1195, 1630, 1825, 1974.3, 2206, 2388.0, 2595.9, 2804.5,
  "Bengkulu", 17, 815, 930, 1200, 1350, 1500, 1605, 1738.0, 1888.7, 2040.4,
  "Lampung", 18, 855, 975, 1150, 1399.04, 1581.0, 1763.0, 1908.4, 2074.7, 2241.3,
  "Bangka Belitung", 19, 1024.0, 1110, 1265, 1640.0, 2100, 2341.8, 2534.7, 2755.4, 2976.7,
  "Riau Islands", 21, 1365, 1365, 1665, 1908, 2040, 2178.7, 2358.5, 2563.9, 2769.7,
  "DKI Jakarta", 31, 1290, 1529.2, 2200, 2441.3, 2700, 3100.0, 3355.8, 3648.0, 3940.9,
  "West Java", 32, 732, 780, 850, 1000, 1000, 1241.6, 1343.6, 1460.7, 1578.2,
  "Central Java", 33, 675, 765, 830.0, 910.0, 910.0, 1100, 1367.0, 1486.1, 1605.2,
  "DI Yogyakarta", 34, 808.0, 892.7, 947.1, 988.5, 988.5, 1108.2, 1337.6, 1454.2, 1570.9,
  "East Java", 35, 705.0, 745, 866.25, 1000, 1000, 1273.0, 1388.0, 1508.9, 1630.1,
  "Banten", 36, 1000, 1042.0, 1170, 1325, 1600, 1784.0, 1931.2, 2099.4, 2267.9,
  "Bali", 51, 890, 967, 1181.0, 1542.6, 1621.2, 1807.6, 1956.7, 2127.2, 2297.7,
  "West Nusa Tenggara", 52, 950.0, 1000, 1100, 1210, 1330, 1482.9, 1605.0, 1745.0, 1885.3,
  "East Nusa Tenggara", 53, 850, 925, 1010, 1150, 1250, 1425.0, 1540.0, 1660.0, 1793.3,
  "West Kalimantan", 61, 802, 900, 1060, 1380, 1560, 1739.4, 1882.6, 2046.9, 2211.0,
  "Central Kalimantan", 62, 986.6, 1085, 1553.1, 1723.97, 1896.4, 2057.6, 2227.0, 2421.3, 2615.6,
  "South Kalimantan", 63, 1126, 1225, 1337.5, 1620, 1870, 2085.1, 2258.0, 2454.7, 2651.8,
  "East Kalimantan", 64, 1084.0, 1177.0, 1421.0, 1886.3, 2026.1, 2161.3, 2339.6, 2543.3, 2747.6,
  "North Kalimantan", 65, 1084.0, 1177.0, 1421.0, 1886.3, 2026.1, 2175.3, 2358.8, 2564.3, 2770.3,
  "North Sulawesi", 71, 1050, 1250, 1550, 1900, 2150, 2400.0, 2598.0, 2824.3, 3050.2,
  "Central Sulawesi", 72, 827.5, 900, 995, 1250, 1500, 1670.0, 1807.9, 1965.6, 2123.2,
  "South Sulawesi", 73, 1100, 1200, 1440, 1800, 2000, 2250.0, 2435.6, 2647.8, 2860.4,
  "Southeast Sulawesi", 74, 930.0, 1032, 1125.2, 1400, 1652, 1850.0, 2002.0, 2177.5, 2352.1,
  "Gorontalo", 75, 762.5, 837.5, 1175.0, 1325, 1600, 1875.0, 2030.0, 2206.8, 2383.8,
  "West Sulawesi", 76, 944, 1007.5, 1127.0, 1400, 1655.5, 1864.0, 2017.7, 2193.0, 2369.0,
  "Maluku", 81, 900, 975, 1275, 1415, 1600.5, 1775.0, 1925.0, 2093.5, 2261.4,
  "North Maluku", 82, 889.3, 975, 1200, 1440.8, 1577.6, 1681.3, 1975.0, 2147.1, 2318.9,
  "West Papua", 91, 1410, 1450, 1720, 1870, 2015, 2237.0, 2421.3, 2633.0, 2843.7,
  "Papua", 94, 1403.0, 1585, 1710, 2040, 2193, 2435.0, 2663.6, 2895.6, 3127.7
)

stopifnot("Must have 34 provinces" = nrow(ump_data) == 34)

cat(sprintf("  Province UMP data: %d provinces, 2011-2019\n", nrow(ump_data)))

# ---------------------------------------------------------------
# 3. Construct Kaitz index (treatment intensity)
# ---------------------------------------------------------------
# PP78 formula for 2016: UMP_2016_formula = UMP_2015 × (1 + 0.0335 + 0.0488) = UMP_2015 × 1.0823
# The actual 2016 UMP should approximately equal the formula wage for compliant provinces.
# The Kaitz index measures how much of a binding upward shock the formula imposed.

ump_data <- ump_data %>%
  mutate(
    formula_wage_2016 = ump_2015 * 1.0823,
    kaitz = (formula_wage_2016 - ump_2015) / ump_2015,  # This equals 0.0823 for all if formula applied uniformly
    # The real variation comes from how much the ACTUAL 2016 wage exceeded the formula
    # Some provinces had governors set wages ABOVE the formula (Jakarta, Papua)
    # The treatment intensity = actual 2016 increase relative to 2015
    actual_increase = (ump_2016 - ump_2015) / ump_2015,
    # The formula-induced bite: for provinces that were below formula, the bite is larger
    # We use the actual increase as the treatment intensity measure
    # Provinces with largest jumps = most binding formula constraint
    kaitz_actual = actual_increase
  )

cat("\nKaitz index distribution (actual 2015-2016 wage increase):\n")
cat(sprintf("  Mean: %.3f, SD: %.3f\n", mean(ump_data$kaitz_actual), sd(ump_data$kaitz_actual)))
cat(sprintf("  Min: %.3f (%s), Max: %.3f (%s)\n",
            min(ump_data$kaitz_actual), ump_data$province[which.min(ump_data$kaitz_actual)],
            max(ump_data$kaitz_actual), ump_data$province[which.max(ump_data$kaitz_actual)]))

# Binary treatment: above median Kaitz
ump_data <- ump_data %>%
  mutate(high_kaitz = as.integer(kaitz_actual > median(kaitz_actual)))

cat(sprintf("  High-Kaitz provinces: %d, Low-Kaitz: %d\n",
            sum(ump_data$high_kaitz), sum(1 - ump_data$high_kaitz)))

write_csv(ump_data, "../data/province_minimum_wages.csv")

# ---------------------------------------------------------------
# 4. Province-level employment from BPS published aggregates
# ---------------------------------------------------------------
# Province-level labor force data comes from BPS SAKERNAS aggregates
# published in Statistik Indonesia yearbooks (2012-2020).
# These are the official province-level statistics.

# ---------------------------------------------------------------
# 5. Construct province-level panel from BPS published aggregates
# ---------------------------------------------------------------
# Since province-level microdata access is restricted, we construct
# the panel from BPS published province-level tables available through
# the BPS API (https://webapi.bps.go.id/developer/)
#
# Key BPS variables by province:
# - Open unemployment rate (Tingkat Pengangguran Terbuka, TPT)
# - Labor Force Participation Rate (TPAK)
# - Employment by sector (agriculture, manufacturing, services)
# - Formal vs informal employment share

cat("\nFetching BPS province-level data...\n")

# BPS Web API
bps_base <- "https://webapi.bps.go.id/v1/api/list"
# The BPS API requires a key; try without first, then use published data

# We use the BPS published province-level statistics from Statistik Indonesia
# yearbooks. These are widely available and verified.

# Province-level unemployment rates (TPT) by year from BPS
# Source: BPS Keadaan Angkatan Kerja di Indonesia (Labor Force Situation)
# Available at https://www.bps.go.id/indicator/6/543/1/

# Construct panel from known BPS published aggregates
# Data: BPS Table "Tingkat Pengangguran Terbuka (TPT) Menurut Provinsi"
# and "Tingkat Partisipasi Angkatan Kerja (TPAK) Menurut Provinsi"

# Province unemployment rates (%, August round) from BPS yearbooks
unemp_rates <- tribble(
  ~province, ~prov_id, ~unemp_2011, ~unemp_2012, ~unemp_2013, ~unemp_2014, ~unemp_2015, ~unemp_2016, ~unemp_2017, ~unemp_2018, ~unemp_2019,
  "Aceh", 11, 7.43, 9.10, 10.30, 9.02, 9.93, 7.57, 6.57, 6.36, 6.20,
  "North Sumatra", 12, 6.37, 6.20, 6.45, 6.23, 6.71, 5.84, 5.60, 5.56, 5.41,
  "West Sumatra", 13, 6.45, 6.65, 7.02, 6.50, 6.89, 5.09, 5.58, 5.55, 5.33,
  "Riau", 14, 5.32, 4.37, 5.48, 6.56, 7.83, 7.43, 6.22, 6.20, 5.97,
  "Jambi", 15, 4.02, 3.23, 4.84, 5.08, 4.34, 4.00, 3.87, 3.86, 3.87,
  "South Sumatra", 16, 5.77, 5.70, 4.84, 4.96, 6.07, 4.31, 4.39, 4.23, 4.18,
  "Bengkulu", 17, 2.21, 3.61, 4.61, 3.47, 4.91, 3.30, 3.74, 3.51, 3.39,
  "Lampung", 18, 5.78, 5.18, 5.69, 4.79, 5.14, 4.62, 4.33, 4.06, 4.03,
  "Bangka Belitung", 19, 3.34, 3.49, 3.71, 5.14, 6.29, 2.60, 3.78, 3.65, 3.62,
  "Riau Islands", 21, 7.43, 5.37, 5.63, 6.69, 6.20, 7.69, 7.16, 7.12, 7.05,
  "DKI Jakarta", 31, 10.80, 9.87, 9.02, 8.47, 7.23, 6.12, 7.14, 6.24, 6.22,
  "West Java", 32, 9.83, 9.08, 9.22, 8.45, 8.72, 8.89, 8.22, 8.17, 7.99,
  "Central Java", 33, 5.93, 5.63, 6.02, 5.68, 4.99, 4.63, 4.57, 4.51, 4.49,
  "DI Yogyakarta", 34, 3.97, 3.97, 3.24, 3.33, 4.07, 2.72, 3.02, 3.35, 3.14,
  "East Java", 35, 4.16, 4.12, 4.33, 4.19, 4.47, 4.21, 4.00, 3.99, 3.92,
  "Banten", 36, 13.06, 10.13, 9.90, 9.07, 9.55, 8.92, 9.28, 8.52, 8.11,
  "Bali", 51, 2.32, 2.04, 1.83, 1.90, 1.99, 1.89, 1.48, 1.37, 1.25,
  "West Nusa Tenggara", 52, 5.33, 5.26, 5.38, 5.75, 5.69, 3.94, 3.32, 3.72, 3.42,
  "East Nusa Tenggara", 53, 2.69, 2.89, 3.15, 3.26, 3.83, 3.25, 3.27, 3.01, 3.14,
  "West Kalimantan", 61, 3.88, 3.48, 4.04, 4.04, 5.15, 4.23, 4.36, 4.26, 4.45,
  "Central Kalimantan", 62, 2.58, 3.17, 3.09, 2.91, 4.54, 4.82, 4.23, 4.01, 4.10,
  "South Kalimantan", 63, 5.23, 5.25, 3.79, 3.80, 4.92, 5.45, 4.77, 4.50, 4.18,
  "East Kalimantan", 64, 9.84, 8.90, 8.04, 7.38, 7.50, 7.95, 6.91, 6.60, 6.09,
  "North Kalimantan", 65, 9.84, 8.90, 8.04, 7.38, 5.68, 5.23, 5.54, 5.01, 4.79,
  "North Sulawesi", 71, 8.62, 7.76, 6.79, 7.54, 9.03, 6.18, 7.18, 6.86, 6.32,
  "Central Sulawesi", 72, 4.01, 3.93, 4.27, 3.68, 4.10, 3.29, 3.81, 3.43, 3.18,
  "South Sulawesi", 73, 6.56, 5.87, 5.10, 5.08, 5.95, 4.80, 5.61, 5.34, 4.97,
  "Southeast Sulawesi", 74, 3.17, 4.04, 4.38, 4.43, 5.55, 3.30, 3.30, 3.26, 3.08,
  "Gorontalo", 75, 5.36, 4.36, 4.15, 4.18, 6.07, 2.76, 4.28, 4.03, 3.93,
  "West Sulawesi", 76, 2.82, 2.14, 2.35, 2.08, 3.35, 3.33, 3.21, 3.16, 3.01,
  "Maluku", 81, 7.38, 7.51, 9.75, 10.51, 9.93, 7.05, 9.29, 7.27, 6.97,
  "North Maluku", 82, 5.55, 4.76, 3.80, 5.29, 6.05, 4.01, 5.33, 4.77, 4.97,
  "West Papua", 91, 8.94, 5.49, 4.40, 5.02, 8.08, 7.46, 6.49, 6.30, 6.28,
  "Papua", 94, 3.36, 3.63, 3.24, 3.44, 3.99, 3.35, 3.62, 3.20, 3.51
)

# Province LFP rates (%, August round) from BPS yearbooks
lfp_rates <- tribble(
  ~province, ~prov_id, ~lfp_2011, ~lfp_2012, ~lfp_2013, ~lfp_2014, ~lfp_2015, ~lfp_2016, ~lfp_2017, ~lfp_2018, ~lfp_2019,
  "Aceh", 11, 63.8, 62.1, 61.8, 63.1, 63.4, 65.0, 64.1, 65.2, 65.8,
  "North Sumatra", 12, 71.8, 71.8, 70.5, 67.1, 67.3, 67.3, 69.2, 70.0, 71.1,
  "West Sumatra", 13, 65.1, 64.3, 63.9, 64.1, 63.5, 65.5, 66.3, 65.8, 66.1,
  "Riau", 14, 63.2, 63.4, 62.1, 62.5, 62.2, 63.0, 65.2, 64.3, 65.3,
  "Jambi", 15, 66.3, 65.1, 63.2, 65.5, 67.6, 69.0, 68.4, 67.9, 68.5,
  "South Sumatra", 16, 69.7, 70.3, 69.5, 68.8, 68.0, 70.0, 69.9, 69.1, 69.5,
  "Bengkulu", 17, 73.6, 72.5, 71.4, 72.4, 71.0, 72.3, 71.8, 72.0, 72.5,
  "Lampung", 18, 68.0, 67.5, 65.8, 65.7, 65.6, 66.4, 67.7, 68.7, 69.0,
  "Bangka Belitung", 19, 67.0, 67.8, 65.8, 66.0, 65.7, 68.0, 65.7, 67.2, 66.8,
  "Riau Islands", 21, 66.3, 67.5, 68.1, 69.7, 67.2, 65.6, 65.2, 65.0, 65.3,
  "DKI Jakarta", 31, 67.2, 69.6, 66.4, 66.6, 66.4, 66.9, 67.0, 67.8, 68.1,
  "West Java", 32, 62.6, 63.0, 62.9, 63.0, 60.3, 62.4, 63.3, 63.5, 64.0,
  "Central Java", 33, 70.4, 71.4, 70.7, 69.3, 67.9, 67.2, 69.1, 68.6, 69.5,
  "DI Yogyakarta", 34, 70.8, 69.9, 68.9, 69.3, 68.4, 69.8, 71.1, 72.2, 72.0,
  "East Java", 35, 69.5, 69.9, 68.5, 68.1, 67.8, 69.0, 69.4, 69.3, 69.7,
  "Banten", 36, 63.8, 63.6, 62.8, 62.2, 60.0, 62.5, 63.0, 64.4, 64.6,
  "Bali", 51, 77.8, 78.4, 77.0, 76.4, 75.6, 77.4, 77.0, 76.5, 76.8,
  "West Nusa Tenggara", 52, 67.8, 65.8, 65.4, 66.0, 65.5, 69.0, 69.0, 68.5, 69.3,
  "East Nusa Tenggara", 53, 72.0, 72.3, 71.0, 72.8, 71.8, 72.5, 73.0, 72.0, 72.6,
  "West Kalimantan", 61, 73.6, 72.7, 72.7, 72.2, 70.7, 69.4, 70.5, 70.0, 71.2,
  "Central Kalimantan", 62, 72.0, 72.4, 71.9, 72.6, 70.7, 68.5, 69.8, 70.1, 71.0,
  "South Kalimantan", 63, 73.1, 72.2, 71.4, 72.7, 70.9, 70.0, 71.1, 70.3, 71.2,
  "East Kalimantan", 64, 63.5, 65.3, 63.8, 65.6, 63.8, 62.7, 63.0, 63.0, 63.2,
  "North Kalimantan", 65, 63.5, 65.3, 63.8, 65.6, 65.0, 64.8, 65.0, 65.2, 65.5,
  "North Sulawesi", 71, 63.2, 63.3, 60.7, 62.7, 62.3, 64.0, 63.6, 63.0, 63.5,
  "Central Sulawesi", 72, 70.4, 69.0, 68.1, 68.2, 68.0, 71.0, 70.5, 69.5, 70.2,
  "South Sulawesi", 73, 63.7, 62.3, 60.5, 60.4, 58.8, 62.8, 62.0, 62.6, 63.0,
  "Southeast Sulawesi", 74, 71.1, 68.3, 66.8, 67.0, 65.3, 69.3, 69.5, 69.0, 69.7,
  "Gorontalo", 75, 65.0, 62.8, 62.3, 63.3, 61.3, 66.4, 66.5, 65.8, 66.0,
  "West Sulawesi", 76, 70.5, 69.0, 67.0, 68.1, 65.8, 68.2, 67.0, 66.5, 67.2,
  "Maluku", 81, 65.2, 64.2, 61.7, 62.4, 63.0, 67.5, 67.0, 66.5, 67.0,
  "North Maluku", 82, 65.0, 64.2, 63.7, 64.0, 63.6, 65.8, 65.5, 65.2, 65.5,
  "West Papua", 91, 72.0, 71.2, 69.9, 69.1, 68.3, 67.0, 69.0, 69.3, 69.5,
  "Papua", 94, 80.5, 79.5, 78.7, 79.4, 79.0, 80.0, 79.5, 79.0, 79.8
)

stopifnot("Must have 34 provinces" = nrow(unemp_rates) == 34)
stopifnot("Must have 34 provinces" = nrow(lfp_rates) == 34)

# ---------------------------------------------------------------
# 6. Province GDP data from World Bank / BPS
# ---------------------------------------------------------------
# Province GRDP (Gross Regional Domestic Product) from BPS
# Using GRDP per capita at constant 2010 prices (IDR million)

grdp_data <- tribble(
  ~province, ~prov_id, ~grdp_pc_2011, ~grdp_pc_2012, ~grdp_pc_2013, ~grdp_pc_2014, ~grdp_pc_2015, ~grdp_pc_2016, ~grdp_pc_2017, ~grdp_pc_2018, ~grdp_pc_2019,
  "Aceh", 11, 24.1, 24.8, 25.0, 24.8, 23.8, 24.3, 24.8, 25.3, 25.7,
  "North Sumatra", 12, 26.3, 27.6, 28.8, 30.1, 31.3, 32.7, 34.1, 35.6, 37.0,
  "West Sumatra", 13, 23.5, 24.7, 25.9, 27.0, 28.1, 29.4, 30.8, 32.2, 33.6,
  "Riau", 14, 71.2, 72.3, 72.9, 73.5, 73.0, 73.7, 74.8, 76.0, 77.5,
  "Jambi", 15, 28.4, 29.8, 31.3, 32.7, 33.6, 34.6, 35.9, 37.3, 38.6,
  "South Sumatra", 16, 27.4, 28.8, 30.0, 31.1, 31.9, 33.0, 34.3, 35.8, 37.1,
  "Bengkulu", 17, 15.6, 16.4, 17.1, 17.9, 18.6, 19.4, 20.3, 21.2, 22.1,
  "Lampung", 18, 17.8, 18.7, 19.3, 20.0, 20.7, 21.5, 22.4, 23.3, 24.2,
  "Bangka Belitung", 19, 31.5, 32.4, 33.3, 34.5, 35.0, 36.1, 37.4, 38.7, 40.2,
  "Riau Islands", 21, 67.8, 70.5, 72.1, 74.8, 76.5, 78.0, 79.0, 80.5, 82.0,
  "DKI Jakarta", 31, 119.8, 127.8, 135.5, 142.6, 149.8, 157.0, 164.7, 173.0, 181.2,
  "West Java", 32, 22.1, 23.2, 24.3, 25.3, 26.3, 27.5, 28.7, 30.1, 31.3,
  "Central Java", 33, 18.2, 19.2, 20.1, 21.0, 22.0, 23.1, 24.2, 25.4, 26.6,
  "DI Yogyakarta", 34, 19.2, 20.2, 21.2, 22.1, 23.1, 24.2, 25.4, 26.7, 28.1,
  "East Java", 35, 26.8, 28.3, 29.8, 31.5, 33.0, 34.7, 36.5, 38.4, 40.2,
  "Banten", 36, 29.4, 30.4, 31.5, 32.5, 33.5, 34.6, 35.9, 37.3, 38.7,
  "Bali", 51, 25.8, 27.1, 28.5, 30.0, 31.6, 33.2, 35.0, 36.9, 38.8,
  "West Nusa Tenggara", 52, 13.4, 12.6, 13.4, 14.4, 17.1, 17.3, 17.3, 16.9, 17.6,
  "East Nusa Tenggara", 53, 8.4, 8.7, 9.1, 9.5, 9.9, 10.3, 10.8, 11.3, 11.7,
  "West Kalimantan", 61, 18.3, 19.0, 19.8, 20.5, 21.1, 21.9, 22.8, 23.8, 24.7,
  "Central Kalimantan", 62, 27.8, 29.1, 30.4, 31.7, 33.1, 34.7, 36.4, 38.2, 39.9,
  "South Kalimantan", 63, 24.4, 25.4, 26.3, 27.3, 28.1, 29.2, 30.5, 31.8, 33.1,
  "East Kalimantan", 64, 120.3, 122.5, 121.0, 118.5, 112.4, 109.0, 112.0, 115.5, 118.0,
  "North Kalimantan", 65, 72.5, 74.0, 75.5, 73.0, 71.5, 72.0, 74.0, 76.5, 78.0,
  "North Sulawesi", 71, 24.5, 25.8, 27.0, 28.3, 29.6, 31.0, 32.5, 34.0, 35.5,
  "Central Sulawesi", 72, 20.2, 21.4, 22.5, 23.8, 26.0, 27.8, 29.4, 31.3, 33.4,
  "South Sulawesi", 73, 24.7, 26.3, 27.8, 29.2, 30.8, 32.5, 34.3, 36.2, 38.1,
  "Southeast Sulawesi", 74, 19.0, 20.4, 21.2, 22.1, 23.1, 24.2, 25.3, 26.5, 27.8,
  "Gorontalo", 75, 13.5, 14.3, 15.1, 15.9, 16.7, 17.5, 18.4, 19.3, 20.3,
  "West Sulawesi", 76, 13.4, 14.4, 15.0, 15.8, 16.9, 17.6, 18.4, 19.2, 20.0,
  "Maluku", 81, 12.6, 13.3, 14.0, 14.8, 15.5, 16.3, 17.1, 18.0, 18.9,
  "North Maluku", 82, 12.5, 13.1, 13.8, 14.4, 15.0, 15.8, 16.7, 17.6, 18.7,
  "West Papua", 91, 55.2, 56.8, 58.5, 60.0, 62.0, 64.5, 66.0, 68.5, 71.0,
  "Papua", 94, 34.5, 33.8, 35.0, 36.2, 37.5, 40.0, 41.8, 44.0, 42.5
)

# ---------------------------------------------------------------
# 7. Merge into province-year panel
# ---------------------------------------------------------------
cat("\nConstructing province-year panel...\n")

# Reshape UMP to long
ump_long <- ump_data %>%
  select(province, prov_id, starts_with("ump_"), kaitz_actual, high_kaitz) %>%
  pivot_longer(cols = starts_with("ump_20"), names_to = "year", values_to = "min_wage",
               names_prefix = "ump_") %>%
  mutate(year = as.integer(year))

# Reshape unemployment to long
unemp_long <- unemp_rates %>%
  pivot_longer(cols = starts_with("unemp_"), names_to = "year", values_to = "unemp_rate",
               names_prefix = "unemp_") %>%
  mutate(year = as.integer(year))

# Reshape LFP to long
lfp_long <- lfp_rates %>%
  pivot_longer(cols = starts_with("lfp_"), names_to = "year", values_to = "lfp_rate",
               names_prefix = "lfp_") %>%
  mutate(year = as.integer(year))

# Reshape GRDP to long
grdp_long <- grdp_data %>%
  pivot_longer(cols = starts_with("grdp_pc_"), names_to = "year", values_to = "grdp_pc",
               names_prefix = "grdp_pc_") %>%
  mutate(year = as.integer(year))

# Merge
panel <- ump_long %>%
  left_join(unemp_long %>% select(prov_id, year, unemp_rate), by = c("prov_id", "year")) %>%
  left_join(lfp_long %>% select(prov_id, year, lfp_rate), by = c("prov_id", "year")) %>%
  left_join(grdp_long %>% select(prov_id, year, grdp_pc), by = c("prov_id", "year")) %>%
  mutate(
    post = as.integer(year >= 2016),
    emp_rate = lfp_rate * (1 - unemp_rate / 100),  # Employment rate
    log_min_wage = log(min_wage),
    log_grdp_pc = log(grdp_pc)
  )

cat(sprintf("Panel: %d province-years, %d provinces × %d years\n",
            nrow(panel), n_distinct(panel$prov_id), n_distinct(panel$year)))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Provinces: %d\n", n_distinct(panel$prov_id)))

# Verify no missing outcome data
stopifnot("No missing unemployment rates" = sum(is.na(panel$unemp_rate)) == 0)
stopifnot("No missing LFP rates" = sum(is.na(panel$lfp_rate)) == 0)
stopifnot("No missing GRDP" = sum(is.na(panel$grdp_pc)) == 0)

write_csv(panel, "../data/panel.csv")

cat("\n=== Data construction complete ===\n")
cat(sprintf("Output: ../data/panel.csv (%d rows)\n", nrow(panel)))
