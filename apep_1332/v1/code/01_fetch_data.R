# ==============================================================================
# 01_fetch_data.R — Fetch ATTAINS + USGS water quality data
# ==============================================================================

source("00_packages.R")
library(httr)
library(dataRetrieval)

DATA_DIR <- "../data"

# ---- STEP 1: Fetch ATTAINS impaired assessment units ----
cat("=== STEP 1: Fetch ATTAINS assessment units ===\n")

focus_states <- c("VA", "NC")
base_gis <- "https://gispub.epa.gov/arcgis/rest/services/OW/ATTAINS_Assessment/MapServer"

fetch_attains <- function(state, layer = 1) {
  all_features <- list()
  offset <- 0
  batch <- 2000
  repeat {
    url <- sprintf("%s/%d/query", base_gis, layer)
    resp <- GET(url, query = list(
      where = paste0("state='", state, "' AND (ircategory='4A' OR ircategory='5')"),
      outFields = "assessmentunitidentifier,assessmentunitname,ircategory,overallstatus,hastmdl,on303dlist,isimpaired,reportingcycle",
      returnGeometry = "false",
      resultRecordCount = batch,
      resultOffset = offset,
      f = "json"
    ), timeout(120))
    if (status_code(resp) != 200) break
    parsed <- jsonlite::fromJSON(content(resp, as = "text", encoding = "UTF-8"), flatten = FALSE)
    feats <- parsed$features
    if (is.null(feats) || nrow(feats) == 0) break
    all_features[[length(all_features) + 1]] <- feats$attributes
    if (nrow(feats$attributes) < batch) break
    offset <- offset + batch
    Sys.sleep(0.5)
  }
  if (length(all_features) == 0) return(NULL)
  bind_rows(all_features)
}

attains_list <- list()
for (st in focus_states) {
  cat(sprintf("Fetching ATTAINS for %s...\n", st))
  result <- fetch_attains(st)
  if (!is.null(result)) {
    result$state <- st
    attains_list[[st]] <- result
    cat(sprintf("  %s: 4A=%d, 5=%d\n", st,
                sum(result$ircategory == "4A"), sum(result$ircategory == "5")))
  }
}
if (length(attains_list) == 0) stop("FATAL: No ATTAINS data.")
attains_df <- bind_rows(attains_list)
saveRDS(attains_df, file.path(DATA_DIR, "attains_assessments.rds"))
cat(sprintf("Total: %d segments (4A: %d, 5: %d)\n",
            nrow(attains_df), sum(attains_df$ircategory == "4A"),
            sum(attains_df$ircategory == "5")))


# ---- STEP 2: Get USGS stations and HUC codes ----
cat("\n=== STEP 2: Find USGS stations with WQ data ===\n")

state_fips <- c(VA = "51", NC = "37")
all_site_nos <- c()
for (st in names(state_fips)) {
  cat(sprintf("Finding USGS stations in %s...\n", st))
  sites <- whatNWISsites(
    stateCd = state_fips[st],
    parameterCd = c("00300"),
    hasDataTypeCd = "qw",
    startDt = "2000-01-01"
  )
  cat(sprintf("  %s: %d stations\n", st, nrow(sites)))
  all_site_nos <- c(all_site_nos, sites$site_no)
  Sys.sleep(1)
}

# Get full site info with HUC codes (batch in groups of 100)
cat(sprintf("\nFetching site info for %d stations...\n", length(all_site_nos)))
site_info_list <- list()
chunks <- split(all_site_nos, ceiling(seq_along(all_site_nos) / 100))
for (i in seq_along(chunks)) {
  if (i %% 5 == 0) cat(sprintf("  Batch %d/%d\n", i, length(chunks)))
  tryCatch({
    info <- readNWISsite(chunks[[i]])
    site_info_list[[i]] <- info
  }, error = function(e) {
    cat(sprintf("  Batch %d error: %s\n", i, e$message))
  })
  Sys.sleep(0.3)
}

site_info <- bind_rows(site_info_list)
site_info$huc8 <- substr(site_info$huc_cd, 1, 8)
cat(sprintf("Sites with HUC info: %d across %d HUC8s\n",
            nrow(site_info), n_distinct(site_info$huc8)))
saveRDS(site_info, file.path(DATA_DIR, "usgs_site_info.rds"))

# Get unique HUC8s
huc8s <- unique(site_info$huc8)
huc8s <- huc8s[nchar(huc8s) == 8]  # valid HUC8s only
cat(sprintf("Valid HUC8s: %d\n", length(huc8s)))


# ---- STEP 3: Fetch DO data from WQP by HUC8 ----
cat("\n=== STEP 3: Fetch WQP DO data by HUC8 ===\n")

wq_list <- list()
errors <- 0
fetched <- 0

for (i in seq_along(huc8s)) {
  huc <- huc8s[i]
  if (i %% 10 == 0) cat(sprintf("  HUC8 %d/%d (fetched %d so far)...\n", i, length(huc8s), fetched))

  tryCatch({
    dat <- readWQPdata(
      huc = huc,
      characteristicName = "Dissolved oxygen (DO)",
      startDateLo = "01-01-2000",
      startDateHi = "12-31-2023"
    )
    if (!is.null(dat) && nrow(dat) > 0) {
      keep <- intersect(names(dat), c(
        "MonitoringLocationIdentifier", "ActivityStartDate",
        "CharacteristicName", "ResultMeasureValue",
        "ResultMeasure.MeasureUnitCode", "HUCEightDigitCode"
      ))
      dat_slim <- dat[, keep, drop = FALSE]
      # Coerce ResultMeasureValue to character to avoid type conflicts on bind
      dat_slim$ResultMeasureValue <- as.character(dat_slim$ResultMeasureValue)
      dat_slim$huc8 <- huc
      wq_list[[huc]] <- dat_slim
      fetched <- fetched + nrow(dat_slim)
    }
  }, error = function(e) {
    errors <<- errors + 1
  })

  Sys.sleep(0.3)
  if (errors > 30) {
    cat("Too many errors, stopping.\n")
    break
  }
}

if (length(wq_list) == 0) stop("FATAL: No WQP data.")

wq_df <- bind_rows(wq_list)
cat(sprintf("\nDO readings: %s from %d stations in %d HUC8s\n",
            format(nrow(wq_df), big.mark = ","),
            n_distinct(wq_df$MonitoringLocationIdentifier),
            n_distinct(wq_df$huc8)))
saveRDS(wq_df, file.path(DATA_DIR, "wqp_do_readings.rds"))

cat("\n=== Data fetch complete ===\n")
