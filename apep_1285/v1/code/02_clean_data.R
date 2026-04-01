## 02_clean_data.R — Construct analysis panel
## APEP-1285: AEOI Shock and Swiss Real Estate

source("00_packages.R")

df_raw <- readRDS("../data/snb_real_estate_raw.rds")
banking <- readRDS("../data/banking_intensity.rds")

cat("=== Cleaning SNB Real Estate Data ===\n")
cat("Raw dimensions: ", nrow(df_raw), " x ", ncol(df_raw), "\n")

# Rename columns to meaningful names
names(df_raw) <- c("year", "property_type", "region", "unit", "value")

# Keep only annual observations (unit = "A"), drop "T" (trend)
df <- df_raw %>%
  filter(unit == "A") %>%
  mutate(
    year = as.integer(year),
    value = as.numeric(value)
  ) %>%
  filter(!is.na(value), !is.na(year)) %>%
  select(year, property_type, region, value)

cat("After filtering to annual: ", nrow(df), " rows\n")
cat("Years: ", min(df$year), " to ", max(df$year), "\n")
cat("Regions: ", paste(sort(unique(df$region)), collapse = ", "), "\n")
cat("Property types: ", paste(sort(unique(df$property_type)), collapse = ", "), "\n")

# Check region codes against banking intensity
cat("\nRegion codes in data: ", paste(sort(unique(df$region)), collapse = ", "), "\n")
cat("Region codes in banking: ", paste(sort(banking$region), collapse = ", "), "\n")

# Note: data has RO (Rest of Switzerland?) and RG (another Lake Geneva?)
# Let me check what regions are present
region_summary <- df %>%
  filter(year == 2016) %>%
  group_by(region) %>%
  summarise(n_types = n(), .groups = "drop")
cat("\nRegions with data in 2016:\n")
print(region_summary)

# Merge banking intensity
# Need to handle the RG0/RG1/RO discrepancy — check if RG and RO exist
if ("RG" %in% unique(df$region) & !("RG0" %in% unique(df$region))) {
  # RG in the data corresponds to RG0 (Lake Geneva)
  banking$region[banking$region == "RG0"] <- "RG"
}
if ("RO" %in% unique(df$region)) {
  # RO = Rest of Lake Geneva / Other Lake Geneva (Valais)
  # This maps to RG1 in our banking intensity
  banking$region[banking$region == "RG1"] <- "RO"
}

# Merge
df <- df %>%
  left_join(banking %>% select(region, banking_share, foreign_bank_share, region_name),
            by = "region")

# Check merge
cat("\nMerge results:\n")
cat("Matched: ", sum(!is.na(df$banking_share)), " / ", nrow(df), "\n")

# Drop the national total (GS) — we analyze regions only
df <- df %>% filter(region != "GS")

cat("After dropping national total: ", nrow(df), " rows\n")

# Check for missing banking intensity
unmatched <- df %>% filter(is.na(banking_share)) %>% distinct(region)
if (nrow(unmatched) > 0) {
  cat("WARNING: Unmatched regions: ", paste(unmatched$region, collapse = ", "), "\n")
  # Assign median banking share to unmatched regions
  median_share <- median(banking$banking_share, na.rm = TRUE)
  median_foreign <- median(banking$foreign_bank_share, na.rm = TRUE)
  df <- df %>%
    mutate(
      banking_share = ifelse(is.na(banking_share), median_share, banking_share),
      foreign_bank_share = ifelse(is.na(foreign_bank_share), median_foreign, foreign_bank_share),
      region_name = ifelse(is.na(region_name), region, region_name)
    )
}

# Create analysis variables
df <- df %>%
  mutate(
    post = as.integer(year >= 2017),
    treat_intensity = banking_share,
    treat_x_post = treat_intensity * post,
    # Log price index
    log_price = log(value),
    # Standardize treatment intensity (mean 0, SD 1) for interpretation
    treat_std = (banking_share - mean(banking_share)) / sd(banking_share)
  )

# Create event time variable
df <- df %>%
  mutate(event_time = year - 2017)

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat("Panel dimensions: ", n_distinct(df$region), " regions x ",
    n_distinct(df$year), " years\n")
cat("Property types: ", n_distinct(df$property_type), "\n")
cat("Total observations: ", nrow(df), "\n")

# Banking intensity distribution
cat("\nBanking intensity (NOGA 64 share) by region:\n")
df %>%
  distinct(region, region_name, banking_share, foreign_bank_share) %>%
  arrange(desc(banking_share)) %>%
  print()

# Pre-treatment outcome summary by property type
cat("\nPre-treatment (2010-2016) price index by property type:\n")
df %>%
  filter(year >= 2010, year <= 2016) %>%
  group_by(property_type) %>%
  summarise(
    mean_price = mean(value, na.rm = TRUE),
    sd_price = sd(value, na.rm = TRUE),
    min_price = min(value, na.rm = TRUE),
    max_price = max(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Save analysis panel
saveRDS(df, "../data/analysis_panel.rds")

cat("\nAnalysis panel saved. Ready for estimation.\n")
