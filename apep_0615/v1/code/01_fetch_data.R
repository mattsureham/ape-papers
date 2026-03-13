# 01_fetch_data.R — Fetch NADAC data from CMS data.medicaid.gov
# Uses the datastore query POST API with conditions filter

source("00_packages.R")

cat("=== Fetching NADAC brand drug data from CMS ===\n")

# NADAC dataset IDs by year
nadac_ids <- c(
  "2013" = "1fe73992-cbfd-5109-97bc-dee8b33fdcff",
  "2014" = "ba0c3734-8012-549a-8f50-2ff389d0e0ef",
  "2015" = "4d7af295-2132-55a8-b40c-d6630061f3e8",
  "2016" = "7656fc17-f1b4-566b-9a2d-c4a4f2ac7ae1",
  "2017" = "1c5d0fc9-693a-534a-8240-4627d9362b0d",
  "2018" = "8de1b213-73c5-552b-b84e-ac795f34d056",
  "2019" = "76a1984a-6d69-5e4d-86c8-65eb31f0506d",
  "2020" = "c933dc16-7de9-52b6-8971-4b75992673e0",
  "2021" = "d5eaf378-dcef-5779-83de-acdd8347d68e",
  "2022" = "dfa2ab14-06c2-457a-9e36-5cb6d80f8d93",
  "2023" = "4a00010a-132b-4e4d-a611-543c9521280f",
  "2024" = "99315a95-37ac-4eee-946a-3c523b4c481e",
  "2025" = "f38d0706-1239-442c-a3cc-40ef1b686ac0"
)

fetch_nadac_year <- function(dataset_id, year) {
  cat(sprintf("  Fetching %s brand drugs...\n", year))
  base_url <- sprintf(
    "https://data.medicaid.gov/api/1/datastore/query/%s/0",
    dataset_id
  )

  all_rows <- list()
  offset <- 0
  batch_size <- 5000

  repeat {
    body <- list(
      conditions = list(
        list(
          property = "classification_for_rate_setting",
          value = "B",
          operator = "="
        )
      ),
      limit = batch_size,
      offset = offset
    )

    resp <- httr::POST(
      base_url,
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      httr::content_type_json(),
      httr::timeout(180)
    )

    if (httr::status_code(resp) != 200) {
      warning("API returned status ", httr::status_code(resp), " for ", year)
      break
    }

    txt <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(txt, flatten = TRUE)
    results <- parsed$results

    if (is.null(results) || length(results) == 0 ||
        (is.data.frame(results) && nrow(results) == 0)) break

    all_rows[[length(all_rows) + 1]] <- as_tibble(results)
    n_got <- nrow(results)
    cat(sprintf("    offset=%d, got %d rows (total: %s)\n",
                offset, n_got, format(parsed$count, big.mark = ",")))

    if (n_got < batch_size) break
    offset <- offset + batch_size
  }

  if (length(all_rows) == 0) {
    cat(sprintf("  Year %s: NO BRAND DATA\n", year))
    return(NULL)
  }

  df <- bind_rows(all_rows)
  cat(sprintf("  Year %s: %s brand records\n", year, format(nrow(df), big.mark = ",")))
  df
}

# Fetch all years
nadac_raw <- list()
for (yr in names(nadac_ids)) {
  result <- fetch_nadac_year(nadac_ids[yr], yr)
  if (!is.null(result)) {
    nadac_raw[[yr]] <- result
  }
}

nadac <- bind_rows(nadac_raw)
cat(sprintf("\nTotal brand drug records fetched: %s\n", format(nrow(nadac), big.mark = ",")))

# HARD FAIL if no data
if (nrow(nadac) == 0) {
  stop("FATAL: No NADAC data fetched. API may be down.")
}

# Clean and type-convert
nadac <- nadac %>%
  mutate(
    nadac_per_unit = as.numeric(nadac_per_unit),
    effective_date = as.Date(effective_date),
    year  = lubridate::year(effective_date),
    month = lubridate::month(effective_date),
    quarter = lubridate::quarter(effective_date)
  ) %>%
  filter(!is.na(nadac_per_unit), nadac_per_unit > 0)

cat(sprintf("After cleaning: %s records, %d unique NDCs\n",
            format(nrow(nadac), big.mark = ","),
            n_distinct(nadac$ndc)))

# Save
saveRDS(nadac, "../data/nadac_brand.rds")
cat("Saved: ../data/nadac_brand.rds\n")

# Validation
cat("\n=== Validation ===\n")
cat(sprintf("Years covered: %d to %d\n", min(nadac$year), max(nadac$year)))
cat(sprintf("Unique NDCs: %d\n", n_distinct(nadac$ndc)))
cat(sprintf("Date range: %s to %s\n", min(nadac$effective_date), max(nadac$effective_date)))
nadac %>% count(year) %>% print(n = 20)
