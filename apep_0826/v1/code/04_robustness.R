# =============================================================================
# 04_robustness.R — Robustness checks and event study
# =============================================================================

source("00_packages.R")

cat("=== Loading data ===\n")
panel <- read_csv("../data/analysis_panel.csv.gz", show_col_types = FALSE)
panel_ind <- read_csv("../data/panel_by_industry.csv.gz", show_col_types = FALSE) %>%
  filter(year >= 2011, year <= 2019)

# --- 1. Proper Event Study ---
cat("=== Event Study (proper extraction) ===\n")

panel <- panel %>%
  mutate(rel_q_binned = pmax(pmin(rel_quarter, 12), -8))

es_model <- feols(log_emp ~ i(rel_q_binned, coal_share, ref = -1) |
                    county_id + time_q,
                  data = panel, cluster = ~state_fips)

# Use fixest's coeftable for proper extraction
es_ct <- coeftable(es_model)
es_coefs <- data.frame(
  coef_name = rownames(es_ct),
  estimate = es_ct[, "Estimate"],
  se = es_ct[, "Std. Error"],
  stringsAsFactors = FALSE
) %>%
  mutate(
    rel_quarter = as.numeric(gsub("rel_q_binned::(-?\\d+):coal_share", "\\1", coef_name)),
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  ) %>%
  filter(!is.na(rel_quarter)) %>%
  arrange(rel_quarter)

# Add reference period (0 by construction)
es_coefs <- bind_rows(
  es_coefs,
  data.frame(coef_name = "ref", estimate = 0, se = 0,
             rel_quarter = -1, ci_lo = 0, ci_hi = 0)
) %>%
  arrange(rel_quarter)

cat("Event study coefficients:\n")
print(es_coefs %>% select(rel_quarter, estimate, se, ci_lo, ci_hi))
write_csv(es_coefs, "../data/event_study_coefs.csv")

# Pre-trend test: F-test for joint significance of pre-period coefficients
pre_coefs <- es_coefs %>% filter(rel_quarter < -1 & rel_quarter >= -8)
if (nrow(pre_coefs) > 0) {
  f_stat <- sum(pre_coefs$estimate^2 / pre_coefs$se^2) / nrow(pre_coefs)
  p_val <- 1 - pf(f_stat, nrow(pre_coefs), es_model$nobs - length(coef(es_model)))
  cat(sprintf("Pre-trend F-test: F = %.3f, p = %.4f\n", f_stat, p_val))
}

# --- 2. Triple Difference: Coal (212) vs Oil/Gas (211) ---
cat("\n=== Triple Difference: Coal vs Oil/Gas ===\n")

panel_ddd <- panel_ind %>%
  filter(industry %in% c("211", "212")) %>%
  mutate(
    time_q = year + (quarter - 1) / 4,
    post = as.integer(time_q >= 2014.5),
    is_coal_ind = as.integer(industry == "212"),
    log_emp = log(pmax(emp, 1)),
    county_industry = paste0(geography, "_", industry)
  )

# DDD: county-industry FE + time FE + is_coal × post
m_ddd <- feols(log_emp ~ is_coal_ind:post | county_industry + time_q,
               data = panel_ddd, cluster = ~state_fips)

cat(sprintf("  DDD (Coal×Post): β = %.4f (SE = %.4f)\n",
            coef(m_ddd)["is_coal_ind:post"], se(m_ddd)["is_coal_ind:post"]))

# --- 3. Exclude Phase-In Quarter (Q3 2014) ---
cat("\n=== Robustness: Exclude Q3 2014 ===\n")

panel_no_q3 <- panel %>% filter(!(year == 2014 & quarter == 3))
m_no_q3 <- feols(log_emp ~ treatment | county_id + time_q,
                 data = panel_no_q3, cluster = ~state_fips)
cat(sprintf("  Excluding Q3 2014: β = %.4f (SE = %.4f)\n",
            coef(m_no_q3)["treatment"], se(m_no_q3)["treatment"]))

# --- 4. Restrict to Coal vs Non-Mining Counties ---
cat("\n=== Robustness: Pre-2014 Window Only ===\n")

# Falsification: restrict to 2011-2013 (all pre-treatment)
panel_pre <- panel %>% filter(year <= 2013) %>%
  mutate(fake_post = as.integer(time_q >= 2012.5),
         fake_treatment = coal_share * fake_post)

m_placebo <- feols(log_emp ~ fake_treatment | county_id + time_q,
                   data = panel_pre, cluster = ~state_fips)
cat(sprintf("  Placebo (fake 2012Q3 cutoff): β = %.4f (SE = %.4f)\n",
            coef(m_placebo)["fake_treatment"], se(m_placebo)["fake_treatment"]))

# --- 5. Coal Price Sensitivity ---
cat("\n=== Coal Price Interaction ===\n")

m_price <- feols(log_emp ~ treatment + coal_price_x_share + oil_price_x_share |
                   county_id + time_q,
                 data = panel, cluster = ~state_fips)
cat(sprintf("  With price controls: β = %.4f (SE = %.4f)\n",
            coef(m_price)["treatment"], se(m_price)["treatment"]))
cat(sprintf("  Coal price × share: β = %.4f (SE = %.4f)\n",
            coef(m_price)["coal_price_x_share"], se(m_price)["coal_price_x_share"]))

# --- 6. Heterogeneity: Underground vs Surface ---
cat("\n=== Appalachian vs Western Coal Counties ===\n")

# Appalachian states: WV (54), KY (21), VA (51), PA (42), OH (39), TN (47), AL (01), MD (24)
appalachian_fips <- c(54, 21, 51, 42, 39, 47, 1, 24)

panel_app <- panel %>% filter(state_fips %in% appalachian_fips)
panel_west <- panel %>% filter(!state_fips %in% appalachian_fips)

m_app <- feols(log_emp ~ treatment | county_id + time_q,
               data = panel_app, cluster = ~state_fips)
m_west <- feols(log_emp ~ treatment | county_id + time_q,
                data = panel_west, cluster = ~state_fips)

cat(sprintf("  Appalachian: β = %.4f (SE = %.4f), n = %d\n",
            coef(m_app)["treatment"], se(m_app)["treatment"], nrow(panel_app)))
cat(sprintf("  Non-Appalachian: β = %.4f (SE = %.4f), n = %d\n",
            coef(m_west)["treatment"], se(m_west)["treatment"], nrow(panel_west)))

# Save all robustness models
saveRDS(list(
  es_model = es_model,
  m_ddd = m_ddd,
  m_no_q3 = m_no_q3,
  m_placebo = m_placebo,
  m_price = m_price,
  m_app = m_app,
  m_west = m_west
), "../data/robustness_models.rds")

cat("\n=== Robustness Complete ===\n")
