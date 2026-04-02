# ==============================================================================
# 02_clean_data.R — Clean and merge ATTAINS + WQP data
# ==============================================================================

source("00_packages.R")
library(httr)
DATA_DIR <- "../data"

cat("=== Loading raw data ===\n")
attains <- readRDS(file.path(DATA_DIR, "attains_assessments.rds"))
site_info <- readRDS(file.path(DATA_DIR, "usgs_site_info.rds"))
wq_do <- readRDS(file.path(DATA_DIR, "wqp_do_readings.rds"))

cat(sprintf("ATTAINS segments: %d\n", nrow(attains)))
cat(sprintf("USGS sites: %d\n", nrow(site_info)))
cat(sprintf("DO readings: %s\n", format(nrow(wq_do), big.mark = ",")))

# State-level TMDL shares
state_tmdl <- attains %>%
  group_by(state) %>%
  summarize(
    n_4A = sum(ircategory == "4A"),
    n_5 = sum(ircategory == "5"),
    n_total = n(),
    tmdl_share = n_4A / n_total,
    .groups = "drop"
  )
cat("\nState-level TMDL shares:\n")
print(state_tmdl)


# ---- Clean WQ data ----
cat("\n=== Cleaning water quality data ===\n")

wq <- wq_do %>%
  mutate(
    date = as.Date(ActivityStartDate),
    year = year(date),
    quarter = quarter(date),
    do_value = as.numeric(ResultMeasureValue),
    station_id = MonitoringLocationIdentifier
  ) %>%
  filter(
    !is.na(do_value),
    do_value >= 0,
    do_value <= 25,
    year >= 2000,
    year <= 2023
  )

cat(sprintf("After cleaning: %s readings (%s removed)\n",
            format(nrow(wq), big.mark = ","),
            format(nrow(wq_do) - nrow(wq), big.mark = ",")))
cat(sprintf("Mean DO: %.2f mg/L (SD: %.2f)\n", mean(wq$do_value), sd(wq$do_value)))


# ---- Assign state to each station ----
cat("\n=== Assigning states to stations ===\n")

# Map site_info to station IDs
site_huc <- site_info %>%
  mutate(
    station_id = paste0("USGS-", site_no),
    huc8 = substr(huc_cd, 1, 8),
    state = case_when(
      state_cd == "51" ~ "VA",
      state_cd == "37" ~ "NC",
      TRUE ~ "OTHER"
    )
  ) %>%
  select(station_id, huc8, state, dec_lat_va, dec_long_va) %>%
  distinct(station_id, .keep_all = TRUE)

# Assign state from station ID or HUC codes
# WQP includes non-USGS stations — assign state from huc8 prefix
huc8_state <- site_huc %>%
  filter(state %in% c("VA", "NC")) %>%
  select(huc8, state) %>%
  distinct(huc8, .keep_all = TRUE)

# Merge WQ data with HUC and state info
wq_huc <- wq %>%
  select(station_id, huc8) %>%
  distinct(station_id, .keep_all = TRUE) %>%
  filter(nchar(huc8) == 8)

station_state <- wq_huc %>%
  left_join(huc8_state, by = "huc8") %>%
  filter(!is.na(state))

cat(sprintf("Stations with state assignment: %d\n", nrow(station_state)))
cat(sprintf("  VA: %d, NC: %d\n",
            sum(station_state$state == "VA"),
            sum(station_state$state == "NC")))


# ---- Build HUC8-level TMDL share ----
cat("\n=== Building HUC8-level TMDL approximation ===\n")

# Quick geometry sample: fetch 200 ATTAINS segments with coordinates for HUC8 mapping
base_gis <- "https://gispub.epa.gov/arcgis/rest/services/OW/ATTAINS_Assessment/MapServer"

fetch_sample_coords <- function(state, n = 200) {
  url <- sprintf("%s/1/query", base_gis)
  resp <- GET(url, query = list(
    where = paste0("state='", state, "' AND (ircategory='4A' OR ircategory='5')"),
    outFields = "assessmentunitidentifier,ircategory",
    returnGeometry = "true",
    geometryType = "esriGeometryEnvelope",
    returnCentroid = "true",
    outSR = "4326",
    resultRecordCount = n,
    f = "json"
  ), timeout(60))
  if (status_code(resp) != 200) return(NULL)
  json_text <- content(resp, as = "text", encoding = "UTF-8")
  if (grepl("\"error\"", json_text)) return(NULL)
  parsed <- tryCatch(jsonlite::fromJSON(json_text, flatten = FALSE), error = function(e) NULL)
  if (is.null(parsed) || is.null(parsed$features)) return(NULL)
  feats <- parsed$features
  attrs <- feats$attributes
  # Get first coordinate from line geometry
  if (!is.null(feats$geometry) && !is.null(feats$geometry$paths)) {
    coords <- sapply(feats$geometry$paths, function(p) {
      if (is.list(p) && length(p) > 0) {
        pts <- p[[1]]
        if (is.matrix(pts)) return(c(mean(pts[,1]), mean(pts[,2])))
      }
      return(c(NA_real_, NA_real_))
    })
    if (is.matrix(coords)) {
      attrs$lon <- coords[1,]
      attrs$lat <- coords[2,]
    }
  }
  attrs
}

