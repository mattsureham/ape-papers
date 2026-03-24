## 03_main_analysis.R — Main DiD estimation
## SNAP EA Expiration and Eviction Filings
## Uses: fixest (TWFE, Sun-Abraham), did (Callaway-Sant'Anna), data.table

source("00_packages.R")

data_dir <- "../data"
monthly <- readRDS(file.path(data_dir, "ets_panel_monthly.rds"))

## ═══════════════════════════════════════════════════════════════════
## 0. Fix Census income codes & reconstruct quartiles
## ═══════════════════════════════════════════════════════════════════
## Census ACS uses negative values (e.g., -666666666) for missing/suppressed
monthly[median_income < 0, median_income := NA_real_]

## Reconstruct income quartiles with clean data
monthly[, income_quartile := cut(median_income,
                                  breaks = quantile(median_income,
                                                    probs = c(0, 0.25, 0.5, 0.75, 1),
                                                    na.rm = TRUE),
                                  labels = c("Q1_low", "Q2", "Q3", "Q4_high"),
                                  include.lowest = TRUE)]

## ═══════════════════════════════════════════════════════════════════
## 1. TWFE Difference-in-Differences (baseline)
## ═══════════════════════════════════════════════════════════════════
cat("=== MAIN ANALYSIS ===\n\n")
cat("1. TWFE DiD (baseline)\n")

## Binary treatment: post = 1 if EA has ended in this state by this month
## Cluster at state level

## Main specification: filing rate (per 1000 renter units)
twfe_main <- feols(
  filing_rate ~ post | GEOID + month_num,
  data = monthly,
  cluster = ~state_abbr
)
cat("TWFE coefficient:", round(coef(twfe_main)["post"], 4),
    "SE:", round(se(twfe_main)["post"], 4), "\n")
summary(twfe_main)

## Filing count (level)
twfe_count <- feols(
  filings ~ post | GEOID + month_num,
  data = monthly,
  cluster = ~state_abbr
)

## ═══════════════════════════════════════════════════════════════════
## 2. Callaway-Sant'Anna (heterogeneity-robust)
## ═══════════════════════════════════════════════════════════════════
cat("\n2. Callaway-Sant'Anna estimation\n")

## CS requires: yname (outcome), tname (time), idname (unit), gname (group)
## group = first treated period (0 for never-treated)

## Ensure panel is balanced within the analysis window
## Some tracts may have missing months
panel_check <- monthly[, .(n_months = .N), by = GEOID]
balanced_tracts <- panel_check[n_months == max(n_months), GEOID]
monthly_bal <- monthly[GEOID %in% balanced_tracts]
cat("Balanced panel:", length(balanced_tracts), "tracts,",
    nrow(monthly_bal), "rows\n")

## Convert GEOID to numeric for CS
monthly_bal[, tract_id := as.integer(factor(GEOID))]

## Run CS ATT
## Use not-yet-treated as control group for maximum power
cs_out <- tryCatch({
  att_gt(
    yname = "filing_rate",
    tname = "month_num",
    idname = "tract_id",
    gname = "treat_month_cs",
    data = as.data.frame(monthly_bal),
    control_group = "notyettreated",
    base_period = "universal",
    bstrap = TRUE,
    cband = TRUE,
    clustervars = "state_abbr"
  )
}, error = function(e) {
  cat("CS estimation error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  ## Aggregate to simple ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("CS ATT:", round(cs_agg$overall.att, 4),
      "SE:", round(cs_agg$overall.se, 4), "\n")

  ## Dynamic aggregation (event study)
  cs_dyn <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 18)
  cat("\nCS Event Study (dynamic ATT):\n")
  cs_dyn_df <- data.frame(
    event_time = cs_dyn$egt,
    att = cs_dyn$att.egt,
    se = cs_dyn$se.egt,
    ci_lower = cs_dyn$att.egt - 1.96 * cs_dyn$se.egt,
    ci_upper = cs_dyn$att.egt + 1.96 * cs_dyn$se.egt
  )
  print(cs_dyn_df)

  ## Group-level aggregation
  cs_group <- aggte(cs_out, type = "group")
  cat("\nCS Group ATTs:\n")
  print(data.frame(
    group = cs_group$egt,
    att = round(cs_group$att.egt, 4),
    se = round(cs_group$se.egt, 4)
  ))
} else {
  cat("CS estimation failed. Using TWFE only.\n")
}

