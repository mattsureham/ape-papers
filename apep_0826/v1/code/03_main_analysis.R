# =============================================================================
# 03_main_analysis.R — Main DiD analysis
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- read_csv("../data/analysis_panel.csv.gz", show_col_types = FALSE)

# --- 1. Summary Statistics ---
cat("=== Summary Statistics ===\n")

# Pre-period means by coal dominance
pre_stats <- panel %>%
  filter(post == 0) %>%
  group_by(is_coal_county) %>%
  summarise(
    n_counties = n_distinct(county_id),
    mean_emp = mean(emp, na.rm = TRUE),
    mean_sep = mean(sep, na.rm = TRUE),
    mean_hir = mean(hir_new, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    mean_coal_share = mean(coal_share, na.rm = TRUE),
    .groups = "drop"
  )
print(pre_stats)

# --- 2. Main DiD: Continuous Treatment ---
cat("\n=== Main DiD Regressions ===\n")

# Specification 1: Basic — county FE + quarter FE
m1 <- feols(log_emp ~ treatment | county_id + time_q,
            data = panel, cluster = ~state_fips)

# Specification 2: Add coal price control
m2 <- feols(log_emp ~ treatment + coal_price_x_share | county_id + time_q,
            data = panel, cluster = ~state_fips)

# Specification 3: Add state-quarter FE (absorbs all state-level shocks)
m3 <- feols(log_emp ~ treatment | county_id + state_quarter,
            data = panel, cluster = ~state_fips)

# Specification 4: Separation rate as outcome
m4 <- feols(sep_rate ~ treatment | county_id + time_q,
            data = panel, cluster = ~state_fips)

# Specification 5: Log new hires
m5 <- feols(log_hir ~ treatment | county_id + time_q,
            data = panel, cluster = ~state_fips)

cat("Main results:\n")
cat(sprintf("  M1 (basic): β = %.4f (SE = %.4f)\n",
            coef(m1)["treatment"], se(m1)["treatment"]))
cat(sprintf("  M2 (+ coal price): β = %.4f (SE = %.4f)\n",
            coef(m2)["treatment"], se(m2)["treatment"]))
cat(sprintf("  M3 (state×quarter FE): β = %.4f (SE = %.4f)\n",
            coef(m3)["treatment"], se(m3)["treatment"]))
cat(sprintf("  M4 (sep rate): β = %.4f (SE = %.4f)\n",
            coef(m4)["treatment"], se(m4)["treatment"]))
cat(sprintf("  M5 (log hires): β = %.4f (SE = %.4f)\n",
            coef(m5)["treatment"], se(m5)["treatment"]))

# Save main models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
        "../data/main_models.rds")

# --- 3. Event Study ---
cat("\n=== Event Study ===\n")

# Create relative time dummies interacted with coal share
# Bin endpoints at -8 and +12
panel <- panel %>%
  mutate(
    rel_q_binned = pmax(pmin(rel_quarter, 12), -8),
    rel_q_factor = factor(rel_q_binned)
  )

# Event study: coal_share × relative quarter dummies
# Reference period: Q2 2014 (rel_quarter = -1)
es_model <- feols(log_emp ~ i(rel_q_binned, coal_share, ref = -1) |
                    county_id + time_q,
                  data = panel, cluster = ~state_fips)

cat("Event study coefficients:\n")
es_coefs <- data.frame(
  rel_quarter = as.numeric(gsub(".*::", "", names(coef(es_model)))),
  estimate = as.numeric(coef(es_model)),
  se = as.numeric(se(es_model))
) %>%
  mutate(
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se
  ) %>%
  arrange(rel_quarter)

print(es_coefs)
write_csv(es_coefs, "../data/event_study_coefs.csv")
saveRDS(es_model, "../data/es_model.rds")

# --- 4. Binary DiD: Coal vs Oil/Gas Counties ---
cat("\n=== Binary Coal vs Oil/Gas ===\n")

panel_binary <- panel %>%
  filter(is_coal_county | is_oilgas_county)

m_binary <- feols(log_emp ~ coal_x_post | county_id + time_q,
                  data = panel_binary, cluster = ~state_fips)

cat(sprintf("  Coal vs Oil/Gas: β = %.4f (SE = %.4f)\n",
            coef(m_binary)["coal_x_post"], se(m_binary)["coal_x_post"]))

# --- 5. Industry-Level Mechanism ---
cat("\n=== Industry-Level Mechanism ===\n")

# Load industry panel
panel_ind <- read_csv("../data/panel_by_industry.csv.gz", show_col_types = FALSE) %>%
  filter(year >= 2011, year <= 2019) %>%
  mutate(
    time_q = year + (quarter - 1) / 4,
    post = as.integer(time_q >= 2014.5),
    log_emp = log(pmax(emp, 1))
  )

# Coal (212) employment trajectory
m_coal <- feols(log_emp ~ post | geography + time_q,
                data = filter(panel_ind, industry == "212"),
                cluster = ~state_fips)

# Oil/gas (211) employment trajectory — placebo
m_oilgas <- feols(log_emp ~ post | geography + time_q,
                  data = filter(panel_ind, industry == "211"),
                  cluster = ~state_fips)

cat(sprintf("  Coal (212) post: β = %.4f (SE = %.4f)\n",
            coef(m_coal)["post"], se(m_coal)["post"]))
cat(sprintf("  Oil/Gas (211) post: β = %.4f (SE = %.4f)\n",
            coef(m_oilgas)["post"], se(m_oilgas)["post"]))

# --- 6. Diagnostics for Validation ---
diag <- list(
  n_treated = n_distinct(panel$county_id[panel$is_coal_county]),
  n_pre = sum(panel$rel_quarter < 0 & panel$rel_quarter >= -8) / n_distinct(panel$county_id),
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$county_id),
  n_quarters = n_distinct(panel$time_q),
  n_clusters = n_distinct(panel$state_fips)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Analysis Complete ===\n")
cat(sprintf("Diagnostics: %d treated, %.0f pre-periods, %d obs\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
