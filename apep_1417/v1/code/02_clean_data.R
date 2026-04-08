## 02_clean_data.R — Clean and construct analysis panel
## apep_1417: Singapore ABSD and Housing Markets

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Property Price Index by Locality
# ============================================================
cat("=== Loading property price index ===\n")
ppi <- read_csv(file.path(data_dir, "ppi_locality.csv"), show_col_types = FALSE)
cat("  Rows:", nrow(ppi), "| Columns:", paste(names(ppi), collapse = ", "), "\n")
cat("  Segments:", paste(unique(ppi$market_segment), collapse = " | "), "\n")

# Parse quarter to date
ppi <- ppi |>
  mutate(
    year = as.integer(substr(quarter, 1, 4)),
    qtr = as.integer(substr(quarter, 7, 7)),
    date = as.Date(paste0(year, "-", (qtr - 1) * 3 + 1, "-01")),
    time_q = year + (qtr - 1) / 4,
    segment = case_when(
      grepl("Core", market_segment) ~ "CCR",
      grepl("Rest", market_segment) ~ "RCR",
      grepl("Outside", market_segment) ~ "OCR",
      TRUE ~ market_segment
    )
  )

cat("  Year range:", min(ppi$year), "-", max(ppi$year), "\n")
cat("  Quarters:", n_distinct(ppi$quarter), "\n")

# ============================================================
# 2. Rental Index by Locality
# ============================================================
cat("\n=== Loading rental index ===\n")
rental_raw <- read_csv(file.path(data_dir, "rental_index.csv"), show_col_types = FALSE)
cat("  Raw rows:", nrow(rental_raw), "\n")

# This is wide format: DataSeries, 20254Q, 20253Q, ...
# Pivot to long
rental <- rental_raw |>
  pivot_longer(-DataSeries, names_to = "qtr_code", values_to = "rental_index") |>
  mutate(
    rental_index = as.numeric(rental_index),
    year = as.integer(substr(qtr_code, 1, 4)),
    qtr = as.integer(substr(qtr_code, 5, 5)),
    date = as.Date(paste0(year, "-", (qtr - 1) * 3 + 1, "-01")),
    time_q = year + (qtr - 1) / 4,
    segment = case_when(
      grepl("Core", DataSeries) ~ "CCR",
      grepl("Rest", DataSeries) ~ "RCR",
      grepl("Outside", DataSeries) ~ "OCR",
      TRUE ~ "Other"
    )
  ) |>
  mutate(quarter = paste0(year, "-Q", qtr)) |>
  filter(segment %in% c("CCR", "RCR", "OCR"), !is.na(rental_index))

cat("  Clean rows:", nrow(rental), "\n")
cat("  Year range:", min(rental$year), "-", max(rental$year), "\n")

# ============================================================
# 3. Transaction Volumes
# ============================================================
cat("\n=== Loading transaction volumes ===\n")

load_transactions <- function(file, seg) {
  df <- read_csv(file, show_col_types = FALSE)
  df |>
    mutate(
      year = as.integer(substr(quarter, 1, 4)),
      qtr = as.integer(substr(quarter, 7, 7)),
      date = as.Date(paste0(year, "-", (qtr - 1) * 3 + 1, "-01")),
      time_q = year + (qtr - 1) / 4,
      segment = seg
    )
}

txn_ccr <- load_transactions(file.path(data_dir, "transactions_ccr.csv"), "CCR")
txn_ocr <- load_transactions(file.path(data_dir, "transactions_ocr.csv"), "OCR")

# Aggregate total units per quarter-segment
txn <- bind_rows(txn_ccr, txn_ocr) |>
  group_by(segment, quarter, year, qtr, date, time_q) |>
  summarise(total_units = sum(units, na.rm = TRUE), .groups = "drop")

cat("  CCR quarters:", n_distinct(txn_ccr$quarter), "| OCR quarters:", n_distinct(txn_ocr$quarter), "\n")

