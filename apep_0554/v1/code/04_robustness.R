## ============================================================
## 04_robustness.R — Robustness checks and placebo tests
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

source("00_packages.R")

panel <- fread(file.path(data_dir, "scm_panel.csv"))
kor_ind <- fread(file.path(data_dir, "korea_industry_panel.csv"))

T0 <- 2018

## ============================================================
## 1. PLACEBO-IN-SPACE: Synthetic control for each donor country
## ============================================================

cat("=== Placebo-in-Space Tests ===\n")

## Run SCM for each donor country (permutation test)
## This tests: if we pretend country X was treated in 2018,
## would we see a similar gap?

balanced <- panel[!is.na(mean_weekly_hours) & !is.na(tfr) & year >= 2005 & year <= 2023]
balanced[, unit := as.integer(factor(iso3))]

all_countries <- unique(balanced$iso3)
donor_pool <- setdiff(all_countries, "KOR")

placebo_results <- list()
for (cc in all_countries) {
  cat("  Running placebo for:", cc, "\n")
  cc_unit <- balanced[iso3 == cc, unique(unit)]
  other_units <- balanced[iso3 != cc, unique(unit)]

  tryCatch({
    dp <- dataprep(
      foo = as.data.frame(balanced[, .(unit, year, mean_weekly_hours, gdp_pc)]),
      predictors = "gdp_pc",
      predictors.op = "mean",
      time.predictors.prior = 2005:(T0 - 1),
      dependent = "mean_weekly_hours",
      unit.variable = "unit",
      time.variable = "year",
      treatment.identifier = cc_unit,
      controls.identifier = other_units,
      time.optimize.ssr = 2005:(T0 - 1),
      time.plot = 2005:2023
    )

    s <- synth(dp, optimxmethod = "BFGS")
    actual <- as.numeric(dp$Y1plot)
    synthetic <- as.numeric(dp$Y0plot %*% s$solution.w)
    gap <- actual - synthetic

    pre_mspe <- mean(gap[1:(T0 - 2005)]^2)

    placebo_results[[cc]] <- data.table(
      iso3 = cc,
      year = 2005:2023,
      gap = gap,
      pre_mspe = pre_mspe,
      is_treated = cc == "KOR"
    )
  }, error = function(e) {
    cat("    Failed for", cc, ":", e$message, "\n")
  })
}

if (length(placebo_results) > 0) {
  placebo_all <- rbindlist(placebo_results)

  ## Compute p-value: fraction of placebos with post/pre MSPE ratio >= Korea's
  kor_pre_mspe <- placebo_all[iso3 == "KOR" & year < T0, mean(gap^2)]
  kor_post_mspe <- placebo_all[iso3 == "KOR" & year >= T0, mean(gap^2)]
  kor_ratio <- kor_post_mspe / max(kor_pre_mspe, 1e-10)

  ratios <- placebo_all[, .(pre = mean(gap[year < T0]^2),
                             post = mean(gap[year >= T0]^2)),
                         by = iso3]
  ratios[, ratio := post / pmax(pre, 1e-10)]
  pvalue_hours <- mean(ratios$ratio >= kor_ratio)

  cat(sprintf("\nPlacebo p-value (hours): %.3f (Korea ratio: %.2f)\n",
              pvalue_hours, kor_ratio))
  cat(sprintf("Countries with larger ratio: %d / %d\n",
              sum(ratios$ratio >= kor_ratio), nrow(ratios)))

  fwrite(placebo_all, file.path(data_dir, "placebo_hours_results.csv"))
  fwrite(ratios, file.path(data_dir, "placebo_mspe_ratios.csv"))
}

## ============================================================
## 2. PLACEBO-IN-SPACE for TFR
## ============================================================

cat("\n=== Placebo-in-Space: TFR ===\n")

placebo_tfr <- list()
for (cc in all_countries) {
  cc_unit <- balanced[iso3 == cc, unique(unit)]
  other_units <- balanced[iso3 != cc, unique(unit)]

  tryCatch({
    dp <- dataprep(
      foo = as.data.frame(balanced[, .(unit, year, tfr, gdp_pc)]),
      predictors = "gdp_pc",
      predictors.op = "mean",
      time.predictors.prior = 2005:(T0 - 1),
      dependent = "tfr",
      unit.variable = "unit",
      time.variable = "year",
      treatment.identifier = cc_unit,
      controls.identifier = other_units,
      time.optimize.ssr = 2005:(T0 - 1),
      time.plot = 2005:2023
    )

    s <- synth(dp, optimxmethod = "BFGS")
    gap <- as.numeric(dp$Y1plot) - as.numeric(dp$Y0plot %*% s$solution.w)
    pre_mspe <- mean(gap[1:(T0 - 2005)]^2)

    placebo_tfr[[cc]] <- data.table(
      iso3 = cc, year = 2005:2023, gap = gap,
      pre_mspe = pre_mspe, is_treated = cc == "KOR"
    )
  }, error = function(e) NULL)
}

