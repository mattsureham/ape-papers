# 02_clean_data.R — Clean and classify Comtrade data with BEC categories
# APEP-0569: Egypt Devaluation Import Compression

source("00_packages.R")
DATA_DIR <- "../data"

# ============================================================
# PART 1: Load HS6 panel
# ============================================================
cat("Loading HS6 panel...\n")
panel <- fread(file.path(DATA_DIR, "comtrade_egy_hs6_panel.csv"))

# Use primaryValue (most complete); fall back to cifvalue
panel[, import_value := fifelse(!is.na(primaryValue) & primaryValue > 0,
  primaryValue,
  fifelse(!is.na(cifvalue) & cifvalue > 0, cifvalue, NA_real_)
)]

# Extract HS2 and HS4 from HS6 code
panel[, hs6 := as.character(cmdCode)]
panel[, hs2 := substr(hs6, 1, 2)]
panel[, hs4 := substr(hs6, 1, 4)]
panel[, year := as.integer(refYear)]

# Drop rows with zero or missing import values
panel <- panel[!is.na(import_value) & import_value > 0]
cat(sprintf("After cleaning: %d rows, %d products, %d years\n",
  nrow(panel), uniqueN(panel$hs6), uniqueN(panel$year)))

# ============================================================
# PART 2: BEC classification at HS2/HS4 level
# ============================================================
# Classify each HS6 product into: intermediate, capital, or final
# Based on standard BEC Rev.4/5 correspondence rules

classify_bec <- function(hs2, hs4) {
  hs2_num <- as.integer(hs2)
  hs4_num <- as.integer(hs4)

  # --- FUELS (separate category for robustness) ---
  if (hs2_num == 27) return("fuels")

  # --- CLEARLY INTERMEDIATE ---
  # Minerals, ores
  if (hs2_num %in% c(25, 26)) return("intermediate")
  # Chemicals (inorganic, organic, pharma intermediates, fertilizers, etc.)
  if (hs2_num %in% 28:38) return("intermediate")
  # Plastics in primary forms, rubber raw
  if (hs2_num %in% c(39, 40)) {
    # Consumer plastics/rubber products
    if (hs4_num %in% c(3922:3926, 4014:4017)) return("final")
    return("intermediate")
  }
  # Leather, furs, wood, cork, straw, pulp, paper (raw/semi-processed)
  if (hs2_num %in% 41:49) {
    # Printed books, newspapers → final
    if (hs4_num %in% 4901:4911) return("final")
    return("intermediate")
  }
  # Textile fibers, yarns, fabrics (raw/semi-processed)
  if (hs2_num %in% 50:55) return("intermediate")
  # Stone, ceramics, glass
  if (hs2_num %in% 68:70) return("intermediate")
  # Base metals (iron, steel, copper, aluminum, etc.)
  if (hs2_num %in% 72:81) {
    # Metal tools and household articles → final
    if (hs2_num %in% c(82, 83)) return("final")
    return("intermediate")
  }

  # --- CLEARLY FINAL CONSUMPTION ---
  # Food, beverages, tobacco (HS 01-24)
  if (hs2_num %in% 1:24) {
    # Raw agricultural inputs for industry
    if (hs4_num %in% c(
      1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, # cereals
      1201, 1202, 1203, 1204, 1205, 1206, 1207, # oilseeds
      1501, 1502, 1503, 1504, 1505, 1506, 1507, 1508, 1509, 1510, # fats
      1701, # raw sugar
      2301, 2302, 2303, 2304, 2305, 2306, 2308, 2309 # animal feed / residues
    )) return("intermediate")
    return("final")
  }
  # Made-up textiles, apparel, footwear, headwear
  if (hs2_num %in% 56:67) return("final")
  # Precious metals, jewelry
  if (hs2_num == 71) return("final")
  # Tools, cutlery, household metal articles
  if (hs2_num %in% c(82, 83)) return("final")
  # Arms
  if (hs2_num == 93) return("final")
  # Furniture, toys, sports, misc manufactured
  if (hs2_num %in% 94:96) return("final")
  # Art, antiques
  if (hs2_num == 97) return("final")
  # Watches, musical instruments
  if (hs2_num %in% c(91, 92)) return("final")

  # --- MIXED CHAPTERS: HS4-level refinement ---

  # HS 84: Machinery — split into capital/parts/consumer
  if (hs2_num == 84) {
    # Consumer appliances
    if (hs4_num %in% c(
      8415, # air conditioning
      8418, # refrigerators
      8422, # dishwashers (part)
      8450, # washing machines
      8451, # dry-cleaning machines (household)
      8467, # hand tools
      8469, # typewriters (obsolete but classified)
      8470, # calculators
      8471, # computers (consumer)
      8473  # computer parts (consumer)
    )) return("final")
    # Parts and accessories
    if (hs4_num %in% c(8409, 8413, 8414, 8481, 8482, 8483, 8484, 8485, 8486, 8487)) {
      return("intermediate") # parts = intermediate inputs
    }
    # Default for HS 84: capital goods
    return("capital")
  }

  # HS 85: Electrical machinery — split
  if (hs2_num == 85) {
    # Consumer electronics
    if (hs4_num %in% c(
      8516, # electric heaters, ovens, hair dryers
      8517, # telephones, smartphones
      8518, # microphones, speakers
      8519, # sound recording/reproducing
      8521, # video recording
      8523, # recorded media
      8527, # radio receivers
      8528  # TVs, monitors
    )) return("final")
    # Electronic components / parts = intermediate
    if (hs4_num %in% c(8532, 8533, 8534, 8535, 8536, 8537, 8538, 8539,
                        8540, 8541, 8542, 8543, 8544, 8545, 8546, 8547, 8548)) {
      return("intermediate")
    }
    # Default for HS 85: capital goods (motors, generators, transformers)
    return("capital")
  }

  # HS 86: Railway equipment → capital
  if (hs2_num == 86) return("capital")

  # HS 87: Vehicles — split
  if (hs2_num == 87) {
    # Consumer vehicles
    if (hs4_num %in% c(
      8703, # passenger cars
      8711, # motorcycles
      8712, # bicycles
      8713, # invalid carriages
      8714, # bicycle/motorcycle parts (consumer)
      8715, # baby carriages
      8716  # trailers (consumer)
    )) return("final")
    # Vehicle parts = intermediate
    if (hs4_num == 8708) return("intermediate")
    # Trucks, buses, special vehicles → capital
    return("capital")
  }

  # HS 88: Aircraft → capital
  if (hs2_num == 88) return("capital")

  # HS 89: Ships → capital
  if (hs2_num == 89) return("capital")

  # HS 90: Instruments — mostly capital, some consumer
  if (hs2_num == 90) {
    if (hs4_num %in% c(9003, 9004)) return("final") # spectacles
    return("capital")
  }

  # Default fallback
  return("intermediate")
}

