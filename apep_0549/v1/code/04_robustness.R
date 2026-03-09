## =============================================================================
## 04_robustness.R — Robustness checks and mechanism tests
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
state_dow   <- fread(file.path(data_dir, "state_dow_month_panel.csv"))
state_month <- fread(file.path(data_dir, "state_month_panel.csv"))
state_year  <- fread(file.path(data_dir, "state_year_panel.csv"))

state_month[, treat_date := as.Date(treat_date)]
state_year[, treat_date := as.Date(treat_date)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

## -----------------------------------------------------------------------------
## 1. Exclude COVID period (March 2020 - December 2020)
## -----------------------------------------------------------------------------

cat("--- Excluding COVID lockdown period ---\n")

sm_nocovid <- state_month[!(YEAR == 2020 & MONTH >= 3)]
sd_nocovid <- state_dow[!(YEAR == 2020 & MONTH >= 3)]

ddd_nocovid <- feols(
  alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = sd_nocovid,
  cluster = ~state_fips
)

cat("DDD excluding COVID (Mar-Dec 2020):\n")
print(coeftable(ddd_nocovid)["legal_x_sunday_x_nfl", ])

twfe_nocovid <- feols(
  alc_rate ~ treated | state_fips + time_id,
  data = sm_nocovid,
  cluster = ~state_fips
)

cat("TWFE Monthly excluding COVID:\n")
print(coeftable(twfe_nocovid)["treated", ])

## -----------------------------------------------------------------------------
## 2. NFL Season vs. Off-Season
## -----------------------------------------------------------------------------

cat("\n--- NFL Season vs. Off-Season ---\n")

# Effect should be larger during NFL season
dd_nfl <- feols(
  alcohol_crashes ~ legal_x_sunday |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow[nfl_season == 1],
  cluster = ~state_fips
)

dd_offseason <- feols(
  alcohol_crashes ~ legal_x_sunday |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow[nfl_season == 0],
  cluster = ~state_fips
)

cat("DD during NFL season:\n")
print(coeftable(dd_nfl)["legal_x_sunday", ])
cat("\nDD during off-season:\n")
print(coeftable(dd_offseason)["legal_x_sunday", ])

## -----------------------------------------------------------------------------
## 3. Nighttime vs. Daytime
## -----------------------------------------------------------------------------

cat("\n--- Nighttime (8PM-3AM) vs. Daytime ---\n")

# Construct daytime alcohol crashes
state_dow[, day_alc := alcohol_crashes - night_alc]

ddd_night <- feols(
  night_alc ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

ddd_day <- feols(
  day_alc ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

cat("DDD Nighttime alcohol crashes:\n")
print(coeftable(ddd_night)["legal_x_sunday_x_nfl", ])
cat("\nDDD Daytime alcohol crashes:\n")
print(coeftable(ddd_day)["legal_x_sunday_x_nfl", ])

## -----------------------------------------------------------------------------
## 4. Wild cluster bootstrap (state-level)
## -----------------------------------------------------------------------------

cat("\n--- Wild Cluster Bootstrap ---\n")

# Use fwildclusterboot for wild bootstrap p-values
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  set.seed(2024)
  boot_ddd <- tryCatch({
    boottest(
      object = feols(
        alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday +
          treated + treated:nfl_season + nfl_season |
          state_dow + time_id + state_fips,
        data = state_dow,
        cluster = ~state_fips
      ),
      param = "legal_x_sunday_x_nfl",
      clustid = "state_fips",
      B = 9999,
      type = "rademacher"
    )
    }, error = function(e) {
      cat("Wild bootstrap failed:", e$message, "\n")
      NULL
    })

  if (!is.null(boot_ddd)) {
    cat("Wild cluster bootstrap p-value (DDD):", boot_ddd$p_val, "\n")
  }
} else {
  cat("fwildclusterboot not available; skipping.\n")
}

## -----------------------------------------------------------------------------
## 5. Leave-one-out (drop each treated state)
## -----------------------------------------------------------------------------

cat("\n--- Leave-One-Out Analysis ---\n")

treated_states <- unique(state_month[ever_treated == 1]$state_fips)
loo_results <- list()

for (st in treated_states) {
  loo_data <- state_dow[state_fips != st]

  loo_mod <- tryCatch({
    feols(
      alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
        state_dow + time_id^dow + state_fips^time_id,
      data = loo_data,
      cluster = ~state_fips
    )
  }, error = function(e) NULL)

  if (!is.null(loo_mod)) {
    loo_results[[st]] <- data.table(
      dropped_state = st,
      coef = coef(loo_mod)["legal_x_sunday_x_nfl"],
      se = se(loo_mod)["legal_x_sunday_x_nfl"]
    )
  }
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))

cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_dt$coef), max(loo_dt$coef)))
cat(sprintf("LOO mean:  %.4f (full sample DDD for comparison)\n", mean(loo_dt$coef)))

