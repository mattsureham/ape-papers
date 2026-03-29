# ==============================================================================
# 03_main_analysis.R — Main DiD estimation
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_final.rds")

cat("Panel loaded:", nrow(panel), "rows\n")
cat("Counties:", uniqueN(panel$county_fips), "\n")

# ==============================================================================
# 1. CALLAWAY-SANT'ANNA ESTIMATION — Hispanic visible-sector employment share
# ==============================================================================

# Subset to Hispanic workers
hisp <- panel[ethnicity == "A2"]
cat("\nHispanic panel:", nrow(hisp), "rows\n")
cat("Treated counties:", uniqueN(hisp[activation_time_q > 0]$county_fips), "\n")
cat("Never-treated:", uniqueN(hisp[activation_time_q == 0]$county_fips), "\n")

# Create numeric county ID for did package
hisp[, county_id := as.integer(factor(county_fips))]

# --- Outcome 1: Visible-sector employment share ---
cat("\n=== Callaway-Sant'Anna: Hispanic Visible-Sector Employment Share ===\n")

cs_visible <- att_gt(
  yname = "emp_share_visible",
  tname = "time_q",
  idname = "county_id",
  gname = "activation_time_q",
  data = as.data.frame(hisp),
  control_group = "notyettreated",
  base_period = "universal",
  clustervars = "state_fips"
)

# Aggregate to event study
es_visible <- aggte(cs_visible, type = "dynamic", min_e = -8, max_e = 12)
cat("\nEvent study (visible share):\n")
summary(es_visible)

# Overall ATT
att_visible <- aggte(cs_visible, type = "simple")
cat("\nOverall ATT (visible share):\n")
summary(att_visible)

# Save results
saveRDS(cs_visible, "../data/cs_visible.rds")
saveRDS(es_visible, "../data/es_visible.rds")
saveRDS(att_visible, "../data/att_visible.rds")

# --- Outcome 2: Opaque-sector employment share ---
cat("\n=== Callaway-Sant'Anna: Hispanic Opaque-Sector Employment Share ===\n")

cs_opaque <- att_gt(
  yname = "emp_share_opaque",
  tname = "time_q",
  idname = "county_id",
  gname = "activation_time_q",
  data = as.data.frame(hisp),
  control_group = "notyettreated",
  base_period = "universal",
  clustervars = "state_fips"
)

es_opaque <- aggte(cs_opaque, type = "dynamic", min_e = -8, max_e = 12)
cat("\nEvent study (opaque share):\n")
summary(es_opaque)

att_opaque <- aggte(cs_opaque, type = "simple")
cat("\nOverall ATT (opaque share):\n")
summary(att_opaque)

saveRDS(cs_opaque, "../data/cs_opaque.rds")
saveRDS(es_opaque, "../data/es_opaque.rds")
saveRDS(att_opaque, "../data/att_opaque.rds")

# --- Outcome 3: Hispanic average earnings (visible sector) ---
cat("\n=== Callaway-Sant'Anna: Hispanic Visible-Sector Earnings ===\n")

# Only counties with positive visible employment
hisp_earn <- hisp[emp_visible > 0 & !is.na(earn_weighted_visible) &
                    is.finite(earn_weighted_visible)]

hisp_earn[, county_id_earn := as.integer(factor(county_fips))]
hisp_earn[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]

cs_earn <- att_gt(
  yname = "earn_weighted_visible",
  tname = "time_q",
  idname = "county_id_earn",
  gname = "activation_time_q",
  data = as.data.frame(hisp_earn),
  control_group = "notyettreated",
  base_period = "universal",
  clustervars = "state_fips"
)

att_earn <- aggte(cs_earn, type = "simple")
cat("\nOverall ATT (visible earnings):\n")
summary(att_earn)

saveRDS(cs_earn, "../data/cs_earn.rds")
saveRDS(att_earn, "../data/att_earn.rds")

# ==============================================================================
# 2. TWFE REGRESSIONS (for comparison and tables)
# ==============================================================================

cat("\n=== TWFE Regressions ===\n")

# Create post-treatment indicator
hisp[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]

# TWFE: visible share
twfe_visible <- feols(emp_share_visible ~ post | county_id + time_q,
                      data = hisp, vcov = ~state_fips)
cat("\nTWFE visible share:\n")
print(summary(twfe_visible))

# TWFE: opaque share
twfe_opaque <- feols(emp_share_opaque ~ post | county_id + time_q,
                     data = hisp, vcov = ~state_fips)
