# 02_clean_data.R — Build institution-year panel from IPEDS files
# apep_0844: State Disinvestment and Enrollment Composition

source("00_packages.R")

data_dir <- "../data"
years <- 2003:2022

# ============================================================================
# 1. Load and stack Header files (institution metadata)
# ============================================================================
cat("=== Loading Header files ===\n")
hd_list <- list()
for (y in years) {
  f <- file.path(data_dir, paste0("hd", y, ".csv"))
  if (!file.exists(f)) next
  dt <- fread(f, select = c("UNITID", "INSTNM", "STABBR", "FIPS",
                             "CONTROL", "ICLEVEL", "SECTOR"))
  dt[, year := y]
  hd_list[[as.character(y)]] <- dt
}
hd <- rbindlist(hd_list, fill = TRUE)
cat("  Header rows:", nrow(hd), "| Unique institutions:", uniqueN(hd$UNITID), "\n")

# Filter: Public 4-year institutions only (CONTROL=1, ICLEVEL=1)
hd <- hd[CONTROL == 1 & ICLEVEL == 1]
cat("  After filter (public 4-year):", uniqueN(hd$UNITID), "institutions\n")

# ============================================================================
# 2. Load Tuition data (IC_AY files)
# ============================================================================
cat("\n=== Loading IC_AY (tuition) files ===\n")
ic_list <- list()
for (y in years) {
  # IC_AY files have various naming patterns
  candidates <- list.files(data_dir, pattern = paste0("(?i)ic", y, ".*ay"),
                           full.names = TRUE)
  candidates <- candidates[grepl("\\.csv$", candidates, ignore.case = TRUE)]
  if (length(candidates) == 0) next

  dt <- fread(candidates[1])
  names(dt) <- toupper(names(dt))

  # Key variables: TUITION2 = in-state tuition, TUITION3 = out-of-state tuition
  cols_want <- intersect(names(dt), c("UNITID", "TUITION2", "TUITION3",
                                       "FEE2", "FEE3", "CHG2AY3", "CHG3AY3"))
  dt <- dt[, ..cols_want]
  dt[, year := y]
  ic_list[[as.character(y)]] <- dt
}
ic <- rbindlist(ic_list, fill = TRUE)

# Force numeric conversion (IPEDS files sometimes have character columns)
for (col in c("TUITION2", "TUITION3", "CHG2AY3", "CHG3AY3")) {
  if (col %in% names(ic)) ic[, (col) := as.numeric(get(col))]
}

# Harmonize tuition: prefer TUITION2/3, fall back to CHG2AY3/CHG3AY3
if ("CHG2AY3" %in% names(ic)) {
  ic[, tuition_instate := fifelse(!is.na(TUITION2) & TUITION2 > 0, TUITION2,
                                  fifelse(!is.na(CHG2AY3) & CHG2AY3 > 0, CHG2AY3, NA_real_))]
} else {
  ic[, tuition_instate := fifelse(!is.na(TUITION2) & TUITION2 > 0, TUITION2, NA_real_)]
}
if ("CHG3AY3" %in% names(ic)) {
  ic[, tuition_outstate := fifelse(!is.na(TUITION3) & TUITION3 > 0, TUITION3,
                                    fifelse(!is.na(CHG3AY3) & CHG3AY3 > 0, CHG3AY3, NA_real_))]
} else {
  ic[, tuition_outstate := fifelse(!is.na(TUITION3) & TUITION3 > 0, TUITION3, NA_real_)]
}
ic <- ic[, .(UNITID, year, tuition_instate, tuition_outstate)]
cat("  Tuition rows:", nrow(ic), "\n")

