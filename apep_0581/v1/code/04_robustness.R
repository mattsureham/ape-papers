# 04_robustness.R — Robustness checks and placebo tests
# APEP-0581: Technology Standards and Facility-Level Pollution

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "facility_panel.csv"))
bat_info <- fread(file.path(data_dir, "bat_conclusions.csv"))

primary_outcome <- "log_nox_tonnes"
cat("Primary outcome:", primary_outcome, "\n")

# Create numeric IDs
panel[, unit_id := as.integer(as.factor(sector_country))]
panel[, year := as.integer(year)]

# Analysis sample (2000+)
analysis_data <- panel[year >= 2000 & !is.na(get(primary_outcome))]
cat("Analysis sample:", nrow(analysis_data), "observations\n")
cat("Units:", uniqueN(analysis_data$sector_country), "\n")
cat("Sectors:", uniqueN(analysis_data$bat_sector), "\n\n")

# Helper to extract p-values from fixest
get_pval <- function(m, coef_name) {
  ct <- coeftable(m)
  ct[coef_name, "Pr(>|t|)"]
}

# ============================================================================
# ROBUSTNESS 1: Leave-one-sector-out
# ============================================================================

cat("=== LEAVE-ONE-SECTOR-OUT ===\n")

sectors <- unique(analysis_data$bat_sector[!is.na(analysis_data$bat_sector)])
loso_results <- list()

for (s in sectors) {
  subset_data <- analysis_data[bat_sector != s]
  if (nrow(subset_data) < 50) next

  model <- tryCatch({
    feols(
      log_nox_tonnes ~ post_bat | unit_id + year,
      data = subset_data, cluster = ~bat_sector
    )
  }, error = function(e) NULL)

  if (!is.null(model)) {
    loso_results[[s]] <- data.table(
      excluded_sector = s,
      coefficient = coef(model)["post_bat"],
      se = se(model)["post_bat"],
      pvalue = get_pval(model, "post_bat"),
      n_obs = nobs(model)
    )
    cat(sprintf("  Excluding %-45s coef=%.4f (SE=%.4f)\n", s,
                coef(model)["post_bat"], se(model)["post_bat"]))
  }
}

if (length(loso_results) > 0) {
  loso_dt <- rbindlist(loso_results)
  fwrite(loso_dt, file.path(data_dir, "robustness_loso.csv"))
  cat("LOSO coefficient range:", round(range(loso_dt$coefficient), 4), "\n")
}

# ============================================================================
# ROBUSTNESS 2: Alternative treatment timing (adoption vs compliance)
# ============================================================================

cat("\n=== ALTERNATIVE TREATMENT TIMING ===\n")

if ("post_bat_adoption" %in% names(analysis_data)) {
  model_adoption <- tryCatch({
    feols(
      log_nox_tonnes ~ post_bat_adoption | unit_id + year,
      data = analysis_data, cluster = ~bat_sector
    )
  }, error = function(e) NULL)

  if (!is.null(model_adoption)) {
    cat("Treatment = BAT adoption date:\n")
    cat("  Coef:", coef(model_adoption)["post_bat_adoption"], "\n")
    cat("  SE:", se(model_adoption)["post_bat_adoption"], "\n")
    cat("  p:", get_pval(model_adoption, "post_bat_adoption"), "\n")

    fwrite(data.table(
      model = "adoption_timing",
      outcome = primary_outcome,
      coefficient = coef(model_adoption)["post_bat_adoption"],
      se = se(model_adoption)["post_bat_adoption"],
      pvalue = get_pval(model_adoption, "post_bat_adoption"),
      n_obs = nobs(model_adoption)
    ), file.path(data_dir, "robustness_adoption_timing.csv"))
  }
}

# ============================================================================
# ROBUSTNESS 3: CO2 placebo (covered by EU ETS, not primarily BAT)
# ============================================================================

cat("\n=== CO2 PLACEBO ===\n")

