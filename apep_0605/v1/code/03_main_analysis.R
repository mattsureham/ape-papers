# =============================================================================
# 03_main_analysis.R — Main DiD analysis with Callaway-Sant'Anna
# apep_0605: Asymmetric Resource Curse in US Shale Counties
# =============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, fips := sprintf("%05s", as.character(fips))]
panel[, state_fips := substr(fips, 1, 2)]

cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$fips), "counties\n")
cat("Treated:", uniqueN(panel[shale == 1]$fips), "counties\n")
cat("Control:", uniqueN(panel[shale == 0]$fips), "counties\n")

# =============================================================================
# 1. CALLAWAY-SANT'ANNA: Total Employment
# =============================================================================

cat("\n=== CS-DiD: Log Total Employment ===\n")

cs_total <- att_gt(
  yname = "log_total_emp",
  tname = "year",
  idname = "county_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_fips",
  print_details = FALSE
)

# Overall ATT
agg_total <- aggte(cs_total, type = "simple")
cat("Overall ATT (log total employment):", round(agg_total$overall.att, 4),
    "(SE:", round(agg_total$overall.se, 4), ")\n")

# Dynamic effects (event study)
es_total <- aggte(cs_total, type = "dynamic", min_e = -10, max_e = 15)
cat("Event study estimated\n")

# =============================================================================
# 2. CS-DiD: Mining Employment
# =============================================================================

cat("\n=== CS-DiD: Log Mining Employment ===\n")

cs_mining <- att_gt(
  yname = "log_mining_emp",
  tname = "year",
  idname = "county_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_fips",
  print_details = FALSE
)

agg_mining <- aggte(cs_mining, type = "simple")
cat("Overall ATT (log mining employment):", round(agg_mining$overall.att, 4),
    "(SE:", round(agg_mining$overall.se, 4), ")\n")

es_mining <- aggte(cs_mining, type = "dynamic", min_e = -10, max_e = 15)

# =============================================================================
# 3. CS-DiD: Non-Mining Employment
# =============================================================================

cat("\n=== CS-DiD: Log Non-Mining Employment ===\n")

cs_nonmining <- att_gt(
  yname = "log_nonmining_emp",
  tname = "year",
  idname = "county_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_fips",
  print_details = FALSE
)

agg_nonmining <- aggte(cs_nonmining, type = "simple")
cat("Overall ATT (log non-mining employment):", round(agg_nonmining$overall.att, 4),
    "(SE:", round(agg_nonmining$overall.se, 4), ")\n")

es_nonmining <- aggte(cs_nonmining, type = "dynamic", min_e = -10, max_e = 15)

# =============================================================================
# 4. CS-DiD: Average Earnings
# =============================================================================

cat("\n=== CS-DiD: Log Average Earnings ===\n")

cs_earnings <- att_gt(
  yname = "log_earnings",
  tname = "year",
  idname = "county_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_fips",
  print_details = FALSE
)

agg_earnings <- aggte(cs_earnings, type = "simple")
cat("Overall ATT (log earnings):", round(agg_earnings$overall.att, 4),
    "(SE:", round(agg_earnings$overall.se, 4), ")\n")

es_earnings <- aggte(cs_earnings, type = "dynamic", min_e = -10, max_e = 15)

# =============================================================================
# 5. FORMAL ASYMMETRY TEST
# =============================================================================

cat("\n=== Asymmetry Test ===\n")

# Extract event study coefficients for total employment
es_df <- data.table(
  event_time = es_total$egt,
  att = es_total$att.egt,
  se = es_total$se.egt
)

# Boom phase: event times 0 to 8 (treatment onset through peak ~2014 for median play)
# Bust phase: event times 9+ (2015 onwards for median play)
boom_atts <- es_df[event_time >= 0 & event_time <= 8]
bust_atts <- es_df[event_time > 8]

boom_avg <- mean(boom_atts$att, na.rm = TRUE)
bust_avg <- mean(bust_atts$att, na.rm = TRUE)

cat("Average boom ATT (e=0 to 8):", round(boom_avg, 4), "\n")
cat("Average bust ATT (e=9+):", round(bust_avg, 4), "\n")
cat("Ratio bust/boom:", round(bust_avg / boom_avg, 3), "\n")

# Use aggte to get calendar-time aggregation for formal test
cal_total <- aggte(cs_total, type = "calendar")

# =============================================================================
# 6. FIXEST TWFE (for comparison and additional specifications)
# =============================================================================

cat("\n=== TWFE Comparison ===\n")

# Simple TWFE (for reference — known to be biased with staggered treatment)
twfe_total <- feols(log_total_emp ~ shale_x_price | county_id + year,
                    data = panel, cluster = ~state_fips)
cat("TWFE (shale × price):", round(coef(twfe_total)["shale_x_price"], 6),
    "(SE:", round(se(twfe_total)["shale_x_price"], 6), ")\n")

twfe_mining <- feols(log_mining_emp ~ shale_x_price | county_id + year,
                     data = panel, cluster = ~state_fips)
