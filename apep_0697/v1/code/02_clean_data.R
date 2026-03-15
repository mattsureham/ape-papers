## 02_clean_data.R — apep_0697
## Clean and construct panels from Stats NZ Property Transfer Statistics

source("00_packages.R")

data_dir <- "../data"
hist_dir <- "../data/historical_releases"
if (!dir.exists(hist_dir)) hist_dir <- "historical_releases"

# ============================================================
# 1. Extract QUARTERLY data from quarterly-format releases
# ============================================================
# These releases (Mar 2018 - Mar 2020) have Table 2 with quarterly breakdowns
quarterly_releases <- c(
  "march-2018.xlsx",
  "september-2018.xlsx",
  "december-2018.xlsx",
  "march-2019.xlsx",
  "june-2019.xlsx",
  "september-2019.xlsx",
  "december-2019.xlsx",
  "march-2020.xlsx"
)

parse_quarterly_table2 <- function(filepath) {
  t2 <- read_excel(filepath, sheet = "Table 2")

  # Row 5 has the year labels, Row 6 has quarter labels
  year_row <- as.character(unlist(t2[5, ]))
  qtr_row <- as.character(unlist(t2[6, ]))

  # Build quarter dates from years and quarters
  # Fill forward years (years appear once then NA for subsequent quarters)
  current_year <- NA
  periods_buyer <- list()
  periods_seller <- list()

  # Determine which columns are buyers (left) and sellers (right)
  # Row 3 has "Buyers(6)" and "Sellers(7)" labels
  row3 <- as.character(unlist(t2[3, ]))
  buyer_start <- which(grepl("Buyer", row3, ignore.case = TRUE))[1]
  seller_start <- which(grepl("Seller", row3, ignore.case = TRUE))[1]

  # Parse column dates
  parse_periods <- function(start_col, end_col) {
    periods <- list()
    cur_year <- NA
    for (j in start_col:end_col) {
      yr <- year_row[j]
      qt <- qtr_row[j]
      if (!is.na(yr) && yr != "NA") cur_year <- as.integer(yr)
      if (is.na(qt) || qt == "NA" || is.na(cur_year)) next
      # Map month names to quarter numbers
      q_num <- switch(qt,
        "Mar" = 1, "Jun" = 2, "Sep" = 3, "Dec" = 4,
        NA)
      if (!is.na(q_num)) {
        periods[[length(periods) + 1]] <- list(col = j, year = cur_year, quarter = q_num)
      }
    }
    periods
  }

  buyer_periods <- parse_periods(buyer_start, seller_start - 1)
  seller_periods <- parse_periods(seller_start, ncol(t2))

  # Find data rows: between "Number" header row and the percentage section
  # Number rows start at row 7 (or 8), end before "Percentage" row
  n_rows <- nrow(t2)
  data_start <- NA
  data_end_num <- NA
  data_start_pct <- NA
  data_end_pct <- NA

  for (i in 1:n_rows) {
    val <- as.character(t2[i, 1])
    if (!is.na(val) && grepl("^Number", val)) data_start <- i + 1
    if (!is.na(val) && grepl("^Percentage", val)) {
      data_end_num <- i - 1
      data_start_pct <- i + 1
    }
    if (!is.na(val) && grepl("^1[.]", val) && !is.na(data_start_pct)) {
      data_end_pct <- i - 1
      break
    }
  }

  if (is.na(data_start) || is.na(data_end_num)) {
    cat("  Could not find data boundaries in", basename(filepath), "\n")
    return(NULL)
  }

  # Also find the series ref row (skip it)
  results <- list()

  for (i in data_start:data_end_num) {
    area <- as.character(t2[i, 1])
    if (is.na(area) || grepl("^Series ref", area)) next

    # Extract buyer counts for each quarter
    for (p in buyer_periods) {
      val <- as.character(t2[i, p$col])
      count <- suppressWarnings(as.numeric(val))
      if (val == "C") count <- NA_real_  # Confidential

      results[[length(results) + 1]] <- tibble(
        area = area,
        year = p$year,
        quarter = p$quarter,
        foreign_buyer_count = count,
        confidential = (val == "C")
      )
    }
  }

  # Also extract percentages
  pct_results <- list()
  if (!is.na(data_start_pct) && !is.na(data_end_pct)) {
    for (i in data_start_pct:data_end_pct) {
      area <- as.character(t2[i, 1])
      if (is.na(area) || grepl("^Series ref", area)) next

      for (p in buyer_periods) {
        val <- as.character(t2[i, p$col])
        pct <- suppressWarnings(as.numeric(val))
        if (val == "C") pct <- NA_real_

        pct_results[[length(pct_results) + 1]] <- tibble(
          area = area,
          year = p$year,
          quarter = p$quarter,
          foreign_buyer_pct = pct
        )
      }
    }
  }

  counts_df <- bind_rows(results)
  pcts_df <- bind_rows(pct_results)

  if (nrow(pcts_df) > 0) {
    out <- counts_df %>%
      left_join(pcts_df, by = c("area", "year", "quarter"))
  } else {
    out <- counts_df %>% mutate(foreign_buyer_pct = NA_real_)
  }

  out %>%
    mutate(
      date = as.Date(sprintf("%d-%02d-01", year, quarter * 3)),
      source_file = basename(filepath)
    )
}

