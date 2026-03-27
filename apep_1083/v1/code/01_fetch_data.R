# 01_fetch_data.R — Fetch Swiss construction investment and second-home data
source("00_packages.R")

# Set working directory to paper root (parent of code/)
paper_root <- normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
if (file.exists(file.path(paper_root, "data"))) setwd(paper_root)
# Ensure data dir exists
dir.create("data", showWarnings = FALSE)

# ---------------------------------------------------------------
# 1) BFS PxWeb Table 203: Construction investment by municipality,
#    sector (12 categories), and year (1994-2023)
# ---------------------------------------------------------------
cat("=== Fetching BFS Construction Investment Data (Table 203) ===\n")

bfs_url <- "https://www.pxweb.bfs.admin.ch/api/v1/de/px-x-0904010000_203/px-x-0904010000_203.px"

# Get metadata
meta_resp <- GET(bfs_url, timeout(30))
stopifnot(meta_resp$status_code == 200)
meta <- content(meta_resp, as = "parsed")

vars <- meta$variables
geo_var <- vars[[1]]
auftr_var <- vars[[2]]
kat_var <- vars[[3]]
beob_var <- vars[[4]]
year_var <- vars[[5]]

years <- unlist(year_var$values)
muni_codes <- unlist(geo_var$values)
sector_codes <- unlist(kat_var$values)

# Filter to actual municipality codes (numeric, 4 digits)
muni_codes <- muni_codes[grepl("^[0-9]{3,4}$", muni_codes)]
cat(sprintf("Municipalities to fetch: %d\n", length(muni_codes)))
cat(sprintf("Years: %s to %s (%d)\n", min(years), max(years), length(years)))
cat(sprintf("Sectors: %d categories\n", length(sector_codes)))

# Sector lookup
sector_lookup <- setNames(unlist(kat_var$valueTexts), unlist(kat_var$values))
cat("Sector categories:\n")
for (i in seq_along(sector_codes)) {
  cat(sprintf("  %s: %s\n", sector_codes[i], sector_lookup[sector_codes[i]]))
}

# Fetch one year at a time, all municipalities, all sectors
# Per year: ~2100 munis * 12 sectors = ~25,200 cells (under typical PxWeb limits)
all_data <- list()

for (yr in years) {
  cat(sprintf("  Fetching %s...", yr))

  query_body <- list(
    query = list(
      list(
        code = geo_var$code,
        selection = list(filter = "item", values = as.list(muni_codes))
      ),
      list(
        code = auftr_var$code,
        selection = list(filter = "item", values = list("0"))
      ),
      list(
        code = kat_var$code,
        selection = list(filter = "all", values = list("*"))
      ),
      list(
        code = beob_var$code,
        selection = list(filter = "item", values = list("kost_j"))
      ),
      list(
        code = year_var$code,
        selection = list(filter = "item", values = list(yr))
      )
    ),
    response = list(format = "json")
  )

  resp <- POST(
    bfs_url,
    body = toJSON(query_body, auto_unbox = TRUE),
    content_type_json(),
    timeout(180)
  )

  if (resp$status_code != 200) {
    cat(sprintf(" FAILED (status %d)\n", resp$status_code))
    # Try with fewer municipalities (split in half)
    n <- length(muni_codes)
    half <- ceiling(n / 2)
    for (chunk_idx in 1:2) {
      chunk <- if (chunk_idx == 1) muni_codes[1:half] else muni_codes[(half+1):n]
      query_body$query[[1]]$selection$values <- as.list(chunk)
      resp2 <- POST(bfs_url, body = toJSON(query_body, auto_unbox = TRUE),
                     content_type_json(), timeout(180))
      if (resp2$status_code == 200) {
        parsed2 <- content(resp2, as = "parsed")
        rows2 <- lapply(parsed2$data, function(d) {
          data.frame(
            muni_code = d$key[[1]], sector_code = d$key[[3]],
            year = as.integer(d$key[[5]]),
            investment = as.numeric(d$values[[1]]),
            stringsAsFactors = FALSE
          )
        })
        all_data[[paste0(yr, "_", chunk_idx)]] <- bind_rows(rows2)
        cat(sprintf(" chunk%d:%d", chunk_idx, length(parsed2$data)))
      }
      Sys.sleep(0.3)
    }
    cat("\n")
    next
  }

  parsed <- content(resp, as = "parsed")
  n_cells <- length(parsed$data)
  cat(sprintf(" %d cells\n", n_cells))

  if (n_cells == 0) next

  rows <- lapply(parsed$data, function(d) {
    # Keys: geo, auftraggeber, sector, beobachtungseinheit, year
    data.frame(
      muni_code = d$key[[1]],
      sector_code = d$key[[3]],
      year = as.integer(d$key[[5]]),
      investment = as.numeric(d$values[[1]]),
      stringsAsFactors = FALSE
    )
  })

  all_data[[yr]] <- bind_rows(rows)
  Sys.sleep(0.3)
}

