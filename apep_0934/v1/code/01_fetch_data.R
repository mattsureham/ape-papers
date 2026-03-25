# 01_fetch_data.R — Data acquisition for apep_0934
# Community wind ownership and NIMBYism in Denmark
# Sources: Energidataservice (wind capacity), DST StatBank (property, elections, population)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. ENERGIDATASERVICE — Onshore wind capacity by municipality (monthly)
# ============================================================================
cat("=== Fetching onshore wind capacity per municipality ===\n")

# Fetch all records from CapacityPerMunicipality (12,573 total)
# API returns max 10,000 per request, so paginate
all_records <- list()
offset <- 0
batch_size <- 5000

repeat {
  url <- sprintf(
    "https://api.energidataservice.dk/dataset/CapacityPerMunicipality?limit=%d&offset=%d&sort=Month%%20asc",
    batch_size, offset
  )
  resp <- httr::GET(url, httr::timeout(60))
  stopifnot("Energidataservice fetch failed" = httr::status_code(resp) == 200)

  content <- httr::content(resp, as = "parsed")
  records <- content$records
  cat(sprintf("  Batch at offset %d: %d records\n", offset, length(records)))

  if (length(records) == 0) break

  # Convert to data frame
  batch_df <- do.call(rbind, lapply(records, function(r) {
    data.frame(
      month = as.character(r$Month),
      municipality_no = as.character(r$MunicipalityNo),
      onshore_wind_mw = ifelse(is.null(r$OnshoreWindCapacity), NA_real_, as.numeric(r$OnshoreWindCapacity)),
      n_onshore_turbines = ifelse(is.null(r$NumberOnshoreWindGenerators), NA_integer_, as.integer(r$NumberOnshoreWindGenerators)),
      solar_mw = ifelse(is.null(r$SolarPowerCapacity), NA_real_, as.numeric(r$SolarPowerCapacity)),
      offshore_wind_mw = ifelse(is.null(r$OffshoreWindCapacity), NA_real_, as.numeric(r$OffshoreWindCapacity)),
      stringsAsFactors = FALSE
    )
  }))

  all_records[[length(all_records) + 1]] <- batch_df
  offset <- offset + batch_size

  if (length(records) < batch_size) break
}

wind_df <- do.call(rbind, all_records)
wind_df$month <- as.Date(substr(wind_df$month, 1, 10))
wind_df$year <- as.integer(format(wind_df$month, "%Y"))

cat(sprintf("  Total wind records: %d\n", nrow(wind_df)))
cat(sprintf("  Date range: %s to %s\n", min(wind_df$month), max(wind_df$month)))
cat(sprintf("  Municipalities: %d\n", length(unique(wind_df$municipality_no))))

# Replace NA with 0 for capacity columns
wind_df$onshore_wind_mw[is.na(wind_df$onshore_wind_mw)] <- 0
wind_df$n_onshore_turbines[is.na(wind_df$n_onshore_turbines)] <- 0

saveRDS(wind_df, file.path(data_dir, "wind_capacity.rds"))

# Quick summary: municipalities with onshore wind as of Jan 2020
wind_2020 <- wind_df[wind_df$month == as.Date("2020-01-01"), ]
cat(sprintf("  Municipalities with onshore wind (Jan 2020): %d of %d\n",
            sum(wind_2020$onshore_wind_mw > 0, na.rm = TRUE), nrow(wind_2020)))

# ============================================================================
# 2. DST StatBank — EJEN5: Property sales by municipality
# ============================================================================
cat("\n=== Fetching DST property data ===\n")

# First check EJEN5 metadata (property sales stats)
meta_url <- "https://api.statbank.dk/v1/tableinfo"

# Try EJEN5 (property sale prices)
ejen5_meta <- httr::POST(meta_url,
                         body = list(table = "EJEN5", format = "JSON"),
                         encode = "json", httr::timeout(60))

