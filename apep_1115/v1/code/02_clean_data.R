# ==============================================================================
# 02_clean_data.R — Construct analysis panel
# ==============================================================================

source("00_packages.R")

# --- Load data ---
sc <- readRDS("../data/sc_activation_dates.rds")
qwi_raw <- readRDS("../data/qwi_raw.rds")
qwi_totals <- readRDS("../data/qwi_totals.rds")

cat("SC activation dates:", nrow(sc), "counties\n")
cat("QWI raw:", nrow(qwi_raw), "rows\n")
cat("QWI totals:", nrow(qwi_totals), "rows\n")

# --- Convert to data.table for speed ---
setDT(qwi_raw)
setDT(qwi_totals)
setDT(sc)

# --- Create time variable (numeric quarter) ---
qwi_raw[, time_q := year * 4 + quarter]
qwi_totals[, time_q := year * 4 + quarter]

# Pad county_fips to 5 digits
qwi_raw[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi_totals[, county_fips := sprintf("%05d", as.integer(county_fips))]
sc[, county_fips := sprintf("%05d", as.integer(county_fips))]

# --- Classify industries ---
# Enforcement-visible: Construction (236, 237, 238), Manufacturing (311-339)
# Enforcement-opaque: Food services (722), Social assistance (624), Healthcare (621, 622, 623)

visible_industries <- c("236", "237", "238",
                         paste0(rep(31:33, each = 10), 0:9))
# Filter to valid 3-digit NAICS
visible_industries <- intersect(visible_industries,
                                unique(qwi_raw$industry))

opaque_industries <- c("621", "622", "623", "624", "722")

cat("Visible industries found:", length(visible_industries), "\n")
cat("Opaque industries found:",
    length(intersect(opaque_industries, unique(qwi_raw$industry))), "\n")

# Tag industries
qwi_raw[, sector := fcase(
  industry %in% c("236", "237", "238"), "construction",
  industry %chin% as.character(311:339), "manufacturing",
  industry %in% c("621", "622", "623"), "healthcare",
  industry == "624", "social_assistance",
  industry == "722", "food_services",
  default = "other"
)]

# Broader category
qwi_raw[, sector_type := fcase(
  sector %in% c("construction", "manufacturing"), "visible",
  sector %in% c("healthcare", "social_assistance", "food_services"), "opaque",
  default = "other"
)]

cat("\nSector distribution:\n")
print(qwi_raw[, .N, by = sector][order(-N)])

# --- Aggregate to county × quarter × ethnicity × sector_type ---
panel_sector <- qwi_raw[sector_type %in% c("visible", "opaque"),
  .(emp = sum(Emp, na.rm = TRUE),
    hires = sum(HirA, na.rm = TRUE),
    seps = sum(Sep, na.rm = TRUE),
    earn_weighted = sum(EarnS * Emp, na.rm = TRUE) / sum(Emp[!is.na(EarnS)], na.rm = TRUE)),
  by = .(county_fips, year, quarter, time_q, ethnicity, sector_type)
]

# --- Merge with total employment ---
panel_sector <- merge(panel_sector, qwi_totals,
                      by = c("county_fips", "year", "quarter", "ethnicity"),
                      all.x = TRUE, suffixes = c("", "_total"))

# Compute employment share
panel_sector[, emp_share := emp / total_emp]

# --- Merge SC activation dates ---
panel_sector <- merge(panel_sector, sc[, .(county_fips, activation_date, activation_quarter)],
                      by = "county_fips", all.x = TRUE)

# Compute activation time_q
panel_sector[, activation_year := as.integer(substr(activation_quarter, 1, 4))]
panel_sector[, activation_q := as.integer(substr(activation_quarter, 6, 6))]
panel_sector[, activation_time_q := activation_year * 4 + activation_q]

# Counties without SC activation = never-treated (treated = 0 in did package)
panel_sector[is.na(activation_time_q), activation_time_q := 0]

# Event time
panel_sector[activation_time_q > 0, event_time := time_q - activation_time_q]

cat("\nPanel dimensions:\n")
cat("  Rows:", nrow(panel_sector), "\n")
cat("  Counties:", uniqueN(panel_sector$county_fips), "\n")
cat("  Time periods:", uniqueN(panel_sector$time_q), "\n")
cat("  Treated counties:", uniqueN(panel_sector[activation_time_q > 0]$county_fips), "\n")
cat("  Never-treated counties:", uniqueN(panel_sector[activation_time_q == 0]$county_fips), "\n")

# --- Create the wide panel for DiD (one row per county × quarter × ethnicity) ---
panel_wide <- dcast(panel_sector,
                    county_fips + year + quarter + time_q + ethnicity +
                      total_emp + activation_time_q ~ sector_type,
                    value.var = c("emp", "emp_share", "earn_weighted"),
                    fill = 0)

cat("\nWide panel:", nrow(panel_wide), "rows\n")

# --- Filter to counties with sufficient data ---
# Need at least 4 pre-treatment quarters and nonzero Hispanic employment
county_coverage <- panel_wide[ethnicity == "A2",
  .(n_quarters = .N,
    mean_total_emp = mean(total_emp, na.rm = TRUE),
    has_visible = any(emp_visible > 0),
    has_opaque = any(emp_opaque > 0)),
  by = county_fips
]

# Keep counties with at least 20 quarters of data and mean Hispanic emp > 50
good_counties <- county_coverage[n_quarters >= 20 & mean_total_emp >= 50]$county_fips
cat("Counties meeting quality filter:", length(good_counties),
    "of", uniqueN(panel_wide$county_fips), "\n")

panel_final <- panel_wide[county_fips %in% good_counties]
cat("Final panel:", nrow(panel_final), "rows\n")
cat("  Counties:", uniqueN(panel_final$county_fips), "\n")

# Extract state FIPS for clustering
panel_final[, state_fips := substr(county_fips, 1, 2)]

# --- Save ---
saveRDS(panel_final, "../data/panel_final.rds")
saveRDS(panel_sector, "../data/panel_sector.rds")

cat("\nPanel construction complete.\n")
