# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure and construct analysis panel
# =============================================================================

source("00_packages.R")

# --- Manual Azure connection (azure_data.R has a parsing issue with semicolons) ---
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING", line)) {
    val <- sub("^[^=]+=", "", line)
    val <- gsub("^[\"']|[\"']$", "", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
  }
}

conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
stopifnot("Azure connection string not found" = nchar(conn_str) > 50)

con <- dbConnect(duckdb::duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET apep_az (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure via DuckDB\n")

# --- E-Verify treatment dates (state FIPS -> first mandate quarter) ---
everify_states <- tribble(
  ~state_fips, ~state_abbr, ~mandate_year, ~mandate_quarter,
  4,  "AZ", 2008, "2008-01-01",  # Arizona: Legal Arizona Workers Act
  28, "MS", 2008, "2008-07-01",  # Mississippi: Employment Protection Act
  45, "SC", 2009, "2009-01-01",  # South Carolina: Illegal Immigration Reform Act
  1,  "AL", 2012, "2012-04-01",  # Alabama: Beason-Hammon Act
  13, "GA", 2012, "2012-01-01",  # Georgia: Illegal Immigration Reform Act
  22, "LA", 2012, "2012-08-01",  # Louisiana: Act No. 376
  47, "TN", 2012, "2012-01-01",  # Tennessee: Lawful Employment Act
  37, "NC", 2013, "2013-10-01"   # North Carolina: permanent E-Verify
) |>
  mutate(mandate_date = as.Date(mandate_quarter))

cat("E-Verify mandate states:\n")
print(everify_states)

# --- Fetch QWI: race/ethnicity x 3-digit NAICS ---
cat("\nFetching QWI race/ethnicity x 3-digit NAICS from Azure...\n")

qwi_raw <- dbGetQuery(con, "
  SELECT geography, year, quarter, sex, agegrp, race, ethnicity,
         industry, Emp, EmpEnd, EmpS, HirA, HirN, HirR, Sep,
         EarnS, EarnHirNS, FrmJbGn, FrmJbLs, TurnOvrS
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry IN ('236', '237', '238', '541', '621')
    AND year BETWEEN 2004 AND 2016
    AND geography >= 1000
    AND ethnicity IN ('A1', 'A2')
    AND race = 'A0'
")

cat("Raw QWI rows fetched:", format(nrow(qwi_raw), big.mark = ","), "\n")
stopifnot("No data fetched from Azure" = nrow(qwi_raw) > 0)

# --- Validate key columns ---
required_cols <- c("geography", "year", "quarter", "ethnicity", "industry",
                   "Emp", "HirN", "Sep", "EmpS", "HirR", "EarnHirNS")
missing_cols <- setdiff(required_cols, names(qwi_raw))
if (length(missing_cols) > 0) {
  stop("Missing columns in QWI data: ", paste(missing_cols, collapse = ", "))
}

# --- Extract state FIPS from county geography code ---
qwi_raw <- qwi_raw |>
  mutate(
    geography = as.integer(geography),
    state_fips = as.integer(geography %/% 1000),
    county_fips = geography,
    quarter_date = as.Date(paste0(year, "-", sprintf("%02d", (quarter - 1) * 3 + 1), "-01")),
    is_construction = industry %in% c("236", "237", "238"),
    is_hispanic = ethnicity == "A2"  # A0=All, A1=Not Hispanic, A2=Hispanic
  )

cat("Unique states:", n_distinct(qwi_raw$state_fips), "\n")
cat("Unique counties:", n_distinct(qwi_raw$county_fips), "\n")
cat("Ethnicity values:", paste(sort(unique(qwi_raw$ethnicity)), collapse = ", "), "\n")

cat("Rows after county-level + ethnicity filter:", format(nrow(qwi_raw), big.mark = ","), "\n")

# --- Merge E-Verify treatment ---
qwi_raw <- qwi_raw |>
  left_join(
    everify_states |> select(state_fips, mandate_date, state_abbr),
    by = "state_fips"
  ) |>
  mutate(
    treated_state = !is.na(mandate_date),
    post_mandate = !is.na(mandate_date) & quarter_date >= mandate_date,
    cohort_year = if_else(treated_state, as.integer(year(mandate_date)), 0L)
  )

# --- Aggregate to county x quarter x sector-group x ethnicity ---
# Sum 3-digit NAICS within construction (236+237+238) and within placebo (541+621)
# race=A0 and sex=0 and agegrp=A00 are already filtered, so just aggregate industries
panel <- qwi_raw |>
  group_by(county_fips, state_fips, year, quarter, quarter_date,
           is_construction, is_hispanic, treated_state,
           post_mandate, cohort_year, mandate_date) |>
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    EmpS = sum(EmpS, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    HirR = sum(HirR, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    EarnHirNS_wtd = sum(EarnHirNS * HirN, na.rm = TRUE),
    HirN_for_earn = sum(if_else(!is.na(EarnHirNS) & HirN > 0, HirN, 0), na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    hire_rate = HirN / pmax(Emp, 1),
    sep_rate = Sep / pmax(Emp, 1),
    recall_rate = HirR / pmax(Emp, 1),
    stability_rate = EmpS / pmax(Emp, 1),
    earn_new_hire = if_else(HirN_for_earn > 0, EarnHirNS_wtd / HirN_for_earn, NA_real_),
    time_index = (year - 2004L) * 4L + as.integer(quarter)
  )

cat("\nPanel rows after aggregation:", format(nrow(panel), big.mark = ","), "\n")

# --- Filter: counties with avg Hispanic construction Emp >= 50 pre-treatment ---
# Aggregate across 3-digit NAICS within construction for this threshold
hisp_constr_pre <- panel |>
  filter(is_hispanic & is_construction & year <= 2007) |>
  group_by(county_fips, state_fips, year, quarter) |>
  summarise(total_constr_emp = sum(Emp, na.rm = TRUE), .groups = "drop") |>
  group_by(county_fips, state_fips) |>
  summarise(avg_hisp_constr_emp = mean(total_constr_emp, na.rm = TRUE), .groups = "drop") |>
  filter(avg_hisp_constr_emp >= 50)

cat("Counties with avg Hispanic construction Emp >= 50 (pre-2008):", nrow(hisp_constr_pre), "\n")

panel <- panel |>
  filter(county_fips %in% hisp_constr_pre$county_fips)

cat("Final panel rows:", format(nrow(panel), big.mark = ","), "\n")
cat("Final unique counties:", n_distinct(panel$county_fips), "\n")

# Treated vs control
treated_counties <- panel |> filter(treated_state) |> pull(county_fips) |> unique()
control_counties <- panel |> filter(!treated_state) |> pull(county_fips) |> unique()
cat("Treated counties:", length(treated_counties), "\n")
cat("Control counties:", length(control_counties), "\n")

# --- Summary statistics ---
cat("\n--- Summary: Hispanic construction workers ---\n")
panel |>
  filter(is_construction & is_hispanic) |>
  group_by(treated_state) |>
  summarise(
    n_counties = n_distinct(county_fips),
    mean_emp = round(mean(Emp, na.rm = TRUE)),
    mean_hire_rate = round(mean(hire_rate, na.rm = TRUE), 3),
    mean_sep_rate = round(mean(sep_rate, na.rm = TRUE), 3),
    mean_stability = round(mean(stability_rate, na.rm = TRUE), 3),
    .groups = "drop"
  ) |>
  print()

cat("\n--- Summary: Non-Hispanic construction workers ---\n")
panel |>
  filter(is_construction & !is_hispanic) |>
  group_by(treated_state) |>
  summarise(
    n_counties = n_distinct(county_fips),
    mean_emp = round(mean(Emp, na.rm = TRUE)),
    mean_hire_rate = round(mean(hire_rate, na.rm = TRUE), 3),
    mean_sep_rate = round(mean(sep_rate, na.rm = TRUE), 3),
    mean_stability = round(mean(stability_rate, na.rm = TRUE), 3),
    .groups = "drop"
  ) |>
  print()

# --- Save ---
saveRDS(panel, "../data/qwi_panel.rds")
saveRDS(everify_states, "../data/everify_states.rds")
saveRDS(hisp_constr_pre, "../data/county_sample.rds")

dbDisconnect(con, shutdown = TRUE)

cat("\nData saved to data/qwi_panel.rds\n")
cat("Done.\n")
