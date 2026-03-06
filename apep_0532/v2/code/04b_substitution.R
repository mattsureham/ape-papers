# ==============================================================================
# 04b_substitution.R — Google Trends substitution analysis
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================
# Shows WHERE attention goes during heat shocks:
# - In high-ag states: more searches for agricultural terms, fewer for climate
# - In low-ag states: more climate searches, no agricultural response
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# LOAD SUBSTITUTION PANEL
# ==============================================================================
gt_file <- file.path(data_dir, "gtrends_substitution_panel.csv")

if (!file.exists(gt_file)) {
  cat("Substitution panel not found. Creating from Google Trends state data...\n")

  gt_raw <- fread(file.path(data_dir, "google_trends_state_v2.csv"))
  wx <- fread(file.path(data_dir, "india_weather_daily.csv"))
  ag <- fread(file.path(data_dir, "ag_shares.csv"))

  # Process weather
  wx[, date := as.Date(date)]
  wx[, year := year(date)]
  wx[, month := month(date)]

  wx_monthly <- wx[year >= 2004, .(
    tavg_mean = mean(tavg, na.rm = TRUE),
    tavg_anomaly = mean(tavg, na.rm = TRUE) # placeholder
  ), by = .(state, year, month)]

  # Process GT
  gt_raw[, hits_num := as.numeric(ifelse(hits == "<1", 0.5, hits))]
  gt_raw[, date := as.Date(date)]
  gt_raw[, year := year(date)]
  gt_raw[, month := month(date)]

  gt_raw[, term_type := fifelse(keyword %in% c("global warming", "climate change"), "climate",
                        fifelse(keyword %in% c("crop damage", "rain forecast", "crop insurance", "mandi price"), "agricultural",
                        "placebo"))]

  gt_panel <- gt_raw[, .(search_index = mean(hits_num, na.rm = TRUE)),
                      by = .(state, year, month, term_type)]
  gt_wide <- dcast(gt_panel, state + year + month ~ term_type,
                    value.var = "search_index", fill = 0)

  gt_wide <- merge(gt_wide, wx_monthly, by = c("state", "year", "month"), all.x = TRUE)
  gt_wide <- merge(gt_wide, ag[, .(state, ag_emp_share)], by = "state", all.x = TRUE)
  gt_wide[, state_id := as.integer(as.factor(state))]
  gt_wide[, time_id := year * 100 + month]
  gt_wide[, tavg_x_ag := tavg_anomaly * ag_emp_share]

  fwrite(gt_wide, gt_file)
}

gt <- fread(gt_file)
cat("Substitution panel:", nrow(gt), "state-month obs\n\n")

# ==============================================================================
# SUBSTITUTION REGRESSIONS
# ==============================================================================
cat("=== Substitution Analysis ===\n\n")

# Climate search response (replicating v1 finding)
cat("--- Climate searches ---\n")
s1 <- feols(climate ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = gt, cluster = ~state_id)
summary(s1)

# Agricultural search response (should be opposite sign)
cat("\n--- Agricultural searches ---\n")
s2 <- feols(agricultural ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = gt, cluster = ~state_id)
summary(s2)

# Placebo search (should be null)
cat("\n--- Placebo searches ---\n")
s3 <- feols(placebo ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = gt, cluster = ~state_id)
summary(s3)

# ==============================================================================
# SPLIT BY AG TERCILE
# ==============================================================================
cat("\n--- Split by agricultural tercile ---\n\n")

gt[, ag_tercile := cut(ag_emp_share,
                        breaks = quantile(ag_emp_share, c(0, 1/3, 2/3, 1), na.rm = TRUE),
                        labels = c("Low", "Medium", "High"),
                        include.lowest = TRUE)]

for (outcome in c("climate", "agricultural")) {
  for (t in c("Low", "High")) {
    cat(outcome, "searches in", t, "ag states:\n")
    f <- as.formula(paste(outcome, "~ tavg_anomaly | state_id + time_id"))
    m <- tryCatch(
      feols(f, data = gt[ag_tercile == t], cluster = ~state_id),
      error = function(e) { cat("  Error:", e$message, "\n"); NULL }
    )
    if (!is.null(m)) summary(m)
    cat("\n")
  }
}

# ==============================================================================
# SAVE RESULTS
# ==============================================================================
sub_results <- data.table(
  outcome = c("Climate", "Agricultural", "Placebo"),
  tavg_coef = c(coef(s1)["tavg_anomaly"], coef(s2)["tavg_anomaly"], coef(s3)["tavg_anomaly"]),
  tavg_se = c(se(s1)["tavg_anomaly"], se(s2)["tavg_anomaly"], se(s3)["tavg_anomaly"]),
  interaction_coef = c(coef(s1)["tavg_x_ag"], coef(s2)["tavg_x_ag"], coef(s3)["tavg_x_ag"]),
  interaction_se = c(se(s1)["tavg_x_ag"], se(s2)["tavg_x_ag"], se(s3)["tavg_x_ag"])
)
fwrite(sub_results, file.path(data_dir, "substitution_results.csv"))

cat("\n=== Substitution analysis complete ===\n")
