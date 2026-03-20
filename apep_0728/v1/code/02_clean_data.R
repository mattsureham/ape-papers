## 02_clean_data.R — apep_0728
## Construct analysis variables for DDD estimation

source("00_packages.R")

qwi <- readRDS("../data/qwi_panel.rds")
cat("Loaded QWI panel:", nrow(qwi), "rows\n")

# ── 1. Construct key variables ────────────────────────────────────────────────

# Create Black indicator for the race dimension
qwi <- qwi %>%
  mutate(
    is_black = as.integer(race == "BK"),
    is_white = as.integer(race == "WH"),
    is_asian = as.integer(race == "AS"),
    log_earnings = log(avg_earnings),
    # Time period indicators
    year_q = paste0(year, "Q", quarter),
    # Relative quarter to PNTR (Q4 2000 = 0)
    rel_quarter = (year - 2000) * 4 + (quarter - 4),
    # Treatment intensity interactions
    ntr_x_black = ntr_gap * is_black,
    ntr_x_post = ntr_gap * post_pntr,
    black_x_post = is_black * post_pntr,
    # Triple interaction
    ntr_x_black_x_post = ntr_gap * is_black * post_pntr,
    # High NTR gap indicator (above median)
    high_ntr = as.integer(ntr_gap > median(ntr_gap)),
    # County-industry identifier
    county_industry = paste(county_fips, naics3, sep = "_"),
    # County-quarter identifier
    county_quarter = paste(county_fips, year, quarter, sep = "_"),
    # Industry-quarter identifier
    industry_quarter = paste(naics3, year, quarter, sep = "_")
  )

# Drop observations with missing earnings (suppressed cells)
qwi_clean <- qwi %>%
  filter(!is.na(log_earnings), is.finite(log_earnings))

cat("Rows after dropping missing earnings:", nrow(qwi_clean), "\n")
cat("Dropped", nrow(qwi) - nrow(qwi_clean), "rows with missing earnings\n")

# ── 2. Create Black-White earnings gap panel ──────────────────────────────────
# For each county × industry × quarter: compute BW gap
bw_gap <- qwi_clean %>%
  filter(race %in% c("BK", "WH")) %>%
  select(county_fips, naics3, year, quarter, race, log_earnings, employment,
         ntr_gap, black_share, state_fips, post_pntr, sector_name,
         county_ntr_gap, time_q, rel_quarter) %>%
  pivot_wider(
    id_cols = c(county_fips, naics3, year, quarter, ntr_gap, black_share,
                state_fips, post_pntr, sector_name, county_ntr_gap, time_q, rel_quarter),
    names_from = race,
    values_from = c(log_earnings, employment)
  ) %>%
  mutate(
    bw_earnings_gap = log_earnings_BK - log_earnings_WH,
    county_industry = paste(county_fips, naics3, sep = "_"),
    county_quarter = paste(county_fips, year, quarter, sep = "_"),
    industry_quarter = paste(naics3, year, quarter, sep = "_"),
    high_ntr = as.integer(ntr_gap > median(ntr_gap))
  ) %>%
  filter(!is.na(bw_earnings_gap), is.finite(bw_earnings_gap))

cat("Black-White gap panel:", nrow(bw_gap), "county-industry-quarter cells\n")
cat("Counties:", n_distinct(bw_gap$county_fips), "\n")

# ── 3. Summary statistics ────────────────────────────────────────────────────
cat("\n=== SUMMARY STATISTICS ===\n")

# Pre-PNTR vs Post-PNTR earnings by race
pre_stats <- qwi_clean %>%
  filter(race %in% c("BK", "WH")) %>%
  group_by(race, post_pntr) %>%
  summarise(
    mean_earnings = mean(avg_earnings, na.rm = TRUE),
    mean_log_earnings = mean(log_earnings, na.rm = TRUE),
    mean_employment = mean(employment, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )
print(pre_stats)

# High vs Low NTR gap comparison
ntr_stats <- qwi_clean %>%
  filter(race %in% c("BK", "WH")) %>%
  group_by(race, high_ntr, post_pntr) %>%
  summarise(
    mean_earnings = mean(avg_earnings, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  )
cat("\nEarnings by race × NTR gap × period:\n")
print(ntr_stats)

# ── 4. Save cleaned data ────────────────────────────────────────────────────
saveRDS(qwi_clean, "../data/qwi_clean.rds")
saveRDS(bw_gap, "../data/bw_gap_panel.rds")

cat("\n=== CLEAN DATA COMPLETE ===\n")
cat("Main panel (race-level):", nrow(qwi_clean), "rows\n")
cat("BW gap panel:", nrow(bw_gap), "rows\n")
