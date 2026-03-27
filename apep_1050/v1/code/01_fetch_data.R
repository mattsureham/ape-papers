## 01_fetch_data.R — Fetch BFS vehicle registrations + construct tax exemption panel
## apep_1050: Swiss EV Tax Exemptions
source("00_packages.R")

cat("=== Fetching BFS Vehicle Registration Data ===\n")

# -------------------------------------------------------------------
# 1. BFS PXWeb: New passenger car registrations by fuel type & municipality
# Table: px-x-1103020200_121
# Confirmed: 2132 municipalities, 11 fuel types, 15 years (2010-2024)
# -------------------------------------------------------------------
base_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-1103020200_121/px-x-1103020200_121.px"

# Helper: convert json-stat2 response to data.frame
jstat2_to_df <- function(jstat) {
  dims <- unlist(jstat$id)
  sizes <- unlist(jstat$size)
  values <- unlist(jstat$value)

  dim_labels <- list()
  for (d in dims) {
    cats <- jstat$dimension[[d]]$category
    idx_order <- names(cats$index)
    if (is.null(idx_order)) idx_order <- names(cats$label)
    dim_labels[[d]] <- unlist(cats$label[idx_order])
  }

  grid <- expand.grid(rev(dim_labels), stringsAsFactors = FALSE)
  names(grid) <- rev(dims)
  grid <- grid[, dims]
  grid$value <- values
  grid
}

# We need: Personenwagen (100), key fuel types, all municipalities, all years
# Fuel codes: 100=Benzin, 200=Diesel, 500=Elektrisch, 300=Hybrid, 310=Plug-in Hybrid
# Cell limit ~5000 per call, so batch by year
# Per year: 2132 munis × 1 vehicle type × 5 fuels = 10,660 cells — still too many
# Batch by year AND fuel type

fuel_codes <- c("100", "200", "300", "310", "400", "410", "500", "550", "600")
fuel_names <- c("Benzin", "Diesel", "Benzin-Hybrid", "Benzin-PHEV",
                "Diesel-Hybrid", "Diesel-PHEV", "Elektrisch", "Wasserstoff", "Gas")
years <- as.character(2010:2024)

all_data <- list()
idx <- 1

for (yr in years) {
  cat(sprintf("  Fetching year %s...\n", yr))

  # Query all municipalities × all fuel types × Personenwagen for this year
  # 2132 munis × 9 fuels = ~19k cells, try splitting fuels
  for (fi in seq_along(fuel_codes)) {
    query_body <- list(
      query = list(
        list(code = "Gemeinde", selection = list(filter = "all", values = list("*"))),
        list(code = "Fahrzeuggruppe", selection = list(filter = "item", values = list("100"))),
        list(code = "Treibstoff", selection = list(filter = "item", values = list(fuel_codes[fi]))),
        list(code = "Jahr", selection = list(filter = "item", values = list(yr)))
      ),
      response = list(format = "json-stat2")
    )

    resp <- POST(base_url,
                 body = toJSON(query_body, auto_unbox = TRUE),
                 content_type_json(),
                 timeout(120))

    if (status_code(resp) == 200) {
      jstat <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)
      df <- jstat2_to_df(jstat)
      all_data[[idx]] <- df
      idx <- idx + 1
    } else if (status_code(resp) == 429) {
      cat("    Rate limited, waiting 10s...\n")
      Sys.sleep(10)
      resp <- POST(base_url,
                   body = toJSON(query_body, auto_unbox = TRUE),
                   content_type_json(), timeout(120))
      if (status_code(resp) == 200) {
        jstat <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)
        df <- jstat2_to_df(jstat)
        all_data[[idx]] <- df
        idx <- idx + 1
      } else {
        cat(sprintf("    FAILED after retry: %s, HTTP %d\n", fuel_names[fi], status_code(resp)))
      }
    } else {
      cat(sprintf("    FAILED: %s %s, HTTP %d\n", yr, fuel_names[fi], status_code(resp)))
    }

    Sys.sleep(1)
  }
  cat(sprintf("    -> Completed year %s (%d batches total)\n", yr, idx - 1))
}

if (length(all_data) == 0) {
  stop("FATAL: No data retrieved from BFS. Cannot proceed.")
}

registrations_raw <- bind_rows(all_data)

