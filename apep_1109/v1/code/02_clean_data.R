## 02_clean_data.R — Clean and merge all data sources into analysis panel
## apep_1109: Crop Insurance and Deaths of Despair

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

cat("=== 1. Clean NCHS Overdose Data ===\n")

nchs <- fread(file.path(data_dir, "nchs_overdose_raw.csv"))

# Standardize column names
setnames(nchs, tolower(names(nchs)))
cat(sprintf("  Columns: %s\n", paste(names(nchs), collapse = ", ")))
cat(sprintf("  Rows: %d, Years: %d-%d, Counties: %d\n",
            nrow(nchs), min(nchs$year), max(nchs$year), n_distinct(nchs$fips)))

# Create clean FIPS (5-digit, zero-padded)
nchs[, fips5 := sprintf("%05d", as.integer(fips))]

# Key variables
nchs[, `:=`(
  od_rate = as.numeric(model_based_death_rate),
  od_sd = as.numeric(standard_deviation),
  pop = as.numeric(population),
  urban_rural = urbanrural
)]

# Drop if missing key vars
nchs_clean <- nchs[!is.na(od_rate) & !is.na(pop) & pop > 0,
                    .(fips5, year, od_rate, od_sd, pop, urban_rural)]

cat(sprintf("  After cleaning: %d rows, %d counties\n",
            nrow(nchs_clean), n_distinct(nchs_clean$fips5)))

# Classify urban/rural
nchs_clean[, rural := as.integer(urban_rural %in% c("Noncore", "Micropolitan",
                                                      "Small Metro"))]

cat("\n=== 2. Clean RMA Crop Insurance Data ===\n")

rma <- fread(file.path(data_dir, "rma_county_year.csv"))
cat(sprintf("  RMA rows: %d\n", nrow(rma)))

# Ensure FIPS is 5-digit
rma[, fips5 := sprintf("%05d", as.integer(gsub("^0+", "", fips)))]
# Some records may have state-level (county=000) — drop those
rma <- rma[as.integer(county_fips) > 0]

# Aggregate to county-year (some duplicates from state_fips handling)
rma_clean <- rma[, .(
  indemnity = sum(indemnity, na.rm = TRUE),
  premium = sum(premium, na.rm = TRUE),
  subsidy = sum(subsidy, na.rm = TRUE),
  liability = sum(liability, na.rm = TRUE),
  policies = sum(policies, na.rm = TRUE),
  net_acres = sum(net_acres, na.rm = TRUE)
), by = .(fips5, year)]

cat(sprintf("  After cleaning: %d county-years, %d counties, %d years\n",
            nrow(rma_clean), n_distinct(rma_clean$fips5), n_distinct(rma_clean$year)))

# Flag agricultural counties: counties that appear in RMA data in >=10 years
ag_counties <- rma_clean[, .N, by = fips5][N >= 10, fips5]
cat(sprintf("  Agricultural counties (>=10 years in RMA): %d\n", length(ag_counties)))

cat("\n=== 3. Parse NOAA PDSI Data ===\n")

# PDSI format: fixed-width, each row = one climate division + year
# Column 1: 6-digit code (2-digit state FIPS + 2-digit division + 2-digit element_code=02)
# Followed by 12 monthly values
pdsi_lines <- readLines(file.path(data_dir, "pdsi_raw.txt"))
cat(sprintf("  PDSI lines: %d\n", length(pdsi_lines)))

# Parse fixed-width format
parse_pdsi <- function(lines) {
  # Each line: positions 1-6 = state_div_element, 7-10 = year, then 12 values of 7 chars each
  dt_list <- lapply(lines, function(l) {
    if (nchar(l) < 17) return(NULL)
    state_code <- substr(l, 1, 2)
    div_code <- substr(l, 3, 4)
    elem <- substr(l, 5, 6)
    yr <- as.integer(substr(l, 7, 10))

    # 12 monthly values, each 7 characters starting at position 11
    vals <- numeric(12)
    for (m in 1:12) {
      start <- 11 + (m - 1) * 7
      end <- start + 6
      v <- as.numeric(trimws(substr(l, start, end)))
      vals[m] <- ifelse(is.na(v) || v < -99, NA_real_, v)
    }

    data.table(
      state_fips = state_code,
      division = div_code,
      year = yr,
      pdsi_jan = vals[1], pdsi_feb = vals[2], pdsi_mar = vals[3],
      pdsi_apr = vals[4], pdsi_may = vals[5], pdsi_jun = vals[6],
      pdsi_jul = vals[7], pdsi_aug = vals[8], pdsi_sep = vals[9],
      pdsi_oct = vals[10], pdsi_nov = vals[11], pdsi_dec = vals[12]
    )
  })

  rbindlist(dt_list[!sapply(dt_list, is.null)])
}

pdsi <- parse_pdsi(pdsi_lines)
cat(sprintf("  Parsed: %d rows\n", nrow(pdsi)))

# Filter to 2003-2021
pdsi <- pdsi[year >= 2003 & year <= 2021]

# Growing season PDSI: April-September average
pdsi[, pdsi_growing := rowMeans(.SD, na.rm = TRUE),
     .SDcols = c("pdsi_apr", "pdsi_may", "pdsi_jun",
                  "pdsi_jul", "pdsi_aug", "pdsi_sep")]

