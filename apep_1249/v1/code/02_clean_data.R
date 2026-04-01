## 02_clean_data.R — Variable construction and data quality checks

source("00_packages.R")

panel <- fread("../data/panel.csv")
cat("Panel loaded:", nrow(panel), "obs\n")

# ---------------------------------------------------------------
# Data quality: check for implausibly small values
# ---------------------------------------------------------------
# ACT mining has zeros — drop ACT for mining-specific analysis
# For electricity, ACT and NT are very small (< 3K) — keep but flag
panel[, small_state := state %in% c("ACT", "NT")]

# ---------------------------------------------------------------
# Within-state demeaning for visual displays
# ---------------------------------------------------------------
panel[, log_emp_dm := log_emp - mean(log_emp), by = .(state, industry)]

# ---------------------------------------------------------------
# Create alternative treatment intensity measures
# ---------------------------------------------------------------
# 1. Binary high-coal indicator (top 3: NSW, VIC, QLD)
panel[, high_coal := as.integer(coal_share >= 0.60)]

# 2. Quartile-based treatment groups
panel[, coal_group := fcase(
  coal_share == 0, "zero",
  coal_share <= 0.10, "low",
  coal_share <= 0.50, "medium",
  coal_share > 0.50, "high"
)]

# ---------------------------------------------------------------
# State-level controls: total non-electricity employment as proxy
# for state economic conditions
# ---------------------------------------------------------------
non_elec <- panel[industry != "electricity",
                  .(non_elec_emp = sum(employment)),
                  by = .(state, yq, year, quarter)]
panel <- merge(panel, non_elec, by = c("state", "yq", "year", "quarter"), all.x = TRUE)
panel[, log_non_elec := log(non_elec_emp)]

# ---------------------------------------------------------------
# State-specific linear time trends
# ---------------------------------------------------------------
panel[, time_trend := yq - 2005]
panel[, state_trend := paste0("trend_", state)]

# ---------------------------------------------------------------
# Employment share of coal-intensive vs non-coal industries
# This serves as a mechanism check: if carbon tax shifts composition
# ---------------------------------------------------------------
state_totals <- panel[, .(total_emp = sum(employment)), by = .(state, yq)]
panel <- merge(panel, state_totals, by = c("state", "yq"), all.x = TRUE)
panel[, emp_share := employment / total_emp]

# ---------------------------------------------------------------
# Summary statistics for paper
# ---------------------------------------------------------------
elec <- panel[industry == "electricity"]

cat("\n=== Summary statistics: Electricity sector ===\n")
cat("Pre-tax (2005-2012Q2):\n")
print(elec[period == "pre", .(
  mean_emp = round(mean(employment), 2),
  sd_emp = round(sd(employment), 2),
  mean_log_emp = round(mean(log_emp), 3),
  sd_log_emp = round(sd(log_emp), 3),
  n_obs = .N
)])

cat("\nTax period (2012Q3-2014Q2):\n")
print(elec[period == "tax", .(
  mean_emp = round(mean(employment), 2),
  sd_emp = round(sd(employment), 2),
  mean_log_emp = round(mean(log_emp), 3),
  sd_log_emp = round(sd(log_emp), 3),
  n_obs = .N
)])

cat("\nPost-repeal (2014Q3-2019):\n")
print(elec[period == "post_repeal", .(
  mean_emp = round(mean(employment), 2),
  sd_emp = round(sd(employment), 2),
  mean_log_emp = round(mean(log_emp), 3),
  sd_log_emp = round(sd(log_emp), 3),
  n_obs = .N
)])

# Summary by coal group
cat("\n=== Mean electricity employment by coal group ===\n")
print(elec[, .(mean_emp = round(mean(employment), 1),
               states = paste(unique(state), collapse=",")),
           by = coal_group][order(-mean_emp)])

# Save cleaned panel
fwrite(panel, "../data/panel_clean.csv")
cat("\nCleaned panel saved:", nrow(panel), "obs\n")
