## 01_fetch_data.R — Fetch and parse data from DANE and datos.gov.co
## apep_1164: The Formalization Dividend
source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Parse DANE Department-Level Annual Labor Market Data
# ============================================================
cat("=== Parsing DANE department-level labor market data ===\n")

dept_file <- file.path(data_dir, "dane_dept_2024.xls")
stopifnot("Department annex file not found" = file.exists(dept_file))

# Read the main sheet using readxl
library(readxl)

raw <- read_xls(dept_file, sheet = "Departamentos anual", col_names = FALSE, .name_repair = "minimal")
colnames(raw) <- paste0("V", seq_len(ncol(raw)))

# Parse the structured Excel: departments are blocks of 18 rows each
# Department name at row start, then Concepto row, then blank, then data rows
# Variables: %PET, TGP, TO, TD, TS, then population counts
departments <- c("Antioquia", "Atlántico", "Bolívar", "Boyacá", "Caldas",
                  "Caquetá", "Cauca", "Cesar", "Chocó", "Córdoba",
                  "Cundinamarca", "Huila", "La Guajira", "Magdalena", "Meta",
                  "Nariño", "Norte de Santander", "Quindío", "Risaralda",
                  "Santander", "Sucre", "Tolima", "Valle del Cauca")

# Find department header rows
dept_rows <- which(raw$V1 %in% departments)
cat("Found", length(dept_rows), "departments\n")

# Extract year columns from the Concepto row after first department
concept_row <- dept_rows[1] + 1
years <- as.numeric(na.omit(unlist(raw[concept_row, 2:ncol(raw)])))
year_cols <- which(!is.na(as.numeric(unlist(raw[concept_row, ]))))
cat("Years:", paste(years, collapse=", "), "\n")

# Variables in each department block (relative to dept header row)
var_offsets <- data.frame(
  offset = c(3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16),
  varname = c("pct_pet", "tgp", "to", "td", "ts",
              "pop_total", "pet", "labor_force", "employed", "unemployed",
              "out_labor_force", "underemployed", "potential_labor_force"),
  stringsAsFactors = FALSE
)

# Build panel
panel_list <- list()
for (i in seq_along(dept_rows)) {
  dept_name <- departments[i]
  base_row <- dept_rows[i]

  for (j in seq_along(years)) {
    yr <- years[j]
    col_idx <- year_cols[j]

    row_data <- data.frame(department = dept_name, year = yr, stringsAsFactors = FALSE)

    for (k in seq_len(nrow(var_offsets))) {
      r <- base_row + var_offsets$offset[k]
      if (r <= nrow(raw) && col_idx <= ncol(raw)) {
        val <- suppressWarnings(as.numeric(raw[[col_idx]][r]))
        row_data[[var_offsets$varname[k]]] <- val
      } else {
        row_data[[var_offsets$varname[k]]] <- NA_real_
      }
    }

    panel_list[[length(panel_list) + 1]] <- row_data
  }
}

dept_panel <- bind_rows(panel_list)
cat("Department panel:", nrow(dept_panel), "rows,", length(unique(dept_panel$department)), "departments\n")

# Validate: should have 23 depts x 18 years = 414 rows
stopifnot("Expected 23 departments" = length(unique(dept_panel$department)) == 23)

# Population is in thousands — key variables are rates (already in %)
# and population counts (in thousands)
cat("Year range:", range(dept_panel$year, na.rm=TRUE), "\n")
cat("Employment rate (TO) range:", round(range(dept_panel$to, na.rm=TRUE), 1), "\n")

# ============================================================
# 2. Fetch ETPV Pre-Registration Data from datos.gov.co
# ============================================================
cat("\n=== Fetching ETPV pre-registration data ===\n")

# Aggregate ETPV registrations by department
etpv_url <- "https://www.datos.gov.co/resource/6eyy-q57b.json"
etpv_query <- paste0(etpv_url,
  "?$select=departamento_residencia,departamento_divipola,sum(cantidad)",
  "&$group=departamento_residencia,departamento_divipola",
  "&$order=sum_cantidad%20DESC",
  "&$limit=50")

etpv_raw <- jsonlite::fromJSON(etpv_query)
etpv_dept <- etpv_raw %>%
  filter(departamento_divipola != "9999") %>%  # Remove "En Revisión"
  mutate(
    etpv_registrations = as.numeric(sum_cantidad),
    divipola = departamento_divipola
  ) %>%
  select(dept_etpv = departamento_residencia, divipola, etpv_registrations)

cat("ETPV departments:", nrow(etpv_dept), "\n")
cat("Total registrations:", format(sum(etpv_dept$etpv_registrations), big.mark=","), "\n")

# Also get monthly breakdown for event study
etpv_monthly_url <- paste0(etpv_url,
  "?$select=departamento_residencia,departamento_divipola,anio,mes,sum(cantidad)",
  "&$group=departamento_residencia,departamento_divipola,anio,mes",
  "&$order=anio,mes",
  "&$limit=5000")
