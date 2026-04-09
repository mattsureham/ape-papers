## 02_clean_data.R — Construct analysis variables
source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
squid <- fread(file.path(data_dir, "squid_panel.csv"))
squid[, date := as.Date(date)]

# ---- Main analysis sample: CHN, KOR, TWN, JPN ----
# These are the major squid jigging nations with clear subsidy status
main <- squid[flag %in% c("CHN", "KOR", "TWN", "JPN")]

cat("Main sample flags:\n")
print(main[, .(n_days = uniqueN(date), total_hours = round(sum(fishing_hours)),
               mean_vessels = round(mean(mmsi_present), 1)), by = flag])

# ---- Outcome variables ----
# Log fishing hours (add 1 to handle zeros)
main[, log_fishing_hours := log(fishing_hours + 1)]
# Fishing hours per vessel (intensive margin)
main[, hours_per_vessel := fifelse(mmsi_present > 0, fishing_hours / mmsi_present, 0)]
main[, log_hours_per_vessel := log(hours_per_vessel + 1)]
# Extensive margin: whether any fishing occurred
main[, any_fishing := as.integer(fishing_hours > 0)]

# ---- Lunar bins for nonparametric analysis ----
main[, lunar_bin := cut(lunar_fraction, breaks = seq(0, 1, 0.1), include.lowest = TRUE,
                        labels = paste0(seq(0, 90, 10), "-", seq(10, 100, 10), "%"))]

# ---- Subsidy indicator ----
main[, subsidized := as.integer(flag == "CHN")]

# ---- Interaction term ----
main[, lunar_x_subsidized := lunar_fraction * subsidized]

# ---- Summary statistics ----
cat("\nSummary statistics (main sample):\n")
cat("N observations:", nrow(main), "\n")
cat("N unique dates:", uniqueN(main$date), "\n")
cat("N flags:", uniqueN(main$flag), "\n")
cat("Mean fishing hours:", round(mean(main$fishing_hours), 1), "\n")
cat("SD fishing hours:", round(sd(main$fishing_hours), 1), "\n")
cat("Mean lunar fraction:", round(mean(main$lunar_fraction), 3), "\n")

# ---- Save ----
fwrite(main, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis_panel.csv:", nrow(main), "rows\n")
