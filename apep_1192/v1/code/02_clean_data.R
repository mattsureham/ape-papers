# 02_clean_data.R — Parse and clean NHTSA flat files, construct analysis dataset
# apep_1192: Defect Queue Congestion

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Parse Investigations
# ============================================================
cat("Parsing investigations...\n")
inv_file <- list.files(file.path(data_dir, "investigations_raw"),
                       pattern = "\\.txt$", full.names = TRUE)[1]

inv_raw <- fread(inv_file, header = FALSE, sep = "\t", quote = "",
                 fill = TRUE, encoding = "Latin-1",
                 col.names = c("action_number", "make", "model", "year",
                               "compname", "mfr_name", "odate", "cdate",
                               "campno", "subject", "summary"))

cat(sprintf("  Raw investigation rows: %s\n", format(nrow(inv_raw), big.mark = ",")))

# Extract investigation type from action number prefix
inv_raw[, inv_type := str_extract(action_number, "^[A-Z]+")]
inv_raw[, `:=`(open_date = ymd(odate), close_date = ymd(cdate))]

# Keep PE and EA investigations
inv_pe_ea <- inv_raw[inv_type %in% c("PE", "EA")]

# Collapse to investigation level
inv <- inv_pe_ea[, .(
  inv_type = first(inv_type),
  open_date = first(open_date),
  close_date = first(close_date),
  campno = first(campno[campno != ""]),
  mfr_name = first(mfr_name),
  compname = first(compname),
  subject = first(subject),
  n_models = .N
), by = action_number]

# Standardize manufacturer names
inv[, mfr_clean := toupper(trimws(mfr_name))]
mfr_map <- list(
  "FORD" = "^FORD",
  "GENERAL MOTORS" = "^GENERAL MOTORS|^GM|^CHEVROLET|^BUICK|^CADILLAC|^GMC",
  "CHRYSLER/STELLANTIS" = "^CHRYSLER|^DODGE|^JEEP|^RAM|^FCA|^STELLANTIS",
  "TOYOTA" = "^TOYOTA|^LEXUS",
  "HONDA" = "^HONDA|^ACURA",
  "NISSAN" = "^NISSAN|^INFINITI|^DATSUN",
  "HYUNDAI/KIA" = "^HYUNDAI|^KIA",
  "BMW" = "^BMW|^MINI",
  "MERCEDES-BENZ" = "^MERCEDES|^DAIMLER",
  "VW GROUP" = "^VOLKSWAGEN|^VW|^AUDI|^PORSCHE",
  "SUBARU" = "^SUBARU|^FUJI",
  "TESLA" = "^TESLA",
  "VOLVO" = "^VOLVO",
  "MAZDA" = "^MAZDA"
)
for (nm in names(mfr_map)) {
  inv[grepl(mfr_map[[nm]], mfr_clean), mfr_clean := nm]
}

# Standardize component categories
inv[, comp_cat := fcase(
  grepl("AIR BAG", compname, ignore.case = TRUE), "AIR BAGS",
  grepl("BRAKE|BRAKING", compname, ignore.case = TRUE), "BRAKES",
  grepl("STEER", compname, ignore.case = TRUE), "STEERING",
  grepl("ENGINE|POWERTRAIN", compname, ignore.case = TRUE), "ENGINE/POWERTRAIN",
  grepl("FUEL", compname, ignore.case = TRUE), "FUEL SYSTEM",
  grepl("TIRE|WHEEL", compname, ignore.case = TRUE), "TIRES/WHEELS",
  grepl("ELECTR|WIRING|BATTERY", compname, ignore.case = TRUE), "ELECTRICAL",
  grepl("LIGHT|LAMP", compname, ignore.case = TRUE), "LIGHTING",
  grepl("SEAT|RESTRAINT|BELT", compname, ignore.case = TRUE), "SEATS/RESTRAINTS",
  grepl("SUSPEN", compname, ignore.case = TRUE), "SUSPENSION",
  grepl("STRUCT|BODY|DOOR|HOOD|TRUNK|LATCH", compname, ignore.case = TRUE), "STRUCTURE/BODY",
  grepl("VISIB|WINDSHIELD|WIPER|MIRROR|GLASS", compname, ignore.case = TRUE), "VISIBILITY",
  grepl("SPEED|CRUISE|ACCEL|THROTTLE", compname, ignore.case = TRUE), "SPEED CONTROL",
  default = "OTHER"
)]

