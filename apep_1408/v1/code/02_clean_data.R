## 02_clean_data.R — Clean and construct analysis panel
## apep_1408: PNIS coca substitution in Colombia

source("00_packages.R")

data_dir <- "../data"

## ─────────────────────────────────────────────────
## 1. Reshape coca panel to long format
## ─────────────────────────────────────────────────

coca_raw <- readRDS(file.path(data_dir, "coca_raw.rds"))

# Year columns are _2001 through _2023
year_cols <- grep("^_\\d{4}$", names(coca_raw), value = TRUE)
coca_long <- coca_raw %>%
  pivot_longer(
    cols = all_of(year_cols),
    names_to = "year",
    values_to = "coca_ha"
  ) %>%
  mutate(
    year = as.integer(gsub("^_", "", year)),
    coca_ha = as.numeric(coca_ha),
    coca_ha = replace_na(coca_ha, 0),
    codmpio = as.character(codmpio),
    coddepto = as.character(coddepto)
  ) %>%
  select(coddepto, departamento, codmpio, municipio, year, coca_ha)

cat("Coca panel long: ", nrow(coca_long), "rows,",
    n_distinct(coca_long$codmpio), "municipalities,",
    n_distinct(coca_long$year), "years\n")

## ─────────────────────────────────────────────────
## 2. Identify PNIS treatment municipalities and timing
## ─────────────────────────────────────────────────

pnis_raw <- readRDS(file.path(data_dir, "pnis_raw.rds"))

# PNIS enrollment — all municipalities enrolled 2017-2018
# Wave assignment based on historical documentation:
# Wave 1 (2017): Putumayo, Nariño, Caquetá — first signatories
# Wave 2 (2018): remaining municipalities
pnis <- pnis_raw %>%
  mutate(
    codmpio = as.character(divipola_municipal),
    pnis_enrolled = 1,
    # Total families enrolled
    n_families = as.numeric(pagos_asistencia_alimentaria),
    n_collectors = as.numeric(recolectores)
  )

# Assign treatment wave based on department
wave1_depts <- c("PUTUMAYO", "NARIÑO", "CAQUETÁ", "CAQUETA")
pnis <- pnis %>%
  mutate(
    dept_upper = toupper(departamento),
    first_treat = case_when(
      dept_upper %in% wave1_depts ~ 2017L,
      TRUE ~ 2018L
    )
  )

cat("PNIS municipalities:", nrow(pnis), "\n")
cat("Wave 1 (2017):", sum(pnis$first_treat == 2017), "\n")
cat("Wave 2 (2018):", sum(pnis$first_treat == 2018), "\n")

## ─────────────────────────────────────────────────
## 3. Merge and construct analysis panel
## ─────────────────────────────────────────────────

panel <- coca_long %>%
  left_join(
    pnis %>% select(codmpio, pnis_enrolled, first_treat, n_families, n_collectors),
    by = "codmpio"
  ) %>%
  mutate(
    pnis_enrolled = replace_na(pnis_enrolled, 0),
    first_treat = if_else(pnis_enrolled == 0, 0L, first_treat),
    # Log coca (adding 0.01 for zeros)
    log_coca = log(coca_ha + 0.01),
    # Inverse hyperbolic sine (handles zeros better)
    ihs_coca = log(coca_ha + sqrt(coca_ha^2 + 1)),
    # Pre-PNIS coca intensity (2016 level as dose)
    coca_2016 = NA_real_,
    # Post indicator
    post = as.integer(year >= first_treat & first_treat > 0),
    # Relative time
    rel_time = if_else(first_treat > 0, year - first_treat, NA_integer_)
  )

# Fill coca_2016 as pre-treatment dose variable
coca_baseline <- coca_long %>%
  filter(year == 2016) %>%
  select(codmpio, coca_2016 = coca_ha)

panel <- panel %>%
  select(-coca_2016) %>%
  left_join(coca_baseline, by = "codmpio") %>%
  mutate(coca_2016 = replace_na(coca_2016, 0))

## ─────────────────────────────────────────────────
## 4. Process eradication data
## ─────────────────────────────────────────────────

erad_raw <- readRDS(file.path(data_dir, "eradication_raw.rds"))

# Extract year from fecha_hecho and aggregate to municipality-year
erad_annual <- erad_raw %>%
  mutate(
    year = as.integer(substr(fecha_hecho, 1, 4)),
    codmpio = as.character(cod_muni),
    cantidad = as.numeric(cantidad),
    # Classify eradication type from tipo_de_cultivo or method info
    crop_type = tolower(tipo_de_cultivo)
  ) %>%
  filter(!is.na(year), year >= 2007) %>%
  group_by(codmpio, year) %>%
  summarize(
    erad_events = n(),
    erad_ha = sum(cantidad, na.rm = TRUE),
    .groups = "drop"
  )

cat("Eradication annual panel:", nrow(erad_annual), "rows\n")

# Merge eradication into main panel
panel <- panel %>%
  left_join(erad_annual, by = c("codmpio", "year")) %>%
  mutate(
    erad_events = replace_na(erad_events, 0),
    erad_ha = replace_na(erad_ha, 0),
    log_erad = log(erad_ha + 0.01),
    ihs_erad = log(erad_ha + sqrt(erad_ha^2 + 1))
  )

## ─────────────────────────────────────────────────
## 5. Final panel summary
## ─────────────────────────────────────────────────

cat("\n=== ANALYSIS PANEL ===\n")
cat("Total rows:", nrow(panel), "\n")
cat("Municipalities:", n_distinct(panel$codmpio), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("PNIS municipalities:", sum(panel$pnis_enrolled == 1 & panel$year == 2017), "\n")
cat("Never-treated:", sum(panel$pnis_enrolled == 0 & panel$year == 2017), "\n")

cat("\nCoca summary (all muni-years):\n")
print(summary(panel$coca_ha))

cat("\nCoca summary (PNIS municipalities, pre-2017):\n")
print(summary(panel$coca_ha[panel$pnis_enrolled == 1 & panel$year < 2017]))

cat("\nCoca summary (PNIS municipalities, post-2017):\n")
print(summary(panel$coca_ha[panel$pnis_enrolled == 1 & panel$year >= 2017]))

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nAnalysis panel saved.\n")
