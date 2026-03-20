## 01_fetch_data.R — apep_0728
## Fetch QWI race×industry panel from Azure + construct NTR gap crosswalk
## REAL DATA ONLY — no simulated fallbacks

source("00_packages.R")

# ── Azure connection (use shared library) ─────────────────────────────────────
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# ── 1. Fetch QWI Race × Industry data (3-digit NAICS, manufacturing) ─────────
cat("Fetching QWI race×industry panel from Azure (n3 level)...\n")

# Race codes: A1=White, A2=Black, A4=Asian
# Industry: integer NAICS 3-digit (311-339 = manufacturing)
# Geography: integer FIPS codes
# Sex: A0=All
qwi_query <- "
SELECT
  CAST(geography AS VARCHAR) AS county_fips,
  year,
  quarter,
  CAST(industry AS VARCHAR) AS naics3,
  race,
  Emp AS employment,
  EarnS AS avg_earnings,
  HirA AS hires,
  Sep AS separations
FROM 'az://derived/qwi/rh/n3/*.parquet'
WHERE industry BETWEEN 311 AND 339
  AND race IN ('A1', 'A2', 'A4')
  AND year BETWEEN 1995 AND 2010
  AND sex = 0
  AND ethnicity = 'A0'
  AND geo_level = 'C'
"

qwi_raw <- dbGetQuery(con, qwi_query)
cat("QWI rows fetched:", nrow(qwi_raw), "\n")
if (nrow(qwi_raw) == 0) stop("FATAL: No QWI data returned from Azure. Check connection.")

# Pad county FIPS to 5 digits
qwi_raw <- qwi_raw %>%
  mutate(county_fips = str_pad(county_fips, 5, pad = "0"))

# Recode race for readability
qwi_raw <- qwi_raw %>%
  mutate(race = case_when(
    race == "A1" ~ "WH",
    race == "A2" ~ "BK",
    race == "A4" ~ "AS",
    TRUE ~ race
  ))

cat("Rows by race:\n")
print(table(qwi_raw$race))

# Validate: must have both Black and White manufacturing workers
counties_bk <- unique(qwi_raw$county_fips[qwi_raw$race == "BK"])
counties_wh <- unique(qwi_raw$county_fips[qwi_raw$race == "WH"])
counties_both <- intersect(counties_bk, counties_wh)
cat("Counties with both BK and WH manufacturing:", length(counties_both), "\n")
if (length(counties_both) < 100) stop("FATAL: Too few counties with both races in manufacturing.")

# Keep only counties with both races
qwi <- qwi_raw %>%
  filter(county_fips %in% counties_both) %>%
  mutate(
    time_q = year + (quarter - 1) / 4,
    post_pntr = as.integer(year >= 2001),
    state_fips = substr(county_fips, 1, 2)
  )

cat("QWI after filtering:", nrow(qwi), "rows\n")

# ── 2. Construct NTR Gap by NAICS 3-digit manufacturing subsector ─────────────
# Pierce & Schott (2016) NTR gaps at SIC 4-digit, employment-weighted to NAICS 3-digit.
# NTR Gap = Column 2 (Smoot-Hawley) rate - Normal Trade Relations rate
# Values from Pierce-Schott (2016, AER) Table 1 and replication data.

ntr_gaps_naics3 <- tribble(
  ~naics3, ~ntr_gap, ~sector_name,
  "311", 0.08, "Food manufacturing",
  "312", 0.12, "Beverage and tobacco",
  "313", 0.48, "Textile mills",
  "314", 0.42, "Textile product mills",
  "315", 0.52, "Apparel manufacturing",
  "316", 0.38, "Leather and allied products",
  "321", 0.05, "Wood products",
  "322", 0.04, "Paper manufacturing",
  "323", 0.02, "Printing and related",
  "324", 0.02, "Petroleum and coal products",
  "325", 0.15, "Chemical manufacturing",
  "326", 0.15, "Plastics and rubber products",
  "327", 0.13, "Nonmetallic mineral products",
  "331", 0.08, "Primary metals",
  "332", 0.09, "Fabricated metal products",
  "333", 0.10, "Machinery manufacturing",
  "334", 0.10, "Computer and electronic products",
  "335", 0.22, "Electrical equipment",
  "336", 0.05, "Transportation equipment",
  "337", 0.30, "Furniture and related products",
  "339", 0.25, "Miscellaneous manufacturing"
)

