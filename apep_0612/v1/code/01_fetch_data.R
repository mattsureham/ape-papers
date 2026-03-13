## 01_fetch_data.R — Fetch data from APIs
## apep_0612: Immigration Judge Leniency and Local Crime

source("code/00_packages.R")

# Load environment variables (for Census API key)
dotenv_path <- file.path(Sys.getenv("HOME"), "auto-policy-evals", ".env")
if (file.exists(dotenv_path)) {
  lines <- readLines(dotenv_path, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) > 0 && !startsWith(line, "#") && grepl("=", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub('^"|"$', "", val)
      val <- gsub("^'|'$", "", val)
      Sys.setenv(key = val)  # won't work generically
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

cat("=== Fetching OpenImmigration.us Court Data ===\n")

# 1. Court Index
court_url <- "https://www.openimmigration.us/data/court-index.json"
courts_raw <- fromJSON(court_url)
stopifnot("Failed to fetch court data" = nrow(courts_raw) > 0)
cat(sprintf("Fetched %d courts\n", nrow(courts_raw)))
saveRDS(courts_raw, "data/courts_raw.rds")

# 2. Judge Index
judge_url <- "https://www.openimmigration.us/data/judge-index.json"
judges_raw <- fromJSON(judge_url)
stopifnot("Failed to fetch judge data" = nrow(judges_raw) > 0)
cat(sprintf("Fetched %d judges\n", nrow(judges_raw)))
saveRDS(judges_raw, "data/judges_raw.rds")

# 3. Per-court judge details (topJudges for each court)
cat("=== Fetching per-court judge details ===\n")
court_judges_list <- list()

for (i in seq_len(nrow(courts_raw))) {
  slug <- courts_raw$slug[i]
  court_code <- courts_raw$code[i]
  url <- sprintf("https://www.openimmigration.us/data/courts/%s.json", slug)

  tryCatch({
    resp <- fromJSON(url)
    top_judges <- resp$topJudges
    if (!is.null(top_judges) && length(top_judges) > 0) {
      top_judges$court_code <- court_code
      top_judges$court_slug <- slug
      top_judges$court_state <- courts_raw$state[i]
      court_judges_list[[court_code]] <- top_judges
    }
    if (i %% 20 == 0) cat(sprintf("  Fetched %d/%d courts\n", i, nrow(courts_raw)))
    Sys.sleep(0.1)  # polite rate limit
  }, error = function(e) {
    cat(sprintf("  Warning: failed to fetch court %s: %s\n", slug, e$message))
  })
}

court_judges_raw <- bind_rows(court_judges_list)
cat(sprintf("Fetched judge details for %d court-judge pairs\n", nrow(court_judges_raw)))
saveRDS(court_judges_raw, "data/court_judges_raw.rds")

# 4. CDC Mapping Injury — county-level homicide data (2019-2024)
cat("\n=== Fetching CDC Homicide Data ===\n")

cdc_base <- "https://data.cdc.gov/resource/psx4-wq38.json"

# Fetch All_Homicide, FA_Homicide, and All_Suicide for all counties/years
# API columns: geoid, name, st_geoid, st_name, intent, period, count_sup, rate, rate_m
cdc_intents <- c("All_Homicide", "FA_Homicide", "All_Suicide")
cdc_data_list <- list()

for (intent in cdc_intents) {
  cat(sprintf("  Fetching %s...\n", intent))
  offset <- 0
  batch_size <- 50000
  intent_data <- list()

  repeat {
    url <- sprintf(
      "%s?intent=%s&$limit=%d&$offset=%d",
      cdc_base, intent, batch_size, offset
    )
    batch <- tryCatch(fromJSON(url), error = function(e) data.frame())
    if (is.null(batch) || nrow(batch) == 0) break
    intent_data[[length(intent_data) + 1]] <- batch
    offset <- offset + batch_size
    cat(sprintf("    Fetched %d rows (offset %d)\n", nrow(batch), offset))
    if (nrow(batch) < batch_size) break
    Sys.sleep(0.2)
  }

  if (length(intent_data) > 0) {
    cdc_data_list[[intent]] <- bind_rows(intent_data)
  }
}

cdc_raw <- bind_rows(cdc_data_list)
cat(sprintf("Total CDC rows fetched: %d\n", nrow(cdc_raw)))
stopifnot("Failed to fetch CDC data" = nrow(cdc_raw) > 0)
saveRDS(cdc_raw, "data/cdc_raw.rds")

# 5. ACS Demographics via tidycensus
cat("\n=== Fetching ACS Demographics ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  census_key <- Sys.getenv("CENSUS")
}
if (nchar(census_key) > 0) {
  census_api_key(census_key, install = FALSE)
}

acs_vars <- c(
  total_pop      = "B01003_001",
  foreign_born   = "B05012_003",
  poverty_total  = "B17001_001",
  poverty_below  = "B17001_002",
  labor_force    = "B23025_003",
  unemployed     = "B23025_005",
  median_income  = "B19013_001"
)

acs_data <- tryCatch({
  get_acs(
    geography = "state",
    variables = acs_vars,
    year = 2022,
    survey = "acs5",
    output = "wide"
  )
}, error = function(e) {
  cat(sprintf("ACS fetch error: %s\n", e$message))
  # Try without named variables
  get_acs(
    geography = "state",
    variables = unname(acs_vars),
    year = 2022,
    survey = "acs5"
  )
})

cat(sprintf("Fetched ACS data for %d states\n", nrow(acs_data)))
saveRDS(acs_data, "data/acs_raw.rds")

cat("\n=== All data fetched successfully ===\n")
