# 01_fetch_data.R — Download RIETI merger data and MIC fiscal data
# Japan Heisei Municipal Merger Fiscal Cliff (apep_0836)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. RIETI Municipality Converter (merger dates + codes)
# ============================================================
cat("=== Downloading RIETI Municipality Converter ===\n")

rieti_url <- "https://raw.githubusercontent.com/keisukekondokk/municipality-converter/master/data_converter/municipality_converter_jp.csv"
rieti_file <- file.path(data_dir, "rieti_converter.csv")

resp <- GET(rieti_url, write_disk(rieti_file, overwrite = TRUE))
if (status_code(resp) != 200) {
  stop("FATAL: RIETI converter download failed with status ", status_code(resp))
}

rieti <- fread(rieti_file, encoding = "UTF-8")
cat("RIETI converter:", nrow(rieti), "rows,", ncol(rieti), "cols\n")
cat("Columns:", paste(names(rieti), collapse = ", "), "\n\n")

# ============================================================
# 2. MIC Local Public Finance Survey
# ============================================================
cat("=== Downloading MIC Fiscal Data ===\n")

# Map fiscal years to Heisei/Reiwa year codes for URL construction
# FY2006 = H18, ..., FY2018 = H30, FY2019 = R01, ..., FY2023 = R05
fy_map <- data.table(
  fy = 2006:2023,
  era_code = c(
    paste0("h", 18:30),  # H18-H30 = FY2006-FY2018
    paste0("r0", 1:5)    # R01-R05 = FY2019-FY2023
  )
)

# Landing page URL pattern
# FY2006-2018: https://www.soumu.go.jp/iken/zaisei/hXX_shichouson.html
# FY2019-2023: https://www.soumu.go.jp/iken/zaisei/rXX_shichouson.html
fy_map[, landing_url := paste0(
  "https://www.soumu.go.jp/iken/zaisei/",
  era_code, "_shichouson.html"
)]

# For FY2006-2011, Excel files follow predictable pattern
# For FY2012+, we need to scrape the landing page
mic_dir <- file.path(data_dir, "mic_raw")
dir.create(mic_dir, showWarnings = FALSE)

download_fiscal_year <- function(fy, era_code, landing_url) {
  cat(sprintf("  FY%d (%s): ", fy, era_code))

  # Try predictable URL pattern first (FY2006-2011)
  if (fy <= 2011) {
    # Pattern: hXX_shichouson_01.xls (summary table)
    direct_url <- paste0(
      "https://www.soumu.go.jp/iken/zaisei/xls/",
      era_code, "_shichouson_01.xls"
    )
    ext <- "xls"
  } else {
    # For FY2012+, scrape landing page for Excel links
    tryCatch({
      page <- read_html(landing_url)
      links <- html_attr(html_nodes(page, "a"), "href")

      # Find Excel files - look for first municipal file (概況 or _01)
      excel_links <- links[grepl("\\.(xls|xlsx)$", links, ignore.case = TRUE)]

      if (length(excel_links) == 0) {
        cat("NO EXCEL LINKS FOUND on landing page\n")
        return(NULL)
      }

      # Make absolute URL
      direct_url <- excel_links[1]
      if (!grepl("^http", direct_url)) {
        direct_url <- paste0("https://www.soumu.go.jp", direct_url)
      }
      ext <- ifelse(grepl("\\.xlsx$", direct_url, ignore.case = TRUE), "xlsx", "xls")
    }, error = function(e) {
      cat("SCRAPE FAILED:", e$message, "\n")
      return(NULL)
    })
  }

  out_file <- file.path(mic_dir, paste0("fy", fy, ".", ext))

  tryCatch({
    resp <- GET(direct_url, write_disk(out_file, overwrite = TRUE),
                timeout(60), user_agent("Mozilla/5.0 (R/httr)"))
    if (status_code(resp) == 200 && file.size(out_file) > 1000) {
      cat(sprintf("OK (%s, %.0f KB)\n", ext, file.size(out_file)/1024))
      return(out_file)
    } else {
      cat(sprintf("FAILED (status %d, size %d)\n", status_code(resp), file.size(out_file)))
      file.remove(out_file)
      return(NULL)
    }
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    return(NULL)
  })
}

