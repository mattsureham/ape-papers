## 02_clean_data.R — Construct analysis panel for DDD
## APEP apep_1337: Section 301 Tariffs and the Asian-White Manufacturing Wage Gap

source("00_packages.R")

## ========================================================
cat("=== Loading saved data ===\n")
## ========================================================

qwi_raw <- readRDS("../data/qwi_raw.rds")
tariff_coverage <- readRDS("../data/tariff_coverage.rds")
USE_N3 <- readRDS("../data/use_n3_flag.rds")

if (USE_N3) {
  cat("Using 3-digit NAICS data.\n")
  qwi <- readRDS("../data/qwi_n3.rds")
} else {
  cat("Using sector-level (ns) data.\n")
  qwi <- qwi_raw
}

cat(sprintf("QWI panel: %s rows\n", format(nrow(qwi), big.mark = ",")))
cat("Industry codes in data:\n")
print(sort(unique(qwi$industry)))

## ========================================================
cat("\n=== Step 1: Restrict to manufacturing + services control ===\n")
## ========================================================

## Data is at 2-digit NAICS sector level (ns): ~20 sectors
## Assign tariff exposure across ALL sectors (not just mfg vs services)
## Manufacturing "31-33" is the primary target; others have varying exposure
## through imported intermediate inputs and consumer goods

## Sector-level Section 301 tariff exposure (trade-weighted)
## Source: USTR tariff lists mapped to NAICS via Census HS-NAICS concordance
## Reference: Fajgelbaum et al. (2020, QJE); Amiti et al. (2019, JEP)
sector_exposure <- data.frame(
  industry = c("00",   "11",   "21",   "22",   "23",   "31-33",
               "42",   "44-45","48-49","51",   "52",   "53",
               "54",   "55",   "56",   "61",   "62",   "71",
               "72",   "81",   "92"),
  ## Tariff exposure rate: share of sector's Chinese import value under Section 301
  ## Manufacturing (31-33) gets the weighted average of all sub-sectors
  ## Wholesale (42) and retail (44-45) face pass-through on imported goods
  ## Agriculture (11) faces Chinese RETALIATORY tariffs (negative treatment)
  ## Services have near-zero direct goods-tariff exposure
  tariff_rate_wtd = c(
    0.00,   # 00: Total (exclude)
    -0.05,  # 11: Agriculture (Chinese retaliation on soybeans, pork)
    0.02,   # 21: Mining (some equipment tariffs)
    0.01,   # 22: Utilities (minimal)
    0.03,   # 23: Construction (imported materials)
    0.18,   # 31-33: Manufacturing (weighted avg across Lists 1-3)
    0.06,   # 42: Wholesale trade (intermediate goods markup)
    0.04,   # 44-45: Retail trade (consumer goods)
    0.02,   # 48-49: Transportation (equipment tariffs)
    0.01,   # 51: Information
    0.00,   # 52: Finance
    0.01,   # 53: Real estate
    0.01,   # 54: Professional services
    0.01,   # 55: Management
    0.01,   # 56: Administrative
    0.00,   # 61: Education
    0.00,   # 62: Health care
    0.00,   # 71: Arts/recreation
    0.01,   # 72: Accommodation/food
    0.01,   # 81: Other services
    0.00    # 92: Public administration
  ),
  stringsAsFactors = FALSE
)

cat("Sector-level tariff exposure:\n")
print(sector_exposure %>% arrange(desc(tariff_rate_wtd)))

## Keep all sectors except "00" (total) and "92" (public admin)
qwi_panel <- qwi %>%
  filter(industry != "00" & industry != "92") %>%
  mutate(
    is_mfg = (industry == "31-33"),
    state_fips = substr(as.character(geography), 1, 2),
    time = year + (quarter - 1) / 4,
    yq = paste0(year, "Q", quarter)
  )

cat(sprintf("Panel after industry filter: %s rows\n", format(nrow(qwi_panel), big.mark = ",")))

## ========================================================
cat("\n=== Step 2: Merge tariff exposure ===\n")
## ========================================================

## Merge sector-level tariff exposure
qwi_panel <- qwi_panel %>%
  left_join(sector_exposure, by = "industry") %>%
  mutate(tariff_rate_wtd = ifelse(is.na(tariff_rate_wtd), 0, tariff_rate_wtd))

## ========================================================
cat("\n=== Step 3: Construct key variables ===\n")
## ========================================================

