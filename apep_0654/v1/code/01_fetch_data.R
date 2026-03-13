## 01_fetch_data.R — Fetch QWI data from Azure and define treatment timing
source("00_packages.R")

cat("=== Fetching QWI data from Azure ===\n")

# Azure connection — load from .env if not in environment
az_conn <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
if (!nzchar(az_conn)) {
  env_file <- normalizePath("../../../../.env", mustWork = FALSE)
  if (file.exists(env_file)) {
    lines <- readLines(env_file)
    for (line in lines) {
      if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", line)) {
        az_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
        break
      }
    }
  }
}
stopifnot(nzchar(az_conn))

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string = '%s';", az_conn))

# ------------------------------------------------------------------
# 1. Treatment timing: ULR law adoption dates for 26 states
# ------------------------------------------------------------------
# FIPS codes + effective quarter for ULR laws
# Sources: NCSL universal license recognition tracker, state legislative records
ulr_states <- tribble(
  ~state_fips, ~state_name,       ~treat_year, ~treat_quarter,
  "04",        "Arizona",          2019,  2,  # SB 1627, April 2019
  "30",        "Montana",          2019,  3,  # SB 250, July 2019
  "42",        "Pennsylvania",     2019,  3,  # Act 41, July 2019
  "49",        "Utah",             2020,  2,  # SB 171, May 2020
  "28",        "Mississippi",      2020,  3,  # HB 1263, July 2020
  "16",        "Idaho",            2020,  3,  # HB 439, July 2020
  "19",        "Iowa",             2020,  3,  # HB 2627, July 2020
  "29",        "Missouri",         2020,  3,  # SB 608, Aug 2020
  "56",        "Wyoming",          2020,  3,  # SF 35, July 2020
  "18",        "Indiana",          2021,  3,  # SB 1, July 2021
  "20",        "Kansas",           2021,  3,  # HB 2066, July 2021
  "33",        "New Hampshire",    2021,  3,  # HB 198, Aug 2021
  "54",        "West Virginia",    2021,  2,  # SB 472, June 2021
  "39",        "Ohio",             2022,  2,  # SB 131, April 2022
  "01",        "Alabama",          2022,  3,  # SB 162, Aug 2022
  "22",        "Louisiana",        2022,  3,  # SB 283, Aug 2022
  "13",        "Georgia",          2022,  3,  # SB 84, July 2022
  "21",        "Kentucky",         2022,  3,  # SB 44, July 2022
  "45",        "South Carolina",   2022,  2,  # SB 885, June 2022
  "47",        "Tennessee",        2022,  1,  # SB 1624, Jan 2022
  "05",        "Arkansas",         2023,  3,  # SB 49, July 2023
  "31",        "Nebraska",         2023,  4,  # LB 17, Oct 2023
  "37",        "North Carolina",   2023,  4,  # SB 196, Oct 2023
  "40",        "Oklahoma",         2023,  4,  # SB 294, Nov 2023
  "51",        "Virginia",         2023,  3,  # SB 1437, July 2023
  "38",        "North Dakota",     2023,  3   # SB 2328, July 2023
)

# Compute continuous quarter for treatment
ulr_states <- ulr_states %>%
  mutate(treat_yq = treat_year * 4 + treat_quarter)

cat("ULR treatment states:", nrow(ulr_states), "\n")
cat("Treatment year range:", min(ulr_states$treat_year), "-", max(ulr_states$treat_year), "\n")

# ------------------------------------------------------------------
# 2. Fetch QWI sex-by-education panel (se) from Azure
# ------------------------------------------------------------------
# This gives us education level breakdowns for the DDD
cat("\nFetching QWI se (sex-by-education) panel...\n")

qwi_query <- "
SELECT
  CAST(geography AS VARCHAR) AS geography,
  CAST(industry AS VARCHAR) AS industry,
  CAST(sex AS VARCHAR) AS sex,
  CAST(education AS VARCHAR) AS education,
  year,
  quarter,
  \"Emp\" AS emp,
  \"EarnS\" AS earn_s,
  \"EarnHirNS\" AS earn_hir,
  \"HirN\" AS hir_n,
  \"HirA\" AS hir_a,
  \"Sep\" AS sep,
  \"FrmJbGn\" AS frm_jb_gn,
  \"FrmJbLs\" AS frm_jb_ls,
  \"TurnOvrS\" AS turnover