construction_raw <- bind_rows(all_data)
cat(sprintf("\nTotal construction records: %d rows\n", nrow(construction_raw)))

if (nrow(construction_raw) == 0) {
  stop("FATAL: No construction data retrieved from BFS. Cannot proceed.")
}

# Add sector names
construction_raw$sector_name <- sector_lookup[construction_raw$sector_code]

cat(sprintf("Unique municipalities: %d\n", n_distinct(construction_raw$muni_code)))
cat(sprintf("Year range: %d - %d\n", min(construction_raw$year), max(construction_raw$year)))
cat(sprintf("Non-NA investments: %d\n", sum(!is.na(construction_raw$investment))))

saveRDS(construction_raw, "data/construction_raw.rds")
saveRDS(sector_lookup, "data/sector_lookup.rds")
cat("Saved data/construction_raw.rds\n")

# ---------------------------------------------------------------
# 2) ARE Second-Home Shares via geo.admin.ch
# ---------------------------------------------------------------
cat("\n=== Fetching ARE Second-Home Shares ===\n")

# Try geo.admin.ch identify endpoint for the Zweitwohnungsanteil layer
# Query with the full Swiss bounding box
identify_url <- "https://api3.geo.admin.ch/rest/services/api/MapServer/identify"

id_resp <- GET(
  identify_url,
  query = list(
    geometry = "2485000,1075000,2834000,1296000",
    geometryType = "esriGeometryEnvelope",
    layers = "all:ch.are.wohnungsinventar-zweitwohnungsanteil",
    mapExtent = "2485000,1075000,2834000,1296000",
    imageDisplay = "1000,600,96",
    tolerance = 0,
    returnGeometry = "false",
    sr = 2056,
    limit = 5000
  ),
  timeout(120)
)

cat(sprintf("geo.admin.ch status: %d\n", id_resp$status_code))

zweitwohnung <- NULL

if (id_resp$status_code == 200) {
  id_data <- content(id_resp, as = "parsed")
  cat(sprintf("Features returned: %d\n", length(id_data$results)))

  if (length(id_data$results) > 0) {
    # Print first result to understand field names
    attrs <- id_data$results[[1]]$attributes
    cat("Field names:", paste(names(attrs), collapse = ", "), "\n")

    zweit_rows <- lapply(id_data$results, function(f) {
      a <- f$attributes
      # Try various field name patterns
      muni_id <- a$gde_no %||% a$bfs_nr %||% a$gemeindenummer %||%
                 a$gdeno %||% a$gdenr %||% NA_integer_
      muni_name <- a$gde_name %||% a$gemeindename %||% a$gdename %||% NA_character_
      canton <- a$kt_kz %||% a$kanton %||% a$kantonskuerzel %||% NA_character_
      share <- a$anteil_zweitwohnungen %||% a$zweitwohnungsanteil %||%
               a$anteil %||% a$share %||% NA_real_

      data.frame(
        muni_id = as.integer(muni_id),
        muni_name = as.character(muni_name),
        canton = as.character(canton),
        second_home_share = as.numeric(share),
        stringsAsFactors = FALSE
      )
    })
    zweitwohnung <- bind_rows(zweit_rows)
    cat(sprintf("Parsed %d municipality records\n", nrow(zweitwohnung)))
  }
}

