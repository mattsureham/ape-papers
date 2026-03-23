## 01_fetch_data.R — Fetch Swiss referendum data and GDELT competing news
## apep_0840: Competing News IV and Swiss Referendum Turnout

source("00_packages.R")

# ============================================================================
# PART 1: Swiss referendum data via swissdd
# ============================================================================

cat("Fetching Swiss national referendum results (2015-2024)...\n")

# Get all national votes from 2015 onward
votes <- get_nationalvotes(from_date = "2015-01-01", to_date = "2024-12-31")

stopifnot("votes data must not be empty" = nrow(votes) > 0)
cat(sprintf("  Retrieved %d municipality-vote observations\n", nrow(votes)))
cat(sprintf("  Unique vote dates: %d\n", length(unique(votes$votedate))))
cat(sprintf("  Unique municipalities: %d\n", length(unique(votes$id))))
cat(sprintf("  Unique ballot items: %d\n", length(unique(votes$name))))

# Key columns: id (municipality BFS number), votedate, name (ballot item),
# jaStimmenInProzent (yes %), stimmbeteiligungInProzent (turnout %)
# canton_id, canton_name

# Save raw referendum data
fwrite(as.data.table(votes), "../data/referendum_raw.csv")
cat("  Saved referendum_raw.csv\n")

# ============================================================================
# PART 2: GDELT data via BigQuery — competing news around vote dates
# ============================================================================

cat("\nFetching GDELT competing news data from BigQuery...\n")

# Get unique vote dates
vote_dates <- sort(unique(as.Date(votes$votedate)))
cat(sprintf("  Processing %d vote dates\n", length(vote_dates)))

# For each vote date, query GDELT for the 14-day window before
# We need: (a) Swiss political articles, (b) foreign disaster articles
# Split by source language (French, German, Italian, English)

# Build date windows for SQL
date_windows <- data.table(
  vote_date = vote_dates,
  window_start = vote_dates - 14,
  window_end = vote_dates - 1
)

# Single BigQuery query covering all vote windows
# GDELT GKG partitioned table: gdelt-bq.gdeltv2.gkg_partitioned
# Key fields: DATE, SourceCommonName, V2Themes, V2Locations, V2Tone

# Construct SQL for all windows at once
window_clauses <- paste0(
  sprintf("(_PARTITIONTIME BETWEEN '%s' AND '%s')",
          format(date_windows$window_start, "%Y-%m-%d"),
          format(date_windows$window_end, "%Y-%m-%d")),
  collapse = " OR "
)