# Create climate division ID (state_fips + division)
pdsi[, climdiv := paste0(state_fips, division)]

pdsi_clean <- pdsi[, .(climdiv, state_fips, division, year, pdsi_growing)]
cat(sprintf("  Climate divisions: %d, years: %d-%d\n",
            n_distinct(pdsi_clean$climdiv), min(pdsi_clean$year), max(pdsi_clean$year)))

cat("\n=== 4. Build Climate Division to County Crosswalk ===\n")

# Parse the NOAA county-to-climate-division file (space-delimited)
xwalk_lines <- readLines(file.path(data_dir, "county_climdiv_xwalk.txt"))
# Skip header lines (first 4 lines: 2 description + 1 blank + 1 column header)
xwalk_lines <- xwalk_lines[-(1:4)]
xwalk_lines <- xwalk_lines[nchar(trimws(xwalk_lines)) > 0]

xwalk <- data.table(do.call(rbind, strsplit(trimws(xwalk_lines), "\\s+")))
setnames(xwalk, c("fips5", "ncdc_fips", "climdiv"))
xwalk <- xwalk[nchar(fips5) == 5 & nchar(climdiv) >= 3, .(fips5, climdiv)]
cat(sprintf("  Crosswalk: %d counties mapped to %d divisions\n",
            nrow(xwalk), n_distinct(xwalk$climdiv)))

# Add state FIPS to NCHS data
nchs_clean[, state_fips := substr(fips5, 1, 2)]

# Merge county-to-division crosswalk, then join division-level PDSI
nchs_clean <- merge(nchs_clean, xwalk, by = "fips5", all.x = TRUE)
cat(sprintf("  Counties with division mapping: %d of %d\n",
            sum(!is.na(nchs_clean$climdiv)), n_distinct(nchs_clean$fips5)))

# Also prepare state-level PDSI as fallback
state_pdsi <- pdsi_clean[, .(
  pdsi_state = mean(pdsi_growing, na.rm = TRUE)
), by = .(state_fips, year)]

cat("\n=== 5. Merge into Analysis Panel ===\n")

# Start with NCHS
panel <- copy(nchs_clean)

# Merge division-level PDSI
panel <- merge(panel, pdsi_clean[, .(climdiv, year, pdsi_growing)],
               by = c("climdiv", "year"), all.x = TRUE)

# Merge state-level PDSI as fallback
panel <- merge(panel, state_pdsi, by = c("state_fips", "year"), all.x = TRUE)
panel[is.na(pdsi_growing), pdsi_growing := pdsi_state]

cat(sprintf("  Counties with division-level PDSI: %d\n",
            n_distinct(panel[!is.na(pdsi_growing), fips5])))

# Merge RMA data
panel <- merge(panel, rma_clean, by = c("fips5", "year"), all.x = TRUE)

# Counties with no RMA data = non-agricultural
panel[is.na(indemnity), `:=`(
  indemnity = 0, premium = 0, subsidy = 0,
  liability = 0, policies = 0, net_acres = 0
)]

# Flag agricultural county
panel[, ag_county := as.integer(fips5 %in% ag_counties)]

# Per capita measures
panel[, `:=`(
  indemnity_pc = indemnity / pop * 1000,  # per 1000 people
  premium_pc = premium / pop * 1000,
  subsidy_pc = subsidy / pop * 1000
)]

# Insurance penetration: liability / (pop * some scaling)
# Better: use pre-period average insurance coverage as a fixed characteristic
panel_pre <- panel[year <= 2007 & ag_county == 1,
                   .(avg_premium_pc = mean(premium_pc, na.rm = TRUE),
                     avg_liability_pc = mean(liability / pop * 1000, na.rm = TRUE),
                     avg_policies_pc = mean(policies / pop * 1000, na.rm = TRUE)),
                   by = fips5]

panel <- merge(panel, panel_pre, by = "fips5", all.x = TRUE)

# Quintiles of insurance penetration (for triple-diff)
panel[ag_county == 1 & !is.na(avg_premium_pc),
      ins_quintile := ntile(avg_premium_pc, 5), by = character(0)]
panel[, high_insurance := as.integer(ins_quintile >= 4)]

# Drought indicator
panel[, drought := as.integer(pdsi_growing < -2)]  # Severe drought

# Summary stats
cat(sprintf("  Panel: %d county-years\n", nrow(panel)))
cat(sprintf("  Counties: %d total, %d agricultural\n",
            n_distinct(panel$fips5), n_distinct(panel[ag_county == 1, fips5])))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Ag counties with insurance data: %d\n",
            n_distinct(panel[ag_county == 1 & premium > 0, fips5])))
cat(sprintf("  Drought county-years: %d (%.1f%%)\n",
            sum(panel$drought, na.rm = TRUE),
            100 * mean(panel$drought, na.rm = TRUE)))
cat(sprintf("  Mean OD rate: %.1f per 100K\n", mean(panel$od_rate, na.rm = TRUE)))
cat(sprintf("  Mean indemnity/capita (ag counties): $%.0f\n",
            mean(panel[ag_county == 1, indemnity_pc], na.rm = TRUE)))

# Save
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis_panel.csv\n")
