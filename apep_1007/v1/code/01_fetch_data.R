## 01_fetch_data.R — Fetch data from Eurostat, World Bank, ECB
## apep_1007: Banking the Unbanked by Mandate

source("00_packages.R")

eu27 <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI",
          "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU",
          "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE")

# ---- 1. Transposition dates ----
cat("=== 1. PAD transposition dates ===\n")

transposition_dates <- data.table(
  country_code = eu27,
  country_name = c("Austria", "Belgium", "Bulgaria", "Croatia", "Cyprus",
                    "Czech Republic", "Denmark", "Estonia", "Finland",
                    "France", "Germany", "Greece", "Hungary", "Ireland",
                    "Italy", "Latvia", "Lithuania", "Luxembourg",
                    "Malta", "Netherlands", "Poland", "Portugal",
                    "Romania", "Slovakia", "Slovenia", "Spain", "Sweden"),
  transposition_date = as.Date(c(
    "2016-09-15", "2016-10-01", "2016-12-15", "2017-01-15", "2017-06-01",
    NA, "2016-06-01", "2017-01-20", "2017-01-01",
    "2015-08-07", "2016-06-18", "2017-04-15", NA, "2016-09-18",
    "2017-03-22", "2016-11-01", "2016-09-01", "2017-05-01",
    "2016-09-18", "2016-11-25", "2016-08-08", "2017-10-01",
    "2017-12-28", NA, NA, "2017-11-25", "2017-06-01"
  )),
  pre_existing_law = c(
    FALSE, FALSE, FALSE, FALSE, FALSE,
    TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
    TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE,
    TRUE, TRUE, FALSE, FALSE
  )
)

transposition_dates[!is.na(transposition_date), treatment_year := year(transposition_date)]
transposition_dates[pre_existing_law == TRUE, treatment_year := NA_integer_]
cat("  Treated:", sum(!is.na(transposition_dates$treatment_year)),
    "| Never-treated:", sum(transposition_dates$pre_existing_law), "\n")
fwrite(transposition_dates, "../data/transposition_dates.csv")

# ---- 2. Eurostat JSON-stat API: Internet banking ----
cat("\n=== 2. Eurostat: Internet banking (JSON-stat API) ===\n")

# Direct JSON-stat 2.0 endpoint — most reliable method
# Dataset: isoc_ci_ac_i (Internet activities by individuals)
# Indicator: I_IUBK (Internet banking)
json_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "isoc_ci_ac_i?",
  "indic_is=I_IUBK&ind_type=IND_TOTAL&unit=PC_IND&",
  "geo=", paste(eu27, collapse = "&geo=")
)

ibank_clean <- NULL

resp <- tryCatch(httr::GET(json_url, httr::timeout(120)), error = function(e) NULL)

if (!is.null(resp) && httr::status_code(resp) == 200) {
  json_raw <- httr::content(resp, "text", encoding = "UTF-8")
  json_data <- jsonlite::fromJSON(json_raw)

  if ("value" %in% names(json_data) && "dimension" %in% names(json_data)) {
    dims <- json_data$dimension
    geo_cats <- dims$geo$category$index
    time_cats <- dims$time$category$index
    geo_codes <- names(geo_cats)
    time_codes <- names(time_cats)

    # Compute size of each dimension to map flat index to multi-dim
    dim_sizes <- sapply(json_data$id, function(d) length(json_data$dimension[[d]]$category$index))
    dim_names <- json_data$id

    vals <- json_data$value
    rows <- list()

    # The flat index follows row-major order across dimensions
    # For each value in the flat map, compute the position in each dimension
    total_size <- prod(dim_sizes)
    geo_dim_idx <- which(dim_names == "geo")
    time_dim_idx <- which(dim_names == "time")

    for (flat_idx_str in names(vals)) {
      flat_idx <- as.integer(flat_idx_str)
      # Compute multi-dimensional indices
      remaining <- flat_idx
      multi_idx <- integer(length(dim_sizes))
      for (d in length(dim_sizes):1) {
        multi_idx[d] <- remaining %% dim_sizes[d]
        remaining <- remaining %/% dim_sizes[d]
      }

      geo_val <- geo_codes[multi_idx[geo_dim_idx] + 1]
      time_val <- time_codes[multi_idx[time_dim_idx] + 1]

      rows[[length(rows) + 1]] <- data.table(
        country_code = toupper(geo_val),
        year = as.integer(time_val),
        internet_banking_pct = as.numeric(vals[[flat_idx_str]])
      )
    }

    if (length(rows) > 0) {
      ibank_clean <- rbindlist(rows)
      ibank_clean <- ibank_clean[country_code %in% eu27 & !is.na(internet_banking_pct)]
      cat("  Internet banking from JSON-stat:", nrow(ibank_clean), "obs,",
          uniqueN(ibank_clean$country_code), "countries\n")
      cat("  Year range:", range(ibank_clean$year), "\n")
    }
  }
} else {
  cat("  JSON-stat API returned status:", ifelse(is.null(resp), "connection failed",
                                                   httr::status_code(resp)), "\n")
}

