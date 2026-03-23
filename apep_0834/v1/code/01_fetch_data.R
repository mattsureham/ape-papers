## 01_fetch_data.R — Fetch MLIT station passenger data (S12) and land price data (L01)
source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Helper: download and extract MLIT zip ----
fetch_mlit <- function(url, dest_dir, label) {
  zip_path <- file.path(dest_dir, paste0(label, ".zip"))
  if (!file.exists(zip_path)) {
    cat(sprintf("Downloading %s...\n", label))
    resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE),
                      httr::timeout(300))
    if (httr::status_code(resp) != 200) {
      unlink(zip_path)
      stop(sprintf("Download failed for %s: HTTP %d", label, httr::status_code(resp)))
    }
    cat(sprintf("  Downloaded: %s (%.1f MB)\n", label,
                file.info(zip_path)$size / 1e6))
  } else {
    cat(sprintf("  Already cached: %s\n", label))
  }
  # Extract
  extract_dir <- file.path(dest_dir, label)
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)
  utils::unzip(zip_path, exdir = extract_dir)
  cat(sprintf("  Extracted to %s\n", extract_dir))
  return(extract_dir)
}

## ---- 1. Station passenger data (S12) — multiple years ----
# S12 data available for FY2011-FY2022
# URL pattern: https://nlftp.mlit.go.jp/ksj/gml/data/S12/S12-{yy}/S12-{yy}_GML.zip
# where yy = last two digits of the fiscal year
s12_years <- 2011:2022
s12_data_list <- list()

for (yr in s12_years) {
  yy <- sprintf("%02d", yr %% 100)
  url <- sprintf("https://nlftp.mlit.go.jp/ksj/gml/data/S12/S12-%s/S12-%s_GML.zip", yy, yy)
  label <- sprintf("S12_%d", yr)

  tryCatch({
    extract_dir <- fetch_mlit(url, data_dir, label)
    # Find GML or shapefile
    gml_files <- list.files(extract_dir, pattern = "\\.shp$|\\.geojson$|\\.gml$",
                            recursive = TRUE, full.names = TRUE)
    if (length(gml_files) == 0) {
      # Try reading CSV
      csv_files <- list.files(extract_dir, pattern = "\\.csv$",
                              recursive = TRUE, full.names = TRUE)
      if (length(csv_files) > 0) {
        cat(sprintf("  Reading CSV for %d\n", yr))
        df_yr <- read_csv(csv_files[1], show_col_types = FALSE)
        df_yr$fiscal_year <- yr
        s12_data_list[[as.character(yr)]] <- df_yr
      } else {
        cat(sprintf("  No recognized data files for %d, trying sf::st_read on dir...\n", yr))
        df_yr <- sf::st_read(extract_dir, quiet = TRUE)
        df_yr$fiscal_year <- yr
        s12_data_list[[as.character(yr)]] <- df_yr
      }
    } else {
      cat(sprintf("  Reading spatial file for %d: %s\n", yr, basename(gml_files[1])))
      df_yr <- sf::st_read(gml_files[1], quiet = TRUE)
      df_yr$fiscal_year <- yr
      s12_data_list[[as.character(yr)]] <- df_yr
    }
  }, error = function(e) {
    cat(sprintf("  WARNING: Failed to fetch/read S12 for %d: %s\n", yr, e$message))
  })
}

cat(sprintf("\nS12: Successfully loaded %d of %d years\n",
            length(s12_data_list), length(s12_years)))

if (length(s12_data_list) == 0) {
  stop("FATAL: No S12 station data could be loaded. Cannot proceed.")
}

# Save combined station data
saveRDS(s12_data_list, file.path(data_dir, "s12_raw_list.rds"))

## ---- 2. Land price data (L01) — key years ----
# L01 URL pattern: https://nlftp.mlit.go.jp/ksj/gml/data/L01/L01-{yy}/L01-{yy}_GML.zip
# Download pre-treatment (2005) and post-treatment (2015, 2020) years
l01_years <- c(2005, 2010, 2015, 2020)
l01_data_list <- list()

for (yr in l01_years) {
  yy <- sprintf("%02d", yr %% 100)
  url <- sprintf("https://nlftp.mlit.go.jp/ksj/gml/data/L01/L01-%s/L01-%s_GML.zip", yy, yy)
  label <- sprintf("L01_%d", yr)

  tryCatch({
    extract_dir <- fetch_mlit(url, data_dir, label)
    gml_files <- list.files(extract_dir, pattern = "\\.shp$|\\.geojson$|\\.gml$",
                            recursive = TRUE, full.names = TRUE)
    csv_files <- list.files(extract_dir, pattern = "\\.csv$",
                            recursive = TRUE, full.names = TRUE)

    if (length(gml_files) > 0) {
      cat(sprintf("  Reading spatial file for L01 %d: %s\n", yr, basename(gml_files[1])))
      df_yr <- sf::st_read(gml_files[1], quiet = TRUE)
    } else if (length(csv_files) > 0) {
      cat(sprintf("  Reading CSV for L01 %d\n", yr))
      df_yr <- read_csv(csv_files[1], show_col_types = FALSE)
    } else {
      # Try reading any file with sf
      all_files <- list.files(extract_dir, recursive = TRUE, full.names = TRUE)
      cat(sprintf("  Files found: %s\n", paste(basename(all_files), collapse = ", ")))
      df_yr <- sf::st_read(extract_dir, quiet = TRUE)
    }
    df_yr$survey_year <- yr
    l01_data_list[[as.character(yr)]] <- df_yr
    cat(sprintf("  L01 %d: %d observations\n", yr, nrow(df_yr)))
  }, error = function(e) {
    cat(sprintf("  WARNING: Failed to fetch/read L01 for %d: %s\n", yr, e$message))
  })
}

cat(sprintf("\nL01: Successfully loaded %d of %d years\n",
            length(l01_data_list), length(l01_years)))

if (length(l01_data_list) == 0) {
  stop("FATAL: No L01 land price data could be loaded. Cannot proceed.")
}

saveRDS(l01_data_list, file.path(data_dir, "l01_raw_list.rds"))

cat("\n=== Data fetch complete ===\n")
cat(sprintf("S12 years: %s\n", paste(names(s12_data_list), collapse = ", ")))
cat(sprintf("L01 years: %s\n", paste(names(l01_data_list), collapse = ", ")))
