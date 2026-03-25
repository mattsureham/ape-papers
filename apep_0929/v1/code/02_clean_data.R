# 02_clean_data.R — Parse MIC Excel files, construct panel dataset

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# PART 1: Parse donation time series (FY2008-FY2024)
# ============================================================

cat("=== Parsing donation time series ===\n")

raw_ts <- read_excel(
  file.path(data_dir, "municipality_timeseries.xlsx"),
  sheet = 1, col_names = FALSE
)

# Year mapping from Japanese era names (row 2)
# Cols 3-4: FY2008 (H20), 5-6: FY2009, ..., 35-36: FY2024
year_cols <- data.frame(
  col_amount = seq(3, 35, by = 2),
  col_count  = seq(4, 36, by = 2),
  fy = 2008:2024
)

# Extract municipality data (rows 5 onward, skip header rows and aggregates)
# Col 1 = prefecture, Col 2 = municipality name
data_rows <- raw_ts[5:nrow(raw_ts), ]
# Remove aggregate rows (市町村合計, 合計, 全国合計, and prefecture-only rows)
data_rows <- data_rows %>%
  filter(
    !is.na(...2),  # Municipality name must be present (excludes prefecture rows)
    !...2 %in% c("市町村合計", "合計", "全国合計"),
    !...1 %in% c("市町村合計", "合計", "全国合計")
  )

cat("Municipality rows found:", nrow(data_rows), "\n")

# Reshape to long format
panel_list <- list()
for (i in 1:nrow(year_cols)) {
  yr <- year_cols$fy[i]
  ca <- year_cols$col_amount[i]
  cc <- year_cols$col_count[i]

  tmp <- data_rows %>%
    transmute(
      prefecture = ...1,
      municipality = ...2,
      fy = yr,
      donation_amount = as.numeric(.data[[paste0("...", ca)]]),
      donation_count  = as.numeric(.data[[paste0("...", cc)]])
    )
  panel_list[[i]] <- tmp
}

panel <- bind_rows(panel_list)

# Note: amounts in the timeseries appear to be in thousands of yen (千円)
# Verify with known values (Izumisano FY2018 should be ~49.7B yen = 49,752,906 千円)
cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Unique municipalities:", n_distinct(paste(panel$prefecture, panel$municipality)), "\n")
cat("Years:", paste(sort(unique(panel$fy)), collapse = ", "), "\n")

# ============================================================
# PART 2: Parse FY2018 cost breakdown (pre-reform gift rates)
# ============================================================

cat("\n=== Parsing FY2018 cost breakdown ===\n")

raw_cost <- read_excel(
  file.path(data_dir, "fy2018_detailed_01.xlsx"),
  sheet = 1, col_names = FALSE
)

# Structure (from inspection):
# Col 1: municipality code, Col 2: prefecture, Col 3: municipality
# Col 5: FY2018 donation amount (yen), Col 12: gift procurement cost (yen)
# Col 19: gift procurement cost ratio

cost_data <- raw_cost[6:nrow(raw_cost), ] %>%
  transmute(
    muni_code   = as.character(...1),
    prefecture  = as.character(...2),
    municipality = as.character(...3),
    fy2018_donations_yen = as.numeric(...5),
    fy2018_gift_cost_yen = as.numeric(...12),
    fy2018_gift_rate     = as.numeric(...19)
  ) %>%
  filter(
    !is.na(muni_code),
    !is.na(prefecture),
    nchar(muni_code) >= 6  # Valid municipality codes are 6 digits
  )

cat("Municipalities with FY2018 cost data:", nrow(cost_data), "\n")

# Check distribution of gift rates
cat("\nFY2018 gift rate distribution:\n")
cat("  N non-missing:", sum(!is.na(cost_data$fy2018_gift_rate)), "\n")
cat("  Mean:", round(mean(cost_data$fy2018_gift_rate, na.rm = TRUE), 3), "\n")
cat("  Median:", round(median(cost_data$fy2018_gift_rate, na.rm = TRUE), 3), "\n")
cat("  P25:", round(quantile(cost_data$fy2018_gift_rate, 0.25, na.rm = TRUE), 3), "\n")
cat("  P75:", round(quantile(cost_data$fy2018_gift_rate, 0.75, na.rm = TRUE), 3), "\n")
cat("  Max:", round(max(cost_data$fy2018_gift_rate, na.rm = TRUE), 3), "\n")
cat("  Above 30%:", sum(cost_data$fy2018_gift_rate > 0.30, na.rm = TRUE), "\n")

