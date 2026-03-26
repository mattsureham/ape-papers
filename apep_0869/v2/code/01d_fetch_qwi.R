# 01d_fetch_qwi.R — Fetch LEHD Quarterly Workforce Indicators
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry
#
# QWI provides worker-flow data (hires, separations, job creation/destruction)
# at the county-industry-quarter level. This answers: did employment fall
# because firms stopped hiring or because they actively downsized?

source("00_packages.R")

# ============================================================
# LEHD QWI via Census API
# ============================================================

cat("=== FETCHING QWI DATA ===\n")

# States
target_states <- c("17", "18", "55", "29", "19", "21")
state_abbrev <- c("17" = "il", "18" = "in", "55" = "wi",
                  "29" = "mo", "19" = "ia", "21" = "ky")

# QWI variables we need
# HirA = All hires, HirN = New hires, Sep = Separations
# FrmJbC = Firm job creation, FrmJbD = Firm job destruction
# EarnHirAS = Avg earnings of hires, EarnSepS = Avg earnings of separations
# Emp = Beginning-of-quarter employment, EmpEnd = End-of-quarter employment
qwi_vars <- c("HirA", "HirN", "Sep", "FrmJbC", "FrmJbD",
              "Emp", "EmpEnd", "EarnHirAS", "EarnSepS")

# Census API key
census_key <- Sys.getenv("CENSUS_API_KEY")
key_param <- if (census_key != "") paste0("&key=", census_key) else ""

# QWI is available via Census API
# Endpoint: https://api.census.gov/data/timeseries/qwi/sa
# Parameters: for=county:*, in=state:XX, time=YYYY-Q, industry=XX

years <- 2015:2024
quarters <- 1:4

qwi_all <- list()
fetch_count <- 0
error_count <- 0

for (st in target_states) {
  for (yr in years) {
    for (qtr in quarters) {
      time_param <- sprintf("%d-Q%d", yr, qtr)
      vars_str <- paste(qwi_vars, collapse = ",")

      url <- sprintf(
        "https://api.census.gov/data/timeseries/qwi/sa?get=%s&for=county:*&in=state:%s&time=%s&industry=51&industry=52&industry=54&industry=62%s",
        vars_str, st, time_param, key_param
      )

      resp <- tryCatch(
        {
          r <- httr::GET(url, httr::timeout(60))
          if (httr::status_code(r) == 200) {
            json_text <- httr::content(r, as = "text", encoding = "UTF-8")
            parsed <- jsonlite::fromJSON(json_text)
            if (!is.null(parsed) && nrow(parsed) > 1) {
              dt <- as.data.table(parsed[-1, , drop = FALSE])
              setnames(dt, parsed[1, ])
              dt$year <- yr
              dt$qtr <- qtr
              fetch_count <<- fetch_count + 1
              dt
            } else {
              NULL
            }
          } else {
            NULL
          }
        },
        error = function(e) {
          error_count <<- error_count + 1
          NULL
        }
      )

      if (!is.null(resp) && nrow(resp) > 0) {
        qwi_all[[paste(st, yr, qtr)]] <- resp
      }

      Sys.sleep(0.3)
    }
  }
  cat(sprintf("State %s done. Fetched: %d, Errors: %d\n",
              state_abbrev[st], fetch_count, error_count))
}

if (length(qwi_all) == 0) {
  cat("WARNING: QWI API returned no data. Trying bulk download fallback...\n")

  # Fallback: download QWI CSV files directly from LEHD
  # https://lehd.ces.census.gov/data/qwi/latest_release/
  qwi_fallback <- list()

  for (st in names(state_abbrev)) {
    abbrev <- state_abbrev[st]
    url <- sprintf("https://lehd.ces.census.gov/data/qwi/latest_release/%s/qwi_%s_sa_f_gs_n4_op_u.csv.gz",
                   abbrev, abbrev)

    cat(sprintf("Trying LEHD bulk for %s...\n", abbrev))
    dest <- sprintf("../data/qwi_%s.csv.gz", abbrev)

    dl_ok <- tryCatch({
      download.file(url, dest, mode = "wb", quiet = TRUE)
      TRUE
    }, error = function(e) {
      # Try alternative URL patterns
      url2 <- sprintf("https://lehd.ces.census.gov/data/qwi/latest_release/%s/qwi_%s_sa_f_gs_n3_op_u.csv.gz",
                      abbrev, abbrev)
      tryCatch({
        download.file(url2, dest, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e2) FALSE)
    })

    if (dl_ok && file.exists(dest) && file.size(dest) > 1000) {
      dt <- fread(cmd = sprintf("zcat %s", dest), nrows = 500000)
      # Filter to our industries and counties
      if ("industry" %in% names(dt)) {
        dt <- dt[substr(industry, 1, 2) %in% c("51", "52", "54", "62")]
      }
      if (nrow(dt) > 0) {
        qwi_fallback[[abbrev]] <- dt
        cat(sprintf("  Got %d rows for %s\n", nrow(dt), abbrev))
      }
    }
  }

  if (length(qwi_fallback) > 0) {
    qwi_raw <- rbindlist(qwi_fallback, fill = TRUE)
  } else {
    cat("FATAL: No QWI data from either API or bulk download.\n")
    cat("QWI mechanism tests will be omitted from V2.\n")
    # Write empty marker
    writeLines("QWI_UNAVAILABLE", "../data/qwi_status.txt")
    q(save = "no")
  }
} else {
  qwi_raw <- rbindlist(qwi_all, fill = TRUE)
}

cat(sprintf("\nQWI raw: %d rows\n", nrow(qwi_raw)))

# ============================================================
# Clean and save
# ============================================================

# Construct area_fips
if ("state" %in% names(qwi_raw) && "county" %in% names(qwi_raw)) {
  qwi_raw[, area_fips := paste0(state, county)]
}

# Convert numeric columns
for (v in qwi_vars) {
  if (v %in% names(qwi_raw)) {
    qwi_raw[[v]] <- as.numeric(qwi_raw[[v]])
  }
}

# Filter to relevant industries
if ("industry" %in% names(qwi_raw)) {
  qwi_raw[, naics_2 := substr(industry, 1, 2)]
  qwi_clean <- qwi_raw[naics_2 %in% c("51", "52", "54", "62")]
} else {
  qwi_clean <- qwi_raw
}

fwrite(qwi_clean, "../data/qwi_clean.csv")
cat(sprintf("Saved: qwi_clean.csv (%d rows)\n", nrow(qwi_clean)))

cat("\n=== QWI FETCH COMPLETE ===\n")
