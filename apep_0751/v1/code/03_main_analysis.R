## 03_main_analysis.R — Main DiD estimation
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")

# State FIPS for clustering
analysis <- analysis %>%
  mutate(state_fips = substr(fips, 1, 2))

cat(sprintf("Analysis: %d obs, %d counties, %d states\n",
            nrow(analysis), n_distinct(analysis$fips), n_distinct(analysis$state_fips)))

# ---- Main specification: Continuous-treatment DiD ----
# Treatment: conv_share_pre × post
analysis <- analysis %>%
  mutate(treat = conv_share_pre * post)

# (1) OLS: log convenience stores
m1 <- feols(log_conv ~ treat | fips + year, data = analysis, cluster = ~state_fips)

# (2) OLS: log supermarkets (within-unit placebo)
m2 <- feols(log_super ~ treat | fips + year, data = analysis, cluster = ~state_fips)

# (3) OLS: log total food retailers
m3 <- feols(log_total ~ treat | fips + year, data = analysis, cluster = ~state_fips)

# (4) Poisson QMLE: convenience stores
m4 <- fepois(convenience ~ treat | fips + year, data = analysis, cluster = ~state_fips)

# (5) Poisson QMLE: supermarkets (placebo)
m5 <- fepois(supermarket ~ treat | fips + year, data = analysis, cluster = ~state_fips)

cat("\n=== Main Results ===\n")
cat("(1) OLS: log(1+convenience)\n")
print(summary(m1))
cat("\n(2) OLS: log(1+supermarket) [placebo]\n")
print(summary(m2))
cat("\n(3) OLS: log(1+total food)\n")
print(summary(m3))
cat("\n(4) Poisson: convenience\n")
print(summary(m4))
cat("\n(5) Poisson: supermarket [placebo]\n")
print(summary(m5))

# ---- Event study ----
analysis <- analysis %>%
  mutate(
    event_time = year - 2018,
    event_fac  = factor(event_time)
  )

# Interact each event-time dummy with pre-reform convenience share
# Reference: event_time = -1 (2017)
es_ols <- feols(log_conv ~ i(event_fac, conv_share_pre, ref = "-1") | fips + year,
                data = analysis, cluster = ~state_fips)

cat("\n=== Event Study (OLS) ===\n")
print(summary(es_ols))

es_pois <- fepois(convenience ~ i(event_fac, conv_share_pre, ref = "-1") | fips + year,
                  data = analysis, cluster = ~state_fips)

cat("\n=== Event Study (Poisson) ===\n")
print(summary(es_pois))

# ---- Save results ----
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  es_ols = es_ols, es_pois = es_pois
)
saveRDS(results, "../data/main_results.rds")

# ---- Diagnostics for validator ----
diag <- list(
  n_treated  = sum(analysis$conv_share_pre > median(analysis$conv_share_pre, na.rm = TRUE) &
                     analysis$post == 1) / sum(analysis$post == 1),
  n_pre      = length(unique(analysis$year[analysis$year < 2018])),
  n_obs      = nrow(analysis),
  n_counties = n_distinct(analysis$fips),
  n_states   = n_distinct(analysis$state_fips)
)
# n_treated: counties above median treatment intensity
diag$n_treated <- n_distinct(analysis$fips[analysis$conv_share_pre >
                                             median(analysis$conv_share_pre, na.rm = TRUE)])
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("Main analysis complete.\n")