if (httr::status_code(ejen5_meta) == 200) {
  meta <- httr::content(ejen5_meta, as = "text", encoding = "UTF-8")
  meta <- jsonlite::fromJSON(meta, simplifyVector = FALSE)
  cat("  EJEN5 variables:\n")
  for (v in meta$variables) {
    cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
  }

  # Fetch: all municipalities, sale price per m2, single-family houses, all quarters
  ejen5_body <- list(
    table = "EJEN5",
    format = "CSV",
    delimiter = "Semicolon",
    variables = list(
      list(code = "EJENDOMSKAT", values = list("20")),  # Single-family houses
      list(code = "Tid", values = list("*")),
      list(code = "KOMMUNE", values = list("*"))
    )
  )

  ejen5_resp <- httr::POST("https://api.statbank.dk/v1/data",
                           body = ejen5_body, encode = "json",
                           httr::timeout(120))
  if (httr::status_code(ejen5_resp) == 200) {
    ejen5_text <- httr::content(ejen5_resp, as = "text", encoding = "UTF-8")
    ejen5_df <- read.csv(text = ejen5_text, sep = ";", stringsAsFactors = FALSE)
    cat(sprintf("  EJEN5 rows: %d\n", nrow(ejen5_df)))
    cat(sprintf("  EJEN5 columns: %s\n", paste(names(ejen5_df), collapse = ", ")))
    if (nrow(ejen5_df) > 0) cat(sprintf("  Sample: %s\n", paste(head(ejen5_df, 2), collapse = " | ")))
    saveRDS(ejen5_df, file.path(data_dir, "ejen5_raw.rds"))
  } else {
    cat(sprintf("  EJEN5 data fetch failed: %d\n", httr::status_code(ejen5_resp)))
  }
} else {
  cat("  EJEN5 not available\n")
}

# Also try BM010: Property values (public assessment)
bm_meta <- httr::POST(meta_url,
                      body = list(table = "BM010", format = "JSON"),
                      encode = "json", httr::timeout(60))
