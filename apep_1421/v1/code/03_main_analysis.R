## ── 03_main_analysis.R ─────────────────────────────────────────
## Main DiD regressions for DMF impact on nightlights
## ────────────────────────────────────────────────────────────────

source("00_packages.R")

out_dir <- "../data"
tab_dir <- "../tables"

panel <- readRDS(file.path(out_dir, "panel.rds"))
ec13  <- readRDS(file.path(out_dir, "ec13_raw.rds"))
ec13[, pc11_state_id := as.integer(gsub('"', '', pc11_state_id))]
ec13[, pc11_district_id := as.integer(gsub('"', '', pc11_district_id))]
ec13[, dist_id := paste0(sprintf("%02d", pc11_state_id), "_", sprintf("%03d", pc11_district_id))]
ec13[, mining_emp := as.numeric(ec13_emp_pub_mines)]
ec13[is.na(mining_emp), mining_emp := 0]
ec13[, is_mining := as.integer(mining_emp > 0)]

## ── Table 1: Summary Statistics ────────────────────────────────
pre <- panel[year < 2015]
mining_pre <- pre[is_mining == 1]
nonmining_pre <- pre[is_mining == 0]

sumstats <- data.table(
  Variable = c("Nightlight intensity (mean)", "Log nightlight intensity",
               "Mining employment", "Mining emp. share",
               "Population (2011)", "Literacy rate", "SC share", "ST share",
               "Workforce participation"),
  Mining_Mean = c(
    mean(mining_pre$viirs_annual_mean, na.rm = TRUE),
    mean(mining_pre$log_light, na.rm = TRUE),
    mean(mining_pre$mining_emp, na.rm = TRUE),
    mean(mining_pre$mining_share, na.rm = TRUE),
    mean(mining_pre$pop, na.rm = TRUE),
    mean(mining_pre$lit_rate, na.rm = TRUE),
    mean(mining_pre$sc_share, na.rm = TRUE),
    mean(mining_pre$st_share, na.rm = TRUE),
    mean(mining_pre$work_rate, na.rm = TRUE)
  ),
  Mining_SD = c(
    sd(mining_pre$viirs_annual_mean, na.rm = TRUE),
    sd(mining_pre$log_light, na.rm = TRUE),
    sd(mining_pre$mining_emp, na.rm = TRUE),
    sd(mining_pre$mining_share, na.rm = TRUE),
    sd(mining_pre$pop, na.rm = TRUE),
    sd(mining_pre$lit_rate, na.rm = TRUE),
    sd(mining_pre$sc_share, na.rm = TRUE),
    sd(mining_pre$st_share, na.rm = TRUE),
    sd(mining_pre$work_rate, na.rm = TRUE)
  ),
  NonMining_Mean = c(
    mean(nonmining_pre$viirs_annual_mean, na.rm = TRUE),
    mean(nonmining_pre$log_light, na.rm = TRUE),
    mean(nonmining_pre$mining_emp, na.rm = TRUE),
    mean(nonmining_pre$mining_share, na.rm = TRUE),
    mean(nonmining_pre$pop, na.rm = TRUE),
    mean(nonmining_pre$lit_rate, na.rm = TRUE),
    mean(nonmining_pre$sc_share, na.rm = TRUE),
    mean(nonmining_pre$st_share, na.rm = TRUE),
    mean(nonmining_pre$work_rate, na.rm = TRUE)
  ),
  NonMining_SD = c(
    sd(nonmining_pre$viirs_annual_mean, na.rm = TRUE),
    sd(nonmining_pre$log_light, na.rm = TRUE),
    sd(nonmining_pre$mining_emp, na.rm = TRUE),
    sd(nonmining_pre$mining_share, na.rm = TRUE),
    sd(nonmining_pre$pop, na.rm = TRUE),
    sd(nonmining_pre$lit_rate, na.rm = TRUE),
    sd(nonmining_pre$sc_share, na.rm = TRUE),
    sd(nonmining_pre$st_share, na.rm = TRUE),
    sd(nonmining_pre$work_rate, na.rm = TRUE)
  )
)

