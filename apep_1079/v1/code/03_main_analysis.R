# 03_main_analysis.R — Main regressions
# apep_1079: Section 301 tariffs and racial employment effects

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
county_exp <- readRDS("../data/county_exposure.rds")
asian_shares <- readRDS("../data/asian_industry_shares.rds")

cat("Analysis panel:", nrow(df), "rows\n")

# ============================================================
# 1. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

sumstats <- df %>%
  group_by(race_label) %>%
  summarize(
    n_obs = n(),
    n_counties = n_distinct(fips),
    n_industries = n_distinct(naics3),
    mean_emp = mean(Emp, na.rm = TRUE),
    sd_emp = sd(Emp, na.rm = TRUE),
    mean_log_emp = mean(log_emp, na.rm = TRUE),
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    mean_earn = mean(EarnS, na.rm = TRUE),
    sd_earn = sd(EarnS, na.rm = TRUE),
    mean_tariff = mean(tariff_max, na.rm = TRUE),
    .groups = "drop"
  )
print(sumstats)

sd_log_emp_all <- sd(df$log_emp, na.rm = TRUE)
sd_log_emp_pre <- sd(df$log_emp[df$post == 0], na.rm = TRUE)
cat("\nSD(log Emp) pre-treatment:", round(sd_log_emp_pre, 4), "\n")

# ============================================================
# 2. Create additional FE variables
# ============================================================
df <- df %>%
  mutate(
    time_id_factor = factor(time_id),
    county_qtr = paste(fips, year, quarter, sep = "_"),
    state_qtr = paste(state, year, quarter, sep = "_"),
    # Region (Census division) for region × quarter FE
    region = case_when(
      state %in% c("09","23","25","33","44","50") ~ "NE",
      state %in% c("34","36","42") ~ "MA",
      state %in% c("17","18","26","39","55") ~ "ENC",
      state %in% c("19","20","27","29","31","38","46") ~ "WNC",
      state %in% c("10","11","12","13","24","37","45","51","54") ~ "SA",
      state %in% c("01","21","28","47") ~ "ESC",
      state %in% c("05","22","40","48") ~ "WSC",
      state %in% c("04","08","16","30","32","35","49","56") ~ "MT",
      state %in% c("02","06","15","41","53") ~ "PAC",
      TRUE ~ "OT"
    ),
    region_qtr = paste(region, year, quarter, sep = "_")
  )

# ============================================================
# 3. Primary specification: Bartik county-level exposure
# ============================================================
# Bartik_tariff varies by county (employment-weighted industry tariff exposure)
# → identified with county×race FE + industry×quarter FE + race×quarter FE

cat("\n=== Model 1: Bartik County Exposure (baseline) ===\n")
m1 <- feols(
  log_emp ~ bartik_tariff:post | county_race + time_id_factor,
  data = df,
  cluster = ~state
)
summary(m1)

cat("\n=== Model 2: Bartik with race interactions ===\n")
m2 <- feols(
  log_emp ~ bartik_tariff:post + bartik_tariff:post:is_asian +
    bartik_tariff:post:is_black | county_race + time_id_factor + race_qtr,
  data = df,
  cluster = ~state
)
summary(m2)

cat("\n=== Model 3: Bartik with industry×quarter FE ===\n")
m3 <- feols(
  log_emp ~ bartik_tariff:post + bartik_tariff:post:is_asian +
    bartik_tariff:post:is_black | county_race + ind_qtr + race_qtr,
  data = df,
  cluster = ~state
)
summary(m3)

# ============================================================
# 4. Industry-level specification (simpler FE)
# ============================================================
# tariff_max varies by industry → cannot use industry×quarter FE
# Use cell_id + race×quarter FE

cat("\n=== Model 4: Industry tariff rate (no ind×qtr FE) ===\n")
m4 <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr,
  data = df,
  cluster = ~state
)
summary(m4)

cat("\n=== Model 5: Industry tariff + region×quarter FE ===\n")
m5 <- feols(
  log_emp ~ tariff_max:post + tariff_max:post:is_asian +
    tariff_max:post:is_black | cell_id + race_qtr + region_qtr,
  data = df,
  cluster = ~state
)
summary(m5)

