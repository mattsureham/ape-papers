## 02_clean_data.R — Further cleaning and panel construction
## TLV Vacancy Tax Expansion — apep_0523

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# 1. Load commune-quarter panel
# ===========================================================================
cat("=== Loading panel ===\n")
panel <- fread(file.path(data_dir, "commune_quarter_panel.csv"))
cat(sprintf("Panel loaded: %s rows, %s communes\n",
            format(nrow(panel), big.mark = ","), uniqueN(panel$codgeo)))

# ===========================================================================
# 2. Balance panel — fill missing commune-quarters with zeros
# ===========================================================================
cat("\n=== Balancing panel ===\n")

# Get all unique communes and quarters
communes <- unique(panel[, .(codgeo, group, zone_type, code_epci)])
quarters <- sort(unique(panel$quarter))
year_q_map <- unique(panel[, .(quarter, year_q)])

# Create full grid
full_grid <- CJ(codgeo = communes$codgeo, quarter = quarters)
full_grid <- merge(full_grid, communes, by = "codgeo", all.x = TRUE)
full_grid <- merge(full_grid, year_q_map, by = "quarter", all.x = TRUE)

# Merge with actual data
balanced <- merge(full_grid, panel[, .(codgeo, quarter, n_transactions, total_value,
                                        median_price, median_prix_m2, mean_surface,
                                        pct_apartment, mean_rooms)],
                  by = c("codgeo", "quarter"), all.x = TRUE)

# Fill missing with zeros for count, NA for prices
balanced[is.na(n_transactions), n_transactions := 0]

# Treatment indicators
balanced[, treated := as.integer(group == "newly_treated_2023")]
balanced[, post := as.integer(year_q >= 2024)]
balanced[, treat_post := treated * post]

# Log outcomes (add 1 for log of counts)
balanced[, log_n_trans := log(n_transactions + 1)]
balanced[, log_med_price := log(median_price)]
balanced[, log_prix_m2 := log(median_prix_m2)]

# Numeric time period (for event study)
balanced[, time_period := as.integer(factor(quarter, levels = sort(unique(quarter))))]

# Relative time to treatment (2024Q1 = 0)
treat_quarter <- "2024Q1"
treat_period <- balanced[quarter == treat_quarter, unique(time_period)]
balanced[, rel_time := time_period - treat_period]

cat(sprintf("Balanced panel: %s rows, %s communes, %s quarters\n",
            format(nrow(balanced), big.mark = ","),
            uniqueN(balanced$codgeo),
            uniqueN(balanced$quarter)))

# ===========================================================================
# 3. Compute pre-treatment summary statistics
# ===========================================================================
cat("\n=== Pre-treatment summary statistics ===\n")

pre_panel <- balanced[year_q < 2024]
pre_stats <- pre_panel[, .(
  mean_n_trans = mean(n_transactions, na.rm = TRUE),
  mean_price = mean(median_price, na.rm = TRUE),
  mean_prix_m2 = mean(median_prix_m2, na.rm = TRUE),
  mean_surface = mean(mean_surface, na.rm = TRUE),
  mean_pct_apt = mean(pct_apartment, na.rm = TRUE),
  n_communes = uniqueN(codgeo),
  total_obs = .N
), by = group]

print(pre_stats)
fwrite(pre_stats, file.path(data_dir, "pre_treatment_stats.csv"))

# ===========================================================================
# 4. Create analysis-ready datasets
# ===========================================================================

# Main analysis: newly_treated vs never_treated
main_sample <- balanced[group %in% c("newly_treated_2023", "never_treated")]
cat(sprintf("\nMain sample (newly_treated + never_treated): %s rows, %s communes\n",
            format(nrow(main_sample), big.mark = ","),
            uniqueN(main_sample$codgeo)))

# Placebo analysis: always_treated only (should show no 2023 effect)
placebo_sample <- balanced[group %in% c("always_treated", "never_treated")]
cat(sprintf("Placebo sample (always_treated + never_treated): %s rows, %s communes\n",
            format(nrow(placebo_sample), big.mark = ","),
            uniqueN(placebo_sample$codgeo)))

# Heterogeneity: by zone type
het_sample <- balanced[group %in% c("newly_treated_2023", "never_treated")]
het_sample[, zone_tendue := as.integer(zone_type == "tendue")]

# Save analysis datasets
fwrite(main_sample, file.path(data_dir, "main_sample.csv"))
fwrite(placebo_sample, file.path(data_dir, "placebo_sample.csv"))
fwrite(het_sample, file.path(data_dir, "het_sample.csv"))
fwrite(balanced, file.path(data_dir, "balanced_panel.csv"))

cat("\nAll analysis datasets saved.\n")
cat("Done.\n")
