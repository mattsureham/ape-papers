## 03_main_analysis.R — Main DiD analysis
## apep_0987: EPA MATS Staggered Compliance and Infant Health

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

panel <- readRDS("panel_lbw.rds")
cat("Panel loaded:", nrow(panel), "obs,", n_distinct(panel$fips), "counties\n")

# Use CHR release year as the time variable (annual, 2012-2020)
# first_treat is the compliance wave year (2015, 2016, 2017) or 0 for never-treated

# Create numeric county ID for `did` package
panel <- panel %>%
  mutate(
    county_id = as.integer(factor(fips)),
    year = chr_year,  # Use CHR release year as time dimension
    lbw_pct = lbw_rate * 100  # Convert to percentage for readability
  )

cat("Year range:", range(panel$year), "\n")
cat("Treatment groups:", table(panel$first_treat), "\n")
cat("LBW mean:", round(mean(panel$lbw_pct, na.rm = TRUE), 2), "%\n")
cat("LBW SD:", round(sd(panel$lbw_pct, na.rm = TRUE), 2), "%\n")

# For CS-DiD: treatment timing must be in the same units as year variable
# CHR 2015 covers ~2009-2013 births → maps to data_year ~2011
# MATS Wave 1 compliance was April 2015, which would affect births starting ~late 2015
# CHR release year 2019 first captures post-MATS births (data_year ~2015)
# So treatment "year" in CHR release-year space:
#   Wave 1 (2015 compliance) → first affects CHR 2019 release (data year ~2015-2016)
#   Wave 2 (2016 compliance) → first affects CHR 2020 release (data year ~2016-2017)
#   Wave 3 (2017 compliance) → first affects CHR 2020+ release

# Map compliance wave to CHR release year when it first affects births
panel <- panel %>%
  mutate(
    first_treat_chr = case_when(
      first_treat == 2015 ~ 2019L,  # MATS 2015 → CHR 2019
      first_treat == 2016 ~ 2020L,  # MATS 2016 → CHR 2020
      first_treat == 2017 ~ 2020L,  # MATS 2017 → CHR 2020 (grouped with Wave 2 for power)
      first_treat == 0 ~ 0L         # Never-treated
    )
  )

cat("\nTreatment timing in CHR years:\n")
print(table(panel$first_treat_chr))

# ============================================================
# Model 1: TWFE DiD — LBW on exposure to coal plant compliance
# ============================================================
cat("\n=== Model 1: TWFE DiD ===\n")

# Create post-treatment indicator
panel <- panel %>%
  mutate(
    post = ifelse(first_treat_chr > 0 & year >= first_treat_chr, 1L, 0L),
    treated_ever = ifelse(first_treat_chr > 0, 1L, 0L)
  )

# TWFE regression
m1_twfe <- feols(lbw_pct ~ post | county_id + year, data = panel,
                 cluster = ~fips)
cat("TWFE result:\n")
summary(m1_twfe)

# ============================================================
# Model 2: Callaway-Sant'Anna DiD
# ============================================================
cat("\n=== Model 2: Callaway-Sant'Anna ===\n")

# CS-DiD requires: yname, tname, idname, gname
# gname = first treatment period (0 for never-treated)
cs_data <- panel %>%
  filter(!is.na(lbw_pct)) %>%
  arrange(county_id, year)

# Check panel balance
cat("Panel balance:\n")
print(table(table(cs_data$county_id)))

cs_out <- tryCatch({
  att_gt(
    yname = "lbw_pct",
    tname = "year",
    idname = "county_id",
    gname = "first_treat_chr",
    data = cs_data,
    control_group = "nevertreated",
    est_method = "dr",  # Doubly robust
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  # Try simpler specification
  att_gt(
    yname = "lbw_pct",
    tname = "year",
    idname = "county_id",
    gname = "first_treat_chr",
    data = cs_data,
    control_group = "nevertreated",
    est_method = "reg",
    base_period = "universal"
  )
})

cat("\nCS-DiD group-time ATTs:\n")
summary(cs_out)

# Aggregate to overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS-DiD Overall ATT:\n")
summary(cs_agg)

# Dynamic event study
cs_dynamic <- aggte(cs_out, type = "dynamic")
cat("\nCS-DiD Dynamic (event study):\n")
summary(cs_dynamic)

# ============================================================
# Model 3: Treatment intensity — distance gradient
# ============================================================
cat("\n=== Model 3: Distance gradient ===\n")

panel <- panel %>%
  mutate(
    near_25mi = dist_km <= 40,       # 0-25 miles
    near_50mi = dist_km <= 80.5,     # 0-50 miles
    far_50_100mi = dist_km > 80.5 & dist_km <= 161,  # 50-100 miles (placebo)
    post_near25 = post * near_25mi,
    post_near50 = post * near_50mi,
    inv_dist = ifelse(dist_km > 0, 1 / dist_km, 0),  # Inverse distance weight
    post_inv_dist = post * inv_dist
  )

# Continuous treatment intensity
m3_dist <- feols(lbw_pct ~ post_inv_dist | county_id + year, data = panel,
                 cluster = ~fips)
cat("Inverse-distance treatment intensity:\n")
summary(m3_dist)

# Distance bins
m3_bins <- feols(lbw_pct ~ i(post, near_25mi) + i(post, far_50_100mi) |
                   county_id + year,
                 data = panel %>% filter(near_50mi | far_50_100mi | !exposed),
                 cluster = ~fips)
cat("\nDistance bin effects:\n")
summary(m3_bins)

# ============================================================
# Model 4: Triple-difference — high vs low capacity exposure
# ============================================================
cat("\n=== Model 4: Triple-difference (capacity intensity) ===\n")

panel <- panel %>%
  mutate(
    high_cap = capacity_50mi > median(capacity_50mi[exposed], na.rm = TRUE),
    post_high_cap = post * high_cap
  )

m4_ddd <- feols(lbw_pct ~ post + post_high_cap | county_id + year,
                data = panel %>% filter(exposed | !treated_ever),
                cluster = ~fips)
cat("DDD result (high vs low capacity exposure):\n")
summary(m4_ddd)

# ============================================================
# Save results
# ============================================================
cat("\n=== Saving results ===\n")

results <- list(
  twfe = m1_twfe,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_dynamic = cs_dynamic,
  dist_intensity = m3_dist,
  dist_bins = m3_bins,
  ddd_capacity = m4_ddd
)
saveRDS(results, "main_results.rds")

# Write diagnostics.json
n_treated_counties <- n_distinct(panel$fips[panel$treated_ever == 1])
n_pre <- length(unique(panel$year[panel$year < min(panel$first_treat_chr[panel$first_treat_chr > 0])]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = n_distinct(panel$fips),
  n_years = n_distinct(panel$year),
  lbw_mean = mean(panel$lbw_pct, na.rm = TRUE),
  lbw_sd = sd(panel$lbw_pct, na.rm = TRUE),
  twfe_coef = coef(m1_twfe)["post"],
  twfe_se = se(m1_twfe)["post"],
  cs_att = cs_agg$overall.att,
  cs_se = cs_agg$overall.se
)
write_json(diagnostics, "diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics:\n")
cat("  n_treated:", n_treated_counties, "\n")
cat("  n_pre:", n_pre, "\n")
cat("  n_obs:", n_obs, "\n")
cat("  TWFE coef:", round(coef(m1_twfe)["post"], 4), "\n")
cat("  CS ATT:", round(cs_agg$overall.att, 4), "\n")

cat("\n=== Main analysis complete ===\n")
