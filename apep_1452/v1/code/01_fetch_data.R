## 01_fetch_data.R — Fetch Eurostat employment + Statbel wage index data
source("00_packages.R")

data_dir <- "../data/"

# ========================================================================
# 1. Eurostat: Quarterly employment by NACE Rev. 2 section, Belgium
# ========================================================================
cat("Fetching Eurostat quarterly employment (lfsq_egan2)...\n")

# Use Eurostat JSON API
base_url <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/lfsq_egan2"
params <- list(
  geo = "BE",
  sex = "T",
  age = "Y15-74",
  unit = "THS_PER",
  format = "JSON",
  sinceTimePeriod = "2018-Q1",
  untilTimePeriod = "2025-Q4"
)

resp <- request(base_url) |>
  req_url_query(!!!params) |>
  req_perform()

if (resp_status(resp) != 200) stop("Eurostat API returned status ", resp_status(resp))

json_data <- resp_body_json(resp)

# Parse Eurostat JSON-stat format
values <- unlist(json_data$value)
if (length(values) == 0) stop("No employment data returned from Eurostat")

# Get dimension indices
nace_dim <- json_data$dimension$nace_r2$category
nace_labels <- unlist(nace_dim$label)
nace_ids <- names(nace_labels)

time_dim <- json_data$dimension$time$category
time_labels <- unlist(time_dim$label)
time_ids <- names(time_labels)

# Build index mapping
dim_sizes <- unlist(json_data$size)
# Dimensions: freq, nace_r2, unit, age, sex, geo, time
# Only nace_r2 and time vary (others are singleton after filtering)
# We need to figure out which dimensions have size > 1

cat("Dimension sizes:", paste(names(json_data$dimension), dim_sizes, sep="=", collapse=", "), "\n")

# Build the full grid by finding varying dimensions
n_nace <- length(nace_ids)
n_time <- length(time_ids)

# The JSON-stat values are indexed by a flat key derived from dimension positions
# For our query, only nace_r2 and time vary
# We need to reconstruct the mapping

# Get all dimension sizes
dims <- json_data$dimension
dim_names <- json_data$id
dim_sizes_vec <- unlist(json_data$size)

# Find indices for each named value
# Values are keyed by flat index = sum(index_i * prod(sizes[i+1:end]))
# Build a function to decode
decode_index <- function(flat_idx, sizes) {
  n <- length(sizes)
  indices <- integer(n)
  remaining <- flat_idx
  for (i in seq_len(n)) {
    block <- prod(sizes[(i+1):n])
    if (i == n) block <- 1
    indices[i] <- remaining %/% block
    remaining <- remaining %% block
  }
  indices
}

# Build data frame from values
emp_rows <- list()
for (key in names(values)) {
  idx <- as.integer(key)
  positions <- decode_index(idx, dim_sizes_vec)

  nace_pos <- positions[which(unlist(dim_names) == "nace_r2")] + 1
  time_pos <- positions[which(unlist(dim_names) == "time")] + 1

  if (nace_pos <= length(nace_ids) && time_pos <= length(time_ids)) {
    emp_rows[[length(emp_rows) + 1]] <- data.frame(
      nace = nace_ids[nace_pos],
      nace_label = nace_labels[nace_pos],
      quarter = time_ids[time_pos],
      employment_ths = as.numeric(values[key]),
      stringsAsFactors = FALSE
    )
  }
}

employment <- bind_rows(emp_rows)
cat("Employment data:", nrow(employment), "rows,", n_distinct(employment$nace), "sectors,",
    n_distinct(employment$quarter), "quarters\n")

if (nrow(employment) < 100) stop("Too few employment observations: ", nrow(employment))

# ========================================================================
# 2. Statbel: Quarterly Wage and Salary Index by NACE subsector
# ========================================================================
cat("\nFetching Statbel quarterly wage index...\n")

wage_url <- "https://statbel.fgov.be/sites/default/files/files/documents/Conjunctuur/4.3%20Loonmassa/WSI_2015_STATBEL_EN.xls"

wage_file <- file.path(data_dir, "statbel_wage_index.xls")
download.file(wage_url, wage_file, mode = "wb", quiet = TRUE)

if (!file.exists(wage_file) || file.size(wage_file) < 10000) {
  stop("Statbel wage index download failed or file too small")
}

# Read XLS — structure may vary, read first sheet
wage_raw <- read_excel(wage_file, sheet = 1)
cat("Statbel wage index raw:", nrow(wage_raw), "rows,", ncol(wage_raw), "columns\n")
cat("Column names:", paste(head(names(wage_raw), 10), collapse=", "), "\n")

# Save raw data for inspection
saveRDS(wage_raw, file.path(data_dir, "wage_index_raw.rds"))

# ========================================================================
# 3. Eurostat: Hours worked per person (lfsq_ewhais)
# ========================================================================
cat("\nFetching Eurostat hours worked (lfsq_ewhais)...\n")

hours_url <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/lfsq_ewhais"
hours_params <- list(
  geo = "BE",
  sex = "T",
  age = "Y15-74",
  worktime = "TOTAL",
  unit = "HR",
  format = "JSON",
  sinceTimePeriod = "2018-Q1",
  untilTimePeriod = "2025-Q4"
)

hours_resp <- tryCatch({
  request(hours_url) |>
    req_url_query(!!!hours_params) |>
    req_perform()
}, error = function(e) {
  cat("WARNING: Hours worked data not available:", conditionMessage(e), "\n")
  cat("Proceeding with employment data only.\n")
  NULL
})

if (!is.null(hours_resp) && resp_status(hours_resp) == 200) {
  hours_json <- resp_body_json(hours_resp)
  hours_values <- unlist(hours_json$value)

  hours_nace <- hours_json$dimension$nace_r2$category
  hours_nace_labels <- unlist(hours_nace$label)
  hours_nace_ids <- names(hours_nace_labels)

  hours_time <- hours_json$dimension$time$category
  hours_time_ids <- names(unlist(hours_time$label))

  hours_dim_sizes <- unlist(hours_json$size)
  hours_dim_names <- hours_json$id

  hours_rows <- list()
  for (key in names(hours_values)) {
    idx <- as.integer(key)
    positions <- decode_index(idx, hours_dim_sizes)

    nace_pos <- positions[which(unlist(hours_dim_names) == "nace_r2")] + 1
    time_pos <- positions[which(unlist(hours_dim_names) == "time")] + 1

    if (nace_pos <= length(hours_nace_ids) && time_pos <= length(hours_time_ids)) {
      hours_rows[[length(hours_rows) + 1]] <- data.frame(
        nace = hours_nace_ids[nace_pos],
        quarter = hours_time_ids[time_pos],
        hours_worked = as.numeric(hours_values[key]),
        stringsAsFactors = FALSE
      )
    }
  }

  hours_data <- bind_rows(hours_rows)
  cat("Hours worked data:", nrow(hours_data), "rows\n")
  saveRDS(hours_data, file.path(data_dir, "hours_worked.rds"))
} else {
  cat("Hours worked data unavailable; will use employment only.\n")
}

# ========================================================================
# 4. Save employment data
# ========================================================================
saveRDS(employment, file.path(data_dir, "employment.rds"))
cat("\nAll data saved to", data_dir, "\n")
cat("Files:", paste(list.files(data_dir), collapse=", "), "\n")
