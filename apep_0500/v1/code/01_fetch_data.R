## ===========================================================
## 01_fetch_data.R — Download UCDP GED + Nigeria boundaries
## APEP-0500: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

source("00_packages.R")

# -----------------------------------------------------------
# 1. UCDP Georeferenced Event Dataset (GED) v25.1
# -----------------------------------------------------------
cat("Downloading UCDP GED v25.1...\n")

ucdp_url <- "https://ucdp.uu.se/downloads/ged/ged251-csv.zip"
ucdp_zip <- file.path(data_dir, "ged251-csv.zip")
ucdp_csv <- file.path(data_dir, "GEDEvent_v25_1.csv")

if (!file.exists(ucdp_csv)) {
  download.file(ucdp_url, ucdp_zip, mode = "wb", quiet = FALSE)
  unzip(ucdp_zip, exdir = data_dir)
  cat("UCDP GED downloaded and extracted.\n")
} else {
  cat("UCDP GED already exists.\n")
}

# Load and filter to Nigeria
ged_full <- fread(ucdp_csv)
ged_nga <- ged_full[country == "Nigeria"]
cat(sprintf("Nigeria events: %d (of %d total)\n", nrow(ged_nga), nrow(ged_full)))

# Save Nigeria subset
fwrite(ged_nga, file.path(data_dir, "ucdp_nigeria.csv"))

# -----------------------------------------------------------
# 2. Nigeria Administrative Boundaries (GADM v4.1)
# -----------------------------------------------------------
cat("\nDownloading Nigeria GADM boundaries...\n")

# State boundaries (level 1) - try GeoPackage first, then GeoJSON
gadm1_gpkg <- file.path(data_dir, "nga_states.gpkg")
gadm1_file <- file.path(data_dir, "gadm41_NGA_1.json")

if (!file.exists(gadm1_gpkg) && !file.exists(gadm1_file)) {
  # Try GADM gpkg (smaller, faster)
  gpkg_url <- "https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_NGA.gpkg"
  gpkg_file <- file.path(data_dir, "gadm41_NGA.gpkg")

  if (!file.exists(gpkg_file)) {
    tryCatch({
      download.file(gpkg_url, gpkg_file, mode = "wb", quiet = FALSE,
                    timeout = 300)
    }, error = function(e) {
      # Fallback: try GeoJSON
      cat("GeoPackage download failed, trying GeoJSON...\n")
      gadm1_url <- "https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_NGA_1.json"
      download.file(gadm1_url, gadm1_file, mode = "wb", quiet = FALSE,
                    timeout = 300)
    })
  }

  if (file.exists(gpkg_file)) {
    nga_states <- st_read(gpkg_file, layer = "ADM_ADM_1", quiet = TRUE)
    nga_lgas <- st_read(gpkg_file, layer = "ADM_ADM_2", quiet = TRUE)
    cat(sprintf("States loaded from GPKG: %d\n", nrow(nga_states)))
    cat(sprintf("LGAs loaded from GPKG: %d\n", nrow(nga_lgas)))

    # Save as separate geopackages
    st_write(nga_states, gadm1_gpkg, layer = "states",
             delete_dsn = TRUE, quiet = TRUE)
    st_write(nga_lgas, file.path(data_dir, "nga_lgas.gpkg"),
             layer = "lgas", delete_dsn = TRUE, quiet = TRUE)
  } else {
    nga_states <- st_read(gadm1_file, quiet = TRUE)
    cat(sprintf("States loaded from JSON: %d\n", nrow(nga_states)))

    gadm2_url <- "https://geodata.ucdavis.edu/gadm/gadm4.1/json/gadm41_NGA_2.json"
    gadm2_file <- file.path(data_dir, "gadm41_NGA_2.json")
    download.file(gadm2_url, gadm2_file, mode = "wb", quiet = FALSE,
                  timeout = 300)
    nga_lgas <- st_read(gadm2_file, quiet = TRUE)
    cat(sprintf("LGAs loaded from JSON: %d\n", nrow(nga_lgas)))

    st_write(nga_states, gadm1_gpkg, layer = "states",
             delete_dsn = TRUE, quiet = TRUE)
    st_write(nga_lgas, file.path(data_dir, "nga_lgas.gpkg"),
             layer = "lgas", delete_dsn = TRUE, quiet = TRUE)
  }
} else {
  # Load from existing files
  if (file.exists(gadm1_gpkg)) {
    nga_states <- st_read(gadm1_gpkg, layer = "states", quiet = TRUE)
    nga_lgas <- st_read(file.path(data_dir, "nga_lgas.gpkg"),
                        layer = "lgas", quiet = TRUE)
  } else {
    nga_states <- st_read(gadm1_file, quiet = TRUE)
    gadm2_file <- file.path(data_dir, "gadm41_NGA_2.json")
    nga_lgas <- st_read(gadm2_file, quiet = TRUE)
  }
  cat(sprintf("States loaded: %d\n", nrow(nga_states)))
  cat(sprintf("LGAs loaded: %d\n", nrow(nga_lgas)))
}