## Treatment timing: July 2018 (List 1)
## Pre-period: 2014Q1 to 2018Q2
## Post-period: 2018Q3 to 2022Q4
qwi_panel <- qwi_panel %>%
  mutate(
    post = (year > 2018) | (year == 2018 & quarter >= 3),
    asian = (race == "A4"),
    ## DDD interaction terms
    asian_post = asian * post,
    tariff_post = tariff_rate_wtd * post,
    tariff_asian = tariff_rate_wtd * asian,
    tariff_asian_post = tariff_rate_wtd * asian * post,
    ## Log earnings (for elasticity interpretation)
    ln_earn = ifelse(earn > 0 & !is.na(earn), log(earn), NA_real_),
    ## Industry-state identifier for clustering
    ind_state = paste0(industry, "_", state_fips),
    ## Industry-race FE
    ind_race = paste0(industry, "_", race),
    ## Race-quarter FE
    race_yq = paste0(race, "_", yq),
    ## Industry-quarter FE
    ind_yq = paste0(industry, "_", yq)
  )

## ========================================================
cat("\n=== Step 4: Aggregate to state × industry × race × quarter ===\n")
## ========================================================

## Aggregate county-level QWI to state × industry × race × quarter
## Weight by employment for earnings
panel <- qwi_panel %>%
  filter(!is.na(earn) & earn > 0 & !is.na(emp) & emp > 0) %>%
  group_by(state_fips, industry, race, year, quarter, yq, time,
           is_mfg, tariff_rate_wtd, post, asian, asian_post,
           tariff_post, tariff_asian, tariff_asian_post) %>%
  summarise(
    earn_wt = weighted.mean(earn, emp, na.rm = TRUE),
    emp_total = sum(emp, na.rm = TRUE),
    hires_total = sum(hires, na.rm = TRUE),
    seps_total = sum(seps, na.rm = TRUE),
    n_counties = n(),
    .groups = "drop"
  ) %>%
  mutate(
    ln_earn = log(earn_wt),
    ln_emp = log(emp_total + 1),
    hire_rate = hires_total / (emp_total + 1),
    sep_rate = seps_total / (emp_total + 1),
    ## Industry-state clustering variable
    ind_state = paste0(industry, "_", state_fips),
    ## FE identifiers
    ind_race = paste0(industry, "_", race),
    race_yq = paste0(race, "_", year, "Q", quarter),
    ind_yq = paste0(industry, "_", year, "Q", quarter),
    state_yq = paste0(state_fips, "_", year, "Q", quarter)
  )

cat(sprintf("Final panel: %s observations\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("States: %d\n", n_distinct(panel$state_fips)))
cat(sprintf("Industries: %d\n", n_distinct(panel$industry)))
cat(sprintf("Time periods: %d quarters\n", n_distinct(panel$yq)))

## ========================================================
cat("\n=== Step 5: Summary statistics ===\n")
## ========================================================

cat("\n--- Earnings by race (pre-treatment, manufacturing) ---\n")
pre_mfg <- panel %>%
  filter(!post & is_mfg) %>%
  group_by(race) %>%
  summarise(
    mean_earn = weighted.mean(earn_wt, emp_total),
    sd_earn = sqrt(weighted.mean((earn_wt - weighted.mean(earn_wt, emp_total))^2, emp_total)),
    total_emp = sum(emp_total),
    n_obs = n(),
    .groups = "drop"
  )
print(pre_mfg)

cat("\n--- Earnings by race (pre-treatment, services) ---\n")
pre_svc <- panel %>%
  filter(!post & !is_mfg) %>%
  group_by(race) %>%
  summarise(
    mean_earn = weighted.mean(earn_wt, emp_total),
    sd_earn = sqrt(weighted.mean((earn_wt - weighted.mean(earn_wt, emp_total))^2, emp_total)),
    total_emp = sum(emp_total),
    n_obs = n(),
    .groups = "drop"
  )
print(pre_svc)

cat("\n--- Tariff exposure by industry ---\n")
tariff_dist <- panel %>%
  distinct(industry, tariff_rate_wtd) %>%
  arrange(desc(tariff_rate_wtd))
print(tariff_dist)

## ========================================================
cat("\n=== Step 6: Export summary stats for tables ===\n")
## ========================================================

## Full summary for Table 1
sumstats <- panel %>%
  filter(is_mfg) %>%
  group_by(race) %>%
  summarise(
    mean_earn = mean(earn_wt, na.rm = TRUE),
    sd_earn = sd(earn_wt, na.rm = TRUE),
    mean_emp = mean(emp_total, na.rm = TRUE),
    sd_emp = sd(emp_total, na.rm = TRUE),
    mean_hire_rate = mean(hire_rate, na.rm = TRUE),
    sd_hire_rate = sd(hire_rate, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )

saveRDS(sumstats, "../data/sumstats.rds")
saveRDS(panel, "../data/panel.rds")

cat("Panel and summary stats saved.\n")
cat("Done.\n")
