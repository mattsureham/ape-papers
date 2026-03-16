## 01_fetch_data.R — Fetch data from SCB (Statistics Sweden) API
## APEP-0705: Sweden's RUT Household Services Deduction

source("00_packages.R")

data_dir <- "../data"

## --- Helper: query SCB PxWeb and return tidy tibble ---
fetch_scb_tidy <- function(table_path, query_body, value_name = "value") {
  url <- paste0("https://api.scb.se/OV0104/v1/doris/en/ssd/", table_path)

  resp <- POST(url, body = query_body, encode = "json", content_type_json())

  if (status_code(resp) != 200) {
    stop("SCB API error ", status_code(resp), " for ", table_path)
  }

  raw <- content(resp, "text", encoding = "UTF-8")
  parsed <- fromJSON(raw)

  dims <- parsed$dimension
  dim_names <- names(dims)
  values <- parsed$value

  # Build label vectors in index order for each dimension
  dim_labels <- lapply(dim_names, function(d) {
    cats <- dims[[d]]$category
    idx <- unlist(cats$index)
    labs <- unlist(cats$label)
    labs[order(idx)]
  })
  names(dim_labels) <- dim_names

  # JSON-stat2: last dimension varies fastest (C-order)
  # expand.grid: first dimension varies fastest (F-order)
  # Solution: reverse dimension order for expand.grid, then reorder columns back
  grid <- expand.grid(rev(dim_labels), stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  grid <- grid[, rev(seq_len(ncol(grid)))]  # reverse columns back to original order
  grid[[value_name]] <- values
  as_tibble(grid)
}

## ============================================================
## 1. INCOME: Mean income by municipality, 1999-2024
## ============================================================
cat("=== Fetching mean earned income by municipality (1999-2024) ===\n")

# Get municipality codes from metadata
meta_resp <- GET("https://api.scb.se/OV0104/v1/doris/en/ssd/HE/HE0110/HE0110A/SamForvInk1")
meta <- content(meta_resp, "parsed")
all_regions <- meta$variables[[1]]$values
region_texts <- meta$variables[[1]]$valueTexts
muni_mask <- nchar(all_regions) == 4
muni_codes <- all_regions[muni_mask]
muni_names <- region_texts[muni_mask]
cat("Found", length(muni_codes), "municipalities\n")

all_years <- as.character(1999:2024)
batch_size <- 50
income_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  Income batch", ceiling(i / batch_size), "\n")

  # Request ONLY mean income (HE0110J7), total sex, 20-64, total bracket
  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = batch)),
      list(code = "Kon", selection = list(filter = "item", values = list("1+2"))),
      list(code = "Alder", selection = list(filter = "item", values = list("20-64"))),
      list(code = "Inkomstklass", selection = list(filter = "item", values = list("TOT"))),
      list(code = "ContentsCode", selection = list(filter = "item",
           values = list("HE0110J7", "HE0110J9")))
    ),
    response = list(format = "json-stat2")
  )

  result <- fetch_scb_tidy("HE/HE0110/HE0110A/SamForvInk1", query)
  income_list <- c(income_list, list(result))
  Sys.sleep(0.3)
}

income_raw <- bind_rows(income_list)
cat("Raw income rows:", nrow(income_raw), "\n")

# Separate mean income and person count
income_df <- income_raw %>%
  pivot_wider(
    names_from = ContentsCode,
    values_from = value
  ) %>%
  rename(
    region = Region,
    year = Tid
  ) %>%
  select(region, year, everything(), -Kon, -Alder, -Inkomstklass)

# Fix column names based on what JSON-stat returns
content_names <- names(income_df)[3:4]
cat("Content columns:", paste(content_names, collapse = ", "), "\n")

# Rename to standard names
names(income_df)[3] <- "mean_income"
names(income_df)[4] <- "n_persons"

income_df <- income_df %>%
  mutate(year = as.integer(year))

cat("Income panel: ", n_distinct(income_df$region), "munis x",
    n_distinct(income_df$year), "years =", nrow(income_df), "obs\n")

# Quick sanity: Stockholm 2006 should be ~280-350 SEK thousands
sthlm_06 <- income_df %>% filter(grepl("Stockholm", region), year == 2006)
cat("Stockholm 2006 mean income:", sthlm_06$mean_income, "SEK thousands\n")

## ============================================================
## 2. TREATMENT INTENSITY: Mean income in 2006
## ============================================================
cat("\n=== Computing treatment intensity ===\n")

treatment_df <- income_df %>%
  filter(year == 2006) %>%
  select(region, mean_income_2006 = mean_income, n_persons_2006 = n_persons) %>%
  mutate(
    # Standardized treatment intensity (z-score)
    treat_intensity = (mean_income_2006 - mean(mean_income_2006, na.rm = TRUE)) /
                       sd(mean_income_2006, na.rm = TRUE),
    # Quartiles for heterogeneity analysis
    income_quartile = ntile(mean_income_2006, 4)
  )

