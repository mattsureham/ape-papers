# =============================================================================
# 03_main_analysis.R — Primary DiD and event study estimation
# apep_0965: EU Retaliatory Tariffs and US County Employment
# =============================================================================

source("00_packages.R")

panel <- fread("../data/county_panel_balanced.csv")
panel[, yq_factor := factor(paste0(year, "Q", quarter))]
panel[, fips := factor(fips)]

message(sprintf("Analysis sample: %s obs, %d counties",
                format(nrow(panel), big.mark = ","),
                panel[, uniqueN(fips)]))

# ---------------------------------------------------------------------------
# 1. Static DiD: Continuous treatment
# Y_ct = alpha_c + gamma_t + beta * Exposure_c * Post_t + eps
# ---------------------------------------------------------------------------

# Main outcome: total manufacturing employment
static_emp <- feols(log_emp ~ exposure_share:post | fips + yq_factor,
                    data = panel, cluster = ~state_fips)

# Targeted industry employment
static_targeted <- feols(log_emp_targeted ~ exposure_share:post | fips + yq_factor,
                         data = panel, cluster = ~state_fips)

# Hires
static_hira <- feols(log_hira ~ exposure_share:post | fips + yq_factor,
                     data = panel, cluster = ~state_fips)

# Separations
static_sep <- feols(log_sep ~ exposure_share:post | fips + yq_factor,
                    data = panel, cluster = ~state_fips)

message("=== STATIC DiD RESULTS ===")
message(sprintf("Total mfg emp:    β = %.4f (SE = %.4f), p = %.4f",
                coef(static_emp), se(static_emp), pvalue(static_emp)))
message(sprintf("Targeted emp:     β = %.4f (SE = %.4f), p = %.4f",
                coef(static_targeted), se(static_targeted), pvalue(static_targeted)))
message(sprintf("Total hires:      β = %.4f (SE = %.4f), p = %.4f",
                coef(static_hira), se(static_hira), pvalue(static_hira)))
message(sprintf("Total seps:       β = %.4f (SE = %.4f), p = %.4f",
                coef(static_sep), se(static_sep), pvalue(static_sep)))

# ---------------------------------------------------------------------------
# 2. Event Study: Dynamic specification
# Y_ct = alpha_c + gamma_t + sum_k beta_k * Exposure_c * 1(t=k) + eps
# Reference period: 2018Q2 (rel_time = -1)
# ---------------------------------------------------------------------------

# Create relative time indicators interacted with exposure
panel[, rel_time_f := factor(rel_time)]

# Event study for total manufacturing employment
es_emp <- feols(log_emp ~ i(rel_time, exposure_share, ref = -1) | fips + yq_factor,
                data = panel, cluster = ~state_fips)

# Event study for targeted industry employment
es_targeted <- feols(log_emp_targeted ~ i(rel_time, exposure_share, ref = -1) | fips + yq_factor,
                     data = panel, cluster = ~state_fips)

message("=== EVENT STUDY RESULTS (total mfg employment) ===")
message("Pre-treatment coefficients (should be ~0):")
es_coefs <- coef(es_emp)
es_se <- se(es_emp)
pre_coefs <- es_coefs[grep("rel_time::-", names(es_coefs))]
message(sprintf("  Max absolute pre-trend: %.4f", max(abs(pre_coefs))))

# ---------------------------------------------------------------------------
# 3. Save results for tables
# ---------------------------------------------------------------------------

# Store key results
results <- list(
  static_emp = static_emp,
  static_targeted = static_targeted,
  static_hira = static_hira,
  static_sep = static_sep,
  es_emp = es_emp,
  es_targeted = es_targeted
)

saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------------------
# 4. Diagnostics JSON
# ---------------------------------------------------------------------------
n_treated <- panel[exposure_share > 0, uniqueN(fips)]
n_pre <- panel[post == 0, uniqueN(yq_factor)]
n_obs <- nrow(panel)

# Pre-treatment SD(Y) for SDE calculation
pre_panel <- panel[post == 0]
sd_log_emp <- sd(pre_panel$log_emp, na.rm = TRUE)
sd_log_emp_targeted <- sd(pre_panel$log_emp_targeted, na.rm = TRUE)
sd_log_hira <- sd(pre_panel$log_hira, na.rm = TRUE)
sd_log_sep <- sd(pre_panel$log_sep, na.rm = TRUE)

# SD of exposure for continuous treatment SDE
sd_exposure <- sd(panel[post == 0, .(exposure_share = first(exposure_share)), by = fips]$exposure_share)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = panel[, uniqueN(fips)],
  n_quarters = panel[, uniqueN(yq_factor)],
  sd_log_emp = sd_log_emp,
  sd_log_emp_targeted = sd_log_emp_targeted,
  sd_log_hira = sd_log_hira,
  sd_log_sep = sd_log_sep,
  sd_exposure = sd_exposure,
  beta_emp = as.numeric(coef(static_emp)),
  se_emp = as.numeric(se(static_emp)),
  beta_targeted = as.numeric(coef(static_targeted)),
  se_targeted = as.numeric(se(static_targeted)),
  beta_hira = as.numeric(coef(static_hira)),
  se_hira = as.numeric(se(static_hira)),
  beta_sep = as.numeric(coef(static_sep)),
  se_sep = as.numeric(se(static_sep))
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
message("Saved diagnostics.json")
