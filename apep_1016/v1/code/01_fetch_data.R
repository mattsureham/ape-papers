## 01_fetch_data.R — Fetch bankruptcy case data + business formation data
## apep_1016: Fresh Start Dividend
##
## Data sources:
## 1. CourtListener RECAP Archive: Chapter 13 bankruptcy cases with judge assignments
## 2. Census Business Formation Statistics (BFS): County-level business applications

library(httr)
library(jsonlite)
library(tidyverse)
library(data.table)

set.seed(20260326)

DATA_DIR <- file.path(dirname(getwd()), "data")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

cat("=== Fetching data for apep_1016 ===\n")

# -----------------------------------------------------------------------
# 1. CourtListener: Chapter 13 cases from 10 large bankruptcy courts
# -----------------------------------------------------------------------

# Courts selected for high Ch13 volume and geographic diversity
courts <- c("flsb", "ilnb", "mieb", "txsb", "ganb",
            "tnmb", "mdb", "njb", "ohsb", "vaeb")

court_info <- data.frame(
  court_id = courts,
  court_name = c("S.D. Florida", "N.D. Illinois", "E.D. Michigan",
                 "S.D. Texas", "N.D. Georgia", "M.D. Tennessee",
                 "D. Maryland", "D. New Jersey", "S.D. Ohio", "E.D. Virginia"),
  state_fips = c("12", "17", "26", "48", "13", "47", "24", "34", "39", "51"),
  stringsAsFactors = FALSE
)

# Quarterly date ranges for 2010-2019
quarters <- expand.grid(
  year = 2010:2019,
  q = 1:4,
  stringsAsFactors = FALSE
) %>%
  mutate(
    start = as.Date(paste0(year, "-", (q - 1) * 3 + 1, "-01")),
    end = as.Date(paste0(year, "-", q * 3, "-",
                         ifelse(q %in% c(1, 4), "31",
                                ifelse(q == 2, "30", "30"))))
  )

# Fix end-of-quarter dates
quarters$end <- as.Date(ifelse(
  quarters$q == 1, paste0(quarters$year, "-03-31"),
  ifelse(quarters$q == 2, paste0(quarters$year, "-06-30"),
         ifelse(quarters$q == 3, paste0(quarters$year, "-09-30"),
                paste0(quarters$year, "-12-31")))
), origin = "1970-01-01")

cat(sprintf("Fetching Ch13 cases from %d courts × %d quarters = %d API calls\n",
            length(courts), nrow(quarters), length(courts) * nrow(quarters)))

# Function to fetch one page of CourtListener results
fetch_cl_page <- function(court_id, date_start, date_end, page_size = 20) {
  url <- "https://www.courtlistener.com/api/rest/v4/search/"
  resp <- GET(url, query = list(
    q = "chapter 13",
    type = "r",
    court = court_id,
    filed_after = format(date_start, "%Y-%m-%d"),
    filed_before = format(date_end, "%Y-%m-%d"),
    page_size = page_size
  ))

  if (status_code(resp) == 429) {
    cat("  Rate limited, waiting 10s...\n")
    Sys.sleep(10)
    resp <- GET(url, query = list(
      q = "chapter 13",
      type = "r",
      court = court_id,
      filed_after = format(date_start, "%Y-%m-%d"),
      filed_before = format(date_end, "%Y-%m-%d"),
      page_size = page_size
    ))
  }

  if (status_code(resp) != 200) {
    warning(sprintf("API error %d for %s %s-%s",
                    status_code(resp), court_id,
                    date_start, date_end))
    return(NULL)
  }

  content <- content(resp, as = "parsed", simplifyVector = TRUE)

  if (length(content$results) == 0) return(NULL)

  results <- content$results
  tibble(
    court_id = court_id,
    case_name = results$caseName,
    docket_number = results$docketNumber,
    judge_name = results$assignedTo,
    judge_id = results$assigned_to_id,
    date_filed = as.Date(results$dateFiled),
    date_terminated = as.Date(results$dateTerminated),
    total_in_quarter = content$count
  )
}