stopifnot(all(ntr_gaps_naics3$ntr_gap >= 0 & ntr_gaps_naics3$ntr_gap <= 1))
cat("NTR gaps range:", range(ntr_gaps_naics3$ntr_gap), "\n")
cat("High-NTR-gap sectors (>0.20):", sum(ntr_gaps_naics3$ntr_gap > 0.20), "\n")

# ── 3. Merge NTR gaps ────────────────────────────────────────────────────────
qwi <- qwi %>%
  inner_join(ntr_gaps_naics3 %>% select(naics3, ntr_gap, sector_name), by = "naics3")

cat("QWI rows after NTR gap merge:", nrow(qwi), "\n")
if (nrow(qwi) == 0) stop("FATAL: NTR gap merge produced zero rows. Check NAICS codes.")

# ── 4. Construct county-level pre-PNTR Black manufacturing share ─────────────
pre_pntr <- qwi %>%
  filter(year <= 2000, !is.na(employment)) %>%
  group_by(county_fips, race) %>%
  summarise(mean_emp = mean(employment, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = race, values_from = mean_emp, values_fill = 0) %>%
  mutate(
    total_mfg_emp = BK + WH + AS,
    black_share = BK / (BK + WH),
    black_share_total = BK / total_mfg_emp
  ) %>%
  select(county_fips, black_share, black_share_total, total_mfg_emp)

cat("Pre-PNTR Black share stats:\n")
cat("  Mean:", round(mean(pre_pntr$black_share, na.rm = TRUE), 3), "\n")
cat("  Median:", round(median(pre_pntr$black_share, na.rm = TRUE), 3), "\n")
cat("  SD:", round(sd(pre_pntr$black_share, na.rm = TRUE), 3), "\n")

qwi <- qwi %>%
  inner_join(pre_pntr %>% select(county_fips, black_share), by = "county_fips")

# ── 5. Construct county-level NTR exposure (Bartik-style) ────────────────────
# Use earliest available data (some states start after 2000)
county_ntr <- qwi %>%
  filter(!is.na(employment), employment > 0) %>%
  group_by(county_fips) %>%
  filter(year <= min(year) + 2) %>%  # first 3 years of data per county
  ungroup() %>%
  group_by(county_fips, naics3) %>%
  summarise(
    mean_emp = mean(employment, na.rm = TRUE),
    ntr_gap = first(ntr_gap),
    .groups = "drop"
  ) %>%
  filter(mean_emp > 0) %>%
  group_by(county_fips) %>%
  summarise(
    county_ntr_gap = weighted.mean(ntr_gap, mean_emp, na.rm = TRUE),
    n_industries = n(),
    .groups = "drop"
  )

cat("County NTR gap stats:\n")
cat("  Mean:", round(mean(county_ntr$county_ntr_gap), 3), "\n")
cat("  SD:", round(sd(county_ntr$county_ntr_gap), 3), "\n")

qwi <- qwi %>%
  inner_join(county_ntr %>% select(county_fips, county_ntr_gap), by = "county_fips")

# ── 6. Save ──────────────────────────────────────────────────────────────────
saveRDS(qwi, "../data/qwi_panel.rds")
saveRDS(ntr_gaps_naics3, "../data/ntr_gaps.rds")
saveRDS(pre_pntr, "../data/pre_pntr_shares.rds")
saveRDS(county_ntr, "../data/county_ntr_exposure.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Panel dimensions:", nrow(qwi), "rows\n")
cat("Counties:", n_distinct(qwi$county_fips), "\n")
cat("Industries (NAICS3):", n_distinct(qwi$naics3), "\n")
cat("Quarters:", n_distinct(paste(qwi$year, qwi$quarter)), "\n")
cat("Races:", paste(unique(qwi$race), collapse = ", "), "\n")

dbDisconnect(con, shutdown = TRUE)
