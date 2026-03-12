## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0486 v2: Progressive Prosecutors, Incarceration, and Public Safety
## NEW in v2: WCB for all specs, county-clustered SEs, randomization inference, donut

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
panel[, state_fips := str_pad(as.character(state_fips), width = 2, pad = "0")]
panel[, pretrial_rate := fifelse(total_pop_15to64 > 0,
                                  total_jail_pretrial / total_pop_15to64 * 100000, NA_real_)]

cat("=== ROBUSTNESS 1: Pre-COVID Sample (2005-2019) ===\n")

pre_covid <- panel[year <= 2019]
rob_precovid <- feols(
  jail_rate ~ treated | fips + year,
  data = pre_covid[!is.na(jail_rate)],
  cluster = ~state_fips
)
cat("Pre-COVID jail rate:\n")
summary(rob_precovid)

cat("\n=== ROBUSTNESS 2: Pre-2020 Cohorts Only ===\n")

pre2020_cohort <- panel[treatment_year == 0 | treatment_year < 2020]
rob_precohort <- feols(
  jail_rate ~ treated | fips + year,
  data = pre2020_cohort[!is.na(jail_rate)],
  cluster = ~state_fips
)
cat("Pre-2020 cohorts jail rate:\n")
summary(rob_precohort)

cat("\n=== ROBUSTNESS 3: Leave-One-Out Influence ===\n")

large_counties <- c("17031", "06037", "48201", "42101", "48113")
loo_results <- list()

for (drop_fips in large_counties) {
  subset <- panel[fips != drop_fips & !is.na(jail_rate)]
  mod <- feols(
    jail_rate ~ treated | fips + year,
    data = subset,
    cluster = ~state_fips
  )
  county_name <- panel[fips == drop_fips, county_name[1]]
  loo_results[[drop_fips]] <- data.frame(
    dropped = county_name,
    fips = drop_fips,
    coef = coef(mod)["treated"],
    se = se(mod)["treated"],
    pval = pvalue(mod)["treated"]
  )
  cat(sprintf("  Drop %s (%s): coef=%.2f, se=%.2f, p=%.3f\n",
              county_name, drop_fips,
              coef(mod)["treated"], se(mod)["treated"], pvalue(mod)["treated"]))
}

loo_df <- bind_rows(loo_results)
fwrite(loo_df, file.path(DATA_DIR, "loo_results.csv"))

cat("\n=== ROBUSTNESS 4: Wild Cluster Bootstrap (ALL main specs) ===\n")

