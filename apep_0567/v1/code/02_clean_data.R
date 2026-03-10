# ==============================================================================
# 02_clean_data.R — Construct analysis panel
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
# ==============================================================================

source("00_packages.R")

# ==============================================================================
# 1. Load raw data
# ==============================================================================

cat("Loading raw data files...\n")

# --- Vacancy data (BFS SSE: DF_LWZ_1) ---
stopifnot("Vacancy data missing" = file.exists("../data/vacancy_municipal.csv"))
vacancy <- fread("../data/vacancy_municipal.csv")
# Columns: geo_name, year, vacant_count, vacancy_rate, bfs_nr
vacancy <- vacancy[!is.na(bfs_nr) & bfs_nr >= 1 & bfs_nr <= 6999]
setnames(vacancy, "bfs_nr", "gem_id")
cat("  Vacancy data:", nrow(vacancy), "municipality-year obs\n")

# --- Population data (BFS PXWeb: px-x-0102020000_201) ---
stopifnot("Population data missing" = file.exists("../data/statpop_municipal.csv"))
pop_raw <- fread("../data/statpop_municipal.csv")
# Column: "Kanton (-) / Bezirk (>>) / Gemeinde (......)" has format "......0001 Name"
geo_col <- names(pop_raw)[2]  # The long geo column name
pop_raw[, gem_id := as.integer(sub("^[.]+([0-9]+).*", "\\1", get(geo_col)))]
pop_raw[, year := as.integer(Jahr)]
pop_raw[, population := as.integer(get(names(pop_raw)[5]))]
# Keep only municipality-level rows (those with dots prefix and valid BFS number)
population <- pop_raw[!is.na(gem_id) & gem_id >= 1 & gem_id <= 6999,
                       .(gem_id, year, population)]
cat("  Population data:", nrow(population), "municipality-year obs\n")

# --- Employment data (BFS PXWeb: px-x-0602010000_102) ---
stopifnot("Employment data missing" = file.exists("../data/statent_sector.csv"))
emp_raw <- fread("../data/statent_sector.csv")
# Columns: Jahr, Gemeinde, Wirtschaftssektor, Beobachtungseinheit, value
# Gemeinde format: "1 Aeugst am Albis" or "Schweiz"
emp_raw[, gem_id := as.integer(sub("^([0-9]+) .*", "\\1", Gemeinde))]
emp_raw[, year := as.integer(Jahr)]
setnames(emp_raw, "Arbeitsstätten und Beschäftigte", "value")

# Filter to Beschäftigte (headcount) only
emp_beschaeft <- emp_raw[Beobachtungseinheit == "Beschäftigte" & !is.na(gem_id)]

# Pivot sectors to wide
emp_total <- emp_beschaeft[Wirtschaftssektor == "Wirtschaftssektor - Total",
                            .(gem_id, year, emp_total = value)]
emp_secondary <- emp_beschaeft[Wirtschaftssektor == "Sekundärer Sektor",
                                .(gem_id, year, emp_secondary = value)]
emp_tertiary <- emp_beschaeft[Wirtschaftssektor == "Tertiärer Sektor",
                               .(gem_id, year, emp_tertiary = value)]

employment <- Reduce(function(x, y) merge(x, y, by = c("gem_id", "year"), all = TRUE),
                      list(emp_total, emp_secondary, emp_tertiary))
cat("  Employment data:", nrow(employment), "municipality-year obs\n")

# --- Second-home shares (ARE Wohnungsinventar) ---
stopifnot("ZWA data missing" = file.exists("../data/zwa_current.csv"))
zwa <- fread("../data/zwa_current.csv")
# Columns: gemeinde_nr, gemeinde_name, total_dwellings, zwa_pct, status
setnames(zwa, "gemeinde_nr", "gem_id")
zwa <- zwa[!is.na(gem_id) & !is.na(zwa_pct)]
cat("  ZWA data:", nrow(zwa), "municipalities\n")

# --- Merger crosswalk ---
stopifnot("Merger crosswalk missing" = file.exists("../data/merger_crosswalk.csv"))
mergers <- fread("../data/merger_crosswalk.csv")
# Columns: dissolved_code, successor_code, merger_year
cat("  Merger crosswalk:", nrow(mergers), "mappings\n")

