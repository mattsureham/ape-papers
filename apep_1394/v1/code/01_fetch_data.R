## 01_fetch_data.R — Fetch QWI data from Azure and build panel
## apep_1394: PFL × Healthcare Workforce Retention

source("00_packages.R")

cat("=== FETCHING QWI DATA FROM AZURE ===\n")

# -----------------------------------------------------------------------
# 1. Connect to Azure via DuckDB directly
# -----------------------------------------------------------------------

library(duckdb)
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")

# Load connection string from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
conn_str <- ""
for (l in env_lines) {
  l <- trimws(l)
  if (startsWith(l, "AZURE_STORAGE_CONNECTION_STRING=")) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", l)
    conn_str <- gsub("^[\"']|[\"']$", "", conn_str)
    break
  }
}
stopifnot("Azure connection string not found" = nchar(conn_str) > 0)

DBI::dbExecute(con, paste0("CREATE SECRET apep (TYPE azure, CONNECTION_STRING '", conn_str, "');"))
cat("Connected to Azure\n")

QWI_PATH <- "az://derived/qwi/sa/ns/*.parquet"

# Healthcare (NAICS 62) — primary analysis
qwi_health <- DBI::dbGetQuery(con, paste0(
  "SELECT * FROM '", QWI_PATH, "' ",
  "WHERE industry = '62' AND geo_level = 'S' AND sex IN (1, 2) AND agegrp = 'A00' AND year BETWEEN 2001 AND 2024"
))
cat("Healthcare QWI rows:", nrow(qwi_health), "\n")
stopifnot("No healthcare data" = nrow(qwi_health) > 100)

# Finance (NAICS 52) — falsification industry
qwi_finance <- DBI::dbGetQuery(con, paste0(
  "SELECT * FROM '", QWI_PATH, "' ",
  "WHERE industry = '52' AND geo_level = 'S' AND sex IN (1, 2) AND agegrp = 'A00' AND year BETWEEN 2001 AND 2024"
))
cat("Finance QWI rows:", nrow(qwi_finance), "\n")

# Nursing/residential care (NAICS 623) — subsector robustness
qwi_nursing <- DBI::dbGetQuery(con, paste0(
  "SELECT * FROM '", QWI_PATH, "' ",
  "WHERE industry = '623' AND geo_level = 'S' AND sex IN (1, 2) AND agegrp = 'A00' AND year BETWEEN 2001 AND 2024"
))
cat("Nursing QWI rows:", nrow(qwi_nursing), "\n")

# Age-group data for heterogeneity (healthcare only)
qwi_age <- DBI::dbGetQuery(con, paste0(
  "SELECT * FROM '", QWI_PATH, "' ",
  "WHERE industry = '62' AND geo_level = 'S' AND sex IN (1, 2) ",
  "AND agegrp IN ('A01','A02','A03','A04','A05','A06','A07','A08') AND year BETWEEN 2001 AND 2024"
))
cat("Age-group QWI rows:", nrow(qwi_age), "\n")

DBI::dbDisconnect(con, shutdown = TRUE)

# -----------------------------------------------------------------------
# 2. PFL treatment calendar
# -----------------------------------------------------------------------

pfl_states <- tribble(
  ~state_fips, ~state_abbr, ~pfl_year, ~pfl_quarter,
  6,   "CA", 2004, 3,
  34,  "NJ", 2009, 3,
  44,  "RI", 2014, 1,
  36,  "NY", 2018, 1,
  53,  "WA", 2020, 1,
  11,  "DC", 2020, 3,
  25,  "MA", 2021, 1,
  9,   "CT", 2022, 1,
  41,  "OR", 2023, 3,
  8,   "CO", 2024, 1
)

pfl_states <- pfl_states |>
  mutate(
    pfl_date = as.Date(paste0(pfl_year, "-", sprintf("%02d", (pfl_quarter - 1) * 3 + 1), "-01")),
    pfl_yq = pfl_year + (pfl_quarter - 1) / 4
  )

# -----------------------------------------------------------------------
# 3. Build panel
# -----------------------------------------------------------------------

build_panel <- function(qwi_df, industry_label) {
  panel <- qwi_df |>
    as_tibble() |>
    mutate(
      state_fips = as.integer(geography),
      female = as.integer(sex == 2),
      yq = year + (quarter - 1) / 4,
      date_q = as.Date(paste0(year, "-", sprintf("%02d", (quarter - 1) * 3 + 1), "-01")),
      time_id = (year - 2001) * 4 + quarter
    ) |>
    left_join(pfl_states |> select(state_fips, pfl_year, pfl_quarter, pfl_yq, pfl_date, state_abbr),
              by = "state_fips") |>
    mutate(
      pfl_state = !is.na(pfl_year),
      post_pfl = ifelse(pfl_state, as.integer(yq >= pfl_yq), 0L),
      treated_ddd = post_pfl * female,
      cohort_year = ifelse(pfl_state, pfl_year, 0L)
    )

  cat(industry_label, "panel:", nrow(panel), "rows,",
      n_distinct(panel$state_fips), "states,",
      sum(panel$pfl_state) / 2, "treated state-sex obs\n")
  panel
}

panel <- build_panel(qwi_health, "Healthcare")
panel_finance <- build_panel(qwi_finance, "Finance")
if (nrow(qwi_nursing) > 0) {
  panel_nursing <- build_panel(qwi_nursing, "Nursing")
} else {
  cat("Nursing (NAICS 623) not available at state level — using healthcare (62) only\n")
  panel_nursing <- panel  # fallback
}

# -----------------------------------------------------------------------
# 4. Save
# -----------------------------------------------------------------------

saveRDS(panel, "../data/panel.rds")
saveRDS(panel_finance, "../data/panel_finance.rds")
saveRDS(panel_nursing, "../data/panel_nursing.rds")
saveRDS(qwi_age, "../data/qwi_age.rds")
saveRDS(pfl_states, "../data/pfl_states.rds")
write_csv(panel, "../data/panel.csv")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Panel dimensions:", nrow(panel), "x", ncol(panel), "\n")
cat("PFL states:", paste(pfl_states$state_abbr, collapse = ", "), "\n")
cat("Quarters:", n_distinct(panel$time_id), "\n")