if (length(placebo_tfr) > 0) {
  placebo_tfr_all <- rbindlist(placebo_tfr)
  fwrite(placebo_tfr_all, file.path(data_dir, "placebo_tfr_results.csv"))

  tfr_ratios <- placebo_tfr_all[, .(pre = mean(gap[year < T0]^2),
                                     post = mean(gap[year >= T0]^2)),
                                 by = iso3]
  tfr_ratios[, ratio := post / pmax(pre, 1e-10)]
  kor_tfr_ratio <- tfr_ratios[iso3 == "KOR", ratio]
  pvalue_tfr <- mean(tfr_ratios$ratio >= kor_tfr_ratio)

  cat(sprintf("Placebo p-value (TFR): %.3f\n", pvalue_tfr))
  fwrite(tfr_ratios, file.path(data_dir, "placebo_tfr_ratios.csv"))
}

## ============================================================
## 3. PLACEBO-IN-TIME: Pretend treatment in 2013 or 2015
## ============================================================

cat("\n=== Placebo-in-Time ===\n")

placebo_time_results <- list()
for (fake_t0 in c(2013, 2015)) {
  cat(sprintf("  Testing placebo treatment in %d...\n", fake_t0))

  tryCatch({
    dp_fake <- dataprep(
      foo = as.data.frame(balanced[year <= 2017, .(unit, year, mean_weekly_hours, gdp_pc)]),
      predictors = "gdp_pc",
      predictors.op = "mean",
      time.predictors.prior = 2005:(fake_t0 - 1),
      dependent = "mean_weekly_hours",
      unit.variable = "unit",
      time.variable = "year",
      treatment.identifier = balanced[iso3 == "KOR", unique(unit)],
      controls.identifier = balanced[iso3 != "KOR", unique(unit)],
      time.optimize.ssr = 2005:(fake_t0 - 1),
      time.plot = 2005:2017
    )

    s_fake <- synth(dp_fake, optimxmethod = "BFGS")
    gap_fake <- as.numeric(dp_fake$Y1plot) - as.numeric(dp_fake$Y0plot %*% s_fake$solution.w)
    pre_mspe <- mean(gap_fake[1:(fake_t0 - 2005)]^2)
    post_mspe <- mean(gap_fake[(fake_t0 - 2005 + 1):length(gap_fake)]^2)
    avg_post_gap <- mean(gap_fake[(fake_t0 - 2005 + 1):length(gap_fake)])
    cat(sprintf("    Placebo %d: pre-MSPE=%.4f post-MSPE=%.4f avg-gap=%.3f\n",
                fake_t0, pre_mspe, post_mspe, avg_post_gap))
    placebo_time_results[[as.character(fake_t0)]] <- data.table(
      fake_treatment_year = fake_t0,
      pre_mspe = pre_mspe,
      post_mspe = post_mspe,
      avg_post_gap = avg_post_gap,
      ratio = post_mspe / max(pre_mspe, 1e-10)
    )
  }, error = function(e) {
    cat(sprintf("    Placebo %d failed: %s\n", fake_t0, e$message))
  })
}

## Save placebo-in-time results
if (length(placebo_time_results) > 0) {
  pit <- rbindlist(placebo_time_results)
  fwrite(pit, file.path(data_dir, "placebo_in_time_results.csv"))
  cat("Placebo-in-time results saved\n")
  print(pit)
}

## ============================================================
## 4. LEAVE-ONE-OUT: Remove each major donor, re-run SCM
## ============================================================

cat("\n=== Leave-One-Out Stability ===\n")

## Identify top donors from main SCM
if (file.exists(file.path(data_dir, "scm_hours_weights.csv"))) {
  top_donors <- fread(file.path(data_dir, "scm_hours_weights.csv"))
  top_donors <- top_donors[weight > 0.05]$iso3
} else {
  ## If weights not available, use top 5 by pre-treatment hours similarity
  kor_pre_hours <- balanced[iso3 == "KOR" & year < T0, mean(mean_weekly_hours)]
  pre_sim <- balanced[iso3 != "KOR" & year < T0,
                      .(diff = abs(mean(mean_weekly_hours, na.rm = TRUE) - kor_pre_hours)),
                      by = iso3]
  top_donors <- pre_sim[order(diff)][1:5]$iso3
}

loo_results <- list()
for (drop in top_donors) {
  cat("  Dropping:", drop, "\n")
  loo_data <- balanced[iso3 != drop]
  loo_data[, unit := as.integer(factor(iso3))]
  kor_u <- loo_data[iso3 == "KOR", unique(unit)]
  other_u <- loo_data[iso3 != "KOR", unique(unit)]

  tryCatch({
    dp_loo <- dataprep(
      foo = as.data.frame(loo_data[, .(unit, year, mean_weekly_hours, gdp_pc)]),
      predictors = "gdp_pc",
      predictors.op = "mean",
      time.predictors.prior = 2005:(T0 - 1),
      dependent = "mean_weekly_hours",
      unit.variable = "unit",
      time.variable = "year",
      treatment.identifier = kor_u,
      controls.identifier = other_u,
      time.optimize.ssr = 2005:(T0 - 1),
      time.plot = 2005:2023
    )

    s_loo <- synth(dp_loo, optimxmethod = "BFGS")
    gap_loo <- as.numeric(dp_loo$Y1plot) - as.numeric(dp_loo$Y0plot %*% s_loo$solution.w)

    loo_results[[drop]] <- data.table(
      dropped = drop, year = 2005:2023, gap = gap_loo
    )
  }, error = function(e) {
    cat("    Failed for", drop, "\n")
  })
}

