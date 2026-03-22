## =============================================================================
## 02_clean_data.R — Clean ICFES data and construct analysis variables
## Paper: Estrato Boundaries and Educational Sorting in Colombia (apep_0755)
## =============================================================================

source("00_packages.R")

cat("=== Cleaning ICFES data ===\n")

## Load raw data
df <- fread("../data/icfes_raw.csv")
cat(sprintf("Raw data: %s rows\n", format(nrow(df), big.mark = ",")))

## -----------------------------------------------------------------------------
## 1. Parse estrato (running variable)
## Values: "Estrato 1" through "Estrato 6", plus "Sin Estrato"
## -----------------------------------------------------------------------------
df[, estrato := as.integer(gsub("Estrato ", "", fami_estratovivienda))]
cat("\nEstrato parsing:\n")
print(table(df$estrato, df$fami_estratovivienda, useNA = "always"))

## Drop observations without a valid estrato (1-6)
n_before <- nrow(df)
df <- df[estrato %in% 1:6]
cat(sprintf("\nDropped %s obs without valid estrato (1-6)\n",
            format(n_before - nrow(df), big.mark = ",")))

## -----------------------------------------------------------------------------
## 2. Clean test scores (convert to numeric)
## -----------------------------------------------------------------------------
score_vars <- c("punt_global", "punt_matematicas", "punt_lectura_critica",
                "punt_ingles", "punt_c_naturales", "punt_sociales_ciudadanas")

for (v in score_vars) {
  if (v %in% names(df)) {
    df[[v]] <- as.numeric(df[[v]])
  }
}

## Drop observations with missing global score
n_before <- nrow(df)
df <- df[!is.na(punt_global)]
cat(sprintf("Dropped %s obs with missing punt_global\n",
            format(n_before - nrow(df), big.mark = ",")))

## -----------------------------------------------------------------------------
## 3. Standardize municipality names
## Merge BOGOTÁ D.C. and BOGOTÁ, D.C.; MEDELLÍN and MEDELLIN
## -----------------------------------------------------------------------------
df[cole_mcpio_ubicacion %in% c("BOGOTÁ D.C.", "BOGOTÁ, D.C."),
   cole_mcpio_ubicacion := "BOGOTA"]
df[cole_mcpio_ubicacion %in% c("MEDELLÍN", "MEDELLIN"),
   cole_mcpio_ubicacion := "MEDELLIN"]
df[cole_mcpio_ubicacion == "CARTAGENA DE INDIAS",
   cole_mcpio_ubicacion := "CARTAGENA"]

cat("\nStandardized municipality distribution:\n")
print(table(df$cole_mcpio_ubicacion))

## -----------------------------------------------------------------------------
## 4. Parse year from periodo
## periodo format: YYYYS where S = semester (1 or 2 or 4)
## Use the main exam period (semester 2/4) for each year
## -----------------------------------------------------------------------------
df[, year := as.integer(substr(periodo, 1, 4))]
df[, semester := as.integer(substr(periodo, 5, 5))]

cat("\nYear-semester distribution:\n")
print(table(df$year, df$semester))

## Focus on main exam periods (semester 2 or 4 — the standard exam)
## Semester 1 is small makeup/special sessions
n_before <- nrow(df)
df <- df[semester %in% c(2, 4)]
cat(sprintf("\nKept main exam periods only: dropped %s obs\n",
            format(n_before - nrow(df), big.mark = ",")))

## -----------------------------------------------------------------------------
## 5. Create household asset index
## Binary indicators from family variables
## -----------------------------------------------------------------------------
df[, has_internet  := as.integer(fami_tieneinternet == "Si")]
df[, has_computer  := as.integer(fami_tienecomputador == "Si")]
df[, has_washer    := as.integer(fami_tienelavadora == "Si")]
df[, has_car       := as.integer(fami_tieneautomovil == "Si")]
df[, asset_index   := has_internet + has_computer + has_washer + has_car]

## Parental education ordinal variable
educ_levels <- c(
  "Ninguno" = 0,
  "Primaria incompleta" = 1,
  "Primaria completa" = 2,
  "Secundaria (Bachillerato) incompleta" = 3,
  "Secundaria (Bachillerato) completa" = 4,
  "Técnica o tecnológica incompleta" = 5,
  "Técnica o tecnológica completa" = 6,
  "Educación profesional incompleta" = 7,
  "Educación profesional completa" = 8,
  "Postgrado" = 9
)

