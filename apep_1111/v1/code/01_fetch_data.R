# 01_fetch_data.R — Fetch all data for FEMA Risk Rating 2.0 analysis
# Sources: FEMA NFIP Claims API (v2), Census Building Permits Survey, BLS LAUS

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. FEMA NFIP Claims — County-Level Flood Exposure (Treatment Intensity)
# ============================================================================
# Strategy: Historical claims per capita proxy treatment intensity.
# Counties with more historical flood damage faced larger RR2.0 premium increases
# because old zone-based pricing systematically underpriced their risk.

cat("=== Fetching FEMA NFIP Claims (county-level) ===\n")

fetch_claims_batch <- function(skip = 0, batch_size = 10000) {
  url <- sprintf(
    "https://www.fema.gov/api/open/v2/FimaNfipClaims?$top=%d&$skip=%d&$select=countyCode,yearOfLoss,amountPaidOnBuildingClaim,amountPaidOnContentsClaim,state,totalBuildingInsuranceCoverage&$orderby=id",
    batch_size, skip
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(180)), error = function(e) NULL)
  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)
  content <- tryCatch(
    httr::content(resp, as = "text", encoding = "UTF-8"),
    error = function(e) NULL
  )
  if (is.null(content)) return(NULL)
  parsed <- tryCatch(jsonlite::fromJSON(content), error = function(e) NULL)
  if (is.null(parsed) || !"FimaNfipClaims" %in% names(parsed)) return(NULL)
  result <- parsed$FimaNfipClaims
  if (!is.data.frame(result) || nrow(result) == 0) return(NULL)
  return(result)
}

# Fetch claims data in batches — focus on getting enough for county aggregation
all_claims <- list()
skip <- 0
batch_size <- 10000
max_records <- 2000000  # Cap at 2M for API stability

cat("Fetching NFIP claims (this may take several minutes)...\n")
repeat {
  chunk <- fetch_claims_batch(skip, batch_size)
  if (is.null(chunk)) break
  all_claims[[length(all_claims) + 1]] <- chunk
  total_so_far <- sum(sapply(all_claims, nrow))
  if (total_so_far %% 100000 < batch_size) {
    cat(sprintf("  Fetched %s claims...\n", format(total_so_far, big.mark = ",")))
  }
  skip <- skip + batch_size
  if (total_so_far >= max_records) break
  Sys.sleep(0.2)
}

claims_df <- bind_rows(all_claims)
cat(sprintf("Total NFIP claims fetched: %s\n", format(nrow(claims_df), big.mark = ",")))
stopifnot("No claims data fetched" = nrow(claims_df) > 0)

# Aggregate to county level
claims_county <- claims_df %>%
  mutate(
    fips = countyCode,
    total_paid = coalesce(amountPaidOnBuildingClaim, 0) +
                 coalesce(amountPaidOnContentsClaim, 0),
    pre_rr2 = yearOfLoss < 2021
  ) %>%
  filter(!is.na(fips), nchar(fips) == 5) %>%
  group_by(fips, state) %>%
  summarise(
    total_claims = n(),
    pre_rr2_claims = sum(pre_rr2),
    total_paid_millions = sum(total_paid, na.rm = TRUE) / 1e6,
    pre_rr2_paid_millions = sum(total_paid[pre_rr2], na.rm = TRUE) / 1e6,
    avg_claim = mean(total_paid, na.rm = TRUE),
    .groups = "drop"
  )

saveRDS(claims_county, file.path(data_dir, "claims_county.rds"))
cat(sprintf("Claims by county: %d counties\n", nrow(claims_county)))
cat(sprintf("  Total paid: $%s million\n",
            format(sum(claims_county$total_paid_millions), big.mark = ",")))

# Also create annual county claims panel for event study controls
claims_annual <- claims_df %>%
  mutate(fips = countyCode) %>%
  filter(!is.na(fips), nchar(fips) == 5, yearOfLoss >= 2005) %>%
  group_by(fips, year = yearOfLoss) %>%
  summarise(
    n_claims = n(),
    paid_millions = sum(coalesce(amountPaidOnBuildingClaim, 0) +
                        coalesce(amountPaidOnContentsClaim, 0),
                        na.rm = TRUE) / 1e6,
    .groups = "drop"
  )

saveRDS(claims_annual, file.path(data_dir, "claims_annual.rds"))

# ============================================================================
# 2. Census Building Permits Survey — Annual County Data
# ============================================================================
cat("\n=== Fetching Census Building Permits Survey ===\n")

