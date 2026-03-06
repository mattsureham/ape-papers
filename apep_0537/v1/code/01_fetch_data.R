## 01_fetch_data.R — Fetch all data sources for apep_0537
## GenAI as Seniority-Biased Technological Change

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Load .env file for API keys
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  env_lines <- readLines(env_file, warn = FALSE)
  env_lines <- env_lines[!grepl("^#|^\\s*$", env_lines)]
  for (line in env_lines) {
    if (!grepl("=", line)) next
    eq_pos <- regexpr("=", line)
    key <- trimws(substr(line, 1, eq_pos - 1))
    val <- trimws(substr(line, eq_pos + 1, nchar(line)))
    val <- gsub("^['\"]|['\"]$", "", val)
    if (nchar(key) > 0) {
      args <- list(val)
      names(args) <- key
      do.call(Sys.setenv, args)
    }
  }
  cat("  Loaded .env file\n")
}

# ===========================================================================
# 1. SEC EDGAR EFTS: GenAI mentions in 10-K filings
# ===========================================================================
cat("\n=== Fetching SEC EDGAR GenAI mentions ===\n")

# Use simpler queries to avoid encoding issues, fetch separately and union
search_terms <- c(
  '%22generative+AI%22',
  '%22generative+artificial+intelligence%22',
  '%22large+language+model%22',
  '%22ChatGPT%22'
)

edgar_all <- list()

for (term in search_terms) {
  for (year in 2018:2025) {
    url <- sprintf(
      "https://efts.sec.gov/LATEST/search-index?q=%s&forms=10-K,10-K/A&dateRange=custom&startdt=%d-01-01&enddt=%d-12-31&from=0&size=200",
      term, year, year
    )

    tryCatch({
      resp <- GET(url, add_headers(`User-Agent` = "APEP Research apep@research.org"))
      if (status_code(resp) != 200) next

      parsed <- content(resp, as = "parsed")
      total_hits <- parsed$hits$total$value
      if (total_hits == 0) next

      # Extract hits
      hits <- lapply(parsed$hits$hits, function(h) {
        data.frame(
          cik = paste(h$`_source`$ciks, collapse = ";"),
          sic = paste(h$`_source`$sics, collapse = ";"),
          file_date = h$`_source`$file_date %||% NA,
          display_name = paste(h$`_source`$display_names, collapse = ";"),
          stringsAsFactors = FALSE
        )
      })

      batch <- bind_rows(hits) %>% mutate(year = year, search_term = term)
      edgar_all[[paste(term, year)]] <- batch

      # Paginate if needed
      if (total_hits > 200) {
        for (pg in 1:min(ceiling(total_hits / 200) - 1, 49)) {
          Sys.sleep(0.15)
          url_pg <- sprintf(
            "https://efts.sec.gov/LATEST/search-index?q=%s&forms=10-K,10-K/A&dateRange=custom&startdt=%d-01-01&enddt=%d-12-31&from=%d&size=200",
            term, year, year, pg * 200
          )
          resp_pg <- GET(url_pg, add_headers(`User-Agent` = "APEP Research apep@research.org"))
          if (status_code(resp_pg) == 200) {
            parsed_pg <- content(resp_pg, as = "parsed")
            hits_pg <- lapply(parsed_pg$hits$hits, function(h) {
              data.frame(
                cik = paste(h$`_source`$ciks, collapse = ";"),
                sic = paste(h$`_source`$sics, collapse = ";"),
                file_date = h$`_source`$file_date %||% NA,
                display_name = paste(h$`_source`$display_names, collapse = ";"),
                stringsAsFactors = FALSE
              )
            })
            if (length(hits_pg) > 0) {
              edgar_all[[paste(term, year, pg)]] <- bind_rows(hits_pg) %>%
                mutate(year = year, search_term = term)
            }
          }
        }
      }

      cat(sprintf("    %s | %d: %d hits\n", gsub("%22|%2B", "", term), year, total_hits))
    }, error = function(e) {
      warning(sprintf("EDGAR error: %s", e$message))
    })

    Sys.sleep(0.15)
  }
}

