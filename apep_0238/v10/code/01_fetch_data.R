# ── apep_0238 v10: Fetch Data ──────────────────────────────────────────────
# Sources: FRED (state employment, UR, LFPR, HPI, industry shares, JOLTS)
#          BLS (unemployment by duration — published tables)
#          CPS via IPUMS (temp layoff share, U→E flows)

# Source packages - detect script dir robustly
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
if (length(.file_arg) > 0) {
  .script_dir <- dirname(normalizePath(sub("^--file=", "", .file_arg)))
} else {
  .script_dir <- getwd()
}
source(file.path(.script_dir, "00_packages.R"))

# ══════════════════════════════════════════════════════════════════════════
# 1. FRED: State-level labor market data
# ══════════════════════════════════════════════════════════════════════════

cat("Fetching FRED data...\n")

fetch_fred_series <- function(series_id, start = "2000-01-01", end = "2024-06-01") {
  tryCatch({
    d <- fredr(series_id = series_id, observation_start = as.Date(start),
               observation_end = as.Date(end))
    data.table(date = d$date, value = d$value)
  }, error = function(e) {
    warning(sprintf("Failed to fetch %s: %s", series_id, e$message))
    NULL
  })
}

# ── 1a. Nonfarm payrolls ──
cat("  Nonfarm payrolls...")
emp_list <- lapply(STATES, function(st) {
  d <- fetch_fred_series(paste0(st, "NA"))
  if (!is.null(d)) d[, state := st]
  d
})
emp_dt <- rbindlist(emp_list[!sapply(emp_list, is.null)])
setnames(emp_dt, "value", "nonfarm_emp")
cat(sprintf(" %d states\n", uniqueN(emp_dt$state)))

# ── 1b. Unemployment rate ──
cat("  Unemployment rates...")
ur_list <- lapply(STATES, function(st) {
  d <- fetch_fred_series(paste0(st, "UR"))
  if (!is.null(d)) d[, state := st]
  d
})
ur_dt <- rbindlist(ur_list[!sapply(ur_list, is.null)])
setnames(ur_dt, "value", "ur")
cat(sprintf(" %d states\n", uniqueN(ur_dt$state)))

# ── 1c. Labor force participation rate ──
cat("  LFPR...")
lfpr_list <- lapply(STATES, function(st) {
  fips <- STATE_FIPS[st]
  d <- fetch_fred_series(paste0("LBSSA", fips))
  if (!is.null(d)) d[, state := st]
  d
})
lfpr_dt <- rbindlist(lfpr_list[!sapply(lfpr_list, is.null)])
setnames(lfpr_dt, "value", "lfpr")
cat(sprintf(" %d states\n", uniqueN(lfpr_dt$state)))

# ── 1d. House price index (FHFA) ──
cat("  House price indices...")
hpi_list <- lapply(STATES, function(st) {
  d <- fetch_fred_series(paste0(st, "STHPI"))
  if (!is.null(d)) d[, state := st]
  d
})
hpi_dt <- rbindlist(hpi_list[!sapply(hpi_list, is.null)])
setnames(hpi_dt, "value", "hpi")
cat(sprintf(" %d states\n", uniqueN(hpi_dt$state)))

# ── 1e. State population ──
cat("  Population...")
pop_list <- lapply(STATES, function(st) {
  d <- fetch_fred_series(paste0(st, "POP"), start = "2000-01-01")
  if (!is.null(d)) d[, state := st]
  d
})
pop_dt <- rbindlist(pop_list[!sapply(pop_list, is.null)])
setnames(pop_dt, "value", "pop")
cat(sprintf(" %d states\n", uniqueN(pop_dt$state)))

# ── 1f. Industry employment (for Bartik construction) ──
cat("  Industry employment...")
INDUSTRIES <- c("MFG", "CONS", "FIRE", "LEIH", "EDUH", "GOVT", "PROF", "INFO", "TRAD", "MINE")
IND_CODES <- c(MFG = "MFGN", CONS = "CONSN", FIRE = "FIREN", LEIH = "LEIHN",
               EDUH = "EDUHN", GOVT = "GOVTN", PROF = "PBSVN", INFO = "INFON",
               TRAD = "TRADN", MINE = "MINEN")

ind_list <- list()
for (st in STATES) {
  for (ind in names(IND_CODES)) {
    sid <- paste0(st, IND_CODES[ind])
    d <- fetch_fred_series(sid)
    if (!is.null(d)) {
      d[, `:=`(state = st, industry = ind)]
      ind_list[[paste0(st, "_", ind)]] <- d
    }
  }
}
ind_dt <- rbindlist(ind_list)
setnames(ind_dt, "value", "ind_emp")
cat(sprintf(" %d state-industry pairs\n", uniqueN(paste(ind_dt$state, ind_dt$industry))))

# ── 1g. National JOLTS ──
cat("  JOLTS national data...")
jolts_series <- c(openings = "JTSJOL", hires = "JTSTSL", quits = "JTSQUL",
                  layoffs = "JTSLDL", separations = "JTSSRL")
jolts_list <- lapply(names(jolts_series), function(nm) {
  d <- fetch_fred_series(jolts_series[nm], start = "2000-12-01")
  if (!is.null(d)) d[, series := nm]
  d
})
jolts_dt <- rbindlist(jolts_list[!sapply(jolts_list, is.null)])
setnames(jolts_dt, "value", "rate")
cat(" done\n")

# ══════════════════════════════════════════════════════════════════════════
# 2. BLS: Unemployment by duration (published tables)
# ══════════════════════════════════════════════════════════════════════════

cat("Fetching BLS unemployment duration data...\n")

