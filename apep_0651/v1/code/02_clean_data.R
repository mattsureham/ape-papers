# ==============================================================================
# 02_clean_data.R — Construct analysis dataset
# APEP Paper apep_0651: The Spotlight Effect on Mine Safety Enforcement
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ------------------------------------------------------------------------------
# 1. Load raw data
# ------------------------------------------------------------------------------

accidents   <- readRDS(file.path(data_dir, "accidents_raw.rds"))
inspections <- readRDS(file.path(data_dir, "inspections_raw.rds"))
violations  <- readRDS(file.path(data_dir, "violations_raw.rds"))
mines       <- readRDS(file.path(data_dir, "mines_raw.rds"))
fema        <- fread(file.path(data_dir, "fema_disasters.csv"))
vix         <- fread(file.path(data_dir, "fred_vix.csv"))

cat("Loaded: accidents=", nrow(accidents), ", inspections=", nrow(inspections),
    ", violations=", nrow(violations), ", mines=", nrow(mines),
    ", fema=", nrow(fema), ", vix=", nrow(vix), "\n")

# Print column names for debugging
cat("\nAccident columns:\n")
cat(paste(names(accidents), collapse = ", "), "\n\n")

# ------------------------------------------------------------------------------
# 2. Identify fatal accidents
# ------------------------------------------------------------------------------

# DEGREE_INJURY_CD: "01" = Fatality
if ("DEGREE_INJURY_CD" %in% names(accidents)) {
  # Check values
  cat("DEGREE_INJURY_CD values:\n")
  print(table(accidents$DEGREE_INJURY_CD))
  fatalities <- accidents[DEGREE_INJURY_CD == "01" | DEGREE_INJURY_CD == 1]
} else {
  stop("Cannot find DEGREE_INJURY_CD column. Available: ",
       paste(names(accidents), collapse = ", "))
}

cat("\nTotal fatalities:", nrow(fatalities), "\n")

# Parse fatality dates
fatalities[, fatality_date := as.Date(ACCIDENT_DT, format = "%m/%d/%Y")]
if (sum(is.na(fatalities$fatality_date)) > nrow(fatalities) / 2) {
  fatalities[, fatality_date := as.Date(ACCIDENT_DT)]
}
cat("Fatalities with valid dates:", sum(!is.na(fatalities$fatality_date)), "\n")

# Mine ID
fatalities[, mine_id := as.character(MINE_ID)]

# Drop missing dates and restrict to 2000-2024
fatalities <- fatalities[!is.na(fatality_date)]
fatalities <- fatalities[year(fatality_date) >= 2000 & year(fatality_date) <= 2024]
cat("Fatalities 2000-2024:", nrow(fatalities), "\n")

# Collapse to unique fatality events (mine × date)
fatality_events <- fatalities[, .(
  n_killed = .N
), by = .(mine_id, fatality_date)]

cat("Unique fatality events (mine x date):", nrow(fatality_events), "\n")

# Add time identifiers
fatality_events[, `:=`(
  year = year(fatality_date),
  quarter = quarter(fatality_date),
  yq = paste0(year(fatality_date), "Q", quarter(fatality_date)),
  week_start = floor_date(fatality_date, "week"),
  month = floor_date(fatality_date, "month")
)]

# ------------------------------------------------------------------------------
# 3. Construct news competition instruments
# ------------------------------------------------------------------------------

# --- FEMA: count new disaster declarations in the same week ---
cat("\nConstructing FEMA disaster instrument...\n")
fema[, decl_date := as.Date(substr(declarationDate, 1, 10))]
fema <- fema[!is.na(decl_date)]
fema[, decl_week := floor_date(decl_date, "week")]

# Weekly disaster counts (number of distinct disaster declarations)
fema_weekly <- fema[, .(
  n_disasters = uniqueN(disasterNumber),
  n_major_disasters = sum(declarationType == "DR", na.rm = TRUE)
), by = decl_week]

