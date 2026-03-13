## 04_robustness.R — Robustness checks and mechanism tests
## apep_0630: Surprise Billing Laws and ED Quality

library(data.table)
library(fixest)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "."
setwd(file.path(script_dir, ".."))

panel <- fread("data/analysis_panel.csv")
results <- readRDS("data/main_results.rds")

# ===================================================================
# 1. Ownership heterogeneity (PE mechanism proxy)
# ===================================================================
cat("=== Ownership Heterogeneity (SA) ===\n")
panel[, cohort := fifelse(G == 0, 10000L, G)]

own_results <- list()
for (own_type in c("For-profit", "Nonprofit", "Government")) {
  sub <- panel[ownership_type == own_type]
  n_tr <- uniqueN(sub[G > 0]$provider_id)
  cat(sprintf("\n%s: %d hospitals, %d treated\n", own_type, uniqueN(sub$provider_id), n_tr))

  if (n_tr >= 10 && uniqueN(sub$meas_year) >= 3) {
    sub[, cohort := fifelse(G == 0, 10000L, G)]
    sa_sub <- tryCatch(
      feols(ed_time ~ sunab(cohort, meas_year) | provider_id + meas_year,
            data = sub, cluster = ~state),
      error = function(e) { cat("  SA error:", conditionMessage(e), "\n"); NULL }
    )
    if (!is.null(sa_sub)) {
      sa_agg <- summary(sa_sub, agg = "ATT")
      ct <- coeftable(sa_agg)
      own_results[[own_type]] <- list(
        coef = ct[1, "Estimate"],
        se = ct[1, "Std. Error"],
        n = nobs(sa_sub),
        n_hosp = uniqueN(sub$provider_id),
        n_treated = n_tr
      )
      cat(sprintf("  SA ATT: %.2f (SE=%.2f)\n", ct[1, "Estimate"], ct[1, "Std. Error"]))
    }
  }
}

# ===================================================================
# 2. Placebo: OP_20 (door-to-diagnostic eval, ED process measure)
# ===================================================================
cat("\n=== Placebo Test: OP_20 ===\n")
tec_full <- fread("data/ed_measures_panel.csv")
tec_full[, provider_id := as.character(provider_id)]

# Parse measurement year
tec_full[, end_date_str := as.character(end_date)]
tec_full[, end_year := as.integer(substr(end_date_str, 1, 4))]
tec_full[is.na(end_year) | end_year < 2000, end_year := as.integer(
  sub(".*/", "", end_date_str[is.na(end_year) | end_year < 2000])
)]
tec_full[is.na(end_year), end_year := release_year - 1L]
tec_full[, meas_year := end_year]

placebo_data <- tec_full[measure_id == "OP_20" & !is.na(score),
                          .(provider_id, state, meas_year, placebo_score = score)]

# Add treatment info
surprise_billing <- data.table(
  state = c("NY", "CT", "FL", "CA", "IL", "MD", "NH", "NJ", "OR"),
  law_year = c(2015L, 2015L, 2016L, 2017L, 2018L, 2018L, 2018L, 2018L, 2018L)
)
placebo_data <- merge(placebo_data, surprise_billing, by = "state", all.x = TRUE)
placebo_data[is.na(law_year), law_year := 0L]
placebo_data[, cohort := fifelse(law_year == 0, 10000L, law_year)]

territories <- c("AS", "GU", "MH", "MP", "PR", "VI", "DC")
placebo_data <- placebo_data[!state %in% territories]

cat(sprintf("OP_20 data: %d obs, %d hospitals, %d treated\n",
            nrow(placebo_data), uniqueN(placebo_data$provider_id),
            uniqueN(placebo_data[law_year > 0]$provider_id)))

if (nrow(placebo_data) > 500 && uniqueN(placebo_data[law_year > 0]$provider_id) >= 20) {
  sa_placebo <- tryCatch(
    feols(placebo_score ~ sunab(cohort, meas_year) | provider_id + meas_year,
          data = placebo_data, cluster = ~state),
    error = function(e) { cat("Placebo SA error:", conditionMessage(e), "\n"); NULL }
  )
  if (!is.null(sa_placebo)) {
    sa_plac_agg <- summary(sa_placebo, agg = "ATT")
    cat("Placebo (OP_20) ATT:\n")
    print(sa_plac_agg)
  }
}

# ===================================================================
# 3. Leave-one-state-out
# ===================================================================
cat("\n=== Leave-One-State-Out ===\n")
treated_states <- unique(panel[G > 0]$state)
loo_results <- data.table()

for (drop_state in treated_states) {
  sub <- panel[state != drop_state]
  twfe_loo <- feols(ed_time ~ treated | provider_id + meas_year,
                    data = sub, cluster = ~state)
  loo_results <- rbind(loo_results, data.table(
    dropped = drop_state,
    coef = coef(twfe_loo)["treated"],
    se = sqrt(vcov(twfe_loo)["treated", "treated"])
  ))
}
cat("Leave-one-out results (TWFE):\n")
print(loo_results)

# ===================================================================
# 4. Save robustness results
# ===================================================================
saveRDS(list(
  ownership = own_results,
  loo = loo_results
), "data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
