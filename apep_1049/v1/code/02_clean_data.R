# 02_clean_data.R — Construct analysis panel
# apep_1049: EU Single-Use Plastics Directive

source("00_packages.R")

# ===========================================================================
# Load raw data
# ===========================================================================
waspac <- readRDS("data/waspac_gen.rds")
transposition <- readRDS("data/transposition.rds")
gdp <- readRDS("data/gdp_pc.rds")
pop <- readRDS("data/population.rds")

eu27 <- data.table(
  iso2 = c("AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR",
           "DE","EL","HU","IE","IT","LV","LT","LU","MT","NL",
           "PL","PT","RO","SK","SI","ES","SE")
)

# ===========================================================================
# 1. Reshape packaging waste: wide by material
# ===========================================================================
message("Reshaping packaging waste data...")

# Rename waste categories for clarity
waste_labels <- data.table(
  waste = c("W150101", "W150102", "W150103", "W150104", "W150107", "W1501"),
  material = c("paper", "plastic", "wood", "metal", "glass", "total")
)

waspac <- merge(waspac, waste_labels, by = "waste")

# Unit: tonnes (T) — check
message("Units in data: ", paste(unique(waspac$unit), collapse = ", "))

# Keep tonnes
waspac_t <- waspac[unit == "T"]

# Cast wide: one column per material
panel_wide <- dcast(waspac_t, geo + year ~ material, value.var = "values")

message(sprintf("Panel: %d country-years, %d countries, years %d-%d",
                nrow(panel_wide), uniqueN(panel_wide$geo),
                min(panel_wide$year), max(panel_wide$year)))

# ===========================================================================
# 2. Merge population to create per-capita measures
# ===========================================================================
panel <- merge(panel_wide, pop, by = c("geo", "year"), all.x = TRUE)

# Per capita (kg per person)
for (mat in c("plastic", "paper", "glass", "metal", "wood", "total")) {
  panel[, paste0(mat, "_pc") := get(mat) / population * 1000]  # tonnes to kg
}

# Substitution ratio: plastic share of total
panel[, plastic_share := plastic / total]
# Paper share
panel[, paper_share := paper / total]

# ===========================================================================
# 3. Merge transposition treatment
# ===========================================================================
trans_lookup <- transposition[!is.na(iso2), .(geo = iso2, effective_year)]

panel <- merge(panel, trans_lookup, by = "geo", all.x = TRUE)

# Treatment indicator
panel[, treated := fifelse(!is.na(effective_year) & year >= effective_year, 1L, 0L)]

# Callaway-Sant'Anna requires first_treat = 0 for never-treated
# Countries without transposition date in our data = never-treated (or very late)
panel[, first_treat := fifelse(is.na(effective_year), 0L, effective_year)]

# ===========================================================================
# 4. Merge GDP controls
# ===========================================================================
panel <- merge(panel, gdp, by = c("geo", "year"), all.x = TRUE)
panel[, ln_gdp_pc := log(gdp_pc)]

# ===========================================================================
# 5. Create country numeric ID for Callaway-Sant'Anna
# ===========================================================================
panel[, country_id := as.integer(factor(geo))]

# ===========================================================================
# 6. Filter to analysis sample
# ===========================================================================
# Keep 2006-2023 (data availability window)
panel <- panel[year >= 2006 & year <= 2023]

# Drop observations with missing primary outcome
panel <- panel[!is.na(plastic_pc)]

# Summary
message("\n=== Analysis Panel Summary ===")
message(sprintf("Observations: %d", nrow(panel)))
message(sprintf("Countries: %d", uniqueN(panel$geo)))
message(sprintf("Years: %d-%d", min(panel$year), max(panel$year)))
message(sprintf("Treated countries: %d", uniqueN(panel$geo[panel$first_treat > 0])))
message(sprintf("Never-treated: %d", uniqueN(panel$geo[panel$first_treat == 0])))
message(sprintf("Treatment cohorts: %s", paste(sort(unique(panel$first_treat[panel$first_treat > 0])), collapse = ", ")))

# Cohort distribution
cohort_tab <- panel[first_treat > 0, .(n_countries = uniqueN(geo)), by = first_treat]
message("\nCohort sizes:")
print(cohort_tab[order(first_treat)])

# Pre-treatment years
message(sprintf("\nPre-treatment periods (before earliest transposition): %d years",
                min(panel$first_treat[panel$first_treat > 0]) - min(panel$year)))

# ===========================================================================
# 7. Save analysis panel
# ===========================================================================
saveRDS(panel, "data/analysis_panel.rds")
fwrite(panel, "data/analysis_panel.csv")

message("\nAnalysis panel saved to data/analysis_panel.rds")