df[, mother_educ := educ_levels[fami_educacionmadre]]
df[, father_educ := educ_levels[fami_educacionpadre]]
df[, max_parent_educ := pmax(mother_educ, father_educ, na.rm = TRUE)]

## Female indicator
df[, female := as.integer(estu_genero == "F")]

## Official (public) school indicator
df[, official := as.integer(cole_naturaleza == "OFICIAL")]

## Bilingual school indicator
df[, bilingual := as.integer(cole_bilingue == "S")]

## -----------------------------------------------------------------------------
## 6. Create school-level aggregates
## Key unit for boundary analysis
## -----------------------------------------------------------------------------
school_df <- df[, .(
  mean_global    = mean(punt_global, na.rm = TRUE),
  mean_math      = mean(punt_matematicas, na.rm = TRUE),
  mean_reading   = mean(punt_lectura_critica, na.rm = TRUE),
  sd_global      = sd(punt_global, na.rm = TRUE),
  n_students     = .N,
  mean_estrato   = mean(estrato, na.rm = TRUE),
  modal_estrato  = as.integer(names(sort(table(estrato), decreasing = TRUE))[1]),
  pct_estrato_1  = mean(estrato == 1, na.rm = TRUE),
  pct_estrato_2  = mean(estrato == 2, na.rm = TRUE),
  pct_estrato_3  = mean(estrato == 3, na.rm = TRUE),
  pct_estrato_4  = mean(estrato == 4, na.rm = TRUE),
  pct_estrato_5  = mean(estrato == 5, na.rm = TRUE),
  pct_estrato_6  = mean(estrato == 6, na.rm = TRUE),
  mean_asset     = mean(asset_index, na.rm = TRUE),
  pct_internet   = mean(has_internet, na.rm = TRUE),
  pct_computer   = mean(has_computer, na.rm = TRUE),
  pct_female     = mean(female, na.rm = TRUE),
  mean_parent_ed = mean(max_parent_educ, na.rm = TRUE),
  is_official    = first(official),
  is_bilingual   = first(bilingual),
  municipality   = first(cole_mcpio_ubicacion)
), by = .(cole_cod_dane_establecimiento, year)]

cat(sprintf("\nSchool-year observations: %s\n",
            format(nrow(school_df), big.mark = ",")))
cat(sprintf("Unique schools: %s\n",
            format(length(unique(school_df$cole_cod_dane_establecimiento)), big.mark = ",")))

## -----------------------------------------------------------------------------
## 7. Identify boundary schools
## A "boundary school" draws students from adjacent estratos
## Key: schools where the modal estrato differs from a substantial
## minority of students
## -----------------------------------------------------------------------------

## For each school-year, compute estrato concentration
## (Herfindahl index of estrato shares)
school_df[, estrato_hhi := pct_estrato_1^2 + pct_estrato_2^2 +
            pct_estrato_3^2 + pct_estrato_4^2 +
            pct_estrato_5^2 + pct_estrato_6^2]

## Boundary school: HHI < 0.5 (draws from multiple estratos meaningfully)
school_df[, boundary_school := estrato_hhi < 0.5]
cat(sprintf("\nBoundary schools (HHI < 0.5): %s of %s (%.1f%%)\n",
            format(sum(school_df$boundary_school), big.mark = ","),
            format(nrow(school_df), big.mark = ","),
            100 * mean(school_df$boundary_school)))

## Summary statistics by estrato
cat("\n=== Summary statistics by student estrato ===\n")
summary_by_estrato <- df[, .(
  n = .N,
  mean_global = mean(punt_global, na.rm = TRUE),
  sd_global   = sd(punt_global, na.rm = TRUE),
  mean_math   = mean(punt_matematicas, na.rm = TRUE),
  pct_internet = mean(has_internet, na.rm = TRUE),
  mean_parent_ed = mean(max_parent_educ, na.rm = TRUE),
  pct_official = mean(official, na.rm = TRUE)
), by = estrato][order(estrato)]
print(summary_by_estrato)

## Save cleaned data
fwrite(df, "../data/icfes_clean.csv")
fwrite(school_df, "../data/school_panel.csv")
cat(sprintf("\nSaved: icfes_clean.csv (%s rows), school_panel.csv (%s rows)\n",
            format(nrow(df), big.mark = ","),
            format(nrow(school_df), big.mark = ",")))