# ============================================================
# PART 3: Merge panel with treatment assignment
# ============================================================

cat("\n=== Merging panel with treatment ===\n")

# Match by prefecture + municipality name
# First standardize names
panel <- panel %>%
  mutate(
    prefecture = str_trim(prefecture),
    municipality = str_trim(municipality)
  )

cost_data <- cost_data %>%
  mutate(
    prefecture = str_trim(prefecture),
    municipality = str_trim(municipality)
  )

# Merge
panel <- panel %>%
  left_join(
    cost_data %>% select(prefecture, municipality, muni_code,
                         fy2018_gift_rate, fy2018_donations_yen),
    by = c("prefecture", "municipality")
  )

# Check merge success
cat("Panel rows with gift rate:", sum(!is.na(panel$fy2018_gift_rate)),
    "out of", nrow(panel), "\n")
cat("Unique municipalities with gift rate:",
    n_distinct(paste(panel$prefecture[!is.na(panel$fy2018_gift_rate)],
                     panel$municipality[!is.na(panel$fy2018_gift_rate)])), "\n")

# ============================================================
# PART 4: Construct treatment variables
# ============================================================

cat("\n=== Constructing treatment variables ===\n")

# Treatment intensity = max(gift_rate - 0.30, 0)
# Binary treatment = gift_rate > 0.30
panel <- panel %>%
  mutate(
    # Treatment variables
    treat_intensity = pmax(fy2018_gift_rate - 0.30, 0, na.rm = FALSE),
    treat_binary    = as.integer(fy2018_gift_rate > 0.30),
    high_gift       = as.integer(fy2018_gift_rate > 0.30),

    # Post-reform indicator (FY2020 = first full fiscal year after June 2019 reform)
    post = as.integer(fy >= 2020),

    # Exclude FY2019 (partial treatment year)
    partial_year = as.integer(fy == 2019),

    # Log outcome (add 1 to handle zeros)
    log_donations = log(donation_amount + 1),

    # Create municipality ID
    muni_id = paste(prefecture, municipality, sep = "_"),

    # Relative time (event study)
    rel_time = fy - 2019,

    # Known excluded municipalities (June 2019)
    # Izumisano (泉佐野市), Miyaki (みやき町), Kami (高野町), Minoh (? - check)
    excluded = as.integer(municipality %in% c("泉佐野市", "みやき町", "高野町", "小山町"))
  )

# Summary statistics
cat("Treatment assignment:\n")
cat("  Treated (gift rate > 30%):", sum(panel$treat_binary == 1 & panel$fy == 2018, na.rm = TRUE), "municipalities\n")
cat("  Control (gift rate <= 30%):", sum(panel$treat_binary == 0 & panel$fy == 2018, na.rm = TRUE), "municipalities\n")
cat("  Missing gift rate:", sum(is.na(panel$treat_binary) & panel$fy == 2018), "municipalities\n")

# ============================================================
# PART 5: Save panel
# ============================================================

# Filter to analysis sample: FY2014-FY2024, non-missing treatment
# Using FY2014+ to get 5 pre-periods (FY2014-2018) + 5 post-periods (FY2020-2024)
analysis_panel <- panel %>%
  filter(
    fy >= 2014,
    !is.na(treat_binary),
    fy != 2019  # Exclude partial treatment year
  )

cat("\n=== Analysis sample ===\n")
cat("Years:", paste(sort(unique(analysis_panel$fy)), collapse = ", "), "\n")
cat("Municipalities:", n_distinct(analysis_panel$muni_id), "\n")
cat("Observations:", nrow(analysis_panel), "\n")

saveRDS(analysis_panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(panel, file.path(data_dir, "full_panel.rds"))

# Save cost data separately for additional analysis
saveRDS(cost_data, file.path(data_dir, "cost_data_fy2018.rds"))

cat("\nData cleaning complete. Files saved.\n")
