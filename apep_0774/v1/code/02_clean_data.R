# 02_clean_data.R — Build mine-quarter panel with inspection events
source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. Load inspections — regular (E01) only
# =============================================================================
cat("=== 1. Loading inspections ===\n")

insp <- fread(file.path(data_dir, "Inspections.txt"), sep = "|", fill = TRUE,
              select = c("EVENT_NO", "MINE_ID", "INSPECTION_BEGIN_DT",
                         "ACTIVITY_CODE", "COAL_METAL_IND"))

cat("Total inspection records:", formatC(nrow(insp), big.mark = ","), "\n")

# Keep regular safety inspections (E01 and legacy codes 01, AAA)
insp <- insp[ACTIVITY_CODE %in% c("E01", "01", "AAA")]
cat("Regular safety inspections:", formatC(nrow(insp), big.mark = ","), "\n")

# Parse date and create quarter
insp[, insp_date := as.Date(INSPECTION_BEGIN_DT, format = "%m/%d/%Y")]
insp <- insp[!is.na(insp_date)]
insp[, year := year(insp_date)]
insp[, quarter := quarter(insp_date)]
insp[, yq := year + (quarter - 1) / 4]

# Restrict to 2000-2024
insp <- insp[year >= 2000 & year <= 2024]
cat("After date filter (2000-2024):", formatC(nrow(insp), big.mark = ","), "\n")


# =============================================================================
# 2. Load violations — count S&S per inspection event
# =============================================================================
cat("\n=== 2. Loading violations ===\n")

viol <- fread(file.path(data_dir, "Violations.txt"), sep = "|", fill = TRUE,
              select = c("EVENT_NO", "MINE_ID", "SIG_SUB", "PROPOSED_PENALTY"))

cat("Total violation records:", formatC(nrow(viol), big.mark = ","), "\n")

# Count S&S violations per inspection event
viol[, is_ss := SIG_SUB == "Y"]
ss_counts <- viol[, .(n_ss = sum(is_ss, na.rm = TRUE),
                       total_penalty = sum(as.numeric(PROPOSED_PENALTY), na.rm = TRUE)),
                   by = EVENT_NO]

cat("Unique events with violations:", formatC(nrow(ss_counts), big.mark = ","), "\n")


# =============================================================================
# 3. Merge inspections with violation severity
# =============================================================================
cat("\n=== 3. Merging inspections with violations ===\n")

insp_sev <- merge(insp, ss_counts, by = "EVENT_NO", all.x = TRUE)
insp_sev[is.na(n_ss), n_ss := 0L]
insp_sev[is.na(total_penalty), total_penalty := 0]

cat("Inspections with S&S counts:\n")
print(insp_sev[, .N, by = .(severe = n_ss >= 3)][order(severe)])

# Define treatment: severe (>=3 S&S) vs clean (0 S&S)
insp_sev[, treatment := fcase(
  n_ss >= 3, "severe",
  n_ss == 0, "clean",
  default = "moderate"
)]

cat("\nTreatment distribution:\n")
print(insp_sev[, .N, by = treatment][order(-N)])

# Keep only severe and clean for stacked DiD
events <- insp_sev[treatment %in% c("severe", "clean")]
cat("Events for analysis:", formatC(nrow(events), big.mark = ","), "\n")


# =============================================================================
# 4. Load mine-quarter employment data
# =============================================================================
cat("\n=== 4. Loading employment data ===\n")

emp <- fread(file.path(data_dir, "MinesProdQuarterly.txt"), sep = "|", fill = TRUE,
             select = c("MINE_ID", "STATE", "SUBUNIT", "CAL_YR", "CAL_QTR",
                         "AVG_EMPLOYEE_CNT", "HOURS_WORKED"))

cat("Total employment records:", formatC(nrow(emp), big.mark = ","), "\n")

# Aggregate to mine × quarter (across subunits)
emp_mine <- emp[, .(
  emp = sum(as.numeric(AVG_EMPLOYEE_CNT), na.rm = TRUE),
  hours = sum(as.numeric(HOURS_WORKED), na.rm = TRUE),
  state = STATE[1]
), by = .(MINE_ID, year = CAL_YR, quarter = CAL_QTR)]

emp_mine[, yq := year + (quarter - 1) / 4]
emp_mine <- emp_mine[year >= 2000 & year <= 2024]

cat("Mine-quarters:", formatC(nrow(emp_mine), big.mark = ","), "\n")
cat("Unique mines:", formatC(uniqueN(emp_mine$MINE_ID), big.mark = ","), "\n")


# =============================================================================
# 5. Build stacked event-study panel
# =============================================================================
cat("\n=== 5. Building stacked event-study panel ===\n")

# For each event, create an event-study window: -4 to +8 quarters
# Keep first regular inspection per mine per quarter (if multiple)
events_first <- events[order(MINE_ID, yq, -n_ss),
                        .SD[1],
                        by = .(MINE_ID, year, quarter)]

cat("Unique mine-quarter events:", formatC(nrow(events_first), big.mark = ","), "\n")

# Create event time grid
event_grid <- events_first[, {
  eq <- yq  # Event quarter (as decimal year)
  ey <- year
  eqtr <- quarter

  # Generate -4 to +8 quarters
  offsets <- -4:8
  grid_years <- integer(length(offsets))
  grid_qtrs <- integer(length(offsets))

  for (i in seq_along(offsets)) {
    total_qtr <- (ey - 2000) * 4 + eqtr + offsets[i]
    grid_years[i] <- 2000 + total_qtr %/% 4
    grid_qtrs[i] <- ((total_qtr - 1) %% 4) + 1
  }

  list(
    panel_year = grid_years,
    panel_quarter = grid_qtrs,
    event_time = offsets,
    event_treatment = treatment
  )
}, by = .(event_id = EVENT_NO, MINE_ID, event_year = year, event_quarter = quarter)]

cat("Event-grid rows:", formatC(nrow(event_grid), big.mark = ","), "\n")

# Merge with employment
event_grid[, panel_yq := panel_year + (panel_quarter - 1) / 4]
emp_mine[, panel_yq := yq]

panel <- merge(event_grid, emp_mine[, .(MINE_ID, panel_yq, emp, hours, state)],
               by = c("MINE_ID", "panel_yq"), all.x = TRUE)

# Drop events where we can't observe the full window
panel <- panel[!is.na(emp)]
events_with_data <- panel[, .(n_obs = .N), by = event_id]
full_events <- events_with_data[n_obs >= 10, event_id]  # At least 10 of 13 quarters
panel <- panel[event_id %in% full_events]

cat("Panel after merge and filter:", formatC(nrow(panel), big.mark = ","), "\n")
cat("Events with sufficient data:", formatC(length(full_events), big.mark = ","), "\n")
cat("Unique mines:", formatC(uniqueN(panel$MINE_ID), big.mark = ","), "\n")

# Log employment
panel[, log_emp := log(pmax(emp, 1))]

# Summary
cat("\nSummary by treatment:\n")
print(panel[event_time == 0, .(
  n_events = uniqueN(event_id),
  n_mines = uniqueN(MINE_ID),
  mean_emp = round(mean(emp, na.rm = TRUE), 1),
  median_emp = round(median(emp, na.rm = TRUE), 1)
), by = event_treatment])


# =============================================================================
# 6. Save
# =============================================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
saveRDS(panel, file.path(data_dir, "panel.rds"))
cat("\nPanel saved.\n")
