# 02_clean_data.R — Construct continuous summary scores from CMS measure stars
# apep_1448: Medicare Advantage Quality Bonus RDD
#
# The overall Part C star rating is determined by rounding the weighted average
# of measure-level stars to the nearest 0.5. We reconstruct this continuous
# weighted average as our running variable.

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# CMS Measure Weights (from CMS Technical Notes)
# ============================================================================
# CMS assigns equal weight (1.0) to most Part C measures, with some measures
# receiving higher weight (1.5 or 3.0) for improvement and patient experience.
# For the overall Part C summary, all Part C measures are weighted equally
# in the star computation (each measure = 1 star, averaged).
#
# The key insight: the Part C summary score = simple average of all Part C
# measure stars that a contract reports. CMS then rounds to nearest 0.5.

# ============================================================================
# Parse measure stars from each year's Excel master table
# ============================================================================

parse_year <- function(year) {
  # Find the master table Excel file
  star_dir <- file.path(data_dir, paste0("star_", year))
  if (!dir.exists(star_dir)) return(NULL)

  xlsx_files <- list.files(star_dir, pattern = "Report_Card_Master_Table.*\\.xlsx$",
                           full.names = TRUE, recursive = TRUE)

  # For years with a single Data Table xlsx (2020-2021 style)
  if (length(xlsx_files) == 0) {
    xlsx_files <- list.files(star_dir, pattern = "Data Table.*\\.xlsx$",
                             full.names = TRUE, recursive = TRUE)
  }

  # If multiple xlsx files (Fall vs Spring release), prefer Spring (latest)
  if (length(xlsx_files) > 1) {
    spring <- grep("Spring", xlsx_files, value = TRUE)
    if (length(spring) > 0) {
      xlsx_files <- spring[1]
    } else {
      # Use the most recently dated file
      xlsx_files <- tail(sort(xlsx_files), 1)
    }
  }

  if (length(xlsx_files) == 0) {
    cat(sprintf("  No Excel master table for %d\n", year))
    return(NULL)
  }

  xlsx_path <- xlsx_files[1]
  cat(sprintf("Processing %d: %s\n", year, basename(xlsx_path)))

  # Read Summary_Rating sheet for the displayed rating
  summary_df <- tryCatch(
    read_excel(xlsx_path, sheet = "Summary_Rating", skip = 1),
    error = function(e) {
      # Try alternative sheet names
      sheets <- excel_sheets(xlsx_path)
      sum_sheet <- grep("summary", sheets, ignore.case = TRUE, value = TRUE)
      if (length(sum_sheet) > 0) {
        read_excel(xlsx_path, sheet = sum_sheet[1], skip = 1)
      } else NULL
    }
  )

  if (is.null(summary_df)) {
    cat(sprintf("  No summary sheet for %d\n", year))
    return(NULL)
  }

  # Standardize column names — remove leading year prefix
  names(summary_df) <- gsub("^\\d{4}\\s+", "", names(summary_df))
  names(summary_df) <- trimws(names(summary_df))

  # Extract contract ID and overall/Part C star rating
  contract_col <- grep("contract", names(summary_df), ignore.case = TRUE, value = TRUE)[1]
  partc_col <- grep("Part C Summary", names(summary_df), ignore.case = TRUE, value = TRUE)[1]
  overall_col <- grep("Overall", names(summary_df), ignore.case = TRUE, value = TRUE)[1]
  org_col <- grep("Organization Type", names(summary_df), ignore.case = TRUE, value = TRUE)[1]
  name_col <- grep("Contract Name", names(summary_df), ignore.case = TRUE, value = TRUE)[1]
  parent_col <- grep("Parent Organization", names(summary_df), ignore.case = TRUE, value = TRUE)[1]

  result <- summary_df %>%
    select(
      contract_id = all_of(contract_col),
      org_type = all_of(org_col),
      contract_name = all_of(name_col),
      parent_org = all_of(parent_col),
      partc_stars = all_of(partc_col),
      overall_stars = all_of(overall_col)
    ) %>%
    mutate(
      year = year,
      partc_stars = as.numeric(partc_stars),
      overall_stars = as.numeric(overall_stars),
      contract_id = trimws(contract_id)
    ) %>%
    filter(!is.na(partc_stars))  # Keep only contracts with Part C ratings

  # Now read Measure_Stars to reconstruct the continuous score
  measure_df <- tryCatch({
    raw <- read_excel(xlsx_path, sheet = "Measure_Stars", col_names = FALSE)
    # Row 1 = title, Row 2 = column headers (domains/ids), Row 3 = measure names
    # Data starts from row 4

    # Get measure names from row 3
    measure_names <- as.character(raw[3, ])

    # Get contract IDs from row 2
    id_names <- as.character(raw[2, ])

    # Find Part C measure columns (start with C)
    c_cols <- grep("^C\\d{2}", measure_names)

    # Data rows start at row 4
    data_rows <- raw[4:nrow(raw), ]

    # Extract contract IDs (column 1)
    contracts <- trimws(as.character(data_rows[[1]]))

    # Extract Part C measure stars
    c_stars <- data_rows[, c_cols]
    names(c_stars) <- measure_names[c_cols]

    # Convert to numeric (non-numeric = NA)
    c_stars <- c_stars %>% mutate(across(everything(), ~suppressWarnings(as.numeric(.x))))

    # Compute continuous summary score = mean of available Part C measure stars
    c_stars$contract_id <- contracts
    c_stars$n_measures <- rowSums(!is.na(c_stars %>% select(-contract_id)))
    c_stars$summary_score <- rowMeans(
      c_stars %>% select(-contract_id, -n_measures),
      na.rm = TRUE
    )

    c_stars %>%
      select(contract_id, summary_score, n_measures) %>%
      filter(!is.na(summary_score) & n_measures >= 5)  # Need enough measures
  }, error = function(e) {
    cat(sprintf("  Measure_Stars parse error for %d: %s\n", year, e$message))
    NULL
  })

  if (!is.null(measure_df)) {
    result <- result %>%
      left_join(measure_df, by = "contract_id")
  }

  cat(sprintf("  %d contracts with Part C ratings, %d with continuous scores\n",
              nrow(result), sum(!is.na(result$summary_score))))

  result
}

