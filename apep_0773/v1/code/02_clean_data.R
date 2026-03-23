# ============================================================
# 02_clean_data.R — Build analysis panel
# apep_0773: Collateral Damage
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"

snap <- readRDS(file.path(data_dir, "snap_monthly.rds"))
proc_rates <- readRDS(file.path(data_dir, "procedural_rates.rds"))
ea_dates <- readRDS(file.path(data_dir, "ea_dates.rds"))

cat("=== Building analysis panel ===\n")
cat("  SNAP rows:", nrow(snap), "\n")
cat("  States:", length(unique(snap$state)), "\n")

# ----------------------------------------------------------
# 1. Classify states
# ----------------------------------------------------------
integrated_states <- c("AL","AR","CO","CT","DE","FL","GA","HI",
                       "ID","IN","KY","LA","MD","MI","MS","NE",
                       "NV","NH","NM","NC","OH","PA","SC","WV")

snap[, integrated := as.integer(state %in% integrated_states)]

# Merge procedural rates
snap <- merge(snap, proc_rates, by = "state", all.x = TRUE)

# ----------------------------------------------------------
# 2. Treatment: Post April 2023 (unwinding start)
# ----------------------------------------------------------
snap[, post_unwinding := as.integer(year > 2023 | (year == 2023 & month >= 4))]

# Also create EA control: post-EA for each state
snap <- merge(snap, ea_dates, by = "state", all.x = TRUE)
snap[, post_ea := as.integer(
  as.Date(paste0(year, "-", sprintf("%02d", month), "-01")) > ea_end_month
)]
snap[is.na(post_ea), post_ea := 0L]

# ----------------------------------------------------------
# 3. Log SNAP participation
# ----------------------------------------------------------
snap[, ln_snap := log(pmax(snap_hh, 1))]
snap[, snap_rate_pct := snap_rate * 100]

# Numeric state ID
state_map <- data.table(state = sort(unique(snap$state)),
                         state_id = seq_along(sort(unique(snap$state))))
snap <- merge(snap, state_map, by = "state")

# ----------------------------------------------------------
# 4. Summary stats
# ----------------------------------------------------------
cat("\n=== Summary Statistics ===\n")
pre <- snap[post_unwinding == 0]
cat("  Pre-unwinding SNAP rate (integrated):",
    round(mean(pre[integrated == 1]$snap_rate_pct, na.rm = TRUE), 2), "%\n")
cat("  Pre-unwinding SNAP rate (separate):",
    round(mean(pre[integrated == 0]$snap_rate_pct, na.rm = TRUE), 2), "%\n")
cat("  Pre-unwinding SNAP HH (integrated, mean):",
    round(mean(pre[integrated == 1]$snap_hh, na.rm = TRUE), 0), "\n")
cat("  Pre-unwinding SNAP HH (separate, mean):",
    round(mean(pre[integrated == 0]$snap_hh, na.rm = TRUE), 0), "\n")

cat("  Total observations:", nrow(snap), "\n")
cat("  Integrated states:", sum(snap$integrated == 1 & !duplicated(snap$state)), "\n")
cat("  Separate states:", sum(snap$integrated == 0 & !duplicated(snap$state)), "\n")

saveRDS(snap, file.path(data_dir, "analysis_panel.rds"))
cat("\n=== Cleaning complete ===\n")
