## 01_fetch_data.R — Fetch CBS buurt data + KNMI earthquake catalog
## apep_1069: The Compensation Cliff

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. KNMI Induced Earthquake Catalog
# ============================================================================
cat("=== Fetching KNMI induced earthquake catalog ===\n")

# CSV has full historical record (1986-2020)
knmi_csv_url <- "https://cdn.knmi.nl/knmi/map/page/seismologie/all_induced.csv"
knmi_csv <- tryCatch(
  {
    resp <- GET(knmi_csv_url)
    if (status_code(resp) != 200) stop("HTTP ", status_code(resp))
    content(resp, as = "text", encoding = "UTF-8")
  },
  error = function(e) {
    cat("CSV failed:", e$message, "\n")
    NULL
  }
)

if (!is.null(knmi_csv)) {
  eq_csv <- fread(text = knmi_csv, header = TRUE)
  cat("CSV earthquakes:", nrow(eq_csv), "events\n")
} else {
  stop("FATAL: Cannot fetch KNMI earthquake data. Cannot proceed without real data.")
}

# Also get JSON (has more recent events 2018+)
knmi_json_url <- "https://cdn.knmi.nl/knmi/map/page/seismologie/all_induced.json"
eq_json <- tryCatch(
  {
    resp <- GET(knmi_json_url)
    if (status_code(resp) != 200) stop("HTTP ", status_code(resp))
    fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  },
  error = function(e) {
    cat("JSON failed:", e$message, "\nUsing CSV only.\n")
    NULL
  }
)

# Combine and deduplicate
if (!is.null(eq_json)) {
  # JSON format: date, time, location, lat, lon, depth, mag
  eq_json_dt <- as.data.table(eq_json)
  names(eq_json_dt) <- tolower(names(eq_json_dt))
  cat("JSON earthquakes:", nrow(eq_json_dt), "events\n")
}

# Standardize CSV data
eq_data <- eq_csv %>%
  rename_all(tolower) %>%
  mutate(
    date_str = as.character(yymmdd),
    date = as.Date(date_str, format = "%Y%m%d"),
    lat = as.numeric(lat),
    lon = as.numeric(lon),
    mag = as.numeric(mag),
    depth = as.numeric(depth)
  ) %>%
  filter(!is.na(lat), !is.na(lon), !is.na(mag)) %>%
  select(date, location, lat, lon, depth, mag)

# Add JSON events not in CSV (post-2020)
if (!is.null(eq_json_dt)) {
  # JSON has same column names as CSV (YYMMDD, TIME, LOCATION, etc.)
  json_cols <- names(eq_json_dt)
  cat("JSON columns:", paste(json_cols, collapse = ", "), "\n")

  # Find the date column (might be yymmdd or date)
  date_col <- intersect(c("yymmdd", "date"), json_cols)[1]
  loc_col <- intersect(c("location", "plaats"), json_cols)[1]

  if (!is.na(date_col)) {
    eq_json_clean <- eq_json_dt %>%
      rename(date_raw = all_of(date_col)) %>%
      mutate(
        eq_date = as.Date(as.character(date_raw), format = "%Y%m%d"),
        lat = as.numeric(lat),
        lon = as.numeric(lon),
        mag = as.numeric(mag),
        depth = as.numeric(depth)
      ) %>%
      filter(!is.na(lat), !is.na(lon), !is.na(mag))

    if (!is.na(loc_col)) {
      eq_json_clean <- eq_json_clean %>% rename(location = all_of(loc_col))
    }

    eq_json_clean <- eq_json_clean %>%
      select(date = eq_date, location, lat, lon, depth, mag)

    # Keep JSON events after max CSV date
    max_csv_date <- max(eq_data$date, na.rm = TRUE)
    eq_json_new <- eq_json_clean %>% filter(date > max_csv_date)
    cat("New events from JSON (post-", as.character(max_csv_date), "):", nrow(eq_json_new), "\n")
    eq_data <- bind_rows(eq_data, eq_json_new)
  }
}

cat("Total earthquakes:", nrow(eq_data), "\n")
cat("Date range:", as.character(min(eq_data$date)), "to", as.character(max(eq_data$date)), "\n")
cat("Magnitude range:", min(eq_data$mag), "to", max(eq_data$mag), "\n")

