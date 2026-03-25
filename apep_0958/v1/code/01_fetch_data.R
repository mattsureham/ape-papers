## 01_fetch_data.R — Fetch all data from Dutch open APIs
## apep_0958: Dutch Nitrogen Ruling and Populist Backlash

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

if (!requireNamespace("cbsodataR", quietly = TRUE)) {
  install.packages("cbsodataR", repos = "https://cloud.r-project.org", quiet = TRUE)
}
library(cbsodataR)

## ============================================================
## 1. CBS: Building Permits by Municipality (83671NED)
## ============================================================
cat("=== 1. Fetching CBS building permits ===\n")

if (!file.exists(file.path(data_dir, "cbs_permits_full.rds"))) {
  permits_df <- cbs_get_data("83671NED")
  saveRDS(permits_df, file.path(data_dir, "cbs_permits_full.rds"))
  cat(sprintf("  Permits: %d rows\n", nrow(permits_df)))
} else {
  cat("  Already fetched.\n")
}

## ============================================================
## 2. CBS: Population — use 37230NED (smaller, annual, by muni)
## ============================================================
cat("\n=== 2. Fetching CBS population (37230NED) ===\n")

if (!file.exists(file.path(data_dir, "cbs_population.rds"))) {
  # 37230NED: Regionale kerncijfers Nederland (regional key figures)
  # Contains population, area, and other useful municipality-level data
  # This is a compact table with one row per municipality per year
  pop_df <- cbs_get_data("70072NED")  # Regionale kerncijfers: bevolking
  saveRDS(pop_df, file.path(data_dir, "cbs_population.rds"))
  cat(sprintf("  Population: %d rows\n", nrow(pop_df)))
} else {
  cat("  Already fetched.\n")
}

## ============================================================
## 3. CBS: Employment by municipality & sector
## ============================================================
cat("\n=== 3. Fetching CBS employment ===\n")

if (!file.exists(file.path(data_dir, "cbs_employment.rds"))) {
  # 84312NED: Banen van werknemers; bedrijfstak, regio
  emp_df <- tryCatch({
    cbs_get_data("84312NED")
  }, error = function(e) {
    cat(sprintf("  84312NED: %s\n", e$message))
    cat("  Trying 83583NED...\n")
    cbs_get_data("83583NED")
  })
  saveRDS(emp_df, file.path(data_dir, "cbs_employment.rds"))
  cat(sprintf("  Employment: %d rows\n", nrow(emp_df)))
} else {
  cat("  Already fetched.\n")
}

## ============================================================
## 4. Kiesraad: Election data
##    Use CBS table for Provinciale Staten results
## ============================================================
cat("\n=== 4. Fetching election data ===\n")

if (!file.exists(file.path(data_dir, "cbs_elections.rds"))) {
  # Try Kiesraad verkiezingsuitslagen CSV first (more granular)
  # Kiesraad provides open data at https://www.kiesraad.nl/verkiezingen/provinciale-statenverkiezingen/uitslagen
  # Alternative: scrape from verkiezingsuitslagen.nl

  # Let's use CBS table 85734NED or search for available election tables
  cat("  Searching for CBS election tables...\n")
  tables <- cbs_search("provinciale statenverkiezingen", language = "nl")
  if (nrow(tables) > 0) {
    cat(sprintf("  Found %d CBS election tables\n", nrow(tables)))
    cat("  IDs:", paste(tables$Identifier[1:min(5, nrow(tables))], collapse = ", "), "\n")
    cat("  Titles:", paste(tables$ShortTitle[1:min(5, nrow(tables))], collapse = "; "), "\n")

    # Try the first match
    elec_df <- tryCatch({
      cbs_get_data(tables$Identifier[1])
    }, error = function(e) {
      cat(sprintf("  First table failed: %s\n", e$message))
      NULL
    })
    if (!is.null(elec_df)) {
      saveRDS(elec_df, file.path(data_dir, "cbs_elections.rds"))
      cat(sprintf("  Elections: %d rows\n", nrow(elec_df)))
    }
  }

  # If CBS doesn't have it, fetch from Kiesraad directly
  if (!file.exists(file.path(data_dir, "cbs_elections.rds"))) {
    cat("  No CBS table found. Fetching from Kiesraad API...\n")

    # Kiesraad open data portal
    # 2023 PS results via data.overheid.nl
    urls <- c(
      ps2023 = "https://data.overheid.nl/sites/default/files/dataset/a3dd6c4d-dd87-439e-a057-f5c03dda7f93/resources/Telling_PS2023_gemeente.csv",
      ps2019 = "https://data.overheid.nl/sites/default/files/dataset/3be8f0a6-4413-4c0c-aaff-e0833a4b6524/resources/Telling_PS2019_gemeente.csv"
    )

    for (nm in names(urls)) {
      resp <- tryCatch(GET(urls[[nm]], timeout(60)), error = function(e) NULL)
      if (!is.null(resp) && resp$status_code == 200) {
        writeBin(content(resp, "raw"), file.path(data_dir, paste0("kiesraad_", nm, ".csv")))
        cat(sprintf("  %s downloaded\n", nm))
      } else {
        cat(sprintf("  %s: not available at this URL\n", nm))
      }
    }
  }
} else {
  cat("  Already fetched.\n")
}

## ============================================================
## 5. PDOK: Natura 2000 shapefiles
## ============================================================
cat("\n=== 5. Fetching Natura 2000 shapefiles ===\n")

