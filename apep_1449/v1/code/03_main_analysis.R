## 03_main_analysis.R — Main regressions
source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt[, date := as.Date(date)]

cat("=== MAIN ANALYSIS ===\n")
cat("Observations:", nrow(dt), "\n\n")

# ---- Table 1: Summary Statistics ----
sum_stats <- dt[, .(
  Mean = mean(fishing_hours),
  SD = sd(fishing_hours),
  Min = min(fishing_hours),
  Max = max(fishing_hours),
  N = .N
), by = fleet_type]
cat("Summary by fleet type:\n")
print(sum_stats)

# Pre-treatment SD of fishing hours (for SDE calculation later)
sd_y_all <- sd(dt$fishing_hours)
sd_y_chn <- sd(dt[flag == "CHN"]$fishing_hours)
sd_y_comp <- sd(dt[flag != "CHN"]$fishing_hours)
cat("\nSD(fishing_hours) — All:", round(sd_y_all, 2),
    "| CHN:", round(sd_y_chn, 2),
    "| Comparator:", round(sd_y_comp, 2), "\n")

# ---- Specification 1: Pooled lunar effect ----
# log(fishing_hours + 1) = beta * lunar_fraction + flag FE + yearmonth FE
m1 <- feols(log_fishing_hours ~ lunar_fraction | flag + yearmonth, data = dt,
            cluster = ~date)
cat("\n--- Model 1: Pooled lunar effect ---\n")
summary(m1)

# ---- Specification 2: Heterogeneous by subsidy status ----
m2 <- feols(log_fishing_hours ~ lunar_fraction + lunar_x_subsidized |
              flag + yearmonth, data = dt, cluster = ~date)
cat("\n--- Model 2: Heterogeneous (subsidy interaction) ---\n")
summary(m2)

# ---- Specification 3: By-flag regressions ----
flags <- c("CHN", "KOR", "TWN", "JPN")
flag_results <- list()
for (f in flags) {
  sub <- dt[flag == f]
  if (nrow(sub) > 30) {
    m <- feols(log_fishing_hours ~ lunar_fraction | yearmonth, data = sub,
               cluster = ~date)
    flag_results[[f]] <- m
    cat(sprintf("\n--- Flag %s: beta = %.4f (SE = %.4f), N = %d ---\n",
                f, coef(m)["lunar_fraction"], se(m)["lunar_fraction"], nrow(sub)))
  }
}

# ---- Specification 4: Extensive margin (any fishing) ----
m4 <- feols(any_fishing ~ lunar_fraction + lunar_x_subsidized |
              flag + yearmonth, data = dt, cluster = ~date)
cat("\n--- Model 4: Extensive margin ---\n")
summary(m4)

# ---- Specification 5: Intensive margin (hours per vessel) ----
m5 <- feols(log_hours_per_vessel ~ lunar_fraction + lunar_x_subsidized |
              flag + yearmonth, data = dt, cluster = ~date)
cat("\n--- Model 5: Intensive margin (hours/vessel) ---\n")
summary(m5)

# ---- Save regression objects ----
saveRDS(list(m1 = m1, m2 = m2, m4 = m4, m5 = m5, flag_results = flag_results,
             sd_y_all = sd_y_all, sd_y_chn = sd_y_chn, sd_y_comp = sd_y_comp,
             sum_stats = sum_stats),
        file.path(data_dir, "main_results.rds"))

# ---- Diagnostics for validation ----
# For continuous treatment design: "treated" = high-illumination days (>0.5)
# "pre" = number of distinct lunar cycles in the sample
jsonlite::write_json(list(
  n_treated = nrow(dt[lunar_fraction > 0.5]),
  n_pre = length(unique(dt$yearmonth)),
  n_obs = nrow(dt)
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