cat("Parsing quarterly releases...\n")
quarterly_data <- map_dfr(quarterly_releases, function(fname) {
  fpath <- file.path(hist_dir, fname)
  if (!file.exists(fpath)) {
    cat("  Missing:", fname, "\n")
    return(NULL)
  }
  cat("  Processing:", fname, "...")
  d <- parse_quarterly_table2(fpath)
  if (!is.null(d)) cat(sprintf(" %d area-quarter obs\n", nrow(d)))
  d
})

# Deduplicate: when same area-quarter appears in multiple releases,
# prefer the most recent release (later data may be revised)
quarterly_panel <- quarterly_data %>%
  group_by(area, year, quarter) %>%
  slice_tail(n = 1) %>%  # Latest file wins
  ungroup()

cat(sprintf("\nQuarterly panel: %d area-quarter observations\n", nrow(quarterly_panel)))
cat(sprintf("  Areas: %d\n", n_distinct(quarterly_panel$area)))
cat(sprintf("  Quarters: %s to %s\n",
            min(quarterly_panel$date), max(quarterly_panel$date)))

# ============================================================
# 2. Extract ANNUAL data from annual-format releases
# ============================================================
# Use the Dec 2020 release (has years 2016-2020) for pre-ban annual data
# and the Jun 2024 release for the full 2020-2024 period

parse_annual_table2 <- function(filepath) {
  t2 <- read_excel(filepath, sheet = "Table 2")

  # Row 5 has year labels
  year_row <- as.character(unlist(t2[5, ]))
  row3 <- as.character(unlist(t2[3, ]))

  buyer_start <- which(grepl("Buyer", row3, ignore.case = TRUE))[1]
  seller_start <- which(grepl("Seller", row3, ignore.case = TRUE))[1]

  # Extract years for buyer columns
  buyer_years <- list()
  for (j in buyer_start:(seller_start - 1)) {
    yr <- suppressWarnings(as.integer(year_row[j]))
    if (!is.na(yr)) {
      buyer_years[[length(buyer_years) + 1]] <- list(col = j, year = yr)
    }
  }

  # Find data rows
  n_rows <- nrow(t2)
  data_start <- NA
  data_end_num <- NA
  data_start_pct <- NA
  data_end_pct <- NA

  for (i in 1:n_rows) {
    val <- as.character(t2[i, 1])
    if (!is.na(val) && grepl("^Number", val)) data_start <- i + 1
    if (!is.na(val) && grepl("^Percentage", val)) {
      data_end_num <- i - 1
      data_start_pct <- i + 1
    }
    if (!is.na(val) && grepl("^1[.]", val) && !is.na(data_start_pct)) {
      data_end_pct <- i - 1
      break
    }
  }

  if (is.na(data_start) || is.na(data_end_num)) return(NULL)

  results <- list()
  for (i in data_start:data_end_num) {
    area <- as.character(t2[i, 1])
    if (is.na(area) || grepl("^Series ref", area)) next

    for (p in buyer_years) {
      val <- as.character(t2[i, p$col])
      count <- suppressWarnings(as.numeric(val))
      if (!is.na(val) && val == "C") count <- NA_real_

      results[[length(results) + 1]] <- tibble(
        area = area,
        year = p$year,
        foreign_buyer_count = count,
        confidential = (!is.na(val) && val == "C")
      )
    }
  }

  # Percentages
  pct_results <- list()
  if (!is.na(data_start_pct) && !is.na(data_end_pct)) {
    for (i in data_start_pct:data_end_pct) {
      area <- as.character(t2[i, 1])
      if (is.na(area) || grepl("^Series ref", area)) next

      for (p in buyer_years) {
        val <- as.character(t2[i, p$col])
        pct <- suppressWarnings(as.numeric(val))
        if (!is.na(val) && val == "C") pct <- NA_real_

        pct_results[[length(pct_results) + 1]] <- tibble(
          area = area,
          year = p$year,
          foreign_buyer_pct = pct
        )
      }
    }
  }

  counts_df <- bind_rows(results)
  pcts_df <- bind_rows(pct_results)

  if (nrow(pcts_df) > 0) {
    counts_df %>%
      left_join(pcts_df, by = c("area", "year")) %>%
      mutate(source_file = basename(filepath))
  } else {
    counts_df %>%
      mutate(foreign_buyer_pct = NA_real_, source_file = basename(filepath))
  }
}