## -----------------------------------------------------------------------------
## 6. Goodman-Bacon decomposition (annual)
## -----------------------------------------------------------------------------

cat("\n--- Goodman-Bacon Decomposition ---\n")

if (requireNamespace("bacondecomp", quietly = TRUE)) {
  library(bacondecomp)

  sy_bacon <- copy(state_year)
  sy_bacon[, state_num := as.integer(as.factor(state_fips))]

  bacon_out <- tryCatch({
    bacon(alc_rate ~ treated, data = as.data.frame(sy_bacon),
          id_var = "state_num", time_var = "YEAR")
  }, error = function(e) {
    cat("Bacon decomposition failed:", e$message, "\n")
    NULL
  })

  if (!is.null(bacon_out)) {
    bacon_summary <- as.data.table(bacon_out)
    # Bacon output may have varying columns; standardize
    if ("estimate" %in% names(bacon_summary) && "weight" %in% names(bacon_summary) &&
        "type" %in% names(bacon_summary)) {
      bacon_summary <- bacon_summary[, .(type, weight, estimate)]
    } else {
      # Use first 3 relevant columns
      setnames(bacon_summary, 1:3, c("type", "weight", "estimate"))
    }
    cat("Goodman-Bacon decomposition:\n")
    print(bacon_summary[, .(
      avg_estimate = weighted.mean(estimate, weight),
      total_weight = sum(weight)
    ), by = type])

    fwrite(bacon_summary, file.path(data_dir, "bacon_decomp.csv"))
  }
} else {
  cat("bacondecomp not available; skipping.\n")
}

## -----------------------------------------------------------------------------
## 7. HonestDiD sensitivity bounds
## -----------------------------------------------------------------------------

cat("\n--- HonestDiD Sensitivity Analysis ---\n")

# Use the fixest event study for HonestDiD
load(file.path(data_dir, "main_models.RData"))