# ============================================================================
# 3. Load Finance data (F1A — state appropriations)
# ============================================================================
cat("\n=== Loading Finance (F1A) files ===\n")
fin_list <- list()
for (y in years) {
  yy1 <- sprintf("%02d", y %% 100)
  yy2 <- sprintf("%02d", (y + 1) %% 100)
  pattern <- paste0("(?i)f", yy1, yy2, ".*f1a")
  candidates <- list.files(data_dir, pattern = pattern, full.names = TRUE)
  candidates <- candidates[grepl("\\.csv$", candidates, ignore.case = TRUE)]
  # Prefer non-RV version
  if (length(candidates) > 1) {
    non_rv <- candidates[!grepl("_rv", candidates, ignore.case = TRUE)]
    if (length(non_rv) > 0) candidates <- non_rv
  }
  if (length(candidates) == 0) next

  dt <- fread(candidates[1])
  names(dt) <- toupper(names(dt))

  # F1A15 = State appropriations (GASB public institutions)
  # F1A16 = Local appropriations
  # F1A01 = Tuition and fees revenue
  cols_want <- intersect(names(dt), c("UNITID", "F1A01", "F1A02", "F1A15",
                                       "F1A16", "F1A26", "F1A27"))
  dt <- dt[, ..cols_want]
  dt[, year := y]
  fin_list[[as.character(y)]] <- dt
}
fin <- rbindlist(fin_list, fill = TRUE)

# Force numeric (IPEDS files sometimes have character markers for missing)
for (col in c("F1A01", "F1A02", "F1A15", "F1A16", "F1A26", "F1A27")) {
  if (col %in% names(fin)) fin[, (col) := suppressWarnings(as.numeric(get(col)))]
}

# Ensure columns exist (fill with NA if missing from some years)
for (col in c("F1A01", "F1A15", "F1A26")) {
  if (!col %in% names(fin)) fin[, (col) := NA_real_]
}

# State appropriations = F1A15 (operating) + F1A26 (nonoperating, if available)
fin[, state_approp := fifelse(is.na(F1A15), 0, F1A15) +
                      fifelse(is.na(F1A26), 0, F1A26)]
# Tuition revenue
fin[, tuition_revenue := F1A01]
fin <- fin[, .(UNITID, year, state_approp, tuition_revenue)]
cat("  Finance rows:", nrow(fin), "\n")

# ============================================================================
# 4. Load Enrollment data (EF — by race)
# ============================================================================
cat("\n=== Loading Fall Enrollment files ===\n")
enr_list <- list()
for (y in years) {
  candidates <- list.files(data_dir, pattern = paste0("(?i)ef", y, "a"),
                           full.names = TRUE)
  candidates <- candidates[grepl("\\.csv$", candidates, ignore.case = TRUE)]
  if (length(candidates) == 0) next

  dt <- fread(candidates[1])
  names(dt) <- toupper(names(dt))

  # Filter to grand total (EFALEVEL=1 = All students total)
  if ("EFALEVEL" %in% names(dt)) {
    dt <- dt[EFALEVEL == 1]
  }

  # Race variables (post-2008 naming)
  race_cols <- c("EFTOTLT", "EFBKAAT", "EFHISPT", "EFWHITT",
                 "EFNRALT", "EFASIAT", "EFAIANT", "EF2MORT", "EFUNKNT")
  cols_have <- intersect(names(dt), c("UNITID", race_cols))
  dt <- dt[, ..cols_have]
  # Force numeric for all enrollment columns
  for (col in setdiff(names(dt), "UNITID")) {
    dt[, (col) := suppressWarnings(as.numeric(get(col)))]
  }
  dt[, year := y]
  enr_list[[as.character(y)]] <- dt
}
enr <- rbindlist(enr_list, fill = TRUE)
cat("  Enrollment rows:", nrow(enr), "\n")

# ============================================================================
# 5. Load Student Financial Aid (Pell grants)
# ============================================================================
cat("\n=== Loading SFA (financial aid) files ===\n")
sfa_list <- list()
for (y in years) {
  yy1 <- sprintf("%02d", y %% 100)
  yy2 <- sprintf("%02d", (y + 1) %% 100)
  pattern <- paste0("(?i)sfa", yy1, yy2)
  candidates <- list.files(data_dir, pattern = pattern, full.names = TRUE)
  candidates <- candidates[grepl("\\.csv$", candidates, ignore.case = TRUE)]
  if (length(candidates) > 1) {
    non_rv <- candidates[!grepl("_rv", candidates, ignore.case = TRUE)]
    if (length(non_rv) > 0) candidates <- non_rv
  }
  if (length(candidates) == 0) next

  dt <- fread(candidates[1])
  names(dt) <- toupper(names(dt))

  # PGRNT_N = Pell grant recipients, PGRNT_P = Pell pct, PGRNT_A = avg Pell amount
  # SCUGRAD = full-time first-time degree-seeking undergrads (denominator)
  # UPGRNTN = number receiving any federal grants
  cols_want <- intersect(names(dt), c("UNITID", "PGRNT_N", "PGRNT_P", "PGRNT_A",
                                       "SCUGRAD", "UPGRNTN", "FGRNT_N", "FGRNT_P",
                                       "SCFA2"))
  dt <- dt[, ..cols_want]
  # Force numeric
  for (col in setdiff(names(dt), "UNITID")) {
    dt[, (col) := suppressWarnings(as.numeric(get(col)))]
  }
  dt[, year := y]
  sfa_list[[as.character(y)]] <- dt
}
sfa <- rbindlist(sfa_list, fill = TRUE)
cat("  SFA rows:", nrow(sfa), "\n")