# ============================================================
# 5. Binary high-exposure specification
# ============================================================
cat("\n=== Model 6: Binary high-exposure ===\n")
m6 <- feols(
  log_emp ~ high_exposure:post + high_exposure:post:is_asian +
    high_exposure:post:is_black | cell_id + race_qtr + region_qtr,
  data = df,
  cluster = ~state
)
summary(m6)

# ============================================================
# 6. Event study (quarterly leads/lags)
# ============================================================
cat("\n=== Event Study ===\n")

# 2018Q3 = time_id 14 (2015Q1=1, Q2=2, ..., 2018Q3=14)
df <- df %>%
  mutate(
    rel_time = time_id - 14,
    rel_time_binned = case_when(
      rel_time <= -6 ~ -6L,
      rel_time >= 6 ~ 6L,
      TRUE ~ as.integer(rel_time)
    )
  )

# Verify time mapping
cat("Time ID → Year-Quarter:\n")
print(df %>% distinct(year, quarter, time_id, rel_time) %>% arrange(time_id) %>% head(20))

# Event study with Bartik exposure
es_all <- feols(
  log_emp ~ i(rel_time_binned, bartik_tariff, ref = -1) |
    county_race + race_qtr,
  data = df,
  cluster = ~state
)

# By race
es_white <- feols(
  log_emp ~ i(rel_time_binned, bartik_tariff, ref = -1) |
    county_race,
  data = df %>% filter(race == "A1"),
  cluster = ~state
)

es_asian <- feols(
  log_emp ~ i(rel_time_binned, bartik_tariff, ref = -1) |
    county_race,
  data = df %>% filter(race == "A4"),
  cluster = ~state
)

es_black <- feols(
  log_emp ~ i(rel_time_binned, bartik_tariff, ref = -1) |
    county_race,
  data = df %>% filter(race == "A2"),
  cluster = ~state
)

cat("Event study models estimated.\n")

# ============================================================
# 7. Decomposition: mechanical composition vs within-industry
# ============================================================
cat("\n=== Composition Decomposition ===\n")

# Pre-treatment industry shares by race
pre_shares <- df %>%
  filter(post == 0) %>%
  group_by(race_label) %>%
  mutate(race_total = sum(Emp, na.rm = TRUE)) %>%
  group_by(naics3, race_label) %>%
  summarize(
    ind_share = sum(Emp, na.rm = TRUE) / first(race_total),
    avg_tariff = first(tariff_max),
    .groups = "drop"
  )

# Employment-weighted mean tariff by race
composition <- pre_shares %>%
  group_by(race_label) %>%
  summarize(
    weighted_tariff = sum(ind_share * avg_tariff, na.rm = TRUE),
    .groups = "drop"
  )
cat("Mechanical tariff exposure by race:\n")
print(composition)

asian_vs_white <- composition$weighted_tariff[composition$race_label == "Asian"] /
  composition$weighted_tariff[composition$race_label == "White"]
cat("Asian/White mechanical exposure ratio:", round(asian_vs_white, 2), "\n")

# ============================================================
# 8. Earnings
# ============================================================
cat("\n=== Earnings ===\n")
m_earn <- feols(
  log_earn ~ bartik_tariff:post + bartik_tariff:post:is_asian +
    bartik_tariff:post:is_black | county_race + ind_qtr + race_qtr,
  data = df %>% filter(!is.na(log_earn)),
  cluster = ~state
)
summary(m_earn)

# ============================================================
# 9. Save
# ============================================================
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
  m_earn = m_earn,
  es_all = es_all, es_white = es_white, es_asian = es_asian, es_black = es_black,
  sumstats = sumstats,
  composition = composition,
  sd_log_emp_pre = sd_log_emp_pre,
  sd_log_emp_all = sd_log_emp_all,
  asian_vs_white_ratio = asian_vs_white
)
saveRDS(results, "../data/main_results.rds")

# Diagnostics for validator
n_treated <- n_distinct(df$fips[df$bartik_tariff > median(df$bartik_tariff) & df$post == 1])
n_pre <- length(unique(df$time_id[df$post == 0]))
n_obs <- nrow(df)

diagnostics <- list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save final panel with rel_time
saveRDS(df, "../data/analysis_panel_final.rds")

cat("\nDiagnostics:", paste(names(diagnostics), diagnostics, sep = "=", collapse = ", "), "\n")
cat("Main analysis complete.\n")