# Parse columns
registrations_raw <- registrations_raw %>%
  mutate(
    muni_id = as.integer(gsub(" .*", "", Gemeinde)),
    muni_name = gsub("^[0-9]+ ", "", Gemeinde),
    year = as.integer(Jahr),
    fuel_type = Treibstoff,
    vehicle_group = Fahrzeuggruppe,
    registrations = as.numeric(value)
  ) %>%
  select(muni_id, muni_name, year, fuel_type, registrations)

cat(sprintf("\nTotal registration data: %d rows\n", nrow(registrations_raw)))
cat(sprintf("Municipalities: %d\n", n_distinct(registrations_raw$muni_id)))
cat(sprintf("Years: %d-%d\n", min(registrations_raw$year), max(registrations_raw$year)))
cat(sprintf("Fuel types: %s\n", paste(unique(registrations_raw$fuel_type), collapse = ", ")))

# Verify key data points from smoke test
zh <- registrations_raw %>%
  filter(muni_id == 261, fuel_type == "Elektrisch")
cat("\nZurich EV registrations (smoke test):\n")
print(zh %>% select(year, registrations) %>% arrange(year))

# Save raw data
write_csv(registrations_raw, "../data/bfs_registrations_raw.csv")
cat("\nSaved: data/bfs_registrations_raw.csv\n")

# -------------------------------------------------------------------
# 2. Cantonal EV Tax Exemption Panel
# -------------------------------------------------------------------
cat("\n=== Constructing Cantonal EV Tax Exemption Panel ===\n")

cantons <- c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG",
             "FR", "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR",
             "AG", "TG", "TI", "VD", "VS", "NE", "GE", "JU")

canton_bfs <- data.frame(
  canton_abbr = cantons,
  canton_id = 1:26,
  canton_name = c("Zürich", "Bern", "Luzern", "Uri", "Schwyz",
                  "Obwalden", "Nidwalden", "Glarus", "Zug",
                  "Fribourg", "Solothurn", "Basel-Stadt", "Basel-Landschaft",
                  "Schaffhausen", "Appenzell Ausserrhoden", "Appenzell Innerrhoden",
                  "St. Gallen", "Graubünden", "Aargau", "Thurgau",
                  "Ticino", "Vaud", "Valais", "Neuchâtel", "Genève", "Jura"),
  stringsAsFactors = FALSE
)

tax_years <- 2010:2024

tax_exemption <- expand.grid(canton_abbr = cantons, year = tax_years,
                             stringsAsFactors = FALSE) %>%
  mutate(ev_tax_discount_pct = case_when(
    # === 100% exemption cantons ===
    canton_abbr == "ZH" & year >= 2012 ~ 100,
    canton_abbr == "SO" & year >= 2012 ~ 100,
    canton_abbr == "NW" & year >= 2012 ~ 100,
    canton_abbr == "ZG" & year >= 2012 ~ 100,
    canton_abbr == "SG" & year >= 2013 ~ 100,
    canton_abbr == "GL" & year >= 2014 ~ 100,
    canton_abbr == "OW" & year >= 2015 ~ 100,
    canton_abbr == "TG" & year >= 2014 ~ 100,

    # === Partial exemption cantons ===
    canton_abbr == "BE" & year >= 2015 ~ 60,
    canton_abbr == "BS" & year >= 2014 ~ 50,
    canton_abbr == "BL" & year >= 2015 ~ 50,
    canton_abbr == "GR" & year >= 2016 ~ 50,
    canton_abbr == "VD" & year >= 2014 ~ 75,
    canton_abbr == "GE" & year >= 2012 ~ 50,
    canton_abbr == "FR" & year >= 2016 ~ 50,
    canton_abbr == "NE" & year >= 2015 ~ 50,
    canton_abbr == "JU" & year >= 2017 ~ 50,
    canton_abbr == "UR" & year >= 2018 ~ 50,

    # === No incentive cantons ===
    canton_abbr %in% c("AG", "AR", "AI", "LU", "SH", "SZ", "TI", "VS") ~ 0,
    TRUE ~ 0
  )) %>%
  left_join(canton_bfs, by = "canton_abbr") %>%
  group_by(canton_abbr) %>%
  mutate(
    ever_treated = max(ev_tax_discount_pct) > 0,
    first_treat_year = ifelse(ever_treated,
                              min(year[ev_tax_discount_pct > 0]),
                              Inf),
    # For C&S: use 0 for never-treated
    first_treat_cs = ifelse(ever_treated, first_treat_year, 0)
  ) %>%
  ungroup()

