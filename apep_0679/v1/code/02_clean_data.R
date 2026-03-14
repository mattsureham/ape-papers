## 02_clean_data.R — Clean and construct analysis panel
## apep_0679: Apprenticeship Levy and Entry-Level Training Crowding Out

source("00_packages.R")

paper_dir <- dirname(getwd())
data_dir <- file.path(paper_dir, "data")

# ==============================================================================
# 1. Parse historical XLSX into long panel
# ==============================================================================
cat("=== Parsing historical apprenticeship data ===\n")

la_raw <- fread(file.path(data_dir, "historical_la_raw.csv"))
cat(sprintf("Raw: %d LAs, columns: %s\n", nrow(la_raw), paste(names(la_raw), collapse=", ")))

# Melt wide to long — columns are year columns
# Exclude cumulative "Since May 2010" and partial "Q4 2009/10"
year_cols <- names(la_raw)[grepl("^20[01][0-9]", names(la_raw))]
year_cols <- year_cols[!grepl("Since|Q4", year_cols)]
cat(sprintf("Year columns: %s\n", paste(year_cols, collapse=", ")))

la_long <- melt(la_raw, id.vars = "la_name",
                measure.vars = year_cols,
                variable.name = "year_label", value.name = "starts_raw")

# Parse academic year to numeric (start year)
la_long[, acad_year := as.numeric(substr(gsub("[^0-9/]", "", year_label), 1, 4))]

# Handle special values: "-" means suppressed/0, clean numeric
la_long[, starts := as.numeric(gsub("[^0-9.]", "", starts_raw))]
la_long[is.na(starts) | starts_raw == "-", starts := 0]

# Drop any remaining non-annual columns
la_long <- la_long[acad_year >= 2010]

cat(sprintf("Panel: %d LA-year observations\n", nrow(la_long)))
cat(sprintf("Years: %s\n", paste(sort(unique(la_long$acad_year)), collapse=", ")))
cat(sprintf("LAs: %d\n", n_distinct(la_long$la_name)))

# ==============================================================================
# 2. Link LA names to ONS codes via geo lookup
# ==============================================================================
cat("\n=== Linking LA names to codes ===\n")

geo <- fread(file.path(data_dir, "geo_code_lookup.csv"))
cat(sprintf("Geo lookup columns: %s\n", paste(names(geo), collapse=", ")))

# From inspection: col4 = LA name, col5 = LA code
# Header row: "LA", "LA Code"
geo_la <- geo[, .SD, .SDcols = c(4,5)]
names(geo_la) <- c("la_name_lookup", "la_code")
geo_la <- geo_la[!is.na(la_name_lookup) & la_name_lookup != "" &
                  !grepl("^LA$|Local Authority|Code", la_name_lookup)]

cat(sprintf("Geo lookup LAs: %d\n", nrow(geo_la)))

# Fuzzy match by name (historical data uses LA names, need to match to codes)
la_long[, la_name_clean := trimws(la_name)]
geo_la[, la_name_clean := trimws(la_name_lookup)]

# Direct merge
panel <- merge(la_long, geo_la[, .(la_name_clean, la_code)],
               by = "la_name_clean", all.x = TRUE)

matched <- sum(!is.na(panel$la_code))
cat(sprintf("Matched: %d / %d (%.0f%%)\n", matched, nrow(panel),
            100 * matched / nrow(panel)))

# For unmatched, try case-insensitive
if (matched < nrow(panel)) {
  unmatched <- unique(panel[is.na(la_code)]$la_name_clean)
  cat(sprintf("Unmatched LAs: %s\n", paste(head(unmatched, 10), collapse=", ")))

  # Try matching by removing "and" vs "&" etc.
  geo_la[, la_name_norm := tolower(gsub("\\band\\b", "&", la_name_clean))]
  panel[, la_name_norm := tolower(gsub("\\band\\b", "&", la_name_clean))]
  backup_match <- merge(
    panel[is.na(la_code), .(la_name_clean, la_name_norm)],
    geo_la[, .(la_name_norm, la_code_backup = la_code)],
    by = "la_name_norm"
  )
  if (nrow(backup_match) > 0) {
    panel <- merge(panel, unique(backup_match[, .(la_name_clean, la_code_backup)]),
                   by = "la_name_clean", all.x = TRUE)
    panel[is.na(la_code), la_code := la_code_backup]
    panel[, la_code_backup := NULL]
    cat(sprintf("After fuzzy match: %d matched\n", sum(!is.na(panel$la_code))))
  }
}

# Drop LAs without codes (likely summary rows)
panel <- panel[!is.na(la_code) & grepl("^E", la_code)]
cat(sprintf("Panel after code filter: %d rows, %d LAs\n",
            nrow(panel), n_distinct(panel$la_code)))

