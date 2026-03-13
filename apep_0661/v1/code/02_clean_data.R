# 02_clean_data.R — Clean and merge all datasets for apep_0661
# UK Asylum Dispersal and Local Crime

source("00_packages.R")
library(readODS)

data_dir <- "../data"

# =============================================================================
# 1. ASYLUM DATA
# =============================================================================
cat("=== 1. Cleaning asylum data ===\n")

asylum_raw <- as.data.table(readxl::read_excel(
  file.path(data_dir, "asylum_support_la.xlsx"),
  sheet = "Data_Asy_D11", skip = 1, .name_repair = "unique"))
setnames(asylum_raw, c("date", "support_type", "region", "la_name",
                         "lad_code", "accom_type", "people"))
asylum_raw[, people := as.numeric(people)]
asylum_raw[, date_parsed := as.Date(date, format = "%d %b %Y")]
if (all(is.na(asylum_raw$date_parsed))) asylum_raw[, date_parsed := as.Date(date)]
asylum_raw[, year := as.integer(format(date_parsed, "%Y"))]
asylum_raw[, quarter := ceiling(as.integer(format(date_parsed, "%m")) / 3)]
asylum_raw[, yq := paste0(year, "Q", quarter)]

# Total asylum seekers per LA-quarter
asylum <- asylum_raw[!is.na(lad_code) & lad_code != "N/A" & !grepl("N/A", la_name),
                      .(asylum_total = sum(people, na.rm = TRUE)),
                      by = .(lad_code, la_name, region, year, quarter, yq)]

# Dispersal only
disp <- asylum_raw[accom_type == "Dispersal Accommodation" &
                      !is.na(lad_code) & lad_code != "N/A" & !grepl("N/A", la_name),
                    .(asylum_dispersal = sum(people, na.rm = TRUE)),
                    by = .(lad_code, year, quarter, yq)]
asylum <- merge(asylum, disp, by = c("lad_code", "year", "quarter", "yq"), all.x = TRUE)
asylum[is.na(asylum_dispersal), asylum_dispersal := 0]

cat("Asylum:", nrow(asylum), "rows,", uniqueN(asylum$lad_code), "LAs,",
    uniqueN(asylum$yq), "quarters\n")

# =============================================================================
# 2. CRIME DATA
# =============================================================================
cat("\n=== 2. Cleaning crime data ===\n")

crime_file <- file.path(data_dir, "prc_csp_2016_2024.ods")
crime_sheets <- grep("^20", list_ods_sheets(crime_file), value = TRUE)

crime_list <- list()
for (s in crime_sheets) {
  d <- as.data.table(read_ods(crime_file, sheet = s))
  setnames(d, c("fin_year", "fin_quarter", "police_force", "csp_name",
                "offence_desc", "offence_group", "offence_subgroup",
                "offence_code", "count"))
  d[, count := as.numeric(count)]
  crime_list[[s]] <- d
}
crime_raw <- rbindlist(crime_list, fill = TRUE)

# Financial year-quarter → calendar year-quarter
crime_raw[, fy_start := as.integer(substr(fin_year, 1, 4))]
crime_raw[, fq := as.integer(fin_quarter)]
crime_raw[fq == 1, `:=`(cal_year = fy_start, cal_quarter = 2L)]
crime_raw[fq == 2, `:=`(cal_year = fy_start, cal_quarter = 3L)]
crime_raw[fq == 3, `:=`(cal_year = fy_start, cal_quarter = 4L)]
crime_raw[fq == 4, `:=`(cal_year = fy_start + 1L, cal_quarter = 1L)]
crime_raw[, yq := paste0(cal_year, "Q", cal_quarter)]

crime_raw[, crime_cat := fcase(
  offence_group == "Violence against the person", "violence",
  offence_group == "Theft offences", "theft",
  offence_group == "Criminal damage and arson", "criminal_damage",
  offence_group == "Drug offences", "drugs",
  offence_group == "Public order offences", "public_order",
  offence_group == "Sexual offences", "sexual",
  offence_group == "Possession of weapons offences", "weapons",
  offence_group == "Robbery", "robbery",
  default = "other"
)]

crime_total <- crime_raw[, .(total_crime = sum(count, na.rm = TRUE)),
                          by = .(csp_name, cal_year, cal_quarter, yq)]

crime_cats <- dcast(crime_raw[, .(cnt = sum(count, na.rm = TRUE)),
                               by = .(csp_name, yq, crime_cat)],
                    csp_name + yq ~ crime_cat, value.var = "cnt", fill = 0)
