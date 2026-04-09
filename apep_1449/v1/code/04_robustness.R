## 04_robustness.R — Robustness checks and falsification
source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt[, date := as.Date(date)]

cat("=== ROBUSTNESS & FALSIFICATION ===\n")

# ---- Robustness 1: Quadratic lunar term ----
dt[, lunar_sq := lunar_fraction^2]
r1 <- feols(log_fishing_hours ~ lunar_fraction + lunar_sq + lunar_x_subsidized |
              flag + yearmonth, data = dt, cluster = ~date)
cat("\n--- Quadratic lunar specification ---\n")
summary(r1)

# ---- Robustness 2: Day-of-week controls ----
r2 <- feols(log_fishing_hours ~ lunar_fraction + lunar_x_subsidized |
              flag + yearmonth + dow, data = dt, cluster = ~date)
cat("\n--- With day-of-week FE ---\n")
summary(r2)

# ---- Robustness 3: Binary full moon (>0.9) vs new moon (<0.1) ----
dt[, full_moon := as.integer(lunar_fraction > 0.9)]
dt[, new_moon := as.integer(lunar_fraction < 0.1)]
dt[, full_x_sub := full_moon * subsidized]

r3 <- feols(log_fishing_hours ~ full_moon + full_x_sub |
              flag + yearmonth, data = dt[full_moon == 1 | new_moon == 1],
            cluster = ~date)
cat("\n--- Binary: full moon vs new moon ---\n")
summary(r3)

# ---- Robustness 4: Levels instead of logs ----
r4 <- feols(fishing_hours ~ lunar_fraction + lunar_x_subsidized |
              flag + yearmonth, data = dt, cluster = ~date)
cat("\n--- Levels specification ---\n")
summary(r4)

# ---- Falsification 1: Trawlers (light-independent) ----
trawl_file <- file.path(data_dir, "trawler_panel.csv")
if (file.exists(trawl_file)) {
  trawl <- fread(trawl_file)
  trawl[, date := as.Date(date)]
  trawl <- trawl[flag %in% c("CHN", "KOR", "TWN", "JPN")]
  trawl[, log_fishing_hours := log(fishing_hours + 1)]
  trawl[, yearmonth := format(date, "%Y-%m")]

  if (nrow(trawl) > 100) {
    f1 <- feols(log_fishing_hours ~ lunar_fraction | flag + yearmonth,
                data = trawl, cluster = ~date)
    cat("\n--- Falsification: Trawlers (should be null) ---\n")
    summary(f1)
  }
} else {
  cat("\nTrawler data not available yet.\n")
}

# ---- Falsification 2: Year-by-year stability ----
for (y in unique(dt$year)) {
  sub <- dt[year == y]
  m <- feols(log_fishing_hours ~ lunar_fraction + lunar_x_subsidized |
               flag + month, data = sub, cluster = ~date)
  cat(sprintf("Year %d: beta_lunar=%.4f, beta_interact=%.4f, N=%d\n",
              y, coef(m)["lunar_fraction"], coef(m)["lunar_x_subsidized"], nrow(sub)))
}

# ---- Nonparametric binned means ----
bins <- dt[, .(mean_hours = mean(fishing_hours),
               mean_log_hours = mean(log_fishing_hours),
               n = .N),
           by = .(lunar_bin, fleet_type)]
fwrite(bins, file.path(data_dir, "lunar_bins.csv"))
cat("\nSaved lunar_bins.csv for nonparametric evidence.\n")

# ---- Save robustness results ----
saveRDS(list(r1 = r1, r2 = r2, r3 = r3, r4 = r4),
        file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS COMPLETE ===\n")
