## 01_fetch_data.R — Fetch MHLW Women's Active Engagement Enterprise Database
## apep_0608: Japan Women's Participation Disclosure RDD
##
## Data source: https://positive-ryouritsu.mhlw.go.jp/positivedb/opendata/
## Downloaded via session-authenticated request (site requires cookies)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

csv_path <- file.path(data_dir, "99_20260313_utf8.csv")
zip_path <- file.path(data_dir, "mhlw_women_opendata.zip")

## ---- Download if needed ----
if (!file.exists(csv_path)) {
  if (file.exists(zip_path)) {
    cat("Extracting from existing zip...\n")
    unzip(zip_path, exdir = data_dir)
  } else {
    # Two-step: get session cookies, then download
    cat("Downloading MHLW open data (requires session cookies)...\n")
    cookie_file <- tempfile(fileext = ".txt")

    # Step 1: Visit page to get session
    system2("curl", c(
      "-sL", "-c", cookie_file,
      "-A", shQuote("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"),
      "-o", "/dev/null",
      shQuote("https://positive-ryouritsu.mhlw.go.jp/positivedb/opendata/")
    ))

    # Step 2: Download with cookies
    system2("curl", c(
      "-sL", "-b", cookie_file,
      "-A", shQuote("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"),
      "-o", zip_path,
      shQuote("https://positive-ryouritsu.mhlw.go.jp/positivedb/opendata/download_nb.html?w=99")
    ))

    if (!file.exists(zip_path) || file.size(zip_path) < 1e6) {
      stop("FATAL: Failed to download MHLW data. File too small or missing.")
    }

    cat("Downloaded:", round(file.size(zip_path) / 1e6, 1), "MB\n")
    unzip(zip_path, exdir = data_dir)
  }
}

# Find the CSV (filename includes date)
if (!file.exists(csv_path)) {
  csvs <- list.files(data_dir, pattern = "^99_.*\\.csv$", full.names = TRUE)
  if (length(csvs) == 0) stop("FATAL: No CSV found after extraction.")
  csv_path <- csvs[1]
}

stopifnot("Data file must exist" = file.exists(csv_path))
cat("Data file:", csv_path, "\n")
cat("File size:", round(file.size(csv_path) / 1e6, 1), "MB\n")

## ---- Read raw data ----
# This is a wide CSV with ~230+ columns in Japanese
# We selectively read key columns
df_raw <- read_csv(csv_path, locale = locale(encoding = "UTF-8"),
                   show_col_types = FALSE, guess_max = 5000)

cat("Raw dimensions:", nrow(df_raw), "x", ncol(df_raw), "\n")

## ---- Extract key variables ----
# Column mapping (Japanese → English):
# 企業名 = company name
# 法人番号 = corporate number
# 業種 = industry
# 都道府県 = prefecture
# 企業規模 = firm size category
# 市場区分 = market listing
# 10.管理職に占める女性労働者の割合-割合(%) = female manager share
# 14.男女の賃金の差異1-全労働者(%) = gender wage gap (all workers)
# 14.男女の賃金の差異2-うち正規雇用労働者(%) = wage gap (regular workers)
# 14.男女の賃金の差異3-うち非正規雇用労働者(%) = wage gap (non-regular)

# Get column names
cnames <- names(df_raw)

# Find relevant columns by pattern matching
find_col <- function(pattern) {
  idx <- grep(pattern, cnames)
  if (length(idx) == 0) return(NA_character_)
  cnames[idx[1]]
}

col_map <- list(
  company_name = cnames[1],       # 企業名
  corp_number  = cnames[2],       # 法人番号
  industry     = cnames[4],       # 業種
  industry_detail = cnames[5],    # 業種(詳細分類)
  prefecture   = cnames[6],       # 都道府県
  firm_size    = cnames[7],       # 企業規模
  market       = cnames[9],       # 市場区分
  female_manager_pct = find_col("10\\.管理職.*割合"),
  female_manager_n   = find_col("10\\.管理職.*人数"),
  female_manager_total = find_col("10\\.管理職.*男女計"),
  female_section_pct = find_col("9\\.係長級.*割合"),
  female_board_pct   = find_col("11\\.役員.*割合"),
  wage_gap_all    = find_col("14\\.男女の賃金の差異1"),
  wage_gap_regular = find_col("14\\.男女の賃金の差異2"),
  wage_gap_nonreg  = find_col("14\\.男女の賃金の差異3")
)

cat("\nColumn mapping:\n")
for (nm in names(col_map)) {
  cat(sprintf("  %-25s -> %s\n", nm, col_map[[nm]]))
}

# Select and rename
df <- df_raw %>%
  select(any_of(unlist(col_map))) %>%
  setNames(names(col_map)[!is.na(unlist(col_map))])

cat("\nSelected data:", nrow(df), "x", ncol(df), "\n")

## ---- Save ----
saveRDS(df, file.path(data_dir, "mhlw_selected.rds"))
cat("Saved mhlw_selected.rds\n")
