# 02_clean_data.R — Construct analysis dataset for apep_0822
# Cohort × FeA intensity design using 2018 Census

setwd(file.path(dirname(sys.frame(1)$ofile %||% "."), "."))
source("00_packages.R")

data_dir <- "../data/"

# ===========================================================================
# 1. Load raw datasets
# ===========================================================================
cat("=== Loading datasets ===\n")
literacy   <- readRDS(file.path(data_dir, "census_literacy.rds"))
education  <- readRDS(file.path(data_dir, "census_education.rds"))
employment <- readRDS(file.path(data_dir, "census_employment.rds"))
pop_census <- readRDS(file.path(data_dir, "census_population.rds"))
services   <- readRDS(file.path(data_dir, "census_services.rds"))
housing    <- readRDS(file.path(data_dir, "census_housing.rds"))
stratum    <- readRDS(file.path(data_dir, "census_stratum.rds"))
households <- readRDS(file.path(data_dir, "census_households.rds"))
fea_muni   <- readRDS(file.path(data_dir, "fea_municipal.rds"))
divipola   <- readRDS(file.path(data_dir, "divipola.rds"))

# ===========================================================================
# 2. Construct municipality-level population
# ===========================================================================
cat("=== Constructing population variables ===\n")

# Total municipality population from census
muni_pop <- pop_census %>%
  filter(area == "total", sexo == "total", grupo_de_edad == "total") %>%
  mutate(
    muni_code = codigo_municipio,
    dept_code = codigo_departamento,
    total_pop = as.numeric(total)
  ) %>%
  select(muni_code, dept_code, departamento, municipio, total_pop)

cat("Municipalities with population data:", nrow(muni_pop), "\n")
cat("Population range:", range(muni_pop$total_pop), "\n")

# Urban share
urban_pop <- pop_census %>%
  filter(sexo == "total", grupo_de_edad == "total") %>%
  mutate(pop = as.numeric(total)) %>%
  select(codigo_municipio, area, pop) %>%
  pivot_wider(names_from = area, values_from = pop) %>%
  mutate(
    muni_code = codigo_municipio,
    urban_share = ifelse(!is.na(cabecera) & !is.na(total),
                         as.numeric(cabecera) / as.numeric(total), NA)
  ) %>%
  select(muni_code, urban_share)

# ===========================================================================
# 3. Construct literacy outcomes by cohort
# ===========================================================================
cat("\n=== Constructing literacy outcomes ===\n")

# Literacy rates by age group and municipality
lit_rates <- literacy %>%
  filter(area == "total", sexo == "total") %>%
  mutate(total = as.numeric(total)) %>%
  select(codigo_municipio, grupo_de_edad, sabe_leer_y_escribir, total) %>%
  pivot_wider(names_from = sabe_leer_y_escribir, values_from = total) %>%
  mutate(
    literate = as.numeric(si),
    total_n  = as.numeric(total),
    lit_rate = literate / total_n
  ) %>%
  select(codigo_municipio, grupo_de_edad, literate, total_n, lit_rate)

# Young cohort: ages 15-24 (born 1994-2003, FeA-exposed during childhood)
lit_young <- lit_rates %>%
  filter(grupo_de_edad == "entre_15_y_24_anos") %>%
  rename(
    muni_code = codigo_municipio,
    lit_young = lit_rate,
    n_young = total_n
  ) %>%
  select(muni_code, lit_young, n_young)

# Older cohort: ages 25+ (computed as 15+ minus 15-24)
lit_15plus <- lit_rates %>%
  filter(grupo_de_edad == "de_15_anos_y_mas") %>%
  rename(lit_15plus = lit_rate, n_15plus = total_n, literate_15plus = literate) %>%
  select(codigo_municipio, lit_15plus, n_15plus, literate_15plus)

lit_young_raw <- literacy %>%
  filter(area == "total", sexo == "total",
         grupo_de_edad == "entre_15_y_24_anos", sabe_leer_y_escribir == "si") %>%
  mutate(literate_young = as.numeric(total)) %>%
  select(codigo_municipio, literate_young)

lit_young_total <- literacy %>%
  filter(area == "total", sexo == "total",
         grupo_de_edad == "entre_15_y_24_anos", sabe_leer_y_escribir == "total") %>%
  mutate(n_young_tot = as.numeric(total)) %>%
  select(codigo_municipio, n_young_tot)