crime_panel <- merge(crime_total, crime_cats, by = c("csp_name", "yq"))

cat("Crime:", nrow(crime_panel), "rows,", uniqueN(crime_panel$csp_name), "CSPs\n")

# =============================================================================
# 3. NAME MATCHING: CSP ↔ LA
# =============================================================================
cat("\n=== 3. Matching CSP names to LA names ===\n")

# Most CSPs have the same name as their LA. Build a comprehensive mapping.
# Start with the CSP→LA table in the ONS file (combined CSPs only)
csp_map_raw <- as.data.table(readxl::read_excel(
  file.path(data_dir, "ons_crime_pfa.xlsx"),
  sheet = "Table C1", skip = 3, .name_repair = "unique"))
setnames(csp_map_raw, c("pfa_name", "csp_name", "la_code", "la_name"))
csp_map_raw <- csp_map_raw[!is.na(la_code) & la_code != ""]

# For combined CSPs: create a mapping from LA code → CSP name
combined_la_to_csp <- csp_map_raw[, .(csp_name = csp_name[1]), by = la_code]

# For all other LAs: CSP name = LA name
# Match asylum LA names to crime CSP names directly
csp_names <- unique(crime_panel$csp_name)
la_names <- unique(asylum$la_name)

# Direct matches
direct <- intersect(csp_names, la_names)
cat("Direct name matches:", length(direct), "\n")

# Build full mapping: for each asylum LA, find its CSP name
asylum[, csp_name := la_name]  # default: CSP = LA name

# Override with combined CSP mapping where applicable
for (i in seq_len(nrow(combined_la_to_csp))) {
  la_c <- combined_la_to_csp$la_code[i]
  csp_n <- combined_la_to_csp$csp_name[i]
  asylum[lad_code == la_c, csp_name := csp_n]
}

# Manual fixes for common naming differences
name_fixes <- list(
  c("York", "City of York"),
  c("Kingston upon Hull, City of", "Kingston upon Hull"),
  c("Bristol, City of", "Bristol"),
  c("Herefordshire, County of", "Herefordshire"),
  c("Durham", "County Durham")
)
for (fix in name_fixes) {
  asylum[la_name == fix[1], csp_name := fix[2]]
  asylum[la_name == fix[2], csp_name := fix[1]]
}
# Try both directions
for (fix in name_fixes) {
  if (fix[1] %in% csp_names) asylum[la_name == fix[2], csp_name := fix[1]]
  if (fix[2] %in% csp_names) asylum[la_name == fix[1], csp_name := fix[2]]
}

# Check match rate
matched <- sum(asylum$csp_name %in% csp_names)
cat("Matched rows:", matched, "/", nrow(asylum), sprintf("(%.0f%%)\n", 100 * matched / nrow(asylum)))

# Aggregate asylum to CSP-quarter level
asylum_csp <- asylum[csp_name %in% csp_names,
                      .(asylum_total = sum(asylum_total, na.rm = TRUE),
                        asylum_dispersal = sum(asylum_dispersal, na.rm = TRUE)),
                      by = .(csp_name, year, quarter, yq)]
cat("Asylum by CSP:", nrow(asylum_csp), "rows,", uniqueN(asylum_csp$csp_name), "CSPs\n")

# =============================================================================
# 4. CENSUS VACANCY
# =============================================================================
cat("\n=== 4. Census vacancy ===\n")
census <- fread(file.path(data_dir, "census_clean.csv"))

# Map census LA codes to CSP names
census[, csp_name := GEOGRAPHY_NAME]
for (i in seq_len(nrow(combined_la_to_csp))) {
  census[GEOGRAPHY_CODE == combined_la_to_csp$la_code[i],
         csp_name := combined_la_to_csp$csp_name[i]]
}

census_csp <- census[csp_name %in% csp_names,
                      .(total_dwellings = sum(total_dwellings, na.rm = TRUE),
                        vacant = sum(vacant, na.rm = TRUE)),
                      by = csp_name]
census_csp[, vacancy_share := vacant / total_dwellings]
cat("Census CSPs:", nrow(census_csp), "\n")

# =============================================================================
# 5. POPULATION
# =============================================================================
cat("\n=== 5. Population data ===\n")
pop_raw <- as.data.table(readxl::read_excel(
  file.path(data_dir, "ons_population_ts.xlsx"),
  sheet = "MYEB1", skip = 1, .name_repair = "unique"))
setnames(pop_raw, 1:5, c("lad_code", "la_name", "country", "sex", "age"))
year_cols <- grep("^population_", names(pop_raw), value = TRUE)

