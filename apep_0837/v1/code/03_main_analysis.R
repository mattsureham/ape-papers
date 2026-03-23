# 03_main_analysis.R — Triple-diff and event study for R2D analysis
source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# ============================================================================
# 1. Triple-Difference: France × High-Connectivity × Post-2017
# ============================================================================
cat("=== MAIN SPECIFICATION: Triple-Difference ===\n\n")

# Primary outcome: long hours (>48h/week) percentage
# Full triple-diff with country-occupation, country-year, and occupation-year FEs
m1 <- feols(long_hours_pct ~ france_high_post |
              country_isco + country_year + isco_year,
            data = panel, cluster = ~country)

cat("Model 1: Long hours — DDD with full FEs\n")
summary(m1)

# Secondary outcome: usual weekly hours
m2 <- feols(usual_hours ~ france_high_post |
              country_isco + country_year + isco_year,
            data = panel, cluster = ~country)

cat("\nModel 2: Usual hours — DDD with full FEs\n")
summary(m2)

# ============================================================================
# 2. Decomposed Double-Differences (for comparison)
# ============================================================================
cat("\n=== DECOMPOSED: France × Post by connectivity group ===\n\n")

# High-connectivity only
panel_high <- panel %>% filter(conn_group == "High")
m3 <- feols(long_hours_pct ~ france_post |
              country_isco + isco_year,
            data = panel_high, cluster = ~country)
cat("Model 3: Long hours — France × Post, High-connectivity only\n")
summary(m3)

# Low-connectivity only
panel_low <- panel %>% filter(conn_group == "Low")
m4 <- feols(long_hours_pct ~ france_post |
              country_isco + isco_year,
            data = panel_low, cluster = ~country)
cat("Model 4: Long hours — France × Post, Low-connectivity only\n")
summary(m4)

# ============================================================================
# 3. Event Study — Year-by-year DDD coefficients
# ============================================================================
cat("\n=== EVENT STUDY ===\n\n")

# Create year interactions (omit 2016 as reference)
panel <- panel %>%
  mutate(
    event_time = year - 2017,
    rel_year = factor(event_time)
  )

# Event study: France × High-connectivity × Year dummies
m_event <- feols(long_hours_pct ~ i(event_time, france * high_conn, ref = -1) |
                   country_isco + country_year + isco_year,
                 data = panel, cluster = ~country)

cat("Model 5: Event study (reference year = 2016)\n")
summary(m_event)

# Save event study coefficients for table
event_coefs <- data.frame(
  event_time = as.integer(names(coef(m_event))),
  estimate = as.numeric(coef(m_event)),
  se = as.numeric(se(m_event))
)
# Parse event_time from coefficient names
event_coefs$event_time <- as.integer(gsub(".*::", "", gsub("event_time::", "", names(coef(m_event)))))
event_coefs <- event_coefs %>%
  mutate(
    year = event_time + 2017,
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se,
    pre_post = ifelse(year < 2017, "Pre", "Post")
  ) %>%
  arrange(event_time)

cat("\nEvent study coefficients:\n")
print(event_coefs %>% select(year, estimate, se, ci_lo, ci_hi))

# ============================================================================
# 4. Wild cluster bootstrap p-values (9 clusters is thin)
# ============================================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n\n")

# For main DDD coefficient
tryCatch({
  boot_m1 <- boottest(m1, param = "france_high_post",
                      B = 9999, clustid = "country",
                      type = "webb")
  cat("WCB for DDD (long hours):\n")
  cat(sprintf("  Point estimate: %.3f\n", coef(m1)["france_high_post"]))
  cat(sprintf("  WCB p-value: %.4f\n", boot_m1$p_val))
  cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n", boot_m1$conf_int[1], boot_m1$conf_int[2]))

  boot_m2 <- boottest(m2, param = "france_high_post",
                       B = 9999, clustid = "country",
                       type = "webb")
  cat("\nWCB for DDD (usual hours):\n")
  cat(sprintf("  Point estimate: %.3f\n", coef(m2)["france_high_post"]))
  cat(sprintf("  WCB p-value: %.4f\n", boot_m2$p_val))
  cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n", boot_m2$conf_int[1], boot_m2$conf_int[2]))
}, error = function(e) {
  cat("WCB failed:", e$message, "\n")
  cat("Falling back to CR standard errors (shown in main models above).\n")
})

# ============================================================================
# 5. Diagnostics for validation
# ============================================================================
# For triple-diff, treated cells = France × high-connectivity × post-2017 years
n_treated <- nrow(panel %>% filter(france == 1, high_conn == 1, post == 1) %>%
                   distinct(country, isco, year))
n_pre <- length(unique(panel$year[panel$year < 2017]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = n_distinct(panel$country),
  n_occupations = n_distinct(panel$isco),
  years = paste(range(panel$year), collapse = "-"),
  ddd_coef = round(coef(m1)["france_high_post"], 4),
  ddd_se = round(se(m1)["france_high_post"], 4),
  ddd_pval = round(pvalue(m1)["france_high_post"], 4)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# ============================================================================
# Save models
# ============================================================================
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m_event = m_event,
             event_coefs = event_coefs),
        "../data/models.rds")
cat("Models saved.\n")
