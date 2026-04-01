## 03_main_analysis.R — Main DiD analysis
## apep_1278: The Compliance Lottery

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")

cat("=== Main Analysis ===\n")

# -----------------------------------------------------------------------
# 1. TWFE (benchmark, reported with caveats about heterogeneity bias)
# -----------------------------------------------------------------------
cat("\n--- TWFE Benchmark ---\n")

# Main outcome: VAT gap
twfe_gap <- feols(
  vat_gap_pct ~ lottery_active | country_id + year,
  data = panel %>% filter(!is.na(vat_gap_pct), country != "MT"),
  cluster = ~country_id
)
summary(twfe_gap)

# Secondary outcome: VAT revenue as % of GDP
twfe_vat <- feols(
  vat_gdp_ratio ~ lottery_active | country_id + year,
  data = panel %>% filter(country != "MT"),
  cluster = ~country_id
)
summary(twfe_vat)

# -----------------------------------------------------------------------
# 2. Callaway-Sant'Anna (2021) — heterogeneity-robust staggered DiD
# -----------------------------------------------------------------------
cat("\n--- Callaway-Sant'Anna ---\n")

# Prepare data: exclude Malta (always-treated before panel)
# Exclude countries with cancelled lotteries for on-only CS estimator
# (handle cancellations separately in robustness)
cs_data <- panel %>%
  filter(!is.na(vat_gap_pct), country != "MT") %>%
  # For on-only analysis, exclude post-cancellation observations
  # or more conservatively, exclude cancelled countries entirely
  mutate(
    cs_group_clean = case_when(
      country %in% c("SK", "PL", "CZ", "LV") ~ as.integer(lottery_start),  # Keep treated until cancellation
      is.na(lottery_start) ~ 0L,
      TRUE ~ as.integer(lottery_start)
    )
  )

# Run CS with never-treated as comparison
cs_result <- att_gt(
  yname = "vat_gap_pct",
  tname = "year",
  idname = "country_id",
  gname = "cs_group_clean",
  data = cs_data,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "varying",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\n--- Group-Time ATTs ---\n")
summary(cs_result)

# Aggregate to overall ATT
cs_agg <- aggte(cs_result, type = "simple")
cat("\n--- Overall ATT (simple) ---\n")
summary(cs_agg)

# Dynamic aggregation (event study)
cs_dynamic <- aggte(cs_result, type = "dynamic", min_e = -5, max_e = 5)
cat("\n--- Dynamic ATT (event study) ---\n")
summary(cs_dynamic)

# Group-level aggregation
cs_group <- aggte(cs_result, type = "group")
cat("\n--- Group ATT ---\n")
summary(cs_group)

# -----------------------------------------------------------------------
# 3. Event study with fixest (Sun-Abraham)
# -----------------------------------------------------------------------
cat("\n--- Sun-Abraham Event Study ---\n")

# Create relative time variable
es_data <- panel %>%
  filter(!is.na(vat_gap_pct), country != "MT") %>%
  mutate(
    treat_year = ifelse(ever_treated & cs_group > 0, cs_group, NA_integer_),
    rel_time = ifelse(!is.na(treat_year), year - treat_year, NA_integer_)
  )

# Sun-Abraham via fixest::sunab
sa_result <- feols(
  vat_gap_pct ~ sunab(treat_year, rel_time) | country_id + year,
  data = es_data %>% mutate(treat_year = ifelse(is.na(treat_year), 10000, treat_year)),
  cluster = ~country_id
)
cat("\n--- Sun-Abraham Results ---\n")
summary(sa_result)

# -----------------------------------------------------------------------
# 4. Save results for tables
# -----------------------------------------------------------------------
results <- list(
  twfe_gap = twfe_gap,
  twfe_vat = twfe_vat,
  cs_result = cs_result,
  cs_agg = cs_agg,
  cs_dynamic = cs_dynamic,
  cs_group = cs_group,
  sa_result = sa_result
)
saveRDS(results, "../data/main_results.rds")

# -----------------------------------------------------------------------
# 5. Diagnostics for validator
# -----------------------------------------------------------------------
# Count treated observations (country-years with active lottery)
n_treated_obs <- panel %>%
  filter(lottery_active == 1, country != "MT") %>%
  nrow()

n_treated_countries <- panel %>%
  filter(ever_treated, country != "MT", cs_group > 0) %>%
  pull(country) %>%
  n_distinct()

n_pre <- cs_data %>%
  filter(cs_group_clean > 0) %>%
  group_by(country) %>%
  summarise(n_pre = sum(year < cs_group_clean)) %>%
  pull(n_pre) %>%
  min()

diagnostics <- list(
  n_treated = n_treated_obs,
  n_treated_countries = n_treated_countries,
  n_pre = n_pre,
  n_obs = nrow(cs_data),
  n_countries = n_distinct(cs_data$country),
  n_years = n_distinct(cs_data$year),
  twfe_coef = coef(twfe_gap)["lottery_active"],
  twfe_se = se(twfe_gap)["lottery_active"],
  cs_att = cs_agg$overall.att,
  cs_se = cs_agg$overall.se
)
write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
cat("=== Main analysis complete ===\n")