if ("log_co2_tonnes" %in% names(analysis_data) &&
    sum(!is.na(analysis_data$log_co2_tonnes)) > 100) {
  model_co2 <- tryCatch({
    feols(
      log_co2_tonnes ~ post_bat | unit_id + year,
      data = analysis_data, cluster = ~bat_sector
    )
  }, error = function(e) NULL)

  if (!is.null(model_co2)) {
    cat("CO2 placebo result:\n")
    cat("  Coef:", coef(model_co2)["post_bat"], "\n")
    cat("  SE:", se(model_co2)["post_bat"], "\n")
    cat("  p:", get_pval(model_co2, "post_bat"), "\n")

    fwrite(data.table(
      model = "co2_placebo",
      outcome = "log_co2_tonnes",
      coefficient = coef(model_co2)["post_bat"],
      se = se(model_co2)["post_bat"],
      pvalue = get_pval(model_co2, "post_bat"),
      n_obs = nobs(model_co2)
    ), file.path(data_dir, "robustness_co2_placebo.csv"))
  }
} else {
  cat("CO2 data not available for placebo test.\n")
}

# ============================================================================
# ROBUSTNESS 4: Placebo treatment timing (-3 years)
# ============================================================================

cat("\n=== PLACEBO TIMING (-3 YEARS) ===\n")

placebo_data <- copy(analysis_data)
placebo_data[, placebo_compliance := compliance_year - 3L]
placebo_data[, post_placebo := as.integer(!is.na(placebo_compliance) & year >= placebo_compliance)]

# Restrict to pre-treatment period only
placebo_data <- placebo_data[year < compliance_year | is.na(compliance_year) | compliance_year == 0]

if (nrow(placebo_data) > 100) {
  model_placebo <- tryCatch({
    feols(
      log_nox_tonnes ~ post_placebo | unit_id + year,
      data = placebo_data, cluster = ~bat_sector
    )
  }, error = function(e) NULL)

  if (!is.null(model_placebo)) {
    cat("Placebo timing (-3 years) result:\n")
    cat("  Coef:", coef(model_placebo)["post_placebo"], "\n")
    cat("  SE:", se(model_placebo)["post_placebo"], "\n")
    cat("  p:", get_pval(model_placebo, "post_placebo"), "\n")

    fwrite(data.table(
      model = "placebo_timing",
      coefficient = coef(model_placebo)["post_placebo"],
      se = se(model_placebo)["post_placebo"],
      pvalue = get_pval(model_placebo, "post_placebo"),
      n_obs = nobs(model_placebo)
    ), file.path(data_dir, "robustness_placebo_timing.csv"))
  }
}

# ============================================================================
# ROBUSTNESS 5: Randomization inference
# ============================================================================

cat("\n=== RANDOMIZATION INFERENCE ===\n")

set.seed(42)
n_perms <- 500

# Get observed coefficient (no clustering for speed)
main_model <- tryCatch({
  feols(
    log_nox_tonnes ~ post_bat | unit_id + year,
    data = analysis_data
  )
}, error = function(e) NULL)

if (!is.null(main_model)) {
  observed_coef <- coef(main_model)["post_bat"]

  # Permutation: shuffle compliance years across sectors
  bat_timing <- unique(analysis_data[, .(bat_sector, compliance_year)])
  perm_coefs <- numeric(n_perms)

  for (i in seq_len(n_perms)) {
    shuffled_years <- sample(bat_timing$compliance_year)
    perm_map <- data.table(
      bat_sector = bat_timing$bat_sector,
      perm_compliance = shuffled_years
    )

    perm_data <- merge(analysis_data, perm_map, by = "bat_sector")
    perm_data[, post_perm := as.integer(perm_compliance > 0 & year >= perm_compliance)]

    perm_model <- tryCatch({
      feols(
        log_nox_tonnes ~ post_perm | unit_id + year,
        data = perm_data
      )
    }, error = function(e) NULL)

    if (!is.null(perm_model)) {
      perm_coefs[i] <- coef(perm_model)["post_perm"]
    }

    if (i %% 100 == 0) cat("  Permutation", i, "of", n_perms, "\n")
  }

  # Two-sided p-value
  ri_pvalue <- mean(abs(perm_coefs) >= abs(observed_coef), na.rm = TRUE)
  cat("RI p-value:", ri_pvalue, "\n")
  cat("Observed coefficient:", observed_coef, "\n")
  cat("Permutation mean:", mean(perm_coefs, na.rm = TRUE), "\n")
  cat("Permutation SD:", sd(perm_coefs, na.rm = TRUE), "\n")

  fwrite(data.table(
    observed_coef = observed_coef,
    ri_pvalue = ri_pvalue,
    perm_mean = mean(perm_coefs, na.rm = TRUE),
    perm_sd = sd(perm_coefs, na.rm = TRUE),
    n_perms = n_perms
  ), file.path(data_dir, "robustness_ri.csv"))

  fwrite(data.table(perm_coef = perm_coefs),
         file.path(data_dir, "ri_permutation_dist.csv"))
}