if (length(edgar_all) == 0) {
  stop("EDGAR data fetch failed completely.\nPivot research question or fix the source.")
}

edgar_df <- bind_rows(edgar_all) %>%
  distinct(cik, file_date, .keep_all = TRUE) %>%
  mutate(
    sic_2d = substr(sic, 1, 2),
    filing_quarter = quarter(as.Date(file_date)),
    filing_year = year(as.Date(file_date))
  )

cat(sprintf("\nTotal EDGAR GenAI filings (deduplicated): %d across years %d-%d\n",
            nrow(edgar_df), min(edgar_df$filing_year, na.rm = TRUE),
            max(edgar_df$filing_year, na.rm = TRUE)))

# Count by year
edgar_by_year <- edgar_df %>% count(filing_year, name = "n_filings")
cat("  By year:\n")
for (i in seq_len(nrow(edgar_by_year))) {
  cat(sprintf("    %d: %d filings\n", edgar_by_year$filing_year[i], edgar_by_year$n_filings[i]))
}

fwrite(edgar_df, file.path(data_dir, "edgar_genai_filings.csv"))
cat("  Saved edgar_genai_filings.csv\n")

# ===========================================================================
# 2. BLS QCEW: Quarterly employment by industry (national, area=US000)
# ===========================================================================
cat("\n=== Fetching BLS QCEW data ===\n")

qcew_list <- list()

for (yr in 2015:2024) {
  for (qtr in 1:4) {
    url <- sprintf("https://data.bls.gov/cew/data/api/%d/%d/area/US000.csv", yr, qtr)

    tryCatch({
      resp <- GET(url, add_headers(`User-Agent` = "APEP Research apep@research.org"))
      if (status_code(resp) != 200) {
        warning(sprintf("QCEW API failed for %d Q%d (HTTP %d)", yr, qtr, status_code(resp)))
        next
      }

      tmp <- tempfile(fileext = ".csv")
      writeBin(content(resp, "raw"), tmp)
      df_qtr <- fread(tmp, showProgress = FALSE)
      df_qtr$year <- yr
      df_qtr$quarter <- qtr
      qcew_list[[paste(yr, qtr, sep = "_")]] <- df_qtr
      unlink(tmp)
    }, error = function(e) {
      warning(sprintf("QCEW error %d Q%d: %s", yr, qtr, e$message))
    })

    Sys.sleep(0.1)
  }
  cat(sprintf("  %d: done\n", yr))
}

if (length(qcew_list) == 0) {
  stop("QCEW data fetch failed completely.\nPivot research question or fix the source.")
}

qcew_raw <- rbindlist(qcew_list, fill = TRUE)
cat(sprintf("  QCEW raw: %d rows, %d year-quarters\n",
            nrow(qcew_raw), n_distinct(paste(qcew_raw$year, qcew_raw$quarter))))

fwrite(qcew_raw, file.path(data_dir, "qcew_raw.csv"))
cat("  Saved qcew_raw.csv\n")

# ===========================================================================
# 3. BLS OEWS: Occupation x industry employment (research estimates)
# ===========================================================================
cat("\n=== Fetching BLS OEWS data ===\n")

# Use the research estimates which have occupation x industry detail
# Available from 2012 onwards. URL pattern changes by year.
oews_list <- list()

