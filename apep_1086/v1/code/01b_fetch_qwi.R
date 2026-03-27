# 01b_fetch_qwi.R — Fetch QWI manufacturing employment (batched by year)
# APEP Paper apep_1086

source("00_packages.R")

data_dir <- "../data/"

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("CENSUS_API_KEY not set")

state_fips <- sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))

# Batch years into groups of 5 to avoid URL length limits
year_batches <- list(
  "2001,2002,2003,2004,2005",
  "2006,2007,2008,2009,2010",
  "2011,2012,2013,2014,2015",
  "2016,2017,2018,2019,2020",
  "2021,2022,2023"
)

all_data <- list()
idx <- 0

for (st in state_fips) {
  cache_file <- file.path(data_dir, paste0("qwi_mfg_", st, ".rds"))
  if (file.exists(cache_file)) {
    idx <- idx + 1
    all_data[[idx]] <- readRDS(cache_file)
    next
  }

  st_data <- list()
  st_ok <- TRUE

  for (yb in year_batches) {
    qwi_url <- paste0(
      "https://api.census.gov/data/timeseries/qwi/se?",
      "get=Emp,EmpS,HirA,Sep,EarnHirAS",
      "&for=county:*",
      "&in=state:", st,
      "&industry=31-33",
      "&sex=0&agegrp=A00&race=A0&ethnicity=A0",
      "&firmage=0&firmsize=0&ownercode=A05",
      "&quarter=1",
      "&year=", yb,
      "&key=", census_key
    )

    resp <- tryCatch(
      GET(qwi_url, timeout(60)),
      error = function(e) NULL
    )

    if (is.null(resp) || resp$status_code != 200) next

    raw <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- tryCatch(fromJSON(raw), error = function(e) NULL)
    if (is.null(parsed) || length(parsed) < 2) next

    df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    st_data <- c(st_data, list(df))

    Sys.sleep(0.2)
  }

  if (length(st_data) > 0) {
    combined <- bind_rows(st_data)
    saveRDS(combined, cache_file)
    idx <- idx + 1
    all_data[[idx]] <- combined
    cat("State", st, ":", nrow(combined), "rows\n")
  } else {
    cat("State", st, ": no data\n")
  }
}

qwi <- bind_rows(all_data)
cat("\nTotal QWI rows:", format(nrow(qwi), big.mark = ","), "\n")
cat("States:", n_distinct(qwi$state), "\n")
cat("Counties:", n_distinct(paste0(qwi$state, qwi$county)), "\n")
cat("Years:", paste(sort(unique(qwi$year)), collapse = ", "), "\n")

saveRDS(qwi, file.path(data_dir, "qwi_manufacturing.rds"))
cat("Saved to qwi_manufacturing.rds\n")