lit_old <- lit_15plus %>%
  left_join(lit_young_raw, by = "codigo_municipio") %>%
  left_join(lit_young_total, by = "codigo_municipio") %>%
  mutate(
    muni_code = codigo_municipio,
    literate_old = literate_15plus - literate_young,
    n_old = n_15plus - n_young_tot,
    lit_old = ifelse(n_old > 0, literate_old / n_old, NA)
  ) %>%
  select(muni_code, lit_old, n_old)

cat("Young cohort literacy range:", range(lit_young$lit_young, na.rm = TRUE), "\n")

# ===========================================================================
# 4. Construct education level shares
# ===========================================================================
cat("\n=== Constructing education shares ===\n")

edu_shares <- education %>%
  filter(area == "total", sexo == "total") %>%
  mutate(total = as.numeric(total)) %>%
  select(codigo_municipio, nivel_educativo, total) %>%
  pivot_wider(names_from = nivel_educativo, values_from = total, values_fill = 0)

# Clean column names
names(edu_shares) <- gsub("[^a-z0-9_]", "_", tolower(names(edu_shares)))

edu_muni <- edu_shares %>%
  mutate(
    muni_code = codigo_municipio,
    total_edu = as.numeric(total),
    share_none = as.numeric(ninguno) / total_edu,
    share_primary = (as.numeric(primaria_completa) + as.numeric(primaria_incompleta)) / total_edu,
    share_secondary = (as.numeric(secundaria_completa) + as.numeric(secundaria_incompleta) +
                       as.numeric(media_completa) + as.numeric(media_incompleta)) / total_edu,
    share_tertiary = (as.numeric(tecnico) + as.numeric(tecnologico) +
                      as.numeric(universitario) +
                      as.numeric(especializacion__maestria__doctorado)) / total_edu,
    share_secondary_plus = share_secondary + share_tertiary
  ) %>%
  select(muni_code, total_edu, share_none, share_primary, share_secondary,
         share_tertiary, share_secondary_plus)

cat("Education shares computed for", nrow(edu_muni), "municipalities\n")

# ===========================================================================
# 5. Construct employment outcomes
# ===========================================================================
cat("\n=== Constructing employment outcomes ===\n")

emp_wide <- employment %>%
  filter(area == "total", sexo == "total") %>%
  mutate(n = as.numeric(total)) %>%
  select(codigo_municipio, actividad_realizada_la_semana_anterior, n) %>%
  pivot_wider(names_from = actividad_realizada_la_semana_anterior,
              values_from = n, values_fill = 0)

emp_muni <- emp_wide %>%
  mutate(
    muni_code = codigo_municipio,
    total_working_age = total_personas_de_10_anos_y_mas,
    working = trabajo_por_lo_menos_una_hora_en_una_actividad_que_le_genero_algun_ingreso +
              trabajo_o_ayudo_en_un_negocio_por_lo_menos_una_hora_sin_que_le_pagaran +
              no_trabajo_pero_tenia_un_empleo_trabajo_o_negocio_por_el_que_recibe_ingresos,
    searching = busco_trabajo,
    studying = estudio,
    labor_force = working + searching,
    emp_rate = working / total_working_age,
    unemp_rate = ifelse(labor_force > 0, searching / labor_force, NA),
    study_rate = studying / total_working_age
  ) %>%
  select(muni_code, total_working_age, emp_rate, unemp_rate, study_rate)

cat("Employment rates computed for", nrow(emp_muni), "municipalities\n")

# ===========================================================================
# 6. Construct housing/services outcomes
# ===========================================================================
cat("\n=== Constructing housing and services outcomes ===\n")

# Public services: electricity, aqueduct, sewerage coverage
svc_muni <- services %>%
  filter(area == "total") %>%
  mutate(total = as.numeric(total)) %>%
  select(codigo_municipio, servicio_publico, disponible, total) %>%
  filter(disponible == "si") %>%
  select(codigo_municipio, servicio_publico, total) %>%
  pivot_wider(names_from = servicio_publico, values_from = total, values_fill = 0)

names(svc_muni) <- gsub("[^a-z0-9_]", "_", tolower(names(svc_muni)))
svc_muni <- svc_muni %>%
  rename(muni_code = codigo_municipio)

# Housing floor quality: share with dirt floors
floor_muni <- housing %>%
  filter(area == "total", tipo_de_vivienda == "total") %>%
  mutate(units = as.numeric(viviendas_ocupadas_con_personas_presentes)) %>%
  select(codigo_municipio, materiales_predominantes_de_los_pisos, units) %>%
  pivot_wider(names_from = materiales_predominantes_de_los_pisos,
              values_from = units, values_fill = 0)