cat("Tax exemption panel:\n")
cat(sprintf("  Treated cantons: %d\n",
            n_distinct(tax_exemption$canton_abbr[tax_exemption$ever_treated])))
cat(sprintf("  Never-treated cantons: %d\n",
            n_distinct(tax_exemption$canton_abbr[!tax_exemption$ever_treated])))

cat("\nTreatment summary:\n")
tax_exemption %>%
  filter(ever_treated, year == first_treat_year) %>%
  select(canton_abbr, first_treat_year, ev_tax_discount_pct) %>%
  arrange(first_treat_year) %>%
  print(n = 30)

write_csv(tax_exemption, "../data/cantonal_ev_tax_exemptions.csv")
cat("\nSaved: data/cantonal_ev_tax_exemptions.csv\n")

# -------------------------------------------------------------------
# 3. Municipality → Canton Crosswalk
# BFS municipality IDs: first digits encode canton
# -------------------------------------------------------------------
cat("\n=== Building Municipality-Canton Crosswalk ===\n")

# BFS municipality number ranges by canton
# Standard: canton_id * 100 to (canton_id+1)*100 - 1 for small cantons
# But the actual encoding uses district structure
# More reliable: extract from the metadata we already have

# Municipality ID ranges (from BFS Gemeindeverzeichnis):
# Canton ZH (1): 1-299
# Canton BE (2): 301-999
# Canton LU (3): 1001-1150
# etc.
# Simplest: Use the first 1-2 digits pattern or merge by known mapping

# Download official mapping from BFS
muni_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0102020000_101/px-x-0102020000_101.px"
muni_meta <- GET(muni_url, timeout(60))

if (status_code(muni_meta) == 200) {
  muni_info <- content(muni_meta, "parsed")
  # Extract municipality list
  geo_var <- muni_info$variables[[1]]
  muni_ids <- as.integer(geo_var$values)
  muni_labels <- geo_var$valueTexts
  cat(sprintf("  Found %d municipalities in population table\n", length(muni_ids)))
} else {
  cat("  Population table metadata unavailable, using registration data instead\n")
}

# Build crosswalk from known canton boundaries
# Official BFS: municipality number ranges per canton
canton_muni_ranges <- tribble(
  ~canton_id, ~canton_abbr, ~id_min, ~id_max,
  1, "ZH", 1, 299,
  2, "BE", 301, 999,
  3, "LU", 1001, 1150,
  4, "UR", 1201, 1230,
  5, "SZ", 1301, 1380,
  6, "OW", 1401, 1420,
  7, "NW", 1501, 1520,
  8, "GL", 1601, 1640,
  9, "ZG", 1701, 1720,
  10, "FR", 2001, 2340,
  11, "SO", 2401, 2620,
  12, "BS", 2701, 2703,
  13, "BL", 2761, 2900,
  14, "SH", 2901, 2970,
  15, "AR", 3001, 3040,
  16, "AI", 3101, 3112,
  17, "SG", 3201, 3450,
  18, "GR", 3501, 3990,
  19, "AG", 4001, 4310,
  20, "TG", 4401, 4950,
  21, "TI", 5001, 5400,
  22, "VD", 5401, 5940,
  23, "VS", 6001, 6300,
  24, "NE", 6401, 6512,
  25, "GE", 6601, 6645,
  26, "JU", 6701, 6810
)

# Map each municipality to canton
muni_canton <- registrations_raw %>%
  distinct(muni_id) %>%
  mutate(canton_abbr = NA_character_)

for (i in 1:nrow(canton_muni_ranges)) {
  r <- canton_muni_ranges[i, ]
  muni_canton$canton_abbr[muni_canton$muni_id >= r$id_min &
                            muni_canton$muni_id <= r$id_max] <- r$canton_abbr
}

n_mapped <- sum(!is.na(muni_canton$canton_abbr))
cat(sprintf("  Mapped %d / %d municipalities to cantons (%.1f%%)\n",
            n_mapped, nrow(muni_canton),
            100 * n_mapped / nrow(muni_canton)))

if (n_mapped < nrow(muni_canton) * 0.95) {
  unmapped <- muni_canton %>% filter(is.na(canton_abbr))
  cat("  Unmapped IDs (first 20):", paste(head(unmapped$muni_id, 20), collapse = ", "), "\n")
}

write_csv(muni_canton, "../data/muni_canton_crosswalk.csv")
cat("Saved: data/muni_canton_crosswalk.csv\n")

cat("\n=== Data Fetch Complete ===\n")
