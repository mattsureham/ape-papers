## 04_robustness.R — Robustness checks and placebos
## apep_0641: Salary History Bans and Industry Pay Compression

source("00_packages.R")

cat("=== Running robustness checks ===\n")

# ---- Load data ----
qwi <- arrow::read_parquet("../data/analysis_panel.parquet")
gap <- arrow::read_parquet("../data/gender_gap_panel.parquet")
qwi_rh <- arrow::read_parquet("../data/qwi_race_panel.parquet")
ban_states <- read_csv("../data/ban_states.csv", show_col_types = FALSE)

# ---- 1. Event study for gender gap (CS-DiD) ----
cat("\n--- 1. Event study for gender gap ---\n")

# Create state-industry-quarter gender gap panel
gap_panel <- gap %>%
  filter(!is.na(log_ratio_hir), is.finite(log_ratio_hir)) %>%
  mutate(
    state_ind_id = as.integer(factor(paste(state_fips, industry)))
  )

# CS-DiD on log female/male earnings ratio
cs_gap <- att_gt(
  yname = "log_ratio_hir",
  tname = "yq",
  idname = "state_ind_id",
  gname = "treat_quarter",
  data = as.data.frame(gap_panel),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

es_gap <- aggte(cs_gap, type = "dynamic", min_e = -8, max_e = 12)
cat("Event study (gender gap):\n")
summary(es_gap)

# ---- 2. Placebo: Male 45-54 workers ----
cat("\n--- 2. Placebo: Male 45-54 earnings ---\n")

# Re-load the full QWI data with age groups
dotenv <- readLines("../../../../.env", warn = FALSE)
az_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", dotenv, value = TRUE)
az_conn <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", az_line[1])

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("SET azure_storage_connection_string = '%s';", az_conn))

