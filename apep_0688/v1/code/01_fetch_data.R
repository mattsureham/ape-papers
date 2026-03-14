## 01_fetch_data.R — Fetch ONS PFA crime data and population estimates
## Data: ONS "Police Force Area Data Tables" + NOMIS population
## Sources: ONS PFA tables (xlsx), NOMIS API, ONS Open Geography Portal

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ─────────────────────────────────────────────────────────────────────────────
## 1. ONS Police Force Area Crime Data Tables
## ─────────────────────────────────────────────────────────────────────────────
## The ONS publishes "Crime in England and Wales: Police Force Area Data Tables"
## quarterly. Each publication contains Table P6 (knife crime time series by PFA)
## and Table P8 (firearm offences time series by PFA), with rolling annual data
## from ~2010 to the latest quarter.
##
## We download the latest edition (year ending September 2025) which contains
## the full historical time series.

cat("=== Fetching ONS PFA crime data ===\n")

ons_url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/crimeandjustice/datasets/policeforceareadatatables/yearendingseptember2025/policeforceareatablesyesep25.xlsx"

ons_file <- file.path(data_dir, "ons_pfa_crime.xlsx")

resp <- tryCatch(
  request(ons_url) |> req_timeout(120) |> req_perform(),
  error = function(e) stop("FATAL: Failed to download ONS PFA crime data: ", conditionMessage(e))
)
writeBin(resp_body_raw(resp), ons_file)

