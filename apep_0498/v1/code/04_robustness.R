## =============================================================================
## 04_robustness.R — Robustness checks and sensitivity analysis
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel_grants.csv"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
panel_pre_covid <- panel[year <= 2019]

set.seed(20240304)

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ---------------------------------------------------------------------------
## 1. Wild Cluster Bootstrap
## ---------------------------------------------------------------------------
cat("--- 1. Wild Cluster Bootstrap ---\n")

if ("ph_grant_per_head" %in% names(panel_pre_covid)) {
  ## Pre-filter to remove singleton fixed effects before WCB
  drug_data <- panel_pre_covid[!is.na(drug_death_rate) & !is.na(ph_grant_per_head)]
  ## Remove LAs with only 1 observation (singletons)
  la_counts <- drug_data[, .N, by = la_code]
  drug_data <- drug_data[la_code %in% la_counts[N > 1]$la_code]
  yr_counts <- drug_data[, .N, by = year]
  drug_data <- drug_data[year %in% yr_counts[N > 1]$year]

  m_drug <- feols(drug_death_rate ~ ph_grant_per_head | la_code + year,
                  data = drug_data)

  ## Check for removed singletons and exclude them from data
  if (length(m_drug$fixef_removed) > 0) {
    removed_ids <- unlist(m_drug$fixef_removed)
    drug_data2 <- drug_data[!la_code %in% removed_ids & !year %in% removed_ids]
    m_drug2 <- feols(drug_death_rate ~ ph_grant_per_head | la_code + year,
                     data = drug_data2)
  } else {
    m_drug2 <- m_drug
    drug_data2 <- drug_data
  }

  wcb_drug <- tryCatch({
    boottest(m_drug2, param = "ph_grant_per_head",
             clustid = drug_data2$la_code,
             B = 9999, type = "webb")
  }, error = function(e) {
    cat(sprintf("  WCB failed for drug deaths: %s\n", e$message))
    NULL
  })

  if (!is.null(wcb_drug)) {
    cat(sprintf("  Drug deaths WCB p-value: %.4f (CI: [%.4f, %.4f])\n",
                wcb_drug$p_val, wcb_drug$conf_int[1], wcb_drug$conf_int[2]))
  }

  ## Alcohol mortality
  alc_data <- panel_pre_covid[!is.na(alcohol_mortality) & !is.na(ph_grant_per_head)]
  la_counts_a <- alc_data[, .N, by = la_code]
  alc_data <- alc_data[la_code %in% la_counts_a[N > 1]$la_code]

  m_alc <- feols(alcohol_mortality ~ ph_grant_per_head | la_code + year,
                 data = alc_data)

  if (length(m_alc$fixef_removed) > 0) {
    removed_ids_a <- unlist(m_alc$fixef_removed)
    alc_data2 <- alc_data[!la_code %in% removed_ids_a & !year %in% removed_ids_a]
    m_alc2 <- feols(alcohol_mortality ~ ph_grant_per_head | la_code + year,
                    data = alc_data2)
  } else {
    m_alc2 <- m_alc
    alc_data2 <- alc_data
  }

  wcb_alc <- tryCatch({
    boottest(m_alc2, param = "ph_grant_per_head",
             clustid = alc_data2$la_code,
             B = 9999, type = "webb")
  }, error = function(e) {
    cat(sprintf("  WCB failed for alcohol: %s\n", e$message))
    NULL
  })

  if (!is.null(wcb_alc)) {
    cat(sprintf("  Alcohol mort WCB p-value: %.4f (CI: [%.4f, %.4f])\n",
                wcb_alc$p_val, wcb_alc$conf_int[1], wcb_alc$conf_int[2]))
  }
}

## ---------------------------------------------------------------------------
## 2. Leave-One-Region-Out
## ---------------------------------------------------------------------------
cat("\n--- 2. Leave-One-Region-Out ---\n")

loro_results <- data.table()

for (excl in c("London", "non-London")) {
  sub_data <- if (excl == "London") {
    panel_pre_covid[!grepl("^E09", la_code)]
  } else {
    panel_pre_covid  # Full sample for comparison
  }

  if (nrow(sub_data[!is.na(drug_death_rate) & !is.na(ph_grant_per_head)]) > 50) {
    m <- feols(drug_death_rate ~ ph_grant_per_head | la_code + year,
               data = sub_data[!is.na(drug_death_rate) & !is.na(ph_grant_per_head)],
               cluster = ~la_code)
    loro_results <- rbind(loro_results, data.table(
      excluded = excl,
      coef = coef(m)["ph_grant_per_head"],
      se = se(m)["ph_grant_per_head"],
      n = nobs(m)
    ))
  }
}

cat("Leave-One-Region-Out (drug deaths):\n")
print(loro_results)

## ---------------------------------------------------------------------------
## 3. Excluding 2020-2021 (COVID years) from full panel
## ---------------------------------------------------------------------------
cat("\n--- 3. Drop COVID Years Only ---\n")

