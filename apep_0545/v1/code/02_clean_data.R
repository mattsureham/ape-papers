## 02_clean_data.R
## Data cleaning and panel construction for regulatory ratchet analysis
## Merges: Federal Register outcomes + GDELT coverage + competing-news IV

library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

# Set working directory to the project root directory (papers/apep_XXXX/vN/)
if (interactive() && requireNamespace("rstudioapi", quietly=TRUE) && rstudioapi::isAvailable()) {
  setwd(normalizePath(file.path(dirname(rstudioapi::getActiveDocumentContext()$path), "..")))
}
# Command-line: run from the project root directory (papers/apep_XXXX/vN/), e.g., Rscript code/02_clean_data.R
source("code/00_packages.R")

DATA_DIR <- "data/"

# ============================================================
# LOAD DATA
# ============================================================

fr_data        <- fread(file.path(DATA_DIR, "fr_agency_quarter.csv"))
gdelt_data     <- fread(file.path(DATA_DIR, "gdelt_agency_quarter.csv"))
competing_data <- fread(file.path(DATA_DIR, "gdelt_competing_news.csv"))

cat("FR data: ", nrow(fr_data), "rows\n")
cat("GDELT data: ", nrow(gdelt_data), "rows\n")
cat("Competing news: ", nrow(competing_data), "rows\n")

# ============================================================
# AGENCY METADATA
# ============================================================

# Agency characteristics for heterogeneity analysis
agency_meta <- data.table(
  agency_id = c("EPA","OSHA","FDA","NHTSA","FAA","FRA","MSHA","CPSC","FMCSA","PHMSA","NRC","CFTC"),
  sector    = c("environment","occupational_safety","food_drug","auto_safety",
                "aviation","railroad","mining","consumer_products","trucking",
                "pipeline","nuclear","financial_derivatives"),
  # High-salience agencies (public perceives incidents as newsworthy)
  high_salience = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE),
  # Staffing level proxy (2020 FTE, approximate from USASpending/OMB)
  staff_fte_2020 = c(14172, 2113, 17468, 600, 9900, 770, 2400, 540, 1100, 600, 3200, 870),
  # Whether agency underwent major reorganization in study period
  major_reorg = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
)

# ============================================================
# MERGE DATASETS
# ============================================================

# Merge FR + GDELT
panel <- merge(fr_data, gdelt_data, by=c("agency_id", "year", "quarter"), all.x=TRUE)

# Merge in competing news IV (quarter-level)
panel <- merge(panel, competing_data[, .(year, quarter,
                                          total_gkg_volume = total_articles,
                                          competing_news_vol,
                                          competing_news_share,
                                          election_coverage,
                                          natural_disaster_coverage,
                                          sports_coverage,
                                          conflict_coverage)],
               by=c("year", "quarter"), all.x=TRUE)

# Merge agency metadata
panel <- merge(panel, agency_meta, by="agency_id", all.x=TRUE)

# ============================================================
# VARIABLE CONSTRUCTION
# ============================================================

# Time variable
panel[, `:=`(
  time_id = (year - 2015) * 4 + quarter,  # 1 to 40
  agency_quarter_id = paste0(agency_id, "_", year, "Q", quarter)
)]

# OUTCOME VARIABLES
panel[, `:=`(
  # Log-transformed outcomes (add 1 to handle zeros)
  log_n_significant   = log(n_significant + 1),
  log_n_final         = log(n_final_rule + 1),
  log_n_proposed      = log(n_proposed_rule + 1),
  log_n_total         = log(n_total + 1),

  # Normalized by agency baseline (within-agency deviation)
  sig_per_quarter     = n_significant  # primary level outcome
)]

# TREATMENT VARIABLE: Incident coverage
# Log of agency-specific safety incident articles in that quarter
panel[, `:=`(
  log_incident_coverage    = log(incident_articles + 1),
  log_burden_coverage      = log(burden_articles + 1),
  log_burden_neg_coverage  = log(burden_neg_tone_articles + 1),
  # Share of total GKG: controls for overall news growth
  incident_share           = incident_articles / pmax(total_articles, 1),
  burden_share             = burden_articles / pmax(total_articles, 1)
)]

# INSTRUMENT: Competing news (quarter-level, log-transformed)
panel[, `:=`(
  log_competing_news  = log(competing_news_vol + 1),
  log_competing_share = log(competing_news_share * 100 + 0.001),  # share * 100 so log is interpretable
  # Natural disasters only (most exogenous component)
  log_nat_disaster    = log(natural_disaster_coverage + 1),
  # Election coverage (pre-scheduled, exogenous to rulemaking calendar)
  log_elections       = log(election_coverage + 1)
)]

