## 01_fetch_data.R — Fetch SESNSP municipal crime incidence data (monthly)
## apep_1156: Mexico AVGM and Domestic Violence Reporting

source("00_packages.R")

# -------------------------------------------------------------------
# 1. Download SESNSP municipal crime data from GitHub mirror
# -------------------------------------------------------------------
zip_url <- "https://raw.githubusercontent.com/lapanquecita/incidencia-delictiva/main/data/municipal.zip"
zip_path <- "../data/municipal.zip"
csv_path <- "../data/municipal.csv"

if (!file.exists(csv_path)) {
  cat("Downloading SESNSP municipal crime data...\n")
  download.file(zip_url, zip_path, mode = "wb", quiet = FALSE)
  unzip(zip_path, exdir = "../data/")
}

stopifnot("municipal.csv not found after download" = file.exists(csv_path))

raw <- fread(csv_path, encoding = "UTF-8")
stopifnot("Download returned empty data" = nrow(raw) > 0)
cat(sprintf("Loaded %d rows, %d columns\n", nrow(raw), ncol(raw)))

# -------------------------------------------------------------------
# 2. Standardize column names
# -------------------------------------------------------------------
setnames(raw, c("year", "state_code", "state_name", "mun_code", "mun_name",
                "legal_good", "crime_type", "crime_subtype", "modality",
                "jan", "feb", "mar", "apr", "may", "jun",
                "jul", "aug", "sep", "oct", "nov", "dec"))

# -------------------------------------------------------------------
# 3. Select crime categories of interest
# -------------------------------------------------------------------
# Map crime subtypes to our categories
crime_map <- data.table(
  crime_subtype = c("Violencia familiar",
                    "Feminicidio",
                    "Robo a casa habitación",
                    "Robo a negocio",
                    "Abuso sexual",
                    "Violación simple"),
  crime_cat = c("dv", "feminicide", "property_burglary", "property_business",
                "sexual_abuse", "rape")
)

# Filter to crimes of interest
crimes <- raw[crime_subtype %in% crime_map$crime_subtype]
crimes <- merge(crimes, crime_map, by = "crime_subtype", all.x = TRUE)

cat(sprintf("Filtered to %d rows across %d crime categories\n",
            nrow(crimes), uniqueN(crimes$crime_cat)))

# -------------------------------------------------------------------
# 4. Pivot to long format (one row per mun-year-month-crime)
# -------------------------------------------------------------------
month_cols <- c("jan", "feb", "mar", "apr", "may", "jun",
                "jul", "aug", "sep", "oct", "nov", "dec")

crimes_long <- melt(crimes,
                    id.vars = c("year", "state_code", "state_name",
                                "mun_code", "mun_name", "crime_cat"),
                    measure.vars = month_cols,
                    variable.name = "month_str",
                    value.name = "count")

# Convert month string to integer
month_lookup <- setNames(1:12, month_cols)
crimes_long[, month := month_lookup[month_str]]

# Aggregate across modalities within same crime subtype
# (e.g., homicidio doloso "con arma de fuego" + "con arma blanca" + ...)
panel <- crimes_long[, .(count = sum(count, na.rm = TRUE)),
                     by = .(year, month, state_code, state_name,
                            mun_code, mun_name, crime_cat)]

# Create yearmonth integer for panel
panel[, ym := year * 100 + month]

cat(sprintf("Panel: %d rows, %d municipalities, %d months, %d crime categories\n",
            nrow(panel), uniqueN(panel$mun_code),
            uniqueN(panel$ym), uniqueN(panel$crime_cat)))

# -------------------------------------------------------------------
# 5. Verify key crime categories
# -------------------------------------------------------------------
cat("\n--- Crime category totals ---\n")
cat_totals <- panel[, .(total = sum(count)), by = crime_cat]
print(cat_totals[order(-total)])

# -------------------------------------------------------------------
# 6. Save processed panel
# -------------------------------------------------------------------
fwrite(panel, "../data/crime_panel_monthly.csv")
cat("\nSaved monthly crime panel to data/crime_panel_monthly.csv\n")

# Also save state-level summary for quick checks
state_yr <- panel[crime_cat == "dv",
                  .(dv_total = sum(count)),
                  by = .(year, state_code, state_name)]
cat("\n--- DV cases by year (national) ---\n")
print(state_yr[, .(total_dv = sum(dv_total)), by = year][order(year)])
