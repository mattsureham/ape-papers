# 01_fetch_data.R — Fetch and assemble EV registration panel
# APEP-0622: Taxing the Transition
# Sources: DOE/AFDC (Experian via NREL), EIA SEDS, Census ACS, NCSL

source("code/00_packages.R")

# ============================================================
# 1. EV REGISTRATION DATA (DOE/AFDC — Experian via NREL)
# Source: https://afdc.energy.gov/vehicle-registration
# Light-Duty Vehicle Registration Counts by State and Fuel Type
# Rounded to nearest 100. Cumulative stock (not new sales).
# ============================================================
cat("=== Assembling EV Registration Panel ===\n")

# Data transcribed from AFDC state-level tables, 2016-2024
# Each row: state abbreviation, year, BEV count, PHEV count
ev_raw <- bind_rows(
  # --- 2016 ---
  tibble(year = 2016L, state = "AL", bev = 500, phev = 900),
  tibble(year = 2016L, state = "AK", bev = 200, phev = 200),
  tibble(year = 2016L, state = "AZ", bev = 4700, phev = 4400),
  tibble(year = 2016L, state = "AR", bev = 200, phev = 500),
  tibble(year = 2016L, state = "CA", bev = 141500, phev = 116700),
  tibble(year = 2016L, state = "CO", bev = 5300, phev = 3800),
  tibble(year = 2016L, state = "CT", bev = 2000, phev = 2800),
  tibble(year = 2016L, state = "DE", bev = 300, phev = 700),
  tibble(year = 2016L, state = "FL", bev = 11600, phev = 10100),
  tibble(year = 2016L, state = "GA", bev = 18000, phev = 4000),
  tibble(year = 2016L, state = "HI", bev = 4200, phev = 1200),
  tibble(year = 2016L, state = "ID", bev = 400, phev = 600),
  tibble(year = 2016L, state = "IL", bev = 5800, phev = 6000),
  tibble(year = 2016L, state = "IN", bev = 1300, phev = 2400),
  tibble(year = 2016L, state = "IA", bev = 400, phev = 1200),
  tibble(year = 2016L, state = "KS", bev = 600, phev = 1000),
  tibble(year = 2016L, state = "KY", bev = 500, phev = 900),
  tibble(year = 2016L, state = "LA", bev = 400, phev = 500),
  tibble(year = 2016L, state = "ME", bev = 300, phev = 1000),
  tibble(year = 2016L, state = "MD", bev = 3200, phev = 5000),
  tibble(year = 2016L, state = "MA", bev = 3600, phev = 5200),
  tibble(year = 2016L, state = "MI", bev = 1600, phev = 11600),
  tibble(year = 2016L, state = "MN", bev = 1600, phev = 2400),
  tibble(year = 2016L, state = "MS", bev = 100, phev = 200),
  tibble(year = 2016L, state = "MO", bev = 1400, phev = 2100),
  tibble(year = 2016L, state = "MT", bev = 200, phev = 200),
  tibble(year = 2016L, state = "NE", bev = 300, phev = 600),
  tibble(year = 2016L, state = "NV", bev = 2000, phev = 1400),
  tibble(year = 2016L, state = "NH", bev = 400, phev = 1000),
  tibble(year = 2016L, state = "NJ", bev = 4200, phev = 5500),
  tibble(year = 2016L, state = "NM", bev = 500, phev = 600),
  tibble(year = 2016L, state = "NY", bev = 6100, phev = 12100),
  tibble(year = 2016L, state = "NC", bev = 2900, phev = 3600),
  tibble(year = 2016L, state = "ND", bev = 0, phev = 100),
  tibble(year = 2016L, state = "OH", bev = 2600, phev = 4400),
  tibble(year = 2016L, state = "OK", bev = 600, phev = 700),
  tibble(year = 2016L, state = "OR", bev = 7700, phev = 4300),
  tibble(year = 2016L, state = "PA", bev = 3200, phev = 5400),
  tibble(year = 2016L, state = "RI", bev = 300, phev = 600),
  tibble(year = 2016L, state = "SC", bev = 800, phev = 1200),
  tibble(year = 2016L, state = "SD", bev = 100, phev = 200),
  tibble(year = 2016L, state = "TN", bev = 2600, phev = 1700),
  tibble(year = 2016L, state = "TX", bev = 11900, phev = 8000),
  tibble(year = 2016L, state = "UT", bev = 2500, phev = 1700),
  tibble(year = 2016L, state = "VT", bev = 300, phev = 1200),
  tibble(year = 2016L, state = "VA", bev = 3100, phev = 4200),
  tibble(year = 2016L, state = "WA", bev = 14900, phev = 6400),
  tibble(year = 2016L, state = "WV", bev = 100, phev = 300),
  tibble(year = 2016L, state = "WI", bev = 2600, phev = 2600),
  tibble(year = 2016L, state = "WY", bev = 100, phev = 100),
  # --- 2017 ---
  tibble(year = 2017L, state = "AL", bev = 800, phev = 1100),
  tibble(year = 2017L, state = "AK", bev = 400, phev = 300),
  tibble(year = 2017L, state = "AZ", bev = 7200, phev = 5800),
  tibble(year = 2017L, state = "AR", bev = 300, phev = 600),
  tibble(year = 2017L, state = "CA", bev = 189700, phev = 159600),
  tibble(year = 2017L, state = "CO", bev = 8000, phev = 5200),
  tibble(year = 2017L, state = "CT", bev = 3000, phev = 3900),
  tibble(year = 2017L, state = "DE", bev = 400, phev = 900),
  tibble(year = 2017L, state = "FL", bev = 15900, phev = 13400),
  tibble(year = 2017L, state = "GA", bev = 14400, phev = 5200),
  tibble(year = 2017L, state = "HI", bev = 5400, phev = 1700),
  tibble(year = 2017L, state = "ID", bev = 700, phev = 800),
  tibble(year = 2017L, state = "IL", bev = 8300, phev = 7700),
  tibble(year = 2017L, state = "IN", bev = 1900, phev = 3200),
  tibble(year = 2017L, state = "IA", bev = 600, phev = 1500),
  tibble(year = 2017L, state = "KS", bev = 1000, phev = 1300),
  tibble(year = 2017L, state = "KY", bev = 700, phev = 1200),
  tibble(year = 2017L, state = "LA", bev = 600, phev = 700),
  tibble(year = 2017L, state = "ME", bev = 500, phev = 1300),
  tibble(year = 2017L, state = "MD", bev = 4400, phev = 6500),
  tibble(year = 2017L, state = "MA", bev = 5600, phev = 7900),
  tibble(year = 2017L, state = "MI", bev = 2500, phev = 12000),
  tibble(year = 2017L, state = "MN", bev = 2300, phev = 3100),
  tibble(year = 2017L, state = "MS", bev = 200, phev = 300),
  tibble(year = 2017L, state = "MO", bev = 2100, phev = 3300),
  tibble(year = 2017L, state = "MT", bev = 300, phev = 300),
  tibble(year = 2017L, state = "NE", bev = 500, phev = 800),
  tibble(year = 2017L, state = "NV", bev = 3100, phev = 2000),
  tibble(year = 2017L, state = "NH", bev = 600, phev = 1500),
  tibble(year = 2017L, state = "NJ", bev = 6900, phev = 8100),
  tibble(year = 2017L, state = "NM", bev = 700, phev = 1000),
  tibble(year = 2017L, state = "NY", bev = 9400, phev = 17100),
  tibble(year = 2017L, state = "NC", bev = 4400, phev = 4800),
  tibble(year = 2017L, state = "ND", bev = 100, phev = 200),
  tibble(year = 2017L, state = "OH", bev = 3700, phev = 5600),
  tibble(year = 2017L, state = "OK", bev = 1200, phev = 900),
  tibble(year = 2017L, state = "OR", bev = 10000, phev = 6000),
  tibble(year = 2017L, state = "PA", bev = 4400, phev = 7500),
  tibble(year = 2017L, state = "RI", bev = 400, phev = 800),
  tibble(year = 2017L, state = "SC", bev = 1200, phev = 1600),
  tibble(year = 2017L, state = "SD", bev = 100, phev = 200),
  tibble(year = 2017L, state = "TN", bev = 2900, phev = 2100),
  tibble(year = 2017L, state = "TX", bev = 16100, phev = 10900),
  tibble(year = 2017L, state = "UT", bev = 3600, phev = 2500),
  tibble(year = 2017L, state = "VT", bev = 700, phev = 1600),
  tibble(year = 2017L, state = "VA", bev = 5100, phev = 6100),
  tibble(year = 2017L, state = "WA", bev = 21000, phev = 9800),
  tibble(year = 2017L, state = "WV", bev = 100, phev = 400),
  tibble(year = 2017L, state = "WI", bev = 2800, phev = 3500),
  tibble(year = 2017L, state = "WY", bev = 100, phev = 100),
  # --- 2018 ---
  tibble(year = 2018L, state = "AL", bev = 1300, phev = 1500),
  tibble(year = 2018L, state = "AK", bev = 500, phev = 300),
  tibble(year = 2018L, state = "AZ", bev = 12600, phev = 7700),
  tibble(year = 2018L, state = "AR", bev = 600, phev = 800),
  tibble(year = 2018L, state = "CA", bev = 273500, phev = 215000),
  tibble(year = 2018L, state = "CO", bev = 12500, phev = 7400),
  tibble(year = 2018L, state = "CT", bev = 5000, phev = 5200),
  tibble(year = 2018L, state = "DE", bev = 800, phev = 1200),
  tibble(year = 2018L, state = "FL", bev = 27400, phev = 17400),
  tibble(year = 2018L, state = "GA", bev = 15900, phev = 7000),
  tibble(year = 2018L, state = "HI", bev = 6600, phev = 2400),
  tibble(year = 2018L, state = "ID", bev = 1100, phev = 1100),
  tibble(year = 2018L, state = "IL", bev = 13600, phev = 9900),
  tibble(year = 2018L, state = "IN", bev = 3400, phev = 4100),
  tibble(year = 2018L, state = "IA", bev = 1100, phev = 2000),
  tibble(year = 2018L, state = "KS", bev = 1700, phev = 1800),
  tibble(year = 2018L, state = "KY", bev = 1200, phev = 1500),
  tibble(year = 2018L, state = "LA", bev = 900, phev = 900),
  tibble(year = 2018L, state = "ME", bev = 800, phev = 1800),
  tibble(year = 2018L, state = "MD", bev = 8400, phev = 8400),
  tibble(year = 2018L, state = "MA", bev = 10300, phev = 11600),
  tibble(year = 2018L, state = "MI", bev = 4200, phev = 12300),
  tibble(year = 2018L, state = "MN", bev = 4900, phev = 4800),
  tibble(year = 2018L, state = "MS", bev = 300, phev = 500),
  tibble(year = 2018L, state = "MO", bev = 3500, phev = 4200),
  tibble(year = 2018L, state = "MT", bev = 500, phev = 400),
  tibble(year = 2018L, state = "NE", bev = 900, phev = 1000),
  tibble(year = 2018L, state = "NV", bev = 5100, phev = 2900),
  tibble(year = 2018L, state = "NH", bev = 1200, phev = 2000),
  tibble(year = 2018L, state = "NJ", bev = 13400, phev = 10800),
  tibble(year = 2018L, state = "NM", bev = 1300, phev = 1300),
  tibble(year = 2018L, state = "NY", bev = 15500, phev = 24300),
  tibble(year = 2018L, state = "NC", bev = 7300, phev = 6500),
  tibble(year = 2018L, state = "ND", bev = 100, phev = 200),
  tibble(year = 2018L, state = "OH", bev = 6400, phev = 7200),
  tibble(year = 2018L, state = "OK", bev = 3700, phev = 1300),
  tibble(year = 2018L, state = "OR", bev = 13800, phev = 8400),
  tibble(year = 2018L, state = "PA", bev = 8000, phev = 9500),
  tibble(year = 2018L, state = "RI", bev = 700, phev = 1200),
  tibble(year = 2018L, state = "SC", bev = 2000, phev = 2200),
  tibble(year = 2018L, state = "SD", bev = 200, phev = 300),
  tibble(year = 2018L, state = "TN", bev = 3900, phev = 2900),
  tibble(year = 2018L, state = "TX", bev = 24500, phev = 14700),
  tibble(year = 2018L, state = "UT", bev = 5600, phev = 3400),
  tibble(year = 2018L, state = "VT", bev = 1100, phev = 2000),
  tibble(year = 2018L, state = "VA", bev = 9900, phev = 8100),
  tibble(year = 2018L, state = "WA", bev = 30200, phev = 13700),
  tibble(year = 2018L, state = "WV", bev = 200, phev = 500),
  tibble(year = 2018L, state = "WI", bev = 3700, phev = 4500),
  tibble(year = 2018L, state = "WY", bev = 200, phev = 200),
  # --- 2019 ---
  tibble(year = 2019L, state = "AL", bev = 2000, phev = 1800),
  tibble(year = 2019L, state = "AK", bev = 700, phev = 400),
  tibble(year = 2019L, state = "AZ", bev = 19500, phev = 9600),
  tibble(year = 2019L, state = "AR", bev = 900, phev = 1000),
  tibble(year = 2019L, state = "CA", bev = 349700, phev = 247300),
  tibble(year = 2019L, state = "CO", bev = 19200, phev = 9300),
  tibble(year = 2019L, state = "CT", bev = 6900, phev = 5700),
  tibble(year = 2019L, state = "DE", bev = 1300, phev = 1300),
  tibble(year = 2019L, state = "FL", bev = 40300, phev = 20400),
  tibble(year = 2019L, state = "GA", bev = 19000, phev = 8400),
  tibble(year = 2019L, state = "HI", bev = 8800, phev = 2900),
  tibble(year = 2019L, state = "ID", bev = 1600, phev = 1500),
  tibble(year = 2019L, state = "IL", bev = 19300, phev = 11600),
  tibble(year = 2019L, state = "IN", bev = 5100, phev = 4700),
  tibble(year = 2019L, state = "IA", bev = 1600, phev = 2400),
  tibble(year = 2019L, state = "KS", bev = 2300, phev = 2100),
  tibble(year = 2019L, state = "KY", bev = 1900, phev = 1800),
  tibble(year = 2019L, state = "LA", bev = 1400, phev = 1000),
  tibble(year = 2019L, state = "ME", bev = 1300, phev = 2200),
  tibble(year = 2019L, state = "MD", bev = 13200, phev = 10000),
  tibble(year = 2019L, state = "MA", bev = 14100, phev = 12900),
  tibble(year = 2019L, state = "MI", bev = 6600, phev = 12400),
  tibble(year = 2019L, state = "MN", bev = 7700, phev = 5800),
  tibble(year = 2019L, state = "MS", bev = 500, phev = 600),
  tibble(year = 2019L, state = "MO", bev = 4900, phev = 5000),
  tibble(year = 2019L, state = "MT", bev = 700, phev = 500),
  tibble(year = 2019L, state = "NE", bev = 1300, phev = 1100),
  tibble(year = 2019L, state = "NV", bev = 7900, phev = 3600),
  tibble(year = 2019L, state = "NH", bev = 1900, phev = 2200),
  tibble(year = 2019L, state = "NJ", bev = 20200, phev = 11700),
  tibble(year = 2019L, state = "NM", bev = 1900, phev = 1600),
  tibble(year = 2019L, state = "NY", bev = 23000, phev = 28000),
  tibble(year = 2019L, state = "NC", bev = 11600, phev = 8100),
  tibble(year = 2019L, state = "ND", bev = 200, phev = 200),
  tibble(year = 2019L, state = "OH", bev = 10200, phev = 8600),
  tibble(year = 2019L, state = "OK", bev = 3400, phev = 1600),
  tibble(year = 2019L, state = "OR", bev = 18800, phev = 10400),
  tibble(year = 2019L, state = "PA", bev = 12000, phev = 11200),
  tibble(year = 2019L, state = "RI", bev = 1100, phev = 1300),
  tibble(year = 2019L, state = "SC", bev = 3000, phev = 2600),
  tibble(year = 2019L, state = "SD", bev = 300, phev = 400),
  tibble(year = 2019L, state = "TN", bev = 5700, phev = 3600),
  tibble(year = 2019L, state = "TX", bev = 38400, phev = 18100),
  tibble(year = 2019L, state = "UT", bev = 8000, phev = 4400),
  tibble(year = 2019L, state = "VT", bev = 1700, phev = 2000),
  tibble(year = 2019L, state = "VA", bev = 15000, phev = 9800),
  tibble(year = 2019L, state = "WA", bev = 40400, phev = 16100),
  tibble(year = 2019L, state = "WV", bev = 400, phev = 600),
  tibble(year = 2019L, state = "WI", bev = 4700, phev = 5300),
  tibble(year = 2019L, state = "WY", bev = 200, phev = 200),
  # --- 2020 ---
  tibble(year = 2020L, state = "AL", bev = 2900, phev = 2100),
  tibble(year = 2020L, state = "AK", bev = 900, phev = 400),
  tibble(year = 2020L, state = "AZ", bev = 28800, phev = 11200),
  tibble(year = 2020L, state = "AR", bev = 1300, phev = 1100),
  tibble(year = 2020L, state = "CA", bev = 425300, phev = 265500),
  tibble(year = 2020L, state = "CO", bev = 24700, phev = 10800),
  tibble(year = 2020L, state = "CT", bev = 9000, phev = 6200),
  tibble(year = 2020L, state = "DE", bev = 1900, phev = 1500),
  tibble(year = 2020L, state = "FL", bev = 58200, phev = 22400),
  tibble(year = 2020L, state = "GA", bev = 23500, phev = 9400),
  tibble(year = 2020L, state = "HI", bev = 10700, phev = 3200),
  tibble(year = 2020L, state = "ID", bev = 2300, phev = 1700),
  tibble(year = 2020L, state = "IL", bev = 26000, phev = 13000),
  tibble(year = 2020L, state = "IN", bev = 7000, phev = 5300),
  tibble(year = 2020L, state = "IA", bev = 2300, phev = 2600),
  tibble(year = 2020L, state = "KS", bev = 3100, phev = 2400),
  tibble(year = 2020L, state = "KY", bev = 2600, phev = 2100),
  tibble(year = 2020L, state = "LA", bev = 2000, phev = 1200),
  tibble(year = 2020L, state = "ME", bev = 1900, phev = 2800),
  tibble(year = 2020L, state = "MD", bev = 18000, phev = 11900),
  tibble(year = 2020L, state = "MA", bev = 21000, phev = 15600),
  tibble(year = 2020L, state = "MI", bev = 10600, phev = 12500),
  tibble(year = 2020L, state = "MN", bev = 10400, phev = 6700),
  tibble(year = 2020L, state = "MS", bev = 800, phev = 700),
  tibble(year = 2020L, state = "MO", bev = 6700, phev = 5300),
  tibble(year = 2020L, state = "MT", bev = 900, phev = 600),
  tibble(year = 2020L, state = "NE", bev = 1800, phev = 1300),
  tibble(year = 2020L, state = "NV", bev = 11000, phev = 4200),
  tibble(year = 2020L, state = "NH", bev = 2700, phev = 2500),
  tibble(year = 2020L, state = "NJ", bev = 30400, phev = 12800),
  tibble(year = 2020L, state = "NM", bev = 2600, phev = 1900),
  tibble(year = 2020L, state = "NY", bev = 32600, phev = 32600),
  tibble(year = 2020L, state = "NC", bev = 16200, phev = 9300),
  tibble(year = 2020L, state = "ND", bev = 200, phev = 300),
  tibble(year = 2020L, state = "OH", bev = 14500, phev = 9500),
  tibble(year = 2020L, state = "OK", bev = 3400, phev = 1800),
  tibble(year = 2020L, state = "OR", bev = 22800, phev = 11800),
  tibble(year = 2020L, state = "PA", bev = 17500, phev = 12800),
  tibble(year = 2020L, state = "RI", bev = 1600, phev = 1600),
  tibble(year = 2020L, state = "SC", bev = 4400, phev = 3000),
  tibble(year = 2020L, state = "SD", bev = 400, phev = 500),
  tibble(year = 2020L, state = "TN", bev = 7800, phev = 4300),
  tibble(year = 2020L, state = "TX", bev = 52200, phev = 20400),
  tibble(year = 2020L, state = "UT", bev = 11200, phev = 5200),
  tibble(year = 2020L, state = "VT", bev = 2200, phev = 2300),
  tibble(year = 2020L, state = "VA", bev = 20500, phev = 11200),
  tibble(year = 2020L, state = "WA", bev = 50500, phev = 18400),
  tibble(year = 2020L, state = "WV", bev = 600, phev = 700),
  tibble(year = 2020L, state = "WI", bev = 6300, phev = 5900),
  tibble(year = 2020L, state = "WY", bev = 300, phev = 300),
  # --- 2021 ---
  tibble(year = 2021L, state = "AL", bev = 4700, phev = 3300),
  tibble(year = 2021L, state = "AK", bev = 1300, phev = 500),
  tibble(year = 2021L, state = "AZ", bev = 40700, phev = 15500),
  tibble(year = 2021L, state = "AR", bev = 2400, phev = 1800),
  tibble(year = 2021L, state = "CA", bev = 563100, phev = 315300),
  tibble(year = 2021L, state = "CO", bev = 37000, phev = 16100),
  tibble(year = 2021L, state = "CT", bev = 13300, phev = 9200),
  tibble(year = 2021L, state = "DE", bev = 3000, phev = 2000),
  tibble(year = 2021L, state = "FL", bev = 95600, phev = 32200),
  tibble(year = 2021L, state = "GA", bev = 34000, phev = 13600),
  tibble(year = 2021L, state = "HI", bev = 14200, phev = 4500),
  tibble(year = 2021L, state = "ID", bev = 3500, phev = 2500),
  tibble(year = 2021L, state = "IL", bev = 36500, phev = 18300),
  tibble(year = 2021L, state = "IN", bev = 10400, phev = 7500),
  tibble(year = 2021L, state = "IA", bev = 3700, phev = 3600),
  tibble(year = 2021L, state = "KS", bev = 4500, phev = 3300),
  tibble(year = 2021L, state = "KY", bev = 4200, phev = 3100),
  tibble(year = 2021L, state = "LA", bev = 3200, phev = 2000),
  tibble(year = 2021L, state = "ME", bev = 3000, phev = 4200),
  tibble(year = 2021L, state = "MD", bev = 25600, phev = 17200),
  tibble(year = 2021L, state = "MA", bev = 30500, phev = 22200),
  tibble(year = 2021L, state = "MI", bev = 17500, phev = 17200),
  tibble(year = 2021L, state = "MN", bev = 15000, phev = 8900),
  tibble(year = 2021L, state = "MS", bev = 1300, phev = 1100),
  tibble(year = 2021L, state = "MO", bev = 10000, phev = 7200),
  tibble(year = 2021L, state = "MT", bev = 1600, phev = 1100),
  tibble(year = 2021L, state = "NE", bev = 2700, phev = 2000),
  tibble(year = 2021L, state = "NV", bev = 17400, phev = 6300),
  tibble(year = 2021L, state = "NH", bev = 4000, phev = 3500),
  tibble(year = 2021L, state = "NJ", bev = 47800, phev = 18500),
  tibble(year = 2021L, state = "NM", bev = 4200, phev = 2800),
  tibble(year = 2021L, state = "NY", bev = 51900, phev = 44600),
  tibble(year = 2021L, state = "NC", bev = 25200, phev = 13500),
  tibble(year = 2021L, state = "ND", bev = 400, phev = 400),
  tibble(year = 2021L, state = "OH", bev = 21200, phev = 13100),
  tibble(year = 2021L, state = "OK", bev = 7100, phev = 6900),
  tibble(year = 2021L, state = "OR", bev = 30300, phev = 16900),
  tibble(year = 2021L, state = "PA", bev = 26800, phev = 17800),
  tibble(year = 2021L, state = "RI", bev = 2500, phev = 2400),
  tibble(year = 2021L, state = "SC", bev = 7400, phev = 4700),
  tibble(year = 2021L, state = "SD", bev = 700, phev = 700),
  tibble(year = 2021L, state = "TN", bev = 12200, phev = 6300),
  tibble(year = 2021L, state = "TX", bev = 80900, phev = 30600),
  tibble(year = 2021L, state = "UT", bev = 16500, phev = 7500),
  tibble(year = 2021L, state = "VT", bev = 3400, phev = 3200),
  tibble(year = 2021L, state = "VA", bev = 30700, phev = 15800),
  tibble(year = 2021L, state = "WA", bev = 66800, phev = 24300),
  tibble(year = 2021L, state = "WV", bev = 1000, phev = 1000),
  tibble(year = 2021L, state = "WI", bev = 9300, phev = 7700),
  tibble(year = 2021L, state = "WY", bev = 500, phev = 400),
  # --- 2022 ---
  tibble(year = 2022L, state = "AL", bev = 8700, phev = 4400),
  tibble(year = 2022L, state = "AK", bev = 2000, phev = 700),
  tibble(year = 2022L, state = "AZ", bev = 65800, phev = 20400),
  tibble(year = 2022L, state = "AR", bev = 5100, phev = 2500),
  tibble(year = 2022L, state = "CA", bev = 903600, phev = 361100),
  tibble(year = 2022L, state = "CO", bev = 59900, phev = 24000),
  tibble(year = 2022L, state = "CT", bev = 22000, phev = 13100),
  tibble(year = 2022L, state = "DE", bev = 5400, phev = 2800),
  tibble(year = 2022L, state = "FL", bev = 168000, phev = 45800),
  tibble(year = 2022L, state = "GA", bev = 60100, phev = 18100),
  tibble(year = 2022L, state = "HI", bev = 19800, phev = 5600),
  tibble(year = 2022L, state = "ID", bev = 5900, phev = 3500),
  tibble(year = 2022L, state = "IL", bev = 66900, phev = 25700),
  tibble(year = 2022L, state = "IN", bev = 17700, phev = 10100),
  tibble(year = 2022L, state = "IA", bev = 6200, phev = 4900),
  tibble(year = 2022L, state = "KS", bev = 7600, phev = 4300),
  tibble(year = 2022L, state = "KY", bev = 7600, phev = 4400),
  tibble(year = 2022L, state = "LA", bev = 5900, phev = 2900),
  tibble(year = 2022L, state = "ME", bev = 5000, phev = 5700),
  tibble(year = 2022L, state = "MD", bev = 46100, phev = 22900),
  tibble(year = 2022L, state = "MA", bev = 49400, phev = 30500),
  tibble(year = 2022L, state = "MI", bev = 33100, phev = 24300),
  tibble(year = 2022L, state = "MN", bev = 24300, phev = 11900),
  tibble(year = 2022L, state = "MS", bev = 2400, phev = 1600),
  tibble(year = 2022L, state = "MO", bev = 17900, phev = 10400),
  tibble(year = 2022L, state = "MT", bev = 3300, phev = 1700),
  tibble(year = 2022L, state = "NE", bev = 4600, phev = 2900),
  tibble(year = 2022L, state = "NV", bev = 32900, phev = 8800),
  tibble(year = 2022L, state = "NH", bev = 7000, phev = 4800),
  tibble(year = 2022L, state = "NJ", bev = 87000, phev = 26800),
  tibble(year = 2022L, state = "NM", bev = 7100, phev = 3900),
  tibble(year = 2022L, state = "NY", bev = 84700, phev = 59800),
  tibble(year = 2022L, state = "NC", bev = 45600, phev = 18800),
  tibble(year = 2022L, state = "ND", bev = 600, phev = 600),
  tibble(year = 2022L, state = "OH", bev = 34100, phev = 17800),
  tibble(year = 2022L, state = "OK", bev = 16300, phev = 11500),
  tibble(year = 2022L, state = "OR", bev = 47000, phev = 22500),
  tibble(year = 2022L, state = "PA", bev = 47400, phev = 25400),
  tibble(year = 2022L, state = "RI", bev = 4300, phev = 3400),
  tibble(year = 2022L, state = "SC", bev = 13500, phev = 6700),
  tibble(year = 2022L, state = "SD", bev = 1200, phev = 1000),
  tibble(year = 2022L, state = "TN", bev = 22000, phev = 8900),
  tibble(year = 2022L, state = "TX", bev = 149000, phev = 42800),
  tibble(year = 2022L, state = "UT", bev = 28000, phev = 10200),
  tibble(year = 2022L, state = "VT", bev = 5300, phev = 4200),
  tibble(year = 2022L, state = "VA", bev = 56600, phev = 21700),
  tibble(year = 2022L, state = "WA", bev = 104100, phev = 31400),
  tibble(year = 2022L, state = "WV", bev = 1900, phev = 1400),
  tibble(year = 2022L, state = "WI", bev = 15700, phev = 10000),
  tibble(year = 2022L, state = "WY", bev = 800, phev = 600),
  # --- 2023 ---
  tibble(year = 2023L, state = "AL", bev = 13000, phev = 5800),
  tibble(year = 2023L, state = "AK", bev = 2700, phev = 900),
  tibble(year = 2023L, state = "AZ", bev = 89800, phev = 25600),
  tibble(year = 2023L, state = "AR", bev = 7100, phev = 3200),
  tibble(year = 2023L, state = "CA", bev = 1256600, phev = 410700),
  tibble(year = 2023L, state = "CO", bev = 90100, phev = 37500),
  tibble(year = 2023L, state = "CT", bev = 31600, phev = 18400),
  tibble(year = 2023L, state = "DE", bev = 8400, phev = 3800),
  tibble(year = 2023L, state = "FL", bev = 254900, phev = 57300),
  tibble(year = 2023L, state = "GA", bev = 92400, phev = 22700),
  tibble(year = 2023L, state = "HI", bev = 25600, phev = 7300),
  tibble(year = 2023L, state = "ID", bev = 8500, phev = 4600),
  tibble(year = 2023L, state = "IL", bev = 99600, phev = 33400),
  tibble(year = 2023L, state = "IN", bev = 26100, phev = 12900),
  tibble(year = 2023L, state = "IA", bev = 9000, phev = 6100),
  tibble(year = 2023L, state = "KS", bev = 11300, phev = 5600),
  tibble(year = 2023L, state = "KY", bev = 11600, phev = 5600),
  tibble(year = 2023L, state = "LA", bev = 8200, phev = 4000),
  tibble(year = 2023L, state = "ME", bev = 7400, phev = 7600),
  tibble(year = 2023L, state = "MD", bev = 72100, phev = 31300),
  tibble(year = 2023L, state = "MA", bev = 73800, phev = 43800),
  tibble(year = 2023L, state = "MI", bev = 50300, phev = 29100),
  tibble(year = 2023L, state = "MN", bev = 37100, phev = 16100),
  tibble(year = 2023L, state = "MS", bev = 3600, phev = 2000),
  tibble(year = 2023L, state = "MO", bev = 26900, phev = 13900),
  tibble(year = 2023L, state = "MT", bev = 4600, phev = 2500),
  tibble(year = 2023L, state = "NE", bev = 6900, phev = 3800),
  tibble(year = 2023L, state = "NV", bev = 47400, phev = 10600),
  tibble(year = 2023L, state = "NH", bev = 9900, phev = 6600),
  tibble(year = 2023L, state = "NJ", bev = 134800, phev = 40900),
  tibble(year = 2023L, state = "NM", bev = 10300, phev = 4900),
  tibble(year = 2023L, state = "NY", bev = 131300, phev = 92300),
  tibble(year = 2023L, state = "NC", bev = 70200, phev = 23700),
  tibble(year = 2023L, state = "ND", bev = 1000, phev = 800),
  tibble(year = 2023L, state = "OH", bev = 50400, phev = 24000),
  tibble(year = 2023L, state = "OK", bev = 22800, phev = 33000),
  tibble(year = 2023L, state = "OR", bev = 64400, phev = 28800),
  tibble(year = 2023L, state = "PA", bev = 70200, phev = 38900),
  tibble(year = 2023L, state = "RI", bev = 6400, phev = 5100),
  tibble(year = 2023L, state = "SC", bev = 20900, phev = 9000),
  tibble(year = 2023L, state = "SD", bev = 1700, phev = 1300),
  tibble(year = 2023L, state = "TN", bev = 33200, phev = 11000),
  tibble(year = 2023L, state = "TX", bev = 230100, phev = 55300),
  tibble(year = 2023L, state = "UT", bev = 40000, phev = 13000),
  tibble(year = 2023L, state = "VT", bev = 7800, phev = 5700),
  tibble(year = 2023L, state = "VA", bev = 84900, phev = 26800),
  tibble(year = 2023L, state = "WA", bev = 152100, phev = 41200),
  tibble(year = 2023L, state = "WV", bev = 2800, phev = 1800),
  tibble(year = 2023L, state = "WI", bev = 24900, phev = 12500),
  tibble(year = 2023L, state = "WY", bev = 1100, phev = 800)
)