honest_results <- tryCatch({
  # Extract event study coefficients and variance-covariance matrix
  sm_es <- copy(state_month)
  sm_es[, rel_month := fifelse(
    is.na(treat_date), NA_integer_,
    as.integer(difftime(as.Date(sprintf("%d-%02d-15", YEAR, MONTH)),
                         treat_date, units = "days") / 30.44)
  )]
  sm_es[, rel_month_binned := pmax(pmin(rel_month, 12L), -12L)]

  es_honest <- feols(
    alc_rate ~ i(rel_month_binned, ever_treated, ref = -1) |
      state_fips + time_id,
    data = sm_es[!is.na(rel_month) | ever_treated == 0],
    cluster = ~state_fips
  )

  betahat <- coef(es_honest)
  sigma <- vcov(es_honest)

  # Separate pre and post
  pre_idx <- grep("::-", names(betahat))
  post_idx <- grep("::[0-9]", names(betahat))

  if (length(pre_idx) > 1 && length(post_idx) > 0) {
    delta_rm_results <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("HonestDiD sensitivity results:\n")
    print(delta_rm_results)

    fwrite(as.data.table(delta_rm_results),
           file.path(data_dir, "honestdid_results.csv"))
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
  }

  delta_rm_results
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

## -----------------------------------------------------------------------------
## 8. Poisson (PPML) robustness
## -----------------------------------------------------------------------------

cat("\n--- Poisson Pseudo-ML (PPML) ---\n")

ddd_poisson <- tryCatch({
  fepois(
    alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
      state_dow + time_id^dow + state_fips^time_id,
    data = state_dow,
    cluster = ~state_fips
  )
}, error = function(e) {
  cat("Poisson DDD failed:", e$message, "\n")
  NULL
})

if (!is.null(ddd_poisson)) {
  cat("Poisson DDD:\n")
  print(coeftable(ddd_poisson)["legal_x_sunday_x_nfl", ])
}

## -----------------------------------------------------------------------------
## 9. Exposure-normalized DDD (crashes per DOW occurrence)
## -----------------------------------------------------------------------------

cat("\n--- Exposure-Normalized DDD ---\n")

if ("alc_per_dow" %in% names(state_dow)) {
  ddd_exposure <- feols(
    alc_per_dow ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
      state_dow + time_id^dow + state_fips^time_id,
    data = state_dow,
    cluster = ~state_fips
  )
  cat("Exposure-normalized DDD (crashes per DOW occurrence):\n")
  print(coeftable(ddd_exposure)["legal_x_sunday_x_nfl", ])
} else {
  cat("alc_per_dow not available; skipping.\n")
  ddd_exposure <- NULL
}

## -----------------------------------------------------------------------------
## 10. Alternative control groups
## -----------------------------------------------------------------------------

cat("\n--- Alternative Control Groups ---\n")

# Retail-only sports betting states (have retail but not mobile)
# These are states with some form of legal sports betting but not mobile
retail_only_states <- c("28", "35", "30", "10", "38", "46", "02",
                        "44", "16", "31", "27", "55")

# A) Drop retail-only states entirely
sd_no_retail <- state_dow[!(state_fips %in% retail_only_states)]
ddd_no_retail <- tryCatch({
  feols(
    alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
      state_dow + time_id^dow + state_fips^time_id,
    data = sd_no_retail,
    cluster = ~state_fips
  )
}, error = function(e) { cat("Drop retail failed:", e$message, "\n"); NULL })

if (!is.null(ddd_no_retail)) {
  cat("DDD dropping retail-only states:\n")
  print(coeftable(ddd_no_retail)["legal_x_sunday_x_nfl", ])
}

# B) Never-treated only as control (exclude ever-treated pre-treatment)
sd_never_ctrl <- state_dow[ever_treated == 1 | (ever_treated == 0 & !(state_fips %in% retail_only_states))]
ddd_never_ctrl <- tryCatch({
  feols(
    alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
      state_dow + time_id^dow + state_fips^time_id,
    data = sd_never_ctrl,
    cluster = ~state_fips
  )
}, error = function(e) { cat("Never-treated ctrl failed:", e$message, "\n"); NULL })

if (!is.null(ddd_never_ctrl)) {
  cat("DDD with never-treated controls only (exc. retail-only):\n")
  print(coeftable(ddd_never_ctrl)["legal_x_sunday_x_nfl", ])
}

## -----------------------------------------------------------------------------
## 11. Measured-BAC robustness (police-reported DRINKING==1 only)
## -----------------------------------------------------------------------------

cat("\n--- Measured-BAC Robustness ---\n")

if ("measured_alc" %in% names(state_dow)) {
  ddd_measured <- feols(
    measured_alc ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
      state_dow + time_id^dow + state_fips^time_id,
    data = state_dow,
    cluster = ~state_fips
  )
  cat("DDD with police-reported alcohol only:\n")
  print(coeftable(ddd_measured)["legal_x_sunday_x_nfl", ])
} else {
  cat("measured_alc not available; skipping.\n")
  ddd_measured <- NULL
}

## -----------------------------------------------------------------------------
## 12. Saturday placebo (non-NFL high-drinking day)
## -----------------------------------------------------------------------------

cat("\n--- Saturday Placebo ---\n")

state_dow[, is_saturday := as.integer(dow == 7)]
state_dow[, legal_x_saturday := treated * is_saturday]
state_dow[, legal_x_saturday_x_nfl := treated * is_saturday * nfl_season]

ddd_saturday <- feols(
  alcohol_crashes ~ legal_x_saturday_x_nfl + legal_x_saturday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

cat("Saturday placebo DDD:\n")
print(coeftable(ddd_saturday)["legal_x_saturday_x_nfl", ])

## -----------------------------------------------------------------------------
## 13. Collect all robustness results
## -----------------------------------------------------------------------------

robust_summary <- data.table(
  test = c("Main DDD", "Excl. COVID", "NFL Season Only",
           "Off-Season", "Nighttime DDD", "Daytime DDD",
           "LOO Min", "LOO Max"),
  coef = c(
    coef(feols(alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday +
                 treated * nfl_season |
                 state_dow + time_id^dow + state_fips^time_id,
               data = state_dow, cluster = ~state_fips))["legal_x_sunday_x_nfl"],
    coef(ddd_nocovid)["legal_x_sunday_x_nfl"],
    coef(dd_nfl)["legal_x_sunday"],
    coef(dd_offseason)["legal_x_sunday"],
    coef(ddd_night)["legal_x_sunday_x_nfl"],
    coef(ddd_day)["legal_x_sunday_x_nfl"],
    min(loo_dt$coef),
    max(loo_dt$coef)
  )
)

fwrite(robust_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\n=== ROBUSTNESS SUMMARY ===\n")
print(robust_summary)

# Save all robustness models
save(ddd_nocovid, twfe_nocovid, dd_nfl, dd_offseason,
     ddd_night, ddd_day, loo_dt,
     ddd_poisson, ddd_exposure, ddd_no_retail, ddd_never_ctrl,
     ddd_measured, ddd_saturday,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness analysis complete.\n")
