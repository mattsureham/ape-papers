# =============================================================================
# 02_clean_data.R — Construct county-level panel with treatment exposure
# apep_0965: EU Retaliatory Tariffs and US County Employment
# =============================================================================

source("00_packages.R")

targeted_county <- fread("../data/targeted_county_qtr.csv")
mfg_county <- fread("../data/mfg_county_qtr.csv")

# ---------------------------------------------------------------------------
# Step 1: Construct treatment exposure
# Exposure = targeted emp / total mfg emp, measured at 2017Q4
# ---------------------------------------------------------------------------

# County total manufacturing employment in 2017Q4
county_mfg_2017q4 <- mfg_county[year == 2017 & quarter == 4,
  .(total_mfg_emp = emp), by = fips]

# County targeted employment in 2017Q4
county_targeted_2017q4 <- targeted_county[year == 2017 & quarter == 4,
  .(targeted_emp = emp_targeted), by = fips]

# Merge
exposure <- merge(county_mfg_2017q4, county_targeted_2017q4,
                  by = "fips", all.x = TRUE)
exposure[is.na(targeted_emp), targeted_emp := 0]
exposure[, exposure_share := targeted_emp / total_mfg_emp]
exposure[is.na(exposure_share) | is.infinite(exposure_share), exposure_share := 0]

message(sprintf("Counties with any targeted employment: %d / %d",
                exposure[targeted_emp > 0, .N], nrow(exposure)))
message(sprintf("Mean exposure share: %.3f, Median: %.3f",
                mean(exposure$exposure_share), median(exposure$exposure_share)))

# ---------------------------------------------------------------------------
# Step 2: Merge panel
# ---------------------------------------------------------------------------

panel <- merge(mfg_county, targeted_county,
               by = c("fips", "year", "quarter"), all.x = TRUE)
panel[is.na(emp_targeted), emp_targeted := 0]
panel[is.na(hira_targeted), hira_targeted := 0]
panel[is.na(sep_targeted), sep_targeted := 0]

# Merge exposure
panel <- merge(panel, exposure[, .(fips, exposure_share, targeted_emp, total_mfg_emp)],
               by = "fips", all.x = TRUE)

# ---------------------------------------------------------------------------
# Step 3: Create analysis variables
# ---------------------------------------------------------------------------

panel[, yq := year + (quarter - 1) / 4]
panel[, post := as.integer(year > 2018 | (year == 2018 & quarter >= 3))]
panel[, rel_time := (year - 2018) * 4 + (quarter - 3)]

# Log outcomes
panel[, log_emp := log(emp + 1)]
panel[, log_hira := log(hira + 1)]
panel[, log_sep := log(sep + 1)]
panel[, log_emp_targeted := log(emp_targeted + 1)]

# State FIPS
panel[, state_fips := as.integer(substr(sprintf("%05d", fips), 1, 2))]

# Year-quarter factor
panel[, yq_factor := factor(paste0(year, "Q", quarter))]

# Exposure categories
panel[, exposure_cat := fcase(
  exposure_share > 0.05, "High (>5%)",
  exposure_share > 0.02, "Medium (2-5%)",
  exposure_share > 0, "Low (0-2%)",
  default = "None"
)]
panel[, exposure_cat := factor(exposure_cat,
  levels = c("None", "Low (0-2%)", "Medium (2-5%)", "High (>5%)"))]

# ---------------------------------------------------------------------------
# Step 4: Balanced panel
# ---------------------------------------------------------------------------

# Drop counties with zero mfg emp
panel <- panel[total_mfg_emp > 0]

# Balanced panel: counties present in all 32 quarters
county_obs <- panel[, .N, by = fips]
max_obs <- max(county_obs$N)
balanced_counties <- county_obs[N == max_obs, fips]

message(sprintf("Balanced counties: %d / %d (%.0f%%)",
                length(balanced_counties), nrow(county_obs),
                100 * length(balanced_counties) / nrow(county_obs)))

panel_bal <- panel[fips %in% balanced_counties]

message(sprintf("Final balanced panel: %s obs, %d counties, %d quarters",
                format(nrow(panel_bal), big.mark = ","),
                panel_bal[, uniqueN(fips)],
                panel_bal[, uniqueN(yq)]))

# Exposure distribution
message("Exposure distribution:")
message(sprintf("  None: %d counties", panel_bal[yq == 2018, sum(exposure_cat == "None")]))
message(sprintf("  Low: %d counties", panel_bal[yq == 2018, sum(exposure_cat == "Low (0-2%)")]))
message(sprintf("  Medium: %d counties", panel_bal[yq == 2018, sum(exposure_cat == "Medium (2-5%)")]))
message(sprintf("  High: %d counties", panel_bal[yq == 2018, sum(exposure_cat == "High (>5%)")]))

# Save
fwrite(panel, "../data/county_panel_full.csv")
fwrite(panel_bal, "../data/county_panel_balanced.csv")
fwrite(exposure, "../data/county_exposure.csv")
message("Saved county panel and exposure data.")
