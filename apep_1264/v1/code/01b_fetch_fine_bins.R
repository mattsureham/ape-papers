# 01b_fetch_fine_bins.R — Get fine-grained firm-size bins
# Try: OECD SDBS, Eurostat SBS, BFS detailed tables
source("code/00_packages.R")

data_dir <- "data"

# ===========================================================================
# 1) Check BFS 0602000000 tables for size-class breakdowns
# ===========================================================================
cat("=== Checking BFS 0602000000 table family ===\n")

bfs_api <- "https://www.pxweb.bfs.admin.ch/api/v1/de"

for (i in 101:108) {
  tpath <- sprintf("px-x-0602000000_%03d", i)
  url <- paste0(bfs_api, "/", tpath)
  resp <- httr::GET(url, httr::timeout(15))
  if (httr::status_code(resp) != 200) next

  content <- httr::content(resp, as = "parsed")
  if (is.null(content$variables)) {
    # Folder — check subfile
    for (item in content) {
      sub_url <- paste0(url, "/", item$id)
      sub_resp <- httr::GET(sub_url, httr::timeout(15))
      if (httr::status_code(sub_resp) == 200) {
        sub <- httr::content(sub_resp, as = "parsed")
        if (!is.null(sub$variables)) {
          cat("\nTable:", tpath, "/", item$id, "\n")
          for (v in sub$variables) {
            cat("  ", v$code, ":", v$text, "(", length(v$values), ")")
            if (length(v$values) <= 20) {
              cat(" →", paste(head(v$valueTexts, 10), collapse=" | "))
            }
            cat("\n")
          }
        }
      }
      Sys.sleep(0.2)
    }
  }
  Sys.sleep(0.3)
}

# ===========================================================================
# 2) OECD SDBS — Structural and Demographic Business Statistics
# ===========================================================================
cat("\n=== Trying OECD SDBS data ===\n")

# OECD.Stat SDBS endpoint for firm demographics by size class
# Dataset: SSIS_BSC_ISIC4 (Business Statistics by Size Class, ISIC Rev.4)
oecd_url <- "https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_SSIS_BSC_ISIC4@DF_BSC_ISIC4,1.0/CHE..._T..A"

oecd_resp <- httr::GET(
  oecd_url,
  httr::add_headers(Accept = "application/vnd.sdmx.data+csv;file=true"),
  httr::timeout(60)
)

cat("OECD SDBS response:", httr::status_code(oecd_resp), "\n")

if (httr::status_code(oecd_resp) == 200) {
  raw_text <- httr::content(oecd_resp, as = "text", encoding = "UTF-8")
  df_oecd <- data.table::fread(text = raw_text)
  cat("OECD data:", nrow(df_oecd), "rows\n")
  cat("Columns:", paste(names(df_oecd), collapse = ", "), "\n")
  print(head(df_oecd, 10))
  data.table::fwrite(df_oecd, file.path(data_dir, "oecd_sdbs.csv"))
} else {
  # Try alternative OECD endpoint
  cat("Trying alternative OECD paths...\n")

  oecd_alts <- c(
    # SBS by size class
    "https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_SSIS_BSC_ISIC4@DF_BSC_ISIC4,1.0/CHE...?startPeriod=2011&endPeriod=2023",
    # Alternative SBS format
    "https://stats.oecd.org/restsdmx/sdmx.ashx/GetData/SSIS_BSC_ISIC4/CHE.../all?startTime=2011&endTime=2023",
    # SDBS main data
    "https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS/DSD_SDBS@DF_SDBS/CHE.A._T._T._T._T?startPeriod=2011"
  )

  for (alt_url in oecd_alts) {
    cat("  Trying:", substr(alt_url, 1, 100), "\n")
    resp <- httr::GET(
      alt_url,
      httr::add_headers(Accept = "application/vnd.sdmx.data+csv;file=true"),
      httr::timeout(30)
    )
    cat("  Status:", httr::status_code(resp), "\n")
    if (httr::status_code(resp) == 200) {
      raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
      df <- tryCatch(data.table::fread(text = raw_text), error = function(e) NULL)
      if (!is.null(df) && nrow(df) > 0) {
        cat("  Got:", nrow(df), "rows\n")
        cat("  Cols:", paste(names(df), collapse=", "), "\n")
        print(head(df, 5))
        data.table::fwrite(df, file.path(data_dir, "oecd_sdbs.csv"))
        break
      }
    }
    Sys.sleep(0.5)
  }
}

# ===========================================================================
# 3) Eurostat SBS — Annual enterprise statistics by size class
# ===========================================================================
cat("\n=== Trying Eurostat SBS data ===\n")

