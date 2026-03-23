## 01_fetch_data.R — Fetch QWI data from Census API
## ABAWD enforcement classification + QWI employment by state × age group × quarter
source("code/00_packages.R")

# ── Census API key ───────────────────────────────────────────────
api_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(api_key) == 0) stop("CENSUS_API_KEY not set in .env")

# ── ABAWD Enforcement Classification (FY2024) ───────────────────
# Sources: FNS SNAP ABAWD waiver status tables, CBPP analysis
# Full enforcement: states that reinstated ABAWD time limits statewide
# Statewide waiver: states that waived time limits entirely
# Partial waiver: states with area-based waivers only

abawd_status <- data.frame(
  state_fips = c(
    # Full enforcement (~18 states with no waivers in FY2024)
    "01", "05", "12", "13", "16", "18", "20", "22", "28",
    "29", "31", "37", "38", "40", "45", "47", "48", "56",
    # Statewide waiver (12 states)
    "02", "06", "09", "11", "15", "25", "32", "34", "35",
    "36", "44", "51",
    # Partial waiver (remaining 21 states)
    "04", "08", "10", "17", "19", "21", "23", "24", "26",
    "27", "30", "33", "39", "41", "42", "46", "49", "50",
    "53", "54", "55"
  ),
  enforcement = c(
    rep("full", 18),
    rep("waiver", 12),
    rep("partial", 21)
  ),
  stringsAsFactors = FALSE
)

state_names <- data.frame(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,
                                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                                  36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,
                                  53,54,55,56)),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                 "Connecticut","Delaware","DC","Florida","Georgia","Hawaii","Idaho",
                 "Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine",
                 "Maryland","Massachusetts","Michigan","Minnesota","Mississippi",
                 "Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey",
                 "New Mexico","New York","North Carolina","North Dakota","Ohio",
                 "Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina",
                 "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia",
                 "Washington","West Virginia","Wisconsin","Wyoming"),
  stringsAsFactors = FALSE
)

abawd_status <- merge(abawd_status, state_names, by = "state_fips", all.x = TRUE)
cat("ABAWD classification:\n")
cat("  Full enforcement:", sum(abawd_status$enforcement == "full"), "states\n")
cat("  Statewide waiver:", sum(abawd_status$enforcement == "waiver"), "states\n")
cat("  Partial waiver:", sum(abawd_status$enforcement == "partial"), "states\n")
saveRDS(abawd_status, "data/abawd_status.rds")

# ── Fetch QWI: one request per state × quarter × age group ──────
base_url <- "https://api.census.gov/data/timeseries/qwi/sa"

# Build all combinations
combos <- expand.grid(
  state_fips = unique(abawd_status$state_fips),
  year = 2018:2024,
  quarter = 1:4,
  agegrp = c("A06", "A07"),  # 45-54, 55-64
  stringsAsFactors = FALSE
)
combos <- combos[order(combos$state_fips, combos$year, combos$quarter, combos$agegrp), ]

cat("\nFetching QWI:", nrow(combos), "requests (51 states × 28 quarters × 2 age groups)...\n")

fetch_one <- function(st, yr, qt, ag) {
  url <- paste0(
    base_url,
    "?get=Emp,HirA,Sep,EarnS",
    "&for=state:", st,
    "&time=", yr, "-Q", qt,
    "&agegrp=", ag,
    "&sex=0",
    "&ownercode=A05",
    "&industry=00",
    "&key=", api_key
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(30)), error = function(e) NULL)
  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)
  txt <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- tryCatch(jsonlite::fromJSON(txt), error = function(e) NULL)
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)
  df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df
}

results <- vector("list", nrow(combos))
errors <- 0

for (i in seq_len(nrow(combos))) {
  df <- fetch_one(combos$state_fips[i], combos$year[i],
                  combos$quarter[i], combos$agegrp[i])
  if (!is.null(df)) {
    results[[i]] <- df
  } else {
    errors <- errors + 1
  }
  if (i %% 200 == 0) {
    cat(sprintf("  %d/%d (%.0f%%), errors: %d\n", i, nrow(combos),
                100 * i / nrow(combos), errors))
    Sys.sleep(0.3)
  }
}

cat("\nFetch complete:", sum(!sapply(results, is.null)), "successful,",
    errors, "errors out of", nrow(combos), "\n")

qwi_raw <- bind_rows(results[!sapply(results, is.null)])
if (nrow(qwi_raw) == 0) stop("FATAL: No QWI data fetched.")

# Convert columns
for (col in c("Emp", "HirA", "Sep", "EarnS")) {
  qwi_raw[[col]] <- as.numeric(qwi_raw[[col]])
}

# Extract year/quarter from time column
qwi_raw <- qwi_raw |>
  mutate(
    year = as.integer(substr(time, 1, 4)),
    quarter = as.integer(substr(time, 7, 7))
  ) |>
  rename(state_fips = state) |>
  mutate(
    age_group = ifelse(agegrp == "A06", "45-54", "55-64"),
    time_id = year + (quarter - 1) / 4
  )

cat("\nQWI summary:\n")
cat("  Rows:", nrow(qwi_raw), "\n")
cat("  States:", n_distinct(qwi_raw$state_fips), "\n")
cat("  Quarters:", n_distinct(paste(qwi_raw$year, qwi_raw$quarter)), "\n")
cat("  Age groups:", paste(unique(qwi_raw$age_group), collapse = ", "), "\n")
cat("  Year range:", min(qwi_raw$year), "-", max(qwi_raw$year), "\n")

stopifnot("Too few states" = n_distinct(qwi_raw$state_fips) >= 25)
stopifnot("Too few quarters" = n_distinct(paste(qwi_raw$year, qwi_raw$quarter)) >= 15)

# Check for missing data
emp_check <- qwi_raw |>
  group_by(age_group) |>
  summarise(n = n(), mean_emp = mean(Emp, na.rm = TRUE),
            pct_na = mean(is.na(Emp)) * 100)
print(emp_check)

saveRDS(qwi_raw, "data/qwi_raw.rds")
cat("\nSaved data/qwi_raw.rds\n")