for (yr in 2015:2024) {
  yr_short <- substr(as.character(yr), 3, 4)

  # Try research estimates first (occupation x industry x state)
  url <- sprintf("https://www.bls.gov/oes/special-requests/oesm%sall.zip", yr_short)

  cat(sprintf("  Fetching OEWS %d...\n", yr))

  tryCatch({
    tmp_zip <- tempfile(fileext = ".zip")
    resp <- GET(url, add_headers(`User-Agent` = "APEP Research apep@research.org"),
                write_disk(tmp_zip, overwrite = TRUE), timeout(120))

    if (status_code(resp) != 200) {
      # Try national only
      url2 <- sprintf("https://www.bls.gov/oes/special-requests/oesm%snat.zip", yr_short)
      resp <- GET(url2, add_headers(`User-Agent` = "APEP Research apep@research.org"),
                  write_disk(tmp_zip, overwrite = TRUE), timeout(120))
      if (status_code(resp) != 200) {
        warning(sprintf("OEWS download failed for %d", yr))
        next
      }
    }

    tmp_dir <- file.path(tempdir(), paste0("oews_", yr))
    dir.create(tmp_dir, showWarnings = FALSE)
    unzip(tmp_zip, exdir = tmp_dir)

    # Find data files - prefer CSV/TXT, then Excel
    all_files <- list.files(tmp_dir, recursive = TRUE, full.names = TRUE)
    data_files <- all_files[grepl("\\.(xlsx|xls|csv|txt)$", all_files, ignore.case = TRUE)]

    # Prefer the "all_data" or "nat" file with the most rows
    best_file <- NULL
    best_rows <- 0

    for (f in data_files) {
      tryCatch({
        if (grepl("\\.csv$|\\.txt$", f, ignore.case = TRUE)) {
          test <- fread(f, nrows = 5, showProgress = FALSE)
        } else {
          test <- as.data.table(read_excel(f, n_max = 5))
        }
        if (nrow(test) > 0 && ncol(test) > 5) {
          # Count full rows
          if (grepl("\\.csv$|\\.txt$", f, ignore.case = TRUE)) {
            full <- fread(f, showProgress = FALSE)
          } else {
            full <- as.data.table(read_excel(f, guess_max = 100000))
          }
          if (nrow(full) > best_rows) {
            best_rows <- nrow(full)
            best_file <- f
          }
        }
      }, error = function(e) NULL)
    }

    if (!is.null(best_file) && best_rows > 100) {
      if (grepl("\\.csv$|\\.txt$", best_file, ignore.case = TRUE)) {
        df_oews <- fread(best_file, showProgress = FALSE)
      } else {
        df_oews <- as.data.table(read_excel(best_file, guess_max = 200000))
      }
      df_oews$oews_year <- yr
      oews_list[[as.character(yr)]] <- df_oews
      cat(sprintf("    %d: %d rows, %d columns\n", yr, nrow(df_oews), ncol(df_oews)))
    } else {
      warning(sprintf("No usable OEWS data file found for %d (best had %d rows)", yr, best_rows))
    }

    unlink(tmp_zip)
    unlink(tmp_dir, recursive = TRUE)
  }, error = function(e) {
    warning(sprintf("OEWS error for %d: %s", yr, e$message))
  })

  Sys.sleep(0.5)
}

if (length(oews_list) == 0) {
  stop("OEWS data fetch failed completely.\nPivot research question or fix the source.")
}

# Harmonize column names across years
oews_raw <- rbindlist(oews_list, fill = TRUE)
cat(sprintf("  OEWS raw: %d rows across %d years\n",
            nrow(oews_raw), n_distinct(oews_raw$oews_year)))

fwrite(oews_raw, file.path(data_dir, "oews_raw.csv"))
cat("  Saved oews_raw.csv\n")

# ===========================================================================
# 4. O*NET Job Zone data
# ===========================================================================
cat("\n=== Fetching O*NET Job Zone data ===\n")

onet_url <- "https://www.onetcenter.org/dl_files/database/db_29_0_text.zip"
tmp_onet <- tempfile(fileext = ".zip")

