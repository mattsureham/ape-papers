## 02_clean_data.R — Merge POStPlan treatment with BFS county outcomes
## apep_0783: USPS POStPlan and Rural Business Formation

source("00_packages.R")

data_dir <- "../data/"

# ============================================================
# 1. Load and clean POStPlan treatment data
# ============================================================
cat("=== Cleaning POStPlan data ===\n")

postplan <- readRDS(file.path(data_dir, "postplan_raw.rds"))

# Focus on POStPlan-affected offices (those with hour reductions)
# Proposed Level: 2, 4, 6 = hours reduced; 18 = upgraded to Level 18 (not reduced)
postplan <- postplan %>%
  mutate(
    zip5 = substr(gsub("[^0-9]", "", ZIP.Code), 1, 5),
    proposed_hours = as.numeric(Proposed.Level),
    # Original hours were 8 for all POStPlan offices
    hours_lost = ifelse(proposed_hours <= 6, 8 - proposed_hours, 0),
    treated = hours_lost > 0,
    awel = as.numeric(AWEL)
  )

cat("Treatment distribution:\n")
cat("  Reduced to 2 hours (lost 6):", sum(postplan$proposed_hours == 2), "\n")
cat("  Reduced to 4 hours (lost 4):", sum(postplan$proposed_hours == 4), "\n")
cat("  Reduced to 6 hours (lost 2):", sum(postplan$proposed_hours == 6), "\n")
cat("  Upgraded to Level 18 (no loss):", sum(postplan$proposed_hours == 18), "\n")

# ============================================================
# 2. Load ZIP-to-county crosswalk
# ============================================================
cat("\n=== Loading ZIP-to-county crosswalk ===\n")

xwalk <- readRDS(file.path(data_dir, "zip_county_xwalk.rds"))