if (length(loo_results) > 0) {
  loo_all <- rbindlist(loo_results)
  fwrite(loo_all, file.path(data_dir, "loo_hours_results.csv"))
  cat("LOO results saved\n")
}

## ============================================================
## 5. INDUSTRY ROBUSTNESS: Leave-one-industry-out
## ============================================================

cat("\n=== Leave-One-Industry-Out ===\n")

industries <- unique(kor_ind[!is.na(hours) & !is.na(treatment_intensity)]$industry)
kor_ind[, post := as.integer(year >= T0)]

lioo_results <- list()
for (ind in industries) {
  m <- feols(hours ~ treatment_intensity:post | industry + year,
             data = kor_ind[industry != ind & !is.na(hours) & !is.na(treatment_intensity)],
             cluster = ~industry)
  lioo_results[[ind]] <- data.table(
    dropped_industry = ind,
    coef = coef(m)["treatment_intensity:post"],
    se = se(m)["treatment_intensity:post"]
  )
}
lioo <- rbindlist(lioo_results)
cat("Industry sensitivity:\n")
print(lioo)
fwrite(lioo, file.path(data_dir, "leave_one_industry_out.csv"))

## ============================================================
## 6. GENDER HETEROGENEITY
## ============================================================

cat("\n=== Gender Heterogeneity in Hours Reduction ===\n")

kor_hours_raw <- fread(file.path(data_dir, "kor_hours_industry.csv"))
kor_gender <- kor_hours_raw[grepl("^ECO_ISIC4_[A-U]$", classif1) & sex != "SEX_T",
                            .(industry = sub("ECO_ISIC4_", "", classif1),
                              sex = sex,
                              year = as.integer(time),
                              hours = as.numeric(obs_value))]
kor_gender <- kor_gender[!is.na(hours)]

## Use INDUSTRY-LEVEL (not sex-specific) treatment intensity for consistency
## with the main analysis in 03_main_analysis.R
ind_baseline <- kor_gender[year >= 2015 & year <= 2017,
                           .(baseline_hours = mean(hours)),
                           by = industry]
kor_gender <- merge(kor_gender, ind_baseline, by = "industry")
kor_gender[, treatment_intensity := pmax(baseline_hours - 40, 0)]
kor_gender[, post := as.integer(year >= T0)]

## Run SEPARATE regressions by sex
gender_f <- feols(hours ~ treatment_intensity:post | industry + year,
                  data = kor_gender[sex == "SEX_F" & !is.na(hours) & !is.na(treatment_intensity)],
                  cluster = ~industry)
gender_m <- feols(hours ~ treatment_intensity:post | industry + year,
                  data = kor_gender[sex == "SEX_M" & !is.na(hours) & !is.na(treatment_intensity)],
                  cluster = ~industry)
cat("Female-specific industry DiD:\n")
print(summary(gender_f))
cat("Male-specific industry DiD:\n")
print(summary(gender_m))

gender_coefs <- data.table(
  sex = c("Female", "Male"),
  coef = c(coef(gender_f)["treatment_intensity:post"],
           coef(gender_m)["treatment_intensity:post"]),
  se = c(se(gender_f)["treatment_intensity:post"],
         se(gender_m)["treatment_intensity:post"]),
  pvalue = c(pvalue(gender_f)["treatment_intensity:post"],
             pvalue(gender_m)["treatment_intensity:post"]),
  nobs = c(nobs(gender_f), nobs(gender_m)),
  r2 = c(r2(gender_f, "r2"), r2(gender_m, "r2")),
  r2_within = c(r2(gender_f, "wr2"), r2(gender_m, "wr2"))
)
fwrite(gender_coefs, file.path(data_dir, "gender_heterogeneity.csv"))

## Generate gender table with etable
etable(gender_f, gender_m,
       headers = c("Female", "Male"),
       tex = TRUE,
       file = file.path(table_dir, "table5_gender.tex"),
       title = "Gender-Specific Industry-Level Hours Response",
       label = "tab:gender",
       notes = paste("Each column estimates Equation (3) separately by sex.",
                     "Treatment intensity = max(baseline hours - 40, 0),",
                     "computed from 2015-2017 industry-specific averages.",
                     "Standard errors clustered at the industry level.",
                     "Source: ILO ILOSTAT, industry-by-sex hours data for South Korea."))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