inv <- inv[!is.na(open_date)]
cat(sprintf("  Unique PE/EA investigations: %s\n", format(nrow(inv), big.mark = ",")))

inv[, duration_days := as.numeric(difftime(close_date, open_date, units = "days"))]
inv[is.na(close_date), duration_days := as.numeric(difftime(Sys.Date(), open_date, units = "days"))]
inv[, open_yq := paste0(year(open_date), "Q", quarter(open_date))]
inv[, open_year := year(open_date)]
inv[, has_recall := (campno != "" & !is.na(campno))]
cat(sprintf("  With linked recalls: %s (%.1f%%)\n", sum(inv$has_recall), 100 * mean(inv$has_recall)))

# ============================================================
# 2. Compute Concurrent Open Investigations (the instrument)
# ============================================================
cat("Computing concurrent investigation counts...\n")

inv[is.na(close_date), close_date_use := Sys.Date()]
inv[!is.na(close_date), close_date_use := close_date]

# Vectorized interval overlap using data.table's non-equi join
# For each investigation i, count others whose [open_date, close_date] contains i's open_date
inv_for_join <- inv[, .(action_number, open_date, close_date_use, mfr_clean, comp_cat)]

# Self-join: for each investigation, find all others open on its opening date
setkey(inv_for_join, open_date, close_date_use)

n <- nrow(inv_for_join)
concurrent_all <- integer(n)
concurrent_other_mfr <- integer(n)

# Use a fast approach: sort by open_date, track open/close events
cat("  Using event-sweep approach...\n")
events <- rbindlist(list(
  inv_for_join[, .(action_number, date = open_date, event = 1L, mfr_clean, comp_cat)],
  inv_for_join[, .(action_number, date = close_date_use, event = -1L, mfr_clean, comp_cat)]
))
setorder(events, date, event)

# For each investigation, count open investigations on its open date
# Faster: for each inv, binary search the sorted open/close dates
od_vec <- inv_for_join$open_date
cd_vec <- inv_for_join$close_date_use
mfr_vec <- inv_for_join$mfr_clean

for (i in seq_len(n)) {
  d <- od_vec[i]
  # Investigations open on date d: open_date <= d & close_date_use >= d
  mask <- od_vec <= d & cd_vec >= d
  mask[i] <- FALSE  # exclude self
  concurrent_all[i] <- sum(mask)
  concurrent_other_mfr[i] <- sum(mask & mfr_vec != mfr_vec[i])
}

inv[, concurrent_all := concurrent_all]
inv[, concurrent_other_mfr := concurrent_other_mfr]

cat(sprintf("  Concurrent (all): mean=%.1f, sd=%.1f, min=%d, max=%d\n",
            mean(inv$concurrent_all), sd(inv$concurrent_all),
            min(inv$concurrent_all), max(inv$concurrent_all)))
cat(sprintf("  Concurrent (excl own mfr): mean=%.1f, sd=%.1f\n",
            mean(inv$concurrent_other_mfr), sd(inv$concurrent_other_mfr)))

# ============================================================
# 3. Parse Complaints — aggregate to manufacturer-month level (FAST)
# ============================================================
cat("Parsing complaints...\n")
comp_file <- list.files(file.path(data_dir, "complaints_raw"),
                        pattern = "\\.txt$", full.names = TRUE)[1]