# Download all fiscal years
results <- list()
for (i in seq_len(nrow(fy_map))) {
  results[[i]] <- download_fiscal_year(
    fy_map$fy[i], fy_map$era_code[i], fy_map$landing_url[i]
  )
  Sys.sleep(1)  # Be polite to MIC servers
}

downloaded <- fy_map[!sapply(results, is.null)]
cat(sprintf("\nDownloaded %d of %d fiscal years\n", nrow(downloaded), nrow(fy_map)))

if (nrow(downloaded) < 10) {
  stop("FATAL: Could only download ", nrow(downloaded), " fiscal years. Need at least 10 for credible analysis.")
}

# ============================================================
# 3. Parse downloaded Excel files
# ============================================================
cat("\n=== Parsing MIC Excel Files ===\n")

parse_mic_file <- function(file_path, fy) {
  cat(sprintf("  Parsing FY%d... ", fy))

  tryCatch({
    # Read Excel - typically first sheet has municipal data
    sheets <- excel_sheets(file_path)

    # Try to read the first sheet
    raw <- read_excel(file_path, sheet = 1, col_names = FALSE)

    # MIC files have Japanese headers. Structure typically:
    # Row 1-3: headers/titles
    # Column 1: municipality code (団体コード)
    # Column 2: municipality name
    # Subsequent columns: financial variables

    # Find the header row (contains "団体コード" or numeric codes starting with 01)
    header_row <- NULL
    for (r in 1:min(10, nrow(raw))) {
      row_vals <- as.character(unlist(raw[r, ]))
      if (any(grepl("団体コード|code|Code", row_vals, ignore.case = TRUE))) {
        header_row <- r
        break
      }
    }

    if (is.null(header_row)) {
      # Alternative: find first row where col 1 looks like a 6-digit code
      for (r in 1:min(15, nrow(raw))) {
        val <- as.character(raw[[r, 1]])
        if (!is.na(val) && grepl("^[0-9]{5,6}$", trimws(val))) {
          header_row <- r - 1
          break
        }
      }
    }

    if (is.null(header_row)) {
      cat("SKIP (no header found)\n")
      return(NULL)
    }

    # Re-read with proper header
    dt <- as.data.table(read_excel(file_path, sheet = 1, skip = header_row))

    # Standardize column names
    old_names <- names(dt)

    # First column should be municipality code
    # Look for columns with revenue/expenditure data
    # Key variables we need: code, total revenue, total expenditure, LAT, local tax

    # For now, keep first 15 columns max and rename generically
    if (ncol(dt) > 15) dt <- dt[, 1:15]

    # Add fiscal year
    dt[, fiscal_year := fy]

    cat(sprintf("OK (%d rows, %d cols)\n", nrow(dt), ncol(dt)))
    return(dt)
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    return(NULL)
  })
}

# Parse all files
parsed_list <- list()
mic_files <- list.files(mic_dir, pattern = "\\.(xls|xlsx)$", full.names = TRUE)

for (f in mic_files) {
  fy <- as.integer(gsub(".*fy(\\d+)\\..*", "\\1", basename(f)))
  parsed_list[[as.character(fy)]] <- parse_mic_file(f, fy)
}

# Report parsing results
parsed_ok <- parsed_list[!sapply(parsed_list, is.null)]
cat(sprintf("\nSuccessfully parsed %d fiscal years\n", length(parsed_ok)))

# ============================================================
# 4. Save raw parsed data for inspection
# ============================================================
saveRDS(rieti, file.path(data_dir, "rieti_raw.rds"))

if (length(parsed_ok) > 0) {
  saveRDS(parsed_ok, file.path(data_dir, "mic_parsed_raw.rds"))
}

cat("\n=== Raw data saved. Proceed to 02_clean_data.R ===\n")
