## =============================================================================
## 02_clean_data.R — Clean and merge all data sources
## apep_0571: Voting reform and public safety in Chile
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## ===========================================================================
## Helper: standardize comuna names
## ===========================================================================
clean_comuna <- function(x) {
  x <- toupper(trimws(x))
  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x <- stringr::str_replace_all(x, "\\s+", " ")
  x
}

# Install stringi if needed
if (!requireNamespace("stringi", quietly = TRUE)) {
  install.packages("stringi", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(stringi)

## ===========================================================================
## 1. SERVEL ELECTORAL DATA — construct treatment variable
## ===========================================================================
cat("=== Processing SERVEL electoral data ===\n")

servel_08 <- haven::read_dta(file.path(data_dir, "servel_participation.dta"))
turnout_08 <- servel_08 %>%
  group_by(comuna) %>%
  summarise(
    turnout_2008 = mean(part_08, na.rm = TRUE),
    tipologia = first(tipologia),
    .groups = "drop"
  )

base_2012 <- haven::read_dta(file.path(data_dir, "base_cox_gonzalez.tab"))
turnout_12 <- base_2012 %>%
  group_by(comuna) %>%
  summarise(
    voters_2012 = sum(v_total, na.rm = TRUE),
    nonvoters_2012 = sum(nv_total, na.rm = TRUE),
    padron_2012 = sum(totalpadron, na.rm = TRUE),
    young_voters = sum(v_rango1819 + v_rango2024 + v_rango2529, na.rm = TRUE),
    young_nonvoters = sum(nv_rango1819 + nv_rango2024 + nv_rango2529, na.rm = TRUE),
    old_voters = sum(v_rango6064 + v_rango6569 + v_rango7074 + v_rango7579 + v_rango80, na.rm = TRUE),
    old_nonvoters = sum(nv_rango6064 + nv_rango6569 + nv_rango7074 + nv_rango7579 + nv_rango80, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    turnout_2012 = voters_2012 / padron_2012,
    young_share = (young_voters + young_nonvoters) / padron_2012,
    young_turnout = young_voters / pmax(young_voters + young_nonvoters, 1),
    old_turnout = old_voters / pmax(old_voters + old_nonvoters, 1)
  )

turnout_08$comuna_clean <- clean_comuna(turnout_08$comuna)
turnout_12$comuna_clean <- clean_comuna(turnout_12$comuna)

turnout <- turnout_08 %>%
  inner_join(turnout_12, by = "comuna_clean", suffix = c("_08", "_12")) %>%
  mutate(
    turnout_decline = turnout_2008 - turnout_2012,
    turnout_decline_pct = turnout_decline * 100
  )
cat("  Turnout: ", nrow(turnout), " comunas, decline mean=",
    round(mean(turnout$turnout_decline_pct), 1), "pp\n")

## ===========================================================================
## 2. DMCS CRIME DATA 2010-2012 (from pre-parsed CSV)
## ===========================================================================
cat("\n=== Processing DMCS 2010-2012 ===\n")
dmcs <- fread(file.path(data_dir, "dmcs_2010_2012_clean.csv"))
cat("  Raw:", nrow(dmcs), "rows\n")

# Classify crimes and create aggregate categories
dmcs <- dmcs %>%
  mutate(
    homicide = Homicidio,
    violent_robbery = Robo_Intimidacion + Robo_Violencia + Robo_Sorpresa,
    vehicle_theft = Robo_Vehiculo_Motorizado + Robo_Accesorio_Vehiculo,
    burglary = Robo_Lugar_Habitado + Robo_Lugar_No_Habitado + Otros_Robos_Fuerza,
    theft = Hurto,
    assault = Lesiones,
    sexual_offense = Violacion,
    domestic_violence = VIF,
    drugs = Ley_Drogas,
    # Aggregate categories
    discretionary_crime = violent_robbery + vehicle_theft + burglary + theft + drugs,
    nondiscretionary_crime = homicide + domestic_violence + sexual_offense + assault,
    total_crime = discretionary_crime + nondiscretionary_crime
  )

# Aggregate monthly → annual
dmcs_annual <- dmcs %>%
  group_by(comuna, year) %>%
  summarise(
    across(c(total_crime, discretionary_crime, nondiscretionary_crime,
             homicide, violent_robbery, burglary, theft, vehicle_theft,
             domestic_violence, drugs, assault, sexual_offense),
           sum, na.rm = TRUE),
    .groups = "drop"
  )
dmcs_annual$comuna_clean <- clean_comuna(dmcs_annual$comuna)
cat("  DMCS annual:", nrow(dmcs_annual), "obs,", n_distinct(dmcs_annual$comuna), "comunas\n")

## ===========================================================================
## 3. CEAD CRIME DATA 2018-2024
## ===========================================================================
cat("\n=== Processing CEAD 2018-2024 ===\n")
cead <- arrow::read_parquet(file.path(data_dir, "cead_2018_2025.parquet"))

cead <- cead %>%
  mutate(
    crime_category = case_when(
      delito %in% c("Homicidios", "Femicidios") ~ "homicide",
      delito %in% c("Violaciones") ~ "sexual_offense",
      delito %in% c("Robos con violencia o intimidaci\u00f3n", "Robo por sorpresa") ~ "violent_robbery",
      delito %in% c("Robo de veh\u00edculo motorizado",
                     "Robo violento de veh\u00edculo motorizado",
                     "Robo de objetos de o desde veh\u00edculo") ~ "vehicle_theft",
      delito %in% c("Robo en lugar habitado", "Robos en lugar no habitado",
                     "Otros robos con fuerza en las cosas", "Robo frustrado") ~ "burglary",
      delito == "Hurtos" ~ "theft",
      delito %in% c("Lesiones graves o grav\u00edsimas", "Lesiones menos graves",
                     "Lesiones leves") ~ "assault",
      delito == "Violencia intrafamiliar" ~ "domestic_violence",
      delito == "Delitos asociados a drogas" ~ "drugs",
      TRUE ~ "other"
    ),
    police_discretionary = crime_category %in%
      c("violent_robbery", "vehicle_theft", "burglary", "theft", "drugs"),
    year = lubridate::year(fecha)
  )

cead_annual <- cead %>%
  filter(year >= 2018, year <= 2024) %>%
  group_by(comuna, year) %>%
  summarise(
    total_crime = sum(delito_n, na.rm = TRUE),
    discretionary_crime = sum(delito_n[police_discretionary], na.rm = TRUE),
    nondiscretionary_crime = sum(delito_n[!police_discretionary], na.rm = TRUE),
    homicide = sum(delito_n[crime_category == "homicide"], na.rm = TRUE),
    violent_robbery = sum(delito_n[crime_category == "violent_robbery"], na.rm = TRUE),
    burglary = sum(delito_n[crime_category == "burglary"], na.rm = TRUE),
    theft = sum(delito_n[crime_category == "theft"], na.rm = TRUE),
    vehicle_theft = sum(delito_n[crime_category == "vehicle_theft"], na.rm = TRUE),
    domestic_violence = sum(delito_n[crime_category == "domestic_violence"], na.rm = TRUE),
    drugs = sum(delito_n[crime_category == "drugs"], na.rm = TRUE),
    assault = sum(delito_n[crime_category == "assault"], na.rm = TRUE),
    sexual_offense = sum(delito_n[crime_category == "sexual_offense"], na.rm = TRUE),
    .groups = "drop"
  )
cead_annual$comuna_clean <- clean_comuna(cead_annual$comuna)
cat("  CEAD annual:", nrow(cead_annual), "obs,", n_distinct(cead_annual$comuna), "comunas\n")

## ===========================================================================
## 4. COMBINE CRIME PANELS & MERGE TREATMENT
## ===========================================================================
cat("\n=== Building analysis panel ===\n")

common_cols <- c("comuna_clean", "year", "total_crime", "discretionary_crime",
                 "nondiscretionary_crime", "homicide", "violent_robbery",
                 "burglary", "theft", "vehicle_theft", "domestic_violence",
                 "drugs", "assault", "sexual_offense")

crime_panel <- bind_rows(
  dmcs_annual %>% select(all_of(common_cols)) %>% mutate(source = "DMCS"),
  cead_annual %>% select(all_of(common_cols)) %>% mutate(source = "CEAD")
) %>%
  mutate(
    post = as.integer(year >= 2013),
    period = case_when(
      year <= 2011 ~ "pre",
      year == 2012 ~ "reform_year",
      TRUE ~ "post"
    )
  )

# Merge with turnout treatment
panel <- crime_panel %>%
  inner_join(
    turnout %>% select(comuna_clean, turnout_2008, turnout_2012,
                        turnout_decline, turnout_decline_pct, tipologia,
                        padron_2012, young_turnout, old_turnout),
    by = "comuna_clean"
  )

cat("  Panel:", nrow(panel), "obs,", n_distinct(panel$comuna_clean), "comunas\n")
cat("  Years:", paste(sort(unique(panel$year)), collapse=", "), "\n")

# Crime rates per 1000 registered voters (using padron_2012 as denominator)
panel <- panel %>%
  mutate(
    pop = padron_2012 / 1000,
    total_rate = total_crime / pop,
    discretionary_rate = discretionary_crime / pop,
    nondiscretionary_rate = nondiscretionary_crime / pop,
    homicide_rate = homicide / pop,
    robbery_rate = violent_robbery / pop,
    burglary_rate = burglary / pop,
    theft_rate = theft / pop,
    drugs_rate = drugs / pop,
    dv_rate = domestic_violence / pop,
    # Log versions
    ln_total = log(total_crime + 1),
    ln_discretionary = log(discretionary_crime + 1),
    ln_nondiscretionary = log(nondiscretionary_crime + 1),
    ln_robbery = log(violent_robbery + 1),
    ln_burglary = log(burglary + 1),
    ln_drugs = log(drugs + 1),
    ln_dv = log(domestic_violence + 1),
    ln_homicide = log(homicide + 1),
    # Standardized treatment
    turnout_decline_std = (turnout_decline - mean(turnout_decline)) / sd(turnout_decline),
    # Tercile indicators for heterogeneity
    decline_tercile = ntile(turnout_decline, 3)
  )

# Drop reform year
panel_clean <- panel %>% filter(year != 2012)

cat("  Clean panel:", nrow(panel_clean), "obs (excl. 2012)\n")

## ===========================================================================
## 5. SUMMARY STATISTICS
## ===========================================================================
cat("\n=== Summary Statistics ===\n")

# Pre vs post comparison
for (p in c("pre", "post")) {
  sub <- panel_clean %>% filter(period == p)
  cat(sprintf("\n  %s period (%s):\n", toupper(p),
              paste(sort(unique(sub$year)), collapse=",")))
  cat(sprintf("    N = %d obs, %d comunas\n", nrow(sub), n_distinct(sub$comuna_clean)))
  cat(sprintf("    Total crime: mean=%.0f, sd=%.0f\n",
              mean(sub$total_crime), sd(sub$total_crime)))
  cat(sprintf("    Discretionary: mean=%.0f, sd=%.0f\n",
              mean(sub$discretionary_crime), sd(sub$discretionary_crime)))
  cat(sprintf("    Non-discretionary: mean=%.0f, sd=%.0f\n",
              mean(sub$nondiscretionary_crime), sd(sub$nondiscretionary_crime)))
}

# Treatment variable
cat("\n  Treatment (turnout decline, pp):\n")
cat(sprintf("    mean=%.1f, sd=%.1f, min=%.1f, max=%.1f\n",
            mean(turnout$turnout_decline_pct), sd(turnout$turnout_decline_pct),
            min(turnout$turnout_decline_pct), max(turnout$turnout_decline_pct)))

## ===========================================================================
## SAVE
## ===========================================================================
fwrite(panel_clean, file.path(data_dir, "analysis_panel.csv"))
fwrite(panel, file.path(data_dir, "analysis_panel_full.csv"))
fwrite(turnout, file.path(data_dir, "turnout_merged.csv"))

# Save summary stats for LaTeX tables
sumstat_vars <- panel_clean %>%
  summarise(
    across(c(total_crime, discretionary_crime, nondiscretionary_crime,
             homicide, violent_robbery, burglary, theft, drugs,
             domestic_violence, assault, turnout_decline_pct, padron_2012),
           list(mean = ~mean(., na.rm=TRUE),
                sd = ~sd(., na.rm=TRUE),
                min = ~min(., na.rm=TRUE),
                max = ~max(., na.rm=TRUE)),
           .names = "{.col}_{.fn}")
  )
fwrite(sumstat_vars, file.path(data_dir, "summary_stats.csv"))

cat("\n=== Data cleaning complete ===\n")

# === DATA VALIDATION ===
stopifnot("300+ comunas" = n_distinct(panel_clean$comuna_clean) >= 300)
stopifnot("Pre and post" = all(c("pre", "post") %in% panel_clean$period))
stopifnot("Treatment variation" = sd(panel_clean$turnout_decline) > 0.01)
cat("Validation passed:", nrow(panel_clean), "rows,",
    n_distinct(panel_clean$comuna_clean), "comunas,",
    length(unique(panel_clean$year)), "years\n")
