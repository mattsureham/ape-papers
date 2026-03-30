# ==============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# ==============================================================================
source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
exposure <- readRDS("../data/exposure.rds")
qwi_rh <- readRDS("../data/qwi_rh_raw.rds")

waste <- panel %>%
  filter(industry == "562") %>%
  mutate(county_id = as.integer(factor(fips)))

# ==============================================================================
# 1. PLACEBO SECTORS: NAICS 722 (Food Services) — no waste channel
# ==============================================================================
cat("=== Placebo: NAICS 722 (Food Services) ===\n")

food <- panel %>%
  filter(industry == "722") %>%
  mutate(log_emp = log(Emp + 1))

m_placebo_722 <- feols(log_emp ~ high_exposure:post | fips + time_q,
                       data = food, cluster = ~state_fips)
cat("Food services (722):\n")
print(summary(m_placebo_722))

# NAICS 541 (Professional Services)
cat("\n=== Placebo: NAICS 541 (Professional Services) ===\n")
prof <- panel %>%
  filter(industry == "541") %>%
  mutate(log_emp = log(Emp + 1))

m_placebo_541 <- feols(log_emp ~ high_exposure:post | fips + time_q,
                       data = prof, cluster = ~state_fips)
cat("Professional services (541):\n")
print(summary(m_placebo_541))

# ==============================================================================
# 2. CONTINUOUS TREATMENT INTENSITY (terciles)
# ==============================================================================
cat("\n=== Continuous treatment: exposure terciles ===\n")

waste <- waste %>%
  mutate(
    exposure_tercile = ntile(waste_share, 3),
    high_tercile = as.integer(exposure_tercile == 3),
    mid_tercile = as.integer(exposure_tercile == 2)
  )

m_tercile <- feols(log_emp ~ high_tercile:post + mid_tercile:post | fips + time_q,
                   data = waste, cluster = ~state_fips)
cat("Tercile specification:\n")
print(summary(m_tercile))

# ==============================================================================
# 3. DONUT HOLE (exclude announcement period 2017Q3-2017Q4)
# ==============================================================================
cat("\n=== Donut hole: exclude 2017Q3-Q4 ===\n")

waste_donut <- waste %>%
  filter(!(year == 2017 & quarter >= 3))

m_donut <- feols(log_emp ~ high_exposure:post | fips + time_q,
                 data = waste_donut, cluster = ~state_fips)
cat("Donut hole estimate:\n")
print(summary(m_donut))

# ==============================================================================
# 4. SCRAP WHOLESALERS (NAICS 423) — adjacent affected sector
# ==============================================================================
cat("\n=== NAICS 423 (Merchant Wholesalers — includes scrap) ===\n")

scrap <- panel %>%
  filter(industry == "423") %>%
  mutate(log_emp = log(Emp + 1))

m_scrap <- feols(log_emp ~ high_exposure:post | fips + time_q,
                 data = scrap, cluster = ~state_fips)
cat("Merchant wholesalers (423):\n")
print(summary(m_scrap))

# ==============================================================================
# 5. RACE DECOMPOSITION (NAICS 562)
# ==============================================================================
cat("\n=== Race Decomposition (NAICS 562) ===\n")

qwi_rh_clean <- qwi_rh %>%
  mutate(
    fips = as.character(fips),
    time_q = (year - 2013) * 4 + quarter,
    log_emp = log(Emp + 1)
  ) %>%
  filter(!is.na(Emp), race %in% c("A1", "A2")) %>%
  inner_join(exposure %>% select(fips, high_exposure, waste_share), by = "fips") %>%
  mutate(
    post = as.integer(year >= 2018),
    state_fips = substr(fips, 1, 2),
    race_label = case_when(
      race == "A1" ~ "White",
      race == "A2" ~ "Non-White",
      TRUE ~ "Other"
    )
  )

for (r in c("White", "Non-White")) {
  cat(sprintf("\nRace: %s\n", r))
  sub <- qwi_rh_clean %>% filter(race_label == r)
  m_race <- feols(log_emp ~ high_exposure:post | fips + time_q,
                  data = sub, cluster = ~state_fips)
  print(summary(m_race))
}

# ==============================================================================
# 6. HIRES AND SEPARATIONS
# ==============================================================================
cat("\n=== Hires and Separations ===\n")

m_hires <- feols(log(HirA + 1) ~ high_exposure:post | fips + time_q,
                 data = waste, cluster = ~state_fips)
m_sep <- feols(log(Sep + 1) ~ high_exposure:post | fips + time_q,
               data = waste, cluster = ~state_fips)

cat("Hires:\n")
print(summary(m_hires))
cat("\nSeparations:\n")
print(summary(m_sep))

# ==============================================================================
# Save robustness results
# ==============================================================================
rob_results <- list(
  placebo_722 = m_placebo_722,
  placebo_541 = m_placebo_541,
  tercile = m_tercile,
  donut = m_donut,
  scrap_423 = m_scrap,
  hires = m_hires,
  sep = m_sep
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
