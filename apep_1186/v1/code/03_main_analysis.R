## 03_main_analysis.R — Main estimation: quiet zone effects on crossing safety
## apep_1186: Railroad Quiet Zones and Crossing Safety

source("00_packages.R")

panel <- fread("../data/panel.csv")
cat("Panel loaded:", nrow(panel), "rows,", uniqueN(panel$crossing_id), "crossings\n")

## ---------------------------------------------------------------
## 1. Summary statistics
## ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

pre <- panel[year < 2005]
summ <- pre[, .(
  mean_accidents = mean(accidents),
  mean_any_acc   = mean(any_accident),
  mean_killed    = mean(total_killed),
  mean_injured   = mean(total_injured),
  mean_aadt      = mean(aadt, na.rm = TRUE),
  mean_trains    = mean(total_trains, na.rm = TRUE),
  mean_speed     = mean(max_speed, na.rm = TRUE),
  mean_gates     = mean(has_gates, na.rm = TRUE),
  n_crossings    = uniqueN(crossing_id)
), by = .(treated_ever = as.integer(treat_group > 0))]
print(summ)

## Pre-treatment SD of outcomes (for SDE)
pre_treated <- panel[treat_group > 0 & year < treat_group]
pre_all <- panel[year < 2005]
sd_any_acc <- sd(pre_all$any_accident)
sd_any_cas <- sd(pre_all$any_casualty)
sd_acc_count <- sd(pre_all$accidents)
cat("\nPre-treatment SDs:\n")
cat("  any_accident:", sd_any_acc, "\n")
cat("  any_casualty:", sd_any_cas, "\n")
cat("  accidents:", sd_acc_count, "\n")

## ---------------------------------------------------------------
## 2. TWFE estimates
## ---------------------------------------------------------------
cat("\n=== TWFE Estimates ===\n")

m1_twfe <- feols(any_accident ~ treated | crossing_id + year,
                 data = panel, cluster = ~county_fips)

m2_twfe <- feols(accidents ~ treated | crossing_id + year,
                 data = panel, cluster = ~county_fips)

m3_cas <- feols(any_casualty ~ treated | crossing_id + year,
                data = panel, cluster = ~county_fips)

m4_killed <- feols(total_killed ~ treated | crossing_id + year,
                   data = panel, cluster = ~county_fips)

m5_injured <- feols(total_injured ~ treated | crossing_id + year,
                    data = panel, cluster = ~county_fips)

cat("Any accident:", coef(m1_twfe), "(SE:", se(m1_twfe), ")\n")
cat("Accident count:", coef(m2_twfe), "(SE:", se(m2_twfe), ")\n")
cat("Any casualty:", coef(m3_cas), "(SE:", se(m3_cas), ")\n")
cat("Total killed:", coef(m4_killed), "(SE:", se(m4_killed), ")\n")
cat("Total injured:", coef(m5_injured), "(SE:", se(m5_injured), ")\n")

## ---------------------------------------------------------------
## 3. Sun-Abraham event study (heterogeneity-robust, sampled)
## ---------------------------------------------------------------
cat("\n=== Sun-Abraham Event Study ===\n")

## Use stratified sample (all treated + 3x controls) for memory
set.seed(20260331)
treated_ids <- unique(panel[treat_group > 0, crossing_id])
control_ids <- unique(panel[treat_group == 0, crossing_id])
n_controls_es <- min(length(control_ids), length(treated_ids) * 3)
sampled_controls_es <- sample(control_ids, n_controls_es)
es_data <- panel[crossing_id %in% c(treated_ids, sampled_controls_es)]

cat("Event study sample:", uniqueN(es_data$crossing_id), "crossings\n")

## Manual event-time indicators (more memory-efficient than sunab)
es_data[, event_time := fifelse(treat_group > 0, year - treat_group, NA_integer_)]
es_data[, et_bin := fifelse(!is.na(event_time),
                             pmin(pmax(event_time, -10L), 10L),
                             NA_integer_)]
## Reference: event_time == -1
es_data[, et_bin_ref := fifelse(is.na(et_bin), 0L, et_bin)]

es_sunab <- feols(any_accident ~ i(et_bin_ref, ref = -1) | crossing_id + year,
                  data = es_data,
                  cluster = ~county_fips)
cat("Sun-Abraham event study:\n")
print(summary(es_sunab))

## Extract event-time coefficients
es_ct <- coeftable(es_sunab)
es_coefs <- data.table(
  term     = rownames(es_ct),
  estimate = es_ct[, 1],
  se       = es_ct[, 2],
  tval     = es_ct[, 3],
  pval     = es_ct[, 4]
)
es_coefs[, event_time := as.integer(gsub(".*::", "", term))]
es_coefs <- es_coefs[!is.na(event_time)][order(event_time)]

## Add reference period
es_coefs <- rbind(
  es_coefs,
  data.table(term = "ref", estimate = 0, se = 0, tval = NA, pval = NA,
             event_time = -1L)
)
es_coefs <- es_coefs[order(event_time)]

cat("\nEvent-time coefficients:\n")
print(es_coefs[, .(event_time, estimate, se, pval)])

## ---------------------------------------------------------------
## 4. Callaway-Sant'Anna (sampled)
## ---------------------------------------------------------------
cat("\n=== Callaway-Sant'Anna ===\n")

set.seed(20260331)
treated_ids <- unique(panel[treat_group > 0, crossing_id])
control_ids <- unique(panel[treat_group == 0, crossing_id])
n_controls  <- min(length(control_ids), length(treated_ids) * 10)
sampled_controls <- sample(control_ids, n_controls)
cs_sample <- panel[crossing_id %in% c(treated_ids, sampled_controls)]
cs_sample <- cs_sample[!is.na(county_fips)]
cs_sample[, id := as.integer(factor(crossing_id))]
cs_sample[, g := as.integer(treat_group)]

cat("CS sample:", uniqueN(cs_sample$crossing_id), "crossings\n")

cs_out <- att_gt(
  yname  = "any_accident",
  tname  = "year",
  idname = "id",
  gname  = "g",
  data   = as.data.frame(cs_sample),
  control_group = "nevertreated",
  base_period   = "universal",
  cores         = 4
)

cs_overall <- aggte(cs_out, type = "simple")
cat("\nCS overall ATT:", cs_overall$overall.att,
    "(SE:", cs_overall$overall.se, ")\n")

cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -10, max_e = 10)
cat("\nCS dynamic (event-time) ATTs:\n")
print(data.frame(e = cs_dynamic$egt, att = cs_dynamic$att.egt,
                 se = cs_dynamic$se.egt))

## ---------------------------------------------------------------
## 5. Save results
## ---------------------------------------------------------------
save(m1_twfe, m2_twfe, m3_cas, m4_killed, m5_injured,
     es_sunab, es_coefs, cs_out, cs_overall, cs_dynamic,
     summ, sd_any_acc, sd_any_cas, sd_acc_count,
     file = "../data/main_results.RData")

## Write diagnostics.json
n_treated <- uniqueN(panel[treat_group > 0, crossing_id])
n_pre <- length(unique(panel[year < 2005, year]))
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre     = n_pre,
  n_obs     = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("  n_treated:", n_treated, "\n")
cat("  n_pre:", n_pre, "\n")
cat("  n_obs:", n_obs, "\n")
