## 04_robustness.R — Event study, placebos, and robustness checks
source("00_packages.R")

panel <- fread("../data/panel.csv")
panel[, yearmonth := factor(paste0(year, "-", sprintf("%02d", month)))]

## ---- Event study: quarter-level interactions ----
# Create relative quarter variable (relative to 2017-Q1)
panel[, quarter := ceiling(month / 3)]
panel[, rel_qtr := (year - 2017) * 4 + quarter - 1]  # 2017-Q1 = 0

# Collapse to agency-quarter for cleaner event study
qpanel <- panel[, .(log_nprm = log(sum(n_nprm) + 1),
                     log_rule = log(sum(n_rule) + 1),
                     log_total = log(sum(n_nprm + n_rule) + 1),
                     share_econ_sig = first(share_econ_sig),
                     post_eo = max(post_eo),
                     post_rescission = max(post_rescission)),
                 by = .(agency_id, year, quarter, rel_qtr)]
qpanel[, yearqtr := factor(paste0(year, "-Q", quarter))]

# Event study: share_econ_sig × relative quarter
# Reference: 2016-Q4 (rel_qtr = -1)
es <- feols(log_nprm ~ i(rel_qtr, share_econ_sig, ref = -1) |
              agency_id + yearqtr, data = qpanel, cluster = ~agency_id)
cat("Event study (NPRM volume, quarterly):\n")
summary(es)

es_coefs <- as.data.table(coeftable(es), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
fwrite(es_coefs, "../data/event_study_coefs.csv")

## ---- Placebo: fake treatment at 2013 ----
panel[, post_placebo := as.integer(year > 2013 | (year == 2013 & month >= 2))]
panel[, post_placebo_x_intensity := post_placebo * share_econ_sig]
panel_pre <- panel[year < 2017]

placebo_m1 <- feols(log_nprm ~ post_placebo_x_intensity |
                      agency_id + yearmonth, data = panel_pre, cluster = ~agency_id)
cat("\nPlacebo (fake 2013 treatment):\n")
summary(placebo_m1)

## ---- Leave-one-out: exclude EPA ----
panel_no_epa <- panel[agency_id != "EPA"]
loo_m1 <- feols(log_nprm ~ post_eo_x_intensity + post_rescission_x_intensity |
                  agency_id + yearmonth, data = panel_no_epa, cluster = ~agency_id)
cat("\nLeave-one-out (no EPA) NPRM:\n")
summary(loo_m1)

## ---- Leave-one-out: exclude FAA ----
panel_no_faa <- panel[agency_id != "FAA"]
loo_m2 <- feols(log_nprm ~ post_eo_x_intensity + post_rescission_x_intensity |
                  agency_id + yearmonth, data = panel_no_faa, cluster = ~agency_id)
cat("\nLeave-one-out (no FAA) NPRM:\n")
summary(loo_m2)

## ---- Binary treatment: top-quartile vs bottom-quartile ----
q75 <- quantile(panel$share_econ_sig, 0.75, na.rm = TRUE)
q25 <- quantile(panel$share_econ_sig, 0.25, na.rm = TRUE)
panel[, high_intensity := as.integer(share_econ_sig >= q75)]
panel[, low_intensity := as.integer(share_econ_sig <= q25)]
panel_binary <- panel[high_intensity == 1 | low_intensity == 1]
panel_binary[, post_eo_x_high := post_eo * high_intensity]
panel_binary[, post_rescission_x_high := post_rescission * high_intensity]

bin_m1 <- feols(log_nprm ~ post_eo_x_high + post_rescission_x_high |
                  agency_id + yearmonth, data = panel_binary, cluster = ~agency_id)
cat("\nBinary treatment (Q4 vs Q1):\n")
summary(bin_m1)

## ---- Save robustness results ----
rob_results <- list(
  event_study = es,
  es_coefs = es_coefs,
  placebo = placebo_m1,
  loo_epa = loo_m1,
  loo_faa = loo_m2,
  binary = bin_m1
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
