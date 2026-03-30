library(data.table)
library(tigris)

fips <- as.data.table(tigris::fips_codes)
cat("fips_codes columns:", names(fips), "\n")
cat("Sample fips_codes rows:\n")
print(head(fips, 10))

# Show what the county column looks like
cat("\nSample county names from tigris:\n")
print(head(fips$county, 20))

# What the ARCOS county names look like
arcos <- fread("../data/arcos_instrument.csv", nrows = 0)
cat("\nARCOS instrument doesn't have county names - check arcos_annual\n")
# Let me re-check