# Fallback: search opendata.swiss
if (is.null(zweitwohnung) || nrow(zweitwohnung) < 100) {
  cat("Trying opendata.swiss...\n")

  # Search for ARE datasets about second homes
  search_terms <- c("Zweitwohnungsanteil", "Wohnungsinventar", "second homes")
  for (term in search_terms) {
    are_search <- GET(
      "https://ckan.opendata.swiss/api/3/action/package_search",
      query = list(q = term, rows = 5),
      timeout(30)
    )
    if (are_search$status_code == 200) {
      results <- content(are_search, as = "parsed")
      cat(sprintf("  '%s': %d results\n", term, results$result$count))
      for (r in results$result$results) {
        title <- r$title$de %||% r$title$en %||% r$name
        cat(sprintf("    %s\n", title))
        for (res in r$resources) {
          fmt <- toupper(res$format %||% "")
          url <- res$url %||% ""
          if (grepl("CSV|XLSX|JSON", fmt) && nchar(url) > 0) {
            cat(sprintf("      %s: %s\n", fmt, substr(url, 1, 100)))
            if (grepl("CSV", fmt) && is.null(zweitwohnung)) {
              tryCatch({
                temp <- tempfile(fileext = ".csv")
                download.file(url, temp, mode = "wb", quiet = TRUE)
                df <- tryCatch(read_csv(temp, show_col_types = FALSE),
                               error = function(e) read_delim(temp, delim = ";", show_col_types = FALSE))
                cat(sprintf("      -> %d rows, cols: %s\n", nrow(df), paste(names(df), collapse=", ")))
                if (nrow(df) > 100) {
                  zweitwohnung <- df
                }
              }, error = function(e) cat(sprintf("      Error: %s\n", e$message)))
            }
          }
        }
      }
    }
  }
}

# If still nothing, construct the treatment variable from the official ARE list
# The official list of municipalities exceeding 20% is published as a federal ordinance
# (Verzeichnis der Gemeinden mit einem Zweitwohnungsanteil von über 20 Prozent)
if (is.null(zweitwohnung) || nrow(zweitwohnung) < 100) {
  cat("\nConstructing treatment from official ARE Gemeindeliste...\n")
  # The ARE publishes a JSON/CSV of municipalities and their status
  # Try the REST API for the specific layer
  layer_url <- "https://api3.geo.admin.ch/rest/services/api/MapServer/ch.are.wohnungsinventar-zweitwohnungsanteil"
  layer_resp <- GET(layer_url, timeout(30))
  if (layer_resp$status_code == 200) {
    layer_meta <- content(layer_resp, as = "parsed")
    cat("  Layer metadata:\n")
    cat(sprintf("    name: %s\n", layer_meta$name %||% "?"))
    cat(sprintf("    description: %s\n", substr(layer_meta$description %||% "?", 1, 200)))

    # Try to get all features via the layer's query endpoint
    query_url <- paste0(layer_url, "/query")
    q_resp <- GET(query_url,
      query = list(where = "1=1", outFields = "*", f = "json", returnGeometry = "false"),
      timeout(60))
    if (q_resp$status_code == 200) {
      q_data <- content(q_resp, as = "parsed")
      if (!is.null(q_data$features)) {
        cat(sprintf("  Query returned %d features\n", length(q_data$features)))
      }
    }
  }
}

if (!is.null(zweitwohnung) && nrow(zweitwohnung) > 10) {
  saveRDS(zweitwohnung, "data/zweitwohnung.rds")
  cat(sprintf("\nSaved data/zweitwohnung.rds (%d municipalities)\n", nrow(zweitwohnung)))
} else {
  cat("\nWARNING: Zweitwohnung data requires alternative approach.\n")
  cat("Will construct in 02_clean_data.R using BFS GWS dwelling data.\n")
}

cat("\n=== Data Fetch Complete ===\n")
cat("Files:", paste(list.files("data/", pattern = "\\.rds$"), collapse = ", "), "\n")
