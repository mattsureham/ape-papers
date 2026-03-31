## 03_main_analysis.R — Main econometric analysis
## apep_1220: Denmark Property Tax Reform and Housing Market Lock-in

source("00_packages.R")

data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
dose <- readRDS(file.path(data_dir, "treatment_dose.rds"))

cat("=== Panel structure ===\n")
cat(sprintf("  Municipalities: %d\n", n_distinct(panel$municipality)))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Post-reform obs: %d\n", sum(panel$post == 1, na.rm = TRUE)))

# ============================================================
# 1. Main specification: Dose-Response DiD
# ============================================================

cat("\n=== MAIN SPECIFICATION: Dose-Response DiD ===\n")

# Dependent variable: log total property taxes (1000kr)
# Treatment: dose_pct_change × post
# FEs: municipality + year

# Filter to analysis window (2016-2025)
analysis <- panel %>%
  filter(year >= 2016, year <= 2025) %>%
  filter(!is.na(dose_pct_change)) %>%
  filter(!is.na(total_property_tax_1000kr))

cat(sprintf("  Analysis sample: %d observations\n", nrow(analysis)))
cat(sprintf("  Municipalities: %d\n", n_distinct(analysis$municipality)))

# Main regression: total property tax
m1_tax <- feols(log_total_tax ~ dose_pct_change:post |
                  municipality + year, data = analysis,
                cluster = ~municipality)

cat("\n--- Model 1: Log total property tax ---\n")
print(summary(m1_tax))

# Total assessment
m2_assess <- feols(log_assessment ~ dose_pct_change:post |
                     municipality + year, data = analysis,
                   cluster = ~municipality)

cat("\n--- Model 2: Log total assessment ---\n")
print(summary(m2_assess))

# Forced sales (level, not log — many zeros)
analysis_fs <- panel %>%
  filter(year >= 2016, year <= 2025) %>%
  filter(!is.na(dose_pct_change)) %>%
  filter(!is.na(forced_sales))

m3_forced <- feols(forced_sales ~ dose_pct_change:post |
                     municipality + year, data = analysis_fs,
                   cluster = ~municipality)

cat("\n--- Model 3: Forced sales ---\n")
print(summary(m3_forced))

# Log forced sales (add 1 for zeros)
m3b_forced_log <- feols(log_forced_sales ~ dose_pct_change:post |
                          municipality + year, data = analysis_fs,
                        cluster = ~municipality)

cat("\n--- Model 3b: Log forced sales ---\n")
print(summary(m3b_forced_log))

# Grundskyld rate itself (mechanical check)
m4_rate <- feols(grundskyld_promille ~ dose_pct_change:post |
                   municipality + year, data = analysis,
                 cluster = ~municipality)

cat("\n--- Model 4: Grundskyld promille (mechanical check) ---\n")
print(summary(m4_rate))

# ============================================================
# 2. Event study specification
# ============================================================

cat("\n=== EVENT STUDY ===\n")

# Create event-time dummies (relative to 2023, last pre-reform year)
analysis_es <- analysis %>%
  mutate(
    event_time = year - 2024,
    # Bin endpoints
    event_time_bin = case_when(
      event_time <= -7 ~ -7,
      event_time >= 2 ~ 2,
      TRUE ~ event_time
    )
  )

# Event study: interaction of dose with year dummies
# Omit 2023 (event_time = -1) as reference
es_tax <- feols(log_total_tax ~ i(event_time_bin, dose_pct_change, ref = -1) |
                  municipality + year,
                data = analysis_es,
                cluster = ~municipality)

cat("\n--- Event Study: Log total property tax ---\n")
print(summary(es_tax))

es_forced <- feols(forced_sales ~ i(event_time_bin, dose_pct_change, ref = -1) |
                     municipality + year,
                   data = analysis_fs %>%
                     mutate(event_time = year - 2024,
                            event_time_bin = case_when(
                              event_time <= -7 ~ -7,
                              event_time >= 2 ~ 2,
                              TRUE ~ event_time
                            )),
                   cluster = ~municipality)

cat("\n--- Event Study: Forced sales ---\n")
print(summary(es_forced))

# ============================================================
# 3. Regional house price analysis (EJ131)
# ============================================================