# Fetch data for all courts × quarters
all_cases <- list()
call_count <- 0
total_calls <- length(courts) * nrow(quarters)

for (ct in courts) {
  for (i in seq_len(nrow(quarters))) {
    call_count <- call_count + 1
    if (call_count %% 50 == 0) {
      cat(sprintf("  Progress: %d/%d calls (%.0f%%)\n",
                  call_count, total_calls, 100 * call_count / total_calls))
    }

    result <- tryCatch(
      fetch_cl_page(ct, quarters$start[i], quarters$end[i]),
      error = function(e) {
        warning(sprintf("Error for %s Q%d %d: %s",
                        ct, quarters$q[i], quarters$year[i], e$message))
        NULL
      }
    )

    if (!is.null(result)) {
      all_cases[[length(all_cases) + 1]] <- result
    }

    # Rate limiting: 0.6s between calls
    Sys.sleep(0.6)
  }
}

cases_df <- bind_rows(all_cases)
stopifnot("No cases fetched — CourtListener API may be down" = nrow(cases_df) > 0)

cat(sprintf("\nFetched %d cases from CourtListener across %d courts\n",
            nrow(cases_df), n_distinct(cases_df$court_id)))
cat(sprintf("Unique judges: %d\n", n_distinct(cases_df$judge_name, na.rm = TRUE)))
cat(sprintf("Date range: %s to %s\n",
            min(cases_df$date_filed, na.rm = TRUE),
            max(cases_df$date_filed, na.rm = TRUE)))

# Save raw bankruptcy data
fwrite(cases_df, file.path(DATA_DIR, "courtlistener_ch13_cases.csv"))
cat("Saved courtlistener_ch13_cases.csv\n")


# -----------------------------------------------------------------------
# 2. Census BFS: State-level business applications (monthly)
# -----------------------------------------------------------------------

census_key <- Sys.getenv("CENSUS_API_KEY")
key_param <- ifelse(nchar(census_key) > 0, paste0("&key=", census_key), "")

# States covered by our courts
state_fips <- unique(court_info$state_fips)

cat(sprintf("\nFetching Census BFS data for %d states...\n", length(state_fips)))

# BFS time series API
# Available variables: BA_BA (business applications), BA_HBA (high-propensity),
# BA_WBA (with planned wages)
bfs_list <- list()

for (st in state_fips) {
  url <- sprintf(
    "https://api.census.gov/data/timeseries/eits/bfs?get=BA_BA,BA_HBA,BA_WBA&for=state:%s&time=from+2010-01+to+2022-12%s",
    st, key_param
  )

  resp <- tryCatch({
    GET(url, timeout(30))
  }, error = function(e) {
    warning(sprintf("BFS API error for state %s: %s", st, e$message))
    NULL
  })

  if (is.null(resp) || status_code(resp) != 200) {
    # Try alternative: year-by-year
    cat(sprintf("  BFS bulk query failed for state %s, trying year-by-year...\n", st))
    for (yr in 2010:2022) {
      for (mn in 1:12) {
        time_str <- sprintf("%d-%02d", yr, mn)
        url2 <- sprintf(
          "https://api.census.gov/data/timeseries/eits/bfs?get=BA_BA,BA_HBA,BA_WBA&for=state:%s&time=%s%s",
          st, time_str, key_param
        )
        resp2 <- tryCatch(GET(url2, timeout(15)), error = function(e) NULL)
        if (!is.null(resp2) && status_code(resp2) == 200) {
          parsed <- content(resp2, as = "text", encoding = "UTF-8")
          df <- tryCatch(fromJSON(parsed), error = function(e) NULL)
          if (!is.null(df) && nrow(df) > 1) {
            header <- df[1, ]
            vals <- df[-1, , drop = FALSE]
            colnames(vals) <- header
            bfs_list[[length(bfs_list) + 1]] <- as.data.frame(vals)
          }
        }
        Sys.sleep(0.1)
      }
    }
    next
  }

  parsed <- content(resp, as = "text", encoding = "UTF-8")
  df <- tryCatch(fromJSON(parsed), error = function(e) NULL)
  if (!is.null(df) && nrow(df) > 1) {
    header <- df[1, ]
    vals <- df[-1, , drop = FALSE]
    colnames(vals) <- header
    bfs_list[[length(bfs_list) + 1]] <- as.data.frame(vals)
    cat(sprintf("  State %s: %d months of BFS data\n", st, nrow(vals)))
  }

  Sys.sleep(0.3)
}