panel_no_covid <- panel[!year %in% 2020:2021]
m_nocovid <- feols(drug_death_rate ~ ph_grant_per_head | la_code + year,
                   data = panel_no_covid[!is.na(drug_death_rate) & !is.na(ph_grant_per_head)],
                   cluster = ~la_code)
cat("Full panel minus 2020-2021:\n")
print(summary(m_nocovid))

## ---------------------------------------------------------------------------
## 4. HonestDiD Sensitivity (Rambachan-Roth bounds)
## ---------------------------------------------------------------------------
cat("\n--- 4. HonestDiD Sensitivity ---\n")

## Re-estimate event study restricted to 2006-2019 for clean HonestDiD
if ("baseline_grant_std" %in% names(panel_pre_covid)) {
  es_data <- panel_pre_covid[year >= 2006 & !is.na(drug_death_rate) & !is.na(baseline_grant_std)]

  es_drug <- feols(drug_death_rate ~ i(year, baseline_grant_std, ref = 2014) | la_code + year,
                   data = es_data,
                   cluster = ~la_code)

  tryCatch({
    betahat <- coef(es_drug)
    sigma <- vcov(es_drug)

    ## Count pre-periods (2006-2013) and post-periods (2015-2019)
    pre_idx <- grep("year::(200[6-9]|201[0-3]):", names(betahat))
    post_idx <- grep("year::(201[5-9]):", names(betahat))

    cat(sprintf("  Pre-periods: %d, Post-periods: %d, Total coefficients: %d\n",
                length(pre_idx), length(post_idx), length(betahat)))

    if (length(pre_idx) > 0 && length(post_idx) > 0 &&
        length(pre_idx) + length(post_idx) == length(betahat)) {
      honest_result <- HonestDiD::createSensitivityResults(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mvec = seq(0, 0.5, by = 0.1)
      )
      cat("HonestDiD sensitivity results:\n")
      print(honest_result)
      saveRDS(honest_result, file.path(DATA_DIR, "honestdid_results.rds"))
    } else {
      cat("  Pre + post periods don't sum to total coefficients. Skipping HonestDiD.\n")
    }
  }, error = function(e) {
    cat(sprintf("  HonestDiD failed: %s\n", e$message))
  })
}

## ---------------------------------------------------------------------------
## 5. Dosage Check (Continuous Treatment Monotonicity)
## ---------------------------------------------------------------------------
cat("\n--- 5. Dosage Check ---\n")

if ("total_change_pct" %in% names(panel_pre_covid)) {
  ## Use total_change_pct (time-invariant) for dosage groups
  ## Get unique LA-level change values
  la_changes <- unique(panel_pre_covid[!is.na(total_change_pct), .(la_code, total_change_pct)])

  if (nrow(la_changes) >= 10) {
    ## Create tercile-based dose response (more robust than quintiles with limited N)
    breaks <- unique(quantile(la_changes$total_change_pct, c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE))
    if (length(breaks) >= 3) {
      la_changes[, dose_group := cut(total_change_pct,
                                      breaks = breaks,
                                      labels = paste0("Q", seq_len(length(breaks) - 1)),
                                      include.lowest = TRUE)]

      panel_pre_covid <- merge(
        panel_pre_covid,
        la_changes[, .(la_code, dose_group)],
        by = "la_code", all.x = TRUE
      )

      ## Reference group = least-cut quartile
      ref_q <- paste0("Q", length(breaks) - 1)

      dose_results <- data.table()
      for (q in setdiff(unique(na.omit(panel_pre_covid$dose_group)), ref_q)) {
        sub <- panel_pre_covid[dose_group %in% c(q, ref_q)]
        if (nrow(sub[!is.na(drug_death_rate)]) > 20) {
          sub[, treated := as.integer(dose_group == q)]
          sub[, post := as.integer(year >= 2016)]
          m <- tryCatch({
            feols(drug_death_rate ~ treated:post | la_code + year,
                  data = sub[!is.na(drug_death_rate)],
                  cluster = ~la_code)
          }, error = function(e) NULL)

          if (!is.null(m)) {
            dose_results <- rbind(dose_results, data.table(
              group = q,
              coef = coef(m)[1],
              se = se(m)[1]
            ))
          }
        }
      }
      cat(sprintf("Dose-response (drug deaths, vs %s=least cut):\n", ref_q))
      print(dose_results)
    }
  }
}

## ---------------------------------------------------------------------------
## 6. Save robustness results
## ---------------------------------------------------------------------------
rob_results <- list(
  wcb_drug = if (exists("wcb_drug")) wcb_drug else NULL,
  wcb_alc = if (exists("wcb_alc")) wcb_alc else NULL,
  loro = loro_results,
  nocovid = if (exists("m_nocovid")) m_nocovid else NULL,
  dose = if (exists("dose_results")) dose_results else NULL
)

saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))
cat("\n✓ Robustness results saved\n")
