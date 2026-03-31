# 04_robustness.R — Robustness checks for DDD

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, asian_cf := as.integer(race == "A4") * as.integer(sector_type == "customer_facing")]
results <- readRDS("../data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ── 1. Wild Cluster Bootstrap ──
cat("── 1. Wild Cluster Bootstrap ──\n")

boot_result <- tryCatch({
  boottest(results$m1,
           param = "asian:customer_facing:post_covid",
           B = 999,
           clustid = ~state_fips,
           type = "mammen")
}, error = function(e) {
  cat(sprintf("  Bootstrap error: %s\n", e$message))
  NULL
})

if (!is.null(boot_result)) {
  cat(sprintf("  Bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("  Bootstrap CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
}

# ── 2. Placebo: Fake treatment at 2018Q1 (pre-COVID only) ──
cat("\n── 2. Placebo test ──\n")

panel[, fake_post := as.integer(yrqtr >= 2018.0)]
panel_pre <- panel[yrqtr < 2020]

m_placebo <- feols(log_emp ~ asian_cf:fake_post |
                     state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                   data = panel_pre, cluster = ~state_fips)

cat("Placebo (fake treatment at 2018Q1, pre-COVID only):\n")
print(summary(m_placebo))

# ── 3. Exclude top-3 Asian population states ──
cat("\n── 3. Exclude CA, NY, HI ──\n")

panel_excl <- panel[!state_fips %in% c("06", "36", "15")]

m_excl <- feols(log_emp ~ asian_cf:post_covid |
                  state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                data = panel_excl, cluster = ~state_fips)

print(summary(m_excl))

# ── 4. Level specification ──
cat("\n── 4. Level specification ──\n")

m_level <- feols(emp ~ asian_cf:post_covid |
                   state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                 data = panel, cluster = ~state_fips)

print(summary(m_level))

# ── 5. Persistence: Early vs Late post-COVID ──
cat("\n── 5. Persistence ──\n")

panel[, early_post := as.integer(yrqtr >= 2020 & yrqtr < 2022)]
panel[, late_post := as.integer(yrqtr >= 2022)]

m_persist <- feols(log_emp ~ asian_cf:early_post + asian_cf:late_post |
                     state_fips^yrqtr + race^sector_type + state_fips^sector_type + race^yrqtr,
                   data = panel, cluster = ~state_fips)

print(summary(m_persist))

# ── 6. Individual sector breakdown ──
cat("\n── 6. Sector breakdown ──\n")

qwi <- fread("../data/qwi_state_race_industry.csv")
qwi[, state_fips := sprintf("%02d", as.integer(state_fips))]
qwi[, yrqtr := year + (quarter - 1) / 4]
qwi[, asian := as.integer(race == "A4")]
qwi[, post_covid := as.integer(yrqtr >= 2020)]
qwi[, log_emp := log(emp + 1)]

for (ind in c("72", "44-45", "54", "51")) {
  cat(sprintf("\n  NAICS %s:\n", ind))
  m_ind <- feols(log_emp ~ asian:post_covid |
                   state_fips + yrqtr,
                 data = qwi[industry == ind], cluster = ~state_fips)
  ct <- coeftable(m_ind)
  idx <- grep("asian.*post_covid", rownames(ct))
  if (length(idx) > 0) {
    cat(sprintf("    Coef: %.4f, SE: %.4f, p: %.4f\n",
                ct[idx, 1], ct[idx, 2], ct[idx, 4]))
  }
}

# ── Save ──
rob_results <- list(
  boot_result = boot_result,
  m_placebo = m_placebo,
  m_excl = m_excl,
  m_level = m_level,
  m_persist = m_persist
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