## ═══════════════════════════════════════════════════════════════════
## 3. Event study with fixest (TWFE-based)
## ═══════════════════════════════════════════════════════════════════
cat("\n3. TWFE Event Study\n")

## Create event time variable (months relative to EA end)
monthly[, event_time := as.integer(
  difftime(year_month, ea_end_date, units = "days")
) %/% 30]

## Restrict event window to [-12, +18]
monthly_es <- monthly[event_time >= -12 & event_time <= 18]

## Sun-Abraham event study (avoids forbidden comparison bias)
es_sa <- feols(
  filing_rate ~ sunab(treat_month_cs, month_num) | GEOID + month_num,
  data = monthly_es[treat_month_cs > 0 | treat_month_cs == 0],
  cluster = ~state_abbr
)
cat("Sun-Abraham event study estimated.\n")

## TWFE event study for comparison
monthly_es[, event_time_f := factor(event_time)]
## Drop event_time -1 as reference
monthly_es[, event_time_f := relevel(event_time_f, ref = "-1")]

es_twfe <- feols(
  filing_rate ~ event_time_f | GEOID + month_num,
  data = monthly_es[early_optout == TRUE | early_optout == FALSE],
  cluster = ~state_abbr
)

## ═══════════════════════════════════════════════════════════════════
## 4. Dose-Response: Interaction with SNAP participation rate
## ═══════════════════════════════════════════════════════════════════
cat("\n4. Dose-Response by SNAP participation\n")

## Interact treatment with continuous SNAP rate
dose_cont <- feols(
  filing_rate ~ post + post:snap_rate | GEOID + month_num,
  data = monthly[!is.na(snap_rate)],
  cluster = ~state_abbr
)
cat("Dose-response (continuous):\n")
summary(dose_cont)

## By SNAP quartile
dose_q <- feols(
  filing_rate ~ post:snap_quartile | GEOID + month_num,
  data = monthly[!is.na(snap_quartile)],
  cluster = ~state_abbr
)
cat("\nDose-response (quartiles):\n")
summary(dose_q)

## ═══════════════════════════════════════════════════════════════════
## 5. Income Placebo: High-income tracts should show no effect
## ═══════════════════════════════════════════════════════════════════
cat("\n5. Income Placebo\n")

## Split by income quartile
for (q in c("Q1_low", "Q4_high")) {
  fit_q <- feols(
    filing_rate ~ post | GEOID + month_num,
    data = monthly[income_quartile == q],
    cluster = ~state_abbr
  )
  cat(q, "- ATT:", round(coef(fit_q)["post"], 4),
      "SE:", round(se(fit_q)["post"], 4),
      "p:", round(fixest::pvalue(fit_q)["post"], 4), "\n")
}

## ═══════════════════════════════════════════════════════════════════
## 6. Store results and diagnostics
## ═══════════════════════════════════════════════════════════════════
cat("\n=== STORING RESULTS ===\n")

## Diagnostics for validator
n_treated <- length(unique(monthly[early_optout == TRUE, state_abbr]))
n_pre <- length(unique(monthly[event_time < 0, month_num]))
n_obs <- nrow(monthly)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_tracts = length(unique(monthly$GEOID)),
  n_states = length(unique(monthly$state_abbr)),
  n_months = length(unique(monthly$month_num)),
  twfe_att = round(coef(twfe_main)["post"], 4),
  twfe_se = round(se(twfe_main)["post"], 4),
  twfe_pval = round(fixest::pvalue(twfe_main)["post"], 6),
  sd_y_pre = round(sd(monthly[post == 0, filing_rate], na.rm = TRUE), 4)
)

if (!is.null(cs_out)) {
  diag$cs_att <- round(cs_agg$overall.att, 4)
  diag$cs_se <- round(cs_agg$overall.se, 4)
}

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

## Save estimation objects
saveRDS(twfe_main, file.path(data_dir, "twfe_main.rds"))
saveRDS(cs_out, file.path(data_dir, "cs_out.rds"))
saveRDS(cs_dyn_df, file.path(data_dir, "cs_event_study.rds"))
saveRDS(dose_cont, file.path(data_dir, "dose_cont.rds"))
saveRDS(dose_q, file.path(data_dir, "dose_quartile.rds"))

cat("\nDiagnostics:\n")
print(diag)
cat("\nMain analysis complete.\n")
