# 01_fetch_data.R — Fetch facility and impairment data
# Source 1: EPA FRS Wastewater GIS (facilities with lat/lon/HUC/compliance)
# Source 2: EPA ATTAINS ArcGIS (303d-listed waters by HUC-12)

source("00_packages.R")

# ============================================================
# PART 1: Fetch NPDES facilities from FRS Wastewater GIS
# ============================================================
cat("=== Fetching NPDES facilities from FRS Wastewater GIS ===\n")

states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

base_url <- "https://gispub.epa.gov/arcgis/rest/services/OEI/FRS_Wastewater/MapServer/1/query"
fields <- paste0("NPDES_ID,CWP_NAME,CWP_STATE,CWP_COUNTY,CWP_CITY,",
                 "FAC_LAT,FAC_LONG,FAC_DERIVED_HUC,",
                 "CWP_IMP_WATER_FLG,CWP_CURRENT_SNC_STATUS,",
                 "CWP_13QTRS_COMPL_STATUS,CWP_MAJOR_MINOR_TYPE_FLAG,",
                 "CWP_PERMIT_STATUS_DESC,SIC_CODES,NAICS_CODES,",
                 "CWP_FACILITY_TYPE_INDICATOR,STATE_WATER_BODY_NAME")

fac_list <- list()
for (st in states) {
  offset <- 0
  batch <- 1
  while (TRUE) {
    # Fetch all NPDES facilities (not just major — we need the full sample for boundary comparisons)
    url <- paste0(base_url,
                  "?where=CWP_STATE%3D%27", st, "%27",
                  "&outFields=", fields,
                  "&f=json",
                  "&resultRecordCount=5000",
                  "&resultOffset=", offset,
                  "&returnGeometry=false")

    res <- tryCatch(httr::GET(url, httr::timeout(120)), error = function(e) NULL)
    if (is.null(res) || httr::status_code(res) != 200) break

    parsed <- tryCatch(jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8")),
                       error = function(e) NULL)
    if (is.null(parsed) || is.null(parsed$features)) break

    attrs <- parsed$features$attributes
    if (is.null(attrs) || !is.data.frame(attrs) || nrow(attrs) == 0) break

    fac_list[[paste0(st, "_", batch)]] <- as.data.table(attrs)
    if (batch == 1) cat("  ", st, ":", nrow(attrs))
    else cat("+", nrow(attrs))

    if (nrow(attrs) < 5000) { cat("\n"); break }
    offset <- offset + 5000
    batch <- batch + 1
    Sys.sleep(0.3)
  }
  Sys.sleep(0.3)
}

facilities <- rbindlist(fac_list, fill = TRUE)
cat("\nTotal facilities:", nrow(facilities), "\n")
if (nrow(facilities) < 1000) stop("FATAL: Too few facilities.")

cat("With coordinates:", sum(!is.na(facilities$FAC_LAT) & !is.na(facilities$FAC_LONG)), "\n")
cat("With HUC:", sum(!is.na(facilities$FAC_DERIVED_HUC) & facilities$FAC_DERIVED_HUC != ""), "\n")
cat("Major:", sum(facilities$CWP_MAJOR_MINOR_TYPE_FLAG == "M", na.rm = TRUE), "\n")
cat("On impaired water:", sum(facilities$CWP_IMP_WATER_FLG == "Y", na.rm = TRUE), "\n")

saveRDS(facilities, "../data/facilities_raw.rds")
cat("Saved facilities_raw.rds\n")

# ============================================================
# PART 2: Fetch ATTAINS 303(d)-listed waters with HUC-12
# ============================================================
cat("\n=== Fetching ATTAINS 303(d) listed waters ===\n")

attains_base <- "https://gispub.epa.gov/arcgis/rest/services/OW/ATTAINS_Assessment/MapServer/3/query"
attains_fields <- "huc12,isimpaired,on303dlist,reportingcycle,state,hastmdl,overallstatus"

att_list <- list()
for (st in states) {
  offset <- 0
  batch <- 1
  while (TRUE) {
    url <- paste0(attains_base,
                  "?where=state%3D%27", st, "%27+AND+on303dlist%3D%27Y%27",
                  "&outFields=", attains_fields,
                  "&f=json",
                  "&resultRecordCount=10000",
                  "&resultOffset=", offset,
                  "&returnGeometry=false")

    res <- tryCatch(httr::GET(url, httr::timeout(180)), error = function(e) NULL)
    if (is.null(res) || httr::status_code(res) != 200) break

    parsed <- tryCatch(jsonlite::fromJSON(httr::content(res, as = "text", encoding = "UTF-8")),
                       error = function(e) NULL)
    if (is.null(parsed) || is.null(parsed$features)) break

    attrs <- parsed$features$attributes
    if (is.null(attrs) || !is.data.frame(attrs) || nrow(attrs) == 0) break

    att_list[[paste0(st, "_", batch)]] <- as.data.table(attrs)
    if (batch == 1) cat("  ", st, ":", nrow(attrs))
    else cat("+", nrow(attrs))

    if (nrow(attrs) < 10000) { cat("\n"); break }
    offset <- offset + 10000
    batch <- batch + 1
    Sys.sleep(0.5)
  }
  Sys.sleep(0.3)
}

if (length(att_list) == 0) stop("FATAL: No ATTAINS data.")

attains <- rbindlist(att_list, fill = TRUE)
cat("\nTotal 303(d) listed records:", nrow(attains), "\n")
cat("Unique HUC-12s on 303(d):", uniqueN(attains$huc12), "\n")

saveRDS(attains, "../data/attains_303d.rds")
cat("Saved attains_303d.rds\n")

cat("\n=== Data fetch complete ===\n")
