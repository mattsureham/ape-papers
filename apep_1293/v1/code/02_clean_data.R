## ==============================================================
## 02_clean_data.R — apep_1293
## Merge homicide panel, population, and shooting club data
## ==============================================================

source("code/00_packages.R")

## ------------------------------------------------------------------
## 1. Load raw data
## ------------------------------------------------------------------

cat("=== Loading raw data ===\n")

# Homicide panel (from BigQuery, 2013-2022)
hom <- fread("data/homicide_panel_bq.csv")
cat(sprintf("Homicide panel: %d rows\n", nrow(hom)))

# Population
pop <- fread("data/population_municipality.csv")
cat(sprintf("Population: %d rows\n", nrow(pop)))

# Shooting clubs
clubs <- fread("data/shooting_clubs_panel.csv")
cat(sprintf("Shooting clubs panel: %d rows\n", nrow(clubs)))

## ------------------------------------------------------------------
## 2. Add 2023 DATASUS data if available
## ------------------------------------------------------------------

sim_2023_files <- list.files("data/sim_raw", pattern = "DO.*2023\\.dbc$",
                              full.names = TRUE)

if (length(sim_2023_files) > 0) {
  cat(sprintf("\nProcessing %d 2023 SIM files...\n", length(sim_2023_files)))

  sim_2023_list <- list()
  for (f in sim_2023_files) {
    tryCatch({
      df <- read.dbc::read.dbc(f)
      dt <- as.data.table(df)
      keep_cols <- intersect(names(dt), c("CODMUNOCOR", "CAUSABAS"))
      dt <- dt[, ..keep_cols]
      sim_2023_list[[f]] <- dt
    }, error = function(e) {
      cat(sprintf("  Error reading %s: %s\n", basename(f), e$message))
    })
  }

  if (length(sim_2023_list) > 0) {
    sim_2023 <- rbindlist(sim_2023_list, fill = TRUE)

    # Classify causes
    sim_2023[, icd3 := substr(CAUSABAS, 1, 3)]
    sim_2023[, cause_group := fcase(
      grepl("^X9[345]", icd3), "firearm_homicide",
      grepl("^(X8[5-9]|X9[0-2]|X9[6-9]|Y0[0-9])", icd3), "nonfirearm_homicide",
      default = NA_character_
    )]

    sim_2023_hom <- sim_2023[!is.na(cause_group)]
    sim_2023_hom[, mun_code := substr(CODMUNOCOR, 1, 6)]

    hom_2023 <- sim_2023_hom[, .(deaths = .N),
                              by = .(mun_code, cause_group)]
    hom_2023[, year := 2023L]

    cat(sprintf("2023 homicide records: %d\n", sum(hom_2023$deaths)))
    cat(sprintf("  Firearm: %d  Non-firearm: %d\n",
                sum(hom_2023[cause_group == "firearm_homicide"]$deaths),
                sum(hom_2023[cause_group == "nonfirearm_homicide"]$deaths)))

    hom <- rbind(hom, hom_2023[, .(year, mun_code, cause_group, deaths)])
  }
}

## ------------------------------------------------------------------
## 3. Build balanced panel
## ------------------------------------------------------------------

cat("\n=== Building balanced panel ===\n")

# Ensure consistent types — truncate to 6-digit IBGE codes
# (DATASUS uses 6-digit, BigQuery id_municipio uses 7-digit)
hom[, mun_code := substr(as.character(mun_code), 1, 6)]
pop[, mun_code := substr(as.character(mun_code), 1, 6)]
clubs[, mun_code := substr(as.character(mun_code), 1, 6)]

# Remove NA municipality codes
hom <- hom[!is.na(mun_code) & mun_code != "NA"]
pop <- pop[!is.na(mun_code) & mun_code != "NA"]

# All municipality-year-cause combinations
all_muns <- sort(unique(pop$mun_code))
all_years <- sort(unique(hom$year))
causes <- c("firearm_homicide", "nonfirearm_homicide")

# Create balanced grid
grid <- CJ(mun_code = all_muns, year = all_years, cause_group = causes)
cat(sprintf("Balanced grid: %d rows (%d munis × %d years × %d causes)\n",
            nrow(grid), length(all_muns), length(all_years), length(causes)))

