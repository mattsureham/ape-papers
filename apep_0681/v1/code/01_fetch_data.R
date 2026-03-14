# 01_fetch_data.R — Fetch UK Business Counts from NOMIS via direct API
# apep_0681: IR35 Off-Payroll Reforms
# Data: NM_142_1 (UK Business Counts) by LA × SIC × legal status × year

source("00_packages.R")

nomis_key <- Sys.getenv("NOMIS_API_KEY")
cat(sprintf("NOMIS API key: %s\n", ifelse(nchar(nomis_key) > 0, "SET", "NOT SET")))

# ---- NOMIS API helper ----
fetch_nomis <- function(dataset_id, params) {
  base_url <- sprintf("https://www.nomisweb.co.uk/api/v01/dataset/%s.data.csv", dataset_id)

  req <- request(base_url)
  for (nm in names(params)) {
    req <- req |> req_url_query(!!nm := params[[nm]])
  }
  if (nchar(nomis_key) > 0) {
    req <- req |> req_url_query(uid = nomis_key)
  }

  resp <- req |>
    req_timeout(120) |>
    req_retry(max_tries = 3, backoff = ~2) |>
    req_perform()

  txt <- resp_body_string(resp)
  stopifnot("Empty NOMIS response" = nchar(txt) > 100)
  read_csv(txt, show_col_types = FALSE)
}

# ---- NOMIS internal industry codes (SIC 2-digit) ----
# Discovered via /industry.def.sdmx.json
sic_map <- c(
  "62" = "146800702",  # Computer programming, consultancy
  "70" = "146800710",  # Head offices; management consultancy
  "71" = "146800711",  # Architectural and engineering
  "78" = "146800718",  # Employment activities
  "47" = "146800687",  # Retail trade
  "56" = "146800696",  # Food and beverage service
  "69" = "146800709",  # Legal and accounting
  "46" = "146800686"   # Wholesale trade
)

# ---- Fetch all sectors ----
cat("Fetching UK Business Counts (NM_142_1) from NOMIS...\n")

all_data <- list()

for (sic_label in names(sic_map)) {
  nomis_id <- sic_map[sic_label]
  cat(sprintf("  SIC %s (NOMIS %s)...\n", sic_label, nomis_id))

  params <- list(
    geography = "TYPE464",
    date      = "latestMINUS9-latest",
    industry  = nomis_id,
    legal_status = "0,1,2,3",
    employment_sizeband = "0",
    measures  = "20100",
    select    = "DATE_NAME,GEOGRAPHY_NAME,GEOGRAPHY_CODE,INDUSTRY_NAME,LEGAL_STATUS,LEGAL_STATUS_NAME,OBS_VALUE"
  )

  d <- fetch_nomis("NM_142_1", params)
  d$sic_code <- as.integer(sic_label)
  all_data[[sic_label]] <- d
  cat(sprintf("    → %d rows\n", nrow(d)))
  Sys.sleep(1)
}

# ---- Combine and validate ----
raw_data <- bind_rows(all_data)
cat(sprintf("\nTotal rows: %d\n", nrow(raw_data)))
stopifnot("No data" = nrow(raw_data) > 0)
stopifnot("Missing sectors" = length(unique(raw_data$sic_code)) == 8)

write_csv(raw_data, "../data/nomis_business_counts_raw.csv")
cat("Saved: data/nomis_business_counts_raw.csv\n")

# ---- Summary ----
cat("\n--- Summary ---\n")
cat(sprintf("Years: %s\n", paste(sort(unique(raw_data$DATE_NAME)), collapse = ", ")))
cat(sprintf("LAs: %d\n", n_distinct(raw_data$GEOGRAPHY_CODE)))
cat(sprintf("SICs: %s\n", paste(sort(unique(raw_data$sic_code)), collapse = ", ")))
cat(sprintf("Legal statuses: %s\n", paste(sort(unique(raw_data$LEGAL_STATUS_NAME)), collapse = "; ")))

# Quick check: SIC 62 companies trend
sic62_co <- raw_data |>
  filter(sic_code == 62, LEGAL_STATUS == 1) |>
  group_by(DATE_NAME) |>
  summarise(total = sum(OBS_VALUE, na.rm = TRUE), .groups = "drop") |>
  arrange(DATE_NAME)
cat("\nSIC 62 (IT) companies by year:\n")
print(sic62_co, n = 20)
