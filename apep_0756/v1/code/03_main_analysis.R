# 03_main_analysis.R — Main DDD estimation
# apep_0756: Fair Workweek, Unfair Turnover?

source("00_packages.R")

df <- readRDS("../data/panel_main.rds")

cat("=== Main Analysis ===\n")
cat("Observations:", nrow(df), "\n")
cat("Treated county-industries (treated_county=1 & treated_industry=1):",
    n_distinct(df$county_ind[df$treated_county == 1 & df$treated_industry == 1]), "\n")

# ── Main DDD specification ───────────────────────────────────────────────────
# Y = β(TreatedCounty × TreatedIndustry × Post) + county×industry FE +
#     industry×quarter FE + county×quarter FE + ε
# Clustered at county level

# Outcome 1: Separation rate
# FE: county^industry, industry^quarter, county^quarter
# With county^quarter and industry^quarter FEs, the two-way interactions
# (dd_county_post, dd_ind_post) are absorbed. Only ddd remains.
ddd_sep <- feols(
  sep_rate ~ ddd |
    fips^industry + industry^t_int + fips^t_int,
  data = df,
  cluster = ~fips
)

# Outcome 2: New hire rate
ddd_hire <- feols(
  hire_rate ~ ddd |
    fips^industry + industry^t_int + fips^t_int,
  data = df,
  cluster = ~fips
)

# Outcome 3: Average earnings (stable jobs)
ddd_earn <- feols(
  log_earn ~ ddd |
    fips^industry + industry^t_int + fips^t_int,
  data = df,
  cluster = ~fips
)

# Outcome 4: Log employment
ddd_emp <- feols(
  log_emp ~ ddd |
    fips^industry + industry^t_int + fips^t_int,
  data = df,
  cluster = ~fips
)

cat("\n=== DDD Results ===\n")
cat("\nSeparation rate:\n")
print(summary(ddd_sep))
cat("\nNew hire rate:\n")
print(summary(ddd_hire))
cat("\nLog earnings:\n")
print(summary(ddd_earn))
cat("\nLog employment:\n")
print(summary(ddd_emp))

# ── Store pre-treatment SDs for SDE calculation ──────────────────────────────
pre_stats <- df %>%
  filter(post == 0 | treated_county == 0) %>%
  filter(treated_industry == 1) %>%
  summarise(
    sd_sep_rate = sd(sep_rate, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    sd_log_earn = sd(log_earn, na.rm = TRUE),
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    mean_sep_rate = mean(sep_rate, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    mean_earn = mean(earn_avg, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE)
  )

cat("\n=== Pre-treatment summary stats (treated industries) ===\n")
print(pre_stats)

# ── Event study (DDD) ───────────────────────────────────────────────────────
# Create relative time variable for treated counties
df_es <- df %>%
  filter(treated_county == 1) %>%
  mutate(
    rel_time = t_int - first_treat_int,
    # Bin endpoints
    rel_time_binned = case_when(
      rel_time < -8 ~ -8L,
      rel_time > 8 ~ 8L,
      TRUE ~ as.integer(rel_time)
    )
  )

# Event study: treated vs control industries within treated counties
es_sep <- feols(
  sep_rate ~ i(rel_time_binned, treated_industry, ref = -1) |
    county_ind + t_int,
  data = df_es,
  cluster = ~fips
)

es_hire <- feols(
  hire_rate ~ i(rel_time_binned, treated_industry, ref = -1) |
    county_ind + t_int,
  data = df_es,
  cluster = ~fips
)

cat("\n=== Event Study (within treated counties, treated vs control industries) ===\n")
cat("\nSeparation rate event study:\n")
print(summary(es_sep))
cat("\nNew hire rate event study:\n")
print(summary(es_hire))

# ── Save results ─────────────────────────────────────────────────────────────
results <- list(
  ddd_sep = ddd_sep,
  ddd_hire = ddd_hire,
  ddd_earn = ddd_earn,
  ddd_emp = ddd_emp,
  es_sep = es_sep,
  es_hire = es_hire,
  pre_stats = pre_stats
)

saveRDS(results, "../data/main_results.rds")

# ── Diagnostics for validator ────────────────────────────────────────────────
n_treated_counties <- n_distinct(df$fips[df$treated_county == 1])
n_pre <- n_distinct(df$t_int[df$t_int < min(df$first_treat_int[df$first_treat_int > 0])])

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = nrow(df)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written:", toJSON(diagnostics, auto_unbox = TRUE), "\n")
