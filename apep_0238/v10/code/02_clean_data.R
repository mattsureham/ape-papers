# ── apep_0238 v10: Clean Data ──────────────────────────────────────────────
# Construct: state panel, exposure measures, Bartik instrument, EPOP

# Source packages - detect script dir robustly
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
if (length(.file_arg) > 0) {
  .script_dir <- dirname(normalizePath(sub("^--file=", "", .file_arg)))
} else {
  .script_dir <- getwd()
}
source(file.path(.script_dir, "00_packages.R"))
raw <- readRDS(file.path(DATA_DIR, "raw_data.rds"))

# ══════════════════════════════════════════════════════════════════════════
# 1. State-month panel
# ══════════════════════════════════════════════════════════════════════════

cat("Building state-month panel...\n")

panel <- raw$employment[, .(state, date, nonfarm_emp)]
panel <- merge(panel, raw$unemployment_rate[, .(state, date, ur)],
               by = c("state", "date"), all.x = TRUE)
panel <- merge(panel, raw$lfpr[, .(state, date, lfpr)],
               by = c("state", "date"), all.x = TRUE)

# Add population (annual, interpolate monthly)
if (!is.null(raw$population) && nrow(raw$population) > 0) {
  pop <- raw$population[, .(state, date, pop)]
  pop[, year := year(date)]
  panel[, year := year(date)]
  panel <- merge(panel, pop[, .(state, year, pop)], by = c("state", "year"), all.x = TRUE)
  # Forward-fill population within state
  setorder(panel, state, date)
  panel[, pop := nafill(pop, type = "locf"), by = state]
  panel[, year := NULL]
}

# Construct EPOP (nonfarm payrolls / population in thousands)
if ("pop" %in% names(panel)) {
  panel[, epop := nonfarm_emp / pop]
}

# Add civilian employment from LAUS if available
if (!is.null(raw$civilian_employment) && nrow(raw$civilian_employment) > 0) {
  panel <- merge(panel, raw$civilian_employment[, .(state, date, civ_emp)],
                 by = c("state", "date"), all.x = TRUE)
  if ("pop" %in% names(panel)) {
    panel[, civ_epop := civ_emp / pop]
  }
}

setorder(panel, state, date)
cat(sprintf("  Panel: %d state-months, %d states\n", nrow(panel), uniqueN(panel$state)))

# ══════════════════════════════════════════════════════════════════════════
# 2. Housing price boom instrument (Great Recession)
# ══════════════════════════════════════════════════════════════════════════

cat("Constructing HPI boom measure...\n")

hpi <- raw$hpi[, .(state, date, hpi)]
hpi[, year_q := paste0(year(date), "Q", quarter(date))]

# 2003Q1 and 2006Q4
hpi_2003q1 <- hpi[year_q == "2003Q1", .(state, hpi_start = hpi)]
hpi_2006q4 <- hpi[year_q == "2006Q4", .(state, hpi_end = hpi)]

hpi_boom <- merge(hpi_2003q1, hpi_2006q4, by = "state")
hpi_boom[, hpi_boom := log(hpi_end) - log(hpi_start)]
hpi_boom[, hpi_boom_sd := (hpi_boom - mean(hpi_boom)) / sd(hpi_boom)]

cat(sprintf("  HPI boom: mean=%.3f, sd=%.3f, range=[%.3f, %.3f]\n",
            mean(hpi_boom$hpi_boom), sd(hpi_boom$hpi_boom),
            min(hpi_boom$hpi_boom), max(hpi_boom$hpi_boom)))

# ══════════════════════════════════════════════════════════════════════════
# 3. Bartik instrument (COVID)
# ══════════════════════════════════════════════════════════════════════════

cat("Constructing COVID Bartik instrument...\n")

ind <- raw$industry
ind[, year := year(date)]
ind[, month := month(date)]

# Pre-pandemic industry shares (2019 annual average)
shares_2019 <- ind[year == 2019, .(share_emp = mean(ind_emp, na.rm = TRUE)),
                   by = .(state, industry)]
state_total_2019 <- shares_2019[, .(total = sum(share_emp)), by = state]
shares_2019 <- merge(shares_2019, state_total_2019, by = "state")
shares_2019[, omega := share_emp / total]

# National industry shock: Feb 2020 to Apr 2020 (leave-one-out)
feb2020 <- ind[year == 2020 & month == 2, .(state, industry, emp_feb = ind_emp)]
apr2020 <- ind[year == 2020 & month == 4, .(state, industry, emp_apr = ind_emp)]
nat_shock <- merge(feb2020, apr2020, by = c("state", "industry"))

