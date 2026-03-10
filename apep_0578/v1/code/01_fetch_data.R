## ============================================================================
## 01_fetch_data.R — Fetch NUTS3 regional data from Eurostat
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== Fetching Eurostat NUTS3 data ===\n")

# Helper: detect time column name (Eurostat R package uses TIME_PERIOD or time)
get_time_col <- function(df) {
  if ("TIME_PERIOD" %in% names(df)) return("TIME_PERIOD")
  if ("time" %in% names(df)) return("time")
  stop("No time column found. Columns: ", paste(names(df), collapse = ", "))
}

# Helper: extract geo + time + values from Eurostat tibble
extract_gtv <- function(df, geo_col = "geo") {
  tc <- get_time_col(df)
  out <- df[, c(geo_col, tc, "values")]
  names(out) <- c("geo_code", "year", "value")
  out$year <- as.integer(out$year)
  out <- out[!is.na(out$value), ]
  out
}

## ---------------------------------------------------------------------------
## 1. NUTS3 GDP (nama_10r_3gdp)
## ---------------------------------------------------------------------------
cat("Fetching NUTS3 GDP...\n")
gdp_raw <- tryCatch(
  get_eurostat("nama_10r_3gdp", time_format = "num"),
  error = function(e) stop("FATAL: Cannot fetch nama_10r_3gdp: ", e$message,
                            "\nEurostat API is unavailable. Cannot proceed.")
)

# Filter: EUR_HAB (EUR per inhabitant), current prices
gdp <- extract_gtv(gdp_raw[gdp_raw$unit == "EUR_HAB", ])
names(gdp) <- c("nuts3", "year", "gdp_pc")
cat("  GDP: ", nrow(gdp), " observations,", length(unique(gdp$nuts3)), "regions\n")

## ---------------------------------------------------------------------------
## 2. NUTS3 Employment (nama_10r_3empers)
## ---------------------------------------------------------------------------
cat("Fetching NUTS3 employment...\n")
emp_raw <- tryCatch(
  get_eurostat("nama_10r_3empers", time_format = "num"),
  error = function(e) stop("FATAL: Cannot fetch nama_10r_3empers: ", e$message)
)

# Filter: total employment (NACE_R2 = TOTAL), thousand persons
emp <- extract_gtv(emp_raw[emp_raw$nace_r2 == "TOTAL" & emp_raw$unit == "THS", ])
names(emp) <- c("nuts3", "year", "employment")
cat("  Employment: ", nrow(emp), " observations\n")

## ---------------------------------------------------------------------------
## 3. NUTS3 GVA by sector (nama_10r_3gva)
## ---------------------------------------------------------------------------
cat("Fetching NUTS3 GVA by sector...\n")
gva_raw <- tryCatch(
  get_eurostat("nama_10r_3gva", time_format = "num"),
  error = function(e) {
    warning("Could not fetch GVA data: ", e$message)
    NULL
  }
)

if (!is.null(gva_raw)) {
  # Check available NACE codes
  cat("  GVA NACE codes available:", paste(unique(gva_raw$nace_r2)[1:20], collapse = ", "), "...\n")

  # Unit is CP_MEUR (current prices, million EUR)
  gva_unit <- "CP_MEUR"
  # Total GVA
  gva_total_raw <- gva_raw[gva_raw$nace_r2 == "TOTAL" & gva_raw$unit == gva_unit, ]
  # Trade/transport/accommodation (G-I)
  gva_trade_raw <- gva_raw[gva_raw$nace_r2 %in% c("G-I", "GI", "G_I") & gva_raw$unit == gva_unit, ]
  # Manufacturing (C)
  gva_manuf_raw <- gva_raw[gva_raw$nace_r2 == "C" & gva_raw$unit == gva_unit, ]

  if (nrow(gva_total_raw) > 0) {
    gva_total <- extract_gtv(gva_total_raw)
    names(gva_total) <- c("nuts3", "year", "gva_total")
  } else { gva_total <- NULL }

  if (nrow(gva_trade_raw) > 0) {
    gva_trade <- extract_gtv(gva_trade_raw)
    names(gva_trade) <- c("nuts3", "year", "gva_trade_transport")
  } else { gva_trade <- NULL }

  if (nrow(gva_manuf_raw) > 0) {
    gva_manuf <- extract_gtv(gva_manuf_raw)
    names(gva_manuf) <- c("nuts3", "year", "gva_manufacturing")
  } else { gva_manuf <- NULL }

  cat("  GVA total:", ifelse(!is.null(gva_total), nrow(gva_total), 0), "obs\n")
  cat("  GVA trade/transport:", ifelse(!is.null(gva_trade), nrow(gva_trade), 0), "obs\n")
  cat("  GVA manufacturing:", ifelse(!is.null(gva_manuf), nrow(gva_manuf), 0), "obs\n")
} else {
  gva_total <- gva_trade <- gva_manuf <- NULL
  cat("  GVA: skipped (API error)\n")
}

