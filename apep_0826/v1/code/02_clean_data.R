# =============================================================================
# 02_clean_data.R — Construct analysis dataset
# =============================================================================

source("00_packages.R")

cat("=== Loading raw data ===\n")
qwi_mining <- read_csv("../data/qwi_mining.csv.gz", show_col_types = FALSE)
qwi_total <- read_csv("../data/qwi_total.csv.gz", show_col_types = FALSE)
prices <- read_csv("../data/commodity_prices.csv", show_col_types = FALSE)

# --- 1. Construct county-level coal vs. oil/gas shares (2013 baseline) ---
cat("Constructing coal/oil shares (2013 baseline)...\n")

baseline_2013 <- qwi_mining %>%
  filter(year == 2013) %>%
  group_by(geography, industry) %>%
  summarise(emp_annual = mean(emp, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = industry, values_from = emp_annual,
              names_prefix = "emp_", values_fill = 0)

# Counties must have mining employment to be in sample
baseline_2013 <- baseline_2013 %>%
  mutate(
    emp_mining_total = emp_211 + emp_212 + emp_213,
    coal_share = emp_212 / pmax(emp_mining_total, 1),
    oilgas_share = emp_211 / pmax(emp_mining_total, 1),
    is_coal_county = coal_share > 0.5,
    is_oilgas_county = oilgas_share > 0.5
  ) %>%
  filter(emp_mining_total >= 10) # Minimum mining presence

cat(sprintf("  Counties with mining: %d\n", nrow(baseline_2013)))
cat(sprintf("  Coal-dominant (>50%%): %d\n", sum(baseline_2013$is_coal_county)))
cat(sprintf("  Oil/gas-dominant (>50%%): %d\n", sum(baseline_2013$is_oilgas_county)))

# --- 2. Build county-quarter panel ---
cat("Building county-quarter panel...\n")

# Aggregate QWI mining to county-quarter level (sum across 211+212+213)
panel <- qwi_mining %>%
  filter(geography %in% baseline_2013$geography) %>%
  group_by(geography, state_fips, year, quarter) %>%
  summarise(
    emp = sum(emp, na.rm = TRUE),
    emp_end = sum(emp_end, na.rm = TRUE),
    hir_all = sum(hir_all, na.rm = TRUE),
    hir_new = sum(hir_new, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    frm_job_gain = sum(frm_job_gain, na.rm = TRUE),
    frm_job_loss = sum(frm_job_loss, na.rm = TRUE),
    .groups = "drop"
  )

# Also keep industry-specific employment for mechanism analysis
panel_by_industry <- qwi_mining %>%
  filter(geography %in% baseline_2013$geography) %>%
  select(geography, state_fips, year, quarter, industry, emp, sep, hir_new, earn_s)

# Merge baseline shares
panel <- panel %>%
  left_join(baseline_2013 %>% select(geography, coal_share, oilgas_share,
                                       is_coal_county, is_oilgas_county,
                                       emp_mining_total),
            by = "geography")

# Merge total employment
panel <- panel %>%
  left_join(qwi_total %>% select(geography, year, quarter, emp_total, earn_total),
            by = c("geography", "year", "quarter"))

# Merge commodity prices
panel <- panel %>%
  left_join(prices, by = c("year", "quarter"))

# --- 3. Create time variables ---
cat("Creating time and treatment variables...\n")

panel <- panel %>%
  mutate(
    time_q = year + (quarter - 1) / 4,
    post = as.integer(time_q >= 2014.5),  # Q3 2014 = 2014.5
    rel_quarter = (year - 2014) * 4 + (quarter - 3),  # 0 = Q3 2014
    treatment = coal_share * post,  # Continuous DiD
    coal_x_post = is_coal_county * post,  # Binary DiD
    # Log outcomes (add 1 to handle zeros)
    log_emp = log(pmax(emp, 1)),
    log_sep = log(pmax(sep, 1)),
    log_hir = log(pmax(hir_new, 1)),
    # Separation rate
    sep_rate = sep / pmax(emp, 1),
    # Coal price control
    coal_price_x_share = coal_price * coal_share,
    oil_price_x_share = oil_price * oilgas_share,
    # State-quarter FE identifier
    state_quarter = paste0(state_fips, "_", year, "Q", quarter),
    county_id = geography
  )

# --- 4. Restrict sample ---
# Drop if zero employment throughout or missing key variables
panel <- panel %>%
  group_by(county_id) %>%
  mutate(ever_has_emp = any(emp > 0, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(ever_has_emp) %>%
  select(-ever_has_emp)

# Trim to analysis window: 2011Q1 - 2019Q4
panel <- panel %>%
  filter(year >= 2011 & year <= 2019)

cat(sprintf("  Final panel: %d observations\n", nrow(panel)))
cat(sprintf("  Counties: %d\n", n_distinct(panel$county_id)))
cat(sprintf("  Time periods: %d quarters\n", n_distinct(panel$time_q)))
cat(sprintf("  Coal counties: %d\n", n_distinct(panel$county_id[panel$is_coal_county])))
cat(sprintf("  Oil/gas counties: %d\n", n_distinct(panel$county_id[panel$is_oilgas_county])))

# --- 5. Save ---
write_csv(panel, "../data/analysis_panel.csv.gz")
write_csv(panel_by_industry, "../data/panel_by_industry.csv.gz")
write_csv(baseline_2013, "../data/baseline_2013.csv")

cat("Saved analysis_panel.csv.gz and baseline_2013.csv\n")
