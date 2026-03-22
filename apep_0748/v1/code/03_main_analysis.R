## 03_main_analysis.R — Main DiD analysis
## apep_0748: GP Practice Closures and A&E Utilization

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Trusts:", length(unique(panel$provider_code)), "\n")
cat("Months:", length(unique(panel$period)), "\n")
cat("Ever-treated:", sum(panel$cohort > 0 & !duplicated(panel$provider_code)), "\n")
cat("Never-treated:", sum(panel$cohort == 0 & !duplicated(panel$provider_code)), "\n")

## Drop rows with missing outcome
panel_clean <- panel %>%
  filter(!is.na(type1_attendances), type1_attendances > 0) %>%
  mutate(
    log_type1 = log(type1_attendances),
    ## Numeric trust ID for fixest
    trust_id = as.numeric(factor(provider_code)),
    ## Time period as numeric
    year_month = as.numeric(format(period, "%Y")) + (as.numeric(format(period, "%m")) - 1) / 12,
    ## Calendar month for seasonality
    cal_month = factor(format(period, "%m")),
    ## COVID indicator
    covid = as.integer(period >= as.Date("2020-03-01") & period <= as.Date("2021-06-30"))
  )

cat("\nClean panel:", nrow(panel_clean), "observations\n")

## ============================================================
## 1. TWFE Baseline
## ============================================================
cat("\n=== 1. TWFE Regression ===\n")

## Model 1: Basic TWFE
m1 <- feols(log_type1 ~ treated | provider_code + period,
            data = panel_clean, cluster = ~provider_code)
cat("Model 1 (TWFE basic):\n")
print(summary(m1))

## Model 2: TWFE with COVID control
m2 <- feols(log_type1 ~ treated + covid | provider_code + period,
            data = panel_clean, cluster = ~provider_code)
cat("\nModel 2 (TWFE + COVID):\n")
print(summary(m2))

## Model 3: TWFE excluding COVID period
panel_nocovid <- panel_clean %>%
  filter(period < as.Date("2020-03-01") | period > as.Date("2021-06-30"))

m3 <- feols(log_type1 ~ treated | provider_code + period,
            data = panel_nocovid, cluster = ~provider_code)
cat("\nModel 3 (TWFE excl. COVID):\n")
print(summary(m3))

## Model 4: Treatment intensity (cumulative closures)
m4 <- feols(log_type1 ~ cumulative_closures | provider_code + period,
            data = panel_clean, cluster = ~provider_code)
cat("\nModel 4 (Treatment intensity):\n")
print(summary(m4))

## ============================================================
## 2. Callaway-Sant'Anna Estimator
## ============================================================
cat("\n=== 2. Callaway-Sant'Anna ===\n")

## Prepare data for did package
## C-S needs: numeric panel ID, numeric time, numeric group (first treatment period)
cs_data <- panel_clean %>%
  mutate(
    unit_id = as.numeric(factor(provider_code)),
    time_id = as.numeric(factor(period)),
    group = ifelse(cohort == 0, 0, cohort)
  ) %>%
  ## C-S needs complete cases
  filter(!is.na(log_type1))

## Check group distribution
cat("Treatment cohorts:\n")
print(table(cs_data$group[!duplicated(cs_data$unit_id)]))

## Run C-S with not-yet-treated as control
cs_out <- tryCatch({
  att_gt(
    yname = "log_type1",
    tname = "time_id",
    idname = "unit_id",
    gname = "group",
    data = cs_data,
    control_group = "notyettreated",
    est_method = "dr",
    base_period = "varying"
  )
}, error = function(e) {
  cat("C-S error:", conditionMessage(e), "\n")
  ## Try simpler specification
  tryCatch({
    att_gt(
      yname = "log_type1",
      tname = "time_id",
      idname = "unit_id",
      gname = "group",
      data = cs_data,
      control_group = "notyettreated",
      est_method = "reg",
      base_period = "varying"
    )
  }, error = function(e2) {
    cat("C-S simpler spec also failed:", conditionMessage(e2), "\n")
    NULL
  })
})

