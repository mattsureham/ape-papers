# ==============================================================================
# 03_main_analysis.R — Primary DDD regressions + event study
# ==============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_balanced.rds")

# --- Create time variables ---
panel <- panel %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    # Relative quarter: 0 = 2018Q1 (reference), 2 = 2018Q3 (first post, skip Q2)
    rel_qtr = round((yq - 2018.0) * 4)
  )

# ============================================================================
# TABLE 2: Main DDD Results
# ============================================================================

cat("=== Main DDD Regressions ===\n\n")

# Column 1: DD — Info × Post (no geographic variation)
# FE: county + industry + yearqtr (additive — so info × post is identified)
m1 <- feols(log_emp ~ info_post | county_fips + naics2 + yearqtr,
            data = panel, cluster = ~state_fips)

cat(sprintf("DD (info × post): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m1)["info_post"], se(m1)["info_post"], pvalue(m1)["info_post"]))

# Columns 2-5: DDD — Info × Post × EU_Share
# FE: county × yearqtr + naics2 × yearqtr
# Lower-order terms (info_post, post_eu) are absorbed by these FE.
# info_eu varies by state × industry but not time, so also absorbed by county × yearqtr
# (since county determines state). Only the triple interaction is identified.

# Column 2: DDD for employment
m2 <- feols(log_emp ~ info_post_eu | county_fips^yearqtr + naics2^yearqtr,
            data = panel, cluster = ~state_fips)

# Column 3: DDD for hires
m3 <- feols(log_hira ~ info_post_eu | county_fips^yearqtr + naics2^yearqtr,
            data = panel, cluster = ~state_fips)

# Column 4: DDD for separations
m4 <- feols(log_sep ~ info_post_eu | county_fips^yearqtr + naics2^yearqtr,
            data = panel, cluster = ~state_fips)

# Column 5: DDD for earnings
m5 <- feols(log_earns ~ info_post_eu | county_fips^yearqtr + naics2^yearqtr,
            data = panel, cluster = ~state_fips)

cat(sprintf("  Employment DDD (β): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m2)["info_post_eu"], se(m2)["info_post_eu"], pvalue(m2)["info_post_eu"]))
cat(sprintf("  Hires DDD (β): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m3)["info_post_eu"], se(m3)["info_post_eu"], pvalue(m3)["info_post_eu"]))
cat(sprintf("  Separations DDD (β): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m4)["info_post_eu"], se(m4)["info_post_eu"], pvalue(m4)["info_post_eu"]))
cat(sprintf("  Earnings DDD (β): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m5)["info_post_eu"], se(m5)["info_post_eu"], pvalue(m5)["info_post_eu"]))

# ============================================================================
# EVENT STUDY: Quarter-by-Quarter DDD
# ============================================================================

cat("\n=== Event Study ===\n\n")

# Interact each relative quarter with info × eu_share
# Reference: rel_qtr = 0 (2018Q1)
# Create interaction variable for event study
panel$info_eu <- panel$info * panel$eu_share

es_model <- feols(
  log_emp ~ i(rel_qtr, info_eu, ref = 0) |
    county_fips^yearqtr + naics2^yearqtr,
  data = panel, cluster = ~state_fips
)

cat("Event study estimated.\n")

# ============================================================================
# BINARY TREATMENT DDD
# ============================================================================

cat("\n=== Binary Treatment & Subsector ===\n\n")

# Binary DDD: above/below median EU share
panel <- panel %>%
  mutate(
    info_post_high = info * post * eu_high
  )

m_binary <- feols(log_emp ~ info_post_high | county_fips^yearqtr + naics2^yearqtr,
                  data = panel, cluster = ~state_fips)

cat(sprintf("Binary treatment DDD: %.4f (SE: %.4f, p: %.4f)\n",
            coef(m_binary)["info_post_high"],
            se(m_binary)["info_post_high"],
            pvalue(m_binary)["info_post_high"]))

# 3-digit subsector test: data-intensive (518, 519, 511) vs others
qwi_3d <- readRDS("../data/qwi_3digit.rds")
qwi_3d_panel <- qwi_3d %>%
  left_join(readRDS("../data/trade_exposure.rds") %>% select(state_fips, eu_share),
            by = "state_fips") %>%
  filter(!is.na(eu_share)) %>%
  mutate(
    yq = year + (quarter - 1) / 4,
    post = (yq >= 2018.5),
    transition = (year == 2018 & quarter == 2),
    log_emp = log(Emp + 1),
    yearqtr = paste0(year, "Q", quarter),
    data_intensive = as.integer(naics3 %in% c("518", "519", "511")),
    post_data_eu = post * data_intensive * eu_share
  ) %>%
  filter(!transition, year >= 2016, yq <= 2020.0)

m_subsector <- feols(
  log_emp ~ post_data_eu | county_fips^yearqtr + naics3^yearqtr,
  data = qwi_3d_panel, cluster = ~state_fips
)

cat(sprintf("Data-intensive subsector DDD: %.4f (SE: %.4f, p: %.4f)\n",
            coef(m_subsector)["post_data_eu"],
            se(m_subsector)["post_data_eu"],
            pvalue(m_subsector)["post_data_eu"]))

# ============================================================================
# Save models and diagnostics
# ============================================================================

n_treated_states <- panel %>%
  filter(eu_high == 1) %>%
  pull(state_fips) %>%
  n_distinct()

n_pre <- panel %>%
  filter(!post) %>%
  pull(yearqtr) %>%
  n_distinct()

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$county_fips),
  n_states = n_distinct(panel$state_fips),
  n_quarters = n_distinct(panel$yearqtr),
  dd_coef_emp = unname(coef(m1)["info_post"]),
  dd_se_emp = unname(se(m1)["info_post"]),
  ddd_coef_emp = unname(coef(m2)["info_post_eu"]),
  ddd_se_emp = unname(se(m2)["info_post_eu"]),
  ddd_coef_hires = unname(coef(m3)["info_post_eu"]),
  ddd_se_hires = unname(se(m3)["info_post_eu"]),
  ddd_coef_sep = unname(coef(m4)["info_post_eu"]),
  ddd_se_sep = unname(se(m4)["info_post_eu"]),
  ddd_coef_earn = unname(coef(m5)["info_post_eu"]),
  ddd_se_earn = unname(se(m5)["info_post_eu"]),
  binary_coef = unname(coef(m_binary)["info_post_high"]),
  binary_se = unname(se(m_binary)["info_post_high"]),
  subsector_coef = unname(coef(m_subsector)["post_data_eu"]),
  subsector_se = unname(se(m_subsector)["post_data_eu"])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
             es_model = es_model, m_binary = m_binary, m_subsector = m_subsector),
        "../data/main_models.rds")

cat("\nMain analysis complete. Diagnostics saved.\n")