fetch_bps_year <- function(year) {
  url <- sprintf("https://www2.census.gov/econ/bps/County/co%da.txt", year)
  cat(sprintf("  BPS %d...", year))

  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat(" FAILED\n")
    return(NULL)
  }

  content_text <- httr::content(resp, as = "text", encoding = "UTF-8")

  # BPS files have a 2-line header + blank line, then data
  lines <- strsplit(content_text, "\n")[[1]]
  # Skip first 2 header lines and any blank lines
  data_lines <- lines[-(1:2)]
  data_lines <- data_lines[nchar(trimws(data_lines)) > 0]

  if (length(data_lines) == 0) {
    cat(" NO DATA LINES\n")
    return(NULL)
  }

  # Create column names based on known BPS structure
  col_names <- c("survey_year", "state_fips", "county_fips", "region", "division", "county_name",
                 "u1_bldgs", "u1_units", "u1_value",
                 "u2_bldgs", "u2_units", "u2_value",
                 "u34_bldgs", "u34_units", "u34_value",
                 "u5p_bldgs", "u5p_units", "u5p_value",
                 "u1r_bldgs", "u1r_units", "u1r_value",
                 "u2r_bldgs", "u2r_units", "u2r_value",
                 "u34r_bldgs", "u34r_units", "u34r_value",
                 "u5pr_bldgs", "u5pr_units", "u5pr_value")

  df <- tryCatch({
    d <- read.csv(text = paste(data_lines, collapse = "\n"),
                  header = FALSE, stringsAsFactors = FALSE,
                  strip.white = TRUE, fill = TRUE)
    ncols <- min(ncol(d), length(col_names))
    names(d)[1:ncols] <- col_names[1:ncols]
    d
  }, error = function(e) NULL)

  if (is.null(df) || nrow(df) == 0) {
    cat(" PARSE ERROR\n")
    return(NULL)
  }

  df$year <- year
  cat(sprintf(" OK (%d rows)\n", nrow(df)))
  return(df)
}

bps_list <- list()
for (yr in 2010:2024) {
  result <- fetch_bps_year(yr)
  if (!is.null(result)) {
    bps_list[[as.character(yr)]] <- result
  }
  Sys.sleep(0.5)
}

cat(sprintf("BPS data fetched for %d years\n", length(bps_list)))
stopifnot("FATAL: No building permits data" = length(bps_list) > 0)

cat("BPS columns: ", paste(names(bps_list[[1]]), collapse = ", "), "\n")
saveRDS(bps_list, file.path(data_dir, "bps_raw_list.rds"))

# ============================================================================
# 3. BLS LAUS — County Unemployment (control variable)
# ============================================================================
cat("\n=== Fetching BLS LAUS data ===\n")

resp_laus <- tryCatch(
  httr::GET(
    "https://download.bls.gov/pub/time.series/la/la.data.64.County",
    httr::timeout(300),
    httr::add_headers("User-Agent" = "APEP Research (academic use)")
  ),
  error = function(e) NULL
)

if (!is.null(resp_laus) && httr::status_code(resp_laus) == 200) {
  laus_text <- httr::content(resp_laus, as = "text", encoding = "UTF-8")
  laus_raw <- read.delim(text = laus_text, header = TRUE,
                         strip.white = TRUE, stringsAsFactors = FALSE)
  cat(sprintf("LAUS records: %d\n", nrow(laus_raw)))
  saveRDS(laus_raw, file.path(data_dir, "laus_raw.rds"))
} else {
  cat("LAUS download unavailable. Proceeding without unemployment controls.\n")
}

# ============================================================================
# 4. County Population (Census intercensal estimates via API)
# ============================================================================
cat("\n=== Fetching county population estimates ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) {
  pop_url <- sprintf(
    "https://api.census.gov/data/2020/dec/dhc?get=NAME,P1_001N&for=county:*&key=%s",
    census_key
  )
  resp_pop <- tryCatch(httr::GET(pop_url, httr::timeout(60)), error = function(e) NULL)

  if (!is.null(resp_pop) && httr::status_code(resp_pop) == 200) {
    pop_content <- httr::content(resp_pop, as = "text", encoding = "UTF-8")
    pop_raw <- jsonlite::fromJSON(pop_content)
    pop_df <- as.data.frame(pop_raw[-1, ], stringsAsFactors = FALSE)
    names(pop_df) <- pop_raw[1, ]
    pop_df <- pop_df %>%
      mutate(
        fips = paste0(state, county),
        population = as.numeric(P1_001N)
      ) %>%
      select(fips, county_name = NAME, population)

    saveRDS(pop_df, file.path(data_dir, "county_population.rds"))
    cat(sprintf("County population: %d counties\n", nrow(pop_df)))
  }
} else {
  cat("No Census API key. Skipping population download.\n")
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data Fetch Summary ===\n")
for (f in sort(list.files(data_dir, pattern = "\\.rds$"))) {
  obj <- readRDS(file.path(data_dir, f))
  if (is.data.frame(obj)) {
    cat(sprintf("  %s: %d rows x %d cols\n", f, nrow(obj), ncol(obj)))
  } else if (is.list(obj)) {
    cat(sprintf("  %s: list of %d elements\n", f, length(obj)))
  }
}
cat("\nData fetch complete.\n")