names(floor_muni) <- gsub("[^a-z0-9_]", "_", tolower(names(floor_muni)))
floor_muni <- floor_muni %>%
  mutate(
    muni_code = codigo_municipio,
    total_housing = as.numeric(total),
    share_dirt_floor = ifelse(total_housing > 0,
                              as.numeric(tierra_arena_barro) / total_housing, NA)
  ) %>%
  select(muni_code, total_housing, share_dirt_floor)

# ===========================================================================
# 7. Construct FeA treatment intensity
# ===========================================================================
cat("\n=== Constructing FeA treatment intensity ===\n")

fea_treat <- fea_muni %>%
  mutate(
    muni_code = codigomunicipioatencion,
    fea_beneficiaries = as.numeric(total_beneficiaries)
  ) %>%
  select(muni_code, fea_beneficiaries)

# ===========================================================================
# 8. Female household headship
# ===========================================================================
hh_muni <- households %>%
  filter(area == "total") %>%
  mutate(total = as.numeric(total)) %>%
  select(codigo_municipio, condicion, total) %>%
  pivot_wider(names_from = condicion, values_from = total, values_fill = 0)

names(hh_muni) <- gsub("[^a-z0-9_]", "_", tolower(names(hh_muni)))
hh_muni <- hh_muni %>%
  mutate(
    muni_code = codigo_municipio,
    total_hh = as.numeric(hogares_con_jefes_hombre) + as.numeric(hogares_con_jefes_mujer),
    share_female_head = as.numeric(hogares_con_jefes_mujer) / total_hh
  ) %>%
  select(muni_code, total_hh, share_female_head)

# ===========================================================================
# 9. Merge all into analysis dataset
# ===========================================================================
cat("\n=== Merging analysis dataset ===\n")

analysis <- muni_pop %>%
  left_join(urban_pop, by = "muni_code") %>%
  left_join(lit_young, by = "muni_code") %>%
  left_join(lit_old, by = "muni_code") %>%
  left_join(edu_muni, by = "muni_code") %>%
  left_join(emp_muni, by = "muni_code") %>%
  left_join(floor_muni, by = "muni_code") %>%
  left_join(hh_muni, by = "muni_code") %>%
  left_join(fea_treat, by = "muni_code") %>%
  mutate(
    # FeA intensity = beneficiaries per capita
    fea_per_capita = fea_beneficiaries / total_pop,
    # Cohort literacy gap (young minus old)
    lit_cohort_gap = lit_young - lit_old,
    # Log population
    log_pop = log(total_pop),
    # Small municipality dummy (Phase 1 proxy)
    small_muni = as.integer(total_pop < 100000),
    # Department FE
    dept = as.factor(dept_code)
  )

cat("Analysis dataset:", nrow(analysis), "municipalities\n")
cat("With FeA data:", sum(!is.na(analysis$fea_per_capita)), "\n")
cat("With literacy data:", sum(!is.na(analysis$lit_young)), "\n")

# Drop municipalities with missing key variables
analysis_clean <- analysis %>%
  filter(
    !is.na(fea_per_capita),
    !is.na(lit_young),
    !is.na(lit_old),
    n_young > 50,  # minimum sample size
    n_old > 50
  )

cat("Clean sample:", nrow(analysis_clean), "municipalities\n")

# ===========================================================================
# 10. Summary statistics
# ===========================================================================
cat("\n=== Summary Statistics ===\n")

summ_vars <- analysis_clean %>%
  select(total_pop, urban_share, fea_per_capita, fea_beneficiaries,
         lit_young, lit_old, lit_cohort_gap,
         share_secondary_plus, share_tertiary,
         emp_rate, share_dirt_floor, share_female_head)

cat("\n")
for (v in names(summ_vars)) {
  x <- summ_vars[[v]]
  cat(sprintf("%-25s N=%5d  Mean=%8.4f  SD=%8.4f  Min=%8.4f  Max=%8.4f\n",
              v, sum(!is.na(x)), mean(x, na.rm=TRUE), sd(x, na.rm=TRUE),
              min(x, na.rm=TRUE), max(x, na.rm=TRUE)))
}

# Save
saveRDS(analysis_clean, file.path(data_dir, "analysis.rds"))
cat("\nSaved analysis.rds with", nrow(analysis_clean), "observations\n")
