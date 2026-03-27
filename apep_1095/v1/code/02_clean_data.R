## 02_clean_data.R — Variable construction and panel preparation
## apep_1095: Induced seismicity and self-regulation in Texas Permian Basin

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
earthquakes <- readRDS("../data/earthquakes_raw.rds")

cat("Panel loaded:", nrow(panel), "observations\n")

# ========================================================================
# 1. Construct treatment intensity variables
# ========================================================================

# Injection volume proxy: use SRA-level volume reduction schedules
# (RRC mandated average 54% reduction, range 25-88% by well)
# Since individual well-level H-10 data requires manual download,
# we model injection reduction intensity at the SRA level based on
# documented RRC orders:
#   Gardendale: deep disposal suspended (100% reduction for deep wells)
#   NCR: operator-led plan targeting 162,000 BPD (est. 40-60% reduction)
#   Stanton: phased reduction (est. 30-50% reduction)

panel <- panel %>%
  mutate(
    # Treatment intensity (SRA-specific reduction magnitude)
    treat_intensity = case_when(
      in_gardendale & post ~ 1.0,   # Full suspension of deep disposal
      in_ncr & post ~ 0.54,         # Average documented reduction
      in_stanton & post ~ 0.40,     # More modest reductions
      TRUE ~ 0
    ),
    # Pre-treatment seismicity baseline (for heterogeneity)
    # Will be computed below after aggregation
    log_eq_count = log1p(eq_count),
    # Binary post indicator by SRA
    post_gardendale = in_gardendale & month_date >= as.Date("2021-12-01"),
    post_ncr = in_ncr & month_date >= as.Date("2022-03-01"),
    post_stanton = in_stanton & month_date >= as.Date("2022-05-01")
  )

# ========================================================================
# 2. Compute pre-treatment baseline seismicity for each grid cell
# ========================================================================
pre_baseline <- panel %>%
  filter(year <= 2020) %>%
  group_by(grid_id) %>%
  summarize(
    pre_mean_eq = mean(eq_count, na.rm = TRUE),
    pre_total_eq = sum(eq_count, na.rm = TRUE),
    pre_any_eq = as.integer(pre_total_eq > 0),
    .groups = "drop"
  )

panel <- panel %>%
  left_join(pre_baseline, by = "grid_id") %>%
  mutate(
    pre_mean_eq = replace_na(pre_mean_eq, 0),
    pre_total_eq = replace_na(pre_total_eq, 0),
    pre_any_eq = replace_na(pre_any_eq, 0L),
    high_baseline = as.integer(pre_mean_eq > median(pre_mean_eq[pre_mean_eq > 0], na.rm = TRUE))
  )

# ========================================================================
# 3. Construct ring-zone panel for displacement analysis
# ========================================================================
# Aggregate at SRA-ring-zone × month level

ring_panel <- earthquakes %>%
  mutate(ym = paste0(year, "-", sprintf("%02d", month))) %>%
  group_by(ring_zone, ym) %>%
  summarize(
    eq_count = n(),
    eq_count_m25 = sum(mag >= 2.5, na.rm = TRUE),
    eq_count_m30 = sum(mag >= 3.0, na.rm = TRUE),
    .groups = "drop"
  )

# Fill in zero months
all_combos <- expand.grid(
  ring_zone = c("Within SRA", "0-20km buffer", "20-50km buffer", "50-100km buffer", ">100km"),
  ym = unique(panel$ym),
  stringsAsFactors = FALSE
)

ring_panel <- all_combos %>%
  left_join(ring_panel, by = c("ring_zone", "ym")) %>%
  mutate(
    eq_count = replace_na(eq_count, 0L),
    eq_count_m25 = replace_na(eq_count_m25, 0L),
    eq_count_m30 = replace_na(eq_count_m30, 0L),
    year = as.integer(substr(ym, 1, 4)),
    month_num = as.integer(substr(ym, 6, 7)),
    month_date = as.Date(paste0(ym, "-01")),
    # Post = after first SRA enforcement (Dec 2021)
    post_any = month_date >= as.Date("2021-12-01"),
    within_sra = ring_zone == "Within SRA",
    ring_factor = factor(ring_zone,
                         levels = c(">100km", "50-100km buffer", "20-50km buffer",
                                    "0-20km buffer", "Within SRA"))
  )

# ========================================================================
# 4. Construct SRA-level monthly aggregates (for event study)
# ========================================================================
sra_monthly <- panel %>%
  filter(in_any_sra) %>%
  group_by(sra_name, ym, month_date, rel_month) %>%
  summarize(
    eq_count = sum(eq_count),
    eq_count_m25 = sum(eq_count_m25),
    n_cells = n(),
    eq_rate = eq_count / n(),
    .groups = "drop"
  ) %>%
  mutate(
    post = case_when(
      sra_name == "Gardendale" ~ month_date >= as.Date("2021-12-01"),
      sra_name == "NCR" ~ month_date >= as.Date("2022-03-01"),
      sra_name == "Stanton" ~ month_date >= as.Date("2022-05-01"),
      TRUE ~ FALSE
    )
  )

# ========================================================================
# 5. Summary statistics
# ========================================================================
cat("\n=== Summary Statistics ===\n")
cat("\nPanel dimensions:\n")
cat(sprintf("  Grid cells: %d (treated: %d, control: %d)\n",
            n_distinct(panel$grid_id),
            n_distinct(panel$grid_id[panel$treated]),
            n_distinct(panel$grid_id[!panel$treated])))
cat(sprintf("  Months: %d (%s to %s)\n",
            n_distinct(panel$ym),
            min(panel$ym), max(panel$ym)))
cat(sprintf("  Total obs: %d\n", nrow(panel)))

cat("\nEarthquake counts by period:\n")
panel %>%
  mutate(period = if_else(year <= 2021, "Pre (2017-2021)", "Post (2022-2024)")) %>%
  group_by(treated, period) %>%
  summarize(total_eq = sum(eq_count), mean_eq = mean(eq_count), .groups = "drop") %>%
  print()

cat("\nSRA monthly earthquake counts:\n")
sra_monthly %>%
  group_by(sra_name, post) %>%
  summarize(mean_eq = mean(eq_count), total_eq = sum(eq_count), .groups = "drop") %>%
  print()

# ========================================================================
# 6. Save cleaned data
# ========================================================================
saveRDS(panel, "../data/panel_clean.rds")
saveRDS(ring_panel, "../data/ring_panel.rds")
saveRDS(sra_monthly, "../data/sra_monthly.rds")

cat("\nCleaned data saved.\n")
