## 02_clean_data.R — Clean WFP data and construct APMC stringency index
## apep_0550: India Farm Laws Symmetric Natural Experiment
##
## Data: WFP/VAM food price monitoring (retail prices, INR/kg)
## from Humanitarian Data Exchange (HDX)

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")

## ================================================================
## 1. CONSTRUCT APMC STRINGENCY INDEX
## ================================================================
## Based on: Chatterjee (2020, EPW), Chand (2012), Acharya (2006),
## NITI Aayog (2016) state-level APMC reform assessment.
##
## Components:
##   1. Total market fees/cess (% of transaction value)
##   2. Number of commodities under APMC regulation
##   3. Restrictions on private mandi operation
##
## We construct a continuous index: higher = more regulated = more "treated"

apmc_index <- data.table(
  state = c(
    "Punjab", "Haryana", "Madhya Pradesh", "Maharashtra",
    "Gujarat", "Karnataka", "Andhra Pradesh", "Telangana",
    "Uttar Pradesh", "Rajasthan", "West Bengal", "Tamil Nadu",
    "Odisha", "Jharkhand", "Chhattisgarh", "Uttarakhand",
    "Bihar", "Kerala",
    ## Additional states for WFP coverage
    "Delhi", "Assam", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Tripura", "Arunachal Pradesh", "Sikkim",
    "Goa", "Himachal Pradesh", "Jammu and Kashmir"
  ),
  ## Total APMC market charges (% of commodity value)
  apmc_cess_pct = c(
    8.5,  # Punjab: arhatia commission + mkt fee + rural dev cess
    6.5,  # Haryana: similar to Punjab
    2.0,  # MP: reduced after reforms
    1.5,  # Maharashtra: 1% mkt fee + 0.5% cess
    1.0,  # Gujarat: reformed, low fees
    1.5,  # Karnataka: 1% mkt fee + 0.5% cess
    1.0,  # AP: reformed market fees
    1.0,  # Telangana: reformed (post-bifurcation)
    2.5,  # UP: market fee + development charges
    1.6,  # Rajasthan: reformed
    0.5,  # WB: low mkt fee
    1.0,  # TN: low mkt fee
    1.0,  # Odisha: reformed
    1.5,  # Jharkhand: moderate
    2.0,  # Chhattisgarh: moderate cess
    2.0,  # Uttarakhand: moderate
    0.0,  # Bihar: APMC abolished 2006
    0.0,  # Kerala: most commodities exempt
    ## Additional states
    0.0,  # Delhi: no APMC act (governed by Essential Commodities)
    1.5,  # Assam: moderate APMC
    1.0,  # Manipur: limited APMC
    0.5,  # Meghalaya: weak APMC
    0.0,  # Mizoram: no APMC act
    0.5,  # Nagaland: weak APMC
    1.0,  # Tripura: moderate
    0.5,  # Arunachal Pradesh: weak
    0.0,  # Sikkim: no APMC
    1.0,  # Goa: moderate
    1.5,  # HP: moderate
    2.0   # J&K: moderate
  ),
  n_regulated_commodities = c(
    46, 42, 67, 166, 82, 100, 72, 72,
    98, 94, 60, 48, 52, 40, 35, 45,
    0, 8,
    ## Additional states
    0, 45, 20, 10, 0, 12, 25, 10, 0, 30, 50, 55
  ),
  private_mkt_restricted = c(
    1, 1, 0, 0, 0, 0, 0, 0,
    1, 0, 1, 0, 0, 1, 1, 0,
    0, 0,
    ## Additional states
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
  ),
  blocked_farm_laws = c(
    1,  # Punjab: passed 3 counter-bills Oct 2020
    0, 0, 0, 0, 0, 0, 0, 0,
    1,  # Rajasthan: passed counter-legislation Dec 2020
    0, 0, 0, 0,
    1,  # Chhattisgarh: passed amendment to counter
    0,
    0,  # Bihar: irrelevant (no APMC)
    0,  # Kerala: passed resolution, no legislative block
    ## Additional states: none formally blocked
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  ),
  apmc_abolished = c(
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    1,  # Bihar: abolished 2006
    0,
    ## Additional states
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  )
)

## Construct composite APMC stringency index (0-1 scale)
apmc_index[, cess_norm := apmc_cess_pct / max(apmc_cess_pct)]
apmc_index[, commodities_norm := n_regulated_commodities / max(n_regulated_commodities)]
apmc_index[, `:=`(
  apmc_stringency = 0.40 * cess_norm +
                    0.30 * commodities_norm +
                    0.30 * private_mkt_restricted
)]

## Bihar and states without APMC should be ~0
apmc_index[apmc_abolished == 1, apmc_stringency := 0]

cat("APMC Stringency Index:\n")
print(apmc_index[order(-apmc_stringency),
  .(state, apmc_cess_pct, n_regulated_commodities,
    private_mkt_restricted, blocked_farm_laws, apmc_stringency)])

fwrite(apmc_index, file.path(DATA_DIR, "apmc_stringency.csv"))

## ================================================================
## 2. LOAD AND CLEAN WFP FOOD PRICE DATA
## ================================================================

prices <- fread(file.path(DATA_DIR, "prices_filtered.csv"))
if (nrow(prices) == 0) {
  stop("No filtered prices found. Run 01_fetch_data.R first.")
}

cat("\nLoaded WFP filtered data:", nrow(prices), "rows\n")
cat("Columns:", paste(names(prices), collapse = ", "), "\n")