# Compute total EVs (BEV + PHEV)
ev_raw <- ev_raw %>%
  mutate(ev_total = bev + phev)

cat("EV registration panel: ", nrow(ev_raw), " state-year obs\n")
cat("States:", n_distinct(ev_raw$state), "\n")
cat("Years:", paste(sort(unique(ev_raw$year)), collapse = ", "), "\n")
cat("US BEV totals by year:\n")
ev_raw %>% group_by(year) %>% summarise(total_bev = sum(bev)) %>% print()

# ============================================================
# 2. EV FEE POLICY DATA (NCSL/EV Hub curated)
# ============================================================
ev_fees <- tribble(
  ~state, ~enacted_year, ~fee_bev, ~fee_phev,
  "WA", 2012, 150, 75,   "CO", 2013, 50, 50,    "NC", 2013, 130, 130,
  "GA", 2015, 200, 200,   "ID", 2015, 140, 75,
  "WV", 2017, 200, 100,   "WI", 2017, 100, 75,   "SC", 2017, 120, 60,
  "TN", 2017, 100, 50,    "IN", 2017, 150, 50,    "MN", 2017, 75, 75,
  "MI", 2017, 135, 47,    "CA", 2017, 100, 100,
  "AL", 2019, 200, 100,   "AR", 2019, 200, 100,   "HI", 2019, 50, 50,
  "IL", 2019, 100, 100,   "IA", 2019, 65, 32,     "KS", 2019, 100, 50,
  "ND", 2019, 120, 50,    "OH", 2019, 200, 100,    "OR", 2019, 110, 110,
  "UT", 2019, 90, 52,
  "WY", 2020, 200, 100,   "OK", 2021, 110, 60,    "SD", 2021, 50, 50,
  "TX", 2022, 200, 100,   "NE", 2022, 75, 75,     "PA", 2022, 75, 75,
  "VA", 2022, 64, 64,     "NJ", 2023, 250, 250,   "MT", 2023, 125, 75,
  "MD", 2024, 125, 100
)

