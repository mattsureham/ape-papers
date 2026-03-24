## 04_robustness.R — apep_0850
## Robustness checks for Geneva minimum wage DDD

source("00_packages.R")

panel <- readRDS("../data/analysis_panel_fr.rds")
panel_ti <- readRDS("../data/analysis_panel_ti.rds")

ddd_panel <- panel[bite %in% c("high", "low")]
ddd_panel[, ge_hb := as.integer(canton == 25) * as.integer(bite == "high")]

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. PLACEBO CANTON: Vaud as if treated
# ============================================================

ddd_panel[, vaud := as.integer(canton == 22)]
ddd_panel[, vaud_hb := vaud * as.integer(bite == "high")]

r1_placebo_canton <- feols(
  log_cbw ~ vaud:I(bite == "high"):post |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel[canton != 25],  # Exclude Geneva
  cluster = ~canton_sector
)

cat("--- R1: Placebo canton (Vaud as treated, Geneva excluded) ---\n")
summary(r1_placebo_canton)

# ============================================================
# 2. PLACEBO TIMING: False treatment at Q4 2018
# ============================================================

ddd_panel[, post_placebo_2018 := as.integer(time_q >= 2018.75)]

r2_placebo_time <- feols(
  log_cbw ~ ge_hb:post_placebo_2018 |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel[time_q < 2020.75],  # Only pre-treatment data
  cluster = ~canton_sector
)

cat("\n--- R2: Placebo timing (false treatment Q4 2018, pre-treatment data only) ---\n")
summary(r2_placebo_time)

# ============================================================
# 3. CLEAN PRE-PERIOD: 2015-2019 only (post-franc-shock, pre-COVID)
# ============================================================

r3_clean_pre <- feols(
  log_cbw ~ ge_hb:post |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel[year >= 2015],
  cluster = ~canton_sector
)

cat("\n--- R3: Clean pre-period (2015 onward, post-franc-shock) ---\n")
summary(r3_clean_pre)

# ============================================================
# 4. ASINH TRANSFORMATION (instead of log)
# ============================================================

ddd_panel[, asinh_cbw := asinh(cbw)]

r4_asinh <- feols(
  asinh_cbw ~ ge_hb:post |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel,
  cluster = ~canton_sector
)

cat("\n--- R4: Inverse hyperbolic sine transformation ---\n")
summary(r4_asinh)

# ============================================================
# 5. POISSON QUASI-MLE (count data)
# ============================================================

r5_poisson <- fepois(
  cbw ~ ge_hb:post |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel[cbw > 0],
  cluster = ~canton_sector
)

cat("\n--- R5: Poisson QMLE ---\n")
summary(r5_poisson)

# ============================================================
# 6. CONTINUOUS BITE MEASURE
# ============================================================

# Approximate sector-level bite from 2018 LSE
bite_continuous <- data.table(
  noga = c(55, 56, 47, 96, 81, 78, 93,   # high bite
           64, 65, 21, 26, 62, 69, 71, 72),  # low bite
  bite_frac = c(0.35, 0.38, 0.22, 0.30, 0.25, 0.20, 0.28,  # high
                0.03, 0.02, 0.01, 0.04, 0.02, 0.04, 0.03, 0.01) # low
)

ddd_panel_cont <- merge(ddd_panel, bite_continuous, by = "noga", all.x = TRUE)
ddd_panel_cont[, ge_bite := as.integer(canton == 25) * bite_frac]

r6_continuous <- feols(
  log_cbw ~ ge_bite:post |
    canton_sector + sector_quarter + canton_quarter,
  data = ddd_panel_cont[!is.na(bite_frac)],
  cluster = ~canton_sector
)

cat("\n--- R6: Continuous bite measure ---\n")
summary(r6_continuous)

# ============================================================
# 7. TICINO REPLICATION (Italy-origin CBW, CHF 19/hr, April 2021)
# ============================================================

panel_ti[, high_bite := as.integer(bite == "high")]
panel_ti[, log_cbw := log(cbw + 1)]
panel_ti[, t := as.integer(factor(TIME_PERIOD))]

# Treatment: Q2 2021
ti_treatment_q <- panel_ti[TIME_PERIOD == "2021-Q2", unique(t)]
panel_ti[, post_ti := as.integer(t >= ti_treatment_q)]

ti_panel <- panel_ti[bite %in% c("high", "low")]

r7_ticino <- feols(
  log_cbw ~ high_bite:post_ti | noga + t,
  data = ti_panel,
  cluster = ~noga
)

cat("\n--- R7: Ticino replication (CHF 19/hr, April 2021) ---\n")
summary(r7_ticino)

# ============================================================
# 8. LEAVE-ONE-SECTOR-OUT
# ============================================================

cat("\n--- R8: Leave-one-sector-out (high-bite sectors) ---\n")
high_sectors <- c(55, 56, 47, 96, 81, 78, 93)
loso_results <- data.table()

for (drop_s in high_sectors) {
  loso_data <- ddd_panel[noga != drop_s]
  m_loso <- feols(
    log_cbw ~ ge_hb:post |
      canton_sector + sector_quarter + canton_quarter,
    data = loso_data,
    cluster = ~canton_sector
  )
  loso_results <- rbind(loso_results, data.table(
    dropped_sector = drop_s,
    coef = coef(m_loso)["ge_hb:post"],
    se = se(m_loso)["ge_hb:post"]
  ))
}

print(loso_results)
cat(sprintf("LOSO range: [%.4f, %.4f]\n",
            min(loso_results$coef), max(loso_results$coef)))

# ============================================================
# 9. WILD CLUSTER BOOTSTRAP (canton level)
# ============================================================

cat("\n--- R9: Wild cluster bootstrap (canton level) ---\n")

# Simple OLS version for bootstrap (fixest not directly supported by fwildclusterboot)
# Use the within-transformed data approach
ddd_panel[, ge_hb_post := ge_hb * post]

# Run a simpler model that fwildclusterboot can handle
m_for_boot <- feols(
  log_cbw ~ ge_hb_post | canton_sector + t,
  data = ddd_panel,
  cluster = ~canton
)

cat("Main estimate (canton-clustered): ")
cat(sprintf("%.4f (SE: %.4f, p: %.4f)\n",
            coef(m_for_boot)["ge_hb_post"],
            se(m_for_boot)["ge_hb_post"],
            pvalue(m_for_boot)["ge_hb_post"]))

tryCatch({
  boot_result <- boottest(
    m_for_boot,
    param = "ge_hb_post",
    clustid = ~canton,
    B = 999,
    type = "webb"
  )
  cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("Wild bootstrap 95%% CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
}, error = function(e) {
  cat(sprintf("Bootstrap failed: %s\n", e$message))
  cat("Note: With only 5 cantons, wild cluster bootstrap has limited power.\n")
})

# ============================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================

rob_results <- list(
  r1_placebo_canton = r1_placebo_canton,
  r2_placebo_time = r2_placebo_time,
  r3_clean_pre = r3_clean_pre,
  r4_asinh = r4_asinh,
  r5_poisson = r5_poisson,
  r6_continuous = r6_continuous,
  r7_ticino = r7_ticino,
  loso_results = loso_results
)

saveRDS(rob_results, "../data/robustness_models.rds")

cat("\n=== Robustness checks complete ===\n")