if (httr::status_code(bm_meta) == 200) {
  meta_bm <- jsonlite::fromJSON(httr::content(bm_meta, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
  cat("\n  BM010 variables:\n")
  for (v in meta_bm$variables) {
    cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
  }
}

# Try EJDFOE1 (property wealth by municipality)
ejdfoe1_meta <- httr::POST(meta_url,
                           body = list(table = "EJDFOE1", format = "JSON"),
                           encode = "json", httr::timeout(60))
if (httr::status_code(ejdfoe1_meta) == 200) {
  meta_ej <- jsonlite::fromJSON(httr::content(ejdfoe1_meta, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
  cat("\n  EJDFOE1 variables:\n")
  for (v in meta_ej$variables) {
    cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
    if (length(v$values) <= 20) {
      for (val in v$values) {
        cat(sprintf("      %s: %s\n", val$id, val$text))
      }
    }
  }

  # Fetch total property values by municipality × year
  ejd_body <- list(
    table = "EJDFOE1",
    format = "CSV",
    delimiter = "Semicolon",
    variables = list(
      list(code = "KOMMUNE", values = list("*")),
      list(code = "EJDTYPE", values = list("100")),
      list(code = "TID", values = list("*"))
    )
  )

  ejd_resp <- httr::POST("https://api.statbank.dk/v1/data",
                         body = ejd_body, encode = "json",
                         httr::timeout(120))
  if (httr::status_code(ejd_resp) == 200) {
    ejd_text <- httr::content(ejd_resp, as = "text", encoding = "UTF-8")
    ejd_df <- read.csv(text = ejd_text, sep = ";", stringsAsFactors = FALSE)
    cat(sprintf("  EJDFOE1 rows: %d\n", nrow(ejd_df)))
    cat(sprintf("  EJDFOE1 columns: %s\n", paste(names(ejd_df), collapse = ", ")))
    saveRDS(ejd_df, file.path(data_dir, "ejdfoe1_raw.rds"))
  } else {
    cat(sprintf("  EJDFOE1 fetch failed: %d\n", httr::status_code(ejd_resp)))
  }
}

# ============================================================================
# 3. DST StatBank — VALGK3: Municipal election results
# ============================================================================
cat("\n=== Fetching municipal election data ===\n")

# Try VALGK3
valgk3_meta <- httr::POST(meta_url,
                          body = list(table = "VALGK3", format = "JSON"),
                          encode = "json", httr::timeout(60))

election_table <- NULL
if (httr::status_code(valgk3_meta) == 200) {
  meta_v <- jsonlite::fromJSON(httr::content(valgk3_meta, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
  cat("  VALGK3 variables:\n")
  for (v in meta_v$variables) {
    cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
    if (v$id == "PARTI" && length(v$values) <= 30) {
      for (val in v$values) {
        cat(sprintf("      %s: %s\n", val$id, val$text))
      }
    }
  }
  election_table <- "VALGK3"
} else {
  cat("  VALGK3 not available, trying KVRES\n")
  kvres_meta <- httr::POST(meta_url,
                           body = list(table = "KVRES", format = "JSON"),
                           encode = "json", httr::timeout(60))
  if (httr::status_code(kvres_meta) == 200) {
    meta_kv <- jsonlite::fromJSON(httr::content(kvres_meta, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
    cat("  KVRES variables:\n")
    for (v in meta_kv$variables) {
      cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
    }
    election_table <- "KVRES"
  }
}

if (!is.null(election_table)) {
  # Fetch all parties, municipalities, years
  elec_body <- list(
    table = election_table,
    format = "CSV",
    delimiter = "Semicolon",
    variables = list(
      list(code = "KOMMUNE", values = list("*")),
      list(code = "PARTI", values = list("*")),
      list(code = "TID", values = list("*"))
    )
  )

  elec_resp <- httr::POST("https://api.statbank.dk/v1/data",
                          body = elec_body, encode = "json",
                          httr::timeout(120))
  if (httr::status_code(elec_resp) == 200) {
    elec_text <- httr::content(elec_resp, as = "text", encoding = "UTF-8")
    elec_df <- read.csv(text = elec_text, sep = ";", stringsAsFactors = FALSE)
    cat(sprintf("  %s rows: %d\n", election_table, nrow(elec_df)))
    cat(sprintf("  Columns: %s\n", paste(names(elec_df), collapse = ", ")))
    saveRDS(elec_df, file.path(data_dir, "elections_raw.rds"))
  }
} else {
  stop("No election data table available")
}

# ============================================================================
# 4. DST StatBank — FOLK1A: Population by municipality (quarterly)
# ============================================================================
cat("\n=== Fetching population data ===\n")

folk_meta <- httr::POST(meta_url,
                        body = list(table = "FOLK1A", format = "JSON"),
                        encode = "json", httr::timeout(60))
if (httr::status_code(folk_meta) == 200) {
  meta_f <- jsonlite::fromJSON(httr::content(folk_meta, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
  cat("  FOLK1A variables:\n")
  for (v in meta_f$variables) {
    cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
  }

  # Fetch total population by municipality (all quarters)
  # Only get total (no breakdown by age/sex)
  folk_body <- list(
    table = "FOLK1A",
    format = "CSV",
    delimiter = "Semicolon",
    variables = list(
      list(code = "OMRÅDE", values = list("*")),
      list(code = "TID", values = list("*"))
    )
  )

  folk_resp <- httr::POST("https://api.statbank.dk/v1/data",
                          body = folk_body, encode = "json",
                          httr::timeout(180))
  if (httr::status_code(folk_resp) == 200) {
    folk_text <- httr::content(folk_resp, as = "text", encoding = "UTF-8")
    folk_df <- read.csv(text = folk_text, sep = ";", stringsAsFactors = FALSE)
    cat(sprintf("  FOLK1A rows: %d\n", nrow(folk_df)))
    saveRDS(folk_df, file.path(data_dir, "population_raw.rds"))
  }
} else {
  cat("  FOLK1A not available\n")
}

# ============================================================================
# 5. DST StatBank — INDKP106: Income by municipality
# ============================================================================
cat("\n=== Fetching income data ===\n")

inc_meta <- httr::POST(meta_url,
                       body = list(table = "INDKP106", format = "JSON"),
                       encode = "json", httr::timeout(60))
if (httr::status_code(inc_meta) == 200) {
  meta_i <- jsonlite::fromJSON(httr::content(inc_meta, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
  cat("  INDKP106 variables:\n")
  for (v in meta_i$variables) {
    cat(sprintf("    %s (%s): %d values\n", v$id, v$text, length(v$values)))
    if (v$id == "ENHED" && length(v$values) <= 20) {
      for (val in v$values) {
        cat(sprintf("      %s: %s\n", val$id, val$text))
      }
    }
  }

  # Fetch average income per person by municipality
  inc_body <- list(
    table = "INDKP106",
    format = "CSV",
    delimiter = "Semicolon",
    variables = list(
      list(code = "KOMMUNE", values = list("*")),
      list(code = "ENHED", values = list("116")),
      list(code = "TID", values = list("*"))
    )
  )

  inc_resp <- httr::POST("https://api.statbank.dk/v1/data",
                         body = inc_body, encode = "json",
                         httr::timeout(120))
  if (httr::status_code(inc_resp) == 200) {
    inc_text <- httr::content(inc_resp, as = "text", encoding = "UTF-8")
    inc_df <- read.csv(text = inc_text, sep = ";", stringsAsFactors = FALSE)
    cat(sprintf("  INDKP106 rows: %d\n", nrow(inc_df)))
    saveRDS(inc_df, file.path(data_dir, "income_raw.rds"))
  }
} else {
  cat("  INDKP106 not available\n")
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data acquisition complete ===\n")
files <- list.files(data_dir, pattern = "\\.rds$")
cat(sprintf("Saved %d files: %s\n", length(files), paste(files, collapse = ", ")))