cat("\nTWFE opaque share:\n")
print(summary(twfe_opaque))

# TWFE: visible earnings
twfe_earn <- feols(earn_weighted_visible ~ post | county_id_earn + time_q,
                   data = hisp_earn, vcov = ~state_fips)
cat("\nTWFE visible earnings:\n")
print(summary(twfe_earn))

saveRDS(twfe_visible, "../data/twfe_visible.rds")
saveRDS(twfe_opaque, "../data/twfe_opaque.rds")
saveRDS(twfe_earn, "../data/twfe_earn.rds")

# ==============================================================================
# 3. PLACEBO: Non-Hispanic workers
# ==============================================================================

cat("\n=== PLACEBO: Non-Hispanic Workers ===\n")

nonhisp <- panel[ethnicity == "A1"]
nonhisp[, county_id := as.integer(factor(county_fips))]
nonhisp[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]

# TWFE: non-Hispanic visible share
twfe_nh_visible <- feols(emp_share_visible ~ post | county_id + time_q,
                         data = nonhisp, vcov = ~state_fips)
cat("\nTWFE non-Hispanic visible share:\n")
print(summary(twfe_nh_visible))

# TWFE: non-Hispanic opaque share
twfe_nh_opaque <- feols(emp_share_opaque ~ post | county_id + time_q,
                        data = nonhisp, vcov = ~state_fips)
cat("\nTWFE non-Hispanic opaque share:\n")
print(summary(twfe_nh_opaque))

saveRDS(twfe_nh_visible, "../data/twfe_nh_visible.rds")
saveRDS(twfe_nh_opaque, "../data/twfe_nh_opaque.rds")

# ==============================================================================
# 4. TRIPLE-DIFFERENCE
# ==============================================================================

cat("\n=== Triple-Difference: Hispanic vs Non-Hispanic × Visible vs Opaque ===\n")

# Stack Hispanic and non-Hispanic panels
panel_long <- panel[, .(county_fips, year, quarter, time_q, ethnicity,
                        total_emp, activation_time_q, state_fips,
                        emp_share_visible, emp_share_opaque)]

# Create interaction terms
panel_long[, hispanic := as.integer(ethnicity == "A2")]
panel_long[, post := as.integer(time_q >= activation_time_q & activation_time_q > 0)]
panel_long[, county_id := as.integer(factor(county_fips))]

# Triple-diff on visible share: Hispanic × Post × SC
# Y = visible_share, interactions: Hispanic × Post
twfe_ddd <- feols(emp_share_visible ~ hispanic:post + post:hispanic |
                    county_id^hispanic + time_q^hispanic,
                  data = panel_long, vcov = ~state_fips)
cat("\nTriple-diff (visible share, Hispanic × Post interaction):\n")

# Better: explicit triple-diff
twfe_ddd2 <- feols(emp_share_visible ~ post * hispanic |
                     county_id + time_q + county_id:hispanic + time_q:hispanic,
                   data = panel_long, vcov = ~state_fips)
cat("\nTriple-diff v2:\n")
print(summary(twfe_ddd2))

saveRDS(twfe_ddd2, "../data/twfe_ddd.rds")

# ==============================================================================
# 5. DIAGNOSTICS
# ==============================================================================

cat("\n=== Computing diagnostics ===\n")

n_treated <- uniqueN(hisp[activation_time_q > 0]$county_fips)
n_control <- uniqueN(hisp[activation_time_q == 0]$county_fips)

# Pre-periods: count quarters before earliest activation
earliest_activation <- min(hisp[activation_time_q > 0]$activation_time_q)
earliest_data <- min(hisp$time_q)
n_pre <- earliest_activation - earliest_data

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = as.integer(n_pre),
  n_obs = nrow(hisp),
  n_counties = uniqueN(hisp$county_fips),
  n_states = uniqueN(hisp$state_fips),
  att_visible = as.numeric(att_visible$overall.att),
  att_visible_se = as.numeric(att_visible$overall.se),
  att_opaque = as.numeric(att_opaque$overall.att),
  att_opaque_se = as.numeric(att_opaque$overall.se)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")
cat("  ATT visible share:", round(diagnostics$att_visible, 5),
    "(SE:", round(diagnostics$att_visible_se, 5), ")\n")
cat("  ATT opaque share:", round(diagnostics$att_opaque, 5),
    "(SE:", round(diagnostics$att_opaque_se, 5), ")\n")