if (!is.null(cs_out)) {
  cat("\nC-S Group-Time ATTs:\n")
  print(summary(cs_out))

  ## Aggregate to simple ATT
  cs_simple <- aggte(cs_out, type = "simple")
  cat("\nSimple ATT:\n")
  print(summary(cs_simple))

  ## Dynamic (event study) aggregation
  cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 24)
  cat("\nDynamic ATT:\n")
  print(summary(cs_dynamic))

  ## Save C-S results
  saveRDS(cs_out, file.path(data_dir, "cs_results.rds"))
  saveRDS(cs_dynamic, file.path(data_dir, "cs_dynamic.rds"))
}

## ============================================================
## 3. Sun-Abraham Estimator (robustness)
## ============================================================
cat("\n=== 3. Sun-Abraham (fixest::sunab) ===\n")

## Need to create event-time variable
panel_clean <- panel_clean %>%
  mutate(
    first_treat_date = if_else(cohort > 0,
                                as.Date(paste0(substr(as.character(cohort), 1, 4), "-",
                                              substr(as.character(cohort), 5, 6), "-01")),
                                as.Date(NA)),
    event_time = as.numeric(difftime(period, first_treat_date, units = "days") / 30.44),
    event_time_round = round(event_time)
  )

## Sun-Abraham with fixest
sa_out <- tryCatch({
  feols(log_type1 ~ sunab(cohort, time_period, ref.p = -1) | provider_code + period,
        data = panel_clean %>% filter(cohort > 0 | cohort == 0),
        cluster = ~provider_code)
}, error = function(e) {
  cat("Sun-Abraham error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(sa_out)) {
  cat("\nSun-Abraham results:\n")
  print(summary(sa_out))
  saveRDS(sa_out, file.path(data_dir, "sa_results.rds"))
}

## ============================================================
## 4. Alternative outcome: Total attendances
## ============================================================
cat("\n=== 4. Total Attendances ===\n")

panel_clean <- panel_clean %>%
  mutate(log_total = log(total_attendances))

m_total <- feols(log_total ~ treated | provider_code + period,
                 data = panel_clean %>% filter(!is.na(log_total)),
                 cluster = ~provider_code)
cat("Total attendances TWFE:\n")
print(summary(m_total))

## ============================================================
## 5. Store results for tables
## ============================================================
cat("\n=== Saving results ===\n")

results <- list(
  twfe_basic = m1,
  twfe_covid = m2,
  twfe_nocovid = m3,
  twfe_intensity = m4,
  twfe_total = m_total,
  cs_out = cs_out,
  cs_simple = if (exists("cs_simple")) cs_simple else NULL,
  cs_dynamic = if (exists("cs_dynamic")) cs_dynamic else NULL,
  sa_out = sa_out
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## Update diagnostics
diagnostics <- jsonlite::fromJSON(file.path(data_dir, "diagnostics.json"))
diagnostics$n_treated <- sum(panel_clean$cohort > 0 & !duplicated(panel_clean$provider_code))
diagnostics$n_pre <- length(unique(panel_clean$period[panel_clean$period < as.Date("2019-01-01")]))
diagnostics$n_obs <- nrow(panel_clean)
diagnostics$mean_type1 <- round(mean(panel_clean$type1_attendances, na.rm = TRUE))
diagnostics$sd_type1 <- round(sd(panel_clean$type1_attendances, na.rm = TRUE))
diagnostics$twfe_coef <- coef(m1)["treated"]
diagnostics$twfe_se <- sqrt(vcov(m1)["treated", "treated"])

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("All results saved.\n")
cat("\n=== KEY FINDINGS ===\n")
cat("TWFE (treated):", round(coef(m1)["treated"], 4),
    "(SE:", round(sqrt(vcov(m1)["treated", "treated"]), 4), ")\n")
if (!is.null(cs_out) && exists("cs_simple")) {
  cat("C-S Simple ATT:", round(cs_simple$overall.att, 4),
      "(SE:", round(cs_simple$overall.se, 4), ")\n")
}
