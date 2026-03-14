## ============================================================
## 04_robustness.R — Robustness checks and placebo tests
## apep_0674: PBF and the Cream-Skimming Margin
## ============================================================

source("00_packages.R")
load("../data/analysis_panel.RData")
load("../data/main_results.RData")

## ============================
## A. Private-institution placebo
## ============================

cat("\n=== PRIVATE INSTITUTION PLACEBO ===\n")

## Private 4-year institutions in ALL states (PBF and non-PBF)
## They should NOT respond to PBF (they don't receive state appropriations)

private_data <- panel |>
  filter(is_private_4yr, year >= 2003, year <= 2022) |>
  filter(!is.na(bachelors_total), bachelors_total > 0) |>
  mutate(
    ln_bachelors = log(pmax(bachelors_total, 1)),
    ln_enroll = log(pmax(enroll_total, 1)),
    treated = as.integer(!is.na(pbf_year) & year >= pbf_year)
  ) |>
  group_by(unitid) |>
  filter(n() >= 10, max(bachelors_total, na.rm = TRUE) >= 50) |>
  ungroup()

cat("Private sample:", nrow(private_data), "obs,",
    n_distinct(private_data$unitid), "institutions\n")

placebo_comp <- feols(ln_bachelors ~ treated | unitid + year,
                      data = private_data, cluster = ~state)
placebo_enroll <- feols(ln_enroll ~ treated | unitid + year,
                        data = private_data, cluster = ~state)
placebo_minority <- feols(pct_minority ~ treated | unitid + year,
                          data = private_data, cluster = ~state)

cat("Placebo completions:", coef(placebo_comp)["treated"],
    " SE:", se(placebo_comp)["treated"], "\n")
cat("Placebo enrollment:", coef(placebo_enroll)["treated"],
    " SE:", se(placebo_enroll)["treated"], "\n")
cat("Placebo minority %:", coef(placebo_minority)["treated"],
    " SE:", se(placebo_minority)["treated"], "\n")

## ============================
## B. Within-state DDD: Public vs Private in PBF states
## ============================

cat("\n=== WITHIN-STATE DDD ===\n")

ddd_data <- panel |>
  filter(sector %in% c(1, 2), pbf_treated, year >= 2003, year <= 2022) |>
  filter(!is.na(bachelors_total), bachelors_total > 0) |>
  mutate(
    ln_bachelors = log(pmax(bachelors_total, 1)),
    is_public_num = as.integer(is_public),
    post_pbf_num = as.integer(year >= pbf_year),
    ddd_treat = is_public_num * post_pbf_num
  ) |>
  group_by(unitid) |>
  filter(n() >= 10, max(bachelors_total, na.rm = TRUE) >= 50) |>
  ungroup()

ddd_comp <- feols(ln_bachelors ~ ddd_treat + is_public_num:i(year) | unitid + year,
                  data = ddd_data, cluster = ~state)

cat("DDD completions:", coef(ddd_comp)["ddd_treat"],
    " SE:", se(ddd_comp)["ddd_treat"], "\n")

## ============================
## C. Alternative treatment timing: exclude early adopters (2009-2011)
## ============================

cat("\n=== SENSITIVITY: EXCLUDE EARLY ADOPTERS ===\n")

late_data <- twfe_data |>
  filter(first_treat == 0 | first_treat >= 2012)

reg_late_comp <- feols(ln_bachelors ~ treated | unitid + year,
                       data = late_data, cluster = ~state)
reg_late_gr <- feols(grad_rate_150 ~ treated | unitid + year,
                     data = late_data, cluster = ~state)

cat("Late adopters only - completions:", coef(reg_late_comp)["treated"],
    " SE:", se(reg_late_comp)["treated"], "\n")
cat("Late adopters only - grad rate:", coef(reg_late_gr)["treated"],
    " SE:", se(reg_late_gr)["treated"], "\n")

## ============================
## D. Dose-response: PBF share intensity
## ============================

cat("\n=== DOSE-RESPONSE ===\n")

dose_data <- twfe_data |>
  left_join(pbf_states |> select(state, pbf_share_pct), by = "state") |>
  mutate(
    pbf_dose = ifelse(post_pbf, pbf_share_pct / 100, 0),
    pbf_high = ifelse(post_pbf & !is.na(pbf_share_pct) & pbf_share_pct >= 20, 1, 0),
    pbf_low = ifelse(post_pbf & !is.na(pbf_share_pct) & pbf_share_pct < 20, 1, 0)
  )

reg_dose <- feols(ln_bachelors ~ pbf_dose | unitid + year,
                  data = dose_data, cluster = ~state)

reg_hilo <- feols(ln_bachelors ~ pbf_high + pbf_low | unitid + year,
                  data = dose_data, cluster = ~state)

cat("Dose (continuous):", coef(reg_dose)["pbf_dose"],
    " SE:", se(reg_dose)["pbf_dose"], "\n")
cat("High-dose (>=20%):", coef(reg_hilo)["pbf_high"],
    " SE:", se(reg_hilo)["pbf_high"], "\n")
cat("Low-dose (<20%):", coef(reg_hilo)["pbf_low"],
    " SE:", se(reg_hilo)["pbf_low"], "\n")

## ============================
## E. Alternative clustering: state-year
## ============================

cat("\n=== ALTERNATIVE CLUSTERING ===\n")

reg_comp_sy <- feols(ln_bachelors ~ treated | unitid + year,
                     data = twfe_data, cluster = ~state + year)

cat("Two-way clustering (state + year):",
    coef(reg_comp_sy)["treated"], " SE:", se(reg_comp_sy)["treated"], "\n")

## Wild cluster bootstrap skipped (fwildclusterboot not available for this R version)
boot_result <- NULL

## ============================
## Save robustness results
## ============================

save(placebo_comp, placebo_enroll, placebo_minority,
     ddd_comp, reg_late_comp, reg_late_gr,
     reg_dose, reg_hilo,
     reg_comp_sy, boot_result,
     private_data, dose_data,
     file = "../data/robustness_results.RData")
cat("\nSaved robustness results.\n")
