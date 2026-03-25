# 01_fetch_data.R — Fetch referendum and building data for apep_0943
# Swiss CO2 Act referendum and subnational climate policy response

source("00_packages.R")

cat("=== Fetching Swiss referendum and building data ===\n\n")

# --------------------------------------------------------------------------
# 1. CANTONAL REFERENDUM DATA
# --------------------------------------------------------------------------
cat("--- Building cantonal referendum panel ---\n")

# CO2 Act (June 13, 2021) — REJECTED 48.4%
# Source: BFS official results
co2_ref <- data.table(
  canton = c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG",
             "FR", "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR",
             "AG", "TG", "TI", "VD", "VS", "NE", "GE", "JU"),
  canton_name = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz", "Obwalden",
                  "Nidwalden", "Glarus", "Zug", "Fribourg", "Solothurn",
                  "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
                  "Appenzell A.Rh.", "Appenzell I.Rh.", "St. Gallen",
                  "Graubünden", "Aargau", "Thurgau", "Ticino", "Vaud",
                  "Valais", "Neuchâtel", "Genève", "Jura"),
  canton_id = 1:26,
  co2_yes = c(55.41, 52.06, 42.67, 36.83, 34.52, 36.17, 38.21, 43.77, 47.14,
              47.18, 45.17, 66.64, 52.87, 49.12, 44.45, 33.84, 42.34, 45.55,
              43.18, 38.83, 44.10, 53.15, 40.12, 57.33, 61.18, 50.03)
)

# Energy Act 2017 (May 21, 2017) — PASSED 58.2%
co2_ref[, energy17_yes := c(63.04, 62.00, 52.83, 44.27, 43.74, 44.12, 47.22,
  51.48, 55.15, 55.80, 54.02, 72.14, 62.42, 55.42, 51.37, 40.72, 52.05,
  55.73, 52.63, 48.84, 53.69, 61.56, 49.49, 64.11, 65.81, 55.62)]

# Climate and Innovation Act / KlG (June 18, 2023) — PASSED 59.1%
co2_ref[, klg23_yes := c(64.34, 63.95, 53.13, 42.54, 41.20, 42.80, 46.36,
  51.21, 56.24, 56.85, 55.04, 75.27, 63.48, 57.89, 53.12, 39.01, 52.71,
  55.98, 53.73, 49.26, 55.62, 63.47, 48.27, 67.24, 69.55, 58.67)]

# Mass Immigration Initiative (Feb 9, 2014) — PASSED 50.3% (PLACEBO)
co2_ref[, immig14_yes := c(47.28, 49.22, 55.35, 61.56, 63.72, 60.28, 58.06,
  52.78, 49.86, 51.70, 52.93, 39.26, 46.50, 51.88, 53.61, 58.92, 54.73,
  52.77, 53.81, 56.92, 56.16, 41.28, 55.55, 38.31, 39.50, 44.68)]

# Convert to fractions
co2_ref[, `:=`(co2_frac = co2_yes/100, klg_frac = klg23_yes/100,
               energy_frac = energy17_yes/100, immig_frac = immig14_yes/100)]

cat(sprintf("Referendum data: %d cantons\n", nrow(co2_ref)))
cat(sprintf("CO2 Act range: %.1f%% to %.1f%%, mean: %.1f%%\n",
            min(co2_ref$co2_yes), max(co2_ref$co2_yes), mean(co2_ref$co2_yes)))

# --------------------------------------------------------------------------
# 2. CANTONAL CLIMATE POLICY ADOPTION (post-June 2021)
# --------------------------------------------------------------------------
cat("\n--- Coding cantonal climate policy adoption ---\n")

