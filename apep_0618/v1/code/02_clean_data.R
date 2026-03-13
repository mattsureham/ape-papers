## 02_clean_data.R — Construct LA-month panel and compute bunching intensity
library(data.table)
library(tidyverse)

## Load raw data
ppd <- fread("data/ppd_2010_2019.csv.gz")
cat("Loaded", format(nrow(ppd), big.mark = ","), "transactions\n")

## ---- Filter to England only (exclude Wales — different SDLT regime from 2018) ----
## Welsh districts identified by county field — but district names are cleaner
## Wales moved to Land Transaction Tax in April 2018, so we restrict to England
## Welsh counties: remove transactions where county contains Welsh local authorities
## Simpler: the reform is England-specific from 2018; keep all 2010-2017, restrict 2018-2019
## Actually, SDLT applied to England+Wales until April 2018; after that, Wales has LTT
## For clean identification, restrict to England throughout (district-level)

## Load England LA list (326 LAs)
## District field in PPD maps to LA names — use districts present pre-reform as our universe
pre_reform <- ppd[date < as.Date("2014-12-04")]
post_reform <- ppd[date >= as.Date("2014-12-04")]

## Restrict to standard-price transactions (exclude auctions etc)
ppd <- ppd[txn_category == "A" | txn_category == ""]

## ---- Construct LA-month panel ----
## Monthly transaction counts
la_month <- ppd[, .(
  n_txn = .N,
  n_txn_200_350 = sum(price >= 200000 & price <= 350000),
  n_txn_near_notch = sum(price >= 240000 & price <= 260000),
  n_txn_below_notch = sum(price >= 240000 & price < 250000),
  n_txn_dead_zone = sum(price >= 250001 & price <= 260000),
  n_txn_at_250 = sum(price >= 249000 & price <= 250000),
  median_price = as.double(median(price)),
  mean_price = mean(as.double(price))
), by = .(district, ym, year, month)]

cat("LA-month panel:", nrow(la_month), "observations\n")
cat("Unique LAs:", uniqueN(la_month$district), "\n")

## ---- Compute pre-reform bunching intensity ----
## Bunching = excess mass ratio at £240k-£250k relative to counterfactual
## Counterfactual: transactions in £200k-£240k and £260k-£350k (symmetric around notch)

pre_data <- ppd[date >= as.Date("2010-01-01") & date < as.Date("2014-12-04") &
                price >= 200000 & price <= 350000]

## For each LA, compute bunching intensity
la_bunching <- pre_data[, {
  # Count in 10k bins
  below_far <- sum(price >= 200000 & price < 240000) # 4 bins of 10k each
  below_notch <- sum(price >= 240000 & price < 250000) # 1 bin of 10k
  dead_zone <- sum(price >= 250000 & price < 260000) # 1 bin of 10k
  above_far <- sum(price >= 260000 & price <= 350000) # 9 bins of 10k each
  total_200_350 <- sum(price >= 200000 & price <= 350000)

  # Counterfactual density per 10k bin: average of non-notch-affected bins
  # Bins: below_far has 4 bins, above_far has 9 bins = 13 non-affected bins
  counterfactual_per_bin <- (below_far + above_far) / 13

  # Excess mass ratio: (actual in £240k-£250k) / counterfactual_per_bin - 1
  excess_mass <- below_notch / counterfactual_per_bin - 1

  # Dead zone depth: 1 - (actual in £250k-£260k) / counterfactual_per_bin
  dead_zone_depth <- 1 - dead_zone / counterfactual_per_bin

  # Simple bunching share: share of £200-£350k transactions that are in £240k-£250k
  bunch_share <- below_notch / total_200_350

  list(
    excess_mass = excess_mass,
    dead_zone_depth = dead_zone_depth,
    bunch_share = bunch_share,
    n_pre_200_350 = total_200_350,
    n_pre_below_notch = below_notch,
    n_pre_dead_zone = dead_zone,
    counterfactual_per_bin = counterfactual_per_bin
  )
}, by = district]

cat("\n--- Bunching intensity summary ---\n")
cat("LAs with data:", nrow(la_bunching), "\n")
cat("Excess mass ratio: mean =", round(mean(la_bunching$excess_mass, na.rm = TRUE), 3),
    ", median =", round(median(la_bunching$excess_mass, na.rm = TRUE), 3),
    ", sd =", round(sd(la_bunching$excess_mass, na.rm = TRUE), 3), "\n")
cat("Dead zone depth: mean =", round(mean(la_bunching$dead_zone_depth, na.rm = TRUE), 3), "\n")

## Drop LAs with fewer than 50 transactions in £200k-£350k range pre-reform
## (insufficient data to compute reliable bunching)
la_bunching <- la_bunching[n_pre_200_350 >= 50]
cat("LAs after minimum-count filter:", nrow(la_bunching), "\n")

## ---- Merge bunching intensity into panel ----
panel <- merge(la_month, la_bunching[, .(district, excess_mass, dead_zone_depth,
                                         bunch_share, n_pre_200_350)],
               by = "district", all.x = FALSE)

## Create time variables
panel[, post := as.integer(ym >= 201412)]
panel[, date_ym := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]

## Create LA numeric ID for fixest
panel[, la_id := as.integer(as.factor(district))]

## Construct log outcomes (add 1 to handle zeros)
panel[, ln_txn := log(n_txn + 1)]
panel[, ln_txn_200_350 := log(n_txn_200_350 + 1)]
panel[, dead_zone_share := n_txn_dead_zone / (n_txn_near_notch + 1)]

cat("\nFinal panel:", nrow(panel), "observations\n")
cat("Unique LAs:", uniqueN(panel$district), "\n")
cat("Months:", uniqueN(panel$ym), "\n")
cat("Date range:", as.character(min(panel$date_ym)), "to", as.character(max(panel$date_ym)), "\n")

## ---- Summary statistics ----
cat("\n--- Panel summary statistics ---\n")
cat("Monthly transactions per LA: mean =", round(mean(panel$n_txn), 1),
    ", median =", round(median(panel$n_txn), 1),
    ", sd =", round(sd(panel$n_txn), 1), "\n")
cat("Monthly near-notch transactions: mean =", round(mean(panel$n_txn_near_notch), 1),
    ", median =", round(median(panel$n_txn_near_notch), 1), "\n")

## ---- Save ----
fwrite(panel, "data/panel.csv.gz")
fwrite(la_bunching, "data/la_bunching.csv")
cat("\nSaved panel.csv.gz and la_bunching.csv\n")