# Query 1: Count articles by date and theme category
# Swiss articles: V2Locations contains Switzerland (FIPS=SZ or country code CH)
# Disaster articles: V2Themes contains NATURAL_DISASTER, TERROR, CRISISLEX
sql_gdelt <- sprintf("
WITH article_flags AS (
  SELECT
    DATE(_PARTITIONTIME) AS article_date,
    -- Language detection from source domain
    CASE
      WHEN REGEXP_CONTAINS(SourceCommonName, r'(?i)(lemonde|lefigaro|liberation|20minutes|rts\\.ch|tdg\\.ch|letemps|24heures|bilan\\.ch)')
        THEN 'fr'
      WHEN REGEXP_CONTAINS(SourceCommonName, r'(?i)(spiegel|faz\\.net|zeit\\.de|nzz\\.ch|tagesanzeiger|blick\\.ch|srf\\.ch|20min\\.ch|watson\\.ch|aargauerzeitung|bernerzeitung|luzernerzeitung|tagblatt\\.ch)')
        THEN 'de'
      WHEN REGEXP_CONTAINS(SourceCommonName, r'(?i)(corriere|repubblica|rsi\\.ch|tio\\.ch|cdt\\.ch)')
        THEN 'it'
      ELSE 'other'
    END AS source_lang,
    -- Swiss content flag
    CASE WHEN REGEXP_CONTAINS(COALESCE(V2Locations, ''), r'SZ|Switzerland|Schweiz|Suisse|Svizzera') THEN 1 ELSE 0 END AS is_swiss,
    -- Disaster/crisis content flag
    CASE WHEN REGEXP_CONTAINS(COALESCE(V2Themes, ''), r'NATURAL_DISASTER|TERROR|CRISISLEX|FAMINE|EPIDEMIC|EARTHQUAKE|FLOOD|HURRICANE|CYCLONE') THEN 1 ELSE 0 END AS is_disaster,
    -- Political/referendum content flag
    CASE WHEN REGEXP_CONTAINS(COALESCE(V2Themes, ''), r'ELECTION|REFERENDUM|VOTE|DEMOCRACY|LEGISLATION|PARLIAMENT|POLITICAL') THEN 1 ELSE 0 END AS is_political
  FROM `gdelt-bq.gdeltv2.gkg_partitioned`
  WHERE (%s)
)
SELECT
  article_date,
  source_lang,
  COUNT(*) AS total_articles,
  SUM(is_swiss) AS swiss_articles,
  SUM(is_disaster) AS disaster_articles,
  SUM(CASE WHEN is_swiss = 1 AND is_political = 1 THEN 1 ELSE 0 END) AS swiss_political_articles,
  SUM(CASE WHEN is_disaster = 1 AND is_swiss = 0 THEN 1 ELSE 0 END) AS foreign_disaster_articles
FROM article_flags
WHERE source_lang IN ('fr', 'de', 'it')
GROUP BY article_date, source_lang
ORDER BY article_date, source_lang
", window_clauses)

cat("  Running BigQuery query (may take 1-2 minutes)...\n")
bq_project <- "scl-librechat"
gdelt_daily <- tryCatch(
  {
    result <- bigrquery::bq_project_query(bq_project, sql_gdelt)
    bigrquery::bq_table_download(result)
  },
  error = function(e) {
    stop(sprintf("GDELT BigQuery query FAILED: %s\nCannot proceed without real GDELT data.", e$message))
  }
)

stopifnot("GDELT data must not be empty" = nrow(gdelt_daily) > 0)
cat(sprintf("  Retrieved %d daily-language observations from GDELT\n", nrow(gdelt_daily)))

fwrite(as.data.table(gdelt_daily), "../data/gdelt_daily.csv")
cat("  Saved gdelt_daily.csv\n")

# ============================================================================
# PART 3: Ballot item metadata from Swissvotes
# ============================================================================

cat("\nFetching ballot item metadata from Swissvotes...\n")

# Swissvotes provides CSV with ballot item details
# Download the full dataset
swissvotes_url <- "https://swissvotes.ch/storage/votes_dataset.csv"
swissvotes_raw <- tryCatch(
  fread(swissvotes_url, encoding = "UTF-8"),
  error = function(e) {
    # Try alternative encoding
    tryCatch(
      fread(swissvotes_url, encoding = "Latin-1"),
      error = function(e2) {
        stop(sprintf("Swissvotes download FAILED: %s\nCannot proceed without ballot metadata.", e2$message))
      }
    )
  }
)

stopifnot("Swissvotes data must not be empty" = nrow(swissvotes_raw) > 0)
cat(sprintf("  Retrieved %d ballot items from Swissvotes\n", nrow(swissvotes_raw)))

fwrite(swissvotes_raw, "../data/swissvotes_raw.csv")
cat("  Saved swissvotes_raw.csv\n")

# ============================================================================
# PART 4: Municipality metadata from BFS
# ============================================================================

cat("\nFetching municipality metadata...\n")

# BFS municipality list with language region, canton, population
# Use the opendata.swiss CKAN API
bfs_url <- "https://dam-api.bfs.admin.ch/hub/api/dam/assets/32007792/master"
bfs_muni <- tryCatch(
  fread(bfs_url, encoding = "UTF-8"),
  error = function(e) {
    cat("  BFS direct download failed, trying alternative...\n")
    # Alternative: construct from swissdd canton info
    muni_meta <- unique(as.data.table(votes)[, .(
      bfs_id = id,
      canton_id = canton_id,
      canton_name = canton_name
    )])
    # Assign language region based on canton
    french_cantons <- c("GE", "VD", "NE", "JU")
    mixed_cantons <- c("FR", "VS", "BE")  # Bilingual
    italian_cantons <- c("TI")
    romansh_cantons <- c("GR")  # Mixed

    muni_meta[, language_region := fifelse(
      canton_id %in% french_cantons, "fr",
      fifelse(canton_id %in% italian_cantons, "it",
              fifelse(canton_id %in% mixed_cantons, "mixed", "de"))
    )]
    muni_meta
  }
)

if ("bfs_id" %in% names(bfs_muni)) {
  fwrite(bfs_muni, "../data/municipality_meta.csv")
  cat(sprintf("  Saved municipality_meta.csv (%d municipalities)\n", nrow(bfs_muni)))
} else {
  # Process BFS file
  fwrite(bfs_muni, "../data/municipality_meta_raw.csv")
  cat(sprintf("  Saved municipality_meta_raw.csv (%d rows)\n", nrow(bfs_muni)))
}

cat("\n=== Data fetch complete ===\n")
cat(sprintf("  Referendum observations: %d\n", nrow(votes)))
cat(sprintf("  GDELT daily-language obs: %d\n", nrow(gdelt_daily)))
cat(sprintf("  Swissvotes ballot items: %d\n", nrow(swissvotes_raw)))