# Merge homicides (fill zeros for municipality-years with no homicides)
panel <- merge(grid, hom, by = c("mun_code", "year", "cause_group"), all.x = TRUE)
panel[is.na(deaths), deaths := 0L]

# Merge population
panel <- merge(panel, pop, by = c("mun_code", "year"), all.x = TRUE)

# Drop municipalities without population data
panel <- panel[!is.na(population) & population > 0]
cat(sprintf("Panel after population merge: %d rows\n", nrow(panel)))

# Compute homicide rate per 100K
panel[, rate := deaths / population * 100000]

## ------------------------------------------------------------------
## 4. Treatment intensity: shooting club density
## ------------------------------------------------------------------

cat("\n=== Computing treatment intensity ===\n")

# Pre-treatment (2018) club density as treatment intensity
clubs_2018 <- clubs[year == 2018, .(clubs_2018 = sum(active_clubs)),
                     by = mun_code]

# Merge club density
panel <- merge(panel, clubs_2018, by = "mun_code", all.x = TRUE)
panel[is.na(clubs_2018), clubs_2018 := 0L]

# Club density per 100K (using 2018 population)
pop_2018 <- pop[year == 2018, .(pop_2018 = population), by = mun_code]
panel <- merge(panel, pop_2018, by = "mun_code", all.x = TRUE)
panel[, club_density := clubs_2018 / pop_2018 * 100000]
panel[is.na(club_density), club_density := 0]

# Binary treatment: any club in 2018
panel[, has_club := as.integer(clubs_2018 > 0)]

# Treatment intensity categories
panel[, club_tercile := fcase(
  club_density == 0, "none",
  club_density <= quantile(club_density[club_density > 0], 0.5, na.rm = TRUE), "low",
  default = "high"
)]

## ------------------------------------------------------------------
## 5. Policy period indicators
## ------------------------------------------------------------------

panel[, post_2019 := as.integer(year >= 2019)]
panel[, post_2023 := as.integer(year >= 2023)]

# Interaction terms
panel[, post2019_clubs := post_2019 * club_density]
panel[, post2023_clubs := post_2023 * club_density]
panel[, post2019_hasclub := post_2019 * has_club]
panel[, post2023_hasclub := post_2023 * has_club]

# Firearm indicator for DDD
panel[, firearm := as.integer(cause_group == "firearm_homicide")]

## ------------------------------------------------------------------
## 6. Summary statistics
## ------------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")

cat(sprintf("Municipalities: %d\n", uniqueN(panel$mun_code)))
cat(sprintf("Years: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("Municipality-year-cause obs: %d\n", nrow(panel)))

# Club distribution
cat(sprintf("\nTreatment distribution:\n"))
cat(sprintf("  Municipalities with clubs in 2018: %d\n",
            uniqueN(panel[clubs_2018 > 0]$mun_code)))
cat(sprintf("  Municipalities without clubs: %d\n",
            uniqueN(panel[clubs_2018 == 0]$mun_code)))

# Average homicide rates
cat(sprintf("\nFirearm homicide rate (per 100K):\n"))
cat(sprintf("  Pre-2019 (2013-2018): %.2f\n",
            panel[firearm == 1 & year < 2019, weighted.mean(rate, population)]))
cat(sprintf("  Post-2019 (2019-2022): %.2f\n",
            panel[firearm == 1 & year >= 2019 & year < 2023,
                  weighted.mean(rate, population)]))
if (2023 %in% panel$year) {
  cat(sprintf("  Post-2023 (2023): %.2f\n",
              panel[firearm == 1 & year >= 2023, weighted.mean(rate, population)]))
}

## ------------------------------------------------------------------
## 7. Save analysis-ready panel
## ------------------------------------------------------------------

fwrite(panel, "data/analysis_panel.csv")
cat(sprintf("\nSaved analysis panel: %d rows to data/analysis_panel.csv\n", nrow(panel)))

# Save diagnostics
n_treated <- uniqueN(panel[clubs_2018 > 0]$mun_code)
n_pre <- length(unique(panel[year < 2019]$year))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE,
                      pretty = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