# Filter to Groningen region (lat 52.8-53.5, lon 6.2-7.2)
eq_groningen <- eq_data %>%
  filter(lat >= 52.8, lat <= 53.5, lon >= 6.2, lon <= 7.2)
cat("Groningen region earthquakes:", nrow(eq_groningen), "\n")

saveRDS(eq_data, file.path(data_dir, "earthquakes_all.rds"))
saveRDS(eq_groningen, file.path(data_dir, "earthquakes_groningen.rds"))

# ============================================================================
# 2. CBS Buurt-Level Data (Kerncijfers wijken en buurten)
# ============================================================================
cat("\n=== Fetching CBS buurt data ===\n")

# CBS table IDs for Kerncijfers wijken en buurten by year
# These are the standard "key figures for neighborhoods" tables
cbs_tables <- c(
  "2015" = "83220NED",
  "2016" = "83487NED",
  "2017" = "83765NED",
  "2018" = "84286NED",
  "2019" = "84583NED",
  "2020" = "84799NED",
  "2021" = "85039NED",
  "2022" = "85163NED",
  "2023" = "85318NED"
)

# Function to fetch CBS data for one year with error handling
fetch_cbs_year <- function(table_id, year) {
  cat("  Fetching", year, "(table", table_id, ")...\n")

  tryCatch({
    # Get data using cbsodataR
    raw <- cbs_get_data(table_id)

    # Find the WOZ column (varies by year but pattern is consistent)
    woz_cols <- grep("WOZ|woz", names(raw), value = TRUE, ignore.case = TRUE)
    woning_cols <- grep("Woningvoorraad|woningvoorraad", names(raw), value = TRUE, ignore.case = TRUE)
    koop_cols <- grep("Koopwoningen|koopwoningen", names(raw), value = TRUE, ignore.case = TRUE)
    huur_cols <- grep("Huurwoningen|huurwoningen", names(raw), value = TRUE, ignore.case = TRUE)
    bevolking_cols <- grep("AantalInwoners|Inwoners", names(raw), value = TRUE, ignore.case = TRUE)

    cat("    Found WOZ cols:", paste(woz_cols, collapse = ", "), "\n")
    cat("    Rows:", nrow(raw), "\n")

    # Standard columns: RegioS contains the buurt code
    # WijkenEnBuurten is the code column in most tables
    code_col <- intersect(c("WijkenEnBuurten", "Codering_3", "RegioS"), names(raw))
    name_col <- intersect(c("Gemeentenaam_1", "Gemeentenaam"), names(raw))

    if (length(code_col) == 0) {
      cat("    WARNING: No region code column found. Columns:", head(names(raw), 20), "\n")
      return(NULL)
    }

    result <- raw %>%
      select(
        region_code = all_of(code_col[1]),
        any_of(c(name_col[1])),
        any_of(woz_cols),
        any_of(woning_cols),
        any_of(koop_cols),
        any_of(huur_cols),
        any_of(bevolking_cols)
      ) %>%
      mutate(year = as.integer(year))

    # Rename WOZ column to standard name
    if (length(woz_cols) > 0) {
      names(result)[names(result) == woz_cols[1]] <- "woz_avg"
    }
    if (length(woning_cols) > 0) {
      names(result)[names(result) == woning_cols[1]] <- "housing_stock"
    }
    if (length(koop_cols) > 0) {
      names(result)[names(result) == koop_cols[1]] <- "owner_occupied_pct"
    }
    if (length(bevolking_cols) > 0) {
      names(result)[names(result) == bevolking_cols[1]] <- "population"
    }

    # Filter to buurten only (code starts with "BU")
    result <- result %>%
      filter(grepl("^BU", trimws(region_code)))

    cat("    Buurten extracted:", nrow(result), "\n")
    return(result)

  }, error = function(e) {
    cat("    ERROR:", e$message, "\n")
    return(NULL)
  })
}

# Fetch each year
buurt_list <- list()
for (yr in names(cbs_tables)) {
  buurt_list[[yr]] <- fetch_cbs_year(cbs_tables[[yr]], yr)
  Sys.sleep(1)  # Rate limiting
}

# Check which years succeeded
success_years <- names(buurt_list)[!sapply(buurt_list, is.null)]
cat("\nSuccessfully fetched years:", paste(success_years, collapse = ", "), "\n")