cat("Treatment intensity: mean =", round(mean(treatment_df$treat_intensity), 3),
    ", sd =", round(sd(treatment_df$treat_intensity), 3), "\n")
cat("Mean income 2006: min =", round(min(treatment_df$mean_income_2006, na.rm=TRUE), 1),
    ", max =", round(max(treatment_df$mean_income_2006, na.rm=TRUE), 1),
    ", mean =", round(mean(treatment_df$mean_income_2006, na.rm=TRUE), 1), "\n")

## ============================================================
## 3. EMPLOYMENT M+N sector (SNI2007, 2008-2018)
## ============================================================
cat("\n=== Fetching M+N sector employment (2008-2018) ===\n")

sectors_07 <- c("M+N", "B+C", "I", "R+S+T+U", "P", "Q")
emp07_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  Sector batch", ceiling(i / batch_size), "\n")

  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = batch)),
      list(code = "SNI2007", selection = list(filter = "item", values = as.list(sectors_07))),
      list(code = "Kon", selection = list(filter = "item", values = list("1", "2")))
    ),
    response = list(format = "json-stat2")
  )

  result <- fetch_scb_tidy("AM/AM0207/AM0207J/NattSNI07KonK", query)
  emp07_list <- c(emp07_list, list(result))
  Sys.sleep(0.3)
}

emp07_df <- bind_rows(emp07_list) %>%
  rename(region = Region, sector = SNI2007, sex = Kon, year = Tid, emp = value) %>%
  mutate(year = as.integer(year))

cat("SNI2007 records:", nrow(emp07_df), "\n")
cat("Years:", paste(sort(unique(emp07_df$year)), collapse = ", "), "\n")

## ============================================================
## 4. EMPLOYMENT pre-reform (SNI2002, 2004-2007)
## ============================================================
cat("\n=== Fetching pre-reform employment (SNI2002, 2004-2007) ===\n")

sectors_02 <- c("J+Kexkl73", "C+D", "H+Oexkl90+P")
emp02_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  SNI2002 batch", ceiling(i / batch_size), "\n")

  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = batch)),
      list(code = "SNI2002", selection = list(filter = "item", values = as.list(sectors_02))),
      list(code = "Kon", selection = list(filter = "item", values = list("1", "2")))
    ),
    response = list(format = "json-stat2")
  )

  result <- fetch_scb_tidy("AM/AM0207/AM0207J/NattSNIKonK", query)
  emp02_list <- c(emp02_list, list(result))
  Sys.sleep(0.3)
}

emp02_df <- bind_rows(emp02_list) %>%
  rename(region = Region, sector = SNI2002, sex = Kon, year = Tid, emp = value) %>%
  mutate(year = as.integer(year))

cat("SNI2002 records:", nrow(emp02_df), "\n")

## ============================================================
## 5. EMPLOYMENT RATE by birth origin (2004-2018)
## ============================================================
cat("\n=== Fetching employment rates by native/foreign-born (2004-2018) ===\n")

emprate_list <- list()

for (i in seq(1, length(muni_codes), by = batch_size)) {
  batch <- muni_codes[i:min(i + batch_size - 1, length(muni_codes))]
  cat("  Emp rate batch", ceiling(i / batch_size), "\n")

  query <- list(
    query = list(
      list(code = "Region", selection = list(filter = "item", values = batch)),
      list(code = "InrikesUtrikes", selection = list(filter = "item",
           values = list("13", "23"))),
      list(code = "Kon", selection = list(filter = "item", values = list("4")))
    ),
    response = list(format = "json-stat2")
  )

  result <- fetch_scb_tidy("AM/AM0207/AM0207J/RAMSForvInt04", query)
  emprate_list <- c(emprate_list, list(result))
  Sys.sleep(0.3)
}

emprate_df <- bind_rows(emprate_list) %>%
  rename(region = Region, origin = InrikesUtrikes, sex = Kon, year = Tid,
         emp_rate = value) %>%
  mutate(year = as.integer(year))

cat("Employment rate records:", nrow(emprate_df), "\n")

## ============================================================
## SAVE
## ============================================================
cat("\n=== Saving data ===\n")

saveRDS(income_df, file.path(data_dir, "income_municipality.rds"))
saveRDS(treatment_df, file.path(data_dir, "treatment_intensity.rds"))
saveRDS(emp07_df, file.path(data_dir, "employment_sni07.rds"))
saveRDS(emp02_df, file.path(data_dir, "employment_sni02.rds"))
saveRDS(emprate_df, file.path(data_dir, "employment_rate_origin.rds"))
saveRDS(tibble(code = muni_codes, name = muni_names),
        file.path(data_dir, "municipality_names.rds"))

# Validation
stopifnot("Need 280+ municipalities" = n_distinct(income_df$region) >= 280)
stopifnot("Need 25+ years" = n_distinct(income_df$year) >= 25)
stopifnot("Treatment intensity not all NA" = sum(!is.na(treatment_df$treat_intensity)) > 250)

cat("\n=== ALL DATA FETCHED AND SAVED ===\n")