# Extract ZCTA5 and county FIPS
xwalk_clean <- xwalk %>%
  mutate(
    zip5 = sprintf("%05d", as.integer(GEOID_ZCTA5_20)),
    county_fips = sprintf("%05d", as.integer(GEOID_COUNTY_20)),
    area_pct = AREALAND_PART / AREALAND_ZCTA5_20  # share of ZIP area in county
  ) %>%
  # Take the county that contains the largest share of each ZIP
  group_by(zip5) %>%
  slice_max(area_pct, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(zip5, county_fips)

cat("Crosswalk: ", nrow(xwalk_clean), " unique ZIP-county mappings\n")

# ============================================================
# 3. Merge POStPlan with county FIPS
# ============================================================
cat("\n=== Merging POStPlan with counties ===\n")

postplan_county <- postplan %>%
  left_join(xwalk_clean, by = "zip5")

matched <- sum(!is.na(postplan_county$county_fips))
cat("ZIP-county match rate:", matched, "/", nrow(postplan_county),
    "(", round(100 * matched / nrow(postplan_county), 1), "%)\n")

# Drop unmatched
postplan_county <- postplan_county %>%
  filter(!is.na(county_fips))

# ============================================================
# 4. Construct county-level treatment variables
# ============================================================
cat("\n=== Constructing county-level treatment ===\n")

county_treatment <- postplan_county %>%
  group_by(county_fips) %>%
  summarise(
    n_po_total = n(),
    n_po_treated = sum(treated),
    n_po_2hr = sum(proposed_hours == 2),
    n_po_4hr = sum(proposed_hours == 4),
    n_po_6hr = sum(proposed_hours == 6),
    n_po_18 = sum(proposed_hours == 18),
    # Treatment intensity: average hours lost per PO in county
    avg_hours_lost = mean(hours_lost),
    # Total hours lost in county
    total_hours_lost = sum(hours_lost),
    # Share of POs that were treated
    share_treated = mean(treated),
    # Dose: weighted by severity (more weight on 2-hour offices)
    dose = sum(hours_lost) / n(),
    # Mean AWEL score
    mean_awel = mean(awel, na.rm = TRUE),
    .groups = "drop"
  )

cat("Counties with any POStPlan PO:", nrow(county_treatment), "\n")
cat("Counties with treated POs (hours reduced):", sum(county_treatment$n_po_treated > 0), "\n")
cat("\nDose distribution (avg hours lost):\n")
print(summary(county_treatment$dose))

# ============================================================
# 5. Load and reshape BFS data
# ============================================================
cat("\n=== Loading BFS county data ===\n")

bfs <- readxl::read_xlsx(
  file.path(data_dir, "bfs_county_apps_annual.xlsx"),
  skip = 2  # Skip header rows
)

cat("BFS raw:", nrow(bfs), "counties ×", ncol(bfs), "columns\n")
cat("Columns:", paste(names(bfs), collapse = ", "), "\n")

# Reshape to long format
bfs_long <- bfs %>%
  mutate(
    county_fips = paste0(
      sprintf("%02d", as.integer(state_fips)),
      sprintf("%03d", as.integer(county_fips))
    )
  ) %>%
  select(county_fips, State, County, starts_with("BA")) %>%
  pivot_longer(
    cols = starts_with("BA"),
    names_to = "year",
    values_to = "ba"
  ) %>%
  mutate(
    year = as.integer(gsub("BA", "", year)),
    ba = as.numeric(ba)
  )

cat("BFS long format:", nrow(bfs_long), "county-years\n")
cat("Year range:", min(bfs_long$year), "-", max(bfs_long$year), "\n")
cat("Counties:", n_distinct(bfs_long$county_fips), "\n")

# ============================================================
# 6. Merge treatment with outcomes
# ============================================================
cat("\n=== Merging treatment and outcomes ===\n")

# Create panel: all counties × all years
panel <- bfs_long %>%
  left_join(county_treatment, by = "county_fips") %>%
  mutate(
    # Counties not in POStPlan data = untreated (no post offices affected)
    has_postplan_po = !is.na(n_po_total),
    n_po_treated = replace_na(n_po_treated, 0),
    dose = replace_na(dose, 0),
    share_treated = replace_na(share_treated, 0),
    avg_hours_lost = replace_na(avg_hours_lost, 0),
    total_hours_lost = replace_na(total_hours_lost, 0),
    # Binary treatment: any treated POs in county
    ever_treated = n_po_treated > 0,
    # Post-treatment indicator (POStPlan started Sep 2012, main rollout 2013-2015)
    post = year >= 2013,
    # Treatment × post
    treat_post = ever_treated * post,
    # Dose × post (continuous treatment)
    dose_post = dose * post,
    # State FIPS for clustering
    state_fips = substr(county_fips, 1, 2),
    # Log BA (adding 1 for zeros)
    log_ba = log(ba + 1)
  )

cat("Panel dimensions:", nrow(panel), "county-years\n")
cat("Unique counties:", n_distinct(panel$county_fips), "\n")
cat("Treated counties:", sum(panel$ever_treated & panel$year == 2012), "\n")
cat("Control counties:", sum(!panel$ever_treated & panel$year == 2012), "\n")

# ============================================================
# 7. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# Pre-treatment means by treatment status
pre_stats <- panel %>%
  filter(year < 2013) %>%
  group_by(ever_treated) %>%
  summarise(
    n_counties = n_distinct(county_fips),
    mean_ba = mean(ba, na.rm = TRUE),
    sd_ba = sd(ba, na.rm = TRUE),
    median_ba = median(ba, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment (2005-2012) business applications by treatment status:\n")
print(pre_stats)

# Dose distribution among treated
dose_stats <- panel %>%
  filter(ever_treated, year == 2012) %>%
  summarise(
    mean_dose = mean(dose),
    sd_dose = sd(dose),
    p25_dose = quantile(dose, 0.25),
    p50_dose = quantile(dose, 0.50),
    p75_dose = quantile(dose, 0.75)
  )
cat("\nDose distribution (treated counties, avg hours lost per PO):\n")
print(dose_stats)

# ============================================================
# 8. Save analysis dataset
# ============================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(county_treatment, file.path(data_dir, "county_treatment.rds"))

cat("\n=== Cleaning complete ===\n")
cat("Analysis panel saved:", nrow(panel), "rows\n")
