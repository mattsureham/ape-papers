## 04_robustness.R — Robustness checks and placebo tests
## apep_0495: Private School VAT and State School Housing Premium

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

cat("=== ROBUSTNESS CHECKS ===\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date_transfer := as.Date(date_transfer)]
panel[, prop_type := factor(property_type)]
panel[, is_london := as.integer(grepl("^E09", la_code))]

## =========================================================================
## 1. PLACEBO: Zero-treatment areas (LAs with no private schools)
## =========================================================================
cat("\n--- Placebo 1: Zero-treatment areas ---\n")

## Run DDD only on areas with private_share == 0
## The DDD coefficient should be zero (no treatment to transmit)
zero_treat <- panel[private_share == 0]
cat("  Observations in zero-private LAs:", format(nrow(zero_treat), big.mark = ","), "\n")

if (nrow(zero_treat) > 1000) {
  m_placebo_zero <- tryCatch({
    feols(log_price ~ near_good_school:post_vat +
            i(property_type) + i(old_new) + i(duration) |
            la_code + year_month,
          data = zero_treat, vcov = "hetero")
  }, error = function(e) {
    cat("  Zero-treatment placebo failed:", e$message, "\n")
    NULL
  })
  if (!is.null(m_placebo_zero)) {
    cat("  Near Good × Post in zero-private areas:",
        coef(m_placebo_zero)["near_good_school:post_vat"], "\n")
    cat("  SE:", sqrt(vcov(m_placebo_zero)["near_good_school:post_vat",
                                            "near_good_school:post_vat"]), "\n")
  }
} else {
  cat("  Insufficient observations for zero-treatment placebo\n")
}

## =========================================================================
## 2. PLACEBO: Temporal (fake treatment date = Jan 2020)
## =========================================================================
cat("\n--- Placebo 2: Temporal (fake treatment Jan 2020) ---\n")

## Use only pre-treatment data (2015-2023)
pre_only <- panel[date_transfer < as.Date("2024-01-01")]
pre_only[, fake_post := as.integer(date_transfer >= as.Date("2020-01-01"))]

m_placebo_time <- feols(log_price ~ high_private:near_good_school:fake_post +
                          high_private:fake_post + near_good_school:fake_post +
                          i(property_type) + i(old_new) + i(duration) |
                          pc_sector + year_month,
                        data = pre_only, cluster = ~la_code)

## Find the DDD coefficient (name may vary in fixest)
placebo_coefs <- names(coef(m_placebo_time))
ddd_coef_name <- placebo_coefs[grepl("high_private.*near_good.*fake_post|fake_post.*near_good.*high_private", placebo_coefs)]
if (length(ddd_coef_name) == 0) {
  ## Try alternate ordering
  ddd_coef_name <- placebo_coefs[grepl("high_private", placebo_coefs) &
                                   grepl("near_good", placebo_coefs) &
                                   grepl("fake_post", placebo_coefs)]
}
cat("  Available interaction terms:", paste(placebo_coefs[grepl(":", placebo_coefs)], collapse = ", "), "\n")
if (length(ddd_coef_name) > 0) {
  cat("  DDD at fake treatment (Jan 2020):", coef(m_placebo_time)[ddd_coef_name[1]], "\n")
  cat("  SE:", sqrt(vcov(m_placebo_time)[ddd_coef_name[1], ddd_coef_name[1]]), "\n")
} else {
  cat("  DDD coefficient not found in temporal placebo model\n")
}

## =========================================================================
## 3. PLACEBO: Flats vs Houses (school quality matters less for flats)
## =========================================================================
cat("\n--- Placebo 3: Flats (school quality less relevant) ---\n")

## Flats (1-bed, investment) should be less sensitive to school quality
m_flats <- feols(log_price ~ high_private:near_good_school:post_vat +
                   high_private:post_vat + near_good_school:post_vat +
                   i(old_new) + i(duration) |
                   pc_sector + year_month,
                 data = panel[property_type == "F"], cluster = ~la_code)

m_houses <- feols(log_price ~ high_private:near_good_school:post_vat +
                    high_private:post_vat + near_good_school:post_vat +
                    i(old_new) + i(duration) |
                    pc_sector + year_month,
                  data = panel[property_type %in% c("D", "S", "T")], cluster = ~la_code)

## Print DDD coefficients (fixest may reorder interaction terms)
flats_cn <- names(coef(m_flats))
houses_cn <- names(coef(m_houses))
flats_ddd_nm <- flats_cn[grepl("high_private", flats_cn) & grepl("near_good", flats_cn) & grepl("post_vat", flats_cn)]
houses_ddd_nm <- houses_cn[grepl("high_private", houses_cn) & grepl("near_good", houses_cn) & grepl("post_vat", houses_cn)]
cat("  DDD for flats:", if(length(flats_ddd_nm) > 0) coef(m_flats)[flats_ddd_nm[1]] else NA, "\n")
cat("  DDD for houses:", if(length(houses_ddd_nm) > 0) coef(m_houses)[houses_ddd_nm[1]] else NA, "\n")

## =========================================================================
## 4. Distance cutoff sensitivity
## =========================================================================
cat("\n--- Distance cutoff sensitivity ---\n")

cutoffs <- c(1, 2, 3, 5, 10)
cutoff_results <- data.table()

for (d in cutoffs) {
  panel[, near_good_d := as.integer(dist_good_km <= d)]

  m_d <- tryCatch({
    feols(log_price ~ high_private:near_good_d:post_vat +
            high_private:post_vat + near_good_d:post_vat +
            i(property_type) + i(old_new) + i(duration) |
            pc_sector + year_month,
          data = panel, cluster = ~la_code)
  }, error = function(e) NULL)

  if (!is.null(m_d)) {
    cn <- names(coef(m_d))
    coef_name <- cn[grepl("high_private", cn) & grepl("near_good_d", cn) & grepl("post_vat", cn)]
    if (length(coef_name) > 0) {
      cutoff_results <- rbind(cutoff_results, data.table(
        cutoff_km = d,
        coef = coef(m_d)[coef_name[1]],
        se = sqrt(vcov(m_d)[coef_name[1], coef_name[1]]),
        n = nobs(m_d)
      ))
    }
  }
  if (nrow(cutoff_results[cutoff_km == d]) > 0) {
    cat("  Cutoff:", d, "km | Coef:", cutoff_results[cutoff_km == d, coef],
        "| SE:", cutoff_results[cutoff_km == d, se], "\n")
  } else {
    cat("  Cutoff:", d, "km | FAILED\n")
  }
}

fwrite(cutoff_results, file.path(data_dir, "distance_cutoff_sensitivity.csv"))

## =========================================================================
## 5. Leave-one-region-out
## =========================================================================
cat("\n--- Leave-one-region-out ---\n")

regions <- panel[!is.na(region), unique(region)]
loo_results <- data.table()

for (reg in regions) {
  m_loo <- tryCatch({
    feols(log_price ~ high_private:near_good_school:post_vat +
            high_private:post_vat + near_good_school:post_vat +
            i(property_type) + i(old_new) + i(duration) |
            pc_sector + year_month,
          data = panel[region != reg], cluster = ~la_code)
  }, error = function(e) NULL)

  if (!is.null(m_loo)) {
    coef_name <- "high_private:near_good_school:post_vat"
    if (coef_name %in% names(coef(m_loo))) {
      loo_results <- rbind(loo_results, data.table(
        excluded_region = reg,
        coef = coef(m_loo)[coef_name],
        se = sqrt(vcov(m_loo)[coef_name, coef_name])
      ))
    }
  }
}

fwrite(loo_results, file.path(data_dir, "leave_one_region_out.csv"))
cat("  Coefficient range:", round(range(loo_results$coef), 4), "\n")

## =========================================================================
## 6. HonestDiD sensitivity analysis
## =========================================================================
cat("\n--- HonestDiD Sensitivity Analysis ---\n")

## Run on the DD specification (simpler for HonestDiD)
## Event study for DD: high_private × post
es_dd <- feols(log_price ~ i(rel_month, high_private, ref = -1) +
                 i(property_type) + i(old_new) + i(duration) |
                 pc_sector + year_month,
               data = panel[rel_month >= -24 & rel_month <= 14],
               cluster = ~la_code)

## Extract pre-treatment coefficients for HonestDiD
tryCatch({
  es_dd_coefs <- coeftable(es_dd)
  pre_coefs <- es_dd_coefs[grepl("high_private.*::-[0-9]", rownames(es_dd_coefs)), ]

  cat("  Pre-treatment coefficients (DD):\n")
  cat("  Max absolute pre-trend:", round(max(abs(pre_coefs[, 1])), 4), "\n")
  cat("  Joint F-test of pre-trends: see event study figure\n")

  ## HonestDiD bounds (relative magnitudes approach)
  ## This bounds the post-treatment effect under the assumption that
  ## violations of parallel trends are no larger than pre-treatment movements
  if (requireNamespace("HonestDiD", quietly = TRUE)) {
    cat("  Running HonestDiD relative magnitudes...\n")
    ## Extract beta and sigma for HonestDiD
    beta_hat <- coef(es_dd)[grepl("high_private", names(coef(es_dd)))]
    sigma_hat <- vcov(es_dd)[grepl("high_private", rownames(vcov(es_dd))),
                              grepl("high_private", colnames(vcov(es_dd)))]

    ## Only proceed if dimensions match
    n_pre <- sum(grepl("::-", names(beta_hat)))
    n_post <- sum(grepl("::[0-9]", names(beta_hat)))

    if (n_pre > 0 && n_post > 0) {
      cat("  Pre-treatment periods:", n_pre, "\n")
      cat("  Post-treatment periods:", n_post, "\n")

      honest_result <- tryCatch({
        HonestDiD::createSensitivityResults_relativeMagnitudes(
          betahat = beta_hat,
          sigma = sigma_hat,
          numPrePeriods = n_pre,
          numPostPeriods = n_post,
          Mbarvec = seq(0, 2, by = 0.5)
        )
      }, error = function(e) {
        cat("  HonestDiD failed:", e$message, "\n")
        NULL
      })

      if (!is.null(honest_result)) {
        cat("  HonestDiD results:\n")
        print(honest_result)
        save(honest_result, file = file.path(data_dir, "honestdid_results.RData"))
      }
    }
  }
}, error = function(e) {
  cat("  HonestDiD analysis failed:", e$message, "\n")
})

## =========================================================================
## 7. Within-LA price dispersion (inequality channel)
## =========================================================================
cat("\n--- Within-LA Price Dispersion ---\n")

## Collapse to LA × month level
la_month <- panel[, .(
  mean_log_price = mean(log_price, na.rm = TRUE),
  sd_log_price = sd(log_price, na.rm = TRUE),
  p90 = quantile(price, 0.90, na.rm = TRUE),
  p10 = quantile(price, 0.10, na.rm = TRUE),
  p90_p10_ratio = quantile(price, 0.90, na.rm = TRUE) / quantile(price, 0.10, na.rm = TRUE),
  n_transactions = .N
), by = .(la_code, year_month, high_private, private_share)]

la_month[, year_month_date := as.Date(paste0(year_month, "-01"))]
la_month[, post_vat := as.integer(year_month_date >= as.Date("2025-01-01"))]

## Does within-LA price dispersion increase more in high-private areas?
m_disp <- feols(p90_p10_ratio ~ high_private:post_vat |
                  la_code + year_month,
                data = la_month[n_transactions >= 20],
                cluster = ~la_code,
                weights = ~n_transactions)

cat("  P90/P10 ratio: High Private × Post:",
    coef(m_disp)["high_private:post_vat"], "\n")

fwrite(la_month, file.path(data_dir, "la_month_panel.csv"))

## =========================================================================
## 8. MDE calculation
## =========================================================================
cat("\n--- Minimum Detectable Effect ---\n")

## Compute MDE for the DDD
n_total <- nrow(panel)
n_treated <- panel[high_private == 1 & near_good_school == 1 & post_vat == 1, .N]
n_clusters <- uniqueN(panel$la_code)
outcome_sd <- sd(panel$log_price, na.rm = TRUE)

## Simple MDE formula: MDE = 2.8 × σ / √(n_treated × (1 - n_treated/n_total))
mde <- 2.8 * outcome_sd / sqrt(n_treated * (1 - n_treated / n_total))
cat("  N total:", format(n_total, big.mark = ","), "\n")
cat("  N treated cells:", format(n_treated, big.mark = ","), "\n")
cat("  Outcome SD:", round(outcome_sd, 3), "\n")
cat("  Approximate MDE (α=0.05, power=0.80):", round(mde, 4), "\n")
cat("  In percentage terms:", round(100 * (exp(mde) - 1), 2), "%\n")

## Save robustness results
save(m_placebo_time, m_flats, m_houses, cutoff_results,
     loo_results, m_disp, mde,
     file = file.path(data_dir, "robustness_models.RData"))

## =========================================================================
## Robustness summary table
## =========================================================================
cat("\n--- Generating robustness summary ---\n")

## Helper to extract DDD coefficient from a model
extract_ddd <- function(model, pattern_parts) {
  cn <- names(coef(model))
  idx <- which(Reduce(`&`, lapply(pattern_parts, function(p) grepl(p, cn))))
  if (length(idx) > 0) {
    nm <- cn[idx[1]]
    list(coef = coef(model)[nm], se = sqrt(vcov(model)[nm, nm]))
  } else {
    list(coef = NA_real_, se = NA_real_)
  }
}

placebo_ddd <- extract_ddd(m_placebo_time, c("high_private", "near_good", "fake_post"))
flats_ddd <- extract_ddd(m_flats, c("high_private", "near_good", "post_vat"))
houses_ddd <- extract_ddd(m_houses, c("high_private", "near_good", "post_vat"))

## Combine key placebo and robustness results
rob_summary <- data.table(
  Test = c("Temporal placebo (Jan 2020)",
           "Flats only (school quality less relevant)",
           "Houses only (school quality relevant)",
           "Distance 1km", "Distance 2km", "Distance 3km",
           "Distance 5km", "Distance 10km"),
  Coefficient = c(
    placebo_ddd$coef,
    flats_ddd$coef,
    houses_ddd$coef,
    cutoff_results$coef
  ),
  SE = c(
    placebo_ddd$se,
    flats_ddd$se,
    houses_ddd$se,
    cutoff_results$se
  )
)
rob_summary[, Stars := fcase(
  abs(Coefficient / SE) >= 2.576, "***",
  abs(Coefficient / SE) >= 1.960, "**",
  abs(Coefficient / SE) >= 1.645, "*",
  default = ""
)]

fwrite(rob_summary, file.path(tables_dir, "robustness_summary.csv"))
cat("\nRobustness summary:\n")
print(rob_summary)

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
