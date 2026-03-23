## 01_fetch_data.R — Download GADM, homicide data, population, and VIIRS
## APEP paper apep_0814: El Salvador gang removal and nighttime economic activity

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ─────────────────────────────────────────────────────────────────────────────
# 1. GADM Level 2 boundaries (municipalities)
# ─────────────────────────────────────────────────────────────────────────────
message("=== Fetching GADM ADM2 boundaries for El Salvador ===")
gadm_path <- file.path(data_dir, "gadm_slv_adm2.gpkg")

if (!file.exists(gadm_path)) {
  slv <- geodata::gadm(country = "SLV", level = 2, path = data_dir)
  slv_sf <- sf::st_as_sf(slv)
  sf::st_write(slv_sf, gadm_path, delete_dsn = TRUE)
  message("GADM saved: ", nrow(slv_sf), " municipalities")
} else {
  slv_sf <- sf::st_read(gadm_path, quiet = TRUE)
  message("GADM loaded from cache: ", nrow(slv_sf), " municipalities")
}

stopifnot("Expected ~260 municipalities" = nrow(slv_sf) >= 250)
message("Municipalities: ", nrow(slv_sf))

# ─────────────────────────────────────────────────────────────────────────────
# 2. Municipality-level homicide rates (Carcach 2025, PLOS ONE)
#    Source: PNC and IML administrative records, 2002-2021
#    DOI: 10.1371/journal.pone.0330215
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Fetching municipality-level homicide data ===")
hom_path <- file.path(data_dir, "homicide_rates.csv")
gang_path <- file.path(data_dir, "gang_detentions.csv")
pop_path <- file.path(data_dir, "population.csv")

base_url <- "https://journals.plos.org/plosone/article/file?type=supplementary&id=10.1371/journal.pone.0330215"

if (!file.exists(hom_path)) {
  # S1: Homicide rates (municipality × year, 2002-2021)
  download.file(paste0(base_url, ".s001"), hom_path, mode = "wb", quiet = FALSE)
  message("Homicide rates saved: ", round(file.size(hom_path) / 1024), " KB")
} else {
  message("Homicide rates loaded from cache")
}

if (!file.exists(gang_path)) {
  # S2: Gang detentions (municipality × year, 2011-2018)
  download.file(paste0(base_url, ".s002"), gang_path, mode = "wb", quiet = FALSE)
  message("Gang detentions saved: ", round(file.size(gang_path) / 1024), " KB")
} else {
  message("Gang detentions loaded from cache")
}

if (!file.exists(pop_path)) {
  # S3: Population by municipality (1965-2022)
  download.file(paste0(base_url, ".s003"), pop_path, mode = "wb", quiet = FALSE)
  message("Population saved: ", round(file.size(pop_path) / 1024), " KB")
} else {
  message("Population loaded from cache")
}

# Read and validate
hom_df <- data.table::fread(hom_path)
gang_df <- data.table::fread(gang_path)
pop_df <- data.table::fread(pop_path)

message("Homicide data: ", nrow(hom_df), " rows, ",
        ncol(hom_df), " cols")
message("  Columns: ", paste(names(hom_df), collapse = ", "))
message("Gang detentions: ", nrow(gang_df), " rows")
message("Population: ", nrow(pop_df), " rows")

# ─────────────────────────────────────────────────────────────────────────────
# 3. VIIRS nightlights via blackmarbler (annual VNP46A4, 2012-2023)
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Fetching VIIRS annual nightlights (2012-2023) ===")
viirs_path <- file.path(data_dir, "viirs_annual.csv")

if (!file.exists(viirs_path)) {
  nasa_token <- Sys.getenv("NASA_EARTHDATA_API_KEY")
  if (nasa_token == "") stop("NASA_EARTHDATA_API_KEY must be set in .env")

  years <- 2012:2023

  # Extract annual mean nighttime radiance per municipality
  ntl_list <- list()
  for (yr in years) {
    message("  Downloading VIIRS for ", yr, "...")
    tryCatch({
      ntl <- blackmarbler::bm_extract(
        roi_sf = slv_sf,
        product_id = "VNP46A4",
        date = yr,
        bearer = nasa_token
      )
      ntl$year <- yr
      ntl_list[[as.character(yr)]] <- ntl
      message("    Done: ", yr)
    }, error = function(e) {
      message("    ERROR for ", yr, ": ", e$message)
    })
  }

  if (length(ntl_list) == 0) {
    stop("VIIRS download failed for all years. Check NASA_EARTHDATA_API_KEY.")
  }

  viirs_df <- data.table::rbindlist(ntl_list, fill = TRUE)
  data.table::fwrite(viirs_df, viirs_path)
  message("VIIRS saved: ", nrow(viirs_df), " rows, years: ",
          paste(unique(viirs_df$year), collapse = ", "))
} else {
  viirs_df <- data.table::fread(viirs_path)
  message("VIIRS loaded from cache: ", nrow(viirs_df), " rows")
}

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Data fetch complete ===")
message("GADM municipalities: ", nrow(slv_sf))
message("Homicide data: ", nrow(hom_df), " municipality-years")
message("Gang detentions: ", nrow(gang_df), " municipalities")
message("Population: ", nrow(pop_df), " municipality-years")
message("VIIRS municipality-years: ", nrow(viirs_df))

# Save GADM for downstream use
sf::st_write(slv_sf, file.path(data_dir, "gadm_slv_adm2.gpkg"),
             delete_dsn = TRUE, quiet = TRUE)
message("All data saved to: ", data_dir)
