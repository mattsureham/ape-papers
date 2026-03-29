# =============================================================================
# 04_robustness.R — Robustness checks (pill-weighted specifications)
# =============================================================================

source("00_packages.R")

dt <- fread("../data/county_month_panel.csv")
oxy_dos <- fread("../data/oxy_by_dosage.csv")

# Filter to counties with >=100 avg pills/month
county_avg <- dt[, .(avg_pills = mean(total_oxy_pills)), by = county_id]
keep <- county_avg[avg_pills >= 100]$county_id
dt <- dt[county_id %in% keep]
dt[, county_id := as.factor(county_id)]
dt[, ym_fac := as.factor(ym_int)]
dt[, weight := total_oxy_pills]

treatment_ym <- (2011 - 2006) * 12 + 7

# ---------------------------------------------------------------------------
# 1. Alternative high-dose thresholds (weighted)
# ---------------------------------------------------------------------------
cat("=== Alternative Thresholds (Pill-Weighted) ===\n")

for (thresh in c(20, 40)) {
  oxy_dos[, high := as.integer(dos_mg >= thresh)]
  alt_agg <- oxy_dos[, .(
    total_pills = sum(total_pills),
    high_pills = sum(total_pills * high)
  ), by = .(BUYER_STATE, BUYER_COUNTY, year, month)]
  alt_agg[, high_share := high_pills / total_pills]
  alt_agg[, county_id := paste0(BUYER_STATE, "_", BUYER_COUNTY)]
  alt_agg[, ym_int := (year - 2006) * 12 + month]
  alt_agg <- alt_agg[county_id %in% keep]
  alt_agg[, fl := as.integer(BUYER_STATE == "FL")]
  alt_agg[, post := as.integer(ym_int >= treatment_ym)]
  alt_agg[, treated := fl * post]
  alt_agg[, county_id := as.factor(county_id)]
  alt_agg[, ym_fac := as.factor(ym_int)]
  alt_agg[, weight := total_pills]

  m_alt <- feols(high_share ~ treated | county_id + ym_fac,
                 data = alt_agg, cluster = ~BUYER_STATE, weights = ~weight)
  cat(sprintf("\nThreshold >= %dmg: coef=%.4f, se=%.4f, p=%.4f\n",
              thresh, coef(m_alt)["treated"], se(m_alt)["treated"],
              pvalue(m_alt)["treated"]))
}

# ---------------------------------------------------------------------------
# 2. Donut hole: exclude Oct 2010 – June 2011 transition (weighted)
# ---------------------------------------------------------------------------
cat("\n=== Donut Hole (Pill-Weighted) ===\n")

dt_donut <- dt[ym_int < 58 | ym_int >= 67]  # excl Oct 2010 – Jun 2011
m_donut <- feols(high_dose_share ~ treated | county_id + ym_fac,
                 data = dt_donut, cluster = ~BUYER_STATE, weights = ~weight)
cat("Donut: coef=", coef(m_donut)["treated"],
    " se=", se(m_donut)["treated"], "\n")

# ---------------------------------------------------------------------------
# 3. Unweighted (for comparison)
# ---------------------------------------------------------------------------
cat("\n=== Unweighted (for comparison) ===\n")

m_uw <- feols(high_dose_share ~ treated | county_id + ym_fac,
              data = dt, cluster = ~BUYER_STATE)
cat("Unweighted: coef=", coef(m_uw)["treated"],
    " se=", se(m_uw)["treated"], "\n")

# ---------------------------------------------------------------------------
# 4. Placebo test: GA as "treated", AL as control (weighted)
# ---------------------------------------------------------------------------
cat("\n=== Placebo: GA vs AL (Pill-Weighted) ===\n")

dt_placebo <- dt[BUYER_STATE %in% c("GA", "AL")]
dt_placebo[, fl_placebo := as.integer(BUYER_STATE == "GA")]
dt_placebo[, treated_placebo := fl_placebo * post]

m_placebo <- feols(high_dose_share ~ treated_placebo | county_id + ym_fac,
                   data = dt_placebo, cluster = ~BUYER_STATE, weights = ~weight)
cat("Placebo (GA vs AL): coef=", coef(m_placebo)["treated_placebo"],
    " se=", se(m_placebo)["treated_placebo"],
    " p=", pvalue(m_placebo)["treated_placebo"], "\n")

# ---------------------------------------------------------------------------
# 5. Leave-one-out county jackknife (FL counties, weighted)
# ---------------------------------------------------------------------------
cat("\n=== Leave-one-out Jackknife (Pill-Weighted) ===\n")

fl_counties <- unique(as.character(dt[fl == 1]$county_id))
jack_coefs <- numeric(length(fl_counties))

for (i in seq_along(fl_counties)) {
  dt_jack <- dt[county_id != fl_counties[i]]
  m_jack <- feols(high_dose_share ~ treated | county_id + ym_fac,
                  data = dt_jack, cluster = ~BUYER_STATE, weights = ~weight)
  jack_coefs[i] <- coef(m_jack)["treated"]
}

cat("Jackknife range:", round(range(jack_coefs), 4), "\n")
cat("Jackknife mean:", round(mean(jack_coefs), 4), "\n")
cat("Jackknife SD:", round(sd(jack_coefs), 4), "\n")

# ---------------------------------------------------------------------------
# 6. Restricted pre-period (2009+ only, avoiding early boom)
# ---------------------------------------------------------------------------
cat("\n=== Restricted Pre-Period (2009+, Pill-Weighted) ===\n")

dt_2009 <- dt[year >= 2009]
m_2009 <- feols(high_dose_share ~ treated | county_id + ym_fac,
                data = dt_2009, cluster = ~BUYER_STATE, weights = ~weight)
cat("2009+ only: coef=", coef(m_2009)["treated"],
    " se=", se(m_2009)["treated"], "\n")

# ---------------------------------------------------------------------------
# Save robustness results and models
# ---------------------------------------------------------------------------
rob <- list(
  donut = list(coef = coef(m_donut)["treated"], se = se(m_donut)["treated"]),
  unweighted = list(coef = coef(m_uw)["treated"], se = se(m_uw)["treated"]),
  placebo_ga_al = list(coef = coef(m_placebo)["treated_placebo"],
                       se = se(m_placebo)["treated_placebo"],
                       pval = pvalue(m_placebo)["treated_placebo"]),
  jackknife_range = range(jack_coefs),
  jackknife_sd = sd(jack_coefs),
  restricted_2009 = list(coef = coef(m_2009)["treated"], se = se(m_2009)["treated"])
)

write_json(rob, "../data/robustness_results.json", auto_unbox = TRUE, digits = 8)
save(m_donut, m_placebo, m_uw, m_2009, file = "../data/robustness_models.RData")

cat("\nRobustness checks complete.\n")