setnames(fema_weekly, "decl_week", "week_start")

# Also compute monthly counts for robustness
fema[, decl_month := floor_date(decl_date, "month")]
fema_monthly <- fema[, .(
  n_disasters_month = uniqueN(disasterNumber)
), by = decl_month]
setnames(fema_monthly, "decl_month", "month")

# Merge weekly disaster counts to fatality events
fatality_events <- merge(fatality_events, fema_weekly,
                         by = "week_start", all.x = TRUE)
fatality_events[is.na(n_disasters), n_disasters := 0]
fatality_events[is.na(n_major_disasters), n_major_disasters := 0]

# Monthly disasters
fatality_events <- merge(fatality_events, fema_monthly,
                         by = "month", all.x = TRUE)
fatality_events[is.na(n_disasters_month), n_disasters_month := 0]

cat("FEMA instrument: mean weekly disasters =", round(mean(fatality_events$n_disasters), 2),
    ", SD =", round(sd(fatality_events$n_disasters), 2), "\n")

# Log and standardize
fatality_events[, log_disasters := log(n_disasters + 1)]
fatality_events[, z_disasters := scale(log_disasters)[, 1]]

# --- VIX: weekly average volatility ---
if (nrow(vix) > 0) {
  cat("Constructing VIX instrument...\n")
  vix[, date := as.Date(date)]
  vix[, week_start := floor_date(date, "week")]
  vix_weekly <- vix[, .(
    vix_mean = mean(vix, na.rm = TRUE)
  ), by = week_start]

  fatality_events <- merge(fatality_events, vix_weekly,
                           by = "week_start", all.x = TRUE)
  # VIX not available on all days — forward-fill
  fatality_events[, vix_mean := nafill(vix_mean, type = "locf")]
  fatality_events[, z_vix := scale(log(pmax(vix_mean, 1)))[, 1]]

  cat("VIX instrument: mean =", round(mean(fatality_events$vix_mean, na.rm = TRUE), 1),
      ", SD =", round(sd(fatality_events$vix_mean, na.rm = TRUE), 1), "\n")
}

# --- Combined instrument: PCA of FEMA + VIX ---
if ("z_vix" %in% names(fatality_events)) {
  has_both <- !is.na(fatality_events$z_disasters) & !is.na(fatality_events$z_vix)
  if (sum(has_both) > 100) {
    pca_data <- fatality_events[has_both, .(z_disasters, z_vix)]
    pca <- prcomp(pca_data, center = TRUE, scale. = TRUE)
    fatality_events[has_both, z_news_pressure := pca$x[, 1]]
    cat("Combined news pressure (PC1): captures",
        round(pca$sdev[1]^2 / sum(pca$sdev^2) * 100, 1), "% of variance\n")
  }
}

# ------------------------------------------------------------------------------
# 4. Construct enforcement outcomes (pre/post fatality)
# ------------------------------------------------------------------------------

cat("\nParsing enforcement dates...\n")

# Inspections
inspections[, mine_id := as.character(MINE_ID)]
inspections[, insp_date := as.Date(INSPECTION_BEGIN_DT, format = "%m/%d/%Y")]
if (sum(is.na(inspections$insp_date)) > nrow(inspections) / 2) {
  inspections[, insp_date := as.Date(INSPECTION_BEGIN_DT)]
}
cat("Valid inspection dates:", sum(!is.na(inspections$insp_date)),
    "of", nrow(inspections), "\n")

# Violations
violations[, mine_id := as.character(MINE_ID)]

# Try multiple date column names
viol_date_cols <- intersect(c("VIOLATION_OCCUR_DT", "VIOLATION_DT", "EVENT_NO"),
                            names(violations))
