# ============================================================================
# apep_1201: When the Anchor Drops
# 01_fetch_data.R - Fetch raw FDIC and SNAP data
# ============================================================================

source("code/00_packages.R")

snap_zip_url <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
snap_zip_path <- "data/raw/snap-retailer-locator-data2005-2025.zip"
snap_csv_path <- "data/raw/Historical SNAP Retailer Locator Data 2005-2025.csv"
fdic_out_path <- "data/raw/fdic_sod_2010_2024.parquet"
snap_out_path <- "data/raw/snap_grocery_history.parquet"

if (!file.exists(snap_zip_path)) {
  resp <- request(snap_zip_url) |>
    req_perform(path = snap_zip_path)
  stopifnot(resp_status(resp) == 200L)
}

if (!file.exists(snap_csv_path)) {
  unzip(snap_zip_path, exdir = "data/raw")
}

stopifnot(file.exists(snap_csv_path))

if (!file.exists(fdic_out_path)) {
  years <- 2010:2024
  fdic_fields <- paste(
    c(
      "YEAR", "CERT", "BRNUM", "UNINUMBR", "NAMEBR", "STALPBR",
      "CNTYNUMB", "DEPSUMBR", "SIMS_LATITUDE", "SIMS_LONGITUDE"
    ),
    collapse = ","
  )

  fetch_fdic_year <- function(year_value) {
    year_dt <- vector("list", 0)
    offset <- 0L
    total <- NA_integer_

    repeat {
      req <- request("https://api.fdic.gov/banks/sod") |>
        req_url_query(
          fields = fdic_fields,
          filters = sprintf("YEAR:%d", year_value),
          sort_by = "UNINUMBR",
          sort_order = "ASC",
          limit = 10000,
          offset = offset,
          format = "json"
        )

      resp <- req_perform(req)
      stopifnot(resp_status(resp) == 200L)

      payload <- resp_body_json(resp, simplifyVector = TRUE)
      if (is.null(payload$data) || length(payload$data) == 0L) {
        break
      }

      if (is.na(total)) {
        total <- as.integer(payload$meta$total)
      }

      page_dt <- as.data.table(payload$data)
      setnames(page_dt, names(page_dt), sub("^data\\.", "", names(page_dt)))
      if ("score" %in% names(page_dt)) {
        page_dt[, score := NULL]
      }
      year_dt[[length(year_dt) + 1L]] <- page_dt
      offset <- offset + nrow(page_dt)

      cat(sprintf("FDIC year %d: %s / %s rows\n", year_value, format(offset, big.mark = ","), format(total, big.mark = ",")))

      if (offset >= total) {
        break
      }
    }

    out <- rbindlist(year_dt, fill = TRUE)
    out[, year := as.integer(YEAR)]
    out[, cert := as.integer(CERT)]
    out[, brnum := as.integer(BRNUM)]
    out[, branch_id := as.integer(UNINUMBR)]
    out[, bank_name := as.character(NAMEBR)]
    out[, state_abbr := as.character(STALPBR)]
    out[, county_code := as.integer(CNTYNUMB)]
    out[, county_id := sprintf("%s_%s", state_abbr, pad_county(county_code))]
    out[, deposits := as.numeric(DEPSUMBR)]
    out[, latitude := as.numeric(SIMS_LATITUDE)]
    out[, longitude := as.numeric(SIMS_LONGITUDE)]
    out <- out[
      !is.na(branch_id) &
      !is.na(latitude) &
      !is.na(longitude) &
      latitude != 0 &
      longitude != 0,
      .(year, cert, brnum, branch_id, bank_name, state_abbr, county_code, county_id, deposits, latitude, longitude)
    ]

    unique(out, by = c("year", "branch_id"))
  }

  fdic_all <- rbindlist(lapply(years, fetch_fdic_year), fill = TRUE)
  setorder(fdic_all, branch_id, year)
  safe_write_parquet(fdic_all, fdic_out_path)
}

if (!file.exists(snap_out_path)) {
  snap <- fread(
    snap_csv_path,
    select = c(
      "Record ID", "Store Name", "Store Type", "Street Number", "Street Name",
      "City", "State", "Zip Code", "County", "Latitude", "Longitude",
      "Authorization Date", "End Date"
    ),
    showProgress = TRUE
  )

  setnames(
    snap,
    old = names(snap),
    new = c(
      "record_id", "store_name", "store_type", "street_number", "street_name",
      "city", "state_abbr", "zip_code", "county_name", "latitude", "longitude",
      "authorization_date", "end_date"
    )
  )

  snap <- snap[
    store_type %chin% valid_store_types &
    !is.na(latitude) &
    !is.na(longitude) &
    latitude != 0 &
    longitude != 0
  ]

  snap[, authorization_date := mdy(authorization_date)]
  snap[, end_date := fifelse(trimws(end_date) == "", as.character(NA), end_date)]
  snap[, end_date := mdy(end_date)]
  snap[, store_name := str_squish(store_name)]
  snap[, city := str_squish(city)]
  snap[, street_name := str_squish(street_name)]
  snap[, county_name := str_squish(county_name)]
  snap[, zip_code := sprintf("%05d", as.integer(zip_code))]

  safe_write_parquet(snap, snap_out_path)
}

cat("Raw data fetch complete.\n")