placebo_data <- dbGetQuery(con, "
  SELECT
    SUBSTRING(CAST(geography AS VARCHAR), 1, 2) AS state_fips,
    CAST(sex AS VARCHAR) AS sex,
    CAST(agegrp AS VARCHAR) AS agegrp,
    CAST(industry AS VARCHAR) AS industry,
    year, quarter,
    \"EarnHirNS\" AS earn_hir,
    \"HirN\" AS hir_n,
    \"Emp\" AS emp
  FROM read_parquet('az://derived/qwi/sa/ns/*.parquet')
  WHERE year >= 2013 AND year <= 2025
    AND CAST(agegrp AS VARCHAR) = 'A05'
    AND CAST(sex AS VARCHAR) = '1'
    AND CAST(industry AS VARCHAR) = '00'
")

dbDisconnect(con, shutdown = TRUE)

placebo_panel <- placebo_data %>%
  filter(!is.na(earn_hir), earn_hir > 0) %>%
  mutate(
    yq = year * 4L + quarter,
    log_earn_hir = log(earn_hir)
  ) %>%
  left_join(ban_states %>% select(state_fips, treat_quarter), by = "state_fips") %>%
  mutate(
    treat_quarter = ifelse(is.na(treat_quarter), 0L, treat_quarter),
    state_id = as.integer(factor(state_fips))
  )

cs_placebo <- att_gt(
  yname = "log_earn_hir",
  tname = "yq",
  idname = "state_id",
  gname = "treat_quarter",
  data = as.data.frame(placebo_panel),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

es_placebo <- aggte(cs_placebo, type = "dynamic", min_e = -8, max_e = 12)
att_placebo <- aggte(cs_placebo, type = "simple")
cat("Placebo (Male 45-54) ATT:", att_placebo$overall.att, "\n")
cat("Placebo SE:", att_placebo$overall.se, "\n")

# ---- 3. Exclude COVID quarters (2020Q1–2021Q2) ----
cat("\n--- 3. Exclude COVID quarters ---\n")

gap_nocovid <- gap %>%
  filter(!(year == 2020 | (year == 2021 & quarter <= 2))) %>%
  mutate(state_ind_id = as.integer(factor(paste(state_fips, industry))))

cs_nocovid <- att_gt(
  yname = "log_ratio_hir",
  tname = "yq",
  idname = "state_ind_id",
  gname = "treat_quarter",
  data = as.data.frame(gap_nocovid),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

att_nocovid <- aggte(cs_nocovid, type = "simple")
cat("Gender gap ATT (excl COVID):", att_nocovid$overall.att, "\n")

# ---- 4. Race heterogeneity (Doleac-Hansen test) ----
cat("\n--- 4. Race heterogeneity ---\n")

race_panel <- qwi_rh %>%
  filter(!is.na(earn_hir), earn_hir > 0, industry == "00") %>%
  mutate(
    yq = year * 4L + quarter,
    log_earn_hir = log(earn_hir),
    black = as.integer(race == "A2"),
    white = as.integer(race == "A1")
  ) %>%
  left_join(ban_states %>% select(state_fips, treat_quarter), by = "state_fips") %>%
  mutate(
    treat_quarter = ifelse(is.na(treat_quarter), 0L, treat_quarter),
    post = as.integer(yq >= treat_quarter & treat_quarter > 0)
  )

# Black workers
race_black <- race_panel %>%
  filter(black == 1) %>%
  mutate(state_id = as.integer(factor(state_fips)))

# CS-DiD for Black new-hire earnings
if (n_distinct(race_black$state_fips) >= 5) {
  cs_black <- tryCatch({
    att_gt(
      yname = "log_earn_hir",
      tname = "yq",
      idname = "state_id",
      gname = "treat_quarter",
      data = as.data.frame(race_black),
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal"
    )
  }, error = function(e) {
    cat("CS-DiD for Black workers failed:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_black)) {
    att_black <- aggte(cs_black, type = "simple")
    cat("Black new-hire earnings ATT:", att_black$overall.att, "\n")
    cat("Black SE:", att_black$overall.se, "\n")
  }
}

# White workers
race_white <- race_panel %>%
  filter(white == 1) %>%
  mutate(state_id = as.integer(factor(state_fips)))

if (n_distinct(race_white$state_fips) >= 5) {
  cs_white <- tryCatch({
    att_gt(
      yname = "log_earn_hir",
      tname = "yq",
      idname = "state_id",
      gname = "treat_quarter",
      data = as.data.frame(race_white),
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal"
    )
  }, error = function(e) {
    cat("CS-DiD for White workers failed:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_white)) {
    att_white <- aggte(cs_white, type = "simple")
    cat("White new-hire earnings ATT:", att_white$overall.att, "\n")
    cat("White SE:", att_white$overall.se, "\n")
  }
}

# ---- 5. Sun & Abraham estimator ----
cat("\n--- 5. Sun & Abraham estimator ---\n")

# Use fixest::sunab for state-level female earnings
fem_panel <- qwi %>%
  filter(female == 1, industry != "00") %>%
  group_by(state_fips, year, quarter, yq, treat_quarter) %>%
  summarise(
    earn_hir = weighted.mean(earn_hir, hir_n, na.rm = TRUE),
    emp = sum(emp, na.rm = TRUE),
    hir_n = sum(hir_n, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(log_earn_hir = log(earn_hir)) %>%
  filter(is.finite(log_earn_hir), treat_quarter >= 0)

# sunab requires cohort = 0 for never-treated encoded as Inf or large number
fem_sa <- fem_panel %>%
  mutate(cohort = ifelse(treat_quarter == 0, 10000L, treat_quarter))

sa_result <- feols(
  log_earn_hir ~ sunab(cohort, yq) | state_fips + yq,
  data = fem_sa,
  cluster = ~state_fips
)

cat("Sun & Abraham (Female Earnings):\n")
summary(sa_result)

# ---- Save robustness results ----
robust_results <- list(
  cs_gap = cs_gap,
  es_gap = es_gap,
  es_placebo = es_placebo,
  att_placebo = att_placebo,
  att_nocovid = att_nocovid,
  cs_black = if (exists("cs_black")) cs_black else NULL,
  cs_white = if (exists("cs_white")) cs_white else NULL,
  att_black = if (exists("att_black")) att_black else NULL,
  att_white = if (exists("att_white")) att_white else NULL,
  sa_result = sa_result
)

saveRDS(robust_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
