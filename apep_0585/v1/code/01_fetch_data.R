## 01_fetch_data.R — Data acquisition from Eurostat, FDA openFDA, and EUDAMED
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1) EUROSTAT — Annual Industrial Production Index (sts_inpr_a)
# ============================================================================

cat("=== Fetching Eurostat production indices ===\n")

fetch_eurostat_prod <- function(nace_code, label) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/sts_inpr_a",
    "?nace_r2=", nace_code,
    "&s_adj=NSA",
    "&unit=I21",
    "&sinceTimePeriod=2015",
    "&untilTimePeriod=2025",
    "&format=JSON&lang=en"
  )

  resp <- GET(url)
  if (status_code(resp) != 200) stop("Eurostat API failed for ", nace_code, ": HTTP ", status_code(resp))

  d <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)

  geo_idx <- d$dimension$geo$category$index
  time_idx <- d$dimension$time$category$index
  geo_labels <- d$dimension$geo$category$label
  values <- d$value

  n_time <- length(time_idx)

  rows <- list()
  for (geo in names(geo_idx)) {
    geo_pos <- geo_idx[[geo]]
    for (yr in names(time_idx)) {
      t_pos <- time_idx[[yr]]
      idx <- as.character(geo_pos * n_time + t_pos)
      if (!is.null(values[[idx]])) {
        rows <- c(rows, list(data.frame(
          geo = geo,
          geo_name = geo_labels[[geo]],
          year = as.integer(yr),
          nace = nace_code,
          nace_label = label,
          prod_index = values[[idx]],
          stringsAsFactors = FALSE
        )))
      }
    }
  }

  bind_rows(rows)
}

# Fetch treated and control sectors
sectors <- list(
  list(code = "C325", label = "Medical/dental instruments"),
  list(code = "C21",  label = "Pharmaceuticals"),
  list(code = "C265", label = "Measuring/testing instruments"),
  list(code = "C26",  label = "Computer/electronic/optical")
)

eurostat_prod <- bind_rows(lapply(sectors, function(s) {
  cat("  Fetching", s$code, "...\n")
  Sys.sleep(1)  # Be polite to Eurostat API
  fetch_eurostat_prod(s$code, s$label)
}))

cat("  Eurostat production index:", nrow(eurostat_prod), "observations\n")
cat("  Countries with C325 data:",
    paste(sort(unique(eurostat_prod$geo[eurostat_prod$nace == "C325"])), collapse = ", "), "\n")

fwrite(eurostat_prod, paste0(data_dir, "eurostat_prod_index.csv"))


# ============================================================================
# 2) EUROSTAT — SBS Enterprise Statistics (sbs_na_ind_r2)
# ============================================================================

cat("\n=== Fetching Eurostat SBS enterprise counts ===\n")

fetch_eurostat_sbs <- function(indicator, indicator_label) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/sbs_na_ind_r2",
    "?nace_r2=C325",
    "&indic_sb=", indicator,
    "&sinceTimePeriod=2015",
    "&untilTimePeriod=2022",
    "&format=JSON&lang=en"
  )

  resp <- GET(url)
  if (status_code(resp) != 200) stop("Eurostat SBS API failed: HTTP ", status_code(resp))

  d <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)

  geo_idx <- d$dimension$geo$category$index
  time_idx <- d$dimension$time$category$index
  geo_labels <- d$dimension$geo$category$label
  values <- d$value

  n_time <- length(time_idx)

  rows <- list()
  for (geo in names(geo_idx)) {
    geo_pos <- geo_idx[[geo]]
    for (yr in names(time_idx)) {
      t_pos <- time_idx[[yr]]
      idx <- as.character(geo_pos * n_time + t_pos)
      if (!is.null(values[[idx]])) {
        rows <- c(rows, list(data.frame(
          geo = geo,
          geo_name = geo_labels[[geo]],
          year = as.integer(yr),
          indicator = indicator,
          indicator_label = indicator_label,
          value = values[[idx]],
          stringsAsFactors = FALSE
        )))
      }
    }
  }

  bind_rows(rows)
}

sbs_indicators <- list(
  list(code = "V11110", label = "Number of enterprises"),
  list(code = "V12110", label = "Turnover (million EUR)"),
  list(code = "V16110", label = "Number of persons employed")
)

eurostat_sbs <- bind_rows(lapply(sbs_indicators, function(s) {
  cat("  Fetching", s$label, "...\n")
  Sys.sleep(1)
  fetch_eurostat_sbs(s$code, s$label)
}))

# Filter to individual countries only (remove aggregates)
aggregates <- c("EU27_2020", "EU28", "EU27_2007", "EA19", "EA20", "EA21", "TOTAL")
eurostat_sbs <- eurostat_sbs %>% filter(!geo %in% aggregates)