# ============================================================================
# Process all years
# ============================================================================

cat("=== Processing Star Ratings by Year ===\n\n")
all_years <- 2015:2026
panels <- list()

for (yr in all_years) {
  df <- parse_year(yr)
  if (!is.null(df) && nrow(df) > 0) {
    panels[[as.character(yr)]] <- df
  }
}

panel <- bind_rows(panels)

cat(sprintf("\n=== Panel Summary ===\n"))
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
cat(sprintf("Contracts with continuous scores: %d\n", sum(!is.na(panel$summary_score))))

# ============================================================================
# Verify: does the continuous score predict the displayed star rating?
# ============================================================================

if (sum(!is.na(panel$summary_score)) > 0) {
  check <- panel %>%
    filter(!is.na(summary_score) & !is.na(partc_stars)) %>%
    mutate(
      predicted_stars = round(summary_score * 2) / 2,  # Round to nearest 0.5
      match = abs(predicted_stars - partc_stars) < 0.01
    )

  cat(sprintf("\nValidation: predicted stars match displayed stars in %.1f%% of cases\n",
              mean(check$match) * 100))
  cat(sprintf("Correlation: %.3f\n", cor(check$summary_score, check$partc_stars)))

  # Distribution near the 3.5/4.0 threshold
  near_threshold <- check %>%
    filter(summary_score >= 3.25 & summary_score <= 4.25)
  cat(sprintf("Contracts near 3.75 threshold (3.25-4.25): %d\n", nrow(near_threshold)))

  # Show the distribution of summary scores
  cat("\nSummary score distribution (near threshold):\n")
  near_threshold %>%
    mutate(bin = cut(summary_score, breaks = seq(3.0, 4.5, by = 0.1))) %>%
    count(bin) %>%
    print(n = 20)
}

# ============================================================================
# Create the RDD analysis variable: distance to 3.75 threshold
# ============================================================================

panel <- panel %>%
  mutate(
    # Distance to threshold (running variable)
    score_centered = summary_score - 3.75,
    # Treatment: above threshold = 4+ stars = quality bonus
    above_threshold = as.integer(summary_score >= 3.75),
    # Displayed Part C stars (for reference)
    star_4plus = as.integer(partc_stars >= 4)
  )

# ============================================================================
# Save
# ============================================================================

write_csv(panel, file.path(data_dir, "panel_star_ratings.csv"))
cat(sprintf("\nSaved panel: %s\n", file.path(data_dir, "panel_star_ratings.csv")))

# Summary statistics
cat("\n=== Key Statistics ===\n")
cat(sprintf("Total contract-years: %d\n", nrow(panel)))
cat(sprintf("With continuous scores: %d\n", sum(!is.na(panel$summary_score))))
cat(sprintf("Above threshold (>=3.75): %d\n", sum(panel$above_threshold == 1, na.rm = TRUE)))
cat(sprintf("Below threshold (<3.75): %d\n", sum(panel$above_threshold == 0, na.rm = TRUE)))

panel %>%
  filter(!is.na(summary_score)) %>%
  group_by(year) %>%
  summarise(
    n = n(),
    mean_score = mean(summary_score),
    sd_score = sd(summary_score),
    n_near_threshold = sum(summary_score >= 3.25 & summary_score <= 4.25),
    .groups = "drop"
  ) %>%
  print(n = 15)
