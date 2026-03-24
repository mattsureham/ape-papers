## 03_main_analysis.R — Primary regressions
## apep_0845: EU Professional Qualifications Directive

source("code/00_packages.R")
library(fixest)
library(data.table)

cat("\n=== MAIN ANALYSIS ===\n")

panel <- readRDS("data/analysis_panel.rds")

# Drop rows with missing outcome or treatment
# Restrict to 2006-2023 for balanced LFS coverage and cleaner pre-trends
panel <- panel[!is.na(oq_gap_all) & !is.na(n_regulated) & !is.na(year) &
               year >= 2006 & year <= 2023]
cat(sprintf("Analysis sample: %d obs, %d countries, years %d-%d\n",
            nrow(panel), uniqueN(panel$country),
            min(panel$year), max(panel$year)))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 1: Summary Statistics
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- Table 1: Summary Statistics ---\n")

# Pre-period stats
pre <- panel[year < 2016]
post <- panel[year >= 2016]

summary_stats <- data.table(
  Variable = c("Overqualification rate (EU-foreign)",
               "Overqualification rate (national)",
               "Overqualification gap (EU-for. $-$ nat.)",
               "Overqualification gap (non-EU $-$ nat.)",
               "Regulated professions (count)",
               "Countries", "Country-years"),
  Pre_Mean = c(mean(pre$eu_for, na.rm = TRUE),
               mean(pre$nat, na.rm = TRUE),
               mean(pre$oq_gap, na.rm = TRUE),
               mean(pre$oq_gap_noneu, na.rm = TRUE),
               mean(pre$n_regulated, na.rm = TRUE),
               uniqueN(pre$country), nrow(pre)),
  Pre_SD = c(sd(pre$eu_for, na.rm = TRUE),
             sd(pre$nat, na.rm = TRUE),
             sd(pre$oq_gap, na.rm = TRUE),
             sd(pre$oq_gap_noneu, na.rm = TRUE),
             sd(pre$n_regulated, na.rm = TRUE), NA, NA),
  Post_Mean = c(mean(post$eu_for, na.rm = TRUE),
                mean(post$nat, na.rm = TRUE),
                mean(post$oq_gap, na.rm = TRUE),
                mean(post$oq_gap_noneu, na.rm = TRUE),
                mean(post$n_regulated, na.rm = TRUE),
                uniqueN(post$country), nrow(post)),
  Post_SD = c(sd(post$eu_for, na.rm = TRUE),
              sd(post$nat, na.rm = TRUE),
              sd(post$oq_gap, na.rm = TRUE),
              sd(post$oq_gap_noneu, na.rm = TRUE),
              sd(post$n_regulated, na.rm = TRUE), NA, NA)
)

print(summary_stats)

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 2: Main Results — Continuous Treatment DiD
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- Table 2: Main DiD Results ---\n")

# Model 1: Primary — All-foreign gap (24 countries)
m1 <- feols(oq_gap_all ~ treat_post | country + year, data = panel,
            cluster = ~country)

# Model 2: All-foreign gap binary treatment
m2 <- feols(oq_gap_all ~ high_reg_post | country + year, data = panel,
            cluster = ~country)

# Model 3: EU-foreign gap (subset with EU citizenship data)
m3 <- feols(oq_gap ~ treat_post | country + year, data = panel,
            cluster = ~country)

# Model 4: National overqualification level (mechanism check)
m4 <- feols(nat ~ treat_post | country + year, data = panel,
            cluster = ~country)

# Model 5: Non-EU foreign gap (placebo — not covered by directive)
m5 <- feols(oq_gap_noneu ~ treat_post | country + year, data = panel,
            cluster = ~country)

etable(m1, m2, m3, m4, m5,
       headers = c("Gap (Binary)", "Gap (Cont.)", "EU-For.", "National", "Non-EU (Placebo)"),
       se.below = TRUE, fitstat = c("n", "wr2"))

## ═══════════════════════════════════════════════════════════════════════════
## TABLE 3: Event Study
## ═══════════════════════════════════════════════════════════════════════════

cat("\n--- Table 3: Event Study ---\n")

# Event study with continuous treatment intensity
# Reference period: year before reform (event_time = -1, i.e., 2015)
panel[, et_factor := factor(event_time)]
panel[, et_factor := relevel(et_factor, ref = as.character(-1))]

es_model <- feols(oq_gap_all ~ i(event_time, rp_std, ref = -1) | country + year,
                  data = panel, cluster = ~country)

cat("Event study coefficients:\n")
print(coeftable(es_model))

# Store event study for table
es_coefs <- as.data.table(coeftable(es_model), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "t", "p"))

## ═══════════════════════════════════════════════════════════════════════════
## Diagnostics JSON
## ═══════════════════════════════════════════════════════════════════════════

# Count treated/control for diagnostics
# Continuous treatment: all countries are treated with different intensity
# n_treated = total countries (all have positive treatment variation)
n_treated <- uniqueN(panel$country)  # All 17 countries are treated (continuous DiD)
n_control <- 0  # No untreated group in continuous treatment DiD
n_pre <- uniqueN(panel[year < 2016]$year)
n_post <- uniqueN(panel[year >= 2016]$year)

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = n_pre,
  n_post = n_post,
  n_obs = nrow(panel),
  n_countries = uniqueN(panel$country),
  year_range = c(min(panel$year), max(panel$year)),
  main_coef = coef(m2)["treat_post"],
  main_se = se(m2)["treat_post"],
  main_p = pvalue(m2)["treat_post"],
  placebo_coef = coef(m5)["treat_post"],
  placebo_p = pvalue(m5)["treat_post"]
)

jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nDiagnostics saved: %d treated, %d pre-periods, %d obs\n",
            n_treated, n_pre, nrow(panel)))

## ═══════════════════════════════════════════════════════════════════════════
## Save model objects for tables script
## ═══════════════════════════════════════════════════════════════════════════

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
             es_model = es_model, es_coefs = es_coefs,
             summary_stats = summary_stats, panel = panel),
        "data/model_results.rds")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