comp_raw <- fread(comp_file, header = FALSE, sep = "\t", quote = "",
                  fill = TRUE, encoding = "Latin-1", select = 1:11,
                  col.names = c("cmplid", "odino", "mfr_name", "maketxt",
                                "modeltxt", "yeartxt", "crash", "faildate",
                                "fire", "injured", "deaths"))

cat(sprintf("  Raw complaint rows: %s\n", format(nrow(comp_raw), big.mark = ",")))

comp_raw[, `:=`(
  received_date = ymd(faildate),
  is_crash = (crash == "Y"),
  is_fire = (fire == "Y"),
  n_injured = pmax(as.numeric(injured), 0, na.rm = TRUE),
  n_deaths = pmax(as.numeric(deaths), 0, na.rm = TRUE)
)]

# Map complaint makes to standardized manufacturer
comp_raw[, make_clean := toupper(trimws(maketxt))]
comp_raw[, mfr_std := make_clean]  # default
for (nm in names(mfr_map)) {
  comp_raw[grepl(mfr_map[[nm]], make_clean), mfr_std := nm]
}

# Aggregate to manufacturer-month
comp_raw[, ym := floor_date(received_date, "month")]
comp_mfr_month <- comp_raw[!is.na(ym), .(
  n_complaints = .N,
  n_crashes = sum(is_crash),
  n_injuries = sum(n_injured),
  n_deaths = sum(n_deaths),
  n_fires = sum(is_fire)
), by = .(mfr_std, ym)]

cat(sprintf("  Manufacturer-month obs: %s\n", format(nrow(comp_mfr_month), big.mark = ",")))

# For each investigation, look up complaints in its manufacturer during and pre-period
cat("Linking complaints to investigations...\n")
inv[, open_month := floor_date(open_date, "month")]
inv[, close_month := floor_date(fifelse(is.na(close_date), Sys.Date(), close_date), "month")]

# Pre-period: 12 months before investigation opened
inv[, pre_start := open_month - months(12)]

# Merge: during-period complaints
inv[, comp_during := 0L]
inv[, crashes_during := 0L]
inv[, injuries_during := 0L]
inv[, deaths_during := 0L]
inv[, comp_pre := 0L]
inv[, severity_pre := 0]

for (i in seq_len(nrow(inv))) {
  mfr_i <- inv$mfr_clean[i]
  om <- inv$open_month[i]
  cm <- inv$close_month[i]
  ps <- inv$pre_start[i]

  # During period
  sub_d <- comp_mfr_month[mfr_std == mfr_i & ym >= om & ym <= cm]
  if (nrow(sub_d) > 0) {
    set(inv, i, "comp_during", sum(sub_d$n_complaints))
    set(inv, i, "crashes_during", sum(sub_d$n_crashes))
    set(inv, i, "injuries_during", sum(sub_d$n_injuries))
    set(inv, i, "deaths_during", sum(sub_d$n_deaths))
  }

  # Pre-period
  sub_p <- comp_mfr_month[mfr_std == mfr_i & ym >= ps & ym < om]
  if (nrow(sub_p) > 0) {
    set(inv, i, "comp_pre", sum(sub_p$n_complaints))
    set(inv, i, "severity_pre",
        sum(sub_p$n_crashes) + 3 * sum(sub_p$n_injuries) + 10 * sum(sub_p$n_deaths))
  }
}
cat("  Complaint linkage complete.\n")

# ============================================================
# 4. Parse Recalls and link
# ============================================================
cat("Parsing recalls...\n")
rec_files <- list.files(file.path(data_dir, "recalls_raw"),
                        pattern = "\\.txt$", full.names = TRUE)

rec_list <- lapply(rec_files, function(f) {
  fread(f, header = FALSE, sep = "\t", quote = "", fill = TRUE,
        encoding = "Latin-1", select = 1:16,
        col.names = c("campno", "maketxt", "modeltxt", "yeartxt",
                       "mfgcampno", "compname", "mfgname",
                       "bgman", "endman", "rcltypecd", "potaff",
                       "odate", "cdate", "influenced_by", "mfgtxt", "rcdate"))
})
rec_raw <- rbindlist(rec_list, fill = TRUE)

