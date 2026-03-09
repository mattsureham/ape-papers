## =============================================================================
## 04_robustness.R — Robustness Checks
## Paper: The Economic Integration Lottery
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel <- panel[!is.na(avg_judge_leniency) & !is.na(court_grant_rate)]

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$court_city), "courts\n")

## ---------------------------------------------------------------------------
## A. Placebo Outcomes (High-Skill Sectors)
## ---------------------------------------------------------------------------

cat("\n=== PLACEBO: HIGH-SKILL SECTORS ===\n")
cat("(Asylum integration should NOT affect finance/professional services)\n")

placebo_outcomes <- c("log_finance", "log_professional")
placebo_labels <- c("Log Finance Employment", "Log Professional Services Employment")

placebo_results <- list()
for (i in seq_along(placebo_outcomes)) {
  y <- placebo_outcomes[i]
  if (!y %in% names(panel) || all(is.na(panel[[y]]))) next

  piv <- tryCatch({
    feols(as.formula(paste(y, "~ 1 | year | court_grant_rate ~ avg_judge_leniency")),
          data = panel, cluster = ~court_city)
  }, error = function(e) NULL)

  if (!is.null(piv)) {
    placebo_results[[y]] <- data.table(
      outcome = placebo_labels[i],
      coef_iv = coef(piv)["fit_court_grant_rate"],
      se_iv = se(piv)["fit_court_grant_rate"],
      pval_iv = fixest::pvalue(piv)["fit_court_grant_rate"],
      n_obs = nobs(piv),
      pass = ifelse(abs(fixest::pvalue(piv)["fit_court_grant_rate"]) > 0.1, "PASS", "FAIL")
    )

    cat(sprintf("  %-40s β_IV=%.4f (SE=%.4f) p=%.3f → %s\n",
                placebo_labels[i], coef(piv)["fit_court_grant_rate"],
                se(piv)["fit_court_grant_rate"], fixest::pvalue(piv)["fit_court_grant_rate"],
                ifelse(abs(fixest::pvalue(piv)["fit_court_grant_rate"]) > 0.1, "PASS", "FAIL")))
  }
}

if (length(placebo_results) > 0) {
  placebo_dt <- rbindlist(placebo_results)
  fwrite(placebo_dt, file.path(data_dir, "placebo_results.csv"))
}

## ---------------------------------------------------------------------------
## B. Leave-One-Court-Out Stability
## ---------------------------------------------------------------------------

cat("\n=== LEAVE-ONE-COURT-OUT ===\n")

main_outcome <- if ("log_total" %in% names(panel)) "log_total" else {
  log_vars <- grep("^log_", names(panel), value = TRUE)
  if (length(log_vars) > 0) log_vars[1] else NA
}

if (!is.na(main_outcome) && main_outcome %in% names(panel)) {
  courts <- unique(panel$court_city)
  loco_results <- list()

  for (ct in courts) {
    sub <- panel[court_city != ct]
    loco <- tryCatch({
      feols(as.formula(paste(main_outcome, "~ 1 | year | court_grant_rate ~ avg_judge_leniency")),
            data = sub, cluster = ~court_city)
    }, error = function(e) NULL)

    if (!is.null(loco)) {
      loco_results[[ct]] <- data.table(
        excluded_court = ct,
        coef_iv = coef(loco)["fit_court_grant_rate"],
        se_iv = se(loco)["fit_court_grant_rate"],
        n_obs = nobs(loco)
      )
    }
  }

  loco_dt <- rbindlist(loco_results)
  fwrite(loco_dt, file.path(data_dir, "loco_results.csv"))

  cat("  Coefficient range:", round(range(loco_dt$coef_iv), 4), "\n")
  cat("  Mean:", round(mean(loco_dt$coef_iv), 4), "\n")
  cat("  SD:", round(sd(loco_dt$coef_iv), 4), "\n")
}

## ---------------------------------------------------------------------------
## C. Alternative Fixed Effects
## ---------------------------------------------------------------------------

cat("\n=== ALTERNATIVE FE SPECIFICATIONS ===\n")

