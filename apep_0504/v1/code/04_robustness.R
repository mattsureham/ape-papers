## ============================================================
## 04_robustness.R — Robustness checks and diagnostics
## APEP Paper: Does Naming Work?
## ============================================================

source("00_packages.R")
library(fixest)
library(data.table)
library(fwildclusterboot)

data_dir <- "../data/"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, yq := as.Date(yq)]
food_panel <- panel[is_food == TRUE]

## ============================================================
## 1. Pre-trend tests
## ============================================================
cat("\n=== PRE-TREND TESTS ===\n")

food_treated <- food_panel[!is.na(rel_time) & rel_time >= -8]

food_treated[, rel_time_binned := fcase(
  rel_time < -8L, -8L,
  rel_time > 20L, 20L,
  default = rel_time
)]

# Full event study — then test pre-treatment coefficients
m_pretrend <- feols(n_entry ~ i(rel_time_binned, ref = -2) | la_id + time_id,
                    data = food_treated,
                    cluster = ~la_code)

cat("Pre-trend coefficients (pre-period only):\n")
ct <- coeftable(m_pretrend)
pre_rows <- grep("::-[3-8]", rownames(ct))
print(ct[pre_rows, ])

# Joint test of pre-treatment coefficients
if (length(pre_rows) > 1) {
  pre_names <- rownames(ct)[pre_rows]
  pre_test <- wald(m_pretrend, pre_names, print = FALSE)
  cat("\nJoint pre-trend F-test p-value:",
      round(pre_test$p, 4), "\n")
}

## ============================================================
## 2. Wild cluster bootstrap inference
## ============================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

m_main <- feols(n_entry ~ did | la_id + time_id,
                data = food_panel, cluster = ~la_code)

tryCatch({
  set.seed(20240101)
  boot_result <- boottest(
    m_main,
    param = "did",
    clustid = "la_code",
    B = 9999,
    type = "webb"
  )
  cat("Wild cluster bootstrap results (entry ~ did):\n")
  cat("  Point estimate:", round(coef(m_main)["did"], 4), "\n")
  cat("  Bootstrap p-value:", round(boot_result$p_val, 4), "\n")
  cat("  Bootstrap CI:",
      round(boot_result$conf_int[1], 4), "to",
      round(boot_result$conf_int[2], 4), "\n")

  saveRDS(boot_result, file.path(data_dir, "bootstrap_entry.rds"))
}, error = function(e) {
  cat("Wild cluster bootstrap failed:", e$message, "\n")
})

## ============================================================
## 3. Placebo: Non-food businesses
## ============================================================
cat("\n=== PLACEBO: NON-FOOD BUSINESSES ===\n")

nonfood_panel <- panel[is_food == FALSE]
m_placebo_entry <- feols(n_entry ~ did | la_id + time_id,
                         data = nonfood_panel, cluster = ~la_code)
m_placebo_exit <- feols(n_exit_proxy ~ did | la_id + time_id,
                        data = nonfood_panel, cluster = ~la_code)

cat("Placebo (non-food) entry:\n")
etable(m_placebo_entry)
cat("Placebo (non-food) exit proxy:\n")
etable(m_placebo_exit)

## ============================================================
## 4. Border design: Welsh border LAs
## ============================================================
cat("\n=== BORDER DESIGN ===\n")

welsh_border_las <- c("W06000005", "W06000006", "W06000011",
                       "W06000019", "W06000020", "W06000021")

border_panel <- food_panel[
  la_code %in% welsh_border_las |
  (country == "England" & region %in% c("West Midlands", "South West", "North West"))
]

if (nrow(border_panel) > 100) {
  m_border <- feols(n_entry ~ did | la_id + time_id,
                    data = border_panel, cluster = ~la_code)
  cat("Border design (entry):\n")
  etable(m_border)
} else {
  cat("Insufficient border panel data. Skipping.\n")
}

## ============================================================
## 5. Separate cohort estimates
## ============================================================
cat("\n=== COHORT-SPECIFIC ESTIMATES ===\n")

wales_england <- food_panel[country %in% c("Wales", "England")]
m_wales <- feols(n_entry ~ did | la_id + time_id,
                 data = wales_england, cluster = ~la_code)

ni_england <- food_panel[country %in% c("Northern Ireland", "England")]
m_ni <- feols(n_entry ~ did | la_id + time_id,
              data = ni_england, cluster = ~la_code)

cat("Wales-only estimate:\n")
etable(m_wales)
cat("NI-only estimate:\n")
etable(m_ni)

## ============================================================
## 6. Exclude COVID period
## ============================================================
cat("\n=== EXCLUDING COVID ===\n")

no_covid <- food_panel[!(yq >= as.Date("2020-01-01") &
                          yq <= as.Date("2021-07-01"))]
m_nocovid <- feols(n_entry ~ did | la_id + time_id,
                   data = no_covid, cluster = ~la_code)
cat("Excluding COVID period:\n")
etable(m_nocovid)

## ============================================================
## 7. Alternative time windows
## ============================================================
cat("\n=== ALTERNATIVE TIME WINDOWS ===\n")

short_run <- food_panel[yq >= as.Date("2011-10-01") &
                         yq <= as.Date("2015-10-01") &
                         country %in% c("Wales", "England")]
m_short <- feols(n_entry ~ did | la_id + time_id,
                 data = short_run, cluster = ~la_code)
cat("Short-run (2yr pre/post):\n")
etable(m_short)

m_long <- feols(n_entry ~ did | la_id + time_id,
                data = food_panel, cluster = ~la_code)
cat("Long-run (full sample):\n")
etable(m_long)

## ============================================================
## 8. HonestDiD sensitivity
## ============================================================
cat("\n=== HONESTDID SENSITIVITY ===\n")

tryCatch({
  library(HonestDiD)

  food_treated_es <- food_panel[!is.na(rel_time) &
                                 rel_time >= -8 & rel_time <= 20]
  m_honest <- feols(n_entry ~ i(rel_time, ref = -2) | la_id + time_id,
                    data = food_treated_es, cluster = ~la_code)

  betahat <- coef(m_honest)
  sigma <- vcov(m_honest)

  es_names <- grep("rel_time", names(betahat), value = TRUE)
  betahat <- betahat[es_names]
  sigma <- sigma[es_names, es_names]

  pre_idx <- grep("::-", es_names)
  post_idx <- grep("::[0-9]", es_names)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    honest_result <- createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("HonestDiD sensitivity analysis:\n")
    print(honest_result)
    saveRDS(honest_result, file.path(data_dir, "honestdid_results.rds"))
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
})

## ============================================================
## 9. Save all robustness results
## ============================================================
cat("\n=== SAVING ROBUSTNESS RESULTS ===\n")

robustness <- list(
  placebo_entry = m_placebo_entry,
  placebo_exit = m_placebo_exit,
  wales_only = m_wales,
  ni_only = m_ni,
  no_covid = m_nocovid,
  short_run = m_short,
  long_run = m_long
)

if (exists("m_border")) robustness$border <- m_border

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("Robustness checks complete.\n")
