## 03_main_analysis.R — Primary DiD estimation
## apep_0841: Poland 500+ and Female Labor Supply

source("00_packages.R")
library(fixest)
library(data.table)

cat("=== Main Analysis ===\n")

panel <- readRDS("../data/analysis_panel.rds")

# ─── Specification 1: Simple Poland × Post DiD ─────────────────────────────
cat("\n--- Specification 1: Simple DiD (Poland vs CEE, pre/post 2019) ---\n")

m1 <- feols(emp_rate_f ~ poland_post | nuts2 + year,
            data = panel, cluster = ~nuts2)
cat("Poland × Post2019 coefficient:\n")
print(summary(m1))

# ─── Specification 2: Treatment Intensity DiD ──────────────────────────────
cat("\n--- Specification 2: Treatment Intensity DiD ---\n")
# Only within Poland: exploit intensity variation
pl <- panel[panel$poland == 1, ]

m2 <- feols(emp_rate_f ~ intensity_post | nuts2 + year,
            data = pl, cluster = ~nuts2)
cat("Intensity × Post2019 coefficient (Poland only):\n")
print(summary(m2))

# ─── Specification 3: Triple Difference (Poland × Intensity × Post) ───────
cat("\n--- Specification 3: Triple Difference (full panel) ---\n")

m3 <- feols(emp_rate_f ~ poland_intensity_post + poland_post + intensity_post |
              nuts2 + year,
            data = panel, cluster = ~nuts2)
cat("Triple-diff coefficient:\n")
print(summary(m3))

# ─── Specification 4: With GDP control ─────────────────────────────────────
cat("\n--- Specification 4: With GDP per capita control ---\n")

m4 <- feols(emp_rate_f ~ poland_intensity_post + poland_post + intensity_post +
              log(gdp_pc) | nuts2 + year,
            data = panel[!is.na(panel$gdp_pc) & panel$gdp_pc > 0, ],
            cluster = ~nuts2)
print(summary(m4))

# ─── Event Study ───────────────────────────────────────────────────────────
cat("\n--- Event Study: Poland × Intensity × Year ---\n")

# Create event-time dummies interacted with Poland × intensity
# Reference period: year = 2018 (t = -1)
pl$event_time_f <- factor(pl$event_time)
pl$event_time_f <- relevel(pl$event_time_f, ref = "-1")

m_event <- feols(emp_rate_f ~ i(event_time, treat_intensity_std, ref = -1) |
                   nuts2 + year,
                 data = pl, cluster = ~nuts2)
cat("Event study coefficients:\n")
print(summary(m_event))

# Save event study coefficients
# Extract event time from fixest coefficient names like "event_time::-9:treat_intensity_std"
coef_names <- names(coef(m_event))
event_times <- as.numeric(gsub("event_time::(-?[0-9]+):treat_intensity_std", "\\1", coef_names))
es_coefs <- data.frame(
  event_time = event_times,
  estimate = as.numeric(coef(m_event)),
  se = as.numeric(sqrt(diag(vcov(m_event))))
)
es_coefs$ci_lo <- es_coefs$estimate - 1.96 * es_coefs$se
es_coefs$ci_hi <- es_coefs$estimate + 1.96 * es_coefs$se
# Add reference period (t = -1, coefficient = 0)
es_coefs <- rbind(es_coefs, data.frame(event_time = -1, estimate = 0, se = 0,
                                        ci_lo = 0, ci_hi = 0))
es_coefs <- es_coefs[order(es_coefs$event_time), ]
write.csv(es_coefs, "../data/event_study_coefs.csv", row.names = FALSE)

# ─── Specification 5: Gender gap (Female - Male) as outcome ────────────────
cat("\n--- Specification 5: Gender Gap DiD ---\n")
# Controls for common shocks to labor demand that affect both genders
panel_gg <- panel[!is.na(panel$emp_rate_f) & !is.na(panel$emp_rate_m), ]
panel_gg$gender_gap <- panel_gg$emp_rate_f - panel_gg$emp_rate_m

m5 <- feols(gender_gap ~ poland_post | nuts2 + year,
            data = panel_gg, cluster = ~nuts2)
cat("Gender gap × Poland×Post:\n")
print(summary(m5))

# ─── Specification 6: Visegrad-only DiD ───────────────────────────────────
cat("\n--- Specification 6: Visegrad-only controls (CZ, SK, HU) ---\n")
panel_v4 <- panel[panel$country %in% c("PL", "CZ", "SK", "HU"), ]

m6 <- feols(emp_rate_f ~ poland_post | nuts2 + year,
            data = panel_v4, cluster = ~nuts2)
cat("Poland×Post (Visegrad controls only):\n")
print(summary(m6))

# ─── Save diagnostics ──────────────────────────────────────────────────────
n_treated <- length(unique(pl$nuts2))
n_pre <- length(unique(panel$year[panel$year < 2019]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_regions_total = length(unique(panel$nuts2)),
  n_regions_poland = n_treated,
  n_regions_control = length(unique(panel$nuts2[panel$poland == 0])),
  years = paste(min(panel$year), max(panel$year), sep = "-"),
  main_coef_simple_did = round(coef(m1)["poland_post"], 4),
  main_se_simple_did = round(sqrt(diag(vcov(m1)))["poland_post"], 4),
  main_coef_intensity = round(coef(m2)["intensity_post"], 4),
  main_se_intensity = round(sqrt(diag(vcov(m2)))["intensity_post"], 4),
  main_coef_triple = round(coef(m3)["poland_intensity_post"], 4),
  main_se_triple = round(sqrt(diag(vcov(m3)))["poland_intensity_post"], 4),
  sd_y_pre = round(sd(panel$emp_rate_f[panel$post2019 == 0], na.rm = TRUE), 4)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# ─── Save models for table generation ──────────────────────────────────────
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6, m_event = m_event),
        "../data/main_models.rds")
cat("Models saved to data/main_models.rds\n")
