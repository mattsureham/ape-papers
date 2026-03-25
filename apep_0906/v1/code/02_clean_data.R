## 02_clean_data.R — Construct analysis panel
## apep_0906: Panama Canal Expansion and Port Labor Markets

library(tidyverse)
library(data.table)

data_dir <- file.path(dirname(getwd()), "data")

# Load fetched data
qwi <- readRDS(file.path(data_dir, "qwi_ports.rds"))
ports <- readRDS(file.path(data_dir, "port_counties.rds"))

cat("Raw QWI rows:", nrow(qwi), "\n")

# ============================================================
# 1. CONSTRUCT TIME VARIABLES
# ============================================================

panel <- qwi %>%
  mutate(
    # Time period: quarters since 2010Q1
    time_q = (year - 2010) * 4 + quarter,
    # Calendar quarter (for seasonality)
    cal_quarter = quarter,
    # Post-expansion indicator (June 26, 2016 = start of Q3 2016)
    post = as.integer(year > 2016 | (year == 2016 & quarter >= 3)),
    # Treatment indicator: East/Gulf coast port
    treated = as.integer(region %in% c("East", "Gulf")),
    # County identifier
    county_id = paste0(state, county),
    # Log employment (handle zeros)
    log_emp = ifelse(Emp > 0, log(Emp), NA_real_),
    # Hiring rate
    hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    # Separation rate
    sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_),
    # Log earnings
    log_earn = ifelse(EarnBeg > 0, log(EarnBeg), NA_real_)
  )

# ============================================================
# 2. TREATMENT INTENSITY
# ============================================================

# Measure 1: Simple binary (East/Gulf vs West)
# Measure 2: Pre-expansion transport employment share
# (counties more reliant on transport are more exposed)

pre_emp <- panel %>%
  filter(year %in% 2013:2015, industry == "48-49") %>%
  group_by(county_id, port_name, region, treated) %>%
  summarise(
    mean_emp_pre = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  )

# Compute intensity: rank-based measure (to avoid scale differences)
pre_emp <- pre_emp %>%
  mutate(
    emp_rank = rank(mean_emp_pre) / n(),
    # For East/Gulf: higher pre-expansion employment = more treatment exposure
    # For West: treatment intensity is negative (potential loss)
    intensity = case_when(
      region %in% c("East", "Gulf") ~ emp_rank,
      region == "West" ~ 0  # West Coast is the control
    )
  )

panel <- panel %>%
  left_join(pre_emp %>% select(county_id, mean_emp_pre, intensity),
            by = "county_id")

# ============================================================
# 3. EVENT STUDY TIME VARIABLES
# ============================================================

# Event time relative to 2016 Q3 (expansion opening)
panel <- panel %>%
  mutate(
    event_time = (year - 2016) * 4 + (quarter - 3),
    # Bin extreme event times
    event_time_binned = case_when(
      event_time < -12 ~ -12L,
      event_time > 20 ~ 20L,
      TRUE ~ as.integer(event_time)
    )
  )

# ============================================================
# 4. VALIDATE PANEL
# ============================================================

cat("\n=== PANEL SUMMARY ===\n")
cat("Total observations:", nrow(panel), "\n")
cat("Unique counties:", n_distinct(panel$county_id), "\n")
cat("Time range:", min(panel$year), "Q", min(panel$quarter[panel$year == min(panel$year)]),
    "to", max(panel$year), "Q", max(panel$quarter[panel$year == max(panel$year)]), "\n")

cat("\nBy region and industry:\n")
panel %>%
  group_by(region, industry) %>%
  summarise(
    n_counties = n_distinct(county_id),
    n_obs = n(),
    mean_emp = round(mean(Emp, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  print()

cat("\nTreatment groups:\n")
panel %>%
  filter(industry == "48-49") %>%
  group_by(treated, post) %>%
  summarise(
    n = n(),
    mean_emp = round(mean(Emp, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  print()

# ============================================================
# 5. SAVE ANALYSIS PANEL
# ============================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis panel:", nrow(panel), "rows\n")