tryCatch({
  resp <- GET(onet_url, write_disk(tmp_onet, overwrite = TRUE),
              add_headers(`User-Agent` = "APEP Research apep@research.org"),
              timeout(120))

  if (status_code(resp) != 200) {
    stop(sprintf("O*NET download failed (HTTP %d)", status_code(resp)))
  }

  tmp_onet_dir <- file.path(tempdir(), "onet")
  dir.create(tmp_onet_dir, showWarnings = FALSE)
  unzip(tmp_onet, exdir = tmp_onet_dir)

  jz_file <- list.files(tmp_onet_dir, pattern = "Job.Zones", full.names = TRUE, recursive = TRUE)
  if (length(jz_file) == 0) stop("Job Zones file not found in O*NET download")

  job_zones <- fread(jz_file[1])
  cat(sprintf("  O*NET Job Zones: %d occupations\n", nrow(job_zones)))
  fwrite(job_zones, file.path(data_dir, "onet_job_zones.csv"))

  # Work Activities for physical task classification
  wa_file <- list.files(tmp_onet_dir, pattern = "Work.Activities", full.names = TRUE, recursive = TRUE)
  if (length(wa_file) > 0) {
    work_activities <- fread(wa_file[1])
    fwrite(work_activities, file.path(data_dir, "onet_work_activities.csv"))
    cat(sprintf("  O*NET Work Activities: %d rows\n", nrow(work_activities)))
  }

  # Work Context for manual/physical classification
  wc_file <- list.files(tmp_onet_dir, pattern = "Work.Context", full.names = TRUE, recursive = TRUE)
  if (length(wc_file) > 0) {
    work_context <- fread(wc_file[1])
    fwrite(work_context, file.path(data_dir, "onet_work_context.csv"))
    cat(sprintf("  O*NET Work Context: %d rows\n", nrow(work_context)))
  }

  unlink(tmp_onet)
  unlink(tmp_onet_dir, recursive = TRUE)
}, error = function(e) {
  stop(sprintf("O*NET fetch failed: %s\nPivot research question or fix the source.", e$message))
})

# ===========================================================================
# 5. Felten-Raj-Seamans AIOE scores
# ===========================================================================
cat("\n=== Fetching AIOE scores ===\n")

aioe_url <- "https://raw.githubusercontent.com/AIOE-Data/AIOE/main/AIOE_DataAppendix.xlsx"

tryCatch({
  tmp_aioe <- tempfile(fileext = ".xlsx")
  resp <- GET(aioe_url, write_disk(tmp_aioe, overwrite = TRUE))

  if (status_code(resp) != 200) {
    stop(sprintf("AIOE download failed (HTTP %d)", status_code(resp)))
  }

  sheets <- excel_sheets(tmp_aioe)
  cat(sprintf("  AIOE sheets: %s\n", paste(sheets, collapse = ", ")))

  # Read each sheet to find occupation-level scores
  for (sh in sheets) {
    df_sh <- read_excel(tmp_aioe, sheet = sh, n_max = 5)
    cat(sprintf("    Sheet '%s': %d cols, headers: %s\n",
                sh, ncol(df_sh), paste(names(df_sh)[1:min(5, ncol(df_sh))], collapse = ", ")))
  }

  # Read the sheet with SOC codes and AIOE scores
  # Usually Appendix A has the occupation-level data
  aioe_occ <- read_excel(tmp_aioe, sheet = "Appendix A")
  cat(sprintf("  AIOE Appendix A: %d rows, %d cols\n", nrow(aioe_occ), ncol(aioe_occ)))
  fwrite(as.data.table(aioe_occ), file.path(data_dir, "aioe_scores.csv"))
  cat("  Saved aioe_scores.csv\n")

  unlink(tmp_aioe)
}, error = function(e) {
  warning(sprintf("AIOE fetch failed: %s — will construct alternative exposure measure", e$message))
})

# ===========================================================================
# 6. FRED: Macro controls
# ===========================================================================
cat("\n=== Fetching FRED macro controls ===\n")

fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) == 0) {
  warning("FRED_API_KEY not set — fetching FRED via direct CSV download instead")
  # Fallback: download FRED data as CSV
  fred_series_urls <- c(
    UNRATE = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=UNRATE&cosd=2015-01-01&coed=2025-12-31",
    FEDFUNDS = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=FEDFUNDS&cosd=2015-01-01&coed=2025-12-31",
    CPIAUCSL = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCSL&cosd=2015-01-01&coed=2025-12-31"
  )

  fred_list <- list()
  for (nm in names(fred_series_urls)) {
    tryCatch({
      df <- fread(fred_series_urls[[nm]])
      names(df) <- c("date", "value")
      df$series <- nm
      fred_list[[nm]] <- df
    }, error = function(e) warning(sprintf("FRED CSV fallback failed for %s", nm)))
  }

  if (length(fred_list) > 0) {
    fred_df <- rbindlist(fred_list)
    fwrite(fred_df, file.path(data_dir, "fred_controls.csv"))
    cat(sprintf("  FRED (CSV fallback): %d observations\n", nrow(fred_df)))
  }
} else {
  fred_series <- c("UNRATE", "FEDFUNDS", "CPIAUCSL", "PAYEMS", "VIXCLS")
  fred_list <- list()

  for (s in fred_series) {
    url <- sprintf(
      "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2015-01-01&observation_end=2025-12-31",
      s, fred_key
    )

    tryCatch({
      resp <- GET(url)
      if (status_code(resp) == 200) {
        parsed <- content(resp, as = "parsed")
        obs <- lapply(parsed$observations, function(o) {
          data.frame(date = o$date, value = as.numeric(o$value), series = s,
                     stringsAsFactors = FALSE)
        })
        fred_list[[s]] <- bind_rows(obs)
      }
    }, error = function(e) warning(sprintf("FRED error for %s: %s", s, e$message)))
    Sys.sleep(0.2)
  }

  fred_df <- bind_rows(fred_list)
  fwrite(fred_df, file.path(data_dir, "fred_controls.csv"))
  cat(sprintf("  FRED: %d observations across %d series\n", nrow(fred_df), n_distinct(fred_df$series)))
}

# ===========================================================================
# 7. CPS via Census API (employment by age group)
# ===========================================================================
cat("\n=== Fetching CPS/ACS data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  cat("  CENSUS_API_KEY not set — skipping CPS. Will use QCEW + OEWS.\n")
} else {
  cps_list <- list()

  for (yr in 2015:2023) {
    # ACS 1-year: Employment status by age (B23001)
    # Get total population, total in labor force, and employed by age groups
    url <- sprintf(
      "https://api.census.gov/data/%d/acs/acs1?get=NAME,B23001_001E,B23001_003E,B23001_010E,B23001_017E,B23001_024E,B23001_031E,B23001_038E,B23001_045E,B23001_052E,B23001_059E,B23001_066E,B23001_073E&for=state:*&key=%s",
      yr, census_key
    )

    tryCatch({
      resp <- GET(url)
      if (status_code(resp) == 200) {
        parsed <- content(resp, as = "text", encoding = "UTF-8")
        df_cps <- fread(text = parsed)
        names(df_cps) <- as.character(df_cps[1, ])
        df_cps <- df_cps[-1, ]
        df_cps$year <- yr
        cps_list[[as.character(yr)]] <- df_cps
        cat(sprintf("    %d: %d states\n", yr, nrow(df_cps)))
      }
    }, error = function(e) warning(sprintf("CPS error for %d: %s", yr, e$message)))

    Sys.sleep(0.3)
  }

  if (length(cps_list) > 0) {
    cps_raw <- rbindlist(cps_list, fill = TRUE)
    fwrite(cps_raw, file.path(data_dir, "acs_age_employment.csv"))
    cat(sprintf("  Saved acs_age_employment.csv: %d rows\n", nrow(cps_raw)))
  }
}

# ===========================================================================
# DATA VALIDATION (required)
# ===========================================================================
cat("\n=== Data Validation ===\n")

stopifnot("EDGAR data has GenAI filings" = nrow(edgar_df) >= 10)
cat(sprintf("  EDGAR: %d filings ✓\n", nrow(edgar_df)))

stopifnot("QCEW has data" = nrow(qcew_raw) > 10000)
cat(sprintf("  QCEW: %d rows, %d year-quarters ✓\n",
            nrow(qcew_raw), n_distinct(paste(qcew_raw$year, qcew_raw$quarter))))

stopifnot("OEWS has data" = nrow(oews_raw) > 1000)
cat(sprintf("  OEWS: %d rows across %d years ✓\n",
            nrow(oews_raw), n_distinct(oews_raw$oews_year)))

jz_check <- fread(file.path(data_dir, "onet_job_zones.csv"))
stopifnot("O*NET Job Zones covers 800+ occupations" = nrow(jz_check) >= 800)
cat(sprintf("  O*NET Job Zones: %d occupations ✓\n", nrow(jz_check)))

cat("\n=== All data fetched and validated ===\n")
