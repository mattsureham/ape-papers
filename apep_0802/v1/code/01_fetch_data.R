## 01_fetch_data.R — Load pre-extracted data for NZ deductibility analysis
## Data was extracted from Stats NZ Excel + MBIE CSV by 01_extract_excel.py
## apep_0802

source("00_packages.R")

## 1. Building consents by region and dwelling type (Jan 2021–Jan 2026)
region_type <- fread("../data/building_consents_by_region_type.csv")
cat("Region-type panel:", nrow(region_type), "rows,",
    uniqueN(region_type$region), "regions,",
    uniqueN(region_type$dwelling_type), "types,",
    uniqueN(region_type$date), "months\n")

## 2. Building consents by TA (Jan 2019–Jan 2026)
ta_consents <- fread("../data/building_consents_by_ta.csv")
cat("TA panel:", nrow(ta_consents), "rows,",
    uniqueN(ta_consents$ta), "TAs,",
    uniqueN(ta_consents$date), "months\n")

## 3. Active rental bonds by TA (Jan 1993–Oct 2020) — wide format
bonds_wide <- fread("../data/ta-active-bonds.csv")
# Reshape to long
bonds_long <- melt(bonds_wide, id.vars = "Month", variable.name = "ta",
                   value.name = "active_bonds")
setnames(bonds_long, "Month", "date")
bonds_long[, date := as.Date(date)]
# Drop National Total
bonds_long <- bonds_long[ta != "National Total"]
cat("Bonds panel:", nrow(bonds_long), "rows,",
    uniqueN(bonds_long$ta), "TAs\n")

## 4. Mean rents by TA (Jan 1993–Oct 2020) — wide format
rents_wide <- fread("../data/ta-mean-rents.csv")
rents_long <- melt(rents_wide, id.vars = "Month", variable.name = "ta",
                   value.name = "mean_rent")
setnames(rents_long, "Month", "date")
rents_long[, date := as.Date(date)]
rents_long <- rents_long[ta != "National Total"]

## 5. Population by TA
pop <- fread("../data/population_by_ta.csv")
cat("Population:", nrow(pop), "rows,",
    uniqueN(pop$ta), "TAs,",
    uniqueN(pop$year), "years\n")

## Save as RDS for downstream scripts
saveRDS(region_type, "../data/region_type.rds")
saveRDS(ta_consents, "../data/ta_consents.rds")
saveRDS(bonds_long, "../data/bonds_long.rds")
saveRDS(rents_long, "../data/rents_long.rds")
saveRDS(pop, "../data/pop.rds")

cat("\n✓ All data loaded and saved to RDS.\n")
