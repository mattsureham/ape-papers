## 01_fetch_data.R — Fetch IPEDS data from local DuckDB + FRED macrodata
source("00_packages.R")

cat("=== Fetching IPEDS + FRED data ===\n")

# ---------------------------------------------------------------
# 1. IPEDS from local DuckDB
# ---------------------------------------------------------------
ipeds_path <- normalizePath("../data/ipeds.duckdb")
stopifnot(file.exists(ipeds_path))
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ipeds_path, read_only = TRUE)

# --- Institutional directory ---
cat("Fetching HD...\n")
hd <- DBI::dbGetQuery(con, "
  SELECT unitid, institution_name, state, fips_state, control,
         sector, level, carnegie_basic, hbcu, locale_code,
         size_category, year
  FROM hd
  WHERE control = 1 AND year BETWEEN 2003 AND 2022
")
cat(sprintf("  HD: %d rows, %d unique institutions\n", nrow(hd), length(unique(hd$unitid))))
stopifnot(nrow(hd) > 10000)

# --- Tuition (from view) ---
cat("Fetching tuition...\n")
tuition <- DBI::dbGetQuery(con, "
  SELECT unitid, year, tuition_in_state, tuition_out_state
  FROM v_tuition_trends
  WHERE year BETWEEN 2003 AND 2022
")
cat(sprintf("  Tuition: %d rows\n", nrow(tuition)))

# --- Finance (state appropriations = f1a08 for GASB public institutions) ---
cat("Fetching finance...\n")
fin <- DBI::dbGetQuery(con, "
  SELECT unitid, year,
         f1a01 AS tuition_fees_rev,
         f1a08 AS state_approp,
         f1a09 AS local_approp,
         f1a06 AS total_op_rev,
         f1a18 AS total_expenses
  FROM f1a
  WHERE year BETWEEN 2003 AND 2022
")
cat(sprintf("  Finance: %d rows\n", nrow(fin)))

# --- FTE enrollment (from efia) ---
cat("Fetching FTE...\n")
fte <- DBI::dbGetQuery(con, "
  SELECT unitid, year, efteug AS fte_ug, eftegd AS fte_grad
  FROM efia
  WHERE year BETWEEN 2003 AND 2022
")
fte$fte_total <- fte$fte_ug + fte$fte_grad
cat(sprintf("  FTE: %d rows\n", nrow(fte)))

# --- SFA: Pell grant data ---
cat("Fetching SFA (Pell)...\n")
sfa <- DBI::dbGetQuery(con, "
  SELECT unitid, year,
         scugrad AS ug_enrolled_sfa,
         fgrnt_n AS fed_grant_n,
         fgrnt_p AS fed_grant_pct,
         fgrnt_a AS fed_grant_avg_amt,
         pgrnt_n AS pell_n,
         pgrnt_p AS pell_pct,
         pgrnt_a AS pell_avg_amt,
         tstdpel AS total_pell_recipients
  FROM sfa
  WHERE year BETWEEN 2003 AND 2022
")
cat(sprintf("  SFA: %d rows\n", nrow(sfa)))

# --- Enrollment by race (ef_a) ---
cat("Fetching enrollment by race...\n")
enroll <- DBI::dbGetQuery(con, "
  SELECT unitid, year, efalevel, lstudy,
         eftotlt AS total, eftotlm AS total_m, eftotlw AS total_w,
         efbkaat AS black, efhispt AS hispanic, efwhitt AS white,
         efasiat AS asian, efaiant AS aian, efnhpit AS nhpi,
         ef2mort AS two_more, efnralt AS nonresident, efunknt AS unknown
  FROM ef_a
  WHERE year BETWEEN 2003 AND 2022
    AND efalevel = 1  -- All students total
    AND lstudy = 999  -- Grand total (all levels of study)
")
cat(sprintf("  Enrollment: %d rows\n", nrow(enroll)))

# If lstudy=999 returned no rows, try without filter
if (nrow(enroll) == 0) {
  cat("  Retrying enrollment without lstudy filter...\n")
  enroll <- DBI::dbGetQuery(con, "
    SELECT unitid, year, efalevel, lstudy,
           eftotlt AS total, eftotlm AS total_m, eftotlw AS total_w,
           efbkaat AS black, efhispt AS hispanic, efwhitt AS white,
           efasiat AS asian, efaiant AS aian, efnhpit AS nhpi,
           ef2mort AS two_more, efnralt AS nonresident, efunknt AS unknown
    FROM ef_a
    WHERE year BETWEEN 2003 AND 2022
      AND efalevel = 1
  ")
  cat(sprintf("  Enrollment (no lstudy filter): %d rows\n", nrow(enroll)))

  # Aggregate to institution-year level (sum across lstudy)
  enroll <- enroll |>
    group_by(unitid, year) |>
    summarise(across(c(total, total_m, total_w, black, hispanic, white,
                       asian, aian, nhpi, two_more, nonresident, unknown),
                     ~sum(.x, na.rm = TRUE)),
              .groups = "drop")
  cat(sprintf("  Enrollment aggregated: %d rows\n", nrow(enroll)))
}

DBI::dbDisconnect(con, shutdown = TRUE)

# ---------------------------------------------------------------
# 2. FRED: National macro + state unemployment
# ---------------------------------------------------------------
cat("\nFetching FRED data...\n")
fred_key <- Sys.getenv("FRED_API_KEY")
stopifnot(nchar(fred_key) > 0)

fetch_fred <- function(series_id) {
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2000-01-01&observation_end=2023-12-31",
    series_id, fred_key
  )
  resp <- httr::GET(url)
  stopifnot(httr::status_code(resp) == 200)
  content <- httr::content(resp, as = "parsed")
  tibble(
    date = as.Date(sapply(content$observations, `[[`, "date")),
    value = as.numeric(sapply(content$observations, `[[`, "value"))
  ) |> filter(!is.na(value))
}

# National GDP growth
gdp <- fetch_fred("A191RL1Q225SBEA") |>
  mutate(year = as.integer(format(date, "%Y"))) |>
  group_by(year) |>
  summarise(gdp_growth = mean(value), .groups = "drop")

# National unemployment
unemp <- fetch_fred("UNRATE") |>
  mutate(year = as.integer(format(date, "%Y"))) |>
  group_by(year) |>
  summarise(unemp_rate = mean(value), .groups = "drop")

macro <- full_join(gdp, unemp, by = "year") |> filter(year >= 2003, year <= 2022)
cat(sprintf("  Macro: %d years\n", nrow(macro)))

# State unemployment rates
cat("Fetching state unemployment...\n")
state_abbrs <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC")

state_unemp_list <- list()
for (st in state_abbrs) {
  tryCatch({
    su <- fetch_fred(paste0(st, "UR"))
    su$state <- st
    state_unemp_list[[st]] <- su
  }, error = function(e) {
    cat(sprintf("  Warning: %s failed\n", st))
  })
  Sys.sleep(0.1)
}

state_unemp <- bind_rows(state_unemp_list) |>
  mutate(year = as.integer(format(date, "%Y"))) |>
  group_by(state, year) |>
  summarise(state_unemp = mean(value), .groups = "drop") |>
  filter(year >= 2003, year <= 2022)
cat(sprintf("  State unemployment: %d state-years (%d states)\n",
            nrow(state_unemp), n_distinct(state_unemp$state)))

# ---------------------------------------------------------------
# 3. Save
# ---------------------------------------------------------------
saveRDS(hd, "../data/ipeds_hd.rds")
saveRDS(tuition, "../data/ipeds_tuition.rds")
saveRDS(fin, "../data/ipeds_finance.rds")
saveRDS(fte, "../data/ipeds_fte.rds")
saveRDS(sfa, "../data/ipeds_sfa.rds")
saveRDS(enroll, "../data/ipeds_enrollment.rds")
saveRDS(macro, "../data/fred_macro.rds")
saveRDS(state_unemp, "../data/state_unemp.rds")

cat("\n=== Data fetch complete ===\n")
