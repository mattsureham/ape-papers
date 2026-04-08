# 02_clean_data.R — Construct running variable and analysis sample
source("00_packages.R")

raw <- readRDS("../data/raw_incidents.rds")
cpi <- readRDS("../data/cpi.rds")

# CPI base year: 1984
cpi_1984 <- cpi[year == 1984, cpi]
stopifnot(length(cpi_1984) == 1)

# Merge CPI to incidents
raw[, year := IYEAR]
df <- merge(raw, cpi, by = "year", all.x = TRUE)
df <- df[!is.na(cpi)]

# Compute CPI-adjusted threshold for each year
# Statutory threshold: $50,000 in 1984 dollars
df[, threshold := 50000 * (cpi / cpi_1984)]

# Running variable: normalized cost
df[, norm_cost := TOTAL_COST_CURRENT / threshold]

# Treatment: significant incident flag
df[, significant := as.integer(toupper(SIGNIFICANT) == "YES")]

# Filter to years with sufficient data (2010-2022)
df <- df[year >= 2010 & year <= 2022]

# Drop missing cost
df <- df[!is.na(TOTAL_COST_CURRENT) & TOTAL_COST_CURRENT > 0]

cat("Analysis sample:", nrow(df), "incidents\n")
cat("Years:", min(df$year), "-", max(df$year), "\n")
cat("Significant:", sum(df$significant), "/", nrow(df), "\n")
cat("Threshold range: $", round(min(df$threshold)), "- $", round(max(df$threshold)), "\n")

# Check first stage: significant rate by bins of norm_cost
bins <- df[, .(
  n = .N,
  pct_sig = mean(significant)
), by = .(bin = cut(norm_cost, breaks = c(0, 0.5, 0.8, 0.9, 0.95, 1.0, 1.05, 1.1, 1.2, 1.5, Inf)))]
cat("\nFirst stage by cost bin:\n")
print(bins)

# Cause codes near threshold
near <- df[norm_cost > 0.8 & norm_cost < 1.2]
cat("\nCause distribution near threshold (0.8x-1.2x):\n")
if ("CAUSE" %in% names(df)) {
  print(near[, .N, by = CAUSE][order(-N)])
} else {
  # Try alternative column names
  cause_cols <- grep("cause|CAUSE", names(df), value = TRUE, ignore.case = TRUE)
  cat("Available cause columns:", paste(cause_cols, collapse = ", "), "\n")
}

# Create operator-level panel for outcomes
# Count incidents per operator-year
op_panel <- df[, .(
  n_incidents = .N,
  n_significant = sum(significant),
  total_cost = sum(TOTAL_COST_CURRENT, na.rm = TRUE)
), by = .(OPERATOR_ID, year)]

cat("\nOperator panel:", nrow(op_panel), "operator-years\n")
cat("Unique operators:", uniqueN(op_panel$OPERATOR_ID), "\n")

# For each incident near threshold, compute operator's future incident rate
# Window: t+1 to t+3
bw <- 0.20  # 20% bandwidth for main sample
near_incidents <- df[abs(norm_cost - 1) < bw]
cat("\nIncidents within", bw*100, "% bandwidth:", nrow(near_incidents), "\n")

# Compute future outcomes for each incident
compute_future <- function(inc_row, all_data, window = 3) {
  op <- inc_row$OPERATOR_ID
  yr <- inc_row$year
  future <- all_data[OPERATOR_ID == op & year > yr & year <= yr + window]
  pre <- all_data[OPERATOR_ID == op & year < yr & year >= yr - window]
  list(
    future_incidents = nrow(future),
    future_cost = sum(future$TOTAL_COST_CURRENT, na.rm = TRUE),
    pre_incidents = nrow(pre),
    pre_rate = nrow(pre) / window
  )
}

# Vectorized approach for speed
cat("Computing future outcomes for near-threshold incidents...\n")

results <- list()
for (i in seq_len(nrow(near_incidents))) {
  inc <- near_incidents[i]
  op <- inc$OPERATOR_ID
  yr <- inc$year

  future <- df[OPERATOR_ID == op & year > yr & year <= yr + 3]
  pre <- df[OPERATOR_ID == op & year < yr & year >= yr - 3]

  results[[i]] <- data.table(
    report_number = inc$REPORT_NUMBER,
    operator_id = op,
    year = yr,
    norm_cost = inc$norm_cost,
    significant = inc$significant,
    total_cost = inc$TOTAL_COST_CURRENT,
    threshold = inc$threshold,
    future_incidents = nrow(future),
    future_cost = sum(future$TOTAL_COST_CURRENT, na.rm = TRUE),
    pre_incidents = nrow(pre),
    pre_rate = nrow(pre) / 3
  )
}

analysis <- rbindlist(results)

# Normalize future incidents by pre-rate (add 1 to avoid division by zero)
analysis[, future_rate := future_incidents / 3]
analysis[, norm_future := future_rate / (pre_rate + 0.1)]

# Centered running variable
analysis[, norm_cost_centered := norm_cost - 1]

cat("\nAnalysis dataset:", nrow(analysis), "observations\n")
cat("Below threshold:", sum(analysis$norm_cost < 1), "\n")
cat("Above threshold:", sum(analysis$norm_cost >= 1), "\n")
cat("Mean future incidents (below):", mean(analysis[norm_cost < 1, future_incidents]), "\n")
cat("Mean future incidents (above):", mean(analysis[norm_cost >= 1, future_incidents]), "\n")

# Save
saveRDS(df, "../data/incidents_clean.rds")
saveRDS(analysis, "../data/analysis.rds")
saveRDS(op_panel, "../data/operator_panel.rds")

cat("Cleaned data saved.\n")
