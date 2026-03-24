# 02_clean_data.R — Build analysis panel
# apep_0870: Upload Filter Tax

source("code/00_packages.R")

# ============================================================================
# 1. LOAD RAW DATA
# ============================================================================

emp      <- fread("data/employment_by_sector.csv")
trans    <- fread("data/transposition_dates.csv")
gdp      <- fread("data/nuts2_gdp.csv")
pop      <- fread("data/nuts2_population.csv")

message("Employment obs: ", nrow(emp))
message("Unique NUTS2: ", uniqueN(emp$geo))

# ============================================================================
# 2. MERGE TRANSPOSITION TREATMENT
# ============================================================================

# Create treatment map: country → transposition_year
treat_map <- trans[!is.na(transposition_year), .(iso2, transposition_year)]
# EEA controls are never-treated (no transposition_year)
eea_controls <- c("NO", "CH", "IS")

emp[, country := substr(geo, 1, 2)]
emp <- merge(emp, treat_map, by.x = "country", by.y = "iso2", all.x = TRUE)
# EEA controls: never treated
emp[country %in% eea_controls, transposition_year := NA_integer_]

# Binary treatment indicator
emp[, treated := fifelse(!is.na(transposition_year) & year >= transposition_year, 1L, 0L)]

# Relative time to treatment (for event study)
emp[, rel_time := fifelse(!is.na(transposition_year), year - transposition_year, NA_integer_)]

# ============================================================================
# 3. MERGE CONTROLS
# ============================================================================

emp <- merge(emp, gdp, by = c("geo", "year"), all.x = TRUE)
emp <- merge(emp, pop, by = c("geo", "year"), all.x = TRUE)

# GDP per capita
emp[, gdp_pc := gdp_mio * 1e6 / population]

# Log employment (main outcome)
emp[, log_emp := log(emp + 1)]

# Employment share (NACE J or K / total) — alternative outcome
emp_wide <- dcast(emp, geo + year + country + transposition_year + treated + rel_time +
                    gdp_mio + population + gdp_pc ~ nace,
                  value.var = "emp", fun.aggregate = mean, na.rm = TRUE)
setnames(emp_wide, c("J", "K", "TOTAL"), c("emp_j", "emp_k", "emp_total"),
         skip_absent = TRUE)
emp_wide[, share_j := emp_j / emp_total]
emp_wide[, share_k := emp_k / emp_total]
emp_wide[, log_emp_j := log(emp_j + 1)]
emp_wide[, log_emp_k := log(emp_k + 1)]

# ============================================================================
# 4. FILTER PANEL
# ============================================================================

# Keep 2015-2023 (5+ pre-treatment years for earliest treated: NL 2020)
emp_wide <- emp_wide[year >= 2015 & year <= 2023]

# Drop regions with too many missing years
region_coverage <- emp_wide[, .(n_years = sum(!is.na(emp_j))), by = geo]
good_regions <- region_coverage[n_years >= 6, geo]
emp_wide <- emp_wide[geo %in% good_regions]

message("\n=== Panel Summary ===")
message("Observations: ", nrow(emp_wide))
message("NUTS2 regions: ", uniqueN(emp_wide$geo))
message("Countries: ", uniqueN(emp_wide$country))
message("Years: ", min(emp_wide$year), "-", max(emp_wide$year))
message("Treated regions: ", uniqueN(emp_wide[treated == 1, geo]))
message("Never-treated (EEA control) regions: ",
        uniqueN(emp_wide[country %in% c("NO", "CH", "IS"), geo]))

# Treatment timing distribution
treat_dist <- unique(emp_wide[!is.na(transposition_year),
                              .(country, transposition_year)])[order(transposition_year)]
message("\nTransposition timing:")
print(treat_dist)

# ============================================================================
# 5. SAVE
# ============================================================================

# Long-format panel (for CS-DiD with sector dimension)
emp_long <- emp[year >= 2015 & year <= 2023 & geo %in% good_regions]
fwrite(emp_long, "data/panel_long.csv")
message("\nSaved: data/panel_long.csv (", nrow(emp_long), " rows)")

# Wide-format panel (region-year, main analysis)
fwrite(emp_wide, "data/panel_wide.csv")
message("Saved: data/panel_wide.csv (", nrow(emp_wide), " rows)")

# ============================================================================
# 6. CS-DiD FORMATTED DATA
# ============================================================================

# For did::att_gt(): need numeric group variable (transposition_year, 0 for never-treated)
csdid_data <- copy(emp_wide)
csdid_data[, group := fifelse(is.na(transposition_year), 0L, transposition_year)]
csdid_data[, id := as.integer(factor(geo))]

# Verify CS-DiD requirements
n_treated_units <- uniqueN(csdid_data[group > 0, geo])
n_pre <- uniqueN(csdid_data[year < min(csdid_data[group > 0, group]), year])
message("\nCS-DiD requirements:")
message("  Treated units: ", n_treated_units, " (need >= 20)")
message("  Pre-periods: ", n_pre, " (need >= 5)")

fwrite(csdid_data, "data/panel_csdid.csv")
message("Saved: data/panel_csdid.csv")
