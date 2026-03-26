# 01_fetch_data.R — Fetch QWI data from Azure and construct analysis panel
# apep_0970: UI Duration Cuts and Education Gradient

source("00_packages.R")

# ── Load .env for Azure connection ──────────────────────────────────
env_file <- "../../../../.env"
stopifnot(file.exists(env_file))
lines <- readLines(env_file, warn = FALSE)
az_conn <- NULL
for (line in lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    az_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    az_conn <- gsub('^["\']|["\']$', '', az_conn)
    break
  }
}
stopifnot("Azure connection string not found" = !is.null(az_conn))

# ── Connect via DuckDB ──────────────────────────────────────────────
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string = '%s';", az_conn))
cat("Azure connection configured.\n")

# ── Push aggregation to DuckDB (state × education × quarter) ───────
# 60M raw rows → aggregate in SQL to avoid R memory exhaustion
cat("Fetching and aggregating QWI SE panel in DuckDB...\n")
panel_raw <- dbGetQuery(con, "
  WITH qwi AS (
    SELECT
      CAST(CAST(geography AS INTEGER) / 1000 AS INTEGER) AS statefips,
      year,
      quarter,
      CAST(education AS VARCHAR) AS education,
      Emp,
      EmpEnd,
      EmpS,
      HirA,
      HirN,
      Sep,
      EarnS,
      EarnBeg,
      EarnHirAS,
      EarnHirNS,
      EarnSepS,
      FrmJbGn,
      FrmJbLs,
      TurnOvrS
    FROM read_parquet('az://derived/qwi/se/ns/*.parquet')
    WHERE year BETWEEN 2007 AND 2020
      AND CAST(education AS VARCHAR) IN ('E1', 'E2', 'E3')
      AND CAST(industry AS VARCHAR) != '00'
      AND CAST(geography AS VARCHAR) != ''
      AND geography IS NOT NULL
  )
  SELECT
    statefips,
    education,
    year,
    quarter,
    -- Employment-weighted average earnings
    SUM(EarnS * COALESCE(Emp, 1)) / NULLIF(SUM(CASE WHEN EarnS IS NOT NULL THEN COALESCE(Emp, 1) END), 0) AS earn_s,
    SUM(EarnBeg * COALESCE(Emp, 1)) / NULLIF(SUM(CASE WHEN EarnBeg IS NOT NULL THEN COALESCE(Emp, 1) END), 0) AS earn_beg,
    SUM(EarnHirAS * COALESCE(HirA, 1)) / NULLIF(SUM(CASE WHEN EarnHirAS IS NOT NULL THEN COALESCE(HirA, 1) END), 0) AS earn_hir,
    SUM(EarnSepS * COALESCE(Sep, 1)) / NULLIF(SUM(CASE WHEN EarnSepS IS NOT NULL THEN COALESCE(Sep, 1) END), 0) AS earn_sep,
    -- Counts
    SUM(Emp) AS emp,
    SUM(EmpEnd) AS emp_end,
    SUM(EmpS) AS emp_s,
    SUM(HirA) AS hires,
    SUM(HirN) AS new_hires,
    SUM(Sep) AS separations,
    SUM(FrmJbGn) AS job_creation,
    SUM(FrmJbLs) AS job_destruction,
    SUM(TurnOvrS) AS turnover,
    COUNT(*) AS n_county_cells
  FROM qwi
  GROUP BY statefips, education, year, quarter
  ORDER BY statefips, education, year, quarter
")

cat(sprintf("Aggregated panel rows: %s\n", format(nrow(panel_raw), big.mark = ",")))
stopifnot("Panel is empty — fetch failed" = nrow(panel_raw) > 0)

dbDisconnect(con, shutdown = TRUE)

# ── Define treatment states and timing ──────────────────────────────
treatment_states <- tribble(
  ~statefips, ~state_abbr, ~cut_date,        ~new_max_weeks,
  12L,        "FL",        "2011-07-01",     23,
  45L,        "SC",        "2011-06-01",     20,
  29L,        "MO",        "2011-07-01",     20,
  26L,        "MI",        "2011-08-01",     20,
  13L,        "GA",        "2012-07-01",     20,
  37L,        "NC",        "2013-07-01",     20,
  5L,         "AR",        "2014-01-01",     16
) %>%
  mutate(
    cut_date = as.Date(cut_date),
    cut_year = as.integer(format(cut_date, "%Y")),
    cut_quarter = as.integer(ceiling(as.numeric(format(cut_date, "%m")) / 3)),
    first_treat_t = (cut_year - 2007) * 4 + cut_quarter,
    cut_magnitude = 26L - new_max_weeks
  )

cat("Treatment states:\n")
print(treatment_states %>% select(state_abbr, cut_date, new_max_weeks, cut_magnitude))

# ── Build analysis panel ────────────────────────────────────────────
panel <- panel_raw %>%
  mutate(
    hire_rate = hires / emp,
    sep_rate = separations / emp,
    new_hire_rate = new_hires / emp,
    net_job_creation = (job_creation - job_destruction) / emp,
    ln_earn_s = log(earn_s),
    ln_earn_hir = log(earn_hir),
    time_t = (year - 2007L) * 4L + quarter,
    yq_label = paste0(year, "Q", quarter)
  ) %>%
  left_join(
    treatment_states %>% select(statefips, state_abbr, first_treat_t, new_max_weeks, cut_magnitude),
    by = "statefips"
  ) %>%
  mutate(
    first_treat_t = replace_na(first_treat_t, 0L),
    treated_state = first_treat_t > 0,
    state_abbr = ifelse(is.na(state_abbr), sprintf("S%02d", statefips), state_abbr),
    cut_magnitude = replace_na(cut_magnitude, 0L),
    edu_label = case_when(
      education == "E1" ~ "HS or less",
      education == "E2" ~ "Some college",
      education == "E3" ~ "BA+",
      TRUE ~ education
    )
  )

# ── Summary ─────────────────────────────────────────────────────────
cat("\n=== Panel Summary ===\n")
n_treated <- n_distinct(panel$statefips[panel$treated_state])
n_control <- n_distinct(panel$statefips[!panel$treated_state])
cat(sprintf("States: %d (treated: %d, control: %d)\n",
            n_distinct(panel$statefips), n_treated, n_control))
cat(sprintf("Education groups: %d (%s)\n",
            n_distinct(panel$edu_label),
            paste(sort(unique(panel$edu_label)), collapse = ", ")))
cat(sprintf("Quarters: %d (%s to %s)\n",
            n_distinct(panel$time_t),
            min(panel$yq_label), max(panel$yq_label)))
cat(sprintf("Total panel obs: %s\n", format(nrow(panel), big.mark = ",")))

cat("\nEarnings by education and treatment (2010):\n")
panel %>%
  filter(year == 2010) %>%
  group_by(edu_label, treated_state) %>%
  summarise(
    mean_earn = mean(earn_s, na.rm = TRUE),
    mean_hire_earn = mean(earn_hir, na.rm = TRUE),
    mean_emp = mean(emp / 1e6, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(edu_label, treated_state) %>%
  print(n = 20)

# ── Save ────────────────────────────────────────────────────────────
saveRDS(panel, "../data/qwi_panel.rds")
cat("\nSaved: data/qwi_panel.rds\n")
saveRDS(treatment_states, "../data/treatment_states.rds")
cat("Saved: data/treatment_states.rds\n")
