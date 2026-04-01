## 04_robustness.R — Robustness checks and placebo tests
## Double-difference design: Small Firm × Post

library(data.table)
library(fixest)
library(tidyverse)
library(jsonlite)

DATA_DIR <- file.path(dirname(getwd()), "data")

geih <- readRDS(file.path(DATA_DIR, "geih_analytic.rds"))
geih[, written := as.integer(p6450 == 2)]
geih[, pension := as.integer(p6920 == 1)]

# ---- Robustness 1: Very small firms (≤5) vs medium ----
cat("\n=== ROBUSTNESS 1: VERY SMALL FIRMS ===\n")

geih[, very_small := as.integer(firmsize_cat %in% 1:3)]  # ≤5 employees

rob_vsmall <- feols(benefit_index ~ very_small:post + very_small + post +
                      age + I(age^2) + female + factor(educ_level) |
                      city + year_quarter,
                    data = geih[!is.na(benefit_index) & !is.na(educ_level) &
                                  (very_small == 1 | medium_firm == 1)],
                    cluster = ~city)

cat(sprintf("  Very small (≤5) vs medium: %.4f (%.4f)\n",
            coef(rob_vsmall)["very_small:post"], se(rob_vsmall)["very_small:post"]))

# ---- Robustness 2: Alternative comparison — include large firms ----
cat("\n=== ROBUSTNESS 2: SMALL VS LARGE (>50) ===\n")

# Re-read full data without small/medium restriction
geih_full <- fread(file.path(DATA_DIR, "geih_combined_2011_2016.csv"))
names(geih_full) <- tolower(names(geih_full))
geih_full[, age := as.numeric(p6040)]
geih_full[, female := as.integer(p6020 == 2)]
geih_full[, educ_level := as.numeric(p6210)]
geih_full[educ_level == 9, educ_level := NA]
geih_full[, earnings := as.numeric(p6500)]
geih_full[earnings == 98 | earnings == 99, earnings := NA]
geih_full[, firmsize_cat := as.numeric(p6870)]
geih_full[, small_firm := as.integer(firmsize_cat %in% 1:4)]
geih_full[, large_firm := as.integer(firmsize_cat %in% 8:9)]
geih_full[, post := as.integer(year >= 2013)]
geih_full[, quarter := ceiling(month / 3)]
geih_full[, year_quarter := paste0(year, "Q", quarter)]
geih_full[, city := as.factor(area)]
geih_full[, benefit_vacation := as.integer(p6424s1 == 1)]
geih_full[, benefit_prima_nav := as.integer(p6424s2 == 1)]
geih_full[, benefit_cesantias := as.integer(p6424s3 == 1)]
geih_full[, benefit_pension := as.integer(p6920 == 1)]
geih_full[, benefit_index := rowSums(cbind(benefit_vacation, benefit_prima_nav,
                                            benefit_cesantias, benefit_pension), na.rm = FALSE)]

# Small vs large (skip medium)
geih_sl <- geih_full[p6430 %in% c(1, 2) & age >= 18 & age <= 65 &
                       !is.na(earnings) & earnings > 0 &
                       (small_firm == 1 | large_firm == 1)]

rob_large <- feols(benefit_index ~ small_firm:post + small_firm + post +
                     age + I(age^2) + female + factor(educ_level) |
                     city + year_quarter,
                   data = geih_sl[!is.na(benefit_index) & !is.na(educ_level)],
                   cluster = ~city)

cat(sprintf("  Small vs large (>50): %.4f (%.4f), N=%s\n",
            coef(rob_large)["small_firm:post"], se(rob_large)["small_firm:post"],
            format(nobs(rob_large), big.mark = ",")))

# ---- Robustness 3: Sector fixed effects ----
cat("\n=== ROBUSTNESS 3: SECTOR FIXED EFFECTS ===\n")

geih[, sector := as.numeric(rama2d)]
rob_sector <- feols(benefit_index ~ small_firm:post + small_firm + post +
                      age + I(age^2) + female + factor(educ_level) |
                      city + year_quarter + sector,
                    data = geih[!is.na(benefit_index) & !is.na(educ_level) & !is.na(sector)],
                    cluster = ~city)

cat(sprintf("  With sector FE: %.4f (%.4f)\n",
            coef(rob_sector)["small_firm:post"], se(rob_sector)["small_firm:post"]))

# ---- Placebo 1: Government workers ----
cat("\n=== PLACEBO 1: GOVERNMENT WORKERS ===\n")

geih_govt <- geih[p6430 == 2]
if (nrow(geih_govt[!is.na(benefit_index)]) > 500) {
  placebo_govt <- feols(benefit_index ~ small_firm:post + small_firm + post +
                          age + I(age^2) + female |
                          city + year_quarter,
                        data = geih_govt[!is.na(benefit_index)],
                        cluster = ~city)
  cat(sprintf("  Gov workers DiD: %.4f (%.4f), N=%s\n",
              coef(placebo_govt)["small_firm:post"], se(placebo_govt)["small_firm:post"],
              format(nobs(placebo_govt), big.mark = ",")))
} else {
  cat("  Too few government workers for placebo\n")
  placebo_govt <- NULL
}

# ---- Placebo 2: Fake treatment year (2011 in pre-reform period) ----
cat("\n=== PLACEBO 2: FAKE TREATMENT YEAR (2011) ===\n")

geih_pre <- geih[year <= 2012]
geih_pre[, fake_post := as.integer(year >= 2012)]

placebo_time <- feols(benefit_index ~ small_firm:fake_post + small_firm + fake_post +
                        age + I(age^2) + female |
                        city + year_quarter,
                      data = geih_pre[!is.na(benefit_index)],
                      cluster = ~city)

cat(sprintf("  Fake 2012 DiD: %.4f (%.4f)\n",
            coef(placebo_time)["small_firm:fake_post"],
            se(placebo_time)["small_firm:fake_post"]))

# ---- Robustness 4: Written contract workers only ----
cat("\n=== ROBUSTNESS 4: WRITTEN CONTRACT SUBSAMPLE ===\n")

geih[, written := as.integer(p6450 == 2)]
geih_written <- geih[written == 1]

rob_written <- feols(benefit_index ~ small_firm:post + small_firm + post +
                       age + I(age^2) + female + factor(educ_level) |
                       city + year_quarter,
                     data = geih_written[!is.na(benefit_index) & !is.na(educ_level)],
                     cluster = ~city)

cat(sprintf("  Written contract only: %.4f (%.4f), N=%s\n",
            coef(rob_written)["small_firm:post"], se(rob_written)["small_firm:post"],
            format(nobs(rob_written), big.mark = ",")))

# ---- Save robustness models ----
save(rob_vsmall, rob_large, rob_sector,
     placebo_govt, placebo_time, rob_written,
     file = file.path(DATA_DIR, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