# ============================================================
# 4. HDB Resale (Placebo)
# ============================================================
cat("\n=== Loading HDB resale data ===\n")
hdb <- read_csv(file.path(data_dir, "hdb_resale.csv"), show_col_types = FALSE)
cat("  Rows:", nrow(hdb), "\n")

# Aggregate to quarterly mean price by town
hdb_q <- hdb |>
  mutate(
    year = as.integer(substr(month, 1, 4)),
    mo = as.integer(substr(month, 6, 7)),
    qtr = ceiling(mo / 3),
    quarter = paste0(year, "-Q", qtr),
    date = as.Date(paste0(year, "-", (qtr - 1) * 3 + 1, "-01")),
    time_q = year + (qtr - 1) / 4,
    resale_price = as.numeric(resale_price)
  ) |>
  group_by(town, quarter, year, qtr, date, time_q) |>
  summarise(
    mean_price = mean(resale_price, na.rm = TRUE),
    median_price = median(resale_price, na.rm = TRUE),
    n_txn = n(),
    .groups = "drop"
  )

cat("  Towns:", n_distinct(hdb_q$town), "| Quarters:", n_distinct(hdb_q$quarter), "\n")

# ============================================================
# 5. Build unified analysis panel
# ============================================================
cat("\n=== Building analysis panel ===\n")

# ABSD announcement dates and rates
absd_rounds <- tibble(
  round = 1:5,
  date_announced = as.Date(c("2011-12-08", "2013-01-12", "2018-07-06", "2021-12-16", "2023-04-27")),
  absd_rate = c(10, 15, 20, 30, 60),
  label = c("10% (Dec 2011)", "15% (Jan 2013)", "20% (Jul 2018)",
            "30% (Dec 2021)", "60% (Apr 2023)")
)

# Merge price and rental indices
panel <- ppi |>
  select(segment, quarter, year, qtr, date, time_q, price_index) |>
  left_join(
    rental |> select(segment, quarter, rental_index),
    by = c("segment", "quarter")
  ) |>
  left_join(
    txn |> select(segment, quarter, total_units),
    by = c("segment", "quarter")
  )

# Treatment indicators
# CCR = high foreign exposure (~16%), OCR = low (~3%), RCR = medium
panel <- panel |>
  mutate(
    treated = as.integer(segment == "CCR"),
    # Cumulative ABSD rate in effect
    absd_rate = case_when(
      date >= as.Date("2023-04-27") ~ 60,
      date >= as.Date("2021-12-16") ~ 30,
      date >= as.Date("2018-07-06") ~ 20,
      date >= as.Date("2013-01-12") ~ 15,
      date >= as.Date("2011-12-08") ~ 10,
      TRUE ~ 0
    ),
    post_any = as.integer(absd_rate > 0),
    # Individual round dummies
    post_r1 = as.integer(date >= as.Date("2011-12-08")),
    post_r2 = as.integer(date >= as.Date("2013-01-12")),
    post_r3 = as.integer(date >= as.Date("2018-07-06")),
    post_r4 = as.integer(date >= as.Date("2021-12-16")),
    post_r5 = as.integer(date >= as.Date("2023-04-27")),
    # Log transforms
    log_price = log(price_index),
    log_rental = log(rental_index),
    log_units = log(total_units + 1)
  )

# Segment as factor with OCR as reference
panel$segment_f <- factor(panel$segment, levels = c("OCR", "RCR", "CCR"))

# Numeric time index for event studies
panel$t <- as.integer(factor(panel$quarter))

cat("  Panel:", nrow(panel), "segment-quarters\n")
cat("  Segments:", paste(unique(panel$segment), collapse = ", "), "\n")
cat("  Year range:", min(panel$year), "-", max(panel$year), "\n")

# Save
write_csv(panel, file.path(data_dir, "analysis_panel.csv"))
write_csv(hdb_q, file.path(data_dir, "hdb_quarterly.csv"))
saveRDS(absd_rounds, file.path(data_dir, "absd_rounds.rds"))

cat("\n=== Panel construction complete ===\n")
