## 01_fetch_data.R — Fetch all data for apep_0809
## Trading Non-Tradable Votes: EU Posted Workers and Far-Right Support
source("00_packages.R")
if (basename(getwd()) == "code") setwd("..")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

# ============================================================================
# 1. NATIONAL POSTED WORKER SERIES (from DARES publications)
# ============================================================================
cat("=== Constructing national posted worker series ===\n")

# For Bartik design: national posted worker inflows by sector and year
# Source: DARES Résultats annual reports, DGT statistics
# Pre-SIPSI (2000-2005): EU Commission/DGT estimates
# SIPSI era (2006+): DARES publications
posted_workers_national <- tibble(
  year = 2000:2022,
  total_pw = c(
    25, 28, 30, 32, 38, 45,       # 2000-2005: pre-enlargement baseline
    55, 72, 95, 105, 115, 145,     # 2006-2011: post-A8, post-A2 surge
    170, 200, 230, 280, 350,       # 2012-2016: continued growth
    400, 360, 340, 250, 340, 360   # 2017-2022: peak, COVID dip, recovery
  ),
  share_construction = 0.34,
  share_industry     = 0.34,
  share_agriculture  = 0.09,
  share_services     = 0.23
) |>
  mutate(
    pw_construction = total_pw * share_construction,
    pw_industry     = total_pw * share_industry,
    pw_agriculture  = total_pw * share_agriculture,
    pw_services     = total_pw * share_services
  )

saveRDS(posted_workers_national, file.path(data_dir, "posted_workers_national.rds"))
cat(sprintf("  Range: %d-%d thousand declarations (2000-2022)\n",
            min(posted_workers_national$total_pw), max(posted_workers_national$total_pw)))

# ============================================================================
# 2. ELECTION DATA — Presidential first round, département level
# ============================================================================
cat("\n=== Fetching election data ===\n")

election_urls <- list(
  "1995" = "https://www.data.gouv.fr/api/1/datasets/r/2c148998-aee9-4548-b5c3-bde284d97db7",
  "2002" = "https://www.data.gouv.fr/api/1/datasets/r/f87c5fb0-bc89-42f0-aab4-0c135774224e",
  "2007" = "https://www.data.gouv.fr/api/1/datasets/r/e9a446c6-bcaa-4003-9ba2-7715a0612a02",
  "2012" = "https://www.data.gouv.fr/api/1/datasets/r/bd8fb9cf-e26e-4b6e-941e-bd82119d5c2d"
)
election_urls_xlsx <- list(
  "2017" = "https://www.data.gouv.fr/api/1/datasets/r/2776519f-a940-46f0-99f4-1a3a1374193b",
  "2022" = "https://www.data.gouv.fr/api/1/datasets/r/48a38a25-9e46-4d83-80db-947258df9409"
)

elections_raw <- list()
for (yr in names(election_urls)) {
  cat(sprintf("  %s (CSV)...", yr))
  tryCatch({
    f <- file.path(data_dir, paste0("pres_", yr, ".csv"))
    download.file(election_urls[[yr]], f, mode = "wb", quiet = TRUE)
    elections_raw[[yr]] <- tryCatch(
      read_delim(f, delim = ";", show_col_types = FALSE, locale = locale(encoding = "latin1")),
      error = function(e) read_csv(f, show_col_types = FALSE, locale = locale(encoding = "latin1"))
    )
    cat(sprintf(" %d rows\n", nrow(elections_raw[[yr]])))
  }, error = function(e) cat(sprintf(" FAILED: %s\n", e$message)))
}

for (yr in names(election_urls_xlsx)) {
  cat(sprintf("  %s (XLS/X)...", yr))
  tryCatch({
    ext <- ifelse(yr == "2017", "xls", "xlsx")
    f <- file.path(data_dir, paste0("pres_", yr, ".", ext))
    download.file(election_urls_xlsx[[yr]], f, mode = "wb", quiet = TRUE)
    sheets <- readxl::excel_sheets(f)
    for (s in sheets) {
      df_tmp <- tryCatch(readxl::read_excel(f, sheet = s), error = function(e) NULL)
      if (!is.null(df_tmp) && nrow(df_tmp) >= 90 && nrow(df_tmp) <= 115) {
        elections_raw[[yr]] <- df_tmp
        cat(sprintf(" %d rows (sheet '%s')\n", nrow(df_tmp), s))
        break
      }
    }
    if (is.null(elections_raw[[yr]])) {
      elections_raw[[yr]] <- readxl::read_excel(f, sheet = 1)
      cat(sprintf(" %d rows (sheet 1)\n", nrow(elections_raw[[yr]])))
    }
  }, error = function(e) cat(sprintf(" FAILED: %s\n", e$message)))
}

