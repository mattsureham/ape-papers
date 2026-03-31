## 01_fetch_data.R — Fetch CDC VSRR provisional drug overdose death data
## APEP-1185: Kratom Bans and Opioid Overdose Mortality

source("00_packages.R")

# ============================================================================
# CDC VSRR Provisional Drug Overdose Deaths
# Dataset: xkb8-kh2a on data.cdc.gov
# Contains: state-month drug overdose deaths with drug-type indicators
# Month is TEXT ("January", "February", ...), data_value may be absent
# ============================================================================

cat("Fetching CDC VSRR data...\n")

base_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

# Fetch in batches
all_data <- list()
offset <- 0
batch_size <- 50000

repeat {
  url <- paste0(base_url, "?$limit=", batch_size, "&$offset=", offset,
                "&$order=year,month")

  resp <- httr::GET(url, httr::add_headers("Accept" = "application/json"))

  if (httr::status_code(resp) != 200) {
    stop("CDC API returned status ", httr::status_code(resp),
         ": ", httr::content(resp, as = "text"))
  }

  batch <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))

  if (nrow(batch) == 0) break

  all_data[[length(all_data) + 1]] <- batch
  offset <- offset + batch_size

  cat("  Fetched", offset, "rows...\n")

  if (nrow(batch) < batch_size) break

  Sys.sleep(0.5)
}

raw <- bind_rows(all_data)
cat("Total rows fetched:", nrow(raw), "\n")

stopifnot("No data returned from CDC API" = nrow(raw) > 0)

# ============================================================================
# Clean: convert text month to integer, parse data_value
# ============================================================================

cat("Cleaning data...\n")

month_lookup <- c(
  "January" = 1L, "February" = 2L, "March" = 3L, "April" = 4L,
  "May" = 5L, "June" = 6L, "July" = 7L, "August" = 8L,
  "September" = 9L, "October" = 10L, "November" = 11L, "December" = 12L
)

df <- raw %>%
  mutate(
    year = as.integer(year),
    month_num = month_lookup[month],
    data_value = as.numeric(data_value)
  ) %>%
  # Keep only rows with valid data_value (suppressed rows have NA)
  filter(!is.na(data_value), !is.na(month_num), !is.na(state_name)) %>%
  select(state_name, state_abbrev = state, year, month = month_num,
         indicator, data_value)

cat("After cleaning:", nrow(df), "rows\n")
cat("Unique states:", n_distinct(df$state_name), "\n")
cat("Year range:", min(df$year), "-", max(df$year), "\n")
cat("Month range:", min(df$month), "-", max(df$month), "\n")
cat("Unique indicators:\n")
for (ind in sort(unique(df$indicator))) cat("  ", ind, "\n")

# ============================================================================
# Validate: all 5 ban states present
# ============================================================================

ban_states <- c("Indiana", "Wisconsin", "Arkansas", "Alabama", "Rhode Island")
missing <- setdiff(ban_states, unique(df$state_name))
if (length(missing) > 0) {
  stop("FATAL: Ban states missing from data: ", paste(missing, collapse = ", "))
}
cat("\nAll 5 ban states present in data. ✓\n")

# Check coverage for ban states
for (st in ban_states) {
  st_data <- df %>% filter(state_name == st, indicator == "Number of Drug Overdose Deaths")
  cat(sprintf("  %s: %d months, %d-%d\n", st, nrow(st_data), min(st_data$year), max(st_data$year)))
}

# ============================================================================
# Save
# ============================================================================

saveRDS(df, "../data/cdc_vsrr_raw.rds")
cat("\nSaved", nrow(df), "rows to data/cdc_vsrr_raw.rds\n")
