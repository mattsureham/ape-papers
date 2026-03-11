# ==============================================================================
# 01_fetch_data.R — Fetch data from Azure (IPUMS full-count + MLP linked panels)
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ==============================================================================
# 1. State Prohibition Adoption Dates (Beienburg 2020)
# ==============================================================================
# Source: Beienburg, Sean. 2020. "Prohibition, the Constitution, and States'
# Rights." University of Chicago Press. Appendix table.

prohibition <- data.table(
  statefip = c(
    # Already dry before 1907
    23, 20, 38,  # ME, KS, ND
    # Third Wave (1907-1919)
    13, 40,      # GA, OK (1907)
    28, 37,      # MS, NC (1908)
    47,          # TN (1909)
    54,          # WV (1912)
    51, 41, 8, 4, 53,  # VA, OR, CO, AZ, WA (1914)
    1, 5, 19, 16,       # AL, AR, IA, ID (1915)
    45, 30, 46, 26, 31, # SC, MT, SD, MI, NE (1916)
    18, 33, 49,          # IN, NH, UT (1917)
    35, 48, 39, 56, 12, 32, # NM, TX, OH, WY, FL, NV (1918)
    21                       # KY (1919)
  ),
  prohib_year = c(
    1884, 1880, 1889,
    1907, 1907,
    1908, 1908,
    1909,
    1912,
    1914, 1914, 1914, 1914, 1914,
    1915, 1915, 1915, 1915,
    1916, 1916, 1916, 1916, 1916,
    1917, 1917, 1917,
    1918, 1918, 1918, 1918, 1918, 1918,
    1919
  )
)

# Never-dry states (wet until national prohibition 1920)
never_dry <- data.table(
  statefip = c(36, 42, 17, 25, 9, 24, 34, 10, 22, 29, 44, 27, 55, 6, 50),
  # NY, PA, IL, MA, CT, MD, NJ, DE, LA, MO, RI, MN, WI, CA, VT
  prohib_year = 1920L  # Only via 18th Amendment
)

prohib_dates <- rbind(prohibition, never_dry)
prohib_dates[, dry_before_1910 := prohib_year < 1910]
prohib_dates[, dry_1910_1919 := prohib_year >= 1910 & prohib_year < 1920]
prohib_dates[, never_dry := prohib_year == 1920]
# Years of state prohibition exposure by 1920 census (April 1920)
prohib_dates[, prohib_years_by_1920 := pmax(0, 1920 - prohib_year)]

fwrite(prohib_dates, "../data/prohibition_dates.csv")
cat("Prohibition dates for", nrow(prohib_dates), "states saved.\n")

# ==============================================================================
# 2. County-level Alcohol Industry Shares from 1910 Full-Count Census
# ==============================================================================
# Alcohol-related occupations/industries in the harmonized census data:
#   OCC1950 = 730 (Bartenders) — direct alcohol service, most disrupted by prohibition
#   IND1950 = 869 (Eating and drinking places) — includes saloons, taverns, bars
#     In 1910 context, ~300K+ saloons dominated this category
#   IND1950 = 216 (Food/beverage manufacturing) — includes breweries, distilleries
#   We use IND1950=869 as primary measure (saloon density) and OCC1950=730 as narrow

cat("Computing county-level alcohol industry shares from 1910 full-count census...\n")

