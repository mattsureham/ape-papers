## 01_fetch_data.R — Download Swiss housing inventory data from geo.admin.ch
## apep_0796: Swiss Second Home Ban RDD

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- 1. Housing Inventory (Zweitwohnungsinventar) ----
## STAC collection: ch.are.wohnungsinventar-zweitwohnungsanteil
## Available as xlsx.zip for each wave

base_url <- "https://data.geo.admin.ch/ch.are.wohnungsinventar-zweitwohnungsanteil"

# Define all available waves (from STAC API listing)
waves <- c(
  "2017", "2018", "2019-03", "2019-10",
  "2020-03", "2020-10", "2021-03", "2021-10",
  "2022-03", "2022-10", "2023-03", "2023-10",
  "2024-03", "2024-10", "2025-03", "2025-10"
)

all_data <- list()

for (w in waves) {
  cat("Fetching wave:", w, "\n")
  slug <- paste0("wohnungsinventar-zweitwohnungsanteil_", w)

  # Construct download URL
  # File naming pattern: {slug}_2056.xlsx.zip
  xlsx_url <- paste0(base_url, "/", slug, "/", slug, "_2056.xlsx.zip")

  tmp_zip <- tempfile(fileext = ".zip")
  tmp_dir <- tempdir()

  resp <- httr::GET(xlsx_url, httr::write_disk(tmp_zip, overwrite = TRUE))

  if (httr::status_code(resp) != 200) {
    cat("  WARNING: HTTP", httr::status_code(resp), "for wave", w, "- skipping\n")
    next
  }

  # Unzip
  unzip(tmp_zip, exdir = tmp_dir)

  # Find the xlsx file
  xlsx_files <- list.files(tmp_dir, pattern = paste0("ZWG.*\\.xlsx$"), full.names = TRUE)
  if (length(xlsx_files) == 0) {
    # Try alternative pattern
    xlsx_files <- list.files(tmp_dir, pattern = "\\.xlsx$", full.names = TRUE)
  }

  if (length(xlsx_files) == 0) {
    cat("  WARNING: No xlsx found for wave", w, "\n")
    next
  }

  # Read the data sheet (skip metadata sheet)
  xlsx_file <- xlsx_files[length(xlsx_files)]  # Take latest if multiple
  sheets <- readxl::excel_sheets(xlsx_file)
  data_sheet <- sheets[grepl("ZWG", sheets)]

  if (length(data_sheet) == 0) {
    cat("  WARNING: No ZWG sheet found in", basename(xlsx_file), "\n")
    next
  }

  df <- readxl::read_excel(xlsx_file, sheet = data_sheet[1])
  df$wave <- w
  all_data[[w]] <- df

  cat("  OK:", nrow(df), "municipalities\n")

  # Clean up
  file.remove(tmp_zip)
  file.remove(xlsx_file)
}

stopifnot("No data downloaded — API failure" = length(all_data) > 0)

# Combine all waves
zwg_panel <- bind_rows(all_data)
cat("\nTotal observations:", nrow(zwg_panel), "\n")
cat("Unique municipalities:", n_distinct(zwg_panel$Gem_No), "\n")
cat("Waves downloaded:", n_distinct(zwg_panel$wave), "\n")

# Standardize column names
zwg_panel <- zwg_panel %>%
  rename(
    muni_id = Gem_No,
    muni_name = Name,
    canton_no = Kt_No,
    canton = Kt_Kz,
    total_dwellings = ZWG_3150,
    primary_count = ZWG_3010,
    primary_pct = ZWG_3110,
    secondary_pct = ZWG_3120
  )

# Save
saveRDS(zwg_panel, file.path(data_dir, "zwg_panel_raw.rds"))
cat("Saved zwg_panel_raw.rds\n")

## ---- 2. Municipal population data from BFS PXWeb ----
## Table px-x-0102010000_101: Permanent resident population by municipality

pop_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102010000_101/px-x-0102010000_101.px"

# Query for 2020 population (midpoint of observation period)
pop_query <- list(
  query = list(
    list(code = "Jahr", selection = list(filter = "item", values = list("2020")))
  ),
  response = list(format = "json-stat2")
)

pop_resp <- httr::POST(
  pop_url,
  body = jsonlite::toJSON(pop_query, auto_unbox = TRUE),
  httr::content_type_json(),
  encode = "raw"
)

if (httr::status_code(pop_resp) == 200) {
  pop_json <- httr::content(pop_resp, as = "text", encoding = "UTF-8")
  pop_data <- jsonlite::fromJSON(pop_json)
  cat("Population data retrieved from BFS PXWeb.\n")

  # Parse JSON-stat2 format
  dims <- pop_data$dimension
  values <- pop_data$value

  # Extract municipality dimension
  muni_dim <- dims$`Gemeinde......`
  if (!is.null(muni_dim)) {
    muni_labels <- muni_dim$category$label
    muni_ids <- names(muni_labels)
    pop_df <- data.frame(
      muni_id_bfs = muni_ids,
      muni_name_bfs = unlist(muni_labels),
      population_2020 = values,
      stringsAsFactors = FALSE
    )
    pop_df$muni_id_num <- as.integer(gsub("\\D", "", pop_df$muni_id_bfs))
    saveRDS(pop_df, file.path(data_dir, "population_2020.rds"))
    cat("Saved population_2020.rds:", nrow(pop_df), "municipalities\n")
  } else {
    cat("WARNING: Could not parse BFS population JSON-stat2 format.\n")
    cat("Available dimensions:", paste(names(dims), collapse = ", "), "\n")
  }
} else {
  cat("WARNING: BFS PXWeb population query returned HTTP", httr::status_code(pop_resp), "\n")
  cat("Will proceed without population data.\n")
}

## ---- 3. BFS empty dwelling rates ----
## Table px-x-0902030000_103

empty_url <- "https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0902030000_103/px-x-0902030000_103.px"

empty_query <- list(
  query = list(
    list(code = "Jahr", selection = list(filter = "item", values = list("2020", "2021", "2022", "2023", "2024")))
  ),
  response = list(format = "json-stat2")
)

empty_resp <- httr::POST(
  empty_url,
  body = jsonlite::toJSON(empty_query, auto_unbox = TRUE),
  httr::content_type_json(),
  encode = "raw"
)

if (httr::status_code(empty_resp) == 200) {
  empty_json <- httr::content(empty_resp, as = "text", encoding = "UTF-8")
  cat("Empty dwelling data retrieved from BFS PXWeb.\n")
  saveRDS(empty_json, file.path(data_dir, "empty_dwellings_raw.rds"))
} else {
  cat("NOTE: Empty dwelling data not available (HTTP", httr::status_code(empty_resp), ").\n")
  cat("Will proceed without empty dwelling rates.\n")
}

cat("\n=== Data fetch complete ===\n")
cat("Files in data/:\n")
print(list.files(data_dir))
