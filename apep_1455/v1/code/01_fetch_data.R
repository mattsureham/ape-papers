# 01_fetch_data.R — Fetch Stats NZ Building Consents data
source("00_packages.R")

# Stats NZ Building Consents — monthly Excel releases with historical annual data
# Table 4: Annual region × dwelling type (2016-2026)
# Table 6: Annual TA-level totals (2021-2026)

url <- "https://www.stats.govt.nz/assets/Uploads/Building-consents-issued/Building-consents-issued-February-2026/Download-data/building-consents-issued-february-2026.xlsx"
dest <- "../data/building_consents_raw.xlsx"

cat("Downloading Stats NZ Building Consents (Feb 2026 release)...\n")
resp <- httr::GET(url, httr::write_disk(dest, overwrite = TRUE), httr::timeout(120))
stopifnot(httr::status_code(resp) == 200)
cat("Downloaded:", file.size(dest), "bytes\n")

# ---- Parse Table 4: Annual region × dwelling type ----
t4 <- readxl::read_excel(dest, sheet = "Table 4", col_names = FALSE)

# Extract years from row 7
years_row <- as.character(unlist(t4[7, ]))
# First 11 year columns are absolute counts (2016-2026)
# Next columns are percentage changes — skip those
year_cols <- which(!is.na(years_row) & grepl("^20", years_row))
years <- as.integer(years_row[year_cols])
# Keep only the first occurrence of each year (absolute counts, not % change)
dup <- duplicated(years)
year_cols <- year_cols[!dup]
years <- years[!dup]
cat("Years:", paste(years, collapse = ", "), "\n")

# Extract region × dwelling type data
# Regions start at row 9 and go in blocks: region name, then Total/Houses/Multi-unit
results <- list()
current_region <- NA
skip_regions <- c("North Island", "South Island(3)", "Area outside region(4)", "New Zealand")
seen_nz <- FALSE
for (i in 9:nrow(t4)) {
  col1 <- as.character(t4[i, 1])
  col2 <- as.character(t4[i, 2])
  # Stop after "New Zealand" row (before % change section)
  if (!is.na(col1) && col1 == "New Zealand") { seen_nz <- TRUE }
  if (seen_nz && !is.na(col1) && col1 == "Percentage change from previous year") break

  # Region names are in col 1 (col 2 is NA)
 if (!is.na(col1) && col1 != "") {
    if (col1 %in% skip_regions || grepl("^(Number|Symbol|Source|Note|\\()", col1)) next
    current_region <- col1
    next
  }

  # Dwelling types are in col 2
  if (is.na(col2) || is.na(current_region)) next
  if (!col2 %in% c("Total", "Houses", "Multi-unit homes(1)")) next

  vals <- suppressWarnings(as.numeric(unlist(t4[i, year_cols])))

  dwelling_type <- case_when(
    col2 == "Total" ~ "total",
    col2 == "Houses" ~ "houses",
    col2 == "Multi-unit homes(1)" ~ "multi_unit"
  )

  for (j in seq_along(years)) {
    results[[length(results) + 1]] <- tibble(
      region = current_region,
      year = years[j],
      dwelling_type = dwelling_type,
      n_consents = vals[j]
    )
  }
}

df_region <- bind_rows(results)
cat("Parsed", nrow(df_region), "region-year-type observations\n")
cat("Regions:", paste(unique(df_region$region), collapse = ", "), "\n")

# Pivot wider: one row per region-year with total, houses, multi_unit
df_region <- df_region %>%
  mutate(n_consents = as.numeric(n_consents)) %>%
  # Remove any duplicates (from % change section)
  distinct(region, year, dwelling_type, .keep_all = TRUE)

cat("After dedup:", nrow(df_region), "rows,", n_distinct(df_region$region), "regions\n")

df_wide <- df_region %>%
  pivot_wider(names_from = dwelling_type, values_from = n_consents) %>%
  mutate(
    total = as.numeric(total),
    houses = as.numeric(houses),
    multi_unit = as.numeric(multi_unit),
    multi_unit_share = multi_unit / total,
    houses_share = houses / total
  )

cat("\nSample of data:\n")
print(df_wide %>% filter(region %in% c("Waikato", "Bay of Plenty", "Northland")) %>% arrange(region, year))

saveRDS(df_wide, "../data/region_consents.rds")
cat("\nSaved region-level consents data.\n")

# ---- Parse Table 6: TA-level total consents (annual) ----
t6 <- readxl::read_excel(dest, sheet = "Table 6", col_names = FALSE)

# Years in row 7
yr_row6 <- as.character(unlist(t6[7, ]))
yr_cols6 <- which(!is.na(yr_row6) & grepl("^20", yr_row6))
yrs6 <- as.integer(yr_row6[yr_cols6])
dup6 <- duplicated(yrs6)
yr_cols6 <- yr_cols6[!dup6]
yrs6 <- yrs6[!dup6]
cat("\nTable 6 years:", paste(yrs6, collapse = ", "), "\n")

# TA names start at row 10
ta_results <- list()
for (i in 10:nrow(t6)) {
  ta_name <- as.character(t6[i, 1])
  if (is.na(ta_name) || ta_name == "" || grepl("^(Number|Symbol|Source|Note|\\()", ta_name)) next
  # Skip Auckland local boards (indented under Auckland)
  # Keep only district/city TAs
  vals <- suppressWarnings(as.numeric(unlist(t6[i, yr_cols6])))
  if (all(is.na(vals))) next

  for (j in seq_along(yrs6)) {
    ta_results[[length(ta_results) + 1]] <- tibble(
      ta = ta_name,
      year = yrs6[j],
      total_consents = vals[j]
    )
  }
}

df_ta <- bind_rows(ta_results)
cat("Parsed", nrow(df_ta), "TA-year observations\n")
cat("TAs found:", length(unique(df_ta$ta)), "\n")

saveRDS(df_ta, "../data/ta_consents.rds")
cat("Saved TA-level consents data.\n")