pts_list <- list()
for (st in c("VA", "NC")) {
  cat(sprintf("  Fetching sample coordinates for %s...\n", st))
  pts <- fetch_sample_coords(st, n = 500)
  if (!is.null(pts) && "lon" %in% names(pts)) {
    pts$state <- st
    pts_list[[st]] <- pts
    cat(sprintf("    %s: %d segments with coordinates\n", st, sum(!is.na(pts$lon))))
  } else {
    cat(sprintf("    %s: no coordinates obtained\n", st))
  }
}

# If we got coordinates, match to HUC8 via nearest USGS station
if (length(pts_list) > 0) {
  attains_pts <- bind_rows(pts_list)
  attains_pts <- attains_pts %>% filter(!is.na(lon), !is.na(lat))

  usgs_pts <- site_huc %>%
    filter(!is.na(dec_lat_va), !is.na(dec_long_va), nchar(huc8) == 8)

  # Nearest-station match to assign HUC8
  cat(sprintf("  Matching %d ATTAINS segments to HUC8...\n", nrow(attains_pts)))
  attains_pts$matched_huc8 <- sapply(1:nrow(attains_pts), function(i) {
    dists <- (usgs_pts$dec_lat_va - attains_pts$lat[i])^2 +
             (usgs_pts$dec_long_va - attains_pts$lon[i])^2
    usgs_pts$huc8[which.min(dists)]
  })

  # HUC8-level TMDL share from matched sample
  huc8_tmdl <- attains_pts %>%
    filter(nchar(matched_huc8) == 8) %>%
    group_by(huc8 = matched_huc8) %>%
    summarize(
      n_4A = sum(ircategory == "4A"),
      n_5 = sum(ircategory == "5"),
      n_total = n(),
      tmdl_share = n_4A / n_total,
      .groups = "drop"
    ) %>%
    filter(n_total >= 3)  # require at least 3 segments per HUC8

  cat(sprintf("  HUC8s with TMDL share: %d\n", nrow(huc8_tmdl)))
  cat(sprintf("  Mean TMDL share: %.2f (SD: %.2f)\n",
              mean(huc8_tmdl$tmdl_share), sd(huc8_tmdl$tmdl_share)))
  saveRDS(huc8_tmdl, file.path(DATA_DIR, "huc8_tmdl_share.rds"))
} else {
  # Fallback: use state-level TMDL share
  cat("  Using state-level TMDL share as fallback.\n")
  huc8_tmdl <- huc8_state %>%
    left_join(state_tmdl %>% select(state, tmdl_share), by = "state")
}


# ---- Build analysis panel ----
cat("\n=== Building analysis panel ===\n")

panel <- wq %>%
  group_by(station_id, huc8, year) %>%
  summarize(
    do_mean = mean(do_value, na.rm = TRUE),
    do_sd = sd(do_value, na.rm = TRUE),
    do_min = min(do_value, na.rm = TRUE),
    do_n = n(),
    .groups = "drop"
  ) %>%
  filter(do_n >= 2, nchar(huc8) == 8)

# Merge with state assignment
panel <- panel %>%
  left_join(station_state %>% select(station_id, state), by = "station_id")

# Merge with TMDL share
panel <- panel %>%
  left_join(huc8_tmdl %>% select(huc8, tmdl_share), by = "huc8")

# If no HUC8-level, use state-level
if (all(is.na(panel$tmdl_share))) {
  panel <- panel %>%
    left_join(state_tmdl %>% select(state, tmdl_share_state = tmdl_share), by = "state") %>%
    mutate(tmdl_share = coalesce(tmdl_share, tmdl_share_state)) %>%
    select(-tmdl_share_state)
}

# Create treatment variables
panel <- panel %>%
  filter(!is.na(tmdl_share), !is.na(state)) %>%
  mutate(
    high_tmdl = as.numeric(tmdl_share > median(tmdl_share, na.rm = TRUE)),
    has_tmdl_data = TRUE,
    post = as.numeric(year >= 2010)
  )

cat(sprintf("Panel: %d station-years, %d stations, %d HUC8s\n",
            nrow(panel), n_distinct(panel$station_id), n_distinct(panel$huc8)))

saveRDS(panel, file.path(DATA_DIR, "analysis_panel.rds"))


# ---- Summary statistics ----
cat("\n=== Summary statistics ===\n")
cat(sprintf("Mean DO: %.2f (SD: %.2f)\n", mean(panel$do_mean), sd(panel$do_mean)))

cat("\nBy TMDL coverage:\n")
panel %>%
  group_by(high_tmdl) %>%
  summarize(
    n_obs = n(),
    n_stations = n_distinct(station_id),
    mean_do = round(mean(do_mean), 2),
    sd_do = round(sd(do_mean), 2),
    .groups = "drop"
  ) %>%
  print()

cat("\nBy state and period:\n")
panel %>%
  mutate(period = ifelse(year < 2010, "Pre", "Post")) %>%
  group_by(state, period) %>%
  summarize(mean_do = round(mean(do_mean), 2), n = n(), .groups = "drop") %>%
  print()

# Write diagnostics
diag <- list(
  n_treated = n_distinct(panel$station_id[panel$high_tmdl == 1]),
  n_pre = length(unique(panel$year[panel$year < 2010])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\n=== Data cleaning complete ===\n")
