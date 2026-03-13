## 01_fetch_data.R — Download CMS Hospital Compare data from NBER archive
## apep_0630: Surprise Billing Laws and ED Quality

library(data.table)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "."
setwd(file.path(script_dir, ".."))
dir.create("data", showWarnings = FALSE)

# ---- NBER Archive file map ----
# Different naming conventions across years
tec_files <- list(
  list(year = 2014, sub = "7", file = "hqi_hosp_timelyeffectivecare.csv", fmt = "old"),
  list(year = 2015, sub = "4", file = "hqi_hosp_timelyeffectivecare.csv", fmt = "old"),
  list(year = 2016, sub = "10", file = "hqi_hosp_timelyeffectivecare.csv", fmt = "old"),
  list(year = 2017, sub = "4", file = "timely_and_effective_care_hospital.csv", fmt = "new"),
  list(year = 2018, sub = "7", file = "timely_and_effective_care_hospital.csv", fmt = "new"),
  list(year = 2019, sub = "7", file = "timely_and_effective_care_hospital.csv", fmt = "new")
)

hosp_files <- list(
  list(year = 2014, sub = "7", file = "hqi_hosp.csv", fmt = "old"),
  list(year = 2015, sub = "4", file = "hqi_hosp.csv", fmt = "old"),
  list(year = 2016, sub = "10", file = "hqi_hosp.csv", fmt = "old"),
  list(year = 2017, sub = "4", file = "hospital_general_information.csv", fmt = "new"),
  list(year = 2018, sub = "7", file = "hospital_general_information.csv", fmt = "new"),
  list(year = 2019, sub = "7", file = "hospital_general_information.csv", fmt = "new")
)

base_url <- "https://data.nber.org/compare/hospital"

# ---- Download timely effective care data ----
cat("Downloading Timely and Effective Care data...\n")
tec_all <- list()

for (info in tec_files) {
  url <- sprintf("%s/%d/%s/%s", base_url, info$year, info$sub, info$file)
  local <- sprintf("data/tec_%d.csv", info$year)

  if (!file.exists(local) || file.size(local) < 100) {
    cat(sprintf("  Downloading %d...\n", info$year))
    system2("curl", c("-s", "-L", "-o", local, "--max-time", "120", url))
    if (!file.exists(local) || file.size(local) < 100) {
      stop(sprintf("Failed to download %s", url))
    }
  }

  dt <- fread(local, na.strings = c("Not Available", "Not Applicable", "nan", ""))

  if (info$fmt == "old") {
    # Old format: providerid, hospname, condition, msr_cd, measureid, measurename, score, ...
    # No state column — extract from providerid or merge later
    setnames(dt, tolower(names(dt)))
    dt <- dt[, .(
      provider_id = providerid,
      measure_id = measureid,
      score = as.numeric(score),
      sample = as.numeric(sample),
      start_date = measurestartdatestr,
      end_date = measureenddatestr,
      release_year = info$year
    )]
  } else {
    # New format: provider_id, hospital_name, ..., state, ..., measure_id, score, ...
    setnames(dt, tolower(gsub("[^a-zA-Z0-9]", "_", names(dt))))
    dt <- dt[, .(
      provider_id = provider_id,
      state = state,
      measure_id = measure_id,
      score = as.numeric(score),
      sample = as.numeric(sample),
      start_date = measure_start_date,
      end_date = measure_end_date,
      release_year = info$year
    )]
  }

  # Keep only ED measures
  dt <- dt[measure_id %in% c("OP_18b", "OP_22", "OP_18a", "OP_18c", "OP_20", "OP_21")]
  tec_all[[as.character(info$year)]] <- dt
  cat(sprintf("  %d: %d rows for ED measures\n", info$year, nrow(dt)))
}

tec <- rbindlist(tec_all, fill = TRUE)
stopifnot("No timely/effective care data" = nrow(tec) > 0)
cat(sprintf("Total ED measure observations: %d\n", nrow(tec)))

# ---- Download hospital general information ----
cat("\nDownloading Hospital General Information...\n")
hosp_all <- list()

for (info in hosp_files) {
  url <- sprintf("%s/%d/%s/%s", base_url, info$year, info$sub, info$file)
  local <- sprintf("data/hosp_%d.csv", info$year)

  if (!file.exists(local) || file.size(local) < 100) {
    cat(sprintf("  Downloading %d...\n", info$year))
    system2("curl", c("-s", "-L", "-o", local, "--max-time", "120", url))
    if (!file.exists(local) || file.size(local) < 100) {
      stop(sprintf("Failed to download %s", url))
    }
  }

  dt <- fread(local, na.strings = c("Not Available", "Not Applicable", "nan", ""))
  setnames(dt, tolower(gsub("[^a-zA-Z0-9]", "_", names(dt))))

  if (info$fmt == "old") {
    dt <- dt[, .(
      provider_id = providerid,
      state = state,
      hospital_type = hospitaltype,
      ownership = hospitalownership,
      emergency = emergencyservices,
      release_year = info$year
    )]
  } else {
    dt <- dt[, .(
      provider_id = provider_id,
      state = state,
      hospital_type = hospital_type,
      ownership = hospital_ownership,
      emergency = emergency_services,
      release_year = info$year
    )]
  }

  hosp_all[[as.character(info$year)]] <- dt
  cat(sprintf("  %d: %d hospitals\n", info$year, nrow(dt)))
}

hosp <- rbindlist(hosp_all, fill = TRUE)
stopifnot("No hospital info data" = nrow(hosp) > 0)

# ---- Merge state info into older TEC records ----
# For 2014-2016 releases, state is missing from TEC. Merge from hospital info.
tec_need_state <- tec[is.na(state)]
tec_have_state <- tec[!is.na(state)]

if (nrow(tec_need_state) > 0) {
  cat(sprintf("\nMerging state for %d records from hospital info...\n", nrow(tec_need_state)))
  tec_need_state[, state := NULL]
  hosp_state <- unique(hosp[, .(provider_id, state, release_year)])
  tec_need_state <- merge(tec_need_state, hosp_state,
                          by = c("provider_id", "release_year"), all.x = TRUE)
  tec <- rbind(tec_have_state, tec_need_state, fill = TRUE)
}

# Drop records still missing state
n_before <- nrow(tec)
tec <- tec[!is.na(state)]
cat(sprintf("Dropped %d records with missing state\n", n_before - nrow(tec)))

# ---- Save ----
fwrite(tec, "data/ed_measures_panel.csv")
fwrite(hosp, "data/hospital_info.csv")

cat(sprintf("\nFinal ED measures panel: %d rows\n", nrow(tec)))
cat(sprintf("Hospital info: %d rows\n", nrow(hosp)))
cat(sprintf("States: %d\n", uniqueN(tec$state)))
cat(sprintf("Hospitals: %d\n", uniqueN(tec$provider_id)))
cat(sprintf("Release years: %s\n", paste(sort(unique(tec$release_year)), collapse = ", ")))
cat(sprintf("Measures: %s\n", paste(sort(unique(tec$measure_id)), collapse = ", ")))
