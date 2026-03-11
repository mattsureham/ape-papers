# ==============================================================================
# 03_main_analysis.R — Main DiD analysis
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
mir_panel <- fread(file.path(data_dir, "mir_panel.csv"))
hpi_panel <- fread(file.path(data_dir, "hpi_panel.csv"))

mir_panel[, date := as.Date(date)]
hpi_panel[, date := as.Date(date)]

# ==============================================================================
# 1. Callaway-Sant'Anna: Mortgage Rates
# ==============================================================================
cat("=== CS-DiD: Mortgage Rates ===\n")

# Use QUARTERLY data for CS-DiD to reduce cohort granularity
# Aggregate monthly rates to quarterly
mir_panel[, date := as.Date(date)]
mir_panel[, yr := year(date)]
mir_panel[, qtr := quarter(date)]
mir_panel[, yq_idx := (yr - 2005) * 4 + qtr]

mir_q <- mir_panel[!is.na(rate),
                    .(rate = mean(rate, na.rm = TRUE),
                      consumer_rate = mean(consumer_rate, na.rm = TRUE)),
                    by = .(country, country_id, yq_idx, yr, qtr, transposition_date)]

# Assign treatment at quarterly level (avoids mid-quarter split creating duplicate rows)
mir_q[, date_q := as.Date(paste0(yr, "-", (qtr - 1) * 3 + 1, "-01"))]
mir_q[, treated := as.integer(!is.na(transposition_date) & date_q >= as.Date(transposition_date))]

# Cohort = quarter of transposition (0 = never treated)
mir_q[!is.na(transposition_date),
      cohort_q := (year(transposition_date) - 2005) * 4 + quarter(transposition_date)]
mir_q[is.na(transposition_date), cohort_q := 0L]

cat("Quarterly panel:", nrow(mir_q), "obs,", uniqueN(mir_q$country), "countries\n")
cat("Treatment cohorts (quarters):\n")
print(mir_q[cohort_q > 0, .(countries = uniqueN(country)), by = cohort_q][order(cohort_q)])

# Balance the panel: keep countries present in all quarters
n_periods <- uniqueN(mir_q$yq_idx)
balanced_countries <- mir_q[!is.na(rate), .N, by = country][N == n_periods, country]
mir_bal <- mir_q[country %in% balanced_countries]
cat("Balanced panel:", nrow(mir_bal), "obs,", uniqueN(mir_bal$country), "countries\n")

# --- Sun-Abraham IW estimator (fixest) as primary ---
# Use large cohort_q value for never-treated (none exist here, so use latest as reference)
mir_bal[, cohort_sunab := fifelse(cohort_q == 0, 10000L, cohort_q)]

sunab_rate <- feols(rate ~ sunab(cohort_sunab, yq_idx, ref.p = -1) | country_id + yq_idx,
                     data = mir_bal[!is.na(rate)],
                     cluster = ~country_id)
cat("\n--- Sun-Abraham IW Estimator (Mortgage Rates) ---\n")
summary(sunab_rate)

# Extract event-study coefficients
sa_coefs <- as.data.table(coeftable(sunab_rate), keep.rownames = "term")
setnames(sa_coefs, c("term", "estimate", "se", "t_stat", "p_value"))
sa_coefs[, rel_time := as.integer(gsub(".*::", "", term))]
sa_coefs <- sa_coefs[!is.na(rel_time)]

es_rate_dt <- data.table(
  rel_time = sa_coefs$rel_time,
  att = sa_coefs$estimate,
  se = sa_coefs$se,
  ci_lower = sa_coefs$estimate - 1.96 * sa_coefs$se,
  ci_upper = sa_coefs$estimate + 1.96 * sa_coefs$se
)
fwrite(es_rate_dt, file.path(data_dir, "es_rate_results.csv"))

# Overall ATT (average of post-treatment coefficients)
post_coefs <- sa_coefs[rel_time >= 0]
overall_att <- mean(post_coefs$estimate)
# SE via delta method: avg of correlated estimates
vcv <- vcov(sunab_rate)
post_idx <- which(grepl("::", names(coef(sunab_rate))) &
                    as.integer(gsub(".*::", "", names(coef(sunab_rate)))) >= 0)
if (length(post_idx) > 0) {
  overall_se <- sqrt(sum(vcv[post_idx, post_idx]) / length(post_idx)^2)
} else {
  overall_se <- mean(post_coefs$se)
}

overall_rate_dt <- data.table(
  outcome = "mortgage_rate",
  att = overall_att,
  se = overall_se,
  ci_lower = overall_att - 1.96 * overall_se,
  ci_upper = overall_att + 1.96 * overall_se
)
fwrite(overall_rate_dt, file.path(data_dir, "overall_rate.csv"))
cat("\nOverall ATT (mortgage rate):", round(overall_att, 4),
    "(SE:", round(overall_se, 4), ")\n")

# Also save as cs_rate and es_rate objects for downstream compatibility
cs_rate <- sunab_rate
es_rate <- es_rate_dt
overall_rate <- overall_rate_dt

# ==============================================================================
# 2. Sun-Abraham: House Price Index (quarterly)
# ==============================================================================
cat("\n=== Sun-Abraham: House Price Index ===\n")

hpi_panel[, cohort_sunab := fifelse(cohort_num == 0, 10000L, cohort_num)]

