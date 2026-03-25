# 02_clean_data.R — Construct analysis panel
# Merge BERD, GDP, employment, and transposition dates at NUTS2 level

source("00_packages.R")

data_dir <- "../data/"

# ===========================================================================
# 1. Load data
# ===========================================================================
berd <- fread(file.path(data_dir, "berd_nuts2.csv"))
gdp <- fread(file.path(data_dir, "gdp_nuts2.csv"))
emp <- fread(file.path(data_dir, "employment_nuts2.csv"))
gerd <- fread(file.path(data_dir, "gerd_nuts2.csv"))
trans <- fread(file.path(data_dir, "transposition_dates.csv"))

message("=== Loaded data ===")
message("BERD: ", nrow(berd), " obs, ", uniqueN(berd$geo), " regions")
message("GDP: ", nrow(gdp), " obs")
message("Employment: ", nrow(emp), " obs")
message("GERD: ", nrow(gerd), " obs")
message("Transposition: ", nrow(trans), " countries")

# CRITICAL: Filter transposition dates to only include post-directive adoption
# Directive 2016/943 was adopted June 8, 2016. Any "transposition" before that
# is a pre-existing trade secret law incorrectly linked by CELLAR SPARQL.
trans_pre <- trans[first_transposition < as.Date("2016-06-09")]
if (nrow(trans_pre) > 0) {
  message("WARNING: Removing ", nrow(trans_pre), " countries with pre-directive dates: ",
          paste(trans_pre$iso2, collapse = ", "))
  trans <- trans[first_transposition >= as.Date("2016-06-09")]
}
message("After filtering: ", nrow(trans), " countries with valid transposition dates")

# ===========================================================================
# 2. Merge BERD + GDP → BERD intensity (% of GDP)
# ===========================================================================
panel <- merge(berd, gdp, by = c("geo", "country", "year"), all.x = TRUE)
panel[, berd_gdp_pct := 100 * berd_mio_eur / gdp_mio_eur]

# Merge employment
panel <- merge(panel, emp, by = c("geo", "country", "year"), all.x = TRUE)

# Merge total GERD
panel <- merge(panel, gerd, by = c("geo", "country", "year"), all.x = TRUE)
panel[, gerd_gdp_pct := 100 * gerd_mio_eur / gdp_mio_eur]

# ===========================================================================
# 3. Add transposition treatment
# ===========================================================================
# Map transposition year to each region via country code
panel <- merge(panel, trans[, .(iso2, transposition_year)],
               by.x = "country", by.y = "iso2", all.x = TRUE)

# Binary treatment: post-transposition indicator
panel[, post := fifelse(!is.na(transposition_year) & year >= transposition_year, 1L, 0L)]

# Event time: years relative to transposition
panel[, event_time := year - transposition_year]

# For Callaway-Sant'Anna: first_treat = transposition_year (0 for never-treated)
# Countries that haven't transposed by end of sample are "never treated"
panel[, first_treat := fifelse(is.na(transposition_year), 0L, transposition_year)]

# ===========================================================================
# 4. Construct treatment intensity (Baker McKenzie proxy)
# Countries with weaker pre-existing trade secret protection got a larger
# "treatment dose." Based on Baker McKenzie (2016) survey and legal analysis:
#   High pre-existing protection (smaller dose): DE, FR, SE, NL, AT, FI
#   Medium: IT, ES, BE, DK, IE, PT
#   Low (largest dose): PL, CZ, SK, HU, RO, BG, HR, SI, LV, LT, EE, CY, MT, EL, LU
# Score: 1 = high pre-existing, 2 = medium, 3 = low
# ===========================================================================
intensity_map <- data.table(
  country = c("DE","FR","SE","NL","AT","FI",       # High existing protection
              "IT","ES","BE","DK","IE","PT","UK",    # Medium
              "PL","CZ","SK","HU","RO","BG","HR",   # Low
              "SI","LV","LT","EE","CY","MT","EL","LU"),
  protection_pre = c(rep(1L, 6), rep(2L, 7), rep(3L, 12))
)

panel <- merge(panel, intensity_map, by = "country", all.x = TRUE)
# Continuous treatment: intensity × post
panel[, treatment_intensity := protection_pre * post]

# ===========================================================================
# 5. Log transform outcome
# ===========================================================================
panel[, ln_berd := log(berd_mio_eur + 1)]
panel[, ln_gdp := log(gdp_mio_eur)]
panel[, ln_gerd := log(gerd_mio_eur + 1)]
panel[, berd_per_emp := berd_mio_eur / (emp_ths + 0.001)]