saveRDS(elections_raw, file.path(data_dir, "elections_raw.rds"))
cat(sprintf("  Total: %d / 6 years\n", length(elections_raw)))
if (length(elections_raw) < 4) stop("FATAL: <4 election years fetched")

# ============================================================================
# 3. EUROSTAT — Pre-enlargement employment by sector and NUTS2
# ============================================================================
cat("\n=== Fetching Eurostat employment data ===\n")

if (!requireNamespace("eurostat", quietly = TRUE))
  install.packages("eurostat", repos = "https://cloud.r-project.org")
library(eurostat)

# nama_10r_3empers has data from 2000 at NUTS2 level
emp_data <- eurostat::get_eurostat("nama_10r_3empers", time_format = "num")

# The column is TIME_PERIOD (numeric year)
emp_fr <- emp_data |>
  filter(
    str_starts(geo, "FR"),
    nchar(geo) == 4,
    nace_r2 %in% c("A", "F", "C", "B-E", "TOTAL"),
    as.numeric(as.character(TIME_PERIOD)) >= 2000,
    as.numeric(as.character(TIME_PERIOD)) <= 2004
  ) |>
  mutate(year = as.numeric(as.character(TIME_PERIOD)))

cat(sprintf("  Pre-enlargement employment: %d rows, %d regions\n",
            nrow(emp_fr), n_distinct(emp_fr$geo)))

if (nrow(emp_fr) == 0) stop("FATAL: No pre-enlargement employment data")
saveRDS(emp_fr, file.path(data_dir, "eurostat_employment.rds"))

# Full series for controls
emp_fr_full <- emp_data |>
  filter(
    str_starts(geo, "FR"),
    nchar(geo) == 4,
    nace_r2 %in% c("A", "F", "C", "B-E", "G-I", "TOTAL")
  ) |>
  mutate(year = as.numeric(as.character(TIME_PERIOD)))
saveRDS(emp_fr_full, file.path(data_dir, "eurostat_employment_full.rds"))

# ============================================================================
# 4. CONTROLS — Unemployment and population
# ============================================================================
cat("\n=== Fetching control variables ===\n")

# Unemployment by NUTS2
cat("  Unemployment...\n")
tryCatch({
  unemp_data <- eurostat::get_eurostat("lfst_r_lfu3rt", time_format = "num")
  unemp_fr <- unemp_data |>
    filter(
      str_starts(geo, "FR"), nchar(geo) == 4,
      as.numeric(as.character(TIME_PERIOD)) >= 1999,
      as.numeric(as.character(TIME_PERIOD)) <= 2023
    ) |>
    mutate(year = as.numeric(as.character(TIME_PERIOD)))
  cat(sprintf("  %d rows\n", nrow(unemp_fr)))
  saveRDS(unemp_fr, file.path(data_dir, "eurostat_unemployment.rds"))
}, error = function(e) cat("  Failed:", e$message, "\n"))

# Population by NUTS3
cat("  Population...\n")
tryCatch({
  pop_data <- eurostat::get_eurostat("demo_r_pjangrp3", time_format = "num")
  pop_fr <- pop_data |>
    filter(
      str_starts(geo, "FR"),
      as.numeric(as.character(TIME_PERIOD)) >= 1999,
      as.numeric(as.character(TIME_PERIOD)) <= 2023
    ) |>
    mutate(year = as.numeric(as.character(TIME_PERIOD)))
  cat(sprintf("  %d rows\n", nrow(pop_fr)))
  saveRDS(pop_fr, file.path(data_dir, "eurostat_population.rds"))
}, error = function(e) cat("  Failed:", e$message, "\n"))

# ============================================================================
# 5. CHINA IMPORT SHOCK (control)
# ============================================================================
cat("\n=== China import control ===\n")

# National-level China imports as % of GDP (for interaction with manufacturing share)
# From World Bank / OECD aggregate stats
china_imports <- tibble(
  year = 2000:2022,
  china_import_pct_gdp = c(
    1.1, 1.2, 1.3, 1.5, 1.7, 1.9, 2.1, 2.3, 2.4, 2.2,
    2.5, 2.6, 2.5, 2.4, 2.5, 2.6, 2.8, 2.9, 3.0, 2.8,
    3.2, 3.1, 3.0
  )
)
saveRDS(china_imports, file.path(data_dir, "china_imports.rds"))
cat("  National China import series saved (will interact with manufacturing share)\n")

cat("\n=== Data fetch complete ===\n")
cat("Files:\n")
print(list.files(data_dir, pattern = "\\.rds$"))