# ============================================================
# 3. EIA MOTOR GASOLINE CONSUMPTION (control variable)
# ============================================================
cat("\n=== Fetching EIA Gasoline Consumption ===\n")
eia_key <- Sys.getenv("EIA_API_KEY")

# Fetch all states, all years
gas_df <- tibble()
for (yr in 2016:2022) {
  url <- paste0(
    "https://api.eia.gov/v2/seds/data/?api_key=", eia_key,
    "&frequency=annual&data[0]=value",
    "&facets[seriesId][]=MGACP",
    "&start=", yr, "&end=", yr, "&length=60"
  )
  resp <- GET(url, timeout(20))
  if (status_code(resp) == 200) {
    data <- content(resp, as = "parsed")$response$data
    yr_data <- map_dfr(data, function(x) {
      tibble(
        state = x$stateId %||% NA_character_,
        year = as.integer(x$period),
        gas_consumption_kbbl = as.numeric(x$value)
      )
    })
    gas_df <- bind_rows(gas_df, yr_data)
  }
  Sys.sleep(0.3)
}
gas_df <- gas_df %>% filter(!state %in% c("US", "DC", "X3", "X5"), !is.na(state))
cat("Gas consumption:", nrow(gas_df), "obs,", n_distinct(gas_df$state), "states\n")