if ("VIOLATION_OCCUR_DT" %in% names(violations)) {
  violations[, viol_date := as.Date(VIOLATION_OCCUR_DT, format = "%m/%d/%Y")]
  if (sum(is.na(violations$viol_date)) > nrow(violations) / 2) {
    violations[, viol_date := as.Date(VIOLATION_OCCUR_DT)]
  }
} else {
  cat("Violation date columns:", paste(names(violations), collapse = ", "), "\n")
  # Try VIOLATION_ISSUE_DT
  viol_dt_col <- grep("(?i)date|_dt$", names(violations), value = TRUE)
  cat("Date-like columns:", paste(viol_dt_col, collapse = ", "), "\n")
  if (length(viol_dt_col) > 0) {
    violations[, viol_date := as.Date(get(viol_dt_col[1]), format = "%m/%d/%Y")]
  }
}
cat("Valid violation dates:", sum(!is.na(violations$viol_date)),
    "of", nrow(violations), "\n")

# Penalty column
penalty_cols <- intersect(c("PROPOSED_PENALTY", "PENALTY_AMOUNT", "AMOUNT_ASSESSED",
                            "PROPOSED_PENALTY_AMOUNT"), names(violations))
if (length(penalty_cols) > 0) {
  violations[, penalty := as.numeric(gsub("[^0-9.]", "", get(penalty_cols[1])))]
  cat("Penalty column:", penalty_cols[1], "\n")
} else {
  cat("No penalty column found. Setting penalties to 0.\n")
  violations[, penalty := 0]
}

# S&S (significant and substantial) flag
ss_cols <- intersect(c("SIG_SUB", "SIG_AND_SUB", "SIGNIFICANT_SUBSTANTIAL"),
                     names(violations))
if (length(ss_cols) > 0) {
  violations[, is_ss := grepl("Y|1|TRUE", get(ss_cols[1]), ignore.case = TRUE)]
  cat("S&S column:", ss_cols[1], "\n")
} else {
  violations[, is_ss := FALSE]
}

# ------------------------------------------------------------------------------
# 5. Compute enforcement windows for each fatality event
# ------------------------------------------------------------------------------

cat("\nComputing enforcement windows for", nrow(fatality_events), "events...\n")

# Vectorized approach: for each event, count enforcement in windows
# Pre-compute inspection and violation indices for speed
setkey(inspections, mine_id, insp_date)
setkey(violations, mine_id, viol_date)

compute_enforcement <- function(ev_mine_id, ev_date) {
  # Pre-event enforcement (365 days before)
  pre_start <- ev_date - 365
  post_90 <- ev_date + 90
  post_180 <- ev_date + 180
  post_365 <- ev_date + 365

  mine_insp <- inspections[mine_id == ev_mine_id & !is.na(insp_date)]
  mine_viol <- violations[mine_id == ev_mine_id & !is.na(viol_date)]

  list(
    insp_pre_365 = nrow(mine_insp[insp_date >= pre_start & insp_date < ev_date]),
    insp_post_90 = nrow(mine_insp[insp_date > ev_date & insp_date <= post_90]),
    insp_post_180 = nrow(mine_insp[insp_date > ev_date & insp_date <= post_180]),
    insp_post_365 = nrow(mine_insp[insp_date > ev_date & insp_date <= post_365]),
    viol_pre_365 = nrow(mine_viol[viol_date >= pre_start & viol_date < ev_date]),
    viol_post_90 = nrow(mine_viol[viol_date > ev_date & viol_date <= post_90]),
    viol_post_180 = nrow(mine_viol[viol_date > ev_date & viol_date <= post_180]),
    viol_post_365 = nrow(mine_viol[viol_date > ev_date & viol_date <= post_365]),
    penalty_pre_365 = sum(mine_viol[viol_date >= pre_start & viol_date < ev_date]$penalty, na.rm = TRUE),
    penalty_post_90 = sum(mine_viol[viol_date > ev_date & viol_date <= post_90]$penalty, na.rm = TRUE),
    penalty_post_180 = sum(mine_viol[viol_date > ev_date & viol_date <= post_180]$penalty, na.rm = TRUE),
    penalty_post_365 = sum(mine_viol[viol_date > ev_date & viol_date <= post_365]$penalty, na.rm = TRUE),
    ss_pre_365 = sum(mine_viol[viol_date >= pre_start & viol_date < ev_date]$is_ss, na.rm = TRUE),
    ss_post_90 = sum(mine_viol[viol_date > ev_date & viol_date <= post_90]$is_ss, na.rm = TRUE)
  )
}

