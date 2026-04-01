## 02_clean_data.R — Clean and construct analysis dataset
## APEP Paper: Mexico's Sorteo Militar and Youth Crime
##
## Strategy: Merge individual demographics (TPer_Vic1) with crime incidents
## (TMod_Vic) to create person-level victimization indicators by age, sex,
## state, year.

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load ENVIPE data across all years
# ============================================================
cat("=== Loading ENVIPE data across 2021-2024 ===\n")

# File path patterns differ between years (case sensitivity, naming)
find_envipe_file <- function(year, table_prefix) {
  base_dir <- file.path(data_dir, "envipe", as.character(year))
  # Search for the data file recursively
  pattern <- paste0("conjunto_de_datos_", table_prefix, ".*", year)
  files <- list.files(base_dir, pattern = pattern, recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
  # Filter to actual data files (not dictionary/catalog)
  data_files <- files[grepl("conjunto_de_datos/conjunto_de_datos", files)]
  if (length(data_files) == 0) {
    stop("Cannot find ", table_prefix, " data file for year ", year)
  }
  return(data_files[1])
}

# Load all years
all_persons <- list()
all_incidents <- list()

for (yr in 2021:2024) {
  cat("Processing ENVIPE", yr, "...\n")

  # Load person-level data (TPer_Vic1 = all selected persons 18+)
  pv1_file <- find_envipe_file(yr, "tper_vic1")
  pv1 <- fread(pv1_file, select = c("ID_PER", "SEXO", "EDAD",
                                      "CVE_ENT", "NOM_ENT",
                                      "FAC_HOG", "FAC_ELE",
                                      "EST_DIS", "UPM_DIS"))
  pv1[, survey_year := yr]
  cat("  Persons:", nrow(pv1), "\n")

  # Load crime incidents (TMod_Vic)
  vic_file <- find_envipe_file(yr, "tmod_vic")
  vic <- fread(vic_file, select = c("ID_PER", "BPCOD", "SEXO", "EDAD",
                                     "BP1_1", "BP1_4",
                                     "FAC_DEL", "EST_DIS", "UPM_DIS"))
  vic[, survey_year := yr]
  cat("  Crime incidents:", nrow(vic), "\n")

  all_persons[[as.character(yr)]] <- pv1
  all_incidents[[as.character(yr)]] <- vic
}

persons <- rbindlist(all_persons, fill = TRUE)
incidents <- rbindlist(all_incidents, fill = TRUE)

cat("\n=== Combined totals ===\n")
cat("Total persons:", nrow(persons), "\n")
cat("Total crime incidents:", nrow(incidents), "\n")

# ============================================================
# 2. Construct person-level victimization indicators
# ============================================================
cat("\n=== Constructing victimization variables ===\n")

# Count crimes per person-year
person_crimes <- incidents[, .(
  n_crimes = .N,
  n_violent = sum(BPCOD %in% c(5, 11, 12, 13, 14)),  # robbery, assault, kidnap, sexual
  n_property = sum(BPCOD %in% c(1, 2, 3, 4, 6)),     # vehicle, vandalism, burglary
  n_fraud = sum(BPCOD %in% c(7, 8)),                  # bank/consumer fraud
  n_extortion = sum(BPCOD == 9),                       # extortion
  n_threats = sum(BPCOD == 10)                          # threats
), by = .(ID_PER, survey_year)]

# Merge with all persons
df <- merge(persons, person_crimes,
            by = c("ID_PER", "survey_year"), all.x = TRUE)

# Fill non-victims with zeros
crime_vars <- c("n_crimes", "n_violent", "n_property",
                "n_fraud", "n_extortion", "n_threats")
for (v in crime_vars) {
  df[is.na(get(v)), (v) := 0]
}

# Binary victimization indicators
df[, victim := as.integer(n_crimes > 0)]
df[, victim_violent := as.integer(n_violent > 0)]
df[, victim_property := as.integer(n_property > 0)]

# ============================================================
# 3. Construct treatment variables
# ============================================================
cat("=== Constructing treatment variables ===\n")

# Male indicator
df[, male := as.integer(SEXO == 1)]

# Age groups relevant to the Sorteo Militar
# 18-19: Currently eligible for lottery (the treatment window)
# 20-21: Recently finished service (persistence test)
# 22-25: Further past service
# 26-35: Control (well past any lottery effect)
df[, age_group := fcase(
  EDAD >= 18 & EDAD <= 19, "18-19",
  EDAD >= 20 & EDAD <= 21, "20-21",
  EDAD >= 22 & EDAD <= 25, "22-25",
  EDAD >= 26 & EDAD <= 35, "26-35",
  EDAD >= 36 & EDAD <= 50, "36-50",
  EDAD > 50, "51+"
)]

# Lottery-eligible indicator (males 18-19)
df[, lottery_eligible := as.integer(male == 1 & EDAD >= 18 & EDAD <= 19)]

# Male × age interaction for the DiD
df[, male_18_19 := as.integer(male == 1 & EDAD >= 18 & EDAD <= 19)]
df[, age_18_19 := as.integer(EDAD >= 18 & EDAD <= 19)]

# State fixed effect
df[, state := as.integer(CVE_ENT)]

# ============================================================
# 4. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# Sample sizes by year
cat("\nPersons by year:\n")
print(df[, .N, by = survey_year][order(survey_year)])

# Victimization rates by sex and age group
cat("\nVictimization rate (any crime) by sex × age group:\n")
rate_table <- df[!is.na(age_group),
                  .(rate = round(mean(victim) * 100, 1),
                    n = .N),
                  by = .(male, age_group)]
print(dcast(rate_table, age_group ~ male, value.var = "rate"))

cat("\nViolent victimization rate by sex × age group:\n")
viol_table <- df[!is.na(age_group),
                  .(rate = round(mean(victim_violent) * 100, 1),
                    n = .N),
                  by = .(male, age_group)]
print(dcast(viol_table, age_group ~ male, value.var = "rate"))

# Key comparison: male-female gap at 18-19 vs other ages
cat("\n=== Key Comparison: Male-Female Victimization Gap ===\n")
gap_table <- df[!is.na(age_group) & age_group %in% c("18-19","20-21","22-25","26-35"),
                 .(rate = mean(victim) * 100),
                 by = .(male, age_group)]
gap_wide <- dcast(gap_table, age_group ~ male, value.var = "rate")
names(gap_wide) <- c("age_group", "female", "male")
gap_wide[, gap := male - female]
print(gap_wide)

# ============================================================
# 5. Save analysis dataset
# ============================================================
cat("\n=== Saving analysis dataset ===\n")

# Keep only relevant ages (18-50 for main analysis)
df_analysis <- df[EDAD >= 18 & EDAD <= 50]
cat("Analysis sample (ages 18-50):", nrow(df_analysis), "person-years\n")

fwrite(df_analysis, file.path(data_dir, "analysis_panel.csv"))
cat("Saved to:", file.path(data_dir, "analysis_panel.csv"), "\n")

# ============================================================
# 6. Also prepare SESNSP state-level data
# ============================================================
cat("\n=== Preparing SESNSP supplementary data ===\n")

sesnsp <- fread(file.path(data_dir, "sesnsp_victimas.csv"),
                encoding = "Latin-1")

# Check actual column names (encoding may vary)
cat("SESNSP columns:", paste(names(sesnsp)[1:9], collapse=", "), "\n")

# Standardize column names
setnames(sesnsp, 1:9, c("year", "state_code", "state", "bien_juridico",
                          "crime_type", "crime_subtype", "modality",
                          "sex", "age_group"))

month_cols <- names(sesnsp)[10:21]
cat("Month columns:", paste(month_cols, collapse=", "), "\n")

sesnsp_long <- melt(sesnsp,
                     id.vars = c("year", "state_code", "state",
                                 "crime_type", "crime_subtype",
                                 "sex", "age_group"),
                     measure.vars = month_cols,
                     variable.name = "month_name",
                     value.name = "count")

sesnsp_long[, month := seq_along(month_cols)[match(month_name, month_cols)]]
sesnsp_long[, count := as.numeric(count)]

# Filter to homicides (the hardest outcome)
sesnsp_homicide <- sesnsp_long[crime_type == "Homicidio"]

cat("SESNSP homicide records:", nrow(sesnsp_homicide), "\n")

# Aggregate to state-year-sex-age panel
sesnsp_panel <- sesnsp_homicide[, .(
  homicide_victims = sum(count, na.rm = TRUE)
), by = .(year, state_code, state, sex, age_group)]

fwrite(sesnsp_panel, file.path(data_dir, "sesnsp_homicide_panel.csv"))
cat("Saved SESNSP homicide panel\n")

# Summary
cat("\nSESNSP Homicide victims by sex and age:\n")
sesnsp_summary <- sesnsp_panel[, .(total = sum(homicide_victims)),
                                by = .(sex, age_group)][order(sex, age_group)]
print(sesnsp_summary)

cat("\nData cleaning complete.\n")