if (!is.na(main_outcome) && main_outcome %in% names(panel)) {
  fe_specs <- list(
    "Year FE only" = "~ 1 | year",
    "Region + Year FE" = "~ 1 | region + year",
    "State + Year FE" = "~ 1 | state_fips + year",
    "No FE" = "~ 1"
  )

  fe_results <- list()
  for (name in names(fe_specs)) {
    fe_iv <- tryCatch({
      feols(as.formula(paste(main_outcome, fe_specs[[name]],
                             "| court_grant_rate ~ avg_judge_leniency")),
            data = panel, cluster = ~court_city)
    }, error = function(e) NULL)

    if (!is.null(fe_iv)) {
      fe_results[[name]] <- data.table(
        specification = name,
        coef_iv = coef(fe_iv)["fit_court_grant_rate"],
        se_iv = se(fe_iv)["fit_court_grant_rate"],
        pval_iv = fixest::pvalue(fe_iv)["fit_court_grant_rate"],
        n_obs = nobs(fe_iv)
      )

      cat(sprintf("  %-25s β_IV=%.4f (SE=%.4f) p=%.3f\n",
                  name, coef(fe_iv)["fit_court_grant_rate"],
                  se(fe_iv)["fit_court_grant_rate"],
                  fixest::pvalue(fe_iv)["fit_court_grant_rate"]))
    }
  }

  if (length(fe_results) > 0) {
    fe_dt <- rbindlist(fe_results)
    fwrite(fe_dt, file.path(data_dir, "alt_fe_results.csv"))
  }
}

## ---------------------------------------------------------------------------
## D. Alternative Clustering
## ---------------------------------------------------------------------------

cat("\n=== ALTERNATIVE CLUSTERING ===\n")

if (!is.na(main_outcome) && main_outcome %in% names(panel)) {
  clust_specs <- list(
    "Court" = ~court_city,
    "State" = ~state_fips
  )

  clust_results <- list()
  for (name in names(clust_specs)) {
    cl_iv <- tryCatch({
      feols(as.formula(paste(main_outcome, "~ 1 | year | court_grant_rate ~ avg_judge_leniency")),
            data = panel, cluster = clust_specs[[name]])
    }, error = function(e) NULL)

    if (!is.null(cl_iv)) {
      clust_results[[name]] <- data.table(
        clustering = name,
        coef_iv = coef(cl_iv)["fit_court_grant_rate"],
        se_iv = se(cl_iv)["fit_court_grant_rate"],
        pval_iv = fixest::pvalue(cl_iv)["fit_court_grant_rate"]
      )

      cat(sprintf("  %-20s SE=%.4f (vs court-clustered)\n",
                  name, se(cl_iv)["fit_court_grant_rate"]))
    }
  }

  if (length(clust_results) > 0) {
    clust_dt <- rbindlist(clust_results)
    fwrite(clust_dt, file.path(data_dir, "alt_clustering_results.csv"))
  }
}

## ---------------------------------------------------------------------------
## E. LIML Estimation
## ---------------------------------------------------------------------------

cat("\n=== LIML vs 2SLS ===\n")

main_outcomes <- c("log_total", "log_accom_food", "log_admin_svc",
                    "log_wage_total", "noncitizen_share")
main_labels <- c("Total Employment", "Accommodation Employment",
                  "Admin Services Employment", "Weekly Wage", "Noncitizen Share")

liml_results <- list()
for (i in seq_along(main_outcomes)) {
  y <- main_outcomes[i]
  if (!y %in% names(panel) || all(is.na(panel[[y]]))) next

  liml <- tryCatch({
    formula_str <- paste(y, "~ factor(year) | court_grant_rate | avg_judge_leniency")
    model <- ivreg(as.formula(formula_str), data = panel[!is.na(get(y))])
    list(coef = coef(model)["court_grant_rate"],
         se = sqrt(vcovCL(model, cluster = panel[!is.na(get(y)), court_city])["court_grant_rate", "court_grant_rate"]))
  }, error = function(e) NULL)

  if (!is.null(liml)) {
    liml_results[[y]] <- data.table(
      outcome = main_labels[i],
      coef_liml = liml$coef,
      se_liml = liml$se
    )

    cat(sprintf("  %-30s LIML: β=%.4f (SE=%.4f)\n",
                main_labels[i], liml$coef, liml$se))
  }
}

