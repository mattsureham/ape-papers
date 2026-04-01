# =============================================================================
# 03_main_analysis.R — Event-study DiD for HBCU PLUS loan shock
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
treatment <- readRDS("../data/treatment.rds")
first_stage <- readRDS("../data/first_stage.rds")

# ---- Summary statistics ----
message("=== Summary Statistics ===")
message(sprintf("Total county-quarter obs: %s", format(nrow(panel), big.mark = ",")))
message(sprintf("Unique counties: %d", n_distinct(panel$county_fips)))
message(sprintf("HBCU counties: %d", n_distinct(panel$county_fips[panel$hbcu_county == 1])))
message(sprintf("Quarters: %d (%s to %s)",
                n_distinct(panel$yq),
                min(panel$yq), max(panel$yq)))
message(sprintf("Enrollment peak (2011): %s",
                format(first_stage$total_enrollment[first_stage$year == 2011], big.mark = ",")))
message(sprintf("Enrollment trough (2015): %s (%.1f%%)",
                format(first_stage$total_enrollment[first_stage$year == 2015], big.mark = ","),
                first_stage$pct_change[first_stage$year == 2015]))

# ---- 1. Main event study: Continuous treatment ----
# Y_{ct} = alpha_c + gamma_{st} + sum_k beta_k * (HBCUShare_c * D_k) + eps
# Reference period: 2012Q2 (event_q = -1)
panel <- panel %>%
  mutate(event_q_factor = relevel(factor(event_q), ref = as.character(-1)))

es_cont <- feols(
  log_emp ~ i(event_q, hbcu_share, ref = -1) |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)
summary(es_cont)

# ---- 2. Binary treatment event study ----
es_binary <- feols(
  log_emp ~ i(event_q, hbcu_county, ref = -1) |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)
summary(es_binary)

# ---- 3. Static DiD (collapsed pre/post) ----
did_static <- feols(
  log_emp ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)
summary(did_static)

# Binary
did_static_binary <- feols(
  log_emp ~ hbcu_county:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)
summary(did_static_binary)

# ---- 4. Earnings ----
did_earn <- feols(
  log_earn ~ hbcu_share:post |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)
summary(did_earn)

es_earn <- feols(
  log_earn ~ i(event_q, hbcu_share, ref = -1) |
    county_fips + state_fips^quarter + year^quarter,
  data = panel,
  cluster = ~state_fips
)

# ---- 5. County-level first-stage regression ----
# Show that counties with higher pre-shock HBCU enrollment share
# experienced larger enrollment declines (2011 to 2015)
hbcu_county_enroll <- readRDS("../data/hbcu_county_enrollment.rds")

# Compute county-level enrollment change: 2011 vs 2015
county_enroll_change <- hbcu_county_enroll %>%
  filter(year %in% c(2011, 2015)) %>%
  pivot_wider(names_from = year, values_from = hbcu_enrollment,
              names_prefix = "enroll_") %>%
  filter(!is.na(enroll_2011) & enroll_2011 > 0 & !is.na(enroll_2015)) %>%
  mutate(
    enroll_change = enroll_2015 - enroll_2011,
    enroll_pct_change = 100 * (enroll_2015 - enroll_2011) / enroll_2011,
    county_fips_chr = sprintf("%05d", abs(county_fips))
  )

# Merge with treatment to get pre-shock HBCU share
county_enroll_change <- county_enroll_change %>%
  left_join(treatment %>% select(county_fips, hbcu_share),
            by = c("county_fips_chr" = "county_fips"))

# First-stage regression: enrollment change per county employment on HBCU share
# This is the economically relevant first stage: the DiD treatment is enrollment/emp,
# so we need the enrollment *change* scaled by county employment to load on HBCU share.
county_enroll_change <- county_enroll_change %>%
  mutate(enroll_change_per_emp = (enroll_2015 - enroll_2011) / treatment$emp_pre[match(county_fips_chr, treatment$county_fips)])

first_stage_reg <- lm(enroll_change_per_emp ~ hbcu_share, data = county_enroll_change)
summary(first_stage_reg)
message(sprintf("\n=== First-Stage Regression ==="))
message(sprintf("Counties with higher HBCU share experienced larger enrollment-per-emp declines:"))
message(sprintf("  Coef on HBCU share: %.4f (SE = %.4f, p = %.4f)",
                coef(first_stage_reg)["hbcu_share"],
                summary(first_stage_reg)$coefficients["hbcu_share", "Std. Error"],
                summary(first_stage_reg)$coefficients["hbcu_share", "Pr(>|t|)"]))
message(sprintf("  R-squared: %.3f", summary(first_stage_reg)$r.squared))
message(sprintf("  N counties: %d", nrow(county_enroll_change)))

saveRDS(first_stage_reg, "../data/first_stage_reg.rds")

# ---- 6. Save results ----
saveRDS(es_cont, "../data/es_cont.rds")
saveRDS(es_binary, "../data/es_binary.rds")
saveRDS(did_static, "../data/did_static.rds")
saveRDS(did_static_binary, "../data/did_static_binary.rds")
saveRDS(did_earn, "../data/did_earn.rds")
saveRDS(es_earn, "../data/es_earn.rds")

# ---- 7. Write diagnostics ----
n_treated <- n_distinct(panel$county_fips[panel$hbcu_county == 1])
n_pre <- length(unique(panel$event_q[panel$event_q < 0]))
n_obs <- nrow(panel)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    n_clusters = n_distinct(panel$state_fips),
    n_counties_total = n_distinct(panel$county_fips),
    enrollment_peak = first_stage$total_enrollment[first_stage$year == 2011],
    enrollment_trough = first_stage$total_enrollment[first_stage$year == 2015],
    enrollment_decline_pct = round(first_stage$pct_change[first_stage$year == 2015], 1)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

message("Main analysis complete.")