rec_raw[, `:=`(recall_date = ymd(rcdate), units_affected = as.numeric(potaff))]

rec <- rec_raw[, .(
  recall_date = first(recall_date[!is.na(recall_date)]),
  units_affected = sum(units_affected, na.rm = TRUE),
  influenced_by = first(influenced_by),
  n_models = .N
), by = campno]

cat(sprintf("  Unique recall campaigns: %s\n", format(nrow(rec), big.mark = ",")))

# Ensure campno types match for merge
inv[, campno := as.character(campno)]
rec[, campno := as.character(campno)]
inv <- merge(inv, rec[, .(campno, recall_date, units_affected,
                           recall_influenced_by = influenced_by)],
             by = "campno", all.x = TRUE)

inv[has_recall == TRUE, days_to_recall := as.numeric(
  difftime(recall_date, open_date, units = "days"))]

# ============================================================
# 5. Final sample and save
# ============================================================
cat("Applying sample restrictions...\n")
inv <- inv[open_year >= 2000 & open_year <= 2024]
cat(sprintf("  After year restriction (2000-2024): %s\n", format(nrow(inv), big.mark = ",")))

inv_closed <- inv[!is.na(close_date)]
cat(sprintf("  Closed investigations: %s\n", format(nrow(inv_closed), big.mark = ",")))

inv_closed[, log_duration := log(duration_days + 1)]

# Manufacturer size proxy
mfr_size <- inv_closed[, .(mfr_inv_count = .N), by = mfr_clean]
inv_closed <- merge(inv_closed, mfr_size, by = "mfr_clean", all.x = TRUE)

# Save
fwrite(inv_closed, file.path(data_dir, "analysis_investigations.csv"))
fwrite(inv, file.path(data_dir, "all_investigations.csv"))

# Summary
cat("\n=== Analysis Dataset Summary ===\n")
cat(sprintf("  Observations: %s\n", format(nrow(inv_closed), big.mark = ",")))
cat(sprintf("  PE: %s | EA: %s\n", sum(inv_closed$inv_type == "PE"),
            sum(inv_closed$inv_type == "EA")))
cat(sprintf("  With recall: %s (%.1f%%)\n",
            sum(inv_closed$has_recall), 100 * mean(inv_closed$has_recall)))
cat(sprintf("  Duration (days): mean=%.0f, median=%.0f, sd=%.0f\n",
            mean(inv_closed$duration_days), median(inv_closed$duration_days),
            sd(inv_closed$duration_days)))
cat(sprintf("  Concurrent (all): mean=%.1f, sd=%.1f, [%d, %d]\n",
            mean(inv_closed$concurrent_all), sd(inv_closed$concurrent_all),
            min(inv_closed$concurrent_all), max(inv_closed$concurrent_all)))
cat(sprintf("  Concurrent (excl mfr): mean=%.1f, sd=%.1f\n",
            mean(inv_closed$concurrent_other_mfr), sd(inv_closed$concurrent_other_mfr)))
cat(sprintf("  Manufacturers: %d | Components: %d\n",
            uniqueN(inv_closed$mfr_clean), uniqueN(inv_closed$comp_cat)))
cat(sprintf("  Year range: %d-%d\n", min(inv_closed$open_year), max(inv_closed$open_year)))
cat(sprintf("  Injuries during inv: mean=%.1f, total=%d\n",
            mean(inv_closed$injuries_during), sum(inv_closed$injuries_during)))
cat(sprintf("  Deaths during inv: mean=%.2f, total=%d\n",
            mean(inv_closed$deaths_during), sum(inv_closed$deaths_during)))

cat("\nData cleaning complete.\n")
