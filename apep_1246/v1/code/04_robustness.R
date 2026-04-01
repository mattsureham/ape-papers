# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# =============================================================================

source("00_packages.R")

panel_pooled_bal <- readRDS("../data/panel_pooled_bal.rds")
panel_age <- readRDS("../data/panel_age.rds")
main_results <- readRDS("../data/main_results.rds")

# -----------------------------------------------------------------------
# 1. Placebo Sector: NAICS 621 (Ambulatory Care)
#    Partially covered by mandates, so we expect WEAKER effect
# -----------------------------------------------------------------------
cat("=== PLACEBO: NAICS 621 (Ambulatory Care) ===\n")

# Need to fetch 621 data — use a quick DuckDB query
# Fix Azure connection string (shell truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (ln in env_lines) {
  ln <- trimws(ln)
  if (startsWith(ln, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^[^=]+=", "", ln)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

qwi_621 <- dbGetQuery(con, "
  SELECT
    geography AS county_fips,
    year, quarter,
    industry,
    SUM(Emp) AS emp,
    SUM(HirA) AS hires,
    SUM(Sep) AS seps,
    AVG(EarnS) AS earn
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry IN ('621', '624')
    AND year >= 2015
    AND agegrp = 'A00'
    AND sex = 0
  GROUP BY geography, year, quarter, industry
")
apep_azure_disconnect(con)

setDT(qwi_621)
qwi_621[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi_621[, state_fips := substr(county_fips, 1, 2)]
qwi_621[, qtr := (year - 2015L) * 4L + quarter]
qwi_621[, naics621 := as.integer(industry == "621")]
qwi_621[, cs_id := paste0(county_fips, "_", industry)]
qwi_621[, log_emp := log(emp + 1)]

mandate_states <- readRDS("../data/mandate_states.rds")
qwi_621 <- merge(qwi_621, mandate_states[, .(state_fips, mandate_qtr)],
                 by = "state_fips", all.x = TRUE)
qwi_621[is.na(mandate_qtr), mandate_qtr := 0L]
qwi_621[, has_state_mandate := as.integer(mandate_qtr > 0)]
qwi_621[, post_mandate := as.integer(
  (has_state_mandate == 1 & qtr >= mandate_qtr) |
  (has_state_mandate == 0 & qtr >= 29L)
)]

# Balance filter
qcnt <- qwi_621[, .N, by = cs_id]
max_q <- qwi_621[, uniqueN(qtr)]
bal_ids <- qcnt[N >= max_q * 0.9, cs_id]
qwi_621_bal <- qwi_621[cs_id %in% bal_ids & emp > 0]

placebo_621 <- feols(
  log_emp ~ has_state_mandate:naics621:post_mandate +
            has_state_mandate:post_mandate +
            naics621:post_mandate +
            has_state_mandate:naics621 |
            cs_id + state_fips^qtr,
  data = qwi_621_bal,
  cluster = ~state_fips
)
cat("Placebo 621 vs 624:\n")
summary(placebo_621)

# -----------------------------------------------------------------------
# 2. Placebo Demographics: Age 55+ (high vax rates → weaker sieve)
# -----------------------------------------------------------------------
cat("\n=== PLACEBO: AGE 55+ (High Vaccination Rate) ===\n")

panel_55plus <- panel_age[age_broad == "55+"]
panel_55plus[, cs_id := paste0(county_fips, "_", industry, "_55plus")]

placebo_55plus <- feols(
  log_emp ~ has_state_mandate:naics623:post_mandate +
            has_state_mandate:post_mandate +
            naics623:post_mandate +
            has_state_mandate:naics623 |
            cs_id + state_fips^qtr,
  data = panel_55plus[emp > 0],
  cluster = ~state_fips
)
cat("Placebo 55+:\n")
summary(placebo_55plus)

# -----------------------------------------------------------------------
# 3. Wild Cluster Bootstrap for main DDD
# -----------------------------------------------------------------------
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Run WCB for the main DDD employment specification
tryCatch({
  wcb <- boottest(
    main_results$ddd_emp,
    param = "has_state_mandate:naics623:post_mandate",
    clustid = ~state_fips,
    B = 999,
    type = "webb"
  )
  cat("Wild cluster bootstrap p-value:", wcb$p_val, "\n")
  cat("WCB 95% CI:", wcb$conf_int, "\n")
  saveRDS(wcb, "../data/wcb_result.rds")
}, error = function(e) {
  cat("WCB failed:", e$message, "\n")
  cat("Falling back to cluster-robust SEs only.\n")
})

# -----------------------------------------------------------------------
# 4. Leave-One-Out (drop each mandate state)
# -----------------------------------------------------------------------
cat("\n=== LEAVE-ONE-OUT ===\n")

mandate_st <- unique(panel_pooled_bal[has_state_mandate == 1, state_fips])
loo_results <- data.table(
  dropped_state = character(),
  coef = numeric(),
  se = numeric()
)

for (st in mandate_st) {
  sub <- panel_pooled_bal[state_fips != st]
  tryCatch({
    m <- feols(
      log_emp ~ has_state_mandate:naics623:post_mandate +
                has_state_mandate:post_mandate +
                naics623:post_mandate +
                has_state_mandate:naics623 |
                cs_id + state_fips^qtr,
      data = sub,
      cluster = ~state_fips
    )
    loo_results <- rbind(loo_results, data.table(
      dropped_state = st,
      coef = coef(m)["has_state_mandate:naics623:post_mandate"],
      se = se(m)["has_state_mandate:naics623:post_mandate"]
    ))
  }, error = function(e) NULL)
}

cat("Leave-one-out range:\n")
cat(sprintf("  Coefs: [%.4f, %.4f]\n", min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  Main:  %.4f\n",
            coef(main_results$ddd_emp)["has_state_mandate:naics623:post_mandate"]))

# -----------------------------------------------------------------------
# 5. Sun-Abraham alternative estimator
# -----------------------------------------------------------------------
cat("\n=== SUN-ABRAHAM (Alternative Estimator) ===\n")

# For Sun-Abraham, we need treatment cohort + relative time
panel_pooled_bal[, cohort := fifelse(has_state_mandate == 1, mandate_qtr, 10000L)]

# Create relative time
panel_pooled_bal[, rel_time_sa := fifelse(
  has_state_mandate == 1,
  qtr - mandate_qtr,
  NA_integer_
)]

# Run Sun-Abraham within NAICS 623 only (simpler specification)
naics623_only <- panel_pooled_bal[naics623 == 1]

sunab_emp <- feols(
  log_emp ~ sunab(cohort, qtr) | county_fips + qtr,
  data = naics623_only,
  cluster = ~state_fips
)
cat("Sun-Abraham ATT:\n")
summary(sunab_emp)

# -----------------------------------------------------------------------
# 6. Save all robustness results
# -----------------------------------------------------------------------
rob_results <- list(
  placebo_621 = placebo_621,
  placebo_55plus = placebo_55plus,
  loo_results = loo_results,
  sunab_emp = sunab_emp
)
saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nAll robustness results saved.\n")