# BLS publishes state-level unemployment by duration via LAUS
# Series IDs: LAUST{FIPS}0000000000{dur_code}
# Duration codes: 03 = <5wk, 04 = 5-14wk, 05 = 15-26wk, 06 = 27+wk, 07 = total
fetch_bls_duration <- function(fips, dur_code, start = "2000-01-01") {
  # BLS LAUS series: state unemployment by duration
  # Try FRED first (some are available)
  sid <- paste0("LAUST", fips, "00000000000", dur_code)
  tryCatch({
    d <- fredr(series_id = sid, observation_start = as.Date(start),
               observation_end = as.Date("2024-06-01"))
    if (nrow(d) > 0) return(data.table(date = d$date, value = d$value))
    NULL
  }, error = function(e) NULL)
}

dur_list <- list()
for (st in STATES) {
  fips <- STATE_FIPS[st]
  # 27+ weeks unemployed
  d27 <- fetch_bls_duration(fips, "06")
  # Total unemployed
  dtot <- fetch_bls_duration(fips, "07")
  if (!is.null(d27) && !is.null(dtot)) {
    merged <- merge(d27, dtot, by = "date", suffixes = c("_27plus", "_total"))
    merged[, `:=`(state = st, ltu_share = value_27plus / value_total)]
    dur_list[[st]] <- merged
  }
}

if (length(dur_list) > 0) {
  dur_dt <- rbindlist(dur_list)
  cat(sprintf("  BLS duration data: %d states with LTU share\n", uniqueN(dur_dt$state)))
} else {
  cat("  BLS duration series not available via FRED. Will construct from CPS.\n")
  dur_dt <- NULL
}

# ══════════════════════════════════════════════════════════════════════════
# 3. CPS mechanism variables
# ══════════════════════════════════════════════════════════════════════════

# CPS Basic Monthly provides: reason for unemployment (temp layoff vs permanent),
# unemployment duration, and (via matched panels) U→E transitions.
#
# Strategy: Use BLS published tables for aggregate LTU share + temp layoff share.
# These are available from FRED at the national level and from BLS LAUS at state level.
# For state-level temp layoff share, we construct from CPS microdata via IPUMS
# if BLS published tables are insufficient.

cat("Fetching CPS-derived mechanism variables...\n")

# ── 3a. National temporary layoff share (from FRED) ──
temp_layoff_nat <- fetch_fred_series("LNS13023653")  # Temp layoff level
unemp_nat <- fetch_fred_series("UNEMPLOY")  # Total unemployed
if (!is.null(temp_layoff_nat) && !is.null(unemp_nat)) {
  temp_nat <- merge(temp_layoff_nat, unemp_nat, by = "date", suffixes = c("_temp", "_total"))
  temp_nat[, temp_layoff_share := value_temp / value_total]
  cat("  National temp layoff share: available\n")
} else {
  temp_nat <- NULL
  cat("  National temp layoff share: not available\n")
}

# ── 3b. National LTU share (27+ weeks / total, from FRED) ──
ltu_nat_27 <- fetch_fred_series("UEMP27OV")  # 27+ weeks
unemp_nat_tot <- fetch_fred_series("UNEMPLOY")
if (!is.null(ltu_nat_27) && !is.null(unemp_nat_tot)) {
  ltu_nat <- merge(ltu_nat_27, unemp_nat_tot, by = "date", suffixes = c("_27", "_total"))
  ltu_nat[, ltu_share := value_27 / value_total]
  cat("  National LTU share: available\n")
} else {
  ltu_nat <- NULL
}

# ── 3c. State-level: prime-age EPOP ──
# BLS LAUS provides civilian employment and population by state
# Prime-age (25-54) EPOP requires CPS or ACS; BLS publishes total EPOP
cat("  State EPOP ratios...")
epop_list <- lapply(STATES, function(st) {
  fips <- STATE_FIPS[st]
  # Employment-to-population ratio from LAUS
  d <- fetch_fred_series(paste0("LBSSA", fips))  # This is LFPR, not EPOP
  # For EPOP, we need employment / civilian noninstitutional population
  # FRED: {ST}EPOP doesn't exist uniformly. Use emp/pop ratio.
  NULL
})

# Construct EPOP from nonfarm payrolls / population (approximate)
# Better: use LAUS civilian employment. FRED series: {ST}E for employment level
cat(" constructing from LAUS...\n")
civ_emp_list <- lapply(STATES, function(st) {
  fips <- STATE_FIPS[st]
  d <- fetch_fred_series(paste0("LAUST", fips, "0000000000005"))  # Employment level
  if (!is.null(d)) d[, state := st]
  d
})
civ_emp_dt <- rbindlist(civ_emp_list[!sapply(civ_emp_list, is.null)])
if (nrow(civ_emp_dt) > 0) {
  setnames(civ_emp_dt, "value", "civ_emp")
  cat(sprintf("  Civilian employment: %d states\n", uniqueN(civ_emp_dt$state)))
} else {
  cat("  Civilian employment LAUS series not found. Using nonfarm payrolls.\n")
  civ_emp_dt <- NULL
}

# ══════════════════════════════════════════════════════════════════════════
# 4. Save all raw data
# ══════════════════════════════════════════════════════════════════════════

cat("Saving raw data...\n")
raw_data <- list(
  employment = emp_dt,
  unemployment_rate = ur_dt,
  lfpr = lfpr_dt,
  hpi = hpi_dt,
  population = pop_dt,
  industry = ind_dt,
  jolts = jolts_dt,
  ltu_duration = dur_dt,
  temp_layoff_national = temp_nat,
  ltu_national = ltu_nat,
  civilian_employment = civ_emp_dt
)
saveRDS(raw_data, file.path(DATA_DIR, "raw_data.rds"))
cat(sprintf("Saved to %s\n", file.path(DATA_DIR, "raw_data.rds")))
cat("Data fetch complete.\n")
