## 02_clean_data.R — Construct analysis dataset
## apep_1317: Colombia draft lottery and wartime conscription

source("00_packages.R")
data_dir <- "../data"

# ===========================================================================
# 1. Clean Saber 11 data
# ===========================================================================
cat("=== Cleaning Saber 11 data ===\n")

saber11 <- readRDS(file.path(data_dir, "saber11_raw.rds"))
cat(sprintf("Raw records: %d\n", nrow(saber11)))

# Parse birth dates and exam periods
saber11_clean <- saber11 %>%
  mutate(
    # Parse birth date (format: DD/MM/YYYY)
    birth_date = as.Date(estu_fechanacimiento, format = "%d/%m/%Y"),
    birth_year = year(birth_date),
    birth_month = month(birth_date),
    # Parse exam period: first 4 digits = year
    exam_year = as.integer(substr(periodo, 1, 4)),
    exam_semester = as.integer(substr(periodo, 5, 5)),
    # Numeric scores
    math_score = as.numeric(punt_matematicas),
    eng_score = as.numeric(punt_ingles),
    # Gender indicator (1 = Male)
    male = as.integer(estu_genero == "M"),
    # Department (standardize names)
    department = toupper(trimws(cole_depto_ubicacion)),
    # SES stratum (1-6)
    stratum = as.integer(gsub("Estrato ", "", fami_estratovivienda)),
    # School type
    public_school = as.integer(cole_naturaleza == "OFICIAL"),
    rural = as.integer(cole_area_ubicacion == "RURAL"),
    # Age at exam
    age_at_exam = as.numeric(difftime(
      as.Date(paste0(exam_year, "-06-15")), birth_date, units = "days"
    )) / 365.25
  ) %>%
  filter(
    !is.na(birth_year),
    birth_year >= 1990 & birth_year <= 2006,
    !is.na(math_score),
    !is.na(male),
    nchar(department) > 1,
    age_at_exam >= 14 & age_at_exam <= 25  # Reasonable age range
  )

cat(sprintf("After cleaning: %d records\n", nrow(saber11_clean)))
cat(sprintf("Birth years: %d to %d\n", min(saber11_clean$birth_year),
            max(saber11_clean$birth_year)))
cat(sprintf("Males: %d (%.1f%%), Females: %d\n",
            sum(saber11_clean$male), 100*mean(saber11_clean$male),
            sum(!saber11_clean$male)))

# ===========================================================================
# 2. Merge conflict intensity
# ===========================================================================
cat("\n=== Merging conflict data ===\n")

conflict <- readRDS(file.path(data_dir, "conflict_proxy.rds"))

# Standardize department names for merging
saber11_clean <- saber11_clean %>%
  mutate(
    dept_std = case_when(
      grepl("BOGOT", department) ~ "BOGOTA",
      grepl("NORTE.+SANTANDER", department) ~ "NORTE DE SANTANDER",
      grepl("VALLE", department) ~ "VALLE DEL CAUCA",
      grepl("GUAJIRA", department) ~ "LA GUAJIRA",
      grepl("SAN ANDRES", department) ~ "SAN ANDRES",
      TRUE ~ department
    )
  )

saber11_merged <- saber11_clean %>%
  left_join(conflict, by = c("dept_std" = "department"))

merge_rate <- mean(!is.na(saber11_merged$high_conflict))
cat(sprintf("Conflict merge rate: %.1f%%\n", 100 * merge_rate))

# Drop unmerged (small territories without conflict data)
saber11_analysis <- saber11_merged %>%
  filter(!is.na(high_conflict))

cat(sprintf("Analysis sample: %d records in %d departments\n",
            nrow(saber11_analysis),
            n_distinct(saber11_analysis$dept_std)))

# ===========================================================================
# 3. Create treatment variables
# ===========================================================================
cat("\n=== Creating treatment variables ===\n")

# Key timing: FARC peace deal signed November 24, 2016
# Males born before 1999 turned 18 before 2017 → drafted during conflict
# Males born 1999+ turned 18 in 2017+ → drafted after peace deal

saber11_analysis <- saber11_analysis %>%
  mutate(
    # Conflict-era cohort: turned 18 before peace deal (born <= 1998)
    conflict_cohort = as.integer(birth_year <= 1998),
    # Triple-difference components
    male_x_conflict = male * high_conflict,
    male_x_cohort = male * conflict_cohort,
    conflict_x_cohort = as.integer(high_conflict) * conflict_cohort,
    # DDD interaction
    ddd = male * as.integer(high_conflict) * conflict_cohort,
    # Continuous conflict intensity version
    male_x_intensity = male * conflict_intensity,
    male_x_intensity_x_cohort = male * conflict_intensity * conflict_cohort
  )

cat("Treatment summary:\n")
cat(sprintf("  Conflict-era cohorts (born <= 1998): %d (%.1f%%)\n",
            sum(saber11_analysis$conflict_cohort),
            100 * mean(saber11_analysis$conflict_cohort)))
cat(sprintf("  Males in high-conflict depts, conflict cohort (DDD=1): %d\n",
            sum(saber11_analysis$ddd)))