# ============================================================================
# 6. Merge into institution-year panel
# ============================================================================
cat("\n=== Merging panel ===\n")
# Ensure UNITID is integer everywhere
hd[, UNITID := as.integer(UNITID)]
ic[, UNITID := as.integer(UNITID)]
fin[, UNITID := as.integer(UNITID)]
enr[, UNITID := as.integer(UNITID)]
sfa[, UNITID := as.integer(UNITID)]

panel <- merge(hd, ic, by = c("UNITID", "year"), all.x = TRUE)
panel <- merge(panel, fin, by = c("UNITID", "year"), all.x = TRUE)
panel <- merge(panel, enr, by = c("UNITID", "year"), all.x = TRUE)
panel <- merge(panel, sfa, by = c("UNITID", "year"), all.x = TRUE)

cat("  Panel rows:", nrow(panel), "| Institutions:", uniqueN(panel$UNITID),
    "| Years:", paste(range(panel$year), collapse="-"), "\n")

# ============================================================================
# 7. Construct key variables
# ============================================================================

# Pell share: prefer PGRNT_P (pre-computed pct of first-time full-time UG)
# Convert from percentage (0-100) to proportion (0-1)
if ("PGRNT_P" %in% names(panel)) {
  panel[, pell_share := suppressWarnings(as.numeric(PGRNT_P)) / 100]
} else {
  panel[, pell_share := fifelse(SCUGRAD > 0, PGRNT_N / SCUGRAD, NA_real_)]
}

# Enrollment composition shares
panel[, black_share := fifelse(EFTOTLT > 0, EFBKAAT / EFTOTLT, NA_real_)]
panel[, hispanic_share := fifelse(EFTOTLT > 0, EFHISPT / EFTOTLT, NA_real_)]
panel[, white_share := fifelse(EFTOTLT > 0, EFWHITT / EFTOTLT, NA_real_)]
panel[, nonres_share := fifelse(EFTOTLT > 0, EFNRALT / EFTOTLT, NA_real_)]
panel[, minority_share := fifelse(EFTOTLT > 0,
                                  (fifelse(is.na(EFBKAAT), 0, EFBKAAT) +
                                   fifelse(is.na(EFHISPT), 0, EFHISPT)) / EFTOTLT,
                                  NA_real_)]

# Per-student state appropriations (using total enrollment as FTE proxy)
panel[, approp_per_student := fifelse(EFTOTLT > 0, state_approp / EFTOTLT, NA_real_)]

# Log versions
panel[, log_approp := log(pmax(state_approp, 1))]
panel[, log_tuition := log(pmax(tuition_instate, 1))]
panel[, log_enrollment := log(pmax(EFTOTLT, 1))]

# State identifiers
panel[, state := STABBR]
stopifnot(all(!is.na(panel$state)))

# ============================================================================
# 8. Construct Bartik instrument
# ============================================================================
cat("\n=== Constructing Bartik instrument ===\n")

# Component 1: Pre-period state HE budget share (2003-2005 average)
# = total state appropriations to HE / (proxy for total state budget)
# We approximate using cross-institution state totals from IPEDS

state_he_2003 <- panel[year %in% 2003:2005,
                       .(total_he_approp = sum(state_approp, na.rm = TRUE),
                         n_inst = .N),
                       by = state]