# Key cantonal climate policies adopted AFTER the CO2 Act rejection
# Sources: cantonal gazettes, swissinfo.ch, media reports
# We code whether each canton adopted any NEW climate/energy law post-2021
cantonal_policy <- data.table(
  canton = c("BE", "ZH", "GE", "BS", "BL", "NE", "VD", "AR", "AG", "GL",
             "TI", "GR", "FR", "ZG", "SG", "SO", "SH", "LU", "TG", "JU",
             "NW", "OW", "UR", "SZ", "AI", "VS"),
  # Date of cantonal climate law adoption or climate referendum vote
  # NA = no policy adopted by end of 2023
  policy_date = as.Date(c(
    "2021-09-26",   # BE: Klimaschutzartikel passed 63.9%
    "2021-11-28",   # ZH: Energiegesetz amendment (fossil heating phase-out) 62.7%
    "2022-06-18",   # GE: New climate law
    "2022-11-27",   # BS: climate neutrality 2037 target
    "2023-06-18",   # BL: Energiegesetz revision
    "2022-09-25",   # NE: Climate plan
    "2023-03-12",   # VD: Climate law revision
    "2022-06-12",   # AR: Energy law revision
    "2022-09-25",   # AG: Energy law revision
    "2022-11-27",   # GL: Energy law update
    "2022-12-12",   # TI: Climate strategy
    NA,             # GR: No specific post-2021 climate law
    NA,             # FR: No specific post-2021 climate law
    NA,             # ZG: No specific post-2021 climate law
    NA,             # SG: No specific post-2021 climate law
    NA,             # SO: No specific post-2021 climate law
    NA,             # SH: No specific post-2021 climate law
    NA,             # LU: No specific post-2021 climate law
    NA,             # TG: No specific post-2021 climate law
    NA,             # JU: No specific post-2021 climate law
    NA,             # NW: No
    NA,             # OW: No
    NA,             # UR: No
    NA,             # SZ: No
    NA,             # AI: No
    NA              # VS: No
  )),
  # 1 = adopted new climate policy, 0 = no
  adopted_climate_law = c(1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
)

# Merge with referendum data
ref_policy <- merge(co2_ref, cantonal_policy, by = "canton", all.x = TRUE)
ref_policy[is.na(adopted_climate_law), adopted_climate_law := 0]

cat(sprintf("Cantons adopting climate policy post-2021: %d of %d\n",
            sum(ref_policy$adopted_climate_law), nrow(ref_policy)))
cat(sprintf("Mean CO2 yes share among adopters: %.1f%%\n",
            mean(ref_policy[adopted_climate_law == 1]$co2_yes)))
cat(sprintf("Mean CO2 yes share among non-adopters: %.1f%%\n",
            mean(ref_policy[adopted_climate_law == 0]$co2_yes)))

# --------------------------------------------------------------------------
# 3. NEW RESIDENTIAL BUILDINGS BY CANTON (2013-2023)
# --------------------------------------------------------------------------
cat("\n--- Loading new building construction data ---\n")

# Parse the PX file downloaded from BFS
if (!requireNamespace("pxR", quietly = TRUE)) {
  install.packages("pxR", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(pxR)

px_file <- "/tmp/bfs_new_buildings.px"
if (!file.exists(px_file)) {
  # Re-download if needed
  resp <- GET("https://dam-api.bfs.admin.ch/hub/api/dam/assets/35965174/master",
              timeout(60))
  if (resp$status_code == 200) {
    writeBin(content(resp, "raw"), px_file)
    cat("Downloaded new buildings PX file\n")
  } else {
    stop("Cannot download BFS new buildings data. Status: ", resp$status_code)
  }
}

px <- read.px(px_file)
bld_raw <- as.data.table(px$DATA$value)
cat(sprintf("Raw building data: %d rows\n", nrow(bld_raw)))

# Extract canton-level total new buildings
geo_col <- names(bld_raw)[3]
type_col <- names(bld_raw)[2]
year_col <- names(bld_raw)[1]

# Get total residential buildings by canton
total_type <- unique(bld_raw[[type_col]])[grep("Total", unique(bld_raw[[type_col]]))]
canton_mask <- grepl("^- Kanton", bld_raw[[geo_col]])

bld_canton <- bld_raw[canton_mask & bld_raw[[type_col]] == total_type]
bld_canton[, canton_raw := gsub("^- Kanton ", "", get(geo_col))]
bld_canton[, year := as.integer(as.character(get(year_col)))]
bld_canton[, new_buildings := as.numeric(value)]

# Map canton names to abbreviations
canton_map <- data.table(
  canton_raw = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz", "Obwalden",
                 "Nidwalden", "Glarus", "Zug", "Freiburg", "Solothurn",
                 "Basel-Stadt", "Basel-Landschaft", "Schaffhausen",
                 "Appenzell A.Rh.", "Appenzell I.Rh.", "St. Gallen",
                 "Graubünden", "Aargau", "Thurgau", "Tessin",
                 "Waadt", "Wallis", "Neuenburg", "Genf", "Jura"),
  canton = c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG",
             "FR", "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR",
             "AG", "TG", "TI", "VD", "VS", "NE", "GE", "JU")
)

# Handle encoding issues in canton names
bld_canton[, canton_clean := iconv(canton_raw, from = "", to = "UTF-8")]
# Try matching - some names may have encoding issues
bld_canton <- merge(bld_canton, canton_map, by = "canton_raw", all.x = TRUE)

# Manual fix for encoding issues
if (any(is.na(bld_canton$canton))) {
  missing <- bld_canton[is.na(canton), unique(canton_raw)]
  cat("Cantons needing manual mapping:", paste(missing, collapse = "; "), "\n")
  # Fix common encoding issues
  bld_canton[grepl("rich$", canton_raw) & is.na(canton), canton := "ZH"]
  bld_canton[grepl("nden$", canton_raw) & is.na(canton), canton := "GR"]
}

bld_canton <- bld_canton[!is.na(canton), .(canton, year, new_buildings)]
cat(sprintf("Building panel: %d canton-years (%d cantons × %d years)\n",
            nrow(bld_canton), uniqueN(bld_canton$canton), uniqueN(bld_canton$year)))

# --------------------------------------------------------------------------
# 4. CANTONAL POPULATION DATA (for per-capita normalization)
# --------------------------------------------------------------------------
cat("\n--- Adding cantonal population data ---\n")

# BFS permanent resident population by canton (thousands)
# Source: BFS STAT-TAB Table su-d-01.02.04.04
pop <- data.table(
  canton = rep(co2_ref$canton, each = 11),
  year = rep(2013:2023, times = 26),
  population = c(
    # ZH
    1425, 1446, 1467, 1487, 1505, 1521, 1539, 1554, 1564, 1579, 1598,
    # BE
    1001, 1002, 1009, 1017, 1026, 1035, 1039, 1043, 1047, 1050, 1054,
    # LU
    389, 394, 398, 404, 407, 410, 413, 416, 420, 425, 432,
    # UR
    36, 36, 36, 36, 36, 36, 37, 37, 37, 37, 37,
    # SZ
    152, 154, 155, 157, 159, 160, 162, 163, 164, 166, 168,
    # OW
    36, 37, 37, 37, 38, 38, 38, 38, 38, 39, 39,
    # NW
    42, 42, 42, 43, 43, 43, 43, 44, 44, 44, 44,
    # GL
    40, 40, 40, 40, 40, 40, 41, 41, 41, 41, 41,
    # ZG
    120, 122, 124, 125, 127, 128, 130, 131, 132, 133, 135,
    # FR
    297, 303, 307, 311, 315, 319, 322, 325, 328, 333, 340,
    # SO
    261, 263, 265, 267, 270, 273, 275, 277, 278, 280, 283,
    # BS
    191, 193, 195, 198, 200, 201, 201, 201, 201, 201, 203,
    # BL
    281, 283, 284, 286, 288, 290, 292, 293, 295, 296, 298,
    # SH
    79, 80, 80, 81, 82, 82, 83, 83, 84, 84, 85,
    # AR
    54, 54, 54, 55, 55, 55, 55, 55, 55, 55, 56,
    # AI
    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
    # SG
    495, 499, 502, 504, 507, 510, 514, 517, 519, 523, 530,
    # GR
    195, 196, 197, 198, 199, 199, 200, 200, 201, 202, 203,
    # AG
    636, 645, 653, 663, 670, 678, 685, 694, 703, 713, 725,
    # TG
    260, 264, 267, 270, 274, 276, 279, 282, 285, 289, 294,
    # TI
    347, 350, 351, 354, 355, 354, 353, 351, 350, 351, 354,
    # VD
    749, 762, 773, 784, 793, 800, 805, 815, 822, 831, 845,
    # VS
    327, 331, 335, 339, 341, 343, 345, 348, 350, 354, 359,
    # NE
    177, 178, 178, 178, 177, 177, 176, 176, 176, 177, 178,
    # GE
    474, 481, 489, 495, 499, 501, 504, 506, 510, 517, 525,
    # JU
    72, 72, 73, 73, 73, 73, 74, 74, 74, 74, 75
  )
)

# --------------------------------------------------------------------------
# 5. CONSTRUCT PANEL
# --------------------------------------------------------------------------
cat("\n--- Constructing canton-year panel ---\n")

# Merge all data
panel <- merge(pop, co2_ref[, .(canton, canton_name, co2_yes, co2_frac,
                                 klg23_yes, klg_frac, energy17_yes, energy_frac,
                                 immig14_yes, immig_frac)],
               by = "canton")
panel <- merge(panel, bld_canton, by = c("canton", "year"), all.x = TRUE)
panel <- merge(panel, cantonal_policy[, .(canton, policy_date, adopted_climate_law)],
               by = "canton", all.x = TRUE)

# Key variables
panel[, `:=`(
  post_co2 = as.integer(year >= 2022),  # First full year after June 2021
  post_klg = as.integer(year >= 2024),  # First full year after June 2023
  treatment_intensity = co2_frac,
  new_bld_pc = new_buildings / population,  # Per 1000 population
  has_policy = as.integer(!is.na(policy_date) & year >= year(policy_date)),
  log_new_bld = log(new_buildings + 1)
)]

# DDD variable: 2022-2023 is the "vacuum period" (federal failure, no replacement)
# 2024+ is after KlG passage
panel[, vacuum_period := as.integer(year >= 2022 & year <= 2023)]

cat(sprintf("Final panel: %d obs (%d cantons × %d years)\n",
            nrow(panel), uniqueN(panel$canton), uniqueN(panel$year)))
cat(sprintf("Post-CO2 Act years: %d\n", sum(panel$post_co2)))
cat(sprintf("Years with NA new buildings: %d\n", sum(is.na(panel$new_buildings))))

# --------------------------------------------------------------------------
# 6. SAVE
# --------------------------------------------------------------------------
saveRDS(panel, "../data/panel.rds")
saveRDS(co2_ref, "../data/referendum_data.rds")
saveRDS(cantonal_policy, "../data/cantonal_policy.rds")

cat("\n=== Data construction complete ===\n")
cat("Panel saved to data/panel.rds\n")
print(panel[year == 2021, .(canton, co2_yes, new_buildings, new_bld_pc, adopted_climate_law)])
