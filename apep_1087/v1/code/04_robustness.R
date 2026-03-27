## 04_robustness.R — Robustness checks and placebo tests
## apep_1087: Healthcare WVP Mandates and Worker Injuries

source("00_packages.R")

data_dir <- "../data"
hc <- data.table::fread(file.path(data_dir, "panel_healthcare.csv"))
panel <- data.table::fread(file.path(data_dir, "panel_full.csv"))

## Drop territories
hc <- hc[!is.na(state_fips)]

## Fix treatment timing (match main analysis)
hc[state_abbr == "CT", wvp_year := 0]
hc[state_abbr == "TX", wvp_year := 0]
hc[, wvp_year := as.numeric(wvp_year)]
hc[, post := as.integer(year >= wvp_year & wvp_year > 0)]

## Balance panel
state_counts <- hc[, .N, by = state_fips]
max_years <- max(state_counts$N)
hc <- hc[state_fips %in% state_counts[N == max_years]$state_fips]

## ============================================================
## 1. Placebo: Non-healthcare establishments
## ============================================================

cat("--- Placebo: Non-healthcare sector ---\n")
nonhc <- panel[sector == "non_healthcare"]
nonhc <- nonhc[!is.na(state_fips)]
nonhc[state_abbr == "CT", wvp_year := 0]
nonhc[state_abbr == "TX", wvp_year := 0]
nonhc[, wvp_year := as.numeric(wvp_year)]
nonhc[, post := as.integer(year >= wvp_year & wvp_year > 0)]

## Balance
nonhc_counts <- nonhc[, .N, by = state_fips]
nonhc <- nonhc[state_fips %in% nonhc_counts[N == max(nonhc_counts$N)]$state_fips]

## CS DiD on non-healthcare (should show NO effect)
cs_placebo <- did::att_gt(
  yname = "dafw_rate",
  tname = "year",
  idname = "state_fips",
  gname = "wvp_year",
  data = as.data.frame(nonhc),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

agg_placebo <- did::aggte(cs_placebo, type = "simple")
cat("Placebo ATT (non-healthcare DAFW rate):\n")
print(summary(agg_placebo))

## ============================================================
## 2. Leave-one-state-out sensitivity
## ============================================================

cat("\n--- Leave-one-state-out ---\n")

treated_states <- unique(hc[wvp_year > 0]$state_fips)
loo_results <- data.frame(
  dropped_state = character(),
  att = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (drop_st in treated_states) {
  hc_loo <- hc[state_fips != drop_st]
  dropped_name <- unique(hc[state_fips == drop_st]$state_abbr)

  cs_loo <- tryCatch({
    out <- did::att_gt(
      yname = "dafw_rate",
      tname = "year",
      idname = "state_fips",
      gname = "wvp_year",
      data = as.data.frame(hc_loo),
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "varying"
    )
    agg <- did::aggte(out, type = "simple")
    data.frame(
      dropped_state = dropped_name,
      att = agg$overall.att,
      se = agg$overall.se
    )
  }, error = function(e) {
    data.frame(dropped_state = dropped_name, att = NA, se = NA)
  })

  loo_results <- rbind(loo_results, cs_loo)
}

cat("\nLeave-one-out ATTs:\n")
print(loo_results)

## ============================================================
## 3. Alternative outcome: log(DAFW + 1) per 100 workers
## ============================================================

cat("\n--- Log specification ---\n")
hc[, log_dafw_rate := log(dafw_rate + 0.01)]

cs_log <- did::att_gt(
  yname = "log_dafw_rate",
  tname = "year",
  idname = "state_fips",
  gname = "wvp_year",
  data = as.data.frame(hc),
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying"
)

agg_log <- did::aggte(cs_log, type = "simple")
cat("Log DAFW rate ATT:\n")
print(summary(agg_log))

## ============================================================
## 4. TWFE with controls (state-level trends)
## ============================================================

cat("\n--- TWFE with state-specific linear trends ---\n")

hc[, time_trend := year - min(year)]

twfe_trend <- fixest::feols(
  dafw_rate ~ post | state_fips + year + state_fips[time_trend],
  data = hc,
  cluster = ~state_fips
)
cat("TWFE with state trends:\n")
print(summary(twfe_trend))

## ============================================================
## 5. Excluding 2023 (data quality concern)
## ============================================================

cat("\n--- Excluding 2023 ---\n")
hc_pre23 <- hc[year <= 2022]
## Drop 2023 cohort (no post-treatment data without 2023)
hc_pre23 <- hc_pre23[wvp_year != 2023 | wvp_year == 0]
hc_pre23[wvp_year == 2023, wvp_year := 0]

cs_no23 <- tryCatch({
  out <- did::att_gt(
    yname = "dafw_rate", tname = "year", idname = "state_fips",
    gname = "wvp_year", data = as.data.frame(hc_pre23),
    control_group = "nevertreated", anticipation = 0, base_period = "varying"
  )
  did::aggte(out, type = "simple")
}, error = function(e) {
  cat("Excluding 2023 failed:", e$message, "\n")
  list(overall.att = NA, overall.se = NA)
})

cat("ATT excluding 2023:", cs_no23$overall.att, "(SE:", cs_no23$overall.se, ")\n")

## ============================================================
## 6. Wild cluster bootstrap (few treated clusters concern)
## ============================================================

cat("\n--- Wild cluster bootstrap p-values ---\n")

## Use fwildclusterboot if available, otherwise skip
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  twfe_base <- fixest::feols(
    dafw_rate ~ post | state_fips + year,
    data = hc,
    cluster = ~state_fips
  )

  boot_result <- tryCatch({
    fwildclusterboot::boottest(
      twfe_base,
      param = "post",
      clustid = ~state_fips,
      B = 999,
      type = "webb"
    )
  }, error = function(e) {
    cat("Bootstrap failed:", e$message, "\n")
    NULL
  })

  if (!is.null(boot_result)) {
    cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
  }
} else {
  cat("fwildclusterboot not available, skipping\n")
}

## ============================================================
## 6. Save robustness results
## ============================================================

rob_results <- list(
  placebo_att = agg_placebo$overall.att,
  placebo_se = agg_placebo$overall.se,
  loo = loo_results,
  log_att = agg_log$overall.att,
  log_se = agg_log$overall.se,
  trend_coef = coef(twfe_trend)["post"],
  trend_se = se(twfe_trend)["post"],
  no23_att = cs_no23$overall.att,
  no23_se = cs_no23$overall.se
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