# Apply classification
cat("Classifying products by BEC category...\n")
panel[, bec_category := mapply(classify_bec, hs2, hs4)]
panel[, bec_category := factor(bec_category,
  levels = c("intermediate", "capital", "fuels", "final")
)]

cat("BEC classification distribution:\n")
print(panel[, .(.N, total_value = sum(import_value, na.rm = TRUE) / 1e9),
  by = bec_category][order(-N)])

# ============================================================
# PART 3: Create analysis variables
# ============================================================

# Treatment indicators
panel[, post := as.integer(year >= 2017)] # devaluation Nov 2016, full year effect from 2017
panel[, is_intermediate := as.integer(bec_category == "intermediate")]
panel[, is_capital := as.integer(bec_category == "capital")]
panel[, is_final := as.integer(bec_category == "final")]
panel[, is_fuels := as.integer(bec_category == "fuels")]

# Log transform (add 1 for products with very small values)
panel[, log_imports := log(import_value)]
panel[, log_imports_p1 := log(import_value + 1)]

# Asinh transform (handles zeros better)
panel[, asinh_imports := asinh(import_value)]

# Create 3-way classification (combine fuels with intermediate for main spec)
panel[, bec3 := fifelse(bec_category == "fuels", "intermediate", as.character(bec_category))]
panel[, bec3 := factor(bec3, levels = c("intermediate", "capital", "final"))]

# Create product identifier for panel FE
panel[, product_id := as.integer(factor(hs6))]

# Pre-devaluation import share (for continuous treatment)
pre_mean <- panel[year %in% 2013:2015, .(pre_import = mean(import_value, na.rm = TRUE)), by = hs6]
panel <- merge(panel, pre_mean, by = "hs6", all.x = TRUE)
panel[, log_pre_import := log(pre_import + 1)]

# ============================================================
# PART 4: Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# By BEC category
summ_bec <- panel[, .(
  n_products = uniqueN(hs6),
  n_obs = .N,
  mean_import = mean(import_value, na.rm = TRUE),
  median_import = median(import_value, na.rm = TRUE),
  total_import_bn = sum(import_value, na.rm = TRUE) / 1e9
), by = .(bec3, post)]
setorder(summ_bec, bec3, post)
cat("\nBy BEC category and period:\n")
print(summ_bec)

# Overall panel dimensions
cat(sprintf("\nFinal panel: %d obs, %d products, %d years\n",
  nrow(panel), uniqueN(panel$hs6), uniqueN(panel$year)))
cat(sprintf("  Intermediate: %d products\n", panel[bec3 == "intermediate", uniqueN(hs6)]))
cat(sprintf("  Capital: %d products\n", panel[bec3 == "capital", uniqueN(hs6)]))
cat(sprintf("  Final: %d products\n", panel[bec3 == "final", uniqueN(hs6)]))

# ============================================================
# PART 5: Aggregate trends for plotting
# ============================================================