cat("TWFE mining:", round(coef(twfe_mining)["shale_x_price"], 6),
    "(SE:", round(se(twfe_mining)["shale_x_price"], 6), ")\n")

twfe_nonmining <- feols(log_nonmining_emp ~ shale_x_price | county_id + year,
                        data = panel, cluster = ~state_fips)
cat("TWFE non-mining:", round(coef(twfe_nonmining)["shale_x_price"], 6),
    "(SE:", round(se(twfe_nonmining)["shale_x_price"], 6), ")\n")

twfe_earnings <- feols(log_earnings ~ shale_x_price | county_id + year,
                       data = panel, cluster = ~state_fips)
cat("TWFE earnings:", round(coef(twfe_earnings)["shale_x_price"], 6),
    "(SE:", round(se(twfe_earnings)["shale_x_price"], 6), ")\n")

# =============================================================================
# 7. BOOM vs BUST SPLIT REGRESSION
# =============================================================================

cat("\n=== Boom vs Bust Split ===\n")

# Create boom/bust indicators (using oil price peak as cutpoint)
# WTI peaked ~2008 ($97) and 2014 ($93), crashed in 2015 ($49) and 2020 ($39)
panel[, boom_period := as.integer(year <= 2014)]
panel[, bust_period := as.integer(year > 2014)]
panel[, shale_x_boom := shale * boom_period]
panel[, shale_x_bust := shale * bust_period]

# Post-treatment only
panel[, post_treat := as.integer(first_treat > 0 & year >= first_treat)]
panel[, post_boom := post_treat * boom_period]
panel[, post_bust := post_treat * bust_period]

split_reg <- feols(log_total_emp ~ post_boom + post_bust | county_id + year,
                   data = panel, cluster = ~state_fips)
cat("Post × Boom:", round(coef(split_reg)["post_boom"], 4),
    "(SE:", round(se(split_reg)["post_boom"], 4), ")\n")
cat("Post × Bust:", round(coef(split_reg)["post_bust"], 4),
    "(SE:", round(se(split_reg)["post_bust"], 4), ")\n")

# Test for asymmetry: H0: β_boom = β_bust (symmetric effects)
# Use direct coefficient comparison
diff_coef <- coef(split_reg)["post_boom"] - coef(split_reg)["post_bust"]
V <- vcov(split_reg)
diff_se <- sqrt(V["post_boom","post_boom"] + V["post_bust","post_bust"] - 2*V["post_boom","post_bust"])
wald_stat <- (diff_coef / diff_se)^2
wald_p <- 1 - pchisq(wald_stat, 1)
cat("Difference (boom - bust):", round(diff_coef, 4),
    "(SE:", round(diff_se, 4), ")\n")
cat("Chi-sq test (boom = bust):", round(wald_stat, 3),
    "p =", round(wald_p, 4), "\n")

# =============================================================================
# 8. SAVE RESULTS AND DIAGNOSTICS
# =============================================================================

# Save event study results
es_results <- list(
  total = data.table(event_time = es_total$egt, att = es_total$att.egt,
                     se = es_total$se.egt, outcome = "total_emp"),
  mining = data.table(event_time = es_mining$egt, att = es_mining$att.egt,
                      se = es_mining$se.egt, outcome = "mining_emp"),
  nonmining = data.table(event_time = es_nonmining$egt, att = es_nonmining$att.egt,
                         se = es_nonmining$se.egt, outcome = "nonmining_emp"),
  earnings = data.table(event_time = es_earnings$egt, att = es_earnings$att.egt,
                        se = es_earnings$se.egt, outcome = "earnings")
)

es_combined <- rbindlist(es_results)
fwrite(es_combined, "../data/event_study_results.csv")

# Save model objects
save(cs_total, cs_mining, cs_nonmining, cs_earnings,
     es_total, es_mining, es_nonmining, es_earnings,
     agg_total, agg_mining, agg_nonmining, agg_earnings,
     twfe_total, twfe_mining, twfe_nonmining, twfe_earnings,
     split_reg, wald_stat, wald_p,
     boom_avg, bust_avg,
     file = "../data/main_results.RData")

# Diagnostics JSON for validation
diagnostics <- list(
  n_treated = uniqueN(panel[shale == 1]$fips),
  n_pre = length(unique(panel[shale == 1 & event_time < 0]$year)),
  n_obs = nrow(panel),
  n_counties = uniqueN(panel$fips),
  n_years = uniqueN(panel$year),
  n_cohorts = uniqueN(panel[first_treat > 0]$first_treat),
  att_total = round(agg_total$overall.att, 6),
  se_total = round(agg_total$overall.se, 6),
  att_mining = round(agg_mining$overall.att, 6),
  se_mining = round(agg_mining$overall.se, 6),
  boom_att = round(boom_avg, 6),
  bust_att = round(bust_avg, 6)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nResults saved.\n")
cat("Diagnostics:\n")
print(diagnostics)