if (length(success_years) < 4) {
  stop("FATAL: Could not fetch enough years of CBS data. Need at least 4 years.")
}

# Combine all years
buurt_panel <- bind_rows(buurt_list[success_years])
cat("Total buurt-year observations:", nrow(buurt_panel), "\n")

saveRDS(buurt_panel, file.path(data_dir, "buurt_panel_raw.rds"))

# ============================================================================
# 3. Buurt Geographic Boundaries from CBS/PDOK
# ============================================================================
cat("\n=== Fetching buurt shapefiles ===\n")

# CBS publishes buurt boundaries via their geo service
# Try the most recent year available
geo_urls <- c(
  "2023" = "https://service.pdok.nl/cbs/wijkenbuurten/2023/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=buurten&outputFormat=json&count=20000",
  "2022" = "https://service.pdok.nl/cbs/wijkenbuurten/2022/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=buurten&outputFormat=json&count=20000",
  "2021" = "https://service.pdok.nl/cbs/wijkenbuurten/2021/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=buurten&outputFormat=json&count=20000"
)

buurt_geo <- NULL
for (yr in names(geo_urls)) {
  cat("  Trying buurt boundaries", yr, "...\n")
  tryCatch({
    buurt_geo <- st_read(geo_urls[[yr]], quiet = TRUE)
    cat("  Success! Buurten:", nrow(buurt_geo), "\n")
    break
  }, error = function(e) {
    cat("  Failed:", e$message, "\n")
  })
}

if (is.null(buurt_geo)) {
  # Fallback: try direct GeoJSON download
  cat("  Trying fallback approach...\n")
  tryCatch({
    # Use a CQL filter to get only Groningen province buurten to reduce download size
    url <- paste0(
      "https://service.pdok.nl/cbs/wijkenbuurten/2022/wfs/v1_0",
      "?service=WFS&version=2.0.0&request=GetFeature",
      "&typeName=buurten&outputFormat=json",
      "&count=5000",
      "&CQL_FILTER=gemeentenaam%20LIKE%20%27%25%27"
    )
    buurt_geo <- st_read(url, quiet = TRUE)
    cat("  Fallback success! Buurten:", nrow(buurt_geo), "\n")
  }, error = function(e) {
    cat("  Fallback also failed:", e$message, "\n")
  })
}

if (!is.null(buurt_geo)) {
  saveRDS(buurt_geo, file.path(data_dir, "buurt_geo.rds"))
  cat("Buurt boundaries saved.\n")
} else {
  cat("WARNING: Could not fetch buurt boundaries. Will construct centroids from CBS data.\n")
}

# ============================================================================
# 4. Groningen Province Municipality List
# ============================================================================
cat("\n=== Identifying Groningen province municipalities ===\n")

# Groningen province municipalities (2023 municipal boundaries)
groningen_gemeenten <- c(
  "Groningen", "Het Hogeland", "Eemsdelta", "Midden-Groningen",
  "Oldambt", "Pekela", "Stadskanaal", "Veendam", "Westerwolde",
  "Westerkwartier"
)

# Also include adjacent Drenthe municipalities for boundary comparison
drenthe_border <- c(
  "Tynaarlo", "Aa en Hunze", "Borger-Odoorn", "Emmen",
  "Noordenveld", "Assen"
)

# And Friesland border municipalities
friesland_border <- c(
  "Noardeast-Fryslân", "Dantumadiel", "Achtkarspelen",
  "Smallingerland", "Opsterland", "Tytsjerksteradiel"
)

all_study_gemeenten <- c(groningen_gemeenten, drenthe_border, friesland_border)
cat("Study area municipalities:", length(all_study_gemeenten), "\n")
cat("Groningen:", length(groningen_gemeenten), "\n")
cat("Border (Drenthe + Friesland):", length(drenthe_border) + length(friesland_border), "\n")

saveRDS(
  list(
    groningen = groningen_gemeenten,
    drenthe_border = drenthe_border,
    friesland_border = friesland_border,
    all = all_study_gemeenten
  ),
  file.path(data_dir, "study_municipalities.rds")
)

cat("\n=== Data fetch complete ===\n")
cat("Files saved in:", normalizePath(data_dir), "\n")