# Leave-one-out national shock for each state
bartik_list <- list()
for (st in STATES) {
  other <- nat_shock[state != st]
  nat_chg <- other[, .(delta_nat = (sum(emp_apr) - sum(emp_feb)) / sum(emp_feb)),
                   by = industry]
  st_shares <- shares_2019[state == st, .(industry, omega)]
  merged <- merge(st_shares, nat_chg, by = "industry", all.x = TRUE)
  merged[is.na(delta_nat), delta_nat := 0]
  bartik_list[[st]] <- data.table(state = st, bartik_covid = sum(merged$omega * merged$delta_nat))
}
bartik_dt <- rbindlist(bartik_list)
bartik_dt[, bartik_covid_sd := (bartik_covid - mean(bartik_covid)) / sd(bartik_covid)]

cat(sprintf("  Bartik COVID: mean=%.4f, sd=%.4f\n",
            mean(bartik_dt$bartik_covid), sd(bartik_dt$bartik_covid)))

# ══════════════════════════════════════════════════════════════════════════
# 4. Exposure dataset (cross-section of 50 states)
# ══════════════════════════════════════════════════════════════════════════

cat("Building state exposure dataset...\n")

exposure <- merge(hpi_boom[, .(state, hpi_boom, hpi_boom_sd)],
                  bartik_dt[, .(state, bartik_covid, bartik_covid_sd)],
                  by = "state")

# Saiz elasticity (negated: higher = more supply-constrained)
exposure[, saiz := -SAIZ_ELASTICITY[state]]

# Pre-recession controls
# GR: pre-recession employment growth 2004-2007
panel[, log_emp := log(nonfarm_emp)]
gr_pre <- panel[date >= "2004-01-01" & date <= "2007-11-01"]
gr_growth <- gr_pre[, {
  if (.N >= 12) {
    growth <- (log_emp[.N] - log_emp[1]) / (.N / 12)
  } else {
    growth <- NA_real_
  }
  .(pre_growth_gr = growth, log_emp_peak_gr = log_emp[date == max(date)])
}, by = state]

# COVID: pre-recession employment growth 2017-2020
covid_pre <- panel[date >= "2017-01-01" & date <= "2020-01-01"]
covid_growth <- covid_pre[, {
  if (.N >= 12) {
    growth <- (log_emp[.N] - log_emp[1]) / (.N / 12)
  } else {
    growth <- NA_real_
  }
  .(pre_growth_covid = growth, log_emp_peak_covid = log_emp[date == max(date)])
}, by = state]

exposure <- merge(exposure, gr_growth, by = "state", all.x = TRUE)
exposure <- merge(exposure, covid_growth, by = "state", all.x = TRUE)

# Add region controls
exposure <- merge(exposure, STATE_REGION, by = "state")

# Additional controls for richer specification
# Construction share, manufacturing share, education share (2006 for GR, 2019 for COVID)
ind_shares_2006 <- ind[year == 2006, .(avg_emp = mean(ind_emp, na.rm = TRUE)),
                       by = .(state, industry)]
total_2006 <- ind_shares_2006[, .(total_2006 = sum(avg_emp)), by = state]
ind_shares_2006 <- merge(ind_shares_2006, total_2006, by = "state")
ind_shares_2006[, share := avg_emp / total_2006]

cons_share <- ind_shares_2006[industry == "CONS", .(state, cons_share_2006 = share)]
mfg_share <- ind_shares_2006[industry == "MFG", .(state, mfg_share_2006 = share)]

exposure <- merge(exposure, cons_share, by = "state", all.x = TRUE)
exposure <- merge(exposure, mfg_share, by = "state", all.x = TRUE)

cat(sprintf("  Exposure dataset: %d states\n", nrow(exposure)))

# ══════════════════════════════════════════════════════════════════════════
# 5. Outcome variables: log employment change at each horizon
# ══════════════════════════════════════════════════════════════════════════

cat("Computing employment outcomes by horizon...\n")

HORIZONS_GR <- c(0, 3, 6, 12, 24, 36, 48, 60, 84, 120)
HORIZONS_COVID <- c(0, 3, 6, 12, 24, 36, 48)