if (length(liml_results) > 0) {
  liml_dt <- rbindlist(liml_results)
  fwrite(liml_dt, file.path(data_dir, "liml_results.csv"))
}

## ---------------------------------------------------------------------------
## F. Subsample Analysis: Time Periods
## ---------------------------------------------------------------------------

cat("\n=== SUBSAMPLE BY TIME PERIOD ===\n")

if (!is.na(main_outcome) && main_outcome %in% names(panel)) {
  year_range <- range(panel$year)
  mid_year <- floor(mean(year_range))

  time_results <- list()

  early <- panel[year <= mid_year]
  if (nrow(early) > 30) {
    t_early <- tryCatch({
      feols(as.formula(paste(main_outcome, "~ 1 | year | court_grant_rate ~ avg_judge_leniency")),
            data = early, cluster = ~court_city)
    }, error = function(e) NULL)

    if (!is.null(t_early)) {
      time_results[["Early"]] <- data.table(
        period = paste0("Early (", year_range[1], "-", mid_year, ")"),
        coef_iv = coef(t_early)["fit_court_grant_rate"],
        se_iv = se(t_early)["fit_court_grant_rate"],
        n_obs = nobs(t_early)
      )
    }
  }

  late <- panel[year > mid_year]
  if (nrow(late) > 30) {
    t_late <- tryCatch({
      feols(as.formula(paste(main_outcome, "~ 1 | year | court_grant_rate ~ avg_judge_leniency")),
            data = late, cluster = ~court_city)
    }, error = function(e) NULL)

    if (!is.null(t_late)) {
      time_results[["Late"]] <- data.table(
        period = paste0("Late (", mid_year + 1, "-", year_range[2], ")"),
        coef_iv = coef(t_late)["fit_court_grant_rate"],
        se_iv = se(t_late)["fit_court_grant_rate"],
        n_obs = nobs(t_late)
      )
    }
  }

  if (length(time_results) > 0) {
    time_dt <- rbindlist(time_results)
    fwrite(time_dt, file.path(data_dir, "time_subsample_results.csv"))
    for (r in seq_len(nrow(time_dt))) {
      cat(sprintf("  %-30s β_IV=%.4f\n", time_dt$period[r], time_dt$coef_iv[r]))
    }
  }
}

## ---------------------------------------------------------------------------
## G. Monotonicity Check
## ---------------------------------------------------------------------------

cat("\n=== MONOTONICITY CHECK ===\n")
cat("(Judge leniency should move grant rates in the same direction for all subgroups)\n")

if ("region" %in% names(panel)) {
  mono_results <- list()
  for (reg in unique(panel$region)) {
    sub <- panel[region == reg]
    if (n_distinct(sub$court_city) < 3) next

    mono <- tryCatch({
      feols(court_grant_rate ~ avg_judge_leniency | year, data = sub)
    }, error = function(e) NULL)

    if (!is.null(mono)) {
      mono_results[[reg]] <- data.table(
        subgroup = reg,
        coef = coef(mono)["avg_judge_leniency"],
        se = se(mono)["avg_judge_leniency"],
        n_courts = n_distinct(sub$court_city)
      )

      cat(sprintf("  %-15s β=%.4f (%d courts) → %s\n",
                  reg, coef(mono)["avg_judge_leniency"],
                  n_distinct(sub$court_city),
                  ifelse(coef(mono)["avg_judge_leniency"] > 0, "PASS", "VIOLATION")))
    }
  }

  if (length(mono_results) > 0) {
    mono_dt <- rbindlist(mono_results)
    fwrite(mono_dt, file.path(data_dir, "monotonicity_results.csv"))
  }
}

cat("\n=== ROBUSTNESS COMPLETE ===\n")
