## 04_robustness.R — Robustness checks and mechanism tests
## apep_0981: Good Samaritan Laws and Opioid Treatment Entry

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ============================================================================
# 1. TRIPLE-DIFFERENCE: BUP vs OPIOID × PRE/POST GSL
# ============================================================================
# The opioid placebo also trends up (likely Medicaid expansion).
# DDD isolates the GSL-specific channel (buprenorphine grows MORE than opioid).

cat("=== 1. Triple-Difference (DDD) ===\n")

# Stack long panel: state × year × drug_type
bup_long <- panel[, .(state, year, state_id, first_treat, treated,
                        log_rx = log_bup_rx, drug_type = "buprenorphine")]
opi_long <- panel[, .(state, year, state_id, first_treat, treated,
                        log_rx = log_opioid_rx, drug_type = "opioid_placebo")]
ddd_panel <- rbind(bup_long, opi_long)
ddd_panel[, is_bup := as.integer(drug_type == "buprenorphine")]

# DDD: treated × is_bup interaction
ddd_fit <- feols(log_rx ~ treated * is_bup | state_id + year + drug_type,
                  data = ddd_panel, cluster = ~state_id)
cat("DDD: GSL × Buprenorphine interaction:\n")
print(summary(ddd_fit))

# ============================================================================
# 2. MEDICAID EXPANSION CONTROL
# ============================================================================
cat("\n=== 2. Controlling for Medicaid Expansion ===\n")

# Medicaid expansion dates (ACA, state adoption)
med_exp <- data.table(
  state = c("AZ","AR","CA","CO","CT","DC","DE","HI","IL","IN",
            "IA","KY","MD","MA","MI","MN","MT","NV","NH","NJ",
            "NM","NY","ND","OH","OR","PA","RI","VT","WA","WV",
            "AK","LA","VA","ME","ID","NE","MO","OK","SD"),
  med_exp_year = c(2014,2014,2014,2014,2010,2014,2014,2014,2014,2015,
                    2014,2014,2014,2006,2014,2014,2016,2014,2014,2014,
                    2014,2014,2014,2014,2014,2015,2014,2014,2014,2014,
                    2015,2016,2019,2019,2020,2020,2021,2021,2024)
)

panel <- merge(panel, med_exp, by = "state", all.x = TRUE)
panel[is.na(med_exp_year), med_exp_year := 9999]  # never expanded
panel[, medicaid_expanded := as.integer(year >= med_exp_year)]

# TWFE with Medicaid expansion control
twfe_bup_med <- feols(log_bup_rx ~ treated + medicaid_expanded | state_id + year,
                       data = panel, cluster = ~state_id)
cat("TWFE with Medicaid expansion control:\n")
print(summary(twfe_bup_med))

# CS with Medicaid expansion as covariate
cs_bup_med <- att_gt(
  yname = "log_bup_rx",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  xformla = ~ medicaid_expanded,
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)
cs_att_med <- aggte(cs_bup_med, type = "simple", na.rm = TRUE)
cat("\nCS ATT with Medicaid expansion control:\n")
print(summary(cs_att_med))

# ============================================================================
# 3. NALOXONE ACCESS LAW CONTROL
# ============================================================================
cat("\n=== 3. Controlling for Naloxone Access Laws ===\n")

# Naloxone access law adoption dates (from PDAPS)
nal_dates <- data.table(
  state = c("NM","WA","CT","RI","NY","CA","CO","IL","NC","OR",
            "VT","WI","NJ","MA","OH","PA","TN","MD","UT","VA",
            "DE","OK","AR","FL","GA","HI","IN","KY","LA","MN",
            "MT","NV","NH","SC","WV","AK","AL","AZ","IA","ID",
            "ME","MI","MO","MS","NE","ND","SD","TX","WY"),
  nal_year = c(2001,2010,2011,2012,2006,2008,2013,2010,2013,2013,
               2013,2014,2013,2012,2014,2014,2014,2013,2014,2013,
               2014,2013,2015,2015,2014,2014,2015,2015,2014,2014,
               2015,2015,2015,2015,2015,2016,2015,2017,2016,2015,
               2014,2014,2017,2016,2017,2016,2016,2015,2018)
)

panel <- merge(panel, nal_dates, by = "state", all.x = TRUE)
panel[is.na(nal_year), nal_year := 9999]
panel[, naloxone_law := as.integer(year >= nal_year)]

# TWFE with both controls
twfe_both <- feols(log_bup_rx ~ treated + medicaid_expanded + naloxone_law |
                     state_id + year, data = panel, cluster = ~state_id)
cat("TWFE with Medicaid + Naloxone controls:\n")
print(summary(twfe_both))

# ============================================================================
# 4. BACON DECOMPOSITION (TWFE DIAGNOSTICS)
# ============================================================================
cat("\n=== 4. Goodman-Bacon Decomposition ===\n")