compute_outcomes <- function(panel, peak_date, horizons, prefix) {
  peak_emp <- panel[date == peak_date, .(state, emp_peak = nonfarm_emp)]
  if ("epop" %in% names(panel)) {
    peak_epop <- panel[date == peak_date, .(state, epop_peak = epop)]
    peak_emp <- merge(peak_emp, peak_epop, by = "state")
  }

  outcomes <- list()
  for (h in horizons) {
    target_date <- peak_date %m+% months(h)
    target <- panel[date == target_date, .(state, nonfarm_emp)]
    if ("epop" %in% names(panel)) {
      target_epop <- panel[date == target_date, .(state, epop)]
      target <- merge(target, target_epop, by = "state")
    }

    merged <- merge(peak_emp, target, by = "state", suffixes = c("_peak", ""))
    merged[, (paste0("d_log_emp_", h)) := log(nonfarm_emp) - log(emp_peak)]
    if ("epop_peak" %in% names(merged) && "epop" %in% names(merged)) {
      merged[, (paste0("d_epop_", h)) := epop - epop_peak]
    }
    outcomes[[as.character(h)]] <- merged[, c("state", grep("^d_", names(merged), value = TRUE)), with = FALSE]
  }

  result <- outcomes[[1]]
  for (i in 2:length(outcomes)) {
    result <- merge(result, outcomes[[i]], by = "state", all = TRUE)
  }
  result
}

# Need lubridate for %m+%
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate", repos = "https://cloud.r-project.org")
library(lubridate)

gr_outcomes <- compute_outcomes(panel, GR_PEAK, HORIZONS_GR, "gr")
covid_outcomes <- compute_outcomes(panel, COVID_PEAK, HORIZONS_COVID, "covid")

# ── Single estimand: average EPOP months 48-120 ──
cat("Computing single estimand (avg EPOP 48-120)...\n")

compute_avg_outcome <- function(panel, peak_date, h_start, h_end, step = 3) {
  horizons <- seq(h_start, h_end, by = step)
  peak_emp <- panel[date == peak_date, .(state, emp_peak = nonfarm_emp)]
  if ("epop" %in% names(panel)) {
    peak_epop <- panel[date == peak_date, .(state, epop_peak = epop)]
    peak_emp <- merge(peak_emp, peak_epop, by = "state")
  }

  all_outcomes <- list()
  for (h in horizons) {
    target_date <- peak_date %m+% months(h)
    target <- panel[date == target_date]
    if (nrow(target) == 0) next
    target <- target[, .(state, nonfarm_emp, epop)]
    merged <- merge(peak_emp, target, by = "state", suffixes = c("_peak", ""))
    merged[, d_log_emp := log(nonfarm_emp) - log(emp_peak)]
    if ("epop_peak" %in% names(merged)) {
      merged[, d_epop := epop - epop_peak]
    }
    all_outcomes[[as.character(h)]] <- merged[, .(state, d_log_emp, d_epop)]
  }

  if (length(all_outcomes) == 0) return(NULL)

  stacked <- rbindlist(all_outcomes, idcol = "horizon")
  avg <- stacked[, .(avg_d_log_emp = mean(d_log_emp, na.rm = TRUE),
                     avg_d_epop = mean(d_epop, na.rm = TRUE)),
                 by = state]
  avg
}

gr_avg <- compute_avg_outcome(panel, GR_PEAK, 48, 120)
covid_avg <- compute_avg_outcome(panel, COVID_PEAK, 24, 48)  # Shorter window for COVID

# ══════════════════════════════════════════════════════════════════════════
# 6. Merge everything and save
# ══════════════════════════════════════════════════════════════════════════

cat("Merging datasets...\n")

# Merge exposure with GR outcomes
analysis_gr <- merge(exposure, gr_outcomes, by = "state")
if (!is.null(gr_avg)) {
  analysis_gr <- merge(analysis_gr, gr_avg, by = "state")
}

# Merge exposure with COVID outcomes
analysis_covid <- merge(exposure, covid_outcomes, by = "state")
if (!is.null(covid_avg)) {
  analysis_covid <- merge(analysis_covid, covid_avg, by = "state")
}

# Save
saveRDS(list(
  panel = panel,
  exposure = exposure,
  analysis_gr = analysis_gr,
  analysis_covid = analysis_covid,
  gr_outcomes = gr_outcomes,
  covid_outcomes = covid_outcomes,
  gr_avg = gr_avg,
  covid_avg = covid_avg
), file.path(DATA_DIR, "analysis_data.rds"))

# Also save state panel as CSV for reference
fwrite(panel, file.path(DATA_DIR, "state_panel.csv"))
fwrite(exposure, file.path(DATA_DIR, "state_exposure.csv"))

cat(sprintf("Analysis data saved. GR: %d states, COVID: %d states\n",
            nrow(analysis_gr), nrow(analysis_covid)))
cat("Data cleaning complete.\n")