cat("  SBS data:", nrow(eurostat_sbs), "observations,",
    n_distinct(eurostat_sbs$geo), "countries\n")

fwrite(eurostat_sbs, paste0(data_dir, "eurostat_sbs_c325.csv"))


# ============================================================================
# 3) FDA openFDA — 510(k) Clearances
# ============================================================================

cat("\n=== Fetching FDA 510(k) clearances ===\n")

# Fetch annual counts by device class
fda_annual <- data.frame()

for (yr in 2010:2025) {
  for (cls in c(1, 2)) {  # Class 3 uses PMA, not 510(k)
    url <- paste0(
      "https://api.fda.gov/device/510k.json",
      "?search=decision_date:[", yr, "0101+TO+", yr, "1231]",
      "+AND+openfda.device_class:", cls,
      "&limit=1"
    )

    resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)

    if (is.null(resp) || status_code(resp) != 200) {
      # Try without device class filter
      cat("  Warning: failed for year", yr, "class", cls, "\n")
      next
    }

    d <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    total <- d$meta$results$total

    fda_annual <- rbind(fda_annual, data.frame(
      year = yr,
      device_class = cls,
      clearances = total,
      stringsAsFactors = FALSE
    ))

    Sys.sleep(0.5)  # Rate limiting
  }
  cat("  Year", yr, "done\n")
}

# Also fetch total counts per year (regardless of class)
for (yr in 2010:2025) {
  url <- paste0(
    "https://api.fda.gov/device/510k.json",
    "?search=decision_date:[", yr, "0101+TO+", yr, "1231]",
    "&limit=1"
  )

  resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)

  if (!is.null(resp) && status_code(resp) == 200) {
    d <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    fda_annual <- rbind(fda_annual, data.frame(
      year = yr,
      device_class = 0,  # 0 = all classes
      clearances = d$meta$results$total,
      stringsAsFactors = FALSE
    ))
  }

  Sys.sleep(0.5)
}

cat("  FDA data:", nrow(fda_annual), "observations\n")
fwrite(fda_annual, paste0(data_dir, "fda_510k_annual.csv"))


# ============================================================================
# 4) EUDAMED — Device Registrations by Risk Class
# ============================================================================

cat("\n=== Fetching EUDAMED device data (sampled) ===\n")

# Get total device count
url_total <- "https://ec.europa.eu/tools/eudamed/api/devices/udiDiData?pageSize=1&page=0"
resp_total <- GET(url_total, timeout(30))
total_devices <- fromJSON(content(resp_total, "text", encoding = "UTF-8"))$totalElements
cat("  EUDAMED total devices:", total_devices, "\n")

# Sample 2000 devices across the database (random pages)
# The API doesn't support risk class filtering, so we sample broadly
cat("  Fetching device sample for risk class distribution...\n")

eudamed_devices <- data.frame()
total_pages <- floor(total_devices / 100)

# Sample from different parts of the database
set.seed(42)
sample_pages <- sort(c(0:9, sample(10:min(total_pages, 12000), 10)))

for (pg in sample_pages) {
  url <- paste0(
    "https://ec.europa.eu/tools/eudamed/api/devices/udiDiData",
    "?pageSize=100&page=", pg
  )

  resp <- tryCatch(GET(url, timeout(60)), error = function(e) NULL)

  if (!is.null(resp) && status_code(resp) == 200) {
    raw_text <- content(resp, "text", encoding = "UTF-8")
    d <- fromJSON(raw_text, simplifyVector = FALSE)

    if (length(d$content) > 0) {
      for (item in d$content) {
        rc_code <- if (is.list(item$riskClass)) item$riskClass$code else NA_character_
        ds_code <- if (is.list(item$deviceStatusType)) item$deviceStatusType$code else NA_character_
        mfr_srn <- if (!is.null(item$manufacturerSrn)) item$manufacturerSrn else NA_character_
        mfr_name <- if (!is.null(item$manufacturerName)) item$manufacturerName else NA_character_
        t_name <- if (!is.null(item$tradeName)) item$tradeName else NA_character_
        ar_srn <- if (!is.null(item$authorisedRepresentativeSrn)) item$authorisedRepresentativeSrn else NA_character_

        eudamed_devices <- rbind(eudamed_devices, data.frame(
          risk_class = gsub("refdata\\.risk-class\\.", "", rc_code),
          device_status = gsub("refdata\\.device-model-status\\.", "", ds_code),
          manufacturer_srn = mfr_srn,
          manufacturer_name = mfr_name,
          trade_name = t_name,
          ar_srn = ar_srn,
          stringsAsFactors = FALSE
        ))
      }
    }
  }

  Sys.sleep(0.3)
  if (pg %% 5 == 0) cat("  Page", pg, "- devices so far:", nrow(eudamed_devices), "\n")
}

