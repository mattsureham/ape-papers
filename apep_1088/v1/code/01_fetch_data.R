## 01_fetch_data.R — Fetch IRS nonprofit data from EO BMF + ProPublica API
## apep_1088: IRS 990 Threshold Reform and Nonprofit Growth
##
## Data sources:
##   1. IRS EO BMF (Exempt Org Business Master File): universe of exempt orgs
##   2. ProPublica Nonprofit Explorer API: financial time series per EIN
##
## Strategy:
##   - EO BMF gives universe of 501(c)(3) orgs with income/asset ranges
##   - Filter to orgs in the $25K-$300K revenue range (covers manipulation window)
##   - Sample ~6,000 EINs, fetch full financial histories from ProPublica
##   - ProPublica has filings back to ~2005 for many orgs

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

# ============================================================
# STEP 1: Download and parse IRS Exempt Organizations BMF
# ============================================================
cat("=== Step 1: Downloading IRS EO Business Master File ===\n")

bmf_regions <- c("eo1", "eo2", "eo3", "eo4")
bmf_url_base <- "https://www.irs.gov/pub/irs-soi/"
bmf_files <- list()

for (region in bmf_regions) {
  cache_file <- file.path(data_dir, paste0(region, ".csv"))

  if (file.exists(cache_file)) {
    cat(sprintf("  Loading cached %s\n", region))
    bmf <- fread(cache_file, colClasses = "character")
  } else {
    url <- paste0(bmf_url_base, region, ".csv")
    cat(sprintf("  Downloading %s from %s\n", region, url))

    response <- GET(url, timeout(120))
    if (status_code(response) != 200) {
      stop(sprintf("FATAL: Failed to download %s (HTTP %d). Cannot proceed.", region, status_code(response)))
    }

    raw_text <- content(response, "text", encoding = "UTF-8")
    bmf <- fread(raw_text, colClasses = "character")
    fwrite(bmf, cache_file)
  }

  bmf_files[[region]] <- bmf
  cat(sprintf("  %s: %s organizations\n", region, format(nrow(bmf), big.mark = ",")))
}

bmf_all <- rbindlist(bmf_files, fill = TRUE)
cat(sprintf("\nTotal EO BMF records: %s\n", format(nrow(bmf_all), big.mark = ",")))

# Standardize column names (IRS uses inconsistent casing)
names(bmf_all) <- toupper(names(bmf_all))

# Filter to 501(c)(3) organizations (SUBSECTION = 03)
bmf_c3 <- bmf_all[SUBSECTION == "03" | SUBSECTION == "3"]
cat(sprintf("501(c)(3) organizations: %s\n", format(nrow(bmf_c3), big.mark = ",")))

# INCOME_CD categorizes orgs by gross receipts range:
# 1 = $1-$10K, 2 = $10K-$25K, 3 = $25K-$100K, 4 = $100K-$500K,
# 5 = $500K-$1M, 6 = $1M-$5M, 7 = $5M-$10M, 8 = $10M-$50M, 9 = $50M+
# We want codes 3 ($25K-$100K) and 4 ($100K-$500K) — spans our manipulation window

bmf_target <- bmf_c3[INCOME_CD %in% c("3", "4")]
cat(sprintf("Orgs in $25K-$500K range: %s\n", format(nrow(bmf_target), big.mark = ",")))

# ============================================================
# STEP 2: Sample EINs for ProPublica API fetch
# ============================================================
cat("\n=== Step 2: Sampling EINs for API fetch ===\n")

# Stratified sample: equal from income_cd 3 and 4
set.seed(20260327)

n_per_stratum <- 3000
eins_cd3 <- bmf_target[INCOME_CD == "3", sample(EIN, min(n_per_stratum, .N))]
eins_cd4 <- bmf_target[INCOME_CD == "4", sample(EIN, min(n_per_stratum, .N))]
sample_eins <- c(eins_cd3, eins_cd4)

cat(sprintf("Sampled %d EINs from income_cd=3, %d from income_cd=4\n",
    length(eins_cd3), length(eins_cd4)))