# Use releases with annual format that together cover 2016-2024
annual_releases <- c(
  "december-2020.xlsx",  # Has 2016-2020
  "june-2024.xlsx"       # Has 2020-2024
)

cat("\nParsing annual releases...\n")
annual_data <- map_dfr(annual_releases, function(fname) {
  fpath <- file.path(hist_dir, fname)
  if (!file.exists(fpath)) {
    cat("  Missing:", fname, "\n")
    return(NULL)
  }
  cat("  Processing:", fname, "...")
  d <- parse_annual_table2(fpath)
  if (!is.null(d)) cat(sprintf(" %d area-year obs\n", nrow(d)))
  d
})

# Deduplicate annual data
annual_panel <- annual_data %>%
  group_by(area, year) %>%
  slice_tail(n = 1) %>%
  ungroup()

cat(sprintf("\nAnnual panel: %d area-year observations\n", nrow(annual_panel)))
cat(sprintf("  Areas: %d\n", n_distinct(annual_panel$area)))
cat(sprintf("  Years: %s to %s\n", min(annual_panel$year), max(annual_panel$year)))

# ============================================================
# 3. Extract NATIONAL QUARTERLY data from Table 1
# ============================================================
# Use Sep 2018 release for pre-ban data and later releases for post-ban

parse_table1_quarterly <- function(filepath) {
  t1 <- read_excel(filepath, sheet = "Table 1")

  # Find the quarterly section
  n_rows <- nrow(t1)
  qtr_start <- NA
  qtr_end <- NA

  for (i in 1:n_rows) {
    val <- as.character(t1[i, 1])
    if (!is.na(val) && val == "Quarter") qtr_start <- i + 1
    if (!is.na(val) && grepl("^Percentage", val) && !is.na(qtr_start)) {
      qtr_end <- i - 1
      break
    }
  }

  if (is.na(qtr_start)) return(NULL)

  # Get column headers from rows 3-5
  # Row 3: "Quarter(5)"
  # Row 4: affiliation categories
  # Row 5: Buyers/Sellers

  results <- list()
  cur_year <- NA

  for (i in qtr_start:qtr_end) {
    yr <- suppressWarnings(as.integer(as.character(t1[i, 1])))
    qtr_name <- as.character(t1[i, 2])

    if (!is.na(yr)) cur_year <- yr
    if (is.na(cur_year) || is.na(qtr_name) || qtr_name == "NA") next

    q_num <- switch(qtr_name,
      "Mar" = 1, "Jun" = 2, "Sep" = 3, "Dec" = 4,
      NA)
    if (is.na(q_num)) next

    # Column 3: "At least one NZ citizen" buyers
    # Column 5: "At least one NZ resident visa (but no NZ citizen)" buyers
    # Column 7: "No NZ citizens or resident visas" buyers — this is our foreign buyer count
    # Column 9: Corporate buyers
    # Column 11: Total known buyers

    citizen_buyers <- suppressWarnings(as.numeric(as.character(t1[i, 3])))
    resident_buyers <- suppressWarnings(as.numeric(as.character(t1[i, 5])))
    foreign_buyers <- suppressWarnings(as.numeric(as.character(t1[i, 7])))
    corporate_buyers <- suppressWarnings(as.numeric(as.character(t1[i, 9])))
    total_buyers <- suppressWarnings(as.numeric(as.character(t1[i, 11])))

    # Get total including unknown from later columns
    total_all <- suppressWarnings(as.numeric(as.character(t1[i, ncol(t1)])))

    results[[length(results) + 1]] <- tibble(
      year = cur_year,
      quarter = q_num,
      date = as.Date(sprintf("%d-%02d-01", cur_year, q_num * 3)),
      citizen_buyers = citizen_buyers,
      resident_buyers = resident_buyers,
      foreign_buyers = foreign_buyers,
      corporate_buyers = corporate_buyers,
      total_known_buyers = total_buyers,
      total_transfers = total_all
    )
  }

  bind_rows(results) %>%
    mutate(
      foreign_buyer_pct = foreign_buyers / total_known_buyers * 100,
      source_file = basename(filepath)
    )
}