tryCatch({
  if (requireNamespace("bacondecomp", quietly = TRUE)) {
    library(bacondecomp)
    # Need balanced panel for Bacon decomposition
    panel_bal <- panel[, .N, by = state_id][N == max(N)]
    panel_bacon <- panel[state_id %in% panel_bal$state_id]
    bacon_out <- bacon(log_bup_rx ~ treated, data = as.data.frame(panel_bacon),
                        id_var = "state_id", time_var = "year")
    cat("Bacon decomposition:\n")
    print(summary(bacon_out))
  }
}, error = function(e) {
  cat(sprintf("  Bacon decomposition skipped: %s\n", e$message))
  cat("  TWFE (0.14) vs CS ATT (0.62): gap suggests heterogeneous TE weighting.\n")
})

# ============================================================================
# 5. ALTERNATIVE SPECIFICATIONS
# ============================================================================
cat("\n=== 5. Alternative Specifications ===\n")

# 5a. Level outcome (not logged)
cat("5a. Level outcome (bup_rx in levels):\n")
twfe_level <- feols(bup_rx ~ treated | state_id + year, data = panel,
                     cluster = ~state_id)
print(summary(twfe_level))

# 5b. Asinh transformation
panel[, asinh_bup := asinh(bup_rx)]
twfe_asinh <- feols(asinh_bup ~ treated | state_id + year, data = panel,
                     cluster = ~state_id)
cat("\n5b. Asinh(bup_rx):\n")
print(summary(twfe_asinh))

# 5c. Per-capita rate
twfe_percap <- feols(log_bup_rate ~ treated | state_id + year, data = panel,
                      cluster = ~state_id)
cat("\n5c. Log bup rate/100K:\n")
print(summary(twfe_percap))

# ============================================================================
# 6. SENSITIVITY TO SAMPLE PERIOD
# ============================================================================
cat("\n=== 6. Sample Period Sensitivity ===\n")

# Exclude COVID years (2020-2022)
panel_precovid <- panel[year <= 2019]
cs_precovid <- att_gt(
  yname = "log_bup_rx",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel_precovid),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)
cs_att_precovid <- aggte(cs_precovid, type = "simple")
cat("CS ATT (pre-COVID, 2006-2019):\n")
print(summary(cs_att_precovid))

# Exclude early adopters (2007-2011) — potential selection
panel_post2012 <- panel[first_treat == 0 | first_treat >= 2012]
cs_post2012 <- att_gt(
  yname = "log_bup_rx",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel_post2012),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)
cs_att_post2012 <- aggte(cs_post2012, type = "simple")
cat("\nCS ATT (excluding early adopters, cohorts 2012+):\n")
print(summary(cs_att_post2012))

# ============================================================================
# 7. HETEROGENEITY
# ============================================================================
cat("\n=== 7. Heterogeneity ===\n")

# By Medicaid expansion status
panel[, expansion_state := as.integer(med_exp_year <= 2015)]

# Expansion states
panel_exp <- panel[expansion_state == 1]
panel_noexp <- panel[expansion_state == 0]

cs_exp <- att_gt(
  yname = "log_bup_rx", tname = "year", idname = "state_id",
  gname = "first_treat", data = as.data.frame(panel_exp),
  control_group = "notyettreated", anticipation = 0,
  est_method = "dr", base_period = "universal"
)
cs_att_exp <- aggte(cs_exp, type = "simple")
cat("CS ATT (Medicaid expansion states):\n")
print(summary(cs_att_exp))

if (uniqueN(panel_noexp$first_treat) >= 2) {
  cs_noexp <- att_gt(
    yname = "log_bup_rx", tname = "year", idname = "state_id",
    gname = "first_treat", data = as.data.frame(panel_noexp),
    control_group = "notyettreated", anticipation = 0,
    est_method = "dr", base_period = "universal"
  )
  cs_att_noexp <- aggte(cs_noexp, type = "simple")
  cat("\nCS ATT (non-expansion states):\n")
  print(summary(cs_att_noexp))
} else {
  cat("\nToo few non-expansion cohorts for separate CS estimation.\n")
  # Use TWFE for non-expansion states
  twfe_noexp <- feols(log_bup_rx ~ treated | state_id + year,
                       data = panel_noexp, cluster = ~state_id)
  cat("TWFE (non-expansion states):\n")
  print(summary(twfe_noexp))
}

# ============================================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================================
robust_results <- list(
  ddd = ddd_fit,
  twfe_med = twfe_bup_med,
  cs_att_med = cs_att_med,
  twfe_both = twfe_both,
  twfe_level = twfe_level,
  twfe_asinh = twfe_asinh,
  cs_att_precovid = cs_att_precovid,
  cs_att_post2012 = cs_att_post2012,
  cs_att_exp = cs_att_exp
)
saveRDS(robust_results, file.path(data_dir, "robust_results.rds"))

# Save updated panel (with controls)
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
