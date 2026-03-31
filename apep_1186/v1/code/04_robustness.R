## 04_robustness.R — Robustness checks
## apep_1186: Railroad Quiet Zones and Crossing Safety

source("00_packages.R")

panel <- fread("../data/panel.csv")
load("../data/main_results.RData")

## ---------------------------------------------------------------
## 1. Heterogeneity by pre-existing safety infrastructure
## ---------------------------------------------------------------
cat("=== Heterogeneity: Gates vs No Gates ===\n")

## Crossings with gates should be less affected (already safe)
m_gates <- feols(any_accident ~ treated | crossing_id + year,
                 data = panel[has_gates == 1], cluster = ~county_fips)
m_nogates <- feols(any_accident ~ treated | crossing_id + year,
                   data = panel[has_gates == 0], cluster = ~county_fips)

cat("With gates:", coef(m_gates), "(SE:", se(m_gates), ")\n")
cat("No gates:", coef(m_nogates), "(SE:", se(m_nogates), ")\n")

## ---------------------------------------------------------------
## 2. Heterogeneity by traffic volume
## ---------------------------------------------------------------
cat("\n=== Heterogeneity: High vs Low AADT ===\n")

med_aadt <- median(panel[treat_group > 0, aadt], na.rm = TRUE)
cat("Median AADT among treated:", med_aadt, "\n")

m_high_traffic <- feols(any_accident ~ treated | crossing_id + year,
                        data = panel[aadt >= med_aadt], cluster = ~county_fips)
m_low_traffic <- feols(any_accident ~ treated | crossing_id + year,
                       data = panel[aadt < med_aadt], cluster = ~county_fips)

cat("High AADT:", coef(m_high_traffic), "(SE:", se(m_high_traffic), ")\n")
cat("Low AADT:", coef(m_low_traffic), "(SE:", se(m_low_traffic), ")\n")

## ---------------------------------------------------------------
## 3. Leave-one-out by top adopting states
## ---------------------------------------------------------------
cat("\n=== Leave-One-Out by State ===\n")

top_states <- panel[treat_group > 0, .N, by = state_fips][order(-N)][1:5]
cat("Top 5 adopting states:\n")
print(top_states)

loo_results <- list()
for (s in top_states$state_fips) {
  m_loo <- feols(any_accident ~ treated | crossing_id + year,
                 data = panel[state_fips != s], cluster = ~county_fips)
  loo_results[[as.character(s)]] <- data.table(
    state_dropped = s,
    estimate = coef(m_loo)[[1]],
    se = se(m_loo)[[1]]
  )
}
loo_dt <- rbindlist(loo_results)
cat("\nLeave-one-out results:\n")
print(loo_dt)

## ---------------------------------------------------------------
## 4. Severity analysis (conditional on accident)
## ---------------------------------------------------------------
cat("\n=== Severity Conditional on Accident ===\n")

## Among crossing-years WITH an accident: is severity higher?
acc_panel <- panel[accidents > 0]
cat("Crossing-years with accidents:", nrow(acc_panel), "\n")

m_killed_cond <- feols(total_killed ~ treated | crossing_id + year,
                       data = acc_panel, cluster = ~county_fips)
m_injured_cond <- feols(total_injured ~ treated | crossing_id + year,
                        data = acc_panel, cluster = ~county_fips)

cat("Killed | accident:", coef(m_killed_cond), "(SE:", se(m_killed_cond), ")\n")
cat("Injured | accident:", coef(m_injured_cond), "(SE:", se(m_injured_cond), ")\n")

## ---------------------------------------------------------------
## 5. Placebo: pre-2005 "treatment" (pseudo-QZ dates)
## ---------------------------------------------------------------
cat("\n=== Placebo: Pseudo-Treatment in 2000 ===\n")

## Restrict to 1990-2004, assign placebo treatment at 2000
## for crossings that actually got QZ in 2005-2010
placebo_data <- panel[year <= 2004]
placebo_data[, placebo_treated := as.integer(
  treat_group >= 2005 & treat_group <= 2010 & year >= 2000)]

m_placebo <- feols(any_accident ~ placebo_treated | crossing_id + year,
                   data = placebo_data, cluster = ~county_fips)

cat("Placebo (2000):", coef(m_placebo), "(SE:", se(m_placebo), ")\n")

## ---------------------------------------------------------------
## 6. Train speed heterogeneity
## ---------------------------------------------------------------
cat("\n=== Heterogeneity: High vs Low Speed ===\n")

med_speed <- median(panel[treat_group > 0, max_speed], na.rm = TRUE)
cat("Median max speed among treated:", med_speed, "\n")

m_high_speed <- feols(any_accident ~ treated | crossing_id + year,
                      data = panel[max_speed >= med_speed], cluster = ~county_fips)
m_low_speed <- feols(any_accident ~ treated | crossing_id + year,
                     data = panel[max_speed < med_speed & max_speed > 0],
                     cluster = ~county_fips)

cat("High speed:", coef(m_high_speed), "(SE:", se(m_high_speed), ")\n")
cat("Low speed:", coef(m_low_speed), "(SE:", se(m_low_speed), ")\n")

## ---------------------------------------------------------------
## 7. Save all robustness results
## ---------------------------------------------------------------
save(m_gates, m_nogates, m_high_traffic, m_low_traffic,
     loo_dt, m_killed_cond, m_injured_cond, m_placebo,
     m_high_speed, m_low_speed, med_aadt, med_speed,
     file = "../data/robustness_results.RData")

cat("\n=== Robustness complete ===\n")