# Process in batches with progress reporting
n_events <- nrow(fatality_events)
enforcement_list <- vector("list", n_events)
batch_size <- 100

for (i in seq_len(n_events)) {
  enforcement_list[[i]] <- compute_enforcement(
    fatality_events$mine_id[i],
    fatality_events$fatality_date[i]
  )
  if (i %% batch_size == 0) {
    cat(sprintf("  Processed %d / %d events (%.0f%%)\n", i, n_events, i / n_events * 100))
  }
}

enforcement <- rbindlist(lapply(enforcement_list, as.data.table))
cat("Enforcement outcomes computed.\n")

# Bind to fatality events
analysis <- cbind(fatality_events, enforcement)

# ------------------------------------------------------------------------------
# 6. Add mine characteristics
# ------------------------------------------------------------------------------

mines[, mine_id := as.character(MINE_ID)]

mine_char_cols <- intersect(
  c("mine_id", "CURRENT_MINE_NAME", "STATE", "MINE_TYPE", "COAL_METAL_IND",
    "PRIMARY_SIC", "PRIMARY_SIC_DESC", "CURRENT_MINE_STATUS",
    "AVG_MINE_EMPLOYMENT", "LATITUDE", "LONGITUDE",
    "FIPS_CNTY_CD", "FIPS_CNTY_NM"),
  names(mines)
)

if (length(mine_char_cols) > 1) {
  mine_info <- unique(mines[, ..mine_char_cols])
  mine_info <- mine_info[!duplicated(mine_id, fromLast = TRUE)]
  analysis <- merge(analysis, mine_info, by = "mine_id", all.x = TRUE)
  cat("Mine characteristics matched:", sum(!is.na(analysis$STATE)),
      "of", nrow(analysis), "\n")
}

# Create analysis variables
if ("COAL_METAL_IND" %in% names(analysis)) {
  analysis[, is_coal := as.integer(COAL_METAL_IND == "C")]
}

if ("AVG_MINE_EMPLOYMENT" %in% names(analysis)) {
  analysis[, log_employment := log(pmax(as.numeric(AVG_MINE_EMPLOYMENT), 1))]
  analysis[, large_mine := as.integer(as.numeric(AVG_MINE_EMPLOYMENT) >= 50)]
}

# Fixed effects
if ("STATE" %in% names(analysis)) {
  analysis[, state_fe := as.factor(STATE)]
}
analysis[, yq_fe := as.factor(yq)]

# ------------------------------------------------------------------------------
# 7. Save analysis dataset
# ------------------------------------------------------------------------------

saveRDS(analysis, file.path(data_dir, "analysis.rds"))

cat("\n=== Analysis dataset ===\n")
cat("Observations:", nrow(analysis), "\n")
cat("Unique mines:", uniqueN(analysis$mine_id), "\n")
cat("Date range:", as.character(min(analysis$fatality_date)),
    "to", as.character(max(analysis$fatality_date)), "\n")
cat("Mean weekly FEMA disasters:", round(mean(analysis$n_disasters), 2), "\n")
cat("Mean post-90d inspections:", round(mean(analysis$insp_post_90), 2), "\n")
cat("Mean post-90d violations:", round(mean(analysis$viol_post_90), 2), "\n")
cat("Mean post-90d penalties:", round(mean(analysis$penalty_post_90), 0), "\n")

cat("\n=== Cleaning complete ===\n")