# Annual aggregates by BEC
agg_annual <- panel[, .(
  total_imports = sum(import_value, na.rm = TRUE),
  n_products = uniqueN(hs6),
  mean_imports = mean(import_value, na.rm = TRUE)
), by = .(year, bec3)]

# Index to 2015 = 100
base_2015 <- agg_annual[year == 2015, .(bec3, base = total_imports)]
agg_annual <- merge(agg_annual, base_2015, by = "bec3")
agg_annual[, index_100 := total_imports / base * 100]

fwrite(agg_annual, file.path(DATA_DIR, "agg_annual_bec.csv"))

# ============================================================
# PART 6: Save analysis-ready panel
# ============================================================
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

# Save summary stats for tables
fwrite(summ_bec, file.path(DATA_DIR, "summary_stats_bec.csv"))

# ============================================================
# PART 7: Process monthly data
# ============================================================
if (file.exists(file.path(DATA_DIR, "comtrade_egy_monthly_hs2_panel.csv"))) {
  cat("\nProcessing monthly data...\n")
  monthly <- fread(file.path(DATA_DIR, "comtrade_egy_monthly_hs2_panel.csv"))

  monthly[, hs2 := as.character(cmdCode)]
  monthly[, import_value := fifelse(!is.na(primaryValue) & primaryValue > 0,
    primaryValue,
    fifelse(!is.na(cifvalue) & cifvalue > 0, cifvalue, NA_real_)
  )]
  monthly <- monthly[!is.na(import_value) & import_value > 0]

  # Classify HS2 chapters into BEC (simpler, chapter-level)
  monthly[, bec3 := fcase(
    as.integer(hs2) %in% c(25:38, 39:40, 41:49, 50:55, 68:70, 72:81), "intermediate",
    as.integer(hs2) %in% c(84:86, 88:90), "capital",
    as.integer(hs2) == 27, "intermediate", # fuels → intermediate for 3-way
    default = "final"
  )]
  monthly[, bec3 := factor(bec3, levels = c("intermediate", "capital", "final"))]

  # Create time variable
  monthly[, year := as.integer(refYear)]
  monthly[, month := as.integer(refMonth)]
  monthly[, ym := year * 100 + month]
  monthly[, months_from_deval := (year - 2016) * 12 + (month - 11)]

  # Aggregate by BEC × month
  monthly_agg <- monthly[, .(
    total_imports = sum(import_value, na.rm = TRUE)
  ), by = .(ym, year, month, bec3, months_from_deval)]

  # Index to Oct 2016 = 100
  base_oct16 <- monthly_agg[ym == 201610, .(bec3, base = total_imports)]
  monthly_agg <- merge(monthly_agg, base_oct16, by = "bec3", all.x = TRUE)
  monthly_agg[, index_100 := total_imports / base * 100]

  fwrite(monthly_agg, file.path(DATA_DIR, "monthly_agg_bec.csv"))
  cat(sprintf("Monthly data processed: %d rows\n", nrow(monthly_agg)))
}

# ============================================================
# PART 8: Process bilateral data
# ============================================================
bilateral_files <- list.files(DATA_DIR, pattern = "comtrade_egy_bilateral_hs2_", full.names = TRUE)
if (length(bilateral_files) > 0) {
  cat("\nProcessing bilateral data...\n")
  bilateral <- rbindlist(lapply(bilateral_files, fread), fill = TRUE)

  bilateral[, import_value := fifelse(!is.na(primaryValue) & primaryValue > 0,
    primaryValue,
    fifelse(!is.na(cifvalue) & cifvalue > 0, cifvalue, NA_real_)
  )]
  bilateral <- bilateral[!is.na(import_value) & import_value > 0]
  bilateral[, year := as.integer(refYear)]
  bilateral[, hs2 := as.character(cmdCode)]

  # Classify partner currency zone
  # Dollar-zone: USA (842), Canada (124), Saudi Arabia (682), UAE (784)
  # Euro-zone: Germany (276), France (251), Italy (380), Spain (724), Netherlands (528)
  # Yuan-zone: China (156)
  bilateral[, currency_zone := fcase(
    partnerCode %in% c(842, 124, 682, 784, 414, 634), "dollar",
    partnerCode %in% c(276, 251, 380, 724, 528, 56, 40, 300, 620, 246), "euro",
    partnerCode == 156, "yuan",
    default = "other"
  )]

  bilateral_agg <- bilateral[, .(
    total_imports = sum(import_value, na.rm = TRUE)
  ), by = .(year, currency_zone)]

  base_2015_b <- bilateral_agg[year == 2015, .(currency_zone, base = total_imports)]
  bilateral_agg <- merge(bilateral_agg, base_2015_b, by = "currency_zone", all.x = TRUE)
  bilateral_agg[, index_100 := total_imports / base * 100]

  fwrite(bilateral_agg, file.path(DATA_DIR, "bilateral_agg_currency.csv"))
  cat(sprintf("Bilateral data processed: %d rows\n", nrow(bilateral_agg)))
}

cat("\n=== Data cleaning complete ===\n")