# -----------------------------------------------------------
# 3. Anti-Open Grazing Law Adoption Dates
# -----------------------------------------------------------
cat("\nCreating treatment assignment data...\n")

# Compiled from legislative records and news reports
# Sources: Tandfonline 2024, ThisDay, Guardian, ICIR, Cable
law_dates <- tribble(
  ~state,           ~law_year, ~law_month, ~source,
  "Ekiti",          2016,      8,          "First state; Gov Fayose signed Aug 2016",
  "Benue",          2017,      11,         "Open Grazing Prohibition and Ranches Establishment Law, Nov 2017",
  "Taraba",         2017,      12,         "Signed into law 2017",
  "Abia",           2018,      6,          "Control of Nomadic Cattle Rearing, Jun 2018",
  "Ebonyi",         2018,      9,          "Anti-open grazing law 2018",
  "Oyo",            2019,      10,         "Open Rearing and Grazing Regulation Law, Oct 2019",
  "Ondo",           2021,      8,          "Post-SGF resolution, Aug 2021",
  "Rivers",         2021,      8,          "Signed Aug 19, 2021",
  "Enugu",          2021,      9,          "Signed Sep 14, 2021",
  "Osun",           2021,      9,          "Signed Sep 15, 2021",
  "Lagos",          2021,      9,          "Signed Sep 20, 2021",
  "Delta",          2021,      9,          "Passed Sep 30, 2021",
  "Ogun",           2021,      10,         "Signed late 2021",
  "Akwa Ibom",      2021,      10,         "Adopted post-SGF 2021"
)

# States that never adopted (through 2024)
never_treated <- c(
  "Adamawa", "Bauchi", "Bayelsa", "Borno", "Cross River", "Edo",
  "Gombe", "Imo", "Jigawa", "Kaduna", "Kano", "Katsina",
  "Kebbi", "Kogi", "Kwara", "Nasarawa", "Niger", "Plateau",
  "Sokoto", "Yobe", "Zamfara", "Federal Capital Territory", "Anambra"
)

# Create first_treat variable (effective treatment year in annual panel)
# Convention: treat begins in adoption year if adopted Jan-Jun,
# in the following year if adopted Jul-Dec
law_data <- law_dates %>%
  mutate(first_treat = ifelse(law_month <= 6, law_year, law_year + 1L)) %>%
  select(state, first_treat, law_year, law_month, source)

# Add never-treated states
never_df <- tibble(
  state = never_treated,
  first_treat = 0L,
  law_year = NA_integer_,
  law_month = NA_integer_,
  source = "No anti-open grazing law through 2024"
)

treatment <- bind_rows(law_data, never_df)
cat(sprintf("Treated states: %d, Never-treated: %d, Total: %d\n",
            sum(treatment$first_treat > 0),
            sum(treatment$first_treat == 0),
            nrow(treatment)))

write_csv(treatment, file.path(data_dir, "treatment_assignment.csv"))

# -----------------------------------------------------------
# 4. FAO Gridded Livestock (for pastoral zone classification)
# -----------------------------------------------------------
cat("\nDownloading FAO livestock density data...\n")

# GLW4 cattle density (latest version)
# Using 10km resolution for Africa
glw_url <- "https://dataverse.harvard.edu/api/access/datafile/6569885"
glw_file <- file.path(data_dir, "glw4_cattle.tif")

if (!file.exists(glw_file)) {
  tryCatch({
    download.file(glw_url, glw_file, mode = "wb", quiet = FALSE, timeout = 120)
    cat("FAO GLW cattle density downloaded.\n")
  }, error = function(e) {
    cat("WARNING: GLW download failed. Will use alternative pastoral classification.\n")
    cat("Error:", conditionMessage(e), "\n")
  })
} else {
  cat("FAO GLW already exists.\n")
}

# -----------------------------------------------------------
# 5. Summary
# -----------------------------------------------------------
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("UCDP Nigeria events: %d\n", nrow(ged_nga)))
cat(sprintf("GADM states: %d\n", nrow(nga_states)))
cat(sprintf("GADM LGAs: %d\n", nrow(nga_lgas)))
cat(sprintf("Treated states: %d\n", sum(treatment$first_treat > 0)))
cat(sprintf("Years covered: %s-%s\n",
            min(ged_nga$year), max(ged_nga$year)))
cat("Data fetch complete.\n")