# Eurostat sbs_sc_ind_r2 — Annual enterprise stats for industry by size class
# Switzerland (CH) is included as EFTA country
eurostat_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/",
  "sbs_sc_ind_r2/A.CH.B-N_X_K642._T+10-19+20-49+50-249+GE250.V11110+V11210+V16110",
  "?format=SDMX-CSV&startPeriod=2011&endPeriod=2023"
)

euro_resp <- httr::GET(eurostat_url, httr::timeout(60))
cat("Eurostat SBS response:", httr::status_code(euro_resp), "\n")

if (httr::status_code(euro_resp) == 200) {
  raw_text <- httr::content(euro_resp, as = "text", encoding = "UTF-8")
  df_euro <- data.table::fread(text = raw_text)
  cat("Eurostat data:", nrow(df_euro), "rows\n")
  cat("Columns:", paste(names(df_euro), collapse = ", "), "\n")
  print(head(df_euro, 10))
  data.table::fwrite(df_euro, file.path(data_dir, "eurostat_sbs.csv"))
} else {
  # Try alternative Eurostat datasets
  cat("Trying alternative Eurostat tables...\n")
  euro_tables <- c(
    # SBS overall - NACE aggregates by size
    "sbs_sc_ovr_r2",
    # SBS industry by size
    "sbs_sc_1b_se_r2",
    # Enterprise demography by size
    "bd_size_r3"
  )

  for (tbl in euro_tables) {
    # Try simpler query - total economy
    alt_url <- paste0(
      "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/",
      tbl, "/A.CH?format=SDMX-CSV&startPeriod=2011&endPeriod=2023"
    )
    resp <- httr::GET(alt_url, httr::timeout(30))
    cat("  ", tbl, ":", httr::status_code(resp), "\n")
    if (httr::status_code(resp) == 200) {
      raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
      df <- tryCatch(data.table::fread(text = raw_text), error = function(e) NULL)
      if (!is.null(df) && nrow(df) > 0) {
        cat("  Got:", nrow(df), "rows\n")
        cat("  Cols:", paste(names(df), collapse=", "), "\n")
        # Check for size class variable
        size_cols <- grep("size|SIZE", names(df), value = TRUE, ignore.case = TRUE)
        cat("  Size cols:", paste(size_cols, collapse=", "), "\n")
        print(head(df, 5))
        data.table::fwrite(df, file.path(data_dir, "eurostat_sbs.csv"))
        break
      }
    }
    Sys.sleep(0.5)
  }
}

# ===========================================================================
# 4) Also try the BFS R package for more granular data
# ===========================================================================
cat("\n=== Trying BFS R package ===\n")

if (!requireNamespace("BFS", quietly = TRUE)) {
  install.packages("BFS", repos = "https://cloud.r-project.org")
}

tryCatch({
  library(BFS)

  # Search for STATENT datasets with size class
  cat("Searching BFS catalog for size-class datasets...\n")
  catalog <- bfs_get_catalog_data(language = "de")
  cat("Catalog has", nrow(catalog), "entries\n")

  # Filter for enterprise/industry domain (06) with size class
  size_datasets <- catalog[grepl("Gr.ssenklasse|Besch.ftigtenklasse|Unternehmensgr",
                                  catalog$title, ignore.case = TRUE), ]
  cat("Found", nrow(size_datasets), "datasets with size class info\n")

  if (nrow(size_datasets) > 0) {
    for (i in 1:min(5, nrow(size_datasets))) {
      cat("\n  [", i, "]", size_datasets$title[i], "\n")
      cat("      URL:", size_datasets$url[i], "\n")
    }

    # Download the first relevant dataset
    for (i in 1:min(3, nrow(size_datasets))) {
      cat("\nTrying dataset", i, ":", size_datasets$title[i], "\n")
      df <- tryCatch(
        bfs_get_data(url_bfs = size_datasets$url[i]),
        error = function(e) {
          cat("  Error:", e$message, "\n")
          NULL
        }
      )
      if (!is.null(df) && nrow(df) > 0) {
        df <- data.table::as.data.table(df)
        cat("  Got:", nrow(df), "rows x", ncol(df), "cols\n")
        cat("  Cols:", paste(names(df), collapse=", "), "\n")
        print(head(df, 5))
        data.table::fwrite(df, file.path(data_dir, "bfs_fine_bins.csv"))
        break
      }
    }
  }
}, error = function(e) {
  cat("BFS package error:", e$message, "\n")
})

# ===========================================================================
# 5) Summary of what we got
# ===========================================================================
cat("\n=== Data Acquisition Summary ===\n")
for (f in c("statent_raw.csv", "oecd_sdbs.csv", "eurostat_sbs.csv", "bfs_fine_bins.csv")) {
  fpath <- file.path(data_dir, f)
  if (file.exists(fpath)) {
    df <- data.table::fread(fpath)
    cat("✓", f, ":", nrow(df), "rows x", ncol(df), "cols\n")
  } else {
    cat("✗", f, ": not found\n")
  }
}
