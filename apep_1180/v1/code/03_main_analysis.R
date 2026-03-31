# 03_main_analysis.R — Main DiD and RDD analysis for apep_1180
# Korea Mandatory English Disclosure paper

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")

weekly  <- fread(file.path(data_dir, "weekly_panel.csv"))
monthly <- fread(file.path(data_dir, "monthly_panel.csv"))
firms   <- fread(file.path(data_dir, "firm_characteristics.csv"))

# ============================================================
# A. DIFFERENCE-IN-DIFFERENCES: Weekly Panel
# ============================================================
cat("=" ,rep("=", 59), "\n")
cat("A. DIFFERENCE-IN-DIFFERENCES\n")
cat("=" ,rep("=", 59), "\n\n")

# Primary specification: Log Amihud illiquidity
# Y_it = alpha_i + delta_t + beta * Post_t * Treated_i + epsilon_it
# Firm and week FE, clustered at firm level

# A1. Log Amihud illiquidity (primary outcome)
did_amihud <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                    data = weekly, cluster = ~ticker)
cat("A1. DiD: Log Amihud Illiquidity\n")
summary(did_amihud)

# A2. Log turnover (secondary outcome)
did_turnover <- feols(log_turnover_w ~ post:phase1 | ticker + week,
                      data = weekly, cluster = ~ticker)
cat("\nA2. DiD: Log Turnover\n")
summary(did_turnover)

# A3. Absolute return / volatility
did_absret <- feols(abs_ret_w ~ post:phase1 | ticker + week,
                    data = weekly, cluster = ~ticker)
cat("\nA3. DiD: Absolute Return (Volatility)\n")
summary(did_absret)

# ============================================================
# B. EVENT STUDY: Dynamic DiD
# ============================================================
cat("\n", "=" ,rep("=", 59), "\n")
cat("B. EVENT STUDY\n")
cat("=" ,rep("=", 59), "\n\n")

# Monthly relative time for event study (more reliable than weeks)
# Use yearmonth relative to treatment month (202401)
weekly[, ym := as.integer(substr(week, 1, 4)) * 12 +
         as.integer(gsub(".*W", "", substr(week, 1, 8))) %/% 4]
# Simpler: parse week date and compute relative month
weekly[, week_date2 := as.Date(paste0(substr(week, 1, 4), "-01-01")) +
         (as.integer(gsub(".*W", "", week)) - 1) * 7]
weekly[, rel_month := 12 * (year(week_date2) - 2024) + month(week_date2) - 1]

cat("Relative months range:", range(weekly$rel_month, na.rm = TRUE), "\n")
cat("Available relative months:", sort(unique(weekly$rel_month)), "\n")

# Trim to +-24 months, reference = month -1 (December 2023)
weekly_es <- weekly[rel_month >= -24 & rel_month <= 23]
ref_month <- -1L

# Event study: Amihud
es_amihud <- feols(log_amihud_w ~ i(rel_month, phase1, ref = ref_month) | ticker + week,
                   data = weekly_es, cluster = ~ticker)
cat("Event Study: Log Amihud Illiquidity\n")
summary(es_amihud)

# Event study: Turnover
es_turnover <- feols(log_turnover_w ~ i(rel_month, phase1, ref = ref_month) | ticker + week,
                     data = weekly_es, cluster = ~ticker)
cat("\nEvent Study: Log Turnover\n")
summary(es_turnover)

# Extract event study coefficients for diagnostics
es_coefs <- as.data.table(coeftable(es_amihud), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))
es_coefs[, rel_m := as.integer(gsub(".*::", "", gsub(":phase1", "", term)))]
es_coefs <- es_coefs[order(rel_m)]

# Pre-trends test: joint F-test on pre-treatment coefficients
pre_coefs <- es_coefs[rel_m < -1]
if (nrow(pre_coefs) > 0) {
  pre_terms <- paste0("rel_month::", pre_coefs$rel_m, ":phase1")
  pre_test <- wald(es_amihud, pre_terms)
  cat("\nPre-trends joint F-test (Amihud):\n")
  print(pre_test)
}

# Save event study coefficients
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# ============================================================
# C. REGRESSION DISCONTINUITY: Asset Threshold
# ============================================================
cat("\n", "=" ,rep("=", 59), "\n")
cat("C. REGRESSION DISCONTINUITY\n")
cat("=" ,rep("=", 59), "\n\n")

# For RDD, use post-period monthly data
# Running variable: log total assets centered at 10T KRW threshold
THRESHOLD <- 10e12

# Merge total assets into monthly data
monthly <- merge(monthly, firms[, .(ticker, total_assets_firm = total_assets)],
                 by = "ticker", all.x = TRUE)

