## 02_clean_data.R — Clean and prepare analysis dataset
## apep_1281: Pricing to the Cap

source("00_packages.R")

dt <- fread("../data/nsw_psi_2018_2025.csv")
dt[, contract_date := as.Date(contract_date)]

cat("Raw records:", nrow(dt), "\n")

## ---- Create analysis variables ----

# Year-month
dt[, ym := format(contract_date, "%Y-%m")]
dt[, year := year(contract_date)]
dt[, month := month(contract_date)]

# Reform indicator: July 1, 2023 stamp duty threshold increase
dt[, post_reform := contract_date >= as.Date("2023-07-01")]

# Fix dates: remove records with clearly wrong dates
dt <- dt[contract_date >= as.Date("2017-01-01") & contract_date <= as.Date("2026-01-01")]

# Property type classification (primary_purpose is freeform — use pattern matching)
dt[, prop_type := "other"]
dt[grepl("RESIDEN|HOUSE|HOME|DUPLEX|VILLA|TOWNHOUSE|UNIT|APARTMENT|FLAT|TERRACE|COTTAGE|DWELLING|SEMI.DETACH|MAISONETTE|GRANNY|STRATA", primary_purpose, ignore.case = TRUE), prop_type := "residential"]
dt[grepl("VACANT LAND|VACANT$|^VL$|^VL |LAND ONLY", primary_purpose, ignore.case = TRUE), prop_type := "vacant_land"]
dt[grepl("COMMERCIAL|OFFICE|SHOP|RETAIL|WAREHOUSE|FACTORY|INDUSTRIAL|BUSINESS|SHOWROOM|STUDIO(?!.*HOME)", primary_purpose, ignore.case = TRUE, perl = TRUE), prop_type := "commercial"]
dt[grepl("FARM|RURAL|AGRICULTURAL|GRAZING|PASTORAL|VINEYARD|ORCHARD", primary_purpose, ignore.case = TRUE), prop_type := "farm"]
# Nature field as fallback for unmatched
dt[prop_type == "other" & nature == "R", prop_type := "residential"]
dt[prop_type == "other" & nature == "V", prop_type := "vacant_land"]

cat("Property type distribution:\n")
print(dt[, .N, by = prop_type][order(-N)])

# Nature of property: R=Residence, V=Vacant land
dt[, is_residence := nature == "R"]
dt[, is_vacant := nature == "V"]

## ---- Filter to analysis sample ----
# Focus on transactions in the FHB-relevant price range ($100K - $2M)
# This captures all three thresholds with sufficient bandwidth
dt_analysis <- dt[purchase_price >= 100000 & purchase_price <= 2000000]

cat("Analysis sample (100K-2M):", nrow(dt_analysis), "\n")

# Residential only for main analysis
dt_res <- dt_analysis[prop_type == "residential"]
cat("Residential transactions:", nrow(dt_res), "\n")

# Non-residential for placebo
dt_nonres <- dt_analysis[prop_type %in% c("commercial", "farm")]
cat("Commercial/Farm (placebo):", nrow(dt_nonres), "\n")

## ---- Create price bins ----
# $5,000 bins for bunching estimation
dt_analysis[, price_bin_5k := floor(purchase_price / 5000) * 5000]

# $1,000 bins for finer analysis near thresholds
dt_analysis[, price_bin_1k := floor(purchase_price / 1000) * 1000]

## ---- Pre/post period split for migration test ----
# Pre-reform: Jan 2018 - Jun 2023
# Post-reform: Jul 2023 - Dec 2025
dt_analysis[, period := fifelse(post_reform, "post", "pre")]

## ---- Save ----
fwrite(dt_analysis, "../data/analysis_sample.csv")

cat("\n=== Summary ===\n")
cat("Total analysis sample:", nrow(dt_analysis), "\n")
cat("Residential:", sum(dt_analysis$prop_type == "residential"), "\n")
cat("Vacant land:", sum(dt_analysis$prop_type == "vacant_land"), "\n")
cat("Commercial:", sum(dt_analysis$prop_type == "commercial"), "\n")
cat("Farm:", sum(dt_analysis$prop_type == "farm"), "\n")
cat("Pre-reform:", sum(dt_analysis$period == "pre"), "\n")
cat("Post-reform:", sum(dt_analysis$period == "post"), "\n")

cat("\nDONE: 02_clean_data.R\n")
