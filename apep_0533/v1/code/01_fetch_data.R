## 01_fetch_data.R — Fetch QWI data from Census API
## apep_0533: Salary History Bans and the Gender Earnings Gap

source("00_packages.R")

# Census API key
api_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(api_key) == 0) stop("CENSUS_API_KEY not set. Cannot proceed.")

# ============================================================
# QWI API parameters
# ============================================================

# State FIPS codes (01-56, excluding territories)
state_fips <- sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))

# Variables to fetch
vars <- c("Emp", "EmpS", "EarnS", "EarnBeg", "EarnHirNS", "EarnHirAS",
          "HirN", "HirNs", "HirA", "Sep", "SepS")

# Sex codes: 1 = Male, 2 = Female
sex_codes <- c("1", "2")

# Time range: 2010-Q1 to 2024-Q4
time_range <- "from+2010-Q1+to+2024-Q4"

# ============================================================
# Fetch function (one state x sex at a time to avoid API limits)
# ============================================================

fetch_qwi <- function(state, sex, vars, time_range, api_key) {
  var_str <- paste(vars, collapse = ",")
  url <- sprintf(
    "https://api.census.gov/data/timeseries/qwi/sa?get=%s&for=state:%s&time=%s&sex=%s&key=%s",
    var_str, state, time_range, sex, api_key
  )

  resp <- tryCatch({
    GET(url, timeout(60))
  }, error = function(e) {
    warning(sprintf("HTTP error for state=%s sex=%s: %s", state, sex, e$message))
    return(NULL)
  })

  if (is.null(resp) || status_code(resp) != 200) {
    warning(sprintf("API returned status %s for state=%s sex=%s",
                    ifelse(is.null(resp), "NULL", status_code(resp)), state, sex))
    return(NULL)
  }

  raw <- content(resp, as = "text", encoding = "UTF-8")
  if (nchar(raw) < 10 || raw == "[]") {
    warning(sprintf("Empty response for state=%s sex=%s", state, sex))
    return(NULL)
  }

  parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)

  dt <- as.data.table(parsed[-1, , drop = FALSE])
  setnames(dt, parsed[1, ])
  return(dt)
}

# ============================================================
# Main fetch loop
# ============================================================

cat("Fetching QWI data for", length(state_fips), "states x 2 sexes...\n")
all_data <- list()
i <- 0

for (st in state_fips) {
  for (sx in sex_codes) {
    i <- i + 1
    if (i %% 20 == 0) cat(sprintf("  Progress: %d / %d\n", i, length(state_fips) * 2))

    dt <- fetch_qwi(st, sx, vars, time_range, api_key)
    if (!is.null(dt)) {
      all_data[[length(all_data) + 1]] <- dt
    }

    Sys.sleep(0.3)  # Rate limiting
  }
}

cat("Combining results...\n")
qwi <- rbindlist(all_data, fill = TRUE)

# Convert numeric columns
num_cols <- vars
for (col in num_cols) {
  if (col %in% names(qwi)) {
    qwi[, (col) := as.numeric(get(col))]
  }
}
qwi[, state := as.character(state)]
qwi[, sex := as.integer(sex)]

cat(sprintf("Aggregate data: %d rows, %d states, %d quarters\n",
            nrow(qwi), uniqueN(qwi$state), uniqueN(qwi$time)))

# ============================================================
# Also fetch by INDUSTRY for heterogeneity analysis
# ============================================================

industries <- c("11", "21", "22", "23", "31-33", "42", "44-45", "48-49",
                "51", "52", "53", "54", "55", "56", "61", "62", "71", "72", "81")

cat("\nFetching industry-level data...\n")
ind_data <- list()
j <- 0

for (st in state_fips) {
  for (sx in sex_codes) {
    for (ind in industries) {
      j <- j + 1
      if (j %% 200 == 0) cat(sprintf("  Industry progress: %d / %d\n",
                                       j, length(state_fips) * 2 * length(industries)))

      url <- sprintf(
        "https://api.census.gov/data/timeseries/qwi/sa?get=EarnS,EarnHirNS,Emp,HirN&for=state:%s&time=%s&sex=%s&industry=%s&key=%s",
        st, time_range, sx, ind, api_key
      )

      resp <- tryCatch(GET(url, timeout(60)), error = function(e) NULL)
      if (is.null(resp) || status_code(resp) != 200) next

      raw <- content(resp, as = "text", encoding = "UTF-8")
      parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)
      if (is.null(parsed) || nrow(parsed) < 2) next

      dt <- as.data.table(parsed[-1, , drop = FALSE])
      setnames(dt, parsed[1, ])
      ind_data[[length(ind_data) + 1]] <- dt

      Sys.sleep(0.15)
    }
  }
}

cat("Combining industry data...\n")
qwi_ind <- rbindlist(ind_data, fill = TRUE)

for (col in c("EarnS", "EarnHirNS", "Emp", "HirN")) {
  if (col %in% names(qwi_ind)) {
    qwi_ind[, (col) := as.numeric(get(col))]
  }
}
qwi_ind[, state := as.character(state)]
qwi_ind[, sex := as.integer(sex)]

cat(sprintf("Industry data: %d rows, %d states, %d industries\n",
            nrow(qwi_ind), uniqueN(qwi_ind$state), uniqueN(qwi_ind$industry)))

# ============================================================
# Save raw data
# ============================================================

fwrite(qwi, file.path(data_dir, "qwi_aggregate.csv"))
fwrite(qwi_ind, file.path(data_dir, "qwi_industry.csv"))

# ============================================================
# DATA VALIDATION
# ============================================================

stopifnot("Expected 50+ state FIPS" = uniqueN(qwi$state) >= 50)
stopifnot("Expected both sexes" = all(c(1L, 2L) %in% qwi$sex))
stopifnot("Expected 40+ quarters" = uniqueN(qwi$time) >= 40)
stopifnot("Expected EarnHirNS present" = "EarnHirNS" %in% names(qwi))
stopifnot("Expected non-null earnings" = sum(!is.na(qwi$EarnS)) > 1000)

cat(sprintf("\nData validation passed:\n  Aggregate: %d rows, %d states, %d quarters\n  Industry: %d rows, %d states, %d industries\n",
            nrow(qwi), uniqueN(qwi$state), uniqueN(qwi$time),
            nrow(qwi_ind), uniqueN(qwi_ind$state), uniqueN(qwi_ind$industry)))
