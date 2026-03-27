# 01_fetch_data.R — Fetch PAH water quality data from USGS
# APEP-1081: Coal Tar Sealant Bans and Waterway PAH Contamination
# Uses read_USGS_samples() (new USGS Water Data API)

source("00_packages.R")

# ── Coal-tar sealant ban dates ──
ban_dates <- tribble(
  ~jurisdiction, ~state_abbr, ~fips, ~ban_year, ~scope,
  "Washington DC",  "DC", "US:11", 2009L, "district",
  "Washington",     "WA", "US:53", 2011L, "state",
  "Minnesota",      "MN", "US:27", 2014L, "state",
  "New York",       "NY", "US:36", 2022L, "state",
  "Maryland",       "MD", "US:24", 2023L, "state",
  "Maine",          "ME", "US:23", 2024L, "state",
  "Virginia",       "VA", "US:51", 2025L, "state"
)

# Control states (never-treated) with FIPS codes
control_states <- tribble(
  ~state_abbr, ~fips,
  "OH", "US:39",
  "PA", "US:42",
  "WI", "US:55",
  "IA", "US:19",
  "MI", "US:26",
  "NJ", "US:34",
  "CT", "US:09",
  "NC", "US:37",
  "WV", "US:54",
  "OR", "US:41",
  "IL", "US:17",
  "IN", "US:18",
  "KY", "US:21",
  "TN", "US:47",
  "SC", "US:45",
  "GA", "US:13",
  "TX", "US:48",
  "CO", "US:08",
  "FL", "US:12",
  "MA", "US:25",
  "NH", "US:33",
  "VT", "US:50",
  "DE", "US:10",
  "RI", "US:44",
  "AL", "US:01",
  "MO", "US:29",
  "NE", "US:31",
  "KS", "US:20",
  "SD", "US:46",
  "ND", "US:38"
)

all_states <- bind_rows(
  ban_dates %>% select(state_abbr, fips),
  control_states
)

# ── Fetch function ──
fetch_usgs_pah <- function(fips_code, state_abbr, characteristic = "Fluoranthene") {
  cat(sprintf("  Fetching %s for %s (%s)...\n", characteristic, state_abbr, fips_code))
  tryCatch({
    result <- read_USGS_samples(
      stateFips = fips_code,
      characteristic = characteristic,
      activityMediaName = "Water",
      activityStartDateLower = "2000-01-01"
    )
    if (is.null(result) || nrow(result) == 0) {
      cat(sprintf("    No data for %s\n", state_abbr))
      return(NULL)
    }
    # Select only needed columns to avoid bind_rows type conflicts
    keep_cols <- c("Location_Identifier", "Location_Latitude", "Location_Longitude",
                   "Location_StatePostalCode", "Location_HUCEightDigitCode",
                   "Location_Type", "Activity_StartDate", "Activity_Media",
                   "Result_Measure", "Result_MeasureUnit",
                   "Result_ResultDetectionCondition",
                   "DetectionLimit_MeasureA", "Result_Characteristic")
    avail <- intersect(keep_cols, names(result))
    result <- result[, avail, drop = FALSE]
    # Coerce all to character for safe binding
    result <- result %>% mutate(across(everything(), as.character))
    result$state_abbr <- state_abbr
    cat(sprintf("    Got %d records\n", nrow(result)))
    result
  }, error = function(e) {
    cat(sprintf("    ERROR for %s: %s\n", state_abbr, e$message))
    return(NULL)
  })
}

# ── Fetch fluoranthene for all states ──
cat("Fetching fluoranthene data from USGS Water Data API...\n")
fluor_list <- list()
for (i in 1:nrow(all_states)) {
  st <- all_states$state_abbr[i]
  fp <- all_states$fips[i]
  res <- fetch_usgs_pah(fp, st, "Fluoranthene")
  if (!is.null(res) && nrow(res) > 0) {
    fluor_list[[st]] <- res
  }
  Sys.sleep(0.5)
}

if (length(fluor_list) == 0) {
  stop("FATAL: No fluoranthene data retrieved. Cannot proceed.")
}

fluor_raw <- bind_rows(fluor_list)
cat(sprintf("\nTotal fluoranthene records: %d from %d states\n",
            nrow(fluor_raw), length(fluor_list)))

# ── Fetch placebo: Lead ──
cat("\nFetching placebo contaminant: Lead...\n")
placebo_states <- c(ban_dates$state_abbr, "OH", "PA", "WI", "IA", "MI")
lead_list <- list()
for (st in placebo_states) {
  fp <- all_states$fips[all_states$state_abbr == st]
  res <- fetch_usgs_pah(fp, st, "Lead")
  if (!is.null(res) && nrow(res) > 0) {
    lead_list[[st]] <- res
  }
  Sys.sleep(0.5)
}
lead_raw <- if (length(lead_list) > 0) bind_rows(lead_list) else NULL
cat(sprintf("Lead records: %d\n", ifelse(is.null(lead_raw), 0, nrow(lead_raw))))

# ── Fetch placebo: Atrazine ──
cat("\nFetching placebo contaminant: Atrazine...\n")
atrazine_list <- list()
for (st in placebo_states) {
  fp <- all_states$fips[all_states$state_abbr == st]
  res <- fetch_usgs_pah(fp, st, "Atrazine")
  if (!is.null(res) && nrow(res) > 0) {
    atrazine_list[[st]] <- res
  }
  Sys.sleep(0.5)
}
atrazine_raw <- if (length(atrazine_list) > 0) bind_rows(atrazine_list) else NULL
cat(sprintf("Atrazine records: %d\n", ifelse(is.null(atrazine_raw), 0, nrow(atrazine_raw))))

# ── Fetch secondary PAH: Pyrene ──
cat("\nFetching secondary PAH: Pyrene...\n")
pyrene_list <- list()
for (st in placebo_states) {
  fp <- all_states$fips[all_states$state_abbr == st]
  res <- fetch_usgs_pah(fp, st, "Pyrene")
  if (!is.null(res) && nrow(res) > 0) {
    pyrene_list[[st]] <- res
  }
  Sys.sleep(0.5)
}
pyrene_raw <- if (length(pyrene_list) > 0) bind_rows(pyrene_list) else NULL
cat(sprintf("Pyrene records: %d\n", ifelse(is.null(pyrene_raw), 0, nrow(pyrene_raw))))

# ── Save raw data ──
saveRDS(fluor_raw, "../data/fluor_raw.rds")
saveRDS(ban_dates, "../data/ban_dates.rds")
if (!is.null(lead_raw)) saveRDS(lead_raw, "../data/lead_raw.rds")
if (!is.null(atrazine_raw)) saveRDS(atrazine_raw, "../data/atrazine_raw.rds")
if (!is.null(pyrene_raw)) saveRDS(pyrene_raw, "../data/pyrene_raw.rds")

cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("Fluoranthene: %d records across %d states\n",
            nrow(fluor_raw), n_distinct(fluor_raw$state_abbr)))
cat("States with data:\n")
fluor_raw %>%
  group_by(state_abbr) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n)) %>%
  print(n = 50)