if (length(bfs_list) > 0) {
  bfs_df <- bind_rows(bfs_list)
  bfs_df <- bfs_df %>%
    mutate(
      BA_BA = as.numeric(BA_BA),
      BA_HBA = as.numeric(BA_HBA),
      BA_WBA = as.numeric(BA_WBA),
      state_fips = state,
      year = as.integer(substr(time, 1, 4)),
      month = as.integer(substr(time, 6, 7))
    )

  fwrite(bfs_df, file.path(DATA_DIR, "census_bfs_state_monthly.csv"))
  cat(sprintf("\nSaved census_bfs_state_monthly.csv (%d rows)\n", nrow(bfs_df)))
} else {
  stop("FATAL: No BFS data fetched. Cannot proceed without outcome data.")
}


# -----------------------------------------------------------------------
# 3. Census BDS: Annual state-level firm births (supplementary outcome)
# -----------------------------------------------------------------------

cat("\nFetching Census BDS data (annual firm births)...\n")

bds_list <- list()

for (yr in 2010:2021) {
  url <- sprintf(
    "https://api.census.gov/data/timeseries/bds/firms?get=FIRM,FIRMDEATH_FIRM,ESTAB,ESTAB_ENTRY_RATE,ESTAB_EXIT_RATE&for=state:%s&YEAR=%d%s",
    paste(state_fips, collapse = ","), yr, key_param
  )

  # BDS might need individual state calls
  for (st in state_fips) {
    url_st <- sprintf(
      "https://api.census.gov/data/timeseries/bds/firms?get=FIRM,FIRMDEATH_FIRM,ESTAB,ESTAB_ENTRY_RATE,ESTAB_EXIT_RATE&for=state:%s&YEAR=%d%s",
      st, yr, key_param
    )

    resp <- tryCatch(GET(url_st, timeout(15)), error = function(e) NULL)
    if (!is.null(resp) && status_code(resp) == 200) {
      parsed <- content(resp, as = "text", encoding = "UTF-8")
      df <- tryCatch(fromJSON(parsed), error = function(e) NULL)
      if (!is.null(df) && nrow(df) > 1) {
        header <- df[1, ]
        vals <- df[-1, , drop = FALSE]
        colnames(vals) <- header
        bds_list[[length(bds_list) + 1]] <- as.data.frame(vals)
      }
    }
    Sys.sleep(0.2)
  }
}

if (length(bds_list) > 0) {
  bds_df <- bind_rows(bds_list)
  bds_df <- bds_df %>%
    mutate(across(c(FIRM, FIRMDEATH_FIRM, ESTAB), as.numeric),
           ESTAB_ENTRY_RATE = as.numeric(ESTAB_ENTRY_RATE),
           ESTAB_EXIT_RATE = as.numeric(ESTAB_EXIT_RATE),
           state_fips = state,
           year = as.integer(YEAR))

  fwrite(bds_df, file.path(DATA_DIR, "census_bds_state_annual.csv"))
  cat(sprintf("Saved census_bds_state_annual.csv (%d rows)\n", nrow(bds_df)))
}


# -----------------------------------------------------------------------
# 4. Summary statistics
# -----------------------------------------------------------------------

cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("Bankruptcy cases: %d\n", nrow(cases_df)))
cat(sprintf("Courts: %d\n", n_distinct(cases_df$court_id)))
cat(sprintf("Unique judges: %d\n", n_distinct(cases_df$judge_name, na.rm = TRUE)))
if (exists("bfs_df")) {
  cat(sprintf("BFS observations: %d\n", nrow(bfs_df)))
}
if (exists("bds_df")) {
  cat(sprintf("BDS observations: %d\n", nrow(bds_df)))
}
cat("=== Data fetch complete ===\n")