# ============================================================================
# ROBUSTNESS 6: Alternative clustering (country level)
# ============================================================================

cat("\n=== ALTERNATIVE CLUSTERING ===\n")

# Main uses bat_sector clustering. Try country-level.
model_country_cluster <- tryCatch({
  feols(
    log_nox_tonnes ~ post_bat | unit_id + year,
    data = analysis_data, cluster = ~country
  )
}, error = function(e) NULL)

if (!is.null(model_country_cluster)) {
  cat("Country-level clustering:\n")
  cat("  Coef:", coef(model_country_cluster)["post_bat"], "\n")
  cat("  SE:", se(model_country_cluster)["post_bat"], "\n")
  cat("  p:", get_pval(model_country_cluster, "post_bat"), "\n")
  cat("  Clusters:", uniqueN(analysis_data$country), "\n")

  fwrite(data.table(
    model = "cluster_country",
    coefficient = coef(model_country_cluster)["post_bat"],
    se = se(model_country_cluster)["post_bat"],
    pvalue = get_pval(model_country_cluster, "post_bat"),
    n_clusters = uniqueN(analysis_data$country)
  ), file.path(data_dir, "robustness_alt_clustering.csv"))
}

# Two-way clustering: sector + country
model_twoway <- tryCatch({
  feols(
    log_nox_tonnes ~ post_bat | unit_id + year,
    data = analysis_data, cluster = ~bat_sector + country
  )
}, error = function(e) NULL)

if (!is.null(model_twoway)) {
  cat("\nTwo-way clustering (sector + country):\n")
  cat("  Coef:", coef(model_twoway)["post_bat"], "\n")
  cat("  SE:", se(model_twoway)["post_bat"], "\n")
  cat("  p:", get_pval(model_twoway, "post_bat"), "\n")
}

# ============================================================================
# ROBUSTNESS 7: Excluding early/late cohorts
# ============================================================================

cat("\n=== COHORT SENSITIVITY ===\n")

# Exclude the earliest cohort (2012 — Iron/Steel, Glass)
early_cutoff <- 2016
late_data <- analysis_data[compliance_year >= early_cutoff | first_treat == 0]
if (nrow(late_data) > 100) {
  model_late <- tryCatch({
    feols(
      log_nox_tonnes ~ post_bat | unit_id + year,
      data = late_data, cluster = ~bat_sector
    )
  }, error = function(e) NULL)

  if (!is.null(model_late)) {
    cat("Excluding pre-2016 cohorts:\n")
    cat("  Coef:", coef(model_late)["post_bat"], "\n")
    cat("  SE:", se(model_late)["post_bat"], "\n")
  }
}

# ============================================================================
# Summary
# ============================================================================

cat("\n=== ROBUSTNESS SUMMARY ===\n")

rob_files <- list.files(data_dir, pattern = "^robustness_", full.names = TRUE)
for (f in rob_files) {
  r <- tryCatch(fread(f), error = function(e) NULL)
  if (!is.null(r) && "coefficient" %in% names(r)) {
    cat(sprintf("  %-35s coef=%.4f\n", basename(f), r$coefficient[1]))
  }
}

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