# Approximate state budget as total HE appropriations / national HE budget share
# (HE is typically 10-12% of state budgets)
# Better: use cross-state variation in total_he_approp as the "share" directly
# since we don't have total state budgets in IPEDS
# This is the "exposure" component of the Bartik instrument

# Normalize: state HE spending per institution (pre-period)
state_he_2003[, he_intensity := total_he_approp / n_inst]
state_he_2003[, he_share := he_intensity / mean(he_intensity, na.rm = TRUE)]
panel <- merge(panel, state_he_2003[, .(state, he_share)], by = "state", all.x = TRUE)

# Component 2: National fiscal shock (annual)
# Use year-over-year change in total national state HE appropriations
national_he <- panel[, .(national_approp = sum(state_approp, na.rm = TRUE)),
                     by = year]
national_he <- national_he[order(year)]
national_he[, national_shock := (national_approp - shift(national_approp, 1)) /
                                 shift(national_approp, 1)]

panel <- merge(panel, national_he[, .(year, national_shock)], by = "year", all.x = TRUE)

# Bartik instrument = pre-period HE share × national shock
panel[, bartik := he_share * national_shock]

# Also: state-level unemployment rate as alternative shock
# (loaded from FRED if available)
fred_gdp <- file.path(data_dir, "fred_gdp_growth.csv")
if (file.exists(fred_gdp)) {
  gdp <- fread(fred_gdp)
  # Negative GDP growth = fiscal shock
  gdp[, gdp_shock := -gdp_growth / 100]  # Invert: negative growth = positive shock
  panel <- merge(panel, gdp[, .(year, gdp_shock)], by = "year", all.x = TRUE)
  panel[, bartik_gdp := he_share * gdp_shock]
  cat("  GDP-based Bartik instrument constructed.\n")
}

# ============================================================================
# 9. Summary statistics and validation
# ============================================================================
cat("\n=== Panel summary ===\n")
cat("  Total obs:", nrow(panel), "\n")
cat("  Institutions:", uniqueN(panel$UNITID), "\n")
cat("  States:", uniqueN(panel$state), "\n")
cat("  Year range:", paste(range(panel$year), collapse = "-"), "\n")
cat("  Non-missing tuition:", sum(!is.na(panel$tuition_instate)), "\n")
cat("  Non-missing state approp:", sum(!is.na(panel$state_approp) & panel$state_approp > 0), "\n")
cat("  Non-missing Pell share:", sum(!is.na(panel$pell_share)), "\n")
cat("  Non-missing total enrollment:", sum(!is.na(panel$EFTOTLT) & panel$EFTOTLT > 0), "\n")
cat("  Non-missing Black share:", sum(!is.na(panel$black_share)), "\n")

# Key descriptive stats
cat("\n  Mean in-state tuition:", round(mean(panel$tuition_instate, na.rm=TRUE)), "\n")
cat("  Mean state approp per student:", round(mean(panel$approp_per_student, na.rm=TRUE)), "\n")
cat("  Mean Pell share:", round(mean(panel$pell_share, na.rm=TRUE), 3), "\n")
cat("  Mean total enrollment:", round(mean(panel$EFTOTLT, na.rm=TRUE)), "\n")

# Save panel
fwrite(panel, file.path(data_dir, "panel.csv"))
cat("\n  Panel saved to data/panel.csv\n")

# ============================================================================
# 10. Write diagnostics
# ============================================================================
# Count treated units (states with >20% approp decline 2007-2012)
state_change <- panel[year %in% c(2007, 2012),
                      .(approp = sum(state_approp, na.rm = TRUE)),
                      by = .(state, year)]
state_change <- dcast(state_change, state ~ year, value.var = "approp")
names(state_change) <- c("state", "approp_2007", "approp_2012")
state_change[, pct_change := (approp_2012 - approp_2007) / approp_2007]
n_treated_states <- sum(state_change$pct_change < -0.20, na.rm = TRUE)

# For IV design: all states are "treated" with continuous variation
# n_treated = number of state clusters
diag <- list(
  n_treated = uniqueN(panel$state),
  n_pre = length(2004:2007),
  n_obs = nrow(panel[!is.na(tuition_instate) & !is.na(state_approp)])
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\n  Diagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")