# ===========================================================================
# 6. Create numeric panel ID for did package
# ===========================================================================
panel[, region_id := as.integer(factor(geo))]

# ===========================================================================
# 7. Balance and coverage checks
# ===========================================================================
# Drop rows with missing BERD (main outcome)
panel_clean <- panel[!is.na(berd_mio_eur) & !is.na(gdp_mio_eur)]

message("\n=== Panel summary ===")
message("Total obs: ", nrow(panel_clean))
message("Regions: ", uniqueN(panel_clean$geo))
message("Countries: ", uniqueN(panel_clean$country))
message("Years: ", min(panel_clean$year), "-", max(panel_clean$year))
message("Treated countries: ", uniqueN(panel_clean[first_treat > 0, country]))
message("Never-treated obs: ", sum(panel_clean$first_treat == 0))

# Cohort sizes
message("\n=== Treatment cohorts ===")
cohorts <- panel_clean[, .(n_regions = uniqueN(geo)), by = first_treat]
print(cohorts[order(first_treat)])

# Coverage by year
message("\n=== BERD coverage by year ===")
coverage <- panel_clean[, .(
  n_regions = uniqueN(geo),
  mean_berd = mean(berd_mio_eur, na.rm = TRUE),
  mean_berd_gdp = mean(berd_gdp_pct, na.rm = TRUE)
), by = year]
print(coverage[order(year)])

# Pre-treatment outcome means by cohort
message("\n=== Pre-treatment BERD intensity by cohort ===")
pre_means <- panel_clean[year < 2018, .(
  mean_berd_gdp = mean(berd_gdp_pct, na.rm = TRUE),
  sd_berd_gdp = sd(berd_gdp_pct, na.rm = TRUE),
  n_regions = uniqueN(geo)
), by = first_treat]
print(pre_means[order(first_treat)])

# ===========================================================================
# 8. Create balanced panel (critical: BERD has biennial reporters)
# ===========================================================================
# Many NUTS2 regions report BERD only biennially, creating a saw-tooth
# composition effect that confounds DiD. Restrict to regions observed in
# at least 12 of 14 years.
region_year_counts <- panel_clean[, .N, by = geo]
message("\n=== Region-year coverage distribution ===")
print(table(region_year_counts$N))

# Balanced panel: regions with data in all years
max_years <- max(region_year_counts$N)
balanced_geos <- region_year_counts[N >= max_years - 2, geo]  # allow missing at most 2 years
panel_balanced <- panel_clean[geo %in% balanced_geos]

message("Balanced panel: ", uniqueN(panel_balanced$geo), " regions (from ",
        uniqueN(panel_clean$geo), " total)")
message("Balanced panel obs: ", nrow(panel_balanced))

# Also create strictly balanced (all years present)
strict_geos <- region_year_counts[N == max_years, geo]
panel_strict <- panel_clean[geo %in% strict_geos]
message("Strictly balanced: ", uniqueN(panel_strict$geo), " regions, ",
        nrow(panel_strict), " obs")

# Check coverage in balanced panel
bal_cov <- panel_balanced[, .N, by = year]
message("\n=== Balanced panel coverage by year ===")
print(bal_cov[order(year)])

# ===========================================================================
# 9. Save
# ===========================================================================
fwrite(panel_clean, file.path(data_dir, "analysis_panel.csv"))
fwrite(panel_balanced, file.path(data_dir, "analysis_panel_balanced.csv"))
fwrite(panel_strict, file.path(data_dir, "analysis_panel_strict.csv"))
message("\nSaved analysis_panel.csv: ", nrow(panel_clean), " obs")
message("Saved analysis_panel_balanced.csv: ", nrow(panel_balanced), " obs")
message("Saved analysis_panel_strict.csv: ", nrow(panel_strict), " obs")

# Also save a summary for diagnostics
summary_stats <- list(
  n_obs = nrow(panel_clean),
  n_regions = uniqueN(panel_clean$geo),
  n_countries = uniqueN(panel_clean$country),
  n_treated_countries = uniqueN(panel_clean[first_treat > 0, country]),
  year_min = min(panel_clean$year),
  year_max = max(panel_clean$year),
  mean_berd_gdp = mean(panel_clean$berd_gdp_pct, na.rm = TRUE),
  sd_berd_gdp = sd(panel_clean$berd_gdp_pct, na.rm = TRUE)
)
write_json(summary_stats, file.path(data_dir, "panel_summary.json"), auto_unbox = TRUE)