# WCB for baseline jail rate
set.seed(2024)
wcb_jail <- tryCatch({
  boottest(
    feols(jail_rate ~ treated | fips + year, data = panel[!is.na(jail_rate)],
          cluster = ~state_fips),
    param = "treated",
    clustid = "state_fips",
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("WCB baseline failed:", e$message, "\n")
  NULL
})

if (!is.null(wcb_jail)) {
  cat("\nWild Cluster Bootstrap (Baseline Jail Rate):\n")
  print(summary(wcb_jail))
}

# WCB for metro-only
metro_panel <- fread(file.path(DATA_DIR, "metro_panel.csv"))
metro_panel[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
metro_panel[, state_fips := str_pad(as.character(state_fips), width = 2, pad = "0")]

set.seed(2024)
wcb_metro <- tryCatch({
  boottest(
    feols(jail_rate ~ treated | fips + year, data = metro_panel[!is.na(jail_rate)],
          cluster = ~state_fips),
    param = "treated",
    clustid = "state_fips",
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("WCB metro failed:", e$message, "\n")
  NULL
})

if (!is.null(wcb_metro)) {
  cat("\nWild Cluster Bootstrap (Metro Jail Rate):\n")
  print(summary(wcb_metro))
}

# WCB for state×year FE
set.seed(2024)
wcb_sxyr <- tryCatch({
  boottest(
    feols(jail_rate ~ treated | fips + state_fips^year, data = panel[!is.na(jail_rate)],
          cluster = ~state_fips),
    param = "treated",
    clustid = "state_fips",
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("WCB state×year failed:", e$message, "\n")
  NULL
})

if (!is.null(wcb_sxyr)) {
  cat("\nWild Cluster Bootstrap (State × Year FE):\n")
  print(summary(wcb_sxyr))
}

# WCB for homicide
set.seed(2024)
wcb_hom <- tryCatch({
  boottest(
    feols(homicide_rate ~ treated | fips + year, data = panel[!is.na(homicide_rate)],
          cluster = ~state_fips),
    param = "treated",
    clustid = "state_fips",
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("WCB homicide failed:", e$message, "\n")
  NULL
})

if (!is.null(wcb_hom)) {
  cat("\nWild Cluster Bootstrap (Homicide):\n")
  print(summary(wcb_hom))
}

# WCB for DDD
set.seed(2024)
race_long <- fread(file.path(DATA_DIR, "race_panel.csv"))
race_long[, fips := str_pad(as.character(fips), width = 5, pad = "0")]
ddd_data <- race_long[!is.na(jail_rate_race)]
ddd_data[, `:=`(
  fips_race = paste0(fips, "_", race),
  year_race = paste0(year, "_", race),
  state_fips = substr(fips, 1, 2)
)]

wcb_ddd <- tryCatch({
  ddd_mod <- feols(
    jail_rate_race ~ is_black:treated | fips_race + year_race + fips^year,
    data = ddd_data,
    cluster = ~state_fips
  )
  boottest(
    ddd_mod,
    param = "is_black:treated",
    clustid = "state_fips",
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("WCB DDD failed:", e$message, "\n")
  NULL
})

if (!is.null(wcb_ddd)) {
  cat("\nWild Cluster Bootstrap (DDD):\n")
  print(summary(wcb_ddd))
}

# Store WCB results
wcb_results <- list(
  baseline = wcb_jail,
  metro = wcb_metro,
  sxyr = wcb_sxyr,
  homicide = wcb_hom,
  ddd = wcb_ddd
)

cat("\n=== ROBUSTNESS 5: County-clustered SEs ===\n")

# Re-estimate with county-level clustering
twfe_jail_county <- feols(
  jail_rate ~ treated | fips + year,
  data = panel[!is.na(jail_rate)],
  cluster = ~fips
)
cat("County-clustered SEs (Jail Rate):\n")
cat(sprintf("  coef=%.2f, se=%.2f, p=%.4f\n",
            coef(twfe_jail_county)["treated"],
            se(twfe_jail_county)["treated"],
            pvalue(twfe_jail_county)["treated"]))

cat("\n=== ROBUSTNESS 6: Randomization Inference ===\n")

# Permute treatment across counties
set.seed(2024)
n_perms <- 1000
actual_coef <- coef(feols(jail_rate ~ treated | fips + year,
                           data = panel[!is.na(jail_rate)],
                           cluster = ~state_fips))["treated"]

# Get unique treated FIPS
treated_fips <- unique(panel[ever_treated == 1, fips])
all_fips <- unique(panel$fips)
n_treated <- length(treated_fips)

ri_coefs <- numeric(n_perms)
cat("Running randomization inference (", n_perms, "permutations)...\n")

for (perm in seq_len(n_perms)) {
  # Randomly assign treatment to n_treated counties
  fake_treated <- sample(all_fips, n_treated)
  perm_panel <- copy(panel[!is.na(jail_rate)])

  # Get treatment years from actual treated counties
  actual_treatment_info <- panel[ever_treated == 1, .(fips, treatment_year)]
  actual_treatment_info <- actual_treatment_info[!duplicated(fips)]

  # Assign random treatment years
  perm_panel[, fake_treated := fifelse(fips %in% fake_treated, 1L, 0L)]
  perm_panel[, fake_treatment_year := 0L]

  # Map actual treatment years to fake treated counties
  fake_treatment_map <- data.table(
    fips = fake_treated,
    fake_treatment_year = sample(actual_treatment_info$treatment_year, n_treated, replace = TRUE)
  )
  perm_panel <- merge(perm_panel, fake_treatment_map, by = "fips", all.x = TRUE,
                       suffixes = c("", ".new"))
  perm_panel[!is.na(fake_treatment_year.new), fake_treatment_year := fake_treatment_year.new]
  perm_panel[, fake_treatment_year.new := NULL]
  perm_panel[, fake_post := fifelse(fake_treatment_year > 0 & year >= fake_treatment_year, 1L, 0L)]

  tryCatch({
    mod <- feols(jail_rate ~ fake_post | fips + year,
                 data = perm_panel, cluster = ~state_fips)
    ri_coefs[perm] <- coef(mod)["fake_post"]
  }, error = function(e) {
    ri_coefs[perm] <- NA
  })

  if (perm %% 200 == 0) cat(sprintf("  Permutation %d/%d\n", perm, n_perms))
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(actual_coef), na.rm = TRUE)
cat(sprintf("\nRandomization Inference:\n"))
cat(sprintf("  Actual coefficient: %.2f\n", actual_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  Non-NA permutations: %d/%d\n", sum(!is.na(ri_coefs)), n_perms))

# Save RI distribution
fwrite(data.table(perm_coef = ri_coefs), file.path(DATA_DIR, "ri_distribution.csv"))

cat("\n=== ROBUSTNESS 7: HonestDiD Sensitivity ===\n")

tryCatch({
  panel[, rel_time := fifelse(treatment_year > 0, year - treatment_year, NA_integer_)]
  panel[treatment_year == 0, rel_time := -1000L]
  panel[, rel_time_binned := pmin(pmax(rel_time, -8L), 6L)]
  panel[rel_time == -1000L, rel_time_binned := NA_integer_]

  es_data <- panel[!is.na(jail_rate) & !is.na(rel_time_binned)]
  es_data[, rel_time_f := factor(rel_time_binned)]

  es_mod <- feols(
    jail_rate ~ i(rel_time_f, ref = "-1") | fips + year,
    data = es_data,
    cluster = ~state_fips
  )

  honest_result <- tryCatch({
    betahat <- coef(es_mod)
    sigma <- vcov(es_mod)
    pre_idx <- grep("rel_time_f::-[2-8]", names(betahat))
    post_idx <- grep("rel_time_f::[0-6]", names(betahat))

    if (length(pre_idx) > 0 && length(post_idx) > 0) {
      honest <- HonestDiD::createSensitivityResults(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mvec = seq(0, 0.5, by = 0.1),
        alpha = 0.05
      )
      cat("HonestDiD sensitivity results:\n")
      print(honest)
      honest
    }
  }, error = function(e) {
    cat("HonestDiD failed:", e$message, "\n")
    NULL
  })
}, error = function(e) {
  cat("Event study setup failed:", e$message, "\n")
})

cat("\n=== ROBUSTNESS 8: AAPI Placebo ===\n")

if ("aapi_pop_15to64" %in% names(panel)) {
  panel[, aapi_jail_rate := fifelse(aapi_pop_15to64 > 10,
                                     aapi_jail_pop / aapi_pop_15to64 * 100000, NA_real_)]
} else {
  panel[, aapi_jail_rate := fifelse(!is.na(aapi_jail_pop) & total_pop_15to64 > 0,
                                     aapi_jail_pop / total_pop_15to64 * 100000, NA_real_)]
}

rob_aapi <- feols(
  aapi_jail_rate ~ treated | fips + year,
  data = panel[!is.na(aapi_jail_rate) & is.finite(aapi_jail_rate)],
  cluster = ~state_fips
)
cat("AAPI Placebo:\n")
summary(rob_aapi)

cat("\n=== ROBUSTNESS 9: Jail Admissions (Flow) ===\n")

panel[, jail_adm_rate := fifelse(total_pop_15to64 > 0,
                                  total_jail_adm / total_pop_15to64 * 100000, NA_real_)]

rob_adm <- feols(
  jail_adm_rate ~ treated | fips + year,
  data = panel[!is.na(jail_adm_rate)],
  cluster = ~state_fips
)
cat("Jail Admissions Rate:\n")
summary(rob_adm)

cat("\n=== ROBUSTNESS 10: Excluding 2020 ===\n")

rob_no2020 <- feols(
  jail_rate ~ treated | fips + year,
  data = panel[year != 2020 & !is.na(jail_rate)],
  cluster = ~state_fips
)
cat("Excluding 2020:\n")
summary(rob_no2020)

cat("\n=== ROBUSTNESS 11: Population-Weighted ===\n")

rob_weighted <- feols(
  jail_rate ~ treated | fips + year,
  data = panel[!is.na(jail_rate) & !is.na(total_pop)],
  weights = ~total_pop,
  cluster = ~state_fips
)
cat("Population-weighted:\n")
summary(rob_weighted)

cat("\n=== ROBUSTNESS 12: Spillover Donut ===\n")

if ("donut_sample" %in% names(panel)) {
  donut_panel <- panel[donut_sample == 1 & !is.na(jail_rate)]
  rob_donut <- feols(
    jail_rate ~ treated | fips + year,
    data = donut_panel,
    cluster = ~state_fips
  )
  cat("Donut (excluding adjacent counties):\n")
  summary(rob_donut)
} else {
  cat("Donut sample not available.\n")
  rob_donut <- NULL
}

cat("\n=== SAVING ALL ROBUSTNESS RESULTS ===\n")

rob_results <- list(
  precovid = rob_precovid,
  precohort = rob_precohort,
  loo = loo_df,
  no2020 = rob_no2020,
  aapi_placebo = rob_aapi,
  jail_adm = rob_adm,
  weighted = rob_weighted,
  donut = if (exists("rob_donut")) rob_donut else NULL,
  wcb = wcb_results,
  ri_pvalue = ri_pvalue,
  ri_coefs = ri_coefs,
  county_clustered = twfe_jail_county
)

saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