# ============================================================
# STEP 3: Fetch financial histories from ProPublica API
# ============================================================
cat("\n=== Step 3: Fetching ProPublica financial data ===\n")

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a[1])) b else a

fetch_propublica <- function(ein) {
  url <- sprintf("https://projects.propublica.org/nonprofits/api/v2/organizations/%s.json", ein)
  resp <- tryCatch(
    GET(url, timeout(30), add_headers(`User-Agent` = "APEP-Research/1.0")),
    error = function(e) NULL
  )

  if (is.null(resp) || status_code(resp) != 200) return(NULL)

  parsed <- tryCatch(content(resp, "parsed"), error = function(e) NULL)
  if (is.null(parsed)) return(NULL)

  org <- parsed$organization
  filings <- parsed$filings_with_data
  if (is.null(filings) || length(filings) == 0) return(NULL)

  rows <- lapply(filings, function(f) {
    data.table(
      ein = ein,
      org_name = org$name %||% NA_character_,
      ntee_code = org$ntee_code %||% NA_character_,
      state = org$state %||% NA_character_,
      tax_year = as.integer(f$tax_prd_yr %||% NA),
      gross_receipts = as.numeric(f$totrevenue %||% NA),
      total_expenses = as.numeric(f$totfuncexpns %||% NA),
      total_assets = as.numeric(f$totassetsend %||% NA),
      form_type = as.integer(f$formtype %||% NA)
    )
  })

  rbindlist(rows, fill = TRUE)
}

revenue_cache <- file.path(data_dir, "propublica_revenue.rds")

if (file.exists(revenue_cache)) {
  cat("  Loading cached ProPublica data\n")
  revenue_data <- readRDS(revenue_cache)
} else {
  revenue_list <- list()
  total <- length(sample_eins)
  fetched <- 0
  empty <- 0

  for (i in seq_along(sample_eins)) {
    ein <- sample_eins[i]
    result <- fetch_propublica(ein)

    if (!is.null(result) && nrow(result) > 0) {
      revenue_list[[ein]] <- result
      fetched <- fetched + 1
    } else {
      empty <- empty + 1
    }

    if (i %% 500 == 0) {
      cat(sprintf("  Progress: %d/%d (fetched: %d, empty: %d)\n", i, total, fetched, empty))
    }

    Sys.sleep(0.12)  # ~8 req/sec, respectful rate
  }

  revenue_data <- rbindlist(revenue_list, fill = TRUE)
  saveRDS(revenue_data, revenue_cache)
  cat(sprintf("  Saved %s rows from %d organizations\n",
      format(nrow(revenue_data), big.mark = ","), fetched))
}

# ============================================================
# STEP 4: Validate data quality
# ============================================================
cat("\n=== Step 4: Data Validation ===\n")

stopifnot("No revenue data fetched — cannot proceed" = nrow(revenue_data) > 0)
stopifnot("Need at least 500 unique EINs" = length(unique(revenue_data$ein)) >= 500)

cat(sprintf("Total rows: %s\n", format(nrow(revenue_data), big.mark = ",")))
cat(sprintf("Unique EINs: %s\n", format(length(unique(revenue_data$ein)), big.mark = ",")))
cat(sprintf("Year range: %d-%d\n",
    min(revenue_data$tax_year, na.rm = TRUE),
    max(revenue_data$tax_year, na.rm = TRUE)))

# Revenue distribution by year
cat("\nRevenue summary by year:\n")
rev_by_year <- revenue_data[!is.na(gross_receipts) & !is.na(tax_year),
  .(n = .N,
    p25 = quantile(gross_receipts, 0.25, na.rm = TRUE),
    median = median(gross_receipts, na.rm = TRUE),
    p75 = quantile(gross_receipts, 0.75, na.rm = TRUE)),
  by = tax_year][order(tax_year)]
print(rev_by_year)

# Save for later scripts
fwrite(revenue_data, file.path(data_dir, "revenue_panel.csv"))
cat("\n01_fetch_data.R complete.\n")
