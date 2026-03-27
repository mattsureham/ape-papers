## 03_main_analysis.R — Primary DiD and triple-diff estimates
## apep_1050: Swiss EV Tax Exemptions
source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- read_csv("../data/panel_analysis.csv", show_col_types = FALSE)
panel_long <- read_csv("../data/panel_long_analysis.csv", show_col_types = FALSE)

# -------------------------------------------------------------------
# 1. TWFE Difference-in-Differences (Continuous Treatment)
# -------------------------------------------------------------------
cat("\n--- TWFE: Continuous Treatment ---\n")

# Primary specification: EV share ~ tax discount
# Municipality and year FE, clustered at canton level
m1_share <- feols(ev_share ~ tax_discount | muni_id + year,
                  data = panel, cluster = ~canton_abbr)

# Log EV registrations
m1_log <- feols(log_ev ~ tax_discount | muni_id + year,
                data = panel, cluster = ~canton_abbr)

# Level: EV registrations
m1_level <- feols(ev_regs ~ tax_discount | muni_id + year,
                  data = panel, cluster = ~canton_abbr)

# Binary treatment
m1_binary <- feols(ev_share ~ treated | muni_id + year,
                   data = panel, cluster = ~canton_abbr)

cat("TWFE Results:\n")
etable(m1_share, m1_log, m1_level, m1_binary,
       headers = c("EV Share", "Log EV", "EV Count", "EV Share (Binary)"))

# -------------------------------------------------------------------
# 2. Callaway & Sant'Anna (2021) — Binary Treatment
# -------------------------------------------------------------------
cat("\n--- Callaway & Sant'Anna ---\n")

# Need: panel with id, time, outcome, first_treat_g (0 = never treated)
cs_data <- panel %>%
  mutate(first_treat_g = as.integer(first_treat_g)) %>%
  filter(!is.na(ev_share))

# C&S ATT(g,t) estimation
cs_out <- tryCatch({
  att_gt(
    yname = "ev_share",
    tname = "year",
    idname = "muni_id",
    gname = "first_treat_g",
    data = cs_data,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying",
    clustervars = "canton_abbr",
    print_details = FALSE
  )
}, error = function(e) {
  cat("C&S failed:", e$message, "\n")
  # Try without canton clustering (cluster at municipality level by default)
  att_gt(
    yname = "ev_share",
    tname = "year",
    idname = "muni_id",
    gname = "first_treat_g",
    data = cs_data,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "varying",
    print_details = FALSE
  )
})

# Aggregate: overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nOverall ATT (C&S):\n")
summary(cs_agg)

# Event study aggregation
cs_es <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 8)
cat("\nEvent Study (C&S):\n")
summary(cs_es)

# Save event study coefficients for tables
es_df <- data.frame(
  rel_year = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    sig = ifelse(abs(att / se) > 1.96, "*", "")
  )

cat("\nEvent Study Coefficients:\n")
print(es_df, digits = 4)

# Check pre-trends
pre_coefs <- es_df %>% filter(rel_year < 0)
cat(sprintf("\nPre-trend test: %d pre-period coefficients\n", nrow(pre_coefs)))
cat(sprintf("Max absolute pre-trend: %.4f (se=%.4f)\n",
            max(abs(pre_coefs$att)), pre_coefs$se[which.max(abs(pre_coefs$att))]))
any_sig_pre <- any(abs(pre_coefs$att / pre_coefs$se) > 1.96)
cat(sprintf("Any significant pre-trends: %s\n", ifelse(any_sig_pre, "YES ⚠", "NO ✓")))

write_csv(es_df, "../data/event_study_coefs.csv")

# -------------------------------------------------------------------
# 3. Triple-Difference: EV vs ICE within municipality-year
# -------------------------------------------------------------------
cat("\n--- Triple Difference: EV vs ICE ---\n")

# If the tax exemption drives EV adoption, it should affect EV registrations
# but NOT gasoline/diesel registrations within the same municipality.

m_triple <- feols(log_regs ~ treated_ev + treated + is_ev |
                    muni_id + year,
                  data = panel_long, cluster = ~canton_abbr)

m_triple2 <- feols(log_regs ~ i(is_ev, tax_discount) + tax_discount |
                     muni_id + year,
                   data = panel_long, cluster = ~canton_abbr)

cat("Triple-Diff Results:\n")
etable(m_triple, m_triple2,
       headers = c("Binary", "Continuous"))

# -------------------------------------------------------------------
# 4. Treatment Intensity: 100% vs Partial vs No Exemption
# -------------------------------------------------------------------
cat("\n--- Treatment Intensity ---\n")

panel <- panel %>%
  mutate(
    intensity_group = case_when(
      ev_tax_discount_pct == 100 ~ "Full (100%)",
      ev_tax_discount_pct > 0 ~ "Partial (50-75%)",
      TRUE ~ "None (0%)"
    ),
    intensity_group = factor(intensity_group,
                             levels = c("None (0%)", "Partial (50-75%)", "Full (100%)"))
  )

m_intensity <- feols(ev_share ~ i(intensity_group, ref = "None (0%)") | muni_id + year,
                     data = panel, cluster = ~canton_abbr)

cat("Intensity Results:\n")
etable(m_intensity)

# -------------------------------------------------------------------
# 5. Save Results for Tables
# -------------------------------------------------------------------

# Collect key estimates
results <- list(
  twfe_continuous = list(
    coef = coef(m1_share)["tax_discount"],
    se = sqrt(vcov(m1_share)["tax_discount", "tax_discount"]),
    n = nobs(m1_share),
    n_muni = n_distinct(panel$muni_id[!is.na(panel$ev_share)]),
    n_cantons = n_distinct(panel$canton_abbr)
  ),
  twfe_binary = list(
    coef = coef(m1_binary)["treated"],
    se = sqrt(vcov(m1_binary)["treated", "treated"]),
    n = nobs(m1_binary)
  ),
  cs_att = list(
    coef = cs_agg$overall.att,
    se = cs_agg$overall.se,
    n = nrow(cs_data)
  ),
  triple_diff = list(
    coef = coef(m_triple)["treated_ev"],
    se = sqrt(vcov(m_triple)["treated_ev", "treated_ev"]),
    n = nobs(m_triple)
  )
)

# Store model objects
saveRDS(list(
  m1_share = m1_share,
  m1_log = m1_log,
  m1_level = m1_level,
  m1_binary = m1_binary,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_es = cs_es,
  m_triple = m_triple,
  m_triple2 = m_triple2,
  m_intensity = m_intensity,
  results = results
), "../data/main_results.rds")

# -------------------------------------------------------------------
# 6. Write diagnostics.json for validator
# -------------------------------------------------------------------
# Treated units = municipalities in treated cantons
# Pre-periods = years before the median treatment cohort (2014)
median_treat_yr <- median(unique(panel$first_treat_year[panel$ever_treated & is.finite(panel$first_treat_year)]))
diagnostics <- list(
  n_treated = n_distinct(panel$muni_id[panel$ever_treated]),
  n_pre = length(unique(panel$year[panel$year < median_treat_yr])),
  n_obs = nrow(panel)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main Analysis Complete ===\n")