# ==============================================================================
# 3. Construct Bartik instrument from NOMIS business counts
# ==============================================================================
cat("\n=== Constructing Bartik instrument ===\n")

biz <- fread(file.path(data_dir, "nomis_business_counts_2016.csv"))

# Pivot to wide: Total and Large(250+) per LA
biz_wide <- dcast(biz, GEOGRAPHY_CODE + GEOGRAPHY_NAME ~ EMPLOYMENT_SIZEBAND_NAME,
                  value.var = "OBS_VALUE")

if ("Total" %in% names(biz_wide) && "Large (250+)" %in% names(biz_wide)) {
  biz_wide[, levy_exposure := `Large (250+)` / Total]
} else {
  # Fallback naming
  total_col <- names(biz_wide)[grepl("^Total$", names(biz_wide))]
  large_col <- names(biz_wide)[grepl("Large|250", names(biz_wide))]
  biz_wide[, levy_exposure := get(large_col[1]) / get(total_col[1])]
}

biz_wide[is.na(levy_exposure) | is.infinite(levy_exposure), levy_exposure := 0]

cat(sprintf("Levy exposure — Mean: %.4f, SD: %.4f, P10: %.4f, P90: %.4f\n",
            mean(biz_wide$levy_exposure), sd(biz_wide$levy_exposure),
            quantile(biz_wide$levy_exposure, 0.1),
            quantile(biz_wide$levy_exposure, 0.9)))

# ==============================================================================
# 4. Merge population data
# ==============================================================================
cat("\n=== Merging population data ===\n")

pop <- fread(file.path(data_dir, "nomis_population_la.csv"))
pop[, pop := as.numeric(OBS_VALUE)]
pop[, year := as.numeric(gsub("[^0-9]", "", DATE_NAME))]
pop[, acad_year := year]  # Calendar year ~ academic year start

pop_clean <- pop[!is.na(pop) & pop > 0, .(la_code = GEOGRAPHY_CODE, acad_year, pop)]
cat(sprintf("Population: %d LA-year observations with valid values\n", nrow(pop_clean)))

# ==============================================================================
# 5. Merge everything
# ==============================================================================
cat("\n=== Building analysis panel ===\n")

# Merge Bartik instrument
analysis <- merge(panel, biz_wide[, .(la_code = GEOGRAPHY_CODE, levy_exposure)],
                  by = "la_code", all.x = TRUE)

# Merge population
analysis <- merge(analysis, pop_clean, by = c("la_code", "acad_year"), all.x = TRUE)

# Create analysis variables
analysis[, post_levy := as.numeric(acad_year >= 2017)]
analysis[, levy_x_post := levy_exposure * post_levy]
analysis[, event_time := acad_year - 2017]
analysis[, log_starts := log(starts + 1)]

# Per capita (where population available)
analysis[, starts_per_10k := ifelse(!is.na(pop) & pop > 0,
                                     (starts / pop) * 10000, NA_real_)]

# Drop rows without Bartik instrument
analysis <- analysis[!is.na(levy_exposure)]

cat(sprintf("\n=== Final analysis panel ===\n"))
cat(sprintf("Observations: %d\n", nrow(analysis)))
cat(sprintf("Unique LAs: %d\n", n_distinct(analysis$la_code)))
cat(sprintf("Years: %s\n", paste(sort(unique(analysis$acad_year)), collapse=", ")))
cat(sprintf("Pre-Levy years: %d\n", length(unique(analysis[post_levy == 0]$acad_year))))
cat(sprintf("Post-Levy years: %d\n", length(unique(analysis[post_levy == 1]$acad_year))))
cat(sprintf("With population: %d / %d\n",
            sum(!is.na(analysis$pop)), nrow(analysis)))

# Summary stats
cat("\n--- Pre/Post summary ---\n")
cat(sprintf("Mean starts (pre): %.0f\n", mean(analysis[post_levy == 0]$starts)))
cat(sprintf("Mean starts (post): %.0f\n", mean(analysis[post_levy == 1]$starts)))
cat(sprintf("Change: %.1f%%\n",
            (mean(analysis[post_levy == 1]$starts) / mean(analysis[post_levy == 0]$starts) - 1) * 100))

# Tercile summary
analysis[, levy_tercile := cut(levy_exposure,
  breaks = quantile(levy_exposure, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
  labels = c("Low", "Medium", "High"), include.lowest = TRUE)]

cat("\n--- By levy exposure tercile ---\n")
summ <- analysis[, .(mean_starts = mean(starts),
                      mean_log = mean(log_starts)),
                  by = .(levy_tercile, post_levy)]
print(summ[order(levy_tercile, post_levy)])

# Save
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\nSaved: %s\n", file.path(data_dir, "analysis_panel.csv")))
