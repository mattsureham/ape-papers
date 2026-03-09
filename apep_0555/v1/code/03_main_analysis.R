## ============================================================================
## 03_main_analysis.R — Primary DiD and event study regressions
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

source(file.path(here::here(), "output", "apep_0555", "v1", "code", "00_packages.R"))

panel <- fread(file.path(data_dir, "panel.csv"))
rice  <- fread(file.path(data_dir, "rice_panel.csv"))

## =========================================================================
## 1. MAIN DiD: High CMI x Cash Crisis (commodity-market & market-time FE)
## =========================================================================

## Specification 1: Acute crisis (Feb-May 2023)
m1_acute <- feols(
  log_price ~ high_cmi:cash_crisis_acute |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

## Specification 2: Extended crisis (Feb-Dec 2023)
m1_extended <- feols(
  log_price ~ high_cmi:cash_crisis_extended |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

## Specification 3: Decomposed periods (announcement, acute, extended, recovery)
m1_decomposed <- feols(
  log_price ~ high_cmi:announcement + high_cmi:cash_crisis_acute +
    high_cmi:i(year == 2023 & month >= 6, ref = FALSE) +
    high_cmi:recovery |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

cat("=== MAIN DiD RESULTS ===\n")
cat("\nAcute crisis (Feb-May 2023):\n")
print(summary(m1_acute))
cat("\nExtended crisis (Feb-Dec 2023):\n")
print(summary(m1_extended))

## =========================================================================
## 2. EVENT STUDY: Monthly leads and lags
## =========================================================================

## Bin extreme leads/lags to avoid sparse cells
panel[, event_time_binned := pmax(pmin(event_time, 18), -24)]

## Event study with monthly dummies
es_model <- feols(
  log_price ~ i(event_time_binned, high_cmi, ref = -1) |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

## Extract event study coefficients
## fixest i() names: "event_time_binned::-24:high_cmi"
es_coefs <- as.data.table(coeftable(es_model), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))

## Parse event_time from coefficient names like "event_time_binned::-24:high_cmi"
es_coefs[, event_time := as.integer(str_extract(term, "-?\\d+"))]
es_coefs <- es_coefs[!is.na(event_time)]

## Add reference period
es_coefs <- rbind(
  es_coefs,
  data.table(term = "ref", estimate = 0, se = 0, tstat = 0, pval = 1, event_time = -1)
)
es_coefs[, `:=`(
  ci_lo = estimate - 1.96 * se,
  ci_hi = estimate + 1.96 * se
)]
setorder(es_coefs, event_time)

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))
cat("\nEvent study coefficients saved.\n")

## =========================================================================
## 3. LOCAL vs IMPORTED RICE (sharpest placebo)
## =========================================================================

rice[, local_rice := as.integer(commodity == "Rice (local)")]

## Rice DiD: local vs imported within same markets
m_rice_acute <- feols(
  log_price ~ local_rice:cash_crisis_acute |
    market_commodity + market_id_num^time_idx,
  data = rice,
  cluster = ~state
)

m_rice_extended <- feols(
  log_price ~ local_rice:cash_crisis_extended |
    market_commodity + market_id_num^time_idx,
  data = rice,
  cluster = ~state
)

## Rice event study
rice[, event_time_binned := pmax(pmin(event_time, 18), -24)]

es_rice <- feols(
  log_price ~ i(event_time_binned, local_rice, ref = -1) |
    market_commodity + market_id_num^time_idx,
  data = rice,
  cluster = ~state
)

es_rice_coefs <- as.data.table(coeftable(es_rice), keep.rownames = "term")
setnames(es_rice_coefs, c("term", "estimate", "se", "tstat", "pval"))
es_rice_coefs[, event_time := as.integer(str_extract(term, "-?\\d+"))]
es_rice_coefs <- es_rice_coefs[!is.na(event_time)]
es_rice_coefs <- rbind(
  es_rice_coefs,
  data.table(term = "ref", estimate = 0, se = 0, tstat = 0, pval = 1, event_time = -1)
)
es_rice_coefs[, `:=`(
  ci_lo = estimate - 1.96 * se,
  ci_hi = estimate + 1.96 * se
)]
setorder(es_rice_coefs, event_time)

fwrite(es_rice_coefs, file.path(data_dir, "event_study_rice_coefs.csv"))
cat("\nRice event study coefficients saved.\n")

cat("\n=== RICE DiD RESULTS ===\n")
cat("\nRice acute crisis:\n")
print(summary(m_rice_acute))
cat("\nRice extended crisis:\n")
print(summary(m_rice_extended))

## =========================================================================
## 4. SUMMARY TABLE DATA
## =========================================================================

## Create comprehensive summary statistics by CMI and period
sumstats_detail <- panel[, .(
  n_obs = .N,
  n_markets = n_distinct(market),
  n_commodities = n_distinct(commodity),
  n_states = n_distinct(state),
  mean_price_ngn = mean(price, na.rm = TRUE),
  sd_price_ngn = sd(price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  sd_log_price = sd(log_price, na.rm = TRUE),
  min_price = min(price, na.rm = TRUE),
  max_price = max(price, na.rm = TRUE)
), by = .(cmi, period = fifelse(
  cash_crisis_acute == 1, "Acute crisis (Feb-May 2023)",
  fifelse(announcement == 1, "Announcement (Nov 2022-Jan 2023)",
  fifelse(recovery == 1, "Recovery (2024+)", "Pre-reform"))
))]

fwrite(sumstats_detail, file.path(data_dir, "sumstats_detail.csv"))

## Save main regression coefficients for tables
main_results <- data.table(
  specification = c("Acute crisis", "Extended crisis", "Rice acute", "Rice extended"),
  estimate = c(
    coef(m1_acute),
    coef(m1_extended),
    coef(m_rice_acute),
    coef(m_rice_extended)
  ),
  se = c(
    sqrt(diag(vcov(m1_acute))),
    sqrt(diag(vcov(m1_extended))),
    sqrt(diag(vcov(m_rice_acute))),
    sqrt(diag(vcov(m_rice_extended)))
  ),
  n_obs = c(
    nobs(m1_acute),
    nobs(m1_extended),
    nobs(m_rice_acute),
    nobs(m_rice_extended)
  )
)
main_results[, `:=`(
  tstat = estimate / se,
  pval = 2 * pnorm(-abs(estimate / se)),
  stars = fifelse(abs(estimate / se) > 2.576, "***",
           fifelse(abs(estimate / se) > 1.96, "**",
            fifelse(abs(estimate / se) > 1.645, "*", "")))
)]

fwrite(main_results, file.path(data_dir, "main_results.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Main DiD results saved to data/main_results.csv\n")
cat("Event study coefficients saved to data/event_study_coefs.csv\n")