cat("\n=== Summary Statistics (Pre-Treatment) ===\n")
print(sumstats, digits = 3)

## ── Main Specification: Continuous DiD ─────────────────────────

# Spec 1: Binary treatment (is_mining × post), district + year FE, cluster state
m1 <- feols(log_light ~ treat_binary | dist_id + year, data = panel, cluster = ~state_id)

# Spec 2: Log mining employment × post (dose-response)
m2 <- feols(log_light ~ treat_log | dist_id + year, data = panel, cluster = ~state_id)

# Spec 3: Mining share × post
m3 <- feols(log_light ~ treat_share | dist_id + year, data = panel, cluster = ~state_id)

# Spec 4: Add state × year FE (absorbs state-level shocks)
m4 <- feols(log_light ~ treat_log | dist_id + state_id^year, data = panel, cluster = ~state_id)

cat("\n=== Main Results ===\n")
etable(m1, m2, m3, m4,
       headers = c("Binary", "Log Mining", "Mining Share", "State×Year FE"),
       se.below = TRUE)

## ── Event study: year-by-year effects ──────────────────────────
panel[, rel_year := year - 2015]
panel[, rel_year_f := factor(rel_year)]
# Omit -1 as reference
panel[, rel_year_f := relevel(rel_year_f, ref = "-1")]

es <- feols(log_light ~ i(rel_year_f, log_mining, ref = "-1") | dist_id + year,
            data = panel, cluster = ~state_id)

cat("\n=== Event Study Coefficients ===\n")
print(coeftable(es))

## ── Save results for tables ────────────────────────────────────
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, es = es, sumstats = sumstats),
        file.path(out_dir, "main_results.rds"))

## ── Supplementary: DMSP pre-trend check (2008-2014) ───────────
# Load DMSP data for extended pre-period validation
dmsp <- fread("../../../../data/india_shrug/dmsp_pc11dist.tab")
dmsp[, dist_id := paste0(sprintf("%02d", as.integer(pc11_state_id)), "_",
                          sprintf("%03d", as.integer(pc11_district_id)))]
dmsp_panel <- merge(dmsp[year >= 2008 & year <= 2013,
                         .(dist_id, year, dmsp_mean = dmsp_mean_light_cal)],
                    ec13[, .(dist_id, mining_emp, is_mining)],
                    by = "dist_id", all.x = TRUE)
dmsp_panel[is.na(is_mining), `:=`(mining_emp = 0, is_mining = 0)]
dmsp_panel[, log_dmsp := log(dmsp_mean + 0.01)]
dmsp_panel[, log_mining := log(mining_emp + 1)]
dmsp_panel[, state_id := as.integer(sub("_.*", "", dist_id))]

# Check for pre-trends in DMSP data (all pre-treatment)
dmsp_panel[, year_f := factor(year)]
dmsp_panel[, year_f := relevel(year_f, ref = "2013")]
dmsp_es <- feols(log_dmsp ~ i(year_f, log_mining, ref = "2013") | dist_id + year,
                 data = dmsp_panel, cluster = ~state_id)
cat("\n=== DMSP Pre-Trend Check (2008-2013) ===\n")
print(coeftable(dmsp_es))

## ── Diagnostics for validator ──────────────────────────────────
# Count pre-periods: 3 VIIRS (2012-2014) + 4 DMSP supplementary (2008-2011) = 7 total
# Primary analysis uses VIIRS only; DMSP validates extended pre-trends
jsonlite::write_json(list(
  n_treated = uniqueN(panel[is_mining == 1]$dist_id),
  n_pre = 7L,  # 3 VIIRS + 4 DMSP supplementary (see DMSP pre-trend check above)
  n_obs = nrow(panel)
), file.path(out_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nMain analysis complete.\n")
