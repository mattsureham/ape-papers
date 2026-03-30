## ── 01_fetch_data.R ───────────────────────────────────────────────────────
## Fetch QWI race panel from Azure for RTW treated + comparison states
## ───────────────────────────────────────────────────────────────────────────

source("00_packages.R")

# Force-read connection string from .env (shell may truncate at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

## ── Define states ────────────────────────────────────────────────────────
# Treated RTW states (adoption year)
treated_states <- c(
  "18" = 2012,  # Indiana (Feb 2012)
  "26" = 2013,  # Michigan (effective Mar 2013)
  "55" = 2015,  # Wisconsin (Mar 2015)
  "54" = 2016   # West Virginia (Jul 2016)
)

# Comparison: never-RTW neighbors
comparison_states <- c("17", "39", "27", "42", "36")
# IL=17, OH=39, MN=27, PA=42, NY=36

all_state_fips <- c(names(treated_states), comparison_states)

## ── Fetch QWI race data ─────────────────────────────────────────────────
cat("Fetching QWI race panel from Azure...\n")

# Build state file paths for DuckDB
state_abbrevs <- c("in", "mi", "wi", "wv", "il", "oh", "mn", "pa", "ny")

queries <- list()
for (st in state_abbrevs) {
  queries[[st]] <- sprintf(
    "SELECT * FROM 'az://derived/qwi/rh/ns/%s.parquet'
     WHERE geo_level = 'C'
       AND race IN ('A1', 'A2')
       AND ethnicity = 'A0'
       AND industry = '00'
       AND firmage = 0 AND firmsize = 0
       AND sex = 0 AND agegrp = 'A00' AND education = 'E0'",
    st
  )
}

# Execute queries and combine
dfs <- list()
for (st in names(queries)) {
  cat(sprintf("  Fetching %s...\n", toupper(st)))
  dfs[[st]] <- dbGetQuery(con, queries[[st]])
  cat(sprintf("    -> %d rows\n", nrow(dfs[[st]])))
}

df_all <- bind_rows(dfs)
cat(sprintf("\nTotal rows: %d\n", nrow(df_all)))

## ── Also fetch manufacturing (NAICS 31-33) for mechanism ────────────────
cat("\nFetching manufacturing sector (NAICS 31-33)...\n")

mfg_queries <- list()
for (st in state_abbrevs) {
  mfg_queries[[st]] <- sprintf(
    "SELECT * FROM 'az://derived/qwi/rh/ns/%s.parquet'
     WHERE geo_level = 'C'
       AND race IN ('A1', 'A2')
       AND ethnicity = 'A0'
       AND industry = '31-33'
       AND firmage = 0 AND firmsize = 0
       AND sex = 0 AND agegrp = 'A00' AND education = 'E0'",
    st
  )
}

mfg_dfs <- list()
for (st in names(mfg_queries)) {
  cat(sprintf("  Fetching %s manufacturing...\n", toupper(st)))
  mfg_dfs[[st]] <- dbGetQuery(con, mfg_queries[[st]])
}

df_mfg <- bind_rows(mfg_dfs)
cat(sprintf("Manufacturing rows: %d\n", nrow(df_mfg)))

## ── Validate data ────────────────────────────────────────────────────────
stopifnot("No data returned" = nrow(df_all) > 0)
stopifnot("Missing earnings" = sum(!is.na(df_all$EarnS)) > 0)
stopifnot("Missing employment" = sum(!is.na(df_all$Emp)) > 0)

cat("\n=== Data validation ===\n")
cat(sprintf("States:  %d\n", length(unique(substr(df_all$geography, 1, 2)))))
cat(sprintf("Counties: %d\n", length(unique(df_all$geography))))
cat(sprintf("Years:   %d-%d\n", min(df_all$year), max(df_all$year)))
cat(sprintf("Races:   %s\n", paste(unique(df_all$race), collapse = ", ")))

## ── Save to data/ ────────────────────────────────────────────────────────
saveRDS(df_all, "../data/qwi_race_all_industries.rds")
saveRDS(df_mfg, "../data/qwi_race_manufacturing.rds")

dbDisconnect(con, shutdown = TRUE)
cat("\nData saved to data/\n")