if (!file.exists(ons_file) || file.size(ons_file) < 10000) {
  stop("FATAL: ONS PFA crime data download failed or file is too small")
}
cat("ONS PFA data downloaded:", file.size(ons_file), "bytes\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1a. Parse Table P6: Knife crime time series by PFA
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Parsing Table P6 (knife crime) ---\n")

## Read raw to find header row
p6_raw <- read_excel(ons_file, sheet = "Table P6 ", col_names = FALSE, .name_repair = "minimal")

## Find the row with "Area Codes" — that's the header
header_row <- which(apply(p6_raw, 1, function(x) any(grepl("Area Code", x, ignore.case = TRUE))))
if (length(header_row) == 0) stop("FATAL: Cannot find header row in Table P6")
header_row <- header_row[1]

## Read data starting from header
p6 <- read_excel(ons_file, sheet = "Table P6 ", skip = header_row - 1, col_names = TRUE, .name_repair = "unique_quiet")
names(p6)[1:2] <- c("area_code", "area_name")

## Identify columns with year data (e.g., "Apr 2010 to\n Mar 2011")
year_cols <- grep("^Apr|^Oct|^Jul|^Jan", names(p6), value = TRUE)
pct_cols <- grep("^%|involving", names(p6), value = TRUE)

## Keep only count columns (not percentage columns)
## Count columns are the ones that match "Apr YYYY to" pattern
count_cols <- setdiff(names(p6)[3:ncol(p6)], pct_cols)
## Actually, alternate columns: counts then percentages
## Let's take every other column starting from column 3
col_indices <- seq(3, ncol(p6), by = 2)  # Odd-numbered data columns = counts
count_col_names <- names(p6)[col_indices]

cat("Year columns found:", length(count_col_names), "\n")
cat("Sample column names:", paste(head(count_col_names, 3), collapse = " | "), "\n")

## Filter to PFA rows (exclude regions, England/Wales totals)
## PFA codes start with E23 (England) or W15 (Wales)
p6_pfa <- p6[grepl("^E23|^W15", p6$area_code), ]
cat("PFA rows:", nrow(p6_pfa), "\n")

## Pivot to long format
p6_long <- p6_pfa |>
  select(area_code, area_name, all_of(count_col_names)) |>
  pivot_longer(cols = -c(area_code, area_name),
               names_to = "period_raw", values_to = "knife_crime") |>
  mutate(knife_crime = as.numeric(knife_crime))

## Extract year from period string
## Pattern: "Apr YYYY to\n Mar YYYY+1" or similar
## Extract years from period strings like "Apr 2010 to\n Mar 2011"
p6_long <- p6_long |>
  mutate(
    years_found = str_extract_all(period_raw, "\\d{4}"),
    year_start = as.integer(map_chr(years_found, ~ .x[1])),
    year_end = as.integer(map_chr(years_found, ~ tail(.x, 1))),
    fy = paste0(year_start, "/", substr(year_end, 3, 4))
  ) |>
  select(-years_found)

cat("Years covered:", paste(range(p6_long$year_end, na.rm = TRUE), collapse = " to "), "\n")
cat("Forces:", n_distinct(p6_long$area_name), "\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1b. Parse Table P8: Firearm offences time series by PFA
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Parsing Table P8 (firearm offences) ---\n")

p8_raw <- read_excel(ons_file, sheet = "Table P8 ", col_names = FALSE, .name_repair = "minimal")
header_row_8 <- which(apply(p8_raw, 1, function(x) any(grepl("Area code|Area Code", x, ignore.case = TRUE))))
if (length(header_row_8) == 0) stop("FATAL: Cannot find header row in Table P8")
header_row_8 <- header_row_8[1]

p8 <- read_excel(ons_file, sheet = "Table P8 ", skip = header_row_8 - 1, col_names = TRUE, .name_repair = "unique_quiet")
names(p8)[1:2] <- c("area_code", "area_name")

## P8 may have count and percentage columns mixed
p8_pfa <- p8[grepl("^E23|^W15", p8$area_code), ]

## Filter to numeric columns only (counts, not % change text)
all_data_cols <- names(p8)[3:ncol(p8)]
## Keep only columns that match "Apr|Oct|Jul|Jan" year patterns and don't contain "%"
count_col_names_8 <- all_data_cols[!grepl("%|change|compared", all_data_cols, ignore.case = TRUE)]
## Also ensure columns are numeric
numeric_check <- sapply(count_col_names_8, function(cn) {
  is.numeric(p8_pfa[[cn]]) || all(is.na(p8_pfa[[cn]])) ||
    all(grepl("^\\d+$|^\\[", as.character(p8_pfa[[cn]][!is.na(p8_pfa[[cn]])])))
})
count_col_names_8 <- count_col_names_8[numeric_check]

cat("Year columns found:", length(count_col_names_8), "\n")

p8_long <- p8_pfa |>
  select(area_code, area_name, all_of(count_col_names_8)) |>
  pivot_longer(cols = -c(area_code, area_name),
               names_to = "period_raw", values_to = "firearm_offences") |>
  mutate(
    firearm_offences = as.numeric(firearm_offences),
    years_found = str_extract_all(period_raw, "\\d{4}"),
    year_start = as.integer(map_chr(years_found, ~ .x[1])),
    year_end = as.integer(map_chr(years_found, ~ tail(.x, 1)))
  ) |>
  select(-years_found)

cat("Years covered:", paste(range(p8_long$year_end, na.rm = TRUE), collapse = " to "), "\n")

## ─────────────────────────────────────────────────────────────────────────────
## 1c. Parse Table P1: Total recorded crime by offence group (cross-section)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Parsing Table P1 (total crime, latest year) ---\n")

p1_raw <- read_excel(ons_file, sheet = "Table P1", col_names = FALSE, .name_repair = "minimal")
header_row_1 <- which(apply(p1_raw, 1, function(x) any(grepl("Area Code", x, ignore.case = TRUE))))
if (length(header_row_1) == 0) stop("FATAL: Cannot find header row in Table P1")
header_row_1 <- header_row_1[1]

p1 <- read_excel(ons_file, sheet = "Table P1", skip = header_row_1 - 1, col_names = TRUE, .name_repair = "unique_quiet")
names(p1)[1:2] <- c("area_code", "area_name")

p1_pfa <- p1[grepl("^E23|^W15", p1$area_code), ]
cat("P1 PFA rows:", nrow(p1_pfa), "\n")
cat("P1 columns:", paste(head(names(p1), 10), collapse = " | "), "\n")

## Save cross-section for summary stats
fwrite(as.data.table(p1_pfa), file.path(data_dir, "crime_crosssection.csv"))

## Note: The knife crime (P6) and firearm (P8) time-series panels are our
## primary data. Knife crime is the most direct VRU target outcome.
## Total violence from P1 cross-section used for summary statistics only.

## ─────────────────────────────────────────────────────────────────────────────
## 2. Population from ONS Table P3 (same file)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Extracting population from Table P3 ===\n")

p3_raw <- read_excel(ons_file, sheet = "Table P3", col_names = FALSE, .name_repair = "minimal")
header_row_3 <- which(apply(p3_raw, 1, function(x) any(grepl("Area Code", x, ignore.case = TRUE))))
if (length(header_row_3) == 0) stop("FATAL: Cannot find header row in Table P3")

p3 <- read_excel(ons_file, sheet = "Table P3", skip = header_row_3[1] - 1, col_names = TRUE, .name_repair = "unique_quiet")
names(p3)[1:2] <- c("area_code", "area_name")

p3_pfa <- p3[grepl("^E23|^W15", p3$area_code), ]

## Find population column
pop_col <- grep("^Pop|population", names(p3_pfa), ignore.case = TRUE, value = TRUE)[1]
if (is.na(pop_col)) {
  ## Population is typically column 3
  pop_col <- names(p3_pfa)[3]
  cat("Using column 3 as population:", pop_col, "\n")
}

pop_df <- data.table(
  area_code = p3_pfa$area_code,
  area_name = p3_pfa$area_name,
  population = as.numeric(p3_pfa[[pop_col]])
)

cat("Population data:", nrow(pop_df), "forces\n")
cat("Population range:", range(pop_df$population, na.rm = TRUE), "\n")
fwrite(pop_df, file.path(data_dir, "population_pfa.csv"))

## ─────────────────────────────────────────────────────────────────────────────
## 3. VRU Treatment Assignment
## ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Creating VRU treatment assignment ===\n")

## 18 forces allocated Serious Violence Fund grants in 2019
## Source: Home Office press release, "Serious violence: new public health approach"
## Selection based on highest rates of serious violence, Mar 2016-Mar 2018
vru_forces_2019 <- c(
  "Metropolitan Police",
  "West Midlands",
  "Greater Manchester",
  "Merseyside",
  "South Yorkshire",
  "West Yorkshire",
  "Lancashire",
  "Nottinghamshire",
  "Avon and Somerset",
  "Hampshire",
  "Essex",
  "Kent",
  "Thames Valley",
  "Bedfordshire",
  "Sussex",
  "Northumbria",
  "Cleveland",
  "South Wales"
)

## Two additional forces received funding in 2022
vru_forces_2022 <- c("Humberside", "Leicestershire")

treatment_df <- data.table(
  force_name = c(vru_forces_2019, vru_forces_2022),
  cohort_year = c(rep(2019L, length(vru_forces_2019)),
                  rep(2022L, length(vru_forces_2022))),
  vru = 1L
)

fwrite(treatment_df, file.path(data_dir, "vru_treatment.csv"))
cat("VRU treatment:", nrow(treatment_df), "treated forces\n")

## ─────────────────────────────────────────────────────────────────────────────
## 4. Force Contiguity Matrix (for spillover analysis)
## ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Building force contiguity matrix ===\n")

## Police force area boundaries from ONS Open Geography Portal
boundary_url <- "https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Police_Force_Areas_December_2023_EW_BFC/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson"

boundary_resp <- tryCatch(
  request(boundary_url) |> req_timeout(120) |> req_perform(),
  error = function(e) {
    cat("ArcGIS failed:", conditionMessage(e), "\n")
    cat("Building contiguity from known geographic adjacency...\n")
    NULL
  }
)

if (!is.null(boundary_resp)) {
  boundary_json <- resp_body_string(boundary_resp)
  pfa_sf <- st_read(boundary_json, quiet = TRUE)

  ## Get force name column
  name_col <- intersect(names(pfa_sf), c("PFA23NM", "PFA22NM", "PFANM"))[1]
  if (is.na(name_col)) name_col <- names(pfa_sf)[grep("NM$", names(pfa_sf))[1]]

  if (!is.na(name_col)) {
    touches_mat <- st_touches(pfa_sf, sparse = FALSE)
    force_names_geo <- pfa_sf[[name_col]]

    contiguity_pairs <- list()
    for (i in 1:nrow(touches_mat)) {
      neighbors <- which(touches_mat[i, ])
      for (j in neighbors) {
        contiguity_pairs[[length(contiguity_pairs) + 1]] <- data.table(
          force_1 = force_names_geo[i],
          force_2 = force_names_geo[j]
        )
      }
    }
    contiguity_long <- rbindlist(contiguity_pairs)
    cat("Contiguity pairs from GIS:", nrow(contiguity_long), "\n")
  } else {
    cat("WARNING: Cannot identify force name column, using manual contiguity\n")
    contiguity_long <- NULL
  }
} else {
  contiguity_long <- NULL
}

## Fallback: manual contiguity based on known geography
if (is.null(contiguity_long) || nrow(contiguity_long) == 0) {
  cat("Using manual contiguity matrix...\n")
  ## Key adjacencies (England & Wales police forces)
  manual_pairs <- rbind(
    data.table(force_1 = "Metropolitan Police", force_2 = c("City of London", "Essex", "Kent", "Surrey", "Sussex", "Thames Valley", "Hertfordshire", "Bedfordshire")),
    data.table(force_1 = "West Midlands", force_2 = c("Staffordshire", "Warwickshire", "West Mercia")),
    data.table(force_1 = "Greater Manchester", force_2 = c("Lancashire", "West Yorkshire", "Derbyshire", "Cheshire", "Merseyside")),
    data.table(force_1 = "Merseyside", force_2 = c("Lancashire", "Greater Manchester", "Cheshire", "North Wales")),
    data.table(force_1 = "South Yorkshire", force_2 = c("West Yorkshire", "Nottinghamshire", "Derbyshire", "Humberside", "Lincolnshire")),
    data.table(force_1 = "West Yorkshire", force_2 = c("South Yorkshire", "Greater Manchester", "Lancashire", "North Yorkshire")),
    data.table(force_1 = "Lancashire", force_2 = c("Greater Manchester", "Merseyside", "West Yorkshire", "North Yorkshire", "Cumbria")),
    data.table(force_1 = "Nottinghamshire", force_2 = c("South Yorkshire", "Derbyshire", "Leicestershire", "Lincolnshire")),
    data.table(force_1 = "Avon and Somerset", force_2 = c("Gloucestershire", "Wiltshire", "Dorset", "Devon and Cornwall", "South Wales", "Gwent")),
    data.table(force_1 = "Hampshire", force_2 = c("Thames Valley", "Surrey", "Sussex", "Wiltshire", "Dorset")),
    data.table(force_1 = "Essex", force_2 = c("Metropolitan Police", "Kent", "Suffolk", "Hertfordshire", "Cambridgeshire")),
    data.table(force_1 = "Kent", force_2 = c("Metropolitan Police", "Essex", "Surrey", "Sussex")),
    data.table(force_1 = "Thames Valley", force_2 = c("Metropolitan Police", "Hampshire", "Wiltshire", "Gloucestershire", "West Mercia", "Warwickshire", "Northamptonshire", "Bedfordshire", "Hertfordshire", "Surrey")),
    data.table(force_1 = "Bedfordshire", force_2 = c("Metropolitan Police", "Thames Valley", "Hertfordshire", "Cambridgeshire", "Northamptonshire")),
    data.table(force_1 = "Sussex", force_2 = c("Metropolitan Police", "Kent", "Surrey", "Hampshire")),
    data.table(force_1 = "Northumbria", force_2 = c("Durham", "Cumbria")),
    data.table(force_1 = "Cleveland", force_2 = c("Durham", "North Yorkshire")),
    data.table(force_1 = "South Wales", force_2 = c("Gwent", "Dyfed-Powys", "Avon and Somerset"))
  )
  ## Make symmetric
  contiguity_long <- rbind(manual_pairs, manual_pairs[, .(force_1 = force_2, force_2 = force_1)])
  contiguity_long <- unique(contiguity_long)
  cat("Manual contiguity pairs:", nrow(contiguity_long), "\n")
}

fwrite(contiguity_long, file.path(data_dir, "force_contiguity.csv"))

## Classify untreated forces as boundary vs interior
all_vru <- c(vru_forces_2019, vru_forces_2022)
boundary_forces <- unique(c(
  contiguity_long[force_1 %in% all_vru & !(force_2 %in% all_vru), force_2],
  contiguity_long[force_2 %in% all_vru & !(force_1 %in% all_vru), force_1]
))

cat("Boundary forces (untreated, adjacent to VRU):", length(boundary_forces), "\n")
cat(paste(" -", sort(boundary_forces), collapse = "\n"), "\n")

fwrite(data.table(force_name = boundary_forces, boundary = 1L),
       file.path(data_dir, "boundary_forces.csv"))

## ─────────────────────────────────────────────────────────────────────────────
## 5. Save knife crime and firearm panels
## ─────────────────────────────────────────────────────────────────────────────
fwrite(as.data.table(p6_long), file.path(data_dir, "knife_crime_panel.csv"))
fwrite(as.data.table(p8_long), file.path(data_dir, "firearm_panel.csv"))

cat("\n=== Data fetch complete ===\n")
cat("Files saved in", data_dir, ":\n")
cat(paste(" -", list.files(data_dir, pattern = "\\.csv$"), collapse = "\n"), "\n")
