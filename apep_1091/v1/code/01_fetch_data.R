# ==============================================================================
# 01_fetch_data.R — Fetch IPUMS full-count census data from Azure
# Paper: The Picture Bride Premium
# ==============================================================================

source("00_packages.R")

# Force-reload .env (shell may truncate Azure connection string at semicolons)
env_file <- normalizePath("../../../../.env")
lines <- readLines(env_file, warn = FALSE)
for (line in lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\'"]$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# --------------------------------------------------------------------------
# Query 1: Asian men from 1900, 1910, 1920, 1930 full-count censuses
# RACE: 4=Chinese, 5=Japanese; SEX: 1=Male
# Column availability varies: SEI only in 1920+, CLASSWKR not in 1900
# --------------------------------------------------------------------------

# Common columns across all years
base_cols <- "HISTID, YEAR, STATEFIP, AGE, RACE, SEX, MARST,
              OCC1950, OCCSCORE, LIT, BPL, FARM, OWNERSHP"

fetch_census_year <- function(con, year_file, year_label, extra_cols = "") {
  cat(sprintf("Fetching %s census data (Asian men 15-65)...\n", year_label))

  cols <- base_cols
  if (nchar(extra_cols) > 0) cols <- paste0(cols, ", ", extra_cols)

  query <- sprintf("
    SELECT %s
    FROM 'az://raw/ipums_fullcount/%s.parquet'
    WHERE RACE IN (4, 5)
      AND SEX = 1
      AND AGE BETWEEN 15 AND 65
  ", cols, year_file)

  df <- DBI::dbGetQuery(con, query)
  cat(sprintf("  %s: %d rows fetched\n", year_label, nrow(df)))
  return(as.data.table(df))
}

dt_1900 <- fetch_census_year(con, "us1900m", "1900")
dt_1910 <- fetch_census_year(con, "us1910m", "1910", "CLASSWKR")
dt_1920 <- fetch_census_year(con, "us1920c", "1920", "CLASSWKR, SEI")
dt_1930 <- fetch_census_year(con, "us1930d", "1930", "CLASSWKR, SEI")

# Combine (fill=TRUE handles missing columns)
dt_all <- rbindlist(list(dt_1900, dt_1910, dt_1920, dt_1930), fill = TRUE)

cat(sprintf("\nTotal rows: %d\n", nrow(dt_all)))
cat("Counts by year and race:\n")
print(dt_all[, .N, by = .(YEAR, race_label = ifelse(RACE == 4, "Chinese", "Japanese"))])

# --------------------------------------------------------------------------
# Query 2: Asian women for sex ratio calculations
# --------------------------------------------------------------------------

fetch_women <- function(con, year_file, year_label) {
  cat(sprintf("Fetching %s women...\n", year_label))
  query <- sprintf("
    SELECT YEAR, STATEFIP, RACE, SEX, AGE, MARST
    FROM 'az://raw/ipums_fullcount/%s.parquet'
    WHERE RACE IN (4, 5) AND SEX = 2 AND AGE BETWEEN 15 AND 65
  ", year_file)
  df <- DBI::dbGetQuery(con, query)
  cat(sprintf("  %s: %d women\n", year_label, nrow(df)))
  return(as.data.table(df))
}

dt_women_1900 <- fetch_women(con, "us1900m", "1900")
dt_women_1910 <- fetch_women(con, "us1910m", "1910")
dt_women_1920 <- fetch_women(con, "us1920c", "1920")
dt_women_1930 <- fetch_women(con, "us1930d", "1930")

dt_women <- rbindlist(list(dt_women_1900, dt_women_1910, dt_women_1920, dt_women_1930),
                       fill = TRUE)

cat("\nWomen by year and race:\n")
print(dt_women[, .N, by = .(YEAR, race_label = ifelse(RACE == 4, "Chinese", "Japanese"))])

# --------------------------------------------------------------------------
# Query 3: MLP crosswalk — fetch 1920-1930 links for Japanese/Chinese
# --------------------------------------------------------------------------

cat("\nExploring MLP crosswalk structure...\n")
mlp_sample <- DBI::dbGetQuery(con, "
  SELECT * FROM 'az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet' LIMIT 5
")
cat("MLP columns:", paste(names(mlp_sample), collapse = ", "), "\n")
cat("Sample:\n")
print(mlp_sample)

# --------------------------------------------------------------------------
# Save intermediate data
# --------------------------------------------------------------------------

saveRDS(dt_all, "../data/census_asian_men.rds")
saveRDS(dt_women, "../data/census_asian_women.rds")
saveRDS(mlp_sample, "../data/mlp_sample.rds")

cat("\nData saved to ../data/\n")

# Verify data integrity
stopifnot("No rows fetched" = nrow(dt_all) > 0)
stopifnot("Missing YEAR" = !any(is.na(dt_all$YEAR)))
stopifnot("Missing RACE" = !any(is.na(dt_all$RACE)))
stopifnot("Need at least 4 years" = length(unique(dt_all$YEAR)) == 4)

# Summary statistics
cat("\n=== SUMMARY ===\n")
cat("Japanese men by year:\n")
print(dt_all[RACE == 5, .(N = .N, mean_age = round(mean(AGE), 1),
                           married_pct = round(100 * mean(MARST <= 2), 1),
                           mean_occscore = round(mean(OCCSCORE, na.rm = TRUE), 1)),
             by = YEAR][order(YEAR)])
cat("\nChinese men by year:\n")
print(dt_all[RACE == 4, .(N = .N, mean_age = round(mean(AGE), 1),
                           married_pct = round(100 * mean(MARST <= 2), 1),
                           mean_occscore = round(mean(OCCSCORE, na.rm = TRUE), 1)),
             by = YEAR][order(YEAR)])

cat("\nData fetch complete. Integrity checks passed.\n")

apep_azure_disconnect(con)
