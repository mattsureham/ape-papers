source("code/00_packages.R")

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

api_base <- "https://wildlife.faa.gov/WildlifeAdmin/api/Service/"

discover_public_headers <- function() {
  home_html <- paste(system("curl -sL https://wildlife.faa.gov/home", intern = TRUE), collapse = "\n")
  main_js <- regmatches(
    home_html,
    regexpr('main-[A-Z0-9]+\\.js', home_html, perl = TRUE)
  )
  if (!length(main_js) || is.na(main_js) || !nzchar(main_js)) {
    stop("Could not discover FAA wildlife frontend bundle for public API headers.")
  }

  js_text <- paste(system(sprintf("curl -sL %s", shQuote(paste0("https://wildlife.faa.gov/", main_js))), intern = TRUE), collapse = "\n")
  token_match <- regmatches(
    js_text,
    regexpr('token:"[A-Z0-9-]{20,}"', js_text, perl = TRUE)
  )
  client_match <- regmatches(
    js_text,
    regexpr('clientId:"[^"]+"', js_text, perl = TRUE)
  )
  if (!length(token_match) || is.na(token_match) || !nzchar(token_match) ||
      !length(client_match) || is.na(client_match) || !nzchar(client_match)) {
    stop("Could not parse FAA wildlife public API headers from frontend bundle.")
  }

  token <- sub('^token:"([^"]+)"$', "\\1", token_match)
  client_id <- sub('^clientId:"([^"]+)"$', "\\1", client_match)
  c(
    token = token,
    clientId = client_id,
    `Content-Type` = "application/json"
  )
}

api_headers <- discover_public_headers()

post_json <- function(endpoint, body_list) {
  body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE, null = "null")
  con <- url(paste0(api_base, endpoint), open = "rb", headers = api_headers)
  on.exit(close(con), add = TRUE)
  stop("POST via url() is unsupported in this R build.")
}

get_json <- function(url) {
  raw_path <- tempfile(fileext = ".json")
  cmd <- sprintf(
    "curl -sL -H %s -H %s %s",
    shQuote(sprintf("token: %s", api_headers[["token"]])),
    shQuote(sprintf("clientId: %s", api_headers[["clientId"]])),
    shQuote(url)
  )
  raw_text <- system(cmd, intern = TRUE)
  jsonlite::fromJSON(paste(raw_text, collapse = "\n"), simplifyVector = TRUE)
}

post_json_curl <- function(url, body_list) {
  body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE, null = "null")
  tmp_body <- tempfile(fileext = ".json")
  writeLines(body_json, tmp_body)
  cmd <- sprintf(
    paste(
      "curl -sL -X POST",
      "-H %s -H %s -H %s",
      "--data-binary @%s %s"
    ),
    shQuote(sprintf("token: %s", api_headers[["token"]])),
    shQuote(sprintf("clientId: %s", api_headers[["clientId"]])),
    shQuote("Content-Type: application/json"),
    shQuote(tmp_body),
    shQuote(url)
  )
  raw_text <- system(cmd, intern = TRUE)
  unlink(tmp_body)
  jsonlite::fromJSON(paste(raw_text, collapse = "\n"), simplifyVector = TRUE)
}

strike_query <- list(
  fromDate = "",
  toDate = "",
  IncidentDateFrom = "1990-01-01",
  IncidentDateTo = "2024-12-31",
  LupdateDateFrom = "1990-01-01",
  LupdateDateTo = "2024-12-31",
  airCraftTypeId = "0",
  damageLevelId = "0",
  engineTypeId = "0",
  engineTypeCode = "0",
  wildLifeId = "0",
  airportId = "",
  stateId = 0,
  role = "PUBLIC",
  processingStatusId = "3",
  strikeReportTypeId = 1,
  siIdentifiedTypeId = "",
  nonIndigenous = FALSE,
  operatorId = "",
  operatorCode = "",
  operatorName = ""
)

message("Fetching public wildlife-strike database...")
strike_resp <- post_json_curl(paste0(api_base, "searchDatabase/"), strike_query)
stopifnot(isTRUE(strike_resp$Success), strike_resp$Total > 100000)
strike_dt <- as.data.table(strike_resp$Result)
fwrite(strike_dt, "data/raw/nwsd_strikes.csv.gz")