# ============================================================
# 4. CENSUS POPULATION
# ============================================================
cat("\n=== Fetching Census Population ===\n")
census_key <- Sys.getenv("CENSUS_API_KEY")

pop_df <- map_dfr(2016:2022, function(yr) {
  url <- paste0(
    "https://api.census.gov/data/", yr, "/acs/acs1",
    "?get=B01003_001E,NAME&for=state:*&key=", census_key
  )
  Sys.sleep(0.5)
  resp <- tryCatch(GET(url, timeout(15)), error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    raw <- content(resp, as = "parsed")
    map_dfr(raw[-1], function(row) {
      tibble(population = as.numeric(row[[1]]),
             state_name = row[[2]],
             state_fips = row[[3]],
             year = yr)
    })
  } else tibble()
})
cat("Population:", nrow(pop_df), "state-year obs\n")

# ============================================================
# 5. SAVE ALL
# ============================================================
cat("\n=== Saving ===\n")
saveRDS(ev_raw, "data/ev_registrations.rds")
saveRDS(ev_fees, "data/ev_fees.rds")
saveRDS(gas_df, "data/gas_consumption.rds")
saveRDS(pop_df, "data/population.rds")

cat("Files:\n")
cat(paste(list.files("data/", pattern = "\\.rds$"), collapse = "\n"), "\n")
cat("\n=== Data Fetch Complete ===\n")
