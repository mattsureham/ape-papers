# 01_fetch_data.R — Fetch QWI race/ethnicity from LEHD bulk download
# State-level, NAICS sector, race×ethnicity demographics
# Real data only — no simulated fallbacks
source("00_packages.R")

# ---- State abbreviations and FIPS ----
state_info <- tribble(
  ~fips, ~abbr,
  "01", "al", "02", "ak", "04", "az", "05", "ar", "06", "ca",
  "09", "ct", "10", "de", "11", "dc", "12", "fl", "13", "ga",
  "15", "hi", "16", "id", "17", "il", "18", "in", "19", "ia",
  "20", "ks", "21", "ky", "22", "la", "23", "me", "24", "md",
  "25", "ma", "28", "ms", "29", "mo", "30", "mt", "31", "ne",
  "33", "nh", "34", "nj", "36", "ny", "37", "nc", "38", "nd",
  "39", "oh", "40", "ok", "44", "ri", "45", "sc", "46", "sd",
  "47", "tn", "48", "tx", "49", "ut", "51", "va", "54", "wv",
  "56", "wy"
)

# ---- Download LEHD bulk files ----
base_url <- "https://lehd.ces.census.gov/data/qwi/latest_release"
tmpdir <- tempdir()

all_data <- list()

for (i in seq_len(nrow(state_info))) {
  st_fips <- state_info$fips[i]
  st_abbr <- state_info$abbr[i]

  # rh = race×ethnicity, f = all firms, gs = state geography, ns = NAICS sector, op = private, u = all sizes
  url <- sprintf("%s/%s/qwi_%s_rh_f_gs_ns_op_u.csv.gz", base_url, st_abbr, st_abbr)
  dest <- file.path(tmpdir, sprintf("qwi_%s_rh.csv.gz", st_abbr))

  cat(sprintf("[%d/%d] Downloading %s...\n", i, nrow(state_info), st_abbr))

  dl_ok <- tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) {
    cat(sprintf("  ERROR downloading %s: %s\n", st_abbr, conditionMessage(e)))
    FALSE
  })

  if (!dl_ok) next

  df <- tryCatch({
    data.table::fread(cmd = sprintf("gzcat '%s'", dest), showProgress = FALSE)
  }, error = function(e) {
    # Try gunzip fallback
    tryCatch({
      data.table::fread(cmd = sprintf("gunzip -c '%s'", dest), showProgress = FALSE)
    }, error = function(e2) {
      cat(sprintf("  ERROR reading %s: %s\n", st_abbr, conditionMessage(e2)))
      NULL
    })
  })

  if (is.null(df) || nrow(df) == 0) next

  # Filter to industries we need: 72 (Accommodation & Food), 31-33 (Manufacturing)
  # and races: A1 (White), A2 (Black)
  df_filtered <- df[industry %in% c("72", "31-33") & race %in% c("A1", "A2")]

  if (nrow(df_filtered) > 0) {
    df_filtered$state_fips <- st_fips
    all_data[[length(all_data) + 1]] <- df_filtered
  }

  # Clean up temp file
  file.remove(dest)
}

stopifnot("No data downloaded from LEHD — check connectivity" = length(all_data) > 0)

df_raw <- rbindlist(all_data, fill = TRUE)
cat(sprintf("Total rows: %s\n", format(nrow(df_raw), big.mark = ",")))

# ---- Select and rename columns ----
df_raw <- df_raw %>%
  as_tibble() %>%
  select(
    state_fips, geography, year, quarter, industry, race, ethnicity,
    Emp, HirA, Sep, EarnHirAS, EarnS,
    HirN, FrmJbGn, FrmJbLs
  ) %>%
  mutate(
    year = as.integer(year),
    quarter = as.integer(quarter),
    Emp = as.numeric(Emp),
    HirA = as.numeric(HirA),
    Sep = as.numeric(Sep),
    EarnHirAS = as.numeric(EarnHirAS),
    EarnS = as.numeric(EarnS)
  )

# ---- Save ----
saveRDS(df_raw, "../data/qwi_raw.rds")

cat("States:", length(unique(df_raw$state_fips)), "\n")
cat("Industries:", paste(sort(unique(df_raw$industry)), collapse = ", "), "\n")
cat("Races:", paste(sort(unique(df_raw$race)), collapse = ", "), "\n")
cat("Year range:", paste(range(df_raw$year, na.rm = TRUE), collapse = "-"), "\n")
cat("Rows per industry:\n")
print(table(df_raw$industry))
cat("Done.\n")