# --- Municipality snapshot (for canton assignment) ---
if (file.exists("../data/municipality_snapshot_2024.csv")) {
  muni_snap <- fread("../data/municipality_snapshot_2024.csv")
  # Level 3 = municipalities; Parent is the Bezirk, not canton directly
  # BfsCode is the municipality BFS number
  # Canton can be derived from the hierarchy: canton-level entries have Level=1
  cantons <- muni_snap[Level == 1, .(canton_code = HistoricalCode, canton_id = BfsCode)]
  bezirke <- muni_snap[Level == 2, .(bezirk_code = HistoricalCode, canton_parent = Parent)]
  gemeinden <- muni_snap[Level == 3, .(gem_id = BfsCode, bezirk_parent = Parent)]
  # Join: Gemeinde -> Bezirk -> Canton
  bez_canton <- merge(bezirke, cantons, by.x = "canton_parent", by.y = "canton_code", all.x = TRUE)
  canton_lookup <- merge(gemeinden, bez_canton[, .(bezirk_code, canton_id)],
                          by.x = "bezirk_parent", by.y = "bezirk_code", all.x = TRUE)
  canton_lookup <- canton_lookup[!is.na(canton_id), .(gem_id, canton_id)]
  cat("  Municipality snapshot:", nrow(canton_lookup), "entries with canton\n")
} else {
  canton_lookup <- NULL
}

# ==============================================================================
# 2. Harmonize municipality IDs (apply merger crosswalk)
# ==============================================================================

cat("\nHarmonizing municipality IDs across time...\n")

# Build transitive closure: follow chain of mergers to current boundary
# Some municipalities merged multiple times
harmonize_id <- function(dt, id_col = "gem_id") {
  dt <- copy(dt)
  merger_map <- mergers[, .(old_id = dissolved_code, new_id = successor_code)]
  # Apply iteratively (handles chains)
  for (iter in 1:5) {
    changed <- 0
    for (i in seq_len(nrow(merger_map))) {
      old <- merger_map$old_id[i]
      new <- merger_map$new_id[i]
      n <- sum(dt[[id_col]] == old, na.rm = TRUE)
      if (n > 0) {
        dt[get(id_col) == old, (id_col) := new]
        changed <- changed + n
      }
    }
    if (changed == 0) break
  }
  return(dt)
}

vacancy    <- harmonize_id(vacancy)
population <- harmonize_id(population)
employment <- harmonize_id(employment)
cat("  Harmonization complete.\n")

# ==============================================================================
# 3. Aggregate to harmonized municipality-year level
# ==============================================================================

cat("Aggregating to municipality-year level...\n")

# Vacancy: take weighted mean of rates, sum of counts
vacancy_panel <- vacancy[, .(
  vacant_count = sum(vacant_count, na.rm = TRUE),
  vacancy_rate = mean(vacancy_rate, na.rm = TRUE)
), by = .(gem_id, year)]

# Population: sum for merged municipalities
pop_panel <- population[, .(
  population = sum(population, na.rm = TRUE)
), by = .(gem_id, year)]
pop_panel[, log_pop := log(population)]

# Employment: sum for merged municipalities
emp_panel <- employment[, .(
  emp_total     = sum(emp_total, na.rm = TRUE),
  emp_secondary = sum(emp_secondary, na.rm = TRUE),
  emp_tertiary  = sum(emp_tertiary, na.rm = TRUE)
), by = .(gem_id, year)]
emp_panel[, `:=`(
  log_emp_total     = log(emp_total + 1),
  log_emp_secondary = log(emp_secondary + 1),
  log_emp_tertiary  = log(emp_tertiary + 1)
)]

# ==============================================================================
# 4. Construct treatment assignment
# ==============================================================================

cat("Constructing treatment assignment...\n")

# Treatment = second-home share > 20% (from current ARE data)
zwa[, treated := as.integer(zwa_pct >= 20)]
treatment <- zwa[, .(gem_id, second_home_share = zwa_pct, treated)]

# Also harmonize the treatment IDs
treatment <- harmonize_id(treatment)
treatment <- treatment[, .(second_home_share = mean(second_home_share),
                            treated = max(treated)), by = gem_id]

cat("  Treated municipalities:", sum(treatment$treated), "\n")
cat("  Control municipalities:", sum(1 - treatment$treated), "\n")
cat("  Mean SH share (treated):", round(mean(treatment$second_home_share[treatment$treated == 1]), 1), "%\n")
cat("  Mean SH share (control):", round(mean(treatment$second_home_share[treatment$treated == 0]), 1), "%\n")

# ==============================================================================
# 5. Merge into master panel
# ==============================================================================

cat("Merging into master panel...\n")