FROM read_parquet('az://derived/qwi/se/ns/*.parquet')
WHERE year >= 2014
  AND year <= 2025
  AND CAST(industry AS VARCHAR) != '00'
  AND CAST(industry AS VARCHAR) != '99'
  AND LENGTH(CAST(geography AS VARCHAR)) = 5
"

qwi_raw <- dbGetQuery(con, qwi_query)
cat("Raw QWI rows fetched:", nrow(qwi_raw), "\n")
stopifnot(nrow(qwi_raw) > 100000)

# ------------------------------------------------------------------
# 3. Aggregate to state-industry-quarter level
# ------------------------------------------------------------------
cat("\nAggregating to state-industry-quarter level...\n")

qwi_raw <- qwi_raw %>%
  mutate(state_fips = substr(geography, 1, 2))

# Aggregate across counties and demographics (sex, education)
# For earnings: weighted mean by employment/hires
# For flows: sum
state_panel <- qwi_raw %>%
  group_by(state_fips, industry, year, quarter) %>%
  summarise(
    # Compute weighted earnings BEFORE summing weights
    earn_hir = {
      valid <- !is.na(earn_hir) & !is.na(hir_n) & hir_n > 0
      if (sum(valid) == 0) NA_real_
      else weighted.mean(earn_hir[valid], hir_n[valid])
    },
    earn_s = {
      valid <- !is.na(earn_s) & !is.na(emp) & emp > 0
      if (sum(valid) == 0) NA_real_
      else weighted.mean(earn_s[valid], emp[valid])
    },
    emp = sum(emp, na.rm = TRUE),
    hir_n = sum(hir_n, na.rm = TRUE),
    hir_a = sum(hir_a, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    frm_jb_gn = sum(frm_jb_gn, na.rm = TRUE),
    frm_jb_ls = sum(frm_jb_ls, na.rm = TRUE),
    turnover = sum(turnover, na.rm = TRUE),
    .groups = "drop"
  )

cat("State-industry-quarter panel rows:", nrow(state_panel), "\n")

# ------------------------------------------------------------------
# 4. Also create education-split panel for DDD
# ------------------------------------------------------------------
cat("\nCreating education-split panel...\n")

# E1=less than HS, E2=HS, E3=some college, E4=bachelor's+
# Licensed workers are primarily E3 (some college/associate) and E4 (bachelor's+)
# Unlicensed are E1 and E2
edu_panel <- qwi_raw %>%
  mutate(high_ed = ifelse(education %in% c("E3", "E4"), 1L, 0L)) %>%
  group_by(state_fips, industry, year, quarter, high_ed) %>%
  summarise(
    earn_hir = {
      valid <- !is.na(earn_hir) & !is.na(hir_n) & hir_n > 0
      if (sum(valid) == 0) NA_real_
      else weighted.mean(earn_hir[valid], hir_n[valid])
    },
    earn_s = {
      valid <- !is.na(earn_s) & !is.na(emp) & emp > 0
      if (sum(valid) == 0) NA_real_
      else weighted.mean(earn_s[valid], emp[valid])
    },
    emp = sum(emp, na.rm = TRUE),
    hir_n = sum(hir_n, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    frm_jb_gn = sum(frm_jb_gn, na.rm = TRUE),
    frm_jb_ls = sum(frm_jb_ls, na.rm = TRUE),
    .groups = "drop"
  )

cat("Education-split panel rows:", nrow(edu_panel), "\n")

# ------------------------------------------------------------------
# 5. Save
# ------------------------------------------------------------------
dbDisconnect(con, shutdown = TRUE)

write_parquet(state_panel, "../data/state_panel.parquet")
write_parquet(edu_panel, "../data/edu_panel.parquet")
write_csv(ulr_states, "../data/ulr_treatment_timing.csv")

cat("\n=== Data fetch complete ===\n")
cat("State panel:", nrow(state_panel), "rows\n")
cat("Education panel:", nrow(edu_panel), "rows\n")
cat("Treatment states:", nrow(ulr_states), "\n")
