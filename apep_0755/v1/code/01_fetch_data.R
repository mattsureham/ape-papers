## =============================================================================
## 01_fetch_data.R — Fetch ICFES Saber 11 student data from datos.gov.co
## Paper: Estrato Boundaries and Educational Sorting in Colombia (apep_0755)
## =============================================================================

source("00_packages.R")

cat("=== Fetching ICFES Saber 11 data from datos.gov.co ===\n")

BASE_URL <- "https://www.datos.gov.co/resource/kgxf-xxbe.json"

## Fetch by city-period combination to avoid large single queries
fetch_batch <- function(city, periodo, offset = 0, limit = 50000) {
  where <- sprintf("cole_mcpio_ubicacion='%s' AND periodo='%s'", city, periodo)
  params <- list(
    `$limit`  = as.integer(limit),
    `$offset` = as.integer(offset),
    `$where`  = where,
    `$order`  = "estu_consecutivo"
  )

  resp <- tryCatch(
    GET(BASE_URL, query = params, timeout(90)),
    error = function(e) {
      cat(sprintf("    Error: %s\n", e$message))
      return(NULL)
    }
  )

  if (is.null(resp) || status_code(resp) != 200) return(NULL)
  content_text <- content(resp, as = "text", encoding = "UTF-8")
  records <- tryCatch(
    fromJSON(content_text, flatten = TRUE),
    error = function(e) { cat(sprintf("    JSON parse error: %s\n", e$message)); NULL }
  )
  if (is.null(records)) return(NULL)
  if (!is.data.frame(records) || nrow(records) == 0) return(NULL)
  return(as.data.table(records))
}

## Check if data already on disk
if (file.exists("../data/icfes_raw.csv")) {
  df_raw <- fread("../data/icfes_raw.csv")
  if (nrow(df_raw) >= 500000) {
    cat(sprintf("Found existing data: %s rows. Skipping fetch.\n",
                format(nrow(df_raw), big.mark = ",")))
  } else {
    cat(sprintf("Existing data too small (%s rows). Re-fetching.\n",
                format(nrow(df_raw), big.mark = ",")))
    df_raw <- NULL
  }
} else {
  df_raw <- NULL
}

if (is.null(df_raw)) {
  ## City names in the API
  cities <- c("BOGOTÁ D.C.", "BOGOTÁ, D.C.", "CALI", "MEDELLÍN", "MEDELLIN",
              "BARRANQUILLA", "CARTAGENA DE INDIAS")

  ## Main exam periods (large cohorts only)
  periodos <- c("20224", "20194", "20172", "20162", "20152", "20142", "20132",
                "20122", "20112")

  all_data <- list()
  idx <- 1

  for (city in cities) {
    for (per in periodos) {
      cat(sprintf("Fetching %s / %s...\n", city, per))
      offset <- 0

      while (TRUE) {
        batch <- fetch_batch(city, per, offset = offset)
        if (is.null(batch) || nrow(batch) == 0) break

        all_data[[idx]] <- batch
        cat(sprintf("  offset=%s: %d records\n", format(offset, big.mark = ","), nrow(batch)))
        idx <- idx + 1

        if (nrow(batch) < 50000) break
        offset <- offset + 50000
        Sys.sleep(0.3)
      }
      Sys.sleep(0.2)

      ## Save partial data periodically
      if (idx %% 20 == 0) {
        partial <- rbindlist(all_data, fill = TRUE)
        fwrite(partial, "../data/icfes_raw_partial.csv")
        cat(sprintf("  [Checkpoint: %s records saved]\n",
                    format(nrow(partial), big.mark = ",")))
      }
    }
  }

  df_raw <- rbindlist(all_data, fill = TRUE)
  cat(sprintf("\nTotal records fetched: %s\n", format(nrow(df_raw), big.mark = ",")))

  fwrite(df_raw, "../data/icfes_raw.csv")
  cat("Saved raw data to disk.\n")
}

## Validate
stopifnot("No data fetched from ICFES API" = nrow(df_raw) > 0)
stopifnot("Missing estrato field" = "fami_estratovivienda" %in% names(df_raw))
stopifnot("Missing global score" = "punt_global" %in% names(df_raw))

cat(sprintf("\nEstrato distribution:\n"))
print(table(df_raw$fami_estratovivienda, useNA = "always"))

cat(sprintf("\nMunicipality distribution:\n"))
print(table(df_raw$cole_mcpio_ubicacion, useNA = "always"))

cat(sprintf("\nPeriod distribution:\n"))
print(table(df_raw$periodo, useNA = "always"))

cat(sprintf("\nFinal: %s rows, %d columns\n",
            format(nrow(df_raw), big.mark = ","), ncol(df_raw)))