etpv_monthly <- jsonlite::fromJSON(etpv_monthly_url)

# ============================================================
# 3. Match department names between DANE and ETPV datasets
# ============================================================
cat("\n=== Matching department names ===\n")

# Create crosswalk
crosswalk <- data.frame(
  department = departments,
  dept_etpv = c("Antioquia", "Atlántico", "Bolívar", "Boyacá", "Caldas",
                "Caquetá", "Cauca", "Cesar", "Chocó", "Córdoba",
                "Cundinamarca", "Huila", "La Guajira", "Magdalena", "Meta",
                "Nariño", "Norte de Santander", "Quindio", "Risaralda",
                "Santander", "Sucre", "Tolima", "Valle del Cauca"),
  stringsAsFactors = FALSE
)

# Merge ETPV onto the crosswalk
etpv_matched <- crosswalk %>%
  left_join(etpv_dept, by = "dept_etpv")

# Check for mismatches
unmatched <- etpv_matched %>% filter(is.na(etpv_registrations))
if (nrow(unmatched) > 0) {
  cat("WARNING: Unmatched departments:\n")
  print(unmatched$department)
  # Try fuzzy matching for Quindío
  for (um in unmatched$department) {
    candidates <- etpv_dept$dept_etpv[agrep(um, etpv_dept$dept_etpv, max.distance = 0.2)]
    if (length(candidates) > 0) {
      cat("  ", um, "-> possible match:", candidates, "\n")
      etpv_matched$etpv_registrations[etpv_matched$department == um] <-
        etpv_dept$etpv_registrations[etpv_dept$dept_etpv == candidates[1]]
    }
  }
}

# ============================================================
# 4. Construct Treatment Intensity Variable
# ============================================================
cat("\n=== Constructing treatment intensity ===\n")

# Use pre-ETPV (2019) department population as denominator
pop_2019 <- dept_panel %>%
  filter(year == 2019) %>%
  select(department, pop_2019 = pop_total)

treatment <- etpv_matched %>%
  left_join(pop_2019, by = "department") %>%
  mutate(
    # ETPV registrations per 1000 population
    ven_share = etpv_registrations / (pop_2019 * 1000) * 100  # as percentage
  ) %>%
  select(department, etpv_registrations, pop_2019, ven_share)

cat("Venezuelan share (ETPV/pop) summary:\n")
print(summary(treatment$ven_share))
cat("\nTop 5 departments by Venezuelan share:\n")
print(treatment %>% arrange(desc(ven_share)) %>% head(5) %>%
        select(department, ven_share, etpv_registrations))

# ============================================================
# 5. Merge into final analysis panel
# ============================================================
cat("\n=== Building analysis panel ===\n")

panel <- dept_panel %>%
  left_join(treatment %>% select(department, ven_share, etpv_registrations), by = "department") %>%
  mutate(
    post = as.integer(year >= 2021),
    treat_intensity = ven_share * post,
    # Add Bogotá D.C. to the panel if not already there
    # (it's coded as Cundinamarca in DANE but separate in ETPV)
    dept_id = as.integer(factor(department))
  )

# Restrict to 2015-2024 for cleaner analysis (avoids structural breaks in early data)
panel <- panel %>% filter(year >= 2015)
cat("Final panel:", nrow(panel), "observations\n")
cat("Departments:", length(unique(panel$department)), "\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Pre-treatment periods:", sum(panel$year < 2021) / 23, "\n")
cat("Post-treatment periods:", sum(panel$year >= 2021) / 23, "\n")

# Validate
stopifnot("Missing treatment intensity" = !any(is.na(panel$ven_share)))
stopifnot("Missing employment rate" = sum(is.na(panel$to)) < nrow(panel) * 0.1)

# ============================================================
# 6. Also download the 13-city informality data for mechanism
# ============================================================
cat("\n=== Parsing 13-city informality data ===\n")

informal_file <- file.path(data_dir, "dane_informal_latest.xlsx")
if (file.exists(informal_file)) {
  # This is a complex Excel with city-level informality time series
  # Parse the "Prop informalidad" sheet for informality proportions
  raw_inf <- read_xlsx(informal_file, sheet = "Prop informalidad", col_names = FALSE, .name_repair = "minimal")
  colnames(raw_inf) <- paste0("V", seq_len(ncol(raw_inf)))
  cat("Informality sheet dimensions:", nrow(raw_inf), "x", ncol(raw_inf), "\n")

  # The data has city blocks, each with one row of informality proportions
  # Time periods in columns (rolling 3-month averages)
  # We'll extract this in a later analysis step if needed
} else {
  cat("Informality annex not found — skipping supplementary analysis\n")
}

# ============================================================
# 7. Save cleaned data
# ============================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(treatment, file.path(data_dir, "treatment_intensity.rds"))
saveRDS(etpv_monthly, file.path(data_dir, "etpv_monthly.rds"))

cat("\n=== Data construction complete ===\n")
cat("Saved: analysis_panel.rds, treatment_intensity.rds, etpv_monthly.rds\n")