cat("\nParsing national quarterly data from Table 1...\n")
national_quarterly <- map_dfr(
  list.files(hist_dir, pattern = "[.]xlsx$", full.names = TRUE),
  function(f) {
    d <- parse_table1_quarterly(f)
    if (!is.null(d) && nrow(d) > 0) {
      cat(sprintf("  %s: %d quarters (%s to %s)\n",
                  basename(f), nrow(d), min(d$date), max(d$date)))
    }
    d
  }
)

# Deduplicate national quarterly
national_quarterly <- national_quarterly %>%
  group_by(year, quarter) %>%
  slice_tail(n = 1) %>%
  ungroup() %>%
  arrange(date)

cat(sprintf("\nNational quarterly panel: %d quarters (%s to %s)\n",
            nrow(national_quarterly), min(national_quarterly$date), max(national_quarterly$date)))

# ============================================================
# 4. Construct treatment intensity
# ============================================================
# Use pre-ban (2017-2018) average foreign buyer percentage by area

# From quarterly data: average over pre-ban quarters
pre_ban_intensity_q <- quarterly_panel %>%
  filter(date < as.Date("2018-10-01")) %>%
  group_by(area) %>%
  summarize(
    pre_ban_foreign_pct = mean(foreign_buyer_pct, na.rm = TRUE),
    pre_ban_foreign_count = mean(foreign_buyer_count, na.rm = TRUE),
    n_pre_quarters = sum(!is.na(foreign_buyer_pct)),
    .groups = "drop"
  )

cat("\nPre-ban foreign buyer intensity (quarterly, top 20):\n")
pre_ban_intensity_q %>%
  filter(!is.na(pre_ban_foreign_pct)) %>%
  arrange(desc(pre_ban_foreign_pct)) %>%
  head(20) %>%
  print()

# ============================================================
# 5. Save cleaned datasets
# ============================================================
saveRDS(quarterly_panel, file.path(data_dir, "quarterly_panel.rds"))
saveRDS(annual_panel, file.path(data_dir, "annual_panel.rds"))
saveRDS(national_quarterly, file.path(data_dir, "national_quarterly.rds"))
saveRDS(pre_ban_intensity_q, file.path(data_dir, "pre_ban_intensity.rds"))

cat("\nData cleaning complete.\n")
cat(sprintf("  Quarterly panel: %d obs, %d areas, %d quarters\n",
            nrow(quarterly_panel), n_distinct(quarterly_panel$area),
            n_distinct(quarterly_panel$date)))
cat(sprintf("  Annual panel: %d obs, %d areas, %d years\n",
            nrow(annual_panel), n_distinct(annual_panel$area),
            n_distinct(annual_panel$year)))
cat(sprintf("  National quarterly: %d quarters\n", nrow(national_quarterly)))