## Parse date
prices[, date := as.Date(date)]

## Standardize state names (admin1 → state)
prices[, state := admin1]

## Fix known state name variants
prices[state == "Orissa", state := "Odisha"]
prices[state == "Chattisgarh", state := "Chhattisgarh"]
prices[state == "Jammu And Kashmir", state := "Jammu and Kashmir"]
prices[state == "Andaman and Nicobar", state := "Andaman and Nicobar Islands"]

## Standardize commodity names
## WFP uses: Rice, Wheat, Onions, Potatoes, Tomatoes
prices[commodity == "Onions", commodity := "Onion"]
prices[commodity == "Potatoes", commodity := "Potato"]
prices[commodity == "Tomatoes", commodity := "Tomato"]

## Use INR price (price column is in INR/kg)
prices[, price_inr := as.numeric(price)]

## Drop missing/zero prices
prices <- prices[!is.na(price_inr) & price_inr > 0]
prices <- prices[!is.na(date)]

## Create time variables
prices[, `:=`(
  year      = year(date),
  month_num = month(date),
  ym        = floor_date(date, "month")
)]

## Filter to analysis window
prices <- prices[year >= 2018 & year <= 2023]

cat("\nCleaned prices:", nrow(prices), "rows,",
    uniqueN(prices$state), "states,",
    uniqueN(prices$commodity), "commodities,",
    uniqueN(prices$market), "markets\n")

## ================================================================
## 3. CREATE TREATMENT VARIABLES
## ================================================================

## Key dates
ENACT_DATE <- as.Date("2020-06-05")  # Ordinances promulgated
STAY_DATE  <- as.Date("2021-01-12")  # Supreme Court stay
REPEAL_DATE <- as.Date("2021-12-01") # Formal repeal

prices[, `:=`(
  pre       = date < ENACT_DATE,
  on_phase  = date >= ENACT_DATE & date < STAY_DATE,
  off_phase = date >= STAY_DATE,
  phase = fifelse(date < ENACT_DATE, 0L,
          fifelse(date < STAY_DATE, 1L, 2L))
)]

## Merge APMC stringency
prices <- merge(prices, apmc_index[, .(state, apmc_stringency, blocked_farm_laws,
                                        apmc_abolished, apmc_cess_pct)],
               by = "state", all.x = TRUE)

## Drop observations without APMC data (e.g., small UTs not in index)
n_before <- nrow(prices)
prices <- prices[!is.na(apmc_stringency)]
cat("\nDropped", n_before - nrow(prices), "obs without APMC data\n")

## Create market-commodity ID for FE
prices[, market_commodity := paste(market, commodity, sep = "_")]
prices[, commodity_month := paste(commodity, format(ym, "%Y-%m"), sep = "_")]

## Create log price
prices[, log_price := log(price_inr)]

cat("\nPanel with treatment:", nrow(prices), "rows\n")
cat("Phase distribution:\n")
print(prices[, .N, by = .(phase = fifelse(phase == 0, "Pre",
                           fifelse(phase == 1, "ON", "OFF")))])

## ================================================================
## 4. AGGREGATE TO MONTHLY STATE-COMMODITY LEVEL
## ================================================================

monthly <- prices[,
  .(
    mean_price     = mean(price_inr, na.rm = TRUE),
    median_price   = median(price_inr, na.rm = TRUE),
    log_mean_price = mean(log_price, na.rm = TRUE),
    sd_price       = sd(price_inr, na.rm = TRUE),
    price_range    = max(price_inr, na.rm = TRUE) - min(price_inr, na.rm = TRUE),
    n_markets      = uniqueN(market),
    n_obs          = .N
  ),
  by = .(state, commodity, ym, year, phase, apmc_stringency,
         blocked_farm_laws, apmc_abolished, apmc_cess_pct)
]

## State-commodity FE ID
monthly[, state_commodity := paste(state, commodity, sep = "_")]

## Commodity-month FE ID
monthly[, commodity_month := paste(commodity, format(ym, "%Y-%m"), sep = "_")]

## Create ON and OFF dummies
monthly[, `:=`(
  on_phase  = as.integer(phase == 1),
  off_phase = as.integer(phase == 2)
)]

## Save
fwrite(monthly, file.path(DATA_DIR, "monthly_panel.csv"))
fwrite(prices, file.path(DATA_DIR, "market_panel.csv"))

cat("\nMonthly panel:", nrow(monthly), "rows,",
    uniqueN(monthly$state), "states,",
    uniqueN(monthly$commodity), "commodities\n")

## ================================================================
## 5. SUMMARY STATISTICS
## ================================================================

sumstats <- prices[, .(
  N = .N,
  Mean_Price = mean(price_inr, na.rm = TRUE),
  SD_Price = sd(price_inr, na.rm = TRUE),
  Min_Price = min(price_inr, na.rm = TRUE),
  Max_Price = max(price_inr, na.rm = TRUE),
  N_Markets = uniqueN(market),
  N_States = uniqueN(state)
), by = commodity]

cat("\nSummary statistics by commodity:\n")
print(sumstats)
fwrite(sumstats, file.path(DATA_DIR, "summary_stats.csv"))

## Cross-tabulation of states by APMC stringency
cat("\nStates by APMC stringency:\n")
print(apmc_index[order(-apmc_stringency),
  .(state, apmc_stringency = round(apmc_stringency, 3),
    apmc_cess_pct, blocked = blocked_farm_laws)])

cat("\n=== DATA CLEANING COMPLETE ===\n")