pop_long <- melt(pop_raw[, c("lad_code", "la_name", year_cols), with = FALSE],
                 id.vars = c("lad_code", "la_name"),
                 variable.name = "yr", value.name = "pop")
pop_long[, year := as.integer(gsub("population_", "", yr))]
pop_long[, pop := as.numeric(pop)]
pop_la <- pop_long[, .(population = sum(pop, na.rm = TRUE)), by = .(lad_code, la_name, year)]
pop_la <- pop_la[population > 0]

# Map to CSP names
pop_la[, csp_name := la_name]
for (i in seq_len(nrow(combined_la_to_csp))) {
  pop_la[lad_code == combined_la_to_csp$la_code[i],
         csp_name := combined_la_to_csp$csp_name[i]]
}
pop_csp <- pop_la[csp_name %in% csp_names,
                   .(population = sum(population, na.rm = TRUE)),
                   by = .(csp_name, year)]
cat("Population CSPs:", uniqueN(pop_csp$csp_name), "\n")

# =============================================================================
# 6. BUILD FINAL PANEL
# =============================================================================
cat("\n=== 6. Building final panel ===\n")

# Start with crime panel (most complete)
panel <- copy(crime_panel)

# Add asylum data
panel <- merge(panel, asylum_csp, by = c("csp_name", "yq"), all.x = TRUE)
panel[is.na(asylum_total), asylum_total := 0]
panel[is.na(asylum_dispersal), asylum_dispersal := 0]
# Fix year/quarter from crime data
panel[is.na(year), year := cal_year]
panel[is.na(quarter), quarter := cal_quarter]

# Add population
panel <- merge(panel, pop_csp, by.x = c("csp_name", "cal_year"),
               by.y = c("csp_name", "year"), all.x = TRUE)

# Add vacancy share
panel <- merge(panel, census_csp[, .(csp_name, vacancy_share)],
               by = "csp_name", all.x = TRUE)

# Compute rates (per 1,000 population)
panel[, crime_rate := total_crime / (population / 1000)]
panel[, asylum_rate := asylum_total / (population / 1000)]
panel[, dispersal_rate := asylum_dispersal / (population / 1000)]

# Category rates
for (cat_name in c("violence", "theft", "criminal_damage", "drugs",
                    "public_order", "sexual", "weapons", "robbery", "other")) {
  panel[, paste0(cat_name, "_rate") := get(cat_name) / (population / 1000)]
}

# Shift-share IV
national_asylum <- asylum_raw[!grepl("N/A", la_name) & !is.na(people),
                                .(national_total = sum(people, na.rm = TRUE)),
                                by = yq]
panel <- merge(panel, national_asylum, by = "yq", all.x = TRUE)
panel[is.na(national_total), national_total := 0]
panel[, ssiv := vacancy_share * national_total]

# Filter to valid observations
panel <- panel[!is.na(population) & population > 0 &
                 !is.na(vacancy_share) & !is.na(crime_rate)]

# Restrict to 2016-2024 (overlapping period)
panel <- panel[cal_year >= 2016 & cal_year <= 2024]

# Create IDs for fixed effects
panel[, csp_id := as.integer(factor(csp_name))]
panel[, time_id := (cal_year - 2016) * 4 + cal_quarter]

cat("\n====== FINAL PANEL ======\n")
cat("Observations:", nrow(panel), "\n")
cat("Unique CSPs:", uniqueN(panel$csp_name), "\n")
cat("Quarters:", uniqueN(panel$yq), "\n")
cat("Year range:", min(panel$cal_year), "-", max(panel$cal_year), "\n")
cat("CSPs with any dispersal:", uniqueN(panel[asylum_dispersal > 0]$csp_name),
    "/", uniqueN(panel$csp_name), "\n")

cat("\nSummary:\n")
for (v in c("crime_rate", "asylum_rate", "dispersal_rate", "vacancy_share")) {
  cat(sprintf("  %s: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
              v, mean(panel[[v]], na.rm = TRUE), sd(panel[[v]], na.rm = TRUE),
              min(panel[[v]], na.rm = TRUE), max(panel[[v]], na.rm = TRUE)))
}

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis_panel.csv\n")

# Diagnostics for validator
jsonlite::write_json(list(
  n_obs = nrow(panel),
  n_treated = uniqueN(panel[asylum_dispersal > 0]$csp_name),
  n_pre = length(unique(panel[cal_year < 2020]$yq)),
  n_csp = uniqueN(panel$csp_name)
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
