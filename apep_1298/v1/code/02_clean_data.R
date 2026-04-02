# ==============================================================================
# 02_clean_data.R — Construct analysis dataset
# ==============================================================================

source("00_packages.R")

# --- Load raw data ---
qwi_total <- readRDS("../data/qwi_total.rds")
qwi_sector <- readRDS("../data/qwi_sector.rds")
qcew_2012 <- readRDS("../data/qcew_2012.rds")
qcew_2010 <- readRDS("../data/qcew_2010.rds")
pop_df <- readRDS("../data/pop_df.rds")

# --- Construct federal employment share (treatment intensity) ---
# QCEW uses 5-character FIPS, QWI uses numeric FIPS
qcew_2012[, fips := as.character(area_fips)]
qcew_2012[, fed_share := ifelse(total_emp > 0, fed_emp / total_emp, 0)]

qcew_2010[, fips := as.character(area_fips)]
qcew_2010[, fed_share_2010 := ifelse(total_emp > 0, fed_emp / total_emp, 0)]

# --- Clean QWI data ---
qwi <- as.data.table(qwi_total)
qwi[, fips := sprintf("%05d", as.integer(geography))]
qwi[, yearqtr := year + (quarter - 1) / 4]
qwi[, time_id := (year - 2010) * 4 + quarter]  # sequential quarter index

# --- Merge treatment exposure ---
qwi <- merge(qwi, qcew_2012[, .(fips, fed_share, fed_emp, total_emp)],
             by = "fips", all.x = TRUE)
qwi <- merge(qwi, qcew_2010[, .(fips, fed_share_2010)],
             by = "fips", all.x = TRUE)
qwi <- merge(qwi, pop_df, by = "fips", all.x = TRUE)

# Drop counties with missing exposure
qwi <- qwi[!is.na(fed_share) & !is.na(population)]

# --- Define shutdown quarters ---
# 2013 Q4: Oct 1-16 shutdown (16 days)
# 2019 Q1: Dec 22 2018 - Jan 25 2019 (35 days, mostly in Q1 2019)
qwi[, shutdown_2013 := as.integer(year == 2013 & quarter == 4)]
qwi[, shutdown_2019 := as.integer(year == 2019 & quarter == 1)]
qwi[, shutdown := as.integer(shutdown_2013 == 1 | shutdown_2019 == 1)]

# Interaction: treatment intensity × shutdown
qwi[, treat_shutdown := fed_share * shutdown]
qwi[, treat_shutdown_2013 := fed_share * shutdown_2013]
qwi[, treat_shutdown_2019 := fed_share * shutdown_2019]

# --- Create event-time variables for each shutdown ---
# 2013Q4 event: event_time centered at 2013Q4
qwi[, event_time_2013 := time_id - ((2013 - 2010) * 4 + 4)]
# 2019Q1 event: event_time centered at 2019Q1
qwi[, event_time_2019 := time_id - ((2019 - 2010) * 4 + 1)]

# --- Log outcomes (handle zeros) ---
qwi[, ln_emp := log(private_emp + 1)]
qwi[, emp_pc := private_emp / (population / 1000)]  # per 1,000 pop

# --- High vs low federal share categories ---
qwi[, fed_share_cat := fifelse(fed_share >= quantile(fed_share, 0.75, na.rm = TRUE),
                                "High (Q4)", "Low (Q1-Q3)")]

# --- Sector-level data ---
qwi_sec <- as.data.table(qwi_sector)
qwi_sec[, fips := sprintf("%05d", as.integer(geography))]
qwi_sec[, yearqtr := year + (quarter - 1) / 4]
qwi_sec[, time_id := (year - 2010) * 4 + quarter]
qwi_sec <- merge(qwi_sec, qcew_2012[, .(fips, fed_share, fed_emp, total_emp)],
                 by = "fips", all.x = TRUE)
qwi_sec <- qwi_sec[!is.na(fed_share)]
qwi_sec[, shutdown := as.integer((year == 2013 & quarter == 4) | (year == 2019 & quarter == 1))]
qwi_sec[, treat_shutdown := fed_share * shutdown]

# Sector labels
sector_labs <- c("72" = "Accommodation & Food",
                 "44-45" = "Retail Trade",
                 "31-33" = "Manufacturing",
                 "62" = "Healthcare")
qwi_sec[, sector_label := sector_labs[industry]]

# --- Summary statistics ---
cat("\n=== Dataset Summary ===\n")
cat(sprintf("Counties: %d\n", uniqueN(qwi$fips)))
cat(sprintf("Quarters: %d (%d to %d)\n", uniqueN(qwi$time_id), min(qwi$year), max(qwi$year)))
cat(sprintf("Total obs: %s\n", format(nrow(qwi), big.mark = ",")))
cat(sprintf("Federal share: mean=%.3f, sd=%.3f, p25=%.3f, p75=%.3f\n",
            mean(qwi[quarter == 1 & year == 2012]$fed_share),
            sd(qwi[quarter == 1 & year == 2012]$fed_share),
            quantile(qwi[quarter == 1 & year == 2012]$fed_share, 0.25),
            quantile(qwi[quarter == 1 & year == 2012]$fed_share, 0.75)))
cat(sprintf("Mean private emp: %s\n", format(round(mean(qwi$private_emp, na.rm = TRUE)), big.mark = ",")))

# --- Save analysis dataset ---
saveRDS(qwi, "../data/analysis_total.rds")
saveRDS(qwi_sec, "../data/analysis_sector.rds")
cat("Analysis datasets saved.\n")