# Fallback: try eurostat R package with isoc_ci_ac_i
if (is.null(ibank_clean) || nrow(ibank_clean) < 50) {
  cat("  Trying eurostat R package for isoc_ci_ac_i...\n")
  raw <- tryCatch({
    as.data.table(eurostat::get_eurostat("isoc_ci_ac_i", time_format = "num"))
  }, error = function(e) {
    cat("    Failed:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(raw) && nrow(raw) > 0) {
    cat("    Raw data:", nrow(raw), "rows. Columns:", paste(names(raw), collapse = ", "), "\n")
    # The time column from eurostat package is named "time" but it's numeric
    time_col <- intersect(c("time", "TIME_PERIOD", "time_period"), names(raw))
    if (length(time_col) > 0) {
      setnames(raw, time_col[1], "time_val")
    }
    filt <- raw[indic_is == "I_IUBK" & ind_type == "IND_TOTAL" & unit == "PC_IND"]
    if (nrow(filt) > 0) {
      ibank_clean <- filt[, .(country_code = toupper(geo),
                               year = as.integer(time_val),
                               internet_banking_pct = values)]
      ibank_clean <- ibank_clean[country_code %in% eu27]
      cat("    Filtered:", nrow(ibank_clean), "obs\n")
    }
  }
}

if (!is.null(ibank_clean) && nrow(ibank_clean) > 0) {
  fwrite(ibank_clean, "../data/eurostat_internet_banking.csv")
  cat("  Saved eurostat_internet_banking.csv\n")
} else {
  stop("FATAL: Cannot retrieve internet banking data from Eurostat. Cannot proceed.")
}

# ---- 3. World Bank Global Findex ----
cat("\n=== 3. Global Findex: Account ownership ===\n")

findex <- tryCatch({
  findex_raw <- WDI::WDI(
    indicator = c("account_pct" = "FX.OWN.TOTL.ZS"),
    country = eu27,
    start = 2011, end = 2024,
    extra = TRUE
  )
  dt <- as.data.table(findex_raw)[!is.na(account_pct)]
  dt[, country_code := iso2c]
  cat("  Findex:", nrow(dt), "obs,", uniqueN(dt$country_code), "countries\n")
  cat("  Years:", sort(unique(dt$year)), "\n")
  fwrite(dt[, .(country_code, country = country, year, account_pct)],
         "../data/findex.csv")
  dt
}, error = function(e) {
  cat("  WDI API failed:", conditionMessage(e), "\n")
  cat("  Fetching Findex directly from World Bank API...\n")

  # Direct JSON fetch from World Bank
  wdi_url <- paste0("https://api.worldbank.org/v2/en/country/all/indicator/",
                      "FX.OWN.TOTL.ZS?format=json&date=2011:2024&per_page=500")
  resp <- tryCatch(httr::GET(wdi_url, httr::timeout(120)), error = function(e2) NULL)

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    json <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    if (length(json) >= 2 && is.data.frame(json[[2]])) {
      df <- as.data.table(json[[2]])
      df <- df[!is.na(value) & countryiso3code != ""]
      # Map ISO3 to ISO2
      iso_map <- data.table(
        iso3 = c("AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN",
                  "FRA","DEU","GRC","HUN","IRL","ITA","LVA","LTU","LUX",
                  "MLT","NLD","POL","PRT","ROU","SVK","SVN","ESP","SWE"),
        iso2 = eu27
      )
      df <- merge(df, iso_map, by.x = "countryiso3code", by.y = "iso3")
      findex_dt <- df[, .(country_code = iso2, year = as.integer(date),
                           account_pct = as.numeric(value))]
      cat("  Direct WDI:", nrow(findex_dt), "obs\n")
      fwrite(findex_dt, "../data/findex.csv")
      return(findex_dt)
    }
  }

  cat("  Findex data unavailable — proceeding with Eurostat data only.\n")
  # Create minimal placeholder with NAs
  fwrite(data.table(country_code = character(), country = character(),
                     year = integer(), account_pct = numeric()),
         "../data/findex.csv")
  NULL
})

# ---- 4. Eurostat: Financial hardship ----
cat("\n=== 4. Financial hardship (ilc_mdes04) ===\n")

euro_expense <- tryCatch({
  dt <- as.data.table(eurostat::get_eurostat("ilc_mdes04", time_format = "num"))
  time_col <- intersect(c("time", "TIME_PERIOD", "time_period"), names(dt))
  if (length(time_col) > 0) setnames(dt, time_col[1], "time_val")
  if ("hhtyp" %in% names(dt)) dt <- dt[hhtyp == "TOTAL"]
  if ("incgrp" %in% names(dt)) dt <- dt[incgrp == "TOTAL"]
  if ("unit" %in% names(dt)) dt <- dt[unit == "PC"]
  dt[, .(country_code = toupper(geo), year = as.integer(time_val),
         unable_expense_pct = values)]
}, error = function(e) {
  cat("  Failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(euro_expense) && nrow(euro_expense) > 0) {
  euro_expense <- euro_expense[country_code %in% eu27 & !is.na(unable_expense_pct)]
  cat("  Hardship:", nrow(euro_expense), "obs,", uniqueN(euro_expense$country_code), "countries\n")
  fwrite(euro_expense, "../data/eurostat_financial_hardship.csv")
}

# ---- 5. Eurostat: Internet use (placebo) ----
cat("\n=== 5. Internet use placebo ===\n")

# Use general internet use (isoc_ci_ifp_iu or isoc_ci_ac_i with non-banking indicator)
placebo_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/",
  "isoc_ci_ac_i?",
  "indic_is=I_IUEM&ind_type=IND_TOTAL&unit=PC_IND&",
  "geo=", paste(eu27, collapse = "&geo=")
)

placebo_data <- NULL
resp_p <- tryCatch(httr::GET(placebo_url, httr::timeout(120)), error = function(e) NULL)

if (!is.null(resp_p) && httr::status_code(resp_p) == 200) {
  json_p <- jsonlite::fromJSON(httr::content(resp_p, "text", encoding = "UTF-8"))
  if ("value" %in% names(json_p)) {
    dims_p <- json_p$dimension
    geo_cats_p <- names(dims_p$geo$category$index)
    time_cats_p <- names(dims_p$time$category$index)
    dim_sizes_p <- sapply(json_p$id, function(d) length(json_p$dimension[[d]]$category$index))
    dim_names_p <- json_p$id
    geo_dim_p <- which(dim_names_p == "geo")
    time_dim_p <- which(dim_names_p == "time")
    vals_p <- json_p$value
    rows_p <- list()
    for (fi in names(vals_p)) {
      flat <- as.integer(fi)
      mi <- integer(length(dim_sizes_p))
      rem <- flat
      for (d in length(dim_sizes_p):1) {
        mi[d] <- rem %% dim_sizes_p[d]
        rem <- rem %/% dim_sizes_p[d]
      }
      rows_p[[length(rows_p) + 1]] <- data.table(
        country_code = toupper(geo_cats_p[mi[geo_dim_p] + 1]),
        year = as.integer(time_cats_p[mi[time_dim_p] + 1]),
        internet_info_pct = as.numeric(vals_p[[fi]])
      )
    }
    if (length(rows_p) > 0) {
      placebo_data <- rbindlist(rows_p)
      placebo_data <- placebo_data[country_code %in% eu27 & !is.na(internet_info_pct)]
      cat("  Placebo (email):", nrow(placebo_data), "obs\n")
      fwrite(placebo_data, "../data/eurostat_internet_info.csv")
    }
  }
}

if (is.null(placebo_data) || nrow(placebo_data) < 50) {
  cat("  Placebo fetch limited, skipping.\n")
}

# ---- 6. ECB MIR: Deposit rates ----
cat("\n=== 6. ECB MIR deposit rates ===\n")

mir_data <- list()
for (cc in eu27) {
  key <- paste0("M.", cc, ".B.L22.A.R.A.2240.EUR.N")
  url <- paste0("https://data-api.ecb.europa.eu/service/data/MIR/", key,
                 "?format=csvdata&startPeriod=2010&endPeriod=2024")
  tryCatch({
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      txt <- httr::content(resp, "text", encoding = "UTF-8")
      if (nchar(txt) > 100) {
        dt <- fread(text = txt)
        if (nrow(dt) > 0 && "OBS_VALUE" %in% names(dt)) {
          mir_data[[cc]] <- data.table(
            country_code = cc,
            year_month = dt$TIME_PERIOD,
            deposit_rate = as.numeric(dt$OBS_VALUE)
          )
        }
      }
    }
  }, error = function(e) NULL)
}

if (length(mir_data) > 0) {
  mir_dt <- rbindlist(mir_data)
  mir_dt[, year := as.integer(substr(year_month, 1, 4))]
  mir_dt[, month := as.integer(substr(year_month, 6, 7))]
  cat("  ECB MIR:", nrow(mir_dt), "obs,", uniqueN(mir_dt$country_code), "countries\n")
  fwrite(mir_dt, "../data/ecb_mir_deposits.csv")
}

cat("\n=== DATA FETCH COMPLETE ===\n")
list.files("../data/", pattern = "\\.csv$")