cat("\n=== REGIONAL HOUSE PRICES ===\n")

ej131 <- readRDS(file.path(data_dir, "ej131_clean.rds"))

# Focus on single-family houses, number of sales
sales_monthly <- ej131 %>%
  filter(property_type == "Enfamiliehuse") %>%
  filter(metric == "Salg ved prisberegning (antal)") %>%
  filter(!region %in% c("Hele landet")) %>%
  mutate(
    yearmonth = year + (month - 1) / 12,
    post = as.integer(year >= 2024),
    log_sales = log(pmax(value, 1))
  )

# Calculate post-reform change in sales
pre_mean <- sales_monthly %>%
  filter(year %in% 2021:2023) %>%
  group_by(region) %>%
  summarize(pre_avg = mean(value, na.rm = TRUE))

post_mean <- sales_monthly %>%
  filter(year >= 2024) %>%
  group_by(region) %>%
  summarize(post_avg = mean(value, na.rm = TRUE))

regional_change <- pre_mean %>%
  left_join(post_mean, by = "region") %>%
  mutate(pct_change = (post_avg - pre_avg) / pre_avg * 100)

cat("Regional sales volume change (pre=2021-23 vs post=2024+):\n")
print(regional_change)

# House prices
prices_monthly <- ej131 %>%
  filter(property_type == "Enfamiliehuse") %>%
  filter(metric == "Gennemsnitlig pris pr. ejendom (1000 kr)") %>%
  filter(!region %in% c("Hele landet")) %>%
  mutate(post = as.integer(year >= 2024))

pre_price <- prices_monthly %>%
  filter(year %in% 2021:2023) %>%
  group_by(region) %>%
  summarize(pre_avg = mean(value, na.rm = TRUE))

post_price <- prices_monthly %>%
  filter(year >= 2024) %>%
  group_by(region) %>%
  summarize(post_avg = mean(value, na.rm = TRUE))

price_change <- pre_price %>%
  left_join(post_price, by = "region") %>%
  mutate(pct_change = (post_avg - pre_avg) / pre_avg * 100)

cat("\nRegional average house price change:\n")
print(price_change)

# ============================================================
# 4. LABY22 — First-time buyer share analysis
# ============================================================

cat("\n=== FIRST-TIME BUYER ANALYSIS ===\n")

laby22 <- readRDS(file.path(data_dir, "laby22_clean.rds"))

# First-time buyer share for single-family houses
ftb <- laby22 %>%
  filter(property_type == "Enfamiliehuse") %>%
  filter(metric == "Andelen af førstegangskøbere (pct.)") %>%
  mutate(post = as.integer(year >= 2024))

cat("First-time buyer share by municipality group:\n")
ftb_summary <- ftb %>%
  group_by(muni_group, post) %>%
  summarize(mean_ftb = mean(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = post, values_from = mean_ftb,
              names_prefix = "period_")

print(ftb_summary)

# Average house prices
avg_price <- laby22 %>%
  filter(property_type == "Enfamiliehuse") %>%
  filter(metric == "Gennemsnitlig pris pr. ejendom (1.000 kr.)") %>%
  mutate(post = as.integer(year >= 2024))

cat("\nAverage house price by municipality group (1000 kr):\n")
price_summary <- avg_price %>%
  group_by(muni_group, post) %>%
  summarize(mean_price = mean(value, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = post, values_from = mean_price,
              names_prefix = "period_")

print(price_summary)

# ============================================================
# 5. Save regression objects and diagnostics
# ============================================================

saveRDS(list(
  m1_tax = m1_tax,
  m2_assess = m2_assess,
  m3_forced = m3_forced,
  m3b_forced_log = m3b_forced_log,
  m4_rate = m4_rate,
  es_tax = es_tax,
  es_forced = es_forced,
  regional_sales = regional_change,
  regional_prices = price_change,
  ftb_summary = ftb_summary,
  price_summary = price_summary
), file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validate_v1.py
diagnostics <- list(
  n_treated = n_distinct(analysis$municipality[analysis$post == 1]),
  n_pre = length(unique(analysis$year[analysis$year < 2024])),
  n_obs = nrow(analysis)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\nMain analysis complete.\n")
