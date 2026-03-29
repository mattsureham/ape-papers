# ==============================================================================
# 04_robustness.R — Robustness checks and sensitivity analysis
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_final.rds")
hisp <- panel[ethnicity == "A2"]
hisp[, county_id := as.integer(factor(county_fips))]
hisp[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]

# ==============================================================================
# 1. DROP GREAT RECESSION COHORTS (activated 2008Q4-2009Q2)
# ==============================================================================

cat("=== Robustness: Excluding Great Recession activation cohorts ===\n")

# Recession quarters: 2008Q4 = 2008*4+4 = 8036, 2009Q1 = 8037, 2009Q2 = 8038
recession_qs <- c(2008 * 4 + 4, 2009 * 4 + 1, 2009 * 4 + 2)

hisp_no_recession <- hisp[!(activation_time_q %in% recession_qs)]
hisp_no_recession[, county_id_nr := as.integer(factor(county_fips))]

twfe_nr_visible <- feols(emp_share_visible ~ post | county_id_nr + time_q,
                         data = hisp_no_recession, vcov = ~state_fips)
cat("TWFE visible (no recession cohorts):\n")
print(summary(twfe_nr_visible))

twfe_nr_opaque <- feols(emp_share_opaque ~ post | county_id_nr + time_q,
                        data = hisp_no_recession, vcov = ~state_fips)
cat("TWFE opaque (no recession cohorts):\n")
print(summary(twfe_nr_opaque))

saveRDS(twfe_nr_visible, "../data/twfe_nr_visible.rds")
saveRDS(twfe_nr_opaque, "../data/twfe_nr_opaque.rds")

# ==============================================================================
# 2. LATE ACTIVATORS ONLY (2010-2013)
# ==============================================================================

cat("\n=== Robustness: Late activators only (2010-2013) ===\n")

late_qs <- (2010 * 4 + 1):(2013 * 4 + 4)
hisp_late <- hisp[activation_time_q == 0 | activation_time_q %in% late_qs]
hisp_late[, county_id_late := as.integer(factor(county_fips))]

twfe_late_visible <- feols(emp_share_visible ~ post | county_id_late + time_q,
                           data = hisp_late, vcov = ~state_fips)
cat("TWFE visible (late activators):\n")
print(summary(twfe_late_visible))

saveRDS(twfe_late_visible, "../data/twfe_late_visible.rds")

# ==============================================================================
# 3. ALTERNATIVE INDUSTRY DEFINITIONS
# ==============================================================================

cat("\n=== Robustness: Construction only (narrower visible) ===\n")

# Recompute with construction-only as visible
panel_sector <- readRDS("../data/panel_sector.rds")
setDT(panel_sector)

# Construction-only: go back to qwi_raw for finer industry detail
qwi_raw <- readRDS("../data/qwi_raw.rds")
setDT(qwi_raw)
qwi_raw[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi_raw[, time_q := year * 4 + quarter]

constr_panel <- qwi_raw[industry %in% c("236", "237", "238") & ethnicity == "A2",
  .(emp_constr = sum(Emp, na.rm = TRUE)),
  by = .(county_fips, year, quarter, time_q)
]

# Merge with totals
qwi_totals <- readRDS("../data/qwi_totals.rds")
setDT(qwi_totals)
qwi_totals[, county_fips := sprintf("%05d", as.integer(county_fips))]
qwi_totals[, time_q := year * 4 + quarter]

hisp_totals <- qwi_totals[ethnicity == "A2"]
constr_panel <- merge(constr_panel, hisp_totals[, .(county_fips, time_q, total_emp)],
                      by = c("county_fips", "time_q"), all.x = TRUE)
constr_panel[, constr_share := emp_constr / total_emp]

# Merge SC dates
sc <- as.data.table(readRDS("../data/sc_activation_dates.rds"))
constr_panel <- merge(constr_panel, sc[, .(county_fips, activation_quarter)],
                      by = "county_fips", all.x = TRUE)

constr_panel[, activation_year := as.integer(substr(activation_quarter, 1, 4))]
constr_panel[, activation_q_num := as.integer(substr(activation_quarter, 6, 6))]
constr_panel[, activation_time_q := activation_year * 4 + activation_q_num]
constr_panel[is.na(activation_time_q), activation_time_q := 0]
constr_panel[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]
constr_panel[, county_id := as.integer(factor(county_fips))]
constr_panel[, state_fips := substr(county_fips, 1, 2)]

# Filter to good counties
good_counties <- unique(panel$county_fips)
constr_panel <- constr_panel[county_fips %in% good_counties]

twfe_constr <- feols(constr_share ~ post | county_id + time_q,
                     data = constr_panel, vcov = ~state_fips)
cat("TWFE construction-only share:\n")
print(summary(twfe_constr))

saveRDS(twfe_constr, "../data/twfe_constr.rds")

# ==============================================================================
# 4. BACON DECOMPOSITION
# ==============================================================================

cat("\n=== Bacon Decomposition ===\n")

# Need balanced panel subset for bacon decomposition
# Use a simpler specification
hisp_balanced <- hisp[, .(emp_share_visible = mean(emp_share_visible, na.rm = TRUE),
                          post = max(post),
                          activation_time_q = first(activation_time_q),
                          state_fips = first(state_fips)),
                      by = .(county_fips, time_q)]
hisp_balanced[, county_id := as.integer(factor(county_fips))]
hisp_balanced[, treated := as.integer(activation_time_q > 0)]

# Check if balanced
n_periods <- uniqueN(hisp_balanced$time_q)
county_counts <- hisp_balanced[, .N, by = county_fips]
balanced_counties <- county_counts[N == n_periods]$county_fips

if (length(balanced_counties) >= 100) {
  hisp_bal <- hisp_balanced[county_fips %in% balanced_counties]
  hisp_bal[, county_id := as.integer(factor(county_fips))]

  bacon_out <- tryCatch({
    bacon(emp_share_visible ~ post, data = as.data.frame(hisp_bal),
          id_var = "county_id", time_var = "time_q")
  }, error = function(e) {
    cat("Bacon decomposition error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(bacon_out)) {
    cat("Bacon decomposition results:\n")
    bacon_summary <- aggregate(cbind(estimate, weight) ~ type, data = bacon_out,
                               FUN = mean)
    print(bacon_summary)
    saveRDS(bacon_out, "../data/bacon_decomp.rds")
  }
} else {
  cat("Insufficient balanced counties for Bacon decomposition.\n")
}

# ==============================================================================
# 5. HONESTDID SENSITIVITY
# ==============================================================================

cat("\n=== HonestDiD Sensitivity Analysis ===\n")

# Use the event study from CS estimation
es_visible <- readRDS("../data/es_visible.rds")

# Extract pre-treatment coefficients for HonestDiD
tryCatch({
  # Get the event-study beta and variance-covariance matrix
  es_beta <- es_visible$att.egt
  es_se <- es_visible$se.egt
  es_e <- es_visible$egt

  # Separate pre and post
  pre_idx <- which(es_e < 0)
  post_idx <- which(es_e >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    cat("Pre-treatment coefficients:\n")
    for (i in pre_idx) {
      cat(sprintf("  e=%d: %.5f (%.5f)\n", es_e[i], es_beta[i], es_se[i]))
    }
    cat("Post-treatment coefficients:\n")
    for (i in post_idx) {
      cat(sprintf("  e=%d: %.5f (%.5f)\n", es_e[i], es_beta[i], es_se[i]))
    }
  }
}, error = function(e) {
  cat("HonestDiD preparation error:", conditionMessage(e), "\n")
})

cat("\nRobustness checks complete.\n")