county_alc <- DBI::dbGetQuery(con, "
  SELECT
    statefip AS statefip_1910,
    countyicp AS countyicp_1910,
    COUNT(*) AS total_workers,
    SUM(CASE WHEN ind1950 = 869 THEN 1 ELSE 0 END) AS saloon_workers,
    SUM(CASE WHEN occ1950 = 730 THEN 1 ELSE 0 END) AS bartenders,
    SUM(CASE WHEN ind1950 = 216 THEN 1 ELSE 0 END) AS bev_manuf_workers,
    SUM(CASE WHEN occ1950 = 730 OR ind1950 = 869 THEN 1 ELSE 0 END) AS alc_adjacent,
    AVG(occscore) AS mean_occscore_1910,
    SUM(CASE WHEN sex = 2 AND occ1950 < 979 AND ind1950 > 0 THEN 1 ELSE 0 END) AS female_workers,
    SUM(CASE WHEN age BETWEEN 18 AND 65 THEN 1 ELSE 0 END) AS working_age_pop
  FROM 'az://raw/ipums_fullcount/us1910m.parquet'
  WHERE age BETWEEN 18 AND 65
    AND occ1950 < 979
    AND ind1950 > 0
  GROUP BY statefip, countyicp
  HAVING total_workers >= 100
")
setDT(county_alc)

# Primary measure: saloon/eating-drinking share (IND1950=869)
county_alc[, alc_share := saloon_workers / total_workers]
# Narrow measure: bartender share (OCC1950=730)
county_alc[, bartender_share := bartenders / total_workers]
# Broad measure: all alcohol-adjacent (saloons + bartenders not in 869)
county_alc[, alc_broad_share := alc_adjacent / total_workers]
# Manufacturing beverages
county_alc[, bev_manuf_share := bev_manuf_workers / total_workers]
county_alc[, female_lfp_1910 := female_workers / working_age_pop]

cat("County alcohol shares computed for", nrow(county_alc), "counties.\n")
cat("Mean saloon share:", round(mean(county_alc$alc_share), 5), "\n")
cat("Max saloon share:", round(max(county_alc$alc_share), 4), "\n")
cat("Counties with >0 saloon workers:", sum(county_alc$alc_share > 0), "\n")
cat("Counties with >1% saloon share:", sum(county_alc$alc_share > 0.01), "\n")

fwrite(county_alc, "../data/county_alcohol_shares.csv")

# ==============================================================================
# 3. Linked 1910-1920 Panel (Main Analysis Sample)
# ==============================================================================
cat("\nFetching linked 1910-1920 panel (working-age, non-alcohol, with outcomes)...\n")

panel_1910_1920 <- DBI::dbGetQuery(con, "
  SELECT
    histid_1910,
    statefip_1910,
    countyicp_1910,
    age_1910,
    sex_1910,
    race_1910,
    nativity_1910,
    marst_1910,
    occ1950_1910,
    ind1950_1910,
    occscore_1910,
    classwkr_1910,
    lit_1910,
    ownershp_1910,
    statefip_1920,
    countyicp_1920,
    occ1950_1920,
    ind1950_1920,
    occscore_1920,
    classwkr_1920,
    ownershp_1920,
    mover,
    age_diff
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE age_1910 BETWEEN 18 AND 55
    AND occ1950_1910 < 979
    AND ind1950_1910 > 0
    AND ind1950_1910 != 869
    AND occ1950_1910 != 730
    AND ABS(age_diff - 10) <= 2
")
setDT(panel_1910_1920)

cat("Linked 1910-1920 panel:", nrow(panel_1910_1920), "rows\n")
cat("States:", uniqueN(panel_1910_1920$statefip_1910), "\n")

fwrite(panel_1910_1920, "../data/panel_1910_1920.csv")

# ==============================================================================
# 4. Linked 1900-1910 Panel (Pre-Trend Test)
# ==============================================================================
cat("\nFetching linked 1900-1910 panel for pre-trend test...\n")

panel_1900_1910 <- DBI::dbGetQuery(con, "
  SELECT
    histid_1900,
    statefip_1900,
    countyicp_1900,
    age_1900,
    sex_1900,
    race_1900,
    nativity_1900,
    occ1950_1900,
    ind1950_1900,
    occscore_1900,
    statefip_1910,
    countyicp_1910,
    occ1950_1910,
    ind1950_1910,
    occscore_1910,
    mover,
    age_diff
  FROM 'az://derived/mlp_panel/linked_1900_1910.parquet'
  WHERE age_1900 BETWEEN 18 AND 55
    AND occ1950_1900 < 979
    AND ind1950_1900 > 0
    AND ind1950_1900 != 869
    AND occ1950_1900 != 730
    AND ABS(age_diff - 10) <= 2
")
setDT(panel_1900_1910)

cat("Linked 1900-1910 panel:", nrow(panel_1900_1910), "rows\n")
fwrite(panel_1900_1910, "../data/panel_1900_1910.csv")

# ==============================================================================
# 5. County-level Alcohol Shares from 1900 Census (for pre-trend exposure)
# ==============================================================================
cat("\nComputing county alcohol shares from 1900 full-count census...\n")

county_alc_1900 <- DBI::dbGetQuery(con, "
  SELECT
    statefip AS statefip_1900,
    countyicp AS countyicp_1900,
    COUNT(*) AS total_workers_1900,
    SUM(CASE WHEN ind1950 = 869 THEN 1 ELSE 0 END) AS saloon_workers_1900,
    SUM(CASE WHEN occ1950 = 730 THEN 1 ELSE 0 END) AS bartenders_1900
  FROM 'az://raw/ipums_fullcount/us1900m.parquet'
  WHERE age BETWEEN 18 AND 65
    AND occ1950 < 979
    AND ind1950 > 0
  GROUP BY statefip, countyicp
  HAVING total_workers_1900 >= 100
")
setDT(county_alc_1900)
county_alc_1900[, alc_share_1900 := saloon_workers_1900 / total_workers_1900]

fwrite(county_alc_1900, "../data/county_alcohol_shares_1900.csv")
cat("1900 county alcohol shares computed for", nrow(county_alc_1900), "counties.\n")

# ==============================================================================
# 6. Linked 1920-1930 Panel (Long-Run Effects)
# ==============================================================================
cat("\nFetching linked 1920-1930 panel for long-run analysis...\n")

panel_1920_1930 <- DBI::dbGetQuery(con, "
  SELECT
    histid_1920,
    statefip_1920,
    countyicp_1920,
    age_1920,
    sex_1920,
    race_1920,
    nativity_1920,
    occ1950_1920,
    ind1950_1920,
    occscore_1920,
    classwkr_1920,
    statefip_1930,
    countyicp_1930,
    occ1950_1930,
    ind1950_1930,
    occscore_1930,
    classwkr_1930,
    mover,
    age_diff
  FROM 'az://derived/mlp_panel/linked_1920_1930.parquet'
  WHERE age_1920 BETWEEN 18 AND 55
    AND occ1950_1920 < 979
    AND ind1950_1920 > 0
    AND ind1950_1920 != 869
    AND occ1950_1920 != 730
    AND ABS(age_diff - 10) <= 2
")
setDT(panel_1920_1930)

cat("Linked 1920-1930 panel:", nrow(panel_1920_1930), "rows\n")
fwrite(panel_1920_1930, "../data/panel_1920_1930.csv")

# ==============================================================================
# 7. Female Labor Force Data (Cross-Section) from 1910 and 1920 Full-Count
# ==============================================================================
cat("\nComputing county-level female LFP from 1920 full-count census...\n")

county_female_1920 <- DBI::dbGetQuery(con, "
  SELECT
    statefip,
    countyicp,
    SUM(CASE WHEN sex = 2 AND occ1950 < 979 AND ind1950 > 0 THEN 1 ELSE 0 END) AS female_employed_1920,
    SUM(CASE WHEN sex = 2 THEN 1 ELSE 0 END) AS female_total_1920,
    COUNT(*) AS total_pop_1920
  FROM 'az://raw/ipums_fullcount/us1920c.parquet'
  WHERE age BETWEEN 18 AND 65
  GROUP BY statefip, countyicp
  HAVING total_pop_1920 >= 100
")
setDT(county_female_1920)
county_female_1920[, female_lfp_1920 := female_employed_1920 / female_total_1920]

fwrite(county_female_1920, "../data/county_female_1920.csv")
cat("1920 female LFP computed for", nrow(county_female_1920), "counties.\n")

apep_azure_disconnect(con)

# ==============================================================================
# DATA VALIDATION
# ==============================================================================
cat("\n=== DATA VALIDATION ===\n")
stopifnot("Panel 1910-1920 has observations" = nrow(panel_1910_1920) > 1000000)
stopifnot("Panel 1900-1910 has observations" = nrow(panel_1900_1910) > 100000)
stopifnot("Panel 1920-1930 has observations" = nrow(panel_1920_1930) > 1000000)
stopifnot("County alcohol shares computed" = nrow(county_alc) > 500)
stopifnot("Multiple states represented" = uniqueN(panel_1910_1920$statefip_1910) >= 40)
stopifnot("Alcohol share has variation" = sd(county_alc$alc_share) > 0)

cat("Data validation passed.\n")
cat("  Panel 1910-1920:", format(nrow(panel_1910_1920), big.mark = ","), "individuals\n")
cat("  Panel 1900-1910:", format(nrow(panel_1900_1910), big.mark = ","), "individuals\n")
cat("  Panel 1920-1930:", format(nrow(panel_1920_1930), big.mark = ","), "individuals\n")
cat("  Counties with alcohol data:", nrow(county_alc), "\n")
cat("  States:", uniqueN(panel_1910_1920$statefip_1910), "\n")
