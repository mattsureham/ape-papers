# 01_fetch_data.R — Fetch JEPX spot price data and reactor restart timeline
library(data.table)
library(readr)
library(lubridate)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
setwd(dirname(script_dir))  # Set to v1/ directory
if (!dir.exists("data")) dir.create("data")

# ─── 1. JEPX Spot Prices ───────────────────────────────────────────────────
cat("Fetching JEPX spot price data...\n")
jepx_url <- "https://japanesepower.org/jepxSpot.csv"
jepx_file <- "data/jepx_spot.csv"

download.file(jepx_url, jepx_file, mode = "wb", quiet = FALSE)
stopifnot("JEPX download failed" = file.exists(jepx_file) && file.size(jepx_file) > 1e5)

jepx <- fread(jepx_file)
cat(sprintf("JEPX raw: %d rows, %d columns\n", nrow(jepx), ncol(jepx)))
cat(sprintf("Columns: %s\n", paste(names(jepx), collapse = ", ")))
cat(sprintf("Date range: %s to %s\n", min(jepx[[1]]), max(jepx[[1]])))

# Validate: expect 200K+ rows and 10+ regions
stopifnot("JEPX data too small" = nrow(jepx) > 100000)

saveRDS(jepx, "data/jepx_raw.rds")
cat("JEPX data saved.\n")

# ─── 2. Reactor Restart Timeline ───────────────────────────────────────────
# Source: NRA public records, compiled from JAIF and World Nuclear Association
# 14 reactors restarted across 5 regions, 2015-2024
restart_data <- data.table(
  reactor = c(
    "Sendai 1", "Sendai 2",                    # Kyushu
    "Takahama 3", "Takahama 4", "Ohi 3", "Ohi 4", "Mihama 3",  # Kansai
    "Ikata 3",                                   # Shikoku
    "Genkai 3", "Genkai 4",                      # Kyushu
    "Tokai 2",                                   # (not restarted yet — reference)
    "Onagawa 2",                                 # Tohoku
    "Shimane 2",                                 # Chugoku
    "Takahama 1", "Takahama 2"                   # Kansai
  ),
  region = c(
    "Kyushu", "Kyushu",
    "Kansai", "Kansai", "Kansai", "Kansai", "Kansai",
    "Shikoku",
    "Kyushu", "Kyushu",
    NA,          # Tokai 2 not yet restarted
    "Tohoku",
    "Chugoku",
    "Kansai", "Kansai"
  ),
  restart_date = as.Date(c(
    "2015-08-11", "2015-10-15",
    "2016-01-29", "2016-02-26", "2018-03-14", "2018-05-09", "2021-06-23",
    "2016-08-12",
    "2018-03-23", "2018-06-16",
    NA,
    "2024-10-29",
    "2024-12-07",
    "2023-07-28", "2023-09-15"
  )),
  capacity_mw = c(
    890, 890,
    870, 870, 1180, 1180, 826,
    890,
    1180, 1180,
    1100,
    825,
    820,
    826, 826
  )
)

# Remove reactors not yet restarted
restart_data <- restart_data[!is.na(restart_date)]
cat(sprintf("Reactor restart timeline: %d reactors in %d regions\n",
            nrow(restart_data), uniqueN(restart_data$region)))

# First restart per region (treatment onset)
first_restart <- restart_data[, .(
  first_restart_date = min(restart_date),
  first_reactor = reactor[which.min(restart_date)],
  total_capacity_mw = sum(capacity_mw),
  n_reactors = .N
), by = region]

cat("\nFirst restart by region:\n")
print(first_restart[order(first_restart_date)])

saveRDS(restart_data, "data/restart_timeline.rds")
saveRDS(first_restart, "data/first_restart.rds")

# ─── 3. Region mapping ────────────────────────────────────────────────────
# Japan's 10 electricity regions and their Hz frequency
regions <- data.table(
  region = c("Hokkaido", "Tohoku", "Tokyo", "Chubu", "Hokuriku",
             "Kansai", "Chugoku", "Shikoku", "Kyushu", "Okinawa"),
  frequency_hz = c(50, 50, 50, 60, 60, 60, 60, 60, 60, 60),
  grid = c("East", "East", "East", "West", "West",
           "West", "West", "West", "West", "West")
)

# Merge treatment info
regions <- merge(regions, first_restart[, .(region, first_restart_date, n_reactors)],
                 by = "region", all.x = TRUE)
regions[, treated := !is.na(first_restart_date)]

cat("\nRegion treatment status:\n")
print(regions[order(frequency_hz, region)])

saveRDS(regions, "data/regions.rds")
cat("\nAll data fetched and saved.\n")
