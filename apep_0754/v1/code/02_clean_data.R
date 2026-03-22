## 02_clean_data.R — Build state × store-type × quarter panel
## APEP Working Paper apep_0754

source("00_packages.R")

## ---- 1. Load data ----
retailers <- readRDS("../data/retailers_clean.rds")
pilot_dates <- readRDS("../data/pilot_dates.rds")

## ---- 2. Define analysis period ----
# Panel: 2015Q1 to 2024Q4 (5 years pre, 4+ years post for most states)
years <- 2015:2024
quarters_grid <- CJ(year = years, quarter = 1:4)
quarters_grid[, yq := paste0(year, "Q", quarter)]
quarters_grid[, yq_num := (year - 2015) * 4 + quarter]  # numeric quarter index

## ---- 3. Build active store counts by state × store_group × quarter ----
# A store is "active" in quarter t if auth_date <= end of t AND (end_date is NA or end_date > start of t)
cat("Building state × store-type × quarter panel...\n")

# Create quarter start/end dates
quarters_grid[, q_start := as.Date(paste0(year, "-", (quarter - 1) * 3 + 1, "-01"))]
quarters_grid[, q_end := q_start + months(3) - 1]

# For each quarter, count active stores and exits by state × store_group
panel_list <- list()
for (i in 1:nrow(quarters_grid)) {
  qstart <- quarters_grid$q_start[i]
  qend <- quarters_grid$q_end[i]
  yq <- quarters_grid$yq[i]
  yq_n <- quarters_grid$yq_num[i]

  # Active stores: authorized before quarter end, and either still active or ended after quarter start
  active <- retailers[auth_date <= qend & (is.na(end_date) | end_date >= qstart)]

  # Exits: stores whose end_date falls within this quarter
  exits <- retailers[!is.na(end_date) & end_date >= qstart & end_date <= qend]

  # Entries: stores authorized within this quarter
  entries <- retailers[auth_date >= qstart & auth_date <= qend]

  # Aggregate by state × store_group
  active_counts <- active[, .(n_active = .N), by = .(State, store_group)]
  exit_counts   <- exits[, .(n_exits = .N), by = .(State, store_group)]
  entry_counts  <- entries[, .(n_entries = .N), by = .(State, store_group)]

  # Merge
  merged <- merge(active_counts, exit_counts, by = c("State", "store_group"), all.x = TRUE)
  merged <- merge(merged, entry_counts, by = c("State", "store_group"), all.x = TRUE)
  merged[is.na(n_exits), n_exits := 0]
  merged[is.na(n_entries), n_entries := 0]
  merged[, yq := yq]
  merged[, yq_num := yq_n]
  merged[, year := quarters_grid$year[i]]
  merged[, quarter := quarters_grid$quarter[i]]

  panel_list[[i]] <- merged
}

panel <- rbindlist(panel_list)

# Compute exit rate
panel[, exit_rate := n_exits / n_active]
panel[, entry_rate := n_entries / n_active]
panel[, net_change_rate := (n_entries - n_exits) / n_active]

cat(sprintf("Panel: %s state-type-quarter obs\n", format(nrow(panel), big.mark = ",")))

## ---- 4. Merge treatment dates ----
# Map state abbreviations
panel <- merge(panel, pilot_dates[, .(state, pilot_date, treat_year, treat_quarter)],
               by.x = "State", by.y = "state", all.x = TRUE)

# Treatment indicator
panel[, treat_yq_num := ifelse(!is.na(treat_year),
                                (treat_year - 2015) * 4 + treat_quarter,
                                NA_real_)]
panel[, treated := as.integer(!is.na(treat_yq_num) & yq_num >= treat_yq_num)]
panel[, post := treated]  # alias

# Treatment cohort for CS-DiD (0 = never treated)
panel[, first_treat := ifelse(is.na(treat_yq_num), 0, treat_yq_num)]

# Convenience store indicator
panel[, is_conv := as.integer(store_group == "convenience")]
panel[, is_super := as.integer(store_group == "supermarket")]

# For DDD: restrict to convenience + supermarket
panel_ddd <- panel[store_group %in% c("convenience", "supermarket")]

cat(sprintf("DDD panel (conv + super): %s obs\n", format(nrow(panel_ddd), big.mark = ",")))

## ---- 5. Create state-level panel (convenience stores only) for CS-DiD ----
panel_conv <- panel[store_group == "convenience"]

cat(sprintf("Convenience store panel: %s obs\n", format(nrow(panel_conv), big.mark = ",")))

# Summary stats
cat("\n=== Summary Statistics ===\n")
cat(sprintf("States with treatment: %d\n", panel_conv[first_treat > 0, uniqueN(State)]))
cat(sprintf("Never-treated states: %d\n", panel_conv[first_treat == 0, uniqueN(State)]))
cat(sprintf("Quarters: %d (%s to %s)\n",
    uniqueN(panel$yq_num), min(panel$yq), max(panel$yq)))
cat(sprintf("Mean exit rate (convenience): %.4f\n", mean(panel_conv$exit_rate, na.rm = TRUE)))
cat(sprintf("Mean exit rate (supermarket): %.4f\n",
    mean(panel[store_group == "supermarket"]$exit_rate, na.rm = TRUE)))

## ---- 6. Save panels ----
saveRDS(panel, "../data/panel_full.rds")
saveRDS(panel_conv, "../data/panel_conv.rds")
saveRDS(panel_ddd, "../data/panel_ddd.rds")

cat("\n=== Panel construction complete ===\n")
