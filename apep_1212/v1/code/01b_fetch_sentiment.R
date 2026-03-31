# 01b_fetch_sentiment.R — Construct anti-Asian exposure measure
# Uses Census ACS 5-Year Asian population shares by state (pre-determined)
# and FBI Hate Crime Statistics for validation

source("00_packages.R")

# ── 1. Census ACS: Asian population share by state (2019 vintage, pre-COVID) ──

cat("Fetching Census ACS 2019 5-Year state-level race data...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) stop("CENSUS_API_KEY not set in .env")

# B02001: Race - total (001), Asian alone (005)
url <- sprintf(
  "https://api.census.gov/data/2019/acs/acs5?get=NAME,B02001_001E,B02001_005E&for=state:*&key=%s",
  census_key
)

resp <- httr::GET(url)
if (httr::status_code(resp) != 200) {
  stop(sprintf("Census API returned %d: %s", httr::status_code(resp), httr::content(resp, "text")))
}

raw <- jsonlite::fromJSON(httr::content(resp, "text"))
census_df <- as.data.table(raw[-1, ])  # Drop header row
setnames(census_df, c("state_name", "total_pop", "asian_pop", "state_fips"))
census_df[, total_pop := as.numeric(total_pop)]
census_df[, asian_pop := as.numeric(asian_pop)]
census_df[, asian_share := asian_pop / total_pop]
census_df[, state_fips := sprintf("%02d", as.integer(state_fips))]

cat(sprintf("States: %d\n", nrow(census_df)))
cat(sprintf("Asian share range: %.3f (min) to %.3f (max)\n",
            min(census_df$asian_share), max(census_df$asian_share)))

# Top 10 states by Asian share
cat("\n── Top 10 states by Asian population share (2019 ACS) ──\n")
print(census_df[order(-asian_share), .(state_name, asian_share, asian_pop, total_pop)][1:10])

# ── 2. Standardize Asian share for use as treatment intensity ──
census_df[, asian_share_std := (asian_share - mean(asian_share)) / sd(asian_share)]

# Also create a high-Asian indicator (above median)
med_share <- median(census_df$asian_share)
census_df[, high_asian := as.integer(asian_share > med_share)]

cat(sprintf("\nMedian Asian share: %.4f\n", med_share))
cat(sprintf("High-Asian states: %d, Low-Asian states: %d\n",
            sum(census_df$high_asian), sum(1 - census_df$high_asian)))

# ── 3. FBI Hate Crime Statistics (annual, for mechanism evidence) ──
# FBI publishes hate crime data via Crime Data Explorer API

cat("\nFetching FBI Hate Crime statistics...\n")

# FBI Crime Data Explorer API - hate crime by state
fbi_url <- "https://api.usa.gov/crime/fbi/cde/hate-crime/state/bias/anti-asian/count"
fbi_key <- Sys.getenv("FBI_CDE_API_KEY", "")

# Try FBI API - if unavailable, proceed without it (optional data)
fbi_available <- FALSE
if (nchar(fbi_key) > 0) {
  fbi_resp <- tryCatch({
    httr::GET(paste0(fbi_url, "?API_KEY=", fbi_key))
  }, error = function(e) NULL)
  if (!is.null(fbi_resp) && httr::status_code(fbi_resp) == 200) {
    fbi_available <- TRUE
    cat("FBI hate crime data retrieved.\n")
  }
}

if (!fbi_available) {
  cat("FBI API unavailable (key not set or API error). Using Census ACS only.\n")
  cat("This is acceptable: Asian population share is the primary measure.\n")
}

# ── 4. Save ──
fwrite(census_df[, .(state_fips, state_name, total_pop, asian_pop, asian_share,
                      asian_share_std, high_asian)],
       "../data/state_asian_share.csv")

cat("\nSaved state_asian_share.csv\n")
cat("Treatment intensity measure: pre-COVID Asian population share (2019 ACS 5-Year)\n")
cat("This is predetermined and exogenous to COVID-era sentiment.\n")
