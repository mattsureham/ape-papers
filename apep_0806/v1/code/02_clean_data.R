## 02_clean_data.R — Construct analysis variables
## apep_0806: Ireland Rent Pressure Zones

source("00_packages.R")

panel <- readRDS("../data/rent_panel.rds")

# ── 1. Create rent growth variable ───────────────────────────────────────
panel <- panel %>%
  arrange(county, time_id) %>%
  group_by(county) %>%
  mutate(
    rent_lag1  = dplyr::lag(rent_eur, 1),
    rent_lag4  = dplyr::lag(rent_eur, 4),  # same quarter previous year
    # Quarter-on-quarter growth
    rent_growth_qq = (rent_eur - rent_lag1) / rent_lag1 * 100,
    # Year-on-year growth (same quarter)
    rent_growth_yy = (rent_eur - rent_lag4) / rent_lag4 * 100,
    # Log first difference (approx quarterly growth)
    dlog_rent = log_rent - dplyr::lag(log_rent, 1),
    # Annualised YoY log change
    dlog_rent_yy = log_rent - dplyr::lag(log_rent, 4)
  ) %>%
  ungroup()

# ── 2. Pre-treatment summary statistics ──────────────────────────────────
# Define pre-treatment as before first RPZ designation (2016Q3)
pre <- panel %>% filter(time_id < (2016 * 4 + 4))  # before 2016Q4

pre_stats <- pre %>%
  group_by(county) %>%
  summarise(
    mean_rent     = mean(rent_eur, na.rm = TRUE),
    sd_rent       = sd(rent_eur, na.rm = TRUE),
    mean_growth   = mean(rent_growth_yy, na.rm = TRUE),
    n_quarters    = n(),
    .groups = "drop"
  )

cat("Pre-treatment summary (before 2016Q4):\n")
print(pre_stats %>% arrange(desc(mean_rent)), n = 26)

# ── 3. Treatment cohort labels ───────────────────────────────────────────
cohort_labels <- tribble(
  ~rpz_yq,   ~cohort_label,
  "2016Q4",  "Wave 1: Dec 2016",
  "2017Q1",  "Wave 2: Jan 2017",
  "2017Q3",  "Wave 3: Sep 2017",
  "2018Q1",  "Wave 4: Jan 2018",
  "2019Q1",  "Wave 5: Jan 2019",
  "2021Q3",  "Wave 6: Aug 2021 (national)"
)

panel <- panel %>%
  left_join(
    readRDS("../data/rpz_dates.rds") %>% select(county, rpz_yq),
    by = c("county", "rpz_yq" = "rpz_yq")
  ) %>%
  # rpz_yq already exists from 01_fetch
  left_join(cohort_labels, by = "rpz_yq") %>%
  mutate(
    cohort_label = factor(cohort_label),
    early_treated = rpz_yq %in% c("2016Q4", "2017Q1", "2017Q3"),
    late_treated  = rpz_yq == "2021Q3"
  )

# ── 4. Panel balance check ──────────────────────────────────────────────
panel_balance <- panel %>%
  count(county) %>%
  summarise(
    min_obs = min(n),
    max_obs = max(n),
    balanced = min(n) == max(n)
  )
cat("\nPanel balance:", ifelse(panel_balance$balanced, "BALANCED", "UNBALANCED"),
    "(", panel_balance$min_obs, "-", panel_balance$max_obs, "obs per county)\n")

# ── 5. Descriptive statistics table ──────────────────────────────────────
# Summary by early-treated, mid-treated, late-treated
desc_table <- panel %>%
  filter(year >= 2012, year <= 2016) %>%
  mutate(
    treat_group = case_when(
      rpz_yq %in% c("2016Q4", "2017Q1") ~ "Early (2016-17)",
      rpz_yq %in% c("2017Q3", "2018Q1", "2019Q1") ~ "Mid (2017-19)",
      TRUE ~ "Late/National (2021)"
    )
  ) %>%
  group_by(treat_group) %>%
  summarise(
    n_counties   = n_distinct(county),
    mean_rent    = mean(rent_eur, na.rm = TRUE),
    sd_rent      = sd(rent_eur, na.rm = TRUE),
    mean_yy_growth = mean(rent_growth_yy, na.rm = TRUE),
    sd_yy_growth = sd(rent_growth_yy, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment descriptives by treatment wave:\n")
print(desc_table)

# ── 6. Save ──────────────────────────────────────────────────────────────
saveRDS(panel, "../data/analysis_panel.rds")
cat("\n✓ Analysis panel saved: data/analysis_panel.rds\n")
cat("  Obs:", nrow(panel), "\n")
cat("  Non-missing YoY growth:", sum(!is.na(panel$rent_growth_yy)), "\n")
