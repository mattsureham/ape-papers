# =============================================================================
# 01_fetch_data.R — Fetch CDC VSRR Provisional Drug Overdose Deaths
# =============================================================================
# Source: CDC VSRR via data.cdc.gov SODA API (endpoint: xkb8-kh2a)
# Unit: state x month x drug indicator
# =============================================================================
source("00_packages.R")

# =============================================================================
# PART 1: FTS Legalization Dates
# =============================================================================
# Compiled from state legislation, NLHPP tracker, and legal databases.
# fts_year = calendar year law went into effect.

fts_laws <- tribble(
  ~state,                ~state_abbr, ~fts_year,
  "Rhode Island",        "RI", 2018L,
  "Massachusetts",       "MA", 2018L,
  "North Carolina",      "NC", 2019L,
  "Virginia",            "VA", 2020L,
  "Maryland",            "MD", 2021L,
  "New Mexico",          "NM", 2021L,
  "Nevada",              "NV", 2021L,
  "Colorado",            "CO", 2021L,
  "Connecticut",         "CT", 2021L,
  "Illinois",            "IL", 2021L,
  "Vermont",             "VT", 2021L,
  "Minnesota",           "MN", 2021L,
  "Delaware",            "DE", 2021L,
  "Oregon",              "OR", 2021L,
  "California",          "CA", 2022L,
  "Washington",          "WA", 2022L,
  "New York",            "NY", 2022L,
  "New Jersey",          "NJ", 2022L,
  "Pennsylvania",        "PA", 2022L,
  "Michigan",            "MI", 2022L,
  "Arizona",             "AZ", 2022L,
  "New Hampshire",       "NH", 2022L,
  "Maine",               "ME", 2022L,
  "Hawaii",              "HI", 2022L,
  "Louisiana",           "LA", 2022L,
  "Wisconsin",           "WI", 2022L,
  "Ohio",                "OH", 2022L,
  "Montana",             "MT", 2023L,
  "Indiana",             "IN", 2023L,
  "Kentucky",            "KY", 2023L,
  "Tennessee",           "TN", 2023L,
  "Nebraska",            "NE", 2023L,
  "Alaska",              "AK", 2023L,
  "Utah",                "UT", 2023L,
  "South Dakota",        "SD", 2023L,
  "North Dakota",        "ND", 2023L,
  "Arkansas",            "AR", 2023L,
  "Georgia",             "GA", 2023L,
  "Oklahoma",            "OK", 2023L,
  "West Virginia",       "WV", 2023L,
  "Mississippi",         "MS", 2023L,
  "Missouri",            "MO", 2023L,
  "Iowa",                "IA", 2023L
)

cat("FTS legalization dates compiled:", nrow(fts_laws), "states\n")
cat("By year:\n")
print(table(fts_laws$fts_year))

# =============================================================================
# PART 2: Fetch CDC VSRR Data
# =============================================================================
base_url <- "https://data.cdc.gov/resource/xkb8-kh2a.json"

fetch_cdc_vsrr <- function(offset = 0, limit = 50000) {
  resp <- GET(
    base_url,
    query = list(
      `$limit` = limit,
      `$offset` = offset,
      `$order` = ":id",
      `$where` = "year >= '2015'"
    ),
    add_headers("Accept" = "application/json")
  )
  if (status_code(resp) != 200) {
    stop("CDC API returned status ", status_code(resp))
  }
  fromJSON(content(resp, "text", encoding = "UTF-8"), flatten = TRUE)
}

cat("Fetching CDC VSRR data...\n")
all_data <- list()
offset <- 0
repeat {
  chunk <- fetch_cdc_vsrr(offset = offset)
  if (length(chunk) == 0 || nrow(chunk) == 0) break
  all_data[[length(all_data) + 1]] <- chunk
  cat("  Fetched", nrow(chunk), "rows (offset:", offset, ")\n")
  offset <- offset + 50000
  if (nrow(chunk) < 50000) break
  Sys.sleep(0.5)
}

cdc_raw <- bind_rows(all_data)
cat("Total CDC VSRR rows:", nrow(cdc_raw), "\n")
cat("Columns:", paste(names(cdc_raw), collapse = ", "), "\n")

# Save raw
write_csv(cdc_raw, "../data/cdc_vsrr_raw.csv")
write_csv(fts_laws, "../data/fts_legalization.csv")
message("Saved CDC VSRR data: ", nrow(cdc_raw), " rows")
message("Saved FTS legalization: ", nrow(fts_laws), " states")
