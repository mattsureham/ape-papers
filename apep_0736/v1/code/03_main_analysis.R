## 03_main_analysis.R — Main regression analysis
## apep_0736: Who Counts the Dead?

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
border_panel <- readRDS(file.path(data_dir, "border_panel.rds"))
pair_panel <- readRDS(file.path(data_dir, "pair_panel.rds"))
cross_mdi <- readRDS(file.path(data_dir, "cross_mdi_pairs.rds"))

# ─────────────────────────────────────────────────────────────────────
# Summary statistics
# ─────────────────────────────────────────────────────────────────────
cat("=== Summary Statistics ===\n")

# Compare coroner vs ME counties
summary_by_mdi <- panel %>%
  filter(year == 2019) %>%
  group_by(mdi_type) %>%
  summarise(
    n_counties = n(),
    mean_od_rate = mean(od_rate, na.rm = TRUE),
    sd_od_rate = sd(od_rate, na.rm = TRUE),
    median_pop = median(population, na.rm = TRUE),
    mean_pct_poverty = mean(pct_poverty, na.rm = TRUE),
    mean_pct_black = mean(pct_black, na.rm = TRUE),
    mean_pct_white = mean(pct_white, na.rm = TRUE),
    mean_median_income = mean(median_income, na.rm = TRUE),
    .groups = "drop"
  )

print(summary_by_mdi)
cat("\n")

# Border pair summary
border_summary <- border_panel %>%
  filter(year == 2019) %>%
  group_by(mdi_type) %>%
  summarise(
    n_counties = n(),
    mean_od_rate = mean(od_rate, na.rm = TRUE),
    sd_od_rate = sd(od_rate, na.rm = TRUE),
    mean_pct_poverty = mean(pct_poverty, na.rm = TRUE),
    .groups = "drop"
  )

cat("Border counties in 2019:\n")
print(border_summary)

# ─────────────────────────────────────────────────────────────────────
# Specification 1: Full panel, State FE
# od_rate ~ is_coroner + controls + state_fips FE + year FE
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Specification 1: Full Panel, State + Year FE ===\n")

# Restrict to coroner vs ME counties (drop "Other County Official")
panel_cm <- panel %>% filter(is_coroner == 1 | is_me == 1)

# 1a: No controls
m1a <- feols(od_rate ~ is_coroner | state_fips + year, data = panel_cm,
             cluster = ~state_fips)

# 1b: With demographic controls
m1b <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
               state_fips + year, data = panel_cm, cluster = ~state_fips)

# 1c: Add urban/rural controls
m1c <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
               state_fips + year + urban_rural, data = panel_cm, cluster = ~state_fips)

cat("Model 1a (no controls):\n")
summary(m1a)
cat("\nModel 1b (demographics):\n")
summary(m1b)
cat("\nModel 1c (+ urban/rural FE):\n")
summary(m1c)

# ─────────────────────────────────────────────────────────────────────
# Specification 2: Border pair design, Pair × Year FE
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Specification 2: Border Pair Design ===\n")

# Restrict pair panel to coroner vs ME
pair_cm <- pair_panel %>%
  filter(is_coroner == 1 | is_me == 1) %>%
  mutate(pair_year = paste0(pair_id, "_", year))

# 2a: Pair FE + Year FE
m2a <- feols(od_rate ~ is_coroner | pair_id + year, data = pair_cm,
             cluster = ~state_fips)

# 2b: Pair × Year FE (strictest: within-pair, within-year comparison)
m2b <- feols(od_rate ~ is_coroner + log_pop + pct_poverty | pair_year,
             data = pair_cm, cluster = ~state_fips)

cat("Model 2a (pair + year FE):\n")
summary(m2a)
cat("\nModel 2b (pair × year FE):\n")
summary(m2b)

# ─────────────────────────────────────────────────────────────────────
# Specification 3: Time evolution of the detection gap
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Specification 3: Detection Gap Over Time ===\n")

# Create 4 time periods
panel_cm <- panel_cm %>%
  mutate(
    period = case_when(
      year <= 2006 ~ "2003-2006",
      year <= 2010 ~ "2007-2010",
      year <= 2015 ~ "2011-2015",
      TRUE ~ "2016-2021"
    ),
    period = factor(period, levels = c("2003-2006", "2007-2010", "2011-2015", "2016-2021"))
  )

m3 <- feols(od_rate ~ is_coroner:period | state_fips + year,
            data = panel_cm, cluster = ~state_fips)

cat("Model 3 (coroner × period interaction):\n")
summary(m3)

# ─────────────────────────────────────────────────────────────────────
# Specification 4: Elected vs appointed (mechanism)
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Specification 4: Elected vs Appointed ===\n")

m4 <- feols(od_rate ~ elected + log_pop + pct_poverty + pct_black + pct_white |
              state_fips + year, data = panel_cm, cluster = ~state_fips)

cat("Model 4 (elected dummy):\n")
summary(m4)

# ─────────────────────────────────────────────────────────────────────
# Store key results for tables
# ─────────────────────────────────────────────────────────────────────
results <- list(
  m1a = m1a, m1b = m1b, m1c = m1c,
  m2a = m2a, m2b = m2b,
  m3 = m3, m4 = m4,
  summary_by_mdi = summary_by_mdi,
  border_summary = border_summary
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# ─────────────────────────────────────────────────────────────────────
# Write diagnostics.json for validate_v1
# ─────────────────────────────────────────────────────────────────────
n_treated <- n_distinct(panel_cm$fips[panel_cm$is_coroner == 1])
n_pre <- length(unique(panel_cm$year[panel_cm$year <= 2010]))
n_obs <- nrow(panel_cm)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs,
    n_border_pairs = nrow(cross_mdi),
    n_border_counties = n_distinct(border_panel$fips)
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated, n_pre, n_obs))
cat("\n=== Main analysis complete ===\n")
