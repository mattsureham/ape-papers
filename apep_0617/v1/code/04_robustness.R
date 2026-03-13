## 04_robustness.R — Robustness checks
## Wild cluster bootstrap, dose-response, manufacturing placebo

source("00_packages.R")

panel <- fread("../data/panel_main.csv")
df_triple <- fread("../data/panel_triple.csv")
load("../data/analysis_results.RData")

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# A. Dose-response: EITC generosity (credit %)
# ============================================================
cat("\n--- Dose-response: EITC credit percentage ---\n")

panel[, eitc_intensity := fifelse(eitc_adopt_year > 0 & year >= eitc_adopt_year,
                                  eitc_pct, 0)]

dose_health <- feols(share_62 ~ eitc_intensity | statefip + year,
                     data = panel, cluster = ~statefip)

dose_food <- feols(share_72 ~ eitc_intensity | statefip + year,
                   data = panel, cluster = ~statefip)

cat("Dose-response results:\n")
etable(dose_health, dose_food)

# ============================================================
# B. Refundable vs non-refundable
# ============================================================
cat("\n--- Refundable vs non-refundable EITCs ---\n")

panel[, treated_refundable := as.integer(treated == 1 & refundable == 1)]
panel[, treated_nonrefund := as.integer(treated == 1 & refundable == 0)]

refund_health <- feols(share_62 ~ treated_refundable + treated_nonrefund |
                       statefip + year, data = panel, cluster = ~statefip)

refund_food <- feols(share_72 ~ treated_refundable + treated_nonrefund |
                     statefip + year, data = panel, cluster = ~statefip)

cat("Refundable/Non-refundable results:\n")
etable(refund_health, refund_food)

# ============================================================
# C. Manufacturing placebo (not directly affected by EITC)
# ============================================================
cat("\n--- Manufacturing placebo (sector 31-33) ---\n")

twfe_mfg <- feols(share_3133 ~ treated | statefip + year,
                  data = panel, cluster = ~statefip)
cat("Manufacturing share (placebo):\n")
etable(twfe_mfg)

# ============================================================
# D. Admin/support services (56) — low-wage, service-sector control
# ============================================================
cat("\n--- Admin/support services (sector 56) ---\n")

twfe_admin <- feols(share_56 ~ treated | statefip + year,
                    data = panel, cluster = ~statefip)
cat("Admin services share:\n")
etable(twfe_admin)

# ============================================================
# E. Earnings outcomes (log average earnings by sector)
# ============================================================
cat("\n--- Earnings outcomes ---\n")

# Log earnings
panel[, log_earn_62 := log(pmax(earn_62, 1))]
panel[, log_earn_72 := log(pmax(earn_72, 1))]

twfe_earn_health <- feols(log_earn_62 ~ treated | statefip + year,
                          data = panel[is.finite(log_earn_62)],
                          cluster = ~statefip)
twfe_earn_food <- feols(log_earn_72 ~ treated | statefip + year,
                        data = panel[is.finite(log_earn_72)],
                        cluster = ~statefip)

cat("Log earnings results:\n")
etable(twfe_earn_health, twfe_earn_food)

# ============================================================
# F. Restrict to post-2001 adopters only
# ============================================================
cat("\n--- Post-2001 adopters only ---\n")

# Keep only states where eitc_adopt_year == 0 (never) or >= 2002
panel_post2001 <- panel[eitc_adopt_year == 0 | eitc_adopt_year >= 2002]

twfe_post_health <- feols(share_62 ~ treated | statefip + year,
                          data = panel_post2001, cluster = ~statefip)
twfe_post_food <- feols(share_72 ~ treated | statefip + year,
                        data = panel_post2001, cluster = ~statefip)

cat("Post-2001 only:\n")
etable(twfe_post_health, twfe_post_food)

# ============================================================
# G. Drop Great Recession years (2008-2010)
# ============================================================
cat("\n--- Exclude Great Recession (2008-2010) ---\n")

panel_norec <- panel[!(year %in% 2008:2010)]

twfe_norec_health <- feols(share_62 ~ treated | statefip + year,
                           data = panel_norec, cluster = ~statefip)
twfe_norec_food <- feols(share_72 ~ treated | statefip + year,
                         data = panel_norec, cluster = ~statefip)

cat("Excluding recession:\n")
etable(twfe_norec_health, twfe_norec_food)

# ============================================================
# Save robustness results
# ============================================================
save(dose_health, dose_food,
     refund_health, refund_food,
     twfe_mfg, twfe_admin,
     twfe_earn_health, twfe_earn_food,
     twfe_post_health, twfe_post_food,
     twfe_norec_health, twfe_norec_food,
     file = "../data/robustness_results.RData")

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