# ADMINISTRATION INDICATORS
panel[, `:=`(
  # Trump EO 13771 ("2-for-1") was signed January 30, 2017
  trump_eo = as.integer(year >= 2017 & !(year == 2017 & quarter == 1)),
  trump_era = as.integer(year %in% 2017:2020),
  biden_era = as.integer(year %in% 2021:2024),
  # Q-specific dummies for seasonal patterns in rulemaking
  q1 = as.integer(quarter == 1),
  q2 = as.integer(quarter == 2),
  q3 = as.integer(quarter == 3),
  q4 = as.integer(quarter == 4)
)]

# LAGGED VARIABLES
setorder(panel, agency_id, year, quarter)

# Create 1-quarter, 2-quarter, 3-quarter lags of incident and burden coverage
panel[, `:=`(
  log_incident_L1 = shift(log_incident_coverage, 1, type="lag"),
  log_incident_L2 = shift(log_incident_coverage, 2, type="lag"),
  log_incident_L3 = shift(log_incident_coverage, 3, type="lag"),
  log_incident_L4 = shift(log_incident_coverage, 4, type="lag"),
  log_burden_L1   = shift(log_burden_coverage, 1, type="lag"),
  log_burden_L2   = shift(log_burden_coverage, 2, type="lag"),
  log_burden_L3   = shift(log_burden_coverage, 3, type="lag"),
  log_competing_L1 = shift(log_competing_news, 1, type="lag")
), by = agency_id]

# ============================================================
# AGENCY FIXED EFFECTS ENCODING
# ============================================================
panel[, agency_fe := as.factor(agency_id)]
panel[, quarter_fe := as.factor(paste(year, quarter, sep="Q"))]
panel[, year_fe := as.factor(year)]

# ============================================================
# SUMMARY STATISTICS FOR SANITY CHECK
# ============================================================
cat("\n=== PANEL SUMMARY ===\n")
cat("Observations: ", nrow(panel), "\n")
cat("Agencies: ", n_distinct(panel$agency_id), "\n")
cat("Year range: ", min(panel$year), "-", max(panel$year), "\n")
cat("Quarters: ", n_distinct(panel$quarter_fe), "\n")

cat("\nOutcome variable (n_significant by agency, mean):\n")
print(panel[, .(mean_sig=mean(n_significant, na.rm=TRUE),
                sd_sig=sd(n_significant, na.rm=TRUE),
                min_sig=min(n_significant, na.rm=TRUE),
                max_sig=max(n_significant, na.rm=TRUE)),
            by=agency_id][order(-mean_sig)])

cat("\nTreatment variable (log_incident_coverage by agency, mean):\n")
print(panel[, .(mean_inc=mean(log_incident_coverage, na.rm=TRUE),
                sd_inc=sd(log_incident_coverage, na.rm=TRUE)),
            by=agency_id][order(-mean_inc)])

cat("\nCompeting news IV (by year, mean):\n")
print(panel[, .(mean_comp=mean(log_competing_news, na.rm=TRUE)), by=year][order(year)])

cat("\nCorrelation matrix (outcome ~ treatment ~ IV):\n")
cor_vars <- c("log_n_significant", "log_incident_coverage", "log_burden_coverage",
              "log_competing_news", "log_nat_disaster", "log_elections")
cor_data <- panel[, ..cor_vars]
print(round(cor(cor_data, use="complete.obs"), 3))

# ============================================================
# SAVE CLEAN PANEL
# ============================================================
fwrite(panel, file.path(DATA_DIR, "panel_clean.csv"))
cat("\nClean panel saved: ", nrow(panel), "rows\n")

# Summary statistics table for paper
sumstats_vars <- c("n_significant", "n_final_rule", "n_proposed_rule",
                   "incident_articles", "burden_articles", "burden_neg_tone_articles",
                   "competing_news_vol", "total_gkg_volume")

sumstats <- panel[, lapply(.SD, function(x) list(
  N=sum(!is.na(x)), mean=mean(x, na.rm=TRUE), sd=sd(x, na.rm=TRUE),
  min=min(x, na.rm=TRUE), median=median(x, na.rm=TRUE), max=max(x, na.rm=TRUE)
)), .SDcols=sumstats_vars]

# Reshape for table
sumstats_long <- data.table(
  variable = sumstats_vars,
  N    = sapply(sumstats_vars, function(v) sum(!is.na(panel[[v]]))),
  mean = sapply(sumstats_vars, function(v) mean(panel[[v]], na.rm=TRUE)),
  sd   = sapply(sumstats_vars, function(v) sd(panel[[v]], na.rm=TRUE)),
  min  = sapply(sumstats_vars, function(v) min(panel[[v]], na.rm=TRUE)),
  median = sapply(sumstats_vars, function(v) median(panel[[v]], na.rm=TRUE)),
  max  = sapply(sumstats_vars, function(v) max(panel[[v]], na.rm=TRUE))
)

fwrite(sumstats_long, file.path(DATA_DIR, "summary_stats.csv"))
cat("Summary stats saved.\n")

message("02_clean_data.R complete.")
