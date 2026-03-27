# 03_main_analysis.R — Main DiD analysis
source("00_packages.R")

paper_root <- normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
if (file.exists(file.path(paper_root, "data"))) setwd(paper_root)

panel <- readRDS("data/panel.rds")
cat(sprintf("Panel: %d rows, %d municipalities, years %d-%d\n",
  nrow(panel), n_distinct(panel$muni_code), min(panel$year), max(panel$year)))

# ---------------------------------------------------------------
# 1) Binary DiD: Treated (>20%) vs Control (<20%), Pre vs Post 2013
# ---------------------------------------------------------------
cat("\n=== Binary DiD Results ===\n")

# Main outcomes
outcomes <- c("log_residential", "log_commercial", "log_total",
              "log_leisure", "log_non_residential", "log_roads")
outcome_labels <- c("Log Residential", "Log Commercial", "Log Total",
                    "Log Leisure/Culture", "Log Non-Residential", "Log Roads (Placebo)")

did_results <- list()

for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  cat(sprintf("\n--- %s ---\n", outcome_labels[i]))

  # Basic DiD with municipality and year FE
  fml <- as.formula(paste0(y, " ~ treat_post | muni_code + year"))
  fit <- feols(fml, data = panel, cluster = "muni_code")
  cat(sprintf("  Beta = %.4f (SE = %.4f), p = %.4f\n",
    coef(fit)["treat_post"], se(fit)["treat_post"], pvalue(fit)["treat_post"]))

  did_results[[y]] <- fit
}

# ---------------------------------------------------------------
# 2) Continuous DiD: Treatment intensity × Post
# ---------------------------------------------------------------
cat("\n\n=== Continuous DiD (Intensity) Results ===\n")

intensity_results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ intensity_post | muni_code + year"))
  fit <- feols(fml, data = panel, cluster = "muni_code")
  cat(sprintf("  %s: Beta = %.4f (SE = %.4f)\n", outcome_labels[i],
    coef(fit)["intensity_post"], se(fit)["intensity_post"]))
  intensity_results[[y]] <- fit
}

# ---------------------------------------------------------------
# 3) Event Study: Year-by-year effects
# ---------------------------------------------------------------
cat("\n\n=== Event Study ===\n")

panel <- panel %>%
  mutate(event_time = year - 2012)

# Drop the period just before treatment (event_time = -1 = 2011)
event_fit_res <- feols(
  log_residential ~ i(event_time, treated, ref = -1) | muni_code + year,
  data = panel, cluster = "muni_code"
)

event_fit_com <- feols(
  log_commercial ~ i(event_time, treated, ref = -1) | muni_code + year,
  data = panel, cluster = "muni_code"
)

event_fit_tot <- feols(
  log_total ~ i(event_time, treated, ref = -1) | muni_code + year,
  data = panel, cluster = "muni_code"
)

# Extract event study coefficients
cat("\nResidential event study coefficients:\n")
es_res <- data.frame(
  event_time = as.integer(gsub("event_time::", "", names(coef(event_fit_res)))),
  coef = coef(event_fit_res),
  se = se(event_fit_res)
) %>% arrange(event_time)
print(es_res)

# Check pre-trends
pre_coefs <- es_res %>% filter(event_time < -1)
cat(sprintf("\nPre-trend joint F-test (residential):\n"))
pre_test <- wald(event_fit_res, paste0("event_time::", -18:-2, ":treated"))
cat(sprintf("  F-stat = %.2f, p-value = %.4f\n", pre_test$stat, pre_test$p))

# ---------------------------------------------------------------
# 4) Save results for tables
# ---------------------------------------------------------------

# Compute standard deviations for SDE calculation
sds <- panel %>%
  filter(year <= 2011) %>%
  summarise(
    sd_log_residential = sd(log_residential, na.rm = TRUE),
    sd_log_commercial = sd(log_commercial, na.rm = TRUE),
    sd_log_total = sd(log_total, na.rm = TRUE),
    sd_log_leisure = sd(log_leisure, na.rm = TRUE),
    sd_log_non_residential = sd(log_non_residential, na.rm = TRUE),
    sd_log_roads = sd(log_roads, na.rm = TRUE)
  )

cat("\n\nPre-treatment standard deviations:\n")
print(sds)

# Save all results
results <- list(
  did = did_results,
  intensity = intensity_results,
  event_res = event_fit_res,
  event_com = event_fit_com,
  event_tot = event_fit_tot,
  sds = sds,
  panel = panel
)
saveRDS(results, "data/results.rds")

# Diagnostics for validation
n_treated <- n_distinct(panel$muni_code[panel$treated == 1])
n_pre <- length(unique(panel$year[panel$year < 2013]))
diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
  n_treated, n_pre, nrow(panel)))
cat("Saved data/results.rds and data/diagnostics.json\n")