# Use post-treatment months only for RDD
monthly_post <- monthly[post == 1 & !is.na(total_assets_firm)]

# Running variable: log(total_assets) - log(threshold)
monthly_post[, running := log(total_assets_firm) - log(THRESHOLD)]

# Treatment: above threshold
monthly_post[, above := as.integer(running >= 0)]

# Average outcomes across post-treatment months per firm
firm_post <- monthly_post[, .(
  log_amihud = mean(log_amihud_m, na.rm = TRUE),
  log_turnover = mean(log_turnover_m, na.rm = TRUE),
  abs_ret = mean(abs_ret_m, na.rm = TRUE),
  running = mean(running),
  above = first(above),
  n_months = .N
), by = ticker]

cat("Firms for RDD:", nrow(firm_post), "\n")
cat("Above threshold:", sum(firm_post$above == 1), "\n")
cat("Below threshold:", sum(firm_post$above == 0), "\n\n")

# RDD: Amihud illiquidity
if (nrow(firm_post) > 50) {
  rdd_amihud <- rdrobust(y = firm_post$log_amihud,
                          x = firm_post$running,
                          c = 0, kernel = "triangular",
                          bwselect = "mserd")
  cat("RDD: Log Amihud Illiquidity (MSE-optimal bandwidth)\n")
  summary(rdd_amihud)

  # RDD: Turnover
  rdd_turnover <- rdrobust(y = firm_post$log_turnover,
                            x = firm_post$running,
                            c = 0, kernel = "triangular",
                            bwselect = "mserd")
  cat("\nRDD: Log Turnover\n")
  summary(rdd_turnover)
} else {
  cat("WARNING: Too few firms for RDD estimation\n")
  rdd_amihud <- NULL
  rdd_turnover <- NULL
}

# ============================================================
# D. SIZE HETEROGENEITY (mechanism: who benefits from English disclosure?)
# ============================================================
cat("\n", "=" ,rep("=", 59), "\n")
cat("D. HETEROGENEITY\n")
cat("=" ,rep("=", 59), "\n\n")

# Within treated firms: larger firms (more foreign interest) vs smaller treated firms
weekly[, large_treated := as.integer(phase1 == 1 &
                                       market_cap >= median(market_cap[phase1 == 1]))]
weekly[phase1 == 0, large_treated := 0]

# Split sample: large vs small treated firms
did_large <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                   data = weekly[large_treated == 1 | phase1 == 0],
                   cluster = ~ticker)
cat("Large treated firms (above median market cap among treated):\n")
summary(did_large)

did_small <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                   data = weekly[large_treated == 0],
                   cluster = ~ticker)
cat("\nSmall treated firms (below median market cap among treated):\n")
summary(did_small)

# Sector heterogeneity: Financial vs non-financial
weekly[, financial := as.integer(grepl("Financial|Insurance|Bank", sector, ignore.case = TRUE))]

did_financial <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                       data = weekly[financial == 1 | phase1 == 0],
                       cluster = ~ticker)
cat("\nFinancial sector treated firms:\n")
summary(did_financial)

did_nonfinancial <- feols(log_amihud_w ~ post:phase1 | ticker + week,
                          data = weekly[financial == 0],
                          cluster = ~ticker)
cat("\nNon-financial sector treated firms:\n")
summary(did_nonfinancial)

# ============================================================
# E. SAVE RESULTS
# ============================================================
cat("\n", "=" ,rep("=", 59), "\n")
cat("E. SAVING RESULTS\n")
cat("=" ,rep("=", 59), "\n\n")

# Save model objects
results <- list(
  did_amihud = did_amihud,
  did_turnover = did_turnover,
  did_absret = did_absret,
  es_amihud = es_amihud,
  es_turnover = es_turnover,
  did_large = did_large,
  did_small = did_small,
  did_financial = did_financial,
  did_nonfinancial = did_nonfinancial
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Save diagnostics for validator
n_treated <- uniqueN(weekly[phase1 == 1]$ticker)
n_control <- uniqueN(weekly[phase1 == 0]$ticker)
n_pre_weeks <- uniqueN(weekly[post == 0]$week)

diagnostics <- list(
  n_treated = n_treated,
  n_control = n_control,
  n_pre = n_pre_weeks,
  n_obs = nrow(weekly),
  n_firms = uniqueN(weekly$ticker),
  treatment_date = "2024-01-02",
  treatment_threshold = "KRW 10 trillion total assets"
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("Main results saved.\n")
cat("Diagnostics: n_treated =", n_treated, ", n_pre =", n_pre_weeks, ", n_obs =", nrow(weekly), "\n")