if (!file.exists(file.path(data_dir, "natura2000_sf.rds"))) {
  n2k_url <- "https://service.pdok.nl/rvo/natura2000/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=natura2000:natura2000&outputFormat=application%2Fjson&count=500"

  resp <- tryCatch(GET(n2k_url, timeout(120)), error = function(e) {
    cat(sprintf("  N2K error: %s\n", e$message))
    NULL
  })

  if (!is.null(resp) && resp$status_code == 200) {
    writeBin(content(resp, "raw"), file.path(data_dir, "natura2000.geojson"))
    n2k_sf <- st_read(file.path(data_dir, "natura2000.geojson"), quiet = TRUE)
    saveRDS(n2k_sf, file.path(data_dir, "natura2000_sf.rds"))
    cat(sprintf("  Natura 2000: %d sites\n", nrow(n2k_sf)))
  } else {
    # Try without output format specification
    n2k_alt <- "https://service.pdok.nl/rvo/natura2000/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=natura2000:natura2000&count=200"
    resp2 <- tryCatch(GET(n2k_alt, timeout(120)), error = function(e) NULL)
    if (!is.null(resp2) && resp2$status_code == 200) {
      writeBin(content(resp2, "raw"), file.path(data_dir, "natura2000.gml"))
      n2k_sf <- st_read(file.path(data_dir, "natura2000.gml"), quiet = TRUE)
      saveRDS(n2k_sf, file.path(data_dir, "natura2000_sf.rds"))
      cat(sprintf("  Natura 2000 (GML): %d sites\n", nrow(n2k_sf)))
    } else {
      stop("FATAL: Cannot fetch Natura 2000 data from PDOK.")
    }
  }
} else {
  cat("  Already fetched.\n")
}

## ============================================================
## 6. PDOK: Municipality boundaries (2019)
## ============================================================
cat("\n=== 6. Fetching municipality boundaries ===\n")

if (!file.exists(file.path(data_dir, "municipalities_sf.rds"))) {
  # Try multiple PDOK WFS type names
  type_names <- c(
    "gemeenten",
    "cbs_gemeente_2019_gegeneraliseerd",
    "gemeente_gegeneraliseerd"
  )

  success <- FALSE
  for (tn in type_names) {
    muni_url <- sprintf(
      "https://service.pdok.nl/cbs/wijkenbuurten/2019/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=%s&outputFormat=application%%2Fjson&count=400",
      tn
    )
    resp <- tryCatch(GET(muni_url, timeout(120)), error = function(e) NULL)
    if (!is.null(resp) && resp$status_code == 200) {
      writeBin(content(resp, "raw"), file.path(data_dir, "municipalities_2019.geojson"))
      muni_sf <- tryCatch(
        st_read(file.path(data_dir, "municipalities_2019.geojson"), quiet = TRUE),
        error = function(e) NULL
      )
      if (!is.null(muni_sf) && nrow(muni_sf) > 0) {
        saveRDS(muni_sf, file.path(data_dir, "municipalities_sf.rds"))
        cat(sprintf("  Municipalities (%s): %d features\n", tn, nrow(muni_sf)))
        success <- TRUE
        break
      }
    }
    cat(sprintf("  TypeName '%s' didn't work, trying next...\n", tn))
  }

  if (!success) {
    # Fallback: use 2023 boundaries or generic
    cat("  Trying 2023 boundaries as fallback...\n")
    muni_url_23 <- "https://service.pdok.nl/cbs/wijkenbuurten/2023/wfs/v1_0?service=WFS&version=2.0.0&request=GetFeature&typeName=gemeenten&outputFormat=application%2Fjson&count=400"
    resp23 <- tryCatch(GET(muni_url_23, timeout(120)), error = function(e) NULL)
    if (!is.null(resp23) && resp23$status_code == 200) {
      writeBin(content(resp23, "raw"), file.path(data_dir, "municipalities_2023.geojson"))
      muni_sf <- st_read(file.path(data_dir, "municipalities_2023.geojson"), quiet = TRUE)
      saveRDS(muni_sf, file.path(data_dir, "municipalities_sf.rds"))
      cat(sprintf("  Municipalities (2023 fallback): %d features\n", nrow(muni_sf)))
    } else {
      cat("  WARNING: Could not fetch municipality boundaries.\n")
    }
  }
} else {
  cat("  Already fetched.\n")
}

## ============================================================
## 7. CBS: Regional key figures (70072NED) for controls
## ============================================================
cat("\n=== 7. Fetching regional key figures ===\n")

if (!file.exists(file.path(data_dir, "cbs_regional_keys.rds"))) {
  keys_df <- tryCatch({
    cbs_get_data("70072NED")
  }, error = function(e) {
    cat(sprintf("  70072NED: %s\n", e$message))
    tryCatch(cbs_get_data("70072ned"), error = function(e2) NULL)
  })
  if (!is.null(keys_df)) {
    saveRDS(keys_df, file.path(data_dir, "cbs_regional_keys.rds"))
    cat(sprintf("  Regional keys: %d rows\n", nrow(keys_df)))
  }
} else {
  cat("  Already fetched.\n")
}

cat("\n=== All data fetching complete ===\n")
cat("Files in data dir:\n")
cat(paste(" ", list.files(data_dir), collapse = "\n"), "\n")