# ===========================================================================
# 4. Clean Saber Pro data
# ===========================================================================
cat("\n=== Cleaning Saber Pro data ===\n")

saberpro <- readRDS(file.path(data_dir, "saberpro_raw.rds"))
cat(sprintf("Raw Saber Pro records: %d\n", nrow(saberpro)))

saberpro_clean <- saberpro %>%
  mutate(
    birth_date = as.Date(estu_fechanacimiento, format = "%d/%m/%Y"),
    birth_year = year(birth_date),
    exam_year = as.integer(substr(periodo, 1, 4)),
    quant_score = as.numeric(mod_razona_cuantitat_punt),
    reading_score = as.numeric(mod_lectura_critica_punt),
    eng_score = as.numeric(mod_ingles_punt),
    writing_score = as.numeric(mod_comuni_escrita_punt),
    citizen_score = as.numeric(mod_competen_ciudada_punt),
    male = as.integer(estu_genero == "M"),
    department = toupper(trimws(estu_depto_presentacion)),
    hours_worked = as.numeric(estu_horassemanatrabaja),
    public_univ = as.integer(inst_origen == "OFICIAL"),
    stratum = as.integer(gsub("Estrato ", "", fami_estratovivienda))
  ) %>%
  mutate(
    dept_std = case_when(
      grepl("BOGOT", department) ~ "BOGOTA",
      grepl("NORTE.+SANTANDER", department) ~ "NORTE DE SANTANDER",
      grepl("VALLE", department) ~ "VALLE DEL CAUCA",
      grepl("GUAJIRA", department) ~ "LA GUAJIRA",
      grepl("SAN ANDRES", department) ~ "SAN ANDRES",
      TRUE ~ department
    )
  ) %>%
  left_join(conflict, by = c("dept_std" = "department")) %>%
  filter(!is.na(birth_year), !is.na(male), !is.na(high_conflict)) %>%
  mutate(
    conflict_cohort = as.integer(birth_year <= 1998),
    ddd = male * as.integer(high_conflict) * conflict_cohort
  )

cat(sprintf("Clean Saber Pro: %d records\n", nrow(saberpro_clean)))

# ===========================================================================
# 5. Create department-level aggregates for enrollment ratio
# ===========================================================================
cat("\n=== Creating enrollment ratio analysis ===\n")

# Aggregate Saber 11 by department × gender × exam year
s11_dept <- saber11_analysis %>%
  group_by(dept_std, male, exam_year) %>%
  summarise(
    n_s11 = n(),
    avg_math_s11 = mean(math_score, na.rm = TRUE),
    avg_eng_s11 = mean(eng_score, na.rm = TRUE),
    .groups = "drop"
  )

# Aggregate Saber Pro by department × gender × exam year
sp_dept <- saberpro_clean %>%
  group_by(dept_std, male, exam_year) %>%
  summarise(
    n_sp = n(),
    avg_quant_sp = mean(quant_score, na.rm = TRUE),
    avg_eng_sp = mean(eng_score, na.rm = TRUE),
    .groups = "drop"
  )

# Merge: approximate university completion rate
# Saber Pro year T ~ Saber 11 year T-5 (typical 5-year gap)
enrollment_panel <- s11_dept %>%
  mutate(sp_year = exam_year + 5) %>%
  left_join(sp_dept, by = c("dept_std", "male", "sp_year" = "exam_year")) %>%
  mutate(
    # Ratio of Saber Pro takers to Saber 11 takers (proxy for university completion)
    completion_ratio = n_sp / n_s11
  ) %>%
  left_join(conflict, by = c("dept_std" = "department")) %>%
  filter(!is.na(high_conflict))

cat(sprintf("Enrollment panel: %d cells\n", nrow(enrollment_panel)))

# ===========================================================================
# 6. Save analysis datasets
# ===========================================================================
saveRDS(saber11_analysis, file.path(data_dir, "saber11_analysis.rds"))
saveRDS(saberpro_clean, file.path(data_dir, "saberpro_analysis.rds"))
saveRDS(enrollment_panel, file.path(data_dir, "enrollment_panel.rds"))

# Summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat(sprintf("Saber 11 analysis:\n"))
cat(sprintf("  N = %d\n", nrow(saber11_analysis)))
cat(sprintf("  Departments: %d\n", n_distinct(saber11_analysis$dept_std)))
cat(sprintf("  Exam years: %d to %d\n", min(saber11_analysis$exam_year),
            max(saber11_analysis$exam_year)))
cat(sprintf("  Mean math score: %.1f (SD: %.1f)\n",
            mean(saber11_analysis$math_score, na.rm = TRUE),
            sd(saber11_analysis$math_score, na.rm = TRUE)))
cat(sprintf("  Male share: %.1f%%\n", 100 * mean(saber11_analysis$male)))
cat(sprintf("  High-conflict dept share: %.1f%%\n",
            100 * mean(saber11_analysis$high_conflict)))
cat(sprintf("  Conflict-era cohort share: %.1f%%\n",
            100 * mean(saber11_analysis$conflict_cohort)))

cat("\nData cleaning complete.\n")