sunab_hpi <- feols(log_hpi ~ sunab(cohort_sunab, time_idx, ref.p = -1) | country_id + time_idx,
                    data = hpi_panel[!is.na(log_hpi)],
                    cluster = ~country_id)
cat("\nSun-Abraham IW Estimator — Log HPI:\n")
summary(sunab_hpi)

# Extract event-study coefficients
hpi_coefs <- as.data.table(coeftable(sunab_hpi), keep.rownames = "term")
setnames(hpi_coefs, c("term", "estimate", "se", "t_stat", "p_value"))
hpi_coefs[, rel_time := as.integer(gsub(".*::", "", term))]
hpi_coefs <- hpi_coefs[!is.na(rel_time)]

es_hpi_dt <- data.table(
  rel_time = hpi_coefs$rel_time,
  att = hpi_coefs$estimate,
  se = hpi_coefs$se,
  ci_lower = hpi_coefs$estimate - 1.96 * hpi_coefs$se,
  ci_upper = hpi_coefs$estimate + 1.96 * hpi_coefs$se
)
fwrite(es_hpi_dt, file.path(data_dir, "es_hpi_results.csv"))

# Overall ATT for HPI
post_hpi <- hpi_coefs[rel_time >= 0]
overall_hpi_att <- mean(post_hpi$estimate)
vcv_hpi <- vcov(sunab_hpi)
post_idx_hpi <- which(grepl("::", names(coef(sunab_hpi))) &
                        as.integer(gsub(".*::", "", names(coef(sunab_hpi)))) >= 0)
if (length(post_idx_hpi) > 0) {
  overall_hpi_se <- sqrt(sum(vcv_hpi[post_idx_hpi, post_idx_hpi]) / length(post_idx_hpi)^2)
} else {
  overall_hpi_se <- mean(post_hpi$se)
}

overall_hpi_dt <- data.table(
  outcome = "log_hpi",
  att = overall_hpi_att,
  se = overall_hpi_se,
  ci_lower = overall_hpi_att - 1.96 * overall_hpi_se,
  ci_upper = overall_hpi_att + 1.96 * overall_hpi_se
)
fwrite(overall_hpi_dt, file.path(data_dir, "overall_hpi.csv"))
cat("Overall ATT (log HPI):", round(overall_hpi_att, 4),
    "(SE:", round(overall_hpi_se, 4), ")\n")

cs_hpi <- sunab_hpi
es_hpi <- es_hpi_dt
overall_hpi <- overall_hpi_dt

# ==============================================================================
# 3. TWFE (fixest) as comparison specification
# ==============================================================================
cat("\n=== TWFE Comparison Specifications ===\n")

# TWFE: mortgage rate (quarterly)
twfe_rate <- feols(rate ~ treated | country_id + yq_idx,
                    data = mir_q[!is.na(rate)],
                    cluster = ~country_id)
cat("\nTWFE — Mortgage Rate:\n")
summary(twfe_rate)

# TWFE: log HPI
twfe_hpi <- feols(log_hpi ~ treated | country_id + time_idx,
                   data = hpi_panel[!is.na(log_hpi)],
                   cluster = ~country_id)
cat("\nTWFE — Log HPI:\n")
summary(twfe_hpi)

# ==============================================================================
# 4. Consumer Credit Placebo (Sun-Abraham)
# ==============================================================================
cat("\n=== Placebo: Consumer Credit Rates ===\n")

# Balance consumer panel
mir_cons_bal <- mir_bal[!is.na(consumer_rate)]

sunab_consumer <- tryCatch({
  feols(consumer_rate ~ sunab(cohort_sunab, yq_idx, ref.p = -1) | country_id + yq_idx,
        data = mir_cons_bal, cluster = ~country_id)
}, error = function(e) {
  cat("Consumer credit Sun-Abraham failed:", e$message, "\n")
  NULL
})

if (!is.null(sunab_consumer)) {
  cons_coefs <- as.data.table(coeftable(sunab_consumer), keep.rownames = "term")
  setnames(cons_coefs, c("term", "estimate", "se", "t_stat", "p_value"))
  cons_coefs[, rel_time := as.integer(gsub(".*::", "", term))]
  cons_coefs <- cons_coefs[!is.na(rel_time)]

  es_consumer_dt <- data.table(
    rel_time = cons_coefs$rel_time,
    att = cons_coefs$estimate,
    se = cons_coefs$se,
    ci_lower = cons_coefs$estimate - 1.96 * cons_coefs$se,
    ci_upper = cons_coefs$estimate + 1.96 * cons_coefs$se
  )
  fwrite(es_consumer_dt, file.path(data_dir, "es_consumer_placebo.csv"))

  post_cons <- cons_coefs[rel_time >= 0]
  overall_consumer_dt <- data.table(
    outcome = "consumer_rate_placebo",
    att = mean(post_cons$estimate),
    se = mean(post_cons$se)
  )
  fwrite(overall_consumer_dt, file.path(data_dir, "overall_consumer_placebo.csv"))
  cat("Consumer credit placebo ATT:", round(mean(post_cons$estimate), 4), "\n")
}

# ==============================================================================
# 5. Save all model objects for later use
# ==============================================================================
save(cs_rate, es_rate, overall_rate,
     cs_hpi, es_hpi, overall_hpi,
     twfe_rate, twfe_hpi, mir_q,
     file = file.path(data_dir, "main_models.RData"))

cat("\nMain analysis complete. All results saved.\n")