writeLines(
  jsonlite::toJSON(strike_query, auto_unbox = TRUE, pretty = TRUE),
  "data/raw/nwsd_query.json"
)

message("Fetching FAA airport metadata...")
airport_resp <- get_json(paste0(api_base, "GetAirports"))
stopifnot(isTRUE(airport_resp$Success), airport_resp$Total > 1000)
airport_dt <- as.data.table(airport_resp$Result)
fwrite(airport_dt, "data/raw/faa_airports.csv.gz")

message("Downloading current Part 139 workbook and 2004 regulatory evaluation...")
download.file(
  "https://www.faa.gov/sites/faa.gov/files/arp-aas-part139-cert-status-table-2026-02-19-rev.xlsx",
  destfile = "data/raw/part139_status_current.xlsx",
  mode = "wb",
  quiet = TRUE
)
download.file(
  "https://www.faa.gov/sites/faa.gov/files/airports/resources/publications/regulations/regulatory-evaluation.pdf",
  destfile = "data/raw/regulatory_evaluation_part139_2004.pdf",
  mode = "wb",
  quiet = TRUE
)

message("Writing historical Class III roster from FAA appendix...")
class3_dt <- data.table(
  airport_code = c(
    "HII", "SOW", "ELD", "HRO", "JBR", "BPK", "IPL", "IYK", "CGX", "SPW",
    "AUG", "BHB", "RKD", "CBE", "MBL", "GGW", "GDV", "HVR", "LWT", "MLS",
    "SDY", "OLF", "CDR", "EAR", "ALM", "CNM", "GUP", "SAF", "SVC", "DIK",
    "PNC", "BWD", "CNY", "VEL", "BLF", "FAQ", "Z08"
  ),
  associated_city = c(
    "Lake Havasu City", "Show Low", "El Dorado", "Harrison", "Jonesboro",
    "Mountain Home", "Imperial", "Inyokern", "Chicago", "Spencer", "Augusta",
    "Bar Harbor", "Rockland", "Cumberland", "Manistee", "Glasgow", "Glendive",
    "Havre", "Lewistown", "Miles City", "Sidney", "Wolf Point", "Chadron",
    "Kearney", "Alamogordo", "Carlsbad", "Gallup", "Santa Fe", "Silver City",
    "Dickinson", "Ponca City", "Brownwood", "Moab", "Vernal", "Bluefield",
    "Fitiuta Village", "Ofu Village"
  ),
  airport_name = c(
    "Lake Havasu City", "Show Low Municipal", "South AR Regional", "Boone County",
    "Jonesboro Municipal", "Baxter Co. Regional", "Imperial County", "Inyokern",
    "Merrill Meigs", "Spencer Municipal", "Augusta State",
    "Hancock County-Bar Harbor", "Knox County Regional", "Greater Cumberland Reg.",
    "Manistee Co.-Blacker", "Wokal Fld/Glasgow Int'l", "Dawson Community",
    "Havre City-County", "Lewistown Municipal", "Frank Wiley Field",
    "Sidney-Richland Muni.", "L M Clayton", "Chadron Municipal",
    "Kearney Municipal", "Alamogordo-White Sands", "Cavern City Air Terminal",
    "Gallup Municipal", "Santa Fe Municipal", "Grant County",
    "Dickinson Municipal", "Ponca City Municipal", "Brownwood Regional",
    "Canyonlands Field", "Vernal", "Mercer County", "Fitiuta", "Ofu"
  ),
  source = "FAA regulatory evaluation appendix III-3",
  source_date = as.Date("2001-07-01")
)
fwrite(class3_dt, "data/raw/class3_airports_2001.csv")

stopifnot(
  nrow(strike_dt) > 300000,
  nrow(airport_dt) > 3000,
  all(c("AIRPORT", "IncidentDate", "Damage") %in% names(strike_dt)),
  nrow(class3_dt) == 37
)

message("Fetch complete.")