## ---------------------------------------------------------------------------
## 4. Tourism overnight stays (tour_occ_nin2)
## ---------------------------------------------------------------------------
cat("Fetching tourism overnight stays...\n")
tour_raw <- tryCatch(
  get_eurostat("tour_occ_nin2", time_format = "num",
               filters = list(nace_r2 = "I551-I553", unit = "NR", c_resid = "TOTAL")),
  error = function(e) {
    warning("Could not fetch tourism data: ", e$message)
    NULL
  }
)

if (!is.null(tour_raw)) {
  tour <- extract_gtv(tour_raw)
  names(tour) <- c("nuts2", "year", "tourism_nights")
  cat("  Tourism: ", nrow(tour), " observations\n")
} else {
  tour <- NULL
  cat("  Tourism: skipped (API error)\n")
}

## ---------------------------------------------------------------------------
## 5. NUTS3 population (for weighting)
## ---------------------------------------------------------------------------
cat("Fetching NUTS3 population...\n")
pop_raw <- tryCatch(
  get_eurostat("demo_r_pjangrp3", time_format = "num",
               filters = list(sex = "T", age = "TOTAL")),
  error = function(e) {
    # Try alternative population dataset
    tryCatch(
      get_eurostat("demo_r_d3dens", time_format = "num"),
      error = function(e2) {
        warning("Could not fetch population data: ", e2$message)
        NULL
      }
    )
  }
)

if (!is.null(pop_raw)) {
  if ("age" %in% names(pop_raw)) {
    pop <- extract_gtv(pop_raw)
  } else {
    pop <- extract_gtv(pop_raw[pop_raw$unit == "PER_KM2", ])
  }
  names(pop) <- c("nuts3", "year", "population")
  cat("  Population: ", nrow(pop), " observations\n")
} else {
  pop <- NULL
  cat("  Population: skipped\n")
}

## ---------------------------------------------------------------------------
## 6. Save raw data
## ---------------------------------------------------------------------------
cat("\nSaving raw datasets...\n")

fwrite(as.data.table(gdp), file.path(data_dir, "nuts3_gdp.csv"))
fwrite(as.data.table(emp), file.path(data_dir, "nuts3_employment.csv"))

if (!is.null(gva_total)) fwrite(as.data.table(gva_total), file.path(data_dir, "nuts3_gva_total.csv"))
if (!is.null(gva_trade)) fwrite(as.data.table(gva_trade), file.path(data_dir, "nuts3_gva_trade.csv"))
if (!is.null(gva_manuf)) fwrite(as.data.table(gva_manuf), file.path(data_dir, "nuts3_gva_manufacturing.csv"))
if (!is.null(tour)) fwrite(as.data.table(tour), file.path(data_dir, "nuts2_tourism.csv"))
if (!is.null(pop)) fwrite(as.data.table(pop), file.path(data_dir, "nuts3_population.csv"))

## ---------------------------------------------------------------------------
## 7. Data validation
## ---------------------------------------------------------------------------
cat("\n=== Data Validation ===\n")

stopifnot("GDP data must have >100 NUTS3 regions" = length(unique(gdp$nuts3)) >= 100)
stopifnot("GDP data must span 2003-2020" = all(2003:2020 %in% unique(gdp$year)))
stopifnot("Employment data must exist" = nrow(emp) > 0)

# Check key border regions exist
key_regions <- c("AT111", "AT112", "DE213", "DE21D", "DK012", "SE224")
found <- sum(key_regions %in% unique(gdp$nuts3))
cat("Key border regions found in GDP data:", found, "of", length(key_regions), "\n")

cat("\nData validation PASSED.\n")
cat("GDP:", nrow(gdp), "rows,", length(unique(gdp$nuts3)), "NUTS3 regions,",
    length(unique(gdp$year)), "years (", min(gdp$year), "-", max(gdp$year), ")\n")
cat("Employment:", nrow(emp), "rows\n")

cat("\n01_fetch_data.R complete.\n")