# Start with vacancy panel (longest time series, 1995-2025)
panel <- vacancy_panel[, .(gem_id, year, vacant_count, vacancy_rate)]

# Merge population
panel <- merge(panel, pop_panel[, .(gem_id, year, population, log_pop)],
               by = c("gem_id", "year"), all.x = TRUE)

# Merge employment (only available 2011+)
panel <- merge(panel, emp_panel, by = c("gem_id", "year"), all.x = TRUE)

# Merge treatment assignment
panel <- merge(panel, treatment, by = "gem_id", all.x = TRUE)

# Keep only municipalities with treatment assignment
panel <- panel[!is.na(treated)]

# ==============================================================================
# 6. Create analysis variables
# ==============================================================================

cat("Creating analysis variables...\n")

# Post-treatment indicator (initiative passed March 2012, effective Jan 2013)
panel[, post := as.integer(year >= 2013)]

# Relative year for event study
panel[, rel_year := year - 2013]

# Canton ID — derive from municipality snapshot or BFS numbering
if (!is.null(canton_lookup)) {
  panel <- merge(panel, canton_lookup, by = "gem_id", all.x = TRUE)
  # For any missing, derive from BFS numbering convention
  panel[is.na(canton_id), canton_id := as.integer(substr(sprintf("%04d", gem_id), 1,
                                                          nchar(sprintf("%04d", gem_id)) - 2))]
} else {
  # Derive canton from BFS municipality number
  panel[, canton_id := as.integer(substr(sprintf("%04d", gem_id), 1,
                                          nchar(sprintf("%04d", gem_id)) - 2))]
}

cat("  Cantons:", uniqueN(panel$canton_id), "\n")

# Tourism intensity based on tertiary sector employment share (pre-treatment)
pre_emp <- panel[year %in% 2011:2012 & !is.na(emp_total) & emp_total > 0,
                  .(tert_share = mean(emp_tertiary / emp_total, na.rm = TRUE)),
                  by = gem_id]
pre_emp[, tourism_intensity := fifelse(tert_share > 0.7, "high",
                                        fifelse(tert_share > 0.5, "medium", "low"))]
panel <- merge(panel, pre_emp[, .(gem_id, tourism_intensity)],
               by = "gem_id", all.x = TRUE)
panel[is.na(tourism_intensity), tourism_intensity := "low"]

# Language region
german_cantons <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20)
panel[, german_speaking := as.integer(canton_id %in% german_cantons)]

# ==============================================================================
# 7. Compute pre-treatment trends
# ==============================================================================

cat("Computing pre-treatment trends...\n")

trends <- panel[, .(mean_vacancy = mean(vacancy_rate, na.rm = TRUE),
                     mean_pop = mean(population, na.rm = TRUE),
                     n_munis = .N),
                 by = .(year, treated)]
fwrite(trends, "../data/trends_by_treatment.csv")

# ==============================================================================
# 8. Save analysis panel
# ==============================================================================

cat("\nSaving analysis panel...\n")
fwrite(panel, "../data/panel.csv")

# ==============================================================================
# 9. Validation
# ==============================================================================

cat("\n=== DATA VALIDATION ===\n")

n_munis <- uniqueN(panel$gem_id)
n_years <- uniqueN(panel$year)
n_treated <- uniqueN(panel[treated == 1]$gem_id)
n_control <- uniqueN(panel[treated == 0]$gem_id)
year_range <- range(panel$year)

stopifnot("Expected 100+ municipalities" = n_munis >= 100)
stopifnot("Expected treated municipalities" = n_treated >= 50)
stopifnot("Expected control municipalities" = n_control >= 100)
stopifnot("Expected multiple years" = n_years >= 10)
stopifnot("Expected pre-treatment data" = min(panel$year) <= 2010)
stopifnot("Expected post-treatment data" = max(panel$year) >= 2015)

cat(sprintf("Panel: %d municipalities x %d years = %d rows\n",
            n_munis, n_years, nrow(panel)))
cat(sprintf("  Treated: %d municipalities\n", n_treated))
cat(sprintf("  Control: %d municipalities\n", n_control))
cat(sprintf("  Years: %d-%d\n", year_range[1], year_range[2]))
cat(sprintf("  Vacancy rate: mean=%.2f%%, SD=%.2f%%\n",
            mean(panel$vacancy_rate, na.rm = TRUE),
            sd(panel$vacancy_rate, na.rm = TRUE)))
cat("Data validation PASSED.\n")
