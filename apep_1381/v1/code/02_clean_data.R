# Clean and prepare data for analysis
source("code/00_packages.R")

# Load raw data
df_raw <- read.csv("data/psa_panel_raw.csv", stringsAsFactors = FALSE)

# Convert to data table for efficiency
df <- as.data.table(df_raw)

# Calculate baseline tobacco dependence (2013-2017 average)
baseline_period <- df[Year %between% c(2013, 2017), ]

# For each province, calculate mean tobacco area
baseline_exposure <- baseline_period[, .(
  baseline_tobacco_area = mean(Tobacco_Area_Ha, na.rm = TRUE)
), by = Province]

# Define treated as provinces with baseline tobacco area > 100 hectares (meaningful producers)
# The idea manifest identifies 11 high-exposure provinces
baseline_exposure[, tobacco_dependence := baseline_tobacco_area / max(baseline_tobacco_area)]
baseline_exposure[, n_treated := sum(baseline_tobacco_area > 100)]

# Merge back to main dataset
df <- merge(df, baseline_exposure[, .(Province, tobacco_dependence)], by = "Province")

# Create treatment timing indicators
df[, year_post_train := pmax(0, Year - 2017)]  # Years since treatment
df[, post_2018 := as.integer(Year >= 2018)]
df[, treated := as.integer(tobacco_dependence > median(tobacco_dependence))]  # Binary treatment for some specs

# Create interaction for continuous DiD
df[, treated_post := tobacco_dependence * post_2018]

# Create event-study lags and leads
for (k in -8:7) {
  lag_year <- 2018 + k
  col_name <- paste0("lag_", k)
  df[[col_name]] <- as.integer(df$Year == lag_year) * df$tobacco_dependence
}

# Create dummy variables for event study (alternative specification)
df[, event_time := Year - 2018]
event_dummies <- model.matrix(~ 0 + factor(event_time), data = df)
for (i in 1:ncol(event_dummies)) {
  col_name <- paste0("event_", colnames(event_dummies)[i])
  df[[col_name]] <- event_dummies[, i]
}

# Add province and year fixed effects identifiers
df[, prov_fe := as.factor(Province)]
df[, year_fe := as.factor(Year)]

# Log tobacco area (handle zeros)
df[, log_tobacco_area := log(Tobacco_Area_Ha + 0.1)]

# Outcome: change in tobacco acreage
df <- df[order(Province, Year)]
df[, tobacco_area_lag := shift(Tobacco_Area_Ha, 1), by = Province]
df[, dlog_area := log(Tobacco_Area_Ha + 0.1) - log(tobacco_area_lag + 0.1)]

# Summary statistics
message("Dataset dimensions: ", nrow(df), " province-year observations")
message("Provinces: ", n_distinct(df$Province))
message("Years: ", min(df$Year), "-", max(df$Year))
message("\nBaseline tobacco dependence summary:")
print(summary(df$tobacco_dependence))

message("\nTobacco area (hectares) summary:")
print(summary(df$Tobacco_Area_Ha))

message("\nPre-2018 (2010-2017) vs Post-2018 (2018-2024) mean acreage by exposure:")
print(df[, .(
  mean_area = mean(Tobacco_Area_Ha, na.rm = TRUE),
  sd_area = sd(Tobacco_Area_Ha, na.rm = TRUE)
), by = .(post_2018)])

# Save clean dataset
write.csv(df, "data/tobacco_panel_clean.csv", row.names = FALSE)
saveRDS(df, "data/tobacco_panel_clean.rds")

message("\n✓ Clean data saved to data/tobacco_panel_clean.csv")

# Write diagnostics
diagnostics_list <- list(
  n_treated = n_distinct(df$Province[df$tobacco_dependence > 0.1]),
  n_pre = length(unique(df$Year[df$Year < 2018])),
  n_obs = nrow(df)
)

jsonlite::write_json(diagnostics_list, "data/diagnostics.json", auto_unbox = TRUE)
message("✓ Diagnostics written to data/diagnostics.json")
