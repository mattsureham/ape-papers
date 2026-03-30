## 02_clean_data.R — Variable construction and panel diagnostics
## apep_1164: The Formalization Dividend
source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
treatment <- readRDS(file.path(data_dir, "treatment_intensity.rds"))

# ============================================================
# 1. Additional variable construction
# ============================================================

panel <- panel %>%
  mutate(
    # Event time relative to ETPV (March 2021 → year 2021)
    event_time = year - 2021,

    # Log outcomes for semi-elasticity interpretation
    log_employed = log(employed * 1000),
    log_labor_force = log(labor_force * 1000),
    log_pop = log(pop_total * 1000),

    # Employment-to-population ratio (alternative to TO which is occupation rate)
    emp_pop_ratio = employed / pop_total * 100,

    # Labor force participation is TGP (already in dataset)
    # Unemployment rate is TD (already in dataset)

    # Treatment quartiles for heterogeneity
    ven_quartile = cut(ven_share,
                       breaks = quantile(ven_share, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
                       labels = c("Q1_Low", "Q2", "Q3", "Q4_High"),
                       include.lowest = TRUE),

    # Binary high-treatment indicator (above median)
    high_ven = as.integer(ven_share > median(ven_share, na.rm = TRUE)),

    # Department and year as factors for FE
    dept_fe = factor(department),
    year_fe = factor(year)
  )

# ============================================================
# 2. Descriptive statistics
# ============================================================
cat("=== Panel Descriptive Statistics ===\n\n")

cat("Treatment intensity (Venezuelan share) by quartile:\n")
panel %>%
  filter(year == 2019) %>%
  group_by(ven_quartile) %>%
  summarise(
    n_depts = n(),
    mean_ven_share = round(mean(ven_share), 2),
    mean_to = round(mean(to, na.rm=TRUE), 1),
    mean_td = round(mean(td, na.rm=TRUE), 1),
    mean_tgp = round(mean(tgp, na.rm=TRUE), 1),
    .groups = "drop"
  ) %>%
  print()

cat("\n\nPre-treatment balance (2019):\n")
pre_balance <- panel %>%
  filter(year == 2019) %>%
  select(department, ven_share, to, td, tgp, ts, pop_total) %>%
  arrange(desc(ven_share))
print(as.data.frame(pre_balance))

cat("\n\nMean outcomes by period:\n")
panel %>%
  mutate(period = ifelse(year < 2021, "Pre (2015-2020)", "Post (2021-2024)")) %>%
  group_by(period) %>%
  summarise(
    TO = round(mean(to, na.rm=TRUE), 2),
    TD = round(mean(td, na.rm=TRUE), 2),
    TGP = round(mean(tgp, na.rm=TRUE), 2),
    .groups = "drop"
  ) %>%
  print()

# ============================================================
# 3. COVID adjustment
# ============================================================
# 2020 is severely affected by COVID lockdowns
# We exclude 2020 from the main pre-period but include it in robustness
cat("\n\nNote on COVID: 2020 shows major disruptions\n")
panel %>%
  filter(year %in% c(2019, 2020, 2021)) %>%
  group_by(year) %>%
  summarise(mean_to = round(mean(to, na.rm=TRUE), 1), .groups = "drop") %>%
  print()

# Create COVID-adjusted panel (excluding 2020)
panel_no_covid <- panel %>% filter(year != 2020)
cat("Panel without 2020:", nrow(panel_no_covid), "observations\n")

# ============================================================
# 4. Save
# ============================================================
saveRDS(panel, file.path(data_dir, "panel_clean.rds"))
saveRDS(panel_no_covid, file.path(data_dir, "panel_no_covid.rds"))

cat("\n=== Cleaning complete ===\n")