# Extract manufacturer country from SRN prefix
eudamed_devices$mfr_country <- str_extract(eudamed_devices$manufacturer_srn, "^[A-Z]{2}")

cat("  EUDAMED sample:", nrow(eudamed_devices), "devices\n")

# Compute risk class distribution from sample
risk_dist_sample <- eudamed_devices %>%
  filter(!is.na(risk_class)) %>%
  count(risk_class, name = "n_sampled") %>%
  mutate(pct = n_sampled / sum(n_sampled) * 100) %>%
  arrange(risk_class)

# Extrapolate to total
risk_dist_sample$total_devices <- round(risk_dist_sample$pct / 100 * total_devices)

# Map to clean labels
risk_dist_sample$risk_class_clean <- case_match(
  risk_dist_sample$risk_class,
  "class-i" ~ "Class I",
  "class-iia" ~ "Class IIa",
  "class-iib" ~ "Class IIb",
  "class-iii" ~ "Class III",
  .default = risk_dist_sample$risk_class
)

cat("  Risk class distribution (from sample):\n")
print(risk_dist_sample)

fwrite(risk_dist_sample, paste0(data_dir, "eudamed_risk_class_summary.csv"))
fwrite(eudamed_devices, paste0(data_dir, "eudamed_device_sample.csv"))


# ============================================================================
# 5) EUROSTAT — SBS for Control Sectors (C21, C265)
# ============================================================================

cat("\n=== Fetching SBS for control sectors ===\n")

control_sbs <- data.frame()

for (nace in c("C21", "C265", "C26")) {
  url <- paste0(
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/sbs_na_ind_r2",
    "?nace_r2=", nace,
    "&indic_sb=V11110",  # Enterprise count
    "&sinceTimePeriod=2015",
    "&untilTimePeriod=2022",
    "&format=JSON&lang=en"
  )

  resp <- GET(url)
  if (status_code(resp) == 200) {
    d <- fromJSON(content(resp, "text", encoding = "UTF-8"), simplifyVector = FALSE)

    geo_idx <- d$dimension$geo$category$index
    time_idx <- d$dimension$time$category$index
    geo_labels <- d$dimension$geo$category$label
    values <- d$value
    n_time <- length(time_idx)

    for (geo in names(geo_idx)) {
      if (geo %in% aggregates) next
      geo_pos <- geo_idx[[geo]]
      for (yr in names(time_idx)) {
        t_pos <- time_idx[[yr]]
        idx <- as.character(geo_pos * n_time + t_pos)
        if (!is.null(values[[idx]])) {
          control_sbs <- rbind(control_sbs, data.frame(
            geo = geo,
            geo_name = geo_labels[[geo]],
            year = as.integer(yr),
            nace = nace,
            enterprises = values[[idx]],
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }

  cat("  ", nace, "done\n")
  Sys.sleep(1)
}

fwrite(control_sbs, paste0(data_dir, "eurostat_sbs_control_sectors.csv"))


# ============================================================================
# DATA VALIDATION
# ============================================================================

cat("\n=== DATA VALIDATION ===\n")

# Check production index
prod <- fread(paste0(data_dir, "eurostat_prod_index.csv"))
c325 <- prod[nace == "C325"]
stopifnot("C325 production data exists" = nrow(c325) > 0)
stopifnot("Multiple countries in C325" = n_distinct(c325$geo) >= 5)
stopifnot("Years span 2015-2025" = min(c325$year) <= 2015 & max(c325$year) >= 2024)
cat("  Production index: ", nrow(prod), " rows, ",
    n_distinct(prod$geo), " countries, ",
    n_distinct(prod$nace), " sectors, ",
    n_distinct(prod$year), " years\n")

# Check FDA data
fda <- fread(paste0(data_dir, "fda_510k_annual.csv"))
stopifnot("FDA data exists" = nrow(fda) > 0)
stopifnot("FDA covers 2015-2025" = any(fda$year == 2015) & any(fda$year >= 2024))
cat("  FDA 510(k):", nrow(fda), "rows\n")

# Check EUDAMED
eud <- fread(paste0(data_dir, "eudamed_risk_class_summary.csv"))
stopifnot("EUDAMED risk classes found" = nrow(eud) >= 2)
cat("  EUDAMED summary:", sum(eud$total_devices, na.rm = TRUE), "total devices across",
    nrow(eud), "risk classes\n")

# Check SBS
sbs <- fread(paste0(data_dir, "eurostat_sbs_c325.csv"))
stopifnot("SBS data exists" = nrow(sbs) > 0)
cat("  SBS C325:", nrow(sbs), "rows,", n_distinct(sbs$geo), "countries\n")

cat("\nData validation passed. All sources confirmed.\n")
