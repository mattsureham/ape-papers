# =============================================================================
# 03b_revised_inference.R — Address reviewer concerns: county-clustered SEs,
# county trends, time placebo
# =============================================================================

source("00_packages.R")

dt <- fread("../data/county_month_panel.csv")
county_avg <- dt[, .(avg_pills = mean(total_oxy_pills)), by = county_id]
keep <- county_avg[avg_pills >= 100]$county_id
dt <- dt[county_id %in% keep]
dt[, county_id := as.factor(county_id)]
dt[, ym_fac := as.factor(ym_int)]
dt[, weight := total_oxy_pills]

# ---------------------------------------------------------------------------
# 1. County-clustered SEs (288 clusters instead of 3)
# ---------------------------------------------------------------------------
cat("=== County-Clustered SEs ===\n")

m1_county <- feols(high_dose_share ~ treated | county_id + ym_fac,
                   data = dt, cluster = ~county_id, weights = ~weight)
cat("Pill-weighted, county-clustered:\n")
cat("  Coef:", coef(m1_county)["treated"], "\n")
cat("  SE:", se(m1_county)["treated"], "\n")
cat("  p-value:", pvalue(m1_county)["treated"], "\n")

# Also for avg mg and oxy/hydro
m2_county <- feols(avg_mg ~ treated | county_id + ym_fac,
                   data = dt, cluster = ~county_id, weights = ~weight)
m3_county <- feols(oxy_hydro_ratio ~ treated | county_id + ym_fac,
                   data = dt, cluster = ~county_id, weights = ~weight)

cat("\nAvg mg, county-clustered: coef=", coef(m2_county)["treated"],
    " se=", se(m2_county)["treated"],
    " p=", pvalue(m2_county)["treated"], "\n")
cat("Oxy ratio, county-clustered: coef=", coef(m3_county)["treated"],
    " se=", se(m3_county)["treated"],
    " p=", pvalue(m3_county)["treated"], "\n")

# ---------------------------------------------------------------------------
# 2. County-specific linear trends
# ---------------------------------------------------------------------------
cat("\n=== County-Specific Linear Trends ===\n")

dt[, trend := ym_int]
m1_trends <- feols(high_dose_share ~ treated | county_id[trend] + ym_fac,
                   data = dt, cluster = ~county_id, weights = ~weight)
cat("With county-specific trends:\n")
cat("  Coef:", coef(m1_trends)["treated"], "\n")
cat("  SE:", se(m1_trends)["treated"], "\n")
cat("  p-value:", pvalue(m1_trends)["treated"], "\n")

# ---------------------------------------------------------------------------
# 3. Time placebo (fake treatment at July 2009)
# ---------------------------------------------------------------------------
cat("\n=== Time Placebo (July 2009) ===\n")

# Use only pre-treatment data (before Oct 2010)
dt_pre <- dt[ym_int < 58]  # before Oct 2010
fake_treatment_ym <- (2009 - 2006) * 12 + 7  # July 2009 = month 43
dt_pre[, post_fake := as.integer(ym_int >= fake_treatment_ym)]
dt_pre[, treated_fake := fl * post_fake]

m1_placebo_time <- feols(high_dose_share ~ treated_fake | county_id + ym_fac,
                         data = dt_pre, cluster = ~county_id, weights = ~weight)
cat("Time placebo (July 2009):\n")
cat("  Coef:", coef(m1_placebo_time)["treated_fake"], "\n")
cat("  SE:", se(m1_placebo_time)["treated_fake"], "\n")
cat("  p-value:", pvalue(m1_placebo_time)["treated_fake"], "\n")

# ---------------------------------------------------------------------------
# 4. Event study with county-clustered SEs
# ---------------------------------------------------------------------------
cat("\n=== Event Study (County-Clustered) ===\n")

dt[, event_quarter := floor(event_time / 3)]
dt[event_quarter < -8, event_quarter := -8]
dt[event_quarter > 5, event_quarter := 5]

m_es_county <- feols(high_dose_share ~ i(event_quarter, fl, ref = -1) | county_id + ym_fac,
                     data = dt, cluster = ~county_id, weights = ~weight)
cat("Event study coefficients (county-clustered):\n")
print(coeftable(m_es_county))

# ---------------------------------------------------------------------------
# Save revised models
# ---------------------------------------------------------------------------
save(m1_county, m2_county, m3_county, m1_trends, m1_placebo_time, m_es_county,
     file = "../data/revised_models.RData")

# Update main results for tables
revised_results <- list(
  county_clustered = list(
    high_dose_share = list(
      coef = coef(m1_county)["treated"],
      se = se(m1_county)["treated"],
      pval = pvalue(m1_county)["treated"]
    ),
    avg_mg = list(
      coef = coef(m2_county)["treated"],
      se = se(m2_county)["treated"],
      pval = pvalue(m2_county)["treated"]
    ),
    oxy_hydro_ratio = list(
      coef = coef(m3_county)["treated"],
      se = se(m3_county)["treated"],
      pval = pvalue(m3_county)["treated"]
    )
  ),
  county_trends = list(
    coef = coef(m1_trends)["treated"],
    se = se(m1_trends)["treated"],
    pval = pvalue(m1_trends)["treated"]
  ),
  time_placebo = list(
    coef = coef(m1_placebo_time)["treated_fake"],
    se = se(m1_placebo_time)["treated_fake"],
    pval = pvalue(m1_placebo_time)["treated_fake"]
  )
)

write_json(revised_results, "../data/revised_results.json", auto_unbox = TRUE, digits = 8)
cat("\nRevised inference complete.\n")
